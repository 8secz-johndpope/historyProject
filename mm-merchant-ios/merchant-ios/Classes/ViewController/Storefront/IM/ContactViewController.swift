//
//  ContactViewController.swift
//  merchant-ios
//
//  Created by HungPM on 5/16/16.
//  Copyright © 2016 WWE & CO. All rights reserved.
//

import Foundation
import PromiseKit

class ContactViewController: MmContactViewController, FriendListViewCellDelegate, NoCollectionItemCellDelegate {
    
    enum ContactViewControllerType: Int {
        case friendViewController
        case friendRequestViewController
        case companyViewController
        case otherViewController
    }

    enum MyRole: Int {
        case MMOnly
        case NotMM
        case MMAndMerchant
    }

    private let FriendListViewCellID = "FriendListViewCellID"
    private let ContactHeaderCellID = "ContactHeaderCellID"
    private let NoCollectionItemCellID = "NoCollectionItemCellID"
    private let CellHeight = CGFloat(60)

    private var myRole: MyRole?
    private var emptySearchText = ""
    private var queryText = ""
    private var currentMerchantId = 0
    private var targetUserKey = ""
    private var pickedMerchant: Merchant?
    private var pickerView: PickerView?
    private var backgroundView: UIView?
    private var isNoConnection = false
    private var queueType = QueueType.Unknown
    private var firstLoaded = false
    private var isShowingFriendList = true

    private var dataSource = [Any]()  {
        didSet {
            if collectionView != nil {
                filteredDataSource = dataSource
                collectionView.reloadData()
            }
        }
    }
    private var filteredDataSource = [Any]()

    var viewControllerType = ContactViewControllerType.friendViewController
    var searchBarMaxY = CGFloat(0)
    var conv: Conv?
    var otherMembersInGroup: [User]?
    var friendListMode = FriendListMode.normalMode
    var viewHeight = CGFloat(0)
    var isFromProfile = false
    var isForwardChat = false
    var chatModel: ChatModel?
    var tbHeight = CGFloat(0)
    var topMargin = CGFloat(50)
    
    var dismissViewController: ((User?) -> ())?
    var popViewController: ((User) -> ())?
    var pushViewController: ((UIViewController) -> ())?
    var needUpdateTitle: (() -> Void)?
    var didPopHandler: ((User, ChatModel) -> ())?
    var didPickMerchant: ((Merchant, QueueType) -> ())?
    var dismissSearchBar: (() -> Void)?

    //MARK:- Views
    override func viewDidLoad() {
        super.viewDidLoad()
        
        if let merchants = Context.customerServiceMerchants().merchants {
            var isMM = false
            var isMerchant = false
            
            for merchant in merchants {
                if merchant.merchantId == Constants.MMMerchantId {
                    isMM = true
                }
                else {
                    isMerchant = true
                }
            }
            
            if isMM && isMerchant {
                myRole = .MMAndMerchant
            }
            else if isMM {
                myRole = .MMOnly
            }
            else {
                myRole = .NotMM
            }
        }

        setupCollectionView()
        setupDismissKeyboardGesture()
        
        initAnalyticLog()
        
        isShowingFriendList = (viewControllerType == .friendViewController || viewControllerType == .companyViewController) ? true : false
        
        if viewControllerType == .companyViewController {
            getDataSource()
        }
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        
        if viewControllerType != .companyViewController {
            getDataSource()
        }
    }
    
    func setupCollectionView() {
        
        collectionView.frame = CGRect(x:collectionView.frame.origin.x, y: 0, width: collectionView.frame.width, height: viewHeight)
        collectionView.contentInset = UIEdgeInsets(top: topMargin, left: 0, bottom: 0, right: 0)
        
        collectionView.register(FriendListViewCell.self, forCellWithReuseIdentifier: FriendListViewCellID)
        collectionView.register(NoCollectionItemCell.self, forCellWithReuseIdentifier: NoCollectionItemCellID)
        
        if viewControllerType == .companyViewController || viewControllerType == .otherViewController {
            collectionView.register(ContactHeaderView.self, forSupplementaryViewOfKind: UICollectionElementKindSectionHeader, withReuseIdentifier: ContactHeaderCellID)
        }
    }
    
    func createPickerView() {
        pickerView = PickerView.fromNib()
        
        pickerView!.configPickerViewWithTitle(String.localize("LB_CA_CS_SEND_BY"), doneButonText: String.localize("LB_CONFIRM"), dataSource: [])
        
        pickerView!.frame = CGRect(x:0, y: self.view.frame.height, width: self.view.frame.width, height: 260)
        
        view.addSubview(pickerView!)
        
        pickerView!.doneButtonHandler = { [weak self] in
            if let strongSelf = self {
                strongSelf.dismissPickerView(true)
            } else {
                ErrorLogManager.sharedManager.recordNonFatalError(withException: .NullPointer)
            }
        }
    }
    
    func showPickerView() {
        backgroundView = UIView(frame: self.view.bounds)
        backgroundView!.backgroundColor = UIColor.clear
        view.addSubview(backgroundView!)
        
        let singleTap = UITapGestureRecognizer(target: self, action: #selector(dismissPickerView))
        backgroundView!.addGestureRecognizer(singleTap)
        
        view.bringSubview(toFront: pickerView!)
        
        UIView.animate(withDuration: 0.25) {
            self.pickerView!.frame = CGRect(x:self.pickerView!.frame.origin.x, y: self.view.frame.height - 260, width: self.pickerView!.frame.width, height: self.pickerView!.frame.height)
        }
    }

    @objc func dismissPickerView(_ doneButtonTapped: Bool = false) {
        UIView.animate(withDuration: 0.25, animations: {
            
            self.pickerView!.frame = CGRect(x:self.pickerView!.frame.origin.x, y: self.view.frame.height, width: self.pickerView!.frame.width, height: self.pickerView!.frame.height)
            
            })
        { finished in
            
            guard finished else { return }
            
            self.backgroundView!.removeFromSuperview()
            
            if doneButtonTapped {
                let senderMerchantId: Int = Context.customerServiceMerchants().merchants![self.pickerView!.picker!.selectedRow(inComponent: 0)].merchantId
                let myRole: UserRole = UserRole(userKey: Context.getUserKey(), merchantId: senderMerchantId)
                
                WebSocketManager.sharedInstance().sendMessage(
                    IMConvStartIntenalChatMessage(userList: [myRole],
                        senderMerchantId: senderMerchantId,
                        merchantId: self.currentMerchantId),
                    checkNetwork: true,
                    viewController: self,
                    completion: { [weak self] (ack) in
                        if let strongSelf = self, let convKey = ack.data {
                            let viewController = AgentChatViewController(convKey: convKey)
                            strongSelf.pushViewController?(viewController)
                        }
                    }
                )
            }
        }
    }
    
    func isForwardingToMM(_ merchant: Merchant?) -> Bool {
        if let myMerchant = merchant, myMerchant.merchantId == Constants.MMMerchantId {
            return true
        }
        return false
    }
    
    //MARK:- Collection View methods and delegates
    
    
    func numberOfSections(in collectionView: UICollectionView) -> Int {
        
        if viewControllerType == .companyViewController || viewControllerType == .otherViewController {
            if filteredDataSource.isEmpty {
                return 1
            }

            return filteredDataSource.count
        }
        
        return 1
    }
    
    override func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        if filteredDataSource.isEmpty {
            return 1
        }

        if viewControllerType == .companyViewController {
            if let merchant = filteredDataSource.get(section) as? Merchant, let user = merchant.users {
                return user.count
            }
        }
        
        if viewControllerType == .otherViewController {
            if isForwardChat {
                let merchant = filteredDataSource.get(section) as? Merchant
                if isForwardingToMM(merchant) {
                    return 3
                }

                return 4
            }
            
            return 1
        }

        return filteredDataSource.count
    }
    
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, referenceSizeForHeaderInSection section: Int) -> CGSize {

        if (viewControllerType == .companyViewController || viewControllerType == .otherViewController) && !filteredDataSource.isEmpty {
            return CGSize(width: view.bounds.width, height: 30)
        }
        
        return CGSize.zero
    }
    
    func collectionView(_ collectionView: UICollectionView, viewForSupplementaryElementOfKind kind: String, at indexPath: IndexPath) -> UICollectionReusableView {
        
        let view = collectionView.dequeueReusableSupplementaryView(ofKind: kind, withReuseIdentifier: ContactHeaderCellID, for: indexPath) as! ContactHeaderView
        
        if !filteredDataSource.isEmpty {
            if let merchant = filteredDataSource.get(indexPath.section) as? Merchant {
                if viewControllerType == .companyViewController {
                    if let users = merchant.users, !users.isEmpty {
                        view.merchantName.text = merchant.merchantName + " (\(users.count))"
                    }
                }
                else {
                    view.merchantName.text = merchant.merchantDisplayName
                }
            }
        }
        
        return view
    }
    
    override func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        let cell = collectionView.dequeueReusableCell(withReuseIdentifier: FriendListViewCellID, for: indexPath) as! FriendListViewCell
        cell.isExclusiveTouch = true
        
        if !filteredDataSource.isEmpty {
            switch viewControllerType {
            case .friendViewController, .friendRequestViewController:
                
                cell.chatButton.tag = indexPath.row
                cell.acceptButton.tag = indexPath.row
                cell.deleteButton.tag = indexPath.row
                cell.friendListViewCellDelegate = self
                
                if let user = filteredDataSource.get(indexPath.row) as? User {
                    cell.upperLabel.text = user.displayName
                    cell.setImage(user.profileImage, category: .user)
                    cell.setData(user, isFriend: isShowingFriendList)
                    
                    // Impression tag
                    cell.analyticsViewKey = self.analyticsViewRecord.viewKey
                    if let viewKey = cell.analyticsViewKey {
                        let impressionType = user.userTypeString()
                        cell.initAnalytics(withViewKey: viewKey, impressionKey: AnalyticsManager.sharedManager.recordImpression(impressionRef: user.userKey, impressionType: impressionType, impressionDisplayName: user.displayName, merchantCode: String(format: "%d", user.merchant.merchantId), positionComponent: "ContactListing", positionIndex: indexPath.row + 1, positionLocation: self.positionLocation(), viewKey: viewKey))
                    }
                }
                
                if friendListMode == .shareMode || friendListMode == .attachFriend || friendListMode == .tagMode || !isFromProfile || viewControllerType == .friendViewController {
                    cell.chatView.isHidden = true
                }

            case .companyViewController:
                if let merchant = filteredDataSource.get(indexPath.section) as? Merchant, let user = merchant.users?.get(indexPath.row) {
                    cell.upperLabel.text = user.displayName
                    cell.setImage(user.profileImage, category: .user)
                    
                    cell.chatView.isHidden = true
                    cell.buttonView.isHidden = true
                    
                    cell.diamondImageView.isHidden = true
                    cell.imageView.contentMode = .scaleAspectFit
                    cell.chatView.isHidden = true
                    cell.imageView.layer.borderWidth = 0.0
                }

            case .otherViewController:
                if isForwardChat {
                    let merchant = filteredDataSource.get(indexPath.section) as? Merchant
                    if self.isForwardingToMM(merchant) {
                        switch indexPath.row {
                        case 0:
                            cell.upperLabel.text = String.localize("LB_CS_QUEUE_GENERAL")
                            
                        case 1:
                            cell.upperLabel.text = String.localize("LB_CS_QUEUE_BUSINESS")
                            
                        case 2:
                            cell.upperLabel.text = String.localize("LB_CS_QUEUE_ESCAL")

                        default: break
                        }
                        
                    }
                    else {
                        switch indexPath.row {
                        case 0:
                            cell.upperLabel.text = String.localize("LB_CS_QUEUE_PRE_SALE")
                            
                        case 1:
                            cell.upperLabel.text = String.localize("LB_CS_QUEUE_POST_SALE")
                            
                        case 2:
                            cell.upperLabel.text = String.localize("LB_CS_QUEUE_GENERAL")
                            
                        case 3:
                            cell.upperLabel.text = String.localize("LB_CS_QUEUE_ESCAL")
                            
                        default: break
                        }
                    }

                }
                else {
                    switch indexPath.row {
                    case 0:
                        cell.upperLabel.text = String.localize("LB_CS_QUEUE_GENERAL")
        
                    default: break
                    }
                }
                
                if let merchant = filteredDataSource.get(indexPath.section) as? Merchant {
                    if merchant.merchantId != Constants.MMMerchantId { // not MM
                        cell.setImage(merchant.headerLogoImage, category: .merchant)
                    }
                    else {
                        cell.imageView.image = Merchant().MMImageIconBlack
                    }
                }
                cell.chatView.isHidden = true
                cell.buttonView.isHidden = true
                
                cell.diamondImageView.isHidden = true
                cell.imageView.layer.borderWidth = 0
                cell.imageView.layer.cornerRadius = 0
                cell.imageView.contentMode = .scaleAspectFit
                cell.chatView.isHidden = true
                
            }
            return cell
        }
        else {
            let cell = collectionView.dequeueReusableCell(withReuseIdentifier: NoCollectionItemCellID, for: indexPath) as! NoCollectionItemCell
            
            if isNoConnection {
                cell.label.isHidden = true
                cell.imageView.isHidden = true
                
                if noConnectionView == nil {
                    let ViewSize = CGSize(width: self.view.width, height: 198)
                    noConnectionView = NoConnectionView(frame: CGRect(x:0, y: (self.view.height - ViewSize.height) / 2.0, width: ViewSize.width, height: ViewSize.height))
                    noConnectionView!.reloadHandler = { [weak self] in
                        if let strongSelf = self {
                            strongSelf.getDataSource()
                        }
                    }
                }
                if noConnectionView!.superview == nil {
                    cell.addSubview(noConnectionView!)
                }
            }
            else {
                if noConnectionView?.superview != nil {
                    noConnectionView?.removeFromSuperview()
                }

                cell.imageView.isHidden = false

                cell.label.text = String.localize("LB_SEARCH_NO_RESULT")//Fix MM-21757
                cell.imageView.image = UIImage(named: "NoContact_icon")
                cell.imageView.isHidden = !firstLoaded
                cell.label.isHidden = !firstLoaded
                cell.setAddFriendButtonHidden(!firstLoaded)
                cell.delegate = self
            }
            return cell
        }
    }
    
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, sizeForItemAt indexPath: IndexPath) -> CGSize {
        if filteredDataSource.isEmpty {
            return collectionView.frame.size
        }
        
        return CGSize(width: view.frame.size.width , height: CellHeight)
    }
    
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, minimumInteritemSpacingForSectionAt section: Int) -> CGFloat {
        return 0.0
    }
    
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, minimumLineSpacingForSectionAt section: Int) -> CGFloat {
        return 0.0
    }
    
    func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        guard !filteredDataSource.isEmpty else {
            return
        }
        
        if isForwardChat {
            let merchant = filteredDataSource[indexPath.section] as? Merchant
            if self.isForwardingToMM(merchant) {
                switch indexPath.row {
                case 0:
                    queueType = .General
                case 1:
                    queueType = .Business
                case 2:
                    queueType = .Escalation

                default: break
                }
                
            }
            else {
                switch indexPath.row {
                case 0:
                    queueType = .Presales
                    
                case 1:
                    queueType = .Postsales
                    
                case 2:
                    queueType = .General
                    
                case 3:
                    queueType = .Escalation
                    
                default: break
                }
            }
        }
        else {
            queueType = .General
        }
        
        if !filteredDataSource.isEmpty {
            
            view.isUserInteractionEnabled = false
        
            switch viewControllerType {
            case .friendViewController, .friendRequestViewController:
                
                if friendListMode == .normalMode {
                    if let user = self.filteredDataSource.get(indexPath.row) as? User {
                        if queryText.length > 0 && isFromProfile {
                            view.analyticsViewKey = analyticsViewRecord.viewKey
                            view.recordAction(
                                .Input,
                                sourceRef: queryText,
                                sourceType: .Text,
                                targetRef: user.userKey
                            )
                        }
                        
                        if viewControllerType == .friendViewController && !isFromProfile {
                            view.isUserInteractionEnabled = false
                            
                            let myRole: UserRole = UserRole(userKey: Context.getUserKey())
                            let targetRole: UserRole = UserRole(userKey: user.userKey)
                            
                            WebSocketManager.sharedInstance().sendMessage(
                                IMConvStartMessage(userList: [myRole, targetRole], senderMerchantId: myRole.merchantId),
                                checkNetwork: true,
                                viewController: self,
                                completion: { [weak self] (ack) in
                                    
                                    if let strongSelf = self, let convKey = ack.data {
                                        let viewController = UserChatViewController(convKey: convKey)
                                        strongSelf.pushViewController?(viewController)
                                        strongSelf.view.isUserInteractionEnabled = true
                                    }
                                }, failure: { [weak self] in
                                    if let strongSelf = self {
                                        strongSelf.view.isUserInteractionEnabled = true
                                    }
                                }
                            )
                        }
                        else {
                           PushManager.sharedInstance.goToProfile(user, hideTabBar: false)
                        }
                        
                        view.isUserInteractionEnabled = true
                    }
                } else if friendListMode == .shareMode {
                    
                    if let user = self.filteredDataSource.get(indexPath.row) as? User {
                        
                        Alert.alert(
                            self,
                            title: String.localize("LB_CA_FORWARD"),
                            message: user.displayName,
                            okActionComplete: { [weak self] () -> Void in
                                if let strongSelf = self {
                                    if let chatModel = strongSelf.chatModel {
                                        strongSelf.didPopHandler?(user, chatModel)
                                    }
                                }
                            },
                            cancelActionComplete:nil)
                        
                        view.isUserInteractionEnabled = true
                    }
                    
                } else if friendListMode == .tagMode {
                    
                    if let user = self.filteredDataSource.get(indexPath.row) as? User {
                        dismissViewController?(user)
                    }
                    view.isUserInteractionEnabled = true
                    
                } else {
                    
                    if let user = self.filteredDataSource.get(indexPath.row) as? User {
                        Alert.alert(
                            self,
                            title: "", message:String.localize("LB_CA_IM_SHARE_FRD_NOTE").replacingOccurrences(of: "{0}", with: user.displayName),
                            okTitle: String.localize("LB_OK"),
                            okActionComplete: { [weak self] () -> Void in
                                if let strongSelf = self {
                                    strongSelf.popViewController?(user)
                                }
                            },
                            cancelActionComplete:nil)
                        
                        view.isUserInteractionEnabled = true
                    }
                }
                
            case .companyViewController:
                Log.debug("Company tap")
                
                if let merchant = self.filteredDataSource.get(indexPath.section) as? Merchant, let userKey = merchant.users?[indexPath.row].userKey {
                    
                    currentMerchantId = merchant.merchantId
                    targetUserKey = userKey
                    
                    let myRole: UserRole = UserRole(userKey: Context.getUserKey(), merchantId: currentMerchantId)
                    let targetRole: UserRole = UserRole(userKey: targetUserKey, merchantId: currentMerchantId)
                    
                    WebSocketManager.sharedInstance().sendMessage(
                        IMConvStartIntenalChatMessage(userList: [myRole, targetRole],
                            senderMerchantId: currentMerchantId,
                            merchantId: currentMerchantId),
                        checkNetwork: true,
                        viewController: self,
                        completion: { [weak self] (ack) in
                            if let strongSelf = self, let convKey = ack.data {
                                let viewController = AgentChatViewController(convKey: convKey)
                                strongSelf.pushViewController?(viewController)
                            }
                        }
                    )
                    
                    view.isUserInteractionEnabled = true
                }
                
            case .otherViewController:
                Log.debug("Other tap")
                
                if let merchant = self.filteredDataSource.get(indexPath.section) as? Merchant {
                    pickedMerchant = merchant
                    currentMerchantId = merchant.merchantId
                    
                    if isForwardChat {
                        didPickMerchant?(merchant, queueType)
                    }
                    else {
                        if pickerView == nil {
                            createPickerView()
                        }
                        
                        var pickerDataSource = [String]()
                        
                        if currentMerchantId == Constants.MMMerchantId {
                            if let merchants = Context.customerServiceMerchants().merchants {
                                for merchant in merchants {
                                    if merchant.merchantId != Constants.MMMerchantId {
                                        pickerDataSource.append(Context.getUserProfile().displayName + "(\(merchant.merchantCompanyName))")
                                    }
                                }
                            }
                        }
                        else {
                            pickerDataSource.append(Context.getUserProfile().displayName + "(\(Merchant.MM().merchantCompanyName))")
                        }
                        
                        pickerView!.dataSource = pickerDataSource
                        pickerView!.picker.reloadAllComponents()
                        
                        showPickerView()
                    }
                    view.isUserInteractionEnabled = true
                }
                
            }
            
            view.endEditing(true)
        }
        
        //record action
        var user: User?
        if viewControllerType == .friendViewController || viewControllerType == .friendRequestViewController {
            user = self.filteredDataSource.get(indexPath.row) as? User
        }
        else if viewControllerType == .companyViewController {
            if let merchant = self.filteredDataSource.get(indexPath.section) as? Merchant {
                user = merchant.users?.get(indexPath.row)
            }
        }
        
        if user != nil, let cell = collectionView.cellForItem(at: indexPath){
            let sourceType = AnalyticsActionRecord.ActionElement(rawValue: user!.userTypeString())
            let targetRef = user!.targetProfilePageTypeString()
            cell.recordAction(.Tap, sourceRef: user!.userKey, sourceType: sourceType ?? .User, targetRef: targetRef, targetType: .View)
        }
    }

    //MARK:- FriendListViewCellDelegate
    func chatClicked(_ rowIndex: Int, sender: UIButton) {
        
        
        if let friend = self.filteredDataSource.get(rowIndex) as? User {
            
            view.isUserInteractionEnabled = false
            
            let myRole: UserRole = UserRole(userKey: Context.getUserKey())
            let targetRole: UserRole = UserRole(userKey: friend.userKey)
            
            WebSocketManager.sharedInstance().sendMessage(
                IMConvStartMessage(userList: [myRole, targetRole], senderMerchantId: myRole.merchantId),
                checkNetwork: true,
                viewController: self,
                completion: { [weak self] (ack) in
                    if let strongSelf = self, let convKey = ack.data {
                        let viewController = UserChatViewController(convKey: convKey)
                        strongSelf.pushViewController?(viewController)
                        strongSelf.view.isUserInteractionEnabled = true
                    }
                }, failure: { [weak self] in
                    if let strongSelf = self {
                        strongSelf.view.isUserInteractionEnabled = true
                    }
                }
            )
        }
        
        // Action tag
        let indexPath = IndexPath(item: rowIndex, section: 0)
        if let cell = collectionView.cellForItem(at: indexPath) {
            cell.analyticsViewKey = self.analyticsViewRecord.viewKey
            cell.recordAction(
                .Tap,
                sourceRef: "Chat",
                sourceType: .Button,
                targetRef: "Chat-Friend",
                targetType: .View
            )
        }
    }

    func acceptClicked(_ rowIndex: Int, sender: UIButton) {
        Log.debug("acceptClicked: \(rowIndex)")
        
        if let user = self.filteredDataSource.get(rowIndex) as? User {
            
            view.isUserInteractionEnabled = false
            
            user.friendStatus = String.localize("LB_CA_IM_ACCEPTED")
            acceptRequest(user)
            
            //record action
            sender.recordAction(.Tap, sourceRef: "AddFriend-Accept", sourceType: .Button, targetRef: user.userKey, targetType: .User)
        }
    }
    
    func deleteClicked(_ rowIndex: Int, sender: UIButton) {
        Log.debug("deleteClicked: \(rowIndex)")
        
        if let user = self.filteredDataSource.get(rowIndex) as? User {
            
            view.isUserInteractionEnabled = false
            
            user.friendStatus = String.localize("LB_CA_IM_DELETED")
            deleteRequest(user)
            
            //record action
            sender.recordAction(.Tap, sourceRef: "AddFriend-Delete", sourceType: .Button, targetRef: user.userKey, targetType: .User)
        }
    }
 
    //MARK: - NoCollectionItemCellDelegate
    func didSelectAddFriendButton(_ sender: UIButton) {
        pushViewController?(AddFriendViewController())
    }
 
    // MARK:- Logging
    func positionLocation() -> String {
        var positionLocation = "Contact-All"
        switch viewControllerType {
        case .friendViewController:
            positionLocation = "Contact-All"
        case .friendRequestViewController:
            positionLocation = "Contact-FriendRequest"
        case .companyViewController:
            positionLocation = "Contact-Company"
        case .otherViewController:
            positionLocation = "Contact-Other"
        }
        
        return positionLocation
    }
 
    func initAnalyticLog(){
        initAnalyticsViewRecord(
            viewDisplayName: Context.getUsername(),
            viewParameters: Context.getUserKey(),
            viewLocation: self.positionLocation(),
            viewType: "IM"
        )
    }
    
    //MARK:- Keyboard
    override func keyboardWillShowNotification(_ notification: NSNotification) {
        super.keyboardWillShowNotification(notification)

        if let keyboardFrame = (notification.userInfo?[UIKeyboardFrameEndUserInfoKey] as? NSValue) {
            let keyboardSize = keyboardFrame.cgRectValue.size
            let contentInsets = UIEdgeInsets(top: 50, left: 0.0, bottom: keyboardSize.height - tbHeight, right: 0.0)
            
            collectionView.contentInset = contentInsets
            collectionView.scrollIndicatorInsets = contentInsets
            
        }
        else {
            ErrorLogManager.sharedManager.recordNonFatalError(withException: .NullPointer)
        }
    }
    
    override func keyboardWillHideNotification(_ notification: NSNotification) {
        super.keyboardWillHideNotification(notification)
        
        collectionView.contentInset = UIEdgeInsets(top: 50, left: 0.0, bottom: 0.0, right: 0.0)
        collectionView.scrollIndicatorInsets = UIEdgeInsets.zero
    }
    
    override func dismissKeyboardFromView() {
        dismissSearchBar?()
    }
    
    //MARK:- UISearchBarDelegate
    @objc func searchBarSearchButtonClicked(_ searchBar: UISearchBar) {
        filter(searchBar.text!)
        searchBar.resignFirstResponder()
    }
    
    @objc func searchBar(_ searchBar: UISearchBar, textDidChange searchText: String) {
        queryText = searchBar.text ?? ""
        
        if searchBar.text?.length == 0 && friendListMode != .tagMode {
            if !isForwardChat {
                if dataSource.isEmpty {
                    if viewControllerType == .friendViewController {
                        loadFriend()
                    }
                    else if viewControllerType == .friendRequestViewController {
                        loadFriendRequest()
                    }
                    else if viewControllerType == .companyViewController {
                        loadListContactCompany()
                    }
                    else {
                        loadListContactOther()
                    }
                }
                else {
                    filter("")
                }
            }
            else {
                if dataSource.count == 0 {
                    loadListContactOther()
                }
                else {
                    filter("")
                }
            }
        }
        else {
            filter(searchBar.text!)
        }
    }
    
    @objc func searchBarCancelButtonClicked(_ searchBar: UISearchBar) {
        searchBar.resignFirstResponder()
    }
    
    @objc func searchBarShouldBeginEditing(_ searchBar: UISearchBar) -> Bool {
        searchBar.showsCancelButton = true
        styleCancelButton(searchBar, enable: true)
        return true
    }
    
    @objc func searchBarShouldEndEditing(_ searchBar: UISearchBar) -> Bool {
        searchBar.showsCancelButton = false
        return true
    }
    
    @objc  func styleCancelButton(_ searchBar: UISearchBar, enable: Bool){
        if enable {
            if let _cancelButton = searchBar.value(forKey: "_cancelButton"),
                let cancelButton = _cancelButton as? UIButton {
                cancelButton.isEnabled = enable //comment out if you want this button disabled when keyboard is not visible
                cancelButton.setTitle(String.localize("LB_CANCEL"), for: UIControlState.normal)
            }
        }
    }
    
    func filter(_ text: String!) {
        if isForwardChat {
            if text.length == 0 {
                filteredDataSource = dataSource
            }
            else {
                if let dataSource = dataSource as? [Merchant] {
                    filteredDataSource = dataSource.filter(){ ($0.merchantDisplayName).lowercased().range(of: text.lowercased()) != nil }
                }
            }
        }
        else if friendListMode == .shareMode || friendListMode == .tagMode {
            if text.length == 0 {
                filteredDataSource = dataSource
            }
            else {
                if let dataSource = dataSource as? [User] {
                    filteredDataSource = dataSource.filter({ ($0.displayName).lowercased().range(of: text.lowercased()) != nil || ($0.userName).lowercased().range(of: text.lowercased()) != nil })
                }
            }
        }
        else {
            if viewControllerType == .friendViewController {
                if text.length == 0 {
                    filteredDataSource = dataSource
                }
                else {
                    if let dataSource = dataSource as? [User] {
                        filteredDataSource = dataSource.filter({ ($0.displayName).lowercased().range(of: text.lowercased()) != nil || ($0.userName).lowercased().range(of: text.lowercased()) != nil })
                    }
                    
                    if isFromProfile {
                        if filteredDataSource.isEmpty {
                            if emptySearchText == "" {
                                emptySearchText = text
                                
                                self.view.analyticsViewKey = self.analyticsViewRecord.viewKey
                                self.view.recordAction(
                                    .Input,
                                    sourceRef: text,
                                    sourceType: .Text,
                                    targetRef: "User"
                                )
                            }
                        }
                        else {
                            emptySearchText = ""
                        }
                    }
                }
            }
            else if viewControllerType == .friendRequestViewController {
                if text.length == 0 {
                    filteredDataSource = dataSource
                }
                else {
                    if let dataSource = dataSource as? [User] {
                        filteredDataSource = dataSource.filter({ ($0.displayName).lowercased().range(of: text.lowercased()) != nil || ($0.userName).lowercased().range(of: text.lowercased()) != nil })
                    }
                    
                    if isFromProfile {
                        if filteredDataSource.isEmpty {
                            if emptySearchText == "" {
                                emptySearchText = text
                                
                                self.view.analyticsViewKey = self.analyticsViewRecord.viewKey
                                self.view.recordAction(
                                    .Input,
                                    sourceRef: text,
                                    sourceType: .Text,
                                    targetRef: "User"
                                )
                            }
                        }
                        else {
                            emptySearchText = ""
                        }
                    }
                }
            }
            else if viewControllerType == .companyViewController {
                if text.length == 0 {
                    filteredDataSource = dataSource
                }
                else {
                    filteredDataSource.removeAll()
                    if let dataSource = dataSource as? [Merchant] {
                        for merchant in dataSource {
                            if let users = merchant.users {
                                let aMerchant = Merchant()
                                aMerchant.merchantId = merchant.merchantId
                                aMerchant.merchantName = merchant.merchantName
                                aMerchant.users = users.filter({ ($0.displayName).lowercased().range(of: text.lowercased()) != nil || ($0.userName).lowercased().range(of: text.lowercased()) != nil })
                                
                                if let users = aMerchant.users, !users.isEmpty {
                                    filteredDataSource.append(aMerchant)
                                }
                            }
                        }
                    }
                }
            }
            else {
                if text.length == 0 {
                    filteredDataSource = dataSource
                }
                else {
                    if let dataSource = dataSource as? [Merchant] {
                        filteredDataSource = dataSource.filter(){ ($0.merchantDisplayName).lowercased().range(of: text.lowercased()) != nil }
                    }
                }
            }
        }
        
        collectionView.reloadData()
    }
    
    //MARK: - Services
    func getDataSource() {
        if isForwardChat {
            loadListContactOther()
        }
        else if friendListMode == .shareMode {
            loadFriend()
        }
        else if friendListMode == .tagMode {
            if let otherMembersInGroup = otherMembersInGroup {
                dataSource = otherMembersInGroup
                filter(queryText)
            }
        }
        else {
            switch viewControllerType {
            case .friendViewController:
                loadFriend()

            case .friendRequestViewController:
                loadFriendRequest()

            case .companyViewController:
                loadListContactCompany()

            case .otherViewController:
                loadListContactOther()
            }
        }
    }
    
    func loadFriend() {
        firstly {
            return listFriends()
            }.then { friends -> Void in
                self.isNoConnection = false
                self.firstLoaded = true
                
                if friends.count > 0 {
                    if var dataSource = self.dataSource as? [User] {
                        dataSource = friends
                        dataSource.sortByDisplayName()
                        self.dataSource = dataSource
                    }
                }
                
                self.filter(self.queryText)
            }.catch { _ in
                Log.error("error")
                self.isNoConnection = true
                self.filter(self.queryText)
        }
    }
    
    func loadFriendRequest() {
        
        firstly {
            return listFriendRequest()
            }.then { friendRequests -> Void in
                
                self.isNoConnection = false
                self.firstLoaded = true
                
                if friendRequests.count > 0 {
                    if var dataSource = self.dataSource as? [User] {
                        dataSource = friendRequests
                        self.dataSource = dataSource
                    }
                }
                
                CacheManager.sharedManager.updateNumberOfFriendRequests(self.dataSource.count, notify: true)
                
                self.filter(self.queryText)
                
            }.always {
                self.needUpdateTitle?()
            }.catch { _ in
                Log.error("error")
                self.isNoConnection = true
                self.filter(self.queryText)
        }
    }
    
    func deleteRequest(_ user: User) {
        firstly {
            return deleteFriendRequest(user)
            }.then { _ -> Void in
                self.getDataSource()
                
                let value = CacheManager.sharedManager.numberOfFriendRequests - 1
                CacheManager.sharedManager.updateNumberOfFriendRequests(value, notify: true)
                
            }.always {
                self.view.isUserInteractionEnabled = true
            }.catch { _ -> Void in
                Log.error("error")
        }
    }
    
    func acceptRequest(_ user: User) {
        firstly {
            return acceptFriendRequest(user)
            }.then { _ -> Void in
                self.getDataSource()
                
                let value = CacheManager.sharedManager.numberOfFriendRequests - 1
                CacheManager.sharedManager.updateNumberOfFriendRequests(value, notify: true)
                CacheManager.sharedManager.addFriend(user)
            }.always {
                self.view.isUserInteractionEnabled = true
            }.catch { _ -> Void in
                Log.error("error")
        }
    }
    
    func deleteFriendRequest(_ user: User) -> Promise<Any> {
        return Promise{ fulfill, reject in
            FriendService.deleteRequest(user, completion: { [weak self] (response) in
                    if let strongSelf = self {
                        if response.result.isSuccess {
                            if response.response?.statusCode == 200 {
                                fulfill("OK")
                                CacheManager.sharedManager.deleteFriend(user)
                            }
                            else {
                                strongSelf.handleApiResponseError(response, reject: reject)
                            }
                        }
                        else{
                            reject(response.result.error!)
                            strongSelf.handleApiResponseError(response, reject: reject)
                        }
                    }
                    else {
                        ErrorLogManager.sharedManager.recordNonFatalError(withException: .NullPointer)
                    }
                })
        }
    }
    
    func acceptFriendRequest(_ user: User) -> Promise<Any> {
        return Promise{ fulfill, reject in
            FriendService.acceptRequest(user, completion: { [weak self] (response) in
                    if let strongSelf = self {
                        if response.result.isSuccess {
                            if response.response?.statusCode == 200 {
                                fulfill("OK")
                            }
                            else {
                                strongSelf.handleApiResponseError(response, reject: reject)
                            }
                        }
                        else {
                            reject(response.result.error!)
                            strongSelf.handleApiResponseError(response, reject: reject)
                        }
                    }
                    else {
                        ErrorLogManager.sharedManager.recordNonFatalError(withException: .NullPointer)
                    }
                })
        }
    }
    
    func loadListContactCompany() {
        func listMerchant(_ merchant: Merchant) -> Promise<[Merchant]> {
            return Promise { fulfill, reject in
                firstly {
                    return listMerchantAgent(merchant.merchantId)
                    }.then { users -> Void in
                        merchant.users = users
                        fulfill([merchant])
                    }.catch { error -> Void in
                        reject(error)
                }
            }
        }
        
        var promiseList = [Promise<[Merchant]>]()
        if Context.IAmMMAgent() {
            promiseList = [listMMAgent()]
            Context.customerServiceMerchants().merchants?.forEach({ (merchant) in
                promiseList.append(listMerchant(merchant))
            })
        }
        else {
            Context.customerServiceMerchants().merchants?.forEach({ (merchant) in
                promiseList.append(listMerchant(merchant))
            })
        }
        
        when(fulfilled: promiseList).then { (agents) -> Void in
            self.dataSource.removeAll()
            if var dataSource = self.dataSource as? [Merchant] {
                for agent in agents {
                    dataSource += agent
                }
                self.dataSource = dataSource

                for merchant in self.dataSource as! [Merchant] {
                    
                    if let myMerchants =  Context.customerServiceMerchants().merchants {
                        var isMerchantMatched = false
                        for myMerchant in myMerchants {
                            if merchant.merchantId == myMerchant.merchantId {
                                isMerchantMatched = true
                            }
                        }
                        if !isMerchantMatched && merchant.merchantId != Constants.MMMerchantId {
                            dataSource.remove(merchant)
                        }
                    }
                    
                    if merchant.users != nil {
                        for user in merchant.users! {
                            if user.userKey == Context.getUserKey() {
                                merchant.users!.remove(user)
                                break
                            }
                        }
                        
                        if merchant.users!.isEmpty {
                            dataSource.remove(merchant)
                        }
                    }
                    
                    merchant.users?.sort(by: { $0.displayName.lowercased() < $1.displayName.lowercased() })
                }
            }
            
            self.firstLoaded = true
            self.filter(self.queryText)
            
            }.catch { _ in
                Log.error("error")
                self.isNoConnection = true
                self.filter(self.queryText)
        }
        
    }
    
    func getListMerchant(dataSource:[Merchant]) {
        var data = dataSource
        firstly {
            self.listMerchant()
            }.then { merchants -> Void in
                self.isNoConnection = false
                self.firstLoaded = true
                data += merchants
                self.dataSource = dataSource
            }.always {
                self.filter(self.queryText)
            }.catch { _ in
                Log.error("error")
                self.dataSource.removeAll()
                self.isNoConnection = true
                self.filter(self.queryText)
        }
    }
    
    func loadListContactOther() {
        dataSource.removeAll()
        
        if isForwardChat {
            if var dataSource = self.dataSource as? [Merchant] {
                dataSource.append(Merchant.MM())
                
                if let conv = self.conv, conv.IAmMM() == true {
                    // show MM + all merchants (call API service) with correct queue
                    firstly {
                        listMerchant()
                        }.then { merchants -> Void in
                            self.isNoConnection = false
                            self.firstLoaded = true

                            dataSource += merchants
                            self.dataSource = dataSource
                            
                        }.always {
                            self.filter(self.queryText)
                        }.catch { _ in
                            Log.error("error")
                            self.dataSource.removeAll()
                            self.isNoConnection = true
                    }
                }
                else {
                    // show MM + self-merchant with correct queue
                    if let merchant = conv?.merchantObject {
                        dataSource.append(merchant)
                    }
                    self.dataSource = dataSource
                    self.firstLoaded = true
                    self.filter(self.queryText)
                }
            }
            
        }
        else {
            if var dataSource = self.dataSource as? [Merchant] {
                
                getListMerchant(dataSource: dataSource)
                
                if let myRole = self.myRole {
                    switch myRole {
                    case .MMAndMerchant:
                        dataSource.append(Merchant.MM())
                        getListMerchant(dataSource: dataSource)
                        
                    case .MMOnly:
                        getListMerchant(dataSource: dataSource)
                        
                    case .NotMM:
                        self.dataSource.append(Merchant.MM())

                        self.firstLoaded = true
                        self.filter(queryText)
                    }
                }

            }
        }
    }

}
