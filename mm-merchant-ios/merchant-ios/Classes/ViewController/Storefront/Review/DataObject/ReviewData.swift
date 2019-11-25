//
//  ReviewData.swift
//  merchant-ios
//
//  Created by Quang Truong Dinh on 6/1/16.
//  Copyright © 2016 WWE & CO. All rights reserved.
//

import Foundation

class ReviewData {
    
    enum ReviewItemType : Int {
        case unknown = -1
        case productItem = 0
        case rating = 1
        case description = 2
        case photo = 3
    }
    
    var title: String?
    var cellHeight: CGFloat = 0
    var hasBorder = true
    var reuseIdentifier: String?
    var orderItem: OrderItem?
    var ratingValue: Int = 5 //Default 5
    var reviewDescription = ""
    var reviewImages: [UIImage]?
    var dataType: ReviewItemType = .unknown
    
    init(title: String? = nil, cellHeight: CGFloat = 0, hasBorder: Bool = true, reuseIdentifier: String? = nil, orderItem: OrderItem?) {
        self.title = title
        self.cellHeight = cellHeight
        self.hasBorder = hasBorder
        self.reuseIdentifier = reuseIdentifier
        self.orderItem = orderItem
    }
    
}
