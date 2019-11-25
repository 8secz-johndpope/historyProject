//
//  CuratorBarViewCell.swift
//  merchant-ios
//
//  Created by Vu Dinh Trung on 6/1/16.
//  Copyright © 2016 WWE & CO. All rights reserved.
//

import UIKit



class CuratorBarViewCell: UICollectionViewCell {
    
    static let CellId = "CuratorBarViewCell"
    static let heightCell = CGFloat(44)
    private let heightLabel = CGFloat(22)
    var photoLabel = UILabel()
    
    var maxImageLabel = UILabel()
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        
        let text = String.localize("LB_CA_PHOTO")
        photoLabel.applyFontSize(15, isBold: true)
        photoLabel.text = text
        addSubview(photoLabel)
        
        let strMax = String.init(format: "%d/%d", 0, Constants.LimitNumber.ImagesNumber)
        
        maxImageLabel.formatSize(13)
        maxImageLabel.textAlignment = .right
        maxImageLabel.text = strMax
        self.addSubview(maxImageLabel)
        self.backgroundColor = UIColor.secondary5()
        
    }
    
    override func layoutSubviews() {
        super.layoutSubviews()
        
        if let text = photoLabel.text{
            photoLabel.frame = CGRect(x: Margin.left, y: (bounds.height - heightLabel) / 2, width: StringHelper.getTextWidth(text, height: heightLabel, font: photoLabel.font), height: heightLabel)
        }
        
        let widthText = CGFloat(40)
        maxImageLabel.frame = CGRect(x: self.bounds.width - widthText - Margin.right, y: (bounds.height - heightLabel) / 2, width: widthText, height: heightLabel)
    }
    
}
