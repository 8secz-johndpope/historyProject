//
//  FreeShipHeader.swift
//  merchant-ios
//
//  Created by Vu Dinh Trung on 7/21/16.
//  Copyright © 2016 WWE & CO. All rights reserved.
//

import UIKit

class FreeShipFooter: UICollectionReusableView {
    
    static let FreeShipFooterId = "FreeShipFooterId"
    var descriptionLabel : UILabel!
    
    private final let HeightLabel = CGFloat(15)
    var separatorView = UIView()
    
    var merchant: Merchant? {
        didSet {
            let freeShippingThreshold = merchant?.freeShippingThreshold
            let freeShippingFrom = merchant?.freeShippingFrom
            let freeShippingTo = merchant?.freeShippingTo
            let shippingFee = merchant?.shippingFee
            let isFreeShippingEnabled = merchant?.isFreeShippingEnabled() ?? false
            var freeShippingPeriod = ""
            
            if !isFreeShippingEnabled {
                descriptionLabel.text = "" // no free shipping is always overridden
                return
            }
            
            if shippingFee == 0 {
                descriptionLabel.text = String.localize("LB_CA_ALL_FREE_SHIPPING") // free shipping is always overridden
                return
            }
            
            var withinDateRange = false
            
            if let _ = freeShippingFrom, let freeShippingTo = freeShippingTo {
                let freeShippingFromDateComponents = (Calendar.current as NSCalendar).components([.day, .month, .year], from: freeShippingFrom! as Date)
                let freeShippingToDateComponents = (Calendar.current as NSCalendar).components([.day, .month, .year], from: freeShippingTo as Date)
                
                freeShippingPeriod = String.localize("LB_CA_FREE_SHIPPING_PERIOD").replacingOccurrences(of: "{FreeShippingStartMonthInAlphabet}", with: "\(freeShippingFromDateComponents.month ?? 0)")
                freeShippingPeriod = freeShippingPeriod.replacingOccurrences(of: "{FreeShippingStartDayInAlphabet}", with: "\(freeShippingFromDateComponents.day ?? 0)")
                freeShippingPeriod = freeShippingPeriod.replacingOccurrences(of: "{FreeShippingEndMonthInAlphabet}", with: "\(freeShippingToDateComponents.month ?? 0)")
                freeShippingPeriod = freeShippingPeriod.replacingOccurrences(of: "{FreeShippingEndDayInAlphabet}", with: "\(freeShippingToDateComponents.day ?? 0)")
                
                let today = Date()
                if freeShippingFrom! <= today && today <= freeShippingTo {
                    withinDateRange = true
                }
            }
            
            let locale = Locale(identifier: "zh_Hans_CN")
            let currencySymbol = (locale as NSLocale).object(forKey: NSLocale.Key.currencySymbol) as! String
            var freeShippingAmount = ""
            
            if freeShippingThreshold != nil {
                freeShippingAmount = currencySymbol + "\(freeShippingThreshold!)"
            }
            
            if withinDateRange {
                if freeShippingThreshold == 0 {
                    descriptionLabel.text = freeShippingPeriod + String.localize("LB_CA_ALL_FREE_SHIPPING")
                }else {
                    descriptionLabel.text = freeShippingPeriod + String.localize("LB_CA_FREE_SHIPPING_MIN_AMT").replacingOccurrences(of: "{FreeShippingMinOrderAmount}", with: freeShippingAmount)
                }
            }else {
                descriptionLabel.text = String.localize("LB_CA_FREE_SHIPPING_MIN_AMT").replacingOccurrences(of: "{FreeShippingMinOrderAmount}", with: freeShippingAmount)
            }
           
        }
    }
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        backgroundColor = UIColor.white
        
        let descripLabel = { () -> UILabel in
            let leftRightPadding: CGFloat = 15
            let label = UILabel(frame: CGRect(x: leftRightPadding , y: (bounds.height - HeightLabel)/2, width: bounds.width - 2 * leftRightPadding, height: HeightLabel))
            descriptionLabel = label
            return label
        }()
        descriptionLabel.formatSize(14)
        descripLabel.textColor = UIColor.secondary7()
        addSubview(descripLabel)
        
        separatorView.backgroundColor = UIColor.clear
        addSubview(separatorView)
    }
    
    override func layoutSubviews() {
        super.layoutSubviews()
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    func setSeparatorStyle(_ separatorStyle: CheckoutFooterView.SeparatorStyle, withColor color: UIColor = UIColor.backgroundGray()) {
        var marginLeft: CGFloat = 0
        var marginRight: CGFloat = 0
        
        separatorView.backgroundColor = color
        
        switch separatorStyle {
        case .none:
            separatorView.isHidden = true
        case .full:
            separatorView.isHidden = false
        case .singleItem:
            marginLeft = Margin.left
            marginRight = Margin.left
            separatorView.isHidden = false
        case .multipleItem:
            marginLeft = FCheckoutViewController.MultipleMerchantSizeEdgeInsets.left
            marginRight = Margin.left
            separatorView.isHidden = false
        }
        
        separatorView.frame = CGRect(x: marginLeft, y: frame.height - 1, width: frame.width - marginLeft - marginRight, height: Constants.Separator.BoldThickness)
        
        layoutSubviews()
    }
    
}
