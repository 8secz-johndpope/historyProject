//
//  FilterCuratorCollectionViewCell.swift
//  merchant-ios
//
//  Created by khanh.nguyen on 6/9/16.
//  Copyright © 2016 WWE & CO. All rights reserved.
//

import UIKit

class FilterCuratorCollectionViewCell: UICollectionViewCell {
    var label = UILabel()
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        
        label.frame = bounds
        label.formatSmall()
        label.textColor = UIColor.black
        label.textAlignment = .center
        label.backgroundColor = UIColor.clear
        contentView.addSubview(label)
    }
    
    override func layoutSubviews() {
        super.layoutSubviews()
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    
}
