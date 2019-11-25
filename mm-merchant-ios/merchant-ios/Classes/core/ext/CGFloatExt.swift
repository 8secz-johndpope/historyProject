//
//  CGFloatExt.swift
//  storefront-ios
//
//  Created by MJ Ling on 2018/7/5.
//  Copyright © 2018年 WWE & CO. All rights reserved.
//

import Foundation
import UIKit

//以下是设备的PPI定义
let IPHONE_3GS_PPI = 163 //320
let IPHONE_4_PPI = 326   //640
let IPHONE_5_PPI = 326   //640
let IPHONE_6_PPI = 326   //750
let IPHONE_6P_PPI = 401  //1242 -> 1080
let IPHONE_7_PPI = 326   //750
let IPHONE_7P_PPI = 401  //1242 -> 1080
let IPHONE_8_PPI = 326  //750
let IPHONE_8P_PPI = 401 //1242 -> 1080
let IPHONE_X_PPI = 458  //1125

extension CGFloat {
    
    // 用于计算屏幕布局取整问题，当数值不合理时自动填充，根据PPI值最小计算合理值
    public func densityRounded() -> CGFloat {
//        let deviceModel = UIDevice.current.model
        
        var v = self.rounded()
        if self > 0 && v <= CGFloat(0.0) {
            v = CGFloat(1.0)
        }
        return v
    }
}
