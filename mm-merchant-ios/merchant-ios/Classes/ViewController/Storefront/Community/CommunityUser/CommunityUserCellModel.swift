//
//  CommunityUserCellModel.swift
//  storefront-ios
//
//  Created by Leslie Zhang on 2018/8/6.
//  Copyright © 2018年 WWE & CO. All rights reserved.
//

import UIKit

class CommunityUserCellModel: CMSCellModel {
    override init() {
        super.init()
        cellHeight = CuratorCell.curatorCellHeight()
        isExclusiveLine = true
    }
    func ssn_cellClass(_ cellID: String, isFloating: Bool) -> AnyClass {
        return CuratorsCell.self
    }
    var userList:[User]?
}
