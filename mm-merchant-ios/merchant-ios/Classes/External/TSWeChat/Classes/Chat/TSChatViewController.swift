//
//  TSChatViewController.swift
//  TSWeChat
//
//  Created by Hilen on 12/10/15.
//  Copyright © 2015 Hilen. All rights reserved.
//

import UIKit
import SnapKit
import Photos
import MBProgressHUD
import YYText
import PromiseKit
import ObjectMapper
import SKPhotoBrowser

/*
 *   聊天详情的 ViewController
 */
class TSChatViewController: MmViewController {
    
    enum ChatOptionMenu: Int {
        case chatInfoPage
        case customerInfoPage
        case forwardChat
        case flagUnflagChat
        case closeChat
        case merchantInfoPage
    }
    
    var convCloseTextfield: UITextField?
    var listOfChatOptionMenu:[ChatOptionMenu]?
    
    var followUpLabel: UILabel?
    var keyboardObservers: [AnyObject] = []
    
    @IBOutlet weak var tableViewMarginBottomConstraint: NSLayoutConstraint!
    @IBOutlet weak var listTableView: UITableView!
    @IBOutlet var refreshView: UIView!
    @IBOutlet weak var indicatorView: UIActivityIndicatorView!
    
    fileprivate(set) var conv: Conv?
    var presenter: User? {
        return conv?.presenter
    }
    
    var forwardChatModel: ChatModel?
    var chatActionBarView: TSChatActionBarView!  //action bar
    var chatCommentActionBarView: TSChatActionBarView!
    var actionBarPaddingBottomConstraint: Constraint? //action bar 的 bottom Constraint
    var actionBarHeightConstraint: Constraint?
    var textInputOffset: CGFloat?
    var keyboardHeightConstraint: NSLayoutConstraint?  //键盘高度的 Constraint
    var emotionInputView: TSChatEmotionInputView! //表情键盘
    var shareMoreView: TSChatShareMoreView!    //分享键盘
    var messageView: TSChatListPredefinedMessage!    //分享键盘
    var voiceIndicatorView: TSChatVoiceIndicatorView! //声音的显示 View
    var imagePicker = UIImagePickerController()  //照相机
    var imagePickerNavigationController = UINavigationController()
    var itemDataSouce = [ChatModel]()
    var imageDataSouce = [ChatModel]()
    var isReloading: Bool = false               //UITableView 是否正在加载数据, 如果是，把当前发送的消息缓存起来后再进行发送
    var currentVoiceCell: TSChatVoiceCell!     //现在正在播放的声音的 cell
    var isEndRefreshing: Bool = true            // 是否结束了下拉加载更多
    var backgroundImage = UIImageView()
    lazy var loadMore: ChatModel = {
        let model = ChatModel(type: .LoadMore)
        model.timeDate = Date(timeIntervalSince1970: 0)
        return model
    } ()
    
    var paidOrder: ParentOrder? //For action after payment
    
    var didPopHandler: ((_ friend: User, _ chatModel: ChatModel) -> ())?
    
    var cacheMessages = [ChatModel]()
    
    var firstLoad = true
    var previousChatBoxHeight: CGFloat!
    
    var didCreateNewChat: ((_ ack: IMAckMessage, _ convType: ConvType) -> ())?
    var finishedForwardingChat: ((_ stayOn: Bool) -> ())?
    var finishedTransferChat: ((_ stayOn: Bool, _ convKey: String) -> ())?
    var isScrolled = false
    
    required init(nibName nibNameOrNil: String?, bundle nibBundleOrNil: Bundle?) {
        super.init(nibName: nibNameOrNil == nil ? "TSChatViewController" : nibNameOrNil, bundle: nibBundleOrNil)
    }
    
    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
    }
    
    
    
//    @available(*, deprecated, message: "use Navigator open url, 5.5版本将完全丢弃")
    convenience init(convKey: String) {
        let conv = WebSocketManager.sharedInstance().conversationForKey(convKey) ?? Conv(convKey: convKey)
        self.init(conv: conv)
    }
    
//    @available(*, deprecated, message: "use Navigator open url, 5.5版本将完全丢弃")
    convenience init(conv: Conv) {
        self.init(nibName: "TSChatViewController", bundle: nil)
        self.conv = conv
    }
    
    private func renderChat(showError:Bool = true) {
        guard let conv = self.conv else {
            if showError {
                ErrorLogManager.sharedManager.recordNonFatalError(withException: .NullPointer)
            }
            return
        }
        
        let viewLocation = conv.chatTypeString()
        var viewDisplayName = ""
        if conv.isGroupChat() {
            if let groupChatName = conv.groupChatName() {
                var userName = ""
                for nameModel in groupChatName {
                    userName = nameModel.name + ", "
                    viewDisplayName += userName
                }
                
                if viewDisplayName.length > 1 {
                    let index = viewDisplayName.index(viewDisplayName.endIndex, offsetBy: -2)
                    viewDisplayName = String(viewDisplayName[index])
                }
            }
        } else {
            viewDisplayName = conv.presenter?.displayName ?? ""
        }
        
        initAnalyticsViewRecord(
            merchantCode: conv.merchantObject?.merchantCode,
            viewDisplayName: viewDisplayName,
            viewLocation: viewLocation,
            viewRef: conv.convKey,
            viewType: "IM"
        )
    }
    
    private func loadHistoryChat() {
        
        if let conv = self.conv {
            let messages = CacheManager.sharedManager.cachedMessageForConv(conv)
            processHistory(messages, more: false)
            WebSocketManager.sharedInstance().convReadMessage(conv.convKey)
        }
        
        fetchHistory { [weak self] (request, response) in
            if let strongSelf = self {
                strongSelf.handleIncomingHistory(request: request, response: response)
            } else {
                ErrorLogManager.sharedManager.recordNonFatalError(withException: .NullPointer)
            }
        }
        
        reloadConversation()
    }
    
    
    @objc private func asyncLoadConv(_ params:[String:Any]) {
        if !LoginManager.isValidUser() {
            return
        }
        
        let targetRole: UserRole? = params["targetRole"] as? UserRole
        let merchantId: Int? = params["merchantId"] as? Int
        let queueType: QueueType? = params["queueType"] as? QueueType
        
        var list:[UserRole] = []
        let myRole: UserRole = UserRole(userKey: Context.getUserKey())
        list.append(myRole)
        
        if let targetRole = targetRole {
            list.append(targetRole)
        }
        
        if list.isEmpty {
            return
        }
        
        var queue:QueueType = QueueType.General
        if let queueType = queueType {
            queue = queueType
        }
        
        //需要等待链接建立
        let end = Date.init(timeIntervalSinceNow: 60)//等待一分钟
        if LoginManager.isValidUser() && !WebSocketManager.sharedInstance().isConnected {
            //采用loop等待应用启动状态ok(WebSocket链接ok)
            while(RunLoop.current.run(mode: RunLoopMode.defaultRunLoopMode, before: end) && !WebSocketManager.sharedInstance().isConnected) {
                //nothing
            }
        }
        
        print("通过open url打开进入聊天页面")
        
        WebSocketManager.sharedInstance().sendMessage(
            IMConvStartToCSMessage( userList: list, queue:queue, senderMerchantId: myRole.merchantId, merchantId: merchantId ),
            completion: { [weak self] ack in
                if let strongSelf = self {
                    if let convKey = ack.data {
                        strongSelf.conv = WebSocketManager.sharedInstance().conversationForKey(convKey) ?? Conv(convKey: convKey)
                    }
                    //
                    strongSelf.renderChat()
                    strongSelf.loadHistoryChat()
                }
            }, failure: { [weak self] in
                if let strongSelf = self {
                    strongSelf.showErrorAlert(String.localize("MSG_ERR_NETWORK_1009"))
                }
            }
        )
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        // 走open url过来(将废弃init直接传入参数方式)，直接带参数, 有一下几种可能
        var waiting = false
        if conv == nil {
            // 1、传入会话id
            if let key = self.ssn_Arguments["conversationKey"]?.string,!key.isEmpty {
                self.conv = WebSocketManager.sharedInstance().conversationForKey(key) ?? Conv(convKey: key)
            } else if let targetUserKey = self.ssn_Arguments["targetUserKey"]?.string,!targetUserKey.isEmpty {//2、传入targetUserKey
                waiting = true

                let targetRole: UserRole = UserRole(userKey: targetUserKey)
                let info:[String:Any] = ["targetRole":targetRole]
                //必须使用perform afterDelay来调用，使得异步事件为handle loopsouce，而不是简单压栈，以防止asyncLoadConv中使用嵌套loop导致main_queue的阻塞
                self.perform(#selector(TSChatViewController.asyncLoadConv), with: info, afterDelay:0.01)
                
            } else if let merchantId = self.ssn_Arguments["merchantId"]?.int {//3、merchant聊天；merchant = 0表示mm客服
                
                var queue:QueueType = QueueType.General
                if let queueType = self.ssn_Arguments["queueType"]?.string, let type = QueueType(rawValue: queueType) {
                    queue = type
                }
                
                let info:[String:Any] = ["queueType":queue,"merchantId":merchantId]
                //必须使用perform afterDelay来调用，使得异步事件为handle loopsouce，而不是简单压栈，以防止asyncLoadConv中使用嵌套loop导致main_queue的阻塞
                self.perform(#selector(TSChatViewController.asyncLoadConv), with: info, afterDelay:0.01)
                
            }
        }
        
        // for automation
        self.pageAccessibilityId = "IM_UserChat"
        
        // 渲染聊天
        renderChat(showError:!waiting)
        
        self.view.backgroundColor = UIColor(colorNamed: TSColor.viewBackgroundColor)
        
        //TableView init
        self.listTableView.register(TSChatTextCell.NibObject(), forCellReuseIdentifier: TSChatTextCell.identifier)
        self.listTableView.register(TSChatImageCell.NibObject(), forCellReuseIdentifier: TSChatImageCell.identifier)
        self.listTableView.register(TSChatVoiceCell.NibObject(), forCellReuseIdentifier: TSChatVoiceCell.identifier)
        self.listTableView.register(TSChatSystemCell.NibObject(), forCellReuseIdentifier: TSChatSystemCell.identifier)
        self.listTableView.register(TSChatTimeCell.NibObject(), forCellReuseIdentifier: TSChatTimeCell.identifier)
        self.listTableView.register(TSChatShareProductCell.NibObject(), forCellReuseIdentifier: TSChatShareProductCell.identifier)
        self.listTableView.register(TSShareUserCell.NibObject(), forCellReuseIdentifier: TSShareUserCell.identifier)
        self.listTableView.register(TSShareMerchantCell.NibObject(), forCellReuseIdentifier: TSShareMerchantCell.identifier)
        self.listTableView.register(TSShareBrandCell.NibObject(), forCellReuseIdentifier: TSShareBrandCell.identifier)
        self.listTableView.register(TSShareOrderCell.NibObject(), forCellReuseIdentifier: TSShareOrderCell.identifier)
        self.listTableView.register(TSLoadMoreCell.NibObject(), forCellReuseIdentifier: TSLoadMoreCell.identifier)
        self.listTableView.register(TSChatCommentCell.NibObject(), forCellReuseIdentifier: TSChatCommentCell.identifier)
        self.listTableView.register(TSChatTransferCell.NibObject(), forCellReuseIdentifier: TSChatTransferCell.identifier)
        self.listTableView.register(TSSharePostCell.NibObject(), forCellReuseIdentifier: TSSharePostCell.identifier)
        self.listTableView.register(TSSharePageCell.NibObject(), forCellReuseIdentifier: TSSharePageCell.identifier)
        self.listTableView.register(TSCouponCell.NibObject(), forCellReuseIdentifier: TSCouponCell.identifier)
        self.listTableView.register(TSShipmentCell.NibObject(), forCellReuseIdentifier: TSShipmentCell.identifier)
        self.listTableView.register(TSShipmentImageCell.NibObject(), forCellReuseIdentifier: TSShipmentImageCell.identifier)
        self.listTableView.register(TSChatAutoRespondCell.NibObject(), forCellReuseIdentifier: TSChatAutoRespondCell.identifier)
        self.listTableView.register(TSMasterCouponCell.NibObject(), forCellReuseIdentifier: TSMasterCouponCell.identifier)
        
        self.listTableView.tableFooterView = UIView()
        //self.listTableView.tableHeaderView = self.refreshView
        
        //初始化子 View，键盘控制，动作 bar
        self.setupSubviews(self)
        
        //设置录音 delegate
        AudioRecordInstance.delegate = self
        //设置播放 delegate
        AudioPlayInstance.delegate = self
        
        chatActionBarView.layer.borderWidth = 1.0
        chatActionBarView.layer.borderColor = UIColor.secondary1().cgColor
        chatActionBarView.layer.masksToBounds = true
        self.createBackButton()
        
        NotificationCenter.default.addObserver(self, selector: #selector(TSChatViewController.showSaveImageSuccessPopup), name:NSNotification.Name(rawValue: "SaveImageSuccess"), object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(TSChatViewController.showSaveImageFailedPopup), name:NSNotification.Name(rawValue: "SaveImageFailed"), object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(TSChatViewController.conversationListUpdated), name: NSNotification.Name(rawValue: IMDidUpdateConversationList), object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(TSChatViewController.didReceiveMessage), name: NSNotification.Name(rawValue: IMDidReceiveMessage), object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(handleCellExpand), name:NSNotification.Name(rawValue: "cellDidLoad"), object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(TSChatViewController.reloadTable), name:NSNotification.Name(rawValue: "commentCellLoaded"), object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(changeAlias), name:Constants.Notification.changeAliasOnProfileView, object: nil)
        
        loadHistoryChat()
    }
    
    @objc func handleCellExpand() {
        self.reloadTable()
        if !self.isScrolled {
            self.listTableView.scrollBottomToLastRow()
        }
    }
    
    func setupBackgroundImage() {
        self.listTableView.backgroundColor = UIColor.clear
        
        backgroundImage.frame = CGRect(x: 0, y: StartYPos, width: Constants.ScreenSize.SCREEN_WIDTH, height: Constants.ScreenSize.SCREEN_HEIGHT - 64)
        backgroundImage.image = UIImage(named: "")
        self.view.insertSubview(backgroundImage, at: 0)
        
        if let merchantObject = conv?.merchantObject {
            
            let merchantBackgroundImage = merchantObject.backgroundImage
            
            if merchantBackgroundImage != "" {
                backgroundImage.mm_setImageWithURL(ImageURLFactory.URLSize1000(merchantBackgroundImage, category: .merchant), placeholderImage : nil)
            }
        } else {
            ErrorLogManager.sharedManager.recordNonFatalError(withException: .NullPointer)
        }
    }
    
    func createRightBarButton() {
        
        var rightButtonItems = [UIBarButtonItem]()
        
        if checkChatOptionMenuToShowMoreButton() {
            
            let ButtonHeight = CGFloat(25)
            let ButtonWidth = CGFloat(30)
            
            let buttonMore = UIButton(type: .custom)
            buttonMore.setImage(UIImage(named: "icon_more"), for: UIControlState())
            buttonMore.frame = CGRect(x: 0, y: 0, width: ButtonWidth, height: ButtonHeight)
            buttonMore.addTarget(self, action: #selector(moreButtonTapped), for: .touchUpInside)
            self.setAccessibilityIdForView("UIBT_MORE", view: buttonMore)
            
            rightButtonItems.append(UIBarButtonItem(customView: buttonMore))
        }
        
        if let conv = self.conv, conv.isFollowUp() == true && !conv.isClosed() {
            let PaddingLeft = CGFloat(5)
            let PaddingTop = CGFloat(2)
            followUpLabel = { () -> UILabel in
                let label = UILabel()
                label.font = UIFont.boldSystemFont(ofSize: 12)
                label.text = String.localize("LB_CS_CHAT_FLAGGED")
                label.textColor = UIColor.white
                label.textAlignment = .center
                label.backgroundColor = UIColor.primary1()
                label.layer.cornerRadius = 3
                label.clipsToBounds =  true
                label.sizeToFit()
                label.frame = CGRect(x: 0, y: 0, width: label.frame.width + (2 * PaddingLeft), height: label.frame.height + (2 * PaddingTop))
                rightButtonItems.append(UIBarButtonItem(customView: label))
                
                return label
            }()
        }
        else {
            followUpLabel = nil
        }
        
        self.navigationItem.rightBarButtonItems = rightButtonItems
    }
    
    func checkChatOptionMenuToShowMoreButton() -> Bool {
        
        self.listOfChatOptionMenu = self.optionMenuConfig()
        
        if let listOfChatOptionMenu = self.listOfChatOptionMenu, listOfChatOptionMenu.count > 0 {
            return true
        }
        return false
    }
    
    override func backButtonClicked(_ button: UIButton) {
        if let conv = self.conv {
            WebSocketManager.sharedInstance().readConvLocal(conv.convKey)
        }
        self.navigationController?.popViewController(animated: true)
    }
    
    @objc func moreButtonTapped() {
        Log.debug("more button tapped")
        
        guard let listOfChatOptionMenu = self.listOfChatOptionMenu else {
            return
        }
        
        let optionMenu = UIAlertController(title: nil, message: nil, preferredStyle: .actionSheet)
        for chatOptionMenu in listOfChatOptionMenu {
            switch chatOptionMenu.rawValue {
            case ChatOptionMenu.chatInfoPage.rawValue:
                
                let groupChatInfoAction = UIAlertAction(title: String.localize("LB_CA_IM_CHAT_INFO"), style: .default, handler: { [weak self] (alert: UIAlertAction!) -> Void in
                    if let strongSelf = self {
                        
                        // Action tag
                        strongSelf.view.analyticsViewKey = strongSelf.analyticsViewRecord.viewKey
                        strongSelf.view.recordAction(
                            .Tap,
                            sourceRef: "ChatInfo",
                            sourceType: .Button,
                            targetRef: "ChatInfo",
                            targetType: .View
                        )
                        
                        let groupChatInfoViewController = GroupChatInfoViewController()
                        groupChatInfoViewController.conv = strongSelf.conv
                        groupChatInfoViewController.didCreateNewChat = { ack, convType in
                            if let convKey = ack.data {
                                strongSelf.reloadConversation(Conv(convKey: convKey))
                            }
                        }
                        
                        strongSelf.navigationController?.push(groupChatInfoViewController, animated: true)
                    }
                    })
                optionMenu.addAction(groupChatInfoAction)
                break
                
            case ChatOptionMenu.customerInfoPage.rawValue:
                
                let customerInfoAction = UIAlertAction(title: String.localize("LB_CUST_INFO"), style: .default, handler: { [weak self] (alert: UIAlertAction!) -> Void in
                    if let strongSelf = self {
                        Log.debug("customer info")
                        
                        // Action tag
                        strongSelf.view.analyticsViewKey = strongSelf.analyticsViewRecord.viewKey
                        strongSelf.view.recordAction(
                            .Tap,
                            sourceRef: "CustomerInfo",
                            sourceType: .Button,
                            targetRef: "CustomerInfo",
                            targetType: .View
                        )
                        
                        let imCustomerInfoViewController = IMCustomerInfoViewController()
                        imCustomerInfoViewController.conv = strongSelf.conv
                        imCustomerInfoViewController.productAttachedHandler = {[weak self] (data) in
                            if let strongSelf = self {
                                let productModel = ProductModel()
                                
                                strongSelf.showLoading()
                                
                                firstly {
                                    return ProductManager.searchStyleWithSkuId(data.skuId)
                                    }.then { response -> Void in
                                        if let style = response as? Style {
                                            
                                            for viewController in (strongSelf.navigationController?.viewControllers)! {
                                                if let chatViewController = viewController as? TSChatViewController {
                                                    strongSelf.navigationController?.popToViewController(chatViewController, animated: true)
                                                    break
                                                }
                                            }
                                            
                                            productModel.style = style
                                            productModel.sku = style.defaultSku()
                                            
                                            let chatModel = ChatModel.init(productModel: productModel)
                                            chatModel.messageContentType = MessageContentType.Product
                                            
                                            strongSelf.forwardChatModel = chatModel
                                            
                                            var targetType: AnalyticsActionRecord.ActionElement = .ChatCustomer
                                            if let conv = strongSelf.conv {
                                                if conv.isFriendChat() {
                                                    targetType = .ChatFriend
                                                } else if conv.isInternalChat() {
                                                    targetType = .ChatInternal
                                                }
                                            }
                                            // Action tag
                                            strongSelf.view.analyticsViewKey = strongSelf.analyticsViewRecord.viewKey
                                            strongSelf.view.recordAction(
                                                .Send,
                                                sourceRef: chatModel.productModel?.style?.styleCode,
                                                sourceType: .Product,
                                                targetRef: strongSelf.conv?.convKey,
                                                targetType: targetType
                                            )
                                            
                                            strongSelf.forwardPendingMessage()
                                        } else {
                                            ErrorLogManager.sharedManager.recordNonFatalError(withException: .NullPointer)
                                        }
                                    }.always {
                                        strongSelf.stopLoading()
                                    }.catch { _ -> Void in
                                        Log.error("error")
                                }
                            }
                        }
                        
                        strongSelf.navigationController?.push(imCustomerInfoViewController, animated: true)
                    } else {
                        ErrorLogManager.sharedManager.recordNonFatalError(withException: .NullPointer)
                    }
                    })
                
                optionMenu.addAction(customerInfoAction)
                break
                
            case ChatOptionMenu.forwardChat.rawValue:
                
                let forwardChatAction = UIAlertAction(title: String.localize("LB_CS_FORWARD_CHAT_TO"), style: .default, handler: { [weak self] (alert: UIAlertAction!) -> Void in
                    if let strongSelf = self, let conv = strongSelf.conv {
                        Log.debug("forward chat")
                        // Action tag
                        strongSelf.view.analyticsViewKey = strongSelf.analyticsViewRecord.viewKey
                        strongSelf.view.recordAction(
                            .Tap,
                            sourceRef: "MessageForward",
                            sourceType: .Button,
                            targetRef: "MessageForward",
                            targetType: .View
                        )
                        
                        let forwardChatVC = ForwardChatViewController()
                        forwardChatVC.conv = conv
                        
                        if let merchant = strongSelf.conv?.myMerchantObject() {
                            forwardChatVC.pickedMerchant = (merchant, conv.queue)
                        }
                        
                        forwardChatVC.finishedForwardingChat = { stayOn in
                            if stayOn {
                                strongSelf.showSuccessPopupWithText(String.localize("MSG_SUC_CS_FORWARD_CHAT"))
                            }
                            else {
                                strongSelf.navigationController?.popViewController(animated: false)
                            }
                        }
                        
                        forwardChatVC.finishedTransferChat = { stayOn, convKey in
                            if stayOn {
                                strongSelf.finishedTransferChat?(stayOn, convKey)
                            }
                            else {
                                strongSelf.showSuccessPopupWithText(String.localize("MSG_SUC_CS_FORWARD_CHAT"))
                            }
                        }
                        
                        let navigationController = MmNavigationController(rootViewController: forwardChatVC)
                        strongSelf.present(navigationController, animated: true, completion: nil)
                    } else {
                        ErrorLogManager.sharedManager.recordNonFatalError(withException: .NullPointer)
                    }
                    })
                
                optionMenu.addAction(forwardChatAction)
                break
                
            case ChatOptionMenu.flagUnflagChat.rawValue:
                
                if let conv = self.conv {
                    
                    let flagUnflagChatAction = UIAlertAction(title:
                        conv.isFollowUp() ? String.localize("LB_CS_CHAT_UNFLAG"): String.localize("LB_CS_FOLLOW_UP"), style: .default, handler: { [weak self] (alert: UIAlertAction!) -> Void in
                            if let strongSelf = self {
                                Log.debug("flag/Unflag chat")
                                
                                var targetType: AnalyticsActionRecord.ActionElement = .ChatCustomer
                                if conv.isFriendChat() {
                                    targetType = .ChatFriend
                                } else if conv.isInternalChat() {
                                    targetType = .ChatInternal
                                }
                                
                                if conv.isFollowUp() {
                                    // Action tag
                                    strongSelf.view.analyticsViewKey = strongSelf.analyticsViewRecord.viewKey
                                    strongSelf.view.recordAction(
                                        .Tap,
                                        sourceRef: "CancelFollowup",
                                        sourceType: .Button,
                                        targetRef: conv.convKey,
                                        targetType: targetType
                                    )
                                    
                                    WebSocketManager.sharedInstance().sendMessage(
                                        IMConvUnFlagMessage(
                                            convKey: conv.convKey,
                                            myUserRole: conv.myUserRole
                                        ),
                                        checkNetwork: true,
                                        viewController: strongSelf,
                                        completion: { (ack) in
                                            if let me = conv.me {
                                                conv.userListFlag.remove(me.userKey)
                                                strongSelf.createRightBarButton()
                                                if let titleString = strongSelf.displayTitle() {
                                                    strongSelf.title = titleString
                                                }
                                            } else {
                                                ErrorLogManager.sharedManager.recordNonFatalError(withException: .NullPointer)
                                            }
                                        }
                                    )
                                    
                                    
                                } else {
                                    // Action tag
                                    strongSelf.view.analyticsViewKey = strongSelf.analyticsViewRecord.viewKey
                                    strongSelf.view.recordAction(
                                        .Tap,
                                        sourceRef: "Followup",
                                        sourceType: .Button,
                                        targetRef: conv.convKey,
                                        targetType: targetType
                                    )
                                    
                                    WebSocketManager.sharedInstance().sendMessage(
                                        IMConvFlagMessage(
                                            convKey: conv.convKey,
                                            myUserRole: conv.myUserRole
                                        ),
                                        checkNetwork: true,
                                        viewController: strongSelf,
                                        completion: { (ack) in
                                            if let me = conv.me {
                                                conv.userListFlag.append(me.userKey)
                                                strongSelf.createRightBarButton()
                                                if let titleString = strongSelf.displayTitle() {
                                                    strongSelf.title = titleString
                                                }
                                            } else {
                                                ErrorLogManager.sharedManager.recordNonFatalError(withException: .NullPointer)
                                            }
                                        }
                                    )
                                }
                            } else {
                                ErrorLogManager.sharedManager.recordNonFatalError(withException: .NullPointer)
                            }
                        })
                    
                    optionMenu.addAction(flagUnflagChatAction)
                    
                }
                break
                
            case ChatOptionMenu.closeChat.rawValue:
                
                let closeChatAction = UIAlertAction(title: String.localize("LB_CS_CLOSE_CHAT"), style: .default, handler: { [weak self] (alert: UIAlertAction!) -> Void in
                    if let strongSelf = self {
                        Log.debug("close chat")
                        
                        let alert = UIAlertController(title: String.localize("LB_CS_CLOSE_CHAT"), message: String.localize("LB_CS_CLOSE_CHAT_CONF"), preferredStyle: UIAlertControllerStyle.alert)
                        
                        alert.addTextField(configurationHandler: strongSelf.configurationTextField)
                        
                        alert.addAction(UIAlertAction(title: String.localize("LB_CANCEL"), style: UIAlertActionStyle.cancel, handler: nil))
                        alert.addAction(UIAlertAction(title: String.localize("LB_CLOSE"), style: UIAlertActionStyle.default, handler:{ (UIAlertAction)in
                            
                            var targetType: AnalyticsActionRecord.ActionElement = .ChatCustomer
                            if let conv = strongSelf.conv {
                                if conv.isFriendChat() {
                                    targetType = .ChatFriend
                                } else if conv.isInternalChat() {
                                    targetType = .ChatInternal
                                }
                            }
                            // Action tag
                            strongSelf.view.analyticsViewKey = strongSelf.analyticsViewRecord.viewKey
                            strongSelf.view.recordAction(
                                .Tap,
                                sourceRef: "CloseChat",
                                sourceType: .Button,
                                targetRef: strongSelf.conv?.convKey,
                                targetType: targetType
                            )
                            
                            if let comment = strongSelf.convCloseTextfield?.text, comment.isEmpty == false {
                                
                                let commentModel = CommentModel()
                                commentModel.comment = comment
                                commentModel.status = CommentStatus.Closed
                                commentModel.merchantId = strongSelf.conv?.myMerchantObject()?.merchantId
                                let chatModel = ChatModel(commentModel: commentModel)
                                strongSelf.forwardChatModel = chatModel
                                strongSelf.forwardPendingMessage()
                            }
                            strongSelf.sendConversationClose()
                            strongSelf.navigationController?.popToRootViewController(animated: true)
                        }))
                        strongSelf.present(alert, animated: true, completion: nil)
                    } else {
                        ErrorLogManager.sharedManager.recordNonFatalError(withException: .NullPointer)
                    }
                    })
                
                optionMenu.addAction(closeChatAction)
                break
                
            case ChatOptionMenu.merchantInfoPage.rawValue:
                
                let groupChatInfoAction = UIAlertAction(title: String.localize("LB_CA_IM_CHAT_MERC_PROF"), style: .default, handler: { [weak self] (alert: UIAlertAction!) -> Void in
                    
                    guard let strongSelf = self else {
                        ErrorLogManager.sharedManager.recordNonFatalError(withException: .NullPointer)
                        return
                    }
                    
                    if let merchant = strongSelf.conv?.merchantObject {
                        Navigator.shared.dopen(Navigator.mymm.website_merchant_merchantId + "\(merchant.merchantId)")
                    }

                    })
                optionMenu.addAction(groupChatInfoAction)
                
                
            default:
                break
            }
        }
        
        let cancelAction = UIAlertAction(title: String.localize("LB_CANCEL"), style: .cancel, handler: nil)
        optionMenu.addAction(cancelAction)
        
        optionMenu.view.tintColor = UIColor.secondary2()
        
        self.present(optionMenu, animated: true, completion: nil)
        optionMenu.view.tintColor = UIColor.alertTintColor()
    }
    
    func configurationTextField(_ textField: UITextField!)
    {
        if let tField = textField {
            //Save reference to the UITextField
            self.convCloseTextfield = tField
            self.convCloseTextfield!.placeholder = String.localize("LB_CS_COMMENT_TEXTBOX")
        } else {
            ErrorLogManager.sharedManager.recordNonFatalError(withException: .NullPointer)
        }
    }
    
    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        self.listTableView.contentInset = UIEdgeInsets(top: 15, left: 0, bottom: 0, right: 0)
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        
        self.keyboardControl()
        
        NotificationCenter.default.addObserver(self, selector: #selector(TSChatViewController.keyboardWillShow), name: NSNotification.Name.UIKeyboardWillShow, object: nil);
        NotificationCenter.default.addObserver(self, selector: #selector(TSChatViewController.keyboardDidShow), name: NSNotification.Name.UIKeyboardDidShow, object: nil);
        NotificationCenter.default.addObserver(self, selector: #selector(TSChatViewController.keyboardWillHide), name: NSNotification.Name.UIKeyboardWillHide, object: nil);
        NotificationCenter.default.addObserver(self, selector: #selector(TSChatViewController.willHideEditMenu), name: NSNotification.Name.UIMenuControllerWillHideMenu, object: nil);
        
        NotificationCenter.default.addObserver(self, selector: #selector(TSChatViewController.didWebsocketConnected), name: NSNotification.Name(rawValue: IMDidWebsocketConnected), object: nil)
        
        NotificationCenter.default.addObserver(self, selector: #selector(TSChatViewController.applicationWillResignActive), name: NSNotification.Name.UIApplicationWillResignActive, object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(TSChatViewController.applicationDidBecomeActive), name: NSNotification.Name.UIApplicationDidBecomeActive, object: nil)
        
        NotificationCenter.default.addObserver(self, selector: #selector(handleCellExpand), name: Constants.Notification.reloadChatScreen, object: nil)
        startAllAnimations()
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        
        stopAllAnimations()
        
        NotificationCenter.default.removeObserver(self, name: NSNotification.Name.UIKeyboardWillShow, object: nil)
        NotificationCenter.default.removeObserver(self, name: NSNotification.Name.UIKeyboardWillHide, object: nil)
        NotificationCenter.default.removeObserver(self, name: NSNotification.Name.UIMenuControllerWillHideMenu, object: nil)
        NotificationCenter.default.removeObserver(self, name: NSNotification.Name.UIMenuControllerWillHideMenu, object: nil)
        NotificationCenter.default.removeObserver(self, name: Constants.Notification.reloadChatScreen, object: nil)
        AudioPlayInstance.stopPlayer()
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        
        //初次进入时需要调整页面
        adjustKeyboardHeight()
    }
    
    private func adjustKeyboardHeight() {
        if IsIphoneX {
            let offset:CGFloat = 18
            var fm = self.listTableView.frame
            fm.size.height = self.view.bounds.size.height - ScreenBottom - ScreenTop - 64 - 44 + offset
            self.listTableView.frame = fm
            self.listTableView.contentInset = UIEdgeInsets(top: offset, left: 0, bottom: 0, right: 0)
            self.listTableView.scrollBottomToLastRow()
        }
    }
    
    override func viewDidDisappear(_ animated: Bool) {
        super.viewDidDisappear(animated)
        
        self.removeKeyboardControl()

        NotificationCenter.default.removeObserver(self, name: NSNotification.Name.UIApplicationDidBecomeActive, object: nil)
        NotificationCenter.default.removeObserver(self, name: NSNotification.Name.UIApplicationWillResignActive, object: nil)
    }
    
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    func displayTitle() -> String? {
        
        var title : String?
        
        if let conv = self.conv {
            if let groupChatName = conv.convName {
                return groupChatName
            }
            
            if conv.convType == .Customer && conv.merchantId == Constants.MMMerchantId && conv.IAmCustomer() {
                if let merchantId = conv.merchantId {
                    
                    if merchantId == 0 {
                        title = Merchant.MM().merchantName
                    }
                    else {
                        CacheManager.sharedManager.merchantById(merchantId, completion: { [weak self] (merchant) in
                            if let strongSelf = self, let merchant = merchant {
                                title = merchant.merchantName
                                strongSelf.title = title
                            }
                            })
                    }
                }
            }
            else if !conv.isGroupChat(){
                if (conv.isInternalChat()) {
                    if conv.presenter == nil {
                        let merchantName = conv.merchantObject?.merchantName ?? ""
                        title = QueueStatistics.queueText(conv.queue) + "(\(merchantName))"
                    }
                    else if let displayName = conv.presenter?.displayName, let merchantName = conv.presentMerchant?.merchantName {
                        title = displayName + "(\(merchantName))"
                    }
                } else if (conv.isCustomerChat()) {
                    if (conv.IAmCustomer()) {
                        if conv.merchantId == Constants.MMMerchantId {
                            title = Merchant.MM().merchantName
                        } else if let merchantName = conv.merchantObject?.merchantName {
                            title = merchantName
                        }
                    } else {
                        if let displayName = conv.presenter?.displayName {
                            title = displayName
                        }
                    }
                } else {
                    if let displayName = conv.presenter?.displayName {
                        title = displayName
                    }
                }
            } else {
                var userListString = ""
                var merchantList:[String] = []
                for userRole in conv.otherUserRoleList {
                    var userName = ""
                    
                    if let user = userRole.userObj {
                        if (conv.IAmAgent()) {
                            if let merchant = userRole.merchantObj {
                                userName = user.displayName + "(\(merchant.merchantName))" + ", "
                            } else {
                                userName = user.displayName + ", "
                            }
                        } else if (conv.IAmCustomer()) {
                            if let merchant = userRole.merchantObj {
                                if merchant.merchantId == Constants.MMMerchantId {
                                    title = Merchant.MM().merchantName + ", "
                                } else if (!merchantList.contains(merchant.merchantName)) {
                                    userName = merchant.merchantName + ", "
                                    merchantList.append(merchant.merchantName)
                                }
                            } else {
                                userName = user.displayName + ", "
                            }
                        } else {
                            userName = user.displayName + ", "
                        }
                        userListString += userName
                    }
                }
                
                if userListString.length > 1 {
                    let index = userListString.index(userListString.endIndex, offsetBy: -2)
                    userListString = String(userListString[..<index])
                    
                    userListString += "(\(conv.userList.count))"
                    var width = Constants.ScreenSize.SCREEN_WIDTH
                    if width > 375 {
                        width -= 8
                    }
                    if let conv = self.conv, conv.isFollowUp() == true && !conv.isClosed() && checkChatOptionMenuToShowMoreButton() {
                        width -= 162
                    } else if checkChatOptionMenuToShowMoreButton() {
                        width -= 119
                    } else if let conv = self.conv, conv.isFollowUp() == true && !conv.isClosed() {
                        width -= 124
                    } else {
                        width -= 75
                    }
                    
                    if let font = self.navigationController?.navigationBar.titleTextAttributes?[NSAttributedStringKey.font] as? UIFont {
                        userListString = (userListString as NSString).truncating(at: "(", toWidth: width, with: font)
                    }
                    else {
                        let defaultFont = UIFont.systemFont(ofSize: 16)
                        userListString = (userListString as NSString).truncating(at: "(", toWidth: width, with: defaultFont)
                    }
                    
                    title = userListString
                }
            }
        } else {
            ErrorLogManager.sharedManager.recordNonFatalError(withException: .NullPointer)
        }
        
        return title
    }
    
    func configMessage(_ message: ChatModel) {
        if let conv = self.conv, let userKey = message.chatSendId, let user = conv.userForKey(userKey) {
            message.chatSenderProfileKey = user.profileImage
        }
    }
    
    func reloadMessages() {
        
        for message in itemDataSouce {
            configMessage(message)
        }
    }
    
    func reloadConversation(_ conv: Conv) {
        self.conv = conv
        
        itemDataSouce.removeAll()
        imageDataSouce.removeAll()
        
        fetchHistory { [weak self] (request, response) in
            if let strongSelf = self {
                strongSelf.handleIncomingHistory(request: request, response: response)
            } else {
                ErrorLogManager.sharedManager.recordNonFatalError(withException: .NullPointer)
            }
        }
        
        reloadConversation()
        
    }
    
    func reloadConversation() {
        
        if let convKey = self.conv?.convKey, let conv = WebSocketManager.sharedInstance().conversationForKey(convKey) {
            self.conv = conv
        }
        
        if let titleString = displayTitle() {
            self.title = titleString
        }
        
        var enabled = true
        if let conv = self.conv, conv.IAmAgent() && conv.isClosed() == true {
            enabled = false
        }
        
        if checkChatOptionMenuToShowMoreButton() {
            createRightBarButton()
        }
        else {
            self.navigationItem.rightBarButtonItems = nil
        }
        
        let enableInputs = { (enabled: Bool) in
            self.chatActionBarView.messageButton.isEnabled = enabled
            self.chatActionBarView.shareButton.isEnabled = enabled
            self.chatActionBarView.recordButton.isEnabled = enabled
            self.chatActionBarView.inputTextView.isUserInteractionEnabled = enabled
            self.navigationItem.rightBarButtonItem?.isEnabled = enabled
        }
        enableInputs(enabled)
        
        reloadMessages()
        
        setupBackgroundImage()
        
        listTableView.reloadData()
        
        //调整高度
        adjustKeyboardHeight()
    }
    
    @objc func conversationListUpdated(_ notification: Notification) {
        reloadConversation()
    }
    
    //MARK: TSChatCellDelegate
    func forwardTextDidTapped(_ string: String) {
        let contactListVC = ContactListViewController()
        contactListVC.isAgent = false
        contactListVC.friendListMode = .shareMode
        
        let chatModel = ChatModel(text: string)
        chatModel.chatSendId = Context.getUserKey()
        contactListVC.chatModel = chatModel
        contactListVC.isFromUserChat = true
        self.navigationController?.push(contactListVC, animated: true)
        
        contactListVC.didPopHandler = { [weak self] friend, chatModel in
            if let strongSelf = self {
                if let callback = strongSelf.didPopHandler {
                    if let nav = strongSelf.navigationController {
                        for c in nav.viewControllers {
                            if c is IMViewController {
                                strongSelf.navigationController?.popToViewController(c, animated: false)
                                break
                            }
                        }
                    }
                    callback(friend, chatModel)
                } else {
                    ErrorLogManager.sharedManager.recordNonFatalError(withException: .NullPointer)
                }
            } else {
                ErrorLogManager.sharedManager.recordNonFatalError(withException: .NullPointer)
            }
        }
    }
    
    func forwardImageDidTaped(_ image: UIImage) {
        Log.debug("forwardImageDidTaped")
        
        let contactListVC = ContactListViewController()
        contactListVC.isAgent = false
        contactListVC.friendListMode = .shareMode
        
        let sendImageModel = ChatImageModel(image: image)
        let storeKey = "send_image"+String(format: "%f", Date.milliseconds)
        sendImageModel.localStoreName = storeKey
        let chatModel = ChatModel(imageModel:sendImageModel)
        chatModel.chatSendId = Context.getUserKey()
        contactListVC.chatModel = chatModel
        contactListVC.isFromUserChat = true
        self.navigationController?.push(contactListVC, animated: true)
        
        contactListVC.didPopHandler = { [weak self] friend, chatModel in
            if let strongSelf = self {
                if let callback = strongSelf.didPopHandler {
                    if let nav = strongSelf.navigationController {
                        for c in nav.viewControllers {
                            if c is IMViewController {
                                strongSelf.navigationController?.popToViewController(c, animated: false)
                                break
                            }
                        }
                    }
                    callback(friend, chatModel)
                } else {
                    ErrorLogManager.sharedManager.recordNonFatalError(withException: .NullPointer)
                }
            } else {
                ErrorLogManager.sharedManager.recordNonFatalError(withException: .NullPointer)
            }
        }
    }
    
    func saveImageDidTaped(_ image: UIImage) {
        Log.debug("saveImageDidTaped")
        CustomAlbumHelper.saveImageToAlbum(image) { [weak self] (success, error) in
            if let strongSelf = self {
                if success {
                    strongSelf.showSaveImageSuccessPopup()
                } else {
                    strongSelf.showSaveImageFailedPopup()
                }
            }
        }
    }
    
    func forwardUserDidTaped(_ user: User) {
        let contactListVC = ContactListViewController()
        contactListVC.isAgent = false
        contactListVC.friendListMode = .shareMode
        
        let userModel = UserModel()
        userModel.user = user
        
        let chatModel = ChatModel.init(userModel: userModel)
        chatModel.messageContentType = MessageContentType.ShareUser
        chatModel.chatSendId = Context.getUserKey()
        contactListVC.chatModel = chatModel
        contactListVC.isFromUserChat = true
        self.navigationController?.push(contactListVC, animated: true)
        
        contactListVC.didPopHandler = { [weak self] friend, chatModel in
            if let strongSelf = self {
                if let callback = strongSelf.didPopHandler {
                    if let nav = strongSelf.navigationController {
                        for c in nav.viewControllers {
                            if c is IMViewController {
                                strongSelf.navigationController?.popToViewController(c, animated: false)
                                break
                            }
                        }
                    }
                    callback(friend, chatModel)
                } else {
                    ErrorLogManager.sharedManager.recordNonFatalError(withException: .NullPointer)
                }
            } else {
                ErrorLogManager.sharedManager.recordNonFatalError(withException: .NullPointer)
            }
        }
        
        Log.debug("forwardUserDidTaped")
    }
    
    func resendMessage(_ model: ChatModel) {
        
        let retryMenu = UIAlertController(title: String.localize("IM_MSG_NO_SEND"), message: nil, preferredStyle: .actionSheet)
        retryMenu.addAction(
            UIAlertAction(
                title: String.localize("LB_CA_IM_MSG_FAILED_RESEND"),
                style: .default,
                handler: { [weak self] (action) in
                    if let strongSelf = self, let message = model.requestMessage(strongSelf.conv?.myUserRole) {
                        WebSocketManager.sharedInstance().sendMessage(
                            message,
                            completion: { (ack) in
                                strongSelf.itemDataSouce.remove(model)
                                strongSelf.listTableView.reloadData()
                            }
                        )
                    } else {
                        ErrorLogManager.sharedManager.recordNonFatalError(withException: .NullPointer)
                    }
                }
            )
        )
        
        retryMenu.addAction(
            UIAlertAction(
                title: String.localize("LB_AC_DELETE"),
                style: .default,
                handler: { [weak self] (action) in
                    if let strongSelf = self {
                        CacheManager.sharedManager.deleteMsg(model.correlationKey)
                        strongSelf.itemDataSouce.remove(model)
                        strongSelf.imageDataSouce.remove(model)
                        strongSelf.listTableView.reloadData()
                    } else {
                        ErrorLogManager.sharedManager.recordNonFatalError(withException: .NullPointer)
                    }
                }
            )
        )
        
        retryMenu.addAction(
            UIAlertAction(
                title: String.localize("LB_CA_CANCEL"),
                style: .cancel,
                handler: nil
            )
        )
        
        self.present(retryMenu, animated: true, completion: nil)
        retryMenu.view.tintColor = UIColor.alertTintColor()
    }
    
    func forwardVoiceDidTaped(_ audioModel: ChatAudioModel) {
        Log.debug("forwardVoiceDidTaped")
        
        let chatModel = ChatModel.init(audioModel: audioModel)
        chatModel.chatSendId = Context.getUserKey()
        
        let contactListVC = ContactListViewController()
        contactListVC.isAgent = false
        contactListVC.friendListMode = .shareMode
        contactListVC.chatModel = chatModel
        contactListVC.isFromUserChat = true
        
        self.navigationController?.push(contactListVC, animated: true)
        
        contactListVC.didPopHandler = { [weak self] friend, chatModel in
            if let strongSelf = self {
                if let callback = strongSelf.didPopHandler {
                    if let nav = strongSelf.navigationController {
                        for c in nav.viewControllers {
                            if c is IMViewController {
                                strongSelf.navigationController?.popToViewController(c, animated: false)
                                break
                            }
                        }
                    }
                    callback(friend, chatModel)
                } else {
                    ErrorLogManager.sharedManager.recordNonFatalError(withException: .NullPointer)
                }
            } else {
                ErrorLogManager.sharedManager.recordNonFatalError(withException: .NullPointer)
            }
        }
    }
    
    func killAudioRecording() {
        AudioRecordManager.sharedInstance.stopRecord()
        shareMoreView.isUserInteractionEnabled = true
        messageView.isUserInteractionEnabled = true
        listTableView.isUserInteractionEnabled = true
        self.navigationController?.navigationBar.isUserInteractionEnabled = true
    }

    override func shouldHaveCollectionView() -> Bool {
        return false
    }
    
    func optionMenuConfig() -> [ChatOptionMenu]? {
        var menu: [ChatOptionMenu]?
        if let conv = self.conv {
            if conv.convType == .Private {
                menu = [
                    .chatInfoPage
                ]
            }
            else if conv.convType == .Customer && conv.IAmCustomer() {
                if conv.merchantId == Constants.MMMerchantId {
                    menu = [
                    ]
                }
                else {
                    menu = [
                        .merchantInfoPage
                    ]
                }
            }
            else if conv.convType == .Customer && (conv.IAmAgent() || conv.IAmMM()) {
                if conv.isGroupChat() {
                    menu = [
                        .chatInfoPage,
                        .customerInfoPage,
                        .flagUnflagChat
                    ]
                    if (conv.isOwner()) {
                        menu?.append(.closeChat)
                    }
                } else {
                    menu = [
                        .chatInfoPage,
                        .customerInfoPage,
                        .forwardChat,
                        .flagUnflagChat,
                        .closeChat
                    ]
                }
            } else if conv.convType == .Internal {
                menu = [
                    .chatInfoPage,
                    .flagUnflagChat,
                    .closeChat
                ]
            } else {
                menu = [
                    .chatInfoPage
                ]
            }
        }
        return menu
    }

}

extension TSChatViewController {
    
    //MARK: IM Notifcation Event
    @objc func didReceiveMessage(_ notification: Notification) {
        if let userInfo = notification.userInfo, let chatMessage = userInfo[IMMessageKey] as? ChatModel {
            receiveMessage(chatMessage)
        }
    }
    
    func receiveMessage(_ chatMessage: ChatModel) {
        
        if let conv = self.conv, !conv.shouldShowComment(chatMessage) {
            return
        }
        
        configMessage(chatMessage)
        
        if let convKey = chatMessage.convKey, convKey == conv?.convKey {
            
            if let index = self.itemDataSouce.index(where: { (ele) -> Bool in return ele == chatMessage }) {
                
                let oldChatModel = self.itemDataSouce.remove(at: index)
                chatMessage.tag = oldChatModel.tag
                self.itemDataSouce.append(chatMessage)
                self.listTableView.reloadData()
                
            } else {
                dispatch_async_safely_to_main_queue({
                    self.itemDataSouce.append(chatMessage)
                    
                    if chatMessage.messageContentType == .Image || chatMessage.messageContentType == .ImageUUID || chatMessage.messageContentType == .ForwardImage {
                        chatMessage.tag = self.imageDataSouce.count
                        self.imageDataSouce.append(chatMessage)
                    }
                    let insertIndexPath = IndexPath(row: self.itemDataSouce.count - 1, section: 0)
                    self.listTableView.insertRowsAtBottom([insertIndexPath])
                })
            }
            
        }
        
    }
    
    typealias AnalysisResult = (result: [ChatModel], latest: ChatModel?, oldest: ChatModel?)
    
    func analysisDataSource(_ conv: Conv, messages: [ChatModel]) -> AnalysisResult {
        
        var latest: ChatModel?
        var oldest: ChatModel?
        var result = [ChatModel]()
        
        for message in messages {
            
            let sameConv = conv.convKey.length > 0 && message.convKey == conv.convKey
            let loadMore = message.messageContentType == .LoadMore
            let timestamp = message.messageContentType == .Time
            
            if !sameConv || loadMore || timestamp {
                continue
            }
            
            result.append(message)
            
            if latest == nil || message > latest! {
                latest = message
            }
            
            if oldest == nil || message < oldest! {
                oldest = message
            }
            
        }
        
        return AnalysisResult(result, latest, oldest)
        
    }
    
    func handleIncomingHistory(request: IMMsgListRequestMessage, response res: IMMsgListResponseMessage?) {
        
        guard let response = res else {
            return
        }
        
        let messages = response.messageList
        
        let more = { () -> Bool in
            
            let pageStart = request.pageStart
            
            if let message = messages.first, messages.count == 1 { // inclusive cases
                return message.timeDate != pageStart
            } else if messages.count == 0 { // init case
                return false
            }
            // other cases
            return true
        } ()
        
        
        processHistory(messages, more: more)
        
        forwardPendingMessage()
    }
    
    func processHistory(_ messages: [ChatModel], more: Bool) {
        
        guard let conv = self.conv else {
            return
        }
        
        var scrollingPosition = UITableViewScrollPosition.bottom
        
        var oldest: ChatModel?
        
        let currentSource = analysisDataSource(conv, messages: itemDataSouce)
        
        let newSource = analysisDataSource(conv, messages: messages)
        
        if currentSource.result.count == 0 {
            
            // use the new data source range
            oldest = newSource.oldest
            
        } else {
            
            // if discontinuous, only show the latest one
            let discontinuous = { (s1: AnalysisResult, s2: AnalysisResult) -> Bool in
                guard let latest = s1.latest, let oldest = s2.oldest else {
                    return false
                }
                return latest < oldest
            }
            
            // if continuous, need to merge 2 data sources
            let continuous = { (s1: AnalysisResult, s2: AnalysisResult) -> Bool in
                guard let s1latest = s1.latest, let s1oldest = s1.oldest, let s2latest = s2.latest, let s2oldest = s2.oldest else {
                    return false
                }
                return s1latest >= s2oldest || s1oldest <= s2latest
            }
            
            if discontinuous(currentSource, newSource) {
                
                // use the new data source range
                oldest = newSource.oldest
                
            } else if continuous(currentSource, newSource) {
                
                // user the merged range
                oldest = newSource.oldest
                if currentSource.oldest! < newSource.oldest! {
                    oldest =  currentSource.oldest
                }
                
                scrollingPosition = .none
                
            } else {
                
                // no data?
                
            }
            
        }
        
        let rangeResult = CacheManager.sharedManager.cachedMessageForConv(
            conv,
            oldestModel: oldest
        )
        
        var previousMessage: ChatModel?
        var finalResult = [ChatModel]()
        var imageSource = [ChatModel]()
        
        for message in rangeResult {
            
            if !conv.shouldShowComment(message) {
                continue
            }
            
            configMessage(message)
            
            if message.messageContentType == MessageContentType.Image ||
                message.messageContentType == MessageContentType.ImageUUID ||
                message.messageContentType == MessageContentType.ForwardImage {
                
                message.tag = imageSource.count
                imageSource.append(message)
                
            }
            
            if previousMessage == nil || message.shouldDisplayTimstampBetween(previousMessage!) {
                finalResult.append(ChatModel(timeDate: message.timeDate))
            }
            
            finalResult.append(message)
            previousMessage = message
        }
        
        if more {
            loadMore.needToLoadMore = true
            finalResult.insert(loadMore, at: 0)
        }
        
        itemDataSouce = finalResult
        imageDataSouce = imageSource
        
        // scroll position
        
        let offset = self.listTableView.contentOffset
        
        if scrollingPosition == .none {
            
            // keep existing scroll position
            
            let height = self.listTableView.contentSize.height
            
            self.listTableView.reloadData()
            let offsetY = self.listTableView.contentSize.height - height + offset.y
            self.listTableView.setContentOffset(CGPoint(x: offset.x, y: offsetY >= 0 ? offsetY : 0), animated: false)
            
        } else {
            
            // go to bottom
            
            self.listTableView.reloadData()
            if self.listTableView.contentSize.height > self.listTableView.frame.height {
                self.listTableView.scrollBottomToLastRow()
            } else {
                if !itemDataSouce.isEmpty {
                    self.listTableView.scrollToTop()
                }
            }
            
        }
        
    }
    
    func forwardPendingMessage() {
        if self.forwardChatModel != nil {
            switch self.forwardChatModel!.messageContentType {
            case .Text:
                if let content = self.forwardChatModel?.messageContent {
                    self.sendText(content, myUserRole: self.conv?.myUserRole)
                }
                break
            case .Image:
                if let image = self.forwardChatModel?.imageModel?.image {
                    self.resizeAndSendImage(image)
                }
                break
            case .ShareUser:
                if let userModel = self.forwardChatModel?.userModel {
                    self.sendShareModel(userModel)
                }
                break
            case .ShareMerchant:
                if let merchantModel = self.forwardChatModel?.merchantModel {
                    self.sendShareModel(merchantModel)
                }
                break
            case .ShareBrand:
                if let brandModel = self.forwardChatModel?.brandModel {
                    self.sendShareModel(brandModel)
                }
                break
            case .Product:
                if let productModel = self.forwardChatModel?.productModel {
                    self.sendShareModel(productModel)
                }
                break
            case .VoiceUUID:
                if let audioModel = self.forwardChatModel?.audioModel {
                    self.sendShareModel(audioModel)
                }
                break
            case .ShareOrder:
                if let orderModel = self.forwardChatModel?.orderModel {
                    self.sendShareModel(orderModel)
                }
                break
            case .Comment:
                if let commentModel = self.forwardChatModel?.commentModel {
                    self.sendShareModel(commentModel)
                }
                break
            case .SharePost:
                if let postModel = self.forwardChatModel?.model as? PostModel {
                    self.sendShareModel(postModel)
                }
                break
            case .SharePage:
                if let magazineCoverModel = self.forwardChatModel?.model as? MagazineCoverModel {
                    self.sendShareModel(magazineCoverModel)
                }
                break
            case .Coupon:
                if let couponModel = self.forwardChatModel?.model as? CouponModel{
                    self.sendShareModel(couponModel)
                }
                break
            case .Shipment:
                if let shipmentModel = self.forwardChatModel?.shipmentModel {
                    self.sendShareModel(shipmentModel)
                }
                break
            case .MasterCoupon :
                if let model = self.forwardChatModel {
                    self.sendMasterCoupon(model)
                }
                
            default:
                break
            }
            
            self.forwardChatModel = nil
        }
    }
    
    @objc func changeAlias() {
        if let title = displayTitle() {
            self.title = title
        }
    }
    
}

// MARK: - @protocol UITableViewDataSource
extension TSChatViewController: UITableViewDataSource, UITableViewDelegate {
    func numberOfSections(in tableView: UITableView) -> Int {
        return 1
    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return self.itemDataSouce.count
    }
    
    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        guard let chatModel = self.itemDataSouce.get(indexPath.row) else {
            return 0
        }
        let type: MessageContentType = chatModel.messageContentType
        return type.chatCellHeight(chatModel)
    }
    
    @objc func showThankYouPage() {
        let thankYouViewController = ThankYouViewController()
        thankYouViewController.fromViewController = self
        thankYouViewController.parentOrder = paidOrder
        let navigationController = MmNavigationController(rootViewController: thankYouViewController)
        navigationController.modalPresentationStyle = .overFullScreen
        
        self.present(navigationController, animated: true, completion: nil)
        self.stopLoading()
    }
    
    private func showCheckoutActionSheet(withStyle style: Style, referrerUserKey: String?) {
        firstly {
            self.fetchMerchant(style.merchantId)
            }.then { merchant -> Void in
                if let merchant = merchant as? Merchant {
                    let checkoutViewController = FCheckoutViewController(checkoutMode: .style, merchant: merchant, style: style, referrer: referrerUserKey)
                    
                    checkoutViewController.didDismissHandler = { [weak self] confirmed, parentOrder in
                        if let strongSelf = self {
                            strongSelf.updateButtonCartState()
                            strongSelf.updateButtonWishlistState()
                            
                            if confirmed {
                                strongSelf.showLoading()
                                strongSelf.paidOrder = parentOrder
                                Timer.scheduledTimer(timeInterval: 0.5, target: strongSelf, selector: #selector(strongSelf.showThankYouPage), userInfo: nil, repeats: false)
                            }
                        } else {
                            ErrorLogManager.sharedManager.recordNonFatalError(withException: .NullPointer)
                        }
                    }
                    
                    let navigationController = MmNavigationController()
                    navigationController.viewControllers = [checkoutViewController]
                    navigationController.modalPresentationStyle = .overFullScreen
                    
                    self.present(navigationController, animated: false, completion: nil)
                } else {
                    ErrorLogManager.sharedManager.recordNonFatalError(withException: .NullPointer)
                }
        }
    }
    
    private func fetchMerchant(_ merchantId: Int) -> Promise<Any> {
        return Promise { fulfill, reject in
            CacheManager.sharedManager.merchantById(merchantId, completion: { (merchant) in
                if let merchant = merchant {
                    fulfill(merchant)
                } else {
                    let error = NSError(domain: "", code: -999, userInfo: nil)
                    reject(error)
                }
            })
        }
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        
        guard let chatModel = self.itemDataSouce.get(indexPath.row) else {
            return TSChatBaseCell()
        }
        let typeStyle:MessageContentType? =  chatModel.messageContentType
        guard let type = typeStyle else {
            return TSChatBaseCell()
        }
        
        guard let cell = type.chatCell(tableView, indexPath: indexPath, model: chatModel, viewController: self) else {
            return TSChatBaseCell()
        }
        
        let authorUser: User? = chatModel.fromMe ? self.conv?.me : self.presenter
        
        cell.backgroundColor = UIColor.clear
        
        WebSocketManager.sharedInstance().msgReadMessage(chatModel)
        
        switch cell {
        case is TSChatTimeCell, is TSLoadMoreCell:
            break
            
        case is TSCouponCell:
            var couponCode = ""
            var couponName = ""
            var strMerchantId = ""
            
            if let cell = cell as? TSCouponCell, let merchantId = cell.model?.senderMerchantId, let coupon = cell.model?.coupon {
                couponCode = coupon.couponReference
                couponName = coupon.couponName
                strMerchantId = "\(merchantId)"
            }
            cell.initAnalytics(withViewKey: analyticsViewRecord.viewKey, impressionKey: recordImpression(impressionRef: couponCode, impressionType: "Coupon", impressionDisplayName: couponName, merchantCode: strMerchantId, positionComponent: "Grid", positionIndex: indexPath.row + 1, positionLocation: "IMChat"))
            
        default:
            // Impression tag - Message
            var authorType = "User"
            let authorUser: User? = chatModel.fromMe ? self.conv?.me : self.presenter
            var impressionRef: String?
            
            if let user = authorUser {
                impressionRef = user.userKey
                authorType = user.userTypeString()
            }
            var positionLocation = "Chat-Customer"
            if let conv = self.conv {
                positionLocation = conv.chatTypeString()
            }
            let impressionKey = self.recordImpression(
                impressionRef,
                authorType: authorType,
                impressionRef: chatModel.messageId,
                impressionType: "Message",
                positionComponent: "MessageFeeding",
                positionLocation: positionLocation
            )
            cell.initAnalytics(withViewKey: self.analyticsViewRecord.viewKey, impressionKey: impressionKey)
        }
        
        if let productCell = cell as? TSChatShareProductCell {
            
            productCell.buyHandler = { [weak self] (cell, style, isSwipe) in
                if let strongSelf = self {
                    // Action tag
                    cell.recordAction(
                        .Slide,
                        sourceRef: "SwipeToBuy",
                        sourceType: .Button,
                        targetRef: "Checkout",
                        targetType: .View
                    )
                    
                    let referrerUserKey = authorUser?.userKey
                    strongSelf.showCheckoutActionSheet(withStyle: style, referrerUserKey: referrerUserKey)
                } else {
                    ErrorLogManager.sharedManager.recordNonFatalError(withException: .NullPointer)
                }
            }
        }
        else if let commentCell = cell as? TSChatCommentCell {
            commentCell.resendMessage = { [weak self] model in
                if let strongSelf = self {
                    strongSelf.resendMessage(model)
                } else {
                    ErrorLogManager.sharedManager.recordNonFatalError(withException: .NullPointer)
                }
            }
        }
        else {
            if let postCell = cell as? TSSharePostCell {
                
                postCell.buyHandler = { [weak self] (cell, post, isSwipe) in
                    if let strongSelf = self, let post = post {
                        let referrerUserKey = authorUser?.userKey
                        
                        let skuCodes = (post.skuList ?? []).map({ $0.styleCode })
                        let merchantIds = post.getMerchantIds()
                        CheckoutService.defaultService.searchStyle(withStyleCodes: skuCodes, merchantIds: merchantIds).then { (styles) -> Void in
                            if styles.count > 0{
                                
                                let checkoutViewController = FCheckoutViewController(checkoutMode: .multipleMerchant, skus: post.skuList ?? [], styles: styles, referrer: referrerUserKey, redDotButton: strongSelf.buttonCart)
                                
                                checkoutViewController.didDismissHandler = { confirmed, parentOrder in
                                    strongSelf.updateButtonCartState()
                                    strongSelf.updateButtonWishlistState()
                                    
                                    if confirmed {
                                        strongSelf.showLoading()
                                        strongSelf.paidOrder = parentOrder
                                        Timer.scheduledTimer(timeInterval: 0.5, target: strongSelf, selector: #selector(strongSelf.showThankYouPage), userInfo: nil, repeats: false)
                                    }
                                }
                                
                                let navigationController = MmNavigationController()
                                navigationController.viewControllers = [checkoutViewController]
                                navigationController.modalPresentationStyle = .overFullScreen
                                
                                strongSelf.present(navigationController, animated: false, completion: nil)
                                
                            } else {
                                strongSelf.showError(String.localize("MSG_ERR_POST_ALL_INVALID"), animated: true)
                            }
                        }
                    } else {
                        ErrorLogManager.sharedManager.recordNonFatalError(withException: .NullPointer)
                    }
                }
            }
        }
        
        return cell
    }
    
}

// MARK: - @protocol UIScrollViewDelegate
extension TSChatViewController {
    func scrollViewWillBeginDragging(_ scrollView: UIScrollView) {
        if scrollView == self.listTableView {
            isScrolled = true
            self.hideAllKeyboard()
        }
    }
    
    //MARK: Notification
    @objc func showSaveImageSuccessPopup() {
        if let app = UIApplication.shared.delegate as? AppDelegate, let window = app.window {
            let hud = MBProgressHUD.showAdded(to: window, animated: true)
            hud?.mode = .customView
            hud?.opacity = 0.7
            let imageView = UIImageView(image: UIImage(named: "alert_ok"))
            imageView.contentMode = .scaleAspectFit
            imageView.frame = CGRect(x: 0, y: 0, width: 60, height: 60)
            hud?.customView = imageView
            hud?.labelText = String.localize("MSG_SUC_CA_IM_SAVE_IMG")
            hud?.hide(true, afterDelay: 1.5)
        }
    }
    
    @objc func showSaveImageFailedPopup() {
        TSAlertView_show(String.localize("LB_CA_IM_ACCESS_PHOTOS_PERMIT"), message: String.localize("LB_CA_IM_ACCESS_PHOTOS_DENIED"), labelCancel: nil)
    }
    
    @objc func reloadTable() {
        self.listTableView.reloadData()
    }
    
    @objc func keyboardWillHide(_ sender: Notification) {
        let keyboardType = self.chatActionBarView.keyboardType
        if keyboardType == .emotion || keyboardType == .share || keyboardType == .message {
            return
        }
        self.chatActionBarView.adjustBarHeight(hidden: true)
        if let userInfo = sender.userInfo {
            let duration = userInfo[UIKeyboardAnimationDurationUserInfoKey] as! NSNumber
            let curve = userInfo[UIKeyboardAnimationCurveUserInfoKey] as! NSNumber
            self.view.setNeedsLayout()
            UIView.animate(
                withDuration: TimeInterval(truncating: duration),
                delay: 0,
                options: [UIViewAnimationOptions(rawValue: UInt(truncating: curve))], animations: {
                    self.tableViewMarginBottomConstraint.constant = self.chatActionBarView.height
                    let height = self.chatActionBarView.getAdjustOffset(hidden: true)
                    self.actionBarHeightConstraint?.update(offset: height)
                    self.view.layoutIfNeeded()
            }, completion: nil)
        } else {
            ErrorLogManager.sharedManager.recordNonFatalError(withException: .NullPointer)
        }
    }
    
    @objc func keyboardWillShow(_ sender: Notification) {
        if let userInfo = sender.userInfo {
            let keyboardSize: CGSize =  (userInfo[UIKeyboardFrameEndUserInfoKey] as! NSValue).cgRectValue.size
                
                let height = self.chatActionBarView.getAdjustOffset(hidden: false)
                let heightOfset = keyboardSize.height + height
                
                let duration = userInfo[UIKeyboardAnimationDurationUserInfoKey] as! NSNumber
                let curve = userInfo[UIKeyboardAnimationCurveUserInfoKey] as! NSNumber
                self.view.setNeedsLayout()
                UIView.animate(
                    withDuration: TimeInterval(truncating: duration),
                    delay: 0,
                    options: [UIViewAnimationOptions(rawValue: UInt(truncating: curve))], animations: {
                        self.tableViewMarginBottomConstraint.constant = heightOfset
                        self.view.layoutIfNeeded()
                }, completion: nil)
                
                self.listTableView.scrollToBottomAnimated(false)
         
        } else {
            ErrorLogManager.sharedManager.recordNonFatalError(withException: .NullPointer)
        }
    }
    
    @objc func keyboardDidShow(_ sender: Notification) {
        self.chatActionBarView.adjustBarHeight(hidden: false)
    }
    
    @objc func willHideEditMenu(_ sender: Notification) {
        UIMenuController.shared.menuItems = []
    }
    
    @objc func didWebsocketConnected(_ sender: Notification) {
        fetchHistory { [weak self] (request, response) in
            if let strongSelf = self {
                strongSelf.handleIncomingHistory(request: request, response: response)
            } else {
                ErrorLogManager.sharedManager.recordNonFatalError(withException: .NullPointer)
            }
        }
    }
    
    @objc func applicationDidBecomeActive(_ sender: Notification) {
        startAllAnimations()
    }
    
    @objc func applicationWillResignActive(_ sender: Notification) {
        killAudioRecording()
        stopAllAnimations()
    }
    
    // MARK: - Handle animations
    
    func startAllAnimations() {
        
    }
    
    func stopAllAnimations() {
        
    }
    
}
