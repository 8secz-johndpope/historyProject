//
//  ShoppingCartViewController.swift
//  merchant-ios
//
//  Created by Alan YU on 28/12/2015.
//  Copyright © 2015 Koon Kit Chan. All rights reserved.
//

import Foundation
import PromiseKit
import ObjectMapper
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


class ShoppingCartViewController: MmCartViewController, ShoppingCartPromotionViewDelegate {
    
    private final let ProductCellID = "ProductCellID"
    private final let ShoppingCartItemCellID = "ShoppingCartItemCellID"
    private final let ShoppingCartPromotionCellID = "ShoppingCartPromotionCellID"
    private final let ShoppingCartFooterViewID = "ShoppingCartFooterViewID"
	
	private let footerHeight: CGFloat = 80
    private final let SummaryViewHeight: CGFloat = 62
    
    private var promotionView: ShoppingCartPromotionView!
    private var dataSource: [ShoppingCartSectionData]!
    private var cartBannerList = [Banner]()
    private var selectAllCartItemButton: UIButton!
    private var noItemView: UIView!
    
    private var allCartItemSelected = false {
        didSet {
            self.selectAllCartItemButton.isSelected = allCartItemSelected
        }
    }
    
    private var summaryLabel: UILabel!
    private var buttonConfirmPurchase: UIButton!
    
    private var checkboxContainer: UIView!
    private var selectAllLabel: UILabel!

    private var cart: Cart?
    private var styles: [Style] = []
    private var listMerchant: [CartMerchant] = [CartMerchant]()

    private var listCartItemIdSelected : [Int] = [Int]()
    private var tapGesture: UITapGestureRecognizer!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        self.navigationController?.isNavigationBarHidden = false
        self.navigationItem.title = String.localize("LB_CA_CART")
        self.view.backgroundColor = UIColor.backgroundGray()
        
        self.tapGesture = UITapGestureRecognizer(target: self, action: #selector(ShoppingCartViewController.viewDidTap))
            
        self.promotionView = ShoppingCartPromotionView.viewWithScreenSize()
        
        setupNavigationBar()
        setupNoItemView()

        collectionView.register(UICollectionViewCell.self, forCellWithReuseIdentifier: self.ShoppingCartPromotionCellID)
        collectionView.register(ShoppingCartItemCell.self, forCellWithReuseIdentifier: self.ShoppingCartItemCellID)
        collectionView.register(ShoppingCartSectionHeaderView.self, forSupplementaryViewOfKind: UICollectionElementKindSectionHeader, withReuseIdentifier: ShoppingCartSectionHeaderView.ViewIdentifier)
        collectionView.register(UICollectionReusableView.self, forSupplementaryViewOfKind: UICollectionElementKindSectionFooter, withReuseIdentifier: ShoppingCartFooterViewID)
		
        collectionView.backgroundColor = UIColor.clear
        collectionView.alwaysBounceVertical = true
        dataSource = [ShoppingCartSectionData]()
        
        // FIXME: Delete me!!
        for section in self.dataSource {
            section.sectionSelected = self.allCartItemSelected
        }
                
        let summaryView = { () -> UIView in
            
            var bottomHeight: CGFloat = 0
            if self.navigationController?.viewControllers.count > 1 {
                bottomHeight = ScreenBottom
            }
            let frame = CGRect(x: 0, y: collectionView.frame.maxY - bottomHeight, width: collectionView.width, height: SummaryViewHeight + bottomHeight)
            
            let view = UIView(frame: frame)
            view.backgroundColor = UIColor.white
            
            let separatorView = { () -> UIView in
                let view = UIView(frame: CGRect(x: 0, y: 0, width: frame.width, height: 1))
                view.backgroundColor = UIColor.backgroundGray()
                
                return view
            } ()
            view.addSubview(separatorView)

            let checkboxContainer = { () -> UIView in
                let view = UIView(frame: CGRect(x: 0, y: 0, width: Constants.Checkbox.Size.width, height: SummaryViewHeight))
                
                let button = UIButton(type: .custom)
                button.config(
                    normalImage: UIImage(named: "icon_checkbox_unchecked"),
                    selectedImage: UIImage(named: "icon_checkbox_checked")
                )
                button.frame = CGRect(x: 0, y: 0, width: view.width, height: view.height)
                button.imageView?.sizeToFit()
                button.addTarget(self, action: #selector(ShoppingCartViewController.toggleSelectAllCartItems), for: .touchUpInside)
				view.addSubview(button)
                self.selectAllCartItemButton = button
                
                return view
            } ()
            self.checkboxContainer = checkboxContainer
            view.addSubview(checkboxContainer)
            
            let selectAllLabel = { () -> UILabel in
                let label = UILabel(frame: CGRect.zero)
                label.text = String.localize("LB_CA_SELECT_ALL_PI")
                label.formatSmall()
                label.sizeToFit()
                
                label.frame = CGRect(x: checkboxContainer.frame.maxX, y: 0, width: label.width, height: SummaryViewHeight)
                return label
            } ()
            
            selectAllLabel.isUserInteractionEnabled = true
            selectAllLabel.addGestureRecognizer(UITapGestureRecognizer(target: self, action: #selector(ShoppingCartViewController.toggleSelectAllCartItems)))
            
            self.selectAllLabel = selectAllLabel
            view.addSubview(selectAllLabel)
            
            buttonConfirmPurchase = { () -> UIButton in
                let rightPadding = CGFloat(8)
                let buttonSize = CGSize(width: 106, height: 41)
                let xPos = frame.width - buttonSize.width - rightPadding
                let yPos = (SummaryViewHeight - buttonSize.height) / 2
                
                let button = UIButton(type: .custom)
                button.frame = CGRect(x: xPos, y: yPos, width: buttonSize.width, height: buttonSize.height)
                button.setTitle(String.localize("LB_CA_CFM_PURCHASE"), for: UIControlState())
                button.addTarget(self, action: #selector(ShoppingCartViewController.confirmPurchase), for: .touchUpInside)
                button.formatPrimary()
                
                return button
            } ()
            view.addSubview(buttonConfirmPurchase)
            
            
            let summaryLabel = { () -> UILabel in
                let padding = CGFloat(15)
                let label = UILabel(frame: UIEdgeInsetsInsetRect(
                    CGRect(x: selectAllLabel.frame.maxX, y: 0, width: buttonConfirmPurchase.frame.minX - selectAllLabel.frame.maxX, height: SummaryViewHeight),
                    UIEdgeInsets(top: 0, left: padding, bottom: 0, right: padding))
                )
                label.textAlignment = .right
                label.formatSingleLine(16)
                
                return label
            } ()
            view.addSubview(summaryLabel)
            self.summaryLabel = summaryLabel
            
            return view
        } ()
        
        self.view.addSubview(summaryView)
        self.updateSummaryPrice()
        collectionView.contentInset = UIEdgeInsets(top: 0, left: 0, bottom: ScreenBottom, right: 0)
        
        self.initAnalyticLog()
	}
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        
        NotificationCenter.default.addObserver(self, selector: #selector(ShoppingCartViewController.keyboardWillShow), name: NSNotification.Name.UIKeyboardWillShow, object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(ShoppingCartViewController.keyboardWillHide), name: NSNotification.Name.UIKeyboardWillHide, object: nil)
        
        self.view.initAnalytics(withViewKey: analyticsViewRecord.viewKey)
        Context.setVisitedCart(true)
        
        self.reloadDataSource()
        
        self.showLoading()
        
        if LoginManager.getLoginState() == .validUser || (Context.anonymousShoppingCartKey() != nil && Context.anonymousShoppingCartKey() != "0") {
            listCartItem({ [weak self] in
                if let strongSelf = self {
                    
                    var selectedCartItems: [CartItem] = []
                    
                    for merchant in strongSelf.cart?.merchantList ?? []{
                        for cartItem in merchant.itemList ?? []{
                            if cartItem.selected{
                                selectedCartItems.append(cartItem)
                            }
                        }
                    }
                    
                    strongSelf.cart = CacheManager.sharedManager.cart
                    
                    for merchant in strongSelf.cart?.merchantList ?? []{
                        for cartItem in merchant.itemList ?? []{
                            cartItem.selected = selectedCartItems.contains(where: { (selectedCartItem) -> Bool in
                                return (selectedCartItem.merchantId == cartItem.merchantId && selectedCartItem.cartItemId == cartItem.cartItemId)
                            })
                        }
                    }
                    
                    firstly {
                        return BannerService.fetchBanners([.shoppingCart])
                        }.then { banners -> Void in
                            strongSelf.cartBannerList = banners
                            strongSelf.reloadDataSource()
                            strongSelf.loadSelectedCache()
                        }.always {
                            strongSelf.stopLoading()
                        }.catch { _ -> Void in
                            Log.error("error")
                    }
                } else {
                    ErrorLogManager.sharedManager.recordNonFatalError(withException: .NullPointer)
                }
            }, fail: { [weak self] in
				Log.error("error")
				
                if let strongSelf = self {
                    firstly {
                        return BannerService.fetchBanners([.shoppingCart])
                    }.then { banners -> Void in
                        strongSelf.cartBannerList = banners
                        strongSelf.reloadDataSource()
                    }.always {
                        strongSelf.stopLoading()
                    }.catch { _ -> Void in
                        Log.error("error")
                    }
                } else {
                    ErrorLogManager.sharedManager.recordNonFatalError(withException: .NullPointer)
                }
            })
        } else {
            //Only Load Banners
            firstly {
                return BannerService.fetchBanners([.shoppingCart])
            }.then { [weak self]  banners -> Void in
                if let strongSelf = self {
                    strongSelf.cartBannerList = banners
                    strongSelf.reloadDataSource()
                } else {
                    ErrorLogManager.sharedManager.recordNonFatalError(withException: .NullPointer)
                }
            }.always { [weak self] in
                if let strongSelf = self {
                    strongSelf.stopLoading()
                } else {
                    ErrorLogManager.sharedManager.recordNonFatalError(withException: .NullPointer)
                }
            }.catch { _ -> Void in
                Log.error("error")
            }
        }
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
		
		NotificationCenter.default.removeObserver(self)
    }
    
    // MARK: - Analytics
    
    func initAnalyticLog() {
        self.initAnalyticsViewRecord(viewDisplayName: "User: \(Context.getUsername())", viewParameters: "u=\(Context.getUserKey())", viewLocation: "Cart",  viewType: "Product")
    }
    
    // MARK: - Data
        
    func loadSelectedCache() {
        for section in self.dataSource {
            for row in section.dataSource {
                if type(of: row) == CartItem.self {
                    for cartItemIdSelected in listCartItemIdSelected {
                        if (row as! CartItem).cartItemId == cartItemIdSelected {
                            (row as! CartItem).selected = true
                        }
                    }
                }
            }
        }
        
        self.reloadSelectStatus()
    }
    
    func saveSelectedCache() {
        updateSelectedCartItemIdList()
        reloadSelectStatus()
    }

    func setupNavigationBar() {
        if (self.navigationController?.viewControllers.count)! > 1 {
            createBackButton()
        }
        self.navigationItem.rightBarButtonItems = [UIBarButtonItem.messageButtonItem(self, action: #selector(self.openChatView))]
    }
    
    private func setupNoItemView() {
        let noOrderViewSize = CGSize(width: 90, height: 100)
        noItemView = UIView(frame: CGRect(x: (view.width - noOrderViewSize.width) / 2, y: (collectionView.height + 163 - noOrderViewSize.height) / 2, width: noOrderViewSize.width, height: noOrderViewSize.height))
        noItemView.isHidden = true
        
        let boxImageViewSize = CGSize(width: 80, height: 70)
        let boxImageView = UIImageView(frame: CGRect(x: (noItemView.width - boxImageViewSize.width) / 2, y: 0, width: boxImageViewSize.width, height: boxImageViewSize.height))
        boxImageView.image = UIImage(named: "cart_blank_icon")
        noItemView.addSubview(boxImageView)
        
        let label = UILabel(frame: CGRect(x: 0, y: boxImageView.height + 10, width: noOrderViewSize.width, height: 20))
        label.textAlignment = .center
        label.formatSize(16)
        label.textColor = UIColor.secondary3()
        label.text = String.localize("LB_CA_CART_NOITEM")
        noItemView.addSubview(label)
        
        view.addSubview(noItemView)
    }
    
    @objc func toggleSelectAllCartItems(_ button: UIButton) {
        allCartItemSelected = !allCartItemSelected
        
        for section in self.dataSource {
            section.sectionSelected = allCartItemSelected
        }
        
        self.updateSelectedCartItemIdList()
        
        self.cartItemSelectDidChanged()
        
        self.view.recordAction(.Tap, sourceRef: (allCartItemSelected ? "Checked-All" : "Unchecked-All"), sourceType: .Button, targetRef: "Cart", targetType: .View)
    }
    
    func cartItemSelectDidChanged() {
        self.updateSummaryPrice()
        self.collectionView.reloadData()
    }
    
    func updateSummaryPrice() {
        var sum: Double = 0
        var numOfItems = 0
        
        for section in self.dataSource {
            for row in section.dataSource {
                if type(of: row) == CartItem.self {
                    let item = row as! CartItem
                    if item.selected {
                        sum += item.price() * Double(item.qty)
                        numOfItems += item.qty
                    }
                }
            }
        }
        
        if numOfItems > 0 {
            buttonConfirmPurchase.isEnabled = true
            buttonConfirmPurchase.formatPrimary()
        } else {
            buttonConfirmPurchase.isEnabled = false
            buttonConfirmPurchase.formatDisable()
        }
        
        let saleFont = UIFont.systemFont(ofSize: 14)
        
        let attString = NSMutableAttributedString()

        let numberString = NSAttributedString(
            string: String.localize("LB_SELECTED_PI_NO") + "(" + (numOfItems.formatQuantity() ?? "") + ") ",
            attributes: [
                NSAttributedStringKey.foregroundColor: UIColor.secondary2(),
                NSAttributedStringKey.font: saleFont
            ]
        )
        attString.append(numberString)
    
        let priceString = NSAttributedString(
            string: sum.formatPrice() ?? "",
            attributes: [
                NSAttributedStringKey.foregroundColor: UIColor.primary3(),
                NSAttributedStringKey.font: saleFont
            ]
        )
        attString.append(priceString)

        self.summaryLabel.attributedText = attString
    }
    
    func searchStyle(withStyleCodes styleCodes: [String], merchantIds: [String]) -> Promise<Any> {
        return Promise{ fulfill, reject in
            SearchService.searchStyleByStyleCodeAndMechantId(styleCodes.joined(separator: ","), merchantIds: merchantIds.joined(separator: ",")) { [weak self] (response) in
                if let strongSelf = self {
                    if response.result.isSuccess {
                        if let response = Mapper<SearchResponse>().map(JSONObject: response.result.value), let styles = response.pageData {
                            strongSelf.styles = styles
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
            }
        }
    }
    
    func reloadDataSource() {
        self.dataSource.removeAll()
        if cartBannerList.count > 0 { // 判断无广告时 不出现广告位
            self.dataSource.append(ShoppingCartSectionData(sectionHeader: nil, reuseIdentifier: self.ShoppingCartPromotionCellID, dataSource: [self.promotionView]))
        }
        var invalidCartItems = [CartItem]()
        
        if let merchants = self.cart?.merchantList {
            for merchant in merchants {
                if let itemList = merchant.itemList {
                    for currentItem in itemList {
                        
                        if currentItem.isOutOfStock() || !currentItem.isProductValid() {
                            invalidCartItems.append(currentItem)
                            merchant.itemList?.remove(currentItem)
                        }
                    }
                    
                    if merchant.itemList?.count > 0 {
                        let data = ShoppingCartSectionData(sectionHeader: [], reuseIdentifier: self.ShoppingCartItemCellID, dataSource: merchant.itemList!)
                        data.merchant = merchant
                        self.dataSource.append(data)
                    } else {
                        self.cart?.merchantList?.remove(merchant)
                    }
                } else {
                    ErrorLogManager.sharedManager.recordNonFatalError(withException: .NullPointer)
                }
            }
        }
        
        // Show invalid / out of stock in the last section
        if invalidCartItems.count > 0 {
            let invalidCartItemSection = ShoppingCartSectionData(sectionHeader: [], reuseIdentifier: self.ShoppingCartItemCellID, dataSource: invalidCartItems)
            self.dataSource.append(invalidCartItemSection)
        }

        let hasItemInCart = (dataSource.count >= 1)
        let hasValidItemInCart = (cart?.merchantList?.count > 0)
        
        checkboxContainer.isHidden = !hasValidItemInCart
        selectAllLabel.isHidden = !hasValidItemInCart
        
        noItemView.isHidden = hasItemInCart
        collectionView.alwaysBounceVertical = hasItemInCart
        
        collectionView.reloadData()
    }
    
    @objc private func openChatView() {
        Navigator.shared.dopen(Navigator.mymm.imLanding)
    }
    
    @objc func viewDidTap() {
        self.view.endEditing(true)
    }
    
    @objc func confirmPurchase(_ sender: UIButton) {
        sender.isEnabled = false
        sender.formatDisable()
        if validateCartData() {
            updateSelectedCartItemIdList()
            
            if LoginManager.getLoginState() == .validUser {
                prepareDataForCheckout(completion: { [weak self] (selectedSkus, styles, referrerUserKeys) in
                    if let strongSelf = self {
                        if styles.count > 0 {
                            let checkoutViewController = FCheckoutViewController(checkoutMode: .cartCheckout, skus: selectedSkus, styles: styles, referrerUserKeys: referrerUserKeys, targetRef: "Cart")
                            strongSelf.navigationController?.push(checkoutViewController, animated: true)
                        } else {
                            strongSelf.showError(String.localize("MSG_CA_ERR_SKU_INVALID"), animated: true)
                        }
                    } else {
                        ErrorLogManager.sharedManager.recordNonFatalError(withException: .NullPointer)
                    }
                    sender.isEnabled = true
                    sender.formatPrimary()
                })
            } else {
                LoginManager.goToLogin()
            }
        }
        self.view.recordAction(.Tap, sourceRef: "ConfirmPurchase", sourceType: .Button, targetRef: "OrderConfirmation", targetType: .View)
    }
    
    // Validation and showing error dialog
    
    func validateCartData() -> Bool {
        for section in self.dataSource {
            for row in section.dataSource {
                if type(of: row) == CartItem.self {
                   let currentCartItem = row as! CartItem
                    if currentCartItem.selected {
                        if currentCartItem.isOutOfStock() {
                            self.showError(String.localize("LB_CA_PDP_SOLD_OUT_MESSAGE"), animated: true)
                            return false
                        }
                    }
                }
            }
        }
        
        return true
    }
    
    func numberOfSections(in collectionView: UICollectionView) -> Int {
        return dataSource.count
    }
    
    override func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return dataSource[section].dataSource.count
    }
    
    override func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        let sectionData = self.dataSource[indexPath.section]
        let data = sectionData.dataSource[indexPath.row]
        let cell = collectionView.dequeueReusableCell(withReuseIdentifier: sectionData.reuseIdentifier, for: indexPath)
        
        //if type(of: data) == ShoppingCartPromotionView.self {
        if sectionData.reuseIdentifier == ShoppingCartPromotionCellID {
            self.promotionView.cartBannerList = self.cartBannerList
            self.promotionView.delegate = self
            self.promotionView.initAnalytics(withViewKey: analyticsViewRecord.viewKey)
            cell.addSubview(self.promotionView)
            
        } else if let data = data as? CartItem {
            let edit = { [weak self] (data: CartItem) in
                if let strongSelf = self {
                    let checkoutViewController = FCheckoutViewController(checkoutMode: .updateStyle, merchant: nil, cartItem: data, referrer: data.userKeyReferrer, redDotButton: strongSelf.buttonCart)
                    
                    checkoutViewController.didDismissHandler = { [weak self] confirmed, _ in
                        if !confirmed {
                            return
                        }
                        
                        if let strongSelf = self {
                            if LoginManager.getLoginState() == .validUser || (Context.anonymousShoppingCartKey() != nil && Context.anonymousShoppingCartKey() != "0") {
                                strongSelf.showLoading()
                                
                                strongSelf.listCartItem({
                                    strongSelf.cart = CacheManager.sharedManager.cart
                                    strongSelf.allCartItemSelected = false
                                    strongSelf.reloadDataSource()
                                    strongSelf.loadSelectedCache()
                                    strongSelf.stopLoading()
                                }, fail: {
                                    strongSelf.stopLoading()
                                    Log.error("error")
                                })
                            }
                            
                            strongSelf.reloadSelectStatus()
                        } else {
                            ErrorLogManager.sharedManager.recordNonFatalError(withException: .NullPointer)
                        }
                    }
                    
                    strongSelf.saveSelectedCache()
                    
                    let navigationController = MmNavigationController()
                    navigationController.viewControllers = [checkoutViewController]
                    navigationController.modalPresentationStyle = .overFullScreen
                    
                    strongSelf.present(navigationController, animated: false, completion: nil)
                } else {
                    ErrorLogManager.sharedManager.recordNonFatalError(withException: .NullPointer)
                }
            }
            
            let itemCell = cell as! ShoppingCartItemCell
            let cartItem = self.dataSource[indexPath.section].dataSource[indexPath.row] as? CartItem
            
            let wishlistMenuCell = SwipeActionMenuCellData(
                text: String.localize("LB_CA_MOVE2WISHLIST"),
                icon: UIImage(named: "icon_swipe_addToWishlist"),
                backgroundColor: UIColor.swipeActionColor.backgroundColor(swipeActionType: .add),
                defaultAction: true,
                action: { [weak self, data] () -> Void in
                    if let strongSelf = self {
                        strongSelf.indexPathForData(data, found: { (indexPath) in
                            let sectionData = strongSelf.dataSource[indexPath.section]
                            
                            if let cartItem = sectionData.dataSource[indexPath.row] as? CartItem {
                                strongSelf.saveSelectedCache()
                                
                                strongSelf.moveItemToWishlist(cartItem.cartItemId, isSpecificSku: true, success: {
                                    strongSelf.showSuccessPopupWithText(String.localize("LB_CA_MOVE2WISHLIST_SUCCESS"))
                                    strongSelf.cart = CacheManager.sharedManager.cart
                                    strongSelf.reloadDataSource()
                                    strongSelf.loadSelectedCache()
                                    strongSelf.updateButtonWishlistState()
                                }, fail: {
                                    strongSelf.showErrorAlert(String.localize("LB_CA_MOVE2WISHLIST_FAILED"))
                                })
                                
                                itemCell.recordAction(.Tap, sourceRef: "MoveToCollection", sourceType: .Button, targetRef: "Collection-Product", targetType: .View)
                            } else {
                                ErrorLogManager.sharedManager.recordNonFatalError(withException: .NullPointerOrTypeMismatch)
                            }
                        })
                    } else {
                        ErrorLogManager.sharedManager.recordNonFatalError(withException: .NullPointer)
                    }
                }
            )
            
            let editMenuCell = SwipeActionMenuCellData(
                text: String.localize("LB_CA_EDIT"),
                icon: UIImage(named: "icon_swipe_edit"),
                backgroundColor: UIColor.swipeActionColor.backgroundColor(swipeActionType: .edit),
                action: {
                    edit(data)
                    itemCell.recordAction(.Tap, sourceRef: "Edit", sourceType: .Button, targetRef: "Cart-EditItem", targetType: .View)
                }
            )
            
            let deleteMenuCell = SwipeActionMenuCellData(
                text: String.localize("LB_CA_DELETE"),
                icon: UIImage(named: "icon_swipe_delete"),
                backgroundColor: UIColor.swipeActionColor.backgroundColor(swipeActionType: .delete),
                defaultAction: true,
                action: { [weak self, data] () -> Void in
                    if let strongSelf = self {
                        Alert.alert(strongSelf, title: "", message: String.localize("MSG_CA_CONFIRM_REMOVE"), okActionComplete: { () -> Void in
                            strongSelf.indexPathForData(data, found: { (indexPath) in
                                let sectionData = strongSelf.dataSource[indexPath.section]
                                
                                if let cartItem = sectionData.dataSource[indexPath.row] as? CartItem {
                                    strongSelf.saveSelectedCache()
                                    
                                    strongSelf.removeCartItem(cartItem.cartItemId, success: {
                                        strongSelf.showSuccessPopupWithText(String.localize("LB_CA_DEL_CART_ITEM_SUCCESS"))
                                        strongSelf.cart = CacheManager.sharedManager.cart
                                        strongSelf.reloadDataSource()
                                        strongSelf.loadSelectedCache()
                                    }, fail: {
                                        strongSelf.showErrorAlert(String.localize("LB_CA_CART_ITEM_FAILED"))
                                    })
                                } else {
                                    ErrorLogManager.sharedManager.recordNonFatalError(withException: .NullPointerOrTypeMismatch)
                                }
                            })
                        })
                        itemCell.recordAction(.Tap, sourceRef: "Delete", sourceType: .Button, targetRef: "Cart", targetType: .View)
                    } else {
                        ErrorLogManager.sharedManager.recordNonFatalError(withException: .NullPointer)
                    }
                }
            )
            
            if cartItem!.isProductValid() {
                itemCell.leftMenuItems = [wishlistMenuCell]
                itemCell.rightMenuItems = [editMenuCell, deleteMenuCell]
            } else {
                itemCell.leftMenuItems = []
                itemCell.rightMenuItems = [deleteMenuCell]
            }
            
            itemCell.editHandler = { (data) in
                edit(data)
                itemCell.recordAction(.Tap, sourceRef: "Edit", sourceType: .Button, targetRef: "Cart-EditItem", targetType: .View)
            }
            
            itemCell.cartItemSelectHandler = { [weak self] (cartItem) in
                if let strongSelf = self {
                    strongSelf.handleCartItemSelected(cartItem)
                    itemCell.recordAction(.Tap, sourceRef: (cartItem.selected ? "Checked-Product" : "Unchecked-Product"), sourceType: .Button, targetRef: "Cart", targetType: .View)
                } else {
                    ErrorLogManager.sharedManager.recordNonFatalError(withException: .NullPointer)
                }
            }
            
            itemCell.productCellHandler = { [weak self] (data) in
                if let strongSelf = self {
                    if data.isProductValid() {
                        strongSelf.showProductDetailPage(cartItem: data)
                    } else {
                        let styleViewController = StyleViewController(isProductActive: false)
                        
                        strongSelf.navigationController?.isNavigationBarHidden = false
                        strongSelf.navigationController?.push(styleViewController, animated: true)
                    }
                } else {
                    ErrorLogManager.sharedManager.recordNonFatalError(withException: .NullPointer)
                }
                
                itemCell.recordAction(.Tap, sourceRef: data.styleCode, sourceType: .Product, targetRef: "PDP", targetType: .View)
            }

            itemCell.data = cartItem
            itemCell.accessibilityIdentifierIndex(indexPath.row)
            
            if let cartData = cartItem {
                itemCell.initAnalytics(withViewKey: self.analyticsViewRecord.viewKey, impressionKey: AnalyticsManager.sharedManager.recordImpression(brandCode: "\(cartData.brandCode)", impressionRef: cartData.styleCode, impressionType: "Product", impressionVariantRef: "\(cartData.skuCode)", impressionDisplayName: cartData.skuName, merchantCode: "", positionComponent: "ProductListing", positionIndex: indexPath.row + 1, positionLocation: "Cart", viewKey: self.analyticsViewRecord.viewKey))
            } else {
                ErrorLogManager.sharedManager.recordNonFatalError(withException: .NullPointer)
            }
            
        }
        
        return cell
    }
    
    func showProductDetailPage(cartItem:CartItem) {
        self.showLoading()
        
        SearchService.searchStyleBySkuId(cartItem.skuId) { [weak self] (response) in
            if let strongSelf = self {
                strongSelf.stopLoading()
                
                if response.result.isSuccess {
                    if response.response?.statusCode == 200 {
                        if let styleResponse = Mapper<SearchResponse>().map(JSONObject: response.result.value) {
                            if let pageData = styleResponse.pageData {
                                if pageData.count > 0 {
                                    if let style = pageData.first {
                                        let color = Color()
                                        color.colorId = cartItem.colorId
                                        color.colorKey = cartItem.colorKey
                                        color.skuColor = cartItem.skuColor
                                        
                                        let size = Size()
                                        size.sizeId = cartItem.sizeId
                                        
                                        let styleFilter = StyleFilter()
                                        styleFilter.colors = [color]
                                        styleFilter.sizes = [size]
                                        
                                        let styleViewController = StyleViewController(style: style, styleFilter: styleFilter)
                                        
                                        strongSelf.navigationController?.isNavigationBarHidden = false
                                        strongSelf.navigationController?.pushViewController(styleViewController, animated: true)
                                    } else {
                                        ErrorLogManager.sharedManager.recordNonFatalError(withException: .NullPointer)
                                    }
                                } else {
                                    let styleViewController = StyleViewController(isProductActive: false)
                                    
                                    strongSelf.navigationController?.isNavigationBarHidden = false
                                    strongSelf.navigationController?.pushViewController(styleViewController, animated: true)
                                }
                            } else {
                                ErrorLogManager.sharedManager.recordNonFatalError(withException: .NullPointer)
                            }
                        } else {
                            ErrorLogManager.sharedManager.recordNonFatalError(withException: .FailToParseAPIResponse)
                        }
                    }
                }
            } else {
                ErrorLogManager.sharedManager.recordNonFatalError(withException: .NullPointer)
            }
        }
    }
    
    func reloadSelectStatus() {
        var allSelected = true
        var count = 0
        
        for section in self.dataSource {
            count += section.cartItemCount
            
            if !section.sectionSelected {
                allSelected = false
                break
            }
        }
        
        self.allCartItemSelected = allSelected && count > 0
        self.cartItemSelectDidChanged()
    }
    @discardableResult
    func indexPathForData(_ data: CartItem, found: ((_ indexPath: IndexPath) -> Void)) -> IndexPath? {
        var indexPath: IndexPath!
        section: for section in 0..<self.dataSource.count {
            for row in 0..<self.dataSource[section].dataSource.count {
                if let item = self.dataSource[section].dataSource[row] as? CartItem {
                    
                    if ObjectIdentifier(item) == ObjectIdentifier(data) {
                        indexPath = IndexPath(row: row, section: section)
                        found(indexPath)
                        
                        break section
                    }
                }
            }
        }
        
        return indexPath
    }
    
    func listDataSelected() -> [ShoppingCartSectionData] {
        var listData = [ShoppingCartSectionData]()
        
        if let merchantList = self.cart?.merchantList {
            for merchant in merchantList {
                if let itemList = merchant.itemList {
                    var cartItems = [CartItem]()
                    
                    for cartItem in itemList {
                        if listCartItemIdSelected.contains(cartItem.cartItemId) {
                            cartItems.append(cartItem)
                        }
                    }
                    
                    if !cartItems.isEmpty {
                        let data = ShoppingCartSectionData(sectionHeader: [], sectionFooter: [], reuseIdentifier: ProductCellID, dataSource: cartItems)
                        data.merchant = merchant
                        data.commentText = CheckoutCommentCell.CommentPlaceholder
                        data.commentBoxColor = UIColor.secondary3()
                        data.fapiaoText = ""
                        listData.append(data)
                    }
                } else {
                    ErrorLogManager.sharedManager.recordNonFatalError(withException: .NullPointer)
                }
            }
        }

        return listData
    }
    
    func prepareDataForCheckout(completion: @escaping (_ selectedSkus: [Sku], _ styles: [Style], _ referrerUserKeys: [String : String]) -> Void) {
        var selectedCartItems = [CartItem]()
        var referrerUserKeys = [String : String]()
        
        var merchantIds = [String]()
        if let merchants = self.cart?.merchantList {
            for merchant in merchants {
                if let cartItems = merchant.itemList {
                    for cartItem in cartItems {
                        if listCartItemIdSelected.contains(cartItem.cartItemId) {
                            selectedCartItems.append(cartItem)
                        }
                    }
                } else {
                    ErrorLogManager.sharedManager.recordNonFatalError(withException: .NullPointer)
                }
                let merchantId = String(merchant.merchantId)
                if !merchantIds.contains(merchantId) {
                    merchantIds.append(merchantId)
                }
            }
        }
        
        let styleCodes = selectedCartItems.map({ $0.styleCode })
        
        CheckoutService.defaultService.searchStyle(withStyleCodes: styleCodes, merchantIds: merchantIds).then { (styles) -> Void in
            var selectedSkus = [Sku]()
            var selectedStyles = [Style]()
            
            if styles.count > 0 {
                for selectedCartItem in selectedCartItems {
                    var selectedSku: Sku?
                    var selectedStyle: Style?
                    
                    for style in styles {
                        if style.merchantId == selectedCartItem.merchantId {
                            let thisStyle = style.copy()
                            
                            for sku in thisStyle.skuList {
                                if sku.skuCode == selectedCartItem.skuCode {
                                    sku.qty = selectedCartItem.qty
                                    sku.brandName = selectedCartItem.brandName
                                    selectedSku = sku
                                    selectedStyle = thisStyle
                                    break
                                }
                            }
                            
                            if selectedSku != nil && selectedStyle != nil{
                                break
                            }
                        }
                    }
                    
                    if let selectedSku = selectedSku {
                        selectedSkus.append(selectedSku)
                    }
                    
                    if let selectedStyle = selectedStyle {
                        selectedStyles.append(selectedStyle)
                    }
                    
                    if let referrerUserKey = selectedCartItem.userKeyReferrer, referrerUserKey.length > 0 {
                        referrerUserKeys["\(selectedCartItem.skuId)"] = referrerUserKey
                    }
                }
            } else {
                ErrorLogManager.sharedManager.recordNonFatalError(withException: .DataIsEmpty)
            }
            
            completion(selectedSkus, selectedStyles, referrerUserKeys)
        }
    }
    
    // MARK: CollectionView
    
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, referenceSizeForHeaderInSection section: Int) -> CGSize {
        let sectionData = self.dataSource[section]
        
        //Invalid section don't need to show merchant / brand header view
        if sectionData.merchant == nil {
            return CGSize.zero
        }
        
        if sectionData.sectionHeader != nil && sectionData.dataSource.count > 0 {
            return CGSize(width: view.width, height: ShoppingCartSectionHeaderView.DefaultHeight)
        }
        
        return CGSize.zero
    }
    
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, referenceSizeForFooterInSection section: Int) -> CGSize {
        if section < dataSource.count - 1 {
            return CGSize(width: view.width, height: 10)
        }
        
        return CGSize.zero
    }
    
    func collectionView(_ collectionView: UICollectionView, viewForSupplementaryElementOfKind kind: String, at indexPath: IndexPath) -> UICollectionReusableView {
		if kind == UICollectionElementKindSectionHeader {
            let view = collectionView.dequeueReusableSupplementaryView(ofKind: kind, withReuseIdentifier: ShoppingCartSectionHeaderView.ViewIdentifier, for: indexPath) as! ShoppingCartSectionHeaderView
            view.data = self.dataSource[indexPath.section]
            
            view.cartItemSelectHandler = { [weak self] (shoppingCartSectionData) in
                if let strongSelf = self {
                    strongSelf.handleCartMerchantSelected(shoppingCartSectionData.merchant)
                    view.recordAction(.Tap, sourceRef: (view.selectAllCartItemButton.isSelected ? "Checked-Merchant" : "Unchecked-Merchant"), sourceType: .Button, targetRef: "Cart", targetType: .View)
                } else {
                    ErrorLogManager.sharedManager.recordNonFatalError(withException: .NullPointer)
                }
            }
            
            view.viewCouponHandler = { [weak self] (merchant) in
                if let _ = self {
                    Navigator.shared.dopen(Navigator.mymm.website_coupon_center + "\(merchant.merchantId)")
                    // record action
                    view.recordAction(.Tap, sourceRef: "Cart-MerchantCouponClaimList", sourceType: .Button, targetRef: "MerchantCouponClaimList", targetType: .View)
                }
            }
            
            view.headerTappedHandler = { (data) in
                
                if let cartMerchant = data.merchant {
                    let merchant = Merchant()
                    merchant.merchantId = cartMerchant.merchantId
                    
                    Navigator.shared.dopen(Navigator.mymm.website_merchant_merchantId + "\(merchant.merchantId)")
                    
                    
                    if let merchant = view.data?.merchant {
                        view.recordAction(.Tap, sourceRef: "\(merchant.merchantId)", sourceType: .Merchant, targetRef: "MPP", targetType: .View)
                    } else {
                        ErrorLogManager.sharedManager.recordNonFatalError(withException: .NullPointer)
                    }
                } else {
                    ErrorLogManager.sharedManager.recordNonFatalError(withException: .NullPointer)
                }
            }
            
            if let merchant = view.data?.merchant {
                let cachedMerchant = CacheManager.sharedManager.cachedMerchantForId(merchant.merchantId)
                view.initAnalytics(withViewKey: self.analyticsViewRecord.viewKey, impressionKey: AnalyticsManager.sharedManager.recordImpression( impressionRef: "\(merchant.merchantId)", impressionType: "Merchant", impressionDisplayName: merchant.merchantName, merchantCode: cachedMerchant?.merchantCode, positionComponent: "ProductListing", positionIndex: indexPath.section + 1, positionLocation: "Cart", viewKey: self.analyticsViewRecord.viewKey))
            } else {
                ErrorLogManager.sharedManager.recordNonFatalError(withException: .NullPointer)
            }
            
            return view
        } else if kind == UICollectionElementKindSectionFooter {
            let view = collectionView.dequeueReusableSupplementaryView(ofKind: kind, withReuseIdentifier: ShoppingCartFooterViewID, for: indexPath)
            return view
        }
        
        return UICollectionReusableView()
    }
	
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, minimumInteritemSpacingForSectionAt section: Int) -> CGFloat {
        return 0.0
    }
    
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, minimumLineSpacingForSectionAt section: Int) -> CGFloat {
        return 0.0
    }
    
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, sizeForItemAt indexPath: IndexPath) -> CGSize {
        let sectionData = self.dataSource[indexPath.section]
        let data = sectionData.dataSource[indexPath.row]
        var height = CGFloat(0)
        
        //if type(of: data) == ShoppingCartPromotionView.self {
        if sectionData.reuseIdentifier == ShoppingCartPromotionCellID {
            height = (data as! UIView).bounds.size.height
        } else {
            height = ShoppingCartItemCell.DefaultHeight
            
            if let cartItem = data as? CartItem {
                if !cartItem.isProductValid() {
                    //Reduce height for action button when cart item is invalid
                    height = height - 20
                }
            } else {
                ErrorLogManager.sharedManager.recordNonFatalError(withException: .NullPointerOrTypeMismatch)
            }
        }
        
        return CGSize(width: view.width, height: height)
    }

    override func collectionViewBottomPadding() -> CGFloat {
        return SummaryViewHeight
    }
    
    // MARK: - Keyboard Delegate
    
    @objc func keyboardWillShow(_ notification: Notification) {
        self.navigationController?.view.addGestureRecognizer(tapGesture)
    }
    
    @objc func keyboardWillHide(_ notification: Notification) {
         self.navigationController?.view.removeGestureRecognizer(tapGesture)
    }
    
    //MARK: - Banner Cell Delegate
    
    func didSelectBanner(_ banner: Banner) {
        if banner.link.contains(Constants.MagazineCoverList) {
            // open as magazine cover list
            if LoginManager.isLoggedInErrorPrompt() {
                let magazineCollectionViewController = MagazineCollectionViewController()
                self.navigationController?.push(magazineCollectionViewController, animated: true)
            }
        } else {
            Navigator.shared.dopen(banner.link)
        }
    }
    
    //MARK: - CartItem selected
    
    private func updateSelectedCartItemIdList(){
        listCartItemIdSelected.removeAll()
        
        for sectionItem in self.dataSource {
            for rowItem in sectionItem.dataSource {
                if let cartItem = rowItem as? CartItem{
                    if cartItem.selected{
                       listCartItemIdSelected.append(cartItem.cartItemId)
                    }
                }
            }
        }
    }
    
    private func updateAllCartItemsSelected(){
        var isSelectedAll = true
        var count = 0
        for (_, section) in self.dataSource.enumerated() {
            count += section.cartItemCount
            
            if !section.sectionSelected {
                isSelectedAll = false
                break
            }
        }
        
        self.allCartItemSelected = isSelectedAll && count > 0
    }
    
    private func handleCartMerchantSelected(_ cartMerchant: CartMerchant?){
        guard let cartMerchant = cartMerchant else{
            return
        }
        
        let sectionIndex = self.getSectionIndex(cartMerchant)
        
        reloadSection(sectionIndex)
        
        updateAllCartItemsSelected()
        updateSummaryPrice()
    }
    
    private func handleCartItemSelected(_ cartItem: CartItem){
        let sectionIndex = self.getSectionIndex(cartItem)
        
        reloadSection(sectionIndex)
        
        updateAllCartItemsSelected()
        updateSummaryPrice()
    }
    
    //MARK: - Helpers
    
    private func reloadSection(_ sectionIndex: Int){
        let numberOfSections = self.collectionView.numberOfSections
        guard sectionIndex >= 0 && sectionIndex < numberOfSections else {
            return
        }
        
        UIView.setAnimationsEnabled(false)
        self.collectionView.performBatchUpdates({
            self.collectionView.reloadSections(IndexSet(integer: sectionIndex))
            }, completion: { (completed) in
                UIView.setAnimationsEnabled(true)
        })
    }
    
    private func getSectionIndex(_ cartItem: CartItem) -> Int{
        var section = -1
        for (sectionIndex, sectionItem) in self.dataSource.enumerated() {
            for (_, rowItem) in sectionItem.dataSource.enumerated(){
                if let rowCartItem = rowItem as? CartItem{
                    if rowCartItem.merchantId == cartItem.merchantId && rowCartItem.skuId == cartItem.skuId{
                        section = sectionIndex
                        return section
                    }
                }
            }
        }
        
        return section
    }
    
    private func getSectionIndex(_ cartMerchant: CartMerchant?) -> Int{
        var section = -1
        
        guard let cartMerchant = cartMerchant else {
            return section
        }
        
        for (sectionIndex, sectionItem) in self.dataSource.enumerated() {
            if cartMerchant.merchantId == sectionItem.merchant?.merchantId{
                section = sectionIndex
                return section
            }
        }
        
        return section
    }
}

