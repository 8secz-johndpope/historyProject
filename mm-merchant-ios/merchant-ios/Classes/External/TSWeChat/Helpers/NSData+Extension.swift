//
//  NSData+Extension.swift
//  TSWeChat
//
//  Created by Hilen on 11/25/15.
//  Copyright © 2015 Hilen. All rights reserved.
//

import Foundation

extension Data {
    public var tokenString: String {
        let characterSet: CharacterSet = CharacterSet(charactersIn:"<>")
        let deviceTokenString: String = (self.description as NSString).trimmingCharacters(in: characterSet).replacingOccurrences(of: " ", with:"") as String
        return deviceTokenString
    }
    
    static func dataFromJSONFile(_ fileName: String) -> Data? {
        if let path = Bundle.main.path(forResource: fileName, ofType: "json") {
            do {
                let data = try Data(contentsOf: URL(fileURLWithPath: path), options: NSData.ReadingOptions.mappedIfSafe)
                return data
            } catch let error as NSError {
                print(error.localizedDescription)
                return nil
            }
        } else {
            print("Invalid filename/path.")
            return nil
        }
    }
    
    var MD5String: String {
        var digest = [UInt8](repeating: 0, count: Int(CC_MD5_DIGEST_LENGTH))
        _ =  self.withUnsafeBytes { bytes in
            CC_MD5(bytes, CC_LONG(self.count), &digest)
        }
        var digestHex = ""
        for index in 0..<Int(CC_MD5_DIGEST_LENGTH) {
            digestHex += String(format: "%02x", digest[index])
        }
        return digestHex
    }
}
