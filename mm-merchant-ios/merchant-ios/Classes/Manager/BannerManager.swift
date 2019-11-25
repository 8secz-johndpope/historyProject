//
//  BannerManager.swift
//  merchant-ios
//
//  Created by Sang Nguyen on 6/8/17.
//  Copyright © 2017 WWE & CO. All rights reserved.
//

import Foundation
import PromiseKit
import ObjectMapper
import RealmSwift

class BannerManager {
    class var sharedManager: BannerManager {
        get {
            struct Singleton {
                static let instance = BannerManager()
            }
            return Singleton.instance
        }
    }
    
    private final var bannerPopupViewController:BannerPopUpViewController? = nil
    
    //This flag to check show campaign pop up when home page re-appeared
    //to avoid displaying 2 pop up at the same time
    var shouldFetchCampaignPopUpNextTime = false
    private var isFetchingPopUpBanner = false
    
    /// 登录过后弹出的产品广告页
    func showPopupBanner() {
        isFetchingPopUpBanner = true
        firstly {
            return BannerService.fetchBanners([.popUpBanner], loadFromCache: false)
        }.then { [weak self] banners -> Void in
            if let strongSelf = self {
                strongSelf.isFetchingPopUpBanner = false
                
                if let topViewController = ShareManager.sharedManager.getTopViewController(), let banner = banners.first, !Context.isShowedPopupBanner(banner.bannerKey) {
                    self?.bannerPopupViewController = BannerPopUpViewController()
                    self?.bannerPopupViewController?.banner = banner
                    let navigationController = MmNavigationController(rootViewController: self!.bannerPopupViewController!)
                    navigationController.volatileContainers = false
                    navigationController.modalPresentationStyle = .overFullScreen
                    navigationController.modalTransitionStyle = .crossDissolve
                    topViewController.present(navigationController, animated: true, completion: nil)
                    
                    Context.setShowedPopupBanner(banner.bannerKey)
                } else {
                    if strongSelf.shouldFetchCampaignPopUpNextTime {
                        strongSelf.getCampaigns()
                    }
                }
            }
        }.always { [weak self] in
            if let strongSelf = self {
                strongSelf.isFetchingPopUpBanner = false
            }
        }.catch { [weak self] (error) -> Void in
            if let strongSelf = self {
                if strongSelf.shouldFetchCampaignPopUpNextTime {
                    strongSelf.getCampaigns()
                }
            }
        }
    }
    
    /// 关闭广告位
    func closeBannerViewController() {
        if bannerPopupViewController != nil {
            bannerPopupViewController?.closeButtonPressed()
            bannerPopupViewController = nil
        }
    }
    
    func showCampaignPopup() {
        if let topViewController = ShareManager.sharedManager.getTopViewController() {
            let profilePopupViewController = ProfilePopupViewController()
            profilePopupViewController.presentViewController = topViewController
            let nvc = MmNavigationController(rootViewController: profilePopupViewController)
            nvc.modalPresentationStyle = .overFullScreen
            nvc.modalTransitionStyle = .crossDissolve
            topViewController.present(nvc, animated: false, completion: nil)
            shouldFetchCampaignPopUpNextTime = false
        }
        
    }

    
    func pushCampaignViewController() {
        if let topViewController = ShareManager.sharedManager.getTopViewController() {
            let profilePopupViewController = ProfilePopupViewController(presenttationStyle: .none)
            topViewController.navigationController?.pushViewController(profilePopupViewController, animated: true)
        }
    }
    
    @discardableResult
    func getCampaigns() -> Promise<Bool> {
        
        if isFetchingPopUpBanner {
            shouldFetchCampaignPopUpNextTime = true
            return Promise(value: false)
        }
        
        if LoginManager.getLoginState() != .validUser {
            return Promise(value: false)
        }
        
        if let isReferralEnabled = Context.isReferralPopupEnable(), !isReferralEnabled { //avoid duplicated call if referral campaign is disabled
            return Promise(value: false)
        }
        
        shouldFetchCampaignPopUpNextTime = false
        return ExclusiveService.getCampaigns().then { (campaigns) -> Promise<Bool> in
            
            for campaign in campaigns {
                if campaign.campaignKey == Constants.Campaign.CampaignReferralKey {
                    let canShowCampaign = (Date() > campaign.availableFrom && Date() < campaign.availableTo)
                    if (canShowCampaign) {
                        self.showCampaignPopup()
                    }
                    Context.setEnableReferralPopup(canShowCampaign)
                    return Promise(value: canShowCampaign)
                }
            }
            return Promise(value: false)
        }
        
    }
}
