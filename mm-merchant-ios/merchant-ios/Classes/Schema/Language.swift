//
//  Language.swift
//  merchant-ios
//
//  Created by Koon Kit Chan on 2/11/15.
//  Copyright © 2015 Koon Kit Chan. All rights reserved.
//

import Foundation
import ObjectMapper
import RealmSwift

class Language: Mappable {
    
    var languageId = 0
    var cultureCode = ""
    var languageName = ""
    
    
    required convenience init?(map: Map) {
        self.init()
    }
    
    // Mappable
    func mapping(map: Map) {
        languageId         <- map["LanguageId"]
        cultureCode        <- map["CultureCode"]
        languageName       <- map["LanguageName"]
    }
}
