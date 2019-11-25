//
//  HeaderMerchantProfileView.swift
//  merchant-ios
//
//  Created by Trung Vu on 3/10/16.
//  Copyright © 2016 WWE & CO. All rights reserved.
//
import UIKit

import Kingfisher

@objc
protocol HeaderMerchantProfileDelegate: NSObjectProtocol {
    @objc optional func didSelectButtonFollow(_ sender: UIButton, status: Bool)
    @objc optional func didSelectButtonShare(_ sender: UIButton)
    @objc optional func didSelectButtonChat(_ sender: UIButton)
    @objc optional func didSelectFollowerList(_ gesture: UITapGestureRecognizer)
    @objc optional func didSelectDescriptionView(_ gesture: UITapGestureRecognizer)
}

enum ButtonTag: Int {
    case buttonDescTag = 20,
    buttonServiceTag,
    buttonRatingTag
}
class HeaderMerchantProfileView: UICollectionReusableView {
    
    private final let HeightForCell: CGFloat = 134.0
    private final let HeightNavigation: CGFloat = 44.0
    private final let ImageAvatarWidth : CGFloat = 70.0
    private final let ImageIconWidth: CGFloat = 25.0
    private final let HeighLabelUserName: CGFloat = 18.0
    private final let HeightAvatar: CGFloat = 92.0
    
    private final let HeightActionView: CGFloat = 70.0
    private final let HeightBottomView: CGFloat = 44.0
    private final let marginTop:CGFloat = 10.0
    private final let ImageCameraWidth:CGFloat = 25.0
    private final let marginLeftCamera:CGFloat = 15.0
    private final let ImageCameraHeight: CGFloat = 20.0
    private final let MarginActionButton:CGFloat = 20.0
    private final let WidthImageCameraBottom:CGFloat = 80.0
    private final let WidthItemButton:CGFloat = 30
    private final let HeightItemButton:CGFloat = 30
    private final let space:CGFloat = 5.0
    private final let widthLogo: CGFloat = 120.0
    private final let HeightLogo:CGFloat = 35.0
    private final let marginLeft:CGFloat = 48.0
    private final let HeightDescriptionView:CGFloat = 100.0
    
    private final let grayColor = UIColor.secondary4()
    private final let NotiHasAvatar = "NotiHasAvatar"
    
    var coverImageView          = UIImageView()
    var overlay                 = UIImageView()

    var  bottomView             = UIView()
    var labelFollower           = UILabel()
    var labelNumberFollower     = UILabel()
	var buttonFollower			= UIButton()

    var imageViewAdd            = UIImageView()
    var buttonAddFollow         = UIButton()
    var imageViewShare          = UIImageView()
    var buttonShare             = UIButton()
    var imageViewChat           = UIImageView()
    var buttonChat              = UIButton()
    
    var imageviewLogo           = UIImageView()
    var viewScore               = UIView()
    var buttonDesc              = UIButton()
    var buttonService           = UIButton()
    var buttonRating            = UIButton()
    
    var viewDescrip             = UIView()
    var labelName               = UILabel()
    var labelDescription        = UILabel()
    var line                    = UIView()
    var imageviewArrow          = UIImageView()
    
    var merchant = Merchant()
    weak var delegateMerchantProfile: HeaderMerchantProfileDelegate?
    var statusFollow = false
	
	var brand = Brand()
	
    override init(frame: CGRect) {
        super.init(frame: frame)
        self.isUserInteractionEnabled = true
        self.backgroundColor = UIColor.white
        
        coverImageView.image = UIImage(named: "default_cover")
        coverImageView.contentMode = .scaleAspectFill
        coverImageView.clipsToBounds = true
        coverImageView.isUserInteractionEnabled = false
        self.addSubview(coverImageView)
        
        overlay.image = UIImage(named: "overlay")
        self.addSubview(overlay)
        
        //create bottom View
        bottomView.backgroundColor = UIColor(white: 0, alpha: 0.5)
        self.addSubview(bottomView)
        
        labelFollower.text = String.localize("LB_CA_FOLLOWER")
        let tapGesture = UITapGestureRecognizer(target: self, action: #selector(HeaderMerchantProfileView.onHandleFollower))
        labelFollower.addGestureRecognizer(tapGesture)
        labelFollower.isUserInteractionEnabled = true
        labelFollower.formatSize(14)
        labelFollower.textColor = UIColor.white
        bottomView.addSubview(labelFollower)

		labelNumberFollower.text = ""
        labelNumberFollower.formatSize(18)
        labelNumberFollower.textColor = UIColor.white
        bottomView.addSubview(labelNumberFollower)
		
        // right view
		
        imageViewAdd.image = UIImage(named: "btn_request")
        imageViewAdd.contentMode = .scaleAspectFill
		let followGesture = UITapGestureRecognizer(target: self, action: #selector(HeaderMerchantProfileView.onHandleFollow))
		imageViewAdd.addGestureRecognizer(followGesture)
		imageViewAdd.isUserInteractionEnabled = true
        bottomView.addSubview(imageViewAdd)
        bottomView.addSubview(buttonAddFollow)
        buttonAddFollow.setTitle(String.localize("LB_CA_FOLLOW"), for: UIControlState())
        buttonAddFollow.addTarget(self, action: #selector(HeaderMerchantProfileView.onHandleFollow), for: .touchUpInside)
        buttonAddFollow.titleLabel?.formatSize(14)
        bottomView.addSubview(imageViewShare)
		
		imageViewShare.image = UIImage(named: "btn_share_wht")
		let shareGesture = UITapGestureRecognizer(target: self, action: #selector(HeaderMerchantProfileView.onHandleShare))
		imageViewShare.addGestureRecognizer(shareGesture)
		imageViewShare.isUserInteractionEnabled = true
        bottomView.addSubview(buttonShare)
        buttonShare.setTitle(String.localize("LB_CA_SHARE"), for: UIControlState())
        buttonShare.addTarget(self, action: #selector(HeaderMerchantProfileView.onHandleShare), for: .touchUpInside)
        buttonShare.titleLabel?.formatSize(14)
		bottomView.addSubview(buttonChat)
		
		imageViewChat.image = UIImage(named: "btn_cs_wht")
		let chatGesture = UITapGestureRecognizer(target: self, action: #selector(HeaderMerchantProfileView.onHandleChat))
		imageViewChat.addGestureRecognizer(chatGesture)
		imageViewChat.isUserInteractionEnabled = true
        buttonChat.addTarget(self, action: #selector(HeaderMerchantProfileView.onHandleChat), for: .touchUpInside)
        buttonChat.setTitle(String.localize("LB_CA_PROF_CS"), for: UIControlState())
        buttonChat.titleLabel?.formatSize(14)
		bottomView.addSubview(imageViewChat)
        
        buttonDesc = self.createButton(ButtonTag.buttonDescTag.rawValue, textName: String.localize("LB_CA_PROD_DESC"), number: "5.0")
        buttonService = self.createButton(ButtonTag.buttonServiceTag.rawValue, textName: String.localize("LB_CA_CUST_SERVICE"), number: "5.0")
        buttonRating = self.createButton(ButtonTag.buttonRatingTag.rawValue, textName: String.localize("LB_CA_SHIPMENT_RATING"), number: "5.0")
        if let button = buttonRating.viewWithTag(9) {
            button.backgroundColor = UIColor.clear
        }
        // logo
//        imageviewLogo.image = UIImage(named: "logo_demo")
        imageviewLogo.contentMode = .center
        viewScore.addSubview(imageviewLogo)
        self.addSubview(viewDescrip)
        self.addSubview(viewScore)
        viewScore.addSubview(buttonDesc)
        viewScore.addSubview(buttonService)
        viewScore.addSubview(buttonRating)
        line.backgroundColor = UIColor.primary2()
        viewScore.addSubview(line)
        
        labelName.text = ""
        labelName.formatSize(15)
        labelName.textColor = UIColor.secondary2()
        viewDescrip.addSubview(labelName)
        
        labelDescription.text = ""
        labelDescription.formatSize(14)
        labelDescription.textColor = UIColor.secondary3()
        labelDescription.lineBreakMode = NSLineBreakMode.byTruncatingTail
        labelDescription.numberOfLines = 2
        viewDescrip.addSubview(labelDescription)
        
        imageviewArrow.image = UIImage(named: "icon_arrow")
        viewDescrip.addSubview(imageviewArrow)
        
        let tapDescription = UITapGestureRecognizer(target: self, action: #selector(HeaderMerchantProfileView.didSelectDescriptionDetail))
        viewDescrip.addGestureRecognizer(tapDescription)
        
    }
    
    override func layoutSubviews() {
        super.layoutSubviews()
        
        coverImageView.frame = CGRect(x: 0, y: 0, width: self.frame.width, height: self.frame.height - HeightDescriptionView - 80)
        overlay.frame = coverImageView.frame
        
        // set up description view
        viewDescrip.frame = CGRect(x: 0, y: self.frame.height - 80, width: self.frame.width, height: 80)
        
        
        viewScore.frame = CGRect(x: 0, y: self.frame.height - HeightDescriptionView - 80, width: self.frame.width, height: HeightDescriptionView)
        imageviewLogo.frame = CGRect(x: (self.frame.width - widthLogo)/2, y: 10, width: widthLogo, height: HeightLogo)
        
        let width = (self.frame.width - marginLeft * 2) / 3
        let orginYBtn = imageviewLogo.frame.origin.y + HeightLogo + space

        buttonDesc.frame = CGRect(x: marginLeft, y: orginYBtn, width: width, height: 40)
        buttonService.frame = CGRect(x: buttonDesc.frame.origin.x + width, y: orginYBtn, width: width, height: 40)
        buttonRating.frame = CGRect(x: buttonService.frame.origin.x + width, y: orginYBtn, width: width, height: 40)
        
        
        //setup bottomView
        bottomView.frame = CGRect(x: 0, y: viewScore.frame.origin.y - HeightBottomView, width: self.frame.width
            , height: HeightBottomView)
        
        let widthLabelFollower = StringHelper.getTextWidth(labelFollower.text!, height: 22.0, font: labelFollower.font)
        labelFollower.frame = CGRect(x: 16, y: (bottomView.frame.height - 22.0) / 2, width: widthLabelFollower, height: 22.0)
        updateFrameLabelFollowing()
        
        // add view follow
//        let WidthViewRight = self.frame.width - (self.labelNumberFollower.frame.origin.x + self.labelNumberFollower.frame.width + 0)
//        viewRight.frame =  CGRect(x:bottomView.frame.size.width - WidthViewRight, y: 0, width: WidthViewRight, height: HeightBottomView)


        let widthButtonChat = StringHelper.getTextWidth((buttonChat.titleLabel?.text)!, height: buttonChat.frame.height, font: (buttonChat.titleLabel?.font)!)
        buttonChat.frame = CGRect(x: self.frame.width - space - widthButtonChat, y: (HeightBottomView - HeightItemButton)/2, width: widthButtonChat, height: HeightItemButton)
        imageViewChat.frame = CGRect(x: buttonChat.frame.origin.x - WidthItemButton, y: (HeightBottomView - HeightItemButton)/2, width: WidthItemButton, height: HeightItemButton)
        
        let widthItemFollow = StringHelper.getTextWidth((buttonShare.titleLabel?.text)!, height: buttonShare.frame.height, font: (buttonShare.titleLabel?.font)!)
        buttonShare.frame = CGRect(x: imageViewChat.frame.origin.x - widthItemFollow - space, y: (HeightBottomView - HeightItemButton)/2, width: widthItemFollow, height: HeightItemButton)
        imageViewShare.frame = CGRect(x: buttonShare.frame.origin.x - WidthItemButton, y: (HeightBottomView - HeightItemButton)/2, width: WidthItemButton, height: HeightItemButton)
        
        let widthItemFollowBtn = StringHelper.getTextWidth((buttonAddFollow.titleLabel?.text)!, height: buttonAddFollow.frame.height, font: (buttonAddFollow.titleLabel?.font)!)
        buttonAddFollow.frame = CGRect(x: imageViewShare.frame.origin.x - widthItemFollowBtn - space, y: (HeightBottomView - HeightItemButton)/2, width: widthItemFollowBtn, height: HeightItemButton)
        imageViewAdd.frame = CGRect(x: buttonAddFollow.frame.origin.x - WidthItemButton, y: (HeightBottomView - HeightItemButton)/2, width: WidthItemButton, height: HeightItemButton)
        
       
        labelName.frame = CGRect(x: marginTop, y: marginTop, width: self.frame.width - marginTop*2, height: 21)
        updateFrameDescription()
        line.frame = CGRect(x: marginTop, y: HeightDescriptionView - 1, width: self.frame.width - marginTop * 2, height: 1)
        imageviewArrow.frame = CGRect(x: self.frame.width - 25, y: (80 - 15)/2, width: 8, height: 15)
		
		updateFollowersButton()
        
        if self.brand.brandId != 0 {
            self.adjustShareButtonPosition()
        }
    }
		
	func updateFollowersButton() {
		buttonFollower = UIButton(frame: CGRect(x: labelFollower.frame.origin.x, y: labelFollower.frame.origin.y, width: (labelFollower.frame.origin.x + labelFollower.frame.size.width + labelNumberFollower.frame.size.width), height: labelFollower.frame.size.height))
		buttonFollower.addTarget(self, action: #selector(HeaderMerchantProfileView.onHandleFollower), for: .touchUpInside)
		bottomView.addSubview(buttonFollower)
	}
    
    func updateFrameDescription() {
        
        labelDescription.frame = CGRect(x: marginTop, y: labelName.frame.origin.y + 21, width: self.frame.width - 60, height: 42)
    }
    
//    func updateFrame() {
//        var height = getTextHeight(labelDescription.text!, width: self.frame.width - 40, font: labelDescription.font)
//        if height > HeightDescriptionView - space {
//            height = HeightDescriptionView - space - labelName.frame.height - marginTop
//        }
//        labelDescription.frame = CGRect(x:marginTop, y: labelName.frame.origin.y + 21, width: self.frame.width - 60, height: height)
//    }
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    func updateFrameLabelFollowing() {
        let widthLabelFollower = StringHelper.getTextWidth(labelFollower.text!, height: 22.0, font: labelFollower.font)
        let widthLabelNumberFollower = StringHelper.getTextWidth(labelNumberFollower.text!, height: 22.0, font: labelNumberFollower.font)
        let xLabel = 16 + widthLabelFollower + 10
        labelNumberFollower.frame = CGRect(x: xLabel, y: (bottomView.frame.height - 22.0) / 2 , width: widthLabelNumberFollower, height: 22.0)
    }
    
    func getTextHeight(_ text: String, width: CGFloat, font: UIFont) -> CGFloat {
        let constraintRect = CGSize(width: width, height: CGFloat.greatestFiniteMagnitude)
        let boundingBox = text.boundingRect(with: constraintRect, options: NSStringDrawingOptions.usesLineFragmentOrigin, attributes: [NSAttributedStringKey.font: font], context: nil)
        return boundingBox.height
    }
    func originY() -> CGFloat
    {
        var originY:CGFloat = 0;
        let application: UIApplication = UIApplication.shared
        if (application.isStatusBarHidden)
        {
            originY = application.statusBarFrame.size.height
        }
        return originY;
    }
    func createButton(_ index: Int, textName: String, number: String) -> UIButton {
        let width = (self.frame.width - marginLeft * 2) / 3
        let frm = CGRect(x: 0, y: 0, width: width, height: HeightActionView)
        let buttonParent = UIButton(frame: frm)
        buttonParent.tag = index
        buttonParent.backgroundColor = UIColor.white
        buttonParent.setTitle(String(format: "%@ %@", textName, number), for: UIControlState())
        buttonParent.titleLabel?.formatSize(12)
        buttonParent.setTitleColor(UIColor.secondary2(), for: UIControlState())
        
        let border = UIView(frame: CGRect(x: width - 1, y: 5, width: 1, height: 30))
        border.backgroundColor = UIColor.primary2()
        border.tag = 9
        border.alpha = 0.5
        buttonParent.addSubview(border)
        return buttonParent
    }
    
    //MARK: loading data
    
    func configDataWithMerchant(_ merchant: Merchant, isFollowing: Bool) {
        self.merchant = merchant
        statusFollow = isFollowing
        labelNumberFollower.text = String(format: "%d", merchant.followerCount)
        setCoverImage(merchant.profileBannerImage, imageCategory: .merchant)
        labelName.text = String(format: "%@", merchant.merchantName)
        labelDescription.text = String(format: "%@", merchant.merchantDesc)
        updateFrameDescription()
        setDataImageviewLogo(merchant.headerLogoImage, imageCategory: .merchant)
        configButtonFollow(isFollowing)
        
        layoutSubviews()
    }

	func configDataWithBrand(_ brand: Brand) {
		self.brand = brand
		
		statusFollow = false
		labelNumberFollower.text = ""
		
		setCoverImage(brand.profileBannerImage, imageCategory: .brand)
		
		labelName.text = String(format: "%@", brand.brandName)
		labelDescription.text = String(format: "%@", brand.brandDesc)
		
		updateFrameDescription()
		
		setDataImageviewLogo(brand.headerLogoImage, imageCategory: .brand)
		
		configButtonFollow(false)
		
		layoutSubviews()
		
		adjustShareButtonPosition()
		
	}
	
	func adjustShareButtonPosition() {
	
		imageViewShare.frame = imageViewChat.frame
		buttonShare.frame = buttonChat.frame
		buttonShare.contentHorizontalAlignment = UIControlContentHorizontalAlignment.left
		
		buttonFollower.isHidden = true
		buttonAddFollow.isHidden = true
		buttonChat.isHidden = true
		
		labelFollower.isHidden = true
		imageViewAdd.isHidden = true
		imageViewChat.isHidden = true

		var rect = imageViewShare.frame
		rect.origin.x = rect.origin.x + 15
		imageViewShare.frame = rect
		
		rect = buttonShare.frame
		rect.origin.x = rect.origin.x + 15
		buttonShare.frame = rect
	}

	func setCoverImage(_ key : String, imageCategory : ImageCategory){
        if self.frame.height > 0 {
            coverImageView.mm_setImageWithURL(HeaderMyProfileCell.getCoverImageUrl(key, imageCategory: imageCategory, width: self.width), placeholderImage: UIImage(named: "default_cover"), contentMode: .scaleAspectFill)
        }
    }
    
    func setDataImageviewLogo(_ key : String, imageCategory : ImageCategory){
	
        if imageviewLogo.frame.size.width > 0 {
            imageviewLogo.mm_setImageWithURL(ImageURLFactory.URLSize1000(key, category:imageCategory), placeholderImage : nil, contentMode: .scaleAspectFit)
        }
        
    }
    
    func configButtonFollow(_ status:Bool) {
        if status {
            imageViewAdd.image = UIImage(named: "btn_ok")
            buttonAddFollow.setTitle(String.localize("LB_CA_FOLLOWED"), for: UIControlState())
        } else {
            imageViewAdd.image = UIImage(named: "btn_request")
            buttonAddFollow.setTitle(String.localize("LB_CA_FOLLOW"), for: UIControlState())
        }
    }
    // MARK: - Action
    @objc func onHandleFollow(_ sender: UIButton) {
        self.delegateMerchantProfile?.didSelectButtonFollow!(sender, status:statusFollow)
    }
    
    @objc func onHandleShare(_ sender: UIButton) {
        self.delegateMerchantProfile?.didSelectButtonShare!(sender)
    }
    @objc func onHandleChat(_ sender: UIButton) {
        self.delegateMerchantProfile?.didSelectButtonChat!(sender)
    }
    @objc func onHandleFollower(_ gesture: UITapGestureRecognizer){
        if self.merchant.followerCount > 0 {
            self.delegateMerchantProfile?.didSelectFollowerList!(gesture)
        }
    }
    
    @objc func didSelectDescriptionDetail(_ gesture: UITapGestureRecognizer){
        self.delegateMerchantProfile?.didSelectDescriptionView!(gesture)
    }
}
