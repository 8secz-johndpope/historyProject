//
//  IMLandingViewCell.swift
//  merchant-ios
//
//  Created by Alan YU on 19/5/16.
//  Copyright © 2016 WWE & CO. All rights reserved.
//

import Foundation

enum ConversationStatus: Int {
    case unknown,
    followed,
    closed
}

class IMConversationViewCell : SwipeActionMenuCell {
    
    @IBOutlet weak var profileIcon: GroupChatImageView!
    @IBOutlet weak var nameLabel: UILabel!
    @IBOutlet weak var lastMessageLabel: UILabel!
    @IBOutlet weak var diamondImageView: UIImageView!
    @IBOutlet weak var timeLabel: UILabel!
    @IBOutlet weak var badgeLabel: UILabel!
    @IBOutlet weak var separator: UIView!
    @IBOutlet weak var otherMerchantNameLabel: UILabel!
    @IBOutlet weak var statusLabel: UILabel!
    @IBOutlet weak var dataContainer: UIView!
    
    @IBOutlet weak var groupChatName: GroupChatNameContainer!
    @IBOutlet weak var merchantIcon: UIImageView!
    
    var groupChatNameList: [GroupChatName]? {
        didSet {
            if let list = self.groupChatNameList {
                
                let maxWidth = self.timeLabel.frame.minX - 2
                groupChatName.setCombineNames(list, maxWidth: maxWidth)
            }
        }
    }
    
    var conversationStatus : ConversationStatus? {
        didSet {
            if let convStatus = self.conversationStatus {
                
                var PaddingLeft = CGFloat(0)
                var PaddingTop = CGFloat(0)
                
                switch convStatus {
                case .followed:
                    statusLabel.isHidden = false
                    statusLabel.text = String.localize("LB_CS_CHAT_FLAGGED")
                    statusLabel.textColor = UIColor.white
                    statusLabel.backgroundColor = UIColor.primary1()
                    statusLabel.layer.cornerRadius = 3
                    PaddingLeft = 5
                    PaddingTop = 2
                    
                case .closed:
                    statusLabel.isHidden = false
                    statusLabel.text = String.localize("LB_CLOSED")
                    statusLabel.textColor = UIColor.black
                    statusLabel.backgroundColor = UIColor.clear
                    statusLabel.layer.cornerRadius = 0

                default:
                    statusLabel.isHidden = true
                    
                }
                
                statusLabel.sizeToFit()

                if merchantIcon.isHidden {
                    statusLabel.frame = CGRect(x: dataContainer.frame.width - statusLabel.frame.width - (2 * PaddingLeft), y: 20, width: statusLabel.frame.width + (2 * PaddingLeft), height: statusLabel.frame.height + (2 * PaddingTop))
                }
                else {
                    statusLabel.frame = CGRect(x: merchantIcon.frame.minX - statusLabel.frame.width - 5 - (2 * PaddingLeft), y: 20, width: statusLabel.frame.width + (2 * PaddingLeft), height: statusLabel.frame.height + (2 * PaddingTop))
                }
            }
        }
    }
    
    override func awakeFromNib() {
        super.awakeFromNib()

        profileIcon.contentMode = .scaleAspectFit
        profileIcon.layer.borderColor = UIColor.primary1().cgColor
        profileIcon.clipsToBounds = true
        
        separator.backgroundColor = UIColor.secondary1()
        
        lastMessageLabel.textColor = UIColor.secondary2()
        
        timeLabel.textColor = UIColor.secondary2()
        
        badgeLabel.round()
        badgeLabel.backgroundColor = UIColor.primary1()
        badgeLabel.textColor = UIColor.white
        badgeLabel.isHidden = true
        
        let circleLayer = CAShapeLayer()
        circleLayer.path = UIBezierPath(ovalIn: CGRect(x: 0, y: 0, width: badgeLabel.width, height: badgeLabel.width)).cgPath
        circleLayer.fillColor = UIColor.clear.cgColor
        circleLayer.strokeColor = UIColor.white.cgColor
        circleLayer.lineWidth = 1
        badgeLabel.layer.addSublayer(circleLayer)
        
        otherMerchantNameLabel.textColor = UIColor.secondary2()
        otherMerchantNameLabel.layer.cornerRadius = 5
        otherMerchantNameLabel.layer.borderColor = UIColor.secondary1().cgColor
        otherMerchantNameLabel.layer.borderWidth = 1
        
        merchantIcon.layer.cornerRadius = 3
        merchantIcon.clipsToBounds = true
    }
    
    override func layoutSubviews() {
        super.layoutSubviews()
        
        timeLabel.sizeToFit()
        otherMerchantNameLabel.sizeToFit()
        nameLabel.sizeToFit()
        
        let padding = CGFloat(2)
        let labelHeight = CGFloat(20)
        let width = dataContainer.frame.width
        
        let layoutTimeLabel = {
            
            var timeLabelFrame = self.timeLabel.frame
            timeLabelFrame.originX = width - self.timeLabel.frame.width
            timeLabelFrame.sizeHeight = labelHeight
            self.timeLabel.frame = timeLabelFrame
            
        }
        layoutTimeLabel()
        
        let layoutNameAndOtherMerchantName = {
            
            var merchantNameLabelExtraSpace = CGFloat(0)
            if self.otherMerchantNameLabel.text != nil {
                merchantNameLabelExtraSpace = CGFloat(7)
            }
            
            let occupied = self.otherMerchantNameLabel.frame.width + merchantNameLabelExtraSpace + self.timeLabel.frame.width + padding * 2
            let maxWidth = width - occupied
            
            var nameFrame = self.nameLabel.frame
            if nameFrame.sizeWidth > maxWidth {
                nameFrame.sizeWidth = maxWidth
            }
            nameFrame.sizeHeight = labelHeight
            self.nameLabel.frame = nameFrame
            
            var otherMerchantNameLabelFrame = self.otherMerchantNameLabel.frame
            otherMerchantNameLabelFrame.originX = self.nameLabel.frame.maxX + padding
            otherMerchantNameLabelFrame.sizeHeight = labelHeight
            otherMerchantNameLabelFrame.sizeWidth += merchantNameLabelExtraSpace
            self.otherMerchantNameLabel.frame = otherMerchantNameLabelFrame
            
        }
        layoutNameAndOtherMerchantName()
        
        let layoutLastMessageAndMyMerchantName = {
            
            var frame = self.lastMessageLabel.frame
            frame.originX = 0
            
            let lastMessWidth: CGFloat!

            if !self.statusLabel.isHidden {
                lastMessWidth = self.statusLabel.frame.minX - frame.originX
            }
            else {
                if self.merchantIcon.isHidden {
                    lastMessWidth = width - frame.originX
                }
                else {
                    lastMessWidth = self.merchantIcon.frame.minX - frame.originX
                }
            }
            
            frame.sizeWidth = lastMessWidth
            frame.sizeHeight = labelHeight
            
            self.lastMessageLabel.frame = frame
        }
        layoutLastMessageAndMyMerchantName()
        
    }
    
    func setImage(_ imageKey: String?, category: ImageCategory = .user) {
        let defaultImage = UIImage(named: "default_profile_icon")
        if let key = imageKey, key.length > 0 {
            profileIcon.mm_setImageWithURL(
                ImageURLFactory.URLSize(.size128, key: key, category: category),
                placeholderImage: defaultImage,
                contentMode: .scaleAspectFill
            )
        } else {
            profileIcon.image = defaultImage
        }
    }
    
    func showCurator(_ show: Bool) {
        diamondImageView.isHidden = !show
        if show {
            profileIcon.layer.borderWidth = 1.0
        } else {
            profileIcon.layer.borderWidth = 0.0
        }
    }
    
    func setUnreadCount(_ count: Int) {
        if count > 0 {
            badgeLabel.isHidden = false
            badgeLabel.text = String(count)
        } else {
            badgeLabel.isHidden = true
        }
    }
    
    func setOtherMerchant(_ merchant: Merchant?) {
        if let text = merchant?.merchantName {
            otherMerchantNameLabel.text = text
        } else {
            otherMerchantNameLabel.text = nil
        }
    }
    
    func profileImageRounded(_ rounded: Bool) {
        if rounded {
            profileIcon.layer.cornerRadius = profileIcon.frame.height / 2
//            profileIcon.layer.borderWidth = 1
        } else {
            profileIcon.layer.cornerRadius = 0
            profileIcon.layer.borderWidth = 0
        }
    }
    
}

