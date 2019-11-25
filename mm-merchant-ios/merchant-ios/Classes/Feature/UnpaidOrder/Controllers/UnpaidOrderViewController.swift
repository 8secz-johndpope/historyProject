//
//  UnpaidOrderViewController.swift
//  merchant-ios
//
//  Created by Jerry Chong on 30/8/2017.
//  Copyright © 2017 WWE & CO. All rights reserved.
//

import Foundation
import UIKit
import SnapKit
import PromiseKit
import ObjectMapper

class UnpaidOrderViewController: OrderBaseViewController {
    
    var cancelReasons: [OrderCancelReason]?
    
    private final let TopMenuViewButtonCount = 5
    private final let OrderActionCellHeight: CGFloat = 50

    private var noOrderView: UIView!
    private var dataSource = [SectionUnpaidOrderCellData]()
    private var orders = [ParentOrder]()
    private var currentPage = 1
    private var totalPage = 0
    
    var viewMode: Constants.OmsViewMode = .all
    var viewHeight: CGFloat = 0
    var fromViewController: UIViewController?
    weak var parentOrderManagementPage: OrderManagementCollectionViewController? = nil
    var countDownTimer: Timer?
    var checkoutHandler: CheckoutHandler!
    
    var shouldRefreshOrderList = true
    
    private var orderLoadingView = UIActivityIndicatorView()
    private enum LoadingType {
        case normal
        case loading
    }
    private var loadingType = LoadingType.normal {
        didSet {
            switch loadingType {
            case .normal:
                DispatchQueue.main.async(execute: {
                    self.orderLoadingView.stopAnimating()
                })
                break
            case .loading:
                DispatchQueue.main.async(execute: {
                    self.orderLoadingView.startAnimating()
                })
                break
            }
        }
    }
    
    deinit {
        countDownTimer?.invalidate()
        countDownTimer = nil
    }

    override func viewDidLoad(){
        
        self.title = String.localize("LB_CA_MY_ORDERS")
        self.view.backgroundColor = UIColor.clear
        
        createBackButton()
        setupCollectionView()
        setupNoOrderView()
        initAnalyticsViewRecord(viewDisplayName: String.localize("LB_CA_PROD_DESC"), viewLocation: "PendingPayment", viewType: "PendingPayment")
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        if shouldRefreshOrderList{
            //shouldRefreshOrderList = false
            updateDataView(viewMode)
        }
    }

    private func setupCollectionView() {
        
        let layout: UICollectionViewFlowLayout = UICollectionViewFlowLayout()
        layout.scrollDirection = .vertical
        layout.itemSize = CGSize(width: view.bounds.width, height: 100)
        layout.sectionInset = UIEdgeInsets.init()
        layout.minimumInteritemSpacing = 0
        layout.minimumLineSpacing = 0
        
        collectionView = MMCollectionView(frame: view.frame, collectionViewLayout: layout)
        
        collectionView.backgroundColor = UIColor.clear
        collectionView.register(UICollectionViewCell.self, forCellWithReuseIdentifier: "DefaultCellID")
        collectionView.register(OrderItemCell.self, forCellWithReuseIdentifier: OrderItemCell.CellIdentifier)
        collectionView.register(OrderMerchantCell.self, forCellWithReuseIdentifier: OrderMerchantCell.CellIdentifier)
        collectionView.register(OrderUnpaidActionCell.self, forCellWithReuseIdentifier: OrderUnpaidActionCell.CellIdentifier)
        collectionView.register(UnpaidSectionHeaderView.self, forSupplementaryViewOfKind: UICollectionElementKindSectionHeader, withReuseIdentifier: UnpaidSectionHeaderView.ViewIdentifier)
        collectionView.register(UICollectionReusableView.self, forSupplementaryViewOfKind: UICollectionElementKindSectionFooter, withReuseIdentifier: "CollectionFooter")
        
        collectionView.frame = CGRect(x: 0, y: 0, width: ScreenWidth, height: viewHeight)
        collectionView.contentInset = UIEdgeInsets(top: 0, left: PaddingContent, bottom: 0, right: PaddingContent)
        view.addSubview(collectionView)
        
        collectionView.delegate = self
        collectionView.dataSource = self
        
        let animator = MMRefreshAnimator(frame: CGRect(x: 0, y: 0, width: self.collectionView.frame.width, height: 80))
        
        collectionView.addPullToRefreshWithAction({ [weak self] in
            if let strongSelf = self {
                strongSelf.updateDataView(strongSelf.viewMode)
            } else {
                ErrorLogManager.sharedManager.recordNonFatalError(withException: .NullPointer)
            }
            }, withAnimator: animator)
        
        collectionView.pullToRefreshView?.frame = CGRect(x: -PaddingContent, y: -animator.height, width: self.collectionView.frame.width, height: animator.height)
        
    }
    
    @objc func timeUpdate() {
        NotificationCenter.default.post(name: Constants.Notification.updateTimeNotification, object: nil)
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
        actionButton.setTitle(String.localize("LB_CA_SHOP_AROUND"), for: UIControlState())
        actionButton.addTarget(self, action: #selector(self.backToProduct(_:)), for: .touchUpInside)
        noOrderView.addSubview(actionButton)
        
        let label = UILabel(frame: CGRect(x: 0, y: boxImageView.frame.maxY, width: noOrderViewSize.width, height: actionButton.frame.minY - boxImageView.frame.maxY))
        label.textAlignment = .center
        label.formatSize(16)
        label.textColor = UIColor.secondary3()
        label.text = String.localize("LB_CA_ORDER_CONTENT_EMPTY")
        noOrderView.addSubview(label)
        
        view.addSubview(noOrderView)
    }
    
    private func addSwipeGesture(_ selector: Selector, direction: UISwipeGestureRecognizerDirection) -> UISwipeGestureRecognizer{
        let swipeGestureRecognizer = UISwipeGestureRecognizer(target: self, action: selector)
        swipeGestureRecognizer.direction = direction
        swipeGestureRecognizer.delegate = self
        self.collectionView.addGestureRecognizer(swipeGestureRecognizer)
        return swipeGestureRecognizer
    }
    
    @objc func backToProduct(_ sender: UIButton) {
        self.ssn_home()
    }
    
    private func fetchOrders(inViewMode viewMode: Constants.OmsViewMode, atPage page: Int) -> Promise<Any> {
        return Promise { fulfill, reject in
            OrderService.viewUnpaidOrder(page: page, completion: { [weak self] (response) in
                let statusCode = response.response?.statusCode ?? 0
                
                if let strongSelf = self {
                    if response.result.isSuccess {
                        if statusCode == 200 {
                            if let orderList = Mapper<OrderUnpaidList>().map(JSONObject: response.result.value) {
                                
                                print(response.description)
                                strongSelf.currentPage = orderList.pageCurrent
                                strongSelf.totalPage = orderList.pageTotal
                                
                                if orderList.pageData != nil {
                                    if let pageData = orderList.pageData {
                                        strongSelf.orders.append(contentsOf: pageData)
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
    
    // Update list data base on view mode
    
    private func updateDataView(viewMode: Constants.OmsViewMode) {
        self.viewMode = viewMode
        loadOrders(clearOrderList: true)
    }
    
    private func showPopupOrderSuccess(parentOrder: ParentOrder?) {
        if let targetViewController = self.fromViewController, let navigationController = targetViewController.navigationController {
            
            //Profile Popup VC
            let profilePopupViewController = ProfilePopupViewController(presenttationStyle: .none)
            profilePopupViewController.popupType = .OrderSuccess
            profilePopupViewController.viewOrderPressed = { [weak self] in
                if let strongSelf = self {
                    navigationController.popViewController(animated: false)
                    strongSelf.gotoOrderDetail(parentOrder: parentOrder)
                    
                }
            }
            
            profilePopupViewController.handleDismiss = {
                
                //Go back to previous screen
                navigationController.dismiss(animated: true, completion: nil)
            }
            navigationController.pushViewController(profilePopupViewController, animated: true)
        }
    }
    
    private func gotoOrderDetail(parentOrder: ParentOrder?) {
        
        if let targetViewController = self.fromViewController, let navigationController = targetViewController.navigationController {
            if let parentOrder = parentOrder, let order = parentOrder.orders?.first {
                let sectionData = OrderManager.buildOrderSectionData(withOrder: order)
                let orderDetailViewController = OrderDetailViewController()
                orderDetailViewController.originalViewMode = .toBeShipped
                orderDetailViewController.orderSectionData = sectionData
                navigationController.pushViewController(orderDetailViewController, animated: true)
            }
        }
    }
    
    func numberOfSectionsInCollectionView(collectionView: UICollectionView) -> Int {
        return dataSource.count
    }
    
    override func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return self.dataSource[section].datasource.count

    }
    
    override func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, minimumLineSpacingForSectionAt section: Int) -> CGFloat {
        return 0
    }
    
    override func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, minimumInteritemSpacingForSectionAt section: Int) -> CGFloat {
        return 0
    }
    
    override func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        let sectionData = self.dataSource[indexPath.section]
        let data = sectionData.datasource[indexPath.row]
        
        // Load More
        if indexPath.section == self.dataSource.count - 1 && indexPath.row == 0 && totalPage > currentPage {
            loadOrders(atPage: currentPage + 1)
        }
        
        if data.type == .merchant{
            let cell = collectionView.dequeueReusableCell(withReuseIdentifier: OrderMerchantCell.CellIdentifier, for: indexPath) as! OrderMerchantCell
            if let _data = data.content as? Order{
                cell.IsForUnpaid = true
                cell.unpaidData = _data
                cell.csButton.isHidden = true
                cell.headerTappedHandler = { [weak self] (order) in
                    if let strongSelf = self {
                        if (strongSelf.orders.indices.contains(indexPath.section)){
                            let order = strongSelf.orders[indexPath.section]
                            if let targetViewController = strongSelf.fromViewController, let navigationController = targetViewController.navigationController {
                                let orderDetailViewController = DetailUnpaidOrderViewController(nibName: nil, bundle: nil)
                                orderDetailViewController.parentOrder = order
                                navigationController.push(orderDetailViewController, animated: true)
                            }
                        }
                        
                    } else {
                        ErrorLogManager.sharedManager.recordNonFatalError(withException: .NullPointer)
                    }
                }
                
                if (orders.indices.contains(indexPath.section)){
                    let po = orders[indexPath.section]
                    let firstOrderId = po.orders?[0].merchantId
                    if firstOrderId != _data.merchantId{
                        cell.showTopView(true)
                    }else{
                        cell.showTopView(false)
                    }
                }
                
            }
            cell.showDisclosureIndicator(false)
            return cell
        } else if data.type == .item {
            let cell = collectionView.dequeueReusableCell(withReuseIdentifier: OrderItemCell.CellIdentifier, for: indexPath) as! OrderItemCell
            cell.viewMode = viewMode
            if let _data = data.content as? OrderItem{
                cell.unpaidData = _data
            }
            
            cell.hideAfterSaleQuantityLabel(false)
            cell.bottomBorderView.isHidden = true
            
            cell.updateLayout()
            
            return cell
        } else if data.type == .action {
            let cell = collectionView.dequeueReusableCell(withReuseIdentifier: OrderUnpaidActionCell.CellIdentifier, for: indexPath) as! OrderUnpaidActionCell
            
            if let _data = data.content as? ParentOrder{
                cell.lastCreateDate = _data.lastCreated
                cell.parentOrder = _data
                cell.cancelOrderHandler = { [weak self] in
                    if let strongSelf = self {
                        
                        let completion = {
                            
                            let alertController = UIAlertController(title: String.localize("LB_CA_COUPON_UNBUNDLE_CANCEL_ORDER"),
                                                                    message: String.localize("LB_CA_COUPON_UNBUNDLE_CANCEL_ORDER_DESC"),
                                                                    preferredStyle: UIAlertControllerStyle.alert)
                            
                            for reason in strongSelf.cancelReasons! {
                                alertController.addAction(UIAlertAction(title: reason.reasonName, style: .default) { UIAlertAction in
                                    OrderService.expireOrder(_data.parentOrderKey, reason: reason.reasonName, completion: { (response) in
                                        if response.result.isSuccess, response.response?.statusCode == 200 {
                                            strongSelf.showSuccessPopupWithText(String.localize("LB_CA_COUPON_UNBUNDLE_CANCEL_SUCCESS"))
                                            strongSelf.loadOrders(clearOrderList: true)
                                        } else {
                                            strongSelf.showSuccessPopupWithText(String.localize("LB_CA_COUPON_UNBUNDLE_CANCEL_FAIL"))
                                        }
                                    })
                                })
                            }
                            alertController.addAction(UIAlertAction(title: String.localize("LB_CA_CANCEL"), style: .cancel))
                            alertController.view.tintColor = UIColor.alertTintColor()
                            strongSelf.present(alertController, animated: true, completion: nil)
                        }
                        
                        if let _ = strongSelf.cancelReasons {
                            completion()
                        } else {
                            OrderService.unpaidOrderCancelReason({ (_reasons) in
                                strongSelf.cancelReasons = _reasons
                                completion()
                            })
                        }
                        
                    }
                }
                
                cell.payHandler = { [weak self] in
                    if let strongSelf = self {
                        strongSelf.view.recordAction(.Tap, sourceRef: "Pay", sourceType: .Button, targetRef: "Payment-Alipay", targetType: .View)
                        
                        strongSelf.checkoutHandler = CheckoutHandler(unpaidViewController: strongSelf, dismiss: { (parentOrder) -> Void in
                            
                            if let po = parentOrder {
                                strongSelf.view.recordAction(.Submit, sourceRef: po.parentOrderKey, sourceType: .ParentOrder, targetRef: "Payment-Alipay", targetType: .View)
                                
                                if let orders = po.orders {
                                    for order in orders {
                                        strongSelf.view.recordAction(.Submit, sourceRef: order.orderKey, sourceType: .MerchantOrder, targetRef: "Payment-Alipay", targetType: .View)
                                    }
                                }
                                
                                if po.parentOrderStatusId == 2 || po.parentOrderStatusId == 3 {
                                    strongSelf.showPopupOrderSuccess(parentOrder: po)
                                }else{
                                    let alertController = UIAlertController(title: String.localize("LB_CA_UNPAID_ORDER_FAILED_TO_PAY"), message: String.localize("LB_CA_UNPAID_ORDER_FAILED_TO_PAY_DIALOG"), preferredStyle: UIAlertControllerStyle.alert)
                                    var okString: String!
                                    okString = String.localize("LB_CA_UNPAID_ORDER_CHECK_ORDER")
                                    let okAction = UIAlertAction(title: okString, style: .default) { UIAlertAction in
                                        strongSelf.view.recordAction(.Tap, sourceRef: "CheckOrder", sourceType: .Button, targetRef: "PendingPayment", targetType: .View)
                                    }
                                    alertController.addAction(okAction)
                                    strongSelf.present(alertController, animated: true, completion: nil)
                                }
                            } else {
                                ErrorLogManager.sharedManager.recordNonFatalError(withException: .NullPointer)
                            }
                        })
                        
                        strongSelf.checkoutHandler.processUnpaidPayment(_data, completion: { (success, error) in
                            if success {
                                strongSelf.loadOrders(clearOrderList: true)
                            } else {
                                if let error = error, error.domain.isEmpty {
                                    Alert.alertWithSingleButton(strongSelf, title:  String.localize("LB_CA_UNPAID_ORDER_FAILED_TO_PAY"), message: String.localize("LB_CA_UNPAID_ORDER_FAILED_TO_PAY_DIALOG"))
                                } else {
                                    Alert.alertWithSingleButton(strongSelf, title: String.localize("LB_CA_PAYMENT_UNUSUAL_WARNING_MESSAGE"), message: "")
                                }
                            }
                        })
                        
                    }
                    
                }
            }
            
            
            return cell
        } else {
            return getDefaultCell(collectionView, cellForItemAt: indexPath)
        }
    }
    
}

extension UnpaidOrderViewController {
    // MARK: - Data Processing
    func loadOrders(atPage page: Int = 1, clearOrderList: Bool = false) {
        DispatchQueue.main.async(execute: {
            self.loadingType = LoadingType.loading
        })
        
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
                
            }.catch { error in 
                DispatchQueue.main.async {
                    self.loadingType = LoadingType.normal
                }
                self.collectionView.stopPullToRefresh() //Stop animation for pull to refresh (If Any)
        }
    }

    private func reloadDataSource() {
        self.dataSource.removeAll()
        
        let successParentOrderKeys = CheckoutService.defaultService.getSuccessParentOrderKey()
        for successParentOrderKey in successParentOrderKeys {
            orders = orders.filter{ $0.parentOrderKey == successParentOrderKey }
        }
        
        
        for order in orders {
            dataSource.append(OrderManager.buildUnpaidOrderSectionData(withOrder: order))
        }
        
        noOrderView.isHidden = (dataSource.count > 0)
        
        if dataSource.count == 0 && totalPage > currentPage {
            // Load more
            loadOrders(atPage: currentPage + 1)
            DispatchQueue.main.async(execute: {
                self.collectionView.reloadData()
            })
            
        } else {
            // Must Reload Data before stop pull to refresh
            DispatchQueue.main.async(execute: {
                self.collectionView.reloadData()
            })
            
            // We recurse loadOrders so only stop loading indicator when we stop load more
            DispatchQueue.main.async(execute: {
                self.loadingType = LoadingType.normal
            })
            self.collectionView.stopPullToRefresh()
        }
        
        if(dataSource.count > 0){
            countDownTimer = Timer.scheduledTimer(timeInterval: 1.0, target: self, selector: #selector(self.timeUpdate), userInfo: nil, repeats: true)
        }else{
            countDownTimer?.invalidate()
            countDownTimer = nil
        }
    }
    
    // Update list data base on view mode
    
    private func updateDataView(_ viewMode: Constants.OmsViewMode) {
        self.viewMode = viewMode
        loadOrders(clearOrderList: true)
    }
}

extension UnpaidOrderViewController {
    func numberOfSections(in collectionView: UICollectionView) -> Int {
        return dataSource.count
    }
    
    func collectionView(_ collectionView: UICollectionView, viewForSupplementaryElementOfKind kind: String, at indexPath: IndexPath) -> UICollectionReusableView {
        switch kind {
        case UICollectionElementKindSectionHeader:
            let view = collectionView.dequeueReusableSupplementaryView(ofKind: kind, withReuseIdentifier: UnpaidSectionHeaderView.ViewIdentifier, for: indexPath) as! UnpaidSectionHeaderView
            if (orders.indices.contains(indexPath.section)){
                let order = self.orders[indexPath.section]
                view.data = order
                view.orderCreatedDate = order.lastCreated
                view.headerTapHandler = { [weak self] in
                    if let strongSelf = self {
                        if let targetViewController = strongSelf.fromViewController, let navigationController = targetViewController.navigationController {
                            let orderDetailViewController = DetailUnpaidOrderViewController(nibName: nil, bundle: nil)
                            orderDetailViewController.parentOrder = order
                            navigationController.push(orderDetailViewController, animated: true)
                        }
                    }
                }
            }
            
            return view
            
        case UICollectionElementKindSectionFooter:
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
        default:
            return UICollectionReusableView()
        }
    }
}


// MARK: UICollectionViewDelegate
extension UnpaidOrderViewController {
    func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        if (orders.indices.contains(indexPath.section)){
            let order = self.orders[indexPath.section]
            if let targetViewController = self.fromViewController, let navigationController = targetViewController.navigationController {
                view.recordAction(.Tap, sourceRef: "PendingPayment", sourceType: .Banner, targetRef: "PendingPayment-Detail", targetType: .View)
                
                let orderDetailViewController = DetailUnpaidOrderViewController(nibName: nil, bundle: nil)
                orderDetailViewController.parentOrder = order
                navigationController.push(orderDetailViewController, animated: true)
            }
        }
    }
}



// MARK: UICollectionViewDelegateFlowLayout
extension UnpaidOrderViewController {
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, sizeForItemAt indexPath: IndexPath) -> CGSize {
        let sectionData = self.dataSource[indexPath.section]
        let data = sectionData.datasource[indexPath.row]
        var cellHeight: CGFloat = 0
        
        if data.type == .merchant{
            cellHeight = OrderStatusCellHeight
        } else if data.type == .item {
            cellHeight = OrderItemCell.DefaultHeight
        } else if data.type == .action {
            cellHeight = OrderActionCellHeight
        }
        
        if cellHeight > 0 {
            return CGSize(width: view.width - (PaddingContent * 2), height: cellHeight)
        } else {
            return CGSize.zero
        }
    }
    
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, insetForSectionAt section: Int) -> UIEdgeInsets {
        return UIEdgeInsets(top: 0, left: 0 , bottom: 0, right: 0)
    }
    
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, referenceSizeForHeaderInSection section: Int) -> CGSize {
        _ = self.dataSource[section]
        
//        if sectionData.sectionHeader != nil && sectionData.dataSource.count > 0 {
            return CGSize(width: self.view.bounds.width, height: UnpaidSectionHeaderView.DefaultHeight)
//        }
        
    }
    
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, referenceSizeForFooterInSection section: Int) -> CGSize {
        if(section == self.dataSource.count - 1) {
            return CGSize(width: collectionView.bounds.width, height: 40)
        }else{
            return CGSize(width: collectionView.bounds.width, height: 0)
        }
    }

}

