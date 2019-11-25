//
//  CenterLayoutView.swift
//  merchant-ios
//
//  Created by Alan YU on 6/1/2016.
//  Copyright © 2016 WWE & CO. All rights reserved.
//

import Foundation

enum CenterLayoutMode: Int {
    case flow
    case central
}

class CenterLayoutView: UIView {

    var mode = CenterLayoutMode.flow {
        didSet {
            self.setNeedsLayout()
        }
    }
    
    override func layoutSubviews() {
        super.layoutSubviews()

        let views = self.subviews
        let frame = self.bounds
        
        switch self.mode {
        case .flow:
            
            let centerY = self.bounds.height / 2
            
            var width = CGFloat(0)
            
            for view in views {
                width += view.bounds.width
            }
            
            var lastXPos = (frame.width - width) / 2
            for view in views {
                view.center = CGPoint(x: lastXPos + view.bounds.width / 2, y: centerY)
                lastXPos += view.bounds.width
            }
            
        case .central:
            
            for view in views {
                view.center = CGPoint(x: frame.width / 2, y: frame.height / 2)
            }
        }
        
    }
}
