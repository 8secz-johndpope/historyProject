//
//  Banner.swift
//  merchant-ios
//
//  Created by Gam Bogo on 5/16/16.
//  Copyright © 2016 WWE & CO. All rights reserved.
//

import Foundation
import ObjectMapper

enum BannerType : Int {
    case normal = 1
    case redZoneProduct = 2
    case blackZoneProduct = 3
}


enum BannerCollectionType: Int {
    case unknown = 0
    case newsFeed
    case discover
    case shoppingCart
    case magazine
    case profileBanner
    case gridBanner
    case referralCouponPage = 8
    case referralCouponSNS
    
    case redZoneProduct = 10
    case blackZoneProduct = 11
    case redZoneShortcut = 12
    case blackZoneShortcut = 13
    
    case blackZoneTop = 14
    case blackZoneSub = 15
    case popUpBanner = 16
}


struct SkuItem : Mappable {
    var skuID = 0
    var productImageKey : String?
    var style: Style?
    
    init?(map: Map) {
        
    }
    
    mutating func mapping(map: Map) {
        skuID               <- map["SkuId"]
        productImageKey     <- map["ProductImage"]
    }
    
}

class Banner: Mappable {
    
    var bannerId = 0
    var bannerKey = ""
    var bannerImage = ""
    var bannerName = ""
    var link = ""
    
    var collectionType: BannerCollectionType = .unknown
    var bannerType : BannerType = .normal
    var skuList = [SkuItem]()
    
    required convenience init?(map: Map) {
        self.init()
    }
    
    // Mappable
    func mapping(map: Map) {
        bannerId        <- map["BannerId"]
        bannerKey       <- map["BannerKey"]
        bannerImage     <- map["BannerImage"]
        bannerName      <- map["BannerName"]
        link            <- map["Link"]
        collectionType  <- (map["BannerCollectionId"], EnumTransform())
        bannerType      <- (map["BannerTypeId"], EnumTransform())
        skuList         <- map["SkuList"]
    }
    
    
    func itemPerRow() -> Int {
        var count  = 3
        if bannerType == .redZoneProduct {
            count = 3
        } else if bannerType == .blackZoneProduct {
            count = 2
        }
        let items = min(count, skuList.count)
        return max(1, items)
    }
    
    func cacheableObject() -> BannerCacheObject {
        return BannerCacheObject(banner: self)
    }
    
}
