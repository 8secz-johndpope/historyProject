//
//  ProductLikeUserListViewController.swift
//  merchant-ios
//
//  Created by Quang Truong Dinh on 2/20/17.
//  Copyright © 2017 WWE & CO. All rights reserved.
//

import Foundation
import ObjectMapper
import PromiseKit

class ProductLikeUserListViewController: MmViewController, FollowingUserViewCellDelegate{
    
    var productLikeList = [ProductLikeItem](){
        didSet{
            updateTitle()
        }
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        createBackButton()
        setupCollectionView()
        updateTitle()
    }
    
    func setupCollectionView() {
        collectionView?.backgroundColor = UIColor.primary2()
        collectionView?.register(ProductLikeUserCell.self, forCellWithReuseIdentifier: ProductLikeUserCell.CellIdentifier)
    }
    
    func updateTitle(){
        self.title = "(\(productLikeList.count)人) 喜欢这件单品"
    }

    func numberOfSections(in collectionView: UICollectionView) -> Int {
        return 1
    }
    
    override func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return productLikeList.count
    }
    
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, sizeForItemAt indexPath: IndexPath) -> CGSize {
        return CGSize(width: view.width, height: ProductLikeUserCell.DefaultHeight)
    }
    
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, insetForSectionAt section: Int) -> UIEdgeInsets {
        return UIEdgeInsets(top: 15, left: 0, bottom: 0, right: 0)
    }
    
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, minimumLineSpacingForSectionAt section: Int) -> CGFloat {
        return 5
    }
    
    override func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        let cell = collectionView.dequeueReusableCell(withReuseIdentifier: ProductLikeUserCell.CellIdentifier, for: indexPath) as! ProductLikeUserCell
        cell.followButton.tag = indexPath.row
        cell.delegateFollowingUserList = self
        cell.setupCellData(productLikeList[indexPath.row])
        return cell
    }
    
    func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        let index = indexPath.row
        guard index < self.productLikeList.count && index >= 0 else{
            return
        }
        openUserProfile(self.productLikeList[index])
    }
    
    //MARK: - FollowingUserViewCellDelegate
    
    func onTapFollowHandle(_ rowIndex: Int, sender: ButtonFollow) {
        handleFollow(rowIndex, sender: sender, fromGuestMode: false)
    }
    
    private func handleFollow(_ rowIndex: Int, sender: ButtonFollow, fromGuestMode: Bool){
        if LoginManager.getLoginState() != .validUser {
            LoginManager.goToLogin {
                self.handleFollow(rowIndex, sender: sender, fromGuestMode: fromGuestMode)
            }
            return
        }
        
        guard self.productLikeList.indices.contains(rowIndex) else{
            return
        }
        
        let productLiked = self.productLikeList[rowIndex]
        if FollowService.isFollowing(productLiked.userKey) && !fromGuestMode{
            unfollowUser(productLiked, sender: sender)
        } else {
            followUser(productLiked, sender: sender)
        }
    }
    
    //MARK: - Helpers
    func openUserProfile(_ productLikeItem : ProductLikeItem) -> Void {
        DeepLinkManager.sharedManager.pushPublicProfile(viewController: self, userName: productLikeItem.userName)
    }
    
    //MARK: - Web Services
    func followUser(_ productLiked: ProductLikeItem, sender: ButtonFollow) {
        productLiked.isLoading = true
        sender.showLoading()
        firstly {
            return FollowService.requestFollow(productLiked.userKey)
            }.then { _ -> Void in
                self.showSuccessPopupWithText(String.localize("MSG_SUC_FOLLOWED"))
                productLiked.isLoading = false
                sender.hideLoading()
                self.collectionView.reloadData()
            }.catch { _ -> Void in
                Log.error("error")
                productLiked.isLoading = false
                sender.hideLoading()
                self.collectionView.reloadData()
        }
    }
    
    func unfollowUser(_ productLiked: ProductLikeItem, sender: ButtonFollow ) {
        productLiked.isLoading = true
        sender.showLoading()
        firstly {
            return FollowService.requestUnfollow(productLiked.userKey)
            }.then { _ -> Void in
                productLiked.isLoading = false
                sender.hideLoading()
                self.collectionView.reloadData()
            }.catch { error -> Void in
                Log.error("error")
                
                let error = error as NSError
                if let apiResp = error.userInfo["data"] as? ApiResponse {
                    self.handleApiResponseError(apiResponse: apiResp, statusCode: error.code)
                }
                productLiked.isLoading = false
                sender.hideLoading()
                self.collectionView.reloadData()
        }
    }
}
