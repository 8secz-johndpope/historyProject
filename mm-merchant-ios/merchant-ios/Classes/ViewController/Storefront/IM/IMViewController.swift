//
//  IMViewController.swift
//  merchant-ios
//
//  Created by Koon Kit Chan on 18/11/15.
//  Copyright © 2015 Koon Kit Chan. All rights reserved.
//

import Foundation
import ObjectMapper
import PromiseKit

enum IMLandingSection: Int {
    case merchant = 0
    case conv = 1
}

class IMViewController : MmViewController, IMNoConversationCellDelegate {
    
    private final let IMAgentCellID = "IMAgentCellID"
    private final let IMConversationViewCellID = "IMConversationViewCellID"
    private final let IMAgentHeaderID = "IMAgentHeaderID"
    private final let IMAgentFooterID = "IMAgentFooterID"
    private final let IMFilterHeaderID = "IMFilterHeaderID"
    
    private final let CellHeight : CGFloat = 65
    private var dataSource: [IMLandingConversationData] = []
    
    private var merchants = [Merchant]()
    private var merchantQueues = [MerchantQueues]()
    
    private var arrowImageView : UIImageView!
    
    private var isDescendingConvList = IMFilterCache.sharedInstance.sortType() == .orderedDescending ? true : false
    
    private var convCloseTextfield: UITextField?
    private var buttonContact: ButtonRedDot!
    private final var sortButton: UIButton?
    private final var filterButton: UIButton?
    private final var footerLabel: UILabel?
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        pageAccessibilityId = "IM_Landing"
        
        if let merchants =  Context.customerServiceMerchants().merchants {
            self.merchants = merchants
        }
        
        initAnalyticsViewRecord(
            viewDisplayName: "User: \(Context.getUserProfile().displayName)",
            viewParameters: "u=\(Context.getUserProfile().userKey)",
            viewLocation: self.merchants.count != 0 ? "Landing-Agent" : "Landing-User",
            viewType: "IM"
        )
        
        if let merchantQueues = WebSocketManager.sharedInstance().linkedCustomerServices {
            self.merchantQueues = merchantQueues
        }
        
        self.title = String.localize("LB_CA_MESSENGER")
        self.view.backgroundColor = UIColor.white
        
        let ButtonHeight = CGFloat(36)
        let ButtonWidth = CGFloat(36)
        
        buttonContact = ButtonRedDot(number: CacheManager.sharedManager.numberOfFriendRequests)
        buttonContact.setImage(UIImage(named: "chat_contact_icon"), for: UIControlState())
        buttonContact.hasRedDot(false)
        buttonContact.badgeAdjust = CGPoint(x: -20, y: 2)
        buttonContact.contentEdgeInsets = UIEdgeInsets(top: 0, left: 0, bottom: 0, right: 0)
        buttonContact.frame = CGRect(x: 0, y: 0, width: ButtonWidth, height: ButtonHeight)
        buttonContact.addTarget(self, action: #selector(contactButtonTapped), for: .touchUpInside)
        self.setAccessibilityIdForView("UIBT_IM_FRD", view: buttonContact)
        
        let buttonAdd = UIButton(type: .custom)
        buttonAdd.setImage(UIImage(named: "add_icon"), for: UIControlState())
        buttonAdd.frame = CGRect(x: 0, y: 0, width: ButtonWidth, height: ButtonHeight)
        buttonAdd.contentEdgeInsets = UIEdgeInsets(top: 0, left: 0, bottom: 0, right: 0)
        buttonAdd.addTarget(self, action: #selector(IMViewController.addButtonClicked), for: .touchUpInside)
        self.setAccessibilityIdForView("UIBT_IM_NEW_FRIEND", view: buttonAdd)
        
        self.navigationItem.rightBarButtonItems = [UIBarButtonItem(customView: buttonAdd), UIBarButtonItem(customView: buttonContact)]
        self.createBackButton()

        self.collectionView.register(IMConversationViewCell.NibObject(), forCellWithReuseIdentifier: IMConversationViewCellID)
        self.collectionView.register(IMAgentCell.self, forCellWithReuseIdentifier: IMAgentCellID)
        self.collectionView.register(UICollectionReusableView.self, forSupplementaryViewOfKind: UICollectionElementKindSectionHeader, withReuseIdentifier: IMAgentHeaderID)
        self.collectionView.register(UICollectionReusableView.self, forSupplementaryViewOfKind: UICollectionElementKindSectionFooter, withReuseIdentifier: IMAgentFooterID)
        self.collectionView.register(UICollectionReusableView.self, forSupplementaryViewOfKind: UICollectionElementKindSectionHeader, withReuseIdentifier: IMFilterHeaderID)
        
        NotificationCenter.default.addObserver(self, selector: #selector(IMViewController.didUpdateConvList), name: NSNotification.Name(rawValue: IMDidUpdateConversationList), object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(IMViewController.reloadFriendRequestButton), name: NSNotification.Name(rawValue: FriendRequestDidUpdateNotification), object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(IMViewController.didUpdateLinkedCustomerServices), name: NSNotification.Name(rawValue: IMDidUpdateLinkedCustomerServices), object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(IMViewController.didUpdateFriendRequest),
                                               name: Constants.Notification.refreshFriendRequest, object: nil)
        
        reloadFriendRequestButton()
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        loadFilterConvList()
        
        if let _ = self.navigationController?.tabBarController?.tabBar {
        } else {
            ErrorLogManager.sharedManager.recordNonFatalError(withException: .NullPointer)
        }
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
    }
    
    override func refresh() {
        self.loadFilterConvList()
    }
    
    func loadFilterConvList(){
        dataSource = WebSocketManager.sharedInstance().listConvFilter(IMFilterCache.sharedInstance.filterChat())
        WebSocketManager.sharedInstance().updateConversationUnreadCount()
        reloadDataSource()
    }
    
    @objc func didUpdateConvList(_ notification: Notification) {
        loadFilterConvList()
    }
    
    @objc func didUpdateLinkedCustomerServices(_ notification: Notification){
        
        if let linkedCustomerServices = notification.object as? [MerchantQueues] {
            self.merchantQueues = linkedCustomerServices
            self.collectionView.reloadData()
        }
    }
    
    @objc func didUpdateFriendRequest(_ notification: Notification) {
        LoginManager.loadFriendRequest(
            completion: {
                self.reloadFriendRequestButton()
        }
        )
    }
    
    func numberOfPreSalesWithMerchantId(_ merchantId : Int) -> Int {
        if self.merchantQueues.count > 0 {
            for aMerchantQueue in self.merchantQueues {
                if let aQueueStatistics = aMerchantQueue.queueByType(.General, convType: .Customer), aMerchantQueue.merchantId == merchantId && aMerchantQueue.merchantId == Constants.MMCSId {
                    return aQueueStatistics.new
                } else if let aQueueStatistics = aMerchantQueue.queueByType(.Presales, convType: .Customer), aMerchantQueue.merchantId == merchantId {
                    return aQueueStatistics.new
                }
            }
        }
        return 0
    }
    
    @objc func reloadFriendRequestButton() {
        let total = CacheManager.sharedManager.numberOfFriendRequests
        buttonContact.setBadgeNumber(total)
    }
    
    //MARK: Collection View methods and delegates
    override func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        var count = 0
        if section == IMLandingSection.merchant.rawValue {
            count = merchants.count
        } else if section == IMLandingSection.conv.rawValue {
            count = dataSource.count
        }
        return count
    }
    
    func numberOfSections(in collectionView: UICollectionView) -> Int {
        return 2
    }
    
    func collectionView(_ collectionView: UICollectionView, viewForSupplementaryElementOfKind kind: String, at indexPath: IndexPath) -> UICollectionReusableView {
        
        if indexPath.section == IMLandingSection.conv.rawValue {
            let headerView = collectionView.dequeueReusableSupplementaryView(ofKind: kind, withReuseIdentifier: IMFilterHeaderID, for: indexPath)
            
            headerView.backgroundColor = UIColor.white
            
            if sortButton == nil {
                let leftView = UIView(frame: CGRect(x: 0, y: 0, width: headerView.bounds.width / 2.0, height: headerView.bounds.height))
                let buttonWith = CGFloat(100)
                let arrowWidth = CGFloat(15)
                
                sortButton = UIButton(type: .custom)
                sortButton!.frame = CGRect(x: leftView.center.x - buttonWith / 2.0, y: 0, width: buttonWith, height: headerView.frame.height)
                sortButton!.formatSecondaryNonBorder()
                sortButton!.contentEdgeInsets = UIEdgeInsets(top: 0, left: 0, bottom: 0, right: arrowWidth);
                sortButton!.addTarget(self, action: #selector(handleSortTapped), for: .touchUpInside)
                leftView.addSubview(sortButton!)
                arrowImageView = UIImageView(frame: CGRect(x: sortButton!.frame.width - arrowWidth, y: (sortButton!.frame.height - arrowWidth)/2, width: arrowWidth, height: arrowWidth))
                arrowImageView.contentMode = .scaleAspectFit
                sortButton!.addSubview(arrowImageView)
                headerView.addSubview(leftView)
                
                let rightView = UIView(frame: CGRect(x: headerView.bounds.width / 2.0, y: 0, width: headerView.bounds.width / 2.0, height: headerView.bounds.height))
                filterButton = UIButton(type: .custom)
                filterButton!.frame = CGRect(x: rightView.bounds.width / 2.0 - buttonWith / 2.0, y: 0, width: buttonWith, height: headerView.frame.height)
                filterButton!.formatSecondaryNonBorder()
                filterButton!.addTarget(self, action: #selector(handleFilterTapped), for: .touchUpInside)
                rightView.addSubview(filterButton!)
                headerView.addSubview(rightView)
                
                let separator = UIImageView(frame: CGRect(x: 0, y: headerView.frame.height - 0.5, width: headerView.frame.width, height: 0.5))
                separator.backgroundColor = UIColor.secondary1()
                headerView.addSubview(separator)
            }
            
            filterButton!.setTitle(String.localize("LB_CA_FILTER") + " (\(IMFilterCache.sharedInstance.numberFilterSelected()))", for: UIControlState())
            
            if isDescendingConvList {
                sortButton!.setTitle(String.localize("LB_IM_CS_SORT_NEWEST"), for: UIControlState())
                arrowImageView.image = UIImage(named:"arrow_close")
            } else {
                sortButton!.setTitle(String.localize("LB_IM_CS_SORT_OLDEST"), for: UIControlState())
                arrowImageView.image = UIImage(named:"arrow_open")
            }
            
            return headerView
        } else {
            if kind == UICollectionElementKindSectionHeader {
                let headerView = collectionView.dequeueReusableSupplementaryView(ofKind: kind, withReuseIdentifier: IMAgentHeaderID, for: indexPath)
                
                headerView.backgroundColor = UIColor(hexString:"#717171")
                
                if footerLabel == nil {
                    let padding = CGFloat(15)
                    footerLabel = UILabel(frame: CGRect(x: padding, y: 0, width: headerView.frame.width - 2*padding, height: headerView.frame.height))
                    footerLabel!.formatSize(14)
                    footerLabel!.textColor = UIColor.white
                    footerLabel!.text = String.localize("LB_CA_CS_AGENT_ACC")
                    headerView.addSubview(footerLabel!)
                }
                
                return headerView
            }
            else /*if kind == UICollectionElementKindSectionFooter*/ {
                
                let footerView = collectionView.dequeueReusableSupplementaryView(ofKind: kind, withReuseIdentifier: IMAgentFooterID, for: indexPath)
                
                footerView.backgroundColor = UIColor(hexString:"#717171")
                
                return footerView
            }
        }
    }
    
    @objc func handleSortTapped() {
        isDescendingConvList = !isDescendingConvList
        
        // Action tag
        var sourceRef : String?
        var targetRef : String?
        if isDescendingConvList {
            sourceRef = "Sort-Oldest"
            targetRef = "Sort-Newest"
        } else {
            sourceRef = "Sort-Newest"
            targetRef = "Sort-Oldest"
        }
        self.view.analyticsViewKey = self.analyticsViewRecord.viewKey
        self.view.recordAction(
            .Tap,
            sourceRef: sourceRef,
            sourceType: .Button,
            targetRef: targetRef,
            targetType: .View
        )
        
        IMFilterCache.sharedInstance.saveSortType(isDescendingConvList ? .orderedDescending : .orderedAscending)
        self.reloadDataSource()
    }
    
    func sortConvList() {
        
        let compare = IMFilterCache.sharedInstance.sortType()
        
        dataSource.sort { (left, right) -> Bool in
            return left.timestamp.compare(right.timestamp) == compare
        }
    }
    
    @objc func handleFilterTapped() {
        
        // Action tag
        self.view.analyticsViewKey = self.analyticsViewRecord.viewKey
        self.view.recordAction(
            .Tap,
            sourceRef: "Filter",
            sourceType: .Button,
            targetRef: "ChatFilter",
            targetType: .View
        )
        
        let imFilterViewController = IMFilterViewController()
        self.navigationController?.push(imFilterViewController, animated: true)
    }
    
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, referenceSizeForHeaderInSection section: Int) -> CGSize {
        var height: CGFloat = 0
        if section == IMLandingSection.merchant.rawValue && merchants.count > 0 {
            height = 35
        } else if section == IMLandingSection.conv.rawValue && merchants.count > 0 {
            height = 40
        }
        return CGSize(width: self.view.bounds.width, height: height)
    }
    
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, referenceSizeForFooterInSection section: Int) -> CGSize {
        var height: CGFloat = 0
        if section == IMLandingSection.merchant.rawValue && merchants.count > 0 {
            height = 4
        }
        return CGSize(width: self.view.bounds.width, height: height)
    }
    
    override func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        
        if indexPath.section == IMLandingSection.conv.rawValue {
            let index = indexPath.row
            
            let cell = collectionView.dequeueReusableCell(withReuseIdentifier: IMConversationViewCellID, for: indexPath) as! IMConversationViewCell
            
            self.setAccessibilityIdForView("UI_IM_CONVERSATION", view: cell)
            
            let data = dataSource[index]
            
            let merchantCode = data.conv.myMerchantObject()?.merchantCode
            let impressionType = data.conv.chatTypeString()
            var imrepssionDisplayName = ""
            
            if data.conv.isGroupChat() {
                
                if let groupChatName = data.conv.groupChatName() {
                    var userName = ""
                    for nameModel in groupChatName {
                        userName = nameModel.name + ", "
                        imrepssionDisplayName += userName
                        
                        // Impression tag - User
                        recordImpression(
                            impressionRef: data.conv.convKey,
                            impressionType: (impressionType == "Chat-Customer" || impressionType == "Chat-Internal") ? "Merchant":"User",
                            impressionDisplayName: userName,
                            parentType: impressionType,
                            positionComponent: "ChatListing",
                            positionIndex: index + 1,
                            positionLocation: self.merchants.count != 0 ? "IMLanding-Agent" : "IMLanding-User"
                        )
                    }
                    
                    if imrepssionDisplayName.length > 1 {
                        let index = imrepssionDisplayName.index(imrepssionDisplayName.endIndex, offsetBy: -2)
                        imrepssionDisplayName = String(imrepssionDisplayName[..<index])
                    }
                }
            } else {
                imrepssionDisplayName = data.conv.presenter?.displayName ?? ""
                
                // Impression tag - User
                recordImpression(
                    impressionRef: data.conv.convKey,
                    impressionType: (impressionType == "Chat-Customer" || impressionType == "Chat-Internal") ? "Merchant":"User",
                    impressionDisplayName: imrepssionDisplayName,
                    parentType: impressionType,
                    positionComponent: "ChatListing",
                    positionIndex: index + 1,
                    positionLocation: self.merchants.count != 0 ? "IMLanding-Agent" : "IMLanding-User"
                )
            }
            
            // Impression tag - Chat
            let impressionKey = recordImpression(
                impressionRef: data.conv.convKey,
                impressionType: impressionType,
                impressionVariantRef: merchantCode,
                impressionDisplayName: imrepssionDisplayName,
                merchantCode: merchantCode,
                positionComponent: "ChatListing",
                positionIndex: index + 1,
                positionLocation: self.merchants.count != 0 ? "IMLanding-Agent" : "IMLanding-User"
            )
            
            cell.initAnalytics(withViewKey: analyticsViewRecord.viewKey, impressionKey: impressionKey)
            
            if let myMerchantObj = data.conv.myMerchantObject() {
                if let merchantColor = Context.customerServiceMerchants().merchantColorForId(myMerchantObj.merchantId) {
                    cell.merchantIcon.backgroundColor = merchantColor
                    cell.merchantIcon.isHidden = false
                } else {
                    cell.merchantIcon.isHidden = true
                }
            }
            else {
                cell.merchantIcon.isHidden = true
            }
            
            cell.conversationStatus = ConversationStatus.unknown
            
            if data.conv.isMyClient() || data.conv.isInternalChat() || data.conv.IAmMM() {
                if data.conv.isClosed() {
                    cell.conversationStatus = ConversationStatus.closed
                } else if data.conv.isFollowUp() {
                    cell.conversationStatus = ConversationStatus.followed
                }
            }
            
            cell.nameLabel.isHidden = true
            cell.otherMerchantNameLabel.isHidden = true
            cell.lastMessageLabel.text = data.lastMessage
            if let msgNotReadCount = data.conv.msgNotReadCount {
                cell.setUnreadCount(msgNotReadCount)
            }
            
            cell.profileImageRounded(true)
            
            if let combinedImageKey = data.conv.combinedImageKey() {
                ImageFilesManager.cachedImageForKey(
                    combinedImageKey,
                    completion: { (image, error, cacheType, imageURL) in
                        if let returnedImage = image {
                            cell.profileIcon.image = returnedImage
                        } else {
                            data.conv.fetchThumbnail({ (images) in
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
            
            cell.showCurator(data.isCurator)
            cell.timeLabel.text = data.timestamp.imTimeString
            
            cell.layoutSubviews()
            
            if let groupName = data.conv.groupChatName() {
                var groupChatNameList = [GroupChatName]()
                for nameModel in groupName {
                    groupChatNameList.append(GroupChatName(nameModel: nameModel))
                }
                
                cell.groupChatNameList = groupChatNameList
            }
            
            if data.conv.isFriendChat() || data.conv.IAmCustomer() {
                cell.rightMenuItems = [
                    SwipeActionMenuCellData(
                        text: String.localize("LB_CA_DELETE"),
                        icon: UIImage(named: "icon_swipe_delete"),
                        backgroundColor: UIColor(hexString: "#7A848C"),
                        defaultAction: true,
                        action: { [weak self] () -> Void in
                            if let strongSelf = self {
                                if data.conv.isAllowLeaveChat() {
                                    Alert.alert(strongSelf, title: "", message: String.localize("LB_CS_CHAT_GROUP_DELETE"), okActionComplete: { () -> Void in
                                        
                                        if let myUserRole = data.conv.myUserRole {
                                            WebSocketManager.sharedInstance().sendMessage(
                                                IMConvRemoveMessage(
                                                    convKey: data.conv.convKey,
                                                    userList: [myUserRole],
                                                    myUserRole: myUserRole
                                                ),
                                                completion: { _ in
                                                    WebSocketManager.sharedInstance().removeConv(data.conv)
                                                    CacheManager.sharedManager.deleteConv(data.conv.convKey)
                                                    strongSelf.loadFilterConvList()
                                                    WebSocketManager.sharedInstance().updateConversationUnreadCount()
                                            }, failure: {
                                                strongSelf.showErrorAlert(String.localize("MSG_ERR_NETWORK_1009"))
                                            }
                                            )
                                        }
                                    }, cancelActionComplete: nil)
                                }
                                else {
                                    Alert.alert(strongSelf, title: "", message: String.localize("LB_CS_CHAT_GROUP_DELETE"), okActionComplete: { () -> Void in
                                        
                                        WebSocketManager.sharedInstance().sendMessage(
                                            IMConvHideMessage(
                                                convKey: data.conv.convKey,
                                                myUserRole: data.conv.myUserRole
                                            ),
                                            completion: { _ in
                                                WebSocketManager.sharedInstance().removeConv(data.conv)
                                                strongSelf.loadFilterConvList()
                                                WebSocketManager.sharedInstance().updateConversationUnreadCount()
                                        }, failure: {
                                            strongSelf.showErrorAlert(String.localize("MSG_ERR_NETWORK_1009"))
                                        }
                                        )
                                        
                                        
                                    }, cancelActionComplete: nil)
                                }
                            } else {
                                ErrorLogManager.sharedManager.recordNonFatalError(withException: .NullPointer)
                            }
                        }
                    ),
                ]
            } else if data.conv.IAmAgent() || data.conv.isInternalChat() || data.conv.IAmMM() {
                
                let closeMenu = SwipeActionMenuCellData(
                    text: String.localize("LB_CLOSE"),
                    icon: UIImage(named: "close"),
                    backgroundColor: UIColor(hexString: "#77848d"),
                    defaultAction: true,
                    action: { [weak self] () -> Void in
                        if let strongSelf = self {
                            // Action tag
                            if let cell = collectionView.cellForItem(at: indexPath) {
                                
                                var sourceType: AnalyticsActionRecord.ActionElement = .ChatCustomer
                                if data.conv.isFriendChat() {
                                    sourceType = .ChatFriend
                                } else if data.conv.isInternalChat() {
                                    sourceType = .ChatInternal
                                }
                                
                                cell.recordAction(
                                    .Slide,
                                    sourceRef: data.conv.convKey,
                                    sourceType: sourceType,
                                    targetRef: "Close",
                                    targetType: .Button
                                )
                            }
                            
                            strongSelf.doCloseConversation(data)
                        } else {
                            ErrorLogManager.sharedManager.recordNonFatalError(withException: .NullPointer)
                        }
                    }
                )
                
                let unflagMenu = SwipeActionMenuCellData(
                    text: String.localize("LB_CS_CHAT_UNFLAG"),
                    icon: UIImage(named: "unflag"),
                    backgroundColor: UIColor(hexString: "#f16264"),
                    action: { () -> Void in
                        WebSocketManager.sharedInstance().sendMessage(
                            IMConvUnFlagMessage(
                                convKey: data.conv.convKey,
                                myUserRole: data.conv.myUserRole
                            ),
                            completion: { [weak self] (ack) in
                                if let strongSelf = self, let me = data.conv.me {
                                    data.conv.userListFlag.remove(me.userKey)
                                    strongSelf.reloadDataSource()
                                }
                            }, failure: { [weak self] in
                                if let strongSelf = self {
                                    strongSelf.showErrorAlert(String.localize("MSG_ERR_NETWORK_1009"))
                                }
                            }
                        )
                }
                )
                
                let flagMenu = SwipeActionMenuCellData(
                    text: String.localize("LB_CS_FOLLOW_UP"),
                    icon: UIImage(named: "flag"),
                    backgroundColor: UIColor(hexString: "#f16264"),
                    action: { () -> Void in
                        
                        // Action tag
                        if let cell = collectionView.cellForItem(at: indexPath) {
                            
                            var sourceType: AnalyticsActionRecord.ActionElement = .ChatCustomer
                            if data.conv.isFriendChat() {
                                sourceType = .ChatFriend
                            } else if data.conv.isInternalChat() {
                                sourceType = .ChatInternal
                            }
                            
                            cell.recordAction(
                                .Slide,
                                sourceRef: data.conv.convKey,
                                sourceType: sourceType,
                                targetRef: "Followup",
                                targetType: .Button
                            )
                        }
                        
                        WebSocketManager.sharedInstance().sendMessage(
                            IMConvFlagMessage(
                                convKey: data.conv.convKey,
                                myUserRole: data.conv.myUserRole
                            ),
                            completion: { [weak self] (ack) in
                                if let strongSelf = self, let me = data.conv.me {
                                    data.conv.userListFlag.append(me.userKey)
                                    strongSelf.reloadDataSource()
                                }
                            }, failure: { [weak self] in
                                if let strongSelf = self{
                                    strongSelf.showErrorAlert(String.localize("MSG_ERR_NETWORK_1009"))
                                }
                            }
                        )
                }
                )
                
                if (data.conv.isMyClient() || data.conv.isInternalChat() || data.conv.IAmMM()) && !data.conv.isClosed() {
                    if data.conv.isFollowUp() {
                        cell.rightMenuItems = [unflagMenu]
                    } else {
                        cell.rightMenuItems = [flagMenu]
                    }
                }
                else {
                    cell.rightMenuItems = nil
                }
                
                if !data.conv.isClosed() && data.conv.isOwner() || data.conv.isInternalChat() {
                    if cell.rightMenuItems == nil {
                        cell.rightMenuItems = [closeMenu]
                    }
                    else {
                        cell.rightMenuItems?.append(closeMenu)
                    }
                }
            }
            else {
                cell.rightMenuItems = nil
            }
            
            return cell
            
        } else {
            
            let cell = collectionView.dequeueReusableCell(withReuseIdentifier: IMAgentCellID, for: indexPath) as! IMAgentCell
            let merchant = self.merchants[indexPath.row]
            
            // Impression tag - Merchant
            let merchantCode = String(merchant.merchantId)
            let impressionKey = recordImpression(
                impressionRef: merchantCode,
                impressionType: "Merchant",
                impressionVariantRef: merchantCode,
                impressionDisplayName: merchant.merchantDisplayName,
                merchantCode: merchantCode,
                positionComponent: "ChatListing",
                positionIndex: indexPath.row + 1,
                positionLocation: self.merchants.count != 0 ? "IMLanding-Agent" : "IMLanding-User"
            )
            
            cell.initAnalytics(withViewKey: analyticsViewRecord.viewKey, impressionKey: impressionKey)
            
            cell.data = merchant
            
            let numberOfQueues = self.numberOfPreSalesWithMerchantId(merchant.merchantId)
            
            if numberOfQueues > 0 {
                var queueType = "Queue-Presales"
                if merchant.merchantId == Constants.MMCSId {
                    queueType = "Queue-General"
                }
                // Impression tag - Pre-Sale Queues shown on user screen
                recordImpression(
                    impressionRef: String(merchant.merchantId),
                    impressionType: queueType,
                    impressionDisplayName:  merchant.merchantDisplayName,
                    merchantCode: String(merchant.merchantId),
                    positionComponent: "QueueListing",
                    positionIndex: indexPath.row + 1,
                    positionLocation: self.merchants.count != 0 ? "IMLanding-Agent" : "IMLanding-User"
                )
            }
            
            cell.displayNumberOfPreSales(numberOfQueues)
            cell.pickUpTappedHandler = { [weak self] (cell, merchant) in
                if let strongSelf = self {
                    var type: QueueType = .Presales
                    if merchant.merchantId == Constants.MMCSId {
                        type = .General
                    }
                    
                    WebSocketManager.sharedInstance().sendMessage(
                        IMQueueAnswerNextMessage(queue: type, merchantId: merchant.merchantId),
                        completion: { (ack) in
                            if let convKey = ack.data {
                                
                                let viewController = AgentChatViewController(convKey: convKey)
                                
                                // Action tag
                                var targetRef = "Chat-Customer"
                                if let conv = viewController.conv {
                                    targetRef = conv.chatTypeString()
                                }
                                cell.recordAction(
                                    .Tap,
                                    sourceRef: "PickNewChat",
                                    sourceType: .Button,
                                    targetRef: targetRef,
                                    targetType: .View
                                )
                                
                                viewController.finishedTransferChat = { (stayOn: Bool, convKey: String) in
                                    strongSelf.navigationController?.popViewController(animated:false)
                                    let viewController = AgentChatViewController(convKey: convKey)
                                    viewController.showPopUp = stayOn
                                    strongSelf.navigationController?.pushViewController(viewController, animated: false)
                                }
                                
                                strongSelf.navigationController?.pushViewController(viewController, animated: true)
                            }
                            else {
                                Alert.alertWithSingleButton(strongSelf, title: "", message: String.localize("MSG_ERR_CS_CHAT_SELF"), buttonString: String.localize("LB_OK"))
                            }
                    }, failure: {
                        strongSelf.showErrorAlert(String.localize("MSG_ERR_NETWORK_1009"))
                    }
                    )
                    
                }
                
            }
            
            return cell
        }
    }
    
    func doCloseConversation(_ data : IMLandingConversationData) {
        let alert = UIAlertController(title: String.localize("LB_CS_CLOSE_CHAT"), message: String.localize("LB_CS_CLOSE_CHAT_CONF"), preferredStyle: UIAlertControllerStyle.alert)
        alert.view.tintColor = UIColor.alertTintColor()
        alert.addTextField(configurationHandler: self.configurationTextField)
        
        alert.addAction(UIAlertAction(title: String.localize("LB_CANCEL"), style: UIAlertActionStyle.cancel, handler: nil))
        alert.addAction(UIAlertAction(title: String.localize("LB_CLOSE"), style: UIAlertActionStyle.default, handler:{ [weak self] _ in
            if let strongSelf = self {
                if let merchantId = data.conv.myMerchantObject()?.merchantId, let comment = strongSelf.convCloseTextfield?.text, comment.isEmpty == false {
                    
                    WebSocketManager.sharedInstance().sendMessage(
                        IMCommentMessage(
                            comment: comment,
                            merchantId: merchantId,
                            convKey: data.conv.convKey,
                            status: CommentStatus.Closed,
                            myUserRole: data.conv.myUserRole
                        ), completion: nil, failure: {
                            strongSelf.showErrorAlert(String.localize("MSG_ERR_NETWORK_1009"))
                    }
                    )
                    
                    strongSelf.sendConversationClose(data.conv)
                } else {
                    
                    strongSelf.sendConversationClose(data.conv)
                }
            } else {
                ErrorLogManager.sharedManager.recordNonFatalError(withException: .NullPointer)
            }
        }))
        self.present(alert, animated: true, completion: nil)
    }
    
    func sendConversationClose(_ conv: Conv) {
        WebSocketManager.sharedInstance().sendMessage(
            IMConvCloseMessage(
                convKey: conv.convKey,
                myUserRole: conv.myUserRole
            ), completion: nil, failure: { [weak self] in
                if let strongSelf = self {
                    strongSelf.showErrorAlert(String.localize("MSG_ERR_NETWORK_1009"))
                }
            }
        )
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
    
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, sizeForItemAt indexPath: IndexPath) -> CGSize {
        return CGSize(width: self.view.frame.size.width , height: CellHeight)
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
    
    func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        
        if indexPath.section == IMLandingSection.conv.rawValue {
            let index = indexPath.row
            
            let conv = self.dataSource[index].conv
            
            // Action tag
            if let cell = collectionView.cellForItem(at: indexPath) {
                
                let targetRef = conv.chatTypeString()
                cell.recordAction(
                    .Tap,
                    sourceRef: conv.convKey,
                    sourceType: .Button,
                    targetRef: targetRef,
                    targetType: .View
                )
            }
            
            if conv.isMyClient() || conv.isInternalChat() {
                let viewController = AgentChatViewController(conv: conv)
                
                viewController.finishedTransferChat = { [weak self] (stayOn: Bool, convKey: String) in
                    if let strongSelf = self {
                        strongSelf.navigationController?.popViewController(animated: false)
                        let viewController = AgentChatViewController(convKey: convKey)
                        viewController.showPopUp = stayOn
                        strongSelf.navigationController?.push(viewController, animated: false)
                    }
                }
                
                self.navigationController?.push(viewController, animated: true)
                
            } else {
                let viewController = UserChatViewController(conv: conv)
                viewController.didPopHandler = { friend, chatModel in
                    let myRole: UserRole = UserRole(userKey: Context.getUserKey())
                    let targetRole: UserRole = UserRole(userKey: friend.userKey)
                    
                    WebSocketManager.sharedInstance().sendMessage(
                        IMConvStartMessage(
                            userList: [myRole, targetRole],
                            senderMerchantId: myRole.merchantId
                        ),
                        completion: { [weak self] (ack) in
                            
                            if let strongSelf = self, let convKey = ack.data {
                                
                                let viewController = UserChatViewController(convKey: convKey)
                                viewController.forwardChatModel = chatModel
                                strongSelf.navigationController?.pushViewController(viewController, animated: true)
                            }
                        }, failure: { [weak self] in
                            if let strongSelf = self {
                                strongSelf.showErrorAlert(String.localize("MSG_ERR_NETWORK_1009"))
                            }
                        }
                    )
                }
                
                self.navigationController?.push(viewController, animated: true)
            }
            
        } else if (indexPath.section == IMLandingSection.merchant.rawValue) {
            
            let presalesQueueViewController = PresalesQueueViewController()
            let merchant = self.merchants[indexPath.row]
            
            var queueType = "Queue-Presales"
            if merchant.merchantId == Constants.MMCSId {
                queueType = "Queue-General"
            }
            
            // Action tag
            if let cell = collectionView.cellForItem(at: indexPath) {
                cell.recordAction(
                    .Tap,
                    sourceRef: queueType,
                    sourceType: .Button,
                    targetRef: queueType,
                    targetType: .View
                )
            }
            
            presalesQueueViewController.merchant = merchant
            presalesQueueViewController.numberOfPreSales = self.numberOfPreSalesWithMerchantId(merchant.merchantId)
            self.navigationController?.push(presalesQueueViewController, animated: true)
        }
    }
    
    //MARK: - View Action
    
    @objc func addButtonClicked(_ sender : UIBarButtonItem){
        // record action
        view.analyticsViewKey = analyticsViewRecord.viewKey
        view.recordAction(
            .Tap,
            sourceRef: "FindFriend",
            sourceType: .Button,
            targetRef: "FindFriendOptions",
            targetType: .View
        )
        
        let optionMenu = UIAlertController(title: nil, message: nil, preferredStyle: .actionSheet)
        let initChatAction = UIAlertAction(title: String.localize("LB_IM_CHAT_GROUP_NEW"), style: .default, handler: {
            [weak self] (alert: UIAlertAction!) -> Void in
            if let strongSelf = self {
                // record action
                strongSelf.view.analyticsViewKey = strongSelf.analyticsViewRecord.viewKey
                strongSelf.view.recordAction(
                    .Tap,
                    sourceRef: "NewChatRoom",
                    sourceType: .Button,
                    targetRef: "ChatList",
                    targetType: .View
                )
                
                let initChatVC = InitChatViewController()
                initChatVC.isAgent = Context.isUserAgent()
                
                initChatVC.didCreateNewChat = { ack, convType in
                    if let convKey = ack.data {
                        var viewController: TSChatViewController!
                        if convType == .Private {
                            viewController = UserChatViewController(convKey: convKey)
                        }
                        else {
                            viewController = AgentChatViewController(convKey: convKey)
                        }
                        
                        strongSelf.navigationController?.push(viewController, animated: false)
                    } else {
                        ErrorLogManager.sharedManager.recordNonFatalError(withException: .NullPointer)
                    }
                }
                
                initChatVC.findFriend = {
                    // Action tag
                    strongSelf.view.analyticsViewKey = strongSelf.analyticsViewRecord.viewKey
                    strongSelf.view.recordAction(
                        .Tap,
                        sourceRef: "AddUser",
                        sourceType: .Button,
                        targetRef: "AddUser",
                        targetType: .View
                    )
                    let addFriendViewController = AddFriendViewController()
                    strongSelf.navigationController?.pushViewController(addFriendViewController, animated: true)
                }
                
                let navigationController = MmNavigationController(rootViewController: initChatVC)
                strongSelf.present(navigationController, animated: true, completion: nil)
            }
        })
        
        let findFriendAction = UIAlertAction(title: String.localize("LB_CA_IM_FIND_USER_ADD"), style: .default, handler: { [weak self] _ in
            // Action tag
            if let strongSelf = self {
                strongSelf.view.analyticsViewKey = strongSelf.analyticsViewRecord.viewKey
                strongSelf.view.recordAction(
                    .Tap,
                    sourceRef: "AddUser",
                    sourceType: .Button,
                    targetRef: "AddUser",
                    targetType: .View
                )
                
                strongSelf.navigationController?.push(AddFriendViewController(), animated: true)
            } else {
                ErrorLogManager.sharedManager.recordNonFatalError(withException: .NullPointer)
            }
        })
        
        let scanAction = UIAlertAction(title: String.localize("LB_CA_IM_SCAN_QR"), style: .default, handler: { [weak self] _ in
            Log.debug(String.localize("LB_CA_IM_SCAN_QR"))
            
            if let strongSelf = self {
                // record action
                
                strongSelf.view.analyticsViewKey = strongSelf.analyticsViewRecord.viewKey
                strongSelf.view.recordAction(
                    .Tap,
                    sourceRef: "Scan",
                    sourceType: .Button,
                    targetRef: "Scan",
                    targetType: .View
                )
                
                Utils.checkCameraPermissionWithCallBack({ (granted) in
                    if granted {
                        if (try? QRCodeReader.supportsMetadataObjectTypes()) ?? false {
                            strongSelf.navigationController?.push(MMScanQRCodeController(), animated: true)
                        } else {
                            ErrorLogManager.sharedManager.recordNonFatalError(withException: .NullPointer)
                        }
                    }else {
                        ErrorLogManager.sharedManager.recordNonFatalError(withException: .NullPointer)
                    }
                })
            }
        })
        
        let cancelAction = UIAlertAction(title: String.localize("LB_CA_CANCEL"), style: .cancel, handler: { [weak self] _ in
            if let strongSelf = self {
                // record action
                
                strongSelf.view.analyticsViewKey = strongSelf.analyticsViewRecord.viewKey
                strongSelf.view.recordAction(
                    .Tap,
                    sourceRef: "Cancel",
                    sourceType: .Button,
                    targetRef: "IMLanding",
                    targetType: .View
                )
            }
        })
        
        optionMenu.addAction(initChatAction)
        optionMenu.addAction(findFriendAction)
        optionMenu.addAction(scanAction)
        optionMenu.addAction(cancelAction)
        
        optionMenu.view.tintColor = UIColor.secondary2()
        
        self.present(optionMenu, animated: true, completion: nil)
        optionMenu.view.tintColor = UIColor.alertTintColor()
    }
    
    
    @objc func contactButtonTapped(){
        
        // Action tag
        self.view.analyticsViewKey = self.analyticsViewRecord.viewKey
        self.view.recordAction(
            .Tap,
            sourceRef: "ContactList",
            sourceType: .Button,
            targetRef: "ContactList",
            targetType: .View
        )
        
        let contactListVC = ContactListViewController()
        
        if merchants.isEmpty {
            contactListVC.isAgent = false
        }
        
        self.navigationController?.push(contactListVC, animated: true)
    }
    
    func reloadDataSource() {
        sortConvList()
        self.collectionView?.reloadData()
    }
    
    //MARK: - IMNoConversationCell Delegate
    
    func didSelectAddFriendButton(_ sender: UIButton) {
        self.navigationController?.push(AddFriendViewController(), animated: true)
    }
    
}
