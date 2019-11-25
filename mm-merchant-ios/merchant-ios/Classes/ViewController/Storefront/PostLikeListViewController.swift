//
//  PostLikeListViewController.swift
//  merchant-ios
//
//  Created by Tony Fung on 4/10/2016.
//  Copyright © 2016年 WWE & CO. All rights reserved.
//

import UIKit
import PromiseKit
import ObjectMapper

struct UserLikeStruct {
    
    var likeObj: PostLike
    private var isUserFollowing: Bool? //THIS ONE SHOULD BE REAL PRIVATE
    
    init(like: PostLike){
        self.likeObj = like
    }
    
    var isFollowingUser : Bool {
        mutating get {
//            if let follow = isUserFollowing {
//                return follow
//            } else {
                let follow = FollowService.instance.cachedFollowingUserKeys.contains(likeObj.userKey ?? "")
                isUserFollowing = follow
                return follow
//            }
        }
    }
    

    
}

extension UserLikeStruct: Equatable {}

func ==(lhs: UserLikeStruct, rhs: UserLikeStruct) -> Bool{
    return lhs.likeObj == rhs.likeObj
}

class PostLikeListViewController: MmViewController {
    
    
    
    var post : Post!
    
    var isHideTabBar = false
    private var totalLike = 0
    private var likeStructs : [UserLikeStruct] = []
    
    private var pageNo : Int = 1
    
    private var localShallowMyLike: UserLikeStruct? //for locally append like object
    
    
    override func viewDidLoad() {
        super.viewDidLoad()

        refreshLikeList()
        
        self.collectionView.register(PostLikeViewCell.self, forCellWithReuseIdentifier: "PostLikeViewCell")
        self.collectionView.register(PlaceHolderCell.self, forCellWithReuseIdentifier: PlaceHolderCell.PlaceHolderCellIdentifier)
        
        self.title = String.localize("LB_CA_POST_LIKE_COUNT").replacingOccurrences(of: "{0}", with: String(totalLike))
        self.createBackButton()
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    func insertMyUserLikeForThisPost() {
        
        let isMeLikedInResponse = likeStructs.contains { (likeStruct) -> Bool in
            return likeStruct.likeObj.userKey == Context.getUserKey()
        }
        
        if !isMeLikedInResponse {
            //we check is we liked it locally
            if let likeIndex = PostStorageManager.sharedManager.userLikes.index(where: { (like) -> Bool in
                return like.postId == self.post.postId && like.statusId == Constants.StatusID.active.rawValue
            }) {
                // I have liked this post
                let like = PostStorageManager.sharedManager.userLikes[likeIndex]
                let user = Context.getUserProfile()
                like.displayName = user.displayName
                like.profileImageKey = user.profileImage
                like.isCurator = (user.isCurator == 1)
                like.userKey = user.userKey
                
                if localShallowMyLike != nil {
                    likeStructs.remove(localShallowMyLike!)
                }
                localShallowMyLike = UserLikeStruct(like: like)
                likeStructs.insert(localShallowMyLike!, at: 0)
            }
        } else if localShallowMyLike != nil{
            
            likeStructs.remove(localShallowMyLike!)
            localShallowMyLike = nil
            // we have liked in response. we have to remove the local like if any is inserted 
            
        }
        
    }
    
    
    func fetchLikeObjects(_ pageNo: Int = 1) -> Promise<Any> {
        return Promise { fulfill, reject in
            NewsFeedService.getLikedObjectsByPost(post.postId, pageNo: pageNo) { [weak self](response) in
                if response.result.isSuccess {
                    
                    if response.response?.statusCode == 200, let postLikeResponse: PostLikeResponse = Mapper<PostLikeResponse>().map(JSONObject: response.result.value) {
                        self?.totalLike = postLikeResponse.hitsTotal
                        
                        if pageNo == 1 {
                            self?.likeStructs = []
                        }
                        
                        let pagedLikes = (postLikeResponse.likeList ?? []).map({ (like) -> UserLikeStruct in
                            return UserLikeStruct(like: like)
                        })
                        
                        self?.likeStructs.append(contentsOf: pagedLikes)
                        
                        if pageNo == 1 {
                            self?.insertMyUserLikeForThisPost()
                        }
                        
                        fulfill("OK")
                    } else {
                        let error = NSError(domain: "", code: response.response?.statusCode ?? 0, userInfo: nil)
                        reject(error)
                    }
                }else {
                    reject(response.result.error!)
                }
            }
        }
    }
    
    
    func refreshLikeList(_ pageNo: Int = 1) {

        fetchLikeObjects(pageNo).then { (_) -> Void in
            self.pageNo = pageNo
            self.collectionView.reloadData()
            self.title = String.localize("LB_CA_POST_LIKE_COUNT").replacingOccurrences(of: "{0}", with: String(self.totalLike))
        }
    
    }
    
    //MARK: Collection View methods and delegates
    override func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return self.likeStructs.count > 0 ? self.likeStructs.count : 1
    }
    
    func numberOfSections(in collectionView: UICollectionView) -> Int {
        return 1
    }
    
    override func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        
        if self.likeStructs.count == 0 {
            let cell = collectionView.dequeueReusableCell(withReuseIdentifier: PlaceHolderCell.PlaceHolderCellIdentifier, for: indexPath) as! PlaceHolderCell
            cell.descriptionLabel.text = String.localize("LB_CA_NO_COMMENT")
            return cell
        }
        let cell = collectionView.dequeueReusableCell(withReuseIdentifier: "PostLikeViewCell", for: indexPath) as! PostLikeViewCell
        
        if(indexPath.row == self.likeStructs.count - 1) {
            if self.likeStructs.count < totalLike {
                self.refreshLikeList(pageNo + 1)
            }
        }
        cell.analyticsViewKey = self.analyticsViewRecord.viewKey
        cell.setupData(likeStructs[indexPath.row].likeObj, isFollowingUser: likeStructs[indexPath.row].isFollowingUser)
        cell.delegate = self
        
//        var postCode : String? = nil
//        if let post = self.post {
//            postCode = "\(post.postId)"
//        }
//        cell.initAnalytics(withViewKey: self.analyticsViewRecord.viewKey, impressionKey: AnalyticsManager.sharedManager.recordImpression(Context.getUserProfile().userKey,authorType: self.getAuthoType(),brandCode: nil, impressionRef: commentIdString, impressionType: "Comment", impressionDisplayName: impressionDisplayName, parentRef: postCode,parentType: "Post", positionComponent: "Comment", positionIndex: indexPath.row, positionLocation: "PostComment", referrerRef: nil, referrerType: nil, viewKey: self.analyticsViewRecord.viewKey))
        return cell
    }
    
    
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, sizeForItemAt indexPath: IndexPath) -> CGSize {
        if likeStructs.count == 0 {
            return CGSize(width: self.view.frame.size.width , height: self.collectionView.frame.height)
        }
        let height : CGFloat = 70.0
        return CGSize(width: self.view.frame.size.width , height: height)
        
    }
    
//    func collectionView(_ collectionView: UICollectionView,
//                        layout collectionViewLayout: UICollectionViewLayout,
//                               insetForSectionAt section: Int) -> UIEdgeInsets {
//        return UIEdgeInsets(top: 0.0, left: 0.0, bottom: self.commentActionBarView.frame.size.height, right: 0.0)
//    }
    
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, minimumInteritemSpacingForSectionAt section: Int) -> CGFloat {
        return 0.0
    }
    
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, minimumLineSpacingForSectionAt section: Int) -> CGFloat {
        return 0.0
    }
    
    func collectionView(_ collectionView: UICollectionView,
                        didSelectItemAt indexPath: IndexPath) {
        Log.debug("didSelectItemAtIndexPath: \(indexPath.row)")
        
        guard likeStructs.count > 0 else { return }
        
        if let userKey = likeStructs[indexPath.row].likeObj.userKey {
           
            let user = User()
            user.userKey = userKey
            PushManager.sharedInstance.goToProfile(user, hideTabBar: false)
        }
    }
    
    
    
}

extension PostLikeListViewController: PostLikeCellDelegate {
    func followUserClicked(_ likeObj: PostLike, isCurrentFollowing: Bool) {
        if LoginManager.getLoginState() != .validUser {
            LoginManager.goToLogin()
            return
        }
        if let userKey = likeObj.userKey {
            if isCurrentFollowing {
                let message = String.localize("LB_CA_UNFOLLOW_CONF").replacingOccurrences(of: "{0}", with: likeObj.displayName)
                Alert.alert(self, title: "", message: message, okActionComplete: { () -> Void in
                    FollowService.requestUnfollow(userKey).then { _ -> Void in
                        self.collectionView.reloadData()
                    }.catch { _ -> Void in
                        Log.error("error")
                    }
                }, cancelActionComplete:nil)
            }else {
                FollowService.requestFollow(userKey).then { _ -> Void  in
                    self.collectionView.reloadData()
                }.catch { (_) -> Void in
                    Log.error("error")
                }
    
            }
            
        }
    }
}
