//
//  TouchImageView.swift
//  PhotoFrame
//
//  Created by Markus Chow on 2/5/2016.
//  Copyright © 2016 Markus Chow. All rights reserved.
//

import UIKit
import Kingfisher

extension UIImageView {
	var imageScale: CGSize {
        
        var sx = 0.0
        var sy = 0.0
        if let image = self.image {
            sx = Double(self.frame.size.width / image.size.width)
            sy = Double(self.frame.size.height / image.size.height)
        }
		
		var s = 1.0
		switch (self.contentMode) {
		case .scaleAspectFit:
			s = fmin(sx, sy)
			return CGSize (width: s, height: s)
			
		case .scaleAspectFill:
			s = fmax(sx, sy)
			return CGSize(width:s, height:s)
			
		case .scaleToFill:
			return CGSize(width:sx, height:sy)
			
		default:
			return CGSize(width:s, height:s)
		}
	}
}

protocol TouchImageViewDelegate {
    func returnImage(_ image: UIImage)
}

class TouchImageView: UIImageView , UIGestureRecognizerDelegate {
		
    var touchImageDelegate: TouchImageViewDelegate!
	
	var initialImageScale : CGFloat = 0.0
    
    var initialFrame = CGRect.zero
	var loadFrameFromCache = false
	override var image: UIImage? {
		didSet {
			if image != nil {
				initialImageScale = self.imageScale.width
                
                if let image = self.image {
                    if let superView = self.superview {
                        var rect = CGRect.zero
                        let expectedHeight = superView.size.width * image.size.height / image.size.width
                        if expectedHeight >= superView.size.height {
                            rect = CGRect(x: 0, y: 0, width: superView.size.width, height: expectedHeight)
                        }else {
                            rect = CGRect(x: 0, y: 0, width: superView.size.height * image.size.width / image.size.height, height: superView.size.height)
                        }
                        rect.origin.x = (superView.frame.size.width - rect.size.width) / 2
                        rect.origin.y = (superView.frame.size.height - rect.size.height) / 2
                        if loadFrameFromCache == false {
                            self.frame = rect
                            self.initialFrame = rect
                        }else {
                            self.initialFrame = superView.bounds
                        }
                        
                        
                    }
                    
                }
                
			}
		}
	}
    
	override init(frame: CGRect) {
		super.init(frame: frame)
		
		self.isUserInteractionEnabled = true
		self.isMultipleTouchEnabled = true
		self.isExclusiveTouch = false
		
		self.contentMode = .scaleAspectFill		
		
	}
	
	required init?(coder aDecoder: NSCoder) {
		fatalError("init(coder:) has not been implemented")
	}
	
    func setProductImage(_ imageKey : String){
//        self.mm_setImageWithURL(ImageURLFactory.get(imageKey), placeholderImage: UIImage(named: "holder"), contentMode: .scaleAspectFill)
        
        
        
    }
    
    
    func setupDataByImageCrop(_ cropImage: UIImage) {
        self.image = cropImage
        
        
    }
}
