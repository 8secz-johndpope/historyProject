//
//  PostImageCell.swift
//  merchant-ios
//
//  Created by HungPM on 9/12/17.
//  Copyright © 2017 WWE & CO. All rights reserved.
//

import UIKit

class PostImageCell: UICollectionViewCell {

    lazy var bgImageView:UIImageView = {
        let bgImageView = TouchImageView(frame: CGRect(x: 0, y: 0, width: ScreenWidth, height: ScreenWidth))
        bgImageView.contentMode = .scaleAspectFill
        return bgImageView
    }()
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        
        self.addSubview(bgImageView)
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    var model: PostCreateData? {
        didSet{
            if let model = model {
                bgImageViewSetImage(model)
            }
        }
    }
    
    func bgImageViewSetImage(_ model: PostCreateData?)  {
        if let model = model{
            if let imageRect = model.imageRect{
                bgImageView.image = model.processedImage?.crop(bounds: imageRect)
            }else{
                bgImageView.image = model.processedImage
            }
            
            if let image =  bgImageView.image{
                var rect = CGRect.zero
                let expectedHeight = ScreenWidth * image.size.height / image.size.width
                let HDHeight = ScreenWidth * image.size.width / image.size.height
                
                if expectedHeight >= ScreenWidth {
                    rect = CGRect(x:0,y: 0,width:image.size.width / image.size.height * ScreenWidth,height: ScreenWidth)
                    rect.origin.x = (ScreenWidth - rect.size.width) / 2
                    rect.origin.y = (ScreenWidth - rect.size.height) / 2
                }else {
                    
                    let height = image.size.height / image.size.width * ScreenWidth
                    rect = CGRect(x:0,y: 0,width: ScreenWidth,height: height)
                    rect.origin.x = (ScreenWidth - rect.size.width) / 2
                    rect.origin.y = (ScreenWidth - rect.size.height) / 2
                    
                    bgImageView.frame = CGRect(x:0,y:(ScreenWidth - HDHeight)/2,width: ScreenWidth,height:HDHeight)
                }
                bgImageView.frame = rect                
                
            }
       
        }

    }
}
