//
//  AfterSalesHistoryViewController.swift
//  merchant-ios
//
//  Created by Gambogo on 4/14/16.
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


protocol AfterSalesHistoryViewProtocol: NSObjectProtocol {
    func didCancelOrderDisputeFromAfterSalesHistory(_ isSuccess: Bool)
    func didDisputeOrderFromAfterSalesHistory(_ isSuccess: Bool)
}

class AfterSalesHistoryViewController: MmViewController, AfterSalesViewProtocol {
    
    enum AfterSalesActionType: Int {
        case cancel = 0,
        dispute
    }

    let AfterSalesActionLabels = [
        String.localize("LB_CA_RTN_CANCEL"),
        String.localize("LB_CA_OMS_DISPUTE_APP")
    ]
    
    private let ActionViewVerticalPadding: CGFloat = 10
    
    var order: Order?
    var afterSalesKey: String?
    var inventoryLocation: InventoryLocation? = nil
    var originalViewMode: Constants.OmsViewMode = .all
    
    private var historySections: [Any] = []
    private var bottomActionView: UIView? = nil
    
    private var afterSalesType: Constants.OMSAfterSalesType = .cancel
    private var afterSalesActionTypes: [AfterSalesActionType] = []
    
    private var orderReturn: OrderReturn?
    
    private var cancelReasons = [BaseReason]()
    private var returnReasons = [BaseReason]()
    private var disputeReasons = [BaseReason]()
    
    var orderSectionData: OrderSectionData? = nil
    
    var orderDisplayStatus: Constants.OrderDisplayStatus = .unknown {
        didSet {
            afterSalesActionTypes.removeAll()
            
            switch orderDisplayStatus {
            case .returnRequestSubmitted, .disputeOpen:
                afterSalesActionTypes.append(.cancel)
            case .returnRejected, .returnRequestRejected, .disputeDeclined, .disputeRejected:
                afterSalesActionTypes.append(.dispute)
            default:
                break
            }
            
            switch orderDisplayStatus {
            case .refundAccepted, .orderClosed:
                afterSalesType = .cancel
            case .returnRequestSubmitted, .returnRequestAuthorised, .returnRequestRejected, .returnAccepted, .returnRejected, .returnRequestDeclinedCanNotDispute, .returnRequestRejectedCanNotDispute:
                afterSalesType = .return
            case .disputeOpen, .disputeInProgress, .disputeAccepted, .disputeDeclined, .disputeRejected:
                afterSalesType = .dispute
            default:
                break
            }
        }
    }

    weak var delegate: AfterSalesHistoryViewProtocol?
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        self.view.backgroundColor = UIColor.primary2()
        
        switch afterSalesType {
        case .dispute:
            self.title = String.localize("LB_CA_POSTSALE")
        default:
            self.title = String.localize("LB_CA_REFUND")
        }
        
        if afterSalesActionTypes.count > 0 {
            createBottomActionView()
        }
        
        setupCollectionView()
        createBackButton()
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        
        loadHistoryData()
    }
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
    }

    // MARK: - Data Processing
    
    private func listAfterSalesHistory(_ orderKey: String) -> Promise<Any> {
        var afterSalesHistoryType: OrderService.AfterSalesHistoryType = .cancel
        
        switch afterSalesType {
        case .cancel:
            afterSalesHistoryType = .cancel
        case .return, .dispute:
            afterSalesHistoryType = .return
        }
        
        return Promise{ fulfill, reject in
            OrderService.listAfterSalesHistory(orderKey: orderKey, afterSalesHistoryType: afterSalesHistoryType, completion: { (response) in
                let statusCode = response.response?.statusCode ?? 0
                
				if response.result.isSuccess {
					if statusCode == 200 {
						if let afterSalesHistory = Mapper<AfterSalesHistory>().map(JSONObject: response.result.value) {
							fulfill(afterSalesHistory)
                        } else {
                            ErrorLogManager.sharedManager.recordNonFatalError(withException: .FailToParseAPIResponse)
                            fulfill(AfterSalesHistory())
                        }
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
	
    private func cancelOrderReturn(key orderReturnKey: String) -> Promise<Any> {
        return Promise{ fulfill, reject in
            OrderService.cancelOrderReturn(orderReturnKey: orderReturnKey, completion: { [weak self] (response) in
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
			})
        }
    }
    
    // MARK: - Setup
    
    private func setupCollectionView() {
        collectionView.backgroundColor = UIColor.clear
        collectionView.register(AfterSalesHistoryTimeHeaderView.self, forSupplementaryViewOfKind: UICollectionElementKindSectionHeader, withReuseIdentifier: AfterSalesHistoryTimeHeaderView.ViewIdentifier)
        collectionView.register(AfterSalesHistoryCell.self, forCellWithReuseIdentifier: AfterSalesHistoryCell.CellIdentifier)
        
        collectionView.backgroundColor = UIColor.primary2()
        
        setupCollectionViewFrame()
    }
    
    private func setupCollectionViewFrame() {
        var yPos: CGFloat = 0
        
        if let navigationBar = self.navigationController?.navigationBar {
            yPos = navigationBar.frame.maxY
        } else {
            ErrorLogManager.sharedManager.recordNonFatalError(withException: .NullPointer)
        }
        
        var actionViewHeight: CGFloat = 0
        
        if let bottomActionView = self.bottomActionView {
            actionViewHeight = bottomActionView.height
        }
        
        collectionView.frame = CGRect(x: 0, y: yPos, width: ScreenWidth, height: ScreenHeight - (yPos + tabBarHeight + actionViewHeight))
    }
    
    private func createBottomActionView() {
        bottomActionView?.removeFromSuperview()

        if afterSalesActionTypes.count == 0{
            bottomActionView = nil
            return
        }
        
        let horizontalPadding: CGFloat = 20
        let buttonWidth: CGFloat = 90
        let paddingBetweenButtons: CGFloat = 20
        
        bottomActionView = UIView(frame: CGRect(x: 0, y: view.height - Constants.ActionButton.Height - (ActionViewVerticalPadding * 2), width: view.width, height: Constants.ActionButton.Height + (ActionViewVerticalPadding * 2)))
        bottomActionView!.backgroundColor = UIColor.white
        
        let topBorderLine = UIView(frame: CGRect(x: 0, y: 0, width: bottomActionView!.width, height: 1))
        topBorderLine.backgroundColor = UIColor.backgroundGray()
        bottomActionView!.addSubview(topBorderLine)
        
        var currentButtonFrame = CGRect(x: bottomActionView!.width - buttonWidth - horizontalPadding, y: ActionViewVerticalPadding, width: buttonWidth, height: Constants.ActionButton.Height)
        
        for index in stride(from: (0), through: afterSalesActionTypes.count - 1, by: +1) {
            let actionButton = ActionButton(frame: currentButtonFrame)
            actionButton.setTitle(AfterSalesActionLabels[afterSalesActionTypes[index].rawValue], for: UIControlState())
            actionButton.touchUpClosure = { _ in
                switch self.afterSalesActionTypes[index] {
                case .cancel:
                    Alert.alert(self, title: String.localize("LB_CA_CONFIRM_CANCEL"), message: "", okActionComplete: { () -> Void in
                        switch self.orderDisplayStatus {
                        case .returnRequestSubmitted, .returnRequestAuthorised:
                            self.cancelReturnRequest()
                        case .disputeOpen:
                            self.cancelDisputeRequest()
                        default:
                            break
                        }
                    })
                case .dispute:
                    self.createDisputeRequest()
                }
            }
            
            bottomActionView!.addSubview(actionButton)
            currentButtonFrame.originX = currentButtonFrame.originX - buttonWidth - paddingBetweenButtons
        }
        
        self.view.addSubview(bottomActionView!)
    }
    
    // MARK: - Load data
    
    private func loadHistoryData() {
        if let order = order {
            var orderItemMap: [String: OrderItem] = [String: OrderItem]()
            for orderItem in order.orderItems ?? [] {
                orderItemMap["\(orderItem.skuId)"] = orderItem
            }
            
            if afterSalesType == .cancel {
                loadCancelHistory()
            } else {
                loadReturnHistory()
            }
        } else {
            ErrorLogManager.sharedManager.recordNonFatalError(withException: .NullPointer)
        }
    }
    
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
                                    strongSelf.cancelReasons = cancelReasons
                                } else {
                                    ErrorLogManager.sharedManager.recordNonFatalError(withException: .FailToParseAPIResponse)
                                }
                            case .`return`:
                                if let returnReasons: Array<OrderReturnReason> = Mapper<OrderReturnReason>().mapArray(JSONObject: response.result.value) {
                                    strongSelf.returnReasons = returnReasons
                                } else {
                                    ErrorLogManager.sharedManager.recordNonFatalError(withException: .FailToParseAPIResponse)
                                }
                            case .dispute:
                                if let disputeReasons: Array<OrderDisputeReason> = Mapper<OrderDisputeReason>().mapArray(JSONObject: response.result.value) {
                                    strongSelf.disputeReasons = disputeReasons
                                } else {
                                    ErrorLogManager.sharedManager.recordNonFatalError(withException: .FailToParseAPIResponse)
                                }
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
                            fulfill("OK")
                        }
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
    
    private func loadInventoryLocation(merchantId: Int, locationExternalCode: String) -> Promise<Any> {
        return Promise { fulfill, reject in
            InventoryService.viewLocation(merchantId: merchantId, locationExternalCode: locationExternalCode, completion: { (response) in
                let statusCode = response.response?.statusCode ?? 0
                
                if response.result.isSuccess {
                    if statusCode == 200 {
                        if let inventoryLocation = Mapper<InventoryLocation>().map(JSONObject: response.result.value) {
                            fulfill(inventoryLocation)
                        } else {
                            ErrorLogManager.sharedManager.recordNonFatalError(withException: .FailToParseAPIResponse)
                            fulfill("OK")
                        }
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
    
    private func loadCancelHistory() {
        if let order = order {
            if let orderCancelKey = afterSalesKey {
                showLoading()
                
                firstly {
                    return self.listAfterSalesReasons(afterSalesType: .cancel)
                }.then { _ -> Promise<Any> in
                    return self.listAfterSalesHistory(order.orderKey)
                }.then { afterSalesHistory -> Void in
                    self.historySections = []
                    
                    if let afterSalesHistory = afterSalesHistory as? AfterSalesHistory {
                        let orderCancels = (afterSalesHistory.order?.orderCancels ?? []).filter{ $0.orderCancelKey == orderCancelKey }
                        let orderHistories = (afterSalesHistory.orderHistory ?? []).filter{ $0.entityId == orderCancelKey }
                        
                        if let orderCancel = orderCancels.first {
                            for orderHistory in orderHistories {
                                let notificationEvent = Constants.NotificationEvent.getCancelEnumType(orderHistory.orderHistoryTypeId)
                                let data = AfterSalesHistoryData(notificationEventId: notificationEvent, historyTime: orderHistory.lastCreated)
                                data.order = afterSalesHistory.order
                                data.orderCancel = orderCancel
                                data.cancelReason = self.getReasonNameWithId(orderCancel.orderCancelReasonId, inReasons: self.cancelReasons)
                                data.createPatternContent(data.notificationEventId)
                                
                                self.historySections.append(data)
                            }
                        } else {
                            ErrorLogManager.sharedManager.recordNonFatalError(withException: .DataIsEmpty)
                        }
                    } else {
                        ErrorLogManager.sharedManager.recordNonFatalError(withException: .NullPointerOrTypeMismatch)
                    }
                    
                    self.collectionView.reloadData()
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
    }
    
    private func loadReturnHistory() {
        if let order = order {
            if let orderReturnKey = afterSalesKey {
                if let orderReturn = order.orderReturns?.filter({ $0.orderReturnKey == afterSalesKey }).first {
                    showLoading()
                    
                    firstly {
                        return self.listAfterSalesReasons(afterSalesType: .`return`)
                    }.then { _ -> Promise<Any> in
                        return self.listAfterSalesReasons(afterSalesType: .dispute)
                    }.then { _ -> Promise<Any> in
                        if orderReturn.locationExternalCode.length > 0 {
                            return self.loadInventoryLocation(merchantId: order.merchantId, locationExternalCode: orderReturn.locationExternalCode)
                        } else {
                            return Promise { fulfill, reject in
                                fulfill("OK")
                            }
                        }
                    }.then { inventoryLocation -> Promise<Any> in
                        if let location = inventoryLocation as? InventoryLocation {
                            self.inventoryLocation = location
                        } else {
                            ErrorLogManager.sharedManager.recordNonFatalError(withException: .NullPointerOrTypeMismatch)
                        }
                        
                        return self.listAfterSalesHistory(self.order?.orderKey ?? "")
                    }.then { afterSalesHistory -> Void in
                        self.historySections = []
                        
                        if let afterSalesHistory = afterSalesHistory as? AfterSalesHistory {
                            if let innerOrder = afterSalesHistory.order {
                                if innerOrder.orderReturns != nil {
                                    let innerOrderReturns = innerOrder.orderReturns!.filter{ $0.orderReturnKey == orderReturnKey }
                                    
                                    if let orderHistories = innerOrderReturns.first?.getSortedOrderHistories() {
                                        for orderHistory in orderHistories {
                                            let notificationEvent = Constants.NotificationEvent.getReturnEnumType(orderHistory.orderReturnStatusCode)
                                            
                                            if notificationEvent.isShow(){
                                                let data = AfterSalesHistoryData(notificationEventId: notificationEvent, historyTime: orderHistory.lastCreated)
                                                data.order = innerOrder
                                                data.orderReturn = orderReturn
                                                data.inventoryLocation = self.inventoryLocation
                                                data.orderReturnHistoryKey = orderHistory.orderReturnHistoryKey
                                                data.returnReason = self.getReasonNameWithId(orderHistory.orderReturnReasonId, inReasons: self.returnReasons)
                                                data.disputeReason = self.getReasonNameWithId(orderHistory.orderDisputeReasonId, inReasons: self.disputeReasons)
                                                
                                                let orderReturnImageKeys = [orderHistory.image1 , orderHistory.image2 , orderHistory.image3]
                                                
                                                for imageKey in orderReturnImageKeys {
                                                    if !imageKey.isEmpty {
                                                        data.photoList.append(imageKey)
                                                    }
                                                }
                                                
                                                data.createPatternContent(data.notificationEventId)
                                                
                                                self.historySections.append(data)
                                            }
                                        }
                                    } else {
                                        ErrorLogManager.sharedManager.recordNonFatalError(withException: .NullPointer)
                                    }
                                    
                                    //self.updateAfterSalesActionTypes(innerOrderReturns.first)
                                    
                                } else {
                                    ErrorLogManager.sharedManager.recordNonFatalError(withException: .NullPointer)
                                }
                            } else {
                                ErrorLogManager.sharedManager.recordNonFatalError(withException: .NullPointer)
                            }
                        } else {
                            ErrorLogManager.sharedManager.recordNonFatalError(withException: .NullPointerOrTypeMismatch)
                        }
                        
                        self.collectionView.reloadData()
                        self.scrollToLatestHistoryData()
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
    }
    
    private func scrollToLatestHistoryData(){
        if self.historySections.count > 0 {
            let indexPath = IndexPath(row: 0, section: self.historySections.count - 1)
            self.collectionView.scrollToItem(at: indexPath, at: UICollectionViewScrollPosition.bottom, animated: true)
        }
    }
    
    // MARK: - Action
    
    func cancelReturnRequest() {
        showLoading()
        
        if let orderSectionData = orderSectionData {
            if let order = orderSectionData.order {
                if let orderReturn = order.orderReturns?.first {
                    firstly {
                        return cancelOrderReturn(key: orderReturn.orderReturnKey)
                    }.then { _ -> Void in
                        self.backAfterCancelAfterSalesRequest(order: order)
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
    }
    
    func cancelDisputeRequest() {
        showLoading()
        
        if let orderSectionData = orderSectionData {
            if let order = orderSectionData.order {
                if let orderReturn = order.orderReturns?.first {
                    firstly {
                        return cancelOrderReturn(key: orderReturn.orderReturnKey)
                    }.then { orderActionResponse -> Promise<Any> in
                        let orderActionResponse = orderActionResponse as? OrderActionResponse
                        return self.viewOrderReturn(orderReturnKey: (orderActionResponse?.entityId ?? ""))
                    }.then { [weak self] orderReturn -> Void in
                        if let orderReturn = orderReturn as? OrderReturn {
                            if let strongSelf = self {
                                strongSelf.orderReturn = orderReturn
                                strongSelf.backAfterCancelAfterSalesRequest(order: order, orderReturn: orderReturn)
                            }
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
    }
    
    func createDisputeRequest() {
        let afterSalesViewController = AfterSalesViewController()
        afterSalesViewController.currentViewType = .dispute
        afterSalesViewController.orderSectionData = orderSectionData
        
        if orderSectionData?.order?.orderReturns?.count > 0 {
            let orderReturn = orderSectionData?.order?.orderReturns?.first
            
            if orderReturn?.orderReturnStatus == .disputeRejected {
                self.showErrorAlert(String.localize("MSG_ERR_INVALID_ORDER_RETURN_STATUS"))
                return
            }
            
            if orderReturn?.order == nil {
                orderReturn?.order = orderSectionData?.order
            }
            
            afterSalesViewController.setDataSourceWithOrderReturn(orderReturn)
        }
        
        afterSalesViewController.delegate = self
        
        let navigationController = MmNavigationController(rootViewController: afterSalesViewController)
        present(navigationController, animated: true, completion: nil)
    }
    
    // MARK: - Navigation
    
    func backAfterCancelAfterSalesRequest(order: Order, orderReturn: OrderReturn? = nil) {
        if let viewControllers = self.navigationController?.viewControllers {
            for i in 0..<viewControllers.count {
                if let orderManagementCollectionViewController = viewControllers[i] as? OrderManagementCollectionViewController {
                    if let _ = order.orderItems?.first {
                        if let orderDetailViewController = viewControllers[i + 1] as? OrderDetailViewController {                            
                            if orderReturn != nil {
                                if order.orderReturns != nil && order.orderReturns?.count > 0 {
                                    self.delegate?.didCancelOrderDisputeFromAfterSalesHistory(true)
                                    _ = self.navigationController?.pop(to: orderDetailViewController, animated: true)
                                } else {
                                    orderManagementCollectionViewController.defaultViewMode = originalViewMode
                                    _ = self.navigationController?.pop(to: orderManagementCollectionViewController, animated: true)
                                }
                            } else {
                                orderDetailViewController.reloadAfterCancelOrderReturn(true)
                                _ = self.navigationController?.pop(to: orderDetailViewController, animated: true)
                            }
                        } else {
                            self.navigationController?.popViewController(animated: true)
                        }
                    } else {
                        orderManagementCollectionViewController.defaultViewMode = self.originalViewMode
                        _ = self.navigationController?.pop(to: orderManagementCollectionViewController, animated: true)
                    }
                    
                    break
                }
            }
        } else {
            ErrorLogManager.sharedManager.recordNonFatalError(withException: .NullPointer)
        }
    }
    
    // MARK: - Collection View Data Source methods
    
    func numberOfSections(in collectionView: UICollectionView) -> Int {
        return self.historySections.count
    }
    
    override func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return 1
    }
    
    override func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        let cell = collectionView.dequeueReusableCell(withReuseIdentifier: AfterSalesHistoryCell.CellIdentifier, for: indexPath) as! AfterSalesHistoryCell
        cell.data = historySections[indexPath.section] as? AfterSalesHistoryData
        
        return cell
    }
    
    func collectionView(_ collectionView: UICollectionView, viewForSupplementaryElementOfKind kind: String, at indexPath: IndexPath) -> UICollectionReusableView {
        let afterSalesHistoryData = self.historySections[indexPath.section] as! AfterSalesHistoryData
        
        let view = collectionView.dequeueReusableSupplementaryView(ofKind: kind, withReuseIdentifier: AfterSalesHistoryTimeHeaderView.ViewIdentifier, for: indexPath) as! AfterSalesHistoryTimeHeaderView
        view.timeValue = afterSalesHistoryData.historyTime
        return view
    }
    
    // MARK: - Collection View Delegate (Flow Layout) methods
    
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, insetForSectionAt section: Int) -> UIEdgeInsets {
        return UIEdgeInsets.zero
    }
    
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, referenceSizeForHeaderInSection section: Int) -> CGSize {
        return CGSize(width: view.width, height: AfterSalesHistoryTimeHeaderView.DefaultHeight)
    }
    
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, minimumInteritemSpacingForSectionAt section: Int) -> CGFloat {
        return 0.0
    }
    
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, minimumLineSpacingForSectionAt section: Int) -> CGFloat {
        return 0.0
    }
    
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, sizeForItemAt indexPath: IndexPath) -> CGSize {
        if let data = historySections[indexPath.section] as? AfterSalesHistoryData {
            return AfterSalesHistoryCell.getSizeAfterSalesHistoryCell(data, cellWidth: view.width)
        } else {
            ErrorLogManager.sharedManager.recordNonFatalError(withException: .NullPointerOrTypeMismatch)
        }
        
        return CGSize.zero
    }
    
    // MARK: - AfterSalesViewProtocol
    
    func didCancelOrder(_ isSuccess: Bool, orderItem: OrderItem?, orderCancel: OrderCancel?) {
        
    }
    
    func didReturnOrder(_ isSuccess: Bool, orderItem: OrderItem?, orderReturn: OrderReturn?) {
        
    }
    
    func didDisputeOrder(_ isSuccess: Bool, orderItem: OrderItem?, orderReturn: OrderReturn?) {
        for viewController in (self.navigationController?.viewControllers)! {
            if let orderDetailViewController = viewController as? OrderDetailViewController {
                _ = self.navigationController?.pop(to: orderDetailViewController, animated: true)
                break
            }
        }
        
        if let orderReturn = orderReturn {
            orderDisplayStatus = OrderManager.orderDisplayStatus(orderReturn: orderReturn)
            
            if self.order != nil {
                if self.order!.orderReturns == nil {
                    self.order!.orderReturns = [OrderReturn]()
                }
                self.order!.orderReturns!.removeAll()
                self.order!.orderReturns!.append(orderReturn)
            } else {
                ErrorLogManager.sharedManager.recordNonFatalError(withException: .NullPointer)
            }
        } else {
            ErrorLogManager.sharedManager.recordNonFatalError(withException: .NullPointer)
        }
        
        createBottomActionView()
        setupCollectionViewFrame()
        
        self.loadHistoryData()
        
        delegate?.didDisputeOrderFromAfterSalesHistory(isSuccess)
    }
    
    func didSubmitReportReview(_ isSuccess: Bool) {
        
    }
    
    // MARK: - Helper
    
    private func getReasonNameWithId(_ reasonId: Int, inReasons reasons: [BaseReason]) -> String {
        let filteredReasons = reasons.filter({$0.reasonId == reasonId})
        
        if let reason = filteredReasons.first {
            return reason.reasonName
        } else {
            ErrorLogManager.sharedManager.recordNonFatalError(withException: .DataIsEmpty)
        }
        
        return ""
    }
    
    private func updateAfterSalesActionTypes(_ orderReturn: OrderReturn?){
        guard let orderReturn = orderReturn else{
            return
        }
        
        let orderDisplayStatus = OrderManager.orderDisplayStatus(orderReturn: orderReturn)
        
        switch orderDisplayStatus {
        case .returnRequestRejected, .returnRejected, .disputeDeclined, .disputeRejected:
            break
        default:
            return
        }
        
        var latestOrderReturnHistory: OrderReturnHistory?
        
        switch orderReturn.orderReturnStatus{
        case .returnRequestRejected:
            latestOrderReturnHistory = orderReturn.getLastestOrderHistory(notificationEvent: Constants.NotificationEvent.returnRequestRejected)
            break
        case .returnRejected:
            latestOrderReturnHistory = orderReturn.getLastestOrderHistory(notificationEvent: Constants.NotificationEvent.returnRejected)
            break
        case .disputeDeclined:
            latestOrderReturnHistory = orderReturn.getLastestOrderHistory(notificationEvent: Constants.NotificationEvent.disputeDeclined)
            break
        case .disputeRejected:
            latestOrderReturnHistory = orderReturn.getLastestOrderHistory(notificationEvent: Constants.NotificationEvent.disputeRejected)
            break
        default:
            break
        }
        
        if let orderHistory = latestOrderReturnHistory{
            afterSalesActionTypes.removeAll()
            
            let duration = orderHistory.lastCreated.isDaysAgo()
            if duration < 3{
                afterSalesActionTypes.append(.dispute)
            }
            
            createBottomActionView()
            setupCollectionViewFrame()
        }
    }
}
