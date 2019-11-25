//
//  TSShareShipmentShippedCell.swift
//  merchant-ios
//
//  Created by LongTa on 7/1/16.
//  Copyright © 2016 WWE & CO. All rights reserved.
//

import UIKit
import ObjectMapper
class TSShipmentCell: TSChatBaseCell,UICollectionViewDelegate,UICollectionViewDelegateFlowLayout,UICollectionViewDataSource {

    @IBOutlet weak var collectionView: UICollectionView!
    @IBOutlet weak var backgroundImage: UIImageView!
    @IBOutlet weak var viewContent: UIView!
    @IBOutlet weak var labelShipmentStatus: UILabel!
    @IBOutlet weak var arrowImage: UIImageView!
    
    private var dataSource = [CollectionViewSectionData]()
    static let MarginLeftRight: CGFloat = 20
    static let MarginBottom: CGFloat = 10
    static let ShipmentImageCellHeight: CGFloat = 115
    static let ShipmentTextCellHeight: CGFloat = 20
    static let CollectionViewStartY: CGFloat = 65
    static let ConerRadiusCollectionView: CGFloat = 8
    var conv: Conv?
    
    static let descCell = DescCell()
    override func awakeFromNib() {
        super.awakeFromNib()
        // Initialization code
       
        collectionView.register(DescCell.self, forCellWithReuseIdentifier: DescCell.CellIdentifier)
        collectionView.register(OrderItemCell.self, forCellWithReuseIdentifier: OrderItemCell.CellIdentifier)
        collectionView.register(ShipmentTextReusableView.self, forSupplementaryViewOfKind: UICollectionElementKindSectionHeader, withReuseIdentifier: ShipmentTextReusableView.HeaderIdentifier)
        collectionView.register(ShipmentTextReusableView.self, forSupplementaryViewOfKind: UICollectionElementKindSectionFooter, withReuseIdentifier: ShipmentTextReusableView.FooterIdentifier)
        collectionView.register(CollectionViewImageContainerCell.NibObject(), forCellWithReuseIdentifier: CollectionViewImageContainerCell.CellIdentifier)
        
        let tap = TapGestureRecognizer()
        viewContent.addGestureRecognizer(tap)
        tap.tapHandler = { [weak self] _ in
            if let strongSelf = self {
                guard let delegate = strongSelf.delegate, let cellDidTaped = delegate.cellDidTaped else {
                    return
                }
                cellDidTaped(strongSelf)
            }
        }
        collectionView.backgroundColor = UIColor.white
        collectionView.isScrollEnabled = false
    }
    
    override func setCellContent(_ model: ChatModel) {
        super.setCellContent(model)
        
        if let shipmentModel = model.shipmentModel {
            
            if model.orderType == .OrderReturn || model.dataType == .OrderCollectionNotification || model.dataType == .OrderCollectionCancelNotification || model.dataType == .OrderCollectedNotification {
                
                var merchantId = -1
                var locationExternalCode = ""
                
                if model.orderType == .OrderReturn, let orderReturn = shipmentModel.orderReturn {
                    merchantId = orderReturn.merchantId ?? -1
                    locationExternalCode = orderReturn.locationExternalCode
                }
                else {
                    merchantId = shipmentModel.shipment?.order?.merchantId ?? -1
                    locationExternalCode = shipmentModel.shipment?.locationExternalCode ?? ""
                }
                
                if shipmentModel.inventoryLocation != nil {
                    self.fillContentWithData(shipmentModel, model: model, inventoryLocation: shipmentModel.inventoryLocation)
                }
                else {
                    if merchantId != -1 {
                        InventoryService.viewLocation(merchantId: merchantId, locationExternalCode: locationExternalCode, completion: { [weak self] (response) in
                            if let strongSelf = self {
                                var isOK = false
                                if response.result.isSuccess {
                                    if response.response?.statusCode == 200 {
                                        let inventoryLocation = Mapper<InventoryLocation>().map(JSONObject: response.result.value)
                                        model.shipmentModel?.inventoryLocation = inventoryLocation
                                        strongSelf.fillContentWithData(shipmentModel, model: model, inventoryLocation: inventoryLocation)
                                        isOK = true
                                        strongSelf.setNeedsLayout()
                                        NotificationCenter.default.post(name: Constants.Notification.reloadChatScreen, object: nil)
                                        return
                                    }
                                }
                                
                                if !isOK {
                                    strongSelf.fillContentWithData(shipmentModel, model: model)
                                    strongSelf.setNeedsLayout()
                                }
                            } else {
                                ErrorLogManager.sharedManager.recordNonFatalError(withException: .NullPointer)
                            }
                        })
                    }
                    else {
                        fillContentWithData(shipmentModel, model: model)
                    }
                }
            } else {
                fillContentWithData(shipmentModel, model: model)
            }
        } else if let orderShipmentKey = model.orderShipmentKey {
            //Using dumy data first
            let shipment = Shipment()
            shipment.orderShipmentKey = orderShipmentKey

            let shipmentModel = ShipmentModel()
            shipmentModel.shipment = shipment
            shipmentModel.orderType = model.orderType
            model.shipmentModel = shipmentModel
            self.fillContentWithData(shipmentModel, model: model)
            
            if model.orderType == .OrderReturn{
                if let conv = self.conv {
                    if conv.IAmCustomer() {
                        self.getReturnDetail(orderShipmentKey, model: model)
                    }
                    else {
                        if let merchantId = conv.merchantId {
                            self.getReturnDetail(orderShipmentKey, model: model, merchantId: merchantId)
                        }
                    }
                }
            } else if model.dataType == .OrderCancelNotification || model.dataType == .OrderCancelFailNotification {
                self.getOrderCancelled(orderShipmentKey, model: model)
            } else if model.dataType == .OrderDetailUpdatedNotification {
                self.getOrder(orderShipmentKey, model: model)
            } else {
                if model.dataType != .OrderCancelRefundNotification && model.dataType != .OrderReturnRefundNotification {
                    if let conv = self.conv {
                        if conv.IAmCustomer() {
                            self.getShipmentDetail(orderShipmentKey, model: model)
                        }
                        else {
                            if let merchantId = conv.merchantId {
                                self.getShipmentDetail(orderShipmentKey, model: model, merchantId: merchantId)
                            }
                        }
                    }
                }
            }
        }
        self.setNeedsLayout()
    }
    
    func getShipmentDetail(_ key: String, model: ChatModel, merchantId: Int? = nil) {
        ShipmentService.view(orderShipmentKey: key, merchantId: merchantId, completion: { [weak self] (response)  in
            if let strongSelf = self, response.response?.statusCode == 200 {
                
                if let shipment :  Shipment = Mapper<Shipment>().map(JSONObject: response.result.value){
                    let shipmentModel = ShipmentModel()
                    shipmentModel.shipment = shipment
                    shipmentModel.orderType = model.orderType
                    model.shipmentModel = shipmentModel
                    
                    InventoryService.viewLocation(merchantId: shipment.order?.merchantId ?? 0, locationExternalCode: shipment.locationExternalCode, completion: { (response) in
                        var isOK = false
                        if response.result.isSuccess {
                            if response.response?.statusCode == 200 {
                                let inventoryLocation = Mapper<InventoryLocation>().map(JSONObject: response.result.value)
                                model.shipmentModel?.inventoryLocation = inventoryLocation
                                strongSelf.fillContentWithData(shipmentModel, model: model, inventoryLocation: inventoryLocation)
                                isOK = true
                                strongSelf.setNeedsLayout()
                                NotificationCenter.default.post(name: Constants.Notification.reloadChatScreen, object: nil)
                                return
                            }
                        }
                        if !isOK {
                            strongSelf.fillContentWithData(shipmentModel, model: model)
                            strongSelf.setNeedsLayout()
                            NotificationCenter.default.post(name: Constants.Notification.reloadChatScreen, object: nil)
                            return
                        }
                    })
                } else {
                    ErrorLogManager.sharedManager.recordNonFatalError(withException: .FailToParseAPIResponse)
                    
                }
            } else {
                ErrorLogManager.sharedManager.recordNonFatalError(withException: .NullPointer)
                
            }
        })
    }
    
    func getReturnDetail(_ key: String, model: ChatModel, merchantId: Int? = nil) {
        OrderService.viewOrderReturn(orderReturnKey: key, merchantId: merchantId, completion: { [weak self] (response) in
            if let strongSelf = self {
                if response.result.isSuccess {
                    if response.response?.statusCode == 200 {
                        
                        
                        var orderItemsFiltered : [OrderItem] = []
                        if let orderReturn = Mapper<OrderReturn>().map(JSONObject: response.result.value) {
                            let shipmentModel = ShipmentModel()
                            if let order = orderReturn.order {
                                if let orderItems  = order.orderItems, let orderReturnItems = orderReturn.orderReturnItems {
                                    for orderReturnItem in orderReturnItems {
                                        if let orderItem = orderItems.filter({$0.skuId == orderReturnItem.skuId}).first {
                                            orderItemsFiltered.append(orderItem)
                                        }
                                    }
                                }
                                order.orderItems = orderItemsFiltered
                            }
                            shipmentModel.orderReturn = orderReturn
                            shipmentModel.orderType = model.orderType
                            model.shipmentModel = shipmentModel
                            
                            _ = InventoryService.viewLocation(merchantId: orderReturn.merchantId ?? 0, locationExternalCode: orderReturn.locationExternalCode, completion: { (response) in
                                var isOK = false
                                if response.result.isSuccess {
                                    if response.response?.statusCode == 200 {
                                        let inventoryLocation = Mapper<InventoryLocation>().map(JSONObject: response.result.value)
                                        model.shipmentModel?.inventoryLocation = inventoryLocation
                                        strongSelf.fillContentWithData(shipmentModel, model: model, inventoryLocation: inventoryLocation)
                                        NotificationCenter.default.post(name: Constants.Notification.reloadChatScreen, object: nil)
                                        isOK = true
                                    }
                                }
                                if !isOK {
                                    strongSelf.fillContentWithData(shipmentModel, model: model)
                                    NotificationCenter.default.post(name: Constants.Notification.reloadChatScreen, object: nil)
                                }
                            })
                        } else {
                            ErrorLogManager.sharedManager.recordNonFatalError(withException: .FailToParseAPIResponse)
                        }
                    } else {
                        
                    }
                } else {
                    
                }
            } else {
                ErrorLogManager.sharedManager.recordNonFatalError(withException: .NullPointer)
            }
        })

    }
    
    func getOrderCancelled(_ key: String, model: ChatModel){
        _ = OrderService.viewOrderCancel(orderCancelKey: key) { [weak self] (response) in
            if let strongSelf = self {
                if response.result.isSuccess {
                    if response.response?.statusCode == 200 {
                        if let orderCancel = Mapper<OrderCancel>().map(JSONObject: response.result.value) {
                            let shipmentModel = ShipmentModel()
                            shipmentModel.orderCancel = orderCancel
                            shipmentModel.orderType = model.orderType
                            model.shipmentModel = shipmentModel
                            strongSelf.fillContentWithData(shipmentModel, model: model)
                            NotificationCenter.default.post(name: Constants.Notification.reloadChatScreen, object: nil)
                        } else {
                            ErrorLogManager.sharedManager.recordNonFatalError(withException: .FailToParseAPIResponse)
                        }
                    }
                }
            } else {
                ErrorLogManager.sharedManager.recordNonFatalError(withException: .NullPointer)
            }
        }
    }

    func getOrder(_ key: String, model: ChatModel){
        OrderService.viewOrder(key) { [weak self] (response) in
            if let strongSelf = self {
                if response.result.isSuccess {
                    if response.response?.statusCode == 200 {
                        if let order = Mapper<Order>().map(JSONObject: response.result.value) {
                            let shipmentModel = ShipmentModel()
                            let shipment = Shipment()
                            shipment.order = order
                            shipment.orderKey = key
                            shipmentModel.shipment = shipment
                            shipmentModel.orderType = model.orderType
                            model.shipmentModel = shipmentModel
                            strongSelf.fillContentWithData(shipmentModel, model: model)
                            NotificationCenter.default.post(name: Constants.Notification.reloadChatScreen, object: nil)
                        }
                        else {
                            ErrorLogManager.sharedManager.recordNonFatalError(withException: .FailToParseAPIResponse)
                            
                        }
                    }
                }
                else {
                    
                }
            } else {
                ErrorLogManager.sharedManager.recordNonFatalError(withException: .NullPointer)
            }
        }
    }
    @discardableResult
    class func layoutHeight(_ model: ChatModel) -> CGFloat {
        let marginBottom : CGFloat = 20
        switch model.dataType {
        case .OrderShipmentNotification:
            if let shipmentItems = model.shipmentModel?.shipment?.orderShipmentItems {
                return CollectionViewStartY + ShipmentTextCellHeight * 3 + CGFloat(shipmentItems.count) * ShipmentImageCellHeight + marginBottom
            }
            return CollectionViewStartY + ShipmentTextCellHeight * 3 + ShipmentImageCellHeight + marginBottom
        case .OrderCollectionNotification:
            if let shipmentModel = model.shipmentModel {
                let height =  TSShipmentCell.getTextHeight(shipmentModel.getShipmentAddress())
                if let shipmentItems = model.shipmentModel?.shipment?.orderShipmentItems {
                    return CollectionViewStartY + ShipmentTextCellHeight * 2 + height + CGFloat(shipmentItems.count) * ShipmentImageCellHeight + marginBottom
                }
                return CollectionViewStartY + ShipmentTextCellHeight * 2 + height + ShipmentImageCellHeight + marginBottom
            }
            return CollectionViewStartY + ShipmentTextCellHeight * 3 + ShipmentImageCellHeight + marginBottom
        case .OrderShipmentCancelNotification:
            return CollectionViewStartY + ShipmentTextCellHeight * 4 + marginBottom
        case .OrderCollectionCancelNotification:
            if let shipmentModel = model.shipmentModel {
                let height =  TSShipmentCell.getTextHeight(shipmentModel.getShipmentAddress())
                return CollectionViewStartY + ShipmentTextCellHeight * 2 + height  + marginBottom
            }
            return CollectionViewStartY + ShipmentTextCellHeight * 4  + marginBottom
        case .OrderCollectedNotification:
            if let shipmentModel = model.shipmentModel {
                let height =  TSShipmentCell.getTextHeight(shipmentModel.getShipmentAddress())
                return CollectionViewStartY + ShipmentTextCellHeight * 2 + height  + marginBottom
            }
            return CollectionViewStartY + ShipmentTextCellHeight * 4  + marginBottom
        case .OrderShipmentNotConfirmReceivedNotification:
            if let shipmentModel = model.shipmentModel {
                let coursierNameHeigt = TSShipmentCell.getTextHeight(shipmentModel.getCourierName())
                let shipmentNoHeigt = TSShipmentCell.getTextHeight(shipmentModel.getShipmentNo())
                let createdDateHeight =  TSShipmentCell.getTextHeight(shipmentModel.getShipmentCreateDate())
                return CollectionViewStartY + ShipmentTextCellHeight + coursierNameHeigt + shipmentNoHeigt + createdDateHeight  + marginBottom
            }
            return CollectionViewStartY + ShipmentTextCellHeight * 2  + marginBottom
        case .OrderShipmentAutoConfirmReceivedNotification:
            return CollectionViewStartY + ShipmentTextCellHeight * 3  + marginBottom
        case .OrderRemindReviewNotification:
            return CollectionViewStartY + ShipmentTextCellHeight * 2  + marginBottom
        case .OrderDetailUpdatedNotification:
            if let shipmentModel = model.shipmentModel {
                let height =  TSShipmentCell.getTextHeight(shipmentModel.getOrderUpdateAddress())
                return CollectionViewStartY + ShipmentTextCellHeight * 7 + height  + marginBottom
            }
            return CollectionViewStartY + ShipmentTextCellHeight * 8 + marginBottom
        case .OrderCancelNotification:
            if let shipmentModel = model.shipmentModel {
                let height =  TSShipmentCell.getTextHeight(shipmentModel.getShipmentAddress())
                return CollectionViewStartY + ShipmentTextCellHeight * 2 + height + ShipmentImageCellHeight + marginBottom
            }
            return CollectionViewStartY + ShipmentTextCellHeight * 2 + ShipmentImageCellHeight + marginBottom
        case .OrderCancelFailNotification,
             .OrderCancelRefundNotification,
             .OrderReturnRefundNotification:
            return CollectionViewStartY + ShipmentTextCellHeight + marginBottom
        case .ReturnRequestAgreedNotification:
            if let inventory = model.shipmentModel?.inventoryLocation, let shipmentModel = model.shipmentModel {
                let addressHeight = TSShipmentCell.getTextHeight(String.localize("LB_RTN_ADDR") + ": " + inventory.formatAddress())
                let authoriseHeight = TSShipmentCell.getTextHeight(shipmentModel.getReturnAuthorised())
                return CollectionViewStartY + ShipmentTextCellHeight * 6 + authoriseHeight + addressHeight + marginBottom
            }
            else if let shipmentModel = model.shipmentModel {
                let addressHeight = TSShipmentCell.getTextHeight(shipmentModel.getShipmentAddress())
                let authoriseHeight = TSShipmentCell.getTextHeight(shipmentModel.getReturnAuthorised())
                return CollectionViewStartY + ShipmentTextCellHeight * 8 + addressHeight + authoriseHeight  + marginBottom
            }
            return CollectionViewStartY + ShipmentTextCellHeight * 10 + marginBottom
        case .ReturnItemAcceptedNotification:
            return CollectionViewStartY + ShipmentTextCellHeight + marginBottom
        case .ReturnItemRejectedNotification,
             .ReturnRequestRejectedNotification:
            let rejectTextHeight =  TSShipmentCell.getTextHeight(String.localize("LB_CA_RETURN_REJECTED_TEXT"))
            if let shipmentModel = model.shipmentModel {
                
                let responseHeight = TSShipmentCell.getTextHeight(shipmentModel.getMerchantResponse())
                if let shipmentItems = model.shipmentModel?.shipment?.orderShipmentItems {
                    return CollectionViewStartY + ShipmentTextCellHeight + rejectTextHeight + responseHeight + CGFloat(shipmentItems.count) * ShipmentImageCellHeight + marginBottom
                }
                let rmanoHeight = TSShipmentCell.getTextHeight (shipmentModel.getRMANO())
                return CollectionViewStartY + rejectTextHeight + responseHeight  + rmanoHeight +   ShipmentImageCellHeight + marginBottom
            }
            return CollectionViewStartY + ShipmentTextCellHeight * 2 + rejectTextHeight + ShipmentImageCellHeight + marginBottom
        case .ReturnDisputeProcessingNotification:
            let height =  TSShipmentCell.getTextHeight(String.localize("LB_CA_DISPUTE_INPROGRESS_TEXT"))
            return CollectionViewStartY + ShipmentTextCellHeight * 3 + height  + marginBottom
        case .ReturnDisputeApprovedNotification:
            return CollectionViewStartY + ShipmentTextCellHeight  + marginBottom
        case .ReturnDisputeRejectedNotification:
            return CollectionViewStartY + ShipmentTextCellHeight * 3 + marginBottom
        case .ReturnRequestDisputeProcessingNotification:
            return CollectionViewStartY + ShipmentTextCellHeight * 4 + marginBottom
        case .ReturnRequestDisputeRejectedNotification:
            return CollectionViewStartY + ShipmentTextCellHeight * 3 + marginBottom
        case .ReturnRequestDisputeApprovedNotification:
            return CollectionViewStartY + ShipmentTextCellHeight * 3 + marginBottom
        default:
            break
        }
        return 262
    }

    override func layoutContents() {
        super.layoutContents()
        var frame = self.contentView.frame
        frame.size.width = ScreenWidth - TSShipmentCell.MarginLeftRight
        self.contentView.frame = frame;
        self.viewContent.frame = self.contentView.bounds
        guard let model = self.model else {
            return
        }
        self.viewContent.left = (ScreenWidth - self.viewContent.width) / 2
        if model.fromMe {
            backgroundImage.image = UIImage(named: "shareUser_pink")
        } else {
            backgroundImage.image = UIImage(named: "shareUser_wht")
        }
        frame = self.backgroundImage.frame
        frame.size.height = self.frame.size.height - TSShipmentCell.MarginBottom
        self.backgroundImage.frame = frame
        
        frame = self.collectionView.frame
        frame.origin.x = 1 //Margin left 1 px
        frame.size.width = self.viewContent.frame.width - 2 //Margin left and right
        frame.size.height = self.frame.height - (self.collectionView.frame.minY + TSShipmentCell.MarginBottom)
        self.collectionView.frame = frame
        self.collectionView.layer.cornerRadius = TSShipmentCell.ConerRadiusCollectionView
        self.viewContent.top = self.avatarImageView.top
        self.collectionView.reloadData()
    }
    
    // Update list contents
    func fillContentWithData(_ shipmentModel:ShipmentModel, model: ChatModel, inventoryLocation: InventoryLocation? = nil) {
        var status = ""
        self.dataSource = [CollectionViewSectionData]()
        switch model.dataType {
        case .OrderShipmentNotification://Done
            status = String.localize("LB_CAPP_SHIPPED") //+ "0"
            let collectionViewSectionData = CollectionViewSectionData(reuseIdentifier: "",dataSource: [Any]())
            collectionViewSectionData.dataSource.append(String.localize("LB_CA_YOUR_ORDER_1") + String.localize("LB_CA_YOUR_ORDER_2"))
            collectionViewSectionData.dataSource.append(ShipmentItem())
            collectionViewSectionData.dataSource.append(shipmentModel.getCourierName() as Any)
            collectionViewSectionData.dataSource.append(shipmentModel.getShipmentNo() as Any)
            self.dataSource.append(collectionViewSectionData)
            
        case .OrderCollectionNotification:
            
            status = String.localize("LB_CAPP_TOBECOLLECTED")  //+ "1"
            let collectionViewSectionData = CollectionViewSectionData(reuseIdentifier: "",dataSource: [Any]())
            collectionViewSectionData.dataSource.append(String.localize("LB_CA_YOUR_ORDER_1") + String.localize("LB_CA_YOUR_ORDER_3"))
            collectionViewSectionData.dataSource.append(ShipmentItem())
            if let pickupLocation = inventoryLocation {
                collectionViewSectionData.dataSource.append(pickupLocation.formatAddress() as Any)
            }
            else {
                collectionViewSectionData.dataSource.append(shipmentModel.getShipmentAddress() as Any)
            }
            collectionViewSectionData.dataSource.append(shipmentModel.getPostalCode() as Any)
            
            self.dataSource.append(collectionViewSectionData)

        case .OrderShipmentCancelNotification:
            status = String.localize("LB_SHIPMENT_CANCELLED")  //+ "2"
            var collectionViewSectionData = CollectionViewSectionData(reuseIdentifier: "",dataSource: [Any]())
            collectionViewSectionData.dataSource.append(shipmentModel.getCourierName() as Any)
            collectionViewSectionData.dataSource.append(shipmentModel.getShipmentNo() as Any)
            collectionViewSectionData.dataSource.append("" as Any)

            self.dataSource.append(collectionViewSectionData)
            
            collectionViewSectionData = CollectionViewSectionData(reuseIdentifier: "",dataSource: [Any]())
            collectionViewSectionData.dataSource.append(String.localize("LB_SHIPMENT_CANCELLED_TEXT"))
            self.dataSource.append(collectionViewSectionData)
            
        case .OrderCollectionCancelNotification:
             status = String.localize("LB_COLLECTION_CANCELLED")  //+ "3"
             var collectionViewSectionData = CollectionViewSectionData(reuseIdentifier: "",dataSource: [Any]())
             if let pickupLocation = inventoryLocation {
                collectionViewSectionData.dataSource.append(pickupLocation.formatAddress() as Any)
             }
             else {
                collectionViewSectionData.dataSource.append(shipmentModel.getShipmentAddress() as Any)
             }
             collectionViewSectionData.dataSource.append(shipmentModel.getPostalCode() as Any)
             self.dataSource.append(collectionViewSectionData)
             
             collectionViewSectionData = CollectionViewSectionData(reuseIdentifier: "",dataSource: [Any]())
             collectionViewSectionData.dataSource.append(String.localize("LB_SHIPMENT_CANCELLED_TEXT"))
             self.dataSource.append(collectionViewSectionData)
            
        case .OrderCollectedNotification:
            status = String.localize("LB_COLLECTION_COLLECTED")  //+ "4"
            var collectionViewSectionData = CollectionViewSectionData(reuseIdentifier: "",dataSource: [Any]())
            if let pickupLocation = inventoryLocation {
                collectionViewSectionData.dataSource.append(pickupLocation.formatAddress() as Any)
            }
            else {
                collectionViewSectionData.dataSource.append(shipmentModel.getShipmentAddress() as Any)
            }
            collectionViewSectionData.dataSource.append(shipmentModel.getPostalCode() as Any)
            self.dataSource.append(collectionViewSectionData)
            
            collectionViewSectionData = CollectionViewSectionData(reuseIdentifier: "",dataSource: [Any]())
            collectionViewSectionData.dataSource.append(String.localize("LB_COLLECTION_COLLECTED_TEXT"))
            self.dataSource.append(collectionViewSectionData)
            
        case .OrderShipmentNotConfirmReceivedNotification:
            status = String.localize("LB_CAPP_RECEIVING_REMINDER") //+ "5"
            var collectionViewSectionData = CollectionViewSectionData(reuseIdentifier: "",dataSource: [Any]())
            collectionViewSectionData.dataSource.append(shipmentModel.getCourierName() as Any)
            collectionViewSectionData.dataSource.append(shipmentModel.getShipmentNo() as Any)
            collectionViewSectionData.dataSource.append("" as Any)
            collectionViewSectionData.dataSource.append(shipmentModel.getShipmentCreateDate() as Any)
            self.dataSource.append(collectionViewSectionData)
           
            collectionViewSectionData = CollectionViewSectionData(reuseIdentifier: "",dataSource: [Any]())
            collectionViewSectionData.dataSource.append(shipmentModel.getShipmentCreateDate() as Any)
            
        case .OrderShipmentAutoConfirmReceivedNotification:
            status = String.localize("LB_SHIPMENT_MANUALRECEIVE") //+ "6"
            var collectionViewSectionData = CollectionViewSectionData(reuseIdentifier: "",dataSource: [Any]())
            collectionViewSectionData.dataSource.append(shipmentModel.getCourierName() as Any)
            collectionViewSectionData.dataSource.append(shipmentModel.getShipmentNo() as Any)
            self.dataSource.append(collectionViewSectionData)
            
            collectionViewSectionData = CollectionViewSectionData(reuseIdentifier: "",dataSource: [Any]())
            collectionViewSectionData.dataSource.append(String.localize("LB_CA_SHIPMENT_AUTORECEIVE_TEXT"))
            self.dataSource.append(collectionViewSectionData)
            
        case .OrderRemindReviewNotification:
            status = String.localize("LB_ORDER_REVIEW_REMINDER") //+ "7"
            let collectionViewSectionData = CollectionViewSectionData(reuseIdentifier: "",dataSource: [Any]())
            collectionViewSectionData.dataSource.append(String.localize("LB_IM_REMINDER_REVIEW_NOTE"))
            self.dataSource.append(collectionViewSectionData)
            
        case .OrderDetailUpdatedNotification:
            status = String.localize("LB_ORDER_INFO_UPDATED") //+ "8"
            var collectionViewSectionData = CollectionViewSectionData(reuseIdentifier: "",dataSource: [Any]())
            collectionViewSectionData.dataSource.append(String.localize("LB_CA_YOUR_ORDER_4") + String.localize("LB_CA_YOUR_ORDER_5"))
            collectionViewSectionData.dataSource.append("" as Any)
            collectionViewSectionData.dataSource.append(shipmentModel.getOrderUpdateAddress() as Any)
            collectionViewSectionData.dataSource.append("" as Any)
            collectionViewSectionData.dataSource.append(shipmentModel.getOrderUpdatePostalCode() as Any)
            collectionViewSectionData.dataSource.append(shipmentModel.getOrderUpdateRecipientName() as Any)
            collectionViewSectionData.dataSource.append(shipmentModel.getOrderUpdateContact() as Any)
            self.dataSource.append(collectionViewSectionData)
            
            collectionViewSectionData = CollectionViewSectionData(reuseIdentifier: "",dataSource: [Any]())
            collectionViewSectionData.dataSource.append(String.localize("LB_ORDER_INFO_UPDATED_TEXT"))
            self.dataSource.append(collectionViewSectionData)
            
        case .OrderCancelNotification:
            status = String.localize("LB_CA_CANCEL_ACCEPTED") //+ "9"
            let collectionViewSectionData = CollectionViewSectionData(reuseIdentifier: "",dataSource: [Any]())
            collectionViewSectionData.dataSource.append(String.localize("LB_CA_YOUR_ORDER_1") + String.localize("LB_CA_YOUR_ORDER_7"))
            collectionViewSectionData.dataSource.append(ShipmentItem())
            collectionViewSectionData.dataSource.append(String.localize("LB_CANCEL_ORDER_TEXT"))
            self.dataSource.append(collectionViewSectionData)
            
        case .ReturnRequestAgreedNotification:
            status = String.localize("LB_CA_RETURN_AUTHORISED") //+ "10"
            
            let collectionViewSectionData = CollectionViewSectionData(reuseIdentifier: "",dataSource: [Any]())
            collectionViewSectionData.dataSource.append(String.localize("LB_CA_RMA_TEXT_2"))
            collectionViewSectionData.dataSource.append("" as Any)
            
            if let myInventoryLocation = inventoryLocation {
                collectionViewSectionData.dataSource.append(String.localize("LB_RTN_ADDR") + ": " + myInventoryLocation.formatAddress())
                let merchantName = shipmentModel.orderReturn?.order?.merchantName ?? ""
                collectionViewSectionData.dataSource.append(String.localize("LB_CS_CONTACT") + ": " + "\(merchantName)(\(myInventoryLocation.geoCountryName))")
                collectionViewSectionData.dataSource.append(String.localize("LB_CA_POSTAL_CODE") + ": " + "\(myInventoryLocation.postalCode)")
            } else  {
                collectionViewSectionData.dataSource.append(shipmentModel.getReturnAddress() as Any)
                collectionViewSectionData.dataSource.append(shipmentModel.getPostalCode() as Any)
                collectionViewSectionData.dataSource.append(shipmentModel.getRecipientName() as Any)
                collectionViewSectionData.dataSource.append(shipmentModel.getContact() as Any)
            }
        
            collectionViewSectionData.dataSource.append("" as Any)
            collectionViewSectionData.dataSource.append(shipmentModel.getReturnAuthorised() as Any)
            collectionViewSectionData.dataSource.append("" as Any)
            collectionViewSectionData.dataSource.append(shipmentModel.getRMANO() as Any)
            self.dataSource.append(collectionViewSectionData)
            
        case .ReturnItemAcceptedNotification:
            status = String.localize("LB_RETURN_ACCEPT") //+ "12"
            
            let collectionViewSectionData = CollectionViewSectionData(reuseIdentifier: "",dataSource: [Any]())
            collectionViewSectionData.dataSource.append(shipmentModel.getRMANO() as Any)
            self.dataSource.append(collectionViewSectionData)
            
        case .ReturnItemRejectedNotification,
             .ReturnRequestRejectedNotification:
            if model.dataType == .ReturnRequestRejectedNotification {
                status = String.localize("LB_CA_RETURN_REJECTED") //+ "13"
            }
            else {
                status = String.localize("LB_RETURN_REJECT") //+ "13"
            }
            let collectionViewSectionData = CollectionViewSectionData(reuseIdentifier: "",dataSource: [Any]())
            collectionViewSectionData.dataSource.append(shipmentModel.getMerchantResponse() as Any)
            collectionViewSectionData.dataSource.append(ShipmentItem())
            collectionViewSectionData.dataSource.append(String.localize("LB_CA_RETURN_REJECTED_TEXT"))
            collectionViewSectionData.dataSource.append(shipmentModel.getRMANO() as Any)
            self.dataSource.append(collectionViewSectionData)
            
        case .ReturnDisputeProcessingNotification:
            status = String.localize("LB_CA_DISPUTE_INPROGRESS") //+ "14"
            let collectionViewSectionData = CollectionViewSectionData(reuseIdentifier: "",dataSource: [Any]())
            collectionViewSectionData.dataSource.append(String.localize("LB_CA_DISPUTE_INPROGRESS_TEXT"))
            collectionViewSectionData.dataSource.append("" as Any)
            collectionViewSectionData.dataSource.append(shipmentModel.getRMANO() as Any)
            self.dataSource.append(collectionViewSectionData)
            
        case .ReturnDisputeApprovedNotification:
            status = String.localize("LB_CAPP_DISPUTE_CONSUMER_SUCCESS") //+ "15"
            let collectionViewSectionData = CollectionViewSectionData(reuseIdentifier: "",dataSource: [Any]())
            collectionViewSectionData.dataSource.append(String.localize("LB_MM_DISPUTE_RESPONSE"))
            self.dataSource.append(collectionViewSectionData)
            
        case .ReturnDisputeRejectedNotification:
            status = String.localize("LB_CAPP_DISPUTE_CONSUMER_FAIL") //+ "16"
            let collectionViewSectionData = CollectionViewSectionData(reuseIdentifier: "",dataSource: [Any]())
            collectionViewSectionData.dataSource.append(String.localize("LB_MM_DISPUTE_RESPONSE_DELINED"))
            collectionViewSectionData.dataSource.append("" as Any)
            collectionViewSectionData.dataSource.append(shipmentModel.getRMANO() as Any)
            self.dataSource.append(collectionViewSectionData)
            
        case .ReturnRequestDisputeProcessingNotification:
            status = String.localize("LB_CA_DISPUTE_INPROGRESS") //+ "17"
            let collectionViewSectionData = CollectionViewSectionData(reuseIdentifier: "",dataSource: [Any]())
            collectionViewSectionData.dataSource.append(String.localize("LB_CA_DISPUTE_INPROGRESS_TEXT"))
            collectionViewSectionData.dataSource.append("" as Any)
            collectionViewSectionData.dataSource.append(shipmentModel.getRMANO() as Any)
            self.dataSource.append(collectionViewSectionData)
            
        case .ReturnRequestDisputeRejectedNotification:
            status = String.localize("LB_CAPP_DISPUTE_CONSUMER_FAIL") //+ "18"
            let collectionViewSectionData = CollectionViewSectionData(reuseIdentifier: "",dataSource: [Any]())
            collectionViewSectionData.dataSource.append(String.localize("LB_MM_DISPUTE_RESPONSE_DELINED"))
            collectionViewSectionData.dataSource.append("" as Any)
            collectionViewSectionData.dataSource.append(shipmentModel.getRMANO() as Any)
            self.dataSource.append(collectionViewSectionData)
            
        case .ReturnRequestDisputeApprovedNotification:
            status = String.localize("LB_CAPP_DISPUTE_CONSUMER_SUCCESS") //+ "19"
            let collectionViewSectionData = CollectionViewSectionData(reuseIdentifier: "",dataSource: [Any]())
            collectionViewSectionData.dataSource.append(String.localize("LB_MM_DISPUTE_RESPONSE"))
            collectionViewSectionData.dataSource.append("" as Any)
            collectionViewSectionData.dataSource.append(shipmentModel.getRMANO() as Any)
            self.dataSource.append(collectionViewSectionData)
            
        case .OrderCancelFailNotification:
            status = String.localize("LB_CA_CANCEL_REJECTED")
            
        case .OrderCancelRefundNotification,
             .OrderReturnRefundNotification:
            status = String.localize("LB_REFUND_SUCCESS")
            
        default:
            break
        }
        //TO
        self.labelShipmentStatus.text = status
        collectionView.reloadData()
    }
    //MARK - UICollectionViewDataSource
    func numberOfSections(in collectionView: UICollectionView) -> Int {
        return self.dataSource.count
    }
    
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        
        return self.dataSource[section].dataSource.count
    }
    
    //MARK - UICollectionViewDelegate
    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        let data = self.dataSource[indexPath.section].dataSource[
            indexPath.row]
        if let text = data as? String {
            let cell = collectionView.dequeueReusableCell(withReuseIdentifier: DescCell.CellIdentifier, for: indexPath) as! DescCell
            cell.descLabel.text = text
            cell.upperBorderView.isHidden = true
            cell.lowerBorderView.isHidden = true
            return cell
        } else {
            let cell = collectionView.dequeueReusableCell(withReuseIdentifier: OrderItemCell.CellIdentifier, for: indexPath) as! OrderItemCell
            cell.bottomBorderView.isHidden = true
            return cell
        }

    }
    
    //MARK - UICollectionViewDelegateFlowLayout
    
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, sizeForItemAt indexPath: IndexPath) -> CGSize {
        let data = self.dataSource[indexPath.section].dataSource[
        indexPath.row]
        if let text = data as? String {
            return CGSize(width: self.collectionView.frame.width , height: TSShipmentCell.getTextHeight(text))
        }

        return CGSize(width: self.collectionView.frame.width , height: TSShipmentCell.ShipmentImageCellHeight)
        
    }
    
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, insetForSectionAt section: Int) -> UIEdgeInsets {
        return UIEdgeInsets(top: 5, left: 0, bottom: 5, right: 0)
    }
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, minimumInteritemSpacingForSectionAt section: Int) -> CGFloat {
        return 0.0
    }
    
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, minimumLineSpacingForSectionAt section: Int) -> CGFloat {
        return 0.0
    }

    class func getTextHeight(_ text: String) -> CGFloat {
        if text.length > 0{
            let textHeight = CGFloat(text.stringHeightWithMaxWidth(TSShipmentCell.getTextWidth(), font: descCell.descLabel.font))
            return textHeight
        }
        return TSShipmentCell.ShipmentTextCellHeight
    }
    
    class func getTextWidth() -> CGFloat {
        return ScreenWidth - (TSShipmentCell.MarginLeftRight + ShipmentTextReusableView.PaddingLeftRight * 2 + 2)
    }
}
