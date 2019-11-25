//
//  NameSettingViewCell.swift
//  merchant-ios
//
//  Created by Markus Chow on 12/8/2016.
//  Copyright © 2016 WWE & CO. All rights reserved.
//

import Foundation

class NameSettingViewCell: UICollectionViewCell {
	
	
    static let CellIdentifier = "NameSettingViewCellID"
    static let DefaultHeight: CGFloat = 64  // Actual height: 46, padding: 9
    
    private final let MarginHorizontal: CGFloat = 11
    private final let MarginVertical: CGFloat = 9
    
    var textField = UITextField()
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        self.backgroundColor = UIColor.white
        self.clipsToBounds = true
        
        textField.format()
        
        addSubview(textField)
    }
    
    override func layoutSubviews() {
        super.layoutSubviews()
        
        textField.frame = CGRect(x: MarginHorizontal, y: MarginVertical, width: bounds.width - (MarginHorizontal * 2), height: bounds.height - (MarginVertical * 2))
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

	
	
}
