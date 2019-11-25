//
//  IMFilterHeaderView.swift
//  merchant-ios
//
//  Created by Vo Huy Hung on 5/16/16.
//  Copyright © 2016 WWE & CO. All rights reserved.
//

import UIKit

class IMFilterHeaderView: UICollectionReusableView {
    var titleLabel = UILabel()
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        backgroundColor = UIColor.white
        
        let padding = CGFloat(20)
        titleLabel.frame = CGRect(x: padding, y: 0, width: frame.width - padding, height: frame.height)
        titleLabel.textAlignment = .left
        titleLabel.formatSize(15)
        addSubview(titleLabel)
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}
