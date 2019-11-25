//
//  MmSolutionViewController.swift
//  merchant-ios
//
//  Created by Kam on 22/12/2016.
//  Copyright © 2016 WWE & CO. All rights reserved.
//

import UIKit

class MmSolutionViewController: MmViewController {
    @IBOutlet weak var webView: UIWebView!
    @IBOutlet weak var lblTitle: UILabel!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        lblTitle.text = String.localize("LB_NETWORK_SOLUTION")

        // Do any additional setup after loading the view.
        let url = Bundle.main.url(forResource: "SolutionPage/index", withExtension:"html")
        var request = URLRequest(url: url!)
        webView.allowsInlineMediaPlayback = true
        webView.mediaPlaybackRequiresUserAction = false
        request.setMMAppPrivateInfo()
        webView.loadRequest(request)
        
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    @IBAction func dismiss(_ sender: Any) {
        self.dismiss(animated: true, completion: nil)
    }
    
    override func shouldHaveCollectionView() -> Bool {
        return false
    }
}


extension MmSolutionViewController: UIWebViewDelegate {
    
    func webView(_ webView: UIWebView, shouldStartLoadWith request: URLRequest, navigationType: UIWebViewNavigationType) -> Bool {
        if let urlString = request.url?.absoluteString {
            let deepLinkDictionary = DeepLinkManager.sharedManager.getDeepLinkTypeValue(urlString)
            let deepLinkType: DeepLinkManager.DeepLinkType = (deepLinkDictionary?.keys.first)!
            if deepLinkType != .URL {
                Navigator.shared.dopen(urlString)
                return false
            }
        }
        return true
    }
}
