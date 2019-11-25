//
//  MMFilterEnum.swift
//  storefront-ios
//
//  Created by Demon on 19/7/18.
//  Copyright © 2018年 WWE & CO. All rights reserved.
//

import Foundation

enum MMFilterType: Int {
    case priceRange = 0
    case gender
    case category
    case brand
    case merchant
    case productTag
    case color
    case count
    
    case unKnow

    var sectionTitle: String {
        switch self {
        case .priceRange:
            return String.localize("LB_CA_FILTER_PRICE_RANGE")
        case .gender:
            return String.localize("LB_CA_FILTER_CATEGORY")
        case .brand:
            return String.localize("LB_CA_FILTER_BRAND")
        case .merchant:
            return String.localize("LB_TICKET_TYPE_MERC")
        case .productTag:
            return String.localize("LB_CA_FILTER_PRODUCT_TAG")
        case .color:
            return String.localize("LB_CA_FILTER_COLOR")
        default:
            return ""
        }
    }
}

enum MMFilterBadgeType: Int {
    case discount = -100
    case overSeas = -101
}

enum MMFilterGenderType {
    case unKnow
    case female
    case male
    case allGender
}

