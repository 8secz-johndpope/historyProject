//
//  URLRequestExtension.swift
//  storefront-ios
//
//  Created by Alan Team on 23/3/2018.
//  Copyright © 2018 WWE & CO. All rights reserved.
//

extension URLRequest {
    
    mutating func setMMAppPrivateInfo() {
        let heads = self.allHTTPHeaderFields ?? [:]
        
        //设置user agent
//        if #available(iOS 9.0, *) {} else {
            let ua = heads["User-Agent"]
            if ua == nil || ua!.range(of:"mymm/iOS") == nil {
                let userAgentDefault = UserDefaults.standard.string(forKey: "UserAgent")
                setValue(userAgentDefault, forHTTPHeaderField: "User-Agent")
            }
//        }
        
        //设置jwt
        let authorization = self.allHTTPHeaderFields?["Authorization"]
        let tk = Context.getToken()
        if !tk.isEmpty && (authorization == nil || authorization!.isEmpty) {
            setValue(tk, forHTTPHeaderField: "Authorization")
        }
        
        //设置用的cookie
        let domain = getMastHostDomain()
        if !domain.isEmpty {
            let cookieString = self.allHTTPHeaderFields?["Cookie"] ?? ""
            var cookie = ""
            //登录状态
            if LoginManager.isValidUser() {
                 let user = Context.getUserProfile()
                if cookieString.range(of: "MMUserKey=") == nil {
                    if !cookie.isEmpty {
                        cookie = cookie + "; "
                    }
                    cookie = cookie + "MMUserKey=" + Urls.encoded(str: user.userKey)
                }
                if cookieString.range(of: "MMUserName=") == nil {
                    if !cookie.isEmpty {
                        cookie = cookie + "; "
                    }
                    cookie = cookie + "MMUserName=" + Urls.encoded(str: user.userName)
                }
            }
            
            //埋点需要
            let sessionKey = AnalyticsManager.sharedManager.getSessionKey()
            if cookieString.range(of: "AnalyticsSessionKey=") == nil {
                if !cookie.isEmpty {
                    cookie = cookie + "; "
                }
                cookie = cookie + "AnalyticsSessionKey=" + Urls.encoded(str: sessionKey)
            }
            
            if let identifierForVendor = UIDevice.current.identifierForVendor {
                if !cookie.isEmpty {
                    cookie = cookie + "; "
                }
                cookie = cookie + "AnalyticsDeviceKey=" + Urls.encoded(str: identifierForVendor.uuidString)
            }
            
            
            setValue(cookie, forHTTPHeaderField: "Cookie")
        }
    }
    
    public static func getMMAppPrivateCookie() -> [String:String] {
        var cookie:[String:String] = [:]
        //登录状态
        if LoginManager.isValidUser() {
            let user = Context.getUserProfile()
            cookie["MMUserKey"] = Urls.encoded(str: user.userKey)
            cookie["MMUserName"] = Urls.encoded(str: user.userName)
            
            let tk = Context.getToken()
            if !tk.isEmpty {
                cookie["MMAccessToken"] = tk
            }
        }
        
        //埋点需要
        let sessionKey = AnalyticsManager.sharedManager.getSessionKey()
        cookie["AnalyticsSessionKey"] = Urls.encoded(str: sessionKey)
        if let identifierForVendor = UIDevice.current.identifierForVendor {
            cookie["AnalyticsDeviceKey"] = identifierForVendor.uuidString
        }
        
        
        return cookie
    }
    
    public static func getSetCookieJavascript() -> String {
        let kvs = getMMAppPrivateCookie()
        var str = ""
        for (key,value) in kvs {
            str = str + "document.cookie = '" + key + "=" + value + "';"
        }
        return str
    }
    
    func getMastHostDomain() -> String {
        guard let host = self.url?.host else {
            return ""
        }
        
        let ss = host.split(separator: ".")
        if ss.count <= 2 {
            return host
        }
        return "\(ss[ss.count - 2]).\(ss[ss.count - 1])"
    }
}
