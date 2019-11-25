//
//  HashTagExtension.swift
//  storefront-ios
//
//  Created by lingminjun on 2018/4/19.
//  Copyright © 2018年 WWE & CO. All rights reserved.
//

import Foundation

extension String {
    //链接优先
    public func rangeMatches(pattern:String, exclude patternExclude:String) -> [NSRange] {
        guard let regex = try? NSRegularExpression(pattern: pattern, options: []) else { return [] }
        let text:NSString = self as NSString
        let lenght = text.length
        let matches = regex.matches(in: self, options: [], range: NSRange(location: 0, length: lenght))
        var list:[NSRange] = []
        for match in matches {
            let rg = match.range
            list.append(rg)
        }
        
        guard let regex2 = try?  NSRegularExpression(pattern: patternExclude, options: [.caseInsensitive]) else { return list }
        let matches2 = regex2.matches(in: self, options: [], range: NSRange(location: 0, length: lenght))
        for match in matches2 {
            let rg = match.range
            for (index,r) in list.enumerated() {
                if (rg.lowerBound <= r.lowerBound && rg.upperBound > r.lowerBound)
                    || (rg.lowerBound < r.upperBound && rg.upperBound >= r.upperBound) {
                    //针对最后一个是hash值得情况，继续保留hash值
                    if r.lowerBound + 1 == rg.upperBound && text.character(at: r.lowerBound) == 35/*"#"*/ {
                        continue
                    }
                    list.remove(at: index)
                }
            }
        }
        
        return list
    }
    
    public func substringsMatches(pattern:String, exclude patternExclude:String) -> [String] {
        var list:[String] = []
        let text:NSString = self as NSString
        let ranges = self.rangeMatches(pattern: pattern, exclude: patternExclude)
        for range in ranges {
            list.append(text.substring(with: range))
        }
        return list
    }
}
