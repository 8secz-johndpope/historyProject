//
//  singnRecommendService.swift
//  storefront-ios
//
//  Created by Leslie Zhang on 2018/8/13.
//  Copyright © 2018年 WWE & CO. All rights reserved.
//

import UIKit

class SingnRecommendService {
    static func userGetRecommendData(pagesize:Int,pageno:Int,success: @escaping ((_ value: CMSPageComsModel) -> Void),failure: @escaping (_ error: Error) -> Bool) {
        
        let params: [String : Any] = ["pageno": pageno, "pagesize": pagesize]
        
        let url = Constants.Path.Host + "/x/selections"
        
        let scs:((_ value: CMSPageComsModel) -> Void) = { (value) in
            //先生产vid
            genRecommendDataVid(pagesize: pagesize, pageno: pageno, comp: value)
            
            success(value)
        }
        RequestFactory.requestWithObject(.get, url: url,parameters:params, appendUserKey: true, appendUserId: true, success: scs, failure: failure)
    }
    
    static func publickGetRecommendData(pagesize:Int,pageno:Int,success: @escaping ((_ value: CMSPageComsModel) -> Void),failure: @escaping (_ error: Error) -> Bool) {
        
        let params: [String : Any] = ["pageno": pageno, "pagesize": pagesize]
        
        let url = Constants.Path.Host + "/x/selections/anonymous"
        
        let scs:((_ value: CMSPageComsModel) -> Void) = { (value) in
            //先生产vid
            genRecommendDataVid(pagesize: pagesize, pageno: pageno, comp: value)
            
            success(value)
        }
        
        RequestFactory.requestWithObject(.get, url: url,parameters:params, appendUserKey: false, appendUserId: false, success: scs, failure: failure)
    }
    
    //相似商品（syte）
    static func styleSearchData(skuid:Int, excludeself:Bool = false,waiting:Bool = false, pagesize:Int,pageno:Int,success: @escaping ((_ value: Syte) -> Void),failure: @escaping (_ error: Error) -> Bool) {
        
        let params: [String : Any] = ["skuid":skuid,"excludeself":excludeself ? 1 : 0,"pageno": pageno, "pagesize": pagesize]
        
        let url = Constants.Path.Host + "/search/style/related"
        
        let finalScs:((_ value: Syte) -> Void) = { (value) in
            //先生产vid
            let idx = pageno < 1 ? 0 : (pageno - 1) * pagesize
            genRelatedDataVid(idx:idx, syte: value)
            
            success(value)
        }
        
        let scs:((_ value: Syte) -> Void) = { (value) in
            
            //只有excludeself和waiting都为true时展示
            if excludeself && waiting && (value.pageData == nil || value.pageData!.isEmpty) {
                DispatchQueue.main.asyncAfter(deadline: DispatchTime.now() + 5, execute: {
                    RequestFactory.requestWithObject(.get, url: url,parameters:params, appendUserKey: false, appendUserId: false, success: finalScs, failure: failure)
                });
                return
            }
            
            finalScs(value)
        }
        
        RequestFactory.requestWithObject(.get, url: url,parameters:params, appendUserKey: false, appendUserId: false, success: scs, failure: failure)
        
    }
    
    //PDP页面相关商品接口实现，里面会根据 syteLoaded 来判断是否需要继续加载syte
    static func searchRecommendedProducts(skuid:Int, merchantId:Int, pagesize:Int, pageno:Int, syteLoaded:Bool = false,dataCount:Int = 0,success: @escaping ((_ value: Syte) -> Void),failure: @escaping (_ error: Error) -> Bool) {
        
        //加载最新商品
        let finalBlock:((_ syte: Syte) -> Void) = { (syte) in
            let search_url = Constants.Path.Host + "/search/style"
            let params : [String : Any] = ["merchantid": merchantId,
                                               "pageno" : pageno,
                                               "pagesize" : (pagesize <= 0 ? 50 : pagesize),
                                               "badgeid": 1,
                                               "notsoldout":1,
                                               "order":"desc",
                                               "sort":"DisplayRanking",
                                               "aggsize":1000
            ]
            
            //最后请求成功，合并数据
            let scs:((_ value: SearchResponse) -> Void) = { (value) in
                
                if syte.pageData == nil {
                    syte.pageData = value.pageData
                } else if let datas = value.pageData {//新品数据拼接到后面
                    syte.pageData?.append(contentsOf: datas)
                }
                syte.pageCurrent = value.pageCurrent
                syte.hitsTotal = value.hitsTotal
                syte.pageSize = value.pageSize
                syte.pageTotal = value.pageCount
                
                //先生产vid
                genRelatedDataVid(idx: dataCount, syte: syte)
                
                success(syte)
            }
            
            let flr:(_ error: Error) -> Bool = { (err) in
                if let datas = syte.pageData, !datas.isEmpty {//因为有syte数据，同样成功返回
                    syte.pageCurrent = 0
                    success(syte)
                    return true
                } else {//
                    return failure(err)
                }
            }
            
            RequestFactory.requestWithObject(.get, url: search_url, parameters:params, appendUserKey: false, appendUserId: false, success: scs, failure: flr)
        }
        
        
        if !syteLoaded {//优先加载syte
            
            let syte_url = Constants.Path.Host + "/search/style/related"
            let params: [String : Any] = ["skuid":skuid, "excludeself":1, "pageno": 1, "pagesize": 50]
            
            let syteScs:((_ value: Syte) -> Void) = { (value) in
                if let datas = value.pageData, !datas.isEmpty {
                    value.containedSyte = true
                }
                finalBlock(value)
            }
            let syteflr:(_ error: Error) -> Bool = { (err) in
                //忽略错误，继续加载新品
                let stye = Syte()
                finalBlock(stye)
                return true
            }
            RequestFactory.requestWithObject(.get, url: syte_url, parameters:params, appendUserKey: false, appendUserId: false, success: syteScs, failure: syteflr)
            
        } else {//直接加载新品
            let stye = Syte()
            finalBlock(stye)
        }
        
    }
    
    //埋点需要
    private static func genRelatedDataVid(idx:Int, syte:Syte) {
        if let dts = syte.pageData {
            for j in 0..<dts.count {
                let d = dts[j]
                //pageId.compId.compIdx.dataType.dataId.dataIndex
                let id = d.currentSkuId != 0 ? d.currentSkuId : d.defaultSkuId()
                d.vid = "related.plp.0.SKU.\(id).\(idx + j)"
            }
        }
    }
    
    //埋点需要
    public static func genRelatedBrandVid(brand:Brand, index:Int) {
        brand.vid = "related.plp.0.BRAND.\(brand.brandId).\(index)"
    }
    
    //埋点需要
    private static func genRecommendDataVid(pagesize:Int,pageno:Int, comp:CMSPageComsModel) {
        let idx = pageno < 1 ? 0 : (pageno - 1) * pagesize        
        if let dts = comp.data {
            for j in 0..<dts.count {
                let d = dts[j]
                //pageId.compId.compIdx.dataType.dataId.dataIndex
                d.vid = "recommendpopup.plp.0.\(d.dType).\(d.dId).\(idx + j)"
            }
        }
    }
    
}
