//
//  Conv.swift
//  merchant-ios
//
//  Created by Koon Kit Chan on 16/3/2016.
//  Copyright © 2016 WWE & CO. All rights reserved.
//

import Foundation
import ObjectMapper

enum ConvState: String {
    case Unknown = "Unknown"
    case New = "New"
    case Agent = "Agent"
    case Customer = "Customer"
}

enum ConvStatus: String {
    case Unknown = "Unknown"
    case Open = "Open"
    case Closed = "Closed"
}

enum ConvType: String {
    case Unknown = "Unknown"
    case Customer = "Customer"
    case Internal = "Internal"
    case Private = "Private"
}

class Conv : IMSystemMessage, Equatable {
    
    var convType = ConvType.Unknown
    var convKey = ""
    var userList = [UserRole]()
    var userListHidden = [String]()
    var lastMessage: ChatModel?
    var msgNotReadCount: Int?
    var merchantId: Int?
    var senderMerchantId: Int?
    var queue = QueueType.Unknown
    var state = ConvState.Unknown
    var status = ConvStatus.Unknown
    var userListFlag = [String]()
    var timestampClosed = Date()
    var convName: String?
    var fromCache = false
    
    fileprivate(set) var merchantObject: Merchant?
    fileprivate(set) var MMObject: Merchant?
    fileprivate(set) var userObjectList = [UserRole]()
    fileprivate(set) var otherUserRoleList = [UserRole]()
    fileprivate(set) var otherMerchantUserRoleList = [UserRole]()
    fileprivate(set) var me: User?
    fileprivate(set) var myUserRole: UserRole?
    fileprivate(set) var merchantMap = [Int: Merchant]()
    fileprivate(set) var userRoleMap = [String: UserRole]()
    
    var presenter: User? {
        get {
            return otherUserRoleList.first?.userObj
        }
    }
    
    var presentMerchant: Merchant? {
        get {
            return otherUserRoleList.first?.merchantObj
        }
    }
    
    required convenience init?(map: Map) {
        self.init()
    }
    
    convenience init(convKey: String, userRole: UserRole? = nil) {
        self.init()
        self.convKey = convKey
        self.myUserRole = userRole
    }
    
    // Mappable
    override func mapping(map: Map) {
        super.mapping(map: map)
        
        convType            <-  (map["ConvType"], EnumTransform())
        convKey             <-  map["ConvKey"]
        userListFlag        <-  map["UserListFlag"]
        userList            <-  map["UserList"]
        userListHidden      <-  map["UserListHidden"]
        lastMessage         <-  map["MsgLast"]
        msgNotReadCount     <-  map["MsgNotReadCount"]
        merchantId          <-  map["MerchantId"]
        senderMerchantId    <-  map["SenderMerchantId"]
        timestamp           <-  (map["Timestamp"], IMDateTransform())
        timestampClosed     <-  (map["TimestampClosed"], IMDateTransform())
        queue               <-  (map["Queue"], EnumTransform())
        state               <-  (map["State"], EnumTransform())
        status              <-  (map["Status"], EnumTransform())
        convName            <-  map["ConvName"]
    }
    
    func updateUsers(_ me: User?, map: [String: User]) {
        
        userObjectList.removeAll()
        otherUserRoleList.removeAll()
        userRoleMap.removeAll()
        
        self.me = me
        self.myUserRole = nil
        
        for userRole in userList {
            if let userKey = userRole.userKey, let user = map[userKey] {
                if user.userKey != me?.userKey {
                    otherUserRoleList.append(userRole)
                } else {
                    self.myUserRole = userRole
                }
                userRole.userObj = user
                userObjectList.append(userRole)
                userRoleMap[user.userKey] = userRole
            }
        }
        
    }
    
    func loadMyUserRoleIfNeeded() -> UserRole? {
        if let role = self.myUserRole {
            return role
        }
        
        if userList.count > 0 {
            for userRole in userList {
                if Context.getUserKey() == userRole.userKey {
                    self.myUserRole = userRole
                    return userRole
                }
            }
        }
        return nil
    }
    
    func updateMerchants(_ map: [Int: Merchant]) {
        
        if let merchantId = self.merchantId, let merchant = map[merchantId] {
            merchantObject = merchant
            merchantMap[merchantId] = merchant
        } else if let merchantId = self.merchantId, merchantId == Constants.MMMerchantId {
            merchantObject = Merchant.MM()
            merchantMap[merchantId] = merchantObject
        }
        
        MMObject = nil
        
        for userRole in userList {
            
            if let merchantId = userRole.merchantId, merchantId == Constants.MMMerchantId {
                // MM is a virtual merchant
                MMObject = Merchant.MM()
                userRole.merchantObj = MMObject
                merchantMap[merchantId] = MMObject
            }
            
            if let merchantId = userRole.merchantId, let merchant = map[merchantId] {
                userRole.merchantObj = merchant
                merchantMap[merchantId] = merchant
            }
        }
        
    }
    
    func shouldVisibleForUser(_ userKey: String) -> Bool {
        return userList.contains(where: { $0.userKey == userKey }) && !userListHidden.contains(userKey)
    }
    
    func myMerchantObject() -> Merchant? {
        return myUserRole?.merchantObj
    }
    
    func isGroupChat() -> Bool {
        return userList.count > 2
    }
    
    func isMyClient() -> Bool {
        
        if let merchantId = self.merchantId, convType == .Customer {
            return !IAmCustomer() && Context.customerServiceMerchants().merchantIds().contains(merchantId)
        }
        
        return false
        
//        return !IAmCustomer() && (IAmAgent() || IAmMM())
    }
    
    func isMyAgent() -> Bool {
        return IAmCustomer()
    }
    
    func isFriendChat() -> Bool {
        return convType == .Private
    }
    
    func isCustomerChat() -> Bool {
        return convType == .Customer
    }
    
    func isInternalChat() -> Bool {
        return convType == .Internal
    }
    
    func isClosed() -> Bool {
        return status == .Closed
    }
    
    func isFollowUp() -> Bool {
        if let userKey = me?.userKey {
            return userListFlag.contains(userKey)
        }
        return false
    }
    
    func isOwner() -> Bool {
        if let myMerchantId = self.myMerchantObject()?.merchantId {
            return myMerchantId == self.merchantId
        }
        return false
    }
    
    func isChatting() -> Bool {
        return status != .Closed
    }
    
    func customer() -> User? {
        for user in userList {
            if user.merchantId == nil {
                return user.userObj
            }
        }
        return nil
    }
    
    func userForKey(_ userKey: String) -> User? {
        if let user = CacheManager.sharedManager.cachedUserForUserKey(userKey) {
            return user
        }
        return userRoleForKey(userKey)?.userObj
    }
    
    func merchantForId(_ merchantId: Int) -> Merchant? {
        return merchantMap[merchantId]
    }
    
    func userRoleForKey(_ userKey: String) -> UserRole? {
        return userRoleMap[userKey]
	}
	
	override func cacheableObject() -> IMConvCacheObject {
        return IMConvCacheObject(conv: self)
    }
    
    func shouldShowComment(_ msg: ChatModel) -> Bool {
        
        if msg.dataType == .TransferRedirect {
            if let stayOn = msg.stayOn {
                if IAmCustomer() || (IAmMM() && stayOn) {
                    return true
                }
            }
            return false
        }
        else if msg.dataType == .Comment || msg.dataType == .ForwardDescription || msg.dataType == .ForwardImage || msg.dataType == .ForwardProduct || msg.dataType == .TransferComment {
            if IAmCustomer() {
                return false
            } else {
                return true
            }
        }
        else {
            return true
        }
    }
    
    func IAmOwnerAgent() -> Bool {
        if let myUserRole = self.myUserRole {
            for role in userList {
                if let userKey = role.userKey, role.merchantId != nil {
                    return userKey == myUserRole.userKey
                }
            }
        }
        return false
    }
    
    func IAmMM() -> Bool {
        return myUserRole?.merchantObj?.isMM() == true
    }
    
    func IAmAgent() -> Bool {
        if let mid = merchantId, let myMerchantId = myUserRole?.merchantObj?.merchantId {
            return mid == myMerchantId
        }
        return false
    }
    
    func IAmCustomer() -> Bool {
        let userRole = self.loadMyUserRoleIfNeeded()
        if let role = userRole, convType == .Customer {
            return role.merchantId == nil
        }
        return false
    }
    
    func isAllowInviteGroupChat() -> Bool {
        return !self.IAmCustomer()
    }
    
    func isAllowLeaveChat() -> Bool {
        if isGroupChat() {
            if isFriendChat() || isInternalChat() {
                return true
            }
            else if isCustomerChat() {
                if IAmCustomer() {
                    return false
                }
                else if IAmMM() {
                    return true
                }
                else if IAmAgent() {
                    for userRole in otherUserRoleList {
                        if let merchantId = userRole.merchantId, merchantId == self.merchantId {
                            return true
                        }
                    }
                    return false
                }
            }
        }
        
        return false
    }
    
    func shouldStartNewConv() -> Bool {
        return !self.isCustomerChat() && !self.isGroupChat()
    }
    
    let UserLimitForPrivateThumbnail = 3
    let UserLimitForThumbnail = 2
    let DefaultImageKey = "Default"
    
    func isMMConv() -> Bool {
        return self.merchantId == Constants.MMMerchantId
    }
    
    func fetchThumbnail(_ completion: (([UIImage]) -> Void)?) {
        
        var urls = [URL]()
        let callback = { (images: [UIImage]) -> Void in
            completion?(images)
        }
        
        if convType == .Internal {
            
            let length = min(otherUserRoleList.count, UserLimitForThumbnail)
            
            for role in otherUserRoleList[0..<length] {
                if let profileImage = role.userObj?.profileImage {
                    urls.append(ImageURLFactory.URLSize128(profileImage, category: .user))
                }
            }
            
        } else if convType == .Customer {
            
            if IAmCustomer() {
                
                if merchantObject?.merchantId == Constants.MMMerchantId {
                    urls.append(URL(string: "MM://icon")!)
                } else {
                    if let headerLogoImage = merchantObject?.headerLogoImage {
                        urls.append(ImageURLFactory.URLSize128(headerLogoImage, category: .merchant))
                    }
                }
                
//                if !self.isMMConv() && self.MMObject?.MMImageIcon != nil/* && merchantId == self.merchantId*/ {
//                    urls.append(NSURL(string: "MM://icon")!)
//                }
                
            } else {
                
                if let profileImage = customer()?.profileImage {
                    urls.append(ImageURLFactory.URLSize128(profileImage, category: .user))
                }
                
                if let headerLogoImage = merchantObject?.headerLogoImage, headerLogoImage.length > 0 && self.IAmMM() {
                    urls.append(ImageURLFactory.URLSize128(headerLogoImage, category: .merchant))
                }
                
                if self.MMObject?.MMImageIconBlack != nil && self.IAmAgent() && !self.isMMConv() {
                    urls.append(URL(string: "MM://icon")!)
                }
            }
            
        } else {
            
            // Private chat
            
            var list = otherUserRoleList
            
            // thumbnail including me only if group chat
            if isGroupChat() {
                list = userList
            }
            
            let length = min(list.count, UserLimitForPrivateThumbnail)
            for role in list[0..<length] {
                if let profileImage = role.userObj?.profileImage {
                   urls.append(ImageURLFactory.URLSize128(profileImage, category: .user))
                }
            }
            
        }
        if urls.isEmpty {
            callback([])
        } else {
            Utils.fetchImages(
                urls,
                completion: callback
            )
        }
        
    }
    
    func chatTypeString() -> String {
        var chatType = "Chat-Customer"
        if self.isFriendChat() {
            chatType = "Chat-Friend"
        } else if self.isInternalChat() {
            chatType = "Chat-Internal"
        }
        return chatType
    }
    
    func combinedImageKey() -> String? {
        var imageKeys = [String]()
        
        if convType == .Internal {
            
            let length = min(otherUserRoleList.count, UserLimitForThumbnail)
            
            for role in otherUserRoleList[0..<length] {
                if let profileImage = role.userObj?.profileImage, !profileImage.isEmpty {
                    imageKeys.append(profileImage)
                } else {
                    imageKeys.append(DefaultImageKey)
                }
            }
            
        } else if convType == .Customer {
            
            if IAmCustomer() {
                
                if merchantObject?.merchantId == Constants.MMMerchantId {
                    imageKeys.append("MM://icon")
                } else {
                    if let headerLogoImage = merchantObject?.headerLogoImage {
                        imageKeys.append(headerLogoImage)
                    }
                }
                
//                if !self.isMMConv() && self.MMObject?.MMImageIcon != nil/* && merchantId == self.merchantId*/ {
//                    imageKeys.append("MM://icon")
//                }
                
            } else {
                
                if let profileImage = customer()?.profileImage, !profileImage.isEmpty {
                    imageKeys.append(profileImage)
                } else {
                    imageKeys.append(DefaultImageKey)
                }
                
                if let headerLogoImage = merchantObject?.headerLogoImage, headerLogoImage.length > 0 && self.IAmMM() {
                    imageKeys.append(headerLogoImage)
                }
                
                if self.MMObject?.MMImageIconBlack != nil && self.IAmAgent() && !self.isMMConv() {
                    imageKeys.append("MM://icon")
                }
                
            }
            
        } else {
            
            // Private chat
            
            var list = otherUserRoleList
            
            // thumbnail including me only if group chat
            if isGroupChat() {
                list = userList
            }
            
            let length = min(list.count, UserLimitForPrivateThumbnail)
            for role in list[0..<length] {
                if let profileImage = role.userObj?.profileImage, !profileImage.isEmpty {
                    imageKeys.append(profileImage)
                } else {
                    imageKeys.append(DefaultImageKey)
                }
            }
            
        }
        
        return imageKeys.joined(separator: "")
    }
    
    func restartMessage() -> IMConvStartToCSMessage? {
        if let myUserRole = self.myUserRole, let merchantId = self.merchantId {
            return IMConvStartToCSMessage(userList: [myUserRole],
                                          queue: queue,
                                          senderMerchantId: nil,
                                          merchantId: merchantId)
        }
        return nil
    }

    func addUserRole(_ userRoles: [UserRole]) {
        for userRole in userRoles {
            userList.append(userRole)
        }
    }
    
    func groupChatName() -> [NameModel]? {
        if let groupname = self.convName {
            return [NameModel(name: groupname)]
        }
        
        if IAmCustomer() {
            if !isGroupChat() {
                return [NameModel(name: merchantObject?.merchantName ?? "")]
            } else {
                var name = ""
                for userRole in otherUserRoleList {
                    if let merchantName = userRole.merchantObj?.merchantName, !name.contains(merchantName) {
                        name += merchantName + ", "
                    }
                }
                
                if !name.isEmpty {
                    let index = name.index(name.endIndex, offsetBy: -2)
                    name = String(name[..<index])
                }
                
                return [NameModel(name: name)]
            }
        }
        else {

            if isInternalChat() && presenter == nil {
                let merchantName = merchantObject?.merchantName ?? ""
                return [NameModel(name: QueueStatistics.queueText(queue) + "(\(merchantName))")]
            }

            var nameModelList = [NameModel]()
            for userRole in otherUserRoleList {
                var nameModel: NameModel!
                if let user = userRole.userObj {
                    nameModel = NameModel(name: user.displayName, isCurator: user.isCurator == 1 ? true : false)
                }
                
                if let merchant = userRole.merchantObj {
                    nameModel.merchantName = merchant.merchantName
                }
                nameModelList.append(nameModel)
            }
            
            return nameModelList
        }
    }
    
    func defaultGroupChatName() -> String {
        if let groupname = self.convName {
            return groupname
        }
        
        var userListString = Context.getUserProfile().displayName
        
        for userRole in self.otherUserRoleList {
            if let user = userRole.userObj {
                let displayName = ", " + user.displayName
                userListString += displayName
            }
        }
        
        return userListString
    }
}

func ==(lhs: Conv, rhs: Conv) -> Bool {
    return lhs.convKey == rhs.convKey
}


