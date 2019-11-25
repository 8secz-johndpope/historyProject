//
//  TutuWrapper.swift
//  merchant-ios
//
//  Created by Alan YU on 18/9/2017.
//  Copyright © 2017 WWE & CO. All rights reserved.
//

import PromiseKit

class TutuWrapper {
    
    typealias BeautySetting = (smoothing: CGFloat, whitening: CGFloat, skinColor: CGFloat, eyeSize: CGFloat, chinSize: CGFloat,fistSelect:Bool)
    
    enum Filter: String {
        case leica = "Leica" // 莱卡
        case noir = "Noir" // 黑白
        case sweet002 = "Sweet002" // 甜蜜
        case skinRuddy = "SkinRuddy" // 红润
        case tiffany = "Tiffany" // 蒂凡尼
        case olympus = "Olympus" //奥林巴斯
        case skinPink = "SkinPink" //粉嫩
        case nude = "Nude" //裸色
        case bonnie = "Bonnie" //邦妮
        case modern = "Modern" //现代
    }
    
    static let DefaultValue = CGFloat(0.5)
    static let MinValue = CGFloat(0)
    static let MaxValue = CGFloat(1)
    
    static func defaultSettings() -> BeautySetting {
        return (smoothing: 0, whitening: 0, skinColor: DefaultValue, eyeSize: 0, chinSize: 0,fistSelect:true)
    }
    
    static func apply(_ filter: Filter, forImage image: UIImage) -> Promise<PhotoFilterUtils.WrappedFilterResult> {
        return Promise<PhotoFilterUtils.WrappedFilterResult> { fulfill, reject in
            DispatchQueue.global(qos: .default).async(execute: {() -> Void in
                let manager = TutuObjCWrapper.tutuFilterManager()!
                guard manager.isInited else {
                    reject(Error.notInitYet.error)
                    return
                }
                guard manager.filterCodes.contains(where: { ($0 as? String) == filter.rawValue }) else {
                    reject(Error.missingFilter.error)
                    return
                }
                if let result = manager.process(with: image, byFilterCode: filter.rawValue) {
                    fulfill((nil, result))
                } else {
                    reject(Error.failToBeautyPhoto.error)
                }
            })
        }
    }
    
    static func beauty(_ photo: UIImage, settings: BeautySetting) -> Promise<(BeautySetting, UIImage)> {
        return Promise<(BeautySetting, UIImage)> { fulfill, reject in
            let skinFilterManager = TuSDKSkinFilterAPI.initSkinFilterWrap()
            skinFilterManager.submitSkinFilterParameter(
                with: photo,
                smoothing: settings.smoothing,
                whitening: settings.whitening,
                skinColor: settings.skinColor,
                eyeSize: settings.eyeSize,
                chinSize: settings.chinSize,
                completeHandler:  { () -> Void in
                    if let result = skinFilterManager.process(with: photo) {
                        fulfill((settings, result))
                    } else {
                        reject(Error.failToBeautyPhoto.error)
                    }
                }
            )
        }
    }
    
    private enum Error {
        case notInitYet
        case missingFilter
        case failToBeautyPhoto
        var error: NSError {
            switch self {
            case .notInitYet:
                return NSError(domain: "Tutu", code: -1, userInfo: ["reason": "FilterManager not init yet"])
            case .missingFilter:
                return NSError(domain: "Tutu", code: -2, userInfo: ["reason": "Missing filter"])
            case .failToBeautyPhoto:
                return NSError(domain: "Tutu", code: -3, userInfo: ["reason": "Fail to beauty photo"])
            }
        }
    }
    
}
