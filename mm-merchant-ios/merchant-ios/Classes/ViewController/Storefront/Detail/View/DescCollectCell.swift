//
//  DescCollectCell.swift
//  merchant-ios
//
//  Created by Koon Kit Chan on 2/12/2015.
//  Copyright © 2015 Koon Kit Chan. All rights reserved.
//

import Foundation
import Kingfisher

class DescCollectCell : UICollectionViewCell {
    var descImageView = UIImageView()
    override init(frame: CGRect) {
        super.init(frame: frame)
        backgroundColor = UIColor.white
        descImageView.image = UIImage(named: "holder")
        
        //use ScaleAspectFill because we dynamic height in PDP for image
        descImageView.contentMode = .scaleAspectFill
        addSubview(descImageView)
        layoutSubviews()
    }
    override func layoutSubviews() {
        super.layoutSubviews()
        descImageView.frame = CGRect(x: bounds.minX, y: bounds.minY, width: bounds.width, height: bounds.height)
    }
    
    func setImage(_ imageKey : String, completion: ((_ image: Image?, _ error: NSError?) -> ())? = nil){
        
        //use ScaleAspectFill because we dynamic height in PDP for image
        descImageView.mm_setImageWithURL(ImageURLFactory.URLSize1000(imageKey, category: .product), placeholderImage : UIImage(named: "holder"), contentMode: .scaleAspectFill, completion: { (image: Image?, error: NSError?, cacheType: CacheType, imageURL: URL?) in
            completion?(image, error)
        })
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
}
