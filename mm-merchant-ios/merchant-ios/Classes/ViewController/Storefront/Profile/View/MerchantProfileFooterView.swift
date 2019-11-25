//
//  MerchantProfileFooterView.swift
//  merchant-ios
//
//  Created by khanh.nguyen on 7/6/16.
//  Copyright © 2016 WWE & CO. All rights reserved.
//

import UIKit

class MerchantProfileFooterView: UICollectionReusableView {
    
    var merchant: Merchant? {
        didSet {
            if let url = merchant?.headerLogoImage {
                imageView.mm_setImageWithURL(ImageURLFactory.URLSize1000(url, category: .merchant), placeholderImage: nil, clipsToBounds: true, contentMode: .scaleAspectFit, progress: nil, optionsInfo: nil, completion: nil)
                
            }
            if let name = merchant?.merchantCompanyName {
                nameLabel.text = String(format: "2016 %@", name).uppercased()
            }
        }
    }
    
    var nameLabel = UILabel()
    var copyrightLabel = UILabel()
    var imageView = UIImageView()
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        
        let bottomView = UIView()
        bottomView.frame = CGRect(x: 0, y: 0, width: self.bounds.sizeWidth, height: 30)
        bottomView.backgroundColor = UIColor.white
        self.addSubview(bottomView)
        
        nameLabel.text = String.localize("ALL RIGHTS RESERVED")
        nameLabel.formatSize(14)
        nameLabel.textColor = UIColor.secondary7()
        nameLabel.frame = CGRect(x: 0, y: 0, width: bottomView.frame.sizeWidth/2, height: bottomView.frame.sizeHeight)
        nameLabel.textAlignment = NSTextAlignment.center
        bottomView.addSubview(nameLabel)
        
        
        copyrightLabel.text = String.localize("ALL RIGHTS RESERVED")
        copyrightLabel.formatSize(14)
        copyrightLabel.textColor = UIColor.secondary7()
        copyrightLabel.frame = CGRect(x: bottomView.frame.center.x, y: 0, width: bottomView.frame.sizeWidth/2, height: bottomView.frame.sizeHeight)
        copyrightLabel.textAlignment = NSTextAlignment.center
        bottomView.addSubview(copyrightLabel)
        
        var lineView = UIView()
        let height = CGFloat(18)
        lineView.frame = CGRect(x: bottomView.frame.center.x - 1, y: (bottomView.frame.sizeHeight - height) / 2, width: 1, height: height)
        lineView.backgroundColor = UIColor.darkGray
        bottomView.addSubview(lineView)
        
        
        lineView = UIView()
        lineView.backgroundColor = UIColor.primary2()
        let leftMargin = CGFloat(20)
        lineView.frame = CGRect(x: leftMargin, y: 0, width: self.bounds.sizeWidth - 2 * leftMargin, height: 1)
        bottomView.addSubview(lineView)
        
        imageView.frame = CGRect(x: bounds.midX - Constants.Value.BrandImageWidth / 2, y: bottomView.frame.maxY, width: Constants.Value.BrandImageWidth , height: self.bounds.sizeHeight - bottomView.frame.maxY)
        self.addSubview(imageView)
        
    }
    
    override func layoutSubviews() {
        super.layoutSubviews()
        
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}
