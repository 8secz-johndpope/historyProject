//
//  SearchTerm.swift
//  merchant-ios
//
//  Created by Koon Kit Chan on 6/1/2016.
//  Copyright © 2016 Koon Kit Chan. All rights reserved.
//

import Foundation
import ObjectMapper

class SearchTerm : Mappable{
    var entityId = 0
    var entity = ""
    var searchTerm = ""
    var searchTermIn = ""
    var entityImage = ""
    
    required convenience init?(map: Map) {
        self.init()
    }
    
    // Mappable
    func mapping(map: Map) {
        entityId                <- map["EntityId"]
        entity                  <- map["Entity"]
        searchTermIn            <- map["SearchTermIn"]
        searchTerm              <- map["SearchTerm"]
        entityImage             <- map["EntityImage"]
    }

}
