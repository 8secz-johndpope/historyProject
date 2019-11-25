//
//  TSShareOrderCell.swift
//  merchant-ios
//
//  Created by Kam on 5/5/2016.
//  Copyright © 2016 WWE & CO. All rights reserved.
//

import UIKit
import ObjectMapper

class TSShareOrderCell: TSChatBaseCell {
    
    private static let ItemCellHeight = CGFloat(81)
    private static let FooterCellHeight = CGFloat(68)
    private static let HeaderCellHeight = CGFloat(39)
    
    private final let OrderCellId = "OrderCellId"
    private final let OrderHeaderId = "OrderHeaderId"
    private final let OrderFooterId = "OrderFooterId"

    @IBOutlet weak var collectionView: UICollectionView!
    @IBOutlet weak var backgroundImage: UIImageView!
    @IBOutlet weak var viewContent: UIView!
    
    override func awakeFromNib() {
        super.awakeFromNib()
        // Initialization code
        
        self.collectionView.register(TSShareOrderCollectionViewCell.NibObject(), forCellWithReuseIdentifier: OrderCellId)
        self.collectionView.register(TSShareOrderHeaderView.self, forSupplementaryViewOfKind: UICollectionElementKindSectionHeader, withReuseIdentifier: OrderHeaderId)
        self.collectionView.register(TSShareOrderFooterView.self, forSupplementaryViewOfKind: UICollectionElementKindSectionFooter, withReuseIdentifier: OrderFooterId)
        
        let tap = TapGestureRecognizer()
        viewContent.addGestureRecognizer(tap)
        tap.tapHandler = { [weak self] _ in
            if let strongSelf = self {
                guard let delegate = strongSelf.delegate, let cellDidTaped = delegate.cellDidTaped else {
                    ErrorLogManager.sharedManager.recordNonFatalError(withException: .NullPointer)
                    return
                }
                cellDidTaped(strongSelf)
            }
        }
    }

    override func setSelected(_ selected: Bool, animated: Bool) {
        super.setSelected(selected, animated: animated)

        // Configure the view for the selected state
    }
    
    override func setCellContent(_ model: ChatModel) {
        super.setCellContent(model)
        
        if model.orderModel?.orderShare == nil {
            getOrderWithModel(model)
        }
        
        setContentWithModel(model)
    }
    
    func setContentWithModel(_ model: ChatModel) {
        var rect = viewContent.frame
        rect.size.height = TSShareOrderCell.layoutHeight(model) > 0 ? TSShareOrderCell.layoutHeight(model) - kChatAvatarMarginTop - kChatBubblePaddingBottom : 0
        viewContent.frame = rect
        
        reloadView()
        self.setNeedsLayout()
    }
    
    class func layoutHeight(_ model: ChatModel) -> CGFloat {
        var height = kChatAvatarMarginTop + kChatBubblePaddingBottom + HeaderCellHeight + FooterCellHeight + ItemCellHeight
        
        let calHeight = { (orderShare: OrderShare) -> CGFloat in
            var height = CGFloat(0)
            
            if let items = orderShare.items {
                for orderItem in items {
                    // no color, no size or no quantity shipped
                    if orderItem.colorId == 1 || orderItem.sizeId == 1 || orderItem.quantityShipped == nil {
                        height += TSShareOrderCell.ItemCellHeight
                    }
                    else {
                        // plus 18 for quantity shipped line added
                        height += TSShareOrderCell.ItemCellHeight + 18
                    }
                }
            }
            return kChatAvatarMarginTop + kChatBubblePaddingBottom + HeaderCellHeight + FooterCellHeight + height
        }
        
        if let orderShare = model.orderModel?.orderShare {
            height = calHeight(orderShare)
        }
        
        return height
    }
    
    override func layoutContents() {
        super.layoutContents()

        guard let model = self.model else {
            return
        }
        
        if model.fromMe {
            self.viewContent.left = ScreenWidth - kChatAvatarMarginLeft - kChatAvatarWidth - kChatBubbleMaginLeft - self.viewContent.width
            backgroundImage.image = UIImage(named: "shareUser_pink")
        } else {
            self.viewContent.left = kChatBubbleLeft
            backgroundImage.image = UIImage(named: "shareUser_wht")
        }
        
        self.viewContent.top = self.avatarImageView.top
    }

    func reloadView() {
        collectionView.reloadData()
    }
    
    func getOrderWithModel(_ model: ChatModel) {
        if let orderModel = model.orderModel, let orderKey = orderModel.orderNumber {
            OrderService.viewOrder(orderKey) { [weak self] (response) in
                if response.result.isSuccess && response.response?.statusCode == 200 {
                    if let order = Mapper<Order>().map(JSONObject: response.result.value) {
                        
                        orderModel.order = order
                        let orderShare = OrderShare()
                        var items = [OrderShareItem]()
                        
                        orderShare.orderNumber = orderKey
                        orderShare.price = order.grandTotal
                        orderShare.orderReferenceNumber = model.orderReferenceNumber ?? ""
                        orderShare.orderType = model.orderType
                        
                        var totalPrice = Double(0)
                        
                        if let shipmentKey = model.shipmentKey {
                            if let orderShipments = order.orderShipments {
                                for orderShipment in orderShipments {
                                    if orderShipment.orderShipmentKey == shipmentKey, let orderShipmentItems = orderShipment.orderShipmentItems {
                                        for shipmentItem in orderShipmentItems {
                                            let item = OrderShareItem()
                                            
                                            if shipmentItem.qtyShipped > 0 {
                                                item.quantity = shipmentItem.qtyShipped
                                            }
                                            
                                            item.quantityShipped = shipmentItem.qtyShipped
                                            
                                            if let orderItems = order.orderItems {
                                                for orderItem in orderItems {
                                                    if orderItem.skuId == shipmentItem.skuId {
                                                        if shipmentItem.qtyShipped == 0 {
                                                            item.quantity = orderItem.qtyToShip
                                                        }

                                                        item.productImage = orderItem.productImage
                                                        item.skuName = orderItem.skuName
                                                        item.price = orderItem.unitPrice
                                                        item.colorName = orderItem.colorName
                                                        item.sizeName = orderItem.sizeName
                                                        item.colorId = orderItem.colorId
                                                        item.sizeId = orderItem.sizeId

                                                        break
                                                    }
                                                }
                                            }

                                            totalPrice += item.price * Double(item.quantity)

                                            items.append(item)
                                        }
                                        
                                        orderShare.items = items
                                        if order.orderStatus == .partialShipped || order.orderStatus == .shipped {
                                            orderShare.shouldHideReferenceNumber = true
                                        }
                                        orderShare.price = totalPrice

                                        break
                                    }
                                }
                            }
                        }
                        else if let orderItems = order.orderItems, !orderItems.isEmpty {
                            for orderItem in orderItems {
                                let item = OrderShareItem()
                                var isAppend = false
                                
                                if orderModel.orderType == OrderShareType.OrderReturn {
                                    if let orderReturns = order.orderReturns, !orderReturns.isEmpty {
                                        for orderReturn in orderReturns {
                                            if let orderReturnItems = orderReturn.orderReturnItems, !orderReturnItems.isEmpty {
                                                for orderReturnItem in orderReturnItems {
                                                    if orderReturnItem.skuId == orderItem.skuId {
                                                        item.quantity += orderReturnItem.qtyReturned
                                                        isAppend = true
                                                    }
                                                }
                                            }
                                        }
                                    }
                                } else if orderModel.orderType == OrderShareType.OrderShipment {
                                    isAppend = true
                                    item.quantity = orderItem.qtyOrdered
                                    item.quantityShipped = orderItem.qtyShipped
                                    if order.orderStatus == .partialShipped || order.orderStatus == .shipped {
                                        orderShare.shouldHideReferenceNumber = true
                                    }
                                } else {
                                    isAppend = true
                                    item.quantity = orderItem.qtyOrdered
                                }
                                item.productImage = orderItem.productImage
                                item.skuName = orderItem.skuName
                                item.price = orderItem.unitPrice
                                item.colorName = orderItem.colorName
                                item.sizeName = orderItem.sizeName
                                item.colorId = orderItem.colorId
                                item.sizeId = orderItem.sizeId
                                
                                if isAppend {
                                    items.append(item)
                                    if orderModel.orderType == OrderShareType.OrderReturn {
                                        totalPrice += orderItem.unitPrice
                                    }
                                }
                                
                            }
                            
                            orderShare.items = items
                            
                            if orderModel.orderType == OrderShareType.OrderReturn {
                                orderShare.price = totalPrice
                            }
                        }

                        model.orderModel?.orderShare = orderShare
                        
                        if let strongSelf = self {
                            strongSelf.setContentWithModel(model)
                            NotificationCenter.default.post(name: NSNotification.Name(rawValue: "cellDidLoad"), object: nil)
                        }
                    }
                }
            }
        } else {
            ErrorLogManager.sharedManager.recordNonFatalError(withException: .NullPointer)
        }
    }
}

//MARK: CollectionView
extension TSShareOrderCell: UICollectionViewDataSource {
    
    func numberOfSections(in collectionView: UICollectionView) -> Int {
        return 1
    }

    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        
        if let orderItems = self.model?.orderModel?.orderShare?.items {
            return orderItems.count
        }
        
        return 0
    }
    
    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        
        let cell = collectionView.dequeueReusableCell(withReuseIdentifier: OrderCellId, for: indexPath) as! TSShareOrderCollectionViewCell
        
        if let orderItems = self.model?.orderModel?.orderShare?.items, !orderItems.isEmpty {
            cell.orderItem = orderItems[indexPath.row]
        }
        else {
            cell.productImage.image = UIImage(named: "mm_white")
            cell.proudctNameLabel.text = ""
            
            cell.priceLabel.text = ""
            
            cell.colorLabel.text = String.localize("LB_CA_PI_COLOR") + " : "
            cell.sizeLabel.text = String.localize("LB_CA_PI_SIZE") + " : "
            cell.shippedLabel.text = ""
        }
        
        return cell
    }
}

extension TSShareOrderCell: UICollectionViewDelegateFlowLayout {
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, minimumLineSpacingForSectionAt section: Int) -> CGFloat {
        return 0
    }
    
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, minimumInteritemSpacingForSectionAt section: Int) -> CGFloat {
        return 0
    }
    
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, referenceSizeForHeaderInSection section: Int) -> CGSize {
        return CGSize(width: collectionView.frame.width, height: TSShareOrderCell.HeaderCellHeight)
    }
    
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, referenceSizeForFooterInSection section: Int) -> CGSize {
        return CGSize(width: collectionView.frame.width, height: TSShareOrderCell.FooterCellHeight)
    }

    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, sizeForItemAt indexPath: IndexPath) -> CGSize {
        
        if let orderItem = self.model?.orderModel?.orderShare?.items?.get(indexPath.row) {
            // no color, no size or no quantity shipped
            if orderItem.colorId == 1 || orderItem.sizeId == 1 || orderItem.quantityShipped == nil {
                return CGSize(width: collectionView.frame.width, height: TSShareOrderCell.ItemCellHeight)
            }
        }

        // plus 18 for quantity shipped line added
        return CGSize(width: collectionView.frame.width, height: TSShareOrderCell.ItemCellHeight + 18)
    }
    
    func collectionView(_ collectionView: UICollectionView, viewForSupplementaryElementOfKind kind: String, at indexPath: IndexPath) -> UICollectionReusableView {
        
        if kind == UICollectionElementKindSectionHeader {
            
            let view = collectionView.dequeueReusableSupplementaryView(ofKind: kind, withReuseIdentifier: OrderHeaderId, for: indexPath) as! TSShareOrderHeaderView
            
            if let orderShare = self.model?.orderModel?.orderShare {
                view.orderNumberLabel.text = orderShare.orderNumber
                if orderShare.orderType == .OrderReturn {
                    view.shipmentNumberLabel.text = orderShare.orderReferenceNumber
                    
                    view.shipmentNumberLabel.isHidden = false
                    view.lblShipment.isHidden = false
                    
                    view.lblShipment.text = String.localize("LB_CA_OMS_RETURN_NO")
                }
                else if orderShare.orderType == .OrderShipment {
                    if orderShare.shouldHideReferenceNumber {
                        view.shipmentNumberLabel.isHidden = true
                        view.lblShipment.isHidden = true
                    }
                    else if orderShare.orderReferenceNumber != "" {
                        view.shipmentNumberLabel.text = orderShare.orderReferenceNumber
                        
                        view.shipmentNumberLabel.isHidden = false
                        view.lblShipment.isHidden = false
                        
                        view.lblShipment.text = String.localize("LB_CA_OMS_SHIPMENT_NO")
                    }
                    else {
                        view.shipmentNumberLabel.isHidden = true
                        view.lblShipment.isHidden = true
                    }
                }
                else {
                    view.shipmentNumberLabel.isHidden = true
                    view.lblShipment.isHidden = true
                }
            }
            else {
                view.orderNumberLabel.text = ""
                view.shipmentNumberLabel.text = ""
                
                view.shipmentNumberLabel.isHidden = true
                view.lblShipment.isHidden = true
            }
            view.layoutSubviews()
            
            return view
        }
        else {
            let view = collectionView.dequeueReusableSupplementaryView(ofKind: kind, withReuseIdentifier: OrderFooterId, for: indexPath) as! TSShareOrderFooterView

            var quantity = 0
            if let orderItems = self.model?.orderModel?.orderShare?.items {
                for orderItem in orderItems {
                    quantity += orderItem.quantity
                }
            }
            
            if let orderModel = self.model?.orderModel, orderModel.orderType == .OrderReturn {
                view.summaryLabel.text = String.localize("LB_CA_OMS_TOTAL_PRODUCT_RMA").replacingOccurrences(of: "{0}", with: "\(quantity)")
            }
            else {
                var price = Double(0)
                if let orderShare = self.model?.orderModel?.orderShare {
                    price = orderShare.price
                }
                
                let quantityText = String.localize("LB_CA_OMS_TOTAL_PRODUCT").replacingOccurrences(of: "{0}", with: "\(quantity)")
                
                view.summaryLabel.text = quantityText + " " + String.localize("LB_CA_OMS_SUBTOTAL") + " " + price.formatPrice()!
            }
            
            view.lblTimestamp.text = self.model?.timeDate.detailChatTimeString
            return view
        }
    }
}
