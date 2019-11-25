//
//  TSChatViewController+HandleData.swift
//  TSWeChat
//
//  Created by Hilen on 1/29/16.
//  Copyright © 2016 Hilen. All rights reserved.
//

import Foundation

// MARK: - @extension TSChatViewController
extension TSChatViewController {
    /**
     发送文字
     */
    
    //获取聊天列表数据
    func fetchHistory(_ completion: ((_ request: IMMsgListRequestMessage, _ response: IMMsgListResponseMessage?) -> Void)?){
        if let conversation = self.conv {
            let message = IMMsgListRequestMessage(
                convKey: conversation.convKey,
                myUserRole: conversation.myUserRole
            )
            WebSocketManager.sharedInstance().sendMessage(
                message,
                completion: { ack in
                    completion?(
                        message,
                        ack.associatedObject as? IMMsgListResponseMessage
                    )
                }
            )
            
        }
    }
    
    func fetchMoreHistory(_ completion: ((_ request: IMMsgListRequestMessage, _ response: IMMsgListResponseMessage?) -> Void)?) {
        
        var message: ChatModel?
        for chat in self.itemDataSouce {
            if chat.messageContentType != .LoadMore && chat.messageContentType != .Time {
                message = chat
                break
            }
        }
        
        if let conversation = self.conv,
            let oldestMessage = message {
        
            let pageStart = oldestMessage.timeDate
            let message = IMMsgListRequestMessage(
                convKey: conversation.convKey,
                myUserRole: conversation.myUserRole,
                pageStart: pageStart
            )
            
            WebSocketManager.sharedInstance().sendMessage(
                message,
                completion: { ack in
                    completion?(
                        message,
                        ack.associatedObject as? IMMsgListResponseMessage
                    )
                }
            )
            
        }
    }
    
    func chatSendText() {
        dispatch_async_safely_to_main_queue({[weak self] in
            guard let strongSelf = self else {
                return
            }
            
            let textView : UITextView!
            
            if strongSelf.chatCommentActionBarView.isHidden == true {
                textView = strongSelf.chatActionBarView.inputTextView
            } else  {
                textView = strongSelf.chatCommentActionBarView.inputTextView
            }
            
            guard textView.text.length < 1000 else {
                return
            }
            
            guard textView.text.trimmingCharacters(in: CharacterSet.whitespacesAndNewlines).length > 0 else{
                return
            }
            
            
            if strongSelf.chatCommentActionBarView.isHidden == true {
                if let string = strongSelf.chatActionBarView.inputTextView.text {
                    self?.sendText(string, myUserRole: self?.conv?.myUserRole)
                }
            } else  {
                let string = strongSelf.chatCommentActionBarView.inputTextView.text
                let commentModel = CommentModel()
                commentModel.comment = string
                commentModel.status = CommentStatus.Normal
                commentModel.merchantId = strongSelf.conv?.myMerchantObject()?.merchantId
                
                let chatModel = ChatModel(commentModel: commentModel)
                strongSelf.forwardChatModel = chatModel
                
                var targetType: AnalyticsActionRecord.ActionElement = .ChatCustomer
                if let conv = strongSelf.conv {
                    if conv.isFriendChat() {
                        targetType = .ChatFriend
                    } else if conv.isInternalChat() {
                        targetType = .ChatInternal
                    }
                }
                // Action tag
                strongSelf.view.analyticsViewKey = strongSelf.analyticsViewRecord.viewKey
                strongSelf.view.recordAction(
                    .Send,
                    sourceRef: chatModel.messageId,
                    sourceType: .Comment,
                    targetRef: strongSelf.conv?.convKey,
                    targetType: targetType
                )
                
                strongSelf.forwardPendingMessage()
            }
            
            textView.text = ""
            
            if strongSelf.chatCommentActionBarView.isHidden {
                strongSelf.chatActionBarView.sendButton.isHidden = true
                strongSelf.chatActionBarView.shareButton.isHidden = false
                
                textView.snp.remakeConstraints { [weak self] (make) in
                    guard let strongSelf = self else { return }
                    
                    make.left.equalTo(strongSelf.chatActionBarView.containerView.snp.left).offset(57)
                    make.top.equalTo(strongSelf.chatActionBarView.containerView.snp.top).offset(7)
                    make.right.equalTo(strongSelf.chatActionBarView.containerView.snp.right).offset(strongSelf.textInputOffset ?? -48)
                    make.height.equalTo(strongSelf.chatActionBarView.containerView.snp.height).offset(-14).priority(.medium)
                }
            } else  {
                strongSelf.chatCommentActionBarView.sendButton.isHidden = true
                strongSelf.chatCommentActionBarView.shareButton.isHidden = false
                
                textView.snp.remakeConstraints { [weak self] (make) in
                    guard let strongSelf = self else { return }
                    
                    make.left.equalTo(strongSelf.chatActionBarView.containerView.snp.left).offset(5)
                    make.top.equalTo(strongSelf.chatActionBarView.containerView.snp.top).offset(7)
                    make.right.equalTo(strongSelf.chatActionBarView.containerView.snp.right).offset(-48)
                    make.height.equalTo(strongSelf.chatActionBarView.containerView.snp.height).offset(-14).priority(.medium)
                }
            }
        })
    }
    
    func sendMasterCoupon(_ model: ChatModel) {
        let chatModel = model
        
        if let conv = self.conv, let userRole = self.conv?.myUserRole {
            let message = IMMasterCouponMessage(
                convKey: conv.convKey,
                myUserRole: userRole,
                merchantId: String(chatModel.merchantId)
            )
            WebSocketManager.sharedInstance().sendMessage(message)
        }
        
        if self.itemDataSouce.count > 0 {
            let previousChat = self.itemDataSouce[self.itemDataSouce.count - 1]
            if chatModel.shouldDisplayTimstampBetween(previousChat) {
                self.itemDataSouce.insert(ChatModel(timestamp: chatModel.timestamp!), at: self.itemDataSouce.count)
            }
        } else {
            self.itemDataSouce.insert(ChatModel(timestamp: chatModel.timestamp!), at: self.itemDataSouce.count)
        }
        
//        self.itemDataSouce.append(chatModel)
        self.listTableView.reloadData {
            self.listTableView.scrollBottomWithoutFlashing()
        }

        
        
        

    }
    
    func sendText(_ string: String, myUserRole: UserRole?) {
        let chat = ChatModel(text: string)
        chat.chatSendId = Context.getUserKey()
        
        var targetType:  AnalyticsActionRecord.ActionElement = .ChatCustomer
        if let conv = self.conv {
            if  conv.isFriendChat() {
                targetType = .ChatFriend
            } else if conv.isInternalChat() {
                targetType = .ChatInternal
            }
            // Action tag
            self.view.analyticsViewKey = self.analyticsViewRecord.viewKey
            self.view.recordAction(
                .Send,
                sourceRef: chat.messageId,
                sourceType: .Message,
                targetRef: conv.convKey,
                targetType: targetType
            )
        }
        
        if let me = conv?.me {
            chat.chatSenderProfileKey = me.profileImage
        }
        if self.itemDataSouce.count > 0 {
            let previousChat = self.itemDataSouce[self.itemDataSouce.count - 1]
            if chat.shouldDisplayTimstampBetween(previousChat) {
                self.itemDataSouce.insert(ChatModel(timestamp: chat.timestamp!), at: self.itemDataSouce.count)
                let insertIndexPath = IndexPath(row: self.itemDataSouce.count - 1, section: 0)
                self.listTableView.insertRowsAtBottom([insertIndexPath])
            }
        } else {
            self.itemDataSouce.insert(ChatModel(timestamp: chat.timestamp!), at: self.itemDataSouce.count)
            let insertIndexPath = IndexPath(row: self.itemDataSouce.count - 1, section: 0)
            self.listTableView.insertRowsAtBottom([insertIndexPath])
        }
        self.itemDataSouce.append(chat)
        let insertIndexPath = IndexPath(row: self.itemDataSouce.count - 1, section: 0)
        self.listTableView.insertRowsAtBottom([insertIndexPath])
        self.sendMessageToSocket(chat, myUserRole: myUserRole)
    }
    
    func sendMessageToSocket(_ chat: ChatModel, myUserRole: UserRole?){
        if let content = chat.messageContent, let conv = self.conv, let userRole = myUserRole {
            
            let message = IMTextMessage(
                text: content,
                convKey: conv.convKey,
                myUserRole: userRole
            )
            chat.correlationKey = message.correlationKey
            
            WebSocketManager.sharedInstance().sendMessage(message)
        } else {
            ErrorLogManager.sharedManager.recordNonFatalError(withException: .NullPointer)
        }
    }
    
    func sendConversationClose() {
        if let conv = self.conv {
            WebSocketManager.sharedInstance().sendMessage(
                IMConvCloseMessage(
                    convKey: conv.convKey,
                    myUserRole: conv.myUserRole
                )
            )
        }  else {
            ErrorLogManager.sharedManager.recordNonFatalError(withException: .NullPointer)
        }
    }
    
    /**
     发送声音
     */
    func chatSendVoice(_ audioModel: ChatAudioModel) {
        dispatch_async_safely_to_main_queue({[weak self] in
            guard let strongSelf = self else {
                return
            }
            
            var targetType:  AnalyticsActionRecord.ActionElement = .ChatCustomer
            if let conv = strongSelf.conv {
                if  conv.isFriendChat() {
                    targetType = .ChatFriend
                } else if conv.isInternalChat() {
                    targetType = .ChatInternal
                }
                // Action tag
                strongSelf.view.analyticsViewKey = strongSelf.analyticsViewRecord.viewKey
                strongSelf.view.recordAction(
                    .Send,
                    sourceRef: audioModel.audioId,
                    sourceType: .Voice,
                    targetRef: conv.convKey,
                    targetType: targetType
                )
            }
            
            let model = ChatModel(audioModel: audioModel)

            if let me = strongSelf.conv?.me {
                model.chatSenderProfileKey = me.profileImage
            }
            if strongSelf.itemDataSouce.count > 0 {
                let previousChat = strongSelf.itemDataSouce[strongSelf.itemDataSouce.count - 1]
                if model.shouldDisplayTimstampBetween(previousChat) {
                    strongSelf.itemDataSouce.insert(ChatModel(timestamp: model.timestamp!), at: strongSelf.itemDataSouce.count)
                    let insertIndexPath = IndexPath(row: strongSelf.itemDataSouce.count - 1, section: 0)
                    strongSelf.listTableView.insertRowsAtBottom([insertIndexPath])
                }
            } else {
                strongSelf.itemDataSouce.insert(ChatModel(timestamp: model.timestamp!), at: strongSelf.itemDataSouce.count)
                let insertIndexPath = IndexPath(row: strongSelf.itemDataSouce.count - 1, section: 0)
                strongSelf.listTableView.insertRowsAtBottom([insertIndexPath])
            }
            
            strongSelf.itemDataSouce.append(model)
            let insertIndexPath = IndexPath(row: strongSelf.itemDataSouce.count - 1, section: 0)
            strongSelf.listTableView.insertRowsAtBottom([insertIndexPath])
            
            if let conv = strongSelf.conv, let localStoreName = audioModel.keyHash {
                
                model.convKey = conv.convKey
                
                let message = IMAudioMessage(
                    localStoreName: localStoreName,
                    duration: model.audioDuration,
                    convKey: conv.convKey,
                    myUserRole: conv.myUserRole
                )
                
                model.correlationKey = message.correlationKey
                
                WebSocketManager.sharedInstance().sendMessage(message)
                
            }
            
        })
    }

    /**
     发送图片
     */
    func chatSendImage(_ imageModel: ChatImageModel, forwardMode: Bool = false) {
        dispatch_async_safely_to_main_queue({[weak self] in
            guard let strongSelf = self else {
                return
            }
            let model = ChatModel(imageModel: imageModel, forwardMode: forwardMode)
            model.chatSendId = Context.getUserKey()
            if let me = strongSelf.conv?.me {
                model.chatSenderProfileKey = me.profileImage
            }
            if strongSelf.itemDataSouce.count > 0 {
                let previousChat = strongSelf.itemDataSouce[strongSelf.itemDataSouce.count - 1]
                if model.shouldDisplayTimstampBetween(previousChat) {
                    strongSelf.itemDataSouce.append(ChatModel(timestamp: model.timestamp!))
                    let insertIndexPath = IndexPath(row: strongSelf.itemDataSouce.count - 1, section: 0)
                    strongSelf.listTableView.insertRowsAtBottom([insertIndexPath])
                }
            } else {
                strongSelf.itemDataSouce.append(ChatModel(timestamp: model.timestamp!))
                let insertIndexPath = IndexPath(row: strongSelf.itemDataSouce.count - 1, section: 0)
                strongSelf.listTableView.insertRowsAtBottom([insertIndexPath])
            }
            strongSelf.itemDataSouce.append(model)
            if model.messageContentType == MessageContentType.Image {
                model.tag = strongSelf.imageDataSouce.count
                strongSelf.imageDataSouce.append(model)
            }
            let insertIndexPath = IndexPath(row: strongSelf.itemDataSouce.count - 1, section: 0)
            strongSelf.listTableView.insertRowsAtBottom([insertIndexPath])
            
            if let conv = strongSelf.conv, let image = imageModel.image, let localStoreName = imageModel.localStoreName {
                
                model.convKey = conv.convKey
                
                let message = IMImageMessage(
                    localStoreName: localStoreName,
                    width: image.size.width,
                    height: image.size.height,
                    convKey: conv.convKey,
                    myUserRole: conv.myUserRole
                )
                
                model.correlationKey = message.correlationKey
                
                WebSocketManager.sharedInstance().sendMessage(message)
            }
            
        })
    }
    
    func sendShareModel<T : Sharable>(_ model: T, forwardMode: Bool = false) {
        var chatModel: ChatModel
        let wsManager = WebSocketManager.sharedInstance()
        
        switch model {
        case is ProductModel:
            chatModel = ChatModel(productModel: model as! ProductModel, forwardMode: forwardMode)
            chatModel.cellHeight = CGFloat(440)
            
            let product = model as! ProductModel
            if let sku = product.sku, let conv = self.conv {
                if forwardMode {
                    let message = IMForwardProductMessage(
                        skuId: "\(sku.skuId)",
                        convKey: conv.convKey,
                        myUserRole: conv.myUserRole
                    )
                    chatModel.correlationKey = message.correlationKey
                    wsManager.sendMessage(message)
                }
                else {
                    let message = IMSkuMessage(
                        skuId: "\(sku.skuId)",
                        convKey: conv.convKey,
                        myUserRole: conv.myUserRole
                    )
                    chatModel.correlationKey = message.correlationKey
                    wsManager.sendMessage(message)
                }
            }

        case is ChatAudioModel:
            
            chatModel = ChatModel(audioModel: model as! ChatAudioModel)
            
            if let convKey = conv?.convKey {
                chatModel.convKey =  convKey
            }
            
            if let message = chatModel.requestMessage(conv?.myUserRole) as? IMAudioMessage {
                message.readyToSend = true
                wsManager.sendMessage(message)
            }
            
        case is OrderModel:
            chatModel = ChatModel(orderModel: model as! OrderModel)

            let orderModel = model as! OrderModel

            if let conv = self.conv, let orderNumber = orderModel.orderNumber {
                let message = IMOrderMessage(
                    orderKey: orderNumber,
                    orderReferenceNumber: orderModel.orderReferenceNumber,
                    orderShipmentKey: orderModel.orderShipmentKey,
                    orderType: orderModel.orderType,
                    convKey: conv.convKey,
                    myUserRole: conv.myUserRole
                )
                chatModel.correlationKey = message.correlationKey
                wsManager.sendMessage(message)
            }

        case is CommentModel:
            chatModel = ChatModel(commentModel: model as! CommentModel, forwardMode: forwardMode)
            if let conv = self.conv, let comment = (model as! CommentModel).comment, let merchantId = (model as! CommentModel).merchantId {
                let message = IMCommentMessage(
                    comment: comment,
                    merchantId: merchantId,
                    convKey: conv.convKey,
                    status: (model as! CommentModel).status,
                    myUserRole: conv.myUserRole
                )
                chatModel.correlationKey = message.correlationKey
                wsManager.sendMessage(message)
            }
        default:
            chatModel = ChatModel(model: model)
            
            if let conv = self.conv {
                let message = IMUserMessage(
                    sharable : model,
                    convKey: conv.convKey
                )
                chatModel.correlationKey = message.correlationKey
                wsManager.sendMessage(message)
            }
        }
        
        if let me = conv?.me {
            chatModel.chatSenderProfileKey = me.profileImage
        }
        
        if self.itemDataSouce.count > 0 {
            let previousChat = self.itemDataSouce[self.itemDataSouce.count - 1]
            if chatModel.shouldDisplayTimstampBetween(previousChat) {
                self.itemDataSouce.insert(ChatModel(timestamp: chatModel.timestamp!), at: self.itemDataSouce.count)
            }
        } else {
            self.itemDataSouce.insert(ChatModel(timestamp: chatModel.timestamp!), at: self.itemDataSouce.count)
        }
        
        self.itemDataSouce.append(chatModel)
        self.listTableView.reloadData { 
            self.listTableView.scrollBottomWithoutFlashing()
        }
        
    }
    
}
