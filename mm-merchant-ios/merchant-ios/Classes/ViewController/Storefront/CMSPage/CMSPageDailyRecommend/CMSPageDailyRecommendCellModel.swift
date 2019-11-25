//
//  CMSPageDailyRecommendCellModel.swift
//  storefront-ios
//
//  Created by Leslie Zhang on 2018/7/17.
//  Copyright © 2018年 WWE & CO. All rights reserved.
//

import UIKit

class CMSPageDailyRecommendCellModel: CMSCellModel {
    var cancelTap: (() -> Void)?
    
    func ssn_cellClass(_ cellID: String, isFloating: Bool) -> AnyClass {
        return CMSPageDailyRecommendCell.self
    }
    
    public var recommends:[CMSPageComsModel]?
    public var recommendLinks:[String]?
}
