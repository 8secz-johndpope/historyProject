//
//  NewMerchantProfileHeaderView.swift
//  merchant-ios
//
//  Created by Quang Truong Dinh on 4/18/17.
//  Copyright © 2017 WWE & CO. All rights reserved.
//

import UIKit
import YYText

protocol MerchantProfileHeaderViewDelegate: NSObjectProtocol { //Prevent memory leak
    func didSelectButtonFollow(_ sender: UIButton, status: Bool)
    func didSelectFollowerList(_ gesture: UITapGestureRecognizer)
    func didSelectMerchantProfileView(_ sender: UIView)
}

class MerchantProfileHeaderView: UICollectionReusableView {
    static let MerchantProfileHeaderViewIdentifier = "MerchantProfileHeaderViewIdentifier"
    
    private var merchantInfoViewHeight = CGFloat(55)
    private var bottomViewHeight = CGFloat(52)
    private final let MerchantCoverImageRatio: CGFloat = 1242/860
    
    weak var delegate: MerchantProfileHeaderViewDelegate? //Prevent memory leak

    private var overlay                 = UIImageView()
    private var overlayBottom           = UIImageView()
    private var coverImageView          = UIImageView()
    private var merchantInfoView              = UIView()
    private var bottomView              = UIView()
    private var merchantAvatarButton          = UIButton()
    private var merchantAboutLabel      = UILabel()
    private var merchantArrrowButton          = UIButton()
    private var merchantNameLabel: YYLabel = {
        let label = YYLabel()
        label.font = UIFont.boldSystemFont(ofSize: 16)
        label.textVerticalAlignment = .center
        label.numberOfLines = 2
        return label
    } ()
    private var labelPost           = UILabel()
    private var labelFollower           = UILabel()
    private var followButton            = ButtonFollow()
    
    private var isFollowing = false
    private var merchant : Merchant?

    override init(frame: CGRect) {
        super.init(frame: frame)
        self.isUserInteractionEnabled = true
        topImageView.addGestureRecognizer(UITapGestureRecognizer(target: self, action: #selector(MerchantProfileHeaderView.viewTapGesture)))
        self.addSubview(topImageView)
        topImageView.snp.makeConstraints { (make) in
            make.edges.equalTo(self)
        }
        
        
//        self.addSubview(bottomView)
//        self.addSubview(coverImageView)
//        self.addSubview(merchantInfoView)
//        setupImageView()
//        setupMerchantInfoView()
//        setupBottomView()
        
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    let iconSizeWidth :CGFloat  = 30
    
    override func layoutSubviews() {
        super.layoutSubviews()
        
        let leftPadding: CGFloat = 17
        let horizontalPadding: CGFloat = 12
        let labelHeight: CGFloat = 22

        merchantAvatarButton.frame = CGRect(x: leftPadding, y: -leftPadding, width: 72, height: 72)
        merchantAvatarButton.round()
        merchantArrrowButton.frame = CGRect(x: merchantInfoView.width - 28, y: (merchantInfoView.height - 26)/2, width: 26, height: 26)
        merchantArrrowButton.imageEdgeInsets = UIEdgeInsets(top: 8, left: 10, bottom: 8, right: 10)
        merchantAboutLabel.frame = CGRect(x: merchantArrrowButton.frame.minX - 25, y: (merchantInfoView.height - 26)/2, width: 30, height: 26)

        merchantNameLabel.frame = CGRect(x: merchantAvatarButton.frame.maxX + horizontalPadding, y: 7, width: merchantAboutLabel.frame.minX - merchantAvatarButton.frame.maxX - 15, height: labelHeight * 2)
        
        var rect = labelPost.frame
        rect.origin.x = leftPadding
        rect.size.height = 30
        rect.origin.y = (bottomView.frame.size.height - rect.size.height) / 2
        rect.size.width = StringHelper.getTextWidth(labelPost.text ?? "", height: labelPost.frame.sizeHeight, font: labelPost.font)
        labelPost.frame = rect
        
        rect = labelFollower.frame
        rect.origin.x = leftPadding
        rect.size.height = 30
        rect.origin.y = (bottomView.frame.size.height - rect.size.height) / 2
        rect.size.width = StringHelper.getTextWidth(labelFollower.text!, height: labelFollower.frame.sizeHeight, font: labelFollower.font)
        labelFollower.frame = rect

        rect = followButton.frame
        rect.size.height = ButtonFollow.ButtonFollowSize.height
        rect.size.width = ButtonFollow.ButtonFollowSize.width
        rect.origin.x = bottomView.width - rect.size.width - 15
        rect.origin.y = (bottomView.frame.size.height - rect.size.height) / 2
        followButton.frame = rect
        
        let height = CGFloat(100)
        overlay.frame = CGRect(x: 0, y: 0, width: self.frame.size.width, height: height)
        
        rect = overlayBottom.frame
        rect.originX = 0
        rect.size.width = self.frame.width
        rect.size.height = height
        rect.originY = coverImageView.frame.height - rect.size.height
        overlayBottom.frame = rect
    }
    
    // MARK: Views
    func setupImageView() {
        coverImageView.frame = CGRect(x: 0, y: 0, width: self.bounds.sizeWidth, height: self.bounds.sizeWidth / MerchantCoverImageRatio)
        
        overlay.image = UIImage(named: "overlay")
        coverImageView.addSubview(overlay)
        
        overlayBottom.image = UIImage(named: "overlay_bottom")
        coverImageView.addSubview(overlayBottom)
    }
    
    func setupMerchantInfoView(){
        merchantInfoView.frame = CGRect(x: 0, y: self.bounds.maxY - bottomViewHeight - merchantInfoViewHeight,  width: self.frame.width, height: merchantInfoViewHeight)
        merchantInfoView.backgroundColor = UIColor.white
        
        merchantInfoView.addSubview(merchantNameLabel)
        
        merchantAvatarButton.viewBorder(UIColor.secondary1(), width: 1)
        merchantAvatarButton.backgroundColor = UIColor.white
        merchantAvatarButton.imageView?.contentMode = .scaleAspectFit
        merchantInfoView.addSubview(merchantAvatarButton)
        
        merchantAboutLabel.formatSize(12)
        merchantAboutLabel.textAlignment = .right
        merchantAboutLabel.textColor = UIColor.secondary7()
        merchantAboutLabel.text =  String.localize("LB_CA_MERCHANT_ABOUT")
        merchantInfoView.addSubview(merchantAboutLabel)
        
        let rightButton = UIButton()
        rightButton.backgroundColor = UIColor.clear
        rightButton.setTitleColor(UIColor.white, for: UIControlState())
        rightButton.addTarget(self, action: #selector(MerchantProfileHeaderView.arrowButtonTapped), for: .touchUpInside)
        rightButton.setImage(UIImage(named: "icon_arrow"), for: UIControlState())
        merchantArrrowButton = rightButton
        merchantInfoView.addSubview(rightButton)
    }
    
    func setupBottomView() {
        bottomView.frame = CGRect(x: 0, y: self.bounds.maxY - bottomViewHeight,  width: self.frame.width, height: bottomViewHeight)
        bottomView.backgroundColor = UIColor.white
        
        labelPost.text = String.localize("LB_AC_POST")
        labelPost.formatSize(13)
        labelPost.textColor = UIColor.secondary7()
        labelPost.isUserInteractionEnabled = true
        labelPost.isHidden = true
        labelPost.addGestureRecognizer(UITapGestureRecognizer(target: self, action: #selector(MerchantProfileHeaderView.onHandlePost)))
        
        bottomView.addSubview(labelPost)
        
        labelFollower.text = String.localize("LB_CA_FOLLOWER")
        labelFollower.formatSize(14)
        labelFollower.textColor = UIColor.secondary3()
        labelFollower.isUserInteractionEnabled = true
        let gesture = UITapGestureRecognizer(target: self, action: #selector(MerchantProfileHeaderView.onHandleFollower))
        labelFollower.addGestureRecognizer(gesture)
        
        bottomView.addSubview(labelFollower)
        
        followButton.setTitle(String.localize("LB_CA_FOLLOW"), for: UIControlState())
        followButton.isUserInteractionEnabled = true
        followButton.titleLabel?.formatSize(13)
        followButton.setTitleColor(UIColor.secondary7(), for: UIControlState())
        followButton.addTarget(self, action: #selector(MerchantProfileHeaderView.onHandleFollow), for: UIControlEvents.touchUpInside)
        bottomView.addSubview(followButton)
        
        
        let lineView = UIView()
        let margin = CGFloat(0)
        let height = CGFloat(1)
        lineView.frame = CGRect(x: margin, y: bottomView.bounds.maxY - height, width: bottomView.frame.sizeWidth - 2*margin, height: height)
        lineView.backgroundColor = UIColor.primary2()
        
        bottomView.addSubview(lineView)
        
        self.bringSubview(toFront: bottomView)
        
        self.layoutSubviews()
    }
    
    func removeBottomView(){
        //bottomViewHeight = 0
        bottomView.removeFromSuperview()
        //coverImageView.frame = CGRect(x: 0, y: 0, width: self.bounds.sizeWidth, height: self.bounds.sizeWidth / MerchantCoverImageRatio)
        merchantInfoView.frame = CGRect(x: 0, y: coverImageView.frame.maxY,  width: self.frame.width, height: merchantInfoViewHeight)
        
    }
    
    func setupButtonFollow(_ status:Bool) {
        followButton.setFollowButtonState(status)
    }
    
    func setCoverImage(_ key : String, imageCategory : ImageCategory){
        if self.frame.height > 0 {
            coverImageView.mm_setImageWithURL(HeaderMyProfileCell.getCoverImageUrl(key, imageCategory: imageCategory, width: self.width), placeholderImage: UIImage(named: "default_cover"), contentMode: .scaleAspectFill)
        }
    }
    
    func loadDataWithMerchant(_ merchant: Merchant, isFollowing: Bool) {
        self.merchant = merchant
        merchantAvatarButton.mm_setImageWithURL(ImageURLFactory.URLSize256(merchant.largeLogoImage, category: .merchant), forState: UIControlState(), placeholderImage: nil)
        
        merchantNameLabel.text = merchant.merchantName
        
        let followerCountText = NumberHelper.getNumberMeasurementString(merchant.followerCount)
        let followerText = String(format: "%@ %@", followerCountText, String.localize("LB_CA_FOLLOWER"))
        
        var myMutableString = NSMutableAttributedString()
        
        var name = Constants.iOS8Font.Normal
        if #available(iOS 9.0, *) {
            name = Constants.Font.Normal
        }

        if let font = UIFont(name: name, size: 14) {
            myMutableString = NSMutableAttributedString(string: followerText as String, attributes: [NSAttributedStringKey.font:font])
            myMutableString.addAttribute(NSAttributedStringKey.foregroundColor, value: UIColor.secondary2(), range: NSRange(location:0,length:followerCountText.count))
        }
        
        labelFollower.attributedText = myMutableString
        
        labelPost.text = String(format: "%@ %@", NumberHelper.getNumberMeasurementString(0), String.localize("LB_AC_POST"))
        
        setCoverImage(merchant.profileBannerImage, imageCategory: .merchant)
        
        self.isFollowing = isFollowing
        
        bottomView.bringSubview(toFront: labelFollower)
        if merchant.isLoading {
            followButton.showLoading()
            followButton.setTitle("", for: UIControlState())
        }else {
            followButton.hideLoading()
            setupButtonFollow(isFollowing)
        }
        layoutSubviews()
        
        topImageView.merchant = merchant
        topImageView.follow = isFollowing
    }
    
    func loadDataWithBrand(_ brand: Brand) {
        merchantAvatarButton.mm_setImageWithURL(ImageURLFactory.URLSize256(brand.largeLogoImage, category: .brand), forState: UIControlState(), placeholderImage: nil)
        setCoverImage(brand.profileBannerImage, imageCategory: .brand)
        merchantNameLabel.text = brand.brandName
        layoutSubviews()
    }
    
    // MARK: - Action
    @objc func followImageTapped(_ tapGesture: UITapGestureRecognizer){
        self.followButton.sendActions(for: .touchUpInside)
    }
    
    @objc func onHandleFollow(_ sender: UIButton) {
        self.delegate?.didSelectButtonFollow(sender, status:isFollowing)
    }

    @objc func onHandleFollower(_ gesture: UITapGestureRecognizer){
        if let data = self.merchant {
            if data.followerCount > 0 {
                self.delegate?.didSelectFollowerList(gesture)
            }
        }
    }
    
    @objc func onHandlePost(_ gesture: UITapGestureRecognizer){
        
    }
    
    @objc func arrowButtonTapped(_ sender: UIButton) {
        delegate?.didSelectMerchantProfileView(sender)
    }
    
    @objc func viewTapGesture(_ gesture: UITapGestureRecognizer) {
        if let tappedView = gesture.view{
            delegate?.didSelectMerchantProfileView(tappedView)
        }
    }
    
    lazy var topImageView:BrandAndMerchantHeadView = {
        let topImageView = BrandAndMerchantHeadView()
        topImageView.attentionButton.addTarget(self, action: #selector(MerchantProfileHeaderView.onHandleFollow), for: UIControlEvents.touchUpInside)
         let gesture = UITapGestureRecognizer(target: self, action: #selector(MerchantProfileHeaderView.onHandleFollower))
         topImageView.attentionLabel.addGestureRecognizer(gesture)
        return topImageView
    }()
}
