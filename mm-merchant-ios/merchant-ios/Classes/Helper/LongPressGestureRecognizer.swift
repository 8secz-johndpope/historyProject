//
//  LongPressGestureRecognizer.swift
//  merchant-ios
//
//  Created by Alan YU on 13/4/2017.
//  Copyright © 2017 WWE & CO. All rights reserved.
//

import UIKit

class LongPressGestureRecognizer: UILongPressGestureRecognizer {
    
    var longPressHandler: ((_ recognizer: LongPressGestureRecognizer) -> Void)? {
        didSet {
            addTarget(self, action: #selector(LongPressGestureRecognizer.handler))
        }
    }
    
    @objc func handler(_ recognizer: LongPressGestureRecognizer) {
        longPressHandler?(recognizer)
    }

}
