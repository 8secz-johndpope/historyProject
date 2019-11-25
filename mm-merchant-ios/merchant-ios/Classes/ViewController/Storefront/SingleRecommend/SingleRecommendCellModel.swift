//
//  SingleRecommendCellModel.swift
//  storefront-ios
//
//  Created by Leslie Zhang on 2018/7/17.
//  Copyright © 2018年 WWE & CO. All rights reserved.
//

import UIKit

class SingleRecommendCellModel: CMSCellModel {
    var cancelTap: (() -> Void)?

    func ssn_cellClass(_ cellID: String, isFloating: Bool) -> AnyClass {
        return SingleRecommendCell.self
    }
    var showCancel:Bool?
}
