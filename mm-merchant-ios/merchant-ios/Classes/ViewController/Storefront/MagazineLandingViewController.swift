//
//  MagazineLandingViewController.swift
//  merchant-ios
//
//  Created by Tony Fung on 6/6/2017.
//  Copyright © 2017年 WWE & CO. All rights reserved.
//

import UIKit
import WebKit
import ObjectMapper

class MagazineLandingViewController: MmViewController, WKNavigationDelegate {

    var webView = WKWebView()
    var authRequest : URLRequest? = nil
    var authenticated = false
    var trustedDomains = [Constants.Path.DeepLinkDomain:true] // set up as necessary
    var topOffsetY : CGFloat = 0
    override func viewDidLoad() {
        super.viewDidLoad()
        self.title = String.localize("LB_CA_MYMM_MAGAZINE")
        
        self.setupNavigationBarButton()
        setupWebview()
        loadData()
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
    }


    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
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
        
        let statusBarHeight = UIApplication.shared.statusBarFrame.size.height
        webView = WKWebView(frame: CGRect(x: 0, y: 0, width: self.view.bounds.width, height: self.view.bounds.height - tabBarHeight - topOffsetY - statusBarHeight), configuration: configuration)
        webView.navigationDelegate = self
        self.view.addSubview(webView)
        //webView.scrollView.contentInset = UIEdgeInsets(top: 0, left: 0, bottom: CGFloat(50), right: 0)
        
        
    }

    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
    }
    
    func loadData() {
        self.showLoading()
        MagazineService.viewContentPage(Constants.MagazineLandingKey, completion: { [weak self] (response) in
            if let strongSelf = self {
                strongSelf.stopLoading()
                if response.result.isSuccess && response.response?.statusCode == 200 , let magazine = Mapper<MagazineCover>().map(JSONObject: response.result.value), let url = URL(string: magazine.link) {
                    var request = URLRequest(url: url)
                    strongSelf.authRequest = request
                    request.setMMAppPrivateInfo()
                    strongSelf.webView.load(request)
                    strongSelf.initAnalyticLog(magazine)
                } else {
                    strongSelf.webView.isHidden = true
                    ContentNotFoundView.showContentNotFoundView(strongSelf.webView.frame, onView: strongSelf.view)
                    
                }
            }
        })
    }

    
    override func scrollToTop() {
        
        let js = "clearInterval(scrollInterval); var scrollStep = -window.scrollY / (500 / 30),  scrollInterval = setInterval(function(){  if ( window.scrollY != 0 ) {     window.scrollBy( 0, scrollStep );  }    else clearInterval(scrollInterval);    },30);  "
        webView.evaluateJavaScript(js) { (result, error) in
            
            
        }
    }
    
    func initAnalyticLog(_ magazine: MagazineCover){
        initAnalyticsViewRecord(
            nil,
            authorType: nil,
            brandCode: nil,
            merchantCode: nil,
            referrerRef: nil,
            referrerType: nil,
            viewDisplayName: magazine.contentPageName,
            viewParameters: magazine.contentPageKey,
            viewLocation: "ContentPage",
            viewRef: magazine.link ,
            viewType: "Web"
        )
    }
    
    //MARK: - WKWebViewDelegate
    func webView(_ webView: WKWebView, didReceive challenge: URLAuthenticationChallenge, completionHandler: @escaping (URLSession.AuthChallengeDisposition, URLCredential?) -> Void) {
        var cred: URLCredential?
        if let serverTrust = challenge.protectionSpace.serverTrust {
            cred = URLCredential.init(trust: serverTrust)
        }
        completionHandler(.useCredential, cred)
    }
    
    internal func webView(_ webView: WKWebView, decidePolicyFor navigationAction: WKNavigationAction, decisionHandler: @escaping (WKNavigationActionPolicy) -> Void) {
        
        var policy = WKNavigationActionPolicy.allow
        if let url = navigationAction.request.url {
            if navigationAction.navigationType == WKNavigationType.linkActivated  {
                let deepLinkDictionary = DeepLinkManager.sharedManager.getDeepLinkTypeValue(url.absoluteString)
                let deepLinkType: DeepLinkManager.DeepLinkType = (deepLinkDictionary?.keys.first)!
                if deepLinkType != .URL {
                    Navigator.shared.dopen(url.absoluteString)
                    policy = WKNavigationActionPolicy.cancel
                }
            }
            
        }
        decisionHandler(policy)
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
    

    private var searchButton = UIButton()
    
    func setupNavigationBarButton() {
        let ButtonHeight = CGFloat(25)
        let ButtonWidth = CGFloat(30)
        
        searchButton.frame = CGRect(x: 0, y: 0, width: ButtonWidth, height: ButtonHeight)
        searchButton.setImage(UIImage(named: "search_grey"), for: UIControlState())
        searchButton.addTarget(self, action: #selector(MagazineLandingViewController.searchIconClicked), for: UIControlEvents.touchUpInside)
        let leftBarButton = UIBarButtonItem(customView: searchButton)
        
        self.navigationItem.leftBarButtonItem = leftBarButton
        
        
    }
    
    // MARK: - Views And Ac@objc tions
    @objc func searchIconClicked() {
        let searchViewController = ProductListSearchViewController()
        self.navigationController?.push(searchViewController, animated: false)
    }
    
    override func showLoading() {
        //super.showLoading()
        
        if self.loadingView == nil {
            let animator = MMRefreshAnimator(frame: CGRect(x: 0, y: 100, width: self.collectionView.frame.width, height: 80))
            animator.animateImageView()
            self.webView.addSubview(animator)
            self.loadingView = animator
        } else if let animator = self.loadingView as? MMRefreshAnimator{
            self.webView.addSubview(animator)
            animator.animateImageView()
        }
        self.webView.isUserInteractionEnabled = false
    }
    
    override func stopLoading() {
        //super.stopLoading()
        
        if let animator = self.loadingView as? MMRefreshAnimator {
            animator.stopAnimateImageView()
            animator.removeFromSuperview()
        }
        self.webView.isUserInteractionEnabled = true
    }

    
}
