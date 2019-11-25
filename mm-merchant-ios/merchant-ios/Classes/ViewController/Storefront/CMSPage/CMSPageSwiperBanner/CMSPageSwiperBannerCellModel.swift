//
//  CMSPageSwiperBannerCellModel.swift
//  MMDemoForLeslie_Swift4.0
//
//  Created by Leslie Zhang on 2018/3/26.
//  Copyright © 2018年 Leslie Zhang. All rights reserved.
//

import UIKit

class CMSPageSwiperBannerCellModel: CMSCellModel {
    
    func ssn_cellClass(_ cellID: String, isFloating: Bool) -> AnyClass {
        return CMSPageSwiperBannerCell.self
    }
    
    public var subTitle: String = ""
    public var data:[CMSPageDataModel]?
    public var isLocationZeroBanner: Bool = true // 第一次进来banner在0号位 不随机,不滚动
}
