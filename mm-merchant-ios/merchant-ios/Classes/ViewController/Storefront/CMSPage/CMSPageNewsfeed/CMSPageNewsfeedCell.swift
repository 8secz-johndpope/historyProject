//
//  CMSPageNewsfeedCell.swift
//  MMDemoForLeslie_Swift4.0
//
//  Created by Leslie Zhang on 2018/3/26.
//  Copyright © 2018年 Leslie Zhang. All rights reserved.
//

import UIKit
import Kingfisher

class CMSPageNewsfeedCell: UICollectionViewCell {

    lazy var backgroundImageView:UIImageView = {
        let backgroundImageView = UIImageView()
        backgroundImageView.isUserInteractionEnabled = true
        backgroundImageView.layer.cornerRadius = 4.0
        backgroundImageView.layer.masksToBounds = true
        backgroundImageView.layer.borderColor = UIColor.primary2().cgColor
        backgroundImageView.layer.borderWidth = 1
        return backgroundImageView
    }()
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        
        self.backgroundColor = UIColor.white
        
        self.contentView.addSubview(backgroundImageView)
        
        backgroundImageView.snp.makeConstraints { (make) in
            make.left.right.top.equalTo(self)
            make.bottom.equalTo(self).offset(-MMMargin.CMS.imageToTitle)
        }

    }
    
    func setImageView(dataModel:CMSPageDataModel,imageView:UIImageView,adaptiveHeight:Bool? = nil) {
        var category:ImageCategory = .banner
        var scale = UIViewContentMode.scaleAspectFill
        if dataModel.dType == DataType.SKU {
            category = .product
            scale = .scaleAspectFit
            if let adaptiveHeight = adaptiveHeight {
                if adaptiveHeight {
                    scale = .scaleAspectFill
                }
            }
        }else if dataModel.dType == DataType.POST {
            category = .post
        }else if dataModel.dType == DataType.MERCHANT {
            category = .merchant
        }
        var url = URL(string: "")
        if let imageUrl = dataModel.imageUrl {
            url = ImageURLFactory.URLSize512(imageUrl, category: category)
        }else {
            if let style = dataModel.style {
                url =  ImageURLFactory.URLSize512(style.currentImageKey, category: category)
            }
        }
        if let iamgeUrl = url {
            KingfisherManager.shared.retrieveImage(with: iamgeUrl, options: nil, progressBlock: nil, completionHandler: { (image, error, cacheType, imageURL) in
                imageView.contentMode = scale
                imageView.image = image
                if  !cacheType.cached {
                    imageView.fadeIn(duration: 0.5)
                }
            })
        }

    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

}
