//
//  MerchantFeedViewController.swift
//  merchant-ios
//
//  Created by Quang Truong on 4/17/17.
//  Copyright © 2017 WWE & CO. All rights reserved.
//

import UIKit
import PromiseKit
import ObjectMapper
import CSStickyHeaderFlowLayout
import Alamofire
import Kingfisher
// FIXME: comparison operators with optionals were removed from the Swift Standard Libary.
// Consider refactoring the code to use the non-optional operators.
private func < <T : Comparable>(lhs: T?, rhs: T?) -> Bool {
  switch (lhs, rhs) {
  case let (l?, r?):
    return l < r
  case (nil, _?):
    return true
  default:
    return false
  }
}

// FIXME: comparison operators with optionals were removed from the Swift Standard Libary.
// Consider refactoring the code to use the non-optional operators.
private func > <T : Comparable>(lhs: T?, rhs: T?) -> Bool {
  switch (lhs, rhs) {
  case let (l?, r?):
    return l > r
  default:
    return rhs < lhs
  }
}


class MerchantFeedViewController: MmCartViewController, MerchantProductListDelegate, PullToRefreshViewUpdateDelegate, CheckoutDelegate {
    
    private enum MerchantProfileSection: Int {
        case tileFeature = 0
        case productList = 1
        case feed = 2
        case footer = 3
    }
    
    private var searchButton = UIButton()
    private var backButton = UIButton()
    private var imageViewLogo = UIImageView()
    private final let HeaderProfileIdentifier = "HeaderMerchantProfileView"
    private final let ProductListCellIdentifier = "ProductListCellIdentifier"
    private final let FeedCellIdentifier = "FeedCellIdentifier"
    private final let CellId = "Cell"
    private final let FooterProfileIdentifier = "FooterProfileIdentifier"
    private final let HeaderViewIdentifier = "HeaderViewIdentifier"
    private final let CollectionReusableViewIdentifier = "CollectionReusableViewIdentifier"
    
    private var HeaderCellHeight = CGFloat(310)
    private let ProductListHeight = CGFloat(338)
    private final let WidthLogo: CGFloat = 120.0
    private final let HeightLogo: CGFloat = 35.0
    private var feedDatasources = [String]()
    private var ProductListDatasources = [String]()
    private var productTiles = [MerchantImage]()
    private final let BarHeight = CGFloat(44)
    
    
    private var needReloadData = false
    private var isVisible = false
    var merchant: Merchant? {
        didSet {
            if let data = merchant {
                imageViewLogo.mm_setImageWithURL(ImageURLFactory.getRaw(data.headerLogoImage, category: .merchant, width: ResizerSize.size256.rawValue), placeholderImage: nil, clipsToBounds: true, contentMode: .scaleAspectFit, progress: nil, optionsInfo: nil, completion: nil)
                if let images = data.merchantImages {
                    if (images.count > 0) {
                        var sortedProductTitles = images.filter({$0.imageTypeCode.range(of: "Tile") != nil})
                        sortedProductTitles.sort(by: {$0.position < $1.position})
                        DispatchQueue.main.async {
                            self.productTiles = sortedProductTitles
                            if (self.productTiles.count > 0){
                                self.collectionView.reloadData()
                            }
                        }
                        fetchData(false)
                    }
                    
                }
            }
        }
    }
    private var merchantKey: String {
        get {
            if let merchant = self.merchant {
                return String(merchant.merchantId)
            }
            return "0"
        }
    }
    private var isFollowing = false
    var isFromUserChat = false
    var hideTabbar = false
    
    private var styles : [Style] = []
    private var filteredStyles : [Style] = []
    private var isLoadFeedDone = false
    private var layout: CSStickyHeaderFlowLayout? {
        return self.collectionView?.collectionViewLayout as? CSStickyHeaderFlowLayout
    }
    private var customPullToRefreshView: PullToRefreshUpdateView?
    private var paidOrder: ParentOrder?
    private var myFeedCollectionViewCells = [MyFeedCollectionViewCell]()
    //MARK:- View methods
    
    private var postManager : PostManager!
    
    var scrollViewDidScrollAction: ((UIScrollView) -> ())?
    var scrollViewDidEndScrollingAnimationAction: ((UIScrollView) -> ())?
    var viewWillAppearAction: (() -> Void)?
    var viewDidAppearAction: (() -> Void)?
    
    var sectionInsets = UIEdgeInsets(top: 0, left: 0, bottom: 0, right: 0)
    
    func addLogoOnNavi() {
        imageViewLogo = UIImageView(frame: CGRect(x: (self.view.frame.width - WidthLogo)/2, y: 0, width: WidthLogo, height: HeightLogo))
        self.navigationItem.titleView = imageViewLogo
        imageViewLogo.isHidden = false
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        self.setupCollectionView()
        if let merchantId = self.merchant?.merchantId {
            postManager = PostManager(postFeedTyle: .merchantFeed, merchantId: merchantId, collectionView: self.collectionView, viewController: self)
        }
        
        initAnalytics()
        self.updateNewsFeed(pageno: 1)
        NotificationCenter.default.addObserver(self, selector: #selector(self.followingMerchantDidUpdate), name: Constants.Notification.followingMerchantDidUpdate, object: nil)
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        
        NotificationCenter.default.addObserver(self, selector: #selector(self.startAllAnimations), name: NSNotification.Name.UIApplicationWillEnterForeground, object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(self.stopAllAnimations), name: NSNotification.Name.UIApplicationDidEnterBackground, object: nil)
        
        if needReloadData {
            needReloadData = false
            fetchData(true)
        }
        isVisible = true
        
        viewWillAppearAction?()
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        startAllAnimations()
        
        viewDidAppearAction?()
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)

        imageViewLogo.isHidden = true
        
        stopAllAnimations()
        
        NotificationCenter.default.removeObserver(self, name: NSNotification.Name.UIApplicationWillEnterForeground, object: nil)
        NotificationCenter.default.removeObserver(self, name: NSNotification.Name.UIApplicationDidEnterBackground, object: nil)
        isVisible = false
    }
    
    func createBack(_ imageName: String, selectorName: String, size:CGSize,left: CGFloat, right: CGFloat) -> UIBarButtonItem {
        backButton.setImage(UIImage(named: imageName), for: UIControlState())
        backButton.frame = CGRect(x: 0, y: 0, width: size.width, height: size.height)
        backButton.contentEdgeInsets = UIEdgeInsets.init(top: 0, left: left, bottom: 0, right: right)
        backButton .addTarget(self, action:Selector(selectorName), for: UIControlEvents.touchUpInside)
        let temp:UIBarButtonItem = UIBarButtonItem()
        temp.customView = backButton
        return temp
    }
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
    }
    
    override func shouldHaveCollectionView() -> Bool {
        return true
    }
    
    private func setupCollectionView() {
        self.collectionView.delegate = self
        self.collectionView.dataSource = self
        self.collectionView.frame = self.view.bounds
        self.collectionView.backgroundColor = .white
        self.collectionView.register(UICollectionViewCell.self, forCellWithReuseIdentifier: CellId)
        self.collectionView.register(MerchantProductListCollectionCell.self, forCellWithReuseIdentifier: MerchantProductListCollectionCell.CellIdentifier)
        self.collectionView.register(MyFeedCollectionViewCell.self, forCellWithReuseIdentifier: FeedCellIdentifier)
        self.collectionView.register(HomeHeaderView.self, forSupplementaryViewOfKind: UICollectionElementKindSectionHeader, withReuseIdentifier: HeaderViewIdentifier)
        self.collectionView.register(UICollectionReusableView.self, forSupplementaryViewOfKind: UICollectionElementKindSectionHeader, withReuseIdentifier: CollectionReusableViewIdentifier)
        self.collectionView.register(UICollectionReusableView.self, forSupplementaryViewOfKind: UICollectionElementKindSectionFooter, withReuseIdentifier: CollectionReusableViewIdentifier)
        self.collectionView.register(FeatureCollectionCell.self, forCellWithReuseIdentifier: FeatureCollectionCell.CellIdentifier)

        customPullToRefreshView = PullToRefreshUpdateView(frame: CGRect(x: (self.collectionView.frame.width - Constants.Value.PullToRefreshViewHeight) / 2, y: 435.0, width: Constants.Value.PullToRefreshViewHeight, height: Constants.Value.PullToRefreshViewHeight), scrollView: self.collectionView)
        customPullToRefreshView?.delegate = self
        self.collectionView.addSubview(customPullToRefreshView!)
        
    }
    
    @objc func showThankYouPage() {
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
    
    func searchIconClicked(_ id : Any) {
        let searchViewController = ProductListSearchViewController()
        self.navigationController?.push(searchViewController, animated: false)
    }

    //MARK: - API
    
    func fetchProductList() {
        firstly {
            return self.getProductList(merchant!)
            }.then { _ -> Void in
                self.collectionView.reloadData()
                
            }.always {
                if self.isLoadFeedDone {
                    self.stopLoading()
                }
            }.catch { _ -> Void in
                Log.error("error")
        }
    }
    
    func didSelectButtonFollow(_ sender: UIButton, status: Bool){
        print(status.description)
    }
    func didSelectFollowerList(_ gesture: UITapGestureRecognizer){}
    func didSelectMerchantProfileView(_ sender: UIView){}
    
    func unfollowMerchant(_ merchant: Merchant, sender: MMLoadingButton) {
        let message = String.localize("LB_CA_UNFOLLOW_CONF").replacingOccurrences(of: "{0}", with: merchant.merchantName)
        Alert.alert(self, title: "", message: message, okActionComplete: { () -> Void in
            // call api unfollow request
            merchant.isLoading = true
      
            firstly {
                return FollowService.requestUnfollow(merchant: merchant)
                }.then { _ -> Void in
                    self.isFollowing = false
                    merchant.followerCount -= 1//Fix MM-19185
                    sender.hideLoading()
                    merchant.isLoading = false
                    self.collectionView.reloadData()
                }.catch { _ -> Void in
                    Log.error("error")
                    sender.hideLoading()
                    merchant.isLoading = false
                    self.collectionView.reloadData()
            }
        }, cancelActionComplete:nil)
    }
    
    func followMerchant(_ merchant: Merchant, sender: MMLoadingButton) {
        merchant.isLoading = true
  
        firstly {
            return FollowService.requestFollow(merchant: merchant)
            }.then { _ -> Void in
                self.isFollowing = true
                merchant.followerCount += 1//fix MM-19185
                sender.hideLoading()
                merchant.isLoading = false
                self.collectionView.reloadData()
            }.catch { error -> Void in
                Log.error("error")
                let error = error as NSError
                if let apiResp = error.userInfo["data"] as? ApiResponse {
                    self.handleError(apiResp, statusCode: error.code, animated: true)
                }
                sender.hideLoading()
                merchant.isLoading = false
                self.collectionView.reloadData()
        }
    }
    
    private func fetchData(_ isFetchMerchant: Bool = true){
        updateMerchantView(isFetchMerchant , isLoginUser: (LoginManager.getLoginState() == .validUser))
    }
    
    private func updateMerchantView(_ isFetchMerchant: Bool = true, isLoginUser: Bool){
        guard merchant != nil else { return }
        
        var fetchMerchantPromise: Promise<Any> = Promise{ fulfill, reject in
            fulfill("OK")
        }
        
        if isFetchMerchant{
            fetchMerchantPromise = self.fetchMerchant(self.merchant!)
        }
        
        var checkMerchantPromise: Promise<Any> = Promise{ fulfill, reject in
            fulfill("OK")
        }
        
        if isLoginUser{
            checkMerchantPromise = self.checkMerchant(self.merchant!)
        }
        
        firstly {
            return fetchMerchantPromise
            }.then { _ -> Promise<Any> in
                return checkMerchantPromise
            }.then { _ -> Void in
                self.fetchProductList()
            }.catch { _ -> Void in
                Log.error("error")
        }
    }

    func getProductList(_ merchant: Merchant)-> Promise<Any> {
        return Promise{ fulfill, reject in
            MerchantService.getProductListOfMerchant(merchant.merchantId) { [weak self] (response) in
                if let strongSelf = self {
                    if response.response?.statusCode == 200 {
               
                        background_async {
                            if let styleResponse = Mapper<SearchResponse>().map(JSONObject: response.result.value){
                                if let styles = styleResponse.pageData {
                                    strongSelf.styles = styles
                                    strongSelf.filteredStyles = strongSelf.styles.filter({ !$0.isOutOfStock() && $0.isValid() })
                                } else {
                                    strongSelf.styles = []
                                    strongSelf.filteredStyles = []
                                }
                            }
                            main_async {
                                fulfill("OK")
                            }
                        }
                    } else {
                        strongSelf.handleError(response, animated: true, reject: reject)
                    }
                }
            }
        }
    }
    
    func checkMerchant(_ merchant: Merchant)-> Promise<Any> {
        return Promise{ fulfill, reject in
            RelationshipService.relationshipByMerchant(merchant.merchantId) { [weak self] (response) in
                if let strongSelf = self {
                    if response.response?.statusCode == 200 {
                        
                        background_async {
                            if let relationShip = Mapper<Relationship>().map(JSONObject: response.result.value) {
                                strongSelf.isFollowing = relationShip.isFollowing
                                main_async {
                                    fulfill("OK")
                                }
                            }else {
                                ErrorLogManager.sharedManager.recordNonFatalError(withException: .FailToParseAPIResponse)
                                let error = NSError(domain: "", code: -999, userInfo: nil)
                                main_async {
                                    reject(error)
                                }
                            }
                        }
                        
                    } else {
                        strongSelf.handleError(response, animated: true)
                    }
                }
            }
        }
    }
    
    func fetchMerchant(_ merchant: Merchant) -> Promise<Any>{
        return Promise{ fulfill, reject in
            MerchantService.view(merchant.merchantId){[weak self] (response) in
                if let strongSelf = self {
                    if response.result.isSuccess {
                        if response.response?.statusCode == 200 {
                            background_async {
                                if  let merchants = Mapper<Merchant>().mapArray(JSONObject: response.result.value) {
                                    if let index = merchants.index(where: { $0.merchantId == merchant.merchantId }) {
                                        let obj = merchants[index]
                                        strongSelf.merchant = obj
                                        main_async {
                                            fulfill("OK")
                                        }
                                    }else {
                                        let error = NSError(domain: "", code: -999, userInfo: nil)
                                        main_async {
                                            reject(error)
                                        }
                                        
                                    }
                                    
                                }else {
                                    let error = NSError(domain: "", code: -999, userInfo: nil)
                                    main_async {
                                        reject(error)
                                    }
                                }
                                
                            }
                            
                        } else {
                            var statusCode = 0
                            if let code = response.response?.statusCode {
                                statusCode = code
                            }
                            let error = NSError(domain: "", code: statusCode, userInfo: nil)
                            reject(error)
                        }
                    } else {
                        reject(response.result.error!)
                    }
                }
            }
        }
    }
    
    func updateNewsFeed(pageno: Int, completion:(()->Void)? = nil) {
        guard merchantKey != "0" else {
            return
        }
        
        guard postManager != nil else {
            return
        }
        
        firstly {
            return postManager.fetchNewsFeed(.merchantFeed, merchantId: merchant?.merchantId, pageno: pageno)
            }.then { postIds -> Promise<Any> in
                return self.postManager.getPostActivitiesByPostIds(postIds as! String)
            }.then { _ -> Void in
                
                self.collectionView.reloadData()
                if self.collectionView.contentSize.height < ScreenHeight {
                    self.collectionView.contentInset = UIEdgeInsets(top: 0, left: 0, bottom: ScreenWidth * 0.6, right: 0)
                } else {
                    self.collectionView.contentInset = UIEdgeInsets(top: 0, left: 0, bottom: ScreenWidth * 0.4, right: 0)
                }
            }.always {
                self.isLoadFeedDone = true
                if let completion = completion{
                    completion()
                }
            }.catch { _ -> Void in
                Log.error("error")
        }
    }
    
    func getSelectedSku(_ style: Style) -> Sku?{
        var selectedColorKey = ""
        if let defaultSku =  style.defaultSku() {
            selectedColorKey = defaultSku.colorKey
        }
        let selectedSizeId = style.defaultSku()?.sizeId ?? 0
        
        let selectedSku = style.searchSkuIdAndColorKey(selectedSizeId, colorKey: selectedColorKey)
        
        return selectedSku ?? style.defaultSku()
    }
    

    //MARK:- CollectionViewDelegate
    func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        if indexPath.section == MerchantProfileSection.tileFeature.rawValue {
            
            let isIndexValid = productTiles.indices.contains(indexPath.row)
            if (!isIndexValid){ return }
            
            let tile = productTiles[indexPath.row]
            
            if tile.link.length > 0 {
                if tile.link.contains(Constants.MagazineCoverList) {
                    // open as magazine cover list
                    
                    let magazineCollectionViewController = MagazineCollectionViewController()
                    self.navigationController?.push(magazineCollectionViewController, animated: true)
                    
                } else {
                    Navigator.shared.dopen(tile.link)
                }
            }
            
            if collectionView.indexPathIsValid(indexPath){
                if let cell = collectionView.cellForItem(at: indexPath) as? FeatureCollectionCell {
                    cell.recordAction(.Tap, sourceRef: String(indexPath.row + 1), sourceType: .TileBanner, targetRef: tile.link, targetType: .URL)
                }
            }
            
        }
    }
    
    func numberOfSections(in collectionView: UICollectionView) -> Int {
        return MerchantProfileSection.footer.rawValue
    }
    
    override func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        switch section {
        case MerchantProfileSection.productList.rawValue:
            return filteredStyles.count > 0 ? 1 : 0
        case MerchantProfileSection.tileFeature.rawValue:
            return productTiles.count
        case MerchantProfileSection.feed.rawValue where postManager != nil:
            return (merchant != nil && postManager.currentPosts.count > 0) ? postManager.currentPosts.count + (postManager.hasLoadMore ? 1 : 0) : 0
        default:
            return 0
        }
    }
    
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, minimumInteritemSpacingForSectionAt section: Int) -> CGFloat {
        return 0
    }
    
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, minimumLineSpacingForSectionAt section: Int) -> CGFloat {
        return section == MerchantProfileSection.feed.rawValue ? PostManager.NewsFeedLineSpacing : 0
    }
    
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, insetForSectionAt section: Int) -> UIEdgeInsets {
        if section == 0{
            return sectionInsets
        }
        return UIEdgeInsets.zero
    }
    
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, referenceSizeForHeaderInSection section: Int) -> CGSize {
        if let sectionType = MerchantProfileSection(rawValue: section){
            switch sectionType{
            case .feed where postManager != nil && postManager.currentPosts.count > 0:
                return CGSize(width: collectionView.bounds.size.width, height: HomeHeaderView.ViewHeight)
            default:
                break
            }
        }
        
        return CGSize(width: collectionView.bounds.size.width,height: 0)
    }
    
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, referenceSizeForFooterInSection section: Int) -> CGSize {
        return CGSize(width: collectionView.bounds.size.width,height: 0)
    }
    
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, sizeForItemAt indexPath: IndexPath) -> CGSize {
        switch indexPath.section {
        case MerchantProfileSection.productList.rawValue:
            return CGSize(width: self.collectionView.frame.size.width, height: ProductListHeight)
        case MerchantProfileSection.tileFeature.rawValue:
            var width : CGFloat = 0
            let height : CGFloat = ceil(collectionView.frame.size.width / 2)
            if indexPath.row % 2 == 0 {
                width = ceil(collectionView.frame.size.width / 2)
            } else {
                width = collectionView.frame.size.width - ceil(collectionView.frame.size.width / 2)
            }
            if productTiles.count == 0 {
                return CGSize(width: width, height: 0)
            }
            return CGSize(width: width, height: height)
        case MerchantProfileSection.feed.rawValue where postManager != nil:
            if indexPath.row == postManager.currentPosts.count {
                if (postManager.hasLoadMore) {
                    return CGSize(width: self.view.frame.size.width, height: Constants.Value.CatCellHeight)
                }
            }
            
            return CGSize(width: self.view.frame.size.width, height: postManager.getHeightAtIndex(indexPath)) //risk
        default:
            return CGSize(width: self.collectionView.frame.size.width, height: 0)
        }
    }
    
    func collectionView(_ collectionView: UICollectionView, viewForSupplementaryElementOfKind kind: String, at indexPath: IndexPath) -> UICollectionReusableView {
        if kind == UICollectionElementKindSectionHeader {
            if let sectionType = MerchantProfileSection(rawValue: indexPath.section){
                switch sectionType{
                case .feed:
                    if let headerView = collectionView.dequeueReusableSupplementaryView(ofKind: UICollectionElementKindSectionHeader, withReuseIdentifier: HeaderViewIdentifier, for: indexPath) as? HomeHeaderView {
                        headerView.label.text = String.localize("LB_CA_HIGHLIGHT_POST")
                        headerView.formatStyle(UIFont(name: Constants.Font.Normal, size: 16), textColor: UIColor.secondary2(), lineColor: UIColor.secondary3(), lineSize: CGSize(width: 50, height: 1), space: CGFloat(24))
                        return headerView
                    }
                    
                default:
                    break
                }
            }
        }
        
        return collectionView.dequeueReusableSupplementaryView(ofKind: kind, withReuseIdentifier: CollectionReusableViewIdentifier, for: indexPath)
    }
    
    override func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        switch indexPath.section {
        case MerchantProfileSection.productList.rawValue:
            if let cell = collectionView.dequeueReusableCell(withReuseIdentifier: MerchantProductListCollectionCell.CellIdentifier, for: indexPath) as? MerchantProductListCollectionCell {
                cell.merchant = self.merchant
                cell.analyticsViewKey = self.analyticsViewRecord.viewKey
                cell.reloadData(self.styles, filteredStyles: self.filteredStyles)
                cell.formatStyle(UIFont(name: Constants.Font.Normal, size: 16), textColor: UIColor.secondary2(), lineColor: UIColor.secondary3(), lineSize: CGSize(width: 50, height: 1))
                cell.delegate = self
                cell.ownerViewController = self
                return cell
            }
        case MerchantProfileSection.tileFeature.rawValue :
            if let cell = collectionView.dequeueReusableCell(withReuseIdentifier: FeatureCollectionCell.CellIdentifier, for: indexPath) as? FeatureCollectionCell {
                let data = productTiles[indexPath.row]
                cell.featureImageView.mm_setImageWithURL(ImageURLFactory.URLSize512(data.merchantImage, category: .merchant), placeholderImage: UIImage(named: "tile_placeholder"), clipsToBounds: true, contentMode: .scaleAspectFill, progress: nil, optionsInfo: nil, completion: { (image: UIImage?, error, cacheType, imageURL) in
                    if error == nil {
                        cell.featureImageView.contentMode = .scaleAspectFill
                        cell.featureImageView.backgroundColor = UIColor.white
                    } else {
                        cell.featureImageView.contentMode = .center
                        cell.featureImageView.backgroundColor = UIColor.primary2()
                    }
                    // cell.featureImageView.image = image
                })
                let viewKey = self.analyticsViewRecord.viewKey
                if let merchant = self.merchant, self.merchant?.merchantName.length > 0{
                    cell.initAnalytics(withViewKey: viewKey, impressionKey: AnalyticsManager.sharedManager.recordImpression(authorType: nil, brandCode: nil, impressionRef: "\(merchant.merchantId)", impressionType: "Merchant", impressionVariantRef: nil, impressionDisplayName: merchant.merchantName, merchantCode: merchant.merchantCode, parentRef: nil, parentType: nil, positionComponent: "TileBanner", positionIndex: (indexPath.row + 1), positionLocation: "MPP", referrerRef: nil, referrerType: nil, viewKey: viewKey))
                }
                return cell
            }
        case MerchantProfileSection.feed.rawValue where postManager != nil:
            
            if indexPath.row == postManager.currentPosts.count {
                let cell = loadingCellForIndexPath(indexPath)
                cell.initAnalytics(withViewKey: self.analyticsViewRecord.viewKey)
                if (!postManager.hasLoadMore) {
                    cell.isHidden = true
                } else {
                    cell.isHidden = false
                    
                    self.updateNewsFeed(pageno: postManager.currentPageNumber + 1)
                }
                return cell
            }
            
            if let cell = postManager.getNewsfeedCell(indexPath) as? MyFeedCollectionViewCell{
                if !myFeedCollectionViewCells.contains(cell) {
                    myFeedCollectionViewCells.append(cell)
                }
                
                cell.checkoutDelegate = self
                cell.tag = indexPath.row
                cell.recordImpressionAtIndexPath(indexPath, positionLocation: "MPP", viewKey: self.analyticsViewRecord.viewKey)
                
                return cell
            }
            
        default:
            break
        }
        
        return getDefaultCell(collectionView, cellForItemAt: indexPath)
    }
    
    func loadingCellForIndexPath(_ indexPath: IndexPath) -> UICollectionViewCell {
        let cell = getDefaultCell(self.collectionView, cellForItemAt: indexPath)
        for view in cell.contentView.subviews {
            view.removeFromSuperview()
        }
        cell.contentView.backgroundColor = UIColor.white
        let activity = UIActivityIndicatorView(activityIndicatorStyle: UIActivityIndicatorViewStyle.gray)
        activity.center = cell.center
        var rect = activity.frame
        rect.origin.y -= 0.0
        activity.frame = rect
        cell .addSubview(activity)
        activity.startAnimating()
        return cell
    }
    
    func getDefaultCell(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        let cell = collectionView.dequeueReusableCell(withReuseIdentifier: CellId, for: indexPath)
        return cell
    }
    
    //MARK: -- PullToRefreshViewDelegate
    func didEndPullToRefresh() {
        self.updateNewsFeed(pageno: 1, completion: {
        })
    }
    
    //MARK: - Merchant Product List Delegate
    func didselctedProduct(_ style: Style) {
        let styleViewController = StyleViewController(style: style)
        
        self.navigationController?.push(styleViewController, animated: true)
    }
    
    func didSelectedHeartImageView(_ style: Style, cell: ProductCollectionViewCell) {
        if  let selectedSku = self.getSelectedSku(style) {
            
            let sourceRef = style.isWished() ? "Wishlist-Remove" : "Wishlist-Add"
            cell.recordAction(.Tap, sourceRef: sourceRef, sourceType: .Button, targetRef: "\(style.styleCode)", targetType: .Product)
            
            if selectedSku.isWished() {
                
                cell.heartImageView.image = UIImage(named: "ic_grey_star_plp")
                
                let cartItemId = CacheManager.sharedManager.cartItemIdForSku(selectedSku)
                
                firstly{
                    return self.removeWishlistItem(cartItemId)
                    }.always {
                        // reload UI
                        self.collectionView.reloadData()
                        self.updateButtonWishlistState()
                    }.catch { _ -> Void in
                        Log.error("error")
                }
            } else {
                var isServiceDone = false
                var isAnimationDone = false
                
                cell.heartImageView.image = UIImage(named: "ic_red_star_plp")
                
                let wishListAnimation = WishListAnimation(heartImage: cell.heartImageView, redDotButton: self.buttonWishlist)
                wishListAnimation.setAnimationImage(UIImage(named: "ic_red_star_plp"))
                wishListAnimation.showAnimation(completion: {
                    isAnimationDone = true
                    if isServiceDone {
                        self.collectionView.reloadData()
                        self.updateButtonWishlistState()
                    }
                })
                
                firstly {
                    return self.addWishlistItem(style.merchantId, skuId: selectedSku.skuId, isSpecificSku: false, referrer: nil)
                    }.always {
                        // reload UI
                        isServiceDone = true
                        if isAnimationDone {
                            self.collectionView.reloadData()
                            self.updateButtonWishlistState()
                        }
                    }.catch { _ -> Void in
                        Log.error("error")
                }
            }
        }
        
    }
    
    // MARK: - Handle animations
    @objc func startAllAnimations() {
        for cell in myFeedCollectionViewCells {
            cell.resetAnimation()
        }
    }
    
    @objc func stopAllAnimations() {
        for cell in myFeedCollectionViewCells {
            cell.stopAnimation()
        }
    }
    
    //MARK: - UIScrollView Delegate
    func scrollViewDidEndScrollingAnimation(_ scrollView: UIScrollView) {
        if scrollView == self.collectionView{
            scrollViewDidEndScrollingAnimationAction?(scrollView)
        }
    }
    
    func scrollViewDidScroll(_ scrollView: UIScrollView) {
        if scrollView == self.collectionView{
            scrollViewDidScrollAction?(scrollView)
        }
    }
    
    //MARK: Handle update following event
    @objc func followingMerchantDidUpdate(_ notification: Notification) {
        if !self.isVisible {
            if let object = notification.object, object is Merchant {
                if let merchant = object as? Merchant, merchant.merchantId == self.merchant?.merchantId {
                    self.needReloadData = true
                }
            }
        }
    }
    
    func doActionBuy(_ isSwipe : Bool, index: Int) {
        
        if postManager == nil {
            return
        }
        
        let post = self.postManager.currentPosts[index]
        
        let styleCodes = (post.skuList ?? []).map({ $0.styleCode })
        let merchantIds = post.getMerchantIds()
        let postSkus = post.skuList ?? []
        CheckoutService.defaultService.searchStyle(withStyleCodes: styleCodes, merchantIds: merchantIds).then { (searchStyles) -> Void in
            if searchStyles.count > 0{
                var checkOutStyles = [Style]()
                var checkOutValidStyles = [Style]()
                var checkOutInValidOutOfStockStyles = [Style]()
                
                for postSku in postSkus{
                    let validStyles = searchStyles.filter{$0.styleCode == postSku.styleCode && $0.merchantId == postSku.merchantId}
                    if let validStyle = validStyles.first{
                        if validStyle.isValid() && !validStyle.isOutOfStock(){
                            checkOutValidStyles.append(validStyle)
                        }
                        else{
                            checkOutInValidOutOfStockStyles.append(validStyle)
                        }
                    }
                    else{
                        let inActiveStyle = postSku.createStyle()
                        inActiveStyle.statusId = Constants.StatusID.inactive.rawValue
                        inActiveStyle.merchantStatusId = Constants.StatusID.inactive.rawValue
                        inActiveStyle.brandStatusId = Constants.StatusID.inactive.rawValue
                        for sku in inActiveStyle.skuList{
                            sku.statusId = Constants.StatusID.inactive.rawValue
                        }
                        checkOutInValidOutOfStockStyles.append(inActiveStyle)
                    }
                }
                
                if checkOutValidStyles.count > 0{
                    checkOutStyles.append(contentsOf: checkOutValidStyles)
                }
                
                if checkOutInValidOutOfStockStyles.count > 0{
                    checkOutStyles.append(contentsOf: checkOutInValidOutOfStockStyles)
                }
                
                let checkoutViewController = FCheckoutViewController(checkoutMode: .multipleMerchant, skus: post.skuList ?? [], styles: checkOutStyles, referrer: nil, redDotButton: self.buttonCart)
                
                checkoutViewController.didDismissHandler = { confirmed, parentOrder in
                    self.updateButtonCartState()
                    self.updateButtonWishlistState()
                    
                    if confirmed {
                        self.showLoading()
                        self.paidOrder = parentOrder
                        Timer.scheduledTimer(timeInterval: 0.5, target: self, selector: #selector(self.showThankYouPage), userInfo: nil, repeats: false)
                    }
                }
                
                let navigationController = MmNavigationController()
                navigationController.viewControllers = [checkoutViewController]
                navigationController.modalPresentationStyle = .overFullScreen
                
                self.present(navigationController, animated: false, completion: nil)
            } else {
                self.showError(String.localize("MSG_ERR_POST_ALL_INVALID"), animated: true)
            }
        }
        
    }
    
    func initAnalytics() {
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
}

extension UICollectionView {
    func indexPathIsValid(_ indexPath: IndexPath) -> Bool {
        if indexPath.row >= self.numberOfItems(inSection: indexPath.section) {
            return false
        }
        return true
    }
}
