//
//  StyleBrandCell.swift
//  storefront-ios
//
//  Created by Leslie Zhang on 2018/9/3.
//  Copyright © 2018年 WWE & CO. All rights reserved.
//

import UIKit

class StyleBrandCell: UICollectionViewCell {
    static public let CellIdentifier = "StyleBrandCell"
    static public let CellHeight: CGFloat = 40
    public var brandName:String? {
        didSet {
            if let str = brandName {
                brandLabel.text = str
            }
        }
    }
    
    //MARK: - init
    override init(frame: CGRect) {
        super.init(frame: frame)
        
        self.contentView.backgroundColor = UIColor(hexString: "#FAFAFA")
        self.contentView.addSubview(tipLabel)
        self.contentView.addSubview(brandIconImageView)
        self.contentView.addSubview(brandLabel)
        self.contentView.addSubview(rightIconImageView)
        
        tipLabel.snp.makeConstraints { (make) in
            make.left.equalTo(15)
            make.centerY.equalTo(self.contentView)
        }
        brandIconImageView.snp.makeConstraints { (make) in
            make.centerY.equalTo(self.contentView)
            make.left.equalTo(tipLabel.snp.right).offset(10)
        }
        brandLabel.snp.makeConstraints { (make) in
            make.centerY.equalTo(self.contentView)
            make.left.equalTo(brandIconImageView.snp.right).offset(6)
            make.width.equalTo(ScreenWidth * 0.7)
        }
        rightIconImageView.snp.makeConstraints { (make) in
            make.centerY.equalTo(self.contentView)
            make.right.equalTo(self.contentView).offset(-15)
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
        tipLabel.text = String.localize("LB_CA_FILTER_BRAND")
        return tipLabel
    }()
    lazy private var brandIconImageView:UIImageView = {
        let brandIconImageView = UIImageView()
        brandIconImageView.image = UIImage(named: "brand_tag")
        brandIconImageView.sizeToFit()
        return brandIconImageView
    }()
    lazy private var brandLabel:UILabel = {
        let brandLabel = UILabel()
        brandLabel.textColor = UIColor(hexString: "#333333")
        brandLabel.font = UIFont.systemFont(ofSize: 14)
        return brandLabel
    }()
    lazy private var rightIconImageView:UIImageView = {
        let rightIconImageView = UIImageView()
        rightIconImageView.image = UIImage(named: "arrow_right")
        rightIconImageView.sizeToFit()
        return rightIconImageView
    }()
}
