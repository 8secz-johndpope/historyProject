//
//  UIButton+Chat.swift
//  TSWeChat
//
//  Created by Hilen on 12/18/15.
//  Copyright © 2015 Hilen. All rights reserved.
//

import Foundation

class TSChatButton: UIButton {
    var showTypingKeyboard: Bool
    
    required init(coder aDecoder: NSCoder) {
        self.showTypingKeyboard = true
        super.init(coder: aDecoder)!
    }
    
    var tapHandler: ((_ button: TSChatButton) -> Void)? {
        didSet {
            addTarget(self, action: #selector(TSChatButton.handler), for: .touchUpInside)
        }
    }
    
    @objc func handler(_ button: TSChatButton) {
        tapHandler?(button)
    }

}
