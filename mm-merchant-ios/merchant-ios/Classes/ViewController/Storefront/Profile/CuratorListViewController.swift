//
//  CuratorListViewController.swift
//  merchant-ios
//
//  Created by Trung Vu on 3/7/16.
//  Copyright © 2016 WWE & CO. All rights reserved.
//

import UIKit
import PromiseKit
import ObjectMapper


class CuratorListViewController: MmViewController, CuratorListDelegate, FollowViewControllerDelegate {
    
    
    private final let CellId = "Cell"
    private final let CuratorListViewCellId = "CuratorListViewCellId"
    
    private final let CatCellHeight : CGFloat = 40
    private final let CellHeight : CGFloat = 65
    private final let TopViewHeight: CGFloat = 144
    var contentView = UIView()
    var curators = [User]()
    var start = 0
    var limit = Constants.Paging.Offset
    var datasources = [User]()
    var currentProfileType : TypeProfile = TypeProfile.Private
    var user = User()
    var hasLoadMore = false
    var searchText:String = ""
    var searchBar:UISearchBar?
    
    override func viewDidLoad() {
        super.viewDidLoad()
        setupCollectionView()
        initAnalyticLog()
    }
	
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
		
		self.view.endEditing(true)
		
		self.reloadData()
    }
    
    func reloadData(){
        start = 0
        
        self.curators.removeAll()
        self.collectionView.reloadData()
        switch (self.currentProfileType) {
        case TypeProfile.Private:
            self.updateFollowersListView(start, pageSize: limit)
        case TypeProfile.Public:
            self.updateFollowersListView(start, pageSize: limit, userKey: user.userKey)
        }
    }
	
    override func viewWillDisappear(_ animated: Bool) {
//        super.viewWillDisappear(animated)
        //we don't call super method because the super method causes the issue on following list
    }
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
	
	
    //MARK: - style View
    func setupCollectionView() {
        self.collectionView.frame = CGRect(x:0, y: 0, width: self.view.bounds.width, height: self.view.bounds.height - TopViewHeight)
        self.collectionView!.register(CuratorListViewCell.self, forCellWithReuseIdentifier: CuratorListViewCellId)
        self.collectionView?.register(PlaceHolderCell.self, forCellWithReuseIdentifier: PlaceHolderCell.PlaceHolderCellIdentifier)
    }

    func refreshCollectionView(){
        self.curators.removeAll()
        self.collectionView.reloadData()
    }
    
    //MARK: - delegate & datasource
    
    func numberOfSections(in collectionView: UICollectionView) -> Int {
        return 1
    }
    
    override func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        switch (collectionView) {
        case self.collectionView:
            return self.curators.count + 1
        default:
            return 0
        }
    }
    
    
    
    override func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        switch collectionView {
        case self.collectionView:
            
            if self.curators.count == 0 {
                let cell = collectionView.dequeueReusableCell(withReuseIdentifier: PlaceHolderCell.PlaceHolderCellIdentifier, for: indexPath) as! PlaceHolderCell
                cell.descriptionLabel.text = String.localize("LB_CA_NO_FOLLOWED_CURATOR")
                cell.imageView.image = UIImage(named: "placeholder_icon_follow")
                return cell
            }
            let cell = collectionView.dequeueReusableCell(withReuseIdentifier: CuratorListViewCellId, for: indexPath) as! CuratorListViewCell
			
			// hide follow / unfollow button for public profile
			cell.followButton.isHidden = (currentProfileType == .Public) && (user.userKey != Context.getUserKey())

            if indexPath.item == self.curators.count {
                let cell = loadingCellForIndexPath(indexPath)
                if (!hasLoadMore) {
                    cell.isHidden = true
                } else {
                    cell.isHidden = false

                    switch (self.currentProfileType) {
                    case .Private:
                        self.updateFollowersListView(start, pageSize: limit)
                    case .Public:
                        self.updateFollowersListView(start, pageSize: limit, userKey: user.userKey)
                    }

                }
                return cell
            } else {
                cell.deletate_ = self
                let user = self.curators[indexPath.row]
                cell.followButton.isHidden = (user.userKey != Context.getUserKey() ? false : true)
                cell.followButton.tag = indexPath.row
                cell.setupData(user)
                cell.analyticsViewKey = self.analyticsViewRecord.viewKey
                if let viewKey = cell.analyticsViewKey {
                    cell.initAnalytics(withViewKey: viewKey, impressionKey: AnalyticsManager.sharedManager.recordImpression(impressionRef: Context.getUserKey(), impressionType: "Curator", impressionDisplayName: Context.getUsername(), merchantCode: user.merchant.merchantCode, positionComponent: "FollowerListing", positionIndex: indexPath.row + 1, positionLocation: "MyFollow-User", viewKey: viewKey))
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
                if self.curators.count == 0 {
                    return CGSize(width: self.view.frame.size.width , height: self.collectionView.frame.height)
                }
                return CGSize(width: self.view.frame.size.width , height: CellHeight)
            default:
                return CGSize(width: self.view.frame.size.width / 4, height: Constants.Value.CatCellHeight)
            }
            
    }
    
    func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        if self.curators.count > 0 {
            let curator = self.curators[indexPath.row]
            let user = User()
            user.userKey = curator.userKey
            user.userName = curator.userName
            PushManager.sharedInstance.goToProfile(user, hideTabBar: false)
            
            //record action
            if let cell = collectionView.cellForItem(at: indexPath){
                cell.recordAction(.Tap, sourceRef: curator.userKey, sourceType: .Curator, targetRef: "CPP", targetType: .View)
                
                if searchText.length > 0{
                    recordSearchBarAction(curator.userKey)
                }
            }
        }
    }
    //MARK: - loading Data
    
    func updateFollowersListView(_ pageIndex: Int, pageSize: Int, userKey: String = Context.getUserKey()){
        firstly{
            
            return FollowService.listFollowingUsers(.getCuratorOnly, byUser: userKey, start: pageIndex, limit: pageSize)
            
        }.then { (followers) -> Void in
            
            if followers.count > 0 {
                self.curators.append(contentsOf: followers)
                self.datasources = self.curators
                self.hasLoadMore = followers.count >= self.limit
                self.start += self.limit
                
            } else {
                self.hasLoadMore = false
            }
    
        }.always {
            self.collectionView.reloadData()

        }.catch { _ -> Void in
            Log.error("error")
        }
    }
    
    
    public func didSelectFollow(_ rowInt: Int, sender: ButtonFollow) {
        
        guard LoginManager.getLoginState() == .validUser else {
            LoginManager.goToLogin()
            return
        }
        
        let user = self.curators[rowInt]
        if self.isFollowed(user) { //
            unfollowUser(user, sender: sender)
        } else {
            followUser(user, sender: sender)
        }
        
    }
    
    func isFollowed(_ user: User) ->Bool{
        return FollowService.instance.cachedFollowingUserKeys.contains(user.userKey)
    }
    
    //MARK: api follow
    func followUser(_ user:User, sender: ButtonFollow) {
        
        //record action
        if let analyticsImpressionKeySuperview = sender.superview?.analyticsImpressionKey {
            
            sender.initAnalytics(withViewKey: self.analyticsViewRecord.viewKey, impressionKey: analyticsImpressionKeySuperview)
            sender.recordAction(.Tap, sourceRef: "Follow", sourceType: .Button, targetRef: user.userKey, targetType: .Curator)
            
        }
        
        sender.showLoading()
        user.isLoading = true
        firstly{
            return FollowService.requestFollow(user.userKey)
            }.then
            { _ -> Void in
                user.isFollowUser = true
                user.followStatus = String.localize("LB_CA_FOLLOW")
                user.followerCount += 1
                user.isLoading = false
                sender.hideLoading()
                self.collectionView.reloadData()
            }.always {
                self.stopLoading()
            }.catch { error -> Void in
                Log.error("error")
                let error = error as NSError
                if let apiResp = error.userInfo["data"] as? ApiResponse {
                    self.handleApiResponseError(apiResponse: apiResp, statusCode: error.code)
                }
                user.isLoading = false
                sender.hideLoading()
                self.collectionView.reloadData()
        }
    }
   
    func unfollowUser(_ user:User, sender: ButtonFollow) {
        let message = String.localize("LB_CA_UNFOLLOW_CONF").replacingOccurrences(of: "{0}", with: user.displayName)
        Alert.alert(self, title: "", message: message, okActionComplete: { () -> Void in
            //record action
            
            if let analyticsImpressionKeySuperview = sender.superview?.analyticsImpressionKey {
                
                sender.initAnalytics(withViewKey: self.analyticsViewRecord.viewKey, impressionKey: analyticsImpressionKeySuperview)
                sender.recordAction(.Tap, sourceRef: "Unfollow", sourceType: .Button, targetRef: user.userKey, targetType: .Curator)
            }
           

            // call api unfollow request
            sender.showLoading()
            user.isLoading = true
            firstly{
                return FollowService.requestUnfollow(user.userKey)
                }.then
                { _ -> Void in
                    user.isFollowUser = false
                    user.followStatus = String.localize("LB_CA_FOLLOWED")
                    user.followerCount -= 1
                    user.isLoading = false
                    sender.hideLoading()
                    self.collectionView.reloadData()
                }.always {
                    self.stopLoading()
                }.catch { error -> Void in
                    Log.error("error")
                    let error = error as NSError
                    if let apiResp = error.userInfo["data"] as? ApiResponse {
                        self.handleApiResponseError(apiResponse: apiResp, statusCode: error.code)
                    }
                    user.isLoading = false
                    sender.hideLoading()
                    self.collectionView.reloadData()
            }
            }, cancelActionComplete:nil)
    }
    
   
    func searchTextChanged(_ text: String, searchBar: UISearchBar){
        searchText = text
        self.searchBar = searchBar
        if text.length == 0 {
            self.renderCuratorView()
        } else {
            self.filter(text, searchBar: searchBar)
        }
    }

    func recordSearchBarAction(_ userKey: String?){
        if let searchBar = self.searchBar{
            searchBar.initAnalytics(withViewKey: self.analyticsViewRecord.viewKey)
            searchBar.recordAction(.Input, sourceRef: searchText, sourceType: .Text, targetRef: (userKey == nil ? "":userKey), targetType: .Curator)
        }
    }
    
    //MARK: Delegate Search
    func filter(_ text: String, searchBar: UISearchBar){
        let array = self.datasources.filter(){ ($0.displayName).lowercased().range(of: text.lowercased()) != nil }
        self.curators = array
        self.collectionView.reloadData()
        if array.count == 0{
            recordSearchBarAction(nil)
        }
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
    
    func renderCuratorView() {
        self.curators = self.datasources
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
            viewLocation: "MyFollow-Curator",
            viewRef: user.userKey,
            viewType: "Curator"
        )
    }
    
    func currentUser() -> User{
        return (self.currentProfileType == .Public ? self.user : Context.getUserProfile())
    }
}
