//
//  CustomerProductCell.swift
//  merchant-ios
//
//  Created by HungPM on 1/25/16.
//  Copyright © 2016 WWE & CO. All rights reserved.
//

import Foundation

class CustomerProductCell: UICollectionViewCell {
    
    private var productImageView: UIImageView!
    private var brandImageView: UIImageView!
    private var productNameLabel: UILabel!
    private var productPriceLabel: UILabel!

    var cellTappedHandler: ((_ data: CartItem) -> Void)?
    var productAttachedHandler: ((_ data: CartItem) -> Void)?

    var data: CartItem? {
        didSet {
            if let cartItem = self.data {

                productImageView.mm_setImageWithURL(ImageURLFactory.URLSize1000(cartItem.productImage), placeholderImage: UIImage(named: "Spacer"), contentMode: .scaleAspectFit)
                
                self.productNameLabel.text = cartItem.skuName
                self.fillPrice(cartItem.priceSale, priceRetail: cartItem.priceRetail, isSale: cartItem.isSale)
                
                self.brandImageView.mm_setImageWithURL(
                    ImageURLFactory.URLSize1000(cartItem.brandImage, category: .brand), placeholderImage: UIImage(named: "holder"), contentMode: .scaleAspectFit, completion: { (image, error, cacheType, imageURL) -> () in
                        if let image = image {
                            let imageWidth = image.size.width
                            let imageHeight = image.size.height
                            let imageRatio = imageWidth / imageHeight
                            
                            self.brandImageView.frame = CGRect(x:self.brandImageView.frame.origin.x, y: self.brandImageView.frame.origin.y, width: self.brandImageView.frame.size.height * imageRatio, height: self.brandImageView.frame.size.height)
                        }
                    }
                )
            }
        }
    }
    

    func fillPrice(_ priceSale: Double, priceRetail: Double, isSale: Int) {
        self.productPriceLabel.attributedText = PriceHelper.fillPrice(priceSale, priceRetail: priceRetail, isSale: isSale)
    }

    override init(frame: CGRect) {
        super.init(frame: frame)
        
        let ContainerPaddingTop = CGFloat(23)
        let ContainerHeight = CGFloat(142)
        
        let containerFrame = CGRect(x: 0, y: ContainerPaddingTop, width: frame.width, height: ContainerHeight)
        let containerView = UIView(frame: containerFrame)

        self.contentView.addSubview(containerView)
        
		let singleTap = UITapGestureRecognizer(target: self, action: #selector(cellTapped))
		
		containerView.addGestureRecognizer(singleTap)

        let MarginLeft = CGFloat(15)
        let heightOfProductImageView = CGFloat(114)
        let widthOfProductImageView = heightOfProductImageView / Constants.Ratio.ProductImageHeight

        let productImageFrame = CGRect(x: MarginLeft, y: 0, width: widthOfProductImageView, height: heightOfProductImageView)
        let productImageView = UIImageView(frame: productImageFrame)
        productImageView.contentMode = .scaleAspectFit

		containerView.addSubview(productImageView)
		self.productImageView = productImageView
		
        let leftPadding = CGFloat(10)
        let rightPadding = CGFloat(5)
        
        let xPos = productImageFrame.maxX + leftPadding
        
        let brandImageView = { () -> UIImageView in
            
            let imageView = UIImageView(frame: CGRect(x: xPos, y: 0, width: 0, height: 28))
            self.brandImageView = imageView
            
            return imageView
        } ()
        containerView.addSubview(brandImageView)
        
        let yPadding = CGFloat(10)
        let productNameHeight = CGFloat(30)
        let productNameFrame = CGRect(x: xPos, y: brandImageView.frame.maxY + yPadding, width: frame.width - xPos - rightPadding, height: productNameHeight)
        let productNameLabel = UILabel(frame: productNameFrame)
        productNameLabel.formatSize(14)
        productNameLabel.textColor = UIColor(hexString: "#757575")
        self.productNameLabel = productNameLabel
        containerView.addSubview(productNameLabel)
        
        let priceLabelHeight = CGFloat(30)
        let priceLableFrame = CGRect(x: xPos, y: productNameLabel.frame.maxY, width: frame.width - xPos - rightPadding, height: priceLabelHeight)
        let priceLabel = UILabel(frame: priceLableFrame)
        priceLabel.escapeFontSubstitution = true
        self.productPriceLabel = priceLabel
        containerView.addSubview(priceLabel)
        
        let marginRight = CGFloat(14)
        //let marginBottom = CGFloat(7)
        let sendButtonSize = CGSize(width: 70, height: Constants.ActionButton.Height)
        let sendButtonFrame = CGRect(x: containerView.width - marginRight - sendButtonSize.width, y: containerView.height - sendButtonSize.height, width: sendButtonSize.width, height: sendButtonSize.height)
        let sendButton = ActionButton(frame: sendButtonFrame, titleStyle: .highlighted)
        sendButton.setTitle(String.localize("LB_SEND"), for: UIControlState())
        sendButton.touchUpClosure = { _ in
            if let callback = self.productAttachedHandler, let data = self.data {
                callback(data)
            }
        }
        containerView.addSubview(sendButton)
        
        let lineHeight = CGFloat(1)
        let line = UIView(frame: CGRect(x: 0, y: self.contentView.frame.maxY - lineHeight, width: self.contentView.frame.width, height: lineHeight))
        line.backgroundColor = UIColor.secondary1()
        self.contentView.addSubview(line)
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    @objc func cellTapped() {
        if let callback = self.cellTappedHandler, let data = self.data {
            callback(data)
        }
    }
}
