//
//  ImageMarginCollectCell.swift
//  merchant-ios
//
//  Created by Koon Kit Chan on 22/12/2015.
//  Copyright © 2015 Koon Kit Chan. All rights reserved.
//

import Foundation


class ImageMarginCollectCell : UICollectionViewCell{
    var imageView = UIImageView()
    var filter = UIView()
    var label = UILabel()
    override init(frame: CGRect) {
        super.init(frame: frame)
        backgroundColor = UIColor.white
        imageView.image = UIImage(named: "holder")
        addSubview(imageView)
        filter.backgroundColor = UIColor.black
        filter.alpha = 0.3
        addSubview(filter)
        label.formatSmall()
        label.textAlignment = .center
        addSubview(label)
        layout()
    }
    override func layoutSubviews() {
        super.layoutSubviews()
        layout()

    }
    
    func layout(){
        imageView.frame = CGRect(x: bounds.minX, y:bounds.minY, width: bounds.width, height: bounds.height)
        filter.frame = self.bounds
        label.frame = CGRect(x: bounds.midX - 30, y: bounds.midY - 20, width: 60, height: 40)
    }
    
    func setImage(_ imageKey : String, category : ImageCategory){
      
        imageView.mm_setImageWithURL(ImageURLFactory.URLSize1000(imageKey, category: category), placeholderImage : UIImage(named: "holder"), contentMode: UIViewContentMode.scaleAspectFit)
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}
