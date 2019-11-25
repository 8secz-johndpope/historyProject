//
//  StyleRealPriceCell.swift
//  storefront-ios
//
//  Created by Leslie Zhang on 2018/9/5.
//  Copyright © 2018年 WWE & CO. All rights reserved.
//

import UIKit

class StyleRealPriceCell: UICollectionViewCell {
    static public let CellIdentifier = "StyleRealPriceCell"
    static public let CellHeight: CGFloat = 28
    var realPrice:String? {
        didSet {
            if let price = realPrice {
                let attr = NSAttributedString(
                    string: price,
                    attributes: [
                        NSAttributedStringKey.foregroundColor: UIColor(hexString: "#999999"),
                        NSAttributedStringKey.strikethroughStyle: NSUnderlineStyle.styleSingle.rawValue,
                        NSAttributedStringKey.font: UIFont.systemFont(ofSize: 12),
                        NSAttributedStringKey.baselineOffset: (UIFont.systemFont(ofSize: 12).capHeight - UIFont.systemFont(ofSize: 12).capHeight) / 2
                    ]
                )
                priceLabel.attributedText = attr
            }
        }
    }
    
    //MARK: - init
    override init(frame: CGRect) {
        super.init(frame: frame)
        
        self.contentView.addSubview(tipLabel)
        self.contentView.addSubview(priceLabel)
        
        tipLabel.snp.makeConstraints { (make) in
            make.left.equalTo(self.contentView).offset(15)
            make.centerY.equalTo(self.contentView)
        }
        priceLabel.snp.makeConstraints { (make) in
            make.left.equalTo(tipLabel.snp.right).offset(2)
            make.centerY.equalTo(self.contentView)
        }
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    //MARK: - lazy
    lazy private var tipLabel:UILabel = {
        let tipLabel = UILabel()
        tipLabel.textColor = UIColor(hexString: "#999999")
        tipLabel.font = UIFont.systemFont(ofSize: 12)
        tipLabel.text = "原价"
        return tipLabel
    }()
    lazy private var priceLabel:UILabel = {
        let priceLabel = UILabel()
        priceLabel.textColor = UIColor(hexString: "#999999")
        priceLabel.font = UIFont.systemFont(ofSize: 12)
        return priceLabel
    }()

}
