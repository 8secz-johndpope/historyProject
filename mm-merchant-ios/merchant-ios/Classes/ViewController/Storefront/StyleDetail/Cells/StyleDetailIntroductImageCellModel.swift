//
//  StyleDetailIntroductImageCellModel.swift
//  storefront-ios
//
//  Created by Leslie Zhang on 14/09/2018.
//  Copyright © 2018 WWE & CO. All rights reserved.
//

import UIKit

class StyleDetailIntroductImageCellModel: StyleDetailCellModel {
    override init() {
        super.init()
    }
    
    func ssn_cellClass(_ cellID: String, isFloating: Bool) -> AnyClass {
        return StyleDetailIntroductImageCell.self
    }
    
    public var imageData:Img? {
        didSet {
            if let data = imageData {
                var whratio: Float = 1.0
                let imageHeight = ScreenWidth
                if let r = data.imageKey.whratio() {
                    whratio = r
                }
                self.cellHeight = imageHeight * CGFloat(whratio)
            }
        }
    }
}
