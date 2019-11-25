//
//  ForwardChatProductCell.swift
//  merchant-ios
//
//  Created by HungPM on 6/1/16.
//  Copyright © 2016 WWE & CO. All rights reserved.
//

import Foundation

class ForwardChatProductCell: UICollectionViewCell {
    
    var productImageView: UIImageView!
    var brandImageView: UIImageView!
    var productNameLabel: UILabel!
    var productPriceLabel: UILabel!
    var buttonPick: UIButton!
    var buttonDelete: UIButton!

    var buttonPickHandler: (() -> Void)?
    var buttonDeleteHandler: (() -> Void)?

    private var singleTap: UITapGestureRecognizer?
    
    var productModel: ProductModel? {
        didSet {
            if let productModel = self.productModel, let style = productModel.style, let sku = productModel.sku {
                
                _ = brandImageView.mm_setImageWithURL(
                    ImageURLFactory.URLSize128(style.brandSmallLogoImage, category: .brand),
                    placeholderImage: UIImage(named: "holder"),
                    completion: { (image, error, cacheType, imageURL) -> () in
                        if let image = image {
                            let imageWidth = image.size.width
                            let imageHeight = image.size.height
                            let imageRatio = imageWidth / imageHeight
                            
                            self.brandImageView.frame = CGRect(x:self.brandImageView.frame.origin.x, y: self.brandImageView.frame.origin.y, width: self.brandImageView.frame.size.height * imageRatio, height: self.brandImageView.frame.size.height)
                        }
                        
                })

                if let productImageKey = style.findImageKeyByColorKey(sku.colorKey) {
                    _ = productImageView.mm_setImageWithURL(
                        ImageURLFactory.URLSize256(productImageKey),
                        placeholderImage: UIImage(named: "Spacer"),
                        contentMode: .scaleAspectFit,
                        completion: nil
                    )
                }
                
                productPriceLabel.attributedText = PriceHelper.fillPrice(style.priceSale, priceRetail: style.priceRetail, isSale: sku.isSale)
                
                productNameLabel.text = style.skuName
                
                buttonDelete.isHidden = false
                buttonPick.isHidden = true
                
                if self.singleTap == nil {
                    self.singleTap = UITapGestureRecognizer(target: self, action: #selector(buttonPickTapped))
                }
                contentView.addGestureRecognizer(self.singleTap!)
            }
        }
    }
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        
        let MarginTop = CGFloat(10)
        let MarginLeft = CGFloat(5)
        
        productImageView = { () -> UIImageView in
            let height = CGFloat(114)
            let width = height / Constants.Ratio.ProductImageHeight

            let imageView = UIImageView(frame: CGRect(x: MarginLeft, y: MarginTop, width: width, height: height))
            imageView.contentMode = .scaleAspectFit

            return imageView
        }()
        contentView.addSubview(productImageView)
        
        let xPos = productImageView.frame.maxX + MarginLeft
        let yPadding = CGFloat(5)

        brandImageView = { () -> UIImageView in
            let imageView = UIImageView(frame: CGRect(x: xPos, y: MarginTop, width: 0, height: 38))

            return imageView
        }()
        contentView.addSubview(brandImageView)
        
        productNameLabel = { () -> UILabel in
            let label = UILabel(frame: CGRect(x: xPos, y: brandImageView.frame.maxY + yPadding, width: frame.width - xPos - MarginLeft, height: 30))
            label.formatSize(14)
            label.textColor = UIColor(hexString: "#757575")

            return label
        }()
        contentView.addSubview(productNameLabel)
        
        productPriceLabel = { () -> UILabel in
            let label = UILabel(frame: CGRect(x: xPos, y: productNameLabel.frame.maxY, width: frame.width - xPos - MarginLeft, height: 30))
            label.escapeFontSubstitution = true
            
            return label
        }()
        contentView.addSubview(productPriceLabel)

        buttonPick = { () -> UIButton in
            let Width = CGFloat(50)
            let button = UIButton(type: .custom)
            button.frame = CGRect(x: frame.width - Width - (2 * MarginLeft), y: MarginTop, width: Width, height: Width)
            button.setImage(UIImage(named: "addproduct_btn"), for: UIControlState())
            button.addTarget(self, action: #selector(buttonPickTapped), for: .touchUpInside)
            
            return button
        }()
        contentView.addSubview(buttonPick)

        buttonDelete = { () -> UIButton in
            let Width = CGFloat(32)
            let button = UIButton(type: .custom)
            button.frame = CGRect(x: frame.width - Width - (2 * MarginLeft), y: MarginTop, width: Width, height: Width)
            button.setImage(UIImage(named: "btn_close_grey"), for: UIControlState())
            button.addTarget(self, action: #selector(buttonDeleteTapped), for: .touchUpInside)
            
            return button
        }()
        contentView.addSubview(buttonDelete)

        let separatorView = { () -> UIView in
            let view = UIView(frame: CGRect(x: MarginLeft, y: frame.size.height - 1, width: frame.width - (2 * MarginLeft), height: 1))
            view.backgroundColor = UIColor.backgroundGray()
            
            return view
        }()
        contentView.addSubview(separatorView)
        
        buttonDelete.isHidden = true
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    @objc func buttonPickTapped() {
        buttonPickHandler?()
    }
    
    @objc func buttonDeleteTapped() {
        productImageView.image = nil
        brandImageView.image = nil
        productNameLabel.text = ""
        productPriceLabel.text = ""
        
        buttonPick.isHidden = false
        buttonDelete.isHidden = true
        contentView.removeGestureRecognizer(self.singleTap!)
        
        buttonDeleteHandler?()
    }
}
