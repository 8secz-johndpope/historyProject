//
//  PriceHelper.swift
//  merchant-ios
//
//  Created by Vu Dinh Trung on 5/19/16.
//  Copyright © 2016 WWE & CO. All rights reserved.
//

import UIKit

class PriceHelper {
    
    class func getFormattedPriceText(withRetailPrice retailPrice: Double, salePrice: Double, isSale: Int, hasValidCoupon: Bool = false,sameColor: Bool = false,retailPriceFontSize: CGFloat = 10, salePriceFontSize: CGFloat = 14, retailPriceWithSaleFontColor: UIColor = UIColor.secondary2(), isBoldSalePriceFont: Bool = false, otherContent: Bool = false,content: String = "",imageName: String = "") -> NSMutableAttributedString {

        var _isSale = isSale
        if (salePrice == 0) {
            _isSale = 0
        }
        let priceText = NSMutableAttributedString()
        
        if(hasValidCoupon){
            let attachment: NSTextAttachment = NSTextAttachment()
            attachment.image = UIImage(named: "coupon_stamp")
            if let image = attachment.image{
                attachment.bounds = CGRect(x: 0, y: -3, width: image.size.width, height: image.size.height);
            }

            let attachmentString: NSAttributedString = NSAttributedString(attachment: attachment)
            
            let paraStyle = NSMutableParagraphStyle()
            paraStyle.lineBreakMode = .byTruncatingTail
            paraStyle.alignment = .center
            
            if otherContent{
                attachment.image = UIImage(named: imageName)
                if let image = attachment.image{
                    attachment.bounds = CGRect(x: 0, y: -2, width: image.size.width, height: image.size.height);
                }
                priceText.append(attachmentString)
                let spacing = NSAttributedString(string: " ")
                priceText.append(spacing)
            }else{
                let spacing = NSAttributedString(string: " ")
                priceText.append(spacing)
                priceText.append(attachmentString)
            }
        }
        
        let retailPriceFont = isBoldSalePriceFont ? UIFont.boldSystemFont(ofSize: retailPriceFontSize) : UIFont.systemFont(ofSize: retailPriceFontSize)
        let salePriceFont = UIFont.systemFont(ofSize: salePriceFontSize)
        
        if _isSale > 0 {
            if let formattedSalePrice = salePrice.formatPrice() {
                let saleText = NSAttributedString(
                    string: formattedSalePrice + " ",
                    attributes: [
                        NSAttributedStringKey.foregroundColor: UIColor.primary3(),
                        NSAttributedStringKey.font: salePriceFont,
                        NSAttributedStringKey.strikethroughStyle: NSUnderlineStyle.styleNone.rawValue
                    ]
                )
                
                priceText.append(saleText)
            }
            
            if let formattedRetailPrice = retailPrice.formatPrice() {
                let retailText = NSAttributedString(
                    string: formattedRetailPrice,
                    attributes: [
                        NSAttributedStringKey.foregroundColor: retailPriceWithSaleFontColor,
                        NSAttributedStringKey.strikethroughStyle: NSUnderlineStyle.styleSingle.rawValue,
                        NSAttributedStringKey.font: retailPriceFont,
                        NSAttributedStringKey.baselineOffset: (salePriceFont.capHeight - retailPriceFont.capHeight) / 2
                    ]
                )
                
                priceText.append(retailText)
            }
        } else {
            var contentStr = retailPrice.formatPrice()
            if otherContent{
                contentStr = content
            }
            
            var retailPriceColor = retailPriceWithSaleFontColor
            
            if sameColor {
                retailPriceColor = UIColor.primary3()
            }
            
            if let formattedRetailPrice = contentStr {
                let retailText = NSAttributedString(
                    string: formattedRetailPrice,
                    attributes: [
                        NSAttributedStringKey.foregroundColor: retailPriceColor,
                        NSAttributedStringKey.font: salePriceFont,
                        NSAttributedStringKey.attachment:NSTextAlignment.left
                    ]
                )
                
                priceText.append(retailText)
            }
        }
        
        return priceText
    }
    
    class func fillPrice(_ priceSales: Double, priceRetail: Double, isSale: Int, hasValidCoupon: Bool = false, otherContent: Bool = false,content: String = "",imageName: String = "", salePriceFontSize: CGFloat = 14,sameColor: Bool = false) -> NSMutableAttributedString {
        return getFormattedPriceText(withRetailPrice: priceRetail, salePrice: priceSales, isSale: isSale, hasValidCoupon: hasValidCoupon,sameColor: sameColor,salePriceFontSize:salePriceFontSize, otherContent:otherContent,content:content,imageName:imageName)
    }
    
    class func calculatedPrice(_ priceSales: Double, priceRetail: Double, isSale: Int) -> Double {
        return isSale > 0 ? priceSales : priceRetail
    }
    
}
