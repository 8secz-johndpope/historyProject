//
//  CheckoutCouponCell.swift
//  merchant-ios
//
//  Created by Sang Nguyen on 7/6/16.
//  Copyright © 2016 WWE & CO. All rights reserved.
//

import Foundation

class CheckoutCouponCell: UICollectionViewCell {
    
    static let CellIdentifier = "CheckoutCouponCellID"
    
    private final let LeftMargin: CGFloat = 20
    private final let RightMargin: CGFloat = 10
    
    var leftLabel = UILabel()
    var couponNameLabel = UILabel()
    var priceLabel = UILabel()
    var redDotView = UIView()

    private var separatorView = UIView()
    private var arrowView = UIImageView()
    
    private final let Spacing: CGFloat = 10
    private final var ArrowWidth: CGFloat = 32
    
    private var coupon: Coupon?
    private var isFullSeparator = false
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        
        leftLabel.formatSize(15)
        self.contentView.addSubview(leftLabel)
        
        redDotView.backgroundColor = .red
        redDotView.isHidden = true
        contentView.addSubview(redDotView)
        
        couponNameLabel.formatSize(15)
        couponNameLabel.textAlignment = .right
        self.contentView.addSubview(couponNameLabel)
        
        priceLabel.formatSize(15)
        priceLabel.textColor = UIColor.primary1()
        self.contentView.addSubview(priceLabel)
        
        arrowView.image = UIImage(named: "icon_arrow_small")
        arrowView.contentMode = .scaleAspectFit
        self.contentView.addSubview(arrowView)
        
        separatorView.backgroundColor = UIColor.backgroundGray()
        self.contentView.addSubview(self.separatorView)
        
        self.separatorView.isHidden = true
    }
    
    override func layoutSubviews() {
        super.layoutSubviews()
        
        let width = StringHelper.getTextWidth(leftLabel.text ?? "", height: frame.height, font: self.leftLabel.font)
        leftLabel.frame = CGRect(x: LeftMargin, y: 0, width: width, height: frame.height)
        
        redDotView.frame = CGRect(x: leftLabel.frame.maxX + 10, y: leftLabel.frame.midY - 3, width: 6, height: 6)
        redDotView.round()

        arrowView.frame = CGRect(x: frame.width - (ArrowWidth + 20 / 2), y: (frame.height - ArrowWidth) / 2, width: ArrowWidth, height: ArrowWidth)
        
        let priceWidth = StringHelper.getTextWidth(priceLabel.text ?? "", height: frame.height, font: self.priceLabel.font)
        var min_x = arrowView.frame.minX
        if (ArrowWidth == 0){
            min_x -= 10
        }
        priceLabel.frame = CGRect(x: min_x - priceWidth, y: 0, width: priceWidth, height: frame.height)
        couponNameLabel.frame = CGRect(x: redDotView.frame.maxX + Spacing, y: 0, width: priceLabel.frame.minX - (redDotView.frame.maxX + Spacing), height: frame.height)
        
        let separatorLeftMargin = isFullSeparator ? 0 : LeftMargin
        let separatorRightMargin = isFullSeparator ? 0 : RightMargin
        
        separatorView.frame = CGRect(x: separatorLeftMargin, y: frame.height - 1, width: frame.width - separatorLeftMargin - separatorRightMargin, height: 1)
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    func setStyle(withSeparator hasSeparator: Bool = true, isFullSeparator: Bool = false) {
        self.isFullSeparator = isFullSeparator
        
        separatorView.isHidden = !hasSeparator
    }

    func setData(_ coupon: Coupon?) {
        self.coupon = coupon
        
        if let strongCoupon = coupon {
            self.couponNameLabel.text = strongCoupon.couponName + ": "
            let price = strongCoupon.couponAmount
            let stringPrice = price.formatPrice() ?? ""
            self.priceLabel.text = "-" + stringPrice
        } else {
            self.couponNameLabel.text = ""
            self.priceLabel.text = ""
        }
        
        self.layoutSubviews()
    }
    
    func setUnpaidCoupon(couponName: String, price: Double) {
        if (couponName.count > 0 || price > 0 ) {
            self.couponNameLabel.text = couponName + ": "
            let price = price
            let stringPrice = price.formatPrice() ?? ""
            self.priceLabel.text = "-" + stringPrice
        } else {
            self.couponNameLabel.text = ""
            self.priceLabel.text = ""
        }
        ArrowWidth = 0
        
        self.layoutSubviews()
    }
    
    func setDataByParentOrder(_ parentOrder: ParentOrder?) {
        if let _parentOrder = parentOrder {
            //self.couponNameLabel.text = strongCoupon.couponName + ": "
            self.couponNameLabel.text = ""
            let price = _parentOrder.mmCouponAmount
            let stringPrice = price.formatPrice() ?? ""
            self.priceLabel.text = "-" + stringPrice
        } else {
            self.couponNameLabel.text = ""
            self.priceLabel.text = ""
        }
        arrowView.isHidden = true
        self.layoutSubviews()
    }
    
    func setDataByOrder(_ order: Order?) {
        if let _order = order {
            //self.couponNameLabel.text = strongCoupon.couponName + ": "
            self.couponNameLabel.text = ""
            let price = _order.couponAmount
            let stringPrice = price.formatPrice() ?? ""
            self.priceLabel.text = "-" + stringPrice
        } else {
            self.couponNameLabel.text = ""
            self.priceLabel.text = ""
        }
        arrowView.isHidden = true
        self.layoutSubviews()
    }

}
