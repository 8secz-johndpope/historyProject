//
//  SearchFriendViewCell.swift
//  merchant-ios
//
//  Created by HVN_Pivotal on 3/8/16.
//  Copyright © 2016 WWE & CO. All rights reserved.
//

import Foundation


protocol SearchFriendViewCellDelegate: class {
    func addFriendClicked(_ rowIndex: Int)
    func followClicked(_ rowIndex: Int)
}
class SearchFriendViewCell : SwipeActionMenuCell{
    var imageView = UIImageView()
    var upperLabel = UILabel()
    var borderView = UIView()
    var diamondImageView = UIImageView()
    var buttonView = UIView()
    var addFriendButton = UIButton()
    var addFollowButton = UIButton()
    var iconAddFriend = UIImageView()
    var iconAddFollow = UIImageView()
    weak var searchFriendViewCellDelegate: SearchFriendViewCellDelegate?
    private final let MarginRight : CGFloat = 20
    private final let MarginLeft : CGFloat = 15
    private final let LabelMarginTop : CGFloat = 15
    private final let LabelMarginRight : CGFloat = 30
    private final let ImageWidth : CGFloat = 44
    private final let ImageDiamondWidth : CGFloat = 16
    private final let LabelRightWidth : CGFloat = 100
    private final let LabelLowerMarginTop : CGFloat = 33
    private final let ButtonHeight : CGFloat = 30
    private final let ButtonWidth : CGFloat = 95
    private final let IconAddWidth : CGFloat = 21
    private final let Padding : CGFloat = 5
    var isSearchFriend : Bool = false
    override init(frame: CGRect) {
        super.init(frame: frame)
        self.clipsToBounds = true
        backgroundColor = UIColor.white
        imageView.layer.borderWidth = 1.0
        imageView.clipsToBounds = true
        imageView.contentMode = .scaleAspectFit
        imageView.layer.borderColor = UIColor.primary1().cgColor
        addSubview(imageView)
        upperLabel.formatSize(15)
        addSubview(upperLabel)
        
        diamondImageView.image = UIImage(named: "curator_diamond")
        addSubview(diamondImageView)
        addSubview(diamondImageView)
        
        iconAddFriend.image = UIImage(named: "icon_add_red")
        addFriendButton.addTarget(self, action: #selector(SearchFriendViewCell.addFriendClicked), for: UIControlEvents.touchUpInside)
        addFriendButton.setTitle(String.localize("LB_CA_ADD_FRIEND"), for: UIControlState())
        addFriendButton.setTitleColor(UIColor.secondary2(), for: UIControlState())
        addFriendButton.contentEdgeInsets = UIEdgeInsets(top: 0, left: IconAddWidth + Padding, bottom: 0, right: 0);
        addFriendButton.titleLabel!.font = UIFont.systemFont(ofSize: 12)
        addFriendButton.titleLabel!.minimumScaleFactor = 0.5
        addFriendButton.titleLabel!.adjustsFontSizeToFitWidth = true
        addFriendButton.contentHorizontalAlignment = UIControlContentHorizontalAlignment.left
        addFriendButton.addSubview(iconAddFriend)
        
        
        iconAddFollow.image = UIImage(named: "icon_add_red")
        addFollowButton.addTarget(self, action: #selector(SearchFriendViewCell.followClicked), for: UIControlEvents.touchUpInside)
        addFollowButton.setTitle(String.localize("LB_CA_FOLLOW"), for: UIControlState())
        addFollowButton.setTitleColor(UIColor.secondary2(), for: UIControlState())
        addFollowButton.contentEdgeInsets = UIEdgeInsets(top: 0, left: IconAddWidth + Padding, bottom: 0, right: 0);
        addFollowButton.titleLabel!.font = UIFont.systemFont(ofSize: 12)
        addFollowButton.titleLabel!.adjustsFontSizeToFitWidth = true
        addFollowButton.titleLabel!.minimumScaleFactor = 0.5
        addFollowButton.contentHorizontalAlignment = UIControlContentHorizontalAlignment.left
        addFollowButton.addSubview(iconAddFollow)
        
        buttonView.addSubview(addFriendButton)
        buttonView.addSubview(addFollowButton)
        buttonView.backgroundColor = UIColor.white
        addSubview(buttonView)
        borderView.backgroundColor = UIColor.secondary1()
        addSubview(borderView)
        layoutSubviews()
    }
    
    override func layoutSubviews() {
        super.layoutSubviews()
        imageView.frame = CGRect(x: bounds.minX + MarginLeft, y: bounds.midY - ImageWidth / 2, width: ImageWidth, height: ImageWidth)
        var ratio : CGFloat = 2 / 5
        if isSearchFriend {
            ratio = 1.0
        }
        upperLabel.frame = CGRect(x: imageView.frame.maxX + MarginRight, y: bounds.minY, width: bounds.width * ratio - (imageView.frame.maxX + MarginRight), height: bounds.height)
        
        buttonView.frame = CGRect(x: upperLabel.frame.maxX , y: bounds.minY , width: (bounds.width - MarginLeft * 2) * 3 / 5, height:bounds.height )
        iconAddFriend.frame = CGRect(x: 0 , y: (ButtonHeight - IconAddWidth) / 2 , width: IconAddWidth, height:IconAddWidth)
        iconAddFollow.frame = CGRect(x: 0 , y: (ButtonHeight - IconAddWidth) / 2 , width: IconAddWidth, height:IconAddWidth)
        
        var followWidth = StringHelper.getTextWidth(addFollowButton.titleLabel!.text!, height: ButtonHeight, font: addFollowButton.titleLabel!.font) + (self.iconAddFollow.isHidden ? 0 : IconAddWidth + Padding)
        if followWidth > ButtonWidth {
            followWidth = ButtonWidth
        }
        addFollowButton.frame = CGRect(x: buttonView.frame.width - followWidth , y: (buttonView.frame.height - ButtonHeight) / 2 , width: followWidth, height:ButtonHeight)
        
        var friendWidth = StringHelper.getTextWidth(addFriendButton.titleLabel!.text!, height: ButtonHeight, font: addFriendButton.titleLabel!.font) + (self.iconAddFriend.isHidden ? 0 : IconAddWidth + Padding)
        if friendWidth > (ButtonWidth * 2) - followWidth {
            friendWidth = (ButtonWidth * 2) - followWidth
        }
        addFriendButton.frame = CGRect(x: addFollowButton.frame.minX - (friendWidth + 5) , y: (buttonView.frame.height - ButtonHeight) / 2 , width: friendWidth, height:ButtonHeight)
        borderView.frame = CGRect(x: bounds.minX, y: bounds.maxY - 1, width: bounds.width, height: 1)
        diamondImageView.frame = CGRect(x: imageView.frame.maxX - (ImageDiamondWidth - 2), y: imageView.frame.maxY - ImageDiamondWidth, width: ImageDiamondWidth, height: ImageDiamondWidth)
    }
    
    func setButtonFrame(_ user:User){
        var followWidth = StringHelper.getTextWidth(user.followStatus, height: ButtonHeight, font: addFollowButton.titleLabel!.font) + (self.iconAddFollow.isHidden ? 0 : IconAddWidth + Padding)
        if followWidth > ButtonWidth {
            followWidth = ButtonWidth
        }
        addFollowButton.frame = CGRect(x: buttonView.frame.width - followWidth , y: (buttonView.frame.height - ButtonHeight) / 2 , width: followWidth, height:ButtonHeight)
        var friendWidth = StringHelper.getTextWidth(user.friendStatus, height: ButtonHeight, font: addFriendButton.titleLabel!.font) + (self.iconAddFriend.isHidden ? 0 : IconAddWidth + Padding)
        if friendWidth > (ButtonWidth * 2) - followWidth {
            friendWidth = (ButtonWidth * 2) - followWidth
        }
        addFriendButton.frame = CGRect(x: addFollowButton.frame.minX - (friendWidth + 5) , y: (buttonView.frame.height - ButtonHeight) / 2 , width: friendWidth, height:ButtonHeight)
    }
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    func setImage(_ key : String, imageCategory : ImageCategory ){
		imageView.mm_setImageWithURL(ImageURLFactory.URLSize128(key, category: imageCategory), placeholderImage : UIImage(named: "default_profile_icon"))
		imageView.contentMode = .scaleAspectFill
    }
    
    @objc func addFriendClicked(_ sender: UIButton) {
        if self.searchFriendViewCellDelegate != nil {
            self.searchFriendViewCellDelegate?.addFriendClicked(sender.tag)
        }
    }
    
    @objc func followClicked(_ sender: UIButton) {
        if self.searchFriendViewCellDelegate != nil {
            self.searchFriendViewCellDelegate?.followClicked(sender.tag)
        }
    }
    
    func setData(_ user:User){
        self.diamondImageView.isHidden = true
        self.imageView.layer.borderWidth = 0.0
        if user.isCurator == 1 {
            self.diamondImageView.isHidden = false
            self.imageView.layer.cornerRadius = self.imageView.frame.height / 2
            self.imageView.layer.borderWidth = 1.0
        } else {
            self.diamondImageView.isHidden = true
            self.imageView.layer.borderWidth = 0.0
            if user.merchantId != 0 {
                self.imageView.layer.cornerRadius = 0
            } else {
                self.imageView.layer.cornerRadius = self.imageView.frame.height / 2
            }
        }
        self.upperLabel.text = user.displayName
        self.setImage(user.profileImage, imageCategory: .user)
        if user.friendStatus.length == 0 {
            user.friendStatus = String.localize("LB_CA_ADD_FRIEND")
        }
        if user.followStatus.length == 0 {
            user.followStatus = String.localize("LB_CA_FOLLOW")
        }
        if  user.friendStatus == String.localize("LB_CA_ADD_FRIEND"){
            self.addFriendButton.setTitle(String.localize("LB_CA_ADD_FRIEND"), for: UIControlState())
            self.iconAddFriend.isHidden = false
            iconAddFriend.image = UIImage(named: "icon_add_red")
            addFriendButton.contentEdgeInsets = UIEdgeInsets(top: 0, left: IconAddWidth + Padding, bottom: 0, right: 0);
        } else if user.friendStatus == String.localize("LB_CA_FRD_REQ_CANCEL") {
            self.addFriendButton.setTitle(String.localize("LB_CA_FRD_REQ_CANCEL"), for: UIControlState())
            self.iconAddFriend.isHidden = false
            iconAddFriend.image = UIImage(named: "icon_cancel_friend")
            addFriendButton.contentEdgeInsets = UIEdgeInsets(top: 0, left: IconAddWidth + Padding, bottom: 0, right: 0);
        } else {
            self.addFriendButton.setTitle(String.localize("LB_CA_BEFRIENDED"), for: UIControlState())
            self.iconAddFriend.isHidden = true;
            addFriendButton.contentEdgeInsets = UIEdgeInsets.zero
        }
        
        if user.followStatus.length == 0 || user.followStatus == String.localize("LB_CA_FOLLOW"){
            addFollowButton.setTitle(String.localize("LB_CA_FOLLOW"), for: UIControlState())
            self.iconAddFollow.isHidden = false
            iconAddFollow.image = UIImage(named: "icon_add_red")
            addFollowButton.contentEdgeInsets = UIEdgeInsets(top: 0, left: IconAddWidth + Padding, bottom: 0, right: 0);
        } else {
            addFollowButton.setTitle(String.localize("LB_CA_FOLLOWED"), for: UIControlState())
            self.iconAddFollow.isHidden = false;
            iconAddFollow.image = UIImage(named: "tick_icon")
            addFollowButton.contentEdgeInsets = UIEdgeInsets(top: 0, left: IconAddWidth + Padding, bottom: 0, right: 0);
        }
        self.setButtonFrame(user)
    }

}

