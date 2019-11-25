//
//  IMFilterCache.swift
//  merchant-ios
//
//  Created by HungPM on 5/24/16.
//  Copyright © 2016 WWE & CO. All rights reserved.
//

import Foundation

class IMFilterCache {
    
    class var sharedInstance: IMFilterCache {
        get {
            struct Singleton {
                static let instance = IMFilterCache()
            }
            return Singleton.instance
        }
    }
    
    //0. friend 1. customer 2. internal staff 3. in chatting 4. closed 5. follow up
    private final var filterValues = [false, false, false, false, false, false]
    private final var sortResult = ComparisonResult.orderedDescending
    
    //private init
    private init() {}
    
    func saveFilterChat(_ newValues: [Bool]) {
        filterValues = newValues
    }
    
    func filterChat() -> [Bool] {
        return filterValues
    }
    
    func numberFilterSelected() -> Int {
        var numberSelected = 0
        
        for value in filterValues {
            if value {
                numberSelected += 1
            }
        }
        
        return numberSelected
    }
    
    func sortType() -> ComparisonResult {
        return sortResult
    }
    
    func saveSortType(_ newValue: ComparisonResult) {
        sortResult = newValue
    }

}
