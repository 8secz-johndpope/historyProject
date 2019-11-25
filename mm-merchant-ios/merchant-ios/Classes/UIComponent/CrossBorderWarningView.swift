//
//  CrossBorderWarningView.swift
//  storefront-ios
//
//  Created by Kam on 5/9/2018.
//  Copyright © 2018 WWE & CO. All rights reserved.
//

import UIKit

class CrossBorderWarningView: UICollectionReusableView {
    static let ViewIdentifier = "CrossBorderWarningViewID"
//    static let padding = CGFloat(18)

    var icon = UIImageView()
    var titleLabel = UILabel()
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        
        backgroundColor = UIColor(hexString: "F5E5E5")
//        let separatorHeight = CGFloat(1)
//        let padding = CrossBorderWarningView.padding
        icon.image = UIImage(named: "cross_border_warning")
        addSubview(icon)
        
        titleLabel.formatSize(13)
        titleLabel.textAlignment = .left
        titleLabel.textColor = UIColor(hexString: "EA4141")
        titleLabel.text = String.localize("LB_CA_XBORDER_NAME_CONSISTENT_MESSAGE")
        addSubview(titleLabel)
    }
    
    override func layoutSubviews() {
        super.layoutSubviews()
        
        self.icon.snp.makeConstraints { (make) in
            make.left.equalToSuperview().offset(5)
//            make.top.equalToSuperview().offset(5)
            make.centerY.equalToSuperview()
            make.height.equalTo(15)
            make.width.equalTo(15)
        }
        
        self.titleLabel.snp.makeConstraints { [weak self] (make) in
            if let strongSelf = self {
                make.left.equalTo(strongSelf.icon.snp.right).offset(5)
//                make.top.equalToSuperview().offset(5)
                make.centerY.equalToSuperview()
                make.width.equalTo(strongSelf.width - 25)
                make.height.lessThanOrEqualToSuperview().offset(-5)
            }
        }
//        let paddingLeft: CGFloat = 17
//        titleLabel.frame = CGRect(x: paddingLeft, y: 0, width: self.bounds.sizeWidth - 2 * paddingLeft, height: self.bounds.sizeHeight * 0.7)
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}
