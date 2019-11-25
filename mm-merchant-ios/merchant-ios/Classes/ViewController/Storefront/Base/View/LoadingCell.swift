//
//  LoadingCell.swift
//  merchant-ios
//
//  Created by HungPM on 4/24/17.
//  Copyright © 2017 WWE & CO. All rights reserved.
//

import Foundation

class LoadingTableViewCell: UITableViewCell {
    
    let activity = UIActivityIndicatorView(activityIndicatorStyle: .whiteLarge)
    
    override init(style: UITableViewCellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)
        
        activity.color = UIColor.black
        self.addSubview(activity)
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override func layoutSubviews() {
        super.layoutSubviews()

        activity.center = CGPoint(x: self.frame.sizeWidth / 2 , y: self.frame.sizeHeight / 2)
        activity.startAnimating()
    }
}

class LoadingCollectionViewCell: UICollectionViewCell {
    
    let activity = UIActivityIndicatorView(activityIndicatorStyle: .whiteLarge)
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        
        activity.color = UIColor.black
        self.addSubview(activity)
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override func layoutSubviews() {
        super.layoutSubviews()
        
        activity.center = CGPoint(x: self.frame.sizeWidth / 2 , y: self.frame.sizeHeight / 2)
        activity.startAnimating()
    }
}
