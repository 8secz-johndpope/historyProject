//
//  CMSPageProductBannerVerticalCellModel.swift
//  storefront-ios
//
//  Created by Leslie Zhang on 2018/4/16.
//  Copyright © 2018年 WWE & CO. All rights reserved.
//

import UIKit

class CMSPageProductBannerVerticalCellModel: CMSCellModel {
    func ssn_cellClass(_ cellID: String, isFloating: Bool) -> AnyClass {
        return ProductBannerVideoCell.self
    }
    
    public var title: String = ""
    public var subTitle: String = ""
    public var data:[CMSPageDataModel]?
    public var padding:CGFloat = -1.0
}
