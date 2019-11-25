//
//  BadgeCell.swift
//  merchant-ios
//
//  Created by Koon Kit Chan on 19/1/2016.
//  Copyright © 2016 WWE & CO. All rights reserved.
//

import Foundation
class BadgeCell : UICollectionViewCell {
    static let CheckBoxSize = CGSize(width: 15, height: 15)
    
    var imageView = UIImageView()
    var checkBoxImageView = UIImageView(image: UIImage(named: "icon_checkbox_checked"))
    var label = UILabel()
    override init(frame: CGRect) {
        super.init(frame: frame)
        addSubview(imageView)
        addSubview(checkBoxImageView)
        addSubview(label)
        label.formatSize(14)
        label.textAlignment = .center
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override func layoutSubviews() {
        super.layoutSubviews()
        imageView.frame = CGRect(x: bounds.minX, y: bounds.minY + 5, width: bounds.width, height: bounds.height - 10)
        checkBoxImageView.frame = CGRect(x: imageView.frame.maxX - BadgeCell.CheckBoxSize.width - 5, y: imageView.frame.midY - BadgeCell.CheckBoxSize.height/2, width: BadgeCell.CheckBoxSize.width, height: BadgeCell.CheckBoxSize.height)
        imageView.layer.cornerRadius = 5
        if checkBoxImageView.isHidden{
            label.frame = CGRect(x: imageView.frame.minX, y: bounds.minY, width: imageView.bounds.width, height: bounds.height)
        }
        else{
            label.frame = CGRect(x: imageView.frame.minX, y: bounds.minY, width: imageView.bounds.width - BadgeCell.CheckBoxSize.width, height: bounds.height)
        }
    }
    
    func highlight(_ isSelected : Bool){
        if isSelected{
            checkBoxImageView.isHidden = false
            imageView.layer.borderColor = UIColor.primary1().cgColor
            label.frame = CGRect(x: imageView.frame.minX, y: bounds.minY, width: imageView.bounds.width - BadgeCell.CheckBoxSize.width, height: bounds.height)
            label.textColor = UIColor.primary1()
            label.textAlignment = .center
        }else{
            checkBoxImageView.isHidden = true
            imageView.layer.borderColor = UIColor.secondary1().cgColor
            label.frame = CGRect(x: imageView.frame.minX, y: bounds.minY, width: imageView.bounds.width, height: bounds.height)
            label.textColor = UIColor.secondary2()
            label.textAlignment = .center
        }
    }
    
    func border() {
        imageView.layer.borderColor = UIColor.secondary1().cgColor
        imageView.layer.borderWidth = 1
    }
}
