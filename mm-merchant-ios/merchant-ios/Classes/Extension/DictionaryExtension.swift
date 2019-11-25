//
//  DictionaryExtension.swift
//  storefront-ios
//
//  Created by Alan YU on 23/1/2018.
//  Copyright © 2018 WWE & CO. All rights reserved.
//

import Foundation

extension Dictionary {
    
    mutating func mergeAll(_ map: [Key: Value]) {
        for (key, value) in map {
            self[key] = value
        }
    }
    
    /// dictionary to jsonString
    ///
    /// - Returns: jsonString
    func jsonPrettyStringEncoded() -> String? {
        if JSONSerialization.isValidJSONObject(self) {
            let jsonData: Data?
            do {
                jsonData = try JSONSerialization.data(withJSONObject: self, options: .prettyPrinted)
            } catch let error {
                print(error)
                jsonData = nil
            }
            if let JSON = jsonData {
                return String(data: JSON, encoding: String.Encoding.utf8)
            }
        }
        return nil
    }
}

