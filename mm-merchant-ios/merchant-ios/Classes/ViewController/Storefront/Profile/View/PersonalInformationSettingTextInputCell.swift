//
//  PersonalInformationSettingTextInputCell.swift
//  merchant-ios
//
//  Created by Stephen Yuen on 21/3/2016.
//  Copyright © 2016 WWE & CO. All rights reserved.
//

import UIKit

class PersonalInformationSettingTextInputCell: UICollectionViewCell {
    
    static let CellIdentifier = "PersonalInformationSettingTextInputCellID"
    static let DefaultHeight: CGFloat = 89  // Actual height: 46, padding: 9

    private final let MarginHorizontal: CGFloat = 11
    private final let MarginVertical: CGFloat = 9

    static let TextFieldHeight = CGFloat(46)
    static let LabelHeight = CGFloat(20)
    var textField = UITextField()
    var label = UILabel()
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        self.backgroundColor = UIColor.white
        self.clipsToBounds = true
        
        textField.format()
        
        label.formatSize(14)
        label.text = String.localize("LB_CA_NICKNAME_NOTE")
        label.textColor = UIColor.secondary3()
        
        addSubview(textField)
        addSubview(label)
    }
    
    override func layoutSubviews() {
        super.layoutSubviews()
        
        textField.frame = CGRect(x: MarginHorizontal, y: MarginVertical, width: bounds.width - (MarginHorizontal * 2), height: PersonalInformationSettingTextInputCell.TextFieldHeight)
        label.frame = CGRect(x: MarginHorizontal, y: textField.frame.maxY + 5, width: bounds.width - (MarginHorizontal * 2), height: PersonalInformationSettingTextInputCell.LabelHeight)
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
}
