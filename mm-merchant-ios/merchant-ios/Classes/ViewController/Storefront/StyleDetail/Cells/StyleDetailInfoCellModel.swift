//
//  StyleDetailInfoCellModel.swift
//  storefront-ios
//
//  Created by Leslie Zhang on 15/09/2018.
//  Copyright © 2018 WWE & CO. All rights reserved.
//

import UIKit

class StyleDetailInfoCellModel: StyleDetailCellModel {
    override init() {
        super.init()
        
        cellHeight = 28 + 60 + 40
    }
    
    func ssn_cellClass(_ cellID: String, isFloating: Bool) -> AnyClass {
        return StyleDetailInfoCell.self
    }
    public var style:Style?
    weak var delegate:StyleDetailInfoCellDelegage?
}
