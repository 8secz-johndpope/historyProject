//
//  CouponInputViewController.swift
//  merchant-ios
//
//  Created by LongTa on 6/16/16.
//  Copyright © 2016 WWE & CO. All rights reserved.
//

import UIKit
import PromiseKit
import ObjectMapper

protocol CouponInputViewControllerDelegate: NSObjectProtocol {
    func didInputCoupon(_ coupon: Coupon, isMmCoupon: Bool, withMerchantId merchantId: Int)
    func didRemoveCoupon(_ isMmCoupon: Bool, withMerchantId merchantId: Int)
    func revertMerchantCoupon(_ coupon: Coupon?, withMerchantId merchantId: Int)
}

extension CouponInputViewControllerDelegate {
    func revertMerchantCoupon(_ coupon: Coupon?, withMerchantId merchantId: Int){}
}

class CouponInputViewController: MmViewController, UITextFieldDelegate {
    
    private final let CouponInputHeaderViewId = "CouponInputHeaderViewId"
    private final let CouponInputFooterViewId = "CouponInputFooterViewId"
    
    private final let ConfirmButtonHeight: CGFloat = 44
    private final let Spacing: CGFloat = 10
    
    private var confirmButton = UIButton()
    private var footerView: CouponInputFooterView?
    
    weak var delegate: CouponInputViewControllerDelegate?
    
    var isShowMMCoupon = false
    var inputCoupon: Coupon?
    var originalCoupon: Coupon?
    
    var cartMerchant: CartMerchant?
    var totalAmount: Double = 0
    
    private var coupons: [Coupon] = []
    private var selectingIndex = 0
    private var currentPage = 1
    private var totalPage = 0
    private var merchantId = 0
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        self.title = String.localize("LB_CA_CHECKOUT_COUPON_APPLY")
        
        self.initAnalyticLog()
        self.setupNavigationBar()
        self.setupLayout()
    }
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        
        self.navigationController?.setNavigationBarHidden(false, animated: false)
        
        NotificationCenter.default.addObserver(self, selector: #selector(self.keyboardWillShow), name: NSNotification.Name.UIKeyboardWillShow, object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(self.keyboardWillHide), name: NSNotification.Name.UIKeyboardWillHide, object: nil)
        
        self.collectionView?.reloadData()
        
        if !isShowMMCoupon {
            if let cartMerchant = self.cartMerchant {
                merchantId = cartMerchant.merchantId
            } else {
                ErrorLogManager.sharedManager.recordNonFatalError(withException: .NullPointer)
            }
        }
        
        loadCouponsAtPage(1, clearCouponList: true)
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        
        NotificationCenter.default.removeObserver(self, name: NSNotification.Name.UIKeyboardWillShow, object: nil)
        NotificationCenter.default.removeObserver(self, name: NSNotification.Name.UIKeyboardWillHide, object: nil)
    }

    func setupNavigationBar() {
        self.createBackButton()
    }
    
    func handleCheckOrderWithCouponError(_ notification: Notification) {
        self.stopLoading()
        
        if let errorCode = notification.object as? String {
            self.showError(String.localize(errorCode), animated: true)
        } else {
            ErrorLogManager.sharedManager.recordNonFatalError(withException: .NullPointerOrTypeMismatch)
        }
        
        self.reloadAllData()
    }
    
    func handleCheckOrderWithCouponSuccess() {
        self.stopLoading()
        self.navigationController?.popViewController(animated: true)
    }
    
    func setupLayout() {
        confirmButton.addTarget(self, action: #selector(self.confirmButtonClicked), for: .touchUpInside)
        confirmButton.setTitle(String.localize("LB_CA_CONFIRM"), for: UIControlState())
        confirmButton.frame = CGRect(x: Spacing, y: Spacing , width: self.view.bounds.width - Spacing * 2, height: ConfirmButtonHeight)
        
        let bottomView = UIView()
        bottomView.frame = CGRect(x: 0, y: view.height - (ConfirmButtonHeight + Spacing * 2), width: view.width, height: ConfirmButtonHeight + Spacing * 2)
        bottomView.addSubview(confirmButton)
        
        let line = UIView()
        line.backgroundColor = UIColor.secondary1()
        line.frame = CGRect(x: 0, y: 0, width: bottomView.frame.width, height: 1)
        bottomView.addSubview(line)
        self.view.addSubview(bottomView)
        
        collectionView.frame = CGRect(x: 0, y: StartYPos, width: view.width, height: view.height - (64 + ConfirmButtonHeight + Spacing * 2))
        collectionView.backgroundColor = UIColor.white
        collectionView.register(CouponViewCell.self, forCellWithReuseIdentifier: CouponViewCell.CellIdentifier)
        collectionView.register(CouponInputHeaderView.self, forSupplementaryViewOfKind: UICollectionElementKindSectionHeader, withReuseIdentifier: self.CouponInputHeaderViewId)
        collectionView.register(CouponInputFooterView.self, forSupplementaryViewOfKind: UICollectionElementKindSectionFooter, withReuseIdentifier: self.CouponInputFooterViewId)
        collectionView.reloadData()
        
        updateConfirmButton()
    }
    
    // MARK: Keyboard
    
    @objc func keyboardWillShow(_ notification: Notification) {
        if let info = notification.userInfo, let kbObj = info[UIKeyboardFrameEndUserInfoKey] {
            var kbRect = (kbObj as! NSValue).cgRectValue
            kbRect = self.view.convert(kbRect, from: nil)
            
            var frame = self.collectionView.frame
            frame.size.height = self.view.frame.size.height - (frame.origin.y + kbRect.height)
            
            UIView.animate(withDuration: 0.25, delay: 0.0, options: .curveEaseOut, animations: {
                self.collectionView.frame = frame
            }, completion: { finished in
                
            })
        } else {
            ErrorLogManager.sharedManager.recordNonFatalError(withException: .NullPointer)
        }
    }
    
    @objc func keyboardWillHide(_ notification: Notification) {
        UIView.animate(withDuration: 0.25, delay: 0.0, options: .curveEaseOut, animations: {
            self.collectionView.frame = CGRect(x: 0, y: StartYPos, width: self.view.width, height: self.view.height - (64 + self.ConfirmButtonHeight + self.Spacing * 2))
        }, completion: { finished in
            
        })
    }
    
    @objc func checkCoupon() {
        self.dismissKeyboard()
        
        var couponCode = ""
        
        if let string = footerView?.textFieldCouponInput.text?.trimmingCharacters(in: CharacterSet.whitespacesAndNewlines).lowercased()  {
            if string.length < 1 {
                self.showError(String.localize("LB_CA_CHECKOUT_MERC_COUPON_CODE"), animated: true)
                return
            }
            
            couponCode = string
        } else {
            ErrorLogManager.sharedManager.recordNonFatalError(withException: .NullPointer)
        }
        
        if let couponInputView = self.footerView {
            couponInputView.resetCouponNameAndPrice()
        } else {
            ErrorLogManager.sharedManager.recordNonFatalError(withException: .NullPointer)
        }
        
        showLoading()
        
        firstly {
            return checkCouponService(couponCode)
        }.then { _ -> Void in
            if self.checkValid(coupon: self.inputCoupon) {
                self.showSuccessPopupWithText(String.localize("LB_CA_VALID_COUPON"))
            }
            
            self.selectCouponAtIndex(-1)
        }.always {
            self.stopLoading()
        }.catch { _ -> Void in
            Log.error("error")
        }
    }
    
    //Show dialog when invalid coupon
    
    func checkValid(coupon:Coupon?, isShowError: Bool = true) -> Bool {
        var isValid = true
        
        if let coupon = self.inputCoupon {
            var errorMessage = ""
            
            if !isShowMMCoupon {
                if let cartMerchant = self.cartMerchant {
                    let merchantId = cartMerchant.merchantId
                    //This coupon doesn't belong to current merchant
                    if coupon.merchantId != merchantId {
                        errorMessage = String.localize("MSG_ERR_CA_COUPON_CODE_VALID")
                        isValid = false
                    }
                } else {
                    ErrorLogManager.sharedManager.recordNonFatalError(withException: .NullPointer)
                }
            }
            
            if !coupon.isAvailable && coupon.isRedeemable && self.isShowMMCoupon == coupon.isMmCoupon() {
                if !checkMinimumAmount(coupon) {
                    return false
                }
            } else if coupon.isAvailable == false {
                errorMessage = String.localize("MSG_ERR_INVALID_COUPON")
                isValid = false
            } else if coupon.isRedeemable == false {
                errorMessage = String.localize("MSG_ERR_CA_COUPON_CODE_EXCEED_LIMIT")
                isValid = false
            } else {
                errorMessage = String.localize("MSG_ERR_CA_COUPON_CODE_VALID")
                isValid = false
            }
            
            if isShowError && !isValid {
                self.showError(errorMessage, animated: true)
            }
        } else {
            ErrorLogManager.sharedManager.recordNonFatalError(withException: .NullPointer)
        }
        
        return isValid
    }
    
    func checkCouponService(_ couponCode: String) -> Promise<Any> {
        var merchantId = 0
        
        if !isShowMMCoupon {
            if let cartMerchant = self.cartMerchant {
                merchantId = cartMerchant.merchantId
            } else {
                ErrorLogManager.sharedManager.recordNonFatalError(withException: .NullPointer)
            }
        }
        
        return Promise{ fulfill, reject in
            CouponService.checkCoupon(couponCode, merchantId: merchantId, success: { [weak self] (coupon) in
                if let strongSelf = self {
                    strongSelf.inputCoupon = coupon
                    fulfill("OK")
                }
                else {
                    ErrorLogManager.sharedManager.recordNonFatalError(withException: .NullPointer)
                }
                }, failure: { (error) -> Bool in
                    reject(error)
                    return false
            })
        }
    }
    
    private func loadCoupon(_ merchantId: Int, page: Int, pageSize: Int) -> Promise<Any> {
        return Promise{ fulfill, reject in
            CouponService.listCoupon(merchantId, success: { [weak self] (couponList) in
                if let strongSelf = self {
                    if let coupons = couponList.pageData {
                        strongSelf.currentPage = couponList.pageCurrent
                        strongSelf.totalPage = couponList.pageTotal
                        strongSelf.coupons.append(contentsOf: coupons)
                        
                        let coupon = strongSelf.isShowMMCoupon ? strongSelf.originalCoupon : strongSelf.cartMerchant?.coupon
                        
                        if let strongCoupon = coupon {
                            let filterCoupons = strongSelf.coupons.filter{ $0.couponReference == strongCoupon.couponReference }
                            
                            for coupon in filterCoupons {
                                coupon.isSelected = true
                            }
                        } else {
                            ErrorLogManager.sharedManager.recordNonFatalError(withException: .NullPointer)
                        }
                        fulfill("OK")
                    }
                }
                else {
                    ErrorLogManager.sharedManager.recordNonFatalError(withException: .NullPointer)
                }
                }, failure: { (error) -> Bool in
                    reject(error)
                    return false
            })
        }
    }

    func dismissKeyboard() {
        self.view.endEditing(true)
    }
    
    // MARK: UITextField Delegate
    
    func textFieldShouldReturn(_ textField: UITextField) -> Bool {
        dismissKeyboard()
        checkCoupon()
        
        return true
    }
    
    func textFieldShouldClear(_ textField: UITextField) -> Bool {
        footerView?.setData(nil)
        return true
    }
    
    // MARK: Methods
    
    func didClickConfirmButton() {
        dismissKeyboard()
        checkCoupon()
    }
    
    func loadCouponsAtPage(_ page: Int, clearCouponList: Bool = false) {
        if clearCouponList {
            coupons.removeAll()
            currentPage = 1
            totalPage = 0
        }
        
        showLoading()
        
        firstly {
            return self.loadCoupon(self.merchantId, page: page, pageSize: Constants.Paging.Offset)
        }.then { _ -> Void in
            self.reloadAllData()
        }.always {
            self.stopLoading()
        }.catch { _ -> Void in
            Log.error("error")
        }
    }
    
    // MARK: - Collection view delegate flow layout methods
    
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, minimumInteritemSpacingForSectionAt section: Int) -> CGFloat {
        return 0.0
    }
    
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, minimumLineSpacingForSectionAt section: Int) -> CGFloat {
        return 0.0
    }
    
    // MARK: - Collection view data source methods
    
    func numberOfSections(in collectionView: UICollectionView) -> Int {
        return 1
    }
    
    override func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return coupons.count
    }
    
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, referenceSizeForHeaderInSection section: Int) -> CGSize {
        return CGSize(width: view.width, height: 70)
    }
    
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, referenceSizeForFooterInSection section: Int) -> CGSize {
        return CGSize(width: view.width, height: 110)
    }
    
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, sizeForItemAt indexPath: IndexPath) -> CGSize {
        return CGSize(width: view.width, height: 44)
    }
    
    func collectionView(_ collectionView: UICollectionView, viewForSupplementaryElementOfKind kind: String, at indexPath: IndexPath) -> UICollectionReusableView {
        if kind == UICollectionElementKindSectionHeader {
            let view = collectionView.dequeueReusableSupplementaryView(ofKind: kind, withReuseIdentifier: self.CouponInputHeaderViewId, for: indexPath) as! CouponInputHeaderView
            
            if self.isShowMMCoupon {
                view.setMmData()
            } else {
                view.setMerchantData(self.cartMerchant)
            }
            
            return view
        } else /*if kind == UICollectionElementKindSectionFooter*/ {
            let view = collectionView.dequeueReusableSupplementaryView(ofKind: kind, withReuseIdentifier: self.CouponInputFooterViewId, for: indexPath) as! CouponInputFooterView
            view.setData(nil, isShowMMCoupon: isShowMMCoupon)
            
            if let coupon = self.inputCoupon {
                view.setData(coupon, isShowMMCoupon: isShowMMCoupon)
                view.enableCheckBox(self.checkValid(coupon: coupon, isShowError: false))
            } else {
                view.enableCheckBox(false)
            }
            
            view.addButton.addTarget(self, action: #selector(self.checkCoupon), for: UIControlEvents.touchUpInside)
            view.textFieldCouponInput.delegate = self
            view.addGestureRecognizer(UITapGestureRecognizer(target: self, action: #selector(self.didClickFooterView)))
            footerView = view
            
            return view
        }
    }
    
    override func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        let cell = collectionView.dequeueReusableCell(withReuseIdentifier: CouponViewCell.CellIdentifier, for: indexPath) as! CouponViewCell
        let coupon = self.coupons[indexPath.row]
        cell.setData(coupon)
        
        // Load More
        if indexPath.row >= self.coupons.count - 1 && totalPage > currentPage {
            loadCouponsAtPage(currentPage + 1)
        }
        
        return cell
    }
    
    // MARK: - Collection View delegate methods
    
    func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        self.dismissKeyboard()
        self.selectingIndex = indexPath.row
        self.selectCouponAtIndex(indexPath.row)
    }
    
    private func invertSelected(coupon: Coupon?) {
        if let strongCoupon = coupon {
            strongCoupon.isSelected = !strongCoupon.isSelected
        } else {
            ErrorLogManager.sharedManager.recordNonFatalError(withException: .NullPointer)
        }
    }
    
    private func getCouponAtIndex(_ index: Int) -> Coupon?{
        if selectingIndex > -1 {
            let coupon = coupons[selectingIndex]
            return coupon
        } else {
            return inputCoupon
        }
    }
    
    func selectCouponAtIndex(_ index: Int) {
        self.selectingIndex = index
        
        let selectingCoupon = getCouponAtIndex(selectingIndex)
        invertSelected(coupon: selectingCoupon)
        
        let isSelectingInputConpon = (selectingIndex == -1)
        
        if let strongInputCoupon = inputCoupon {
            if !isSelectingInputConpon {
                strongInputCoupon.isSelected = false
            }
        } else {
            ErrorLogManager.sharedManager.recordNonFatalError(withException: .NullPointer)
        }
        
        for coupon in coupons {
            if isSelectingInputConpon {
                coupon.isSelected = false
            } else {
                if let strongSelectingCoupon = selectingCoupon {
                    if coupon.couponReference != strongSelectingCoupon.couponReference {
                        coupon.isSelected = false
                    }
                } else {
                    ErrorLogManager.sharedManager.recordNonFatalError(withException: .NullPointer)
                }
            }
        }
        
        reloadAllData()
        
        if let coupon = selectingCoupon {
            checkMinimumAmount(coupon)
        }
    }
    
    @objc func confirmButtonClicked(_ button: UIButton) {
        if isMissingData() {
            showError(String.localize("LB_CA_SELECT_COUPON"), animated: true)
            return
        }
        
        for coupon in coupons {
            if coupon.isSelected {
                
                if !checkMinimumAmount(coupon) {
                    return
                }
                
                showLoading()
                
                //Analytic
                let couponActionRecord = AnalyticsManager.createActionRecord(analyticsViewKey: analyticsViewRecord.viewKey, actionTrigger: .Apply, sourceRef: "\(coupon.couponId)", sourceType: isShowMMCoupon ? .CouponMyMM : .CouponMerchant, targetRef: "Checkout", targetType: .View)
                AnalyticsManager.sharedManager.recordAction(couponActionRecord)
                
                delegate?.didInputCoupon(coupon, isMmCoupon: isShowMMCoupon, withMerchantId: merchantId)
                handleCheckOrderWithCouponSuccess()
                
                return
            }
        }
        
        if let strongCoupon = inputCoupon {
            showLoading()
            
            delegate?.didInputCoupon(strongCoupon, isMmCoupon: isShowMMCoupon, withMerchantId: merchantId)
        } else {
            delegate?.didRemoveCoupon(isShowMMCoupon, withMerchantId: merchantId)
        }
        
        self.handleCheckOrderWithCouponSuccess()
    }
    
    @discardableResult
    func checkMinimumAmount(_ coupon: Coupon) -> Bool {
        if coupon.minimumSpendAmount > self.totalAmount {
            let errorMessage = String.localize("MSG_ERR_CA_COUPON_CODE_MIN").replacingOccurrences(of: "{0}", with: coupon.minimumSpendAmount.formatPriceWithoutCurrencySymbol() ?? "0")
            showError(errorMessage, animated: true)
            return false
        }
        
        return true
    }
    
    @objc func didClickFooterView() {
        if let coupon = self.inputCoupon {
            if checkValid(coupon: coupon, isShowError: false) {
                selectCouponAtIndex(-1)
            } else {
                coupon.isSelected = false
            }
            
            reloadAllData()
        } else {
            ErrorLogManager.sharedManager.recordNonFatalError(withException: .NullPointer)
        }
    }
    
    func isMissingData() -> Bool {
        if let coupon = inputCoupon {
            if !coupon.isSelected {
                return true
            }
            
            if !checkValid(coupon: inputCoupon) {
                return true
            }
        }
        
        return false
    }
    
    func isEnoughInfo() -> Bool {
        for coupon in coupons {
            if coupon.isSelected {
                return true
            }
        }
        
        if let coupon = inputCoupon {
            if !coupon.isSelected {
                return false
            }
            
            if !checkValid(coupon: inputCoupon) {
                return false
            }
        } else {
            return false
        }

        return true
    }
    
    func updateConfirmButton () {
        confirmButton.formatPrimary()
        confirmButton.layer.borderWidth = 0
    }
    
    func reloadAllData(){
        updateConfirmButton()
        self.collectionView.reloadData()
    }
    
    override func backButtonClicked(_ button: UIButton)  {
        dismissKeyboard()
        
        super.backButtonClicked(button)
    }
    
    // MARK: Logging
    
    func initAnalyticLog(){
        let viewLocation: String = isShowMMCoupon ? "Coupon-MyMM" : "Coupon-Merchant"
        var merchantCode: String? = nil
        
        if !isShowMMCoupon {
            if let cartMerchant = self.cartMerchant {
                merchantCode = "\(cartMerchant.merchantId)"
            } else {
                ErrorLogManager.sharedManager.recordNonFatalError(withException: .NullPointer)
            }
        }
        
        initAnalyticsViewRecord(
            merchantCode: merchantCode,
            viewDisplayName: String.localize("LB_CA_CHECKOUT_COUPON_APPLY"),
            viewLocation: viewLocation,
            viewType: "Checkout"
        )
    }
}
