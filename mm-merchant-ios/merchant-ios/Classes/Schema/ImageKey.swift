//
//  ImageKey.swift
//  storefront-ios
//
//  Created by Demon on 30/7/18.
//  Copyright © 2018年 WWE & CO. All rights reserved.
//

import Foundation

extension String {
    
    //解析字符串中 a2885307277034f7ea189dfaf034b111_w_h
    func whratio() -> Float? {
        guard let list = self.regularExpression(pattern: "[a-f0-9]{32}_[0-9\\.]+_[0-9\\.]+") else { return nil }
        if list.count <= 0 {
            return nil
        }
        let text = self as NSString
        let imgKey = text.substring(with: list[0])
        let array = imgKey.components(separatedBy: "_")
        if let width = Float(array[1]), let height = Float(array[2]) {
            return height/width
        }
        return nil
    }
    
    
    /// 正则抠出响应的数据
    ///
    /// - Parameter pattern: 正则
    /// - Returns: [nsrange]
    func regularExpression(pattern: String) -> [NSRange]? {
        guard let regex = try? NSRegularExpression(pattern: pattern, options: [.caseInsensitive]) else { return nil }
        let text: NSString = self as NSString
        let lenght = text.length
        let matches = regex.matches(in: self, options: [], range: NSRange(location: 0, length: lenght))
        var list:[NSRange] = []
        for match in matches {
            let rg = match.range
            list.append(rg)
        }
        
        if list.count <= 0 {
            return nil
        }
        return list
    }
    
}


