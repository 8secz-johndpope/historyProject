//
//  WebViewCell.swift
//  merchant-ios
//
//  Created by Quang Truong Dinh on 2/7/17.
//  Copyright © 2017 WWE & CO. All rights reserved.
//

import UIKit

class WebViewCell: UICollectionViewCell, UIWebViewDelegate{
    static let CellIdentifier = "WebViewCellID"
    static let DefaultHeight: CGFloat = 500
    
    var containerMargin = UIEdgeInsets(top: 0, left: 0, bottom: 0, right: 0)
    
    private var containerView = UIView()
    private var webView = UIWebView()
    
    var data: WebViewCellData?{
        didSet{
            if let data = data, !data.isLoaded{
                loadUrl(data.url)
            }
        }
    }
    
    //var webViewDidChangeHeight: ((CGFloat, WebViewCell)->())?
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        self.backgroundColor = UIColor.primary2()
        self.clipsToBounds = true
        
        containerView.backgroundColor = UIColor.white
        addSubview(containerView)
        
        webView.delegate = self
        webView.allowsInlineMediaPlayback = true
        webView.mediaPlaybackRequiresUserAction = false
        
        containerView.addSubview(webView)
    }
    
    override func layoutSubviews() {
        super.layoutSubviews()
        containerView.frame = CGRect(x: 0, y: containerMargin.top, width: self.width, height: self.height - (containerMargin.top - containerMargin.bottom))
        webView.frame = CGRect(x: 0, y: 0, width: containerView.width, height: containerView.height)
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    func loadUrl(_ url: String){
        if let nsUrl = URL(string: url){
            var request = URLRequest(url: nsUrl)
            request.setMMAppPrivateInfo()
            webView.loadRequest(request)
        }
    }
    
    class func getHeight() -> CGFloat{
        return WebViewCell.DefaultHeight
    }
    
    func webView(_ webView: UIWebView, shouldStartLoadWith request: URLRequest, navigationType: UIWebViewNavigationType) -> Bool {
        return true
    }
    
    func webViewDidStartLoad(_ webView: UIWebView) {
        
    }
    
    func webViewDidFinishLoad(_ webView: UIWebView) {
        //data?.height = webView.scrollView.contentSize.height
        data?.isLoaded = true
        //webViewDidChangeHeight?(data?.height ?? 0, self)
    }
    
    func webView(_ webView: UIWebView, didFailLoadWithError error: Error) {
        
    }
}

class WebViewCellData{
    var height: CGFloat = WebViewCell.DefaultHeight
    var url: String = ""{
        didSet{
            isLoaded = false
        }
    }
    var isLoaded = false
    
    init() {
    }
}
