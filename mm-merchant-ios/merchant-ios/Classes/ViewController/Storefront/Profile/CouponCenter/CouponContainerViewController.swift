//
//  CouponContainerViewController.swift
//  storefront-ios
//
//  Created by Kam on 18/5/2018.
//  Copyright © 2018 WWE & CO. All rights reserved.
//

import UIKit

class CouponContainerViewController: NavPageViewController {

    var merchantId: Int?
    var navigateIndex: Int?
    
    let deeplinks = ["myCoupon", "rr", "re", "rn", "rm"]
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        if let merchantId = self.ssn_Arguments["merchantid"]?.int {
            self.merchantId = merchantId
        } else if let merchantId = self.ssn_Arguments["merchantId"]?.int {
            self.merchantId = merchantId
        }
        
        if self.ssn_uri.length > 0 {
            for uri in self.deeplinks where self.ssn_uri.contains(uri) {
                self.navigateIndex = 1
                break
            }
        }
        
        createBackButton()
        
        self.options = SegmentedControlOptions(
            enableSegmentControl: true,
            segmentedTitles: [String.localize("LB_CA_COUPON_CLAIM_CENTER"), String.localize("LB_CA_COUPON_CLAIMED")],
            selectedTitleColors: [UIColor.secondary15(), UIColor.secondary15()],
            deSelectedTitleColor: UIColor.secondary16(),
            indicatorColors: [UIColor.primary1(), UIColor.primary1()],
            hasRedDot: [false, CacheManager.sharedManager.hasNewClaimedCoupon],
            navigateToTabIndex: self.navigateIndex ?? 0,
            segmentButtonWidth: 80
        )
        
        let centerVC = CouponCenterViewController()
        if let merchantId = self.merchantId {
            centerVC.merchantId = merchantId
        }
        centerVC.reddotUpdateHandler = {
            self.segmentedControl?.updateReddot(hasReddot: [false, CacheManager.sharedManager.hasNewClaimedCoupon])
        }
        
        let claimedVC = CouponClaimedViewController()
        claimedVC.reddotUpdateHandler = {
            self.segmentedControl?.updateReddot(hasReddot: [false, CacheManager.sharedManager.hasNewClaimedCoupon])
        }
        
        self.viewControllers = [centerVC, claimedVC]
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }

}
