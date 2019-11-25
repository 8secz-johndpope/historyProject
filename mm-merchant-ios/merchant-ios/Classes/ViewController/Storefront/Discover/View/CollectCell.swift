//
//  CollectCell.swift
//  merchant-ios
//
//  Created by Koon Kit Chan on 23/9/15.
//  Copyright © 2015 Koon Kit Chan. All rights reserved.
//

import Foundation
import UIKit
import PromiseKit
import ObjectMapper

class CollectCell : UICollectionViewCell {
    
    static let CellIdentifier = "CollectCellID"
    
    private let BadgeImageSize = CGSize(width: 30, height: 30)
    private let PlayImageSize = CGSize(width: 42, height: 18)
    var sizeOfLikeImageView : CGSize = CGSize(width: 45, height: 45)
    
    var nameLabel = UILabel()
    var imageView = UIImageView()
    var badgeImageView = UIImageView()
    var priceLabel = UILabel()
    var heartImageView = UIImageView()
    var brandImageView = UIImageView()
    var playerImageView = UIImageView()
    var saleFontSize: CGFloat = 16
    var retailFontSize: CGFloat = 11
    
    var saleFont: UIFont!
    var retailFont: UIFont!
	
	var sku: Sku?
	
	var style : Style?
    
    var tapHandler: (() -> Void)?
	
    override init(frame: CGRect) {
        super.init(frame: frame)
        
        backgroundColor = UIColor.white
        
        addSubview(imageView)
        
        addSubview(brandImageView)
        
        nameLabel.formatSize(13)
        nameLabel.textAlignment = .center
        addSubview(nameLabel)
        
        priceLabel.formatSize(16)
        priceLabel.font = saleFont
        priceLabel.textAlignment = .center
        priceLabel.escapeFontSubstitution = true
        addSubview(priceLabel)
        
        heartImageView.image = UIImage(named: "star_nav")
        addSubview(heartImageView)
        
        //Default Hide
        badgeImageView.isHidden = true
        badgeImageView.backgroundColor = UIColor.clear
        addSubview(badgeImageView)
        
        playerImageView.isHidden = true
        playerImageView.image = UIImage(named: "plp_play")
        playerImageView.contentMode = .scaleAspectFit
        addSubview(playerImageView)
        
        layoutSubviews()
    }
    
    override func layoutSubviews() {
        super.layoutSubviews()
        
        saleFont = UIFont.boldSystemFont(ofSize: saleFontSize)
        retailFont = UIFont.systemFont(ofSize: retailFontSize)
        
        imageView.frame = CGRect(x: bounds.minX, y: bounds.minY, width: bounds.width, height: bounds.width * Constants.Ratio.ProductImageHeight)
        
        brandImageView.frame = CGRect(x: bounds.midX - Constants.Value.BrandImageWidth / 2, y: imageView.frame.maxY + 7 , width: Constants.Value.BrandImageWidth , height: Constants.Value.BrandImageHeight)
        nameLabel.frame = CGRect(x: bounds.minX + 25 , y: brandImageView.frame.maxY  , width: bounds.width - 50 , height: 40)
        priceLabel.frame = CGRect(x: bounds.minX, y: nameLabel.frame.maxY + 4 , width: bounds.width, height: 20)
        
        let Margin : CGFloat = 5
        let sizeOfHeartImageView = Constants.FaviorIconSize
        heartImageView.frame = CGRect(x: imageView.frame.maxX - sizeOfHeartImageView.width - Margin, y: imageView.frame.maxY  - sizeOfHeartImageView.height - Margin, width: sizeOfHeartImageView.width, height: sizeOfHeartImageView.height)
        heartImageView.contentMode = .scaleAspectFit
        
        badgeImageView.frame = CGRect(x: 5, y: 5, width: BadgeImageSize.width, height: BadgeImageSize.height)
        
        heartImageView.addGestureRecognizer(UITapGestureRecognizer(target:self, action:#selector(self.handleImageTapped)))
		
        playerImageView.frame = CGRect(x: 10, y: imageView.frame.sizeHeight - PlayImageSize.height - 10, width: PlayImageSize.width, height: PlayImageSize.height)
        
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    func setBrandImage(_ imageKey : String) {
        _ = brandImageView.mm_setImageWithURL(ImageURLFactory.URLSize256(imageKey, category: .brand), placeholderImage : UIImage(named: "Spacer"), contentMode: UIViewContentMode.scaleAspectFit)
    }
    
    func setProductImage(_ imageKey : String, contentMode : UIViewContentMode = .scaleAspectFill) {
        _ = imageView.mm_setImageWithURL(ImageURLFactory.URLSize1000(imageKey, category: .product), placeholderImage: UIImage(named: "brand_placeholder"), contentMode: contentMode)
    }

    func fillPrice(_ priceSale: Double, priceRetail: Double, isSale: Int, hasValidCoupon: Bool = false) {
        priceLabel.attributedText = PriceHelper.fillPrice(priceSale, priceRetail: priceRetail, isSale: isSale, hasValidCoupon: hasValidCoupon)
    }
    
    func setBadgeImage(_ badgeImageKey: String) {
        if badgeImageKey.isEmptyOrNil() {
            self.badgeImageView.isHidden = true
        } else {
            self.badgeImageView.isHidden = false
            self.badgeImageView.mm_setImageWithURL(ImageURLFactory.get(badgeImageKey, isForProductList: true), placeholderImage: nil, contentMode: contentMode)
        }
    }
    
    var data: CartItem? {
        didSet {
            if let cartItem = self.data {
                imageView.mm_setImageWithURL(ImageURLFactory.URLSize1000(cartItem.productImage, category: .product), placeholderImage: UIImage(named: "brand_placeholder"), contentMode: .scaleAspectFit)
                
                self.nameLabel.text = cartItem.skuName
                self.fillPrice(cartItem.priceSale, priceRetail: cartItem.priceRetail, isSale: cartItem.isSale)
                
                self.brandImageView.mm_setImageWithURL(
                    ImageURLFactory.URLSize256(cartItem.brandImage, category: .brand), placeholderImage: UIImage(named: "holder"), contentMode: .scaleAspectFit, completion: { (image, error, cacheType, imageURL) -> () in
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
	
	func searchStyle(withSkuId skuId: Int) -> Promise<Any> {
		return Promise{ fulfill, reject in
            style = nil
			SearchService.searchStyleBySkuId(skuId) { [weak self] (response) in
				if let strongSelf = self {
					if response.result.isSuccess {
						if let response = Mapper<SearchResponse>().map(JSONObject: response.result.value), let styles = response.pageData {
							
							strongSelf.style = styles.first
							
						}
						fulfill("OK")
					} else {
                        reject(response.result.error ?? NSError(domain: "", code: 0, userInfo: nil))
					}
				}
			}
		}
	}
	
	
    var inActiveLabel = UILabel(frame: CGRect(x: 0, y: 0, width: 0, height: 0))
    
	func updateInactiveOrOutOfStockStatus() {
		
		inActiveLabel.removeFromSuperview()
		
		var labalString = ""
		
		if let style = style {
			if !style.isValid() || style.isOutOfStock() {
				labalString = String.localize("LB_CA_OUT_OF_STOCK")
			}
		}
		else {
			labalString = String.localize("LB_CA_OUT_OF_STOCK")
		}
		
		if (self.style != nil) && (self.style?.styleCode != self.sku?.styleCode) {
			labalString = String.localize("LB_CA_OUT_OF_STOCK")
		}
		
		if labalString.count > 0 {
            self.isUserInteractionEnabled = false
			inActiveLabel.layoutInactiveOrOutOfStockLabel(forView: imageView, sizePercentage: 0.6)
			inActiveLabel.text = labalString
			self.addSubview(inActiveLabel)
		}else {
            self.isUserInteractionEnabled = true
			inActiveLabel.removeFromSuperview()
		}
		
	}
	
    func setBadgeImage(_ imageKey: String, isProductList: Bool = false) {
        badgeImageView.mm_setImageWithURL(ImageURLFactory.get(imageKey, isForProductList: isProductList), placeholderImage : UIImage(named: "holder"), contentMode: UIViewContentMode.scaleAspectFit)
    }
    
    @objc func handleImageTapped(sender: UIGestureRecognizer) {
        if let callback = self.tapHandler {
            callback()
        } else {
            ErrorLogManager.sharedManager.recordNonFatalError(withException: .NullPointer)
        }
    }
    

}
