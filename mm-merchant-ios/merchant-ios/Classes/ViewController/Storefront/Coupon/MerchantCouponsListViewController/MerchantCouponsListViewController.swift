//
//  MerchantCouponsListViewController.swift
//  merchant-ios
//
//  Created by Alan YU on 2/2/2017.
//  Copyright © 2017 WWE & CO. All rights reserved.
//

import Foundation
import PromiseKit

class MerchantCouponsListViewController: MmViewController {
    
    var tableView: UITableView!
    
    private static let MerchantCouponHeaderViewIdentifier = "MerchantCouponHeaderView"
    private static let MerchantCouponViewCellIdentifier = "MerchantCouponViewCell"
    private static let NoActiveCouponCellIdentifier = "NoActiveCouponCell"
    
    private let HeaderHeight = CGFloat(50)

    private var coupons = [Coupon]()
    private var claimedCoupons = [Coupon]()
    private var shouldShowNoCoupon = false
    private var merchantId = 0
    
    var data: Any?
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        self.title = String.localize("LB_CA_CART_COUPON_CLAIM")
        createBackButton(.grayColor)
        setupView()
        
        tableView.backgroundColor = UIColor.primary2()
        tableView.register(
            UINib(nibName: MerchantCouponsListViewController.MerchantCouponViewCellIdentifier, bundle: nil),
            forCellReuseIdentifier: MerchantCouponsListViewController.MerchantCouponViewCellIdentifier
        )
        tableView.register(
            UINib(nibName: MerchantCouponsListViewController.NoActiveCouponCellIdentifier, bundle: nil),
            forCellReuseIdentifier: MerchantCouponsListViewController.NoActiveCouponCellIdentifier
        )
        tableView.register(
            UINib(nibName: MerchantCouponsListViewController.MerchantCouponHeaderViewIdentifier, bundle: nil),
            forCellReuseIdentifier: MerchantCouponsListViewController.MerchantCouponHeaderViewIdentifier
        )

        loadCoupons()
        
        initAnalyticLog()
    }
        
    func setupView() {
        var frame = view.frame
        var navigationBarMaxY = CGFloat(0)
        if let navigationController = self.navigationController, !navigationController.isNavigationBarHidden {
            navigationBarMaxY = navigationController.navigationBar.frame.maxY
        }
        frame.origin.y = navigationBarMaxY
        frame.size.height -= navigationBarMaxY
        
        tableView = UITableView(frame: frame)
        tableView.delegate = self
        tableView.dataSource = self
        tableView.separatorStyle = .none
        view.addSubview(tableView)
    }

    override func shouldHaveCollectionView() -> Bool {
        return false
    }

    func compareCoupon() {
        for i in 0 ..< coupons.count {
            for claimedCoupon in self.claimedCoupons {
                if coupons[i].couponId == claimedCoupon.couponId {
                    claimedCoupon.isClaimed = true
                    self.coupons[i] = claimedCoupon
                    break
                }
            }
            
            if coupons[i].isSegmented == 1, let remark = CouponManager.shareManager().getCouponRemarkWith(coupons[i].segmentMerchantId, brandId: coupons[i].segmentBrandId, categoryId: coupons[i].segmentCategoryId)  {
                coupons[i].couponRemark = remark
            }
        }
    }

    func loadCoupons() {
        showLoading()
        
        if let merchant = data as? CartMerchant {
            merchantId = merchant.merchantId
        }
        else if let merchant = data as? Merchant {
            merchantId = merchant.merchantId
        }
        
        let promises = [loadCoupons(merchantId), loadClaimedCoupon(merchantId)]
        when(fulfilled: promises).then { _ -> Void in
            self.compareCoupon()
            
            }.always {
                self.shouldShowNoCoupon = true
                self.tableView.reloadData()
                self.stopLoading()
        }
    }
    
    func loadCouponsAtPage(_ pageNo: Int) {
        firstly {
            return loadCoupons(merchantId)
            }.then {  _ -> Void in
                self.compareCoupon()
                self.tableView.reloadData()
        }
    }

    func loadCoupons(_ merchantId: Int) -> Promise<Any> {
        return Promise { fulfill, _ in
            firstly {
                return CouponManager.shareManager().coupons(forMerchantId: merchantId)
                }.then { _, coupons -> Void in
                    if let coupons = coupons {
                        self.coupons = coupons.map { coupon in
                            coupon.isExpanded = false
                            return coupon
                        }
                    }
                }.always {
                    fulfill("OK")
            }
        }
    }
    
    func loadClaimedCoupon(_ merchantId: Int) -> Promise<Any>  {
        return Promise { fulfill, _ in
            firstly {
                return CouponManager.shareManager().wallet(forMerchantId: merchantId)
                }.then { _, coupons -> Void in
                    if let coupons = coupons {
                        self.claimedCoupons = coupons.map { coupon in
                            coupon.isExpanded = false
                            return coupon
                        }
                    }
                }.always {
                    fulfill("OK")
            }
        }
    }
    
    // MARK: - Analytics
    func initAnalyticLog() {
        var merchantId = ""
        var merchantName = ""
        
        if let merchant = data as? Merchant {
            merchantId = "\(merchant.merchantId)"
            merchantName = merchant.merchantName
        }
        else if let merchant = data as? CartMerchant {
            merchantId = "\(merchant.merchantId)"
            merchantName = merchant.merchantName
        }
        
        initAnalyticsViewRecord(merchantCode: merchantId, viewDisplayName: merchantName, viewLocation: "Cart-MerchantCouponClaimList", viewType: "Coupon")

    }
}

extension MerchantCouponsListViewController: UITableViewDelegate {
    func tableView(_ tableView: UITableView, heightForHeaderInSection section: Int) -> CGFloat {
        return 0
    }

    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        if coupons.isEmpty {
            return tableView.height - HeaderHeight
        }

        if indexPath.row == 0 {
            //header
            return HeaderHeight
        }
        
        let coupon = coupons[indexPath.row - 1]
        
        if coupon.isExpanded {
            let height = 30 + StringHelper.heightForText(coupon.couponRemark, width: tableView.frame.width - 60, font: UIFont.fontLightWithSize(14))

            return 110 + height
        }
        
        return 110
    }
}

extension MerchantCouponsListViewController: UITableViewDataSource {
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        if coupons.isEmpty && shouldShowNoCoupon {
            return 1
        }

        return coupons.count + 1
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        if coupons.isEmpty {
            let cell = tableView.dequeueReusableCell(withIdentifier: MerchantCouponsListViewController.NoActiveCouponCellIdentifier) as! NoActiveCouponCell
            cell.lblCouponEmpty.text = String.localize("LB_CA_CART_MERC_COUPON_EMPTY")
            
            return cell
        }
        
        if indexPath.row == 0 {
            //header
            let cell = tableView.dequeueReusableCell(withIdentifier: MerchantCouponsListViewController.MerchantCouponHeaderViewIdentifier, for: indexPath) as! MerchantCouponHeaderView
            
            cell.data = data
            
            return cell
        }

        let cell = tableView.dequeueReusableCell(withIdentifier: MerchantCouponsListViewController.MerchantCouponViewCellIdentifier, for: indexPath) as! MerchantCouponViewCell

        if let coupon = coupons.get(indexPath.row - 1) {
        
            cell.isClaimedCoupon = coupon.isClaimed
            cell.data = coupon
            
            cell.buttonTapHandler = { [weak self] coupon in
                if let strongSelf = self, let merchantId = coupon.merchantId {
                    // record action
                    cell.recordAction(.Tap, sourceRef: "ClaimToMyCoupon", sourceType: .Button, targetRef: coupon.couponReference, targetType: .Coupon)
                    
                    CouponService.claimCoupon(coupon.couponReference, merchantId: merchantId, complete: { (response) in
                        if response.result.isSuccess && response.response?.statusCode == 200 {
                            coupon.isClaimed = true
                            cell.setButtonClaim(true)
                            CacheManager.sharedManager.hasNewClaimedCoupon = true
                            strongSelf.showSuccessPopupWithText(String.localize("LB_CA_COUPON_CLAIMED_SUC"))
                            CouponManager.shareManager().invalidate(wallet: merchantId)
                        }
                    })
                }
            }
            
            cell.toggleExpandCollapseHandler = {
                tableView.beginUpdates()
                tableView.endUpdates()
            }
            
            // record impression
            if let merchantId = coupon.merchantId {
                let impressionKey = recordImpression(impressionRef: coupon.couponReference, impressionType: "Coupon", impressionDisplayName: coupon.couponName, merchantCode: "\(merchantId)", positionComponent: "Grid", positionIndex: indexPath.row, positionLocation: "Cart-MerchantCouponClaimList")
                cell.initAnalytics(withViewKey: analyticsViewRecord.viewKey, impressionKey: impressionKey)
            }
            
        }
        
        return cell
    }

}
