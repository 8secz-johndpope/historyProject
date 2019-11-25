//
//  TSShipmentImageCell.swift
//  merchant-ios
//
//  Created by LongTa on 7/4/16.
//  Copyright © 2016 WWE & CO. All rights reserved.
//

import UIKit

let kMarginTop: CGFloat = 5               //头像的 margin top

class TSShipmentImageCell: TSShipmentCell {
    
    private final let PaddingContent: CGFloat = 15
    private final let CollectionViewPadding: CGFloat = 1
    
    private var headerText:String?
    private var footerText:String?
    private var smallText:String?
    
    override func layoutContents() {
        super.layoutContents()
        
        if let model = self.model{
            collectionView.isScrollEnabled = false
            
            let additionalHeight = TSShipmentImageCell.layoutHeight(model) - self.frame.size.height
            Log.debug(additionalHeight)
            var frame = self.viewContent.frame
            frame.size.height += additionalHeight
            self.viewContent.frame = frame
            
            var collectionViewFrame = self.collectionView.frame
            collectionViewFrame.origin.y = TSShipmentCell.CollectionViewStartY
            self.collectionView.frame = collectionViewFrame
            
            var backgroundImageFrame = self.backgroundImage.frame
            backgroundImageFrame.origin.y = frame.origin.y - CollectionViewPadding
            backgroundImageFrame.size.height = frame.size.height + 2*CollectionViewPadding - TSShipmentCell.MarginBottom
            self.backgroundImage.frame = backgroundImageFrame
        }
    }
    
    
    override class func layoutHeight(_ model: ChatModel) -> CGFloat {
        super.layoutHeight(model)
        
        if let shipmentModel = model.shipmentModel{
            let maximumWidth = TSShipmentCell.getTextWidth()
            
            let headerText = self.getHeaderTextWithShipment(shipmentModel, model: model)
            let headerTextHeight = headerText.stringHeightWithMaxWidth(maximumWidth, font: ShipmentTextReusableView.ContentFont)
            let headerHeight = CGFloat(headerTextHeight) + kMarginTop
            
            let footerText = self.getFooterTextWithShipment(shipmentModel, model: model)
            let footerTextHeight = footerText.stringHeightWithMaxWidth(maximumWidth, font: (TSShipmentImageCell.isShouldUseSmallFont(model) == true ? ShipmentTextReusableView.ContentSmallFont:ShipmentTextReusableView.ContentFont))
            
            var footerHeight = CGFloat(footerTextHeight) + kMarginTop
            if shipmentModel.orderType == .OrderCancel {
                footerHeight += ShipmentTextReusableView.SmallTextHeight
            }
            
            var contentHeight = CGFloat(0)
            
            if model.dataType == .OrderCancelRefundNotification || model.dataType == .OrderReturnRefundNotification {
                contentHeight = CGFloat(20)
            } else {
                if shipmentModel.orderType == .OrderReturn {
                    if TSShipmentImageCell.shouldShowReturnImage(model) {
                        contentHeight = OrderItemCell.DefaultHeight //1 row
                    }
                } else{
                    contentHeight = CGFloat(OrderItemCell.DefaultHeight * CGFloat(TSShipmentImageCell.numberOfOrderShipmentItems(model)))
                }
            }
            
            let paddingBottom = TSShipmentCell.MarginBottom * 2
            return CGFloat(headerHeight + footerHeight + contentHeight + TSShipmentCell.CollectionViewStartY + paddingBottom)
        }
        else{
            return 262
        }
    }
    
    class func shouldShowReturnImage(_ model: ChatModel?) -> Bool{
        if let shipmentModel = model?.shipmentModel{
            if shipmentModel.orderType == .OrderReturn{
                if let orderReturn = model?.shipmentModel?.orderReturn{
                    if (orderReturn.image1.length > 0 || orderReturn.image2.length > 0 || orderReturn.image3.length > 0){
                        return true
                    }
                }
            }
        }
        return false
    }
    
    class func numberOfOrderShipmentItems(_ model: ChatModel?) -> Int{
        if let orderItems = model?.shipmentModel?.shipment?.order?.orderItems{
            return orderItems.count
        }
        return 0
    }
    
    override func fillContentWithData(_ shipmentModel:ShipmentModel, model: ChatModel, inventoryLocation: InventoryLocation? = nil) {
        super.fillContentWithData(shipmentModel, model: model, inventoryLocation: inventoryLocation)
        
        if let shipmentModel = model.shipmentModel{
            headerText = TSShipmentImageCell.getHeaderTextWithShipment(shipmentModel, model: model)
            footerText = TSShipmentImageCell.getFooterTextWithShipment(shipmentModel, model: model)
            smallText = TSShipmentImageCell.getSmallTextWithShipment(shipmentModel, model: model)
            
            arrowImage.isHidden = (shipmentModel.orderType == .OrderCancel ||
                                model.dataType == .OrderReturnRefundNotification ||
                                model.dataType == .OrderCancelRefundNotification)
            
            collectionView.isHidden = false
            collectionView.reloadData()
        }
    }
    
    class func isShouldUsingShipmentImageCell(_ model: ChatModel) -> Bool{
        switch model.dataType {
        case .OrderCollectionNotification,
             .OrderShipmentNotification,
             .OrderCancelNotification,
             .OrderCancelFailNotification,
             .OrderCancelRefundNotification,
             .OrderReturnRefundNotification,
             .ReturnItemRejectedNotification,
             .ReturnRequestRejectedNotification,
             .ReturnDisputeRejectedNotification,
             .ReturnDisputeApprovedNotification,
             .ReturnRequestDisputeRejectedNotification,
             .ReturnRequestDisputeApprovedNotification:
            return true
        default:
            return false
        }
    }
    
    class func isShouldUseSmallFont(_ model: ChatModel?) -> Bool{
        if let model = model{
            switch model.dataType {
            case .ReturnRequestDisputeApprovedNotification, .ReturnRequestDisputeRejectedNotification, .ReturnDisputeApprovedNotification, .ReturnDisputeRejectedNotification:
                return true
            default:
                return false
            }
        }
        return false
    }
    
    class func getHeaderTextWithShipment(_ shipmentModel:ShipmentModel, model: ChatModel) -> String{
        var text = ""
        switch model.dataType {
        case .OrderCollectionNotification:
            text = (String.localize("LB_CA_YOUR_ORDER_1") + " " + String.localize("LB_CA_YOUR_ORDER_3"))
            break
        case .OrderShipmentNotification:
            text = (String.localize("LB_CA_YOUR_ORDER_1") + " " + String.localize("LB_CA_YOUR_ORDER_2"))
            break
        case .OrderCancelNotification:
            text = (String.localize("LB_CA_YOUR_ORDER_1") + " " + String.localize("LB_CA_YOUR_ORDER_7"))
            break
        case .OrderCancelFailNotification:
            text = "\(String.localize("LB_CA_YOUR_ORDER_1"))\(String.localize("LB_CA_YOUR_ORDER_12"))"
            break
        case .OrderCancelRefundNotification,
             .OrderReturnRefundNotification:
            let orderKey = model.dataBody.components(separatedBy: "|")
            text = String.localize("MSG_NTF_PUSH_REFUND_SUCCESS").replacingOccurrences(of: "{OrderKey}", with: orderKey.count > 0 ? orderKey[0] : "")
            break
        case .ReturnItemRejectedNotification,
             .ReturnRequestRejectedNotification:
            text = String.localize("LB_CA_RETURN_REJECTED_TEXT")
            break
        case .ReturnDisputeRejectedNotification:
            text = String.localize("LB_MM_DISPUTE_RESPONSE_DELINED")
            break
        case .ReturnDisputeApprovedNotification:
            text = String.localize("LB_MM_DISPUTE_RESPONSE")
            break
        case .ReturnRequestDisputeRejectedNotification:
            text = String.localize("LB_MM_DISPUTE_RESPONSE_DELINED")
            break
        case .ReturnRequestDisputeApprovedNotification:
            text = String.localize("LB_MM_DISPUTE_RESPONSE")
            break
        default:
            break
        }
        Log.debug(text)
        return text
    }
    
    class func getSmallTextWithShipment(_ shipmentModel: ShipmentModel, model: ChatModel) -> String? {
        var text: String?
        switch model.dataType {
        case .OrderCancelNotification, .OrderCancelFailNotification:
            text = String.localize("LB_RMA_NO") + " " + (shipmentModel.orderCancel?.orderCancelKey ?? "")
        case .OrderCancelRefundNotification, .OrderReturnRefundNotification:
            let amount = model.dataBody.components(separatedBy: "|")
            text = String.localize("LB_REFUND_AMOUNT") + " : " + (amount.count > 1 ? amount[1] : "")
            break
        default:
            break
        }
        return text
    }
    
    class func getFooterTextWithShipment(_ shipmentModel: ShipmentModel, model: ChatModel) -> String{
        var text = ""
        switch model.dataType {
        case .OrderCollectionNotification:
            if let inventoryLocation = shipmentModel.inventoryLocation {
                let merchantName = shipmentModel.shipment?.order?.merchantName ?? ""
                text = String.localize("LB_COLLECTION_ADDRESS") + ": " + "\(inventoryLocation.formatAddress())\n" + String.localize("LB_CS_CONTACT") + ": " + "\(merchantName)(\(inventoryLocation.geoCountryName))\n" + String.localize("LB_CA_POSTAL_CODE") + ": " + "\(inventoryLocation.postalCode)"
            }
            else {
                text = "\(shipmentModel.getShipmentAddress())\n\(shipmentModel.getPostalCode())"
            }
            
        case .OrderShipmentNotification:
            text = "\(shipmentModel.getCourierName())\n\(shipmentModel.getShipmentNo())"
            
        case .ReturnItemRejectedNotification,
             .ReturnRequestRejectedNotification:
            text = shipmentModel.getRMANO()
            
        case .ReturnDisputeRejectedNotification:
            text = shipmentModel.getRMANO()
            
        case .ReturnDisputeApprovedNotification:
            text = shipmentModel.getRMANO()
            
        case .ReturnRequestDisputeRejectedNotification:
            text = shipmentModel.getRMANO()
            
        case .ReturnRequestDisputeApprovedNotification:
            text = shipmentModel.getRMANO()
            
        default:
            break
        }
        Log.debug(text)
        return text
    }
    
    //MARK: CollectionView
    override func numberOfSections(in collectionView: UICollectionView) -> Int{
        return 1
    }
    
    override func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        if self.model?.shipmentModel?.orderType == .OrderShipment {
            return TSShipmentImageCell.numberOfOrderShipmentItems(self.model)
        } else if self.model?.shipmentModel?.orderType == .OrderCancel {
            return 0
        } else {
            return 1
        }
    }
    
    func collectionView(_ collectionView: UICollectionView, viewForSupplementaryElementOfKind kind: String, at indexPath: IndexPath) -> UICollectionReusableView {
        
        if kind == UICollectionElementKindSectionHeader {
            let view = collectionView.dequeueReusableSupplementaryView(ofKind: kind, withReuseIdentifier: ShipmentTextReusableView.HeaderIdentifier, for: indexPath) as! ShipmentTextReusableView
            view.setText(headerText, isUsingSmallFont: false)
            return view
        }
        else /*if kind == UICollectionElementKindSectionFooter*/ {//footer
            let view = collectionView.dequeueReusableSupplementaryView(ofKind: kind, withReuseIdentifier: ShipmentTextReusableView.FooterIdentifier, for: indexPath) as! ShipmentTextReusableView
            view.setText(footerText, isUsingSmallFont: TSShipmentImageCell.isShouldUseSmallFont(self.model))
            view.setSmallText(smallText);
            return view
        }
    }
    override func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        if self.model?.shipmentModel?.orderType == .OrderShipment{
            return self.orderItemCell(indexPath)
        }
        else{
            return self.imageCell(indexPath)
        }
    }
    
    func orderItemCell(_ indexPath: IndexPath) -> OrderItemCell{
        let cell = collectionView.dequeueReusableCell(withReuseIdentifier: OrderItemCell.CellIdentifier, for: indexPath) as! OrderItemCell
        
        if let order = model?.shipmentModel?.shipment?.order{
            if let orderItems = order.orderItems{
                //set data
                let data = OrderSectionData(sectionHeader: [], reuseIdentifier: OrderItemCell.CellIdentifier, dataSource: orderItems)
                data.order = order
                cell.orderDisplayStatus = data.orderDisplayStatus
                let orderItem = orderItems[indexPath.row]
                cell.data = orderItem
                //set text color
                cell.productNameLabel.textColor = UIColor.secondary4()
                cell.productColorLabel.textColor = UIColor.secondary4()
                cell.productSizeLabel.textColor = UIColor.secondary4()
                cell.productPriceLabel.textColor = UIColor.secondary4()
                cell.productQtyLabel.textColor = UIColor.secondary4()
            }
        }

        cell.bottomBorderView.isHidden = true
        cell.updateLayout()
        return cell
    }
    
    func imageCell(_ indexPath: IndexPath) -> CollectionViewImageContainerCell{
        let cell = collectionView.dequeueReusableCell(withReuseIdentifier: CollectionViewImageContainerCell.CellIdentifier, for: indexPath) as! CollectionViewImageContainerCell
        
        if let orderReturn = self.model?.shipmentModel?.orderReturn{
            cell.listImagesURL = [orderReturn.image1, orderReturn.image2, orderReturn.image3]
            cell.collectionView.reloadData()
        }

        return cell
    }
    
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, referenceSizeForHeaderInSection section: Int) -> CGSize {
        let textView = ShipmentTextReusableView(frame: collectionView.frame)
        textView.setText(headerText, isUsingSmallFont: false)
        return textView.viewSize()
    }
    
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, referenceSizeForFooterInSection section: Int) -> CGSize {
        let textView = ShipmentTextReusableView(frame: collectionView.frame)
        textView.setText(footerText, isUsingSmallFont: TSShipmentImageCell.isShouldUseSmallFont(self.model))
        textView.setSmallText(smallText);
        return textView.viewSize()
    }
    
    override func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, sizeForItemAt indexPath: IndexPath) -> CGSize {
        if let shipmentModel = self.model?.shipmentModel{
            if shipmentModel.orderType == .OrderReturn{
                if TSShipmentImageCell.shouldShowReturnImage(model) == false{
                    return CGSize.zero
                }
            }
        }
        return CGSize(width: self.frame.size.width - (2 * PaddingContent), height: OrderItemCell.DefaultHeight)
    }
}
