//
//  StyleDetailTitleCellModel.swift
//  storefront-ios
//
//  Created by Leslie Zhang on 17/09/2018.
//  Copyright © 2018 WWE & CO. All rights reserved.
//

import UIKit

class StyleDetailTitleCellModel: StyleDetailCellModel {
    override init() {
        super.init()
        
    }
    
    func ssn_cellClass(_ cellID: String, isFloating: Bool) -> AnyClass {
        return StyleDetailTitleCell.self
    }
    
    public var title:String?
}
