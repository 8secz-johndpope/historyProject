//
//  PresalesQueueViewController.swift
//  merchant-ios
//
//  Created by HungPM on 5/6/16.
//  Copyright © 2016 WWE & CO. All rights reserved.
//

import Foundation

class PresalesQueueViewController : MmViewController {
    
    private final let IMNoConversationCellID = "IMNoConversationCellID"
    private final let IMConversationViewCellID = "IMConversationViewCellID"
    private final let CSQueueNoteHeaderID = "CSQueueNoteHeaderID"
    
    private final let CellHeight = CGFloat(70)
    
    private var logoImageView: UIImageView!
    private var merchantNameLabel: UILabel!
    
    private var queueNumberLabel: UILabel!
    private var queueButton: UIButton!

    private let padding = CGFloat(5)
    
    var merchant: Merchant?
    
    var numberOfPreSales = 0
    
    var convList = [Conv]()
    
    //MARK: View life cycle
    override func viewDidLoad() {
        super.viewDidLoad()
        
        var merchantCode : String?
        var viewLocation : String?
        var queueName : String?

        if let merchant = self.merchant, let vLocation: String = merchant.merchantId == Constants.MMMerchantId ? "Queue-General" : "Queue-PreSale" {
            merchantCode =  String(merchant.merchantId)
            viewLocation = vLocation
            queueName = merchant.merchantCompanyName + String.localize("LB_CA_CS_SETTING")
        }
        
        initAnalyticsViewRecord(
            merchantCode: merchantCode,
            viewDisplayName: queueName != nil ? "Queue:\(String(describing: queueName))" : nil,
            viewParameters: merchantCode != nil ? "q=\(String(describing: merchantCode))" : nil,
            viewLocation: viewLocation,
            viewType: "IM"
        )
        
        setupNavigation()
        
        self.collectionView.register(IMNoConversationCell.self, forCellWithReuseIdentifier: IMNoConversationCellID)
        self.collectionView.register(IMConversationViewCell.NibObject(), forCellWithReuseIdentifier: IMConversationViewCellID)
        
        self.collectionView.register(UICollectionReusableView.self, forSupplementaryViewOfKind: UICollectionElementKindSectionHeader, withReuseIdentifier: CSQueueNoteHeaderID)
        
        NotificationCenter.default.addObserver(self, selector: #selector(PresalesQueueViewController.didUpdateQueueConvList), name: NSNotification.Name(rawValue: IMDidUpdateQueueConvList), object: nil)
    }
    
    @objc func didUpdateQueueConvList(_ notification: Notification) {
        if let userInfo = notification.userInfo, let convList = userInfo[IMConversationListKey] as? [Conv] {
            self.convList = convList
            
            self.numberOfPreSales = convList.count
            self.displayNumberOfPreSales()
            
            self.collectionView.reloadData()
        } else {
            ErrorLogManager.sharedManager.recordNonFatalError(withException: .NullPointer)
        }
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        
        self.navigationController?.isNavigationBarHidden = true
    
        fetchQueueConvList()
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        
        self.navigationController?.isNavigationBarHidden = false
    }
    
    //MARK: UI
    func setupNavigation() {
        
        let paddingTop = CGFloat(12)
        let margin = CGFloat(6)
        
        let viewNavigation = UIView(frame: CGRect(x: 0, y: 0, width: view.bounds.width, height: self.navigationController!.navigationBar.frame.maxY + 7))
    
        viewNavigation.backgroundColor = UIColor(hexString: "#919191")
        view.addSubview(viewNavigation)
        
        self.collectionView.frame = CGRect(x: self.collectionView.frame.originX, y: viewNavigation.height, width: self.collectionView.width, height: self.collectionView.frame.maxY - viewNavigation.height)
        
        let buttonBack = UIButton(type: .custom)
        buttonBack.setImage(UIImage(named: "back_wht"), for: UIControlState())
        buttonBack.frame = CGRect(x: margin,y: (paddingTop + viewNavigation.height - Constants.Value.BackButtonHeight) / 2, width: Constants.Value.BackButtonWidth, height: Constants.Value.BackButtonHeight)
        buttonBack.addTarget(self, action: #selector(backButtonClicked), for: .touchUpInside)
        viewNavigation.addSubview(buttonBack)
        
        logoImageView = { () -> UIImageView in
            let logoImageSize = CGSize(width: 32, height: 32)
            let imageView = UIImageView(frame: CGRect(x: buttonBack.frame.maxX + padding, y: (paddingTop + viewNavigation.height - logoImageSize.height) / 2, width: logoImageSize.width, height: logoImageSize.height))
            imageView.contentMode = .scaleAspectFit
            return imageView
        }()
        viewNavigation.addSubview(logoImageView)
        
        queueButton = { () -> UIButton in
            let buttonSize = CGSize(width: 60, height: 33)
            let button = UIButton(type: .custom)
            button.frame = CGRect(x: viewNavigation.width - margin - buttonSize.width, y: (paddingTop + viewNavigation.height - buttonSize.height) / 2, width: buttonSize.width, height: buttonSize.height)
            button.formatPrimary()
            button.setTitle("+ \(String.localize("LB_CA_CS_GET_NEXT"))", for: UIControlState())
            return button
        }()
        viewNavigation.addSubview(queueButton)
        queueButton.addTarget(self, action: #selector(PresalesQueueViewController.queueButtonTapped), for: .touchUpInside)
        
        let queueLabel = { () -> UILabel in
            let labelSize = CGSize(width: 40, height: 14)
            let label = UILabel()
            label.frame = CGRect(x: queueButton.frame.minX - labelSize.width - padding, y: queueButton.frame.minY + 2, width: labelSize.width, height: labelSize.height)
            label.formatSize(10)
            label.textColor = UIColor.white
            label.textAlignment = .center
            label.text = String.localize("LB_CA_CS_UNANS")
            return label
        } ()
        viewNavigation.addSubview(queueLabel)
        
        queueNumberLabel = { () -> UILabel in
            let labelSize = CGSize(width: 40, height: 17)
            let label = UILabel(frame: CGRect(x: queueButton.frame.minX - labelSize.width - padding, y: queueLabel.frame.maxY + 3, width: labelSize.width, height: labelSize.height))
            label.formatSize(15)
            label.textColor = UIColor.white
            label.textAlignment = .center
            label.text = "-"
            return label
        }()
        viewNavigation.addSubview(queueNumberLabel)
        
        merchantNameLabel = { () -> UILabel in
            let xPos = logoImageView.frame.maxX + padding
            
            var labelWidth = queueNumberLabel.frame.minX - xPos - padding
            if labelWidth > 150 {
                labelWidth = 150
            }
            
            let label = UILabel(frame: CGRect(x: xPos, y: paddingTop, width: labelWidth, height: viewNavigation.height - paddingTop))
            label.font = UIFont.usernameFont()
            label.lineBreakMode = NSLineBreakMode.byTruncatingTail
            label.numberOfLines = 2
            label.textColor = UIColor.white
            return label
            }()
        viewNavigation.addSubview(merchantNameLabel)
        
        if let merchant = self.merchant {
            if merchant.merchantId != Constants.MMMerchantId { // not MM
                logoImageView.mm_setImageWithURL(ImageURLFactory.URLSize(.size128, key: merchant.headerLogoImage, category: .merchant), placeholderImage: nil, clipsToBounds: true, contentMode: .scaleAspectFit)
            } else {
                logoImageView.image = Merchant().MMImageIconBlack
            }

            merchantNameLabel.text = merchant.merchantCompanyName +  String.localize("LB_CA_CS_SETTING")
        }
        
        displayNumberOfPreSales()
    }
    
    func displayNumberOfPreSales() {
        if self.numberOfPreSales > 0 {
            self.queueButton.setTitle("+ \(String.localize("LB_CA_CS_GET_NEXT"))", for: UIControlState())
            self.queueButton.formatPrimary()
            self.queueButton.isEnabled = true
            self.queueNumberLabel.text = "\(self.numberOfPreSales)"
        } else {
            self.queueButton.setTitle("+ \(String.localize("LB_CA_CS_GET_NEXT"))", for: UIControlState())
            self.queueButton.formatPrimary()
            self.queueButton.layer.backgroundColor = UIColor.secondary1().cgColor
            self.queueButton.isEnabled = false
            self.queueNumberLabel.text = "0"
        }
    }
    
    @objc func queueButtonTapped() {
        if let merchant = self.merchant, let queueType: QueueType = merchant.merchantId == Constants.MMMerchantId ? .General : .Presales {
            WebSocketManager.sharedInstance().sendMessage(
                IMQueueAnswerNextMessage(queue: queueType, merchantId: merchant.merchantId),
                checkNetwork: true,
                viewController: self,
                completion: { [weak self] (ack) in
                    if let strongSelf = self {
                        if let convKey = ack.data {
                            
                            // Action tag
                            var targetRef = "Chat-Customer"
                            if let conv = strongSelf.convList.first {
                                targetRef = conv.chatTypeString()
                            }
                            strongSelf.view.analyticsViewKey = strongSelf.analyticsViewRecord.viewKey
                            strongSelf.view.recordAction(
                                .Tap,
                                sourceRef: "PickNewChat",
                                sourceType: .Button,
                                targetRef: targetRef,
                                targetType: .View
                            )
                            
                            let viewController = AgentChatViewController(convKey: convKey)
                            
                            strongSelf.navigationController?.pushViewController(viewController, animated: true)
                        }
                        else {
                            Alert.alertWithSingleButton(strongSelf, title: "", message: String.localize("MSG_ERR_CS_CHAT_SELF"), buttonString: String.localize("LB_OK"))
                        }
                    } else {
                        ErrorLogManager.sharedManager.recordNonFatalError(withException: .NullPointer)
                    }
                }
            )
        }
    }
    
    func fetchQueueConvList() {
        if let merchant = self.merchant {
            
            var queue: QueueType = .Presales
            if merchant.merchantId == Constants.MMMerchantId {
                queue = .General
            }
            
            WebSocketManager.sharedInstance().sendMessage(
                IMQueueRequestConvList(
                    queue: queue,
                    status: ConvStatus.Open,
                    state: ConvState.New,
                    merchantId: merchant.merchantId
                ),
                completion: nil)
            
        } else {
            ErrorLogManager.sharedManager.recordNonFatalError(withException: .NullPointer)
        }
    }
    
    //MARK: Collection View DataSource and Delegates
    
    func numberOfSections(in collectionView: UICollectionView) -> Int {
        return 1
    }

    override func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        
        if self.convList.count > 0 {
            return self.convList.count
        } else {
            return 1
        }
    }
    
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, referenceSizeForHeaderInSection section: Int) -> CGSize {
        if self.convList.count > 0 {
            return CGSize(width: self.view.bounds.width, height: 40)
        } else {
            return CGSize.zero
        }
    }
    
    func collectionView(_ collectionView: UICollectionView, viewForSupplementaryElementOfKind kind: String, at indexPath: IndexPath) -> UICollectionReusableView {
        
        let headerView = collectionView.dequeueReusableSupplementaryView(ofKind: kind, withReuseIdentifier: CSQueueNoteHeaderID, for: indexPath)
        
        if headerView.viewWithTag(1001) == nil {

            let queueNoteLabel = UILabel(frame:CGRect(x: 0, y: 0, width: headerView.width, height: headerView.height))
            queueNoteLabel.backgroundColor = UIColor.clear
            queueNoteLabel.tag = 1001
            queueNoteLabel.text = String.localize("LB_CA_IM_CS_QUEUE_NOTE")
            queueNoteLabel.formatSmall()
            queueNoteLabel.textColor = UIColor.secondary3()
            queueNoteLabel.textAlignment = .center
            headerView.addSubview(queueNoteLabel)
            
            let separatorLine = UIView(frame:CGRect(x: 0, y: headerView.height - 1, width: headerView.width, height: 1))
            separatorLine.backgroundColor = UIColor.secondary1()
            headerView.addSubview(separatorLine)
        }
        
        return headerView
    }
    
    override func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        
        if self.convList.count > 0 {
            let cell = collectionView.dequeueReusableCell(withReuseIdentifier: IMConversationViewCellID, for: indexPath) as! IMConversationViewCell
            
            let conv = self.convList[indexPath.row]
            
            // Impresstion tag
            let impressionType = conv.chatTypeString()
            let impressionKey = recordImpression(
                impressionRef: conv.convKey,
                impressionType:  impressionType,
                impressionDisplayName: conv.presenter?.displayName,
                merchantCode: conv.merchantObject?.merchantCode,
                positionComponent: "ChatListing",
                positionIndex: indexPath.row + 1,
                positionLocation: conv.merchantId == Constants.MMMerchantId ? "Queue-General" : "Queue-PreSale"
            )
            
            cell.initAnalytics(withViewKey: analyticsViewRecord.viewKey, impressionKey: impressionKey)
            
            // Impresstion tag
            recordImpression(
                impressionRef: conv.presenter?.userKey,
                impressionType:  "User",
                impressionDisplayName: conv.presenter?.displayName,
                merchantCode: conv.merchantObject?.merchantCode,
                parentRef: conv.convKey,
                parentType: impressionType,
                positionComponent: "ChatListing",
                positionIndex: indexPath.row + 1,
                positionLocation: conv.merchantId == Constants.MMMerchantId ? "Queue-General" : "Queue-PreSale"
            )
            
            cell.conversationStatus = ConversationStatus.unknown
            
            cell.nameLabel.isHidden = true
            cell.otherMerchantNameLabel.isHidden = true
            
            if let msgNotReadCount = conv.msgNotReadCount {
                cell.setUnreadCount(msgNotReadCount)
            }
            
            cell.profileImageRounded(true)
            if let combinedImageKey = conv.combinedImageKey() {
                ImageFilesManager.cachedImageForKey(
                    combinedImageKey,
                    completion: { (image, error, cacheType, imageURL) in
                        if let returnedImage = image {
                            cell.profileIcon.image = returnedImage
                        } else {
                            conv.fetchThumbnail({ (images) in
                                if !images.isEmpty {
                                    cell.profileIcon.setCombineImages(images)
                                    
                                    if let combinedImage = cell.profileIcon.image {
                                        ImageFilesManager.storeImage(combinedImage,
                                            key: combinedImageKey,
                                            completionHandler:nil)
                                    }
                                }
                                else {
                                    cell.profileIcon.image = UIImage(named: "default_profile_pic")
                                }
                            })
                        }
                    }
                )
            }
            
            cell.lastMessageLabel.text = conv.lastMessage?.messageContent ?? ""
            cell.showCurator(conv.presenter?.isCurator == 1)
            cell.timeLabel.text = conv.timestamp.imTimeString
            
            cell.layoutSubviews()
            
            if let groupName = conv.groupChatName() {
                var groupChatNameList = [GroupChatName]()
                for nameModel in groupName {
                    groupChatNameList.append(GroupChatName(nameModel: nameModel))
                }
                
                cell.groupChatNameList = groupChatNameList
            }

            cell.isUserInteractionEnabled = true
            return cell
            
        } else {
            let cell = collectionView.dequeueReusableCell(withReuseIdentifier: IMNoConversationCellID, for: indexPath) as! IMNoConversationCell
            cell.label.text = String.localize("LB_CA_CS_NOMSG")
            cell.buttonAddFriend.isHidden = true
            cell.layoutSubviews()
            cell.isUserInteractionEnabled = false
            return cell
        }
    }

    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, sizeForItemAt indexPath: IndexPath) -> CGSize {
        
        if self.convList.count > 0 {
            return CGSize(width: self.view.frame.size.width , height: CellHeight)
        } else {
            return CGSize(width: self.view.frame.size.width , height: collectionView.height)
        }
    }
    
    func collectionView(_ collectionView: UICollectionView,
                        layout collectionViewLayout: UICollectionViewLayout,
                               insetForSectionAt section: Int) -> UIEdgeInsets {
        return UIEdgeInsets(top: 0.0, left: 0.0, bottom: 0.0, right: 0.0)
    }
    
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, minimumInteritemSpacingForSectionAt section: Int) -> CGFloat {
        return 0.0
    }
    
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, minimumLineSpacingForSectionAt section: Int) -> CGFloat {
        return 0.0
    }
    
    func collectionView(_ collectionView: UICollectionView,
                        didSelectItemAt indexPath: IndexPath) {
        
        let conv = self.convList[indexPath.row]
        if conv.senderUserKey == Context.getUserKey() {
            Alert.alertWithSingleButton(self, title: "", message: String.localize("MSG_ERR_CS_CHAT_SELF"), buttonString: String.localize("LB_OK"))
        }
        else if let merchant = self.merchant {
            WebSocketManager.sharedInstance().sendMessage(
                IMQueueAnswerSpecific(convKey: conv.convKey, queue: .Presales, merchantId: merchant.merchantId),
                checkNetwork: true,
                viewController: self,
                completion: { [weak self] (ack) in
                    if let strongSelf = self {
                        if let convKey = ack.data {
                            
                            if let cell = collectionView.cellForItem(at: indexPath) {
                                // Action tag
                                var sourceType: AnalyticsActionRecord.ActionElement = .ChatCustomer
                                if conv.isFriendChat() {
                                    sourceType = .ChatFriend
                                } else if conv.isInternalChat() {
                                    sourceType = .ChatInternal
                                }
                                
                                cell.recordAction(
                                    .Tap,
                                    sourceRef: convKey,
                                    sourceType: sourceType,
                                    targetRef: sourceType.rawValue,
                                    targetType: .View
                                )
                            }
                            
                            let viewController = AgentChatViewController(convKey: convKey)
                            
                            strongSelf.navigationController?.pushViewController(viewController, animated: true)
                        } else {
                            Alert.alertWithSingleButton(strongSelf, title: "", message: String.localize("MSG_ERR_CS_CHAT_PICKEDUP"), buttonString: String.localize("LB_OK"))
                        }
                    } else {
                        ErrorLogManager.sharedManager.recordNonFatalError(withException: .NullPointer)
                    }
                }
            )
        }
    }

    deinit {
        NotificationCenter.default.removeObserver(self)
    }
}
