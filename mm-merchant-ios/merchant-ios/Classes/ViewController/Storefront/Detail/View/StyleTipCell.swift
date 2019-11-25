//
//  StyleTipCell.swift
//  storefront-ios
//
//  Created by Leslie Zhang on 2018/9/5.
//  Copyright © 2018年 WWE & CO. All rights reserved.
//

import UIKit

class StyleTipCell: UICollectionViewCell {
    static public let CellIdentifier = "StyleTipCell"
    static public let CellHeight: CGFloat = 50
    //MARK: - init
    override init(frame: CGRect) {
        super.init(frame: frame)
        
        self.contentView.addSubview(bgView)
        bgView.addSubview(iconImageView)
        bgView.addSubview(tipLabel)

        bgView.snp.makeConstraints { (make) in
            make.left.equalTo(self.contentView).offset(15)
            make.right.equalTo(self.contentView).offset(-15)
            make.top.equalTo(self.contentView).offset(8)
            make.bottom.equalTo(self.contentView)
        }
        iconImageView.snp.makeConstraints { (make) in
            make.left.equalTo(bgView).offset(12)
            make.top.equalTo(bgView).offset(8)
        }
        tipLabel.snp.makeConstraints { (make) in
            make.left.equalTo(iconImageView.snp.right).offset(6)
            make.top.equalTo(bgView).offset(6)
            make.width.equalTo((ScreenWidth - 30) * 0.9)
        }
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    //MARK: - lazy
    lazy private var bgView:UIView = {
        let bgView = UIView()
        bgView.backgroundColor = UIColor(hexString: "#FFF5DC")
        return bgView
    }()
    lazy private var iconImageView:UIImageView = {
        let iconImageView = UIImageView()
        iconImageView.image = UIImage(named: "hint_ic")
        iconImageView.sizeToFit()
        return iconImageView
    }()
    lazy private var tipLabel:UILabel = {
        let tipLabel = UILabel()
        tipLabel.text = String.localize("LB_CA_PDP_ESTIMATED_PRICE_DESC")
        tipLabel.font = UIFont.systemFont(ofSize: 12)
        tipLabel.textColor = UIColor(hexString: "#C19650")
        tipLabel.numberOfLines = 0
        tipLabel.textAlignment = .left
        return tipLabel
    }()
}
