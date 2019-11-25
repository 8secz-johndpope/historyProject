//
//  AboutDetailViewController.swift
//  merchant-ios
//
//  Created by Quang Truong Dinh on 3/22/16.
//  Copyright © 2016 WWE & CO. All rights reserved.
//

import Foundation
import CFNetwork
import WebKit

class AboutDetailViewController: MmViewController, WKNavigationDelegate {
    
    var isNavigationBarHidden = false
    
    private final let WebviewMarginTop : CGFloat = 65
    
    private var titleName: String = ""
    private var htmlContainFileName: String = ""
    
    var webview : WKWebView!

	var push = true
    
	convenience init(title: String, urlGetContentPage: String, push: Bool = true){
        self.init(nibName: nil, bundle: nil)
        self.titleName = title
        self.htmlContainFileName = urlGetContentPage
		self.push = push
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        self.title = self.titleName
        
        createBackButton()
        setupSubViews()
        if(titleName == String.localize("LB_CA_TNC")){
            initAnalyticLog()
        }
        
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        
        isNavigationBarHidden = (self.navigationController?.isNavigationBarHidden)!
        self.navigationController?.setNavigationBarHidden(false, animated: animated)
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        
        self.navigationController?.setNavigationBarHidden(isNavigationBarHidden, animated: animated)
    }

    func setupSubViews() {
        
        
        let preferences = WKPreferences()
        
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
        
        let rect = CGRect(x: 0, y: WebviewMarginTop, width: view.width, height: view.height - WebviewMarginTop - tabBarHeight)
        self.webview = WKWebView(frame: rect, configuration: configuration)
        
        webview.navigationDelegate = self
        
        let request = URLRequest(url: URL(string: self.htmlContainFileName)!)
        loadURL(request)
        view.addSubview(webview)
        
    }
    
    func loadURL(_ req: URLRequest) {
        var request = req
        request.setMMAppPrivateInfo()
        webview.load(request)
    }
    
    
    //MARK: - WKWebView Delegate
    func webView(_ webView: WKWebView, didReceive challenge: URLAuthenticationChallenge, completionHandler: @escaping (URLSession.AuthChallengeDisposition, URLCredential?) -> Void) {
        let cred = URLCredential.init(trust: challenge.protectionSpace.serverTrust!)
        completionHandler(.useCredential, cred)
    }
    
    internal func webView(_ webView: WKWebView, decidePolicyFor navigationAction: WKNavigationAction, decisionHandler: @escaping (WKNavigationActionPolicy) -> Void) {
        
        if let url = navigationAction.request.url {
            if ( navigationAction.navigationType == WKNavigationType.linkActivated ) && push {
                
                Navigator.shared.dopen(url.absoluteString)
//                    let webViewController = WebViewController()
//                    webViewController.url = url
//                    webViewController.isTabBarHidden = true
//                    self.navigationController?.push(webViewController, animated: true)
                    decisionHandler(WKNavigationActionPolicy.cancel)
                    return
            } else {
                if url.absoluteString.range(of: "mailto:") != nil || url.absoluteString.range(of: "tel:") != nil  {
                    if UIApplication.shared.canOpenURL(url) {
                        UIApplication.shared.openURL(url)
                        decisionHandler(WKNavigationActionPolicy.cancel)
                        return
                    }
                }
            }
        }
        
        decisionHandler(WKNavigationActionPolicy.allow)
    }
    
    func webView(_ webView: WKWebView, didFailProvisionalNavigation navigation: WKNavigation!, withError error: Error) {
        let error = error as NSError
        if error.domain == NSURLErrorDomain {
            if error.code == NSURLErrorServerCertificateHasBadDate ||
                error.code == NSURLErrorServerCertificateUntrusted ||
                error.code == NSURLErrorServerCertificateHasUnknownRoot ||
                error.code == NSURLErrorServerCertificateNotYetValid {
                let urlHttp = self.htmlContainFileName.replacingOccurrences(of: ProtocolWeb.https, with: ProtocolWeb.http)
                loadURL(URLRequest(url: URL(string: urlHttp)!))
            }
        }
    }
    
    
    
    
    
    func webView(_ webView: UIWebView, shouldStartLoadWithRequest request: URLRequest, navigationType: UIWebViewNavigationType) -> Bool {
		
		if navigationType == UIWebViewNavigationType.linkClicked && push {
            if let url = request.url?.absoluteString {
                Navigator.shared.dopen(url)
            }
//            let webViewController = WebViewController()
//            webViewController.url = request.url!
//            webViewController.isTabBarHidden = true
//            self.navigationController?.push(webViewController, animated: true)
            
            return false
        }
		
        return true
    }
    
    
    func webView(_ webView: UIWebView, didFailLoadWithError error: NSError) {
        if (error.domain == NSURLErrorDomain) {
			if ( error.code == NSURLErrorServerCertificateHasBadDate ||
				error.code == NSURLErrorServerCertificateUntrusted         ||
				error.code == NSURLErrorServerCertificateHasUnknownRoot    ||
				error.code == NSURLErrorServerCertificateNotYetValid)
			{
				
				let urlHttp = self.htmlContainFileName.replacingOccurrences(of: ProtocolWeb.https, with: ProtocolWeb.http)
				loadURL(URLRequest(url: URL(string: urlHttp)!))
				
			}
        }
    }
    
    // MARK: Logging
    func initAnalyticLog(){
        
        initAnalyticsViewRecord(
            nil,
            authorType: nil,
            brandCode: nil,
            merchantCode: nil,
            referrerRef: nil,
            referrerType: nil,
            viewDisplayName: nil,
            viewParameters: nil,
            viewLocation: "TNC",
            viewRef: nil,
            viewType: "Signup"
        )
    }
}
