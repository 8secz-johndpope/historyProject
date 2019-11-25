//
//  Camera360Wrapper.swift
//  Camera360
//
//  Created by Alan YU on 6/9/2017.
//  Copyright © 2017 YDIVA.COM. All rights reserved.
//

import UIKit
import Foundation
import PromiseKit
import ObjectMapper
import Alamofire
import Kingfisher

class Camera360Wrapper {
    
    enum Filter: String {
        case C360_Skin_Soft // 魔法美肤 | 自然美肤
        case C360_Skin_DepthClean // 魔法美肤 | 光滑美肤
        case C360_Skin_SoftWhitening // 魔法美肤 | 轻度美白
        case C360_Skin_DepthWhitening // 魔法美肤 | 深度美白
        case C360_Skin_CleanBW // 魔法美肤 | 艺术黑白
        case C360_Skin_Sunshine // 魔法美肤 | 暖暖阳光
        case C360_Skin_Greenish // 魔法美肤 | 清新丽人
        case C360_Skin_RedLip // 魔法美肤 | 香艳红唇
        case C360_Skin_Sweet // 魔法美肤 | 甜美可人1
        case C360_Skin_SweetNew // 魔法美肤 | 甜美可人2
        case C360_LightColor_SweetRed // 日系 | 甜美
        case C360_LightColor_ColorBlue // 日系 | 清凉
        case C360_LightColor_Lighting0 // 日系 | 阳光灿烂
        case C360_LightColor_Lighting1 // 日系 | 一米阳光
        case C360_LightColor_Beauty // 日系 | 唯美
        case C360_LightColor_Cyan // 日系 | 果冻
        case C360_LightColor_LowSatGreen // 日系 | 淡雅
        case C360_LightColor_NatureFresh // 日系 | 清新
        case C360_LightColor_NatureWarm // 日系 | 温暖
        case C360_Seulki // 韩范 | 浅咖啡
        case C360_Yuri // 韩范 | 薄荷绿
        case C360_Hyejin // 韩范 | 清新蓝
        case C360_Miyeon // 韩范 | 甜蜜粉
        case C360_Doona // 韩范 | 优雅白
        case C360_Eunjin // 韩范 | 浆果红
        case C360_Hyori // 韩范 | 妩媚紫
        case C360_H1 // 欧美风 | 渔人码头
        case C360_H2 // 欧美风 | 夏威夷
        case C360_H3 // 欧美风 | 西雅图
        case C360_H4 // 欧美风 | 好莱坞
        case C360_H5 // 欧美风 | 密西西比
        case C360_H6 // 欧美风 | 奥斯丁
        case C360_V5 // 视觉人像 | 松烟墨
        case C360_V6 // 视觉人像 | 松脂
        case C360_V7 // 视觉人像 | 胡桃栗
        case C360_V8 // 视觉人像 | 翡冷翠
        case C360_Skin_S1 // 一妆到底 | 亮颜发光
        case C360_Skin_S2 // 一妆到底 | 平衡哑光
        case C360_Skin_S3 // 一妆到底 | 明眸亮唇
        case C360_w1 // 宛如初现 | 初现美白
        case C360_w2 // 宛如初现 | 初现丽人
        case C360_w3 // 宛如初现 | 初现增强
        case C360_w4 // 宛如初现 | 初现韩范
        case C360_w5 // 宛如初现 | 初现日系
        case C360_w6 // 宛如初现 | 初现红润
        case C360_Sketch_Line // 手绘 | 黑白线条
        case C360_Sketch_BW // 手绘 | 黑白超现实
        case C360_Sketch_Yellow // 手绘 | 那些年
        case C360_Sketch_Color // 手绘 | 彩色
        case C360_Sketch_ColorMul // 手绘 | 油彩画
        case C360_Sketch_Neon // 手绘 | 霓虹
        case C360_Sketch_WideLine // 手绘 | 炭笔画
        case C360_Sketch_LightColor // 手绘 | 亮彩
        case C360_Sketch_SoftColor // 手绘 | 淡彩
        case C360_CartoonEX_Line // 漫画 | 线条卡通
        case C360_CartoonEX_Color // 漫画 | 彩色线条卡通
        case C360_CartoonEX_BlockColor // 漫画 | 彩色块卡通
        case C360_CartoonEX_Sweet // 漫画 | 甜美卡通
        case C360_CartoonEX_Colorful // 漫画 | 多彩卡通
        case C360_CartoonEX_Greenish // 漫画 | 素雅卡通
        case C360_CartoonEX_Color2 // 漫画 | 彩色卡通
        case C360_CartoonEX_RedLip // 漫画 | 诱惑
        case C360_CartoonEX_NewOubama // 漫画 | 新奥巴马头像
        case C360_CartoonEX_NewBadge // 漫画 | 新印章
        case C360_Retro_Decadent // 复古 | 紫色迷情
        case C360_Retro_Hazy // 复古 | 复古暖黄
        case C360_Retro_Rustic // 复古 | 金色年华
        case C360_Retro_Recall // 复古 | 橙黄回忆
        case C360_Retro_Blue // 复古 | 夜色朦胧
        case C360_Retro_Turn // 复古 | 蓦然回首
        case C360_Retro_Yellow // 复古 | 泛黄记忆
        case C360_Retro_Greenish // 复古 | 祖母绿
        case C360_Retro_Blueish // 复古 | 弥漫森林
        case C360_LOMO_Cyan // LOMO | 青色
        case C360_LOMO_Film // LOMO | 电影
        case C360_LOMO_Greenish // LOMO | 淡青
        case C360_LOMO_Fashion // LOMO | 时尚
        case C360_LOMO_Recall // LOMO | 浅回忆
        case C360_LOMO_Cold // LOMO | 冷艳
        case C360_LOMO_Warm // LOMO | 暖秋
        case C360_LOMO_Zest // LOMO | 热情
        case C360_LOMO_Leaf // LOMO | 枫叶
        case E_119 // LOFT | 青涩
        case E_120 // LOFT | 慵懒
        case E_121 // LOFT | 沉静
        case E_122 // LOFT | 午后
        case E_123 // LOFT | 暮色
        case E_124 // LOFT | 流年
        case E_112 // 弗莱胶片 | Gold
        case E_113 // 弗莱胶片 | Vista
        case E_114 // 弗莱胶片 | Xtra
        case E_115 // 弗莱胶片 | Ektar
        case E_116 // 弗莱胶片 | Veliva
        case E_117 // 弗莱胶片 | Profoto
        case E_118 // 弗莱胶片 | Superia
        case C360_HDR_Soft // 风景 | 轻柔
        case C360_HDR_Vivid // 风景 | 绚丽
        case C360_HDR_Enhance // 风景 | 经典
        case C360_HDR_Shine // 风景 | 光绚
        case C360_HDR_Storm // 风景 | 风暴
        case C360_HDR_BW1 // 风景 | HDR黑白1
        case C360_HDR_BW // 风景 | HDR黑白2
        case C360_HDR_Stand // 风景 | HDR标准
        case C360_HDR_Strong // 风景 | HDR浓郁
        case C360_HDR_Natural // 风景 | HDR原色
        case C360_HDR_Lighting // 风景 | HDR亮丽
        case C360_HDR_Night // 风景 | HDR夜间补光
        case C360_Colorful_rainbow // 流光溢彩 | 彩虹
        case C360_Colorful_Crystal // 流光溢彩 | 水晶
        case C360_Colorful_Sky // 流光溢彩 | 碧空如洗
        case C360_Colorful_Cloud // 流光溢彩 | 天高云淡
        case C360_Colorful_Ripple // 流光溢彩 | 微波荡漾
        case C360_Colorful_Vivid // 流光溢彩 | 绚丽多彩
        case C360_Colorful_Flow // 流光溢彩 | 流云漓彩
        case C360_Colorful_Red // 流光溢彩 | 姹紫嫣红
        case C360_Colorful_Gold // 流光溢彩 | 金色秋天
        case C360_Colorful_Purple // 流光溢彩 | 紫色迷情
        case C360_ShiftColor_Red1 // 魔法色彩 | 樱桃红
        case C360_ShiftColor_Red2 // 魔法色彩 | 中国红
        case C360_ShiftColor_Yellow1 // 魔法色彩 | 橘子橙
        case C360_ShiftColor_Green // 魔法色彩 | 绿之森
        case C360_ShiftColor_Blue // 魔法色彩 | 深海蓝
        case C360_ShiftColor_SkyBlue // 魔法色彩 | 天空蓝
        case C360_ShiftColor_Yellow2 // 魔法色彩 | 柠檬黄
        case C360_ShiftColor_Purple // 魔法色彩 | 熏衣紫
        case C360_ShiftColor_Summer // 魔法色彩 | 魔法夏天
        case C360_BW_Normal // 黑白 | 标准
        case C360_BW_Enhance // 黑白 | 雅黑
        case C360_BW_Strong // 黑白 | 强烈
        case C360_BW_Storm // 黑白 | 黑白风暴
        case C360_BW_Art // 黑白 | 黑白艺术
    }
    
    private static let APIKey = "59cb528b72955557205ef2c1"
    private static let SecretKey = "IDy8R6FfS5DQEyFwqNSWlR8RJwfCbF8wHT5Tpqjk"
    private static let APIDomain = "https://effectapi.camera360.com"
    
    private static func generateAccessToken(byURL url: String, body: String?) -> String? {
        
        var data = url + "\n"
        if let body = body {
            data += body
        }
        
        if let cKey = SecretKey.cString(using: String.Encoding.utf8), let cData = data.cString(using: String.Encoding.utf8) {
            var result = [CUnsignedChar](repeating: 0, count: Int(CC_SHA1_DIGEST_LENGTH))
            CCHmac(
                CCHmacAlgorithm(kCCHmacAlgSHA1),
                cKey,
                Int(strlen(cKey)),
                cData,
                Int(strlen(cData)),
                &result
            )
            let hmacData = Data(bytes: UnsafePointer<UInt8>(result), count: (Int(CC_SHA1_DIGEST_LENGTH)))
            let hmacBase64 = hmacData.base64EncodedString(options: NSData.Base64EncodingOptions.lineLength64Characters)
            return "Camera360 " + APIKey + ":" + String(hmacBase64).replacingOccurrences(of: "+", with: "-").replacingOccurrences(of: "/", with: "_")
        }
        
        return nil
        
    }
    
    private static func camera360Request(byPath path: String, method: Alamofire.HTTPMethod, parameters: [String: String] = [:]) -> URLRequest? {
        
        if let url = URL(string: APIDomain + path) {
            
            var bodyList = [String]()
            for (k, v) in parameters {
                if let key = k.addingPercentEncoding(withAllowedCharacters: CharacterSet.urlQueryAllowed),
                    let value = v.addingPercentEncoding(withAllowedCharacters: CharacterSet.urlQueryAllowed) {
                    bodyList.append(key + "=" + value)
                }
            }
            
            let bodyString = bodyList.joined(separator: "&")
            
            var request = URLRequest(url: url)
            request.httpMethod = method.rawValue
            request.httpBody = bodyString.data(using: String.Encoding.utf8)
            
            if let accessToken = generateAccessToken(byURL: path, body: bodyString) {
                request.setValue(accessToken, forHTTPHeaderField: "Authorization")
            }
            
            return request
            
        }
        
        return nil
    }
    
    private static func uploadToken(_ uploadOnly: Bool = false) -> Promise<Resource> {
        return Promise<Resource> { fulfill, reject in
            
            let path = "/uploadtoken?uploadOnly=" + (uploadOnly ? "1" : "0")
            
            if let request = camera360Request(
                byPath: path,
                method: .get
                ) {
                
                Alamofire
                    .request(request)
                    .validate()
                    .responseJSON(completionHandler: { (response) in
                        switch response.result {
                        case .success(let value):
                            if let uploadToken = Mapper<Resource>().map(JSONObject: value) {
                                fulfill(uploadToken)
                            } else {
                                reject(Error.mappingError.error)
                            }
                        case .failure(let error):
                            reject(error)
                        }
                    })
                
            } else {
                reject(Error.invalidRequst.error)
            }
        }
    }
    
    private static func upload(_ image: UIImage, forResource resource: Resource, withFilter filter: Filter, strength: Int = 100, rotateAngle: Int = 0, mirrorX: Int = 0, mirrorY: Int = 0) -> Promise<PhotoFilterUtils.WrappedFilterResult> {
        return Promise<PhotoFilterUtils.WrappedFilterResult> { fulfill, reject in
            
            if !resource.valid() {
                reject(Error.invalidResource.error)
                return
            }
            
            Alamofire.upload(multipartFormData: { multipartFormData in
                
                let addPostData = { (key: String, value: String) in
                    if let valueData = value.data(using: String.Encoding.utf8, allowLossyConversion: false) {
                        multipartFormData.append(valueData, withName: key)
                    }
                }
                
                if let fileData = UIImageJPEGRepresentation(image, 0.9) {
                    multipartFormData.append(fileData, withName: "file", fileName: "image.jpeg", mimeType: "image/jpeg")
                }
                
                //                    let (key, strength) = filter.values
                
                addPostData("key", resource.key!)
                addPostData("token", resource.token!)
                addPostData("x:filter", "\(filter)")
                addPostData("x:strength", "\(strength)")
                addPostData("x:rotateAngle", "\(rotateAngle)")
                addPostData("x:mirrorX", "\(mirrorX)")
                addPostData("x:mirrorY", "\(mirrorY)")
                
            }, to: resource.uphost!, method: .post, headers: nil, encodingCompletion: { encodingResult in
                switch encodingResult {
                case .success(let request, _, _):
                    request.responseJSON(completionHandler: { (response) in
                        switch response.result {
                        case .success(let value):
                            if let result = Mapper<Result>().map(JSONObject: value) {
                                if let url = result.url, let imageURL = URL(string: url) {
                                    KingfisherManager.shared.retrieveImage(with: imageURL, options: nil, progressBlock: nil, completionHandler: { (image, error, cacheType, imageURL) in
                                        if let image = image {
                                            cache(url, forResource: resource, filter: filter)
                                            fulfill((resource, image))
                                        } else {
                                            reject(Error.failToDownloadImage.error)
                                        }
                                    })
                                }
                            } else {
                                reject(Error.mappingError.error)
                            }
                        case .failure(let error):
                            reject(error)
                        }
                    })
                case .failure(let encodingError):
                    reject(encodingError)
                }
            })
            
        }
    }
    
    private static func update(_ filter: Filter, strength: Int = 100, rotateAngle: Int = 0, mirrorX: Int = 0, mirrorY: Int = 0, forResource resource: Resource) -> Promise<PhotoFilterUtils.WrappedFilterResult> {
        return Promise<PhotoFilterUtils.WrappedFilterResult> { fulfill, reject in
            
            if !resource.valid() {
                reject(Error.invalidResource.error)
                return
            }
            
            cachedFilterResult(resource, filter: filter).then { image -> Void in
                if let cachedImage = image {
                    fulfill((resource, cachedImage))
                } else {
                    
                    let path = "/pics/" + resource.key! + "/effects"
                    
                    if let request = camera360Request(
                        byPath: path,
                        method: .post,
                        parameters: [
                            "x:filter": "\(filter)",
                            "x:strength": "\(strength)",
                            "x:rotateAngle": "\(rotateAngle)",
                            "x:mirrorX": "\(mirrorX)",
                            "x:mirrorY": "\(mirrorY)",
                        ]) {
                        
                        Alamofire.request(request).validate()
                            .responseJSON(completionHandler: { (response) in
                                switch response.result {
                                case .success(let value):
                                    if let result = Mapper<Result>().map(JSONObject: value) {
                                        if let url = result.url, let imageURL = URL(string: url) {
                                            KingfisherManager.shared.retrieveImage(with: imageURL, options: nil, progressBlock: nil, completionHandler: { (image, error, cacheType, imageURL) in
                                                if let image = image {
                                                    cache(url, forResource: resource, filter: filter)
                                                    fulfill((resource, image))
                                                } else {
                                                    reject(Error.failToDownloadImage.error)
                                                }
                                            })
                                        }
                                    } else {
                                        reject(Error.mappingError.error)
                                    }
                                case .failure(let error):
                                    reject(error)
                                }
                            })
                        
                    } else {
                        reject(Error.invalidRequst.error)
                    }
                }
            }
        }
    }
    
    static func apply(_ filter: Filter, forImage : UIImage? = nil, resource: Resource? = nil) -> Promise<PhotoFilterUtils.WrappedFilterResult> {
        return Promise<PhotoFilterUtils.WrappedFilterResult> { fulfill, reject in
            if let resource = resource { // reuse the resource
                update(filter, forResource: resource)
                    .then { result in
                        fulfill(result)
                    }
                    .catch { error in
                        reject(error)
                    }
            } else { // create new resource
                guard let image = forImage else {
                    reject(Error.missingImage.error)
                    return
                }
                uploadToken()
                    .then { (newResource) -> Promise<PhotoFilterUtils.WrappedFilterResult> in
                        return upload(image, forResource: newResource, withFilter: filter)
                    }
                    .then { result in
                        fulfill(result)
                    }
                    .catch { error in
                        reject(error)
                    }
            }
        }
    }
    
    private static var keyURLMap = [String: String]()
    
    private static func cacheKey(_ forResource: Resource, filter: Filter) -> String? {
        if let key = forResource.key {
            return key + "_" + filter.rawValue
        }
        return nil
    }
    
    private static func filteredURL(_ forResource: Resource, filter: Filter) -> String? {
        if let resultKey = cacheKey(forResource, filter: filter) {
            return keyURLMap[resultKey]
        }
        return nil
    }
    
    private static func cachedFilterResult(_ forResource: Resource, filter: Filter) -> Promise<UIImage?>  {
        return Promise<UIImage?> { fulfill, reject in
            if let stringURL = filteredURL(forResource, filter: filter), let url = URL(string: stringURL) {
                KingfisherManager.shared.retrieveImage(with: url, options: nil, progressBlock: nil, completionHandler: { (image, error, cacheType, imageURL) in
                    fulfill(image)
                })
            } else {
                fulfill(nil)
            }
        }
    }
    
    private static func cache(_ imageURL: String, forResource: Resource, filter: Filter) {
        if let resultKey = cacheKey(forResource, filter: filter) {
            keyURLMap[resultKey] = imageURL
        }
    }
    
    private enum Error {
        case mappingError
        case invalidResource
        case invalidRequst
        case missingImage
        case failToDownloadImage
        
        var error: NSError {
            switch self {
            case .mappingError:
                return NSError(domain: "Camera30", code: -1, userInfo: ["reason": "Map object fail"])
            case .invalidResource:
                return NSError(domain: "Camera30", code: -2, userInfo: ["reason": "Invalid resource"])
            case .invalidRequst:
                return NSError(domain: "Camera30", code: -2, userInfo: ["reason": "Invalid request"])
            case .missingImage:
                return NSError(domain: "Camera30", code: -2, userInfo: ["reason": "Invalid Image"])
            case .failToDownloadImage:
                return NSError(domain: "Camera30", code: -2, userInfo: ["reason": "Fail to donwload image"])
            }
        }
    }
    
    typealias FilterResult = (resource: Resource, result: Result)
    
    struct Resource: Mappable {
        
        fileprivate(set) var key: String?
        fileprivate(set) var uphost: String?
        fileprivate(set) var token: String?
        
        init?(map: Map) {
            
        }
        
        mutating func mapping(map: Map) {
            key <- map["key"]
            uphost <- map["uphost"]
            token <- map["token"]
        }
        
        func valid() -> Bool {
            return key != nil && uphost != nil && token != nil
        }
    }
    
    struct Result: Mappable {
        
        fileprivate(set) var url: String?
        
        init?(map: Map) {
            
        }
        
        mutating func mapping(map: Map) {
            url <- map["url"]
        }
        
        func valid() -> Bool {
            return url != nil
        }
    }
    
}
