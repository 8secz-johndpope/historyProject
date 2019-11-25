//
//  StyleTagAndGetPriceCell.swift
//  storefront-ios
//
//  Created by Leslie Zhang on 2018/9/4.
//  Copyright © 2018年 WWE & CO. All rights reserved.
//

import UIKit

class StyleTagAndGetPriceCell: UICollectionViewCell {
    static public let CellIdentifier = "StyleTagAndGetPriceCell"
    static public let CellHeight: CGFloat = 28
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

    //MARK: - init
    override init(frame: CGRect) {
        super.init(frame: frame)
        
        self.contentView.addSubview(oneTagView)
        self.contentView.addSubview(expressFeeButton)
        self.contentView.addSubview(iconImageView)
        self.contentView.addSubview(tipLabel)
        self.contentView.addSubview(getPriceLabel)
        
        oneTagView.snp.makeConstraints { (make) in
            make.left.equalTo(self.contentView).offset(15)
            make.centerY.equalTo(self.contentView)
        }
        getPriceLabel.snp.makeConstraints { (make) in
            make.right.equalTo(self.contentView).offset(-15)
            make.centerY.equalTo(self.contentView)
        }
        tipLabel.snp.makeConstraints { (make) in
            make.right.equalTo(getPriceLabel.snp.left)
            make.centerY.equalTo(self.contentView)
        }
        iconImageView.snp.makeConstraints { (make) in
            make.right.equalTo(tipLabel.snp.left).offset(-2)
            make.centerY.equalTo(self.contentView)
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
            make.centerY.equalTo(self.contentView)
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
}
