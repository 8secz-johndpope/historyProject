//
//  MasterCouponsViewController.swift
//  merchant-ios
//
//  Created by HungPM on 7/27/17.
//  Copyright © 2017 WWE & CO. All rights reserved.
//

import Foundation
import PromiseKit

class MasterCouponsViewController: MmViewController {
    
    private static let MerchantCouponViewCellIdentifier = "MerchantCouponViewCell"
    private static let MerchantCouponHeaderViewIdentifier = "MerchantCouponHeaderView"
    private static let NoActiveCouponCellIdentifier = "NoActiveCouponCell"
    
    private var merchantCoupons = [MerchantCoupon]()
    private var coupons = [Coupon]()
    private var claimedCoupons = [Coupon]()
    private var shouldShowNoCoupon = false
    
    var tableView: UITableView!
    var viewHeight = CGFloat(0)
    var viewControllerType: CouponViewControllerType = .merchantCouponViewController
    var merchantId: Int?
    var headerTapHandler: ((Merchant) -> ())?

    //MARK:- View Lifecycle
    override func viewDidLoad() {
        super.viewDidLoad()
        
        initAnalytics()
        setupView()
        setupTableView()
        loadCoupons()
    }
    
    func setupView() {
        var frame = view.frame
        frame.size.height = viewHeight

        tableView = UITableView(frame: frame)
        tableView.delegate = self
        tableView.dataSource = self
        tableView.separatorStyle = .none
        view.addSubview(tableView)
    }
    
    //MARK:- Config view
    override func shouldHaveCollectionView() -> Bool {
        return false
    }

    func setupTableView() {
        tableView.backgroundColor = UIColor.primary2()
        tableView.register(
            UINib(nibName: MasterCouponsViewController.MerchantCouponViewCellIdentifier, bundle: nil),
            forCellReuseIdentifier: MasterCouponsViewController.MerchantCouponViewCellIdentifier
        )
        tableView.register(
            UINib(nibName: MasterCouponsViewController.NoActiveCouponCellIdentifier, bundle: nil),
            forCellReuseIdentifier: MasterCouponsViewController.NoActiveCouponCellIdentifier
        )
        
        if viewControllerType == .merchantCouponViewController {
            tableView.register(
                UINib(nibName: MasterCouponsViewController.MerchantCouponHeaderViewIdentifier, bundle: nil),
                forCellReuseIdentifier: MasterCouponsViewController.MerchantCouponHeaderViewIdentifier
            )
        }
    }
    
    //MARK:- Services
    func loadCoupons() {
        showLoading()
        
        var merchantId = CouponMerchant.allMerchant.rawValue
        
        if viewControllerType == .mmCouponViewController {
            merchantId = CouponMerchant.mm.rawValue
        } else if let mID = self.merchantId {
            if mID > CouponMerchant.mm.rawValue {
                merchantId = mID
            } else {
                self.merchantId = nil
            }
        }
        
        let promises = [loadCoupons(merchantId), loadClaimedCoupon(merchantId)]
        
        when(fulfilled: promises).then { _ -> Void in
            
            self.compareCoupon()
            if self.viewControllerType == .mmCouponViewController || self.merchantId != nil {
                self.coupons.sort(by: { $0.couponAmount > $1.couponAmount })
            }
            else {
                self.groupAndSortCoupons()
            }
            
            }.always {
                self.shouldShowNoCoupon = true
                self.tableView.reloadData()
                self.stopLoading()
        }
    }
    
    func loadCoupons(_ merchantId: Int) -> Promise<Any> {
        return Promise { fulfill, _ in
            firstly {
                return CouponManager.shareManager().coupons(forMerchantId: merchantId)
                }.then { _, coupons -> Void in
                    if let coupons = coupons {
                        self.coupons = coupons.filter { $0.isWithinActivePeriod && $0.isAvailable }.map { coupon in
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

    func compareCoupon() {
        for i in 0 ..< coupons.count {
            for claimedCoupon in claimedCoupons {
                if coupons[i].couponId == claimedCoupon.couponId {
                    claimedCoupon.isClaimed = true
                    coupons[i] = claimedCoupon
                    break
                }
            }
            
            if coupons[i].isSegmented == 1, let remark = CouponManager.shareManager().getCouponRemarkWith(coupons[i].segmentMerchantId, brandId: coupons[i].segmentBrandId, categoryId: coupons[i].segmentCategoryId) {
                coupons[i].couponRemark = remark
            }
        }
    }
    
    func groupAndSortCoupons() {
        var merchantIds = [Int]()
        for coupon in coupons where coupon.merchantId != nil {
            if !merchantIds.contains(coupon.merchantId!) {
                merchantIds.append(coupon.merchantId!)
            }
        }
        
        for merchantId in merchantIds {
            if let merchant = CacheManager.sharedManager.cachedMerchantById(merchantId) {
                let merchantCoupon = MerchantCoupon()
                merchantCoupon.merchant = merchant
                merchantCoupons.append(merchantCoupon)
            }
        }
        
        merchantCoupons.sort(by: { $0.merchant!.merchantName.uppercased() < $1.merchant!.merchantName.uppercased() })
        
        for coupon in coupons {
            for merchantCoupon in merchantCoupons {
                if coupon.merchantId == merchantCoupon.merchant!.merchantId {
                    merchantCoupon.coupons.append(coupon)
                }
            }
        }
        
        for merchantCoupon in merchantCoupons {
            merchantCoupon.coupons.sort(by: { $0.couponAmount > $1.couponAmount })
        }
    }
}

// MARK:- UITableViewDelegate
extension MasterCouponsViewController: UITableViewDelegate {
    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        if coupons.isEmpty {
            return tableView.height
        }
        
        var coupon: Coupon
        
        if viewControllerType == .mmCouponViewController {
            coupon = coupons[indexPath.row]
        }
        else {
            if indexPath.row == 0 {
                //header
                if indexPath.section != 0 {
                    return 80
                }
                
                return 50
            }
            
            if self.merchantId != nil {
                coupon = coupons[indexPath.row - 1]
            }
            else {
                coupon = merchantCoupons[indexPath.section].coupons[indexPath.row - 1]
            }
        }
        
        if coupon.isExpanded {
            let height = 30 + StringHelper.heightForText(coupon.couponRemark, width: tableView.frame.width - 60, font: UIFont.fontLightWithSize(14))
            
            return 110 + height
        }
        
        return 110
    }
    
    func tableView(_ tableView: UITableView, heightForHeaderInSection section: Int) -> CGFloat {
        return 0
    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        if viewControllerType == .mmCouponViewController || indexPath.row != 0 {
            return
        }

        var merchant: Merchant?
        if let merchantId = merchantId {
            merchant = CacheManager.sharedManager.cachedMerchantById(merchantId)
        }
        else {
            merchant = merchantCoupons[indexPath.section].merchant
        }
        
        if let merchant = merchant {
            headerTapHandler?(merchant)
        }
    }
}

// MARK:- UITableViewDataSource
extension MasterCouponsViewController: UITableViewDataSource {
    
    func numberOfSections(in tableView: UITableView) -> Int {
       
        if coupons.isEmpty && shouldShowNoCoupon {
            return 1
        }
        
        if viewControllerType == .mmCouponViewController || self.merchantId != nil {
            return 1
        }
        
        return merchantCoupons.count
    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        if coupons.isEmpty && shouldShowNoCoupon {
            return 1
        }
        
        if viewControllerType == .mmCouponViewController {
            return coupons.count
        }

        if self.merchantId != nil {
            return coupons.count + 1
        }
        
        return merchantCoupons[section].coupons.count + 1
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        if coupons.isEmpty {
            let cell = tableView.dequeueReusableCell(withIdentifier: MasterCouponsViewController.NoActiveCouponCellIdentifier) as! NoActiveCouponCell
            cell.lblCouponEmpty.text = String.localize("LB_CA_CART_MERC_COUPON_EMPTY")
            
            return cell
        }
        
        if viewControllerType == .merchantCouponViewController && indexPath.row == 0 {
            //header
            let cell = tableView.dequeueReusableCell(withIdentifier: MasterCouponsViewController.MerchantCouponHeaderViewIdentifier, for: indexPath) as! MerchantCouponHeaderView
            cell.rightView.isHidden = false
            cell.topSeparator.isHidden = true

            if let merchantId = merchantId {
                cell.data = CacheManager.sharedManager.cachedMerchantById(merchantId)
            }
            else {
                cell.data = merchantCoupons[indexPath.section].merchant
            }
            
            return cell
        }
        
        let cell = tableView.dequeueReusableCell(withIdentifier: MasterCouponsViewController.MerchantCouponViewCellIdentifier, for: indexPath) as! MerchantCouponViewCell
        
        var coupon: Coupon
        if viewControllerType == .merchantCouponViewController {
            if merchantId != nil {
                coupon = coupons[indexPath.row - 1]
            }
            else {
                coupon = merchantCoupons[indexPath.section].coupons[indexPath.row - 1]
            }
        }
        else {
            coupon = coupons[indexPath.row]
        }
        
        cell.isClaimedCoupon = coupon.isClaimed
        cell.data = coupon
        
        cell.buttonTapHandler = { [weak self] coupon in
            if let strongSelf = self, let merchantId = coupon.merchantId {
                
                CouponService.claimCoupon(coupon.couponReference, merchantId: merchantId, complete: { (response) in
                    if response.result.isSuccess && response.response?.statusCode == 200 {
                        coupon.isClaimed = true
                        cell.setButtonClaim(true)
                        CacheManager.sharedManager.hasNewClaimedCoupon = true
                        strongSelf.showSuccessPopupWithText(String.localize("LB_CA_COUPON_CLAIMED_SUC"), isAddWindow: true)
                        CouponManager.shareManager().invalidate(wallet: merchantId)
                    }
                })
            }
        }
        
        cell.toggleExpandCollapseHandler = {
            tableView.beginUpdates()
            tableView.endUpdates()
        }
        
        return cell
    }
    
    //MARK: - Analytics
    
    func initAnalytics() {
        var viewLocation = ""
        if viewControllerType == .mmCouponViewController {
            viewLocation = "MasterCouponList-MyMMCoupon"
        }
        else {
            viewLocation = "MasterCouponList-MerchantCoupon"
        }
        initAnalyticsViewRecord(viewLocation: viewLocation, viewType: "Coupon")
    }
}
