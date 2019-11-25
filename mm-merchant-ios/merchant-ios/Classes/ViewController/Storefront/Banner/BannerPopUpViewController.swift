//
//  BannerPopUpViewController.swift
//  merchant-ios
//
//  Created by Sang Nguyen on 6/8/17.
//  Copyright © 2017 WWE & CO. All rights reserved.
//

import UIKit

class BannerPopUpViewController: MmViewController {

    private var contentView = UIView()
    private var bannerImageView = UIImageView()
    private var closeButton = UIButton(type: .custom)
    
    var banner: Banner?
    
    override func viewDidLoad() {
        super.viewDidLoad()
        createSubviews()
        
        initAnalyticLog()
        
        if let banner = self.banner {
            let url = ImageURLFactory.URLSize1000(banner.bannerImage, category: .banner)
            bannerImageView.mm_setImageWithURL(url, placeholderImage: UIImage(named: "holder"), contentMode: .scaleAspectFill)
        }
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        self.navigationController?.isNavigationBarHidden = true
    }
    
    func initAnalyticLog() {
        initAnalyticsViewRecord(
            viewLocation: "PopupBanner",
            viewType: "Banner"
        )
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        
        self.contentView.initAnalytics(withViewKey: analyticsViewRecord.viewKey)
        if let banner = self.banner {
            
            var positionLocation = ""
            if Context.defaultZone == .redZone {
                positionLocation = "Newsfeed-Home-RedZone"
            } else if Context.defaultZone == .blackZone {
                positionLocation = "Newsfeed-Home-BlackZone"
            }
            
            let impressionKey = AnalyticsManager.sharedManager.recordImpression(impressionRef: banner.bannerKey, impressionType: "Banner", impressionDisplayName: banner.bannerName, positionComponent: "PopupBanner", positionLocation: positionLocation, viewKey: self.analyticsViewRecord.viewKey)
            contentView.initAnalytics(withViewKey: self.analyticsViewRecord.viewKey, impressionKey: impressionKey)
        }
    }
    
    func dismissView(_ completion: (() -> Void)? = nil) {
        
        self.dismiss(animated: true) {
            completion?()
        }
    }
    
    @objc func bannerPressed() {
        
        self.dismissView {
            if let banner = self.banner, let currentViewController = ShareManager.sharedManager.getTopViewController() {
                
                self.contentView.recordAction(.Tap, sourceRef: banner.bannerName, sourceType: .PopupBanner, targetRef: banner.link, targetType: .URL)
                if banner.link.contains(Constants.MagazineCoverList) {
                    // open as magazine cover list
                    if LoginManager.isLoggedInErrorPrompt() {
                        let magazineCollectionViewController = MagazineCollectionViewController()
                        DeepLinkManager.sharedManager.getNavViewController(currentViewController)?.push(magazineCollectionViewController, animated: true)
                    }
                } else {
                    Navigator.shared.dopen(banner.link)
                }
            }
        }
    }
    
    @objc func closeButtonPressed () {
        if let banner = self.banner {
            
            var targetRef = ""
            if Context.defaultZone == .redZone {
                targetRef = "Newsfeed-Home-RedZone"
            } else if Context.defaultZone == .blackZone {
                targetRef = "Newsfeed-Home-BlackZone"
            }
            
            self.contentView.recordAction(.Tap, sourceRef: banner.bannerName, sourceType: .PopupBanner, targetRef: targetRef, targetType: .View)
        }
        
        dismissView()
    }
    
    func createSubviews() {
        self.view.backgroundColor = UIColor.clear
        self.collectionView.backgroundColor = UIColor.clear
        
        let viewDidTapGesture = UITapGestureRecognizer(target: self, action:#selector(self.closeButtonPressed))
        viewDidTapGesture.delegate = self
        self.view.addGestureRecognizer(viewDidTapGesture)
        
        let paddingLeftRight: CGFloat = 35
        let widthContentView = ScreenWidth - 2 * paddingLeftRight
        let contentViewSize = CGSize(width: widthContentView, height: widthContentView * 350 / 275 )
        
        let paddingTopBottom = (ScreenHeight - contentViewSize.height) / 2
        contentView.frame = CGRect(x: paddingLeftRight, y: paddingTopBottom, width: contentViewSize.width, height: contentViewSize.height)
        contentView.backgroundColor = UIColor.clear
        contentView.isUserInteractionEnabled = true
        self.view.addSubview(contentView)
        
        //Banner
        bannerImageView.frame = contentView.bounds
        bannerImageView.isUserInteractionEnabled = true
        self.contentView.addSubview(bannerImageView)
        let didTapBanner = UITapGestureRecognizer(target: self, action:#selector(self.bannerPressed))
        didTapBanner.delegate = self
        self.contentView.addGestureRecognizer(didTapBanner)
        
        let transparentView = UIView()
        transparentView.backgroundColor = UIColor.black
        transparentView.alpha = 0.6
        transparentView.frame = self.view.bounds
        transparentView.autoresizingMask = [.flexibleWidth, .flexibleHeight]
        self.view.insertSubview(transparentView, belowSubview: contentView)
        
        let ratio = ScreenWidth / 375
        let closeButtonWidth = 60 * ratio
        closeButton.setBackgroundImage(UIImage(named: "btn_close_light")?.withRenderingMode(.alwaysTemplate), for: .normal)
        closeButton.tintColor = UIColor.white
        closeButton.frame = CGRect(x:contentView.frame.midX - (closeButtonWidth / 2),y:contentView.frame.maxY + 0,width:closeButtonWidth,height:closeButtonWidth)
        closeButton.addTarget(self, action: #selector(self.closeButtonPressed), for: .touchUpInside)
        self.view.addSubview(closeButton)
    }
    
}
