//
//  TagProductSelectionViewController.swift
//  merchant-ios
//
//  Created by Vu Dinh Trung on 4/21/16.
//  Copyright © 2016 WWE & CO. All rights reserved.
//

import UIKit
import ObjectMapper
import PromiseKit

enum ModeTagProduct: Int {
    case wishlist = 0,
    shoppingCart,
	search,
    productListPage,
    productDetailPage,
    profilePage,
    undefine
}
protocol TagProductViewControllerDelegate:NSObjectProtocol {
    func didSelectedItemForTag(_ postCreateData: PostCreateData, mode: ModeTagProduct)
}
class TagProductSelectionViewController: FollowViewController, TagSelectionDelegate, SearchProductViewDelegage {
    private final let CatCellHeight : CGFloat = 40
    private final let SubCatCellId = "SubCatCell"
    private final let WidthItemBar : CGFloat = 30
    private final let HeightItemBar : CGFloat = 25
    private final let SearchIconWidth : CGFloat = 16
    private final let MarginLeft : CGFloat = 10
    private final let SearchBoxWidthRatio : CGFloat = 220 / 375
    
    var searchBarButtonItem : UIBarButtonItem!
    
    let tagWishlistSelectionVc = TagWishlistSelectionViewController()
    let tagShopingCartSelectionVc = TagShopingCartSelectionViewController()
    weak var tagProductDelegate : TagProductViewControllerDelegate?
    var currentMode = ModeTagProduct.wishlist
    var aggregations : Aggregations?
    var styles : [Style] = []
    private var styleFilter : StyleFilter!
    var filteredStyles : [Style] = []
    
    func setStyleFilter(_ filter: StyleFilter, isNeedSnapshot: Bool) {
        self.styleFilter = filter
        if isNeedSnapshot {
            self.styleFilter.saveSnapshot()
        }
    }
    
    override func shouldHavePageViewController() -> Bool {
        return false
    }
    
    convenience init(object: TagProductViewControllerDelegate){
        self.init(nibName: nil, bundle: nil)
        self.tagProductDelegate = object
		
		NotificationCenter.default.addObserver(self, selector: #selector(TagProductSelectionViewController.tagDataReturnedFromSearch), name: Constants.Notification.tagDataFromSearchProduct, object: nil)
    }
	
	deinit {
		NotificationCenter.default.removeObserver(self, name: Constants.Notification.tagDataFromSearchProduct, object: nil)
	}
	
    override func viewDidLoad() {
        super.viewDidLoad()
		
    }

	override func viewWillAppear(_ animated: Bool) {
		super.viewWillAppear(animated)
		
		setupNavigationBar()
		self.title = String.localize("LB_CA_SELECT_PRODUCT")
		self.styleView()
        if(segmentView.selectingTab == 0){
            showWishlist()
        }else {
            showShopingCart()
        }
        
        if self.styleFilter == nil {
            self.setStyleFilter(StyleFilter(), isNeedSnapshot: true)
        }
        
	}
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)

    }
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
	
	override func switchTab(_ index: Int) {
		switch(index) {
		case 0:
			showWishlist()
            self.segmentView.setSelectedTab(0)
			break
		case 1:
			showShopingCart()
            self.segmentView.setSelectedTab(1)
			break
		default:
			break
		}
		
	}

	
	
    //MARK: - styleView
    func setupNavigationBar() {
		
        let backButtonItem = self.createBack()
        self.searchBarButtonItem = backButtonItem
        let searchButtonItem = self.createButtonBar(
            "search_grey",
            selectorName: #selector(TagProductSelectionViewController.searchIconClicked),
            size: CGSize(width: WidthItemBar,height: 24),
            left: -30,
            right: 0
        )
        
        let space = UIBarButtonItem(barButtonSystemItem: .fixedSpace, target: nil, action: nil)
        space.width = 15
        var leftButtonItems = [space]
        leftButtonItems.append(searchButtonItem)
        
        self.navigationItem.rightBarButtonItem = backButtonItem
        self.navigationItem.leftBarButtonItems = leftButtonItems
        
    }
    
    func createBack() -> UIBarButtonItem {
        return self.createButtonBar(
            "btn_close",
            selectorName: #selector(TagProductSelectionViewController.onCloseButton),
            size: CGSize(width: WidthItemBar,height: HeightItemBar),
            left: 0,
            right: 0
        )
    }
    func createButtonBar(_ imageName: String, selectorName: Selector, size:CGSize,left: CGFloat, right: CGFloat) -> UIBarButtonItem {
        let button: UIButton = UIButton()
        button.setImage(UIImage(named: imageName), for: UIControlState())
        button.frame = CGRect(x: 0, y: 0, width: size.width, height: size.height)
        button.contentEdgeInsets = UIEdgeInsets.init(top: 0, left: left, bottom: 0, right: right)
        button.addTarget(self, action: selectorName, for: UIControlEvents.touchUpInside)
        
        let temp:UIBarButtonItem = UIBarButtonItem()
        temp.customView = button
        return temp
    }
   
    func styleView() -> Void {
        self.searchBar.removeFromSuperview()
        contentView.frame = CGRect(x: 0, y: self.segmentView.frame.maxY, width: self.view.frame.width, height: self.view.frame.height - self.segmentView.frame.maxY)
    }
    
    func showWishlist() {
        selectedIndex = ModeTagProduct.wishlist.rawValue
        setSelectedViewControler(selectedIndex)
        tagWishlistSelectionVc.tagWishlistSelectionDelegate = self
        activeViewController = tagWishlistSelectionVc
        self.currentMode = .wishlist
        self.view.endEditing(true)
    }
    
    func showShopingCart() -> Void {
        selectedIndex = ModeTagProduct.shoppingCart.rawValue
        setSelectedViewControler(selectedIndex)
        tagShopingCartSelectionVc.tagShoppingCartSelectionDelegate = self
        activeViewController = tagShopingCartSelectionVc
        self.currentMode = .shoppingCart
        self.view.endEditing(true)
    }
    
    //MARK: -handle event bar item
    @objc func onCloseButton() {
        self.dismiss(animated: true, completion: nil)
    }
    
    @objc func searchIconClicked(){
        let searchViewController = ProductListSearchViewController()
        searchViewController.getStyleDelegate = self
        self.navigationController?.pushViewController(searchViewController, animated: false)
        
//        let discoverViewController = SearchProductViewController()
//        discoverViewController.isSearch = true
//        discoverViewController.delegate = self
//        discoverViewController.isCreatingPost = true
//        self.navigationController?.push(discoverViewController, animated: false)
    }

    
    //MARK: FilterStyle Delegate
    
    //MARK: - Delegate
    func didSelectedItem(_ sku: Sku?, itemType : PostCreateData.ItemType = .unknown) {
        let postCreateData = PostCreateData()
        if let sku = sku{
            postCreateData.skus = [sku]
            postCreateData.itemType = itemType
        }
        self.tagProductDelegate?.didSelectedItemForTag(postCreateData, mode:currentMode)
        self.dismiss(animated: true, completion: nil)
    }
    @objc func tagDataReturnedFromSearch(_ noti: Notification) -> Void {
        if let data = noti.object {
            Log.debug(data)
        }
    }
    func getDataFromSearchProduct(_ style: Style) {
        self.tagProductDelegate?.didSelectedItemForTag(PostCreateData(style:style, itemType: .wishlist), mode:.wishlist)
        
        self.dismiss(animated: true) {
            self.dismiss(animated: true, completion: nil)
        }
    }

    override func createTopView(){
        super.createTopView()
        segmentView = MMSegmentView(frame: CGRect(x: 0, y: StartYPos, width: self.view.bounds.width , height: Constants.Segment.Height), tabs: [String.localize("LB_CA_WISHLIST"),String.localize("LB_CA_CART")])
        segmentView.delegate = self
        self.view.addSubview(segmentView)
        segmentView.refreshUI()
    }
    //MARK: MMSegmentViewDelegate
    override func didSelectTabAtIndex(_ tabIndex: Int) {
        currentTab = tabIndex
        switch(currentTab) {
        case 0:
            showWishlist()
            break
        case 1:
            showShopingCart()
            break
        default:
            break
        }
        self.segmentView.setSelectedTab(tabIndex)
    }
   
}
