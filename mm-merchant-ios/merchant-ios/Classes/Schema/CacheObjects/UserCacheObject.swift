//
//  UserCacheObject.swift
//  merchant-ios
//
//  Created by Alan YU on 1/6/2016.
//  Copyright © 2016 WWE & CO. All rights reserved.
//

import Foundation
import RealmSwift
import ObjectMapper

class UserCacheObject: Object {
    
    @objc dynamic var userKey: String?
    @objc dynamic var jsonString: String?
    
    convenience init(user: User) {
        self.init()
        self.userKey = user.userKey
        
        self.jsonString = Mapper().toJSONString(user, prettyPrint: false)
    }
    
    override static func primaryKey() -> String? {
        return "userKey"
    }

    func object() -> User? {
        if let string = jsonString {
            return Mapper<User>().map(JSONString: string)
        }
        return nil
    }
    
}
