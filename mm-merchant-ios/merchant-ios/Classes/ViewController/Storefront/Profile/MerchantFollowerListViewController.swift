//
//  MerchantFollowerListViewController.swift
//  merchant-ios
//
//  Created by Vu Dinh Trung on 3/17/16.
//  Copyright © 2016 WWE & CO. All rights reserved.
//

import UIKit
import PromiseKit
import ObjectMapper
import Alamofire

class MerchantFollowerListViewController: MmViewController, FollowingUserViewCellDelegate {
    
    var merchant = Merchant()
    
    private final let CellId = "Cell"
    private final let followingUserViewCell = "FollowingUserViewCell"
    private final let orginYSearhBar: CGFloat = 104 + ScreenTop // 20 + 64 + 40
    private final let CatCellHeight : CGFloat = 40
    private final let CellHeight : CGFloat = 65
    var contentView = UIView()
    var followers = [User]()
    var listFollower = NSMutableArray()
    var start: Int = 0
    var limit: Int = Constants.Paging.Offset
    var searchBar: UISearchBar = UISearchBar()
    var placeHolderView = PlaceHolderView()
	
	var hasLoadMore = false
	
    override func viewDidLoad() {
        super.viewDidLoad()
        
        // Do any additional setup after loading the view.
        self.setupPlaceHolderView()
        
        setupCollectionView()
        self.createBackButton()
        
        self.title = String.localize("LB_CA_FOLLOWER_LIST")
        
        self.setupSearchBar()
        initAnalyticLog()
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)

		start = 0
		self.followers.removeAll()
		
        self.updateFollowersListView(start, pageSize: limit, merchantId: merchant.merchantId)
    }
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
	
	override func viewWillDisappear(_ animated: Bool) {
		super.viewWillDisappear(animated)
		self.refreshCollectionView()
	}

	func refreshCollectionView(){
		self.listFollower.removeAllObjects()
		self.renderView()
	}

    //MARK: - style View
    func setupPlaceHolderView() {
        placeHolderView.descriptionLabel.text = String.localize("LB_CA_NO_INFO_DISPLAY")
        placeHolderView.imageView.image = UIImage(named: "NoContact_icon")
        
        self.placeHolderView.isHidden = true
        placeHolderView.frame = self.view.bounds
        self.view.addSubview(placeHolderView)
    }
    
    func setupSearchBar(){
        searchBar.frame = CGRect(x:0, y: StartYPos, width: self.view.bounds.width, height: 40)
        searchBar.placeholder = String.localize("LB_CA_SEARCH")
        self.view.addSubview(self.searchBar)
        searchBar.delegate = self
        
        var textField : UITextField
        textField = searchBar.value(forKey: "_searchField") as! UITextField
        textField.layer.cornerRadius = 15
        textField.layer.masksToBounds = true
    }
    
    func setupCollectionView() {
        self.collectionView.delegate = self
        self.collectionView.dataSource = self
        self.collectionView.frame = CGRect(x:0, y: orginYSearhBar + searchBar.frame.height, width: self.view.bounds.width, height: self.view.bounds.height - orginYSearhBar)
        self.collectionView!.register(FollowingUserViewCell.self, forCellWithReuseIdentifier: followingUserViewCell)
    }
    
    override func backButtonClicked(_ button: UIButton) {
        self.navigationController?.popViewController(animated:true)
    }
    //MARK: SearchFriendViewCellDelegate
    func addFriendClicked(rowIndex: Int){
        Log.debug("addFriendClicked: \(rowIndex)")
        let user = self.followers[rowIndex]
        if user.friendStatus.length == 0 || user.friendStatus == String.localize("LB_CA_ADD_FRIEND") { //Not friend
            self.addFriend(user)
        } else if user.friendStatus == String.localize("LB_CA_FRD_REQ_CANCEL") {
            self.deleteRequest(user)
        }
        self.renderFollowersListView()
    }
    func followClicked(rowIndex: Int){
        Log.debug("followClicked: \(rowIndex)")
        let user = self.followers[rowIndex]
        if user.followStatus.length == 0 || user.followStatus == String.localize("LB_CA_FOLLOWED") { //Not follow
            user.followStatus = String.localize("LB_CA_FOLLOW")
            
            self.unfollowMerchant(merchant)
        } else {
            user.followStatus = String.localize("LB_CA_FOLLOWED")
            self.followMerchant(merchant)
        }
        self.renderFollowersListView()
    }
    func deleteRequest(_ user: User) {
        self.showLoading()
        firstly{
            return self.deleteFriendRequest(user)
            }.then
            { _ -> Void in
                user.friendStatus = String.localize("LB_CA_ADD_FRIEND")
                self.updateFollowersListView(self.start, pageSize: self.limit, merchantId: self.merchant.merchantId)
            }.always {
                self.stopLoading()
            }.catch { _ -> Void in
                Log.error("error")
        }
    }
    
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
                            reject(response.result.error!)
                            strongSelf.handleApiResponseError(response, reject: reject)
                        }
                    }
                })
        }
    }
    
    func addFriend(_ user: User) {
        self.showLoading()
        firstly{
            return self.addFriendRequest(user)
            }.then
            { _ -> Void in
                user.friendStatus = String.localize("LB_CA_FRD_REQ_CANCEL")
                self.showSuccessPopupWithText(String.localize("MSG_SUC_FRIEND_REQ_SENT"))
                self.updateFollowersListView(self.start, pageSize: self.limit, merchantId: self.merchant.merchantId)
            }.always {
                self.stopLoading()
            }.catch { _ -> Void in
                Log.error("error")
        }
    }
    func addFriendRequest(_ user: User) -> Promise<Any> {
        return Promise{ fulfill, reject in
            FriendService.addFriendRequest(user, completion:
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
    
    func renderView() {
        if self.followers.count > 0 {
            self.collectionView.isHidden = false
            self.placeHolderView.isHidden = true
            self.collectionView.reloadData()
        }else {
            self.collectionView.isHidden = true
            self.placeHolderView.isHidden = false
        }
    }
    
    //MARK: - delegate & datasource
    func numberOfSections(in collectionView: UICollectionView) -> Int {
        return 1
    }
    
    override func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        switch (collectionView) {
        case self.collectionView:
            return self.followers.count + 1
        default:
            return	0
        }
    }
    
    override func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        switch collectionView {
        case self.collectionView:
            let cell = collectionView.dequeueReusableCell(withReuseIdentifier: followingUserViewCell, for: indexPath) as! FollowingUserViewCell
//            cell.followButton.isHidden = true
			if indexPath.row == self.followers.count {
				let cell = loadingCellForIndexPath(indexPath)
				if (!hasLoadMore) {
					cell.isHidden = true
				} else {
					cell.isHidden = false
					
                    if let txt = searchBar.text, txt.isEmpty {
                        self.updateFollowersListView(start, pageSize: limit, merchantId: merchant.merchantId)
                    }
				}
				return cell
			} else {
				cell.delegateFollowingUserList = self
				if self.followers.count > 0 {
					let follower = self.followers[indexPath.row]
					cell.setupDataCell(follower )
                    cell.analyticsViewKey = self.analyticsViewRecord.viewKey
                    cell.followButton.tag = indexPath.row
                    cell.followButton.isHidden = follower.userKey == Context.getUserKey()
                    if let viewKey = cell.analyticsViewKey {
                        let merchantCode = follower.isMerchant == 1 ? follower.merchantCode : ""
                        
                        let impressionKey = AnalyticsManager.sharedManager.recordImpression(impressionRef: Context.getUserKey(), impressionType: follower.userTypeString(), impressionDisplayName: follower.userName, merchantCode: merchantCode, positionComponent: "FollowerListing", positionIndex: indexPath.row + 1, positionLocation: "FollowerListing", viewKey: viewKey)
                        cell.initAnalytics(withViewKey: viewKey, impressionKey: impressionKey)
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
        if let txt = searchBar.text, txt.isEmpty {
            activity.startAnimating()
        } else {
            activity.stopAnimating()
        }
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
                return CGSize(width: self.view.frame.size.width , height: CellHeight)
            default:
                return CGSize(width: self.view.frame.size.width / 4, height: Constants.Value.CatCellHeight)
            }
            
    }
    
    func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        let thisUser = self.followers[indexPath.row]
        self.fetchPublicUser(thisUser.userKey)
        
        //record action
        if let cell = collectionView.cellForItem(at: indexPath){
            cell.recordAction(.Tap, sourceRef: thisUser.userKey, sourceType: AnalyticsActionRecord.ActionElement(rawValue: thisUser.userTypeString()) ?? .Unknown, targetRef: thisUser.targetProfilePageTypeString(), targetType: .View)
        }
    }
    
    func renderFollowersListView() {
        self.followers = NSArray(array: self.listFollower) as! [User]
        self.renderView()
    }
    //MARK: - Loading Data
    func fetchFollowsList(_ pageIndex: Int, pageSize: Int, merchantId: Int) -> Promise<Any>{
        return Promise{ fulfill, reject in
            FollowService.listFollowMerchantByMerchantId(pageIndex, limit: pageSize, merchantId: merchantId, completion: { [weak self] (response) in
                if let strongSelf = self {
                    if response.result.isSuccess {
                        if response.response?.statusCode == 200 {
                            let followers = Mapper<User>().mapArray(JSONObject: response.result.value) ?? []
                            
                            Log.debug("followers.count : \(strongSelf.listFollower.count)")
                            
                            if followers.count > 0 {
                                //								self?.isEmpty = false
                                for follower in followers {
                                    follower.followStatus = String.localize("LB_CA_FOLLOWED")
                                    strongSelf.listFollower.add(follower)
                                }
                                if strongSelf.listFollower.count > 0 {
                                    strongSelf.followers = NSArray(array: strongSelf.listFollower) as! [User]
                                }
								
								strongSelf.hasLoadMore = followers.count >= strongSelf.limit
								
								strongSelf.start += strongSelf.limit
								
                            } else {
								
								strongSelf.hasLoadMore = false
                            }
                            
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
                
			})
        }
    }
    
    func updateFollowersListView(_ pageIndex: Int, pageSize: Int, merchantId: Int){
//        self.showLoading()
        firstly{
            
            return self.fetchFollowsList(pageIndex, pageSize: pageSize, merchantId: merchantId)
            }.then { _ -> Void in
                self.renderFollowersListView()
            }.always {
                self.renderFollowersListView()
                self.stopLoading()
            }.catch { _ -> Void in
                Log.error("error")
        }
    }
    
    // Handle api follow merchant
    
    func unfollowMerchant(_ merchant: Merchant) {
        firstly{
            
            return FollowService.requestUnfollow(merchant: merchant)
            }.then { _ -> Void in
                self.renderFollowersListView()
            }.always {
                self.renderFollowersListView()
                self.stopLoading()
            }.catch { error -> Void in
                Log.error("error")
                let error = error as NSError
                if let apiResp = error.userInfo["data"] as? ApiResponse {
                    self.handleError(apiResp, statusCode: error.code, animated: true)
                }
        }
    }
    
    
    func followMerchant(_ merchant: Merchant) {
        firstly{
            
            return FollowService.requestFollow(merchant: merchant)
            }.then { _ -> Void in
                self.renderFollowersListView()
            }.always {
                self.stopLoading()
            }.catch { error -> Void in
                Log.error("error")
                let error = error as NSError
                if let apiResp = error.userInfo["data"] as? ApiResponse {
                    self.handleError(apiResp, statusCode: error.code, animated: true)
                }
        }
    }
    
    //MARK: api follow
    func followUser(_ user: User, sender: ButtonFollow) {
		
		// detect guest mode
		guard (LoginManager.getLoginState() == .validUser) else {
			LoginManager.goToLogin()
			return
		}
		
        //record action
        if let analyticsImpressionKeySuperview = sender.superview?.analyticsImpressionKey {
            sender.initAnalytics(withViewKey: self.analyticsViewRecord.viewKey, impressionKey: analyticsImpressionKeySuperview)
            sender.recordAction(.Tap, sourceRef: "Follow", sourceType: .Button, targetRef: user.userKey, targetType: AnalyticsActionRecord.ActionElement(rawValue: user.userTypeString()) ?? .Unknown)
        }
        user.isLoading = true
        sender.showLoading()
        
        firstly{
            return FollowService.requestFollow(user.userKey)
            }.then
            { _ -> Void in
                user.isLoading = false
                sender.hideLoading()
                self.renderView()
            }.catch { error -> Void in
                Log.error("error")
                let error = error as NSError
                if let apiResp = error.userInfo["data"] as? ApiResponse {
                    self.handleApiResponseError(apiResponse: apiResp, statusCode: error.code)
                }
                user.isLoading = false
                sender.hideLoading()
                self.renderView()
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
            
            user.isLoading = true
            sender.showLoading()
            // call api unfollow request
            firstly{
                return FollowService.requestUnfollow(user.userKey)
                }.then
                { _ -> Void in
                    user.isLoading = false
                    sender.hideLoading()
                    self.renderView()
                }.catch { error -> Void in
                    Log.error("error")
                    
                    let error = error as NSError
                    if let apiResp = error.userInfo["data"] as? ApiResponse {
                        self.handleApiResponseError(apiResponse: apiResp, statusCode: error.code)
                    }
                    user.isLoading = false
                    sender.hideLoading()
                    self.renderView()
            }
            }, cancelActionComplete:nil)
    }
    
    //MARK: - delegate merchant cell
    func onTapFollowHandle(_ rowIndex: Int, sender: ButtonFollow) {
        let user = self.followers[rowIndex]
        if FollowService.instance.cachedFollowingUserKeys.contains(user.userKey) { //
            unfollowUser(user, sender: sender)
        } else {
            followUser(user, sender: sender)
        }

    }
    
    //MARK: -Search
    
    func filter(_ text: String) {
        let array = NSArray(array: self.listFollower) as! [User]
        self.followers = array.filter(){ ($0.displayName).lowercased().range(of: text.lowercased()) != nil }
        self.renderView()
    }
    
    // MARK: 搜索回调
    @objc func searchBarTextDidBeginEditing(_ searchBar: UISearchBar) {
        
    }
    
    @objc func searchBarTextDidEndEditing(_ searchBar: UISearchBar) {
        
    }
    
    @objc func searchBarCancelButtonClicked(_ searchBar: UISearchBar) {
        
        self.view.endEditing(true)
    }
    
    @objc func searchBarSearchButtonClicked(_ searchBar: UISearchBar) {
        self.filter(searchBar.text!)
    }
    @objc func searchBar(_ searchBar: UISearchBar, textDidChange searchText: String) {
        if searchBar.text?.length == 0 {
            self.renderFollowersListView()
        } else {
            self.filter(searchText)
        }
    }
    
    @objc func searchBarShouldBeginEditing(_ searchBar: UISearchBar) -> Bool {
        
        searchBar.showsCancelButton = true
        styleCancelButton(true)
        return true
    }
    
    @objc func searchBarShouldEndEditing(_ searchBar: UISearchBar) -> Bool {
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
    
    // MARK: Logging
    func initAnalyticLog(){
        initAnalyticsViewRecord(
            nil,
            authorType: nil,
            brandCode: nil,
            merchantCode: self.merchant.merchantCode,
            referrerRef: nil,
            referrerType: nil,
            viewDisplayName: self.merchant.merchantName,
            viewParameters: nil,
            viewLocation: "FollowerListing",
            viewRef: "\(self.merchant.merchantId)",
            viewType: "Merchant"
        )
    }
}
