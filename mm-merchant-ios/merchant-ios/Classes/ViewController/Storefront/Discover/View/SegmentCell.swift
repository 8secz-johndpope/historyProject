//
//  SegmentCell.swift
//  merchant-ios
//
//  Created by Koon Kit Chan on 24/11/15.
//  Copyright © 2015 Koon Kit Chan. All rights reserved.
//

import Foundation

class SegmentCell : UICollectionViewCell {
    var customSC : UISegmentedControl!
    
    override init(frame: CGRect) {
        super.init(frame: frame)

        customSC = UISegmentedControl(items: ["First","Second","Third"])
        customSC.selectedSegmentIndex = 0
        customSC.frame = CGRect(x: 10, y: bounds.minY + 10, width: bounds.width - 20, height: bounds.height - 20)
        customSC.backgroundColor = UIColor.white
        customSC.tintColor = UIColor.primary1()
        customSC.layer.cornerRadius = 5.0
        addSubview(customSC)
        
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}
