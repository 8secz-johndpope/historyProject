//
//  MerchantReviewData.swift
//  merchant-ios
//
//  Created by Quang Truong Dinh on 6/1/16.
//  Copyright © 2016 WWE & CO. All rights reserved.
//

import Foundation

class MerchantReviewData {
    
    var title: String?
    var cellHeight: CGFloat = 0
    var hasBorder = true
    var reuseIdentifier: String?
    var order: Order?
    var productDescriptionRating: Int = 5
    var serviceRating: Int = 5
    var logisticsRating: Int = 5
    
    init(title: String? = nil, cellHeight: CGFloat = 0, hasBorder: Bool = true, reuseIdentifier: String? = nil, order: Order?) {
        self.title = title
        self.cellHeight = cellHeight
        self.hasBorder = hasBorder
        self.reuseIdentifier = reuseIdentifier
        self.order = order
    }
    
}