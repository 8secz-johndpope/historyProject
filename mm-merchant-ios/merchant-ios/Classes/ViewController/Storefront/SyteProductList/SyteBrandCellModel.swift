//
//  SyteBrandCellModel.swift
//  storefront-ios
//
//  Created by Leslie Zhang on 2018/8/20.
//  Copyright © 2018年 WWE & CO. All rights reserved.
//

import UIKit

class SyteBrandCellModel: CMSCellModel {
    override init() {
        super.init()
        cellHeight = 76 + 10
        isExclusiveLine = true
    }
    func ssn_cellClass(_ cellID: String, isFloating: Bool) -> AnyClass {
        return SyteBrandCell.self
    }
    var brandList:[Brand]?
}
