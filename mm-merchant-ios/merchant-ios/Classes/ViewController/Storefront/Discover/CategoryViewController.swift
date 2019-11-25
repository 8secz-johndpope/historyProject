//
//  CategoryViewController.swift
//  merchant-ios
//
//  Created by khanh.nguyen on 12/22/16.
//  Copyright © 2016 WWE & CO. All rights reserved.
//

import UIKit
import PromiseKit
import ObjectMapper

class CategoryViewController: DiscoverCategoryViewController {

    var isShowStyleList = false
    weak var delegate: CreatePostProtocol?
    var category: Cat?
    var styles = [Style]()
    
    var styleFilter = StyleFilter()
    
    private var pageTotal = 0
    private var stylesTotal = 0
    private var pageNo = 1
    var canLoadMore = true
    private var noItemView: UIView!
    var styleCollectionView : UICollectionView!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        super.pageAccessibilityId = "CategoryProductSelectPage"
        
        initAnalytic()
        NotificationCenter.default.addObserver(self, selector: #selector(self.didRemoveStyleItem), name: NSNotification.Name(rawValue: "DidRemoveStyle"), object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(CategoryViewController.updateCollectionViewLayout), name: Constants.Notification.createPostDidUpdatePhoto, object: nil)
        
        self.setupNoItemView()
    }

    func setupStyleCollectionView() {
        let layout: UICollectionViewFlowLayout = getCustomFlowLayout()
        layout.sectionInset = UIEdgeInsets(top: 0, left: 0, bottom: 0, right: 0)
        layout.itemSize = CGSize(width: self.view.frame.width, height: 120)
        
        styleCollectionView = UICollectionView(frame: self.collectionView.frame, collectionViewLayout: layout)
        styleCollectionView.dataSource = self
        styleCollectionView.delegate = self
        styleCollectionView.alwaysBounceVertical = true
        styleCollectionView.register(WishListCollectionViewCell.self, forCellWithReuseIdentifier: WishListCollectionViewCell.CellIdentifier)
        styleCollectionView.backgroundColor = UIColor.white
        self.view.addSubview(styleCollectionView)
        styleCollectionView.isHidden = true
    }
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        
        self.refreshUI()
    }
    
    override func feedCategory() {
        if isShowStyleList == false {
            super.feedCategory()
        }
    }
    
    override func setupCollectionView() {
        super.setupCollectionView()
        self.setupStyleCollectionView()
        self.updateCollectionViewLayout()
    }
    
    @objc func updateCollectionViewLayout() {
        let maxY = CGFloat(64)
        self.collectionView.frame.originY = maxY
        self.collectionView.frame.sizeHeight = ScreenSize.height - maxY - (self.delegate?.getBottomViewHeight() ?? 0)
        self.styleCollectionView.frame = self.collectionView.frame
    }
    
    // MARK: - Overrivde Methods
    
    override func onBrandTapped(_ brand: BrandUnionMerchant, cate: Cat, sender: UIButton) {
        self.delegate?.didSelectSubCategory()
        isShowStyleList = true
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
        
        self.pageNo = 1
        self.styleCollectionView.scrollToTopAnimated(false)
        self.getStyles(styleFilter)
    }
    
    override func onSubcateTapped(_ subcate: Cat) {
        self.delegate?.didSelectSubCategory()
        isShowStyleList = true
        
        //MM-24303 clear brand and merchant in case of user selected merchant or brand before select category
        styleFilter.merchants = []
        styleFilter.brands = []
        
        if subcate.categoryId == DiscoverCategoryViewController.AllCategory {
            styleFilter.cats = []
            let parentCategory = self.cats.filter({ (currentCat) -> Bool in
                currentCat.categoryId == subcate.parentCategoryId
            })
            styleFilter.cats = parentCategory
            styleFilter.rootCategories = parentCategory
        } else {
            styleFilter.cats = [subcate]
        }
        
        self.pageNo = 1
        self.styleCollectionView.scrollToTopAnimated(false)
        self.getStyles(styleFilter)
    }
    
    //MARK: - Methods
    
    private func setupNoItemView() {
        let noOrderViewSize = CGSize(width: 90, height: 100)
        noItemView = UIView(frame: CGRect(x: (view.width - noOrderViewSize.width) / 2, y: (collectionView.height + collectionView.y + 64 - noOrderViewSize.height) / 2, width: noOrderViewSize.width, height: noOrderViewSize.height))
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
        
        view.addSubview(noItemView)
    }
    
    func updateNoItemView() {
        if isShowStyleList {
            noItemView.isHidden = !(styles.count == 0)
        } else {
            noItemView.isHidden = true
        }
    }
    
    func loadMore() {
        self.pageNo = self.pageNo + 1
        self.getStyles(self.styleFilter)
    }
    
    func getStyles(_ styleFilter: StyleFilter) {
        self.showLoading()
        
        firstly {
            return self.listStyleByCategory(styleFilter)
        }.then { _ -> Void in
            self.reloadDataSource()
            self.refreshUI()
        }.always {
            self.stopLoading()
        }.catch { _ -> Void in
            Log.error("error")
        }
    }
    
    func reloadDataSource() {
        for style in self.styles {
            var found = false
            
            if let selectedItems = self.delegate?.getSelectedItem() {
                for i in 0..<selectedItems.count {
                    if let sku = selectedItems[i].skus?.filter({$0.skuId == style.defaultSku()?.skuId}).first {
                        if sku.skuId == style.defaultSku()?.skuId {
                            style.selected = true
                            found = true
                            break
                        }
                    }
                }
            } else {
                ErrorLogManager.sharedManager.recordNonFatalError(withException: .NullPointer)
            }
            
            style.selected = found
        }
    }
    
    func refreshUI() {
        if isShowStyleList {
            
            self.styleCollectionView.reloadData()
        }
        
        self.styleCollectionView.isHidden = !isShowStyleList
        self.collectionView.isHidden = isShowStyleList
        self.updateNoItemView()
        self.updateCollectionViewLayout()
    }
    
    func listStyleByCategory(_ styleFilter: StyleFilter) -> Promise<Any> {
        return Promise{ fulfill, reject in
            SearchService.searchStyle(styleFilter, pageSize: Constants.Paging.Offset, pageNo: pageNo) { [weak self] (response) in
                if let strongSelf = self {
                    if response.result.isSuccess {
                        if let styleResponse = Mapper<SearchResponse>().map(JSONObject: response.result.value) {
                            strongSelf.pageTotal = styleResponse.pageTotal
                            var availableStyles = [Style]()
                            
                            if let styles = styleResponse.pageData {
                                availableStyles = styles.filter({ $0.isAvailable() })
                            } else {
                                ErrorLogManager.sharedManager.recordNonFatalError(withException: .NullPointer)
                            }
                            
                            if availableStyles.count > 0 {
                                if strongSelf.pageNo == 1 {
                                    strongSelf.styles = availableStyles
                                } else {
                                    strongSelf.styles.append(contentsOf: availableStyles)
                                }
                                
                                strongSelf.canLoadMore = (availableStyles.count > 0)
                            } else {
                                if strongSelf.pageNo == 1 {
                                    strongSelf.styles = []
                                }
                                
                                strongSelf.canLoadMore = false
                            }
                            
                            fulfill(styleResponse)
                        } else {
                            ErrorLogManager.sharedManager.recordNonFatalError(withException: .FailToParseAPIResponse)
                            
                            fulfill("OK")
                        }
                    } else {
                        reject(response.result.error!)
                    }
                } else {
                    ErrorLogManager.sharedManager.recordNonFatalError(withException: .NullPointer)
                }
            }
        }
    }
    
    override func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return collectionView == styleCollectionView  ? self.styles.count :  self.cats.count
    }
    
    override func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        if collectionView == styleCollectionView {
            if let cell = collectionView.dequeueReusableCell(withReuseIdentifier: WishListCollectionViewCell.CellIdentifier, for: indexPath) as? WishListCollectionViewCell {
                cell.backgroundColor = UIColor.white
                
                let data = self.styles[indexPath.row]
                cell.style = data
                
                if data.selected {
                    cell.tickImageView.image = UIImage(named: "icon_checkbox_checked")
                } else {
                    cell.tickImageView.image = UIImage(named: "icon_checkbox_unchecked2")
                }
                
                cell.setStyle(data, styleFilter: self.styleFilter)
                
                if indexPath.row == self.styles.count - 1 && self.canLoadMore && self.pageTotal > self.pageNo {
                    self.loadMore()
                }
                
                self.setAccessibilityIdForView("UIBT_SELECT_PRODUCT", view: cell)
                
                return cell
            } else {
                ErrorLogManager.sharedManager.recordNonFatalError(withException: .NullPointerOrTypeMismatch)
                
                return UICollectionViewCell()
            }
        } else {
            return super.collectionView(collectionView, cellForItemAt: indexPath)
        }
    }
    
    override func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, referenceSizeForHeaderInSection section: Int) -> CGSize {
        if collectionView == styleCollectionView {
            return CGSize.zero
        } else {
            return super.collectionView(collectionView, layout: collectionViewLayout, referenceSizeForHeaderInSection: section)
        }
    }
    
    override func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, sizeForItemAt indexPath: IndexPath) -> CGSize {

        if collectionView == styleCollectionView {
            return CGSize(width: self.view.frame.size.width , height: CGFloat(100))
        } else {
            return super.collectionView(collectionView, layout: collectionViewLayout, sizeForItemAt: indexPath)
        }
    }
    
    override func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        if collectionView == styleCollectionView {
            if let delegate = delegate {
                let style = self.styles[indexPath.row]
                
                if !delegate.isEnoughPhoto() || style.selected {
                    style.selected = !style.selected
                    delegate.didSelectStyle(style)
                    self.styleCollectionView.reloadData()
                } else {
                    delegate.showErrorFull()
                }
            }
        } else {
            super.collectionView(collectionView, didSelectItemAt: indexPath)
        }
    }

    // MARK:- Notification
    
    @objc func didRemoveStyleItem(_ notification: Notification) {
        if let skuId = notification.object as? Int {
            for item in self.styles {
                if item.defaultSku()?.skuId == skuId {
                    item.selected = false
                    break
                }
            }
            
            self.styleCollectionView.reloadData()
        } else {
            ErrorLogManager.sharedManager.recordNonFatalError(withException: .NullPointerOrTypeMismatch)
        }
    }
    
    //MARK: - Analytics
    
    func initAnalytic(){
        
        let user = Context.getUserProfile()
        let authorType = user.userTypeString()
        
        initAnalyticsViewRecord(
            Context.getUserKey(),
            authorType: authorType,
            brandCode: nil,
            merchantCode: nil,
            referrerRef: nil,
            referrerType: nil,
            viewDisplayName: nil,
            viewParameters: nil,
            viewLocation: "Editor-Image-Category",
            viewRef: nil,
            viewType: "Post"
        )
    }
    
}
