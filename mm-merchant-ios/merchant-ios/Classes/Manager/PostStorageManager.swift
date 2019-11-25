//
//  PostStorageManager.swift
//  merchant-ios
//
//  Created by Tony Fung on 16/8/2016.
//  Copyright © 2016年 WWE & CO. All rights reserved.
//

import UIKit
import ObjectMapper


// Should be only access by Post Manager

class PostStorageManager {
    
    // MARK: - Keys
    static private let Local_User_Posts_Cache = "LOCAL_USER_POSTS_CACHE"
    static private let Local_Merchant_Posts_Cache = "LOCAL_MERCHANT_POSTS_CACHE"
    static private let Local_Product_Posts_Cache = "LOCAL_PRODUCT_POSTS_CACHE"
    static private let Local_Merchant_Post_Comment_Cache = "LOCAL_POST_COMMENTS_CACHE"
    static private let Local_User_Likes_Cache = "LOCAL_USER_LIKES"
    
    // MARK: - Variables
    
    private func filterInvalidPost<T>(value: [T: [Post]]) -> [T: [Post]] {
        var result = [T: [Post]]()
        for (key, list) in value {
            var resultList = [Post]()
            for post in list {
                if post.statusId == Constants.StatusID.active.rawValue {
                    resultList.append(post)
                }
            }
            result[key] = list
        }
        return result
    }
    
    var userPosts : [String: [Post]] {
        get {
            return safeUserPosts
        }
        
        set(value){
            queue.sync {
                safeUserPosts = value
            }
        }
    }
    
    // Comments that the current user made / deleted
    var postCommentLists : [Int: [PostCommentList]] = [:]
    
    var merchantPosts : [Int: [Post]] {
        get {
            return safeMerchantPosts
        }
        
        set(value){
            queue.sync {
                safeMerchantPosts = value
            }
        }
    }
    
    
    var productPosts : [Int: [Post]] {
        get {
            return safeProductPosts
        }
        
        set(value){
            queue.sync {
                safeProductPosts = value
            }
        }
    }

    var userLikes : [PostLike] = []
    
    class var sharedManager: PostStorageManager {
        get {
            struct Singleton {
                static let instance = PostStorageManager()
            }
            return Singleton.instance
        }
    }

    private var queue = DispatchQueue(label: "mymm.post.queue", attributes: [])
    
    private var safeMerchantPosts : [Int: [Post]] = [:]
    private var safeUserPosts : [String : [Post]] = [:]
    private var safeProductPosts : [Int: [Post]] = [:]
    
    
    
    // MARK: - Push Save Load
    
    private var loadedCache = false
    
    func loadLocalPostsFromDisk(){
        
        
        if loadedCache {
            return
        }
        
        loadedCache = true
        
        PostStorageManager.sharedManager.loadUserLikes() // load like from disk as well
        
        let mapper = Mapper<Post>()
        
        if let cachedPosts = UserDefaults.standard.object(forKey: PostStorageManager.Local_User_Posts_Cache) as? [String: [[String:Any]]] {
            
            var userPostList : [String: [Post]] = [:]
            for (userKey, jsonPosts) in cachedPosts {
                let posts = mapper.mapArray(JSONArray: jsonPosts)
                userPostList[userKey] = posts
            }
            PostStorageManager.sharedManager.userPosts = userPostList
        }
        
        if let cachedPosts = UserDefaults.standard.object(forKey: PostStorageManager.Local_Merchant_Posts_Cache) as? [String: [[String:Any]]] {
            
            var merchantPostList : [Int: [Post]] = [:]
            for (merchantId, jsonPosts) in cachedPosts {
                let posts = mapper.mapArray(JSONArray: jsonPosts)
                if let mId = Int(merchantId) {
                    merchantPostList[mId] = posts
                }
            }
            PostStorageManager.sharedManager.merchantPosts = merchantPostList
        }
        
        if let cachedPosts = UserDefaults.standard.object(forKey: PostStorageManager.Local_Product_Posts_Cache) as? [String: [[String:Any]]] {
            
            var productPostList : [Int: [Post]] = [:]
            for (skuId, jsonPosts) in cachedPosts {
                let posts = mapper.mapArray(JSONArray: jsonPosts)
                if let sId = Int(skuId) {
                    productPostList[sId] = posts
                }
            }
            PostStorageManager.sharedManager.productPosts = productPostList
        }
        
    }
    
    
    func saveLocalPostsToDisk(){
        
        queue.async {
            //we convert the object
            let mapper = Mapper<Post>()
            
            var jsonUserPosts : [String: [[String:Any]]] = [:]
            for (userKey, posts) in PostStorageManager.sharedManager.userPosts {
                if userKey == Context.getUserKey() || userKey == FeedType.styleFeed.rawValue || userKey == FeedType.newsFeed.rawValue {
                    let trimedPost = Array(posts.prefix(Constants.Paging.PostOffset)) // limit the post number first
                    let jsonPosts = mapper.toJSONArray(trimedPost)
                    jsonUserPosts[userKey] = jsonPosts
                }
            }
            
            let jsonMerchantPosts : [String: [[String:Any]]] = [:]
//            for (merchantId, posts) in PostStorageManager.sharedManager.merchantPosts {
//                if merchantId == Context.getUserProfile().merchantId {
//                    let trimedPost = Array(posts.prefix(Constants.Paging.PostOffset))
//                    let jsonPosts = mapper.toJSONArray(trimedPost)
//                    jsonMerchantPosts[String(merchantId)] = jsonPosts
//                }
//            }
            
            let jsonProductPosts : [String: [[String:Any]]] = [:]
//            for (skuId, posts) in PostStorageManager.sharedManager.productPosts {
//                let trimedPost = Array(posts.prefix(Constants.Paging.PostOffset))
//                let jsonPosts = mapper.toJSONArray(trimedPost)
//                jsonProductPosts[String(skuId)] = jsonPosts
//            }
            
            UserDefaults.standard.setValue(jsonMerchantPosts, forKey: PostStorageManager.Local_Merchant_Posts_Cache)
            UserDefaults.standard.setValue(jsonProductPosts, forKey: PostStorageManager.Local_Product_Posts_Cache)
            UserDefaults.standard.setValue(jsonUserPosts, forKey: PostStorageManager.Local_User_Posts_Cache)
            
        }
        
    }
    
    // MARK: - Like Save Load
    
    func saveUserLikes(){
        queue.async {
            Log.debug("TF::: saveUserLikes start")
            let mapper = Mapper<PostLike>()
            let likesJson = mapper.toJSONArray(self.userLikes)
            UserDefaults.standard.setValue(likesJson, forKey: PostStorageManager.Local_User_Likes_Cache)
            Log.debug("TF::: saveUserLikes end")
        }
    }
    
    func loadUserLikes() {
        Log.debug("TF::: loadUserLikes start")
        let mapper = Mapper<PostLike>()
        let likesJson = UserDefaults.standard.value(forKey: PostStorageManager.Local_User_Likes_Cache)
        
        userLikes = mapper.mapArray(JSONObject: likesJson) ?? []
        
        Log.debug("TF::: loadUserLikes end")
    }
    
    // MARK: - Comments
    
    
    func saveLocalCommentToDisk(){
        queue.async {
            let mapper = Mapper<PostCommentList>()
            var jsonUserPosts : [String: [[String:Any]]] = [:]
            let postIds = PostStorageManager.sharedManager.postCommentLists.keys.sorted(by: { (first, second) -> Bool in
                return first > second
            }).prefix(Constants.Paging.CommentOffset)
            
            for postId in postIds {
                if let comments = PostStorageManager.sharedManager.postCommentLists[postId] {
                    let trimedComments = Array(comments.prefix(Constants.Paging.CommentOffset))
                    let jsonComments = mapper.toJSONArray(trimedComments)
                    jsonUserPosts[String(postId)] = jsonComments
                }
            }
            UserDefaults.standard.setValue(jsonUserPosts, forKey: PostStorageManager.Local_Merchant_Post_Comment_Cache)
        }
    }

    
    
    func clearLocalComments() {
        UserDefaults.standard.removeObject(forKey: PostStorageManager.Local_Merchant_Post_Comment_Cache)
    }
    
    // MARK: -

    func clearCache(){
        userPosts = [:]
        safeMerchantPosts = [:]
        merchantPosts = [:]
        safeMerchantPosts = [:]
        productPosts = [:]
        safeProductPosts = [:]
        userLikes = []
        postCommentLists = [:]
        clearLocalComments()
        saveUserLikes()
        saveLocalPostsToDisk()
        loadedCache = false
    }
    
    func hasLikedPosts() -> Bool {
        for (like) in PostStorageManager.sharedManager.userLikes {
            if like.statusId == Constants.StatusID.active.rawValue {
                return true
            }
        }
        
        return false
    }
    
    
}
