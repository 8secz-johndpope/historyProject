//
//  BannerCacheObject.swift
//  merchant-ios
//
//  Created by khanh.nguyen on 9/5/17.
//  Copyright © 2017 WWE & CO. All rights reserved.
//

import UIKit
import RealmSwift
import ObjectMapper
import Foundation
class BannerCacheObject: Object {
    
    @objc dynamic var bannerKey: String?
    @objc dynamic var jsonString: String?
    
    convenience init(banner: Banner) {
        self.init()
        self.bannerKey = String(banner.bannerKey)
        
        self.jsonString = Mapper().toJSONString(banner, prettyPrint: false)
    }
    
    override static func primaryKey() -> String? {
        return "bannerKey"
    }
    
    func object() -> Banner? {
        if let string = jsonString {
            return Mapper<Banner>().map(JSONString: string)
        }
        return nil
    }

}
