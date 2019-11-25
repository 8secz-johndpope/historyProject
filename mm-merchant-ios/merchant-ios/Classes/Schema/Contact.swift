//
//  Contact.swift
//  merchant-ios
//
//  Created by khanh.nguyen on 2/8/17.
//  Copyright © 2017 WWE & CO. All rights reserved.
//

import UIKit

class Contact: NSObject {
    
    enum PhoneBookItemType: Int {
        case addall = 0,
        addfriend,
        chatfriend,
        invite
    }
    
    var displayName = ""
    var phoneNumber = ""
    var totalFriendNumber = 0
    var type = PhoneBookItemType.invite
}
