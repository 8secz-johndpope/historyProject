//
//  IMSystemMessage.swift
//  merchant-ios
//
//  Created by Alan YU on 4/5/2016.
//  Copyright © 2016 WWE & CO. All rights reserved.
//

import Foundation

class IMSystemMessage: IMMessage {
    
    func JSONUserList(_ userList: [UserRole]?) -> [[String: Any]] {
        var roleJSON = [[String: Any]]()
        if let list = userList {
            for role in list {
                roleJSON.append([
                    "UserKey": JSONOptionalValue(role.userKey),
                    "MerchantId": JSONOptionalValue(role.merchantId),
                    ])
            }
        }
        return roleJSON
    }
    
}
