//
//  CMSService.swift
//  storefront-ios
//
//  Created by Leslie Zhang on 2018/4/9.
//  Copyright © 2018年 WWE & CO. All rights reserved.
//

import Foundation
import Alamofire
import ObjectMapper



class CMSService {
    static let POST_PATH = Constants.Path.Host + "/page"
    static let CHANNEL_PATH = Constants.Path.Host + "/channel"
    static let COMPONENT_PATH = Constants.Path.Host + "/component"
    
    class func channelList(brand isBrand:Bool = false, success: @escaping ((_ value: [CMSPageModel]) -> Void), failure: @escaping (_ error: Error) -> Bool) {
        var url = CHANNEL_PATH + "/list?Status=2"
        if isBrand {
            url = CHANNEL_PATH + "/list?Type=BRAND&Status=2" // 全部品牌
        }
        RequestFactory.requestWithArray(.get, url: url, appendUserKey: false, appendUserId: false, success: success, failure: failure)
    }
    
    
    class func getComponentDatas(_ comp:CMSPageComsModel,
                                 _ id : Int,
                                 _ pageId : Int,
                                 pagesize:Int,
                                 pageno:Int,
                                 compIdx:Int = 0,
                                 success: @escaping ((_ value: CMSPageComsModel) -> Void),
                                 successArray: @escaping ((_ value: [CMSPageComsModel]) -> Void),
                                 failure: @escaping (_ error: Error) -> Bool) {
        
        var params: [String : Any] = ["pageno": pageno, "pagesize": pagesize, "id": id]
        var url = COMPONENT_PATH + "/getdata"
        
        if comp.comType == .dailyRecommend {
            var sectionIds = [String]()
            if let data = comp.data {
                for model in data {
                    sectionIds.append(model.sectionId)
                }
            }
            let sectionIdsStr = sectionIds.joined(separator: ",")
            url = COMPONENT_PATH + "/getDataArray?id=\(id)"
            params = ["SectionIds":sectionIdsStr,"pageno": "1", "pagesize": "6"]
        }
        
        let aryscs:((_ value: [CMSPageComsModel]) -> Void) = { (value) in
            //先生产vid
            for cidx in 0..<value.count {
                let com = value[cidx]
                let compId = "\(id)-\(cidx)"
                genCompDataVid(pageId: pageId, compIdx:compIdx ,compId: compId, pagesize: pagesize, pageno: pageno, comp: com)
            }
            
            successArray(value)
        }
        
        let scs:((_ value: CMSPageComsModel) -> Void) = { (value) in
            //先生产vid
            genCompDataVid(pageId: pageId, compIdx:compIdx ,compId: "\(id)", pagesize: pagesize, pageno: pageno, comp: value)
            
            success(value)
        }
        
        if comp.comType == .dailyRecommend {
            RequestFactory.requestWithArray(.get, url: url,parameters:params, appendUserKey: false, appendUserId: false, success: aryscs, failure: failure)
     
        } else {
            RequestFactory.requestWithObject(.get, url: url,parameters:params, appendUserKey: false, appendUserId: false, success: scs, failure: failure)
        }
        
        
    }
    

    
    class func list(_ id:Int,chnlId:Int,success: @escaping ((_ value: CMSPageModel) -> Void), failure: @escaping (_ error: Error) -> Bool) {
        let params:[String : Int] = ["Id": id,"ChnlId":chnlId]
        let url = POST_PATH + "/publicview"
        let scs:((_ value: CMSPageModel) -> Void) = { (value) in
            //先生产vid
            genPageDataVid(page:value)
            
            success(value)
        }
        RequestFactory.requestWithObject(.get, url: url,parameters:params, appendUserKey: false, appendUserId: false, success: scs, failure: failure)
    }
    
    private static func genPageDataVid(page:CMSPageModel) {
        guard let coms = page.coms else { return }
        
        for i in 0..<coms.count {
            let comp = coms[i]
            comp.comIdx = i
            if let dts = comp.data {
                for j in 0..<dts.count {
                    let d = dts[j]
                    //pageId.compId.compIdx.dataType.dataId.dataIndex
                    d.vid = "\(page.pageId).\(comp.comId).\(i).\(d.dType).\(d.dId).\(j)"
                }
            }
        }
        
    }
    
    private static func genCompDataVid(pageId:Int,compIdx:Int,compId:String,pagesize:Int,pageno:Int, comp:CMSPageComsModel) {
        comp.comIdx = compIdx
        
        let idx = pageno < 1 ? 0 : (pageno - 1) * pagesize
        
        if let dts = comp.data {
            for j in 0..<dts.count {
                let d = dts[j]
                //pageId.compId.compIdx.dataType.dataId.dataIndex
                d.vid = "\(pageId).\(compId).\(compIdx).\(d.dType).\(d.dId).\(idx + j)"
            }
        }
    }
}
