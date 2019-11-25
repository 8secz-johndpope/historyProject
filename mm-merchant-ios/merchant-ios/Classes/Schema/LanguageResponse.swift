//
//  LanguageResponse.swift
//  merchant-ios
//
//  Created by Koon Kit Chan on 2/11/15.
//  Copyright © 2015 Koon Kit Chan. All rights reserved.
//

import Foundation
import ObjectMapper

class LanguageResponse: Mappable{
    
    var languageList : [Language] = []
    
    required convenience init?(map: Map) {
        self.init()
    }
    
    // Mappable
    func mapping(map: Map) {
        languageList         <- map["LanguageList"]

    }
}
