//
//  AppDelegate.swift
//  merchant-ios
//
//  Created by Koon Kit Chan on 17/9/15.
//  Copyright © 2015 Koon Kit Chan. All rights reserved.
//

import UIKit
import RealmSwift
import Fabric
import Crashlytics
import ObjectMapper
import Alamofire
import Kingfisher
import PromiseKit
import SKPhotoBrowser
import UserNotifications

@UIApplicationMain
class AppDelegate: UIResponder, UIApplicationDelegate, Authorize {
    
    // MARK: - Authorize imp
    func authorized() -> Bool {
        return LoginManager.isValidUser()
    }
    
    func howToAuthorize(url: String, query: QBundle) -> String {
        return Navigator.mymm.website_login
    }
    

    var window: UIWindow?
    
    func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplicationLaunchOptionsKey: Any]?) -> Bool {
        
        window = UIWindow(frame: UIScreen.main.bounds)
        if let twindow = self.window {
            Navigator.shared.launching(root: twindow)
            Navigator.shared.addScheme(scheme: "https")
            Navigator.shared.addScheme(scheme: "http")
            Navigator.shared.addScheme(scheme: "mymm")
            Navigator.shared.addHost(host: "**mymm.com")
            Navigator.shared.addHost(host: "**mymm.cn")
            Navigator.shared.setAuthorize(auth: self)
        }
        //无痕埋点初始化
        trackingSetup()
        
        // Disable animations for UiTest
        if ProcessInfo.processInfo.environment["animations"] == "0" {
            UIView.setAnimationsEnabled(false)
        }
        
        let _ = RequestFactory.networkManager //init the network manager to run the settings at beginning
        
        configWebViewCookies()
        configKingfisher()
        configRealm()
        configCrashlytics()
        configJPush(launchOptions)
        configTheme()
        ShareManager.sharedManager.configSNS()
        configNSURLCache()
        configCacheDirectories()
        configGrowingIO()
        configFilters()
        configPhotoBrowser()
        configAudioSession()
        
//        registerPushToken()
        
        Utils.requestLocationAndPushNotification()
        
        let _ = AnalyticsManager.sharedManager
        ImageCacheManager.configCache()
        
        self.goToStoreFront()
        
        commonAwake()
        
        window?.makeKeyAndVisible()
        configMagicWindow()
        TimestampService.defaultService.updateServerTime()
        if let notification = launchOptions?[UIApplicationLaunchOptionsKey.remoteNotification] as? [NSObject: AnyObject] {
            NotificationManager.sharedManager.handleReceiveNotification(true, userInfo: notification)
        }
        
        webviewSetting()
        return true
    }
    
    private func webviewSetting(){
        let webView = UIWebView(frame: CGRect.zero)
        let userAgent: String? = webView.stringByEvaluatingJavaScript(from: "navigator.userAgent")
        let newUserAgent: String? = userAgent! + ("; mymm/iOS \(Constants.AppVersion)")
        let dictionary = [
            "UserAgent" : newUserAgent!
        ]
        UserDefaults.standard.register(defaults: dictionary)
    }
    
    private func configFilters() {
        // TuSDK App Key
        TuSDK.initSdk(withAppKey: Platform.TutuAppKey)
        TutuObjCWrapper.tutuFilterManager()
    }
    
    private func configPhotoBrowser() {
        SKPhotoBrowserOptions.displayCounterLabel = true                         // counter label will be hidden
        SKPhotoBrowserOptions.displayBackAndForwardButton = false                 // back / forward button will be hidden
        SKPhotoBrowserOptions.displayAction = true                               // action button will be hidden
        SKPhotoBrowserOptions.displayDeleteButton = false                          // delete button will be shown
        SKPhotoBrowserOptions.displayHorizontalScrollIndicator = false            // horizontal scroll bar will be hidden
        SKPhotoBrowserOptions.displayVerticalScrollIndicator = false              // vertical scroll bar will be hidden
    }
 
    func configWebViewCookies() {
        HTTPCookieStorage.shared.cookieAcceptPolicy = .always
    }
    
    func configGrowingIO() {
//        TalkingDataAppCpa.init(Platform.TalkingData.AdTrackingID, withChannelId: "AppStore")
        TrackManager.configTrackInfo()
    }
    
    func configAudioSession() {
        do {
            try AVAudioSession.sharedInstance().setCategory(AVAudioSessionCategoryAmbient)
        } catch _ {}
    }
    
    private func goToStoreFront() {
        if LoginManager.getLoginState() == .validUser {
            Fly.store.switchStoreDomain("\(Context.getUserId())")
            LoginManager.loadFriendRequest()
        } else {
            LoginManager.guestLogin()
        }
        LoginManager.goToStorefront()
    }
    
    func application(_ application: UIApplication, didRegisterForRemoteNotificationsWithDeviceToken deviceToken: Data) {
        NSLog("DeviceToken : \(deviceToken)")
        JPUSHService.registerDeviceToken(deviceToken)
    }
    
    func application(_ application: UIApplication, didFailToRegisterForRemoteNotificationsWithError error: Error) {
        
    }
    
    func application(_ application: UIApplication, didReceiveRemoteNotification userInfo: [AnyHashable : Any]) {
        let active: Bool = application.applicationState == .active
        NotificationManager.sharedManager.handleReceiveNotification(active, userInfo: userInfo)
        let pushInfo = userInfo.jsonPrettyStringEncoded() ?? "推送消息错误..."
        print("-------push infomation--------\n\(pushInfo)")
        JPUSHService.handleRemoteNotification(userInfo)
    }

    func application(_ application: UIApplication, didReceiveRemoteNotification userInfo: [AnyHashable : Any], fetchCompletionHandler completionHandler: @escaping (UIBackgroundFetchResult) -> Void) {
        let active: Bool = application.applicationState == .active
        NotificationManager.sharedManager.handleReceiveNotification(active, userInfo: userInfo)
        let pushInfo = userInfo.jsonPrettyStringEncoded() ?? "推送消息错误..."
        print("-------push infomation--------\n\(pushInfo)")
        JPUSHService.handleRemoteNotification(userInfo)
        completionHandler(UIBackgroundFetchResult.newData)
    }
    
    func applicationWillResignActive(_ application: UIApplication) {
        // Sent when the application is about to move from active to inactive state. This can occur for certain types of temporary interruptions (such as an incoming phone call or SMS message) or when the user quits the application and it begins the transition to the background state.
        // Use this method to pause ongoing tasks, disable timers, and throttle down OpenGL ES frame rates. Games should use this method to pause the game.
    }

    func applicationDidEnterBackground(_ htapplication: UIApplication) {
        // Use this method to release shared resources, save user data, invalidate timers, and store enough application state information to restore your application to its current state in case it is terminated later.
        // If your application supports background execution, this method is called instead of applicationWillTerminate: when the user quits.
        
        WebSocketManager.sharedInstance().stopService()
        Reachability.shared().stopNotifier()
        PostManager.savePostIfNeeded()
        AnalyticsManager.sharedManager.sleep()
        
        VideoPlayManager.shared.appEnterBackground()
    }

    private let UpdateIntervalFor5Min = TimeInterval(5 * 60)
    private let UpdateIntervalFor60Min = TimeInterval(60 * 60)
    private var last5MinUpdateTimestamp: TimeInterval? = nil
    private var last60MinUpdateTimestamp: TimeInterval? = nil
    
    func commonAwake() {
        
        JPUSHService.resetBadge()
        UserService.deviceZero()
        
        UIApplication.shared.applicationIconBadgeNumber = 0
        
        // Social Message unread count
        SocialMessageManager.sharedManager.getSocialMessageUnreadCount()
        
        let now = Date().timeIntervalSince1970
        // 5 min
        let update5Min = {
            // short-circuit if last5MinUpdateTimestamp == nil so last5MinUpdateTimestamp! is always safe
            if self.last5MinUpdateTimestamp == nil || (now - self.last5MinUpdateTimestamp! > self.UpdateIntervalFor5Min) {
                self.last5MinUpdateTimestamp = now
                if LoginManager.getLoginState() == .validUser {
                    CacheManager.sharedManager.refreshCart()
                    CacheManager.sharedManager.refreshWishList()
                    
                    // cache status friend and follow
                    FriendHelper.upgradeStatusFriendAndFollow()
                }
                Log.debug("Update 5 min cache")
            } else {
                Log.debug("last5MinUpdateTimestamp : \(now - self.last5MinUpdateTimestamp!)")
            }
        }
        update5Min()
        
        // 60 min
        let update60Min = {
            // short-circuit if last60MinUpdateTimestamp == nil so last5MinUpdateTimestamp! is always safe
            if self.last60MinUpdateTimestamp == nil || (now - self.last60MinUpdateTimestamp! > self.UpdateIntervalFor60Min) {
                self.last60MinUpdateTimestamp = now
                
                CacheManager.sharedManager.fetchAllMerchants()
                CacheManager.sharedManager.fetchAllBrands()
                CacheManager.sharedManager.fetchAllCategories()
                if LoginManager.getLoginState() == .validUser {
                    CacheManager.sharedManager.fetchAllUsers()
                    FriendHelper.getFriendAliasList()
                }
                                
                Log.debug("Update 60 min cache")
            } else {
                Log.debug("last60MinUpdateTimestamp : \(now - self.last60MinUpdateTimestamp!)")
            }
        }
        update60Min()
        
        if LoginManager.getLoginState() == .validUser {
            WebSocketManager.sharedInstance().startService(Context.getUserKey())
            NotificationCenter.default.post(name: Constants.Notification.refreshFriendRequest, object: nil)
        }
        Reachability.shared().startNotifier()
    }
    
    func applicationWillEnterForeground(_ application: UIApplication) {
        // Called as part of the transition from the background to the inactive state; here you can undo many of the changes made on entering the background.
        commonAwake()
        Utils.logNotificationEnabled()
    }
    
    func applicationDidBecomeActive(_ application: UIApplication) {
        // Restart any tasks that were paused (or not yet started) while the application was inactive. If the application was previously in the background, optionally refresh the user interface.
        AnalyticsManager.sharedManager.wakeUp()
        TimestampService.defaultService.updateServerTime()
    }
    
    func applicationWillTerminate(_ application: UIApplication) {
        // Called when the application is about to terminate. Save data if appropriate. See also applicationDidEnterBackground:.
        // Saves changes in the application's managed object context before the application terminates.
        PostManager.savePostIfNeeded()
        AnalyticsManager.sharedManager.sleep()
    }
    
    func configRealm() {
        let realmName = "MM.0.3.realm"
        
        // Override point for customization after application launch.
        let config = Realm.Configuration(
            fileURL: NSURL(fileURLWithPath: RealmPath + realmName) as URL,
                
            // Set the new schema version. This must be greater than the previously used
            // version (if you've never set a schema version before, the version is 0).
            schemaVersion: UInt64(0),
            
            // Set the block which will be called automatically when opening a Realm with
            // a schema version lower than the one set above
            migrationBlock: { migration, oldSchemaVersion in
                // We haven’t migrated anything yet, so oldSchemaVersion == 0
                if (oldSchemaVersion < 3) {
                    // Nothing to do!
                    // Realm will automatically detect new properties and removed properties
                    // And will update the schema on disk automatically
                }
            }
        )
        
        Log.debug(config.fileURL)
        
        // Tell Realm to use this new configuration object for the default Realm
        Realm.Configuration.defaultConfiguration = config
    }
    
    func configKingfisher() {
        if Constants.Path.TrustAnyCert {
            ImageDownloader.default.downloadTimeout = 60.0
            KingfisherManager.shared.downloader.trustedHosts = Set(Constants.Path.ignoreSSLDomains)
        }
    }
    
    private func configJPush(_ launchOptions: [UIApplicationLaunchOptionsKey: Any]?) {
        JPUSHService.setup(withOption: launchOptions, appKey: Constants.JPush.AppKey, channel: Constants.JPush.Channel, apsForProduction: Constants.JPush.IsProduction)
        NotificationCenter.default.addObserver(forName: NSNotification.Name.jpfNetworkDidLogin, object: nil, queue: nil) { (notification) in
            JPUSHService.registrationIDCompletionHandler { (resCode, registrationID) in
                if let JPushId = registrationID {
                    NSLog("JPush - Get RegistrationID: \(JPushId)") // Keep the log in release build
                    JPUSHService.updateMMTagsAndAlias()
                    UserService.updateDevice(JPushId, deviceIdPrevious: nil, completion: nil)
                } else {
                    NSLog("JPush - fail to get RegistrationID (\(resCode))") // Keep the log in release build
                    ErrorLogManager.sharedManager.recordNonFatalError(withException: .DataIsEmpty, parameters: ["jpush_fail_rescode": "\(resCode)"])
                }
            }
            Utils.logNotificationEnabled()
        }
    }
    
    func configCrashlytics(){
        // Register for Fabrics and Crashlytics
        Fabric.with([Crashlytics.self()])
    }
    
    func configMagicWindow(){
        MWApi.registerApp(Constants.MagicWindow.AppId)
        MWApi.registerMLinkDefaultHandler({ (url: URL, params: Dictionary<AnyHashable, Any>?) -> Void in
            self.magicWindow(url: url, params: params)
        })
        MWApi.registerMLinkHandler(withKey: Constants.MagicWindow.MLinkKey, handler: { (url: URL, params: Dictionary<AnyHashable, Any>?) -> Void in
            self.magicWindow(url: url, params: params)
        })
    }
    
    func magicWindow(url: URL, params: Dictionary<AnyHashable, Any>?) {
        var urlString = ""
        if let params = params {
            if let type = params["type"] as? String {
                let value = (params["value"] as? String ?? "").replacingOccurrences(of: "&amp;", with: "&")
 //             url = String.format("https://%s/%s/%s", Constant.SHARING_HOST, type, value)
                urlString = "https://m.mymm.com/\(type)/\(value)"
            }
        }
        
        var bundle = QBundle()
        if let params = params {
            for (key,value) in params {
                if Injects.isBaseType(value) {
                    bundle[key.description] = QValue("\(value)")
                } else if let entity = value as? MMJsonable {
                    bundle[key.description] = QValue("\(entity.ssn_jsonString())")
                } else if let v = value as? QValue {
                    bundle[key.description] = v
                }
            }
            
            // Referrer User 统一处理，iOS没有此逻辑，直接取key if let dict = queryDict, let referrer = dict["UserKeyReferrer"]
            // https://mymm.com/referral_coupon?referrerUserKey=c49abfb4-806c-11e6-b5b6-0017fa005a3a&cs=sms&cm=message&ca=u:c49abfb4-806c-11e6-b5b6-0017fa005a3a&mw=1
            if params.keys.contains("ca") {
                if let value = params["ca"] as? String {
                    let ss = value.split(separator: ":")
                    if (ss.count == 2) {
                        bundle["UserKeyReferrer"] = QValue(ss[1])
                    }
                }
            }
        }
        
        if !urlString.isEmpty {
            Navigator.shared.dopen(urlString,params:bundle)
        } else {
            Navigator.shared.dopen(url.absoluteString,params:bundle)
        }
        
    }
    
    func configTheme(){
        
        self.window?.tintColor = UIColor.primary1()
        self.window?.backgroundColor = UIColor.white
        
        // Sets the default color of the background of the UITabBar
        UITabBar.appearance().barTintColor = UIColor.white
        UITabBar.appearance().tintColor = UIColor.secondary2()
        UIApplication.shared.statusBarStyle = .default
        if let _ = UIFont(name: Constants.Font.Normal, size: Constants.Font.Size) {//#available(iOS 9, *) {
            UILabel.appearance().substituteAllFontName = Constants.Font.Normal
            UILabel.appearance().substituteAllFontNameBold = Constants.Font.Bold
        } else {
            UILabel.appearance().substituteAllFontName = Constants.iOS8Font.Normal
            UILabel.appearance().substituteAllFontNameBold = Constants.iOS8Font.Bold
        }
    }
    
    func configNSURLCache() {
        URLCache.shared = URLCache(memoryCapacity: 4 * 1024 * 1024, diskCapacity: 50 * 1024 * 1024, diskPath: nil)
    }
    
    func application(_ application: UIApplication, continue userActivity: NSUserActivity, restorationHandler: @escaping ([Any]?) -> Void) -> Bool {
        if Constants.DeepShare.enable {
            return MWApi.continue(userActivity)
        } else {
            //TODO: pending implementation
            return true
        }
    }
    
    func application(_ application: UIApplication, handleOpen url: URL) -> Bool {
        
        if url.scheme == "mymm" {
            return openDeeplinkMyMMScheme(url: url)
        }
        
        if url.scheme == "tencent\(Constants.qqAppID)" {
            return TencentOAuth.handleOpen(url)
        }
        
        var urlHandled = WXApi.handleOpen(url, delegate: WeChatManager.sharedInstance())
        if !urlHandled {
            urlHandled = WeiboSDK.handleOpen(url, delegate: ShareManager.sharedManager)
        }
        
        return urlHandled
    }
    
    func openURL(_ url: URL) -> Bool {
        if url.scheme == "mymm" {
            let query = Urls.query(url: url)
            CacheManager.sharedManager.saveSmzdmCode(query: query)
            AnalyticsManager.sharedManager.renewSession(query: query)
            return openDeeplinkMyMMScheme(url: url)
        }
        
        if (url.host == "safepay") {
            //跳转支付宝钱包进行支付，处理支付结果
            //            AlipaySDK.defaultService().processOrderWithPaymentResult(url, standbyCallback: nil)
            AlipaySDK.defaultService().processOrder(withPaymentResult: url, standbyCallback: { (resultDic) -> Void in
                Log.debug("Finish payment")
                Log.debug(resultDic)
            })
        }
        
        if url.scheme == "tencent\(Constants.qqAppID)" {
            return QQApiInterface.handleOpen(url, delegate: ShareManager.sharedManager)
        }
        
        if url.scheme == "wb\(Constants.weiboAppID)" {
            return WeiboSDK.handleOpen(url, delegate: ShareManager.sharedManager)
        }
        
        if TrackManager.handleURL(url) {
            return true
        }
        
        return WXApi.handleOpen(url, delegate: WeChatManager.sharedInstance())
    }
    
    func application(_ app: UIApplication, open url: URL, options: [UIApplicationOpenURLOptionsKey : Any] = [:]) -> Bool {
        return openURL(url)
    }
    
    func application(_ application: UIApplication, open url: URL, sourceApplication: String?, annotation: Any) -> Bool {
        return openURL(url)
    }
    
    func configCacheDirectories() {
        let fn = FileManager.default
        let paths = [CachePath, RealmPath]
        for path in paths {
            if !fn.fileExists(atPath: path) {
                do {
                    try fn.createDirectory(at: URL(fileURLWithPath: path), withIntermediateDirectories: true, attributes: nil)
                } catch {
                    // ignore
                }
            }
        }
    }
    
    func applicationDidReceiveMemoryWarning(_ application: UIApplication) {
        Log.debug("::::: applicationDidReceiveMemoryWarning :::::")
    }
    
    //MARK: - Deeplink
    private func openDeeplinkMyMMScheme(url: URL) -> Bool {
        let absoluteUrl = url.absoluteString
        let tidyUrl = openDeeplinkMyMMSchemeTidy(url:url)
        //mymm://mymm.com?type=z&value=132%2F132%3Ffeedback%3D%26cpsTime%3D
        if DeepLinkManager.sharedManager.shouldResolveDeeplink(url: absoluteUrl) {
            Navigator.shared.dopen(tidyUrl)
            return true
        }
        if !tidyUrl.isEmpty {
            Navigator.shared.dopen(tidyUrl)
        }
        return true
    }
    
    private func openDeeplinkMyMMSchemeTidy(url: URL) -> String {
        var urlString = url.absoluteString
        if let qs = url.query {
            let query = Urls.query(query: qs)
            if let type = query["type"]?.string, let value = query["value"]?.string, !type.isEmpty, !value.isEmpty {
                urlString = Navigator.mymm.mymm_website_home + type + "/" + value
                urlString = Urls.tidy(url: urlString, query: query)
            }
        }
        return urlString
    }
}

extension AppDelegate: JPUSHRegisterDelegate {
    @available(iOS 10.0, *)
    func jpushNotificationCenter(_ center: UNUserNotificationCenter!, willPresent notification: UNNotification!, withCompletionHandler completionHandler: ((Int) -> Void)!) { // 前台
        let userInfo = notification.request.content.userInfo
        if let trigger = notification.request.trigger {
            if trigger.isKind(of: UNPushNotificationTrigger.self) {
                NotificationManager.sharedManager.handleReceiveNotification(true, userInfo: userInfo)
                let pushInfo = userInfo.jsonPrettyStringEncoded() ?? "推送消息错误..."
                print("-------push infomation--------\n\(pushInfo)")
                JPUSHService.handleRemoteNotification(userInfo)
            }
        }
        
//        completionHandler(Int(UNNotificationPresentationOptions.badge.rawValue | UNNotificationPresentationOptions.alert.rawValue | UNNotificationPresentationOptions.sound.rawValue))
    }
    @available(iOS 10.0, *)
    func jpushNotificationCenter(_ center: UNUserNotificationCenter!, didReceive response: UNNotificationResponse!, withCompletionHandler completionHandler: (() -> Void)!) { // 后台
        let userInfo = response.notification.request.content.userInfo
        if let trigger = response.notification.request.trigger {
            if trigger.isKind(of: UNPushNotificationTrigger.self) {
                NotificationManager.sharedManager.handleReceiveNotification(false, userInfo: userInfo)
                let pushInfo = userInfo.jsonPrettyStringEncoded() ?? "推送消息错误..."
                print("-------push infomation--------\n\(pushInfo)")
                JPUSHService.handleRemoteNotification(userInfo)
            }
        }
        completionHandler()
    }
}

