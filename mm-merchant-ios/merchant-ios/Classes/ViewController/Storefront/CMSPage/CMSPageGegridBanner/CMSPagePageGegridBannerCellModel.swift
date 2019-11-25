//
//  CMSPagePageGegridBannerCellModel.swift
//  MMDemoForLeslie_Swift4.0
//
//  Created by Leslie Zhang on 2018/3/26.
//  Copyright © 2018年 Leslie Zhang. All rights reserved.
//

import UIKit

class CMSPagePageGegridBannerCellModel: CMSCellModel {
    func ssn_cellClass(_ cellID: String, isFloating: Bool) -> AnyClass {
        return CMSPagePageGegridBannerCell.self
    }
    
    public var title: String = ""
    public var subTitle: String = ""
    public var data:[CMSPageDataModel]?
    public var border:CGFloat = 0.0
}
