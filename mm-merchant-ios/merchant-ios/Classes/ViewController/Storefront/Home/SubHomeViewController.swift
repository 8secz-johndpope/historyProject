//
//  SubHomeViewController.swift
//  merchant-ios
//
//  Created by khanh.nguyen on 5/12/17.
//  Copyright © 2017 WWE & CO. All rights reserved.
//

import UIKit
import PromiseKit
import ObjectMapper
import Refresher


class SubHomeViewController : MmViewController, CuratorsCellDelegate, HomeFooterViewDelegate, TopBannerCellDelegate, HashTagViewDelegate , BannerCellDelegate{
    
    private final let DefaultCellID = "DefaultCellID"
    private let MockupCellIdentifier = "MockupCellIdentifier"
    private let LoadingCellIdentifier = "LoadingCellIdentifier"
    private final let OffsetAllowance = CGFloat(5)
    private final let HeaderViewIdentifier = "HeaderViewIdentifier"
    
    
    enum HomeSectionType: Int {
        case TopBannerSection = 4
        case CuratorsSection = 5
        case HashTagFeedSection = 6
        case NewsFeedSection = 7
    }
    
    // Check to show / hide navigation bar
    
    // Data Source
    private var sectionList = [HomeSectionType]()
    private var curatorList = [User]()
    private var bannerList = [Banner]()
    private var hashTagList = [HashTag]()
    private var shouldShowTopBannerSection = false
    
    private var isPresentingViewController = false
    
    private var reloadNewsFeedBannersData = true
    
    var paidOrder: ParentOrder?
    
    private var myFeedCollectionViewCells = [SimpleFeedCollectionViewCell]()
    
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
    
    lazy var upImageView:UpImageView = {
        let upImageView = UpImageView(frame: CGRect(x: 0, y: 0, width: ScreenWidth, height: 48))
        return upImageView
    }()
    
    var floatingActionButton: MMFloatingActionButton = {
        let floatingActionButton = MMFloatingActionButton()
        return floatingActionButton
    }()
    
    func showThankYouPage(){
        let thankYouViewController = ThankYouViewController()
        thankYouViewController.fromViewController = self
        thankYouViewController.parentOrder = paidOrder
        let navigationController = MmNavigationController(rootViewController: thankYouViewController)
        navigationController.modalPresentationStyle = .overFullScreen
        thankYouViewController.handleDismiss = {
        }
        self.present(navigationController, animated: true, completion: nil)
        self.stopLoading()
    }
    
    var postManager : PostManager!
    private var lastPositionY = CGFloat(0)
    
    var onAllUsersSelected: (() -> Void)?
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        NotificationCenter.default.addObserver(self, selector: #selector(self.controllerBackFromForeground), name: NSNotification.Name.UIApplicationWillEnterForeground, object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(self.appGettingLogout), name: Constants.Notification.userLoggedOut, object: nil)
        
        view.backgroundColor = UIColor.white
        //        setupNavigationBar()
        setupCollectionView()
        if let displayViewController = Utils.findActiveNavigationController()?.viewControllers.get(0) {
            postManager = PostManager(postFeedTyle: .newsFeed, collectionView: self.collectionView, viewController: displayViewController)
        }
        
        
        
        initAnalyticLog()
        self.reloadDataSource()
        
        PostManager.postImageCallBack = {[weak self] (imageNum,post,showErro) in
            if let strongSelf = self{
                if let tagImages = post.images{
                    if imageNum == tagImages.count {
                        strongSelf.view.addSubview(strongSelf.upImageView)
                        PostManager.upImageView = strongSelf.upImageView

                    }
                }
                if imageNum == 0{
                    strongSelf.upImageView.removeFromSuperview()
                }
                strongSelf.upImageView.showErro(erro: showErro)
            }
        }
        
        PostManager.createPostSuccess = {[weak self] in
            if let strongSelf = self{
                strongSelf.updateNewsFeed(1)
            }
            
        }
        floatingActionButton.frame = CGRect(x: self.view.frame.width - Constants.Value.WidthActionButton - Constants.Value.MarginActionButton, y: self.view.frame.height  - Constants.Value.WidthActionButton - Constants.Value.MarginActionButton - 140 - TabbarHeight , width: Constants.Value.WidthActionButton , height: Constants.Value.WidthActionButton)
        let tapGesture = UITapGestureRecognizer()
        tapGesture.addTarget(self, action: #selector(touchFloatingActionButton))
        floatingActionButton.addGestureRecognizer(tapGesture)
        self.view.addSubview(floatingActionButton)
    }
    
    @objc func appGettingLogout() {
        isFirstStart = true
    }
    
    @objc func controllerBackFromForeground(){
        hasFetchedDataWhenAppear = false
        if self.viewIsAppearing {
            reloadDataWhenResume()
        }
    }
    
    @objc func touchFloatingActionButton(){
        if LoginManager.isValidUser() {
            PopManager.sharedInstance.selectPost()
        } else {
            LoginManager.goToLogin()
        }
    }
    
    // refresh called when view will appear or back from background
    private func reloadDataWhenResume(){
        
        if !hasFetchedDataWhenAppear {
            self.loadFeaturedCuratorsData()
            self.loadBannersData()
            self.loadFeatureTags()
            hasFetchedDataWhenAppear = true
        } else {
            self.collectionView.reloadData()
            self.collectionView.collectionViewLayout.invalidateLayout()
        }
        
    }
    
    var hasFetchedDataWhenAppear = false
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        
        NotificationCenter.default.addObserver(self, selector: #selector(self.didReceiveScreenCapNotification), name: NSNotification.Name.UIApplicationUserDidTakeScreenshot, object: nil)
        
        reloadDataWhenResume()
        
        if isFirstStart == true{
            updateNewsFeed(1)
            isFirstStart = false
        }

    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        
        NotificationCenter.default.removeObserver(self, name: NSNotification.Name.UIApplicationWillEnterForeground, object: nil)
        NotificationCenter.default.removeObserver(self, name: NSNotification.Name.UIApplicationDidEnterBackground, object: nil)
        NotificationCenter.default.removeObserver(self, name: NSNotification.Name.UIApplicationUserDidTakeScreenshot, object: nil)
        
        isPresentingViewController = false
    }
    
    func showUpImageView() {
        
    }
    
    // MARK: - Set up
    
    private func setupCollectionView() {
        collectionView.backgroundColor = UIColor.white
        collectionView.register(UICollectionViewCell.self, forCellWithReuseIdentifier: self.DefaultCellID)
        collectionView.register(CuratorsCell.self, forCellWithReuseIdentifier: CuratorsCell.CellIdentifier)
        
        collectionView.register(HomeHeaderView.self, forSupplementaryViewOfKind: UICollectionElementKindSectionHeader, withReuseIdentifier: HeaderViewIdentifier)
        
        collectionView.register(HashTagFeedHeaderView.self, forSupplementaryViewOfKind: UICollectionElementKindSectionHeader, withReuseIdentifier: HashTagFeedHeaderView.HeaderViewIdentifier)
        
        collectionView.register(HomeFooterView.self, forSupplementaryViewOfKind: UICollectionElementKindSectionFooter, withReuseIdentifier: HomeFooterView.FooterIdentifier)
        
        collectionView.register(TopBannerCell.self, forCellWithReuseIdentifier: TopBannerCell.CellIdentifier)

        
        configCollectionView()
        
    }
    
    //    private func setupNavigationBar() {
    //        setupNavigationBarCartButton()
    //        setupNavigationBarWishlistButton()
    //
    //        buttonCart?.addTarget(self, action: #selector(self.goToShoppingCart(_:)), for: .touchUpInside)
    //        buttonWishlist?.addTarget(self, action: #selector(self.goToWishList(_:)), for: .touchUpInside)
    //
    //        buttonCart?.accessibilityIdentifier = "view_cart_button"
    //        buttonWishlist?.accessibilityIdentifier = "view_wishlist_button"
    //
    //        buttonCart?.setImage(UIImage(named: "shop"), for: .normal)
    //        buttonWishlist?.setImage(UIImage(named: "heart"), for: .normal)
    //
    //        let rightButtonItems = [
    //            UIBarButtonItem(customView: buttonCart!),
    //            UIBarButtonItem(customView: buttonWishlist!)
    //        ]
    //
    //        self.setupNavigationBarSearchButton()
    //        self.navigationItem.rightBarButtonItems = rightButtonItems
    //
    //        if let navigationController = self.navigationController as? GKFadeNavigationController {
    //            navigationController.setNavigationBarVisibility(GKFadeNavigationControllerNavigationBarVisibility.Hidden, animated: true)
    //        }
    //    }
    
    //    func setupNavigationBarSearchButton() {
    //        let ButtonHeight = CGFloat(25)
    //        let ButtonWidth = CGFloat(30)
    //
    //        searchButton.frame = CGRect(x:0, y: 0, width: ButtonWidth, height: ButtonHeight)
    //        searchButton.setImage(UIImage(named: "search_wht"), for: .normal)
    //        searchButton.accessibilityIdentifier = "discover_search_button"
    //        searchButton.addTarget(self, action: #selector(SubHomeViewController.searchIconClicked), for: UIControlEvents.touchUpInside)
    //        let leftBarButton = UIBarButtonItem(customView: searchButton)
    //
    //        self.navigationItem.leftBarButtonItem = leftBarButton
    //
    //        if viewTitle == nil {
    //            let view = UIView()
    //            view.frame = CGRect(x: 50, y: 0, width: self.view.bounds.maxX * 2 / 3, height: 32.5)
    //
    //            let searchBtn = UIButton(type: UIButtonType.custom)
    //            searchBtn.frame = view.bounds
    //            searchBtn.accessibilityIdentifier = "discover_search_button"
    //            searchBtn.addTarget(self, action: #selector(SubHomeViewController.searchIconClicked), for: UIControlEvents.touchUpInside)
    //
    //            view.addSubview(searchBtn)
    //
    //            let searchBarImage = UIImageView(image: UIImage(named: "search_bar_no_scan"))
    //            searchBarImage.frame = CGRect(x: 0, y: 0, width: view.bounds.maxX, height: searchBarImage.bounds.maxY * view.bounds.maxX / searchBarImage.bounds.maxX)
    //            searchBtn.addSubview(searchBarImage)
    //
    //            searchLabelTitle = UILabel(frame: CGRect(x: 30, y: 0, width: view.bounds.maxX - 55, height: searchBarImage.frame.size.height))
    //            searchLabelTitle.text = String.localize("LB_CA_SEARCH_PLACEHOLDER")
    //            searchLabelTitle.textColor = UIColor.secondary4()
    //            searchLabelTitle.font = UIFont.systemFont(ofSize: 14.0)
    //            searchBtn.addSubview(searchLabelTitle)
    //
    //            self.viewTitle = view
    //        }
    //
    //    }
    
    private func configCollectionView() {
        self.collectionView.delegate = self
        self.collectionView.dataSource = self
        self.collectionView.frame = CGRect(x: 0 , y: 0, width: self.view.bounds.width, height: self.view.bounds.height - tabBarHeight)
        
        self.collectionView.register(UICollectionViewCell.self, forCellWithReuseIdentifier: LoadingCellIdentifier)
        self.collectionView.register(UICollectionViewCell.self, forCellWithReuseIdentifier: MockupCellIdentifier)
        
        //        customPullToRefreshView = PullToRefreshUpdateView(frame: CGRect(x:(self.collectionView.frame.width - Constants.Value.PullToRefreshViewHeight) / 2, y: 258.0, width: Constants.Value.PullToRefreshViewHeight, height: Constants.Value.PullToRefreshViewHeight), scrollView: self.collectionView)
        //        customPullToRefreshView?.delegate = self
        //        self.collectionView.addSubview(customPullToRefreshView!)
        
        let animator = MMRefreshAnimator(frame: CGRect(x:0, y: 0, width: self.collectionView.frame.width, height: 80))
        //animator.referenceNavigationController = self.navigationController
        
        self.collectionView.addPullToRefreshWithAction({ [weak self] in
            if let strongSelf = self {
                strongSelf.refresh()
            }
            }, withAnimator: animator)
        if let layout = collectionView.collectionViewLayout as? PinterestLayout {
            layout.delegate = self
        }
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
        var promises : [Promise<Void>] = [self.updateNewsFeed(1).asVoid()]
        
        promises.append(self.loadFeaturedCuratorsData().asVoid())
        promises.append(self.loadBannersData().asVoid())
        when(fulfilled: promises).then { _ -> Void in
            self.isRefreshing = false
            self.collectionView.stopPullToRefresh()
            }.catch { (error) in
                self.collectionView.stopPullToRefresh()
                self.isRefreshing = false
                print(error)
            }
    }
    
    override func showError(_ message: String, animated: Bool) {
        guard !message.isEmpty else {
            return
        }
        
        let y = CGFloat(0)
        let minHeight = CGFloat(40)
        
        var height = StringHelper.heightForText(message, width: self.view.bounds.width - 10, font: UIFont.systemFontWithSize(14)) + 10
        if height < minHeight {
            height = minHeight
        }
        
        if errorView == nil {
            errorView = IncorrectView()
            errorView?.displayTime = 5
            self.view.addSubview(errorView!)
        }
        
        errorView?.frame = CGRect(x: 0, y: y, width: self.view.bounds.width, height: height)
        errorView?.delegate = self
        errorView?.showMessage(message, animated: animated)
    }
    
    func setNavigationBarControllerHidden(hidden: Bool){
        if self.navigationController?.navigationBar.alpha == (hidden == true ?0.0:1.0) {
            return
        }
        UIView.animate(withDuration: 0.3) {
            self.navigationController?.navigationBar.alpha = hidden == true ?0.0:1.0
        }
    }
    
    // MARK: - Views And Actions
    
    func searchIconClicked() {
        let searchViewController = ProductListSearchViewController()
        self.navigationController?.pushViewController(searchViewController, animated: false)
    }
    
    
    //MARK: - Data Processing
    func compareTopBannerData() {
        var list = [BannerCacheObject]()
        var isBannerChanged = false
        for item in self.bannerList {
            if let _ = CacheManager.sharedManager.cachedBannerForBannerId(String(item.bannerKey)) {
                Log.debug("")
            }else {
                isBannerChanged = true
                list.append(item.cacheableObject())
            }
        }
        CacheManager.sharedManager.cacheListObjects(list)
        if (Context.userHasDismissedTopBanner && isBannerChanged == false) || (bannerList.count == 0) {
            shouldShowTopBannerSection = false
        }else {
            shouldShowTopBannerSection = true
            Context.userHasDismissedTopBanner = false
        }
        
    }
    
    @discardableResult
    private func loadBannersData() -> Promise<Any> {
        return Promise{ fulfill, reject in
            firstly {
                return BannerService.fetchBanners([.discover], loadFromCache: false)
                }.then {  banners -> Void in
                    
                    let arraySlice = banners.filter{ $0.collectionType == .discover }.prefix(Constants.Value.MaximumTopBanner)
                    self.bannerList = Array(arraySlice)
                    self.compareTopBannerData()
                    self.collectionView.reloadData()
                    
                    fulfill("OK")
                    
                }.catch { _ -> Void in
                    
                    Log.error("error @ loadBannersData")
                    let error = NSError(domain: "", code: 0, userInfo: nil)
                    reject(error)
            }
        }
    }
    
    private func listFeatureTags() -> Promise<Any> {
        return Promise{ fulfill, reject in
            HashTagService.listFeatureTags(.Post, completion: { [weak self] (response) in
                    if let strongSelf = self {
                        if response.result.isSuccess {
                            if let hashTagData = Mapper<HashTagList>().map(JSONObject: response.result.value) {
                                if let hashTagList = hashTagData.pageData {
                                    strongSelf.hashTagList = Array(hashTagList.prefix(Constants.Value.MaximumOfficalHashTag))
                                }
                            }
                            
                            
                            fulfill("OK")
                        } else {
                            reject(response.result.error ?? strongSelf.getError(response))
                        }
                    }
                    })
        }
    }
    
    @discardableResult
    private func loadFeatureTags() -> Promise<Any> {
        return Promise{ fulfill, reject in
            firstly {
                return listFeatureTags()
                }.then {  _ -> Void in
                    self.collectionView.reloadData()
                    self.collectionView.collectionViewLayout.invalidateLayout()
                    fulfill("OK")
                }.catch { _ -> Void in
                    Log.error("error @ loadFeaturedCuratorsData")
                    let error = NSError(domain: "", code: 0, userInfo: nil)
                    reject(error)
            }
        }
    }
    
    @discardableResult
    private func loadFeaturedCuratorsData() -> Promise<Any> {
        return Promise{ fulfill, reject in
            firstly {
                return FollowService.listFollowingUserKeys()
                }.then {  _ -> Promise<Any> in
                    return self.listCurator()
                }.then {  _ -> Void in
                    self.collectionView.reloadData()
                    self.collectionView.collectionViewLayout.invalidateLayout()
                    fulfill("OK")
                }.catch { _ -> Void in
                    Log.error("error @ loadFeaturedCuratorsData")
                    let error = NSError(domain: "", code: 0, userInfo: nil)
                    reject(error)
            }
        }
    }
    
    func listCurator() -> Promise<Any> {
        return Promise{ fulfill, reject in
            UserService.listAllRecommendedCurator() { [weak self] (response) in
                if let strongSelf = self {
                    if response.result.isSuccess {
                        let curatorList = Mapper<User>().mapArray(JSONObject: response.result.value) ?? []
                        
                        strongSelf.curatorList.removeAll()
                        for curator in curatorList {
                            if strongSelf.curatorList.count < Constants.Value.MaximumCuratorRecommended {
                                if !FollowService.instance.cachedFollowingUserKeys.contains(curator.userKey) && curator.userKey != Context.getUserKey() {
                                    strongSelf.curatorList.append(curator)
                                }
                            }else {
                                break
                            }
                        }
                        
                        fulfill("OK")
                    } else {
                        reject(response.result.error ?? strongSelf.getError(response))
                    }
                }
            }
        }
    }
    
    private func reloadDataSource() {
        self.sectionList.removeAll()
        
        self.sectionList.append(.TopBannerSection)
        
        self.sectionList.append(.CuratorsSection)
        
        self.sectionList.append(.HashTagFeedSection)
        
        self.sectionList.append(.NewsFeedSection)
        
        self.collectionView.reloadData()
        self.collectionView.collectionViewLayout.invalidateLayout()
    }
    
    // MARK: - UIScrollView Delegate
    func scrollViewDidScroll(_ scrollView: UIScrollView) {
        
        if scrollView == self.collectionView {
            
            let offsetY = scrollView.contentOffset.y - lastPositionY
            lastPositionY = scrollView.contentOffset.y
            let maxY = CGFloat(64)
            if scrollView.contentOffset.y > maxY {
                if offsetY > OffsetAllowance  {
                    floatingActionButton.fadeIn()
                }else if offsetY < -1 * OffsetAllowance{
                    floatingActionButton.fadeOut()
                }
            }else if scrollView.contentOffset.y < maxY && (offsetY * -1) >= 0 {
                floatingActionButton.fadeOut()
            }
            
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
        guard section == sectionList.count - 1 && postManager.hasLoadMore else {
            return CGSize.zero
        }
        return CGSize(width: 320, height: 100)
    }
    
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, referenceSizeForHeaderInSection section: Int) -> CGSize {
        
        let sectionType = self.sectionList[section]
        switch sectionType {
        case .HashTagFeedSection where self.hashTagList.count > 0:
            return CGSize(width: view.frame.width, height: HashTagFeedHeaderView.ViewHeight)
        default:
            break
        }
        return CGSize(width: 0, height: 0)
    }
    
    func collectionView(_ collectionView: UICollectionView, viewForSupplementaryElementOfKind kind: String, at indexPath: IndexPath) -> UICollectionReusableView {
        
        let sectionType = self.sectionList[indexPath.section]
        if kind == UICollectionElementKindSectionHeader {
            
            switch sectionType {
            case .HashTagFeedSection:
                if let hashTagHeaderView = collectionView.dequeueReusableSupplementaryView(ofKind: UICollectionElementKindSectionHeader, withReuseIdentifier: HashTagFeedHeaderView.HeaderViewIdentifier, for: indexPath) as? HashTagFeedHeaderView {
                    hashTagHeaderView.initAnalytics(withViewKey: self.analyticsViewRecord.viewKey)
                    hashTagHeaderView.delegate = self
                    hashTagHeaderView.datasources = self.hashTagList
                return hashTagHeaderView
                }
            case .NewsFeedSection:
                if let headerView = collectionView.dequeueReusableSupplementaryView(ofKind: UICollectionElementKindSectionHeader, withReuseIdentifier: HeaderViewIdentifier, for: indexPath) as? HomeHeaderView {
                    headerView.label.text = String.localize("LB_CA_HIGHLIGHT_POST")
                    return headerView
                }
            default:
                let headerView = collectionView.dequeueReusableSupplementaryView(ofKind: UICollectionElementKindSectionHeader, withReuseIdentifier: HeaderViewIdentifier, for: indexPath)
                return headerView
            }
            
        }
        
        if kind == UICollectionElementKindSectionFooter {
            if sectionType == .CuratorsSection {
                if let view = collectionView.dequeueReusableSupplementaryView(ofKind: UICollectionElementKindSectionFooter, withReuseIdentifier: HomeFooterView.FooterIdentifier, for: indexPath) as? HomeFooterView {
                    view.delegate = self
                    view.section = indexPath.section
                    view.label.text = String.localize("LB_NEWFEED_CURATOR_ALL")
                    return view
                }
            }
        }
        
        let view = collectionView.dequeueReusableSupplementaryView(ofKind: UICollectionElementKindSectionFooter, withReuseIdentifier: "LoadingFooterView", for: indexPath)
        
        if let footer = view as? LoadingFooterView {
            footer.activity.isHidden = !postManager.hasLoadMore
        }
        return view
    }
    
    override func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        
        var resultCell: UICollectionViewCell!
        let sectionType = self.sectionList[indexPath.section]
        
        if sectionType == .TopBannerSection {
            let cell = collectionView.dequeueReusableCell(withReuseIdentifier: TopBannerCell.CellIdentifier, for: indexPath) as! TopBannerCell
            cell.bannerList = self.bannerList
            cell.topBannerCellDelegate = self
            cell.delegate = self
            cell.showOverlay(false)
            
            cell.analyticsViewKey = self.analyticsViewRecord.viewKey
            cell.impressionVariantRef = ""
            cell.positionLocation = "Newsfeed-Home-User"
            cell.positionComponent = "HeroBanner"
            
            return cell
        } else if sectionType == .CuratorsSection && indexPath.row == 0 {
            let cell = collectionView.dequeueReusableCell(withReuseIdentifier: CuratorsCell.CellIdentifier, for: indexPath) as! CuratorsCell
            cell.curatorList = self.curatorList
            
            cell.delegate = self
            cell.analyticsViewKey = self.analyticsViewRecord.viewKey
            resultCell = cell
            
        } else { //sectionType == .NewsFeedSection
            if indexPath.row == postManager.currentPosts.count - 1 && postManager.hasLoadMore{
                self.updateNewsFeed(postManager.currentPageNumber + 1)
            }
            
            let cell = postManager.getSimpleNewsFeedCell(indexPath)
            if let cell = cell as? SimpleFeedCollectionViewCell {
                
                if !myFeedCollectionViewCells.contains(cell) {
                    myFeedCollectionViewCells.append(cell)
                }
                
                cell.isUserInteractionEnabled = true
                cell.recordImpressionAtIndexPath(indexPath, positionLocation: "Newsfeed-Home-User", viewKey: self.analyticsViewRecord.viewKey)
                resultCell = cell
            }
        }
        
        resultCell.disableScrollToTop()
        return resultCell
    }
    
    override func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        let sectionType = self.sectionList[section]
        switch sectionType {
        case .CuratorsSection:
            if self.curatorList.count > Constants.Value.MaximumDisplayingCuratorsList {
                return 1
            }
            else{
                return 0
            }
        case .NewsFeedSection:
            return postManager.currentPosts.count
        case .TopBannerSection:
            return shouldShowTopBannerSection ? 1 : 0
        default:
            break
        }
        
        return 0
    }
    
    func numberOfSections(in collectionView: UICollectionView) -> Int {
        return sectionList.count
    }
    
    
    func collectionView(_ collectionView: UICollectionView, shouldSelectItemAtIndexPath indexPath: IndexPath) -> Bool {
        let sectionType = self.sectionList[indexPath.section]
        if sectionType == .NewsFeedSection {
            return true
        }
        return false
    }
    
    func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        if postManager.currentPosts.indices.contains(indexPath.row) {
            let post = self.postManager.currentPosts[indexPath.row]
            if let cell = collectionView.cellForItem(at: indexPath) {
                cell.recordAction(.Tap, sourceRef: "\(post.postId)", sourceType: .Post, targetRef: "Post-Detail", targetType: .View)
            }
            let postDetailController = PostDetailViewController(postId: post.postId)
            postDetailController.post = post
            self.navigationController?.pushViewController(postDetailController, animated: true)
        }
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
                    Utils.findActiveNavigationController()?.pushViewController(magazineCollectionViewController, animated: true)
                    self.isPresentingViewController = false
                }
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
    
    // MARK: - Banner Cell Delegate
    
    func didClickOnCloseButton() {
        Context.userHasDismissedTopBanner = true
        self.compareTopBannerData()
        self.collectionView.reloadData()
    }
    
    @discardableResult
    func updateNewsFeed(_ pageno: Int)-> Promise<String>{
        if isUpdatingNewFeeds {
            return Promise(value: "OK")
        }
        isUpdatingNewFeeds = true
        return Promise{ fulfill, reject in
            firstly {
                // update inventory location if needed
                // if it is not updated, it will return success without api call
                return postManager.fetchNewsFeed(.newsFeed, pageno: pageno)
                
                }.then { postIds -> Promise<Any> in
                    return self.postManager.getPostActivitiesByPostIds(postIds as! String)
                }.then { _ -> Promise<[PostLike]> in
                    if pageno == 1 {
                        return PostManager.fetchUserLikes()
                    }
                    return Promise(value: [])
                }.always {
                    self.reloadDataSource()
                    self.isUpdatingNewFeeds = false
                    self.collectionView.stopPullToRefresh()
                    fulfill("OK")
                }.catch { _ -> Void in
                    Log.error("error")
                    let error = NSError(domain: "", code: 0, userInfo: nil)
                    reject(error)
            }
        }
    }
    
    
    //MARK: - CuratorsCellDelegate
    func didSelectUser(_ user: User) {
        postManager.didSelectUser(user)
    }

    func didSelectAllUsers() {
        onAllUsersSelected?()
    }
    
    //MARK:- HashTagView Delegate
    
    func hashTagViewAddTopic() {
        
    }
    
    func hashTagViewSelectedTag(_ item: String) {
        let str = item.replacingOccurrences(of: "#", with: "")
        Navigator.shared.dopen(Navigator.mymm.deeplink_dk_tag_tagName + Urls.encoded(str: str))
    }
    
    
    //MARK: - Footer Collection View Delegate
    
    func listAllItems(_ section: Int) {
        
    }
    
    // MARK: Logging
    func initAnalyticLog(){
        initAnalyticsViewRecord(
            nil,
            authorType: nil,
            brandCode: nil,
            merchantCode: nil,
            referrerRef: nil,
            referrerType: nil,
            viewDisplayName: "User: \(Context.getUserProfile().displayName)",
            viewParameters: Context.getUserProfile().userKey,
            viewLocation: "Newsfeed-Home-User",
            viewRef: nil,
            viewType: "Newsfeed"
        )
    }
    
    @objc func didReceiveScreenCapNotification(notification: NSNotification){
        
        if let newsFeedSection = self.sectionList.index(of: .NewsFeedSection), self.postManager.currentPosts.count > 0 {
            let indexPath = IndexPath(item: 0, section: newsFeedSection)
            
            if let attributes: UICollectionViewLayoutAttributes = self.collectionView.layoutAttributesForItem(at: indexPath) {
                var cellFrameInSuperview = self.collectionView.convert(attributes.frame, to: self.view)
                //Only can share post when first newsfeed cell <= middle of screen
                if cellFrameInSuperview.originY <= (ScreenHeight / 2) {
                    self.postManager.sharePost()
                }
            }
        }
    }
    
    override func getCustomFlowLayout() -> UICollectionViewFlowLayout {
        let layout = PinterestLayout()
        layout.delegate = self
        return layout
    }
}

extension SubHomeViewController: MMFloatingActionButtonDelegate {
    
    //MARK: Floating Action Button
    func didSelectedActionButton(gesture: UITapGestureRecognizer) {
        if LoginManager.isValidUser() {
            PopManager.sharedInstance.selectPost()
        } else {
            LoginManager.goToLogin()
        }
    }
}

extension SubHomeViewController : PinterestLayoutDelegate {
    
    
    @objc func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, sizeForItemAtIndexPath indexPath: IndexPath) -> CGSize {
        let sectionType = self.sectionList[indexPath.section]
        if sectionType == .CuratorsSection {
            return CGSize(width: view.frame.width, height: CuratorCell.curatorCellHeight())
        }
        
        if sectionType == .TopBannerSection {
            return CGSize(width: view.frame.width, height: TopBannerCell.ViewHeight)
        }
        
        if indexPath.row == postManager.currentPosts.count {
            if (postManager.hasLoadMore) {
                return CGSize(width: self.view.frame.size.width, height: Constants.Value.CatCellHeight)
            }
        }
        var text = ""
        var userSourceName: String? = nil
        if postManager.currentPosts.indices.contains(indexPath.row) {
            let post = postManager.currentPosts[indexPath.row]
            userSourceName = post.userSource?.userName
            text = post.postText
        }
        let height = SimpleFeedCollectionViewCell.getHeightForCell(text, userSourceName: userSourceName)
        return CGSize(width: SimpleFeedCollectionViewCell.getCellWidth(), height: height)
    }
    
    func collectionView(_ collectionView: UICollectionView, numberOfColumnsInSection section: Int) -> Int {
        let sectionType = self.sectionList[section]
        if sectionType == .NewsFeedSection {
            return 2
        }
        return 0
    }
    
    @objc func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, insetForSectionAtSection section: Int) -> UIEdgeInsets{
        
        let sectionType = self.sectionList[section]
        if sectionType == .NewsFeedSection {
            return UIEdgeInsets(top: PostManager.NewsFeedLineSpacing, left: PostManager.NewsFeedLineSpacing, bottom: 25, right:PostManager.NewsFeedLineSpacing)
        } else if sectionType == .CuratorsSection && self.curatorList.count > 0 {
            return UIEdgeInsets(top: 25, left: 0, bottom: 14, right:0)
        }
        return UIEdgeInsets(top: 0, left: 0, bottom: 0, right: 0)
        
    }
    
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, minimumLineSpacingForSectionAtIndex section: Int) -> CGFloat {
        return PostManager.NewsFeedLineSpacing
    }
    
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, minimumInteritemSpacingForSectionAtIndex section: Int) -> CGFloat {
        return PostManager.NewsFeedLineSpacing
    }
}

internal class HashTagFeedHeaderView: UICollectionReusableView, UICollectionViewDelegateFlowLayout, UICollectionViewDataSource {
    
    static let HeaderViewIdentifier = "HashTagFeedHeaderViewIdentifier"
    static let ViewHeight: CGFloat = 52
    var lineView = UIView()
    var collectionView: UICollectionView!
    weak var delegate:HashTagViewDelegate?
    var datasources = [HashTag]() {
        didSet {
            self.collectionView.reloadData()
        }
    }
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        
        lineView.backgroundColor = UIColor.primary2()
        self.addSubview(lineView)
        
        self.setupCollectionView()
        self.addSubview(collectionView)
        
        self.backgroundColor = UIColor.white
        
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override func layoutSubviews() {
        super.layoutSubviews()
        
        lineView.frame = CGRect(x:0, y: 0, width: self.frame.sizeWidth, height: 10)
        collectionView.frame = CGRect(x:0, y: lineView.frame.maxY + 5, width: self.frame.sizeWidth, height: self.frame.sizeHeight - lineView.frame.maxY)
    }
    
    func setupCollectionView() {
        let layout = UICollectionViewFlowLayout()
        layout.scrollDirection = .horizontal
        layout.headerReferenceSize = CGSize.zero
        layout.footerReferenceSize = CGSize.zero
        layout.sectionInset = UIEdgeInsets.zero
        layout.minimumInteritemSpacing = 0
        layout.minimumLineSpacing = 10
        layout.estimatedItemSize = CGSize(width: frame.width / 3, height: 44)
//        layout.itemSize = CGSize(width: frame.width, height: 44)
        
        collectionView = UICollectionView(frame: CGRect(x:0, y: 0, width: frame.width, height: 44), collectionViewLayout: layout)
        collectionView.contentInset = UIEdgeInsets.zero
        collectionView.backgroundColor = UIColor.clear
        
        collectionView.showsHorizontalScrollIndicator = false
        collectionView.dataSource = self
        collectionView.delegate = self
        collectionView.register(HashTagCell.self, forCellWithReuseIdentifier: HashTagCell.CellIdentifier)
        collectionView.contentInset = UIEdgeInsets(top: 0, left: Margin.left, bottom: 0, right: 0)
        
    }
    
    private func getHashTagText(_ hashTag: String) -> String {
        var hashTagText = hashTag
        if hashTagText.length > 0 {
            hashTagText = hashTag.hasPrefix("#") ? hashTagText : "#\(hashTagText)"
        }
        return hashTagText
    }
    
    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        let cell = collectionView.dequeueReusableCell(withReuseIdentifier: HashTagCell.CellIdentifier, for: indexPath) as! HashTagCell
        cell.type = .roundedBorder
        let hashTag = datasources[indexPath.row]
        let hashTagText = self.getHashTagText(hashTag.tag)
        cell.label.text = hashTagText

        if let viewKey = self.analyticsViewKey {
            cell.initAnalytics(withViewKey: viewKey, impressionKey: AnalyticsManager.sharedManager.recordImpression(impressionType: "HotTopic", impressionDisplayName: hashTagText, positionComponent: "HotListing", positionIndex: indexPath.row + 1, positionLocation: "Newsfeed-Home-User", viewKey: viewKey))
        }
        return cell
        
    }
    
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, minimumInteritemSpacingForSectionAt section: Int) -> CGFloat {
        return 10.0
    }
    
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, minimumLineSpacingForSectionAt section: Int) -> CGFloat {
        return 10.0
    }
    
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, sizeForItemAt indexPath: IndexPath) -> CGSize {
        let hashTag = datasources[indexPath.row]
        let hashTagText = self.getHashTagText(hashTag.tag)
        let width = StringHelper.getTextWidth(hashTagText, height: HashTagView.HashTagHeight, font: UIFont.fontWithSize(HashTagCell.FontSize, isBold: false))
        return CGSize(width: width + Margin.left * 2, height: HashTagView.HashTagHeight)
    }
    
    func numberOfSections(in collectionView: UICollectionView) -> Int {
        return 1
    }
    
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return datasources.count
    }
    
    func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        let hashTag = datasources[indexPath.row]
        let hashTagText = self.getHashTagText(hashTag.tag)
        if let cell = collectionView.cellForItem(at: indexPath) {
            cell.recordAction(.Tap, sourceRef: hashTagText, sourceType: .HotTopic, targetRef: "Newsfeed-Post-Topic", targetType: .View)
        }
        delegate?.hashTagViewSelectedTag(hashTagText)
    }
    
    class func getCellWidth(text: String) -> CGFloat {
        let width = StringHelper.getTextWidth(text, height: HashTagView.HashTagHeight, font: UIFont.fontWithSize(HashTagCell.FontSize, isBold: false))
        return width + Margin.left
        
    }
}
