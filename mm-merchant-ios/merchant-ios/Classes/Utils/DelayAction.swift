//
//  DelayAction.swift
//  merchant-ios
//
//  Created by Alan YU on 5/4/2016.
//  Copyright © 2016 WWE & CO. All rights reserved.
//

import Foundation

class DelayAction {
    
    private var actionBlock: (() -> Void)?
    private var isValid = false
    
    init (delayInSecond: TimeInterval, actionBlock: @escaping () -> Void) {
        
        self.actionBlock = actionBlock
        self.isValid = true
        
        let delayTime = DispatchTime.now() + Double(Int64(delayInSecond * Double(NSEC_PER_SEC))) / Double(NSEC_PER_SEC)
        DispatchQueue.main.asyncAfter(deadline: delayTime) { [weak self] in
            
            if let strongSelf = self, strongSelf.isValid {
                strongSelf.actionBlock?()
                strongSelf.actionBlock = nil
            }
            
        }
        
    }
    
    func cancel() {
        isValid = false
    }
    
    deinit {
        actionBlock = nil
    }
}
