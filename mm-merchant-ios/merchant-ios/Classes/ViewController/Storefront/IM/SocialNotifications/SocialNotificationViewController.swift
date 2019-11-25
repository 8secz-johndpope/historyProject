//
//  SocialNotificationViewController.swift
//  merchant-ios
//
//  Created by HungPM on 9/5/17.
//  Copyright © 2017 WWE & CO. All rights reserved.
//

import Foundation
import PromiseKit

class SocialNotificationViewController: MmViewController {
    private static let SocialNotificationCellIdentifier = "SocialNotificationCell"
    private static let SocialNotificationEmptyCellIdentifier = "SocialNotificationEmptyCell"
    
    private var shouldShowEmptyCell = false
    private var haveNetwork = false
    
    var dataSource = [SocialMessage]()
    var socialMessageType = SocialMessageType.postLiked
    
    // MARK:- View Lifecycle
    override func viewDidLoad() {
        super.viewDidLoad()
        
        var viewTitle = ""
        switch socialMessageType {
        case .postLiked:
            viewTitle = String.localize("LB_CA_NOTIFICATION_LIKE")
            
        case .postComment:
            viewTitle = String.localize("LB_CA_NOTIFICATION_COMMENT")
            
        case .follow:
            viewTitle = String.localize("LB_CA_NOTIFICATION_NEW_FOLLOWER")
        }
        
        title = viewTitle
        initAnalyticLog(viewTitle: viewTitle)
        
        createBackButton()
        setupCollectionView()
        setupNotification()
        
        getSocialMessages()
    }
    
    func setupCollectionView() {
        collectionView.register(UINib(nibName: SocialNotificationViewController.SocialNotificationCellIdentifier, bundle: nil), forCellWithReuseIdentifier: SocialNotificationViewController.SocialNotificationCellIdentifier)
        collectionView.register(UINib(nibName: SocialNotificationViewController.SocialNotificationEmptyCellIdentifier, bundle: nil), forCellWithReuseIdentifier: SocialNotificationViewController.SocialNotificationEmptyCellIdentifier)
    }
    
    func setupNotification() {
        NotificationCenter.default.addObserver(self, selector: #selector(getSocialMessages), name: NSNotification.Name(rawValue: SocialMessageDidUpdateNotification), object: nil)
    }
    
    // MARK:- Service
    @objc func getSocialMessages() {
        showLoading()
        
        let cleanup = { [weak self] (haveNetwork: Bool) in
            if let strongSelf = self {
                strongSelf.shouldShowEmptyCell = true
                strongSelf.haveNetwork = haveNetwork
                strongSelf.collectionView.isScrollEnabled = !strongSelf.dataSource.isEmpty
                strongSelf.collectionView.reloadData()
                
                strongSelf.stopLoading()
            }
        }
        
        SocialMessageService.listSocialMessage(socialMessageType.rawValue, success: { [weak self] (socialMessageResponse) in
            if let strongSelf = self {
                strongSelf.dataSource = socialMessageResponse.pageData.sorted { $0.lastCreated > $1.lastCreated }
                if !strongSelf.dataSource.isEmpty {
                    strongSelf.setReadSocialMessages(strongSelf.dataSource[0].socialMessageId)
                }
                cleanup(true)
            }
            
        }) {  _ -> Bool in
            cleanup(false)
            return false
        }
    }
    
    func setReadSocialMessages(_ lastMessageId: Int) {
        SocialMessageService.readSocialMessage(lastMessageId, success: { [weak self] activateResponse in
            if let strongSelf = self, activateResponse.success {
                switch strongSelf.socialMessageType {
                case .postLiked:
                    SocialMessageManager.sharedManager.postLikedUnread = 0
                    
                case .postComment:
                    SocialMessageManager.sharedManager.postCommentUnread = 0
                    
                case .follow:
                    SocialMessageManager.sharedManager.followUnread = 0
                }
                PostNotification(SocialMessageUnreadChangedNotification)
            }
        }) { (error) -> Bool in
            return true
        }
    }
    
    // MARK:- UICollectionViewDataSource
    override func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        
        if dataSource.isEmpty && shouldShowEmptyCell {
            return 1
        }
        
        return dataSource.count
    }
    
    override func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        
        if dataSource.isEmpty {
            let cell = collectionView.dequeueReusableCell(withReuseIdentifier: SocialNotificationViewController.SocialNotificationEmptyCellIdentifier, for: indexPath) as! SocialNotificationEmptyCell
            
            switch socialMessageType {
            case .postLiked:
                cell.imageView.image = UIImage(named: "like notification-empty")
                cell.label.text = String.localize("LB_CA_NOTIFICATION_NO_LIKE")
                
            case .postComment:
                cell.imageView.image = UIImage(named: "comment notification-empty")
                cell.label.text = String.localize("LB_CA_NOTIFICATION_NO_COMMENT")
                
            case .follow:
                cell.imageView.image = UIImage(named: "Follower-empty")
                cell.label.text = String.localize("LB_CA_NOTIFICATION_NO_NEW_FOLLOWER")
            }
            
            cell.label.isHidden = !haveNetwork
            cell.imageView.isHidden = !haveNetwork
            
            return cell
            
        }
        
        let cell = collectionView.dequeueReusableCell(withReuseIdentifier: SocialNotificationViewController.SocialNotificationCellIdentifier, for: indexPath) as! SocialNotificationCell
        
        cell.socialMessage = dataSource[indexPath.item]
        
        cell.profileImageTapHandler = {  user in
            
                
                PushManager.sharedInstance.goToProfile(user, hideTabBar: true)
           
        }
        
        cell.buttonTapHandler = { [weak self] userKey, isFollowing, displayName in
            if let strongSelf = self {
                Log.debug("button tapped")
                if isFollowing {
                    let message = String.localize("LB_CA_UNFOLLOW_CONF").replacingOccurrences(of: "{0}", with: displayName)
                    Alert.alert(strongSelf, title: "", message: message, okActionComplete: { () -> Void in
                        firstly{
                            return FollowService.requestUnfollow(userKey)
                            }.then { _ -> Void in
                                collectionView.reloadData()
                            }.catch { error -> Void in
                                Log.error("error")
                                
                                let error = error as NSError
                                if let apiResp = error.userInfo["data"] as? ApiResponse {
                                    strongSelf.handleApiResponseError(apiResponse: apiResp, statusCode: error.code)
                                }
                        }
                    }, cancelActionComplete:nil)
                } else {
                    firstly {
                        return FollowService.requestFollow(userKey)
                        }.then { _ -> Void in
                            collectionView.reloadData()
                        }.catch { error -> Void in
                            Log.error("error")
                            
                            let error = error as NSError
                            if let apiResp = error.userInfo["data"] as? ApiResponse {
                                strongSelf.handleApiResponseError(apiResponse: apiResp, statusCode: error.code)
                            }
                    }
                }
            }
        }
        
        return cell
    }
    
    //MARK:- UICollectionViewDelegateFlowLayout
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, minimumLineSpacingForSectionAt section: Int) -> CGFloat {
        return 0
    }
    
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, minimumInteritemSpacingForSectionAt section: Int) -> CGFloat {
        return 0
    }
    
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, insetForSectionAt section: Int) -> UIEdgeInsets {
        if dataSource.isEmpty {
            return UIEdgeInsets.zero
        }
        
        return UIEdgeInsets(top: 4, left: 0, bottom: 0, right: 0)
    }
    
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, sizeForItemAt indexPath: IndexPath) -> CGSize {
        if dataSource.isEmpty {
            return CGSize(width: Constants.ScreenSize.SCREEN_WIDTH, height: collectionView.frame.height)
        }
        
        return CGSize(width: Constants.ScreenSize.SCREEN_WIDTH, height: 92)
    }
    
    //MARK:- UICollectionDelegate
    func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        if !dataSource.isEmpty, let socialMessage = dataSource.get(indexPath.row) {
            switch socialMessageType {
            case .postComment, .postLiked:
                let postDetailController = PostDetailViewController(postId: socialMessage.entityId)
                self.navigationController?.pushViewController(postDetailController, animated: true)
            case .follow:
                if let userKey = socialMessage.fromUserKey {
                    let user = User()
                    user.userKey = userKey
                    PushManager.sharedInstance.goToProfile(user, hideTabBar: true)
                }
            }
        }
    }

    //MARK: - Analytics Logging
    
    func initAnalyticLog(viewTitle: String = ""){
        
        var viewLocation = ""
        
        switch socialMessageType {
        case .postLiked:
            viewLocation = "Like-Landing"
            
        case .postComment:
            viewLocation = "Comment-Landing"
            
        case .follow:
            viewLocation = "NewFollower-Landing"
            
        }
        
        initAnalyticsViewRecord(
            nil,
            authorType: nil,
            brandCode: nil,
            merchantCode: nil,
            referrerRef: nil,
            referrerType: nil,
            viewDisplayName: viewTitle,
            viewParameters: nil,
            viewLocation: viewLocation,
            viewRef: nil,
            viewType: "SocialNotification"
        )
    }
}
