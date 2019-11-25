//
//  PersonalInformationSettingNoteCell.swift
//  merchant-ios
//
//  Created by Stephen Yuen on 21/3/2016.
//  Copyright © 2016 WWE & CO. All rights reserved.
//

import UIKit

class PersonalInformationSettingNoteCell: UICollectionViewCell {

    static let CellIdentifier = "PersonalInformationSettingNoteCellID"
    static let DefaultHeight: CGFloat = 11
    
    private final let MarginHorizontal: CGFloat = 11
    
    var noteLabel = UILabel()
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        self.backgroundColor = UIColor.white
        self.clipsToBounds = true
        
        noteLabel.formatNote()
        
        addSubview(noteLabel)
    }
    
    override func layoutSubviews() {
        super.layoutSubviews()
        
        noteLabel.frame = CGRect(x: MarginHorizontal, y: 0, width: bounds.width - (MarginHorizontal * 2), height: bounds.height)
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}
