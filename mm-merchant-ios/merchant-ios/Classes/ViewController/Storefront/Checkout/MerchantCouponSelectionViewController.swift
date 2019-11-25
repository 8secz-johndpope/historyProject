//
//  MerchantCouponSelectionViewController.swift
//  merchant-ios
//
//  Created by Phan Manh Hung on 2/7/17.
//  Copyright © 2017 WWE & CO. All rights reserved.
//

import Foundation
import PromiseKit

class MerchantCouponSelectionViewController: MmViewController {
    static let UNBUNDLE_ERROR_CODE = 927
    var tableView: UITableView!
    var btnConfirm: UIButton!
    
    private static let MerchantCouponHeaderViewIdentifier = "MerchantCouponHeaderView"
    private static let MerchantCouponSelectionViewCellIdentifier = "MerchantCouponSelectionCell"
    private static let MerchantCouponInputCellIdentifier = "MerchantCouponInputCell"
    private static let MerchantCouponDeselectCellIdentifier = "MerchantCouponDeselectCell"
    private static let LoadingCellIdentifier = "LoadingCell"
    
    private let HeaderHeight = CGFloat(50)
    
    private var lastY = CGFloat(0)
    private var coupons = [Coupon]()
    private var previousSelectedCoupon: Coupon?
    private var selectedClaimedCoupon: Coupon?
    private var previousSelectedCell: CouponSelectionCell?
    private var currentImpressionKey: String?
    private var isKeyboardShowing = false
    
    
    
    var inputCell: MerchantCouponInputCell?
    var noSelectCouponCell: MerchantCouponDeselectCell?
    
    var couponSelectedHandler: ((_ couponMap: [Int: Coupon]?) -> ())?
    
    private var data: CartMerchant?
    private var couponCheckMerchants: [CouponCheckMerchant]?
    private var couponMap: [Int: Coupon]? {
        didSet {
            if let merchantId = self.data?.merchantId, let couponMap = self.couponMap, let selectedCoupon = couponMap[merchantId] {
                self.defaultCoupon = selectedCoupon
            }
        }
    }
    private var totalAmount: Double = 0
    
    private var isMMCoupon = true
    private var inputCoupon: Coupon?
    private var defaultCoupon: Coupon? //for pre-select, should check from couponMap
    
    convenience init(couponCheckMerchants: [CouponCheckMerchant]?/* must include MM */, couponMap: [Int: Coupon]?, cartMerchant: CartMerchant?, totalAmount: Double = 0) {
        self.init(nibName: nil, bundle: nil)
        self.data = cartMerchant
        self.couponCheckMerchants = couponCheckMerchants
        self.setCouponMap(couponMap)
        self.totalAmount = totalAmount
    }
    
    //setter
    func setCouponMap(_ cpMap: [Int: Coupon]?) {
        self.couponMap = cpMap
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        if let merchantId = data?.merchantId, merchantId != Constants.MMMerchantId {
            isMMCoupon = false
        }
        
        if !isMMCoupon {
            self.title = String.localize("LB_COUPON_MERC_SELECT")
        } else {
            self.title = String.localize("LB_COUPON_MYMM_SELECT")
        }
        
        createBackButton(.grayColor)
        setupView()
        
        tableView.backgroundColor = UIColor.primary2()
        tableView.register(
            UINib(nibName: MerchantCouponSelectionViewController.MerchantCouponSelectionViewCellIdentifier, bundle: nil),
            forCellReuseIdentifier: MerchantCouponSelectionViewController.MerchantCouponSelectionViewCellIdentifier
        )
        tableView.register(
            UINib(nibName: MerchantCouponSelectionViewController.MerchantCouponInputCellIdentifier, bundle: nil),
            forCellReuseIdentifier: MerchantCouponSelectionViewController.MerchantCouponInputCellIdentifier
        )
        tableView.register(
            UINib(nibName: MerchantCouponSelectionViewController.MerchantCouponDeselectCellIdentifier, bundle: nil),
            forCellReuseIdentifier: MerchantCouponSelectionViewController.MerchantCouponDeselectCellIdentifier
        )
        tableView.register(
            LoadingTableViewCell.self,
            forCellReuseIdentifier: MerchantCouponSelectionViewController.LoadingCellIdentifier
        )
        tableView.register(
            UINib(nibName: MerchantCouponSelectionViewController.MerchantCouponHeaderViewIdentifier, bundle: nil),
            forCellReuseIdentifier: MerchantCouponSelectionViewController.MerchantCouponHeaderViewIdentifier
        )
        
        initAnalyticLog()
        
        NotificationCenter.default.addObserver(self, selector: #selector(keyboardWillShowNotification), name: NSNotification.Name.UIKeyboardWillShow, object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(keyboardWillHideNotification), name: NSNotification.Name.UIKeyboardWillHide, object: nil)
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        loadCoupons()
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        
        if let merchant = data {
            recordImpression(impressionRef: "\(merchant.merchantId)", impressionType: "Merchant", impressionDisplayName: merchant.merchantName, merchantCode: "\(merchant.merchantId)", positionComponent: merchant.merchantName, positionLocation: "Coupon-Merchant")
        }
    }
    
    func setupView() {
        let BottomViewHeight = CGFloat(67)
        var frame = view.frame
        var navigationBarMaxY = CGFloat(0)
        if let navigationController = self.navigationController, !navigationController.isNavigationBarHidden {
            navigationBarMaxY = navigationController.navigationBar.frame.maxY
        }
        frame.origin.y = navigationBarMaxY
        frame.size.height -= navigationBarMaxY + BottomViewHeight + ScreenBottom
        
        tableView = UITableView(frame: frame)
        tableView.delegate = self
        tableView.dataSource = self
        tableView.separatorStyle = .none
        view.addSubview(tableView)
        
        let bottomView = UIView(frame: CGRect(x: 0, y: tableView.frame.maxY, width: frame.width, height: BottomViewHeight))
        bottomView.backgroundColor = UIColor.white
        view.addSubview(bottomView)
        
        let MarginLeft = CGFloat(10)
        let MarginTop = CGFloat(13)
        btnConfirm = UIButton(type: .custom)
        btnConfirm.frame = CGRect(x: MarginLeft, y: MarginTop, width: bottomView.width - MarginLeft * 2, height: bottomView.height - MarginTop * 2)
        btnConfirm.setTitle(String.localize("LB_CONFIRM"), for: UIControlState())
        btnConfirm.setTitle(String.localize("LB_CONFIRM"), for: .highlighted)
        btnConfirm.layer.cornerRadius = Constants.Button.Radius
        btnConfirm.addTarget(self, action: #selector(buttonConfirmTapped), for: .touchUpInside)
        setButtonConfirmActive(false)
        bottomView.addSubview(btnConfirm)
    }
    
    override func shouldHaveCollectionView() -> Bool {
        return false
    }

    @objc func buttonConfirmTapped(_ button: UIButton) {
        var selectedCoupon: Coupon?
        
        if previousSelectedCell is MerchantCouponInputCell {
            // input coupon
            if let inputCoupon = inputCoupon {
                // record action
                button.initAnalytics(withViewKey: analyticsViewRecord.viewKey, impressionKey: currentImpressionKey)
                button.recordAction(.Tap, sourceRef: "SelectToInputMerchantCouponCode", sourceType: .Button, targetRef: inputCoupon.couponReference, targetType: .Coupon)
                
                selectedCoupon = inputCoupon
                
            }
        }
        else if previousSelectedCell is MerchantCouponDeselectCell {
            // remove coupon
            // record action
            button.initAnalytics(withViewKey: analyticsViewRecord.viewKey, impressionKey: currentImpressionKey)
            button.recordAction(.Tap, sourceRef: "SelectToNoCoupon", sourceType: .Button, targetType: .Coupon)
            
            selectedCoupon = nil
        }
        else if let coupon = previousSelectedCoupon {
            // record action
            button.initAnalytics(withViewKey: analyticsViewRecord.viewKey, impressionKey: currentImpressionKey)
            button.recordAction(.Tap, sourceRef: "SelectToApplyInPurchase", sourceType: .Button, targetRef: coupon.couponReference, targetType: .Coupon)
            
            selectedCoupon = coupon
        }
        
        if var couponMap = self.couponMap, let merchantId = data?.merchantId {
            couponMap[merchantId] = selectedCoupon
            
            if let selectedMMCoupon = couponMap[Constants.MMMerchantId], let merchants = couponCheckMerchants,
                merchantId != Constants.MMMerchantId &&
                !CouponManager.shareManager().eligible(forMMCoupon: selectedMMCoupon, merchants: merchants, selectedCoupons: couponMap) {
                couponMap[Constants.MMMerchantId] = nil
            }
  
            couponSelectedHandler?(couponMap)
            navigationController?.popViewController(animated: true)
        }
    }
    
    func setButtonConfirmActive(_ active: Bool) {
        if active {
            btnConfirm.backgroundColor = UIColor.redDoneButton()
            btnConfirm.isUserInteractionEnabled = true
        }
        else {
            btnConfirm.backgroundColor = UIColor.lightGray
            btnConfirm.isUserInteractionEnabled = false
        }
    }
    
    func loadCoupons() {
        
        self.showLoadingInScreenCenter()
        
        var merchantId = CouponMerchant.mm.rawValue
        
        if !isMMCoupon {
            if let mid = data?.merchantId {
                merchantId = mid
            } else {
                // missing merchant id so skip to make request
                self.stopLoading()
                return
            }
        }
        
        CouponManager.shareManager().invalidate(wallet: merchantId)
        
        firstly {
            return CouponManager.shareManager().wallet(forMerchantId: merchantId)
            }.then { _, coupons -> Void in
                if let coupons = coupons {
                    self.coupons = coupons.filter { !$0.isExpired && CacheManager.sharedManager.isActiveMerchant($0.merchantId) && $0.isRedeemable }.map { coupon in
                        coupon.isExpanded = false
                        coupon.selected = false
                        return coupon
                    }
                    
                    for coupon in self.coupons {
                        if coupon.isSegmented == 1, let remark = CouponManager.shareManager().getCouponRemarkWith(coupon.segmentMerchantId, brandId: coupon.segmentBrandId, categoryId: coupon.segmentCategoryId) {
                            coupon.couponRemark = remark
                        }
                    }
                    
                    let noCouponSelection = {
                        if let noSelectCell = self.noSelectCouponCell {
                            noSelectCell.btnCheckBox.isSelected = true
                            self.previousSelectedCell = noSelectCell
                        }
                    }
                    
                    var shouldSelectCoupon: Coupon?
                    if let selectedClaimedCoupon = self.selectedClaimedCoupon {
                        shouldSelectCoupon = selectedClaimedCoupon
                    } else if let defaultCoupon = self.defaultCoupon {
                        shouldSelectCoupon = defaultCoupon
                    }
                    
                    if let defaultCoupon = shouldSelectCoupon {
                        var isFoundCoupon = false
                        for (index, coupon) in self.coupons.enumerated() {
                            if coupon.couponReference == defaultCoupon.couponReference, !coupon.isPending {
                                coupon.selected = true
                                self.previousSelectedCoupon = coupon
                                isFoundCoupon = true
                                self.setButtonConfirmActive(true)
                                
                                let indexPath = IndexPath(row: index + 3, section: 0)
                                if let cell = self.tableView.cellForRow(at: indexPath) {
                                    self.currentImpressionKey = cell.analyticsImpressionKey
                                }
                                
                                self.inputCoupon = nil
                                if let inputCell = self.inputCell {
                                    inputCell.tfCoupon.text = ""
                                    inputCell.setCouponInfo(nil)
                                    inputCell.btnCheckBox.isSelected = false
                                    inputCell.btnCheckBox.isUserInteractionEnabled = false
                                }
                                
                                break
                            }
                        }
                        
                        if !isFoundCoupon {
                            noCouponSelection()
                        }
                    } else {
                        noCouponSelection()
                    }
                }
                
                self.tableView.reloadData()
            }.always {
                self.stopLoading()
        }
    }
    
    func checkCoupon(_ code: String) {
        
        let couponCode = code.trimmingCharacters(in: CharacterSet.whitespacesAndNewlines).lowercased() 
        if couponCode.length < 1 {
            if isMMCoupon {
                self.showError(String.localize("LB_CA_CHECKOUT_MYMM_COUPON_CODE"), animated: true)
            }
            else {
                self.showError(String.localize("LB_CA_CHECKOUT_MERC_COUPON_CODE"), animated: true)
            }
            return
        }
        
        showLoading()
        
        let disableInput = {
            self.inputCell?.btnCheckBox.isUserInteractionEnabled = false
            if self.previousSelectedCell == self.inputCell {
                self.previousSelectedCell?.btnCheckBox.isSelected = false
                self.previousSelectedCell = nil
                
                if let selectedCoupon = self.previousSelectedCoupon {
                    selectedCoupon.selected = false
                }
                self.previousSelectedCoupon = nil
                
                self.inputCell?.setCouponInfo(nil)
                self.setButtonConfirmActive(false)
            }
        }
        
        firstly {
            return checkCouponService(couponCode)
            }.then { _ -> Void in
                if self.isValid(self.inputCoupon) {
                    self.showSuccessPopupWithText(String.localize("LB_CA_VALID_COUPON"))
                    self.inputCell?.btnCheckBox.isUserInteractionEnabled = true
                    self.inputCell?.btnCheckBox.isSelected = true
                    
                    if let selectedCoupon = self.previousSelectedCoupon {
                        selectedCoupon.selected = false
                    }
                    
                    self.previousSelectedCoupon = nil
                    
                    if self.previousSelectedCell != self.inputCell {
                        self.previousSelectedCell?.btnCheckBox.isSelected = false
                        self.previousSelectedCell = self.inputCell
                    }
                    
                    self.setButtonConfirmActive(true)
                    self.inputCell?.setCouponInfo(self.inputCoupon)
                }
                else {
                    disableInput()
                }
            }.always {
                self.stopLoading()
            }.catch { (error) -> Void in
                Log.error(error)
                disableInput()
                let error = error as NSError
                if error.code == MerchantCouponSelectionViewController.UNBUNDLE_ERROR_CODE { /* block duplicated error prompt*/
                    return
                }
                self.showError(String.localize("MSG_ERR_CA_COUPON_CODE_VALID"), animated: true)
        }
    }
    
    //Show dialog when invalid coupon
    func isValid(_ coupon: Coupon?) -> Bool {
        var isValid = true
        
        if let coupon = coupon {
            var errorMessage = ""
            
            if let cartMerchant = self.data {
                //This coupon doesn't belong to current merchant
                if coupon.merchantId != cartMerchant.merchantId {
                    errorMessage = String.localize("MSG_ERR_CA_COUPON_CODE_VALID")
                    isValid = false
                }
            } else {
                ErrorLogManager.sharedManager.recordNonFatalError(withException: .NullPointer)
            }
            
            if isValid {
                if let startDate = coupon.availableFrom, Date() < startDate as Date {
                    errorMessage = String.localize("LB_CA_COUPON_YET_AVAIL")
                    isValid = false
                } else if coupon.isExpired {
                    errorMessage = String.localize("MSG_ERR_CA_COUPON_CODE_EXPIRED")
                    isValid = false
                } else if !coupon.isAvailable {
                    errorMessage = String.localize("MSG_ERR_INVALID_COUPON")
                    isValid = false
                } else if !coupon.isRedeemable {
                    errorMessage = String.localize("MSG_ERR_CA_COUPON_CODE_EXCEED_LIMIT")
                    isValid = false
                } else if coupon.minimumSpendAmount > self.totalAmount  {
                    errorMessage = String.localize("MSG_ERR_CA_COUPON_CODE_MIN").replacingOccurrences(of: "{0}", with: coupon.minimumSpendAmount.formatPriceWithoutCurrencySymbol() ?? "0")
                    isValid = false
                } else {
                    if let merchantProducts: [CouponCheckMerchant] = self.couponCheckMerchants, let cartMerchant = self.data, let selectedCoupons = couponMap {
                        
                        let manager = CouponManager.shareManager()
                       
                        if cartMerchant.merchantId == Constants.MMMerchantId  {
                            // for MM
                            isValid = manager.eligible(forMMCoupon: coupon, merchants: merchantProducts, selectedCoupons: selectedCoupons)
                      
                        } else {
                            // for Merchants
                            for merchant in merchantProducts {
                                if merchant.merchantId == cartMerchant.merchantId {
                                    isValid = manager.eligible(forMerchantCoupon: coupon, merchant: merchant)
                                    break
                                }
                            }
                        }
                        
                        if !isValid {
                            errorMessage = String.localize("MSG_ERR_CA_COUPON_PROMO_MEET")
                        }
                    }
                    
                }
            }
            
            if !isValid {
                self.showError(errorMessage, animated: true)
            }
        } else {
            ErrorLogManager.sharedManager.recordNonFatalError(withException: .NullPointer)
        }
        
        return isValid
    }
    
    func checkCouponService(_ couponCode: String) -> Promise<Any> {
        return Promise{ fulfill, reject in
            CouponService.checkCoupon(couponCode, merchantId: self.data?.merchantId ?? 0, success: { [weak self] (coupon) in
                if let strongSelf = self {
                    if coupon.isPending {
                        Alert.alert(strongSelf, title: "", message: String.localize("LB_CA_COUPON_UNBUNDLE_LIST_SELECTION_TITLE"),
                                    okTitle: String.localize("LB_CA_COUPON_UNBUNDLE_LIST_SELECTION_CHECK"), okActionComplete: {
                                        strongSelf.view.recordAction(.Tap, sourceRef: "CheckOrder", sourceType: .Button, targetRef: "PendingPayment", targetType: .View)
                                        var bundle = QBundle()
                                        bundle["viewMode"] = QValue(Constants.OmsViewMode.unpaid.rawValue)
                                        Navigator.shared.dopen(Navigator.mymm.website_order_list, params: bundle)
                        }, cancelTitle: String.localize("LB_CA_CANCEL"))
                        strongSelf.selectedClaimedCoupon = coupon
                        reject(NSError(domain: "", code: MerchantCouponSelectionViewController.UNBUNDLE_ERROR_CODE, userInfo: nil))
                    } else {
                        strongSelf.inputCoupon = coupon
                        fulfill("OK")
                    }
                } else {
                    ErrorLogManager.sharedManager.recordNonFatalError(withException: .NullPointer)
                }
                }, failure: { [weak self] (error) -> Bool in
                    if let strongSelf = self {
                        strongSelf.inputCoupon = nil
                    }
                    reject(error)
                    return true
                })
        }
    }
    
    //MARK:- Analytic
    private func initAnalyticLog() {
        if let merchant = data {
            if merchant.merchantId == Constants.MMMerchantId {
                initAnalyticsViewRecord(merchantCode: "\(merchant.merchantId)", viewDisplayName: merchant.merchantName, viewLocation: "MyMMCouponSelectList", viewType: "Coupon")
            }
            else {
                initAnalyticsViewRecord(merchantCode: "\(merchant.merchantId)", viewDisplayName: merchant.merchantName, viewLocation: "MerchantCouponSelectList", viewType: "Coupon")
            }
        }
    }
    
    //MARK:- Keyboard Notification
    @objc override func keyboardWillShowNotification(_ notification: NSNotification) {
        isKeyboardShowing = true
    }
    
    @objc override func keyboardWillHideNotification(_ notification: NSNotification) {
        isKeyboardShowing = false
    }
    
    func scrollViewDidScroll(_ scrollView: UIScrollView) {
        if isKeyboardShowing {
            view.endEditing(true)
        }
        
        if lastY > HeaderHeight && scrollView.contentOffset.y <= HeaderHeight {
            
            if let merchant = data, merchant.merchantId != Constants.MMMerchantId {
                recordImpression(impressionRef: "\(merchant.merchantId)", impressionType: "Merchant", impressionDisplayName: merchant.merchantName, merchantCode: "\(merchant.merchantId)", positionComponent: merchant.merchantName, positionLocation: "Coupon-Merchant")
            }
        }
        
        lastY = scrollView.contentOffset.y
    }
}

extension MerchantCouponSelectionViewController: UITableViewDelegate {
    func tableView(_ tableView: UITableView, heightForHeaderInSection section: Int) -> CGFloat {
        return 0
    }
    
    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        if indexPath.row == 0 {
            //header
            return HeaderHeight
        }
        
        if indexPath.row > 2 {
            let coupon = coupons[indexPath.row - 3]
            
            if coupon.isExpanded {
                let height = 30 + StringHelper.heightForText(coupon.couponRemark, width: tableView.frame.width - 60, font: UIFont.fontLightWithSize(14))
                
                return 110 + height
            }
        }
        
        return 110
    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        guard indexPath.row != 0 else { return }
        
        if let cell = inputCell, !cell.btnCheckBox.isUserInteractionEnabled && indexPath.row == 1 {
            return
        }
        
        guard let cell = tableView.cellForRow(at: indexPath) as? CouponSelectionCell, !cell.btnCheckBox.isSelected /*&& cell.btnCheckBox.isUserInteractionEnabled*/ else { return }
        
        if indexPath.row > 2 {
            if let coupon = coupons.get(indexPath.row - 3) {
                setButtonConfirmActive(false)
                if isValid(coupon) {
                    CouponService.checkCoupon(coupon.couponReference, merchantId: coupon.merchantId ?? 0, success: { [weak self] (coupon) in
                        if let strongSelf = self {
                            if coupon.isPending {
                                Alert.alert(strongSelf, title: "", message: String.localize("LB_CA_COUPON_UNBUNDLE_LIST_SELECTION_TITLE"),
                                            okTitle: String.localize("LB_CA_COUPON_UNBUNDLE_LIST_SELECTION_CHECK"), okActionComplete: {
                                    strongSelf.view.recordAction(.Tap, sourceRef: "CheckOrder", sourceType: .Button, targetRef: "PendingPayment", targetType: .View)
                                    var bundle = QBundle()
                                    bundle["viewMode"] = QValue(Constants.OmsViewMode.unpaid.rawValue)
                                    Navigator.shared.dopen(Navigator.mymm.website_order_list, params: bundle)
                                }, cancelTitle: String.localize("LB_CA_CANCEL"))
                                strongSelf.selectedClaimedCoupon = coupon
                            } else {
                                strongSelf.setButtonConfirmActive(true)
                            }
                        }
                        
                    }, failure: { (error) -> Bool in
                        return true
                    })
                }
                
                if let selectedCoupon = self.previousSelectedCoupon {
                    selectedCoupon.selected = false
                }
                
                coupon.selected = true
                self.previousSelectedCoupon = coupon
                
                // record action
                cell.recordAction(.Tap, sourceRef: "SelectToApplyInPurchase", sourceType: .Button, targetRef: coupon.couponReference, targetType: .Coupon)
            }
        }
        else {
            setButtonConfirmActive(true)
            
            if let selectedCoupon = previousSelectedCoupon {
                selectedCoupon.selected = false
            }
            
            previousSelectedCoupon = nil
            
            // record action
            if indexPath.row == 1 {
                cell.recordAction(.Tap, sourceRef: "SelectToInputMerchantCouponCode", sourceType: .Button, targetType: .Coupon)
            }
            else {
                cell.recordAction(.Tap, sourceRef: "SelectToNoCoupon", sourceType: .Button, targetType: .Coupon)
            }
        }
        
        currentImpressionKey = cell.analyticsImpressionKey
        
        previousSelectedCell?.btnCheckBox.isSelected = false
        cell.btnCheckBox.isSelected = true
        previousSelectedCell = cell
    }
}

extension MerchantCouponSelectionViewController: UITableViewDataSource {
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return coupons.count + 3
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        if indexPath.row == 0 {
            //header
            let cell = tableView.dequeueReusableCell(withIdentifier: MerchantCouponSelectionViewController.MerchantCouponHeaderViewIdentifier, for: indexPath) as! MerchantCouponHeaderView
            
            cell.data = data
            
            return cell
        }
        
        if indexPath.row == 2 {
            // select no coupon row
            let cell = tableView.dequeueReusableCell(withIdentifier: MerchantCouponSelectionViewController.MerchantCouponDeselectCellIdentifier, for: indexPath) as! MerchantCouponDeselectCell
            
            noSelectCouponCell = cell
            
            // record impression
            if let merchant = data {
                var positionLocation = ""
                if merchant.merchantId == Constants.MMMerchantId {
                    positionLocation = "MyMMCouponSelectList"
                }
                else {
                    positionLocation = "MerchantCouponSelectList"
                }
                cell.initAnalytics(withViewKey: analyticsViewRecord.viewKey, impressionKey: recordImpression(impressionType: "Coupon", merchantCode: "\(merchant.merchantId)", positionComponent: "Grid", positionIndex: indexPath.row - 1, positionLocation: positionLocation))
            }
            
            return cell
        }
        else if indexPath.row == 1 {
            // input coupon row
            let cell = tableView.dequeueReusableCell(withIdentifier: MerchantCouponSelectionViewController.MerchantCouponInputCellIdentifier, for: indexPath) as! MerchantCouponInputCell
            
            if isMMCoupon {
                cell.tfCoupon.placeholder = String.localize("LB_CA_CHECKOUT_MYMM_COUPON_CODE")
            }
            else {
                cell.tfCoupon.placeholder = String.localize("LB_CA_CHECKOUT_MERC_COUPON_CODE")
            }
            
            cell.checkCouponHandler = { [weak self] code in
                if let strongSelf = self, let couponCode = code {
                    strongSelf.checkCoupon(couponCode)
                    
                    // record action
                    cell.recordAction(.Tap, sourceRef: "CouponCodeToRedeem", sourceType: .Button, targetRef: couponCode, targetType: .Coupon)
                }
            }
            
            inputCell = cell
            
            // record impression
            if let merchant = data {
                var positionLocation = ""
                if merchant.merchantId == Constants.MMMerchantId {
                    positionLocation = "MyMMCouponSelectList"
                }
                else {
                    positionLocation = "MerchantCouponSelectList"
                }
                cell.initAnalytics(withViewKey: analyticsViewRecord.viewKey, impressionKey: recordImpression(impressionType: "Coupon", merchantCode: "\(merchant.merchantId)", positionComponent: "Grid", positionIndex: indexPath.row, positionLocation: positionLocation))
            }
            
            return cell
        }
        else {
            let cell = tableView.dequeueReusableCell(withIdentifier: MerchantCouponSelectionViewController.MerchantCouponSelectionViewCellIdentifier, for: indexPath) as! MerchantCouponSelectionCell
            
            if let coupon = coupons.get(indexPath.row - 3) {
                cell.data = coupon
                if coupon.selected {
                    previousSelectedCell = cell
                    previousSelectedCoupon = coupon
                }
                
                cell.toggleExpandCollapseHandler = {
                    tableView.beginUpdates()
                    tableView.endUpdates()
                }
                
                // record impression
                if let merchant = data {
                    var positionLocation = ""
                    if merchant.merchantId == Constants.MMMerchantId {
                        positionLocation = "MyMMCouponSelectList"
                    }
                    else {
                        positionLocation = "MerchantCouponSelectList"
                    }
                    cell.initAnalytics(withViewKey: analyticsViewRecord.viewKey, impressionKey: recordImpression(impressionRef: coupon.couponReference, impressionType: "Coupon", impressionDisplayName: coupon.couponName, merchantCode: "\(merchant.merchantId)", positionComponent: "Grid", positionIndex: indexPath.row - 2, positionLocation: positionLocation))
                }
            }
            
            return cell
        }
    }
    
}
