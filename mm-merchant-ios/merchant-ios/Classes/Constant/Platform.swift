//
//  Platform.swift
//  merchant-ios
//
//  Created by Alan YU on 27/10/2016.
//  Copyright © 2016 WWE & CO. All rights reserved.
//

import Foundation

#if MM_PLATFORM_PROD
    
    class Platform {
        
        static let Domain           = "api.mymm.com"
        static let Host             = "https://" + Domain + "/api/v1b"
        
        static let CDNDomain        = "cdn.mymm.com"
        static let WebSocketHost    = "wss://msg.mymm.com:443"
        static let AnalyticsDomain  = "t.mymm.com"
        static let DeveloperMode    = false
        static let TrustAnyCert     = false
        static let IgnoreSSLDomains = [String]()
        
        struct JPush {
            static let AppKey = "e731845bdaf23b69912ae8e7"
        }
        
        struct DeepShare {
            static let AppId = "6df3ae2e6b3a0c30"
        }
        
        struct MagicWindow {
            static let AppId = "UYKG55DHCECIJRKOW4EYMHAWZLIB9OTH"
            static let MLinkKey = "XJuq2sKJknF9meky"
        }
        
        static let wechatAppID = "wx5f856e676f618a69"
        
        struct TalkingData {
            static let AdTrackingID = "E4B14165F9644DBE99DA62779612C80D"
        }
        
        struct GrowingIO {
            static let GrowingIOID = "8b328e27b8c45463"
        }
        
        static let TutuAppKey = "49d33ada1b075010-03-8yvdr1"
        
    }
    
#elseif MM_PLATFORM_DEV
    
    class Platform {
        
        static let Domain           = "dev.mymm.com"
        static let Host             = "https://" + Domain + "/api"
        
        static let CDNDomain        = "cdn.mymm.cn"
        static let WebSocketHost    = "wss://msg.mymm.cn:443"
        static let AnalyticsDomain  = "t.mymm.cn"
        static let DeveloperMode    = false
        static let TrustAnyCert     = false
        static let IgnoreSSLDomains = [String]()
        
        struct JPush {
            static let AppKey = "e731845bdaf23b69912ae8e7"
        }
        
        struct DeepShare {
            static let AppId = "6df3ae2e6b3a0c30"
        }
        
        struct MagicWindow {
            static let AppId = "UYKG55DHCECIJRKOW4EYMHAWZLIB9OTH"
            static let MLinkKey = "XJuq2sKJknF9meky"
        }
        
        static let wechatAppID = "wx5f856e676f618a69"
        
        struct TalkingData {
            static let AdTrackingID = "B8E1BA813AA149EAACDD88D94CD3E60D"
        }
        
        struct GrowingIO {
            static let GrowingIOID = "8b328e27b8c45463"
        }
        
        static let TutuAppKey = "49d33ada1b075010-03-8yvdr1"
        
    }
    
#elseif MM_PLATFORM_HK_PROD

    class Platform {
        
        static let Domain           = "hk.mymm.com"
        static let Host             = "https://" + Domain + "/api/v1b"
        static let CDNDomain        = Domain
        static let CDN              = "https://cdn-hk.mymm.com/api"
        static let WebSocketHost    = "wss://msg.mymm.com:443"
        static let AnalyticsDomain  = "t.mymm.cn"
        static let DeveloperMode    = false
        static let TrustAnyCert     = false
        static let IgnoreSSLDomains = [String]()
        
        struct JPush {
            static let AppKey = "e731845bdaf23b69912ae8e7"
        }
        
        struct DeepShare {
            static let AppId = "6df3ae2e6b3a0c30"
        }
        
        struct MagicWindow {
            static let AppId = "UYKG55DHCECIJRKOW4EYMHAWZLIB9OTH"
            static let MLinkKey = "XJuq2sKJknF9meky"
        }
        
        static let wechatAppID = "wx5f856e676f618a69"
        
        struct TalkingData {
            static let AdTrackingID = "E4B14165F9644DBE99DA62779612C80D"
        }
        
        struct GrowingIO {
            static let GrowingIOID = "8b328e27b8c45463"
        }
        
        static let TutuAppKey = "49d33ada1b075010-03-8yvdr1"
        
    }
    
#elseif MM_PLATFORM_MOBILE
    
    class Platform {
        
        static let Domain           = "mm-dev-mob.chinaeast.cloudapp.chinacloudapi.cn"
        static let Host             = "https://" + Domain + "/api"
        
        static let CDNDomain        = Domain
        
        static let WebSocketHost    = "wss://mm-dev-mob.chinaeast.cloudapp.chinacloudapi.cn:7600"
        static let AnalyticsDomain  = "mm-dev-mob.chinaeast.cloudapp.chinacloudapi.cn"
        static let DeveloperMode    = true
        static let TrustAnyCert     = true
        static let IgnoreSSLDomains = [
            "mm-dev-mob.chinaeast.cloudapp.chinacloudapi.cn",
            "mm-dev-test.chinaeast.cloudapp.chinacloudapi.cn",
            "uat-mm.eastasia.cloudapp.azure.com",
            "auto-mm.eastasia.cloudapp.azure.com",
            "platform-mm.eastasia.cloudapp.azure.com"
        ]
        
        struct JPush {
            static let AppKey = "e731845bdaf23b69912ae8e7"
        }
        
        struct DeepShare {
            static let AppId = "6df3ae2e6b3a0c30"
        }
        
        struct MagicWindow {
            static let AppId = "UYKG55DHCECIJRKOW4EYMHAWZLIB9OTH"
            static let MLinkKey = "XJuq2sKJknF9meky"
        }
        
        static let wechatAppID = "wx5f856e676f618a69"
        
        struct TalkingData {
            static let AdTrackingID = "B8E1BA813AA149EAACDD88D94CD3E60D"
        }
        
        struct GrowingIO {
            static let GrowingIOID = "8b328e27b8c45463"
        }
        
        static let TutuAppKey = "49d33ada1b075010-03-8yvdr1"
        
    }
    
#elseif MM_PLATFORM_NEW_MOBILE
    
    class Platform {
        
        static let Domain           = "mm-dev-mob.chinaeast.cloudapp.chinacloudapi.cn"
        static let Host             = "https://" + Domain + "/api"
        
        static let CDNDomain        = Domain
        
        static let WebSocketHost    = "wss://mm-dev-mob.chinaeast.cloudapp.chinacloudapi.cn:7600"
        static let AnalyticsDomain  = "mm-dev-mob.chinaeast.cloudapp.chinacloudapi.cn"
        static let DeveloperMode    = true
        static let TrustAnyCert     = true
        static let IgnoreSSLDomains = [
            "mm-dev-mob.chinaeast.cloudapp.chinacloudapi.cn",
            "mobile-mm.eastasia.cloudapp.azure.com",
            "test-mm.eastasia.cloudapp.azure.com",
            "uat-mm.eastasia.cloudapp.azure.com",
            "auto-mm.eastasia.cloudapp.azure.com",
            "platform-mm.eastasia.cloudapp.azure.com"
        ]
        
        struct JPush {
            static let AppKey = "e731845bdaf23b69912ae8e7"
        }
        
        struct DeepShare {
            static let AppId = "6df3ae2e6b3a0c30"
        }
        
        struct MagicWindow {
            static let AppId = "UYKG55DHCECIJRKOW4EYMHAWZLIB9OTH"
            static let MLinkKey = "XJuq2sKJknF9meky"
        }
        
        static let wechatAppID = "wx5f856e676f618a69"
        
        struct TalkingData {
            static let AdTrackingID = "B8E1BA813AA149EAACDD88D94CD3E60D"
        }
        
        struct GrowingIO {
            static let GrowingIOID = "8b328e27b8c45463"
        }
        
        static let TutuAppKey = "49d33ada1b075010-03-8yvdr1"
        
    }
    
#elseif MM_PLATFORM_MINT
    
    class Platform {
        
        static let Domain           = "mint.mymm.com"
        static let Host             = "https://" + Domain + "/api"
        static let CDNDomain        = Domain
        static let WebSocketHost    = "wss://mint.mymm.com:7600"
        static let AnalyticsDomain  = "platform-mm.eastasia.cloudapp.azure.com"
        static let DeveloperMode    = true
        static let TrustAnyCert     = false
        static let IgnoreSSLDomains = [String]()
        
        struct JPush {
            static let AppKey = "f2dddb1165e97a71fb584cc1"
        }
        
        struct DeepShare {
            static let AppId = "fb7101bfdcc2c4d7"
        }
        
        struct MagicWindow {
            static let AppId = "H3K0TMWX3WAYGL7X4CL9OXPH5CBCGUD8"
            static let MLinkKey = "mm_enterprise_link1"
        }
        
        static let wechatAppID = "wxc41ccce54390e870"
        
        struct TalkingData {
            static let AdTrackingID = "B8E1BA813AA149EAACDD88D94CD3E60D"
        }
        
        struct GrowingIO {
            static let GrowingIOID = "8b328e27b8c45463"
        }
        
        static let TutuAppKey = "5539bfa89537a845-03-8yvdr1"
        
    }
    
#elseif MM_PLATFORM_UAT_WS
    
    class Platform {
        
        static let Domain           = "uat-ws.mymm.cn"
        static let Host             = "https://" + Domain + "/api"
        static let CDNDomain        = Domain
        static let WebSocketHost    = "wss://uat-pc.mymm.cn:7600"
        static let AnalyticsDomain  = "uat-tr.mymm.cn"
        static let DeveloperMode    = true
        static let TrustAnyCert     = false
        static let IgnoreSSLDomains = [String]()
        
        struct JPush {
            static let AppKey = "f2dddb1165e97a71fb584cc1"
        }
        
        struct DeepShare {
            static let AppId = "fb7101bfdcc2c4d7"
        }
        
        struct MagicWindow {
            static let AppId = "H3K0TMWX3WAYGL7X4CL9OXPH5CBCGUD8"
            static let MLinkKey = "mm_enterprise_link1"
        }
        
        static let wechatAppID = "wxc41ccce54390e870"
        
        struct TalkingData {
            static let AdTrackingID = "B8E1BA813AA149EAACDD88D94CD3E60D"
        }
        
        struct GrowingIO {
            static let GrowingIOID = "8b328e27b8c45463"
        }
        
        static let TutuAppKey = "5539bfa89537a845-03-8yvdr1"
        
    }
    
#elseif MM_PLATFORM_DEMO
    
    class Platform {
        
        static let Domain           = "demo.mymm.com"
        static let Host             = "https://" + Domain + "/api"
        static let CDNDomain        = Domain
        static let WebSocketHost    = "wss://demo.mymm.com:7600"
        static let AnalyticsDomain  = "platform-mm.eastasia.cloudapp.azure.com"
        static let DeveloperMode    = true
        static let TrustAnyCert     = false
        static let IgnoreSSLDomains = [String]()
        
        struct JPush {
            static let AppKey = "f2dddb1165e97a71fb584cc1"
        }
        
        struct DeepShare {
            static let AppId = "fb7101bfdcc2c4d7"
        }
        
        struct MagicWindow {
            static let AppId = "H3K0TMWX3WAYGL7X4CL9OXPH5CBCGUD8"
            static let MLinkKey = "mm_enterprise_link1"
        }
        
        static let wechatAppID = "wxc41ccce54390e870"
        
        struct TalkingData {
            static let AdTrackingID = "B8E1BA813AA149EAACDD88D94CD3E60D"
        }
        
        struct GrowingIO {
            static let GrowingIOID = "8b328e27b8c45463"
        }
        
        static let TutuAppKey = "5539bfa89537a845-03-8yvdr1"
        
    }

#elseif MM_PLATFORM_TEST
    
    class Platform {
        
        static let Domain           = "mm-dev-test.chinaeast.cloudapp.chinacloudapi.cn"
        static let Host             = "https://" + Domain + "/api"
        static let CDNDomain        = Domain
        static let WebSocketHost    = "wss://mm-dev-test.chinaeast.cloudapp.chinacloudapi.cn:7600"
        static let AnalyticsDomain  = "mm-dev-test.chinaeast.cloudapp.chinacloudapi.cn"
        static let DeveloperMode    = true
        static let TrustAnyCert     = true
        static let IgnoreSSLDomains = [
            "mm-dev-mob.chinaeast.cloudapp.chinacloudapi.cn",
            "mm-dev-test.chinaeast.cloudapp.chinacloudapi.cn",
            "uat-mm.eastasia.cloudapp.azure.com",
            "auto-mm.eastasia.cloudapp.azure.com",
            "platform-mm.eastasia.cloudapp.azure.com"
        ]
        
        struct JPush {
            static let AppKey = "e731845bdaf23b69912ae8e7"
        }
        
        struct DeepShare {
            static let AppId = "6df3ae2e6b3a0c30"
        }
        
        struct MagicWindow {
            static let AppId = "UYKG55DHCECIJRKOW4EYMHAWZLIB9OTH"
            static let MLinkKey = "XJuq2sKJknF9meky"
        }
        
        static let wechatAppID = "wx5f856e676f618a69"
        
        struct TalkingData {
            static let AdTrackingID = "B8E1BA813AA149EAACDD88D94CD3E60D"
        }
        
        struct GrowingIO {
            static let GrowingIOID = "8b328e27b8c45463"
        }
        
        static let TutuAppKey = "49d33ada1b075010-03-8yvdr1"
        
    }

#elseif MM_PLATFORM_NEXT
    
    class Platform {
        
        static let Domain           = "next.mymm.com"
        static let Host             = "https://" + Domain + "/api"
        static let CDNDomain        = Domain
        static let WebSocketHost    = "wss://next.mymm.com:7600"
        static let AnalyticsDomain  = "ts-tr.mymm.com" // "uat-lt.mymm.com"
        static let DeveloperMode    = true
        static let TrustAnyCert     = false
        static let IgnoreSSLDomains = [String]()
        
        struct JPush {
            static let AppKey = "f2dddb1165e97a71fb584cc1"
        }
        
        struct DeepShare {
            static let AppId = "fb7101bfdcc2c4d7"
        }
        
        struct MagicWindow {
            static let AppId = "H3K0TMWX3WAYGL7X4CL9OXPH5CBCGUD8"
            static let MLinkKey = "mm_enterprise_link1"
        }
        
        static let wechatAppID = "wxc41ccce54390e870"
        
        struct TalkingData {
            static let AdTrackingID = "B8E1BA813AA149EAACDD88D94CD3E60D"
        }
        
        struct GrowingIO {
            static let GrowingIOID = "8b328e27b8c45463"
        }
        
        static let TutuAppKey = "5539bfa89537a845-03-8yvdr1"
        
    }

#elseif MM_PLATFORM_LOAD
    
    class Platform {
        
        static let Domain           = "load.mymm.com"
        static let Host             = "https://" + Domain + "/api"
        static let CDNDomain        = Domain
        static let WebSocketHost    = "wss://load.mymm.com:7600"
        static let AnalyticsDomain  = "infini-mm.eastasia.cloudapp.azure.com"
        static let DeveloperMode    = true
        static let TrustAnyCert     = false
        static let IgnoreSSLDomains = [String]()
        
        struct JPush {
            static let AppKey = "f2dddb1165e97a71fb584cc1"
        }
        
        struct DeepShare {
            static let AppId = "fb7101bfdcc2c4d7"
        }
        
        struct MagicWindow {
            static let AppId = "H3K0TMWX3WAYGL7X4CL9OXPH5CBCGUD8"
            static let MLinkKey = "mm_enterprise_link1"
        }
        
        static let wechatAppID = "wxc41ccce54390e870"
        
        struct TalkingData {
            static let AdTrackingID = "B8E1BA813AA149EAACDD88D94CD3E60D"
        }
        
        struct GrowingIO {
            static let GrowingIOID = "8b328e27b8c45463"
        }
        
        static let TutuAppKey = "5539bfa89537a845-03-8yvdr1"
        
    }
#elseif MM_PLATFORM_VERIFY
    
    class Platform {
        
        static let Domain           = "verify.mymm.com"
        static let Host             = "https://" + Domain + "/api"
        static let CDNDomain        = Domain
        static let WebSocketHost    = "wss://verify.mymm.com:7600"
        static let AnalyticsDomain  = ""
        static let DeveloperMode    = false
        static let TrustAnyCert     = false
        static let IgnoreSSLDomains = [String]()
        
        struct JPush {
            static let AppKey = "f2dddb1165e97a71fb584cc1"
        }
        
        struct DeepShare {
            static let AppId = "fb7101bfdcc2c4d7"
        }
        
        struct MagicWindow {
            static let AppId = "H3K0TMWX3WAYGL7X4CL9OXPH5CBCGUD8"
            static let MLinkKey = "mm_enterprise_link1"
        }
        
        static let wechatAppID = "wxc41ccce54390e870"
        
        struct TalkingData {
            static let AdTrackingID = "B8E1BA813AA149EAACDD88D94CD3E60D"
        }
        
        struct GrowingIO {
            static let GrowingIOID = "8b328e27b8c45463"
        }
        
        static let TutuAppKey = "5539bfa89537a845-03-8yvdr1"
        
    }
    
#elseif MM_PLATFORM_TWG
    
    class Platform {
        
        static let Domain           = "twg.mymm.com"
        static let Host             = "https://" + Domain + "/api"
        static let CDNDomain        = Domain
        static let WebSocketHost    = "wss://twg.mymm.com:7600"
        static let AnalyticsDomain  = "twg.mymm.com"
        static let DeveloperMode    = true
        static let TrustAnyCert     = false
        static let IgnoreSSLDomains = [String]()
        
        struct JPush {
            static let AppKey = "f2dddb1165e97a71fb584cc1"
        }
        
        struct DeepShare {
            static let AppId = "fb7101bfdcc2c4d7"
        }
        
        struct MagicWindow {
            static let AppId = "H3K0TMWX3WAYGL7X4CL9OXPH5CBCGUD8"
            static let MLinkKey = "mm_enterprise_link1"
        }
        
        static let wechatAppID = "wxc41ccce54390e870"
        
        struct TalkingData {
            static let AdTrackingID = "B8E1BA813AA149EAACDD88D94CD3E60D"
        }
        
        struct GrowingIO {
            static let GrowingIOID = "8b328e27b8c45463"
        }
        
        static let TutuAppKey = "5539bfa89537a845-03-8yvdr1"
        
    }
    
#endif
