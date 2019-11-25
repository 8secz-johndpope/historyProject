//
//  CMSPageNewsfeedCommodityCell.swift
//  MMDemoForLeslie_Swift4.0
//
//  Created by Leslie Zhang on 2018/3/28.
//  Copyright © 2018年 Leslie Zhang. All rights reserved.
//

import UIKit
import YYText
import Kingfisher

class CMSPageNewsfeedCommodityCell: CMSPageNewsfeedCell {
    override func prepareForReuse() {
        super.prepareForReuse()
        
        self.contentImageView.image = nil
    }
    
    lazy var contentImageView:UIImageView = {
        let contentImageView = UIImageView()
        contentImageView.backgroundColor = UIColor.white
        return contentImageView
    }()
    
    lazy var titleLabel:UILabel = {
        let titleLabel = UILabel()
        titleLabel.font = UIFont.systemFont(ofSize: 14)
        return titleLabel
    }()
    
    lazy var contentLabel:UILabel = {
        let contentLabel = UILabel()
        contentLabel.font = UIFont.systemFont(ofSize: 12)
        contentLabel.numberOfLines = 2
        contentLabel.textAlignment = NSTextAlignment.left
        contentLabel.textColor = UIColor.secondary2()
        return contentLabel
    }()
    
    lazy var priceLabel:UILabel = {
        let priceLabel = UILabel()
        priceLabel.font = UIFont.systemFont(ofSize: 12)
        priceLabel.numberOfLines = 0
        return priceLabel
    }()
    
    lazy var statusImageView:UIImageView = {
        let statusImageView = UIImageView()
        statusImageView.image = UIImage(named: "video_ic")
        statusImageView.sizeToFit()
        statusImageView.isHidden = true
        return statusImageView
    }()
    
    lazy var testLabel:UILabel = {
        let testLabel = UILabel()
        testLabel.font = UIFont.systemFont(ofSize: 13)
        testLabel.textColor = UIColor.red
        testLabel.numberOfLines = 0
        testLabel.isHidden = true
        return testLabel
    }()
    
    lazy var oneTagView:UIImageView = {
        let oneTagView = UIImageView()
        oneTagView.sizeToFit()
        return oneTagView
    }()
    
    lazy var twoTagView:UIImageView = {
        let twoTagView = UIImageView()
        twoTagView.sizeToFit()
        return twoTagView
    }()
    
    lazy var threeTagView:UIImageView = {
        let threeTagView = UIImageView()
        threeTagView.sizeToFit()
        return threeTagView
    }()
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        
        self.backgroundColor = UIColor.white
        
        self.addSubview(backgroundImageView)
        backgroundImageView.addSubview(contentImageView)
        backgroundImageView.addSubview(titleLabel)
        backgroundImageView.addSubview(contentLabel)
        backgroundImageView.addSubview(priceLabel)
        backgroundImageView.addSubview(statusImageView)
        backgroundImageView.addSubview(testLabel)
        backgroundImageView.addSubview(oneTagView)
        backgroundImageView.addSubview(twoTagView)
        backgroundImageView.addSubview(threeTagView)
        
        contentImageView.snp.remakeConstraints { (make) in
            make.top.equalTo(backgroundImageView).offset(1)
            make.left.right.equalTo(backgroundImageView)
            make.height.equalTo(backgroundImageView.snp.width)
        }
        titleLabel.snp.makeConstraints { (make) in
            make.bottom.equalTo(contentLabel.snp.top).offset(-MMMargin.CMS.titleToContent)
            make.width.equalTo(backgroundImageView).offset(-20)
            make.height.equalTo(20)
            make.left.equalTo(backgroundImageView).offset(10)
        }
        contentLabel.snp.makeConstraints { (make) in
            make.bottom.equalTo(priceLabel.snp.top).offset(-MMMargin.CMS.contentToPrice)
            make.width.equalTo(titleLabel)
            make.height.lessThanOrEqualTo(30)
            make.centerX.equalTo(backgroundImageView)
        }
        priceLabel.snp.makeConstraints { (make) in
            make.bottom.equalTo(oneTagView.snp.top).offset(-MMMargin.CMS.priceToTag)
            make.width.equalTo(titleLabel)
            make.height.equalTo(15)
            make.centerX.equalTo(backgroundImageView)
        }
        oneTagView.snp.makeConstraints { (make) in
            make.left.equalTo(titleLabel)
            make.height.equalTo(12)
            make.bottom.equalTo(backgroundImageView).offset(-MMMargin.CMS.defultMargin)
        }
        twoTagView.snp.makeConstraints { (make) in
            make.left.equalTo(oneTagView.snp.right).offset(5)
            make.height.equalTo(12)
            make.top.equalTo(oneTagView)
        }
        threeTagView.snp.makeConstraints { (make) in
            make.left.equalTo(twoTagView.snp.right).offset(5)
            make.height.equalTo(12)
            make.top.equalTo(oneTagView)
        }
        statusImageView.snp.makeConstraints { (make) in
            make.top.equalTo(backgroundImageView).offset(MMMargin.CMS.defultMargin)
            make.right.equalTo(backgroundImageView).offset(-MMMargin.CMS.defultMargin)
        }
        testLabel.snp.makeConstraints { (make) in
            make.left.top.equalTo(contentImageView)
        }
        
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    @objc override func ssn_onDisplay(_ tableView: UIScrollView, model: AnyObject,atIndexPath indexPath: IndexPath, reused: Bool) {
        if let cellModel: CMSPageNewsfeedCommodityCellModel = model as? CMSPageNewsfeedCommodityCellModel{
            testLabel.text = cellModel.title
            
            if let dataModel = cellModel.data{
                //埋点需要
                self.track_visitId = dataModel.vid
                self.track_media = dataModel.videoUrl
                
                
                backgroundImageView.whenTapped {
                    if let style = dataModel.style {
                        if let delegate = cellModel.delegate {
                            delegate.getDataFromSearchProduct(style)
                        } else {
                            if dataModel.link.length > 0 {
                                Navigator.shared.dopen(dataModel.link)
                            } else {
                                if let defaultSku = style.defaultSku(){
                                    Navigator.shared.dopen(Navigator.mymm.website_product_skuId + String(defaultSku.skuId))
                                }
                            }
                        }
                    }
                }
                if let style = dataModel.style {
                    if style.videoURL.length > 0 {
                        statusImageView.isHidden = false
                    }else{
                        statusImageView.isHidden = true
                    }
                    
                    priceLabel.attributedText = PriceHelper.fillPrice(style.currentPriceSale, priceRetail: style.currentPriceRetail, isSale: style.currentOnSale ? 1: 0,hasValidCoupon:false)
                    
                    titleLabel.text = style.brandName
                    //计算图高宽,可能来自imageKey
                    var whratio: Float = 1.0
                    if let imageUrl = dataModel.imageUrl,let r = imageUrl.whratio() {
                        whratio = r
                    } else if let style = dataModel.style, let r = style.imageDefault.whratio() {
                        whratio = r
                    }
                    if dataModel.h > 0 && dataModel.w > 0 {
                        whratio = Float(dataModel.h/dataModel.w)
                    }
                    if whratio > 2.0 {
                        whratio = 2.0
                    }
                    var imageHeight = ScreenWidth/2.0 - 19
                    imageHeight = (imageHeight * CGFloat(whratio)).densityRounded()
                    contentImageView.snp.remakeConstraints { (make) in
                        make.top.equalTo(backgroundImageView).offset(1)
                        make.left.right.equalTo(backgroundImageView)
                        make.height.equalTo(imageHeight)
                    }
                    setImageView(dataModel: dataModel, imageView: contentImageView)

                    setPriceAndTage(style: style)
                    
                    
                    if let fetch = self.ssn_fetchs as? MMFetchsController<MMCellModel>, let mmVC = fetch.delegate as? MmViewController {
                        var skuFiltering: Sku? = nil
                        if let defaultSku = style.defaultSku() {
                            if skuFiltering == nil {
                                skuFiltering = defaultSku
                            }
                        } else {
                            ErrorLogManager.sharedManager.recordNonFatalError(withException: .NullPointer)
                        }
                        let skuIdFiltering = (skuFiltering != nil) ? skuFiltering!.skuCode : ""
                        let skuNameFiltering = (skuFiltering != nil) ? skuFiltering!.skuName : ""
                        let merchantCode = CacheManager.sharedManager.cachedMerchantById(style.merchantId)?.merchantCode ?? ""
                        let str = AnalyticsManager.sharedManager.recordImpression(brandCode: "",
                                                                                  impressionRef: "\(style.styleCode)",
                            impressionType: "Product",
                            impressionVariantRef: skuIdFiltering,
                            impressionDisplayName: "\(skuNameFiltering)",
                            merchantCode: merchantCode,
                            positionComponent: "Grid",
                            positionIndex: indexPath.row + 1,
                            positionLocation: mmVC.analyticsViewRecord.viewType,//PLP;MPP;BPP
                            viewKey: mmVC.analyticsViewRecord.viewKey)
                        self.initAnalytics(withViewKey: mmVC.analyticsViewRecord.viewKey, impressionKey: str)
                    }
                }
            }
        }
    }
    
    func setPriceAndTage(style:Style) {
        if style.badgeId == 0 {
            contentLabel.text = style.skuName
        }else{
            var imageName = ""
            if style.badgeId == 1{
                imageName = "new_tag"
            }else if style.badgeId == 2{
                imageName = "hot_tag"
            }else if style.badgeId == 3{
                imageName = "samestyle_tag"
            }else if style.badgeId == 4{
                imageName = "unique_tag"
            }
            contentLabel.attributedText = PriceHelper.fillPrice(0.0, priceRetail: 0.0, isSale: 0,hasValidCoupon:true,otherContent:true, content:style.skuName, imageName:imageName, salePriceFontSize:12)
        }
        
        oneTagView.snp.updateConstraints { (make) in
            make.height.equalTo(12)
        }
        twoTagView.snp.updateConstraints { (make) in
            make.height.equalTo(12)
        }
        threeTagView.snp.updateConstraints { (make) in
            make.height.equalTo(12)
        }

        if style.isCrossBorder && style.couponCount != 0 && style.shippingFee == 0 {
            oneTagView.isHidden = false
            twoTagView.isHidden = false
            threeTagView.isHidden = false
            oneTagView.image = UIImage(named: "crossboard_tag")
            twoTagView.image = UIImage(named: "discount_tag")
            threeTagView.image = UIImage(named: "postage_tag")
        } else if style.isCrossBorder && style.couponCount != 0 && style.shippingFee != 0{
            oneTagView.isHidden = false
            twoTagView.isHidden = false
            threeTagView.isHidden = true
            oneTagView.image = UIImage(named: "crossboard_tag")
            twoTagView.image = UIImage(named: "discount_tag")
        } else if style.isCrossBorder && style.couponCount == 0 && style.shippingFee == 0{
            oneTagView.isHidden = false
            twoTagView.isHidden = false
            threeTagView.isHidden = true
            oneTagView.image = UIImage(named: "crossboard_tag")
            twoTagView.image = UIImage(named: "postage_tag")
        } else if style.isCrossBorder && style.couponCount == 0 && style.shippingFee != 0{
            oneTagView.isHidden = false
            twoTagView.isHidden = true
            threeTagView.isHidden = true
            oneTagView.image = UIImage(named: "crossboard_tag")
        } else if !style.isCrossBorder && style.couponCount != 0 && style.shippingFee == 0{
            oneTagView.isHidden = false
            twoTagView.isHidden = false
            threeTagView.isHidden = true
            oneTagView.image = UIImage(named: "discount_tag")
            twoTagView.image = UIImage(named: "postage_tag")
        } else if !style.isCrossBorder && style.couponCount != 0 && style.shippingFee != 0{
            oneTagView.isHidden = false
            twoTagView.isHidden = true
            threeTagView.isHidden = true
            oneTagView.image = UIImage(named: "discount_tag")
        } else if !style.isCrossBorder && style.couponCount == 0 && style.shippingFee == 0{
            oneTagView.isHidden = false
            twoTagView.isHidden = true
            threeTagView.isHidden = true
            oneTagView.image = UIImage(named: "postage_tag")
        } else if !style.isCrossBorder && style.couponCount == 0 && style.shippingFee != 0 {
            oneTagView.snp.updateConstraints { (make) in
                make.height.equalTo(0)
            }
            twoTagView.snp.updateConstraints { (make) in
                make.height.equalTo(0)
            }
            threeTagView.snp.updateConstraints { (make) in
                make.height.equalTo(0)
            }
        }
    }
    
    open func setProductCell(style: Style?, sku: Sku?) {
        if let style = style, let _ = sku {
            //埋点需要
            self.track_visitId = style.vid
            
            if style.videoURL.length > 0 {
                statusImageView.isHidden = false
            }else{
                statusImageView.isHidden = true
            }
            
            priceLabel.attributedText = PriceHelper.fillPrice(style.currentPriceSale, priceRetail: style.currentPriceRetail, isSale: style.currentOnSale ? 1: 0,hasValidCoupon:false)
            
            titleLabel.text = style.brandName
            //计算图高宽,可能来自imageKey
            var whratio: Float = 1.0
            if let r = style.imageDefault.whratio() {
                whratio = r
            }
            if whratio > 2.0 {
                whratio = 2.0
            }

            var imageHeight = ScreenWidth/2.0 - 19
            imageHeight = (imageHeight * CGFloat(whratio)).densityRounded()
            contentImageView.snp.remakeConstraints { (make) in
                make.top.equalTo(backgroundImageView).offset(1)
                make.left.right.equalTo(backgroundImageView)
                make.height.equalTo(imageHeight)
            }
            KingfisherManager.shared.retrieveImage(with: ImageURLFactory.URLSize512(style.currentImageKey, category: .product), options: nil, progressBlock: nil, completionHandler: { (image, error, cacheType, imageURL) in
                self.contentImageView.image = image
                self.contentImageView.contentMode = .scaleAspectFit
    
                if  !cacheType.cached {
                    self.contentImageView.fadeIn(duration: 0.5)
                }
            })
            setPriceAndTage(style: style)
            
        }
    }
}
