//
//  TSChatModel.swift
//  TSWeChat
//
//  Created by Hilen on 12/9/15.
//  Copyright © 2015 Hilen. All rights reserved.
//

import Foundation
import ObjectMapper

/*
* 聊天内的子 model，根据字典返回类型做处理
*/
class ChatAudioModel : NSObject, TSModelProtocol, Sharable {
    var audioId : String?
    var audioURL : String?
    var bitRate : String?
    var channels : String?
    var createTime : String?
    var duration : Float?
    var fileSize : String?
    var formatName : String?
    var keyHash : String?
    var mimeType : String?
    var dataBody : Data?
    var isFromMe : Bool?
    
    override init() {
        super.init()
    }
    
    required init?(map: Map) {
        
    }
    
    func mapping(map: Map) {
        audioId <- map["audio_id"]
        audioURL <- map["audio_url"]
        bitRate <- map["bit_rate"]
        channels <- map["channels"]
        createTime <- map["ctime"]
        duration <- (map["duration"], TransformerStringToFloat)
        fileSize <- map["file_size"]
        formatName <- map["format_name"]
        keyHash <- map["key_hash"]
        mimeType <- map["mime_type"]
    }
    
    func getMessageContentType() -> MessageContentType{
        return .VoiceUUID
    }
    
    func getMessageDataType() -> MessageDataType{
        return .AudioUUID
    }
    
    func getShareKey() -> String{
        return ""
    }
}

/*
* 聊天内的子 model，根据字典返回类型做处理
*/
class ChatImageModel : NSObject, TSModelProtocol, Sharable {
    var imageHeight : CGFloat?
    var imageWidth : CGFloat?
    var imageId : String?
    var originalURL : String?
    var thumbURL : String?
    var image: UIImage?
    var localStoreName: String?  //拍照，选择相机的图片的临时名称
    var localThumbnailImage: UIImage? {  //从 Disk 加载出来的图片
        if let theLocalStoreName = localStoreName {
            let path = ImageFilesManager.cachePathForKey(theLocalStoreName)
            return UIImage(contentsOfFile: path!)
        } else {
            return nil
        }
    }
    
    override init() {
        super.init()
    }
    
    init(image: UIImage){
        super.init()
        self.image = image
        imageWidth = image.size.width
        imageHeight = image.size.height
    }
    
    required init?(map: Map) {
        
    }
    
    func mapping(map: Map) {
        imageHeight <- (map["height"], TransformerStringToCGFloat)
        imageWidth <- (map["width"], TransformerStringToCGFloat)
        originalURL <- map["original_url"]
        thumbURL <- map["thumb_url"]
        imageId <- map["image_id"]
    }
    
    func getMessageContentType() -> MessageContentType{
        return .Image
    }
    
    func getMessageDataType() -> MessageDataType{
        return .ImageUUID
    }
    
    func getShareKey() -> String{
        return ""
    }
}

class ProductModel : NSObject, TSModelProtocol, Sharable {
    var style : Style?
    var sku: Sku?
    
    override init() {
        super.init()
    }
    
    required init?(map: Map) {
        
    }

    func mapping(map: Map) {
        style <- map["Style"]
        sku <- map["sku"]
    }
    
    func getMessageContentType() -> MessageContentType{
        return .Product
    }
    
    func getMessageDataType() -> MessageDataType{
        return .Sku
    }
    
    func getShareKey() -> String{
        if let sku = sku {
            return "\(sku.skuId)"
        } else {
            return ""
        }
    }
}

class UserModel : NSObject, TSModelProtocol, Sharable {
    var user : User?
    
    override init() {
        super.init()
    }
    
    required init?(map: Map) {
        
    }
    
    func mapping(map: Map) {
        user        <- map["User"]
    }
    
    func getMessageContentType() -> MessageContentType{
        return .ShareUser
    }
    
    func getMessageDataType() -> MessageDataType{
        return .User
    }
    
    func getShareKey() -> String{
        if let user = user {
            return user.userKey
        } else {
            return ""
        }
    }
}

class BrandModel : NSObject, TSModelProtocol, Sharable {
    var brand : Brand?
    
    override init() {
        super.init()
    }
    
    required init?(map: Map) {
        
    }
    
    func mapping(map: Map) {
        brand    <- map["Brand"]
    }
    
    func getMessageContentType() -> MessageContentType{
        return .ShareBrand
    }
    
    func getMessageDataType() -> MessageDataType{
        return .Brand
    }
    
    func getShareKey() -> String{
        if let brand = brand {
            return "\(brand.brandId)"
        } else {
            return ""
        }
    }
}

class MerchantModel : NSObject, TSModelProtocol, Sharable {
    var merchant : Merchant?
    
    override init() {
        super.init()
    }
    
    required init?(map: Map) {
        
    }
    
    func mapping(map: Map) {
        merchant    <- map["Merchant"]
    }
    
    func getMessageContentType() -> MessageContentType{
        return .ShareMerchant
    }
    
    func getMessageDataType() -> MessageDataType{
        return .Merchant
    }
    
    func getShareKey() -> String{
        if let merchant = merchant {
            return "\(merchant.merchantId)"
        } else {
            return ""
        }
    }
}

class ShipmentModel : NSObject, TSModelProtocol, Sharable {
    var shipment : Shipment?
    var orderReturn : OrderReturn?
    var orderCancel: OrderCancel?
    var orderType : OrderShareType = .Order
    var inventoryLocation: InventoryLocation?
    
    override init() {
        super.init()
    }
    
    required init?(map: Map) {
        
    }
    func mapping(map: Map) {
        shipment    <- map["Shipment"]
    }
    
    func getCourierName() ->String {
        let courierName = shipment?.courierName ?? ""
        return String.localize("LB_COURIER_NAME") + ": " + courierName
    }
    
    func getShipmentNo() ->String {
        if self.orderType == .OrderReturn {
            let title = String.localize("LB_CA_OMS_SHIPMENT_NO") + ": "
            if let orderReturn = self.orderReturn {
                return title + orderReturn.consignmentNumber
            }
            return title
        } else {
            let consignmentNumber = shipment?.consignmentNumber ?? ""
            return String.localize("LB_CA_OMS_SHIPMENT_NO") + ": " + consignmentNumber
        }
       
    }
    
    func getShipmentAddress() ->String {
        let address = String.localize("LB_COLLECTION_ADDRESS") + ": "
        if self.orderType == .OrderReturn {
            if let order = self.orderReturn?.order {
                let collectionAddress = "\(order.country), \(order.province), \(order.city), \(order.address)"
                return address + collectionAddress
            }
        } else {
            if let shipment = self.shipment{
                let collectionAddress = "\(shipment.country), \(shipment.province), \(shipment.city), \(shipment.address)"
                return address + collectionAddress
            }
        }
        
        return address
    }
    
    func getShippingAddress() ->String {
        let address = String.localize("LB_SHIPPING_ADDRESS") + ": "
        if self.orderType == .OrderReturn {
            if let order = self.orderReturn?.order {
                let collectionAddress = "\(order.country), \(order.province), \(order.city), \(order.address)"
                return address + collectionAddress
            }
        } else {
            if let shipment = self.shipment{
                let collectionAddress = "\(shipment.country), \(shipment.province), \(shipment.city), \(shipment.address)"
                return address + collectionAddress
            }
        }
        
        return address
    }
    
    func getReturnAddress() -> String{
        let address = String.localize("LB_RTN_ADDR") + ": "
        if self.orderType == .OrderReturn {
            if let order = self.orderReturn?.order {
                let collectionAddress = "\(order.country), \(order.province), \(order.city), \(order.address)"
                return address + collectionAddress
            }
        } else {
            if let shipment = self.shipment{
                let collectionAddress = "\(shipment.country), \(shipment.province), \(shipment.city), \(shipment.address)"
                return address + collectionAddress
            }
        }
        
        return address
    }
    
    func getOrderUpdateAddress() -> String{
        let address = String.localize("LB_SHIPPING_ADDRESS") + ": "
        if let order = self.shipment?.order {
            let collectionAddress = "\(order.country), \(order.province), \(order.city), \(order.address)"
            return address + collectionAddress
        }
        
        return address
    }
    
    func getOrderUpdatePostalCode() -> String{
        let postalCode = String.localize("LB_POSTAL_OR_ZIP") + ": "
        if let order = self.shipment?.order {
            return postalCode + order.postalCode
        }
        
        return postalCode
    }
    
    func getOrderUpdateRecipientName() ->String {
        let recipientName = self.shipment?.order?.recipientName ?? ""
        return String.localize("LB_RECIPIENT_NAME") + ": " + recipientName
    }
    
    func getOrderUpdateContact () ->String {
        let contact = String.localize("LB_CS_CONTACT") + ": "
        if let order = self.shipment?.order {
            return contact + "(\(order.phoneCode.replacingOccurrences(of: "+", with: ""))) \(order.phoneNumber)"
        }
        return contact
    }
    
    func getPostalCode () ->String {
        let postalCode = String.localize("LB_POSTAL_OR_ZIP") + ": "
        if self.orderType == .OrderReturn {
            if let order = self.orderReturn?.order {
                return postalCode + order.postalCode
            }
        } else {
            if let shipment = self.shipment {
                return postalCode + shipment.postalCode
            }
        }
        
        return postalCode
    }
    
    func getRecipientName() ->String {
        var recipientName = ""
        if self.orderType == .OrderReturn {
            recipientName = orderReturn?.order?.recipientName ?? ""
        } else {
            recipientName = shipment?.recipientName ?? ""
        }
        
        return String.localize("LB_RECIPIENT_NAME") + ": " + recipientName
    }
    
    func getMerchantResponse() ->String {
        let merchantResponse = String.localize("LB_RECIPIENT_NAME") + ": "
        if let orderReturn = self.orderReturn{
            return merchantResponse + orderReturn.description
        }
        return merchantResponse
    }
    func getContact () ->String {
        let contact = String.localize("LB_CS_CONTACT") + ": "
        if self.orderType == .OrderReturn {
            if let order = self.orderReturn?.order {
                return contact + "(\(order.phoneCode.replacingOccurrences(of: "+", with: ""))) \(order.phoneNumber)"
            }
        } else {
            if let shipment = self.shipment {
                return contact + "(\(shipment.phoneCode.replacingOccurrences(of: "+", with: ""))) \(shipment.phoneNumber)"
            }
        }
        return contact
    }
    
    func getReturnAuthorised() ->String {
        let merchantResponse = String.localize("LB_CA_RETURN_AUTHORISED_TEXT")
        if self.orderReturn != nil {
            return merchantResponse.replacingOccurrences(of: "{0}", with: "14")// TODO need to replace {0} whith
        }
        return merchantResponse
    }
    
    func getShipmentCreateDate () -> String{
        let  dateFormat = DateFormatter()
        dateFormat.dateFormat = "yyyy-MM-dd"
        if let shipment = self.shipment{
            return String.localize("LB_CAPP_RECEIVING_REMINDER_TEXT1") + dateFormat.string(from: shipment.lastCreated) +  String.localize("LB_CAPP_RECEIVING_REMINDER_TEXT2")
        }
        return String.localize("LB_CAPP_RECEIVING_REMINDER_TEXT1") + dateFormat.string(from: Date()) +  String.localize("LB_CAPP_RECEIVING_REMINDER_TEXT2")
    }
    
    func getRMANO() -> String{
        let rmaTitle = String.localize("LB_RMA_NO")
        if let orderReturn = self.orderReturn{
            return rmaTitle + ": " + orderReturn.orderReturnKey
        }
        return rmaTitle
    }
    
    func getMessageContentType() -> MessageContentType{
        return .Shipment
    }
    
    func getMessageDataType() -> MessageDataType{
        return .OrderShipmentNotification
    }
    
    func getShareKey() -> String{
        return ""
    }
}

class PostModel : NSObject, TSModelProtocol, Sharable {
    var post: Post?
    var imagePostHeight = CGFloat(50)
    override init() {
        
    }
    
    required init?(map: Map) {
        
    }
    
    func mapping(map: Map) {
        post    <- map["Post"]
    }
    
    func getMessageContentType() -> MessageContentType{
        return .SharePost
    }
    
    func getMessageDataType() -> MessageDataType{
        return .NewsFeedPost
    }
    
    func getShareKey() -> String{
        if let post = post {
            return "\(post.postId)"
        } else {
            return ""
        }
    }

    
}
class MagazineCoverModel : NSObject, TSModelProtocol, Sharable {
    var magazineCover: MagazineCover?
    
    override init() {
        
    }
    
    required init?(map: Map) {
        
    }
    
    func mapping(map: Map) {
        magazineCover    <- map["Page"]
    }
    
    func getMessageContentType() -> MessageContentType{
        return .SharePage
    }
    
    func getMessageDataType() -> MessageDataType{
        return .Magazine
    }
    
    func getShareKey() -> String{
        if let magazineCover = magazineCover {
            return magazineCover.contentPageKey
        } else {
            return ""
        }
    }
    
}

class CouponModel : NSObject, TSModelProtocol, Sharable {
    var coupon: Coupon?
    
    override init() {
        
    }
    
    required init?(map: Map) {
        
    }
    
    func mapping(map: Map) {
        coupon    <- map["Coupon"]
    }
    
    func getMessageContentType() -> MessageContentType{
        return .Coupon
    }
    
    func getMessageDataType() -> MessageDataType{
        return .Coupon
    }
    
    func getShareKey() -> String{
        if let coupon = coupon {
            return coupon.couponReference
        } else {
            return ""
        }
    }
}



class OrderModel : NSObject, TSModelProtocol, Sharable {

    var order: Order?
    var orderShare : OrderShare?
    var orderType = OrderShareType.Unknown
    var orderNumber: String?
    var orderReferenceNumber: String?
    var orderShipmentKey: String?

    override init() {
        super.init()
    }
    
    required init?(map: Map) {
        
    }
    
    func mapping(map: Map) {
    }
    
    func getMessageContentType() -> MessageContentType{
        return .ShareOrder
    }
    
    func getMessageDataType() -> MessageDataType{
        return .Order
    }
    
    func getShareKey() -> String{
        if let orderKey = orderNumber {
            return orderKey
        } else {
            return ""
        }
    }
}

class CommentModel : NSObject, TSModelProtocol, Sharable {
    
    var comment : String?
    var merchantId : Int?
    var status = CommentStatus.Normal
    var forwardedMerchantId: Int?
    var forwardedMerchantQueueName: QueueType?
    var forwardedMerchantName: String?
    var merchantName: String?
    var infoText: String?
    var infoHeight: CGFloat?
    
    override init() {
        super.init()
    }
    
    required init?(map: Map) {
        
    }
    
    func mapping(map: Map) {
    }
    
    func getMessageContentType() -> MessageContentType{
        return .Comment
    }
    
    func getMessageDataType() -> MessageDataType{
        return .Comment
    }
    
    func getShareKey() -> String{
        return ""
    }

}

class TransferRedirectModel : NSObject, TSModelProtocol {
    
    var forwardedMerchantId : Int?
    var stayOn: Bool?
    var transferConvKey: String?

    override init() {
        super.init()
    }
    
    required init?(map: Map) {
        
    }
    
    func mapping(map: Map) {
    }
        
    func getMessageContentType() -> MessageContentType{
        return .TransferRedirect
    }
    
    func getMessageDataType() -> MessageDataType{
        return .TransferRedirect
    }
    
    func getShareKey() -> String{
        return ""
    }
}
