//
//  CMSPageModel.swift
//  MMDemoForLeslie_Swift4.0
//
//  Created by Leslie Zhang on 2018/3/22.
//  Copyright © 2018年 Leslie Zhang. All rights reserved.
//

import UIKit
import ObjectMapper

enum DataType: String {
    case DEFAULT = "DEFAULT",
    SKU = "SKU",
    BRAND = "BRAND",
    MERCHANT = "MERCHANT",
    PAGE = "PAGE",
    POST = "POST",
    BANNER = "BANNER",
    COUPON = "Coupon"
}

enum ComCMSPathType: String {
    case defaultBanner = "defaultBanner",
    shortcutBanner = "shortcutBanner",
    heroBanner = "heroBanner'",
    productBanner = "productBanner",
    subBanner = "subBanner",
    postBanner = "postBanner",
    gridBanner = "gridBanner",
    newUserRegister = "newUserRegister"
}

enum CmsOrientationType:String {
    case defaultOrientation = "defaultOrientation",
    vertical = "vertical",
    horizontal = "horizontal"
}

enum CmsComType:String {
    case defaultBanner = "defaultBanner",
    swiperBanner = "swiper_banner",
    gridBanner = "grid_banner",
    productBanner = "product_banner",
    heroBanner = "hero_banner",
    brandListBanner = "brand_list_banner",
    newsfeed = "newsfeed",
    Newsfeed = "Newsfeed",
    productList = "product_list",
    ProductList = "ProductList",
    rankingBanner = "ranking_banner",
    couponSection = "coupon",
    dailyRecommend = "daily_recommend"
}



class CMSPageModel: Mappable {
    public var chnlId:Int = 0
    public var pageId:Int = 0
    public var status:Int = 0
    public var title:String = ""
    public var link: String = ""
    public var coverImage: String = ""
    public var isWeb:Bool = false
    public var description = ""
    public var isShareable:Bool = true //默认是可以分享的
    public var coms:[CMSPageComsModel]?
    
   

    
    private var tempChnlId:Int = 0
    private var tempLink: String = ""
    private var tempPageId = 0
    private var tempId = 0
    
    // page like and comment function
    public var likeCount = 0
    public var pageKey = ""
    public var isLike = false
    
    // cms page
    public var pageType = ""
    public var pageTypeId = 0
    
    required convenience init?(map: Map) {
        self.init()
    }
    
    //因为cms页面实际是一种page，page统一使用老的model:MagazineCover
    public func toMagazineModel() -> MagazineCover {
        let magazine = MagazineCover()
        magazine.contentPageName = self.title
        magazine.contentPageKey = self.pageKey
        magazine.coverImage = self.coverImage
        magazine.isLike = self.isLike
        magazine.contentPageTypeId = self.pageTypeId
        magazine.contentPageId = self.pageId
        magazine.contentPageCollectionName = self.pageType
        magazine.likeCount = self.likeCount
        magazine.total = 0
        magazine.link = self.link
        return magazine
    }
    
    func mapping(map: Map) {
        tempChnlId       <- map["ChannelId"]
        tempLink         <- map["DeepLink"]
        
        if tempChnlId != 0 {
            chnlId   = tempChnlId
        } else {
            chnlId   <- map["ChnlId"]
        }

        tempId       <- map["Id"]
        tempPageId   <- map["ContentPageId"]
        if tempPageId != 0 {
            pageId   = tempPageId
        } else if tempId != 0 {
            pageId   = tempId
        } else {
            pageId   <- map["PageId"]
        }
        
        
        status       <- map["Status"]
        title        <- map["Title"]
        
        if !tempLink.isEmpty {
            link     = tempLink
        } else {
            link     <- map["Link"]
        }
        
        coverImage   <- map["CoverImage"]
        isWeb        <- map["IsWeb"]
        description  <- map["Description"]
        isShareable  <- map["IsShareable"]
        coms         <- map["Coms"]
        
        pageKey      <- map["ContentPageKey"]
        pageType     <- map["Type"]
        pageTypeId   <- map["ContentPageTypeId"]
        likeCount    <- map["LikeCount"]
    }
}

class CMSPageComsModel: Mappable {
    public var comId = ""
    private var intComId:Int = 0 //服务端在public/view和component/getdata接口返回类型不一致
    public var comType:CmsComType = .defaultBanner
    public var w:CGFloat = 0.0
    public var h:CGFloat = 0.0
    public var title:String = ""
    public var moreLink:String = ""
    public var colCount:Int = 1
    public var isActive:Bool = true
    public var isAPI:Bool = false
    public var bottom:Int = 10
    public var border:Int = 0
    public var padding:CGFloat = -1.0
    public var comCMSPath:ComCMSPathType = .defaultBanner
    public var data:[CMSPageDataModel]?
    public var extraInfo:String = ""
    public var orientation:CmsOrientationType = .defaultOrientation
    
    public var comIdx:Int = -1 //索引

    public var comGroupId:String {
        if comIdx < 0 {
            return comType.rawValue
        } else {
            return "\(comIdx)"
        }
    }
    
    public var recommends:[CMSPageComsModel]?
    public var recommendLinks:[String]?
    
    required convenience init?(map: Map) {
        self.init()
    }
    
    func mapping(map: Map) {
        comId       <- map["ComId"]
        intComId       <- map["ComId"]
        if comId.isEmpty && intComId != 0 {//兼容服务端返回 int或者String类型，导致map无法解析问题
            comId = "\(intComId)"
        }
        comType     <- map["ComType"]
        w           <- map["W"]
        h           <- map["H"]
        title       <- map["Title"]
        moreLink    <- map["MoreLink"]
        colCount    <- map["ColCount"]
        isActive    <- map["IsActive"]
        isAPI       <- map["IsAPI"]
        bottom      <- map["Bottom"]
        border      <- map["Border"]
        padding     <- map["Padding"]
        comCMSPath  <- map["ComCMSPath"]
        if padding == -1 {
            if comCMSPath == .shortcutBanner {
                padding = 0
            } else {
                padding = 15
            }
        }
        data        <- map["Data"]
        extraInfo   <- map["ExtraInfo"]
        orientation <- map["Orientation"]
    }
}

class CMSPageDataModel: Mappable {
    public var vid: String = ""
    
    public var dType:DataType = DataType.DEFAULT
    public var dId:String = ""
    private var intDId:Int = 0 //服务端在public/view和component/getdata接口返回类型不一致
    public var link:String = ""
    public var content:String = ""
    public var bannerName:String = ""
    public var imageUrl: String?
    public var w:CGFloat = 0
    public var h:CGFloat = 0
    public var price:String = ""
    public var videoUrl: String = ""
    public var index:Int = 0
    public var dObj: [String:Any]? {
        didSet {
            if let dataObj = dObj {
                if dType == .SKU {
                    self.style = Mapper<Style>().map(JSON: dataObj)
                }else if dType == .BRAND {
                    self.brand = Mapper<Brand>().map(JSON: dataObj)
                }else if dType == .MERCHANT {
                    self.merchant = Mapper<MerchantBrand>().map(JSON: dataObj)
                }else if dType == .PAGE {
                    self.page = Mapper<MagazineCover>().map(JSON: dataObj)
                } else if dType == .COUPON {
                    self.coupon = Mapper<Coupon>().map(JSON: dataObj)
                } else if dType == .POST {
                    self.post = Mapper<Post>().map(JSON: dataObj)
                }
            }
        }
    }
    
    public var style: Style?
    public var brand: Brand?
    public var post: Post?
    public var merchant: MerchantBrand?
    public var page: MagazineCover?
    public var coupon: Coupon?
    public var skuDatas = [CMSPageDataModel]()
    public var sectionId = ""
    public var formPDP = false
    
    required convenience init?(map: Map) {
        self.init()
    }
    
    func mapping(map: Map) {
        dType     <- map["DType"]
        dId       <- map["DId"]
        intDId    <- map["DId"]
        if dId.isEmpty && intDId != 0 {//兼容服务端返回 int或者String类型，导致map无法解析问题
            dId = "\(intDId)"
        }
        link      <- map["Link"]
        content   <- map["Content"]
        bannerName <- map["BannerName"]
        imageUrl  <- map["ImageUrl"]
        w         <- map["W"]
        h         <- map["H"]
        price     <- map["Price"]
        videoUrl  <- map["VideoUrl"]
        dObj      <- map["DObj"]
        sectionId <- map["SectionId"]
    }
}


