//
//  PredefinedAnswer.swift
//  merchant-ios
//
//  Created by hungvo on 6/23/16.
//  Copyright © 2016 WWE & CO. All rights reserved.
//

import Foundation

import ObjectMapper

class PredefinedAnswer: Mappable {
    
    var merchanAnswerId = 0
    var merchantId = 0
    var merchantAnswerName = ""
    var description = ""
    var image = ""
    var lastCreated = Date()
    var lastModified = Date()
    
    required convenience init?(map: Map) {
        self.init()
    }
    
    func mapping(map: Map) {
        merchanAnswerId             <-  map["MerchantAnswerId"]
        merchantId                  <-  map["MerchantId"]
        merchantAnswerName          <-  map["MerchantAnswerName"]
        description                 <-  map["Description"]
        image                       <-  map["Image"]
        lastCreated                 <-  (map["LastCreated"], IMDateTransform(stringFormat: "yyyy-MM-dd'T'HH:mm:ss"))
        lastModified                <-  (map["LastModified"], IMDateTransform(stringFormat: "yyyy-MM-dd'T'HH:mm:ss"))
    }
    
}
