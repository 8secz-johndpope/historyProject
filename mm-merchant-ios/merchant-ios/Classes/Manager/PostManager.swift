//
//  NewsfeedManager.swift
//  merchant-ios
//
//  Created by Tony Fung on 4/5/2016.
//  Copyright © 2016年 WWE & CO. All rights reserved.
//

import Foundation
import PromiseKit
import ObjectMapper
import Kingfisher
import Alamofire


enum FeedType: String {
    case userFeed = "Key_Curator_Feed",
    newsFeed = "Key_News_Feed",
    styleFeed = "Key_Style_Feed",
    merchantFeed = "Key_Merchant_Feed",
    postDetail = "Key_Post_Detail",
    productFeed = "Key_Product_Feed",
    hashTag = "Key_HashTag_Feed"
}



class PostManager : NSObject {
    
    static let NewsFeedLineSpacing : CGFloat =  10.0
    static let hiddenUrls = ["mymm.com", "mymm.cn", "mm.eastasia.cloudapp.azure.com"]
    
    deinit {
        Log.debug("deinit PostManager")
    }
    
    override init() {
        super.init()
    }

    static var postImageCallBack:((_ imageNum: Int,_ post: Post,_ showErro:Bool) -> ())?

    static var createPostSuccess:(() -> ())?
    static var upImageView:UpImageView?
    private static var isNeedSavePost = false
    static var isSkipLoadingNewFeedInHome = false
    var postIdsHidingTag = [Int]() //Current hiding tags for post
    var postIdsExpanded = [Int]()
    var postIdsShowingFullDescriptionText = [Int]()
    private var delayAction: DelayAction?
    var currentPosts : [Post] {
        get{
            var posts : [Post]!
            if let mId = displayingMerchantId {
                posts = PostStorageManager.sharedManager.merchantPosts[mId] ?? []
            } else if let sId = displayingSkuId {
                posts = PostStorageManager.sharedManager.productPosts[sId] ?? []
            } else  {
                posts = PostStorageManager.sharedManager.userPosts[displayingObjectKey] ?? []
            }
            let active = posts.filter({ (post) -> Bool in
                return post.statusId == Constants.StatusID.active.rawValue
            })
            return active
        }
        
        //This setter supporting NewsFeedDetail page
        set {
            if let mId = displayingMerchantId {
                PostStorageManager.sharedManager.merchantPosts[mId] = newValue
            } else if let sId = displayingSkuId {
                PostStorageManager.sharedManager.productPosts[sId] = newValue
            } else  {
                PostStorageManager.sharedManager.userPosts[displayingObjectKey] = newValue
            }
        }
    }
    
    var hasLoadMore = false
    
    var currentPageNumber : Int {
        get {
            
            if let mId = displayingMerchantId {
                
                if let posts = PostStorageManager.sharedManager.merchantPosts[mId] {
                    return  posts.count / Constants.Paging.PostOffset
                }
            } else if let sId = displayingSkuId {
                
                if let posts = PostStorageManager.sharedManager.productPosts[sId] {
                    return  posts.count / Constants.Paging.PostOffset
                }
            } else {
                if let posts = PostStorageManager.sharedManager.userPosts[displayingObjectKey] {
                    return  posts.count / Constants.Paging.PostOffset
                }
            }
            
            
            return 0
        }
    }
    
    
    var displayingObjectKey : String = ""
    private var displayingSkuId : Int?
    private var displayingMerchantId : Int?
    private weak var displayingViewController : UIViewController? //Prevent memory leak
    private weak var displayingCollectionView : UICollectionView?//Prevent memory leak
    
    func registerDisplayingCollectionView(_ collectionView: UICollectionView) {
        displayingCollectionView = collectionView
        displayingCollectionView?.register(MyFeedCollectionViewCell.self, forCellWithReuseIdentifier: PostItemCollectionViewCellIdentifier)
        displayingCollectionView?.register(SimpleFeedCollectionViewCell.self, forCellWithReuseIdentifier: SimpleFeedCollectionViewCell.CellIdentifier)
        displayingCollectionView?.register(NewsFeedDetailCell.self, forCellWithReuseIdentifier: NewsFeedDetailCell.CellIdentifier)
    }
    
    convenience init(postFeedTyle: FeedType, authorKey: String = "", postId: String = "", merchantId: Int? = nil, skuId: Int? = nil, collectionView: UICollectionView, viewController: UIViewController){
        self.init()
        self.hookPostManager(postFeedType: postFeedTyle, authorKey: authorKey, postId: postId, merchantId: merchantId, skuId: skuId, collectionView: collectionView, viewController: viewController)
    }
    
    private func hookPostManager(postFeedType feedType: FeedType, authorKey : String = "", postId: String = "",  merchantId: Int? = nil, skuId: Int? = nil, collectionView: UICollectionView, viewController : UIViewController){
        
        switch feedType {
        case .userFeed:
            displayingObjectKey = authorKey
            displayingMerchantId = nil
            displayingSkuId = nil
            break
        case .merchantFeed:
            displayingObjectKey = ""
            displayingMerchantId = merchantId
            displayingSkuId = nil
            break
            
        case .styleFeed, .newsFeed:
            displayingObjectKey = feedType.rawValue
            displayingMerchantId = nil
            displayingSkuId = nil
            break
        case .hashTag:
            
            displayingObjectKey = feedType.rawValue + postId
            displayingMerchantId = nil
            displayingSkuId = nil
            break

        case .postDetail:
            displayingObjectKey = feedType.rawValue + postId
            displayingMerchantId = nil
            displayingSkuId = nil
            break
            
        case .productFeed:
            displayingObjectKey = ""
            displayingMerchantId = nil
            displayingSkuId = skuId
            break
            
        }
        displayingViewController = viewController
        displayingCollectionView = collectionView
        
        PostStorageManager.sharedManager.loadLocalPostsFromDisk()
        
        if PostStorageManager.sharedManager.userPosts[displayingObjectKey] == nil {
            PostStorageManager.sharedManager.userPosts[displayingObjectKey] = []
        }
        
//        self.mixCommentAndPost()
        displayingCollectionView?.register(MyFeedCollectionViewCell.self, forCellWithReuseIdentifier: PostItemCollectionViewCellIdentifier)
        displayingCollectionView?.register(SimpleFeedCollectionViewCell.self, forCellWithReuseIdentifier: SimpleFeedCollectionViewCell.CellIdentifier)
        displayingCollectionView?.register(NewsFeedDetailCell.self, forCellWithReuseIdentifier: NewsFeedDetailCell.CellIdentifier)
        displayingCollectionView?.register(LoadingFooterView.self, forSupplementaryViewOfKind: UICollectionElementKindSectionFooter, withReuseIdentifier: "LoadingFooterView")
        
        
        // displayingCollectionView?.reloadData()//Remove to fix bug crash when change between home and profile quickly
    }
    
    static func getLocalCommentByPostId(_ postId: Int?) -> [PostCommentList]? {
        if let myPostId = postId {
            return PostStorageManager.sharedManager.postCommentLists[myPostId]
        } else {
            return nil
        }
        
    }
    func mixCommentAndPost() {
        if let newsfeeds = PostStorageManager.sharedManager.userPosts[displayingObjectKey] {
            for newsfeed in newsfeeds {
                if let localComments = PostStorageManager.sharedManager.postCommentLists[newsfeed.postId] {
                    if let newPostCommentLists = newsfeed.postCommentLists  {
                        for comment in localComments {
                            let comments =  newPostCommentLists.filter({$0.correlationKey == comment.correlationKey})
                            if comments.isEmpty {
                                newsfeed.postCommentLists?.append(comment)
                            } else {
                                if let newComment = comments.last {
                                    if comment.lastModified >= newComment.lastModified {
                                        newComment.statusId = comment.statusId
                                        newComment.lastModified = comment.lastModified
                                    }
                                }
                            }
                        }
                    } else {
                        newsfeed.postCommentLists = localComments
                    }
                }
             newsfeed.postCommentLists = newsfeed.postCommentLists?.sorted{$0.lastModified < $1.lastModified}
                
            }
        }
        
    }
    func unhookPostManager(){
        displayingObjectKey = ""
        displayingCollectionView = nil
        displayingViewController = nil
    }
    
    func resetLocalUserPost(userKey: String){
        PostStorageManager.sharedManager.userPosts[userKey] = []
        hasLoadMore = false
    }
    
    func resetLocalMerchantPost(merchantId: Int){
        PostStorageManager.sharedManager.merchantPosts[merchantId] = []
        hasLoadMore = false
    }
    
    static func insertLocalPost(_ userKey: String? = nil, merchantId: Int? = nil, post: Post){
        if let pendingImage = post.pendingUploadImage {
            if post.postImage == "0" || post.postImage == "" {
                KingfisherManager.shared.cache.store(pendingImage, forKey: post.correlationKey)
            }else {
                KingfisherManager.shared.cache.store(pendingImage, forKey: ImageURLFactory.URLSize1000(post.postImage, category: .post).absoluteString)
            }
            
        }
        
        if let userKey = userKey {
            if (PostStorageManager.sharedManager.userPosts[userKey] != nil) {
                PostStorageManager.sharedManager.userPosts[userKey]?.insert(post, at: 0)
            }else{
                PostStorageManager.sharedManager.userPosts[userKey] = [post]
            }
        }else if let merchantId = merchantId{
            if (PostStorageManager.sharedManager.merchantPosts[merchantId] != nil) {
                PostStorageManager.sharedManager.merchantPosts[merchantId]?.insert(post, at: 0)
            }else{
                PostStorageManager.sharedManager.merchantPosts[merchantId] = [post]
            }
        }
        
        //Insert to newsfeed page
        if  PostStorageManager.sharedManager.userPosts[FeedType.newsFeed.rawValue] != nil {
             PostStorageManager.sharedManager.userPosts[FeedType.newsFeed.rawValue]?.insert(post, at: 0)
        } else {
             PostStorageManager.sharedManager.userPosts[FeedType.newsFeed.rawValue] = [post]
        }
    }
    
    
//    static func updateLocalPostCommentList(post: Post?){
//        updatePostCommentCount(post)
////        PostStorageManager.sharedManager.saveLocalCommentToDisk()
//    }
    
    static func updatePostCommentCount(_ post: Post, latestOwnComments: [PostCommentList]){
        
        let newlyAddedCount = latestOwnComments.filter({$0.statusId == Constants.StatusID.active.rawValue}).count
        let newlyRemovedCount = latestOwnComments.filter({$0.statusId == Constants.StatusID.deleted.rawValue}).count
        
        post.commentCount = post.commentCount + newlyAddedCount - newlyRemovedCount
        
    }
    
    
    
    static func correlationKeyOfPostLiked(_ post: Post) -> String {
        for (like) in PostStorageManager.sharedManager.userLikes {
            if like.postId == post.postId && like.statusId == Constants.StatusID.active.rawValue{
                return like.correlationKey
            }
        }
        return ""
    }
    
    static func isLikeThisPost(_ post: Post) -> Bool{
        return self.correlationKeyOfPostLiked(post).length > 0
    }
    
    static func updateLikedPost(_ posts: [Post]) {
        var postLikes =  [PostLike]()
        for (like) in PostStorageManager.sharedManager.userLikes {
            let foundIndex = posts.index(where: { (post) -> Bool in
                return post.postId == like.postId
            })
            
            if let _ = foundIndex {
                postLikes.append(like)
            }
        }
        PostStorageManager.sharedManager.userLikes = postLikes
        PostStorageManager.sharedManager.saveUserLikes()
    }
    
    func isUnlikedThisPost(_ post: Post) -> Bool{
        for (like) in PostStorageManager.sharedManager.userLikes {
            if like.postId == post.postId && like.statusId == Constants.StatusID.deleted.rawValue{
                return true
            }
        }
        return false
    }
    
    static func savePostIfNeeded() {
        if isNeedSavePost {
            isNeedSavePost = false
            PostStorageManager.sharedManager.saveLocalPostsToDisk()
        }
    }
    
    private final let PostItemCollectionViewCellIdentifier = "PostItemCollectionViewCell"
    
    func getSimpleNewsFeedCell(_ indexPath: IndexPath) -> UICollectionViewCell{
        if let cell = displayingCollectionView?.dequeueReusableCell(withReuseIdentifier: SimpleFeedCollectionViewCell.CellIdentifier, for: indexPath) as? SimpleFeedCollectionViewCell {
            cell.setNeedsLayout()
            cell.avatarView.imageView.layer.cornerRadius = cell.avatarView.imageView.frame.width / 2
            
            if self.currentPosts.indices.contains(indexPath.row) {
                
                let post = self.currentPosts[indexPath.row]
                let liked = PostManager.isLikeThisPost(post)
                cell.setupDataByNewfeed(post, isLiked: liked)
                cell.delegate = self
            }
            
            return cell
            
        }
        
        return UICollectionViewCell()
    }
    
    func getNewsfeedDetailCell(_ indexPath: IndexPath) -> UICollectionViewCell {
        if let cell = displayingCollectionView?.dequeueReusableCell(withReuseIdentifier: NewsFeedDetailCell.CellIdentifier, for: indexPath) as? NewsFeedDetailCell {
            cell.setNeedsLayout()
            
            cell.avatarView.imageView.layer.cornerRadius = cell.avatarView.imageView.frame.width / 2
            
            if self.currentPosts.indices.contains(indexPath.row) {
                let post = self.currentPosts[indexPath.row]
                
                cell.setupDataByNewfeed(post)
                if post.styles == nil {
                    cell.updateCellStyles(indexPath.row)
                }
                cell.delegate = self
                if self.postIdsHidingTag.contains(post.postId){
                    post.isHideTag = true
                    cell.hideTags()
                }
                else{
                    post.isHideTag = false
                    cell.setupTags(post, animated: false)
                }
            }
            
            return cell
            
        }
        
        return UICollectionViewCell()
    }
    
    func getNewsfeedCell(_ indexPath: IndexPath) -> UICollectionViewCell{
        if let cell = displayingCollectionView?.dequeueReusableCell(withReuseIdentifier: PostItemCollectionViewCellIdentifier, for: indexPath) as? MyFeedCollectionViewCell {
            cell.setNeedsLayout()
            // cell.expandDescriptionButton.tag = indexPath.row
            cell.avatarView.imageView.layer.cornerRadius = cell.avatarView.imageView.frame.width / 2
            
            if self.currentPosts.indices.contains(indexPath.row) {
                
                let post = self.currentPosts[indexPath.row]
                //                post.isExpandDescriptionText = self.postIdsShowingFullDescriptionText.contains(post.postId)
                cell.handleExpand(post)

                let liked = PostManager.isLikeThisPost(post)
                cell.setupDataByNewfeed(post, isLiked: liked)
                cell.feedCollectionViewCellDelegate = self
                if self.postIdsHidingTag.contains(post.postId){
                    post.isHideTag = true
                    cell.hideTags()
                }
                else{
                    post.isHideTag = false
                    cell.setupTags(post, animated: false)
                }
            }
            
            return cell
            
        }
        
        return UICollectionViewCell()
    }
    
    class func fetchUserLikes() -> Promise<[PostLike]> {
        return Promise { fulfill, reject in
            PostManager.refreshUserLikes({ (likelist) in
                fulfill(likelist)
            })
        }
    }
    
    class func refreshUserLikes(_ completion: (([PostLike]) -> Void)? = nil) {
        if LoginManager.getLoginState() != .validUser {
            completion?([])
            return
        }

        PostManager.requestLikedObjects(Context.getUserKey()).then { (likes) -> Void in
            //we do the de dupplication here
            let cachedLikes = PostStorageManager.sharedManager.userLikes
            var remoteLikes = likes
            
            for cachedLike in cachedLikes {
                let foundIndexRemote = remoteLikes.index(where: { (remoteLike) -> Bool in
                    return (remoteLike.correlationKey == cachedLike.correlationKey || remoteLike.postId == cachedLike.postId)
                })
                
                if let i = foundIndexRemote {
                    let remoteLike = remoteLikes[i]
                    if remoteLike.lastModified < cachedLike.lastModified {
                        remoteLikes[i] = cachedLike
                    }
                }else{
                    remoteLikes.append(cachedLike)
                }
            }
            
            PostStorageManager.sharedManager.userLikes = remoteLikes
            PostStorageManager.sharedManager.saveUserLikes()
            
            
            completion?(remoteLikes)
        }.catch{ (error) in
            completion?([PostLike]())
        }
    }
    
    class func getPostLikedObjects(_ pageno: Int, completion: (([PostLike]) -> Void)? = nil) {
        if LoginManager.getLoginState() != .validUser {
            completion?([])
            return
        }
        
        PostManager.requestLikedObjectsWithPaging(Context.getUserKey(), pageno: pageno).then { (likes) -> Void in
            
            PostManager.deduplicateLikedPosts(likes)
            
            completion?(PostStorageManager.sharedManager.userLikes)
        }.catch { (error) in
            completion?([PostLike]())
        }
    }
    
    private class func deduplicateLikedPosts(_ likes: [PostLike]) {
        //we do the de dupplication here
        let cachedLikes = PostStorageManager.sharedManager.userLikes
        var remoteLikes = likes
        
        for cachedLike in cachedLikes {
            let foundIndexRemote = remoteLikes.index(where: { (remoteLike) -> Bool in
                return (remoteLike.correlationKey == cachedLike.correlationKey || remoteLike.postId == cachedLike.postId)
            })
            
            if let i = foundIndexRemote {
                let remoteLike = remoteLikes[i]
                if remoteLike.lastModified < cachedLike.lastModified {
                    remoteLikes[i] = cachedLike
                }
            }else{
                remoteLikes.append(cachedLike)
            }
        }
        
        PostStorageManager.sharedManager.userLikes = remoteLikes
        PostStorageManager.sharedManager.saveUserLikes()
    }

    func appendToCurrentPosts(_ feedType: FeedType, userKey: String = "", merchantId: Int? = nil, skuId: Int? = nil, remotePosts: [Post]){
        
        if remotePosts.isEmpty {
            return
        }
        
        var workingPosts : [Post] = []
        
        if feedType == .merchantFeed, let mId = merchantId {
            workingPosts = PostStorageManager.sharedManager.merchantPosts[mId] ?? []
        }else if feedType == .userFeed{
            workingPosts = PostStorageManager.sharedManager.userPosts[userKey] ?? []
        }else if feedType == .postDetail {
            workingPosts = PostStorageManager.sharedManager.userPosts[displayingObjectKey] ?? []
        }else if feedType == .productFeed, let sId = skuId {
            workingPosts = PostStorageManager.sharedManager.productPosts[sId] ?? []
        } else {
            workingPosts = PostStorageManager.sharedManager.userPosts[feedType.rawValue] ?? []
        }
        
        //具体的去重逻辑
        for post in remotePosts {
            if (!workingPosts.contains(post)) {
                workingPosts.append(post)
            }
        }
        
        //对于以上逻辑，后面需要全部重写，丢弃PostManager类，最后排序只是临时处理顺序
        workingPosts.sort(by: {$0.lastModified > $1.lastModified})
        
        if feedType == .merchantFeed, let mId = merchantId {
            PostStorageManager.sharedManager.merchantPosts[mId] = workingPosts
        }else if feedType == .userFeed{
            PostStorageManager.sharedManager.userPosts[displayingObjectKey] = workingPosts
        }else if feedType == .postDetail {
            PostStorageManager.sharedManager.userPosts[displayingObjectKey] = workingPosts
        }else if feedType == .productFeed, let sId = skuId {
            PostStorageManager.sharedManager.productPosts[sId] = workingPosts
        } else {
            PostStorageManager.sharedManager.userPosts[feedType.rawValue] = workingPosts
        }
    }
    
    func deduplicateCurrentPosts(_ feedType: FeedType, userKey: String = "", merchantId: Int? = nil, skuId: Int? = nil, remotePosts: [Post]){
        
        var workingPosts : [Post] = []
        
        if feedType == .merchantFeed, let mId = merchantId {
            workingPosts = PostStorageManager.sharedManager.merchantPosts[mId] ?? []
        }else if feedType == .userFeed{
            workingPosts = PostStorageManager.sharedManager.userPosts[userKey] ?? []
        }else if feedType == .postDetail {
            workingPosts = PostStorageManager.sharedManager.userPosts[displayingObjectKey] ?? []
        }else if feedType == .productFeed, let sId = skuId {
            workingPosts = PostStorageManager.sharedManager.productPosts[sId] ?? []
        } else {
            workingPosts = PostStorageManager.sharedManager.userPosts[feedType.rawValue] ?? []
        }
        
        
        //        let correlationPosts : [String: Post] = [:]
        //
        //we took part of the cached list to buffer
        var lastBufferIndex : Int?
        var remoteLatestPost : Post?
        if remotePosts.count > 0 {
            for index in (0...(remotePosts.count - 1)).reversed() {
                let remoteReferencePost = remotePosts[index]
                lastBufferIndex = workingPosts.index(where: { (localPost) -> Bool in
                    return localPost.correlationKey == remoteReferencePost.correlationKey
                })
                if lastBufferIndex != nil {
                    break
                }
            }
            remoteLatestPost = remotePosts[0]
        }
        else if workingPosts.count > 0{
            lastBufferIndex = workingPosts.count - 1 //case first posts is repost post
        }
        
        let bufferPosts = Array(workingPosts.prefix((lastBufferIndex ?? -1) + 1))
        
        //we now set the remote post as the core working list
        workingPosts = remotePosts
        
        var pendingInserts : [Post] = []
        //we loop the cache array to see is it also in the remote array
        for cachePost in bufferPosts {
            let foundIndexRemote = workingPosts.index(where: { (p) -> Bool in
                return p.correlationKey == cachePost.correlationKey || (cachePost.postId == p.postId)
            })
            
            if let i = foundIndexRemote {
                let remotePost = workingPosts[i]
                if remotePost.lastModified < cachePost.lastModified || remotePost.postImage == "0" { //even it is equal we take locally, but how do we update the post with like count changed...?
                    workingPosts[i] = cachePost
                    remotePost.statusId = cachePost.statusId //follow latest status in local
                }
                
            }else if (cachePost.user?.userKey == Context.getUserKey()){
                if let latestPost = remoteLatestPost{
                    if(cachePost.lastModified > latestPost.lastModified) {
                        pendingInserts.append(cachePost)
                    }
                } else {
                    pendingInserts.append(cachePost)
                }
            }
        }
        workingPosts = pendingInserts + workingPosts
        
        //对于以上逻辑，后面需要全部重写，丢弃PostManager类，最后排序只是临时处理顺序
        workingPosts.sort(by: {$0.lastModified > $1.lastModified})
        
        if feedType == .merchantFeed, let mId = merchantId {
            PostStorageManager.sharedManager.merchantPosts[mId] = workingPosts
        }else if feedType == .userFeed{
            PostStorageManager.sharedManager.userPosts[displayingObjectKey] = workingPosts
        }else if feedType == .postDetail {
            PostStorageManager.sharedManager.userPosts[displayingObjectKey] = workingPosts
        }else if feedType == .productFeed, let sId = skuId {
            PostStorageManager.sharedManager.productPosts[sId] = workingPosts
        } else {
            PostStorageManager.sharedManager.userPosts[feedType.rawValue] = workingPosts
        }
        
    }
    
    func getPostActivitiesByPostIds(_ postIds: String = "") -> Promise<Any> {
        return Promise{ fulfill, reject in
            
            guard postIds.length > 0 else {
                // return nothing if postIds not set
                fulfill("OK")
                return
            }
            
            let callback : (DataResponse<Any>) -> Void = { [weak self] (response) in
                
                if let strongSelf = self {
                    if response.response?.statusCode == 200 {
                        DispatchQueue.global(qos: .default).async(execute: {() -> Void in
                            let postActivitys =  Mapper<PostActivity>().mapArray(JSONObject: response.result.value) ?? []
                            let posts = strongSelf.currentPosts
                            for post in posts {
                                
                                
                                if let itemIndex = postActivitys.index(where: { $0.postId == post.postId }) {
                                    let postActivity = postActivitys[itemIndex]
                                    post.likeCount = postActivity.likeCount
                                    post.likeList = postActivity.likeList
                                    let deletedComment = postActivity.commentList.filter({$0.statusId == Constants.StatusID.deleted.rawValue}).count
                                    post.commentCount = postActivity.commentCount - deletedComment
                                    if postActivity.commentList.count > 0 {
                                        postActivity.commentList.sort(by: {$0.lastModified < $1.lastModified})
                                    }
                                    post.postCommentLists = postActivity.commentList
                                    
                                }
  
                                //fetch the comment list i made for this post
                                if let localComments = PostStorageManager.sharedManager.postCommentLists[post.postId] {
                                    
                                    post.postCommentLists?.sort(by: {$0.lastModified < $1.lastModified})
                                    let latestRemoteCommentDate = post.postCommentLists?.last?.lastModified ?? Date()
                                    
                                    let commentsLaterThanServer = localComments.filter({ localComment -> Bool in
                                        // local comments that not contain in server and later than remote latest comment
                                        return localComment.lastModified > latestRemoteCommentDate && !(post.postCommentLists?.contains(where: {$0.correlationKey == localComment.correlationKey }) ?? false)
                                    })
                                    
                                    
                                    if let remoteComments = post.postCommentLists  {
                                        for localComment in localComments {
                                            let myRemoteComments =  remoteComments.filter({$0.correlationKey == localComment.correlationKey})
                                            if myRemoteComments.isEmpty {
                                                post.postCommentLists?.append(localComment)
                                            } else {
                                                if let newComment = myRemoteComments.last {
                                                    if localComment.lastModified >= newComment.lastModified {
                                                        newComment.lastModified = localComment.lastModified
                                                    }
                                                    newComment.statusId = localComment.statusId
                                                }
                                            }
                                        }
                                        
                                    } else {
                                        post.postCommentLists = localComments
                                    }
                                    post.postCommentLists?.sort(by: {$0.lastModified < $1.lastModified})
                                    PostManager.updatePostCommentCount(post, latestOwnComments: commentsLaterThanServer)
                                }
                            }
                            DispatchQueue.main.async {
                                fulfill("OK")
                            }
                        })

                    } else {
                        var statusCode = 0
                        if let code = response.response?.statusCode {
                            statusCode = code
                        }
                        let error = NSError(domain: "", code: statusCode, userInfo: nil)
                        reject(error)
                    }
                } else {
                    var statusCode = 0
                    if let code = response.response?.statusCode {
                        statusCode = code
                    }
                    let error = NSError(domain: "", code: statusCode, userInfo: nil)
                    reject(error)
                }
            }
            _ = NewsFeedService.listNewsFeedByPostIds(postIds, completion: callback)
        }
    }
    
    
    func fetchNewsFeed(_ feedType: FeedType, userKey: String = "", merchantId: Int? = nil, postId: Int? = nil, skuId: Int? = nil, hashTag: String? = nil, pageno: Int) -> Promise<Any> {
        return Promise{ fulfill, reject in
            

            let callback : (DataResponse<Any>) -> Void = { [weak self] (response) in
                
                
                if let strongSelf = self {
                    if response.response?.statusCode == 200 {
                        
                        var postIds = ""
                        
                        DispatchQueue.global(qos: .default).async(execute: {() -> Void in
                            if let newsFeedListResponse :  NewsFeedListResponse = Mapper<NewsFeedListResponse>().map(JSONObject: response.result.value) {
                                
                                
                                if let newsfeeds = newsFeedListResponse.pageData as [Post]? {
                                    
                                    if pageno == 1 {
                                        strongSelf.deduplicateCurrentPosts(feedType, userKey: userKey, merchantId: merchantId, skuId: skuId, remotePosts: newsfeeds)
                                    }
                                    for newsfeed in newsfeeds {
                                        
                                        if pageno > 1 {
                                            if let mId = merchantId {
                                                PostStorageManager.sharedManager.merchantPosts[mId]?.append(newsfeed)
                                            }else if feedType == .userFeed{
                                                PostStorageManager.sharedManager.userPosts[userKey]?.append(newsfeed)
                                            }else if feedType == .postDetail{
                                                PostStorageManager.sharedManager.userPosts[feedType.rawValue + (postId?.toString())!]?.append(newsfeed)
                                            }else if let sId = skuId {
                                                PostStorageManager.sharedManager.productPosts[sId]?.append(newsfeed)
                                            } else {
                                                PostStorageManager.sharedManager.userPosts[feedType.rawValue]?.append(newsfeed)
                                            }
                                        }
                                        
                                        postIds = postIds + String(newsfeed.postId) + ","
                                    }
                                    
                                    if feedType == .styleFeed || feedType == .newsFeed || (feedType == .userFeed && userKey == Context.getUserKey() || (feedType == .merchantFeed && merchantId == Context.getUserProfile().merchantId)) {
                                        PostStorageManager.sharedManager.saveLocalPostsToDisk()
                                    }
                                    
                                    strongSelf.hasLoadMore = newsFeedListResponse.hitsTotal > newsFeedListResponse.pageSize * newsFeedListResponse.pageCurrent
                                    
                                } else {
                                    strongSelf.hasLoadMore = false
                                }
                            }
                            postIds = String(postIds.dropLast())
                            DispatchQueue.main.async {
                                
                                fulfill(postIds)
                            }
                        })
                        
                    } else {
                        var statusCode = 0
                        if let code = response.response?.statusCode {
                            statusCode = code
                        }
                        
                        let error = NSError(domain: "", code: statusCode, userInfo: nil)
                        reject(error)
                    }
                } else {
                    reject(response.result.error ?? NSError(domain: "Network Related", code: 0, userInfo: nil))
                }
                
            }
            
            
            switch feedType {
                
            case .userFeed:
                NewsFeedService.listNewsFeedByUser(userKey, pageno: pageno, completion: callback)
                break
                
            case .merchantFeed:
                if let mId = merchantId {
                    NewsFeedService.listNewsFeedByMerchant(mId, pageno: pageno, completion: callback)
                }
                break
                
            case .productFeed:
                if let sId = skuId {
                    NewsFeedService.listNewsFeedByProduct(sId, pageno: pageno, completion: callback)
                }
                break
                
            case .newsFeed:
                let myUserKey = LoginManager.getLoginState() == .validUser ? Context.getUserKey() : "0"
                
                let userPromise = FollowService.listFollowingUserKeys(useCacheOnlyIfAny: true).asVoid()
                let merchantPromise = FollowService.listFollowingMerchantIds(useCacheOnlyIfAny: true).asVoid()
                let promises : [Promise<Void>] = [userPromise, merchantPromise]
                
                when(fulfilled: promises).then { _ -> Void in
                    var followingUserKeys = Array(FollowService.instance.followingNormalUserKeys.prefix(Constants.NewsFeed.UserKeyLimit))
                    if myUserKey != "0" { followingUserKeys.append(myUserKey) }
                    NewsFeedService.listNewsFeedForUser(myUserKey, pageno: pageno, followingUserKeys: followingUserKeys, completion: callback)
                    }.catch { (error) in
                        print(error)
                        reject(error)
                    }
                
                
                break
                
            case .styleFeed:
                NewsFeedService.listNewsFeedByCurators(pageno, completion: callback)
                break
                
            case .hashTag:
                if let hashTag = hashTag {
                    NewsFeedService.listNewsFeedByHashTag(hashTag, pageno: pageno, completion: callback)
                }
                break
                
            case .postDetail:
                if let pid = postId {
                    NewsFeedService.listNewsFeedByPostId(pid, completion: callback)
                }
                break
            }
            
            
        }
        
    }
    
    
    static func createNewPost(_ post: Post) -> Promise<Any> {
        let thisUser = Context.getUserProfile()
        
        return Promise{ fulfill, reject in
            saveNewFeedPost(post).then { postId -> Void in
                
                post.postId = Int(postId) ?? 0
                post.user = thisUser
                
                fulfill("OK")
                if let createPostSuccess = self.createPostSuccess{
                    createPostSuccess()
                }
                
                }.catch { error -> Void in
                    reject(error)
            }
        }
    }
    
    
    
    
    //MARK: - Private static API call function
    
    func deleteNewsFeed(_ postId: String) -> Promise<Any> {
        
        return Promise{ fulfill, reject in
            NewsFeedService.deleteNewsFeed(postId) { (response) in
                if response.response?.statusCode == 200 {
                    fulfill("OK")
                    
                }else{
                    
                    var statusCode = 0
                    if let code = response.response?.statusCode {
                        statusCode = code
                    }
                    
                    let error = NSError(domain: "", code: statusCode, userInfo: nil)
                    reject(error)
                }
            }
        }
        
    }
    
    
    private static func requestLikedObjects(_ userKey: String) -> Promise<[PostLike]> {
        
        return Promise{ fulfill, reject in
            NewsFeedService.getLikedObjectsByUser(1, completionInBackground: { (response) in
                if response.response?.statusCode == 200 {
                    if let responseValue = response.result.value as? [String: Any],
                        let jsonArray = responseValue["LikeList"] as? [[String: Any]] {
                        let likedObjects = Mapper<PostLike>().mapArray(JSONArray: jsonArray)
                        fulfill(likedObjects)
                    } else {
                        reject(NSError(domain: "", code: 0, userInfo: nil))
                    }
                }else {
                    reject(NSError(domain: "", code: 0, userInfo: nil))
                }
            })
        }
        
    }
    
    private static func requestLikedObjectsWithPaging(_ userKey: String, pageno: Int) -> Promise<[PostLike]> {
        
        return Promise{ fulfill, reject in
            NewsFeedService.getLikedObjectsByUser(pageno, completionInBackground: { (response) in
                if response.response?.statusCode == 200 {
                    if let responseValue = response.result.value as? [String: Any],
                        let jsonArray = responseValue["LikeList"] as? [[String: Any]] {
                        let likedObjects = Mapper<PostLike>().mapArray(JSONArray: jsonArray)
                        fulfill(likedObjects)
                    } else {
                        reject(NSError(domain: "", code: 0, userInfo: nil))
                    }
                }else {
                    reject(NSError(domain: "", code: 0, userInfo: nil))
                }
            })
        }
        
    }

    
    private static func viewUser(_ userKey: String) -> Promise<User> {
        return Promise { fulfill, reject in
            
            UserService.viewWithUserKey(userKey, completion: { (response) in
                if response.result.isSuccess {
                    if response.response?.statusCode == 200 {
                        
                        let user = Mapper<User>().map(JSONObject: response.result.value)!
                        fulfill(user)
                        
                    }else{
                        var statusCode = 0
                        if let code = response.response?.statusCode {
                            statusCode = code
                        }
                        let error = NSError(domain: "", code: statusCode, userInfo: nil)
                        reject(error)
                    }
                }else{
                    reject(response.result.error!)
                }
            })
            
        }
    }
    
    private static func saveNewFeedPost(_ postData : Post) -> Promise<String> {
        return Promise{ fulfill, reject in
            
            NewsFeedService.saveNewFeed(postData, completion: { (response) in
                if response.result.isSuccess{
                    if response.response?.statusCode == 200 {
                        
                        if let result = Mapper<NewsFeedPostResult>().map(JSONObject: response.result.value) {
                            
                            Log.debug("result.postId : \(result.postId)")
                            fulfill(result.postId)
                        }
                        
                    } else {
                        var statusCode = 0
                        if let code = response.response?.statusCode {
                            statusCode = code
                        }
                        
                        var userInfo : [String: Any] = [:]
                        
                        if let apiResponse = Mapper<ApiResponse>().map(JSONObject: response.result.value) {
                            userInfo[NSLocalizedDescriptionKey] = String.localize(apiResponse.appCode)
                        }
                        
                        let error = NSError(domain: "", code: statusCode, userInfo: userInfo)
                        reject(error)
                    }
                } else {
                    if let error = response.result.error {
                        reject(error)
                    } else {
                        reject(NSError(domain: "Unidentified", code: 9999, userInfo: nil))
                    }
                }
                
            })
        }
    }
    
    private static func uploadPostImage(_ image: UIImage?, postId: String) -> Promise<String> {
        
        return Promise{ fulfill, reject in
            if let image = image, image.size.width > 0 {
                
                NewsFeedService.uploadPhoto(postId, image: image, success: {  (response) in
                    
                    if response.result.isSuccess {
                        if response.response?.statusCode == 200 {
                            Log.debug("response.response : \(String(describing: response.response))")
                            if let responseDict = response.result.value as? [String: Any], let imageKey = responseDict["PostImage"] as? String {
                                fulfill(imageKey)
                            }else{
                                reject(NSError(domain: "parsing error", code: 0, userInfo: nil))
                            }
                        }else {
                            
                            let apiResponse = Mapper<ApiResponse>().map(JSONObject: response.result.value)
                            
                            var statusCode = 0
                            if let code = response.response?.statusCode {
                                statusCode = code
                            }
                            let error = NSError(domain: "", code: statusCode, userInfo: [NSLocalizedDescriptionKey: apiResponse?.appCode ?? ""])
                            reject(error)
                            
                        }
                    }else if let err = response.result.error {
                        reject(err)
                    }
                    
                    }, fail: {  encodingError in
                        Log.debug("encodingError")
                        reject(encodingError)
                })
                
            }else{
                fulfill("OK")
            }
            
        }
    }
    
    static func uploadPostImageWithRetry(post: Post, retry: Int,imageNum: Int? = nil,tagImages : [Images]? = nil,postCallback: ((_ post:Post)->())? = nil) {
        self.upImageView?.upImageViewCallBack = {
            uploadPostImageWithRetry(post: post, retry: retry,imageNum: imageNum, tagImages:tagImages,postCallback:postCallback)
        }
        self.upImageView?.cancelUpImageViewCallBack = {
            
            
            let optionMenu = UIAlertController(title: nil, message: nil, preferredStyle: .actionSheet)
            let deleteAction = UIAlertAction(title: String.localize("取消发帖"), style: .default, handler: {
                (alert: UIAlertAction!) ->  Void in
                CacheManager.sharedManager.postDescription = nil
                if let postImageCallBack = self.postImageCallBack{
                    postImageCallBack(0,post,false)
                }
            })
            let cancelAction = UIAlertAction(title:String.localize("LB_CANCEL"), style: .cancel, handler: {
                (alert: UIAlertAction!) -> Void in
                
            })
            optionMenu.addAction(deleteAction)
            optionMenu.addAction(cancelAction)
            PushManager.sharedInstance.getTopViewController().present(optionMenu, animated: true, completion: nil)
            optionMenu.view.tintColor = UIColor.alertTintColor()
        }
        if let imageNum = imageNum{
            if let postImageCallBack = self.postImageCallBack{
                postImageCallBack(imageNum,post,false)
            }
            if imageNum <= 0 {
                if let postCallback = postCallback  {
                    postCallback(post)
                }
                return
            }
        }
        if let images = tagImages{
            
            let imageMapper = images[0]
            
            
            let image = imageMapper.upImage!
            
            self.upImageView?.image = image
            
            NewsFeedService.uploadPhoto("", image: ImageHelper.getServerAcceptedImageSize(image), success: {  (response) in
                
                if response.result.isSuccess {
                    if response.response?.statusCode == 200 {
                       if let responseDict = response.result.value as? [String: Any], let imageKey = responseDict["PostImage"] as? String {
                            Log.debug("imageKey : \(imageKey)")
                            
                            // add imageKey back by post id
                            if post.images != nil{
                                let images = post.images![retry]
                                images.image = imageKey
                            }
                            if tagImages != nil{
                                if retry == 0 {
                                    post.postImage = imageKey
                                    post.statusId = Constants.StatusID.active.rawValue
                                    post.lastModified = NSDate() as Date
                                    post.lastCreated = NSDate() as Date
                                }
                                var nextImages = tagImages
                                nextImages?.remove(at: 0)
                                uploadPostImageWithRetry(post: post, retry: retry + 1,imageNum: imageNum! - 1, tagImages:nextImages,postCallback:postCallback)

                            }
                            
                            
                        }else{
                            Log.debug("parsing error")
                            // retry post image
                            if let postImageCallBack = self.postImageCallBack{
                                postImageCallBack(imageNum!,post,true)
                            }
                        }
                    }else {

                        let apiResponse = Mapper<ApiResponse>().map(JSONObject: response.result.value)
                        
                        var statusCode = 0
                        if let code = response.response?.statusCode {
                            statusCode = code
                        }
                        let error = NSError(domain: "", code: statusCode, userInfo: [NSLocalizedDescriptionKey: apiResponse?.appCode ?? ""])
                        Log.debug("error : \(error)")
                        
                        // retry post image
                        if let postImageCallBack = self.postImageCallBack{
                            postImageCallBack(imageNum!,post,true)
                        }
                    }
                }else if let err = response.result.error {
                    Log.debug("err : \(err)")
                    
                    // retry post image
                    if let postImageCallBack = self.postImageCallBack{
                        postImageCallBack(imageNum!,post,true)
                    }
                }
                
            }, fail: {  encodingError in
                Log.debug("encodingError : \(encodingError)")
                
                // retry post image
                if let postImageCallBack = self.postImageCallBack{
                    postImageCallBack(imageNum!,post,true)
                }
            })
            
        }
        
    }
    
    
    static func changeLikeStatusNewsfeedPost(_ post: Post, likeStatus: Constants.StatusID, correlationKey: String) -> Promise<Any> {
        
        return Promise{ fulfill, reject in
            
            let promise: Promise<String> = {
                if likeStatus == Constants.StatusID.active {
                    return likePostCall(post, correlationKey: correlationKey)
                } else{
                    return unlikePostCall(post, correlationKey: correlationKey)
                }
            } ()
                
            promise.then { (likedCorrelationKey) -> Void in
                fulfill(likedCorrelationKey)
            }.catch { error in
                reject(error)
            }
        }
    }
    
    private static func likePostCall(_ post: Post, correlationKey: String) -> Promise<String> {
        
        return Promise{ fulfill, reject in
            NewsFeedService.likeNewsFeed(post.postId, correlationKey: correlationKey, completion: { (response) in
                if response.result.isSuccess && response.response?.statusCode == 200{
                    if let result = response.result.value as? [String: Any], (result["Success"] as? Int) == 1{
                        Log.debug("likePostCall OK" + correlationKey)
                        fulfill(correlationKey)
                    } else {
                        reject(NSError(domain: "", code: response.response?.statusCode ?? 0, userInfo: ["Error" : (String.localize("LB_ERROR"))]))
                    }
                    
                } else {
                    PostManager.handleError(response,reject: reject)
                }
                
            })
        }
    }
    
    //PostManager.handleError(response, reject: reject)
    class func handleError(_ response : DataResponse<Any>, reject : ((Error) -> Void)? = nil) {
        if let resp = Mapper<ApiResponse>().map(JSONObject: response.result.value){
            if let appCode = resp.appCode {
                
                if let reject = reject {
                    reject(NSError(domain: "", code: response.response?.statusCode ?? 0, userInfo: ["Error" : (String.localize(appCode))]))
                    return
                }
            }
        }
        if let reject = reject {
            reject(NSError(domain: "", code: response.response?.statusCode ?? 0, userInfo: ["Error" : (String.localize("LB_ERROR"))]))
        }
    }
    
    private static func unlikePostCall(_ post: Post, correlationKey: String) -> Promise<String> {
        let key = correlationKey
        return Promise{ fulfill, reject in
            let currentUserKey = Context.getUserKey()
            PostManager.requestLikedObjects(currentUserKey).then { postLikes -> Void in
                
                var postFound = false
                for postLike in postLikes{
                    if postLike.postId == post.postId{
                        if let postLikeId = postLike.postLikeId {
                            postFound = true
                            NewsFeedService.unlikeNewsFeed(postLikeId, completion: { (response) in
                                if response.result.isSuccess{
                                    fulfill(key)
                                } else {
                                    reject(response.result.error!)
                                    
                                }
                            })
                        }
                        break
                    }
                }
                
                if !postFound {
                    fulfill(key) // we still fall back if can't find the user
                }
            }.catch { error in
                reject(error)
            }
            
        }
    }
    
    //MARK:-
    
    func repost(_ clickedNewsFeed: Post) {
//        let currentDisplayViewController = self.displayingViewController as? MmViewController
        if isUserAuthenticated() {
            let correlation = Utils.UUID()
            NewsFeedService.repostNewsFeed(clickedNewsFeed.postId, correlationKey: correlation, completion: { (response) in
                if response.result.isSuccess{
                    if response.response?.statusCode == 200 {
                        if let result = Mapper<NewsFeedPostResult>().map(JSONObject: response.result.value) {
                            let newPost = clickedNewsFeed.clone()
                            newPost.correlationKey = correlation
                            Log.debug("result.postId : \(result.postId)")
                            newPost.postId = Int(result.postId) ?? 0
                            newPost.lastCreated = Date()
                            newPost.lastModified = Date()
                            newPost.user = Context.getUserProfile()
                            newPost.userSource = clickedNewsFeed.user
                            newPost.likeCount = 0
                            newPost.likeList = []
                            newPost.commentCount = 0
                            newPost.postCommentLists = []
                            newPost.isMerchantIdentity = .fromAmbassador
                            newPost.merchant = nil
                            newPost.merchantId = 0
                            
                            //Newest post will be inserted to first index
                            PostManager.insertLocalPost(Context.getUserKey(), post: newPost)
                            if let controller = self.displayingViewController as? MmViewController {
                                controller.showSuccessPopupWithText(String.localize("MSG_CA_SHARE_POST_SUC"))
                            }
                            self.displayingCollectionView?.reloadData()
                            
                            var shouldScrollToTop = false
                            
                            if self.displayingViewController is NewsFeedViewController {
                                
                                if let newsFeedVC = self.displayingViewController as? NewsFeedViewController, let currentVC = newsFeedVC.viewControllerAtIndex(newsFeedVC.currentPageIndex) {
                                    if currentVC is SubHomeViewController {
                                        shouldScrollToTop = true
                                    }
                                }
                            } else if self.displayingViewController is ProfileViewController {
                                shouldScrollToTop = true
                            }
                            
                            if shouldScrollToTop {
                                if let sectionCount = self.displayingCollectionView?.numberOfSections, sectionCount > 0 {
                                    //Currently, Section newsfeed is always the last section
                                    let indexPath = IndexPath(item: 0, section: sectionCount - 1)
                                    self.displayingCollectionView?.scrollToItem(at: indexPath, at: UICollectionViewScrollPosition.top, animated: true)
                                }
                            }
                            
                            if !(self.displayingViewController is PostDetailViewController) {
                                //move to profile user after repost a post
                                self.jumpToProfilePage()
                            }
                        }
                    } else {
                        //Handle Error
                        Log.error("error")
                    }
                } else {
                    //Handle error
                    Log.error("error")
                }
            })
        }
    }
    
    func jumpToProfilePage(){
        guard self.displayingViewController is NewsFeedViewController || self.displayingViewController is ProfileViewController else {
            if let navController = self.displayingViewController?.tabBarController?.viewControllers?.last as? UINavigationController {
                navController.popToRootViewController(animated: true)
            }
            return
        }
        
        
        
    }
    
    // Height Calculation
    func getHeightAtIndex(_ indexPath: IndexPath) -> CGFloat {
        
        if self.currentPosts.count > indexPath.row {
            let post = self.currentPosts[indexPath.row]
            var height :CGFloat = 0.0
            let heightHeaderView = ViewDefaultHeight.HeightHeaderView
            let heightPhoto = ViewDefaultHeight.HeightpostImageView
            let heightActionView = ViewDefaultHeight.HeightActionView
            post.isExpand = self.postIdsExpanded.contains(post.postId)
            
            //SYNC likeCount before getting height of cell
            let isLikeThisPost = PostManager.isLikeThisPost(post)
            if isLikeThisPost {
                let index = post.likeList.index(where: { (likedUser) -> Bool in
                    return likedUser.userKey == Context.getUserKey() //we have the item in like list
                })
                if index == nil {
                    post.likeList.append(Context.getUserProfile())
                    post.likeCount += 1
                }
            } else {
                for user in post.likeList {
                    if user.userKey == Context.getUserKey() {
                        post.likeList.remove(user)
                        post.likeCount = max(post.likeCount - 1, 0)
                        break
                    }
                }
            }
            
            var postDescription = ""
            if post.postText.isEmpty{
                postDescription = BasePostCollectionViewCell.getTextByRemovingAppUrls(post.postText)
            }else{
                postDescription = post.postText
            }
            
            let descriptionHeight =  MyFeedCollectionViewCell.getHeightDescription(postDescription , isExpandDescriptionText: post.isExpand)
            let descriptionViewHeight = (descriptionHeight + (descriptionHeight > 0 ? Margin.TopBottomOfDescription : 0))
            
            var heightCommentView = CGFloat(0)
            let paddingBottomCommentView: CGFloat = 2.0
            heightCommentView += paddingBottomCommentView
            
            height = heightHeaderView + heightPhoto + heightActionView + descriptionViewHeight
            
            if let _ = post.userSource {
                height += ViewDefaultHeight.HeightLabel + Margin.TopBottomOfDescription
            }
            
            return height
        }
        return 0
    }
    
    // Internal calculation of cell height
    
    static func getSuggestionCellHeight(_ post: Post) -> CGFloat {
        if let skus = post.skuList, skus.count > 0 {
            let width = (Constants.ScreenSize.SCREEN_WIDTH - (Constants.Margin.Left + Constants.Margin.Right + Constants.LineSpacing.ImageCell * 2)) / 3
            //            return width * Constants.Ratio.ProductImageHeight + Constants.Value.BrandImageHeight + 71
            return width * Constants.Ratio.ProductImageHeight + 72
        }
        return 0
    }
    
    func getMostVisibleCellIndex() -> Int{
        var maxVisiblePercent: CGFloat = 0
        var visibleIndex = 0
        if let collectionView = self.displayingCollectionView{
            let array = collectionView.indexPathsForVisibleItems
            for indexpath in array {
                if let theAttributes = collectionView.layoutAttributesForItem(at: indexpath) {
                    var offsetTop = collectionView.contentOffset.y - theAttributes.frame.minY
                    if offsetTop < 0 {
                        offsetTop = 0
                    }
                    var offsetBottom = theAttributes.frame.maxY - (collectionView.contentOffset.y + collectionView.frame.height)
                    if offsetBottom < 0 {
                        offsetBottom = 0
                    }
                    let percent = (theAttributes.frame.height - (offsetTop + offsetBottom)) / collectionView.frame.height
                    if percent > maxVisiblePercent {
                        maxVisiblePercent = percent
                        visibleIndex = indexpath.row
                    }
                }
            }
        }
        return visibleIndex
    }
    
   
    private func getHeightTags(_ tags:[String]) -> CGFloat {
        let heightLabel: CGFloat = 21.0
        var string = ""
        for tag in tags {
            string += tag + " "
        }
        if string.length == 0 {
            return 0
        }
        let wd = StringHelper.getTextWidth(string, height: heightLabel, font: UIFont.systemFont(ofSize: 14))
        let height = StringHelper.heightForText(string, width: wd, font: UIFont.systemFont(ofSize: 14))
        return height
    }
    
    //MARK: PostComment
    
    static func savePostComment(_ postCommentList : PostCommentList) -> Promise<Any> {
        return Promise{ fulfill, reject in
            
            NewsFeedService.savePostComment(postCommentList, completion: { (response) in
                if response.result.isSuccess{
                    if response.response?.statusCode == 200 {
                        
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
                
            })
        }
    }
    
    static func changePostCommentStatus(_ postCommentList : PostCommentList, statusId: Int) -> Promise<Any> {
        return Promise{ fulfill, reject in
            if postCommentList.postCommentId == nil { //Local Comment
                fulfill("OK")
            } else {
                NewsFeedService.changePostCommentStatus(postCommentList, statusId: statusId, completion: { (response) in
                    if response.result.isSuccess{
                        if response.response?.statusCode == 200 {
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
                    
                })
            }
        }
    }
    
    static func clearCache(){
        PostStorageManager.sharedManager.clearCache()
    }
    
    
}



extension PostManager : MyFeedCollectionViewCellDelegate, NewsFeedDetailCellDelegate, SimpleFeedCollectionViewCellDelegate {
    
    
    
    //MARK: MyFeedCollectionViewCellDelegate
    func didBuySuccess(_ parentOrder: ParentOrder) {
        self.delayAction = DelayAction(
            delayInSecond: 0.5,
            actionBlock: { [weak self] in
                guard let strongSelf = self else {
                    return
                }
                
                let thankYouViewController = ThankYouViewController()
                thankYouViewController.fromViewController = strongSelf.displayingViewController
                thankYouViewController.parentOrder = parentOrder
                
                let navigationController = MmNavigationController(rootViewController: thankYouViewController)
                navigationController.modalPresentationStyle = .overFullScreen
                thankYouViewController.handleDismiss = {}
                strongSelf.displayingViewController?.present(navigationController, animated: true, completion: nil)
                
            }
        )
    }
    
    func didSelectSku(_ sku: Sku, post: Post, referrerUserKey: String) {
        let style = Style()
        
        let s : Sku = sku
        if style.skuList.count == 0 {
            s.isDefault = 1
            style.skuList.append(s)
        }
        
        style.styleCode = sku.styleCode
        style.merchantId = sku.merchantId
        
        let styleViewController = StyleViewController(style: style)
        if !referrerUserKey.isEmpty {
            styleViewController.referrerUserKey = referrerUserKey
        }else {
            styleViewController.referrerUserKey = post.user?.userKey
        }
        
        
        self.displayingViewController?.navigationController?.pushViewController(styleViewController, animated: true)
    }
    
    func didSelectBrand(_ brand: Brand) {
        Log.debug("didSelectBrandAtIndexPath")
        let brandViewController = BrandViewController()
        brandViewController.brand = brand
        displayingViewController?.navigationController?.pushViewController(brandViewController, animated: true)
        
    }
    func didSelectMerchant(_ merchant: Merchant) {
        Navigator.shared.dopen(Navigator.mymm.website_merchant_merchantId + "\(merchant.merchantId)")
    }
    
    func didSelectUser(_ user: User) {
        Log.debug("didSelectUserAtIndexPath")
        
        if user.userKey == Context.getUserKey() {
            Navigator.shared.dopen(Navigator.mymm.website_account)
        } else {
           PushManager.sharedInstance.goToProfile(user, hideTabBar: true)
        }
    }
    
    
    
    func sharePost(){
        if self.currentPosts.count > 0{
            let index = self.getMostVisibleCellIndex()
            log.debug("test \(index)")
            if index > self.currentPosts.count {
                return
            }
            let post = self.currentPosts[index]
            let shareViewController = ShareViewController(screenCapSharing: true)
            if let controller = self.displayingViewController as? MmViewController {
                shareViewController.viewKey = controller.analyticsViewRecord.viewKey
            }
            let photoContainerHeight = shareViewController.view.bounds.height - ShareViewController.PhotoContainerTopPadding - ShareViewController.ConfirmViewHeight - ShareViewController.CollectionViewHeight - 1
            let shareContentViewHeight = photoContainerHeight - ShareViewController.CapscreenPadding.top - ShareViewController.CapscreenPadding.bottom * 2 - 20
            
            let shareContentViewWidth = shareContentViewHeight / ShareViewController.CapscreenContentRatio
            shareViewController.provideCapscreenView = {
                let container = UIView(frame: CGRect(x:0 , y: 0, width: shareContentViewWidth, height: shareContentViewHeight))
                let productImageView = UIImageView(frame: CGRect(x:10 , y: ViewDefaultHeight.HeightHeaderView, width: shareContentViewWidth - 20, height: shareContentViewWidth - 20))
                if post.postImage == "0" || post.postImage == "" {
                    if let image = KingfisherManager.shared.cache.retrieveImageInDiskCache(forKey: post.correlationKey) {
                        productImageView.image = image
                    }else if let image = post.pendingUploadImage {
                        productImageView.image = image
                    }
                }else {
                    productImageView.mm_setImageWithURL(ImageURLFactory.URLSize1000(post.postImage, category: .post), placeholderImage : UIImage(named: "postPlaceholder"))
                }
                
                productImageView.autoresizingMask = [.flexibleWidth, .flexibleHeight]
                container.addSubview(productImageView)
                
                let headerView = UIView(frame: CGRect(x: 0, y: 0, width: shareContentViewWidth, height: ViewDefaultHeight.HeightHeaderView))
                headerView.autoresizingMask = [.flexibleWidth]
                headerView.backgroundColor = UIColor.white
                let avatarView = AvatarView(imageStr: "", isCurator: 0)
                var frm = avatarView.frame
                frm.origin.x = Margin.left
                frm.origin.y = Margin.top
                avatarView.frame = frm
                
                let labelNameUser = UILabel(frame: CGRect(x: avatarView.frame.maxX + MarginUserName.left, y: avatarView.frame.center.y - 10, width: headerView.frame.width - (avatarView.frame.maxX + MarginUserName.left * 2) , height: 20))
                labelNameUser.formatSize(15)
                labelNameUser.textAlignment = .left
                labelNameUser.lineBreakMode = NSLineBreakMode.byTruncatingTail
                
                headerView.addSubview(avatarView)
                headerView.addSubview(labelNameUser)
                
                if post.isMerchantIdentity == .fromContentManager, let merchant = post.merchant  {
                    avatarView.setupViewByMerchant(merchant)
                    labelNameUser.text = merchant.merchantName.length > 0 ? merchant.merchantName : merchant.merchantCompanyName
                } else if let author = post.user {
                    labelNameUser.text = author.displayName
                    avatarView.setupViewByUser(author, isMerchant: (post.isMerchantIdentity == .fromContentManager))
                }
            
                
                container.addSubview(headerView)
                
                let descriptionLabel = UILabel()
                descriptionLabel.autoresizingMask = [.flexibleWidth, .flexibleHeight, .flexibleTopMargin]
                descriptionLabel.text = post.postText
                descriptionLabel.formatSize(14)
                descriptionLabel.lineBreakMode = NSLineBreakMode.byTruncatingTail
                descriptionLabel.numberOfLines = 2
                container.addSubview(descriptionLabel)
                let descriptMaxHeight :CGFloat = 40
                var height = StringHelper.heightForText(post.postText, width: shareContentViewWidth - 20, font: descriptionLabel.font)
                if height > descriptMaxHeight {
                    height = descriptMaxHeight
                }
                descriptionLabel.frame = CGRect(x:10, y: productImageView.frame.maxY + Margin.bottom, width: shareContentViewWidth - 20, height: height)
                return container
            }
            
            shareViewController.didUserSelectedHandler = { [weak self] (data) in
                if let strongSelf = self {
                    let myRole: UserRole = UserRole(userKey: Context.getUserKey())
                    let targetRole: UserRole = UserRole(userKey: data.userKey)
                    
                    WebSocketManager.sharedInstance().sendMessage(
                        IMConvStartMessage(
                            userList: [myRole, targetRole],
                            senderMerchantId: myRole.merchantId
                        ),
                        checkNetwork: true,
                        viewController: strongSelf.displayingViewController,
                        completion: { (ack) in
                            if let convKey = ack.data {
                                let viewController = UserChatViewController(convKey: convKey)
                                
                                let postModel = PostModel()
                                postModel.post = post
                                let chatModel = ChatModel(model: postModel)
                                chatModel.messageContentType = .SharePost
                                
                                viewController.forwardChatModel = chatModel
                                strongSelf.displayingViewController?.navigationController?.pushViewController(viewController, animated: true)
                            }
                    })
                }
            }
            shareViewController.didMMSelectedHandler = {
                self.repost(post)
            }
            
            shareViewController.didSelectSNSHandler = { method in
                ShareManager.sharedManager.sharePost(post, method: method, referrer: Context.getUserKey())
            }
            self.displayingViewController?.present(shareViewController, animated: false, completion: nil)
        }
    }
    
    func didClickedShare(_ post: Post) {
        
//        guard self.isUserAuthenticated() else {
//            return
//        }
        
        let shareViewController = ShareViewController ()
        
        if let activeViewController = Utils.findActiveController() as? MmViewController {
            shareViewController.viewKey = activeViewController.analyticsViewRecord.viewKey
        }
        
        shareViewController.isSharePost = true
        
        shareViewController.didUserSelectedHandler = { [weak self] (data) in
            if let strongSelf = self {
                let myRole: UserRole = UserRole(userKey: Context.getUserKey())
                let targetRole: UserRole = UserRole(userKey: data.userKey)
                
                WebSocketManager.sharedInstance().sendMessage(
                    IMConvStartMessage(
                        userList: [myRole, targetRole],
                        senderMerchantId: myRole.merchantId
                    ),
                    checkNetwork: true,
                    viewController: strongSelf.displayingViewController,
                    completion: { (ack) in
                        if let convKey = ack.data {
                            let viewController = UserChatViewController(convKey: convKey)
                            
                            let postModel = PostModel()
                            postModel.post = post
                            let chatModel = ChatModel(model: postModel)
                            chatModel.messageContentType = .SharePost
                            
                            viewController.forwardChatModel = chatModel
                            strongSelf.displayingViewController?.navigationController?.pushViewController(viewController, animated: true)
                        }
                    })
            }
        }
        
        shareViewController.didMMSelectedHandler = {
            self.repost(post)
        }
        
        shareViewController.didSelectSNSHandler = { method in
            ShareManager.sharedManager.sharePost(post, method: method, referrer: Context.getUserKey())
        }
        self.displayingViewController?.present(shareViewController, animated: false, completion: nil)
        
    }
    
    func didClickedLikeCount(_ post: Post) {
        let likeListController = PostLikeListViewController()
        likeListController.post = post
        if let _ = displayingViewController as?  ProfileViewController {
            likeListController.isHideTabBar = true
        }
        displayingViewController?.navigationController?.pushViewController(likeListController, animated: true)
    }
    
    func didClickUserProfile(_ user: User) {
        PushManager.sharedInstance.goToProfile(user, hideTabBar: true)
    }
    
    func didClickDescriptionText(_ post: Post) {
        Log.debug("didClickedComment")
        let postDetailController = PostDetailViewController(postId: post.postId)
        postDetailController.post = post
        displayingViewController?.navigationController?.pushViewController(postDetailController, animated: true)
    }
    
    func didClickOnPostImage(_ post: Post) {
        if let displayingVC = self.displayingViewController {
            displayingVC.view.analyticsViewKey = post.analyticsViewKey
            displayingVC.view.analyticsImpressionKey = post.analyticsImpressionKey
            displayingVC.view.recordAction(.Tap, sourceRef: "\(post.postId)", sourceType: .Post, targetRef: "Post-Detail", targetType: .View)
            let postDetailController = PostDetailViewController(postId: post.postId)
            postDetailController.post = post
            displayingVC.navigationController?.pushViewController(postDetailController, animated: true)
        }
    }
    
    func didClickedComment(_ clickedNewsFeed: Post) {
        if LoginManager.getLoginState() != .validUser {
            LoginManager.goToLogin()
        }else {
            Log.debug("didClickedComment")
            let postDetailController = PostDetailViewController(postId: clickedNewsFeed.postId)
            postDetailController.post = clickedNewsFeed
            displayingViewController?.navigationController?.pushViewController(postDetailController, animated: true)
        }
        
    }
    
    func didClickedLike(_ post: Post, cell: UICollectionViewCell) {
        if self.isUserAuthenticated(){
            let correlationKey = PostManager.correlationKeyOfPostLiked(post)
            if (correlationKey.length > 0) { //isLiked -> Unlike action
                //update UI first
                post.likeCount -= 1
                self.updateUnlikePostUI(post, cell: cell)
                PostManager.updateUserLikes(correlationKey, post: post, likeStatus: Constants.StatusID.deleted)
                
                //call api
                PostManager.changeLikeStatusNewsfeedPost(post, likeStatus: Constants.StatusID.deleted, correlationKey: correlationKey).then { (_) -> Void in
                    
                    self.displayingCollectionView?.reloadData()
                    
                    PostManager.isNeedSavePost = true
                    
                }.catch { error in
                    //rollback
                    post.likeCount += 1
                    PostManager.updateUserLikes(correlationKey, post: post, likeStatus: Constants.StatusID.active)
                    self.updateLikePostUI(post, cell: cell)
                    cell.isUserInteractionEnabled = true
                }
            }else{//Like post action
                //generate like correlationkey
                let correlationKey = Utils.UUID()
                
                //update UI first
                post.likeCount += 1
                PostManager.updateUserLikes(correlationKey, post: post, likeStatus: Constants.StatusID.active)
                self.updateLikePostUI(post, cell: cell)
                
                //call api
                PostManager.changeLikeStatusNewsfeedPost(post, likeStatus: Constants.StatusID.active, correlationKey: correlationKey).then { (likedCorrelationKey) -> Void in
                    
                    self.displayingCollectionView?.reloadData()
                    (self.displayingViewController as? MmViewController)?.updateButtonWishlistState()
                    PostManager.isNeedSavePost = true
                }.catch { error in
                    
                    //rollback
                    PostManager.updateUserLikes(correlationKey, post: post, likeStatus: Constants.StatusID.deleted)
                    post.likeCount -= 1
                    self.updateUnlikePostUI(post, cell: cell)
                }
            }
        }
    }
    
    func updateUnlikePostUI (_ post: Post, cell: UICollectionViewCell){
        if (post.likeCount > 0) {
            if cell is MyFeedCollectionViewCell {
                let cell = cell as! MyFeedCollectionViewCell
                if let actionView = cell.actionView{
                    actionView.buttonLike.isSelected = false
                    actionView.likeCountLabel.text =  NumberHelper.formatLikeAndCommentCount(post.likeCount)
                }
            } else if cell is SimpleFeedCollectionViewCell {
                let cell = cell as! SimpleFeedCollectionViewCell
                if post.likeCount > 0 {
                    cell.likeButton.setTitle(NumberHelper.formatLikeAndCommentCount(post.likeCount) , for: .normal)
                } else {
                    cell.likeButton.setTitle("0" , for: .normal)
                }
            }
        }
    }
    
    func updateLikePostUI(_ post: Post, cell: UICollectionViewCell){
        if (post.likeCount > 0) {
            if cell is MyFeedCollectionViewCell {
                let cell = cell as! MyFeedCollectionViewCell
                if let actionView = cell.actionView{
                    actionView.buttonLike.isSelected = true
                    actionView.likeCountLabel.text =  NumberHelper.formatLikeAndCommentCount(post.likeCount)
                    
                }
            }else if cell is SimpleFeedCollectionViewCell {
                let cell = cell as! SimpleFeedCollectionViewCell
                if post.likeCount > 0 {
                    cell.likeButton.setTitle(NumberHelper.formatLikeAndCommentCount(post.likeCount) , for: .normal)
                } else {
                    cell.likeButton.setTitle("0" , for: .normal)
                }
            }
        }
    }
    
    //pass likedCorrelationKey if it is like action
    static func updateUserLikes(_ likedCorrelationKey: String? = nil, post: Post, likeStatus: Constants.StatusID,isRefreshWishlish: Bool = true){
        var isLikeObjExist = false
        for (like) in PostStorageManager.sharedManager.userLikes {
            if like.postId == post.postId {
                isLikeObjExist = true
                like.statusId = likeStatus.rawValue
                if let corKey  = likedCorrelationKey{
                    like.correlationKey = corKey
                }
                like.lastModified = Date()
            }
        }
        
        if isLikeObjExist == false {
            if let correlationKey = likedCorrelationKey  {
                let likeObj = PostLike(likePost: post, corrKey: correlationKey, userKey: Context.getUserKey(), status: likeStatus.rawValue)
                PostStorageManager.sharedManager.userLikes.append(likeObj)
            }
        }
        
        PostStorageManager.sharedManager.saveUserLikes()
        
        if likeStatus == .active {
            let index = post.likeList.index(where: { (likedUser) -> Bool in
                return likedUser.userKey.isEqualToString(Context.getUserKey()) //we have the item in like list
            })
            if index == nil {
                post.likeList.append(Context.getUserProfile())
            }
        } else if likeStatus == .inactive || likeStatus == .deleted {
            for user in post.likeList {
                if user.userKey == Context.getUserKey() {
                    post.likeList.remove(user)
                }
            }
        }
        
        if isRefreshWishlish {
            CacheManager.sharedManager.refreshWishList()
        } else {
            NotificationCenter.default.post(name: NSNotification.Name(rawValue: "refreshWishListFinished"), object: nil)
        }
        
    }
    
    func didClickedOptions(_ clickedNewsFeed: Post, cell: MyFeedCollectionViewCell) {
        
        let optionMenu = UIAlertController(title: nil, message: nil, preferredStyle: .actionSheet)
        _ = PostManager.correlationKeyOfPostLiked(clickedNewsFeed)
        let alertDeleteController = UIAlertController(title: nil, message: String.localize("LB_DELETE_POST_MESSAGE"), preferredStyle: UIAlertControllerStyle.alert)
        alertDeleteController.view.tintColor = UIColor.alertTintColor()
        let cancelDeleteAction = UIAlertAction(title: String.localize("LB_CA_CANCEL"), style: .cancel, handler: {
            (alert: UIAlertAction!) -> Void in
            
        })
        
        
        let confirmDeleteAction = UIAlertAction(title: String.localize("LB_CA_POST_DELETE"), style: .default, handler: {
            (alert: UIAlertAction!) -> Void in
            
            firstly {
                return self.deleteNewsFeed(String(clickedNewsFeed.postId))
                }.then { _ -> Void in
                    clickedNewsFeed.statusId = Constants.StatusID.deleted.rawValue
                    clickedNewsFeed.lastModified = Date()
                    
                    PostManager.updateLocalUserPostStatusChanged(clickedNewsFeed)
                    
                    self.displayingCollectionView?.reloadData()
                    
                }.catch { _ -> Void in
                    Log.error("error")
            }
            
        })
        
        alertDeleteController.addAction(cancelDeleteAction)
        alertDeleteController.addAction(confirmDeleteAction)
        
        
        let deleteAction = UIAlertAction(title: String.localize("LB_CA_POST_DELETE"), style: .default, handler: {
            (alert: UIAlertAction!) -> Void in
            self.displayingViewController?.present(alertDeleteController, animated: true, completion: nil)
        })
        
        
        let reportAction = UIAlertAction(title: String.localize("LB_CA_POST_REPORT"), style: .default, handler: {
            (alert: UIAlertAction!) -> Void in
            
            if self.isUserAuthenticated(){
                let controller = ReportFeedViewController()
                controller.postId = clickedNewsFeed.postId
                
                self.displayingViewController?.navigationController?.pushViewController(controller, animated: true)
            }
        })
        
        let cancelAction = UIAlertAction(title: String.localize("LB_CA_CANCEL"), style: .cancel, handler: {
            (alert: UIAlertAction!) -> Void in
        })
        
        if let author = clickedNewsFeed.user, author.userKey == Context.getUserKey(){
            optionMenu.addAction(deleteAction)
        }else{
            optionMenu.addAction(reportAction)
        }
        optionMenu.addAction(cancelAction)
        
        optionMenu.view.tintColor = UIColor.secondary2()
        
        displayingViewController?.present(optionMenu, animated: true, completion: nil)
        optionMenu.view.tintColor = UIColor.alertTintColor()
    }
    
    
    func collectionViewSelected(_ collectionViewItem: Int) {
        didSelectedExpand(collectionViewItem)
    }
    
    func collectionViewSelectedExpandDescriptionView(_ collectionViewItem: Int) {
        didSelectedExpandDescriptionView(collectionViewItem)
    }
    
    func didSelectedExpand(_ row: Int) -> Void {
        
        let post = self.currentPosts[row]
        displayingCollectionView?.reloadData()
        post.isExpand = !post.isExpand
        
        if postIdsExpanded.contains(post.postId){
            postIdsExpanded.remove(post.postId)
        }
        else{
            postIdsExpanded.append(post.postId)
        }
    }
    
    func didSelectedExpandDescriptionView(_ row: Int) -> Void {
        let post = self.currentPosts[row]
        displayingCollectionView?.reloadData()
        if postIdsShowingFullDescriptionText.contains(post.postId) {
            postIdsShowingFullDescriptionText.remove(post.postId)
        }else {
            postIdsShowingFullDescriptionText.append(post.postId)
        }
    }
    
    func refreshCollectionViewWithStyles(_ styles : [Style], byIndex: Int) {
        if self.currentPosts.count == 0 {
            return
        }
        let post = self.currentPosts[byIndex] as Post
        post.styles = styles
        
        if let skuList = post.skuList {
            for i in 0 ..< skuList.count {
                let postSku = skuList[i]
                
                if let relatedStyle = styles.filter({ (style) -> Bool in
                    style.skuList.contains(where: {$0.skuId == postSku.skuId })
                }).first {
                    
                    if let validSku = relatedStyle.skuList.filter({ $0.skuId == postSku.skuId }).first {
                        postSku.productImage = relatedStyle.findImageKeyByColorKey(validSku.colorKey ) ?? ""
                        postSku.brandImage = relatedStyle.brandHeaderLogoImage
                        postSku.brandName = relatedStyle.brandName
                        postSku.isSale = validSku.isSale
                    }
                }
                
                post.skuList![i] = postSku
            }
        }
        
        DispatchQueue.main.async {
            self.displayingCollectionView?.reloadData()
        }
    }
    
    func didClickedTag(_ post: Post) {
        if post.isHideTag{
            if !postIdsHidingTag.contains(post.postId){
                postIdsHidingTag.append(post.postId)
            }
        }
        else{
            if postIdsHidingTag.contains(post.postId){
                postIdsHidingTag.remove(post.postId)
            }
        }
    }
    
    func didClickedFollowUser(_ user: User, isGoingToFollow: Bool) {
        
        let currentDisplayViewController = self.displayingViewController as? MmViewController
        
        if isGoingToFollow {
            FollowService.instance.cachedLoadingUserKeys.insert(user.userKey)
            firstly {
                return FollowService.requestFollow(user.userKey)
                }.always {
                    FollowService.instance.cachedLoadingUserKeys.remove(user.userKey)
                    self.displayingCollectionView?.reloadData()
                }.catch { _ -> Void in
                    Log.error("error")
            }
            self.logAction(userKey:user.userKey , sourceRef: "Follow",isCurator: user.isCurator == 1)
        } else {
            
            guard self.displayingViewController != nil else { return }
            
            let message = String.localize("LB_CA_UNFOLLOW_CONF").replacingOccurrences(of: "{0}", with: user.displayName)
            Alert.alert(currentDisplayViewController!, title: "", message: message, okActionComplete: { () -> Void in
                
                FollowService.instance.cachedLoadingUserKeys.insert(user.userKey)
                firstly {
                    return FollowService.requestUnfollow(user.userKey)
                    }.always {
                        
                        FollowService.instance.cachedLoadingUserKeys.remove(user.userKey)
                        self.displayingCollectionView?.reloadData()
                        
                    }.catch { error -> Void in
                        Log.error("error")
                        
                        let error = error as NSError
                        if let apiResp = error.userInfo["data"] as? ApiResponse {
                            currentDisplayViewController?.handleApiResponseError(apiResponse: apiResp, statusCode: error.code)
                        }
                }
                self.logAction(userKey:user.userKey , sourceRef: "Unfollow",isCurator: user.isCurator == 1)
                }, cancelActionComplete:{ () -> Void in
                    self.displayingCollectionView?.reloadData()
            })
            
        }
    }
    
    func didClickedFollowMerchant(_ merchant: Merchant, isGoingToFollow: Bool) {
        
        let currentDisplayViewController = self.displayingViewController as? MmViewController
        
        if isGoingToFollow {
            FollowService.instance.cachedLoadingMerchantIds.insert(merchant.merchantId)
            firstly {
                return FollowService.requestFollow(merchant: merchant)
                }.always {
                    FollowService.instance.cachedLoadingMerchantIds.remove(merchant.merchantId)
                    self.displayingCollectionView?.reloadData()
                }.catch { error -> Void in
                    Log.error("error")
                    let error = error as NSError
                    if let apiResp = error.userInfo["data"] as? ApiResponse {
                        currentDisplayViewController?.handleError(apiResp, statusCode: error.code, animated: true)
                    }
            }
            
            self.logAction(sourceRef: "Follow",isMerchant: true)
        } else {
            
            guard self.displayingViewController != nil else { return }
            
            let message = String.localize("LB_CA_UNFOLLOW_CONF").replacingOccurrences(of: "{0}", with: merchant.merchantNameInvariant)
            Alert.alert(self.displayingViewController!, title: "", message: message, okActionComplete: { () -> Void in
                FollowService.instance.cachedLoadingMerchantIds.insert(merchant.merchantId)
                firstly {
                    return FollowService.requestUnfollow(merchant: merchant)
                    }.always {
                        FollowService.instance.cachedLoadingMerchantIds.remove(merchant.merchantId)
                        self.displayingCollectionView?.reloadData()
                    }.catch { error -> Void in
                        Log.error("error")
                        let error = error as NSError
                        if let apiResp = error.userInfo["data"] as? ApiResponse {
                            currentDisplayViewController?.handleError(apiResp, statusCode: error.code, animated: true)
                        }
                }
                self.logAction(sourceRef: "Unfollow",isMerchant: true)
                }, cancelActionComplete:{ () -> Void in
                    self.displayingCollectionView?.reloadData()
            })
        }
    }
    
    
    func didClickOnHashTag(_ hashTag: String) {
        
        if let displayingVC = self.displayingViewController {
            let hashTagValue = hashTag.replacingOccurrences(of: "#", with: "")
            Navigator.shared.dopen(Navigator.mymm.deeplink_dk_tag_tagName + Urls.encoded(str: hashTagValue))
            
            displayingVC.view.recordAction(.Tap, sourceRef: hashTag, sourceType: .Topic, targetRef: "Newsfeed-Post-Topic", targetType: .View)
        }
    }
    
    func didClickOnURL(_ url: String) {
        Navigator.shared.dopen(url)
    }
    
    func logAction(_ actionType: AnalyticsActionRecord.ActionTriggerType = .Tap, userKey: String? = nil, sourceRef: String? = nil,isMerchant: Bool = false, isCurator: Bool = false){
        var actionElement : AnalyticsActionRecord.ActionElement
        if isMerchant {
            actionElement = .Merchant
        } else {
            actionElement = (isCurator ? .Curator : .User)
        }
        self.displayingViewController?.view.recordAction(actionType, sourceRef: sourceRef, sourceType: .Button, targetRef: userKey, targetType: actionElement)
    }
    
    static func insertLocalPostCommentList(_ comment: PostCommentList, post: Post, atFirstIndex: Bool = false){
        
        if let postId = comment.postId {
            if (PostStorageManager.sharedManager.postCommentLists[postId] != nil) {
                if atFirstIndex {
                    PostStorageManager.sharedManager.postCommentLists[postId]?.insert(comment, at: 0)
                } else {
                    PostStorageManager.sharedManager.postCommentLists[postId]?.append(comment)
                }
                
            }else{
                PostStorageManager.sharedManager.postCommentLists[postId] = [comment]
            }
            self.updatePostCommentCount(post, latestOwnComments: [comment])
//            PostStorageManager.sharedManager.saveLocalCommentToDisk()
        }
        
    }
    
    
    func isUserAuthenticated()->Bool{
        if LoginManager.getLoginState() != .validUser {
            LoginManager.goToLogin()
            return false
        } else{
            return true
        }
    }
    
    //MARK:- Mycollection page methods
    static func didUnlikePost(_ post: Post, completion : @escaping ((_ error: NSError?, _ likedCorrelationKey: String? ) -> Void)) {
        if LoginManager.getLoginState() != .validUser {
            return
        }
        let correlationKey = PostManager.correlationKeyOfPostLiked(post)
        if (correlationKey.length > 0) {
            //call api
            firstly {
                return  PostManager.changeLikeStatusNewsfeedPost(post, likeStatus: Constants.StatusID.deleted, correlationKey: correlationKey)
                }.then{ likedCorrelationKey in
                    completion(nil, (likedCorrelationKey as? String) ?? correlationKey)
                    
                }.catch { (error) in
                    completion(error as NSError, nil)
                }
        }
    }
    
    static func updateLocalUserPost(_ post: Post) {
        for (key, _) in PostStorageManager.sharedManager.userPosts {
            if let posts = PostStorageManager.sharedManager.userPosts[key] {
                for localPost in posts {
                    if localPost.postId == post.postId {
                        localPost.likeCount -= 1
                        if localPost.likeCount < 0 {
                            localPost.likeCount = 0
                        }
                    }
                }
            }
        }
        
    }
    
    static func updateLocalUserPostStatusChanged(_ post: Post) {
        for (key, _) in PostStorageManager.sharedManager.userPosts {
            if let posts = PostStorageManager.sharedManager.userPosts[key] {
                for localPost in posts {
                    if localPost.postId == post.postId {
                        localPost.statusId = post.statusId
                    }
                }
            }
        }
        
        for (_, posts) in PostStorageManager.sharedManager.merchantPosts {
            for localPost in posts {
                if localPost.postId == post.postId {
                    localPost.statusId = post.statusId
                }
            }
        }
        
        for (_, posts) in PostStorageManager.sharedManager.productPosts {
            for localPost in posts {
                if localPost.postId == post.postId {
                    localPost.statusId = post.statusId
                }
            }
        }
    }
    
}

