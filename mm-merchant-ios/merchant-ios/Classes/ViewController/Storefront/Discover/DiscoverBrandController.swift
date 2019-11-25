//
//  DiscoverBrandController.swift
//  merchant-ios
//
//  Created by Alan YU on 6/3/2016.
//  Copyright © 2016 WWE & CO. All rights reserved.
//

import Foundation
import PromiseKit
import ObjectMapper
import Alamofire

class DiscoverBrandController: MmViewController, BannerCellDelegate {
    
    private enum LayoutSectionKey: Int {
        case featuredBrands     = 0
        case recommendHeader    = 1
        case recommendBrands    = 2
    }
    
    private var featureBrandImages: [String]!
    private var brandImages: [String]!
    private var brands = [BrandUnionMerchant]()
    private var discoverBannerList = [Banner]()
    private var featuredCollectionViewHeight: CGFloat = 0
    private var recommendHeaderView: UIView!
    
    private final let RecommendHeaderViewHeight: CGFloat = 58
    private final let RecommendHeaderCellId = "RecommendHeaderCellId"
    private final let RecommendBrandsCellId = "RecommendBrandsCellId"
    
    private final let DefaultCellId = "DefaultCellId"
    
    private var canLoadMore = true
    private var isLoadingMoreBrands = false
    private var pageNo = 1
    private var shouldReloadData = true
    var viewHeight: CGFloat = 0

    private var loadingDelayAction: DelayAction?
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        setupCollectionView()
        setupRecommendHeaderView()
        NotificationCenter.default.addObserver(self, selector: #selector(self.feedViewData), name: NSNotification.Name(rawValue: kReachabilityNetworkConnected), object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(self.feedViewData), name: NSNotification.Name.UIApplicationWillEnterForeground, object: nil)
        initAnalyticLog()
        collectionView.reloadData()
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        
        self.navigationItem.setHidesBackButton(true, animated: false)
        NotificationCenter.default.addObserver(self, selector: #selector(self.loadBrandData), name: NSNotification.Name(rawValue: kReachabilityNetworkConnected), object: nil)
        
        self.feedAllData()
        self.navigationController?.isNavigationBarHidden = true
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        self.navigationController?.isNavigationBarHidden = false
    }
    
    override func viewWillLayoutSubviews() {
        super.viewWillLayoutSubviews()
        
        if let noConnectionView = self.noConnectionView {
            let viewSize = CGSize(width: self.view.width, height: 198)
            noConnectionView.frame = CGRect(x: 0, y: (self.view.height - viewSize.height) / 2.0, width: viewSize.width, height: viewSize.height)
        }
    }
    
    func setupCollectionView() {
        collectionView.register(ImageCollectCell.self, forCellWithReuseIdentifier: RecommendBrandsCellId)
        collectionView.register(UICollectionViewCell.self, forCellWithReuseIdentifier: RecommendHeaderCellId)
        collectionView.register(UICollectionViewCell.self, forCellWithReuseIdentifier: DefaultCellId)
        collectionView.register(BannerCell.self, forCellWithReuseIdentifier: BannerCell.CellIdentifier)
        
        collectionView.frame = self.view.bounds
        
        if viewHeight > 0 {
            collectionView.height = viewHeight
        }
    }
    
    func setupRecommendHeaderView() {
        let width = view.bounds.width
        let arrowWidth: CGFloat = 7
        let padding: CGFloat = 12
        
        recommendHeaderView = UIView(frame: CGRect(x: 0, y: 0, width: width, height: RecommendHeaderViewHeight))
        
        let recommendLabel = UILabel()
        recommendLabel.text = String.localize("LB_AC_CAMPAIGN_SOURCE_MEDIUM_REFERRAL")
        if let font = UIFont(name: "PingFangTC-Regular", size: 16){
            recommendLabel.font = font
        }
        recommendLabel.textColor = UIColor.black
        recommendLabel.sizeToFit()
        recommendLabel.frame = CGRect(x: padding, y: 0, width: recommendLabel.bounds.width, height: RecommendHeaderViewHeight)
        
        recommendHeaderView.addSubview(recommendLabel)
        
        let arrowImageView = UIImageView(frame: CGRect(x: width - padding - arrowWidth, y: 0, width: arrowWidth, height: RecommendHeaderViewHeight))
        arrowImageView.image = UIImage(named: "icon_arrow")
        arrowImageView.contentMode = .scaleAspectFit
        recommendHeaderView.addSubview(arrowImageView)
        
        let allLabel = UILabel()
        allLabel.text = String.localize("LB_CA_ALL")
        if let font = UIFont(name: "PingFangTC-Regular", size: 14){
            allLabel.font = font
        }
        allLabel.textColor = UIColor.secondary2()
        allLabel.sizeToFit()
        allLabel.frame = CGRect(x: arrowImageView.frame.minX - padding - allLabel.optimumWidth(), y: 0, width: allLabel.optimumWidth(), height: RecommendHeaderViewHeight)
        recommendHeaderView.addSubview(allLabel)
        
        let brandMerchantButton = UIButton(type: .custom)
        brandMerchantButton.frame = CGRect(x: width - 66, y: 0, width: 66, height: RecommendHeaderViewHeight)
        brandMerchantButton.backgroundColor = UIColor.clear
        brandMerchantButton.addTarget(self, action: #selector(DiscoverBrandController.showListBrandMerchant), for: .touchUpInside)
        recommendHeaderView.addSubview(brandMerchantButton)
    }
    
    // MARK: - Data Processing
    
    @objc func feedViewData() {
        //Allow reload data when the phone back to online
        shouldReloadData = true
        isLoadingMoreBrands = false
        
        if self.viewIsAppearing {
            self.feedAllData()
        }
    }
    
    func feedAllData() {
        self.collectionView.isHidden = (self.brands.count == 0)
        
        self.dismissNoConnectionView()
        
        if Reachability.shared().currentReachabilityStatus() == NotReachable {
            self.dismissNoConnectionView()
            self.showLoading()
            self.loadingDelayAction = DelayAction(delayInSecond: 2.0, actionBlock: { [weak self] in
                if let strongSelf = self{
                    DispatchQueue.main.async(execute: {
                        strongSelf.stopLoading()
                        strongSelf.handleNoNetworkConnection()
                    })
                }
                else{
                    ErrorLogManager.sharedManager.recordNonFatalError(withException: .NullPointer)
                }
                })
            
            return
        }

        
        loadBrandData()
        loadBannerData()

    }
    
    func handleNoNetworkConnection(){
        self.collectionView.isHidden = (self.brands.count == 0)
        
        if self.brands.count == 0{
            self.showNoConnectionView()
            
            if let noConnectionView = self.noConnectionView{
                self.view.bringSubview(toFront: noConnectionView)
                noConnectionView.reloadHandler = { [weak self] in
                    if let strongSelf = self {
                        strongSelf.feedAllData()
                    }
                    else{
                        ErrorLogManager.sharedManager.recordNonFatalError(withException: .NullPointer)
                    }
                }
            }
        }
    }
    
    override func refresh() {
        shouldReloadData = true
        isLoadingMoreBrands = false
        self.feedAllData()
    }
    
    func loadMore() {
        if self.isLoadingMoreBrands{
            return
        }
        
        self.isLoadingMoreBrands = true
        
        firstly {
            return self.searchBrand(self.pageNo + 1)
        }.then { [weak self] _ -> Void in
            if let strongSelf = self {
                strongSelf.reloadAllData()
                strongSelf.isLoadingMoreBrands = false
            }
        }.catch { [weak self] _ -> Void in
            Log.error("error")
            
            if let strongSelf = self {
                strongSelf.isLoadingMoreBrands = false
            }
        }
    }
    
    func reloadAllData() {
        collectionView.reloadData()
    }
    
    @objc func loadBrandData() {
        if !shouldReloadData {
            return
        }
        
        canLoadMore = true
        
        firstly {
            return self.searchBrand(1)
        }.then { [weak self] _ -> Void in
            if let strongSelf = self {
                strongSelf.shouldReloadData = false
                
                strongSelf.reloadAllData()
                
                strongSelf.collectionView.isHidden = (strongSelf.brands.count == 0)
                
                if strongSelf.brands.count > 0 {
                    strongSelf.dismissNoConnectionView()
                }
                
                strongSelf.collectionView.scrollsToTop = true
            }
        }.catch { _ -> Void in
            Log.error("error")
        }
    }
    
    func loadBannerData(){
        if !shouldReloadData {
            return
        }
        
        firstly {
            return BannerService.fetchBanners([.discover])
        }.then { [weak self] banners -> Void in
            if let strongSelf = self {
                strongSelf.discoverBannerList = banners
                strongSelf.reloadAllData()
            }
        }.catch { [weak self] _ -> Void in
            Log.debug("error")
            
            if let strongSelf = self {
                strongSelf.handleNoNetworkConnection()
            }
        }
        
    }
    
    func searchBrand(_ pageNo: Int) -> Promise<Any> {
        return Promise{ fulfill, reject in
            SearchService.searchBrandCombined(pageNo: pageNo, sort: "Priority", order: "desc") { [weak self] (response) in
                if let strongSelf = self {
                    if response.result.isSuccess {
                        background_async {
                            var brands = Mapper<BrandUnionMerchant>().mapArray(JSONObject: response.result.value) ?? []
                            strongSelf.pageNo = pageNo
                            brands = brands.filter({$0.entityId != 0})
                            
                            if pageNo == 1 {
                                strongSelf.brands = brands
                            } else {
                                for brand in brands {
                                    strongSelf.brands.append(brand)
                                }
                            }
                            
                            strongSelf.canLoadMore = (brands.count > 0)
                            main_async {
                                fulfill("OK")
                            }

                        }
                        
                    } else {
                        reject(response.result.error ?? NSError(domain: "", code: 0, userInfo: nil))
                    }
                } else {
                    ErrorLogManager.sharedManager.recordNonFatalError(withException: .NullPointer)
                }
            }
        }
    }
    
    func searchForBrandUnionMerchant(_ item: BrandUnionMerchant?) {
        if let brandUnionMerchant = item {
            if brandUnionMerchant.entity == "Merchant" {
                let merchant = Merchant()
                merchant.merchantId = brandUnionMerchant.entityId
                merchant.merchantName = brandUnionMerchant.name
                merchant.merchantNameInvariant = brandUnionMerchant.nameInvariant
                
                Navigator.shared.dopen(Navigator.mymm.website_merchant_merchantId + "\(merchant.merchantId)")
            } else {
                let brand = Brand()
                brand.brandId = brandUnionMerchant.entityId
                brand.brandName = brandUnionMerchant.name
                
                let brandViewController = BrandViewController()
                brandViewController.brand = brand
                self.navigationController?.push(brandViewController, animated: true)
            }
        } else {
            ErrorLogManager.sharedManager.recordNonFatalError(withException: .NullPointer)
        }
    }
    
    @objc func showListBrandMerchant(_ sender: UIButton) {
        let listMerchantController = ListMerchantController()
        self.navigationController?.push(listMerchantController, animated: true)
        
        sender.recordAction(.Tap, sourceRef: "All", sourceType: .Button, targetRef: "AllBrands", targetType: .View)
    }
    
    //MARK: - Override
    
    override func showLoading(){
        self.showLoadingInScreenCenter()
    }
    
    override func handleError(_ response : DataResponse<Any>, animated: Bool, reject : ((Error) -> Void)? = nil) {
        if let resp = Mapper<ApiResponse>().map(JSONObject: response.result.value){
            self.handleError(resp, statusCode: response.response!.statusCode, animated: true, reject: reject)
        } else {
            if let error = response.result.error as NSError?, error.code != -1009{
                self.showError(
                    Utils.formatErrorMessage(
                        String.localize("LB_ERROR"),
                        error: response.result.error
                    )
                    ,animated: animated
                )
            }
            
            if let reject = reject {
                reject(getError(response))
            }
        }
    }
    
    //MARK: - Collection Delegate
    
    func numberOfSections(in collectionView: UICollectionView) -> Int {
        if collectionView == self.collectionView {
            return 3
        }
        
        return 0
    }
    
    override func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        if collectionView == self.collectionView {
            if let layoutSectionKey = LayoutSectionKey(rawValue: section) {
                if layoutSectionKey == .recommendBrands {
                    return brands.count
                }
            } else {
                ErrorLogManager.sharedManager.recordNonFatalError(withException: .IndexOutOfBounds)
                return 0
            }
            
            return 1
        }
        
        return 0
    }
    
    override func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        var resultCell: UICollectionViewCell!
        
        if collectionView == self.collectionView {
            if let layoutSectionKey = LayoutSectionKey(rawValue: indexPath.section) {
                switch layoutSectionKey {
                case .featuredBrands:
                    let cell = collectionView.dequeueReusableCell(withReuseIdentifier: BannerCell.CellIdentifier, for: indexPath) as! BannerCell
                    cell.delegate = self
                    cell.bannerList = self.discoverBannerList
                    cell.disableScrollToTop()
                    cell.showOverlay(false)
                    cell.analyticsViewKey = self.analyticsViewRecord.viewKey
                    cell.positionLocation = "BrowseByBrand"
                    resultCell = cell
                case .recommendHeader:
                    recommendHeaderView.removeFromSuperview()
                    
                    resultCell = collectionView.dequeueReusableCell(withReuseIdentifier: RecommendHeaderCellId, for: indexPath)
                    resultCell.addSubview(recommendHeaderView)
                case .recommendBrands:
                    let cell = collectionView.dequeueReusableCell(withReuseIdentifier: RecommendBrandsCellId, for: indexPath) as! ImageCollectCell
                    let brand = self.brands[indexPath.row]
                    
                    cell.setImage(brand.largeLogoImage, category: brand.imageCategory, size: .size512)
                    cell.filter.alpha = 0
                    
                    if indexPath.row == self.brands.count - 1 && canLoadMore {
                        canLoadMore = false
                        self.loadMore()
                    } else {
                        cell.analyticsViewKey = self.analyticsViewRecord.viewKey
                        
                        if let viewKey = cell.analyticsViewKey {
                            var impressionType = "Brand"
                            
                            if brand.entity == "Merchant" {
                                impressionType = "Merchant"
                            }
                            
                            cell.initAnalytics(withViewKey: viewKey, impressionKey: AnalyticsManager.sharedManager.recordImpression(brandCode: brand.brandCode,impressionRef: "\(brand.entityId)", impressionType: impressionType, impressionDisplayName: brand.name, merchantCode: brand.merchantCode, positionComponent: "BrandListing", positionIndex: indexPath.row + 1, positionLocation: "BrowseByBrand", viewKey: viewKey))
                        } else {
                            ErrorLogManager.sharedManager.recordNonFatalError(withException: .NullPointer)
                        }
                    }
                    
                    resultCell = cell
                }
            } else {
                ErrorLogManager.sharedManager.recordNonFatalError(withException: .IndexOutOfBounds)
                
                resultCell = collectionView.dequeueReusableCell(withReuseIdentifier: DefaultCellId, for: indexPath)
            }
        } else {
            collectionView.register(UICollectionViewCell.self, forCellWithReuseIdentifier: DefaultCellId)
            
            resultCell = collectionView.dequeueReusableCell(withReuseIdentifier: DefaultCellId, for: indexPath)
        }
        
        return resultCell
    }
    
    func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        if collectionView == self.collectionView {
            
            if let layoutSectionKey = LayoutSectionKey(rawValue: indexPath.section) {
                switch layoutSectionKey {
                case .recommendBrands:
                    let brand = self.brands[indexPath.row]
                    self.searchForBrandUnionMerchant(brand)
                    
                    if let cell = collectionView.cellForItem(at: indexPath) {
                        var sourceType = AnalyticsActionRecord.ActionElement.Brand
                        
                        if brand.entity == "Merchant" {
                            sourceType = AnalyticsActionRecord.ActionElement.Merchant
                        }
                        
                        cell.recordAction(.Tap, sourceRef: "\(brand.entityId)", sourceType: sourceType, targetRef: "PLP", targetType: .View)
                    } else {
                        ErrorLogManager.sharedManager.recordNonFatalError(withException: .NullPointer)
                    }
                default:
                    break
                }
            } else {
                ErrorLogManager.sharedManager.recordNonFatalError(withException: .IndexOutOfBounds)
            }
        }
    }
    
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, minimumInteritemSpacingForSectionAt section: Int) -> CGFloat {
        return 0.0
    }
    
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, minimumLineSpacingForSectionAt section: Int) -> CGFloat {
        if collectionView == self.collectionView && section == LayoutSectionKey.recommendBrands.rawValue {
            return 8
        }
        return 0.0
    }
    
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, insetForSectionAt section: Int) -> UIEdgeInsets {
        return getSectionInsets(collectionView, section: section)
    }
    
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, sizeForItemAt indexPath: IndexPath) -> CGSize {
        if collectionView == self.collectionView {
            if let layoutSectionKey = LayoutSectionKey(rawValue: indexPath.section) {
                switch layoutSectionKey {
                case .featuredBrands:
                    featuredCollectionViewHeight = view.width * Constants.Ratio.PanelImageHeight
                    
                    return CGSize(width: view.width, height: featuredCollectionViewHeight)
                case .recommendHeader:
                    if let recommendHeaderView = recommendHeaderView {
                        return recommendHeaderView.bounds.size
                    } else {
                        ErrorLogManager.sharedManager.recordNonFatalError(withException: .NullPointer)
                        
                        return CGSize.zero
                    }
                case .recommendBrands:
                    let sectionInsets = getSectionInsets(collectionView, section: indexPath.section)
                    let width = (view.width - sectionInsets.left - sectionInsets.right - 8) / 2
                    return CGSize(width: width, height: width)
                }
            } else {
                ErrorLogManager.sharedManager.recordNonFatalError(withException: .IndexOutOfBounds)
            }
        }
        
        return CGSize.zero
    }
    
    func collectionView(_ collectionView: UICollectionView, didEndDisplayingCell cell: UICollectionViewCell, forItemAtIndexPath indexPath: IndexPath) {
        //Turn off the timer to avoid crashing if banner cell is disappeared
        if let bannerCell = cell as? BannerCell {
            bannerCell.isAutoScroll = false
        }
    }
    
    // MARK: - Banner Cell Delegate
    
    func didSelectBanner(_ banner: Banner) {
        if banner.link.contains(Constants.MagazineCoverList) {
            // open as magazine cover list
            if LoginManager.isLoggedInErrorPrompt() {
                let magazineCollectionViewController = MagazineCollectionViewController()
                self.navigationController?.push(magazineCollectionViewController, animated: true)
            }
        } else {
            Navigator.shared.dopen(banner.link)
        }
    }
    
    // MARK: Logging
    
    func initAnalyticLog() {
        initAnalyticsViewRecord(
            nil,
            authorType: nil,
            brandCode: nil,
            merchantCode: nil,
            referrerRef: nil,
            referrerType: nil,
            viewDisplayName: "User: \(Context.getUserProfile().userName)",
            viewParameters: "u=\(Context.getUserProfile().userKey)",
            viewLocation: "BrowseByBrand",
            viewRef: nil,
            viewType: "Brand"
        )
    }
    
    // MARK: - Helpers
    
    private func getSectionInsets(_ collectionView: UICollectionView, section: Int) -> UIEdgeInsets{
        if collectionView == self.collectionView && section == LayoutSectionKey.recommendBrands.rawValue {
            return UIEdgeInsets(top: Constants.Margin.Top, left: 14, bottom: Constants.Margin.Bottom, right: 14)
        }
        return UIEdgeInsets.zero
    }
}
