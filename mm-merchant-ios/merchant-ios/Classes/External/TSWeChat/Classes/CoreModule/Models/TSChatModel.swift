//
//  TSChatModel.swift
//  TSWeChat
//
//  Created by Hilen on 12/9/15.
//  Copyright © 2015 Hilen. All rights reserved.
//

import Foundation
import ObjectMapper
import YYText
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


func == (lhs: ChatModel, rhs: ChatModel) -> Bool {
    
    if lhs.messageId != nil && rhs.messageId != nil {
        return lhs.messageId == rhs.messageId
    }
    
    return lhs.correlationKey == rhs.correlationKey
}

func > (lhs: ChatModel, rhs: ChatModel) -> Bool {
    return lhs.timeDate > rhs.timeDate
}

func < (lhs: ChatModel, rhs: ChatModel) -> Bool {
    return lhs.timeDate < rhs.timeDate
}

func <= (lhs: ChatModel, rhs: ChatModel) -> Bool {
    return lhs.timeDate <= rhs.timeDate
}

func >= (lhs: ChatModel, rhs: ChatModel) -> Bool {
    return lhs.timeDate >= rhs.timeDate
}

enum IMMessageStatus: Int {
    case pending
    case failed
    case sent
}

class ChatModel: NSObject, TSModelProtocol {

    enum CouponType: String {
        case MMClaiming = "MMClaiming"
        case MMInput = "MMInput"
        case MMDesignated = "MMDesignated"
        case MerchantClaiming = "MerchantClaiming"
        case MerchantInput = "MerchantInput"
        case MerchantDesignated = "MerchantDesignated"
    }

    var model : Sharable?
    
    var audioModel : ChatAudioModel? //音频的 Model
    var imageModel : ChatImageModel? //图片的 Model
    var productModel : ProductModel?
    var userModel : UserModel?
    var merchantModel : MerchantModel?
    var brandModel : BrandModel?
    var orderModel : OrderModel?
    var commentModel : CommentModel?
//    var postModel : PostModel?
//    var magazineCoverModel : MagazineCoverModel?
    var coupon: Coupon?
    var shipmentModel : ShipmentModel?
    var transferRedirectModel: TransferRedirectModel?
    var chatSendId : String?  //发送人 ID
    var chatSenderProfileKey : String? //Sender profile image
    var chatReceiveId : String? //接受人 ID
    var device : String? //设备类型，iPhone，Android
    var messageContent : String?  //消息内容
    var messageId : String?  //消息 ID
    var messageContentType : MessageContentType = .Text //消息内容的类型
    var timestamp : String?  //同 publishTimestamp
    var agentOnly : Bool?
    
    var imageWidth: CGFloat = 0
    var imageHeight: CGFloat = 0
    
    var shareSkuId: String?
    var shareMerchantId: Int?
    var shareBrandId: Int?
    var shareUserKey: String?
    var sharePostId: Int?
    var shareContentPageKey: String?
    var couponCode: String?
    var couponType: CouponType?
    var orderShipmentKey : String?
    var localStoreName: String?
    var userListNotRead: [String]?
    
    var needToLoadMore = false
    
    var commentStatus = CommentStatus.Normal
    var isPlayingAudio = false
    var merchantId: Int = 0
    
    var messageStatus: IMMessageStatus {
        if messageId != nil {
            return .sent
        } else if Date().timeIntervalSince(timeDate) > Constants.IMTimeout {
            return .failed
        }
        return .pending
    }
    
    var fromCacahe = false
    
    var timeDate = Date() {
        didSet{
            timestamp = String(format: "%f", self.timeDate.timeIntervalSince1970 * 1000)
        }
    }
    
    var messageFromType : MessageFromType = MessageFromType.Group
    
    var _correlationKey: String?
    var correlationKey: String {
        get {
            if let key = _correlationKey {
                return key
            } else if let key = messageId {
                return key
            } else {
                let key = Utils.UUID()
                _correlationKey = key
                return key
            }
        }
        
        set {
            _correlationKey = newValue
        }
    }
    
    //以下是为了配合 UI 来使用
    var fromMe : Bool { return self.chatSendId == Context.getUserKey() }
    var richTextLayout: YYTextLayout?
    var richTextLinePositionModifier: TSYYTextLinePositionModifier?
    var richTextAttributedString: NSMutableAttributedString?
    var messageSendSuccessType: MessageSendSuccessType = .failed //发送消息的状态
    var cellHeight: CGFloat = 0 //计算的高度储存使用，默认0
    var cellSize = CGSize.zero

    var dataType = MessageDataType.Unknown
    var audioDuration: Int = 1
    
    var senderMerchantId: Int?
    var forwardedMerchantId: Int?
    var forwardedMerchantQueueName: QueueType?
    var stayOn: Bool?
    var transferConvKey: String?
    
    var autoMsgType: String?

    var orderType = OrderShareType.Unknown
    var orderReferenceNumber: String?
    var shipmentKey: String?

    var dataBody = "" {
        didSet{
            
            switch dataType {
            case .Text:
                if autoMsgType == AutoMsgType.ConvWelcome.rawValue {
                    self.messageContentType = .AutoRespond
                } else if autoMsgType != nil {
                    self.messageContentType = .AutoRespond
                }

                self.messageContent = dataBody
                
            case .Audio:
                self.messageContent = String.localize("LB_IM_LIST_PREV_VOICE")
                self.messageContentType = .Voice
                
                audioModel = ChatAudioModel()
                audioModel!.isFromMe = fromMe
                
                dataBody = dataBody.replacingOccurrences(of: "data:audio/wav;base64,", with: "") // temp solution for handle web chat engine
                audioModel?.dataBody = Data(base64Encoded: dataBody, options: NSData.Base64DecodingOptions.ignoreUnknownCharacters)
                
                if audioModel?.dataBody != nil {
                    audioModel!.duration = AudioPlayManager.sharedInstance.getDurationFromPlayer(audioModel!.dataBody!)
                }
                
                if audioModel!.duration == nil {
                    audioModel!.duration = 1.0
                }
                
            case .AudioUUID:
                self.messageContent = String.localize("LB_IM_LIST_PREV_VOICE")
                self.messageContentType = .VoiceUUID
                
                audioModel = ChatAudioModel()
                audioModel!.isFromMe = fromMe
                
                if dataBody.length > 0 {
                    audioModel?.keyHash = dataBody
                } else if localStoreName?.length > 0 {
                    audioModel?.keyHash = localStoreName
                }
                audioModel?.audioURL = MediaService.viewAudio(dataBody)
                
                audioModel!.duration = Float(self.audioDuration)
                
                if audioModel!.duration == nil {
                    audioModel!.duration = 1.0
                }
                
            case .Image:
                self.messageContent = String.localize("LB_IM_LIST_PREV_IMG")
                self.messageContentType = .Image
                
                if let data = Data(base64Encoded: dataBody, options: NSData.Base64DecodingOptions.ignoreUnknownCharacters) {
                    
                    self.imageModel = ChatImageModel(image: UIImage(data: data)!)
                }else{
                    Log.debug("incorrect data")
                }
                
            case .ImageUUID:
                self.messageContent = String.localize("LB_IM_LIST_PREV_IMG")
                self.messageContentType = .ImageUUID
                
                let imageModel = ChatImageModel()
                if dataBody.length > 0 {
                    imageModel.originalURL = MediaService.viewImage(dataBody)
                    imageModel.thumbURL = MediaService.viewImage(dataBody)
                }
                imageModel.imageHeight = imageHeight
                imageModel.imageWidth = imageWidth
                imageModel.localStoreName = localStoreName
                
                self.imageModel = imageModel
                
            case .Sku:
                self.messageContent = String.localize("LB_IM_LIST_PREV_PDP")
                self.messageContentType = .Product
                self.shareSkuId = dataBody
                self.cellHeight = CGFloat(440)
                
            case .User:
                self.messageContent = String.localize("LB_IM_LIST_PREV_USER")
                self.messageContentType = .ShareUser
                self.shareUserKey = dataBody
                
            case .Merchant:
                self.messageContent = String.localize("LB_IM_LIST_PREV_MERC")
                self.messageContentType = .ShareMerchant
                self.shareMerchantId = Int(dataBody)
               
            case .Brand:
                self.messageContent = String.localize("LB_IM_LIST_PREV_MERC")
                self.messageContentType = .ShareBrand
                self.shareBrandId = Int(dataBody)
                
            case .Order:
                self.messageContentType = .ShareOrder
                
                self.orderModel = OrderModel()
                self.orderModel!.orderType = orderType
                self.orderModel!.orderNumber = dataBody
                self.orderModel!.orderReferenceNumber = orderReferenceNumber
                self.orderModel!.orderShipmentKey = shipmentKey

                switch orderType {
                    case .Order:
                        self.messageContent = String.localize("LB_IM_LIST_PREV_ORDER")
                        
                    case .OrderShipment:
                        self.messageContent = String.localize("LB_IM_LIST_PREV_SHIPMENT")
                        
                    case .OrderReturn:
                        self.messageContent = String.localize("LB_IM_LIST_PREV_RMA")
                    
                    default: self.messageContent = ""
                }

            case .Comment:
                self.messageContent = String.localize("LB_IM_LIST_PREV_COMMENT")
                self.messageContentType = .Comment
                let commentModel = CommentModel()
                commentModel.comment = self.dataBody
                commentModel.merchantId = self.shareMerchantId
                commentModel.status = self.commentStatus
                self.commentModel = commentModel
                
            case .ForwardImage:
                self.messageContent = String.localize("LB_IM_LIST_PREV_IMG")
                self.messageContentType = .ForwardImage
                
                let imageModel = ChatImageModel()
                if dataBody.length > 0 {
                    imageModel.originalURL = MediaService.viewImage(dataBody)
                    imageModel.thumbURL = MediaService.viewImage(dataBody)
                }
                imageModel.imageHeight = imageHeight
                imageModel.imageWidth = imageWidth
                imageModel.localStoreName = localStoreName
                
                self.imageModel = imageModel

            case .ForwardProduct:
                self.messageContent = String.localize("LB_IM_LIST_PREV_PDP")
                self.messageContentType = .ForwardProduct
                self.shareSkuId = dataBody
                self.cellHeight = CGFloat(440)

            case .ForwardDescription:
                self.messageContent = String.localize("LB_IM_LIST_PREV_COMMENT")
                self.messageContentType = .ForwardDescription
                let commentModel = CommentModel()
                commentModel.comment = self.dataBody
                commentModel.merchantId = self.senderMerchantId
                commentModel.status = self.commentStatus
                commentModel.forwardedMerchantId = self.forwardedMerchantId
                commentModel.forwardedMerchantQueueName = self.forwardedMerchantQueueName
                self.commentModel = commentModel
                
            case .TransferComment:
                self.messageContent = String.localize("LB_IM_LIST_PREV_COMMENT")
                self.messageContentType = .TransferComment
                let commentModel = CommentModel()
                commentModel.comment = self.dataBody
                commentModel.merchantId = self.senderMerchantId
                commentModel.status = self.commentStatus
                commentModel.forwardedMerchantId = self.forwardedMerchantId
                commentModel.forwardedMerchantQueueName = self.forwardedMerchantQueueName
                self.commentModel = commentModel

            case .TransferRedirect:
                self.messageContentType = .TransferRedirect
                let transferRedirect = TransferRedirectModel()
                transferRedirect.forwardedMerchantId = self.forwardedMerchantId
                transferRedirect.stayOn = self.stayOn
                transferRedirect.transferConvKey = self.transferConvKey
                self.transferRedirectModel = transferRedirect

            case .NewsFeedPost:
                self.messageContent = String.localize("LB_IM_LIST_PREV_POST")
                self.messageContentType = .SharePost
                self.sharePostId = Int(dataBody)
            
            case .Magazine:
                self.messageContent = String.localize("LB_IM_LIST_PREV_PAGE")
                self.messageContentType = .SharePage
                self.shareContentPageKey = dataBody
                
            case .Coupon:
                self.messageContent = String.localize("LB_IM_LIST_PREV_COUPON")
                self.messageContentType = .Coupon
                self.couponCode = dataBody
                
            case .MasterCoupon:
                self.messageContent = String.localize("LB_IM_LIST_PREV_COUPON")
                self.messageContentType = .MasterCoupon
                self.merchantId = Int(dataBody) ?? 0
                
            case .OrderShipmentNotification,
                 .OrderShipmentCancelNotification,
                 .OrderShipmentNotConfirmReceivedNotification,
                 .OrderShipmentAutoConfirmReceivedNotification,
                 .OrderCollectionNotification,
                 .OrderCollectionCancelNotification,
                 .OrderCollectedNotification,
                 .OrderCancelNotification,
                 .OrderCancelFailNotification,
                 .OrderCancelRefundNotification,
                 .OrderReturnRefundNotification:
                self.messageContent = String.localize("MSG_NTF_PUSH_ORDER_STATUS")
                self.setShipmentData(dataBody)
                
            case .ReturnRequestAgreedNotification,
                 .ReturnItemRejectedNotification,
                 .ReturnItemAcceptedNotification,
                 .ReturnRequestRejectedNotification:
                self.messageContent = String.localize("MSG_NTF_PUSH_RETURN_STATUS")
                self.setShipmentData(dataBody)

            case .OrderRemindReviewNotification,
                 .OrderDetailUpdatedNotification,
                 .ReturnDisputeProcessingNotification,
                 .ReturnDisputeApprovedNotification,
                 .ReturnDisputeRejectedNotification,
                 .ReturnRequestDisputeProcessingNotification,
                 .ReturnRequestDisputeRejectedNotification,
                 .ReturnRequestDisputeApprovedNotification:
                self.messageContent = "[Shipment]"
                self.setShipmentData(dataBody)
                
            default: break
            }
        }
    }
    
    func setShipmentData(_ body: String) {
        self.messageContentType = .Shipment
        self.orderShipmentKey = body
        let dataType = self.dataType.rawValue as String
        if dataType.range(of: "Return") != nil {
             self.orderType = .OrderReturn
        } else if dataType.range(of: "Cancel") != nil  {
            self.orderType = .OrderCancel
        } else {
             self.orderType = .OrderShipment
        }
        
    }
    var convKey : String?
    var tag : Int = 0
    
    required init?(map: Map) {
        
    }
    
    func mapping(map: Map) {
        messageId                       <-  map["MsgKey"]
        dataType                        <-  map["DataType"]
        chatSendId                      <-  map["SenderUserKey"]
        convKey                         <-  map["ConvKey"]
        timeDate                        <-  (map["Timestamp"], IMDateTransform())
        imageHeight                     <-  map["Height"]
        imageWidth                      <-  map["Width"]
        localStoreName                  <-  map["LocalStoreName"]
        userListNotRead                 <-  map["UserListNotRead"]
        commentStatus                   <- (map["Status"], EnumTransform())
        audioDuration                   <-  map["AudioDuration"]
        correlationKey                  <-  map["CorrelationKey"]
        forwardedMerchantQueueName      <- (map["ForwardedMerchantQueueName"], EnumTransform())
        forwardedMerchantId             <-  map["ForwardedMerchantId"]
        stayOn                          <-  map["StayOn"]
        transferConvKey                 <-  map["TransferConvKey"]
        autoMsgType                     <-  map["AutoMsg"]
        senderMerchantId                <-  map["SenderMerchantId"]
        orderReferenceNumber            <-  map["OrderReferenceNumber"]
        shipmentKey                     <-  map["OrderShipmentKey"]
        orderType                       <-  (map["OrderType"], EnumTransform())
        agentOnly                       <-  map["AgentOnly"]
        couponType                      <-  (map["CouponType"], EnumTransform())
        // dataBody must assign the last
        dataBody                        <-  map["Data"]
    }
    
    func isUnread() -> Bool {
        if let list = userListNotRead, list.contains(Context.getUserKey()) {
            return true
        }
        return false
    }
    
    func read() {
        userListNotRead = nil
    }
    
    func cacheableObject() -> IMMsgCacheObject {
        return IMMsgCacheObject(message: self)
    }
    
    //自定义时间 model
    init(timestamp: String) {
        super.init()
        self.timestamp = timestamp
        self.messageContent = self.timeDate.chatTimeString
        self.messageContentType = .Time
    }
    
    init(timeDate: Date) {
        super.init()
        self.timeDate = timeDate
        self.messageContent = self.timeDate.chatTimeString
        self.messageContentType = .Time
    }
    
    init(type: MessageContentType) {
        super.init()
        self.messageContentType = type
    }
    
    //自定义发送文本的 ChatModel
    init(text: String) {
        super.init()
        self.timestamp = String(format: "%f", Date.milliseconds)
        self.timeDate = Date()
        self.messageContent = text
        self.messageContentType = .Text
        self.chatSendId = Context.getUserKey()
    }
    
    //自定义发送声音的 ChatModel
    init(audioModel: ChatAudioModel) {
        super.init()
        self.timestamp = String(format: "%f", Date.milliseconds)
        self.timeDate = Date()
        self.messageContent = "[声音]"
        self.messageContentType = .VoiceUUID
        self.audioModel = audioModel
        self.chatSendId = Context.getUserKey()
        self.audioDuration = Int(audioModel.duration ?? 1)
        self.localStoreName = audioModel.keyHash
        self.dataBody = audioModel.keyHash ?? ""
    }
    
    init(userModel: UserModel) {
        super.init()
        self.timestamp = String(format: "%f", Date.milliseconds)
        self.messageContentType = .ShareUser
        self.userModel = userModel
        self.chatSendId = Context.getUserKey()
    }
    
    init(merchantModel: MerchantModel) {
        super.init()
        self.timestamp = String(format: "%f", Date.milliseconds)
        self.messageContentType = .ShareMerchant
        self.merchantModel = merchantModel
        self.chatSendId = Context.getUserKey()
    }
    
    init(brandModel: BrandModel) {
        super.init()
        self.timestamp = String(format: "%f", Date.milliseconds)
        self.messageContentType = .ShareBrand
        self.brandModel = brandModel
        self.chatSendId = Context.getUserKey()
    }
    
    //自定义发送图片的 ChatModel
    init(imageModel: ChatImageModel, forwardMode: Bool = false) {
        super.init()
        self.timestamp = String(format: "%f", Date.milliseconds)
        self.timeDate = Date()
        self.messageContent = "[图片]"
        self.messageContentType = forwardMode ? .ForwardImage : .Image
        self.imageModel = imageModel
        self.chatSendId = Context.getUserKey()
        self.localStoreName = imageModel.localStoreName
    }
    
    init(productModel: ProductModel, forwardMode: Bool = false) {
        super.init()
        self.timestamp = String(format: "%f", Date.milliseconds)
        self.messageContentType = forwardMode ? .ForwardProduct : .Product
        self.productModel = productModel
        self.chatSendId = Context.getUserKey()
    }
    
    init(orderModel: OrderModel) {
        super.init()
        self.timestamp = String(format: "%f", Date.milliseconds)
        self.messageContentType = .ShareOrder
        self.orderModel = orderModel
        self.chatSendId = Context.getUserKey()
    }
    
    init(couponType: MessageContentType, merchantId: Int) {
        super.init()
        self.timestamp = String(format: "%f", Date.milliseconds)
        self.messageContentType = .MasterCoupon
        self.chatSendId = Context.getUserKey()
        self.merchantId = merchantId
        self.messageContent = String(merchantId)
    }
    
    init(commentModel: CommentModel, forwardMode: Bool = false) {
        super.init()
        self.timestamp = String(format: "%f", Date.milliseconds)
        self.timeDate = Date()
        self.messageContentType = forwardMode ? .ForwardDescription : .Comment
        self.chatSendId = Context.getUserKey()
        self.commentModel = commentModel
    }
    
    init(shipmentModel: ShipmentModel) {
        super.init()
        self.timestamp = String(format: "%f", Date.milliseconds)
        self.timeDate = Date()
        self.messageContentType = .Shipment
        self.chatSendId = Context.getUserKey()
        self.shipmentModel = shipmentModel
    }
    
    init<T:Sharable>(model: T){
        super.init()
        self.timestamp = String(format: "%f", Date.milliseconds)
        self.timeDate = Date()
        self.messageContentType = model.getMessageContentType()
        self.chatSendId = Context.getUserKey()
        self.model = model
    }
    
    var downloadProgress: Float = 0
    
    func requestMessage(_ myUserRole: UserRole?) -> IMMessage? {
        
        guard let convKey = self.convKey else {
            return nil
        }
        
        var message: IMMessage?
        
        switch messageContentType {
        
        case .Text:
            message = IMTextMessage(
                text: dataBody,
                convKey: convKey,
                myUserRole: myUserRole
            )
        case .ImageUUID:
            guard let localStoreName = self.localStoreName else {
                return nil
            }
            
            message = IMImageMessage(
                localStoreName: localStoreName,
                width: imageWidth,
                height: imageHeight,
                convKey: convKey,
                myUserRole: myUserRole
            )
            
            (message as! IMImageMessage).data = dataBody
            
        case .VoiceUUID:
            guard let localStoreName = self.localStoreName else {
                return nil
            }
            
            message = IMAudioMessage(
                localStoreName: localStoreName,
                duration: audioDuration,
                convKey: convKey,
                myUserRole: myUserRole
            )
            
            (message as! IMAudioMessage).data = dataBody
            
        case .Product:
            message = IMSkuMessage(
                skuId: dataBody,
                convKey: convKey,
                myUserRole: myUserRole
            )
        case .ShareUser:
            message = IMContactMessage(
                userKey: dataBody,
                convKey: convKey,
                myUserRole: myUserRole
            )
        case .ShareMerchant:
            message = IMMerchantMessage(
                merchantId: dataBody,
                convKey: convKey,
                myUserRole: myUserRole
            )
        case .ShareOrder:
            // missing
            break
        case .SharePost:
            guard let postId =  Int(dataBody) else {
                return nil
            }
            
            message = IMPostMessage(
                postId: postId,
                convKey: convKey,
                myUserRole: myUserRole
            )
        case .SharePage:
            message = IMPageMessage(
                contentPageKey: dataBody,
                convKey: convKey,
                myUserRole: myUserRole
            )
        case .MasterCoupon:
            message = IMMasterCouponMessage(
                convKey: convKey,
                myUserRole: myUserRole,
                merchantId: dataBody
            )
        default:
            break
        }
        
        message?.correlationKey = correlationKey
        
        return message
        
    }
    
    // Show timestamp if 2 messages are in different days
    func shouldDisplayTimstampBetween(_ targetModel: ChatModel) -> Bool {
        
        let calendar = Calendar.current
        let unit: NSCalendar.Unit = [
            NSCalendar.Unit.year,
            NSCalendar.Unit.month,
            NSCalendar.Unit.day
            ]
        let currentComponents:DateComponents = (calendar as NSCalendar).components(unit, from: timeDate)
        let targetComponents:DateComponents = (calendar as NSCalendar).components(unit, from: targetModel.timeDate)

        let year = currentComponents.year! - targetComponents.year!
        let month = currentComponents.month! - targetComponents.month!
        let day = currentComponents.day! - targetComponents.day!
        
        if day > 0 || month > 0 || year > 0 {
            return true
        }
        
        return false
    }
    
    override init() {
        super.init()
    }
    
}

// MARK: - 聊天时间的 格式化字符串
extension Date {
    
    fileprivate var chatTimeString: String {
        get {
            let calendar = Calendar.current
            let now = Date()
            let unit: NSCalendar.Unit = [
                NSCalendar.Unit.minute,
                NSCalendar.Unit.hour,
                NSCalendar.Unit.day,
                NSCalendar.Unit.month,
                NSCalendar.Unit.year,
                ]
            let nowComponents:DateComponents = (calendar as NSCalendar).components(unit, from: now)
            let targetComponents:DateComponents = (calendar as NSCalendar).components(unit, from: self)
            
            let year = nowComponents.year! - targetComponents.year!
            let month = nowComponents.month! - targetComponents.month!
            let day = nowComponents.day! - targetComponents.day!
            
            if year > 0 {
                return String.localize("LB_YEARDATE_COUNT").replacingOccurrences(of: "{0}", with: "\(targetComponents.year!)").replacingOccurrences(of: "{1}", with: "\(targetComponents.month!)").replacingOccurrences(of: "{2}", with: "\(targetComponents.day!)")
            }
            else if month > 0 || day > 1 {
                return String.localize("LB_DATE_COUNT").replacingOccurrences(of: "{0}", with: "\(targetComponents.month!)").replacingOccurrences(of: "{1}", with: "\(targetComponents.day!)")
            }
            else {
                if day > 0 {
                    return String.localize("LB_YESTERDAY")
                }
                else {
                    return String.localize("LB_DATE_TODAY")
                }
            }
        }
    }
    
    public var imTimeString: String {
        get {
            let calendar = Calendar.current
            let now = Date()
            let unit: NSCalendar.Unit = [
                NSCalendar.Unit.minute,
                NSCalendar.Unit.hour,
                NSCalendar.Unit.day,
                NSCalendar.Unit.month,
                NSCalendar.Unit.year,
                ]
            let nowComponents:DateComponents = (calendar as NSCalendar).components(unit, from: now)
            let targetComponents:DateComponents = (calendar as NSCalendar).components(unit, from: self)
            
            let year = nowComponents.year! - targetComponents.year!
            let month = nowComponents.month! - targetComponents.month!
            let day = nowComponents.day! - targetComponents.day!
            
            if year > 0 {
                return String.localize("LB_YEARDATE_COUNT").replacingOccurrences(of: "{0}", with: "\(targetComponents.year!)").replacingOccurrences(of: "{1}", with: "\(targetComponents.month!)").replacingOccurrences(of: "{2}", with: "\(targetComponents.day!)")
            } else if month > 0 || day > 1 {
                return String.localize("LB_DATE_COUNT").replacingOccurrences(of: "{0}", with: "\(targetComponents.month!)").replacingOccurrences(of: "{1}", with: "\(targetComponents.day!)")
            } else {
                if day > 0 {
                    return String.localize("LB_YESTERDAY")
                } else {
                    let dateFormat = DateFormatter()
                    dateFormat.dateFormat = "HH:mm:ss"
                    return dateFormat.string(from: self)
                }
            }
        }
    }
    
}
