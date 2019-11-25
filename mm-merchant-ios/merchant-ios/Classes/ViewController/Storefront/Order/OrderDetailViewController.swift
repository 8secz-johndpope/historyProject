//
//  OrderDetailViewController.swift
//  merchant-ios
//
//  Created by Quang Truong Dinh on 4/4/16.
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


protocol OrderDetailViewControllerDelegate: class {
    func didRequestSwitchViewMode(orderDetailViewController: OrderDetailViewController, viewMode: Constants.OmsViewMode)
    func didUpdateOrder(orderDetailViewController: OrderDetailViewController, order: Order)
}

class OrderDetailViewController: OrderBaseViewController, OrderActionCellDelegate, AfterSalesViewProtocol, AfterSalesHistoryViewProtocol, OrderReviewViewControllerDelegate {
    
    enum SectionHeader: Int {
        case reminder = 0,
        action,
        receiverAddress,
        orderShipment,
        orderInfoHeader,
        orderInfo,
        orderPaymentHeader,
        orderPaymentInfo,
        orderAction,
        merchant,
        price
    }
    
    private final let OrderDetailHeaderID = "OrderDetailHeaderID"
    private final let OrderActionCellHeight: CGFloat = 50
    
    private let CellHeight: CGFloat = 0
    
    private var bottomActionButtonView: ActionButtonView?
    
    private var timelineStatus: OrderStatusHeaderView.TimelineStatus = .unknown
    private var addressData: AddressData?
    private var shipmentAddressData: AddressData?
    private var orderActionData: OrderActionData?
    private var orderSections = [(section: SectionHeader, data: Any)]()
    private var order: Order?
    
    var originalViewMode: Constants.OmsViewMode = .all
    weak var delegate: OrderDetailViewControllerDelegate?
    
    var orderSectionData: OrderSectionData? = nil {
        didSet {
            if let orderSectionData = self.orderSectionData {
                if let order = orderSectionData.order {
                    setupSectionOrders(orderSectionDataList: splitOrder(order))
                } else {
                    ErrorLogManager.sharedManager.recordNonFatalError(withException: .NullPointer)
                }
            } else {
                ErrorLogManager.sharedManager.recordNonFatalError(withException: .NullPointer)
            }
        }
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        self.title = String.localize("LB_CA_ORDER_DTL")
        
        if let viewMode = self.ssn_Arguments["viewMode"]?.int, let mode = Constants.OmsViewMode(rawValue: viewMode) {
            self.originalViewMode = mode
        }
        if let orderKey = self.ssn_Arguments["orderKey"]?.string {
            loadOrderInfo(orderKey:orderKey)
        }
        
        setupCollectionView()
        setupBottomView()
        createBackButton()
    }
    
    func isMerchantOrderKey(orderKey:String) -> Bool {
        if orderKey.count > 3 {
            let str = orderKey.subStringFromIndex(orderKey.count - 3).lowercased()
            if str.containCharactor() {
                return true
            }
        }
        
        //这个是最后的手段，但是非常糟糕
        if orderKey.count >= 17 {
            return true
        }
        
        return false
    }
    
    func loadOrderInfo(orderKey:String) {
        var parentOrderKey = orderKey
        if isMerchantOrderKey(orderKey:orderKey) {
            parentOrderKey = orderKey.subStringToIndex(orderKey.count - 3)
        }
        OrderService.viewMetaOrder(parentOrderKey) { (response) in
            if response.result.isSuccess {
                if response.response?.statusCode == 200 {
                    if let parentOrder = Mapper<ParentOrder>().map(JSONObject: response.result.value), let order = parentOrder.orders?.first {
                        self.orderSectionData = OrderManager.buildOrderSectionData(withOrder: order,viewMode:self.originalViewMode)
                        //重新设置bottom
                        self.setupBottomView()
                        self.collectionView.reloadData()
                    }
                }
            }
        }
    
    }
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
    }
    
    // MARK: - Setup
    
    private func setupSectionOrders(orderSectionDataList: [OrderSectionData]) {
        orderSections.removeAll()
        
        // Section - Detail Call doens't have items
        orderSections.append((section: .reminder, data: []))
        
        // Section - Action Header doesn't have items
        orderSections.append((section: .action, data: []))
        
        if let orderSectionData = self.orderSectionData {
            if let order = orderSectionData.order {
                if let orderShipment = orderSectionData.orderShipment{
                    self.addressData = AddressData(order: order) //Using address data in order level
                    //TODO: Fix MM-24638
                    if orderShipment.orderShipmentStatus != Shipment.OrderShipmentStatus.toShipToConsolidationCentre{
                        self.shipmentAddressData = AddressData(orderShipment: orderShipment)
                    }
                    
                } else {
                    self.addressData = AddressData(order: orderSectionData.order!)
                }
                
                // Section - Receiver Address
                orderSections.append((section: .receiverAddress, data: [self.addressData!]))
            } else {
                ErrorLogManager.sharedManager.recordNonFatalError(withException: .NullPointer)
            }
        } else {
            ErrorLogManager.sharedManager.recordNonFatalError(withException: .NullPointer)
        }
        
        // Section Merchant Header doesn't have items
        orderSections.append((section: .merchant, data: []))
        
        for orderSectionData in orderSectionDataList {
            if orderSectionData.dataSource.count > 0 {
                
                // Copy from root data source
                var orderItemDataSource: [Any] = orderSectionData.dataSource
                if orderItemDataSource.count > 0 {
                    
                    if orderSectionData.orderDisplayStatus == .toBeCollected {
                        if let orderSectionOrder = orderSectionData.order {
                            let orderStatusData = OrderStatusData(order: orderSectionOrder, orderDisplayStatus: orderSectionData.orderDisplayStatus)
                            orderItemDataSource.insert(orderStatusData, at: 0)
                            
                            // Collection detail cell
                            let orderCollectionData = OrderCollectionData(order: orderSectionOrder, orderShipment: orderSectionData.orderShipment)
                            orderItemDataSource.insert(orderCollectionData, at: 1)
                        } else {
                            ErrorLogManager.sharedManager.recordNonFatalError(withException: .NullPointer)
                        }
                    } else if (orderSectionData.orderDisplayStatus != .toBeShipped && orderSectionData.orderDisplayStatus != .cancelRequested && orderSectionData.orderDisplayStatus != .cancelAccepted && orderSectionData.orderDisplayStatus != .cancelRejected) {
                        if let orderSectionOrder = orderSectionData.order {
                            let shipmentStatusData = ShipmentStatusData(order: orderSectionOrder, orderShipment: orderSectionData.orderShipment)
                            
                            /*
                            shipmentStatusData.didUpdateShipmentStatus = { [weak self] in
                                if let strongSelf = self {
                                    strongSelf.collectionView.reloadData()
                                }
                            }
                            */
                            
                            orderItemDataSource.insert(shipmentStatusData, at: 0)
                        } else {
                            ErrorLogManager.sharedManager.recordNonFatalError(withException: .NullPointer)
                        }
                    }
                    
                    var index = 0
                    for data in orderItemDataSource {
                        if type(of: data) == OrderItem.self {
                            let orderItem = data as? OrderItem
                            
                            // Change OrderItem data to OrderItemShipment
                            let orderItemShipment = OrderItemShipment(orderItem: data as! OrderItem, orderDisplayStatus: orderSectionData.orderDisplayStatus)
                            orderItemDataSource[index] = orderItemShipment
                            
                            //Don't create button return/cancel/dispute for Order Cancel
                            if self.orderSectionData != nil && self.orderSectionData!.orderDisplayStatus == .orderClosed {
                                continue
                            }
                            
                            //Process to create button return, cancel, dispute for order
                            if let order = orderSectionData.order {
                                if let orderShipment = order.orderShipments?.first {
                                    if orderShipment.isProcessedShipment {
                                        // Processed shipment
                                        
                                        if (orderShipment.orderShipmentStatus == .received || orderShipment.orderShipmentStatus == .collected) {
                                            // Return button
                                            if let orderShipmentItems = orderShipment.orderShipmentItems {
                                                for orderShipmentItem in orderShipmentItems {
                                                    if orderShipmentItem.skuId == orderItem?.skuId {
                                                        let qtyOrdered = orderItem?.qtyOrdered ?? 0
                                                        let qtyReturned = orderItem?.qtyReturned ?? 0
                                                        let qtyReturnRequested = orderItem?.qtyReturnRequested ?? 0
                                                        let qtyToShip = orderItem?.qtyToShip ?? 0
                                                        let numOfQtyAvailable = qtyOrdered - qtyReturned - qtyReturnRequested - qtyToShip
                                                        //Only show return button if product have qty available
                                                        if numOfQtyAvailable > 0 {
                                                            let orderActionData = OrderItemActionData(order: order, orderItem: orderItem, actionButtonType: .`return`, numOfQtyAvailable: numOfQtyAvailable)
                                                            orderItemDataSource.insert(orderActionData, at: (index + 1))
                                                            index += 1
                                                        }
                                                    }
                                                }
                                            } else {
                                                ErrorLogManager.sharedManager.recordNonFatalError(withException: .NullPointer)
                                            }
                                            
                                            // TODO: API cannot handle it yet
                                            // Return progress button
//                                            if let orderReturns = order.orderReturns {
//                                                for orderReturn in orderReturns {
//                                                    if let orderReturnItems = orderReturn.orderReturnItems {
//                                                        for orderReturnItem in orderReturnItems {
//                                                            if orderReturnItem.skuId == orderItem?.skuId {
//                                                                let orderActionData = OrderItemActionData(order: order, orderItem: orderItem, actionButtonType: .ReturnProgress, numOfProcessingQty: orderReturnItem.qtyReturned, afterSalesKey: orderReturn.orderReturnKey)
//                                                                orderItemDataSource.insert(orderActionData, at: (index + 1))
//                                                                index += 1
//                                                            }
//                                                        }
//                                                    }
//                                                }
//                                            }
                                        }
                                    } else {
                                        // Unprocessed shipment
                                        
                                        if let orderCancels = order.orderCancels {
                                            // Cancel button
                                            var numOfItemRequestedCancel = 0
                                            
                                            for orderCancel in orderCancels {
                                                if let orderCancelItems = orderCancel.orderCancelItems {
                                                    if orderCancel.orderCancelStatus == .cancelRequested {
                                                        for orderCancelItem in orderCancelItems {
                                                            if orderCancelItem.skuId == orderItem?.skuId {
                                                                numOfItemRequestedCancel += orderCancelItem.qtyCancelled
                                                            }
                                                        }
                                                    }
                                                } else {
                                                    ErrorLogManager.sharedManager.recordNonFatalError(withException: .NullPointer)
                                                }
                                            }
                                            
                                            if let orderShipmentItems = orderShipment.orderShipmentItems {
                                                for orderShipmentItem in orderShipmentItems {
                                                    if orderShipmentItem.skuId == orderItem?.skuId {
                                                        if numOfItemRequestedCancel < orderShipmentItem.qtyToShip {
                                                            // Show cancel button if there are some item can be cancelled
                                                            
                                                            let orderActionData = OrderItemActionData(order: order, orderItem: orderItem, actionButtonType: .cancel, numOfQtyAvailable: orderShipmentItem.qtyToShip - numOfItemRequestedCancel)
                                                            orderItemDataSource.insert(orderActionData, at: (index + 1))
                                                            index += 1
                                                            
                                                            break
                                                        }
                                                    }
                                                }
                                            } else {
                                                ErrorLogManager.sharedManager.recordNonFatalError(withException: .NullPointer)
                                            }
                                            
                                            // Cancel progress button
                                            for orderCancel in orderCancels {
                                                if let orderCancelItems = orderCancel.orderCancelItems {
                                                    for orderCancelItem in orderCancelItems {
                                                        if orderCancelItem.skuId == orderItem?.skuId {
                                                            var actionStatus: OrderItemActionCell.ActionStatus = .unknown
                                                            
                                                            switch orderCancel.orderCancelStatus {
                                                            case .cancelAccepted:
                                                                actionStatus = .accepted
                                                            case .cancelRequested:
                                                                actionStatus = .inProgress
                                                            case .cancelRejected:
                                                                actionStatus = .rejected
                                                            default:
                                                                break
                                                            }
                                                            
                                                            let orderActionData = OrderItemActionData(order: order, orderItem: orderItem, actionButtonType: .cancelProgress, actionStatus: actionStatus, numOfProcessingQty: orderCancelItem.qtyCancelled, afterSalesKey: orderCancel.orderCancelKey)
                                                            orderItemDataSource.insert(orderActionData, at: (index + 1))
                                                            index += 1
                                                        }
                                                    }
                                                } else {
                                                    ErrorLogManager.sharedManager.recordNonFatalError(withException: .NullPointer)
                                                }
                                            }
                                        } else {
                                            // No order
                                            let orderActionData = OrderItemActionData(order: order, orderItem: orderItem, actionButtonType: .cancel, numOfQtyAvailable: orderItem?.qtyOrdered)
                                            orderItemDataSource.insert(orderActionData, at: (index + 1))
                                            index += 1
                                        }
                                    }
                                }
                                ErrorLogManager.sharedManager.recordNonFatalError(withException: .NullPointer)
                            }
                        }
                        
                        index += 1
                    }
                }
            
                // Section - Order Items
                orderSections.append((section: .orderShipment, data: orderItemDataSource))
            }
        }
        
        // Section - Price
        if orderSectionData != nil && orderSectionData!.order != nil {
            let orderPriceData = OrderPriceData(order: orderSectionData!.order!)
            orderSections.append((section: .price, data: [orderPriceData]))
        }
        
        // Section - Detail Info
        var orderDetailItems: [OrderDetailData] = [OrderDetailData]()
        
        var orderKey = "---"
        var transactionTime = "---"
        var taxInvoiceName = "---"
        var notes = "---"
        
        if let orderSectionData = orderSectionData {
            let order = orderSectionData.order
            
            if order != nil {
                if order!.comments.count > 0 {
                    notes = order!.comments
                }
                
                if order!.isTaxInvoiceRequested {
                    taxInvoiceName = order!.taxInvoiceName
                }
                
                orderKey = order!.orderKey
                
                if let date = order!.lastCreated {
                    transactionTime = Constants.DateFormatter.getFormatter("yyyy-MM-dd HH:mm:ss").string(from: date)
                }
            } else {
                ErrorLogManager.sharedManager.recordNonFatalError(withException: .NullPointer)
            }
        } else {
            ErrorLogManager.sharedManager.recordNonFatalError(withException: .NullPointer)
        }
        
        orderSections.append((section: .orderInfoHeader, data: [String.localize("LB_CA_TX_DTL")]))
        
        orderDetailItems.append(OrderDetailData(title: String.localize("LB_CA_OMS_ORDER_DETAIL_MERCH_ORDER_NUM"), value: orderKey))
        orderDetailItems.append(OrderDetailData(title: String.localize("LB_CA_OMS_ORDER_DETAIL_TX_TIME"), value: transactionTime))
        orderDetailItems.append(OrderDetailData(title: String.localize("LB_CA_OMS_ORDER_DETAIL_FAPIAO_TITLE"), value: taxInvoiceName))
        orderDetailItems.append(OrderDetailData(title: String.localize("LB_CA_OMS_ORDER_DETAIL_NOTE"), value: notes))
        
        orderSections.append((section: .orderInfo, data: orderDetailItems))
        
        if let orderSectionData = orderSectionData {
            if let order = orderSectionData.order {
                if let orderTransactions = order.orderTransactions {
                    let validOrderTransactions = orderTransactions.filter( { $0.paymentRecordType != .unknown } )
                    
                    if validOrderTransactions.count > 0 {
                        orderSections.append((section: .orderPaymentHeader, data: [String.localize("LB_CA_TX_RD")]))
                        orderSections.append((section: .orderPaymentInfo, data: validOrderTransactions))
                    }
                }
            }
        } else {
            ErrorLogManager.sharedManager.recordNonFatalError(withException: .NullPointer)
        }
        
        // Section - Action
        if let orderSectionData = orderSectionData {
            if let order = orderSectionData.order {
                orderActionData = OrderActionData(order: order, orderDisplayStatus: .unknown) // Show contact CS button at the bottom of view
            } else {
                ErrorLogManager.sharedManager.recordNonFatalError(withException: .NullPointer)
            }
        } else {
            ErrorLogManager.sharedManager.recordNonFatalError(withException: .NullPointer)
        }
    }
    
    private func setupCollectionView() {
        collectionView.backgroundColor = UIColor.clear
        
        collectionView.register(OrderItemCell.self, forCellWithReuseIdentifier: OrderItemCell.CellIdentifier)
        collectionView.register(OrderItemActionCell.self, forCellWithReuseIdentifier: OrderItemActionCell.CellIdentifier)
        collectionView.register(OrderStatusCell.self, forCellWithReuseIdentifier: OrderStatusCell.CellIdentifier)
        collectionView.register(ShipmentStatusCell.self, forCellWithReuseIdentifier: ShipmentStatusCell.CellIdentifier)
        collectionView.register(OrderItemPriceCell.self, forCellWithReuseIdentifier: OrderItemPriceCell.CellIdentifier)
        collectionView.register(OrderActionCell.self, forCellWithReuseIdentifier: OrderActionCell.CellIdentifier)
        collectionView.register(OrderDetailHeaderCell.self, forCellWithReuseIdentifier: OrderDetailHeaderCell.CellIdentifier)
        collectionView.register(OrderDetailCell.self, forCellWithReuseIdentifier: OrderDetailCell.CellIdentifier)
        collectionView.register(OrderPaymentDetailCell.self, forCellWithReuseIdentifier: OrderPaymentDetailCell.CellIdentifier)
        collectionView.register(ReceiverAddressCell.self, forCellWithReuseIdentifier: ReceiverAddressCell.CellIdentifier)
        collectionView.register(OrderCollectionDetailCell.self, forCellWithReuseIdentifier: OrderCollectionDetailCell.CellIdentifier)
        
        collectionView.register(MerchantSectionHeaderView.self, forSupplementaryViewOfKind: UICollectionElementKindSectionHeader, withReuseIdentifier: MerchantSectionHeaderView.ViewIdentifier)
        collectionView.register(OrderStatusHeaderView.self, forSupplementaryViewOfKind: UICollectionElementKindSectionHeader, withReuseIdentifier: OrderStatusHeaderView.ViewIdentifier)
        collectionView.register(UICollectionReusableView.self, forSupplementaryViewOfKind: UICollectionElementKindSectionHeader, withReuseIdentifier: OrderDetailHeaderID)
        collectionView.register(OrderDetailReminderView.self, forSupplementaryViewOfKind: UICollectionElementKindSectionHeader, withReuseIdentifier: OrderDetailReminderView.ViewIdentifier)
        collectionView.register(UICollectionViewCell.self, forCellWithReuseIdentifier: DefaultCellID)
    }
    
    private func setupBottomView() {
        if let orderActionData = self.orderActionData {
            let bottomViewHeight: CGFloat = 46
            
            collectionView.frame = CGRect(x: collectionView.x, y: collectionView.y, width: collectionView.width, height: collectionView.height - bottomViewHeight)
            
            let bottomActionButtonView = ActionButtonView(frame: CGRect(x: collectionView.x, y: collectionView.frame.maxY, width: collectionView.width, height: bottomViewHeight))
            bottomActionButtonView.orderActionData = orderActionData
            bottomActionButtonView.topBorderLine.isHidden = false
            bottomActionButtonView.contactCustomerServiceWithOrder = { [weak self] (order) in
                if let strongSelf = self {
                    strongSelf.contactCustomerServiceWithOrder(strongSelf, order: order , viewMode: strongSelf.originalViewMode)
                } else {
                    ErrorLogManager.sharedManager.recordNonFatalError(withException: .NullPointer)
                }
            }
            
            self.bottomActionButtonView = bottomActionButtonView
            view.addSubview(bottomActionButtonView)
        } else {
            ErrorLogManager.sharedManager.recordNonFatalError(withException: .NullPointer)
        }
    }
    
    private func splitOrder(_ order: Order) -> [OrderSectionData] {
        var results = [OrderSectionData]()
        
        // Split order by shipment
        
        var orders = [Order]()
        
        if let unprocessedShipment = order.unprocessedShipment {
            let order = order.copy()
            order.originalOrder = order.copy()
            order.orderShipments = [unprocessedShipment]
            order.orderReturns = nil    // Unprocessed shipment will never have return item
            order.orderStatus = .paid   // Paid, but not yet shipped
            
            var shipmentItemQtys = [String : Int]()
            
            if let orderShipmentItems = unprocessedShipment.orderShipmentItems {
                for orderShipmentItem in orderShipmentItems {
                    shipmentItemQtys["\(orderShipmentItem.skuId)"] = orderShipmentItem.qtyShipped
                }
            } else {
                ErrorLogManager.sharedManager.recordNonFatalError(withException: .NullPointer)
            }
            
            var actualOrderItems = [OrderItem]()
            
            if let orderItems = order.orderItems {
                for orderItem in orderItems {
                    if let shipmentItemQty = shipmentItemQtys["\(orderItem.skuId)"] {
                        let actualOrderItem = orderItem
                        actualOrderItem.qtyShipped = shipmentItemQty
                        
                        actualOrderItems.append(actualOrderItem)
                    } else {
                        ErrorLogManager.sharedManager.recordNonFatalError(withException: .NullPointer)
                    }
                }
            } else {
                ErrorLogManager.sharedManager.recordNonFatalError(withException: .NullPointer)
            }
            
            order.orderItems = actualOrderItems
            
            orders.append(order)
        } else {
            ErrorLogManager.sharedManager.recordNonFatalError(withException: .NullPointer)
        }
        
        if let orderShipments = order.orderShipments {
            for orderShipment in orderShipments {
                let order = order.copy()
                order.originalOrder = order.copy()
                order.orderShipments = [orderShipment]
                order.orderCancels = nil    // Processed shipment will never have cancel item
                order.orderReturns = nil    // TODO: Pending update from API team
                
                var shipmentItemQtys = [String : Int]()
                
                if let orderShipmentItems = orderShipment.orderShipmentItems {
                    for orderShipmentItem in orderShipmentItems {
                        shipmentItemQtys["\(orderShipmentItem.skuId)"] = orderShipmentItem.qtyShipped
                    }
                } else {
                    ErrorLogManager.sharedManager.recordNonFatalError(withException: .NullPointer)
                }
                
                var actualOrderItems = [OrderItem]()
                
                if let orderItems = order.orderItems {
                    for orderItem in orderItems {
                        if let shipmentItemQty = shipmentItemQtys["\(orderItem.skuId)"] {
                            let actualOrderItem = orderItem
                            actualOrderItem.qtyShipped = shipmentItemQty
                            
                            actualOrderItems.append(actualOrderItem)
                        } else {
                            ErrorLogManager.sharedManager.recordNonFatalError(withException: .NullPointer)
                        }
                    }
                } else {
                    ErrorLogManager.sharedManager.recordNonFatalError(withException: .NullPointer)
                }
                
                order.orderItems = actualOrderItems
                
                orders.append(order)
            }
        } else {
            
            ErrorLogManager.sharedManager.recordNonFatalError(withException: .NullPointer)
        }
        
        for order in orders {
            if let orderShipment = order.orderShipments?.first {
                if orderShipment.orderShipmentStatus != .cancelled {
                    let data = OrderSectionData(sectionHeader: [], reuseIdentifier: OrderItemCell.CellIdentifier, dataSource: order.orderItems!)
                    
                    data.order = order
                    
                    if orderShipment.orderShipmentStatus == .pendingCollection {
                        data.orderDisplayStatus = .toBeCollected
                    }
                    
                    if !orderShipment.isProcessedShipment {
                        data.orderDisplayStatus = .toBeShipped
                    }
                    
                    data.orderShipment = orderShipment
                    
                    if data.orderDisplayStatus != .toBeShipped { // To be shipped don't have button actions
                        let orderActionData = OrderActionData(order: data.order!, orderDisplayStatus: data.orderDisplayStatus)
                        data.append(dataItem: orderActionData)
                    }
                    
                    results.append(data)
                }
            } else {
                ErrorLogManager.sharedManager.recordNonFatalError(withException: .DataIsEmpty)
            }
        }
        
        return results
    }
    
    // MARK: - Data Processing
    
    private func reloadOrder(navigateToAfterSalesHistoryWithKey afterSalesKey: String? = nil) {
        if let orderSectionData = orderSectionData {
            if let order = orderSectionData.order {
                showLoading()
                
                firstly {
                    return fetchOrder(order.orderKey)
                }.then { _ -> Void in
                    self.collectionView.reloadData()
                    self.delegate?.didUpdateOrder(orderDetailViewController: self, order: order)
                    if let afterSalesKey = afterSalesKey {
                        self.navigateToAfterSalesHistory(afterSalesKey: afterSalesKey)
                    } else {
                        ErrorLogManager.sharedManager.recordNonFatalError(withException: .NullPointer)
                    }
                }.always {
                    self.stopLoading()
                }.catch { _ -> Void in
                    
                }
            } else {
                ErrorLogManager.sharedManager.recordNonFatalError(withException: .NullPointer)
            }
        } else {
            ErrorLogManager.sharedManager.recordNonFatalError(withException: .NullPointer)
        }
    }
    
    private func fetchOrder(_ orderKey: String) -> Promise<Any> {
        return Promise { fulfill, reject in
            OrderService.viewOrder(orderKey, completion: { [weak self] (response) in
                let statusCode = response.response?.statusCode ?? 0
                
                if let strongSelf = self {
                    if response.result.isSuccess {
                        if statusCode == 200 {
                            if let order = Mapper<Order>().map(JSONObject: response.result.value) {
                                strongSelf.order = order
                                strongSelf.orderSectionData = OrderManager.buildOrderSectionData(withOrder: order)
                            } else {
                                ErrorLogManager.sharedManager.recordNonFatalError(withException: .FailToParseAPIResponse)
                            }
                            
                            fulfill("OK")
                        } else {
                            let error = NSError(domain: "", code: statusCode, userInfo: nil)
                            reject(error)
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
    
    // MARK: - Collection View Data Source methods
    
    func numberOfSections(in collectionView: UICollectionView) -> Int {
        return self.orderSections.count
    }
    
    override func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        let (_, arrayData) = self.orderSections[section]
        return (arrayData as? [Any])?.count ?? 0
    }
    
    override func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        let (sectionHeader, arrayData) = self.orderSections[indexPath.section]
        
        switch sectionHeader {
        case .receiverAddress:
            if let data = self.addressData {
                let cell = collectionView.dequeueReusableCell(withReuseIdentifier: ReceiverAddressCell.CellIdentifier, for: indexPath) as! ReceiverAddressCell
                cell.data = data
                
                return cell
            } else {
                ErrorLogManager.sharedManager.recordNonFatalError(withException: .NullPointer)
            }
        case .orderShipment:
            if let list = arrayData as? [Any] {
                let data: Any = list[indexPath.row]
                if type(of: data) == ShipmentStatusData.self {
                    let cell = collectionView.dequeueReusableCell(withReuseIdentifier: ShipmentStatusCell.CellIdentifier, for: indexPath) as! ShipmentStatusCell
                    
                    cell.eventLabel.text = "-"
                    
                    if let shipmentStatusData = data as? ShipmentStatusData {
                        cell.data = shipmentStatusData
                        
                        cell.cellTappedHandler = {
                            let shipmentTrackingViewController = ShipmentTrackingViewController()
                            shipmentTrackingViewController.addressData = self.shipmentAddressData
                            
                            if let orderShipment = shipmentStatusData.orderShipment {
                                shipmentTrackingViewController.orderShipment = orderShipment
                            } else {
                                ErrorLogManager.sharedManager.recordNonFatalError(withException: .NullPointer)
                            }
                            
                            self.navigationController?.push(shipmentTrackingViewController, animated: true)
                        }
                    } else {
                        ErrorLogManager.sharedManager.recordNonFatalError(withException: .NullPointer)
                    }
                    
                    return cell
                } else if type(of: data) == OrderStatusData.self {
                    let cell = collectionView.dequeueReusableCell(withReuseIdentifier: OrderStatusCell.CellIdentifier, for: indexPath) as! OrderStatusCell
                    cell.data = data as? OrderStatusData
                    
                    return cell
                } else if type(of: data) == OrderCollectionData.self {
                    let orderCollectionData = data as! OrderCollectionData
                    let cell = collectionView.dequeueReusableCell(withReuseIdentifier: OrderCollectionDetailCell.CellIdentifier, for: indexPath) as! OrderCollectionDetailCell
                    
                    cell.data = orderCollectionData
                    
                    cell.copyAddressTapHandler = { (addressValue) in
                        UIPasteboard.general.string = addressValue
                        self.showSuccessPopupWithText(String.localize("LB_CS_SHARE_COPY_INFO"))
                    }
                    
                    if orderCollectionData.inventoryLocation == nil {
                        orderCollectionData.fetchInBackgroundInventoryLocation(completion: { (isSuccess, inventoryLocation) in
                            if isSuccess {
                                collectionView.reloadData()
                            }
                        })
                    }
                    return cell
                } else if type(of: data) == OrderItemShipment.self {
                    let orderItemShipment = data as! OrderItemShipment
                    let cell = collectionView.dequeueReusableCell(withReuseIdentifier: OrderItemCell.CellIdentifier, for: indexPath) as! OrderItemCell
                    cell.orderDisplayStatus = orderItemShipment.orderDisplayStatus
                    cell.data = orderItemShipment.orderItem
                    
                    if let orderItem = orderItemShipment.orderItem {
                        if orderItemShipment.orderDisplayStatus == .toBeShipped {
                            if let order = orderSectionData?.order {
                                if order.orderStatus == .initiated {
                                    // Case: Order just created (From Thank you page)
                                    cell.setQuantityToShip(orderItem.qtyOrdered)
                                } else if order.orderStatus != .cancelled {
                                    cell.setQuantityToShip(orderItem.qtyToShip)
                                }
                            }
                        } else {
                            cell.setQuantityShipped(orderItem.qtyShipped)
                        }
                    } else {
                        ErrorLogManager.sharedManager.recordNonFatalError(withException: .NullPointer)
                    }
                    
                    cell.hideQuantityLabel(true)
                    cell.bottomBorderView.isHidden = true
                    cell.updateLayout()
                    
                    return cell
                } else if type(of: data) == OrderItemActionData.self {
                    let cell = collectionView.dequeueReusableCell(withReuseIdentifier: OrderItemActionCell.CellIdentifier, for: indexPath) as! OrderItemActionCell
                    
                    if let orderItemActionData = data as? OrderItemActionData {
                        cell.data = orderItemActionData
                        
                        cell.didTapActionButton = { (actionButtonType, orderItem, afterSalesKey) -> Void in
                            self.handleOrderItemAction(actionButtonType, orderItem: orderItem, afterSalesKey: afterSalesKey, numOfQtyAvailable: orderItemActionData.numOfQtyAvailable)
                        }
                    } else {
                        ErrorLogManager.sharedManager.recordNonFatalError(withException: .NullPointerOrTypeMismatch)
                    }
                    
                    return cell
                } else if type(of: data) == OrderActionData.self {
                    let cell = collectionView.dequeueReusableCell(withReuseIdentifier: OrderActionCell.CellIdentifier, for: indexPath) as! OrderActionCell
                    cell.isShowInDetailView = true
                    cell.isDisplayShipmentAndReviewButtons = true
                    cell.data = data as? OrderActionData
                    cell.backgroundColor = UIColor.clear
                    cell.delegate = self
                    
                    if self.orderSectionData != nil {
                        if let order = self.orderSectionData?.order {
                            cell.contactHandler = { [weak self] in
                                if let strongSelf = self {
                                    let orderShipmentKey = (data as! OrderActionData).orderShipmentKey
                                    strongSelf.contactCustomerServiceWithOrder(strongSelf, order: order, orderShipmentKey: orderShipmentKey, viewMode: strongSelf.originalViewMode)
                                }
                            }
                        } else {
                            ErrorLogManager.sharedManager.recordNonFatalError(withException: .NullPointer)
                        }
                    }
                    
                    return cell
                }
            } else {
                ErrorLogManager.sharedManager.recordNonFatalError(withException: .IndexOutOfBounds)
            }
        case .price:
            if let list = arrayData as? [Any]{
                let data: Any = list[indexPath.row]
                if let data = data as? OrderPriceData {
                    let cell = collectionView.dequeueReusableCell(withReuseIdentifier: OrderItemPriceCell.CellIdentifier, for: indexPath) as! OrderItemPriceCell
                    cell.data = data
                    
                    return cell
                } else {
                    ErrorLogManager.sharedManager.recordNonFatalError(withException: .NullPointerOrTypeMismatch)
                }
            } else {
                ErrorLogManager.sharedManager.recordNonFatalError(withException: .IndexOutOfBounds)
            }
        case .orderInfoHeader:
            // TODO: Use header instead of cell
            let cell = collectionView.dequeueReusableCell(withReuseIdentifier: OrderDetailHeaderCell.CellIdentifier, for: indexPath) as! OrderDetailHeaderCell
            
            if let titles = arrayData as? [String] {
                if titles.count == 1 {
                    cell.setTitle(titles.first ?? "")
                    cell.showTopBorderView(true)
                }
            } else {
                ErrorLogManager.sharedManager.recordNonFatalError(withException: .NullPointerOrTypeMismatch)
            }
            
            return cell
        case .orderInfo:
            let cell = collectionView.dequeueReusableCell(withReuseIdentifier: OrderDetailCell.CellIdentifier, for: indexPath) as! OrderDetailCell
            
            if let orderInfoItems = arrayData as? [OrderDetailData] {
                cell.data = orderInfoItems[indexPath.row]
            } else {
                ErrorLogManager.sharedManager.recordNonFatalError(withException: .NullPointerOrTypeMismatch)
            }
            
            return cell
        case .orderPaymentHeader:
            // TODO: Use header instead of cell
            let cell = collectionView.dequeueReusableCell(withReuseIdentifier: OrderDetailHeaderCell.CellIdentifier, for: indexPath) as! OrderDetailHeaderCell
            
            if let titles = arrayData as? [String] {
                if titles.count == 1 {
                    cell.setTitle(titles.first ?? "")
                    cell.showTopBorderView(false)
                }
            } else {
                ErrorLogManager.sharedManager.recordNonFatalError(withException: .NullPointerOrTypeMismatch)
            }
            
            return cell
        case .orderPaymentInfo:
            let cell = collectionView.dequeueReusableCell(withReuseIdentifier: OrderPaymentDetailCell.CellIdentifier, for: indexPath) as! OrderPaymentDetailCell
            
            if let orderTransactions = arrayData as? [OrderTransaction] {
                cell.orderTransaction = orderTransactions[indexPath.row]
            } else {
                ErrorLogManager.sharedManager.recordNonFatalError(withException: .NullPointerOrTypeMismatch)
            }
            
            return cell
        case .orderAction:
            let cell = collectionView.dequeueReusableCell(withReuseIdentifier: OrderActionCell.CellIdentifier, for: indexPath) as! OrderActionCell
            
            cell.delegate = self
            
            if let list = arrayData as? [Any] {
                let data: Any = list[indexPath.row]
                if type(of: data) == OrderActionData.self {
                    let orderActionData = data as! OrderActionData
                    cell.data = orderActionData
                    cell.backgroundColor = UIColor.white
                    
                    if let order: Order = orderActionData.order {
                        cell.contactHandler = { [weak self] in
                            if let strongSelf = self {
                                strongSelf.contactCustomerServiceWithOrder(strongSelf, order: order , viewMode: strongSelf.originalViewMode)
                            }
                        }
                    } else {
                        ErrorLogManager.sharedManager.recordNonFatalError(withException: .NullPointer)
                    }
                }
            } else {
                ErrorLogManager.sharedManager.recordNonFatalError(withException: .IndexOutOfBounds)
            }
            
            return cell
        default:
            break
        }
        
        return getDefaultCell(collectionView, cellForItemAt: indexPath)
    }
    
    func collectionView(_ collectionView: UICollectionView, viewForSupplementaryElementOfKind kind: String, at indexPath: IndexPath) -> UICollectionReusableView {
        let (sectionHeader, _) = orderSections[indexPath.section]
        
        switch sectionHeader {
        case .reminder:
            let view = collectionView.dequeueReusableSupplementaryView(ofKind: kind, withReuseIdentifier: OrderDetailReminderView.ViewIdentifier, for: indexPath) as! OrderDetailReminderView
            
            if let sectionData = self.orderSectionData {
                let isCOD = (sectionData.order != nil ? sectionData.order!.isCOD : false)
                if (isCOD && (sectionData.orderDisplayStatus == .toBeShipped || sectionData.orderDisplayStatus == .shipped)) {
                    view.message = String.localize("LB_CA_OMS_TO_BE_SHIPPED_DETAIL_CALL_FOR_ACTION") + ((self.orderSectionData?.order?.grandTotal)!.formatPrice() ?? "")
                } else if sectionData.orderDisplayStatus == .returnRequestAuthorised {
                    view.message = String.localize("LB_CA_OMS_RTN_AUTH_NOTE")
                }
            } else {
                ErrorLogManager.sharedManager.recordNonFatalError(withException: .NullPointer)
            }
            
            return view
        case .action:
            let view = collectionView.dequeueReusableSupplementaryView(ofKind: kind, withReuseIdentifier: OrderStatusHeaderView.ViewIdentifier, for: indexPath) as! OrderStatusHeaderView
            
            if let orderSectionData = self.orderSectionData {
                view.data = orderSectionData
                
                if let order = orderSectionData.order {
                    view.setTimelineStatus(withOrderStatus: order.orderStatus, isCrossBorder: order.isCrossBorder)
                } else {
                    ErrorLogManager.sharedManager.recordNonFatalError(withException: .NullPointer)
                }
            } else {
                ErrorLogManager.sharedManager.recordNonFatalError(withException: .NullPointer)
            }
            
            return view
        case .merchant:
            let view = collectionView.dequeueReusableSupplementaryView(ofKind: kind, withReuseIdentifier: MerchantSectionHeaderView.ViewIdentifier, for: indexPath) as! MerchantSectionHeaderView
            
            view.isEnablePaddingRight = true
            view.isEnablePaddingLeft = true
            view.showDisclosureIndicator(true)
            view.showSeparatorView(false)
            view.data = self.orderSectionData
            
            view.headerTappedHandler = { [weak self] (data) in
                if let strongSelf = self {
                    if let order = data.order {
                        DeepLinkManager.sharedManager.pushMerchantById(order.merchantId, fromViewController: strongSelf)
                    } else {
                        ErrorLogManager.sharedManager.recordNonFatalError(withException: .NullPointer)
                    }
                } else {
                    ErrorLogManager.sharedManager.recordNonFatalError(withException: .NullPointer)
                }
            }
            
            return view
        default:
            break
        }
        
        let view = collectionView.dequeueReusableSupplementaryView(ofKind: kind, withReuseIdentifier: OrderDetailHeaderID, for: indexPath)
        view.backgroundColor = UIColor.clear
        
        return view
    }
    
    // MARK: - Collection View Delegate (Flow Layout) methods
    
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, insetForSectionAt section: Int) -> UIEdgeInsets {
        return UIEdgeInsets.zero
    }
    
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, referenceSizeForHeaderInSection section: Int) -> CGSize {
        let (sectionHeader, _) = orderSections[section]
        
        switch sectionHeader {
        case .reminder:
            if let sectionData = self.orderSectionData {
                let isCOD = (sectionData.order != nil ? sectionData.order!.isCOD : false)
                if (isCOD && (sectionData.orderDisplayStatus == .toBeShipped || sectionData.orderDisplayStatus == .shipped)) || sectionData.orderDisplayStatus == .returnRequestAuthorised {
                    return CGSize(width: self.view.bounds.width, height: OrderDetailReminderView.DefaultHeight)
                }
            } else {
                ErrorLogManager.sharedManager.recordNonFatalError(withException: .NullPointer)
            }
        case .action:
            return CGSize(width: view.width, height: OrderStatusHeaderView.DefaultHeight)
        case .orderShipment:
            return CGSize(width: view.width, height: 10)
        case .merchant:
            if let sectionData = self.orderSectionData {
                if sectionData.sectionHeader != nil && sectionData.dataSource.count > 0 {
                    return CGSize(width: view.width - (PaddingContent * 2), height: MerchantSectionHeaderView.DefaultHeight)
                }
            } else {
                ErrorLogManager.sharedManager.recordNonFatalError(withException: .NullPointer)
            }
            
            return CGSize.zero
//        case .OrderInfo:
//            return CGSize(width: view.width, height: OrderDetailHeaderViewHeight)
        default:
            break
        }
        
        return CGSize.zero
    }
    
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, sizeForItemAt indexPath: IndexPath) -> CGSize {
        let cellWidth = view.width - (PaddingContent * 2)
        let (sectionHeader, arrayData) = self.orderSections[indexPath.section]
        
        switch sectionHeader {
        case .receiverAddress:
            if let addressData = self.addressData {
                return CGSize(width: cellWidth, height: ReceiverAddressCell.getCellHeight(withAddress: addressData.getFullAddress(), cellWidth: cellWidth))
            } else {
                ErrorLogManager.sharedManager.recordNonFatalError(withException: .NullPointer)
            }
        case .reminder:
            return CGSize(width: cellWidth, height: OrderDetailReminderView.DefaultHeight)
        case .action:
            return CGSize(width: cellWidth, height: CellHeight)
        case .orderShipment:
            if let list = arrayData as? [Any] {
                let data: Any = list[indexPath.row]
                if type(of: data) == ShipmentStatusData.self {
                    return CGSize(width: cellWidth, height: ShipmentStatusCell.getCellHeight(shipmentStatusData: data as! ShipmentStatusData, cellWidth: cellWidth))
                } else if type(of: data) == OrderStatusData.self {
                    let orderStatusData = data as? OrderStatusData
                    
                    if orderStatusData?.orderDisplayStatus == .toBeCollected { //Show order status for to be collected
                        return CGSize(width: cellWidth, height: OrderStatusCellHeight)
                    } else {
                        return CGSize(width: cellWidth, height: 0) //If order status from OMS list we only hidden the cell by set Height = 0
                    }
                } else if type(of: data) == OrderCollectionData.self {
                    return CGSize(width: cellWidth, height: OrderCollectionDetailCell.getCellHeight((data as? OrderCollectionData)!, cellWidth: cellWidth))
                } else if type(of: data) == OrderItemShipment.self {
                    return CGSize(width: cellWidth, height: OrderItemCell.DefaultHeight)
                } else if type(of: data) == OrderItemActionData.self {
                    return CGSize(width: cellWidth, height: OrderItemActionCell.DefaultHeight)
                } else if type(of: data) == OrderActionData.self {
                    return CGSize(width: cellWidth, height: OrderActionCellHeight)
                }
            } else {
                ErrorLogManager.sharedManager.recordNonFatalError(withException: .IndexOutOfBounds)
            }
        case .price:
            if let list = arrayData as? [Any] {
                let data: Any = list[indexPath.row]
                if let data = data as? OrderPriceData {
                    return CGSize(width: cellWidth, height: OrderItemPriceCell.getHeight(hasMMCoupon: (data.mmCouponAmount != ""), hasMerchantCoupon: (data.merchantCouponAmount != ""), hasAdditionalCharge: (data.additionalCharge != ""), hasOrderDiscount: (data.orderDiscount != "")))
                } else {
                    ErrorLogManager.sharedManager.recordNonFatalError(withException: .NullPointerOrTypeMismatch)
                }
            } else {
                ErrorLogManager.sharedManager.recordNonFatalError(withException: .IndexOutOfBounds)
            }
        case .orderInfoHeader:
            return CGSize(width: view.width, height: OrderDetailHeaderCell.DefaultHeight)
        case .orderInfo:
            if let orderInfoItems = arrayData as? [OrderDetailData] {
                return CGSize(width: view.width, height: OrderDetailCell.getCellHeight(text: orderInfoItems[indexPath.row].value, width: view.width - (OrderDetailCell.HorizontalMargin * 2)))
            } else {
                ErrorLogManager.sharedManager.recordNonFatalError(withException: .NullPointerOrTypeMismatch)
            }
        case .orderPaymentHeader:
            return CGSize(width: view.width, height: OrderDetailHeaderCell.DefaultHeight + 7)
        case .orderPaymentInfo:
            if let orderTransactions = arrayData as? [OrderTransaction] {
                let referenceNo = orderTransactions[indexPath.item].referenceNo
                
                return CGSize(width: view.width, height: OrderPaymentDetailCell.BasicHeight + (referenceNo == "" ? 0 : OrderPaymentDetailCell.ExtraHeight))
            } else {
                ErrorLogManager.sharedManager.recordNonFatalError(withException: .NullPointerOrTypeMismatch)
            }
        case .orderAction:
            return CGSize(width: cellWidth, height: 46)
        default:
            break
        }
        
        return CGSize.zero
    }
    
    // MARK: - Collection View Delegate methods
    
    func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        let (sectionHeader, arrayData) = orderSections[indexPath.section]
        if let list = arrayData as? [Any], sectionHeader == .orderShipment && list.count > 0 && indexPath.row < list.count {
            let data = list[indexPath.row]
            if type(of: data) == OrderItemShipment.self {
                if let selectedOrderItem = data as? OrderItemShipment, let orderItem = selectedOrderItem.orderItem, let orderSectionData = orderSectionData, let order = orderSectionData.order {
                    let style = Style()
                    style.styleCode = orderItem.styleCode
                    style.merchantId = order.merchantId
                    
                    let styleViewController = StyleViewController(style: style)
                    
                    self.navigationController?.pushViewController(styleViewController, animated: true)
                }
            }
        }
    }
    
    // MARK: OrderActionCellDelegate
    
    func didConfirmShipment(orderShipmentKey: String, order: Order?) {
        Alert.alert(self, title: String.localize("LB_CA_OMS_PROMPT_CONFIRM_SHIPMENT"), message: String.localize("LB_CA_OMS_SHIPMENT_RATING"), okActionComplete: { () -> Void in
            self.showLoading()
            
            firstly {
                return self.confirmShipment(orderShipmentKey: orderShipmentKey)
            }.then { _ -> Void in
                if let data = order {
                    self.didRequestViewReview(data)
                } else {
                    ErrorLogManager.sharedManager.recordNonFatalError(withException: .NullPointer)
                }
            }.always {
                self.stopLoading()
            }.catch { _ -> Void in
                Log.error("error")
            }
        }, cancelActionComplete: nil)
    }
    
    func didRequestViewShipment(_ order: Order) {
        let shipmentTrackingViewController = ShipmentTrackingViewController()
        self.navigationController?.push(shipmentTrackingViewController, animated: true)
    }
    
    func handleOrderItemAction(_ orderItemActionType: OrderItemActionCell.ActionButtonType, orderItem: OrderItem, afterSalesKey: String, numOfQtyAvailable: Int) {
        if Reachability.shared().currentReachabilityStatus() == NotReachable {
            self.showErrorAlert(String.localize("MSG_ERR_NETWORK_FAIL"))
            return
        }
        
        switch orderItemActionType {
        case .cancel:
            let afterSalesViewController = AfterSalesViewController()
            afterSalesViewController.currentViewType = .cancel
            afterSalesViewController.orderItem = orderItem
            afterSalesViewController.maxAvailableAfterSalesQuantity = numOfQtyAvailable
            afterSalesViewController.orderSectionData = orderSectionData
            afterSalesViewController.delegate = self
            
            let navigationController = MmNavigationController(rootViewController: afterSalesViewController)
            present(navigationController, animated: true, completion: nil)
        case .return:
            let afterSalesViewController = AfterSalesViewController()
            afterSalesViewController.currentViewType = .return
            afterSalesViewController.orderItem = orderItem
            afterSalesViewController.maxAvailableAfterSalesQuantity = numOfQtyAvailable
            afterSalesViewController.orderSectionData = orderSectionData
            afterSalesViewController.delegate = self
            
            let navigationController = MmNavigationController(rootViewController: afterSalesViewController)
            present(navigationController, animated: true, completion: nil)
        case .dispute:
            let afterSalesViewController = AfterSalesViewController()
            afterSalesViewController.currentViewType = .dispute
            afterSalesViewController.orderItem = orderItem
            afterSalesViewController.orderSectionData = orderSectionData
            
            if orderSectionData?.order?.orderReturns?.count > 0 {
                let orderReturn = orderSectionData?.order?.orderReturns?.first
                
                if orderReturn?.order == nil {
                    orderReturn?.order = orderSectionData?.order
                }
                
                if let qtyReturned = orderReturn?.orderReturnItems?.first?.qtyReturned {
                    afterSalesViewController.maxAvailableAfterSalesQuantity = qtyReturned
                } else {
                    ErrorLogManager.sharedManager.recordNonFatalError(withException: .DataIsEmpty)
                }
                
                afterSalesViewController.setDataSourceWithOrderReturn(orderReturn)
            }
            
            afterSalesViewController.delegate = self
            
            let navigationController = MmNavigationController(rootViewController: afterSalesViewController)
            present(navigationController, animated: true, completion: nil)
        case .cancelProgress, .returnProgress, .disputeProgress:
            showAfterSalesHistory(showFromViewController: self, afterSalesKey: afterSalesKey)
        default:
            break
        }
    }
    
    func didRequestViewReview(_ order: Order) {
        let orderReviewViewController = OrderReviewViewController()
        orderReviewViewController.order = order
        orderReviewViewController.delegate = self
        
        let navigationController = MmNavigationController(rootViewController: orderReviewViewController)
        present(navigationController, animated: true, completion: nil)
    }
    
    // MARK: - AfterSalesViewDelegate
    
    func didCancelOrder(_ isSuccess: Bool, orderItem: OrderItem?, orderCancel: OrderCancel?) {
        reloadOrder(navigateToAfterSalesHistoryWithKey: orderCancel?.orderCancelKey)
    }
    
    func didReturnOrder(_ isSuccess: Bool, orderItem: OrderItem?, orderReturn: OrderReturn?) {
        reloadOrder(navigateToAfterSalesHistoryWithKey: orderReturn?.orderReturnKey)
    }
    
    func didDisputeOrder(_ isSuccess: Bool, orderItem: OrderItem?, orderReturn: OrderReturn?) {
        reloadOrder(navigateToAfterSalesHistoryWithKey: orderReturn?.orderReturnKey)
    }
    
    func didSubmitReportReview(_ isSuccess: Bool) {
        
    }
    
    func navigateToAfterSalesHistory(afterSalesKey: String? = nil) {
        // Show .afterSales in Order List when going back
        self.delegate?.didRequestSwitchViewMode(orderDetailViewController: self, viewMode: .afterSales)
        
        if let viewControllers = self.navigationController?.viewControllers {
            for viewController in viewControllers {
                if let orderManagementCollectionViewController = viewController as? OrderManagementCollectionViewController {
                    showAfterSalesHistory(showFromViewController: orderManagementCollectionViewController, afterSalesKey: afterSalesKey)
                    break
                } else if let checkoutViewController = viewController as? FCheckoutViewController {
                    self.navigationController?.popToViewController(checkoutViewController, animated: false)
                    showAfterSalesHistory(showFromViewController: checkoutViewController, afterSalesKey: afterSalesKey)
                    break
                }
            }
        } else {
            ErrorLogManager.sharedManager.recordNonFatalError(withException: .NullPointer)
        }
    }
    
    func reloadAfterCancelOrderReturn(_ isSuccess: Bool) {
        if isSuccess {
            reloadOrder()
        }
    }
    
    // MARK: - OrderReviewViewController
    
    func didSubmitReview(isSuccess: Bool, shouldShowCampaignPopup: Bool) {
        if shouldShowCampaignPopup {
            if let topViewController = ShareManager.sharedManager.getTopViewController() {
                let profilePopupViewController = ProfilePopupViewController()
                profilePopupViewController.presentViewController = topViewController
                let nvm = MmNavigationController(rootViewController: profilePopupViewController)
                nvm.modalPresentationStyle = .custom
                nvm.view.backgroundColor = UIColor.white.withAlphaComponent(0)
                topViewController.present(nvm, animated: false, completion: nil)
            }
        } else {
            self.showSuccessPopupWithText(String.localize("MSG_SUC_CA_OMS_REVIEW"))
        }
    }
    
    //this happens when user close review page
    func didDismissReview() {
        self.reloadOrder()
    }
    
    // MARK: - AfterSalesHistoryViewDelegate
    
    func didCancelOrderDisputeFromAfterSalesHistory(_ isSuccess: Bool) {
        reloadOrder()
        
        self.delegate?.didRequestSwitchViewMode(orderDetailViewController: self, viewMode: .afterSales)
    }
    
    func didDisputeOrderFromAfterSalesHistory(_ isSuccess: Bool) {
        reloadOrder()
        
        // Show .Refund in Order List when going back
        self.delegate?.didRequestSwitchViewMode(orderDetailViewController: self, viewMode: .afterSales)
        
        if let viewControllers = self.navigationController?.viewControllers {
            if viewControllers.count > 1 {
                if let orderManagementViewController = viewControllers[viewControllers.count - 2] as? OrderManagementCollectionViewController {
                    self.navigationController?.popToViewController(orderManagementViewController, animated: false)
                    showAfterSalesHistory(showFromViewController: orderManagementViewController)
                } else {
                    ErrorLogManager.sharedManager.recordNonFatalError(withException: .NullPointerOrTypeMismatch)
                }
            }
        } else {
            ErrorLogManager.sharedManager.recordNonFatalError(withException: .NullPointer)
        }
    }
    
    // MARK: - Helpers
    
    private func showAfterSalesHistory(showFromViewController viewController: UIViewController, afterSalesKey: String? = nil) {
        // Get orderDisplayStatus
        var orderDisplayStatus: Constants.OrderDisplayStatus = .unknown
        
        if let order = order {
            if let afterSalesKey = afterSalesKey {
                if let orderReturns = order.orderReturns {
                    for orderReturn in orderReturns where orderReturn.orderReturnKey == afterSalesKey {
                        switch orderReturn.orderReturnStatus {
                        case .returnCancelled:
                            orderDisplayStatus = .returnCancelled
                        case .returnAuthorized:
                            orderDisplayStatus = .returnRequestAuthorised
                        case .returnRequested:
                            orderDisplayStatus = .returnRequestSubmitted
                        case .returnRequestRejected:
                            orderDisplayStatus = .returnRequestRejected
                        case .returnAccepted:
                            orderDisplayStatus = .returnAccepted
                        case .returnRejected:
                            orderDisplayStatus = .returnRejected
                        case .requestDisputed:
                            orderDisplayStatus = .disputeOpen
                        case .requestDisputeInProgress:
                            orderDisplayStatus = .disputeInProgress
                        case .returnDisputed:
                            orderDisplayStatus = .disputeOpen
                        case .returnDisputeInProgress:
                            orderDisplayStatus = .disputeInProgress
                        default:
                            break
                        }
                    }
                } else {
                    ErrorLogManager.sharedManager.recordNonFatalError(withException: .NullPointer)
                }
                
                if let orderCancels = order.orderCancels {
                    for orderCancel in orderCancels where orderCancel.orderCancelKey == afterSalesKey {
                        switch orderCancel.orderCancelStatus {
                        case .cancelAccepted:
                            orderDisplayStatus = .cancelAccepted
                        case .cancelRequested:
                            orderDisplayStatus = .cancelRequested
                        case .cancelRejected:
                            orderDisplayStatus = .cancelRejected
                        default:
                            break
                        }
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
        
        let afterSalesHistoryViewController = AfterSalesHistoryViewController()
        
        if let orderSectionData = self.orderSectionData {
            afterSalesHistoryViewController.order = orderSectionData.order
            afterSalesHistoryViewController.afterSalesKey = afterSalesKey
            afterSalesHistoryViewController.orderDisplayStatus = (orderDisplayStatus != .unknown) ? orderDisplayStatus : orderSectionData.orderDisplayStatus
            afterSalesHistoryViewController.orderSectionData = orderSectionData
            afterSalesHistoryViewController.originalViewMode = originalViewMode
        } else {
            ErrorLogManager.sharedManager.recordNonFatalError(withException: .NullPointerOrTypeMismatch)
        }
        
        afterSalesHistoryViewController.delegate = self
        
        if let navigationController = viewController.navigationController {
            navigationController.push(afterSalesHistoryViewController, animated: true)
        } else {
            ErrorLogManager.sharedManager.recordNonFatalError(withException: .NullPointer)
        }
    }
}

internal class OrderItemShipment {
    
    var orderItem: OrderItem?
    var orderDisplayStatus: Constants.OrderDisplayStatus = .unknown
    
    init(orderItem: OrderItem, orderDisplayStatus: Constants.OrderDisplayStatus) {
        self.orderItem = orderItem
        self.orderDisplayStatus = orderDisplayStatus
    }
}
