//
//  WishListItemCell.swift
//  merchant-ios
//
//  Created by HungPM on 1/25/16.
//  Copyright © 2016 WWE & CO. All rights reserved.
//

import Foundation
import PromiseKit
import ObjectMapper

class WishListItemCell: SwipeActionMenuCell {
    
    static let CellIdentifier = "WishListItemCellID"
    
    @IBOutlet weak var productContainerView: UIView!
    @IBOutlet weak var productStatusLabel: UILabel!
    @IBOutlet weak var productImageView: UIImageView!
    @IBOutlet weak var merchantNameLabel: UILabel!
    @IBOutlet weak var productNameLabel: UILabel!
    @IBOutlet weak var productPriceLabel: UILabel!
    @IBOutlet weak var productAddToCartButton: UIButton!
    
    @IBOutlet weak var productContainerLeftConstraint: NSLayoutConstraint!
    
    var merchantLogoHandler: ((_ cell: WishListItemCell, _ data: CartItem) -> Void)?
    var addToCartHandler: ((_ cell: WishListItemCell, _ data: CartItem) -> Void)?
    var cellTappedHandler: ((_ cell: WishListItemCell, _ data: CartItem) -> Void)?
    
    var data: CartItem? {
        didSet {
            if let cartItem = self.data {
                productImageView.mm_setImageWithURL(ImageURLFactory.URLSize512(cartItem.productImage, category: .product), placeholderImage: UIImage(named: "holder"), contentMode: .scaleAspectFit)
                
                self.productNameLabel.text = cartItem.skuName
                
                self.fillPrice(cartItem.priceSale, priceRetail: cartItem.priceRetail, isSale: cartItem.isSale)
                
                productAddToCartButton.isHidden = !cartItem.styleIsValid || cartItem.styleIsOutOfStock
                
                let isValidCartItem = cartItem.styleIsValid && !cartItem.styleIsOutOfStock
                productStatusLabel.isHidden = isValidCartItem
                productStatusLabel.text = ""
                
                if !cartItem.styleIsValid || cartItem.styleIsOutOfStock  {
                    productStatusLabel.text = String.localize("LB_CA_CART_WISHLIST_OUTOFSTOCK")
                }

                self.formatFrame(isValidCartItem)
            } else {
                ErrorLogManager.sharedManager.recordNonFatalError(withException: .NullPointer)
            }
        }
    }
    
    override init(frame: CGRect) {
        super.init(frame: frame)
    }
    
    override func awakeFromNib() {
        super.awakeFromNib()
        
        let singleTap = UITapGestureRecognizer(target: self, action: #selector(WishListItemCell.cellTapped))
        productImageView.isUserInteractionEnabled = true
        productImageView.addGestureRecognizer(singleTap)
        
        productStatusLabel.formatSize(12)
        productStatusLabel.textColor = UIColor.white
        productStatusLabel.backgroundColor = UIColor.secondary3()
        productStatusLabel.layer.cornerRadius = 2
        productStatusLabel.clipsToBounds = true
        productStatusLabel.textAlignment = NSTextAlignment.center
        productStatusLabel.isHidden = true
        
        merchantNameLabel.formatSize(14)
        merchantNameLabel.textColor = UIColor.secondary2()
        merchantNameLabel.numberOfLines = 1
        merchantNameLabel.lineBreakMode = .byTruncatingTail
        
        productNameLabel.formatSize(12)
        productNameLabel.textColor = UIColor.secondary2()
        productNameLabel.numberOfLines = 1
        productNameLabel.lineBreakMode = .byTruncatingTail
        
        productPriceLabel.escapeFontSubstitution = true
        productPriceLabel.formatSize(14)
        
        productAddToCartButton.layer.cornerRadius = Constants.ActionButton.Radius
        productAddToCartButton.layer.borderWidth = Constants.ActionButton.BorderWidth
        productAddToCartButton.layer.borderColor = UIColor.secondary3().cgColor
        productAddToCartButton.titleLabel!.font = UIFont(name: productAddToCartButton.titleLabel!.font.fontName, size: CGFloat(14))!
        productAddToCartButton.backgroundColor = UIColor.white
        productAddToCartButton.setTitleColor(UIColor.primary1(), for: UIControlState())
        productAddToCartButton.setTitle(String.localize("LB_CA_CHECKOUT"), for: UIControlState())
        
        productAddToCartButton.touchUpClosure = { [weak self] _ in
            if let strongSelf = self {
                strongSelf.addToCart()
            }
        }
    }
    
    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
    }
    
    private func fillPrice(_ priceSale: Double, priceRetail: Double, isSale: Int) {
        self.productPriceLabel.attributedText = PriceHelper.fillPrice(priceSale, priceRetail: priceRetail, isSale: isSale)
    }
    
    private func formatFrame(_ isValidCartItem: Bool) {
        productContainerLeftConstraint.constant = isValidCartItem ? 6 : 44
    }
    
    func setMerchantName(_ name: String) {
        merchantNameLabel.text = name
    }
    
    func merchantLogoTapped() {
        if let callback = self.merchantLogoHandler {
            if let data = self.data {
                callback(self, data)
            } else {
                ErrorLogManager.sharedManager.recordNonFatalError(withException: .NullPointer)
            }
        }
    }
    
    func addToCart() {
        if let callback = self.addToCartHandler {
            if let data = self.data {
                callback(self, data)
            } else {
                ErrorLogManager.sharedManager.recordNonFatalError(withException: .NullPointer)
            }
        }
    }

    @objc func cellTapped() {
        if let callback = self.cellTappedHandler {
            if let data = self.data {
                callback(self, data)
            } else {
                ErrorLogManager.sharedManager.recordNonFatalError(withException: .NullPointer)
            }
        }
    }
    
    func accessibilityIdentifierIndex(_ index: Int) {
        accessibilityIdentifier = "WishlistCell-\(index)"
    }
}
