//
//  CheckoutPresenter.swift
//  merchant-ios
//
//  Created by Jerry Chong on 19/6/2017.
//  Copyright © 2017 WWE & CO. All rights reserved.
//

import Foundation
import ObjectMapper
import PromiseKit

protocol CheckoutPresenterDelegate: class {
    func refreshContent(_ isSuccess: Bool, isFullList: Bool, items: [NSObject])
    func enableAllButton()
    func disableAllButton()
    func reloadAllData()
    func updateMerchantDataList(_ merchantDataList: [CheckoutMerchantData])
    func updateCheckoutSection(_ checkoutSections: [CheckoutSection])
    func returnDismissHandler(_ confirmed: Bool, parentOrder: ParentOrder?)
    func reloadCollectionView()
    func preselectColorSize(_ style: Style, selectedSizeId: Int?, selectedSkuColor: String?, selectedColorId: Int?)
    func showError(_ message: String, animated: Bool)
    func showFailPopupWithText(_ text: String, delegate: MmViewController?)
    func addCartItem(_ skuId : Int, qty : Int, referrer: String?, success: (() -> Void)?, fail: (() -> Void)?)
    func addMultiProductToCart(_ listSkuId: [Int], referrer: String?, success: (() -> Void)?, fail: (() -> Void)?)
    func showAddToCartAnimation()
    func updateCartItem(_ cartItemId : Int, skuId : Int, qty : Int, success: (() -> Void)? , fail: (() -> Void)? )
    func updateParent(_ parentOrder: ParentOrder?)
    
    func initAnalyticsViewRecord(_ authorRef: String?,
    authorType: String?,
    brandCode: String?,
    merchantCode: String?,
    referrerRef: String?,
    referrerType: String?,
    viewDisplayName: String?,
    viewParameters: String?,
    viewLocation: String?,
    viewRef: String?,
    viewType: String?)
}

extension CheckoutPresenterDelegate {
    func updateParent(_ parentOrder: ParentOrder?){}
    func refreshContent(_ isSuccess: Bool, isFullList: Bool, items: [NSObject]){}
    func enableAllButton() {}
    func disableAllButton() {}
    func reloadAllData() {}
    func updateMerchantDataList(_ merchantDataList: [CheckoutMerchantData]) {}
    func updateCheckoutSection(_ checkoutSections: [CheckoutSection]) {}
    func returnDismissHandler(_ confirmed: Bool, parentOrder: ParentOrder?) {}
    func reloadCollectionView() {}
    func preselectColorSize(_ style: Style, selectedSizeId: Int?, selectedSkuColor: String?, selectedColorId: Int?) {}
    func showError(_ message: String, animated: Bool) {}
    func showFailPopupWithText(_ text: String, delegate: MmViewController? = nil) {}
    func addCartItem(_ skuId : Int, qty : Int, referrer: String?, success: (() -> Void)? = nil, fail: (() -> Void)? = nil) {}
    func addMultiProductToCart(_ listSkuId: [Int], referrer: String?, success: (() -> Void)? = nil, fail: (() -> Void)? = nil) {}
    func showAddToCartAnimation() {}
    func updateCartItem(_ cartItemId : Int, skuId : Int, qty : Int, success: (() -> Void)? = nil, fail: (() -> Void)? = nil) {}
    func initAnalyticsViewRecord(_ authorRef: String? = nil,
                                 authorType: String? = nil,
                                 brandCode: String? = nil,
                                 merchantCode: String? = nil,
                                 referrerRef: String? = nil,
                                 referrerType: String? = nil,
                                 viewDisplayName: String? = nil,
                                 viewParameters: String? = nil,
                                 viewLocation: String? = nil,
                                 viewRef: String? = nil,
                                 viewType: String? = nil) {
        initAnalyticsViewRecord(authorRef, authorType: authorType, brandCode: brandCode, merchantCode: merchantCode, referrerRef: referrerRef, referrerType: referrerType, viewDisplayName: viewDisplayName, viewParameters: viewParameters, viewLocation: viewLocation, viewRef: viewRef, viewType: viewType)
    }
}


final class CheckoutPresenter {
    weak var delegate: CheckoutPresenterDelegate? {
        willSet {
            if newValue as? UIViewController == nil {
                fatalError("you should attach presenter to a view controller.")
            }
        }
    }
    
    private func presenterViewController() -> MmCartViewController? {
        return delegate as? MmCartViewController
    }
    
    private let interactor = CheckoutInteractor()
    
    init() {
        interactor.presenter = self
    }
    
    
    var checkoutHandler: CheckoutHandler!
    private final let AnimationDuration: TimeInterval = 0.3
    private var parentOrder: ParentOrder?
    
    
    weak var contentView = UIView()
    weak var headerView = UIView()
    weak var footerView = UIView()
    weak var address: Address?
    weak var collectionView = MMCollectionView(frame: .zero, collectionViewLayout: UICollectionViewFlowLayout())
    var merchantDataList = [CheckoutMerchantData]()
    

    var checkoutMode: CheckoutMode = .unknown
    var checkoutFromSource: CheckoutFromSource = .unknown
    private var isCart: Bool = false
    var isFlashSale = false
    var defaultFapiaoText: String?
    // For CartCheckout Only
    var referrerUserKeys: [String : String] = [:] // skuId : referrerUserKey
    var referrerUserKey: String?
    var qty = 1 // TODO: Move to CheckoutMerchantData > Style
    var cartItem: CartItem?
    
    private var checkStockError: NSError? = nil
    private var checkOrderError: NSError? = nil

    
    
    func setupPresenter(_ fromCartCheckout: Bool){
        guard let vc = presenterViewController() else { return }
        
        checkoutHandler = CheckoutHandler(cartController: vc, dismiss: { [weak self] (parentOrder) -> Void in
            if let strongSelf = self {
                if fromCartCheckout {
                    // Action Sheet Checkout
                    strongSelf.dismissView(true)
                } else {
                    // Cart Checkout
                    if let po = parentOrder {
                        strongSelf.parentOrder = po
                        vc.view.recordAction(.Submit, sourceRef: po.parentOrderKey, sourceType: .ParentOrder, targetRef: "Payment-Alipay", targetType: .View)
                        
                        if let orders = po.orders {
                            for order in orders {
                                vc.view.recordAction(.Submit, sourceRef: order.orderKey, sourceType: .MerchantOrder, targetRef: "Payment-Alipay", targetType: .View)
                            }
                        }
                        
                        if po.parentOrderStatusId == 2 || po.parentOrderStatusId == 3 {
                            strongSelf.goToThankYouPage(po)
                        }
                    } else {
                        ErrorLogManager.sharedManager.recordNonFatalError(withException: .NullPointer)
                    }
                }
                strongSelf.delegate?.enableAllButton()
            } else {
                ErrorLogManager.sharedManager.recordNonFatalError(withException: .NullPointer)
            }
        })

    }
    
    func dismissView(_ confirmed: Bool = false) {
        guard let vc = presenterViewController() else { return }
        UIView.animate(withDuration: AnimationDuration, animations: { [weak self] () -> Void in
                if let strongSelf = self {
                    strongSelf.contentView?.transform = CGAffineTransform.identity
                } else {
                    ErrorLogManager.sharedManager.recordNonFatalError(withException: .NullPointer)
                }
            }, completion: { [weak self] (success) -> Void in
                if let strongSelf = self {
                    vc.dismiss(animated: false, completion: { [weak strongSelf] in
                        if let strongSelf = strongSelf {
                            strongSelf.delegate?.returnDismissHandler(confirmed, parentOrder: strongSelf.checkoutHandler.getConfirmedOrder())
                        } else {
                            ErrorLogManager.sharedManager.recordNonFatalError(withException: .NullPointer)
                        }
                    })
                } else {
                    ErrorLogManager.sharedManager.recordNonFatalError(withException: .NullPointer)
                }
            })
    }
    
    func apiCheckOrder(proceedActionIfSuccess action: CheckoutAction = .unknown, isCart: Bool, coupon: Coupon?, flashSale:Bool = false, completion: ((_ success: Bool, _ error: NSError?) -> ())?) {
        guard let vc = presenterViewController() else { return }
        self.isCart = isCart
        self.isFlashSale = flashSale
        
        if cartInformationIsValid(forAction: action) {
            if !processCreateOrder(forAction: action, coupon: coupon, completion: completion){
                completion?(false, nil)
            }
        } else if address == nil || address?.userAddressKey.length == 0 {
            CheckoutWireframe.presentAddressPage(address, mode:.checkoutSwipeToPay, fromViewController: vc, completion: { [weak self]  (address) in
                if let strongSelf = self {
                    strongSelf.address = address
                    strongSelf.collectionView?.reloadData()
                    
                    if strongSelf.cartInformationIsValid(forAction: action) {
                        strongSelf.processCreateOrder(forAction: action, coupon: coupon, completion: completion)
                    }
                    else{
                        completion?(false, nil)
                    }
                } else {
                    completion?(false, nil)
                    ErrorLogManager.sharedManager.recordNonFatalError(withException: .NullPointer)
                }
            })
        }
        
        
    }
    
    func cartInformationIsValid(forAction action: CheckoutAction = .unknown) -> Bool {
        guard let vc = presenterViewController() else { return false }
        
        if action != .unknown {
            if LoginManager.getLoginState() == .validUser || action != .checkout {
                // Stock error by checking api
                if let checkStockError = checkStockError {
                    if let errorDetail = checkStockError.userInfo["errorCode"] as? String {
                        vc.showError(String.localize(errorDetail), animated: true)
                        return false
                    } else {
                        ErrorLogManager.sharedManager.recordNonFatalError(withException: .NullPointerOrTypeMismatch)
                    }
                }
                
                if action == .checkout {
                    if address == nil || address?.userAddressKey.length == 0 {
                        if checkoutMode != .cartCheckout {
                            self.delegate?.showError(String.localize("MSG_ERR_ADDRESS_NIL"), animated: true)
                        }
                        
                        return false
                    }
                    
                    // Order Currently Error by api checking
                    if let checkOrderError = checkOrderError {
                        if let errorDetail = checkOrderError.userInfo["errorCode"] as? String {
                            self.delegate?.showError(String.localize(errorDetail), animated: true)
                            return false
                        } else {
                            ErrorLogManager.sharedManager.recordNonFatalError(withException: .NullPointerOrTypeMismatch)
                        }
                    }
                }
                
                for checkoutMerchantData in merchantDataList {
                    if action == .checkout {
                        if let fapiaoText = checkoutMerchantData.fapiaoText {
                            if fapiaoText.containsEmoji() {
                                self.delegate?.showError(String.localize("MSG_ERR_USER_FULLNAME"), animated: true)
                                return false
                            }
                        } else {
                            ErrorLogManager.sharedManager.recordNonFatalError(withException: .NullPointer)
                        }
                        
                        if checkoutMerchantData.enabledFapiao && (checkoutMerchantData.fapiaoText == nil || (checkoutMerchantData.fapiaoText ?? "").isEmptyOrNil()) {
                            self.delegate?.showError(String.localize("MSG_ERR_CA_FAPIAO_NIL"), animated: true)
                            return false
                        }
                    }
                    
                    for style in checkoutMerchantData.styles {
                        if !style.selected {
                            continue
                        }
                        
                        var colorSizeIsValid = true
                        
                        let selectedColor = style.getValidColorAtIndex(style.colorIndexSelected)
                        let selectedSizeId = style.getValidSizeIdAtIndex(style.sizeIndexSelected)
                        
                        if !(style.isEmptyColorList() || selectedColor != nil) {
                            colorSizeIsValid = false
                        }
                        
                        if !(style.isEmptySizeList() || selectedSizeId != -1) {
                            colorSizeIsValid = false
                        }
                        
                        if !colorSizeIsValid {
                            self.delegate?.showError(String.localize("LB_MC_COLORS_SIZE_TITLE"), animated: true)
                            return false
                        }
                    }
                }
                
                return true
            } else {
                LoginManager.goToLogin()
                return false
            }
        } else {
            // Bypass checking
            return true
        }
    }

    func getBestCoupon(_ checkoutMerchantList: [CheckoutMerchantData], completion: ((_ ccmCouponCheckMerchants: [CouponCheckMerchant]?, _ couponMap: [Int: Coupon]?) ->())?  ) {
        // ccm is Coupon Checkout Merchant info
        if checkoutMerchantList.count > 0 {
            var couponCheckMerchantList = [CouponCheckMerchant]()
            
            for checkoutMerchant in checkoutMerchantList {
                if let merchant = checkoutMerchant.merchant{
                    let ccmMerchantId = merchant.merchantId                                                     // merchant id
                    // Items
                    var ccmCouponCheckItemList = [CouponCheckItem]()
                    for merchantStyle in checkoutMerchant.styles {
                        if let sku = merchantStyle.searchSku(merchantStyle.selectedSizeId, colorId: merchantStyle.selectedColorId, skuColor: merchantStyle.selectedSkuColor){
                            let ccmItemMerchantId = ccmMerchantId                                               // item -> merchant id
                            let ccmItemBrandId = sku.brandId                                                    // item -> brand id
                            var ccmItemCategoryId: Int?
                            if let categoryPriorityList = merchantStyle.categoryPriorityList{
                                if let index = categoryPriorityList.index(where: { $0.level == 2 && $0.priority == 0 }) {
                                    ccmItemCategoryId = categoryPriorityList[index].categoryId
                                }
                            }
                            var ccmItemUnitedPrice = sku.isOnSale() ? sku.priceSale : sku.priceRetail         // item -> unit price
                            if self.isFlashSale {
                                ccmItemUnitedPrice = sku.isFlashOnSale() ? sku.priceFlashSale : ccmItemUnitedPrice
                                if (sku.qty != 1) {
                                    sku.qty = 1
                                }
                            }
                            let ccmItemQty = sku.qty                                                            // item -> quantity
                            
                            let ccmCouponCheckItem = CouponCheckItem(
                                                    merchantId: ccmItemMerchantId,
                                                    brandId: ccmItemBrandId,
                                                    categoryId: ccmItemCategoryId,
                                                    unitPrice: ccmItemUnitedPrice,
                                                    qty: ccmItemQty)
                            ccmCouponCheckItemList.append(ccmCouponCheckItem)
                        }
                    }
                    
                    let ccmCouponCheckMerchant = CouponCheckMerchant(merchantId: ccmMerchantId, items: ccmCouponCheckItemList)
                    couponCheckMerchantList.append(ccmCouponCheckMerchant)
                }
            }
            
            CouponManager.shareManager().calculateBestCoupons(couponCheckMerchantList)
                .then { (couponDict: [MerchantId : Coupon]) -> Void in
                    completion?(couponCheckMerchantList, couponDict)
            }
        
            return
        }
    }
    
    func checkOutOfStock(_ coupon: Coupon? = nil, flashSale:Bool = false, completion: ((_ isOutOfStock: Bool) -> ())?) {
        let (skus, orders, errorMessage) = constructOrdersForChecking()
        if errorMessage.length > 0 {
            self.delegate?.showError(errorMessage, animated: true)
        }
        if skus.count > 0 {
            firstly {
                return self.checkoutHandler.checkStockService(skus, orders: orders, coupon: coupon, isFlashSale: flashSale)
                }.then { parentOrder -> Void in
                    self.parentOrder = parentOrder
                    self.delegate?.updateParent(parentOrder)
                    self.checkStockError = nil
                    self.proceedAction(.unknown, withSkus: skus, orders: orders)
                    completion?(false)
                }.catch { (err) -> Void in
                    var message = ""
                    if let errorInfo = (err as NSError).userInfo as? [String: String] {
                        message = String.localize(errorInfo["AppCode"] ?? "")
                        
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
                    }
                    self.delegate?.showError(message, animated: true)
                    completion?(true)
            }
        }else{
            self.delegate?.disableAllButton()
        }
        
//        self.delegate?.reloadCollectionView()
        
    }
    
    func checkStock(usingMMCoupon coupon: Coupon? = nil, showLoading: Bool = true, proceedActionIfSuccess action: CheckoutAction = .unknown) {
        if cartInformationIsValid(forAction: action) {
            let (skus, orders, errorMessage) = constructOrdersForChecking()
            
            if skus.count > 0 {
                if action == .addToCart || action == .checkout {
                    self.proceedAction(action, withSkus: skus, orders: orders)
                } else {
                    
                    firstly {
                        
                        return self.checkoutHandler.checkStockService(skus, orders: orders, coupon: coupon)
                        }.then { parentOrder -> Void in
                            self.parentOrder = parentOrder
                            self.delegate?.updateParent(parentOrder)
                            self.checkStockError = nil
                            if errorMessage.length == 0 {
                                self.delegate?.enableAllButton()
                            }
                            self.proceedAction(action, withSkus: skus, orders: orders)
                        }.catch { (err) -> Void in
                            self.checkStockError = err as NSError
                            var message = ""
                            if let errorInfo = (err as NSError).userInfo as? [String: String] {
                                message = String.localize(errorInfo["AppCode"] ?? "")
                                
                                if errorInfo["AppCode"] == "MSG_ERR_CA_COUPON_MIN_PURCHASE_MEET" {
                                    if let couponReference = errorInfo["Message"], let minSpendAmount = self.findMinimumSpendAmount(withCouponReference: couponReference , mmCoupon: coupon) {
                                        message = String.localize("MSG_ERR_CA_COUPON_MIN_PURCHASE_MEET").replacingOccurrences(of: "{0}", with: "\(minSpendAmount)")
                                    }
                                }
                                
                                if errorInfo["AppCode"] == "MSG_ERR_CART_NOT_FOUND" {
                                    message = ""
                                    let viewController = IDCardCollectionPageViewController(updateCardAction: .swipeToPay)
                                    viewController.callBackAction = {
                                        self.checkStock(usingMMCoupon: coupon, showLoading: showLoading, proceedActionIfSuccess: action)
                                    }
                                }
                            }
                            
                            self.delegate?.showError(message, animated: true)
                            LoadingOverlay.shared.hideOverlayView()
                    }
                    
                }
            } else {
                parentOrder = nil
                if errorMessage.length > 0 {
                    self.delegate?.showError(errorMessage, animated: true)
                }
            }
        } else {
        }
        
//        self.delegate?.reloadCollectionView()
    }
    
        
    func loadUserIDNumberIdentification(_ completion: @escaping (_ success: Bool, _ value: Identification?)->()) {
        let userKey = Context.getUserKey()
        if userKey != "0"{
            IDCardService.getIdentification(userKey, success: { (value) in
                if (value.identificationNumber.count > 0) {
                    completion(true, value)
                } else{
                    completion(false, nil)
                }
            }, failure: { (error) -> Bool in
                completion(false, nil)
                return true
            })
        }
    }
    
    //Coupon
    func loadCachedMerchantsByMerchantIDs(_ merchantIDs: [Int], styles: [Style], skus: [Sku]) {
        
        if self.merchantDataList.count > 0 {
            self.merchantDataList.removeAll()
        }
        
        interactor.getCachedMerchantsByMerchantIDs(merchantIDs) { (merchants, merchantsDict) in
            let sortedStyles = styles.sorted(by: { $0.merchantId < $1.merchantId })
            var merchantDataIndex = 0
            var merchantId = -1
            var checkoutMerchantData: CheckoutMerchantData?
            
            if self.checkoutMode == .cartCheckout {
                self.merchantDataList.append(CheckoutMerchantData(checkoutMode: self.checkoutMode, sectionPosition: .header))
            }
            
            var remainingSkus = [Sku]()
            remainingSkus.append(contentsOf: skus)
            
            for style in sortedStyles {
                // Prepare selected color and style
                let filteredSkus = remainingSkus.filter({ $0.styleCode == style.styleCode })
                
                if let sku = filteredSkus.first {
                    style.selectedSkuId = sku.skuId
                    let selectedColorId = sku.colorId
                    let selectedSkuColor = sku.skuColor
                    let selectedSizeId = sku.sizeId
                    remainingSkus.remove(sku)
                    // Action: Pre-Select Color and Size
                    self.delegate?.preselectColorSize(style, selectedSizeId: selectedSizeId, selectedSkuColor: selectedSkuColor, selectedColorId: selectedColorId)
                    
                }
                
                if merchantId != style.merchantId {
                    merchantId = style.merchantId
                    checkoutMerchantData = CheckoutMerchantData(merchant: merchants.filter({$0.merchantId == merchantId}).first, styles: [], fapiaoText: self.defaultFapiaoText, checkoutMode: self.checkoutMode, merchantDataIndex: merchantDataIndex)
                    
                    if let checkoutMerchantData = checkoutMerchantData {
                        self.merchantDataList.append(checkoutMerchantData)
                    } else {
                        ErrorLogManager.sharedManager.recordNonFatalError(withException: .NullPointer)
                    }
                    
                    merchantDataIndex += 1
                }
                
                checkoutMerchantData?.styles.append(style)
                
            }
            self.merchantDataList.append(CheckoutMerchantData(checkoutMode: self.checkoutMode, sectionPosition: .footer))
            self.delegate?.updateMerchantDataList(self.merchantDataList)
        }
    }

    func loadDefaultAddress(_ completion: ((_ success: Bool, _ address: Address?) -> ())?) {
        interactor.getDefaultAddress(completion)
        
    }
    
    func loadFetchBrand(_ brandId: Int, completion: ((_ success: Bool, _ brand: Brand?) -> ())?){
        interactor.getFetchBrand(brandId, completion: completion)
    }
    
    func getSelectSku() -> Sku? {
        let (skus, _, _) = self.constructOrdersForChecking()

        if skus.isEmpty {
            return nil
        }
        
        if let skuId = skus[0]["SkuId"] as? Int {
            for checkoutMerchantData in merchantDataList {
                for style in checkoutMerchantData.styles {
                    for sku in style.skuList {
                        if sku.skuId == skuId {
                            return sku
                        }
                    }
                }
            }
        }
        
        return nil
    }

    
    // interactor
    func constructOrdersForChecking() -> (skus: [Dictionary<String, Any>], orders: [Dictionary<String, Any>], errorMessage: String) {
        var skus: [Dictionary<String, Any>] = []
        var orders: [Dictionary<String, Any>] = []
        var errorMessage = ""
        
        for checkoutMerchantData in merchantDataList {
            var merchantId = 0
            
            if let merchant = checkoutMerchantData.merchant {
                merchantId = merchant.merchantId
            } else if let style = checkoutMerchantData.styles.first, style.merchantId > 0 {
                merchantId = style.merchantId
            }
            
            if merchantId > 0 {
                var hasSku = false
                
                for style in checkoutMerchantData.styles {
                    if style.selected || checkoutMode != .multipleMerchant {
                        let selectedColor = style.getValidColorAtIndex(style.colorIndexSelected)
                        let selectedSizeId = style.getValidSizeIdAtIndex(style.sizeIndexSelected)
                        
                        if (style.isEmptyColorList() || selectedColor != nil) && (style.isEmptySizeList() || selectedSizeId != -1) {
                            let qty = (checkoutMode == .multipleMerchant) ? 1 : (self.qty <= 0 ? 1 : self.qty)
                            let referrerUserKey = self.referrerUserKey ?? nil
                            var skuObject: Dictionary<String, Any>
                            
                            if let sku = style.searchValidSku(selectedSizeId, colorId: selectedColor?.colorId, skuColor: selectedColor?.skuColor) {
                                if !sku.isOutOfStock() {
                                    hasSku = true
                                    
                                    if sku.qty <= 0 {
                                        sku.qty = 1
                                    }
                                    skuObject = ["SkuId": sku.skuId, "Qty": (checkoutMode == .cartCheckout) ? sku.qty : qty, "StyleCode": sku.styleCode, "MerchantId": sku.merchantId]
                                    
                                    if referrerUserKey != nil {
                                        skuObject["UserKeyReferrer"] = referrerUserKey
                                    } else if referrerUserKeys.count > 0 {
                                        if let referrerUserKey = getReferrerUserKey(withSkuId: sku.skuId) {
                                            skuObject["UserKeyReferrer"] = referrerUserKey
                                        }
                                    }
                                    
                                    skus.append(skuObject)
                                } else {
                                    errorMessage = String.localize("LB_OUT_OF_STOCK")
                                }
                            } else {
                                ErrorLogManager.sharedManager.recordNonFatalError(withException: .NullPointer, parameters: ["message" : "Sku not found."])
                                
                                // TODO: .MultipleMerchant only?
                                
                                Log.debug("========== ALERT")
                                
                                skuObject = ["SkuId": style.selectedSkuId, "Qty": qty]
                                
                                if referrerUserKey != nil {
                                    skuObject["UserKeyReferrer"] = referrerUserKey
                                } else {
                                    if let referrerUserKey = getReferrerUserKey(withSkuId: style.selectedSkuId) {
                                        skuObject["UserKeyReferrer"] = referrerUserKey
                                    }
                                }
                                
                                skus.append(skuObject)
                            }
                        }
                    }
                }
                
                if hasSku {
                    
                    var order: [String: Any] = ["MerchantId" : merchantId as Any, "Comments" : checkoutMerchantData.comment ?? "" as Any]
                    
                    
                    if checkoutMerchantData.enabledFapiao{
                        order["TaxInvoiceName"] = checkoutMerchantData.fapiaoText ?? ""
                    }
                    
                    if let merchantCoupon = checkoutMerchantData.merchantCoupon {
                        order["CouponReference"] = merchantCoupon.couponReference
                    }
                    
                    orders.append(order)
                }
            }
        }
        return (skus, orders, skus.count == 0 ? errorMessage : "")
    }

    
    
    private func proceedAction(_ action: CheckoutAction, withSkus skus: [Dictionary<String, Any>], orders: [Dictionary<String, Any>]) {
        guard let vc = presenterViewController() else { return }
        switch action {
        case .addToCart:
            if self.checkoutMode == .multipleMerchant {
                var skuIds: [Int] = []
                
                for checkoutMerchantData in self.merchantDataList {
                    for style in checkoutMerchantData.styles where style.selected {
                        let selectedColor = style.getValidColorAtIndex(style.colorIndexSelected)
                        let selectedSizeId = style.getValidSizeIdAtIndex(style.sizeIndexSelected)
                        
                        if (style.isEmptyColorList() || selectedColor != nil) && (style.isEmptySizeList() || selectedSizeId != -1) {
                            if let sku = style.searchSku(selectedSizeId, colorId: selectedColor?.colorId, skuColor: selectedColor?.skuColor) {
                                skuIds.append(sku.skuId)
                            } else {
                                ErrorLogManager.sharedManager.recordNonFatalError(withException: .NullPointer, parameters: ["message" : "Sku not found."])
                                
                                // TODO: .MultipleMerchant only?
                                skuIds.append(style.selectedSkuId)
                            }
                        }
                    }
                }
                
                if skus.count > 0 {
                    self.delegate?.addMultiProductToCart(skuIds, referrer: self.referrerUserKey, success: {
                        LoadingOverlay.shared.hideOverlayView()
                        self.delegate?.showAddToCartAnimation()
                        self.dismissView(false)
                        }, fail: {
                            Alert.alertWithSingleButton(vc, title: "", message: String.localize("LB_CA_ADD2CART_FAIL"), buttonString:String.localize("LB_OK"))
                            LoadingOverlay.shared.hideOverlayView()
                            self.dismissView(false)
                    })
                }
            } else {
                if let style = self.merchantDataList.first?.styles.first {
                    let selectedColor = style.getValidColorAtIndex(style.colorIndexSelected)
                    let selectedSizeId = style.getValidSizeIdAtIndex(style.sizeIndexSelected)
                    
                    if (style.isEmptyColorList() || selectedColor != nil) && (style.isEmptySizeList() || selectedSizeId != -1) {
                        if let sku = style.searchSku(selectedSizeId, colorId: selectedColor?.colorId, skuColor: selectedColor?.skuColor) {
                            self.delegate?.addCartItem(sku.skuId, qty: self.qty, referrer: self.referrerUserKey, success: {
                                LoadingOverlay.shared.hideOverlayView()
                                 self.delegate?.showAddToCartAnimation()
                                self.dismissView(false)
                                }, fail: {
                                    Alert.alertWithSingleButton(vc, title: "", message: String.localize("LB_CA_ADD2CART_FAIL"), buttonString:String.localize("LB_OK"))
                                    LoadingOverlay.shared.hideOverlayView()
                                    self.dismissView(false)
                                    
                            })
                        } else {
                            ErrorLogManager.sharedManager.recordNonFatalError(withException: .NullPointer)
                        }
                    } else {
                        // Missing SKU handling
                        self.delegate?.showFailPopupWithText(String.localize("Fail to add shopping cart: Missing Sku"))
                        ErrorLogManager.sharedManager.recordNonFatalError(withException: .NullPointer, parameters: ["message" : "Missing Sku."])
                    }
                } else {
                    ErrorLogManager.sharedManager.recordNonFatalError(withException: .DataIsEmpty)
                }
            }
        case .updateCart:
            if let style = self.merchantDataList.first?.styles.first, let cartItem = self.cartItem {
                let selectedColor = style.getValidColorAtIndex(style.colorIndexSelected)
                let selectedSizeId = style.getValidSizeIdAtIndex(style.sizeIndexSelected)
                
                if let sku = style.searchSku(selectedSizeId, colorId: selectedColor?.colorId, skuColor: selectedColor?.skuColor) {
                    if sku.isOutOfStock() {
                        self.delegate?.showError(String.localize("LB_OUT_OF_STOCK"), animated: true)
                    } else {
                        let cartMerchant = CacheManager.sharedManager.cart?.merchantList?.filter({$0.merchantId == sku.merchantId}).first
                        let existingSameSkuCartItems = cartMerchant?.itemList?.filter{($0.cartItemId != cartItem.cartItemId) && ($0.skuId == sku.skuId)}
                        if let cartItems = existingSameSkuCartItems, cartItems.count > 0{
                            LoadingOverlay.shared.hideOverlayView()
                            self.delegate?.showError(String.localize("LB_CA_SKU_ALREADY_IN_CART"), animated: true)
                        }
                        else{
                            self.delegate?.updateCartItem(cartItem.cartItemId, skuId: sku.skuId, qty: self.qty, success: {
                                self.dismissView(true)
                                }, fail: {
                                    self.dismissView(false)
                            })
                        }
                    }
                } else {
                    // Missing SKU handling
                    self.delegate?.showFailPopupWithText(String.localize("Fail to add shopping cart: Missing Sku"))
                    ErrorLogManager.sharedManager.recordNonFatalError(withException: .NullPointer, parameters: ["message" : "Missing Sku."])
                }
            } else {
                
                self.dismissView(false)
            }
        default:
            LoadingOverlay.shared.hideOverlayView()
        }
    }
    
    //interactor
    @discardableResult
    private func processCreateOrder(forAction action: CheckoutAction, coupon: Coupon?, completion: ((_ success: Bool, _ error: NSError?) -> ())?) -> Bool{
        guard let vc = presenterViewController() else { return false}
        let (skus, orders, errorMessage) = constructOrdersForChecking()
        if skus.count > 0 {
            LoadingOverlay.shared.showOverlay(vc)
            
            if action == .checkout {
                self.checkoutHandler.processCreateOrder(skus, orders: orders, mmCoupon: coupon, addressKey: self.address?.userAddressKey ?? "", isCart: self.isCart, isFlashSale:self.isFlashSale, failBlock: { [weak self] (error, cartViewController) in
                    
                    if let strongSelf = self {
                        var message = ""
                        if let errorInfo = (error as NSError).userInfo as? [String: String] {
                            if errorInfo["AppCode"] == "MSG_ERR_CA_COUPON_MIN_PURCHASE_MEET" {
                                if let couponReference = errorInfo["Message"], let minSpendAmount = strongSelf.findMinimumSpendAmount(withCouponReference: couponReference, mmCoupon: coupon) {
                                    message = String.localize("MSG_ERR_CA_COUPON_MIN_PURCHASE_MEET").replacingOccurrences(of: "{0}", with: "\(minSpendAmount)")
                                }
                            }
                            else {
                                message = String.localize(errorInfo["AppCode"] ?? "")
                            }
                        }
                        
                        if !message.isEmpty{
                            cartViewController.showError(message, animated: true)
                        }
                    }
                    
                    completion?(false, error as NSError)
                    })
                
                return true
            } else {
                LoadingOverlay.shared.hideOverlayView()
                return false
            }
        } else {
            Log.debug("skus.count = 0")
            
            completion?(false, nil)
            
            if errorMessage.length > 0 {
                self.delegate?.showError(errorMessage, animated: true)
            }
            
            return false
        }
    }
    
    // Data Helper
    func findMinimumSpendAmount(withCouponReference couponReference: String, mmCoupon: Coupon?) -> Double? {
        if let mmCoupon = mmCoupon, mmCoupon.couponReference == couponReference {
            return mmCoupon.minimumSpendAmount
        }
        
        for checkoutMerchantData in merchantDataList {
            if let merchantCoupon = checkoutMerchantData.merchantCoupon, merchantCoupon.couponReference == couponReference {
                return merchantCoupon.minimumSpendAmount
            }
        }
        
        return nil
    }
    
    private func getReferrerUserKey(withSkuId skuId: Int) -> String? {
        for (key, referrerUserKey) in referrerUserKeys {
            if skuId == Int(key) && referrerUserKey.length > 0 {
                return referrerUserKey
            }
        }
        
        return nil
    }
    
    
    // Analytic Tag
    func initAnalyticLog() {
        switch checkoutMode {
        case .style, .multipleMerchant:
            delegate?.initAnalyticsViewRecord(viewDisplayName: "SwipeToBuy", viewLocation: "SwipeToBuy", viewType: "Checkout")
        case .updateStyle:
            var merchantCode: String?
            if let merchantId = cartItem?.merchantId{
                merchantCode = CacheManager.sharedManager.cachedMerchantById(merchantId)?.merchantCode
            }
            delegate?.initAnalyticsViewRecord(brandCode: cartItem?.brandCode ?? "", merchantCode: merchantCode, viewDisplayName: "User : \(Context.getUsername())", viewParameters: "u=\(Context.getUserKey())", viewLocation: "Cart-EditItem", viewType: "Product")
        case .cartCheckout:
            break
        default:
            break
        }
    }
    
    func initAlipayCancelAnalyticLog(){
        delegate?.initAnalyticsViewRecord(viewDisplayName: String.localize("LB_CA_UNPAID_ORDER_FAILED_TO_PAY"), viewLocation: "AlipayCancel", viewType: "Checkout")
    }

    //Wireframing
    func goToConfirmationPage(_ checkoutMode: CheckoutMode, skus: [Sku], styles: [Style], referrerUserKeys: [String : String], targetRef: String) {
        guard let vc = presenterViewController() else { return }
        CheckoutWireframe.presentConfimationPage(fromViewController: vc, checkoutMode: checkoutMode, skus: skus, styles: styles, referrerUserKeys: referrerUserKeys, targetRef: targetRef, checkoutFromSource: self.checkoutFromSource)
    }
    
    private func gotoOrders(orderViewMode: Constants.OmsViewMode) {
        var bundle = QBundle()
        bundle["viewMode"] = QValue(orderViewMode.rawValue)
        Navigator.shared.dopen(Navigator.mymm.website_order_list, params: bundle)
    }
    
    private func gotoOrderDetail() {
        
        if let parentOrder = self.parentOrder {
            var bundle = QBundle()
            bundle["viewMode"] = QValue(Constants.OmsViewMode.toBeShipped.rawValue)
            Navigator.shared.dopen(Navigator.mymm.deeplink_o_orderKey + parentOrder.parentOrderKey, params:bundle)
        }
    }
    
    private func backToRootPage(completion: (() -> ())?) {
        //Go back to previous screen
        if let topNavigation = self.getTopNavigationController() {
            if topNavigation.viewControllers.count > 0 {
                topNavigation.popToRootViewController(animated: false)
                CATransaction.begin()
                CATransaction.setCompletionBlock({
                    if let presentingViewController = self.getTopNavigationController()?.presentingViewController {
                        presentingViewController.dismiss(animated: true, completion: {
                            completion?()
                        })
                    } else {
                        completion?()
                    }
                })
                CATransaction.commit()
            }
        }
    }
    
    private func goToThankYouPage(_ parentOrder: ParentOrder?) {        
        if let topViewController = ShareManager.sharedManager.getTopViewController() {
            let profilePopupViewController = ProfilePopupViewController(presenttationStyle: .none)
            profilePopupViewController.popupType = .OrderSuccess
            profilePopupViewController.viewOrderPressed = { [weak self] in
                if let strongSelf = self {
                    strongSelf.backToRootPage {
                        strongSelf.gotoOrderDetail()
                    }
                }
            }
            
            profilePopupViewController.handleDismiss = { [weak self] in
                
                if let strongSelf = self {
                    //Go to My Order > All for Shopping Cart or Wishlist
                    if strongSelf.isCart || strongSelf.checkoutFromSource == .fromWishlist {
                        
                        strongSelf.backToRootPage {
                            strongSelf.gotoOrders(orderViewMode: .all)
                        }
                    } else {
                        
                        //Go back to previous screen
                        if let navigationController = topViewController.navigationController {
                            navigationController.dismiss(animated: true, completion: nil)
                        }
                    }
                }
            }
            
            topViewController.navigationController?.pushViewController(profilePopupViewController, animated: true)
        }
         
    }
    
    func getTopNavigationController() -> UINavigationController? {
        if let currentTopView = ShareManager.sharedManager.getTopViewController(), let navigationController = currentTopView.navigationController {
                return navigationController
            }
        return nil
    }
    
    func goToAddressPage(_ address: Address?, mode: SignupMode, completion:((_ address: Address?) -> ())?) {
        guard let vc = presenterViewController() else { return }
        CheckoutWireframe.presentAddressPage(address, mode: mode, fromViewController: vc, completion: completion)
    }
    
    func goToFapiaoPage(_ fapiao: String, completion:((_ fapiao: String) -> ())?) {
        guard let vc = presenterViewController() else { return }
        CheckoutWireframe.presentFapiaoPage(fapiao, fromViewController: vc, completion: completion)
    }
}
