//
//  OrderItemPriceCell.swift
//  merchant-ios
//
//  Created by Gambogo on 3/31/16.
//  Copyright © 2016 WWE & CO. All rights reserved.
//

import Foundation

class OrderItemPriceCell: UICollectionViewCell {
    
    enum PriceItem: Int {
        case shippingCost = 0
        case merchantCoupon
        case mmCoupon
        case additionalCharge
        case orderDiscount
    }
    
    static let CellIdentifier = "OrderItemPriceCellID"
    static let DefaultHeight: CGFloat = 175
    
    static let LabelHeight: CGFloat = 20
    
    private var separateViewTop = UIView()
    private var shippingCostTitleLabel = UILabel()
    private var shippingCostValueLabel = UILabel()
    private var merchantDiscountTitleLabel = UILabel()
    private var merchantDiscountValueLabel = UILabel()
    private var mmDiscountTitleLabel = UILabel()
    private var mmDiscountValueLabel = UILabel()
    private var additionalChargeTitleLabel = UILabel()
    private var additionalChargeValueLabel = UILabel()
    private var orderDiscountTitleLabel = UILabel()
    private var orderDiscountValueLabel = UILabel()
    private var separateViewTotal = UIView()
    private var subTotalTitleLabel = UILabel()
    private var subTotalValueLabel = UILabel()
    
    var data: OrderPriceData? {
        didSet {
            if let data = self.data {
                shippingCostValueLabel.text = data.shippingCost
                subTotalValueLabel.text = data.grandTotal
                merchantDiscountValueLabel.text = data.merchantCouponAmount
                mmDiscountValueLabel.text = data.mmCouponAmount
                additionalChargeValueLabel.text = data.additionalCharge
                orderDiscountValueLabel.text = data.orderDiscount
                
                var priceItems: [OrderItemPriceCell.PriceItem] = []
                
                if data.merchantCouponAmount == "" {
                    priceItems.append(.merchantCoupon)
                }
                
                if data.mmCouponAmount == "" {
                    priceItems.append(.mmCoupon)
                }
                
                if data.additionalCharge == "" {
                    priceItems.append(.additionalCharge)
                }
                
                if data.orderDiscount == "" {
                    priceItems.append(.orderDiscount)
                }
                
                self.hideItems(priceItems)
            } else {
                ErrorLogManager.sharedManager.recordNonFatalError(withException: .NullPointer)
            }
        }
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        
        self.backgroundColor = UIColor.clear
        
        //Separate line
        separateViewTop.backgroundColor = UIColor.secondary1()
        self.contentView.addSubview(separateViewTop)
        
        separateViewTotal.backgroundColor = UIColor.secondary1()
        self.contentView.addSubview(separateViewTotal)
        
        shippingCostTitleLabel.formatSize(12)
        shippingCostTitleLabel.textColor = UIColor.secondary2()
        shippingCostTitleLabel.text = String.localize("LB_CA_OMS_SHIPPING_COST")
        self.contentView.addSubview(shippingCostTitleLabel)
        
        shippingCostValueLabel.formatSizeBold(13)
        shippingCostValueLabel.textColor = UIColor.secondary2()
        shippingCostValueLabel.textAlignment = .right
        self.contentView.addSubview(shippingCostValueLabel)
        
        merchantDiscountTitleLabel.formatSize(12)
        merchantDiscountTitleLabel.textColor = UIColor.secondary2()
        merchantDiscountTitleLabel.text = String.localize("LB_CA_OMS_MERCHANT_COUPON")
        self.contentView.addSubview(merchantDiscountTitleLabel)
        
        merchantDiscountValueLabel.formatSizeBold(13)
        merchantDiscountValueLabel.textColor = UIColor.primary1()
        merchantDiscountValueLabel.textAlignment = .right
        self.contentView.addSubview(merchantDiscountValueLabel)
        
        mmDiscountTitleLabel.formatSize(12)
        mmDiscountTitleLabel.textColor = UIColor.secondary2()
        mmDiscountTitleLabel.text = String.localize("LB_CA_OMS_MM_COUPON")
        self.contentView.addSubview(mmDiscountTitleLabel)
        
        mmDiscountValueLabel.formatSizeBold(13)
        mmDiscountValueLabel.textColor = UIColor.primary1()
        mmDiscountValueLabel.textAlignment = .right
        self.contentView.addSubview(mmDiscountValueLabel)
        
        additionalChargeTitleLabel.formatSize(12)
        additionalChargeTitleLabel.textColor = UIColor.secondary2()
        additionalChargeTitleLabel.text = String.localize("LB_CA_OMS_EXTRA_CHARGE")
        self.contentView.addSubview(additionalChargeTitleLabel)
        
        additionalChargeValueLabel.formatSizeBold(13)
        additionalChargeValueLabel.textColor = UIColor.secondary2()
        additionalChargeValueLabel.textAlignment = .right
        self.contentView.addSubview(additionalChargeValueLabel)
        
        orderDiscountTitleLabel.formatSize(12)
        orderDiscountTitleLabel.textColor = UIColor.secondary2()
        orderDiscountTitleLabel.text = String.localize("LB_CA_OMS_DISCOUNT")
        self.contentView.addSubview(orderDiscountTitleLabel)
        
        orderDiscountValueLabel.formatSizeBold(13)
        orderDiscountValueLabel.textColor = UIColor.primary1()
        orderDiscountValueLabel.textAlignment = .right
        self.contentView.addSubview(orderDiscountValueLabel)
        
        subTotalTitleLabel.formatSize(12)
        subTotalTitleLabel.textColor = UIColor.secondary2()
        subTotalTitleLabel.text = String.localize("LB_CA_OMS_GRAND_TOTAL")
        self.contentView.addSubview(subTotalTitleLabel)
        
        subTotalValueLabel.formatSizeBold(13)
        subTotalValueLabel.textColor = UIColor.primary1()
        subTotalValueLabel.textAlignment = .right
        self.contentView.addSubview(subTotalValueLabel)
    }
    
    override func layoutSubviews() {
        super.layoutSubviews()
        
        updateFrameViews()
    }
    
    func updateFrameViews() {
        let horizontalPadding: CGFloat = 20
        let labelWidth = (frame.width - (horizontalPadding * 2)) / 2
        let paddingLine: CGFloat = 9
        
        var offsetY: CGFloat = 10
        
        separateViewTop.frame = CGRect(x: paddingLine, y: 0, width: frame.width - 2 * paddingLine, height: 1)
        
        shippingCostTitleLabel.frame = CGRect(x: horizontalPadding, y: offsetY, width: labelWidth, height: OrderItemPriceCell.LabelHeight)
        shippingCostValueLabel.frame = CGRect(x: shippingCostTitleLabel.frame.maxX, y: offsetY, width: labelWidth, height: OrderItemPriceCell.LabelHeight)
        offsetY += OrderItemPriceCell.LabelHeight
        
        if !merchantDiscountTitleLabel.isHidden {
            merchantDiscountTitleLabel.frame = CGRect(x: horizontalPadding, y: offsetY, width: labelWidth, height: OrderItemPriceCell.LabelHeight)
            merchantDiscountValueLabel.frame = CGRect(x: merchantDiscountTitleLabel.frame.maxX, y: offsetY, width: labelWidth, height: OrderItemPriceCell.LabelHeight)
            offsetY += OrderItemPriceCell.LabelHeight
        }

        if !mmDiscountTitleLabel.isHidden {
            mmDiscountTitleLabel.frame = CGRect(x: horizontalPadding, y: offsetY, width: labelWidth, height: OrderItemPriceCell.LabelHeight)
            mmDiscountValueLabel.frame = CGRect(x: mmDiscountTitleLabel.frame.maxX, y: offsetY, width: labelWidth, height: OrderItemPriceCell.LabelHeight)
            offsetY += OrderItemPriceCell.LabelHeight
        }
        
        if !additionalChargeTitleLabel.isHidden {
            additionalChargeTitleLabel.frame = CGRect(x: horizontalPadding, y: offsetY, width: labelWidth, height: OrderItemPriceCell.LabelHeight)
            additionalChargeValueLabel.frame = CGRect(x: additionalChargeTitleLabel.frame.maxX, y: offsetY, width: labelWidth, height: OrderItemPriceCell.LabelHeight)
            offsetY += OrderItemPriceCell.LabelHeight
        }
        
        if !orderDiscountTitleLabel.isHidden {
            orderDiscountTitleLabel.frame = CGRect(x: horizontalPadding, y: offsetY, width: labelWidth, height: OrderItemPriceCell.LabelHeight)
            orderDiscountValueLabel.frame = CGRect(x: orderDiscountTitleLabel.frame.maxX, y: offsetY, width: labelWidth, height: OrderItemPriceCell.LabelHeight)
            offsetY += OrderItemPriceCell.LabelHeight
        }
        
        offsetY += 10
        
        separateViewTotal.frame = CGRect(x: paddingLine, y: offsetY, width: frame.width - 2 * paddingLine, height: 1)
        offsetY += 10
        
        subTotalTitleLabel.frame = CGRect(x: horizontalPadding, y: offsetY, width: labelWidth, height: OrderItemPriceCell.LabelHeight)
        subTotalValueLabel.frame = CGRect(x: subTotalTitleLabel.frame.maxX, y: offsetY, width: labelWidth, height: OrderItemPriceCell.LabelHeight)
    }
    
    // MARK: - View
    
    func hideItems(_ priceItems: [PriceItem]) {
        for priceItem in priceItems {
            switch priceItem {
            case .shippingCost:
                shippingCostTitleLabel.isHidden = true
                shippingCostValueLabel.isHidden = true
            case .merchantCoupon:
                merchantDiscountTitleLabel.isHidden = true
                merchantDiscountValueLabel.isHidden = true
            case .mmCoupon:
                mmDiscountTitleLabel.isHidden = true
                mmDiscountValueLabel.isHidden = true
            case .additionalCharge:
                additionalChargeTitleLabel.isHidden = true
                additionalChargeValueLabel.isHidden = true
            case .orderDiscount:
                orderDiscountTitleLabel.isHidden = true
                orderDiscountValueLabel.isHidden = true
            }
        }
        
        updateFrameViews()
    }
    
    static func getHeight(hasMMCoupon: Bool, hasMerchantCoupon: Bool, hasAdditionalCharge: Bool, hasOrderDiscount: Bool) -> CGFloat {
        var height = OrderItemPriceCell.DefaultHeight
        
        if !hasMMCoupon {
            height -= OrderItemPriceCell.LabelHeight
        }
        
        if !hasMerchantCoupon {
            height -= OrderItemPriceCell.LabelHeight
        }
        
        if !hasAdditionalCharge {
            height -= OrderItemPriceCell.LabelHeight
        }
        
        if !hasOrderDiscount {
            height -= OrderItemPriceCell.LabelHeight
        }
        
        return height
    }
}
