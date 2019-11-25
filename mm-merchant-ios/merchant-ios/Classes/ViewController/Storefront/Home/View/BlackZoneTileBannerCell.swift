//
//  BlackZoneTileBannerCell.swift
//  merchant-ios
//
//  Created by khanh.nguyen on 5/16/17.
//  Copyright © 2017 WWE & CO. All rights reserved.
//

import UIKit

class BlackZoneTileBannerCell: BannerGridViewCell {
    var imageContainer = UIView()
    override init(frame: CGRect) {
        super.init(frame: frame)
        self.imageView.removeFromSuperview()
        imageContainer.addSubview(imageView)
        self.contentView.addSubview(imageContainer)
    }
    
    override func layoutSubviews() {
        super.layoutSubviews()
        self.contentView.frame = CGRect(x: 0, y: 0, width: self.frame.sizeWidth, height: self.frame.sizeHeight)
        imageContainer.frame = CGRect(x: -1, y: 0, width: self.frame.sizeWidth + 2, height: self.frame.sizeHeight)
        imageContainer.clipsToBounds = true
        self.imageView.frame = CGRect(x: 1, y: 0, width: self.frame.sizeWidth , height: self.frame.sizeHeight)
        self.imageView.clipsToBounds = false
        self.contentView.clipsToBounds = false
        
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override func setBanner(_ banner: Banner, index: Int, isLastCell: Bool) {
        super.setBanner(banner, index: index, isLastCell: isLastCell)
    }
    
    override func setImage(_ imageKey : String, imageView: UIImageView, banner: Banner) {
        imageView.mm_setImageWithURL(ImageURLFactory.URLSize750(imageKey, category: .banner), placeholderImage: UIImage(named: "postPlaceholder"), contentMode: .scaleAspectFill)
        
        if let viewKey = self.analyticsViewKey {
            imageView.initAnalytics(withViewKey: viewKey, impressionKey: AnalyticsManager.sharedManager.recordImpression(impressionRef: "\(banner.bannerKey)",
                impressionType: "Banner",
                impressionVariantRef: "BlackZone",
                impressionDisplayName: "b\(imageView.tag + 1)",
                positionComponent: "TileBanner",
                positionIndex: (imageView.tag + 1),
                positionLocation: "Newsfeed-Home-BlackZone",
                viewKey: viewKey))
        }
    }
    
    override func didSelectBanner(_ gesture : UITapGestureRecognizer) {
        if let view = gesture.view {
            if let banner = self.banner{
                self.delegate?.didSelectBanner(banner)
                //record action
                view.recordAction(.Tap, sourceRef: "b\(imageView.tag + 1)", sourceType: .TileBanner, targetRef: banner.link, targetType: .URL)
            }
        }
    }
    
    class func getCellSize(_ index: Int) -> CGSize {
        let screenSize = ScreenSize
        //let height = ceil(screenSize.width * 185.0 / 375.0)
        let height = ceil(screenSize.width / 2)
        let width = index % 2 == 0 ? ceil(screenSize.width / 2) : floor(screenSize.width / 2)
        return CGSize(width: width, height: height)
    }
}
