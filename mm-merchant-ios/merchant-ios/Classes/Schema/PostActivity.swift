//
//  PostActivity.swift
//  merchant-ios
//
//  Created by Sang Nguyen on 6/3/16.
//  Copyright © 2016 WWE & CO. All rights reserved.
//


import RealmSwift
import ObjectMapper
class PostActivity: NSObject, Mappable  {
    
    var postId = 0;
    var likeCount = 0;
    var commentCount = 0;
    var commentList : [PostCommentList] = []
    var likeList : [User] = []
    
    required convenience init?(map: Map) {
        self.init()
    }
    // Mappable
    func mapping(map: Map) {
        postId          <- map["PostId"]
        likeCount       <- map["LikeCount"]
        commentCount    <- map["CommentCount"]
        commentList     <- map["CommentList"]
        likeList        <- map["LikeList"]
    }
}
