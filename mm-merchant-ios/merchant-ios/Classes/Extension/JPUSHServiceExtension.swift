//
//  JPUSHServiceExtension.swift
//  merchant-ios
//
//  Created by Alan YU on 23/2/2017.
//  Copyright © 2017 WWE & CO. All rights reserved.
//

import Foundation

extension JPUSHService {
    
    class func updateMMTagsAndAlias() {
        
        // Tag limited to 40 bytes, Max support up to 1000 tags but not excess 7K
        // Alias limited to 40 bytes (UTF-8 encoding)
        // 40 bytes around 10 characters
        
        var tags = Set<String>()
        
        if let version = Bundle.main.infoDictionary!["CFBundleShortVersionString"] as? String {
            tags.insert(version)
        }
        
        if let validTags = JPUSHService.filterValidTags(tags) {
            Log.debug("JPush Tags: \(String(describing: validTags)), Alias: \(Context.getUsername())")
            
            
            JPUSHService.setTags(validTags as? Set<String>, completion: nil, seq: 0)
            JPUSHService.setAlias(Context.getUsername(), completion: nil, seq: 0)
        }
    }
    
}
