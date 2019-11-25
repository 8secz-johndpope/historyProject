//
//  StringExtension.swift
//  merchant-ios
//
//  Created by Koon Kit Chan on 29/10/15.
//  Copyright © 2015 Koon Kit Chan. All rights reserved.
//

import Foundation

import UIKit
import Alamofire

extension String {
    
    mutating func clean() {
        if self.first == "+" {
            self = self.replacingOccurrences(of: " ", with: "")
            self = self.replacingOccurrences(of: "-", with: "")
        }
    }
    
    func trim() -> String {
        return self.trimmingCharacters(in: NSCharacterSet.whitespaces)
    }
    
    static func localize(_ key : String) -> String{
        return Bundle.main.localizedString(forKey: key, value: nil, table: Context.getCc().lowercased())
    }
    
    private func regCheck(_ regEx: String) -> Bool {
        let regTest = NSPredicate(format:"SELF MATCHES %@", regEx)
        return regTest.evaluate(with: self)
    }
    
    // return true if it is a valid email / phone number
    func isValidMMUsername() -> Bool {
        let isEmail = self.isValidEmail()
        let isPhone = self.isValidPhone()
        return isEmail || isPhone
    }
    
    func isValidEmail() -> Bool {
        let regEx = "^[a-zA-Z0-9.!#$%&'*+/=?^_`{|}~-]+@[a-zA-Z0-9](?:[a-zA-Z0-9-]{0,61}[a-zA-Z0-9])?(?:\\.[a-zA-Z0-9](?:[a-zA-Z0-9-]{0,61}[a-zA-Z0-9])?)*$"
        return regCheck(regEx)
    }
    
    func isValidPhone() -> Bool {
        let regEx = "\\++[0-9 -]*"   // for input must start at "+" and allow number, '-' and ' '
        return regCheck(regEx)
    }
    
    func isNumberic() -> Bool {
        let regEx = "^[0-9]*$"
        return regCheck(regEx)
    }
    
    func isValidPassword() -> Bool {
        let regEx = "^(?=.*[a-z])(?=.*[A-Z])(?=.*[0-9])(?=.*[~!@#$%^&*()_+|}{:\"?><.]).{8,}$"
        return regCheck(regEx)
    }
    
    func isValidUserName() -> Bool {
        let regEx = "^[A-Za-z][a-zA-Z0-9-._]{5,16}$"
        return regCheck(regEx)
    }
    
    mutating func replace(_ str: String?, with: String, options: String.CompareOptions) {
        guard let str = str else { return }
        if let range = range(of: str, options: options, range: nil, locale: nil) {
            return replaceSubrange(range, with: with)
        }
    }
    
    func contain(_ str: String?) -> Bool {
        if let keyword = str {
            
            if self.range(of: keyword) != nil {
                return true
            }
            
            if self.lowercased().range(of: keyword) != nil {
                return true
            }
            
        }
        return false
    }
    
    func containCharactor() -> Bool {
        let charset = CharacterSet(charactersIn: "abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLKMNOPQRSTUVWXYZ")
        if self.lowercased().rangeOfCharacter(from: charset) != nil {
            return true
        }
        return false
    }
    
    func containNumber() -> Bool {
        let charset = CharacterSet(charactersIn: "0123456789")
        if self.lowercased().rangeOfCharacter(from: charset) != nil {
            return true
        }
        return false
    }
    
    func containSpecialCharactor() -> Bool {
        let charset = CharacterSet(charactersIn: "abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLKMNOPQRSTUVWXYZ0123456789")
        if self.lowercased().rangeOfCharacter(from: charset.inverted) != nil {
            return true
        }
        return false
    }
    
    func isValidInvitationName() -> Bool{
        let regEx = "[a-z A-Z 0-9 ,_.]{1,25}$"
        return regCheck(regEx)
    }
    
    func containsEmoji() -> Bool {
        for scalar in unicodeScalars {
            switch scalar.value {
            case 0x200D...0x2BFF,
                 0x3200...0x33FF,
                 0x1F000...0x1F9FF:
                return true
            default:
                continue
            }
        }
        return false
    }
    
    var length: Int {
        get {
            return self.count
        }
    }
    
    static func random(_ length: Int = 20) -> String {
        let base = "abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789"
        var randomString: String = ""
        
        for _ in 0..<length {
            let randomValue = arc4random_uniform(UInt32(base.count))
            randomString += "\(base[base.index(base.startIndex, offsetBy: Int(randomValue))])"
        }
        
        return randomString
    }
    
    func isEmptyOrNil() -> Bool {
        if self.trimmingCharacters(in: CharacterSet.whitespaces) .length == 0 {
            return true
        }
        return false
    }
    
    func toJSON() -> Any? {
        let data = self.data(using: String.Encoding.utf8, allowLossyConversion: true)
        if let data = data {
            let parsedJSON: Any?
            do {
                parsedJSON = try JSONSerialization.jsonObject(with: data, options: JSONSerialization.ReadingOptions.allowFragments)
            } catch _ {
                parsedJSON = nil
            }
            return parsedJSON
        }
        
        return nil
    }
    
    func queryStringToDict() -> [String: String] {
        
        let query = self
        var dictionary = [String: String]()
        
        for keyValueString in query.components(separatedBy: "&") {
            var parts = keyValueString.components(separatedBy: "=")
            if parts.count < 2 { continue; }
            
            let key = parts[0].removingPercentEncoding!
            let value = parts[1].removingPercentEncoding!
            
            dictionary[key] = value
        }
        
        return dictionary
        
    }
    
    func subStringToIndex(_ index: Int) -> String {
        var subString = self
        
        if subString.length > index {
            subString = (subString as NSString).substring(to: index)
        }
        
        return subString
    }
    
    func subStringFromIndex(_ index: Int) -> String {
        var subString = self
        subString = (subString as NSString).substring(from: index)
        return subString
    }
    
    var isPureChinese: Bool {
        guard let rangeChinese = self.range(of: "\\p{Han}*\\p{Han}", options: .regularExpression) else {
            return false //Not contains any Chinese
        }
        
        var result = false
        switch rangeChinese {
        case self.startIndex..<self.endIndex:
            //All words are Chinese
            result = true
            
        default:
            //contains any Chinese
            result = false
        }
        
        return result
    }
    
    var isLadyOrSir: Bool {
        let str = self.replacingOccurrences(of: " ", with: "")
        if str.contain("小姐") || str.contain("女士") || str.contain("先生") {
            return true
        }
        return false
    }
    
    func md5() -> String {
        let context = UnsafeMutablePointer<CC_MD5_CTX>.allocate(capacity: 1)
        var digest = Array<UInt8>(repeating:0, count:Int(CC_MD5_DIGEST_LENGTH))
        CC_MD5_Init(context)
        CC_MD5_Update(context, self, CC_LONG(self.lengthOfBytes(using: String.Encoding.utf8)))
        CC_MD5_Final(&digest, context)
        context.deallocate()
        var hexString = ""
        for byte in digest {
            hexString += String(format:"%02x", byte)
        }
        
        return hexString
    }
    

    func isEqualToString(_ find: String) -> Bool {
        return String(format: self) == find
    }
    
    func nsRange(fromRange range: Range<Index>) -> NSRange {
        let from = range.lowerBound
        let to = range.upperBound
        
        let location = distance(from: startIndex, to: from)
        let length = distance(from: from, to: to)
        
        return NSRange(location: location, length: length)
    }
    
    func range(from nsRange: NSRange) -> Range<String.Index>? {
        guard
            let from16 = utf16.index(utf16.startIndex, offsetBy: nsRange.location, limitedBy: utf16.endIndex),
            let to16 = utf16.index(from16, offsetBy: nsRange.length, limitedBy: utf16.endIndex),
            let from = String.Index(from16, within: self),
            let to = String.Index(to16, within: self)
            else { return nil }
        return from ..< to
    }
    var hasOnlyNewlineSymbols: Bool {
        return trimmingCharacters(in: CharacterSet.newlines).isEmpty
    }
    
    func insertSomeStr(element ele: Character, at index: Int) -> String {
        var str = self
        if str.length > index {
            str.insert(ele, at: str.index(str.startIndex, offsetBy: index))
        }
        if str.length > index*2 {
            str.insert(ele, at: str.index(str.startIndex, offsetBy: index*2 + 1))
        }
        return str
    }
}

extension String: URLRequestConvertible {
    
    public func asURLRequest() throws -> URLRequest {
        guard let url = URL(string: self) else { throw AFError.invalidURL(url: self) }
        return URLRequest(url: url)
    }
    
}
