//
//  InitChatViewController.swift
//  merchant-ios
//
//  Created by HungPM on 6/14/16.
//  Copyright © 2016 WWE & CO. All rights reserved.
//

import Foundation
import PromiseKit

class InitChatViewController: MmContactViewController {
    
    private final let ContactCellID = "ContactCellID"
    private final let ContactHeaderCellID = "ContactHeaderCellID"
    private final let DefaultCellId = "DefaultCellId"
    private final let Limit = 99 // 1 is my self
    private final var pickerView: PickerView?
    private final var backgroundView: UIView?
    private final var topView: InitChatTopView!
    private final var dataSource = [Any]()
    private final var pickerDataSource = [Any]()
    private final var currentMerchantId: Int?
    private final var friends = [User]()
    private final var merchants = [Merchant]()
    private final var existingUsers = [UserRole]()

    private final var currentIndex = 0
    private final var labelSearchResult: UILabel!
    
    private final var noContactView: UIView?
    private final var addFriendView: UIView?

    var isAgent = true
    var conv: Conv?
    
    var didCreateNewChat: ((_ ack: IMAckMessage, _ convType: ConvType) -> ())?
    var findFriend: (() -> Void)?

    // MARK: - View lifecycle
    override func viewDidLoad() {
        super.viewDidLoad()
        loadExistingUsers()
        
        setupNavigationBar()
        setupDismissKeyboardGesture()
        loadPickerDataSource()
        createTopView()
        createSearchResultView()
        updateOkButtonState()
        setupCollectionView()
        
        loadData()
    }
    
    func loadExistingUsers() {
        if let conv = self.conv {
            isAgent = false

            for userRole in conv.userList {
                if let userKey = userRole.userKey, userKey != Context.getUserKey() {
                    existingUsers.append(userRole)
                }
            }
            
            currentMerchantId = conv.merchantId
        } else {
            ErrorLogManager.sharedManager.recordNonFatalError(withException: .NullPointer)
        }
    }
    
    func loadPickerDataSource() {
        pickerDataSource.append(String.localize("LB_IM_CS_IDEN_PERSONAL"))
        
        if let merchants = Context.customerServiceMerchants().merchants {
            for merchant in merchants {
                pickerDataSource.append(merchant)
            }
        }
    }
    
    func showNoContactView(_ isPersonalRole: Bool) {
        let AddFriendViewHeight = CGFloat(55)

        if noContactView == nil {
            noContactView = { () -> UIView in
                let view = UIView(frame: CGRect(x: 0, y: 0, width: self.view.width, height: 105))
                view.backgroundColor = UIColor.clear

                let ImageWidth = CGFloat(80)
                
                let imgViewNoContact = UIImageView(image: UIImage(named: "NoContact_icon"))
                imgViewNoContact.frame = CGRect(x: (view.width - ImageWidth) / 2.0, y: 0, width: ImageWidth, height: ImageWidth)
                imgViewNoContact.contentMode = .scaleAspectFit
                view.addSubview(imgViewNoContact)

                let lblNoContact = UILabel(frame: CGRect(x: 0, y: imgViewNoContact.frame.maxY, width: view.width, height: 25))
                lblNoContact.text = String.localize("LB_CA_IM_CONTACT_EMPTY")
                lblNoContact.textAlignment = .center
                lblNoContact.textColor = UIColor.secondary2()
                lblNoContact.font = UIFont.systemFont(ofSize: 14)
                view.addSubview(lblNoContact)

                collectionView.addSubview(view)

                view.isHidden = true
                return view
            }()
        }
        
        if isPersonalRole {
            if addFriendView == nil {
                addFriendView = { () -> UIView in
                    let view = UIView(frame: CGRect(x: 0, y: collectionView.height - AddFriendViewHeight - ScreenBottom, width: self.view.width, height: AddFriendViewHeight + ScreenBottom))
                    view.backgroundColor = UIColor.clear

                    let separatorView = UIView(frame: CGRect(x: 0, y: 0, width: collectionView.width, height: 1))
                    separatorView.backgroundColor = UIColor.secondary1()
                    view.addSubview(separatorView)
                    
                    collectionView.addSubview(view)
                    
                    let ImageWidth = CGFloat(30)
                    let imgViewAddFriend = UIImageView(image: UIImage(named: "addFriend_icon"))
                    imgViewAddFriend.frame = CGRect(x: 0, y: 0, width: ImageWidth, height: ImageWidth)
                    imgViewAddFriend.contentMode = .scaleAspectFit
                    
                    let lblAddFriend = UILabel(frame: CGRect(x: imgViewAddFriend.frame.maxX, y: 0, width: 80, height: ImageWidth))
                    lblAddFriend.text = String.localize("LB_CA_GO_TO_ADD_FRIEND")
                    lblAddFriend.textColor = UIColor.red
                    lblAddFriend.font = UIFont.systemFont(ofSize: 14)
                    lblAddFriend.sizeToFit()
                    
                    let viewContainer = UIView(frame: CGRect(x: 0, y: 0, width: lblAddFriend.bounds.width + imgViewAddFriend.bounds.width + 5, height: ImageWidth))
                    viewContainer.addSubview(imgViewAddFriend)
                    viewContainer.addSubview(lblAddFriend)
                    lblAddFriend.center = CGPoint(x: lblAddFriend.center.x, y: viewContainer.height / 2.0)
                    viewContainer.center = CGPoint(x: self.view.center.x, y: view.height / 2.0)
                    view.addSubview(viewContainer)
                    
                    view.addGestureRecognizer(UITapGestureRecognizer(target: self, action: #selector(findFriendTapped)))
                        
                    view.isHidden = true
                    return view
                }()
            }
            
            addFriendView?.isHidden = false
        }
        else {
            addFriendView?.isHidden = true
        }
        
        noContactView!.center = CGPoint(x: collectionView.center.x, y: isPersonalRole ? (collectionView.height - AddFriendViewHeight) / 2.0 : collectionView.height / 2.0)
        noContactView!.isHidden = false
    }
    
    func hideNoContactView() {
        noContactView?.isHidden = true
        addFriendView?.isHidden = true
    }
    
    func loadData() {
        
        if let merchantId = currentMerchantId {
            loadListAgentWithMerchantId(merchantId)
        }
        else {
            loadFriend()
        }
    }
    
    func setupNavigationBar() {
        if let conv = self.conv, !conv.shouldStartNewConv() {
            self.title = String.localize("LB_IM_CHAT_WITH_ADD")
        }
        else {
            self.title = String.localize("LB_IM_CHAT_GROUP_NEW")
        }
        
        self.createBackButton(.crossSmall)
    }
    
    override func backButtonClicked(_ button: UIButton) {
        self.cancelButtonTapped()
    }
    
    func createTopView() {
        var viewHeight = CGFloat(60)
        var hideSendFrom = true
        if isAgent {
            viewHeight = CGFloat(120)
            hideSendFrom = false
        }

        topView = InitChatTopView(frame: CGRect(x: 0, y: StartYPos, width: Constants.ScreenSize.SCREEN_WIDTH, height: viewHeight))
        topView.roleLabel.text = pickerDataSource[0] as? String
        topView.merchantView.isHidden = hideSendFrom
        
        if conv != nil {
            topView.lblSendTo.text = String.localize("LB_IM_CHAT_GROUP_WITH_ADD")
        }
        else {
            topView.lblSendTo.text = String.localize("LB_IM_CHAT_WITH_NEW")
        }
        topView.layoutSubviews()
        
        topView.viewMerchantTapHandler = { [weak self] in
            if let strongSelf = self {
                strongSelf.view.endEditing(true)
                
                if strongSelf.pickerView == nil {
                    strongSelf.createPickerView()
                }
                strongSelf.showPickerView()
            }
        }
        
        topView.userTapHandler = { [weak self] user in
            if let strongSelf = self {
                strongSelf.updateOkButtonState()
                user.isSelected = false
                if strongSelf.currentMerchantId == nil {
                    if let index = strongSelf.dataSource.index(where: { (usr) -> Bool in
                        return (usr as! User) == user
                    }) {
                        strongSelf.collectionView.reloadItems(at: [IndexPath(row: index, section: 0)])
                    }
                }
                else {
                    for (section, merchant) in strongSelf.dataSource.enumerated() {
                        let aMerchant = merchant as! Merchant
                        if let users = aMerchant.users {
                            for (row, aUser) in users.enumerated() {
                                if aUser.userKey == user.userKey {
                                    strongSelf.collectionView.reloadItems(at: [IndexPath(row: row, section: section)])
                                    return
                                }
                            }
                        }
                    }
                }
            }
        }
        
        topView.searchFieldTextDidChangeHandler = { [weak self] text in
            guard let strongSelf = self else { return }
            
            strongSelf.filter(text)
        }
        
        view.addSubview(topView)
    }

    func createSearchResultView() {
        labelSearchResult = UILabel(frame: CGRect(x: 0, y: 0, width: Constants.ScreenSize.SCREEN_WIDTH, height: 30))
        labelSearchResult.format()
        labelSearchResult.textAlignment = .center
        labelSearchResult.text = String.localize("LB_SEARCH_NO_RESULT")
        labelSearchResult.isHidden = true
        collectionView.addSubview(labelSearchResult)
        
        labelSearchResult.center = CGPoint(x: collectionView.center.x, y: collectionView.height / 2.0)
    }

    // MARK: - Filter
    func filter(_ text: String) {
        if currentMerchantId == nil {
            if text.length == 0 {
                dataSource = friends
            } else {
                dataSource = friends.filter(){ ($0.displayName).lowercased().range(of: text.lowercased()) != nil || ($0.userName).lowercased().range(of: text.lowercased()) != nil }
            }
        }
        else {
            if text.length == 0 {
                dataSource = merchants
            } else {
                dataSource.removeAll()
                
                for merchant in merchants {
                    
                    if let users = merchant.users {
                        let aMerchant = Merchant()
                        aMerchant.merchantId = merchant.merchantId
                        aMerchant.merchantName = merchant.merchantName
                        aMerchant.users = users.filter({ ($0.displayName).lowercased().range(of: text.lowercased()) != nil || ($0.userName).lowercased().range(of: text.lowercased()) != nil })
                        
                        if let users = aMerchant.users, !users.isEmpty {
                            dataSource.append(aMerchant)
                        }
                    }
                }
            }
        }
        
        if !dataSource.isEmpty {
            labelSearchResult.isHidden = true
        } else {
            if let noContactView = noContactView {
                if noContactView.isHidden {
                    labelSearchResult.isHidden = false
                }
                else {
                    labelSearchResult.isHidden = true
                }
            }
            else {
                labelSearchResult.isHidden = false
            }
        }
        
        collectionView.reloadData()
    }
    
    func setupCollectionView() {
        collectionView.alwaysBounceVertical = false

        collectionView.register(InitChatContactCell.self, forCellWithReuseIdentifier: ContactCellID)
        collectionView.register(UICollectionViewCell.self, forCellWithReuseIdentifier: DefaultCellId)
        collectionView.register(ContactHeaderView.self, forSupplementaryViewOfKind: UICollectionElementKindSectionHeader, withReuseIdentifier: ContactHeaderCellID)
    }
    
    // MARK: - Picker
    func createPickerView() {
        pickerView = PickerView.fromNib()
        
        var dataSource = [String]()
        
        for (index, object) in pickerDataSource.enumerated() {
            if index == 0 {
                dataSource.append(object as! String)
            }
            else {
                dataSource.append((object as! Merchant).merchantCompanyName)
            }
        }
        
        pickerView!.configPickerViewWithTitle(String.localize("LB_CA_CS_SEND_BY"), doneButonText: String.localize("LB_CONFIRM"), dataSource: dataSource)

        pickerView!.frame = CGRect(x: 0, y: view.frame.height, width: view.frame.width, height: 260)
        
        view.addSubview(pickerView!)
        
        pickerView!.doneButtonHandler = { [weak self] in
            if let strongSelf = self {
                strongSelf.dismissPickerView(doneButtonTapp: true)
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
        
        UIView.animate(withDuration: 0.25, animations: {
            self.pickerView!.frame = CGRect(x: self.pickerView!.frame.origin.x, y: self.view.frame.height - 260, width: self.pickerView!.frame.width, height: self.pickerView!.frame.height)
        }) 
    }
    
    @objc func dismissPickerView(doneButtonTapp done: Bool = false) {
        UIView.animate(withDuration: 0.25, animations: {
            self.pickerView!.frame = CGRect(x: self.pickerView!.frame.origin.x, y: self.view.frame.height, width: self.pickerView!.frame.width, height: self.pickerView!.frame.height)
            
            }, completion: { finished in
            
            guard finished else { return }
            
            self.backgroundView!.removeFromSuperview()
            
            if done {
                let index = self.pickerView!.picker.selectedRow(inComponent: 0)
                
                func changeRole() {
                    self.currentIndex = index
                    self.topView.tfContact.text = ""
                    self.resetAllSelected()
                    self.topView.removeAllSelectedUsers()
                    self.updateOkButtonState()
                    
                    self.currentMerchantId = (self.pickerDataSource[index] as? Merchant)?.merchantId
                    
                    let role = self.pickerView!.dataSource[index]
                    self.topView.roleLabel.text = role
                    
                    self.topView.layoutSubviews()
                    self.loadData()
                }
                
                if self.currentIndex != index {
                    
                    if !self.topView.dataSource.isEmpty {
                        Alert.alert(self, title: "", message: String.localize("LB_CA_IM_SENDER_CHANGE"), okTitle: String.localize("LB_OK"), okActionComplete: {
                            
                            changeRole()
                            
                            }, cancelActionComplete: nil)
                    }
                    else {
                        changeRole()
                    }
                }
                
            }
        })
        
    }
    
    // MARK: - Actions
    @objc func okButtonTapped() {
        Log.debug("okButtonTapped")
        
        if Reachability.shared().currentReachabilityStatus() == NotReachable {
            Alert.alertWithSingleButton(self, title: "", message: String.localize("MSG_ERR_NETWORK_FAIL"), buttonString: String.localize("LB_CA_CONFIRM"))
            return
        }
        
        var userList = [UserRole]()
        
        var message: IMSystemMessage!
        var convType: ConvType!
        
        if currentMerchantId == nil {
            if let conv = self.conv, !conv.shouldStartNewConv() {
                for friend in topView.dataSource {
                    if friend.canDelete {
                        let friendRole: UserRole = UserRole(userKey: friend.userKey)
                        userList.append(friendRole)
                    }
                }
                
                message = IMConvAddMessage(convKey: conv.convKey, userList: userList, myUserRole: conv.myUserRole)
            }
            else {
                let myRole: UserRole = UserRole(userKey: Context.getUserKey())
                userList.append(myRole)

                for friend in topView.dataSource {
                    let friendRole: UserRole = UserRole(userKey: friend.userKey)
                    userList.append(friendRole)
                }

                for existingUserRole in existingUsers {
                    var hasFound = false
                    for userRole in userList {
                        if userRole.userKey == existingUserRole.userKey {
                            hasFound = true
                            break
                        }
                    }
                    
                    if !hasFound {
                        userList.append(existingUserRole)
                    }
                }

                message = IMConvStartMessage(userList: userList, senderMerchantId: myRole.merchantId)
            }

            convType = .Private
        }
        else {
            if let conv = self.conv, !conv.shouldStartNewConv() {
                for friend in topView.dataSource {
                    if friend.canDelete {
                        let friendRole: UserRole = UserRole(userKey: friend.userKey, merchantId: friend.merchantId)
                        userList.append(friendRole)
                    }
                }

                message = IMConvAddMessage(convKey: conv.convKey, userList: userList, myUserRole: conv.myUserRole)
            }
            else {
                let myRole: UserRole = UserRole(userKey: Context.getUserKey(), merchantId: currentMerchantId)
                userList.append(myRole)
                
                for friend in topView.dataSource {
                    let friendRole: UserRole = UserRole(userKey: friend.userKey, merchantId: friend.merchantId)
                    userList.append(friendRole)
                }

                message = IMConvStartIntenalChatMessage(userList: userList,
                                                        senderMerchantId: currentMerchantId,
                                                        merchantId: currentMerchantId)
            }

            convType = .Internal
        }
        
        showLoading()
        WebSocketManager.sharedInstance().sendMessage(
            message,
            completion: { [weak self] (ack) in
                if let strongSelf = self {
                    
                    if strongSelf.conv != nil {
                        if !strongSelf.conv!.shouldStartNewConv() {
                            if let conv = WebSocketManager.sharedInstance().conversationForKey(strongSelf.conv!.convKey) {
                                conv.addUserRole(userList)
                            }
                        }
                    }

                    strongSelf.dismiss(animated: false, completion: {
                        strongSelf.didCreateNewChat?(ack, convType)
                    })
                    strongSelf.stopLoading()
                }
            },
            failure: { [weak self] in
                if let strongSelf = self {
                    strongSelf.stopLoading()
                }
            }
        )
    }
    
    func cancelButtonTapped() {
        Log.debug("cancelButtonTapped")
        
        self.dismiss(animated: true, completion: nil)
    }
    
    func updateOkButtonState() {
        let numberOfSelectedFriend = topView.dataSource.filter { $0.canDelete }.count
        var title: String = ""
        if numberOfSelectedFriend == 0 {
            title = String.localize("LB_IM_CHAT_WITH_NEW_COUNT").replacingOccurrences(of: " ({0})", with: "")
        }
        else {
            title = String.localize("LB_IM_CHAT_WITH_NEW_COUNT").replacingOccurrences(of: "{0}", with: "\(numberOfSelectedFriend)")
        }
        self.createRightButton(title, action: #selector(okButtonTapped))
        if let okButton = self.navigationItem.rightBarButtonItem?.customView as? UIButton{
            okButton.isEnabled = numberOfSelectedFriend > 0 ? true:false
        }
    }
    
    func addUser(_ user: User) {
        self.topView.addUser(user)
        updateOkButtonState()
    }
    
    func removeUser(_ user: User) {
        topView.removeUser(user)
        updateOkButtonState()
    }
    
    func resetAllSelected() {
        if currentMerchantId == nil {
            for object in dataSource {
                let user = object as! User
                user.isSelected = false
            }
        }
        else {
            for object in dataSource {
                let merchant = object as! Merchant
                if let users = merchant.users, !users.isEmpty {
                    for user in users {
                        user.isSelected = false
                    }
                }
            }
        }
    }
    
    @objc func findFriendTapped() {
        Log.debug("findFriend")
        dismiss(animated: true) { [weak self] in
            if let strongSelft = self {
                strongSelft.findFriend?()
            }
        }
    }
    
    //MARK: Services
    func loadFriend() {
        firstly {
            return listFriends()
            }.then { friends -> Void in
                self.dismissNoConnectionView()

                if friends.count > 0 {
                    self.hideNoContactView()

                    self.friends = friends
                    self.friends.sortByDisplayName()
                    
                } else {
                    self.showNoContactView(true)
                }
                
                for user in self.friends {
                    
                    for userRole in self.existingUsers {
                        if userRole.userKey == user.userKey {
                            user.isSelected = true
                            user.canDelete = false
                            self.addUser(user)
                            break
                        }
                    }
                    
                }
                
                self.dataSource = self.friends

                self.collectionView.reloadData()
            }.catch { _ in
                Log.error("error")
                self.showNoConnectionView()
                self.noConnectionView!.reloadHandler = { [weak self] in
                    if let strongSelf = self {
                        strongSelf.loadData()
                    }
                }
        }
    }
    
    func listAgent(_ merchantId : Int = -1) -> Promise<[Merchant]> {
        if merchantId == Constants.MMMerchantId {
            return listMMAgent()
        }
        return listMerchant(merchantId)
    }
    
    func listMerchant(_ merchantId: Int = -1) -> Promise<[Merchant]> {
        return Promise { fulfill, reject in
            firstly {
                return listMerchantAgent(merchantId)
                }.then { users -> Void in
                    if let merchants = Context.customerServiceMerchants().merchants {
                        for merchant in merchants {
                            if merchant.merchantId == merchantId {
                                merchant.users = users
                                fulfill([merchant])
                                break
                            }
                        }
                    }
                }.catch { error -> Void in
                    reject(error)
            }
        }
    }
    
    func loadListAgentWithMerchantId(_ merchantId: Int) {
        
        firstly{
            return listAgent(merchantId)
            }.then { agents -> Void in
                self.dismissNoConnectionView()

                if agents.count == 0 {
                    self.showNoContactView(false)
                }
                else {
                    self.hideNoContactView()
                }
                
                var list = [Merchant]()
                for agent in agents {
                    
                    if let users = agent.users, agent.merchantId == self.currentMerchantId {
                    
                        var userList = [User]()
                        for user in users {
                            
                            for userRole in self.existingUsers {
                                if userRole.userKey == user.userKey {
                                    user.isSelected = true
                                    user.canDelete = false
                                    self.addUser(user)
                                    break
                                }
                            }
                            
                            if user.userKey != Context.getUserKey() {
                                userList.append(user)
                            }
                            
                            user.merchantId = agent.merchantId
                        }
                        
                        agent.users = userList
                        if agent.users != nil {
                            agent.users!.sortByDisplayName()
                        }
                        
                        if !userList.isEmpty {
                            list.append(agent)
                        }
                        
                    }
                }
                
                self.merchants = list
                
                self.dataSource = self.merchants

                self.collectionView.reloadData()
            }.catch { _ in
                Log.error("error")
                self.showNoConnectionView()
                self.noConnectionView!.reloadHandler = { [weak self] in
                    if let strongSelf = self {
                        strongSelf.loadData()
                    }
                }
        }
        
    }
    
    //MARK: - CollectionView
    func numberOfSections(in collectionView: UICollectionView) -> Int {
        if currentMerchantId == nil {
            return 1
        }
        
        return dataSource.count
    }
    
    override func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        if currentMerchantId == nil {
            return dataSource.count
        }
        
        if let merchant = dataSource[section] as? Merchant, let user = merchant.users {
            return user.count
        }

        return 0
    }
    
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, referenceSizeForHeaderInSection section: Int) -> CGSize {
        if currentMerchantId == nil {
            return CGSize(width: self.view.bounds.width, height: 0)
        }
        
        return CGSize(width: self.view.bounds.width, height: 30)
    }

    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, sizeForItemAt indexPath: IndexPath) -> CGSize {
        return CGSize(width: view.frame.width, height: 60)
    }
    
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, minimumLineSpacingForSectionAt section: Int) -> CGFloat {
        return 0
    }
    
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, minimumInteritemSpacingForSectionAt section: Int) -> CGFloat {
        return 0
    }

    func collectionView(_ collectionView: UICollectionView, viewForSupplementaryElementOfKind kind: String, at indexPath: IndexPath) -> UICollectionReusableView {
        
        let view = collectionView.dequeueReusableSupplementaryView(ofKind: kind, withReuseIdentifier: ContactHeaderCellID, for: indexPath) as! ContactHeaderView
        
        if !dataSource.isEmpty {
            if let merchant = dataSource[indexPath.section] as? Merchant {
                view.merchantName.text = merchant.merchantName
            }
        }

        return view
    }

    override func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        
        let cell = collectionView.dequeueReusableCell(withReuseIdentifier: ContactCellID, for: indexPath) as! InitChatContactCell

        if currentMerchantId == nil {
            let user = dataSource[indexPath.row] as! User
            
            let defaultProfile = UIImage(named: "default_profile_icon")
            if (user.profileImage.length > 0) {
                cell.profileImageView.mm_setImageWithURL(ImageURLFactory.URLSize(.size128, key: user.profileImage, category: .user), placeholderImage: defaultProfile, contentMode: .scaleAspectFill)
            } else {
                cell.profileImageView.image = defaultProfile
            }
            cell.nameLabel.text = user.displayName
            cell.tagLabel.isHidden = true
            
            if user.canDelete {
                cell.setRedCheckBox()
            }
            else {
                cell.setGrayCheckBox()
            }
            
            cell.buttonTick.isSelected = user.isSelected

            cell.buttonTickHandler = { [weak self] in

                guard let strongSelf = self else { return }
                guard user.canDelete else { return }

                if strongSelf.numberOfSelectedUser() >= strongSelf.Limit && !user.isSelected {
                    Alert.alertWithSingleButton(strongSelf, title: "", message: String.localize("MSG_ERR_CS_CHAT_GROUP_MAX"), buttonString: String.localize("LB_OK"))
                    return
                }

                cell.buttonTick.isSelected = !cell.buttonTick.isSelected

                user.isSelected = !user.isSelected
                if user.isSelected {
                    strongSelf.addUser(user)
                }
                else {
                    strongSelf.removeUser(user)
                }
                
                strongSelf.topView.tfContact.text = ""
                strongSelf.filter("")
            }
            
            cell.layoutSubviews()
        }
        else {
            
            let merchant = dataSource[indexPath.section] as! Merchant
            if let users = merchant.users, !users.isEmpty {
                let user = users[indexPath.row]
                
                let defaultProfile = UIImage(named: "default_profile_icon")
                if (user.profileImage.length > 0) {
                    cell.profileImageView.mm_setImageWithURL(ImageURLFactory.URLSize(.size128, key: user.profileImage, category: .user), placeholderImage: defaultProfile, contentMode: .scaleAspectFill)
                } else {
                    cell.profileImageView.image = defaultProfile
                }
                cell.nameLabel.text = user.displayName
                cell.tagLabel.text = merchant.merchantName
                cell.tagLabel.isHidden = false

                if user.canDelete {
                    cell.setRedCheckBox()
                }
                else {
                    cell.setGrayCheckBox()
                }

                cell.buttonTick.isSelected = user.isSelected
                
                cell.buttonTickHandler = { [weak self] in
                    guard let strongSelf = self else { return }
                    guard user.canDelete else { return }

                    if strongSelf.numberOfSelectedUser() >= strongSelf.Limit && !user.isSelected {
                        Alert.alertWithSingleButton(strongSelf, title: "", message: String.localize("MSG_ERR_CS_CHAT_GROUP_MAX"), buttonString: String.localize("LB_OK"))
                        return
                    }

                    cell.buttonTick.isSelected = !cell.buttonTick.isSelected

                    user.isSelected = !user.isSelected
                    if user.isSelected {
                        strongSelf.addUser(user)
                    }
                    else {
                        strongSelf.removeUser(user)
                    }
                    
                    strongSelf.topView.tfContact.text = ""
                    strongSelf.filter("")
                }

                cell.layoutSubviews()
            }
        }
        
        return cell
        
    }
    
    func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        if currentMerchantId == nil {
            let user = dataSource[indexPath.row] as! User
            
            guard user.canDelete else { return }
            
            if numberOfSelectedUser() >= Limit && !user.isSelected {
                Alert.alertWithSingleButton(self, title: "", message: String.localize("MSG_ERR_CS_CHAT_GROUP_MAX"), buttonString: String.localize("LB_OK"))
                return
            }
            
            user.isSelected = !user.isSelected
            
            let cell = collectionView.cellForItem(at: indexPath) as! InitChatContactCell
            cell.buttonTick.isSelected = user.isSelected
            
            if user.isSelected {
                addUser(user)
            }
            else {
                removeUser(user)
            }
            
            topView.tfContact.text = ""
            filter("")
        }
        else {
            let merchant = dataSource[indexPath.section] as! Merchant
            if let users = merchant.users, !users.isEmpty {
                let user = users[indexPath.row]
                
                guard user.canDelete else { return }
                
                if numberOfSelectedUser() >= Limit && !user.isSelected {
                    Alert.alertWithSingleButton(self, title: "", message: String.localize("MSG_ERR_CS_CHAT_GROUP_MAX"), buttonString: String.localize("LB_OK"))
                    return
                }

                user.isSelected = !user.isSelected
                
                let cell = collectionView.cellForItem(at: indexPath) as! InitChatContactCell
                cell.buttonTick.isSelected = user.isSelected
                
                if user.isSelected {
                    addUser(user)
                }
                else {
                    removeUser(user)
                }
                
                topView.tfContact.text = ""
                filter("")
            }
        }
    }
    
    func numberOfSelectedUser() -> Int {
        if dataSource[0] is User {
            return dataSource.filter{ ($0 as! User).isSelected }.count
        }

        var count = 0
        for merchant in dataSource {
            if let users = (merchant as! Merchant).users, !users.isEmpty {
                count += users.filter{ $0.isSelected }.count
            }
        }
        
        return count
    }
    
    // MARK: - Keyboard
    func keyboardWillShowNotification(_ notification: Notification) {
        if let info = notification.userInfo, let kbObj = info[UIKeyboardFrameEndUserInfoKey] {
            var kbRect = (kbObj as! NSValue).cgRectValue
            kbRect = self.view.convert(kbRect, from: nil)
            let contentInsets = UIEdgeInsets(top: 0.0, left: 0.0, bottom: kbRect.size.height, right: 0.0)
            
            collectionView.contentInset = contentInsets
            collectionView.scrollIndicatorInsets = contentInsets;
            
            labelSearchResult.center = CGPoint(x: collectionView.center.x, y: (collectionView.height - contentInsets.bottom) / 2.0)
        }
    }
    
    func keyboardWillHideNotification(_ notification: Notification) {
        collectionView.contentInset = UIEdgeInsets.zero
        collectionView.scrollIndicatorInsets = UIEdgeInsets.zero
        
        labelSearchResult.center = CGPoint(x: collectionView.center.x, y: collectionView.height / 2.0)
    }

    //MARK: - Config view
    override func collectionViewTopPadding() -> CGFloat {
        if !isAgent || conv != nil {
            return IsIphoneX ? 104 : 80
        }

        return IsIphoneX ? 164 : 140
    }
}
