//
//  CheckoutInfoCell.swift
//  merchant-ios
//
//  Created by hungvo on 1/19/16.
//  Copyright © 2016 WWE & CO. All rights reserved.
//

import UIKit
import Alamofire

class CheckoutInfoCell: UICollectionViewCell {
    
    static let CellIdentifier = "CheckoutInfoCellID"
    
    private final let PaddingLeft: CGFloat = 10
    private final let CheckboxContainerWidth: CGFloat = 39
    private final let PlaceholderImage = UIImage(named: "holder")
    
    var productSelectionView = UIView()
    private var productImageView = UIImageView()
    private var brandNameLabel = UILabel()
    private var productNameLabel = UILabel()
    private var priceLabel = UILabel()
    private var separatorView = UIView()
    private var productSelectionButton: UIButton?
    private var itemDisabledLabel: UILabel?
    private var couponButtonView: UIButton?
    var shouldHaveCouponButton = false
    var isFlashSaleEligible = false //是否存在需要检查新人限购活动
    
    lazy var flashSaleFirstImageView:UIImageView = {
        let flashSaleFirstImageView = UIImageView()
        flashSaleFirstImageView.image = UIImage.init(named: "newbie2_tag")
        flashSaleFirstImageView.sizeToFit()
        flashSaleFirstImageView.isHidden = true
        return flashSaleFirstImageView
    }()
    
    lazy var flashSaleSecondImageView:UIImageView = {
        let flashSaleSecondImageView = UIImageView()
        flashSaleSecondImageView.image = UIImage.init(named: "only2_tag")
        flashSaleSecondImageView.sizeToFit()
        flashSaleSecondImageView.isHidden = true
        return flashSaleSecondImageView
    }()
    
    private var style: Style?
    
    var itemSelectHandler: ((Style) -> ())?
    var viewCouponHandler: (() -> Void)?

    init(frame: CGRect, haveCouponButton: Bool? = false) {
        super.init(frame: frame)
        shouldHaveCouponButton = haveCouponButton ?? false
        initialization()
    }
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        initialization()
    }
    
    func initialization() {
        contentView.backgroundColor = UIColor.white
        clipsToBounds = true
        
        productSelectionView.backgroundColor = UIColor.clear
        let singleTap = UITapGestureRecognizer(target: self, action: #selector(CheckoutInfoCell.toggleItem))
        productSelectionView.addGestureRecognizer(singleTap)
        contentView.addSubview(productSelectionView)
        
        productImageView.image = UIImage(named: "Spacer")
        productImageView.contentMode = .scaleAspectFit
        productImageView.clipsToBounds = true
        productImageView.layer.borderColor = UIColor.lightGray.cgColor
//        productImageView.layer.borderWidth = 0.5
//        productImageView.layer.cornerRadius = 3
        contentView.addSubview(productImageView)
        
        brandNameLabel.formatSize(13)
        brandNameLabel.lineBreakMode = .byTruncatingTail
        brandNameLabel.numberOfLines = 2
        brandNameLabel.textColor = UIColor.secondary7()
        contentView.addSubview(brandNameLabel)
        
        productNameLabel.formatSize(14)
        productNameLabel.lineBreakMode = .byTruncatingTail
        productNameLabel.numberOfLines = 2
        productNameLabel.textColor = UIColor.black
        contentView.addSubview(productNameLabel)
        
        contentView.addSubview(priceLabel)
        contentView.addSubview(flashSaleFirstImageView)
        contentView.addSubview(flashSaleSecondImageView)
        
        separatorView.backgroundColor = UIColor.backgroundGray()
        contentView.addSubview(separatorView)
        
        if shouldHaveCouponButton {
            couponButtonView = { () -> UIButton in
                let button = UIButton(type: .custom)
                button.setTitle(String.localize("LB_CA_CART_MERC_COUPON_LIST"), for: UIControlState())
                button.titleLabel?.font = UIFont.systemFont(ofSize: 13)
                button.setTitleColor(UIColor.primary1(), for: UIControlState())
                button.addTarget(self, action: #selector(showMerchantCouponList), for: .touchUpInside)
                addSubview(button)
                
                return button
            }()
        }
        
        layoutSubviews()
    }
    
    override func layoutSubviews() {
        super.layoutSubviews()
        
        var paddingTop: CGFloat = 10
        if productSelectionButton != nil {
            paddingTop = 15
        }
        let paddingRight: CGFloat = 15
        
        let productImageViewHeight = CGFloat(frame.height - (2 * paddingTop) - 6)
        let productImageViewWidth = productImageViewHeight / Constants.Ratio.ProductImageHeight
        
        let brandLabelHeight: CGFloat = 24
        let productLabelHeight: CGFloat = 24
        let priceLabelHeight: CGFloat = 20
        let ySpacing: CGFloat = 1.5
        var separatorViewMarginLeft: CGFloat = 15
        
        var productImageViewX = PaddingLeft
        
        if productSelectionButton != nil {
            productImageViewX += CheckboxContainerWidth
        }
        
        
        productSelectionView.frame = CGRect(x: frame.minX, y: paddingTop, width: productImageViewX, height: productImageViewHeight)
        
        productImageView.frame = CGRect(x: productImageViewX, y: paddingTop, width: productImageViewWidth, height: productImageViewHeight)

        let xPos = CGFloat(productImageView.frame.maxX + paddingRight)
        
        if shouldHaveCouponButton {
            let couponButtonSize = CGSize(width: 55, height: 30)
            couponButtonView!.frame = CGRect(x: frame.width - couponButtonSize.width, y: paddingTop, width: couponButtonSize.width, height: couponButtonSize.height)
        }

        brandNameLabel.frame = CGRect(x: xPos, y: paddingTop, width: (shouldHaveCouponButton ? couponButtonView!.frame.minX : frame.width) - xPos - paddingRight, height: brandLabelHeight)
        productNameLabel.frame = CGRect(x: xPos, y: brandNameLabel.frame.maxY + ySpacing, width: frame.width - xPos - paddingRight, height: productLabelHeight)
        priceLabel.frame = CGRect(x: xPos, y: productNameLabel.frame.maxY + ySpacing, width: frame.width - xPos - paddingRight, height: priceLabelHeight)
        if productSelectionButton != nil {
            separatorViewMarginLeft = 50
        }
        flashSaleFirstImageView.frame = CGRect(x: xPos, y: priceLabel.frame.maxY + ySpacing, width: flashSaleFirstImageView.size.width, height: flashSaleFirstImageView.size.height)
        
        flashSaleSecondImageView.frame = CGRect(x: flashSaleFirstImageView.frame.maxX + 8, y: priceLabel.frame.maxY + ySpacing, width: flashSaleSecondImageView.size.width, height: flashSaleSecondImageView.size.height)
        
        
        separatorView.frame = CGRect(x: frame.minX + separatorViewMarginLeft, y: frame.height - 1, width: frame.width - frame.minX - paddingRight - separatorViewMarginLeft, height: Constants.Separator.BoldThickness)
    }
    
    func setData(withStyle style: Style, hasCheckbox: Bool = false) {
        self.style = style
        
        let selectedColor = style.getValidColorAtIndex(style.colorIndexSelected)
        var imageKey = ProductManager.getProductImageKey(style, colorKey: selectedColor?.colorKey ?? "")
        if imageKey.isEmpty{
            imageKey = style.imageDefault
        }

        var skuFiltering: Sku? = nil
        if style.colorIndexSelected < 0 && style.sizeIndexSelected < 0{
            skuFiltering = style.defaultSku()
        } else {
            let sizeIdSelected = style.getValidSizeIdAtIndex(style.sizeIndexSelected)
            if let sku = style.searchSku(sizeIdSelected, colorId: selectedColor?.colorId, skuColor: selectedColor?.skuColor){
                skuFiltering = sku
            } else {
                skuFiltering = style.defaultSku()
            }
        }
        
        var priceSale = style.priceSale
        var priceRetail = style.priceRetail
        var isSale = style.isOnSale().hashValue
        
        //high priority for displaying price by sku
        //if can't find and sku meet the search will use style price
        if let strongSkuFiltering = skuFiltering {
            priceRetail = strongSkuFiltering.priceRetail
            
            if self.isFlashSaleEligible && strongSkuFiltering.isFlashOnSale() {
                priceSale = strongSkuFiltering.priceFlashSale
                isSale = strongSkuFiltering.isFlashOnSale().hashValue
                flashSaleFirstImageView.isHidden = false
                flashSaleSecondImageView.isHidden = false
            } else {
                priceSale = strongSkuFiltering.priceSale
                isSale = strongSkuFiltering.isOnSale().hashValue
                flashSaleFirstImageView.isHidden = true
                flashSaleSecondImageView.isHidden = true
            }
        }
        
        setData(withProductName: style.skuName, productImageKey: imageKey, brandName: style.brandName, retailPrice: priceRetail, salePrice: priceSale, isSale: isSale, hasCheckbox: hasCheckbox)
        
        selectItem(style.selected)
        
        let itemDisabled = style.isOutOfStock() || !style.isValid()
        
        productSelectionButton?.isHidden = itemDisabled
        productSelectionView.isHidden = itemDisabled
        itemDisabledLabel?.isHidden = !itemDisabled
        itemDisabledLabel?.text = ""
        
        if !style.isValid() || style.isOutOfStock() {
            itemDisabledLabel?.text = String.localize("LB_CA_SKU_OUTOFSTOCK")
        }
    }
    
    
    func setData(withCartItem cartItem: CartItem, hasCheckbox: Bool = false) {
        setData(withProductName: cartItem.skuName, productImageKey: cartItem.productImage, brandName: cartItem.brandName, retailPrice: cartItem.priceRetail, salePrice: cartItem.priceSale, isSale: cartItem.isOnSale() ? 1 : 0, hasCheckbox: hasCheckbox)
    }
    
    func setData(withProductName productName: String, productImageKey: String, brandName: String, retailPrice: Double, salePrice: Double, isSale: Int, hasCheckbox: Bool) {
        productNameLabel.text = productName
        priceLabel.attributedText = PriceHelper.getFormattedPriceText(withRetailPrice: retailPrice, salePrice: salePrice, isSale: isSale, retailPriceFontSize: 12, salePriceFontSize: 14, retailPriceWithSaleFontColor: UIColor.black)
        updateProductImage(withImageKey: productImageKey)
        
        brandNameLabel.text = brandName
        
        if hasCheckbox {
            setupCheckbox()
        }
        
        layoutSubviews()
    }
    
    func setupCheckbox() {
        if productSelectionButton == nil {
            let button = { () -> UIButton in
                let button = UIButton(type: .custom)
                button.config(
                    normalImage: UIImage(named: "icon_checkbox_unchecked"),
                    selectedImage: UIImage(named: "icon_checkbox_checked")
                )
                button.addTarget(self, action: #selector(self.toggleItem), for: .touchUpInside)
                button.sizeToFit()
                button.frame = CGRect(x: (PaddingLeft + CheckboxContainerWidth - button.width) / 2, y: (self.height - button.height) / 2, width: button.width, height: button.height)
                
                return button
            } ()
            
            contentView.addSubview(button)
            productSelectionButton = button
        }
        
        if itemDisabledLabel == nil {
            let labelSize = CGSize(width: 32, height: 21)
            
            let label = { () -> UILabel in
                if let productSelectionButton = self.productSelectionButton {
                    let label = UILabel(frame: CGRect(x: productSelectionButton.frame.midX - (labelSize.width / 2), y: productSelectionButton.frame.midY - (labelSize.height / 2), width: labelSize.width, height: labelSize.height))
                    label.formatSize(12)
                    label.textColor = UIColor.white
                    label.backgroundColor = UIColor.secondary3()
                    label.layer.cornerRadius = 2
                    label.clipsToBounds = true
                    label.textAlignment = .center
                    label.isHidden = true
                    
                    return label
                }
            
                return UILabel()
            } ()
            
            contentView.addSubview(label)
            itemDisabledLabel = label
        }
    }
    
    @objc func toggleItem() {
        if let style = style {
            selectItem(!style.selected)
            
            if let callback = itemSelectHandler {
                callback(style)
            }
        }
    }
    
    func hideBorder(_ hidden: Bool) {
        separatorView.isHidden = hidden
    }
    
    func updateProductImage(withImageKey imageKey: String) {
        productImageView.mm_setImageWithURL(ImageURLFactory.URLSize256(imageKey, category: .product), placeholderImage: PlaceholderImage, contentMode: .scaleAspectFit)
    }
    
    func getProductImage() -> UIImage? {
        return productImageView.image
    }
    
    private func selectItem(_ selected: Bool) {
        style?.selected = selected
        productSelectionButton?.isSelected = selected
    }
    
    @objc func showMerchantCouponList() {
        viewCouponHandler?()
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}
