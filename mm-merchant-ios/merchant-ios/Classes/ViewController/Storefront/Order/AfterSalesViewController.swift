//
//  AfterSalesViewController.swift
//  merchant-ios
//
//  Created by Quang Truong Dinh on 3/30/16.
//  Copyright © 2016 WWE & CO. All rights reserved.
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


protocol AfterSalesViewProtocol: NSObjectProtocol {
    func didCancelOrder(_ isSuccess: Bool, orderItem: OrderItem?, orderCancel: OrderCancel?)
    func didReturnOrder(_ isSuccess: Bool, orderItem: OrderItem?, orderReturn: OrderReturn?)
    func didDisputeOrder(_ isSuccess: Bool, orderItem: OrderItem?, orderReturn: OrderReturn?)
    func didSubmitReportReview(_ isSuccess: Bool)
}

class AfterSalesViewController: MmViewController, UITextFieldDelegate, UITextViewDelegate, ImagePickerManagerDelegate, UIPickerViewDataSource, UIPickerViewDelegate {
    
    enum ViewType: Int {
        case unknown = 0,
        cancel,
        `return`,
        dispute,
        reportReview
    }
    
    private final let DefaultCellID = "DefaultCellID"
    private final let QuantityCellId = "QuantityCellID"
    
    private final let SummaryViewHeight: CGFloat = 66
    private final let ReasonPickerHeight: CGFloat = 206
    
    private final let Titles = [
        "",
        String.localize("LB_CA_OMS_TAB_REFUND"),
        String.localize("LB_CA_OMS_TAB_RETURN"),
        String.localize("LB_CA_OMS_TAB_DISPUTE"),
        String.localize("LB_CA_REPORT_REVIEW")
    ]
    
    private final let EmptyReasonTexts = [
        "",
        String.localize("LB_CA_SELECT_CANCEL_REASON"),
        String.localize("LB_CA_SELECT_RETURN_REASON"),
        String.localize("LB_CA_SELECT_DISPUTE_REASON"),
        String.localize("LB_CA_REPORT_POST_SELECT_REASON")
    ]
    
    private final let AmountTitles = [
        "",
        String.localize("LB_REFUND_AMOUNT"),
        String.localize("LB_REFUND_AMOUNT"),
        String.localize("LB_DISPUTE_AMOUNT"),
        ""
    ]
    
    private final let DescriptionPlaceholders = [
        "",
        String.localize("LB_REFUND_DESC"),
        String.localize("LB_REFUND_DESC"),
        String.localize("LB_DISPUTE_DESC"),
        String.localize("LB_CA_REPORT_POST_DESC")
    ]
    
    private var selectAllCartItemButton: UIButton!
    private var allCartItemSelected = false {
        didSet {
            self.selectAllCartItemButton.isSelected = allCartItemSelected
        }
    }
    
    private var quantityCell: QuantityCell?
    private var uploadPhotoCell: UploadPhotoCell?
    private var afterSalesAmountCell: AfterSalesAmountCell?
    private var afterSalesReasonCell: AfterSalesReasonCell?
    private var afterSalesDescriptionCell: AfterSalesDescriptionCell?
    
    private var reasonPicker: UIPickerView!
    
    private var afterSalesDescriptionTextView: UITextView?
    private var activeTextView: UITextView?
    
    private var afterSalesQuantity = 1
    
    private var reasons = [BaseReason]()
    private var selectedReason: BaseReason?
    private var selectedReasonId = 0
    
    private var submissionAttempt = 0
    
    private var imagePickerManager: ImagePickerManager?
    
    var orderSectionData: OrderSectionData?
    
    var orderItem: OrderItem?
    
    private var orderCancel: OrderCancel?
    private var orderReturn: OrderReturn?
    var maxAvailableAfterSalesQuantity = 0
    
    private var descriptionCharacterLimit = Constants.CharacterLimit.AfterSalesDescription
    private var imageLimit = 3
    
    private var afterSalesDescription = ""
    
    private var orderReturnImages = [UIImage]()
    
    private var afterSalesDataList = [AfterSalesData]()
    
    var currentViewType: ViewType = .unknown
    weak var delegate: AfterSalesViewProtocol?
    
    var skuReview: SkuReview?
    
    override func viewDidLoad() {
        super.viewDidLoad()
        self.navigationController!.isNavigationBarHidden = false
        self.view.backgroundColor = UIColor.backgroundGray()
        
        self.title = Titles[currentViewType.rawValue]
        
        switch currentViewType {
        case .cancel, .return, .dispute:
            descriptionCharacterLimit = Constants.CharacterLimit.AfterSalesDescription
            imageLimit = Constants.ImageLimit.AfterSales
        case .reportReview:
            descriptionCharacterLimit = Constants.CharacterLimit.ReportReviewDescription
        default:
            break
        }
        
        setupDismissKeyboardGesture()
        createSubViews()
        self.createBackButton(.crossSmall)
    }
    
    override func backButtonClicked(_ button: UIButton) {
        self.dismiss(button)
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        
        self.listAfterSalesReason()
    }
	
	override func viewWillDisappear(_ animated: Bool) {
		super.viewWillDisappear(animated)
		
		if currentViewType == .reportReview {
			NotificationCenter.default.removeObserver(self, name: Constants.Notification.reportReviewListShown, object: nil)
		}
	}
    
    override func collectionViewBottomPadding() -> CGFloat {
        return SummaryViewHeight
    }
    
    private func createRightBarItem() {
        let closeButton = UIButton(type: .custom)
        closeButton.setImage(UIImage(named: "icon_order_refund_cancel"), for: UIControlState())
        closeButton.frame = CGRect(x: self.view.frame.size.width - Constants.Value.BackButtonWidth, y: 0, width: Constants.Value.BackButtonWidth, height: Constants.Value.BackButtonHeight)
        closeButton.addTarget(self, action: #selector(dismiss(_:)), for: .touchUpInside)
        
        self.navigationItem.rightBarButtonItem = UIBarButtonItem(customView: closeButton)
    }
    
    private func createSubViews() {
        collectionView.register(MerchantSectionHeaderView.self, forSupplementaryViewOfKind: UICollectionElementKindSectionHeader, withReuseIdentifier: MerchantSectionHeaderView.ViewIdentifier)
        collectionView.register(UICollectionViewCell.self, forCellWithReuseIdentifier: DefaultCellID)
        collectionView.register(OrderItemCell.self, forCellWithReuseIdentifier: OrderItemCell.CellIdentifier)
        collectionView.register(AfterSalesReasonCell.self, forCellWithReuseIdentifier: AfterSalesReasonCell.CellIdentifier)
        collectionView.register(QuantityCell.self, forCellWithReuseIdentifier: QuantityCellId)
        collectionView.register(AfterSalesAmountCell.self, forCellWithReuseIdentifier: AfterSalesAmountCell.CellIdentifier)
        collectionView.register(AfterSalesDescriptionCell.self, forCellWithReuseIdentifier: AfterSalesDescriptionCell.CellIdentifier)
        collectionView.register(UploadPhotoCell.self, forCellWithReuseIdentifier: UploadPhotoCell.CellIdentifier)
        
        switch currentViewType {
        case .reportReview:
            afterSalesDataList.append(AfterSalesData(title: String.localize("LB_CA_REFUND_REASON"), cellHeight: 40, hasBorder: true, reuseIdentifier: AfterSalesReasonCell.CellIdentifier))
            afterSalesDataList.append(AfterSalesData(title: nil, cellHeight: 130, hasBorder: true, reuseIdentifier: AfterSalesDescriptionCell.CellIdentifier))
        default:
            afterSalesDataList.append(AfterSalesData(title: nil, cellHeight: 140, hasBorder: true, reuseIdentifier: OrderItemCell.CellIdentifier))
            afterSalesDataList.append(AfterSalesData(title: String.localize("LB_CA_REFUND_REASON"), cellHeight: 40, hasBorder: true, reuseIdentifier: AfterSalesReasonCell.CellIdentifier))
            afterSalesDataList.append(AfterSalesData(title: String.localize("LB_QTY"), cellHeight: 40, hasBorder: true, reuseIdentifier: QuantityCellId))
            afterSalesDataList.append(AfterSalesData(title: nil, cellHeight: 130, hasBorder: true, reuseIdentifier: AfterSalesDescriptionCell.CellIdentifier))
            afterSalesDataList.append(AfterSalesData(title: String.localize("LB_CA_MAX_PHOTO"), cellHeight: 130, hasBorder: true, reuseIdentifier: UploadPhotoCell.CellIdentifier))
        }
        
        collectionView.frame = CGRect(x: collectionView.x, y: collectionView.y + 20, width: collectionView.width, height: collectionView.height - 20)
        
        let summaryView = { () -> UIView in
            let frame = CGRect(x: 0, y: collectionView.frame.maxY, width: collectionView.width, height: SummaryViewHeight)
            
            let view = UIView(frame: frame)
            view.backgroundColor = UIColor.white
            
            let confirmButton = { () -> UIButton in
                let rightPadding: CGFloat = 10
                let buttonSize = CGSize(width: 105, height: 38)
                
                let button = UIButton(type: .custom)
                button.frame = CGRect(
                    x: frame.width - buttonSize.width - rightPadding,
                    y: (frame.height - buttonSize.height) / 2,
                    width: buttonSize.width,
                    height: buttonSize.height
                )
                
                switch self.currentViewType {
                case .cancel:
                    button.formatPrimary()
                    button.setTitle(String.localize("LB_CANCEL_ITEMS"), for: UIControlState())
                case .return:
                    button.formatPrimary()
                    button.setTitle(String.localize("LB_CA_Return_Requested"), for: UIControlState())
                case .dispute:
                    button.formatPrimary()
                    button.setTitle(String.localize("LB_CA_RETURN_APPLICATION"), for: UIControlState())
                case .reportReview:
                    button.formatPrimary()
                    button.setTitle(String.localize("LB_CA_SUBMIT"), for: UIControlState())
                    
                    let topBorderView = UIView(frame:CGRect(x: 0, y: 0, width: view.frame.width, height: 1))
                    topBorderView.backgroundColor = UIColor.secondary1()
                    view.addSubview(topBorderView)
                    
                    button.frame = CGRect(
                        x: Constants.BottomButtonContainer.MarginHorizontal,
                        y: Constants.BottomButtonContainer.MarginVertical,
                        width: self.view.frame.size.width - (Constants.BottomButtonContainer.MarginHorizontal * 2),
                        height: Constants.BottomButtonContainer.Height - (Constants.BottomButtonContainer.MarginVertical * 2)
                    )
                default:
                    break
                }
                
                button.addTarget(self, action: #selector(AfterSalesViewController.confirm), for: .touchUpInside)
                
                return button
                
            } ()
            view.addSubview(confirmButton)
            
            return view
        } ()
        view.addSubview(summaryView)
        
    }
    
    // MARK: Action
    
    @objc func confirm() {
        switch currentViewType {
        case .cancel:
            cancelApplication()
        case .return:
            returnApplication()
        case .dispute:
            disputeApplication()
        case .reportReview:
            submitReportReview()
        default:
            break
        }
    }
    
    func submitReportReview() {
        if selectedReason == nil {
            self.showError(String.localize("MSG_ERR_CA_REVIEW_REPORT"), animated: true)
        } else {
            if self.selectedReason != nil {
                self.showLoading()
                firstly {
                    return self.createReportReview()
                }.then { _ -> Void in
                    self.dismiss(animated: true, completion: nil)
                    self.delegate?.didSubmitReportReview(true)
                }.always {
                   self.stopLoading()
                }
            }
        }
    }
    
    func cancelApplication() {
        let okActionTapped = {() -> Void in
            if self.selectedReason != nil {
                firstly {
                    return self.createOrderCancel()
                }.then { _ -> Void in
                    self.dismiss(animated: true, completion: {
                        self.orderItem?.qtyCancelled = self.afterSalesQuantity
                        self.delegate?.didCancelOrder(true, orderItem: self.orderItem, orderCancel: self.orderCancel)
                    })
                }.always {
                    
                }
            }
        }
        
        if selectedReason == nil {
            // TODO: replace with error key
            self.showError(String.localize("MSG_ERR_REASON"), animated: true)
            return
        }
        
        Alert.alert(self, title: String.localize("LB_CA_OMS_CONFIRM_APPLICATION"), message: String.localize("LB_CA_OMS_CANCEL_NOTE"), okActionComplete: { () -> Void in
            okActionTapped()
        }, cancelActionComplete: { () -> Void in
            self.dismiss(animated: true, completion: nil)
        })
    }
    
    func returnApplication() {
        let okActionTapped = { () -> Void in
            if let sectionData = self.orderSectionData {
                if let order = sectionData.order {
                    if let orderItem = self.orderItem {
                        self.showLoading()
                        
                        firstly {
                            return self.createOrderReturn(order.orderKey, merchantId: order.merchantId, skuId: orderItem.skuId, qty: self.afterSalesQuantity, courierId: sectionData.orderShipment!.courierId, orderReturnReasonId: self.selectedReason!.reasonId, description: self.afterSalesDescription, imageDatas: self.getNewOrderReturnPhotoDatas())
                        }.then { orderActionResponse -> Promise<Any> in
                            let orderActionResponse = orderActionResponse as? OrderActionResponse
                            return self.viewOrderReturn(orderReturnKey: (orderActionResponse?.entityId ?? ""))
                        }.then { orderReturn -> Void in
                            if let orderReturn = orderReturn as? OrderReturn {
                                orderItem.qtyReturned = self.afterSalesQuantity
                                
                                self.dismiss(animated: true, completion: {
                                    self.delegate?.didReturnOrder(true, orderItem: orderItem, orderReturn: orderReturn)
                                })
                            } else {
                                ErrorLogManager.sharedManager.recordNonFatalError(withException: .NullPointerOrTypeMismatch)
                            }
                        }.always {
                            self.stopLoading()
                        }.catch { _ -> Void in
                            Log.error("error")
                        }
                    } else {
                        ErrorLogManager.sharedManager.recordNonFatalError(withException: .NullPointer)
                    }
                } else {
                    ErrorLogManager.sharedManager.recordNonFatalError(withException: .NullPointer)
                }
            } else {
                ErrorLogManager.sharedManager.recordNonFatalError(withException: .NullPointer)
            }
        }
        
        if selectedReason == nil {
            // TODO: replace with error key
            self.showError(String.localize("MSG_ERR_REASON"), animated: true)
            return
        }
        
        if afterSalesDescription.isEmpty {
            // TODO: Replace error key for empty comment here
            self.showError(String.localize("MSG_ERR_RETURN_TEXT_BLANK"), animated: true)
            return
        }
        
        Alert.alert(self, title: String.localize("LB_CA_OMS_CONFIRM_APPLICATION"), message: "", okActionComplete: { () -> Void in
            okActionTapped()
        })
    }
    
    func disputeApplication() {
        let okActionTapped = { () -> Void in
            if let sectionData = self.orderSectionData {
                if let order = sectionData.order {
                    if let orderItem = self.orderItem {
                        if let orderReturn = order.orderReturns?.first {
                            self.showLoading()
                            
                            firstly {
                                return self.createOrderDispute(orderReturn, skuId: orderItem.skuId, qty: self.afterSalesQuantity, orderDisputeReasonId: self.selectedReason?.reasonId ?? 0, description: self.afterSalesDescription, images: self.getNewOrderReturnPhotoDatas())
                            }.then { orderActionResponse -> Promise<Any> in
                                let orderActionResponse = orderActionResponse as? OrderActionResponse
                                return self.viewOrderReturn(orderReturnKey: (orderActionResponse?.entityId ?? ""))
                            }.then { orderReturn -> Void in
                                if let orderReturn = orderReturn as? OrderReturn {
                                    orderItem.qtyDisputed = self.afterSalesQuantity
                                    
                                    self.dismiss(animated: true, completion: {
                                        self.delegate?.didDisputeOrder(true, orderItem: orderItem, orderReturn: orderReturn)
                                    })
                                } else {
                                    ErrorLogManager.sharedManager.recordNonFatalError(withException: .NullPointerOrTypeMismatch)
                                }
                            }.always {
                                self.stopLoading()
                            }.catch { _ -> Void in
                                Log.error("error")
                            }
                        } else {
                            ErrorLogManager.sharedManager.recordNonFatalError(withException: .DataIsEmpty)
                        }
                    } else {
                        ErrorLogManager.sharedManager.recordNonFatalError(withException: .NullPointer)
                    }
                } else {
                    ErrorLogManager.sharedManager.recordNonFatalError(withException: .NullPointer)
                }
            } else {
                ErrorLogManager.sharedManager.recordNonFatalError(withException: .NullPointer)
            }
        }
        
        if self.selectedReason == nil {
            // TODO: replace with error key
            self.showError(String.localize("MSG_ERR_REASON"), animated: true)
            return
        }
        
        if afterSalesDescription.isEmpty {
            // TODO: Replace error key for empty comment here
            self.showError(String.localize("MSG_ERR_RETURN_TEXT_BLANK"), animated: true)
            return
        }
        
        Alert.alert(self, title: String.localize("LB_CA_OMS_CONFIRM_APPLICATION"), message: "", okActionComplete: { () -> Void in
            okActionTapped()
        })
    }
    
    @objc func dismiss(_ sender:UIButton!){
        self.dismiss(animated: true, completion: nil)
    }
    
    func addPhoto() {
        if imagePickerManager == nil {
            imagePickerManager = ImagePickerManager(viewController: self, withDelegate: self)
        }
        
        imagePickerManager!.presentDefaultActionSheet(preferredCameraDevice: .rear)
    }
    
    @objc func stepperValueChanged(_ sender: UIButton) {
        var qtyValue = self.afterSalesQuantity
        
        if sender.tag == QuantityCell.Tag.MinusButton {
            qtyValue -= 1
        } else if sender.tag == QuantityCell.Tag.AddButton {
            qtyValue += 1
        }
        
        self.updateQuantityValue(qtyValue)
    }
    
    func updateQuantityValue(_ qtyValue: Int) {
        var quantityValue = qtyValue
        
        // To check replace current quantity if the limit is less than 2 digits
        if maxAvailableAfterSalesQuantity < 10 {
            quantityValue = quantityValue % 10
        }
        
        // Qty checking
        quantityValue = max(quantityValue, 1)
        quantityValue = min(quantityValue, maxAvailableAfterSalesQuantity)
        
        self.afterSalesQuantity = quantityValue
        
        if let quantityCell = self.quantityCell {
            quantityCell.qtyTextField.text = String(self.afterSalesQuantity)
        } else {
            ErrorLogManager.sharedManager.recordNonFatalError(withException: .NullPointer)
        }
        
        if let afterSalesAmountCell = self.afterSalesAmountCell {
            afterSalesAmountCell.valueTextField.text = "\(orderItem!.unitPrice * Double(afterSalesQuantity))"
        } else {
            ErrorLogManager.sharedManager.recordNonFatalError(withException: .NullPointer)
        }
    }
    
    func updateAmountValue(valueText: String) {
        var amountInput: Double = 0.0
        var isValidInput = true
        if !valueText.isEmpty {
            // Make sure not contain characters
            let range = valueText.rangeOfCharacter(from: CharacterSet.decimalDigits)
            if range != nil {
                amountInput = (valueText as NSString).doubleValue
            } else {
                isValidInput = false
            }
        }
        
        // Amount checking
        let maxAmountAvailable: Double = Double(maxAvailableAfterSalesQuantity) * orderItem!.unitPrice

        amountInput = max(amountInput, 0)
        amountInput = min(amountInput, maxAmountAvailable)
        
        if let afterSalesAmountCell = self.afterSalesAmountCell {
            if !isValidInput {
                afterSalesAmountCell.valueTextField.text = "0"
            } else if amountInput >= maxAmountAvailable {
                afterSalesAmountCell.valueTextField.text = "\(maxAmountAvailable)"
            }
        } else {
            ErrorLogManager.sharedManager.recordNonFatalError(withException: .NullPointer)
        }
    }
    
    // MARK: Data
    
    private func listReportReviewReason() -> Promise<Any> {
        return Promise { fulfill, reject in
            ReviewService.getReviewReportReasonList({ [weak self] (response) in
                let statusCode = response.response?.statusCode ?? 0
                
                if let strongSelf = self {
                    if response.result.isSuccess {
                        if statusCode == 200 {
                            if let reportReviewReasons: Array<BaseReason> = Mapper<BaseReason>().mapArray(JSONObject: response.result.value) {
                                strongSelf.reasons = reportReviewReasons
                            } else {
                                ErrorLogManager.sharedManager.recordNonFatalError(withException: .FailToParseAPIResponse)
                            }
                            
                            fulfill("OK")
                        } else {
                            let error = NSError(domain: "", code: statusCode, userInfo: nil)
                            reject(error)
                        }
                    } else {
                        reject(response.result.error ?? NSError(domain: "", code: 0, userInfo: nil))
                    }
                } else {
                    ErrorLogManager.sharedManager.recordNonFatalError(withException: .NullPointer)
                }
            })
        }
    }
    
    @discardableResult
    private func listAfterSalesReasons(afterSalesType: Constants.OMSAfterSalesType = .cancel, completion complete:(() -> Void)? = nil) -> Promise<Any> {
        return Promise { fulfill, reject in
            OrderService.listAfterSalesReasons(afterSalesType: afterSalesType, completion: { [weak self] (response) in
                let statusCode = response.response?.statusCode ?? 0
                
                if let strongSelf = self {
                    if response.result.isSuccess {
                        if statusCode == 200 {
                            switch afterSalesType {
                            case .cancel:
                                if let cancelReasons: Array<OrderCancelReason> = Mapper<OrderCancelReason>().mapArray(JSONObject: response.result.value) {
                                    strongSelf.reasons = cancelReasons
                                } else {
                                    ErrorLogManager.sharedManager.recordNonFatalError(withException: .FailToParseAPIResponse)
                                }
                            case .`return`:
                                if let returnReasons: Array<OrderReturnReason> = Mapper<OrderReturnReason>().mapArray(JSONObject: response.result.value) {
                                    strongSelf.reasons = returnReasons
                                } else {
                                    ErrorLogManager.sharedManager.recordNonFatalError(withException: .FailToParseAPIResponse)
                                }
                            case .dispute:
                                if let disputeReasons: Array<OrderDisputeReason> = Mapper<OrderDisputeReason>().mapArray(JSONObject: response.result.value) {
                                    strongSelf.reasons = disputeReasons
                                } else {
                                    ErrorLogManager.sharedManager.recordNonFatalError(withException: .FailToParseAPIResponse)
                                }
                            }
                            
                            let selectedReasonId = strongSelf.selectedReasonId
                            
                            for i in 0..<strongSelf.reasons.count {
                                let reason = strongSelf.reasons[i]
                                
                                if reason.reasonId == selectedReasonId {
                                    strongSelf.reasonPicker.selectRow(i, inComponent: 0, animated: true)
                                    strongSelf.selectedReason = reason
                                    strongSelf.afterSalesReasonCell?.textField.text = reason.reasonName
                                    strongSelf.afterSalesReasonCell?.textField.textColor = UIColor.blackTitleColor()
                                    break
                                }
                            }
                        } else {
                            let error = NSError(domain: "", code: statusCode, userInfo: nil)
                            reject(error)
                        }
                    } else {
                        reject(response.result.error ?? NSError(domain: "", code: 0, userInfo: nil))
                    }
                } else {
                    ErrorLogManager.sharedManager.recordNonFatalError(withException: .NullPointer)
                }
            })
        }
    }
    
    private func createReportReview() -> Promise<Any> {
        return Promise { fulfill, reject in
            let skuReviewKey = self.skuReview != nil ? skuReview!.skuReviewKey : ""
            
            ReviewService.submitReportReview(reportReasonId: selectedReasonId, reportDescription: afterSalesDescription, skuReviewKey: skuReviewKey, completion: { [weak self] (response) -> Void in
                let statusCode = response.response?.statusCode ?? 0
                
                if let strongSelf = self {
                    if response.result.isSuccess {
                        if statusCode == 200 {
                            fulfill("OK")
                        } else {
                            strongSelf.handleApiResponseError(response, reject: reject)
                        }
                    } else {
                        reject(response.result.error ?? NSError(domain: "", code: 0, userInfo: nil))
                        strongSelf.showNetWorkErrorAlert(response.result.error)
                    }
                } else {
                    ErrorLogManager.sharedManager.recordNonFatalError(withException: .NullPointer)
                }
            })
            
        }
    }

    
    private func createOrderCancel() -> Promise<Any> {
        return Promise { fulfill, reject in
            OrderService.createOrderCancel(orderKey: (self.orderSectionData?.order!.orderKey)!, skuId: self.orderItem!.skuId, qty: self.afterSalesQuantity, orderCancelReasonId: self.selectedReason!.reasonId, description: self.afterSalesDescription, completion: { [weak self] (response) -> Void in
                let statusCode = response.response?.statusCode ?? 0
                
                if let strongSelf = self {
                    if response.result.isSuccess {
                        if statusCode == 200 {
                            if let orderCancel = Mapper<OrderCancel>().map(JSONObject: response.result.value) {
                                strongSelf.orderCancel = orderCancel
                            } else {
                                ErrorLogManager.sharedManager.recordNonFatalError(withException: .FailToParseAPIResponse)
                            }
                            
                            fulfill("OK")
                        } else {
                            strongSelf.handleApiResponseError(response, reject: reject)
                        }
                    } else {
                        reject(response.result.error ?? NSError(domain: "", code: 0, userInfo: nil))
                        strongSelf.showNetWorkErrorAlert(response.result.error)
                    }
                } else {
                    ErrorLogManager.sharedManager.recordNonFatalError(withException: .NullPointer)
                }
            })
        }
    }
    
    private func createOrderReturn(_ orderKey: String, merchantId: Int, skuId: Int, qty: Int, courierId: Int, orderReturnReasonId: Int, description: String, imageDatas: [Data]?) -> Promise<Any> {
        return Promise{ fulfill, reject in
            OrderService.createOrderReturn(orderKey: orderKey, merchantId: merchantId, skuId: skuId, qty: qty, courierId: courierId, orderReturnReasonId: orderReturnReasonId, description: description, images: imageDatas, success: { [weak self] (response) in
                let statusCode = response.response?.statusCode ?? 0
                
                if let strongSelf = self {
                    if response.result.isSuccess {
                        if statusCode == 200 {
                            if let orderActionResponse = Mapper<OrderActionResponse>().map(JSONObject: response.result.value) {
                                fulfill(orderActionResponse)
                            } else {
                                ErrorLogManager.sharedManager.recordNonFatalError(withException: .FailToParseAPIResponse)
                                fulfill("OK")
                            }
                        } else {
                            strongSelf.handleApiResponseError(response, reject: reject)
                        }
                    } else {
                        reject(response.result.error ?? NSError(domain: "", code: 0, userInfo: nil))
                    }
                } else {
                    ErrorLogManager.sharedManager.recordNonFatalError(withException: .NullPointer)
                }
            }, fail: { (error) in
                reject(error)
            })
        }
    }
    
    private func viewOrderReturn(orderReturnKey: String) -> Promise<Any> {
        return Promise { fulfill, reject in
            OrderService.viewOrderReturn(orderReturnKey: orderReturnKey, completion: { (response) in
                let statusCode = response.response?.statusCode ?? 0
                
                if response.result.isSuccess {
                    if statusCode == 200 {
                        if let orderReturn = Mapper<OrderReturn>().map(JSONObject: response.result.value) {
                            fulfill(orderReturn)
                        } else {
                            ErrorLogManager.sharedManager.recordNonFatalError(withException: .FailToParseAPIResponse)
                        }
                        
                        fulfill("OK")
                    } else {
                        let error = NSError(domain: "", code: statusCode, userInfo: nil)
                        reject(error)
                    }
                } else {
                    reject(response.result.error ?? NSError(domain: "", code: 0, userInfo: nil))
                }
            })
        }
    }
    
    private func updateOrderReturn(_ orderReturnKey: String, orderKey: String, merchantId: Int, skuId: Int, qty: Int, courierId: Int, orderReturnReasonId: Int = 0, orderDisputeReasonId: Int = 0, orderReturn: OrderReturn, description: String, orderReturnImages: [Data]?) -> Promise<Any> {
        return Promise{ fulfill, reject in
            OrderService.updateOrderReturn(orderReturnKey: orderReturnKey, orderKey: orderKey, merchantId: merchantId, skuId: skuId, qty: qty, courierId: courierId, orderReturnReasonId: orderReturnReasonId, orderDisputeReasonId: orderDisputeReasonId, orderReturn: orderReturn, description: description, images: orderReturnImages, success: { [weak self] (response) in
                let statusCode = response.response?.statusCode ?? 0
                
                if let strongSelf = self {
                    if response.result.isSuccess {
                        if statusCode == 200 {
                            if let orderActionResponse = Mapper<OrderActionResponse>().map(JSONObject: response.result.value) {
                                fulfill(orderActionResponse)
                            } else {
                                ErrorLogManager.sharedManager.recordNonFatalError(withException: .FailToParseAPIResponse)
                                fulfill("OK")
                            }
                        } else {
                            strongSelf.handleApiResponseError(response, reject: reject)
                        }
                    } else {
                        reject(response.result.error ?? NSError(domain: "", code: 0, userInfo: nil))
                    }
                } else {
                    ErrorLogManager.sharedManager.recordNonFatalError(withException: .NullPointer)
                }
            }, fail: { (error) in
                reject(error)
            })
        }
    }
    
    private func createOrderDispute(_ orderReturn: OrderReturn?, skuId: Int, qty: Int, orderDisputeReasonId: Int, description: String, images: [Data]?) -> Promise<Any> {
        return Promise{ fulfill, reject in
            OrderService.createOrderDispute(orderReturn: orderReturn, skuId: skuId, qty: qty, orderDisputeReasonId: orderDisputeReasonId, description: description, images: images, success: { [weak self] (response) in
                let statusCode = response.response?.statusCode ?? 0
                
                if let strongSelf = self {
                    if response.result.isSuccess {
                        if statusCode == 200 {
                            if let orderActionResponse = Mapper<OrderActionResponse>().map(JSONObject: response.result.value) {
                                fulfill(orderActionResponse)
                            } else {
                                ErrorLogManager.sharedManager.recordNonFatalError(withException: .FailToParseAPIResponse)
                            }
                            
                            fulfill("OK")
                        } else {
                            strongSelf.handleApiResponseError(response, reject: reject)
                        }
                    } else {
                        reject(response.result.error ?? NSError(domain: "", code: 0, userInfo: nil))
                    }
                } else {
                    ErrorLogManager.sharedManager.recordNonFatalError(withException: .NullPointer)
                }
            }, fail: { (error) in
                reject(error)
            })
        }
    }

	@objc func presetReportReviewOption() {
		if self.reasons.count > 0 && self.selectedReason == nil {
			let reason = self.reasons[0]
			self.selectedReason = reason
			self.selectedReasonId = reason.reportReasonId
			self.afterSalesReasonCell?.textField.text = reason.reportReasonName
			self.afterSalesReasonCell?.textField.textColor = UIColor.blackTitleColor()
		}
	}
	
    // Other func
	
    private func listAfterSalesReason() {
        switch currentViewType {
        case .cancel:
            listAfterSalesReasons(afterSalesType: .cancel)
        case .return:
            listAfterSalesReasons(afterSalesType: .`return`)
        case .dispute:
            listAfterSalesReasons(afterSalesType: .dispute)
        case .reportReview:
			NotificationCenter.default.addObserver(self, selector: #selector(AfterSalesViewController.presetReportReviewOption), name: Constants.Notification.reportReviewListShown, object: nil)
            
            self.showLoading()
            
            firstly {
                return self.listReportReviewReason()
            }.always {
                self.stopLoading()
            }
            
        default:
            break
        }
    }
    
    func setDataSourceWithOrderReturn(_ orderReturn: OrderReturn?) {
        self.orderReturn = orderReturn
        self.orderSectionData = OrderSectionData(sectionHeader: [], reuseIdentifier: OrderItemCell.CellIdentifier, dataSource: [])
        
        if let order = orderReturn?.order {
            order.orderReturns?.removeAll()
            order.orderReturns = [OrderReturn]()
            order.orderReturns?.append(orderReturn ?? OrderReturn())
            self.orderSectionData?.order = order
        } else {
            ErrorLogManager.sharedManager.recordNonFatalError(withException: .NullPointer)
        }
        
        if orderReturn?.orderReturnItems?.count > 0 {
            let orderReturnItem = orderReturn?.orderReturnItems?.first
            
            self.afterSalesQuantity = (orderReturnItem?.qtyReturned)!
            
            if orderReturn?.order?.orderItems?.count > 0 {
                let orderItem = orderReturn?.order?.orderItems?.filter( { return $0.skuId == orderReturnItem?.skuId } ).first
                
                if let _ = orderItem {
                    self.orderItem = orderItem
                } else {
                    ErrorLogManager.sharedManager.recordNonFatalError(withException: .NullPointer)
                }
            }
        }
    }
    
    // MARK: CollectionView
    
    func numberOfSections(in collectionView: UICollectionView) -> Int {
        return 1
    }
    
    override func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        switch currentViewType {
        case .cancel:
            return afterSalesDataList.count - 1
        case .return, .dispute, .reportReview:
            return afterSalesDataList.count
        default:
            return 0
        }
    }
    
    override func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        let afterSalesData = afterSalesDataList[indexPath.row]
        
        if afterSalesData.reuseIdentifier != nil {
            var cell = collectionView.dequeueReusableCell(withReuseIdentifier: afterSalesData.reuseIdentifier!, for: indexPath)
            
            switch afterSalesData.reuseIdentifier! {
            case OrderItemCell.CellIdentifier:
                let itemCell = cell as! OrderItemCell
                itemCell.data = orderItem
                itemCell.hidePriceLabel()
                itemCell.afterSaleQuantityLabel.isHidden = true
                itemCell.updateLayout()
                
                return itemCell
            case AfterSalesReasonCell.CellIdentifier:
                let itemCell = cell as! AfterSalesReasonCell
                itemCell.viewType = currentViewType
                
                if let selectedReason = self.selectedReason {
                    itemCell.textField.text = selectedReason.reportReasonName
                    itemCell.textField.textColor = UIColor.blackTitleColor()
                } else {
                     let emptyReasonText: String = EmptyReasonTexts[currentViewType.rawValue]
                    
                     itemCell.textField.placeholder = emptyReasonText
                    
                     itemCell.textField.textColor = UIColor.secondary1()
                }
                
                let afterSalesReasonInputView = AfterSalesReasonInputView(frame: CGRect(x: 0, y: 0, width: self.view.bounds.width, height: ReasonPickerHeight))
                reasonPicker = afterSalesReasonInputView.pickerView
                reasonPicker.delegate = self
                reasonPicker.dataSource = self
                
                itemCell.textField.inputView = afterSalesReasonInputView
                itemCell.textField.delegate = self
                reasonPicker.reloadAllComponents()
                itemCell.showBorder(true)
                
                afterSalesReasonInputView.didPressDone = {
                    itemCell.textField.resignFirstResponder()
                }
                
                afterSalesReasonCell = itemCell
                
                return itemCell
            case QuantityCellId:
                switch currentViewType {
                case .unknown:
                    cell = collectionView.dequeueReusableCell(withReuseIdentifier: AfterSalesAmountCell.CellIdentifier, for: indexPath)
                    let itemCell = cell as! QuantityCell
                    
                    itemCell.setSeparatorStyle(afterSalesData.hasBorder ? .afterSales : .none)
                    itemCell.qtyTextField.text = String(afterSalesQuantity)
                    
                    return itemCell
                case .cancel, .return, .dispute:
                    let itemCell = cell as! QuantityCell
                    
                    itemCell.minusStepButton.addTarget(self, action: #selector(AfterSalesViewController.stepperValueChanged), for: .touchUpInside)
                    itemCell.minusStepButton.accessibilityIdentifier = "icon_quatity_minus"
                    itemCell.minusStepButton.setImage(UIImage(named: "icon_order_quatity_minus"), for: UIControlState())
                    itemCell.minusStepButton.setTitle("", for: UIControlState())
                    
                    itemCell.addStepButton.addTarget(self, action: #selector(AfterSalesViewController.stepperValueChanged), for: .touchUpInside)
                    itemCell.addStepButton.accessibilityIdentifier = "icon_order_quatity_add"
                    itemCell.addStepButton.setImage(UIImage(named: "icon_order_quatity_add"), for: UIControlState())
                    itemCell.addStepButton.setTitle("", for: UIControlState())
                    
                    itemCell.qtyTextField.text = String(afterSalesQuantity)
                    itemCell.qtyValueLabel.text = String(afterSalesQuantity)
                    
                    if itemCell.qtyTextField.delegate == nil {
                        itemCell.qtyTextField.delegate = self
                    }
                    
                    itemCell.qtyTextField.keyboardType = .numberPad
                    itemCell.qtyTextField.accessibilityIdentifier = "checkout_quantity_textfield"
                    itemCell.setSeparatorStyle(.afterSales)
                    
                    self.quantityCell = itemCell
                    itemCell.qtyTextField.addTarget(self, action: #selector(AfterSalesViewController.quantityDidChanged), for: UIControlEvents.editingChanged)
                    
                    //Only display quantity value for creating dispute
                    itemCell.minusStepButton.isHidden = (currentViewType == .dispute)
                    itemCell.addStepButton.isHidden = (currentViewType == .dispute)
                    itemCell.qtyTextField.isHidden = (currentViewType == .dispute)
                    itemCell.qtyValueLabel.isHidden = (currentViewType != .dispute)
                    
                    return itemCell
                default:
                    return cell
                }
            case AfterSalesAmountCell.CellIdentifier:
                let itemCell = cell as! AfterSalesAmountCell
                
                var amountTitle: String = ""
                amountTitle = AmountTitles[currentViewType.rawValue]
                itemCell.titleLabel.text = amountTitle
                
                if itemCell.valueTextField.delegate == nil {
                    itemCell.valueTextField.delegate = self
                }
                
                itemCell.showBorder(afterSalesData.hasBorder)
                
                if let orderItem = self.orderItem {
                    itemCell.valueTextField.text = "\(orderItem.unitPrice * Double(afterSalesQuantity))"
                } else {
                    itemCell.valueTextField.text = ""
                }
                
                itemCell.valueTextField.keyboardType = .decimalPad
                itemCell.valueTextField.addTarget(self, action: #selector(AfterSalesViewController.amountDidChanged), for: UIControlEvents.editingChanged)
                
                afterSalesAmountCell = itemCell
                
                return itemCell
            case AfterSalesDescriptionCell.CellIdentifier:
                let itemCell = cell as! AfterSalesDescriptionCell
                
                itemCell.placeHolder = DescriptionPlaceholders[currentViewType.rawValue]
                itemCell.characterLimit = descriptionCharacterLimit
                itemCell.updateDescriptionCharactersCount(0)
                
                if afterSalesDescription.isEmpty {
                    var descriptionPlaceholder: String = ""
                    descriptionPlaceholder = DescriptionPlaceholders[currentViewType.rawValue]
                    itemCell.descriptionTextView.text = descriptionPlaceholder
                    itemCell.descriptionTextView.textColor = UIColor.secondary1()
                } else {
                    itemCell.descriptionTextView.text = afterSalesDescription // TODO: Duplicated?
                    itemCell.setDescriptionText(afterSalesDescription)
                    itemCell.descriptionTextView.textColor = UIColor.blackTitleColor()
                }
                
                itemCell.descriptionTextView.delegate = self
                
                afterSalesDescriptionTextView = itemCell.descriptionTextView
                afterSalesDescriptionCell = itemCell
                
                return itemCell
            case UploadPhotoCell.CellIdentifier:
                let itemCell = cell as! UploadPhotoCell
                itemCell.imageLimit = imageLimit
                itemCell.isAllowEdit = true
                
                itemCell.cameraTappedHandler = { [weak self] in
                    if let strongSelf = self {
                        strongSelf.addPhoto()
                    } else {
                        ErrorLogManager.sharedManager.recordNonFatalError(withException: .NullPointer)
                    }
                }
                
                self.uploadPhotoCell = itemCell
                
                return itemCell
            default:
                break
            }
        }
        
        return self.defaultCell(collectionView, cellForItemAt: indexPath)
    }
    
    private func defaultCell(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        return collectionView.dequeueReusableCell(withReuseIdentifier: DefaultCellID, for: indexPath)
    }
    
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, referenceSizeForHeaderInSection section: Int) -> CGSize {
        switch currentViewType {
        case .reportReview:
            return CGSize(width: view.width, height: 0)
        default:
            return CGSize(width: view.width, height: MerchantSectionHeaderView.DefaultHeight)
        }
    }
    
    func collectionView(_ collectionView: UICollectionView, viewForSupplementaryElementOfKind kind: String, at indexPath: IndexPath) -> UICollectionReusableView {
        let view = collectionView.dequeueReusableSupplementaryView(ofKind: kind, withReuseIdentifier: MerchantSectionHeaderView.ViewIdentifier, for: indexPath) as! MerchantSectionHeaderView
        view.backgroundColor = UIColor.white
        view.isEnablePaddingRight = true
        view.isEnablePaddingLeft = true
        view.showDisclosureIndicator(false)
        view.data = self.orderSectionData
        view.contentView?.frame = CGRect(x: 0, y: 0, width: view.frame.width, height: MerchantSectionHeaderView.DefaultHeight)
        
        return view
    }
    
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, minimumInteritemSpacingForSectionAt section: Int) -> CGFloat {
        return 0.0
    }
    
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, minimumLineSpacingForSectionAt section: Int) -> CGFloat {
        return 0.0
    }
    
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, sizeForItemAt indexPath: IndexPath) -> CGSize {
        return CGSize(width: view.frame.size.width, height: afterSalesDataList[indexPath.row].cellHeight)
    }
    
    // MARK: - Picker View Delegate
    
    func numberOfComponents(in pickerView: UIPickerView) -> Int {
        return 1
    }
    
    func pickerView(_ pickerView: UIPickerView, numberOfRowsInComponent component: Int) -> Int {
        if pickerView == reasonPicker {
            return reasons.count
        }
        
        return 0
    }
    
    func pickerView(_ pickerView: UIPickerView, titleForRow row: Int, forComponent component: Int) -> String? {
        if pickerView == reasonPicker && component == 0 && row < reasons.count {
            let reason = reasons[row]
            
            if currentViewType == .reportReview {
                return reason.reportReasonName
            }
            
            return reason.reasonName
        }
        
        return ""
    }
    
    func pickerView(_ pickerView: UIPickerView, didSelectRow row: Int, inComponent component: Int) {
        if pickerView == reasonPicker && component == 0 && row < reasons.count {
            selectedReason = reasons[row]
            
            if let selectedReason = selectedReason {
                selectedReasonId = selectedReason.reasonId
                afterSalesReasonCell?.textField.text = selectedReason.reasonName
                
                if currentViewType == .reportReview {
                    selectedReasonId = selectedReason.reportReasonId 
                    afterSalesReasonCell?.textField.text = selectedReason.reportReasonName
                }
            } else {
                ErrorLogManager.sharedManager.recordNonFatalError(withException: .NullPointer)
            }
            
            afterSalesReasonCell?.textField.textColor = UIColor.blackTitleColor()
        }
    }

    // ImagePickerManagerDelegate
	
    func didPickImage(_ image: UIImage!) {
        uploadPhotoCell?.addPhoto(OrderManager.normalizedOrderImage(image), imageKey: "")
    }
    
    // MARK: Text View Delegate
    
    func textViewDidChange(_ textView: UITextView) {
        if textView == self.afterSalesDescriptionTextView{
            afterSalesDescription = textView.text
            
            if let afterSalesDescriptionCell = self.afterSalesDescriptionCell {
                afterSalesDescriptionCell.updateDescriptionCharactersCount(afterSalesDescription.length)
            } else {
                ErrorLogManager.sharedManager.recordNonFatalError(withException: .NullPointer)
            }
        }
    }
    
    func textViewDidBeginEditing(_ textView: UITextView) {
        if textView == self.afterSalesDescriptionTextView {
            self.activeTextView = textView
            
            if afterSalesDescription.isEmpty {
                textView.text =  ""
            }
        }
    }
    
    func textViewDidEndEditing(_ textView: UITextView) {
        if textView == self.afterSalesDescriptionTextView {
            self.activeTextView = nil
            
            if afterSalesDescription.isEmpty {
                textView.text =  String.localize("LB_REFUND_DESC")
                textView.textColor = UIColor.secondary1()
            }
        }
    }
    
    func textView(_ textView: UITextView, shouldChangeTextIn range: NSRange, replacementText text: String) -> Bool {
        if textView == self.afterSalesDescriptionTextView {
            let currentText = textView.text as NSString
            let proposedText = currentText.replacingCharacters(in: range, with: text)
            
            if proposedText.count > descriptionCharacterLimit {
                return false
            }
        }
        
        return true
    }
    
    // MARK: - Text Field Delegate
    
    func textField(_ textField: UITextField, shouldChangeCharactersIn range: NSRange, replacementString string: String) -> Bool {
        if let amountCell = self.afterSalesAmountCell {
            if textField == amountCell.valueTextField {
                var textResult: NSString? = textField.text as NSString?
                if textResult != nil && textResult!.length > 0 {
                    textResult = textResult!.replacingCharacters(in: range, with: string) as NSString?
                    
                    var arraySplit = textResult!.components(separatedBy: ".")
                    
                    if arraySplit.count > 2 {
                        // More than 2 dot signs in number doesn't allow
                        return false
                    } else if arraySplit.count == 2 {
                        // Allow Max number after dot is 2
                        let numberAfterDot = arraySplit[1]
                        if numberAfterDot.length > 2 {
                            return false
                        }
                    }
                }
            }
        } else {
            ErrorLogManager.sharedManager.recordNonFatalError(withException: .NullPointer)
        }

        return true
    }
    
    func textFieldDidBeginEditing(_ textField: UITextField) {
        if let afterSalesReasonCell = afterSalesReasonCell {
            if textField == afterSalesReasonCell.textField {
                if selectedReason == nil && reasons.count > 0 {
                    selectedReason = reasons.first
                    
                    if let selectedReason = selectedReason {
                        if currentViewType == .reportReview {
                            afterSalesReasonCell.textField.text = selectedReason.reportReasonName
                        } else {
                            afterSalesReasonCell.textField.text = selectedReason.reasonName
                        }
                    }
                    
                    afterSalesReasonCell.textField.textColor = UIColor.blackTitleColor()
                }
            }
        } else {
            ErrorLogManager.sharedManager.recordNonFatalError(withException: .NullPointer)
        }
    }
    
    @objc func quantityDidChanged(_ textField: UITextField) {
        if let _ = self.quantityCell {
            var qtyValue = 1
            if textField.text?.length > 0 {
                if let quantityValue = Int(textField.text!) {
                    qtyValue = quantityValue
                }
            }
            
            self.updateQuantityValue(qtyValue)
        } else {
            ErrorLogManager.sharedManager.recordNonFatalError(withException: .NullPointer)
        }
    }
    
    @objc func amountDidChanged(_ textField: UITextField) {
        if let _ = self.afterSalesAmountCell, let textFieldValue = textField.text {
            self.updateAmountValue(valueText: textFieldValue)
        } else {
            self.updateAmountValue(valueText: "0")
        }
    }
    
    // MARK: Observer
    
    override func keyboardWillShowNotification(_ notification: NSNotification) {
        super.keyboardWillShowNotification(notification)
        
        if let keyboardInfoKey = notification.userInfo?[UIKeyboardFrameEndUserInfoKey] {
            let contentInsets = UIEdgeInsets(top: 0.0, left: 0.0, bottom: (keyboardInfoKey as! NSValue).cgRectValue.size.height - SummaryViewHeight, right: 0.0)
            
            collectionView.contentInset = contentInsets
            collectionView.scrollIndicatorInsets = contentInsets
            
            if let activeTextView = self.activeTextView {
                let rect = collectionView.convert(activeTextView.bounds, from: activeTextView)
                collectionView.scrollRectToVisible(rect, animated: false)
            } else {
                ErrorLogManager.sharedManager.recordNonFatalError(withException: .NullPointer)
            }
        } else {
            ErrorLogManager.sharedManager.recordNonFatalError(withException: .NullPointer)
        }
    }
    
    override func keyboardWillHideNotification(_ notification: NSNotification) {
        super.keyboardWillHideNotification(notification)
        
        collectionView.contentInset = UIEdgeInsets.zero
        collectionView.scrollIndicatorInsets = UIEdgeInsets.zero
        collectionView.reloadData()
    }

    // MARK: - Helpers
    
    private func getNewOrderReturnPhotoDatas() -> [Data] {
        var photoDatas = [Data]()
        for orderReturnImageView in (self.uploadPhotoCell?.getPhotos())! {
            let imageData = UIImageJPEGRepresentation(orderReturnImageView.imageView.image! , Constants.CompressionRatio.JPG_COMPRESSION)
            photoDatas.append(imageData!)
        }
        
        return photoDatas
    }
    
    func getHeightErrorView() -> CGFloat {
        var height: CGFloat = 40
        
        if self.navigationController == nil && self.navigationController?.isNavigationBarHidden == true {
            height = 60
        }
        
        return height
    }
    
    func incorrectViewShow(_ isShow: Bool) {
        if currentViewType == .reportReview && isShow {
            UIView.animate(withDuration: 0.3, animations: {
                self.collectionView.transform = CGAffineTransform(translationX: 0, y: self.getHeightErrorView())
            })
        } else {
            UIView.animate(withDuration: 0.3, animations: {
                self.collectionView.transform = CGAffineTransform.identity
            })
        }
    }
    
}
