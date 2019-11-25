//
//  MyCouponViewController.swift
//  merchant-ios
//
//  Created by Phan Manh Hung on 2/8/17.
//  Copyright © 2017 WWE & CO. All rights reserved.
//

import Foundation

class MyCouponViewController: MMPageViewController {

    override func viewDidLoad() {
        super.viewDidLoad()

        let height = self.view.frame.maxY - (SEGMENT_Y + SEGMENT_HEIGHT) - tabBarHeight
        
        let merchantCoupon = CouponViewController()
        merchantCoupon.viewControllerType = .merchantCouponViewController
        merchantCoupon.viewHeight = height
        merchantCoupon.buttonTapHandler = { [weak self] coupon in
            if let _ = self {
                if let merchantId = coupon.merchantId {
                    CacheManager.sharedManager.merchantById(merchantId, completion: { (merchant) in
                        if let merchant = merchant {

                            DispatchQueue.main.async(execute: {
                                Navigator.shared.dopen(Navigator.mymm.website_merchant_merchantId + "\(merchant.merchantId)")
                            })
                        }
                    })
                }
            }
        }

        let mmCoupon = CouponViewController()
        mmCoupon.viewControllerType = .mmCouponViewController
        mmCoupon.viewHeight = height
        
        viewControllers = [mmCoupon, merchantCoupon]
        segmentedTitles = [String.localize("LB_CA_PROFILE_MY_COUPON_MYMM"), String.localize("LB_CA_PROFILE_MY_COUPON_MERC")]

        
        backgroundColor = UIColor.primary2()
        
        self.title = String.localize("LB_CA_PROFILE_MY_COUPON")
        createBackButton(.grayColor)
        createRightButton(String.localize("LB_CA_COUPON_MASTER_CLAIM_LIST_TO"), action: #selector(rightButtonTapped))
        
        //record view
        initAnalyticLog()
    }
    
    override func viewWillAppear(_ animated: Bool) {
//        hasRedDot = [CacheManager.sharedManager.hasNewClaimedMmCoupon, CacheManager.sharedManager.hasNewClaimedMerchantCoupon]
        reloadSegmentState()

        super.viewWillAppear(animated)
    }
    
    @objc func rightButtonTapped() {
//        let masterCouponsVC = MasterCouponsContainerViewController()
//        masterCouponsVC.navigateToTabIndex = currentPageIndex
//
//        navigationController?.push(masterCouponsVC, animated: true)
    }

    override func segmentButtonClicked(_ sender: UIButton!) {
        super.segmentButtonClicked(sender)
        
        // record action
        sender.initAnalytics(withViewKey: analyticsViewRecord.viewKey)
        var targetRef = ""
        
        if sender.tag == 0 {
            //mm coupon
            targetRef = "MyCouponList-MyMMCoupon"
        }
        else {
            //merchant coupon
            targetRef = "MyCouponList-MerchantCoupon"
        }
        
        sender.recordAction(.Tap, sourceRef: "MyCouponList", sourceType: .Button, targetRef: targetRef, targetType: .View)
    }
    
    override func shouldHaveCollectionView() -> Bool {
        return false
    }
    
    func initAnalyticLog(){
        initAnalyticsViewRecord(viewLocation: "MyCouponList", viewType: "Coupon")
    }
}
