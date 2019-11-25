//
//  AnalyticsActionRecord.swift
//  merchant-ios
//
//  Created by Stephen Yuen on 21/7/2016.
//  Copyright © 2016 WWE & CO. All rights reserved.
//

import Foundation

class AnalyticsActionRecord: AnalyticsRecord {
    
    enum ActionTriggerType: String {
        case Unknown = ""
        case Show = "Show"
        case Hide = "Hide"
        case Swipe = "Swipe"
        case Input = "Input"
        case Tap = "Tap"
        case Drag = "Drag"
        case Slide = "Slide"
        case Submit = "Submit"
        case Send = "Send"
        case Copy = "Copy"
        case Scan = "Scan"
        case Apply = "Apply"
        case Add = "Add"
        case Refresh = "Refresh"
        case Edit = "Edit"
        case Logout = "Logout"
        case System = "System"
    }
    
    enum ActionElement: String {
        case Unknown = ""
        case Brand = "Brand"
        case Button = "Button"
        case Channel = "Channel"
        case ChatCustomer = "Chat-Customer"
        case ChatFriend = "Chat-Friend"
        case ChatInternal = "Chat-Internal"
        case Color = "Color"
        case Comment = "Comment"
        case Curator = "Curator"
        case GetInvitationCode = "GetInvitationCode"
        case HeroBanner = "HeroBanner"
        case HeroImage = "HeroImage"
        case InvitationCode = "InvitationCode"
        case Link = "Link"
        case Merchant = "Merchant"
        case MobileLogin = "MobileLogin"
        case Page = "Page"
        case Product = "Product"
        case PopupBanner = "PopupBanner"
        case Redirection = "Redirection"
        case Size = "Size"
        case Table = "Table"
        case Text = "Text"
        case User = "User"
        case View = "View"
        case WeChatLogin = "WeChatLogin"
        case Banner = "Banner"
        case TileBanner = "TileBanner"
        case Post = "Post"
        case Badge = "Badge"
        case PriceRangeFrom = "PriceRange-From"
        case PriceRangeTo = "PriceRange-To"
        case ImageTemplate = "ImageTemplate"
        case Image = "Image"
        case MerchantUser = "MerchantUser"
        case MessagePreDefined = "Message-PreDefined"
        case Voice = "Voice"
        case Message = "Message"
        case PhotoLibrary = "Photo-Library"
        case PhotoCamera = "Photo-Camera"
        case Coupon = "Coupon"
        case ContentPage = "ContentPage"
        case Category = "Category"
        case ExpandedView = "ExpandedView"
        case Article = "Article"
        case Collection = "Collection"
        case SearchTermHistory = "SearchTerm-History"
        case SearchTermTrend = "SearchTerm-Trend"
        case SearchTerm = "SearchTerm"
        case ShippingAddress = "ShippingAddress"
        case CouponMerchant = "Coupon-Merchant"
        case CouponMyMM = "Coupon-MyMM"
        case UserAddress = "UserAddress"
        case ProductSku = "Product-Sku"
        case Qty = "Qty"
        case ParentOrder = "ParentOrder"
        case MerchantOrder = "MerchantOrder"
        case URL = "URL"
        case ShortcutBanner = "ShortcutBanner"
        case ProductBanner = "ProductBanner"
        case InAppNotification = "InAppNotification"
        case Hide = "Hide"
        case Review = "Review"
        case Permission = "Permission"
        case Submit = "Submit"
        case IncentiveReferral = "IncentiveReferral"
        case PDP = "PDP"
        case MPP = "MPP"
        case Topic = "Topic"
        case Add = "Add"
        case HistoryTopic = "HistoryTopic"
        case HotTopic = "HotTopic"
        case Filters = "Filters"
        case Beautifcation = "Beautifcation"
        case MerchantBanner = "MerchantBanner"
        case App = "App"
        case Avatar = "Avatar"
        case CMS = "CMS"
    }
    
    var actionKey = ""                                  // GUID
    var actionTrigger: ActionTriggerType = .Unknown     // Click, Show, Hide, Swipe
    var impressionKey = ""                              // GUID
    var authorRef = ""                                  // GUID or UserKey
    var sourceRef = ""                                  // GUID or string
    var sourceType: ActionElement = .Unknown            // Button, Post
    var sourceTypeString = ""
    var targetRef = ""                                  // String(2048) (e.g. Could be GUID or Free text for Generic Type)
    var targetType: ActionElement = .Unknown            // Generic, Sku
    var targetTypeString = ""
    var referrerRef = ""                                // GUID or UserKey or Link definition
    var referrerType = ""                               // Curator, User, Link
    var viewKey = ""                                    // GUID
    var VID = ""
    
    override init() {
        super.init()
        type = "a"
    }
    
    override func build() -> [String : Any] {
        let parameters = [
            "ak" : actionKey,
            "at" : actionTrigger.rawValue,
            "ar" : authorRef,
            "ik" : impressionKey,
            "sk" : sessionKey,
            "sr" : sourceRef,
            "st" : sourceTypeString.isEmpty ? sourceType.rawValue : sourceTypeString,
            "tr" : targetRef,
            "tt" : targetTypeString.isEmpty ? targetType.rawValue : targetTypeString,
            "ts" : Constants.DateFormatter.getFormatter(.dateAnalytics).string(from: timestamp),
            "rr" : referrerRef,
            "rt" : referrerType,
            "ty" : type,
            "vk" : viewKey,
            "vid": VID
        ]
        
        return parameters
    }
}
