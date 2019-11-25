//
//  NSDate+Extension.swift
//  TSWeChat
//
//  Created by Hilen on 2/22/16.
//  Copyright © 2016 Hilen. All rights reserved.
//

import Foundation

extension Date {
    static var milliseconds: TimeInterval {
        get { return Date().timeIntervalSince1970 * 1000 }
    }
    
    func isDaysAgo() -> Int {
        let calendar: Calendar = Calendar.current
        
        // Replace the hour (time) of both dates with 00:00
        let date1 = calendar.startOfDay(for: self)
        let date2 = calendar.startOfDay(for: Date())
        
        let flags = NSCalendar.Unit.day
        let components = (calendar as NSCalendar).components(flags, from: date1, to: date2, options: [])
        
        return components.day!
    }
    
    func minutesAgo() -> Int? {
        let interval = Date().timeIntervalSince(self)
        let ti = NSInteger(interval)
        let minutes = (ti / 60) % 60
        return minutes
    }
    
    func week() -> String {
        if let myWeekday = (Calendar.current as NSCalendar).components([NSCalendar.Unit.weekday], from: self).weekday {
            switch myWeekday {
            case 0:
                return "周日"
            case 1:
                return "周一"
            case 2:
                return "周二"
            case 3:
                return "周三"
            case 4:
                return "周四"
            case 5:
                return "周五"
            case 6:
                return "周六"
            default:
                break
            }
        }
        return "未取到数据"
    }
    
    static func messageAgoSinceDate(_ date: Date) -> String {
        return self.timeAgoSinceDate(date, numericDates: false)
    }
    
    static func timeAgoSinceDate(_ date: Date, numericDates: Bool) -> String {
        let calendar = Calendar.current
        let now = Date()
        let earliest = (now as NSDate).earlierDate(date)
        let latest = (earliest == now) ? date : now
        let components:DateComponents = (calendar as NSCalendar).components([
            NSCalendar.Unit.minute,
            NSCalendar.Unit.hour,
            NSCalendar.Unit.day,
            NSCalendar.Unit.weekOfYear,
            NSCalendar.Unit.month,
            NSCalendar.Unit.year,
            NSCalendar.Unit.second
            ], from: earliest, to: latest, options: NSCalendar.Options())
        
        if (components.year! >= 2) {
            return "\(String(describing: components.year)) 年前"
        } else if (components.year! >= 1){
            if (numericDates){
                return "1 年前"
            } else {
                return "去年"
            }
        } else if (components.month! >= 2) {
            return "\(String(describing: components.month)) 月前"
        } else if (components.month! >= 1){
            if (numericDates){
                return "1 个月前"
            } else {
                return "上个月"
            }
        } else if (components.weekOfYear! >= 2) {
            return "\(String(describing: components.weekOfYear)) 周前"
        } else if (components.weekOfYear! >= 1){
            if (numericDates){
                return "1 周前"
            } else {
                return "上一周"
            }
        } else if (components.day! >= 2) {
            return "\(String(describing: components.day)) 天前"
        } else if (components.day! >= 1){
            if (numericDates){
                return "1 天前"
            } else {
                return "昨天"
            }
        } else if (components.hour! >= 2) {
            return "\(String(describing: components.hour)) 小时前"
        } else if (components.hour! >= 1){
            return "1 小时前"
        } else if (components.minute! >= 2) {
            return "\(String(describing: components.minute)) 分钟前"
        } else if (components.minute! >= 1){
            return "1 分钟前"
        } else if (components.second! >= 3) {
            return "\(String(describing: components.second)) 秒前"
        } else {
            return "刚刚"
        }
    }
}
