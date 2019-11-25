//
//  TrackingDelegate.swift
//  storefront-ios
//
//  Created by lingminjun on 2018/3/28.
//  Copyright © 2018年 WWE & CO. All rights reserved.
//

import Foundation


let PAGE_VIEW_UUID_KEY = ".PAGE_VIEW_UUID_KEY"
let VIEW_IMPRS_UUID_KEY = ".VIEW_IMPRS_UUID_KEY"

extension UIViewController {
    //控制新老版本埋点兼容
    @objc func track_support() -> Bool {
        return false
    }
}

extension MMUIController {
    //新的埋点开启
    @objc override func track_support() -> Bool {
        return true
    }
}

extension AppDelegate: MMTracker {
    
    
    func trackingSetup() -> Void {
        MMTrack.setTracker(tracker: self)
    }
    
    fileprivate func genViewRecord(page: MMTrackPage) -> AnalyticsViewRecord {
        let url = page.track_url()
        
        //每次都换一遍
        let record = AnalyticsViewRecord()
        record.sessionKey = AnalyticsManager.sharedManager.getSessionKey()
        
        record.viewKey = Utils.UUID()
        record.timestamp = Date()
        if let obj = page as? NSObject {
            obj.ssn_setTag(PAGE_VIEW_UUID_KEY, tag: record.viewKey)
        }
        
        //未登录写0
        record.authorRef = Context.getUserKey()                     // GUID or UserKey
        let user = Context.getUserProfile()
        record.authorType = user.userTypeString()                   // Curator, User
        
        //很费解，如此字段，毫无设计意义（无法扩展，BI自行根据url就可算出页面类型和id）
        //record.brandCode = brandCode ?? ""                     //
        //record.merchantCode = merchantCode ?? ""               //
        
        //所有的地址信息
        record.referrerRef = Urls.tidy(url: page.track_url(), query:QBundle())// page.track_url()                 // GUID or UserKey or Link definition
        record.referrerType = "Link"               // Curator, User, Link
        
        record.viewDisplayName = page.track_title()         //
        if let query = URL(string:url)?.query {
            record.viewParameters = query               //
        }
        record.viewLocation = page.track_pid()               // PDP
        
        //很费解，如此字段，毫无设计意义（无法扩展，BI自行根据url就可算出页面类型和id）
        //        record.viewRef = viewRef ?? ""                         // GUID or "NJMU5588"
        //        record.viewType = viewType ?? ""                       // Product
        
        return record
    }
    
    fileprivate func genImpressionRecord(page: MMTrackPage, comp:MMTrackComponent) -> AnalyticsImpressionRecord {
        let url = page.track_url()
        let vid = comp.track_vid()
        
        //每次都换一遍
        let record = AnalyticsImpressionRecord()
        record.sessionKey = AnalyticsManager.sharedManager.getSessionKey()
        
        if let obj = page as? NSObject,let uuid = obj.ssn_tag(PAGE_VIEW_UUID_KEY) as? String {
            record.viewKey = uuid
        } else {
            record.viewKey = Utils.UUID()
        }
        record.timestamp = Date()
        
        //每次曝光不一样
        record.impressionKey = Utils.UUID()
        if let obj = comp as? NSObject {
            obj.ssn_setTag(VIEW_IMPRS_UUID_KEY, tag: record.impressionKey)
        }
        
        //未登录写0
        record.authorRef = Context.getUserKey()                     // GUID or UserKey
        let user = Context.getUserProfile()
        record.authorType = user.userTypeString()                   // Curator, User
        
        //很费解，如此字段，毫无设计意义（无法扩展，BI自行根据url就可算出页面类型和id）
        //record.brandCode = brandCode ?? ""                     //
        //record.merchantCode = merchantCode ?? ""               //
        // record.parentRef = "\(strongSelf.style.styleCode)"
        // record.parentType = "Product"
        
        //所有的地址信息
        record.referrerRef = Urls.tidy(url: url, query:QBundle())// page.track_url()                 // GUID or UserKey or Link definition
        record.referrerType = "Link"               // Curator, User, Link
        
        //很费解，如此字段，毫无设计意义（无法扩展，BI自行根据url就可算出页面类型和id）
        //        record.viewRef = viewRef ?? ""                         // GUID or "NJMU5588"
        //        record.viewType = viewType ?? ""                       // Product
        
        //取vid中的几个字段
        if !vid.isEmpty {
            //pageId.compId.compIdx.dataType.dataId.dataIdx
            let vcds = vid.split(separator: ".")
            var tvid = ""
//            var pageId = ""
            var compId = ""
            var compIdx = ""
            var dataType = ""
            var dataId = ""
            var dataIdx = ""
            if vcds.count == 6 {
                tvid = "\(MYMM_APP_ID).\(vid)"
//                pageId = String(vcds[0])
                compId = String(vcds[1])
                compIdx = String(vcds[2])
                dataType = String(vcds[3])
                dataId = String(vcds[4])
                dataIdx = String(vcds[5])
            } else if vcds.count == 7 {
                tvid = "\(MYMM_APP_ID).\(vcds[1]).\(vcds[2]).\(vcds[3]).\(vcds[4]).\(vcds[5]).\(vcds[6])"
//                pageId = String(vcds[1])
                compId = String(vcds[2])
                compIdx = String(vcds[3])
                dataType = String(vcds[4])
                dataId = String(vcds[5])
                dataIdx = String(vcds[6])
            }
            
            record.VID = tvid
            
            // "ImpressionRef" :  组件Key,//{BannerKey},{StyleCode},{PostId},{BrandId},可传{dataId}
            // "ImpressionType" : 组件类型,//“Banner”,”Product”,”Post”,”Brand”,可传{dataType}
            record.impressionRef = dataId
            record.impressionType = dataType
            
            //"PositionIndex" : 位置参数,//可传{compIdx-dataIdx},中间用“-”分隔符分开
            record.positionStringIndex = "\(compIdx)-\(dataIdx)"
            
            //"PositionComponent" : 组件英文名称 ,//可传{compId}
            record.positionComponent = compId
        }
        
        //"PositionLocation" :页面英文名称 ,//可传{PageId}
        record.positionLocation = page.track_pid().isEmpty ? page.track_title() : page.track_pid()
  
        //"ImpressionDisplayName" : 组件中文名称,//{BannerName},{SkuName}等
        record.impressionDisplayName =  comp.track_name() //
        
        return record
    }
    
    fileprivate func genActionRecord(page:MMTrackPage,comp:MMTrackComponent) -> AnalyticsActionRecord {
        let url = page.track_url()
        let vid = comp.track_vid()
        let originDataId = comp.track_data_id()
        let originDataType = comp.track_data_type()
        
        
        let record = AnalyticsActionRecord()
        record.sessionKey = AnalyticsManager.sharedManager.getSessionKey()

        if let obj = page as? NSObject,let uuid = obj.ssn_tag(PAGE_VIEW_UUID_KEY) as? String {
            record.viewKey = uuid
        } else {
            record.viewKey = Utils.UUID()
        }
        
        if let obj = comp as? NSObject,let uuid = obj.ssn_tag(VIEW_IMPRS_UUID_KEY) as? String {
            record.impressionKey = uuid
        } else {
            record.impressionKey = Utils.UUID()
        }
        
        //未登录写0
        record.authorRef = Context.getUserKey()                     // GUID or UserKey
//        let user = Context.getUserProfile()
//        record.authorType = user.userTypeString()                   // Curator, User
        
        //所在页面
        //所有的地址信息
        record.referrerRef = Urls.tidy(url: url, query:QBundle())// page.track_url()                 // GUID or UserKey or Link definition
        record.referrerType = "Link"               // Curator, User, Link
        
        record.actionKey = Utils.UUID()
        record.actionTrigger = .Tap //暂时仅仅只记录点击
        
        //        "TargetType" : {compName:按钮名称} ,
        record.targetTypeString = comp.track_name()
        //        "TargetRef" : "{Deeplink}",
        record.targetRef = comp.track_mediaLink()
        
        //取vid中的几个字段
        if !vid.isEmpty {
            //pageId.compId.compIdx.dataType.dataId.dataIdx
            let vcds = vid.split(separator: ".")
            var tvid = ""
            //            var pageId = ""
            var compId = ""
//            var compIdx = ""
            var dataType = ""
            var dataId = ""
//            var dataIdx = ""
            if vcds.count == 6 {
                tvid = "\(MYMM_APP_ID).\(vid)"
                //                pageId = String(vcds[0])
                compId = String(vcds[1])
//                compIdx = String(vcds[2])
                dataType = String(vcds[3])
                dataId = String(vcds[4])
//                dataIdx = String(vcds[5])
            } else if vcds.count == 7 {
                tvid = "\(MYMM_APP_ID).\(vcds[1]).\(vcds[2]).\(vcds[3]).\(vcds[4]).\(vcds[5]).\(vcds[6])"
                //                pageId = String(vcds[1])
                compId = String(vcds[2])
//                compIdx = String(vcds[3])
                dataType = String(vcds[4])
                dataId = String(vcds[5])
//                dataIdx = String(vcds[6])
            }
            
            record.VID = tvid
            
            //        "SourceType" : 组件英文名称 ,//可传{CompId}
            record.sourceTypeString = dataType
            //        "SourceRef" : 组件Key//{BannerKey},{StyleCode},{PostId},{BrandId},{MerchantId},可传{dataId}
            record.sourceRef = dataId
            
            //        "TargetRef" : "{Deeplink}",
            record.targetRef = comp.track_mediaLink().isEmpty ? compId : comp.track_mediaLink()
        } else if !originDataId.isEmpty && !originDataType.isEmpty {
            record.sourceTypeString = originDataType
            record.sourceRef = originDataId
        }
        
        return record
    }
    
    // MARK: - MMTracker imp
    /*View:
     {[
         "Type" : "v"  ,
         "ViewKey" : GUID,
         "SessionKey" : {Inherit current SessionKey}  ,
         "Timestamp" : {ISO 8601 string base with milliseconds}  ,  //时间戳
         "ViewType" : 页面类型 ,//Product,Post,Merchant,Brand等
         "ViewRef" : 参数,//stylecode 或者postId,或者merchantId，BrandId等
         "ViewLocation" : {PageId},
         "ViewParameters" : xxxx,
         "ViewDisplayName" : 页面中文名称,
         "MerchantCode" : xxxx,
         "BrandCode" : xxxx,
         "AuthorType" : NULL  ,
         "AuthorRef" : NULL  ,
         "ReferrerType" : {Deeplink} ,
         "ReferrerRef" : NULL,//如果是网页,则为“web”
     ]}
     */
    func pageEnter(page: MMTrackPage) {
        let url = page.track_url()
        //空的暂时不做埋点
        if url.isEmpty {
            return
        }
        
        //对应到view
        print("页面\(page.track_url())进入")
        if let vc = page as? UIViewController, !vc.track_support() {
            print("页面\(page.track_url())不采用新的埋点")
            return
        }
        
        let record = genViewRecord(page: page)
        AnalyticsManager.sharedManager.recordView(record)
    }
    
    /*
     Impression:
     需要新增字段VID，定义为pageId.compId.compIdx.dataType.dataId.dataIdx
     {[
         "Type" : "i"  ,
         "ImpressionKey" : GUID,
         "SessionKey" : {Inherit current SessionKey}  ,
         "ViewKey" :{Inherit current ViewKey},
         "Timestamp" : {ISO 8601 string base with milliseconds}  ,  //时间戳
         "ImpressionType" : 组件类型,//“Banner”,”Product”,”Post”,”Brand”,可传{dataType}
         "ImpressionRef" :  组件Key,//{BannerKey},{StyleCode},{PostId},{BrandId},可传{dataId}
         "ImpressionVariantRef" : XXX,
         "ImpressionDisplayName" : 组件中文名称,//{BannerName},{SkuName}等
         "PositionLocation" :页面英文名称 ,//可传{PageId}
         "PositionComponent" : 组件英文名称 ,//可传{compId}
         "PositionIndex" : 位置参数,//可传{compIdx-dataIdx},中间用“-”分隔符分开
         "MerchantCode" : NULL,
         "BrandCode" : NULL,
         "ParentType" : NULL  ,
         "ParentRef" : NULL  ,
         "AuthorType" : NULL  ,
         "AuthorRef" : NULL  ,
         "ReferrerType" : NULL  ,
         "ReferrerRef" : NULL
         “VID”: {pageId.compId.compIdx.dataType.dataId.dataIdx}
     ]}
     */
    func viewReveal(page: MMTrackPage, comp: MMTrackComponent) {
        let url = page.track_url()
        let vid = comp.track_vid()
//        let compName = comp.track_name()
        
        //本期仅限打点范围(没有vid的不做曝光)
        if url.isEmpty || vid.isEmpty {
            return
        }
        
        //老页面暂时不去埋点漏出
        if let vc = page as? UIViewController, !vc.track_support() {
            return
        }
        
        //漏出埋点
        let record = genImpressionRecord(page: page, comp: comp)
        AnalyticsManager.sharedManager.recordImpression(record)
    }
    
    /*
     Action:
     需要新增字段VID，定义为pageId.compId.compIdx.dataType.dataId.dataIdx
     3.1  产品的点击action tag是固定的:
     {[
         "Type" : "a"  ,
         "ActionKey" : guid  ,
         "SessionKey" : {Inherit current SessionKey}  ,
         "ViewKey" : {Inherit current ViewKey}  ,
         "ImpressionKey" :{Inherit current ImpressionKey}     ,
         "Timestamp" : {ISO 8601 string base with milliseconds}   ,  //e.g. “2016-07-11T16:30:06.800Z”
         "ActionTrigger" : "Tap"  ,
         "SourceType" : "Product"  ,
         "SourceRef" : {StyleCode}  ,
         "TargetType" : "View"  ,
         "TargetRef" : "PDP"
         “VID”: {pageId.compId.compIdx.dataType.dataId.dataIdx}
     ]}
     3.2 其他action tag可以按照如下规律：
     {[
         "Type" : "a"  ,
         "ActionKey" : GUID  ,
         "SessionKey" : {Inherit current SessionKey}  ,
         "ViewKey" : {Inherit current ViewKey}  ,
         "ImpressionKey" : {Inherit current Banner ImpressionKey}    ,
         "Timestamp" : 时间戳
         "ActionTrigger" : "Tap"  ,
         "SourceType" : 组件英文名称 ,//可传{CompId}
         "SourceRef" : 组件Key//{BannerKey},{StyleCode},{PostId},{BrandId},{MerchantId},可传{dataId}
         "TargetType" : {dataType} ,
         "TargetRef" : "{Deeplink}",
         “VID”: {pageId.compId.compIdx.dataType.dataId.dataIdx}
     ]}
     */
    func viewAction(page: MMTrackPage, comp: MMTrackComponent, event: UIEvent) {
        let url = page.track_url()
        let vid = comp.track_vid()
        let dataId = comp.track_data_id()
        let compName = comp.track_name()
        
        //本期仅限打点范围(没有名字的不做响应埋点)
        if url.isEmpty || (compName.isEmpty && vid.isEmpty && dataId.isEmpty) {
            return
        }
        
        //
        print("页面\(page.track_url())中\"\(comp.track_name())\"响应了")
        
        let record = genActionRecord(page: page, comp: comp)
        AnalyticsManager.sharedManager.recordAction(record)
    }
}

