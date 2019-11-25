//
//  FCheckoutViewController.swift
//  merchant-ios
//
//  Created by Stephen Yuen on 29/8/2016.
//  Copyright © 2016 WWE & CO. All rights reserved.
//

import UIKit
import PromiseKit
import ObjectMapper
import Alamofire


internal class FCheckoutActionSheetCollectionViewFlowLayout: UICollectionViewFlowLayout {
    private var checkoutMode = CheckoutMode.unknown
    
    weak var checkoutViewController: FCheckoutViewController? {
        didSet {
            checkoutMode = checkoutViewController?.checkoutMode ?? CheckoutMode.unknown
        }
    }

    override func layoutAttributesForElements(in rect: CGRect) -> [UICollectionViewLayoutAttributes]? {
        let attributes = super.layoutAttributesForElements(in: rect)
        
        let headerLeftMargin: CGFloat = (checkoutMode == .multipleMerchant) ? FCheckoutViewController.MultipleMerchantSizeEdgeInsets.left : FCheckoutViewController.NormalSizeEdgeInsets.left
        
        var leftMargin: CGFloat = 0
        var maxY: CGFloat = -1.0
        
        attributes?.forEach { layoutAttribute in
            if let strongCheckoutViewController = checkoutViewController {
                if layoutAttribute.representedElementCategory == UICollectionElementCategory.cell {
                    let indexPath = layoutAttribute.indexPath
                    let checkoutSection = strongCheckoutViewController.checkoutSections[indexPath.section]
                    let checkoutItem = checkoutSection.checkoutItems[indexPath.item]
                    
                    if let _ = self.collectionView?.dequeueReusableCell(withReuseIdentifier: SizeCollectionCell.CellIdentifier, for: indexPath) as? SizeCollectionCell {
                        if checkoutItem.itemType == CheckoutItem.ItemType.size {
                            if layoutAttribute.frame.origin.y >= maxY {
                                leftMargin = headerLeftMargin
                            }
                            
                            layoutAttribute.frame.origin.x = leftMargin
                            
                            leftMargin += layoutAttribute.frame.width + FCheckoutViewController.SizeMinimumInteritemSpacing
                            
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

class CheckoutService: NSObject {
    static let defaultService = CheckoutService()
    private let objectKey = "com.mymm.success_parent_key"
    
    func searchStyle(withStyleCodes styleCodes: [String], merchantIds: [String]) -> Promise<[Style]> {
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
    
    
    func saveSuccessParentOrderKey(withParentOrderKey parentOrderKey: String){
        var savedArray = getSuccessParentOrderKey()
        var isExisted = false
        for savedOrderKey in savedArray{
            if (savedOrderKey == parentOrderKey){
                isExisted = true
            }
        }
        if (isExisted){
            savedArray.append(parentOrderKey)
            let defaults = UserDefaults.standard
            defaults.set(savedArray, forKey: objectKey)
            defaults.synchronize()
        }
        
    }
    
    func getSuccessParentOrderKey() -> [String] {
        var resultArray = [String]()
        let defaults = UserDefaults.standard
        if let array = defaults.object(forKey: objectKey) {
            if let _array = array as? [String] {
                resultArray = _array
            }
        }
        return resultArray
    }
}


extension FCheckoutViewController: CheckoutPresenterDelegate {
    func refreshContent(_ isSuccess: Bool, isFullList: Bool, items: [NSObject]){
        
    }
    func updateMerchantDataList(_ merchantDataList: [CheckoutMerchantData]){
        self.merchantDataList = merchantDataList
        presenter.merchantDataList = merchantDataList
        if (self.checkoutMode == .cartCheckout){
            presenter.getBestCoupon(merchantDataList) { [weak self] (ccmCouponCheckMerchants ,couponMap) in
                if let strongSelf = self {
                    if let _ccmCouponCheckMerchants = ccmCouponCheckMerchants{
                        strongSelf.ccmCouponCheckMerchants = _ccmCouponCheckMerchants
                    }
                    strongSelf.refreshAllCoupon(couponMap)
                }
            }
        }
        
    }
    func updateParent(_ parentOrder: ParentOrder?){
        self.parentOrder = parentOrder
        if let _ = self.parentOrder{
            self.enableAllButton()
        }
        self.updateTotalPrice()
        
    }
    func updateCheckoutSection(_ checkoutSections: [CheckoutSection]){
        self.checkoutSections = checkoutSections
    }
    func returnDismissHandler(_ confirmed: Bool, parentOrder: ParentOrder?) {
        if let callback = self.didDismissHandler {
            callback(confirmed, parentOrder)
        }
    }
    func collectionReload(){
        if let collectionView = self.collectionView{
            collectionView.reloadData()
        }
    }
    
}

extension FCheckoutViewController: CheckoutFapiaoCellDelegate {
    func didClickFapiaoButton(_ sender: UIButton) {
        merchantDataList[sender.tag].enabledFapiao = sender.isSelected
        sender.recordAction(.Tap, sourceRef: "InvoiceRequest", sourceType: .Button, targetRef: "OrderConfirmation", targetType: .View)
    }
}

extension FCheckoutViewController: PaymentMethodSelectionViewControllerDelegate{
    func didSelectPayment(_ paymentIndex: Int, paymentName: String) {}
}

enum CheckoutMode: Int {
    case unknown = 0
    case style                          // [.Color, .Size, .Quantity, .Address, .PaymentMethod, .ShippingFee, .MerchantCoupon, .MmCoupon, .Fapiao]
    case cartItem                       // [.Color, .Size, .Quantity, .Address, .PaymentMethod, .ShippingFee, .MerchantCoupon, .MmCoupon, .Fapiao]
    case updateStyle                    // [.Color, .Size, .Quantity]
    case multipleMerchant               // [.Style, .Color, .Size, .ShippingFee, .MerchantCoupon, .Fapiao] (.Address, .PaymentMethod, .MmCoupon)
    case cartCheckout                   // (.FullAddress, .FullPaymentMethod) [.FullStyle, .Fapiao, .ShippingFee, .MerchantCoupon, .MerchantTotal, .Comments] (.MmCoupon)
//    case flashSale
}

enum CheckoutFromSource: Int {
    case unknown
    case fromWishlist
}

enum CheckoutAction: Int {
    case unknown = 0
    case addToCart
    case checkout
    case updateCart
}

class FCheckoutViewController: MmCartViewController {
    let presenter = CheckoutPresenter()
    
    // MARK: Items
    private var contentView = UIView()
    private var headerView = UIView()
    private var footerView = UIView()
    private let checkoutButton: UIButton = {
        let button = UIButton()
        button.formatPrimary()
        button.setTitle(String.localize("LB_EXCL_SUBMIT_INV_CODE"), for: UIControlState())
        return button
    }()
    //PDP弹出界面的按钮
    private let addToCartButton: UIButton = {
        let button = UIButton()
        button.formatPrimary()
        button.setTitleColor(UIColor.primary3(), for: UIControlState())
        button.setTitle(String.localize("LB_CA_ADD2CART"), for: UIControlState())
        button.backgroundColor = UIColor.white
        button.layer.cornerRadius = Constants.Button.Radius
        button.layer.borderColor = UIColor.primary3().cgColor
        button.layer.borderWidth = 1
        return button
    }()
    
    private let grandTotalLabel: UILabel = {
        let label = UILabel()
        label.formatSizeBold(14)
        label.textColor = UIColor.primary3()
        label.lineBreakMode = .byTruncatingTail
        label.numberOfLines = 1
        label.adjustsFontSizeToFitWidth = true
        return label
    }()
    
    private let totalLabel: UILabel = {
        let label = UILabel()
        label.text = String.localize("LB_CA_EDITITEM_SUBTOTAL")
        label.formatSize(14)
        label.sizeToFit()
        return label
    }()
    
    private let countTotalSelectedLabel: UILabel = {
        let label = UILabel()
        label.formatSize(12)
        label.textColor = UIColor.secondary3()
        label.lineBreakMode = .byTruncatingTail
        label.numberOfLines = 1
        label.adjustsFontSizeToFitWidth = true
        label.isHidden = true
        return label
    }()
    
    private let totalSavedLabel: UILabel = {
        let label = UILabel()
        label.formatSize(12)
        label.textColor = UIColor.secondary3()
        label.lineBreakMode = .byTruncatingTail
        label.numberOfLines = 1
        label.adjustsFontSizeToFitWidth = true
        label.isHidden = true
        return label
    }()
    
    
    var didDismissHandler: ((_ confirmed: Bool, _ parentOrder: ParentOrder?) -> ())?
    private var qty = 1 // TODO: Move to CheckoutMerchantData > Style
    
    private final let MaximumQuantity = 99
    private final let AnimationDuration: TimeInterval = 0.3
    private final let PlaceholderImage = UIImage(named: "holder")
    private final let StyleCellHeight: CGFloat = 100
    private final let labelBottomHeight: CGFloat = 16
    
    private final let ColorCellTopPadding: CGFloat = 15
    private final let ColorCellDimension: CGFloat = 50
    
    private final let SizeHeaderViewTopPadding: CGFloat = 9
    private final let SizeHeaderViewHeight: CGFloat = 30
    
    internal static let MultipleMerchantSizeEdgeInsets = UIEdgeInsets(top: 0, left: 49 , bottom: 0, right: 16)
    internal static let NormalSizeEdgeInsets = UIEdgeInsets(top: 0, left: 16 , bottom: 0, right: 16)
    internal static let SizeMinimumInteritemSpacing: CGFloat = 16

    private var checkoutInfoCellDict = [String: CheckoutInfoCell]()
    private var leftSelectionViewDict = [String: UIView]()
    private var checkoutSizeFooterViewFrameDict = [String: CGRect]()
    private var checkoutColorFooterViewFrameDict = [String: CGRect]()

    private var checkoutInfoCell: CheckoutInfoCell?
    private var quantityCell: QuantityCell?
    private var mmCouponIndexPath: IndexPath?

    internal var checkoutMode: CheckoutMode = .unknown {
        didSet {
            Log.debug("checkout Mode: \(checkoutMode)")
        }
    }

    private var address: Address?
    private var usingMMCoupon: Coupon?
    private var usingMerchantCoupons = [Coupon]()
    private var merchantDataList = [CheckoutMerchantData]()
    fileprivate var checkoutSections = [CheckoutSection]()
    private var ccmCouponMap = [Int: Coupon]()
    private var ccmCouponCheckMerchants = [CouponCheckMerchant]()
    private var redDotButton: ButtonRedDot?
    private var parentOrder: ParentOrder?
    
    private var checkStockError: NSError? = nil
    private var checkOrderError: NSError? = nil
    
    // For Analytic tag
    private var targetRef = ""
    
    // For MultipleMerchant Only
    private var skus: [Sku] = []
    private var skuIds: [Int] = []
    private var styles: [Style] = []
    private var hasAnyCrossBorderMerchant = false //if any cross border merchant in check out this variable will be true
    private var userIdentificationNumber = ""
    
    // For CartCheckout Only
    private var referrerUserKeys: [String : String] = [:] // skuId : referrerUserKey
    private var referrerUserKey: String?
    private var cartItem: CartItem?
    private var defaultFapiaoText = String.localize("LB_CA_FAPIAO_NO_NEED")
    private var fromCartCheckout = false
    private var countTotalSelectedWidth: CGFloat = 0
    private let paddingLeft: CGFloat = 20
    private var originalTotal = Double(0)
    var isCart = true
    var isFlashSale = false {        // 作用于订viewmodel = .cartCheckout（单确认），本次提交是否为限购，要生产限购订单
        didSet {
            presenter.isFlashSale = isFlashSale
        }
    }
    
    var checkOutActionType: CheckoutAction = CheckoutAction.unknown // 判断上一个界面是通过购物车还是立即购买状态
    
    var isFlashSaleEligible = false // 作用于viewmodel = .style场景（用于PDP显示）， 当前用户是否满足限购状态
    var checkoutFromSource: CheckoutFromSource = .unknown
    var styleViewController: StyleViewController?

    //MARK: - PDP中点击立即购买时出现的选择sku的弹窗
    convenience init(checkoutMode: CheckoutMode, merchant: Merchant?, style: Style?, referrer: String?, selectedSkuColor: String? = nil, selectedColorId: Int? = nil, selectedSizeId: Int? = nil, redDotButton: ButtonRedDot? = nil, targetRef: String = "") {
        self.init(nibName: nil, bundle: nil)
        //.Style
        self.targetRef = targetRef
        self.checkoutMode = checkoutMode
        
        // TODO: Get Merchant
        if let style = style {
            self.styles.append(style)
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
    
    convenience init(checkoutMode: CheckoutMode, skus: [Sku], styles: [Style], referrer: String?, redDotButton: ButtonRedDot? = nil, targetRef: String = "") {
        self.init(nibName: nil, bundle: nil)
        //.MultipleMerchant
        self.targetRef = targetRef
        self.checkoutMode = checkoutMode
        self.skus = skus
        self.styles = styles
        
        if checkoutMode == .multipleMerchant{
            for style in self.styles{
                style.selected = false
            }
        }
        
        // To update brand name for styles
        for style in self.styles{
            if style.brandName.isEmpty{
                presenter.loadFetchBrand(style.brandId, completion: { (success, brand) in
                    if(success){
                        if let _brand = brand{
                            style.brandName = _brand.brandName
                            self.reloadAllData()
                        }
                    }
                })
            }
        }
        
        if let _ = referrer {
            self.referrerUserKey = referrer
        }
        
        if let _ = redDotButton {
            self.redDotButton = redDotButton
        }
    }
    
    convenience init(checkoutMode: CheckoutMode, merchant: Merchant?, cartItem: CartItem, referrer: String?, redDotButton: ButtonRedDot? = nil, targetRef: String = "") {
        self.init(nibName: nil, bundle: nil)
        //.UpdateStyle
        //.CartItem
        self.targetRef = targetRef
        self.checkoutMode = checkoutMode
        self.cartItem = cartItem
        
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
    
    //MARK: - 订单详情的便利构造函数
    convenience init(checkoutMode: CheckoutMode, skus: [Sku], styles: [Style], referrerUserKeys: [String : String], targetRef: String = "") {
        self.init(nibName: nil, bundle: nil)
        //.CartCheckout
        self.targetRef = targetRef
        self.checkoutMode = checkoutMode
        self.skus = skus
        self.styles = styles
        self.referrerUserKeys = referrerUserKeys
    }
    
    convenience init(checkoutMode: CheckoutMode, sku: Sku, style: Style, referrerUserKey: String?, targetRef: String = "") {
        self.init(nibName: nil, bundle: nil)
        //.FlashSale
        self.targetRef = targetRef
        self.checkoutMode = checkoutMode
        self.skus = [sku]
        self.styles = [style]
        self.referrerUserKey = referrerUserKey
    }
    
    func getViewTitle() -> String {
        return String.localize("LB_CA_ORDER_CONFIRMATION")
    }
    
    // MARK: - Observer
    override func keyboardWillShowNotification(_ notification: NSNotification) {
        super.keyboardWillShowNotification(notification)
        
        if let keyboardSize = (notification.userInfo?[UIKeyboardFrameEndUserInfoKey] as? NSValue)?.cgRectValue {
            contentView.y = ScreenHeight - contentView.height - keyboardSize.height
            
            if(checkoutMode == .cartCheckout){
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
        
        if(checkoutMode == .cartCheckout){
            var frame = collectionView.frame
            frame.size.height = contentView.height - footerView.height - 64
            frame.origin.y = 64
            collectionView.frame = frame
        }
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        initAnalyticLog()
        
        NotificationCenter.default.addObserver(self, selector: #selector(FCheckoutViewController.applicationDidBecomeActive), name: NSNotification.Name.UIApplicationDidBecomeActive, object: nil)
        if let viewControllers = self.navigationController?.viewControllers {
            fromCartCheckout = (viewControllers.count == 1)
        }
        
        contentView.frame = self.view.frame
        
        if fromCartCheckout {
            // Action Sheet Checkout
            self.view.backgroundColor = UIColor.init(white: 0, alpha: 0.6)
            contentView.y = view.height
            contentView.height = view.height * 2 / 3
            
            let dismissViewButton = UIButton(type: .custom)
            dismissViewButton.frame = view.frame
            dismissViewButton.addTarget(self, action: #selector(self.actionDismissViewDidTap), for: .touchUpInside)
            self.view.addSubview(dismissViewButton)
        }
        
        if(checkoutMode == .cartCheckout){
            self.title = self.getViewTitle()
            createBackButton()
        }
        
        view.addSubview(contentView)
    
        presenter.delegate = self
        presenter.setupPresenter(fromCartCheckout)
        presenter.checkoutMode = checkoutMode
        presenter.checkoutFromSource = checkoutFromSource
        presenter.contentView = contentView
        presenter.headerView = headerView
        presenter.footerView = footerView
        presenter.address = address
        presenter.collectionView = collectionView
        presenter.merchantDataList = merchantDataList
        presenter.referrerUserKeys = referrerUserKeys
        presenter.referrerUserKey = referrerUserKey
        presenter.qty = qty
        
        presenter.cartItem = cartItem
        
        if checkoutMode != .multipleMerchant && checkoutMode != .cartCheckout {
            setupHeaderView()
        }
        
        setupFooterView()
        setupCollectionView()
        setupDismissKeyboardGesture()

        if checkoutMode == .multipleMerchant || checkoutMode == .cartCheckout {
            // pass styles in
            for sku in skus {
                skuIds.append(sku.skuId)
            }
            
            LoadingOverlay.shared.showOverlay(self)
            presenter.loadCachedMerchantsByMerchantIDs(self.getMerchantCodeList(self.styles), styles: self.styles, skus: self.skus)
            startLoading()

        } else {
            startLoading()
        }
        
//        let user = Context.getUserProfile()
        presenter.defaultFapiaoText = defaultFapiaoText
        
        /*
        for checkoutMerchantData in merchantDataList {
            checkoutMerchantData.fapiaoText = String.localize("LB_CA_FAPIAO_NO_NEED")
        }*/
        
        reloadAllData()
        presenter.initAnalyticLog()
    }
    
    @objc func appMovedToBackground() {
        let delayTime = DispatchTime.now() + Double(Int64(1 * Double(NSEC_PER_SEC))) / Double(NSEC_PER_SEC)
        DispatchQueue.main.asyncAfter(deadline: delayTime) {
            self.checkUnpaid()
            self.enableAllButton()
        }
    }
    
    func checkUnpaid(){
        if(checkoutMode == .cartCheckout){
            if (startPaymentProcess){
                presenter.initAlipayCancelAnalyticLog()
                AnalyticsManager.sharedManager.recordView(analyticsViewRecord)
                
                if let _ = self.presentedViewController as? UIAlertController{
                    return
                }
                
                let alertController = UIAlertController(title: String.localize("LB_CA_UNPAID_ORDER_FAILED_TO_PAY"), message: String.localize("LB_CA_UNPAID_ORDER_FAILED_TO_PAY_DIALOG"), preferredStyle: UIAlertControllerStyle.alert)
                var okString: String!
                okString = String.localize("LB_CA_UNPAID_ORDER_CHECK_ORDER")
                
                let okAction = UIAlertAction(title: okString, style: .default) { UIAlertAction in
                    self.view.recordAction(.Tap, sourceRef: "CheckOrder", sourceType: .Button, targetRef: "PendingPayment", targetType: .View)
                    
                    let showUnpaidOrderPage: () -> () = {
                        var bundle = QBundle()
                        bundle["viewMode"] = QValue(Constants.OmsViewMode.unpaid.rawValue)
                        Navigator.shared.dopen(Navigator.mymm.website_order_list, params: bundle)
                    }
                    
                    if let navi = self.navigationController {
                        if let _ = navi.presentingViewController {
                            self.dismiss(animated: false, completion: {
                                showUnpaidOrderPage()
                            })
                        } else {
                            navi.popViewController(animated: false) //移除栈后push
                            showUnpaidOrderPage()
                        }
                    }
                    else{
                        showUnpaidOrderPage()
                    }
                }
                
                alertController.addAction(okAction)
                self.present(alertController, animated: true, completion: nil)
            }
        }
    }

    func startLoading() {
        firstly {
            return CacheManager.sharedManager.listClaimedCoupon()
            }.then { _ -> Void in
                self.updateOriginalTotal()
                
                self.presenter.loadDefaultAddress({ (success, address) in
                    if(success){
                        self.address = address
                        self.presenter.address = address
                        self.reloadAllData()
                    }else{
                        self.reloadAllData()
                    }
                })
                
                self.loadIdNumber()
                
                LoadingOverlay.shared.hideOverlayView()
        }
    }
    
    func loadIdNumber() {
        self.presenter.loadUserIDNumberIdentification({ (success, value) in
            if (success) {
                if let idenNumber = value {
                    self.userIdentificationNumber = idenNumber.identificationNumber
                    self.collectionReload()
                }
            }
        })
    }
    
     override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        self.view.initAnalytics(withViewKey: analyticsViewRecord.viewKey)
        if fromCartCheckout {
            self.navigationController?.isNavigationBarHidden = true
        }else{
            self.navigationController?.isNavigationBarHidden = false
        }
        enableAllButton()
        
        NotificationCenter.default.addObserver(self, selector: #selector(self.appMovedToBackground), name: NSNotification.Name.UIApplicationWillEnterForeground, object: nil)
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        if fromCartCheckout {
            UIView.animate(withDuration: AnimationDuration, animations: { [weak self] () -> Void in
                if let strongSelf = self {
                    strongSelf.contentView.transform = CGAffineTransform(translationX: 0, y: -strongSelf.contentView.height)
                } else {
                    ErrorLogManager.sharedManager.recordNonFatalError(withException: .NullPointer)
                }
            }) 
        }
        enableAllButton()
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        NotificationCenter.default.removeObserver(self, name: NSNotification.Name.UIApplicationWillEnterForeground, object: nil)
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
    }
    
    @objc func applicationDidBecomeActive(_ sender: Notification) {
        enableAllButton()
    }
    
    func enableAllButton(){
        confirmButton.isUserInteractionEnabled = true
        checkoutButton.isUserInteractionEnabled = true
        confirmButton.formatPrimary()
        checkoutButton.formatPrimary()
    }
    
    func disableAllButton(){
        confirmButton.isUserInteractionEnabled = false
        checkoutButton.isUserInteractionEnabled = false
        confirmButton.formatDisable()
        checkoutButton.formatDisable()
    }
    
    func reloadAllData() {
        // Update checkoutInfoCell product image (Single product)
        DispatchQueue.main.async {
            if let checkoutInfoCell = self.checkoutInfoCell {
                if let style = self.merchantDataList.first?.styles.first {
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
            
            self.checkoutSections.removeAll()
            
            for checkoutMerchantData in self.merchantDataList {
                if let merchant = checkoutMerchantData.merchant, merchant.isCrossBorder {
                    self.hasAnyCrossBorderMerchant = true
                }
                
                checkoutMerchantData.updateCheckoutItems()
                self.checkoutSections.append(contentsOf: checkoutMerchantData.checkoutSections)
            }
            
            //To Show PRD ID row for cross border merchant
            if self.hasAnyCrossBorderMerchant {
                if let headerMerchantData = self.merchantDataList.filter({$0.sectionPosition == .header}).first {
                    if let checkoutSection = headerMerchantData.checkoutSections.first {
                        checkoutSection.checkoutItems.append(CheckoutItem(itemType: .prc))
                    }
                }
            }
            
            for bestMerchantCoupon in self.usingMerchantCoupons{
                if let bestMerchantId = bestMerchantCoupon.merchantId {
                    for checkoutMerchantData in self.merchantDataList where checkoutMerchantData.merchant?.merchantId == bestMerchantId {
                        checkoutMerchantData.merchantCoupon = bestMerchantCoupon
                    }
                }
            }
            
            self.updateButtonsState()
            
            //
            let selectedSku = self.presenter.getSelectSku()
            var currentFlashSale = false
            if let sku = selectedSku,self.isFlashSaleEligible,sku.isFlashOnSale() {
                currentFlashSale = true
            }
            self.presenter.checkOutOfStock(self.usingMMCoupon, flashSale:(currentFlashSale || self.isFlashSale), completion: nil)
            
            self.collectionView.reloadData()

        }
        
        
    }
    
    private func refreshAllCoupon(_ couponMap: [Int: Coupon]?){
        // clear all excited coupon
        usingMerchantCoupons = []
        for checkoutMerchantData in merchantDataList {
            checkoutMerchantData.merchantCoupon = nil
        }
        
        ccmCouponMap = couponMap ?? [:]
        var bestMMCoupon: Coupon?
        var bestMerchantCoupons = [Coupon]()
        
        if let couponDict = couponMap{
            if let coupon = couponDict[0]{
                bestMMCoupon = coupon
            }
            
            for (merchantId, couponValue) in couponDict {
                if (merchantId != 0){
                    bestMerchantCoupons.append(couponValue)
                }
            }
        }
        
        usingMMCoupon = bestMMCoupon

        for bestMerchantCoupon in bestMerchantCoupons{
            if let bestMerchantId = bestMerchantCoupon.merchantId {
                for checkoutMerchantData in merchantDataList where checkoutMerchantData.merchant?.merchantId == bestMerchantId {
                    checkoutMerchantData.merchantCoupon = bestMerchantCoupon
                    usingMerchantCoupons.append(bestMerchantCoupon)
                }
            }
        }
        presenter.merchantDataList = merchantDataList
        presenter.checkOutOfStock(usingMMCoupon, flashSale:self.isFlashSale, completion: nil)
        DispatchQueue.main.async {
            self.collectionView.reloadData()
        }
        
    }
    
    // MARK: - UI Control Setup ///////////////////////////////////////////////////////////////
    private func setupHeaderView() {
        var viewHeight: CGFloat = 98
        
        if isFlashSaleEligible {
            viewHeight += 8
        }
        
        headerView.frame = CGRect(x: 0, y: 0, width: contentView.width, height: viewHeight)
        
        checkoutInfoCell = CheckoutInfoCell(frame: CGRect(x: 0, y: 0, width: headerView.width, height: headerView.height), haveCouponButton: [.style, .cartItem].contains(checkoutMode) ? true : false)
        
        var data: Any?
        
        if let checkoutInfoCell = checkoutInfoCell {
            switch checkoutMode {
            case .style:
                if let checkoutMerchantData = merchantDataList.first {
                    if let style: Style = checkoutMerchantData.styles.first {
                        checkoutInfoCell.setData(withStyle: style)
                        checkoutInfoCell.isFlashSaleEligible = self.isFlashSaleEligible
                        data = checkoutMerchantData.merchant
                        
                        reloadAllData()
                        let sku = style.searchSku(style.selectedSizeId, colorId: style.selectedColorId, skuColor: style.selectedSkuColor)
                        
                        var merchantCode = style.merchantCode
                        
                        if let merchant = checkoutMerchantData.merchant, merchantCode.length == 0 {
                            merchantCode = merchant.merchantCode
                        }
                        
                        checkoutInfoCell.initAnalytics(withViewKey: self.analyticsViewRecord.viewKey, impressionKey: AnalyticsManager.sharedManager.recordImpression(brandCode: "\(style.brandId)", impressionRef: style.styleCode, impressionType: "Product", impressionVariantRef: sku?.skuCode ?? "", impressionDisplayName: style.skuName, merchantCode: merchantCode, positionComponent: "ProductListing", positionIndex: 1, positionLocation: "Cart", viewKey: self.analyticsViewRecord.viewKey))
                        
                    } else {
                        ErrorLogManager.sharedManager.recordNonFatalError(withException: .DataIsEmpty)
                    }
                } else {
                    ErrorLogManager.sharedManager.recordNonFatalError(withException: .DataIsEmpty)
                }
            case .cartItem:
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
                                self.styles = [style]
                                self.skus = filteredSkuList
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
                                for i in 0..<style.validColorList.count {
                                    if (style.validColorList[i].colorId == cartItem.colorId) && (style.validColorList[i].skuColor == cartItem.skuColor) {
                                        style.colorIndexSelected = i
                                        break
                                    }
                                }
                                
                                for i in 0..<style.validSizeList.count {
                                    if style.validSizeList[i].sizeId == cartItem.sizeId {
                                        style.sizeIndexSelected = i
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
                    
                    checkoutInfoCell.initAnalytics(withViewKey: self.analyticsViewRecord.viewKey, impressionKey: AnalyticsManager.sharedManager.recordImpression(brandCode: "\(cartItem.brandId)", impressionRef: cartItem.styleCode, impressionType: "Product", impressionVariantRef: cartItem.skuCode, impressionDisplayName: cartItem.skuName, merchantCode: merchantCode, positionComponent: "ProductListing", positionIndex: 1, positionLocation: "Cart", viewKey: self.analyticsViewRecord.viewKey))
                } else {
                    ErrorLogManager.sharedManager.recordNonFatalError(withException: .NullPointer)
                }
            default:
                break
            }
            
            checkoutInfoCell.viewCouponHandler = { [weak self] in
                if let strongSelf = self {
                    // record action
                    strongSelf.view.recordAction(.Tap, sourceRef: "SwipeToBuy-MerchantCouponClaimList", sourceType: .Button, targetRef: "MerchantCouponClaimList", targetType: .View)

                    if let merchant = data as? Merchant {
                        self?.dismiss(animated: false, completion: {
                            Navigator.shared.dopen(Navigator.mymm.website_coupon_center + "\(merchant.merchantId)")
                        })
                    }
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
        
        footerView.frame = CGRect(x: 0, y: contentView.height - viewHeight - ScreenBottom, width: contentView.width, height: viewHeight + ScreenBottom)
        footerView.backgroundColor = UIColor.white
        
        
        totalLabel.frame = CGRect(x: paddingLeft, y: (footerView.height - labelBottomHeight) / 2, width: totalLabel.width, height: labelBottomHeight)
        
        footerView.addSubview(totalLabel)
        
        let rightButtonFrame = CGRect(x: footerView.width - rightButtonWidth - paddingRight, y: (footerView.height - buttonHeight) / 2 , width: rightButtonWidth, height: buttonHeight )
        var grandTotalLabelWidth: CGFloat = 0
        
        switch checkoutMode {
        case .updateStyle:
            confirmButton.frame = rightButtonFrame
            confirmButton.addTarget(self, action: #selector(self.actionConfirmForCart), for: .touchUpInside)
            footerView.addSubview(confirmButton)
            
            grandTotalLabelWidth = confirmButton.x - totalLabel.frame.maxX
        case .cartCheckout:
            let confirmButtonWidth: CGFloat = 106
            confirmButton.frame = CGRect(x: footerView.width - confirmButtonWidth - paddingRight, y: (footerView.height - buttonHeight) / 2, width: confirmButtonWidth, height: buttonHeight)
            confirmButton.addTarget(self, action: #selector(self.actionCheckout), for: .touchUpInside)
            footerView.addSubview(confirmButton)
            
            grandTotalLabelWidth = confirmButton.x - totalLabel.frame.maxX
            countTotalSelectedWidth = confirmButton.x - paddingLeft - paddingBetweenItems

        default:
            checkoutButton.frame = rightButtonFrame
            checkoutButton.addTarget(self, action: #selector(actionCheckout), for: .touchUpInside)
            footerView.addSubview(checkoutButton)
            
            addToCartButton.frame = CGRect(x: checkoutButton.x - leftButtonWidth - paddingBetweenItems, y: checkoutButton.y, width: leftButtonWidth, height: checkoutButton.height )
            addToCartButton.addTarget(self, action: #selector(self.actionAddToCart), for: .touchUpInside)
            footerView.addSubview(addToCartButton)
            
            grandTotalLabelWidth = addToCartButton.x - totalLabel.frame.maxX - paddingBetweenItems
            countTotalSelectedWidth = addToCartButton.x - paddingLeft - paddingBetweenItems
        }
        
        grandTotalLabel.frame = CGRect(x: totalLabel.frame.maxX, y: (footerView.height - labelBottomHeight) * 0.3, width: grandTotalLabelWidth, height: labelBottomHeight)
        footerView.addSubview(grandTotalLabel)
        
        countTotalSelectedLabel.frame = CGRect(x: paddingLeft, y: (footerView.height - labelBottomHeight) * 0.7, width: countTotalSelectedWidth, height: labelBottomHeight)
        footerView.addSubview(countTotalSelectedLabel)
        

        footerView.addSubview(totalSavedLabel)

        let borderView = UIView(frame: CGRect(x: 0, y: 0, width: footerView.width, height: 1))
        borderView.backgroundColor = UIColor.secondary1()
        footerView.addSubview(borderView)
        
        contentView.addSubview(footerView)
        
        addToCartButton.addTarget(self, action: #selector(self.actionAddToCart), for: .touchUpInside)

    }
    
    private func setupCollectionView() {
        if fromCartCheckout {
            let checkoutActionSheetCollectionViewFlowLayout = FCheckoutActionSheetCollectionViewFlowLayout()
            checkoutActionSheetCollectionViewFlowLayout.checkoutViewController = self
            checkoutActionSheetCollectionViewFlowLayout.sectionInset = UIEdgeInsets(top: 0, left: 0, bottom: 0, right: 0)
            checkoutActionSheetCollectionViewFlowLayout.itemSize = CGSize(width: self.view.frame.width, height: 120)
            collectionView.setCollectionViewLayout(checkoutActionSheetCollectionViewFlowLayout, animated: true)
            collectionView.frame = CGRect(x: 0, y: headerView.frame.maxY, width: contentView.width, height: contentView.height - footerView.height - headerView.frame.maxY)
        } else {
            collectionView.frame = CGRect(x: 0, y: StartYPos, width: contentView.width, height: contentView.height - footerView.height - 64)
        }
        
        collectionView.backgroundColor = UIColor.white
        
        collectionView.register(SizeHeaderView.self, forSupplementaryViewOfKind: UICollectionElementKindSectionHeader, withReuseIdentifier: SizeHeaderView.ViewIdentifier)
        collectionView.register(CouponInputHeaderView.self, forSupplementaryViewOfKind: UICollectionElementKindSectionHeader, withReuseIdentifier: CouponInputHeaderView.ViewIdentifier)
        collectionView.register(SeparatorHeaderView.self, forSupplementaryViewOfKind: UICollectionElementKindSectionFooter, withReuseIdentifier: SeparatorHeaderView.ViewIdentifier)
        collectionView.register(CrossBorderWarningView.self, forSupplementaryViewOfKind: UICollectionElementKindSectionFooter, withReuseIdentifier: CrossBorderWarningView.ViewIdentifier)
        collectionView.register(CheckoutFooterView.self, forSupplementaryViewOfKind: UICollectionElementKindSectionFooter, withReuseIdentifier: CheckoutFooterView.ViewIdentifier)
        collectionView.register(PersonalInformationSettingMenuCell.self, forCellWithReuseIdentifier: PersonalInformationSettingMenuCell.CellIdentifier)
        
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
    
    // MARK: - Scroll Control ///////////////////////////////////////////////
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
    
    // MARK: - Action
    
    func setValueCountSelectedLabel(_ value: Int) {
        countTotalSelectedLabel.text = String.localize("LB_SELECTED_PI_NO") + "(\(value))"
        if value > 1 {
            countTotalSelectedLabel.isHidden = false
            countTotalSelectedLabel.frame = CGRect(x: countTotalSelectedLabel.x, y: countTotalSelectedLabel.y, width: StringHelper.getTextWidth(countTotalSelectedLabel.text!, height: countTotalSelectedLabel.height, font: countTotalSelectedLabel.font), height: countTotalSelectedLabel.height)
            totalLabel.frame.originY = (footerView.height - labelBottomHeight) * 0.3
            grandTotalLabel.frame.originY = (footerView.height - labelBottomHeight) * 0.3
        } else {
            countTotalSelectedLabel.isHidden = true
            //Align Center Vertical when hiding countTotalSelectedLabel
            totalLabel.frame.originY = (footerView.height - labelBottomHeight) / 2
            grandTotalLabel.frame.originY = (footerView.height - labelBottomHeight) / 2
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
        self.navigationController?.push(styleViewController, animated: true)
    }
    
    func updateOriginalTotal() {
        originalTotal = 0
        var mmTotal = Double(0)
        var merchantTotal = Double(0)
        
        for checkoutMerchantData in merchantDataList {
            switch checkoutMode {
            case .updateStyle: break
                
            case .cartCheckout:
                originalTotal += checkoutMerchantData.getMerchantTotal(includeShipmentFee: true, includeCoupon: false, selectedSkus: [], parentOrder: parentOrder, isFlashSale: self.isFlashSale)
                mmTotal += checkoutMerchantData.getMerchantTotal(includeShipmentFee: false, includeCoupon: true, selectedSkus: [], parentOrder: parentOrder, isFlashSale: self.isFlashSale)
                merchantTotal += checkoutMerchantData.getMerchantTotal(includeShipmentFee: false, includeCoupon: false, selectedSkus: [], parentOrder: parentOrder, isFlashSale: self.isFlashSale)
                
            default:
                originalTotal += checkoutMerchantData.getMerchantTotal(includeShipmentFee: true, includeCoupon: false, qty: qty, parentOrder: parentOrder)
                mmTotal += checkoutMerchantData.getMerchantTotal(includeShipmentFee: false, includeCoupon: true, qty: qty, parentOrder: parentOrder)
                merchantTotal += checkoutMerchantData.getMerchantTotal(includeShipmentFee: false, includeCoupon: false, qty: qty, parentOrder: parentOrder)
                
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
        
        total = parentOrder?.grandTotal ?? 0
        
        if (checkoutMode != .cartCheckout) {
            for checkoutMerchantData in merchantDataList {
                for style in checkoutMerchantData.styles where style.selected {
                    let filterOrder = parentOrder?.orders?.filter{$0.merchantId == style.merchantId}
                    if let _filterOrder = filterOrder{
                        if _filterOrder.count > 0 {
                            let order = _filterOrder[0]
                            total -= Double(order.shippingTotal)
                        }
                    }
                }
            }
            originalTotal = total
            DispatchQueue.main.async {
                self.grandTotalLabel.text = total.formatPrice()
            }
            
        }else{
            DispatchQueue.main.async {
                self.grandTotalLabel.text = total.formatPrice()
            }
        }
        
        
        var differentTotal: Double = 0
        differentTotal += usingMMCoupon?.couponAmount ?? 0
        for checkoutMerchantData in merchantDataList {
            var hasSelectedStyle = false
            for style in checkoutMerchantData.styles where style.selected {
                hasSelectedStyle = true
            }
            if let merchant = checkoutMerchantData.merchant, hasSelectedStyle {
                for coupon in usingMerchantCoupons{
                    if merchant.merchantId == coupon.merchantId ?? -1 {
                        differentTotal += coupon.couponAmount
                    }
                }
            }
        }
        
        
        if differentTotal > 0 {
            totalSavedLabel.isHidden = false
            
            totalSavedLabel.text = String.localize("LB_CA_CHECKOUT_COUPON_SAVED").replacingOccurrences(of: "{SavedAmount}", with: differentTotal.formatPriceWithoutCurrencySymbol() ?? "")
            
            totalLabel.frame.originY = (footerView.height - labelBottomHeight) * 0.3
            grandTotalLabel.frame.originY = (footerView.height - labelBottomHeight) * 0.3
            
            if countTotalSelectedLabel.isHidden {
                totalSavedLabel.frame = CGRect(x: paddingLeft, y: (footerView.height - labelBottomHeight) * 0.7, width: countTotalSelectedWidth, height: labelBottomHeight)
            }
            else {
                countTotalSelectedLabel.frame = CGRect(x: countTotalSelectedLabel.x, y: countTotalSelectedLabel.y, width: StringHelper.getTextWidth(countTotalSelectedLabel.text!, height: countTotalSelectedLabel.height, font: countTotalSelectedLabel.font), height: countTotalSelectedLabel.height)
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
                checkoutButton.isEnabled = true
                checkoutButton.formatPrimary()
            } else {
                addToCartButton.isEnabled = false
                checkoutButton.isEnabled = false
                checkoutButton.formatDisable()
            }
            
            if checkoutMode == .style && self.isFlashSaleEligible {
                if let sku = self.presenter.getSelectSku(), sku.isFlashOnSale() {
                    addToCartButton.isHidden = true
                    checkoutButton.setTitle(String.localize("LB_CA_NEWBIEPRICE_PDP_BUY_NOW"), for: UIControlState())
                } else {
                    addToCartButton.isHidden = false
                    checkoutButton.setTitle(String.localize("LB_EXCL_SUBMIT_INV_CODE"), for: UIControlState())
                }
            } else {
                addToCartButton.isHidden = false
                checkoutButton.setTitle(String.localize("LB_EXCL_SUBMIT_INV_CODE"), for: UIControlState())
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
//            updateTotalPrice()
        }
        
        if checkOutActionType == .addToCart {
            // 只有购物车
            addToCartButton.x = footerView.width - addToCartButton.width - 8
            checkoutButton.isHidden = false
        } else if checkOutActionType == .checkout {
            // 只有确认
            addToCartButton.isHidden = true
        }
    }
    
    // MARK: - Button Actions or Cell Selection
    
    func didSelectFapiao(_ merchantIndex: Int) {
        presenter.goToFapiaoPage(self.merchantDataList[merchantIndex].fapiaoText ?? "") { (fapiao) in

            var needInvoice = true
            if (fapiao != String.localize("LB_CA_FAPIAO_NO_NEED")){
                needInvoice = true
            }
            self.merchantDataList[merchantIndex].fapiaoText = fapiao
            self.merchantDataList[merchantIndex].enabledFapiao = needInvoice
            
            self.presenter.merchantDataList = self.merchantDataList
            
            DispatchQueue.main.async {
                self.collectionView.reloadData()
            }
        }
    }
    
    func didSelectPRCView() {
        let viewController = IDCardCollectionPageViewController(updateCardAction: .setting)
        viewController.callBackAction = { [weak self] in
            if let strongSelf = self {
                strongSelf.loadIdNumber()
            }
        }
        self.navigationController?.push(viewController, animated: true)
    }
    
    func didSelectAddressView() {
        self.view.recordAction(.Tap, sourceRef: address?.userAddressKey ?? "", sourceType: .ShippingAddress, targetRef: "UserAddress-Select", targetType: .View)
        presenter.goToAddressPage(address, mode: .checkout) { [weak self] (address) in
            if let strongSelf = self {
                strongSelf.address = address
                strongSelf.presenter.address = address
                strongSelf.reloadAllData()
            } else {
                ErrorLogManager.sharedManager.recordNonFatalError(withException: .NullPointer)
            }
        }
    }
    
    func didSelectCouponView(isMMCoupon: Bool, atIndex index: Int = 0) {
        if LoginManager.getLoginState() == .validUser {
            
            let cartMerchant = CartMerchant()
            var total: Double = 0
            
            
            
            if isMMCoupon {
                // record action
                view.recordAction(.Tap, sourceRef: "Coupon-MyMM", sourceType: .Button, targetRef: "Coupon-MyMM", targetType: .View)
                
                let mmMerchant = Merchant.MM()
                cartMerchant.merchantName = mmMerchant.merchantName
                cartMerchant.merchantId = mmMerchant.merchantId
                
                for checkoutMerchantData in merchantDataList {
                    switch checkoutMode {
                    case .cartCheckout:
                        total += checkoutMerchantData.getMerchantTotal(includeShipmentFee: false, includeCoupon: true, selectedSkus: skus, parentOrder: parentOrder, isFlashSale:self.isFlashSale)
                    default:
                        total += checkoutMerchantData.getMerchantTotal(includeShipmentFee: false, includeCoupon: true, qty: qty, parentOrder: parentOrder)
                    }
                }
            }
            else {
                // record action
                view.recordAction(.Tap, sourceRef: "Coupon-Merchant", sourceType: .Button, targetRef: "Coupon-Merchant", targetType: .View)
                
                let checkoutMerchantData = merchantDataList[index]
                cartMerchant.merchantName = checkoutMerchantData.merchant?.merchantName ?? ""
                cartMerchant.merchantImage = checkoutMerchantData.merchant?.headerLogoImage ?? ""
                cartMerchant.merchantId = checkoutMerchantData.merchant?.merchantId ?? 0
                
                switch checkoutMode {
                case .cartCheckout:
                    total += checkoutMerchantData.getMerchantTotal(includeShipmentFee: false, includeCoupon: false, selectedSkus: skus, parentOrder: parentOrder, isFlashSale:self.isFlashSale)
                default:
                    total += checkoutMerchantData.getMerchantTotal(includeShipmentFee: false, includeCoupon: false, qty: qty, parentOrder: parentOrder)
                }
            }

            let couponSelectionVC = MerchantCouponSelectionViewController(couponCheckMerchants: ccmCouponCheckMerchants, couponMap: ccmCouponMap, cartMerchant: cartMerchant, totalAmount: total)
            couponSelectionVC.couponSelectedHandler = { [weak self] (couponDict) -> Void in
                if let strongSelf = self {
                    strongSelf.refreshAllCoupon(couponDict)
                }
            }

            self.navigationController?.isNavigationBarHidden = false
            self.navigationController?.pushViewController(couponSelectionVC, animated: true)
        }
    }

    func actionBeforeChecking(_ completion: @escaping (_ checkValid: Bool) -> Void) {
        var hasError = false
        for merchantData in merchantDataList{
            if let _ = merchantData.merchant{
                if let style = merchantData.styles.first, style.selected {
                    let selectedColor = style.getValidColorAtIndex(style.colorIndexSelected)
                    let selectedSizeId = style.getValidSizeIdAtIndex(style.sizeIndexSelected)
                    
                    if(selectedColor == nil || selectedSizeId == 0 || selectedSizeId == -1){
                        self.showError(String.localize("LB_MC_COLORS_SIZE_TITLE"), animated: true)
                        hasError = true
                        enableAllButton()
                        completion(false)
                        return
                    }
                }
            }
        }

        if (checkoutMode == .cartItem || checkoutMode == .cartCheckout){
            if (address?.userAddressKey.length == 0) {
                showError(String.localize("LB_MC_COLORS_SIZE_TITLE"), animated: true)
                hasError = true
                completion(false)
                return
            }
        }
        
        presenter.checkOutOfStock(usingMMCoupon,flashSale:self.isFlashSale) { (isOutOfStock) in
            if hasError{
                self.enableAllButton()
                completion(false)
                return
            }else{
                if(isOutOfStock){
                    self.enableAllButton()
                    completion(false)
                    return
                }else{
                    completion(true)
                    return
                }
            }
        } 
    }
    
    @objc func actionDismissViewDidTap(_ sender: UIButton?) {
        presenter.dismissView(false)
    }
    
    /// 加入购物车
    @objc func actionAddToCart(_ sender: UIButton) {
        if !self.isNetworkReachable(){
            self.showNetWorkErrorAlert(nil)
            return
        }
        
        disableAllButton()
        confirmButton.formatPrimary()
        checkoutButton.formatPrimary()
        actionBeforeChecking {  (checkValid) in
            if (checkValid){
                self.presenter.checkStock(usingMMCoupon: self.usingMMCoupon, proceedActionIfSuccess: .addToCart)
                self.view.recordAction(.Tap, sourceRef: "AddToCart", sourceType: .Button, targetRef: self.targetRef, targetType: .View)
            }
        }
    }
    
    /// 选择sku的确认按钮响应方法
    @objc func actionCheckout(_ sender: UIButton) {
        if !self.isNetworkReachable(){
            self.showNetWorkErrorAlert(nil)
            return
        }

        disableAllButton()
        actionBeforeChecking {  (checkValid) in
            if (checkValid){
                sender.isUserInteractionEnabled = false
                sender.formatDisable()
                
                let (skuDictArray, _, _) = self.presenter.constructOrdersForChecking()
                print(skuDictArray.debugDescription)

                var passStyles: [Style] = []
                var passSkus: [Sku] = []

                if self.checkoutMode == .multipleMerchant {
                    for style in self.styles{
                        if(style.selected){
                            passStyles.append(style)
                        }
                    }
                }else{
                    passStyles = self.styles
                }
                
                for style in passStyles {
                    for skuDict in skuDictArray {
                        if let skuId = skuDict["SkuId"] as? Int, let qty = skuDict["Qty"] as? Int {
                            let sku = style.findSkuBySkuId(skuId)
                            if (qty == 0){
                                sku?.qty = 1
                            }else{
                                sku?.qty = qty
                            }
                            
                            if let sku = sku{
                                passSkus.append(sku)
                                self.referrerUserKeys[sku.skuId.description] = self.referrerUserKey
                            }
                        }
                    }
                }
                
                
                if (self.checkoutMode != .cartCheckout && self.checkoutMode != .updateStyle){
                    if(self.checkoutMode == .multipleMerchant){
                    
                    }
                    if(self.selectionChecking(passStyles)){
                        
                        var gotoFlashConfirmationPage = false
                        if passStyles.count > 0 && passSkus.count > 0 && self.checkoutMode == .style && self.isFlashSaleEligible {
                            if passSkus[0].isFlashOnSale() {
                                gotoFlashConfirmationPage = true
                            }
                        }
                        
                        //去新人限购订单确认页
                        if gotoFlashConfirmationPage,let styleVC = self.styleViewController {
                            styleVC.gotoFlashBuy(style: passStyles[0], sku: passSkus[0])
                            self.presenter.dismissView(false)//直接隐藏掉
                        } else {
                            self.presenter.goToConfirmationPage(.cartCheckout,
                                                                skus: passSkus,
                                                                styles: passStyles,
                                                                referrerUserKeys: self.referrerUserKeys,
                                                                targetRef: self.targetRef
                            )
                        }
                    }else{
                        self.showError(String.localize("LB_MC_COLORS_SIZE_TITLE"), animated: true)
                    }

                }else{
                    var hasCrossBorderProduct = false
                    for style in passStyles {
                        if (style.isCrossBorder) {
                            hasCrossBorderProduct = true
                        }
                    }
                    
                    if (hasCrossBorderProduct){
                        self.createPendingOrderWithPRC()
                    } else {
                        self.createPendingOrder()
                    }
                }
            }
        }
    }
    
    func createPendingOrderWithPRC() {
        self.presenter.loadUserIDNumberIdentification({ (success, value) in
            if (success) {
                
                //MM-31882 check every single logic
                var isFullyContainsSimplifyChinese = false
                var isMatchReceipantName = false
                
                if let identificationID = value {
                    
                    if let address = self.address, !address.userAddressKey.isEmpty {
                        let addressData = AddressData(address: address)
                        let fullNameID = "\(identificationID.lastName)\(identificationID.firstName)"
                        if addressData.recipientName.isPureChinese {
                            isFullyContainsSimplifyChinese = true
                            
                            if addressData.recipientName == fullNameID {
                                isMatchReceipantName = true
                            }
                        }
                    }
                }
                
                if !isFullyContainsSimplifyChinese {
                    Alert.alertWithSingleButton(self, title: "", message: String.localize("LB_CA_XBORDER_PRC_ID_NAME_CHECK"), buttonString: String.localize("LB_OK"))
                    self.enableAllButton()
                } else if !isMatchReceipantName {
                    Alert.alertWithSingleButton(self, title: "", message: String.localize("LB_CA_XBORDER_NAME_CONSISTENT_MESSAGE"), buttonString: String.localize("LB_OK"))
                    self.enableAllButton()
                } else if isFullyContainsSimplifyChinese && isMatchReceipantName {
                    self.createPendingOrder() //all info is valid go to create pending order
                }
                
            } else {
                Alert.alertWithSingleButton(self, title: "", message: String.localize("LB_CA_XBORDER_ID_NUMBER_MISSING_MESSAGE"), buttonString: String.localize("LB_OK"))
                self.enableAllButton()
            }
        })
    }
    
    func createPendingOrder(){
        self.startPaymentProcess = true
        self.presenter.apiCheckOrder(proceedActionIfSuccess: .checkout, isCart: self.isCart, coupon: self.usingMMCoupon, flashSale:self.isFlashSale, completion: { [weak self] (success, error) in
            if let strongSelf = self{
                strongSelf.enableAllButton()
                if (!success){
                    strongSelf.checkUnpaid()
                }
            }
            })
        
        switch self.checkoutMode {
        case .cartCheckout:
            self.view.recordAction(.Tap, sourceRef: "SubmitOrder", sourceType: .Button, targetRef: "Payment-Alipay", targetType: .View)
        default:
            self.view.recordAction(.Tap, sourceRef: "AddToCart", sourceType: .Button, targetRef: "Payment-Alipay", targetType: .View)
        }
    }
    
    func selectionChecking(_ styles: [Style]?) -> Bool {
        var checkingValid = true
        if let _styles = styles, _styles.count > 0 {
            for style in _styles {
                if style.colorIndexSelected == -1 || style.sizeIndexSelected == -1 {
                    checkingValid = false
                }
            }
        }else{
            checkingValid = false
        }
        return checkingValid
    }
    
    @objc func actionConfirmForCart(_ sender: UIButton) {
        if !self.isNetworkReachable(){
            self.showNetWorkErrorAlert(nil)
            return
        }
        
        disableAllButton()
        presenter.checkStock(usingMMCoupon: usingMMCoupon, proceedActionIfSuccess: .updateCart)
        self.view.recordAction(.Tap, sourceRef: "Confirm", sourceType: .Button, targetRef: "Cart", targetType: .View)
    }
    
    @objc func actionStepperValueChanged(_ sender: UIButton) {
        // Note: These button will not be shown on multiple merchant
        
        if let style = merchantDataList.first?.styles.first {
            let selectedColor = style.getValidColorAtIndex(style.colorIndexSelected)
            let selectedSizeId = style.getValidSizeIdAtIndex(style.sizeIndexSelected)
            
            if(selectedColor == nil || selectedSizeId == 0 || selectedSizeId == -1){
                self.showError(String.localize("LB_MC_COLORS_SIZE_TITLE"), animated: true)
                return
            }
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
                
                //限购不允许对其操作
                if self.isFlashSaleEligible, sku.isFlashOnSale() {
                    qtyValue = 1
                }
                
                self.qty = getValidatedQuantity(qtyValue)
                self.presenter.qty = self.qty
                
                updateOriginalTotal()
                
                if let quantityCell = self.quantityCell {
                    quantityCell.qtyTextField.text = String(self.qty)
                    
                    quantityCell.analyticsViewKey = self.view.analyticsViewKey
                    quantityCell.recordAction(.Input, sourceRef: String(self.qty), sourceType: .Qty, targetRef: sku.skuCode, targetType: .ProductSku)
                    
                    presenter.checkOutOfStock(usingMMCoupon, flashSale:self.isFlashSale, completion: nil)
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
    
    @objc func toggleItem(_ sender: UITapGestureRecognizer) {
        if let tag = sender.view?.tag, let checkoutInfoCell = checkoutInfoCellDict["\(tag)"] {
            checkoutInfoCell.toggleItem()
        } else {
            ErrorLogManager.sharedManager.recordNonFatalError(withException: .IndexOutOfBounds)
        }
    }
    
    // MARK: Analytic
    func initAnalyticLog(){
        initAnalyticsViewRecord(
            nil,
            authorType: nil,
            merchantCode: nil,
            referrerRef: nil,
            referrerType: nil,
            viewDisplayName: self.getViewTitle(),
            viewParameters: nil,
            viewLocation: "OrderConfirmation",
            viewType: "Checkout"
        )
    }
    
    override func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return checkoutSections[section].checkoutItems.count
    }
    
    override func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        let (checkoutSection, checkoutItem, merchantIndex, merchantSectionData) = collectionviewCellInformation(atIndexPath: indexPath)
        
        switch checkoutItem.itemType {
        case .style:
            let cell = collectionView.dequeueReusableCell(withReuseIdentifier: CheckoutInfoCell.CellIdentifier, for: indexPath) as! CheckoutInfoCell
            
            checkoutInfoCellDict["\(self.getCheckoutInfoTag(merchantIndex, styleIndex: checkoutSection.styleIndex))"] = cell
            
            addLeftSelectionForCheckoutInfoCell(cell, merchantIndex: merchantIndex, styleIndex: checkoutSection.styleIndex)
            
            let style: Style = merchantSectionData.styles[checkoutSection.styleIndex]
            cell.setData(withStyle: style, hasCheckbox: true)
            //cell.hideBorder(style.isEmptySizeList() && style.isEmptyColorList()) // TODO:
            
            cell.itemSelectHandler = { [weak self] touchedStyle in
                guard let strongSelf = self else { return }
                strongSelf.updateButtonsState()
                strongSelf.presenter.checkStock(usingMMCoupon: self?.usingMMCoupon)
            }
            
            let sku = style.searchSku(style.selectedSizeId, colorId: style.selectedColorId, skuColor:  style.selectedSkuColor)
            cell.initAnalytics(withViewKey: self.analyticsViewRecord.viewKey, impressionKey: AnalyticsManager.sharedManager.recordImpression(brandCode: "\(style.brandId)", impressionRef: style.styleCode, impressionType: "Product", impressionVariantRef: sku?.skuCode ?? "", impressionDisplayName: style.skuName, merchantCode: style.merchantCode, positionComponent: "ProductListing", positionIndex: indexPath.row, positionLocation: "Cart", viewKey: self.analyticsViewRecord.viewKey))
      
            
            // TODO:
            checkoutInfoCell = cell
            
            return cell
        case .color:
            let cell = collectionView.dequeueReusableCell(withReuseIdentifier: ColorCollectionCell.CellIdentifier, for: indexPath) as! ColorCollectionCell
            
            cell.imageView.image = nil
            cell.topPadding = ColorCellTopPadding
            
            let style: Style = merchantSectionData.styles[checkoutSection.styleIndex]
            let indexPathColor = style.validColorList[indexPath.item]
            let filteredColorImageList = style.colorImageList.filter({ $0.colorKey == indexPathColor.colorKey })
            
            var url: URL?
            
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
       
            
            cell.accessibilityIdentifier = "checkout_color_cell"
            
            return cell
        case .size:
            let cell = collectionView.dequeueReusableCell(withReuseIdentifier: SizeCollectionCell.CellIdentifier, for: indexPath) as! SizeCollectionCell
            let style: Style = merchantSectionData.styles[checkoutSection.styleIndex]
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
       
            cell.accessibilityIdentifier = "checkout_size_cell"
            
            return cell
        case .quantity:
            let cell = collectionView.dequeueReusableCell(withReuseIdentifier: QuantityCell.CellIdentifier, for: indexPath) as! QuantityCell
            
            cell.minusStepButton.addTarget(self, action: #selector(self.actionStepperValueChanged), for: .touchUpInside)
            cell.minusStepButton.accessibilityIdentifier = "checkout_quantity_minus_button"
            
            cell.addStepButton.addTarget(self, action: #selector(self.actionStepperValueChanged), for: .touchUpInside)
            cell.addStepButton.accessibilityIdentifier = "checkout_quantity_add_button"
            
            cell.qtyTextField.text = String(qty)
            cell.qtyTextField.keyboardType = .decimalPad
            cell.qtyTextField.accessibilityIdentifier = "checkout_quantity_textfield"
            
            if cell.qtyTextField.delegate == nil {
                cell.qtyTextField.delegate = self
            }
            
            cell.setSeparatorStyle(isLastCheckoutItem(indexPath) ? .none : .checkout)
            
            quantityCell = cell
            
            return cell
        case .address:
            if LoginManager.getLoginState() == .validUser {
                let cell = collectionView.dequeueReusableCell(withReuseIdentifier: CheckoutCell.CellIdentifier, for: indexPath) as! CheckoutCell
                cell.leftLabel.text = String.localize("LB_CA_EDITITEM_SHIPADDR")
                cell.setStyle(withArrow: true, topSeparator: false, bottomSeparator: true, isFullSeparator: checkoutMode == .cartCheckout)
                cell.setDefaultFont()
                
                if let address = address, address.userAddressKey != "" {
                    let addressData = AddressData(address: address)
                    cell.rightLabel.text = addressData.getFullAddress()
                    cell.rightLabel.textColor = UIColor.secondary2()
                } else {
                    cell.rightLabel.text = String.localize("LB_CA_NEW_SHIPPING_ADDR")
                    cell.rightLabel.textColor = UIColor.secondary1()
                }
                
                cell.rightViewTapHandler = { [weak self] in
                    guard let strongSelf = self else { return }
                    strongSelf.presenter.goToAddressPage(strongSelf.address, mode: .checkoutSwipeToPay, completion: { (address) in
                        strongSelf.address = address
                        strongSelf.presenter.address = address
                        strongSelf.collectionView.reloadItems(at: [indexPath])
                    })
                }
                
                cell.rightLabel.lineBreakMode = .byTruncatingTail
                cell.touchHandler = {}
                return cell
            }
        case .paymentMethod:
            let cell = collectionView.dequeueReusableCell(withReuseIdentifier: CheckoutCell.CellIdentifier, for: indexPath) as! CheckoutCell
            cell.leftLabel.text = String.localize("LB_CA_EDITITEM_PAYMENT_METHOD")
            cell.rightLabel.text = String.localize("LB_CA_PAY_VIA_ALIPAY")
            cell.setStyle(withArrow: false, topSeparator: false, bottomSeparator: true, isFullSeparator: checkoutMode == .cartCheckout)
            cell.rightViewTapHandler = nil
            cell.setDefaultFont() // Must set
            cell.touchHandler = {}
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
                        merchantTotal = merchantSectionData.getMerchantTotal(includeShipmentFee: false, includeCoupon: false, selectedSkus: skus, parentOrder: parentOrder, isFlashSale:self.isFlashSale)
                    default:
                        merchantTotal = merchantSectionData.getMerchantTotal(includeShipmentFee: false, includeCoupon: false, qty: qty, parentOrder: parentOrder)
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
            cell.touchHandler = {}
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
            
            cell.setData(usingMMCoupon)
            
            cell.redDotView.isHidden = !(CacheManager.sharedManager.hasMMCoupon)
            mmCouponIndexPath = indexPath
            cell.layoutSubviews()
            
            return cell
        case .fapiao:
            let cell = collectionView.dequeueReusableCell(withReuseIdentifier: CheckoutCell.CellIdentifier, for: indexPath) as! CheckoutCell
            cell.leftLabel.text = String.localize("LB_FAPIAO")
            cell.setStyle(withArrow: true, topSeparator: false, bottomSeparator: true, isFullSeparator: checkoutMode == .cartCheckout)
            
            var displayFapiaoText = ""
            if (self.merchantDataList[merchantIndex].fapiaoText != String.localize("LB_CA_FAPIAO_NO_NEED")
                && self.merchantDataList[merchantIndex].fapiaoText != String.localize("LB_CA_FAPIAO_INDIVIDUAL")){
                if let fapiaoText = self.merchantDataList[merchantIndex].fapiaoText {
                    let fapiaoCompanyArr = fapiaoText.split{$0 == ";"}.map(String.init)
                    if (fapiaoCompanyArr.count >= 2) {
                        displayFapiaoText = fapiaoCompanyArr[0]
                    }
                }
                
                
                if (self.merchantDataList[merchantIndex].fapiaoText == "" || self.merchantDataList[merchantIndex].fapiaoText == nil || self.merchantDataList[merchantIndex].fapiaoText == " "){
                    self.merchantDataList[merchantIndex].fapiaoText = String.localize("LB_CA_FAPIAO_NO_NEED")
                    displayFapiaoText = String.localize("LB_CA_FAPIAO_NO_NEED")
                }
            }else{
                displayFapiaoText = self.merchantDataList[merchantIndex].fapiaoText ?? ""
            }
            
            cell.rightLabel.text = displayFapiaoText
            cell.setSecondaryFont()
            cell.rightLabel.numberOfLines = 1
            cell.rightLabel.lineBreakMode = .byTruncatingTail
            cell.touchHandler = {
                self.didSelectFapiao(merchantIndex)
            }
            return cell
        case .fullAddress:
            let cell = collectionView.dequeueReusableCell(withReuseIdentifier: CheckoutFullAddressCell.CellIdentifier, for: indexPath) as! CheckoutFullAddressCell
            
            if let address = address, !address.userAddressKey.isEmpty{
                let addressData = AddressData(address: address)
                cell.setContent(withName: addressData.recipientName, address: addressData.getFullAddress(), phoneNumber: addressData.recipientPhoneNumber)
            } else {
                cell.setContent(withName: "", address: String.localize("LB_CA_NEW_SHIPPING_ADDR"), phoneNumber: "")
            }
            
            if self.hasAnyCrossBorderMerchant { //To seperate line with PRC Cell
                cell.showBorder(true)
            } else {
                cell.showBorder(false)
            }
            
            return cell
        case .prc:
            let cell = collectionView.dequeueReusableCell(withReuseIdentifier: PersonalInformationSettingMenuCell.CellIdentifier, for: indexPath) as! PersonalInformationSettingMenuCell
            
            cell.itemLabel.text = String.localize("LB_CA_ID_CARD_VER")
            if userIdentificationNumber.length > 0 {
                cell.valueLabel.text = userIdentificationNumber
            } else {
                cell.valueLabel.text = String.localize("LB_SETTING")
            }
            
            cell.valueImageView.image = nil
            cell.setStyles(.checkout)
            cell.showBorder(false)
            return cell
            
        case .fullPaymentMethod:
            return collectionView.dequeueReusableCell(withReuseIdentifier: CheckoutFullPaymentMethodCell.CellIdentifier, for: indexPath) as! CheckoutFullPaymentMethodCell
        case .fullStyle:
            let cell = collectionView.dequeueReusableCell(withReuseIdentifier: CheckoutProductCell.CellIdentifier, for: indexPath) as! CheckoutProductCell
            cell.isFlashSale = self.isFlashSale
            
             let style: Style = merchantSectionData.styles[checkoutSection.styleIndex]
                
            let tempsku: Sku?
            let selectedColor = style.getValidColorAtIndex(style.colorIndexSelected)
            let selectedSizeId = style.getValidSizeIdAtIndex(style.sizeIndexSelected)
            tempsku = style.searchSku(selectedSizeId, colorId: selectedColor?.colorId, skuColor: selectedColor?.skuColor)
            
            if let sku = tempsku {
                let imageKey = ProductManager.getProductImageKey(style, colorKey: sku.colorKey)
                cell.setProductImage(withImageKey: imageKey)
            } else {
                ErrorLogManager.sharedManager.recordNonFatalError(withException: .NullPointer)
            }
            
            cell.sku = tempsku
            cell.initAnalytics(withViewKey: self.analyticsViewRecord.viewKey, impressionKey: AnalyticsManager.sharedManager.recordImpression(brandCode: "\(style.brandId)", impressionRef: style.styleCode, impressionType: "Product", impressionVariantRef: tempsku?.skuCode ?? "", impressionDisplayName: style.skuName, merchantCode: style.merchantCode, positionComponent: "ProductListing", positionIndex: indexPath.row + 1, positionLocation: "OrderConfirmation", viewKey: self.analyticsViewRecord.viewKey))

            return cell
        case .merchantTotal:
            let cell = collectionView.dequeueReusableCell(withReuseIdentifier: CheckoutCell.CellIdentifier, for: indexPath) as! CheckoutCell
            cell.leftLabel.text = String.localize("LB_CA_MERCHANT_TOTAL")
            
            var formatPriceText: String? = nil
            
            if let merchant = merchantSectionData.merchant {
                var merchantTotal = merchantSectionData.getMerchantTotal(includeShipmentFee: true, includeCoupon: true, selectedSkus: skus, parentOrder: parentOrder, isFlashSale: self.isFlashSale)
                for coupon in usingMerchantCoupons{
                    if merchant.merchantId == coupon.merchantId ?? -1 {
                        merchantTotal -= coupon.couponAmount
                    }
                }
                formatPriceText = merchantTotal.formatPrice()
            }
            
            DispatchQueue.main.async {
                cell.rightLabel.text = formatPriceText ?? ""
            }
            
            
            cell.setPriceFont()
            cell.setStyle(withArrow: false, topSeparator: false, bottomSeparator: true, isFullSeparator: checkoutMode == .cartCheckout)
            cell.rightViewTapHandler = nil
            cell.touchHandler = {}
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
                        if comment.isEmptyOrNil() || comment.trimmingCharacters(in: CharacterSet.whitespacesAndNewlines).length <= 0 {
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
                        if comment.isEmptyOrNil() || comment.trimmingCharacters(in: CharacterSet.whitespacesAndNewlines).length <= 0 {
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
    
}

// MARK: - Collection View data source methods ////////////////////////////////
extension FCheckoutViewController{
    func numberOfSections(in collectionView: UICollectionView) -> Int {
        return checkoutSections.count
    }

    func collectionView(_ collectionView: UICollectionView, viewForSupplementaryElementOfKind kind: String, at indexPath: IndexPath) -> UICollectionReusableView {
        let (checkoutSection, checkoutItem, merchantIndex, merchantSectionData) = collectionviewCellInformation(atIndexPath: indexPath)
        
        if kind == UICollectionElementKindSectionHeader {
            switch checkoutItem.itemType {
            case .style, .fullStyle:
                let couponInputHeaderView = collectionView.dequeueReusableSupplementaryView(ofKind: kind, withReuseIdentifier: CouponInputHeaderView.ViewIdentifier, for: indexPath) as! CouponInputHeaderView
                if (checkoutMode == .style || checkoutMode == .multipleMerchant || checkoutMode == .updateStyle){
                    if (indexPath.section > 0){
                        couponInputHeaderView.isFirst = false
                    }else{
                        couponInputHeaderView.isFirst = true
                    }
                }else{
                    couponInputHeaderView.isFirst = true
                }
                
                
                couponInputHeaderView.imageStyle = (checkoutMode == .cartCheckout) ? .long : .square
                couponInputHeaderView.setMerchantModel(merchantSectionData.merchant)
                
                if checkoutMode == .cartCheckout {
                    couponInputHeaderView.couponButtonView.isHidden = true
                }
                else {
                    couponInputHeaderView.couponButtonView.isHidden = false
                    
                    couponInputHeaderView.viewCouponHandler = { [weak self] in
                        if let strongSelf = self {
                            if let merchantId = merchantSectionData.merchant?.merchantId {
                                Navigator.shared.dopen(Navigator.mymm.website_coupon_center + "\(merchantId)")
                                // record action
                                strongSelf.view.recordAction(.Tap, sourceRef: "SwipeToBuy-MerchantCouponClaimList", sourceType: .Button, targetRef: "MerchantCouponClaimList", targetType: .View)
                            }
                        }
                    }
                }
                
                return couponInputHeaderView
            case .color:
                let sizeHeaderView = collectionView.dequeueReusableSupplementaryView(ofKind: kind, withReuseIdentifier: SizeHeaderView.ViewIdentifier, for: indexPath) as! SizeHeaderView
                //                sizeHeaderView.topPadding = SizeHeaderViewTopPadding
                
                let style: Style = merchantSectionData.styles[checkoutSection.styleIndex]
                sizeHeaderView.hideSizeInformation(!style.haveSizeGrid())
                sizeHeaderView.leftMargin = 14
                sizeHeaderView.rightMargin = 4
                sizeHeaderView.colorName = ""
                
                if style.colorIndexSelected >= 0 && style.colorIndexSelected < style.validColorList.count {
                    let color = style.validColorList[style.colorIndexSelected]
                    sizeHeaderView.colorName = color.skuColor
                }
                sizeHeaderView.hideSideReference()
          
                
                return sizeHeaderView

            case .size:
                let sizeHeaderView = collectionView.dequeueReusableSupplementaryView(ofKind: kind, withReuseIdentifier: SizeHeaderView.ViewIdentifier, for: indexPath) as! SizeHeaderView
//                sizeHeaderView.topPadding = SizeHeaderViewTopPadding
                
                let style: Style = merchantSectionData.styles[checkoutSection.styleIndex]
                sizeHeaderView.hideSizeInformation(!style.haveSizeGrid())
                //sizeHeaderView.leftMargin = (checkoutMode == .MultipleMerchant) ? FCheckoutViewController.MultipleMerchantSizeEdgeInsets.left : FCheckoutViewController.NormalSizeEdgeInsets.left
                //sizeHeaderView.rightMargin = FCheckoutViewController.NormalSizeEdgeInsets.left
                sizeHeaderView.leftMargin = 14
                sizeHeaderView.rightMargin = 4
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
                sizeHeaderView.showSideReference()
          
                
                return sizeHeaderView
            default:
                break
            }
        } else if kind == UICollectionElementKindSectionFooter {
            switch checkoutSection.sectionType {
            case .color, .size:
                let footerView = collectionView.dequeueReusableSupplementaryView(ofKind: kind, withReuseIdentifier: CheckoutFooterView.ViewIdentifier, for: indexPath) as! CheckoutFooterView
                
                footerView.setSeparatorStyle(checkoutMode == .multipleMerchant ? .multipleItem : .singleItem)
//                footerView.separatorView.isHidden = true
                
                switch checkoutSection.sectionType {
                case .color:
                    checkoutColorFooterViewFrameDict["\(self.getCheckoutInfoTag(merchantIndex, styleIndex: checkoutSection.styleIndex))"] = footerView.frame
                case .size:
                    checkoutSizeFooterViewFrameDict["\(self.getCheckoutInfoTag(merchantIndex, styleIndex: checkoutSection.styleIndex))"] = footerView.frame
                default:
                    break
                }
                
                addLeftSelectionForCheckoutInfoCell(checkoutInfoCellDict["\(self.getCheckoutInfoTag(merchantIndex, styleIndex: checkoutSection.styleIndex))"], merchantIndex: merchantIndex, styleIndex: checkoutSection.styleIndex)
                
                return footerView
            case .otherInformation:
                if indexPath.section == 0 {
                    if self.hasAnyCrossBorderMerchant {
                        let footerView = collectionView.dequeueReusableSupplementaryView(ofKind: kind, withReuseIdentifier: CrossBorderWarningView.ViewIdentifier, for: indexPath) as! CrossBorderWarningView
                        return footerView
                    } else {
                        let footerView = collectionView.dequeueReusableSupplementaryView(ofKind: kind, withReuseIdentifier: SeparatorHeaderView.ViewIdentifier, for: indexPath) as! SeparatorHeaderView
                    
                        footerView.separatorView.isHidden = true
                        footerView.backgroundColor = UIColor.backgroundGray()
                        footerView.titleLabel.isHidden = true
                        
                        return footerView
                    }
                }
            case .otherMerchantInformation, .mmCoupon:
                let footerView = collectionView.dequeueReusableSupplementaryView(ofKind: kind, withReuseIdentifier: SeparatorHeaderView.ViewIdentifier, for: indexPath) as! SeparatorHeaderView
                
                footerView.titleLabel.isHidden = true
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
        let (checkoutSection, checkoutItem, _, merchantSectionData) = collectionviewCellInformation(atIndexPath: indexPath)
        
        switch checkoutItem.itemType {
        case .style:
            return CGSize(width: view.width, height: StyleCellHeight)
        case .color:
            return CGSize(width: ColorCellDimension, height: ColorCellDimension + (ColorCellTopPadding * 2))
        case .size:
            let style: Style = merchantSectionData.styles[checkoutSection.styleIndex]
            if indexPath.item < style.validSizeList.count {
                let size = style.validSizeList[indexPath.item]
                return CGSize(width: SizeCollectionCell.getWidth(size.sizeName), height: SizeCollectionCell.DefaultHeight)
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
        case .quantity:
            return CGSize(width: view.width, height: 60)
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
        case .color, .size:
            if checkoutMode == .multipleMerchant {
                return FCheckoutViewController.MultipleMerchantSizeEdgeInsets
            } else {
                return FCheckoutViewController.NormalSizeEdgeInsets
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
        case .style:
            return 20
        case .color:
            return 15
        case .size:
            return FCheckoutViewController.SizeMinimumInteritemSpacing
        default:
            break
        }
        
        return 0
    }
    
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, referenceSizeForHeaderInSection section: Int) -> CGSize {
        let checkoutSection = checkoutSections[section]
        
        switch checkoutSection.sectionType {
        case .style, .fullStyle:
            if section == 0 {
                return CGSize(width: view.width, height: 50)
            }else{
                if (checkoutMode == .style || checkoutMode == .multipleMerchant || checkoutMode == .updateStyle){
                    if (checkoutMode == .multipleMerchant){
                        if checkoutSection.styleIndex == 0 {
                            return CGSize(width: view.width, height: 50)
                        }else{
                            return CGSize(width: view.width, height: 0)
                        }
                    }
                    return CGSize(width: view.width, height: 65)
                }else{
                    if checkoutSection.styleIndex == 0 {
                        return CGSize(width: view.width, height: 50)
                    }
                }
            }
        case .size:
            return CGSize(width: view.width, height: SizeHeaderViewHeight + (15 * 2))
        case .color:
            return CGSize(width: view.width, height: SizeHeaderViewHeight + (18))
        default:
            break
        }
        
        return CGSize.zero
    }
    
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, referenceSizeForFooterInSection section: Int) -> CGSize {
        let checkoutSection = checkoutSections[section]
        
        switch checkoutSection.sectionType {
        case .color:
            return CGSize(width: view.width, height: 1)
        case .size:
            return CGSize(width: view.width, height: 1)
        case .otherInformation:
            if section == 0 && !isLastCheckoutSection(section) {
                if self.hasAnyCrossBorderMerchant {
                    return CGSize(width: view.width, height: 54)
                } else {
                    return CGSize(width: view.width, height: 10)
                }
            }
        case .mmCoupon:
            return CGSize(width: view.width, height: 10)
        case .otherMerchantInformation:
            return CGSize(width: view.width, height: 10)
        default:
            break
        }
        
        return CGSize.zero
    }
    
    private func updateQuantityButtons(sku:Sku? = nil) {
        if let sku = sku, self.isFlashSaleEligible, sku.isFlashOnSale() {
            sku.qty = 1
            self.qty = 1
            self.presenter.qty = 1
            if let cell = self.quantityCell {
                cell.minusStepButton.isUserInteractionEnabled = false
                cell.minusStepButton.isEnabled = false
                cell.addStepButton.isUserInteractionEnabled = false
                cell.addStepButton.isEnabled = false
                cell.qtyTextField.isUserInteractionEnabled = false
                cell.qtyTextField.text = String(sku.qty)
            }
        } else {
            if let cell = self.quantityCell {
                cell.minusStepButton.isUserInteractionEnabled = true
                cell.minusStepButton.isEnabled = true
                cell.addStepButton.isUserInteractionEnabled = true
                cell.addStepButton.isEnabled = true
                cell.qtyTextField.isUserInteractionEnabled = true
            }
        }
    }
    
    
    // MARK: - Collection View delegate methods ////////////////////////////////////////////////
    func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        let (checkoutSection, checkoutItem, merchantIndex, merchantSectionData) = collectionviewCellInformation(atIndexPath: indexPath)
        
        switch checkoutItem.itemType {
        case .style:
           let style: Style = merchantSectionData.styles[checkoutSection.styleIndex]
                showProductDetailView(withStyle: style)
                
                if let cell = collectionView.cellForItem(at: indexPath) as? CheckoutInfoCell {
                    cell.recordAction(.Tap, sourceRef: style.styleCode, sourceType: .Product, targetRef: "PDP", targetType: .View)
                } else {
                    ErrorLogManager.sharedManager.recordNonFatalError(withException: .NullPointerOrTypeMismatch)
                }
        
        case .color:
            let style: Style = merchantSectionData.styles[checkoutSection.styleIndex]
                if style.validColorList[indexPath.item].isValid {
                    if style.colorIndexSelected == indexPath.item {
                        style.colorIndexSelected = -1
                        
                        //Fix always display highligh for size out of stock when deselect color
                        if style.sizeIndexSelected != -1 {
                            let sizeId = style.getValidSizeIdAtIndex(style.sizeIndexSelected)
                            if sizeId != -1 {
                                let sku = style.searchSkuIdAndColorKey(sizeId, colorKey: "")
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
                    
                    //不允许加加减减
                    let selectedSku = self.presenter.getSelectSku()
                    updateQuantityButtons(sku: selectedSku)
                    var currentFlashSale = false
                    if let sku = selectedSku,self.isFlashSaleEligible,sku.isFlashOnSale() {
                        currentFlashSale = true
                    }
                    
                    presenter.checkOutOfStock(usingMMCoupon, flashSale:(self.isFlashSale || currentFlashSale), completion: { (isOutOfStock) in
                        if(isOutOfStock){
                            self.disableAllButton()
                        }else{
                            self.enableAllButton()
                        }
                    })
                    
                    // To reload the price base on color selected
                    if let checkoutInfoCell = checkoutInfoCell{
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
            
        case .size:
            let style: Style = merchantSectionData.styles[checkoutSection.styleIndex]
            if  style.validSizeList[indexPath.item].isValid {
                if style.sizeIndexSelected == indexPath.item {
                    style.sizeIndexSelected = -1
                } else {
                    style.sizeIndexSelected = indexPath.item
                }
                
                //不允许加加减减
                let selectedSku = self.presenter.getSelectSku()
                updateQuantityButtons(sku: selectedSku)
                var currentFlashSale = false
                if let sku = selectedSku,self.isFlashSaleEligible,sku.isFlashOnSale() {
                    currentFlashSale = true
                }
      
                presenter.checkOutOfStock(usingMMCoupon, flashSale:(self.isFlashSale || currentFlashSale), completion: { (isOutOfStock) in
                    if(isOutOfStock){
                        self.disableAllButton()
                    }else{
                        self.enableAllButton()
                    }
                })
                
                
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
            self.didSelectCouponView(isMMCoupon: false, atIndex: merchantIndex)
        case .mmCoupon:
            self.didSelectCouponView(isMMCoupon: true)
        case .fullAddress:
            self.didSelectAddressView()
        case .prc:
            self.didSelectPRCView()
        case .fapiao:
            self.didSelectFapiao(merchantIndex)
        default:
            break
        }
    }

}



// MARK: - Text Field delegate methods ////////////////////////////////////////////////
extension FCheckoutViewController: UITextFieldDelegate{
    func textFieldDidEndEditing(_ textField: UITextField) {
        if let quantityCell = self.quantityCell, textField == quantityCell.qtyTextField {
            if let textInput = textField.text {
                if !textInput.isEmpty {
                    if let quantityUpdated = Int(textInput) {
                        self.qty = getValidatedQuantity(quantityUpdated)
                        self.presenter.qty = self.qty
                    } else {
                        ErrorLogManager.sharedManager.recordNonFatalError(withException: .TypeMismatch)
                    }
                }
            }
            
            textField.text = String(self.qty)
            presenter.checkStock(usingMMCoupon: self.usingMMCoupon)
            
            if self.checkoutMode == .updateStyle || self.checkoutMode == .style || self.checkoutMode == .cartItem {
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
                    let prospectiveText = (currentText as NSString).replacingCharacters(in: range, with: string)
                    
                    if prospectiveText.count == 1 {
                        let zeroString = "0"
                        let isEqualToZeroString = (string == zeroString)
                        
                        if isEqualToZeroString {
                            textField.text = "1"
                            self.qty = getValidatedQuantity(1)
                            self.presenter.qty = self.qty
                            return false
                        }
                    }
                    
                    if prospectiveText.isNumberic() && prospectiveText != "" {
                        if let quantityInput = Int(prospectiveText) {
                            self.qty = getValidatedQuantity(quantityInput)
                            self.presenter.qty = self.qty
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
                
                presenter.checkStock(usingMMCoupon: self.usingMMCoupon)
            } else {
                ErrorLogManager.sharedManager.recordNonFatalError(withException: .DataIsEmpty)
            }
        }
        
        return true
    }
}

// MARK: - Helper ////////////////////////////////
extension FCheckoutViewController {
    private func getMerchantCodeList(_ styles: [Style]?) -> [Int] {
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
    
    private func collectionviewCellInformation(atIndexPath indexPath: IndexPath) -> (checkoutSection: CheckoutSection, checkoutItem: CheckoutItem, merchantIndex: Int, merchantSectionData: CheckoutMerchantData) {
        let checkoutSection = checkoutSections[indexPath.section]
        let checkoutItem = checkoutSection.checkoutItems[indexPath.item]
        let merchantIndex = (checkoutMode == .cartCheckout) ? checkoutSection.merchantDataIndex + 1 : checkoutSection.merchantDataIndex
        let merchantSectionData = merchantDataList[merchantIndex]
        
        return (checkoutSection, checkoutItem, merchantIndex, merchantSectionData)
    }
    
    private func isLastCheckoutItem(_ indexPath: IndexPath) -> Bool{
        let checkoutSection = checkoutSections[indexPath.section]
        return indexPath.row == checkoutSection.checkoutItems.count - 1
    }
    
    private func isLastCheckoutSection(_ section: Int) -> Bool{
        return section == checkoutSections.count - 1
    }
    
    func showAddToCartAnimation() {
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
                        itemStartPos: footerView.convert(checkoutButton.center, to: view),
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
    
    private func getValidatedQuantity(_ quantity: Int) -> Int {
        return (quantity > MaximumQuantity) ? MaximumQuantity : (quantity < 0) ? 1 : quantity
    }
    
    private func getNumberOfCheckoutItems() -> Int{
        var count = 0
        for checkoutSection in checkoutSections{
            count =  count + checkoutSection.checkoutItems.count
        }
        
        return count
    }
    
    private func getCheckoutInfoTag(_ merchantIndex: Int, styleIndex: Int) -> Int{
        let count = self.getNumberOfCheckoutItems()
        return merchantIndex*count + styleIndex
    }
    
    private func addLeftSelectionForCheckoutInfoCell(_ checkoutInfoCell: CheckoutInfoCell?, merchantIndex: Int, styleIndex: Int) {
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
        
        let singleTap = UITapGestureRecognizer(target: self, action: #selector(toggleItem))
        
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
    
    @discardableResult
    private func preselectSize(_ style: Style, selectedSizeId: Int?) -> Bool{
        if let firstSize = style.validSizeList.first, style.validSizeList.count == 1{
            style.sizeIndexSelected = 0
            style.selectedSizeId = firstSize.sizeId
        }
        else{
            guard let selectedSizeId = selectedSizeId else{
                return false
            }
            
            for (index, size) in style.validSizeList.enumerated() {
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
    
    @discardableResult
    private func preselectColor(_ style: Style, selectedColorId: Int?, selectedSkuColor: String?) -> Bool{
        guard let selectedColorId = selectedColorId, let selectedSkuColor = selectedSkuColor, !selectedSkuColor.isEmpty else{
            if let noColor = style.validColorList.first, (style.validColorList.count == 1){
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
    
    internal func preselectColorSize(_ style: Style, selectedSizeId: Int?, selectedSkuColor: String?, selectedColorId: Int?){
        style.sizeIndexSelected = -1
        style.colorIndexSelected = -1
        
        self.preselectSize(style, selectedSizeId: selectedSizeId)
        self.preselectColor(style, selectedColorId: selectedColorId, selectedSkuColor: selectedSkuColor)
    }

}


