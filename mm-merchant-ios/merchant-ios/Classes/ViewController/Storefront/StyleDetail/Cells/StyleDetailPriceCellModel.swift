//
//  StyleDetailPriceCellModel.swift
//  storefront-ios
//
//  Created by Leslie Zhang on 17/09/2018.
//  Copyright © 2018 WWE & CO. All rights reserved.
//

import UIKit

class StyleDetailPriceCellModel: StyleDetailCellModel {
    override init() {
        super.init()
        
    }
    
    func ssn_cellClass(_ cellID: String, isFloating: Bool) -> AnyClass {
        return StyleDetailPriceCell.self
    }
    public var slectSku: Sku?
    public var retailPrice: String?
    public var price: String?
    public var style:Style? {
        didSet {
            if let style = style {
                if let sku = slectSku {
                    let selectedSizeId = sku.sizeId
                    let selectedColorId = sku.colorId
                    let selectedColorKey = sku.colorKey
                    
                    var retailPrice: Double = 0
                    var salePrice: Double = 0
                    let selectedSkuColor = style.findSkuColorFromColorKey(selectedColorKey)
                    if selectedColorId > 0 && selectedSizeId > 0 && selectedSkuColor.length > 0 {
                        if let sku = style.searchSku(selectedSizeId, colorId: selectedColorId, skuColor: selectedSkuColor) {
                            retailPrice = sku.priceRetail
                            if sku.isOnSale() {
                                salePrice = sku.priceSale
                            }
                        }
                    }
                    
                    if retailPrice <= 0 && salePrice <= 0 {
                        if let sku = style.defaultSku() {
                            retailPrice = sku.priceRetail
                            if sku.isOnSale() {
                                salePrice = sku.priceSale
                            }
                        }
                    }
                    
                    if salePrice <= 0 && retailPrice > 0 {
                        salePrice = retailPrice
                        retailPrice = 0
                    }
                    
                    if retailPrice > 0 {
                        self.retailPrice = retailPrice.formatPrice()
                        self.cellHeight = 36 + 28
                    } else {
                        self.cellHeight = 36
                    }
                    self.price = salePrice.formatPrice()
                }
            }
        }
    }
}
