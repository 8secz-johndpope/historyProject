//
//  IDLabelCell.swift
//  merchant-ios
//
//  Created by HungPM on 2/22/16.
//  Copyright © 2016 WWE & CO. All rights reserved.
//

import Foundation

var IDLabelViewHeight = CGFloat(24)

class IDLabelCell : UICollectionViewCell {

    override init(frame: CGRect) {
        super.init(frame: frame)
        
        self.frame = CGRect(x: 0, y: 0, width: frame.width, height: IDLabelViewHeight)
        backgroundColor = UIColor.backgroundGray()
        
        let label = UILabel(frame: self.frame)
        
        label.text = String.localize("LB_CA_ID_CARD_VER_DETAILS")
        
        label.textAlignment = .center
        label.formatSize(10)
        label.textColor = UIColor.secondary2()
        self.contentView.addSubview(label)
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}
