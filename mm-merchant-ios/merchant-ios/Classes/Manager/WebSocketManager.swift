//
//  WebSocketManager.swift
//  merchant-ios
//
//  Created by Koon Kit Chan on 7/3/2016.
//  Copyright © 2016 WWE & CO. All rights reserved.
//

import Foundation
import UIKit
import ObjectMapper
import SwiftWebSocket
import Alamofire
import RealmSwift
import PromiseKit
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


let IMDidUpdateConversationList = "IMDidUpdateConversationList"
let IMDidUpdateLinkedCustomerServices = "IMDidUpdateLinkedCustomerServices"
let IMDidReceiveMessage = "IMDidReceiveMessage"
let IMDidReceiveHistory = "IMDidReceiveHistory"
let IMDidUpdateUnreadBadgeNumber = "IMDidUpdateUnreadBadgeNumber"
let IMDidWebsocketConnected = "IMDidWebsocketConnected"
let IMDidUpdateQueueConvList = "IMDidUpdateQueueConvList"

let IMConversationHistoryKey = "IMConversationHistoryKey"
let IMConversationListKey = "IMConversationListKey"
let IMMessageKey = "IMMessageKey"

typealias IMMessageCallback = (_ ack: IMAckMessage) -> Void

enum MessageType: String {
    case Announce               = "Announce"
    case Init                   = "Init"
    case Message                = "Msg"
    case MessageList            = "MsgList"
    case Conversation           = "Conv"
    case ConversationList       = "ConvList"
    case ConversationHide       = "ConvHide"
    case ConversationStart      = "ConvStart"
    case ConversationForward    = "ConvForward"
    case ConversationTransfer   = "ConvTransfer"
    case ConversationFlag       = "ConvFlag"
    case ConversationUnFlag     = "ConvUnFlag"
    case ConversationClose      = "ConvClose"
    case ConversationAdd        = "ConvAdd"
    case ConversationRemove     = "ConvRemove"
    case ConversationRead       = "ConvRead"
    case MessageAcknowledgement = "Ack"
    case QueueStatistics        = "QueueStat"
    case MessageRead            = "MsgRead"
    case QueueAnswerNext        = "QueueAnswerNext"
    case QueueAnswerSpecific    = "QueueAnswerSpecific"
    case ConvName               = "ConvName"
    case Error                  = "Error"
}

enum MessageDataType: String {
    case Unknown            = "Unknown"
    case Text               = "Text"
    case Audio              = "Audio"
    case Image              = "Image"
    case ImageUUID          = "ImageUUID"
    case AudioUUID          = "AudioUUID"
    case Sku                = "Sku"
    case User               = "User"
    case Merchant           = "Merchant"
    case Brand              = "Brand"
    case Order              = "Order"
    case Refund             = "Refund"
    case Comment            = "Comment"
    case ForwardDescription = "ForwardDescription"
    case ForwardProduct     = "ForwardProduct"
    case ForwardImage       = "ForwardImage"
    case TransferComment    = "TransferComment"
    case TransferRedirect   = "TransferRedirect"
    case NewsFeedPost       = "Post"
    case Magazine           = "Page"
    case Coupon             = "Coupon"
    case MasterCoupon       = "MasterCoupon"
    case OrderShipmentNotification = "OrderShipmentNotification"
    case OrderCollectionNotification = "OrderCollectionNotification"
    case OrderShipmentCancelNotification = "OrderShipmentCancelNotification"
    case OrderCollectionCancelNotification = "OrderCollectionCancelNotification"
    case OrderCollectedNotification = "OrderCollectedNotification"
    case OrderShipmentNotConfirmReceivedNotification = "OrderShipmentNotConfirmReceivedNotification"
    case OrderShipmentAutoConfirmReceivedNotification = "OrderShipmentAutoConfirmReceivedNotification"
    case OrderRemindReviewNotification = "OrderRemindReviewNotification"
    case OrderDetailUpdatedNotification = "OrderDetailUpdatedNotification"
    case OrderCancelNotification = "OrderCancelNotification"
    case OrderCancelFailNotification = "OrderCancelFailNotification"
    case OrderCancelRefundNotification = "OrderCancelRefundNotification"
    case OrderReturnRefundNotification = "OrderReturnRefundNotification"
    case ReturnRequestAgreedNotification = "ReturnRequestAgreedNotification"
    case ReturnItemAcceptedNotification = "ReturnItemAcceptedNotification"
    case ReturnItemRejectedNotification = "ReturnItemRejectedNotification"
    case ReturnDisputeProcessingNotification = "ReturnDisputeProcessingNotification"
    case ReturnDisputeApprovedNotification = "ReturnDisputeApprovedNotification"
    case ReturnDisputeRejectedNotification = "ReturnDisputeRejectedNotification"
    case ReturnRequestDisputeProcessingNotification = "ReturnRequestDisputeProcessingNotification"
    case ReturnRequestDisputeRejectedNotification = "ReturnRequestDisputeRejectedNotification"
    case ReturnRequestDisputeApprovedNotification = "ReturnRequestDisputeApprovedNotification"
    case ReturnRequestRejectedNotification = "ReturnRequestRejectedNotification"
}

enum AutoMsgType: String {
    case Unknown            = "Unknown"
    case ConvWelcome        = "ConvWelcome"
    //TODO: correct the name later
    case Idle               = "Idle"
    case NotAvailable       = "NotAvailable"
}

class WebSocketManager {
    
    private enum WebSocketError: Error {
        case invalidURL
    }
    
    private let MaxRetryCount = 10
    private let SocketTimeout = TimeInterval(10)
    private let PingInterval = TimeInterval(20)
    private let ReconnectDelayRange = 1000...10000
    
    private static let instance = WebSocketManager()
    private let webSocketQueue = DispatchQueue(label: "com.mm.websocket", attributes: [])
    
    private var URI = Constants.Path.WebSocketHost
    private var webSocketClient: WebSocket?
    private var isStarted = false
    fileprivate(set) var userKey: String? {
        didSet {
            if let key = userKey {
                self.user = CacheManager.sharedManager.cachedUserForUserKey(key)
            }
        }
    }

    fileprivate(set) var user: User?
    private var attemptNumber = 0
    
    private var reconnectAction: DelayAction?
    private var timeoutAction: DelayAction?
    private var pingTimer: Timer!
    
    private var lastMessages = [String: ChatModel]()
        
    private var convListMap = [String: Conv]()
    
    private var _convList = [Conv]()
    fileprivate(set) var convList: [Conv] {
        get {
            return _convList
        }
        set (newValue) {
            
            
            convListMap.removeAll()
            
            _convList = newValue.filter({ (conv) -> Bool in

                // add convs
                convListMap[conv.convKey] = conv
                
                if let uKey = userKey, conv.userListHidden.contains(uKey) {
                    return false
                }
                
                return true
            })
            
            sortConvsationList()
            
            var cacheList = [IMConvCacheObject]()
            
            for conv in convList {
                
                convListMap[conv.convKey] = conv
                
                if let lastMessage = conv.lastMessage {
                    updateLastChatMessages(lastMessage)
                }
                
                cacheList.append(conv.cacheableObject())
            }
            
            CacheManager.sharedManager.updateCacheConvList(cacheList)
            
            PostNotification(IMDidUpdateConversationList, object: nil, userInfo: [IMConversationListKey: _convList])
        }
    }
    
    private var _queueConvList = [Conv]()
    fileprivate(set) var queueConvList: [Conv] {
        get {
            return _queueConvList
        }
        set (newValue) {
            
            _queueConvList = newValue
            
            _queueConvList.sort(by: {$0.timestamp > $1.timestamp})
    
            
            PostNotification(IMDidUpdateQueueConvList, object: nil, userInfo: [IMConversationListKey: _queueConvList])
        }
    }
    
    fileprivate(set) var linkedCustomerServices: [MerchantQueues]? {
        didSet {
            PostNotification(IMDidUpdateLinkedCustomerServices, object: linkedCustomerServices)
        }
    }
    
    private var requestPool = [String: (message: IMMessage, completion: IMMessageCallback?)]()
    
    var isConnected: Bool {
        get {
            if let ws = webSocketClient {
                return ws.readyState == .open
            }
            return false
        }
    }
    
    fileprivate(set) var numberOfUnread: Int = 0 {
        didSet {
            if oldValue != numberOfUnread {
                PostNotification(IMDidUpdateUnreadBadgeNumber)
            }
        }
    }
    
    func clearNumberOfUnread() {
        numberOfUnread = 0
    }
    
    static func sharedInstance() -> WebSocketManager {
        return instance
    }
    
    private init() {
        pingTimer = Timer.scheduledTimer(
            timeInterval: PingInterval,
            target: self,
            selector: #selector(WebSocketManager.sendPing),
            userInfo: nil,
            repeats: true
        )
        
        supplementaryDataForConvList(
            CacheManager.sharedManager.cachedConvList(),
            completion: { convList in
                self.convList = convList
                self.updateConversationUnreadCount()
            }
        )
        
    }
    
    private func RunOnSocketThread(_ block: @escaping ()->()) {
        webSocketQueue.async(execute: block)
    }
    
    private func RunOnMainThread(_ block: @escaping ()->()) {
        DispatchQueue.main.async(execute: block)
    }
    
    private func generateWebSocket() throws -> WebSocket {
        
        guard let url = URL(string: URI) else {
            throw WebSocketError.invalidURL
        }
        
        var request = URLRequest(url: url)
        request.timeoutInterval = SocketTimeout
        
        let ws = WebSocket(request: request)
        
        ws.allowSelfSignedSSL = Platform.TrustAnyCert
        ws.compression.on = true
        ws.eventQueue = webSocketQueue
        
        ws.event.message = { message in
            Log.debug("Websocket didReceiveMessage")
            
            if let text = message as? String {
                self.processMessage(text)
            }
        }
        
        ws.event.open = {
            Log.debug("Websocket was connected!")
            self.attemptNumber = 0
            
            let merchants = Context.customerServiceMerchants()
            self.sendMessage(IMAnnounceMessage(senderMerchantList: merchants.merchantIds()))
            PostNotification(IMDidWebsocketConnected, userInfo: nil)
        }
        
        ws.event.pong = { _ in
            self.timeoutAction?.cancel()
        }
        
        ws.event.end = { code, reason, wasClean, error in
            Log.debug("Disconnected! code: \(code), reason: \(reason), wasClean: \(wasClean), error: \(String(describing: error))")
            
            // Normal Closure
            if code != 1000 {
                self.reconnect()
            } else {
                Log.debug("Normal Closure (no reconnection!)")
            }
        }
        
        return ws
    }
    
    private func sortConvsationList() {
        _convList.sort(by: {$0.timestamp > $1.timestamp})
    }
    
    private func supplementaryDataForConvList(_ convList: [Conv], completion: (([Conv]) -> Void)?) {
        
        var userList = [String]()
        var merchantList = [Int]()
        
        if let me = userKey {
            userList.append(me)
        }
        
        for conv in convList {
            
            if let merchantId = conv.merchantId, !merchantList.contains(merchantId) {
                merchantList.append(merchantId)
            }
            
            if let senderMerchantId = conv.senderMerchantId, !merchantList.contains(senderMerchantId) {
                merchantList.append(senderMerchantId)
            }
            
            for userRole in conv.userList {
                if let userKey = userRole.userKey, !userKey.isEmpty && !userList.contains(userRole.userKey!) {
                    userList.append(userRole.userKey!)
                }
                
                if let merchantId = userRole.merchantId, !merchantList.contains(merchantId) {
                    merchantList.append(merchantId)
                }
            }
        }
        
        var userReady = false
        var merchantReady = false
        
        func done() -> Bool {
            return merchantReady && userReady
        }
        
        var userPromise = [Promise<[String: User]>]()
        while userList.count > Constants.MAX_USER_REQUEST {
            let cutList = userList.initial(userList.count - Constants.MAX_USER_REQUEST)
            userList = userList.rest(Constants.MAX_USER_REQUEST)
            
            userPromise.append(Promise<[String: User]> { fufill, fail in
                UserService.viewListWithUserKeys(
                cutList,
                completion: { (map) in
                    fufill(map)
                })
            })
        }
        
        userPromise.append(Promise<[String: User]> { fufill, fail in
            UserService.viewListWithUserKeys(
                userList,
                completion: { (map) in
                    fufill(map)
            })
        })

        when(fulfilled: userPromise).then { maps -> Void in
            var me: User?
            var mergedMap = [String: User]()
            
            maps.eachWithIndex({ (index, map) in
                if index == 0 {
                    mergedMap = map
                }
                else {
                    mergedMap.mergeAll(map)
                }
            })
            
            if let userKey = self.userKey {
                me = mergedMap[userKey]
            }
            
            for conv in convList {
                conv.updateUsers(me, map: mergedMap)
            }
            
            userReady = true
            if let callback = completion, done() {
                callback(convList)
            }
        }
        
        var promise = [Promise<Merchant?>]()
        
        for ids in merchantList {
            promise.append(Promise<Merchant?> { fufill, fail in
                CacheManager.sharedManager.merchantById(ids, completion: { merchantObject in
                    fufill(merchantObject)
                })
            })
        }
        
        when(fulfilled:  promise).then { (merchants) -> Void in
            
            var map = [Int: Merchant]()
            for optionalMerchant in merchants {
                if let merchant = optionalMerchant {
                    map[merchant.merchantId] = merchant
                }
            }
            
            for conv in convList {
                conv.updateMerchants(map)
            }
            
            merchantReady = true
            if let callback = completion, done() {
                callback(convList)
            }
        }
    }
    
    func handleResponse(_ message: IMSystemMessage) {
        
        if let (_, requestCallback) = requestPool[message.correlationKey] {
            
            let ackMessage = IMAckMessage(associatedObject: message)
            
            if let callback = requestCallback {
                self.RunOnMainThread {
                    callback(ackMessage)
                }
            }
            
            requestPool.removeValue(forKey: message.correlationKey)
            
        }

    }
    
    private func processMessage(_ message: String) {
        
        Log.debug("IM Rev : " + message)
        
        guard let json = message.toJSON() as? [String: Any] else {
            return
        }
        
        guard let typeString = json["Type"] as? String else {
            return
        }
        
        guard let type = MessageType(rawValue: typeString) else {
            // ignore incorrect json string or unknown message type
            return
        }
        
        switch type {
            
        case .Init:
            
            guard let initMessage = Mapper<IMInitMessage>().map(JSONObject: json) else {
                break
            }
            
            supplementaryDataForConvList(
                initMessage.convList,
                completion: { convList in
                    self.convList = convList
                    self.linkedCustomerServices = initMessage.linkedCustomerServices()
                    self.updateConversationUnreadCount()
                }
            )
            
            break
            
        case .Conversation:
            Log.debug("Started the conversation here")
            
            guard let incomingConv = Mapper<Conv>().map(JSONObject: json) else {
                break
            }
            
            if incomingConv.msgNotReadCount == nil {
                let existedConv = conversationForKey(incomingConv.convKey)
                incomingConv.msgNotReadCount = existedConv?.msgNotReadCount ?? 0
            }
            
            var updatedConversation = [Conv]()
            
            for existConv in convList {
                if existConv.convKey != incomingConv.convKey {
                    updatedConversation.append(existConv)
                }
            }
            
            updatedConversation.append(incomingConv)
            
            supplementaryDataForConvList(
                updatedConversation,
                completion: { convList in
                    self.convList = convList
                }
            )
            
            break
            
        case .MessageList:
            
            guard let msgListMessage = Mapper<IMMsgListResponseMessage>().map(JSONObject: json) else {
                break
            }
            
            CacheManager.sharedManager.cacheObject(msgListMessage.cacheableObjects())
            
            handleResponse(msgListMessage)
            
            PostNotification(IMDidReceiveHistory, userInfo:[
                IMConversationHistoryKey: msgListMessage.messageList
                ]
            )
            
            break
            
        case .Message:
            
            guard let message = Mapper<ChatModel>().map(JSONObject: json), let convKey = message.convKey else {
                break
            }
            
            CacheManager.sharedManager.cacheObject(message.cacheableObject())
            
            if let userKey = self.userKey, let senderUserKey = message.chatSendId, let userListNotRead = message.userListNotRead,
                userListNotRead.contains(userKey) && senderUserKey == userKey {
                self.msgReadMessage(message)
            }
            
            if let conv = resetHiddenConv(convKey), message.agentOnly == false {
                updateConversationUnreadCount(conv, delta: 1)
            }
            
            updateLastChatMessages(message)

            PostNotification(IMDidUpdateConversationList, userInfo: [IMConversationListKey : self.convList])
            
            PostNotification(IMDidReceiveMessage, userInfo: [IMMessageKey : message])
            
            break
        
        case .QueueStatistics:
            
            guard let queueStat = Mapper<QueueStatistics>().map(JSONObject: json) else {
                break
            }
            
            guard let services = linkedCustomerServices else {
                break
            }
            
            for merchant in services {
                if merchant.merchantId == queueStat.merchantId {
                    merchant.addQueue(queueStat)
                    break
                }
            }
            
            PostNotification(IMDidUpdateLinkedCustomerServices, object: linkedCustomerServices)
            
            break
            
        case .MessageAcknowledgement:
            
            guard let ackMessage = Mapper<IMAckMessage>().map(JSONObject: json) else {
                break
            }
            
            // some requests will return specify object insetad of ack
            let ignoreType: [MessageType] = [.MessageList]
            
            if ignoreType.contains(ackMessage.type) {
                break
            }
            
            if let (message, requestCallback) = requestPool[ackMessage.correlationKey] {
                
                if let module = message.toChatModel() {
                    module.messageId = ackMessage.data
                    CacheManager.sharedManager.cacheObject(module.cacheableObject())
                }
                
                if let callback = requestCallback {
                    self.RunOnMainThread {
                        callback(ackMessage)
                    }
                }
                
                requestPool.removeValue(forKey: ackMessage.correlationKey)
                
            }
            
            break
            
        case .ConversationList:
            
            //Log.debug(json)
            guard let queueConvs = Mapper<IMInitMessage>().map(JSONObject: json) else {
                break
            }
            
            supplementaryDataForConvList(
                queueConvs.convList,
                completion: { convList in
                    self.queueConvList = convList
                    self.updateConversationUnreadCount()
                }
            )
            break
            
        default:
            
            break
            
        }
        
    }
    
    private func connect() {
        self.webSocketClient?.open()
    }
    
    private func disconnect() {
        self.webSocketClient?.close()
    }
    
    func startService(_ userKey: String){
        RunOnSocketThread {
            if !self.isStarted {
                
                self.userKey = userKey
                self.isStarted = true
                self.attemptNumber = 0
                
                self.reconnectAction?.cancel()
                self.reconnectAction = nil
                
                do {
                    self.webSocketClient = try self.generateWebSocket()
                } catch WebSocketError.invalidURL {
                    Log.debug("Can't create web socket due to invalid url \(self.URI)")
                } catch {
                    Log.debug("Something wrong when creating web socket.")
                }
                
                self.connect()
 
            } else {
                Log.debug("Service already started, please stop it first.")
            }
        }
    }
    
    func stopService() {
        RunOnSocketThread {
            
            self.isStarted = false
            
            self.reconnectAction?.cancel()
            self.reconnectAction = nil
            
            self.timeoutAction?.cancel()
            self.timeoutAction = nil
            
            self.disconnect()
            
            Log.debug("Client trigger disconnect")
        }
    }
    
    private func scheduleReconnectAction() -> DelayAction {
        
        let random = arc4random() % UInt32(ReconnectDelayRange.upperBound)
        let delay = TimeInterval(Double(Int(random) + ReconnectDelayRange.lowerBound) / 1000.0)
        Log.debug("Schedule reconnect : \(delay)s")
        
        return DelayAction(
            delayInSecond: delay,
            actionBlock: {
                self.RunOnSocketThread({
                    if (self.isStarted) {
                        
                        self.webSocketClient?.open()
                        
                        Log.debug("Perform reconnect (count : \(self.attemptNumber))")
                    }
                })
        })
    }
    
    private func scheduleTimeoutAction() -> DelayAction {
        
        return DelayAction(
            delayInSecond: SocketTimeout,
            actionBlock: {
                self.RunOnSocketThread({
                    Log.debug("Timeout!")
                    self.reconnect()
                })
        })
    }
    
    private func reconnect() {
        
        if self.isStarted {
            
            self.disconnect()
            self.reconnectAction?.cancel()
            
            if (self.attemptNumber < self.MaxRetryCount) {
                
                self.attemptNumber += 1
                self.reconnectAction = self.scheduleReconnectAction()
                
            } else {
                
                self.isStarted = false
                Log.debug("Reconnection reach the MAX attempt number!")
                
            }
            
        } else {
            Log.debug("Reconnection stoped")
        }
        
    }
    
    @objc func sendPing() {
        
        assert(SocketTimeout < PingInterval)
        
        RunOnSocketThread {
            if self.isStarted && self.isConnected {
                self.webSocketClient?.ping()
                self.timeoutAction = self.scheduleTimeoutAction()
            }
        }
    }
    
    /*!
     send message without convkey
     */
    func sendMessage(_ userList: [UserRole], myUserRole: UserRole, message: IMUserMessage, completion: IMMessageCallback?) {
        sendMessage(
            IMConvStartMessage(userList: userList, senderMerchantId: myUserRole.merchantId),
            completion: { (ack) in
                if ack.isError(), let callback = completion {
                    callback(ack)
                } else {
                    if let convKey = ack.data {
                        message.convKey = convKey
                        self.sendMessage(
                            message,
                            completion: completion
                        )
                    }
                }
            }
        )
    }
    
    @discardableResult
    func resetHiddenConv(_ convKey: String) -> Conv? {
        
        let result = convListMap[convKey]
        
        if let conv = result {
            conv.userListHidden.removeAll()
            if !convList.contains(conv) {
                convList.append(conv)
            }
            CacheManager.sharedManager.cacheObject(conv.cacheableObject())
        }
        
        return result
    }
    
    func sendMessage(_ message: IMMessage, checkNetwork: Bool = false, viewController: UIViewController? = nil, completion: IMMessageCallback?, failure: (() -> Void)? = nil) {
        
        //
        if checkNetwork {
            if let viewController = viewController {
                if Reachability.shared().currentReachabilityStatus() == NotReachable {
                    viewController.showErrorAlert(String.localize("MSG_ERR_NETWORK_FAIL"))
                    failure?()
                    return
                }
            } else if let viewController = Navigator.shared.topContainer() as? UIViewController {
                if Reachability.shared().currentReachabilityStatus() == NotReachable {
                    viewController.showErrorAlert(String.localize("MSG_ERR_NETWORK_FAIL"))
                    failure?()
                    return
                }
            }
        }
        
        RunOnSocketThread {
        
            if message is IMUserMessage {
                let convKey =  (message as! IMUserMessage).convKey
                if let conv = self.conversationForKey(convKey), conv.isClosed() && conv.IAmCustomer() {
                    // send conv start again
                    if let convStart = conv.restartMessage() {
                        self.sendMessage(convStart, completion: { (ack) in
                            if let convKey = ack.data {
                                (message as! IMUserMessage).convKey = convKey
                                self.sendMessage(message, completion: completion)
                            }
                        })
                    }
                    return
                }
            }
            
            if let userKey = self.userKey {
                
                message.senderUserKey = userKey
                
                if let module = message.toChatModel() {
                    CacheManager.sharedManager.cacheObject(module.cacheableObject())
                    self.updateLastChatMessages(module)
                }
                
                if self.isStarted && self.isConnected {
                    
                    if message is IMUserMessage {
                        let convKey =  (message as! IMUserMessage).convKey
                        self.resetHiddenConv(convKey)
                        self.updateConversationUnreadCount()
                    }
                    
                    if message.readyToSend {
                    
                        if let jsonString = message.JSONString() {
                            Log.debug("IM Send : " + jsonString)
                            self.webSocketClient?.send(jsonString)
                        } else {
                            Log.debug("Fail to decode the object to json.")
                        }
                        
                        self.requestPool[message.correlationKey] = (message, completion)
                        
                    } else {
                        
                        message.prepare(
                            completion: { (message) in
                                
                                message.readyToSend = true
                                
                                self.sendMessage(
                                    message,
                                    completion: completion,
                                    failure: failure
                                )
                            },
                            failure: {
                                failure?()
                            }
                        )
                        
                    }
                    
                } else {
                    failure?()
                    Log.debug("Service is not ready to send. (isStarted: \(self.isStarted), isConnected: \(self.isConnected))")
                }
                
            } else {
                failure?()
                Log.debug("UserKey is nil")
            }
            
        }
    }
    
    func sendMessage(_ message: IMMessage) {
        sendMessage(message, completion: nil)
    }
    
    private func updateLastChatMessages(_ chatModel: ChatModel?) {
        if let model = chatModel, let convKey = model.convKey, model.messageContent != nil && model.agentOnly == false {
            convListMap[convKey]?.timestamp = model.timeDate
            sortConvsationList()
            self.lastMessages[convKey] = model
        }
    }
    
    func lastMessageForConversation(_ conv: Conv) -> ChatModel? {
        var messages =  [ChatModel]()
        if let model = self.lastMessages[conv.convKey] {
            messages.append(model)
        }
        messages.sort {$0.timestamp < $1.timestamp}
        return messages.last
    }
    
    func clearConversationUnreadCount(_ incomingConv: Conv?) {
        if let conv = incomingConv, let unreadCount = conv.msgNotReadCount, unreadCount > 0 {
            conv.msgNotReadCount = 0
            self.updateConversationUnreadCount()
        }
    }
    
    func updateConversationUnreadCount(_ incomingConv: Conv? = nil, delta: Int = 0) {
        
        if let conv = incomingConv, conv.msgNotReadCount != nil {
            conv.msgNotReadCount! += delta
            
            // safety guard
            if conv.msgNotReadCount < 0 {
                conv.msgNotReadCount = 0
            }
        }
        
        var total = 0
        for conv in convList {
            var isAppendData = true
            
            var numberFilterSelected = 0
            
            for value in IMFilterCache.sharedInstance.filterChat() {
                if value {
                    numberFilterSelected += 1
                }
            }
            
            if numberFilterSelected == 0 {
                isAppendData = checkAppendData(conv)
            }

            if isAppendData {
                total += conv.msgNotReadCount ?? 0
            }
        }
        
        numberOfUnread = total
    }
    
    func msgReadMessage(_ model: ChatModel) {
        
        RunOnSocketThread {
            
            if model.messageId != nil && model.isUnread() {
                
                model.read()
                
                guard let convKey = model.convKey, let messageKey = model.messageId else {
                    return
                }
                
                if let conv = self.convListMap[convKey] {
                    self.sendMessage(
                        IMMsgReadMessage(messageKey: messageKey, myUserRole: conv.myUserRole)
                    )
                    self.updateConversationUnreadCount(conv, delta: -1)
                    PostNotification(IMDidUpdateConversationList, object: nil)
                }
                
            }
        }
        
    }
    
    func convReadMessage(_ convKey: String?) {
        
        RunOnSocketThread {
            
            if let convkey = convKey {
                if let conv = self.convListMap[convkey] {
                    self.sendMessage(
                        IMConvReadMessage(convKey: convkey)
                    )
                    self.clearConversationUnreadCount(conv)
                    PostNotification(IMDidUpdateConversationList, object: nil)
                }
            }
        }
        
    }
    
    func readConvLocal(_ convKey: String?) {
        RunOnSocketThread {
            
            if let convkey = convKey {
                if let conv = self.convListMap[convkey] {
                    self.clearConversationUnreadCount(conv)
                    PostNotification(IMDidUpdateConversationList, object: nil)
                }
            }
        }
    }
    
    func conversationForKey(_ convKey: String) -> Conv? {
        return convListMap[convKey]
    }
    
    func listConvFilter(_ filterValues: [Bool]) -> [IMLandingConversationData] {
        
        var retArray1 = [IMLandingConversationData]()
        
        var numberFilterSelected = 0
        
        for value in filterValues {
            if value {
                numberFilterSelected += 1
            }
        }
        
        var isFullList = false
        if numberFilterSelected == 0 || numberFilterSelected == 6 {
            isFullList = true
        }
        
        convLoop: for conv in convList {
            
            if isFullList {
                var isAppendData = true
                if numberFilterSelected == 0 {
                    //filter closed/hidden conv
                    isAppendData = checkAppendData(conv)
                }
                else {
                    isAppendData = !(self.lastMessageForConversation(conv) == nil && conv.senderUserKey != userKey && (conv.isInternalChat() || conv.isFriendChat()) && !conv.isGroupChat()) && !(conv.IAmCustomer() && conv.isClosed())
                }
                
                if isAppendData {
                    let data = IMLandingConversationData(conv: conv)
                    retArray1.append(data)
                    continue convLoop
                }
            }
            
            for (index, value) in filterValues.enumerated() {
                
                if !value {
                    continue
                }
                
                if ((index == 0 && conv.isFriendChat()) || ((index == 1 && conv.isCustomerChat()) && !(conv.IAmCustomer() && conv.isClosed())) || (index == 2 && conv.isInternalChat())) &&
                    !(self.lastMessageForConversation(conv) == nil && conv.senderUserKey != userKey && (conv.isInternalChat() || conv.isFriendChat()) && !conv.isGroupChat())
                {
                    let data = IMLandingConversationData(conv: conv)
                    retArray1.append(data)
                    continue convLoop
                }
            }
            
        }
        
        if !isFullList {
            if !filterValues[3] && !filterValues[4] && !filterValues[5] {
                return retArray1
            }
            var retArray2 = [IMLandingConversationData]()
            convLoop: for convData in retArray1 {
                for (index, value) in filterValues.enumerated() {
                    if !value {
                        continue
                    }

                    if (index == 3 && convData.conv.isChatting()) ||
                        (index == 4 && convData.conv.isClosed()) ||
                        (index == 5 && convData.conv.isFollowUp())
                    {
                        retArray2.append(convData)
                        continue convLoop
                    }
                
                }
            }
            
            return retArray2
        }
        
        return retArray1
    }
    
    func removeConv(_ conv: Conv) {
        for aConv in _convList {
            if aConv.convKey == conv.convKey {
                _convList.remove(aConv)
                return
            }
        }
    }
    
    func checkAppendData(_ conv: Conv) -> Bool {
        //filter closed/hidden conv
        if let key = userKey {
            
            let filterClosed = { (conv: Conv) -> Bool in
                return !conv.isClosed() || conv.IAmCustomer()
            }
            
            let filterHidden = { (conv: Conv, userKey: String) -> Bool in
                return !conv.userListHidden.contains(userKey)
            }
            
            let filterNoMsgChat = { (conv: Conv, userKey: String) -> Bool in
                return self.lastMessageForConversation(conv) == nil && conv.senderUserKey != userKey && (conv.isInternalChat() || conv.isFriendChat()) && !conv.isGroupChat()
            }
            
            if !(filterHidden(conv, key) && filterClosed(conv)) || filterNoMsgChat(conv, key) {
                return false
            }
        }
        
        return true
    }
}
