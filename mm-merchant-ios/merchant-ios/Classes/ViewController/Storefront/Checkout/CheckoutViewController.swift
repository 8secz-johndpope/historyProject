//
//  CheckoutViewController.swift
//  merchant-ios
//
//  Created by Stephen Yuen on 29/8/2016.
//  Copyright © 2016 WWE & CO. All rights reserved.
//

import UIKit
import PromiseKit
import ObjectMapper
import Alamofire

class CheckoutViewController: MmCartViewController, UITextFieldDelegate, PaymentMethodSelectionViewControllerDelegate, CheckoutFapiaoCellDelegate {
    /*
    enum CheckoutMode: Int {
        case Unknown = 0
        case Style                          // [.Color, .Size, .Quantity, .Address, .PaymentMethod, .ShippingFee, .MerchantCoupon, .MmCoupon, .Fapiao]
        case CartItem                       // [.Color, .Size, .Quantity, .Address, .PaymentMethod, .ShippingFee, .MerchantCoupon, .MmCoupon, .Fapiao]
        case UpdateStyle                    // [.Color, .Size, .Quantity]
        case MultipleMerchant               // [.Style, .Color, .Size, .ShippingFee, .MerchantCoupon, .Fapiao] (.Address, .PaymentMethod, .MmCoupon)
        case CartCheckout                   // (.FullAddress, .FullPaymentMethod) [.FullStyle, .Fapiao, .ShippingFee, .MerchantCoupon, .MerchantTotal, .Comments] (.MmCoupon)
    }
 */


    
    private final let MaximumQuantity = 99
    
    private final let PlaceholderImage = UIImage(named: "holder")
    private final let StyleCellHeight: CGFloat = 96
    private final let labelBottomHeight: CGFloat = 16
    
    private final let ColorCellTopPadding: CGFloat = 12
    private final let ColorCellDimension: CGFloat = 50
    
    private final let SizeHeaderViewTopPadding: CGFloat = 9
    private final let SizeHeaderViewHeight: CGFloat = 30
    
    internal static let MultipleMerchantSizeEdgeInsets = UIEdgeInsets(top: 0, left: 49 , bottom: 0, right: 16)
    internal static let NormalSizeEdgeInsets = UIEdgeInsets(top: 0, left: 16 , bottom: 0, right: 16)
    internal static let SizeMinimumInteritemSpacing: CGFloat = 16

    private var contentView = UIView()
    private var headerView = UIView()
    private var footerView = UIView()
    
    private var checkoutInfoCellDict = [String:CheckoutInfoCell]()
    private var leftSelectionViewDict = [String:UIView]()
    private var checkoutSizeFooterViewFrameDict = [String:CGRect]()
    private var checkoutColorFooterViewFrameDict = [String:CGRect]()

    private var checkoutButton = UIButton()
    private var addToCartButton = UIButton()
    private var confirmButton = UIButton()
    private var grandTotalLabel = UILabel()
    private var totalLabel = UILabel()
    private var countTotalSelectedLabel = UILabel()
    private var totalSavedLabel = UILabel()

    private var checkoutInfoCell: CheckoutInfoCell?
    private var quantityCell: QuantityCell?
    private var mmCouponIndexPath: IndexPath?

    internal var checkoutMode: CheckoutMode = .Unknown
    private var merchantDataList = [CheckoutMerchantData]()
    private var checkoutSections = [CheckoutSection]()
    
    var address: Address?
    private var mmCoupon: Coupon?
    private var listMMCoupon = [Coupon]()
    private var isMMCouponPicked = false
    
    private var redDotButton: ButtonRedDot?
    
    private var qty = 1 // TODO: Move to CheckoutMerchantData > Style
    
    private var browseFromStyleCode: String?
    
    var didDismissHandler: ((_ confirmed: Bool, _ parentOrder: ParentOrder?) -> ())?
    
    private var checkoutHandler: CheckoutHandler!
    private var parentOrder: ParentOrder?
    
    private var checkStockError: NSError? = nil
    private var checkOrderError: NSError? = nil
    
    // For MultipleMerchant Only
    private var skus: [Sku] = []
    private var skuIds: [Int] = []
    private var styles: [Style] = []
    
    // For CartCheckout Only
    private var referrerUserKeys: [String : String] = [:] // skuId : referrerUserKey
    
    private var cartItem: CartItem?
    
    private var defaultFapiaoText: String?

    private var referrerUserKey: String?
    
    private var isRootViewController = false
    private var hasMMCoupon = false
    private var countTotalSelectedWidth: CGFloat = 0
    private let paddingLeft: CGFloat = 20
    private var originalTotal = Double(0)
    
    
    private final let AnimationDuration: NSTimeInterval = 0.3

    // For Analytics
    private var targetRef = ""
    
    func setTargetRef(string: String){
        targetRef = string
    }
    
    init(checkoutMode: CheckoutMode, merchant: Merchant?, style: Style?, referrer: String?, selectedSkuColor: String? = nil, selectedColorId: Int? = nil, selectedSizeId: Int? = nil, redDotButton: ButtonRedDot? = nil, browseFromStyleCode: String? = nil, targetRef: String = "") {
        super.init(nibName: nil, bundle: nil)
        
        self.checkoutMode = checkoutMode
        self.browseFromStyleCode = browseFromStyleCode
        self.targetRef = targetRef
        // TODO: Get Merchant
        
        if let style = style {
            self.preselectColorSize(style, selectedSizeId: selectedSizeId, selectedSkuColor: selectedSkuColor, selectedColorId: selectedColorId)
            if merchant != nil || checkoutMode == .updateStyle {
                let checkoutMerchantData = CheckoutMerchantData(merchant: merchant, styles: [style], fapiaoText: defaultFapiaoText, checkoutMode: checkoutMode)
                merchantDataList.append(checkoutMerchantData)
            }
        } else {
            ErrorLogManager.sharedManager.recordNonFatalError(withException: .NullPointer)
        }
        
        if let _ = referrer {
            self.referrerUserKey = referrer
        }
        
        if let _ = redDotButton {
            self.redDotButton = redDotButton
        }
    }
    
    init(checkoutMode: CheckoutMode, skus: [Sku], styles: [Style], referrer: String?, redDotButton: ButtonRedDot? = nil, targetRef: String = "") {
        super.init(nibName: nil, bundle: nil)
        
        self.checkoutMode = checkoutMode
        self.skus = skus
        self.styles = styles
        self.targetRef = targetRef
        
        if checkoutMode == .multipleMerchant {
            self.deselectStyles(self.styles)
        }
        
        self.updateBrandNameForStyles()
        
        if let _ = referrer {
            self.referrerUserKey = referrer
        }
        
        if let _ = redDotButton {
            self.redDotButton = redDotButton
        }
    }
    
    init(checkoutMode: CheckoutMode, merchant: Merchant?, cartItem: CartItem, referrer: String?, redDotButton: ButtonRedDot? = nil, targetRef: String = "") {
        super.init(nibName: nil, bundle: nil)
        
        self.checkoutMode = checkoutMode
        self.cartItem = cartItem
        self.targetRef = targetRef
        
        if cartItem.qty > 0 {
            qty = cartItem.qty
        }

        if merchant != nil || checkoutMode == .updateStyle {
            let checkoutMerchantData = CheckoutMerchantData(merchant: merchant, styles: [], fapiaoText: defaultFapiaoText, checkoutMode: checkoutMode)
            merchantDataList.append(checkoutMerchantData)
        }
        
        if let _ = referrer {
            self.referrerUserKey = referrer
        }
        
        if let _ = redDotButton {
            self.redDotButton = redDotButton
        }
    }
    
    init(checkoutMode: CheckoutMode, skus: [Sku], styles: [Style], referrerUserKeys: [String : String], targetRef: String = "") {
        super.init(nibName: nil, bundle: nil)
        
        self.checkoutMode = checkoutMode
        self.skus = skus
        self.styles = styles
        self.referrerUserKeys = referrerUserKeys
        self.targetRef = targetRef
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        
        NotificationCenter.default.addObserver(self, selector: #selector(CheckoutViewController.applicationDidBecomeActive), name: UIApplicationDidBecomeActiveNotification, object: nil)
        
        if let viewControllers = self.navigationController?.viewControllers {
            isRootViewController = (viewControllers.count == 1)
        }
        
        contentView.frame = self.view.frame
        
        if isRootViewController {
            // Action Sheet Checkout
            self.view.backgroundColor = UIColor.init(white: 0, alpha: 0.6)
            contentView.y = view.height
            contentView.height = view.height * 2 / 3
            
            let dismissViewButton = UIButton(type: .custom)
            dismissViewButton.frame = view.frame
            dismissViewButton.addTarget(self, action: #selector(self.dismissViewDidTap), for: .touchUpInside)
            self.view.addSubview(dismissViewButton)
        } else {
            // Cart Checkout
            self.title = String.localize("LB_CA_ORDER_CONFIRMATION")
            createBackButton()
        }
        
        view.addSubview(contentView)
        
        checkoutHandler = CheckoutHandler(cartController: self, dismiss: { [weak self] (parentOrder) -> Void in
            if let strongSelf = self {
                if strongSelf.isRootViewController {
                    // Action Sheet Checkout
                    strongSelf.dismissView(nil, confirmed: true)
                } else {
                    // Cart Checkout
                    if let parentOrder = parentOrder {
                        strongSelf.parentOrder = parentOrder
                        
                        strongSelf.view.recordAction(.Submit, sourceRef: parentOrder.parentOrderKey, sourceType: .ParentOrder, targetRef: "Payment-Alipay", targetType: .View)
                        
                        if let orders = parentOrder.orders {
                            for order in orders {
                                strongSelf.view.recordAction(.Submit, sourceRef: order.orderKey, sourceType: .MerchantOrder, targetRef: "Payment-Alipay", targetType: .View)
                            }
                        }
                        
                        if parentOrder.parentOrderStatusId == 2 || parentOrder.parentOrderStatusId == 3 {
                            strongSelf.showThankYou()
                        }
                    } else {
                        ErrorLogManager.sharedManager.recordNonFatalError(withException: .NullPointer)
                    }
                }
                
                strongSelf.enableCheckoutButtons()
            } else {
                ErrorLogManager.sharedManager.recordNonFatalError(withException: .NullPointer)
            }
        })
        
        if checkoutMode != .multipleMerchant && checkoutMode != .cartCheckout {
            setupHeaderView()
        }
        
        setupFooterView()
        setupCollectionView()
        setupDismissKeyboardGesture()
        
        func complete() {
            self.listMMCoupon = CacheManager.sharedManager.listMMCoupon
            self.hasMMCoupon = CacheManager.sharedManager.hasMMCoupon
            
            self.updateOriginalTotal()
            
            if mmCoupon != nil {
                reloadAllData()
                checkStock()
            }

            if let indexPath = mmCouponIndexPath, hasMMCoupon && collectionView.indexPathsForVisibleItems().contains(indexPath) {
                collectionView.reloadData()
            }
        }
        
        if checkoutMode == .multipleMerchant || checkoutMode == .cartCheckout { //TODO: pass styles in
            for sku in skus {
                skuIds.append(sku.skuId)
            }
            
            LoadingOverlay.shared.showOverlay(self)

            let promises = [listMerchant(self.getMerchantCodeList(self.styles)), CacheManager.sharedManager.listClaimedCoupon()]
            when(fulfilled: promises).then { _ -> Void in
                complete()
            }
        } else if checkoutMode != .updateStyle {
            getDefaultAddress()
            firstly {
                return CacheManager.sharedManager.listClaimedCoupon()
                }.then { _ -> Void in
                    complete()
            }
        }
        
        let user = Context.getUserProfile()
        self.defaultFapiaoText = user.lastName + " " + user.firstName
        
        for checkoutMerchantData in self.merchantDataList {
            checkoutMerchantData.fapiaoText = self.defaultFapiaoText
        }
        
        reloadAllData()
        initAnalyticLog()
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        
        self.view.initAnalytics(withViewKey: analyticsViewRecord.viewKey)
        
        if isRootViewController {
            self.navigationController?.isNavigationBarHidden = true
        }
        
        enableCheckoutButtons()
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        
        if isRootViewController {
            UIView.animate(withDuration: AnimationDuration) { [weak self] () -> Void in
                if let strongSelf = self {
                    strongSelf.contentView.transform = CGAffineTransformMakeTranslation(0, -strongSelf.contentView.height)
                } else {
                    ErrorLogManager.sharedManager.recordNonFatalError(withException: .NullPointer)
                }
            }
        }
        
        if let checkoutInfoCell = checkoutInfoCell {
            switch checkoutMode {
            case .style:
                if let checkoutMerchantData = merchantDataList.first {
                    if let style: Style = checkoutMerchantData.styles.first {
                        checkoutInfoCell.setData(withStyle: style)
                        
                        reloadAllData()
                    }
                }
            default:
                break
            }
        }
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    @objc func applicationDidBecomeActive(sender: NSNotification) {
        handleCheckoutCompletionActions()
    }

    // MARK: - Setup
    
    private func setupHeaderView() {
        let viewHeight: CGFloat = 98
        
        headerView.frame = CGRect(x: 0, y: 0, width: contentView.width, height: viewHeight)
        
        checkoutInfoCell = CheckoutInfoCell(frame: CGRect(x:0, y: 0, width: headerView.width, height: headerView.height), haveCouponButton: [.style, .CartItem].contains(checkoutMode) ? true : false)
        
        var data: Any?
        
        if let checkoutInfoCell = checkoutInfoCell {
            switch checkoutMode {
            case .style:
                if let checkoutMerchantData = merchantDataList.first {
                    if let style: Style = checkoutMerchantData.styles.first {
                        checkoutInfoCell.setData(withStyle: style)
                        
                        data = checkoutMerchantData.merchant
                        
                        reloadAllData()
                        let sku = style.searchSku(style.selectedSizeId, colorId: style.selectedColorId, skuColor: style.selectedSkuColor)
                        
                        var merchantCode = style.merchantCode
                        
                        if let merchant = checkoutMerchantData.merchant, merchantCode.length == 0 {
                            merchantCode = merchant.merchantCode
                        }
                        
                        checkoutInfoCell.initAnalytics(withViewKey: self.analyticsViewRecord.viewKey, impressionKey: AnalyticsManager.sharedManager.recordImpression(brandCode: "\(style.brandId)", impressionRef: style.styleCode, impressionType: "Product", impressionVariantRef: sku?.skuCode ?? "", impressionDisplayName: style.skuName, merchantCode: merchantCode, positionComponent: "ProductListing", positionIndex: 1, positionLocation: getPositionLocation(), viewKey: self.analyticsViewRecord.viewKey))
                        
                    } else {
                        ErrorLogManager.sharedManager.recordNonFatalError(withException: .DataIsEmpty)
                    }
                } else {
                    ErrorLogManager.sharedManager.recordNonFatalError(withException: .DataIsEmpty)
                }
            case .CartItem:
                if let cartItem = self.cartItem {
                    LoadingOverlay.shared.showOverlay(self)

                    firstly {
                        return ProductManager.searchStyleWithSkuId(cartItem.skuId)
                    }.then { response -> Void in
                        if let style = response as? Style {
                            if let checkoutMerchantData = self.merchantDataList.first {
                                
                                let selectedColorSkus = style.skuList.filter{$0.skuColor == cartItem.skuColor && $0.colorId == cartItem.colorId && !$0.isOutOfStock()}
                                if !selectedColorSkus.isEmpty{
                                    for i in 0..<style.validColorList.count {
                                        if (style.validColorList[i].colorId == cartItem.colorId) &&  (style.validColorList[i].skuColor == cartItem.skuColor){
                                            style.colorIndexSelected = i
                                            break
                                        }
                                    }
                                }
                                
                                let filteredSkuList = style.skuList.filter({$0.skuId == cartItem.skuId && !$0.isOutOfStock()})
                                
                                if filteredSkuList.count > 0 {
                                    let selectedSizeId = filteredSkuList[0].sizeId
                                    
                                    for i in 0..<style.validSizeList.count {
                                        if style.validSizeList[i].sizeId == selectedSizeId {
                                            style.sizeIndexSelected = i
                                            break
                                        }
                                    }
                                }
                                
                                checkoutMerchantData.styles = [style]
                                
                                checkoutInfoCell.setData(withStyle: style)
                                data = checkoutMerchantData.merchant

                                self.reloadAllData()
                            }
                        } else {
                            ErrorLogManager.sharedManager.recordNonFatalError(withException: .NullPointerOrTypeMismatch)
                        }
                    }.always {
                        LoadingOverlay.shared.hideOverlayView()
                    }.catch { _ -> Void in
                        Log.error("error")
                    }
                } else {
                    ErrorLogManager.sharedManager.recordNonFatalError(withException: .NullPointer)
                }
            case .updateStyle:
                if let cartItem = self.cartItem {
                    checkoutInfoCell.setData(withCartItem: cartItem)
                    LoadingOverlay.shared.showOverlay(self)

                    let merchantIds = [String(cartItem.merchantId)]
                    firstly {
                        return ProductManager.searchStyleWithStyleCode(cartItem.styleCode, merchantIds: merchantIds)
                    }.then { response -> Void in
                        if let style = response as? Style {
                            if let checkoutMerchantData = self.merchantDataList.first {
                                for (index, color) in style.validColorList.enumerate() {
                                    if (color.colorId == cartItem.colorId) && (color.skuColor == cartItem.skuColor) {
                                        style.colorIndexSelected = index
                                        style.selectedColorId = color.colorId
                                        style.selectedSkuColor = color.skuColor
                                        break
                                    }
                                }
                                
                                for (index, size) in style.validSizeList.enumerate() {
                                    if size.sizeId == cartItem.sizeId {
                                        style.sizeIndexSelected = index
                                        style.selectedSizeId = size.sizeId
                                        break
                                    }
                                }
                                
                                checkoutMerchantData.styles = [style]
                            } else {
                                ErrorLogManager.sharedManager.recordNonFatalError(withException: .DataIsEmpty)
                            }
                        } else {
                            ErrorLogManager.sharedManager.recordNonFatalError(withException: .NullPointerOrTypeMismatch)
                        }
                        
                        self.reloadAllData()
                    }.always {
                        LoadingOverlay.shared.hideOverlayView()
                    }.catch { _ -> Void in
                        Log.error("error")
                    }
                    
                    var merchantCode = cartItem.merchantCode
                    
                    if let checkoutMerchantData = self.merchantDataList.first, let merchant = checkoutMerchantData.merchant, merchantCode.length == 0 {
                        merchantCode = merchant.merchantCode
                    }
                    
                    checkoutInfoCell.initAnalytics(withViewKey: self.analyticsViewRecord.viewKey, impressionKey: AnalyticsManager.sharedManager.recordImpression(brandCode: "\(cartItem.brandId)", impressionRef: cartItem.styleCode, impressionType: "Product", impressionVariantRef: cartItem.skuCode, impressionDisplayName: cartItem.skuName, merchantCode: merchantCode, positionComponent: "ProductListing", positionIndex: 1, positionLocation: getPositionLocation(), viewKey: self.analyticsViewRecord.viewKey))
                } else {
                    ErrorLogManager.sharedManager.recordNonFatalError(withException: .NullPointer)
                }
            default:
                break
            }
            
            checkoutInfoCell.viewCouponHandler = { [weak self] in
                let viewController = MerchantCouponsListViewController()
                if let strongSelf = self {
                    // record action
                    strongSelf.view.recordAction(.Tap, sourceRef: "SwipeToBuy-MerchantCouponClaimList", sourceType: .Button, targetRef: "MerchantCouponClaimList", targetType: .View)

                    viewController.data = data
                    
                    strongSelf.navigationController?.isNavigationBarHidden = false
                    strongSelf.navigationController?.pushViewController(viewController, animated: true)
                }
            }

            headerView.addSubview(checkoutInfoCell)
        }
        
        contentView.addSubview(headerView)
    }
    
    private func setupFooterView() {
        let viewHeight: CGFloat = 65
        let paddingRight: CGFloat = 8
        let leftButtonWidth: CGFloat = 88
        let rightButtonWidth: CGFloat = 84
        let buttonHeight: CGFloat = 41
        let paddingBetweenItems: CGFloat = 4
        
        footerView.frame = CGRect(x: 0, y: contentView.height - viewHeight, width: contentView.width, height: viewHeight)
        footerView.backgroundColor = UIColor.white
        
        totalLabel.text = String.localize("LB_CA_EDITITEM_SUBTOTAL")
        totalLabel.formatSize(14)
        totalLabel.sizeToFit()
        totalLabel.frame = CGRect(x: paddingLeft, y: (footerView.height - labelBottomHeight) / 2, width: totalLabel.width, height: labelBottomHeight)
        
        footerView.addSubview(totalLabel)
        
        let rightButtonFrame = CGRect(x: footerView.width - rightButtonWidth - paddingRight, y: (footerView.height - buttonHeight) / 2, width: rightButtonWidth, height: buttonHeight)
        var grandTotalLabelWidth: CGFloat = 0
        
        switch checkoutMode {
        case .updateStyle:
            confirmButton.frame = rightButtonFrame
            confirmButton.formatPrimary()
            confirmButton.isUserInteractionEnabled = true
            confirmButton.setTitle(String.localize("LB_CA_CONFIRM"), for: .normal)
            confirmButton.addTarget(self, action: #selector(self.confirm), for: .touchUpInside)
            footerView.addSubview(confirmButton)
            
            grandTotalLabelWidth = confirmButton.x - totalLabel.frame.maxX
        case .cartCheckout:
            let confirmButtonWidth: CGFloat = 106
            confirmButton.frame = CGRect(x: footerView.width - confirmButtonWidth - paddingRight, y: (footerView.height - buttonHeight) / 2, width: confirmButtonWidth, height: buttonHeight)
            confirmButton.formatPrimary()
            confirmButton.isUserInteractionEnabled = true
            confirmButton.setTitle(String.localize("LB_CA_SUBMIT_ORDER"), for: .normal)
            confirmButton.addTarget(self, action: #selector(self.checkout), for: .touchUpInside)
            footerView.addSubview(confirmButton)
            
            grandTotalLabelWidth = confirmButton.x - totalLabel.frame.maxX
            countTotalSelectedWidth = confirmButton.x - paddingLeft - paddingBetweenItems

        default:
            checkoutButton.frame = rightButtonFrame
            checkoutButton.formatPrimary()
            checkoutButton.setTitle(String.localize("LB_CA_PDP_SWIPE2PAY_PURCHASE"), for: .normal)
            checkoutButton.addTarget(self, action: #selector(self.checkout), for: .touchUpInside)
            footerView.addSubview(checkoutButton)
            
            addToCartButton.frame = CGRect(x: checkoutButton.x - leftButtonWidth - paddingBetweenItems, y: checkoutButton.y, width: leftButtonWidth, height: checkoutButton.height)
            addToCartButton.formatPrimary()
            addToCartButton.setTitleColor(UIColor.primary3(), for: .normal)
            addToCartButton.setTitle(String.localize("LB_CA_ADD2CART"), for: .normal)
            addToCartButton.backgroundColor = UIColor.white
            addToCartButton.layer.cornerRadius = Constants.Button.Radius
            addToCartButton.layer.borderColor = UIColor.primary3().cgColor
            addToCartButton.layer.borderWidth = 1
            addToCartButton.addTarget(self, action: #selector(self.addToCart), for: .touchUpInside)
            footerView.addSubview(addToCartButton)
            
            grandTotalLabelWidth = addToCartButton.x - totalLabel.frame.maxX - paddingBetweenItems
            countTotalSelectedWidth = addToCartButton.x - paddingLeft - paddingBetweenItems
        }
        
        grandTotalLabel.frame = CGRect(x: totalLabel.frame.maxX, y: (footerView.height - labelBottomHeight) * 0.3, width: grandTotalLabelWidth, height: labelBottomHeight)
        grandTotalLabel.formatSize(14)
        grandTotalLabel.textColor = UIColor.primary3()
        grandTotalLabel.lineBreakMode = .byTruncatingTail
        grandTotalLabel.numberOfLines = 1
        grandTotalLabel.adjustsFontSizeToFitWidth = true
        footerView.addSubview(grandTotalLabel)
        
        countTotalSelectedLabel.frame = CGRect(x: paddingLeft, y: (footerView.height - labelBottomHeight) * 0.7, width: countTotalSelectedWidth, height: labelBottomHeight)
        countTotalSelectedLabel.formatSize(12)
        countTotalSelectedLabel.textColor = UIColor.secondary3()
        countTotalSelectedLabel.lineBreakMode = .byTruncatingTail
        countTotalSelectedLabel.numberOfLines = 1
        countTotalSelectedLabel.adjustsFontSizeToFitWidth = true
        countTotalSelectedLabel.isHidden = true
        footerView.addSubview(countTotalSelectedLabel)
        
        totalSavedLabel.formatSize(12)
        totalSavedLabel.textColor = UIColor.secondary3()
        totalSavedLabel.lineBreakMode = .byTruncatingTail
        totalSavedLabel.numberOfLines = 1
        totalSavedLabel.adjustsFontSizeToFitWidth = true
        totalSavedLabel.isHidden = true
        footerView.addSubview(totalSavedLabel)

        let borderView = UIView(frame: CGRect(x: 0, y: 0, width: footerView.width, height: 1))
        borderView.backgroundColor = UIColor.secondary1()
        footerView.addSubview(borderView)
        
        contentView.addSubview(footerView)
        
        addToCartButton.addTarget(self, action: #selector(self.addToCart), for: .touchUpInside)
    }
    
    private func setupCollectionView() {
        if isRootViewController {
            let checkoutActionSheetCollectionViewFlowLayout = CheckoutActionSheetCollectionViewFlowLayout()
            checkoutActionSheetCollectionViewFlowLayout.checkoutViewController = self
            checkoutActionSheetCollectionViewFlowLayout.sectionInset = UIEdgeInsets(top: 0, left: 0, bottom: 0, right: 0)
            checkoutActionSheetCollectionViewFlowLayout.itemSize = CGSize(width: self.view.frame.width, height: 120)
            collectionView.setCollectionViewLayout(checkoutActionSheetCollectionViewFlowLayout, animated: true)
            
            collectionView.frame = CGRect(x:0, y: headerView.frame.maxY, width: contentView.width, height: contentView.height - footerView.height - headerView.frame.maxY)
        } else {
            collectionView.frame = CGRect(x:0, y: StartYPos, width: contentView.width, height: contentView.height - footerView.height - 64)
        }
        
        collectionView.backgroundColor = UIColor.white
        
        collectionView.register(SizeHeaderView.self, forSupplementaryViewOfKind: UICollectionElementKindSectionHeader, withReuseIdentifier: SizeHeaderView.ViewIdentifier)
        collectionView.register(CouponInputHeaderView.self, forSupplementaryViewOfKind: UICollectionElementKindSectionHeader, withReuseIdentifier: CouponInputHeaderView.ViewIdentifier)
        collectionView.register(SeparatorHeaderView.self, forSupplementaryViewOfKind: UICollectionElementKindSectionFooter, withReuseIdentifier: SeparatorHeaderView.ViewIdentifier)
        collectionView.register(CheckoutFooterView.self, forSupplementaryViewOfKind: UICollectionElementKindSectionFooter, withReuseIdentifier: CheckoutFooterView.ViewIdentifier)
        
        collectionView.register(CheckoutInfoCell.self, forCellWithReuseIdentifier: CheckoutInfoCell.CellIdentifier)
        collectionView.register(ColorCollectionCell.self, forCellWithReuseIdentifier: ColorCollectionCell.CellIdentifier)
        collectionView.register(SizeCollectionCell.self, forCellWithReuseIdentifier: SizeCollectionCell.CellIdentifier)
        collectionView.register(QuantityCell.self, forCellWithReuseIdentifier: QuantityCell.CellIdentifier)
        collectionView.register(CheckoutCell.self, forCellWithReuseIdentifier: CheckoutCell.CellIdentifier)
        collectionView.register(CheckoutCouponCell.self, forCellWithReuseIdentifier: CheckoutCouponCell.CellIdentifier)
        collectionView.register(CheckoutFapiaoCell.self, forCellWithReuseIdentifier: CheckoutFapiaoCell.CellIdentifier)
        
        collectionView.register(CheckoutFullAddressCell.self, forCellWithReuseIdentifier: CheckoutFullAddressCell.CellIdentifier)
        collectionView.register(CheckoutFullPaymentMethodCell.self, forCellWithReuseIdentifier: CheckoutFullPaymentMethodCell.CellIdentifier)
        collectionView.register(CheckoutProductCell.self, forCellWithReuseIdentifier: CheckoutProductCell.CellIdentifier)
        collectionView.register(CheckoutCommentCell.self, forCellWithReuseIdentifier: CheckoutCommentCell.CellIdentifier)
        
        contentView.addSubview(collectionView)
    }
    
    private func initAnalyticLog() {
        switch checkoutMode {
        case .style, .multipleMerchant:
            self.initAnalyticsViewRecord(viewDisplayName: "SwipeToBuy", viewLocation: "SwipeToBuy", viewType: "Checkout")
        case .updateStyle:
            self.initAnalyticsViewRecord(brandCode: cartItem?.brandCode, merchantCode: cartItem?.merchantCode, viewDisplayName: "\(Context.getUsername())", viewParameters: "(Context.getUserKey())", viewLocation: "Cart-EditItem", viewType: "Product")
        case .cartCheckout:
            break
        default:
            break
        }
    }
    
    // MARK: - Action
    
    func setValueCountSelectedLabel(value: Int) {
        countTotalSelectedLabel.text = String.localize("LB_SELECTED_PI_NO") + "(\(value))"
        if value > 1 {
            countTotalSelectedLabel.isHidden = false
            countTotalSelectedLabel.frame = CGRect(x:countTotalSelectedLabel.x, y: countTotalSelectedLabel.y, width: StringHelper.getTextWidth(countTotalSelectedLabel.text!, height: countTotalSelectedLabel.height, font: countTotalSelectedLabel.font), height: countTotalSelectedLabel.height)
            totalLabel.frame.originY = (footerView.height - labelBottomHeight) * 0.3
            grandTotalLabel.frame.originY = (footerView.height - labelBottomHeight) * 0.3
        } else {
            countTotalSelectedLabel.isHidden = true
            //Align Center Vertical when hiding countTotalSelectedLabel
            totalLabel.frame.originY = (footerView.height - labelBottomHeight) / 2
            grandTotalLabel.frame.originY = (footerView.height - labelBottomHeight) / 2
        }
    }
    
    func dismissView(sender: UIButton?, confirmed: Bool = false) {
        UIView.animate(withDuration: AnimationDuration, animations: { [weak self] () -> Void in
            if let strongSelf = self {
                strongSelf.contentView.transform = CGAffineTransform.identity
            } else {
                ErrorLogManager.sharedManager.recordNonFatalError(withException: .NullPointer)
            }
        }, completion: { [weak self] (success) -> Void in
            if let strongSelf = self {
                strongSelf.dismiss(animated: false, completion: { [weak strongSelf] in
                    if let strongSelf = strongSelf {
                        if let callback = strongSelf.didDismissHandler {
                            callback(confirmed: confirmed, parentOrder: strongSelf.checkoutHandler.getConfirmedOrder())
                        } else {
                            ErrorLogManager.sharedManager.recordNonFatalError(withException: .NullPointer)
                        }
                    } else {
                        ErrorLogManager.sharedManager.recordNonFatalError(withException: .NullPointer)
                    }
                })
            } else {
                ErrorLogManager.sharedManager.recordNonFatalError(withException: .NullPointer)
            }
        })
    }
    
    @objc func dismissViewDidTap(sender: UIButton?) {
        dismissView(sender,confirmed: false)
    }
    
    @objc func addToCart(sender: UIButton) {
        LoadingOverlay.shared.showOverlay(self)
        checkStock(proceedActionIfSuccess: .addToCart)
        self.view.recordAction(.Tap, sourceRef: "AddToCart", sourceType: .Button, targetRef: targetRef, targetType: .View)
    }
    
    @objc func checkout(sender: UIButton) {
        sender.isUserInteractionEnabled = false
        sender.formatDisable()
        checkOrder(proceedActionIfSuccess: .checkout, completion: { [weak self] (success, error) in
            if let _ = self{
                sender.formatPrimary()
                sender.isUserInteractionEnabled = true
            }
        })
        
        switch checkoutMode {
        case .cartCheckout:
            self.view.recordAction(.Tap, sourceRef: "SubmitOrder", sourceType: .Button, targetRef: "Payment-Alipay", targetType: .View)
        default:
            self.view.recordAction(.Tap, sourceRef: "AddToCart", sourceType: .Button, targetRef: "Payment-Alipay", targetType: .View)
        }
    }
    
    @objc func confirm(sender: UIButton) {
        checkStock(proceedActionIfSuccess: .updateCart)
        self.view.recordAction(.Tap, sourceRef: "Confirm", sourceType: .Button, targetRef: "Cart", targetType: .View)
    }
    
    @objc func showProductDetail(sender: UIGestureRecognizer) {
        if let style = merchantDataList.first()?.styles.first() {
            if let browseFromStyleCode = browseFromStyleCode, browseFromStyleCode == style.styleCode {
                if let parentViewController = parentViewController {
                    parentViewController.dismiss(animated: true, completion: nil)
                } else {
                    ErrorLogManager.sharedManager.recordNonFatalError(withException: .NullPointer)
                }
            } else {
                showProductDetailView(withStyle: style)
            }
            
            if self.checkoutMode == .style {
                if let checkoutInfoCell = checkoutInfoCell {
                    checkoutInfoCell.recordAction(.Tap, sourceRef: style.styleCode, sourceType: .Product, targetRef: "PDP", targetType: .View)
                } else {
                    ErrorLogManager.sharedManager.recordNonFatalError(withException: .NullPointer)
                }
            }
        } else {
            ErrorLogManager.sharedManager.recordNonFatalError(withException: .DataIsEmpty)
        }
    }
    
    @objc func stepperValueChanged(sender: UIButton) {
        // Note: These button will not be shown on multiple merchant
        
        if let style = merchantDataList.first?.styles.first {
            let selectedColor = style.getValidColorAtIndex(style.colorIndexSelected)
            let selectedSizeId = style.getValidSizeIdAtIndex(style.sizeIndexSelected)
            
            if let sku = style.searchSku(selectedSizeId, colorId: selectedColor?.colorId, skuColor: selectedColor?.skuColor) {
                if checkoutMode == .updateStyle && sku.isOutOfStock() {
                    self.showError(String.localize("LB_OUT_OF_STOCK"), animated: true)
                    return
                }
                
                var qtyValue = self.qty
                
                if sender.tag == QuantityCell.Tag.MinusButton {
                    qtyValue -= 1
                } else if sender.tag == QuantityCell.Tag.AddButton {
                    if qtyValue < Int.max - 1 {
                        qtyValue += 1
                    } else {
                        return
                    }
                }
                
                if qtyValue < 1 {
                    qtyValue = 1
                }
                
                self.qty = getValidatedQuantity(qtyValue)
                
                updateOriginalTotal()
                
                if let quantityCell = self.quantityCell {
                    quantityCell.qtyTextField.text = String(self.qty)
                    checkStock()
                    
                    quantityCell.recordAction(.Input, sourceRef: String(self.qty), sourceType: .Qty, targetRef: sku.skuCode, targetType: .ProductSku)
                } else {
                    ErrorLogManager.sharedManager.recordNonFatalError(withException: .NullPointer)
                }
            } else {
                ErrorLogManager.sharedManager.recordNonFatalError(withException: .NullPointer, parameters: ["message" : "Sku not found."])
            }
        } else {
            ErrorLogManager.sharedManager.recordNonFatalError(withException: .DataIsEmpty)
        }
    }
    
    func showInputCouponView(isMMCoupon: Bool, atIndex index: Int = 0) {
        if LoginManager.getLoginState() == .validUser {
            let couponSelectionVC = MerchantCouponSelectionViewController()
            let cartMerchant = CartMerchant()
            var total: Double = 0
            
            if isMMCoupon {
                // record action
                if checkoutMode == .cartCheckout {
                    view.recordAction(.Tap, sourceRef: "Checkout-Coupon-MyMMCoupon", sourceType: .Button, targetRef: "MyCoupon-MyMMCouponAvail", targetType: .View)
                }
                else {
                    view.recordAction(.Tap, sourceRef: "Coupon-MyMM", sourceType: .Button, targetRef: "Coupon-MyMM", targetType: .View)
                }
                
                let mmMerchant = Merchant.MM()
                cartMerchant.merchantName = mmMerchant.merchantName
                cartMerchant.merchantId = mmMerchant.merchantId
                couponSelectionVC.defaultCoupon = mmCoupon
                
                for checkoutMerchantData in merchantDataList {
                    switch checkoutMode {
                    case .cartCheckout:
                        total += checkoutMerchantData.getMerchantTotal(includeShipmentFee: false, includeCoupon: true, selectedSkus: skus)
                    default:
                        total += checkoutMerchantData.getMerchantTotal(includeShipmentFee: false, includeCoupon: true, qty: qty)
                    }
                }
            }
            else {
                // record action
                if checkoutMode == .cartCheckout {
                    view.recordAction(.Tap, sourceRef: "Checkout-Coupon-MerchantCoupon", sourceType: .Button, targetRef: "MyCoupon-MerchantCouponAvail", targetType: .View)
                }
                else {
                    view.recordAction(.Tap, sourceRef: "Coupon-Merchant", sourceType: .Button, targetRef: "Coupon-Merchant", targetType: .View)
                }

                let checkoutMerchantData = merchantDataList[index]
                cartMerchant.merchantName = checkoutMerchantData.merchant?.merchantName ?? ""
                cartMerchant.merchantImage = checkoutMerchantData.merchant?.headerLogoImage ?? ""
                cartMerchant.merchantId = checkoutMerchantData.merchant?.merchantId ?? 0
                couponSelectionVC.defaultCoupon = checkoutMerchantData.merchantCoupon

                switch checkoutMode {
                case .cartCheckout:
                    total += checkoutMerchantData.getMerchantTotal(includeShipmentFee: false, includeCoupon: false, selectedSkus: skus)
                default:
                    total += checkoutMerchantData.getMerchantTotal(includeShipmentFee: false, includeCoupon: false, qty: qty)
                }
            }

            couponSelectionVC.data = cartMerchant
            couponSelectionVC.totalAmount = total
//            couponSelectionVC.couponSelectedHandler = { [weak self] (coupon, isMmCoupon, merchantId) -> Void in
//                if let strongSelf = self {
//                    if isMmCoupon {
//                        strongSelf.mmCoupon = coupon
//                        strongSelf.isMMCouponPicked = true
//                    } else {
//                        for checkoutMerchantData in strongSelf.merchantDataList where checkoutMerchantData.merchant?.merchantId == merchantId {
//                            checkoutMerchantData.merchantCoupon = coupon
//                            break
//                        }
//                    }
//                    
//                    strongSelf.checkStock()
//                    strongSelf.reloadAllData()
//                }
//            }

            self.navigationController?.isNavigationBarHidden = false
            self.navigationController?.pushViewController(couponSelectionVC, animated: true)
        }
    }
    
    func showAddressView() {
        self.view.recordAction(.Tap, sourceRef: address?.userAddressKey ?? "", sourceType: .ShippingAddress, targetRef: "UserAddress-Select", targetType: .View)
        
        if let _ = address {
            let addressSelectionViewController = AddressSelectionViewController()
            addressSelectionViewController.viewMode = .checkout
            addressSelectionViewController.selectedAddress = address
            
            addressSelectionViewController.didSelectAddress = { [weak self] (address) -> Void in
                if let strongSelf = self {
                    strongSelf.address = address
                    strongSelf.reloadAllData()
                } else {
                    ErrorLogManager.sharedManager.recordNonFatalError(withException: .NullPointer)
                }
            }
            
            self.navigationController?.pushViewController(addressSelectionViewController, animated: true)
        } else {
            let addressAdditionViewController = AddressAdditionViewController()
            addressAdditionViewController.signupMode = .checkout
            addressAdditionViewController.disableBackButton = false
            
            addressAdditionViewController.didAddAddress = { [weak self] (address) -> Void in
                if let strongSelf = self {
                    strongSelf.address = address
                    strongSelf.reloadAllData()
                } else {
                    ErrorLogManager.sharedManager.recordNonFatalError(withException: .NullPointer)
                }
            }
            
            self.navigationController?.pushViewController(addressAdditionViewController, animated: true)
        }
    }
    
    func showProductDetailView(withStyle style: Style) {
        let color = Color()
        color.colorId = style.selectedColorId
        color.colorKey = style.selectedColorKey
        color.skuColor = style.selectedSkuColor ?? ""
        
        let styleFilter = StyleFilter()
        styleFilter.colors = [color]
    
        let styleViewController = StyleViewController(style: style, styleFilter: styleFilter, isProductActive: style.isValid())
        
        self.navigationController?.isNavigationBarHidden = false
        self.navigationController?.pushViewController(styleViewController, animated: true)
    }
    
    func updateOriginalTotal() {
        originalTotal = 0
        var mmTotal = Double(0)
        var merchantTotal = Double(0)
        
        for checkoutMerchantData in merchantDataList {
            switch checkoutMode {
            case .updateStyle: break
                
            case .cartCheckout:
                originalTotal += checkoutMerchantData.getMerchantTotal(includeShipmentFee: true, includeCoupon: false, selectedSkus: [])
                mmTotal += checkoutMerchantData.getMerchantTotal(includeShipmentFee: false, includeCoupon: true, selectedSkus: [])
                merchantTotal += checkoutMerchantData.getMerchantTotal(includeShipmentFee: false, includeCoupon: false, selectedSkus: [])

            default:
                originalTotal += checkoutMerchantData.getMerchantTotal(includeShipmentFee: true, includeCoupon: false, qty: qty)
                mmTotal += checkoutMerchantData.getMerchantTotal(includeShipmentFee: false, includeCoupon: true, qty: qty)
                merchantTotal += checkoutMerchantData.getMerchantTotal(includeShipmentFee: false, includeCoupon: false, qty: qty)

            }
        }
        
        if !isMMCouponPicked {
            var found = false
            for coupon in listMMCoupon {
                if coupon.minimumSpendAmount <= mmTotal {
                    mmCoupon = coupon
                    found = true
                    break
                }
            }
            
            if !found {
                mmCoupon = nil
            }
        }
        else {
            if let mmCoupon = mmCoupon, mmCoupon.minimumSpendAmount > mmTotal {
                self.mmCoupon = nil
            }
        }
        
        for checkoutMerchantData in merchantDataList {
            if let merchantCoupon = checkoutMerchantData.merchantCoupon, merchantCoupon.minimumSpendAmount > merchantTotal {
                checkoutMerchantData.merchantCoupon = nil
            }
        }
        
        if originalTotal == 0 {
            totalSavedLabel.isHidden = true
        }
    }
    
    private func updateTotalPrice() {
        
        var total: Double = 0

        // 1. Calculate the sub-total for merchant item
        // 2. + Shipping fee
        // 3. - Discount
        // 4. - Merchant coupon
        // 5. Calculate the sub-total for all item
        // 6. - MM coupon
            
        for checkoutMerchantData in merchantDataList {
            switch checkoutMode {
            case .updateStyle:
                total += checkoutMerchantData.getMerchantTotal(includeShipmentFee: false, includeCoupon: false, qty: qty)
            case .cartCheckout:
                total += checkoutMerchantData.getMerchantTotal(includeShipmentFee: true, includeCoupon: true, selectedSkus: skus)
            default:
                total += checkoutMerchantData.getMerchantTotal(includeShipmentFee: true, includeCoupon: true, qty: qty)
            }
        }
    
        if let mmCoupon = mmCoupon, mmCoupon.minimumSpendAmount <= total {
            total -= mmCoupon.couponAmount
        }
        
        grandTotalLabel.text = total.formatPrice()

        let differentTotal = originalTotal - total
        
        if differentTotal > 0 {
            totalSavedLabel.isHidden = false

            totalSavedLabel.text = String.localize("LB_CA_CHECKOUT_COUPON_SAVED").replacingOccurrences(of: "{SavedAmount}", with: differentTotal.formatPriceWithoutCurrencySymbol() ?? "")

            totalLabel.frame.originY = (footerView.height - labelBottomHeight) * 0.3
            grandTotalLabel.frame.originY = (footerView.height - labelBottomHeight) * 0.3

            if countTotalSelectedLabel.isHidden {
                totalSavedLabel.frame = CGRect(x: paddingLeft, y: (footerView.height - labelBottomHeight) * 0.7, width: countTotalSelectedWidth, height: labelBottomHeight)
            }
            else {
                countTotalSelectedLabel.frame = CGRect(x:countTotalSelectedLabel.x, y: countTotalSelectedLabel.y, width: StringHelper.getTextWidth(countTotalSelectedLabel.text!, height: countTotalSelectedLabel.height, font: countTotalSelectedLabel.font), height: countTotalSelectedLabel.height)
                totalSavedLabel.frame = CGRect(x: countTotalSelectedLabel.frame.maxX, y: countTotalSelectedLabel.y, width: countTotalSelectedWidth - countTotalSelectedLabel.width, height: labelBottomHeight)
            }
        }
        else {
            totalSavedLabel.isHidden = true
            if countTotalSelectedLabel.isHidden {
                totalLabel.frame.originY = (footerView.height - labelBottomHeight) / 2
                grandTotalLabel.frame.originY = (footerView.height - labelBottomHeight) / 2
            }
        }
    }
    
    private func updateButtonsState() {
        var countSelectedProduct = 0
        
        for checkoutMerchantData in merchantDataList {
            for style in checkoutMerchantData.styles where style.selected {
                countSelectedProduct += 1
            }
        }
        
        if checkoutMode != .updateStyle && checkoutMode != .cartCheckout {
            if countSelectedProduct > 0 {
                addToCartButton.isEnabled = true
                checkoutButton.isUserInteractionEnabled = true
                checkoutButton.formatPrimary()
            } else {
                addToCartButton.isEnabled = false
                checkoutButton.isUserInteractionEnabled = false
                checkoutButton.formatDisable()
            }
            
            setValueCountSelectedLabel(countSelectedProduct) //MM-21504 hide countSelectedLabel when value = 0
            
            updateOriginalTotal()

            if countSelectedProduct <= 0 {
                grandTotalLabel.text = 0.formatPrice() //Fix for can't update price when don't select any product
            } else {
                updateTotalPrice()
            }
        } else {
            setValueCountSelectedLabel(0) //hide label count selected product for update cart quantity
            updateOriginalTotal()
            updateTotalPrice()
        }
    }
    
    // MARK: - Observer
    
    override func keyboardWillShowNotification(_ notification: NSNotification) {
        super.keyboardWillShowNotification(notification)
        
        if let keyboardSize = (notification.userInfo?[UIKeyboardFrameEndUserInfoKey] as? NSValue)?.cgRectValue {
            contentView.y = ScreenHeight - contentView.height - keyboardSize.height
            
            if !isRootViewController {
                var frame = collectionView.frame
                frame.size.height = contentView.height - footerView.height - (keyboardSize.height + 64)
                frame.origin.y = (keyboardSize.height + 64)
                collectionView.frame = frame
            }
        } else {
            ErrorLogManager.sharedManager.recordNonFatalError(withException: .NullPointer)
        }
    }
    
    override func keyboardWillHideNotification(_ notification: NSNotification) {
        super.keyboardWillHideNotification(notification)
        
        contentView.y = ScreenHeight - contentView.height
        
        if !isRootViewController {
            var frame = collectionView.frame
            frame.size.height = contentView.height - footerView.height - 64
            frame.origin.y = 64
            collectionView.frame = frame
        }
    }
    
    // MARK: - 
    
    private func reloadAllData() {
        // Update checkoutInfoCell product image (Single product)
        if let checkoutInfoCell = checkoutInfoCell {
            if let style = merchantDataList.first?.styles.first {
                let color = style.getValidColorAtIndex(style.colorIndexSelected)
                
                if let imageKey = style.findImageKeyByColorKey(color?.colorKey ?? "") {
                    checkoutInfoCell.updateProductImage(withImageKey: imageKey)
                } else {
                    ErrorLogManager.sharedManager.recordNonFatalError(withException: .NullPointer)
                }
            } else {
                ErrorLogManager.sharedManager.recordNonFatalError(withException: .DataIsEmpty)
            }
        }
        
        checkoutSections.removeAll()
        
        for checkoutMerchantData in merchantDataList {
            checkoutMerchantData.updateCheckoutItems()
            checkoutSections.append(contentsOf: checkoutMerchantData.checkoutSections)
        }
        
        updateButtonsState() //updateButtonsState already update price
        collectionView.reloadData()
    }
    
    private func showThankYou() {
        let thankYouViewController = ThankYouViewController()
        thankYouViewController.fromViewController = self
        thankYouViewController.secondaryFormat()
        thankYouViewController.parentOrder = parentOrder
        
        let navigationController = MmNavigationController(rootViewController: thankYouViewController)
        navigationController.modalPresentationStyle = .overFullScreen
        
        thankYouViewController.linkOrderHandler = { [weak self] in
            if let strongSelf = self {
                if let parentOrder = strongSelf.parentOrder, let order = parentOrder.orders?.first {
                    let sectionData = OrderManager.buildOrderSectionData(withOrder: order)
                    let orderDetailViewController = OrderDetailViewController()
                    orderDetailViewController.originalViewMode = .ToBeShipped
                    orderDetailViewController.orderSectionData = sectionData
                    
                    strongSelf.navigationController?.pushViewController(orderDetailViewController, animated: true)
                } else {
                    ErrorLogManager.sharedManager.recordNonFatalError(withException: .DataIsEmpty)
                }
            } else {
                ErrorLogManager.sharedManager.recordNonFatalError(withException: .NullPointer)
            }
        }
        
        thankYouViewController.continueShoppingHandler = { [weak self] in
            if let strongSelf = self {
                strongSelf.continueShopping()
            } else {
                ErrorLogManager.sharedManager.recordNonFatalError(withException: .NullPointer)
            }
        }
        
        thankYouViewController.dismissHandler = { [weak self] in
            if let strongSelf = self {
                strongSelf.continueShopping()
            } else {
                ErrorLogManager.sharedManager.recordNonFatalError(withException: .NullPointer)
            }
        }
        
        self.present(navigationController, animated: false, completion: nil)
        LoadingOverlay.shared.hideOverlayView()
    }
    
    private func continueShopping() {
        if let viewControllers = self.navigationController?.viewControllers {
            if let _ = viewControllers.first as? DiscoverCollectionViewController {
                self.navigationController?.popToRootViewController(animated: true)
            } else {
                // Switch to Discover tab
                if let storefrontController = UIApplication.shared.delegate?.window??.rootViewController as? StorefrontController {
                    storefrontController.selectedIndex = TabIndex.home.rawValue
                } else {
                    ErrorLogManager.sharedManager.recordNonFatalError(withException: .NullPointer)
                }
                
                self.navigationController?.popToRootViewController(animated: false)
            }
        } else {
            ErrorLogManager.sharedManager.recordNonFatalError(withException: .NullPointer)
        }
    }
    
    func handleCheckoutCompletionActions(){
        enableCheckoutButtons()
    }
    
    private func enableCheckoutButtons(){
        confirmButton.isUserInteractionEnabled = true
        checkoutButton.isUserInteractionEnabled = true
        confirmButton.formatPrimary()
        checkoutButton.formatPrimary()
        LoadingOverlay.shared.hideOverlayView()
    }
    
    // MARK: - Data
    
    class func searchStyle(withStyleCodes styleCodes: [String], merchantIds: [String]) -> Promise<[Style]> {
        return Promise{ fulfill, reject in
            SearchService.searchStyleByStyleCodeAndMechantId(styleCodes.joined(separator: ","), merchantIds: merchantIds.joined(separator: ",")) { (response) in
                if response.result.isSuccess {
                    if let response = Mapper<SearchResponse>().map(JSONObject: response.result.value), let styles = response.pageData {
                        fulfill(styles)
                    } else {
                        ErrorLogManager.sharedManager.recordNonFatalError(withException: .FailToParseAPIResponse)
                    }
                    
                    let error = NSError(domain: "", code: 401, userInfo: nil)
                    reject(error)
                } else {
                    reject(response.result.error!)
                }
            }
        }
    }
    
    func listMerchant(merchantIds: [Int]) -> Promise<Any> {
        return Promise{ fulfill, reject in
            MerchantService.viewListWithMerchantIDs(merchantIds, completion: { [weak self] (merchants, map) in
                if let strongSelf = self {
                    let sortedStyles = strongSelf.styles.sort({ $0.merchantId < $1.merchantId })
                    var merchantDataIndex = 0
                    var merchantId = -1
                    var checkoutMerchantData: CheckoutMerchantData?
                    
                    // Header Section
                    if strongSelf.checkoutMode == .cartCheckout {
                        strongSelf.merchantDataList.append(CheckoutMerchantData(checkoutMode: strongSelf.checkoutMode, sectionPosition: .Header))
                    }
                    
                    var remainingSkus = [Sku]()
                    remainingSkus.append(contentsOf: strongSelf.skus)
                    
                    // Normal Section
                    for style in sortedStyles {
                        // Prepare selected color and style
                        let filteredSkus = remainingSkus.filter({ $0.styleCode == style.styleCode })
                        
                        if let sku = filteredSkus.first {
                            style.selectedSkuId = sku.skuId
                            
                            let selectedColorId = sku.colorId
                            let selectedSkuColor = sku.skuColor
                            let selectedSizeId = sku.sizeId
                            
                            remainingSkus.remove(sku)
                            
                            strongSelf.preselectColorSize(style, selectedSizeId: selectedSizeId, selectedSkuColor: selectedSkuColor, selectedColorId: selectedColorId)
                        }
                        
                        if merchantId != style.merchantId {
                            // Insert
                            merchantId = style.merchantId
                            checkoutMerchantData = CheckoutMerchantData(merchant: merchants.filter({$0.merchantId == merchantId}).first, styles: [], fapiaoText: strongSelf.defaultFapiaoText, checkoutMode: strongSelf.checkoutMode, merchantDataIndex: merchantDataIndex)
                            
                            if let checkoutMerchantData = checkoutMerchantData {
                                strongSelf.merchantDataList.append(checkoutMerchantData)
                            } else {
                                ErrorLogManager.sharedManager.recordNonFatalError(withException: .NullPointer)
                            }
                            
                            merchantDataIndex += 1
                        }
                        
                        checkoutMerchantData?.styles.append(style)
                    }
                    
                    // Footer Section
                    strongSelf.merchantDataList.append(CheckoutMerchantData(checkoutMode: strongSelf.checkoutMode, sectionPosition: .Footer))
                    
                    strongSelf.getDefaultAddress(showLoading: false) // Will Stop loading in getDefaultAddress(...) > checkStock(...)
                    strongSelf.reloadAllData()
                    
                    fulfill("ok")
                } else {
                    ErrorLogManager.sharedManager.recordNonFatalError(withException: .NullPointer)
                }
            })
        }
    }
    
    private func getDefaultAddress(showLoading: Bool = true) {
        if LoginManager.getLoginState() == .validUser {
            if showLoading {
                LoadingOverlay.shared.showOverlay(self)
            }
            
            firstly {
                return self.viewDefaultAddress(showErrorDialog: false, completion: nil)
            }.then { _ -> Void in
                if let selectedAddress = CacheManager.sharedManager.selectedAddress {
                    self.address = selectedAddress
                }
                
                self.reloadAllData()
            }.always {
                // Will stop loading in checkStock(...)
                self.checkStock(showLoading: false)
            }.catch { _ -> Void in
                
            }
        }
    }
    
    private func viewDefaultAddress(showErrorDialog: Bool = true, completion:(() -> Void)? = nil) -> Promise<Any> {
        return Promise{ fulfill, reject in
            AddressService.viewDefault({ [weak self] (response) in
                if let strongSelf = self {
                    let statusCode = response.response?.statusCode ?? 0
                    
                    if response.result.isSuccess {
                        if statusCode == 200 {
                            if let address = Mapper<Address>().map(JSONObject: response.result.value) {
                                CacheManager.sharedManager.selectedAddress = address
                                fulfill("OK")
                            } else {
                                ErrorLogManager.sharedManager.recordNonFatalError(withException: .FailToParseAPIResponse)
                                
                                if showErrorDialog {
                                    strongSelf.showError(String.localize("MSG_ERR_CA_SWIPE2PAY_ADDR"), animated: true)
                                }
                            }
                        } else {
                            let error = NSError(domain: "", code: statusCode, userInfo: nil)
                            reject(error)
                            
                            if showErrorDialog {
                                strongSelf.showError(String.localize("MSG_ERR_CA_SWIPE2PAY_ADDR"), animated: true)
                            }
                        }
                    } else {
                        reject(response.result.error!)
                    }
                } else {
                    ErrorLogManager.sharedManager.recordNonFatalError(withException: .NullPointer)
                }
            })
        }
    }
    
    private func constructOrdersForChecking() -> (skus: [Dictionary<String, Any>], orders: [Dictionary<String, Any>], errorMessage: String) {
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
                            let qty = (checkoutMode == .multipleMerchant) ? 1 : self.qty
                            let referrerUserKey = self.referrerUserKey ?? nil
                            var skuObject: Dictionary<String, Any>
                            
                            if let sku = style.searchSku(selectedSizeId, colorId: selectedColor?.colorId, skuColor: selectedColor?.skuColor) {
                                if !sku.isOutOfStock() {
                                    hasSku = true
                                    
                                    skuObject = ["SkuId": sku.skuId, "Qty": (checkoutMode == .cartCheckout) ? sku.qty : qty]
                                    
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
                    var order: Dictionary<String, Any> = ["MerchantId" : merchantId, "Comments" : checkoutMerchantData.comment ?? ""]
                    
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
    
    private func checkStock(showLoading: Bool = true, proceedActionIfSuccess action: CheckoutAction = .Unknown) {
        if showLoading {
            LoadingOverlay.shared.showOverlay(self)
            //self.showLoading()
        }
        
        if cartInformationIsValid(forAction: action) {
            let (skus, orders, errorMessage) = constructOrdersForChecking()
            
            if skus.count > 0 {
                if action == .addToCart || action == .checkout {
                    self.proceedAction(action, withSkus: skus, orders: orders)
                } else {
                    firstly {
                        return checkoutHandler.checkStockService(skus, orders: orders, coupon: mmCoupon)
                    }.then { parentOrder -> Void in
                        self.parentOrder = parentOrder
                        self.checkStockError = nil
                        
                        self.reloadAllData()
                        
                        self.proceedAction(action, withSkus: skus, orders: orders)
                        LoadingOverlay.shared.hideOverlayView()
                    }.catch { (err) -> Void in
                        self.checkStockError = err as NSError
                        var message = ""
                        if let errorInfo = (err as NSError).userInfo as? [String: String] {
                            if errorInfo["AppCode"] == "MSG_ERR_CA_COUPON_MIN_PURCHASE_MEET" {
                                if let couponReference = errorInfo["Message"], let minSpendAmount = self.findMinimumSpendAmount(withCouponReference: couponReference) {
                                    message = String.localize("MSG_ERR_CA_COUPON_MIN_PURCHASE_MEET").replacingOccurrences(of: "{0}", with: "\(minSpendAmount)")
                                }
                            }
                            else {
                                message = String.localize(errorInfo["AppCode"] ?? "")
                            }
                        }
                        self.showError(message, animated: true)
                        LoadingOverlay.shared.hideOverlayView()
                    }
                }
            } else {
                parentOrder = nil
                
                if errorMessage.length > 0 {
                    self.showError(errorMessage, animated: true)
                }
                LoadingOverlay.shared.hideOverlayView()
            }
        } else {
            LoadingOverlay.shared.hideOverlayView()
        }
        
        collectionView.reloadData()
    }
    
    private func proceedAction(action: CheckoutAction, withSkus skus: [Dictionary<String, Any>], orders: [Dictionary<String, Any>]) {
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
                    self.addMultiProductToCart(skuIds, referrer: self.referrerUserKey, success: {
                        LoadingOverlay.shared.hideOverlayView()
                        self.showAddToCartAnimation()
                        self.dismissView(nil, confirmed: false)
                    }, fail: {
                        Alert.alertWithSingleButton(self, title: "", message: String.localize("LB_CA_ADD2CART_FAIL"), buttonString:String.localize("LB_OK"))
                        LoadingOverlay.shared.hideOverlayView()
                        self.dismissView(nil, confirmed: false)
                    })
                }
            } else {
                if let style = self.merchantDataList.first?.styles.first {
                    let selectedColor = style.getValidColorAtIndex(style.colorIndexSelected)
                    let selectedSizeId = style.getValidSizeIdAtIndex(style.sizeIndexSelected)
                    
                    if (style.isEmptyColorList() || selectedColor != nil) && (style.isEmptySizeList() || selectedSizeId != -1) {
                        if let sku = style.searchSku(selectedSizeId, colorId: selectedColor?.colorId, skuColor: selectedColor?.skuColor) {
                            self.addCartItem(sku.skuId, qty: self.qty, referrer: self.referrerUserKey, success: {
                                LoadingOverlay.shared.hideOverlayView()
                                self.showAddToCartAnimation()
                                self.dismissView(nil, confirmed: false)
                            }, fail: {
                                Alert.alertWithSingleButton(self, title: "", message: String.localize("LB_CA_ADD2CART_FAIL"), buttonString:String.localize("LB_OK"))
                                LoadingOverlay.shared.hideOverlayView()
                                self.dismissView(nil, confirmed: false)
                            })
                        } else {
                            ErrorLogManager.sharedManager.recordNonFatalError(withException: .NullPointer, parameters: ["message" : "Sku not found."])
                        }
                    } else {
                        // Missing SKU handling
                        self.showErrorAlert(String.localize("Fail to add shopping cart: Missing Sku"))
                        
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
                        self.showError(String.localize("LB_OUT_OF_STOCK"), animated: true)
                    } else {
                        let cartMerchant = CacheManager.sharedManager.cart?.merchantList?.filter({$0.merchantId == sku.merchantId}).first
                        let existingSameSkuCartItems = cartMerchant?.itemList?.filter{($0.cartItemId != cartItem.cartItemId) && ($0.skuId == sku.skuId)}
                        if let cartItems = existingSameSkuCartItems, cartItems.count > 0{
                            LoadingOverlay.shared.hideOverlayView()

                            self.showError(String.localize("LB_CA_SKU_ALREADY_IN_CART"), animated: true)
                        }
                        else{
                            self.updateCartItem(cartItem.cartItemId, skuId: sku.skuId, qty: self.qty, success: {
                                self.dismissView(nil, confirmed: true)
                                }, fail: {
                                    self.dismissView(nil, confirmed: false)
                            })
                        }
                    }
                } else {
                    // Missing SKU handling
                    self.showErrorAlert(String.localize("Fail to add shopping cart: Missing Sku"))
                    
                    ErrorLogManager.sharedManager.recordNonFatalError(withException: .NullPointer, parameters: ["message" : "Missing Sku."])
                }
            } else {
                self.dismissView(nil, confirmed: false)
            }
        default:
            LoadingOverlay.shared.hideOverlayView()
        }
    }
    
    private func checkOrder(proceedActionIfSuccess action: CheckoutAction = .unknown, completion: ((_ success: Bool, _ error: NSError?) -> ())?) {
        if self.cartInformationIsValid(forAction: action) {
            if !processCreateOrder(forAction: action, completion: completion){
                completion?(success: false, error: nil)
            }
        } else if address == nil || address?.userAddressKey.length == 0 {
            let addressAdditionViewController = AddressAdditionViewController()
            
            addressAdditionViewController.signupMode = .checkoutSwipeToPay
            addressAdditionViewController.disableBackButton = false
            addressAdditionViewController.continueCheckoutProcess = true
            
            addressAdditionViewController.didAddAddress = { [weak self] (address) in
                if let strongSelf = self {
                    strongSelf.address = address
                    strongSelf.collectionView.reloadData()
                    
                    if strongSelf.cartInformationIsValid(forAction: action) {
                        strongSelf.processCreateOrder(forAction: action, completion: completion)
                    }
                    else{
                        completion?(success: false, error: nil)
                    }
                } else {
                    completion?(success: false, error: nil)
                    ErrorLogManager.sharedManager.recordNonFatalError(withException: .NullPointer)
                }
            }
            
            self.navigationController?.isNavigationBarHidden = false
            self.navigationController?.pushViewController(addressAdditionViewController, animated: true)
        }
    }
    
    private func processCreateOrder(forAction action: CheckoutAction, completion: ((_ success: Bool, _ error: NSError?) -> ())?) -> Bool{
        let (skus, orders, errorMessage) = constructOrdersForChecking()
        
        if skus.count > 0 {
            LoadingOverlay.shared.showOverlay(self)
            if action == .checkout {
                self.checkoutHandler.processCreateOrder(skus, orders: orders, mmCoupon: mmCoupon, addressKey: self.address?.userAddressKey ?? "", isCart: checkoutMode == .cartCheckout, failBlock: { [weak self] (error, cartViewController) in
                    
                    if let strongSelf = self {
                        var message = ""
                        if let errorInfo = (error as NSError).userInfo as? [String: String] {
                            if errorInfo["AppCode"] == "MSG_ERR_CA_COUPON_MIN_PURCHASE_MEET" {
                                if let couponReference = errorInfo["Message"], let minSpendAmount = strongSelf.findMinimumSpendAmount(withCouponReference: couponReference) {
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
                    
                    completion?(success: false, error: error as NSError)
                })
                
                return true
            } else {
                LoadingOverlay.shared.hideOverlayView()
                return false
            }
        } else {
            Log.debug("skus.count = 0")
            
            completion?(success: false, error: nil)
            
            if errorMessage.length > 0 {
                self.showError(errorMessage, animated: true)
            }
            
            return false
        }
    }
    
    func findMinimumSpendAmount(withCouponReference couponReference: String) -> Double? {
        if let mmCoupon = self.mmCoupon, mmCoupon.couponReference == couponReference {
            return mmCoupon.minimumSpendAmount
        }
        
        for checkoutMerchantData in merchantDataList {
            if let merchantCoupon = checkoutMerchantData.merchantCoupon, merchantCoupon.couponReference == couponReference {
                return merchantCoupon.minimumSpendAmount
            }
        }
        
        return nil
    }
    
    // MARK: - Collection View data source methods
    
    func numberOfSections(in collectionView: UICollectionView) -> Int {
        return checkoutSections.count
    }
    
    override func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return checkoutSections[section].checkoutItems.count
    }
    
    override func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        let (checkoutSection, checkoutItem, merchantIndex, merchantSectionData) = getCellInformation(atIndexPath: indexPath)

        switch checkoutItem.itemType {
        case .style:
            let cell = collectionView.dequeueReusableCell(withReuseIdentifier: CheckoutInfoCell.CellIdentifier, for: indexPath) as! CheckoutInfoCell
            
            checkoutInfoCellDict["\(self.getCheckoutInfoTag(merchantIndex, styleIndex: checkoutSection.styleIndex))"] = cell
            
            addLeftSelectionForCheckoutInfoCell(cell, merchantIndex: merchantIndex, styleIndex: checkoutSection.styleIndex)
            
            if let style: Style = merchantSectionData.styles[checkoutSection.styleIndex] {
                cell.setData(withStyle: style, hasCheckbox: true)
                //cell.hideBorder(style.isEmptySizeList() && style.isEmptyColorList()) // TODO:
                
                cell.itemSelectHandler = { [weak self] touchedStyle in
                    guard let strongSelf = self else { return }
                    strongSelf.updateButtonsState()
                    strongSelf.checkStock()
                }

                let sku = style.searchSku(style.selectedSizeId, colorId: style.selectedColorId, skuColor:  style.selectedSkuColor)
                cell.initAnalytics(withViewKey: self.analyticsViewRecord.viewKey, impressionKey: AnalyticsManager.sharedManager.recordImpression(brandCode: "\(style.brandId)", impressionRef: style.styleCode, impressionType: "Product", impressionVariantRef: sku?.skuCode ?? "", impressionDisplayName: style.skuName, merchantCode: style.merchantCode, positionComponent: "ProductListing", positionIndex: indexPath.row + 1, positionLocation: getPositionLocation(), viewKey: self.analyticsViewRecord.viewKey))
            } else {
                ErrorLogManager.sharedManager.recordNonFatalError(withException: .IndexOutOfBounds)
            }
            
            // TODO:
            checkoutInfoCell = cell
            
            return cell
        case .color:
            let cell = collectionView.dequeueReusableCell(withReuseIdentifier: ColorCollectionCell.CellIdentifier, for: indexPath) as! ColorCollectionCell
            
            cell.imageView.image = nil
            cell.topPadding = ColorCellTopPadding
            
            if let style: Style = merchantSectionData.styles[checkoutSection.styleIndex] {
                let indexPathColor = style.validColorList[indexPath.item]
                let filteredColorImageList = style.colorImageList.filter({ $0.colorKey == indexPathColor.colorKey })
                
                var url: NSURL?
                
                if filteredColorImageList.isEmpty {
                    url = ImageURLFactory.URLSize256(indexPathColor.colorImage, category: .color)
                } else {
                    url = ImageURLFactory.URLSize256(filteredColorImageList.first?.imageKey ?? "", category: .product)
                }
                
                if let url = url {
                    cell.imageView.mm_setImageWithURL(url, placeholderImage: PlaceholderImage)
                } else {
                    ErrorLogManager.sharedManager.recordNonFatalError(withException: .NullPointer)
                }
                
                // Check for product out of stock
                var filteredSkuList = style.skuList
                filteredSkuList = filteredSkuList.filter({ ($0.skuColor == indexPathColor.skuColor) && ($0.colorId == indexPathColor.colorId)})
                filteredSkuList = filteredSkuList.filter({ !$0.isOutOfStock() && $0.isValid()})
                
                let itemIsValid = !filteredSkuList.isEmpty
                cell.itemSelected(indexPath.item == style.colorIndexSelected)
                cell.itemDisabled(!itemIsValid)
                
                style.validColorList[indexPath.item].isValid = itemIsValid
            } else {
                ErrorLogManager.sharedManager.recordNonFatalError(withException: .IndexOutOfBounds)
            }
            
            cell.accessibilityIdentifier = "checkout_color_cell"
            
            return cell
        case .size:
            let cell = collectionView.dequeueReusableCell(withReuseIdentifier: SizeCollectionCell.CellIdentifier, for: indexPath) as! SizeCollectionCell
            
            if let style: Style = merchantSectionData.styles[checkoutSection.styleIndex] {
                cell.name = style.validSizeList[indexPath.item].sizeName
                
                let selectedColor = style.getValidColorAtIndex(style.colorIndexSelected)
                
                var filteredSkuList = style.skuList
                
                if selectedColor != nil {
                    filteredSkuList = filteredSkuList.filter({ $0.colorId == selectedColor?.colorId && $0.skuColor == selectedColor?.skuColor })
                }
                
                filteredSkuList = filteredSkuList.filter({ $0.sizeId == style.validSizeList[indexPath.item].sizeId })
                filteredSkuList = filteredSkuList.filter({ !$0.isOutOfStock() && $0.isValid()})
                
                let itemIsValid = !filteredSkuList.isEmpty
                
                cell.itemSelected(indexPath.item == style.sizeIndexSelected)
                cell.itemDisabled(!itemIsValid)
                
                style.validSizeList[indexPath.item].isValid = itemIsValid
            } else {
                ErrorLogManager.sharedManager.recordNonFatalError(withException: .IndexOutOfBounds)
            }
            
            cell.accessibilityIdentifier = "checkout_size_cell"
            
            return cell
        case .quantity:
            let cell = collectionView.dequeueReusableCell(withReuseIdentifier: QuantityCell.CellIdentifier, for: indexPath) as! QuantityCell
            
            cell.minusStepButton.addTarget(self, action: #selector(self.stepperValueChanged), for: .touchUpInside)
            cell.minusStepButton.accessibilityIdentifier = "checkout_quantity_minus_button"
            
            cell.addStepButton.addTarget(self, action: #selector(self.stepperValueChanged), for: .touchUpInside)
            cell.addStepButton.accessibilityIdentifier = "checkout_quantity_add_button"
            
            cell.qtyTextField.text = String(qty)
            
            cell.setSeparatorStyle(.checkout)
            cell.qtyTextField.keyboardType = .DecimalPad
            cell.qtyTextField.accessibilityIdentifier = "checkout_quantity_textfield"
            
            if cell.qtyTextField.delegate == nil {
                cell.qtyTextField.delegate = self
            }
            
            quantityCell = cell
            
            return cell
        case .address:
            if LoginManager.getLoginState() == .validUser {
                let cell = collectionView.dequeueReusableCell(withReuseIdentifier: CheckoutCell.CellIdentifier, for: indexPath) as! CheckoutCell
                cell.leftLabel.text = String.localize("LB_CA_EDITITEM_SHIPADDR")
                cell.setStyle(withArrow: true, topSeparator: false, bottomSeparator: true, isFullSeparator: checkoutMode == .cartCheckout)
                cell.setDefaultFont()
                
                var viewController: MmViewController
                
                if let address = address, address.userAddressKey != "" {
                    let addressData = AddressData(address: address)
                    cell.rightLabel.text = addressData.getFullAddress()
                    cell.rightLabel.textColor = UIColor.secondary2()
                    
                    viewController = AddressSelectionViewController()
                    
                    if let addressSelectionViewController = viewController as? AddressSelectionViewController {
                        addressSelectionViewController.viewMode = .checkoutSwipeToPay
                        addressSelectionViewController.selectedAddress = self.address
                        addressSelectionViewController.didSelectAddress = { [weak self] (address) -> Void in
                            if let strongSelf = self{
                                strongSelf.address = address
                                strongSelf.collectionView.reloadItemsAtIndexPaths([indexPath])
                            } else {
                                ErrorLogManager.sharedManager.recordNonFatalError(withException: .NullPointer)
                            }
                        }
                    } else {
                        ErrorLogManager.sharedManager.recordNonFatalError(withException: .NullPointer)
                    }
                } else {
                    cell.rightLabel.text = String.localize("LB_CA_NEW_SHIPPING_ADDR")
                    cell.rightLabel.textColor = UIColor.secondary1()
                    
                    viewController = AddressAdditionViewController()
                    
                    if let addressAdditionViewController = viewController as? AddressAdditionViewController {
                        addressAdditionViewController.signupMode = .checkoutSwipeToPay
                        addressAdditionViewController.disableBackButton = false
                        
                        addressAdditionViewController.didAddAddress = { [weak self] (address) -> Void in
                            if let strongSelf = self {
                                strongSelf.address = address
                                strongSelf.collectionView.reloadItemsAtIndexPaths([indexPath])
                            } else {
                                ErrorLogManager.sharedManager.recordNonFatalError(withException: .NullPointer)
                            }
                        }
                    }
                }
                
                cell.rightViewTapHandler = { [weak self] in
                    if let strongSelf = self {
                        strongSelf.navigationController?.isNavigationBarHidden = false
                        strongSelf.navigationController?.pushViewController(viewController, animated: true)
                    }
                }

                cell.rightLabel.lineBreakMode = .byTruncatingTail
                
                return cell
            }
        case .paymentMethod:
            let cell = collectionView.dequeueReusableCell(withReuseIdentifier: CheckoutCell.CellIdentifier, for: indexPath) as! CheckoutCell
            cell.leftLabel.text = String.localize("LB_CA_EDITITEM_PAYMENT_METHOD")
            cell.rightLabel.text = String.localize("LB_CA_PAY_VIA_ALIPAY")
            cell.setStyle(withArrow: false, topSeparator: false, bottomSeparator: true, isFullSeparator: checkoutMode == .cartCheckout)
            cell.rightViewTapHandler = nil
            cell.setDefaultFont() // Must set
            
            return cell
        case .shippingFee:
            let cell = collectionView.dequeueReusableCell(withReuseIdentifier: CheckoutCell.CellIdentifier, for: indexPath) as! CheckoutCell
            cell.leftLabel.text = String.localize("LB_SHIPPING_FEE")
            
            if let merchant = merchantSectionData.merchant {
                if let order = parentOrder?.orders?.filter({ $0.merchantId == merchant.merchantId }).first {
                    if order.shippingTotal > 0 {
                        cell.rightLabel.text = order.shippingTotal.formatPrice()
                        cell.setPriceFont()
                    } else {
                        cell.rightLabel.text = String.localize("LB_CA_FREE_SHIPPING")
                        cell.setDefaultFont()
                    }
                } else {
                    var merchantTotal: Double = 0
                    
                    switch checkoutMode {
                    case .cartCheckout:
                        merchantTotal = merchantSectionData.getMerchantTotal(includeShipmentFee: false, includeCoupon: false, selectedSkus: skus)
                    default:
                        merchantTotal = merchantSectionData.getMerchantTotal(includeShipmentFee: false, includeCoupon: false, qty: qty)
                    }
                    
                    if merchantTotal == 0{
                        cell.rightLabel.text = ""
                    } else if !merchant.isFreeShippingEnabled() || (merchantTotal < Double(merchant.freeShippingThreshold) && merchant.shippingFee > 0) {
                        cell.rightLabel.text = merchant.shippingFee.formatPrice()
                        cell.setPriceFont()
                    } else {
                        cell.rightLabel.text = String.localize("LB_CA_FREE_SHIPPING")
                        cell.setDefaultFont()
                    }
                }
            } else {
                cell.rightLabel.text = ""
            }
            
            cell.setStyle(withArrow: false, topSeparator: false, bottomSeparator: true, isFullSeparator: checkoutMode == .cartCheckout)
            cell.rightViewTapHandler = nil
            
            return cell
        case .merchantCoupon:
            let cell = collectionView.dequeueReusableCell(withReuseIdentifier: CheckoutCouponCell.CellIdentifier, for: indexPath) as! CheckoutCouponCell
            cell.leftLabel.text = String.localize("LB_CA_CHECKOUT_MERC_COUPON")
            cell.setStyle(withSeparator: (indexPath.item != checkoutSection.checkoutItems.count - 1), isFullSeparator: checkoutMode == .cartCheckout)
            
            if let merchantCoupon = merchantSectionData.merchantCoupon {
                cell.setData(merchantCoupon)
            } else {
                cell.setData(nil)
            }
            
            cell.redDotView.isHidden = true
            cell.layoutSubviews()
            
            return cell
        case .mmCoupon:
            let cell = collectionView.dequeueReusableCell(withReuseIdentifier: CheckoutCouponCell.CellIdentifier, for: indexPath) as! CheckoutCouponCell
            cell.leftLabel.text = String.localize("LB_CA_CHECKOUT_MM_COUPON")
            cell.setStyle(withSeparator: (checkoutMode != .multipleMerchant && checkoutMode != .cartCheckout), isFullSeparator: checkoutMode == .cartCheckout)
            
            cell.setData(mmCoupon)
            
            cell.redDotView.isHidden = !hasMMCoupon
            mmCouponIndexPath = indexPath
            cell.layoutSubviews()

            return cell
        case .fapiao:
            let cell = collectionView.dequeueReusableCell(withReuseIdentifier: CheckoutFapiaoCell.CellIdentifier, for: indexPath) as! CheckoutFapiaoCell
            cell.setStyle(withSeparator: checkoutMode == .cartCheckout, isFullSeparator: checkoutMode == .cartCheckout)
            
            if let fapiaoText = merchantSectionData.fapiaoText {
                cell.fapiaoTextField.text = fapiaoText
            }
            
            cell.invoiceButton.tag = merchantIndex
            cell.enableFapiaoTextfield(merchantSectionData.enabledFapiao)
            
            cell.textFieldEndEditing = { [weak self] cell in
                if let strongSelf = self {
                    if let fapiaoText = cell.fapiaoTextField.text {
                        if fapiaoText.isEmptyOrNil() {
                            cell.fapiaoTextField.text = ""
                            strongSelf.merchantDataList[merchantIndex].fapiaoText = ""
                        } else {
                            strongSelf.merchantDataList[merchantIndex].fapiaoText = fapiaoText
                        }
                    } else {
                        ErrorLogManager.sharedManager.recordNonFatalError(withException: .NullPointer)
                    }
                } else {
                    ErrorLogManager.sharedManager.recordNonFatalError(withException: .NullPointer)
                }
            }
            
            cell.textFieldDidChange = { [weak self] cell in
                if let strongSelf = self {
                    if let fapiaoText = cell.fapiaoTextField.text {
                        strongSelf.merchantDataList[merchantIndex].fapiaoText = fapiaoText
                    } else {
                        ErrorLogManager.sharedManager.recordNonFatalError(withException: .NullPointer)
                    }
                } else {
                    ErrorLogManager.sharedManager.recordNonFatalError(withException: .NullPointer)
                }
            }
            
            cell.delegate = self
            
            return cell
        case .fullAddress:
            let cell = collectionView.dequeueReusableCell(withReuseIdentifier: CheckoutFullAddressCell.CellIdentifier, for: indexPath) as! CheckoutFullAddressCell
            
            if let address = address, !address.userAddressKey.isEmpty{
                let addressData = AddressData(address: address)
                cell.setContent(withName: addressData.recipientName, address: addressData.getFullAddress(), phoneNumber: addressData.recipientPhoneNumber)
            } else {
                cell.setContent(withName: "", address: String.localize("LB_CA_NEW_SHIPPING_ADDR"), phoneNumber: "")
            }
            
            return cell
        case .fullPaymentMethod:
            return collectionView.dequeueReusableCell(withReuseIdentifier: CheckoutFullPaymentMethodCell.CellIdentifier, for: indexPath) as! CheckoutFullPaymentMethodCell
        case .fullStyle:
            let cell = collectionView.dequeueReusableCell(withReuseIdentifier: CheckoutProductCell.CellIdentifier, for: indexPath) as! CheckoutProductCell
            
            if let style: Style = merchantSectionData.styles[checkoutSection.styleIndex] {
                
                let sku = style.searchSku(style.selectedSizeId, colorId: style.selectedColorId, skuColor: style.selectedSkuColor)
                
                if let sku = sku {
                    let imageKey = ProductManager.getProductImageKey(style, colorKey: sku.colorKey)
                    cell.setProductImage(withImageKey: imageKey)
                } else {
                    ErrorLogManager.sharedManager.recordNonFatalError(withException: .NullPointer)
                }
                
                cell.sku = sku
                
                let cachedMerchant = CacheManager.sharedManager.cachedMerchantForId(style.merchantId)
                cell.initAnalytics(withViewKey: self.analyticsViewRecord.viewKey, impressionKey: AnalyticsManager.sharedManager.recordImpression(brandCode: "", impressionRef: style.styleCode, impressionType: "Product", impressionVariantRef: sku?.skuCode ?? "", impressionDisplayName: style.skuName, merchantCode: cachedMerchant?.merchantCode, positionComponent: "OrderConfirmation", positionIndex: indexPath.row + 1, positionLocation: getPositionLocation(), viewKey: self.analyticsViewRecord.viewKey))
            } else {
                ErrorLogManager.sharedManager.recordNonFatalError(withException: .IndexOutOfBounds)
            }
            
            return cell
        case .merchantTotal:
            let cell = collectionView.dequeueReusableCell(withReuseIdentifier: CheckoutCell.CellIdentifier, for: indexPath) as! CheckoutCell
            cell.leftLabel.text = String.localize("LB_CA_MERCHANT_TOTAL")
            
            var formatPriceText: String? = nil
            
            if let merchant = merchantSectionData.merchant {
                if let order = parentOrder?.orders?.filter({ $0.merchantId == merchant.merchantId }).first {
                    formatPriceText = order.grandTotal.formatPrice()
                } else {
                    let merchantTotal = merchantSectionData.getMerchantTotal(includeShipmentFee: true, includeCoupon: true, selectedSkus: skus)
                    formatPriceText = merchantTotal.formatPrice()
                }
            }
            
            cell.rightLabel.text = formatPriceText ?? ""
            
            cell.setPriceFont()
            cell.setStyle(withArrow: false, topSeparator: false, bottomSeparator: true, isFullSeparator: checkoutMode == .cartCheckout)
            cell.rightViewTapHandler = nil
            
            return cell
        case .comments:
            let cell = collectionView.dequeueReusableCell(withReuseIdentifier: CheckoutCommentCell.CellIdentifier, for: indexPath) as! CheckoutCommentCell
            
            if let comment = merchantSectionData.comment, !comment.isEmptyOrNil() {
                cell.textView.text = comment
                cell.textView.textColor = UIColor.black
            } else {
                cell.textView.text = CheckoutCommentCell.CommentPlaceholder
                cell.textView.textColor = UIColor.secondary3()
            }
            
            cell.textViewBeginEditing = { cell in
                if let comment = merchantSectionData.comment, !comment.isEmptyOrNil() {
                    cell.textView.text = comment
                } else {
                    cell.textView.text = ""
                }
                
                cell.textView.textColor = UIColor.black
            }
            
            cell.textViewDidChange = { [weak self] cell in
                if let strongSelf = self {
                    if let comment = cell.textView.text {
                        if comment.isEmptyOrNil() || comment.trimmingCharacters(in: CharacterSet.whitespacesAndNewlines) .length <= 0 {
                            cell.textView.text = ""
                            strongSelf.merchantDataList[merchantIndex].comment = ""
                        } else {
                            strongSelf.merchantDataList[merchantIndex].comment = comment
                        }
                    } else {
                        ErrorLogManager.sharedManager.recordNonFatalError(withException: .NullPointer)
                    }
                } else {
                    ErrorLogManager.sharedManager.recordNonFatalError(withException: .NullPointer)
                }
            }
            
            cell.textViewEndEditing = { [weak self] cell in
                if let strongSelf = self {
                    if let comment = cell.textView.text {
                        if comment.isEmptyOrNil() || comment.trimmingCharacters(in: CharacterSet.whitespacesAndNewlines) .length <= 0 {
                            cell.textView.text = CheckoutCommentCell.CommentPlaceholder
                            cell.textView.textColor = UIColor.secondary3()
                            
                            strongSelf.merchantDataList[merchantIndex].comment = ""
                        } else {
                            strongSelf.merchantDataList[merchantIndex].comment = comment
                        }
                    } else {
                        ErrorLogManager.sharedManager.recordNonFatalError(withException: .NullPointer)
                    }
                } else {
                    ErrorLogManager.sharedManager.recordNonFatalError(withException: .NullPointer)
                }
            }
            
            return cell
        default:
            break
        }
        
        ErrorLogManager.sharedManager.recordNonFatalError(withException: .TypeMismatch)
        
        return UICollectionViewCell()
    }
    
    func collectionView(_ collectionView: UICollectionView, viewForSupplementaryElementOfKind kind: String, at indexPath: IndexPath) -> UICollectionReusableView {
        let (checkoutSection, checkoutItem, merchantIndex, merchantSectionData) = getCellInformation(atIndexPath: indexPath)
        
        if kind == UICollectionElementKindSectionHeader {
            switch checkoutItem.itemType {
            case .style, .fullStyle:
                let couponInputHeaderView = collectionView.dequeueReusableSupplementaryView(ofKind: kind, withReuseIdentifier: CouponInputHeaderView.ViewIdentifier, for: indexPath) as! CouponInputHeaderView
                couponInputHeaderView.imageStyle = (checkoutMode == .cartCheckout) ? .Long : .Square
                couponInputHeaderView.setMerchantModel(merchantSectionData.merchant)
               
                if checkoutMode == .cartCheckout {
                    couponInputHeaderView.couponButtonView.isHidden = true
                }
                else {
                    couponInputHeaderView.couponButtonView.isHidden = false

                    couponInputHeaderView.viewCouponHandler = { [weak self] in
                        let viewController = MerchantCouponsListViewController()
                        if let strongSelf = self {
                            // record action
                            strongSelf.view.recordAction(.Tap, sourceRef: "SwipeToBuy-MerchantCouponClaimList", sourceType: .Button, targetRef: "MerchantCouponClaimList", targetType: .View)

                            viewController.data = merchantSectionData.merchant
                            
                            strongSelf.navigationController?.isNavigationBarHidden = false
                            strongSelf.navigationController?.pushViewController(viewController, animated: true)
                        }
                    }
                }

                return couponInputHeaderView
            case .Size:
                let sizeHeaderView = collectionView.dequeueReusableSupplementaryView(ofKind: kind, withReuseIdentifier: SizeHeaderView.ViewIdentifier, for: indexPath) as! SizeHeaderView
                
                sizeHeaderView.topPadding = SizeHeaderViewTopPadding
                
                if let style: Style = merchantSectionData.styles[checkoutSection.styleIndex] {
                    sizeHeaderView.hideSizeInformation(!style.haveSizeGrid())
                    sizeHeaderView.leftMargin = (checkoutMode == .multipleMerchant) ? CheckoutViewController.MultipleMerchantSizeEdgeInsets.left : CheckoutViewController.NormalSizeEdgeInsets.left
                    sizeHeaderView.rightMargin = CheckoutViewController.NormalSizeEdgeInsets.left
                    sizeHeaderView.sizeGroupName = ""
                    
                    if style.sizeIndexSelected >= 0 && style.sizeIndexSelected < style.validSizeList.count {
                        let size = style.validSizeList[style.sizeIndexSelected]
                        sizeHeaderView.sizeGroupName = size.sizeGroupName
                    }
                    
                    sizeHeaderView.sizeHeaderTappedHandler = { [weak self] in
                        guard let strongSelf = self else { return }
                        let sizeCommentViewController = SizeCommentViewController()
                        sizeCommentViewController.sizeComment = style.skuSizeComment
                        sizeCommentViewController.sizeGridImage = style.highestCategoryPriority()?.sizeGridImage
                        
                        let navigationController = UINavigationController()
                        navigationController.viewControllers = [sizeCommentViewController]
                        
                        strongSelf.present(navigationController, animated: true, completion: nil)
                    }
                } else {
                    ErrorLogManager.sharedManager.recordNonFatalError(withException: .IndexOutOfBounds)
                }
                
                return sizeHeaderView
            default:
                break
            }
        } else if kind == UICollectionElementKindSectionFooter {
            switch checkoutSection.sectionType {
            case .Color, .Size:
                let footerView = collectionView.dequeueReusableSupplementaryView(ofKind: kind, withReuseIdentifier: CheckoutFooterView.ViewIdentifier, for: indexPath) as! CheckoutFooterView
                
                footerView.setSeparatorStyle(checkoutMode == .multipleMerchant ? .MultipleItem : .SingleItem)
                
                switch checkoutSection.sectionType {
                case .Color:
                    checkoutColorFooterViewFrameDict["\(self.getCheckoutInfoTag(merchantIndex, styleIndex: checkoutSection.styleIndex))"] = footerView.frame
                case .Size:
                    checkoutSizeFooterViewFrameDict["\(self.getCheckoutInfoTag(merchantIndex, styleIndex: checkoutSection.styleIndex))"] = footerView.frame
                default:
                    break
                }
                
                addLeftSelectionForCheckoutInfoCell(checkoutInfoCellDict["\(self.getCheckoutInfoTag(merchantIndex, styleIndex: checkoutSection.styleIndex))"], merchantIndex: merchantIndex, styleIndex: checkoutSection.styleIndex)
                
                return footerView
            case .OtherInformation:
                if indexPath.section == 0 {
                    let footerView = collectionView.dequeueReusableSupplementaryView(ofKind: kind, withReuseIdentifier: SeparatorHeaderView.ViewIdentifier, for: indexPath) as! SeparatorHeaderView
                    
                    footerView.separatorView.isHidden = true
                    footerView.backgroundColor = UIColor.backgroundGray()
                    
                    return footerView
                }
            case .OtherMerchantInformation:
                let footerView = collectionView.dequeueReusableSupplementaryView(ofKind: kind, withReuseIdentifier: SeparatorHeaderView.ViewIdentifier, for: indexPath) as! SeparatorHeaderView
                
                footerView.separatorView.isHidden = true
                footerView.backgroundColor = UIColor.backgroundGray()
                
                return footerView
            default:
                break
            }
        }
        
        return UICollectionReusableView()
    }
    
    // MARK: - Collection View delegate methods (Flow Layout)
    
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, sizeForItemAt indexPath: IndexPath) -> CGSize {
        let (checkoutSection, checkoutItem, _, merchantSectionData) = getCellInformation(atIndexPath: indexPath)
        
        switch checkoutItem.itemType {
        case .style:
            return CGSize(width: view.width, height: StyleCellHeight)
        case .color:
            return CGSize(width: ColorCellDimension, height: ColorCellDimension + ColorCellTopPadding)
        case .size:
            if let style: Style = merchantSectionData.styles[checkoutSection.styleIndex] {
                if indexPath.item < style.validSizeList.count {
                    let size = style.validSizeList[indexPath.item]
                    return CGSize(width: SizeCollectionCell.getWidth(size.sizeName), height: SizeCollectionCell.DefaultHeight)
                }
            } else {
                ErrorLogManager.sharedManager.recordNonFatalError(withException: .IndexOutOfBounds)
            }
        case .fullAddress:
            var text = ""
            
            if let address = address, !address.userAddressKey.isEmpty{
                let addressData = AddressData(address: address)
                text = addressData.getFullAddress()
                
                return CGSize(width: view.width, height: CheckoutFullAddressCell.getCellHeight(withAddress: text, cellWidth: view.width))
            } else {
                text = String.localize("LB_CA_NEW_SHIPPING_ADDR")
                
                return CGSize(width: view.width, height: 100)
            }
        case .fullStyle:
            return CGSize(width: view.width, height: CheckoutProductCell.DefaultHeight)
        case .comments:
            return CGSize(width: view.width, height: 110)
        case .unknown:
            break
        default:
            return CGSize(width: view.width, height: 50)
        }
        
        return CGSize.zero
    }
    
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, insetForSectionAt section: Int) -> UIEdgeInsets {
        let checkoutSection = checkoutSections[section]
        
        switch checkoutSection.sectionType {
        case .Color, .Size:
            if checkoutMode == .multipleMerchant {
                return CheckoutViewController.MultipleMerchantSizeEdgeInsets
            } else {
                return CheckoutViewController.NormalSizeEdgeInsets
            }
        default:
            break
        }
        
        return UIEdgeInsets.zero
    }
    
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, minimumLineSpacingForSectionAt section: Int) -> CGFloat {
        return 0
    }
    
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, minimumInteritemSpacingForSectionAt section: Int) -> CGFloat {
        let checkoutSection = checkoutSections[section]
        
        switch checkoutSection.sectionType {
        case .Color:
            return 10
        case .Size:
            return CheckoutViewController.SizeMinimumInteritemSpacing
        default:
            break
        }
        
        return 0
    }
    
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, referenceSizeForHeaderInSection section: Int) -> CGSize {
        let checkoutSection = checkoutSections[section]
        
        switch checkoutSection.sectionType {
        case .style, .fullStyle:
            if checkoutSection.styleIndex == 0 {
                return CGSize(width: view.width, height: 50)
            }
        case .Size:
            return CGSize(width: view.width, height: SizeHeaderViewHeight + SizeHeaderViewTopPadding)
        default:
            break
        }
        
        return CGSize.zero
    }
    
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, referenceSizeForFooterInSection section: Int) -> CGSize {
        let checkoutSection = checkoutSections[section]
        
        switch checkoutSection.sectionType {
        case .Color, .Size:
            return CGSize(width: view.width, height: 12)
        case .OtherInformation:
            if section == 0 {
                return CGSize(width: view.width, height: 10)
            }
        case .OtherMerchantInformation:
            return CGSize(width: view.width, height: 10)
        default:
            break
        }
        
        return CGSize.zero
    }
    
    // MARK: - Collection View delegate methods
    
    func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        let (checkoutSection, checkoutItem, merchantIndex, merchantSectionData) = getCellInformation(atIndexPath: indexPath)
        
        switch checkoutItem.itemType {
        case .style:
            if let style: Style = merchantSectionData.styles[checkoutSection.styleIndex] {
                showProductDetailView(withStyle: style)
                
                if let cell = collectionView.cellForItem(at: indexPath) as? CheckoutInfoCell {
                    cell.recordAction(.Tap, sourceRef: style.styleCode, sourceType: .Product, targetRef: "PDP", targetType: .View)
                } else {
                    ErrorLogManager.sharedManager.recordNonFatalError(withException: .NullPointerOrTypeMismatch)
                }
            } else {
                ErrorLogManager.sharedManager.recordNonFatalError(withException: .IndexOutOfBounds)
            }
        case .color:
            if let style: Style = merchantSectionData.styles[checkoutSection.styleIndex] {
                if style.validColorList[indexPath.item].isValid {
                    if style.colorIndexSelected == indexPath.item {
                        style.colorIndexSelected = -1
                        style.selectedSkuColor = nil
                        style.selectedColorId = -1
                        //Fix always display highligh for size out of stock when deselect color
                        if style.sizeIndexSelected != -1 {
                            let sizeId = style.getValidSizeIdAtIndex(style.sizeIndexSelected)
                            if sizeId != -1 {
                                let sku = style.searchSku(sizeId, colorKey: "")
                                if sku == nil {
                                    style.sizeIndexSelected = -1
                                    style.selectedSizeId = -1
                                }
                            }
                        }
                    } else {
                        style.colorIndexSelected = indexPath.item
                        style.selectedSkuColor = style.validColorList[indexPath.item].skuColor
                        style.selectedColorId = style.validColorList[indexPath.item].colorId
                        
                        if style.sizeIndexSelected != -1{
                            let currentSelectedSizeId = style.getValidSizeIdAtIndex(style.sizeIndexSelected)
                            if currentSelectedSizeId != -1{
                                if style.searchValidSku(currentSelectedSizeId, colorId: style.selectedColorId, skuColor: style.selectedSkuColor) == nil{
                                    style.sizeIndexSelected = -1
                                    style.selectedSizeId = -1
                                }
                            }
                        }
                    }
                    
                    checkStock()
                    
                    // To reload the price base on color selected
                    if let checkoutInfoCell = checkoutInfoCell, checkoutMode != .multipleMerchant {
                        if let checkoutMerchantData = merchantDataList.first {
                            if let style: Style = checkoutMerchantData.styles.first {
                                checkoutInfoCell.setData(withStyle: style)
                            } else {
                                ErrorLogManager.sharedManager.recordNonFatalError(withException: .NullPointer)
                            }
                        }
                    }
                    
                    reloadAllData()
                    
                    if self.checkoutMode == .updateStyle || self.checkoutMode == .style || self.checkoutMode == .multipleMerchant {
                        let color = style.validColorList[indexPath.item]
                        
                        if let sku = style.searchSku(style.selectedSizeId, colorId: style.selectedColorId, skuColor: style.selectedSkuColor) {
                            self.view.recordAction(.Tap, sourceRef: "\(color.colorId)", sourceType: .Color, targetRef: sku.skuCode, targetType: .ProductSku)
                        } else {
                            self.view.recordAction(.Tap, sourceRef: "\(color.colorId)", sourceType: .Color, targetRef: "", targetType: .ProductSku)
                        }
                    }
                }
            } else {
                ErrorLogManager.sharedManager.recordNonFatalError(withException: .IndexOutOfBounds)
            }
        case .size:
            if let style: Style = merchantSectionData.styles[checkoutSection.styleIndex], style.validSizeList[indexPath.item].isValid {
                if style.sizeIndexSelected == indexPath.item {
                    style.sizeIndexSelected = -1
                    style.selectedSizeId = -1
                } else {
                    style.sizeIndexSelected = indexPath.item
                    style.selectedSizeId = style.validSizeList[indexPath.item].sizeId
                }
                
                checkStock()
                
                // To reload the price base on size selected
                if let checkoutInfoCell = checkoutInfoCell, checkoutMode != .multipleMerchant {
                    if let checkoutMerchantData = merchantDataList.first {
                        if let style: Style = checkoutMerchantData.styles.first {
                            checkoutInfoCell.setData(withStyle: style)
                        } else {
                            ErrorLogManager.sharedManager.recordNonFatalError(withException: .DataIsEmpty)
                        }
                    } else {
                        ErrorLogManager.sharedManager.recordNonFatalError(withException: .DataIsEmpty)
                    }
                }
                
                reloadAllData()
                
                if self.checkoutMode == .updateStyle || self.checkoutMode == .style || self.checkoutMode == .multipleMerchant {
                    let size = style.validSizeList[indexPath.item]
                    
                    if let sku = style.searchSku(style.selectedSizeId, colorId: style.selectedColorId, skuColor: style.selectedSkuColor) {
                        self.view.recordAction(.Tap, sourceRef: "\(size.sizeId)", sourceType: .Size, targetRef: sku.skuCode, targetType: .ProductSku)
                    } else {
                        self.view.recordAction(.Tap, sourceRef: "\(size.sizeId)", sourceType: .Size, targetRef: "", targetType: .ProductSku)
                    }
                }
                
            }
        case .address:
            break
        case .merchantCoupon:
            showInputCouponView(isMMCoupon: false, atIndex: merchantIndex)
        case .mmCoupon:
            showInputCouponView(isMMCoupon: true)
        case .fullAddress:
            showAddressView()
        default:
            break
        }
    }
    
    // MARK: - Text Field delegate methods
    
    func scrollViewDidScroll(_ scrollView: UIScrollView) {
        if scrollView == self.collectionView {
            for key in checkoutInfoCellDict.keys {
                if let tag = Int(String(key)){
                    let merchantIndex = tag/self.getNumberOfCheckoutItems()
                    let styleIndex = tag%self.getNumberOfCheckoutItems()
                    self.addLeftSelectionForCheckoutInfoCell(checkoutInfoCellDict[key], merchantIndex: merchantIndex, styleIndex: styleIndex)
                }
            }
        }
    }
    
    func textFieldDidEndEditing(_ textField: UITextField) {
        if let quantityCell = self.quantityCell, textField == quantityCell.qtyTextField {
            if let textInput = textField.text {
                if !textInput.isEmpty {
                    if let quantityUpdated = Int(textInput) {
                        self.qty = getValidatedQuantity(quantityUpdated)
                    } else {
                        ErrorLogManager.sharedManager.recordNonFatalError(withException: .TypeMismatch)
                    }
                }
            }
            
            textField.text = String(self.qty)
            checkStock()
            
            if self.checkoutMode == .updateStyle || self.checkoutMode == .style || self.checkoutMode == .CartItem {
                if let style = merchantDataList.first?.styles.first {
                    if let sku = style.searchSku(style.selectedSizeId, colorId: style.selectedColorId, skuColor: style.selectedSkuColor) {
                        self.view.recordAction(.Input, sourceRef: String(self.qty), sourceType: .Qty, targetRef: sku.skuCode, targetType: .ProductSku)
                    } else {
                        ErrorLogManager.sharedManager.recordNonFatalError(withException: .NullPointer, parameters: ["message" : "Sku not found."])
                    }
                } else {
                    ErrorLogManager.sharedManager.recordNonFatalError(withException: .NullPointer)
                }
            }
        }
    }
    
    func textField(_ textField: UITextField, shouldChangeCharactersIn range: NSRange, replacementString string: String) -> Bool {
        if let quantityCell = self.quantityCell, textField == quantityCell.qtyTextField {
            if let style = merchantDataList.first?.styles.first {
                let selectedColor = style.getValidColorAtIndex(style.colorIndexSelected)
                let selectedSizeId = style.getValidSizeIdAtIndex(style.sizeIndexSelected)
                
                if let sku = style.searchSku(selectedSizeId, colorId: selectedColor?.colorId, skuColor: selectedColor?.skuColor) {
                    if checkoutMode == .updateStyle {
                        if sku.isOutOfStock() {
                            self.showError(String.localize("LB_OUT_OF_STOCK"), animated: true)
                            return false
                        }
                    }
                    
                    let currentText = textField.text ?? ""
                    let prospectiveText = (currentText as NSString).replacingCharacters(in: range, with:string)
                    
                    if prospectiveText.count == 1 {
                        let zeroString = "0"
                        let isEqualToZeroString = (string == zeroString)
                        
                        if isEqualToZeroString {
                            textField.text = "1"
                            self.qty = getValidatedQuantity(1)
                            
                            return false
                        }
                    }
                    
                    if prospectiveText.isNumberic() && prospectiveText != "" {
                        if let quantityInput = Int(prospectiveText) {
                            self.qty = getValidatedQuantity(quantityInput)
                            textField.text = String(self.qty)
                        } else {
                            ErrorLogManager.sharedManager.recordNonFatalError(withException: .TypeMismatch)
                        }
                        
                        return false
                    }
                    
                    return prospectiveText.isNumberic()
                } else {
                    ErrorLogManager.sharedManager.recordNonFatalError(withException: .NullPointer, parameters: ["message" : "Sku not found."])
                }
                
                checkStock()
            } else {
                ErrorLogManager.sharedManager.recordNonFatalError(withException: .DataIsEmpty)
            }
        }
        
        return true
    }
    
    // MARK: - PaymentMethodSelectionViewControllerDelegate
    
    func didSelectPayment(paymentIndex: Int, paymentName: String) {
        // TODO:
    }
    
    // MARK: - CheckoutFapiaoCellDelegate
    
    func didClickFapiaoButton(sender: UIButton) {
        merchantDataList[sender.tag].enabledFapiao = sender.selected
        
        sender.recordAction(.Tap, sourceRef: "InvoiceRequest", sourceType: .Button, targetRef: "OrderConfirmation", targetType: .View)
    }
    
    // MARK: - Actions
    
    @objc func toggleItem(sender: UITapGestureRecognizer) {
        if let tag = sender.view?.tag, let checkoutInfoCell = checkoutInfoCellDict["\(tag)"] {
            checkoutInfoCell.toggleItem()
        } else {
            ErrorLogManager.sharedManager.recordNonFatalError(withException: .IndexOutOfBounds)
        }
    }
    
    // MARK: - Helper
    
    private func getMerchantCodeList(styles: [Style]?) -> [Int] {
        var list = [Int]()
        
        if let styles = styles {
            for style in styles {
                if !list.contains(style.merchantId) {
                    list.append(style.merchantId)
                }
            }
        } else {
            ErrorLogManager.sharedManager.recordNonFatalError(withException: .NullPointer)
        }
        
        return list
    }
    
    private func getCellInformation(atIndexPath indexPath: IndexPath) -> (checkoutSection: CheckoutSection, checkoutItem: CheckoutItem, merchantIndex: Int, merchantSectionData: CheckoutMerchantData) {
        let checkoutSection = checkoutSections[indexPath.section]
        let checkoutItem = checkoutSection.checkoutItems[indexPath.item]
        let merchantIndex = (checkoutMode == .cartCheckout) ? checkoutSection.merchantDataIndex + 1 : checkoutSection.merchantDataIndex
        let merchantSectionData = merchantDataList[merchantIndex]
        
        return (checkoutSection, checkoutItem, merchantIndex, merchantSectionData)
    }
    
    private func cartInformationIsValid(forAction action: CheckoutAction = .Unknown) -> Bool {
        if action != .Unknown {
            if LoginManager.getLoginState() == .validUser || action != .checkout {
                // Stock error by checking api
                if let checkStockError = checkStockError {
                    if let errorDetail = checkStockError.userInfo["errorCode"] as? String {
                        self.showError(String.localize(errorDetail), animated: true)
                        return false
                    } else {
                        ErrorLogManager.sharedManager.recordNonFatalError(withException: .NullPointerOrTypeMismatch)
                    }
                }
                
                if action == .checkout {
                    if address == nil || address?.userAddressKey.length == 0 {
                        if checkoutMode != .cartCheckout {
                            showError(String.localize("MSG_ERR_ADDRESS_NIL"), animated: true)
                        }
                        
                        return false
                    }
                
                    // Order Currently Error by api checking
                    if let checkOrderError = checkOrderError {
                        if let errorDetail = checkOrderError.userInfo["errorCode"] as? String {
                            self.showError(String.localize(errorDetail), animated: true)
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
                                showError(String.localize("MSG_ERR_USER_FULLNAME"), animated: true)
                                return false
                            }
                        } else {
                            ErrorLogManager.sharedManager.recordNonFatalError(withException: .NullPointer)
                        }
                        
                        if checkoutMerchantData.enabledFapiao && (checkoutMerchantData.fapiaoText == nil || (checkoutMerchantData.fapiaoText ?? "").isEmptyOrNil()) {
                            showError(String.localize("MSG_ERR_CA_FAPIAO_NIL"), animated: true)
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
                            showError(String.localize("LB_MC_COLORS_SIZE_TITLE"), animated: true)
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
    
    private func showAddToCartAnimation() {
        if let redDotButton = redDotButton {
            var productImage: UIImage? = nil
            
            if let image = checkoutInfoCell?.getProductImage() {
                productImage = image
            } else {
                ErrorLogManager.sharedManager.recordNonFatalError(withException: .NullPointer)
            }
            
            if let productImage = productImage {
                if let view = UIApplication.shared.windows.first {
                    let animation = CheckoutAnimation(
                        itemImage: productImage,
                        itemSize: CGSize(width: ColorCellDimension, height: ColorCellDimension),
                        itemStartPos: footerView.convertPoint(checkoutButton.center, toView: view),
                        redDotButton: redDotButton
                    )
                    
                    view.addSubview(animation)
                    animation.showAnimation()
                } else {
                    ErrorLogManager.sharedManager.recordNonFatalError(withException: .DataIsEmpty)
                }
            } else {
                ErrorLogManager.sharedManager.recordNonFatalError(withException: .NullPointer)
            }
        }
    }

    private func getValidatedQuantity(quantity: Int) -> Int {
        return (quantity > MaximumQuantity) ? MaximumQuantity : (quantity < 0) ? 1 : quantity
    }
    
    private func getReferrerUserKey(withSkuId skuId: Int) -> String? {
        for (key, referrerUserKey) in referrerUserKeys {
            if skuId == Int(key) && referrerUserKey.length > 0 {
                return referrerUserKey
            }
        }
        
        return nil
    }
    
    private func getNumberOfCheckoutItems() -> Int{
        var count = 0
        for checkoutSection in checkoutSections{
            count =  count + checkoutSection.checkoutItems.count
        }
        
        return count
    }
    
    private func getCheckoutInfoTag(merchantIndex: Int, styleIndex: Int) -> Int{
        let count = self.getNumberOfCheckoutItems()
        return merchantIndex*count + styleIndex
    }
    
    private func addLeftSelectionForCheckoutInfoCell(checkoutInfoCell: CheckoutInfoCell?, merchantIndex: Int, styleIndex: Int) {
        guard let checkoutInfoCell = checkoutInfoCell else{
            ErrorLogManager.sharedManager.recordNonFatalError(withException: .NullPointer)
            return
        }
        
        if let leftSelectionView = leftSelectionViewDict["\(self.getCheckoutInfoTag(merchantIndex, styleIndex: styleIndex))"] {
            leftSelectionView.removeFromSuperview()
        }
        
        guard !checkoutInfoCell.productSelectionView.isHidden else{
            return
        }
        
        let singleTap = UITapGestureRecognizer(target: self, action: #selector(CheckoutViewController.toggleItem))
        
        let frame = checkoutInfoCell.frame
        let leftSelectionView = UIView()
        
        var height = frame.height
        
        if let viewFrame = checkoutSizeFooterViewFrameDict["\(self.getCheckoutInfoTag(merchantIndex, styleIndex: styleIndex))"] {
            height = viewFrame.maxY - checkoutInfoCell.frame.minY
        } else if let viewFrame = checkoutColorFooterViewFrameDict["\(self.getCheckoutInfoTag(merchantIndex, styleIndex: styleIndex))"] {
            height = viewFrame.maxY - checkoutInfoCell.frame.minY
        }

        if height < 0 {
            return
        }
        
        leftSelectionView.frame = CGRect(x: checkoutInfoCell.productSelectionView.frame.minX, y: frame.minY - (collectionView.contentOffset.y), width: checkoutInfoCell.productSelectionView.width, height: height)
        leftSelectionView.addGestureRecognizer(singleTap)
        leftSelectionView.tag = self.getCheckoutInfoTag(merchantIndex, styleIndex: styleIndex)
        
        self.contentView.addSubview(leftSelectionView)
        
        leftSelectionViewDict["\(self.getCheckoutInfoTag(merchantIndex, styleIndex: styleIndex))"] = leftSelectionView
    }
    
    private func preselectSize(style: Style, selectedSizeId: Int?) -> Bool{
        if let firstSize = style.validSizeList.first, style.validSizeList.count == 1{
            style.sizeIndexSelected = 0
            style.selectedSizeId = firstSize.sizeId
        }
        else{
            guard let selectedSizeId = selectedSizeId else{
                return false
            }
            
            for (index, size) in style.validSizeList.enumerate() {
                if size.sizeId == selectedSizeId {
                    style.sizeIndexSelected = index
                    style.selectedSizeId = size.sizeId
                    break
                }
            }
        }
        
        let skus = style.getValidSkusBySizeId(style.selectedSizeId)
        if skus.count == 0{
            style.sizeIndexSelected = -1
            style.selectedSizeId = -1
        }
        
        return (style.sizeIndexSelected != -1)
    }
    
    private func preselectColor(style: Style, selectedColorId: Int?, selectedSkuColor: String?) -> Bool{
        guard let selectedColorId = selectedColorId, let selectedSkuColor = selectedSkuColor, !selectedSkuColor.isEmpty else {
            if let noColor = style.validColorList.first, (style.validColorList.count == 1 && noColor.colorId == 1){
                style.colorIndexSelected = 0
                style.selectedColorId = noColor.colorId
                style.selectedColorKey = noColor.colorKey
                style.selectedSkuColor = noColor.skuColor
                return true
            }
            return false
        }
        
        var colorIndexList = [Int]()
        
        for i in 0..<style.validColorList.count {
            if style.validColorList[i].colorId == selectedColorId &&  style.validColorList[i].skuColor == selectedSkuColor{
                colorIndexList.append(i)
            }
        }
        
        if colorIndexList.count == 1 {
            let selectedColor = style.validColorList[colorIndexList[0]]
            style.colorIndexSelected = colorIndexList[0]
            style.selectedColorId = selectedColor.colorId
            style.selectedColorKey = selectedColor.colorKey
            style.selectedSkuColor = selectedColor.skuColor
        }
        
        let skus = style.getValidSkusByColorId(style.selectedColorId)
        if skus.count == 0{
            style.colorIndexSelected = -1
            style.selectedColorId = -1
            //style.selectedColorKey = ""
        }
        
        return (style.colorIndexSelected != -1)
    }
    
    private func preselectColorSize(style: Style, selectedSizeId: Int?, selectedSkuColor: String?, selectedColorId: Int?){
        style.sizeIndexSelected = -1
        style.colorIndexSelected = -1
        
        self.preselectSize(style, selectedSizeId: selectedSizeId)
        self.preselectColor(style, selectedColorId: selectedColorId, selectedSkuColor: selectedSkuColor)
    }
    
    func updateBrandNameForStyles(){
        for style in self.styles{
            if style.brandName.isEmpty{
                firstly {
                    return self.fetchBrand(style.brandId)
                    }.then { brand -> Void in
                        if let brand = brand as? Brand{
                            style.brandName = brand.brandName
                            self.reloadAllData()
                        }
                    }.always {
                    }.catch { _ -> Void in
                        Log.error("error")
                }
            }
        }
    }
    
    private func deselectStyles(styles: [Style]){
        for style in styles{
            style.selected = false
        }
    }
    
    func fetchBrand(brandId: Int) -> Promise<Any>{
        return Promise{ fulfill, reject in
            BrandService.view(brandId){ (response) in
                if response.result.isSuccess {
                    if response.response?.statusCode == 200 {
                        if let array = response.result.value as? [[String: Any]], let obj = array.first , let brand = Mapper<Brand>().map(JSONObject: obj) {
                            fulfill(brand)
                            
                        } else {
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
                }
                else {
                    reject(response.result.error!)
                }
            }
        }
    }
    
    // MARK: - Analytics
    
    private func getPositionLocation() -> String{
        switch checkoutMode {
        case .style, .multipleMerchant:
            return "SwipeToBuy"
        default:
            return "Cart"
        }
    }
}

internal class CheckoutActionSheetCollectionViewFlowLayout: UICollectionViewFlowLayout {
    
    weak var checkoutViewController: CheckoutViewController? {
        didSet {
            checkoutMode = checkoutViewController?.checkoutMode ?? CheckoutMode.Unknown
        }
    }
    
    private var checkoutMode = CheckoutMode.Unknown
    
    override func layoutAttributesForElementsInRect(rect: CGRect) -> [UICollectionViewLayoutAttributes]? {
        let attributes = super.layoutAttributesForElementsInRect(rect)
        
        let headerLeftMargin: CGFloat = (checkoutMode == .multipleMerchant) ? CheckoutViewController.MultipleMerchantSizeEdgeInsets.left : CheckoutViewController.NormalSizeEdgeInsets.left
        
        var leftMargin: CGFloat = 0
        var maxY: CGFloat = -1.0
        
        attributes?.forEach { layoutAttribute in
            if let strongCheckoutViewController = checkoutViewController {
                if layoutAttribute.representedElementCategory == UICollectionElementCategory.Cell {
                    let indexPath = layoutAttribute.indexPath
                    let checkoutSection = strongCheckoutViewController.checkoutSections[indexPath.section]
                    let checkoutItem = checkoutSection.checkoutItems[indexPath.item]
                    
                    if let _ = self.collectionView?.dequeueReusableCell(withReuseIdentifier: SizeCollectionCell.CellIdentifier, for: indexPath) as? SizeCollectionCell {
                        if checkoutItem.itemType == CheckoutItem.ItemType.Size {
                            if layoutAttribute.frame.origin.y >= maxY {
                                leftMargin = headerLeftMargin
                            }
                            
                            layoutAttribute.frame.origin.x = leftMargin
                            
                            leftMargin += layoutAttribute.frame.width + CheckoutViewController.SizeMinimumInteritemSpacing
                            
                            maxY = max(layoutAttribute.frame.maxY , maxY)
                        }
                    } else {
                        ErrorLogManager.sharedManager.recordNonFatalError(withException: .NullPointerOrTypeMismatch)
                    }
                }
            }
        }
        
        return attributes
    }
}
