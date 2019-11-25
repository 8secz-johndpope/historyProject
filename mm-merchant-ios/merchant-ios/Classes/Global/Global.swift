//
//  Global.swift
//  merchant-ios
//
//  Created by Alan YU on 6/4/2016.
//  Copyright © 2016 WWE & CO. All rights reserved.
//

import Foundation
import RealmSwift

func PostNotification(_ key: String, object anObject: Any? = nil, userInfo anUserInfo: [AnyHashable: Any]? = nil) {
    DispatchQueue.main.async(execute: {
        NotificationCenter.default.post(name: Notification.Name(rawValue: key), object: anObject, userInfo: anUserInfo)
    })
}

let CachePath: String = {
    let paths = NSSearchPathForDirectoriesInDomains(.cachesDirectory, .userDomainMask, true)
    if let cachePath = paths.first {
        return cachePath
    }
    return NSTemporaryDirectory()
} ()

let RealmPath: String = {
    return CachePath + "/Realm/"
} ()

func JSONOptionalValue (_ value: Any?, defaultValue: Any? = nil) -> Any {
    if let result = value {
        return result
    } else if let result = defaultValue {
        return result
    }
    return NSNull()
}

let ScreenSize = UIScreen.main.bounds.size
let ScreenWidth = ScreenSize.width
let ScreenHeight = ScreenSize.height
let ScreenTop:CGFloat =  IsIphoneX ? 24.0 : 0.0
let ScreenStatusHeight: CGFloat = IsIphoneX ? 24.0 : 20.0
let ScreenBottom:CGFloat =  IsIphoneX ? 34.0 : 0.0
let TabbarHeight:CGFloat = (ScreenBottom + 49.0)
let IsIphoneX = UIScreen.main.bounds.equalTo(CGRect(x: 0, y: 0, width: 375, height: 812)) ? true : false
let StartYPos: CGFloat = IsIphoneX ? 88.0 : 64.0

func background_async(_ qos: DispatchQoS.QoSClass = .background, execute: @escaping (() -> Void)) {
    DispatchQueue.global(qos: qos).async(execute: execute)
}

func main_async(execute: @escaping (() -> Void)) {
    DispatchQueue.main.async(execute: execute)
}

func main_after(deadline: DispatchTime, execute: @escaping (() -> Void)) {
    DispatchQueue.main.asyncAfter(deadline: deadline, execute: execute)
}
