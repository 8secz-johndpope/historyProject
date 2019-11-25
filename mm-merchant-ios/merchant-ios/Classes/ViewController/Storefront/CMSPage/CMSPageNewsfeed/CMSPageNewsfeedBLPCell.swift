//
//  CMSPageNewsfeedBLPCell.swift
//  MMDemoForLeslie_Swift4.0
//
//  Created by Leslie Zhang on 2018/3/28.
//  Copyright © 2018年 Leslie Zhang. All rights reserved.
//

import UIKit

class CMSPageNewsfeedBLPCell: CMSPageNewsfeedCell {
    override func prepareForReuse() {
        super.prepareForReuse()
        
        self.contentImageView.image = nil
    }
   //MARK: - life cycle
    override init(frame: CGRect) {
        super.init(frame: frame)
        
        self.backgroundColor = UIColor.white
        
        backgroundImageView.addSubview(contentImageView)
        backgroundImageView.addSubview(titleLabel)
        backgroundImageView.addSubview(contentLabel)
        backgroundImageView.addSubview(statusImageView)
        backgroundImageView.addSubview(testLabel)
        backgroundImageView.addSubview(oneTagView)
        
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
        statusImageView.snp.makeConstraints { (make) in
            make.top.equalTo(backgroundImageView).offset(MMMargin.CMS.defultMargin)
            make.right.equalTo(backgroundImageView).offset(-MMMargin.CMS.defultMargin)
        }
        testLabel.snp.makeConstraints { (make) in
            make.left.top.equalTo(contentImageView)
        }
        oneTagView.snp.makeConstraints { (make) in
            make.left.equalTo(titleLabel)
            make.bottom.equalTo(backgroundImageView).offset(-MMMargin.CMS.defultMargin)
        }
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    //MARK: - private methods
    func setTageUpdateLayout(brand:Brand) {
        if  brand.couponCount == 0 {
            contentLabel.snp.remakeConstraints{ (make) in
                make.bottom.equalTo(backgroundImageView).offset(-MMMargin.CMS.defultMargin)
                make.width.equalTo(titleLabel)
                make.centerX.equalTo(backgroundImageView)
            }
            oneTagView.isHidden = true

        }else{
            contentLabel.snp.remakeConstraints{ (make) in
                make.bottom.equalTo(oneTagView.snp.top).offset(-MMMargin.CMS.priceToTag)
                make.width.equalTo(titleLabel)
                make.centerX.equalTo(backgroundImageView)
            }
            oneTagView.isHidden = false
            
            if  brand.couponCount == 3 {
                oneTagView.image = UIImage(named: "hotbrand_tag")
            } else {
                oneTagView.image = UIImage(named: "discount_tag")
            }
            
        }
        
        if brand.newStyleCount == 0 && brand.newSaleCount == 0 {
            contentLabel.text = ""
            titleLabel.snp.remakeConstraints { (make) in
                if  brand.couponCount == 0{
                    make.bottom.equalTo(backgroundImageView).offset(-MMMargin.CMS.defultMargin)
                }else{
                    make.bottom.equalTo(contentLabel.snp.top).offset(-MMMargin.CMS.titleToContent)
                }
                make.width.equalTo(backgroundImageView).offset(-20)
                make.left.equalTo(backgroundImageView).offset(MMMargin.CMS.defultMargin)
            }
            
        }else{
            if brand.newStyleCount != 0 && brand.newSaleCount == 0{
                contentLabel.text = "上新\(brand.newStyleCount)件 "
            }else if brand.newStyleCount == 0 && brand.newSaleCount != 0{
                contentLabel.text = "折扣\(brand.newSaleCount)件"
            }else if brand.newStyleCount != 0 && brand.newSaleCount != 0{
                contentLabel.text = "上新\(brand.newStyleCount)件 折扣\(brand.newSaleCount)件"
            }
            titleLabel.snp.remakeConstraints { (make) in
                make.bottom.equalTo(contentLabel.snp.top).offset(-MMMargin.CMS.titleToContent)
                make.width.equalTo(backgroundImageView).offset(-20)
                make.left.equalTo(backgroundImageView).offset(MMMargin.CMS.defultMargin)
            }
        }
    }

    @objc override func ssn_onDisplay(_ tableView: UIScrollView, model: AnyObject,atIndexPath indexPath: IndexPath, reused: Bool) {
        if let cellModel: CMSPageNewsfeedBLPCellModel = model as? CMSPageNewsfeedBLPCellModel{
            testLabel.text = cellModel.title
            
            if let dataModel = cellModel.data {
                //埋点需要
                self.track_visitId = dataModel.vid
                self.track_media = dataModel.videoUrl
                
                if let brand = dataModel.brand {
                    setTageUpdateLayout(brand: brand)
                }
                titleLabel.text = dataModel.content
                
                setImageView(dataModel: dataModel, imageView: contentImageView)
                
                backgroundImageView.whenTapped {
                    Navigator.shared.dopen(dataModel.link)
                }
            }
        }
    }
    
    //MARK: - lazy
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
}
