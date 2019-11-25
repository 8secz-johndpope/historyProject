//
//  TSLogger.swift
//  TSWeChat
//
//  Created by Hilen on 12/3/15.
//  Copyright © 2015 Hilen. All rights reserved.
//

import Foundation
import XCGLogger

let documentsDirectory: URL = {
    let urls = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)
    return urls[urls.endIndex - 1]
}()

let cacheDirectory: URL = {
    let urls = FileManager.default.urls(for: .cachesDirectory, in: .userDomainMask)
    return urls[urls.endIndex - 1]
}()

let log: XCGLogger = {
    // Setup XCGLogger
    return XCGLogger.default
}()
