//
//  StyleViewController.swift
//  merchant-ios
//
//  Created by Koon Kit Chan on 27/11/15.
//  Copyright © 2015 Koon Kit Chan. All rights reserved.
//

import Foundation
import PromiseKit
import ObjectMapper
import SwiftDate
import Kingfisher
import SnapKit
import SKPhotoBrowser
import Alamofire

class StyleViewController: MmCartViewController, RatingHeaderViewDelegate,StyleCouponDelegate {
    
    enum EntryPoint: Int{
        case Unknown = 0,
        PLP,
        DeepLink
    }
    
    internal enum SectionType: Int {
        case ProductImageSection = 0  // 产品图片
        case FlashSaleSection         // 新人价
        case BrandNameSection
        case ColorListSection         // 颜色
        case SizeListSection          // 尺寸
        case MerchantSection          // 店铺
        case StylePriceSection        // 商品价格
        case StyleRealPriceSection    // 商品原价
        case StyleGetPriceSection     // 到手价
        case StyleTipGetPriceSection  // 到手价提示
        case StyleNameSection         //商品名
        case StyleBrandSection        //品牌
        case CouponSection            // 优惠券
        case ReviewSection
        case UserListSection         // 相关用户
        case RecommendSection        // 评论
        case DescriptionSection      // 描述
        case ImageListSection        // 图片列表
        case CrossBorderStatementSection
        case OutfitSection
        case SuggestSection     // 相关建议 相关商品
        case LastestPostSection // 相关帖子
        case MarginSection      //间隔
    }
    
    private enum CollectionViewType: Int {
        case UnknownCollection = 0
        case RootCollection
        case UserCollection
        case FeatureCollection
    }
    
    private enum ReviewRow: Int {
        case Unknown = -1
        case UserReviewRow = 0
        case ImagesReviewRow = 1
        case DescriptionReviewRow = 2
    }
    
    private enum BottomButtonTag: Int {
        case UnknownButton = 0
        case SwipeToBuy
        case CustomerService
        case CreatePost
        case ShareProduct
    }
    
    private enum BuyOrAddCartType {
        case HandleBuy // 立即购买
        case AddCart // 加入购物袋
    }
    
    internal static let SizeEdgeInsets = UIEdgeInsets(top: 0, left: 15, bottom: 0, right: 15)
    
    let ColorListSpacing: CGFloat = 10
    var skuId = 0
    var merchantId = 0
    var referrerUserKey: String?
    var checkoutFromSource: CheckoutFromSource = .unknown
    
    private var entryPoint = EntryPoint.Unknown
    private var style = Style()
    private var merchant: Merchant?
    private var searchedStyle: Style?
    private var suggestStyles: [Style] = []
    private var syteStyles: [Style] = []
    private var styleFilter = StyleFilter()
    private var productLikeList: [ProductLikeItem] = []
    
    private var featureCollectionView: UICollectionView?
    private var userCollectionView: UICollectionView?
    private var suggestColectionView: UICollectionView?
    private var inactiveProductView = UIView()
    private var myFeedCollectionViewCells = [SimpleFeedCollectionViewCell]()
    private var IMButton: UIButton?
    private var createPostButton: UIButton?
    private var featureImageCell: FeatureImageCell!
    private var productImagePageControl: UIPageControl?
    private var viewImageTile = UIImageView()
    private var videoCell: FeatureVideoCell?
    private var isVideoCellShowingPresenting = false
    private var detailCollectionViewFlowLayout: DetailCollectionViewFlowLayout?
    
    private var tapGesture: UITapGestureRecognizer?
    
    private var colorIndexSelected = -1
    private var sizeIndexSelected = -1
    private var selectedSizeId = -1
    private var selectedSku: Sku?
    private var syteLoaded: Bool = false
    
    //
    var selectedColorId = -1
    private var selectedColorKey = ""
    //    private var selectedSkuColor = ""
    
    private var currentPage = 0
    private var swipeMenu: SwipeMenu?
    private var filteredColorImageList: [Img] = []
    
    private var summaryReview: ProductReview?
    private var listReviewImages: [ImageBucket] = []
    private var reviewAnalyticsSectionData: AnalyticsSectionData?
    
    private var lastOffset: CGFloat = 0
    
    private var sectionImageListHeight: [String : CGFloat] = [String : CGFloat]()
    
    private var paidOrder: ParentOrder?
    
    private var isSelected = false
    
    private final let CellId = "Cell"
    private final let FeatureCellId = "FeatureCell"
    private final let NameCellId = "NameCell"
    private final let DescCellId = "DescCell"
    private final let DefaultFooterID = "DefaultFooter"
    private final let RecommendCellId = "RecommendCell"
    private final let DescCollectCellId = "DescCollectCell"
    private final let UserCellId = "UserCell"
    private final let UserCollectionCellId = "UserCollectionCell"
    private final let SuggestionCellId = "SuggestionCell"
    private final let CMSPageNewsfeedCommodityCellId = "CMSPageNewsfeedCommodityCell"
    private final let FeatureCollectCellId = "FeatureCollectCell"
    
    private final let LabelInactiveTag = 999
    
    private final let ColorCellTopPadding: CGFloat = 14
    private final let ColorCellDimension: CGFloat = 40
    private final let SizeHeaderViewTopPadding: CGFloat = 15
    private final let SizeHeaderViewHeight: CGFloat = 30
    private final let SwipeViewHeight: CGFloat = 45 + ScreenBottom
    private final let RecommendCellHeight: CGFloat = 35
    private final let UserCellHeight: CGFloat = 60
    private final let UserCellWidth: CGFloat = ScreenWidth / 7 - 15
    private final let UserCellLineSpacing: CGFloat = 6
    private final let HeaderHeight: CGFloat = 30
    private final let HeightTopDescriptionBorder: CGFloat = 6
    private final let SuggestionHeaderHeight: CGFloat = 61
    private final let ImageListHeaderHeight: CGFloat = 1
    private final let FooterFreeShipHeight: CGFloat = 50
    
    private final let NoColor = 1
    private final let NoSize = 1
    
    private var isFlashSaleEligible = false
    private var isFlashSaleDiscount: Bool {
        get {
            var sku = Sku()
            if let selectedSku = selectedSku {
                sku = selectedSku
            }
            return isFlashSaleEligible && sku.isFlashSaleExists
        }
    }
    
    private var couponSuggestionPopView: UIView?
    private var buttonSuggestionPopView: UIButton?
    //    private var swipeViewContainer: UIView!
    private var bottomView: ProductDetailBottomView!
    private var currentImage: UIImage?
    @objc private func popViewController() {
        self.navigationController?.popViewController(animated: true)
    }
    
    private var newsFeeds = [NewsFeedListResponse]()
    
    private var profileUserKey: String {
        get {
            return Context.getUserKey()
        }
    }
    
    private var sectionList = [SectionType]()
    private var isNeedHookPostManager = false
    private var pageNo = 1
    private var pageTotal = 0
    private var postManager: PostManager!
    
    private var coupons = [Coupon]()
    private var claimedCoupons = [Coupon]()
    
    private var isProductActive = true
    
    private var fetchedMerchant = false
    private var fetchedDataSource = false
    private var isFetchingSuggestedProducts = false
    
    private var brandNameCell: BrandNameCell? = nil
    
    private var skPhotoBrowser: SKPhotoBrowser?
    
    convenience init(style: Style? = nil, styleFilter: StyleFilter? = nil, isProductActive: Bool = true, entryPoint: EntryPoint = EntryPoint.Unknown) {
        self.init(nibName: nil, bundle: nil)
        
        self.isProductActive = isProductActive
        self.entryPoint = entryPoint
        
        if isProductActive {
            if let style = style {
                self.style = style
            }
            
            if let styleFilter = styleFilter {
                self.styleFilter = styleFilter
            }
        }
    }
    private var isLoginStatueEnter = false //是登录状态进入
    private var contentOffsetY:CGFloat = 0.0
    private var navigationBarVisibility: MmFadeNavigationControllerNavigationBarVisibility = .hidden {
        didSet {
            UIApplication.shared.statusBarStyle = self.navigationBarVisibility == .visible ? .default : .default
        }
    }
    private lazy var backButton:UIButton = {
        let backButton: UIButton = UIButton()
        backButton.setImage(UIImage(named: "greyBack"), for: .normal)
        backButton.frame = CGRect(x: 0, y: 0, width: 30, height: 25)
        backButton.contentEdgeInsets = UIEdgeInsets.init(top: 0, left: -10, bottom: 0, right: 0)
        backButton.addTarget(self, action: #selector(popViewController), for: .touchUpInside)
        return backButton
    }()
    private lazy var shareButton:UIButton = {
        let shareButton: UIButton = UIButton()
        shareButton.setImage(UIImage(named: "greyShare"), for: .normal)
        shareButton.frame = CGRect(x: 0, y: 0, width: 30, height: 25)
        shareButton.contentEdgeInsets = UIEdgeInsets.init(top: 0, left: 5, bottom: 0, right: 0)
        shareButton.addTarget(self, action: #selector(share), for: .touchUpInside)
        return shareButton
    }()
    private var isSelectStyleTipGetPrice:Bool = false
    
    override func viewDidLoad() {
        //页面进入时登录状态，后面需要根据状态刷新整个页面
        self.isLoginStatueEnter = LoginManager.getLoginState() == .validUser
        
        super.viewDidLoad()
        
        NotificationCenter.default.addObserver(self, selector: #selector(StyleViewController.orderCreatedSuccess), name: Constants.Notification.orderCreatedSucceed, object: nil)
        
        self.configImageViewer()
        
        pageAccessibilityId = "PDP"
        if let referrerUserKey = ssn_Arguments["UserKeyReferrer"]?.string {
            self.referrerUserKey = referrerUserKey
        }
        
        if let skuId = ssn_Arguments["skuId"]?.int {
            self.skuId = skuId
            
            if subviewDidLoad() {
                return
            }
            
            //因为以前的加载代码没有loading，而且都是提前渲染，现在只有skuid时，
            // 需要异步取style，会看到明显刷新过程，体验稍差，后续请优化
            loadStyle(skuId: skuId)
        } else {
            self.skuId = style.defaultSku()?.skuId ?? 0
            
            if subviewDidLoad() {
                return
            }
            
            self.checkStyleContainFlashSale()
            
            preDataLoad()
            
            loadData()
        }
        setupNavigationBarTitle()
    }
    
    @objc func orderCreatedSuccess() {
        if self.isFlashSaleEligible {
            self.isFlashSaleEligible = false //不再满足，所以页面需要重新刷新
            self.reloadAllData()
        }
        
    }
    
    func subviewDidLoad() -> Bool {
        postManager = PostManager(postFeedTyle: .productFeed, skuId: self.skuId, collectionView: collectionView, viewController: self)
        
        setupNavigationBarButtons()
        setupCollectionView()
        
        if swipeMenu == nil {
            //createSwipeView()
            createBottomView()
        }
        
        setupInactiveProductView()
        
        if !isProductActive {
            inactiveProductView.isHidden = false
            return true
        }
        
        return false
    }
    
    func preDataLoad() {
        
        if skuId > 0 {
            updateNewsFeed(pageno: 1, skuId: skuId)
        } else {
            isNeedHookPostManager = true
        }
        
        
        
        setupDefaultColorSize()
        
        var merchantCode = merchant?.merchantCode ?? ""
        if merchantCode.isEmpty{
            if let merchant = CacheManager.sharedManager.cachedMerchantById(style.merchantId){
                merchantCode = merchant.merchantCode
            }
        }
        initAnalyticsViewRecord(brandCode: "", merchantCode: merchantCode, viewDisplayName: "\(style.skuName)", viewLocation: "PDP", viewRef: "\(style.styleCode)", viewType: "Product")
        
        fetchProductList(pageNumber: 1)
        
        self.bottomView.setLike(self.style.isWished()) // 设置收藏按钮的状态
    }
    
    func loadStyle(skuId:Int) {
        SearchService.searchStyleBySkuId(skuId) { (response) in
            
            if response.result.isSuccess {
                if response.response?.statusCode == 200 {
                    if let styleResponse = Mapper<SearchResponse>().map(JSONObject: response.result.value),
                        let pageData = styleResponse.pageData,
                        let style = pageData.first {
                        self.style = style
                        self.preDataLoad()
                        self.loadData()
                        self.checkStyleContainFlashSale()
                        return
                    } else if !self.style.isValid() { //直接展示售罄就行了
                        self.isProductActive = false
                    }
                }
            }
            
            self.reloadAllData()
        }
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        //用于相关商品埋点使用(新埋点，需要老的viewKey)
        if !self.analyticsViewRecord.viewKey.isEmpty {
            self.ssn_setTag(PAGE_VIEW_UUID_KEY, tag: self.analyticsViewRecord.viewKey)
        }
        
        NotificationCenter.default.addObserver(self, selector: #selector(self.didReceiveScreenCapNotification), name: NSNotification.Name.UIApplicationUserDidTakeScreenshot, object: nil)
        
        reloadAllData()
        
        if entryPoint == .PLP || entryPoint == .DeepLink{
            inactiveProductView.isHidden = style.isValid()
        } else {
            inactiveProductView.isHidden = isProductActive
            
            if let strongStyle = self.searchedStyle {
                inactiveProductView.isHidden = strongStyle.isValid()
            }
        }
        
        if !isNetworkReachable() || !fetchedDataSource{
            bottomView.setEnable(false)
            //enableSwipeViewContainer(false)
        }

        if let navigationController = self.navigationController as? MmNavigationController {
            var alpha = contentOffsetY / 100
            if alpha > 1 {
                alpha = 1
                self.navigationItem.titleView?.isHidden = false
            } else {
                self.navigationItem.titleView?.isHidden = true
            }
            self.navigationItem.titleView?.alpha = alpha
            navigationController.setNavigationBarVisibility(offset: contentOffsetY)
            navigationController.navigationBar.shadowImage = UIImage()
        }
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        
        updateSwipeMenuPrice()
        
        NotificationCenter.default.addObserver(self, selector: #selector(self.loadData), name: NSNotification.Name(rawValue: kReachabilityNetworkConnected), object: nil)
        
        UIApplication.shared.statusBarStyle = .default
        
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        
        NotificationCenter.default.removeObserver(self, name: NSNotification.Name.UIApplicationWillEnterForeground, object: nil)
        NotificationCenter.default.removeObserver(self, name: NSNotification.Name.UIApplicationDidEnterBackground, object: nil)
        NotificationCenter.default.removeObserver(self, name: NSNotification.Name.UIApplicationUserDidTakeScreenshot, object: nil)
        NotificationCenter.default.removeObserver(self, name: NSNotification.Name(rawValue: kReachabilityNetworkConnected), object: nil)
        NotificationCenter.default.removeObserver(self, name: NSNotification.Name(rawValue: IMDidWebsocketConnected), object: nil)
        
        //make sure count down timer stop
        brandNameCell?.stopCountDown()
        
        videoCell?.stopVideo()
        videoCell?.videoURL = nil
        
//        self.navigationItem.titleView?.isHidden = true
    }
    
    override func viewWillLayoutSubviews() {
        super.viewWillLayoutSubviews()
        self.inactiveProductView.frame = self.view.frame
    }
    
    @objc func loadData(){
        if !checkNetworkConnection(){
            return
        }
        
        if !fetchedDataSource{
            bottomView.setEnable(false)
            //enableSwipeViewContainer(false)
        }
        
        var fetchStylePromise = Promise<Any>{ fulfill, reject in
            fulfill("OK")
        }
        
        if !(entryPoint == .PLP || entryPoint == .DeepLink){
            var merchantId = Int(0)
            
            if self.merchantId > 0 {
                merchantId = self.merchantId
            } else if style.merchantId > 0 {
                merchantId = style.merchantId
            }
            
            fetchStylePromise = searchStyleWithStyleCode(styleCode: style.styleCode, merchantId: merchantId)
        }
        
        firstly {
            return fetchStylePromise
            }.then { _ -> Promise<Any> in
                if self.skuId == 0 {
                    self.skuId = self.style.defaultSku()?.skuId ?? 0
                }
                
                return self.getLikesProduct(style: self.style)
            }.then { _ -> Promise<Any> in
                return self.fetchMerchant(merchantId: self.style.merchantId)
            }.then {  _ -> Promise<Any> in
                return self.viewSummaryReview(merchantId: self.style.merchantId, styleCode: self.style.styleCode)
            }.then { _ -> Void in
                self.fetchedDataSource = true
                self.updateSwipeMenuPrice()
                self.loadCoupon()
                self.reloadAllData()
                self.stopLoading()
                
            }.always {
                ErrorLogManager.sharedManager.recordNonFatalError(withException: .NullPointer)
                
            }.catch { _ -> Void in
                Log.error("error")
                if self.isProductActive{
                    self.showNoConnectionView(true, reloadHandler: {
                        self.loadData()
                    })
                    self.bottomView.setEnable(false)
                    //self.enableSwipeViewContainer(false)
                }
        }
        
        if style.isValid() && !style.isOutOfStock() {
            //记录最近浏览的sku
            BrowsingHistory.lookOverHistory(skuId: self.skuId, style: self.style)
        }
    }
    
    func updateNewsFeed(pageno: Int, skuId: Int) {
        firstly {
            // update inventory location if needed
            // if it is not updated, it will return success without api call
            return self.postManager.fetchNewsFeed(.productFeed, skuId: skuId, pageno: pageno)
            }.then { postIds -> Promise<Any> in
                return self.postManager.getPostActivitiesByPostIds(postIds as! String)
            }.always {
                self.collectionView?.reloadData()
                self.collectionView.collectionViewLayout.invalidateLayout()
            }.catch { _ -> Void in
                Log.error("error")
        }
    }
    
    func setupCollectionView() {
        if #available(iOS 11.0, *) {
            collectionView.contentInsetAdjustmentBehavior = UIScrollViewContentInsetAdjustmentBehavior.never
        } else {
            automaticallyAdjustsScrollViewInsets = false
        }
        
        let detailCollectionViewFlowLayout = DetailCollectionViewFlowLayout()
        detailCollectionViewFlowLayout.sectionInset = UIEdgeInsets(top: 0, left: 0, bottom: 0, right: 0)
        detailCollectionViewFlowLayout.itemSize = CGSize(width: self.view.frame.width, height: 120)
        self.detailCollectionViewFlowLayout = detailCollectionViewFlowLayout
        self.collectionView.setCollectionViewLayout(detailCollectionViewFlowLayout, animated: true)
        
        var statusBarFrameHeight = ScreenStatusHeight
        if IsIphoneX {
            statusBarFrameHeight = statusBarFrameHeight + 8
        }
        self.collectionView.frame = CGRect.init(x: 0, y: statusBarFrameHeight, width: ScreenWidth, height: ScreenHeight - statusBarFrameHeight)
        
        // Register to make sure app not crash when dequeue collection cell
        postManager.registerDisplayingCollectionView(self.collectionView)
        
        self.collectionView.backgroundColor = UIColor.white
        
        collectionView.register(UICollectionViewCell.self, forCellWithReuseIdentifier: CellId)
        collectionView.register(FeatureImageCell.self, forCellWithReuseIdentifier: FeatureCellId)
        collectionView.register(FlashSaleBarCell.self, forCellWithReuseIdentifier: FlashSaleBarCell.CellIdentifier)
        collectionView.register(NameCell.self, forCellWithReuseIdentifier: NameCellId)
        collectionView.register(BrandNameCell.self, forCellWithReuseIdentifier: BrandNameCell.CellIdentifier)
        collectionView.register(DescCell.self, forCellWithReuseIdentifier: DescCellId)
        collectionView.register(CrossBorderStatementCell.self, forCellWithReuseIdentifier: CrossBorderStatementCell.cellIdentifier)
        collectionView.register(UserCell.self, forCellWithReuseIdentifier: UserCellId)
        collectionView.register(RecommendedCell.self, forCellWithReuseIdentifier: RecommendCellId)
        collectionView.register(SuggestionCell.self, forCellWithReuseIdentifier: SuggestionCellId)
        collectionView.register(ColorCollectionCell.self, forCellWithReuseIdentifier: ColorCollectionCell.CellIdentifier)
        collectionView.register(SizeCollectionCell.self, forCellWithReuseIdentifier: SizeCollectionCell.CellIdentifier)
        collectionView.register(DescCollectCell.self, forCellWithReuseIdentifier: DescCollectCellId)
        collectionView.register(RatingUserCell.self, forCellWithReuseIdentifier: RatingUserCell.CellIdentifier)
        collectionView.register(PlainTextCell.self, forCellWithReuseIdentifier: PlainTextCell.CellIdentifier)
        collectionView.register(HorizontalImageCell.self, forCellWithReuseIdentifier: HorizontalImageCell.CellIdentifier)
        collectionView.register(MerchantCouponCell.self, forCellWithReuseIdentifier: MerchantCouponCell.CellIdentifier)
        collectionView.register(CMSPageBottomCell.self, forCellWithReuseIdentifier: CMSPageBottomCell.CellIdentifier)
        collectionView.register(StyleBrandCell.self, forCellWithReuseIdentifier: StyleBrandCell.CellIdentifier)
        collectionView.register(OrderMerchantCell.self, forCellWithReuseIdentifier: OrderMerchantCell.CellIdentifier)
        collectionView.register(CMSPageNewsfeedCommodityCell.self, forCellWithReuseIdentifier: CMSPageNewsfeedCommodityCellId)
        collectionView.register(StylePriceCell.self, forCellWithReuseIdentifier: StylePriceCell.CellIdentifier)
        collectionView.register(StyleRealPriceCell.self, forCellWithReuseIdentifier: StyleRealPriceCell.CellIdentifier)
        collectionView.register(StyleTagAndGetPriceCell.self, forCellWithReuseIdentifier: StyleTagAndGetPriceCell.CellIdentifier)
        collectionView.register(StyleTipCell.self, forCellWithReuseIdentifier: StyleTipCell.CellIdentifier)
        collectionView.register(StyleCouponCell.self, forCellWithReuseIdentifier: "StyleCouponCell")
        collectionView.register(StyleNameAndCollectCell.self, forCellWithReuseIdentifier: StyleNameAndCollectCell.CellIdentifier)
        
        
        collectionView.register(RatingHeaderView.self, forSupplementaryViewOfKind: UICollectionElementKindSectionHeader, withReuseIdentifier: RatingHeaderView.ViewIdentifier)
        collectionView.register(HeaderView.self, forSupplementaryViewOfKind: UICollectionElementKindSectionHeader, withReuseIdentifier: "Header")
        collectionView.register(SizeHeaderView.self, forSupplementaryViewOfKind: UICollectionElementKindSectionHeader, withReuseIdentifier: SizeHeaderView.ViewIdentifier)
        collectionView.register(UICollectionReusableView.self, forSupplementaryViewOfKind: UICollectionElementKindSectionFooter, withReuseIdentifier: DefaultFooterID)
        collectionView.register(UICollectionViewCell.self, forCellWithReuseIdentifier: "mock_review")
        collectionView.register(UICollectionViewCell.self, forCellWithReuseIdentifier: "mock_product")
        
        collectionView.register(FreeShipFooter.self, forSupplementaryViewOfKind: UICollectionElementKindSectionFooter, withReuseIdentifier: FreeShipFooter.FreeShipFooterId)
        collectionView.register(MyFeedCollectionViewCell.self, forCellWithReuseIdentifier: MyFeedCollectionViewCell.MyFeedCellId)
        collectionView.register(SimpleFeedCollectionViewCell.self, forCellWithReuseIdentifier: SimpleFeedCollectionViewCell.CellIdentifier)
        collectionView.register(SuggestionViewPostHeader.self, forSupplementaryViewOfKind: UICollectionElementKindSectionHeader, withReuseIdentifier: SuggestionViewPostHeader.SuggestionViewPostHeaderId)
        
        collectionView.register(CheckoutFooterView.self, forSupplementaryViewOfKind: UICollectionElementKindSectionFooter, withReuseIdentifier: CheckoutFooterView.ViewIdentifier)
        
        if let layout = collectionView.collectionViewLayout as? PinterestLayout {
            layout.delegate = self
        }
        collectionView.mj_footer = MMRefreshFooter(refreshingTarget: self, refreshingAction: #selector(footerRefursh))
    }
    
     @objc func footerRefursh()  {
        if pageNo < 10 {
            fetchProductList(pageNumber: pageNo)
        } else {
            collectionView.mj_footer.endRefreshing()
        }
        
    }
    
    private func updateSwipeMenuPrice() {
        if let swipeMenu = self.swipeMenu {
            var skuSelected: Sku? = nil
            var priceSale: Double = 0
            var priceRetail: Double = 0
            var isSale = 0
            
            if let searchSku = style.searchSkuIdAndColorKey(selectedSizeId, colorKey: self.selectedColorKey) {
                skuSelected = searchSku
            } else {
                skuSelected = style.defaultSku()
            }
            
            if skuSelected != nil {
                priceSale = skuSelected!.priceSale
                priceRetail = skuSelected!.priceRetail
                isSale = skuSelected!.isOnSale().hashValue
            } else {
                priceSale = style.priceSale
                priceRetail = style.priceRetail
                isSale = style.isOnSale().hashValue
            }
            
            swipeMenu.staticText = PriceHelper.getFormattedPriceText(withRetailPrice: priceRetail, salePrice: priceSale, isSale: isSale, retailPriceFontSize: 11, salePriceFontSize: 16)
            
            if(priceRetail != 0 || priceSale != 0){
                if let sku = skuSelected {
                    if(sku.isValid() && !sku.isOutOfStock()){
                        bottomView.setEnable(true)
                        //enableSwipeViewContainer(true)
                    }else{
                        bottomView.setEnable(false)
                        //enableSwipeViewContainer(false)
                    }
                }else{
                    bottomView.setEnable(false)
                    //enableSwipeViewContainer(false)
                }
                
                
            }else{
                bottomView.setEnable(false)
                //enableSwipeViewContainer(false)
            }
            
            
        } else {
            ErrorLogManager.sharedManager.recordNonFatalError(withException: .NullPointer)
        }
    }
    
    //Find sku list available
    private static func findSkuListAvailable(style searchStyle:Style, colorId: Int, colorKey:String,  sizeId: Int) -> [Sku] {
        
        var filteredSkuList = searchStyle.skuList
        if !colorKey.isEmpty {
            filteredSkuList = filteredSkuList.filter(){ ( $0.colorId == colorId || colorId == -1 ) && $0.colorKey == colorKey }
        }
        
        if sizeId != -1 {
            filteredSkuList = filteredSkuList.filter(){ $0.sizeId == sizeId }
        }
        
        filteredSkuList = filteredSkuList.filter(){!$0.isOutOfStock() }
        
        return filteredSkuList
    }
    
    private static func findSelectedSku(style searchStyle:Style, colorId: Int, colorKey:String, sizeId: Int) -> Sku? {
        var filteredSkuList = searchStyle.skuList
        if !colorKey.isEmpty && sizeId != -1 {
            filteredSkuList = filteredSkuList.filter(){ ( $0.colorId == colorId || colorId == -1 ) && $0.colorKey == colorKey && $0.sizeId == sizeId }
            if filteredSkuList.count > 0 {
                return filteredSkuList[0]
            }
        }
        
        if colorKey.isEmpty && sizeId == -1 {
            return searchStyle.defaultSku()
        }
        
        return nil
    }
    
    private func setupDefaultColorSize() {
        if !styleFilter.sizes.isEmpty{
            let filterValidSizes = self.styleFilter.sizes.filter(){$0.isValid == true}
            selectedSizeId = filterValidSizes[0].sizeId
        }
        
        if !styleFilter.colors.isEmpty {
            let filterValidColors = self.styleFilter.colors.filter(){$0.isValid == true}
            selectedColorId = filterValidColors[0].colorId
            selectedColorKey = filterValidColors[0].colorKey
        }
        
        let sizeList = style.validSizeList.filter(){$0.sizeId == selectedSizeId}
        
        if !sizeList.isEmpty{
            sizeIndexSelected = style.validSizeList.index{$0.sizeId == sizeList[0].sizeId} ?? 0
        }
        
        let skuListSelected = StyleViewController.findSkuListAvailable(style: self.style, colorId: selectedColorId, colorKey: selectedColorKey, sizeId: selectedSizeId)
        
        if skuListSelected.count <= 0 {
            //Current selected color and size is out of stock and need to be deselect
            selectedColorId = -1
            selectedColorKey = ""
            //            selectedSkuColor = ""
            selectedSizeId = -1
        } else {
            let colorList: [Color] = style.validColorList.filter(){
                $0.colorId == selectedColorId &&
                    (selectedColorKey.isEmpty ? true : selectedColorKey == $0.colorKey)
            }
            
            if !colorList.isEmpty {
                isSelected = true
                
                //Find available color by sku list. find the color without out of stock status
                let availableColors = colorList.filter({ (color) -> Bool in
                    var filteredSkuList = style.skuList.filter({ $0.colorId == color.colorId && $0.skuColor == color.skuColor})
                    filteredSkuList = filteredSkuList.filter({ !$0.isOutOfStock() })
                    return filteredSkuList.count > 0
                })
                
                if let color = availableColors.first{
                    selectedColorKey = color.colorKey
                    selectedColorId = color.colorId
                    //                    selectedSkuColor = color.skuColor
                    
                    colorIndexSelected = style.validColorList.index{$0.colorId == selectedColorId && $0.colorKey == selectedColorKey} ?? 0
                }
            }
        }
        
        let colorImages = style.colorImageList
        
        filteredColorImageList = colorImages.filter(){$0.colorKey == selectedColorKey}
        filteredColorImageList = filteredColorImageList.sorted(){$0.position < $1.position}
        
        if filteredColorImageList.count == 0 {
            filteredColorImageList = style.getDefaultImageList()
        }
        
        if (style.validSizeList.count == 1){
            sizeIndexSelected = 0
            selectedSizeId = style.validSizeList[0].sizeId
        }
        
        if (style.validColorList.count == 1){
            colorIndexSelected = 0
            let color = style.validColorList[0]
            selectedColorId = color.colorId
            selectedColorKey = color.colorKey
            //            selectedSkuColor = color.skuColor
        }
        
        reloadAllData()
        
        DispatchQueue.main.async {
            self.featureCollectionView?.scrollsToTop = true
        }
        
        if style.featuredImageList.count == 0 {
            style.featuredImageList = style.getDefaultImageList()
        }
        
    }
    
    private func setupInactiveProductView() {
        let summaryView = { () -> UIView in
            let frame = self.view.frame
            
            let view = UIView(frame: frame)
            view.backgroundColor = UIColor.white
            
            let label = UILabel(frame: CGRect(x: 0, y: 0, width: 0, height: 0))
            label.layoutInactiveOrOutOfStockLabel(forView: view, sizePercentage: 0.3)
            label.text = String.localize("LB_CA_OUT_OF_STOCK")
            view.addSubview(label)
            self.setAccessibilityIdForView("LB_CA_OUT_OF_STOCK", view: label)
            
            let confirmButton = { () -> UIButton in
                let rightPadding: CGFloat = 10
                let bottomPadding: CGFloat = 10
                let buttonSize = CGSize(width: frame.width - 2*rightPadding, height: 38)
                
                let button = UIButton(type: .custom)
                button.frame = CGRect(
                    x: rightPadding,
                    y: frame.height - buttonSize.height - bottomPadding - self.tabBarHeight,
                    width: buttonSize.width,
                    height: buttonSize.height
                )
                
                button.formatPrimary()
                button.setTitle(String.localize("LB_CA_CONT_SHOP"), for: .normal)
                
                button.addTarget(self, action: #selector(StyleViewController.continueShop), for: .touchUpInside)
                
                return button
                
            } ()
            view.addSubview(confirmButton)
            
            return view
        } ()
        
        summaryView.isHidden = true
        
        inactiveProductView = summaryView
        
        view.addSubview(summaryView)
        view.bringSubview(toFront: inactiveProductView)
    }
    
    @objc func continueShop() {
        self.ssn_home()
        //        if let viewControllers = self.navigationController?.viewControllers {
        //            if let _ = viewControllers.first as? DiscoverCollectionViewController {
        //                self.navigationController?.popToRootViewController(animated: true)
        //            }
        //        } else {
        //            ErrorLogManager.sharedManager.recordNonFatalError(withException: .NullPointer)
        //        }
    }
    
    // MARK: - Review
    
    private func getTotalReviewRows() -> Int {
        var countReviewRows = 0
        
        if let summaryReview = self.summaryReview {
            // Row user review
            countReviewRows += 1
            
            if let skuReview = summaryReview.skuReview {
                if skuReview.getImages().count > 0 {
                    // Row photo review
                    countReviewRows += 1
                }
                
                if !skuReview.replyDescription.isEmpty {
                    // Row description review
                    countReviewRows += 1
                }
            }
        }
        
        return countReviewRows
    }
    
    private func getReviewRow(atIndex index: Int) -> ReviewRow {
        var countReviewRows = -1
        
        if let summaryReview = self.summaryReview {
            // Row user review
            countReviewRows += 1
            
            if index == countReviewRows {
                return ReviewRow.UserReviewRow
            }
            
            if let skuReview = summaryReview.skuReview {
                if skuReview.getImages().count > 0 {
                    // Row photo review
                    countReviewRows += 1
                    if index == countReviewRows {
                        return ReviewRow.ImagesReviewRow
                    }
                }
                
                if !skuReview.replyDescription.isEmpty {
                    // Row description review
                    countReviewRows += 1
                    if index == countReviewRows {
                        return ReviewRow.DescriptionReviewRow
                    }
                }
            }
        }
        
        return ReviewRow.Unknown
    }
    
    func getImages(skuReview: SkuReview?) -> [ImageBucket] {
        var listReviewImages = [ImageBucket]()
        
        if let skuReview = skuReview {
            for image in skuReview.getImages() {
                listReviewImages.append(ImageBucket(imageKey: image, category: .review))
            }
        }
        
        return listReviewImages
    }
    
    func viewSummaryReview(merchantId: Int, styleCode: String) -> Promise<Any> {
        return Promise{ fulfill, reject in
            ReviewService.viewSummaryReview(merchantId: merchantId, styleCode: styleCode, completion: { [weak self] (response) in
                if let strongSelf = self {
                    if response.result.isSuccess {
                        if response.response?.statusCode == 200 {
                            strongSelf.summaryReview = nil
                            
                            if let productReview = Mapper<ProductReview>().map(JSONObject: response.result.value) {
                                if let skuReview = productReview.skuReview {
                                    if skuReview.skuId > 0 {
                                        strongSelf.summaryReview = productReview
                                        strongSelf.listReviewImages = strongSelf.getImages(skuReview: productReview.skuReview)
                                        
                                        let analyticsImpressionRecord = AnalyticsImpressionRecord()
                                        analyticsImpressionRecord.authorRef = Context.getUserKey()
                                        analyticsImpressionRecord.authorType = skuReview.userTypeString()
                                        analyticsImpressionRecord.brandCode = "\(strongSelf.style.brandId)"
                                        analyticsImpressionRecord.impressionRef = "\(productReview.skuReview?.skuReviewId.toString() ?? "")"
                                        analyticsImpressionRecord.impressionType = "Review"
                                        analyticsImpressionRecord.impressionDisplayName = AnalyticsManager.trimTextForImpressionDisplayName(productReview.skuReview?.description)
                                        analyticsImpressionRecord.merchantCode = "\(merchantId)"
                                        analyticsImpressionRecord.parentRef = "\(strongSelf.style.styleCode)"
                                        analyticsImpressionRecord.parentType = "Product"
                                        analyticsImpressionRecord.positionComponent = "ReviewListing"
                                        analyticsImpressionRecord.positionIndex = 1
                                        analyticsImpressionRecord.positionLocation = "PDP"
                                        analyticsImpressionRecord.viewKey = strongSelf.analyticsViewRecord.viewKey
                                        
                                        strongSelf.reviewAnalyticsSectionData = AnalyticsSectionData(analyticsImpressionRecord: analyticsImpressionRecord)
                                    }
                                } else {
                                    ErrorLogManager.sharedManager.recordNonFatalError(withException: .NullPointer)
                                }
                            } else {
                                ErrorLogManager.sharedManager.recordNonFatalError(withException: .FailToParseAPIResponse)
                            }
                        }
                        
                        fulfill("OK")
                    } else {
                        reject(response.result.error!)
                    }
                } else {
                    ErrorLogManager.sharedManager.recordNonFatalError(withException: .NullPointer)
                }
            })
        }
    }
    
    // MARK: - Search Style
    
    func searchStyleWithStyleCode(styleCode: String, merchantId: Int) -> Promise<Any> {
        return Promise{ fulfill, reject in
            SearchService.searchStyleByStyleCodeAndMechantId(styleCode, merchantIds: String(merchantId)) { [weak self] (response) in
                if let strongSelf = self {
                    var isProductActive = false
                    
                    if response.result.isSuccess {
                        if let styleResponse = Mapper<SearchResponse>().map(JSONObject: response.result.value) {
                            if let styles = styleResponse.pageData {
                                if styles.count > 0 {
                                    var merchantId: Int?
                                    
                                    if strongSelf.merchantId > 0 {
                                        merchantId = strongSelf.merchantId
                                    } else if strongSelf.style.merchantId > 0 {
                                        merchantId = strongSelf.style.merchantId
                                    }
                                    
                                    if let merchantId = merchantId, let style = styles.filter({ $0.merchantId == merchantId && $0.styleCode == styleCode}).first {
                                        isProductActive = true
                                        
                                        strongSelf.style = style
                                        strongSelf.searchedStyle = style
                                        
                                        // 重新判断首单减
                                        strongSelf.checkStyleContainFlashSale()
                                        
                                        //To fix can't show default image PDP
                                        if strongSelf.style.featuredImageList.count == 0 {
                                            strongSelf.style.featuredImageList = strongSelf.style.getDefaultImageList()
                                        }
                                        
                                        // Set filteredColorImageList
                                        let colorKey = strongSelf.selectedColorKey
                                        if !colorKey.isEmpty && strongSelf.selectedColorId >= 0 {
                                            strongSelf.filteredColorImageList = style.colorImageList.filter({ $0.colorKey == colorKey })
                                            strongSelf.filteredColorImageList = strongSelf.filteredColorImageList.sorted(by: { $0.position < $1.position })
                                        }
                                        strongSelf.setupDefaultColorSize()
                                    } else {
                                        ErrorLogManager.sharedManager.recordNonFatalError(withException: .NullPointer)
                                    }
                                }
                            } else {
                                ErrorLogManager.sharedManager.recordNonFatalError(withException: .NullPointer)
                            }
                        } else {
                            ErrorLogManager.sharedManager.recordNonFatalError(withException: .FailToParseAPIResponse)
                        }
                        strongSelf.isProductActive = isProductActive
                        
                        if !strongSelf.isProductActive {
                            strongSelf.style.statusId = Constants.StatusID.inactive.rawValue
                        }
                        
                        fulfill("OK")
                    } else {
                        reject(response.result.error!)
                    }
                } else {
                    ErrorLogManager.sharedManager.recordNonFatalError(withException: .NullPointer)
                }
            }
        }
    }
    
    func updateInactiveOrOutOfStockStatus(cell: FeatureImageCell) {
        
        var invalidMessage = ""
        
        let style = (entryPoint == .PLP || entryPoint == .DeepLink) ? self.style : self.searchedStyle
        
        if let strongStyle = style {
            if !strongStyle.isValid() || strongStyle.isOutOfStock() {
                invalidMessage = String.localize("LB_CA_OUT_OF_STOCK")
            }
        } else {
            ErrorLogManager.sharedManager.recordNonFatalError(withException: .NullPointer)
        }
        
        if invalidMessage.length > 0 {
            if let label = cell.viewWithTag(LabelInactiveTag) as? UILabel {
                label.text = invalidMessage
            } else {
                let label = UILabel(frame: CGRect(x: 0, y: 0, width: 0, height: 0))
                label.tag = LabelInactiveTag
                label.layoutInactiveOrOutOfStockLabel(forView: cell, sizePercentage: 0.3)
                label.text = invalidMessage
                cell.addSubview(label)
                cell.bringSubview(toFront: cell.heartImageView)
            }
        } else {
            if let label = cell.viewWithTag(LabelInactiveTag) as? UILabel {
                label.removeFromSuperview()
            } else {
                ErrorLogManager.sharedManager.recordNonFatalError(withException: .NullPointer)
            }
        }
    }
    
    func updateInactiveOrOutOfStockFooterView(checkValid:Bool = false) {
        // checkout footer
        
        //swipeViewContainer.isHidden = false
        bottomView.setEnable(false)
        if style.isValid() && isProductActive {
            bottomView.setEnable(true)
            //            enableSwipeViewContainer(true)
        } else {
            bottomView.setEnable(false)
            //enableSwipeViewContainer(false)
        }
        
        if style.isOutOfStock(){
            bottomView.disableBuyAndAddToCart()
        }
        
        let getStyle = (entryPoint == .PLP || entryPoint == .DeepLink) ? self.style : self.searchedStyle
        
        if let strongStyle = getStyle {
            if !strongStyle.isValid() || strongStyle.isOutOfStock() {
                bottomView.setEnable(false)
            } else {
                bottomView.setEnable(true)
            }
        } else {
            ErrorLogManager.sharedManager.recordNonFatalError(withException: .NullPointer)
        }
        
    }
    /*
     func enableSwipeViewContainer(isEnable: Bool){
     if let view = swipeViewContainer {
     for v in view.subviews {
     if v is SwipeMenu {
     DispatchQueue.main.async {
     v.alpha = isEnable ? 1.0 : 0.4
     v.isUserInteractionEnabled = isEnable
     if v is UIButton {
     if let btn: UIButton = (v as? UIButton) {
     btn.isEnabled = isEnable
     } else {
     ErrorLogManager.sharedManager.recordNonFatalError(withException: .NullPointerOrTypeMismatch)
     }
     }
     }
     
     } else if v is UIButton{
     if let btn: UIButton = (v as? UIButton) {
     DispatchQueue.main.async {
     btn.isEnabled = isEnable
     }
     
     } else {
     ErrorLogManager.sharedManager.recordNonFatalError(withException: .NullPointerOrTypeMismatch)
     }
     }
     }
     } else {
     ErrorLogManager.sharedManager.recordNonFatalError(withException: .NullPointer)
     }
     }
     */
    // MARK: CollectionView Data Source, Delegate Method
    
    func numberOfSections(in collectionView: UICollectionView) -> Int {
        switch getCollectionType(collectionView) {
        case .RootCollection:
            return self.sectionList.count
        case .FeatureCollection:
            return 1
        case .UserCollection:
            if self.productLikeList.count > 0 {
                return 1
            }
            return 0
        default:
            return 1
        }
    }
    
    override func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        switch getCollectionType(collectionView) {
        case .RootCollection:
            if self.sectionList.indices.contains(section) {
                let sectionType: SectionType = self.sectionList[section]
                switch sectionType {
                case .FlashSaleSection:
                    return 1
                case .ColorListSection:
                    return self.style.validColorList.count
                case .SizeListSection:
                    return self.style.validSizeList.count
                case .MerchantSection:
                    return 1
                case .StylePriceSection:
                    return 1
                case .StyleRealPriceSection:
                    return 1
                case .StyleGetPriceSection:
                    return 1
                case .StyleTipGetPriceSection:
                    return 1
                case .StyleNameSection:
                    return 1
                case .StyleBrandSection:
                    return 1
                case .MarginSection:
                    return 1
                case .CouponSection:
                    return 1
                case .ReviewSection:
                    return getTotalReviewRows()
                case .DescriptionSection:
                    if self.style.skuDesc.isEmpty{
                        return 0
                    } else {
                        return 1
                    }
                case .ImageListSection:
                    return self.style.descriptionImageList.count
                case .CrossBorderStatementSection:
                    if let merchant = self.merchant {
                        if merchant.isCrossBorder {
                            return 0 // TODO: This section will be replaced by a image description
                        }
                    } else {
                        ErrorLogManager.sharedManager.recordNonFatalError(withException: .NullPointer)
                    }
                    
                    return 0
                case .LastestPostSection:
                    return postManager.currentPosts.count
                case .OutfitSection:
                    return 0
                case .SuggestSection:
                    return self.syteStyles.count
                default:
                    return 1
                }
                
            } else {
                ErrorLogManager.sharedManager.recordNonFatalError(withException: .IndexOutOfBounds)
                
                return 1
            }
        case .FeatureCollection:
            return self.numberOfItemsFeatureCollection()
        case .UserCollection:
            if self.productLikeList.count <= 0 {
                return 0
            } else if self.productLikeList.count < 7 {
                return self.productLikeList.count
            }
            
            //Max show 7 avatar
            return 7
        default:
            return 0
        }
    }
    
    func collectionView(_ collectionView: UICollectionView, willDisplay cell: UICollectionViewCell, forItemAt indexPath: IndexPath) {
        switch getCollectionType(collectionView) {
        case .RootCollection:
            let sectionType: SectionType = self.sectionList[indexPath.section]
            switch sectionType {
                
            case .ProductImageSection:
                if let videoCell = videoCell, isVideoCellShowingPresenting {
                    if style.videoURL.length > 0 {
                        videoCell.playVideo(style.videoURL)
                    }
                }
            default:
                break
            }
            
        case .FeatureCollection:
            if let videoCell = videoCell, indexPath.row == 0 {
                
                isVideoCellShowingPresenting = true
                if style.coverURL.length > 0 {
                    videoCell.setImageURL(style.coverURL)
                }
                
                if style.videoURL.length > 0 {
                    videoCell.playVideo(style.videoURL)
                }
            }
        default:
            break
        }
    }
    
    func collectionView(_ collectionView: UICollectionView, didEndDisplaying cell: UICollectionViewCell, forItemAt indexPath: IndexPath)  {
        switch getCollectionType(collectionView) {
        case .RootCollection:
            if indexPath.section >= self.sectionList.count {
                break
            }
            let sectionType: SectionType = self.sectionList[indexPath.section]
            switch sectionType {
            case .BrandNameSection:
                if let cell = collectionView.cellForItem(at: indexPath) as? BrandNameCell {
                    cell.stopCountDown()
                }
            case .ProductImageSection:
                
                if let videoCell = videoCell {
                    videoCell.pauseVideo()
                }
            default:
                break
            }
            
            
        case .FeatureCollection:
            if let videoCell = videoCell, indexPath.row == 0 {
                isVideoCellShowingPresenting = false
                videoCell.pauseVideo()
            }
        default:
            break
        }
        
    }
    
    override func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        switch getCollectionType(collectionView) {
        case .RootCollection:
            let sectionType: SectionType = self.sectionList[indexPath.section]
            let attributes = UICollectionViewLayoutAttributes.init(forCellWith: indexPath)
            attributes.zIndex = indexPath.section
            
            switch sectionType {
            case .FlashSaleSection:
                let cell = collectionView.dequeueReusableCell(withReuseIdentifier: FlashSaleBarCell.CellIdentifier, for: indexPath) as! FlashSaleBarCell
                cell.sku = selectedSku
                return cell
            case .ProductImageSection:
                let cell = collectionView.dequeueReusableCell(withReuseIdentifier: FeatureCellId, for: indexPath) as! FeatureImageCell
                self.setAccessibilityIdForView("UI_IM_CAROUSEL", view: cell.featureCollectionView)
                
                cell.featureCollectionView?.dataSource = self
                cell.featureCollectionView?.delegate = self
                
                self.featureCollectionView = cell.featureCollectionView
                self.featureCollectionView?.register(FeatureCollectionCell.self, forCellWithReuseIdentifier: FeatureCollectCellId)
                self.featureCollectionView?.register(FeatureVideoCell.self, forCellWithReuseIdentifier: FeatureVideoCell.CellIdentifier)
                
                self.featureCollectionView?.initAnalytics(withViewKey: analyticsViewRecord.viewKey)
                cell.heartImageView.isHidden = true
                if self.style.isWished() {
                    cell.heartImageView.image = UIImage(named: "like_on")
                } else {
                    cell.heartImageView.image = UIImage(named: "like_rest")
                }
                
                self.setAccessibilityIdForView("UIBT_ADD_WISHLIST", view: cell.heartImageView)
                
                cell.heartImageView.isUserInteractionEnabled = true
                cell.heartImageView.addGestureRecognizer(UITapGestureRecognizer(target:self, action:#selector(self.likeTapped)))
                cell.heartImageView.initAnalytics(withViewKey: analyticsViewRecord.viewKey)
                
                if self.style.badgeImage.isEmpty {
                    cell.badgeImageView.isHidden = true
                } else {
                    cell.badgeImageView.isHidden = false
                    cell.setBadgeImage(self.style.badgeImage)
                }
                
                self.setAccessibilityIdForView("UIIMG_BADGE", view: cell.badgeImageView)
                
                cell.pageControl.numberOfPages = numberOfItemsFeatureCollection()
                
                productImagePageControl = cell.pageControl
                self.setAccessibilityIdForView("UI_PRODUCT_IMG_PAGING", view: productImagePageControl)
                
                cell.pageControl.currentPage = self.currentPage
                
                cell.initAnalytics(withViewKey: analyticsViewRecord.viewKey)
                
                self.updateInactiveOrOutOfStockStatus(cell: cell)
                
                featureImageCell = cell
                
                return cell
            case .BrandNameSection:
                let cell = collectionView.dequeueReusableCell(withReuseIdentifier: BrandNameCell.CellIdentifier, for: indexPath) as! BrandNameCell
                brandNameCell = cell
                let (salePrice, retailPrice) = self.getPriceBySelectedSku()
                if retailPrice <= 0 {
                    //Show sale price on selected sku, otherwise show range price
                    if salePrice > 0 {
                        cell.setData(style.skuName, brandName: style.brandName, priceRange: salePrice.formatPrice() ?? style.getRangePrice())
                    } else {
                        cell.setData(style.skuName, brandName: style.brandName, priceRange: style.getRangePrice())
                    }
                } else {
                    cell.setData(style.skuName, brandName: style.brandName, price: salePrice, retailPrice: retailPrice)
                }
                
                //Sale date
                let (dateSaleTo, dateSaleFrom) = self.getSaleDateBySelectedSku()
                cell.dateSaleTo = dateSaleTo
                cell.dateSaleFrom = dateSaleFrom
                if !cell.shouldHideCountDownText() {
                    if !cell.isTimerRunning {
                        cell.startCountDown()
                    }
                }
                
                if let shipingThresold = getShipingThresold() {
                    cell.showShippingThresold(shippingThresold: shipingThresold)
                }
                
                if let merchant = merchant {
                    
                    if merchant.isCrossBorder {
                        cell.showCrossBorderLabel(true)
                    } else {
                        cell.showCrossBorderLabel(false)
                    }
                    
                } else {
                    ErrorLogManager.sharedManager.recordNonFatalError(withException: .NullPointer)
                }
                cell.isFlashSaleDiscount = isFlashSaleDiscount
                
                
                cell.shareTapHandler = {
                    self.share(sender: UIButton())
                }
                
                
                return cell
            case .ColorListSection:
                let cell = collectionView.dequeueReusableCell(withReuseIdentifier: ColorCollectionCell.CellIdentifier, for: indexPath) as! ColorCollectionCell
                self.setAccessibilityIdForView("UIBT_COLOR_SELECT", view: cell)
                cell.topPadding = UserCellLineSpacing
                
                if (style.validColorList.indices.contains(indexPath.item)){
                    let indexPathColor = style.validColorList[indexPath.item]
                    
                    let filteredColorImageList = style.colorImageList.filter({ $0.colorKey == indexPathColor.colorKey })
                    
                    if filteredColorImageList.isEmpty {
                        cell.imageView.mm_setImageWithURL(ImageURLFactory.URLSize1000(indexPathColor.colorImage,category: .color), placeholderImage: UIImage(named: "holder"))
                    } else {
                        cell.setImage(filteredColorImageList[0].imageKey)
                    }
                    
                    cell.initAnalytics(withViewKey: analyticsViewRecord.viewKey)
                    
                    //MM-18824: Check for product out of stock
                    var filteredSkuList = style.skuList
                    filteredSkuList = filteredSkuList.filter({ ($0.skuColor == indexPathColor.skuColor) && ($0.colorId == indexPathColor.colorId)})
                    filteredSkuList = filteredSkuList.filter({ !$0.isOutOfStock() && $0.isValid()})
                    
                    let itemIsValid = !filteredSkuList.isEmpty
                    //                    if(style.validColorList.count == 1){
                    //                        cell.itemSelected(true)
                    //                    }else{
                    //                        cell.itemSelected(indexPath.item == colorIndexSelected)
                    //                    }
                    cell.itemSelected(indexPath.item == colorIndexSelected)
                    cell.itemDisabled(!itemIsValid)
                    style.validColorList[indexPath.item].isValid = itemIsValid
                }
                return cell
            case .SizeListSection:
                let cell = collectionView.dequeueReusableCell(withReuseIdentifier: SizeCollectionCell.CellIdentifier, for: indexPath) as! SizeCollectionCell
                self.setAccessibilityIdForView("UIBT_SIZE_SELECT", view: cell)
                
                if (style.validSizeList.indices.contains(indexPath.item)){
                    cell.name = style.validSizeList[indexPath.item].sizeName
                    
                    cell.initAnalytics(withViewKey: analyticsViewRecord.viewKey)
                    
                    var filteredSkuList = style.skuList
                    
                    if !selectedColorKey.isEmpty && selectedColorId != -1{
                        filteredSkuList = filteredSkuList.filter({ ($0.colorId == selectedColorId) && ($0.colorKey == selectedColorKey) })
                    }
                    
                    filteredSkuList = filteredSkuList.filter({ $0.sizeId == style.validSizeList[indexPath.item].sizeId })
                    filteredSkuList = filteredSkuList.filter({ !$0.isOutOfStock() && $0.isValid()})
                    
                    let itemIsValid = !filteredSkuList.isEmpty
                    
                    //                    if(style.validSizeList.count == 1){
                    //                        cell.itemSelected(true)
                    //                    }else{
                    //                        cell.itemSelected(indexPath.item == sizeIndexSelected)
                    //                    }
                    cell.itemSelected(indexPath.item == sizeIndexSelected)
                    cell.itemDisabled(!itemIsValid)
                    
                    style.validSizeList[indexPath.item].isValid = itemIsValid
                    
                }
                
                return cell
            case .MerchantSection:
                let cell = collectionView.dequeueReusableCell(withReuseIdentifier: OrderMerchantCell.CellIdentifier, for: indexPath) as! OrderMerchantCell
                cell.merchant = merchant
                cell.cellTappedHandler = { [weak self] () in
                    if let strongSelf = self {
                        strongSelf.view.recordAction(.Tap, sourceRef: strongSelf.merchant?.merchantId.toString(), sourceType: .MerchantBanner, targetRef: "MPP", targetType: .View)
                        DeepLinkManager.sharedManager.pushMerchantById(strongSelf.merchant?.merchantId ?? 0, fromViewController: strongSelf)
                    } else {
                        ErrorLogManager.sharedManager.recordNonFatalError(withException: .NullPointer)
                    }
                }
                cell.showTopView(true)
                return cell
            case .StylePriceSection:
                let cell = collectionView.dequeueReusableCell(withReuseIdentifier: StylePriceCell.CellIdentifier, for: indexPath) as! StylePriceCell
                let (salePrice, retailPrice) = self.getPriceBySelectedSku()
                if retailPrice <= 0 {
                    //Show sale price on selected sku, otherwise show range price
                    if salePrice > 0 {
                        cell.noSale = false
                        cell.price = salePrice.formatPrice() ?? style.getRangePrice()
                    } else {
                        cell.noSale = true
                        cell.price = style.getRangePrice()
                    }
                } else {
                    cell.noSale = true
                    cell.price = salePrice.formatPrice()
                }
                let (dateSaleTo, dateSaleFrom) = self.getSaleDateBySelectedSku()
                cell.dateSaleTo = dateSaleTo
                cell.dateSaleFrom = dateSaleFrom
                return cell
            case .StyleRealPriceSection:
                let (_, retailPrice) = self.getPriceBySelectedSku()
                let cell = collectionView.dequeueReusableCell(withReuseIdentifier: StyleRealPriceCell.CellIdentifier, for: indexPath) as! StyleRealPriceCell
                cell.realPrice = retailPrice.formatPrice() ?? style.getRangePrice()
                return cell
            case .StyleGetPriceSection:
                let cell = collectionView.dequeueReusableCell(withReuseIdentifier: StyleTagAndGetPriceCell.CellIdentifier, for: indexPath) as! StyleTagAndGetPriceCell
                if let merchant = merchant {
                    cell.isCrossBorder = merchant.isCrossBorder
                }
                var couponDiscount : Double = 0
                let (salePrice, _) = self.getPriceBySelectedSku()
                var price : Double = salePrice
                
                if LoginManager.getLoginState() == .validUser {
                    CouponManager.shareManager().calculateBestCoupons(style,flashSku:self.selectedSku).then { (couponMap) -> Void in
                        couponDiscount = CouponManager.shareManager().calculateTotalDiscount(Array(couponMap.values))
                        if couponMap.count > 0 {
                            let coupon = couponMap[couponMap.startIndex].value
                            if salePrice >= coupon.minimumSpendAmount {
                                if let sku = self.selectedSku, sku.isFlashSaleExists, self.isFlashSaleEligible {
                                    if coupon.minimumSpendAmount <= sku.priceFlashSale {
                                        price = sku.priceFlashSale - couponDiscount
                                        cell.price = price.formatPrice()
                                        cell.isHiddenPrice = false
                                    } else {
                                       cell.isHiddenPrice = true
                                    }
                                } else {
                                    price = salePrice - couponDiscount
                                    cell.price = price.formatPrice()
                                    cell.isHiddenPrice = false
                                }
                            }
                        } else {
                            cell.isHiddenPrice = true
                        }
                    }
                } else {
                    cell.isHiddenPrice = true
                }

                
                cell.expressFee = getShipingThresold()
                return cell
            case .StyleTipGetPriceSection:
                let cell = collectionView.dequeueReusableCell(withReuseIdentifier: StyleTipCell.CellIdentifier, for: indexPath) as! StyleTipCell
                return cell
            case .StyleNameSection:
                let cell = collectionView.dequeueReusableCell(withReuseIdentifier: StyleNameAndCollectCell.CellIdentifier, for: indexPath) as! StyleNameAndCollectCell
                cell.styleName = style.skuName
                cell.setLike(style.isWished())
                cell.collectButton.tapHandler = {[weak self] in
                    if let strongSelf = self {
                        strongSelf.actionLike(cell)
                    }
                }
                return cell
            case .StyleBrandSection:
                let cell = collectionView.dequeueReusableCell(withReuseIdentifier: StyleBrandCell.CellIdentifier, for: indexPath) as! StyleBrandCell
                cell.brandName = style.brandName
//                cell.datasouces = self.coupons
//                cell.claimedCoupon = self.claimedCoupons
//                cell.delegate = self
//                cell.initAnalytics(withViewKey: analyticsViewRecord.viewKey)
//                cell.positionLocation = "PDP"
//                cell.targetType = .PDP
                return cell
            case .MarginSection:
                let cell = collectionView.dequeueReusableCell(withReuseIdentifier: CMSPageBottomCell.CellIdentifier, for: indexPath) as! CMSPageBottomCell
                cell.backgroundColor = UIColor(hexString: "#F5F5F5")
                return cell
            case .CouponSection:
                let cell = collectionView.dequeueReusableCell(withReuseIdentifier: StyleCouponCell.CellIdentifier, for: indexPath) as! StyleCouponCell
                cell.datasouces = self.coupons
                cell.claimedCoupon = self.claimedCoupons
                cell.delegate = self
                cell.initAnalytics(withViewKey: analyticsViewRecord.viewKey)
                cell.positionLocation = "PDP"

                return cell
            case .ReviewSection:
                
                
                let reviewRow = getReviewRow(atIndex: indexPath.row)
                
                if let reviewAnalyticsSectionData = reviewAnalyticsSectionData {
                    reviewAnalyticsSectionData.trigger(atIndex: reviewRow.rawValue)
                } else {
                    ErrorLogManager.sharedManager.recordNonFatalError(withException: .NullPointer)
                }
                
                switch reviewRow {
                case .UserReviewRow:
                    let cell = collectionView.dequeueReusableCell(withReuseIdentifier: RatingUserCell.CellIdentifier, for: indexPath) as! RatingUserCell
                    cell.ratingView.isUserInteractionEnabled = false
                    
                    if let summaryReview = self.summaryReview {
                        cell.skuReview = summaryReview.skuReview
                    } else {
                        cell.skuReview = nil
                    }
                    
                    cell.moreReviewHandler = { [weak self] (_) -> Void in
                        if let strongSelf = self {
                            strongSelf.showPopupConfirmReport({ (confirm) in
                                if confirm {
                                    strongSelf.reportReview()
                                }
                            })
                        } else {
                            ErrorLogManager.sharedManager.recordNonFatalError(withException: .NullPointer)
                        }
                    }
                    
                    cell.delegate = self
                    
                    return cell
                case .ImagesReviewRow:
                    let cell = collectionView.dequeueReusableCell(withReuseIdentifier: HorizontalImageCell.CellIdentifier, for: indexPath) as! HorizontalImageCell
                    cell.imageBucketDelegate = self
                    cell.hideHeaderView = true
                    cell.dataSource = listReviewImages
                    cell.disableScrollToTop()
                    
                    return cell
                case .DescriptionReviewRow:
                    let cell = collectionView.dequeueReusableCell(withReuseIdentifier: PlainTextCell.CellIdentifier, for: indexPath) as! PlainTextCell
                    
                    if let summaryReview = self.summaryReview {
                        cell.contentLabel.text = summaryReview.skuReview?.replyDescription
                    } else {
                        cell.contentLabel.text = ""
                    }
                    
                    return cell
                default:
                    return getDefaultCell(collectionView, cellForItemAt: indexPath)
                }
                
                
            case .UserListSection:
                // CHANGE VIEW
                let cell = collectionView.dequeueReusableCell(withReuseIdentifier: UserCellId, for: indexPath) as! UserCell
                cell.showTopBorder = true
                cell.userCollectionView?.dataSource = self
                cell.userCollectionView?.delegate = self
                cell.addViewTapGesture()
                cell.viewDidTap = { [weak self] userCell in
                    if let strongSelf = self{
                        strongSelf.openProductLikeUserListPage()
                    }
                }
                self.userCollectionView = cell.userCollectionView
                self.userCollectionView?.register(UserCollectionCell.self, forCellWithReuseIdentifier: UserCollectionCellId)
                return cell
                
            case .RecommendSection:
                let cell = collectionView.dequeueReusableCell(withReuseIdentifier: RecommendCellId, for: indexPath) as! RecommendedCell
                cell.numberLabel.text = "\(productLikeList.count)"
                cell.textLabel.text = String.localize("LB_CA_PDP_NUM_LIKE")
                self.setAccessibilityIdForView("UILB_NUM_LIKE", view: cell.textLabel)
                return cell
                
            case .DescriptionSection:
                let cell = collectionView.dequeueReusableCell(withReuseIdentifier: DescCellId, for: indexPath) as! DescCell
                cell.setDescription(self.style.skuDesc)
                cell.upperBorderView.backgroundColor = UIColor.primary2()
                cell.lowerBorderView.isHidden = true
                cell.heightTopBorder = HeightTopDescriptionBorder
                self.setAccessibilityIdForView("UITA_MERCH_DESC", view: cell.descLabel)
                
                let skus = style.skuList.filter({ $0.skuId == skuId })
                
                cell.initAnalytics(withViewKey: analyticsViewRecord.viewKey, impressionKey: recordImpression(
                    brandCode: "\(style.brandId)",
                    impressionRef: "\(style.styleCode)",
                    impressionType: "Product",
                    impressionVariantRef: "\(skus.first?.skuCode ?? "")",
                    impressionDisplayName: "\(skus.first?.skuName ?? "")",
                    merchantCode: "\(merchant?.merchantCode ?? "")",
                    positionComponent: "DescriptionText",
                    positionLocation: "PDP"))
                return cell
            case .ImageListSection:
                let cell = collectionView.dequeueReusableCell(withReuseIdentifier: DescCollectCellId, for: indexPath) as! DescCollectCell
                
                if (style.descriptionImageList.indices.contains(indexPath.row)){
                    let imageKey = self.style.descriptionImageList[indexPath.row].imageKey
                    self.setAccessibilityIdForView("UIIMG_DESCRIPTION_IMAGE-\(indexPath.row)", view: cell)
                    cell.accessibilityValue = imageKey
                    
                    cell.setImage(imageKey, completion: { [weak self] (image: Image?, error: NSError?) in
                        if let strongSelf = self {
                            if image != nil {
                                if strongSelf.sectionImageListHeight[imageKey] == nil {
                                    //MM-14335 Cache height of Image to fix for image product list is not correct height
                                    let imageFrame = strongSelf.frameImageAspectFitForImage(image: image!, imageView: cell.descImageView)
                                    strongSelf.sectionImageListHeight[imageKey] = round(imageFrame.sizeHeight) //round height for fixing a little line of each image
                                    DispatchQueue.main.async {
                                        if strongSelf.collectionView != nil {
                                            strongSelf.collectionView!.reloadData()
                                            strongSelf.collectionView.collectionViewLayout.invalidateLayout()
                                        }
                                    }
                                }
                            }
                            
                            
                        } else {
                            ErrorLogManager.sharedManager.recordNonFatalError(withException: .NullPointer)
                        }
                    })
                    
                    //                        cell.descImageView.setupImageViewer(with: self, initialIndex: indexPath.row, parentTag:indexPath.section, onOpen: { [weak self] () -> Void in
                    //                            if let strongSelf = self{
                    //                                let longPress = UILongPressGestureRecognizer(target: strongSelf, action: #selector(StyleViewController.handleLongPressOnProductImage))
                    //                                cell.descImageView.imageBrowser.view.addGestureRecognizer(longPress)
                    //                                strongSelf.facebookImageViewer = cell.descImageView.imageBrowser
                    //                            }
                    //                            }, onClose: { () -> Void in
                    //                                self.navigationController?.isNavigationBarHidden = false
                    //                        })
                    //
                    //                        cell.descImageView.isFullScreenItemOnDisplay = true
                    
                    let skus = style.skuList.filter({ $0.skuId == skuId })
                    
                    cell.initAnalytics(withViewKey: analyticsViewRecord.viewKey, impressionKey: recordImpression(
                        brandCode: "\(style.brandId)",
                        impressionRef: "\(style.styleCode)",
                        impressionType: "Product",
                        impressionVariantRef: "\(skus.first?.skuCode ?? "")",
                        impressionDisplayName: "\(skus.first?.skuName ?? "")",
                        merchantCode: "\(merchant?.merchantCode ?? "")",
                        positionComponent: "DescriptionImage",
                        positionIndex: indexPath.row + 1,
                        positionLocation: "PDP"))
                }
                
                
                return cell
            case .CrossBorderStatementSection:
                let cell = collectionView.dequeueReusableCell(withReuseIdentifier: CrossBorderStatementCell.cellIdentifier, for: indexPath) as! CrossBorderStatementCell
                
                let sku = style.skuList.filter({ $0.skuId == skuId }).first
                
                cell.initAnalytics(withViewKey: analyticsViewRecord.viewKey, impressionKey: recordImpression(
                    brandCode: "\(style.brandId)",
                    impressionRef: "\(style.styleCode)",
                    impressionType: "Product",
                    impressionVariantRef: sku?.skuCode,
                    impressionDisplayName: sku?.skuName,
                    merchantCode: "\(merchant?.merchantCode ?? "")",
                    positionComponent: "TaxInfo",
                    positionLocation: "PDP"
                ))
                
                return cell
            case .OutfitSection:
                let cell = collectionView.dequeueReusableCell(withReuseIdentifier: "mock_product", for: indexPath)
                
                let mockUpImageView = UIImageView(image: UIImage(named: "mock_pdp_product"))
                mockUpImageView.contentMode = .scaleToFill
                mockUpImageView.frame = CGRect(x: 0, y: 0, width: view.width, height: 723 * view.width / 375 )
                
                cell.addSubview(mockUpImageView)
                
                return cell
            case .SuggestSection:
                let cell = collectionView.dequeueReusableCell(withReuseIdentifier: CMSPageNewsfeedCommodityCellId, for: indexPath) as! CMSPageNewsfeedCommodityCell
                
                if syteStyles.count > 0 {
                    if (self.syteStyles.indices.contains(indexPath.row)){
                        let style = self.syteStyles[indexPath.row]
                        cell.setProductCell(style: style, sku: style.defaultSku())
                    }
                }

                return cell
                
            case .LastestPostSection:
                if let cell = postManager.getSimpleNewsFeedCell(indexPath) as? SimpleFeedCollectionViewCell {
                    
                    if !myFeedCollectionViewCells.contains(cell) {
                        myFeedCollectionViewCells.append(cell)
                    }
                    
                    cell.isUserInteractionEnabled = true
                    cell.recordImpressionAtIndexPath(indexPath, positionLocation: "PDP", viewKey: self.analyticsViewRecord.viewKey)
                    cell.likeButton.initAnalytics(withViewKey: cell.analyticsViewKey ?? "", impressionKey: cell.analyticsImpressionKey ?? "")
                    return cell
                }
            }
        case .FeatureCollection:
            return self.getFeatureCollectionCell(collectionView, indexPath: indexPath)
        case .UserCollection:
            let cell = collectionView.dequeueReusableCell(withReuseIdentifier: UserCollectionCellId, for: indexPath) as! UserCollectionCell
            if (productLikeList.indices.contains(indexPath.row)){
                cell.userImageView.mm_setImageWithURL(ImageURLFactory.URLSize256(productLikeList[indexPath.row].profileImage, category: .user), placeholderImage: UIImage(named: "default_profile_icon"))
            }
            self.setAccessibilityIdForView("UIBT_CONSUMER_PIC", view: cell.userImageView)
            
            return cell
            
        default:
            break
        }
        
        return getDefaultCell(collectionView, cellForItemAt: indexPath)
    }
    
    func getDefaultCell(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        let cell = collectionView.dequeueReusableCell(withReuseIdentifier: CellId, for: indexPath)
        return cell
    }
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, insetForSectionAt section: Int) -> UIEdgeInsets {
        switch getCollectionType(collectionView) {
        case .UserCollection:
            let numberOfCells = CGFloat(self.collectionView(self.userCollectionView!, numberOfItemsInSection: 0))
            
            let totalLineSpacingCell = (numberOfCells - 1) * UserCellLineSpacing
            let totalWidthUserCell = (numberOfCells * UserCellWidth)
            let edgeInsets = (self.view.frame.size.width - totalWidthUserCell - totalLineSpacingCell) / 2;
            
            return UIEdgeInsets(top: 15, left: edgeInsets, bottom: 0, right: 0)
            
        default:
            break
        }
        
        return UIEdgeInsets.zero
    }
    private func getShipingThresold() -> String? {
        var shipingThresold: String? = nil
        if let merchant = merchant {
            if merchant.isFreeShippingEnabled() {
                if merchant.shippingFee <= 0 {
                    shipingThresold = ""
                } else {
                    shipingThresold = "\(merchant.freeShippingThreshold)"
                }
            }
        }
        return shipingThresold
    }
    
    private func getCollectionType(_ collectionView: UICollectionView) -> CollectionViewType {
        
        if self.collectionView != nil && self.collectionView == collectionView {
            return .RootCollection
        } else if self.userCollectionView != nil && self.userCollectionView == collectionView {
            return .UserCollection
        } else if self.featureCollectionView != nil && self.featureCollectionView == collectionView {
            return .FeatureCollection
        }
        
        return .UnknownCollection
    }
    
    final internal func scrollViewDidScroll(_ scrollView: UIScrollView) {
        if scrollView == self.collectionView {
            let offset = scrollView.contentOffset.y
            contentOffsetY = scrollView.contentOffset.y
            var alpha = offset / 100
            if alpha > 1 {
                alpha = 1
            }
            self.navigationItem.titleView?.isHidden = false 
            if (scrollView.contentOffset.y > 100) {
                self.navigationBarVisibility = .visible
                shareButton.setImage(UIImage(named: "blackShare"), for: .normal)
                backButton.setImage(UIImage(named: "blackBack"), for: .normal)
                shareButton.alpha = 1
                backButton.alpha = 1
                self.navigationItem.titleView?.alpha = alpha
            } else {
                self.navigationBarVisibility = .hidden
                shareButton.setImage(UIImage(named: "greyShare"), for: .normal)
                backButton.setImage(UIImage(named: "greyBack"), for: .normal)
                shareButton.alpha = 1 - alpha
                backButton.alpha = 1 - alpha
                self.navigationItem.titleView?.alpha = alpha
            }

            if let navigationController = self.navigationController as? MmNavigationController {
                navigationController.setNavigationBarVisibility(offset: offset)
            }
            if let featureImageCell = featureImageCell {
                let scrollOffset = scrollView.contentOffset.y
                let offset = scrollOffset - lastOffset
                lastOffset = scrollOffset
                let frame = featureImageCell.featureCollectionView.frame
                
                if scrollOffset < 0 {
                    featureImageCell.featureCollectionView.frame = CGRect(x:frame.minX, y: 0, width: frame.width, height: frame.height)
                } else {
                    featureImageCell.featureCollectionView.frame = CGRect(x:frame.minX, y: frame.minY + offset/2, width: frame.width, height: frame.height)
                }
            } else {
                ErrorLogManager.sharedManager.recordNonFatalError(withException: .NullPointer)
            }
        }
    }
    
    // MARK: Header and Footer View for collection view
    
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, referenceSizeForHeaderInSection section: Int) -> CGSize {
        switch collectionView {
        case self.collectionView:
            let sectionType: SectionType = self.sectionList[section]
            switch sectionType {
            case .ColorListSection:
                return CGSize(width: view.width, height: SizeHeaderViewHeight + (11))
            case .SizeListSection:
                return CGSize(width: view.width, height: SizeHeaderViewHeight + (20))
            case .MerchantSection:
                return CGSize(width: view.width, height: 6)
            case .ReviewSection:
                if let summaryReview = self.summaryReview, let skuReview = summaryReview.skuReview, skuReview.skuId > 0 {
                    return CGSize(width: view.width, height: RatingHeaderView.DefaultHeight)
                } else {
                    ErrorLogManager.sharedManager.recordNonFatalError(withException: .NullPointer)
                }
            case .SuggestSection:
                if !suggestStyles.isEmpty {
                    return CGSize(width: view.width, height: SuggestionHeaderHeight + 5)
                }
                if !syteStyles.isEmpty {
                    return CGSize(width: view.width, height: SuggestionHeaderHeight + 5)
                }
            case .LastestPostSection:
                if !self.postManager.currentPosts.isEmpty {
                    return CGSize(width: view.width, height: SuggestionHeaderHeight + 5)
                }
            case .ImageListSection:
                return CGSize(width: view.width, height: ImageListHeaderHeight)
            default:
                break
            }
            
        default:
            break
        }
        
        return CGSize.zero
    }
    
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, referenceSizeForFooterInSection section: Int) -> CGSize {
        if self.collectionView == collectionView {
            let sectionType: SectionType = self.sectionList[section]
            switch sectionType {
                //            case .BrandNameSection:
                //                if let merchant = merchant, merchant.isFreeShippingEnabled() {
                //                    return CGSize(width: view.width, height: FooterFreeShipHeight)
            //                }
            case .ColorListSection:
                return CGSize(width: view.width, height: 10)
            case .SizeListSection:
                return CGSize(width: view.width, height: 10)
            default:
                break
            }
            
            //Last Section - Because bottom view overlay on collection view we need dummy view
            if self.sectionList.count > 0 && section == self.sectionList.count - 1 {
                return CGSize(width: self.view.bounds.width, height: SwipeViewHeight)
            }
        }
        return CGSize.zero
    }
    
    func collectionView(_ collectionView: UICollectionView, viewForSupplementaryElementOfKind kind: String, at indexPath: IndexPath) -> UICollectionReusableView {
        if collectionView == self.collectionView {
            switch kind {
            case UICollectionElementKindSectionHeader:
                let sectionType: SectionType = self.sectionList[indexPath.section]
                switch sectionType {
                case .ColorListSection:
                    let headerView = collectionView.dequeueReusableSupplementaryView(ofKind: kind, withReuseIdentifier: SizeHeaderView.ViewIdentifier, for: indexPath) as! SizeHeaderView
                    
                    //                        headerView.topPadding = SizeHeaderViewTopPadding
                    //                        headerView.hideSizeInformation(!style.haveSizeGrid())
                    headerView.leftMargin = 14
                    headerView.rightMargin = 14
                    
                    let colors = style.validColorList.filter{($0.colorId == self.selectedColorId && $0.colorKey == self.selectedColorKey)}
                    
                    if style.validColorList.count == 0{
                        headerView.setSizeReferenceLabelVisibility(false)
                    }
                    else if let color = colors.first {
                        headerView.colorName = color.skuColor
                    } else {
                        headerView.colorName = ""
                    }
                    
                    headerView.hideSideReference()
                    return headerView
                case .SizeListSection:
                    let headerView = collectionView.dequeueReusableSupplementaryView(ofKind: kind, withReuseIdentifier: SizeHeaderView.ViewIdentifier, for: indexPath) as! SizeHeaderView
                    
                    //                        headerView.topPadding = SizeHeaderViewTopPadding
                    //                        headerView.hideSizeInformation(!style.haveSizeGrid())
                    headerView.leftMargin = 14
                    headerView.rightMargin = 14
                    
                    let sizes = style.validSizeList.filter{$0.sizeId == self.selectedSizeId}
                    
                    if style.validSizeList.count == 0{
                        headerView.setSizeReferenceLabelVisibility(false)
                    }
                    else if let size = sizes.first {
                        if size.sizeGroupCode.contain("CUSTOM") {
                            headerView.sizeGroupName = size.sizeName
                        } else {
                            headerView.sizeGroupName = size.sizeGroupName
                        }
                    } else {
                        headerView.sizeGroupName = ""
                    }
                    
                    headerView.sizeHeaderTappedHandler = { [weak self] in
                        if let strongSelf = self {
                            let navigationController = UINavigationController()
                            let viewController = SizeCommentViewController()
                            
                            viewController.sizeComment = strongSelf.style.skuSizeComment
                            viewController.sizeGridImage = strongSelf.style.highestCategoryPriority()?.sizeGridImage
                            
                            navigationController.viewControllers = [viewController]
                            
                            strongSelf.present(navigationController, animated: true, completion: nil)
                        } else {
                            ErrorLogManager.sharedManager.recordNonFatalError(withException: .NullPointer)
                        }
                    }
                    headerView.showSideReference()
                    return headerView
                case .ReviewSection:
                    let headerView = collectionView.dequeueReusableSupplementaryView(ofKind: kind, withReuseIdentifier: RatingHeaderView.ViewIdentifier, for: indexPath) as! RatingHeaderView
                    
                    if let summaryReview = self.summaryReview {
                        var averageRating = "(\(summaryReview.ratingAverage))"
                        headerView.ratingView.rating = Double(summaryReview.ratingAverage)
                        
                        if averageRating.length > 6 {
                            averageRating = String(format: "(%0.2f)", summaryReview.ratingAverage)
                        }
                        
                        headerView.totalValueLabel.text = averageRating
                        headerView.totalCommentLabel.text = "\(summaryReview.reviewCount)\(String.localize("LB_MC_POST_COMMENTS"))"
                    }
                    
                    headerView.delegate = self
                    headerView.ratingView.isUserInteractionEnabled = false
                    
                    let sku = style.skuList.filter({ $0.skuId == skuId }).first
                    
                    headerView.initAnalytics(withViewKey: analyticsViewRecord.viewKey, impressionKey: recordImpression(
                        brandCode: "",
                        impressionRef: style.styleCode,
                        impressionType: AnalyticsImpressionRecord.ImpressionType.Product.rawValue,
                        impressionVariantRef: sku?.skuCode,
                        impressionDisplayName: sku?.skuName,
                        merchantCode: "\(merchant?.merchantCode ?? "")",
                        positionComponent: "AllReviews",
                        positionIndex: nil,
                        positionLocation: "PDP"
                    ))
                    
                    return headerView
                case .SuggestSection:
                    let labelText = String.localize("LB_CA_PDP_RECOMMEND_TAB_TITLE")
                    
                    
                    let headerView = collectionView.dequeueReusableSupplementaryView(ofKind: kind, withReuseIdentifier: SuggestionViewPostHeader.SuggestionViewPostHeaderId, for: indexPath) as! SuggestionViewPostHeader
                    headerView.descriptionLabel.text = labelText
                    return headerView
                case .LastestPostSection:
                    let headerView = collectionView.dequeueReusableSupplementaryView(ofKind: kind, withReuseIdentifier: SuggestionViewPostHeader.SuggestionViewPostHeaderId, for: indexPath) as! SuggestionViewPostHeader
                    headerView.descriptionLabel.text = String.localize("LB_CA_POST_RELATED_POST")
                    //                        self.setAccessibilityIdForView("UILB_RCMD_TO_CONSUMER", view: headerView)
                    return headerView
                default:
                    let headerView = collectionView.dequeueReusableSupplementaryView(ofKind: kind, withReuseIdentifier: "Header", for: indexPath) as! HeaderView
                    headerView.backgroundColor = UIColor.primary2()
                    headerView.showSubviews(false)
                    return headerView
                }
                
            case UICollectionElementKindSectionFooter:
                // Show empty footer in last section
                if indexPath.section == self.sectionList.count - 1 {
                    let defaultFooterView = collectionView.dequeueReusableSupplementaryView(ofKind: kind, withReuseIdentifier: DefaultFooterID, for: indexPath)
                    
                    return defaultFooterView
                } else {
                    let sectionType: SectionType = self.sectionList[indexPath.section]
                    switch sectionType {
                    case .BrandNameSection:
                        let footerView = collectionView.dequeueReusableSupplementaryView(ofKind: kind, withReuseIdentifier: FreeShipFooter.FreeShipFooterId, for: indexPath) as! FreeShipFooter
                        
                        var separatorStyle: CheckoutFooterView.SeparatorStyle = .none
                        
                        if ((!style.isEmptyColorList() || !style.isEmptySizeList())) || (sectionType == .ColorListSection && !style.isEmptySizeList()) {
                            separatorStyle = .singleItem
                        }
                        
                        footerView.setSeparatorStyle(separatorStyle, withColor: Constants.Separator.DefaultColor)
                        
                        if let merchant = self.merchant {
                            footerView.merchant = merchant
                        } else {
                            ErrorLogManager.sharedManager.recordNonFatalError(withException: .NullPointer)
                        }
                        return footerView
                    case .SizeListSection, .ColorListSection:
                        let footerView = collectionView.dequeueReusableSupplementaryView(ofKind: kind, withReuseIdentifier: CheckoutFooterView.ViewIdentifier, for: indexPath) as! CheckoutFooterView
                        footerView.setSeparatorStyle(.singleItem, withColor: UIColor(hexString: "#E7E7E7"))
                        footerView.backgroundColor = UIColor.white
                        return footerView
                    default:
                        break
                    }
                    
                }
                
                //                assert(false, "Unexpected collection view requesting footer view")
                return collectionView.dequeueReusableSupplementaryView(ofKind: kind, withReuseIdentifier: DefaultFooterID, for: indexPath)
            default:
                ErrorLogManager.sharedManager.recordNonFatalError(withException: .TypeMismatch)
                
                assert(false, "Unexpected element kind")
                let headerView = collectionView.dequeueReusableSupplementaryView(ofKind: kind, withReuseIdentifier: "Header", for: indexPath) as! HeaderView
                
                return headerView
            }
        } else {
            ErrorLogManager.sharedManager.recordNonFatalError(withException: .TypeMismatch)
            
            assert(false, "Unexpected collection view requesting header view")
            let headerView = collectionView.dequeueReusableSupplementaryView(ofKind: kind, withReuseIdentifier: "Header", for: indexPath) as! HeaderView
            
            return headerView
        }
    }
    
    
    
    // MARK: Collection View Delegate methods
    
    func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        switch getCollectionType(collectionView) {
        case .RootCollection:
            if let cell = collectionView.cellForItem(at: indexPath) {
                let sectionType: SectionType = self.sectionList[indexPath.section]
                switch sectionType {
                case .ColorListSection:
                    if (self.style.validColorList.indices.contains(indexPath.row)){
                        if self.style.validColorList[indexPath.row].isValid {
                            var skuCode = ""
                            var skuColorCode = ""
                            let validColor = style.validColorList[indexPath.row]
                            
                            if let sku = self.style.searchSku(selectedSizeId, colorId: validColor.colorId, skuColor: validColor.skuColor) {
                                skuCode = sku.skuCode
                                skuColorCode = sku.colorCode
                            } else {
                                ErrorLogManager.sharedManager.recordNonFatalError(withException: .NullPointer)
                            }
                            
                            cell.recordAction(.Tap, sourceRef: skuColorCode, sourceType: .Color, targetRef: skuCode, targetType: .Product)
                            
                            if colorIndexSelected == indexPath.row {
                                if isSelected {
                                    isSelected = false
                                    self.currentPage = 0
                                    featureCollectionView?.contentOffset.x = 0
                                }
                                
                                colorIndexSelected = -1
                                selectedColorId = -1
                                selectedColorKey = ""
                                //                                selectedSkuColor = ""
                                
                                //Fixes can't display PDP image when deselect color
                                if self.style.featuredImageList.count == 0 {
                                    self.style.featuredImageList = style.getDefaultImageList()
                                }
                            } else {
                                if !isSelected {
                                    isSelected = true
                                    self.currentPage = 0
                                    featureCollectionView?.contentOffset.x = 0
                                }
                                
                                colorIndexSelected = indexPath.row
                                selectedColorId = style.validColorList[indexPath.row].colorId
                                selectedColorKey = style.validColorList[indexPath.row].colorKey
                                //                                selectedSkuColor = style.validColorList[indexPath.row].skuColor
                                
                                filteredColorImageList = style.colorImageList.filter({$0.colorKey == style.validColorList[indexPath.row].colorKey})
                                
                                if filteredColorImageList.count == 0{
                                    filteredColorImageList = style.getDefaultImageList()
                                }
                                
                                filteredColorImageList = filteredColorImageList.sorted(){$0.position < $1.position}
                                
                                self.selectedSku = StyleViewController.findSelectedSku(style: self.style, colorId: selectedColorId, colorKey: selectedColorKey, sizeId: selectedSizeId)
                            }
                            
                            reloadAllData()
                            
                            featureCollectionView?.scrollsToTop = true
                            
                            updateSwipeMenuPrice()
                        }
                        
                    }
                case .SizeListSection:
                    if (self.style.validSizeList.indices.contains(indexPath.row)){
                        if self.style.validSizeList[indexPath.row].isValid {
                            var skuCode = ""
                            let validSize = style.validSizeList[indexPath.row]
                            let selectedSkuColor = self.style.findSkuColorFromColorKey(selectedColorKey)
                            if let sku = self.style.searchSku(validSize.sizeId, colorId: selectedColorId, skuColor: selectedSkuColor) {
                                skuCode = sku.skuCode
                            } else {
                                ErrorLogManager.sharedManager.recordNonFatalError(withException: .NullPointer)
                            }
                            
                            cell.recordAction(.Tap, sourceRef: "\(validSize.sizeId)", sourceType: .Size, targetRef: skuCode, targetType: .Product)
                            
                            if self.sizeIndexSelected == indexPath.row {
                                sizeIndexSelected = -1
                                selectedSizeId = -1
                            } else {
                                self.sizeIndexSelected = indexPath.row
                                self.selectedSizeId = self.style.validSizeList[indexPath.row].sizeId
                                
                                self.selectedSku = StyleViewController.findSelectedSku(style: self.style, colorId: selectedColorId, colorKey:selectedColorKey, sizeId: selectedSizeId)
                            }
                            
                            self.reloadAllData()
                            
                            updateSwipeMenuPrice()
                        }
                    }
                case .StyleGetPriceSection:
                    if let styleTagAndGetPriceCell = cell as? StyleTagAndGetPriceCell {
                        if let hidden = styleTagAndGetPriceCell.isHiddenPrice {
                            if hidden {
                                self.isSelectStyleTipGetPrice = false
                            } else {
                                self.isSelectStyleTipGetPrice = !self.isSelectStyleTipGetPrice
                            }
                            self.reloadAllData()
                        }
                    }
                case .StyleBrandSection:
                    openBrandProfile(sender: cell)
                case .BrandNameSection:
                    openBrandProfile(sender: cell)
                case .RecommendSection:
                    openProductLikeUserListPage()
                case .ImageListSection:
                    var imageKeys = [String]()
                    let imageList = self.style.descriptionImageList
                    for image in imageList {
                        imageKeys.append(image.imageKey)
                    }
                    self.popupImageViewer(imageKeyList: imageKeys, index: indexPath.row)
                case .SuggestSection:
                    let style = self.syteStyles[indexPath.row]
                    
                    if let cell = collectionView.cellForItem(at: indexPath){
                        cell.recordAction(.Tap, sourceRef: style.styleCode, sourceType: .Product, targetRef: "PDP", targetType: .View)
                    }
                    
                    let styleViewController = StyleViewController(style: style)
                    styleViewController.suggestStyles = self.syteStyles
                    self.navigationController?.pushViewController(styleViewController, animated: true)
                case .LastestPostSection:
                    if postManager.currentPosts.indices.contains(indexPath.row) {
                        let post = self.postManager.currentPosts[indexPath.row]
                        if let cell = collectionView.cellForItem(at: indexPath) {
                            cell.recordAction(.Tap, sourceRef: "\(post.postId)", sourceType: .Post, targetRef: "Post-Detail", targetType: .View)
                        }
                        let postDetailController = PostDetailViewController(postId: post.postId)
                        self.navigationController?.pushViewController(postDetailController, animated: true)
                    }
                default:
                    break
                }
            } else {
                ErrorLogManager.sharedManager.recordNonFatalError(withException: .IndexOutOfBounds)
            }
        case .FeatureCollection:
            
            if style.videoURL.length > 0 && indexPath.row == 0 {
                return
            }
            
            var imageKeys = [String]()
            let imageList = self.style.featuredImageList
            for image in imageList {
                imageKeys.append(image.imageKey)
            }
            var index = indexPath.row
            if style.videoURL.length > 0 || style.coverURL.length > 0 {
                index -= 1
            }
            self.popupImageViewer(imageKeyList: imageKeys, index: index)
        default:
            break
        }
        
    }
    
    //MARK: - Feature Collection Cell
    
    func numberOfItemsFeatureCollection() -> Int {
        
        var countCoverView = 0
        
        if style.videoURL.length > 0 || style.coverURL.length > 0 {
            countCoverView = 1
        }
        
        if !isSelected {
            return self.style.featuredImageList.count + countCoverView
        }
        
        return self.filteredColorImageList.count + countCoverView
    }
    
    func getFeatureCollectionCell(_ collectionView: UICollectionView, indexPath: IndexPath) -> UICollectionViewCell {
        
        var imageRowIndex = indexPath.row
        var hasVideo = false
        
        //First index will be video， 需要往前移yi'wei
        if style.videoURL.length > 0 {
            imageRowIndex = imageRowIndex - 1
            hasVideo = true
        }
        
        if hasVideo && indexPath.row == 0 {
            
            let featureVideoCell = collectionView.dequeueReusableCell(withReuseIdentifier: FeatureVideoCell.CellIdentifier, for: indexPath as IndexPath) as! FeatureVideoCell
            videoCell = featureVideoCell
    
            if let color = filteredColorImageList.first { // 保证第一屏是video的时候,加入购物车也有图片的动画效果
                KingfisherManager.shared.retrieveImage(with: ImageURLFactory.URLSize128(color.imageKey, category: .product), options: nil, progressBlock: nil) { (image, error, cache, url) in
                    self.currentImage = image
                }
            }
            return featureVideoCell
        }
        
        //Normal cases
        let cell = collectionView.dequeueReusableCell(withReuseIdentifier: FeatureCollectCellId, for: indexPath as IndexPath) as! FeatureCollectionCell
        
        cell.startActivityIndicator()
        
        let skus = style.skuList.filter({ $0.skuId == skuId })
        
        if let sku = skus.first {
            cell.initAnalytics(withViewKey: analyticsViewRecord.viewKey, impressionKey: recordImpression(
                brandCode: "\(style.brandId)",
                impressionRef: style.styleCode,
                impressionType: "Product",
                impressionVariantRef: sku.skuCode,
                impressionDisplayName: sku.skuName,
                merchantCode: "\(merchant?.merchantCode ?? "")",
                positionComponent: "HeroImage",
                positionIndex: indexPath.row + 1,
                positionLocation: "PDP"
            ))
        } else {
            ErrorLogManager.sharedManager.recordNonFatalError(withException: .NullPointer)
        }
        
        if colorIndexSelected < 0 && selectedColorId < 0 {
            if imageRowIndex < self.style.featuredImageList.count {
                if (self.style.featuredImageList.indices.contains(imageRowIndex)){
                    cell.setImage(self.filteredColorImageList[imageRowIndex].imageKey, contentMode: .scaleAspectFit, completion: { (image) in
                        self.currentImage = image
                    })
                }
                
            }
        } else {
            if imageRowIndex < self.filteredColorImageList.count {
                if (self.style.featuredImageList.indices.contains(imageRowIndex)){
                    cell.setImage(self.filteredColorImageList[imageRowIndex].imageKey, contentMode: .scaleAspectFit, completion: { (image) in
                        self.currentImage = image
                    })
                }
            }
        }
        
        //        cell.featureImageView.setupImageViewer(with: self, initialIndex: imageRowIndex, parentTag:indexPath.section, onOpen: { [weak self] () -> Void in
        //            if let strongSelf = self{
        //                let longPress = UILongPressGestureRecognizer(target: strongSelf, action: #selector(StyleViewController.handleLongPressOnProductImage))
        //                cell.featureImageView.imageBrowser.view.addGestureRecognizer(longPress)
        //                strongSelf.facebookImageViewer = cell.featureImageView.imageBrowser
        //            }
        //            }, onClose: { () -> Void in
        //                self.navigationController?.isNavigationBarHidden = false
        //
        //        })
        //        cell.featureImageView.isFullScreenItemOnDisplay = true
        self.setAccessibilityIdForView("UI_PRODUCT_IMG", view: cell.featureImageView)
        
        return cell
    }
    
    // MARK: -
    
    func reloadAllData(checkValid:Bool = false) {
        self.sectionList.removeAll()
        self.sectionList.append(.ProductImageSection)
        
        if let selectedSku = self.selectedSku, selectedSku.isFlashSaleExists, self.isFlashSaleEligible {
            self.sectionList.append(.FlashSaleSection)
            self.bottomView.setIsFlashSale(true)
        } else {
            self.bottomView.setIsFlashSale(false)
            self.sectionList.append(.StylePriceSection)
            let (_ , retailPrice) = self.getPriceBySelectedSku()
            if retailPrice > 0 {
                self.sectionList.append(.StyleRealPriceSection)
            }
        }
        
        

        self.sectionList.append(.StyleGetPriceSection)
        if isSelectStyleTipGetPrice {
            self.sectionList.append(.StyleTipGetPriceSection)
        }
        self.sectionList.append(.StyleNameSection)
        self.sectionList.append(.StyleBrandSection)
        
        if self.coupons.count > 0 {
            self.sectionList.append(.MarginSection)
            self.sectionList.append(.CouponSection)
        }
        if self.style.validColorList.count > 0{
            if self.style.validColorList.count == 1 && self.style.validColorList[0].colorId == NoColor {
            }else{
                self.sectionList.append(.MarginSection)
                self.sectionList.append(.ColorListSection)
            }
        }
        
        if self.style.validSizeList.count > 0 {
            if self.style.validSizeList.count == 1 && self.style.validSizeList[0].sizeId == NoSize {
            }else{
                if self.style.validColorList.count <= 0 || ( self.style.validColorList.count == 1 && self.style.validColorList[0].colorId == NoColor){
                    self.sectionList.append(.MarginSection)
                }
                self.sectionList.append(.SizeListSection)
            }
        }
        self.sectionList.append(.MerchantSection)

        
        self.sectionList.append(.ReviewSection)
        if self.productLikeList.count > 0 {
//            self.sectionList.append(.UserListSection)
//            self.sectionList.append(.RecommendSection)
        }
        self.sectionList.append(.DescriptionSection)
        self.sectionList.append(.ImageListSection)
        self.sectionList.append(.CrossBorderStatementSection)
        self.sectionList.append(.OutfitSection)
        self.sectionList.append(.SuggestSection)
//        self.sectionList.append(.LastestPostSection)
        
        let sizeSections = self.sectionList.filter{$0 == .SizeListSection}
        
        if (sizeSections.indices.contains(0)){
            detailCollectionViewFlowLayout?.sizeSection = self.sectionList.index(of: sizeSections[0]) ?? -1
        }else{
            ErrorLogManager.sharedManager.recordNonFatalError(withException: .NullPointer)
        }
        
//        main_async {
            self.featureCollectionView?.reloadData()
            self.userCollectionView?.reloadData()
            self.suggestColectionView?.reloadData()
            self.collectionView?.reloadData()
            self.collectionView.collectionViewLayout.invalidateLayout()
            self.inactiveProductView.isHidden = self.isProductActive
            self.collectionView.isHidden = !self.isProductActive
            self.updateInactiveOrOutOfStockFooterView(checkValid:checkValid)
//        }
    }
    
    deinit {
        //防止异步返回reload刷新页面
        self.featureCollectionView?.delegate = nil
        self.featureCollectionView?.dataSource = nil
        self.userCollectionView?.delegate = nil
        self.userCollectionView?.dataSource = nil
        self.suggestColectionView?.delegate = nil
        self.suggestColectionView?.dataSource = nil
        self.collectionView?.delegate = nil
        self.collectionView?.dataSource = nil
        NotificationCenter.default.removeObserver(self)
    }
    
    func getSaleDateBySelectedSku() -> (dateSaleTo: Date?, dateSaleFrom: Date?) {
        let selectedSkuColor = self.style.findSkuColorFromColorKey(selectedColorKey)
        if selectedColorId > 0 && selectedSizeId > 0 && selectedSkuColor.length > 0 {
            if let sku = self.style.searchSku(selectedSizeId, colorId: selectedColorId, skuColor: selectedSkuColor) {
                return (sku.saleTo, sku.saleFrom)
            }
        }
        
        return (self.style.saleTo, self.style.saleFrom)
    }
    
    func getPriceBySelectedSku() -> (salePrice: Double, retailPrice: Double) {
        var retailPrice: Double = 0
        var salePrice: Double = 0
        let selectedSkuColor = self.style.findSkuColorFromColorKey(selectedColorKey)
        if selectedColorId > 0 && selectedSizeId > 0 && selectedSkuColor.length > 0 {
            if let sku = self.style.searchSku(selectedSizeId, colorId: selectedColorId, skuColor: selectedSkuColor) {
                retailPrice = sku.priceRetail
                if sku.isOnSale() {
                    salePrice = sku.priceSale
                }
            }
        }
        
        if retailPrice <= 0 && salePrice <= 0 {
            if let sku = self.style.defaultSku() {
                retailPrice = sku.priceRetail
                if sku.isOnSale() {
                    salePrice = sku.priceSale
                }
            }
        }
        
        //Fix wrong displaying price color when saleprice = 0 and retailPrice > 0
        if salePrice <= 0 && retailPrice > 0 {
            salePrice = retailPrice
            retailPrice = 0
        }
        
        return (salePrice, retailPrice)
    }
    
    func price() -> String? {
        let formatter = NumberFormatter()
        formatter.numberStyle = NumberFormatter.Style.currency
        formatter.locale = NSLocale(localeIdentifier: "zh_Hans_CN") as Locale?
        formatter.maximumFractionDigits = 0
        let price = self.style.getSkuPrice(colorKey: self.selectedColorKey, sizeId: self.selectedSizeId)
        return price.formatPrice()
    }
    
    func skuCellTextHeight(style: Style) -> CGFloat {
        var cellHeight: CGFloat = 0.0
        //计算图高宽,可能来自imageKey
        var whratio: Float = 1.0
        let cellWidth = ScreenWidth/2.0 - 19.0
        var imageHeight = cellWidth
        if let r = style.imageDefault.whratio() {
            whratio = r
        }
        if whratio > 2.0 {
            whratio = 2.0
        }
        imageHeight = imageHeight * CGFloat(whratio)
        
        var titleHeight:CGFloat = 0.0
        var contentHeight:CGFloat = 0.0
        var tageHeight:CGFloat = 12.0
        
            if !style.isCrossBorder && style.couponCount == 0 && style.shippingFee != 0 {
                tageHeight = 0
            }
            
            titleHeight = 20
            
            var contentTagWidth: CGFloat = 0
            if style.badgeId == 1 || style.badgeId == 2 || style.badgeId == 4 {
                contentTagWidth = 22
            } else if style.badgeId == 3 {
                contentTagWidth = 40 // 明显同款图片的富文本宽度
            }
            contentHeight = style.skuName.getTextWidth(height: 15, font: UIFont.systemFont(ofSize: 12)) + contentTagWidth + 5 > (cellWidth - 20.0) ? 30 : 15
            
            if style.brandId != 0 {
                contentHeight += MMMargin.CMS.imageToTitle
            }
        
        cellHeight = imageHeight + MMMargin.CMS.defultMargin + titleHeight + MMMargin.CMS.contentToPrice + contentHeight + 15 + MMMargin.CMS.contentToPrice + tageHeight + MMMargin.CMS.defultMargin
        return cellHeight
    }
    /*
     func createSwipeView() {
     swipeViewContainer = UIView(frame: CGRect(x:0, y: self.view.frame.height - SwipeViewHeight, width: self.view.frame.width, height: SwipeViewHeight))
     swipeViewContainer.backgroundColor = UIColor.white
     swipeViewContainer.isHidden = true
     
     let topBorderView = UIView(frame: CGRect(x:0, y: 0, width: swipeViewContainer.frame.sizeWidth, height: 1))
     topBorderView.backgroundColor = UIColor.backgroundGray()
     swipeViewContainer.addSubview(topBorderView)
     
     self.view.addSubview(swipeViewContainer)
     
     let swipeMenuWidth: CGFloat = (view.width <= 320) ? 150 : 180
     
     swipeMenu = SwipeMenu(price: self.price(), width: swipeMenuWidth)
     
     if let swipeMenu = self.swipeMenu {
     swipeMenu.initAnalytics(withViewKey: analyticsViewRecord.viewKey)
     
     swipeMenu.frame = CGRect(x:10, y: (SwipeViewHeight - SwipeMenu.SwipeMenuHeight) / 2, width: swipeMenu.frame.width, height: swipeMenu.frame.height)
     swipeViewContainer.addSubview(swipeMenu)
     
     swipeMenu.triggerHandler = { [weak self] isSwipe in
     if let strongSelf = self {
     strongSelf.handleBuy()
     } else {
     ErrorLogManager.sharedManager.recordNonFatalError(withException: .NullPointer)
     }
     }
     } else {
     ErrorLogManager.sharedManager.recordNonFatalError(withException: .NullPointer)
     }
     
     let rightIconDimension: CGFloat = 40
     let padding: CGFloat = 10
     
     let shareButton = UIButton(type: .custom)
     shareButton.frame = CGRect(x:swipeViewContainer.width - rightIconDimension - padding, y: (swipeViewContainer.height - rightIconDimension) / 2, width: rightIconDimension, height: rightIconDimension)
     shareButton.setImage(UIImage(named: "icon_PDP_share"), for: .normal)
     shareButton.addTarget(self, action: #selector(self.share), for: .touchUpInside)
     shareButton.initAnalytics(withViewKey: analyticsViewRecord.viewKey)
     shareButton.tag = BottomButtonTag.ShareProduct.rawValue
     swipeViewContainer.addSubview(shareButton)
     
     let createPostButton = UIButton(type: .custom)
     createPostButton.frame = CGRect(x:shareButton.x - rightIconDimension - padding, y: (swipeViewContainer.height - rightIconDimension) / 2, width: rightIconDimension, height: rightIconDimension)
     createPostButton.setImage(UIImage(named: "icon_PDP_post"), for: .normal)
     createPostButton.addTarget(self, action: #selector(self.createPost), for: .touchUpInside)
     createPostButton.initAnalytics(withViewKey: analyticsViewRecord.viewKey)
     createPostButton.tag = BottomButtonTag.CreatePost.rawValue
     self.createPostButton = createPostButton
     swipeViewContainer.addSubview(createPostButton)
     
     let imButton = UIButton(type: .custom)
     imButton.frame = CGRect(x:createPostButton.x - rightIconDimension - padding, y: (swipeViewContainer.height - rightIconDimension) / 2, width: rightIconDimension, height: rightIconDimension)
     imButton.setImage(UIImage(named: "cs"), for: .normal)
     imButton.addTarget(self, action: #selector(self.chatWithCS), for: .touchUpInside)
     imButton.initAnalytics(withViewKey: analyticsViewRecord.viewKey)
     imButton.tag = BottomButtonTag.CustomerService.rawValue
     swipeViewContainer.addSubview(imButton)
     
     IMButton = imButton
     //        self.updateInactiveOrOutOfStockFooterView()
     }*/
    
    func createBottomView(){
        bottomView = ProductDetailBottomView()
        view.addSubview(bottomView)
        
        bottomView.snp.makeConstraints { [weak self] (target) in
            guard let strongSelf = self else {
                return
            }
            target.left.equalTo(0)
            target.bottom.equalTo(0)
            target.right.equalTo(0)
            target.height.equalTo(strongSelf.SwipeViewHeight)
        }
        
        bottomView.addtocartTapHandler = {[weak self] in
            if let strongSelf = self {
                strongSelf.handleAddToCart()
            }
        }
        bottomView.buyTapHandler = {[weak self] in
            if let strongSelf = self {
                strongSelf.handleBuy()
            }
        }
        bottomView.buyFlashSaleHandler = {[weak self] in
            if let strongSelf = self {
                strongSelf.buyFlashSale()
            }
        }
        bottomView.csTapHandler = {[weak self] in
            if let strongSelf = self {
                strongSelf.chatWithCS(sender: strongSelf.bottomView)
            }
        }
        bottomView.postTapHandler = {
            Navigator.shared.dopen(Navigator.mymm.website_cart)
//            strongSelf.createPost(sender: strongSelf.bottomView)
        }
        bottomView.wishTapHandler = {[weak self] in
            if let strongSelf = self {
                strongSelf.actionLike()
            }
        }
        
        bottomView.setLike(self.style.isWished())
    }
    
    func addToCart(){
        if (selectedSizeId > -1 && selectedColorId > -1){
            let selectedSkuColor = self.style.findSkuColorFromColorKey(selectedColorKey)
            if let searchSku = style.searchSku(selectedSizeId, colorId: selectedColorId, skuColor: selectedSkuColor) {
                LoadingOverlay.shared.showOverlay(self)
                CartService.addCartItem(searchSku.skuId, qty: 1, referrer: referrerUserKey, completion: { response in
                    if response.result.isSuccess {
                        if response.response?.statusCode == 200 {
                            // cached it
                            let cart = Mapper<Cart>().map(JSONObject: response.result.value)
                            CacheManager.sharedManager.cart = cart
                            self.showAddToCartAnimation()
                            LoadingOverlay.shared.hideOverlayView()
                        }else{
                            LoadingOverlay.shared.hideOverlayView()
                        }
                    }else{
                        LoadingOverlay.shared.hideOverlayView()
                    }
                })
            } else {
                showError(String.localize("LB_MC_COLORS_SIZE_TITLE"), animated: true)
            }
            
        }else{
            showError(String.localize("LB_MC_COLORS_SIZE_TITLE"), animated: true)
        }
        
        
        
    }
    
    var userDismissCouponSuggestion = false
    
    func loadCoupon() {
        guard LoginManager.getLoginState() == .validUser else { return  }
        
        when(fulfilled: CouponManager.shareManager().coupons(forMerchantId: CouponMerchant.combine.rawValue), CouponManager.shareManager().wallet(forMerchantId: CouponMerchant.combine.rawValue))
            .then {[weak self] responseCounpon, responseClaimedCounpon -> Void in
                if let strongSelf = self {
                    if let availables = responseCounpon.coupons {
                        var availableCoupons = availables.filter({ ($0.eligible() && $0.isSegmentedFilter(merchantId: strongSelf.style.merchantId, brandId: strongSelf.style.brandId, categories: strongSelf.style.categoryPriorityList)) &&
                            (($0.isMmCoupon() && $0.isSegmentedCriteria(merchantId: strongSelf.style.merchantId, brandId: strongSelf.style.brandId, categories: strongSelf.style.categoryPriorityList)) ||
                                $0.merchantId == strongSelf.style.merchantId ) })
                        availableCoupons.sort(by: { ($0.lastCreated ?? Date()).compare($1.lastCreated ?? Date()) == .orderedDescending })
                        strongSelf.coupons = Array(availableCoupons)
                        
                        if let result = responseClaimedCounpon.coupons {
                            strongSelf.claimedCoupons = result.filter { ($0.isRedeemable && $0.isSegmentedFilter(merchantId: strongSelf.style.merchantId, brandId: strongSelf.style.brandId, categories: strongSelf.style.categoryPriorityList) ) &&
                                (($0.isMmCoupon() && $0.isSegmentedCriteria(merchantId: strongSelf.style.merchantId, brandId: strongSelf.style.brandId, categories: strongSelf.style.categoryPriorityList)) ||
                                    $0.merchantId == strongSelf.style.merchantId) }
                        }
                        strongSelf.reloadAllData()
                    }
                }
            }.catch { (error) in
                Log.error("error")
        }
        
    }
    
    let CouponSuggestionHeight : CGFloat = 36.0
    var offerDescLabel: UILabel?
    
    @objc func dismissCouponSuggestion(sender: UIButton) {
        userDismissCouponSuggestion = true
        couponSuggestionPopView?.removeFromSuperview()
    }
    
    @objc func showPopupCampaign(sender: UIButton) {
        chatWithCS(sender: sender)
//        BannerManager.sharedManager.getCampaigns().then { (success) -> Void in
//            if !success {
//                self.inviteFriend()
//            }
//        }
        
    }
    
    func inviteFriend() {
        let shareViewController = ShareViewController(screenCapSharing: false)
        
        shareViewController.viewKey = self.analyticsViewRecord.viewKey
        shareViewController.isSharingByInviteFriend = true
        shareViewController.didSelectSNSHandler = { method in
            let appName = Bundle.main.infoDictionary!["CFBundleDisplayName"] as? String ?? ""
            var title = String.localize("LB_CA_NATURAL_REF_SNS_MSG")
            title = title.replacingOccurrences(of: "{0}", with: appName)
            
            ShareManager.sharedManager.inviteFriend(title, description: String.localize("LB_CA_NATURAL_REF_SNS_DESC"), url: Constants.Path.DeepLinkURL, image: UIImage(named : "AppIcon"), method: method)
        }
        self.present(shareViewController, animated: false, completion: nil)
    }
    
    @objc func chatWithCS(sender: UIView) {
        checkFlashSaleReload(block:{
            self.privateChatWithCS(sender:sender)
        })
    }
    
    private func privateChatWithCS(sender: UIView) {
        if LoginManager.getLoginState() != .validUser {
            LoginManager.goToLogin {
                self.privateChatWithCS(sender: sender)
            }
            return
        }
        
        sender.recordAction(.Tap, sourceRef: "CustomerSupport", sourceType: .Button, targetRef: "Chat-Customer", targetType: .View)
        
        IMButton?.isEnabled = false
        
        let myRole: UserRole = UserRole(userKey: Context.getUserKey())
        
        WebSocketManager.sharedInstance().sendMessage(
            IMConvStartToCSMessage(
                userList: [myRole],
                queue: .Presales,
                senderMerchantId: myRole.merchantId,
                merchantId: style.merchantId
            ),
            completion: { [weak self] ack in
                if let strongSelf = self {
                    strongSelf.IMButton?.isEnabled = true
                    
                    if let convKey = ack.data {
                        let viewController = UserChatViewController(convKey: convKey)
                        let productModel = ProductModel()
                        productModel.style = strongSelf.style
                        productModel.sku = strongSelf.style.defaultSku()
                        
                        let chatModel = ChatModel.init(productModel: productModel)
                        chatModel.messageContentType = MessageContentType.Product
                        
                        viewController.forwardChatModel = chatModel
                        strongSelf.navigationController?.pushViewController(viewController, animated: true)
                    } else {
                        ErrorLogManager.sharedManager.recordNonFatalError(withException: .NullPointer)
                    }
                } else {
                    ErrorLogManager.sharedManager.recordNonFatalError(withException: .NullPointer)
                }
            }, failure: { [weak self] in
                if let strongSelf = self {
                    strongSelf.showErrorAlert(String.localize("MSG_ERR_NETWORK_1009"))
                }
            }
        )
    }
    
    @objc func share(sender: UIButton) {
        sender.recordAction(.Tap, sourceRef: "Share", sourceType: .Button, targetRef: style.styleCode, targetType: .Product)
        
        self.presentShareSheet()
    }
    
    func presentShareSheet(triggerByScreenCap: Bool = false){
        
        let shareViewController = ShareViewController(screenCapSharing: triggerByScreenCap)
        
        shareViewController.viewKey = self.analyticsViewRecord.viewKey
        
        shareViewController.didUserSelectedHandler = { (data) in
            let myRole: UserRole = UserRole(userKey: Context.getUserKey())
            let targetRole: UserRole = UserRole(userKey: data.userKey)
            
            WebSocketManager.sharedInstance().sendMessage(
                IMConvStartMessage(
                    userList: [myRole, targetRole],
                    senderMerchantId: myRole.merchantId
                ),
                completion: { [weak self] (ack) in
                    if let strongSelf = self {
                        if let convKey = ack.data {
                            let viewController = UserChatViewController(convKey: convKey)
                            let style = strongSelf.style
                            let productModel = ProductModel()
                            
                            productModel.style = style
                            productModel.sku = style.defaultSku()
                            
                            let chatModel = ChatModel.init(productModel: productModel)
                            chatModel.messageContentType = MessageContentType.Product
                            
                            viewController.forwardChatModel = chatModel
                            strongSelf.navigationController?.pushViewController(viewController, animated: true)
                        } else {
                            ErrorLogManager.sharedManager.recordNonFatalError(withException: .NullPointer)
                        }
                    } else {
                        ErrorLogManager.sharedManager.recordNonFatalError(withException: .NullPointer)
                    }
                }, failure: { [weak self] in
                    if let strongSelf = self {
                        strongSelf.showErrorAlert(String.localize("MSG_ERR_NETWORK_1009"))
                    }
                }
            )
        }
        
        shareViewController.didSelectSNSHandler = { [weak self] method in
            if let strongSelf = self {
                let selectedSkuColor = strongSelf.style.findSkuColorFromColorKey(strongSelf.selectedColorKey)
                var searchSku = strongSelf.style.searchSku(strongSelf.selectedSizeId, colorId: strongSelf.selectedColorId, skuColor: selectedSkuColor)
                if searchSku == nil {
                    searchSku = strongSelf.style.defaultSku()
                }
                
                if let foundSku = searchSku {
                    ShareManager.sharedManager.shareProduct(foundSku, suppliedStyle: strongSelf.style, method: method, referrer: Context.getUserKey())
                } else {
                    ErrorLogManager.sharedManager.recordNonFatalError(withException: .NullPointer)
                }
            } else {
                ErrorLogManager.sharedManager.recordNonFatalError(withException: .NullPointer)
            }
        }
        
        if triggerByScreenCap {
            shareViewController.provideCapscreenView = {
                let container = UIView(frame: CGRect(x:0 , y: 0, width: 300, height: 450))
                let productImageView = UIImageView(frame: CGRect(x:10 , y: 10, width: 280, height: 330))
                if self.style.featuredImageList.count > 0 {
                    productImageView.mm_setImageWithURL(ImageURLFactory.URLSize1000(self.style.featuredImageList[0].imageKey, category: .product), placeholderImage: UIImage(named: "holder"), contentMode: .scaleAspectFit)
                }
                
                productImageView.autoresizingMask = [.flexibleWidth, .flexibleHeight]
                
                let merchantImageView = UIImageView(frame: CGRect(x:(300 - Constants.Value.PdpBrandImageWidth) / 2  , y: 350, width: Constants.Value.PdpBrandImageWidth, height: Constants.Value.PdpBrandImageHeight))
                merchantImageView.mm_setImageWithURL(ImageURLFactory.URLSize512(self.style.brandHeaderLogoImage, category: .brand), placeholderImage: UIImage(named: "holder"), contentMode: UIViewContentMode.scaleAspectFit)
                merchantImageView.autoresizingMask = [.flexibleTopMargin, .flexibleLeftMargin, .flexibleRightMargin]
                
                let productTitleLabel = UILabel(frame: CGRect(x:10, y: 400, width: 280, height: 20))
                productTitleLabel.autoresizingMask = [.flexibleWidth, .flexibleTopMargin]
                productTitleLabel.text = self.style.skuName
                productTitleLabel.formatSize(12)
                productTitleLabel.textAlignment = .center
                productTitleLabel.textColor = UIColor.blackLight()
                
                
                let priceTitleLabel = UILabel(frame: CGRect(x:10, y: 420, width: 280, height: 20))
                priceTitleLabel.autoresizingMask = [.flexibleWidth, .flexibleTopMargin]
                priceTitleLabel.attributedText = PriceHelper.fillPrice(self.style.priceSale, priceRetail: self.style.priceRetail, isSale: self.style.isOnSale().hashValue)
                priceTitleLabel.formatSize(12)
                priceTitleLabel.textAlignment = .center
                priceTitleLabel.textColor = UIColor.blackLight()
                
                container.addSubview(productImageView)
                container.addSubview(merchantImageView)
                container.addSubview(productTitleLabel)
                container.addSubview(priceTitleLabel)
                
                //layout part
                
                
                return container
            }
        }
        
        self.present(shareViewController, animated: false, completion: nil)
        
    }
    
    private func reportReview(){
        if LoginManager.getLoginState() != .validUser {
            LoginManager.goToLogin {
                self.reportReview()
            }
            return
        }
        
        if let reviewAnalyticsSectionData = reviewAnalyticsSectionData {
            reviewAnalyticsSectionData.recordAction(.Tap, sourceRef: "ReportReview", sourceType: .Button, targetRef: "\(summaryReview?.skuReview?.skuReviewId ?? 0)", targetType: .Review)
        } else {
            ErrorLogManager.sharedManager.recordNonFatalError(withException: .NullPointer)
        }
        
        let afterSalesViewController = AfterSalesViewController()
        afterSalesViewController.currentViewType = .reportReview
        afterSalesViewController.delegate = self
        afterSalesViewController.skuReview = summaryReview?.skuReview
        let navigationController = MmNavigationController(rootViewController: afterSalesViewController)
        
        present(navigationController, animated: true, completion: nil)
    }
    
    private func checkFlashSaleReload(block: (() -> Void)? = nil) {
        //标识从未登录转到登录
        if self.isFlashSaleEligible && self.isLoginStatueEnter && LoginManager.getLoginState() == .validUser {
            //全部刷新一遍
            self.checkUserEligible(block:block)
            
            return
        }
        
        if block != nil {
            block?()
        }
    }
    
    // 添加购物车
    private func handleAddToCart(){
        checkFlashSaleReload(block: {
            if LoginManager.getLoginState() == .validUser {
                self.view.recordAction(.Tap, sourceRef: "AddToCart", sourceType: .Button, targetRef: self.style.styleCode, targetType: .Product)
                self.openCheckoutPage(type: .AddCart)
            } else {
                LoginManager.goToLogin(loginAfterCompletion: {
                    self.handleAddToCart()
                })
            }
        })
    }
    
    // 立即购买
    private func handleBuy(){
        checkFlashSaleReload(block: {
            if LoginManager.getLoginState() == .validUser {
                self.view.recordAction(.Slide, sourceRef: "SwipeToBuy", sourceType: .Button, targetRef: "Checkout", targetType: .View)
                self.openCheckoutPage(type: .HandleBuy)
            } else {
                LoginManager.goToLogin(loginAfterCompletion: {
                    self.handleBuy()
                })
            }
        })
    }
    
    private func getErrorInfo(_ response: DataResponse<Any>) -> [String: String] {
        var errorInfo = [String: String]()
        
        if let resp = Mapper<ApiResponse>().map(JSONObject: response.value) {
            if let appCode = resp.appCode {
                errorInfo["AppCode"] = appCode
            }
            else {
                errorInfo["AppCode"] = "LB_ERROR"
            }
            
            if let message = resp.message {
                errorInfo["Message"] = message
            }
        }
        
        return errorInfo
    }
    
    private func buyFlashSale() {
        checkFlashSaleReload(block:{
            self.privateBuyFlashSale()
        })
    }
    private func privateBuyFlashSale() {
        if LoginManager.getLoginState() == .validUser {
            guard let selectedSku = self.selectedSku else {
                return
            }
            self.view.recordAction(.Slide, sourceRef: "限购", sourceType: .Button, targetRef: "Checkout", targetType: .View)
            //以下异常逻辑处理摘自 CheckoutPresenter.checkOutOfStock中对异常的处理
            self.gotoFlashBuy(style:self.style,sku:selectedSku)
        } else {
            LoginManager.goToLogin {
                self.privateBuyFlashSale()
            }
        }
    }
    
    // 此方法对外开放，因为弹层也需要goto flashBuy
    func gotoFlashBuy(style: Style, sku:Sku) {
        
        let skuDic: [String: Any] = ["Qty" : 1, /* limited to 1 for flash sale */
            "StyleCode" : style.styleCode,
            "MerchantId" : sku.merchantId,
            "SkuId" : sku.skuId]
        let orderDic: [String: Any] = ["MerchantId" : sku.merchantId, "Comments" : ""]
        
        //以下异常逻辑处理摘自 CheckoutPresenter.checkOutOfStock中对异常的处理
        let failure:(_ err:Error) -> Void = { (err) in
            var message = ""
            if let errorInfo = (err as NSError).userInfo as? [String: String] {
                message = String.localize(errorInfo["AppCode"] ?? "")
                
                /*
                 if errorInfo["AppCode"] == "MSG_ERR_CA_COUPON_MIN_PURCHASE_MEET" {
                 if let couponReference = errorInfo["Message"], let minSpendAmount = self.findMinimumSpendAmount(withCouponReference: couponReference , mmCoupon: coupon) {
                 message = String.localize("MSG_ERR_CA_COUPON_MIN_PURCHASE_MEET").replacingOccurrences(of: "{0}", with: "\(minSpendAmount)")
                 }
                 }
                 
                 if errorInfo["AppCode"] == "MSG_ERR_CART_NOT_FOUND" {
                 message = ""
                 let viewController = IDCardCollectionPageViewController(updateCardAction: .swipeToPay)
                 viewController.callBackAction = {
                 completion?(true)
                 }
                 }
                 */
            }
            self.showError(message, animated: true)
        }
        
        OrderService.checkStock([skuDic], orders: [orderDic], isFlashSale: true, completion: { [weak self] (response) in
            if let strongSelf = self {
                if response.result.isSuccess {
                    if response.response?.statusCode == 200 {
                        if let order = Mapper<ParentOrder>().map(JSONObject: response.result.value) {
                            //从原来页面将sku带过去
                            if sku.qty != 1 {
                                sku.qty = 1
                            }
                            // 此处逻辑与确认订单页面 CheckoutPresenter.goToConfirmationPage逻辑一致，仅仅增加闪购标识
                            let confirmationVC = FCheckoutViewController(checkoutMode: .cartCheckout, sku: sku, style: strongSelf.style, referrerUserKey: strongSelf.referrerUserKey)
                            confirmationVC.isCart = false
                            confirmationVC.isFlashSale = true
                            confirmationVC.checkoutFromSource = .unknown
                            confirmationVC.styleViewController = strongSelf
                            confirmationVC.updateParent(order)
                            strongSelf.navigationController?.push(confirmationVC, animated: true)
                        }
                    } else {
                        var statusCode = 0
                        if let code = response.response?.statusCode {
                            statusCode = code
                        }
                        let errorInfo = strongSelf.getErrorInfo(response)
                        let error = NSError(domain: "", code: statusCode, userInfo: errorInfo)
                        failure(error)
                    }
                } else {
                    var error: Error?
                    
                    if response.result.error != nil && (response.result.error as NSError?)?.userInfo != nil {
                        error = response.result.error
                    } else {
                        error = NSError(domain: "", code: 0, userInfo: ["errorCode": "LB_ERROR"])
                    }
                    
                    if let err = error {
                        failure(err)
                    }
                }
            }
        })
    }
    
    private func openCheckoutPage(type: BuyOrAddCartType) {
        if style.skuList.count > 1  || type == .HandleBuy { // 需要弹窗显示sku进行选择
            gotoMultiSkuCheckoutVC(type)
        } else { // 直接添加到购物车或者到订单页
            if type == .AddCart {
                addShoppingCartAction()
            }
        }
    }
    
    /// 直接跳订单详情页 暂时不适用
    private func gotoOrderDetailVC() {
        //从原来页面将sku带过去
        let sku = style.skuList.first
        if let sku = sku {
            if sku.qty != 1 {
                sku.qty = 1
            }
            // 此处逻辑与确认订单页面 CheckoutPresenter.goToConfirmationPage逻辑一致，
            let confirmationVC = FCheckoutViewController(checkoutMode: .cartCheckout, sku: sku, style:self.style, referrerUserKey: self.referrerUserKey)
            confirmationVC.isCart = false
            confirmationVC.checkoutFromSource = .unknown
            confirmationVC.styleViewController = self
            navigationController?.push(confirmationVC, animated: true)
        }
    }
    
    /// 添加到购物车
    private func addShoppingCartAction() {
        let selectedColor = style.getValidColorAtIndex(0)
        let selectedSizeId = style.getValidSizeIdAtIndex(0)
        
        if (style.isEmptyColorList() || selectedColor != nil) && (style.isEmptySizeList() || selectedSizeId != -1) {
            if let sku = style.searchSku(selectedSizeId, colorId: selectedColor?.colorId, skuColor: selectedColor?.skuColor) {
                if sku.qty != 1 {
                    sku.qty = 1
                }
                self.addCartItem(sku.skuId, qty: sku.qty, referrer: self.referrerUserKey, success: {
                    LoadingOverlay.shared.hideOverlayView()
                    self.showAddToCartAnimation()
                    self.bottomView.cartNumber = CacheManager.sharedManager.numberOfCartItems()
                }, fail: {
                    Alert.alertWithSingleButton(self, title: "", message: String.localize("LB_CA_ADD2CART_FAIL"), buttonString:String.localize("LB_OK"))
                    LoadingOverlay.shared.hideOverlayView()
                })
            } else {
                ErrorLogManager.sharedManager.recordNonFatalError(withException: .NullPointer)
            }
        } else {
            // Missing SKU handling
            showFailPopupWithText(String.localize("Fail to add shopping cart: Missing Sku"))
            ErrorLogManager.sharedManager.recordNonFatalError(withException: .NullPointer, parameters: ["message" : "Missing Sku."])
        }
    }
    
    /// 有多个sku时跳转选择sku的弹框界面
    private func gotoMultiSkuCheckoutVC(_ type: BuyOrAddCartType) {
        var selectedSkuColor: String?
        var selectedColorId: Int?
        
        if self.colorIndexSelected >= 0 && self.colorIndexSelected < self.style.validColorList.count {
            selectedSkuColor = self.style.validColorList[self.colorIndexSelected].skuColor
            selectedColorId = self.style.validColorList[self.colorIndexSelected].colorId
        }
        let checkoutViewController = FCheckoutViewController(checkoutMode: .style, merchant: self.merchant, style: self.style, referrer: self.referrerUserKey, selectedSkuColor: selectedSkuColor, selectedColorId: selectedColorId, selectedSizeId: self.selectedSizeId, redDotButton: self.buttonCart, targetRef: "PDP")
        checkoutViewController.styleViewController = self
        checkoutViewController.checkoutFromSource = self.checkoutFromSource
        checkoutViewController.isFlashSaleEligible = self.isFlashSaleEligible
        if type == .HandleBuy {
            checkoutViewController.checkOutActionType = .checkout
        } else if type == .AddCart {
            checkoutViewController.checkOutActionType = .addToCart
        }
        checkoutViewController.didDismissHandler = { [weak self] (confirmed, parentOrder) in
            if let strongSelf = self{
                strongSelf.loadCoupon()
                strongSelf.updateButtonCartState()
                strongSelf.updateButtonWishlistState()
                strongSelf.bottomView.cartNumber = CacheManager.sharedManager.numberOfCartItems()
                if confirmed {
                    strongSelf.showLoading()
                    strongSelf.paidOrder = parentOrder
                    Timer.scheduledTimer(timeInterval: 0.5, target: strongSelf, selector: #selector(strongSelf.showThankYouPage), userInfo: nil, repeats: false)
                }
            }
        }
        
        let navigationController = MmNavigationController()
        navigationController.viewControllers = [checkoutViewController]
        navigationController.modalPresentationStyle = .overFullScreen
        
        self.present(navigationController, animated: false, completion: nil)
    }
    
    // MARK: Flash Sales
    
    private var isShowFlashSale = false
    private func promptFlashSaleSuggestion(_ sku: Sku?) {
        guard let sku = sku else {
            return
        }
        
        //已经提示过，不再提示
        if isShowFlashSale {
            return
        }
        
        isShowFlashSale = true
        if let colorIndex = self.style.validColorList.index(where: { (color) -> Bool in
            return color.colorKey == sku.colorKey
        }) {
            let indexPathColor = style.validColorList[colorIndex]
            
            let filteredColorImageList = style.colorImageList.filter({ $0.colorKey == indexPathColor.colorKey })
            
            var imageKey = ""
            var imageListIsEmpty = false
            if filteredColorImageList.isEmpty {
                imageListIsEmpty = true
                imageKey = indexPathColor.colorImage
            } else {
                imageListIsEmpty = false
                imageKey = filteredColorImageList[0].imageKey
            }
            
            PopManager.sharedInstance.flashSale(imageListIsEmpty:imageListIsEmpty,imageKey: imageKey, sku: sku, brandCallback: {
                
            }) {
                self.selectedSku(sku: sku)
                self.reloadAllData()
            }
        }
        
    }
    
    private func checkUserEligible(_ sku: Sku? = nil, block: (() -> Void)? = nil /* sku from skuList*/) {
        let completion = {
            if let s = sku {
                //只要不等于默认选中的sku,则需要提示出来
                if let selected = self.selectedSku, selected.skuId != s.skuId {
                    self.promptFlashSaleSuggestion(sku)
                } else {
                    self.reloadAllData()
                }
            } else /*assume from default sku*/ {
                self.reloadAllData()
            }
            
            if block != nil {
                block?()
            }
        }
        if LoginManager.isValidUser() {
            UserService.orderstatus { [weak self] (response) in
                if response.result.isSuccess {
                    if response.response?.statusCode == 200, let strongSelf = self {
                        if let orderStatus = Mapper<UserOrderStatus>().map(JSONObject: response.result.value) {
                            strongSelf.isFlashSaleEligible = orderStatus.isFlashSaleEligible
                            if strongSelf.isFlashSaleEligible {
                                completion()
                            }
                        }
                    }
                }
            }
        } else {
            self.isFlashSaleEligible = true //未登录，有
            //directly show discount price
            completion()
        }
    }
    
    private func initDefaultSelectedSku() {
        if selectedSku != nil {
            return
        }
        //根据deeplink跳转过来优先显示对应的sku [此逻辑暂时未要求]
        let skuColor = self.style.findSkuColorFromColorKey(selectedColorKey)
        if let sku = self.style.searchValidSku(selectedSizeId, colorId: selectedColorId, skuColor: skuColor) {
            selectedSku(sku:sku)
        } else if let sku = self.style.defaultSku() {
            selectedSku(sku:sku)
        }
    }
    
    private func checkStyleContainFlashSale() {
        //先切换到一个选中的sku,
        if selectedSku == nil {
            initDefaultSelectedSku()
        }
        
        if let sku = self.style.getFlashSaleSku() {
            checkUserEligible(sku)
        }
    }
    
    private func selectedSku(sku:Sku) {
        //首次设置，不一定以default为主，因为可能无效
        if let colorIndex = self.style.validColorList.index(where: { (color) -> Bool in
            return color.colorId == sku.colorId && color.colorKey == sku.colorKey
        }) {
            self.colorIndexSelected = colorIndex
        }
        
        if let sizeIndex = self.style.validSizeList.index(where: { (size) -> Bool in
            return size.sizeId == sku.sizeId
        }) {
            self.sizeIndexSelected = sizeIndex
        }
        self.selectedSizeId = sku.sizeId
        self.selectedColorId = sku.colorId
        self.selectedColorKey = sku.colorKey
        self.selectedSku = sku
    }
    
    // MARK: Like Count Action
    
    func actionLike(_ sender:UICollectionViewCell? = nil){
        checkFlashSaleReload(block:{
            self.privateActionLike(sender)
        })
    }
    
    private func privateActionLike(_ sender:UICollectionViewCell? = nil) {
        if LoginManager.getLoginState() != .validUser {
            LoginManager.goToLogin {
                self.privateActionLike(sender)
            }
            return
        }
        
        if (self.style.isWished()){
            self.view.recordAction(.Tap, sourceRef: "Wishlist-Remove", sourceType: .Button, targetRef: style.styleCode, targetType: .Product)
            
            let cartItemId = CacheManager.sharedManager.cartItemIdForStyle(style)
            firstly {
                return self.removeWishlistItem(cartItemId)
                }.always {
                    
                    if let cell = sender as? StyleNameAndCollectCell {
                        cell.setLike(false)
                    } else {
                        self.reloadAllData()
                    }
                    
                    self.bottomView.setLike(false)
                }.catch { _ -> Void in
                    Log.error("error")
            }
        } else {
            self.view.recordAction(.Tap, sourceRef: "Wishlist-Add", sourceType: .Button, targetRef: style.styleCode, targetType: .Product)
            if let cell = sender as? StyleNameAndCollectCell {
                cell.setLike(true)
            }
            
            self.bottomView.setLike(true)
            
            firstly {
                return self.addWishlistItem(style.merchantId, skuId: style.defaultSkuId(), isSpecificSku: false, referrer: self.referrerUserKey)
                }.always {
                    self.reloadAllData()
            }
        }
    }
    
    @objc func likeTapped(sender: UITapGestureRecognizer) {
        if let view = sender.view{
            self.handleWishlistAction(tappedView: view)
        }
        
    }
    
    func handleWishlistAction(tappedView: UIView){
        checkFlashSaleReload(block: {
            self.privateHandleWishlistAction(tappedView: tappedView)
        })
    }
    
    private func privateHandleWishlistAction(tappedView: UIView){
        if LoginManager.getLoginState() != .validUser {
            LoginManager.goToLogin {
                self.privateHandleWishlistAction(tappedView: tappedView)
            }
            return
        }
        
        if !style.isValid() {
            return
        }
        
        let point: CGPoint = tappedView.convert(CGPoint.zero, to: self.suggestColectionView)
        var indexPath = self.suggestColectionView?.indexPathForItem(at: point)
        var aStyle: Style?
        var isSuggestionStyle = false
        
        if indexPath?.section != nil && indexPath?.row != nil {
            if (self.syteStyles.indices.contains(indexPath!.row)){
                aStyle = self.syteStyles[indexPath!.row]
                isSuggestionStyle = true
            }

            
        } else {
            let point: CGPoint = tappedView.convert(CGPoint.zero, to: self.collectionView)
            indexPath = self.collectionView!.indexPathForItem(at: point)
            
            if indexPath?.section != nil && indexPath?.row != nil {
                aStyle = self.style
            }
        }
        
        if let style = aStyle {
            if let _ = tappedView.analyticsViewKey {
                let sourceRef = style.isWished() ? "Wishlist-Remove" : "Wishlist-Add"
                tappedView.recordAction(.Tap, sourceRef: sourceRef, sourceType: .Button, targetRef: "\(style.styleCode)", targetType: .Product)
            } else {
                ErrorLogManager.sharedManager.recordNonFatalError(withException: .NullPointer)
            }
            
            if style.isWished() {
                if let heartImage = tappedView as? UIImageView {
                    main_async {
                        heartImage.image = UIImage(named: "ic_grey_star_plp")
                    }
                    
                } else {
                    ErrorLogManager.sharedManager.recordNonFatalError(withException: .NullPointer)
                }
                
                let cartItemId = CacheManager.sharedManager.cartItemIdForStyle(style)
                
                
                firstly {
                    return self.removeWishlistItem(cartItemId)
                    }.always {
                        self.reloadAllData()
                        self.updateButtonWishlistState()
                    }.catch { _ -> Void in
                        Log.error("error")
                }
            } else {
                var isServiceDone = false
                var isAnimationDone = false
                
                if let heartImage = tappedView as? UIImageView {
                    main_async {
                        heartImage.image = UIImage(named: "ic_red_star_plp")
                        let wishListAnimation = WishListAnimation(heartImage: heartImage, redDotButton: self.buttonWishlist)
                        wishListAnimation.setAnimationImage(heartImage.image)
                        wishListAnimation.showAnimation(completion: { [weak self] in
                            if let strongSelf = self {
                                isAnimationDone = true
                                
                                if isServiceDone {
                                    strongSelf.reloadAllData()
                                    strongSelf.updateButtonWishlistState()
                                }
                            } else {
                                ErrorLogManager.sharedManager.recordNonFatalError(withException: .NullPointer)
                            }
                            
                        })
                    }
                } else {
                    ErrorLogManager.sharedManager.recordNonFatalError(withException: .NullPointer)
                }
                
                var isSpecificSku = false
                
                if !isSuggestionStyle && sizeIndexSelected != -1 && colorIndexSelected != -1 {
                    isSpecificSku = true
                }
                
                firstly {
                    return self.addWishlistItem(style.merchantId, skuId: style.defaultSkuId(), isSpecificSku: isSpecificSku, referrer: self.referrerUserKey)
                    }.always {
                        isServiceDone = true
                        if isAnimationDone {
                            self.reloadAllData()
                            self.updateButtonWishlistState()
                        }
                    }.catch { _ -> Void in
                        Log.error("error")
                }
            }
        } else {
            ErrorLogManager.sharedManager.recordNonFatalError(withException: .NullPointer)
        }
    }
    
    func showAddToCartAnimation() {
        if let redDotButton = buttonCart {
            var productImage: UIImage? = nil
            
            if let image = currentImage{
                productImage = image
            } else {
                ErrorLogManager.sharedManager.recordNonFatalError(withException: .NullPointer)
            }
            
            if let productImage = productImage {
                if let view = UIApplication.shared.windows.first {
                    let animation = CheckoutAnimation(
                        itemImage: productImage,
                        itemSize: CGSize(width: ColorCellDimension, height: ColorCellDimension),
                        itemStartPos: bottomView.convert(bottomView.buyFlashSaleButton.center, to: view),
                        redDotButton: redDotButton
                    )
                    animation.PDPCartAnimation = true
                    view.addSubview(animation)
                    animation.showAnimation()
                } else {
                    ErrorLogManager.sharedManager.recordNonFatalError(withException: .DataIsEmpty)
                }
            } else {
                ErrorLogManager.sharedManager.recordNonFatalError(withException: .NullPointer)
            }
        }
    }
    
    func getStyleFromTappedView(tappedView: UIView) -> Style?{
        let point: CGPoint = tappedView.convert(CGPoint.zero, to: self.suggestColectionView)
        var indexPath = self.suggestColectionView?.indexPathForItem(at: point)
        var tappedStyle: Style?
        
        if let _ = indexPath?.section, let row = indexPath?.row{
            tappedStyle = self.syteStyles[row]
            
        } else {
            let point: CGPoint = tappedView.convert(CGPoint.zero, to: self.collectionView)
            indexPath = self.collectionView?.indexPathForItem(at: point)
            
            if let _ = indexPath?.section, let _ = indexPath?.row{
                tappedStyle = self.style
            }
        }
        
        return tappedStyle
    }
    // MARK: Scroll View Method to control page control
    
    func scrollViewDidEndDecelerating(_ scrollView: UIScrollView) {
        
        if let featureCollectionView = self.featureCollectionView {
            if scrollView == featureCollectionView {
                let scrollFromPage = currentPage
                currentPage = Int(featureCollectionView.contentOffset.x / featureCollectionView.width)
                if let cell = featureCollectionView.cellForItem(at: IndexPath(item: currentPage, section: 0)) as? FeatureCollectionCell {
                    cell.recordAction(.Slide, sourceRef: "\(scrollFromPage + 1)", sourceType: .HeroImage, targetRef: "\(currentPage + 1)", targetType: .HeroImage)
                } else {
                    ErrorLogManager.sharedManager.recordNonFatalError(withException: .NullPointerOrTypeMismatch)
                }
                
                if let productImagePageControl = productImagePageControl {
                    productImagePageControl.currentPage = currentPage
                } else {
                    ErrorLogManager.sharedManager.recordNonFatalError(withException: .NullPointer)
                }
            }
            else if scrollView == suggestColectionView{
                scrollView.recordAction(.Slide, sourceRef: style.styleCode, sourceType: .Product, targetRef: "MoreNewProduct", targetType: .View)
            }
        } else {
            ErrorLogManager.sharedManager.recordNonFatalError(withException: .NullPointer)
        }
    }
    
    func createButtonBar(imageName: String, selectorName: Selector, size:CGSize,left: CGFloat, right: CGFloat) -> UIBarButtonItem {
        let button: UIButton = UIButton()
        button.setImage(UIImage(named: imageName), for: .normal)
        button.frame = CGRect(x:0, y: 0, width: size.width, height: size.height)
        button.contentEdgeInsets = UIEdgeInsets.init(top: 0, left: left, bottom: 0, right: right)
        button.addTarget(self, action: selectorName, for: .touchUpInside)
        
        let temp:UIBarButtonItem = UIBarButtonItem()
        temp.customView = button
        
        return temp
    }
    
    func setupNavigationBarButtons() {
        setupNavigationBarCartButton()
        setupNavigationBarWishlistButton()
        
        var rightButtonItems = [UIBarButtonItem]()
        rightButtonItems.append(UIBarButtonItem(customView: buttonCart!))
        //rightButtonItems.append(UIBarButtonItem(customView: buttonWishlist!))
        
        if let shoppingCartButton = self.buttonCart {
            shoppingCartButton.analyticsViewKey = analyticsViewRecord.viewKey
            shoppingCartButton.addTarget(self, action: #selector(self.goToShoppingCart), for: .touchUpInside)
        } else {
            ErrorLogManager.sharedManager.recordNonFatalError(withException: .NullPointer)
        }
        
        if let wishListButton = self.buttonWishlist {
            wishListButton.analyticsViewKey = analyticsViewRecord.viewKey
            wishListButton.addTarget(self, action: #selector(self.goToWishList), for: .touchUpInside)
        } else {
            ErrorLogManager.sharedManager.recordNonFatalError(withException: .NullPointer)
        }
        

        self.navigationItem.rightBarButtonItems = [UIBarButtonItem(customView: shareButton)]
        
        self.navigationItem.leftBarButtonItems = [UIBarButtonItem(customView: backButton)]
    }
    
    func setupNavigationBarTitle() {
        tapGesture = UITapGestureRecognizer(target: self, action: #selector(self.openMerchantProfile))
        
        if let navigationBar = self.navigationController?.navigationBar {
            let titleViewSize = CGSize(width: navigationBar.size.width / 3, height: navigationBar.size.height / 2 + UIApplication.shared.statusBarFrame.size.height + 5)
            viewImageTile.frame = CGRect(x:navigationBar.frame.size.width / 2 - titleViewSize.width / 2, y: 0, width: titleViewSize.width, height: titleViewSize.height - 12)
            viewImageTile.backgroundColor = UIColor.clear
            viewImageTile.isUserInteractionEnabled = true
            viewImageTile.analyticsViewKey = analyticsViewRecord.viewKey
            
            if let tapGesture = tapGesture {
                viewImageTile.addGestureRecognizer(tapGesture)
            } else {
                ErrorLogManager.sharedManager.recordNonFatalError(withException: .NullPointer)
            }
            let label = UILabel()
            label.text = style.brandName
            label.frame = CGRect(x:navigationBar.frame.size.width / 2 - titleViewSize.width / 2, y: 0, width: titleViewSize.width, height: titleViewSize.height - 12)
            label.alpha = 0
            label.isUserInteractionEnabled = true
            label.textAlignment = .center
            if let tapGesture = tapGesture {
                label.addGestureRecognizer(tapGesture)
            } else {
                ErrorLogManager.sharedManager.recordNonFatalError(withException: .NullPointer)
            }
            self.navigationItem.titleView = label
            self.setViewImageTilte()
            self.setAccessibilityIdForView("UIBT_MERCHANT", view: viewImageTile)

        } else {
            self.title = String.localize("LB_DETAILS")
        }
    }
    
    func setViewImageTilte() {
        if let merchant = self.merchant {
            viewImageTile.mm_setImageWithURL(ImageURLFactory.getRaw(merchant.headerLogoImage, category: .merchant, width: ResizerSize.size256.rawValue), placeholderImage: UIImage(named: "spacer"), clipsToBounds: false, contentMode: UIViewContentMode.scaleAspectFit, progress: nil, optionsInfo: nil, completion: { (image, error, cacheType, imageURL) in
                if error == nil {
                    self.title = ""
                }
            })
        } else {
            ErrorLogManager.sharedManager.recordNonFatalError(withException: .NullPointer)
        }
    }
    
    func getSuggestionCellWidth() -> CGFloat {
        return (view.width / 2) - 22.5
    }
    
    @objc func openMerchantProfile(sender: UITapGestureRecognizer) {
        if let view = sender.view, let merchantId = merchant?.merchantId {
            view.recordAction(.Tap, sourceRef: "\(merchantId)", sourceType: .Merchant, targetRef: "MPP", targetType: .View)
        } else {
            ErrorLogManager.sharedManager.recordNonFatalError(withException: .NullPointer)
        }
        
//        if let merchant = merchant {
//            Navigator.shared.dopen(Navigator.mymm.website_merchant_merchantId + "\(merchant.merchantId)")
//        } else {
//            ErrorLogManager.sharedManager.recordNonFatalError(withException: .NullPointer)
//        }
        let link = Navigator.mymm.website_brand_brandId + String(style.brandId)
        Navigator.shared.dopen(link)

    }
    
    func openBrandProfile(sender: UICollectionViewCell) {
        sender.recordAction(.Tap, sourceRef: "\(style.brandId)", sourceType: .Brand, targetRef: "BPP", targetType: .View)
        
        let brand = Brand()
        brand.brandId = style.brandId
        
        let brandViewController = BrandViewController()
        brandViewController.brand = brand
        self.navigationController?.pushViewController(brandViewController, animated: true)
    }
    
    func openProductLikeUserListPage() {
        let productLikeUserListViewController = ProductLikeUserListViewController()
        productLikeUserListViewController.productLikeList = self.productLikeList
        self.navigationController?.pushViewController(productLikeUserListViewController, animated: true)
    }

    override func collectionViewBottomPadding() -> CGFloat {
        return SwipeViewHeight
    }
    
    func popupImageViewer(imageKeyList: [String], index: Int) {
        var images = [SKPhoto]()
        
        for imageKey in imageKeyList {
            let url = ImageURLFactory.URLSize1000(imageKey, category: .product).absoluteString
            let photo = SKPhoto.photoWithImageURL(url)
            photo.shouldCachePhotoURLImage = true
            images.append(photo)
        }
        
        guard images.count >= imageKeyList.count else {
            return
        }
        
        skPhotoBrowser = SKPhotoBrowser(photos: images)
        if let browser = skPhotoBrowser {
            let initialIndex = index
            browser.initializePageIndex(initialIndex)
            self.navigationController?.present(browser, animated: true, completion: { [weak self] () -> Void in
                if let strongSelf = self {
                    let longPress = UILongPressGestureRecognizer(target: strongSelf, action: #selector(StyleViewController.handleLongPressOnProductImage))
                    browser.view.addGestureRecognizer(longPress)
                }
            })
        }
    }
    
    func isCircular() -> Bool {
        return false
    }
    
    // MARK: - Image height calculation
    
    func frameImageAspectFitForImage(image: UIImage, imageView: UIImageView) -> CGRect {
        // Support Portrait not support Landscape
        // Do the landscape mode in the future if needed
        
        let imageRatio = imageView.size.width / image.size.width
        
        return CGRect(x:0, y: 0, width: image.size.width * imageRatio, height: image.size.height * imageRatio)
    }
    
    // MARK: - handle data
    
    func updateMerchantLogo(merchantId: Int){
        firstly {
            return self.fetchMerchant(merchantId: merchantId)
            }.then { _ -> Void in
                
            }.catch { _ -> Void in
                Log.error("error")
        }
    }
    
    func fetchMerchant(merchantId: Int) -> Promise<Any>{
        return Promise{ fulfill, reject in
            MerchantService.view(merchantId) { [weak self] (response) in
                if let strongSelf = self {
                    strongSelf.fetchedMerchant = true
                    
                    if response.result.isSuccess {
                        if response.response?.statusCode == 200 {
                            if let array = response.result.value as? [[String: Any]], let obj = array.first, let merchant = Mapper<Merchant>().map(JSONObject: obj) {
                                strongSelf.merchant = merchant
                                strongSelf.setViewImageTilte()
                                strongSelf.setupNavigationBarTitle()
                                fulfill("OK")
                            } else {
                                ErrorLogManager.sharedManager.recordNonFatalError(withException: .FailToParseAPIResponse)
                                
                                let error = NSError(domain: "", code: -999, userInfo: nil)
                                reject(error)
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
                        reject(response.result.error ?? NSError(domain: "", code: 0, userInfo: nil))
                    }
                } else {
                    ErrorLogManager.sharedManager.recordNonFatalError(withException: .NullPointer)
                }
            }
        }
    }
    
    @objc func showThankYouPage() {
        stopLoading()
        
        let thankYouViewController = ThankYouViewController()
        thankYouViewController.fromViewController = self
        thankYouViewController.parentOrder = paidOrder
        let navigationController = MmNavigationController(rootViewController: thankYouViewController)
        navigationController.modalPresentationStyle = .overFullScreen
        thankYouViewController.handleDismiss = {
        }
        self.present(navigationController, animated: true, completion: nil)
    }
    
    // MARK: - Get recommended Products
    
    func fetchProductList(pageNumber: Int) {

        
        self.syteData(merchantId: 0, pageNo: pageNumber)
        
//        firstly {
//            return self.searchRecommendedProducts(merchantId: self.style.merchantId, pageNo: pageNumber)
//            }.then { _ -> Void in
//
//            }.always {
//
//
//            }.catch { _ -> Void in
//                Log.error("error")
//        }
        if isFetchingSuggestedProducts{
            return
        }
        
        isFetchingSuggestedProducts = true
    }
    
    func loadMoreProductList(){
        let isCanLoadMore = pageNo == 1 || (pageNo < pageTotal)
        if isCanLoadMore{
            fetchProductList(pageNumber: pageNo + 1)
        }
    }
    
    func syteData(merchantId: Int, pageNo: Int)  {
        SingnRecommendService.searchRecommendedProducts(skuid: self.style.defaultSkuId(),
                                                        merchantId: self.style.merchantId,
                                                        pagesize: 6,
                                                        pageno: self.pageNo,
                                                        syteLoaded:syteLoaded,
                                                        dataCount:self.syteStyles.count,
                                                        success: { (response) in
            self.collectionView.mj_footer.endRefreshing()
            if let pageData = response.pageData,pageData.count > 0 {
                if response.containedSyte {
                    self.syteLoaded = true
                }
                self.pageNo = self.pageNo + 1
                self.syteStyles = self.syteStyles + pageData
                self.collectionView.reloadData()
                self.isFetchingSuggestedProducts = false
                self.suggestColectionView?.reloadData()
            }
        }) { (erro) -> Bool in
            self.collectionView.mj_footer.endRefreshing()
            return true
        }
    }
    
    
    /**
     get recommmended products
     
     - parameter merchantId: merchantid
     - parameter pageNo:     1
     - parameter pageSize:   30
     
     - returns: get styles
     */
    func searchRecommendedProducts(merchantId: Int, pageNo: Int) -> Promise<Any> {
        return Promise{ fulfill, reject in
            SearchService.searchRecommendedProducts(merchantId, pageNo: pageNo, completion: { [weak self] (response) in
                if let strongSelf = self {
                    if response.result.isSuccess {
                        if let styleResponse = Mapper<SearchResponse>().map(JSONObject: response.result.value) {
                            strongSelf.pageNo = pageNo
                            strongSelf.pageTotal = styleResponse.pageTotal
                            if let styles = styleResponse.pageData {
                                let availableStyles = styles.filter({ !$0.isOutOfStock() && $0.isValid() })
                                
                                if availableStyles.count > 0 {
                                    if pageNo == 1 {
                                        strongSelf.suggestStyles = availableStyles
                                    } else {
                                        strongSelf.suggestStyles.append(contentsOf: availableStyles)
                                    }
                                } else {
                                    if pageNo == 1 {
                                        strongSelf.suggestStyles = []
                                    }
                                }
                                
                            } else {
                                ErrorLogManager.sharedManager.recordNonFatalError(withException: .NullPointer)
                                
                                strongSelf.suggestStyles = []
                            }
                        } else {
                            ErrorLogManager.sharedManager.recordNonFatalError(withException: .FailToParseAPIResponse)
                        }
                        fulfill("OK")
                    } else {
                        reject(response.result.error ?? NSError(domain: "", code: 0, userInfo: nil))
                    }
                } else {
                    ErrorLogManager.sharedManager.recordNonFatalError(withException: .NullPointer)
                }
            })
        }
    }
    
    func getLikesProduct(style: Style) -> Promise<Any> {
        return Promise{ fulfill, reject in
            SearchService.getLikesProduct(styleIDs: ["\(style.styleId)"], completion:  { [weak self] (response) in
                if let strongSelf = self {
                    if response.result.isSuccess {
                        if let productLikes = Mapper<ProductLike>().mapArray(JSONObject: response.result.value) {
                            if productLikes.count > 0 {
                                strongSelf.productLikeList = productLikes.first!.likeList
                            }
                        } else {
                            ErrorLogManager.sharedManager.recordNonFatalError(withException: .FailToParseAPIResponse)
                        }
                        
                        fulfill("OK")
                    } else {
                        reject(response.result.error!)
                    }
                } else {
                    ErrorLogManager.sharedManager.recordNonFatalError(withException: .NullPointer)
                }
            })
        }
    }

    //MARK:- StyleCouponDelegate
    func clickOnCoupon(_ coupon: Coupon, cell: StyleCouponCell, claimCompletion: (() -> Void)?) {
        guard LoginManager.getLoginState() == .validUser, !coupon.isClaimed else { return }
        CouponService.claimCoupon(coupon.couponReference, merchantId: coupon.merchantId ?? self.style.merchantId, complete: { [weak self] (response) in
            if let strongSelf = self {
                if response.result.isSuccess && response.response?.statusCode == 200 {
                    coupon.isClaimed = true
                    CacheManager.sharedManager.hasNewClaimedCoupon = true
                    CouponManager.shareManager().invalidate(wallet: CouponMerchant.combine.rawValue)
                    CouponManager.shareManager().invalidate(wallet: coupon.merchantId ?? strongSelf.style.merchantId)
                    strongSelf.showSuccessPopupWithText(String.localize("LB_CA_COUPON_CLAIMED_SUC"))
                    strongSelf.reloadAllData()
                }
            }
        })
    }
//    func viewAllCoupon() {
//        Navigator.shared.dopen(Navigator.mymm.website_coupon_center + "\(self.style.merchantId)")
//        let targetRef = String(self.style.merchantId)
//        self.view.recordAction(.Tap, sourceRef: "MoreCoupon", sourceType: .Link, targetRef: targetRef, targetType: .PDP)
//    }
//
 
    
    // MARK: - Rating Header View Delegate
    
    func didSelectReviewHeader() {
        let productReviewViewController = ProductReviewViewController()
        productReviewViewController.summaryReview = self.summaryReview
        
        self.navigationController?.pushViewController(productReviewViewController, animated: true)
    }
    
    // MARK: - Handle Long Press Gesture on Product Image
    @objc func handleLongPressOnProductImage(gesture: UILongPressGestureRecognizer) -> Void {
        if gesture.state == UIGestureRecognizerState.began {
            
            let alertView = UIAlertView(title: "", message: "保存图片", delegate: self, cancelButtonTitle: String.localize("LB_CANCEL"), otherButtonTitles: String.localize("LB_SAVE"))
            alertView.show()
        }
    }
    
    // MARK: Take Screenshot to share item
    // Can we trim down this fat view controller...
    
    @objc func didReceiveScreenCapNotification(notification: NSNotification){
        
        if inactiveProductView.isHidden {
            self.presentShareSheet(triggerByScreenCap: true)
        }
    }
    
    // MARK: Handle no network connection
    
    func checkNetworkConnection() -> Bool{
        self.dismissNoConnectionView()
        
        let isNetworkAvailable = self.checkNetworkConnection(true, reloadHandler: { [weak self] in
            if let strongSelf = self{
                strongSelf.loadData()
            } else {
                ErrorLogManager.sharedManager.recordNonFatalError(withException: .NullPointer)
            }
            
            },completion: {
        })
        if(!isNetworkAvailable){
            bottomView.setEnable(false)
            //self.enableSwipeViewContainer(false)
        }
        //        self.enableSwipeViewContainer(isNetworkAvailable)
        return isNetworkAvailable
    }
}

extension StyleViewController: RatingUserCellDelegate {
    func didTapOnUser(_ userName: String) {
        DeepLinkManager.sharedManager.pushPublicProfile(viewController: self, userName: userName)
    }
}

extension StyleViewController: AfterSalesViewProtocol {
    
    func didSubmitReportReview(_ isSuccess: Bool) {
        if isSuccess {
            self.showSuccessPopupWithText(String.localize("LB_CA_REPORT_REVIEW_SUCCESS"))
        }
    }
    
    func didCancelOrder(_ isSuccess: Bool, orderItem: OrderItem?, orderCancel: OrderCancel?) {
        
    }
    
    func didDisputeOrder(_ isSuccess: Bool, orderItem: OrderItem?, orderReturn: OrderReturn?) {
        
    }
    
    func didReturnOrder(_ isSuccess: Bool, orderItem: OrderItem?, orderReturn: OrderReturn?) {
        
    }
}

extension StyleViewController : PinterestLayoutDelegate {
    @objc func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, sizeForItemAtIndexPath indexPath: IndexPath) -> CGSize {
        
        switch getCollectionType(collectionView) {
        case .RootCollection:
            guard self.sectionList.indices.contains(indexPath.section) else {
                ErrorLogManager.sharedManager.recordNonFatalError(withException: .IndexOutOfBounds)
                return CGSize(width: view.width, height: 0)
            }
            let sectionType = self.sectionList[indexPath.section]
            
            switch (sectionType){
            case .ProductImageSection:
                return CGSize(width: view.width, height: view.width * Constants.Ratio.ProductImageHeight)
            case .FlashSaleSection:
                return CGSize(width: view.width, height: 48)
            case .BrandNameSection:
                var isCrossBorder = false
                
                if let merchant = merchant {
                    isCrossBorder = merchant.isCrossBorder
                } else {
                    ErrorLogManager.sharedManager.recordNonFatalError(withException: .NullPointer)
                }
                var price = ""
                let (salePrice, retailPrice) = self.getPriceBySelectedSku()
                if style.getRangePrice().length > 0 { // 防止售罄之后没有价格的高度
                    price = style.getRangePrice()
                } else {
                    price = String(salePrice) + String(retailPrice)
                }
                return BrandNameCell.getSizeCell(productName: style.skuName, brandName: style.brandName, price: price, cellWidth: view.width, isCrossBorder: isCrossBorder, shippingThresold: getShipingThresold(),isFlashSaleDiscount: isFlashSaleDiscount)
            case .ColorListSection:
                return CGSize(width: ColorCellDimension, height: ColorCellDimension + UserCellLineSpacing)
            case .SizeListSection:
                let size = self.style.validSizeList[indexPath.row]
                return CGSize(width: SizeCollectionCell.getWidth(size.sizeName), height: SizeCollectionCell.DefaultHeight)
            case .MerchantSection:
                return CGSize(width: view.width, height: OrderMerchantCell.DefaultHeight)
            case .StylePriceSection:
                return CGSize(width: view.width, height: StylePriceCell.CellHeight)
            case .StyleRealPriceSection:
                return CGSize(width: view.width, height: StyleRealPriceCell.CellHeight)
            case .StyleGetPriceSection:
                return CGSize(width: view.width, height: StyleTagAndGetPriceCell.CellHeight)
            case .StyleTipGetPriceSection:
                return CGSize(width: view.width, height: StyleTipCell.CellHeight)
            case .StyleNameSection:
                return CGSize(width: view.width, height: StyleNameAndCollectCell.CellHeight)
            case .StyleBrandSection:
                return CGSize(width: view.width, height: StyleBrandCell.CellHeight)
            case .MarginSection:
                return CGSize(width: view.width, height: 8)
            case .CouponSection:
                return CGSize(width: view.width, height: StyleCouponCell.CellHeight)
            case .ReviewSection:
                let reviewRow = getReviewRow(atIndex: indexPath.row)
                switch reviewRow {
                case .UserReviewRow:
                    if let summaryReview = self.summaryReview {
                        if let skuReview = summaryReview.skuReview {
                            return RatingUserCell.getCellSize(text: skuReview.description, cellWidth: view.width)
                        }
                        return CGSize.zero
                    }
                    return CGSize.zero
                case .ImagesReviewRow:
                    return CGSize(width: view.frame.width, height: view.frame.width / 3.9)
                case .DescriptionReviewRow:
                    if let summaryReview = self.summaryReview {
                        if let skuReview = summaryReview.skuReview {
                            return PlainTextCell.getSizeCell(text: skuReview.replyDescription, cellWidth: view.width)
                        }
                    }
                    return CGSize.zero
                default:
                    return CGSize.zero
                }
            case .UserListSection:
                return CGSize(width: view.width, height: UserCellHeight + UserCell.TopBorderViewHeight)
            case .RecommendSection:
                return CGSize(width: view.width, height: RecommendCellHeight)
            case .DescriptionSection:
                var heightDescription = DescCell.getHeight(self.style.skuDesc, width: self.view.width)
                if heightDescription > 0 {
                    heightDescription = heightDescription + HeightTopDescriptionBorder
                }
                return CGSize(width: view.width, height: heightDescription)
            case .ImageListSection:
                if (self.style.descriptionImageList.indices.contains(indexPath.row)){
                    let imageKey: String = self.style.descriptionImageList[indexPath.row].imageKey
                    if let imageHeight = self.sectionImageListHeight[imageKey] {
                        return CGSize(width: view.width, height: imageHeight)
                    } else {
                        ErrorLogManager.sharedManager.recordNonFatalError(withException: .NullPointer)
                    }
                }
                return CGSize(width: view.width, height: view.width * Constants.Ratio.ProductImageHeight)
            case .OutfitSection:
                return CGSize(width: view.width, height: 723 * view.width / 375 )
            case .SuggestSection:
                let width = self.getSuggestionCellWidth()
                if self.syteStyles.count > indexPath.row {
                    let style = self.syteStyles[indexPath.row]
                    return CGSize(width: width, height: self.skuCellTextHeight(style: style))
                }
                return CGSize(width: width, height: width + Constants.Value.ProductBottomViewHeight)
            case .LastestPostSection:
                var text = ""
                var userSourceName: String? = nil
                if postManager.currentPosts.indices.contains(indexPath.row) {
                    let post = postManager.currentPosts[indexPath.row]
                    userSourceName = post.userSource?.userName
                    text = post.postText
                }
                let height = SimpleFeedCollectionViewCell.getHeightForCell(text, userSourceName: userSourceName)
                return CGSize(width: (view.frame.width - PostManager.NewsFeedLineSpacing * 3) / 2, height: height)
            case .CrossBorderStatementSection:
                if let merchant = self.merchant {
                    if merchant.isCrossBorder {
                        return CGSize(width: view.width, height: CrossBorderStatementCell.getHeight(view.width))
                    }
                } else {
                    if fetchedMerchant {
                        // Merchant could be null if it is not fetched yet
                        ErrorLogManager.sharedManager.recordNonFatalError(withException: .NullPointer)
                    }
                }
                return CGSize(width: view.width, height: 0)
            }
        case .FeatureCollection:
            return CGSize(width: view.width, height: view.width * Constants.Ratio.ProductImageHeight)
        case .UserCollection:
            return CGSize(width: UserCellWidth, height: UserCellHeight)
        default:
            return CGSize(width: view.width, height: 40)
        }
    }
    
    @objc func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, insetForSectionAtSection section: Int) -> UIEdgeInsets {
        switch getCollectionType(collectionView) {
        case .RootCollection:
            let isIndexValid = sectionList.indices.contains(section)
            if (!isIndexValid) { return UIEdgeInsets.zero }
            
            let sectionType: SectionType = self.sectionList[section]
            switch sectionType {
            case .LastestPostSection:
                return UIEdgeInsets(top: PostManager.NewsFeedLineSpacing, left: PostManager.NewsFeedLineSpacing, bottom: 25, right:PostManager.NewsFeedLineSpacing)
            case .ColorListSection:
                if self.style.validColorList.count > 0 {
                    return UIEdgeInsets(top: 0, left: 15 , bottom: 0, right: 15)
                }
            case .SizeListSection:
                if self.style.validSizeList.count > 0 {
                    return StyleViewController.SizeEdgeInsets
                }
            case .ReviewSection:
                if let summaryReview = self.summaryReview {
                    if let _ = summaryReview.skuReview {
                        return UIEdgeInsets(top: 0, left: 0, bottom: 20, right: 0)
                    }
                }
            case .ImageListSection:
                return UIEdgeInsets.zero
            case .SuggestSection:
                return UIEdgeInsets(top: 0, left: 15, bottom: 0, right: 15)
            default:
                break
            }
        case .UserCollection:
            let numberOfCells = CGFloat(self.collectionView(self.userCollectionView!, numberOfItemsInSection: 0))
            
            let totalLineSpacingCell = (numberOfCells - 1) * UserCellLineSpacing
            let totalWidthUserCell = (numberOfCells * UserCellWidth)
            let edgeInsets = (self.view.frame.size.width - totalWidthUserCell - totalLineSpacingCell) / 2;
            
            return UIEdgeInsets(top: 15, left: edgeInsets, bottom: 0, right: 0)
        default:
            break
        }
        
        return UIEdgeInsets.zero
    }
    
    func collectionView(_ collectionView: UICollectionView, numberOfColumnsInSection section: Int) -> Int {
        switch getCollectionType(collectionView) {
        case .RootCollection:
            let sectionType: SectionType = self.sectionList[section]
            switch sectionType {
            case .LastestPostSection, .SuggestSection:
                return 2
            case .FlashSaleSection:
                return 1
            default: break
            }
        default:
            break
        }
        
        return 0
    }
    
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, minimumLineSpacingForSectionAtIndex section: Int) -> CGFloat {
        switch getCollectionType(collectionView) {
        case .RootCollection:
            let sectionType:SectionType  = self.sectionList[section]
            switch sectionType {
            case .ImageListSection:
                return 0.0
            case .LastestPostSection:
                return PostManager.NewsFeedLineSpacing
            case .SizeListSection:
                return 0
            case .UserListSection:
                return 50.0
            case .SuggestSection:
                return 7.5
            default:
                break
            }
            
        case .UserCollection:
            return UserCellLineSpacing
        default:
            break
        }
        
        return 0.0
    }
    
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, minimumInteritemSpacingForSectionAtIndex section: Int) -> CGFloat {
        switch getCollectionType(collectionView) {
        case .RootCollection:
            if self.sectionList.indices.contains(section){
                let sectionType: SectionType = self.sectionList[section]
                switch sectionType {
                case .ColorListSection:
                    return ColorListSpacing;
                case .LastestPostSection:
                    return PostManager.NewsFeedLineSpacing
                case .SizeListSection:
                    return StyleViewController.SizeEdgeInsets.left
                default:
                    break
                }
            } else {
                ErrorLogManager.sharedManager.recordNonFatalError(withException: .IndexOutOfBounds)
            }
        default:
            break
        }
        
        return 0.0
    }
    
}

extension StyleViewController: UIAlertViewDelegate, HorizontalImageBucketCellDelegate {
    func ontap(imageBucketList: [ImageBucket], row: Int) {
        var images = [SKPhoto]()
        
        for imageKey in imageBucketList {
            let url = ImageURLFactory.URLSize1000(imageKey.imageKey, category: imageKey.imageCategory).absoluteString
            let photo = SKPhoto.photoWithImageURL(url)
            photo.shouldCachePhotoURLImage = true
            images.append(photo)
        }
        
        guard images.count >= imageBucketList.count else {
            return
        }
        
        skPhotoBrowser = SKPhotoBrowser(photos: images)
        if let browser = skPhotoBrowser {
            let initialIndex = index
            browser.initializePageIndex(initialIndex)
            self.navigationController?.present(browser, animated: true, completion: nil)
        }
    }
    
    func alertView(_ alertView: UIAlertView, clickedButtonAt buttonIndex: Int) {
        switch buttonIndex {
        case 1:
            if let browser = self.skPhotoBrowser, let image = browser.photoAtIndex(browser.currentPageIndex).underlyingImage {
                CustomAlbumHelper.saveImageToAlbum(image) { (success, error) in
                    if !success {
                        ErrorLogManager.sharedManager.recordNonFatalError(withException: .NullPointer)
                    }
                }
            }
            break
        default:
            break
        }
    }
}

extension StyleViewController: MMNavigationControllerDelegate {
    func preferredNavigationBarVisibility() -> MmFadeNavigationControllerNavigationBarVisibility? {
        return self.navigationBarVisibility
    }
}

internal class DetailCollectionViewFlowLayout : PinterestLayout {
    var sizeSection: Int = -1
    
    override func layoutAttributesForElements(in rect: CGRect) -> [UICollectionViewLayoutAttributes]? {
        let attributes = super.layoutAttributesForElements(in: rect)
        
        var leftMargin: CGFloat = StyleViewController.SizeEdgeInsets.left
        var maxY: CGFloat = -1.0
        
        attributes?.forEach { layoutAttribute in
            if layoutAttribute.indexPath.section == self.sizeSection && layoutAttribute.representedElementKind != UICollectionElementKindSectionHeader{
                if layoutAttribute.frame.origin.y >= maxY {
                    leftMargin = StyleViewController.SizeEdgeInsets.left
                }
                layoutAttribute.frame.origin.x = leftMargin
                
                leftMargin += layoutAttribute.frame.width + StyleViewController.SizeEdgeInsets.left
                maxY = max(layoutAttribute.frame.maxY , maxY)
            }
        }
        
        return attributes
    }
}


