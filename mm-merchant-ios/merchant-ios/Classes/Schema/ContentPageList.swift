//
//  ContentPageList.swift
//  merchant-ios
//
//  Created by Vu Dinh Trung on 6/20/16.
//  Copyright © 2016 WWE & CO. All rights reserved.
//

import UIKit
import ObjectMapper

class ContentPageList: Mappable {
    
    var hitsTotal = 0
    var pageCurrent = 0
    var pageData: [MagazineCover]?
    var pageSize = 0
    var pageTotal = 0
    
    required convenience init?(map: Map) {
        self.init()
    }
    
    // Mappable
    func mapping(map: Map) {
        
        hitsTotal               <- map["HitsTotal"]
        pageCurrent             <- map["PageCurrent"]
        pageData                <- map["PageData"]
        pageSize                <- map["PageSize"]
        pageTotal               <- map["PageTotal"]
        
    }
    
    func isLikedContentPageByContentKey(_ contentKey: String) -> Bool {
        if let data = pageData {
            let index = data.index(where: { (element) -> Bool in
                if element.contentPageKey == contentKey {
                    return true
                }
                return false
                
            })
            
            return index != nil
        }
        return false
    }

}
