//
//  TSUserDefaults.swift
//  TSWeChat
//
//  Created by Hilen on 11/12/15.
//  Copyright © 2015 Hilen. All rights reserved.
//

/// NSUserDefaults 的简单封装

import Foundation

private let TSDefaults = UserDefaults.standard

class TSUserDefaults {
    // MARK: - getter
    
    class func getObject(_ key: String) -> Any? {
        return TSDefaults.object(forKey: key)
    }
    
    class func getInt(_ key: String) -> Int {
        return TSDefaults.integer(forKey: key)
    }
    
    class func getBool(_ key: String) -> Bool {
        return TSDefaults.bool(forKey: key)
    }
    
    class func getFloat(_ key: String) -> Float {
        return TSDefaults.float(forKey: key)
    }
    
    class func getString(_ key: String) -> String? {
        return TSDefaults.string(forKey: key)
    }
    
    class func getData(_ key: String) -> Data? {
        return TSDefaults.data(forKey: key)
    }
    
    class func getArray(_ key: String) -> NSArray? {
        return TSDefaults.array(forKey: key) as NSArray?
    }
    
    class func getDictionary(_ key: String) -> NSDictionary? {
        return TSDefaults.dictionary(forKey: key) as NSDictionary?
    }
    
    // MARK: - getter 获取 Value 带上默认值

    class func getObject(_ key: String, defaultValue: Any) -> Any? {
        if getObject(key) == nil {
            return defaultValue 
        }
        return getObject(key)
    }
    
    class func getInt(_ key: String, defaultValue: Int) -> Int {
        if getObject(key) == nil {
            return defaultValue
        }
        return getInt(key)
    }
    
    class func getBool(_ key: String, defaultValue: Bool) -> Bool {
        if getObject(key) == nil {
            return defaultValue
        }
        return getBool(key)
    }
    
    class func getFloat(_ key: String, defaultValue: Float) -> Float {
        if getObject(key) == nil {
            return defaultValue
        }
        return getFloat(key)
    }
    
    class func getString(_ key: String, defaultValue: String) -> String? {
        if getObject(key) == nil {
            return defaultValue
        }
        return getString(key)
    }
    
    class func getData(_ key: String, defaultValue: Data) -> Data? {
        if getObject(key) == nil {
            return defaultValue
        }
        return getData(key)
    }
    
    class func getArray(_ key: String, defaultValue: NSArray) -> NSArray? {
        if getObject(key) == nil {
            return defaultValue
        }
        return getArray(key)
    }
    
    class func getDictionary(_ key: String, defaultValue: NSDictionary) -> NSDictionary? {
        if getObject(key) == nil {
            return defaultValue
        }
        return getDictionary(key)
    }
    
    
    // MARK: - Setter
    
    class func setObject(_ key: String, value: Any?) {
        if value == nil {
            TSDefaults.removeObject(forKey: key)
        } else {
            TSDefaults.set(value, forKey: key)
        }
        TSDefaults.synchronize()
    }
    
    class func setInt(_ key: String, value: Int) {
        TSDefaults.set(value, forKey: key)
        TSDefaults.synchronize()
    }
    
    class func setBool(_ key: String, value: Bool) {
        TSDefaults.set(value, forKey: key)
        TSDefaults.synchronize()
    }
    
    class func setFloat(_ key: String, value: Float) {
        TSDefaults.set(value, forKey: key)
        TSDefaults.synchronize()
    }
    
    class func setString(_ key: String, value: NSString?) {
        if (value == nil) {
            TSDefaults.removeObject(forKey: key)
        } else {
            TSDefaults.set(value, forKey: key)
        }
        TSDefaults.synchronize()
    }
    
    class func setData(_ key: String, value: Data) {
        setObject(key, value: value)
    }
    
    class func setArray(_ key: String, value: NSArray) {
        setObject(key, value: value)
    }
    
    class func setDictionary(_ key: String, value: NSDictionary) {
        setObject(key, value: value)
    }
    
    // MARK: - Synchronize
    
    class func Sync() {
        TSDefaults.synchronize()
    }
}


