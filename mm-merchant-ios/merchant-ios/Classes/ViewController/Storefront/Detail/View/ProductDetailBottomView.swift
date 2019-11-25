//
//  ProductDetailBottomView.swift
//  merchant-ios
//
//  Created by Jerry Chong on 20/9/2017.
//  Copyright © 2017 WWE & CO. All rights reserved.
//

import Foundation
import SnapKit

class ProductDetailBottomView: UIView {
    static let DefaultHeight: CGFloat = 115
    private let ButtonWidth: CGFloat = 110
    private var isFlash:Bool = false
    var cartNumber:Int? {
        didSet {
            if let number = cartNumber {
                upDartNumberLabelFrame(number: number)
            }
        }
    }
    
    var buyTapHandler: (() -> Void)?
    var addtocartTapHandler: (() -> Void)?
    var buyFlashSaleHandler: (() -> Void)?
    var csTapHandler: (() -> Void)?
    var postTapHandler: (() -> Void)?
    var wishTapHandler: (() -> Void)?

    private let buyButton: UIButton = {
        let button = UIButton()
        button.layer.cornerRadius = 0
        button.titleLabel?.font = UIFont.systemFontWithSize(14)
        button.backgroundColor = UIColor.primary1()
        button.titleLabel?.textColor = UIColor.white
        button.setTitle(String.localize("LB_CA_CHECKOUT"), for: UIControlState())
        button.tag = 0
        return button
    }()
    
    let addCartButton: UIButton = {
        let button = UIButton()
        button.layer.cornerRadius = 0
        button.backgroundColor = UIColor.secondary2()
        button.layer.borderColor = UIColor.secondary2().cgColor
        button.titleLabel?.font = UIFont.systemFontWithSize(14)
        button.titleLabel?.textColor = UIColor.white
        button.setTitle(String.localize("LB_CA_ADD2CART"), for: UIControlState())
        button.tag = 1
        return button
    }()
    
    let buyFlashSaleButton: UIButton = {
        let button = UIButton()
        button.layer.cornerRadius = 0
        button.titleLabel?.font = UIFont.systemFontWithSize(14)
        button.backgroundColor = UIColor.primary1()
        button.titleLabel?.textColor = UIColor.white
        button.setTitle(String.localize("LB_CA_NEWBIEPRICE_PDP_BUY_NOW"), for: UIControlState())
        button.isHidden = true
        return button
    }()
    
    private let iconCSButton: IconButtonView = {
        let view = IconButtonView()
        view.iconDimension = 30
        view.setType(IconButtonView.ButtonType.cs)
        return view
    }()
    
    private let iconPostButton: IconButtonView = {
        let view = IconButtonView()
        view.setType(IconButtonView.ButtonType.cart)
        let l = UILabel()
       
        view.addSubview(l)
        return view
    }()
    
    lazy var cartNumberLabel: UILabel = {
        let cartNumberLabel = UILabel()
        cartNumberLabel.font = UIFont.regularFontWithSize(size: 8)
        cartNumberLabel.textAlignment = .center
        cartNumberLabel.textColor = UIColor.white
        cartNumberLabel.backgroundColor = UIColor.primary1()
        cartNumberLabel.round(6)
        cartNumberLabel.isHidden = false
        return cartNumberLabel
    }()
    
    let iconWishButton: IconButtonView = {
        let view = IconButtonView()
        view.setType(IconButtonView.ButtonType.wish)
        return view
    }()
    
    private let topLine: UIView = {
        let view = UIView()
        view.backgroundColor = UIColor.secondary1()
        return view
    }()

    override init(frame: CGRect) {
        super.init(frame: frame)
        
        let buttonWidth = ScreenWidth - (ButtonWidth * 2)
        let iconWidth = buttonWidth / 3
        
        self.backgroundColor = UIColor.white
        self.clipsToBounds = true
        
        addSubview(buyButton)
        addSubview(addCartButton)
        addSubview(buyFlashSaleButton)
        addSubview(iconCSButton)
        addSubview(iconPostButton)
        iconPostButton.addSubview(cartNumberLabel)
        addSubview(iconWishButton)
        addSubview(topLine)
        
        iconCSButton.snp.makeConstraints { [weak self] (target) in
            guard let strongSelf = self else {
                return
            }
            target.top.equalTo(strongSelf.snp.top).offset(0)
            target.bottom.equalTo(strongSelf.snp.bottom).offset(-0)
            target.left.equalTo(strongSelf.snp.left).offset(0)
            target.width.equalTo(iconWidth)
        }
        
        
        iconPostButton.snp.makeConstraints { [weak self] (target) in
            guard let strongSelf = self else {
                return
            }
            target.top.equalTo(strongSelf.snp.top).offset(0)
            target.bottom.equalTo(strongSelf.snp.bottom).offset(-0)
            target.left.equalTo(strongSelf.iconWishButton.snp.right).offset(0)
            target.width.equalTo(iconWidth)
        }
        
        
        iconWishButton.snp.makeConstraints { [weak self] (target) in
            guard let strongSelf = self else {
                return
            }
            target.top.equalTo(strongSelf.snp.top).offset(0)
            target.bottom.equalTo(strongSelf.snp.bottom).offset(-0)
            target.left.equalTo(strongSelf.iconCSButton.snp.right).offset(0)
            target.width.equalTo(iconWidth)
        }
        
        buyButton.snp.makeConstraints { [weak self] (target) in
            guard let strongSelf = self else {
                return
            }
            target.top.equalTo(strongSelf.snp.top).offset(0)
            target.bottom.equalTo(strongSelf.snp.bottom).offset(-ScreenBottom)
            target.right.equalTo(strongSelf.snp.right).offset(0)
            target.width.equalTo(strongSelf.ButtonWidth)
        }
        
        addCartButton.snp.makeConstraints { [weak self] (target) in
            guard let strongSelf = self else {
                return
            }
            target.top.equalTo(strongSelf.snp.top).offset(0)
            target.bottom.equalTo(strongSelf.snp.bottom).offset(-ScreenBottom)
            target.right.equalTo(strongSelf.buyButton.snp.left).offset(0)
            target.width.equalTo(strongSelf.ButtonWidth)
        }
        
        buyFlashSaleButton.snp.makeConstraints { [weak self] (target) in
            guard let strongSelf = self else {
                return
            }
            target.top.equalTo(strongSelf.snp.top).offset(0)
            target.bottom.equalTo(strongSelf.snp.bottom).offset(-ScreenBottom)
            target.right.equalTo(strongSelf.snp.right).offset(0)
            target.left.equalTo(strongSelf.addCartButton.snp.left).offset(0)
            target.width.equalTo(strongSelf.ButtonWidth*2)
        }
        
        topLine.snp.makeConstraints { [weak self] (target) in
            guard let strongSelf = self else {
                return
            }
            target.top.equalTo(strongSelf.snp.top).offset(0)
            target.right.equalTo(strongSelf.snp.right).offset(0)
            target.left.equalTo(strongSelf.snp.left).offset(0)
            target.height.equalTo(0.5)
        }
        
        setEnable(true)
        
        actionControl()
        
        upDartNumberLabelFrame(number: CacheManager.sharedManager.numberOfCartItems())
    }
    
    func setLike(_ liked: Bool){
        if(liked){
            iconWishButton.iconImageView.image = UIImage(named: "star_red")
            iconWishButton.iconTextLabel.text = String.localize("LB_CA_PROFILE_COLLECTION_COLLECTED")
            let wishListAnimation = WishListAnimation(heartImage: iconWishButton.iconImageView, redDotButton: nil)
            wishListAnimation.showAnimationforsmallimage(completion: {
            })

        }else{
            iconWishButton.iconImageView.image = UIImage(named: "star_profile")
            iconWishButton.iconTextLabel.text = String.localize("LB_BOOKMARK")
        }
        
    }
    
    private func actionControl(){
        iconCSButton.tapHandler = {
            if let callback = self.csTapHandler {
                callback()
            } else {
                ErrorLogManager.sharedManager.recordNonFatalError(withException: .NullPointer)
            }
        }
        iconPostButton.tapHandler = {
            if let callback = self.postTapHandler {
                callback()
            } else {
                ErrorLogManager.sharedManager.recordNonFatalError(withException: .NullPointer)
            }
        }
        iconWishButton.tapHandler = {
            if let callback = self.wishTapHandler {
                callback()
            } else {
                ErrorLogManager.sharedManager.recordNonFatalError(withException: .NullPointer)
            }
        }

        buyButton.addTarget(self, action: #selector(actionTap), for: .touchUpInside)
        addCartButton.addTarget(self, action: #selector(actionTap), for: .touchUpInside)
        buyFlashSaleButton.addTarget(self, action: #selector(actionTap), for: .touchUpInside)
    }
    
    @objc private func actionTap(_ sender: UIButton){
        if (sender == buyButton){
            if let callback = self.buyTapHandler {
                callback()
            } else {
                ErrorLogManager.sharedManager.recordNonFatalError(withException: .NullPointer)
            }
        } else if sender == addCartButton {
            if let callback = self.addtocartTapHandler {
                callback()
            } else {
                ErrorLogManager.sharedManager.recordNonFatalError(withException: .NullPointer)
            }
        } else if sender == buyFlashSaleButton {
            if self.isFlash {
                if let callback = self.buyFlashSaleHandler {
                    callback()
                } else {
                    ErrorLogManager.sharedManager.recordNonFatalError(withException: .NullPointer)
                }
            } else {
                if let callback = self.addtocartTapHandler {
                    callback()
                } else {
                    ErrorLogManager.sharedManager.recordNonFatalError(withException: .NullPointer)
                }
            }
        }
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    private func upDartNumberLabelFrame(number:Int)  {
        var strNumber = ""
        let cartNumber = number
        if cartNumber > 0 {
            strNumber = "\(cartNumber)"
            cartNumberLabel.text = "\(cartNumber)"
            cartNumberLabel.isHidden = false
        } else {
            cartNumberLabel.isHidden = true
        }
        var textWidth = strNumber.getTextWidth(height: 12, font: UIFont.regularFontWithSize(size: 8))
        textWidth = textWidth == 0 ? 0 : textWidth + 6
        cartNumberLabel.frame = CGRect(x:(ScreenWidth - (110 * 2)) / 3 - 22, y: 3, width: textWidth >= 12 ? textWidth : 12 , height: 12)
    }
    
    func setEnable(_ isEnable: Bool){
        if (isEnable) {
            buyButton.isUserInteractionEnabled = true
            addCartButton.isUserInteractionEnabled = true
            buyButton.backgroundColor = UIColor.primary1()
            addCartButton.backgroundColor = UIColor.secondary2()
            buyFlashSaleButton.backgroundColor = UIColor.primary1()
            buyFlashSaleButton.isUserInteractionEnabled = true
        }else{
            buyButton.isUserInteractionEnabled = false
            addCartButton.isUserInteractionEnabled = false
            buyButton.backgroundColor = UIColor.primary1_disable()
            addCartButton.backgroundColor = UIColor.secondary1()
            buyFlashSaleButton.backgroundColor = UIColor.secondary1()
            buyFlashSaleButton.isUserInteractionEnabled = false
        }
        iconCSButton.setEnable(isEnable)
//        iconPostButton.setEnable(isEnable)
//        iconWishButton.setEnable(isEnable)
        
    }
    
    func disableBuyAndAddToCart() {
        
        buyButton.isUserInteractionEnabled = false
        addCartButton.isUserInteractionEnabled = false
        buyButton.backgroundColor = UIColor.primary1_disable()
        addCartButton.backgroundColor = UIColor.secondary1()
        iconCSButton.setEnable(true)
        iconPostButton.setEnable(true)
        iconWishButton.setEnable(true)
    }
    
    func setIsFlashSale(_ isFlash: Bool) {
        addCartButton.isHidden = true
        buyButton.isHidden = true
        buyFlashSaleButton.isHidden = false
        self.isFlash = isFlash
        if isFlash {
            buyFlashSaleButton.setTitle(String.localize("LB_CA_NEWBIEPRICE_PDP_BUY_NOW"), for: UIControlState())
        } else {
            buyFlashSaleButton.setTitle(String.localize("LB_CA_ADD2CART"), for: UIControlState())
        }
    }
}

class IconButtonView: UIView {
    var iconDimension: CGFloat = 13
    enum ButtonType: Int {
        case cs = 0
        case post
        case wish
        case share
        case cart
    }
    
    var tapHandler: (() -> Void)?
    
    private let touchTransparentButton: UIButton = {
        let button = UIButton()
        button.backgroundColor = UIColor.clear
        button.layer.borderWidth = 0
        return button
    }()
    
    let iconImageView: UIImageView = {
        let imageView = UIImageView()
        imageView.backgroundColor = UIColor.clear
        imageView.layer.borderWidth = 0
        imageView.contentMode = .scaleAspectFit
        imageView.clipsToBounds = false
        return imageView
    }()
    
    let iconTextLabel: UILabel = {
        let label = UILabel()
        label.text = ""
        label.formatSize(10)
        label.textColor = UIColor.secondary2()
        label.textAlignment = .center
        return label
    }()
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        
        addSubview(iconImageView)
        addSubview(iconTextLabel)
        addSubview(touchTransparentButton)
        
        touchTransparentButton.addTarget(self, action: #selector(actionTap), for: .touchUpInside)
    }
    
    override func layoutSubviews() {
        super.layoutSubviews()
        
        iconImageView.snp.remakeConstraints { [weak self] (target) in
            guard let strongSelf = self else {
                return
            }
            let widthImage: CGFloat = 18
            target.height.equalTo(18)
            target.width.equalTo(widthImage)
            target.top.equalTo(strongSelf.snp.top).offset(5)
            target.left.equalTo(strongSelf.snp.left).offset((strongSelf.frame.sizeWidth - widthImage)/2)
            target.centerX.equalToSuperview()
        }
        
        iconTextLabel.snp.remakeConstraints { [weak self] (target) in
            guard let strongSelf = self else {
                return
            }
            target.top.equalTo(strongSelf.iconImageView.snp.bottom).offset(4)
            target.centerX.equalToSuperview()
            target.height.equalTo(15)
        }
        
        touchTransparentButton.snp.remakeConstraints { [weak self] (target) in
            guard let strongSelf = self else {
                return
            }
            target.top.equalTo(strongSelf.snp.top).offset(0)
            target.bottom.equalTo(strongSelf.snp.bottom).offset(-0)
            target.left.equalTo(strongSelf.snp.left).offset(0)
            target.right.equalTo(strongSelf.snp.right).offset(0)
        }
    }
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    
    @objc private func actionTap(_ sender: UIButton){
        if let callback = self.tapHandler {
            callback()
        } else {
            ErrorLogManager.sharedManager.recordNonFatalError(withException: .NullPointer)
        }
    }
    
    func setType(_ type: ButtonType){
        switch type {
        case .cart:
            iconImageView.image = UIImage(named: "pdp-cart")
            iconImageView.image = iconImageView.image!.withRenderingMode(UIImageRenderingMode.alwaysTemplate)
            iconImageView.tintColor = UIColor.secondary2()
            
            iconTextLabel.text = String.localize("LB_CA_CART")
        case .cs:
            iconImageView.image = UIImage(named: "pdp_cs")
            iconImageView.image = iconImageView.image!.withRenderingMode(UIImageRenderingMode.alwaysTemplate)
            iconImageView.tintColor = UIColor.secondary2()
            
            iconTextLabel.text = String.localize("LB_CS")
        case .post:
            iconImageView.image = UIImage(named: "camera_black")
            iconTextLabel.text = String.localize("LB_EXCL_POST")
        case .wish:
            iconImageView.image = UIImage(named: "star_pdp")
            iconTextLabel.text = String.localize("LB_BOOKMARK")
        case .share:
            iconImageView.snp.makeConstraints { [weak self] (target) in
                guard let strongSelf = self else {
                    return
                }
                target.height.width.equalTo(strongSelf.iconDimension)
                target.top.equalTo(strongSelf.snp.top).offset(15)
                target.centerX.equalTo(0)
            }
            iconImageView.image = UIImage(named: "share_pdp")
            iconTextLabel.text = String.localize("LB_CA_SHARE")
            iconTextLabel.formatSize(12)
        }
    }
    
    func setEnable(_ isEnable: Bool){
        if (isEnable) {
            touchTransparentButton.isUserInteractionEnabled = true
        }else{
            touchTransparentButton.isUserInteractionEnabled = false
        }
    }
    

}
