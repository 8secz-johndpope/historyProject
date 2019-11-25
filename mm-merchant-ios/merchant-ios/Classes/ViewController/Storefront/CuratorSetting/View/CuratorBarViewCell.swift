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
    var labelPhoto = UILabel()
    var imageCamera = UIImageView()
    var widthCamera = CGFloat(24.75)
    var heightCamera = CGFloat(18.75)
    
    var labelMaxImage = UILabel()
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        
        let text = String.localize("LB_CA_PHOTO")
        labelPhoto.frame = CGRect(x: Margin.left * 2, y: (bounds.height - heightLabel) / 2, width: StringHelper.getTextWidth(text, height: heightLabel, font: labelPhoto.font), height: heightLabel)
        labelPhoto.formatSize(15)
        labelPhoto.text = text
        addSubview(labelPhoto)
        
        imageCamera.frame = CGRect(x: bounds.width - widthCamera - Margin.right * 2, y: (bounds.height - heightCamera) / 2, width: widthCamera, height: heightCamera)
        imageCamera.image = UIImage(named: "camera")
        addSubview(imageCamera)
        
        let strMax = String.init(format: "%d/%d", 0, Constants.LimitNumber.imagesNumber)
        let widthText = StringHelper.getTextWidth(strMax, height: heightLabel, font: labelPhoto.font)
        
        labelMaxImage.frame = CGRect(x: imageCamera.frame.maxX - widthText - Margin.right, y: (bounds.height - heightLabel) / 2, width: widthText, height: heightLabel)
        labelMaxImage.text = strMax
        self.addSubview(labelMaxImage)
        self.backgroundColor = UIColor.secondary5()
    }
}
