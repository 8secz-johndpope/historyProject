//
//  CheckoutMerchantData.swift
//  merchant-ios
//
//  Created by Stephen Yuen on 29/8/2016.
//  Copyright © 2016 WWE & CO. All rights reserved.
//

import Foundation

class CheckoutSection {
    
    enum SectionType: Int {
        case unknown = 0
        case style
        case color
        case size
        case fullStyle
        case otherMerchantInformation
        case otherInformation
        case mmCoupon
    }
    
    var sectionType: SectionType = .unknown
    var styleIndex = 0
    var checkoutItems: [CheckoutItem] = []
    var merchantDataIndex = 0
    
    init(sectionType: SectionType, merchantDataIndex: Int = 0, styleIndex: Int = 0) {
        self.sectionType = sectionType
        self.merchantDataIndex = merchantDataIndex
        self.styleIndex = styleIndex
    }
}

class CheckoutItem {
    
    enum ItemType: Int {
        case unknown = 0
        case style
        case color
        case size
        case quantity
        case address
        case paymentMethod
        case shippingFee
        case merchantCoupon
        case mmCoupon
        case fapiao
        case fullAddress
        case prc //PRC ID
        case fullPaymentMethod
        case fullStyle
        case merchantTotal
        case comments
    }
    
    var itemType: ItemType = .unknown
    var itemIndex = 0
    
    init(itemType: ItemType, itemIndex: Int = 0) {
        self.itemType = itemType
        self.itemIndex = itemIndex
    }
}

class CheckoutMerchantData {
    enum SectionPosition: Int {
        case header = 0
        case normal
        case footer
    }
    
    var merchant: Merchant?
    var styles: [Style] = []
    var merchantCoupon: Coupon?
    var fapiaoText: String?
    var comment: String?
    var allowedRequestFapiao = false
    var enabledFapiao = false
    var merchantDataIndex = 0
    var sectionPosition: SectionPosition = .normal
    
    var checkoutMode: CheckoutMode = .unknown
    
    var checkoutSections: [CheckoutSection] = []
    
    init(checkoutMode: CheckoutMode, sectionPosition: SectionPosition = .normal) {
        self.checkoutMode = checkoutMode
        self.sectionPosition = sectionPosition
        
        updateCheckoutItems()
    }
    
    init(merchant: Merchant?, styles: [Style], fapiaoText: String?, checkoutMode: CheckoutMode, merchantDataIndex: Int = 0, sectionPosition: SectionPosition = .normal) {
        self.merchant = merchant
        self.styles = styles
        self.fapiaoText = fapiaoText
        self.checkoutMode = checkoutMode
        self.merchantDataIndex = merchantDataIndex
        self.sectionPosition = sectionPosition
        
        if let merchant = merchant {
            allowedRequestFapiao = !merchant.isCrossBorder
        }
        
        updateCheckoutItems()
    }
    
    func updateCheckoutItems() {
        checkoutSections.removeAll()
        
        // Deselect inactive or out of stock items
        for style in styles {			
            if !style.isValid() || style.isOutOfStock() {
                style.selected = false
            }
        }
        
        switch checkoutMode {
        case .updateStyle:
            if let style = styles.first {
                if showColorListForStyle(style) {
                    let colorSection = CheckoutSection(sectionType: .color)
                    
                    for i in 0..<style.validColorList.count {
                        colorSection.checkoutItems.append(CheckoutItem(itemType: .color, itemIndex: i))
                    }
                    
                    checkoutSections.append(colorSection)
                }
                
                if showSizeListForStyle(style) {
                    let sizeSection = CheckoutSection(sectionType: .size)
                    
                    for i in 0..<style.validSizeList.count {
                        sizeSection.checkoutItems.append(CheckoutItem(itemType: .size, itemIndex: i))
                    }
                    
                    checkoutSections.append(sizeSection)
                }
            }
            
            let checkoutSection = CheckoutSection(sectionType: .otherInformation)
            checkoutSection.checkoutItems.append(CheckoutItem(itemType: .quantity))
            checkoutSections.append(checkoutSection)
        case .style, .cartItem:
            // [.Color, .Size, .Quantity, .Address, .PaymentMethod, .ShippingFee, .MerchantCoupon, .MMCoupon, .Fapiao]
            
            if let style = styles.first {
                if showColorListForStyle(style) {
                    let colorSection = CheckoutSection(sectionType: .color)
                    
                    for i in 0..<style.validColorList.count {
                        colorSection.checkoutItems.append(CheckoutItem(itemType: .color, itemIndex: i))
                    }
                    
                    checkoutSections.append(colorSection)
                }
                
                if showSizeListForStyle(style) {
                    let sizeSection = CheckoutSection(sectionType: .size)
                    
                    for i in 0..<style.validSizeList.count {
                        sizeSection.checkoutItems.append(CheckoutItem(itemType: .size, itemIndex: i))
                    }
                    
                    checkoutSections.append(sizeSection)
                }
            }
            
            let otherInformationSection = CheckoutSection(sectionType: .otherInformation)
            
            otherInformationSection.checkoutItems.append(CheckoutItem(itemType: .quantity))
//            otherInformationSection.checkoutItems.append(CheckoutItem(itemType: .Address))
//            otherInformationSection.checkoutItems.append(CheckoutItem(itemType: .PaymentMethod))
//            otherInformationSection.checkoutItems.append(CheckoutItem(itemType: .ShippingFee))
//            otherInformationSection.checkoutItems.append(CheckoutItem(itemType: .MerchantCoupon))
//            otherInformationSection.checkoutItems.append(CheckoutItem(itemType: .MMCoupon))
//            
//            if allowedRequestFapiao {
//                otherInformationSection.checkoutItems.append(CheckoutItem(itemType: .Fapiao))
//            }
            
            checkoutSections.append(otherInformationSection)
 
        case .multipleMerchant:
            switch sectionPosition {
            case .normal:
                // [.Style, .Color, .Size, .ShippingFee, .MerchantCoupon, .Fapiao]
                
                for i in 0..<styles.count {
                    let styleSection = CheckoutSection(sectionType: .style, merchantDataIndex: merchantDataIndex, styleIndex: i)
                    styleSection.checkoutItems.append(CheckoutItem(itemType: .style))
                    checkoutSections.append(styleSection)

                    if showColorListForStyle(styles[i]) {
                        let colorSection = CheckoutSection(sectionType: .color, merchantDataIndex: merchantDataIndex, styleIndex: i)
                        
                        for j in 0..<styles[i].validColorList.count {
                            colorSection.checkoutItems.append(CheckoutItem(itemType: .color, itemIndex: j))
                        }
                        
                        checkoutSections.append(colorSection)
                    }

                    if showSizeListForStyle(styles[i]) {
                        let sizeSection = CheckoutSection(sectionType: .size, merchantDataIndex: merchantDataIndex, styleIndex: i)
                        
                        for j in 0..<styles[i].validSizeList.count {
                            sizeSection.checkoutItems.append(CheckoutItem(itemType: .size, itemIndex: j))
                        }
                        
                        checkoutSections.append(sizeSection)
                    }
                }
                /*
                let otherMerchantInformationSection = CheckoutSection(sectionType: .OtherMerchantInformation, merchantDataIndex: merchantDataIndex)
                
                otherMerchantInformationSection.checkoutItems.append(CheckoutItem(itemType: .ShippingFee))
                otherMerchantInformationSection.checkoutItems.append(CheckoutItem(itemType: .MerchantCoupon))
                
                if allowedRequestFapiao {
                    otherMerchantInformationSection.checkoutItems.append(CheckoutItem(itemType: .Fapiao))
                }
                
                checkoutSections.append(otherMerchantInformationSection)
            case .Footer:
                let footerSection = CheckoutSection(sectionType: .OtherInformation, merchantDataIndex: merchantDataIndex)
                
                footerSection.checkoutItems.append(CheckoutItem(itemType: .Address))
                footerSection.checkoutItems.append(CheckoutItem(itemType: .PaymentMethod))
                footerSection.checkoutItems.append(CheckoutItem(itemType: .MMCoupon))
                
                checkoutSections.append(footerSection)
 */
            default:
                break
            }
        case .cartCheckout:
            switch sectionPosition {
            case .header:
                let headerSection = CheckoutSection(sectionType: .otherInformation, merchantDataIndex: merchantDataIndex)
                headerSection.checkoutItems.append(CheckoutItem(itemType: .fullAddress))
                checkoutSections.append(headerSection)
            case .normal:
                // [.FullStyle, .Fapiao, .ShippingFee, .MerchantCoupon, .MerchantTotal, .Comments]
                
                for i in 0..<styles.count {
                    let styleSection = CheckoutSection(sectionType: .fullStyle, merchantDataIndex: merchantDataIndex, styleIndex: i)
                    styleSection.checkoutItems.append(CheckoutItem(itemType: .fullStyle))
                    checkoutSections.append(styleSection)
                }
                
                let otherMerchantInformationSection = CheckoutSection(sectionType: .otherMerchantInformation, merchantDataIndex: merchantDataIndex)
                
                if allowedRequestFapiao {
                    otherMerchantInformationSection.checkoutItems.append(CheckoutItem(itemType: .fapiao))
                }
                
                otherMerchantInformationSection.checkoutItems.append(CheckoutItem(itemType: .shippingFee))
                otherMerchantInformationSection.checkoutItems.append(CheckoutItem(itemType: .merchantCoupon))
                otherMerchantInformationSection.checkoutItems.append(CheckoutItem(itemType: .merchantTotal))
                otherMerchantInformationSection.checkoutItems.append(CheckoutItem(itemType: .comments))
                
                checkoutSections.append(otherMerchantInformationSection)
 
            case .footer:
                
                let mmCouponSection = CheckoutSection(sectionType: .mmCoupon, merchantDataIndex: merchantDataIndex)
                mmCouponSection.checkoutItems.append(CheckoutItem(itemType: .mmCoupon))
                checkoutSections.append(mmCouponSection)
                
                let footerSection = CheckoutSection(sectionType: .otherInformation, merchantDataIndex: merchantDataIndex)
                footerSection.checkoutItems.append(CheckoutItem(itemType: .fullPaymentMethod))

                checkoutSections.append(footerSection)
            }
        default:
            break
        }
    }
    
    func getMerchantTotal(includeShipmentFee: Bool, includeCoupon: Bool, qty: Int = 1, parentOrder: ParentOrder?) -> Double {
        guard let parentOrder = parentOrder else {return 0}
        if (qty == 0) { return 0 }
        var merchantTotal: Double = 0
        merchantTotal = parentOrder.grandTotal
        var hasSelectedStyle = false
        
        for style in styles where style.selected {
            hasSelectedStyle = true
        }

        if !hasSelectedStyle { return 0 }
        
        if let merchant = merchant, includeShipmentFee && hasSelectedStyle && (merchantTotal < Double(merchant.freeShippingThreshold) || !merchant.isFreeShippingEnabled()) {
            if (!includeShipmentFee){
                let filterOrder = parentOrder.orders?.filter{$0.merchantId == merchant.merchantId}
                if let _filterOrder = filterOrder{
                    if _filterOrder.count > 0 {
                        let order = _filterOrder[0]
                        merchantTotal -= Double(order.shippingFee)
                    }
                }
            }
        }
        
//        if let currentMerchantCoupon = merchantCoupon, includeCoupon && currentMerchantCoupon.minimumSpendAmount <= merchantTotal {
//            merchantTotal -= currentMerchantCoupon.couponAmount
//        }
        
        return merchantTotal
    }
    
    func getMerchantTotal(includeShipmentFee: Bool, includeCoupon: Bool, selectedSkus: [Sku], parentOrder: ParentOrder?, isFlashSale:Bool = false) -> Double {
        var merchantTotal: Double = 0
        for style in styles {
            let sku = style.searchSkuIdAndColorKey(style.selectedSizeId, colorKey: style.selectedColorKey)
            if let sku = sku {
                merchantTotal += sku.price(isFlashSale) * Double(sku.qty)
            } else {
                ErrorLogManager.sharedManager.recordNonFatalError(withException: .NullPointer)
            }
        }
        
        if let merchant = merchant, includeShipmentFee && (merchantTotal < Double(merchant.freeShippingThreshold) || !merchant.isFreeShippingEnabled()) {
            merchantTotal += merchant.shippingFee
        }
        return merchantTotal
    }
    
    func toggleStyle(atIndex index: Int) {
        if index >= 0 && index < styles.count {
            styles[index].selected = !styles[index].selected
        }
    }
    
    func showColorListForStyle(_ style: Style) -> Bool {
        return !style.isEmptyColorList() && !style.isOutOfStock() && style.isValid()
    }
    
    func showSizeListForStyle(_ style: Style) -> Bool {
        return !style.isEmptySizeList() && !style.isOutOfStock() && style.isValid()
    }
    
}
