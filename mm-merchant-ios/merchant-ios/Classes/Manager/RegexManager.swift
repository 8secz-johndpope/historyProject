//
//  RegexManager.swift
//  merchant-ios
//
//  Created by Koon Kit Chan on 16/2/2016.
//  Copyright © 2016 WWE & CO. All rights reserved.
//

import Foundation
class RegexManager {
    
    struct ValidPattern {
        static let Username = "^[a-zA-Z]\\w{0,50}$"
        static let Password = "^(?=.*[a-zA-Z])(?=.*[0-9]).{8,16}$"
        struct MobilePhone {
            static let China = "^(1[1-9])"
            static let HongKong = "^(5|6|8|9)"
        }
        static let SpecialCharacter = "^(\\(?\\+?[0-9]*\\)?)?[0-9_\\- \\(\\)]*$"
        static let Email = "^([a-zA-Z0-9_\\-\\.]+)@((\\[[0-9]{1,3}\\.[0-9]{1,3}\\.[0-9]{1,3}\\.)|(([a-zA-Z0-9\\-]+\\.)+))([a-zA-Z]{2,4}|[0-9]{1,3})(\\]?)$"
        
        
        static let PasswordCharacter = "^(?=.*[a-zA-Z]).{1,}$"
        static let PasswordDigit = "^(?=.*[0-9]).{1,}$"
        static let PasswordSpecialCharactor = "^(?=.*[~!@#$%^&*()_+|}{:\"?><.]).{1,}$"
        static let UsernameSpecialCharactor = "^(?=.*[~!@#$%^&*()_+|}{:\"?><.]).{1,}$"
        static let HashTag = "[#＃﹟][^#＃﹟\\s]+"
        static let ExcludeHttp = "http(s?)\\:\\/\\/[0-9a-zA-Z]([-.\\w]*[0-9a-zA-Z])*(:(0-9)*)*(\\/?)([a-zA-Z0-9\\-\\.\\?\\,\\'\\/\\\\\\+&amp;%\\$#_]*)?"
        //static let UsernameAlphabet = "^[a-zA-Z][a-zA-Z0-9-._]$"//"([a-zA-Z][a-zA-Z0-9-._]+)";
    }
//    ^                         Start anchor
//    (?=.*[A-Z].*[A-Z])        Ensure string has two uppercase letters.
//    (?=.*[!@#$&*])            Ensure string has one special case letter.
//    (?=.*[0-9].*[0-9])        Ensure string has two digits.
//    (?=.*[a-z].*[a-z].*[a-z]) Ensure string has three lowercase letters.
//    .{8}                      Ensure string is of length 8.
//    $                         End anchor.
    
//    struct InvalidPattern {
//        struct MobilePhone {
//            static let HongKong = "^(11|99)|(999)"
//        }
//    }
    
    static func isChinaMobile(_ text: String) -> Bool {
        if text.length != 11 || RegexManager.matchesForRegexInText(RegexManager.ValidPattern.MobilePhone.China, text: text).isEmpty {
            return false
        }
        return true
    }
    
    static func isHKMobile(_ text: String) -> Bool {
        if text.length != 8 || RegexManager.matchesForRegexInText(RegexManager.ValidPattern.MobilePhone.HongKong, text: text).isEmpty {
            return false
        }
        return true
    }
    
    class func matchesForRegexInText(_ regex: String!, text: String!, hashTag:Bool = false) -> [String] {
        do {
            if hashTag {
                return text.substringsMatches(pattern:regex, exclude:RegexManager.ValidPattern.ExcludeHttp)
            }
                
            let regex = try NSRegularExpression(pattern: regex, options: [])
            let nsString = text as NSString
            let results = regex.matches(in: text, options: [], range: NSRange(location: 0, length: nsString.length))
            
            return results.map { nsString.substring(with: $0.range)}
        } catch let error as NSError {
            print("invalid regex: \(error.localizedDescription)")
            return []
        }
    }
}
