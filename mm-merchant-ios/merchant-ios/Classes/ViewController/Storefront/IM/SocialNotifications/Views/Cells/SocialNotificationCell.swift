//
//  SocialNotificationCell.swift
//  merchant-ios
//
//  Created by HungPM on 9/5/17.
//  Copyright © 2017 WWE & CO. All rights reserved.
//

import UIKit

class SocialNotificationCell: UICollectionViewCell {
    
    @IBOutlet weak var profileImageView: UIImageView!
    @IBOutlet weak var lblName: UILabel!
    @IBOutlet weak var lblTime: UILabel!
    @IBOutlet weak var lblMessage: UILabel!
    @IBOutlet weak var rightImageView: UIImageView!
    @IBOutlet weak var button: UIButton!
    @IBOutlet weak var iconImageView: UIImageView!
    @IBOutlet weak var viewSeparator: UIView!
    
    var profileImageTapHandler: ((User) -> ())?
    var buttonTapHandler: ((String, Bool, String) -> ())?
    
    var socialMessage: SocialMessage? {
        didSet {
            if let socialMessage = socialMessage {
                if let fromProfileImage = socialMessage.fromProfileImage {
                    profileImageView.mm_setImageWithURL(ImageURLFactory.URLSize128(fromProfileImage, category: .user), placeholderImage: UIImage(named: "Placeholder_avatar"))
                }
                else {
                    profileImageView.image = UIImage(named: "Placeholder_avatar")
                }

                let formatter = Constants.DateFormatter.getFormatter(DateTransformExtension.DateFormatStyle.dateOnly)
                if formatter.string(from: Date()) == formatter.string(from: socialMessage.lastCreated) {
                    lblTime.text = Constants.DateFormatter.getFormatter("HH:mm").string(from: socialMessage.lastCreated)
                } else {
                    lblTime.text = Constants.DateFormatter.getFormatter("yyyy-MM-dd").string(from: socialMessage.lastCreated)
                }
                
                switch socialMessage.socialMessageTypeId {
                case .postLiked:
                    button.isHidden = true
                    lblMessage.isHidden = true
                    iconImageView.isHidden = true
                    
                    if let entityImage = socialMessage.entityImage {
                        rightImageView.mm_setImageWithURL(ImageURLFactory.URLSize256(entityImage, category: .post), placeholderImage: UIImage(named: "empty_status"))
                    }
                    
                    if let fromDisplayName = socialMessage.fromDisplayName {
                        let attString = NSMutableAttributedString(string: fromDisplayName, attributes: [NSAttributedStringKey.font : UIFont.boldFontWithSize(14), NSAttributedStringKey.foregroundColor : UIColor.secondary2()])
                        
                        
                        let str = String.localize("LB_CA_NOTIFICATION_JUST_LIKED").replacingOccurrences(of: "{0} ", with: "")
                        
                        attString.append(NSAttributedString(string: " " + str, attributes: [NSAttributedStringKey.font : UIFont.systemFont(ofSize: 14), NSAttributedStringKey.foregroundColor : UIColor.secondary14()]))
                        lblName.attributedText = attString
                    }
                    
                case .postComment:
                    button.isHidden = true
                    iconImageView.isHidden = true
                    
                    if let entityImage = socialMessage.entityImage {
                        rightImageView.mm_setImageWithURL(ImageURLFactory.URLSize256(entityImage, category: .post), placeholderImage: UIImage(named: "empty_status"))
                    }
                    
                    if let fromDisplayName = socialMessage.fromDisplayName {
                        let attString = NSMutableAttributedString(string: fromDisplayName, attributes: [NSAttributedStringKey.font : UIFont.boldFontWithSize(14), NSAttributedStringKey.foregroundColor : UIColor.secondary2()])
                        
                        let str = String.localize("LB_CA_NOTIFICATION_JUST_COMMENTED").replacingOccurrences(of: "{0} ", with: "")
                        
                        attString.append(NSAttributedString(string: " " + str, attributes: [NSAttributedStringKey.font : UIFont.systemFont(ofSize: 14), NSAttributedStringKey.foregroundColor : UIColor.secondary14()]))
                        lblName.attributedText = attString
                        lblMessage.text = socialMessage.entityText
                    }
                    
                case .follow:
                    rightImageView.isHidden = true
                    lblMessage.isHidden = true
                    
                    if let fromDisplayName = socialMessage.fromDisplayName {
                        let attString = NSMutableAttributedString(string: fromDisplayName, attributes: [NSAttributedStringKey.font : UIFont.boldFontWithSize(14), NSAttributedStringKey.foregroundColor : UIColor.secondary2()])
                        
                        let str = String.localize("LB_CA_NOTIFICATION_JUST_FOLLOWED").replacingOccurrences(of: "{0} ", with: "")
                        
                        attString.append(NSAttributedString(string: " " + str, attributes: [NSAttributedStringKey.font : UIFont.systemFont(ofSize: 14), NSAttributedStringKey.foregroundColor : UIColor.secondary14()]))
                        lblName.attributedText = attString
                    }
                    
                    if let userKey = socialMessage.fromUserKey {
                        setFollowButtonState(FollowService.isFollowing(userKey))
                    }
                }
            }
        }
    }
    
    override func awakeFromNib() {
        super.awakeFromNib()
        
        profileImageView.round()
        
        lblTime.font = UIFont.systemFont(ofSize: 12)
        lblTime.textColor = UIColor.secondary14()
        
        lblMessage.font = UIFont.boldFontWithSize(14)
        lblMessage.textColor = UIColor.secondary2()
        
        viewSeparator.backgroundColor = UIColor(hexString: "#f5f5f5")
        
        profileImageView.addGestureRecognizer(UITapGestureRecognizer(target: self, action: #selector(profileImageTapped)))
        profileImageView.isUserInteractionEnabled = true
    }
    
    func setFollowButtonState(_ isFollowed: Bool) {
        if isFollowed {
            button.titleEdgeInsets = UIEdgeInsets.zero
            button.layer.borderColor = UIColor.secondary2().alpha(0.5).cgColor
            button.setTitle(String.localize("LB_CA_FOLLOWED"), for: UIControlState())
            button.setTitleColor(UIColor.secondary2().alpha(0.5), for: UIControlState())
            iconImageView.isHidden = true
        }
        else {
            button.titleEdgeInsets = UIEdgeInsets(top: 0, left: 10, bottom: 0, right: 0);
            button.layer.borderColor = UIColor.black.cgColor
            button.setTitle(String.localize("LB_CA_FOLLOW"), for: UIControlState())
            button.setTitleColor(UIColor.black, for: UIControlState())
            iconImageView.isHidden = false
        }
        button.layer.borderWidth = 1
        button.layer.cornerRadius = 2
        button.titleLabel?.font = UIFont(name: Constants.Font.Normal, size: 12)
    }
    
    @objc func profileImageTapped() {
        if let socialMessage = socialMessage, let userKey = socialMessage.fromUserKey {
            let user = User()
            user.userKey = userKey
            profileImageTapHandler?(user)
        }
    }
    
    @IBAction func buttonTapped(_ sender: Any) {
        if let userKey = socialMessage?.fromUserKey, let displayName = socialMessage?.fromDisplayName {
            buttonTapHandler?(userKey, FollowService.isFollowing(userKey), displayName)
        }
    }
}
