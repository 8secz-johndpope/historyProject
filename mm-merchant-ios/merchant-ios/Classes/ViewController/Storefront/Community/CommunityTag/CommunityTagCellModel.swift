//
//  CommunityTagCellModel.swift
//  storefront-ios
//
//  Created by Leslie Zhang on 2018/8/6.
//  Copyright © 2018年 WWE & CO. All rights reserved.
//

import UIKit

class CommunityTagCellModel: CMSCellModel {
    override init() {
        super.init()
        cellHeight = 300
        isExclusiveLine = true
    }
    
    func ssn_cellClass(_ cellID: String, isFloating: Bool) -> AnyClass {
        return CommunityTagCell.self
    }
}
