//
//  NewProfileViewController.swift
//  merchant-ios
//
//  Created by Leslie Zhang on 2017/12/11.
//  Copyright © 2017年 WWE & CO. All rights reserved.
//

import UIKit
import PromiseKit
import Alamofire
import ObjectMapper
import Kingfisher
import MJRefresh
import SKPhotoBrowser

class NewProfileViewController: MmViewController {
    
    var user: User?
    var userKey: String?
    var userName: String?
    var relationShip: Relationship?
    private var postManager: PostManager?
    private var finshRequest: Bool = false
    private var canRush:Bool = false
    private let topImageViewHeight:CGFloat = 180
    var followingUsers: NSMutableArray = NSMutableArray()
    var customPullToRefreshView: PullToRefreshUpdateView?
    private let cellSize:CGSize = CGSize(width: (ScreenWidth - 30)/2, height: (ScreenWidth - 30)/2 + 50 )
    var navigationBarVisibility: MmFadeNavigationControllerNavigationBarVisibility = .hidden {
        didSet {
            UIApplication.shared.statusBarStyle = self.navigationBarVisibility == .visible ? .default : .lightContent
        }
    }
    
    //MARK: - Lazy
    lazy var topImageView:UIImageView = {
        let topImageView = UIImageView()
        topImageView.backgroundColor = UIColor.clear
        topImageView.contentMode = UIViewContentMode.scaleAspectFill
        topImageView.clipsToBounds = true
        return topImageView
    }()

    private lazy var headView:ProfileCollectionReusableView = {
        let headView = ProfileCollectionReusableView(frame: CGRect.zero,viewKey: self.analyticsViewRecord.viewKey)
        self.collectionView.addSubview(headView)
        headView.snp.makeConstraints { (make) in
            make.bottom.equalTo(self.collectionView.snp.top)
            make.width.left.right.equalTo(self.collectionView)
        }
        headView.tapFans = { [weak self] in
            if let strongSelf = self{
                strongSelf.gotToFans()
            }
        }
        headView.tapFollow = { [weak self] in
            if let strongSelf = self{
                strongSelf.gotToFollow()
            }
        }
        headView.tapAddFollow = { [weak self] (bool) in
            if let strongSelf = self{
                strongSelf.onHandleAddFollow(bool)
            }
        }
        headView.tapCancelFollow = { [weak self] (bool) in
            if let strongSelf = self{
                strongSelf.onHandleAddFollow(bool)
            }
        }
        headView.tapFriend = { [weak self] (friendStatus) in
            if let strongSelf = self{
                strongSelf.onHandleAddFriend(friendStatus)
            }
        }
        headView.boomView.tapUser = { [weak self] (user) in
            PushManager.sharedInstance.goToProfile(user, hideTabBar: true)
        }
    
        headView.tapAvatar = { [weak self] (user) in
            if let strongSelf = self {
                var images = [SKPhoto]()
                let url = ImageURLFactory.URLSize1000(user.profileImage, category: .user).absoluteString
                images.append(SKPhoto.photoWithImageURL(url))
                let browser = SKPhotoBrowser(photos: images)
                browser.initializePageIndex(0)
                self?.navigationController?.present(browser, animated: true, completion: {})
            }
        }
        
        return headView
    }()
    
    lazy var backButton:UIButton = {
        let container = UIView(frame: CGRect(x:0, y: 0, width: Constants.Value.BackButtonWidth , height: Constants.Value.BackButtonHeight + 20))
        let backButton = UIButton()
        backButton.setImage(UIImage(named: "back_wht"), for: .normal)
        backButton.frame = CGRect(x:0, y: 0, width: container.width, height: container.height)
        let verticalPadding = (container.height - Constants.Value.BackButtonHeight)/2
        backButton.contentEdgeInsets = UIEdgeInsets(top: verticalPadding, left: Constants.Value.BackButtonMarginLeft, bottom: verticalPadding, right: (container.width - Constants.Value.BackButtonWidth))
        backButton.addTarget(self, action: #selector(touchBackButton), for: .touchUpInside)
        backButton.accessibilityIdentifier = "UIBT_BACK"
        return backButton
    }()
    lazy var shareButton:UIButton = {
        let shareButton = UIButton()
        shareButton.frame = CGRect(x:0, y: 0, width: 33, height: 33)
        shareButton.addTarget(self, action: #selector(touchShareButton), for: .touchUpInside)
        shareButton.initAnalytics(withViewKey: self.analyticsViewRecord.viewKey)
        shareButton.contentEdgeInsets = UIEdgeInsets(top: 0, left: 0, bottom: 0, right: CGFloat(-10))
        shareButton.setImage(UIImage.init(named: "share_white"), for: .normal)
        shareButton.clipsToBounds = false
        return shareButton
    }()
    lazy var refreshView:UIActivityIndicatorView = {
        let refreshView = UIActivityIndicatorView(activityIndicatorStyle: UIActivityIndicatorViewStyle.gray)
        refreshView.frame = CGRect(x:(ScreenWidth - refreshView.width)/2, y: 0, width: refreshView.width, height: refreshView.height)
        return refreshView
    }()

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        self.title = ""
        
        if let navigationController = self.navigationController as? MmNavigationController {
            if self.navigationBarVisibility == .visible {
                self.title = user?.displayName
            }
            navigationController.setNavigationBarVisibility(offset: self.collectionView.contentOffset.y + self.collectionView.contentInset.top)
        }
        
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        if let userKey = self.ssn_Arguments["userKey"]?.string {
            self.userKey = userKey
        } else if let userName = self.ssn_Arguments["userName"]?.string {
            let pattern = "[0-9a-zA-Z]{8}-[0-9a-zA-Z]{4}-[0-9a-zA-Z]{4}-[0-9a-zA-Z]{4}-[0-9a-zA-Z]{12}"
            let range = NSRange(location: 0, length: userName.length)
            if let regex = try? NSRegularExpression(pattern: pattern, options: NSRegularExpression.Options.caseInsensitive) {
                let rg = regex.rangeOfFirstMatch(in: userName, options: [], range: range)
                if rg == range {
                    self.userKey = userName
                } else {
                    self.userName = userName
                }
            } else {
                self.userName = userName
            }
        }
        
        self.configImageViewer()
        
        self.automaticallyAdjustsScrollViewInsets = false
        collectionView.frame = CGRect(x: 0 , y: 0, width: self.view.bounds.width, height: self.view.bounds.height - tabBarHeight)
        collectionView.backgroundColor = UIColor.white
        
        collectionView.register(SimpleFeedCollectionViewCell.self, forCellWithReuseIdentifier: SimpleFeedCollectionViewCell.CellIdentifier)
        let footer = MJRefreshAutoFooter(refreshingTarget: self, refreshingAction: #selector(loadMore))
        collectionView.mj_footer = footer
        
        createBarButtons()
        
        self.collectionView.addSubview(self.topImageView)
        collectionView.addSubview(refreshView)
        
        getFollowingUsers(0, pageSize: Constants.Paging.Offset,rush: false)
    }

    //MARK: - Setup UI
    func setCollectionView()  {
        let headViewHeight = headView.systemLayoutSizeFitting(UILayoutFittingCompressedSize).height
        collectionView.contentInset = UIEdgeInsets(top: topImageViewHeight + headViewHeight, left: 0, bottom: 0, right: 0)
        topImageView.frame = CGRect(x:0, y: -topImageViewHeight - headViewHeight - ScreenTop - 64, width: ScreenWidth, height: topImageViewHeight + 64 + ScreenTop)
    }
    func createBarButtons() {
        let container = UIView(frame: CGRect(x:0, y: 0, width: Constants.Value.BackButtonWidth , height: Constants.Value.BackButtonHeight + 20))
        container.addSubview(backButton)
        let backButtonItem = UIBarButtonItem(customView: container)
        self.navigationItem.leftBarButtonItem = backButtonItem
        
        var rightButtonItems = [UIBarButtonItem]()
        rightButtonItems.append(UIBarButtonItem(customView: shareButton))
        self.navigationItem.rightBarButtonItems = rightButtonItems
    }
    
    func setBarWhiteButtons()  {
        backButton.setImage(UIImage(named: "back_wht"), for: .normal)
        shareButton.setImage(UIImage.init(named: "share_white"), for: .normal)
    }
    
    func setBarGrayButtons()  {
        backButton.setImage(UIImage(named: "back_grey"), for: .normal)
        shareButton.setImage(UIImage.init(named: "share_black"), for: .normal)
    }
    
    //MARK: - Touch events
    @objc func touchShareButton()  {
        shareButton.initAnalytics(withViewKey: analyticsViewRecord.viewKey)
        shareButton.recordAction(.Tap, sourceRef: "Share", sourceType: .Button, targetRef: "Share", targetType: .View)
        if let user = self.user {
            PushManager.sharedInstance.goToShareWithUser(self.analyticsViewRecord.viewKey, viewController: self, user: user) { [weak self] (data) in
                if let strongSelf = self {
                   strongSelf.navigationController?.pushViewController(data, animated: true)
                }
            }
        }
    }
    @objc func touchBackButton(){
        self.navigationController?.popViewController(animated:true)
    }
    
    func gotToFans(){
        if let user = self.user {
            let myFollowersViewController = MyFollowersViewController()
            myFollowersViewController.currentProfileType = .Public
            myFollowersViewController.thisUser = user
            self.navigationController?.pushViewController(myFollowersViewController, animated: true)
        }
    }
    func gotToFollow(){
        if let user = self.user {
            let followVC = FollowViewController()
            followVC.user = user
            followVC.modelist = ModeList.usersList
            followVC.selectedIndex = ModeList.usersList.rawValue
            followVC.currentProfileType = .Public
            self.navigationController?.pushViewController(followVC, animated: true)
        }
    }

    override func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        if let post = postManager {
            return post.currentPosts.count
        }
        return 0
    }
    
    override func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        
        guard let postManager = self.postManager else {
            return UICollectionViewCell()
        }
        
        let cell = postManager.getSimpleNewsFeedCell(indexPath)
        if let cell = cell as? SimpleFeedCollectionViewCell {
            
            cell.isUserInteractionEnabled = true
            cell.recordImpressionAtIndexPath(indexPath, positionLocation: "UPP", viewKey: self.analyticsViewRecord.viewKey)
        }
        return cell
    }
    
    deinit {
        print("deinit")
  
    }
    
}

//MARK: - Request
extension NewProfileViewController{
    func fistLoadMore(){
        if let postManager = self.postManager {
            updateNewsFeed(postManager, pageNo: 1)
        }
    }
    
    @objc func loadMore(){
        if let postManager = self.postManager, postManager.hasLoadMore {
            updateNewsFeed(postManager, pageNo: postManager.currentPageNumber + 1)
            collectionView.mj_footer.state = MJRefreshState.idle
        }
    }
    
    func getFollowingUsers(_ pageIndex: Int, pageSize: Int,rush:Bool) {
        //        self.showLoading()
        firstly{
            
            return self.fetchPublicUser()
            }.then {_ in
                
                 return FollowService.listFollowingUsers(.getNonCuratorUser, byUser: self.userKey ?? "", start: pageIndex, limit: pageSize)
            }.then { users -> Promise<Any> in
                
                self.followingUsers = NSMutableArray()
                for user in users {
                    if (self.followingUsers.count < 8){
                        self.followingUsers.add(user)
                    }
                }
               return self.relationshipByUser(self.user!,friendRequest:false)
            }.then { _ -> Void in
                self.headView.user = self.user
                self.headView.isFollowUser = self.user!.isFollowUser
                self.headView.relationship = self.relationShip
                
                if !rush{
                    UIImage.image(fromURL: ImageURLFactory.URLSize512(self.user!.coverImage, category: .user).absoluteString, placeholder: UIImage(named: "default_cover")!, shouldCacheImage: true) {
                        (image: UIImage?) in
                        if image == nil {
                            return
                        }
                        self.topImageView.image = image!.apply(gradientColors: [UIColor(red: 0, green: 0, blue: 0, alpha: 0), UIColor(red: 0, green: 0, blue: 0, alpha: 0.07), UIColor(red: 0, green: 0, blue: 0, alpha: 0.15)]).crop(bounds: CGRect(x: 0.0, y: 0.0, width: image!.size.width, height: 260))
                    }
                    
                }

                self.refreshView.stopAnimating()
                
                
            }.always {
                self.headView.followingUsers = self.followingUsers
                if !rush{
                    self.setCollectionView()
                }
                self.finshRequest = true
                if let postManager = self.postManager {
                    self.updateNewsFeed(postManager, pageNo: 1)
                }
            }.catch { _ -> Void in
                Log.error("error")
        }
    }
    
    func fetchPublicUser() -> Promise<Any> {
        return Promise{ fulfill, reject in
            
            if let user = self.user {
                self.postManager = PostManager(postFeedTyle: .userFeed, authorKey: user.userKey, collectionView: self.collectionView, viewController: self)
                fulfill("OK")
                return
            }
            
            let success:(_ value: User) -> Void = { [weak self]  (user) in
                if let strongSelf = self {
                    strongSelf.user = user
                    if user.userKey.length > 0 {
                        strongSelf.userKey = user.userKey
                        strongSelf.postManager = PostManager(postFeedTyle: .userFeed, authorKey: user.userKey, collectionView: strongSelf.collectionView, viewController: strongSelf)
                        strongSelf.analyticsViewRecord.viewRef = user.userKey
                    }
                    if user.userName.length > 0 {
                        strongSelf.userName = user.userName
                        strongSelf.analyticsViewRecord.viewDisplayName = user.userName
                    }
                    strongSelf.analyticsViewRecord.viewType = "User"
                    strongSelf.analyticsViewRecord.viewLocation = "UPP"
                    
                    fulfill("OK")
                } else {
                    let error = NSError(domain: "", code: -100, userInfo: nil)
                    reject(error)
                }
            }
            
            let failure:(_ error: Error) -> Bool = { (error) in
                reject(error)
                return false
            }
            
            if let userName = self.userName {
                UserService.viewWithUserName(userName, success: success, failure: failure)
            } else if let userKey = self.userKey {
                UserService.viewWithUserKey(userKey, success: success, failure: failure)
            }
        }
    }
    
    func relationshipByUser(_ user: User,friendRequest:Bool) -> Promise<Any>  {
        return Promise{ fulfill, reject in
            
            RelationshipService.relationshipByUser(user.userKey, timestamp: Double(Date().timeIntervalSince1970)) { [weak self] (response) in
                if let strongSelf = self {
                    if response.response?.statusCode == 200 {
                        
                        strongSelf.relationShip = Mapper<Relationship>().map(JSONObject: response.result.value)!
                        strongSelf.user!.isFollowUser = strongSelf.relationShip!.isFollowing
                        if friendRequest {
                            strongSelf.headView.relationship = strongSelf.relationShip
                        }
                        
                        fulfill("OK")
                        //                    strongSelf.reloadData()
                    } else {
                        //                    strongSelf.handleError(response, animated: true)
                    }
                }
            }
        }
    }
    

    func checkStatusUser(_ user: User,friendRequest:Bool) {
        RelationshipService.relationshipByUser(user.userKey, timestamp: Double(Date().timeIntervalSince1970)) { [weak self] (response) in
            if let strongSelf = self {
                if response.response?.statusCode == 200 {
                    
                    strongSelf.relationShip = Mapper<Relationship>().map(JSONObject: response.result.value)!
                    
                    strongSelf.user!.isFollowUser = strongSelf.relationShip!.isFollowing
                    if friendRequest {
                        strongSelf.headView.relationship = strongSelf.relationShip
                    }
                }
            }
        }
    }
    
    func updateNewsFeed(_ postManager: PostManager, pageNo: Int){
        firstly {
            // update inventory location if needed
            // if it is not updated, it will return success without api call
            return postManager.fetchNewsFeed(.userFeed, userKey: self.userKey ?? "", pageno: pageNo)
            }.then { postIds -> Promise<Any> in
                return postManager.getPostActivitiesByPostIds(postIds as! String)
            }.then { _ -> Promise<[PostLike]> in
                
                if pageNo == 1 {
                    return PostManager.fetchUserLikes()
                }
                return Promise(value: [])
                
            }.always {
                
                self.collectionView.reloadData()
                
            }.catch { _ -> Void in
                Log.error("error")
        }
    }
    
    func followUser(_ user:User) {
        user.isLoading = true
        //        self.renderUserView()
        firstly {
            return FollowService.requestFollow(user.userKey)
            }.then { _ -> Void in
                user.isLoading = false
                user.isFollowUser = true
                user.followerCount += 1
                self.deleteRequest(user)
                self.headView.isFollowUser = user.isFollowUser
                //                self.profileHeader?.configButtonAddFollow(user.isFollowUser)
                //                self.renderUserView()
                NotificationCenter.default.post(name: Constants.Notification.followingDidUpdate, object: nil)
            }.catch { _ -> Void in
                user.isLoading = false
                //                self.renderUserView()
                Log.error("error")
        }
    }
    func onHandleAddFriend(_ friendStatus: StatusFriend) {
        guard LoginManager.getLoginState() == .validUser else {
            NotificationCenter.default.post(name: Constants.Notification.notifyUserLogin, object: SignupMode.publicProfile.rawValue)
            return
        }
        
        if friendStatus == .friend {
            let myRole: UserRole = UserRole(userKey: Context.getUserKey())
            let targetRole: UserRole = UserRole(userKey: self.userKey ?? "")
            
            WebSocketManager.sharedInstance().sendMessage(
                IMConvStartMessage(userList: [myRole, targetRole], senderMerchantId: myRole.merchantId),
                checkNetwork: true,
                viewController: self,
                completion: { [weak self] (ack) in
                    if let strongSelf = self, let convKey = ack.data {
                        let viewController = UserChatViewController(convKey: convKey)
                        strongSelf.navigationController?.pushViewController(viewController, animated: true)
                    }
                }
            )
            
            //            let str = String.localize("LB_CA_REMOVE_FRD_CONF")
            //            let message = str.replacingOccurrences(of: "{0}", with: " \(self.user.displayName) ")
            //            Alert.alert(self, title: "", message: message, okActionComplete: { () -> Void in
            //                self.deleteRequest(self.user)
            //                //                self.relationShip?.isFriend = false
            //                //                self.reloadData()
            //                //                self.logAction(self.view, sourceRef: "Unfriend")
            //                }, cancelActionComplete:{ () -> Void in
            //                    //                    self.renderUserView()
            //            })
            
        } else if friendStatus == .pending {
            let str = String.localize("LB_CA_FRD_REQ_CANCEL_CONF")
            let message = str.replacingOccurrences(of: "{0}", with: " \(self.user!.displayName) ")
            Alert.alert(self, title: "", message: message, okActionComplete: { () -> Void in
                if let user = self.user {
                    self.cancelRequest(user)
                }
            }, cancelActionComplete: { () -> Void in
            })
        } else if friendStatus == .unfriend {
            if let user = self.user {
                addFriend(user)
            }
        } else if friendStatus == .receivedFriendRequest {
            if let user = self.user {
                self.acceptRequest(user)
            }
        }
    }
    func acceptRequest(_ user: User) {
        firstly{
            return self.acceptFriendRequest(user)
            }.then
            { _ -> Void in
                user.isFriendUser = true
                self.relationShip?.isFriend = true
                if user.isFollowUser == false{
                    user.isFollowUser = true
                    user.followerCount += 1
                }
                self.checkStatusUser(user, friendRequest: true)
                CacheManager.sharedManager.addFriend(user)
            }.catch { _ -> Void in
                Log.error("error")
        }
    }
    func acceptFriendRequest(_ user:User) -> Promise<Any> {
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
                    }
            })
        }
    }
    func deleteRequest(_ user:User) {
        firstly {
            return self.deleteFriendRequest(user)
            }.then { _ -> Void in
                user.isFriendUser = false
                self.checkStatusUser(user, friendRequest: true)
                //                self.renderUserView()
            }.catch { _ -> Void in
                Log.error("error")
        }
    }
    private func addFriend(_ user:User) {
        self.relationShip?.isLoading = true
        firstly {
            return self.addFriendRequest(user)
            }.then { _ -> Void in
                user.isFriendUser = true
                user.isLoading = false
                if user.isFollowUser == false {
                    user.isFollowUser = true
                    user.followerCount += 1
                    FollowService.instance.cachedFollowingUserKeys.insert(user.userKey)
                }
                //                self.showSuccessPopupWithText(String.localize("MSG_SUC_FRIEND_REQ_SENT"))
            }.always {
                self.checkStatusUser(user, friendRequest: true)
                //                self.relationShip?.isLoading = false
                //                self.user.isLoading = false
                //                self.renderUserView()
            }.catch { _ -> Void in
                Log.error("error")
        }
    }
    func addFriendRequest(_ user:User) -> Promise<Any> {
        return Promise { fulfill, reject in
            FriendService.addFriendRequest(user, completion: { [weak self] (response) in
                if let strongSelf = self {
                    
                    if response.result.isSuccess {
                        if response.response?.statusCode == 200 {
                            //Server is caching by Etag, data will update later, shouldn't update immediately
                            //strongSelf.checkStatusUser(strongSelf.publicUser)
                            fulfill("OK")
                        } else {
                            strongSelf.handleApiResponseError(response, reject: reject)
                        }
                    } else {
                        reject(response.result.error!)
                        strongSelf.handleApiResponseError(response, reject: reject)
                    }
                }
            })
        }
    }
    func deleteFriendRequest(_ user:User) -> Promise<Any> {
        return Promise{ fulfill, reject in
            FriendService.deleteRequest(user, completion: { [weak self] (response) in
                if let strongSelf = self {
                    
                    if response.result.isSuccess {
                        if response.response?.statusCode == 200 {
                            //Server is caching by Etag, data will update later, shouldn't update immediately
                            //strongSelf.checkStatusUser(strongSelf.publicUser)
                            CacheManager.sharedManager.deleteFriend(user)
                            fulfill("OK")
                        } else {
                            strongSelf.handleApiResponseError(response, reject: reject)
                        }
                    } else {
                        reject(response.result.error!)
                        strongSelf.handleApiResponseError(response, reject: reject)
                    }
                }
            })
        }
    }
    
    private func cancelRequest(_ user:User) {
        //        self.relationShip?.isLoading = true
        firstly{
            return self.deleteFriendRequest(user)
            }.then { _ -> Void in
                user.isFriendUser = false
            }.always {
                self.checkStatusUser(user, friendRequest: true)
                //                self.relationShip?.isLoading = false
                //                self.renderUserView()
            }.catch { _ -> Void in
                Log.error("error")
        }
    }
    
    
    
    func onHandleAddFollow(_ followStatus: Bool) {
        guard LoginManager.getLoginState() == .validUser else {
            NotificationCenter.default.post(name: Constants.Notification.notifyUserLogin, object: SignupMode.publicProfile.rawValue)
            return
        }
        
        guard let user = self.user else {
            return
        }
        
        if followStatus {
            unfollowUser(user)
        } else {
            followUser(user)
        }
        
    }
    
    func unfollowUser(_ user:User) {
        let message = String.localize("LB_CA_UNFOLLOW_CONF").replacingOccurrences(of: "{0}", with: user.displayName)
        Alert.alert(self, title: "", message: message, okActionComplete: { () -> Void in
            user.isLoading = true
            
            // call api unfollow request
            firstly {
                return FollowService.requestUnfollow(user.userKey)
                }.then { _ -> Void in
                    user.isLoading = false
                    let filteredPosts = PostStorageManager.sharedManager.userPosts[FeedType.newsFeed.rawValue]?.filter({$0.user?.userKey != user.userKey})
                    PostStorageManager.sharedManager.userPosts[FeedType.newsFeed.rawValue] = filteredPosts
                    
                    user.isFollowUser = false
                    
                    if user.followerCount > 0 {
                        user.followerCount -= 1
                    } else {
                        user.followerCount = 0
                    }
                    //                    self.profileHeader?.configButtonAddFollow(user.isFollowUser)
                    //                    self.renderUserView()
                    self.headView.isFollowUser = user.isFollowUser
                    NotificationCenter.default.post(name: Constants.Notification.followingDidUpdate, object: nil)
                }.catch { error -> Void in
                    Log.error("error")
                    let error = error as NSError
                    if let apiResp = error.userInfo["data"] as? ApiResponse {
                        self.handleApiResponseError(apiResponse: apiResp, statusCode: error.code)
                    }
                    user.isLoading = false
                    //                    self.renderUserView()
            }
        }, cancelActionComplete:{() -> Void in
            user.isLoading = false
            //                self.renderUserView()
        })
    }
}

//MARK: UICollectionViewDelegate & UICollectionViewDataSource & PinterestLayoutDelegate
extension NewProfileViewController: PinterestLayoutDelegate {
    func didEndPullToRefresh() {
        fistLoadMore()
    }

    func scrollViewDidEndDecelerating(_ scrollView: UIScrollView) {
        if finshRequest == false {
            return
        }
        if canRush {
            canRush = false
            refreshView.startAnimating()
            
            getFollowingUsers(0, pageSize: Constants.Paging.Offset,rush:true)
        }

    }
    
    func scrollViewDidScroll(_ scrollView: UIScrollView) {
        if finshRequest == false {
            return
        }
        
        let offsetY = scrollView.contentOffset.y
        if let navigationController = self.navigationController as? MmNavigationController {
            navigationController.setNavigationBarVisibility(offset: offsetY + collectionView.contentInset.top)
        }
        
        if offsetY < -topImageViewHeight - headView.systemLayoutSizeFitting(UILayoutFittingCompressedSize).height - 30{
            canRush = true
        }
        
        if (offsetY <  -topImageViewHeight) {
            
            var frame = topImageView.frame
            frame.size.height = -offsetY - headView.systemLayoutSizeFitting(UILayoutFittingCompressedSize).height
            frame.origin.y = offsetY
            topImageView.frame = frame
      
            
        }
        if (offsetY < -topImageViewHeight/2 - headView.systemLayoutSizeFitting(UILayoutFittingCompressedSize).height) {
            self.navigationBarVisibility = .hidden
            self.title = ""
            setBarWhiteButtons()
        } else{
            self.navigationBarVisibility = .visible
            self.title = user?.displayName
            setBarGrayButtons()
        }
        
    }
    
    @objc func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, sizeForItemAtIndexPath indexPath: IndexPath) -> CGSize {
        
        var text = ""
        var userSourceName: String? = nil
        if let postManager = self.postManager, postManager.currentPosts.indices.contains(indexPath.row) {
            let post = postManager.currentPosts[indexPath.row]
            userSourceName = post.userSource?.userName
            text = post.postText
        }
        let height = SimpleFeedCollectionViewCell.getHeightForCell(text, userSourceName: userSourceName)
        return CGSize(width: SimpleFeedCollectionViewCell.getCellWidth(), height: height)
    }
    
    func collectionView(_ collectionView: UICollectionView, numberOfColumnsInSection section: Int) -> Int {
        return 2
    }
    
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, insetForSectionAt section: Int) -> UIEdgeInsets {
        return UIEdgeInsets(top: PostManager.NewsFeedLineSpacing, left: PostManager.NewsFeedLineSpacing, bottom: 25, right:PostManager.NewsFeedLineSpacing)
    }
    
    @objc func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, insetForSectionAtSection section: Int) -> UIEdgeInsets{
        return UIEdgeInsets(top: PostManager.NewsFeedLineSpacing, left: PostManager.NewsFeedLineSpacing, bottom: 25, right:PostManager.NewsFeedLineSpacing)
    }
    
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, minimumLineSpacingForSectionAtIndex section: Int) -> CGFloat {
        return PostManager.NewsFeedLineSpacing
    }
    
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, minimumInteritemSpacingForSectionAtIndex section: Int) -> CGFloat {
        return PostManager.NewsFeedLineSpacing
    }
}

extension NewProfileViewController: MMNavigationControllerDelegate {
    func preferredNavigationBarVisibility() -> MmFadeNavigationControllerNavigationBarVisibility? {
        return self.navigationBarVisibility
    }
}

