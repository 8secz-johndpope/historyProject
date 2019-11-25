//
//  DebugView.swift
//  storefront-ios
//
//  Created by Alan Team on 13/4/2018.
//  Copyright © 2018 WWE & CO. All rights reserved.
//

import Foundation

class DebugView: UIView {
    
    private var name: String?
    private let debugLabel = UILabel()
    
    convenience init(name: String) {
        self.init()
        
        layer.borderColor = UIColor.blue.cgColor
        layer.borderWidth = 1
        
        debugLabel.text = name
        debugLabel.textColor = UIColor.white
        debugLabel.shadowColor = UIColor.gray
        debugLabel.shadowOffset = CGSize(width: -1, height: -1)
        debugLabel.sizeToFit()
        addSubview(debugLabel)
    }
    
    override func didAddSubview(_ subview: UIView) {
        bringSubview(toFront: debugLabel)
    }
    
}
