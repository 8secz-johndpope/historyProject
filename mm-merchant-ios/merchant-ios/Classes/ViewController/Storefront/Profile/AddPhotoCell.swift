//
//  AddPhotoCell.swift
//  merchant-ios
//
//  Created by khanh.nguyen on 5/17/17.
//  Copyright © 2017 WWE & CO. All rights reserved.
//

import UIKit

class AddPhotoCell: UICollectionViewCell {
    
    static let CellIdentifier = "CellIdentifier"
    var imageBackground = UIImageView()
    var iconImageview = UIImageView()
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        
        imageBackground.backgroundColor = UIColor.secondary11()
        
        iconImageview.image = UIImage(named: "icon_plus_grey")
        
        self.addSubview(imageBackground)
        self.addSubview(iconImageview)
    }
    override func layoutSubviews() {
        super.layoutSubviews()
        
        imageBackground.frame = CGRect(x: Margin.left / 2, y: Margin.left / 2, width: bounds.width - Margin.left , height: bounds.height - Margin.left)
        let width = CGFloat(12)
        iconImageview.frame = CGRect(x: (self.bounds.sizeWidth - width) / 2, y: (self.bounds.sizeHeight - width) / 2, width: width, height: width)
        
    }
}
