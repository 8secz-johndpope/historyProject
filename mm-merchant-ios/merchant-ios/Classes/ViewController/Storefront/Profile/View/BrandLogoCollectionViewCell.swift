//
//  BrandLogoCollectionViewCell.swift
//  merchant-ios
//
//  Created by Vu Dinh Trung on 4/25/16.
//  Copyright © 2016 WWE & CO. All rights reserved.
//

import UIKit

class BrandLogoCollectionViewCell: UICollectionViewCell {
    var brandImageView = UIImageView()
    private final let BrandWidth : CGFloat = 32
    override init(frame: CGRect) {
        super.init(frame: frame)
        brandImageView.image = UIImage(named: "default_cover")
        brandImageView.contentMode = .scaleAspectFill
        self.addSubview(brandImageView)
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override func layoutSubviews() {
        super.layoutSubviews()
        brandImageView.frame = CGRect(x: 0, y: 0, width: BrandWidth, height: BrandWidth)
    }
    
    func setupdataByBrand(_ brand: Brand) -> Void {
        setBrandImage(brand.smallLogoImage, category: .brand)
    }
    func setBrandImage(_ imageKey : String, category: ImageCategory){
        
        brandImageView.mm_setImageWithURL(ImageURLFactory.URLSize128(imageKey, category: category), placeholderImage : UIImage(named: "Spacer"), contentMode: UIViewContentMode.scaleAspectFit)
    }

    func setupDataByMerchant(_ merchant: Merchant) {
        
        setImage(merchant.headerLogoImage, category: .merchant)
    }
    
    func setImage(_ imageKey : String, category : ImageCategory){
        
        brandImageView.mm_setImageWithURL(ImageURLFactory.URLSize128(imageKey, category: category), placeholderImage : UIImage(named: "holder"), contentMode: UIViewContentMode.scaleAspectFit)
    }
    
    var data: CartItem? {
        didSet {
            if let cartItem = self.data {
                brandImageView.mm_setImageWithURL(ImageURLFactory.URLSize128(cartItem.productImage), placeholderImage: UIImage(named: "holder"), contentMode: .scaleAspectFit)
            }
        }
    }
    
    var dataShoppingCart: CartItem? {
        didSet {
            if let data = self.dataShoppingCart {
                self.brandImageView.mm_setImageWithURL(
                    ImageURLFactory.URLSize128(data.productImage, category: .product),
                    placeholderImage: UIImage(named: "holder"),
                    completion: { (image, error, cacheType, imageURL) -> () in
                        if let image = image {
                            let imageWidth = image.size.width
                            let imageHeight = image.size.height
                            let imageRatio = imageWidth / imageHeight
                            
                            self.brandImageView.frame = CGRect(x:self.brandImageView.frame.origin.x, y: self.brandImageView.frame.origin.y, width: self.brandImageView.frame.size.height * imageRatio, height: self.brandImageView.frame.size.height)
                        }
                        
                })
                
                
            }
        }
    }
    
    //TODO: - go to photo collape
    

}
