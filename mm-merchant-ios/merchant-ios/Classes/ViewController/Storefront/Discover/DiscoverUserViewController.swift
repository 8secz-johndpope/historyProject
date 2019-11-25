//
//  DiscoverUserViewController.swift
//  merchant-ios
//
//  Created by Quang Truong on 12/11/17.
//  Copyright © 2017 WWE & CO. All rights reserved.
//

import Foundation
import UIKit
import Alamofire
import PromiseKit
import ObjectMapper

class DiscoverUserViewController: SearchFriendViewController{
    
    private final let DiscoverFriendViewCellID = "DiscoverFriendViewCellID"
    weak var scrollViewDelegate: ProductListViewControllerDelegate?
    override func viewDidLoad() {
        super.viewDidLoad()
        
        collectionView.register(DiscoverFriendViewCell.self, forCellWithReuseIdentifier: DiscoverFriendViewCellID)
        collectionView.bounces = false
        collectionView.alwaysBounceVertical = true
        collectionView.frame = self.view.bounds
        
        let pageHeight:CGFloat = 45.0
        collectionView.contentInset = UIEdgeInsets(top: 0, left: 0, bottom: StartYPos + pageHeight, right: 0)
    }
    
    override func setupSearchResultsController() {
        
    }
    
    override func showSearchBar() {
        
    }
    
    override func doSearch(_ string: String, isRefresh: Bool) {
        if LoginManager.isValidUser() {
            super.doSearch(string, isRefresh: isRefresh)
        }
    }
    
    func refreshData(){
        doSearch(searchString, isRefresh: true)
    }
    
    override func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        if indexPath.row == dataSource.count {
            let cell = loadingCellForIndexPath(indexPath)
            if (!hasLoadMore) {
                cell.isHidden = true
            } else {
                cell.isHidden = false
                
                loadMore()
            }
            return cell
            
        } else {
            
            let cell = collectionView.dequeueReusableCell(withReuseIdentifier: DiscoverFriendViewCellID, for: indexPath) as! DiscoverFriendViewCell
            cell.isSearchFriend = true
            cell.analyticsViewKey = self.analyticsViewRecord.viewKey
            
            let user = dataSource[indexPath.row]
            cell.setData(user)
            cell.followButton.tag = indexPath.row
            
            // Impression tag
            let impressionKey = recordImpression(
                impressionRef: user.userKey,
                impressionType: user.userTypeString(),
                impressionDisplayName: user.displayName,
                merchantCode: user.merchant.merchantCode,
                positionComponent: "UserListing",
                positionIndex: indexPath.row + 1,
                positionLocation: "Search-User"
            )
            
            cell.analyticsImpressionKey = impressionKey
            
            cell.followButtonClickHandler = { [weak self] (_, button) in
                guard let strongSelf = self else{
                    return
                }
                
                if strongSelf.dataSource.indices.contains(button.tag){
                    let user = strongSelf.dataSource[button.tag]
                    if strongSelf.isFollowed(user){
                        strongSelf.unfollowUser(user, sender: button)
                    }
                    else{
                        strongSelf.followUser(user, sender: button)
                    }
                    
                }
            }
            return cell
        }
    }

    //MARK: - APIs
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
    
    override func scrollViewDidScroll(_ scrollView: UIScrollView) {
//        if let delegate = scrollViewDelegate {
//            delegate.productListViewControllerScrollViewDidScroll(scrollView)
//        }
    }
    
    //MARK: - Helpers
    
    func isFollowed(_ user: User) ->Bool{
        return FollowService.instance.cachedFollowingUserKeys.contains(user.userKey)
    }
}
