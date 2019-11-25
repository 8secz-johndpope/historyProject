//
//  MMLoadingButton.swift
//  merchant-ios
//
//  Created by Sang Nguyen on 3/8/17.
//  Copyright © 2017 WWE & CO. All rights reserved.
//

import UIKit

class MMLoadingButton: UIButton {
    
    var loadingIndicator: UIActivityIndicatorView? = nil
    
    //MARK: - Loading Indicator
    func showLoading(_ spinerColor: UIColor? = nil) {
        var indicator: UIActivityIndicatorView! = nil
        if let loadingIndicator = self.loadingIndicator {
            indicator = loadingIndicator
        } else {
            indicator = UIActivityIndicatorView()
            self.loadingIndicator = indicator
        }
        
        let buttonHeight = self.frame.size.height
        let buttonWidth = self.frame.size.width
        indicator.center = CGPoint(x: buttonWidth/2, y: buttonHeight/2)
        if let color = spinerColor {
            indicator.color = color
        }else {
            indicator.color = UIColor.primary1()
        }
        self.addSubview(indicator)
        indicator.startAnimating()
        self.isUserInteractionEnabled = false
    }
    
    func hideLoading() {
        if let indicator = self.loadingIndicator {
            indicator.stopAnimating()
            indicator.removeFromSuperview()
        }
        self.isUserInteractionEnabled = true
    }
    
    override func layoutSubviews() {
        super.layoutSubviews()
        
        if let loadingIndicator = self.loadingIndicator {
            let buttonHeight = self.bounds.size.height
            let buttonWidth = self.bounds.size.width
            loadingIndicator.center = CGPoint(x: buttonWidth/2, y: buttonHeight/2)
        }
    }
}
