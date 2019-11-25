//
//  MMDateStringExtension.swift
//  merchant-ios
//
//  Created by Tony Fung on 28/4/2016.
//  Copyright © 2016年 WWE & CO. All rights reserved.
//

import Foundation

extension Date {
    
    func getUTCFormateDate() -> String {
        let dateFormatter = DateFormatter()
        let timeZone = TimeZone(identifier: "UTC")
        dateFormatter.timeZone = timeZone
        dateFormatter.dateFormat = "yyyy-MM-dd HH:mm:ss"
        return dateFormatter.string(from: self)
    }
    

    
    public var postTimeString: String{
        get {
            let currentDate = Date.init()
            let cc = Context.getCc()
            let timeInterval = -self.timeIntervalSinceNow
            let day = Int(timeInterval / 86400)
            let hour = Int(timeInterval / 3600)
            let min = Int(timeInterval / 60)
            
            let yearBetween = (Calendar.current as NSCalendar).components(NSCalendar.Unit.year, from: self, to: currentDate, options: NSCalendar.Options.init(rawValue: 0)).year
            
            if yearBetween! < 1{ //same year
                if day > 7{ //Publish from +7 days - 1 year ago
                    switch cc.lowercased() {
                    case "cht", "chs"://M月D日 HH:MM or MM月DD日 HH:MM
                        return Constants.DateFormatter.getFormatter("M'\(String.localize("LB_CA_MONTH"))'d'\(String.localize("LB_CA_DAY"))' HH:mm").string(from: self)
                    default://en DD-MM HH:MM
                        let dateFormat = DateFormatter()
                        dateFormat.dateFormat = "dd-MM HH:mm"
                        return dateFormat.string(from: self)
                    }
                }
                else{
                    if day >= 1 {//Publish from 1 day - 7 days ago
                        if day == 1{
                            switch cc.lowercased() {
                            case "cht", "chs":
                                return String.localize("LB_DAY_AGO_PLURAL").replacingOccurrences(of: "{0}", with: "\(1)")
                            default:
                                return String.localize("LB_DAY_AGO_SINGLE")
                            }
                        }
                        else{
                            return String.localize("LB_DAY_AGO_PLURAL").replacingOccurrences(of: "{0}", with: "\(day)")
                        }
                    }
                    else{
                        if hour >= 1{//Publish from 1 hour - 24 hours ago
                            if hour == 1{
                                switch cc.lowercased() {
                                case "cht", "chs":
                                    return String.localize("LB_HOUR_AGO_PLURAL").replacingOccurrences(of: "{0}", with: "\(1)")
                                default:
                                    return String.localize("LB_HOUR_AGO_SINGLE")
                                }
                            }
                            else{
                                return String.localize("LB_HOUR_AGO_PLURAL").replacingOccurrences(of: "{0}", with: "\(hour)")
                            }
                        }
                        else{//Publish from 0 - 59 minute ago
                            if min <= 1{
                                switch cc.lowercased() {
                                case "cht", "chs":
                                    return String.localize("LB_MIN_AGO_PLURAL").replacingOccurrences(of: "{0}", with: "\(1)")
                                default:
                                    return String.localize("LB_MIN_AGO_SINGLE")
                                }
                            }
                            else{
                                return String.localize("LB_MIN_AGO_PLURAL").replacingOccurrences(of: "{0}", with: "\(min)")
                            }
                        }
                    }
                }
            } else{//Publish from +1 years ago //DD-MM-YYYY
                let dateFormat = DateFormatter()
                dateFormat.dateFormat = "dd-MM-yyyy"
                return dateFormat.string(from: self)
            }
        }
    }
    
    public var commentTimeString: String {
        get {
            let timeInterval = -self.timeIntervalSinceNow
            let day = Int(timeInterval / 86400)
            let hour = Int(timeInterval / 3600)
            let min = Int(timeInterval / 60)
            
            if day > 1 {
                return Constants.DateFormatter.getFormatter("yyyy-MM-dd HH:mm").string(from: self)
            } else {
                if (day > 0) {
                    return String.localize("LB_YESTERDAY") + " " + Constants.DateFormatter.getFormatter("HH:mm").string(from: self)
                } else if (hour > 1) {
                    return String.localize("LB_HOUR_AGO_PLURAL").replacingOccurrences(of: "{0}", with: String(hour))
                } else if hour > 0 {
                    return String.localize("LB_HOUR_AGO_SINGLE")
                } else if min > 1 {
                    return String.localize("LB_MIN_AGO_PLURAL").replacingOccurrences(of: "{0}", with: String(min))
                } else if min == 1{
                    return String.localize("LB_MIN_AGO_SINGLE")
                }
                else{
                    return String.localize("LB_CA_TIMESTAMP_NOW")
                }
            }
        }
    }
    
    public var detailChatTimeString: String? {
        get {
            let calendar = Calendar.current
            let now = Date()
            let earliest = (now as NSDate).earlierDate(self)
            
            let selfComponents:DateComponents = (calendar as NSCalendar).components([
                NSCalendar.Unit.second,
                NSCalendar.Unit.minute,
                NSCalendar.Unit.hour
                ], from: earliest)
            
            return String(format: "%02zd:%02zd:%02zd", selfComponents.hour!, selfComponents.minute!, selfComponents.second!)
        }
    }

    func toProductLikeTimeString() -> String{
        return self.postTimeString
    }
}
