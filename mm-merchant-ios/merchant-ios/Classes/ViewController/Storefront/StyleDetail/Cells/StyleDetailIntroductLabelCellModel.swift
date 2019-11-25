//
//  StyleDetailIntroductLabelCellModel.swift
//  storefront-ios
//
//  Created by Leslie Zhang on 14/09/2018.
//  Copyright © 2018 WWE & CO. All rights reserved.
//

import UIKit

class StyleDetailIntroductLabelCellModel: StyleDetailCellModel {
    override init() {
        super.init()
    }
    
    func ssn_cellClass(_ cellID: String, isFloating: Bool) -> AnyClass {
        return StyleDetailIntroductLabelCell.self
    }
    
    public var skuDesc:String? {
        didSet {
            if let desc = skuDesc {
                let paragraphStyle = NSMutableParagraphStyle()
                paragraphStyle.lineSpacing = 5
                
                let attributes: [NSAttributedStringKey : Any] = [
                    NSAttributedStringKey.font: UIFont(name: "PingFangSC-Light", size: 14)!,
                    NSAttributedStringKey.paragraphStyle:paragraphStyle
                    ]
                let size: CGSize = desc.boundingRect(
                    with: CGSize(width: ScreenWidth - 30, height: CGFloat.greatestFiniteMagnitude),
                    options: NSStringDrawingOptions.usesLineFragmentOrigin,
                    attributes: attributes,
                    context: nil
                    ).size
                let topAndBottomMargin:CGFloat = 30.0
                self.cellHeight = size.height + topAndBottomMargin
            }
        }
    }
}
