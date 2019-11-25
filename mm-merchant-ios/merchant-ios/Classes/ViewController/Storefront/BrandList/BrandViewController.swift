//
//  BrandViewController.swift
//  storefront-ios
//
//  Created by Leslie Zhang on 2018/6/15.
//  Copyright © 2018年 WWE & CO. All rights reserved.
//

import UIKit
import ObjectMapper

class BrandViewController: MmViewController,ProductListViewControllerDelegate {
    var brand: Brand?
    private let HEADVIEW_HEIGHT:CGFloat = ScreenWidth * 0.4
    private var navigationBarVisibility: MmFadeNavigationControllerNavigationBarVisibility = .hidden {
        didSet {
            UIApplication.shared.statusBarStyle = self.navigationBarVisibility == .visible ? .default : .lightContent
        }
    }
    private let navigationSearchHeight:CGFloat = 35
    
    //MARK: - life cycle
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        
        UIApplication.shared.statusBarStyle = .default
    }
    override func viewDidLoad() {
        super.viewDidLoad()
        
        self.title = nil
        
        if let brandId = ssn_Arguments["brandId"]?.int {
            let brand = Brand()
            brand.brandId = brandId
            self.brand = brand
        } else if let brandId = ssn_Arguments["brandSubDomain"]?.int {//兼容brandId场景
            let brand = Brand()
            brand.brandId = brandId
            self.brand = brand
        } else if let brandSubdomain = ssn_Arguments["brandId"]?.string {
            let brand = Brand()
            brand.brandSubdomain = brandSubdomain
            self.brand = brand
        } else if let brandSubdomain = ssn_Arguments["brandSubDomain"]?.string {
            let brand = Brand()
            brand.brandSubdomain = brandSubdomain
            self.brand = brand
        }

        if let brand = brand {
            fetchBrand(brand:brand)
        }
        
        createNavigationBar()
    }
    
    private func preferredSkuIds() -> [Int]? {
        var ids = [Int]()
        if let brandId = self.brand?.brandId, brandId > 0 {
            if let cartItem = CartSkuModel.selectCartItemBy(brandId: brandId) {
                ids.append(cartItem.skuId)
            } else if let wishlistItem = WishListSkuModel.selectWishlistCartItemBy(brandId: brandId) {
                ids.append(wishlistItem.skuId)
            } else if let pdpHistory = BrowsingHistory.queryLatestBrowsingSkuBy(brandId: brandId) {
                ids.append(pdpHistory.skuId)
            }
            
            return ids.count > 0 ? ids : nil
        }
        
        return nil
    }
    
    //MARK: - service 
    private func fetchBrand(brand:Brand) {
        if brand.brandId > 0 {
            BrandService.view(brand.brandId) { [weak self] (response) in
                if let strongSelf = self {
                    if response.result.isSuccess {
                        if response.response?.statusCode == 200 {
                            if let array = response.result.value as? [[String: Any]], let obj = array.first , let brand = Mapper<Brand>().map(JSONObject: obj) {
                                strongSelf.updateData(brand)
                            }
                        } else {
                            strongSelf.updateData(brand)
                        }
                    }
                } else {
                    ErrorLogManager.sharedManager.recordNonFatalError(withException: .NullPointer)
                }
            }
        } else {
            BrandService.viewBrandBySubdomain(brand.brandSubdomain) { [weak self] (response) in
                if let strongSelf = self {
                    if response.result.isSuccess {
                        if response.response?.statusCode == 200 {
                            if let brands = Mapper<Brand>().mapArray(JSONObject: response.result.value) {
                                if let brand = brands.first {
                                    strongSelf.updateData(brand)
                                }
                            }
                        } else {
                            strongSelf.updateData(brand)
                        }
                    }
                } else {
                    ErrorLogManager.sharedManager.recordNonFatalError(withException: .NullPointer)
                }
            }
        }
    }
    private func checkBrand(_ brandId:Int) {
        guard (LoginManager.getLoginState() == .validUser) else {
            topImageView.follow = false
            return
        }
        RelationshipService.relationshipByBrand(brandId) { [weak self] (response) in
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
    func saveAndDeleteBrand(isSave:Bool)  {
        if let brand = brand{
            if isSave {
                FollowService.saveBrand(brand.brandId) { [weak self] (response) in
                    if let strongSelf = self {
                        if response.response?.statusCode == 200 {
                            brand.followerCount += 1
                            strongSelf.topImageView.follow = true
                            strongSelf.topImageView.brand = brand
                        } else {
                            strongSelf.topImageView.follow = false
                        }
                    }
                    
                }
            } else {
                FollowService.deleteBrand(brand.brandId) { [weak self] (response) in
                    if let strongSelf = self {
                        if response.response?.statusCode == 200 {
                            brand.followerCount -= 1
                            strongSelf.topImageView.follow = false
                            strongSelf.topImageView.brand = brand
                        } else {
                            strongSelf.topImageView.follow = true
                        }
                    }
                }
            }
        }
    }
    
    //MARK: - ProductListViewControllerDelegate
     func productListViewControllerScrollViewDidScroll(_ scrollView: UIScrollView) {
        let offset = scrollView.contentOffset.y * 2.5
        if let navigationController = self.navigationController as? MmNavigationController {
            navigationController.setNavigationBarVisibility(offset: offset)
        }
        let newOffsetY = scrollView.contentOffset.y
        
        if (newOffsetY < 0) {
            topImageView.frame = CGRect(x: 0, y:newOffsetY, width: ScreenWidth, height: HEADVIEW_HEIGHT + -newOffsetY)
        }
        let scrollOffsetY = 80.0 - scrollView.contentOffset.y
        if (scrollOffsetY < 44.0) {
            self.navigationBarVisibility = .visible
            shareButton.setImage(UIImage(named: "share_black"), for: UIControlState())
            backButton.setImage(UIImage(named: "back_grey"), for: .normal)
        } else {
            self.navigationBarVisibility = .hidden
            shareButton.setImage(UIImage(named: "fan_share"), for: UIControlState())
            backButton.setImage(UIImage(named: "back_wht"), for: .normal)
        }
    }
    
    //MARK: - event response
    @objc private func onHandleFollow(_ sender: UIView) {
        guard (LoginManager.getLoginState() == .validUser) else {
            LoginManager.goToLogin()
            return
        }
        if let follow = topImageView.follow {
            if let brand = self.brand {
                var sourceRef = ""
                if follow {
                    sourceRef = "Unfollow"
                    let message = String.localize("LB_CA_PROFILE_COLLECTION_REMOVAL").replacingOccurrences(of: "{0}", with: brand.brandName)
                    Alert.alert(self, title: "", message: message, okActionComplete: { () -> Void in
                        self.saveAndDeleteBrand(isSave: false)
                    }, cancelActionComplete:nil)
                } else {
                    sourceRef = "Follow"
                    saveAndDeleteBrand(isSave: true)
                }
                if brand.brandCode.length > 0 {
                    sender.analyticsViewKey = self.analyticsViewRecord.viewKey
                    sender.recordAction(.Tap, sourceRef: sourceRef, sourceType: .Button, targetRef: brand.brandCode, targetType: .Brand)
                    
                }
            }
        }
    }
    
    @objc private func didSelectMerchantProfileView(_ sender: UIView) {
        if let brand = self.brand {
            let merchantDescriptionVC = MerchantDescriptionViewController()
            merchantDescriptionVC.mode = DescriptionMode.modeBrand
            merchantDescriptionVC.brand = brand
            self.navigationController?.push(merchantDescriptionVC, animated: true)
        }
    }
    
    @objc private func popViewController() {
        self.navigationController?.popViewController(animated: true)
    }
    
    @objc private func searchIconClicked(_ sender: UIView) {
        PushManager.sharedInstance.goToPLP(self.brand?.brandId, brand: self.brand, isSearch: true, noNeedBrandFeed: true, animated: false)
        if let brand = self.brand, brand.brandCode.length > 0 {
            sender.analyticsViewKey = self.analyticsViewRecord.viewKey
            sender.recordAction(.Tap, sourceRef: "Search", sourceType: .Button, targetRef: brand.brandCode, targetType: .Brand)
        }
    }
    
    @objc private func selectShareButton(sender: UIButton) {
        if let brand = self.brand {
            PushManager.sharedInstance.goToShareWithBrandOrMerchant(self.analyticsViewRecord.viewKey, brand: brand)
            if  brand.brandCode.length > 0 {
                sender.analyticsViewKey = self.analyticsViewRecord.viewKey
                sender.recordAction(.Tap, sourceRef: "Share", sourceType: .Button, targetRef: brand.brandCode, targetType: .Brand)
            }
        }
    }
    
    //MARK: - private methods
    private func updateData(_ brandModel:Brand) {
        self.brand = brandModel
//        self.brand = CacheManager.sharedManager.cachedBrandById(brandModel.brandId)
        
        if let brand = brand {
            let styleFilter = StyleFilter()
            
            if brand.brandId > 0 {
                styleFilter.brands = [brand]
            }
            productListViewController.brandId = brand.brandId
            productListViewController.brand = brand
            productListViewController.preferredSkuIds = self.preferredSkuIds()
            
            topImageView.brand = brand
            
            productListViewController.setStyleFilter(styleFilter, isNeedSnapshot: true)
            
            addProductListViewController()
            
            initAnalyticLog()
            
            checkBrand(brand.brandId)
            
            AnalyticsManager.sharedManager.recordImpression(brandCode: brand.brandCode, impressionRef: "\(brand.brandId)", impressionType: "Brand", impressionDisplayName: brand.brandName, positionComponent: "HeroImage", positionLocation: "BPP", viewKey: self.analyticsViewRecord.viewKey)
            topImageView.initAnalytics(withViewKey: self.analyticsViewRecord.viewKey)
            topImageView.analyticsViewKey = self.analyticsViewRecord.viewKey
        }
    }
    private func addProductListViewController() {
        self.view.addSubview(productListViewController.view)
        self.addChildViewController(productListViewController)
        productListViewController.table.addSubview(topImageView)
        productListViewController.view.frame = self.view.bounds
    }
    private func initAnalyticLog() {
            if let brand = self.brand {
                initAnalyticsViewRecord(
                    nil,
                    authorType: nil,
                    brandCode: "\(brand.brandCode)",
                    merchantCode: nil,
                    referrerRef: nil,
                    referrerType: nil,
                    viewDisplayName: brand.brandName,
                    viewParameters: nil,
                    viewLocation: "BPP",
                    viewRef: "\(brand.brandId)",
                    viewType: "Brand"
                )
            }
    }
    override func shouldHaveCollectionView() -> Bool {
        return false
    }
    
    private func createNavigationBar() {
        if let navigationBar = self.navigationController?.navigationBar {
            let customView = UIView(frame: CGRect(x: 0, y: 0, width: navigationBar.width * 0.7, height: navigationSearchHeight))
            customView.layer.cornerRadius = 4
            customView.layer.masksToBounds = true
            customView.backgroundColor = UIColor.imagePlaceholder()
            customView.addGestureRecognizer(UITapGestureRecognizer(target: self, action: #selector(self.searchIconClicked)))
   
            searchButton.frame =  CGRect(x: (customView.width - searchButton.width) / 2, y: (navigationSearchHeight - searchButton.height) / 2, width: searchButton.width, height:searchButton.height)
            customView.addSubview(searchButton)
            
            self.navigationItem.leftBarButtonItems = [UIBarButtonItem(customView: backButton),UIBarButtonItem(customView: customView)]
            self.navigationItem.rightBarButtonItems = [UIBarButtonItem(customView: shareButton)]
        }
    }
    
    //MARK: - lazy
   private lazy var shareButton:UIButton = {
        let shareButton = UIButton(type: .custom)
        shareButton.imageEdgeInsets = UIEdgeInsets(top: 2, left: 2, bottom: 2, right: 2)
        shareButton.setImage(UIImage(named: "fan_share"), for: .normal)
        shareButton.frame = CGRect(x:0,y:0,width: ScreenWidth * 0.094,height:ScreenWidth * 0.094)
        shareButton.tintColor = UIColor.white
        shareButton.contentEdgeInsets = UIEdgeInsetsMake(0, 0, 0, Constants.Value.NavigationButtonMargin)
        shareButton.addTarget(self, action: #selector(selectShareButton), for: .touchUpInside)
        return shareButton
    }()
    private lazy var backButton:UIButton = {
        let backButton: UIButton = UIButton()
        backButton.setImage(UIImage(named: "back_wht"), for: .normal)
        backButton.frame = CGRect(x: 0, y: 0, width: 30, height: 25)
        backButton.contentEdgeInsets = UIEdgeInsets.init(top: 0, left: Constants.Value.BackButtonMarginLeft, bottom: 0, right: 0)
        backButton.addTarget(self, action: #selector(popViewController), for: .touchUpInside)
        return backButton
    }()
    private lazy var topImageView:BrandAndMerchantHeadView = {
        let topImageView = BrandAndMerchantHeadView(frame: CGRect.init(x: 0, y: 0, width: ScreenWidth, height: HEADVIEW_HEIGHT))
        topImageView.addGestureRecognizer(UITapGestureRecognizer(target: self, action: #selector(self.didSelectMerchantProfileView)))
        topImageView.attentionButton.addTarget(self, action: #selector(onHandleFollow), for: UIControlEvents.touchUpInside)
        return topImageView
    }()
    private lazy var productListViewController:ProductListViewController = {
        let productListViewController = ProductListViewController()
        productListViewController.noNeedBrandFeed = true
        productListViewController.headView = topImageView
        productListViewController.delegate = self
        return productListViewController
    }()
    private lazy var searchButton:UIButton = {
        let searchButton = UIButton()
        searchButton.isUserInteractionEnabled = false
        searchButton.setTitle(String.localize("LB_CA_SEARCH_IN_BRAND"), for: UIControlState.normal)
        searchButton.setImage(UIImage(named: "search"), for: UIControlState.normal)
        searchButton.titleLabel?.font = UIFont.systemFont(ofSize: 12)
        searchButton.setTitleColor(UIColor(hexString: "#BCBCBC"), for: UIControlState.normal)
        searchButton.setIconInLeftWithSpacing(6)
        searchButton.sizeToFit()
        return searchButton
    }()
}

extension BrandViewController: MMNavigationControllerDelegate {
    func preferredNavigationBarVisibility() -> MmFadeNavigationControllerNavigationBarVisibility? {
        return self.navigationBarVisibility
    }
}
