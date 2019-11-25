//
//  StyleNameAndCollectCell.swift
//  storefront-ios
//
//  Created by Leslie Zhang on 2018/9/4.
//  Copyright © 2018年 WWE & CO. All rights reserved.
//

import UIKit

class StyleNameAndCollectCell: UICollectionViewCell {
    static public let CellIdentifier = "StyleNameAndCollectCell"
    static public let CellHeight: CGFloat = 60
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
    
    //MARK: - init
    override init(frame: CGRect) {
        super.init(frame: frame)
        
        self.contentView.addSubview(nameLabel)
        self.contentView.addSubview(collectButton)
        
        nameLabel.snp.makeConstraints { (make) in
            make.left.equalTo(self.contentView).offset(17)
            make.width.equalTo(ScreenWidth * 0.8)
            make.centerY.equalTo(self.contentView)
        }
        collectButton.snp.makeConstraints { (make) in
            make.right.top.bottom.equalTo(self.contentView)
            make.width.equalTo(ScreenWidth * 0.2)
        }
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    //MARK: - lazy
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
    lazy private var tipLabel:UILabel = {
        let tipLabel = UILabel()
        tipLabel.textColor = UIColor(hexString: "#999999")
        tipLabel.font = UIFont.systemFont(ofSize: 11)
        return tipLabel
    }()
    lazy public var collectButton:IconButtonView = {
        let collectButton = IconButtonView()
        collectButton.setType(IconButtonView.ButtonType.wish)
        collectButton.iconImageView.image = UIImage(named: "star_profile")
        collectButton.isUserInteractionEnabled = true
        return collectButton
    }()
}
