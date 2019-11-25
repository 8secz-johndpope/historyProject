//
//  Identification.swift
//  merchant-ios
//
//  Created by Kam on 2/6/2017.
//  Copyright © 2017 WWE & CO. All rights reserved.
//

import UIKit
import ObjectMapper

class Identification: Mappable {

    var identificationNumber = ""
    var lastName = ""
    var firstName = ""
    
    required convenience init?(map: Map) {
        self.init()
    }
    
    func mapping(map: Map) {
        firstName               <- map["FirstName"]
        lastName                <- map["LastName"]
        identificationNumber    <- map["IdentificationNumber"]
    }
}
