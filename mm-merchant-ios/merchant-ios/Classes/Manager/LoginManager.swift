//
//  LoginManager.swift
//  merchant-ios
//
//  Created by Koon Kit Chan on 3/2/2016.
//  Copyright © 2016 WWE & CO. All rights reserved.
//Ï

import Foundation
import PromiseKit
import ObjectMapper


public enum LoginState {
    case validUser, guestUser, loggedOut
}

class LoginManager {
    
    static let RESOURCE_PATH = Constants.Path.Host + "/resource/get"
    
    class func signup(_ parameters: AuthService.SignUpParameter) -> Promise<Void> {
        return AuthService.requestSignup(parameters).then { (token) -> Promise<User> in
            LoginManager.saveLoginState(token)
            return UserService.fetchUser(true)
        }.then { (user) -> Void in
            LoginManager.didRegister(user: user)
            Context.clearInvitationCode()
            LoginManager.setUserAfterLogin(user)
            TrackManager.signUp(user.userKey)
        }
    }
    
    class func shouldEnableAccountLogin(_ completion: @escaping ((Bool) -> Void)) {
        let parameters: [String: Any] = ["keys": "ACCOUNT_LOGIN_ENABLE_IOS_V2"]
        
        let request = RequestFactory.get(RESOURCE_PATH, parameters: parameters, appendUserKey: false)
        request.exResponseJSON(0, dnsRetryCount: 0, completionHandler: { response in
            if response.result.isSuccess {
                if let dicts = response.result.value as? [Dictionary<String, String>], dicts.count > 0, let v = dicts[0]["V"] {
                    if let accountLogin = Mapper<AccountLoginEnable>().map(JSONString: v) {
                        let version = accountLogin.appVersion
                        
                        if version == Constants.AppVersion {
                            let enable = accountLogin.enable
                            completion(enable)
                            return
                        }
                    }
                }
            }
            completion(false)
        })
    }
    
    // MARK: - Data, API calls
    
    class func login(_ username: String, password: String) -> Promise<Void> {
        return AuthService.requestLogin(username, password: password).then { (token) -> Promise<User> in
            LoginManager.saveLoginState(token)
            return UserService.fetchUser(true)
        }.then { (user) -> Void in
            LoginManager.updateUserInfoAfterLogin()
            LoginManager.setUserAfterLogin(user)
            TrackManager.signIn(user.userKey)
            NotificationCenter.default.post(name: Constants.Notification.loginSucceed, object: nil)
        }
    }
    
    
    class func guestLogin(){
        let guest = User.guestUser()
        Context.setUserKey(guest.userKey)
        Context.setToken("")
        Context.saveUserProfile(guest)
        LoginManager.setAuthenticatedUser(false)
        AnalyticsManager.sharedManager.updateSession()
        
    }
    
    private class func getAuthenticatedUser() -> Bool {
        return UserDefaults.standard.bool(forKey: "authenticated")
    }
    
    private class func setAuthenticatedUser(_ authenticated : Bool){
        UserDefaults.standard.set(authenticated,forKey: "authenticated")
    }
    
    class func getLoginState() -> LoginState {
        if LoginManager.getAuthenticatedUser() { // only valid user make use of this boolean
            return .validUser
        }
        
        if Context.getUserProfile().isGuest {
            return .guestUser
        }
        
        return .loggedOut
    }
    
    class func isValidUser() -> Bool {
        return getLoginState() == .validUser
    }
    
    class func isGuestUser() -> Bool {
        return getLoginState() == .guestUser
    }
    
    class func saveLoginState(_ token : Token){
        Context.setToken(token.token)
        Context.setUserId(token.userId)
        Context.setUserKey(token.userKey)
        LoginManager.setAuthenticatedUser(true)
//        Context.saveIAmMMAgent(token.isMM)
        // set Token model
        Context.saveToken(token)
        Fly.store.switchStoreDomain("\(token.userId)")
    }
    
    class func updateUserInfoAfterLogin() {
        CartHelper.upgradeShoppingCart()
        CartHelper.upgradeWishList()
        
        // cache status friend and follow
        FriendHelper.upgradeStatusFriendAndFollow()
        FriendHelper.getFriendAliasList()
        
        // load friend request
        loadFriendRequest()
        
        //Show Popup Banner
//        BannerManager.sharedManager.showPopupBanner()
        
        JPUSHService.updateMMTagsAndAlias()
    }
    
    class func setUserAfterLogin(_ user: User) {
        let MMRole = user.userSecurityGroupArray
        Context.saveIAmMMAgent(MMRole.contains(2) || MMRole.contains(5))
        Context.setCustomerServiceMerchants(user.customerServiceMerchants())
        AnalyticsManager.sharedManager.updateSession()
        WebSocketManager.sharedInstance().startService(user.userKey)
        
        SocialMessageManager.sharedManager.getSocialMessageUnreadCount()
    }
    
    class func didRegister(user: User) {
//        TalkingDataAppCpa.onRegister(user.userKey)
        TrackManager.setUserId(user.userKey)
    }
    
    class func logout(){
        Context.userHasDismissedTopBanner = false
        Context.setToken("")
        Context.setUserId(0)
        Context.setUserKey("0")
        Context.clearUserProfile()
        LoginManager.setAuthenticatedUser(false)
        Context.saveIAmMMAgent(false)
        Context.setCustomerServiceMerchants(CustomerServiceMerchants(merchants: []));
        Context.clearZoneSetting()

        CartHelper.clearShoppingCart()
        CartHelper.clearWishListCart()
        WebSocketManager.sharedInstance().stopService()
        
        PostManager.clearCache()
        CacheManager.sharedManager.removeAllBannerCache()
        CacheManager.sharedManager.removeIMCache()
        CacheManager.sharedManager.removeAllUserCache()
        CouponManager.shareManager().removeAllCouponCache()
        FriendHelper.clearFriendAliasList()
        
        AnalyticsManager.sharedManager.createNewSession()
        ImageCacheManager.clearMemoryCache()
        NotificationCenter.default.post(name: Constants.Notification.userLoggedOut, object: nil)
        Context.setEnableReferralPopup(nil)
        JPUSHService.updateMMTagsAndAlias()
        
        WebSocketManager.sharedInstance().clearNumberOfUnread()
        CacheManager.sharedManager.clearNumberOfFriendRequests()
        CacheManager.sharedManager.clearClaimedCouponFlag()
        
        SocialMessageManager.sharedManager.clearUnreadCount()
        
        Fly.store.switchStoreDomain("")
    }
    
    static func hasStorefront() -> Bool {
        if let rootVC = UIApplication.shared.delegate!.window!!.rootViewController {
            if let _ = rootVC as? MMTabBarController {
                return true
            }
        }
        return false
    }
    
    static func getStorefront() -> MMTabBarController? {
        if let rootVC = UIApplication.shared.delegate!.window!!.rootViewController {
            if let mainTababr = rootVC as? MMTabBarController {
                return mainTababr
            }
        }
        return nil
    }
    
    // MARK: - UI, Flow Control
    
    static func goToStorefront(){
        UIApplication.shared.delegate!.window!!.rootViewController = MMTabBarController()
    }

    static func goToLogin(_ whenAppLaunch: Bool = false, loginAfterCompletion: LoginAfterCompletion? = nil) {
        let loginNavController = MmNavigationController()
        let invitationCodeSuccessfulViewController : InvitationCodeSuccessfulViewController = InvitationCodeSuccessfulViewController()
        if whenAppLaunch {
            invitationCodeSuccessfulViewController.hideCrossView = true
        }
        invitationCodeSuccessfulViewController.loginAfterCompletion = loginAfterCompletion
        loginNavController.viewControllers = [invitationCodeSuccessfulViewController]
        if let windown = UIApplication.shared.delegate?.window {
            windown?.rootViewController?.present(loginNavController, animated: true, completion: nil)
        }
    }
    
    class func loadFriendRequest(completion:(() -> Void)? = nil) {
        if LoginManager.getLoginState() != .validUser {
            return // skip loading auth required API for non-logged in state
        }
        
        FriendService.listRequest() { response in
            if response.result.isSuccess {
                if response.response?.statusCode == 200 {
                    let friendRequests = Mapper<User>().mapArray(JSONObject: response.result.value) ?? []
                    CacheManager.sharedManager.updateNumberOfFriendRequests(friendRequests.count, notify: true)
                }
                
                if let strongCompletion = completion {
                    strongCompletion()
                }
            }
        }
    }
    
    //MARK: check member logged in
    class func isLoggedInErrorPrompt() -> Bool {
        guard LoginManager.isValidUser() else {
            //no auth user
            let alertVC = UIAlertController(title: String.localize("LB_ERRORS") , message: String.localize("MSG_ERR_USER_AUTHENTICATION_FAIL"), preferredStyle: UIAlertControllerStyle.alert)
            alertVC.view.tintColor = UIColor.alertTintColor()
            let cancelAction = UIAlertAction(title: String.localize("LB_TO_CANCEL"), style: UIAlertActionStyle.default, handler: nil)
            alertVC.addAction(cancelAction)
            UIApplication.shared.delegate?.window??.rootViewController?.present(alertVC, animated: true, completion: nil)
            return false
        }
        return true
    }
}

