//
//  TSChatLabel+UI.swift
//  merchant-ios
//
//  Created by Kam on 23/3/2016.
//  Copyright © 2016 WWE & CO. All rights reserved.
//

import Foundation

// MARK: - @extension TSChatLabel
extension UILabel {
    
    func startBlink() {
        self.alpha = 1.0
        UIView.animate(withDuration: 1.0,
            delay: 0.0,
            options: .repeat,
            animations: { self.alpha = 0.0 },
            completion: { [weak self] _ in self?.alpha = 1.0 })
    }
    
    func stopBlink() {
        self.layer.removeAllAnimations()
        self.transform = CGAffineTransform.identity
        self.alpha = 1.0
    }
}
