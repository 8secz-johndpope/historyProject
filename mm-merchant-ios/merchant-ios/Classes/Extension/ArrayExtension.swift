//
//  ArrayExtension.swift
//  merchant-ios
//
//  Created by Tony Fung on 29/4/2016.
//  Copyright © 2016年 WWE & CO. All rights reserved.
//

import Foundation

extension Array where Element: Equatable {
    
    mutating func remove(_ object: Element) {
        self = filter { $0 != object }
    }
    
    func removed(_ object: Element) -> [Element] {
        return filter { $0 != object }
    }
    
}

extension Array where Element: User {
    mutating func sortByDisplayName() {
        self.sort { $0.displayName.lowercased() < $1.displayName.lowercased() }
    }
    
    mutating func append(uniqueUser: Element) {
        var exists = false
        for user in self {
            if user.userKey == uniqueUser.userKey {
                exists = true
                break
            }
        }
        if !exists {
            append(uniqueUser)
        }
    }
    
}

extension Array {
    
    func split(_ byLength: Int) -> [[Element]] {
        
        var copyArray = self
        var returnArray = [[Element]]()
        
        while copyArray.count > 0 {
            let subArray = Array(copyArray.prefix(byLength))
            returnArray.append(subArray)
            copyArray.removeFirst(subArray.count)
        }
        
        return returnArray
    }
    
    func get(_ index: Int) -> Element? {
        if index < count {
            return self[index]
        }
        return nil
    }
    
    func initial(_ numElements: Int = 1) -> [Element] {
        var result: [Element] = []
        if (count > numElements && numElements >= 0) {
            for index in 0..<(count - numElements) {
                result.append(self[index])
            }
        }
        return result
    }
    
    func rest(_ numElements: Int = 1) -> [Element] {
        var result : [Element] = []
        if (numElements < count && numElements >= 0) {
            for index in numElements..<count {
                result.append(self[index])
            }
        }
        return result
    }
    
    func eachWithIndex(_ callback: (Int, Element) -> ()) {
        for (index, elem) in enumerated() {
            callback(index, elem)
        }
    }
    
    // 去重
    func filterDuplicates<E: Equatable>(_ filter: (Element) -> E) -> [Element] {
        var result = [Element]()
        for value in self {
            let key = filter(value)
            if !result.map({filter($0)}).contains(key) {
                result.append(value)
            }
        }
        return result
    }
}
