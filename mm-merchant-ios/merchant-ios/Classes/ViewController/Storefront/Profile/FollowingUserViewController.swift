//
//  FollowingUserViewController.swift
//  merchant-ios
//
//  Created by Trung Vu on 3/7/16.
//  Copyright © 2016 WWE & CO. All rights reserved.
//

import UIKit
import PromiseKit
import ObjectMapper
import Alamofire

enum FollowingUserMode: Int {
    case GetFollowingUserPrivateProfile = 0,
    GetFollowingUserPublicProfile
}
class FollowingUserListViewController: MmViewController, FollowingUserViewCellDelegate, FollowViewControllerDelegate {
    
    private final let CellId = "Cell"
    private final let FollowingUserViewId = "FollowingUserViewCell"
    
    private final let CatCellHeight : CGFloat = 40
    private final let CellHeight : CGFloat = 65
    private final let heightTopView: CGFloat = 144
    var contentView = UIView()
    var dataSource  = NSArray()
    var followingUsers: NSMutableArray = NSMutableArray()
    var start: Int = 0
    var limit: Int = Constants.Paging.Offset
    var arrayUser = [User]()
    
    var currentProfileType: TypeProfile = .Private
    var user: User = User()
    var followingUserMode: FollowingUserMode?
    var hasLoadMore = false
    var searchText:String = ""
    var searchBar:UISearchBar?
    
    override func viewDidLoad() {
        super.viewDidLoad()
        setupCollectionView()
        initAnalyticLog()
    }
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        reloadData()
    }
    
    func reloadData() {
        
        start = 0
        
        self.refreshCollectionView()
        
        switch (currentProfileType) {
        case .Private:
            self.getFollowingUsers(start, pageSize: limit, userKey: Context.getUserKey())
            break
        case .Public:
            self.getFollowingUsers(start, pageSize: limit, userKey: user.userKey)
            break
        }

    }
    
    override func viewWillDisappear(_ animated: Bool) {
//        super.viewWillDisappear(animated)
		//override super's class viewWillDisappear to stop causing issue on following list
    }
    
    //MARK: - style View
    func setupCollectionView() {
        self.collectionView.delegate = self
        self.collectionView.dataSource = self
        self.collectionView.frame = CGRect(x:0, y: 0, width: self.view.bounds.width, height: self.view.bounds.height - heightTopView)
        self.collectionView!.register(FollowingUserViewCell.self, forCellWithReuseIdentifier: FollowingUserViewId)
        self.collectionView?.register(PlaceHolderCell.self, forCellWithReuseIdentifier: PlaceHolderCell.PlaceHolderCellIdentifier)
        
    }

    func refreshCollectionView(){
        self.followingUsers.removeAllObjects()
        self.collectionView.reloadData()
    }
	
    //MARK: - delegate & datasource
    
    func numberOfSections(in collectionView: UICollectionView) -> Int {
        return 1
    }
    
    override func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        switch (collectionView) {
        case self.collectionView:
            return self.followingUsers.count + 1
        default:
            return 0
        }
    }
    
    override func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        switch collectionView {
        case self.collectionView:
            if self.followingUsers.count == 0 {
                let cell = collectionView.dequeueReusableCell(withReuseIdentifier: PlaceHolderCell.PlaceHolderCellIdentifier, for: indexPath) as! PlaceHolderCell
                cell.descriptionLabel.text = String.localize("LB_CA_NO_FOLLOWED_USER")
                cell.imageView.image = UIImage(named: "placeholder_icon_follow")
                return cell
            }
            let cell = collectionView.dequeueReusableCell(withReuseIdentifier: FollowingUserViewId, for: indexPath) as! FollowingUserViewCell
			
			// hide follow / unfollow button for public profile
			cell.followButton.isHidden = (currentProfileType == .Public) && (user.userKey != Context.getUserKey())
			
            if indexPath.row == self.followingUsers.count {
                let cell = loadingCellForIndexPath(indexPath)
                if (!hasLoadMore) {
                    cell.isHidden = true
                } else {
                    cell.isHidden = false

                    switch (currentProfileType) {
                    case .Private:
                        self.getFollowingUsers(start, pageSize: limit, userKey: Context.getUserKey())
                        break
                    case .Public:
                        self.getFollowingUsers(start, pageSize: limit, userKey: user.userKey)
                        break
                    }
                    
                    
                }
                return cell
            } else {
                cell.delegateFollowingUserList = self
                cell.followButton.tag = indexPath.row
                cell.profileType = self.currentProfileType
                if self.followingUsers.count > 0 {
                    if let followingUser = self.followingUsers[indexPath.row] as? User{
                        cell.followButton.isHidden = (followingUser.userKey != Context.getUserKey() ? false : true)
                        cell.setupDataCell(followingUser)
                        cell.initAnalytics(withViewKey: self.analyticsViewRecord.viewKey, impressionKey: AnalyticsManager.sharedManager.recordImpression(nil, authorType: nil, brandCode: nil, impressionRef: followingUser.userKey, impressionType: followingUser.userTypeString(), impressionVariantRef: nil, impressionDisplayName: followingUser.displayName, merchantCode: String(format: "%d", followingUser.merchantId), parentRef: nil, parentType: nil, positionComponent: "FollowerListing", positionIndex: indexPath.row + 1, positionLocation: "MyFollow-User", referrerRef: nil, referrerType: nil, viewKey: self.analyticsViewRecord.viewKey))
                    }
                }
            }
            
            return cell
            
        default:
            return getDefaultCell(collectionView, cellForItemAt: indexPath)
            
        }
    }
    
    func getDefaultCell(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell{
        let cell = collectionView.dequeueReusableCell(withReuseIdentifier: CellId, for: indexPath)
        return cell
    }
    func loadingCellForIndexPath(_ indexPath: IndexPath) -> UICollectionViewCell {
        let cell = getDefaultCell(self.collectionView, cellForItemAt: indexPath)
        let activity = UIActivityIndicatorView(activityIndicatorStyle: UIActivityIndicatorViewStyle.gray)
        activity.center = cell.center
        cell.addSubview(activity)
        activity.startAnimating()
        return cell
    }
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, minimumInteritemSpacingForSectionAt section: Int) -> CGFloat {
        return 0.0
    }
    
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, minimumLineSpacingForSectionAt section: Int) -> CGFloat {
        return 0.0
    }
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, sizeForItemAt indexPath: IndexPath) -> CGSize {
            switch (collectionView) {
            case self.collectionView:
                if self.followingUsers.count == 0 {
                    return CGSize(width: self.view.frame.size.width , height: self.collectionView.frame.height)
                }
                return CGSize(width: self.view.frame.size.width , height: CellHeight)
            default:
                return CGSize(width: self.view.frame.size.width / 4, height: Constants.Value.CatCellHeight)
            }
            
    }
    
    func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        if self.followingUsers.count > 0 {
            let user = self.followingUsers[indexPath.row] as! User
            
            self.fetchPublicUser(user.userKey)
            
            //record action
            if let cell = collectionView.cellForItem(at: indexPath){
                cell.recordAction(.Tap, sourceRef: user.userKey, sourceType: AnalyticsActionRecord.ActionElement(rawValue: user.userTypeString()) ?? .Unknown, targetRef: user.targetProfilePageTypeString(), targetType: .View)
                
                if searchText.length > 0{
                    recordSearchBarAction(user.userKey)
                }
            }
        }
    }
    
    func renderFollowingUserView() {
        self.followingUsers = NSMutableArray(array: self.arrayUser)
        self.collectionView.reloadData()
    }
    
    func searchTextChanged(_ text: String, searchBar: UISearchBar){
        searchText = text
        self.searchBar = searchBar
        if text.length == 0 {
            self.renderFollowingUserView()
        } else {
            self.filter(text, searchBar: searchBar)
        }
    }
    
    func filter(_ text: String, searchBar: UISearchBar){
        let array = self.arrayUser.filter(){ ($0.displayName).lowercased().range(of: text.lowercased()) != nil }
        self.followingUsers = NSMutableArray(array: array)
        self.collectionView.reloadData()
        if array.count == 0{
            recordSearchBarAction(nil)
        }
    }
    
    func recordSearchBarAction(_ userKey: String?){
        if let searchBar = self.searchBar{
            searchBar.initAnalytics(withViewKey: self.analyticsViewRecord.viewKey)
            searchBar.recordAction(.Input, sourceRef: searchText, sourceType: .Text, targetRef: (userKey == nil ? "":userKey), targetType: .User)
        }
    }
    
    // get Merchant for Public profile
    
    func getFollowingUsers(_ pageIndex: Int, pageSize: Int, userKey: String) {
//        self.showLoading()
        firstly{
            
            return FollowService.listFollowingUsers(.getNonCuratorUser, byUser: userKey, start: pageIndex, limit: pageSize)
            }.then { users -> Void in
                
                if users.count > 0 {
                    
                    for user in users {
                        self.followingUsers.add(user)
                    }
                    self.arrayUser = NSArray(array: self.followingUsers) as! [User]
                    self.arrayUser.sortByDisplayName()
                    self.hasLoadMore = users.count >= self.limit
                    self.start += self.limit
                    
                } else {
                    self.hasLoadMore = false
                }
            }.always {
                self.renderFollowingUserView()
                self.stopLoading()
            }.catch { _ -> Void in
                Log.error("error")
        }
    }
    //MARK: api follow
    func followUser(_ user: User, sender: ButtonFollow) {
        
        //record action
        if let analyticsImpressionKeySuperview = sender.superview?.analyticsImpressionKey {
            
            sender.initAnalytics(withViewKey: self.analyticsViewRecord.viewKey, impressionKey: analyticsImpressionKeySuperview)
            sender.recordAction(.Tap, sourceRef: "Follow", sourceType: .Button, targetRef: user.userKey, targetType: AnalyticsActionRecord.ActionElement(rawValue: user.userTypeString()) ?? .Unknown)
            
        }
        
        sender.showLoading()
        user.isLoading = true
        
        firstly{
            return FollowService.requestFollow(user.userKey)
            }.then
            { _ -> Void in
                user.isFollowUser = true
                user.followStatus = String.localize("LB_CA_FOLLOWED")
                user.followerCount += 1
                user.isLoading = false
                sender.hideLoading()
                self.renderUserView()
            }.catch { error -> Void in
                Log.error("error")
                let error = error as NSError
                if let apiResp = error.userInfo["data"] as? ApiResponse {
                    self.handleApiResponseError(apiResponse: apiResp, statusCode: error.code)
                }
                user.isLoading = false
                sender.hideLoading()
                self.renderUserView()
        }
    }
    
    
    func unfollowUser(_ user: User, sender: ButtonFollow) {
        let message = String.localize("LB_CA_UNFOLLOW_CONF").replacingOccurrences(of: "{0}", with: user.displayName)
        Alert.alert(self, title: "", message: message, okActionComplete: { () -> Void in
            //record action
            
            if let analyticsImpressionKeySuperview = sender.superview?.analyticsImpressionKey {
                
                sender.initAnalytics(withViewKey: self.analyticsViewRecord.viewKey, impressionKey: analyticsImpressionKeySuperview)
                sender.recordAction(.Tap, sourceRef: "Unfollow", sourceType: .Button, targetRef: user.userKey, targetType: AnalyticsActionRecord.ActionElement(rawValue: user.userTypeString()) ?? .Unknown)
                
            }
            
            sender.showLoading()
            user.isLoading = true
            // call api unfollow request
            firstly{
                return FollowService.requestUnfollow(user.userKey)
                }.then
                { _ -> Void in
                    user.isFollowUser = false
                    user.followStatus = String.localize("LB_CA_FOLLOW")
                    user.followerCount -= 1
                    user.isLoading = false
                    sender.hideLoading()
                    self.renderUserView()
                }.catch { error -> Void in
                    Log.error("error")
                    
                    let error = error as NSError
                    if let apiResp = error.userInfo["data"] as? ApiResponse {
                        self.handleApiResponseError(apiResponse: apiResp, statusCode: error.code)
                    }
                    user.isLoading = false
                    sender.hideLoading()
                    self.renderUserView()
            }
            }, cancelActionComplete:nil)
    }
    
    
    func renderUserView() {
        self.collectionView.reloadData()
    }

    @discardableResult
    func fetchPublicUser(_ userKey: String) -> Promise<Any>{
        return Promise{ fulfill, reject in
            UserService.viewWithUserKey(userKey){[weak self] (response) in
				if let strongSelf = self {
					if response.result.isSuccess {
						if response.response?.statusCode == 200 {
							
							let user = Mapper<User>().map(JSONObject: response.result.value)!
							
							strongSelf.showPublicProfile(user)
							
							fulfill("OK")
							
						} else {
							var statusCode = 0
							if let code = response.response?.statusCode {
								statusCode = code
							}
							
							let error = NSError(domain: "", code: statusCode, userInfo: nil)
							reject(error)
						}
					} else {
						reject(response.result.error!)
					}
				}
            }
        }
    }
	
    func showPublicProfile(_ user: User) {
        PushManager.sharedInstance.goToProfile(user, hideTabBar: false)
    }
    
    //MARK: - FollowingUserViewCellDelegate
    func onTapFollowHandle(_ rowIndex: Int, sender: ButtonFollow) {
        
        guard LoginManager.getLoginState() == .validUser else {
            LoginManager.goToLogin()
            return
        }
        
        if let user = self.followingUsers[rowIndex] as? User{
            if self.isFollowed(user) { //
                unfollowUser(user, sender: sender)
            } else {
                followUser(user, sender: sender)
            }
        }
    }
    
    func isFollowed(_ user: User) ->Bool{
        return FollowService.instance.cachedFollowingUserKeys.contains(user.userKey)
    }
    
    //MARK: FollowViewControllerDelegate
    func didSelectCancelButton(_ searchBar: UISearchBar) {
        log.debug("Cancel Search")
    }
    func didSelectSearchButton(_ text: String, searchBar: UISearchBar) {
        searchTextChanged(text, searchBar: searchBar)
    }

    func didTextChange(_ text: String, searchBar: UISearchBar) {
        searchTextChanged(text, searchBar: searchBar)
    }
    
    // MARK: Logging
    func initAnalyticLog(){
        let user = self.currentUser()
        initAnalyticsViewRecord(
            nil,
            authorType: nil,
            brandCode: nil,
            merchantCode: user.merchant.merchantCode,
            referrerRef: nil,
            referrerType: nil,
            viewDisplayName: user.userName,
            viewParameters: nil,
            viewLocation: "MyFollow-User",
            viewRef: user.userKey,
            viewType: "User"
        )
    }
    
    func currentUser() -> User{
        return (self.currentProfileType == .Public ? self.user : Context.getUserProfile())
    }
}
