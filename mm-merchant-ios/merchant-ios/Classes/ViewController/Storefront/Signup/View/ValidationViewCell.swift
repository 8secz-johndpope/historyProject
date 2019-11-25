//
//  OutfitBrandViewCell.swift
//  merchant-ios
//
//  Created by Vu Dinh Trung on 4/14/16.
//  Copyright © 2016 WWE & CO. All rights reserved.
//

import UIKit


class ValidationViewCell: UICollectionViewCell {
    static let CellIdentifier = "ValidationViewCellId"
    static let ImageWidth : CGFloat = 15
    static let FontSize = 12
    static let Spacing: CGFloat = 4
    var imageView = UIImageView()
    var upperLabel = UILabel()
   
   
    override init(frame: CGRect) {
        super.init(frame: frame)
        backgroundColor = UIColor.white
        imageView.image = UIImage(named: "checkbox_gray_small")
        imageView.contentMode = .scaleAspectFill
        addSubview(imageView)
        upperLabel.formatSize(ValidationViewCell.FontSize)
        upperLabel.textAlignment = .left
        addSubview(upperLabel)
    }
    
    override func layoutSubviews() {
        super.layoutSubviews()
        let imageWidth = ValidationViewCell.ImageWidth
        imageView.frame = CGRect(x: 0, y: (bounds.height - imageWidth) / 2 , width: imageWidth, height: imageWidth)
        upperLabel.frame = CGRect(x: imageView.frame.maxX + ValidationViewCell.Spacing, y: 0 , width: bounds.width - imageWidth, height: bounds.height)
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    
    //MARK: - setup data
    
    func setValid(_ isValid: Bool){
        if isValid {
            imageView.image = UIImage(named: "checkbox_gray_small_selected")
        } else {
            imageView.image = UIImage(named: "checkbox_gray_small")
        }
        
    }
}
