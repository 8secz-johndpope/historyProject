//
//  IMViewCell.swift
//  merchant-ios
//
//  Created by HVN_Pivotal on 3/3/16.
//  Copyright © 2016 WWE & CO. All rights reserved.
//

import Foundation

protocol FriendListViewCellDelegate: NSObjectProtocol{
    func chatClicked(_ rowIndex: Int, sender: UIButton)
    func acceptClicked(_ rowIndex: Int, sender: UIButton)
    func deleteClicked(_ rowIndex: Int, sender: UIButton)
}
class FriendListViewCell : UICollectionViewCell{
    var imageView = UIImageView()
    var upperLabel = UILabel()
    var borderView = UIView()
    var diamondImageView = UIImageView()
    var rightLabel = UILabel()
    var chatView = UIView()
    var buttonView = UIView()
    var chatButton = UIButton()
    var acceptButton = UIButton()
    var deleteButton = UIButton()
    private final let MarginRight : CGFloat = 20
    private final let MarginLeft : CGFloat = 15
    private final let LabelMarginTop : CGFloat = 15
    private final let LabelMarginRight : CGFloat = 30
    private final let ImageWidth : CGFloat = 40
    private final let ImageDiamondWidth : CGFloat = 16
    private final let LabelRightWidth : CGFloat = 50
    private final let LabelLowerMarginTop : CGFloat = 33
    private final let ButtonHeight : CGFloat = 44
    private final let ButtonWidth : CGFloat = 44
    private final let ChatButtonWidth : CGFloat = 30
    weak var friendListViewCellDelegate: FriendListViewCellDelegate?
    override init(frame: CGRect) {
        super.init(frame: frame)
        backgroundColor = UIColor.white
        imageView.layer.borderWidth = 1.0
        imageView.layer.borderColor = UIColor.primary1().cgColor
        imageView.clipsToBounds = true
        imageView.layer.cornerRadius = ImageWidth / 2
        addSubview(imageView)
        
        upperLabel.font = UIFont.usernameFont()
        upperLabel.textColor = .black
        upperLabel.lineBreakMode = .byTruncatingTail
        upperLabel.numberOfLines = 1
        addSubview(upperLabel)
        diamondImageView.image = UIImage(named: "curator_diamond")
        addSubview(diamondImageView)
        addSubview(diamondImageView)
        rightLabel.formatSize(12)
        rightLabel.textAlignment = .right
        addSubview(rightLabel)
        chatButton.setImage(UIImage(named: "chat_on"), for: UIControlState())
        chatButton.addTarget(self, action: #selector(FriendListViewCell.chatClicked), for: UIControlEvents.touchUpInside)
        chatButton.isExclusiveTouch = true
        chatView.addSubview(chatButton)
        chatView.backgroundColor = UIColor.white
        addSubview(chatView)
        acceptButton.addTarget(self, action: #selector(FriendListViewCell.acceptClicked), for: UIControlEvents.touchUpInside)
        acceptButton.isExclusiveTouch = true
        acceptButton.setImage(UIImage(named: "accept_btn"), for: UIControlState())
        deleteButton.addTarget(self, action: #selector(FriendListViewCell.deleteClicked), for: UIControlEvents.touchUpInside)
        deleteButton.setImage(UIImage(named: "reject_btn"), for: UIControlState())
        deleteButton.isExclusiveTouch = true
        buttonView.addSubview(acceptButton)
        buttonView.addSubview(deleteButton)
        buttonView.backgroundColor = UIColor.white
        addSubview(buttonView)
        borderView.backgroundColor = UIColor.secondary1()
        addSubview(borderView)
        layoutSubviews()
        
        upperLabel.accessibilityIdentifier = "IM_FriendList-UILB_FRIEND"
        acceptButton.accessibilityIdentifier = "IM_FriendList-UIBT_ACCEPT"
        deleteButton.accessibilityIdentifier = "IM_FriendList-UIBT_REJECT"
        chatView.accessibilityIdentifier = "IM_FriendList-UIBT_CHAT"
    }
    
    private let mainLabelHeight :CGFloat = 30.0
    
    override func layoutSubviews() {
        super.layoutSubviews()
        imageView.frame = CGRect(x: bounds.minX + MarginLeft, y: bounds.midY - ImageWidth / 2, width: ImageWidth, height: ImageWidth)
        
        chatView.frame = CGRect(x: frame.width - LabelRightWidth, y: bounds.minY , width: LabelRightWidth, height:bounds.height)
        chatButton.frame = CGRect(x: 0 , y: 0, width: chatView.frame.size.width, height:chatView.frame.size.height)
		chatButton.imageEdgeInsets = UIEdgeInsets(top: 0, left: chatButton.frame.size.width - (chatButton.imageView?.frame.size.width)! - 10, bottom: 0, right: 10)
        
        buttonView.frame = CGRect(x: bounds.maxX - 2*ButtonWidth - 20, y: bounds.minY , width: 2*ButtonWidth + 20, height:bounds.height)
        rightLabel.frame = CGRect(x: frame.width - LabelRightWidth - 20 , y: bounds.minY , width: LabelRightWidth, height:bounds.height)

        let Margin = CGFloat(12)
        var width: CGFloat
        if buttonView.isHidden && chatView.isHidden && rightLabel.isHidden {
            width = bounds.width - (imageView.frame.maxX + Margin + MarginRight)
        }
        else if !buttonView.isHidden && chatView.isHidden && rightLabel.isHidden {
            width = buttonView.frame.minX - (imageView.frame.maxX + Margin + MarginRight)
        }
        else {
            width = rightLabel.frame.minX - (imageView.frame.maxX + Margin)
        }
        
        upperLabel.frame = CGRect(x: imageView.frame.maxX + Margin, y: bounds.minY, width: width, height: bounds.height)

        deleteButton.frame = CGRect(x: buttonView.frame.width - ButtonWidth - 10 , y: (buttonView.frame.height - ButtonHeight) / 2 , width: ButtonWidth, height:ButtonHeight)
        
        acceptButton.frame = CGRect(x: buttonView.frame.width - (ButtonWidth * 2 + 10), y: (buttonView.frame.height - ButtonHeight) / 2 , width: ButtonWidth, height:ButtonHeight)
        
        
        borderView.frame = CGRect(x: bounds.minX, y: bounds.maxY - 0.5, width: bounds.width, height: 0.5)
        diamondImageView.frame = CGRect(x: imageView.frame.maxX - (ImageDiamondWidth - 2), y: imageView.frame.maxY - ImageDiamondWidth, width: ImageDiamondWidth, height: ImageDiamondWidth)
        
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    @objc func chatClicked(_ sender: UIButton) {
        if self.friendListViewCellDelegate != nil {
            self.friendListViewCellDelegate?.chatClicked(sender.tag, sender: sender)
        }
    }
    
    @objc func acceptClicked(_ sender: UIButton) {
        if self.friendListViewCellDelegate != nil {
            self.friendListViewCellDelegate?.acceptClicked(sender.tag, sender: sender)
        }
    }
    
    @objc func deleteClicked(_ sender: UIButton) {
        if self.friendListViewCellDelegate != nil {
            self.friendListViewCellDelegate?.deleteClicked(sender.tag, sender: sender)
        }
    }
    
    func setImage(_ imageKey : String, category : ImageCategory){
        let defaultImage = UIImage(named: "default_profile_icon")
        if (imageKey.length > 0) {
            imageView.mm_setImageWithURL(ImageURLFactory.URLSize128(imageKey, category: category), placeholderImage : defaultImage)
        } else {
            imageView.image = defaultImage
        }
		imageView.contentMode = .scaleAspectFill
    }
    
    func setData (_ user: User, isFriend: Bool) {
        if isFriend {
            chatView.isHidden = false
            buttonView.isHidden = true
            rightLabel.isHidden = true
        } else {
            chatView.isHidden = true
            if user.friendStatus.length > 0 {
                buttonView.isHidden = true
                rightLabel.text = user.friendStatus
                rightLabel.isHidden = false
            } else {
                buttonView.isHidden = false
                rightLabel.isHidden = true
            }
        }
        if user.isCurator == 1 {
            diamondImageView.isHidden = false
            imageView.layer.borderWidth = 1.0
        } else {
            diamondImageView.isHidden = true
            imageView.layer.borderWidth = 0.0
        }
        layoutSubviews()
    }
}

