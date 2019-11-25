//
//  GroupChatInfoViewController.swift
//  merchant-ios
//
//  Created by Vo Huy Hung on 6/15/16.
//  Copyright © 2016 WWE & CO. All rights reserved.
//

import UIKit

class GroupChatInfoViewController: MmViewController {
    
    private final let GroupChatCellID = "GroupChatCellID"
    private final let GroupChatNameCellID = "GroupChatNameCellID"
    private final let GroupChatHeaderViewID = "GroupChatHeaderViewID"
    private final let GroupChatFooterViewID = "GroupChatFooterViewID"
    private final let DefaultHeaderID = "DefaultHeaderID"

    private final let HeightOfHeaderView = CGFloat(50)
    private final let HeightOfFooterView = CGFloat(55)
    private final let HeightOfChangeNameCell = CGFloat(44)

    private final var changeNameCell: GroupChatNameCell!
    
    var userListCell : GroupChatCell?
    
    var seeMoreSelected = false
    
    var conv: Conv!
    var groupChatName: String?
    
    var didCreateNewChat: ((IMAckMessage, ConvType) -> ())?

    override func viewDidLoad() {
        super.viewDidLoad()
        
        NotificationCenter.default.addObserver(self, selector: #selector(reloadConv), name: NSNotification.Name(rawValue: IMDidUpdateConversationList), object: nil)

        // Do any additional setup after loading the view.
        setupNavigationBar()
        setupCollectionView()
        reloadData()
        
        initAnalyticLog()
    }
        
    func initAnalyticLog(){
        initAnalyticsViewRecord(
            merchantCode: String(describing: conv?.merchantObject?.merchantCode),
            viewDisplayName: "ChatInfo",
            viewLocation: "ChatInfo",
            viewRef: conv?.convKey,
            viewType: "IM"
        )
    }
    
    func reloadData() {
        if conv.isAllowLeaveChat() {
            self.createBottomButton(String.localize("LB_CS_CHAT_LEAVE"), customAction: #selector(leaveGroup), useSecondaryStyle: true)
        }
        
        if conv.isGroupChat() && (conv.isFriendChat() || conv.isInternalChat()) {
            groupChatName = conv.defaultGroupChatName()
        }
        
        collectionView.reloadData()
    }
    
    @objc func reloadConv() {
        if let convKey = self.conv?.convKey, let conv = WebSocketManager.sharedInstance().conversationForKey(convKey) {
            self.conv = conv
        }
        
        reloadData()
    }
    
    @objc func leaveGroup(button: UIButton) {
        if Reachability.shared().currentReachabilityStatus() == NotReachable {
            Alert.alertWithSingleButton(self, title: "", message: String.localize("MSG_ERR_NETWORK_FAIL"), buttonString: String.localize("LB_CA_CONFIRM"))
            return
        }

        Alert.alert(self, title: "", message: String.localize("LB_CS_CHAT_GROUP_DELETE"), okActionComplete: { [weak self] () -> Void in
            if let strongSelf = self, let myUserRole = strongSelf.conv.myUserRole {
                WebSocketManager.sharedInstance().sendMessage(
                    IMConvRemoveMessage(convKey:strongSelf.conv.convKey, userList: [myUserRole], myUserRole: myUserRole),
                    completion: { _ in
                        WebSocketManager.sharedInstance().removeConv(strongSelf.conv)
                        CacheManager.sharedManager.deleteConv(strongSelf.conv.convKey)
                        PostNotification(IMDidUpdateConversationList, object:nil)
                        strongSelf.navigationController?.popToRootViewController(animated: true)
                    })
            } else {
                ErrorLogManager.sharedManager.recordNonFatalError(withException: .NullPointer)
            }
            })
    }
    
    func setupCollectionView() {
        collectionView.isScrollEnabled = true
        collectionView.alwaysBounceVertical = false
        collectionView.register(GroupChatCell.self, forCellWithReuseIdentifier: GroupChatCellID)
        collectionView.register(GroupChatNameCell.self, forCellWithReuseIdentifier: GroupChatNameCellID)
        collectionView.register(GroupChatHeaderView.self, forSupplementaryViewOfKind: UICollectionElementKindSectionHeader, withReuseIdentifier: GroupChatHeaderViewID)
        collectionView.register(UICollectionReusableView.self, forSupplementaryViewOfKind: UICollectionElementKindSectionHeader, withReuseIdentifier: DefaultHeaderID)
        collectionView.register(GroupChatFooterView.self, forSupplementaryViewOfKind: UICollectionElementKindSectionFooter, withReuseIdentifier: GroupChatFooterViewID)
    }
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    func setupNavigationBar() {
        
        self.title = String.localize("LB_CA_IM_CHAT_INFO")
        
        let buttonBack = UIButton(type: .custom)
        buttonBack.setImage(UIImage(named: "back_grey"), for: .normal)
        buttonBack.frame = CGRect(x:0, y: 0, width: Constants.Value.BackButtonWidth, height: Constants.Value.BackButtonHeight)
        buttonBack.contentEdgeInsets = UIEdgeInsets.init(top: 0, left: Constants.Value.BackButtonMarginLeft, bottom: 0, right: 0)
        let leftButton = UIBarButtonItem(customView: buttonBack)
        
        buttonBack.addTarget(self, action: #selector(backButtonTapped), for: .touchUpInside)
        
        self.navigationItem.leftBarButtonItem = leftButton
        self.navigationItem.hidesBackButton = false
    }
    
    //MARK: Action handler
    @objc func backButtonTapped() {
        self.navigationController?.popViewController(animated:true)
    }
    
    //MARK: CollectionView Data Source, Delegate Method
    func numberOfSections(in collectionView: UICollectionView) -> Int {
       
        if conv.isGroupChat() && (conv.isFriendChat() || conv.isInternalChat()) {
            return 2
        }
        
        return 1
    }
    
    override func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return 1
    }
    
    func collectionView(_ collectionView: UICollectionView, viewForSupplementaryElementOfKind kind: String, at indexPath: IndexPath) -> UICollectionReusableView {
        
        if indexPath.section == 0 {
            if kind == UICollectionElementKindSectionHeader {
                let headerView = collectionView.dequeueReusableSupplementaryView(ofKind: kind, withReuseIdentifier: GroupChatHeaderViewID, for: indexPath) as! GroupChatHeaderView
                headerView.label.text = String.localize("LB_IM_CHAT_ALL_MEMBER").replacingOccurrences(of: "{0}", with: "\(self.conv.userList.count)")
                
                if !conv.isAllowInviteGroupChat() {
                    headerView.addButton.isHidden  = true
                } else {
                    headerView.addButton.isHidden  = false
                }
                
                headerView.addButtonTappedHandler = { [weak self] in
                    if let strongSelf = self {
                        let initChatVC = InitChatViewController()
                        initChatVC.conv = strongSelf.conv
                        
                        initChatVC.didCreateNewChat = { ack, convType in
                            if let convKey = ack.data {
                                strongSelf.conv = Conv(convKey: convKey)
                                strongSelf.reloadConv()
                                strongSelf.didCreateNewChat?(ack, convType)
                            }
                        }
                        
                        let navigationController = MmNavigationController(rootViewController: initChatVC)
                        strongSelf.present(navigationController, animated: true, completion: nil)
                    } else {
                        ErrorLogManager.sharedManager.recordNonFatalError(withException: .NullPointer)
                    }
                }
                return headerView
            } else  {
                let footerView = collectionView.dequeueReusableSupplementaryView(ofKind: kind, withReuseIdentifier: GroupChatFooterViewID, for: indexPath) as! GroupChatFooterView
                
                footerView.seeMoreSelected = self.seeMoreSelected
                
                footerView.seeMoreButtonTappedHandler = { [weak self] in
                    if let strongSelf = self {
                        strongSelf.seeMoreSelected = footerView.seeMoreSelected
                        
                        collectionView.performBatchUpdates({
                            if strongSelf.seeMoreSelected {
                                strongSelf.userListCell?.expandShowDetailWithHeight(strongSelf.calculateHeightOfCell())
                            } else {
                                strongSelf.userListCell?.collapseRemoveDetailWithHeight(strongSelf.calculateHeightOfCell())
                            }
                            }, completion: nil)
                    } else {
                        ErrorLogManager.sharedManager.recordNonFatalError(withException: .NullPointer)
                    }
                }
                return footerView
            }
        }
        
        let view = collectionView.dequeueReusableSupplementaryView(ofKind: kind, withReuseIdentifier: DefaultHeaderID, for: indexPath)
        view.backgroundColor = UIColor(hexString: "f6f6f6")
        
        return view
    }
    
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, referenceSizeForHeaderInSection section: Int) -> CGSize {
        if section == 0 {
            return CGSize(width: self.view.bounds.width, height: HeightOfHeaderView)
        }
        
        return CGSize(width: self.view.bounds.width, height: 20)
    }
    
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, referenceSizeForFooterInSection section: Int) -> CGSize {
        if section == 0 {
            if self.conv.userList.count > Int(GroupChatMaximumUsersInARow * GroupChatMaximumRows) {
                return CGSize(width: self.view.bounds.width, height: HeightOfFooterView)
            } else  {
                return CGSize(width: self.view.bounds.width, height: 1)
            }
        }
        
        return CGSize(width: self.view.bounds.width, height: 0)
    }
    
    override func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        
        if indexPath.section == 0 {
            let cell = collectionView.dequeueReusableCell(withReuseIdentifier: GroupChatCellID, for: indexPath) as! GroupChatCell
            cell.conv = self.conv
            self.userListCell = cell
            
            cell.userCellImpressionHandler = { [weak self] (user) in
                if let strongSelf = self {
                    // Impression tag
                    let impressionType = user.userTypeString()
                    let parentType = strongSelf.conv.chatTypeString()
                    
                    let impressionKey = strongSelf.recordImpression(
                        impressionRef: user.userKey,
                        impressionType: impressionType,
                        impressionDisplayName: user.displayName,
                        merchantCode: strongSelf.conv.merchantObject?.merchantCode,
                        parentRef: strongSelf.conv.convKey,
                        parentType: parentType,
                        positionComponent: "MemberListing",
                        positionIndex: indexPath.row + 1,
                        positionLocation: "ChatInfo"
                    )
                    cell.initAnalytics(withViewKey: strongSelf.analyticsViewRecord.viewKey, impressionKey: impressionKey)
                } else {
                    ErrorLogManager.sharedManager.recordNonFatalError(withException: .NullPointer)
                }
            }
        
            cell.userCellTappedHandler = { (user) in
              
                    
                    let sourceType = AnalyticsActionRecord.ActionElement(rawValue: user.userTypeString())
                    let targetRef = user.targetProfilePageTypeString()
                    
                    cell.recordAction(
                        .Tap,
                        sourceRef: user.userKey,
                        sourceType: sourceType ?? .User,
                        targetRef: targetRef,
                        targetType: .View
                    )
                    PushManager.sharedInstance.goToProfile(user, hideTabBar: true)
           
            }
            return cell

        }

        let cell = collectionView.dequeueReusableCell(withReuseIdentifier: GroupChatNameCellID, for: indexPath) as! GroupChatNameCell
        cell.lblGroupName.text = groupChatName
        
        changeNameCell = cell
        
        return cell
    }
    
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, sizeForItemAt indexPath: IndexPath) -> CGSize {
        if indexPath.section == 0 {
            return CGSize(width: view.width, height: self.calculateHeightOfCell())
        }
        
        return CGSize(width: view.width, height: HeightOfChangeNameCell)
    }
    
    func calculateHeightOfCell() -> CGFloat {
        var numbersOfRow = ceil(CGFloat(self.conv.userList.count)/GroupChatMaximumUsersInARow)
        
        if !seeMoreSelected && numbersOfRow > GroupChatMaximumRows {
            numbersOfRow = GroupChatMaximumRows
        }
        
        let actualHeightOfCell = numbersOfRow * GroupChatHeightOfARow + numbersOfRow * GroupChatMinimumLineSpacing + GroupChatPaddingTop
        
        return actualHeightOfCell
    }
    
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, minimumInteritemSpacingForSectionAt section: Int) -> CGFloat {
        return 0.0
    }
    
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, minimumLineSpacingForSectionAt section: Int) -> CGFloat {
        return 0.0
    }
    
    func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        if indexPath.section == 1 {
            let changeNameVC = GroupChangeNameViewController()
            changeNameVC.groupName = changeNameCell.lblGroupName.text
            changeNameVC.conv = self.conv
            changeNameVC.groupNameDidSave = { [weak self] name in
                if let strongSelf = self {
                    strongSelf.groupChatName = name
                    strongSelf.changeNameCell.lblGroupName.text = name
                } else {
                    ErrorLogManager.sharedManager.recordNonFatalError(withException: .NullPointer)
                }
            }
            let navigationController = MmNavigationController(rootViewController: changeNameVC)
            self.present(navigationController, animated: true, completion: nil)
        }
    }
    
    // MARK: - Config View
    override func collectionViewBottomPadding() -> CGFloat {
        if conv.isAllowLeaveChat() {
            return Constants.BottomButtonContainer.Height
        }
        
        return 0
    }
}
