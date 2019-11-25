//
//  ProductListViewController.swift
//  storefront-ios
//
//  Created by Leslie Zhang on 2018/5/17.
//  Copyright © 2018年 WWE & CO. All rights reserved.
//

import UIKit
import ObjectMapper
import PromiseKit
import MJRefresh

protocol ProductListViewControllerDelegate: NSObjectProtocol {
    func productListViewControllerScrollViewDidScroll(_ scrollView: UIScrollView)
}

protocol SearchProductViewDelegage: NSObjectProtocol{
    func getDataFromSearchProduct(_ style: Style)
}

class ProductListViewController: MMUICollectionCompatibilityController<MMCellModel>,FilterStyleDelegate,SearchProductViewDelegage {
    var number:Any?
    var viewWillAppearAction: (() -> Void)?
    var viewDidAppearAction: (() -> Void)?
    var pageNo = 1
    var isCreatingPost = false
    var isSearch = false // 为了调查询界面，非全局搜索
    var isEnableAutoCompleteSearch = true
    var isShowTabBarInSearchStyle = true
    
    var noNeedBrandFeed = false     //不需要插入相关品牌,MLP和BLP为true
    private var isPopAfterSelectFromSearch = true
    private var isViewTagAnalyticsEnabled = true
    fileprivate(set) var skuIds : String?
    private var originalStyleFilter: StyleFilter?
    fileprivate(set) var styleFilter = StyleFilter()
    var selectedFilterCategories: [Cat]? //Capture current selected categories to re-displaying
    var originalFilterCategories: [Cat]? //Capture original categories to filter if user
    var cats: [Cat] = []
    typealias WaitingFetchBrandsBlock = (([Brand]) -> ())
    var waitingFetchBrandsBlocks: [WaitingFetchBrandsBlock] = []
    var isFetchingBrands = false
    var brands = [Brand]()
    var aggregations: Aggregations?
    var originalAggregations: Aggregations?
    var sortList:[String] = ["DisplayRanking","LastCreated","LastCreated","PriceSort","PriceSort"]
    var orderList:[String] = ["desc","desc","asc","asc","desc"]
    var styles: [Style] = []
    var isLoadView = false
    weak var delegate:ProductListViewControllerDelegate?
    var merchantId: Int?
    var brandId: Int?
    var brand: Brand?
    var isSearchAllCategory = false
    var fromSearch:Bool = false
    var fromMerchant:Bool = false
    var searchFetchStylesBlock: ((String) -> Void)?
    var doSearchBlock: ((SearchStyleController) -> Void)?
    var searchProductHandler: ((_ chatModel: ChatModel) -> Void)?
    var listBrandMerchant: [Any] = []
    var insetBrandList = [Style]()
    private var endIndex = 0
    private let brandfewNumber = 6
    private let brandMarginNumber = 5
    private let navigationSearchHeight:CGFloat = 35
    private var isVideo = false
    private var needFloating: Bool {
        get {
            return self.table.contentSize.height - self.table.frame.size.height > 44
        }
    }
    private var isHeadViewFloating = false
    private var headViewCellContentView: UIView? {
        get {
            if let cellModel = self.fetchs.fetch[0] as? ProductListBandCellModel {
                return cellModel.superView
            }
            return nil
        }
    }
    private var headViewCloseButton: UIButton?
    weak var getStyleDelegate:SearchProductViewDelegage?
    
    func getDataFromSearchProduct(_ style: Style) {
        if let delegate = getStyleDelegate {
            delegate.getDataFromSearchProduct(style)
        } else {
            //PLP跳转商品详情
            if let defaultSku = style.defaultSku() {
                Navigator.shared.dopen(Navigator.mymm.website_product_skuId + String(defaultSku.skuId))
                if fromSearch {
                    if let sku = style.currentDefaultSku() {
                        BrowsingHistory.clickSearchHistory(keyword: styleFilter.queryString, skuId: sku.skuId, style: style)
                    }
                }
            }
        }

    }
    
    private var userStyleFilter = StyleFilter() // 持有筛选界面用户的选择条件,便于下次进入进行展示
    private final var isInsertSearchHistoryStyle: Bool = true // 是否需要插入历史点击记录(默认综合排序的情况之下)
    private final var searchHistoryStyle: Style? //记录获取到的style
    private final var preferredStyle: Style?
    private final var filterGenderType: MMFilterGenderType = .unKnow //品类性别的的记录值
    private final var recordQueryString: String = "" // 记录搜索的关键词
    private final var contentOffSetY: CGFloat = 0
    open var navigationBarVisibility: MmFadeNavigationControllerNavigationBarVisibility = .visible {
        didSet {
            UIApplication.shared.statusBarStyle = self.navigationBarVisibility == .visible ? .default : .lightContent
        }
    }
    open var preferredSkuIds: [Int]?
    
    //MARK: - life cycle
    override func viewWillAppear(_ animated: Bool) {
        if isViewTagAnalyticsEnabled {//提前填充好数据，super.viewWillAppear中会有页面进入的埋点
            self.initAnalyticsRecord()
        }
        
        super.viewWillAppear(animated)
        
        viewWillAppearAction?()
        
        if let _ = self.headView, let navigationController = self.navigationController as? MmNavigationController {
            if self.isVideo {
                updateTitleNavigation()
            }
            navigationController.setNavigationBarVisibility(offset: contentOffSetY)
        }
        
        let historires = Context.getHistory()
        if historires.count > 0 {
            searchButton.setTitle(historires.first, for: .normal)
        } else if let searchTerms = CacheManager.sharedManager.hotSearchTerms, searchTerms.count > 0 {
            searchButton.setTitle(searchTerms.first?.searchTerm, for: .normal)
        }
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        viewDidAppearAction?()
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        isLoadView = true
        
        self.title = ""
        
        table.backgroundColor = .white
        
        createStyleFilter()//从参数构建filter
        
        if let headView = headView {
            if #available(iOS 11.0, *) {
                table.contentInsetAdjustmentBehavior = UIScrollViewContentInsetAdjustmentBehavior.never
            } else {
                self.automaticallyAdjustsScrollViewInsets = false
            }
            fetchs.fetch.insert(ProductListBuilder.buiderHeadCellModel(headView,isVideo:self.isVideo), atIndex: 0)
            
            if self.isVideo {
                self.setupNavigationBarButton()
            } else {
                self.setupSearchBar()
                backButton.isSelected = true
            }
        } else {
            self.automaticallyAdjustsScrollViewInsets = true
            self.updateTitleNavigation()
            if let title = self.title, !title.isEmpty {
                setupNavigationBar()
            }else {
                setupSearchBar()
            }
        }
        
        if isSearch {
            doSearch()
        } else {
            if !fromSearch {
                if let _ = self.preferredSkuIds {
                    self.searchPreferredStyle { (style) in
                        self.preferredStyle = style
                        self.searchStyle(merchantId: self.merchantId)
                    }
                } else {
                    searchStyle(merchantId:merchantId)
                }
            }
        }
        
        view.addSubview(scrollToTopBtn)
    }
    
    private func setupNavigationBarButton() {
        let backButtonItem = UIBarButtonItem()
        backButton.isSelected = true
        backButtonItem.customView = backButton
        self.navigationItem.leftBarButtonItem = backButtonItem
    }
    
    override func loadFetchs() -> [MMFetch<MMCellModel>] {
        let list = [] as [MMCellModel]
        let f = MMFetchList(list:list)
        return [f]
    }
    
    deinit {
        print("ProductListViewControllerDeinit")
        
        guard let videoView = self.headView as? ProductListVideoView else {
            return
        }
        videoView.videoPlayAction = nil
        videoView.videoStopAction = nil
        videoView.fullScreenClickHandler = nil
        videoView.closeButtonClickHandler = nil
    }
    
    convenience init(_ str:String) {
        self.init(nibName: nil, bundle: nil)
    }
    
    //MARK: - service 
    public func reloadAll()  {
        self.insetBrandList.removeAll()
        self.pageNo = 1
        self.endIndex = 0
        searchSingleStyle {[weak self] (style) in
            if let strongSelf = self {
                strongSelf.searchHistoryStyle = style
                strongSelf.searchStyle(merchantId:strongSelf.merchantId)
            }
        }
        self.table.scrollRectToVisible(CGRect.init(x: 0, y: 0, width: 1, height: 1), animated: false)
    }
    
    @objc private func footerRefursh()  {
        searchStyle()
    }
    
    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        scrollToTopBtn.frame = CGRect(x: ScreenWidth - 60, y: self.view.height - 100, width: 48, height: 48)
    }
    
    private func buildSecondLevelCategory(completion: @escaping ([Cat]) -> Void){
        CacheManager.sharedManager.fetchAllCategories(completion: { [weak self] (cats, nextPage, error) in
            if let strongSelf = self {
                var level2Cats = [Cat]()
                for cat in cats ?? [] {
                    if let cats = cat.categoryList{
                        level2Cats.append(contentsOf: cats)
                    }
                }
                
                var filteredCats = level2Cats.filter{$0.categoryId != 0 && $0.categoryId != DiscoverCategoryViewController.AllCategory}
                
                if let strongAggregations = strongSelf.aggregations {
                    filteredCats = filteredCats.filter({(strongAggregations.categoryArray.contains($0.categoryId))})
                    for filteredCat in filteredCats {
                        filteredCat.categoryList = (filteredCat.categoryList ?? []).filter({(strongAggregations.categoryArray.contains($0.categoryId))})
                    }
                }
                completion(filteredCats)
            } else {
                completion([])
            }
        })
    }
    
    /// 在搜索条件下,获取用户最后一次点击 product of search's keyword
    ///
    /// - Parameter completion: block
    private func searchSingleStyle(completion:@escaping ((Style?) -> Void)) {
        if fromSearch {
            let selecteditem = BrowsingHistory.queryLatestBrowsingSkuBy(keyword:self.styleFilter.queryString)
            guard let item = selecteditem else { completion(nil); return }
            SearchService.searchStyleBySkuId(item.skuId) { (response) in
                if response.result.isSuccess {
                    if let result = Mapper<SearchResponse>().map(JSONObject: response.result.value), let pageData = result.pageData, let style = pageData.first {
                        if (style.isValid() && !style.isOutOfStock()) {
                            completion(style)
                            return
                        }
                    }
                }
                completion(nil)
            }
        } else {
            completion(nil)
        }
    }
    
    private func searchPreferredStyle(completion: @escaping ((Style?) -> Void)) {
        if let ids = self.preferredSkuIds, ids.count > 0 {
//            SearchService.searchStyleBySkuId(ids[0] /*for just one sku in 5.6 version */) { (response) in
//                if response.result.isSuccess {
//                    if let result = Mapper<SearchResponse>().map(JSONObject: response.result.value), let pageData = result.pageData, let style = pageData.first {
//                        if (style.isValid() && !style.isOutOfStock()) {
//                            completion(style)
//                            return
//                        }
//                    }
//                }
//                completion(nil)
//            }
            SearchService.fetchStyleIfNeeded(ids[0] /*for just one sku in 5.6 version */, completion: completion)
        }
    }
    
    public func searchStyle( merchantId: Int? = nil)  {
        SearchService.searchStyle(self.styleFilter, pageSize: Constants.Paging.Offset, pageNo: pageNo, merchantId: merchantId,skuIds: self.skuIds) { [weak self] (response) in
            if let strongSelf = self {
                if response.result.isSuccess {
                    if let styleResponse = Mapper<SearchResponse>().map(JSONObject: response.result.value) {
                        if let styleLists = styleResponse.pageData {
                            var styleList = styleLists
                            //重新加载第一页
                            if strongSelf.pageNo <= 1 {
                                if let _ = strongSelf.headView {
                                    strongSelf.fetchs.fetch.delete(2, length: strongSelf.fetchs.fetch.count() - 2)
                                    
                                }else {
                                    strongSelf.fetchs.fetch.delete(1, length: strongSelf.fetchs.fetch.count() - 1)
                                }
                                
                                if styleList.count == 0 {
                                    strongSelf.noItemView.isHidden = false
                                }else {
                                    strongSelf.noItemView.isHidden = true
                                }
                                strongSelf.createFooter()
                            }
                            
                            if strongSelf.pageNo == 1 && styleList.count != 0 {
                                if strongSelf.fromSearch && (strongSelf.styleFilter.equal(strongSelf.originalStyleFilter ?? StyleFilter())) && strongSelf.isInsertSearchHistoryStyle { // 在第一页中需要过滤于搜索历史相同的一个产品
                                    if let s = strongSelf.searchHistoryStyle {
                                        styleList = styleList.filter({$0.styleId != s.styleId})
                                        if styleList.count == 0 { // 防止过滤后的数据为空,无法进行数据展示
                                            styleList.append(s)
                                        }
                                    }
                                } else if let style = strongSelf.preferredStyle {
                                    styleList = styleList.filter({$0.styleId != style.styleId})
                                    if styleList.count == 0 { // 防止过滤后的数据为空,无法进行数据展示
                                        styleList.append(style)
                                    }
                                }
                            }
                            
                            var feed = strongSelf.createFeed(styleList)
                            
                            if strongSelf.pageNo == 1 && styleList.count != 0 {
                                if strongSelf.fromSearch && (strongSelf.styleFilter.equal(strongSelf.originalStyleFilter ?? StyleFilter())) && strongSelf.isInsertSearchHistoryStyle { // 将搜索keyword对应的产品 insert to list of 0 index
                                    if let s = strongSelf.searchHistoryStyle {
                                        if styleLists.count == 1 { // 防止过滤后的数据为空,无法进行数据展示,移除后插入到first
                                            feed.removeLast()
                                        }
                                        feed.insert(s, at: 0)
                                    }
                                } else if let style = strongSelf.preferredStyle {
                                    if styleLists.count == 1 { // 防止过滤后的数据为空,无法进行数据展示,移除后插入到first
                                        feed.removeLast()
                                    }
                                    feed.insert(style, at: 0)
                                }
                            }
                            
                            if styleList.count != 0 {
                                strongSelf.pageNo = strongSelf.pageNo + 1
                            }
                        strongSelf.fetchs.fetch.append(ProductListBuilder.buiderStyleListCellModel(feed,delegate:strongSelf))

                            if let aggregations = styleResponse.aggregations {
                                strongSelf.aggregations = aggregations
                            } else {
                                strongSelf.aggregations = Aggregations()
                            }
                            
                            if strongSelf.originalAggregations == nil || (strongSelf.originalStyleFilter != nil && strongSelf.originalStyleFilter?.queryString != strongSelf.recordQueryString) {
                                strongSelf.recordQueryString = strongSelf.originalStyleFilter?.queryString ?? ""
                                strongSelf.originalAggregations = strongSelf.aggregations?.clone()
                            }
                            
                            strongSelf.secondLevelCategory(hitsTotal: styleResponse.hitsTotal)
                            
                            if strongSelf.title!.isEmptyOrNil() {
                                strongSelf.updateTitleNavigation()
                            }
                            if styleList.count == 0 {
                                strongSelf.table.mj_footer.endRefreshingWithNoMoreData()
                                if strongSelf.isVideo, strongSelf.needFloating, let container = strongSelf.headViewCellContentView {
                                    let margin = container.height * 0.4
                                    strongSelf.fetchs.fetch.insert(ProductListBuilder.builderBottomMarginCell(margin), atIndex: strongSelf.fetchs.fetch.count())
                                }
                            } else {
                                strongSelf.table.mj_footer.endRefreshing()
                            }
                        }
                    }
                } else {
                    strongSelf.createFooter()
                    strongSelf.secondLevelCategory(hitsTotal: 0)
                    ErrorLogManager.sharedManager.recordNonFatalError(withException: .FailToParseAPIResponse)
                    strongSelf.table.mj_footer.endRefreshing()
                }
            }
        }
    }
    
    private func createFooter()  {
        table.mj_footer = MMRefreshFooter(refreshingTarget: self, refreshingAction: #selector(footerRefursh))
    }
    
    private func secondLevelCategory(hitsTotal:Int)  {
        buildSecondLevelCategory { [weak self] cat in
            if let strongSelf = self {
                strongSelf.updateSearchtCellModel(hitsTotal: hitsTotal,cat:cat)
            }
        }
    }
    
    private func updateSearchtCellModel(hitsTotal:Int,cat:[Cat])  {
        var index:Int = 0
        if let _ = self.headView {
            index = 1
        }
        if let cellModel = self.fetchs.fetch[index] as? ProductListSearchConditionsCellModel {
            var count = 0
            if !isSearchAllCategory {
                count = styleFilter.count() - (originalStyleFilter?.count() ?? 0)
            }
            if count > 0 {
                cellModel.selctCategoryShort = true
            } else {
                cellModel.selctCategoryShort = false
            }
            cellModel.stylesTotal = hitsTotal
            cellModel.categories = cat
            cellModel.filter = self.styleFilter
            self.fetchs.fetch[index] = cellModel

            var idx = 0
            //这样做的原因是因为  sortlist的字符有相同的
            if self.originalStyleFilter?.sort == "DisplayRanking" && self.originalStyleFilter?.order == "desc" {
                idx = 0 // 综合
            } else if self.originalStyleFilter?.sort == "LastCreated" && self.originalStyleFilter?.order == "desc" {
                idx = 1 // 新品优先
            } else if self.originalStyleFilter?.sort == "LastCreated" && self.originalStyleFilter?.order == "asc" {
                idx = 2 // 热销
            } else if self.originalStyleFilter?.sort == "PriceSort" && self.originalStyleFilter?.order == "asc" {
                idx = 3 // 价格由低到高
            } else if self.originalStyleFilter?.sort == "PriceSort" && self.originalStyleFilter?.order == "desc" {
                idx = 4 // 价格由高到低
            }
            self.sortCollectionView.selectIndex = idx
            cellModel.sortMenu = self.sortCollectionView.sortMenu[idx]
            self.fetchs.fetch.update(index)
            sortCollectionView.isSelected = !sortCollectionView.isSelected
            
            
        } else {
            if self.pageNo == 2 {
                var belongsToContainer = false
                if fromSearch || fromMerchant {
                    belongsToContainer = true
                }
                
                self.fetchs.fetch.insert(ProductListBuilder.buiderSearchtCellModel(categories: cat, filter: self.styleFilter, stylesTotal: hitsTotal,belongsToContainer:belongsToContainer, searchTap: { [weak self] in
                    if let storngSelf = self {
                        storngSelf.showFilterViewController(hitsTotal: hitsTotal)
                    }
                    }, sortTap: { [weak self] maxY in
                        if let storngSelf = self {
                            storngSelf.showSortCollectionView(maxY)
                        }
                    }, categoryShort: { [weak self] (filter) in
                        if let storngSelf = self {
                            if let styleFilter = filter{
                                storngSelf.sortCollectionView.removeFromSuperview()
                                storngSelf.styleFilter = styleFilter
                                storngSelf.reloadAll()
                            }
                        }
                }), atIndex: index)
                
                if let cellModel = self.fetchs.fetch[index] as? ProductListSearchConditionsCellModel {
                    var idx = 0
                    if self.originalStyleFilter?.sort == "DisplayRanking" && self.originalStyleFilter?.order == "desc" {
                        idx = 0 // 综合
                    } else if self.originalStyleFilter?.sort == "LastCreated" && self.originalStyleFilter?.order == "desc" {
                        idx = 1 // 新品优先  这样做的原因是因为  sortlist的字符有相同的
                    } else if self.originalStyleFilter?.sort == "LastCreated" && self.originalStyleFilter?.order == "asc" {
                        idx = 2 // 热销
                    } else if self.originalStyleFilter?.sort == "PriceSort" && self.originalStyleFilter?.order == "asc" {
                        idx = 3 // 价格由低到高
                    } else if self.originalStyleFilter?.sort == "PriceSort" && self.originalStyleFilter?.order == "desc" {
                        idx = 4 // 价格由高到低
                    }
                    self.sortCollectionView.selectIndex = idx
                    cellModel.sortMenu = self.sortCollectionView.sortMenu[idx]
                    self.fetchs.fetch.update(index)
                    sortCollectionView.isSelected = !sortCollectionView.isSelected
                }
            }
        }
    }
    
    func createFeed(_ styleList:[Style]) ->  [Any]{
        var styleArray = [Any]()
        
        var recordNumber = 0
 
        //brand去重
        if insetBrandList.count < 100 {
            insetBrandList =  insetBrandList + styleList.filterDuplicates({$0.brandId})
            insetBrandList = insetBrandList.filterDuplicates({$0.brandId})
        }
        
        //分页截取所需的style
        var startIndex = 0
        if self.pageNo != 1 { // 在第一页不进入此条件
            if insetBrandList.count > self.endIndex{
                startIndex = self.endIndex + 1
            }
        }
        let endIndex = insetBrandList.count - self.endIndex > brandfewNumber ? startIndex + (brandfewNumber - 1) : insetBrandList.count - 1
        self.endIndex = endIndex
        
        var newList = [Any]()
        
        var filtrate = false //筛选过的不插入品牌
        var count = 0
        if !isSearchAllCategory {
            count = styleFilter.count() - (originalStyleFilter?.count() ?? 0)
        }
        if count > 0 {
            filtrate = true
        } else {
            filtrate = false
        }
        if !filtrate && fromSearch && !noNeedBrandFeed && insetBrandList.count >= endIndex && startIndex != insetBrandList.count{
            for cellModel in insetBrandList[startIndex...endIndex] {
                newList.append(cellModel)
            }
        }
        
        //style转化为brandCellModel
        newList = getBrandList(newList)
        
        //brandCellModel插入feed流
        for index in 0..<styleList.count {
            if insetBrandList.count > endIndex && recordNumber < brandfewNumber && index % brandMarginNumber == 0 &&  recordNumber < newList.count {
                let model = newList[recordNumber]
                styleArray.append(model)
                recordNumber = recordNumber + 1
            }
            styleArray.append(styleList[index])
        }
        
        return styleArray
    }
    
    func getBrandList(_ styleList:[Any]) -> [CMSPageNewsfeedBLPCellModel] {
        var brandArray = [CMSPageNewsfeedBLPCellModel]()
        
        for styleModel in styleList{
            if let style =  styleModel as? Style{
                let cellModel = CMSPageNewsfeedBLPCellModel()
                cellModel.supportMagicEdge = 15
                let dataModel = CMSPageDataModel()
                dataModel.content = style.brandName
                let brand = Brand()
                brand.couponCount = 3
                dataModel.brand = brand
                dataModel.imageUrl = ImageURLFactory.URLSize512(style.brandSmallLogoImage, category: .brand).absoluteString
                dataModel.link = Navigator.mymm.website_brand_brandId + String(style.brandId)
                cellModel.data = dataModel
                brandArray.append(cellModel)
            }
        }
        
        return brandArray
    }
    
    //MARK: - event response
    private func switchSortCategory(index:Int) {
        styleFilter.sort = sortList[index]
        styleFilter.order = orderList[index]
        originalStyleFilter?.sort = sortList[index]
        originalStyleFilter?.order = orderList[index]
        reloadAll()
    }
    
    private func showSortCollectionView(_ maxY:CGFloat)  {
        if !sortCollectionView.isSelected {
            self.view.addSubview(sortCollectionView)
        }
        sortCollectionView.frame = CGRect.init(x: 0, y: maxY, width: ScreenWidth, height: ScreenHeight - maxY)
        sortCollectionView.isSelected = !sortCollectionView.isSelected
    }
    
    private func showFilterViewController(hitsTotal:Int)  {
        sortCollectionView.removeFromSuperview()
//        let filterViewController = FilterViewController()
//        filterViewController.stylesTotal = hitsTotal
//        filterViewController.styles = self.styles
//        filterViewController.skuIds = self.skuIds
//        filterViewController.originalStyles = self.styles
//        filterViewController.styleFilter = self.styleFilter.clone()
//        filterViewController.originalStyleFilter = self.originalStyleFilter?.clone() ?? StyleFilter()
//        if let aggregations = self.aggregations {
//            filterViewController.aggregations = aggregations
//        }
//        filterViewController.originalAggregations = originalAggregations
//        filterViewController.displayingAggregations = originalAggregations
//        filterViewController.selectedFilterCategories = self.selectedFilterCategories
//        filterViewController.filterStyleDelegate = self
//        self.navigationController?.push(filterViewController, animated: true)
        
        let vc = MMFilterViewController()
        vc.originStyleFilter = self.originalStyleFilter?.clone() ?? StyleFilter()
        vc.userStyleFilter = self.userStyleFilter
        vc.aggregations = self.originalAggregations?.clone()
        vc.styles = self.styles
        vc.selectedfilterGenderType = self.filterGenderType
        vc.filterViewControllerDelegate = self
        vc.confirmBlock = { [weak self] (genderType) in
            if let strongSelf = self {
                strongSelf.filterGenderType = genderType
            }
        }
        vc.modalPresentationStyle = .custom
        present(vc, animated: false, completion: nil)
    }
    
    //MARK: - navigationn
    private func updateTitleNavigation() {
        self.title = ""//String.localize("LB_CA_PLP_PRODUCT_LIST")
        if self.isVideo {//当有视频传入时 viewWillAppear中会根据导航显示状态调整
            if self.navigationBarVisibility == .visible {
                if let tl = self.ssn_Arguments["title"]?.string, !tl.isEmpty {//手动配置title的情况
                    self.title = tl
                } else {
                    self.title = String.localize("LB_CA_PLP_PRODUCT_LIST")
                }
            }
        } else if let tl = self.ssn_Arguments["title"]?.string, !tl.isEmpty {//手动配置title的情况
            self.title = tl
        } else if self.styleFilter.brands.count == 1 {
            self.title = self.styleFilter.brands[0].brandName
        } else if self.styleFilter.merchants.count == 1 {
            self.title = self.styleFilter.merchants[0].merchantName
        } else if self.styleFilter.cats.count == 1 {
            self.title = self.styleFilter.cats[0].categoryName
        }
    }
    
    private  func setupNavigationBar() {
        let backButtonItem = UIBarButtonItem(image: UIImage(named: "back_grey")?.withRenderingMode(.alwaysOriginal), style: .plain, target: self, action: #selector(self.popViewController))
        let searchButtonItem = UIBarButtonItem(image: UIImage(named: "search_grey")?.withRenderingMode(.alwaysOriginal), style: .plain, target: self, action: #selector(self.actionSearch))
        
        var leftButtonItems = [UIBarButtonItem]()
        leftButtonItems.append(backButtonItem)
        
        leftButtonItems.append(searchButtonItem)
        
        self.navigationItem.leftBarButtonItems = leftButtonItems
    }
    
    private func createEmptySearchBox(_ string:String) {
        //View search box
        let searchView = UIView(frame: CGRect(x: -12, y: 0, width: self.view.bounds.maxX - 50, height: 29))
        searchView.layer.cornerRadius = searchView.bounds.maxY / 2;
        searchView.layer.borderColor = UIColor.secondary1().cgColor
        searchView.layer.borderWidth = 1.0
        searchView.isUserInteractionEnabled = false
        
        let searchIconImageView = UIImageView(image: UIImage(named: "search_grey"))
        searchIconImageView.frame = CGRect(x: 10, y: searchView.bounds.midY - 16 / 2, width: 16, height: 16)
        searchView.addSubview(searchIconImageView)
        
        //Label search term
        let searchTermLabel = UILabel(frame: CGRect(x: searchIconImageView.frame.maxX + 10, y: 0, width: searchView.bounds.maxX - (searchIconImageView.bounds.maxX + 10), height: searchView.bounds.maxY))
        searchTermLabel.formatSize(12)
        searchView.addSubview(searchTermLabel)
        searchTermLabel.text = string
        
        //Button Search contains search box
        let searchButton = UIButton(type: UIButtonType.custom)
        searchButton.frame = searchView.bounds
        searchButton.addTarget(self, action:#selector(actionSearch), for: .touchUpInside)
        searchButton.contentEdgeInsets = UIEdgeInsets.zero
        searchButton.addSubview(searchView)
        
        self.navigationItem.leftBarButtonItems = [UIBarButtonItem(customView: backButton),UIBarButtonItem(customView: searchButton)]
        
    }

    private func setupSearchBar() {
        if let navigationBar = self.navigationController?.navigationBar {
            let customView = UIView(frame: CGRect(x: 0, y: 0, width: navigationBar.width * 0.7, height: navigationSearchHeight))
            customView.layer.cornerRadius = 4
            customView.layer.masksToBounds = true
            customView.backgroundColor = UIColor.imagePlaceholder()
            searchButton.frame =  CGRect(x: (customView.width - searchButton.width) / 2, y: (navigationSearchHeight - searchButton.height) / 2, width: searchButton.width, height:searchButton.height)
            customView.addSubview(searchButton)
            self.navigationItem.leftBarButtonItems = [UIBarButtonItem(customView: backButton),UIBarButtonItem(customView: customView)]
        }
    }
    
    @objc private func popViewController()  {
        self.navigationController?.popViewController(animated: true)
    }
    
    @objc private func popupSearch() {
        self.doSearch()
    }
    
    @objc private func actionSearch() {
        doSearch()
    }
    
    /// didClickCloseBtn true: searbar要显示热搜的第一个词, false:则不需要
    func doSearch(_ searchString: String? = nil, didClickCloseBtn: Bool = false) {
        sortCollectionView.removeFromSuperview()

        let searchStyleController = SearchStyleController()
        var searchStr = searchString
        if didClickCloseBtn {
            searchStr = ""
        }
        searchStyleController.searchString = searchStr == nil ? self.styleFilter.queryString : searchStr
        searchStyleController.merchantId = merchantId
        searchStyleController.brandId = brandId
        searchStyleController.styles = self.styles
        searchStyleController.filterStyleDelegate = self
        searchStyleController.isShowHotKeyInSearchbar = didClickCloseBtn
        searchStyleController.isCreatingPost = self.isCreatingPost
        searchStyleController.isEnableAutoCompleteSearch = isEnableAutoCompleteSearch
        searchStyleController.isShowTabBar = isShowTabBarInSearchStyle
        if let _ = brandId {
            searchStyleController.searchType = .brand
            searchStyleController.popTwice = false
        }
        if let _ = merchantId {
            searchStyleController.searchType = .merchant
            searchStyleController.popTwice = true
        }
                
        if fetchs.fetch.count() == 0 {
            searchStyleController.popTwice = true
        }
        
        if let block = doSearchBlock {
            block(searchStyleController)
        } else {
            self.navigationController?.push(searchStyleController, animated: false)
        }

    }
    
    //MARK: - CollectionViewDelegate
    @objc func collectionView(_ collectionView: UICollectionView, magicHorizontalEdgeForCellAt indexPath: IndexPath) -> CGFloat {
        guard let m = fetchs.object(at: indexPath) as? CMSCellModel else {
            return 0.0
        }
        return m.supportMagicEdge
    }
    
    //MARK: - ScrollViewDelegate
    override func scrollViewDidScroll(_ scrollView: UIScrollView) {
        if let _ = self.headView {
            if self.brand == nil {
                scrollView.contentOffset.y = max(scrollView.contentOffset.y, 0)
            }
            
            if let navigationController = self.navigationController as? MmNavigationController {
                let scrollOffsetY = scrollView.contentOffset.y
                navigationController.setNavigationBarVisibility(offset: scrollOffsetY)
                let showingHead: Bool = scrollOffsetY < 44
                backButton.isSelected = showingHead
                if self.isVideo {
                    if showingHead {
                        self.title = ""
                    } else {
                        if let tl = self.ssn_Arguments["title"]?.string, !tl.isEmpty {//手动配置title的情况
                            self.title = tl
                        } else {
                            self.title = String.localize("LB_CA_PLP_PRODUCT_LIST")
                        }
                    }
//                    self.title = showingHead ? "" : String.localize("LB_CA_PLP_PRODUCT_LIST")
                }
                self.navigationBarVisibility = showingHead ? .hidden : .visible
                
                if isVideo, needFloating, let height = headViewCellContentView?.height { // will only send view if video
                    let shouldFloatVideo = scrollOffsetY > (height - StartYPos - 10 /* buffer for cell showing*/)
                    if !shouldFloatVideo {
                        self.sendHeadViewToTop()
                    } else if let head = self.headView as? ProductListVideoView, head.isPlaying {
                        self.sendHeadViewToFloating()
                    }
                }
            }
        }
        if sortCollectionView.isDescendant(of: self.view) {
            sortCollectionView.removeFromSuperview()
        }
        if let delegate = delegate {
            delegate.productListViewControllerScrollViewDidScroll(scrollView)
        }
        
        if scrollView.contentOffset.y > scrollView.height*3  {
            scrollToTopBtn.isHidden = contentOffSetY > scrollView.contentOffset.y ? false : true
            contentOffSetY = scrollView.contentOffset.y
        } else {
            scrollToTopBtn.isHidden = true
        }
    }
    
    private func sendHeadViewToFloating() {
        if isHeadViewFloating { return }
        
        isHeadViewFloating = !isHeadViewFloating
        
        if let headView = self.headView as? ProductListVideoView, let container = self.headViewCellContentView {
            let width = container.frame.width * 0.4
            let height = container.frame.height * 0.4
            let margin = CGFloat(10.0)
            let posY = self.view.height - height - (IsIphoneX ? ScreenBottom : 20)
            headView.frame = CGRect(x: margin, y: posY, width: width, height: height)
            headView.toFloatingView()
            headView.removeFromSuperview()
            self.view.addSubview(headView)
            
            if let closeButton = headViewCloseButton {
                closeButton.isHidden = false
            } else {
                headViewCloseButton = UIButton(frame: CGRect(x: headView.frame.width - 30 , y: 0, width: 30, height: 30))
                headViewCloseButton?.setImage(UIImage(named: "plp_video_close"), for: .normal)
                headViewCloseButton?.whenTapped {
                    headView.closeButtonClickHandler?()
                    headView.removeFromSuperview()
                    self.headViewCloseButton?.isHidden = true
                }
                headView.addSubview(headViewCloseButton!)
            }
        }
    }
    
    private func sendHeadViewToTop() {
        if !isHeadViewFloating { return }
        
        isHeadViewFloating = !isHeadViewFloating
        
        if let headView = self.headView as? ProductListVideoView, let container = self.headViewCellContentView {
            headView.frame = CGRect(x: 0, y: 0, width: container.width, height: container.height)
            headView.toTopView()
            headView.removeFromSuperview()
            container.addSubview(headView)
            
            if let closeButton = headViewCloseButton {
                closeButton.isHidden = true
            }
        }
    }
    
    //MARK: - FilterStyleDelegate
    func filterStyle(_ styles: [Style], styleFilter: StyleFilter, selectedFilterCategories: [Cat]?) {
        if selectedFilterCategories != nil {
            if selectedFilterCategories!.count > 0 {
                self.isSearchAllCategory = false //Clear search all category status
                self.selectedFilterCategories = selectedFilterCategories
            } else {
                self.selectedFilterCategories = nil
            }
        }
        
        self.filterStyle(styles, styleFilter: styleFilter, isNeedSnapshot: false)
    }
    
    func filterStyle(_ styles: [Style], styleFilter: StyleFilter, isNeedSnapshot: Bool) {
        self.isSearchAllCategory = false //Clear search all category status
        
        self.styles = styles
        self.styleFilter = styleFilter.clone()
        
        if isNeedSnapshot {
            styleFilter.saveSnapshot()
        }
        self.reloadAll()
    }
    
    func fetchStyles(_ styles: [Style], styleFilter: StyleFilter, isNeedSnapshot: Bool, merchantId: Int?, completion: ((SearchResponse?) -> Void)?) {
        self.navigationController?.popViewController(animated: false)
        
        if let block = searchFetchStylesBlock {
            block(styleFilter.queryString)
        }
        
        //        if !fromSearch && !noNeedBrandFeed {
        let parent = self.parent
        let pparent = self.parent?.parent
        if (self.isSearch //标识不需要进入全局搜索
            || parent != nil && parent! is ProductListSearchViewController)
            || (pparent != nil && pparent! is ProductListSearchViewController) {
            
            self.isSearchAllCategory = false //Clear search all category status
            self.styles = styles
            setStyleFilter(styleFilter, isNeedSnapshot: true)
            if isNeedSnapshot {
                styleFilter.saveSnapshot()
            }
            setOriginalStylFilter(styleFilter)
            
            var idx = 0
            if let _ = headView {
                idx = 1
            }
            if let cellModel = fetchs.fetch[idx] as? ProductListSearchConditionsCellModel{
                cellModel.sortMenu = ""
                fetchs.fetch.update(idx)
            }
            
            self.createEmptySearchBox(styleFilter.queryString)
            reloadAll()
        } else {//去全局搜索
            let productListSearchViewController = ProductListSearchViewController()
            productListSearchViewController.styleFilter = styleFilter
            productListSearchViewController.styles = styles
            self.navigationController?.pushViewController(productListSearchViewController, animated: false)
        }
    }
    
    func didSelectMerchantFromSearch(_ merchant: Merchant?) {
        if isPopAfterSelectFromSearch {
            self.navigationController?.popViewController(animated: false)
        }
        if let merchant = merchant {
            Navigator.shared.dopen(Navigator.mymm.website_merchant_merchantId + "\(merchant.merchantId)")
        }
    }
    
    func didSelectBrandFromSearch(_ brand: Brand?) {
        let navigationController = self.navigationController
        if isPopAfterSelectFromSearch {
            self.navigationController?.popViewController(animated: false)
        }

        let brandViewController = BrandViewController()
        brandViewController.brand = brand
        navigationController?.push(brandViewController, animated: true)
    }
    
    //MARK: - MMLayout
    override func loadLayoutConfig() -> MMLayoutConfig {
        var _config:MMLayoutConfig = MMLayoutConfig()
        _config.rowHeight = 0
        _config.columnCount = 2
        _config.rowDefaultSpace = 0
        _config.columnSpace = 8
        _config.supportMagicHorizontalEdge = true
        _config.floating = true
        if let _ = headView {
            _config.floatingOffsetY = StartYPos
        }
        return _config
    }
    
    //MARK: - lazy
    
    var headView:UIView? {
        didSet {
            if let _ = headView,isLoadView {
                self.fetchs.fetch.update(0)
            }
            
            if let _ = headView as? ProductListVideoView {
                self.isVideo = true
            }
        }
    }
    
    lazy var sortCollectionView:ProductListSortView = {
        let sortCollectionView = ProductListSortView()
        sortCollectionView.selectTap = { [weak self] (index,sortMenu) in
            if let strongSelf = self {
                strongSelf.isInsertSearchHistoryStyle = index == 0 ? true : false
                var idx = 0
                if let _ = strongSelf.headView {
                    idx = 1
                }
                if let cellModel = strongSelf.fetchs.fetch[idx] as? ProductListSearchConditionsCellModel {
                    cellModel.sortMenu = sortMenu
                    strongSelf.fetchs.fetch.update(idx)
                }
                strongSelf.switchSortCategory(index: index)
                sortCollectionView.isSelected = !sortCollectionView.isSelected
                sortCollectionView.removeFromSuperview()
            }
        }
        return sortCollectionView
    }()
    
    lazy var noItemView:UIView = {
        let noOrderViewSize = CGSize(width: 90, height: 100)
        var headViewHeight:CGFloat = 0
        
        if let headView = headView{
            headViewHeight = headView.frame.size.height
        }
        
        let noItemView = UIView(frame: CGRect(x: (ScreenWidth - noOrderViewSize.width ) / 2, y: (ScreenHeight - noOrderViewSize.height ) / 2 + headViewHeight / 2, width: noOrderViewSize.width, height: noOrderViewSize.height))
        noItemView.isHidden = true
        
        let boxImageViewSize = CGSize(width: 90, height: 70)
        let boxImageView = UIImageView(frame: CGRect(x: (noItemView.width - boxImageViewSize.width) / 2, y: 0, width: boxImageViewSize.width, height: boxImageViewSize.height))
        boxImageView.image = UIImage(named: "icon_empty_plp")
        noItemView.addSubview(boxImageView)
        
        let label = UILabel(frame: CGRect(x: 0, y: boxImageView.height + 10, width: noOrderViewSize.width, height: 20))
        label.textAlignment = .center
        label.formatSize(16)
        label.textColor = UIColor.secondary3()
        label.text = String.localize("LB_CA_CART_NOITEM")
        noItemView.addSubview(label)
        noItemView.isHidden = false
        self.table.addSubview(noItemView)
        return noItemView
    }()
    
    lazy var searchButton:UIButton = {
        let searchButton = UIButton()
        searchButton.isUserInteractionEnabled = true
        searchButton.setTitle(String.localize("LB_CA_HOMEPAGE_SEARCH"), for: UIControlState.normal)
        searchButton.setImage(UIImage(named: "search"), for: UIControlState.normal)
        searchButton.titleLabel?.font = UIFont.systemFont(ofSize: 12)
        searchButton.setTitleColor(UIColor(hexString: "#BCBCBC"), for: UIControlState.normal)
        searchButton.addTarget(self, action: #selector(ProductListViewController.popupSearch), for: .touchUpInside)
        searchButton.setIconInLeftWithSpacing(6)
        searchButton.sizeToFit()
        return searchButton
    }()
    
    lazy var backButton: UIButton = {
        let backButton: UIButton = UIButton()
        backButton.setImage(UIImage(named: "back_grey"), for: .normal)
        backButton.frame = CGRect(x: 0, y: 0, width: 30, height: 25)
        backButton.contentEdgeInsets = UIEdgeInsets.init(top: 0, left: Constants.Value.BackButtonMarginLeft, bottom: 0, right: 0)
        backButton.addTarget(self, action: #selector(popViewController), for: .touchUpInside)
        return backButton
    }()
    
    private lazy var scrollToTopBtn: UIButton = {
        var parentViewY: CGFloat = 0
        if let vc = parent {
            parentViewY = vc.view.y
        }
        let btn = UIButton(frame: CGRect(x: ScreenWidth - 60, y: self.view.height - 100, width: 48, height: 48))
        btn.setImage(UIImage(named: "back_to_top"), for: .normal)
        btn.isHidden = true
        btn.addTarget(self, action: #selector(ProductListViewController.scrollToTopBtnClick), for: UIControlEvents.touchUpInside)
        return btn
    }()
    
    @objc private func scrollToTopBtnClick(_ btn: UIButton) {
        table.scrollToTopAnimated(true)
    }
}

//MARK: - private methods
extension ProductListViewController {
    private func initAnalyticsRecord() {
        var viewParameters = ""
        var viewDisplayName = ""
        var merchantCode = ""
        var viewRef = ""
        
        if let originalStyleFilter = originalStyleFilter, let merchant = originalStyleFilter.merchants.first, originalStyleFilter.merchants.count == 1 {
            viewParameters = "merchant=\(merchant.merchantId)"
            viewRef = "\(merchant.merchantId)"
            viewDisplayName = "merchant=\(merchant.merchantName)"
            merchantCode = merchant.merchantCode
        } else if let originalStyleFilter = originalStyleFilter, let brand = originalStyleFilter.brands.first, originalStyleFilter.brands.count == 1 {
            viewRef = "\(brand.brandId)"
            viewParameters = "brand=\(brand.brandId)"
            viewDisplayName = "brand = \(brand.brandName)"
        } else if let category = styleFilter.rootCategories.first {
            viewRef = "\(category.categoryId)"
            viewParameters = "cat=\(category.categoryId)"
            viewDisplayName = "cat = \(category.categoryName)"
        } else if styleFilter.queryString != ""{
            viewParameters = "search=\(styleFilter.queryString)"
        }
        
        if styleFilter.queryString != "" {
            if viewDisplayName == "" {
                viewDisplayName = "search=\(styleFilter.queryString)"
            } else {
                viewDisplayName = viewDisplayName + " | " + "search=\(styleFilter.queryString)"
            }
        }
        
        var viewLocation = "PLP"
        var viewType = "Product"
        if let _ = self.headView {
            if let originalStyleFilter = originalStyleFilter, let _ = originalStyleFilter.merchants.first, originalStyleFilter.merchants.count == 1 {
                viewLocation = "MPP"
                viewType = "Merchant"
            } else {
                viewLocation = "BPP"
                viewType = "Brand"
            }
        }
        
        initAnalyticsViewRecord(merchantCode: merchantCode, viewDisplayName: viewDisplayName, viewParameters: viewParameters, viewLocation: viewLocation, viewRef: viewRef, viewType: viewType)
    }
    
    func setViewTagAnalyticsEnabled(_ isEnabled: Bool) {
        isViewTagAnalyticsEnabled = isEnabled
    }
    
    func setSearchSkuIds(_ skuIds: String) {
        var correctedSkuIds = ""
        
        let skuIdComponents = skuIds.split(separator: ",")
        
        for skuIdComponent in skuIdComponents{
            if let _ = Int(skuIdComponent) {
                if !correctedSkuIds.isEmpty{
                    correctedSkuIds.append(contentsOf: ",")
                }
                correctedSkuIds.append(contentsOf: skuIdComponent)
            }
        }
        self.skuIds = correctedSkuIds
    }
    
    func setStyleFilter(_ filter: StyleFilter, isNeedSnapshot: Bool) {
        checkFilterBrands(styleFilter: styleFilter)
        self.styleFilter = filter
        self.styleFilter.initFilterTags()
        //
        updateFilterTags()
        //
        if isNeedSnapshot {
            self.styleFilter.saveSnapshot()
        }
        
        if originalStyleFilter == nil {
            setOriginalStylFilter(styleFilter.clone())
        }
    }
    
    func setOriginalStylFilter(_ styleFilter: StyleFilter) {
        checkFilterBrands(styleFilter: styleFilter)
        originalStyleFilter = styleFilter
    }
    
    private func checkFilterBrands(styleFilter: StyleFilter) {
        if let bd = self.brand {
            var containedBrand = false
            for b in styleFilter.brands {
                if b.brandId == bd.brandId {
                    containedBrand = true
                    break
                }
            }
            if !containedBrand {
                styleFilter.brands.append(bd)
            }
        }
    }
    
    private func createStyleFilter() {
        checkFilterBrands(styleFilter: self.styleFilter) //某种情况并不会替换搜索词
        if let skuIdsString = self.ssn_Arguments["sku"]?.string {
            self.setSearchSkuIds(skuIdsString)
            
            if let sort = self.ssn_Arguments["sort"]?.string, let sortOrder = self.ssn_Arguments["order"]?.string {
                let styleFilter = StyleFilter()
                styleFilter.sort = sort
                styleFilter.order = sortOrder
                self.setStyleFilter(styleFilter, isNeedSnapshot: false)
                originalStyleFilter?.sort = sort    // 保证筛选的时候排序依然正确
                originalStyleFilter?.order = sortOrder
            }
        } else {
            StyleFilter.createLinkSytleFilter(ssn_Arguments: self.ssn_Arguments) { [weak self] (hasFilter, styleFilter) in
                if let strongSelf = self {
                    if hasFilter {
                        if styleFilter.merchants.count > 0 && styleFilter.sort.isEmpty {
                            styleFilter.sort = "DisplayRanking"
                            styleFilter.order = "desc"
                        }
                        strongSelf.selectedFilterCategories = styleFilter.cats
                        strongSelf.originalFilterCategories = styleFilter.cats
                        strongSelf.cats = styleFilter.cats
                        strongSelf.setStyleFilter(styleFilter, isNeedSnapshot: true)
                        strongSelf.originalStyleFilter?.sort = styleFilter.sort    // 保证筛选的时候排序依然正确
                        strongSelf.originalStyleFilter?.order = styleFilter.order
                        
                        //综合排序 用指定sort排
                        if !styleFilter.sort.isEmpty && !strongSelf.sortList.contains(styleFilter.sort) {
                            strongSelf.sortList[0] = styleFilter.sort
                            strongSelf.orderList[0] = styleFilter.order
                        }
                    }
                }
            }
        }
    }
    
    //updateFilterTags
    private func updateFilterTags() {
        for filterTag in self.styleFilter.filterTags {
            if (filterTag.name ?? "").isEmpty {
                switch filterTag.filterType {
                case .badge:
                    firstly {
                        return searchBadges()
                        }.then { badges -> Void in
                            var hasFilterBadge = false
                            
                            if let strongBadges = badges as? [Badge] {
                                if let badge = (strongBadges.filter{$0.badgeId == filterTag.id}).first {
                                    filterTag.name = badge.badgeName
                                    hasFilterBadge = true
                                    self.styleFilter.updateSubFilterName(badge)
                                }
                            } else {
                                ErrorLogManager.sharedManager.recordNonFatalError(withException: .NullPointerOrTypeMismatch)
                            }
                            
                            if !hasFilterBadge {
                                self.styleFilter.removeTag(filterTag)
                            }
                        }.always {
                            Log.debug("error")
                    }
                case .brand:
                    fetchBrands({ (brands) in
                        var hasFilterBrand = false
                        
                        if let brand = (brands.filter{$0.brandId == filterTag.id}).first {
                            filterTag.name = brand.brandName
                            hasFilterBrand = true
                            self.styleFilter.updateSubFilterName(brand)
                        }
                        
                        
                        if !hasFilterBrand {
                            self.styleFilter.removeTag(filterTag)
                        }
                    })
                case .category:
                    firstly {
                        return searchCategory(filterTag.id)
                        }.then { category -> Void in
                            if let stongCategory = category as? Cat {
                                filterTag.name = stongCategory.categoryName
                                self.styleFilter.updateSubFilterName(stongCategory)
                            } else {
                                self.styleFilter.removeTag(filterTag)
                            }
                        }.always {
                            Log.debug("error")
                    }
                case .color:
                    firstly {
                        return searchColors()
                        }.then { colors -> Void in
                            var hasFilterColor = false
                            if let strongColors = colors as? [Color] {
                                if let color = (strongColors.filter{$0.colorId == filterTag.id}).first {
                                    filterTag.name = color.colorName
                                    hasFilterColor = true
                                    self.styleFilter.updateSubFilterName(color)
                                }
                            } else {
                                ErrorLogManager.sharedManager.recordNonFatalError(withException: .NullPointerOrTypeMismatch)
                            }
                            
                            if !hasFilterColor {
                                self.styleFilter.removeTag(filterTag)
                            }
                        }.always {
                            Log.debug("error")
                    }
                case .size:
                    firstly {
                        return searchSizes()
                        }.then { sizes -> Void in
                            var hasFilterSize = false
                            
                            if let strongSizes = sizes as? [Size] {
                                if let size = (strongSizes.filter{$0.sizeId == filterTag.id}).first{
                                    filterTag.name = size.sizeName
                                    hasFilterSize = true
                                    self.styleFilter.updateSubFilterName(size)
                                }
                            } else {
                                ErrorLogManager.sharedManager.recordNonFatalError(withException: .NullPointerOrTypeMismatch)
                            }
                            
                            if !hasFilterSize {
                                self.styleFilter.removeTag(filterTag)
                            }
                        }.always {
                            Log.debug("error")
                    }
                case .merchant:
                    firstly {
                        return MerchantService.fetchMerchantsIfNeeded(.all)
                        }.then { merchants -> Void in
                            var hasFilterMerchant = false
                            
                            let strongMerchants : [Merchant] = merchants
                            if let merchant = (strongMerchants.filter{$0.merchantId == filterTag.id}).first {
                                filterTag.name = merchant.merchantName
                                hasFilterMerchant = true
                                self.styleFilter.updateSubFilterName(merchant)
                            }
                            
                            
                            if !hasFilterMerchant {
                                self.styleFilter.removeTag(filterTag)
                            }
                        }.always {
                            Log.debug("error")
                    }
                default:
                    break
                }
            }
        }
    }
    
    private  func searchCategory(_ categoryId: Int) -> Promise<Any> {
        return Promise{ fulfill, reject in
            var ids : [Int] = []
            ids.insert(categoryId, at: 0)
            SearchService.searchCategoryByCategoryId(ids: ids, success: { [weak self] (cats) in
                if let _ = self {
                    if let value = cats.first {
                        fulfill(value)
                    } else {
                        fulfill(())
                    }
                }
                }, failure: { (err) -> Bool in
                    reject(err)
                    return true
            })
        }
    }
    private  func fetchBrands(_ completion: @escaping ([Brand]) -> ()) {
        waitingFetchBrandsBlocks.append(completion)
        
        if isFetchingBrands { return }
        
        isFetchingBrands = true
        
        firstly {
            return searchBrands()
            }.then { [weak self] brands -> Void in
                if let strongSelf = self {
                    for block in strongSelf.waitingFetchBrandsBlocks{
                        block(strongSelf.brands)
                    }
                    strongSelf.waitingFetchBrandsBlocks.removeAll()
                    strongSelf.isFetchingBrands = false
                }
            }.always {
                Log.debug("error")
        }
    }
    
    private  func searchBrands() -> Promise<Any> {
        return Promise{ fulfill, reject in
            SearchService.searchBrand() { [weak self] (response) in
                if let strongSelf = self {
                    if response.result.isSuccess {
                        let brands = Mapper<Brand>().mapArray(JSONObject: response.result.value) ?? []
                        strongSelf.brands = brands
                        fulfill(brands)
                    } else {
                        reject(response.result.error ?? NSError(domain: "", code: 0, userInfo: nil))
                    }
                } else {
                    ErrorLogManager.sharedManager.recordNonFatalError(withException: .NullPointer)
                }
            }
        }
    }
    
    private  func searchColors() -> Promise<Any> {
        return Promise{ fulfill, reject in
            SearchService.searchColor() { [weak self] (response) in
                if let _ = self {
                    if response.result.isSuccess {
                        let colors = Mapper<Color>().mapArray(JSONObject: response.result.value) ?? []
                        fulfill(colors)
                    } else {
                        reject(response.result.error ?? NSError(domain: "", code: 0, userInfo: nil))
                    }
                } else {
                    ErrorLogManager.sharedManager.recordNonFatalError(withException: .NullPointer)
                }
            }
        }
    }
    
    private  func searchSizes() -> Promise<Any> {
        return Promise{ fulfill, reject in
            SearchService.searchSize() { [weak self] (response) in
                if let _ = self {
                    if response.result.isSuccess {
                        let sizes = Mapper<Size>().mapArray(JSONObject: response.result.value) ?? []
                        fulfill(sizes)
                    } else {
                        reject(response.result.error ?? NSError(domain: "", code: 0, userInfo: nil))
                    }
                } else {
                    ErrorLogManager.sharedManager.recordNonFatalError(withException: .NullPointer)
                }
            }
        }
    }
    
    private func searchBadges()-> Promise<Any> {
        return Promise{ fulfill, reject in
            SearchService.searchBadge() { [weak self] (response) in
                if let _ = self {
                    if response.result.isSuccess {
                        let badges = Mapper<Badge>().mapArray(JSONObject: response.result.value) ?? []
                        fulfill(badges)
                    } else {
                        reject(response.result.error ?? NSError(domain: "", code: 0, userInfo: nil))
                    }
                } else {
                    ErrorLogManager.sharedManager.recordNonFatalError(withException: .NullPointer)
                }
            }
        }
    }
}

extension ProductListViewController: MMNavigationControllerDelegate {
    func preferredNavigationBarVisibility() -> MmFadeNavigationControllerNavigationBarVisibility? {
        return self.navigationBarVisibility
    }
}

