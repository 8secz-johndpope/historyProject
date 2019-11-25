//
//  BrowsingHistory.swift
//  storefront-ios
//
//  Created by MJ Ling on 2018/9/3.
//  Copyright © 2018年 WWE & CO. All rights reserved.
//

import Foundation

/**
 * 商品浏览历史，以设备为单位
 */
class BrowsingHistory: DBModel {
    required init() {
        
    }
    
    //浏览sku
    var skuId:Int { get { return SkuId ?? 0 } set { if newValue > 0 { SkuId = newValue } } }
    var styleId:Int { get { return StyleId ?? 0 } set { if newValue > 0 { StyleId = newValue } } }
    var styleCode:String { get { return StyleCode ?? "" } set { if newValue != "" { StyleCode = newValue } } }
    
    //浏览用户
    var userId:Int { get { return UserId ?? 0 } set { if newValue > 0 { UserId = newValue } } }
    var userKey:String { get { return UserKey ?? "" } set { if newValue != "" { UserKey = newValue } } }
    
    //sku对应的商户
    var brandId:Int { get { return BrandId ?? 0 } set { if newValue > 0 { BrandId = newValue } } }
    var brandCode:String { get { return BrandCode ?? "" } set { if newValue != "" { BrandCode = newValue } } }
    
    //sku对应的商户
    var merchantId:Int { get { return MerchantId ?? 0 } set { if newValue > 0 { MerchantId = newValue } } }
    var merchantCode:String { get { return MerchantCode ?? "" } set { if newValue != "" { MerchantCode = newValue } } }
    
    //浏览sku时搜索词
    var keywordHash:String { get { return KeywordHash ?? "" } set { if newValue != "" { KeywordHash = newValue } } }
    var keyword:String { get { return Keyword ?? "" } set { if newValue != "" { Keyword = newValue } } }
    
    var lastCreated:Int64 { get { return LastCreated ?? 0 } set { if newValue != 0 { LastCreated = newValue } } }
    var lastModified:Int64 { get { return LastModified ?? 0 } set { if newValue != 0 { LastModified = newValue } } }
    
    
    // MARK: ==== 浏览历史相关方法 ====
    //以搜索词查询最近浏览sku
    static func queryLatestBrowsingSkuBy(keyword: String) -> BrowsingHistory? {
        let tb = getTable()
        let Hashkey = keyword.ssn_md5()
        let items = tb.objects(BrowsingHistory.self, conditions:["KeywordHash":Hashkey], sort:NSSortDescriptor(key: "LastModified", ascending: false))
        return items.first
    }
    
    //以brandId查询最近浏览sku
    static func queryLatestBrowsingSkuBy(brandId: Int) -> BrowsingHistory? {
        let tb = getTable()
        let items = tb.objects(BrowsingHistory.self, conditions:["BrandId":brandId], sort:NSSortDescriptor(key: "LastModified", ascending: false))
        return items.first
    }
    
    //以userId查询最近浏览skus
    static func queryLatestBrowsingSkuBy(userId: Int, limit:Int = 1000) -> [BrowsingHistory] {
        let tb = getTable()
        return tb.objects(BrowsingHistory.self, conditions:["UserId":userId], sort:NSSortDescriptor(key: "LastModified", ascending: false), limit: limit)
    }
    
    // 搜索列表记录关键词查看
    static func clickSearchHistory(keyword:String, skuId:Int, style:Style? = nil) {
        if keyword.isEmpty || skuId <= 0 {
            return
        }
        
        let item = BrowsingHistory()
        
        item.SkuId = skuId
        
        //避免覆盖无效数据
        if let id = style?.styleId, id > 0 {
            item.StyleId = style?.styleId
            item.StyleCode = style?.styleCode
        }
        
        //避免覆盖无效数据
        if let id = style?.brandId, id > 0 {
            item.BrandId = style?.brandId
            //        item.BrandCode = style?.brandId
        }
        
        //避免覆盖无效数据
        if let id = style?.merchantId, id > 0 {
            item.MerchantId = style?.merchantId
            item.MerchantCode = style?.merchantCode
        }
        
        item.Keyword = keyword
        item.KeywordHash = keyword.ssn_md5()
        
        //若用户存在则，保存用户
        if Context.getUserId() > 0 {
            item.UserId = Context.getUserId()
            item.UserKey = Context.getUserKey()
        }
        
        item.save()
    }
    
    // 查看PDP记录
    static func lookOverHistory(skuId:Int, style:Style) {
        if skuId <= 0 {
            return
        }
        
        let item = BrowsingHistory()
        item.SkuId = skuId
        
        //避免覆盖无效数据
        if style.styleId > 0 {
            item.StyleId = style.styleId
            item.StyleCode = style.styleCode
        }
        
        //避免覆盖无效数据
        if style.brandId > 0 {
            item.BrandId = style.brandId
            //        item.BrandCode = style?.brandId
        }
        
        //避免覆盖无效数据
        if style.merchantId > 0 {
            item.MerchantId = style.merchantId
            item.MerchantCode = style.merchantCode
        }
        
        //若用户存在则，保存用户
        if Context.getUserId() > 0 {
            item.UserId = Context.getUserId()
            item.UserKey = Context.getUserKey()
        }
        
        item.save()
    }
    
    
    //存储数据
    func save() {
        let tb = BrowsingHistory.getTable()
        
        //最好记录服务端时间
        if let date = TimestampService.defaultService.getServerTime() {
            self.lastModified = Int64(date.timeIntervalSince1970)
        } else {
            self.lastModified = Int64(Date().timeIntervalSince1970)
        }
        
        if self.lastCreated <= 0 {
            self.lastCreated = self.lastModified
        }
        
        tb.upinsert(object: self)
        
        //客户端存储太多垃圾
        BrowsingHistory.clearCache(tb:tb)
    }
    
    
    // MARK: ==== 私有方法 ====
    private static func getTableName() -> String {
        return "browsing_history_sku"
    }
    
    private static func getTable() -> DBTable {
        return DBUtil.globaltable(getTableName())
    }
    
    private static var cache_checked = false
    private static func clearCache(tb:DBTable) {
        if !cache_checked {
            cache_checked = true
            DispatchQueue.global().async {
                if tb.objectsCount() > 10000 {
                    let db = DB.db(with: "guest")
                    //删除最后5000条数据
                    db.execute("DELETE FROM \(BrowsingHistory.getTableName()) WHERE rowid >= 0 ORDER BY LastModified ASC LIMIT 5000")
                }
            }
        }
    }
    
    
    
    // MARK: ==== 以下实际字段 ====
    var ssn_rowid: Int64 = 0
    
    //浏览sku
    private var SkuId:Int? = nil
    private var StyleId:Int? = nil
    private var StyleCode:String? = nil
    
    //浏览用户
    private var UserId:Int? = nil
    private var UserKey:String? = nil
    
    //sku对应的商户
    private var BrandId:Int? = nil
    private var BrandCode:String? = nil
    
    //sku对应的商户
    private var MerchantId:Int? = nil
    private var MerchantCode:String? = nil
    
    //浏览sku时搜索词
    private var KeywordHash:String? = nil
    private var Keyword:String? = nil

    private var LastCreated:Int64? = nil
    private var LastModified:Int64? = nil
}
