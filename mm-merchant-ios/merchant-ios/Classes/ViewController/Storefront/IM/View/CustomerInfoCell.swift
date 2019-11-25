//
//  CustomerInfoCell.swift
//  merchant-ios
//
//  Created by Vo Huy Hung on 5/24/16.
//  Copyright © 2016 WWE & CO. All rights reserved.
//

import UIKit

class CustomerInfoCell: UICollectionViewCell {
    
    var titleLabel : UILabel!
    var detailLabel : UILabel!
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        
        let padding = CGFloat(15)
        
        titleLabel = UILabel(frame:CGRect(x: padding, y: 0, width: 100, height: frame.height))
        titleLabel.formatSize(14)
        titleLabel.textColor = UIColor.secondary3()
       
        detailLabel = UILabel(frame:CGRect(x: titleLabel.frame.maxX + padding, y: 0, width: frame.width - titleLabel.frame.maxX, height: frame.height))
        detailLabel.formatSize(14)
        detailLabel.numberOfLines = 0
        detailLabel.textColor = UIColor.secondary2()

        contentView.addSubview(titleLabel)
        contentView.addSubview(detailLabel)
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    func fillData(_ titleStr : String, detailStr : String) {
        titleLabel.text = titleStr
        detailLabel.text = detailStr
    }
    
    
}
