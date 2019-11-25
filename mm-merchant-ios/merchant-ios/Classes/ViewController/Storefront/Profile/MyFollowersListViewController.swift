//
//  MyFollowersListViewController.swift
//  merchant-ios
//
//  Created by Markus Chow on 14/3/2016.
//  Copyright © 2016 WWE & CO. All rights reserved.
//

import UIKit

import PromiseKit
import ObjectMapper
import Alamofire


enum GetFollowerMode: Int {
    case GetFollowerByMerchantId = 0
    case GetFollowerByUserkey
}

class MyFollowersListViewController: MmViewController, SearchFriendViewCellDelegate, FollowViewControllerDelegate, FollowingUserViewCellDelegate {

	private final let CellId = "Cell"
	private final let searchFriendViewCell = "SearchFriendViewCell"
    private final let FollowingUserViewId = "FollowingUserViewCell"

	private final let CatCellHeight : CGFloat = 40
	private final let CellHeight : CGFloat = 65
	var contentView = UIView()
	var followers: NSMutableArray = NSMutableArray()
    var backupData: NSMutableArray = NSMutableArray()
    
	var start: Int = 0
	var limit: Int = Constants.Paging.Offset
    var thisUser = User()
    var currentProfileType = TypeProfile.Private
    var hasLoadMore = false
    var isMoreLoad = false
    
    override func viewDidLoad() {
        super.viewDidLoad()
		setupCollectionView()
        initAnalyticLog()
    }

    override func viewWillAppear(_ animated: Bool) {
		super.viewWillAppear(animated)
        self.collectionView.frame = self.view.bounds
		self.followers.removeAllObjects()
        start = 0
		switch(self.currentProfileType) {
        case .Private:
            self.updateFollowersListView(start, pageSize: limit)
            break;
        case .Public:
            self.updateFollowersListViewPublicProfile(start, pageSize: limit, usekey: self.thisUser.userKey)
            break;
        }
		
	}
	
	override func viewWillDisappear(_ animated: Bool) {
		super.viewWillDisappear(animated)
		self.refreshCollectionView()
	}

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
	
	func refreshCollectionView(){
		self.followers.removeAllObjects()
		self.collectionView.reloadData()
	}
	
	//MARK: - style View
	func setupCollectionView() {
		self.collectionView.delegate = self
		self.collectionView.dataSource = self
		self.collectionView!.register(FollowingUserViewCell.self, forCellWithReuseIdentifier: FollowingUserViewId)
        self.collectionView?.register(PlaceHolderCell.self, forCellWithReuseIdentifier: PlaceHolderCell.PlaceHolderCellIdentifier)
	}
	
	//MARK: SearchFriendViewCellDelegate
	func addFriendClicked(_ rowIndex: Int){
		Log.debug("addFriendClicked: \(rowIndex)")
		let user = self.followers[rowIndex] as! User
		if user.friendStatus.length == 0 || user.friendStatus == String.localize("LB_CA_ADD_FRIEND") { //Not friend
			self.addFriend(user)
		} else if user.friendStatus == String.localize("LB_CA_FRD_REQ_CANCEL") {
			self.deleteRequest(user)
		}
		self.renderFollowersListView()
	}
	
	func followClicked(_ rowIndex: Int){
		Log.debug("followClicked: \(rowIndex)")
		let user = self.followers[rowIndex] as! User
		if user.followStatus.length == 0 || user.followStatus == String.localize("LB_CA_FOLLOW") { //Not follow
			user.followStatus = String.localize("LB_CA_FOLLOWED")
        }
		self.renderFollowersListView()
	}
	
	func deleteRequest(_ user:User) {
		self.showLoading()
		firstly{
			return self.deleteFriendRequest(user)
			}.then
			{ _ -> Void in
				user.friendStatus = String.localize("LB_CA_ADD_FRIEND")
				self.updateFollowersListView(self.start, pageSize: self.limit)
			}.always {
				self.stopLoading()
			}.catch { _ -> Void in
				Log.error("error")
		}
	}
	
	func deleteFriendRequest(_ user:User) -> Promise<Any> {
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
	
	func addFriend(_ user:User) {
		self.showLoading()
		firstly{
			return self.addFriendRequest(user)
			}.then
			{ _ -> Void in
				user.friendStatus = String.localize("LB_CA_FRD_REQ_CANCEL")
				self.showSuccessPopupWithText(String.localize("MSG_SUC_FRIEND_REQ_SENT"))
				self.updateFollowersListView(self.start, pageSize: self.limit)
			}.always {
				self.stopLoading()
			}.catch { _ -> Void in
				Log.error("error")
		}
	}
	
	func addFriendRequest(_ user:User) -> Promise<Any> {
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
    func fetchPublicUser(_ userKey: String, completion: ((User)->())?) -> Promise<Any>{
		return Promise{ fulfill, reject in
			UserService.viewWithUserKey(userKey){[weak self] (response) in
				if let strongSelf = self {
					if response.result.isSuccess {
						if response.response?.statusCode == 200 {
							
                            if let user = Mapper<User>().map(JSONObject: response.result.value) {
                                
                                strongSelf.showPublicProfile(user)
                                
                                if let callBack = completion {
                                    
                                    callBack(user)
                                }
                                
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
			}
		}
	}
	
	func showPublicProfile(_ user: User) {
        PushManager.sharedInstance.goToProfile(user,hideTabBar: true)
	}
	
	//MARK: - delegate & datasource
	func numberOfSections(in collectionView: UICollectionView) -> Int {
		return 1
	}
	
	override func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
		switch (collectionView) {
		case self.collectionView:
            if self.followers.count == 0 {
                return 1
            }
            return self.followers.count + (self.hasLoadMore ? 1:0)
		default:
			return	0
            
		}
	}
	
	override func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
		switch collectionView {
		case self.collectionView:
            if self.followers.count == 0 {
                let cell = collectionView.dequeueReusableCell(withReuseIdentifier: PlaceHolderCell.PlaceHolderCellIdentifier, for: indexPath) as! PlaceHolderCell
                cell.descriptionLabel.text = String.localize("LB_CA_FOLLOWER_NOTFOUND")
                cell.imageView.image = UIImage(named: "NoContact_icon")
                return cell
            }
			let cell = collectionView.dequeueReusableCell(withReuseIdentifier: FollowingUserViewId, for: indexPath) as! FollowingUserViewCell

            cell.delegateFollowingUserList = self
			
            
            if indexPath.row == self.followers.count {
                let cell = loadingCellForIndexPath(indexPath)
                if (!hasLoadMore) {
                    cell.isHidden = true
                } else {
                    cell.isHidden = false

                    switch(self.currentProfileType) {
                    case .Private:
                        self.updateFollowersListView(start, pageSize: limit)
                        break;
                    case .Public:
                        self.updateFollowersListViewPublicProfile(start, pageSize: limit, usekey: self.thisUser.userKey)
                    }
                }
                return cell
                
            } else {
                if self.followers.count > 0 {
                    if let follower = self.followers[indexPath.row] as? User{
                        cell.followButton.tag = indexPath.row
                        cell.setupDataCell(follower)
                        cell.followButton.isHidden = follower.userKey == Context.getUserKey()

                        cell.analyticsViewKey = self.analyticsViewRecord.viewKey
                        if let viewKey = cell.analyticsViewKey {
                            let impressionType = follower.userTypeString() //fix MM-22063
                            cell.initAnalytics(withViewKey: viewKey, impressionKey: AnalyticsManager.sharedManager.recordImpression(impressionRef: follower.userKey, impressionType: impressionType, impressionDisplayName: follower.displayName, merchantCode: String(format: "%d", follower.merchantId), positionComponent: "FollowerListing" , positionIndex: indexPath.row + 1, positionLocation: self.currentProfileType == .Private ? "MyFollowerListing" : "FollowerListing", viewKey: viewKey))
                            
                            
                        }
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
        cell .addSubview(activity)
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
                if self.followers.count == 0 {
                    return CGSize(width: self.view.frame.size.width , height: self.collectionView.frame.height)
                }
				return CGSize(width: self.view.frame.size.width , height: CellHeight)
			default:
				return CGSize(width: self.view.frame.size.width / 4, height: Constants.Value.CatCellHeight)
			}
			
	}
    
    func getUserType(_ user: User) -> AnalyticsActionRecord.ActionElement {
        
        var type = AnalyticsActionRecord.ActionElement.User
        
        if user.isCurator == 1 {
            type = AnalyticsActionRecord.ActionElement.Curator
        }
        else if user.isMerchant == 1 {
            type = AnalyticsActionRecord.ActionElement.MerchantUser
        }
        return type
    }
	
	func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        if self.followers.count > indexPath.row {
            if let thisUser = self.followers[indexPath.row] as? User {
                
                //self.fetchPublicUser(thisUser.userKey)
                
                self.fetchPublicUser(thisUser.userKey, completion: {[weak self] (user) in
                    
                    if let strongSelf = self {
                        //record action
                        if let cell = collectionView.cellForItem(at: indexPath){
                            cell.recordAction(.Tap, sourceRef: user.userKey, sourceType: strongSelf.getUserType(user), targetRef: user.targetProfilePageTypeString(), targetType: .View)
                        }
                    }
                    })
            }
        }
	}
	
	func renderFollowersListView() {
		self.collectionView.reloadData()
	}
	//MARK: - Loading Data
	func fetchFollowsList(_ pageIndex: Int, pageSize: Int) -> Promise<Any>{
		return Promise{ fulfill, reject in
			FollowService.listFollowers(pageIndex, limit: pageSize, completion: { [weak self] (response) in
				if let strongSelf = self {
					if response.result.isSuccess {
						if response.response?.statusCode == 200 {
							let followers:[User] = Mapper<User>().mapArray(JSONObject: response.result.value) ?? []

							Log.debug("followers.count : \(followers.count)")
							
							if followers.count > 0 {

                                strongSelf.followers.addObjects(from: followers)
								strongSelf.hasLoadMore = followers.count >= strongSelf.limit
								
								strongSelf.start += strongSelf.limit
								strongSelf.backupData = NSMutableArray(array: strongSelf.followers)
                                
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
	
	func updateFollowersListView(_ pageIndex: Int, pageSize: Int){
		firstly{
			
			return self.fetchFollowsList(pageIndex, pageSize: pageSize)
			}.then { _ -> Void in
				self.renderFollowersListView()
			}.always {
				self.renderFollowersListView()
				self.stopLoading()
			}.catch { _ -> Void in
				Log.error("error")
		}
	}
	
	// get user public profile 
    func fetchFollowsListPubLicProfile(_ pageIndex: Int, pageSize: Int, useKey: String) -> Promise<Any>{
        return Promise{ fulfill, reject in
            FollowService.listFollowersPublicUser(pageIndex, limit: pageSize, useKey: useKey, completion: { [weak self] (response) in
                if let strongSelf = self {
                    if response.result.isSuccess {
                        if response.response?.statusCode == 200 {
                            let followers:[User] = Mapper<User>().mapArray(JSONObject: response.result.value) ?? []
                            
                            Log.debug("followers.count : \(followers.count)")
                            
                            if followers.count > 0 {
                                strongSelf.followers.addObjects(from: followers)
								strongSelf.hasLoadMore = followers.count >= strongSelf.limit
								
								strongSelf.start += strongSelf.limit
                                strongSelf.backupData = NSMutableArray(array: strongSelf.followers)
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
    
    func updateFollowersListViewPublicProfile(_ pageIndex: Int, pageSize: Int, usekey: String){

        firstly{
            
            return self.fetchFollowsListPubLicProfile(pageIndex, pageSize: pageSize, useKey: usekey)
            }.then { _ -> Void in
                self.renderFollowersListView()
            }.always {
                self.stopLoading()
            }.catch { _ -> Void in
                Log.error("error")
        }
    }
    
    
	//MARK: - delegate merchant cell
	func onTapFollowHandle(sender: UIButton) {
		
	}
    
    func onTapFollowHandle(_ rowIndex: Int, sender: ButtonFollow) {
        if let user = self.followers[rowIndex] as? User{
            if self.isFollowed(user){
                self.unfollowUser(user, sender: sender)
            }
            else{
                self.followUser(user, sender: sender)
            }
        }
    }
    
    func isFollowed(_ user: User) ->Bool{
        return FollowService.instance.cachedFollowingUserKeys.contains(user.userKey)
    }

    func followUser(_ user: User, sender: ButtonFollow) {
        //record action
        
        if let analyticsImpressionKeySuperview = sender.superview?.analyticsImpressionKey {
            
            sender.initAnalytics(withViewKey: self.analyticsViewRecord.viewKey, impressionKey: analyticsImpressionKeySuperview)
            sender.recordAction(.Tap, sourceRef: "Follow", sourceType: .Button, targetRef: user.userKey, targetType: self.getActionTargetType(user))
            
        }
        
        sender.showLoading()
        user.isLoading = true
        Log.debug("Follow clicked")
        firstly {
            return FollowService.requestFollow(user.userKey)
            }.always {
                self.stopLoading()
                user.isLoading = false
                sender.hideLoading()
                self.collectionView.reloadData()
            }.catch { _ -> Void in
                Log.error("error")
        }
    }
    
    // analytics record
    
    func getActionTargetType (_ user: User) -> AnalyticsActionRecord.ActionElement {
        
        var targetType = AnalyticsActionRecord.ActionElement.User
        if user.isCurator == 1 {
            
            targetType = .Curator
            
        } else {
            
            targetType = .User
        }
        
        return targetType
    }

    
    func unfollowUser(_ user: User, sender: ButtonFollow) {
        Log.debug("Unfollow clicked")
        let message = String.localize("LB_CA_UNFOLLOW_CONF").replacingOccurrences(of: "{0}", with: user.displayName)
        Alert.alert(self, title: "", message: message, okActionComplete: { () -> Void in
            //record action
            
            if let analyticsImpressionKeySuperview = sender.superview?.analyticsImpressionKey {
                
                sender.initAnalytics(withViewKey: self.analyticsViewRecord.viewKey, impressionKey: analyticsImpressionKeySuperview)
                sender.recordAction(.Tap, sourceRef: "Unfollow", sourceType: .Button, targetRef: user.userKey, targetType: self.getActionTargetType(user))
            
            }
            
            
            user.isLoading = true
            sender.showLoading()
            firstly {
                return FollowService.requestUnfollow(user.userKey)
                }.always {
                    self.stopLoading()
                    user.isLoading = false
                    sender.hideLoading()
                    self.collectionView.reloadData()
                }.catch { error -> Void in
                    Log.error("error")
                    
                    let error = error as NSError
                    if let apiResp = error.userInfo["data"] as? ApiResponse {
                        self.handleApiResponseError(apiResponse: apiResp, statusCode: error.code)
                    }
            }
            }, cancelActionComplete:nil)
    }
    
    //MARK: Delegate Search
    func filter(_ text:String) {
        let array = self.backupData.filter({ (object) -> Bool in
            (object as! User).displayName.contain(text.lowercased())
        })
        self.followers = NSMutableArray(array: array)
        self.collectionView.reloadData()
    }
	
    func didSelectCancelButton(_ searchBar: UISearchBar) {
        log.debug("Cancel Search")
    }
    
    func didSelectSearchButton(_ text: String, searchBar: UISearchBar) {
        self.filter(text)
    }
  
    func didTextChange(_ text: String, searchBar: UISearchBar) {
        if text.length == 0 {
            self.renderCuratorView()
        } else {
            self.filter(text)
        }
    }
    
    func renderCuratorView() {
        self.followers = NSMutableArray(array: self.backupData)
        self.collectionView.reloadData()
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
            viewLocation: self.currentProfileType == .Private ?  "MyFollowerListing": "FollowerListing",
            viewRef: user.userKey,
            viewType: self.currentProfileType == .Private ?  "User" : user.userTypeString()
        )
    }
    
    func currentUser() -> User{
        return (self.currentProfileType == .Public ? self.thisUser : Context.getUserProfile())
    }
}
