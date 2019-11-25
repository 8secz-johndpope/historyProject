//
//  DateTransformExtension.swift
//  merchant-ios
//
//  Created by Stephen Yuen on 22/3/2016.
//  Copyright © 2016 WWE & CO. All rights reserved.
//

import Foundation
import ObjectMapper

open class DateTransformExtension: DateTransform {
//    public struct DateFormatStyle {
//        static let DateTimeComplexWithoutZ = "yyyy-MM-dd'T'HH:mm:ss.SSS"
//        static let DateTimeComplex = "yyyy-MM-dd'T'HH:mm:ss.SSSZ"
//        static let DateTimeComplexMonthFirst = "MMM dd',' yyyy HH:mm:ss"
//        static let DateTimeComplexMonthFirstWithAmPm = "MMM dd',' yyyy HH:mm:ss a"
//        static let DateTimeSimple = "yyyy-MM-d'T'HH:mm:ss"
//        static let DateOnly = "yyyy-MM-dd"
//        static let DateOnlyWithDot = "yyyy.MM.dd"
//    }
    
    
    public enum DateFormatStyle : String {
        case dateTimeComplexWithoutZ = "yyyy-MM-dd'T'HH:mm:ss.SSS"
        case dateTimeComplex = "yyyy-MM-dd'T'HH:mm:ss.SSSZ"
        case dateTimeComplexMonthFirst = "MMM dd',' yyyy HH:mm:ss"
        case dateTimeComplexMonthFirstWithAmPm = "MMM dd',' yyyy HH:mm:ss a"
        case dateTimeSimple = "yyyy-MM-d'T'HH:mm:ss"
        case dateOnly = "yyyy-MM-dd"
        case dateOnlyWithDot = "yyyy.MM.dd"
        case dateAnalytics = "yyyy-MM-dd HH:mm:ss.SSS"
        
        static func values() -> [DateFormatStyle] {
            return [.dateTimeComplexWithoutZ, .dateTimeComplex, .dateTimeComplexMonthFirst, .dateTimeComplexMonthFirstWithAmPm, .dateTimeSimple, .dateOnly, .dateOnlyWithDot, .dateAnalytics]
        }
        
    }
    
    
    public typealias Object = Date
    public typealias JSON = String
    
    // as server return 2038-01-01T00:00:00.000 as nil!!
    var nilFor2038 = false
    let dateFormatter : DateFormatter
    var currentFormat = DateFormatStyle.dateTimeComplex.rawValue
    
    public init(dateFormatString: String) {
        currentFormat = dateFormatString
        if let format = DateFormatStyle(rawValue: dateFormatString) {
            dateFormatter = Constants.DateFormatter.getFormatter(format)
        }else {
            dateFormatter = DateFormatter()
            dateFormatter.dateFormat = dateFormatString
        }
    }

    
    public init(dateFormat: DateFormatStyle = DateFormatStyle.dateTimeComplex, nilFor2038 inNilFor2038: Bool = false) {
        nilFor2038 = inNilFor2038
        currentFormat = dateFormat.rawValue
        dateFormatter = Constants.DateFormatter.getFormatter(dateFormat)
    }
    
    open override func transformFromJSON(_ value: Any?) -> Date? {
        if let dateInString = value as? String {
            
            if nilFor2038 && (dateInString == "1980-01-01T00:00:00.000" || dateInString == "2038-01-01T00:00:00.000") {
                return nil
            }
            
            if let date = dateFormatter.date(from: dateInString) {
                return date
            }
            
            var formats = DateFormatStyle.values()
            if let format = DateFormatStyle(rawValue: currentFormat) {
                formats.remove(format)
            }
            for format in formats {
                if let date = Constants.DateFormatter.getFormatter(format).date(from: dateInString) {
                    return date
                }
            }
            
            if dateInString == "0000-00-00T00:00:00.000" {
                return nil
            }
            
            ErrorLogManager.sharedManager.recordNonFatalError(withException: .TypeMismatch, parameters: ["Date.String" : dateInString])
        } else if let dateInTimeInterval = value as? TimeInterval {
            return Date(timeIntervalSince1970: dateInTimeInterval)
        }
        
        if let value = value {
            ErrorLogManager.sharedManager.recordNonFatalError(withException: .TypeMismatch, parameters: ["Date.Unknown" : "\(value)"])
        }
        
        return nil
    }
    
    open func convertToJSON(_ value: Date?) -> String? {
        if let date = value {
            return dateFormatter.string(from: date)
        }
        return nil
    }
    
    
}
