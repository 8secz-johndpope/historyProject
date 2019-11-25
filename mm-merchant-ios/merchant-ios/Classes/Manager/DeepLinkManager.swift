//
//  DeepLinkManager.swift
//  merchant-ios
//
//  Created by Gam Bogo on 5/18/16.
//  Copyright © 2016 WWE & CO. All rights reserved.
//

import Foundation
import PromiseKit
import ObjectMapper
import Kingfisher
import Alamofire

// Deep Link Manager to manage shortcut open page
class DeepLinkManager {
    
    //还不能用open url打开的页面，后面逐个消化
    public static func recognizedType(type:String) -> Bool {
        let t = DeepLinkType.deeplinkType(type)
        if (t == DeepLinkType.Conversation
            //                || Type.SKU.getKey().equals(type) //已经兼容
            //                || Type.USER.getKey().equals(type)  //已经兼容
            || t == DeepLinkType.Merchant
            || t == DeepLinkType.Brand
            || t == DeepLinkType.PostDetail
            || t == DeepLinkType.Order
            || t == DeepLinkType.ProductList
            || t == DeepLinkType.OrderReturn
            || t == DeepLinkType.Magazine
            || t == DeepLinkType.InvitationCode
            //                || Type.CAMPAIGN_INVITATION.getKey().equals(type)
            || t == DeepLinkType.Campaign
            || t == DeepLinkType.FriendRequest
            || t == DeepLinkType.VipCard
            || t == DeepLinkType.NewbieCoupon
            || t == DeepLinkType.Referrer
            || t == DeepLinkType.Referee
            
            || t == DeepLinkType.RefereeNewbie
            || t == DeepLinkType.RefereeM
            || t == DeepLinkType.HashTag
            || t == DeepLinkType.SocialNotificationLike
            || t == DeepLinkType.SocialNotificationComment
            || t == DeepLinkType.SocialNotificationFollowers
            || t == DeepLinkType.Posting
            )
        {
            return true;
        }
        return false;
    }
    
    enum DeepLinkType: String {
        case Unknown        = "unknown"
        case Merchant       = "m"
        case Brand          = "b"
        case Product        = "sku"
        case UserCurator    = "u"
        case Magazine       = "p"
        case URL            = "url"
        case Conversation   = "c"
        case Order          = "o"
        case ProductList    = "l"
        case OrderReturn    = "r"
    
        case DeepLinkURL    = "d"
        case PostDetail     = "f"
        case InvitationCode = "campaign"
        
        case Campaign       = "cp"
        case FriendRequest  = "fr"
        case NewbieCoupon   = "nc"
        case Referrer       = "rr"
        case Referee        = "re"
        case RefereeNewbie  = "rn"
        case RefereeM       = "rm"
        case SocialNotificationLike = "dk/pl"
        case SocialNotificationComment = "dk/pc"
        case SocialNotificationFollowers = "dk/fl"
        case VipCard        = "vu"
        case PhoneSettings  = "dk/phone-settings"
        case CuratorList    = "dk/curator-list"
        case DiscoverBrand  = "dk/discover-brand"
        case DiscoverCategory = "dk/discover-category"
        case BrandList  = "dk/brand-list"
        case MerchantList = "dk/merchant-list"
        case HashTag = "dk/tag"
        case CouponMasterPage = "dk/coupon-masterclaim"
        case Posting = "dk/posting"
        @discardableResult
        static func deeplinkType(_ fromString: String) -> DeepLinkType{
            
            let skuAlternate = "s"
            let inviteAlternate = "i"
            let hashTagTopic = "tag"
            let masterCoupon = "coupon"
            
            if fromString == skuAlternate {
                return .Product
            } else if fromString == inviteAlternate {
                return .InvitationCode
            } else if fromString == hashTagTopic {
                return .HashTag
            } else if fromString == masterCoupon {
                return .CouponMasterPage
            } else if fromString == DeepLinkType.Campaign.rawValue {
                return DeepLinkType.Campaign
            }
            
            if let type = DeepLinkType(rawValue: fromString) {
                return type
            } else if fromString.contain("dk/") { //which means it is added in future versions
                return .Unknown
            } else {
                return .URL
            }
            
        }
        
    }
    
    enum ProductListFilter: String {
        case ProductListFilterColor = "color"
        case ProductListFilterSize = "size"
        case ProductListFilterKeyword = "keyword"
        case ProductListFilterS = "s" //same as keyword key
        case ProductListFilterCategory = "cat"
        case ProductListFilterBrand = "brand"
        case ProductListFilterMerchant = "merchant"
        case ProductListFilterPriceFrom = "pf"
        case ProductListFilterPriceTo = "pr"
        case ProductListFilterBadge = "badge"
        case ProductListFilterCrossborder = "iscrossborder"
        case ProductListFilterSale = "issale"
        case ProductListFilterZone = "zone"
        case ProductListFilterSort = "sort"
        case ProductListFilterOrder = "order"
    }
    
    enum OrderType: Int {
        case Order = 0
        case OrderCancel
        case OrderReturn
        case OrderDispute
    }
    
    //static let deeplinkPrefixURL = Constants.Path.DeepLinkURL + "p/"
    
    class var sharedManager: DeepLinkManager {
        get {
            struct Singleton {
                static let instance = DeepLinkManager()
            }
            return Singleton.instance
        }
    }
    
    let urlProtocols = ["https://", "http://", "mymm://"]
    let urlValids = ["mymm.com", "mymm.cn", "mm.eastasia.cloudapp.azure.com"] //valid url redirection is *.mymm.com, *.mymm.cn, *.mm.eastasia.cloudapp.azure.com
    let specialMarks = ["?"]
    
    //This to handle delegate for opening page if success or not
    var completionOpeningPage: ((Bool) -> Void)?
    
    
    //MARK: -
    
    func isValidUrlDeeplink(_ urlString: String) -> Bool {
        
        var urlValue = urlString.lowercased()
        
        for urlProtocol in urlProtocols {
            urlValue = urlValue.replacingOccurrences(of: urlProtocol, with: "")
        }
        
        let keyValues = urlValue.components(separatedBy: "/")
        if keyValues.count > 1 {
            for urlAllowed in urlValids {
                if keyValues[0].contains(urlAllowed) {
                    return true
                }
            }
        }
        
        return false
    }
    
    func getDeepLinkTypeValue(_ urlString: String) -> Dictionary<DeepLinkType, String>? {
        // Remove http and https prefix
        
        if !isValidUrlDeeplink(urlString) {
            //Default is URL
            return [.URL : urlString]
        }
        var urlValue = urlString
        
        for urlProtocol in urlProtocols {
            urlValue.replace(urlProtocol, with: "", options: NSString.CompareOptions.caseInsensitive)
        }
        for specialMark in specialMarks {
            urlValue = urlValue.replacingOccurrences(of: specialMark, with: "/")
        }
        
        let keyValues = urlValue.components(separatedBy: "/")
        if keyValues.count > 2 {
            
            var resultType: DeepLinkType = .Unknown
            //Skip 0: index 0 is the host url
            
            var key = keyValues[1]
            var valueType = keyValues[2]
            
            if key == "dk" {
                key = "dk/" + keyValues[2]
                valueType = keyValues.count > 3 ? keyValues[3] : ""
            }
            
            resultType = DeepLinkType.deeplinkType(key)
            if resultType == .URL {
                valueType = urlString
            } else if resultType == .InvitationCode {
                if keyValues.count > 3 {
                    valueType = keyValues[3].replacingOccurrences(of: "invite=", with: "")
                }
            }
            
            return [resultType: valueType]
        }else if keyValues.count == 2 {
            DeepLinkType.deeplinkType(keyValues[1])
//            if type == .InterestTags {
//                return [.InterestTags: ""]
//            }
        }
        
        //Default is URL
        return [.URL : urlString]
    }
    
    func decodeUrl(url: String) -> String {
        if let urlDecode = url.removingPercentEncoding {
            return urlDecode
        } else {
            return url
        }
    }
    
    //This function to check url need to parse to general type of deeplink or not
    func shouldResolveDeeplink(url: String) -> Bool {
        
        let queries = decodeUrl(url: url).components(separatedBy: "?")
        
        //for URI, the first index will be host name
        if queries.count > 1 {
            for indexQuery in 1 ..< queries.count {
                let currentQuery = queries[indexQuery]
                let params = currentQuery.components(separatedBy: "&")
                
                //find "type" in query url, if yes, the magic window should work
                let foundType = params.filter({$0.hasPrefix("type=")})
                if foundType.count > 0 {
                    return true
                }
            }
        }
        
        return false
    }
    
    func parseUrlToParams(url: String) -> (deepLinkDictionary : [DeepLinkType: String]?, queryDict: [String: String]?) {
        let queries = decodeUrl(url: url).components(separatedBy: "?")
        var queryDict : [String: String]? = nil
        var deeplinkDict: [DeepLinkType: String]? = nil
        
        //for URI, the first index will be host name
        if queries.count > 1 {
            for indexQuery in 1 ..< queries.count {
                let currentQuery = queries[indexQuery]
                let currentQueryDict = currentQuery.queryStringToDict()
                if let type = currentQueryDict["type"], let value = currentQueryDict["value"] {
                    var resultType: DeepLinkType = .Unknown
                    resultType = DeepLinkType.deeplinkType(type)
                    deeplinkDict = [resultType : value]
                } else {
                    queryDict = currentQueryDict
                }
            }
        }
        
        return (deepLinkDictionary: deeplinkDict, queryDict: queryDict)
    }
    
    private func onParamsResponse(_ params: [AnyHashable: Any]){
//        if let type = params["type"] as? String {
//            let value = (params["value"] as? String ?? "").replacingOccurrences(of: "&amp;", with: "&")
//            let array = value.components(separatedBy: "?")
//            var resultType: DeepLinkType = .Unknown
//            resultType = DeepLinkType.deeplinkType(type)
//            var deeplinkDict = [DeepLinkType: String]()
//            let queryDict = array.count > 1 ? array[1].queryStringToDict() : nil
//
//            for val in array {
//                if val.length > 0 {
//                    deeplinkDict = [resultType : val]
//                    break
//                }
//            }
        
//            self.showDeepLinkPage(deepLinkDictionary: deeplinkDict, queryDict: queryDict)
//            self.recordCampaign([resultType: value])
//        }
    }
    
    // MARK: via deepshare
    @objc func onInappDataReturned(params: [NSObject : Any]!, withError error: NSError!) {
        if(error == nil && params != nil){
            onParamsResponse(params)
            Log.debug(params)
        }
    }
    
    func magicWindowParametersResponse(url: URL, params : [AnyHashable : Any]?) {
        if let params = params {
            onParamsResponse(params)
        }
    }
    
    //MARK: Analytics
    func recordCampaign(_ deepLinkDictionary : Dictionary<DeepLinkType, String>? ) {
        if let deeplinkDict = deepLinkDictionary {
            if let deepLinkType: DeepLinkManager.DeepLinkType = (deeplinkDict.keys.first){
                if let value = deeplinkDict[deepLinkType]{
                    AnalyticsManager.sharedManager.recordCampaign(params: value)
                }
            }
        }
    }
    
    
    // MARK: incoming deeplink from outside, redirect cycle handling
    @objc func openPendingDeeplink(){
//        self.openDeepLink(pendingDeeplink as URL?)
    }
    
    @available(*, deprecated, message: "use Navigator open url, 5.4版本将完全丢弃")
    func openDeepLink(_ url: URL?) {
        
        NotificationCenter.default.removeObserver(self, name: NSNotification.Name(rawValue: "DEEP_LINK_PENDING"), object: nil)
        
        if !appRunningReady {
            NotificationCenter.default.addObserver(self, selector: #selector(DeepLinkManager.openPendingDeeplink), name: NSNotification.Name(rawValue: "DEEP_LINK_PENDING"), object: nil)
        }
        
        if LoginManager.isValidUser() {
            if appRunningReady {
                if let deepUrl = url,
                    let deeplinkDict = DeepLinkManager.sharedManager.getDeepLinkTypeValue(decodeUrl(url: deepUrl.absoluteString))
                {
                    DeepLinkManager.sharedManager.showDeepLinkPage(deepLinkDictionary: deeplinkDict, originUrl:deepUrl.absoluteString)
                    pendingDeeplink = nil
                }
            }
        } else {
            //Uncomment this line if we need to continue using deeplink after login / sign up
            //pendingDeeplink = url
            
            openLoginPage()
        }
        
    }
    
    func openLoginPage() {
        if LoginManager.hasStorefront() {
            LoginManager.goToLogin()
        }
    }
    
    var appRunningReady = false
    var pendingDeeplink : NSURL?
    var pendingDeepLinkDictionary: Dictionary<DeepLinkType, String>?
    var pendingQueryDict: Dictionary<String, String>?
    
    func setAppRunningReady(){
        appRunningReady = true
        NotificationCenter.default.post(name: NSNotification.Name(rawValue: "DEEP_LINK_PENDING"), object: nil)
    }
  
    // MARK: Show deep link page support for navigation controller
    @available(*, deprecated, message: "use Navigator open url, 5.4版本将完全丢弃")
    func showDeepLinkPage(viewController: UIViewController? = nil, deepLinkDictionary: Dictionary<DeepLinkType, String>?, originUrl:String = "", completion: @escaping (Bool) -> Void) {
        self.completionOpeningPage = completion
        showDeepLinkPage(viewController: viewController, deepLinkDictionary: deepLinkDictionary)
    }
    
    @discardableResult
    @available(*, deprecated, message: "use Navigator open url, 5.4版本将完全丢弃")
    //MARK:
    func showDeepLinkPage(viewController: UIViewController? = nil, deepLinkDictionary: Dictionary<DeepLinkType, String>?, queryDict:Dictionary<String, String>? = nil, originUrl:String = "") -> Bool {
        
        
        guard let deepLinkDictionaryStrong = deepLinkDictionary, let deepLinkType = deepLinkDictionaryStrong.keys.first else {
            self.completionOpeningPage?(true)
            self.completionOpeningPage = nil
            return false
        }
        
        
        let isStoreFrontDeeplink = ![DeepLinkType.InvitationCode].contains(deepLinkType) // actions inside storefront controller, all exclude invitation code
        let isMemberOnlyDeepLink = [.Conversation, .Order, .OrderReturn, .InvitationCode, .Campaign, .FriendRequest, .NewbieCoupon, .VipCard, .PhoneSettings].contains(deepLinkType)
        
        if LoginManager.getLoginState() != .validUser && isMemberOnlyDeepLink {
            
            openLoginPage()
            
            self.completionOpeningPage?(true)
            self.completionOpeningPage = nil
            return false
        }
        
        
        if !LoginManager.hasStorefront() && isStoreFrontDeeplink {
            LoginManager.goToStorefront()
        }
        
        if let value = deepLinkDictionaryStrong[deepLinkType]{
                switch deepLinkType {
                case .Product:
                    guard value.length > 0, let skuId = Int(value) else {
                        self.completionOpeningPage?(true)
                        self.completionOpeningPage = nil
                        break
                    }
                    
                    //MM-12434: Update for fixing issues can't back to the page
                    var referrerUserKey: String? = nil
                    if let dict = queryDict, let referrer = dict["UserKeyReferrer"] {
                        referrerUserKey = referrer
                    }
                    
                    if viewController != nil {
                        //Normal Case: user touch on banner
                        self.pushProduct(viewController: viewController!, skuId: skuId, referrer: referrerUserKey)
                        self.completionOpeningPage?(true)
                        self.completionOpeningPage = nil
                    } else if let currentTopViewController = ShareManager.sharedManager.getTopViewController() {
                        
                        var found = false
                        
                        if let activeController = Utils.findActiveController() as? StyleViewController {
                            if activeController.skuId == skuId {
                                activeController.referrerUserKey = referrerUserKey
                                found = true
                            }
                        }
                        if !found {
                            CATransaction.begin()
                            CATransaction.setCompletionBlock({
                                self.pushProduct(viewController: currentTopViewController, skuId: skuId, referrer: referrerUserKey)
                                self.completionOpeningPage?(true)
                                self.completionOpeningPage = nil
                            })
                            CATransaction.commit()
                        } else {
                            self.completionOpeningPage?(true)
                            self.completionOpeningPage = nil
                        }
                    }
                    
                    
                    
                case .Merchant:
                    
                    guard value.length > 0 else {
                        self.completionOpeningPage?(true)
                        self.completionOpeningPage = nil
                        break
                    }
                    
                    //MM-12434: Update for fixing issues can't back to the page
                    if viewController != nil {
                        self.pushMerchantBySubdomain(viewController: viewController!, merchantSubdomain: value)
                        self.completionOpeningPage?(true)
                        self.completionOpeningPage = nil
                    } else {
                        //Push Notification or Trigger some where
                        var found = false
                        if let activeController = Utils.findActiveController() as? MerchantViewController {
                            if activeController.merchantId == Int(value) {
                                found = true
                            }
                        }
                        
                        
                        if !found, let currentTopViewController = ShareManager.sharedManager.getTopViewController() {
                            
                            CATransaction.begin()
                            CATransaction.setCompletionBlock({
                                if let merchantId = Int(value) { //if value is Integer -> value = merchant Id
                                    self.pushMerchantById(merchantId, fromViewController: currentTopViewController)
                                } else { //if value is String -> value = merchant sub domain
                                    self.pushMerchantBySubdomain(viewController: currentTopViewController, merchantSubdomain: value)
                                }
                                self.completionOpeningPage?(true)
                                self.completionOpeningPage = nil
                            })
                            CATransaction.commit()
                            
                        } else {
                            self.completionOpeningPage?(true)
                            self.completionOpeningPage = nil
                        }
                    }
                    
                    
                case .Brand:
                    
                    guard value.length > 0 else {
                        self.completionOpeningPage?(true)
                        self.completionOpeningPage = nil
                        break
                    }
                    
                    //MM-12434: Update for fixing issues can't back to the page
                    if viewController != nil {
                        //Normal Case: user touch on banner
                        self.pushBrand(viewController: viewController!, brandSubDomain: value)
                        self.completionOpeningPage?(true)
                        self.completionOpeningPage = nil
                    } else {
                        //Push Notification or Trigger some where
                        if let currentTopViewController = ShareManager.sharedManager.getTopViewController() {
                            
                            CATransaction.begin()
                            CATransaction.setCompletionBlock({
                                self.pushBrand(viewController: currentTopViewController, brandSubDomain: value)
                                self.completionOpeningPage?(true)
                                self.completionOpeningPage = nil
                            })
                            CATransaction.commit()
                        } else {
                            self.completionOpeningPage?(true)
                            self.completionOpeningPage = nil
                        }
                    }
                    
                    
                case .Magazine:
                    
                    //MM-12434: Update for fixing issues can't back to the page
                    if viewController != nil {
                        //Normal Case: user touch on banner
                        let magazineContentViewController = MagazineContentViewController(pageKey: value)
                        self.getNavViewController(viewController!)?.pushViewController(magazineContentViewController, animated: true)
                        
                        //Delegate to current view controller showing
                        self.completionOpeningPage?(true)
                        //We are using singleton so must release the reference from current view controller
                        self.completionOpeningPage = nil
                        
                    } else {
                        //Push Notification or Trigger some where
                        if let currentTopViewController = ShareManager.sharedManager.getTopViewController() {
                            var found = false
                            if let activeController = Utils.findActiveController() as? MagazineContentViewController {
                                if activeController.contentPageKey == value {
                                    found = true
                                }
                            }
                            
                            if !found {
                                CATransaction.begin()
                                CATransaction.setCompletionBlock({
                                    let magazineContentViewController = MagazineContentViewController(pageKey: value)
                                    self.getNavViewController(currentTopViewController)?.pushViewController(magazineContentViewController, animated: true)
                                    //Delegate to current view controller showing
                                    self.completionOpeningPage?(true)
                                    //We are using singleton so must release the reference from current view controller
                                    self.completionOpeningPage = nil
                                })
                                CATransaction.commit()
                            } else {
                                self.completionOpeningPage?(true)
                                self.completionOpeningPage = nil
                            }
                            
                        } else {
                            self.completionOpeningPage?(true)
                            self.completionOpeningPage = nil
                        }
                    }
                    
                    
                    
                case .UserCurator:
                    
                    guard value.length > 0 else {
                        self.completionOpeningPage?(true)
                        self.completionOpeningPage = nil
                        break
                    }
                    
                    //MM-12434: Update for fixing issues can't back to the page
                    if viewController != nil {
                        //Normal Case: user touch on banner
                        self.pushPublicProfile(viewController: viewController!, userName: value)
                        self.completionOpeningPage?(true)
                        self.completionOpeningPage = nil
                    } else {
                        //Push Notification or Trigger some where
                        
                        if let currentTopViewController = ShareManager.sharedManager.getTopViewController() , let navigationBar = getNavViewController(currentTopViewController) , navigationBar.viewControllers.count > 0 {

                            var found = false
                            if let activeController = Utils.findActiveController() as? ProfileViewController {
                                if activeController.user.userName == value {
                                    found = true
                                }
                            }
                            if !found {
                                CATransaction.begin()
                                CATransaction.setCompletionBlock({
                                    self.pushPublicProfile(viewController: currentTopViewController, userName: value)
                                    self.completionOpeningPage?(true)
                                    self.completionOpeningPage = nil
                                })
                                CATransaction.commit()
                            } else {
                                self.completionOpeningPage?(true)
                                self.completionOpeningPage = nil
                            }
                            
                        } else {
                            self.completionOpeningPage?(true)
                            self.completionOpeningPage = nil
                        }
                    }
                    
                case .URL:
                    
                    Navigator.shared.dopen(originUrl)
                    self.completionOpeningPage?(true)
                    self.completionOpeningPage = nil
                    
                    //MM-12434: Update for fixing issues can't back to the page
//                    if viewController != nil {
//                        //Normal Case: user touch on banner
//                        PostManager.isSkipLoadingNewFeedInHome = true
//                        Navigator.shared.dopen(value)
////                        let webViewController = WebViewController()
////                        webViewController.url = URL(string: value)
////                        webViewController.isTabBarHidden = true
////                        self.getNavViewController(viewController!)?.pushViewController(webViewController, animated: true)
//                        //Delegate to current view controller showing
//                        self.completionOpeningPage?(true)
//                        //We are using singleton so must release the reference from current view controller
//                        self.completionOpeningPage = nil
//                    } else
//                    {
//                        //Push Notification or Trigger some where
//                        if let _ = ShareManager.sharedManager.getTopViewController() {
//                            CATransaction.begin()
//                            CATransaction.setCompletionBlock({
//                                Navigator.shared.dopen(value)
////                                let webViewController = WebViewController()
////                                webViewController.url = URL(string: value)
////                                webViewController.isTabBarHidden = true
////                                self.getNavViewController(currentTopViewController)?.pushViewController(webViewController, animated: true)
//                                //Delegate to current view controller showing
//                                self.completionOpeningPage?(true)
//                                //We are using singleton so must release the reference from current view controller
//                                self.completionOpeningPage = nil
//                            })
//                            CATransaction.commit()
//                        } else {
//                            self.completionOpeningPage?(true)
//                            self.completionOpeningPage = nil
//                        }
//                    }
                    
                case .ProductList:
                    Navigator.shared.dopen(originUrl)
                    self.completionOpeningPage?(true)
                    self.completionOpeningPage = nil
                    /*
                    guard value.length > 0 else {
                        self.completionOpeningPage?(true)
                        self.completionOpeningPage = nil
                        break
                    }
                    
                    //MM-12434: Update for fixing issues can't back to the page
                    if viewController != nil {
                        //Normal Case: user touch on banner
                        self.pushProductList(viewController: viewController!, filterString: value)
                        self.completionOpeningPage?(true)
                        self.completionOpeningPage = nil
                    } else {
                        //Push Notification or Trigger some where
                        if let currentTopViewController = ShareManager.sharedManager.getTopViewController() {
                            
                            CATransaction.begin()
                            
                            CATransaction.setCompletionBlock({
                                self.pushProductList(viewController: currentTopViewController, filterString: value)
                                self.completionOpeningPage?(true)
                                self.completionOpeningPage = nil
                            })
                            CATransaction.commit()
                        } else {
                            self.completionOpeningPage?(true)
                            self.completionOpeningPage = nil
                        }
                    }
                    */
                    
                case .Conversation, .NewbieCoupon:
                    
                    guard LoginManager.isLoggedInErrorPrompt() && value.length > 0 , let currentTopViewController = ShareManager.sharedManager.getTopViewController() else {
                        self.completionOpeningPage?(true)
                        self.completionOpeningPage = nil
                        break
                    }
                    CATransaction.begin()
                    CATransaction.setCompletionBlock({
                        self.pushConversation(viewController: currentTopViewController, conversationKey: value)
                        self.completionOpeningPage?(true)
                        self.completionOpeningPage = nil
                    })
                    CATransaction.commit()
                    
                case .SocialNotificationLike, .SocialNotificationComment, .SocialNotificationFollowers:
                    
                    guard LoginManager.isLoggedInErrorPrompt() && value.length > 0 , let currentTopViewController = ShareManager.sharedManager.getTopViewController() else {
                        self.completionOpeningPage?(true)
                        self.completionOpeningPage = nil
                        break
                    }
                    CATransaction.begin()
                    CATransaction.setCompletionBlock({
                        var type = SocialMessageType.postLiked
                        switch deepLinkType {
                        case .SocialNotificationComment:
                            type = .postComment
                        case .SocialNotificationFollowers:
                            type = .follow
                        default:
                            type = .postLiked
                        }
                        self.pushSocialNotification(viewController: currentTopViewController, type: type)
                        self.completionOpeningPage?(true)
                        self.completionOpeningPage = nil
                    })
                    CATransaction.commit()
                    
                case .FriendRequest:
                    
                    guard LoginManager.isLoggedInErrorPrompt() && value.length > 0, let currentTopViewController = ShareManager.sharedManager.getTopViewController()  else {
                        self.completionOpeningPage?(true)
                        self.completionOpeningPage = nil
                        break
                    }
                    
                    CATransaction.begin()
                    
                    CATransaction.setCompletionBlock({
                        self.pushFriendRequest(viewController: currentTopViewController)
                        
                        self.completionOpeningPage?(true)
                        self.completionOpeningPage = nil
                    })
                    CATransaction.commit()
                    
                    
                case .Order:
                    
                    guard LoginManager.isLoggedInErrorPrompt() && value.length > 0, let currentTopViewController = ShareManager.sharedManager.getTopViewController() else {
                        self.completionOpeningPage?(true)
                        self.completionOpeningPage = nil
                        break
                    }
                    CATransaction.begin()
                    CATransaction.setCompletionBlock({
                        self.pushOrderPage(viewController: currentTopViewController, orderKey: value)
                        //Delegate to current view controller showing
                        self.completionOpeningPage?(true)
                        //We are using singleton so must release the reference from current view controller
                        self.completionOpeningPage = nil
                    })
                    CATransaction.commit()
                    
                case .OrderReturn:
                    
                    guard LoginManager.isLoggedInErrorPrompt() && value.length > 0, let currentTopViewController = ShareManager.sharedManager.getTopViewController() else {
                        self.completionOpeningPage?(true)
                        self.completionOpeningPage = nil
                        break
                    }
                    CATransaction.begin()
                    CATransaction.setCompletionBlock({
                        self.pushOrderReturnPage(viewController: currentTopViewController, orderReturnKey: value)
                        //Delegate to current view controller showing
                        self.completionOpeningPage?(true)
                        //We are using singleton so must release the reference from current view controller
                        self.completionOpeningPage = nil
                    })
                    CATransaction.commit()
                    
                case .InvitationCode:
                    
                    guard LoginManager.getLoginState() != .validUser else {
                        self.completionOpeningPage?(true)
                        self.completionOpeningPage = nil
                        break
                    }
                    
                    LoginManager.goToLogin()
                    if let exclusiveVC = ExclusiveViewController.loadedInstance {
                        exclusiveVC.preloadedInvitationCode = value
                    }
                    
                case .PostDetail:
                    
                    guard value.length > 0 , let postId = Int(value)  else {
                        self.completionOpeningPage?(true)
                        self.completionOpeningPage = nil
                        break
                    }
                    
                    
                    //MM-12434: Update for fixing issues can't back to the page
                    var referrerUserKey: String? = nil
                    if let dict = queryDict, let referrer = dict["UserKeyReferrer"] {
                        referrerUserKey = referrer
                    }
                    
                    if viewController != nil {
                        //Normal Case: user touch on banner
                        self.pushPostDetail(viewController: viewController!, postId: postId, referrer: referrerUserKey)
                        //Delegate to current view controller showing
                        self.completionOpeningPage?(true)
                        //We are using singleton so must release the reference from current view controller
                        self.completionOpeningPage = nil
                    } else {
                        //Push Notification or Trigger some where
                        
                        guard let currentTopViewController = ShareManager.sharedManager.getTopViewController(), let navigationBar = getNavViewController(currentTopViewController), navigationBar.viewControllers.count > 0  else {
                            self.completionOpeningPage?(true)
                            self.completionOpeningPage = nil
                            break
                        }
                        
                        var found = false
                        if let activeController = Utils.findActiveController() as? PostDetailViewController {
                            if activeController.postId == postId {
                                activeController.referrerUserKey = referrerUserKey
                                found = true
                            }
                        }
                        if !found {
                            CATransaction.begin()
                            CATransaction.setCompletionBlock({
                                self.pushPostDetail(viewController: currentTopViewController, postId: postId, referrer: referrerUserKey)
                                //Delegate to current view controller showing
                                self.completionOpeningPage?(true)
                                //We are using singleton so must release the reference from current view controller
                                self.completionOpeningPage = nil
                            })
                            CATransaction.commit()
                        } else {
                            self.completionOpeningPage?(true)
                            self.completionOpeningPage = nil
                        }
                        
                        
                    }
                    
                case .HashTag:
                    
                    guard value.length > 0 else {
                        self.completionOpeningPage?(true)
                        self.completionOpeningPage = nil
                        break
                    }
                    
                    let hashTagValue = value.removingPercentEncoding ?? ""
                    
                    //MM-12434: Update for fixing issues can't back to the page
                    if viewController != nil {
                        //Normal Case: user touch on banner
                        self.pushHashTagViewController(viewController: viewController!, hashTag: hashTagValue)
                    } else {
                        //Push Notification or Trigger some where
                        if let currentTopViewController = ShareManager.sharedManager.getTopViewController() , let navigationBar = getNavViewController(currentTopViewController) , navigationBar.viewControllers.count > 0 {
                            
                            CATransaction.begin()
                            CATransaction.setCompletionBlock({
                                self.pushHashTagViewController(viewController: currentTopViewController, hashTag: hashTagValue)
                            })
                            CATransaction.commit()
                            
                        } else {
                            self.completionOpeningPage?(true)
                            self.completionOpeningPage = nil
                        }
                    }
                case .Campaign:
                    if let parentViewController = viewController ?? ShareManager.sharedManager.getTopViewController() {
                        self.presentCampaginViewController(value, parentViewController: parentViewController)
                    }
                    self.completionOpeningPage?(true)
                    self.completionOpeningPage = nil
                case .VipCard:
                    if let viewController = viewController {
                        self.pushVipCard(viewController)
                        self.completionOpeningPage?(true)
                        self.completionOpeningPage = nil
                    } else if let currentTopViewController = ShareManager.sharedManager.getTopViewController() {
                        CATransaction.begin()
                        CATransaction.setCompletionBlock({
                            self.pushVipCard(currentTopViewController)
                            self.completionOpeningPage?(true)
                            self.completionOpeningPage = nil
                        })
                        CATransaction.commit()
                    }
                case .PhoneSettings:
                    let settingsUrl = URL(string: UIApplicationOpenSettingsURLString)
                    if let url = settingsUrl {
                        UIApplication.shared.openURL(url)
                    } else {
                        
                    }
                
                case .CuratorList:
                    pushCuratorList()
                    self.completionOpeningPage?(true)
                    self.completionOpeningPage = nil
                    break
                
                case .DiscoverBrand:
                    pushDiscoverBrand()
                    self.completionOpeningPage?(true)
                    self.completionOpeningPage = nil
                    break
                    
                case .DiscoverCategory:
                    pushDiscoverCategory()
                    self.completionOpeningPage?(true)
                    self.completionOpeningPage = nil
                    break
                    
                case .MerchantList:
                    pushMerchantList()
                    self.completionOpeningPage?(true)
                    self.completionOpeningPage = nil
                    break
                case .BrandList:
                    Navigator.shared.dopen(Navigator.mymm.website_brandlist)
//                    pushBrandList()
                    self.completionOpeningPage?(true)
                    self.completionOpeningPage = nil
                    break
                case .CouponMasterPage:
                    Navigator.shared.dopen(originUrl)
//                    pushCouponMasterPage(value, queryDict: queryDict)
                    self.completionOpeningPage?(true)
                    self.completionOpeningPage = nil
                case .Posting:
                    if LoginManager.getLoginState() == .validUser {
                        pushPosting()
                    }
                    self.completionOpeningPage?(true)
                    self.completionOpeningPage = nil
                case .Unknown,
                     .DeepLinkURL:
                    self.completionOpeningPage?(true)
                    self.completionOpeningPage = nil
                default:
                    Navigator.shared.dopen(originUrl)
                    break
            }
            
            return true
           
        } else {
            self.completionOpeningPage?(true)
            self.completionOpeningPage = nil
        }
        
        return false
    }
    
    
    
    //MARK:
    // MARK: Navigate View Controller
    func getNavViewController(_ viewController: UIViewController) -> UINavigationController? {
        if let navController = viewController as? UINavigationController {
            return navController
        } else {
            return viewController.navigationController
        }
    }
    
    // MARK:
    // MARK: Show campagin page
    func presentCampaginViewController(_ campaginName: String, parentViewController: UIViewController) {
        
        if campaginName == "incentivereferral" {
            let profilePopupViewController = ProfilePopupViewController()
            profilePopupViewController.presentViewController = parentViewController
            let nvm = MmNavigationController(rootViewController: profilePopupViewController)
            parentViewController.present(nvm, animated: false, completion: {
                self.completionOpeningPage?(true)
                self.completionOpeningPage = nil
            })
        }
        
    }
    
    //MARK:
    // MARK: push Product by sku id
    func pushProduct(viewController: UIViewController, skuId: Int, referrer: String?) {
        let loadingViewController = viewController as? LoadingViewController
        loadingViewController?.showLoading()
        
        SearchService.searchStyleBySkuId(skuId) { (response) in
            loadingViewController?.stopLoading()
            
            var showPageSuccess = false
            if response.result.isSuccess {
                if response.response?.statusCode == 200 {
                    if let styleResponse = Mapper<SearchResponse>().map(JSONObject: response.result.value) {
                        if let pageData = styleResponse.pageData {
                            var styleViewController = StyleViewController()
                            
                            if pageData.count > 0 {
                                if let style = pageData.first {
                                    styleViewController = StyleViewController(style: style, entryPoint: StyleViewController.EntryPoint.DeepLink)
                                }
                            }
                            else{
                                styleViewController = StyleViewController(isProductActive: false)
                            }
                            
                            styleViewController.skuId = skuId
                            styleViewController.referrerUserKey = referrer
                            
                            self.getNavViewController(viewController)?.pushViewController(styleViewController, animated: true)
                            
                            showPageSuccess = true
                        }
                    }
                }
            }
            
            // Delegate to current view controller showing
            self.completionOpeningPage?(showPageSuccess)
            
            // We are using singleton so must release the reference from current view controller
            self.completionOpeningPage = nil
        }
    }
    
    //MARK:
    //MARK: Push Merchant by subdomain
    func pushMerchantBySubdomain(viewController: UIViewController, merchantSubdomain: String) {
        let loadingViewController = viewController as? LoadingViewController
        loadingViewController?.showLoading()
        
        MerchantService.viewMerchantSubdomain(merchantSubdomain) { (response) in
            loadingViewController?.stopLoading()
            
            var showPageSuccess = false
            if response.result.isSuccess && response.response?.statusCode == 200{
                
                if let merchants: Array<Merchant> = Mapper<Merchant>().mapArray(JSONObject: response.result.value) {
                    if let merchant = merchants.first {
                        Navigator.shared.dopen(Navigator.mymm.website_merchant_merchantId + "\(merchant.merchantId)")
                    }
                    showPageSuccess = true
                }
                
            } else {
                if let baseController = viewController as? MmViewController {
                    baseController.handleError(response, animated: true)
                }
            }
            
            //Delegate to current view controller showing
            self.completionOpeningPage?(showPageSuccess)
            //We are using singleton so must release the reference from current view controller
            self.completionOpeningPage = nil
        }
    }
    
    //MARK:
    //MARK: Push Merchant by id

    func pushMerchantById(_ merchantId: Int, fromViewController viewController: UIViewController) {
        let loadingViewController = viewController as? LoadingViewController
        loadingViewController?.showLoading()
        
        MerchantService.view(merchantId) { (response) in
            loadingViewController?.stopLoading()
            
            var showPageSuccess = false
            if response.result.isSuccess {
                if response.response?.statusCode == 200 {
                    
                    if let array = response.result.value as? [[String: Any]], let obj = array.first , let merchant = Mapper<Merchant>().map(JSONObject: obj) {
                        
                        Navigator.shared.dopen(Navigator.mymm.website_merchant_merchantId + "\(merchant.merchantId)")
                        showPageSuccess = true
                        
                    }
                    
                }
            }
            
            //Delegate to current view controller showing
            self.completionOpeningPage?(showPageSuccess)
            //We are using singleton so must release the reference from current view controller
            self.completionOpeningPage = nil
        }
    }
    
    //MARK: Push To Brand Detail
    func pushBrand(viewController: UIViewController, brandSubDomain: String) {
        let brand = Brand()
        if let brandId = Int(brandSubDomain){
            brand.brandId = brandId
        }
        else{
            brand.brandSubdomain = brandSubDomain
        }
        let brandViewController = BrandViewController()
        brandViewController.brand = brand
        getNavViewController(viewController)?.pushViewController(brandViewController, animated: true)
        //Delegate to current view controller showing
        self.completionOpeningPage?(true)
        //We are using singleton so must release the reference from current view controller
        self.completionOpeningPage = nil
    }
    
    //MARK:
    //MARK: Push To Profile Detail

    private func pushPublicProfile(viewController: UIViewController, user: User) {

        if let navigationController = getNavViewController(viewController) {
            var controllers = navigationController.viewControllers
            if controllers.count > 1 /* make sure has 2 controllers (profile tab is special case) */ && type(of: controllers[controllers.count - 1]) == ProfileViewController.self {
                navigationController.popViewController(animated:false)
            }

            PushManager.sharedInstance.goToProfile(user, hideTabBar: true)
        }
        //Delegate to current view controller showing
        self.completionOpeningPage?(true)
        //We are using singleton so must release the reference from current view controller
        self.completionOpeningPage = nil
        
    }
    
    func pushPublicProfile(viewController: UIViewController, userName: String) {
        let user = User()
        user.userName = userName
        self.pushPublicProfile(viewController: viewController, user: user)
    }
    
    func pushPublicProfile(viewController: UIViewController, userKey: String) {
        let user = User()
        user.userKey = userKey
        self.pushPublicProfile(viewController: viewController, user: user)
    }
    
    //MARK:
    //MARK: Push To Hash Tag Post
    func pushHashTagViewController(viewController: UIViewController, hashTag: String) {
        let str = hashTag.replacingOccurrences(of: "#", with: "")
        Navigator.shared.dopen(Navigator.mymm.deeplink_dk_tag_tagName + Urls.encoded(str: str))
        
        //Delegate to current view controller showing
        self.completionOpeningPage?(true)
        //We are using singleton so must release the reference from current view controller
        self.completionOpeningPage = nil
    }
    
    //MARK:
    //MARK: Push To Conversation
    func pushConversation(viewController: UIViewController, conversationKey: String){
        
        let pushConv = WebSocketManager.sharedInstance().conversationForKey(conversationKey)
        
        var chatViewController: TSChatViewController
        
        if let _ = pushConv, (pushConv?.isMyClient() == true || pushConv?.isInternalChat() == true || pushConv?.IAmMM() == true) {
            chatViewController = AgentChatViewController(convKey: conversationKey)
        } else {
            chatViewController = UserChatViewController(convKey: conversationKey)
        }
        chatViewController.hidesBottomBarWhenPushed = true
        if let navigationBar = getNavViewController(viewController) {
            
            var isOnSameConv = false
            
            if let lastChildViewController = navigationBar.viewControllers.get(0) {
                if lastChildViewController.isKind(of: TSChatViewController.self) {
                    if let lastChildViewController = lastChildViewController as? TSChatViewController, let conv = lastChildViewController.conv {
                        if conv.convKey == conversationKey {
                            isOnSameConv = true
                        }
                    }
                }
            }
            
            if !isOnSameConv {
                if navigationBar.childViewControllers.count > 1 {
                    if let firstViewController = navigationBar.viewControllers.first {
                        navigationBar.popToViewController(firstViewController, animated: false)
                    }
                }
                navigationBar.pushViewController(chatViewController, animated: true)
            }
        }
        
        //Delegate to current view controller showing
        self.completionOpeningPage?(true)
        //We are using singleton so must release the reference from current view controller
        self.completionOpeningPage = nil
    }
    
    func pushSocialNotification(viewController: UIViewController, type: SocialMessageType) {
        if let navigationBar = getNavViewController(viewController) {
            let snViewController = SocialNotificationViewController()
            snViewController.socialMessageType = type
            if navigationBar.childViewControllers.count > 1 {
                if let firstViewController = navigationBar.viewControllers.first {
                    navigationBar.popToViewController(firstViewController, animated: false)
                }
            }
            // fetch unread count API if stay on IM landing.
            // update listing if on listing page
            navigationBar.pushViewController(snViewController, animated: true)
        }
    }
    
    func pushFriendRequest(viewController: UIViewController) {
        let contactListViewController = ContactListViewController()
        contactListViewController.isAgent = Context.isUserAgent()
        contactListViewController.navigateToTabIndex = 1
        
        if let navigationBar = getNavViewController(viewController) {
            if navigationBar.childViewControllers.count > 1 {
                if let firstViewController = navigationBar.viewControllers.first {
                    navigationBar.popToViewController(firstViewController, animated: false)
                }
            }
            navigationBar.pushViewController(contactListViewController, animated: true)
        }
    }
    
    //MARK:
    //MARK: Push To Order Detail Page
    func pushOrderPage(viewController: UIViewController, orderKey: String) {
        viewOrderDetail(viewController: viewController, orderKey: orderKey)
    }
    
    //MARK: Push Order Return
    func pushOrderReturnPage(viewController: UIViewController, orderReturnKey: String) {
        OrderService.viewOrderReturn(orderReturnKey: orderReturnKey, completion: { (response) in
            if response.result.isSuccess {
                if response.response?.statusCode == 200 {
                    if let orderReturn = Mapper<OrderReturn>().map(JSONObject: response.result.value) {
                        if let order = orderReturn.order {
                            self.viewOrderDetail(viewController: viewController, orderKey: order.orderKey, orderType: .OrderReturn, key: orderReturnKey)
                        }
                    }
                }
            }
        })
    }
    
    //MARK:
    func pushOrderDetail(viewController: UIViewController, order: Order) -> Bool {
        var showPageSuccess = false
        if let orderItems = order.orderItems{
            let data = OrderSectionData(sectionHeader: [], reuseIdentifier: OrderItemCell.CellIdentifier, dataSource: orderItems)
            data.order = order
            
            if let orderShipments = order.orderShipments{
                if orderShipments.count > 0{
                    data.orderShipment = orderShipments[0]
                }
            }
            if let order = data.order{
                let orderStatusData = OrderStatusData(order: order, orderDisplayStatus: data.orderDisplayStatus)
                data.insert(dataItem: orderStatusData, at: 0) //insert to data source at index 0
                
                let orderPriceData = OrderPriceData(order: order)
                data.append(dataItem: orderPriceData)  //append to data source
                
                let orderActionData = OrderActionData(order: order, orderDisplayStatus: data.orderDisplayStatus)
                data.append(dataItem: orderActionData) //append to data source
                
                let orderDetailViewController = OrderDetailViewController()
                orderDetailViewController.orderSectionData = data
                orderDetailViewController.originalViewMode = .all
                
                if viewController.isKind(of: MmNavigationController.self) {
                    if let navigationBar = viewController as? MmNavigationController {
                        navigationBar.pushViewController(orderDetailViewController, animated: true)
                        showPageSuccess = true
                    }
                } else {
                    viewController.navigationController?.pushViewController(orderDetailViewController, animated: true)
                    showPageSuccess = true
                }
            }
        }
        return showPageSuccess
    }
    
    //MARK: Handle Order Response
    func viewOrderDetail(viewController: UIViewController, orderKey: String, orderType: OrderType = .Order, key: String? = nil) {
        OrderService.viewOrder(orderKey) { (response) in
            var showPageSuccess = false
            if response.result.isSuccess {
                if response.response?.statusCode == 200 {
                    if let order = Mapper<Order>().map(JSONObject: response.result.value) {
                        switch orderType {
                        case .Order:
                            showPageSuccess = self.pushOrderDetail(viewController: viewController, order: order)
                        case .OrderReturn:
                            let orders = OrderManager.splitOrder(order)
                            
                            for order in orders {
                                if let orderReturns = order.orderReturns {
                                    if let orderReturn = orderReturns.first {
                                        if let strongKey = key{
                                            if orderReturn.orderReturnKey == strongKey {
                                                showPageSuccess = self.pushOrderDetail(viewController: viewController, order: order)
                                                break
                                            }
                                        }
                                    }
                                }
                            }
                        default:
                            break
                        }
                    }
                }
            }
            //Delegate to current view controller showing
            self.completionOpeningPage?(showPageSuccess)
            //We are using singleton so must release the reference from current view controller
            self.completionOpeningPage = nil
        }
    }
    
    //MARK:
    //MARK: Product List
    func pushProductList(viewController: UIViewController, filterString: String){
        
        let keyValues = filterString.components(separatedBy: "&")
        
        if filterString.contain("sku=") {
            var skuIds = ""
            var sort = ""
            var sortOrder = ""
            for value in keyValues {
                if value.contain("sku=") {
                    skuIds = value.replacingOccurrences(of: "sku=", with: "")
                }
                
                if value.contain("sort=") {
                    sort = value.replacingOccurrences(of: "sort=", with: "")
                }
                
                if value.contain("order=") {
                    sortOrder = value.replacingOccurrences(of: "order=", with: "")
                }
            }
            
            let productListViewController = ProductListViewController()
            productListViewController.setSearchSkuIds(skuIds)
            if sort != "" && sortOrder != "" {
                let styleFilter = StyleFilter()
                styleFilter.sort = sort
                styleFilter.order = sortOrder
                productListViewController.setStyleFilter(styleFilter, isNeedSnapshot: false)
            }
//            productListViewController.isDeepLink = true
            self.getNavViewController(viewController)?.pushViewController(productListViewController, animated: true)
            
        } else {
            let styleFilter = StyleFilter()
            for keyValue in keyValues {
                let keyAndValue:[String] = keyValue.components(separatedBy: "=")
                if keyAndValue.count > 1{//had key and value also
                    let strongValue:String = keyAndValue[1]
                    //if value empty/while space -> check another key
                    if strongValue.trim().length == 0{
                        continue
                    }
                    if let strongKey:DeepLinkManager.ProductListFilter = DeepLinkManager.ProductListFilter(rawValue: keyAndValue[0]){
                        switch strongKey {
                        case .ProductListFilterColor:
                            let colorStrings = strongValue.components(separatedBy: ",")
                            //create color array
                            var colors = [Color]()
                            //add color to array
                            for colorId in colorStrings {
                                if let strongColorId = Int(colorId){
                                    let colorModel = Color()
                                    colorModel.colorId = strongColorId
                                    colors.append(colorModel)
                                }
                            }
                            styleFilter.colors = colors
                        case .ProductListFilterSize:
                            let sizeStrings = strongValue.components(separatedBy: ",")
                            //create size array
                            var sizes = [Size]()
                            //add size to array
                            for sizeId in sizeStrings {
                                if let strongSizeId = Int(sizeId){
                                    let sizeModel = Size()
                                    sizeModel.sizeId = strongSizeId
                                    sizes.append(sizeModel)
                                }
                            }
                            styleFilter.sizes = sizes
                        case .ProductListFilterKeyword, .ProductListFilterS:
                            styleFilter.queryString = strongValue
                        case .ProductListFilterCategory:
                            let catStrings = strongValue.components(separatedBy: ",")
                            //create cat array
                            var ids = [Int]()
                            //add cat to array
                            var cats = [Cat]()
                            
                            for catId in catStrings {
                                if let strongCatId = Int(catId){
                                    ids.append(strongCatId)
                                    let cat = Cat()
                                    cat.categoryId = strongCatId
                                    cats.append(cat)
                                }
                            }
                            
                            styleFilter.cats = cats
                            styleFilter.rootCategories = cats
                            
                            
                        case .ProductListFilterBrand:
                            let brandStrings = strongValue.components(separatedBy: ",")
                            //create brand array
                            var brands = [Brand]()
                            
                            //add brand to array
                            for brandId in brandStrings {
                                if let strongBrandId = Int(brandId){
                                    let brandModel = Brand()
                                    brandModel.brandId = strongBrandId
                                    brands.append(brandModel)
                                }
                            }
                            styleFilter.brands = brands
                            
                        case .ProductListFilterMerchant:
                            let merchantIds = strongValue.components(separatedBy: ",")
                            //create brand array
                            var merchants = [Merchant]()
                            
                            //add brand to array
                            for merchantId in merchantIds {
                                if let mId = Int(merchantId){
                                    let merchant = Merchant()
                                    merchant.merchantId = mId
                                    merchants.append(merchant)
                                }
                            }
                            styleFilter.merchants = merchants
                            styleFilter.sort = "DisplayRanking"
                            styleFilter.order = "desc"
                            
                        case .ProductListFilterPriceFrom:
                            if let priceFromInt = Int(strongValue){
                                styleFilter.priceFrom = priceFromInt
                            }
                            
                        case .ProductListFilterPriceTo:
                            if let priceToInt = Int(strongValue){
                                styleFilter.priceTo = priceToInt
                            }
                        case .ProductListFilterBadge:
                            let badgeStrings = strongValue.components(separatedBy: ",")
                            //create badge array
                            var badges = [Badge]()
                            //add brand to array
                            for badgeId in badgeStrings {
                                if let strongBadgeId = Int(badgeId){
                                    let badgeModel = Badge()
                                    badgeModel.badgeId = strongBadgeId
                                    badges.append(badgeModel)
                                }
                            }
                            styleFilter.badges = badges
                        case .ProductListFilterCrossborder:
                            if let isCrossBorder = Int(strongValue){
                                styleFilter.isCrossBorder = isCrossBorder
                            }
                        case .ProductListFilterSale:
                            if let isSale = Int(strongValue){
                                styleFilter.isSale = isSale
                            }
                        case .ProductListFilterZone:
                            if !styleFilter.zone.isEmpty{
                                styleFilter.zone = ""
                            }
                            else{
                                styleFilter.zone = strongValue
                            }
                        case .ProductListFilterSort:
                            styleFilter.sort = strongValue
                        case .ProductListFilterOrder:
                            styleFilter.order = strongValue
                        }
                    }
                }
            }
            launchStyleFilter(viewController: viewController, styleFilter: styleFilter)
            
        }
    }
    
    func launchStyleFilter(viewController: UIViewController, styleFilter: StyleFilter){
        let productListViewController = ProductListViewController()
//        productListViewController.isDeepLink = true
        productListViewController.selectedFilterCategories = styleFilter.cats
        productListViewController.originalFilterCategories = styleFilter.cats
        productListViewController.cats = styleFilter.cats
        productListViewController.setStyleFilter(styleFilter, isNeedSnapshot: true)
        self.getNavViewController(viewController)?.pushViewController(productListViewController, animated: true)
    }
    
    //MARK: Push To Post Detail
    func pushPostDetail(viewController: UIViewController, postId: Int, referrer: String?) {
        let postDetailViewController = PostDetailViewController(postId: postId)
        postDetailViewController.referrerUserKey = referrer
        getNavViewController(viewController)?.pushViewController(postDetailViewController, animated: true)
        //Delegate to current view controller showing
        self.completionOpeningPage?(true)
        //We are using singleton so must release the reference from current view controller
        self.completionOpeningPage = nil
    }
    
    //MARK:
    //MARK: post to interest tags page
    func presentInterestSelectionPage(fromViewController: UIViewController){
        getNavViewController(fromViewController)?.pushViewController(InterestCategoryPickViewController(), animated: true)
    }
    
    //MARK: Push Vip Card Page
    func pushVipCard(_ fromViewController: UIViewController){
        guard LoginManager.getLoginState() == .validUser else {
            return
        }
        
        firstly {
            return UserService.fetchUser(true)
            }.then { _ -> Void in
                Context.setVisitedVipCard(true)
                
                let user = Context.getUserProfile()
                
                LoyaltyManager.handleListLoyaltyStatus(success: { [weak self] (loyalties) in
                    if let strongSelf = self{
                        let filterLoyalties = loyalties.filter{$0.loyaltyStatusId == user.loyaltyStatusId}
                        if let loyalty = filterLoyalties.first {
                            user.loyalty = loyalty
                            
                            if let viewController = fromViewController as? MemberCardViewController{
                                viewController.initDataSource(user)
                                viewController.reloadData()
                                return
                            }
                            
                            if let profileViewController = fromViewController as? ProfileViewController{
                                profileViewController.user = user
                                profileViewController.reloadData()
                            }
                            
                            let memberCardViewController = MemberCardViewController()
                            memberCardViewController.initDataSource(user)

                            strongSelf.getNavViewController(fromViewController)?.pushViewController(memberCardViewController, animated: true)
                        }
                    }
                    }, failure: { (errorType) in
                        
                })
            }.catch { _ -> Void in
                Log.error("error")
        }
    }
    
    
    /* Deprecated as Discover page is no longer here */
    
    func pushDiscoverBrand() {
        let viewController = DiscoverBrandController()
        Utils.findActiveNavigationController()?.pushViewController(viewController, animated: true)
    }

    
    
    func pushDiscoverCategory() {
//        if let topViewController = ShareManager.sharedManager.getTopViewController() {
//            let viewController = NewCategoryViewController()
//            viewController.hidesBottomBarWhenPushed = true
//            self.getNavViewController(topViewController)?.pushViewController(viewController, animated: true)
//        }
    }
    
    func pushCuratorList() {
//        let tabController = StorefrontController.currentInstance
//        tabController?.showTabIndex(TabIndex.mm.rawValue)
//        tabController?.stylefeedController.navigationController?.popToRootViewController(animated: false)
//        tabController?.stylefeedController.pushToCuratorList()
        let viewController = FilterCuratorsViewController()
        if let naviController = Utils.findActiveNavigationController() {
            naviController.pushViewController(viewController, animated: true)
        }
    }
    
    func pushMerchantList() {
        if let topViewController = ShareManager.sharedManager.getTopViewController() {
            let merchantGridViewController = MerchantGridViewController()
            self.getNavViewController(topViewController)?.pushViewController(merchantGridViewController, animated: true)
        }
    }
    
    func pushBrandList() {
        if let topViewController = ShareManager.sharedManager.getTopViewController() {
            let brandContainerController = BrandContainerController()
            self.getNavViewController(topViewController)?.pushViewController(brandContainerController, animated: true)
        }
    }
    
    func pushPosting() {
        if let topViewController = ShareManager.sharedManager.getTopViewController() {
            let photoCollageViewController = CreatePostSelectImageViewController()
            let navController = UINavigationController()
            navController.viewControllers = [photoCollageViewController]
            topViewController.present(navController, animated: true, completion: nil)
        }
    }
}
