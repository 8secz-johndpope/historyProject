//
//  OrderDetailData.swift
//  merchant-ios
//
//  Created by Quang Truong Dinh on 4/7/16.
//  Copyright © 2016 WWE & CO. All rights reserved.
//

import Foundation

class OrderDetailData {
    
    var title = ""
    var value = ""
    
    init (title: String?, value: String?) {
        self.title = title ?? ""
        self.value = value ?? ""
    }
    
}
