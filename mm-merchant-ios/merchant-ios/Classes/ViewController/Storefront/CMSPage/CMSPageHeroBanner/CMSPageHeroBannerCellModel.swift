//
//  CMSPageHeroBannerCellModel.swift
//  MMDemoForLeslie_Swift4.0
//
//  Created by Leslie Zhang on 2018/3/26.
//  Copyright © 2018年 Leslie Zhang. All rights reserved.
//

import UIKit

class CMSPageHeroBannerCellModel: CMSCellModel {
    
    override init() {
        super.init()
        isExclusiveLine = true
        cellHeight = ScreenWidth * 1.4
    }
    
    func ssn_cellClass(_ cellID: String, isFloating: Bool) -> AnyClass {
        return CMSPageHeroBannerCell.self
    }
    
    public var title: String = ""
    public var subTitle: String = ""
    public var data:[CMSPageDataModel]?
}

