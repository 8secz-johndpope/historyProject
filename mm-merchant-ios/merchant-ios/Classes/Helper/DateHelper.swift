//
//  DateHelper.swift
//  merchant-ios
//
//  Created by Stephen Yuen on 20/10/2016.
//  Copyright © 2016 WWE & CO. All rights reserved.
//

import Foundation

class DateHelper {
    
    class func currentTimeInRange(dateFrom: Date?, dateTo: Date?) -> Bool {
        var isInRange = true
        if let currentTime = TimestampService.defaultService.getServerTime() {
            if let from = dateFrom, currentTime.isBefore(date: from, granularity: .second) {
                isInRange = false
            }
            
            if let to = dateTo, currentTime.isAfter(date: to, granularity: .second) {
                isInRange = false
            }
            return isInRange
        }
        return false
    }
}
