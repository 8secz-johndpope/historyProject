//
//  ContactHeaderView.swift
//  merchant-ios
//
//  Created by HungPM on 5/23/16.
//  Copyright © 2016 WWE & CO. All rights reserved.
//

import Foundation

class ContactHeaderView: UICollectionReusableView {
    
    var merchantName: UILabel!
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        
        let ViewHeight = CGFloat(30)
        
        self.frame = CGRect(x: 0, y: 0, width: frame.width, height: ViewHeight)
        backgroundColor = UIColor(hexString: "f3f5f8")
        
        let Padding = CGFloat(10)
        
        merchantName = UILabel(frame: CGRect(x: Padding, y: 0, width: self.frame.width - (2 * Padding), height: self.frame.height))
        merchantName.formatSize(14)
        addSubview(merchantName)
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

}
