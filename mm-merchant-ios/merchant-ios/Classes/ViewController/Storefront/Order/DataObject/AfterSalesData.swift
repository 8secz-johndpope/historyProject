//
//  AfterSalesData.swift
//  merchant-ios
//
//  Created by Stephen Yuen on 16/5/2016.
//  Copyright © 2016 WWE & CO. All rights reserved.
//

import UIKit

class AfterSalesData {
    
    var title: String?
    var cellHeight: CGFloat = 0
    var hasBorder = true
    var reuseIdentifier: String?
    
    init(title: String? = nil, cellHeight: CGFloat = 0, hasBorder: Bool = true, reuseIdentifier: String? = nil) {
        self.title = title
        self.cellHeight = cellHeight
        self.hasBorder = hasBorder
        self.reuseIdentifier = reuseIdentifier
    }
    
}
