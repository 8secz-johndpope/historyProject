//
//  FilterColorCell.swift
//  merchant-ios
//
//  Created by Sang Nguyen on 21/01/2016.
//  Copyright © 2016 Sang Nguyen. All rights reserved.
//

import Foundation
class FilterColorCell : UICollectionViewCell {
    var labelName = UILabel()
    var imageView = UIImageView()
    private final let LabelHeight: CGFloat = 24
    override init(frame: CGRect) {
        super.init(frame: frame)
        
        imageView.clipsToBounds = true
        imageView.layer.borderColor = UIColor.secondary1().cgColor
        imageView.layer.borderWidth = 1.0
       
        addSubview(imageView)
        labelName.formatSize(14)
        labelName.textAlignment = .center
        addSubview(labelName)
        layoutSubviews()
    }
    override func layoutSubviews() {
        super.layoutSubviews()
        imageView.frame = CGRect(x: (bounds.maxX - Constants.Value.FilterColorWidth) / 2, y: 0, width: Constants.Value.FilterColorWidth, height: Constants.Value.FilterColorWidth)
        imageView.round()
        labelName.frame = CGRect(x: bounds.minX , y: imageView.frame.maxY + 4 , width: bounds.maxX, height: LabelHeight)
    }
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    func border(){
        imageView.layer.borderColor = UIColor.black.cgColor
    }
    
    func unBorder(){
        imageView.layer.borderColor = UIColor.secondary1().cgColor
    }
}
