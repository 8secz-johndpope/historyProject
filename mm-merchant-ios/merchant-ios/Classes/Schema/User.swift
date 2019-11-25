//
//  User.swift
//  merchant-ios
//
//  Created by Koon Kit Chan on 24/9/15.
//  Copyright © 2015 Koon Kit Chan. All rights reserved.
//

import RealmSwift
import ObjectMapper

class User: NSObject, Mappable {
    
    // Specify properties to ignore (Realm won't persist these)
    
    //  override static func ignoredProperties() -> [String] {
    //    return []
    //  }
    
    @objc dynamic var activationToken = ""
    @objc dynamic var coverAlternateImage = ""
    @objc dynamic var coverImage = ""
    @objc dynamic var cultureCode = ""
    @objc dynamic var dateOfBirth: Date?
    
    var _displayName: String = ""
    @objc dynamic var displayName: String {
        get {
            if let userAlias = CacheManager.sharedManager.aliasForKey(self.userKey) {
                if let aliasStr = userAlias.alias, !aliasStr.isEmpty {
                    return aliasStr
                }
            }
            return self._displayName
        }
        set {
            self._displayName = newValue
        }
    }
    @objc dynamic var email = ""
    @objc dynamic var firstName = ""
    @objc dynamic var followerCount = 0
    @objc dynamic var followingBrandCount = 0
    @objc dynamic var followingCuratorCount = 0
    @objc dynamic var followingMerchantCount = 0
    @objc dynamic var followingUserCount = 0
    @objc dynamic var friendCount = 0
    @objc dynamic var gender = ""
    @objc dynamic var geoCityId = 0
    @objc dynamic var geoCountryId = 0
    @objc dynamic var geoProvinceId = 0
    @objc dynamic var inventoryLocationId = 0
    @objc dynamic var isCurator = 0
    @objc dynamic var isFeatured = 0
    @objc dynamic var isMerchant = 0
    @objc dynamic var isMm = 0
    @objc dynamic var isPass = 0
    @objc dynamic var languageId = 1
    @objc dynamic var lastModified = Date()
    @objc dynamic var lastName = ""
    var merchant = Merchant()
    @objc dynamic var merchantCode = ""
    @objc dynamic var middleName = ""
    @objc dynamic var mobileCode = ""
    @objc dynamic var mobileNumber = ""
    @objc dynamic var profileAlternateImage = ""
    @objc dynamic var profileImage = ""
    @objc dynamic var pushLogout = 0
    @objc dynamic var statusID = 0
    @objc dynamic var statusNameInvariant = ""
    @objc dynamic var statusReasonCode = ""
    @objc dynamic var timeZoneId = 1
    @objc dynamic var userDescription = ""
    @objc dynamic var userKey = ""
    @objc dynamic var userName = ""
    @objc dynamic var userSecurityGroupArray = [0]
    var userSocialAccounts: [UserSocialAccount]?
    @objc dynamic var wishlistCount = 0
    @objc dynamic var cc = ""
    
    // Not found in latest return
    @objc dynamic var userTypeId = 1
    @objc dynamic var merchantId = 0
    @objc dynamic var userInventoryLocationArray = [0]
    @objc dynamic var password = ""
    @objc dynamic var passwordOld = ""
    @objc dynamic var count = 0
    @objc dynamic var postLikeId = 0
    
    var isSelected = false
    var isClicking = false
    @objc dynamic var friendStatus = ""
    @objc dynamic var followStatus = ""
    @objc dynamic var isFriendUser = false
    @objc dynamic var isFollowUser = false
    @objc dynamic var referralInviteCode = ""
    @objc dynamic var userReferralCount = 0
    @objc dynamic var postCount = 0
    @objc dynamic var shippedOrderCount = 0
    @objc dynamic var age = 0
    @objc dynamic var lastCreated = Date()

    // Vip card info
    var paymentTotal: Double = 0
    var loyaltyStatusId = 0
    
    //Custom
    var canDelete = true
    
    var isGuest = false
    
    var pendingUploadProfileImage : UIImage?
    var pendingUploadCoverImage : UIImage?

    var loyalty: Loyalty?
    var isLoading = false
    // MARK: Newly added for removing info in login api
    
    var formattedUserMerchantSecurityGroupArray : [MerchantRoles] {
        get {
            var merchantRoles = [MerchantRoles]()
            for (merchantId, roles) in userMerchantSecurityGroupArray as [String : Any]{
                let role = MerchantRoles()
                role.merchantId = Int(merchantId)
                role.roles = roles as? [Int] ?? []
                merchantRoles.append(role)
            }
            return merchantRoles
        }
    }
    
    var userMerchantSecurityGroupArray : [String: Any] = [:]
    var isMM = false
    var merchantsMap = [Int: Merchant]()
    var merchants = [Merchant]() {
        didSet {
            merchantsMap.removeAll()
            for merchant in merchants {
                merchantsMap[merchant.merchantId] = merchant
            }
        }
    }
    
    required convenience init?(map: Map) {
        self.init()
    }
    
    // Mappable
    func mapping(map: Map) {
        
        activationToken             <- map["ActivationToken"]
        coverAlternateImage			<- map["CoverAlternateImage"]
        coverImage                  <- map["CoverImage"]
        cultureCode                 <- map["CultureCode"]
        dateOfBirth                 <- (map["DateOfBirth"], DateTransformExtension(dateFormat: DateTransformExtension.DateFormatStyle.dateOnly))
        _displayName                <- map["DisplayName"]
        email                       <- map["Email"]
        firstName                   <- map["FirstName"]
        followerCount               <- map["FollowerCount"]
        followingBrandCount         <- map["FollowingBrandCount"]
        followingCuratorCount       <- map["FollowingCuratorCount"]
        followingMerchantCount      <- map["FollowingMerchantCount"]
        followingUserCount          <- map["FollowingUserCount"]
        friendCount                 <- map["FriendCount"]
        gender                      <- map["Gender"]
        geoCityId                   <- map["GeoCityId"]
        geoCountryId                <- map["GeoCountryId"]
        geoProvinceId               <- map["GeoProvinceId"]
        inventoryLocationId         <- map["InventoryLocationId"]
        isCurator                   <- map["IsCurator"]
        isFeatured                  <- map["IsFeatured"]
        isMerchant                  <- map["IsMerchant"]
        isMm                        <- map["IsMm"]
        isPass                      <- map["IsPass"]
        languageId                  <- map["LanguageId"]
        lastModified                <- (map["LastModified"], DateTransform())
        lastName                    <- map["LastName"]
        merchant                    <- map["Merchant"]
        merchantCode                <- map["MerchantCode"]
        middleName                  <- map["MiddleName"]
        mobileCode                  <- map["MobileCode"]
        mobileNumber                <- map["MobileNumber"]
        profileAlternateImage       <- map["ProfileAlternateImage"]
        profileImage                <- map["ProfileImage"]
        pushLogout                  <- map["PushLogout"]
        statusID                    <- map["StatusId"]
        statusNameInvariant         <- map["StatusNameInvariant"]
        statusReasonCode            <- map["StatusReasonCode"]
        timeZoneId                  <- map["TimeZoneId"]
        userDescription             <- map["UserDescription"]
        userKey                     <- map["UserKey"]
        userName                    <- map["UserName"]
        userSecurityGroupArray      <- map["UserSecurityGroupArray"]
        userSocialAccounts          <- map["UserSocialAccounts"]
        wishlistCount               <- map["WishlistCount"]
        cc                          <- map["cc"]
        
        // Not found in latest return
        userTypeId                  <- map["UserTypeId"]
        merchantId                  <- map["MerchantId"]
        userInventoryLocationArray  <- map["UserInventoryLocationArray"]
        password                    <- map["Password"]
        passwordOld                 <- map["PasswordOld"]
        count                       <- map["Count"]
        postLikeId                  <- map["PostLikeId"]
        referralInviteCode          <- map["ReferralInviteCode"]
        userReferralCount           <- map["UserReferralCount"]
        postCount                   <- map["PostCount"]
        shippedOrderCount           <- map["ShippedOrderCount"]
        age                         <- map["Age"]
        lastCreated                 <- (map["LastCreated"], DateTransformExtension(dateFormat: DateTransformExtension.DateFormatStyle.dateTimeSimple))
        
        
        // moved from token
        merchants                      <- map["Merchants"]
        userMerchantSecurityGroupArray <- map["UserMerchantSecurityGroupArray"]
        isMM        <- map["IsMm"]
        
        isGuest     <- map["isGuest"]
        
        paymentTotal    <- map["PaymentTotal"]
        loyaltyStatusId         <- map["LoyaltyStatusId"]
    }
    
//    override static func primaryKey() -> String? {
//        return "userKey"
//    }
//    
//    override static func ignoredProperties() -> [String] {
//        return ["userInventoryLocationArray", "userSecurityGroupArray", "password", "passwordOld", "merchant"]
//    }

    func cacheableObject() -> UserCacheObject {
        return UserCacheObject(user: self)
    }
    
    func isFullyInvitation() -> Bool{
        if self.shippedOrderCount > 0 && self.postCount > 0 && self.userReferralCount > 0{
            return true
        }
        return false
    }
    
    func getProfileImage() -> String{
        if self.userKey == Context.getUserKey() {
            let profileImage = Context.getUserProfile().profileImage
            if profileImage.length > 0 {
                return profileImage
            }
        }
        return self.profileImage
    }
	
	// MARK: - Check for Social Account login user type
	func isSocialNetworkAccount() -> Bool {
		return userName == userKey
	}

    func userTypeString() -> String{
        var type = "User"
        if isCurator == 1 {
            type = "Curator"
        }
        else if isMerchant == 1 {
            type = "MerchantUser"
        }
        return type
    }
    
    func targetProfilePageTypeString() -> String{
        var type = "UPP"
        if self.isCurator == 1{
            type = "CPP"
        }
        return type
    }
    
    
    // MARK: Moved from Token
    
    
    func customerServiceMerchants() -> CustomerServiceMerchants {
        var merchants = [Merchant]()
        
        if Context.IAmMMAgent() {
            merchants.insert(Merchant.MM(), at: 0)
        }
        
        for merchant in formattedUserMerchantSecurityGroupArray {
            for roleId  in merchant.roles {
                if let merchantId = merchant.merchantId, roleId == Constants.MMCSId || roleId == Constants.MerchantCSId {
                    if let merchant = merchantsMap[merchantId] {
                        merchants.append(merchant);
                    }
                    break;
                }
            }
        }
        return CustomerServiceMerchants(merchants: merchants)
    }
    
    static func guestUser() -> User {
        let guest = User()
        guest.isGuest = true
        guest.userKey = "GUEST-" + Utils.UUID()
        return guest
    }
    
}
