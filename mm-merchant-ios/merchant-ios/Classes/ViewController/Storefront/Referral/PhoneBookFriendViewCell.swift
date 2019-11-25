//
//  PhoneBookFriendViewCell.swift
//  merchant-ios
//
//  Created by khanh.nguyen on 2/8/17.
//  Copyright © 2017 WWE & CO. All rights reserved.
//

import UIKit

protocol PhoneBookFriendCellDelegate: NSObjectProtocol {
    func didTouchOnInviteButton(_ contact: Contact)
}

class PhoneBookFriendViewCell: UICollectionViewCell {
    
    var nameLabel = UILabel()
    var inviteButton =  UIButton()
    var lineView = UIView()
    var iconInvite = UIImageView()
    var totalFriendLabel = UILabel()
    var HeightLabel = CGFloat(20)
    weak var delegate:PhoneBookFriendCellDelegate?
    
    private final let Padding : CGFloat = 5
    var contact: Contact?
    
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        
        lineView.backgroundColor = UIColor.secondary1()
        contentView.addSubview(lineView)
        
        inviteButton.addTarget(self, action: #selector(PhoneBookFriendViewCell.didTouchOnInviteButton), for: .touchUpInside)
        self.contentView.addSubview(inviteButton)
        
        nameLabel.text = ""
        nameLabel.textColor = UIColor.secondary2()
        nameLabel.numberOfLines = 1
        nameLabel.lineBreakMode = .byTruncatingTail
        nameLabel.font = UIFont(name:"HelveticaNeue-Bold", size: 15)
        contentView.addSubview(nameLabel)
        
        totalFriendLabel.formatSizeBold(15)
        totalFriendLabel.text = ""
        totalFriendLabel.textColor = UIColor.primary1()
        contentView.addSubview(totalFriendLabel)
        
        
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
    
    @objc func didTouchOnInviteButton() {
        if let contactUser = self.contact {
            delegate?.didTouchOnInviteButton(contactUser)
        }
    }
    
    override func layoutSubviews() {
        super.layoutSubviews()
        
        let inviteButtonSize = ButtonFollow.ButtonFollowSize
        inviteButton.frame = CGRect(x: self.bounds.sizeWidth - Margin.right - inviteButtonSize.width, y: (self.bounds.sizeHeight - inviteButtonSize.height) / 2, width: inviteButtonSize.width, height: inviteButtonSize.height)
        iconInvite.frame = CGRect(x: Margin.left / 2 , y: (inviteButtonSize.height - ButtonFollow.ImageViewSize.height) / 2 , width: ButtonFollow.ImageViewSize.width, height:ButtonFollow.ImageViewSize.height)
        
        lineView.frame = CGRect(x: 0, y: self.bounds.sizeHeight - 1 , width: self.bounds.sizeWidth, height: 1)
        
        let width = CGFloat(50)
        
        let maxWidth = min(StringHelper.getTextWidth(nameLabel.text!, height: nameLabel.frame.sizeHeight, font: nameLabel.font), inviteButton.frame.minX  - Margin.left * 2 - width)
        nameLabel.frame = CGRect(x: Margin.left, y: (self.bounds.sizeHeight - CGFloat(HeightLabel)) / 2, width: maxWidth, height: HeightLabel)
        totalFriendLabel.frame = CGRect(x: nameLabel.frame.maxX + Margin.left / 2, y: (self.bounds.sizeHeight - CGFloat(HeightLabel)) / 2, width: width, height: HeightLabel)
    }
    
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    func setData(_ contact: Contact){
        
        self.contact = contact
        
        switch contact.type {
        case .addall:
            inviteButton.layer.borderColor = UIColor.primary1().cgColor
            inviteButton.setImage(nil, for: UIControlState())
            inviteButton.setTitle(String.localize("LB_CA_ADD_ALL_FRIEND"), for: UIControlState())
            inviteButton.backgroundColor = UIColor.primary1()
            inviteButton.setTitleColor(UIColor.white, for: UIControlState())
            
            iconInvite.isHidden = false
            iconInvite.image = UIImage(named: "curator_follow_icon_small")
            
            self.nameLabel.text = contact.displayName
            self.totalFriendLabel.text = String(contact.totalFriendNumber)
            self.totalFriendLabel.isHidden = false
            self.contentView.backgroundColor = UIColor.secondary5()
            break
        case .addfriend:
            inviteButton.layer.borderColor = UIColor.primary1().cgColor
            inviteButton.setImage(nil, for: UIControlState())
            inviteButton.setTitle(String.localize("LB_CA_ADD_FRIEND"), for: UIControlState())
            inviteButton.backgroundColor = UIColor.white
            inviteButton.setTitleColor(UIColor.primary1(), for: UIControlState())
            
            iconInvite.isHidden = false
            iconInvite.image = UIImage(named: "icon_plus_red")
            self.nameLabel.text = contact.displayName
            self.totalFriendLabel.isHidden = true
            self.contentView.backgroundColor = UIColor.white
            break
        case .chatfriend:
            inviteButton.layer.borderColor = UIColor.clear.cgColor
            inviteButton.setImage(UIImage(named: "chat_on"), for: UIControlState())
            inviteButton.setTitle("", for: UIControlState())
            inviteButton.backgroundColor = UIColor.white
            
            iconInvite.isHidden = true
            self.nameLabel.text = contact.displayName
            self.totalFriendLabel.isHidden = true
            self.contentView.backgroundColor = UIColor.white
            break
        case .invite:
            inviteButton.setTitle(String.localize("LB_CA_REF_INVITE"), for: UIControlState())
            inviteButton.layer.borderColor = UIColor.weiboButtonColor().cgColor
            inviteButton.setImage(nil, for: UIControlState())
            inviteButton.backgroundColor = UIColor.white
            inviteButton.setTitleColor(UIColor.weiboButtonColor(), for: UIControlState())
            
            iconInvite.isHidden = false
            iconInvite.image = UIImage(named: "icon_plus_blue")
            self.nameLabel.text = contact.displayName
            self.totalFriendLabel.isHidden = true
            self.contentView.backgroundColor = UIColor.white
            break
        }
        self.layoutSubviews()
        
        
    }
}
