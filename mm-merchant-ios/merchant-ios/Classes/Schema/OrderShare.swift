//
//  OrderShare.swift
//  merchant-ios
//
//  Created by HungPM on 5/19/16.
//  Copyright © 2016 WWE & CO. All rights reserved.
//

import Foundation

class OrderShare {
    
    var orderType = OrderShareType.Order
    var orderNumber = ""
    var orderReferenceNumber = ""
    var price = Double(0)
    var items: [OrderShareItem]?
    var shouldHideReferenceNumber = false
}
