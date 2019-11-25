//
//  OrderManagementViewController.swift
//  merchant-ios
//
//  Created by Gambogo on 3/30/16.
//  Copyright © 2016 WWE & CO. All rights reserved.
//

import Foundation
import PromiseKit
import ObjectMapper
import Refresher

class OrderManagementViewController: OrderBaseViewController, OrderActionCellDelegate, OrderDetailViewControllerDelegate, OrderReviewViewControllerDelegate, AfterSalesHistoryViewProtocol {    
    
    private final let TopMenuViewButtonCount = 5
    private final let OrderActionCellHeight: CGFloat = 50
    
    private var noOrderView: UIView!
    private var dataSource = [OrderSectionData]()
    private var orders = [Order]()
    private var currentPage = 1
    private var totalPage = 0
    
    var viewMode: Constants.OmsViewMode = .all
    var viewHeight: CGFloat = 0
    var fromViewController: UIViewController?
    weak var parentOrderManagementPage: OrderManagementCollectionViewController? = nil
    
    var shouldRefreshOrderList = true
    
    // MARK: - Loading View
    private var orderLoadingView = UIActivityIndicatorView()
    private enum LoadingType {
        case Normal
        case Loading
    }
    private var loadingType = LoadingType.Normal {
        didSet {
            switch loadingType {
            case .Normal:
                main_async{
                    self.orderLoadingView.stopAnimating()
                }
                break
            case .Loading:
                main_async{
                    self.orderLoadingView.startAnimating()
                }
                break
            }
        }
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        
        self.title = String.localize("LB_CA_MY_ORDERS")
        self.view.backgroundColor = UIColor.clear
        
        createBackButton()
        setupCollectionView()
        setupNoOrderView()
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        if shouldRefreshOrderList{
            shouldRefreshOrderList = false
            updateDataView(viewMode)
        }
    }
  
    // MARK: - Views
    
    private func setupCollectionView() {
        collectionView.backgroundColor = UIColor.clear
        collectionView.register(UICollectionViewCell.self, forCellWithReuseIdentifier: DefaultCellID)
        
        collectionView.register(OrderItemCell.self, forCellWithReuseIdentifier: OrderItemCell.CellIdentifier)
        collectionView.register(OrderStatusCell.self, forCellWithReuseIdentifier: OrderStatusCell.CellIdentifier)
        collectionView.register(OrderActionCell.self, forCellWithReuseIdentifier: OrderActionCell.CellIdentifier)
        
        collectionView.register(MerchantSectionHeaderView.self, forSupplementaryViewOfKind: UICollectionElementKindSectionHeader, withReuseIdentifier: MerchantSectionHeaderView.ViewIdentifier)
        collectionView.register(UICollectionReusableView.self, forSupplementaryViewOfKind: UICollectionElementKindSectionFooter, withReuseIdentifier: "CollectionFooter")
        
        collectionView.frame = CGRect(x:0, y: 0, width: ScreenWidth, height: viewHeight)
        collectionView.contentInset = UIEdgeInsets(top: 0, left: PaddingContent, bottom: 0, right: PaddingContent)
        
        let animator = MMRefreshAnimator(frame: CGRect(x:0, y: 0, width: self.collectionView.frame.width, height: 80))
        
        self.collectionView.addPullToRefreshWithAction({ [weak self] in
            if let strongSelf = self {
                strongSelf.updateDataView(strongSelf.viewMode)
            } else {
                ErrorLogManager.sharedManager.recordNonFatalError(withException: .NullPointer)
            }
        }, withAnimator: animator)
        
        self.collectionView.pullToRefreshView?.frame = CGRect(x:-PaddingContent, y: -animator.height, width: self.collectionView.frame.width, height: animator.height)
    }
    
    private func setupNoOrderView() {
        let noOrderViewSize = CGSize(width: 90, height: 156)
        noOrderView = UIView(frame: CGRect(x: (view.width - noOrderViewSize.width) / 2, y: (collectionView.height - noOrderViewSize.height) / 2, width: noOrderViewSize.width, height: noOrderViewSize.height))
        noOrderView.isHidden = true
        
        let boxImageViewSize = CGSize(width: 76, height: 76)
        let boxImageView = UIImageView(frame: CGRect(x: (noOrderView.width - boxImageViewSize.width) / 2, y: 0, width: boxImageViewSize.width, height: boxImageViewSize.height))
        boxImageView.image = UIImage(named: "icon_oms_no_order")
        noOrderView.addSubview(boxImageView)
        
        let actionButtonSize = CGSize(width: 90, height: 25)
        let actionButton = ActionButton(frame: CGRect(x: 0, y: noOrderView.height - actionButtonSize.height, width: actionButtonSize.width, height: actionButtonSize.height))
        actionButton.setTitle(String.localize("LB_CA_SHOP_AROUND"), for: .normal)
        actionButton.addTarget(self, action: #selector(self.backToProduct), for: .touchUpInside)
        noOrderView.addSubview(actionButton)
        
        let label = UILabel(frame: CGRect(x: 0, y: boxImageView.frame.maxY, width: noOrderViewSize.width, height: actionButton.frame.minY - boxImageView.frame.maxY))
        label.textAlignment = .center
        label.formatSize(16)
        label.textColor = UIColor.secondary3()
        label.text = String.localize("LB_CA_ORDER_CONTENT_EMPTY")
        noOrderView.addSubview(label)
        
        view.addSubview(noOrderView)
    }
    
    private func addSwipeGesture(selector: Selector, direction: UISwipeGestureRecognizerDirection) -> UISwipeGestureRecognizer{
        let swipeGestureRecognizer = UISwipeGestureRecognizer(target: self, action: selector)
        swipeGestureRecognizer.direction = direction
        swipeGestureRecognizer.delegate = self
        self.collectionView.addGestureRecognizer(swipeGestureRecognizer)
        return swipeGestureRecognizer
    }
    
    @objc func backToProduct(sender: UIButton) {
        self.ssn_home()
    }
    
    // MARK: - Data Processing
    
    private func loadOrders(atPage page: Int = 1, clearOrderList: Bool = false) {
        main_async{
            self.loadingType = LoadingType.Loading
        }
        
        if clearOrderList {
            orders.removeAll()
            currentPage = 1
            totalPage = 0
        }
        
        firstly {
            return fetchOrders(inViewMode: self.viewMode, atPage: page)
        }.then { _ -> Void in
            self.reloadDataSource()
        }.always {
            
        }.catch { _ -> Void in
            main_async{
                self.loadingType = LoadingType.Normal
            }
            self.collectionView.stopPullToRefresh() //Stop animation for pull to refresh (If Any)
        }
    }
    
    private func fetchOrders(inViewMode viewMode: Constants.OmsViewMode, atPage page: Int) -> Promise<Any> {
        return Promise { fulfill, reject in
            OrderService.listOrder(onViewMode: viewMode, page: page, completion: { [weak self] (response) in
                let statusCode = response.response?.statusCode ?? 0
                
                if let strongSelf = self {
                    if response.result.isSuccess {
                        if statusCode == 200 {
                            if let orderList = Mapper<OrderList>().map(JSONObject: response.result.value) {
                                strongSelf.currentPage = orderList.pageCurrent
                                strongSelf.totalPage = orderList.pageTotal
                                
                                if orderList.pageData != nil {
                                    switch viewMode {
                                    case .all:
                                        if let pageData = orderList.pageData {
                                            // Not required to split order
                                            strongSelf.orders.append(contentsOf: pageData)
                                        }
                                    case .toBeShipped:
                                        // Not required to split order, but need to filter out the order without "to be shipped"
                                        for order in orderList.pageData ?? [] {
                                            if order.unprocessedShipment != nil {
                                                strongSelf.orders.append(order)
                                            } else if let orderShipments = order.orderShipments {
                                                for orderShipment in orderShipments {
                                                    if orderShipment.orderShipmentStatus == .pendingShipment || orderShipment.orderShipmentStatus == .toShipToConsolidationCentre{
                                                        strongSelf.orders.append(order)
                                                        break
                                                    }
                                                }
                                            }
                                        }
                                    case .toBeReceived:
                                        // Not required to split order, but need to filter out the order without "to be received"
                                        for order in orderList.pageData ?? [] {
                                            if let orderShipments = order.orderShipments {
                                                for orderShipment in orderShipments {
                                                    let status = orderShipment.orderShipmentStatus
                                                    
                                                    //MM-24638 .ToShipToConsolidationCentre is belong to ToBeShipped tab
                                                    if (status == .shipped || status == .pendingCollection || status == .shippedToConsolidationCentre || status == .receivedToConsolidationCentre) {
                                                        strongSelf.orders.append(order)
                                                        break
                                                    }
                                                }
                                            }
                                        }
                                    case .toBeRated:
                                        // Split by shipment, need to filter out the order without "to be rated"
                                        for order in orderList.pageData ?? [] {
                                            if let orderShipments = order.orderShipments {
                                                for orderShipment in orderShipments where !orderShipment.isReviewSubmitted {
                                                    let status = orderShipment.orderShipmentStatus
                                                    
                                                    if (status == .received || status == .collected) {
                                                        let order = order.copy()
                                                        order.filteredOrderShipmentKey = orderShipment.orderShipmentKey
                                                        strongSelf.orders.append(order)
                                                    }
                                                }
                                            }
                                        }
                                    case .afterSales:
                                        // Split by order cancel / order return
                                        for order in orderList.pageData ?? [] {
                                            let orders = OrderManager.splitOrder(order)
                                            strongSelf.orders.append(contentsOf: orders)
                                        }
                                    default:
                                        break
                                    }
                                } else {
                                    ErrorLogManager.sharedManager.recordNonFatalError(withMessage: "Null page data in order list.")
                                }
                            } else {
                                ErrorLogManager.sharedManager.recordNonFatalError(withException: .DataIsEmpty)
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
    
    // Update list contents
    
    private func reloadDataSource() {
        self.dataSource.removeAll()
        
        for order in orders {
            if showOrder(orderStatus: order.orderStatus) {
                dataSource.append(OrderManager.buildOrderSectionData(withOrder: order, viewMode: viewMode))
            }
        }
        
        noOrderView.isHidden = (dataSource.count > 0)
        
        if dataSource.count == 0 && totalPage > currentPage {
            // Load more
            loadOrders(atPage: currentPage + 1)
            main_async{
                self.collectionView.reloadData()
            }
            
        } else {
            // Must Reload Data before stop pull to refresh
            main_async{
                self.collectionView.reloadData()
            }
            
            // We recurse loadOrders so only stop loading indicator when we stop load more
            main_async{
                self.loadingType = LoadingType.Normal
            }
            self.collectionView.stopPullToRefresh()
        }
    }
    
    // Update list data base on view mode
    
    private func updateDataView(_ viewMode: Constants.OmsViewMode) {
        self.viewMode = viewMode
        loadOrders(clearOrderList: true)
    }
    
    // MARK: - Collection View Data Source methods
    
    func numberOfSections(in collectionView: UICollectionView) -> Int {
        return self.dataSource.count
    }
    
    override func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return self.dataSource[section].dataSource.count
    }
    
    override func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        
        if indexPath.section >= self.dataSource.count {
              return getDefaultCell(collectionView, cellForItemAt: indexPath)
        }
        
        let sectionData = self.dataSource[indexPath.section]
        let data = sectionData.dataSource[indexPath.row]
        
        // Load More
        if indexPath.section == self.dataSource.count - 1 && indexPath.row == 0 && totalPage > currentPage {
            loadOrders(atPage: currentPage + 1)
        }
        
        if type(of: data) == OrderStatusData.self {
            let cell = collectionView.dequeueReusableCell(withReuseIdentifier: OrderStatusCell.CellIdentifier, for: indexPath) as! OrderStatusCell
            cell.showInOrderList = true
            cell.data = data as? OrderStatusData
            
            return cell
        } else if type(of: data) == OrderItem.self {
            let cell = collectionView.dequeueReusableCell(withReuseIdentifier: sectionData.reuseIdentifier, for: indexPath) as! OrderItemCell
            cell.viewMode = viewMode
            cell.orderDisplayStatus = sectionData.orderDisplayStatus
            
            if let orderItem = data as? OrderItem {
                cell.data = orderItem
                
                if viewMode == .toBeRated {
                    // Split by shipment, get qtyShipped for this shipment
                    if let orderShipment = sectionData.orderShipment, let orderShipmentItems = orderShipment.orderShipmentItems {
                        for orderShipmentItem in orderShipmentItems where orderShipmentItem.skuId == orderItem.skuId {
                            cell.setQuantityShipped(orderShipmentItem.qtyShipped)
                            cell.setProductQty(orderShipmentItem.qtyShipped)
                            break
                        }
                    }
                } else {
                    cell.setQuantityShipped(orderItem.qtyShipped)
                }
            }
            
            cell.hideAfterSaleQuantityLabel(viewMode == .afterSales)
            cell.bottomBorderView.isHidden = true
            
            cell.updateLayout()
            
            return cell
        } else if type(of: data) == OrderActionData.self {
            let cell = collectionView.dequeueReusableCell(withReuseIdentifier: OrderActionCell.CellIdentifier, for: indexPath) as! OrderActionCell
            cell.data = data as? OrderActionData
            cell.isShowInDetailView = false
            cell.isDisplayShipmentAndReviewButtons = (viewMode == .toBeReceived || viewMode == .toBeRated)
            
            cell.delegate = self
            
            if let order = sectionData.order {
                cell.contactHandler = { [weak self] in
                    if let strongSelf = self {
                        if let fromvc = strongSelf.fromViewController {
                            strongSelf.contactCustomerServiceWithOrder(fromvc ,order: order, viewMode: strongSelf.viewMode)
                        }
                        
                    }
                }
            }

            return cell
        } else {
            return getDefaultCell(collectionView, cellForItemAt: indexPath)
        }
    }
    
    func collectionView(_ collectionView: UICollectionView, viewForSupplementaryElementOfKind kind: String, at indexPath: IndexPath) -> UICollectionReusableView {
        switch kind {
        case UICollectionElementKindSectionHeader:
            let view = collectionView.dequeueReusableSupplementaryView(ofKind: kind, withReuseIdentifier: MerchantSectionHeaderView.ViewIdentifier, for: indexPath) as! MerchantSectionHeaderView
            
            guard self.dataSource.indices.contains(indexPath.section) else {
                return view
            }
            
            view.data = self.dataSource[indexPath.section]
            view.headerTappedHandler = { [weak self] (data) in
                if let strongSelf = self, let order = data.order {
                    if let fromvc = strongSelf.fromViewController {
                        DeepLinkManager.sharedManager.pushMerchantById(order.merchantId, fromViewController: fromvc)
                    }
                }
            } 
            return view
            
        case UICollectionElementKindSectionFooter:
            if (self.dataSource.count) > 0 {
                if(indexPath.section == self.dataSource.count - 1){
                    let footercollectionView = collectionView.dequeueReusableSupplementaryView(ofKind: kind, withReuseIdentifier: "CollectionFooter", for: indexPath)
                    footercollectionView.backgroundColor = UIColor.clear
                    let footerView = UIView(frame: CGRect(x: 0, y: 0, width: collectionView.bounds.width, height: 40))
                    orderLoadingView.activityIndicatorViewStyle = UIActivityIndicatorViewStyle.gray
                    orderLoadingView.center = footerView.center
                    footerView.addSubview(orderLoadingView)
                    footercollectionView.addSubview(footerView)
                    return footercollectionView
                }else{
                    let footercollectionView = collectionView.dequeueReusableSupplementaryView(ofKind: kind, withReuseIdentifier: "CollectionFooter", for: indexPath)
                    return footercollectionView
                }
            }else{
                let footercollectionView = collectionView.dequeueReusableSupplementaryView(ofKind: kind, withReuseIdentifier: "CollectionFooter", for: indexPath)
                return footercollectionView
            }
        default:
            return UICollectionReusableView()
        }
    }
    
    // MARK: - Collection View Delegate (Flow Layout) methods
    
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, referenceSizeForHeaderInSection section: Int) -> CGSize {
        let sectionData = self.dataSource[section]
        
        if sectionData.sectionHeader != nil && sectionData.dataSource.count > 0 {
            return CGSize(width: self.view.bounds.width, height: MerchantSectionHeaderView.DefaultHeight)
        }
        
        return CGSize.zero
    }
    
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, sizeForItemAt indexPath: IndexPath) -> CGSize {
        let sectionData = self.dataSource[indexPath.section]
        let data = sectionData.dataSource[indexPath.row]
        var cellHeight: CGFloat = 0
        
        if type(of: data) == OrderStatusData.self {
            cellHeight = OrderStatusCellHeight
        } else if type(of: data) == OrderItem.self {
            cellHeight = OrderItemCell.DefaultHeight
        } else if type(of: data) == OrderActionData.self {
            cellHeight = OrderActionCellHeight
        }
        
        if cellHeight > 0 {
            return CGSize(width: view.width - (PaddingContent * 2), height: cellHeight)
        } else {
            return CGSize.zero
        }
    }
    
    // MARK: - Collection Footer
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, referenceSizeForFooterInSection section: Int) -> CGSize {
        if(section == self.dataSource.count - 1) {
            return CGSize(width: collectionView.bounds.width, height: 40)
        }else{
            return CGSize(width: collectionView.bounds.width, height: 0)
        }
    }

    // MARK: - Collection View Delegate methods
    
    func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        let sectionData = self.dataSource[indexPath.section]
        let data = sectionData.dataSource[indexPath.row]

        
        if (type(of: data) == OrderItem.self || type(of: data) == OrderStatusData.self){
            if viewMode == .afterSales {
                showAfterSalesHistory(orderSection: sectionData)
            } else {
                main_async{
                    if let targetViewController = self.fromViewController
                        , let navigationController = targetViewController.navigationController {
                        let orderDetailViewController = OrderDetailViewController(nibName: nil, bundle: nil)
                        orderDetailViewController.delegate = self
                        orderDetailViewController.originalViewMode = self.viewMode
                        orderDetailViewController.orderSectionData = sectionData
                        navigationController.pushViewController(orderDetailViewController, animated: true)
                    }
                }
            }
        }
    }
    
    // MARK: OrderActionCellDelegate
    
    func didConfirmShipment(orderShipmentKey: String, order: Order?) {
        Alert.alert(self, title: String.localize("LB_CA_OMS_PROMPT_CONFIRM_SHIPMENT"), message: String.localize("LB_CA_OMS_SHIPMENT_RATING"), okActionComplete: { () -> Void in
            main_async{
                self.loadingType = LoadingType.Loading
            }
            
            firstly {
                return self.confirmShipment(orderShipmentKey: orderShipmentKey)
            }.then { _ -> Void in
                if let data = order {
                    self.loadOrders(clearOrderList: true)
                    if let viewControler = self.parentOrderManagementPage?.getViewControler(Constants.OmsViewMode.all) as? OrderManagementViewController{
                        viewControler.shouldRefreshOrderList = true
                    }
                    self.didRequestViewReview(data)
                }
            }.always {
                main_async{
                    self.loadingType = LoadingType.Normal
                }
                self.collectionView.stopPullToRefresh() //Stop animation for pull to refresh (If Any)
            }.catch { _ -> Void in
                Log.error("error")
            }
        }, cancelActionComplete: nil)
    }
    
    func didRequestViewReview(_ order: Order) {
        let orderReviewViewController = OrderReviewViewController()
        orderReviewViewController.order = order
        orderReviewViewController.delegate = self
        
        if let targetViewController = self.fromViewController{
            let navigationController = MmNavigationController(rootViewController: orderReviewViewController)
            targetViewController.present(navigationController, animated: true, completion: nil)
        }
        
    }
    
    func didRequestViewShipment(_ order: Order) {
        if let targetViewController = self.fromViewController
            , let navigationController = targetViewController.navigationController {
            let shipmentTrackingViewController = ShipmentTrackingViewController()
            
            if let orderShipment = order.orderShipments?.first {
                shipmentTrackingViewController.addressData = AddressData(order: order, orderShipment: orderShipment)
                shipmentTrackingViewController.orderShipment = orderShipment
            }
        
            navigationController.pushViewController(shipmentTrackingViewController, animated: true)
        }
    }
    
    // MARK: - OrderReviewViewController
    

    
    func didSubmitReview(isSuccess: Bool, shouldShowCampaignPopup: Bool) {
        if isSuccess {
            if shouldShowCampaignPopup {
                if ShareManager.sharedManager.getTopViewController() != nil {
                    let profilePopupViewController = ProfilePopupViewController()
                    profilePopupViewController.presentViewController = self.parentOrderManagementPage
                    let nvc = MmNavigationController(rootViewController: profilePopupViewController)
                    nvc.modalPresentationStyle = .custom
                    nvc.view.backgroundColor = UIColor.white.withAlphaComponent(0)
                    self.parentOrderManagementPage?.present(nvc, animated: false, completion: nil)
                }
            } else {
                self.showSuccessPopupWithText(String.localize("MSG_SUC_CA_OMS_REVIEW"))
            }
        }
    }
    
    //this happens when user close review page
    func didDismissReview() {
        if let parentOrderManagementPage = self.parentOrderManagementPage {
            parentOrderManagementPage.showView(.toBeRated)
        }
    }
    
    // MARK: - OrderDetailViewControllerDelegate
    
    func didRequestSwitchViewMode(orderDetailViewController: OrderDetailViewController, viewMode: Constants.OmsViewMode) {
        if let parentOrderManagementPage = self.parentOrderManagementPage {
            parentOrderManagementPage.showView(viewMode)
        }
    }
    
    
    func didUpdateOrder(orderDetailViewController: OrderDetailViewController, order: Order) {
        if let parentOrderManagementPage = self.parentOrderManagementPage {
            for viewController in parentOrderManagementPage.viewControllers ?? []{
                if let orderManagementViewController = viewController as? OrderManagementViewController{
                    orderManagementViewController.shouldRefreshOrderList = true
                }
            }
        }
    }
    
    //MARK: - Aftersale History Delegate
    
    func didCancelOrderDisputeFromAfterSalesHistory(_ isSuccess: Bool) {
        if isSuccess {
            updateDataView(viewMode)
        }
    }
    
    func didDisputeOrderFromAfterSalesHistory(_ isSuccess: Bool) {
        if isSuccess {
            updateDataView(viewMode)
        }
    }
    
    // MARK: - Helper
    
    private func showAfterSalesHistory(orderSection: OrderSectionData) {
        if let order = orderSection.order{
            let afterSalesHistoryViewController = AfterSalesHistoryViewController()
            afterSalesHistoryViewController.order = order
            afterSalesHistoryViewController.orderDisplayStatus = orderSection.orderDisplayStatus
            afterSalesHistoryViewController.orderSectionData = orderSection
            afterSalesHistoryViewController.originalViewMode = .afterSales
            afterSalesHistoryViewController.delegate = self
            
            if let orderCancels = order.orderCancels, orderCancels.count > 0 {
                afterSalesHistoryViewController.afterSalesKey = orderCancels.first?.orderCancelKey
            } else if let orderReturns = order.orderReturns, orderReturns.count > 0 {
                afterSalesHistoryViewController.afterSalesKey = orderReturns.first?.orderReturnKey
            }
            
            if let targetViewController = self.fromViewController
                , let navigationController = targetViewController.navigationController {
                navigationController.pushViewController(afterSalesHistoryViewController, animated: true)
            }
        }
    }
    
    private func showOrder(orderStatus: Order.OrderStatus) -> Bool {
        switch viewMode {
        case .all, .toBeShipped, .toBeReceived:
            return true
        case .toBeRated:
            return (orderStatus == .received || orderStatus == .partialShipped)
        case .afterSales:
            return orderStatus == .cancelled
        default:
            return false
        }
    }
}
