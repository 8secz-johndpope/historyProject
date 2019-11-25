//
//  PromotionFooterView.swift
//  merchant-ios
//
//  Created by khanh.nguyen on 5/31/16.
//  Copyright © 2016 WWE & CO. All rights reserved.
//

import UIKit

class PromotionFooterView: UICollectionReusableView {
    
    var titleLabel = UILabel()
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        
        titleLabel.frame = CGRect(x: 0, y: 0, width: frame.width, height: frame.height)
        titleLabel.textAlignment = .center
        titleLabel.formatSize(12)
        titleLabel.textColor = UIColor.secondary2()
        addSubview(titleLabel)
        titleLabel.text = String.localize("LB_CA_CURATOR_PROFILE_RECOM_REM")
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

}
