//
//  String+Crypto.swift
//  TSWeChat
//
//  Created by Hilen on 2/19/16.
//  Copyright © 2016 Hilen. All rights reserved.
//

import Foundation

extension String {
    
    var MD5String: String {
        return data(using: String.Encoding.utf8)?.MD5String ?? self
    }

}
