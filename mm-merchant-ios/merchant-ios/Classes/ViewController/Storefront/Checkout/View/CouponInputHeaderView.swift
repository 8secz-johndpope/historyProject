//
//  CouponInputHeaderView.swift
//  merchant-ios
//
//  Created by Sang Nguyen on 7/6/16.
//  Copyright © 2016 WWE & CO. All rights reserved.
//

import Foundation


class CouponInputHeaderView: UICollectionReusableView {
    
    enum ImageStyle: Int {
        case square = 0
        case long
    }
    
    static let ViewIdentifier = "CouponInputHeaderViewID"
    
    var imageView = UIImageView()
    var couponTitle = UILabel()
    let couponButtonView = UIButton()
    var seperateView = UIView()
    var borderView = UIView()
    
    var imageStyle: ImageStyle = .square
    
    var isFirst = true {
        didSet{
            layoutSubviews()
        }
    }

    private final let MarginLeft: CGFloat = 15
    private final let LogoVerticalMargin: CGFloat = 12
    
    var viewCouponHandler: (() -> Void)?

    override init(frame: CGRect) {
        super.init(frame: frame)
        
        seperateView.backgroundColor = UIColor.backgroundGray()
        addSubview(seperateView)
        
        backgroundColor = UIColor.white
        addSubview(imageView)
        
        couponTitle.formatSize(15)
        addSubview(couponTitle)
        
        borderView.backgroundColor = UIColor.secondary1()
        addSubview(borderView)
        
        couponButtonView.setTitle(String.localize("LB_CA_CART_MERC_COUPON_LIST"), for: UIControlState())
        couponButtonView.titleLabel?.font = UIFont.systemFont(ofSize: 13)
        couponButtonView.setTitleColor(UIColor.primary1(), for: UIControlState())
        couponButtonView.addTarget(self, action: #selector(showMerchantCouponList), for: .touchUpInside)
        addSubview(couponButtonView)

        layoutSubviews()
    }
    
    override func layoutSubviews() {
        super.layoutSubviews()
        
        var seperateViewHeight: CGFloat = 0
        if(!isFirst) {
            seperateViewHeight = 15
        }
        
        let logoHeight = frame.height - (LogoVerticalMargin * 2)
        let logoWidth: CGFloat = (imageStyle == .square) ? logoHeight : 80
        
        seperateView.frame = CGRect(x: 0, y: 0, width: frame.size.width, height: seperateViewHeight)
        
        imageView.frame = CGRect(x: MarginLeft, y: bounds.midY - logoHeight / 2 + seperateViewHeight, width: logoWidth, height: logoHeight - seperateViewHeight)
        
        let couponButtonWidth = CGFloat(55)
        couponButtonView.frame = CGRect(x: frame.width - couponButtonWidth, y: seperateViewHeight , width: couponButtonWidth, height: frame.height - seperateViewHeight)

        couponTitle.frame = CGRect(x: imageView.frame.maxX + MarginLeft , y: seperateViewHeight , width: couponButtonView.frame.minX - (imageView.frame.maxX + MarginLeft) , height: bounds.height - seperateViewHeight)

        borderView.frame = CGRect(x: bounds.minX, y: bounds.maxY - 1, width: bounds.width, height: 1)
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    func setImage(_ key : String, imageCategory : ImageCategory ){
        imageView.mm_setImageWithURL(ImageURLFactory.URLSize128(key, category: imageCategory), placeholderImage : UIImage(named: "holder"), contentMode: UIViewContentMode.scaleAspectFit)
    }
    
    func setMerchantData(_ merchant: CartMerchant?) {
        if let strongMerchant = merchant {
            self.setImage(strongMerchant.merchantImage, imageCategory: ImageCategory.merchant)
            self.couponTitle.text = strongMerchant.merchantName
        } else {
            self.imageView.image = nil
            self.couponTitle.text = ""
        }
    }
    
    func setMerchantModel(_ merchant: Merchant?) {
        if let strongMerchant = merchant {
            self.setImage(strongMerchant.headerLogoImage, imageCategory: ImageCategory.merchant)
            self.couponTitle.text = strongMerchant.merchantName
        } else {
            self.imageView.image = nil
            self.couponTitle.text = ""
        }
    }
    
    func setMmData() {
        self.imageView.image = UIImage(named: "MM_icon")
        self.couponTitle.text = String.localize("LB_MYMM")
    }
    
    @objc func showMerchantCouponList() {
        viewCouponHandler?()
    }
}
