//
//  SegmentedButton.swift
//  merchant-ios
//
//  Created by Kam on 27/11/2017.
//  Copyright © 2017 WWE & CO. All rights reserved.
//

import UIKit

class SegmentedButton: UIButton {
    
    var fontSize: CGFloat = 14.0
    
    override func layoutSubviews() {
        super.layoutSubviews()
        
        switch self.state {
        case UIControlState():
            self.titleLabel?.font = UIFont.systemFont(ofSize: fontSize)
            break
        case UIControlState.selected:
            self.titleLabel?.font = UIFont.boldSystemFont(ofSize: fontSize+1)
            break
        default:
            break
        }
    }
    
}
