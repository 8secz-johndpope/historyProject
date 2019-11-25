//
//  MerchantViewController.swift
//  storefront-ios
//
//  Created by Leslie Zhang on 2018/7/3.
//  Copyright © 2018年 WWE & CO. All rights reserved.
//

import UIKit
import ObjectMapper
import PromiseKit

class MerchantViewController: MMPageViewController,ProductListViewControllerDelegate,MerchantCouponDelegate,MMPageContainerDelegate {
    var merchantId:Int?
    private var merchant: Merchant?
    private var coupons = [Coupon]()
    private var backButton:UIButton?
    private var shareButton:UIButton?
    private var serviceButton:UIButton?
    private var claimedCoupons = [Coupon]()
    private var merchantBrand: MerchantBrand?
    private var merchantFeedViewController:MerchantFeedViewController?
    private let topImageViewHeight:CGFloat = ScreenWidth * 0.4 //头图高度
    private var headMargin:CGFloat = ScreenWidth * 0.4 //顶部间隔，有copon的情况会增加高度
    private var navigationBarVisibility: MmFadeNavigationControllerNavigationBarVisibility = .hidden {
        didSet {
            UIApplication.shared.statusBarStyle = self.navigationBarVisibility == .visible ? .default : .lightContent
        }
    }
    private var contentOffsetY:CGFloat = 0.0
    
    //MARK: - life cycle
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        
        if let navigationController = self.navigationController as? MmNavigationController {
            navigationController.setNavigationBarVisibility(offset: contentOffsetY)
            navigationController.navigationBar.shadowImage = UIImage()
        }
    }
    override func viewDidLoad() {
        super.viewDidLoad()
        
        let completion = {
            self.initAnalyticLog()
        }
        
        self.title = ""
        
        if let mid = ssn_Arguments["merchantId"]?.int {
            merchantId = mid
            self.merchant = CacheManager.sharedManager.cachedMerchantById(mid)
        } else if let mid = ssn_Arguments["merchantSubDomain"]?.int { //必须兼容传过来的参数是merchantId
            merchantId = mid
            self.merchant = CacheManager.sharedManager.cachedMerchantById(mid)
        }
        
        if let _ = self.merchant {
            self.merchantId = self.merchant?.merchantId
            if let merchantId = self.merchantId {
                getCoupons(merchantId)
            }
            completion()
        } else if let merchantSubdomain = ssn_Arguments["merchantSubDomain"]?.string {
            MerchantService.viewMerchantSubdomain(merchantSubdomain) { (response) in
                if response.result.isSuccess && response.response?.statusCode == 200 {
                    if let merchants: Array<Merchant> = Mapper<Merchant>().mapArray(JSONObject: response.result.value), merchants.count > 0 {
                        self.merchant = merchants.first
                        self.merchantId = self.merchant?.merchantId
                        if let merchantId = self.merchantId {
                            self.getCoupons(merchantId)
                        }
                        completion()
                    }
                } 
            }
        } else if let merchantId = merchantId,merchantId > 0 {
            MerchantService.fetchMerchantIfNeeded(merchantId, completion: { (merchant) in
                if let merchant = merchant {
                    self.merchant = merchant
                    self.merchantId = self.merchant?.merchantId
                    if let merchantId = self.merchantId {
                        self.getCoupons(merchantId)
                    }
                    completion()
                } else {
                    ErrorLogManager.sharedManager.recordNonFatalError(withException: .NullPointer)
                }
            })
        }
        
        createNavigationBar()
    }
    
    //MARK: - service 
    private func getCoupons(_ merchantId:Int) {
        guard (LoginManager.getLoginState() == .validUser) else {
            setHeadMarginFetchMerchant()
            return
        }
        
        when(fulfilled: CouponManager.shareManager().coupons(forMerchantId: CouponMerchant.combine.rawValue), CouponManager.shareManager().wallet(forMerchantId: CouponMerchant.combine.rawValue)).then { [weak self] responseCounpon, responseClaimedCounpon -> Void in
            if let strongSelf = self {
                if let result = responseCounpon.coupons {
                    var availableCoupons = result.filter({ $0.eligible() &&
                        (($0.isMmCoupon() && $0.isSegmentedCriteria(merchantId: merchantId)) ||
                            $0.merchantId == merchantId) })
                    availableCoupons.sort(by: { ($0.lastCreated ?? Date()).compare($1.lastCreated ?? Date()) == .orderedDescending })
                    
                    strongSelf.coupons = Array(availableCoupons)
                    
                }
                if let result = responseClaimedCounpon.coupons {
                    strongSelf.claimedCoupons = result.filter { $0.isRedeemable &&
                        (($0.isMmCoupon() && $0.isSegmentedCriteria(merchantId: merchantId)) ||
                            $0.merchantId == merchantId) }
                }
                
                strongSelf.setHeadMarginFetchMerchant()
            }
            }.catch { (error) in
                self.setHeadMarginFetchMerchant()
                Log.error("error")
        }
    }
    private func checkMerchant(_ merchantId:Int) {
        guard (LoginManager.getLoginState() == .validUser) else {
            topImageView.follow = false
            return
        }
        RelationshipService.relationshipByMerchant(merchantId) { [weak self] (response) in
            if let strongSelf = self {
                if response.response?.statusCode == 200 {
                    if let relationShip = Mapper<Relationship>().map(JSONObject: response.result.value) {
                        strongSelf.topImageView.follow = relationShip.isFollowing
                    }
                } else {
                    strongSelf.handleError(response, animated: true)
                }
            }
        }
    }
    private func unfollowMerchant(_ merchant: Merchant) {
        let message = String.localize("LB_CA_PROFILE_COLLECTION_REMOVAL").replacingOccurrences(of: "{0}", with: merchant.merchantName)
        Alert.alert(self, title: "", message: message, okActionComplete: { () -> Void in
            
            firstly {
                return FollowService.requestUnfollow(merchant: merchant)
                }.then { _ -> Void in
                    self.topImageView.follow = false
                    merchant.followerCount -= 1
                    self.topImageView.merchant = merchant
                }.catch { _ -> Void in
                    Log.error("error")
                    
            }
        }, cancelActionComplete:nil)
    }
    private func followMerchant(_ merchant: Merchant) {
        firstly {
            return FollowService.requestFollow(merchant: merchant)
            }.then { _ -> Void in
                merchant.followerCount += 1
                self.topImageView.follow = true
                self.topImageView.merchant = merchant
            }.catch { error -> Void in
                Log.error("error")
                let error = error as NSError
                if let apiResp = error.userInfo["data"] as? ApiResponse {
                    self.handleError(apiResp, statusCode: error.code, animated: true)
                }
        }
    }
    private func fetchMerchantBrands(_ merchantId:Int) {
        
        MerchantService.fetchMerchantBrands(merchantId) { [weak self] (response) in
            if let strongSelf = self {
                if response.response?.statusCode == 200 {
                    if let merchantBrands = Mapper<MerchantBrand>().mapArray(JSONObject: response.result.value) {
                        strongSelf.merchantBrand = merchantBrands.first
                        strongSelf.createViewControlls()
                    }
                } else {
                    strongSelf.createViewControlls()
                    ErrorLogManager.sharedManager.recordNonFatalError(withException: .NullPointer)
                }
            }
        }
    }
    
    //MARK: - MMPageContainerDelegate
    func didScrolledToPage(_ index: Int) {
        view.analyticsViewKey = self.analyticsViewRecord.viewKey
        
        switch index {
        case 0:
            let sourceRef = "Newsfeed"
            view.recordAction(.Tap, sourceRef: sourceRef, sourceType: .Link, targetRef: merchant?.merchantCode, targetType: .Merchant)
        case 1:
            let sourceRef = "ProductListing"
            view.recordAction(.Tap, sourceRef: sourceRef, sourceType: .Link, targetRef: merchant?.merchantCode, targetType: .Merchant)
            
        case 2:
            let sourceRef = "Brand"
            view.recordAction(.Tap, sourceRef: sourceRef, sourceType: .Link, targetRef: merchant?.merchantCode, targetType: .Merchant)
        default:
            break
        }
    }
    
    //MARK: - MerchantCouponDelegate
    func viewAllCoupon() {
        if let merchantId = self.merchant?.merchantId {
            Navigator.shared.dopen(Navigator.mymm.website_coupon_center + "\(merchantId)")
            let targetRef = String(merchantId)
            self.view.recordAction(.Tap, sourceRef: "MoreCoupon", sourceType: .Link, targetRef: targetRef, targetType: .MPP)
        }
    }
    func clickOnCoupon(_ coupon: Coupon, cell: MerchantCouponCell, claimCompletion: (() -> Void)?) {
        guard LoginManager.getLoginState() == .validUser, !coupon.isClaimed else { return }
        if let merchantId = coupon.merchantId {
            CouponService.claimCoupon(coupon.couponReference, merchantId: merchantId, complete: { [weak self] (response) in
                if let strongSelf = self {
                    if response.result.isSuccess && response.response?.statusCode == 200 {
                        coupon.isClaimed = true
                        strongSelf.merchantCouponView.collectionView?.reloadData()
                        CacheManager.sharedManager.hasNewClaimedCoupon = true
                        strongSelf.showSuccessPopupWithText(String.localize("LB_CA_COUPON_CLAIMED_SUC"))
                        CouponManager.shareManager().invalidate(wallet: CouponMerchant.combine.rawValue)
                        CouponManager.shareManager().invalidate(wallet: merchantId)
                    }
                }
            })
        }
    }
    
    //MARK: - ProductListViewControllerDelegate
    func productListViewControllerScrollViewDidScroll(_ scrollView: UIScrollView) {
        if currentPageIndex == 1 {
            contentOffsetY = scrollView.contentOffset.y
            if scrollView.contentOffset.y < 0 || scrollView.contentSize.height > self.view.bounds.height - self.headMargin {
                didScroll(scrollView.contentOffset.y)
            }
        }
    }
    
    //MARK: - event response
    @objc private func didSelectMerchantProfileView(_ sender: UIView) {
        if let merchant = self.merchant {
            let merchantDescriptionVC = MerchantDescriptionViewController()
            merchantDescriptionVC.merchant = merchant
            merchantDescriptionVC.mode = DescriptionMode.modeMerchant
            self.navigationController?.push(merchantDescriptionVC, animated: true)
            
            sender.analyticsViewKey = self.analyticsViewRecord.viewKey //make sure view key is not empty
            sender.recordAction(.Tap, sourceRef: "MerchantDesription", sourceType: .Link, targetRef: merchant.merchantCode, targetType: .Merchant)
        }
    }
    @objc private func onHandleFollow(_ sender: UIView) {
        guard (LoginManager.getLoginState() == .validUser) else {
            LoginManager.goToLogin()
            return
        }
        if let merchant = merchant {
            var sourceRef = ""
            
            if let follow = topImageView.follow {
                if follow {
                    sourceRef = "Unfollow"
                    self.unfollowMerchant(merchant)
                } else {
                    sourceRef = "Follow"
                    self.followMerchant(merchant)
                }
            }
            
            if merchant.merchantCode.length > 0 {
                sender.analyticsViewKey = self.analyticsViewRecord.viewKey
                sender.recordAction(.Tap, sourceRef: sourceRef, sourceType: .Button, targetRef: merchant.merchantCode, targetType: .Merchant)
            }
        }
    }
    @objc private func popViewController() {
        navigationController?.popViewController(animated: true)
    }
    @objc private func selectShareButton(sender: UIButton) {
        if let merchant = self.merchant {
            PushManager.sharedInstance.goToShareWithBrandOrMerchant(self.analyticsViewRecord.viewKey, merchant: merchant)
            
            if merchant.merchantCode.length > 0 {
                sender.analyticsViewKey = self.analyticsViewRecord.viewKey
                sender.recordAction(.Tap, sourceRef: "Share", sourceType: .Button, targetRef: merchant.merchantCode, targetType: .Merchant)
            }
        }
    }
    @objc private func goToMerchantConversation(sender: UIButton) {
        if let merchant = self.merchant {
            if LoginManager.isValidUser() {
                PushManager.sharedInstance.goToMerchantConversation(merchant.merchantId, viewController: self)
                sender.analyticsViewKey = self.analyticsViewRecord.viewKey
                sender.recordAction(.Tap, sourceRef: "CustomerSupport", sourceType: .Button, targetRef: merchant.merchantCode, targetType: .Merchant)
            } else {
                LoginManager.goToLogin()
            }
        }
    }
    @objc private func goToPLP() {
        if let merchant = self.merchant {
            PushManager.sharedInstance.goToPLP(merchantId: merchant.merchantId, isSearch: true, noNeedBrandFeed: true, animated: false)
        }
    }
    
    //MARK: - private methods
    private func setHeadMarginFetchMerchant() {
        
        if coupons.count > 0 {
            headMargin = headMargin + MerchantCouponCell.ViewHeight
        }
        
        MARGIN_Y = headMargin
        
        if let merchantId = merchantId {
            fetchMerchantBrands(merchantId)
        }
    }
    private func createNavigationBar() {
        let backItem = UIBarButtonItem.createBackItem() { [weak self] (button) in
            if let strongSelf = self {
                button.addTarget(self, action: #selector(strongSelf.popViewController), for: .touchUpInside)
                strongSelf.backButton = button
            }
        }
        let shareItem = UIBarButtonItem.createShareItem() { [weak self] (button) in
            if let strongSelf = self {
                button.addTarget(self, action: #selector(strongSelf.selectShareButton), for: .touchUpInside)
                strongSelf.shareButton = button
            }
        }
        let searchItem = UIBarButtonItem.createSearchItem() { [weak self] (customView) in
            if let strongSelf = self {
                customView.addGestureRecognizer(UITapGestureRecognizer(target: self, action: #selector(strongSelf.goToPLP)))
            }
        }
        let serviceItem = UIBarButtonItem.createServiceItem() { [weak self] (button) in
            if let strongSelf = self {
                button.addTarget(self, action: #selector(strongSelf.goToMerchantConversation), for: .touchUpInside)
                strongSelf.serviceButton = button
            }
        }
        navigationItem.leftBarButtonItems = [backItem]
        navigationItem.rightBarButtonItems = [shareItem,serviceItem,searchItem]
    }
    private func createViewControlls() {
        let merchantFeedViewController = MerchantFeedViewController()
        if let merchant = merchant {
            merchantFeedViewController.merchant = merchant
        }
        
        merchantFeedViewController.scrollViewDidScrollAction = { [weak self] (scrollView) in
            if let strongSelf = self {
                if strongSelf.currentPageIndex == 0 {
                    strongSelf.contentOffsetY = scrollView.contentOffset.y
                    strongSelf.didScroll(scrollView.contentOffset.y)
                }
            }
        }
        let productList = ProductListViewController()
        productList.delegate = self
        productList.noNeedBrandFeed = true
        productList.fromMerchant = true
        let styleFilter = StyleFilter()
        if let merchant = merchant {
            styleFilter.merchants = [merchant]
            topImageView.merchant = merchant
        }
        styleFilter.sort = "DisplayRanking"
        productList.setStyleFilter(styleFilter, isNeedSnapshot: true)
        
        var vcs = [UIViewController]()
        var titles = [String]()
        vcs.append(merchantFeedViewController)
        vcs.append(productList)
        
        titles.append(String.localize("LB_TICKET_TYPE_NEWSFEED"))
        titles.append(String.localize("LB_ALL_PRODUCTS"))
        
        if let merchantBrand = merchantBrand, merchantBrand.brandList.count > 1 {
            let brandList = BrandListViewController()
            brandList.brandIds = merchantBrand.brandList
            brandList.didSelectBrandHandler = { [weak self] brand in
                if let strongSelf = self {
                    let styleFilter = StyleFilter()
                    if let data = strongSelf.merchant {
                        styleFilter.merchants = [data]
                    }
                    styleFilter.brands = [brand]
                    
                    PushManager.sharedInstance.goToPLP(styleFilter: styleFilter, animated: true)
                }
            }
            brandList.scrollViewDidScrollAction = { [weak self] (scrollView) in
                if let strongSelf = self {
                    if strongSelf.currentPageIndex == 2 {
                        strongSelf.contentOffsetY = scrollView.contentOffset.y
                        strongSelf.didScroll(scrollView.contentOffset.y)
                    }
                }
            }
            brandList.parentPage = .merchantProfilePage
            
            vcs.append(brandList)
            titles.append(String.localize("LB_COUPON_SEGMENT_BRAND"))
        }
        
        viewControllers = vcs
        segmentedTitles = titles
        reveal()
        self.containerDelegate = self
        
        view.addSubview(topImageView)
        
        if coupons.count > 0 {
            view.addSubview(merchantCouponView)
            merchantCouponView.datasouces = coupons
            merchantCouponView.claimedCoupon = claimedCoupons
            merchantCouponView.targetType = .MPP
        }
        
        if let merchant = merchant {
            checkMerchant(merchant.merchantId)
            
            if merchant.merchantName.length > 0 {
                AnalyticsManager.sharedManager.recordImpression(authorType: nil,
                                                                brandCode: nil,
                                                                impressionRef: "\(merchant.merchantId)",
                    impressionType: "Merchant",
                    impressionVariantRef: nil,
                    impressionDisplayName: merchant.merchantName,
                    merchantCode: merchant.merchantCode,
                    parentRef: nil,
                    parentType: nil,
                    positionComponent: "HeroImage",
                    positionIndex: nil,
                    positionLocation: "MPP",
                    referrerRef: nil,
                    referrerType: nil,
                    viewKey: self.analyticsViewRecord.viewKey)
            }
        }
    }
    private func didScroll(_ contentOffsetY: CGFloat) {
        let newOffsetY = contentOffsetY
        let offset = newOffsetY * 2.5
        if let navigationController = navigationController as? MmNavigationController {
            navigationController.setNavigationBarVisibility(offset: offset)
        }
        if newOffsetY > 0 {
            if newOffsetY > headMargin - StartYPos {
                segmentedControlView?.frame = CGRect(x: 0, y: StartYPos , width: ScreenWidth, height: SEGMENT_HEIGHT)
                merchantCouponView.frame = CGRect(x: 0, y: StartYPos - MerchantCouponCell.ViewHeight, width: ScreenWidth, height: MerchantCouponCell.ViewHeight)
                topImageView.frame = CGRect(x: 0, y: StartYPos - headMargin, width: ScreenWidth, height: topImageViewHeight)
                
            } else {
                segmentedControlView?.frame = CGRect(x: 0, y: SEGMENT_Y - newOffsetY , width: ScreenWidth, height: SEGMENT_HEIGHT)
                merchantCouponView.frame = CGRect(x: 0, y: SEGMENT_Y - newOffsetY - MerchantCouponCell.ViewHeight, width: ScreenWidth, height: MerchantCouponCell.ViewHeight)
                topImageView.frame = CGRect(x: 0, y: SEGMENT_Y - newOffsetY - headMargin, width: ScreenWidth, height: topImageViewHeight)
            }
            let searchBarMaxY = segmentedControlView?.frame.maxY ?? SEGMENT_Y + SEGMENT_HEIGHT
            pageViewController.view.frame = CGRect(x: 0, y: searchBarMaxY, width: view.frame.size.width, height: ScreenHeight - searchBarMaxY )
        } else {
            segmentedControlView?.frame = CGRect(x: 0, y: SEGMENT_Y - newOffsetY , width: ScreenWidth, height: SEGMENT_HEIGHT)
            merchantCouponView.frame = CGRect(x: 0, y: SEGMENT_Y - newOffsetY - MerchantCouponCell.ViewHeight, width: ScreenWidth, height: MerchantCouponCell.ViewHeight)
            topImageView.frame = CGRect(x: 0, y: 0, width: ScreenWidth, height: topImageViewHeight - newOffsetY)
            
            let searchBarMaxY =  SEGMENT_Y + SEGMENT_HEIGHT
            
            
            pageViewController.view.frame = CGRect(x: 0, y: searchBarMaxY, width: view.frame.size.width, height: view.frame.size.height  - searchBarMaxY )
        }
        let scrollOffsetY = 80.0 - contentOffsetY
        if (scrollOffsetY < 44.0) {
            navigationBarVisibility = .visible
            shareButton?.setImage(UIImage(named: "share_black"), for: UIControlState())
            backButton?.setImage(UIImage(named: "back_grey"), for: .normal)
            serviceButton?.setImage(UIImage(named: "cs_black"), for: .normal)
        } else {
            navigationBarVisibility = .hidden
            shareButton?.setImage(UIImage(named: "fan_share"), for: UIControlState())
            backButton?.setImage(UIImage(named: "back_wht"), for: .normal)
            serviceButton?.setImage(UIImage(named: "service_ic"), for: .normal)
        }
    }
    func initAnalyticLog() {
        if let merchant = self.merchant {
            if merchant.merchantCode.isEmpty {
                CacheManager.sharedManager.merchantById(merchant.merchantId, completion: { [weak self] (merchant) in
                    if let strongMerchant = merchant {
                        self?.merchant = strongMerchant 
                        self?.doAnalyticLog()
                    }
                })
            } else {
                doAnalyticLog()
            }
        }
    }
    func doAnalyticLog() {
        if let merchant = self.merchant {
            initAnalyticsViewRecord(
                merchantCode: merchant.merchantCode,
                viewDisplayName: merchant.merchantName,
                viewLocation: "MPP",
                viewRef: "\(merchant.merchantId)",
                viewType: "Merchant"
            )
        }
    }
    
    //MARK: - lazy
    private lazy var topImageView:BrandAndMerchantHeadView = {
        let topImageView = BrandAndMerchantHeadView(frame: CGRect(x: 0, y: 0, width: ScreenWidth, height: topImageViewHeight))
        topImageView.attentionButton.addTarget(self, action: #selector(onHandleFollow), for: UIControlEvents.touchUpInside)
        let gesture = UITapGestureRecognizer(target: self, action: #selector(onHandleFollow))
        topImageView.attentionLabel.addGestureRecognizer(gesture)
        topImageView.initAnalytics(withViewKey: self.analyticsViewRecord.viewKey)
        topImageView.addGestureRecognizer(UITapGestureRecognizer(target: self, action: #selector(didSelectMerchantProfileView)))
        return topImageView
    }()
    private lazy var merchantCouponView:MerchantCouponCell = {
        let merchantCouponView = MerchantCouponCell(frame: CGRect(x: 0, y: topImageViewHeight, width: ScreenWidth, height: MerchantCouponCell.ViewHeight))
        merchantCouponView.delegate = self
        merchantCouponView.initAnalytics(withViewKey: analyticsViewRecord.viewKey)
        merchantCouponView.positionLocation = "MPP"
        merchantCouponView.targetType = .MPP
        return merchantCouponView
    }()
    
}

extension MerchantViewController: MMNavigationControllerDelegate {
    func preferredNavigationBarVisibility() -> MmFadeNavigationControllerNavigationBarVisibility? {
        return self.navigationBarVisibility
    }
}
