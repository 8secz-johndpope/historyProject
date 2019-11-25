//
//  CartSkuModel.swift
//  storefront-ios
//
//  Created by Kam on 4/9/2018.
//  Copyright © 2018 WWE & CO. All rights reserved.
//

import UIKit
import HandyJSON

class CartSkuModel: DBModel {
    var ssn_rowid: Int64 = 0
    
    var skuId: Int {
        get { return SkuId ?? 0 }
        set { SkuId = newValue }
    }
    var styleId: Int {
        get { return StyleId ?? 0 }
        set { StyleId = newValue }
    }
    var styleCode: String {
        get { return StyleCode ?? "" }
        set { StyleCode = newValue }
    }
    var merchantId: Int {
        get { return MerchantId ?? 0 }
        set { MerchantId = newValue }
    }
    var merchantCode: String {
        get { return MerchantCode ?? "" }
        set { MerchantCode = newValue }
    }
    var brandId: Int {
        get { return BrandId ?? 0 }
        set { BrandId = newValue }
    }
    var brandCode: String {
        get { return BrandCode ?? "" }
        set { BrandCode = newValue }
    }
    var syncOpt: Int {
        get { return SyncOpt ?? 0 }
        set { SyncOpt = newValue }
    }
    var lastCreated:Int64 {
        get { return LastCreated ?? 0 }
        set { LastCreated = newValue }
    }
    var lastModified:Int64 {
        get { return LastModified ?? 0 }
        set { LastModified = newValue }
    }
    
    required init() {}
    
    convenience init(skuId: Int, styleCode: String, brandId: Int, brandCode: String, merchantId: Int, lastModified: String) {
        self.init()
        //        self.Hashkey = keyword.ssn_md5()
        self.SkuId = skuId
        self.StyleId = styleId
        self.StyleCode = styleCode
        
        self.BrandId = brandId
        self.BrandCode = brandCode
        
        self.MerchantId = merchantId
        //existing bad design for cartItem, should be in date rather than string
        let date = DateTransformExtension().transformFromJSON(lastModified) ?? Date()
        self.LastModified = Int64(date.timeIntervalSince1970)
    }
    // 实际库字段
    
    private var SkuId: Int? = nil
    private var StyleId: Int? = nil
    private var StyleCode: String? = nil
    private var MerchantId: Int? = nil
    private var MerchantCode: String? = nil
    private var BrandId: Int? = nil
    private var BrandCode: String? = nil
    private var SyncOpt: Int? = nil // 操作数 用于以后的数据同步
    private var LastCreated: Int64? = nil
    private var LastModified: Int64? = nil
    
    static func selectCartItemBy(brandId: Int) -> CartSkuModel? {
        let tb = getWishTable()
        let results = tb.objects(CartSkuModel.self, conditions: ["BrandId": brandId], sort:NSSortDescriptor(key: "LastModified", ascending: false))
        return results.first
    }
    
    static func truncate() {
        let table = getWishTable()
        table.truncate()
    }
    
    static func insertToTable<S: Sequence>(objects: S) where S.Iterator.Element : HandyJSON {
        let tb = getWishTable()
        tb.upinsert(objects: objects)
    }
    
    static func deleteToTable<S: Sequence>(objects: S) where S.Iterator.Element : HandyJSON {
        let tb = getWishTable()
        tb.delete(objects: objects)
    }
    
    private static func getWishTable() -> DBTable {
        return DBUtil.table("shopping_cart")
    }
    
}
