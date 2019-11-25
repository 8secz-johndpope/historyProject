//
//  PostItemCollectionViewCell.swift
//  merchant-ios
//
//  Created by Trung Vu on 2/29/16.
//  Copyright © 2016 WWE & CO. All rights reserved.
//

import UIKit

class PostItemCollectionViewCell: UICollectionViewCell {
    var imageView = UIImageView()
    override init(frame: CGRect) {
        super.init(frame: frame)
        
        imageView.backgroundColor = UIColor.white
		imageView.contentMode = .scaleAspectFit
		
        self.addSubview(imageView)
        layoutSubviews()
    }
    
    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
    }
    
    
    
    override func layoutSubviews() {
        super.layoutSubviews()
        self.imageView.frame = self.bounds
        
    }
    func setDataImage(_ key : String){
        imageView.mm_setImageWithURL(ImageURLFactory.URLSize1000(key, category: .merchant), placeholderImage : nil)
        
    }
    func setupDataDummy(_ strImage: String){
        
        imageView.image = UIImage(named: strImage)
    }
}
