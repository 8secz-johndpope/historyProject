//
//  WeiboUserCollectionViewCell.swift
//  merchant-ios
//
//  Created by khanh.nguyen on 2/7/17.
//  Copyright © 2017 WWE & CO. All rights reserved.
//

import UIKit

class WeiboUserCollectionViewCell: UICollectionViewCell {
    
    var profileImageView = UIImageView()
    var nameLabel = UILabel()
    private var inviteButton =  UIButton()
    var lineView = UIView()
    var iconInvite = UIImageView()
    private final let Padding : CGFloat = 5
    
    var inviteClickedBlock : ((WeiboUser) -> Void)?
    
    
    
    private var friend : WeiboUser?
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        
        profileImageView.clipsToBounds = true
        self.contentView.addSubview(profileImageView)
        
        lineView.backgroundColor = UIColor.secondary1()
        contentView.addSubview(lineView)
        
        self.contentView.addSubview(inviteButton)
        
        nameLabel.formatSize(15)
        nameLabel.text = ""
        nameLabel.textColor = UIColor.secondary2()
        nameLabel.numberOfLines = 1
        nameLabel.lineBreakMode = .byTruncatingTail
        contentView.addSubview(nameLabel)
        
        
        iconInvite.image = UIImage(named: "icon_plus_blue")
        inviteButton.setTitle(String.localize("LB_CA_REF_INVITE"), for: UIControlState())
        inviteButton.setTitleColor(UIColor.weiboButtonColor(), for: UIControlState())
        inviteButton.titleEdgeInsets = UIEdgeInsets(top: 0, left: 10, bottom: 0, right: 0)
        inviteButton.titleLabel!.font = UIFont.systemFont(ofSize: 12)
        inviteButton.titleLabel!.adjustsFontSizeToFitWidth = true
        inviteButton.titleLabel!.minimumScaleFactor = 0.5
        inviteButton.addSubview(iconInvite)
        
        inviteButton.layer.borderColor = UIColor.weiboButtonColor().cgColor
        inviteButton.titleLabel?.font = UIFont(name: Constants.Font.Normal, size: 12)
        inviteButton.layer.cornerRadius = Constants.Value.FollowButtonCornerRadius
        inviteButton.layer.borderWidth = Constants.Value.FollowButtonBorderWidth
    }

    
    override func layoutSubviews() {
        super.layoutSubviews()
        let size = CGFloat(40)
        profileImageView.frame = CGRect(x: Margin.left, y: (self.bounds.sizeHeight - size) / 2, width: size, height: size)
        profileImageView.layer.cornerRadius = size / 2
        
        let inviteButtonSize = ButtonFollow.ButtonFollowSize
        inviteButton.frame = CGRect(x: self.bounds.sizeWidth - Margin.right - inviteButtonSize.width, y: (self.bounds.sizeHeight - inviteButtonSize.height) / 2, width: inviteButtonSize.width, height: inviteButtonSize.height)
        iconInvite.frame = CGRect(x: Margin.left / 2 , y: (inviteButtonSize.height - ButtonFollow.ImageViewSize.height) / 2 , width: ButtonFollow.ImageViewSize.width, height:ButtonFollow.ImageViewSize.height)
        
        nameLabel.frame = CGRect(x: profileImageView.frame.maxX + Margin.left, y: (self.bounds.sizeHeight - CGFloat(20)) / 2, width: inviteButton.frame.minX - profileImageView.frame.maxX - Margin.left * 2, height: 20)
        lineView.frame = CGRect(x: 0, y: self.bounds.sizeHeight - 1 , width: self.bounds.sizeWidth, height: 1)
    }
    
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    func setData(_ friend: WeiboUser, inviteClicked: @escaping ((WeiboUser) -> Void)){
        self.nameLabel.text = friend.screenName
        if let url = URL(string: friend.profileImageUrl) {
            profileImageView.kf.setImage(with: url)
        }
        
        self.friend = friend
        self.inviteClickedBlock = inviteClicked
        self.inviteButton.addTarget(self, action: #selector(WeiboUserCollectionViewCell.inviteClicked), for: UIControlEvents.touchDown)
    }
    
    @objc func inviteClicked() {
        if let inviteBlock = inviteClickedBlock, let user = friend {
            inviteBlock(user)
        }
    }
}
