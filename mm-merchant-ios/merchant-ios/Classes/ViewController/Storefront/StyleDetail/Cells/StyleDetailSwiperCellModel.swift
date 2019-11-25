//
//  StyleDetailSwiperCellModel.swift
//  storefront-ios
//
//  Created by Leslie Zhang on 15/09/2018.
//  Copyright © 2018 WWE & CO. All rights reserved.
//

import UIKit

class StyleDetailSwiperCellModel: StyleDetailCellModel {
    override init() {
        super.init()
    }
    
    func ssn_cellClass(_ cellID: String, isFloating: Bool) -> AnyClass {
        return StyleDetailSwiperCell.self
    }
    
    public var data:[CMSPageDataModel]?
    public var isLocationZeroBanner: Bool = true // 第一次进来banner在0号位 不随机,不滚动
}
