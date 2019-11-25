//
//  LoadingFooterView.swift
//  merchant-ios
//
//  Created by Tony Fung on 24/2/2017.
//  Copyright © 2017年 WWE & CO. All rights reserved.
//

import UIKit

class LoadingFooterView: UICollectionReusableView {

    let activity = UIActivityIndicatorView(activityIndicatorStyle: UIActivityIndicatorViewStyle.whiteLarge)
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        
        self.addSubview(activity)
        
        
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func layoutSubviews() {
        super.layoutSubviews()
        
        activity.center = CGPoint(x: self.frame.sizeWidth / 2 , y: self.frame.sizeHeight / 2)
        if !activity.isHidden {
            activity.startAnimating()
        }
        
    }
    
    
    
}
