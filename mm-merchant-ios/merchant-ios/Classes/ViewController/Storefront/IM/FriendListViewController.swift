//
//  FriendListViewController.swift
//  merchant-ios
//
//  Created by HVN_Pivotal on 3/4/16.
//  Copyright © 2016 WWE & CO. All rights reserved.
//

import Foundation
import PromiseKit
import ObjectMapper


enum FriendListMode: Int {
    case normalMode
    case shareMode
    case attachFriend
    case tagMode
}
class FriendListViewController : MmViewController, FriendListViewCellDelegate{
    
    enum FriendCategory: Int{
        case All = 0,
        FriendRequest,
        Unknown
    }
    
    private final let CellHeight : CGFloat = 60
    private final let CatCellHeight : CGFloat = 40
    private final let FriendStatusAccepted : String = String.localize("LB_CA_IM_ACCEPTED")
    private final let FriendStatusDeleted : String = String.localize("LB_CA_IM_DELETED")
    private let SearchBarHeight : CGFloat = 40
    private var dataSource: [User] = []
    private var friends: [User] = []
    private var friendRequests: [User] = []
    private var isShowingFriendList : Bool = true
    private var catCollectionView : UICollectionView!
    var searchBar = UISearchBar()
    var chatModel : ChatModel?
    var isFromUserChat = false

    var friendListMode: FriendListMode = .normalMode
    
    var didShareToUserHandler: ((User) -> ())?
    var cellId = "CellID"
    
    var didPopHandler: ((User, ChatModel) -> ())?
    
    override func viewDidLoad() {
        super.viewDidLoad()
        self.title = String.localize("LB_CA_FRIEND_LIST")
        self.view.backgroundColor = UIColor.white
        self.collectionView!.register(FriendListViewCell.self, forCellWithReuseIdentifier: "FriendListViewCell")
        self.collectionView.register(UICollectionViewCell.self, forCellWithReuseIdentifier: cellId)
        self.createBackButton()
        self.createTopView()
        self.updateContentView()
        
        if friendListMode == .normalMode {
            self.createRightBarButton()
        }
    }
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        
        refreshDataSource()
        self.getDataSource()
    }
    override func createBackButton() {
        if friendListMode == .normalMode || friendListMode == .attachFriend {
            super.createBackButton()
        } else {
            createBackButton(.cross)
        }
    }
    
    override func backButtonClicked(_ button: UIButton) {
        if friendListMode == .normalMode || friendListMode == .attachFriend {
            super.backButtonClicked(button)
        } else {
            self.dismiss(animated: true, completion: nil)
        }
    }
    
    //MARK: Collection View methods and delegates
    override func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        switch (collectionView) {
        case self.collectionView:
            return self.dataSource.count
        default:
            return 2
        }
    }
    
    
    func createRightBarButton() {
        let rightButton = UIButton(type: UIButtonType.custom)
        rightButton.setTitle("", for: .normal)
        rightButton.setImage(UIImage(named: "addFriend_icon"), for: UIControlState.normal)
        rightButton.frame = CGRect(x: 0, y: 0, width: 40, height: 40)
        rightButton.addTarget(self, action: #selector(FriendListViewController.addFriendClicked), for: UIControlEvents.touchUpInside)
        self.navigationItem.rightBarButtonItem = UIBarButtonItem(customView: rightButton)
        
        self.setAccessibilityIdForView("UIBT_ADD_FRD", view: rightButton)
    }
    
    func getPaddingTop() -> CGFloat {
        if friendListMode == .normalMode || friendListMode == .attachFriend {
            return self.navigationController!.navigationBar.frame.maxY
        } else {
            return self.navigationController!.navigationBar.frame.maxY + App.screenStatusBarHeight
        }
    }
    
    func createTopView() {
        let paddingTop = self.getPaddingTop()
        
        var searchBarFrame : CGRect
        
        if friendListMode == .normalMode {
            
            let layout: SnapFlowLayout = SnapFlowLayout()
            layout.sectionInset = UIEdgeInsets(top: 0, left: 0, bottom: 0, right: 0)
            layout.scrollDirection = UICollectionViewScrollDirection.horizontal
            self.catCollectionView = UICollectionView(frame: CGRect(x: 0, y: paddingTop, width: self.view.bounds.width, height: CatCellHeight), collectionViewLayout: layout)
            self.catCollectionView.delegate = self
            self.catCollectionView.dataSource = self
            self.catCollectionView.backgroundColor = UIColor.white
            self.catCollectionView.register(SubCatCell.self, forCellWithReuseIdentifier: "SubCatCell")
            self.view.addSubview(self.catCollectionView)
            
            searchBarFrame = CGRect(x: self.view.bounds.minX, y: paddingTop + CatCellHeight, width: self.view.bounds.width, height: SearchBarHeight)
            
        } else {
            searchBarFrame = CGRect(x: self.view.bounds.minX, y: paddingTop, width: self.view.bounds.width, height: SearchBarHeight)
        }
        
        self.searchBar.sizeToFit()
        self.searchBar.delegate = self
        self.searchBar.searchBarStyle = UISearchBarStyle.default
        self.searchBar.showsCancelButton = false
        self.searchBar.frame = searchBarFrame
        self.searchBar.placeholder = String.localize("LB_CA_SEARCH")
        self.view.addSubview(self.searchBar)
    }
    
    func updateContentView() {
        if friendListMode == .attachFriend {
            self.collectionView.frame = CGRect(x: self.view.bounds.minX, y: self.collectionView.frame.originY - App.screenStatusBarHeight, width: self.view.bounds.width, height: self.view.bounds.height - (self.navigationController?.navigationBar.frame.height)!)
        }
    }
    
    func numberOfSections(in collectionView: UICollectionView) -> Int {
        return 1
    }
    
    override func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        switch (collectionView) {
        case self.collectionView:
            let cell = collectionView.dequeueReusableCell(withReuseIdentifier: "FriendListViewCell", for: indexPath) as! FriendListViewCell
            
            let user = self.dataSource[indexPath.row]
            cell.upperLabel.text = dataSource[indexPath.row].displayName
            cell.setImage(self.dataSource[indexPath.row].profileImage, category: .user)
            cell.chatButton.tag = indexPath.row
            cell.acceptButton.tag = indexPath.row
            cell.deleteButton.tag = indexPath.row
            cell.friendListViewCellDelegate = self
            cell.setData(user, isFriend: isShowingFriendList)
            
            if friendListMode == .shareMode || friendListMode == .attachFriend {
                cell.chatView.isHidden = true
            }
            
            return cell
            
        default :
            let cell = collectionView.dequeueReusableCell(withReuseIdentifier: "SubCatCell", for: indexPath) as! SubCatCell
            
            if let friendCategory = FriendCategory(rawValue: indexPath.row){
                switch friendCategory {
                case .All:
                    cell.label.text = String.localize("LB_CA_IM_FRD")
                    cell.label.font = UIFont.boldSystemFont(ofSize: 14.0)
                    if isShowingFriendList {
                        cell.imageView.isHidden = false
                        cell.label.textColor = UIColor.primary1()
                        cell.imageView.image = UIImage(named: "underLineBrand")
                    } else {
                        cell.imageView.isHidden = true
                        cell.label.textColor = UIColor.secondary3()
                    }
                    break
                case .FriendRequest:
                    var string = String.localize("LB_CA_FRIENDS_REQUEST")
                    if self.friendRequests.count > 0 {
                        string = string + "(\(self.friendRequests.count))"
                    }
                    cell.label.text = string
                    cell.label.font = UIFont.boldSystemFont(ofSize: 14.0)
                    if isShowingFriendList {
                        cell.imageView.isHidden = true
                        cell.label.textColor = UIColor.secondary3()
                    } else {
                        cell.imageView.isHidden = false
                        cell.label.textColor = UIColor.primary1()
                        cell.imageView.image = UIImage(named: "underLineBrand")
                    }
                    break
                default:
                    break
                }
            }
            
            return cell
        }
        
    }
    
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, sizeForItemAt indexPath: IndexPath) -> CGSize {
        switch (collectionView) {
        case self.collectionView:
            return CGSize(width: self.view.frame.size.width , height: CellHeight)
        default:
            return CGSize(width: self.view.frame.size.width / 4, height: Constants.Value.CatCellHeight)
        }
        
    }
    
    func collectionView(_ collectionView: UICollectionView,
                        layout collectionViewLayout: UICollectionViewLayout,
                               insetForSectionAt section: Int) -> UIEdgeInsets {
        switch (collectionView) {
        case self.collectionView:
            
            if friendListMode == .normalMode {
                return UIEdgeInsets(top: CatCellHeight + SearchBarHeight, left: 0.0, bottom: 0.0, right: 0.0)
            } else {
                return UIEdgeInsets(top: SearchBarHeight , left: 0.0, bottom: 0.0, right: 0.0)
            }
            
        default:
            let space = (self.view.frame.width / 2 - Constants.LineSpacing.SubCatCell) / 2
            return  UIEdgeInsets(top: 0.0, left: space, bottom: 0.0, right: space)
        }
    }
    
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, minimumInteritemSpacingForSectionAt section: Int) -> CGFloat {
        return 0.0
    }
    
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, minimumLineSpacingForSectionAt section: Int) -> CGFloat {
        switch collectionView {
        case self.collectionView!:
            return 0.0
        default:
            return Constants.LineSpacing.SubCatCell
        }
    }
    
    func collectionView(_ collectionView: UICollectionView,
                        didSelectItemAt indexPath: IndexPath) {
        switch collectionView {
        case self.collectionView!:
            switch friendListMode {
            case .normalMode:
                if self.chatModel != nil {
                    
                    Alert.alert(self, title: String.localize("LB_CA_FORWARD"), message:self.friends[indexPath.row].displayName , okActionComplete: { () -> Void in
                        
                        self.navigationController?.popViewController(animated:false)
                        
                        if let callback = self.didPopHandler {
                            callback(self.friends[indexPath.row], self.chatModel!)
                        }
                        
                        }, cancelActionComplete:nil)
                } else {
                    let curator = self.dataSource[indexPath.row]
                    let user = User()
                    user.userKey = curator.userKey
                    user.userName = curator.userName
                    PushManager.sharedInstance.goToProfile(user, hideTabBar: false)
                }
                
                break
            case .shareMode:
                Alert.alert(self, title: String.localize("LB_CA_FORWARD"), message:self.friends[indexPath.row].displayName , okActionComplete: { () -> Void in
                    
                    if let callback = self.didShareToUserHandler {
                        let user =  self.dataSource[indexPath.row]
                        callback(user)
                    }
                    
                    self.dismiss(animated: true, completion: nil)
                    
                    }, cancelActionComplete:nil)
                
                break
            default:
                Alert.alert(self, title: "", message:String.localize("LB_CA_IM_SHARE_FRD_NOTE").replacingOccurrences(of: "{0}", with: self.friends[indexPath.row].displayName), okTitle: String.localize("LB_OK"), okActionComplete: { () -> Void in
                    
                    if let callback = self.didShareToUserHandler {
                        let user =  self.dataSource[indexPath.row]
                        callback(user)
                    }
                    self.navigationController?.popViewController(animated:true)
                    
                    }, cancelActionComplete:nil)
                
                break
            }
            
            break
        default:
            self.friends.removeAll()
            self.friendRequests.removeAll()
            self.searchBar.text=""
            
            if let friendCategory = FriendCategory(rawValue: indexPath.row){
                switch friendCategory {
                case .All:
                    if !isShowingFriendList {
                        isShowingFriendList = true
                        self.reloadDataSource()
                        self.getDataSource()
                    } else {
                        isShowingFriendList = true
                    }
                    
                    break
                case .FriendRequest:
                    if isShowingFriendList {
                        isShowingFriendList = false
                        self.reloadDataSource()
                        self.getDataSource()
                    } else {
                        isShowingFriendList = false
                    }
                    
                    break
                default:
                    break
                }
            }
            break
        }
        
        self.view.endEditing(true)
    }
    
    @objc func addFriendClicked (sender : UIBarButtonItem){
        let addFriendViewController = AddFriendViewController()
        self.navigationController?.pushViewController(addFriendViewController, animated: true)
    }
    
    func reloadDataSource() {
        self.filter(searchBar.text)
        self.collectionView.reloadData()
        
        if friendListMode == .normalMode {
            self.catCollectionView.reloadData()
        }
        
    }
    func refreshDataSource(){
        self.friends.removeAll()
        self.friendRequests.removeAll()
        self.collectionView.reloadData()
    }
    
    func getDataSource() {
        self.loadFriend()
        self.loadFriendRequest()
    }

    // MARK: UISearchBarDelegate
    private func filter(_ keyword : String?) {
        if let text = keyword {
            if isShowingFriendList {
                if text.length == 0 {
                    self.dataSource = self.friends
                } else {
                    self.dataSource = self.friends.filter({ ($0.displayName).lowercased().range(of: text.lowercased()) != nil || ($0.userName).lowercased().range(of: text.lowercased()) != nil})
                }
            } else {
                if text.length == 0 {
                    self.dataSource = self.friendRequests
                } else {
                    self.dataSource = self.friendRequests.filter({ ($0.displayName).lowercased().range(of: text.lowercased()) != nil || ($0.userName).lowercased().range(of: text.lowercased()) != nil})
                }
            }
            self.collectionView.reloadData()
        } else {
            // ignore nil
        }
    }
    
    func searchBarSearchButtonClicked(_ searchBar: UISearchBar) {
        self.filter(searchBar.text)
        searchBar.resignFirstResponder()
    }
    
    func searchBar(_ searchBar: UISearchBar, textDidChange searchText: String) {
        if searchBar.text?.length == 0 {
            if isShowingFriendList {
                if self.friends.count == 0 {
                    self.loadFriend()
                    return
                }
                self.dataSource = self.friends
            } else {
                if self.friendRequests.count == 0 {
                    self.loadFriendRequest()
                    return
                }
                self.dataSource = self.friendRequests
            }
            self.reloadDataSource()
        } else {
            self.filter(searchBar.text)
        }
    }
    
    func searchBarCancelButtonClicked(_ searchBar: UISearchBar) {
        self.view.endEditing(true)
    }
    
    func searchBarShouldBeginEditing(_ searchBar: UISearchBar) -> Bool {
        searchBar.showsCancelButton = true
        styleCancelButton(true)
        return true
    }
    
    func searchBarShouldEndEditing(_ searchBar: UISearchBar) -> Bool {
        searchBar.showsCancelButton = false
        return true
    }
    
    func styleCancelButton(_ enable: Bool){
        if enable {
            if let _cancelButton = searchBar.value(forKey: "_cancelButton"),
                let cancelButton = _cancelButton as? UIButton {
                cancelButton.isEnabled = enable //comment out if you want this button disabled when keyboard is not visible
                if title != nil {
                    cancelButton.setTitle(String.localize("LB_CANCEL"), for: UIControlState.normal)
                }
            }
        }
    }
    func loadFriend() {
        firstly{
            return self.listFriend()
            }.then
            { _ -> Void in
                self.reloadDataSource()
            }.always {
                self.stopLoading()
            }.catch { _ -> Void in
                Log.error("error")
        }
    }
    
    func loadFriendRequest() {
        
        firstly{
            return self.listFriendRequest()
            }.then
            { _ -> Void in
                self.reloadDataSource()
            }.always {
                self.stopLoading()
            }.catch { _ -> Void in
                Log.error("error")
        }
    }
    
    func deleteRequest(_ user: User) {
        firstly{
            return self.deleteFriendRequest(user)
            }.then
            { _ -> Void in
                self.reloadDataSource()
            }.always {
                
            }.catch { _ -> Void in
                Log.error("error")
        }
    }
    
    func acceptRequest(_ user: User) {
        firstly{
            return self.acceptFriendRequest(user)
            }.then
            { _ -> Void in
                CacheManager.sharedManager.addFriend(user)
                self.reloadDataSource()
            }.always {
                
            }.catch { _ -> Void in
                Log.error("error")
        }
    }
    
    //MARK: Promise Call
    func deleteFriendRequest(_ user: User) -> Promise<Any> {
        return Promise{ fulfill, reject in
            FriendService.deleteRequest(user, completion:
                {
                    [weak self] (response) in
                    if let strongSelf = self {
                        if response.result.isSuccess {
                            if response.response?.statusCode == 200 {
                                fulfill("OK")
                                CacheManager.sharedManager.deleteFriend(user)
                            } else {
                                strongSelf.handleApiResponseError(response, reject: reject)
                            }
                        }
                        else{
                            reject(response.result.error!) // forece unwrap here is ok since Alamofire must have error if fail
                            strongSelf.handleApiResponseError(response, reject: reject)
                        }
                    } else {
                        ErrorLogManager.sharedManager.recordNonFatalError(withException: .NullPointer)
                    }
                })
        }
    }
    
    func acceptFriendRequest(_ user: User) -> Promise<Any> {
        return Promise{ fulfill, reject in
            FriendService.acceptRequest(user, completion:
                {
                    [weak self] (response) in
                    if let strongSelf = self {
                        if response.result.isSuccess {
                            if response.response?.statusCode == 200 {
                                fulfill("OK")
                            } else {
                                strongSelf.handleApiResponseError(response, reject: reject)
                            }
                        }
                        else{
                            reject(response.result.error!)
                            strongSelf.handleApiResponseError(response, reject: reject)
                        }
                    } else {
                        ErrorLogManager.sharedManager.recordNonFatalError(withException: .NullPointer)
                    }
                })
        }
    }
    
    func listFriend() -> Promise<Any> {
        return Promise{ fulfill, reject in
            FriendService.listFriends() {
                [weak self] (response) in
                if let strongSelf = self {
                    if response.result.isSuccess {
                        if response.response?.statusCode == 200 {
                            
                            let friend:[User] = Mapper<User>().mapArray(JSONObject: response.result.value) ?? []
                            
                            if friend.count > 0 {
                                strongSelf.friends = friend
                                strongSelf.friends.sortByDisplayName()
                            }
                            
                            fulfill("OK")
                        } else {
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
            }
        }
    }
    
    func listFriendRequest() -> Promise<Any> {
        return Promise{ fulfill, reject in
            FriendService.listRequest() {
                [weak self] (response) in
                if let strongSelf = self {
                    if response.result.isSuccess {
                        if response.response?.statusCode == 200 {
                            let request = Mapper<User>().mapArray(JSONObject: response.result.value) ?? []
                            
                            if request.count > 0 {
                                strongSelf.friendRequests = request
                            }
                            
                            fulfill("OK")
                        } else {
                            strongSelf.handleApiResponseError(response, reject: reject)
                        }
                    }
                    else{
                        reject(response.result.error!)
                        strongSelf.handleApiResponseError(response, reject: reject)
                    }
                } else {
                    ErrorLogManager.sharedManager.recordNonFatalError(withException: .NullPointer)
                }
            }
        }
    }
    
    //MARK: FriendListViewCellDelegate
    func chatClicked(_ rowIndex: Int, sender: UIButton) {
        
        let friend = friends[rowIndex]
        
        let myRole: UserRole = UserRole(userKey: Context.getUserKey())
        let targetRole: UserRole = UserRole(userKey: friend.userKey)
        
        WebSocketManager.sharedInstance().sendMessage(
            IMConvStartMessage(userList: [myRole, targetRole], senderMerchantId: myRole.merchantId),
            checkNetwork: true,
            viewController: self,
            completion: { [weak self] (ack) in
                
                if let strongSelf = self, let convKey = ack.data {
                    let viewController = UserChatViewController(convKey: convKey)
                    strongSelf.navigationController?.pushViewController(viewController, animated: true)
                } else {
                    ErrorLogManager.sharedManager.recordNonFatalError(withException: .NullPointer)
                }
            }
        )
    }
    
    func acceptClicked(_ rowIndex: Int, sender: UIButton) {
        Log.debug("acceptClicked: \(rowIndex)")
        let user = self.dataSource[rowIndex]
        user.friendStatus = FriendStatusAccepted
        self.acceptRequest(user)
    }
    
    func deleteClicked(_ rowIndex: Int, sender: UIButton) {
        Log.debug("deleteClicked: \(rowIndex)")
        let user = self.dataSource[rowIndex]
        user.friendStatus = FriendStatusDeleted
        self.deleteRequest(user)
    }
    
}
