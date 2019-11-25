//
//  BrandListContentCell.swift
//  storefront-ios
//
//  Created by Leslie Zhang on 2018/7/20.
//  Copyright © 2018年 WWE & CO. All rights reserved.
//

import UIKit

class BrandListContentCell: UITableViewCell {
    
    lazy var cancelButton:ButtonFollow = {
        let cancelButton = ButtonFollow()
        cancelButton.isCollectType = true
        return cancelButton
    }()
    
    lazy var brandNameLabel:UILabel = {
        let brandNameLabel = UILabel()
        brandNameLabel.textColor = UIColor.secondary17()
        brandNameLabel.font = UIFont.systemFont(ofSize: 14)
        brandNameLabel.numberOfLines = 0
        return brandNameLabel
    }()
    
    override init(style: UITableViewCellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)
        
        self.selectionStyle = .none
        
        self.contentView.addSubview(cancelButton)
        self.contentView.addSubview(brandNameLabel)
        
        brandNameLabel.snp.makeConstraints { (make) in
            make.top.equalTo(self.contentView).offset(15)
            make.left.equalTo(15)
            make.right.equalTo(cancelButton.snp.left).offset(-5)
            make.bottom.equalTo(self.contentView).offset(-15)
        }
        cancelButton.snp.makeConstraints { (make) in
            make.right.equalTo(-25)
            make.centerY.equalTo(self.contentView)
            make.width.equalTo(60)
            make.height.equalTo(25)
        }
        
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}
