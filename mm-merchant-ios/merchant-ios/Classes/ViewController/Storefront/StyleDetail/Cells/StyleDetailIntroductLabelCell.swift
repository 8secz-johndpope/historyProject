//
//  StyleDetailIntroductLabelCell.swift
//  storefront-ios
//
//  Created by Leslie Zhang on 14/09/2018.
//  Copyright © 2018 WWE & CO. All rights reserved.
//

import UIKit

class StyleDetailIntroductLabelCell: UICollectionViewCell {

    //MARK: - init
    override init(frame: CGRect) {
        super.init(frame: frame)
        
        self.contentView.addSubview(contentLabel)
        
        contentLabel.snp.makeConstraints { (make) in
            make.top.equalTo(self.contentView).offset(15)
            make.left.equalTo(self.contentView).offset(15)
            make.right.equalTo(self.contentView).offset(-15)
            make.bottom.equalTo(self.contentView).offset(-15)
        }
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override func ssn_onDisplay(_ tableView: UIScrollView, model: AnyObject, atIndexPath indexPath: IndexPath, reused: Bool) {
        if let cellModel = model as? StyleDetailIntroductLabelCellModel {
            if let desc = cellModel.skuDesc {
                let paragraphStyle = NSMutableParagraphStyle()
                paragraphStyle.lineSpacing = 5
                let attrString = NSMutableAttributedString(string: desc)
                attrString.addAttribute(NSAttributedStringKey.paragraphStyle, value:paragraphStyle, range:NSRange(location: 0, length: attrString.length))
                contentLabel.attributedText = attrString
            }
        }
    }
    
    //MARK: - lazy
    lazy private var contentLabel:UILabel = {
        let contentLabel = UILabel()
        contentLabel.font = UIFont(name: "PingFangSC-Light", size: 14)
        contentLabel.numberOfLines = 0
        return contentLabel
    }()
}
