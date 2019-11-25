//
//  TapGestureRecognizer.swift
//  merchant-ios
//
//  Created by Alan YU on 13/4/2017.
//  Copyright © 2017 WWE & CO. All rights reserved.
//

import UIKit

class TapGestureRecognizer: UITapGestureRecognizer {
    
    var tapHandler: ((_ recognizer: TapGestureRecognizer) -> Void)? {
        didSet {
            addTarget(self, action: #selector(TapGestureRecognizer.handler))
        }
    }
    
    @objc func handler(_ recognizer: TapGestureRecognizer) {
        tapHandler?(recognizer)
    }
    
}

