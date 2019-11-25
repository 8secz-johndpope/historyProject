//
//  MerchantImageViewCell.swift
//  merchant-ios
//
//  Created by Vu Dinh Trung on 3/18/16.
//  Copyright © 2016 WWE & CO. All rights reserved.
//

import UIKit

class MerchantImageViewCell: UICollectionViewCell {
    
    var imageView = UIImageView()
    override init(frame: CGRect) {
        super.init(frame: frame)
		
		self.imageView.contentMode = .scaleAspectFill
        self.addSubview(imageView)
        layoutSubviews()
    }
    
    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
    }
    
    
    
    override func layoutSubviews() {
        super.layoutSubviews()
        self.imageView.frame = CGRect(x: 0, y: 0, width: bounds.width, height: bounds.height)
		
		
    }
	func setDataImage(_ key : String, imageCategory : ImageCategory){
        imageView.mm_setImageWithURL(ImageURLFactory.URLSize1000(key, category: imageCategory), placeholderImage : nil, contentMode: .scaleAspectFill)
        
    }
    func setupDataByCurator(_ curatorImage: DataImageCurator){
        
        imageView.image = curatorImage.image
        layoutSubviews()
    }
}
