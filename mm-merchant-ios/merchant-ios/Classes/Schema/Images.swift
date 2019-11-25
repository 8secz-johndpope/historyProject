//
//  Images.swift
//  merchant-ios
//
//  Created by Leslie Zhang on 2018/1/16.
//  Copyright © 2018年 WWE & CO. All rights reserved.
//

import UIKit
import ObjectMapper

class Images: Mappable {

    
    var image:String?
    var upImage:UIImage?
    //    var images = [UIImage]()

    var tags: [ImagesTags]?
    var skuList:[Sku]?
    var brandList:[Brand]?
    

    required convenience init?(map: Map) {
        self.init()
    }
    // Mappable
    func mapping(map: Map) {
        image             <- map["Image"]
        tags              <- map["Tags"]
        skuList           <- map["SkuList"]
        brandList         <- map["BrandList"]
    }
}

class ImagesTags: Mappable {
    var id = 0
    var positionX = 0
    var positionY  = 0
    var place = TagPlace.undefined
    var postTag:ProductTagStyle = .Commodity
    var title = ""
    var tagTitle = ""
    var tagImage = ""
    var sku:Sku?
    var brand:Brand?
    var iamgeFrame:CGRect = CGRect.zero
    
    required convenience init?(map: Map) {
        self.init()
    }
    // Mappable
    func mapping(map: Map) {
        id             <- map["Id"]
        positionX      <- map["PositionX"]
        positionY      <- map["PositionY"]
        place          <- map["Place"]
        postTag           <- map["PostTag"]
    }
    
}


