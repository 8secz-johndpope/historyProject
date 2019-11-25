//
//  MerchantSummaryResponse.swift
//  merchant-ios
//
//  Created by Vu Dinh Trung on 8/17/16.
//  Copyright © 2016 WWE & CO. All rights reserved.
//

import Foundation
import ObjectMapper

class MerchantSummaryResponse: Mappable {

    @objc dynamic var reviewCount = 0
    @objc dynamic var ratingProductDescriptionAverage: CGFloat = 0.0
    @objc dynamic var ratingServiceAverage: CGFloat = 0.0
    @objc dynamic var ratingLogisticsAverage: CGFloat = 0.0
    
    required convenience init?(map: Map) {
        self.init()
    }
    
    // Mappable
    func mapping(map: Map) {
        reviewCount <- map["ReviewCount"]
        ratingProductDescriptionAverage <- map["RatingProductDescriptionAverage"]
        ratingServiceAverage <- map["RatingServiceAverage"]
        ratingLogisticsAverage <- map["RatingLogisticsAverage"]
    }
}
