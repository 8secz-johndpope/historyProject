//
//  BannerGridViewCell.swift
//  merchant-ios
//
//  Created by Sang Nguyen on 8/2/16.
//  Copyright © 2016 WWE & CO. All rights reserved.
//

import UIKit

class BannerGridViewCell: UICollectionViewCell {
    var imageView = UIImageView()
    var banner: Banner?
    weak var delegate : BannerCellDelegate?
    var isLastCell = false
    var isImageFullCell = false
    override init(frame: CGRect) {
        super.init(frame: frame)
        backgroundColor = UIColor.white
        imageView.isUserInteractionEnabled = true
        imageView.image = UIImage(named: "holder")
        
        imageView.addGestureRecognizer(UITapGestureRecognizer(target: self, action: #selector(self.didSelectBanner)))
        self.contentView.addSubview(imageView)
    }
    
    override func layoutSubviews() {
        super.layoutSubviews()
        if isLastCell {
            self.imageView.frame = self.contentView.bounds
        }else {
            self.imageView.frame = CGRect(x: 0, y: 0, width: self.contentView.frame.sizeWidth, height: self.contentView.frame.sizeHeight - (isImageFullCell ? 0 : HomeHeaderView.MarginTop))
        }
    }
    
    func setBanner(_ banner : Banner, index: Int, isLastCell: Bool) {
        
        self.banner = banner
        self.imageView.tag = index
        self.setImage(banner.bannerImage, imageView: imageView, banner: banner)
        self.isLastCell = isLastCell
        self.layoutSubviews()
    }
    
    func setImage(_ imageKey : String, imageView: UIImageView, banner: Banner) {
        imageView.mm_setImageWithURL(ImageURLFactory.URLSize1000(imageKey, category: .banner), placeholderImage: UIImage(named: "postPlaceholder"), contentMode: .scaleAspectFill)
        
        if let viewKey = self.analyticsViewKey {
            imageView.initAnalytics(withViewKey: viewKey, impressionKey: AnalyticsManager.sharedManager.recordImpression(impressionRef: "\(banner.bannerKey)", impressionType: "Banner", impressionVariantRef: "RedZone", impressionDisplayName: "r\(imageView.tag + 1)", positionComponent: "TileBanner", positionIndex: (imageView.tag + 1), positionLocation: "Newsfeed-Home-RedZone", viewKey: viewKey))
        }
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    @objc func didSelectBanner(_ gesture : UITapGestureRecognizer) {
        if let view = gesture.view {
            if let banner = self.banner{
                self.delegate?.didSelectBanner(banner)
             
                //record action
                view.recordAction(.Tap, sourceRef: "r\(imageView.tag + 1)", sourceType: .TileBanner, targetRef: banner.link, targetType: .URL)
            }
        }
    }
}
