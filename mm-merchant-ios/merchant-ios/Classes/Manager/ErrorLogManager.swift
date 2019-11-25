//
//  ErrorLogManager.swift
//  merchant-ios
//
//  Created by Stephen Yuen on 25/7/2016.
//  Copyright © 2016 WWE & CO. All rights reserved.
//

import Foundation
import Crashlytics

class ErrorLogManager {
    
    enum Exception: String {
        case NullPointer = "NullPointerException"
        case NullPointerOrTypeMismatch = "NullPointerTypeMismatchException"
        case TypeMismatch = "TypeMismatchException"
        case IndexOutOfBounds = "IndexOutOfBoundsException"
        
        case FailToParseAPIResponse = "FailToParseAPIResponse"
        case DataIsEmpty = "DataIsEmpty"
    }
    
    class var sharedManager: ErrorLogManager {
        get {
            struct Singleton {
                static let instance = ErrorLogManager()
            }
            return Singleton.instance
        }
    }
    
    private init() {
        
    }
    
    func recordNonFatalError(withMessage message: String = "", parameters: [String : String]? = nil, error: NSError? = nil, appendUserKey: Bool = true) {
        var printableData = ""
        
        if let parameters = parameters {
            for (key, value) in parameters {
                printableData += key + "[\(value)]\n"
            }
        }
        
        var domain = Platform.Domain
        
        if appendUserKey {
            domain += "@" + Context.getUserKey() + ";"
        }
        
        domain += " Message: " + message + "; Data: " + printableData
        
        let customError = NSError(domain: domain, code: error?.code ?? 0, userInfo: error?.userInfo)
        Crashlytics.sharedInstance().recordError(customError)
    }
    
    func recordNonFatalError(withException exception: Exception, parameters: [String : String]? = nil) {
        recordNonFatalError(withMessage: exception.rawValue, parameters: parameters)
    }
    
    func recordNonFatalError(_ error: NSError) {
        Crashlytics.sharedInstance().recordError(error)
    }
    
}
