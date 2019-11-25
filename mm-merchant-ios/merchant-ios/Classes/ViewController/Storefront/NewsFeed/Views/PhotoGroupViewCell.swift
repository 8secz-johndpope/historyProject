//
//  PhotoGroupViewCell.swift
//  merchant-ios
//
//  Created by Sang Nguyen on 12/21/16.
//  Copyright © 2016 WWE & CO. All rights reserved.
//

import UIKit

class PhotoGroupViewCell: PhotoAssetCollectionViewCell {
    private final let MarginTopBottom: CGFloat = 10
    private final let MarginLeftRight: CGFloat = 10
    private final let LabelHeight: CGFloat = 25
    
    let imageView = UIImageView()
    let groupLabel = UILabel()
    let bottomSeperator = UIView()
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        backgroundColor = UIColor.white
        self.contentView.backgroundColor = UIColor.clear
        imageView.clipsToBounds = true
        imageView.contentMode = .scaleAspectFill
        groupLabel.formatSmall()
        
        self.contentView.addSubview(imageView)
        self.contentView.addSubview(groupLabel)
        
        bottomSeperator.backgroundColor = UIColor.secondary1()
        self.contentView.addSubview(bottomSeperator)
    }
    
    override func layoutSubviews() {
        super.layoutSubviews()
        
        var frameCell = self.frame
        let imageWidthHeight = frameCell.sizeHeight - (2 * MarginTopBottom)
        imageView.frame = CGRect(x: MarginLeftRight, y: MarginTopBottom, width: imageWidthHeight, height: imageWidthHeight)
        
        let groupLabelX = imageView.frame.maxX + 10
        groupLabel.frame = CGRect(x: groupLabelX, y: (imageView.frame.sizeHeight - LabelHeight) / 2, width: frameCell.sizeWidth - groupLabelX - 10, height: LabelHeight)
        
        bottomSeperator.frame = CGRect(x: 0, y: frameCell.sizeHeight - 1, width: frameCell.sizeWidth, height: 1)
    }
    
    override func didAssetReady(_ image: UIImage?) {
        super.didAssetReady(image)
        imageView.image = image
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}
