//
//  SocialMessage.swift
//  merchant-ios
//
//  Created by HungPM on 9/13/17.
//  Copyright © 2017 WWE & CO. All rights reserved.
//

import Foundation
import ObjectMapper

enum SocialMessageType: Int {
    case postLiked = 1
    case postComment
    case follow
}

class SocialMessage: Mappable {
    
    var socialMessageId = 0
    var socialMessageTypeId = SocialMessageType.postLiked
    var fromUserKey: String?
    var fromDisplayName: String?
    var fromProfileImage: String?
    var entityTypeId = 0
    var entityId = 0
    var entityImage: String?
    var entityText: String?
    var statusId = 0
    var isRead = 0
    var lastCreated = Date()
    
    required convenience init?(map: Map) {
        self.init()
    }
    
    func mapping(map: Map) {
        socialMessageId         <- map["SocialMessageId"]
        socialMessageTypeId     <- (map["SocialMessageTypeId"], EnumTransform())
        fromUserKey             <- map["FromUserKey"]
        fromDisplayName         <- map["FromDisplayName"]
        fromProfileImage        <- map["FromProfileImage"]
        entityTypeId            <- map["EntityTypeId"]
        entityId                <- map["EntityId"]
        entityImage             <- map["EntityImage"]
        entityText              <- map["EntityText"]
        statusId                <- map["StatusId"]
        isRead                  <- map["IsRead"]
        lastCreated             <- (map["LastCreated"], DateTransformExtension(dateFormat: DateTransformExtension.DateFormatStyle.dateTimeSimple))
    }
}
