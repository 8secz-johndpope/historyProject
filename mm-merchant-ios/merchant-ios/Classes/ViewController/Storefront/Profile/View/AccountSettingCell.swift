//
//  AccountSettingCell.swift
//  merchant-ios
//
//  Created by Stephen Yuen on 18/3/2016.
//  Copyright © 2016 WWE & CO. All rights reserved.
//

import Foundation

class AccountSettingCell: UICollectionViewCell {
    
    static let CellIdentifier = "AccountSettingCellID"
    static let DefaultHeight: CGFloat = 45
    
    var titleLabel = UILabel()
    private var imageView = UIImageView()
    private var disclosureIndicatorImageView = UIImageView()
    private var borderView = UIView()
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        self.backgroundColor = UIColor.white
        self.clipsToBounds = true
        
        addSubview(imageView)
        
        titleLabel.formatSize(14)
        addSubview(titleLabel)
        
        disclosureIndicatorImageView.image = UIImage(named: "filter_right_arrow")
        addSubview(disclosureIndicatorImageView)
        
        borderView.backgroundColor = UIColor.secondary1()
        addSubview(borderView)
    }
    
    override func layoutSubviews() {
        super.layoutSubviews()
        
        let marginLeft: CGFloat = 14
        let labelMarginLeft: CGFloat = 12
        let imageViewSize = CGSize(width: 30, height: 30)
        
        imageView.frame = CGRect(x: marginLeft, y: bounds.midY - (imageViewSize.width / 2), width: imageViewSize.width , height: imageViewSize.height)
        borderView.frame = CGRect(x: bounds.minX, y: bounds.maxY - 1, width: bounds.width, height: 1)
        
        disclosureIndicatorImageView.frame = CGRect(
            x: bounds.maxX - 35,
            y: bounds.midY - (disclosureIndicatorImageView.image!.size.height / 2),
            width: disclosureIndicatorImageView.image!.size.width,
            height: disclosureIndicatorImageView.image!.size.height
        )
        
        titleLabel.frame = CGRect(
            x: imageView.frame.maxX + labelMarginLeft,
            y: 0,
            width: disclosureIndicatorImageView.frame.originX - (imageView.frame.maxX + labelMarginLeft),
            height: bounds.height
        )
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    func setImage(imageName: String){
        imageView.image = UIImage(named: imageName)
    }
    
    func showBorder(_ isShow: Bool) {
        borderView.isHidden = !isShow
    }
}
