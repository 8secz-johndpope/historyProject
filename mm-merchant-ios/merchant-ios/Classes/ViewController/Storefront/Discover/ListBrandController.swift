//
//  ListBrandController.swift
//  merchant-ios
//
//  Created by LongTa on 8/29/16.
//  Copyright © 2016 WWE & CO. All rights reserved.
//

import UIKit
import PromiseKit
import ObjectMapper

class ListBrandController: MmViewController {
    
    private let HeaderHeight: CGFloat = 50
    private let ImageMenuCellHeight: CGFloat = 60
    private let SearchBarHeight: CGFloat = 40
    private let ButtonCellHeight: CGFloat = 60
    
    private var contentInset = UIEdgeInsets.zero
    
    var searchBar = UISearchBar()
    var searchString = ""
    var brands = [Brand]()
    var refreshControl = UIRefreshControl()
    
    var canLoadMore = true
    var pageNo = 1
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        setupCollectionView()
        self.edgesForExtendedLayout = UIRectEdge()
        self.title = String.localize("LB_CA_ALL_BRAND")
        
        self.searchBar.sizeToFit()
        self.searchBar.delegate = self
        self.searchBar.searchBarStyle = UISearchBarStyle.default
        self.searchBar.showsCancelButton = false
        self.searchBar.frame = CGRect(x: self.view.bounds.minX, y: self.view.bounds.minY, width: self.view.bounds.width, height: SearchBarHeight)
        self.view.insertSubview(self.searchBar, aboveSubview: self.collectionView)
        self.searchBar.placeholder = String.localize("LB_CA_SEARCH_FILTER_PLACEHOLDER")
        self.setUpRefreshControl()
        
        self.createBackButton()
        loadBrand()
        
        self.initAnalyticsViewRecord(viewDisplayName: "User : \(Context.getUsername())", viewLocation: "AllBrands", viewType: "Brand")
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        
        NotificationCenter.default.addObserver(self, selector: #selector(self.keyboardWillShow), name:NSNotification.Name.UIKeyboardWillShow, object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(self.keyboardWillHide), name:NSNotification.Name.UIKeyboardWillHide, object: nil)
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        
        NotificationCenter.default.removeObserver(self, name: NSNotification.Name.UIKeyboardWillShow, object: nil)
        NotificationCenter.default.removeObserver(self, name: NSNotification.Name.UIKeyboardWillHide, object: nil)
    }

    func setupCollectionView() {
        self.collectionView.dataSource = self
        self.collectionView.delegate = self
        self.collectionView.register(ImageMenuCell.self, forCellWithReuseIdentifier: "ImageMenuCell")
        
        if let navigationBarHeight = self.navigationController?.navigationBar.frame.height {
            self.collectionView.frame = CGRect(x: self.view.bounds.minX, y: SearchBarHeight, width: self.view.bounds.width, height: self.view.bounds.height - SearchBarHeight - UIApplication.shared.statusBarFrame.size.height - navigationBarHeight - tabBarHeight)
        }
        
        self.collectionView.contentSize = self.collectionView.bounds.size
        contentInset = self.collectionView.contentInset
    }

    func loadBrand(_ s: String = "", pageNo: Int = 1, isShowLoading: Bool = true) {

        firstly {
            return self.listBrand(s, pageNo: pageNo)
        }.then { _ -> Void in
            self.collectionView.reloadData()
        }.always {
            self.refreshControl.endRefreshing()
        }.catch { _ -> Void in
            Log.error("error")
        }
        
    }
    
    func listBrand(_ s: String = "", pageNo: Int = 1) -> Promise<Any> {
        return Promise{ fulfill, reject in
            SearchService.searchBrand(s, pageSize: Constants.Paging.Offset, pageNo: pageNo, sort: "BrandName", order: "asc") { [weak self] (response) in
                if let strongSelf = self {
                    if response.result.isSuccess {
                        strongSelf.pageNo = pageNo
                        let brands = Mapper<Brand>().mapArray(JSONObject: response.result.value) ?? []
                        
                        if pageNo == 1 {
                            strongSelf.brands.removeAll()
                        }
                        strongSelf.brands.append(contentsOf: brands)
                        
                        if brands.count == 0 {
                            strongSelf.canLoadMore = false
                            if s.length > 0 {
                                strongSelf.view.initAnalytics(withViewKey: strongSelf.analyticsViewRecord.viewKey)
                                strongSelf.view.recordAction(.Input, sourceRef: s, sourceType: .Text)
                            }
                        } else {
                            strongSelf.canLoadMore = true
                        }
                        
                        fulfill("OK")
                    } else {
                        reject(response.result.error ?? NSError(domain: "", code: 0, userInfo: nil))
                    }
                } else {
                    ErrorLogManager.sharedManager.recordNonFatalError(withException: .NullPointer)
                }
            }
        }
    }
    
    override func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        let cell = collectionView.dequeueReusableCell(withReuseIdentifier: "ImageMenuCell", for: indexPath) as! ImageMenuCell
        let brand = self.brands[indexPath.row]
        cell.upperLabel.text = brand.brandName
        cell.lowerLabel.text = brand.brandNameInvariant
        cell.marginLeftRight = 10
        cell.setImage(brand.headerLogoImage, imageCategory: .brand)
        
        if indexPath.row == self.brands.count - 1 {
            self.loadMore()
        }
        
        let impressionKey = AnalyticsManager.sharedManager.recordImpression(brandCode: brand.brandCode, impressionRef: "\(brand.brandId)", impressionType: "Brand", impressionDisplayName: brand.brandName, merchantCode: "", positionComponent: "BrandListing", positionIndex: (indexPath.row + 1), positionLocation: "AllBrands", viewKey: self.analyticsViewRecord.viewKey)
        cell.initAnalytics(withViewKey: self.analyticsViewRecord.viewKey, impressionKey: impressionKey)
        
        return cell
    }
    
    func numberOfSections(in collectionView: UICollectionView) -> Int {
        return 1
    }
    
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, minimumInteritemSpacingForSectionAt section: Int) -> CGFloat {
        return 0.0
    }
    
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, minimumLineSpacingForSectionAt section: Int) -> CGFloat {
        return 0.0
    }
    
    override func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return self.brands.count
    }
    
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, sizeForItemAt indexPath: IndexPath) -> CGSize {
        switch collectionView {
        case self.collectionView!:
            return CGSize(width: self.view.frame.size.width, height: ImageMenuCellHeight)
        default:
            return CGSize.zero
        }
    }
    
    func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        let styleFilter = StyleFilter()
        let brand = self.brands[indexPath.row]
        
        let brandViewController = BrandViewController()
        brandViewController.brand = brand
        self.navigationController?.push(brandViewController, animated: true)
        
        self.view.initAnalytics(withViewKey: self.analyticsViewRecord.viewKey)
        let targetType = AnalyticsActionRecord.ActionElement.Brand
        
        if searchString.length > 0 {
            self.view.recordAction(.Input, sourceRef: searchString, sourceType: .Text, targetRef: "\(brand.brandId)", targetType: targetType)
        } else {
            self.view.recordAction(.Tap, sourceRef: "\(brand.brandId)", sourceType: targetType, targetRef: "PLP", targetType: .View)
        }
        
        PushManager.sharedInstance.goToPLP(styleFilter: styleFilter, animated: true)
    }
    
    // MARK : Refresh Control
    
    func setUpRefreshControl(){
        self.refreshControl.addTarget(self, action: #selector(refresh(_:)), for: UIControlEvents.valueChanged)
        self.collectionView.addSubview(refreshControl)
        self.collectionView.alwaysBounceVertical = true
    }
    
    @objc func refresh(_ sender : Any){
        loadBrand(searchString, pageNo: 1, isShowLoading: true)
    }
    
    // MARK: UISearchBarDelegate
    
    private func filter(_ text : String!) {
        self.loadBrand(text, pageNo: 1, isShowLoading: true)
    }
    
    func searchBarSearchButtonClicked(_ searchBar: UISearchBar) {
        if let searchText = searchBar.text {
            self.filter(searchText)
        } else {
            ErrorLogManager.sharedManager.recordNonFatalError(withException: .NullPointer)
        }
        
        searchBar.resignFirstResponder()
    }
    
    internal func searchBar(_ searchBar: UISearchBar, textDidChange searchText: String) {
        if let searchText = searchBar.text {
            searchString = searchText
            self.loadBrand(searchString,pageNo: 1, isShowLoading: true)
        } else {
            ErrorLogManager.sharedManager.recordNonFatalError(withException: .NullPointer)
        }
    }
    
    func loadMore() {
        if canLoadMore {
            self.loadBrand(searchString, pageNo: pageNo + 1, isShowLoading: false)
        }
    }
    
    @objc func keyboardWillHide(_ sender: Notification) {
        self.collectionView.contentInset = contentInset
    }
    
    @objc func keyboardWillShow(_ sender: Notification) {
        if let userInfo = sender.userInfo {
             let keyboardSize: CGSize =  (userInfo[UIKeyboardFrameEndUserInfoKey] as! NSValue).cgRectValue.size 
                let heightOfset = ((keyboardSize.height + self.collectionView.bounds.height + 64) - self.view.bounds.size.height)
                
                if heightOfset > 0 {
                    let edgeInset = UIEdgeInsets(top: contentInset.top, left: contentInset.left, bottom: contentInset.bottom + heightOfset, right:  contentInset.right)
                    self.collectionView.contentInset = edgeInset
                }
        
        } else {
            ErrorLogManager.sharedManager.recordNonFatalError(withException: .NullPointer)
        }
    }
}
