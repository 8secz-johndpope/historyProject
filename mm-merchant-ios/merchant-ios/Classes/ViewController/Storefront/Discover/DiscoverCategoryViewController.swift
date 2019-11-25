//
//  DiscoverCategoryViewController.swift
//  merchant-ios
//
//  Created by Kam on 18/4/2016.
//  Copyright © 2016 WWE & CO. All rights reserved.
//

import Foundation
import PromiseKit
import ObjectMapper

class DiscoverCategoryViewController: MmViewController, SubcategoryGridViewDelegate, GenderHeaderViewDelegate {
    
    private final let TopMenuHeight: CGFloat = 40
    private final let GenderViewHeight: CGFloat = 80
    
    static let AllCategory = -1
    
    private var selectedGender = GenderHeaderView.GenderType.female
    
    var viewHeight: CGFloat = 0
    var cats = [Cat]()
    var backupCats = [Cat]()
    var selectedIndexPath: IndexPath?
    var selectedDiscoverCategoryCell: DiscoverCategoryCell?
    private var genderHeaderView: GenderHeaderView?
    
    private var nextPage = CacheManager.sharedManager.categoryNextPage
    
    private var loadingDelayAction: DelayAction?
    
    override func viewDidLoad() {
        super.viewDidLoad()
        super.pageAccessibilityId = "DiscoverCategoryPage"
       
        self.navigationController?.isNavigationBarHidden = false
        self.title = String.localize("LB_CA_CATEGORY")
        
        cats = CacheManager.sharedManager.clonedCategories
        
        backupCats = cats
        groupCategories(backupCats)
        
        setupCollectionView()
        
        sortSelectedGenderCats()
        
        feedCategory()
        
        initAnalyticLog()
        
        collectionView.reloadData()
        
        setupNavigationBarButton()
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)

        NotificationCenter.default.addObserver(self, selector: #selector(self.feedCategory), name: NSNotification.Name(rawValue: kReachabilityNetworkConnected), object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(self.feedCategory), name: NSNotification.Name.UIApplicationWillEnterForeground, object: nil)
        self.navigationController?.isNavigationBarHidden = false
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        
        NotificationCenter.default.removeObserver(self, name: NSNotification.Name(rawValue: kReachabilityNetworkConnected), object: nil)
        NotificationCenter.default.removeObserver(self, name: NSNotification.Name.UIApplicationWillEnterForeground, object: nil)
        self.navigationController?.isNavigationBarHidden = false
    }
    
    override func viewWillLayoutSubviews() {
        super.viewWillLayoutSubviews()
        
        if let noConnectionView = self.noConnectionView {
            let viewSize = CGSize(width: self.view.width, height: 198)
            noConnectionView.frame = CGRect(x: 0, y: (self.view.height - viewSize.height) / 2.0, width: viewSize.width, height: viewSize.height)
        } else {
            ErrorLogManager.sharedManager.recordNonFatalError(withException: .NullPointer)
        }
    }
    
    override func refresh() {
        feedCategory()
    }
    
    // MARK: - Setup views
    
    func setupCollectionView() {
        collectionView.register(DiscoverCategoryCell.self, forCellWithReuseIdentifier: DiscoverCategoryCell.CellIdentifier)
        collectionView.register(GenderHeaderView.self, forSupplementaryViewOfKind: UICollectionElementKindSectionHeader, withReuseIdentifier: GenderHeaderView.viewIdentifier)

        self.setAccessibilityIdForView("UICV_DISCOVER", view: collectionView)
    }
    
    func setupNavigationBarButton() {
        let ButtonHeight = CGFloat(25)
        let ButtonWidth = CGFloat(30)
        
        let backButton = UIButton()
        backButton.frame = CGRect(x: 0, y: 0, width: ButtonWidth, height: ButtonHeight)
        backButton.setImage(UIImage(named: "back_grey"), for: UIControlState())
        backButton.addTarget(self, action: #selector(backButtonTapped), for: .touchUpInside)
        
        let searchButton = UIButton()
        searchButton.frame = CGRect(x: 0, y: 0, width: ButtonWidth, height: ButtonHeight)
        searchButton.setImage(UIImage(named: "search_grey"), for: UIControlState())
        searchButton.addTarget(self, action: #selector(searchButtonTapped), for: .touchUpInside)
        
        let leftButtonItems = [UIBarButtonItem(customView: backButton), UIBarButtonItem(customView: searchButton)]
        navigationItem.leftBarButtonItems = leftButtonItems
        
        buttonCart = ButtonRedDot(type: .custom)
        buttonCart!.setImage(UIImage(named: "cart_grey"), for: UIControlState())
        buttonCart!.frame = CGRect(x: 0, y: 0, width: ButtonWidth, height: ButtonHeight)
        buttonCart!.addTarget(self, action: #selector(goToShoppingCart), for: .touchUpInside)
        
        let rightButtonItems = [UIBarButtonItem(customView: buttonCart!)]
        navigationItem.rightBarButtonItems = rightButtonItems
    }

    // MARK: - Actions
    @objc func backButtonTapped() {
        navigationController?.popViewController(animated: true)
    }
    
    @objc func searchButtonTapped() {
        let searchViewController = ProductListSearchViewController()
        navigationController?.push(searchViewController, animated: false)
    }
    
    // MARK: - Action
    
    func onBrandTapped(_ brand: BrandUnionMerchant, cate: Cat, sender: UIButton) {
        
        let styleFilter = StyleFilter()
        styleFilter.cats = [cate]
        
        if brand.entity == "Brand" {
            let aBrand = Brand()
            aBrand.brandId = brand.entityId
            aBrand.brandName = brand.name
            aBrand.brandNameInvariant = brand.nameInvariant
            styleFilter.brands = [aBrand]
        } else {
            let merchant = Merchant()
            merchant.merchantId = brand.entityId
            merchant.merchantName = brand.name
            merchant.merchantNameInvariant = brand.nameInvariant
            styleFilter.merchants = [merchant]
        }
        
        PushManager.sharedInstance.goToPLP(styleFilter: styleFilter, animated: false)

        sender.recordAction(.Tap, sourceRef: "\(brand.entityId)", sourceType: .Merchant, targetRef: "PLP", targetType: .View)
    }
    
    func onSubcateTapped(_ subcate: Cat) {
        
        let styleFilter = StyleFilter()
        
        if subcate.categoryId == DiscoverCategoryViewController.AllCategory {
            styleFilter.cats = []
            
            let parentCategory = self.cats.filter({ (currentCat) -> Bool in
                currentCat.categoryId == subcate.parentCategoryId
            })
            
            styleFilter.cats = parentCategory
            styleFilter.rootCategories = parentCategory
            
        } else {
            styleFilter.cats = [subcate]
            styleFilter.rootCategories = [subcate]
        }
        
        PushManager.sharedInstance.goToPLP(styleFilter: styleFilter, animated: false)

    }
    
    // MARK: - Category Services

    @objc func feedCategory() {
        if nextPage < 1 {
            return
        }
        
        self.collectionView.isHidden = (self.cats.count == 0)
        
        self.dismissNoConnectionView()
        
        if Reachability.shared().currentReachabilityStatus() == NotReachable {
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
        
        CacheManager.sharedManager.fetchNextCategoryPage(completion: { [weak self] (cats, nextPage, error) in
            if let strongSelf = self {
                guard nextPage != strongSelf.nextPage else{
                    return
                }
                
                strongSelf.nextPage = nextPage
                
                if let cats = cats {
                    strongSelf.backupCats.append(contentsOf: cats)
                }
                
                strongSelf.groupCategories(strongSelf.backupCats)

                strongSelf.sortSelectedGenderCats()
                
                DispatchQueue.main.async(execute: { [weak self] in
                    if let strongSelf = self {
                        strongSelf.collectionView.isHidden = (strongSelf.cats.count == 0)
                        strongSelf.collectionView?.reloadData()
                        
                        if error != nil{
                            strongSelf.handleNoNetworkConnection()
                        }
                    }
                })
            } else {
                ErrorLogManager.sharedManager.recordNonFatalError(withException: .NullPointer)
            }
        })
    }
    
    // MARK: - Collection View Delegate
    
    func collectionView(_ collectionView: UICollectionView, viewForSupplementaryElementOfKind kind: String, at indexPath: IndexPath) -> UICollectionReusableView {
        let headerView = collectionView.dequeueReusableSupplementaryView(ofKind: kind, withReuseIdentifier: GenderHeaderView.viewIdentifier, for: indexPath) as! GenderHeaderView
        headerView.setSelectedGender(genderType: selectedGender)
        headerView.delegate = self
        headerView.initAnalytics(withViewKey: self.analyticsViewRecord.viewKey)
        genderHeaderView = headerView
        return headerView
    }
    
    func numberOfSections(in collectionView: UICollectionView) -> Int {
        return 1
    }
    
    override func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return self.cats.count
    }
    
    override func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        let cell = collectionView.dequeueReusableCell(withReuseIdentifier: DiscoverCategoryCell.CellIdentifier, for: indexPath) as! DiscoverCategoryCell
        
        if indexPath.row < cats.count {
            let category = cats[indexPath.item]
            
            cell.category = category
            cell.label.text = category.categoryName
            cell.setImage(category.categoryImage, imageCategory: .category)
            cell.gridView.updateGridView(category)
            cell.handleGridView(category.isSelected)
            
            //Fix wrong gridview frame while scrolling collection view
            cell.updateSubviewFrames()
            cell.gridView.resizeGridSize()
            cell.analyticsViewKey = self.analyticsViewRecord.viewKey
            cell.gridView.analyticsViewKey = self.analyticsViewRecord.viewKey
            
            if let viewKey = cell.analyticsViewKey {
                cell.initAnalytics(withViewKey: viewKey, impressionKey: AnalyticsManager.sharedManager.recordImpression(impressionRef: "\(category.categoryId)", impressionType: "Category", impressionDisplayName: category.categoryName, positionComponent: "CategoryListing", positionIndex: indexPath.row + 1, positionLocation: "BrowseByCategory", viewKey: viewKey))
            } else {
                ErrorLogManager.sharedManager.recordNonFatalError(withException: .NullPointer)
            }
            
            if indexPath.row == cats.count - 1{
                feedCategory()
            }
            
            self.setAccessibilityIdForView("UIBT_FIRST_LEVEL_CATEGORY-\(category.categoryName)", view: cell)
        }
        
        cell.gridView.delegate = self
        
        return cell
    }
    
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, referenceSizeForHeaderInSection section: Int) -> CGSize {
        return CGSize(width: self.view.bounds.width, height: GenderViewHeight)
    }
    
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, sizeForItemAt indexPath: IndexPath) -> CGSize {
        let selected = self.cats[indexPath.row].isSelected
        
        if let currentCell = collectionView.cellForItem(at: indexPath) as? DiscoverCategoryCell {
            if selected {
                return CGSize(width: view.width, height: currentCell.getSubviewHeight())
            }
        } else {
            ErrorLogManager.sharedManager.recordNonFatalError(withException: .NullPointerOrTypeMismatch)
        }
        
        return CGSize(width: view.width, height: DiscoverCategoryCell.DefaultHeight)
    }
    
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, insetForSectionAt section: Int) -> UIEdgeInsets {
        return UIEdgeInsets.zero
    }
    
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, minimumLineSpacingForSectionAt section: Int) -> CGFloat {
        return 0.0
    }
    
    func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        if let currentCell = collectionView.cellForItem(at: indexPath) as? DiscoverCategoryCell {
            selectedIndexPath = indexPath
            selectedDiscoverCategoryCell = currentCell
            let currentCat = self.cats[indexPath.row]
            
            self.cats[indexPath.row].isSelected = !(currentCat.isSelected)
            
            for index in 0..<self.cats.count {
                if index != indexPath.row {
                    if self.cats[index].isSelected {
                        self.cats[index].isSelected = false
                    }
                    
                    if let cell = collectionView.cellForItem(at: IndexPath(row: index, section: 0)) as? DiscoverCategoryCell {
                        cell.collapseRemoveDetail()
                    } else {
                        ErrorLogManager.sharedManager.recordNonFatalError(withException: .NullPointerOrTypeMismatch)
                    }
                }
            }
            
            collectionView.performBatchUpdates(nil, completion: nil)
            
            if currentCat.isSelected {
                currentCell.expandShowDetail()
            } else {
                currentCell.collapseRemoveDetail()
            }
            
            currentCell.recordAction(.Tap, sourceRef: "\(currentCat.categoryId)", sourceType: .Category, targetRef: currentCat.isSelected == true ? "SubCategoryListing-Show":"SubCategoryListing-Hide", targetType: .ExpandedView)
        } else {
            ErrorLogManager.sharedManager.recordNonFatalError(withException: .NullPointerOrTypeMismatch)
        }
    }
    
    // MARK: - Gender Header Delegate
    
    func didSelectGender(_ genderType: GenderHeaderView.GenderType) {
        if let indexPath = selectedIndexPath {
            self.cats[indexPath.row].isSelected = false
            
            if let cell = selectedDiscoverCategoryCell {
                cell.gridView.isHidden = true
            } else {
                ErrorLogManager.sharedManager.recordNonFatalError(withException: .NullPointer)
            }
            
            self.switchGender(genderType)
            
            selectedIndexPath = nil
        } else {
            self.switchGender(genderType)
        }

        genderHeaderView?.recordAction(.Tap, sourceRef: (genderType == .female) ? "Female" : (genderType == .male ? "Male" : ""), sourceType: .Category, targetRef: "CategoryListing", targetType: .Category)
    }
    
    private func switchGender(_ genderType: GenderHeaderView.GenderType){
        self.dismissNoConnectionView()
        
        self.selectedGender = genderType
        
        if self.backupCats.count == 0 {
            feedCategory()
        } else {
            self.sortSelectedGenderCats()
            self.collectionView?.reloadData()
        }
    }
    
    // MARK: - Override
    
    override func showLoading() {
        self.showLoadingInScreenCenter()
    }
    
    // MARK: - Helpers
    
    private func groupCategories(_ catgories: [Cat]){
        for currentCat in catgories {
            if currentCat.categoryList == nil{
                currentCat.categoryList = [Cat]()
            }
            
            if let categoryList = currentCat.categoryList {
                let categoryAll = Cat()
                categoryAll.categoryId = DiscoverCategoryViewController.AllCategory
                categoryAll.categoryName = String.localize("LB_CA_ALL")
                categoryAll.categoryList = categoryList
                categoryAll.parentCategoryId = currentCat.categoryId
                categoryAll.statusId = 2
                
                if categoryList.count <= 0 {
                    currentCat.categoryList?.append(categoryAll)
                } else {
                    currentCat.categoryList?.insert(categoryAll, at: 0)
                }
            }
        }
    }
    
    private func sortSelectedGenderCats() {
        switch self.selectedGender {
        case GenderHeaderView.GenderType.female:
            self.cats = self.backupCats.filter{$0.isFemale == 1}
        case GenderHeaderView.GenderType.male:
            self.cats = self.backupCats.filter{$0.isMale == 1}
        }
    }
    
    private func handleNoNetworkConnection(){
        self.collectionView.isHidden = (self.cats.count == 0)
        
        if self.cats.count == 0{
            self.showNoConnectionView()
            
            if let noConnectionView = self.noConnectionView{
                self.view.bringSubview(toFront: noConnectionView)
                noConnectionView.reloadHandler = { [weak self] in
                    if let strongSelf = self {
                        strongSelf.feedCategory()
                    }
                    else{
                        ErrorLogManager.sharedManager.recordNonFatalError(withException: .NullPointer)
                    }
                }
            }
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
            viewParameters: Context.getUserProfile().userKey,
            viewLocation: "BrowseByCategory",
            viewRef: nil,
            viewType: "Product"
        )
    }
}
