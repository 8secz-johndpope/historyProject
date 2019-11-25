//
//  CouponClaimedViewController.swift
//  storefront-ios
//
//  Created by Kam on 18/5/2018.
//  Copyright © 2018 WWE & CO. All rights reserved.
//

import Foundation
import PromiseKit

class CouponClaimedViewController: MmViewController {
    var tableView: UITableView!
    var viewHeight = CGFloat(0)
    
    private enum IndexPathSection: Int {
        case activeCoupon
        case inactiveCoupon
    }
    
    private static let ClaimedCouponViewCellIdentifier = "MerchantCouponViewCell"
    private static let HeaderInactiveCouponCellIdentifier = "HeaderInactiveCouponCell"
    private static let NoActiveCouponCellIdentifier = "NoActiveCouponCell"
    
    private var activeCoupons = [Coupon]()
    private var inactiveCoupons = [Coupon]()
    private var shouldShowNoCoupon = false
    private var hasAppeared = false
    
    var data: CartMerchant?
    
    var buttonTapHandler: ((_ coupon: Coupon) -> ())?
    var reddotUpdateHandler: (() -> Void)?
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        setupView()
        setupTableView()
        
        if LoginManager.getLoginState() == .validUser {
            CouponService.popupCouponList(success: { (coupon) in
            }) { (erro) -> Bool in
                return true
            }
            
            CouponManager.shareManager().invalidate(wallet: CouponMerchant.combine.rawValue)
            loadCoupons()
        } else {
            showPlaceholder()
        }
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        if CacheManager.sharedManager.hasNewClaimedCoupon && hasAppeared /* prevent duplicate load with viewDidLoad */ && LoginManager.getLoginState() == .validUser {
            CacheManager.sharedManager.merchantFetchCompletion = {
                self.tableView.reloadData()
            }
            loadCoupons()
        }
        CacheManager.sharedManager.hasNewClaimedCoupon = false
        hasAppeared = true
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        self.reddotUpdateHandler?()
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
    
    func setupTableView() {
        tableView.backgroundColor = UIColor.primary2()
        tableView.register(
            UINib(nibName: CouponClaimedViewController.ClaimedCouponViewCellIdentifier, bundle: nil),
            forCellReuseIdentifier: CouponClaimedViewController.ClaimedCouponViewCellIdentifier
        )
        tableView.register(
            UINib(nibName: CouponClaimedViewController.HeaderInactiveCouponCellIdentifier, bundle: nil),
            forCellReuseIdentifier: CouponClaimedViewController.HeaderInactiveCouponCellIdentifier
        )
        tableView.register(
            UINib(nibName: CouponClaimedViewController.NoActiveCouponCellIdentifier, bundle: nil),
            forCellReuseIdentifier: CouponClaimedViewController.NoActiveCouponCellIdentifier
        )
    }
    
    private func showPlaceholder() {
        let placeholderView = UIView(frame: CGRect(x: 0, y: 150, width: tableView.frame.width, height: 180))
        
        let msgLabel = UILabel(frame: CGRect(x: 0, y: 10, width: placeholderView.frame.width, height:10))
        msgLabel.text = String.localize("LB_CA_COUPON_CENTER_UNLOGIN")
        msgLabel.textAlignment = .center
        msgLabel.textColor = .lightGray
        placeholderView.addSubview(msgLabel)
        
        let button = UIButton(frame: CGRect(x:0 , y: 70, width: 156, height: 36))
        button.center = CGPoint(x: msgLabel.center.x, y: button.center.y)
        button.formatPrimary()
        button.roundCorner(button.frame.height/2)
        button.setTitle(String.localize("LB_CA_SIGN_UP_IN"), for: .normal)
        button.touchUpClosure = { _ in
            var bundle = QBundle()
            bundle["mode"] = QValue(SignupMode.couponClaimed.rawValue)
            Navigator.shared.dopen(Navigator.mymm.website_login, params: bundle, modal:true)
        }
        placeholderView.addSubview(button)
        
        tableView.addSubview(placeholderView)
    }
    
    override func shouldHaveCollectionView() -> Bool {
        return false
    }

    func loadCoupons() {
        let merchantId = CouponMerchant.combine.rawValue
        
        self.showLoadingInScreenCenter()
        
        firstly {
            return CouponManager.shareManager().wallet(forMerchantId: merchantId)
            }.then { _, coupons -> Void in
                if var coupons = coupons {
                    coupons = coupons.filter { $0.isRedeemable }
                    for coupon in coupons {
                        if coupon.isSegmented == 1, let remark = CouponManager.shareManager().getCouponRemarkWith(coupon.segmentMerchantId, brandId: coupon.segmentBrandId, categoryId: coupon.segmentCategoryId) {
                            coupon.couponRemark = remark
                        }
                    }
                    
                    self.activeCoupons = coupons.filter({ !$0.isExpired &&
                        (!CacheManager.sharedManager.merchantPoolReady || CacheManager.sharedManager.isActiveMerchant($0.merchantId)) }).map { coupon in
                        coupon.isExpanded = false
                        return coupon
                    }
                    self.sortMmAndMerchantCoupon()
                    
                    self.inactiveCoupons = coupons.filter({ $0.isExpired ||
                        (CacheManager.sharedManager.merchantPoolReady && !CacheManager.sharedManager.isActiveMerchant($0.merchantId)) }).map { coupon in
                        coupon.isExpanded = false
                        return coupon
                    }
                }
                
            }.always {
                self.stopLoading()
                self.shouldShowNoCoupon = true
                self.tableView.reloadData()
                self.initAnalyticLog()
        }
    }
    
    private func sortMmAndMerchantCoupon() {
        var mmCoupons = [Coupon]()
        mmCoupons = self.activeCoupons.filter { (coupon) -> Bool in
            return coupon.isMmCoupon()
        }
        mmCoupons.sort(by: { $0.claimedTime ?? Date() > $1.claimedTime ?? Date() })
        
        var filterCoupons: [Coupon] = self.activeCoupons.filter { (coupon) -> Bool in
            return coupon.merchantId != Constants.MMMerchantId
        }
        filterCoupons.sort(by: { $0.claimedTime ?? Date() > $1.claimedTime ?? Date() })
        
        self.activeCoupons.removeAll()
        self.activeCoupons = mmCoupons
        self.activeCoupons.append(contentsOf: filterCoupons)
    }
    
    // MARK:- Analytic
    func initAnalyticLog(){
        initAnalyticsViewRecord(viewLocation: "MyCouponList", viewType: "Coupon")
    }
}

// MARK:- UITableViewDelegate
extension CouponClaimedViewController: UITableViewDelegate {
    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        if activeCoupons.isEmpty && inactiveCoupons.isEmpty {
            // no coupon cell
            return tableView.height
        }
        
        if (indexPath.section == IndexPathSection.inactiveCoupon.rawValue || (indexPath.section == IndexPathSection.activeCoupon.rawValue && activeCoupons.isEmpty && !inactiveCoupons.isEmpty)) && indexPath.row == 0 {
            // header inactive coupon
            return 54
        }
        
        // normal cell
        var coupon: Coupon?
        if indexPath.section == IndexPathSection.activeCoupon.rawValue && !activeCoupons.isEmpty {
            coupon = activeCoupons[indexPath.row]
        }
        else if !inactiveCoupons.isEmpty {
            coupon = inactiveCoupons[indexPath.row - 1]
        }
        
        if let coupon = coupon, coupon.isExpanded {
            let height = 30 + StringHelper.heightForText(coupon.couponRemark, width: tableView.frame.width - 60, font: UIFont.fontLightWithSize(14))
            
            return 110 + height
        }
        
        return 110
    }
}

// MARK:- UITableViewDataSource
extension CouponClaimedViewController: UITableViewDataSource {
    func numberOfSections(in tableView: UITableView) -> Int {
        if !activeCoupons.isEmpty && !inactiveCoupons.isEmpty {
            return 2
        }
        
        return 1
    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return numberOfRowsInSection(section)
    }
    
    func numberOfRowsInSection(_ section: Int) -> Int {
        if section == IndexPathSection.activeCoupon.rawValue && !activeCoupons.isEmpty {
            return activeCoupons.count
        }
        
        if inactiveCoupons.count == 0 && shouldShowNoCoupon {
            return 1
        }
        
        if !inactiveCoupons.isEmpty {
            return inactiveCoupons.count + 1
        }
        
        return 0
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        if activeCoupons.isEmpty && inactiveCoupons.isEmpty {
            let cell = tableView.dequeueReusableCell(withIdentifier: CouponClaimedViewController.NoActiveCouponCellIdentifier) as! NoActiveCouponCell
            cell.lblCouponEmpty.text = String.localize("LB_CA_PROFILE_MY_COUPON_EMPTY")
            
            return cell
        }
        
        if indexPath.section == IndexPathSection.activeCoupon.rawValue && !activeCoupons.isEmpty {
            // active coupon
            let cell = tableView.dequeueReusableCell(withIdentifier: CouponClaimedViewController.ClaimedCouponViewCellIdentifier, for: indexPath) as! MerchantCouponViewCell
            
            cell.isActiveCoupon = true
            cell.isClaimedCoupon = true
            let coupon = activeCoupons.get(indexPath.row)
            
            cell.buttonTapHandler = { [weak self] coupon in
                if let strongSelf = self, let merchantId = coupon.merchantId {
                    if merchantId == Constants.MMMerchantId {
                        strongSelf.ssn_home()
                    } else {
                        Navigator.shared.dopen(Navigator.mymm.website_merchant_merchantId + "\(merchantId)")
                        cell.recordAction(.Tap, sourceRef: coupon.couponReference, sourceType: .Coupon, targetRef: "MLP", targetType: .View)
                    }
                }
            }
            
            cell.data = coupon
            
            if let coupon = coupon, coupon.isNew() {
                cell.setCouponState(.new)
            }
            else {
                cell.setCouponState(.none)
            }
            
            cell.toggleExpandCollapseHandler = {
                tableView.beginUpdates()
                tableView.endUpdates()
            }
            
            //record impression
            let impressionKey = recordImpression(with: coupon!, positionIndex: indexPath.row + 1)
            cell.initAnalytics(withViewKey: analyticsViewRecord.viewKey, impressionKey: impressionKey)
            
            cell.labelAmountCenter.constant = -24
            return cell
        }
        
        // inactive coupon
        if indexPath.row == 0 {
            // header inactive coupon
            return tableView.dequeueReusableCell(withIdentifier: CouponClaimedViewController.HeaderInactiveCouponCellIdentifier, for: indexPath) as! HeaderInactiveCouponCell
        }
        
        let cell = tableView.dequeueReusableCell(withIdentifier: CouponClaimedViewController.ClaimedCouponViewCellIdentifier, for: indexPath) as! MerchantCouponViewCell
        cell.isActiveCoupon = false
        cell.button.isHidden = true
        
        if let coupon = inactiveCoupons.get(indexPath.row - 1) {
            cell.data = coupon
            cell.setCouponState(.inactive)
            cell.toggleExpandCollapseHandler = {
                tableView.beginUpdates()
                tableView.endUpdates()
            }
            cell.labelAmountCenter.constant = -12
            //record impression
            recordImpression(with: coupon, positionIndex: indexPath.row)
        }
        
        return cell
    }
    
    @discardableResult
    func recordImpression(with coupon: Coupon, positionIndex: Int) -> String {
        if let merchantId = coupon.merchantId {
            return recordImpression(impressionRef: coupon.couponReference, impressionType: "Coupon", impressionDisplayName: coupon.couponName, merchantCode: "\(merchantId)", positionComponent: "Grid", positionIndex: positionIndex, positionLocation: "MyCoupon")
        }
        
        return ""
    }
}
