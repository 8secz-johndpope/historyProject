//
//  NewsFeed.swift
//  merchant-ios
//
//  Created by Markus Chow on 26/4/2016.
//  Copyright © 2016 WWE & CO. All rights reserved.
//

import Foundation
import ObjectMapper


enum TagPlace: Int {
    case undefined = 0,
    left,
    right
}


enum MerchantIdentity : Int {
    case fromAmbassador = 0,
    fromContentManager = 1
    
}

class Post : Mappable, Equatable {
    
    static func ==(lhs: Post, rhs: Post) -> Bool {
        return lhs.postId == rhs.postId || lhs.correlationKey == rhs.correlationKey
    }
    
    var postId = 0
    var merchantId = 0
    var postText = ""
    var postImage = ""
    var statusId = 0
    var lastModified = Date()
    var lastCreated = Date()
    var user : User?
    var merchant : Merchant?
    var brandList : [Brand] = []
    var merchantList : [Merchant] = []
    var skuList : [Sku]?
    var images : [Images]?
    var userList : [User] = []
    var isExpand = false
    // var isExpandDescriptionText = false
    var likeList : [User] = []
    var likeCount = 0
    var isSelfLiked = false
    var commentCount = 0
    var postLikeId = 0
    var isMerchantIdentity : MerchantIdentity = .fromAmbassador
    var correlationKey : String = Utils.UUID()
    
    var groupKey : String = ""
    
    //for upload part
    var userKey = ""
    var pendingUploadImage : UIImage?
    
    var postCommentLists : [PostCommentList]?
    var isHideTag = false
    var userSource : User?
    var styles : [Style]?
    var isTextExpandable = false
    required convenience init?(map: Map) {
        self.init()
    }
    var analyticsImpressionKey = ""
    var analyticsViewKey = ""
    var feature = "0"
    
    // Mappable
    func mapping(map: Map) {
        
        postId            <- map["PostId"]
        merchantId        <- map["MerchantId"]
        postText        <- map["PostText"]
        postImage        <- map["PostImage"]
        statusId        <- map["StatusId"]
        lastCreated     <- (map["LastCreated"], IMDateTransform(stringFormat: "yyyy-MM-dd'T'HH:mm:ss.SSS"))
        lastModified    <- (map["LastModified"], IMDateTransform(stringFormat: "yyyy-MM-dd'T'HH:mm:ss.SSS"))
        user            <- map["User"]
        merchant        <- map["Merchant"]
        brandList        <- map["BrandList"]
        merchantList    <- map["MerchantList"]
        skuList            <- map["SkuList"]
        images          <- map["Images"]
        userList        <- map["UserList"]
        //        tags            <- map["tags"]
        postCommentLists <- map["PostCommentList"]
        likeList        <- map["LikeList"]
        likeCount       <- map["LikeCount"]
        isSelfLiked     <- map["IsSelfLiked"]
        correlationKey  <- map["CorrelationKey"]
        
        commentCount    <- map["CommentCount"]
        isMerchantIdentity <- map["IsMerchantIdentity"]
        
        
        groupKey        <- map["GroupKey"]
        userSource      <- map["UserSource"]
        postLikeId      <- map["PostLikeId"]
        
        if let images = images {
            var result = [Sku]()
            for image in images {
                guard let skuList = image.skuList else { continue }
                result.append(contentsOf: skuList)
            }
            skuList = result
        }

    }
    
    func timeString() -> String {
        
        /*Test post time
         let todaysDate = NSDate.init()
         let gregorian = NSCalendar(calendarIdentifier: NSGregorianCalendar)
         let dateComponents = NSDateComponents.init()
         
         /*Publish from +1 years ago //passed
         dateComponents.year = -2
         */
         
         /*Publish from +7 days - 1 year ago //passed
         dateComponents.day = -9//Publish from +7 days - 1 year ago
         */
         
         /*Publish from 1 day - 7 days ago //passed
         dateComponents.day = -6
         */
         
         /*Publish from 1 hour - 24 hours ago
         dateComponents.hour = -1
         */
         
         /*Publish from 0 - 59 mins ago
         dateComponents.minute = -2
         */
         
         let targetDate = gregorian?.dateByAddingComponents(dateComponents, toDate: todaysDate, options: NSCalendarOptions.init(rawValue: 0))
         Log.debug(targetDate?.postTimeString)
         */
        
        return lastCreated.postTimeString
    }
    
    
    
    func getSkusParameter() -> [Any] {
        var skuList = [Any]()
        if self.skuList != nil {
            for sku in self.skuList! {
                let data = ["SkuId" : sku.skuId, "PositionX" : sku.positionX, "PositionY" : sku.positionY, "Place" : sku.place.rawValue]
                skuList.append(data)
            }
        }
        return skuList
    }
    func getSkus(){
        var skuList = [Sku]()
        if self.images != nil {
            let images = self.images![0]
            if images.tags != nil{
                for tags in images.tags!{
                    if tags.postTag == .Commodity {
                        let sku = Sku()
                        sku.place = tags.place
                        let tagPercent = ProductTagView.getTapPercentage(CGPoint(x: tags.positionX, y: tags.positionY))
                        sku.positionX = tagPercent.x
                        sku.positionY = tagPercent.y
                        sku.skuId = tags.id
                        skuList.append(sku)
                    }
                }
                self.skuList = skuList
            }
            
        }
        
    }
    func getImagesParameter() -> [Any] {
        var imagesList = [AnyObject]()
        if self.images != nil {
            for images in self.images! {
                
                let data = ["Image" : images.image!,"Tags" : getTags(images: images,type:0)] as [String : Any]
                imagesList.append(data as AnyObject)
            }
        }
        return imagesList
    }
    func getMerchantList() -> [Any] {
        var merchantList = [Any]()
        for merchant in self.merchantList {
            let data = ["MerchantId" : merchant.merchantId, "PositionX" : 0, "PositionY" : 0, "Place" : 0]
            merchantList.append(data as Any)
        }
        return merchantList
    }
    func getTags(images:Images,type:NSInteger) -> [Any] {
        var tagsList = [Any]()
        if images.tags != nil {
            for index in 0..<images.tags!.count {
                let tags = images.tags![index]
                var positionX = tags.positionX
                var positionY = tags.positionY
                if self.feature == "1" {
                    if CGFloat(tags.positionX) > tags.iamgeFrame.maxX || CGFloat(tags.positionX) < tags.iamgeFrame.origin.x || CGFloat(tags.positionY) > tags.iamgeFrame.maxY || CGFloat(tags.positionY) < tags.iamgeFrame.origin.y{
                        
                        positionX = Int(25)
                        var margin = 0
                        if tags.iamgeFrame.size.height > tags.iamgeFrame.size.width{
                            margin = 35
                        }else {
                            margin = 70
                        }
                        positionY = Int(Int(ScreenWidth) - margin * index)
                    }
                }
                
                let tagPercent = ProductTagView.getTapPercentage(CGPoint(x: positionX, y: positionY))
                if type == 0{
                    let data = ["Id" : tags.id, "PositionX" : tagPercent.x, "PositionY" : tagPercent.y, "Place" : tags.place.rawValue,"PostTag":tags.postTag.rawValue]
                    tagsList.append(data)
                }else{
                    let data = ["SkuId" : tags.id, "PositionX" : tagPercent.x, "PositionY" : tagPercent.y, "Place" : tags.place.rawValue]
                    tagsList.append(data)
                }
                
                
            }
        }
        return tagsList
    }
    func getMerchantIds() -> [String] {
        var merchantIds = [String]()
        if let skus = self.skuList {
            for sku in skus {
                let merchantId = String(sku.merchantId)
                if !merchantIds.contains(merchantId) {
                    merchantIds.append(merchantId)
                }
            }
        }
        return merchantIds
    }
    
    func getUserList() -> [Any] {
        var userList = [Any]()
        for user in self.userList {
            let data = ["UserKey" : user.userKey, "PositionX" : 0, "PositionY" : 0, "Place" : 0] as [String : Any]
            userList.append(data as Any)
        }
        return userList
    }
    func clone() -> Post{
        let post = Post()
        post.postId = self.postId
        post.merchantId = self.merchantId
        post.postText =  self.postText
        post.postImage = self.postImage
        post.statusId = self.statusId
        post.lastModified = self.lastModified
        post.lastCreated = self.lastCreated
        post.user = self.user
        post.merchant = self.merchant
        post.brandList = []
        for brand in self.brandList {
            post.brandList.append(brand)
        }
        post.merchantList = []
        for merchant in self.merchantList {
            post.merchantList.append(merchant)
        }
        if let skuList = self.skuList {
            post.skuList = []
            for sku in skuList {
                post.skuList?.append(sku)
            }
        }
        
        if let imgs = self.images {
            post.images = []
            for img in imgs {
                post.images?.append(img)
            }
        }
        
        post.userList = []
        for user in userList {
            post.userList.append(user)
        }
        
        post.isExpand = self.isExpand
        post.likeList = []
        
        for user in self.likeList {
            post.likeList.append(user)
        }
        
        post.likeCount = self.likeCount
        post.correlationKey = self.correlationKey
        post.userKey = self.userKey
        post.pendingUploadImage =  self.pendingUploadImage
        post.isMerchantIdentity =  self.isMerchantIdentity
        
        if let postCommentLists = self.postCommentLists {
            post.postCommentLists = []
            for postCommentList in postCommentLists {
                post.postCommentLists?.append(postCommentList)
            }
        }
        post.isHideTag = self.isHideTag
        return post
    }
    
    func isHasComment() -> Bool{
        if let comments = self.postCommentLists?.filter({$0.statusId != Constants.StatusID.deleted.rawValue}) {
            if comments.count != 0{
                return true
            }
        }
        return false
    }
    
    func isHasSkuList() -> Bool{
        if self.skuList == nil || self.skuList?.count == 0 {
            return false
        }
        return true
    }
}

