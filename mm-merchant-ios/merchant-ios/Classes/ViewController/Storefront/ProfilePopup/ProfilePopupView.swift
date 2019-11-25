//
//  ProfilePopupView.swift
//  merchant-ios
//
//  Created by LongTa on 7/19/16.
//  Copyright © 2016 WWE & CO. All rights reserved.
//

import UIKit

protocol ProfilePopupViewDelegate: NSObjectProtocol {
    func selectedShareMethod(_ method: ShareMethod)
}

class ProfilePopupView: UIView {
    
    enum SocialTag: Int {
        case Wechat = 0
        case WechatFriend
        case Weibo
        case QQ
        case QQSpace
        case SMS
    }
    
    enum PopupType {
        case Campaign
        case OrderSuccess
    }
    
    var popupType: PopupType = .Campaign
    let paddingLeftRight:CGFloat = 15
    
    let labelHeight:CGFloat = 15
    
    let tranparentView = UIView()
    
    let viewContent = UIScrollView()
    let viewContentPaddingTopBottom:CGFloat = 60 + ScreenBottom * 2 
    
    let viewCompletedOrder = ViewCompletedOrder(frame: CGRect.zero)
    
    let bannerImageView = UIImageView()
    let bannerRatio:CGFloat = 2.0
    
    let closeButton = UIButton()
    private final let CloseButtonHeight :CGFloat = 60
    private final let CloseButtonPaddingTop :CGFloat = 0

    let labelPlusWidth:CGFloat = 30
    
    let labelCampaginDesc = UILabel()
    let labelCampaginDescSize:CGSize = CGSize(width: 190, height: 60)
    
    
    let buttonRefereeTNC = UIButton(type: .custom)
    let labelSocialPaddingTop:CGFloat = 35
    
    let viewSocialContainer = UIView()
    
    let thanksImageView = UIImageView()
    let thanksImageViewSize:CGSize = CGSize(width: 190, height: 40)
    let thanksImageViewSizePaddingTop:CGFloat = 50
    
    let labelThankYou = UILabel()
    let labelThankYouSize = CGSize(width: 261, height: 40)
    
    
    let buttonMoreAboutPaddingTopIsFullyInvited:CGFloat = 70
    
    weak var delegate:ProfilePopupViewDelegate?
    
    var isFromInviteFriends = false
    var isFullScreen = false
    let fullyInvitedPaddingTop:CGFloat = 30
    var imageSize : CGSize?
    private final let ProgressNumber : Int = 3
    var refereeTNCPressed: (() -> Void)?
    var viewOrderPressed: (() -> Void)?
    
    init(frame: CGRect, isFullScreen: Bool = false) {
        super.init(frame: frame)

        self.isFullScreen = isFullScreen
        self.initViews()
    }
    
    func initViews() {
        if !isFullScreen {
            self.backgroundColor = UIColor.clear
            
            tranparentView.backgroundColor = UIColor.black.withAlphaComponent(0.4)
            addSubview(tranparentView)
            viewContent.clipsToBounds = true
            viewContent.backgroundColor = UIColor.white
            viewContent.layer.cornerRadius = 10
        }
    
        addSubview(viewContent)
        
        viewContent.addSubview(bannerImageView)

        viewContent.addSubview(viewCompletedOrder)
        
        viewCompletedOrder.buttonViewOrder.addTarget(self, action: #selector(ProfilePopupView.viewOrderPressed(sender:)), for: .touchUpInside)
        
        bannerImageView.image = UIImage(named: "tile_placeholder")
        bannerImageView.contentMode = .scaleAspectFill
        
        closeButton.setBackgroundImage(UIImage(named: "btn_close_light")?.withRenderingMode(.alwaysTemplate), for: .normal)
        
        closeButton.tintColor = UIColor.white
        
        labelCampaginDesc.text = String.localize("LB_MKT_POPUP_TITLE_PLACEHOLDER")
        labelCampaginDesc.formatSizeBold(16)
        labelCampaginDesc.textAlignment = .center
        viewContent.addSubview(labelCampaginDesc)
        
        buttonRefereeTNC.setTitle(String.localize("LB_CA_REFERRAL_TNC"), for: .normal)
        buttonRefereeTNC.titleLabel?.font = UIFont.fontWithSize(12, isBold: false)
        if let imageMore = UIImage(named: "filter_right_arrow")?.resizeWithWidth(12) {
            buttonRefereeTNC.setImage(imageMore, for: .normal)
        }
        
        buttonRefereeTNC.imageEdgeInsets = UIEdgeInsetsMake(3, 6, 3, 6)
        buttonRefereeTNC.setTitleColor(UIColor.secondary2(), for: .normal)
        if #available(iOS 9.0, *) {
            buttonRefereeTNC.semanticContentAttribute = .forceRightToLeft
        }
        buttonRefereeTNC.titleEdgeInsets = UIEdgeInsetsMake(0, 0, 0, 5)
        buttonRefereeTNC.addTarget(self, action: #selector(ProfilePopupView.refereeTNCPressed(sender:)), for: .touchUpInside)
        viewContent.addSubview(buttonRefereeTNC)
        
        self.addSocialSubviews()
        viewContent.addSubview(viewSocialContainer)
        
        thanksImageView.image = UIImage(named: "1+1+1_thankyou")
        viewContent.addSubview(thanksImageView)
        
        labelThankYou.text = String.localize("LB_CA_PARTICIPANTION_THANKS") + "\n" + String.localize("LB_CA_PARTICIPANTION_PRICE")
        labelThankYou.formatSmall()
        labelThankYou.textAlignment = .center
        viewContent.addSubview(labelThankYou)
        if isFullScreen {
            let heightNavigationBar: CGFloat = 64
            viewContent.frame = CGRect(x:0,y: heightNavigationBar,width: self.frame.sizeWidth,height: self.frame.sizeHeight - heightNavigationBar)
        } else {
            viewContent.frame = CGRect(x:paddingLeftRight,y: self.frame.sizeHeight /*viewContentPaddingTopBottom*/,width: self.frame.sizeWidth - 2*paddingLeftRight,height: self.frame.sizeHeight - 2*viewContentPaddingTopBottom)
        }
        
        self.addSubview(closeButton)
        closeButton.snp.makeConstraints { (make) in
            make.centerX.equalTo(self)
            make.top.equalTo(viewContent.snp.bottom).offset(CloseButtonPaddingTop)
            make.width.height.equalTo(CloseButtonHeight)
        }
        
    }
    
    func showContentView(_ animated: Bool){
        var frame = viewContent.frame
        frame.origin.y = viewContentPaddingTopBottom
        var closeFrame = self.closeButton.frame
        closeFrame.origin.y = viewContentPaddingTopBottom + frame.height + CloseButtonPaddingTop
        if animated {
            UIView.animate(withDuration: 0.3, animations: {
                self.viewContent.frame = frame
                self.closeButton.frame = closeFrame
            }, completion: { (completed) in
            }) 
        } else {
            self.viewContent.frame = frame
        }
    }
    
    func hideContentView(){
        var frame = viewContent.frame
        frame.origin.y = self.frame.sizeHeight
        viewContent.frame = frame
        var closeFrame = self.closeButton.frame
        closeFrame.origin.y = self.frame.sizeHeight + viewContent.frame.height + CloseButtonPaddingTop
        self.closeButton.frame = closeFrame
        
    }
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override func layoutSubviews() {
        super.layoutSubviews()
        self.setupLayouts()
    }
    
    
    
    func setupLayouts() {
        tranparentView.frame = self.bounds
        
        if let size = self.imageSize {
             bannerImageView.frame = CGRect(x: 0, y: 0, width: viewContent.frame.sizeWidth,  height: viewContent.frame.sizeWidth / size.width * size.height )
        } else {
            bannerImageView.frame = CGRect(x:0,y: 0,width: viewContent.frame.sizeWidth, height: viewContent.frame.sizeWidth / 375 * 235 )
        }
        
        viewCompletedOrder.frame = bannerImageView.frame
        if popupType == .OrderSuccess {
            bannerImageView.isHidden = true
            viewCompletedOrder.isHidden = false
        } else {
            bannerImageView.isHidden = false
            viewCompletedOrder.isHidden = true
        }
        
        bannerImageView.backgroundColor = UIColor.primary2()
        
        let paddingTopLabelCampaign: CGFloat = 0
        labelCampaginDesc.frame = CGRect(x:(viewContent.frame.sizeWidth - labelCampaginDescSize.width)/2,y: bannerImageView.frame.maxY + paddingTopLabelCampaign,width: labelCampaginDescSize.width,height: labelCampaginDescSize.height)
        
        var paddingTopSocialView: CGFloat = 25
        if Constants.DeviceType.IS_IPHONE_5  {
            paddingTopSocialView = 5
        }
        let labelSocialWidth: CGFloat = 120
        buttonRefereeTNC.frame = CGRect(x:(viewContent.frame.sizeWidth - labelSocialWidth)/2,y: labelCampaginDesc.frame.maxY + paddingTopSocialView ,width:labelSocialWidth,height:labelHeight)
        
        viewSocialContainer.frame = CGRect(x:(viewContent.frame.sizeWidth - viewSocialContainer.frame.sizeWidth)/2,y: buttonRefereeTNC.frame.maxY + 20,width: viewSocialContainer.frame.sizeWidth,height: viewSocialContainer.frame.sizeHeight)
        
        let paddingTop = viewSocialContainer.frame.maxY
        
        viewContent.contentSize = CGSize(width: viewContent.frame.sizeWidth, height: paddingTop)
        
        let originY = (buttonRefereeTNC.frame.minY - bannerImageView.frame.maxY) / 2 + bannerImageView.frame.maxY -  labelCampaginDesc.frame.sizeHeight / 2
        labelCampaginDesc.frame.originY = originY
    }
    
    
    func addSocialSubviews(){
        
        let viewSocialContainerHeight = SocialView.defaultHeight()
        var i = 0
        var yPosition: CGFloat = 0
        var xPosition: CGFloat = 0
        let numberOfSocial = 6
        var marginLeft = CGFloat(20)
        if Constants.DeviceType.IS_IPHONE_5 {
            marginLeft = CGFloat(14)
        }
        let totalViewSocialPadding = ((self.frame.sizeWidth) - 4*SocialView.ovalSize.width) - marginLeft * 2
        let viewSocialPadding = totalViewSocialPadding/4
        
        while i < numberOfSocial {
            
            let socialView = SocialView()
            socialView.ovalButton.tag = i
            socialView.ovalButton.addTarget(self, action: #selector(ProfilePopupView.socialSelected), for: .touchUpInside)
            viewSocialContainer.addSubview(socialView)
            
            if i == SocialTag.Wechat.rawValue {
                socialView.ovalButton.setBackgroundImage(UIImage(named: "wechat"), for: .normal)
                socialView.label.text = String.localize("LB_WECHAT")
            }
            else if i == SocialTag.WechatFriend.rawValue {
                socialView.ovalButton.setBackgroundImage(UIImage(named: "wechat-2"), for: .normal)
                socialView.label.text = String.localize("LB_WECHAT_FRIENDS")
            }
            else if i == SocialTag.Weibo.rawValue {
                socialView.ovalButton.setBackgroundImage(UIImage(named: "weibo"), for: .normal)
                socialView.label.text = String.localize("LB_SINA_WEIBO")
            }
            else if i == SocialTag.QQ.rawValue {
                socialView.ovalButton.setBackgroundImage(UIImage(named: "QQ"), for: .normal)
                socialView.label.text = String.localize("LB_TENCENT_QQ")
            }
            else if i == SocialTag.QQSpace.rawValue {
                socialView.ovalButton.setBackgroundImage(UIImage(named: "qq_space"), for: .normal)
                socialView.label.text = "QQ空间"
            }
            else if i == SocialTag.SMS.rawValue {
                socialView.ovalButton.setBackgroundImage(UIImage(named: "sms"), for: .normal)
                socialView.label.text = String.localize("LB_CA_SMS")
            }
            
            
            socialView.frame = CGRect(x: xPosition, y: yPosition, width: SocialView.ovalSize.width, height: viewSocialContainerHeight)
            
            
            socialView.frame.sizeWidth = SocialView.ovalSize.width
            
            var frameContainer = viewSocialContainer.frame
            if frameContainer.size.width < socialView.frame.maxX {
                frameContainer.size.width = socialView.frame.maxX
            }
            frameContainer.size.height = socialView.frame.maxY
            viewSocialContainer.frame = frameContainer
            i += 1
            
            if i % 4 == 0 {
                xPosition = 0
                yPosition = yPosition + socialView.frame.sizeHeight + 20
            } else {
                xPosition = xPosition + viewSocialPadding + socialView.frame.sizeWidth
            }
            
        }
    }
    
    //MARK: Actions
    func friendSelected(_ sender: UIButton){
        Log.debug(sender.tag)
    }
    
    @objc func viewOrderPressed(sender: UIButton) {
        self.viewOrderPressed?()
    }
    
    @objc func refereeTNCPressed(sender: UIButton){
        self.refereeTNCPressed?()
    }
    
   @objc func socialSelected(_ sender: UIButton){
        switch sender.tag {
        case SocialTag.Wechat.rawValue:
            self.shareMethod(ShareMethod.weChatMessage, sender: sender)
            break
        case SocialTag.WechatFriend.rawValue:
            self.shareMethod(ShareMethod.weChatMoment, sender: sender)
            break
        case SocialTag.Weibo.rawValue:
            self.shareMethod(ShareMethod.weiboWall, sender: sender)
            break
        case SocialTag.QQ.rawValue:
            self.shareMethod(ShareMethod.qqMessage, sender: sender)

            break
        case SocialTag.QQSpace.rawValue:
            self.shareMethod(ShareMethod.qqZone, sender: sender)
            break
        case SocialTag.SMS.rawValue:
            self.shareMethod(ShareMethod.sms, sender: sender)
            break
        default:
            break
        }
    }
    
    func shareMethod(_ method: ShareMethod, sender: UIButton){
        if let delegate = self.delegate{
            delegate.selectedShareMethod(method)
        }
        
        
        var targetRef = ""
        switch method {
        case ShareMethod.weChatMessage:
            targetRef = "WeChat-Friends"
            break
        case ShareMethod.weChatMoment:
            targetRef = "WeChat-Moments"
        case ShareMethod.weiboWall:
            targetRef = "Weibo"
            break
        case ShareMethod.qqMessage:
            targetRef = "QQFriends"
            break
        case ShareMethod.qqZone:
            targetRef = "QQZone"
            break
        case ShareMethod.sms:
            targetRef = "SMS"
            break
        default:
            break
        }
        if self.isInviteFriendScreen() {
            self.recordAction(
                .Tap,
                sourceRef: Constants.SNSFriendReferralEnabled ?  "Incentive-Invite" : "Invite",
                sourceType: .Button,
                targetRef: targetRef,
                targetType: .Channel
            )
        }else {
            //record button action
            self.recordAction(
                .Tap,
                sourceRef: "Share",
                sourceType: .Button,
                targetRef: targetRef,
                targetType: .IncentiveReferral
            )
        }
        
    }
    
    func isInviteFriendScreen() -> Bool {
        if let navi = Utils.findActiveNavigationController() {
            if let _ = navi.viewControllers[0] as? AddFriendViewController {
                return true
            }
        }
        return false
    }
}

internal class ViewCompletedOrder: UIView {
    
    let ImageSize = CGSize(width: 65, height: 65)
    let ButtonSize = CGSize(width: 120, height: 40)
    let imageCompleteOrder = UIImageView()
    let buttonViewOrder = UIButton(type: .custom)
    let bottomSeperateCompleteOrder = UIView()
    let labelCompletedOrder = UILabel()
    
    init(frame: CGRect, isFullScreen: Bool = false) {
        super.init(frame: frame)
        
        imageCompleteOrder.image = UIImage(named: "icon_order_timeline_received_active")
        self.addSubview(imageCompleteOrder)
        
        labelCompletedOrder.text = String.localize("LB_CA_THANKYOU_C4A")
        labelCompletedOrder.formatSizeBold(16)
        labelCompletedOrder.textAlignment = .center
        self.addSubview(labelCompletedOrder)
        
        buttonViewOrder.setTitle(String.localize("LB_CA_UNPAID_ORDER_CHECK_ORDER"), for: .normal)
        buttonViewOrder.layer.borderWidth = Constants.Button.BorderWidth
        buttonViewOrder.layer.borderColor = UIColor.secondary1().cgColor
        buttonViewOrder.layer.backgroundColor = UIColor.white.cgColor
        buttonViewOrder.setTitleColor(UIColor.secondary2(), for: .normal)
        buttonViewOrder.titleLabel!.font = UIFont(name: buttonViewOrder.titleLabel!.font.fontName, size: CGFloat(14))!
        self.addSubview(buttonViewOrder)
        
        bottomSeperateCompleteOrder.backgroundColor = UIColor.backgroundGray()
        self.addSubview(bottomSeperateCompleteOrder)
        
    }
    
    override func layoutSubviews() {
        super.layoutSubviews()
        
        let marginLeftRight: CGFloat = self.bounds.sizeWidth/5
        let heightSeperateView: CGFloat = 7
        imageCompleteOrder.frame = CGRect(x:(self.bounds.sizeWidth - ImageSize.width)/2,y:20,width: self.bounds.sizeWidth * ImageSize.width / 375,height:self.bounds.sizeWidth * ImageSize.height / 375)
        
        let yLabelCompleteOrder = imageCompleteOrder.frame.maxY + 10
        let heightLabelCompleteOrder = self.bounds.sizeHeight / 3
        labelCompletedOrder.frame = CGRect(x:marginLeftRight,y:yLabelCompleteOrder,width:self.bounds.sizeWidth - 2 * marginLeftRight,height:heightLabelCompleteOrder)
        
        buttonViewOrder.frame = CGRect(x:(self.bounds.sizeWidth - ButtonSize.width)/2,y: labelCompletedOrder.frame.maxY,width: ButtonSize.width,height: ButtonSize.height)
        
        bottomSeperateCompleteOrder.frame = CGRect(x:0,y: self.bounds.sizeHeight - heightSeperateView,width: self.bounds.width, height:heightSeperateView)
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}
