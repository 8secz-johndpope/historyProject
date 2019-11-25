//
//  CMSPageRankingBannerCellModel.swift
//  storefront-ios
//
//  Created by Leslie Zhang on 2018/6/5.
//  Copyright © 2018年 WWE & CO. All rights reserved.
//

import UIKit

class CMSPageRankingBannerCellModel: CMSCellModel {
    override init() {
        super.init()
        
        isExclusiveLine = true
        cellHeight = ScreenWidth * 1.4
    }
    
    func ssn_cellClass(_ cellID: String, isFloating: Bool) -> AnyClass {
        return CMSPageRankingBannerCell.self
    }
    
    public var title: String = ""
    public var subTitle: String = ""
    public var data:[CMSPageDataModel]?
}
