//
//  WishListCartViewController.swift
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


class WishListCartViewController: MmCartViewController {

    enum IndexPathSection: Int {
        case header
    }
	
	private final let NoCollectionItemCellID = "NoCollectionItemCellID"
    private final let SeperatorHeaderViewID = "SeperatorHeaderViewID"
	private final let SeperatorFooterViewID = "SeperatorFooterViewID"
    
	private let footerHeight: CGFloat = 80
    private final let CellHeight: CGFloat = 100
	
    private var dataSource = [[CartItem]]()
    var wishlist: Wishlist?
    var cartItems = [CartItem]()
    private var styles: [Style] = []
	private var validCartItems = [CartItem]()
    private var invalidCartItems = [CartItem]()
    
    var viewHeight: CGFloat = 0
    
    var isAppeared = false
	var firstLoaded = false
    var listMerchants: [Int : Merchant] = [Int : Merchant]()
    
    var floatingActionButton: MMFloatingActionButton?
    private var noItemView: UIView?
    
    var thankYouPageDelayAction: DelayAction?
    var checkoutActionSheetDelayAction: DelayAction?
    
    override func viewDidLoad() {
        super.viewDidLoad()
		
        self.view.backgroundColor = UIColor.backgroundGray()
		initAnalyticLog()
		setupCollectionView()
        setupStyleActionButton()
        
        self.dataSource = [[CartItem]]()
        
        
    }
	
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        Context.setVisitedWishlist(true)
    }
    
	override func viewDidAppear(_ animated: Bool) {
		super.viewDidAppear(animated)
		
		isAppeared = true
		refreshWishList()

		self.showFloatingActionButton(self.dataSource.count > 0 && currentType == .Private)
	}

	override func viewWillDisappear(_ animated: Bool) {
		super.viewWillDisappear(animated)
        
		isAppeared = false
		showFloatingActionButton(false)
	}
    
    // MARK: - Style action button
    
    func setupStyleActionButton() {
        let buttonMargin: CGFloat = 16
        let buttonSize = CGSize(width: 56, height: 56)
        
        let floatingActionButton = MMFloatingActionButton()
        floatingActionButton.frame = CGRect(x: view.width - buttonSize.width - buttonMargin, y: view.height - buttonSize.height - buttonMargin - self.tabBarHeight, width: buttonSize.width, height: buttonSize.height)
        floatingActionButton.mmFloatingActionButtonDelegate = self
        floatingActionButton.tag = TagActionButton.ActionButtonTag.rawValue
        floatingActionButton.isHidden = true
        
        self.view.addSubview(floatingActionButton)
        
        self.floatingActionButton = floatingActionButton
    }
	
	func showFloatingActionButton(_ show: Bool) {
        if let floatingActionButton = floatingActionButton {
//            if show && self.wishlist != nil && LoginManager.getLoginState() == .validUser {
//                floatingActionButton.showFloatingButton()
//            } else {
//                floatingActionButton.hiddenFloatingButton()
//            }
            floatingActionButton.hiddenFloatingButton()
        } else {
            ErrorLogManager.sharedManager.recordNonFatalError(withException: .NullPointer)
        }
	}
	
	func setupCollectionView() {
        self.registerDefaultReusableView(collectionView: self.collectionView)
        collectionView.register(UINib(nibName: "WishListItemCell", bundle: nil), forCellWithReuseIdentifier: WishListItemCell.CellIdentifier)
        self.collectionView.register(NoCollectionItemCell.self, forCellWithReuseIdentifier: NoCollectionItemCellID)
        
		self.collectionView.backgroundColor = UIColor.clear
		self.collectionView.alwaysBounceVertical = true
        self.collectionView.frame = CGRect(x: 0, y: 0, width: Constants.ScreenSize.SCREEN_WIDTH, height: viewHeight)
        
        self.view.frame = self.collectionView.frame
	}
    
    func registerDefaultReusableView(collectionView: UICollectionView) {
        collectionView.register(UICollectionReusableView.self, forSupplementaryViewOfKind: UICollectionElementKindSectionHeader, withReuseIdentifier: SeperatorHeaderViewID)
        collectionView.register(UICollectionReusableView.self, forSupplementaryViewOfKind: UICollectionElementKindSectionFooter, withReuseIdentifier: SeperatorFooterViewID)
    }
    
	func refreshWishList() {
		if LoginManager.getLoginState() == .validUser || Context.hasValidAnonymousWishListKey() {
            if !firstLoaded{
                //showLoadingInScreenCenter()
                startBackgroundLoadingIndicator(self.collectionView)
            }
            
			firstly {
                return self.listWishlistItem()
            }.then { _ -> Void in
                self.wishlist = CacheManager.sharedManager.wishlist
            }.always {
                self.stopBackgroundLoadingIndicator()
                self.reloadDataSource()
                
                if self.isAppeared {
                    self.showFloatingActionButton(self.dataSource.count > 0)
                }
            }.catch { _ -> Void in
                Log.error("error")
                self.stopBackgroundLoadingIndicator()
			}
        } else {
            firstLoaded = true
            DispatchQueue.main.async {
                self.collectionView.reloadData()
                self.stopBackgroundLoadingIndicator()
            }
            
        }
	}
	
	override func backButtonClicked(_ button: UIButton) {
		showFloatingActionButton(false)
		
		self.navigationController?.popViewController(animated: true)
	}
    
    func showProductDetailPage(cartItem: CartItem) {
        self.showLoading()
        
        SearchService.searchStyleBySkuId(cartItem.skuId) { (response) in
            self.stopLoading()
            
            if response.result.isSuccess {
                if response.response?.statusCode == 200 {
                    if let styleResponse = Mapper<SearchResponse>().map(JSONObject: response.result.value) {
                        if let pageData = styleResponse.pageData {
                            if pageData.count > 0 {
                                if let style = pageData.first {
                                    let color = Color()
                                    color.colorId = cartItem.colorId
                                    color.colorKey = cartItem.colorKey
                                    
                                    let styleFilter = StyleFilter()
                                    styleFilter.colors = [color]
                                    
                                    let styleViewController = StyleViewController(style: style, styleFilter: styleFilter, isProductActive: style.isValid())
                                    styleViewController.checkoutFromSource = .fromWishlist
                                    
                                    self.navigationController?.isNavigationBarHidden = false
                                    self.navigationController?.pushViewController(styleViewController, animated: true)
                                } else {
                                    ErrorLogManager.sharedManager.recordNonFatalError(withException: .NullPointer)
                                }
                            } else {
                                let styleViewController = StyleViewController(isProductActive: false)
                                
                                self.navigationController?.isNavigationBarHidden = false
                                self.navigationController?.pushViewController(styleViewController, animated: true)
                            }
                        } else {
                            ErrorLogManager.sharedManager.recordNonFatalError(withException: .NullPointer)
                        }
                    } else {
                        ErrorLogManager.sharedManager.recordNonFatalError(withException: .FailToParseAPIResponse)
                    }
                }
            }
        }
    }
    
    func reloadDataSource() {
        self.dataSource.removeAll()
        self.cartItems.removeAll()
        
        if let cartItems = self.wishlist?.cartItems {
            self.cartItems = cartItems
            self.processDataSourceCartItems(cartItems)
        } else {
            self.firstLoaded = true
            self.collectionView.reloadData()
        }
    }
    @discardableResult
    func indexPathForData(_ data: AnyObject, found: ((_ indexPath: IndexPath) -> Void)) -> IndexPath? {
        var indexPath: IndexPath!
        
        for section in 0 ..< self.dataSource.count {
            let items = self.dataSource[section]
            
            for row in 0 ..< items.count{
                let item = items[row]
                
                if ObjectIdentifier(item) == ObjectIdentifier(data) {
                    indexPath = IndexPath(row: row, section: section)
                    found(indexPath)
                    break
                }
            }
        }
        
        return indexPath
    }
    
    func numberOfSections(in collectionView: UICollectionView) -> Int {
        if collectionView == self.collectionView{
            if self.dataSource.count == 0 {
                return 1
            }
            
            return self.dataSource.count
        } else {
            return 0
        }
    }
    
    override func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        if collectionView == self.collectionView{
            if self.dataSource.count == 0 {
                return 1
            }
            
            return self.dataSource[section].count
        } else {
            return 0
        }
    }
    
    override func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
		if self.dataSource.count == 0 {
			self.showFloatingActionButton(false)
			
			let cell = collectionView.dequeueReusableCell(withReuseIdentifier: NoCollectionItemCellID, for: indexPath) as! NoCollectionItemCell
			cell.label.text = String.localize("LB_CA_COLLECTION_PRODUCT_EMPTY")
            cell.isHidden = !firstLoaded
			noItemView = cell
			return cell
        } else {
            showFloatingActionButton(true)
        }
		
        let sectionCarts = self.dataSource[indexPath.section]
		let cartItem = sectionCarts[indexPath.row] as CartItem
		
		let cell = collectionView.dequeueReusableCell(withReuseIdentifier: WishListItemCell.CellIdentifier, for: indexPath) as! WishListItemCell
        cell.data = cartItem
        
        if cartItem.styleIsValid && !cartItem.styleIsOutOfStock {
            cell.leftMenuItems = [
                SwipeActionMenuCellData(
                    text: String.localize("LB_CA_ADD2CART"),
                    icon: UIImage(named: "icon_swipe_addToCart"),
                    backgroundColor: UIColor.swipeActionColor.backgroundColor(swipeActionType: .add),
                    defaultAction: true,
                    action: { [weak self, cartItem] () -> Void in
                        if let strongSelf = self {
                            strongSelf.indexPathForData(cartItem, found: { (indexPath) in
                                let cartItem = (strongSelf.dataSource[indexPath.section])[indexPath.row] as CartItem
                                strongSelf.addToCart(cartItem: cartItem, merchant: nil, checkout: CheckoutAction.addToCart)
                            })
                        } else {
                            ErrorLogManager.sharedManager.recordNonFatalError(withException: .NullPointer)
                        }
                    }
                )
            ]
        } else {
            cell.leftMenuItems = nil
        }
        
        cell.rightMenuItems = [
            SwipeActionMenuCellData(
                text: String.localize("LB_CA_DELETE"),
                icon: UIImage(named: "icon_swipe_delete"),
                backgroundColor: UIColor.swipeActionColor.backgroundColor(swipeActionType: .delete),
                defaultAction: true,
                action: { [weak self, cartItem] () -> Void in
                    if let strongSelf = self {
                        strongSelf.view.analyticsViewKey = strongSelf.analyticsViewRecord.viewKey
                        strongSelf.view.recordAction(.Tap, sourceRef: "Delete", sourceType: .Button, targetRef: "Confirmation", targetType: .Message)
                        Alert.alert(strongSelf, title: "", message: String.localize("LB_CA_COLLECTION_CONF_REMOVE_PRODUCT"), okActionComplete: { () -> Void in
                            strongSelf.indexPathForData(cartItem, found: { (indexPath) in
                                let cartItem = (strongSelf.dataSource[indexPath.section])[indexPath.row] as CartItem
                                
                                firstly {
                                    return strongSelf.removeWishlistItem(cartItem.cartItemId)
                                }.then { _ -> Void in
                                    strongSelf.showSuccessPopupWithText(String.localize("LB_CA_DEL_WISHLIST_ITEM_SUCCESS"))
                                    strongSelf.wishlist = CacheManager.sharedManager.wishlist
                                    strongSelf.reloadDataSource()
                                    Context.setVisitedWishlist(true)
                                }.catch { _ -> Void in
                                    Log.error("error")
                                }
                            })
                        })
                    } else {
                        ErrorLogManager.sharedManager.recordNonFatalError(withException: .NullPointer)
                    }
                }
            )
        ]

        cell.addToCartHandler = { [weak self] (cell, cartItem) in
            if LoginManager.getLoginState() == .validUser {
                if let strongSelf = self {
                    strongSelf.addToCart(cartItem: cartItem, merchant: strongSelf.listMerchants[cartItem.merchantId] ?? nil, checkout: CheckoutAction.checkout)
                    cell.recordAction(.Tap, sourceRef: "AddToCart", sourceType: .Button, targetRef: cartItem.styleCode, targetType: .Product)
                } else {
                    ErrorLogManager.sharedManager.recordNonFatalError(withException: .NullPointer)
                }
            } else {
                LoginManager.goToLogin()
            }
        }

        cell.cellTappedHandler = { [weak self] (cell, cartItem) in
            if let strongSelf = self {
                strongSelf.showProductDetailPage(cartItem: cartItem)
                strongSelf.view.analyticsViewKey = strongSelf.analyticsViewRecord.viewKey
                strongSelf.view.recordAction(.Tap, sourceRef: cartItem.styleCode, sourceType: .Product, targetRef: "PDP", targetType: .View)
            }
        }

        cell.setMerchantName(cartItem.brandName)
        
        cell.merchantLogoHandler = { [weak self] (cell, cartItem) in
            if let strongSelf = self {
                strongSelf.openProductDetailView(cartItem.styleCode, merchantId: cartItem.merchantId)
            } else {
                ErrorLogManager.sharedManager.recordNonFatalError(withException: .NullPointer)
            }
        }
    
        cell.accessibilityIdentifierIndex(indexPath.row)
        
        let impressionKey = AnalyticsManager.sharedManager.recordImpression(brandCode: cartItem.brandCode , impressionRef: cartItem.styleCode, impressionType: "Product", impressionVariantRef: cartItem.skuCode, impressionDisplayName: cartItem.skuName, merchantCode: cartItem.merchantCode, positionComponent: "ProductListing", positionIndex: (indexPath.row + 1), positionLocation: "Collection", viewKey: self.analyticsViewRecord.viewKey)
        cell.initAnalytics(withViewKey: self.analyticsViewRecord.viewKey, impressionKey:impressionKey)
        
        return cell
    }
    
    private func addToCart(cartItem: CartItem, merchant: Merchant? = nil, checkout: CheckoutAction) {
        if let merchant = merchant {
            showCheckoutViewController(cartItem: cartItem, merchant: merchant, checkout: checkout)
        } else {
            CacheManager.sharedManager.merchantById(cartItem.merchantId, completion: {[weak self] merchant in
                if let merchant = merchant {
                    self?.showCheckoutViewController(cartItem: cartItem, merchant: merchant, checkout: checkout)
                } else {
                    ErrorLogManager.sharedManager.recordNonFatalError(withException: .NullPointer)
                }
            })
        }
    }
    
    private func showCheckoutViewController(cartItem data: CartItem, merchant: Merchant, checkout: CheckoutAction) {
        let checkoutViewController = FCheckoutViewController(checkoutMode: .cartItem, merchant: merchant, cartItem: data, referrer: data.userKeyReferrer, redDotButton: self.buttonCart, targetRef: "Cart")
        checkoutViewController.checkOutActionType = checkout
        checkoutViewController.didDismissHandler = { [weak self] (confirmed, parentOrder) in
            if let strongSelf = self {
                strongSelf.updateButtonCartState()
                
                if let parentOrder = parentOrder, confirmed {
                    strongSelf.thankYouPageDelayAction = DelayAction(delayInSecond: 0.5, actionBlock: {
                        strongSelf.showThankYouPage(parentOrder)
                    })
                } else {
                    strongSelf.showFloatingActionButton(strongSelf.dataSource.count > 0)
                }
            } else {
                ErrorLogManager.sharedManager.recordNonFatalError(withException: .NullPointer)
            }
        }
        
        let navigationController = MmNavigationController()
        navigationController.viewControllers = [checkoutViewController]
        navigationController.modalPresentationStyle = .overFullScreen
        
        self.checkoutActionSheetDelayAction = DelayAction(delayInSecond: 0.1, actionBlock: { [weak self] in
            if let strongSelf = self {
                strongSelf.present(navigationController, animated: false, completion: { [weak strongSelf] in
                    if let strongSelf = strongSelf {
                        strongSelf.showFloatingActionButton(false)
                    } else {
                        ErrorLogManager.sharedManager.recordNonFatalError(withException: .NullPointer)
                    }
                })
            } else {
                ErrorLogManager.sharedManager.recordNonFatalError(withException: .NullPointer)
            }
        })
    }
    
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, minimumInteritemSpacingForSectionAt section: Int) -> CGFloat {
        return 0.0
    }
    
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, minimumLineSpacingForSectionAt section: Int) -> CGFloat {
        return 0.0
    }
    
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, insetForSectionAt section: Int) -> UIEdgeInsets {
        return UIEdgeInsets.zero
    }
	
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, sizeForItemAt indexPath: IndexPath) -> CGSize {
		if self.dataSource.count == 0 {
            return collectionView.frame.size
		}
        
		return CGSize(width: view.width , height: CellHeight)
    }
	
	func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, referenceSizeForFooterInSection section: Int) -> CGSize {
        if (section == dataSource.count - 1) {
            return CGSize(width: view.width, height: footerHeight)
        } else {
            if dataSource.count > 0 && dataSource[section].count > 0 {
                return CGSize(width: collectionView.width, height: 10)
            }
            
            return CGSize.zero
        }
	}
    
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, referenceSizeForHeaderInSection section: Int) -> CGSize {
        return CGSize.zero
    }
    
    func collectionView(_ collectionView: UICollectionView, viewForSupplementaryElementOfKind kind: String, at indexPath: IndexPath) -> UICollectionReusableView {
		var viewIdentifier = ""
        
		if kind == UICollectionElementKindSectionHeader {
			viewIdentifier = SeperatorHeaderViewID
		} else if kind == UICollectionElementKindSectionFooter {
			viewIdentifier = SeperatorFooterViewID
		}
		
		let view = collectionView.dequeueReusableSupplementaryView(ofKind: kind, withReuseIdentifier: viewIdentifier, for: indexPath)
		
		return view
    }
    
    func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        if !dataSource.isEmpty {
            let cartItem: CartItem = dataSource[indexPath.section][indexPath.item]
                if let cell = self.collectionView.cellForItem(at: indexPath) as? WishListItemCell {
                    cell.recordAction(.Tap, sourceRef: cartItem.styleCode, sourceType: .Product, targetRef: "PDP", targetType: .View)
                } else {
                    ErrorLogManager.sharedManager.recordNonFatalError(withException: .NullPointerOrTypeMismatch)
                }
                showProductDetailPage(cartItem: cartItem)
      
        }
    }
	
    //MARK: Override
    
    override func showLoading() {
        self.showLoadingInScreenCenter()
    }
    
    //MARK: handle create post 
    
    func didSelectedActionButton(_ gesture: UITapGestureRecognizer) {
        let photoCollageViewController = CreatePostSelectImageViewController()
        photoCollageViewController.selectedIndex = CreatePostControllerIndex.wishListIndex
        let navController = UINavigationController()
        navController.viewControllers = [photoCollageViewController]
        self.present(navController, animated: true, completion: nil)
        
        if let view = gesture.view {
            view.initAnalytics(withViewKey: self.analyticsViewRecord.viewKey)
            view.recordAction(.Tap, sourceRef: "CreatePost", sourceType: .Button, targetRef: "Editor-CollectedProduct", targetType: .View)
        } else {
            ErrorLogManager.sharedManager.recordNonFatalError(withException: .NullPointer)
        }
    }
	
    /**
     goto merchant profile
     */
    func openMerchantProfile(merchant: Merchant) {
        Navigator.shared.dopen(Navigator.mymm.website_merchant_merchantId + "\(merchant.merchantId)")
    }
    
    private func openProductDetailView(_ styleCode: String?, merchantId: Int) {
        let style = Style()
        
        if let styleCode = styleCode {
            style.styleCode = styleCode
        }
        
        let styleViewController = StyleViewController(style: style)
        styleViewController.merchantId = merchantId
        
        self.navigationController?.pushViewController(styleViewController, animated: true)
    }
    
    // MARK: API
    
    func fetchMerchant(_ merchantId: Int) -> Promise<Any> {
        return Promise { fulfill, reject in
            MerchantService.view(merchantId) { (response) in
				if response.result.isSuccess {
					if response.response?.statusCode == 200 {
                        if let array = response.result.value as? [[String: Any]], let obj = array.first, let merchant = Mapper<Merchant>().map(JSONObject: obj) {
							fulfill(merchant)
						} else {
                            ErrorLogManager.sharedManager.recordNonFatalError(withException: .NullPointerOrTypeMismatch)
                            
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
			}
        }
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
    
    // MARK: Helpers
    
    func showThankYouPage(_ parentOrder: ParentOrder) {
        let thankYouViewController = ThankYouViewController()
        thankYouViewController.fromViewController = self
        thankYouViewController.parentOrder = parentOrder
        
        let navigationController = MmNavigationController(rootViewController: thankYouViewController)
        navigationController.modalPresentationStyle = .overFullScreen
        
        thankYouViewController.handleDismiss = { [weak self] in
            self?.showFloatingActionButton(self?.dataSource.count > 0)
        }
        
        self.present(navigationController, animated: true, completion: nil)
        self.stopLoading()
    }
    
    internal func processDataSourceCartItems(_ cartItems: [CartItem]) {
        self.validCartItems.removeAll()
        self.invalidCartItems.removeAll()

        var styleCodes = [String]()
        var merchantIds = [String]()
        
        for cartItem in cartItems {
            styleCodes.append(cartItem.styleCode)
            let merchantId = String(cartItem.merchantId)
            if !merchantIds.contains(merchantId) {
                merchantIds.append(merchantId)
            }
        }
        
        firstly {
            return self.searchStyle(withStyleCodes: styleCodes, merchantIds: merchantIds)
        }.then { _ -> Void in
            for cartItem in cartItems{
                if let style = self.styles.filter({ $0.styleCode == cartItem.styleCode }).first {
                    cartItem.styleIsValid = style.isValid()
                    cartItem.styleIsOutOfStock = style.isOutOfStock()
                } else {
                    cartItem.styleIsValid = false
                }
            }
            
            self.validCartItems = cartItems.filter{!$0.styleIsOutOfStock && $0.styleIsValid}
            self.invalidCartItems = cartItems.filter{($0.styleIsOutOfStock || !$0.styleIsValid)} 
        }.always {
            self.refreshDataSource()
            self.stopLoading()
        }.catch { _ -> Void in
            Log.error("error")
        }
    }
    
    func refreshDataSource() {
        if validCartItems.count > 0 {
            dataSource.append(validCartItems)
        }
        
        if invalidCartItems.count > 0 {
            dataSource.append(invalidCartItems)
        }
        
        self.firstLoaded = true
        collectionView.reloadData()
    }
    
    func getCartItem(indexPath: IndexPath) -> CartItem {
        let sectionCarts = self.dataSource[indexPath.section]
        return sectionCarts[indexPath.row] as CartItem
    }
    
    //MARK: - Analytics Log
    
    private func initAnalyticLog(){
        initAnalyticsViewRecord(
            nil,
            authorType: nil,
            brandCode: nil,
            merchantCode: nil,
            referrerRef: nil,
            referrerType: nil,
            viewDisplayName: "User: \(Context.getUserProfile().displayName)",
            viewParameters: "u=\(Context.getUserKey())",
            viewLocation: "Collection",
            viewRef: nil,
            viewType: "Product"
        )
    }
}
