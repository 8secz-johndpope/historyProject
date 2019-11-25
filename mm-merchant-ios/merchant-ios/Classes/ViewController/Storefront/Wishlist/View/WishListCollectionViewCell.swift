//
//  WishListCollectionViewCell.swift
//  merchant-ios
//
//  Created by khanh.nguyen on 12/21/16.
//  Copyright © 2016 WWE & CO. All rights reserved.
//

import UIKit

class WishListCollectionViewCell: WishListSelectionCollectionViewCell {
    
    var style: Style?
    
    override func layoutSubviews() {
        super.layoutSubviews()
        
        let rightPadding = CGFloat(5)
        let leftPadding = CGFloat(20)
        self.productImageView.frame.originX = self.tickImageView.frame.maxX + leftPadding
        
        let xPos = self.productImageView.frame.maxX + leftPadding
        
        self.brandImageView.frame.originX = xPos
        self.productNameLabel.frame.originX = xPos
        self.productNameLabel.frame.sizeWidth = self.frame.sizeWidth - xPos - rightPadding
        self.productPriceLabel.frame.originX = xPos
        self.productPriceLabel.frame.sizeWidth = self.frame.sizeWidth - xPos - rightPadding
    }
    
    func setStyle(_ style: Style, styleFilter: StyleFilter) {
        self.style = style
        
        var skuFiltering: Sku? = nil
        var selectedSizeId = 0
        var colorKey = ""
        
        if !styleFilter.colors.isEmpty {
            if let color = styleFilter.colors.first {
                if let key = style.findSuitableImageKey(color.colorId) {
                    colorKey = key
                } else {
                    ErrorLogManager.sharedManager.recordNonFatalError(withException: .NullPointer)
                }
            } else {
                ErrorLogManager.sharedManager.recordNonFatalError(withException: .NullPointer)
            }
        }
        
        if !styleFilter.sizes.isEmpty {
            if let size = styleFilter.sizes.first {
                selectedSizeId = size.sizeId
            } else {
                ErrorLogManager.sharedManager.recordNonFatalError(withException: .NullPointer)
            }
        }
        
        if !colorKey.isEmptyOrNil() && selectedSizeId != 0 {
            skuFiltering = style.searchSkuIdAndColorKey(selectedSizeId, colorKey: colorKey)
        }
        
        if let defaultSku = style.defaultSku() {
            if skuFiltering == nil {
                skuFiltering = defaultSku
            }
            
            if colorKey.isEmptyOrNil() {
                colorKey = defaultSku.colorKey
            }
            
            self.productNameLabel.text =  defaultSku.skuName
            
            ProductManager.setProductImage(imageView: self.productImageView, style: style, colorKey: colorKey, placeholderImage: nil, completion: { (image, error) -> Void in
                
            })
        } else {
            ErrorLogManager.sharedManager.recordNonFatalError(withException: .NullPointer)
        }
        
        if skuFiltering != nil {
            self.fillPrice(skuFiltering!.priceSale, priceRetail: skuFiltering!.priceRetail, isSale: skuFiltering!.isOnSale().hashValue)
        }
        
        self.brandImageView.mm_setImageWithURL(
            ImageURLFactory.URLSize512(style.brandHeaderLogoImage, category: .brand), placeholderImage: UIImage(named: "holder"), contentMode: .scaleAspectFit, completion: { (image, error, cacheType, imageURL) -> () in
                if let image = image {
                    let imageWidth = image.size.width
                    let imageHeight = image.size.height
                    let imageRatio = imageWidth / imageHeight
                    
                    self.brandImageView.frame = CGRect(x:self.brandImageView.frame.origin.x, y: self.brandImageView.frame.origin.y, width: self.brandImageView.frame.size.height * imageRatio, height: self.brandImageView.frame.size.height)
                } else {
                    ErrorLogManager.sharedManager.recordNonFatalError(withException: .NullPointer)
                }
            }
        )
    }
}
