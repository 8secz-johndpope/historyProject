//
//  EntityURLFactory.swift
//  merchant-ios
//
//  Created by Tony Fung on 8/3/2016.
//  Copyright © 2016年 WWE & CO. All rights reserved.
//

import Foundation
// FIXME: comparison operators with optionals were removed from the Swift Standard Libary.
// Consider refactoring the code to use the non-optional operators.
private func < <T : Comparable>(lhs: T?, rhs: T?) -> Bool {
  switch (lhs, rhs) {
  case let (l?, r?):
    return l < r
  case (nil, _?):
    return true
  default:
    return false
  }
}

// FIXME: comparison operators with optionals were removed from the Swift Standard Libary.
// Consider refactoring the code to use the non-optional operators.
private func > <T : Comparable>(lhs: T?, rhs: T?) -> Bool {
  switch (lhs, rhs) {
  case let (l?, r?):
    return l > r
  default:
    return rhs < lhs
  }
}


class EntityURLFactory {
    
    private static var prefixPath = Constants.Path.DeepLinkURL
    class func userURL(_ user : User) -> URL{
        let path = "\(prefixPath)u/\(user.userName)" + (Constants.MagicWindow.enable ? "?mw=1" : "")
        return URL(string: path)!
    }
    
    class func getUserNameFromURL(_ url: URL) -> String? {
        let userPrefixPath = prefixPath + "u/"
        let userPrefixPathHttp = "http://\(Constants.Path.DeepShareDomain)/u/"
        if url.pathComponents.count > URL(string: userPrefixPath)?.pathComponents.count && (url.absoluteString.contains(userPrefixPath) || url.absoluteString.contains(userPrefixPathHttp)) {
            return url.lastPathComponent
        }
        
        return nil
    }
    
    class func skuURL(_ sku : Sku) -> URL{
        return URL(string: "\(prefixPath)s/\(sku.skuId)")!
    }
   
    class func merchantURL(_ merchant : Merchant) -> URL{
        return URL(string: "\(prefixPath)m/\(merchant.merchantSubdomain)")!
    }
    
    class func brandURL(_ brand : Brand) -> URL{
        return URL(string: "\(prefixPath)b/\(brand.brandSubdomain)")!
    }

    class func contentPageURL(_ magazineCover : MagazineCover) -> URL{
        return URL(string: "\(prefixPath)p/\(magazineCover.contentPageKey)")!
    }
//    http://deepshare.io/deepshare-web-demo.html?appid=6df3ae2e6b3a0c308&inapp_data=%7B%22key1%22:%22value1%22%7D&sender_id=D14618BD-3F02-4A1E-BDBE-76824B9671C5
    
    class func postURL(_ post : Post) -> URL{
        return URL(string: "\(prefixPath)f/\(post.postId)")!
    }
	
	class func appendServerHostParam(_ params: String) -> String {
		
		let url = URL(string: Constants.Path.Host)
		
		var str = params
		
		//TODO: add production server check later
		
		Log.debug("Host : \(Constants.Path.Host)")
		
		str = params + "&h=https://" + (url?.host)!
		
		return str
	}

    class func deepShareInvitationURL(_ baseURL: String, referrerUserKey: String, params: String = "") -> URL? {
        let urlString = baseURL + "?referrerUserKey=" + referrerUserKey + params.replacingOccurrences(of: "?", with: "&")
		return URL(string: urlString)
    }
    
    class func deepShareProductURL(_ productId: String, params: String = "", referrer: String?) -> URL {
		var urlString : String = Constants.Path.DeepShareWebURL
		
        urlString = urlString + "s/" + productId
	

		let params = EntityURLFactory.appendServerHostParam(params)
		
        urlString += params
        
        if let referrerUserKey = referrer {
            urlString += "&UserKeyReferrer=" + referrerUserKey
        }
        
		let baseURL : URL = URL(string: urlString)!
        return baseURL
    }
    
    class func deepShareMerchantURL(_ mercharntSubdomain: String, params: String = "") -> URL {
		var urlString : String = Constants.Path.DeepShareWebURL
		
        urlString = urlString + "m/" + mercharntSubdomain
		
		
		let params = EntityURLFactory.appendServerHostParam(params)
		
        urlString += params
        let baseURL : URL = URL(string: urlString)!
        return baseURL
    }
    

    class func deepShareBrandURL(brandSubdomain: String, params: String = "") -> NSURL {
        var urlString : String = Constants.Path.DeepShareWebURL
        
        urlString = urlString + "b/" + brandSubdomain
       
        
        let params = EntityURLFactory.appendServerHostParam(params)
        
        urlString += params
        let baseURL : NSURL = NSURL(string: urlString)!
        return baseURL
    }
    
    class func deepSharePostURL(_ postId: String, params: String = "", referrer: String?) -> URL {
		var urlString : String = Constants.Path.DeepShareWebURL
	
        urlString = urlString + "f/" + postId
		
		let params = EntityURLFactory.appendServerHostParam(params)
		
        urlString += params
        
        if let referrerUserKey = referrer {
            urlString += "&UserKeyReferrer=" + referrerUserKey
        }
        
		let baseURL : URL = URL(string: urlString)!
        return baseURL
    }
    
    class func deepSharePageContentURL(_ pageId: String, params: String = "") -> URL {
		var urlString : String = Constants.Path.DeepShareWebURL
			urlString = urlString + "p/" + pageId
		
		let params = EntityURLFactory.appendServerHostParam(params)
		
        urlString += params
		let baseURL : URL = URL(string: urlString)!
        return baseURL
    }
    
    class func deepShareHashTagURL(_ hashTag: String, params: String = "", referrer: String?) -> URL? {
        var urlString : String = Constants.Path.DeepShareWebURL

        urlString = "\(urlString)dk/tag/\(hashTag)"
        
        let params = EntityURLFactory.appendServerHostParam(params)
        urlString = urlString + params
        
        if let referrerUserKey = referrer {
            urlString = "\(urlString)&UserKeyReferrer=\(referrerUserKey)"
        }
        
        
        
        if let escapedURLString = urlString.addingPercentEncoding(withAllowedCharacters: CharacterSet.urlQueryAllowed) {
            if let baseURL : URL = URL(string: escapedURLString) {
                return baseURL
            }
        }
        
        return nil
    }
    
    class func deepShareMasterCouponURL(type: MasterCouponType, referrer: String?) -> URL? {
        var urlString : String = Constants.Path.DeepShareWebURL
        
        urlString = "\(urlString)dk/coupon-masterclaim?entity="
        
        if type == .merchantCoupon {
            urlString = "\(urlString)merchant"
        } else {
            urlString = "\(urlString)mymm"
        }
        
        if let referrerUserKey = referrer {
            urlString = "\(urlString)&UserKeyReferrer=\(referrerUserKey)"
        }
        
        if let escapedURLString = urlString.addingPercentEncoding(withAllowedCharacters: CharacterSet.urlQueryAllowed) {
            if let baseURL : URL = URL(string: escapedURLString) {
                return baseURL
            }
        }
        
        return nil
    }
    
    class func deepShareUserURL(_ username: String, params: String = "") -> URL {
		var urlString : String = Constants.Path.DeepShareWebURL
        let name : String = username
        
        urlString = urlString + "u/" + name
		
		let params = EntityURLFactory.appendServerHostParam(params)
		
        urlString += params
		let baseURL : URL = URL(string: urlString)!
        return baseURL
    }

    
}
