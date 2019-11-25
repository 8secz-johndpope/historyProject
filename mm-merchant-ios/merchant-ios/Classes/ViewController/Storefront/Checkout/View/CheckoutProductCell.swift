//
//  CheckoutProductCell.swift
//  merchant-ios
//
//  Created by Phan Manh Hung on 2/19/16.
//  Copyright © 2016 WWE & CO. All rights reserved.
//

import Foundation
import PromiseKit

let CheckoutConfirmationProductCellHeight : CGFloat = 143

class CheckoutProductCell: UICollectionViewCell {
    
    static let CellIdentifier = "CheckoutProductCellID"
    static let DefaultHeight: CGFloat = 143
    
    private final let PlaceholderImage = UIImage(named: "holder")
    
    private var productImageView: UIImageView!
    private var productNameLabel: UILabel!
    private var productColorLabel: UILabel!
    private var productSizeLabel: UILabel!
    private var productPriceLabel: UILabel!
    private var productQuantityLabel: UILabel!
    private var brandNameLabel : UILabel!
    
    var isFlashSale = false
    
    var data: CartItem? {
        didSet {
            if let data = self.data {
                productNameLabel.text = data.skuName
                
                let existOrEmpty = { (value: String?) -> String in
                    if value != nil {
                        return value!
                    }
                    return ""
                }
                
                productColorLabel.text = String.localize("LB_CA_PI_COLOR") + " : " + existOrEmpty(data.skuColor)
                productSizeLabel.text = String.localize("LB_CA_PI_SIZE") + " : " + existOrEmpty(data.sizeName)
                
                productColorLabel.isHidden = (data.colorId == 1)
                productSizeLabel.isHidden = (data.sizeId == 1)
                
                productQuantityLabel.text = String.localize("LB_CA_PI_QTY") + " : \(data.qty)"
                
                if let style = data.customStyle {
                    ProductManager.setProductImage(imageView: self.productImageView, style:style, colorKey: data.colorKey, placeholderImage: PlaceholderImage)
                } else {
                    if let data = self.data {
                        self.productImageView.mm_setImageWithURL(ImageURLFactory.URLSize256(data.productImage, category: .product), placeholderImage: PlaceholderImage, contentMode: .scaleAspectFit)
                    }
                }
                
                brandNameLabel.text = data.brandName
                
                updatePriceLabel()
                
                layoutSubviews()
            }
        }
    }
    
    var sku: Sku? {
        didSet {
            if let sku = self.sku {
                productNameLabel.text = sku.skuName
                
                let existOrEmpty = { (value: String?) -> String in
                    if value != nil {
                        return value!
                    }
                    return ""
                }
                
                productColorLabel.text = String.localize("LB_CA_PI_COLOR") + " : " + existOrEmpty(sku.skuColor)
                productSizeLabel.text = String.localize("LB_CA_PI_SIZE") + " : " + existOrEmpty(sku.sizeName)
                
                productColorLabel.isHidden = (sku.colorId == 1)
                productSizeLabel.isHidden = (sku.sizeId == 1)
                
                productQuantityLabel.text = String.localize("LB_CA_PI_QTY") + " : \(sku.qty)"
                
                brandNameLabel.text = sku.brandName
                
                updatePriceLabel()
                
                layoutSubviews()
            }
        }
    }
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        
        let SeparatorHeight = CGFloat(1)
        let ProductContentHeight = CGFloat(143)
        let ProductMarginTop = CGFloat(14)
        let MarginLeft = CGFloat(14)
        let DetailFontSize = 12

        //
        let productContainer = { () -> UIView in
            
            let view = UIView(frame: CGRect(x: 0, y: 0, width: frame.width, height: ProductContentHeight))
            
            let productImageView = { () -> UIImageView in
                
                let height = CGFloat(94)
                let width = height / Constants.Ratio.ProductImageHeight

                let imageView = UIImageView(frame:CGRect(x: MarginLeft, y: ProductMarginTop, width: width, height: height))
                imageView.contentMode = .scaleAspectFit
                
                return imageView
            } ()
            view.addSubview(productImageView)
            self.productImageView = productImageView

            //
            let detailPaddingLeft = CGFloat(16)
            let detailWidth = view.frame.width - productImageView.frame.maxX - 2 * detailPaddingLeft
            let detailHeight = CGFloat(18)
            
            let detailViewContainer = { () -> UIView in
                let view = UIView(frame: CGRect(x: productImageView.frame.maxX + detailPaddingLeft, y: ProductMarginTop, width: detailWidth, height: productImageView.frame.height))
                
                //
                let brandNameLabel = { () -> UILabel in
                    let label = UILabel(frame: CGRect(x: 0, y: 0, width: detailWidth, height: detailHeight))
                    label.formatSize(14)
                    label.textColor = UIColor.secondary2()
                    
                    return label
                } ()
                view.addSubview(brandNameLabel)
                self.brandNameLabel = brandNameLabel
                
                //
                let productNameLabel = { () -> UILabel in
                    let label = UILabel(frame: CGRect(x: 0, y: brandNameLabel.frame.maxY, width: detailWidth, height: detailHeight))
                    label.formatSize(DetailFontSize)
                    label.textColor = UIColor.secondary2()
                    
                    return label
                } ()
                view.addSubview(productNameLabel)
                self.productNameLabel = productNameLabel
                
                //
                let colorLabel = { () -> UILabel in
                    let label = UILabel(frame: CGRect(x: 0, y: productNameLabel.frame.maxY, width: detailWidth, height: detailHeight))
                    label.formatSize(DetailFontSize)
                    label.textColor = UIColor.secondary2()
                    
                    return label
                } ()
                view.addSubview(colorLabel)
                self.productColorLabel = colorLabel
                
                //
                let sizeLabel = { () -> UILabel in
                    let label = UILabel(frame: CGRect(x: 0, y: colorLabel.frame.maxY, width: detailWidth, height: detailHeight))
                    label.formatSize(DetailFontSize)
                    label.textColor = UIColor.secondary2()
                    
                    return label
                } ()
                view.addSubview(sizeLabel)
                self.productSizeLabel = sizeLabel
                
                let quantityLabel = { () -> UILabel in
                    let label = UILabel(frame: CGRect(x: 0, y: sizeLabel.frame.maxY, width: detailWidth, height: detailHeight))
                    label.formatSize(DetailFontSize)
                    label.textColor = UIColor.secondary2()
                    
                    return label
                } ()
                view.addSubview(quantityLabel)
                self.productQuantityLabel = quantityLabel
                
                //
                let priceLabel = { () -> UILabel in
                    let label = UILabel(frame: CGRect(x: 0, y: quantityLabel.frame.maxY, width: detailWidth, height: detailHeight))
                    label.escapeFontSubstitution = true
                    return label
                } ()
                view.addSubview(priceLabel)
                self.productPriceLabel = priceLabel
                
                return view
                
            } ()
            view.addSubview(detailViewContainer)
            
            return view
        } ()
        self.contentView.addSubview(productContainer)
        
        //
        let separatorView = { () -> UIView in
            let view = UIView(frame: CGRect(x: 0, y: productContainer.frame.maxY - SeparatorHeight, width: frame.width, height: SeparatorHeight))
            view.backgroundColor = UIColor.backgroundGray()
            
            return view
        } ()
        
        self.contentView.addSubview(separatorView)
        
        layoutSubviews()
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override func prepareForReuse() {
        super.prepareForReuse();
        self.isFlashSale = false
    }
    
    override func layoutSubviews() {
        super.layoutSubviews()
        
        var offsetY = productNameLabel.frame.maxY
        
        if !productColorLabel.isHidden {
            productColorLabel.y = offsetY
            offsetY += productColorLabel.height
        }
        
        if !productSizeLabel.isHidden {
            productSizeLabel.y = offsetY
            offsetY += productSizeLabel.height
        }
        
        productQuantityLabel.y = offsetY
        productPriceLabel.y = offsetY + productQuantityLabel.height
    }
    
    func setProductImage(withImageKey imageKey: String) {
        productImageView.mm_setImageWithURL(ImageURLFactory.URLSize256(imageKey, category: .product), placeholderImage: PlaceholderImage, contentMode: .scaleAspectFit)
    }
    
    private func updatePriceLabel() {
        if let cartItem = self.data {
            productPriceLabel.attributedText = PriceHelper.getFormattedPriceText(withRetailPrice: cartItem.priceRetail, salePrice: cartItem.priceSale, isSale: cartItem.isSale, retailPriceWithSaleFontColor: UIColor(hexString: "#757575"))
        } else if let sku = self.sku {
            if isFlashSale && sku.isFlashSaleExists && sku.priceFlashSale > 0 {//限购显示
                productPriceLabel.attributedText = PriceHelper.getFormattedPriceText(withRetailPrice: sku.priceRetail, salePrice: sku.priceFlashSale, isSale: sku.isFlashOnSale().hashValue, retailPriceWithSaleFontColor: UIColor(hexString: "#757575"))
            } else {
                productPriceLabel.attributedText = PriceHelper.getFormattedPriceText(withRetailPrice: sku.priceRetail, salePrice: sku.priceSale, isSale: sku.isOnSale().hashValue, retailPriceWithSaleFontColor: UIColor(hexString: "#757575"))
            }
        }
    }
    
}
