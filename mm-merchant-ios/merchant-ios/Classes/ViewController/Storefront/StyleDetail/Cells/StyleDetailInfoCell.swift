//
//  StyleDetailInfoCell.swift
//  storefront-ios
//
//  Created by Leslie Zhang on 15/09/2018.
//  Copyright © 2018 WWE & CO. All rights reserved.
//

import UIKit
protocol StyleDetailInfoCellDelegage: NSObjectProtocol{
    func collectButtonSelect()
}
class StyleDetailInfoCell: UICollectionViewCell {
    weak var delegate:StyleDetailInfoCellDelegage?
    var price:String? {
        didSet {
            if let str = price {
                getPriceLabel.text = str
            }
        }
    }
    var isHiddenPrice:Bool? {
        didSet {
            if let hidden = isHiddenPrice {
                if hidden {
                    getPriceLabel.isHidden = true
                    iconImageView.isHidden = true
                    tipLabel.isHidden = true
                } else {
                    getPriceLabel.isHidden = false
                    iconImageView.isHidden = false
                    tipLabel.isHidden = false
                }
                setNeedsUpdateConstraints()
            }
        }
    }
    var isCrossBorder:Bool? {
        didSet {
            if let crossBorder = isCrossBorder {
                if crossBorder {
                    oneTagView.isHidden = false
                } else {
                    oneTagView.isHidden = true
                }
                setNeedsUpdateConstraints()
            }
        }
    }
    var expressFee:String? {
        didSet {
            var expressStr = String.localize("LB_CA_ALL_FREE_SHIPPING")
            if let express = expressFee,express.length > 0 {
                expressStr = String.localize("LB_CA_FREE_SHIPPING_MIN_AMT_S1").replacingOccurrences(of: "{0}", with: express)
            }
            expressFeeButton.setTitle(expressStr, for: UIControlState.normal)
            expressFeeButton.layer.borderColor = UIColor(hexString: "#ED2247").cgColor
            setNeedsUpdateConstraints()
        }
    }
    
    //Name and collect
    public var styleName:String? {
        didSet {
            if let str = styleName {
                nameLabel.text = str
            }
        }
    }
    
    public func setLike(_ liked: Bool){
        if(liked){
            collectButton.iconImageView.image = UIImage(named: "star_red")
            collectButton.iconTextLabel.text = String.localize("LB_CA_PROFILE_COLLECTION_COLLECTED")
            
        }else{
            collectButton.iconImageView.image = UIImage(named: "star_profile")
            collectButton.iconTextLabel.text = String.localize("LB_BOOKMARK")
        }
        
    }
    
    //Brand
    public var brandName:String? {
        didSet {
            if let str = brandName {
                brandLabel.text = str
            }
        }
    }
    
    override func ssn_onDisplay(_ tableView: UIScrollView, model: AnyObject, atIndexPath indexPath: IndexPath, reused: Bool) {
        if let cellModel = model as? StyleDetailInfoCellModel {
            if let style = cellModel.style {
                nameLabel.text = style.skuName
                setLike(style.isWished())
                
                brandLabel.text = style.brandName
                expressFee = "200"
                price = "1,200"
                isHiddenPrice = false
                
                brandBackgroundView.whenTapped {
                    Navigator.shared.dopen(Navigator.mymm.website_brand_brandId + String(style.brandId))
                }
            }
            delegate = cellModel.delegate
        }
    }
    
    //MARK: - init
    override init(frame: CGRect) {
        super.init(frame: frame)
        
        self.contentView.addSubview(oneTagView)
        self.contentView.addSubview(expressFeeButton)
        self.contentView.addSubview(iconImageView)
        self.contentView.addSubview(tipLabel)
        self.contentView.addSubview(getPriceLabel)
        
        self.contentView.addSubview(nameLabel)
        self.contentView.addSubview(collectButton)
        
        self.contentView.addSubview(brandBackgroundView)
        self.contentView.addSubview(brandTipLabel)
        self.contentView.addSubview(brandIconImageView)
        self.contentView.addSubview(brandLabel)
        self.contentView.addSubview(rightIconImageView)
        
        oneTagView.snp.makeConstraints { (make) in
            make.left.equalTo(self.contentView).offset(15)
            make.centerY.equalTo(28 / 2)
        }
        getPriceLabel.snp.makeConstraints { (make) in
            make.right.equalTo(self.contentView).offset(-15)
            make.centerY.equalTo(oneTagView)
        }
        tipLabel.snp.makeConstraints { (make) in
            make.right.equalTo(getPriceLabel.snp.left)
            make.centerY.equalTo(oneTagView)
        }
        iconImageView.snp.makeConstraints { (make) in
            make.right.equalTo(tipLabel.snp.left).offset(-2)
            make.centerY.equalTo(oneTagView)
        }
        
        nameLabel.snp.makeConstraints { (make) in
            make.left.equalTo(self.contentView).offset(17)
            make.width.equalTo(ScreenWidth * 0.8)
            make.centerY.equalTo(28 + (60 / 2))
        }
        collectButton.snp.makeConstraints { (make) in
            make.right.equalTo(self.contentView)
            make.width.equalTo(ScreenWidth * 0.2)
            make.height.equalTo(60)
            make.top.equalTo(28)
        }
        
        brandBackgroundView.snp.makeConstraints { (make) in
            make.left.right.bottom.equalTo(self.contentView)
            make.height.equalTo(40)
        }
        brandTipLabel.snp.makeConstraints { (make) in
            make.left.equalTo(15)
            make.centerY.equalTo(28 + 60 + (40 / 2))
        }
        brandIconImageView.snp.makeConstraints { (make) in
            make.centerY.equalTo(brandTipLabel)
            make.left.equalTo(brandTipLabel.snp.right).offset(10)
        }
        brandLabel.snp.makeConstraints { (make) in
            make.centerY.equalTo(brandTipLabel)
            make.left.equalTo(brandIconImageView.snp.right).offset(6)
            make.width.equalTo(ScreenWidth * 0.7)
        }
        rightIconImageView.snp.makeConstraints { (make) in
            make.centerY.equalTo(brandTipLabel)
            make.right.equalTo(self.contentView).offset(-15)
        }
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    //MARK: - private methods
    override func updateConstraints() {
        expressFeeButton.snp.makeConstraints { (make) in
            if oneTagView.isHidden {
                make.left.equalTo(self.contentView).offset(15)
            } else {
                make.left.equalTo(oneTagView.snp.right).offset(7)
            }
            make.centerY.equalTo(28 / 2)
        }
        super.updateConstraints()
    }
    
    //MARK: - lazy
    lazy var oneTagView:UIImageView = {
        let oneTagView = UIImageView()
        oneTagView.sizeToFit()
        oneTagView.image = UIImage(named: "crossbroder")
        return oneTagView
    }()
    lazy var expressFeeButton:UIButton = {
        let expressFeeButton = UIButton()
        expressFeeButton.setTitleColor(UIColor(hexString: "#ED2247"), for: UIControlState.normal)
        expressFeeButton.titleLabel?.font = UIFont.systemFont(ofSize: 10)
        expressFeeButton.layer.borderWidth = 1
        expressFeeButton.layer.borderColor = UIColor.white.cgColor
        expressFeeButton.layer.cornerRadius = 2
        expressFeeButton.layer.masksToBounds = true
        expressFeeButton.titleLabel?.textAlignment = .center
        expressFeeButton.contentEdgeInsets = UIEdgeInsets.init(top: 2, left: 2, bottom: 2, right: 2)
        return expressFeeButton
    }()
    lazy var iconImageView:UIImageView = {
        let iconImageView = UIImageView()
        iconImageView.image = UIImage(named: "question_ic")
        iconImageView.sizeToFit()
        iconImageView.isHidden = true
        return iconImageView
    }()
    lazy var tipLabel:UILabel = {
        let tipLabel = UILabel()
        tipLabel.textColor = UIColor(hexString: "#ED2247")
        tipLabel.font = UIFont.systemFont(ofSize: 10)
        tipLabel.text = String.localize("LB_CA_PDP_ESTIMATED_PRICE")
        tipLabel.isHidden = true
        return tipLabel
    }()
    lazy var getPriceLabel:UILabel = {
        let getPriceLabel = UILabel()
        getPriceLabel.textColor = UIColor(hexString: "#ED2247")
        getPriceLabel.font = UIFont.boldSystemFont(ofSize: 14)
        getPriceLabel.isHidden = true
        return getPriceLabel
    }()
    
    //name
    lazy private var nameLabel:UILabel = {
        let nameLabel = UILabel()
        nameLabel.textColor = UIColor(hexString: "#333333")
        nameLabel.font = UIFont.boldSystemFont(ofSize: 16)
        nameLabel.numberOfLines = 2
        return nameLabel
    }()
    lazy private var collectIconImageView:UIImageView = {
        let collectIconImageView = UIImageView()
        collectIconImageView.image = UIImage(named: "brand_tag")
        collectIconImageView.sizeToFit()
        return collectIconImageView
    }()
    lazy public var collectButton:IconButtonView = {
        let collectButton = IconButtonView()
        collectButton.setType(IconButtonView.ButtonType.wish)
        collectButton.iconImageView.image = UIImage(named: "star_profile")
        collectButton.isUserInteractionEnabled = true
        collectButton.tapHandler = {
            self.delegate?.collectButtonSelect()
        }
        return collectButton
    }()
    
    //brand
    lazy private var brandBackgroundView:UIView = {
        let brandBackgroundView = UIView()
        brandBackgroundView.backgroundColor = UIColor(hexString: "#FAFAFA")
        return brandBackgroundView
    }()
    lazy private var brandTipLabel:UILabel = {
        let brandTipLabel = UILabel()
        brandTipLabel.textColor = UIColor(hexString: "#999999")
        brandTipLabel.font = UIFont.systemFont(ofSize: 12)
        brandTipLabel.text = String.localize("LB_CA_FILTER_BRAND")
        return brandTipLabel
    }()
    lazy private var brandIconImageView:UIImageView = {
        let brandIconImageView = UIImageView()
        brandIconImageView.image = UIImage(named: "brand_tag")
        brandIconImageView.sizeToFit()
        return brandIconImageView
    }()
    lazy private var brandLabel:UILabel = {
        let brandLabel = UILabel()
        brandLabel.textColor = UIColor(hexString: "#333333")
        brandLabel.font = UIFont.systemFont(ofSize: 14)
        return brandLabel
    }()
    lazy private var rightIconImageView:UIImageView = {
        let rightIconImageView = UIImageView()
        rightIconImageView.image = UIImage(named: "arrow_right")
        rightIconImageView.sizeToFit()
        return rightIconImageView
    }()
}
