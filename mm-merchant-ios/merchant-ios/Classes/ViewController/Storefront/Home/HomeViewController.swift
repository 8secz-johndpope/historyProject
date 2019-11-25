//
//  HomeViewController.swift
//  merchant-ios
//
//  Created by Koon Kit Chan on 18/11/15.
//  Copyright © 2015 Koon Kit Chan. All rights reserved.
//

import Foundation
import PromiseKit
import ObjectMapper
import Refresher

class HomeViewController : MmViewController, BannerCellDelegate, HorizontalImageCellDelegate, HomeFooterViewDelegate, ShortcutBannerCellDelegate, BrandImageCellDelegate {
    
    private final let DefaultCellID = "DefaultCellID"
    private let MockupCellIdentifier = "MockupCellIdentifier"
    private let LoadingCellIdentifier = "LoadingCellIdentifier"
    private final let OffsetAllowance = CGFloat(5)
    private final let HeaderViewIdentifier = "HeaderViewIdentifier"
    
    //Please don't change the order of the list below if not neccessary
    //Refer reloadDataSource() for more detail
    enum HomeSectionType: Int {
        case newsfeedBannerSection = 0 //this section only 1 at top of list
        case shortcutBannerSection = 1
        case promotionSection = 2
        case magazineBannerSection = 3
        case brandsSection = 4
        case categoriesSection = 5
        case productBannerSection = 8
    }
    
    // BannerCell
    private var generalBannerCell: BannerCell?
    private var magazineBannerCell: BannerCell?
    
    // Data Source
    private var sectionList = [HomeSectionType]()
    private var newsfeedBannerList = [Banner]()
    private var shortcutBannerList = [Banner]()
    private var magazineBannerList = [Banner]()
    private var productBannerList = [Banner]()
    
    private var merchantList = [Merchant] ()

    private var gridBanners = [Banner]()
    private var categoriesList = [Cat]()

    private var isPresentingViewController = false
    
    private var reloadNewsFeedBannersData = true
    
    var paidOrder: ParentOrder?
    

	
	var searchLabelTitle : UILabel!
    
    //Pull to refresh
    var customPullToRefreshView: PullToRefreshUpdateView?
    //private var canShowCampaign = false
    private var isUpdatingNewFeeds = false
    private final let BannerGridViewCellIdentifier = "BannerGridViewCell"
    private var isFirstStart = true
    private var user : User?
    private var isRefreshing: Bool = false
    private var searchButton = UIButton()
    private var viewTitle: UIView?
    
    func showThankYouPage(){
        let thankYouViewController = ThankYouViewController()
        thankYouViewController.fromViewController = self
        thankYouViewController.parentOrder = paidOrder
        let navigationController = MmNavigationController(rootViewController: thankYouViewController)
        navigationController.modalPresentationStyle = .overFullScreen
        thankYouViewController.handleDismiss = {
        }
        self.present(navigationController, animated: true, completion: nil)
        self.stopLoad()
    }
    
    
    private var lastPositionY = CGFloat(0)
    override func viewDidLoad() {
        super.viewDidLoad()
        
        NotificationCenter.default.addObserver(self, selector: #selector(self.controllerBackFromForeground), name: NSNotification.Name.UIApplicationWillEnterForeground, object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(self.appGettingLogout), name: Constants.Notification.userLoggedOut, object: nil)
//        title = String.localize("LB_CA_NEWSFEED")
        view.backgroundColor = UIColor.white
        self.createBackButton()
        setupNavigationBar()
        setupCollectionView()

        self.showLoad()
        self.reloadDataSource()
        initAnalyticLog()

    }
    
    @objc func appGettingLogout() {
        isFirstStart = true
    }
    
    @objc func controllerBackFromForeground() {
        hasFetchedDataWhenAppear = false
        
        if self.viewIsAppearing {
            reloadDataWhenResume()
        }
        
    }
    
    // refresh called when view will appear or back from background
    private func reloadDataWhenResume(){
        
        if !hasFetchedDataWhenAppear {
            
            _ = self.loadBannersData()
            _ = self.loadProductBanner()
            _ = self.loadFeaturedMerchantData()
            hasFetchedDataWhenAppear = true
        } else {
            self.collectionView.reloadData()
        }
        
    }
    
    var hasFetchedDataWhenAppear = false
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        
        NotificationCenter.default.addObserver(self, selector: #selector(self.startAllAnimations), name: NSNotification.Name.UIApplicationWillEnterForeground, object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(self.stopAllAnimations), name: NSNotification.Name.UIApplicationDidEnterBackground, object: nil)
        
        startAllAnimations()
        
        reloadDataWhenResume()
        
        if isFirstStart == true{

            isFirstStart = false
        }
        
    }

    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        updateButtonCartState()
        updateButtonWishlistState()
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        stopAllAnimations()
        NotificationCenter.default.removeObserver(self, name: NSNotification.Name.UIApplicationDidEnterBackground, object: nil)
        NotificationCenter.default.removeObserver(self, name: NSNotification.Name.UIApplicationUserDidTakeScreenshot, object: nil)
        isPresentingViewController = false
    }
    
    // MARK: - Set up
    
    private func setupCollectionView() {
        collectionView.backgroundColor = UIColor.feedCollectionViewBackground()
        collectionView.register(UICollectionViewCell.self, forCellWithReuseIdentifier: self.DefaultCellID)
        collectionView.register(BannerCell.self, forCellWithReuseIdentifier: BannerCell.CellIdentifier)
        collectionView.register(HorizontalImageCell.self, forCellWithReuseIdentifier: HorizontalImageCell.CellIdentifier)
        collectionView.register(CuratorsCell.self, forCellWithReuseIdentifier: CuratorsCell.CellIdentifier)
        collectionView.register(FeatureBrandImageCell.self, forCellWithReuseIdentifier: FeatureBrandImageCell.CellIdentifier)
        collectionView.register(BannerGridViewCell.self, forCellWithReuseIdentifier: BannerGridViewCellIdentifier)
        collectionView.register(ProductBannerGroupCell.self, forCellWithReuseIdentifier: ProductBannerGroupCell.CellIdentifier)
        
        
        collectionView.register(HomeHeaderView.self, forSupplementaryViewOfKind: UICollectionElementKindSectionHeader, withReuseIdentifier: HeaderViewIdentifier)
        collectionView.register(HomeFooterView.self, forSupplementaryViewOfKind: UICollectionElementKindSectionFooter, withReuseIdentifier: HomeFooterView.FooterIdentifier)
        
        
        self.collectionView.register(FeatureCollectionCell.self, forCellWithReuseIdentifier: FeatureCollectionCell.CellIdentifier)
        configCollectionView()
        collectionView.register(ShortcutBannerCell.self, forCellWithReuseIdentifier: ShortcutBannerCell.CellIdentifier)
    }
    
    private func setupNavigationBar() {
        setupNavigationBarCartButton()
//        setupNavigationBarWishlistButton()
        
        buttonCart?.addTarget(self, action: #selector(self.goToShoppingCart), for: .touchUpInside)
//        buttonWishlist?.addTarget(self, action: #selector(self.goToWishList(_:)), for: .touchUpInside)
        
        buttonCart?.accessibilityIdentifier = "view_cart_button"
        buttonWishlist?.accessibilityIdentifier = "view_wishlist_button"
//
//        buttonCart?.setImage(UIImage(named: "shop"), for: UIControlState())
//        buttonWishlist?.setImage(UIImage(named: "heart"), for: UIControlState())

        if let btnCart = buttonCart {
            self.navigationItem.rightBarButtonItems = [UIBarButtonItem(customView: btnCart)]
        }
        
        self.setupNavigationBarSearchButton()
    }
    
    func setupNavigationBarSearchButton() {
        let ButtonHeight = CGFloat(25)
        let ButtonWidth = CGFloat(30)
        
        searchButton.frame = CGRect(x: 0, y: 0, width: ButtonWidth, height: ButtonHeight)
        searchButton.contentEdgeInsets = UIEdgeInsets(top: 0, left: 0, bottom: 0, right: 10)
        searchButton.setImage(UIImage(named: "search_grey"), for: UIControlState())
        searchButton.accessibilityIdentifier = "discover_search_button"
        searchButton.addTarget(self, action: #selector(HomeViewController.searchIconClicked), for: UIControlEvents.touchUpInside)
        let leftBarButton = UIBarButtonItem(customView: searchButton)
        
        self.navigationItem.leftBarButtonItems?.append(leftBarButton)
        
        if viewTitle == nil {
            let view = UIView()
            view.frame = CGRect(x: 50, y: 0, width: self.view.bounds.maxX * 2 / 3, height: 32.5)
            
            let searchBtn = UIButton(type: UIButtonType.custom)
            searchBtn.frame = view.bounds
            searchBtn.accessibilityIdentifier = "discover_search_button"
            searchBtn.addTarget(self, action: #selector(HomeViewController.searchIconClicked), for: UIControlEvents.touchUpInside)
            
            view.addSubview(searchBtn)
            
            let searchBarImage = UIImageView(image: UIImage(named: "search_bar_no_scan"))
            searchBarImage.frame = CGRect(x: 0, y: 0, width: view.bounds.maxX, height: searchBarImage.bounds.maxY * view.bounds.maxX / searchBarImage.bounds.maxX)
            searchBtn.addSubview(searchBarImage)
            
            searchLabelTitle = UILabel(frame: CGRect(x: 30, y: 0, width: view.bounds.maxX - 55, height: searchBarImage.frame.size.height))
            searchLabelTitle.text = String.localize("LB_CA_SEARCH_PLACEHOLDER")
            searchLabelTitle.textColor = UIColor.secondary4()
            searchLabelTitle.font = UIFont.systemFont(ofSize: 14.0)
            searchBtn.addSubview(searchLabelTitle)
            
            self.viewTitle = view
        }
        
    }
    
    private func configCollectionView() {
        self.collectionView.delegate = self
        self.collectionView.dataSource = self
        self.collectionView.frame = CGRect(x: 0 , y: 0, width: self.view.bounds.width, height: self.view.bounds.height)
        
        self.collectionView.register(UICollectionViewCell.self, forCellWithReuseIdentifier: LoadingCellIdentifier)
        self.collectionView.register(UICollectionViewCell.self, forCellWithReuseIdentifier: MockupCellIdentifier)
        
        let animator = MMRefreshAnimator(frame: CGRect(x: 0, y: 0, width: self.collectionView.frame.width, height: 80))
        
        self.collectionView.addPullToRefreshWithAction({ [weak self] in
            if let strongSelf = self {
                strongSelf.refresh()
            }
            }, withAnimator: animator)

    }
    
    override func scrollToTop() {
        if !isRefreshing {
            if self.collectionView != nil {
                self.collectionView.stopScrolling()
                self.collectionView.startPullToRefresh()
                self.refresh()
            }
        }
    }
    
    // explicity trigger refresh by pull to refresh / tab bar
    override func refresh() {
        self.isRefreshing = true
        self.hasFetchedDataWhenAppear = false
        var promises : [Promise<Void>] = []
        
        promises.append(self.loadBannersData().asVoid())
        promises.append(self.loadProductBanner().asVoid())
        promises.append(self.loadFeaturedMerchantData().asVoid())
        when(fulfilled: promises).then { _ -> Void in
            self.isRefreshing = false
            self.collectionView.stopPullToRefresh()
            }.catch { (error) in
                self.collectionView.stopPullToRefresh()
                self.isRefreshing = false
                print(error)
            }
    }
    
    // MARK: - Views And Actions
    
    @objc func searchIconClicked() {
        let searchViewController = ProductListSearchViewController()
        self.navigationController?.pushViewController(searchViewController, animated: false)
    }
    
    @objc func startAllAnimations() {
        
        if !self.viewIsAppearing {
            return
        }
        
        generalBannerCell?.reset()
        magazineBannerCell?.reset()
        
    }
    
    @objc func stopAllAnimations() {
        generalBannerCell?.isAutoScroll = false
        magazineBannerCell?.isAutoScroll = false
        
        
    }

    
    private func loadBannersData() -> Promise<Any> {

        return Promise{ fulfill, reject in
            firstly {
                return BannerService.fetchBanners([.newsFeed, .gridBanner, .redZoneShortcut, .redZoneProduct], loadFromCache: false)
                }.then {  banners -> Void in
                    
                    self.newsfeedBannerList = banners.filter{ $0.collectionType == .newsFeed }
                    self.gridBanners = banners.filter{ $0.collectionType == .gridBanner }
                    self.shortcutBannerList = banners.filter{ $0.collectionType == .redZoneShortcut }
                    
                    self.reloadCollectionView()
                    fulfill("OK")
                    
                }.catch { _ in
                    self.stopLoad()
                    Log.error("error @ loadBannersData")
                    let error = NSError(domain: "", code: 0, userInfo: nil)
                    reject(error)
            }
        }
    }
    
    
    private func loadProductBanner() -> Promise<Any> {
        
        return Promise{ fulfill, reject in
            
            BannerService.fetchBanners([.redZoneProduct], loadFromCache: false).then {  banners -> Void in
                
                self.productBannerList = banners.filter{ $0.collectionType == .redZoneProduct }
                
                let skuItems = banners.flatMap({ $0.skuList })
                let groupSkuIds = skuItems.map({ String($0.skuID) }).split(Constants.Paging.SkuSearchLimit)
                
                var promises : [Promise<[Style]>] = []
                
                for skuIds in groupSkuIds {
                    promises.append(ProductManager.searchStyleWithSkuIds(skuIds.joined(separator: ",")))
                }
                
                self.reloadCollectionView()
                
                when(fulfilled: promises).then { stylesGroups -> Void in
                    let styles = stylesGroups.flatMap({ $0 })
                    
                    for banner in self.productBannerList {
                        for i in 0..<banner.skuList.count {
                            
                            if let index = styles.index(where: { (style) -> Bool in
                                return style.skuList.contains(where: { $0.skuId == banner.skuList[i].skuID })
                            }) {
                                banner.skuList[i].style = styles[index]
                            }
                        }
                    }
                    self.reloadCollectionView()
                    fulfill("OK")
                }
                
            }.catch { _  in
                self.stopLoad()
                Log.error("error @ loadProductBanner")
                let error = NSError(domain: "", code: 0, userInfo: nil)
                reject(error)
            }
        }
        
    }
    
    private func loadFeaturedMerchantData() -> Promise<Any> {
        return Promise{ fulfill, reject in
            firstly {
                return self.searchMerchant()
            }.then { _ -> Void in
                self.reloadCollectionView()
                fulfill("OK")
            }.catch { _ -> Void in
                self.stopLoad()
                Log.error("error @ loadFeaturedMerchantData")
                let error = NSError(domain: "", code: 0, userInfo: nil)
                reject(error)
            }
            
        }
    }
    
    
    
    
    func searchMerchant() -> Promise<Any> {
        return Promise { fulfill, reject in
            
            
            MerchantService.fetchMerchantsIfNeeded(.featuredRedZone).then { [weak self] (merchants) -> Void in
                if let strongSelf = self {
                    strongSelf.merchantList = Array(merchants.prefix(Constants.Value.MaximumDisplayingMerchantFeatures))
                }
                
                fulfill("OK")
            }.catch { (error) -> Void in
                reject(error)
            }
        }
    }
    
    func searchForBrandUnionMerchant(brand: BrandUnionMerchant?) {
        let styleFilter = StyleFilter()
        if let brandUnionMerchant = brand {
            if brandUnionMerchant.entity == "Merchant" {
                let merchant = Merchant()
                merchant.merchantId = brandUnionMerchant.entityId
                merchant.merchantName = brandUnionMerchant.name
                merchant.merchantNameInvariant = brandUnionMerchant.nameInvariant
                styleFilter.merchants = [merchant]
            } else {
                let brand = Brand()
                brand.brandId = brandUnionMerchant.entityId
                brand.brandName = brandUnionMerchant.name
                styleFilter.brands = [brand]
            }
        }
        
        PushManager.sharedInstance.goToPLP(styleFilter: styleFilter, animated: true)
    }
    
    func searchForMerchant(merchant: Merchant?) {        
        if let strongMerchant = merchant{
            Navigator.shared.dopen(Navigator.mymm.website_merchant_merchantId + "\(strongMerchant.merchantId)")
        }
    }
    
    private func reloadDataSource() {
        self.sectionList.removeAll()
        
        //Newsfeed banner always top of list
        self.sectionList.append(.newsfeedBannerSection)
        
        self.sectionList.append(.shortcutBannerSection)
        
        //Promotion list
        self.sectionList.append(.promotionSection)
        
        //Product Section
        self.sectionList.append(.productBannerSection)
        
        //Merchant list
        self.sectionList.append(.brandsSection)
        
        

        self.collectionView.reloadData()
    }
    
    private func reloadCollectionView() {
        
        self.stopLoad()
        self.collectionView.reloadData()
    }
    
    // MARK: - UIScrollView Delegate
    func scrollViewDidScroll(_ scrollView: UIScrollView) {
        if scrollView == self.collectionView {
            lastPositionY = scrollView.contentOffset.y

        }
    }

    func scrollViewWillBeginDragging(_ scrollView: UIScrollView) {
        //NotificationCenter.default.post(name: Constants.Notification.ToggleHideOrShowProductTags, object: true)
    }
    
    func scrollViewDidEndDragging(_ scrollView: UIScrollView, willDecelerate decelerate: Bool) {
        customPullToRefreshView?.scrollViewDidEndDragging()
        
        if !decelerate {
            //NotificationCenter.default.post(name: Constants.Notification.ToggleHideOrShowProductTags, object: false)
        }
    }
    
    func scrollViewWillBeginDecelerating(_ scrollView: UIScrollView) {
        //NotificationCenter.default.post(name: Constants.Notification.ToggleHideOrShowProductTags, object: true)
    }
    
    func scrollViewDidEndDecelerating(_ scrollView: UIScrollView) {
        //NotificationCenter.default.post(name: Constants.Notification.ToggleHideOrShowProductTags, object: false)
    }
    
    // MARK: - Collection View
    
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, referenceSizeForFooterInSection section: Int) -> CGSize {
        
        let sectionType = self.sectionList[section]
        if sectionType == .brandsSection && self.merchantList.count > 0 {
            return CGSize(width: self.view.width, height: HomeFooterView.ViewHeight)
        }
        return CGSize.zero
    }
    
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, referenceSizeForHeaderInSection section: Int) -> CGSize {
        let sectionType = self.sectionList[section]
        if self.merchantList.count > 0 && sectionType == .brandsSection {
            return CGSize(width: self.view.width, height: HomeHeaderView.ViewHeight)
        }
        

        if sectionType == .productBannerSection && productBannerList.count > 0 {
            return CGSize(width: self.view.width, height: HomeHeaderView.ViewHeight)
        }
        
        
        
        
        return CGSize(width: 0, height: 0)
    }
    
    func collectionView(_ collectionView: UICollectionView, viewForSupplementaryElementOfKind kind: String, at indexPath: IndexPath) -> UICollectionReusableView {
        if kind == UICollectionElementKindSectionHeader {
            let view = collectionView.dequeueReusableSupplementaryView(ofKind: UICollectionElementKindSectionHeader, withReuseIdentifier: HeaderViewIdentifier, for: indexPath)
            if let headerView = view as? HomeHeaderView {
                let sectionType = self.sectionList[indexPath.section]
                switch sectionType {
                case .promotionSection:
                    headerView.label.text = String.localize("LB_CA_HIGHLIGHT_PROMOTION")
                case .brandsSection:
                    headerView.label.text = String.localize("LB_CA_HIGHLIGHT_MERCHANT")
                
                case .productBannerSection:
                    headerView.label.text = String.localize("LB_CA_RECOMMENDATION")
                    
                default:
                    break
                }
            }
            return view
        }
        
        let sectionType = self.sectionList[indexPath.section]
        if kind == UICollectionElementKindSectionFooter {
            if sectionType == .brandsSection  {
                if let view = collectionView.dequeueReusableSupplementaryView(ofKind: UICollectionElementKindSectionFooter, withReuseIdentifier: HomeFooterView.FooterIdentifier, for: indexPath) as? HomeFooterView {
                    view.delegate = self
                    view.section = indexPath.section
                    view.label.text = String.localize("LB_NEWFEED_MERCHANT_ALL")
                    
                    return view
                }
            }
        }
        
        let view = collectionView.dequeueReusableSupplementaryView(ofKind: UICollectionElementKindSectionFooter, withReuseIdentifier: "LoadingFooterView", for: indexPath)
        
        return view
    }
    
    override func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        
        var resultCell: UICollectionViewCell!
        let sectionType = self.sectionList[indexPath.section]
        
        if sectionType == .newsfeedBannerSection {
            let cell = collectionView.dequeueReusableCell(withReuseIdentifier: BannerCell.CellIdentifier, for: indexPath) as! BannerCell
            cell.delegate = self
            cell.bannerList = self.newsfeedBannerList
            cell.analyticsViewKey = self.analyticsViewRecord.viewKey
            cell.impressionVariantRef = "RedZone"
            cell.positionLocation = "Newsfeed-Home-RedZone"
            generalBannerCell = cell
            cell.showOverlay(false)
            resultCell = cell
        }else if sectionType == .promotionSection {
            if let cell = collectionView.dequeueReusableCell(withReuseIdentifier: BannerGridViewCellIdentifier, for: indexPath) as? BannerGridViewCell {
                cell.analyticsViewKey = self.analyticsViewRecord.viewKey
                cell.isImageFullCell = true
                let data = self.gridBanners[indexPath.row]
                cell.setBanner(data, index: indexPath.row, isLastCell: indexPath.row == self.gridBanners.count - 1)
                cell.delegate = self
                resultCell = cell
            }
        }
        else if sectionType == .productBannerSection {
            if let cell = collectionView.dequeueReusableCell(withReuseIdentifier: ProductBannerGroupCell.CellIdentifier, for: indexPath) as? ProductBannerGroupCell {
                cell.currentIndex = indexPath.row
                cell.analyticsViewKey = self.analyticsViewRecord.viewKey
                cell.banner = self.productBannerList[indexPath.row]
                cell.delegate = self
                resultCell = cell
            }
            
            
        }
        else if sectionType == .magazineBannerSection && indexPath.row == 0 {
            let cell = collectionView.dequeueReusableCell(withReuseIdentifier: BannerCell.CellIdentifier, for: indexPath) as! BannerCell
            cell.delegate = self
            cell.bannerList = self.magazineBannerList
            cell.analyticsViewKey = self.analyticsViewRecord.viewKey
            magazineBannerCell = cell
            resultCell = cell
            
        } else if sectionType == .brandsSection {
            let cell = collectionView.dequeueReusableCell(withReuseIdentifier: FeatureBrandImageCell.CellIdentifier, for: indexPath) as! FeatureBrandImageCell
            
            cell.analyticsViewKey = self.analyticsViewRecord.viewKey
            let merchant = self.merchantList[indexPath.row]
            cell.merchant = merchant
            cell.setImage(merchant.largeLogoImage, category: .merchant, index: indexPath.row, width: Constants.DefaultImageWidth.LargeIcon)
            cell.hideBlurTextView()
            cell.label.text = ""
            cell.delegate = self
            
            resultCell = cell
            
        } else if sectionType == .categoriesSection && indexPath.row == 0 {
            let cell = collectionView.dequeueReusableCell(withReuseIdentifier: HorizontalImageCell.CellIdentifier, for: indexPath) as! HorizontalImageCell
            cell.headerLabel.text = String.localize("LB_CA_RECOMMENDED")
            cell.delegate = self
            cell.dataSource = self.categoriesList
            resultCell = cell
            
        } else if sectionType == .shortcutBannerSection {
            let cell = collectionView.dequeueReusableCell(withReuseIdentifier: ShortcutBannerCell.CellIdentifier, for: indexPath) as! ShortcutBannerCell
            cell.isBlackZonePage = false
            cell.datasources = self.shortcutBannerList
            cell.delegate = self
            cell.initAnalytics(withViewKey: analyticsViewRecord.viewKey)
            return cell
            
        }else { //sectionType == .NewsFeedSection

        }
        
        resultCell.disableScrollToTop()
        return resultCell
    }
    
    override func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        let sectionType = self.sectionList[section]
        switch sectionType {
        case .newsfeedBannerSection:
            return self.newsfeedBannerList.count == 0 ? 0 :  1
        case . shortcutBannerSection:
            return self.shortcutBannerList.count > 0 ? 1 : 0
        case .promotionSection:
            if self.gridBanners.count > 0 {
                return self.gridBanners.count
            }
            return 0
        case .magazineBannerSection, .categoriesSection:
            return 1
        case .brandsSection:
            return self.merchantList.count
        case .productBannerSection:
            return productBannerList.count
        }
    }
    
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, sizeForItemAt indexPath: IndexPath) -> CGSize {
        let sectionType = self.sectionList[indexPath.section]
        if sectionType == .newsfeedBannerSection {
            return CGSize(width: view.width, height: newsfeedBannerList.count == 0 ? 0 : 696.0 / 1125.0 * view.width)
        }else if sectionType == .shortcutBannerSection {
            return CGSize(width: view.width, height: ShortcutBannerCell.getCellHeight(self.shortcutBannerList, itemPerRow: 4, isBlackZone: false))
        } else if sectionType == .productBannerSection {
            let banner = productBannerList[indexPath.row]
            return CGSize(width: view.width, height: ProductBannerGroupCell.getCellHeight(banner))
        } else if sectionType == .promotionSection {
            return CGSize(width: view.width, height: view.width * 185.0 / 375.0)
        }
        else if sectionType == .magazineBannerSection && indexPath.row == 0 {
            return CGSize(width: view.width, height: 696.0 / 1125.0 * view.width)
        } else if sectionType == .categoriesSection && indexPath.row == 0 {
            return CGSize(width: view.width, height: view.frame.width / 4.25 + HorizontalImageCell.getHeaderViewHeight())
        } else if sectionType == .brandsSection {
            var size = FeatureBrandImageCell.getCellSize()
            if indexPath.row == 0 || indexPath.row == 1 {
                size = CGSize(width: size.width, height: size.height - FeatureBrandImageCell.MarginLeft)
            }
            else{
                size = CGSize(width: size.width, height: size.height - FeatureBrandImageCell.MarginLeft + FeatureBrandImageCell.Padding/2)
            }
            return size
        }
        
        return CGSize.zero
    }
    
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, minimumLineSpacingForSectionAt section: Int) -> CGFloat {
        let sectionType = self.sectionList[section]
        if sectionType == .brandsSection || sectionType == .promotionSection || sectionType == .productBannerSection {
            return 0
        }
        return PostManager.NewsFeedLineSpacing
    }
    
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, minimumInteritemSpacingForSectionAt section: Int) -> CGFloat {
        let sectionType = self.sectionList[section]
        if sectionType == .promotionSection || sectionType == .brandsSection || sectionType == .productBannerSection {
            return 0
        }
        return PostManager.NewsFeedLineSpacing
    }
    
//    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, insetForSectionAt section: Int) -> UIEdgeInsets {
//        return UIEdgeInsets.zero
//    }

    func numberOfSections(in collectionView: UICollectionView) -> Int {
        return sectionList.count
    }
    
    func collectionView(_ collectionView: UICollectionView, didEndDisplayingCell cell: UICollectionViewCell, forItemAtIndexPath indexPath: IndexPath) {
        //Turn off the timer to avoid crashing if banner cell is disappeared
        if let bannerCell = cell as? BannerCell {
            bannerCell.isAutoScroll = false
        }
    }
    
    func collectionView(_ collectionView: UICollectionView, shouldSelectItemAtIndexPath indexPath: IndexPath) -> Bool {
        return false
    }
    
    func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {

    }
    
    // MARK: - Banner Cell Delegate
    
    func didSelectBanner(_ banner: Banner) {
        
        if !isPresentingViewController {
            //This flag prevent fast click on banner
            isPresentingViewController = true
			
            if banner.link.contains(Constants.MagazineCoverList) {
                // open as magazine cover list
                if LoginManager.isLoggedInErrorPrompt() {
                    PostManager.isSkipLoadingNewFeedInHome = true
                    let magazineCollectionViewController = MagazineCollectionViewController()
                    self.navigationController?.push(magazineCollectionViewController, animated: true)
                }
                self.isPresentingViewController = false
            } else {
                if let deepLinkDictionary = DeepLinkManager.sharedManager.getDeepLinkTypeValue(banner.link) {
                    
                    if let deepLinkType = deepLinkDictionary.keys.first as DeepLinkManager.DeepLinkType? {
                        if deepLinkType == .Conversation || deepLinkType == .OrderReturn {
                            // check user login
                            if LoginManager.getLoginState() != .validUser {
                                isPresentingViewController = false
                                LoginManager.goToLogin { [weak self] in
                                    if let strongSelf = self {
                                        strongSelf.didSelectBanner(banner)
                                    }
                                }
                                return
                            }
                        }
                        if Navigator.shared.open(banner.link) {
                            self.isPresentingViewController = false
                        }
                    } else {
                        self.isPresentingViewController = false
                    }
                } else {
                    self.isPresentingViewController = false
                }
            }
        }
    }
    
    //MARK: - Horizontal Cell Delegate
    
    func onSelect(merchant: Merchant) {
        self.searchForMerchant(merchant: merchant)
    }
    
    func onSelect(brand: Brand) {
        
    }
    
    func ontap(merchant: Merchant) {
        self.searchForMerchant(merchant: merchant)
    }
    
    func ontap(brand: BrandUnionMerchant) {
        self.searchForBrandUnionMerchant(brand: brand)
    }
    
    func ontap(category: Cat) {
        let styleFilter = StyleFilter()
        styleFilter.cats = [category]
        PushManager.sharedInstance.goToPLP(styleFilter: styleFilter, animated: false)
    }
    
    func onTapBrandAll() {
        let discoverCollectionViewController = DiscoverCollectionViewController()
        discoverCollectionViewController.viewMode = .discoverBrand
        discoverCollectionViewController.showFromOtherTabbar = true
        self.navigationController?.push(discoverCollectionViewController, animated: true)
    }
    
    func onTapCategoryAll() {
        let discoverCollectionViewController = DiscoverCollectionViewController()
        discoverCollectionViewController.viewMode = .discoverCategory
        discoverCollectionViewController.showFromOtherTabbar = true
        self.navigationController?.push(discoverCollectionViewController, animated: true)
    }
    
    //MARK: - Footer Collection View Delegate
    
    func listAllItems(_ section: Int) {
        let sectionType = self.sectionList[section]
        switch sectionType {
        case .brandsSection:
            let merchantGridViewController = MerchantGridViewController()
            self.navigationController?.push(merchantGridViewController, animated: true)
        default:
            break
        }
    }
    
    //MARK: - FeatureBrandCellDelegate
    
    func followNewMerchant(_ merchant: Merchant, sender: UIButton) {

        if let followButton = sender as? ButtonFollow {
            followButton.showLoading()
            merchant.isLoading = true
        }
        Log.debug("Follow new merchant clicked")
        firstly {
            return FollowService.requestFollow(merchant: merchant)
            }.always {
                if let followButton = sender as? ButtonFollow {
                    followButton.hideLoading()
                }
                merchant.isLoading = false
                self.collectionView.reloadData()
            }.catch { error -> Void in
                Log.error("error")
                let error = error as NSError
                if let apiResp = error.userInfo["data"] as? ApiResponse {
                    self.handleError(apiResp, statusCode: error.code, animated: true)
                }
                
        }
        //record action
        sender.initAnalytics(withViewKey: self.analyticsViewRecord.viewKey, impressionKey: sender.analyticsImpressionKey)
        sender.recordAction(.Tap, sourceRef: "Follow", sourceType: .Button, targetRef: merchant.merchantCode, targetType: .Merchant)
    }
    
    func unfollowMerchant(_ merchant: Merchant, sender: UIButton) {
        let message = String.localize("LB_CA_UNFOLLOW_CONF").replacingOccurrences(of: "{0}", with: merchant.merchantNameInvariant)
        Alert.alert(self, title: "", message: message, okActionComplete: { () -> Void in
            if let followButton = sender as? ButtonFollow {
                followButton.showLoading()
                merchant.isLoading = true
            }
            Log.debug("Unfollow new merchant clicked")
            firstly {
                return FollowService.requestUnfollow(merchant: merchant)
                }.always {
                    if let followButton = sender as? ButtonFollow {
                        followButton.hideLoading()
                    }
                    merchant.isLoading = false
                    self.collectionView.reloadData()
                }.catch { error -> Void in
                    Log.error("error")
                    let error = error as NSError
                    if let apiResp = error.userInfo["data"] as? ApiResponse {
                        self.handleError(apiResp, statusCode: error.code, animated: true)
                    }
            }
            //record action
            sender.initAnalytics(withViewKey: self.analyticsViewRecord.viewKey, impressionKey: sender.analyticsImpressionKey)
            sender.recordAction(.Tap, sourceRef: "Unfollow", sourceType: .Button, targetRef: merchant.merchantCode, targetType: .Merchant)
            }, cancelActionComplete:nil)
    }
    
    
    // MARK: Logging
    func initAnalyticLog(){
        initAnalyticsViewRecord(nil,
            authorType: nil,
            brandCode: nil,
            merchantCode: nil,
            referrerRef: nil,
            referrerType: nil,
            viewDisplayName: nil,
            viewParameters: "RedZone",
            viewLocation: "Newsfeed-Home-RedZone",
            viewRef: Context.getUserProfile().userKey ,
            viewType: "Homepage"
        )
    }
    
    func showLoad() {
        //super.showLoading()
        
        if self.loadingView == nil {
            let animator = MMRefreshAnimator(frame: CGRect(x: 0, y: 100, width: self.collectionView.frame.width, height: 80))
            animator.animateImageView()
            self.collectionView.addSubview(animator)
            self.loadingView = animator
        } else if let animator = self.loadingView as? MMRefreshAnimator{
            self.collectionView.addSubview(animator)
            animator.animateImageView()
        }
        self.collectionView.isUserInteractionEnabled = false
    }
    
    func stopLoad() {
        //super.stopLoading()
        
        if let animator = self.loadingView as? MMRefreshAnimator {
            animator.stopAnimateImageView()
            animator.removeFromSuperview()
        }
        self.collectionView.isUserInteractionEnabled = true
    }
    
}

extension HomeViewController: ProductBannerGroupCellDelegate {
    
    func didSelectProductItem(_ style: Style) {
        let styleViewController = StyleViewController(style: style)
        styleViewController.skuId = style.defaultSkuId()
        self.navigationController?.push(styleViewController, animated: true)
    }
    
    func didSelectProductBanner(_ banner: Banner) {
        didSelectBanner(banner)
    }
    
}
