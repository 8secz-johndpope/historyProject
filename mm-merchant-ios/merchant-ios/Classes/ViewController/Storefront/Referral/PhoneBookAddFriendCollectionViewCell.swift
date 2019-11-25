//
//  PhoneBookAddFriendCollectionViewCell.swift
//  merchant-ios
//
//  Created by khanh.nguyen on 2/8/17.
//  Copyright © 2017 WWE & CO. All rights reserved.
//

import UIKit

class PhoneBookAddFriendCollectionViewCell: PhoneBookFriendViewCell {
    var lowerLabel = UILabel()
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        
        lowerLabel.text = ""
        lowerLabel.textColor = UIColor.secondary3()
        lowerLabel.formatSize(11)
        
        contentView.addSubview(lowerLabel)
        
    }
    
    override func layoutSubviews() {
        super.layoutSubviews()
        nameLabel.frame.originY = self.bounds.midY - nameLabel.frame.sizeHeight
        lowerLabel.frame = CGRect(x: Margin.left, y: nameLabel.frame.maxY, width: inviteButton.frame.minX - Margin.left, height: HeightLabel)
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override func setData(_ contact: Contact){
        super.setData(contact)
        lowerLabel.text = contact.phoneNumber
    }
}
