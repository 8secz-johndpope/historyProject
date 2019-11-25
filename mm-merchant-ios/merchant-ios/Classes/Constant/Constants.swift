//
//  Constants.swift
//  merchant-ios
//
//  Created by Koon Kit Chan on 22/9/15.
//  Copyright © 2015 Koon Kit Chan. All rights reserved.
//

import Foundation

import UIKit

struct Constants {
	
	static let AppID = "1142948294"
	static let AppStoreLink = "itms-apps://itunes.apple.com/app/id1142948294"
	
    static let FaviorIconSize = CGSize(width: 40, height: 40)
	static let MMMerchantId = 0
	static let MMCSId = 0
	static let MerchantCSId = 10
	static var AppVersion = Bundle.main.infoDictionary?["CFBundleShortVersionString"] as! String
	static var IsDeveloperMode = false
	static let MaxOrderReturnSubmissionAttempt = 3
	static let IMTimeout = TimeInterval(60)
    static let MaxImageSize = 1572864
    static let MaxImageWidth = 1000

	static let MagazineCoverList = "magazineCoverList"
    static let MagazineLandingKey = "960b14f7-7bf5-4b0a-a4a2-5e3350bb2692"
    
	static let weiboAppID = "3437161635"
	static let qqAppID = "1105436262"
    static let DefaultInvitationCode = "MYMM"
    static let MaxFreeShippingThreshold = 99999999
    static let MAX_USER_REQUEST = 10
    
	static let SNSFriendReferralEnabled = true
    static let SessionCookieDomains = [".mymm.cn", ".mymm.com"]
    static let CMSExpireInMin = 10
    
    struct Path {
        static let DeepLinkDomain = "wweco.com"
        static let DeepShareDomain = "mymm.com"
        static let DeepLinkURL = "https://\(DeepShareDomain)/"
        static let DeepShareWebURL = "https://\(DeepShareDomain)/"
        static let InviteLinkURL = "https://www.mymm.com/dl?inappreferral"
        
        static let TrustAnyCert = Platform.TrustAnyCert
        static let ignoreSSLDomains = Platform.IgnoreSSLDomains
        
        static let Domain = Platform.Domain
        static var Host = Platform.Host
        static var CDN = "https://" + Platform.CDNDomain + "/api"
        static let CDNDomain = Platform.CDNDomain
        
        static var WebSocketHost = Platform.WebSocketHost
        static let AnalyticsDomain = Platform.AnalyticsDomain
        
        static var AnalyticsHost = "https://" + AnalyticsDomain + "/track"
        
        static let ParseHost = "https://api.parse.com/1/classes/"
        static let CountryHost = "https://restcountries.eu/rest/v1/"
        static let ParseHeaders = [
            "X-Parse-Application-Id" : "tSF6abJ4ZwUM6pjpVhDF4poWYmxbPQQg7DbYh8GS",
            "X-Parse-REST-API-Key" : "jib3yX9B3E4WV6iViDL8kbBQWKQWEkB66juY5Fr1",
            "Content-Type" : "application/json"
        ]

    }

    
    struct ExclusiveLaunch {
        static let AvailableFrom = "2016-07-15" //"2016-10-15"
        static let AvailableTo = "2017-02-28"
        static let defaultExclusiveMode = true
        static let campaignKey = "1ebdf622-5944-11e6-9954-0017fa002e29"
    }
    
    struct Campaign {
        static let CampaignReferralKey = "a753b236-6755-4fe0-856e-d6f9cdb29111"
    }
    
    struct DeepShare {
        static let AppId = Platform.DeepShare.AppId
        static let AppScheme = "ds" + AppId
        static let enable = true
    }
    
    struct MagicWindow {
        static let AppId = Platform.MagicWindow.AppId
        static let MLinkKey = Platform.MagicWindow.MLinkKey
        static let enable = true
    }
    
    struct JPush {
        static let AppKey = Platform.JPush.AppKey
        static let Channel = "Publish channel"
        #if DEBUG
            static let IsProduction = false
        #else
            static let IsProduction = true
        #endif
    }
    
    struct Button {
        static let Radius = CGFloat(5)
        static let BorderWidth = CGFloat(1)
    }
    
    struct Segment {
        static let Height : CGFloat = 45
        static let TwoTabStartPercent = CGFloat(30)
        static let ThreeTabStartPercent = CGFloat(25)
        static let FourTabStartPercent = CGFloat(12.5)
        static let FiveTabStartPercent = CGFloat(10)
    }

    
    internal struct DateFormatter {
        static var formatters : [String: Foundation.DateFormatter] = [:]
        static func getFormatter(_ formatString: String, fixedOfficalTimeZone: Bool = false) -> Foundation.DateFormatter {
            if let formatter = formatters[formatString] {
                if fixedOfficalTimeZone { formatter.timeZone = TimeZone(identifier: "Asia/Shanghai") }
                return formatter
            }else {
                let formatter = Foundation.DateFormatter()
                formatter.dateFormat = formatString
                formatters[formatString] = formatter
                if fixedOfficalTimeZone { formatter.timeZone = TimeZone(identifier: "Asia/Shanghai") }
                return formatter
            }
        }
        static func getFormatter(_ format: DateTransformExtension.DateFormatStyle) -> Foundation.DateFormatter {
            return DateFormatter.getFormatter(format.rawValue, fixedOfficalTimeZone: (format == .dateAnalytics))
        }
        
    }
    
    
    struct ActionButton {
        static let Radius = CGFloat(5)
        static let BorderWidth = CGFloat(1)
        static let Height = CGFloat(26)
    }
    
    struct TextField {
        static let BorderWidth = CGFloat(1)
        static let LeftPaddingWidth = CGFloat(15)
        static let OverlayTag = Int(1001)
        static let ArrowTag = Int(1004)
    }
    
    struct TextView {
        static let OverlayTag = Int(1002)
    }
    
    struct Checkbox {
        static let Size = CGSize(width: 50, height: 50)
        static let TagCheckIcon = Int(1003)
    }
    
    struct Font {
        static let Size = CGFloat(16)
        static let Ultralight = "PingFangSC-Ultralight"
        static let Thin = "PingFangSC-Thin"
        static let Normal = "PingFangSC-Light"
        static let Bold = "PingFangSC-Medium"
        static let Semibold = "PingFangSC-Semibold"
        static let Regular = "PingFangSC-Regular"
    }
    
    struct iOS8Font {
        static let Size = CGFloat(16)
        static let Normal = UIFont.systemFont(ofSize: 16).fontName
        static let Bold = UIFont.boldSystemFont(ofSize: 16).fontName
    }
    
    struct Value {
        static let MaximumTopBanner = Int(10)
        static let MaxLoginAttempts = Int(3)
        static let ProductBottomViewHeight = CGFloat(125.0)
        static let CatCellHeight = CGFloat(40.0)
        static let FilterColorWidth = CGFloat(49.0)
        static let BrandImageWidth = CGFloat(105.0)
        static let BrandImageHeight = CGFloat(28.0)
        static let PdpBrandImageWidth = CGFloat(105.0)
        static let PdpBrandImageHeight = CGFloat(28.0)
        static let BackButtonWidth : CGFloat = 30
        static let BackButtonHeight : CGFloat = 25
        static let BackButtonMarginLeft : CGFloat = -22
        static let MaxAttempt: Int = 5
        static let PullToRefreshViewHeight : CGFloat = 20
        static let FollowButtonCornerRadius = CGFloat(2)
        static let FollowButtonBorderWidth = CGFloat(0.5)
        static let RatingStarWidth = Double(20)
        static let RatingStarMargin = Double(15)
        static let ValidationCellHeight : CGFloat = 25
        static let PasswordMinLength : Int = 8
        static let PasswordMaxLength : Int = 16
        static let NickNameMaxLength : Int = 20
        static let FistNameLastNameMaxLength : Int = 50
        static let MarginActionButton: CGFloat = 16
        static let WidthActionButton: CGFloat = 56
        static let MaximumMerchantFeatures : Int = 200
        static let MaximumDisplayingMerchantFeatures : Int = 10
        static let MaximumDisplayingCuratorsList : Int = 0 //Max value to show / hide curator list
        static let MaximumCuratorRecommended : Int = 12 //Litmit displaying curators list
        static let MerchantCoupons: Int = 5
        static let MaximumOfficalHashTag : Int = 15
        static let NavigationButtonMargin: CGFloat = -18
    }
    
    struct PlaceHolder {
        static let FieldName = "<field name>"
        static let CurrentEmail = "<current email>"
        static let CurrentMobileNumber = "<current mobile number>"
    }
    
    struct Notification {
        static let langaugeChanged = NSNotification.Name("LanguageChanged")
		static let showQRCodeOnProfileView = NSNotification.Name("ShowQRCodeOnProfileView")
		static let closeQRCodeOnProfileView = NSNotification.Name("CloseQRCodeOnProfileView")
        static let changeAliasOnProfileView = NSNotification.Name("ChangeAliasOnProfileView")
        static let aliasBeginEditting = NSNotification.Name("AliasBeginEditting")
		static let removeProfileNavBarLogo = NSNotification.Name("RemoveProfileNavBarLogo")
		static let exitTagProductEditMode = NSNotification.Name("ExitTagProductEditMode")
		static let updateTagArraysForPost = NSNotification.Name("UpdateTagArraysForPost")
        static let tagDataFromSearchProduct = NSNotification.Name("TagDataFromSearchProduct")
        static let handleSelectedphoto = NSNotification.Name("HandleSelectedphoto")
		static let notifyUserLogin = NSNotification.Name("NotifyUserLogin")
		static let toggleHideOrShowProductTags = NSNotification.Name("ToggleHideOrShowProductTags")
		static let updateTagArraysForFrame = NSNotification.Name("UpdateTagArraysForFrame")
        static let backUpDataPost = NSNotification.Name("BackUpDataPost")
		static let followCuratorWithGuestUser = NSNotification.Name("FollowCuratorWithGuestUser")
        static let loginSuccessfulFromCheckout = NSNotification.Name("LoginSuccessfulFromCheckout")
        static let reloadChatScreen = NSNotification.Name("ReloadChatScreen")
		static let reportReviewListShown = NSNotification.Name("ReportReviewListShown")
        static let followingDidUpdate = NSNotification.Name("FollowingDidUpdate")
        static let followingMerchantDidUpdate = NSNotification.Name("FollowingMerchantDidUpdate")
		static let refreshNewsFeedPostAfterUploadedImage = NSNotification.Name("RefreshNewsFeedPostAfterUploadedImage")
        static let userLoggedOut = NSNotification.Name("UserLogout")
        static let createPostDidUpdatePhoto = NSNotification.Name("DidUpdatePhoto")
        static let refreshFriendRequest = NSNotification.Name("RefreshFriendRequest")
        static let continueGuestAction = NSNotification.Name("ContinueGuestAction")
        static let themeDidChange = NSNotification.Name("ThemeDidChange")
        static let updateTimeNotification = NSNotification.Name("UpdateTimeNotification")
        static let updateCartBadgeNotification = NSNotification.Name("UpdateCartBadgeNotification")
        static let loginSucceed = NSNotification.Name("LoginSucceedNotification")
        static let orderCreatedSucceed = NSNotification.Name("order.created.success.notice")
        static let profileImageUploadSucceed = NSNotification.Name("ProfileImageUploadSucceed")
        static let couponClaimedDidUpdate = NSNotification.Name("CouponClaimedDidUpdate")
    }
    
    struct Margin {
        static let Top = CGFloat(0.0)
        static let Left = CGFloat(5.0)
        static let Right = CGFloat(5.0)
        static let Bottom = CGFloat(0.0)
    }
    
    struct LimitNumber {
        static let LimitCharactor = 1000
        static let ImagesNumber = 5
        static let LimitSizeImage = CGFloat(10)
        static let LimitPostText = 300
        static let RecommendedProduct = 50
        static let LimitSearchText = 200
    }
    
    struct CharacterLimit {
        static let AfterSalesDescription = 200
        static let ReviewDescription = 200
        static let ReportReviewDescription = 200
        static let CheckoutComment = 200
    }
    
    struct ImageLimit {
        static let AfterSales = 3
        static let Review = 3
        static let ForwardChat = 3
    }
    
    struct LineSpacing {
        static let ImageCell = CGFloat(5.0)
        static let SubCatCell = CGFloat(20.0)
    }
    
    struct ProductGridView {
        static let CenterPadding: CGFloat = 1
    }
    
    struct Ratio {
        static let ProductImageHeight = CGFloat(7.0 / 6.0)
        static let PanelImageHeight = CGFloat(3.0 / 5.0)
        static let CoverImage = CGFloat(16.0 / 9.0)
        static let CuratorViewHeight = CGFloat(1)
    }
    
    struct Price {
        static let Highest : Float = 10000
    }
    
    struct Gender {
        static let Male: String = "M"
        static let Female: String = "F"
    }
    
    struct NewsFeed {
        static let CONST_POST_IMG_FILE_SIZE = "1.5 MB"
        static let CONST_POST_IMG_RESOLUTION_LIMIT : Int = 5000
        static let UserKeyLimit = 100
    }
    
    struct ScreenSize {
        static let SCREEN_WIDTH         = UIScreen.main.bounds.size.width
        static let SCREEN_HEIGHT        = UIScreen.main.bounds.size.height
        static let SCREEN_MAX_LENGTH    = max(ScreenSize.SCREEN_WIDTH, ScreenSize.SCREEN_HEIGHT)
        static let SCREEN_MIN_LENGTH    = min(ScreenSize.SCREEN_WIDTH, ScreenSize.SCREEN_HEIGHT)
        static var RATIO_WIDTH          = (DeviceType.IS_IPHONE_6 ? 1.0 : ScreenSize.SCREEN_WIDTH /  375)
        static var RATIO_HEIGHT         = (DeviceType.IS_IPHONE_6 ? 1.0 : ScreenSize.SCREEN_HEIGHT /  667)
        static var FONT_SCALE_IPHONE6S  = (DeviceType.IS_IPHONE_6P ? 1.27 : (DeviceType.IS_IPHONE_6 ? 1.15 : 1))
    }
    
    struct DeviceType {
        static let IS_IPHONE_4_OR_LESS  = UIDevice.current.userInterfaceIdiom == .phone && ScreenSize.SCREEN_MAX_LENGTH < 568.0
        static let IS_IPHONE_5          = UIDevice.current.userInterfaceIdiom == .phone && ScreenSize.SCREEN_MAX_LENGTH == 568.0
        static let IS_IPHONE_6          = UIDevice.current.userInterfaceIdiom == .phone && ScreenSize.SCREEN_MAX_LENGTH == 667.0
        static let IS_IPHONE_6P         = UIDevice.current.userInterfaceIdiom == .phone && ScreenSize.SCREEN_MAX_LENGTH == 736.0
        static let IS_IPAD              = UIDevice.current.userInterfaceIdiom == .pad && ScreenSize.SCREEN_MAX_LENGTH == 1024.0
    }
    
    struct CountryMobileCode {
        static let DEFAULT = "+86"
        static let HK = "+852"
    }

	struct Paging {
		static let Offset = 30
        static let newOffset = 50
        static let FriendOffset = 300
		static let PostOffset = 30
        static let CommentOffset = 30
        static let LikeListOffset = 200
        static let CategoryOffset = 1000
        static let ProductPropertyOffset = 100
        static let MerchantOffset = 500
        static let All = 9999
        static let BrandBatch = 1000
        static let Curator = 50
        static let BannerOffset = 100
        static let SkuSearchLimit = 90
	}
    
    struct TagProduct {
        static let Limit = 5
    }
    
    struct BottomButtonContainer {
        static let Height = CGFloat(68)
        static let MarginHorizontal = CGFloat(10)
        static let MarginVertical = CGFloat(13)
    }
    
    struct MobileNumber {
        static let MIN_LENGTH = 8
    }
    
    struct CompressionRatio {
        static let IM_JPG_COMPRESSION = CGFloat(1.0)
        static let JPG_COMPRESSION = CGFloat(0.9)
    }
    
    struct ChatSendImageSetting {
        static let ImageBoundSize = CGSize(width: CGFloat(Constants.MaxImageWidth), height: CGFloat(Constants.MaxImageWidth))
    }
    
    struct LenUserName {
        static let MinLen = 6
        static let MaxLen = 17
    }
    
    struct DefaultImageWidth {
        static let ProfilePicture = 200
        static let DiscoverItem = 500
        static let DiscoverBrandLogo = 400
        
        static let GridBanner = 700
        static let LargeIcon = 400
        
        static let Small = 200
        static let Medium = 500
        static let Large = 1000
    }
    
    enum PaymentMethod: Int {
        case alipay = 0
        case cod = 1
    }
    
    enum OmsViewMode: Int {
        case unknown = -1
        case all = 0
        case unpaid
        case toBeShipped
        case toBeReceived
        case toBeRated
        case afterSales
    }
    
    enum StatusID : Int {
        case deleted = 1
        case active
        case pending
        case inactive
    }
    
    enum InventoryStatusID: Int{
        case inStock = 1
        case lowStock
        case outOfStock
        case notAvailable
    }
    
    //Support display interface base on ShipmentStatusId and OrderStatusId
    //Refer OrderSectionData for detail of translations
    
    enum OrderDisplayStatus: Int {
        case unknown = 0
        case toBeShipped
        case shipped
        case received
        case toBeCollected
        case collected
        case cancelAccepted
        case cancelRequested
        case cancelRejected
        case refundAccepted
        case returnCancelled
        case returnRequestSubmitted
        case returnRequestAuthorised
        case returnRequestRejected
        case returnAccepted
        case returnRejected
        case disputeOpen
        case disputeInProgress
        case disputeAccepted
        case disputeRejected
        case disputeDeclined
        case returnRequestDeclinedCanNotDispute
        case returnRequestRejectedCanNotDispute
        case orderClosed
        
        case partialShip //Requirement Updated: We use this when we don't split order to seperate shipment status
    }
    
    enum OMSAfterSalesType: Int {
        case cancel = 0
        case `return`
        case dispute
    }
    
    enum OMSCancelHistoryType: Int{
        case unknown = 0
        case cancelSubmitted = 40
        case cancelSubmittedAutoAccepted
        case cancelSubmittedAccepted
        case cancelSubmittedRejected
    }
    //For displaying notification message
    enum NotificationEvent: Int {
        case unknown = 0
        
        //-- Shipment
        case shipmentDeliveryShipped        //Shipment (type: delivery) status changed to shipped
        case shipmentCollectionCreated      //Shipment (type: collection) is created
        case shipmentDeliveryCancel         //Shipment (type: delivery) is cancelled
        case shipmentCollectionCancel       //Shipment (type: collection) is cancelled
        case shipmentCollectionCollected    //Shipment (type: collection) is marked as "Collected" by merchant
        case shipmentDeliveryNotCollected   //Shipment (type: delivery) is not marked as "collected" by consumers 5 calendar days after status changed to "shipped" in MC for domestic orders or 15 for international orders
        case shipmentAutoReceived           //Shipment (type: delivery) is automatically marked as "received" by system
        
        //-- Order
        case orderAlipaySuccess             //Alipay payment success
        case orderAlipayFailed              //Alipay payment failed
        case orderCODPaymentCreated         //COD payment created
        case orderRefundSuccess             //Refund success
        case orderDetailUpdated             //Order details are updated
        case orderConsumerRequestCancel     //Consumer request to cancel some products
        case orderItemsCancelByMerchants    //Items are cancelled by merchants
        case orderItemsCancelAccepted
        case orderItemsCancelRejected
        
        //-- Return/refund Flow
        case returnRequested                //Return request is submitted
        case returnAuthorized               //Return request is authorised
        case returnRequestRejected          //Return request is rejected
        case returnConsumerNotFilledReturn  //Consumer has not filled in return shipping ID 5 calendar days after merchant accept return request
        case returnConsumerCancelRequest    //Consumer cancel the return request
        case returnAccepted                 //Returned item is accepted
        case returnRejected                 //Returned item is rejected
        
        //-- Dispute Flow
        case disputeSubmitted               //Dispute request is submitted
        case disputeProgress                //Dispute in progress
        case disputeApproved                //Dispute request is approved
        case disputeDeclined                //Dispute request is declined
        case disputeRejected                //Dispute request is rejected
        case returnRequestDeclinedCanNotDispute           //Return request is declined can not be disputed
        case returnRequestRejectedCanNotDispute           //Return rejected can not be disputed
        
        static func getEnumType(_ value: String) -> NotificationEvent {
            switch value {
            case "ORDER_CANCEL_CREATED":
                return NotificationEvent.orderConsumerRequestCancel
            case "ORDER_CANCEL_CONFIRMED":
                return NotificationEvent.orderItemsCancelByMerchants
            case "ORDER_RETURN_CREATED":
                return NotificationEvent.returnRequested
            case "ORDER_RETURN_AUTHORIZED":
                return NotificationEvent.returnAuthorized
            case "ORDER_RETURN_DECLINED":
                return NotificationEvent.returnRequestRejected
            case "ORDER_RETURN_CANCELLED":
                return NotificationEvent.returnConsumerCancelRequest
            case "ORDER_RETURN_ACCEPTED":
                return NotificationEvent.returnAccepted
            case "ORDER_RETURN_REJECTED":
                return NotificationEvent.returnRejected
            default:
                return NotificationEvent.unknown
            }
        }
        
        static func getReturnEnumType(_ value: String) -> NotificationEvent {
            switch value {
            case "REQUESTED":
                return NotificationEvent.returnRequested
            case "AUTHORIZED":
                return NotificationEvent.returnAuthorized
            case "DECLINED":
                return NotificationEvent.returnRequestRejected
            case "CANCELLED":
                return NotificationEvent.returnConsumerCancelRequest
            case "ACCEPTED":
                return NotificationEvent.returnAccepted
            case "REJECTED":
                return NotificationEvent.returnRejected
            case "REQUEST_DISPUTED":
                return NotificationEvent.disputeSubmitted
            case "REQUEST_DISPUTE_IN_PROGRESS":
                return NotificationEvent.disputeProgress
            case "RETURN_DISPUTED":
                return NotificationEvent.disputeSubmitted
            case "RETURN_DISPUTE_IN_PROGRESS":
                return NotificationEvent.disputeProgress
            case "DISPUTE_DECLINED":
                return NotificationEvent.disputeDeclined
            case "DISPUTE_REJECTED":
                return NotificationEvent.disputeRejected
            case "DECLINED_CANNOT_DISPUTE":
                return NotificationEvent.returnRequestDeclinedCanNotDispute
            case "REJECTED_CANNOT_DISPUTE":
                return NotificationEvent.returnRequestRejectedCanNotDispute
            default:
                return NotificationEvent.unknown
            }
        }
        
        static func getCancelEnumType(_ value: Int) -> NotificationEvent{
            if let omsCancelHistoryType = OMSCancelHistoryType(rawValue: value){
                switch omsCancelHistoryType {
                case .cancelSubmitted:
                    return NotificationEvent.orderConsumerRequestCancel
                case .cancelSubmittedAutoAccepted:
                    return NotificationEvent.orderItemsCancelByMerchants
                case .cancelSubmittedAccepted:
                    return NotificationEvent.orderItemsCancelAccepted
                case .cancelSubmittedRejected:
                    return NotificationEvent.orderItemsCancelRejected
                default:
                    break
                }
            }
            return NotificationEvent.unknown
        }
        
        func isShow() -> Bool{
            switch self{
            case .returnRequestDeclinedCanNotDispute, .returnRequestRejectedCanNotDispute:
                return false
            default:
                return true
            }
        }
    }
	
    
	struct TagPercentage {
		static let Offset = 10000
	}
    
    struct Duration {
        static let AliPay : TimeInterval = 2
    }
    
    struct ImageName {
        static let ProfileImagePlaceholder = "profile_avatar"
        static let BrandPlaceholder = "brand_placeholder"
    }
    
    struct Separator {
        static let DefaultThickness: CGFloat = 0.5
        static let BoldThickness: CGFloat = 1
        static let DefaultColor = UIColor.secondary1()
    }
	
    struct ErrorCode {
        static let EmptyReponseErrorCode = -901
    }
    
    
    struct ErrorHandling {
        static let RetryCount = 3
        static let DNSRetryCount = 3
        static let RetryInterval = 3.0
        static let DNSRetryInterval = 2.0
        static let RetryNetworkErrors = [NSURLErrorUnknown /* 1 */, NSURLErrorCannotFindHost /* 1003 */, NSURLErrorCannotConnectToHost /* 1004 */, NSURLErrorDNSLookupFailed /* 1006 */, NSURLErrorNotConnectedToInternet /* 1009 */]
    }
}
