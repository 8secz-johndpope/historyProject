//
//  DetailUnpaidOrderViewController.swift
//  merchant-ios
//
//  Created by Jerry Chong on 30/8/2017.
//  Copyright © 2017 WWE & CO. All rights reserved.
//

import Foundation
import PromiseKit
import ObjectMapper

protocol DetailUnpaidOrderViewControllerDelegate: class {
    func didRequestSwitchViewMode(DetailUnpaidOrderViewController: DetailUnpaidOrderViewController, viewMode: Constants.OmsViewMode)
    func didUpdateOrder(DetailUnpaidOrderViewController: DetailUnpaidOrderViewController, order: Order)
}

class DetailUnpaidOrderViewController: OrderBaseViewController {
    private final let DetailUnpaidOrderHeaderID = "DetailUnpaidOrderHeaderID"
    private final let OrderActionCellHeight: CGFloat = 50
    private var bottomActionButtonView: OrderFooterView?
    

    
    private var timelineStatus: OrderStatusHeaderView.TimelineStatus = .unknown
    private var addressData: AddressData?
    private var shipmentAddressData: AddressData?
    private var orderSectionData = [SectionUnpaidOrderCellData]()
    var parentOrder = ParentOrder() {
        didSet{
            if let orders = parentOrder.orders{
                for order in orders{
                    let merchantID = order.merchantId
                    if let items = order.orderItems{
                        for item in items{
                            item.merchantId = merchantID
                        }
                    }
                }
            }
            
            if let orders = parentOrder.orders{
                for order in orders{
                    if let items = order.orderItems{
                        for item in items{
                            print(item.merchantId.description)
                        }
                    }
                }
            }
        }
    }
    
    
    var originalViewMode: Constants.OmsViewMode = .unpaid
    weak var delegate: DetailUnpaidOrderViewControllerDelegate?
    
    var checkoutHandler: CheckoutHandler!
    
    let confirmButton: UIButton = {
        let button = UIButton()
        button.formatPrimary()
        button.setTitle(String.localize("LB_CA_SUBMIT_ORDER"), for: UIControlState())
        return button
    }()
    
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        self.title = String.localize("LB_CA_ORDER_DTL")
        
        setupCollectionView()
        setupBottomView()
        createBackButton()
        setupSectionOrders()
        setupAnalyticsViewRecord()
    }
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
    }

    private func showPopupOrderSuccess(parentOrder: ParentOrder?) {
        if let navigationController = self.navigationController {
            
            //Profile Popup VC
            let profilePopupViewController = ProfilePopupViewController(presenttationStyle: .none)
            profilePopupViewController.popupType = .OrderSuccess
            profilePopupViewController.viewOrderPressed = { [weak self] in
                if let strongSelf = self {
                    
                    let viewControllers = navigationController.viewControllers
                    for currentVC in viewControllers {
                        if currentVC is OrderManagementCollectionViewController {
                            navigationController.popToViewController(currentVC, animated: false)
                        }
                    }
                    strongSelf.gotoOrderDetail(parentOrder: parentOrder, navigationController: navigationController)
                    
                }
            }
            
            profilePopupViewController.handleDismiss = {
                
                navigationController.popViewController(animated: true)
            }
            navigationController.pushViewController(profilePopupViewController, animated: true)
        }
    }
    
    private func gotoOrderDetail(parentOrder: ParentOrder?, navigationController: UINavigationController) {
        
        if let parentOrder = parentOrder, let order = parentOrder.orders?.first {
            let sectionData = OrderManager.buildOrderSectionData(withOrder: order)
            let orderDetailViewController = OrderDetailViewController()
            orderDetailViewController.originalViewMode = .toBeShipped
            orderDetailViewController.orderSectionData = sectionData
            navigationController.pushViewController(orderDetailViewController, animated: true)
        }
        
    }
    
    // MARK: - Setup
    
    private func setupAnalyticsViewRecord(){
        initAnalyticsViewRecord(viewDisplayName: String.localize("LB_CA_UNPAID_ORDER_FAILED_TO_PAY"), viewLocation: "PendingPayment-Detail", viewType: "PendingPayment")
    }
    
    private func setupSectionOrders() {
        self.orderSectionData = OrderManager.buildUnpaidDetailOrderSectionData(withOrder: parentOrder)
        DispatchQueue.main.async(execute: {
            self.collectionView.reloadData()
        })
    }
    
    private func setupCollectionView() {
        collectionView.backgroundColor = UIColor.backgroundGray()
        
        collectionView.register(UICollectionViewCell.self, forCellWithReuseIdentifier: "DefaultCellID")
        
        collectionView.register(OrderItemCell.self, forCellWithReuseIdentifier: OrderItemCell.CellIdentifier)
        collectionView.register(OrderMerchantCell.self, forCellWithReuseIdentifier: OrderMerchantCell.CellIdentifier)
        collectionView.register(OrderUnpaidActionCell.self, forCellWithReuseIdentifier: OrderUnpaidActionCell.CellIdentifier)
        
        //Detail
        collectionView.register(CheckoutFapiaoCell.self, forCellWithReuseIdentifier: CheckoutFapiaoCell.CellIdentifier)
        collectionView.register(CheckoutCouponCell.self, forCellWithReuseIdentifier: CheckoutCouponCell.CellIdentifier) // mmcoupon, merchant coupon, shipping fee, total
        collectionView.register(ReceiverAddressCell.self, forCellWithReuseIdentifier: ReceiverAddressCell.CellIdentifier)
        collectionView.register(CheckoutFullPaymentMethodCell.self, forCellWithReuseIdentifier: CheckoutFullPaymentMethodCell.CellIdentifier)
        collectionView.register(CheckoutCommentCell.self, forCellWithReuseIdentifier: CheckoutCommentCell.CellIdentifier)
        collectionView.register(CheckoutCell.self, forCellWithReuseIdentifier: CheckoutCell.CellIdentifier)
        
        
        collectionView.register(UnpaidSectionHeaderView.self, forSupplementaryViewOfKind: UICollectionElementKindSectionHeader, withReuseIdentifier: UnpaidSectionHeaderView.ViewIdentifier)
        collectionView.register(UICollectionReusableView.self, forSupplementaryViewOfKind: UICollectionElementKindSectionFooter, withReuseIdentifier: "CollectionFooter")
        
        collectionView.dataSource = self
        collectionView.delegate = self

    }
    
    private func setupBottomView() {
        let bottomViewHeight: CGFloat = 65
        
        collectionView.frame = CGRect(x: collectionView.x, y: collectionView.y, width: collectionView.width, height: collectionView.height - bottomViewHeight)
        
        let bottomActionButtonView = OrderFooterView(frame: CGRect(x: collectionView.x, y: collectionView.frame.maxY, width: collectionView.width, height: bottomViewHeight))
        self.bottomActionButtonView = bottomActionButtonView
        var saveAmount: Double = 0
        saveAmount += parentOrder.mmCouponAmount
        if let orders = parentOrder.orders {
            for order in orders {
                saveAmount += order.couponAmount
            }
        }
        bottomActionButtonView.setParentOrder(parentOrder, vc: self)
        bottomActionButtonView.setData(parentOrder.grandTotal, saveTotal: saveAmount)
        bottomActionButtonView.lastCreateDate = parentOrder.lastCreated
        bottomActionButtonView.payHandler = {[weak self] in
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
                            let thankYouViewController = ThankYouViewController()
                            thankYouViewController.fromViewController = strongSelf
                            thankYouViewController.isSecondaryFormat = true
                            thankYouViewController.parentOrder = strongSelf.parentOrder
                            thankYouViewController.handleContinueShopping = {
                                strongSelf.ssn_home()
                            }
                            let navigationController = MmNavigationController(rootViewController: thankYouViewController)
                            navigationController.modalPresentationStyle = .overFullScreen
                            strongSelf.present(navigationController, animated: false, completion: nil)
                            strongSelf.showPopupOrderSuccess(parentOrder: po)
                        }else{
                            let alertController = UIAlertController(title: String.localize("LB_CA_UNPAID_ORDER_FAILED_TO_PAY"), message: String.localize("LB_CA_UNPAID_ORDER_FAILED_TO_PAY_DIALOG"), preferredStyle: UIAlertControllerStyle.alert)
                            var okString: String!
                            //okString = String.localize("LB_CA_CONFIRM")
                            okString = String.localize("LB_CA_UNPAID_ORDER_CHECK_ORDER")
                            let okAction = UIAlertAction(title: okString, style: .default) { UIAlertAction in
                                self?.dismiss(animated: false, completion: nil)
                            }
                            alertController.addAction(okAction)
                            strongSelf.present(alertController, animated: true, completion: nil)
                        }
                    } else {
                        ErrorLogManager.sharedManager.recordNonFatalError(withException: .NullPointer)
                    }
                })
                
                strongSelf.checkoutHandler.processUnpaidPayment(strongSelf.parentOrder, completion: { (success, error) in
                    if !success {
                        if let error = error, error.domain.isEmpty {
                            Alert.alertWithSingleButton(strongSelf, title:  String.localize("LB_CA_UNPAID_ORDER_FAILED_TO_PAY"), message: String.localize("LB_CA_UNPAID_ORDER_FAILED_TO_PAY_DIALOG"))
                        } else {
                            Alert.alertWithSingleButton(strongSelf, title: String.localize("LB_CA_PAYMENT_UNUSUAL_WARNING_MESSAGE"), message: "")
                        }
                    }
                })
                
            }
        }
        view.addSubview(bottomActionButtonView)
    }

    
    // MARK: - Collection View Data Source methods
    
    func numberOfSections(in collectionView: UICollectionView) -> Int {
        return orderSectionData.count
    }
    
    override func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        let dataSource: [SectionUnpaidOrderCellData] = self.orderSectionData
        
        return dataSource[section].datasource.count
    }
    
    override func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        
        let sectionData = self.orderSectionData[indexPath.section]
        let data = sectionData.datasource[indexPath.row]
        
        if data.type == .merchant{
            let cell = collectionView.dequeueReusableCell(withReuseIdentifier: OrderMerchantCell.CellIdentifier, for: indexPath) as! OrderMerchantCell
            if let _data = data.content as? Order{
                cell.unpaidData = _data
                cell.contactHandler = { [weak self] in
                    if let strongSelf = self{
                        if let parentOrder = data.parentOrder, data.merchantId != 0 {
                            strongSelf.view.recordAction(.Tap, sourceRef: "CustomerSupport", sourceType: .Button, targetRef: "\(data.merchantId)", targetType: .Merchant)
                            strongSelf.contactCustomerServiceWithOrderKey(strongSelf, order: parentOrder, merchantId: data.merchantId)
                        }
                    }
                }
                cell.headerTappedHandler = { [weak self] (order) in
                    if let strongSelf = self {
                        DeepLinkManager.sharedManager.pushMerchantById(order.merchantId, fromViewController: strongSelf)
                    } else {
                        ErrorLogManager.sharedManager.recordNonFatalError(withException: .NullPointer)
                    }
                }
            }
            cell.showDisclosureIndicator(false)
            return cell
        } else if data.type == .item {
            let cell = collectionView.dequeueReusableCell(withReuseIdentifier: OrderItemCell.CellIdentifier, for: indexPath) as! OrderItemCell
            if let _data = data.content as? OrderItem{
                cell.unpaidData = _data
            }
            
            cell.hideAfterSaleQuantityLabel(false)
            cell.bottomBorderView.isHidden = true
            
            cell.updateLayout()
            
            return cell

        } else if data.type == .action {
            let cell = collectionView.dequeueReusableCell(withReuseIdentifier: OrderUnpaidActionCell.CellIdentifier, for: indexPath) as! OrderUnpaidActionCell
            return cell
        } else if data.type == .deliveryAddress {
            let cell = collectionView.dequeueReusableCell(withReuseIdentifier: ReceiverAddressCell.CellIdentifier, for: indexPath) as! ReceiverAddressCell
            if let _data = data.content as? Order{
                let address = Address()
                address.recipientName = _data.recipientName
                address.phoneCode = _data.phoneCode
                address.phoneNumber = _data.phoneNumber
                address.address = _data.address
                address.city = _data.city
                address.province = _data.province
                address.country = _data.country
                let addressData = AddressData(address: address)
                cell.data = addressData
            }
            
            return cell
            
        } else if data.type == .invoice {
            let cell = collectionView.dequeueReusableCell(withReuseIdentifier: CheckoutCell.CellIdentifier, for: indexPath) as! CheckoutCell
            cell.rightLabel.text = ""
            cell.backgroundColor = UIColor.white
            cell.leftLabel.text = String.localize("LB_CA_FAPIAO_TITLE")
            if let _data = data.content as? Order{
                cell.rightLabel.text = _data.taxInvoiceName
            }
            cell.setNormalFont()
            cell.rightViewTapHandler = nil
            cell.setStyle(withArrow: false, topSeparator: true, bottomSeparator: true, isFullSeparator: true)
            return cell
            
        } else if data.type == .shipping {
            let cell = collectionView.dequeueReusableCell(withReuseIdentifier: CheckoutCell.CellIdentifier, for: indexPath) as! CheckoutCell
            cell.rightLabel.text = ""
            cell.backgroundColor = UIColor.white
            cell.leftLabel.text = String.localize("LB_SHIPPING_FEE")
            
            var formatPriceText: String = ""
            if let _data = data.content as? Order{
                if _data.shippingTotal > 0 {
                    formatPriceText = _data.shippingTotal.formatPrice() ?? ""
                    cell.setPriceFont()
                }else{
                    formatPriceText = String.localize("LB_CA_FREE_SHIPPING")
                    cell.setNormalFont()
                }
                
                DispatchQueue.main.async {
                    cell.rightLabel.text = formatPriceText
                }
            }
            cell.rightViewTapHandler = nil
            cell.setStyle(withArrow: false, topSeparator: false, bottomSeparator: true, isFullSeparator: true)
            return cell
            
            
        } else if data.type == .merchantCoupon {
            
            let cell = collectionView.dequeueReusableCell(withReuseIdentifier: CheckoutCouponCell.CellIdentifier, for: indexPath) as! CheckoutCouponCell
            cell.leftLabel.text = String.localize("LB_CA_CHECKOUT_MERC_COUPON")
            cell.setStyle(withSeparator: true, isFullSeparator: true)
            cell.backgroundColor = UIColor.white
            
            if let _data = data.content as? Order{
                cell.setUnpaidCoupon(couponName: _data.couponName ?? "", price: _data.couponAmount)
            }
            
            cell.redDotView.isHidden = true
            cell.layoutSubviews()
            return cell
            
        } else if data.type == .subtotal {
            
            let cell = collectionView.dequeueReusableCell(withReuseIdentifier: CheckoutCell.CellIdentifier, for: indexPath) as! CheckoutCell
            cell.rightLabel.text = ""
            cell.backgroundColor = UIColor.white
            cell.leftLabel.text = String.localize("LB_CA_MERCHANT_TOTAL")
            var formatPriceText: String = ""
            if let _data = data.content as? Order{
                if let items = _data.orderItems{
                    var amount: Double = 0
                    for item in items {
                        let itemAmount = item.unitPrice * Double(item.qtyOrdered)
                        amount += itemAmount
                    }
                    amount -= _data.couponAmount
                    formatPriceText = amount.formatPrice() ?? ""
                    DispatchQueue.main.async {
                        cell.rightLabel.text = formatPriceText
                    }
                }
                
            }
            cell.setPriceFont()
            cell.rightViewTapHandler = nil
            cell.setStyle(withArrow: false, topSeparator: false, bottomSeparator: true, isFullSeparator: true)
            return cell
            
        } else if data.type == .comments {
            
            let cell = collectionView.dequeueReusableCell(withReuseIdentifier: CheckoutCommentCell.CellIdentifier, for: indexPath) as! CheckoutCommentCell
            cell.backgroundColor = UIColor.white
            cell.textView.text = String.localize("LB_CA_CS_COMMENT")
            if let _data = data.content as? Order, (_data.comments.count > 0){
                cell.textView.text = _data.comments
                cell.textView.textColor = UIColor.black
            }
            cell.setEnable(false)
            return cell

        } else if data.type == .mmCoupon {
            let cell = collectionView.dequeueReusableCell(withReuseIdentifier: CheckoutCouponCell.CellIdentifier, for: indexPath) as! CheckoutCouponCell
            cell.leftLabel.text = String.localize("LB_CA_CHECKOUT_MM_COUPON")
            cell.setStyle(withSeparator: true, isFullSeparator: true)
            cell.backgroundColor = UIColor.white
            
            if let _data = data.content as? ParentOrder{
                cell.setUnpaidCoupon(couponName: _data.couponName ?? "", price: _data.mmCouponAmount)
            }
            
            cell.redDotView.isHidden = true
            cell.layoutSubviews()
            return cell
        } else if data.type == .alipyIcon {
            let cell = collectionView.dequeueReusableCell(withReuseIdentifier: CheckoutFullPaymentMethodCell.CellIdentifier, for: indexPath) as! CheckoutFullPaymentMethodCell
            return cell
        } else {
            return getDefaultCell(collectionView, cellForItemAt: indexPath)
        }
        
    }
    
    func collectionView(_ collectionView: UICollectionView, viewForSupplementaryElementOfKind kind: String, at indexPath: IndexPath) -> UICollectionReusableView {
        let view = collectionView.dequeueReusableSupplementaryView(ofKind: kind, withReuseIdentifier: DetailUnpaidOrderHeaderID, for: indexPath)
        view.backgroundColor = UIColor.clear
        return view
    }
    
    // MARK: - Collection View Delegate (Flow Layout) methods
    
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, insetForSectionAt section: Int) -> UIEdgeInsets {
        return UIEdgeInsets(top: 10, left: 0, bottom: 0, right: 0);
    }
    
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, referenceSizeForHeaderInSection section: Int) -> CGSize {
        return CGSize.zero
    }
    
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, referenceSizeForfooterInSection section: Int) -> CGSize {
        return CGSize.zero
    }
    
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, sizeForItemAt indexPath: IndexPath) -> CGSize {
        let sectionData = self.orderSectionData[indexPath.section]
        let data = sectionData.datasource[indexPath.row]
        var cellHeight: CGFloat = 0
        
        if data.type == .merchant{
            cellHeight = OrderStatusCellHeight
        } else if data.type == .item {
            cellHeight = OrderItemCell.DefaultHeight
        } else if data.type == .action {
            cellHeight = OrderActionCellHeight
        } else if data.type == .deliveryAddress {
            
            if let _data = data.content as? Order{
                let address = Address()
                address.recipientName = _data.recipientName
                address.phoneCode = _data.phoneCode
                address.phoneNumber = _data.phoneNumber
                address.address = _data.address
                address.city = _data.city
                address.province = _data.province
                address.country = _data.country
                let addressData = AddressData(address: address)
                let text = addressData.getFullAddress()
                return CGSize(width: view.width, height: ReceiverAddressCell.getCellHeight(withAddress: text, cellWidth: view.width))
            }
            cellHeight = 100
            
        } else if data.type == .invoice {
            cellHeight = OrderActionCellHeight
        } else if data.type == .shipping {
            cellHeight = OrderActionCellHeight
        } else if data.type == .merchantCoupon {
            cellHeight = OrderActionCellHeight
        } else if data.type == .subtotal {
            cellHeight = OrderActionCellHeight
        } else if data.type == .comments {
            cellHeight = 120
        } else if data.type == .mmCoupon {
            cellHeight = OrderActionCellHeight
        } else if data.type == .alipyIcon {
            cellHeight = OrderActionCellHeight
        }
        
        if cellHeight > 0 {
            return CGSize(width: view.width, height: cellHeight)
        } else {
            return CGSize.zero
        }
    }
    
    // MARK: - Collection View Delegate methods
    
    func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        let sectionData = self.orderSectionData[indexPath.section]
        let data = sectionData.datasource[indexPath.row]

        if data.type == .item{
            if let orderItem = data.content as? OrderItem{
                self.view.recordAction(.Tap, sourceRef: orderItem.styleCode, sourceType: .Product, targetRef: "PDP", targetType: .View)
                
                let style = Style()
                style.styleCode = orderItem.styleCode
                style.merchantId = data.merchantId
                
                let styleViewController = StyleViewController(style: style)
                self.navigationController?.pushViewController(styleViewController, animated: true)
            }
        }
    }
    


}
