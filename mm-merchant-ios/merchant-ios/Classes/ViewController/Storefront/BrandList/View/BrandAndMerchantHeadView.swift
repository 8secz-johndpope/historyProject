//
//  BrandAndMerchantHeadView.swift
//  storefront-ios
//
//  Created by Leslie Zhang on 2018/6/20.
//  Copyright © 2018年 WWE & CO. All rights reserved.
//

import UIKit

class BrandAndMerchantHeadView: UICollectionReusableView {
    static let MerchantProfileHeaderViewIdentifier = "MerchantProfileHeaderViewIdentifier"
    var follow: Bool? {
        didSet {
            if let follow = follow {
                if follow {
                    updateAttentionButton(backgroundColor: UIColor.clear, title: String.localize("LB_CA_PROFILE_COLLECTION_COLLECTED"), borderWidth: 0.5, borderColor: UIColor.white)
                    
                } else {
                    updateAttentionButton(backgroundColor: UIColor(hexString: "#FF2B5C"), title: String.localize("LB_CA_PROFILE_COLLECTION"), borderWidth: 0, borderColor: UIColor.clear)
                }
            }
        }
    }
    var brand: Brand? {
        didSet {
            if let brand = brand {
  
                let iconImageURL = ImageURLFactory.URLSize256(brand.largeLogoImage, category: .brand)
                let bgImageURL = HeaderMyProfileCell.getCoverImageUrl(brand.profileBannerImage, imageCategory: .brand, width: self.width)
                
                updateData(text: brand.brandName, iconimageURL: iconImageURL, bgImageURL: bgImageURL,followerCount:brand.followerCount)
            }
        }
    }
    var merchant: Merchant? {
        didSet {
            if let merchant = merchant {
                
                
                let iconImageURL = ImageURLFactory.URLSize256(merchant.largeLogoImage, category: .merchant)
                let bgImageURL = ImageURLFactory.URLSize1000(merchant.profileBannerImage, category:.merchant)
                
                updateData(text: merchant.merchantName, iconimageURL: iconImageURL, bgImageURL: bgImageURL,followerCount:merchant.followerCount)
            }
        }
    }
    
    //MARK: - life cycle
    override init(frame: CGRect) {
        super.init(frame: frame)
        
        self.backgroundColor = .gray
        
        self.addSubview(bgImageView)
        self.addSubview(blackBgImageView)
        self.addSubview(iconImageView)
        self.addSubview(brandLabel)
        self.addSubview(attentionButton)
        self.addSubview(attentionLabel)
        
        bgImageView.snp.makeConstraints { (make) in
            make.edges.equalTo(self)
        }
        blackBgImageView.snp.makeConstraints { (make) in
            make.edges.equalTo(self)
        }
        iconImageView.snp.makeConstraints { (make) in
            make.bottom.equalTo(self).offset(-6)
            make.left.equalTo(self).offset(15)
            make.width.height.equalTo(40)
        }
        brandLabel.snp.makeConstraints { (make) in
            make.centerY.equalTo(iconImageView)
            make.left.equalTo(iconImageView.snp.right).offset(11)
            make.right.equalTo(self).offset(-89)
        }
        attentionButton.snp.makeConstraints { (make) in
            make.centerY.equalTo(iconImageView)
            make.width.equalTo(64)
            make.height.equalTo(30)
            make.right.equalTo(self).offset(-14)
        }
        attentionLabel.snp.makeConstraints { (make) in
            make.centerX.equalTo(attentionButton)
            make.bottom.equalTo(attentionButton.snp.top).offset(-5)
        }
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    //MARK: - private methods
    private func updateAttentionButton(backgroundColor:UIColor,title:String,borderWidth:CGFloat,borderColor:UIColor)  {
        attentionButton.backgroundColor = backgroundColor
        attentionButton.setTitle(title, for: .normal)
        attentionButton.layer.borderWidth = borderWidth
        attentionButton.layer.borderColor = borderColor.cgColor
    }
    
    private func updateData(text:String,iconimageURL:URL,bgImageURL:URL,followerCount:Int? = nil) {
        var followText = ""

        if let followerCount = followerCount {
            followText = String(format: "%@ %@", NumberHelper.getNumberMeasurementString(followerCount), String.localize("LB_CA_FOLLOWER"))
            
            if followerCount == 0 {
                attentionLabel.isHidden = true
            } else {
                attentionLabel.isHidden = false
            }
        }
        let labelHeight = CGFloat(text.stringHeightWithMaxWidth((ScreenWidth - 66 - 89), font: UIFont.systemFont(ofSize: 14)))
        if labelHeight > 17 {
            brandLabel.text = "\(text) " + "| " + String.localize("LB_CA_PROFILE_ABOUT") + ">"
        } else {
            brandLabel.text = "\(text)\n" + String.localize("LB_CA_PROFILE_ABOUT") + ">"
        }
        iconImageView.mm_setImageWithURL(iconimageURL, placeholderImage: UIImage(named: "default_cover"))
        bgImageView.mm_setImageWithURL(bgImageURL, placeholderImage: UIImage(named: "default_cover"), contentMode: .scaleAspectFill)
        attentionLabel.text = followText
        
    }
    
    //MARK: - lazy
    private lazy var blackBgImageView:UIView = {
        let blackBgImageView = UIView()
        blackBgImageView.backgroundColor = .black
        blackBgImageView.alpha = 0.4
        return blackBgImageView
    }()
    private lazy var bgImageView:UIImageView = {
        let bgImageView = UIImageView()
        bgImageView.image = UIImage(named: "default_cover")
        return bgImageView
    }()
    private lazy var iconImageView:UIImageView = {
        let iconImageView = UIImageView()
        iconImageView.layer.cornerRadius = 4
        iconImageView.layer.masksToBounds = true
        iconImageView.layer.borderWidth = 0.5
        iconImageView.layer.borderColor = UIColor.white.cgColor
        iconImageView.image = UIImage(named: "default_cover")
        return iconImageView
    }()
    private lazy var brandLabel:UILabel = {
        let brandLabel = UILabel()
        brandLabel.textColor = .white
        brandLabel.numberOfLines = 2
        brandLabel.font = UIFont.systemFont(ofSize: 14)
        return brandLabel
    }()
    public lazy var attentionButton:UIButton = {
        let attentionButton = UIButton()
        attentionButton.layer.cornerRadius = 4
        attentionButton.layer.masksToBounds = true
        attentionButton.setTitleColor(.white, for: .normal)
        attentionButton.titleLabel?.font = UIFont.systemFont(ofSize: 12)
        return attentionButton
    }()
    public lazy var attentionLabel:UILabel = {
        let attentionLabel = UILabel()
        attentionLabel.font = UIFont.systemFont(ofSize: 10)
        attentionLabel.isUserInteractionEnabled = true
        attentionLabel.textColor = .white
        return attentionLabel
    }()
}

