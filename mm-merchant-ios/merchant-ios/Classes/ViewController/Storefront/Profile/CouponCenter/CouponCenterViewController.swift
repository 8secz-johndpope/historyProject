//
//  CouponCenterViewController.swift
//  storefront-ios
//
//  Created by Kam on 18/5/2018.
//  Copyright © 2018 WWE & CO. All rights reserved.
//

import Foundation
import PromiseKit

class CouponCenterViewController: MmViewController {
    
    private static let MerchantCouponViewCellIdentifier = "MerchantCouponViewCell"
    private static let MerchantCouponHeaderViewIdentifier = "MerchantCouponHeaderView"
    private static let NoActiveCouponCellIdentifier = "NoActiveCouponCell"
    
    private var merchantCoupons = [MerchantCoupon]()
    private var coupons = [Coupon]()
    private var claimedCoupons = [Coupon]()
    private var shouldShowNoCoupon = false
    
    var tableView: UITableView!
    var merchantId: Int?
    var headerTapHandler: ((Merchant) -> ())?
    var reddotUpdateHandler: (() -> Void)?
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
        
        if frame == UIScreen.main.bounds {
            frame = CGRect(x: 0, y: StartYPos, width: frame.width, height: frame.height - StartYPos)
        }
        
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
            UINib(nibName: CouponCenterViewController.MerchantCouponViewCellIdentifier, bundle: nil),
            forCellReuseIdentifier: CouponCenterViewController.MerchantCouponViewCellIdentifier
        )
        tableView.register(
            UINib(nibName: CouponCenterViewController.NoActiveCouponCellIdentifier, bundle: nil),
            forCellReuseIdentifier: CouponCenterViewController.NoActiveCouponCellIdentifier
        )
    }
    
    //MARK:- Services
    func loadCoupons() {
        showLoading()
        
        let merchantId = CouponMerchant.combine.rawValue
        
        if let mId = ssn_Arguments["merchantId"]?.int {
            self.merchantId = mId
        }
        
        let promises = [loadCoupons(merchantId), loadClaimedCoupon(merchantId)]
        
        when(fulfilled: promises).then { _ -> Void in
            
            self.groupAndSortCoupons()
            self.compareCoupon()
            
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
        if LoginManager.isValidUser() {
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
        } else {
            return Promise<Any> { fulfill, reject in
                self.claimedCoupons = []
                fulfill("OK") // fulfill ok to unblock and go through promise
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
        var mmCoupons = [Coupon]()
        mmCoupons = self.coupons.filter { (coupon) -> Bool in
            return coupon.isMmCoupon()
        }
        
        let filterCoupons: [Coupon] = self.coupons.filter { (coupon) -> Bool in
            if let mId = self.merchantId {
                return coupon.merchantId == mId || coupon.merchantId == Constants.MMMerchantId
            } else {
                return true
            }
        }
        
        var merchantIds = [Int]()
        for coupon in filterCoupons where coupon.merchantId != nil {
            if !merchantIds.contains(coupon.merchantId!) {
                merchantIds.append(coupon.merchantId!)
            }
        }
        
        for merchantId in merchantIds {
            if let merchant = CacheManager.sharedManager.cachedMerchantById(merchantId) {
                let merchantCoupon = MerchantCoupon()
                merchantCoupon.merchant = merchant
                merchantCoupon.coupons = filterCoupons.filter({ (coupon) -> Bool in
                    return coupon.merchantId == merchantId
                })
                merchantCoupon.coupons.sort(by: { $0.lastCreated! > $1.lastCreated! })
                merchantCoupons.append(merchantCoupon)
            }
        }
        merchantCoupons.sort(by: { $0.coupons[0].lastCreated! >  $1.coupons[0].lastCreated! })
        
        self.coupons.removeAll()
        self.coupons = mmCoupons
        for merchantCoupon in merchantCoupons {
            var coupons = merchantCoupon.coupons
            coupons.sort(by: { $0.couponAmount > $1.couponAmount } )
            
            self.coupons.append(contentsOf: coupons)
        }
    }
}

// MARK:- UITableViewDelegate
extension CouponCenterViewController: UITableViewDelegate {
    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        if coupons.isEmpty {
            return tableView.height
        }
        
        let coupon: Coupon = coupons[indexPath.row]
        
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

    }
}

// MARK:- UITableViewDataSource
extension CouponCenterViewController: UITableViewDataSource {
    
    func numberOfSections(in tableView: UITableView) -> Int {
        return 1
    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        if coupons.isEmpty && shouldShowNoCoupon {
            return 1
        }
        return coupons.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        if coupons.isEmpty {
            let cell = tableView.dequeueReusableCell(withIdentifier: CouponCenterViewController.NoActiveCouponCellIdentifier) as! NoActiveCouponCell
            cell.lblCouponEmpty.text = String.localize("LB_CA_CART_MERC_COUPON_EMPTY")
            
            return cell
        }
        
        let cell = tableView.dequeueReusableCell(withIdentifier: CouponCenterViewController.MerchantCouponViewCellIdentifier, for: indexPath) as! MerchantCouponViewCell
        
        let coupon: Coupon = coupons[indexPath.row]
        cell.isClaimedCoupon = coupon.isClaimed
        cell.data = coupon
        
        if coupon.isClaimed {
            cell.buttonTapHandler = { [weak self] coupon in
                if let strongSelf = self, let merchantId = coupon.merchantId {
                    if merchantId == Constants.MMMerchantId {
                        strongSelf.ssn_home()
                    } else {
                        Navigator.shared.dopen(Navigator.mymm.website_merchant_merchantId + "\(merchantId)")
                    }
                }
            }
        } else {
            cell.buttonTapHandler = { [weak self] coupon in
                if let strongSelf = self, let merchantId = coupon.merchantId {
                    CouponService.claimCoupon(coupon.couponReference, merchantId: merchantId, complete: { (response) in
                        if response.result.isSuccess && response.response?.statusCode == 200 {
                            coupon.isClaimed = true
                            cell.setButtonClaim(true)
                            CacheManager.sharedManager.hasNewClaimedCoupon = true
                            strongSelf.showSuccessPopupWithText(String.localize("LB_CA_COUPON_CLAIMED_SUC"), isAddWindow: true)
                            strongSelf.reddotUpdateHandler?()
                            CouponManager.shareManager().invalidate(wallet: CouponMerchant.combine.rawValue)
                            CouponManager.shareManager().invalidate(wallet: merchantId)
                            strongSelf.tableView.reloadRows(at: [indexPath], with: .automatic)
                        }
                    })
                }
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
        initAnalyticsViewRecord(viewLocation: "MasterCouponList", viewType: "Coupon")
    }
}
