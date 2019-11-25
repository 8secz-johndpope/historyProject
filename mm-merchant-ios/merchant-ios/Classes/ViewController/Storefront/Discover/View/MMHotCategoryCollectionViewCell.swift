//
//  MMHotCategoryCollectionViewCell.swift
//  storefront-ios
//
//  Created by Demon on 20/8/18.
//  Copyright © 2018年 WWE & CO. All rights reserved.
//

import UIKit

class MMHotCategoryCollectionViewCell: UICollectionViewCell {
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        
        contentView.addSubview(iconImageView)
        contentView.addSubview(categoryNameLb)
        contentView.addSubview(discountLb)
        
        setNeedsUpdateConstraints()
    }
    
    override func updateConstraints() {
        iconImageView.snp.makeConstraints { (make) in
            make.height.width.equalTo(54)
            make.centerX.equalTo(self.contentView.snp.centerX)
            make.top.equalTo(self.contentView.snp.top).offset(20)
        }
        categoryNameLb.snp.makeConstraints { (make) in
            make.top.equalTo(self.iconImageView.snp.bottom).offset(10)
            make.left.right.equalTo(self.contentView)
            make.height.lessThanOrEqualTo(35)
        }
        
        let textWidth = discountLb.text!.getTextWidth(height: 14, font: UIFont.systemFont(ofSize: 10)) + 5
        discountLb.snp.makeConstraints { (make) in
            make.top.equalTo(self.categoryNameLb.snp.bottom).offset(4)
            make.centerX.equalTo(self.contentView.snp.centerX)
            make.width.equalTo(textWidth)
            make.height.equalTo(14)
        }
        
        super.updateConstraints()
    }
    
    private lazy var iconImageView: UIImageView = {
        let im = UIImageView()
        im.backgroundColor = UIColor.secondary2()
        return im
    }()
    
    private lazy var categoryNameLb: UILabel = {
        let lb = UILabel()
        lb.font = UIFont.regularFontWithSize(size: 12)
        lb.textColor = UIColor(hexString: "#333333")
        lb.numberOfLines = 2
        lb.textAlignment = .center
        lb.text = "Coach_Gucci_PAPA"
        return lb
    }()
    
    private lazy var discountLb: UILabel = {
        let lb = UILabel()
        lb.font = UIFont.regularFontWithSize(size: 10)
        lb.textColor = UIColor(hexString: "#ED2247")
        lb.round(1)
        lb.viewBorder(UIColor(hexString: "#ED2247"), width: 0.5)
        lb.textAlignment = .center
        lb.text = "4折起"
        return lb
    }()
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}

class MMHotBrandCollectionViewCell: UICollectionViewCell {
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        
        contentView.addSubview(brandImageView)
        
        brandImageView.snp.makeConstraints { (make) in
            make.edges.equalTo(self.contentView)
        }
    }

    lazy var brandImageView: UIImageView = {
        let im = UIImageView()
        im.round(5)
        return im
    }()
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}

class MMHotBrandCollectionHeaderView: UICollectionReusableView {
    
    public var sectionText: String = "" {
        didSet {
            self.brandNameLb.text = sectionText
        }
    }
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        
        addSubview(brandNameLb)
        addSubview(leftLine)
        addSubview(rightLine)
        
        setNeedsUpdateConstraints()
    }
    
    override func updateConstraints() {
        brandNameLb.snp.makeConstraints { (make) in
            make.center.equalTo(self)
            make.height.equalTo(20)
            make.width.greaterThanOrEqualTo(20)
        }
        leftLine.snp.makeConstraints { (make) in
            make.centerY.equalTo(self.snp.centerY)
            make.width.equalTo(14)
            make.height.equalTo(1)
            make.right.equalTo(self.brandNameLb.snp.left).offset(-15)
        }
        rightLine.snp.makeConstraints { (make) in
            make.centerY.equalTo(self.snp.centerY)
            make.width.height.equalTo(self.leftLine)
            make.left.equalTo(self.brandNameLb.snp.right).offset(15)
        }
        super.updateConstraints()
    }
    
    private lazy var brandNameLb: UILabel = {
        let l = UILabel()
        l.textAlignment = .center
        l.font = UIFont.regularFontWithSize(size: 14)
        l.textColor = UIColor(hexString: "#333333")
        return l
    }()
    
    private lazy var leftLine: UILabel = {
        let l = UILabel()
        l.backgroundColor = UIColor(hexString: "#CCCCCC")
        return l
    }()
    
    private lazy var rightLine: UILabel = {
        let l = UILabel()
        l.backgroundColor = UIColor(hexString: "#CCCCCC")
        return l
    }()
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}

class MMHotBrandCollectionFooterView: UICollectionReusableView {
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        
        addSubview(backgroundView)
        backgroundView.addSubview(allBrandLb)
        backgroundView.addSubview(arrowImageView)
        
        setNeedsUpdateConstraints()
    }
    
    override func updateConstraints() {
        backgroundView.snp.makeConstraints { (make) in
            make.centerX.equalTo(self.snp.centerX)
            make.top.equalTo(self.snp.top)
            make.size.equalTo(CGSize(width: 130, height: 32))
        }
        allBrandLb.snp.makeConstraints { (make) in
            make.center.equalTo(self.backgroundView)
            make.size.equalTo(CGSize(width: 50, height: 18))
        }
        arrowImageView.snp.makeConstraints { (make) in
            make.left.equalTo(self.allBrandLb.snp.right).offset(2)
            make.centerY.equalTo(self.backgroundView.snp.centerY)
            make.size.equalTo(CGSize(width: 7, height: 10))
        }
        super.updateConstraints()
    }
    
    lazy var backgroundView: UIView = {
        let v = UIView()
        v.round(5)
        v.viewBorder(UIColor(hexString: "#E7E7E7"), width: 1)
        return v
    }()
    
    private lazy var allBrandLb: UILabel = {
        let l = UILabel()
        l.text = String.localize("LB_ALL_BRAND")
        l.textColor = UIColor(hexString: "#333333")
        l.font = UIFont.regularFontWithSize(size: 12)
        l.textAlignment = .center
        return l
    }()
    
    private lazy var arrowImageView = UIImageView(image: UIImage(named: "arrows_ic"))
    
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}
