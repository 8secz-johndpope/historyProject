//
//  CustomerInfoHeaderView.swift
//  merchant-ios
//
//  Created by Vo Huy Hung on 5/24/16.
//  Copyright © 2016 WWE & CO. All rights reserved.
//

import UIKit

enum CustomerInfoHeaderMode : Int {
    case blank,
    text,
    avatar
}

class CustomerInfoHeaderView: UICollectionReusableView {
    
    var avatarImageView = UIImageView()
    var usernameLabel = UILabel()
    private var label = UILabel()
    
    var singleLabel = UILabel()
    
    var customerInfoHeaderMode : CustomerInfoHeaderMode? {
        didSet {
            if self.customerInfoHeaderMode == CustomerInfoHeaderMode.blank {
                singleLabel.isHidden = true
                avatarImageView.isHidden = true
                usernameLabel.isHidden = true
                label.isHidden = true
            } else if self.customerInfoHeaderMode == CustomerInfoHeaderMode.text {
                singleLabel.isHidden = false
                avatarImageView.isHidden = true
                usernameLabel.isHidden = true
                label.isHidden = true
            } else {
                singleLabel.isHidden = true
                avatarImageView.isHidden = false
                usernameLabel.isHidden = false
                label.isHidden = false
            }
        }
    }
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        
        let padding = CGFloat(15)
        
        singleLabel.frame = CGRect(x: padding, y: 0, width: frame.width - padding, height: frame.height)
        singleLabel.formatSizeBold(14)
        singleLabel.text = String.localize("LB_CS_ENTRY_PT")
        
        let avatarImageViewWidth = CGFloat(80)
        avatarImageView.frame = CGRect(x: padding, y: (frame.height - avatarImageViewWidth)/2, width: avatarImageViewWidth, height: avatarImageViewWidth)
        avatarImageView.layer.cornerRadius = avatarImageViewWidth/2
        avatarImageView.clipsToBounds = true
        avatarImageView.contentMode = .scaleAspectFit
        
        label.frame = CGRect(x: avatarImageView.frame.maxX + 8, y: avatarImageView.frame.minY + 5, width: frame.width - padding, height: 20)
        label.formatSize(14)
        label.textColor = UIColor.secondary3()
        label.text = String.localize("LB_USERNAME")
        
        usernameLabel.frame = CGRect(x: avatarImageView.frame.maxX + 8, y: label.frame.maxY, width: frame.width - padding, height: 20)
        usernameLabel.formatSize(14)
        
        addSubview(singleLabel)
        addSubview(avatarImageView)
        addSubview(usernameLabel)
        addSubview(label)
        
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}
