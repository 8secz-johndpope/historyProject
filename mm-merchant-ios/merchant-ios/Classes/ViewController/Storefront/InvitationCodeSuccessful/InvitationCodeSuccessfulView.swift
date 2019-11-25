//
//  InvitationCodeSuccessfulView.swift
//  merchant-ios
//
//  Created by LongTa on 7/28/16.
//  Copyright © 2016 WWE & CO. All rights reserved.
//

import UIKit

class InvitationCodeSuccessfulView: UIView {

    private final let paddingLeftRight:CGFloat = 15
    
    let backgroundImageView = UIImageView()
    
    let logoIcon = UIImageView(image: UIImage(named: "logo_home_screen"))
    private final let logoIconPaddingBottom:CGFloat = 14
    private final var loginMethodPaddingBottom:CGFloat = 100
    private final let logoIconSize = CGSize(width: 90, height: 122)
    
    private final let labelCenterHeight:CGFloat = 18
    private final let LabelHeight : CGFloat = 44
    
    let wechatButton = UIButton()
    private final let wechatButtonPaddingRight:CGFloat = 50
    private final let wechatButtonSize:CGSize = CGSize(width: 50, height: 50)

    let registerButton = UIButton()
    
    private final let labelWeChatPaddingTop:CGFloat = 14
    
    private var viewLogin = UIView()
    private final let ButtonHeight : CGFloat = 44
    private var viewLoginOverlay = UIView()
    var loginButton = UIButton()
    private var seperator = UIView()
    var labelWeChat = UILabel()

    init() {
        super.init(frame: UIScreen.main.bounds)
        
        backgroundImageView.image = UIImage(named: "exclusive-bg")
        addSubview(backgroundImageView)
        
        logoIcon.contentMode = .scaleAspectFill
        addSubview(logoIcon)
        
        wechatButton.setImage(UIImage(named: "wechat_login"), for: UIControlState())
        addSubview(wechatButton)
        
        registerButton.setTitle(String.localize("LB_CA_MOBILE_NEW_REGISTRATION"), for: UIControlState())
        registerButton.setTitleColor(UIColor.white, for: UIControlState())
        registerButton.titleLabel?.font = UIFont.fontWithSize(15, isBold: true)
        registerButton.viewBorder(UIColor.primary1())
        registerButton.round(2)
        registerButton.backgroundColor = UIColor.primary1()
        addSubview(registerButton)
        
        loginButton.setTitle(String.localize("LB_CA_LOGIN"), for: UIControlState())
        loginButton.setTitleColor(UIColor.secondary2(), for: UIControlState())
        loginButton.titleLabel?.font = UIFont.systemFont(ofSize: 14)
        loginButton.viewBorder(UIColor.secondary1())
        loginButton.round(2)
        addSubview(loginButton)
        
        labelWeChat.text = String.localize("LB_CA_WECHAT_REGISTRATION")
        labelWeChat.formatSize(14)
        labelWeChat.textColor = UIColor.secondary2()
        labelWeChat.textAlignment = .center
        addSubview(labelWeChat)
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override func layoutSubviews() {
        super.layoutSubviews()
        self.setupLayouts()
    }
    
    func setupLayouts() {
        
        var originY = CGFloat(100)
        var registerPadding = CGFloat(75)
        if Constants.DeviceType.IS_IPHONE_4_OR_LESS  {
            originY = CGFloat(40)
            registerPadding = CGFloat(35)
        }

        
        backgroundImageView.frame = self.bounds
        
        logoIcon.frame = CGRect(x: (frame.sizeWidth - logoIconSize.width)/2, y: originY, width: logoIconSize.width, height: logoIconSize.height)
        
        registerButton.frame = CGRect(x: Margin.left, y: logoIcon.frame.maxY + registerPadding, width: frame.sizeWidth - 2 * Margin.left, height: ButtonHeight)
        
        loginButton.frame = CGRect(x: Margin.left, y: registerButton.frame.maxY + 16, width: frame.sizeWidth - 2 * Margin.left, height: ButtonHeight)
        
        let padding = CGFloat(35)
        
        wechatButton.frame = CGRect(x: (frame.sizeWidth - wechatButtonSize.width)/2, y: loginButton.frame.maxY + padding, width: wechatButtonSize.width, height: wechatButtonSize.height)
        
        if let textWeChat = labelWeChat.text {
            let labelWeChatWidth = StringHelper.getTextWidth(textWeChat, height: labelCenterHeight, font: labelWeChat.font)
            var labelWeChatFrame = CGRect.zero
            labelWeChatFrame.origin.x = wechatButton.frame.midX - labelWeChatWidth/2
            labelWeChatFrame.origin.y = wechatButton.frame.maxY + labelWeChatPaddingTop
            labelWeChatFrame.size = CGSize(width: labelWeChatWidth, height: labelCenterHeight)
            labelWeChat.frame = labelWeChatFrame
        }

        
    }
}
