//
//  ImageURLFactory.swift
//  merchant-ios
//
//  Created by Koon Kit Chan on 2/12/2015.
//  Copyright © 2015 Koon Kit Chan. All rights reserved.
//

import Foundation

enum ImageCategory: String {
    case unknown = ""
    case product = "productimages"
    case brand = "brandimages"
    case merchant = "merchantimages"
    case color = "colorimages"
    case user = "userimages"
    case category = "categoryimages"
    case post = "postimages"
    case orderReturnImage = "orderreturnimages"
    case orderDisputeImage = "orderdisputeimages"
    case courier = "courierimages"
    case banner = "bannerimages"
    case contentPageImages = "contentpageimages"
    case contentPageCollectionImages = "contentpagecollectionimages"
    case review = "reviewimages"
    case badge = "badgeimages"
}

enum ResizerSize: Int {
    case size128    = 128
    case size256    = 256
    case size512    = 512
    case size750    = 750
    case size1000   = 1000
}

class ImageBucket {
    var imageCategory: ImageCategory = .unknown
    var imageKey = ""
    
    init(imageKey: String, category: ImageCategory) {
        self.imageKey = imageKey
        self.imageCategory = category
    }
}

class ImageURLFactory {
    
    class func URLSize(_ size: ResizerSize, key : String, category: ImageCategory = .product) -> URL {
        return resizerImageURL(key, category: category, width: size.rawValue)
    }
    
    class func URLSize128(_ key : String, category: ImageCategory = .product) -> URL {
        return resizerImageURL(key, category: category, width: ResizerSize.size128.rawValue)
    }
    
    class func URLSize256(_ key : String, category: ImageCategory = .product) -> URL {
        return resizerImageURL(key, category: category, width: ResizerSize.size256.rawValue)
    }
    
    class func URLSize512(_ key : String, category: ImageCategory = .product) -> URL {
        return resizerImageURL(key, category: category, width: ResizerSize.size512.rawValue)
    }
    
    class func URLSize750(_ key : String, category: ImageCategory = .product) -> URL {
        return resizerImageURL(key, category: category, width: ResizerSize.size750.rawValue)
    }
    
    class func URLSize1000(_ key : String, category: ImageCategory = .product) -> URL {
        return resizerImageURL(key, category: category, width: ResizerSize.size1000.rawValue)
    }
    
    class func URLSizeOther(_ key : String, category: ImageCategory = .product,width:Int,isOriginalW: Bool = false) -> URL {
        return resizerImageURL(key, category: category, width: width,isOriginalW:isOriginalW)
    }
    
    private class func resizerImageURL(_ key : String, category: ImageCategory = .product, width: Int = Constants.MaxImageWidth, isOriginalW: Bool = false) -> URL {
        if ImageURLFactory.isURLLink(key) {
            if let url =  URL(string: key) {
                return url
            }
        } else {
            let limitedWidth = min(width, Constants.MaxImageWidth)
            var originalW = "w"
            if isOriginalW {
                originalW = "s"
            }
            if let url =  URL(string: Constants.Path.CDN + "/resizer/view?key=" + key + "&\(originalW)=\(limitedWidth)&b=" + category.rawValue) {
                return url
            }
        }
        return URL(string: "")!
    }
    
    @available(*, deprecated, message : "renamed to URLSize`X`")
    class func get(_ key : String, category: ImageCategory = .product, width: Int = Constants.MaxImageWidth) -> URL {
        return resizerImageURL(key, category: category, width: width)
    }
    
    @available(*, deprecated, message : "renamed to URLSize`X`")
    class func get(_ key: String, size:CGSize, category: ImageCategory = .merchant) -> URL {
        return URL(string: Constants.Path.CDN + "/resizer/view?key=" + key + "&w=\(size.width * 5)&h=\(size.height * 2)&b=" + category.rawValue)!
    }
    
    @available(*, deprecated, message : "renamed to URLSize`X`")
    class func getRaw(_ key : String, category: ImageCategory = .product) -> URL {
        return URL(string: Constants.Path.CDN + "/resizer/view?key=" + key + "&s=0&b=" + category.rawValue)!
    }
    
    class func getRaw(_ key : String, category: ImageCategory = .product, width: Int) -> URL {
        let limitedWidth = min(width, Constants.MaxImageWidth)
        return URL(string: Constants.Path.CDN + "/resizer/view?key=" + key + "&w=\(limitedWidth)&b=" + category.rawValue + "&s=0")!
    }
    
    //Get Badge Image for Product List and Product Detail
    class func get(_ badgeImageKey: String, isForProductList: Bool) -> URL {
        
        var imageName = ""
        if isForProductList {
            //Product List
            imageName = "\(badgeImageKey).png"
        } else {
            //Product Detail
            imageName = "\(badgeImageKey)_w_text.png"
        }
        
        return URL(string:"https://" + Platform.CDNDomain + "/assets/badges/\(imageName)")!
    }
    
    private class func isURLLink(_ imageKey: String) -> Bool {
        
        if imageKey.length <= 0 {
            return false
        }
        
        let lowerCase = imageKey.lowercased()
        
        if lowerCase.hasPrefix("http://") || lowerCase.hasPrefix("https://") {
            return true
        }
        
        return false
    }
}
