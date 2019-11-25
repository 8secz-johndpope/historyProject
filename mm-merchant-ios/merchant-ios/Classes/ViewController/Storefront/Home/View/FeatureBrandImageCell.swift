//
//  FeatureBrandImageCell.swift
//  merchant-ios
//
//  Created by LongTa on 8/1/16.
//  Copyright © 2016 WWE & CO. All rights reserved.
//

import UIKit

protocol BrandImageCellDelegate: NSObjectProtocol {
    func onSelect(merchant: Merchant)
    func onSelect(brand: Brand)
}

class FeatureBrandImageCell: ImageCollectCell {

    static let MarginLeft = CGFloat(14)
    static let Padding = CGFloat(8)
    var index = Int(0)
    var merchant: Merchant?
    var brand: Brand?
    
    weak var delegate: BrandImageCellDelegate?
    static let CellIdentifier = "CellIdentifier"
    var impressionKey: String?
    override init(frame: CGRect) {
        super.init(frame: frame)
        self.backgroundColor = UIColor.white
        self.imageView.backgroundColor = UIColor.backgroundGray()
        
        filter.isHidden = true
        imageView.addGestureRecognizer(UITapGestureRecognizer(target: self, action: #selector(self.didSelectImage)))
        imageView.isUserInteractionEnabled = true
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override func layoutSubviews() {
        super.layoutSubviews()
        
        if self.brand != nil { //For feature brand
            imageView.frame = CGRect(x: 0, y: 0, width: frame.sizeWidth, height: frame.sizeHeight)
            
        } else { //For merchant
            if index == 0 {
                imageView.frame = CGRect(x: FeatureBrandImageCell.MarginLeft, y: 0, width: frame.sizeWidth - FeatureBrandImageCell.MarginLeft - FeatureBrandImageCell.Padding / 2, height: frame.sizeHeight -  FeatureBrandImageCell.Padding / 2 )
            }else if index == 1 {
                imageView.frame = CGRect(x: FeatureBrandImageCell.Padding / 2, y: 0, width: frame.sizeWidth - FeatureBrandImageCell.MarginLeft - FeatureBrandImageCell.Padding / 2, height: frame.sizeHeight - FeatureBrandImageCell.Padding / 2 )
            }else {
                if self.index % 2 == 0 {
                    imageView.frame = CGRect(x: FeatureBrandImageCell.MarginLeft, y: FeatureBrandImageCell.Padding / 2 , width: frame.sizeWidth - FeatureBrandImageCell.MarginLeft - FeatureBrandImageCell.Padding / 2, height: frame.sizeHeight -  FeatureBrandImageCell.Padding )
                }else {
                    imageView.frame = CGRect(x: FeatureBrandImageCell.Padding / 2, y: FeatureBrandImageCell.Padding / 2, width: frame.sizeWidth - FeatureBrandImageCell.MarginLeft - FeatureBrandImageCell.Padding / 2, height: frame.sizeHeight -  FeatureBrandImageCell.Padding )
                }
            }
        }
        
    }
    
    class func getCellSize() -> CGSize {
        let width = ScreenSize.width / 2
        return CGSize(width: width, height: width)
    }
    
    func setImage(_ imageKey: String, category: ImageCategory, index: Int, width: Int) {
        self.index = index
        self.imageView.image = self.placeholderImage()
        self.layoutSubviews()
        if imageKey.isEmpty {
            return
        }
        imageView.mm_setImageWithURL(ImageURLFactory.URLSize512(imageKey, category: category), placeholderImage: self.placeholderImage(), clipsToBounds: true, contentMode: .scaleAspectFill, progress: nil, optionsInfo: nil, completion: nil)
        if let viewKey = self.analyticsViewKey {
            if let merchant = self.merchant {
                self.impressionKey = AnalyticsManager.sharedManager.recordImpression(impressionRef: "\(merchant.merchantId)", impressionType: "Merchant", impressionVariantRef: analyticsZoneString, impressionDisplayName: merchant.merchantName, positionComponent: "MerchantListing", positionIndex: index + 1, positionLocation: "Newsfeed-Home-"+analyticsZoneString, viewKey: viewKey)
                self.initAnalytics(withViewKey: viewKey, impressionKey: self.impressionKey)
            } else if let brand = self.brand {
                self.impressionKey = AnalyticsManager.sharedManager.recordImpression(brandCode: brand.brandCode, impressionRef: "\(brand.brandId)", impressionType: "Brand", impressionVariantRef: analyticsZoneString, impressionDisplayName: brand.brandName, positionComponent: "BrandBanner", positionIndex: index + 1, positionLocation: "AllBrands", viewKey: viewKey)
                self.initAnalytics(withViewKey: viewKey, impressionKey: self.impressionKey)
            }
        }
    }
    
    var analyticsZoneString = "RedZone"
    
    @objc func didSelectImage(_ gesture : UITapGestureRecognizer) {
        if let brand = self.brand {
            //record action
            self.recordAction(.Tap, sourceRef: "\(brand.brandId)", sourceType: .Brand, targetRef: "PLP", targetType: .View)
            
            self.delegate?.onSelect(brand: brand)
        } else if let merchant = self.merchant{
            self.delegate?.onSelect(merchant: merchant)
            
            //record action
            self.recordAction(.Tap,sourceRef: merchant.merchantCode, sourceType: .Merchant,targetRef: "MPP", targetType: .View)
            
        }
    }

}
