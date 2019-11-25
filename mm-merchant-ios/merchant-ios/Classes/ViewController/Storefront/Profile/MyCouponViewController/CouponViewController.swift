//
//  CouponViewController.swift
//  merchant-ios
//
//  Created by Phan Manh Hung on 2/8/17.
//  Copyright © 2017 WWE & CO. All rights reserved.
//

import Foundation
import PromiseKit

enum CouponViewControllerType: Int {
    case mmCouponViewController
    case merchantCouponViewController
}

class CouponViewController: MmViewController {
    var tableView: UITableView!
    var viewHeight = CGFloat(0)

    private enum IndexPathSection: Int {
        case activeCoupon
        case inactiveCoupon
    }
    
    private static let MyCouponViewCellIdentifier = "MyCouponViewCell"
    private static let HeaderInactiveCouponCellIdentifier = "HeaderInactiveCouponCell"
    private static let NoActiveCouponCellIdentifier = "NoActiveCouponCell"

    private var activeCoupons = [Coupon]()
    private var inactiveCoupons = [Coupon]()
    private var shouldShowNoCoupon = false

    var viewControllerType: CouponViewControllerType = .merchantCouponViewController
    var data: CartMerchant?
    
    var buttonTapHandler: ((_ coupon: Coupon) -> ())?
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        setupView()
        setupTableView()
        
        CacheManager.sharedManager.hasNewClaimedCoupon = false
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
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
    
    func setupTableView() {
        tableView.backgroundColor = UIColor.primary2()
        tableView.register(
            UINib(nibName: CouponViewController.MyCouponViewCellIdentifier, bundle: nil),
            forCellReuseIdentifier: CouponViewController.MyCouponViewCellIdentifier
        )
        tableView.register(
            UINib(nibName: CouponViewController.HeaderInactiveCouponCellIdentifier, bundle: nil),
            forCellReuseIdentifier: CouponViewController.HeaderInactiveCouponCellIdentifier
        )
        tableView.register(
            UINib(nibName: CouponViewController.NoActiveCouponCellIdentifier, bundle: nil),
            forCellReuseIdentifier: CouponViewController.NoActiveCouponCellIdentifier
        )
    }

    override func shouldHaveCollectionView() -> Bool {
        return false
    }

    func loadCoupons() {
        var merchantId = CouponMerchant.allMerchant.rawValue
        if viewControllerType == .mmCouponViewController {
            merchantId = CouponMerchant.mm.rawValue
        }
        
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
                
                self.activeCoupons = coupons.filter({ !$0.isExpired && CacheManager.sharedManager.isActiveMerchant($0.merchantId) }).map { coupon in
                    coupon.isExpanded = false
                    return coupon
                }
                self.inactiveCoupons = coupons.filter({ $0.isExpired || !CacheManager.sharedManager.isActiveMerchant($0.merchantId) }).map { coupon in
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
    
    // MARK:- Analytic
    func initAnalyticLog(){
        var viewLocation = ""
        if viewControllerType == .mmCouponViewController {
            viewLocation = "MyCouponList-MyMMCoupon"
        }
        else {
            viewLocation = "MyCouponList-MerchantCoupon"
        }
        initAnalyticsViewRecord(viewLocation: viewLocation, viewType: "Coupon")
    }
}

// MARK:- UITableViewDelegate
extension CouponViewController: UITableViewDelegate {
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
extension CouponViewController: UITableViewDataSource {
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
            let cell = tableView.dequeueReusableCell(withIdentifier: CouponViewController.NoActiveCouponCellIdentifier) as! NoActiveCouponCell
            cell.lblCouponEmpty.text = String.localize("LB_CA_PROFILE_MY_COUPON_EMPTY")

            return cell
        }
        
        if indexPath.section == IndexPathSection.activeCoupon.rawValue && !activeCoupons.isEmpty {
            // active coupon
            let cell = tableView.dequeueReusableCell(withIdentifier: CouponViewController.MyCouponViewCellIdentifier, for: indexPath) as! MyCouponViewCell

            if viewControllerType == .mmCouponViewController {
                cell.shouldShowButton = false
            }
            else {
                cell.shouldShowButton = true
                cell.buttonTapHandler = { [weak self] coupon in
                    if let strongSelf = self {
                        //record action
                        cell.recordAction(.Tap, sourceRef: coupon.couponReference, sourceType: .Coupon, targetRef: "MLP", targetType: .View)

                        strongSelf.buttonTapHandler?(coupon)
                    }
                }
            }
            
            cell.isActiveCoupon = true
            let coupon = activeCoupons.get(indexPath.row)
            cell.data = coupon
            
            cell.toggleExpandCollapseHandler = {
                tableView.beginUpdates()
                tableView.endUpdates()
            }

            //record impression
            let impressionKey = recordImpression(with: coupon!, positionIndex: indexPath.row + 1)
            cell.initAnalytics(withViewKey: analyticsViewRecord.viewKey, impressionKey: impressionKey)
            
            return cell
        }
        
        // inactive coupon
        if indexPath.row == 0 {
            // header inactive coupon
            return tableView.dequeueReusableCell(withIdentifier: CouponViewController.HeaderInactiveCouponCellIdentifier, for: indexPath) as! HeaderInactiveCouponCell
        }
        
        let cell = tableView.dequeueReusableCell(withIdentifier: CouponViewController.MyCouponViewCellIdentifier, for: indexPath) as! MyCouponViewCell
        cell.isActiveCoupon = false
        cell.shouldShowButton = false

        if let coupon = inactiveCoupons.get(indexPath.row - 1) {
            cell.data = coupon
            
            cell.toggleExpandCollapseHandler = {
                tableView.beginUpdates()
                tableView.endUpdates()
            }

            //record impression
            recordImpression(with: coupon, positionIndex: indexPath.row)
        }

        return cell
    }
    
    @discardableResult
    func recordImpression(with coupon: Coupon, positionIndex: Int) -> String {
        var positionLocation = ""
        if viewControllerType == .mmCouponViewController {
            positionLocation = "MyCouponList-MyMMCoupon"
        }
        else {
            positionLocation = "MyCoupon-MerchantCouponList"
        }
        if let merchantId = coupon.merchantId {
            return recordImpression(impressionRef: coupon.couponReference, impressionType: "Coupon", impressionDisplayName: coupon.couponName, merchantCode: "\(merchantId)", positionComponent: "Grid", positionIndex: positionIndex, positionLocation: positionLocation)
        }
        
        return ""
    }
}
