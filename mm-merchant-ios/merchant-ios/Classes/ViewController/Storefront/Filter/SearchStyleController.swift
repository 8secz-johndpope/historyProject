//
//  SearchStyleController.swift
//  merchant-ios
//
//  Created by Koon Kit Chan on 11/12/2015.
//  Copyright © 2015 Koon Kit Chan. All rights reserved.
//

import Foundation
import ObjectMapper
import PromiseKit

class SearchStyleController : MmViewController, UISearchResultsUpdating {
    enum SearchMode: Int {
        case normal = 0,
        merchant,
        brand,
        postTagBrand
    }
    var searchController: UISearchController!
    var searchBarButtonItem: UIBarButtonItem!
    var searchBarTextField: UITextField?
    
    var searchString: String?
    var styles: [Style]!
    var searchTerms: [SearchTerm]?
    var histories: [String]!
    var popTwice = false
    var merchantId: Int?
    var brandId: Int?
    var isCreatingPost = false
    var isEnableAutoCompleteSearch = true
    var isShowTabBar = true
    
    var searchType: SearchMode = .normal
    
    var isShowHotKeyInSearchbar: Bool = false
    
    weak var filterStyleDelegate: FilterStyleDelegate!
    var didSelectBrandHandler: ((Brand) -> ())?
    
    private final let SearchIconTag = 8080
    private final let MenuCellId = "MenuCell"
    private final let ImageMenuCellId = "ImageMenuCell"
    private final let HeaderViewId = "Header"
    private final let SearchCellHeight: CGFloat = 45
    private final let SearchBrandCellHeight: CGFloat = 70
    private final let SearchHeaderHeight: CGFloat = 28
    private final let MarginLeft: CGFloat = 15
    
    private var contentInset = UIEdgeInsets.zero
    private var isSearching = false
    private var isPendingAPICall = false
    private var canLoadMore = true
    private var pageNo = 1
    
    override func viewDidLoad() {
        super.viewDidLoad()
        collectionView.delegate = self
        collectionView.dataSource = self
        collectionView.backgroundColor = UIColor.white
        collectionView.keyboardDismissMode = .onDrag
        let layout = MMSearchStyleFlowLayout(.left, 10)
        collectionView.collectionViewLayout = layout
        // Setup navigation menu search bar and button
        
        searchBarButtonItem = UIBarButtonItem(image: UIImage(named: "search"), style: .plain, target: self, action: #selector(SearchStyleController.showSearchBar(sender:)))
        self.navigationItem.leftBarButtonItem = self.searchBarButtonItem
        
        searchController = UISearchController(searchResultsController: nil)
        searchController.searchResultsUpdater = self
        searchController.dimsBackgroundDuringPresentation = false
        searchController.hidesNavigationBarDuringPresentation = false
        searchController.searchBar.sizeToFit()
        searchController.searchBar.delegate = self
        searchController.searchBar.accessibilityIdentifier = "search_style_searchbar"
        searchController.searchBar.searchBarStyle = .minimal
        searchController.searchBar.showsCancelButton = true
        
        self.definesPresentationContext = true
        showSearchBar()
        
        collectionView.register(SearchMenuCell.self, forCellWithReuseIdentifier: MenuCellId)
        collectionView.register(ImageMenuCell.self, forCellWithReuseIdentifier: ImageMenuCellId)
        collectionView.register(HeaderView.self, forSupplementaryViewOfKind: UICollectionElementKindSectionHeader, withReuseIdentifier: HeaderViewId)
        
        contentInset = collectionView.contentInset
        
        resetSearchData()
        
        initAnalyticsViewRecord(viewLocation: "Search-General", viewType: "General")
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
//        navigationController?.navigationBar.clipsToBounds = true
        self.navigationItem.setHidesBackButton(true, animated: false)
        self.view.initAnalytics(withViewKey: analyticsViewRecord.viewKey)
        self.histories = Context.getHistory()
        if self.histories.count > 0 && !self.isShowHotKeyInSearchbar {
            self.searchController.searchBar.placeholder = self.histories.first
        }
    }
    
    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        
        if let textField = searchBarTextField {
            textField.layer.cornerRadius = textField.bounds.height / 2
        }
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        navigationController?.navigationBar.clipsToBounds = false
        searchController?.dismiss(animated: false, completion: nil)
    }

    // MARK: - Action
    
    @objc func clear(sender: UITapGestureRecognizer) {
        
        let alertView = UIAlertController(title: String.localize("LB_CA_SEARCH_HISTORY_DELETE_ALL"), message: nil, preferredStyle: UIAlertControllerStyle.alert)
        let cancelAction = UIAlertAction(title: String.localize("LB_TO_CANCEL"), style: UIAlertActionStyle.cancel, handler: nil)
        let confirmAction = UIAlertAction(title: String.localize("LB_TL_CONFIRMATION"), style: UIAlertActionStyle.default) { (action) in
            self.histories = []
            Context.resetHistoryWeight()
            if let searchTerms = self.searchTerms {
                if searchTerms.count > 0 {
                    self.searchController.searchBar.placeholder = searchTerms[0].searchTerm
                }
            }
            self.collectionView?.reloadData()
            
            self.view.recordAction(.Tap, sourceRef: "Search-History-Clear", sourceType: .Button, targetRef: "Search-General", targetType: .View)
            
        }
        alertView.addAction(cancelAction)
        alertView.addAction(confirmAction)
        present(alertView, animated: true, completion: nil)
        
    }
    
    // MARK: - Search Controller methods
    
    func updateSearchResults(for searchController: UISearchController) {
        isSearching = (searchController.searchBar.text?.length)! < 1
        
        searchController.searchBar.viewWithTag(SearchIconTag)?.isHidden = !isSearching
        
        if !searchController.isActive {
            return
        }
        
        searchString = searchController.searchBar.text
        
        if !isEnableAutoCompleteSearch && !(searchString ?? "").isEmpty{
            collectionView?.reloadData()
            return
        }
        
        // Delay (0.3s) search to make less api called
        if !isPendingAPICall {
            isPendingAPICall = true
            
            DispatchQueue.main.asyncAfter(deadline: .now() + .milliseconds(300), execute: { [weak self] () -> Void in
                if let strongSelf = self {
                    strongSelf.isPendingAPICall = false
                    strongSelf.resetSearchData()
                    
                    if let searchString = strongSelf.searchString {
                        strongSelf.doSearchComplete(searchValue: searchString, pageNo: strongSelf.pageNo, merchantId: strongSelf.merchantId)
                    }
                }
            })
        }
    }
    func searchBar(_ searchBar: UISearchBar, textDidChange searchText: String) {
        //为空的时候保证placeholder为热门搜索:为了clearbutton
        isShowHotKeyInSearchbar = searchText.length == 0 ? true : false
    }
    func doSearchComplete(searchValue: String, pageNo: Int, merchantId: Int? = nil) {
        firstly {
            return self.searchComplete(s: searchValue, pageNo: pageNo, pageSize: Constants.Paging.Offset, merchantId: merchantId)
            }.then { _ -> Void in
                if self.histories.count > 0 && !self.isShowHotKeyInSearchbar {
                    self.searchController.searchBar.placeholder = self.histories.first
                } else {
                    if let searchTerms = self.searchTerms {
                        if searchTerms.count > 0 {
                            self.searchController.searchBar.placeholder = searchTerms[0].searchTerm
                        }
                    }
                }
                self.collectionView?.reloadData()
        }
    }
    
    // MARK: - Search bar methods
    
    @objc func showSearchBar(sender: UISearchBar) {
        showSearchBar()
    }
    
    @objc func showSearchBar() {
        searchController.searchBar.alpha = 0
        
        navigationItem.titleView = searchController.searchBar
        navigationItem.setLeftBarButton(nil, animated: false)
        
        if let button = searchController.searchBar.value(forKey: "cancelButton") as? UIButton {
            button.setTitle(String.localize("LB_CANCEL"), for: .normal)
        }
        searchController.searchBar.returnKeyType = UIReturnKeyType.search
        searchController.searchBar.setImage(UIImage(named: "searchbar_close"), for: .clear, state: .normal)
        searchController.searchBar.tintColor = UIColor.secondary2()
        searchController.searchBar.searchTextPositionAdjustment = UIOffset(horizontal: 10, vertical: 0)
        searchController.searchBar.setPositionAdjustment(UIOffset(horizontal: 2, vertical: 0), for: UISearchBarIcon.search)
        for view in searchController.searchBar.subviews {
            for subsubView in view.subviews {
                if let textField = subsubView as? UITextField {
                    textField.borderStyle = .roundedRect
                    textField.backgroundColor = UIColor(hexString: "#F1F1F1")
                    textField.enablesReturnKeyAutomatically = false
                    switch searchType {
                    case .merchant:
                        textField.placeholder = String.localize("LB_CA_SEARCH_IN_STORE")
                    case .brand:
                        textField.placeholder = String.localize("LB_CA_SEARCH_IN_BRAND")
                    case .postTagBrand:
                        textField.placeholder = String.localize("LB_AC_BRAND_SEARCH")
                    default:
                        textField.placeholder = String.localize("LB_SEARCH")
                    }
                    searchBarTextField = textField
                }
            }
        }
        
        UIView.animate(withDuration: 0.5, animations: { [weak self] in
            if let strongSelf = self {
                strongSelf.searchController.searchBar.alpha = 1
            }
            }, completion: { [weak self] finished in
                if let strongSelf = self {
                    if let str = strongSelf.searchString {
                        strongSelf.searchBarTextField?.text = str
                    }
                    strongSelf.searchController.searchBar.becomeFirstResponder()
                }
        })
    }
    
    // MARK: - UISearchBarDelegate
    
    func searchBar(_ searchBar: UISearchBar, shouldChangeTextIn range: NSRange, replacementText text: String) -> Bool {
        let currentString: String = searchBar.text ?? ""
        
        let maxLength = Constants.LimitNumber.LimitSearchText
        let newString: String = currentString.replacingCharacters(in: Range(range, in: currentString)!, with:text)
        if newString.length <= maxLength {
            return true
        }else {
            return false
        }
    }
    
    func searchBarCancelButtonClicked(_ searchBar: UISearchBar) {
        if let navigationController = navigationController {
            let numberOfViewControllers = navigationController.viewControllers.count
            if popTwice && numberOfViewControllers >= 3 {
                let viewController = navigationController.viewControllers[numberOfViewControllers - 3]
                navigationController.popToViewController(viewController, animated: false)
            } else {
                navigationController.popViewController(animated:false)
            }
        }
        searchBar.initAnalytics(withViewKey: analyticsViewRecord.viewKey)
        searchBar.recordAction(.Tap, sourceRef: "Cancel", sourceType: .Button, targetRef: "Search-General", targetType: .View)
    }
    
    func searchBarSearchButtonClicked(_ searchBar: UISearchBar) {
        if let trimmedString = searchBar.text?.trimmingCharacters(in: CharacterSet.whitespaces)  {
            var searchString = trimmedString
            if searchString.length > 0 {
                Context.addHistory(searchString)
            } else {
                if histories.count > 0 || searchTerms?.count ?? 0 > 0 { // 直接点击search 搜索placehodler
                    searchString = searchBar.placeholder ?? ""
                }
            }
            let styleFilter = StyleFilter()
            styleFilter.queryString = searchString
            
            if let brandId = self.brandId {
                let brand = Brand()
                brand.brandId = brandId
                styleFilter.brands.append(brand)
            }
            
            if let merchantId = self.merchantId {
                let merchant = Merchant()
                merchant.merchantId = merchantId
                styleFilter.merchants.append(merchant)
            }
            
            doSearch(styleFilter: styleFilter, merchantId: merchantId)
        }
        self.view.recordAction(.Input, sourceRef: searchBar.text, sourceType: .Text, targetRef: nil, targetType: .SearchTerm)
        
    }
    
    // MARK: - Collection View methods and delegates
    
    func numberOfSections(in collectionView: UICollectionView) -> Int {
        return 2
    }
    
    override func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        
        switch section {
        case 0:
            if (searchString == "" || !isEnableAutoCompleteSearch) && searchType != .postTagBrand {
                return histories.count
            }
        case 1:
            if let searchTerms = searchTerms {
                return searchTerms.count
            }
        default:
            break
        }
        
        return 0
    }
    
    override func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        switch indexPath.section {
        case 0:
            let cell = collectionView.dequeueReusableCell(withReuseIdentifier: MenuCellId, for: indexPath) as! SearchMenuCell
            
            cell.textLabel.text = histories[indexPath.row]
            cell.borderView.isHidden = true
            
            logImpression(cell: cell, indexPath: indexPath, impressionType: "SearchTerm")
            
            return cell
        case 1:
            if let searchTerms = searchTerms, indexPath.row < searchTerms.count {
                let searchTerm = searchTerms[indexPath.row]
                let cell = collectionView.dequeueReusableCell(withReuseIdentifier: ImageMenuCellId, for: indexPath) as! ImageMenuCell
                cell.topLine.isHidden = indexPath.row == 0 ? false : true
                switch searchTerm.entity {
                case "Brand":
                    cell.setImage(searchTerm.entityImage, imageCategory: .brand, size: .size256)
                    cell.upperLabel.text = searchTerm.searchTermIn
                    cell.lowerLabel.text = searchTerm.searchTerm
                    
                    logImpression(cell: cell, indexPath: indexPath, impressionType: "Brand")
                    
                    return cell
                case "Category":
                    cell.setImage(searchTerm.entityImage, imageCategory: .category, size: .size256)
                    cell.upperLabel.text = searchTerm.searchTermIn
                    cell.lowerLabel.text = searchTerm.searchTerm
                    
                    logImpression(cell: cell, indexPath: indexPath, impressionType: "Category")
                    
                    return cell
                case "Merchant":
                    cell.setImage(searchTerm.entityImage, imageCategory: .merchant, size: .size256)
                    cell.upperLabel.text = searchTerm.searchTermIn
                    cell.lowerLabel.text = searchTerm.searchTerm
                    
                    logImpression(cell: cell, indexPath: indexPath, impressionType: "Merchant")
                    
                    return cell
                default:
                    if indexPath.row == searchTerms.count - 1 && canLoadMore {
                        loadMore()
                    }
                    
                    let cell = collectionView.dequeueReusableCell(withReuseIdentifier: MenuCellId, for: indexPath) as! SearchMenuCell
                    
                    cell.textLabel.text = searchTerm.searchTerm
                    cell.borderView.isHidden = true
                    
                    logImpression(cell: cell, indexPath: indexPath, impressionType: "SearchTerm")
                    
                    return cell
                }
            }
        default:
            break
        }
        
        let cell = collectionView.dequeueReusableCell(withReuseIdentifier: MenuCellId, for: indexPath) as! SearchMenuCell
        cell.borderView.isHidden = false
        
        return cell
    }
    
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, sizeForItemAt indexPath: IndexPath) -> CGSize {
        if (isSearching || !isEnableAutoCompleteSearch) && histories.count > 0 && searchType != .postTagBrand && indexPath.section == 0 {
            let historyString = histories[indexPath.row]
            return CGSize(width: historyString.getTextWidth(height: SearchHeaderHeight, font: UIFont.systemFont(ofSize: 12)) + 20, height: SearchHeaderHeight)
        }
        
        if let searchTerms = searchTerms, indexPath.section == 1 {
            let searchTerm = searchTerms[indexPath.row]
            let searchTermEntity = searchTerm.entity
            
            if (searchTermEntity == "Brand" || searchTermEntity == "Category" || searchTermEntity == "Merchant") {
                return CGSize(width: view.width - MarginLeft * 2, height: SearchBrandCellHeight)
            } else {
                let s = searchTerm.searchTerm
                return CGSize(width: s.getTextWidth(height: SearchHeaderHeight, font: UIFont.systemFont(ofSize: 12)) + 20, height: SearchHeaderHeight)
            }
        }
        return CGSize.zero
    }
    
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, minimumInteritemSpacingForSectionAt section: Int) -> CGFloat {
        return 10
    }
    
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, insetForSectionAt section: Int) -> UIEdgeInsets {
        return UIEdgeInsetsMake(10, 15, 5, 15)
    }
    
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, minimumLineSpacingForSectionAt section: Int) -> CGFloat {
        return 10
    }
    
    // MARK: Header and Footer View for collection view
    
    func collectionView(_ collectionView: UICollectionView, viewForSupplementaryElementOfKind kind: String, at indexPath: IndexPath) -> UICollectionReusableView {
        switch kind {
        case UICollectionElementKindSectionHeader:
            let headerView = collectionView.dequeueReusableSupplementaryView(ofKind: kind, withReuseIdentifier: HeaderViewId, for: indexPath) as! HeaderView
            headerView.label.textColor = UIColor(hexString: "#4A4A4A")
            headerView.label.font = UIFont.systemFont(ofSize: 14)
            headerView.borderView.isHidden = true
            switch indexPath.section {
            case 0:
                headerView.label.text = String.localize("LB_CA_RECENT_SEARCH")
                headerView.label.frame = CGRect(x: MarginLeft, y: 0 , width: headerView.frame.maxX - MarginLeft * 2, height: headerView.bounds.maxY)
                headerView.imageView.isUserInteractionEnabled = true
                
                let image = UIImage(named: "icon_clear_bin") ?? UIImage()
                headerView.imageView.image = image
                headerView.imageView.frame = CGRect(x: headerView.bounds.maxX - (image.size.width + 5), y: headerView.bounds.midY - image.size.height / 2, width: image.size.width, height: image.size.height)
                headerView.imageView.addGestureRecognizer(UITapGestureRecognizer(target: self, action: #selector(SearchStyleController.clear)))
            case 1:
                headerView.label.text = String.localize("LB_CA_TRENDING_SEARCH")
                headerView.label.frame =  CGRect(x: MarginLeft, y: headerView.bounds.minY  - 2, width: view.width - MarginLeft*2, height: 40)
                headerView.imageView.image = nil
                headerView.imageView.isUserInteractionEnabled = false
            default:
                break
            }
            
            return headerView
        default:
            assert(false, "Unexpected element kind")
            
            let headerView = collectionView.dequeueReusableSupplementaryView(ofKind: kind, withReuseIdentifier: HeaderViewId, for: indexPath) as! HeaderView
            return headerView
        }
    }
    
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, referenceSizeForHeaderInSection section: Int) -> CGSize {
        switch section {
        case 0:
            if (isSearching || !isEnableAutoCompleteSearch) && histories.count > 0 && searchType != .postTagBrand {
                return CGSize(width: view.width, height: SearchHeaderHeight)
            }
            
            return CGSize.zero
        case 1:
            if (isSearching || !isEnableAutoCompleteSearch) && searchType != .postTagBrand {
                return CGSize(width: view.width, height: SearchHeaderHeight)
            } else {
                return CGSize.zero
            }
        default:
            return CGSize(width: view.width, height: SearchCellHeight)
        }
    }
    
    func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        var sourceRef: String?
        var sourceType = AnalyticsActionRecord.ActionElement.Unknown
        let styleFilter = StyleFilter()
        
        let cell = collectionView.cellForItem(at: indexPath)
        collectionView.initAnalytics(withViewKey: analyticsViewRecord.viewKey)
        
        switch indexPath.section {
        case 0:
            // Recently search
            if indexPath.row < histories.count {
                let queryString = histories[indexPath.row]
                
                styleFilter.queryString = queryString
                
                Context.addHistory(styleFilter.queryString)
                
                sourceRef = queryString
                sourceType = .SearchTermHistory
            }
            
        case 1:
            // Hot picks
            if let searchTerms = searchTerms, indexPath.row < searchTerms.count {
                let searchTerm = searchTerms[indexPath.row]
                
                switch searchTerm.entity {
                case "Brand":
                    let brand = Brand()
                    brand.brandId = searchTerm.entityId
                    brand.brandName = searchTerm.searchTerm
                    brand.brandNameInvariant = searchTerm.searchTermIn
                    
                    sourceRef = "\(brand.brandId)"
                    
                    if isCreatingPost {
                        styleFilter.brands = [brand]
                    } else {
                        self.navigationController?.popViewController(animated:false)
                        
                        if let filterStyleDelegate = filterStyleDelegate {
                            filterStyleDelegate.didSelectBrandFromSearch(brand)
                        } else if let selectBrandCallback = didSelectBrandHandler {
                            selectBrandCallback(brand)
                        }
                        
                        cell?.recordAction(.Tap, sourceRef: searchString, sourceType: .Text, targetRef: sourceRef, targetType: .Brand)
                        cell?.recordAction(.Tap, sourceRef: sourceRef, sourceType: .Brand, targetRef: "PLP", targetType: .View)
                    }
                case "Category":
                    let cat = Cat()
                    cat.categoryId = searchTerm.entityId
                    cat.categoryName = searchTerm.searchTerm
                    
                    styleFilter.cats = [cat]
                    sourceRef = "\(cat.categoryId)"
                    sourceType = .Category
                    
                    cell?.recordAction(.Tap, sourceRef: searchString, sourceType: .Text, targetRef: sourceRef, targetType: .Category)
                    
                case "Merchant":
                    let merchant = Merchant()
                    merchant.merchantId = searchTerm.entityId
                    merchant.merchantName = searchTerm.searchTerm
                    merchant.merchantNameInvariant = searchTerm.searchTermIn
                    
                    sourceRef = "\(merchant.merchantId)"
                    
                    if isCreatingPost {
                        styleFilter.merchants = [merchant]
                    } else {
                        self.navigationController?.popViewController(animated:false)
                        
                        if let filterStyleDelegate = filterStyleDelegate {
                            filterStyleDelegate.didSelectMerchantFromSearch(merchant)
                        }
                        
                        cell?.recordAction(.Tap, sourceRef: searchString, sourceType: .Text, targetRef: sourceRef, targetType: .Merchant)
                        cell?.recordAction(.Tap, sourceRef: sourceRef, sourceType: .Merchant, targetRef: "PLP", targetType: .View)
                    }
                default:
                    sourceRef = "\(searchTerm.entityId)"
                    sourceType = .SearchTermTrend
                    styleFilter.queryString = searchTerm.searchTerm
                    
                    cell?.recordAction(.Tap, sourceRef: searchString, sourceType: .Text, targetRef: sourceRef, targetType: .SearchTerm)
                }
                
                Context.addHistory(searchTerm.searchTerm)
            }
            
        default:
            break
            
        }
        
        /*//一下逻辑替换掉
         if !isEnableAutoCompleteSearch {
         if let brandId = self.brandId {
         let brand = Brand()
         brand.brandId = brandId
         styleFilter.brands.append(brand)
         }
         
         if let merchantId = self.merchantId{
         let merchant = Merchant()
         merchant.merchantId = merchantId
         styleFilter.merchants.append(merchant)
         }
         }*/
        //替换掉，将相关filter添加进去
        checkFilterBrandsAndMerchant(styleFilter: styleFilter)
        
        styleFilter.isFilter = false
        doSearch(styleFilter: styleFilter, merchantId: merchantId)
        
        collectionView.recordAction(.Tap, sourceRef: sourceRef, sourceType: sourceType, targetRef: "PLP", targetType: .View)
    }
    
    private func checkFilterBrandsAndMerchant(styleFilter: StyleFilter) {
        if let id = self.brandId {
            var containedBrand = false
            for b in styleFilter.brands {
                if b.brandId == id {
                    containedBrand = true
                    break
                }
            }
            if !containedBrand {
                let brand = Brand()
                brand.brandId = id
                styleFilter.brands.append(brand)
            }
        }
        
        if let id = self.merchantId {
            var containedMerchant = false
            for m in styleFilter.merchants {
                if m.merchantId == id {
                    containedMerchant = true
                    break
                }
            }
            if !containedMerchant {
                let merchant = Merchant()
                merchant.merchantId = id
                styleFilter.merchants.append(merchant)
            }
        }
    }
    
    // MARK: Data
    
    func doSearch(styleFilter: StyleFilter, merchantId: Int? = nil) {
        showLoading()
        
        if let filterStyleDelegate = filterStyleDelegate {
            filterStyleDelegate.fetchStyles(styles, styleFilter: styleFilter, isNeedSnapshot: true, merchantId: merchantId, completion: { [weak self] styleResponse in
                if let strongSelf = self {
                    strongSelf.stopLoading()
                    
                    var searchSuccess = false
                    
                    if let styleResponse = styleResponse {
                        if let styles = styleResponse.pageData {
                            if styles.count > 0 {
                                searchSuccess = true
                            }
                        }
                    }
                    
                    if searchSuccess || !styleFilter.queryString.isEmpty{
                        strongSelf.navigationController?.popViewController(animated:false)
                    } else {
                        strongSelf.navigationController?.pushViewController(NoResultViewController(), animated: false)
                    }
                }
            })
        } else {
            stopLoading()
        }
    }
    
    func searchStyle(styleFilter: StyleFilter) -> Promise<Any?> {
        return Promise{ fulfill, reject in
            SearchService.searchStyle(styleFilter){ [weak self] (response) in
                if let strongSelf = self {
                    if response.result.isSuccess {
                        if let styleResponse = Mapper<SearchResponse>().map(JSONObject: response.result.value) {
                            if let styles = styleResponse.pageData {
                                strongSelf.styles = styles
                            } else {
                                strongSelf.styles = []
                            }
                            
                            strongSelf.collectionView?.reloadData()
                            fulfill(styleResponse)
                        } else {
                            fulfill(nil)
                        }
                    } else {
                        reject(response.result.error!)
                    }
                }
            }
        }
    }
    
    func searchComplete(s: String, pageNo: Int, pageSize: Int, merchantId: Int? = nil) -> Promise<Any> {
        return Promise { fulfill, reject in
            SearchService.searchComplete(s.trim(), pageSize: Constants.Paging.newOffset, pageNo: pageNo, sort: "Priority", order: "desc", merchantId: merchantId) { [weak self] (response) in
                if let strongSelf = self {
                    if response.result.isSuccess {
                        if let term = Mapper<SearchTerm>().mapArray(JSONObject: response.result.value) {
                            strongSelf.pageNo = pageNo
                            var searchTerms = term
                            
                            let brandSearchTerms = searchTerms.filter({$0.entity == "Brand"})
                            let categorySearchTerms = searchTerms.filter({$0.entity == "Category"})
                            let merchantSearchTerms = searchTerms.filter({$0.entity == "Merchant"})
                            let residualSearchTerms = searchTerms.filter({$0.entity != "Brand" && $0.entity != "Category" && $0.entity != "Merchant"})
                            
                            searchTerms = merchantSearchTerms + brandSearchTerms + categorySearchTerms + residualSearchTerms
                            
                            if searchTerms.count > 0 {
                                if strongSelf.searchType == .postTagBrand {
                                    strongSelf.searchTerms!.append(contentsOf: brandSearchTerms)
                                } else {
                                    strongSelf.searchTerms!.append(contentsOf: searchTerms)
                                }
                            } else {
                                strongSelf.canLoadMore = false
                            }
                        } else {
                            strongSelf.canLoadMore = false
                        }
                        
                        fulfill("OK")
                    } else {
                        reject(response.result.error!)
                    }
                }
            }
        }
    }
    
    // MARK: - Helper
    
    private func resetSearchData() {
        canLoadMore = true
        pageNo = 1
        searchTerms = []
    }
    
    private func loadMore() {
        if let searchString = searchString {
            doSearchComplete(searchValue: searchString, pageNo: pageNo + 1, merchantId: merchantId)
        }
    }
    
    private func logImpression(cell: UICollectionViewCell, indexPath: IndexPath, impressionType: String) {
        var impressionDisplayName: String?
        var positionComponent: String?
        var impressionRef: String?
        
        switch indexPath.section {
        case 0:
            impressionDisplayName = self.histories[indexPath.row]
            positionComponent = "HistoryListing"
        case 1:
            // Hot picks
            let searchTerm = self.searchTerms?[indexPath.row]
            impressionDisplayName = searchTerm?.searchTerm
            positionComponent = "ResultListing"
            
            if searchTerm?.entity == "Trend"{
                positionComponent = "TrendListing"
            }
            
            if let entityId = self.searchTerms?[indexPath.row].entityId {
                impressionRef = "\(entityId)"
            }
        default:
            impressionDisplayName = self.searchTerms?[indexPath.row].searchTerm
            
            if let entityId = self.searchTerms?[indexPath.row].entityId {
                impressionRef = "\(entityId)"
            }
        }
        
        let viewKey = self.analyticsViewRecord.viewKey
        cell.analyticsViewKey = viewKey
        cell.initAnalytics(withViewKey: viewKey, impressionKey: AnalyticsManager.sharedManager.recordImpression(impressionRef: impressionRef, impressionType: impressionType, impressionDisplayName: impressionDisplayName, positionComponent: positionComponent, positionIndex: indexPath.row + 1, positionLocation: "Search-General", viewKey: viewKey))
    }
    
}



