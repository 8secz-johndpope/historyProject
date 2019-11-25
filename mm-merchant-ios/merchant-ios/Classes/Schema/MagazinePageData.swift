//
//  MagazinePageData.swift
//  merchant-ios
//
//  Created by Quang Truong Dinh on 5/18/16.
//  Copyright © 2016 WWE & CO. All rights reserved.
//

import Foundation

import Foundation
import ObjectMapper

class MagazinePageData: Mappable {
    
    var contentPageCollection: ContentPageCollection?
    var contentPages: [MagazineCover]?
    
    required convenience init?(map: Map) {
        self.init()
    }
    
    // Mappable
    func mapping(map: Map) {
        
        contentPageCollection       <- map["ContentPageCollection"]
        contentPages                <- map["ContentPages"]
    }
}
