//
//  PrivilegeCell.swift
//  merchant-ios
//
//  Created by Quang Truong Dinh on 3/8/17.
//  Copyright © 2017 WWE & CO. All rights reserved.
//

import UIKit

class PrivilegeItemCell: UICollectionViewCell {
    static let CellIdentifier = "PrivilegeItemCellID"
    static let DefaultHeight: CGFloat = 55
    
    private var imageView = UIImageView()
    private var nameLabel = UILabel()
    private var tapGesture = UIGestureRecognizer()

    var loyaltyPrivilege: LoyaltyPrivilege?{
        didSet{
            if let privilege = loyaltyPrivilege?.privilege{
                LoyaltyManager.setPrivilegeImage(imageView, privilegeId: privilege.privilegeId)
                nameLabel.text = privilege.translationCode
            }
        }
    }
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        
        self.addSubview(imageView)
        
        nameLabel.textAlignment = .center
        nameLabel.formatSize(10)
        nameLabel.textColor = UIColor.black
        self.addSubview(nameLabel)
    }
    
    override func layoutSubviews() {
        super.layoutSubviews()
        
        imageView.frame = CGRect(x: (self.width - 34)/2, y: 0, width: 34, height: 22)
        nameLabel.frame = CGRect(x: 0, y: self.frame.height - 30, width: self.width, height: 30)
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    class func getHeight() -> CGFloat{
        return PrivilegeItemCell.DefaultHeight
    }
}
