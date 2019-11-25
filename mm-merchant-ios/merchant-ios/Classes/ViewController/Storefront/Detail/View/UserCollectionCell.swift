//
//  UserCollectionCell.swift
//  merchant-ios
//
//  Created by Koon Kit Chan on 3/12/2015.
//  Copyright © 2015 Koon Kit Chan. All rights reserved.
//

import Foundation
class UserCollectionCell : UICollectionViewCell {
    var userImageView = UIImageView()
    override init(frame: CGRect) {
        super.init(frame: frame)
        backgroundColor = UIColor.white
        userImageView.image = UIImage(named: "placeholder")
        userImageView.layer.borderColor = UIColor.secondary1().cgColor
        userImageView.layer.borderWidth = 1
        addSubview(userImageView)
        layoutSubviews()
    }
    override func layoutSubviews() {
        super.layoutSubviews()
        userImageView.frame = CGRect(x: bounds.minX + 2.5, y: bounds.minY + 5, width: bounds.width - 5, height: bounds.width - 5)
        userImageView.round()
    }
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
}
