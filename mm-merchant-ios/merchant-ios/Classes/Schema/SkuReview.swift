//
//  SkuReview.swift
//  merchant-ios
//
//  Created by Gam Bogo on 6/23/16.
//  Copyright © 2016 WWE & CO. All rights reserved.
//

import Foundation
import ObjectMapper

class SkuReview : Mappable {
    var merchantId = 0
    var skuId = 0
    var styleCode = ""
    var userKey = ""
    var userName = ""
    var userDisplayName = ""
    var userProfileImage = ""
    var rating = 0
    var description = ""
    var statusId = 0
    var image1 = ""
    var image2 = ""
    var image3 = ""
    var lastCreated = Date()
    var lastModified = Date()
    var replyUserId = 0
    var replyMerchantid = 0
    var replyDescription = ""
    var replyCreated = Date()
    
    var total = 0
    var correlationKey = ""
    var skuReviewId = 0
    var productImage = ""
    var skuName = ""
    var sizeName = ""
    var colorName = ""
    var skuReviewKey = ""
    var isCurator = 0
    var isMerchant = 0
    
    required convenience init?(map: Map) {
        self.init()
    }
    
    // Mappable
    func mapping(map: Map) {
        merchantId                  <- map["MerchantId"]
        skuId                       <- map["SkuId"]
        styleCode                   <- map["StyleCode"]
        userKey                     <- map["UserKey"]
        userName                    <- map["UserName"]
        userDisplayName             <- map["DisplayName"]
        userProfileImage            <- map["ProfileImage"]
        rating                      <- map["Rating"]
        description                 <- map["Description"]
        statusId                    <- map["StatusId"]
        image1                      <- map["Image1"]
        image2                      <- map["Image2"]
        image3                      <- map["Image3"]
        lastCreated                 <- (map["LastCreated"], DateTransformExtension(dateFormat: DateTransformExtension.DateFormatStyle.dateTimeSimple))
        lastModified                <- (map["LastModified"], DateTransformExtension(dateFormat: DateTransformExtension.DateFormatStyle.dateTimeSimple))
        replyUserId                 <- map["ReplyUserId"]
        replyMerchantid             <- map["ReplyMerchantId"]
        replyDescription            <- map["ReplyDescription"]
        replyCreated                <- (map["ReplyCreated"], DateTransformExtension(dateFormat: DateTransformExtension.DateFormatStyle.dateTimeSimple))
        total                       <- map["Total"]
        correlationKey              <- map["CorrelationKey"]
        skuReviewId                 <- map["SkuReviewId"]
        
        productImage                <- map["ProductImage"]
        skuName                     <- map["SkuName"]
        sizeName                    <- map["SizeName"]
        colorName                   <- map["ColorName"]
        skuReviewKey                <- map["SkuReviewKey"]
        isCurator                   <- map["IsCurator"]
        isMerchant                  <- map["IsMerchant"]
    }
    
    func getImages() ->  [String] {
        let images = [self.image1, self.image2, self.image3 ]
        var validImages = [String]()
        
        for image in images {
            if !image.isEmpty {
                validImages.append(image)
            }
        }
        
        return validImages
    }
    
    func userTypeString() -> String{
        var type = "User"
        if isCurator == 1 {
            type = "Curator"
        }
        else if isMerchant == 1 {
            type = "MerchantUser"
        }
        return type
    }
}
