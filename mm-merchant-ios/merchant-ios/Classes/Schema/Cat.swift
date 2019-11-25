//
//  Cat.swift
//  merchant-ios
//
//  Created by Koon Kit Chan on 18/11/15.
//  Copyright © 2015 Koon Kit Chan. All rights reserved.
//

import Foundation
import ObjectMapper
import HandyJSON

class Cat: Mappable, Equatable, HandyJSON {
    
    static func ==(lhs: Cat, rhs: Cat) -> Bool {
        return lhs.categoryId == rhs.categoryId
    }
    
    var categoryBrandMerchantList: [BrandUnionMerchant] = []
    var categoryCode = ""
    var categoryId = 0
    var categoryImage = ""
    var categoryList: [Cat]?
    var categoryName = ""
    var categoryNameOrigin = ""
    var categoryNameInvariant = ""
    var featuredImage = ""
    var isMerchCanSelect = 0
    var parentCategoryId = 0
    var priority = 0
    var sizeGridImage = ""
    var sizeGridImageInvariant = ""
    var statusId = 0
    var isMale = 0
    var isFemale = 0
    var selected = false
    var isShow = 0 //0:不显示 1:显示, 判断当前的cat的是否有categorylist数据 或者产品数量
    var defaultCommissionRate = 0.0
    var level = 0
    
    var isSelected = false {
        didSet {
            if isSelected {
                for subCat in categoryList ?? [] {
                    subCat.isSelected = isSelected
                }
            }
        }
    }
    
    required convenience init?(map: Map) {
        self.init()
    }
    
    required init() {}
    
    // Mappable
    func mapping(map: Map) {
        categoryBrandMerchantList   <- map["CategoryBrandMerchantList"]
        categoryCode                <- map["CategoryCode"]
        categoryId                  <- map["CategoryId"]
        categoryImage               <- map["CategoryImage"]
        categoryList                <- map["CategoryList"]
        categoryName                <- map["CategoryName"]
        categoryNameOrigin          <- map["CategoryName"]
        categoryNameInvariant       <- map["CategoryNameInvariant"]
        featuredImage               <- map["FeaturedImage"]
        isMerchCanSelect            <- map["IsMerchCanSelect"]
        parentCategoryId            <- map["ParentCategoryId"]
        priority                    <- map["Priority"]
        sizeGridImage               <- map["SizeGridImage"]
        sizeGridImageInvariant      <- map["SizeGridImageInvariant"]
        statusId                    <- map["StatusId"]
        isMale                      <- map["IsMale"]
        isFemale                    <- map["IsFemale"]
        defaultCommissionRate       <- map["DefaultCommissionRate"]
        level                       <- map["Level"]
        isShow                      <- map["isShow"]
        
    }
    
    
    var CategoryId: Int?
    var CategoryCode: String?
    var CategoryImage: String?
    var CategoryName: String?
    var CategoryNameInvariant: String?
    var FeaturedImage: String?
    var ParentCategoryId: Int?
    var SizeGridImage: String?
    var SizeGridImageInvariant: String?
    var StatusId: Int?
    var IsMale: Int?
    var IsFemale: Int?
    
    private func copyCategoryName(from:Cat, to:Cat) {
        to.isSelected = false // 保证isselected为初始值
        guard let flist = from.categoryList, let tlist = to.categoryList else { return }
        for idx in 0..<tlist.count {
            if idx >= flist.count {
                return
            }
            copyCategoryName(from: flist[idx], to: tlist[idx])
        }
    }
    
    func clone() -> Cat?{
        var c = Cat()
        Injects.fill(origin: self, obj: &c)
        copyCategoryName(from: self, to: c)
        return c
    }
    
    func checkSelected() -> Bool {
        if categoryList == nil || categoryList?.count == 0 {
            return isSelected
        }
        
        for subCat in categoryList! {
            if !subCat.isSelected{
                isSelected = false
                return false
            }
        }
        
        isSelected = true
        return true
    }
    
    func isActive() -> Bool {
        return statusId == 2
    }
    
    func equal(_ cat: Cat?) -> Bool{
        if let strongCat = cat{
            guard strongCat.categoryId == self.categoryId else {
                return false
            }
            
            guard strongCat.categoryList?.count == self.categoryList?.count else {
                return false
            }
            
            for subCat in strongCat.categoryList ?? []{
                let filteredCats = self.categoryList?.filter{$0.categoryId == subCat.categoryId}
                if filteredCats?.count != 1{
                    return false
                }
            }
            
            return true
        }
        
        return false
    }
}
