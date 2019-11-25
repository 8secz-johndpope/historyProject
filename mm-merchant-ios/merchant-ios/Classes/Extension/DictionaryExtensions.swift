//
//  Dictionary.swift
//  storefront-ios
//
//  Created by Alan YU on 19/1/2018.
//  Copyright © 2018 WWE & CO. All rights reserved.
//

import Foundation

extension Dictionary {
    
    mutating func merge<K, V>(_ dictionaries: Dictionary<K, V>...) {
        for dict in dictionaries {
            for (key, value) in dict {
                updateValue(value as! Value, forKey: key as! Key)
            }
        }
    }
    
}
