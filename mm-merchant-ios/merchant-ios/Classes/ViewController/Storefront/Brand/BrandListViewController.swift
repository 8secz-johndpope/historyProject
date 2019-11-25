//
//  BrandListViewController.swift
//  merchant-ios
//
//  Created by HungPM on 5/23/17.
//  Copyright © 2017 WWE & CO. All rights reserved.
//

import Foundation
import PromiseKit
import ObjectMapper

class BrandListViewController: MmViewController, UITableViewDataSource, UITableViewDelegate, BrandImageCellDelegate {
    enum ZoneMode {
        case red
        case black
    }
    
    enum ParentPage {
        case none
        case merchantProfilePage
    }
    
    private let DefaultCellID = "DefaultCellID"
    private static let BrandListCellIdentifier = "BrandListCell"
    private static let LoadingCellIdentifier = "LoadingCell"
    private static let MaxFeaturedBrandsDisplaying = 8
    private static let PaddingFeatureBrandItem = CGFloat(10)
    var fromePost = false // 判断是否需要回调 发帖的地方
    let WidthFeatureBrandCell = (UIScreen.width() - (5 * BrandListViewController.PaddingFeatureBrandItem)) / 4
    private let Spacing = CGFloat(0)
    
    private var brandData = [String: [Brand]]()
    private var featuredBrands = [Brand]()
    
    var brandIds: [Int]? = nil
    private var titles = [String]()
    private var collectionIndexOrder: [String: Int] = [:]
    
    //    var featuredCollectionView: UICollectionView?
    var parentPage: ParentPage = .none
    var scrollViewDidScrollAction: ((UIScrollView) -> ())?
    var viewWillAppearAction: (() -> Void)?
    var viewDidAppearAction: (() -> Void)?
    
    var zoneMode = ZoneMode.red
    var viewHeight = CGFloat(0)
    var topContentInset = CGFloat(0)
    
    var didSelectBrandHandler: ((Brand) -> ())?
    var isFollowBrandList = false
    
    //MARK:- View Lifecycle
    override func viewDidLoad() {
        super.viewDidLoad()
        self.automaticallyAdjustsScrollViewInsets = true
        
        self.createBackButton()
        view.addSubview(tableView)
        setNavView()
        
        if isFollowBrandList {
            FollowService.listFollowBrand({ (response) in
                if response.result.isSuccess {
                    if response.response?.statusCode == 200 {
                        let brandList = Mapper<Brand>().mapArray(JSONObject: response.result.value) ?? []
                        var brandIdList = [Int]()
                        
                        for brand in brandList {
                            brandIdList.append(brand.brandId)
                        }
                        self.tableView.backgroundColor = UIColor.backgroundGray()
                        if brandIdList.count == 0 {
                            self.view.backgroundColor = UIColor.backgroundGray()
//                            self.tableView.backgroundColor = UIColor.backgroundGray()
                            self.noResponseView.isHidden = false
                        } else {
                            self.view.backgroundColor = UIColor.white
//                            self.tableView.backgroundColor = UIColor.white
                            self.noResponseView.isHidden = true
                        }
                        self.listBrands(brandIdList)
                    }
                }
            })
        } else {
            if let brandIds = self.brandIds {
                listBrands(brandIds)
            } else {
                listBrands()
            }
        }

        //analytic
        let viewParameters = zoneMode == .red ? "RedZone" : "BlackZone"
        initAnalyticsViewRecord(viewParameters: viewParameters, viewLocation: "AllBrands", viewType: "Brand")
    }
    
    private func setNavView() {
        if let navigationBar = self.navigationController?.navigationBar {
            searchButton.frame = CGRect(x: 0, y: 0, width: navigationBar.width*0.7, height: 35)
            navigationItem.titleView = searchButton
        }
    }
    
    @objc private func searchButtonClick() {
        let searchStyleController = SearchStyleController()
        searchStyleController.searchType = .postTagBrand
        searchStyleController.didSelectBrandHandler = { [weak self] (brand) in
            if let strongSelf = self {
                if strongSelf.fromePost {
                    if let handler = strongSelf.didSelectBrandHandler {
                        handler(brand)
                    }
                }
            }
        }
        self.navigationController?.pushViewController(searchStyleController, animated: false)
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        if let viewWillAction = viewWillAppearAction {
            viewWillAction()
        }
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        if let viewDidAction = viewDidAppearAction {
            viewDidAction()
        }
        
        //临时解决下mlp当不满一屏的情况，设置offset为0时，会与系统自动调节显示位置冲突
        if let _ = tableView.tableHeaderView, tableView.contentSize.height < ScreenHeight {
            tableView.contentSize.height = ScreenHeight
        }
    }
    
    override func shouldHaveCollectionView() -> Bool {
        return false
    }
    
    //MARK:- TableView Datasource
    
    func numberOfSections(in tableView: UITableView) -> Int {
        return titles.count
    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        let key = titles[section]
        return brandData[key]?.count ?? 0
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let key = titles[indexPath.section]
        if let cell = tableView.dequeueReusableCell(withIdentifier: "BrandListContentCell", for: indexPath) as? BrandListContentCell {
        if let brand = brandData[key]?[indexPath.row] {
            
            if self.parentPage == .merchantProfilePage {
                //analytic
                let impressionVariantRef = zoneMode == .black ? "BlackZone" : "RedZone"
                
                let viewKey = analyticsViewRecord.viewKey
                cell.initAnalytics(withViewKey: viewKey,impressionKey: AnalyticsManager.sharedManager.recordImpression(brandCode: brand.brandCode, impressionRef: "\(brand.brandId)", impressionType: "Brand", impressionVariantRef: impressionVariantRef, impressionDisplayName: brand.brandName, positionComponent: "BrandListing", positionIndex: indexPath.row + 1, positionLocation: "AllBrands", viewKey: viewKey))
            }
            
            cell.brandNameLabel.text = brand.brandName
            
            if isFollowBrandList {
                cell.cancelButton.isHidden = false 
                cell.cancelButton.setFollowButtonState(brand.followStatus)
                cell.cancelButton.whenTapped {
                    self.saveAndDeleteBrand(selectBrand: brand, isSave: !brand.followStatus, pathRow: indexPath.row, key: key)
                }
            } else {
                cell.cancelButton.isHidden = true
            }
        }
        
         return cell
        }
         return UITableViewCell()
    }
    
    func saveAndDeleteBrand(selectBrand:Brand?,isSave:Bool,pathRow:Int,key:String)  {
        if let brand = selectBrand {
            if isSave {
                FollowService.saveBrand(brand.brandId) { [weak self] (response) in
                    if let strongSelf = self {
                        if response.response?.statusCode == 200 {
                            brand.followerCount += 1
                            brand.followStatus = true
                            strongSelf.brandData[key]?[pathRow] = brand
                            strongSelf.tableView.reloadData()
                        }
                    }
                    
                }
            } else {
                FollowService.deleteBrand(brand.brandId) { [weak self] (response) in
                    if let strongSelf = self {
                        if response.response?.statusCode == 200 {
                            brand.followerCount -= 1
                            brand.followStatus = false
                            strongSelf.brandData[key]?[pathRow] = brand
                            strongSelf.tableView.reloadData()
                        }
                    }
                }
            }
        }
    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        let key = titles[indexPath.section]
        if let brand = brandData[key]?[indexPath.row] {
            //analytic
            if self.parentPage == .merchantProfilePage {
                if let cell = tableView.cellForRow(at: indexPath) {
                    cell.recordAction( .Tap, sourceRef: "\(brand.brandId)",sourceType: .Brand, targetRef: "PLP", targetType: .View)
                }
            }
            
            if fromePost || parentPage == .merchantProfilePage {
                if let handler = didSelectBrandHandler {
                    handler(brand)
                }
            } else {
                Navigator.shared.dopen(Navigator.mymm.deeplink_b_brandSubDomain + brand.brandSubdomain)
            }
        }
    }
    
    func listBrands() {
        showLoading()
        
        BrandService.fetchAllBrandsIfNeeded((self.zoneMode == .red ? .red : .black), sort: .BrandName, order: .orderedAscending).then { (brands) -> Void in
            self.brandData.removeAll()
            for brand in brands {
                var firstChar = brand.brandName.subStringToIndex(1).uppercased()
                firstChar = firstChar.isAlpha ? firstChar : "#"
                
                if self.brandData[firstChar] != nil {
                    self.brandData[firstChar]?.append(brand)
                } else {
                    self.brandData[firstChar] = [brand]
                }
            }
            
            self.titles = self.brandData.keys.sorted()
            let count = self.titles.count
            self.titles.remove("#")
            if self.titles.count < count {
                self.titles.append("#")
            }
            self.tableView.reloadData()
            self.tableView.sc_indexViewDataSource = self.titles
            }.always {
                self.stopLoading()
        }
    }
    
    func listBrands(_ brandIds: [Int]) {
        showLoading()
        BrandService.fetchAllBrandsIfNeeded(brandIds: brandIds, sort: .BrandName, order: .orderedAscending).then { (brands) -> Void in
            self.brandData.removeAll()
            for brand in brands {
                var firstChar = brand.brandName.subStringToIndex(1).uppercased()
                firstChar = firstChar.isAlpha ? firstChar : "#"
                
                if self.brandData[firstChar] != nil {
                    self.brandData[firstChar]?.append(brand)
                } else {
                    self.brandData[firstChar] = [brand]
                }
            }
            
            self.titles = self.brandData.keys.sorted()
            let count = self.titles.count
            self.titles.remove("#")
            if self.titles.count < count {
                self.titles.append("#")
            }
            self.tableView.reloadData()
            self.tableView.sc_indexViewDataSource = self.titles
            }.always {
                self.stopLoading()
        }
    }
    
    //MARK: - Featured Brand Delegate
    
    func onSelect(brand: Brand) {
        if let didseletBrand = didSelectBrandHandler {
            didseletBrand(brand)
        }
    }
    
    func onSelect(merchant: Merchant) {
    }
    
    //MARK: - ScrollView Delegate
    
    func scrollViewDidScroll(_ scrollView: UIScrollView) {
        if scrollView == self.tableView {
            if let scrollAction = scrollViewDidScrollAction {
                scrollAction(scrollView)
            }
        }
    }
    
    func tableView(_ tableView: UITableView, viewForHeaderInSection section: Int) -> UIView? {
        let headerView = UIView()
        headerView.backgroundColor = UIColor.white
        let titleLabel = UILabel()
        titleLabel.text = titles[section]
        titleLabel.textColor = UIColor.black
        titleLabel.font = UIFont.systemFont(ofSize: 22)
        headerView.addSubview(titleLabel)
        titleLabel.snp.makeConstraints { (make) in
            make.left.equalTo(headerView).offset(15)
            make.centerY.equalTo(headerView)
        }
        return headerView
    }
    
    // MARK: - lazyload
    
    public lazy var tableView: UITableView = {
        var margin:CGFloat = 20.0
        
        if isFollowBrandList {
            margin = 0.0
        }
        let tb = UITableView(frame: CGRect.init(x: 0, y: margin, width: self.view.bounds.size.width, height: self.view.bounds.size.height - margin), style: UITableViewStyle.plain)
        tb.dataSource = self
        tb.delegate = self
        tb.separatorStyle = .none
        tb.backgroundColor = UIColor.white
        tb.estimatedRowHeight = 40
        tb.rowHeight = UITableViewAutomaticDimension
        tb.sectionFooterHeight = 0.0
        tb.sectionHeaderHeight = 30
        tb.autoresizingMask = [.flexibleWidth,.flexibleHeight]
        tb.showsVerticalScrollIndicator = false
        tb.showsHorizontalScrollIndicator = false
        tb.register(BrandListContentCell.self, forCellReuseIdentifier: "BrandListContentCell")
        tb.register(LoadingTableViewCell.self, forCellReuseIdentifier: BrandListViewController.LoadingCellIdentifier)
        if topContentInset > 0 {
            tb.tableHeaderView = UIView(frame: CGRect(x: 0, y: 0, width: tb.frame.size.width, height: topContentInset))
        }
        let configuration = SCIndexViewConfiguration(indexViewStyle: SCIndexViewStyle.default)
        configuration?.indexItemSelectedBackgroundColor = UIColor(hexString: "#ED2247")
        tb.sc_indexViewConfiguration = configuration
        tb.addSubview(noResponseView)
        return tb
    }()
    
    private lazy var searchButton: UIButton = {
        let searchButton = UIButton()
        searchButton.setTitle(String.localize("LB_AC_BRAND_SEARCH"), for: UIControlState.normal)
        searchButton.setImage(UIImage(named: "search"), for: UIControlState.normal)
        searchButton.titleLabel?.font = UIFont.systemFont(ofSize: 12)
        searchButton.setTitleColor(UIColor(hexString: "#BCBCBC"), for: UIControlState.normal)
        searchButton.roundCorner(4)
        searchButton.addTarget(self, action: #selector(self.searchButtonClick), for: UIControlEvents.touchUpInside)
        searchButton.backgroundColor = UIColor.imagePlaceholder()
        searchButton.setIconInLeftWithSpacing(6)
        searchButton.sizeToFit()
        return searchButton
    }()
    private lazy var noResponseView: UIView = {
        let noResponseView = UIView()
        
        let label = UILabel()
        label.text = "没有已收藏的品牌"
        label.font = UIFont.systemFont(ofSize: 16)
        label.textColor = UIColor.secondary3()
        label.sizeToFit()
        noResponseView.addSubview(label)
        
        let imageView = UIImageView()
        imageView.image = UIImage(named: "icon_wishlist_default")
        imageView.sizeToFit()
        noResponseView.addSubview(imageView)
        
        noResponseView.frame = CGRect(x: (ScreenWidth - label.width) / 2, y: (ScreenHeight - imageView.height - label.height) / 2 - imageView.height, width: label.width, height: imageView.height + label.height + 8)
        imageView.frame = CGRect(x: (noResponseView.width - imageView.width) / 2, y: 0, width: imageView.width, height: imageView.height)
        label.frame = CGRect(x: 0, y: imageView.frame.height + 8, width: label.width, height: label.frame.height)
        noResponseView.isHidden = true
        return noResponseView
    }()
}

extension String {
    var isAlpha: Bool {
        return !isEmpty && range(of: "[^a-zA-Z]", options: .regularExpression) == nil
    }
}




