//
//  IMLandingConversationData.swift
//  merchant-ios
//
//  Created by Alan YU on 19/5/2016.
//  Copyright © 2016 WWE & CO. All rights reserved.
//

import Foundation

class IMLandingConversationData {
    
    fileprivate(set) var conv: Conv
    
    var presenter: User? {
        get {
            return conv.presenter
        }
    }
    
    var profileImage: String? {
        get {
            if conv.isMyAgent() {
                return conv.merchantObject?.headerLogoImage
            }
            return presenter?.profileImage
        }
    }
    
    var profileImageCategory: ImageCategory {
        get {
            if conv.isMyAgent() {
                return .merchant
            }
            return .user
        }
    }
    
    var profileImageRounded: Bool {
        get {
            return !conv.isMyAgent()
        }
    }
    
    var userName: String? {
        get {
            if conv.isMyAgent() {
                return conv.merchantObject?.merchantName
            }
            return presenter?.displayName
        }
    }
    
    var isCurator: Bool {
        get {
            return presenter?.isCurator == 1
        }
    }
    
    var lastMessage: String? {
        get {
            return WebSocketManager.sharedInstance().lastMessageForConversation(conv)?.messageContent ?? ""
        }
    }
    
    var timestamp: Date {
        get {
            if let date = WebSocketManager.sharedInstance().lastMessageForConversation(conv)?.timeDate {
                return date
            }
            return conv.timestamp as Date
        }
    }
    
    init (conv: Conv) {
        self.conv = conv
    }
    
}
