//
//  SizeCommentViewController.swift
//  merchant-ios
//
//  Created by khanh.nguyen on 9/13/16.
//  Copyright © 2016 WWE & CO. All rights reserved.
//

import UIKit

import WebKit

class SizeCommentViewController: MmViewController, WKNavigationDelegate {

    var webView: WKWebView?
    var sizeGridImage : String?
    var sizeComment : String?
    var imageView = UIImageView()
    var scrollView = UIScrollView()
    var sizeImageHeight = CGFloat(0)
    var webViewContentHeight = CGFloat(10)

    var referenceLabel = UILabel()
    
    override func viewDidLoad() {
        super.viewDidLoad()

        
        self.title = String.localize("LB_CA_SIZEGRID")
        
        scrollView.frame = CGRect(x: 0, y: StartYPos, width: self.view.frame.sizeWidth, height: self.view.frame.sizeHeight - 64)
        self.view.addSubview(scrollView)
        
        imageView.frame = CGRect(x: 0, y: 0, width: self.view.frame.sizeWidth, height: sizeImageHeight)
        
        scrollView.addSubview(imageView)
        scrollView.addSubview(referenceLabel)
        
        referenceLabel.frame = CGRect(x: 0, y: imageView.frame.maxY, width: self.view.frame.sizeWidth, height: 30)
        referenceLabel.formatSize(14)
        referenceLabel.textAlignment = .center
        referenceLabel.text = String.localize("LB_CA_SIZE_REF")
        
        let preferences = WKPreferences()
        preferences.javaScriptEnabled = true
        
        let configuration = WKWebViewConfiguration()
        configuration.preferences = preferences
        
        // 加cookie给h5识别，表明在ios端打开该地址
        let cookieValue = URLRequest.getSetCookieJavascript()
        let controller = WKUserContentController()
        let cookieScript = WKUserScript.init(source: cookieValue, injectionTime: .atDocumentStart, forMainFrameOnly: false)
        controller.addUserScript(cookieScript)
        configuration.userContentController = controller
        
        webView = WKWebView(frame: CGRect(x: 0, y: referenceLabel.frame.maxY, width: self.view.frame.sizeWidth, height: webViewContentHeight), configuration: configuration)
        
        if let theWebView = webView {
            theWebView.scrollView.addObserver(self, forKeyPath: "contentSize", options: NSKeyValueObservingOptions.new, context: nil)
            scrollView.addSubview(theWebView)
            if let body = sizeComment  {
                var content = self.getHtmlTemplate()
                content = content.replacingOccurrences(of: "<!-- REPLACEME_BODY -->", with:body)
                theWebView.loadHTMLString(content, baseURL: nil)
                theWebView.navigationDelegate = self
            }
        }
        
        if let gridImage = sizeGridImage {
            imageView.mm_setImageWithURL(ImageURLFactory.URLSize1000(gridImage, category: .category), placeholderImage: nil, clipsToBounds: true, contentMode: UIViewContentMode.scaleAspectFill, progress: nil, optionsInfo: nil) { (image : UIImage?, error, cacheType, imageURL) in
                if let data = image {
                    let width = self.view.frame.size.width
                    self.sizeImageHeight = width * data.size.height / data.size.width
                    self.layoutSubView()
                }else {
                    self.layoutSubView()
                }
            }
        }else {
            self.layoutSubView()
        }
        
        self.createBackButton(.crossSmall)
    }
    
    override func backButtonClicked(_ button: UIButton) {
        self.crossButtonTapped()
    }
    
    deinit {
        if let theWebView = webView {
            theWebView.scrollView.removeObserver(self, forKeyPath: "contentSize")
        }
    }
    
    func layoutSubView() {
        var referenceLabelHeight = CGFloat(30)
        if sizeComment == nil || sizeComment?.length == 0 {
            referenceLabelHeight = CGFloat(0)
            referenceLabel.text = ""
        }
        self.imageView.frame = CGRect(x: 0, y: 0, width: self.view.frame.sizeWidth, height: sizeImageHeight)
        referenceLabel.frame = CGRect(x: 0, y: imageView.frame.maxY, width: self.view.frame.sizeWidth, height: referenceLabelHeight)
        
        if let webView = self.webView {
            webView.frame = CGRect(x: 0, y: self.referenceLabel.frame.maxY, width: self.view.frame.sizeWidth, height: webViewContentHeight)
        }
        
        let totalHeight =  webViewContentHeight + sizeImageHeight + referenceLabelHeight
        self.scrollView.contentSize = CGSize(width: self.view.frame.sizeWidth, height: totalHeight)
        
    }
    
    override func observeValue(forKeyPath keyPath: String?, of object: Any?, change: [NSKeyValueChangeKey : Any]?, context: UnsafeMutableRawPointer?) {
        if keyPath == "contentSize" {
            if let nsSize = change?[NSKeyValueChangeKey.newKey] as? NSValue {
                let height = nsSize.cgSizeValue.height
                webViewContentHeight = height
                self.layoutSubView()
            }
        }
    }
    
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    func getHtmlTemplate() -> String {
        let filePath = Bundle.main.path(forResource: "template", ofType: "html")
        do {
            let content = try String(contentsOfFile:filePath ?? "", encoding: String.Encoding.utf8)
            return content
        } catch _ as NSError {
            return ""
        }
    }

    func createRightBarItem() {
        let crossButton = UIButton(type: .custom)
        crossButton.setImage(UIImage(named: "icon_cross"), for: UIControlState())
        crossButton.frame = CGRect(x: self.view.frame.size.width - Constants.Value.BackButtonWidth, y: 0, width: Constants.Value.BackButtonWidth, height: Constants.Value.BackButtonHeight)
        crossButton.addTarget(self, action: #selector(SizeCommentViewController.crossButtonTapped), for: .touchUpInside)
        
        self.navigationItem.rightBarButtonItem = UIBarButtonItem(customView: crossButton)
    }
    
    @objc func crossButtonTapped() {
        self.dismiss(animated: true, completion: nil)
    }

    //MARK: WKNavigationDelegate
    internal func webView(_ webView: WKWebView, decidePolicyFor navigationAction: WKNavigationAction, decisionHandler: @escaping (WKNavigationActionPolicy) -> Void) {
        if navigationAction.navigationType == WKNavigationType.linkActivated  {
            //MM-18174 [iOS] Size Details - External link should not be clickable
            decisionHandler(WKNavigationActionPolicy.cancel)
            
            /* open comment to allow clickable in web view
            if let url = navigationAction.request.URL{
                let shared = UIApplication.shared
                if shared.canOpenURL(url){
                    decisionHandler(WKNavigationActionPolicy.Allow)
                }
                else{
                    decisionHandler(WKNavigationActionPolicy.Cancel)
                }
            }
            else{
                decisionHandler(WKNavigationActionPolicy.Cancel)
            }
             */
        }
        else{
            decisionHandler(WKNavigationActionPolicy.allow)
        }
    }
}
