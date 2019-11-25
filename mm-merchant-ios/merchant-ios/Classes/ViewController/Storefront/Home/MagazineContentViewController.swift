//
//  MagazineContentViewController.swift
//  merchant-ios
//
//  Created by Gam Bogo on 5/18/16.
//  Copyright © 2016 WWE & CO. All rights reserved.
//

import Foundation
import ObjectMapper
import PromiseKit
import WebKit

class MagazineContentViewController: MmViewController, WKNavigationDelegate,FlyNotice {
    
    var magazineCover: MagazineCover? = nil
    var contentPageKey: String? = nil
    var _url:String? = nil

    var webView = WKWebView()
    
    var authRequest : URLRequest? = nil
    var authenticated = false
    var trustedDomains = [Constants.Path.DeepLinkDomain:true] // set up as necessary
        
    convenience init(pageKey: String){
        self.init()
        contentPageKey = pageKey
    }
    
    deinit {
        Fly.page.unbind(self)
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        if contentPageKey == nil || (contentPageKey?.isEmpty)! {
            contentPageKey = self.ssn_Arguments["pageKey"]?.string
        }
        
        self.edgesForExtendedLayout = .bottom
        
        if let magazineItem = magazineCover {
            self.title = magazineItem.contentPageName
        }
        
        self.view.backgroundColor = UIColor.primary2()
        setupNavigationBar()
        setupWebview()
        self.createBackButton()
        
        loadData()
    }
    
    override func viewDidDisappear(_ animated: Bool) {
        super.viewDidDisappear(animated)
        webView.reload() //to reload the inline video playback
    }
 
    func setupNavigationBar() {
        let rightButtonItems = [
            UIBarButtonItem(customView: shareButton),
            UIBarButtonItem(customView: heartBtn)
        ]
        self.navigationItem.rightBarButtonItems = rightButtonItems
    }

    func setupWebview() {
        let preferences = WKPreferences()
        preferences.javaScriptEnabled = true
        
        let configuration = WKWebViewConfiguration()
        configuration.preferences = preferences
        configuration.allowsInlineMediaPlayback = true
        if #available(iOS 9.0, *) {
            configuration.requiresUserActionForMediaPlayback = false
        } else {
            configuration.mediaPlaybackRequiresUserAction = false
        }
        
        // 加cookie给h5识别，表明在ios端打开该地址
        let cookieValue = URLRequest.getSetCookieJavascript()
        let controller = WKUserContentController()
        let cookieScript = WKUserScript.init(source: cookieValue, injectionTime: .atDocumentStart, forMainFrameOnly: false)
        controller.addUserScript(cookieScript)
        configuration.userContentController = controller
        
        var bounds = self.view.bounds
        bounds.sizeHeight = bounds.height
        webView = WKWebView(frame: bounds, configuration: configuration)
        webView.autoresizingMask = [UIViewAutoresizing.flexibleWidth, UIViewAutoresizing.flexibleHeight]
        webView.navigationDelegate = self
        if #available(iOS 9.0, *) {//高于 iOS 9.0
            //            webView.customUserAgent = UserDefaults.standard.string(forKey: "UserAgent")
        }
        self.view.addSubview(webView)
        
        // http://www.cnblogs.com/NSong/p/6489802.html don't adjust contentInset
        //        webView.scrollView.contentInset = UIEdgeInsetsMake(0, 0, CGFloat(50), 0)
    }
    
    //MARK: - View Interaction

    @objc func likeButtonOnTap(_ sender: ButtonNumberDot) {
        // detect guest mode
        guard (LoginManager.getLoginState() == .validUser) else {
            LoginManager.goToLogin()
            return
        }
        
        sender.isSelected = !sender.isSelected
        
        let isLike: Int =  sender.isSelected ? 1: 0
        if let magazine = self.magazineCover {
            sender.isUserInteractionEnabled = false
            actionLike(isLike, magazineCover: magazine, completion: {
                sender.isUserInteractionEnabled = true
            }, fail: {
                sender.isUserInteractionEnabled = true
                sender.isSelected = !sender.isSelected
                sender.setLikeBadgeNumber(magazine.likeCount)
                Log.debug("Error")
            })
            sender.analyticsViewKey = analyticsViewRecord.viewKey
            let sourceRef = sender.isSelected ? "Like" : "UnLike"
            sender.recordAction(.Tap, sourceRef: sourceRef, sourceType: .Button, targetRef: magazine.contentPageKey, targetType: .ContentPage)
        }
    }
    
    @objc func shareButtonOnTap(_ sender: UIButton) {
        let shareViewController = ShareViewController ()
        
        shareViewController.viewKey = self.analyticsViewRecord.viewKey
        
        shareViewController.didUserSelectedHandler = { [weak self] (data) in
            if let strongSelf = self {
                let myRole: UserRole = UserRole(userKey: Context.getUserKey())
                let targetRole: UserRole = UserRole(userKey: data.userKey)
                WebSocketManager.sharedInstance().sendMessage(
                    IMConvStartMessage(
                        userList: [myRole, targetRole],
                        senderMerchantId: myRole.merchantId
                    ),
                    checkNetwork: true,
                    viewController: strongSelf,
                    completion: { (ack) in
                        if let convKey = ack.data {
                            let viewController = UserChatViewController(convKey: convKey)
                            let magazineCoverModel = MagazineCoverModel()
                            magazineCoverModel.magazineCover = strongSelf.magazineCover
                            let chatModel = ChatModel(model: magazineCoverModel)
                            chatModel.messageContentType = .SharePage
                            viewController.forwardChatModel = chatModel
                            strongSelf.navigationController?.pushViewController(viewController, animated: true)
                        } else {
                            ErrorLogManager.sharedManager.recordNonFatalError(withException: .NullPointer)
                        }
                })
            }
        }
        shareViewController.didSelectSNSHandler = { method in
            if let magazineCover = self.magazineCover {
                ShareManager.sharedManager.shareContentPage(magazineCover, method: method)
                sender.recordAction(.Tap, sourceRef: "Share", sourceType: .Button, targetRef: magazineCover.contentPageKey, targetType: .ContentPage)
            } else {
                ErrorLogManager.sharedManager.recordNonFatalError(withException: .NullPointer)
            }
        }
        
        self.present(shareViewController, animated: false, completion: nil)
    }
    
    //摘抄自 MMWKWebController
    private func checkGotoOtherWebController(url: String) -> Bool {
        if let surl = _url, Urls.isEqualURI(surl, url, scheme:true, host:true) {
            return true
        }
        
        /// 继承特殊参数，自动验证签名
        var turl = url
        var query = QBundle()
        if let sign = self.ssn_Arguments[ROUTER_HOST_SIGN] {
            query[ROUTER_HOST_SIGN] = sign
            turl = Urls.append(url: url, key: ROUTER_HOST_SIGN, value: sign)
        }
        
        //兼容还不能完全使用open url方式打开场景
        let deepLinkDictionary = DeepLinkManager.sharedManager.getDeepLinkTypeValue(turl)
        let deepLinkType: DeepLinkManager.DeepLinkType = (deepLinkDictionary?.keys.first)!
        if deepLinkType != .URL {
            Navigator.shared.dopen(turl)
            return false
        }
        
        /// 委托导航器打开
        if Navigator.shared.open(url, params:query, inner:true) {
            return false
        } else if (!Navigator.shared.isValid(url: url, params: query)) {//不再加载
            return false
        }
        
        //无法Push到新的页面打开的话，就直接打开好了
        guard let nav = self.navigationController else { return true }
        
        query[LOAD_URL_KEY] = QValue(url)
        
        //新的页面打开，体验更好
        let webv = MMWKWebController()
        webv._node = Navigator.shared.getWebRouterNode(url: url, query:query, webController:"MMWKWebController")
        webv.ssn_Arguments = query
        webv.onInit(params: query, ext: nil)
        nav.pushViewController(webv, animated: true)
        
        return false
    }
    
    //MARK: - WKWebViewDelegate
    func webView(_ webView: WKWebView, didReceive challenge: URLAuthenticationChallenge, completionHandler: @escaping (URLSession.AuthChallengeDisposition, URLCredential?) -> Void) {
        let cred = URLCredential.init(trust: challenge.protectionSpace.serverTrust!)
        completionHandler(.useCredential, cred)
    }
    
    internal func webView(_ webView: WKWebView, decidePolicyFor navigationAction: WKNavigationAction, decisionHandler: @escaping (WKNavigationActionPolicy) -> Void) {
        var policy = WKNavigationActionPolicy.allow
        if let url = navigationAction.request.url {
            if navigationAction.navigationType == WKNavigationType.linkActivated  {
                if checkGotoOtherWebController(url: url.absoluteString) {
                    policy = WKNavigationActionPolicy.allow
                } else {
                    policy = WKNavigationActionPolicy.cancel
                }
            }
        }
        decisionHandler(policy)
    }
    
    func webView(_ webView: WKWebView, didFinish navigation: WKNavigation!) {
        if self.title == nil && webView.title != nil {
            self.title = webView.title
        }
    }
    
    func webView(_ webView: WKWebView, didFail navigation: WKNavigation!, withError error: Error) {
        webView.isHidden = true
        ContentNotFoundView.showContentNotFoundView(webView.frame, onView: self.view)
    }
    
    func webView(_ webView: WKWebView, didFailProvisionalNavigation navigation: WKNavigation!, withError error: Error) {
        webView.isHidden = true
        ContentNotFoundView.showContentNotFoundView(webView.frame, onView: self.view)
    }
    func webView(_ webView: WKWebView, didStartProvisionalNavigation navigation: WKNavigation!) {
    }
    
    //MARK: - Webview Delegate
    func webViewDidStartLoad(_ webView: UIWebView) {
    }
    
    func webViewDidFinishLoad(_ webView: UIWebView) {
        guard let request = webView.request else {return}
        guard let resp1 = URLCache.shared.cachedResponse(for: request) else {return}
        guard let resp2 = resp1.response as? HTTPURLResponse else {return}
        let statusCode = resp2.statusCode
        
        if statusCode != 200 {
            Log.debug("statusCode != 200 : \(statusCode)")
            
            // When error show content not found HTML page
            webView.isHidden = true
            
            ContentNotFoundView.showContentNotFoundView(webView.frame, onView: self.view)
        }
    }
    
    func webView(_ webView: UIWebView, didFailLoadWithError error: NSError) {
        webView.isHidden = true
        
        ContentNotFoundView.showContentNotFoundView(webView.frame, onView: self.view)
    }
    
    func webView(_ webView: UIWebView, shouldStartLoadWithRequest request: URLRequest, navigationType: UIWebViewNavigationType) -> Bool {
        if !authenticated {
            authRequest = request
            let urlConnection: NSURLConnection = NSURLConnection(request: request, delegate: self)!
            urlConnection.start()
            return false
        }
        return true
    }
    
    func connection(_ connection: NSURLConnection, willSendRequestForAuthenticationChallenge challenge: URLAuthenticationChallenge) {
        if challenge.protectionSpace.authenticationMethod == NSURLAuthenticationMethodServerTrust {
            let challengeHost = challenge.protectionSpace.host
            if let _ = trustedDomains[challengeHost] {
                challenge.sender!.use(URLCredential(trust: challenge.protectionSpace.serverTrust!), for: challenge)
            }
        }
        challenge.sender!.continueWithoutCredential(for: challenge)
    }
    
    func connection(_ connection: NSURLConnection, didReceiveResponse response: URLResponse) {
        authenticated = true
        connection.cancel()
        authRequest?.setMMAppPrivateInfo()
        webView.load(authRequest!)
    }
    
    //MARK- get  liked content page list
    func loadViewData() {
        if let magazineItem = magazineCover {
            self.title = magazineItem.contentPageName
        }
        
        if let magazine = self.magazineCover {
            if let pageKey = self.contentPageKey, pageKey.isEmpty {
                self.contentPageKey = magazine.contentPageKey
            } else if self.contentPageKey == nil {
                self.contentPageKey = magazine.contentPageKey
            }
        }
        
        if let pageKey = self.contentPageKey {
            Fly.page.bind(pageKey, notice: self) //绑定数据状态变化
        }
    }
    
    func on_data_update(dataId: String, model: FlyModel?, isDeleted: Bool) {
        //同一个数据,非单页的不要有喜欢
        guard let pageLike = model as? Fly.PageHotData, let magazine = self.magazineCover else { return  }
        
        let upLikeCount = magazine.isLike != pageLike.isLike
        magazine.isLike = pageLike.isLike
        if upLikeCount {
            magazine.likeCount = magazine.likeCount + (pageLike.isLike ? 1 : -1)
            heartBtn.isSelected = pageLike.isLike
        }
        heartBtn.setLikeBadgeNumber(magazine.likeCount)
    }
    
    func loadData() {
        if let magazine = self.magazineCover  {
            if !magazine.contentPageKey.isEmpty {
                loadViewData()
            }
        }
        
        if let key = self.contentPageKey { //init by passing the key only
            MagazineService.viewContentPage(key, completion: { [weak self] (response) in
                if let strongSelf = self {
                    if response.result.isSuccess && response.response?.statusCode == 200 {
                        strongSelf.magazineCover = Mapper<MagazineCover>().map(JSONObject: response.result.value)
                        strongSelf.loadViewData()
                        if let link = strongSelf.magazineCover?.link {
                            strongSelf.verifyAndLoadUrl(link)
                        } else {
                            ErrorLogManager.sharedManager.recordNonFatalError(withException: .NullPointer, parameters: ["MagazineCoverResponse": "\(String(describing: response.result.value))"])
                        }
                        if let magazine = strongSelf.magazineCover {
                            strongSelf.initAnalyticLog(withMagazine: magazine)
                        }
                    } else {
                        strongSelf.webView.isHidden = true
                        ContentNotFoundView.showContentNotFoundView(strongSelf.webView.frame, onView: strongSelf.view)
                    }
                }
            })
        } else if let link = magazineCover?.link {
            verifyAndLoadUrl(link)
        }
    }
    
    //此页面存在非Navigator的open方式，需要防止非法url，故统一在此处理
    fileprivate func verifyAndLoadUrl(_ link:String) {
        
        var b = self.ssn_Arguments
        let q = Urls.query(url: link)
        //将验证参数加入
        if let s = q[ROUTER_HOST_SIGN] {
            if !b.keys.contains(ROUTER_HOST_SIGN) {
                b[ROUTER_HOST_SIGN] = s
                self.ssn_Arguments = b
            }
        }
        
        if !Navigator.shared.isValid(url: link, params:self.ssn_Arguments) {
            return
        }
        if let url = URL(string: link) {
            
            if _url == nil {
                _url = link
            }
            
            authRequest = URLRequest(url: url)
            authRequest?.setMMAppPrivateInfo()
            if let authRequest = authRequest {
                webView.load(authRequest)
            }
        }
    }
    
    /**
     action like on content page
     
     - parameter isLike:     1: 0
     - parameter contentKey: contetn page key
     
     - returns: Promize
     */
    @discardableResult
    func actionLike(_ isLike: Int, magazineCover: MagazineCover, completion: (()->())?,  fail: (()->())? ) -> Promise<Any>{
        
        return Promise{ fulfill, reject in
            
            MagazineService.actionLikeMagazine(isLike, contentPageKey: magazineCover.contentPageKey, completion: { (response) in
                if response.result.isSuccess{
                    if response.response?.statusCode == 200 {
                        
                        if let result = response.result.value as? [String: Any], (result["Success"] as? Int) == 1{
                            Log.debug("likePostCall OK" + magazineCover.contentPageKey)
                            
                            let pageLike = Fly.PageHotData()
                            pageLike.pageKey = magazineCover.contentPageKey
                            pageLike.isLike = isLike == 1
                            Fly.page.save(pageLike)
                            
                            //以下代码将废弃，使用Fly.page管理即可
                            if isLike == 1 {
                                CacheManager.sharedManager.addLikedMagazieCover(magazineCover)
                            } else {
                                CacheManager.sharedManager.removeLikedMagazieCover(magazineCover)
                            }
                            
                            fulfill(magazineCover.contentPageKey)
                            if let callback = completion {
                                callback()
                            }
                        }
                    } else {
                        var statusCode = 0
                        if let code = response.response?.statusCode {
                            statusCode = code
                        }
                        let error = NSError(domain: "", code: statusCode, userInfo: nil)
                        reject(error)
                        
                        if let callback = fail {
                            callback()
                        }
                    }
                } else {
                    reject(response.result.error!)
                    
                    if let callback = fail {
                        callback()
                    }
                }
            })
        }
    }

    //MARK: - Analytics Log
    private func initAnalyticLog(withMagazine magazineCover: MagazineCover) {
        initAnalyticsViewRecord(
            viewDisplayName: magazineCover.contentPageName,
            viewParameters: magazineCover.contentPageKey,
            viewLocation: "ContentPage",
            viewRef: magazineCover.link,
            viewType: "Web"
        )
    }
    
    // MARK: -  lazyload
    
    lazy var shareButton: UIButton = {
        let ShareButtonHeight = CGFloat(44)
        let ShareButtonWidth = CGFloat(44)
        let shareButton = UIButton(type: .custom)
        shareButton.setImage(UIImage(named: "share_black"), for: UIControlState())
        shareButton.frame = CGRect(x: 0, y: 0, width: ShareButtonWidth, height: ShareButtonHeight)
        shareButton.addTarget(self, action: #selector(shareButtonOnTap), for: .touchUpInside)
        shareButton.contentEdgeInsets = UIEdgeInsets(top: (ShareButtonHeight - 30)/2, left: (ShareButtonWidth - 30)/2, bottom: (ShareButtonHeight - 25)/2, right: (ShareButtonWidth - 30)/2)
        return shareButton
    }()
    
    lazy var heartBtn: ButtonNumberDot = {
        let ShareButtonHeight = CGFloat(44)
        let ShareButtonWidth = CGFloat(44)
        let btn = ButtonNumberDot(type: .custom)
        btn.setImage(UIImage(named: "icon_heart_filled"), for: .selected)
        btn.setImage(UIImage(named: "icon_heart_stroke"), for: .normal)
        btn.frame = CGRect(x: 0, y: 0, width: ShareButtonWidth, height: ShareButtonHeight)
        btn.addTarget(self, action: #selector(MagazineContentViewController.likeButtonOnTap), for: .touchUpInside)
        return btn
    }()
}

