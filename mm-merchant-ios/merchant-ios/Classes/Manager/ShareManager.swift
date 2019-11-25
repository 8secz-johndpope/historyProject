//
//  ShareManager.swift
//  merchant-ios
//
//  Created by Tony Fung on 26/5/2016.
//  Copyright © 2016年 WWE & CO. All rights reserved.
//

import Kingfisher
import MessageUI
import PromiseKit


enum ShareMethod: Int {
    case unknown = 0
    case weChatMessage 
    case weChatMoment
    case weiboWall
    case qqMessage
    case qqZone
    case sms
    case mmInternal
    case weiboMessage
    
}

enum MasterCouponType: Int {
    case myMMCoupon = 1
    case merchantCoupon = 2
}

enum SharePostIdentity {
    case otherUser(userName: String)
    case myself
    case merchant(merchantName: String)
}


struct WeiboAccessToken {
    var userID: String
    var refreshToken: String
    var accessToken : String
    private var expiryTimestamp : TimeInterval
    
    //helper function
    
    var expiryDate : Date {
        get {
            return Date(timeIntervalSince1970: expiryTimestamp)
        }
    }
    
    init(authResponse: WBAuthorizeResponse) {
        self.userID = authResponse.userID
        self.refreshToken = authResponse.refreshToken
        self.accessToken = authResponse.accessToken
        self.expiryTimestamp = authResponse.expirationDate.timeIntervalSince1970
    }
    
    init(dictionary: [String: Any]) {
        self.userID = dictionary["userID"] as? String ?? ""
        self.refreshToken = dictionary["refreshToken"] as? String ?? ""
        self.accessToken = dictionary["accessToken"] as? String ?? ""
        self.expiryTimestamp = dictionary["expiryTimestamp"] as? TimeInterval ?? 0
    }
    
    func dictionary() -> [String: Any] {
        return ["userID": userID as Any, "refreshToken": refreshToken as Any, "accessToken": accessToken as Any, "expiryTimestamp": expiryTimestamp as Any]
    }
    
}

class ShareManager: NSObject,  MFMessageComposeViewControllerDelegate {

    
    // MARK: - Social network share function -
    private let key_phone_number = "phoneNumber"
    private let key_title = "title"
    private let key_description = "description"
    private let key_contentImage = "imageKey"
    // newly added type
    private let key_article_url = "article_url"
    private let key_article_thumb = "article_thumb_image"
    private let key_object_id = "object_id"
    private let WEIBO_MAX_MESSAGE_LENGTH = 140
    
    private var promisesTupleGroup : [ShareMethod : Promise<Bool>.PendingTuple?] = [:]
    
    
    class var sharedManager: ShareManager {
        get {
            struct Singleton {
                static let instance = ShareManager()
            }
            return Singleton.instance
        }
    }
    
    
    func invokeSharingCompletion(_ method: ShareMethod, isSuccess: Bool){
        if let tuple = promisesTupleGroup[method] {
            tuple?.fulfill(isSuccess)
            promisesTupleGroup.removeValue(forKey: method)
        }
    }
    
    // MARK: SNS Configurations
    var tencentOAuth : TencentOAuth!

	private final let ImageMaxWidth : CGFloat = 200
    func configSNS(){
        configWeibo()
        configQQ()
        configWeChat()
    }
    
    func configWeChat(){
        WXApi.registerApp(Platform.wechatAppID)
    }
    
    func configWeibo(){
        WeiboSDK.enableDebugMode(true)
        WeiboSDK.registerApp(Constants.weiboAppID)
        
        
    }
    
    func configQQ(){
        tencentOAuth = TencentOAuth.init(appId: Constants.qqAppID, andDelegate: nil)
    }
    
    
    var weiboToken : WeiboAccessToken? {
        get {
            if let dict = UserDefaults.standard.dictionary(forKey: "weibo.auth.response") {
                return WeiboAccessToken(dictionary: dict as [String : Any])
            }
            return nil
        }
        
        set {
            if let newDict = newValue?.dictionary() {
                UserDefaults.standard.setValue(newDict, forKey: "weibo.auth.response")
            }
        }
    }
    
    func shareReferralCampagin(_ method: ShareMethod, title: String, sharePath: String, shareImageURL: URL? = nil, referralUserKey: String, displayName: String) {
        
        var path = "http://mymm.com";
        if let url = EntityURLFactory.deepShareInvitationURL(
            sharePath,
            referrerUserKey: referralUserKey,
            params: self.parseParams(method)
            ) {
            path = url.absoluteString
        }
        
        var dict: [String: Any] = [:]
        
        dict[key_title] = title
        dict[key_article_url] = path
        dict[key_object_id] = "referral_webpage_01"
        dict[key_description] = String.localize("LB_SNS_REFERRAL_H5_PAGE_TITLE").replacingOccurrences(of: "{0}", with: displayName)
        
        if let imageUrl = shareImageURL {
            
            KingfisherManager.shared.retrieveImage(with: imageUrl, options: nil, progressBlock: nil, completionHandler: { (image, error, cacheType, imageURL) in
                if let imageDownloaded = image {
                    dict[self.key_article_thumb] = imageDownloaded
                    self.shareObjectByMethod(dict, method: method)
                }else {
                    self.shareObjectByMethod(dict, method: method)
                }
            })
            
        }else{
            dict[key_article_thumb] = UIImage(named: "share_thumbnail")
            
            shareObjectByMethod(dict, method: method)
        }
        

    }

    func inviteFriend(_ title: String, description: String, url: String, image: UIImage?, method : ShareMethod){
        var dict: [String: Any] = [:]
        dict[key_title] = title
        dict[key_article_url] = url
        if let thumbnail = image {
            dict[key_article_thumb] = thumbnail
        }
        dict[key_description] = description
        switch method {
        case .sms:
            dict[key_title] = String.localize("LB_CA_NATURAL_REF_SNS_MSG") + url
            shareObjectByMethod(dict, method: method)
            break
        default:
            ShareManager.sharedManager.shareObjectByMethod(dict, method: method)
        }
    }

    
    func shareUser(_ user: User, method: ShareMethod) {
        var dict: [String: Any] = [:]
        dict[key_title] = "\(String.localize("LB_SHARE_USER").replacingOccurrences(of: "{0}", with: user.displayName))"
        dict[key_article_url] = EntityURLFactory.deepShareUserURL(user.userName, params: self.parseParams(method)).absoluteString
        dict[key_description] = String.localize("LB_CA_SNS_DETAIL")
        switch method {
        case .sms:
            dict[key_title] = "\(String.localize("LB_SHARE_USER").replacingOccurrences(of: "{0}", with: user.displayName))" + "\n" + (EntityURLFactory.deepShareUserURL(user.userName, params: self.parseParams(method)).absoluteString)
            shareObjectByMethod(dict, method: method)
            break
        default:
            if user.profileImage.length > 0 {
                KingfisherManager.shared.retrieveImage(with: ImageURLFactory.URLSize1000(user.profileImage, category: .user), options: nil, progressBlock: nil, completionHandler: { (image, error, cacheType, imageURL) in
                    if let imageDownloaded = image {
                        dict[self.key_article_thumb] = imageDownloaded
                        ShareManager.sharedManager.shareObjectByMethod(dict, method: method)
                    }
                })
            }else {
                dict[key_article_thumb] = UIImage(named: "default_profile_icon")
                ShareManager.sharedManager.shareObjectByMethod(dict, method: method)
            }
            
            break
        }
    }
    
    func shareMerchant(_ merchant: Merchant, method: ShareMethod) {
        var dict: [String: Any] = [:]
        var name = merchant.merchantName
        if merchant.merchantDisplayName.length > 0 {
            name = merchant.merchantDisplayName
        }
        dict[key_title] = "\(String.localize("LB_SHARE_MERCHANT").replacingOccurrences(of: "{0}", with: name))"
        dict[key_description] = merchant.merchantDesc
        dict[key_article_url] = EntityURLFactory.deepShareMerchantURL(String(merchant.merchantSubdomain), params: self.parseParams(method)).absoluteString
        
        switch method {
        case .sms:
            var content = "\(String.localize("LB_SHARE_MERCHANT").replacingOccurrences(of: "{0}", with: name))\(merchant.merchantDesc)" + "\n"
            content +=  EntityURLFactory.deepShareMerchantURL(merchant.merchantSubdomain, params: self.parseParams(method)).absoluteString
            dict[key_title] = content
            shareObjectByMethod(dict, method: method)
            break
        default:
            KingfisherManager.shared.retrieveImage(with: ImageURLFactory.URLSize1000(merchant.headerLogoImage, category: ImageCategory.merchant), options: nil, progressBlock: nil, completionHandler: { (image, error, cacheType, imageURL) in
                if var imageDownloaded = image {
                    imageDownloaded = imageDownloaded.fillBackgroundWithColor(UIColor.white)
                    dict[self.key_article_thumb] = imageDownloaded
                    ShareManager.sharedManager.shareObjectByMethod(dict, method: method)
                }
            })
            break
        }
        
    }
    
    func parseParams(_ method: ShareMethod) -> String {
        var type = ""
        switch method {
        case .sms:
            type = "?cs=sms&cm=message"
        case .weiboWall:
            type = "?cs=weibo&cm=wall"
        case .qqZone:
            type = "?cs=qq&cm=qzone"
        case .qqMessage:
            type = "?cs=qq&cm=message"
        case .weChatMoment:
            type = "?cs=wechat&cm=moment"
        case .weChatMessage:
            type = "?cs=wechat&cm=message"
            
        default:
            break
        }
        let result = String(format: "%@&ca=u:%@&mw=%d", type, Context.getUserKey(), Constants.MagicWindow.enable ? 1 : 0)
        return result
    }

    //MM-32812 Remove because of useless
    /*
    func shareBrand(_ brand: Brand, method: ShareMethod) {
    var dict: [String: Any] = [:]
    dict[key_title] = "\(String.localize("LB_SHARE_BRAND").replacingOccurrences(of: "- {0}", with: brand.brandName)) \(EntityURLFactory.brandURL(brand).absoluteString)"
        switch method {
        case .sms:
            shareObjectByMethod(dict, method: method)
            break
        default:
            let shareView = ShareView(frame:UIScreen.main.bounds)
            shareView.showShareBrand(brand, method: method, dictData: dict)
            break
        }
    }*/
    
    func shareBrand(_ brand: Brand, method: ShareMethod) {
        var dict: [String: AnyObject] = [:]
        let name = brand.brandName
        dict[key_title] = "\(String.localize("LB_SHARE_BRAND").replacingOccurrences(of: "{0}", with: name))" as AnyObject
        dict[key_description] = brand.brandDesc as AnyObject
        dict[key_article_url] = EntityURLFactory.deepShareBrandURL(brandSubdomain: String(brand.brandSubdomain), params: self.parseParams(method)).absoluteString as AnyObject
        
        switch method {
        case .sms:
            var content = "\(String.localize("LB_SHARE_BRAND").replacingOccurrences(of: "{0}", with: name))\(brand.brandDesc)" + "\n"
            content +=  EntityURLFactory.deepShareBrandURL(brandSubdomain: brand.brandSubdomain, params: self.parseParams(method)).absoluteString ?? ""
            dict[key_title] = content as AnyObject
            shareObjectByMethod(dict, method: method)
            break
        default:
            KingfisherManager.shared.retrieveImage(with: ImageURLFactory.URLSize1000(brand.headerLogoImage, category: ImageCategory.brand), options: nil, progressBlock: nil) { (image, error, cacheType, imageURL) in
                if var imageDownloaded = image {
                    imageDownloaded = imageDownloaded.fillBackgroundWithColor(UIColor.white)
                    dict[self.key_article_thumb] = imageDownloaded
                    ShareManager.sharedManager.shareObjectByMethod(dict, method: method)
                }
            }
            break
        }
        
    }
    
    func shareCMSContentPage(_ model: CMSPageModel, method: ShareMethod) {
        var dict: [String: Any] = [:]
        dict[key_title] = model.title
        
        switch method {
        case .qqMessage, .weChatMessage:
            dict[key_description] = String.localize("LB_CA_SNS_DETAIL")
        default:
            dict[key_description] = ""
        }
        
        dict[key_article_url] = model.link
        switch method {
        case .sms:
            dict[key_title] = "\(model.title)" + "\n" + model.link
            shareObjectByMethod(dict, method: method)
            break
        default:
            if model.coverImage.length > 0 {
                KingfisherManager.shared.retrieveImage(with: ImageURLFactory.URLSize1000(model.coverImage, category: .contentPageImages), options: nil, progressBlock: nil, completionHandler: { (image, error, cacheType, imageURL) in
                    if let imageDownloaded = image {
                        dict[self.key_article_thumb] = imageDownloaded
                        ShareManager.sharedManager.shareObjectByMethod(dict, method: method)
                    }
                })
            }else {
                dict[key_article_thumb] = UIImage(named: "default_cover")
                ShareManager.sharedManager.shareObjectByMethod(dict, method: method)
            }
            break
        }
    }
    
    func shareContentPage(_ magazineCover: MagazineCover, method: ShareMethod) {
        var dict: [String: Any] = [:]
        dict[key_title] = magazineCover.contentPageName
        
        switch method {
        case .qqMessage, .weChatMessage:
            dict[key_description] = String.localize("LB_CA_SNS_DETAIL")
        default:
            dict[key_description] = ""
        }
        
        dict[key_article_url] = EntityURLFactory.deepSharePageContentURL(magazineCover.contentPageKey, params: self.parseParams(method)).absoluteString
        switch method {
        case .sms:
            dict[key_title] = "\(magazineCover.contentPageName)" + "\n" + (EntityURLFactory.deepSharePageContentURL(magazineCover.contentPageKey, params: self.parseParams(method)).absoluteString)
            shareObjectByMethod(dict, method: method)
            break
        default:
            if magazineCover.coverImage.length > 0 {
                KingfisherManager.shared.retrieveImage(with: ImageURLFactory.URLSize1000(magazineCover.coverImage, category: .contentPageImages), options: nil, progressBlock: nil, completionHandler: { (image, error, cacheType, imageURL) in
                    if let imageDownloaded = image {
                        dict[self.key_article_thumb] = imageDownloaded
                        ShareManager.sharedManager.shareObjectByMethod(dict, method: method)
                    }
                })
            }else {
                dict[key_article_thumb] = UIImage(named: "default_cover")
                ShareManager.sharedManager.shareObjectByMethod(dict, method: method)
            }
            break
        }
    }
    @discardableResult
    func sharePost(_ post: Post, shareIdentity: SharePostIdentity? = nil, postImage : UIImage? = nil, methods: [ShareMethod], referrer: String?) -> Promise<Bool> {
        
        var p = Promise(value: true)
        
        for method in methods { //chain the promises
            p = p.then { _ -> Promise<Bool> in
                return self.sharePost(post, shareIdentity: shareIdentity, postImage: postImage, method: method, referrer: referrer)
            }
        }
        
        return p
    }
    
    @discardableResult
    func sharePost(_ post: Post, shareIdentity: SharePostIdentity? = nil , postImage : UIImage? = nil, method: ShareMethod, referrer: String?) -> Promise<Bool> {
        var dict: [String: Any] = [:]
        
        let identity : SharePostIdentity = shareIdentity ?? SharePostIdentity.otherUser(userName: post.user?.displayName ?? "")
        
        if case let SharePostIdentity.otherUser(userName) = identity {
            dict[key_title] = "\(String.localize("LB_SHARE_POST").replacingOccurrences(of: "{0}", with: userName))"
        }else if case let SharePostIdentity.merchant(merchantName) = identity {
            dict[key_title] = "\(String.localize("MSG_SHARE_EXTERNALLY_MERCHANT").replacingOccurrences(of: "{0}", with: merchantName))"
        }else if case SharePostIdentity.myself = identity {
            dict[key_title] = "\(String.localize("MSG_SHARE_EXTERNALLY_USER"))"
        }
        var postText = post.postText
        if method == .weiboWall {
            postText = self.getShareTextForWeibo(postText)
        }
        dict[key_description] = postText
        dict[key_article_url] = EntityURLFactory.deepSharePostURL(String(format:"%d",post.postId), params: self.parseParams(method), referrer: referrer).absoluteString
        switch method {
        case .sms:
            var title = ""
            if let string = dict[key_title] as? String {
                title = string
            }
            title = title + post.postText + "\n"
            dict[key_title] = title + (EntityURLFactory.deepSharePostURL(String(format:"%d",post.postId), params: self.parseParams(method), referrer: referrer).absoluteString)
            shareObjectByMethod(dict, method: method)
            break
        default:
            if post.postImage.length > 0 {
                
                KingfisherManager.shared.retrieveImage(with: ImageURLFactory.URLSize1000(post.postImage, category:.post), options: nil, progressBlock: nil, completionHandler: { (image, error, cacheType, imageURL) in
                    if let imageDownloaded = image {
                        dict[self.key_article_thumb] = imageDownloaded
                    }
                    
                    ShareManager.sharedManager.shareObjectByMethod(dict, method: method)
                })
            }else if let image = postImage {
                dict[self.key_article_thumb] = image
                ShareManager.sharedManager.shareObjectByMethod(dict, method: method)
            }else {
                dict[key_article_thumb] = UIImage(named: "default_cover")
                ShareManager.sharedManager.shareObjectByMethod(dict, method: method)
            }
            break
        }
        
        let promiseTuple = Promise<Bool>.pending()
        self.promisesTupleGroup[method] = promiseTuple //store the promise object to hash map
        return promiseTuple.promise
    }
    
    // MARK: - Share Different objects in app -
    
    func shareHashTag(_ hashTag: String, method: ShareMethod, referrer: String? = nil){
        
        var hashTagValue = hashTag
        
        //To remove first "#"
        if hashTagValue.hasPrefix("#") && hashTagValue.length > 1 {
            hashTagValue = String(hashTagValue.dropFirst())
        }
        
        let hashTagURL = EntityURLFactory.deepShareHashTagURL(hashTagValue, params: self.parseParams(method), referrer: referrer)
        var hashTagURLString = ""
        if let hashTagURL = hashTagURL {
            hashTagURLString = hashTagURL.absoluteString
        }
        
        var dict: [String: Any] = [:]
        dict[key_article_url] = hashTagURLString
        
        switch method {
        case .sms:
            dict[key_title] = "\(hashTag)\n \(hashTagURLString)"
            shareObjectByMethod(dict, method: method)
            break
        default:
            dict[key_title] = hashTag
            ShareManager.sharedManager.shareObjectByMethod(dict, method: method)
        }
    }
    
    func shareMasterCoupons(type: MasterCouponType = .myMMCoupon, method: ShareMethod, referrer: String? = nil){
        
        let masterCouponURL = EntityURLFactory.deepShareMasterCouponURL(type: type, referrer: referrer)
        var masterCouponURLString = ""
        if let masterCouponURL = masterCouponURL {
            masterCouponURLString = masterCouponURL.absoluteString
        }
        
        var dict: [String: Any] = [:]
        dict[key_article_url] = masterCouponURLString
        
        switch method {
        case .sms:
            dict[key_title] = "\(String.localize("LB_COUPON_MASTER_WEB"))\n \(masterCouponURLString)"
            shareObjectByMethod(dict, method: method)
            break
        default:
            dict[key_title] = String.localize("LB_COUPON_MASTER_WEB")
            dict[key_description] = String.localize("LB_CA_SNS_DETAIL")
            ShareManager.sharedManager.shareObjectByMethod(dict, method: method)
        }
    }
    
    func shareProduct(_ sku: Sku, suppliedStyle: Style, method: ShareMethod, referrer: String? = nil){
        var dict: [String: Any] = [:]
        var format = String.localize("LB_SHARE_PRODUCT")
        var des = suppliedStyle.skuDesc
        if suppliedStyle.containFlashSale() {
            if let formattedSalePrice = suppliedStyle.minFlashSale().formatPrice() {
                format = String.localize("LB_CA_NEWBIEPRICE_SHARE").replacingOccurrences(of: "{0}", with: formattedSalePrice)
                format = format.replacingOccurrences(of: "{1}", with: "{0}")
                des = String.localize("LB_CA_NEWBIEPRICE_SHARE_DESC")
            }
        }
        dict[key_title] = "\(format.replacingOccurrences(of: "{0}", with: sku.skuName))"
        dict[key_description] = des
        dict[key_article_url] = EntityURLFactory.deepShareProductURL(String(format:"%d",sku.skuId), params: self.parseParams(method), referrer: referrer).absoluteString
        switch method {
        case .sms:
            dict[key_title] = "\(format.replacingOccurrences(of: "{0}", with: sku.skuName))" + "\n" + (EntityURLFactory.deepShareProductURL(String(format:"%d",sku.skuId), params: self.parseParams(method), referrer: referrer).absoluteString)
            shareObjectByMethod(dict, method: method)
            break
        default:
            if let imageKey = suppliedStyle.findImageKeyByColorKey(sku.colorKey) {
                
                KingfisherManager.shared.retrieveImage(with: ImageURLFactory.URLSize1000(imageKey, category: ImageCategory.product), options: nil, progressBlock: nil, completionHandler: { (image, error, cacheType, imageURL) in
                    if let dimage = image {
                        dict[self.key_article_thumb] = dimage
                        ShareManager.sharedManager.shareObjectByMethod(dict, method: method)
                    }
                })
                
            }
        }
    }
    
    func shareObjectByMethod(_ object: Dictionary<String, Any>, method: ShareMethod){
		
        switch method {
        case .weChatMessage:
            shareToWeChat(object, postToWall: false)
            break
        case .weChatMoment:
            shareToWeChat(object, postToWall: true)
            break
        case .weiboWall:
            shareToWeibo(object, postToWall: true)
            break
        case .weiboMessage:
            shareToWeibo(object, postToWall: false)
            break
        case .qqMessage:
            shareToTencentQQ(object, postToWall: false)
            break
        case .qqZone:
            shareToTencentQQ(object, postToWall: true)
            break
        case .sms:
            sendSMSMessage(object)
            
            break
        default: break
            
        }
    }

    
    // MARK: WeChat Share
    private func shareToWeChat(_ object: Dictionary<String, Any>, postToWall: Bool = false){
        
        if WXApi.isWXAppInstalled(){
            let message = WXMediaMessage()
            
            message.title = object[key_title] as? String ?? ""
            message.description = object[key_description] as? String ?? ""
            
            let req = SendMessageToWXReq()
            
            if let image = object[key_contentImage] as? UIImage {
                
                let ext = WXImageObject()
                ext.imageData = UIImageJPEGRepresentation(image, 1.0)
                message.setThumbImage(image.resize(CGSize(width: ImageMaxWidth, height: ImageMaxWidth / image.size.width * image.size.height)))
                req.bText = false
                message.mediaObject = ext
            }else if let article = object[key_article_url] as? String{
                let web = WXWebpageObject()
                web.webpageUrl = article
                message.mediaObject = web
				message.description = ((object[key_description] ?? article) as! String).subStringToIndex(50)
                if let image = object[key_article_thumb] as? UIImage {
                    message.setThumbImage(image.resize(CGSize(width: ImageMaxWidth, height: ImageMaxWidth / image.size.width * image.size.height)))
                }
                req.bText = false
            }else {
                req.text = message.description.subStringToIndex(50)
                req.bText = true
            }
            
            req.message = message
            req.scene = postToWall ? Int32(WXSceneTimeline.rawValue) : Int32(WXSceneSession.rawValue)
            WXApi.send(req)
 
        }
        else{
            let topController = topViewController()
            Alert.alertWithSingleButton(topController, title: "", message: String.localize("MSI_ERR_WECHAT_INSTALL"), buttonString:String.localize("LB_OK"))
        }
    }
    
    // MARK: Weibo Share
    private func shareToWeibo(_ object: Dictionary<String, Any>, postToWall: Bool = true){
        
        if WeiboSDK.isWeiboAppInstalled(){
            
            //MM-25829 check for network disconnected
            if Reachability.shared().currentReachabilityStatus() == NotReachable {
                let topController = topViewController()
                Alert.alertWithSingleButton(topController, title: "", message: String.localize("MSG_ERR_NETWORK_FAIL"), buttonString: String.localize("LB_CA_CONFIRM"))
                return
            }
            
            let authRequest = WBAuthorizeRequest()
            //authRequest.shouldShowWebViewForAuthIfCannotSSO = true
            authRequest.redirectURI = "https://mymm.com"
            authRequest.scope = "all"
            
            let message = WBMessageObject()
            
            if let image = object[key_contentImage] as? UIImage {
                let wbImageObject = WBImageObject()
                wbImageObject.imageData = UIImageJPEGRepresentation(image, 1.0)
                message.imageObject = wbImageObject
                message.text = object[key_description] as? String ?? ""
            }else if let article_url = object[key_article_url] as? String {
                let title = object[key_title] as? String ?? ""
                let keyDescription = object[key_description] as? String ?? ""
                var text = title + "\n" + keyDescription
				
                let maxLengthOfText = WEIBO_MAX_MESSAGE_LENGTH - (9 + 1) // +1 for space in betweeen text and link

                if maxLengthOfText < text.length && maxLengthOfText > 0 {
                    text = (text as NSString).substring(to: maxLengthOfText)
                    text = String(text.dropLast(3))
                    text = text + "..."
                }
				
                message.text = text + " " + article_url

                if let thumbImage = object[key_article_thumb] as? UIImage {
                    let wbImageObject = WBImageObject()
                    wbImageObject.imageData = UIImageJPEGRepresentation(thumbImage, 1.0)
                    message.imageObject = wbImageObject
                }
                
            }
            
            if let request : WBSendMessageToWeiboRequest = WBSendMessageToWeiboRequest.request(withMessage: message, authInfo: authRequest, access_token: nil) as? WBSendMessageToWeiboRequest {
                request.userInfo = ["ShareMessageFrom": "SendMessageToWeiboViewController"]
                WeiboSDK.send(request)
            }
        }
        else{
            let topController = topViewController()
            Alert.alertWithSingleButton(topController, title: "", message: String.localize("MSI_ERR_SINAWEIBO_INSTALL"), buttonString:String.localize("LB_OK"))
            self.invokeSharingCompletion(.weiboWall, isSuccess: false)
        }
        
    }
    //MARK: Send SMS
    class func canSendText() -> Bool {
        return MFMessageComposeViewController.canSendText()
    }
    
    private func sendSMSMessage(_ object: Dictionary<String, Any>){
        
        if ShareManager.canSendText() {
            var message = object[key_title] as? String ?? ""
            
            if let articleUrl = object[key_article_url] as? String {
                message = message + " " + articleUrl
            }
            
            let messageComposeVC = MFMessageComposeViewController()
            messageComposeVC.messageComposeDelegate = self  //  Make sure to set this property to self, so that the controller can be dismissed!
            messageComposeVC.body = message
            
            let topController = topViewController()
            topController.present(messageComposeVC, animated: true, completion: nil)
        }
    }
    
    func sendSMSMessageToInviteFriend(_ object: Dictionary<String, Any>){
        
        if ShareManager.canSendText() {
            let message = object[key_title] as? String ?? ""
            let phoneNumber = object[key_phone_number] as? String ?? ""
            let messageComposeVC = MFMessageComposeViewController()
            messageComposeVC.messageComposeDelegate = self  //  Make sure to set this property to self, so that the controller can be dismissed!
            messageComposeVC.body = message
            messageComposeVC.recipients = [phoneNumber]
            
            let topController = topViewController()
            topController.present(messageComposeVC, animated: true, completion: nil)
        }
    }
    
    func topViewController() -> UIViewController{
        
        var topController = UIApplication.shared.keyWindow?.rootViewController
        if  (topController != nil){
            while let presentedViewController = topController!.presentedViewController {
                topController = presentedViewController
            }
            return topController!
        }
        return topController!
    }

    //MARK: MFMessageComposeViewControllerDelegate
    func messageComposeViewController(_ controller: MFMessageComposeViewController, didFinishWith result: MessageComposeResult) {
        controller.dismiss(animated: true, completion: nil)
    }

    // MARK: QQ Share
    private func shareToTencentQQ(_ object: Dictionary<String, Any>, postToWall: Bool = false){
        
        if QQApiInterface.isQQInstalled() {
            if let image = object[key_contentImage] as? UIImage {
                let imgData = UIImageJPEGRepresentation(image, 1.0)
				
                let title = object[key_title] as? String ?? ""
                
                var apiObject : QQApiObject!
                
                if postToWall {
                    apiObject = QQApiImageArrayForQZoneObject.objectWithimageDataArray([imgData!], title: title) as! QQApiImageArrayForQZoneObject
                    
                }else{
                    
                    apiObject = QQApiImageObject(data: imgData ?? Data(), previewImageData: imgData ?? Data(),
                                                  title: object[key_title] as? String ?? "", description: object[key_description] as? String ?? "")
                }
                
                let req = SendMessageToQQReq(content: apiObject)
                let sendResult = postToWall ? QQApiInterface.sendReq(toQZone: req) : QQApiInterface.send(req)
                Log.debug("\(sendResult.rawValue)")
                
            } else if let articleURL = object[key_article_url] as? String {
				
				var descText: String = object[key_description] as? String ?? ""
				if descText.length == 0 {
					// replace title with URL since there is a 140 characters limit on QQ, the URL could not fully shown 
					// descText = articleURL
					descText = object[key_title] as? String ?? ""
				}
				let maxLengthOfText = WEIBO_MAX_MESSAGE_LENGTH
				
				if maxLengthOfText < descText.length {
					descText = descText.subStringToIndex(maxLengthOfText)
					descText = String(descText.dropLast(3))
					descText = descText + "..."
				}
				
                var resizedThumbImage: UIImage? = nil
                
                if let thumbImage = object[key_article_thumb] as? UIImage {
                    resizedThumbImage = thumbImage.resize(CGSize(width: 200, height: 200))
                }
                
                if resizedThumbImage == nil {
                    resizedThumbImage = UIImage(named: "default_cover")
                }
                
                let data = UIImageJPEGRepresentation(resizedThumbImage!, 1.0) ?? Data()
                
                if let url = URL(string: articleURL) {
                    let apiObject = QQApiURLObject(url: url, title: (object[key_title] as? String) ?? "", description: descText, previewImageData: data, targetContentType: QQApiURLTargetTypeNews)
                    let req = SendMessageToQQReq(content: apiObject)
                    let sendResult = postToWall ? QQApiInterface.sendReq(toQZone: req) : QQApiInterface.send(req)
                    
                    Log.debug("\(sendResult.rawValue)")
                }
            }
            
            
            
        } else{
            let topController = topViewController()
            Alert.alertWithSingleButton(topController, title: "", message: String.localize("MSI_ERR_QQ_INSTALL"), buttonString:String.localize("LB_OK"))
        }
    }
    
    private func handleQQShareResults(_ result: QQApiSendResultCode){
        Log.debug(result)
        self.invokeSharingCompletion(.qqMessage, isSuccess: result == EQQAPISENDSUCESS)
    }

    func getTopViewController(_ base: UIViewController? = UIApplication.shared.keyWindow?.rootViewController) -> UIViewController? { //Cannot use topViewController function
        if let nav = base as? UINavigationController {
            return getTopViewController(nav.visibleViewController)
        }
        if let tab = base as? UITabBarController {
            if let selected = tab.selectedViewController {
                return getTopViewController(selected)
            }
        }
        if let presented = base?.presentedViewController {
            return getTopViewController(presented)
        }
        return base
    }
    
    func handleShareResult(_ method: ShareMethod, isSuccess: Bool) {
        var errorMessage = "";
        switch method {
        case .weChatMessage:
            errorMessage =  (isSuccess ? String.localize("LB_CA_SHARE_WECHAT_SUCCESS") : String.localize("LB_CA_SHARE_WECHAT_FAIL"))
            break
        case .weiboMessage:
            errorMessage =  (isSuccess ? String.localize("LB_CA_SHARE_WEIBO_SUCCESS") : String.localize("LB_CA_SHARE_WEIBO_FAIL"))
            break
        case .qqMessage:
            errorMessage =  (isSuccess ? String.localize("LB_CA_SHARE_QQ_SUCCESS") : String.localize("LB_CA_SHARE_QQ_FAIL"))
            break
        default: break
        }
        
        if let controller = self.getTopViewController() as? MmViewController {
            if isSuccess {
                controller.showSuccessPopupWithText(errorMessage)
            } else {
                controller.showErrorAlert(errorMessage)
            }
        }
    }
   
 }

extension ShareManager: WeiboSDKDelegate, QQApiInterfaceDelegate {
    // MARK: WeiboSDKDelegate
    func didReceiveWeiboRequest(_ request: WBBaseRequest!) {
        Log.debug(request)
    }
    
    func didReceiveWeiboResponse(_ response: WBBaseResponse!) {
        Log.debug(response)
        if let resp = response as? WBSendMessageToWeiboResponse {
            self.invokeSharingCompletion(.weiboWall, isSuccess: true)
            self.handleShareResult(.weiboMessage, isSuccess: resp.statusCode.rawValue == 0)
        } else if let resp = response as? WBAuthorizeResponse {
            if resp.statusCode == .success {
                self.weiboToken = WeiboAccessToken(authResponse: resp)
                NotificationCenter.default.post(name: Notification.Name(rawValue: "weibo.receivedAuthResponse"), object: nil)
            }
        }
    }
    
    // MARK: QQApiInterfaceDelegate
    func onReq(_ req: QQBaseReq!) {}
    
    func onResp(_ resp: QQBaseResp!) {
        if let sendMessageToQQResp = resp as? SendMessageToQQResp {
            self.handleShareResult(.qqMessage, isSuccess: sendMessageToQQResp.result == "0")
            self.invokeSharingCompletion(.qqMessage, isSuccess: sendMessageToQQResp.result == "0")
        }
    }
    
    func isOnlineResponse(_ response: [AnyHashable: Any]!) {}

    func getShareTextForWeibo(_ postDescription: String) -> String {
        var postText = postDescription
        do {
            let regex1 = try NSRegularExpression(pattern: "#+", options: NSRegularExpression.Options.caseInsensitive)
            let range1 = NSRange(location: 0, length: postText.count)
            postText = regex1.stringByReplacingMatches(in: postText, options: [], range: range1, withTemplate: "#")
            let regex2 = try NSRegularExpression(pattern: "# +", options: NSRegularExpression.Options.caseInsensitive)
            let range2 = NSRange(location: 0, length: postText.count)
            postText = regex2.stringByReplacingMatches(in: postText, options: [], range: range2, withTemplate: " ")
            
            let strings = postText.substringsMatches(pattern: RegexManager.ValidPattern.HashTag, exclude: RegexManager.ValidPattern.ExcludeHttp)
            var stringHasTags: [String] = []
            for matchString in strings {
                if stringHasTags.filter({ return $0 == matchString }).count == 0 {
                    stringHasTags.append(matchString)
                }
            }
            
            for string in stringHasTags {
                postText = postText.replacingOccurrences(of: string, with: ("\(string)#"))
            }
        } catch let error as NSError {
            log.error("error:\(error)")
        }
        return postText
    }
}

