//
//  CMSPageNewsfeedMLPCell.swift
//  MMDemoForLeslie_Swift4.0
//
//  Created by Leslie Zhang on 2018/3/28.
//  Copyright © 2018年 Leslie Zhang. All rights reserved.
//

import UIKit

class CMSPageNewsfeedMLPCell: CMSPageNewsfeedCell {
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
        titleLabel.numberOfLines = 0
        return titleLabel
    }()
    
    lazy var contentLabel:UILabel = {
        let contentLabel = UILabel()
        contentLabel.font = UIFont.systemFont(ofSize: 12)
        contentLabel.numberOfLines = 0
        contentLabel.textColor = UIColor.secondary2()
        return contentLabel
    }()
    
    lazy var statusImageView:UIImageView = {
        let statusImageView = UIImageView()
        statusImageView.image = UIImage(named: "multi_icon")
        statusImageView.sizeToFit()
        statusImageView.isHidden = true
        return statusImageView
    }()
    
    lazy var testLabel:UILabel = {
        let testLabel = UILabel()
        testLabel.font = UIFont.systemFont(ofSize: 13)
        testLabel.textColor = UIColor.white
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
        
        backgroundImageView.addSubview(contentImageView)
        backgroundImageView.addSubview(titleLabel)
        backgroundImageView.addSubview(contentLabel)
        backgroundImageView.addSubview(statusImageView)
        backgroundImageView.addSubview(testLabel)
        backgroundImageView.addSubview(oneTagView)
        backgroundImageView.addSubview(twoTagView)
        backgroundImageView.addSubview(threeTagView)
        
        contentImageView.snp.makeConstraints { (make) in
            make.top.left.right.equalTo(backgroundImageView)
            make.height.equalTo(backgroundImageView.snp.width)
        }
        titleLabel.snp.makeConstraints { (make) in
            make.bottom.equalTo(contentLabel.snp.top).offset(-MMMargin.CMS.titleToContent)
            make.width.equalTo(backgroundImageView).offset(-20)
            make.left.equalTo(backgroundImageView).offset(MMMargin.CMS.defultMargin)
        }
        contentLabel.snp.makeConstraints { (make) in
            make.bottom.equalTo(oneTagView.snp.top).offset(-MMMargin.CMS.priceToTag)
            make.width.equalTo(titleLabel)
            make.centerX.equalTo(backgroundImageView)
        }
        oneTagView.snp.makeConstraints { (make) in
            make.left.equalTo(titleLabel)
            make.bottom.equalTo(backgroundImageView).offset(-MMMargin.CMS.defultMargin)
        }
        twoTagView.snp.makeConstraints { (make) in
            make.left.equalTo(oneTagView.snp.right).offset(5)
            make.top.equalTo(oneTagView)
        }
        threeTagView.snp.makeConstraints { (make) in
            make.left.equalTo(twoTagView.snp.right).offset(5)
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
    
    func setTagStatus(dataModel:CMSPageDataModel) {
        if let merchant = dataModel.merchant {
            if  merchant.isCrossBorder == 0 && merchant.isNew == 0 && merchant.couponCount == 0{
                contentLabel.snp.remakeConstraints{ (make) in
                    make.bottom.equalTo(backgroundImageView).offset(-MMMargin.CMS.defultMargin)
                    make.width.equalTo(titleLabel)
                    make.centerX.equalTo(backgroundImageView)
                }
                oneTagView.isHidden = true
                twoTagView.isHidden = true
                threeTagView.isHidden = true
            }else{
                contentLabel.snp.remakeConstraints{ (make) in
                    make.bottom.equalTo(oneTagView.snp.top).offset(-MMMargin.CMS.priceToTag)
                    make.width.equalTo(titleLabel)
                    make.centerX.equalTo(backgroundImageView)
                }
                
                if merchant.isNew != 0 && merchant.isCrossBorder != 0 && merchant.couponCount != 0{
                    oneTagView.isHidden = false
                    twoTagView.isHidden = false
                    threeTagView.isHidden = false
                    oneTagView.image = UIImage(named: "newstore_tag")
                    twoTagView.image = UIImage(named: "crossboard_tag")
                    threeTagView.image = UIImage(named: "discount_tag")
                }else if merchant.isNew != 0 && merchant.isCrossBorder != 0 && merchant.couponCount == 0 {
                    oneTagView.isHidden = false
                    twoTagView.isHidden = false
                    threeTagView.isHidden = true
                    oneTagView.image = UIImage(named: "newstore_tag")
                    twoTagView.image = UIImage(named: "crossboard_tag")
                }else if merchant.isNew != 0 && merchant.isCrossBorder == 0 && merchant.couponCount != 0{
                    oneTagView.isHidden = false
                    twoTagView.isHidden = false
                    threeTagView.isHidden = true
                    oneTagView.image = UIImage(named: "newstore_tag")
                    twoTagView.image = UIImage(named: "discount_tag")
                }else if merchant.isNew != 0 && merchant.isCrossBorder == 0 && merchant.couponCount == 0 {
                    oneTagView.isHidden = false
                    twoTagView.isHidden = true
                    threeTagView.isHidden = true
                    oneTagView.image = UIImage(named: "newstore_tag")
                }else if merchant.isNew == 0 && merchant.isCrossBorder != 0 && merchant.couponCount != 0 {
                    oneTagView.isHidden = false
                    twoTagView.isHidden = false
                    threeTagView.isHidden = true
                    oneTagView.image = UIImage(named: "crossboard_tag")
                    twoTagView.image = UIImage(named: "discount_tag")
                }else if merchant.isNew == 0 && merchant.isCrossBorder != 0 && merchant.couponCount == 0 {
                    oneTagView.isHidden = false
                    twoTagView.isHidden = true
                    threeTagView.isHidden = true
                    oneTagView.image = UIImage(named: "crossboard_tag")
                }else if merchant.isNew == 0 && merchant.isCrossBorder == 0 && merchant.couponCount != 0 {
                    oneTagView.isHidden = false
                    twoTagView.isHidden = true
                    threeTagView.isHidden = true
                    oneTagView.image = UIImage(named: "discount_tag")
                }
            }
            
            if merchant.newStyleCount == 0 && merchant.newSaleCount == 0 {
                contentLabel.text = ""
                titleLabel.snp.remakeConstraints { (make) in
                    if  merchant.isCrossBorder == 0 && merchant.isNew == 0 && merchant.couponCount == 0{
                        make.bottom.equalTo(backgroundImageView).offset(-MMMargin.CMS.defultMargin)
                    }else{
                        make.bottom.equalTo(contentLabel.snp.top).offset(-MMMargin.CMS.titleToContent)
                    }
                    make.width.equalTo(backgroundImageView).offset(-20)
                    make.left.equalTo(backgroundImageView).offset(MMMargin.CMS.defultMargin)
                }
                
            }else{
                if merchant.newStyleCount != 0 && merchant.newSaleCount == 0{
                    contentLabel.text = "上新\(merchant.newStyleCount)件 "
                }else if merchant.newStyleCount == 0 && merchant.newSaleCount != 0{
                    contentLabel.text = "折扣\(merchant.newSaleCount)件"
                }else if merchant.newStyleCount != 0 && merchant.newSaleCount != 0{
                    contentLabel.text = "上新\(merchant.newStyleCount)件 折扣\(merchant.newSaleCount)件"
                }
                
                titleLabel.snp.remakeConstraints { (make) in
                    make.bottom.equalTo(contentLabel.snp.top).offset(-MMMargin.CMS.titleToContent)
                    make.width.equalTo(backgroundImageView).offset(-20)
                    make.left.equalTo(backgroundImageView).offset(MMMargin.CMS.defultMargin)
                }
            }
        }
    }
    
    @objc override func ssn_onDisplay(_ tableView: UIScrollView, model: AnyObject,atIndexPath indexPath: IndexPath, reused: Bool) {
        let cellModel: CMSPageNewsfeedMLPCellModel = model as! CMSPageNewsfeedMLPCellModel
        testLabel.text = cellModel.title

        if let dataModel = cellModel.data {
            //埋点需要
            self.track_visitId = dataModel.vid
            self.track_media = dataModel.videoUrl
            
            setTagStatus(dataModel: dataModel)
            
            setImageView(dataModel: dataModel, imageView: contentImageView)
            
            titleLabel.text = dataModel.content
            
            backgroundImageView.whenTapped {
                var bundle = QBundle()
                if let merchantId = dataModel.merchant?.merchantId {
                    bundle["merchantid"] = QValue(merchantId)
                }
                Navigator.shared.dopen(dataModel.link, params: bundle)
            }
        }
    }
}
