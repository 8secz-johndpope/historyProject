//
//  Context.swift
//  merchant-ios
//
//  Created by Koon Kit Chan on 24/9/15.
//  Copyright © 2015 Koon Kit Chan. All rights reserved.
//

import Foundation
import ObjectMapper
import UIKit

enum ColorZone : Int {
    case redZone = 0
    case blackZone = 1
}

@objc class Context: NSObject {
    static let ShoppingCartKey = "ShoppingCartKey"
    static let WishlistKey = "WishlistKey"
    static let LastAppUpgradeAlertPromptTime = "LastAppUpgradeAlertPromptTime"
	static let LastPostingTime = "LastPostingTime"
	static let modelToken = "ModelToken"
	static let userProfile = "UserProfile"
    
    static let IAmMMAgentKey = "IAmMMAgent"
    static let ReferralCouponKey = "ReferralCouponKey"
    
    class func getHTTPHeader(_ appVersion: String) -> [String : String] {
        var header: [String : String] = [String : String]()
        header["Platform"] = "iOS"
        header["AppVersion"] = appVersion
        header["x-access-token"] = getToken()
        return header
    }
    
    class func setToken(_ tokenString : String) -> Void {
        let preferences = UserDefaults.standard
        preferences.set(tokenString,forKey: "token")
        preferences.synchronize()
    }
    
    class func getToken()->String{
        if let token = UserDefaults.standard.string(forKey: "token") {
            return token
        } else {
            return ""
        }
    }
    
    class func clearInvitationCode() -> Void {
        UserDefaults.standard.removeObject(forKey: "invitationCode")
    }
    
    class func setInvitationCode(_ invitationCode : String) -> Void {
        let preferences = UserDefaults.standard
        preferences.set(invitationCode,forKey: "invitationCode")
        preferences.synchronize()
    }
    
    class func getInvitationCode()->String{
        if let invitationCode = UserDefaults.standard.string(forKey: "invitationCode") {
            return invitationCode
        } else {
            return "" //MM-24359 Remove Constants.DefaultInvitationCode
        }
    }
    
    class func getUserId() -> Int {
        if (UserDefaults.standard.object(forKey: "userId") == nil){
            return 0
        }
        return UserDefaults.standard.object(forKey: "userId") as! Int
    }
    
    class func setUserId(_ userId : Int) -> Void {
        let preferences = UserDefaults.standard
        preferences.set(userId,forKey: "userId")
        preferences.synchronize()
    }
    
    class func getUserKey() -> String {
        
        
        if let userKey = UserDefaults.standard.string(forKey: "userKey") {
            return userKey
        } else {
            return "0"
        }
        
    }
    
    class func setUserKey(_ userKey : String) -> Void {
        let preferences = UserDefaults.standard
        preferences.set(userKey,forKey: "userKey")
        preferences.synchronize()
    }
    
    @objc class func getCc() -> String{
        if (UserDefaults.standard.object(forKey: "cc") == nil){
            return "CHS"
        }
        return UserDefaults.standard.object(forKey: "cc") as! String
    }

    class func setCc(_ cc : String){
        let preferences = UserDefaults.standard
        preferences.set(cc,forKey: "cc")
        switch cc.lowercased() {
        case "en":
            preferences.set(["en", "zh-Hans", "zh_HK", ], forKey: "AppleLanguages")
            break
        case "cht":
            preferences.set(["zh_HK", "zh-Hans", "en", ], forKey: "AppleLanguages")
            break
        case "chs":
            preferences.set(["zh-Hans", "zh_HK", "en", ], forKey: "AppleLanguages")
            break
        default:
            break
        }
        preferences.synchronize()
    }
  
    class func getUsername() -> String {
        return Context.getUserProfile().userName
    }
    
    class func setGender(_ gender : String){
        let preferences = UserDefaults.standard
        preferences.set(gender,forKey: "Gender")
        preferences.synchronize()
    }
    
    class func getGender() -> String{
        if let gender = UserDefaults.standard.object(forKey: "Gender") as? String {
            return  String.localize(gender)
        }
        
        return String.localize("LB_CA_GENDER_M")
    }
    
    class func setLoyaltyStatus(_ statusId : Int){
        let preferences = UserDefaults.standard
        preferences.set(statusId,forKey: "LoyaltyStatus")
        preferences.synchronize()
    }
    
    class func getLoyaltyStatus() -> Int{
        if let loyaltyStatus = UserDefaults.standard.object(forKey: "LoyaltyStatus") as? Int {
            return  loyaltyStatus
        }
        
        return 0
    }
    
    class func setVisitedVipCard(_ isVisited : Bool){
        UserDefaults.standard.set(isVisited, forKey: "IsVisitedVipCard")
    }
    
    class func getVisitedVipCard() -> Bool{
        if let isVisited = UserDefaults.standard.object(forKey: "IsVisitedVipCard") as? Bool {
            return  isVisited
        }
        
        return false
    }
    
    class func setVisitedWishlist(_ isVisited: Bool){
        UserDefaults.standard.set(isVisited, forKey: "IsVisitedWishlist")
    }
    
    class func getVisitedWishlist() -> Bool{
        if let isVisited = UserDefaults.standard.object(forKey: "IsVisitedWishlist") as? Bool {
            return  isVisited
        }
        
        return false
    }
    
    class func setVisitedCart(_ isVisited: Bool){
        UserDefaults.standard.set(isVisited, forKey: "IsVisitedCart")
    }
    
    class func getVisitedCart() -> Bool{
        if let isVisited = UserDefaults.standard.object(forKey: "IsVisitedCart") as? Bool {
            return  isVisited
        }
        
        return false
    }
    
    class func getHistory() -> [String]{
        
        if let searchStr = UserDefaults.standard.object(forKey: "History_search") as? String, searchStr.length > 0 {
            let strArray = searchStr.components(separatedBy: ",")
            return Array(strArray.prefix(15))
            
        }else {
            return []
        }
    }
    
    class func resetHistoryWeight() {
        let preferences = UserDefaults.standard
        preferences.set("",forKey: "History_search")
        preferences.synchronize()
    }
    
    class func addHistory(_ history : String){
        if let searchStr = UserDefaults.standard.object(forKey: "History_search") as? String, searchStr.length > 0 {
            var strArray = searchStr.components(separatedBy: ",")
            strArray.insert(history, at: 0)
            strArray = strArray.filterDuplicates({$0})
            
            UserDefaults.standard.set(strArray.joined(separator: ","), forKey: "History_search")
        } else {
            UserDefaults.standard.set("\(history)", forKey: "History_search")
        }
    }
    
    class func getDefaultPaymentMethod() -> String {
        return "LB_CA_ALIPAY" // Default Selection (the only one)
    }
    
    class func setDefaultPaymentMethod(_ paymentType : String){
        let preferences = UserDefaults.standard
        preferences.set(paymentType,forKey: "defaultPaymentMethod")
        preferences.synchronize()
    }
    
    class func setAnonymousShoppingCartKey(_ cartKey: String) {
        let preferences = UserDefaults.standard
        preferences.set(cartKey, forKey: ShoppingCartKey)
        preferences.synchronize()
    }
    
    class func setLastPostingTime(_ interVal: TimeInterval) {
        let preferences = UserDefaults.standard
        preferences.set(interVal, forKey: LastPostingTime)
        preferences.synchronize()
    }
    
    class func getLastPostingTime() -> TimeInterval? {
        return UserDefaults.standard.object(forKey: LastPostingTime) as? TimeInterval
    }
    
    class func setAnonymousShoppingCartKey(cartKey: String) {
        let preferences = UserDefaults.standard
        preferences.set(cartKey, forKey: ShoppingCartKey)
        preferences.synchronize()
    }
    
    class func anonymousShoppingCartKey() -> String? {
        return UserDefaults.standard.string(forKey: ShoppingCartKey)
    }
    
    class func setAnonymousWishListKey(_ wishListKey: String) {
        let preferences = UserDefaults.standard
        preferences.set(wishListKey, forKey: WishlistKey)
        preferences.synchronize()
    }
    
    class func anonymousWishListKey() -> String? {
        return UserDefaults.standard.string(forKey: WishlistKey)
    }
    
    class func hasValidAnonymousWishListKey() -> Bool {
        return (Context.anonymousWishListKey() != nil && Context.anonymousWishListKey() != "0")
    }
    
    static let CustomerServiceMerchantListKey = "CustomerServiceMerchantsKey"
    
    class func setCustomerServiceMerchants(_ merchants: CustomerServiceMerchants) {
        
        if let json = Mapper<CustomerServiceMerchants>().toJSONString(merchants, prettyPrint: false) {
            
            let preferences = UserDefaults.standard
            preferences.set(json, forKey: CustomerServiceMerchantListKey)
            preferences.synchronize()
            
        }
        
    }
    
    class func customerServiceMerchants() -> CustomerServiceMerchants {
        
        var result: CustomerServiceMerchants!
        let preferences = UserDefaults.standard
        
        if let json = preferences.object(forKey: CustomerServiceMerchantListKey) as? String {
            result = Mapper<CustomerServiceMerchants>().map(JSONString: json)
        }
        
        if result == nil {
            result = CustomerServiceMerchants()
        }
        
        return result
	}

    class func setLastAppUpgradeAlertPromptTime(_ time: Date) {
        let userDefaults = UserDefaults.standard
        userDefaults.set(time, forKey: LastAppUpgradeAlertPromptTime)
        userDefaults.synchronize()
    }
    
    class func getLastAppUpgradeAlertPromptTime() -> Date? {
        if let time = UserDefaults.standard.object(forKey: LastAppUpgradeAlertPromptTime) as? Date {
            return time
        }
        
        return nil
    }
    
    class func saveToken(_ token: Token) {
        if let json = Mapper<Token>().toJSONString(token, prettyPrint: false) {
            let preferences = UserDefaults.standard
            preferences.set(json, forKey: modelToken)
            preferences.synchronize()
        }
    }
    
    class func getTokenModel() -> Token {
        var result: Token!
        let preferences = UserDefaults.standard
        if let json = preferences.object(forKey: modelToken) as? String {
            result = Mapper<Token>().map(JSONString: json)
        }
        if result == nil {
            result = Token()
        }
        
        return result
    }
	
    class func saveUserProfile(_ user: User) {
        let json = Mapper<User>().toJSON(user)
        let preferences = UserDefaults.standard
        preferences.set(json, forKey: userProfile)
        
    }
    
    class func clearUserProfile() {
        UserDefaults.standard.removeObject(forKey: userProfile)
    }
    
    class func getUserProfile () -> User {
        var result: User!
        let preferences = UserDefaults.standard
        
        if let json = preferences.dictionary(forKey: userProfile) {
            result = Mapper<User>().map(JSONObject: json)
        }
        if result == nil {
            result = User()
        }
        
        return result
    }
    

    class func isUserAgent() -> Bool {
        if let merchants = customerServiceMerchants().merchants, !merchants.isEmpty {
            return true
        }
        
        return false
    }
    
    class func IAmMMAgent() -> Bool {
        if (UserDefaults.standard.object(forKey: IAmMMAgentKey) == nil) {
            return false
        }
        return UserDefaults.standard.object(forKey: IAmMMAgentKey) as! Bool
    }
    
    class func saveIAmMMAgent(_ isMM : Bool) -> Void {
        let userDefaults = UserDefaults.standard
        userDefaults.set(isMM, forKey: IAmMMAgentKey)
        userDefaults.synchronize()
    }

    
    class func isShowedPopupBanner(_ bannerKey: String) -> Bool {
        let key = "popupBannerRecord" + Context.getUserKey()
        if let recordMap = UserDefaults.standard.dictionary(forKey: key), let lastViewDate = recordMap[bannerKey] as? String {
            return lastViewDate == Constants.DateFormatter.getFormatter(.dateOnly).string(from: Date())
        }
        return false
    }
    
    // popupBannerRecord+userKey: {bannerKey1: 2015-12-24, bannerKey2: 2015-12-25}
    
    class func setShowedPopupBanner(_ bannerKey: String) {
        let key = "popupBannerRecord" + Context.getUserKey()
        var recordMap = UserDefaults.standard.dictionary(forKey: key) ?? [String: String]()
        recordMap[bannerKey] = Constants.DateFormatter.getFormatter(.dateOnly).string(from: Date())
        UserDefaults.standard.set(recordMap, forKey: key)
    }
    class func setDidShowPopupThankYou(_ isShow: Bool) {
        let key = "isShowingPopupThankYou" + Context.getUserKey()
        let preferences = UserDefaults.standard
        if isShow {
            preferences.set(isShow, forKey: key)
        } else {
            preferences.removeObject(forKey: key)
        }
        preferences.synchronize()
    }
    
    class func setEnableReferralPopup(_ enable: Bool?) {
        let preferences = UserDefaults.standard
        preferences.set(enable, forKey: ReferralCouponKey)
        preferences.synchronize()
    }
    
    class func isReferralPopupEnable() -> Bool? {
        return UserDefaults.standard.object(forKey: ReferralCouponKey) as? Bool
    }
    
    class func didShowPopupThankYou () -> Bool {
        let key = "isShowingPopupThankYou" + Context.getUserKey()
        if (UserDefaults.standard.object(forKey: key) == nil) {
            return false
        }
        return UserDefaults.standard.object(forKey: key) as! Bool
    }
    
    class func hasShownTutorialSpash() -> Bool {
        return true /*NSUserDefaults.standardUserDefaults().boolForKey("hasShowTutorialPage")*/
    }
    
    class func setShownTutorialSpash() {
        UserDefaults.standard.set(true, forKey: "hasShowTutorialPage")
    }
    
    static var isShowedDefaultZoneSetting : Bool {
        get {
            if let isShowedDefaultZoneSetting = UserDefaults.standard.object(forKey: "isShowedDefaultZoneSetting") as? Bool {
                return isShowedDefaultZoneSetting
            }
            return false
        }
        
        set {
            UserDefaults.standard.set(newValue, forKey: "isShowedDefaultZoneSetting")
        }
    }
    
    static var currentZone : ColorZone = Context.defaultZone
    
    static var defaultZone : ColorZone {
        get {
            
            if LoginManager.getLoginState() != .validUser {
                return .redZone
            }
            
            if let zoneId = UserDefaults.standard.object(forKey: "colorZoneSetting") as? Int, let zone = ColorZone(rawValue: zoneId) {
                return zone
            }
            return .redZone
        }
        
        set {
            if LoginManager.getLoginState() == .validUser {
                UserDefaults.standard.set(newValue.rawValue, forKey: "colorZoneSetting")
            }
        }
    }
    
    class func clearZoneSetting() {
        UserDefaults.standard.removeObject(forKey: "colorZoneSetting")
        UserDefaults.standard.removeObject(forKey: "isShowedDefaultZoneSetting")
        Context.currentZone = Context.defaultZone
    }
    
    static var isChannelExpire: Bool? {
        get {
            if let lastUpdate = UserDefaults.standard.object(forKey: "ChannelLastUpdate") as? Date, let minutesAgo = lastUpdate.minutesAgo(), minutesAgo < Constants.CMSExpireInMin {
                return false
            }
            return true
        }
    }
    
    class func setCMSChannel(channels: [CMSPageModel]) {
        let jsonStr = Mapper<CMSPageModel>().toJSONArray(channels)
        UserDefaults.standard.set(jsonStr, forKey: "CMSPageModel")
        UserDefaults.standard.set(Date(), forKey: "ChannelLastUpdate")
    }
    
    class func getCMSChannel(forceCache: Bool = false) -> [CMSPageModel]? {
        if let json = UserDefaults.standard.object(forKey: "CMSPageModel") as? [[String: Any]],
            (forceCache || !isChannelExpire!) {
            let channels = Mapper<CMSPageModel>().mapArray(JSONArray: json)
            return channels
        }
        return nil
    }
    

    static var userHasDismissedTopBanner : Bool {
        get {
            if let value = UserDefaults.standard.object(forKey: "userHasDismissedTopBanner") as? Bool {
                return value
            }
            return false
        }
        
        set {
            UserDefaults.standard.set(newValue, forKey: "userHasDismissedTopBanner")
        }
    }

    static var historyHashtags : [String] {
        get {
            if let result = UserDefaults.standard.object(forKey: "historyHashtags") as? [String] {
                return result
            }
            return [String]()
        }
        
        set {
            UserDefaults.standard.setValue(newValue, forKey: "historyHashtags")

        }
    }
}
