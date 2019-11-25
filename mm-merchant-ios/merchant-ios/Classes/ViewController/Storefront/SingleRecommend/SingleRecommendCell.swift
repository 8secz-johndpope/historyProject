//
//  SingleRecommendCell.swift
//  storefront-ios
//
//  Created by Leslie Zhang on 2018/7/17.
//  Copyright © 2018年 WWE & CO. All rights reserved.
//

import UIKit

class SingleRecommendCell: UICollectionViewCell {
    var cancelTap: (() -> Void)?

    //MARK: - init
    override init(frame: CGRect) {
        super.init(frame: frame)
        
        self.contentView.addSubview(nameLabel)
        self.contentView.addSubview(titleLabel)
        self.contentView.addSubview(cancelButton)
        self.contentView.addSubview(iconImageView)
        
        nameLabel.snp.makeConstraints { (make) in
            make.centerX.equalTo(self.contentView)
            make.bottom.equalTo(titleLabel.snp.top).offset(-4)
        }
        titleLabel.snp.makeConstraints { (make) in
            make.centerX.equalTo(self.contentView)
            make.bottom.equalTo(iconImageView.snp.top).offset(-14)
        }
        cancelButton.snp.makeConstraints { (make) in
            make.centerY.equalTo(titleLabel.snp.top).offset(-2)
            make.right.equalTo(self.contentView).offset(-15)
        }
        iconImageView.snp.makeConstraints { (make) in
            make.centerX.equalTo(self.contentView)
            make.bottom.equalTo(self.contentView).offset(-20)
            make.width.height.equalTo(44)
        }
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    //MARK: - private methods
    override func ssn_onDisplay(_ tableView: UIScrollView, model: AnyObject, atIndexPath indexPath: IndexPath, reused: Bool) {
        if let cellModel: SingleRecommendCellModel = model as? SingleRecommendCellModel {
            self.cancelTap = {
                if let cancelTap = cellModel.cancelTap {
                    cancelTap()
                }
            }
            if let showCancel = cellModel.showCancel {
                if showCancel {
                    cancelButton.isHidden = false
                } else {
                    cancelButton.isHidden = true
                }
            }
        }
    }
    
    //MARK: - event response
    @objc func touchCancelButton()  {
        if let cancelTap = cancelTap {
            cancelTap()
        }
    }
    
    //MARK: - lazy
    lazy private var nameLabel:UILabel = {
        let nameLabel = UILabel()
        nameLabel.numberOfLines = 0
        nameLabel.textAlignment = .center
        nameLabel.font = UIFont.systemFont(ofSize: 16)
        return nameLabel
    }()
    lazy private var titleLabel:UILabel = {
        let titleLabel = UILabel()
        titleLabel.numberOfLines = 0
        titleLabel.textAlignment = .center
        titleLabel.font = UIFont.systemFont(ofSize: 16)
        titleLabel.text = "MyMM今日为你精心推荐~"
        return titleLabel
    }()
    lazy private var cancelButton:UIButton = {
        let cancelButton = UIButton()
        cancelButton.layer.cornerRadius = 12
        cancelButton.layer.masksToBounds = true
        cancelButton.setImage(UIImage(named: "recommend-close"), for: UIControlState.normal)
        cancelButton.imageView?.sizeToFit()
        cancelButton.addTarget(self, action: #selector(touchCancelButton), for: .touchUpInside)
        return cancelButton
    }()
    
    lazy private var iconImageView:UIImageView = {
        let iconImageView = UIImageView()
        iconImageView.layer.cornerRadius = 22
        iconImageView.layer.masksToBounds = true
        if LoginManager.getLoginState() == .validUser {
            let user = Context.getUserProfile()
            if user.profileImage.length > 0 {
                iconImageView.mm_setImageWithURL(ImageURLFactory.URLSize128(user.profileImage, category: .user), placeholderImage: UIImage(named: "default_profile_icon"))
            } else {
                iconImageView.image = UIImage(named: "default_profile_icon")
            }
            nameLabel.text = "Hey \(user.displayName)"
            
        } else {
            nameLabel.text = "Hey "
            iconImageView.image = UIImage(named: "default_profile_icon")
        }
        return iconImageView
    }()
}
