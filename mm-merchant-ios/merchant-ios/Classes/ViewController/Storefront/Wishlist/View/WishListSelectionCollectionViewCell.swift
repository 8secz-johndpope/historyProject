//
//  WishListSelectionCollectionViewCell.swift
//  merchant-ios
//
//  Created by Vu Dinh Trung on 5/18/16.
//  Copyright © 2016 WWE & CO. All rights reserved.
//

import UIKit
import PromiseKit

class WishListSelectionCollectionViewCell: UICollectionViewCell {
    
    static let CellIdentifier = "WishListSelectionCollectionViewCellId"
    
    var productImageView: UIImageView!
    var brandImageView: UIImageView!
    var productNameLabel: UILabel!
    var productPriceLabel: UILabel!
    var tickImageView: UIImageView!
    
    var brandLogoHandle: ((_ data: CartItem) -> Void)?
    var addToCartHandle: ((_ data: CartItem) -> Void)?
    var cellTappedHandler: ((_ data: CartItem) -> Void)?
    
    var data: CartItem? {
        didSet {
            if let cartItem = self.data {
                productImageView.mm_setImageWithURL(ImageURLFactory.URLSize512(cartItem.productImage, category: .product), placeholderImage: UIImage(named: "holder"), contentMode: .scaleAspectFit)
                
                self.productNameLabel.text = cartItem.skuName
                self.fillPrice(cartItem.priceSale, priceRetail: cartItem.priceRetail, isSale: cartItem.isSale)
                
                self.brandImageView.mm_setImageWithURL(
                    ImageURLFactory.URLSize512(cartItem.brandImage, category: .brand), placeholderImage: UIImage(named: "holder"), contentMode: .scaleAspectFit, completion: { (image, error, cacheType, imageURL) -> () in
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
            } else {
                ErrorLogManager.sharedManager.recordNonFatalError(withException: .NullPointer)
            }
        }
    }


    func fillPrice(_ priceSale: Double, priceRetail: Double, isSale: Int) {
        self.productPriceLabel.attributedText = PriceHelper.fillPrice(priceSale, priceRetail: priceRetail, isSale: isSale)
    }
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        
        
        let ContainerPaddingTop = CGFloat(11)
        let ContainerHeight = CGFloat(84)
        
        let containerFrame = CGRect(x: 0, y: ContainerPaddingTop, width: frame.width, height: ContainerHeight)
        let containerView = UIView(frame: containerFrame)
        containerView.backgroundColor = UIColor.white
        self.contentView.addSubview(containerView)
        
        tickImageView = UIImageView(frame: CGRect(x: 16, y: (ContainerHeight - 25) / 2, width: 25, height: 25))
        tickImageView.image = UIImage(named: "icon_checkbox_unchecked2")
        containerView.addSubview(tickImageView)
        
        let MarginLeft = CGFloat(15)
        let heightOfProductImage = CGFloat(78)
        let widthOfProductImage = heightOfProductImage / Constants.Ratio.ProductImageHeight

        let productImageFrame = CGRect(x: tickImageView.frame.maxX + MarginLeft, y: 0, width: widthOfProductImage, height: heightOfProductImage)
        let productImageView = UIImageView(frame: productImageFrame)
        productImageView.contentMode = .scaleAspectFit
        
        containerView.addSubview(productImageView)
        self.productImageView = productImageView
        
        let leftPadding = CGFloat(10)
        let rightPadding = CGFloat(5)
        
        let xPos = productImageFrame.maxX + leftPadding
        
        let brandImageView = { () -> UIImageView in
            
            let imageView = UIImageView(frame: CGRect(x: xPos, y: 0, width: 0, height: 28))
            imageView.isUserInteractionEnabled = true
            let singleTap = UITapGestureRecognizer(target: self, action: #selector(self.brandLogoTapped))
            imageView.addGestureRecognizer(singleTap)
            
            self.brandImageView = imageView
            
            return imageView
        } ()
        containerView.addSubview(brandImageView)
        
        let yPadding = CGFloat(5)
        let productNameHeight = CGFloat(17)
        let productNameFrame = CGRect(x: xPos, y: brandImageView.frame.maxY + yPadding, width: frame.width - xPos - rightPadding, height: productNameHeight)
        let productNameLabel = UILabel(frame: productNameFrame)
        productNameLabel.formatSize(11)
        productNameLabel.textColor = UIColor.secondary3()
        productNameLabel.lineBreakMode = .byTruncatingTail
        self.productNameLabel = productNameLabel
        containerView.addSubview(productNameLabel)
        
        let priceLabelHeight = CGFloat(17)
        let priceLableFrame = CGRect(x: xPos, y: productNameLabel.frame.maxY, width: frame.width - xPos - rightPadding, height: priceLabelHeight)
        let priceLabel = UILabel(frame: priceLableFrame)
        priceLabel.escapeFontSubstitution = true
        priceLabel.formatSize(14)
        self.productPriceLabel = priceLabel
        
        
        
        containerView.addSubview(priceLabel)
        let lineHeight = CGFloat(1)
        let line = UIView(frame: CGRect(x: 0, y: self.contentView.frame.maxY - lineHeight, width: self.contentView.frame.width, height: lineHeight))
        line.backgroundColor = UIColor.backgroundGray()
        self.contentView.addSubview(line)
        self.contentView.backgroundColor = UIColor.white
        
        
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    @objc func brandLogoTapped() {
        if let callback = self.brandLogoHandle {
            if let data = self.data {
                callback(data)
            } else {
                ErrorLogManager.sharedManager.recordNonFatalError(withException: .NullPointer)
            }
        }
    }
    
    func addToCart() {
        if let callback = self.addToCartHandle {
            if let data = self.data {
                callback(data)
            } else {
                ErrorLogManager.sharedManager.recordNonFatalError(withException: .NullPointer)
            }
        }
    }
    
    func cellTapped() {
        if let callback = self.cellTappedHandler {
            if let data = self.data {
                callback(data)
            } else {
                ErrorLogManager.sharedManager.recordNonFatalError(withException: .NullPointer)
            }
        }
    }
    
    func accessibilityIdentifierIndex(_ index: Int) {
        accessibilityIdentifier = "WishlistCell-\(index)"
    }
    
    var dataShoppingCart: CartItem? {
        didSet {
            if let data = self.dataShoppingCart {
                self.productNameLabel.text = data.skuName
                
                self.productImageView.mm_setImageWithURL(ImageURLFactory.URLSize512(data.productImage, category: .product), placeholderImage: UIImage(named: "holder"), completion: nil)
                
                self.brandImageView.mm_setImageWithURL(ImageURLFactory.URLSize512(data.brandImage, category: .brand), placeholderImage: UIImage(named: "holder"), completion: { (image, error, cacheType, imageURL) -> () in
                    if let image = image {
                        let imageWidth = image.size.width
                        let imageHeight = image.size.height
                        let imageRatio = imageWidth / imageHeight
                        
                        self.brandImageView.frame = CGRect(x:self.brandImageView.frame.origin.x, y: self.brandImageView.frame.origin.y, width: self.brandImageView.frame.size.height * imageRatio, height: self.brandImageView.frame.size.height)
                    } else {
                        ErrorLogManager.sharedManager.recordNonFatalError(withException: .NullPointer)
                    }
                })
                
                self.productPriceLabel.attributedText = PriceHelper.fillPrice(data.priceSale, priceRetail: data.priceRetail, isSale: data.isOnSale().hashValue)
            } else {
                ErrorLogManager.sharedManager.recordNonFatalError(withException: .NullPointer)
            }
        }
    }
    
}
