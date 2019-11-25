//
//  MMActivityIndicator.swift
//  merchant-ios
//
//  Created by Stephen Yuen on 2/8/2016.
//  Copyright © 2016 WWE & CO. All rights reserved.
//

import UIKit

class MMActivityIndicator: UIView {
    
    enum IndicatorType {
        case pdp
    }

    private let animationImageView = UIImageView()
    
    private var type = IndicatorType.pdp
    private static var images = [UIImage]()
    
    init(frame: CGRect, type: IndicatorType) {
        super.init(frame: frame)
        
        switch type {
        case .pdp:
            self.backgroundColor = UIColor.primary2()
            
            let imageSize = CGSize(width: 50, height: 50)
            
            animationImageView.frame = CGRect(x: (frame.width - imageSize.width) / 2, y: (frame.height - imageSize.height) / 2, width: imageSize.width, height: imageSize.height)
            
            if MMActivityIndicator.images.count == 0 {
                for i in 1...42 {
                    if let image = UIImage(named: "15000" + String(format: "%02d", i)) {
                        MMActivityIndicator.images.append(image)
                    }
                    
                }
            }
        }
        
        animationImageView.animationImages = MMActivityIndicator.images
        animationImageView.animationDuration = 2
        animationImageView.animationRepeatCount = 0
        
        addSubview(animationImageView)
    }
    
    func startAnimating() {
        animationImageView.startAnimating()
    }
    
    func stopAnimating() {
        animationImageView.stopAnimating()
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    deinit {
        animationImageView.stopAnimating()
    }

}
