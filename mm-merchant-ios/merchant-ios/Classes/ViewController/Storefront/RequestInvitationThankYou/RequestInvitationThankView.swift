//
//  RequestInvitationThankView.swift
//  merchant-ios
//
//  Created by LongTa on 7/15/16.
//  Copyright © 2016 WWE & CO. All rights reserved.
//

import UIKit

class RequestInvitationThankView: UIView {

    let scrollViewContent = UIScrollView()
    
    let smsImageView  = UIImageView()
    static let SMSImageViewTopPadding:CGFloat = 127
    static let SMSImageViewSize:CGSize = CGSize(width: 152, height: 162)
    
    let announceLabel = UILabel()
    static let AnnounceLabelTopPadding:CGFloat = 50
    static let AnnounceLabelHeight:CGFloat = 40

    let phoneNumberLabel = UILabel()
    static let PhoneNumberLabelTopPadding:CGFloat = 6
    static let PhoneNumberLabelHeight:CGFloat = 17

    let seperatorView = UIView()
    static let SeperatorViewTopPadding:CGFloat = 11
    static let SeperatorViewHeight:CGFloat = 1
    
    let wechatInvitationLabel = UILabel()
    static let WechatInvitationLabelTopPadding:CGFloat = 52
    static let WechatInvitationLabelSize:CGSize = CGSize(width: 293, height: 40)
    
    let wechatFollowButton = UIButton(type: UIButtonType.custom)
    static let WechatFollowButtonTopPadding:CGFloat = 16
    static let WechatFollowButtonLeftRightPadding:CGFloat = 15
    static let WechatFollowButtonHeight:CGFloat = 42

    init() {
        super.init(frame: UIScreen.main.bounds)
        
        addSubview(scrollViewContent)
        
        smsImageView.round()
        smsImageView.image = UIImage(named: "thank_you_invitation")
        scrollViewContent.addSubview(smsImageView)
        
        announceLabel.formatSmall()
        announceLabel.text = String.localize("LB_CA_INVITATION_CODE_THANKS")
        announceLabel.textAlignment = .center
        scrollViewContent.addSubview(announceLabel)
        
        phoneNumberLabel.formatSizeBold(14)
        phoneNumberLabel.textAlignment = .center
        scrollViewContent.addSubview(phoneNumberLabel)
        
        seperatorView.backgroundColor = UIColor.secondary1()
        scrollViewContent.addSubview(seperatorView)
        
        wechatInvitationLabel.formatSmall()
        wechatInvitationLabel.text = String.localize("LB_CA_INVITATION_CODE_WECHAT")
        wechatInvitationLabel.textAlignment = .center
        scrollViewContent.addSubview(wechatInvitationLabel)
        
        wechatFollowButton.setTitle(String.localize("LB_CA_WECHAT_ID_COPY"), for: UIControlState())
        wechatFollowButton.backgroundColor = UIColor.red
        wechatFollowButton.setImage(UIImage(named: "weChat_white"), for: UIControlState())
        wechatFollowButton.formatPrimary()
        wechatFollowButton.backgroundColor = UIColor.init(red: 60/255, green: 176/255, blue: 49/255, alpha: 1.0)
        wechatFollowButton.setTitleColor(UIColor.white, for: UIControlState())
        scrollViewContent.addSubview(wechatFollowButton)
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override func layoutSubviews() {
        super.layoutSubviews()
        self.setupLayouts()
    }
    
    func setupLayouts() {
        
        scrollViewContent.frame = self.frame
        
        smsImageView.frame = CGRect(x: (bounds.sizeWidth - RequestInvitationThankView.SMSImageViewSize.width)/2 , y: RequestInvitationThankView.SMSImageViewTopPadding, width: RequestInvitationThankView.SMSImageViewSize.width, height: RequestInvitationThankView.SMSImageViewSize.height)
        
        announceLabel.frame = CGRect(x: (bounds.sizeWidth - bounds.sizeWidth/2)/2, y: smsImageView.frame.maxY + RequestInvitationThankView.AnnounceLabelTopPadding, width: bounds.sizeWidth/2, height: RequestInvitationThankView.AnnounceLabelHeight)

        phoneNumberLabel.frame = CGRect(x: (bounds.sizeWidth - bounds.sizeWidth/2)/2, y: announceLabel.frame.maxY + RequestInvitationThankView.PhoneNumberLabelTopPadding, width: bounds.sizeWidth/2, height: RequestInvitationThankView.PhoneNumberLabelHeight)

        seperatorView.frame = CGRect(x: (bounds.sizeWidth - bounds.sizeWidth/2)/2, y: phoneNumberLabel.frame.maxY + RequestInvitationThankView.SeperatorViewTopPadding, width: bounds.sizeWidth/2, height: RequestInvitationThankView.SeperatorViewHeight)
        
        wechatInvitationLabel.frame = CGRect(x: (bounds.sizeWidth - RequestInvitationThankView.WechatInvitationLabelSize.width)/2, y: seperatorView.frame.maxY + RequestInvitationThankView.WechatInvitationLabelTopPadding, width: RequestInvitationThankView.WechatInvitationLabelSize.width, height: RequestInvitationThankView.WechatInvitationLabelSize.height)
        
        wechatFollowButton.frame = CGRect(x: RequestInvitationThankView.WechatFollowButtonLeftRightPadding, y: wechatInvitationLabel.frame.maxY + RequestInvitationThankView.WechatFollowButtonTopPadding, width: bounds.sizeWidth - 2 * RequestInvitationThankView.WechatFollowButtonLeftRightPadding, height: RequestInvitationThankView.WechatFollowButtonHeight)
        
        scrollViewContent.contentSize = CGSize(width: self.frame.sizeWidth, height: wechatFollowButton.frame.maxY + RequestInvitationThankView.WechatFollowButtonTopPadding)
    }
}
