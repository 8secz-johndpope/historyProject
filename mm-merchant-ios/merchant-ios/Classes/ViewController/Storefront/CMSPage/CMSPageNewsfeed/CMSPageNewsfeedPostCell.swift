//
//  CMSPageNewsfeedPostCell.swift
//  MMDemoForLeslie_Swift4.0
//
//  Created by Leslie Zhang on 2018/3/28.
//  Copyright © 2018年 Leslie Zhang. All rights reserved.
//

import UIKit
import YYText

class CMSPageNewsfeedPostCell: BasePostCollectionViewCell {
    override func prepareForReuse() {
        super.prepareForReuse()
        
        self.contentImageView.image = nil
    }
    
    var post: Post?
    lazy var backgroundImageView:UIImageView = {
        let backgroundImageView = UIImageView()
        backgroundImageView.isUserInteractionEnabled = true
        backgroundImageView.layer.cornerRadius = 4.0
        backgroundImageView.layer.masksToBounds = true
        backgroundImageView.layer.borderColor = UIColor.primary2().cgColor
        backgroundImageView.layer.borderWidth = 1
        return backgroundImageView
    }()
    lazy var contentImageView:UIImageView = {
        let contentImageView = UIImageView()
        contentImageView.isUserInteractionEnabled = true
        return contentImageView
    }()
    lazy var contentLabel:YYLabel = {
        let contentLabel = YYLabel()
        contentLabel.font = UIFont.systemFont(ofSize: 12)
        contentLabel.textColor = UIColor.primary2()
        contentLabel.lineBreakMode = NSLineBreakMode.byTruncatingTail
        contentLabel.preferredMaxLayoutWidth = self.bounds.width - 20
        contentLabel.numberOfLines = 3
        contentLabel.tintColor = UIColor.hashtagColor()
        contentLabel.isUserInteractionEnabled = true
        return contentLabel
    }()
    lazy var iconImageView:AvatarView = {
        let iconImageView = AvatarView(imageStr: "", width: 25, height: 25, mode: .custom)
        iconImageView.sizeCustomAvatar = CGSize(width: 25, height: 25)
        iconImageView.isUserInteractionEnabled = true
        iconImageView.track_consoleTitle = "用户头像"
        return iconImageView
    }()
    lazy var nameLabel:UILabel = {
        let nameLabel = UILabel()
        nameLabel.font = UIFont.systemFont(ofSize: 12)
        nameLabel.isUserInteractionEnabled = true
        return nameLabel
    }()
    lazy var likeButton:UIButton = {
        let likeButton = UIButton()
        let normalImage = UIImage(named: "grey_heart")
        normalImage?.track_consoleTitle = "喜欢"
        likeButton.setImage(normalImage, for: .normal)
        let selectedImage = UIImage(named: "red_heart")
        selectedImage?.track_consoleTitle = "取消喜欢"
        likeButton.setImage(selectedImage, for: .selected)
        likeButton.titleLabel?.font = UIFont(name: Constants.Font.Normal, size: 12)
        likeButton.titleLabel?.textAlignment = .right
        likeButton.addTarget(self, action: #selector(self.tapAction), for: .touchDown)
        likeButton.titleEdgeInsets = UIEdgeInsets(top: 0, left: 0, bottom: 0, right: -4)
        likeButton.setTitleColor(UIColor.secondary3(), for: .normal)
        likeButton.sizeToFit()
        return likeButton
    }()
    lazy var statusImageView:UIImageView = {
        let statusImageView = UIImageView()
        statusImageView.image = UIImage(named: "multi_icon")
        statusImageView.sizeToFit()
        statusImageView.isHidden = true
        return statusImageView
    }()
    lazy var memberImageView:UIImageView = {
        let memberImageView = UIImageView()
        memberImageView.layer.cornerRadius = 5
        memberImageView.layer.masksToBounds = true
        memberImageView.image = UIImage(named: "curator_diamond")
        memberImageView.isHidden = true
        return memberImageView
    }()
    
    @objc  func tapAction()  {
        guard (LoginManager.getLoginState() == .validUser) else {
            LoginManager.goToLogin()
            return
        }
        
        if let post = post{
            var correlationKey = PostManager.correlationKeyOfPostLiked(post)
            if correlationKey.length > 0 {
                
            }else{
                correlationKey = Utils.UUID()
            }
            if self.likeButton.isSelected{
                if post.likeCount > 0{
                    self.likeButton.isUserInteractionEnabled = false
                    post.likeCount = post.likeCount - 1
                    PostManager.updateUserLikes(correlationKey,post: post, likeStatus: Constants.StatusID.deleted)
                    newsFeedServices(post: post,correlationKey: correlationKey, completion: {
                        self.likeButton.setTitle(NumberHelper.formatLikeAndCommentCount(post.likeCount), for: .normal)
                        self.likeButton.isSelected = false
                        self.likeButton.isUserInteractionEnabled = true
                        
                    }) {
                        PostManager.updateUserLikes(correlationKey,post: post, likeStatus: Constants.StatusID.deleted)
                        self.likeButton.isUserInteractionEnabled = true
                        Log.debug("Error")
                    }
                }
                
            }else{
                self.likeButton.isUserInteractionEnabled = false
                post.likeCount = post.likeCount + 1
                PostManager.updateUserLikes(correlationKey, post: post, likeStatus: Constants.StatusID.active)
                newsFeedServices(post: post,correlationKey: correlationKey, completion: {
                    self.likeButton.setTitle(NumberHelper.formatLikeAndCommentCount(post.likeCount), for: .normal)
                    self.likeButton.isSelected = true
                    self.likeButton.isUserInteractionEnabled = true
                }) {
                    PostManager.updateUserLikes(correlationKey, post: post, likeStatus: Constants.StatusID.active)
                    self.likeButton.isUserInteractionEnabled = true
                    Log.debug("Error")
                }
            }
        }
    }
    
    func newsFeedServices(post:Post,correlationKey: String, completion: (()->())?,  fail: (()->())? ) {
        NewsFeedService.likeNewsFeed(post.postId, correlationKey: correlationKey, completion: { (response) in
            if response.result.isSuccess && response.response?.statusCode == 200{
                if let result = response.result.value as? [String: Any], (result["Success"] as? Int) == 1{
                    if let callback = completion {
                        callback()
                    }
                } else {
                    if let callback = fail {
                        callback()
                    }
                }
            } else {
                if let callback = fail {
                    callback()
                }
            }
        })
    }
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        self.backgroundColor = UIColor.white
        self.contentView.addSubview(backgroundImageView)
        
        backgroundImageView.addSubview(contentImageView)
        backgroundImageView.addSubview(contentLabel)
        backgroundImageView.addSubview(iconImageView)
        backgroundImageView.addSubview(memberImageView)
        backgroundImageView.addSubview(nameLabel)
        backgroundImageView.addSubview(likeButton)
        backgroundImageView.addSubview(statusImageView)
        
        backgroundImageView.snp.makeConstraints { (make) in
            make.centerX.top.equalTo(self)
            make.width.equalTo(self.bounds.width)
            make.bottom.equalTo(self).offset(-MMMargin.CMS.imageToTitle)
        }
        contentImageView.snp.makeConstraints { (make) in
            make.top.left.right.equalTo(backgroundImageView)
            make.height.equalTo(backgroundImageView.snp.width)
        }
        contentLabel.snp.makeConstraints({ (make) in
            make.bottom.equalTo(iconImageView.snp.top).offset(-MMMargin.CMS.imageToTitle)
            make.width.equalTo(backgroundImageView).offset(-20)
            make.centerX.equalTo(backgroundImageView)
        })
        iconImageView.snp.makeConstraints({ (make) in
            make.left.equalTo(backgroundImageView).offset(10)
            make.bottom.equalTo(backgroundImageView).offset(-MMMargin.CMS.defultMargin)
            make.width.height.equalTo(20)
        })
        memberImageView.snp.makeConstraints { (make) in
            make.right.equalTo(iconImageView).offset(4)
            make.bottom.equalTo(iconImageView).offset(3)
            make.width.height.equalTo(10)
        }
        nameLabel.snp.makeConstraints({ (make) in
            make.left.equalTo(iconImageView.snp.right).offset(6)
            make.centerY.equalTo(iconImageView)
            make.width.equalTo(ScreenWidth/5)
        })
        likeButton.snp.makeConstraints({ (make) in
            make.centerY.equalTo(iconImageView)
            make.right.equalTo(backgroundImageView).offset(-10)
        })
        statusImageView.snp.makeConstraints { (make) in
            make.top.equalTo(backgroundImageView).offset(MMMargin.CMS.defultMargin)
            make.right.equalTo(backgroundImageView).offset(-MMMargin.CMS.defultMargin)
        }
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override func didClickOnHashTag(_ tag: String) {
        let hashTagValue = tag.replacingOccurrences(of: "#", with: "")
        Navigator.shared.dopen(Navigator.mymm.deeplink_dk_tag_tagName + Urls.encoded(str: hashTagValue))
    }
    
    override func didClickDescriptionText(_ post: Post) {
        if let cellModel = self.ssn_cellModel as? CMSPageNewsfeedPostCellModel {
            if let dataModel = cellModel.data {
                Navigator.shared.dopen(dataModel.link)
            }
        }
    }
    
    override func didClickURL(_ url: String) {
        Navigator.shared.dopen(url)
    }
    
    func setImageView(dataModel:CMSPageDataModel) {
        var category:ImageCategory = .banner
        if dataModel.dType == DataType.SKU {
            category = .product
        }else if dataModel.dType == DataType.POST {
            category = .post
        }else if dataModel.dType == DataType.MERCHANT {
            category = .merchant
        }
        if let imageUrl = dataModel.imageUrl {
            contentImageView.mm_setImageWithURL(ImageURLFactory.URLSize512(imageUrl, category: category), placeholderImage: UIImage(named: "brand_placeholder"), contentMode: .scaleAspectFill)
        }else{
            contentImageView.image = UIImage(named: "brand_placeholder")
        }
    }

    
    @objc override func ssn_onDisplay(_ tableView: UIScrollView, model: AnyObject,atIndexPath indexPath: IndexPath, reused: Bool) {
        if let cellModel: CMSPageNewsfeedPostCellModel = model as? CMSPageNewsfeedPostCellModel{
            
            if let dataModel = cellModel.data {
                post = dataModel.post
                
                //埋点需要
                self.track_visitId = dataModel.vid
                self.track_media = dataModel.videoUrl
                
                setImageView(dataModel: dataModel)
                
                if let post = dataModel.post {
                    self.formatDescription(self.contentLabel, post: post, fontSize: 12)
                    if let user = post.user{
                        self.nameLabel.text = user.displayName
                        self.iconImageView.setupViewByUser(user, isMerchant: (post.isMerchantIdentity.rawValue == 1))
                        if user.isCurator == 1 {
                            memberImageView.isHidden = false
                        } else {
                            memberImageView.isHidden = true
                        }
                    }
                    
                    if let merchant = post.merchant {
                        if post.isMerchantIdentity == .fromContentManager{
                              self.iconImageView.setupViewByMerchant(merchant)
                              self.nameLabel.text = merchant.merchantName.length > 0 ? merchant.merchantName : merchant.merchantCompanyName
                        }
                    }
                    
                    if post.likeCount > 0 {
                        likeButton.setTitle(NumberHelper.formatLikeAndCommentCount(post.likeCount), for: .normal)
                    } else {
                        likeButton.setTitle("0" , for: .normal)
                    }
                    likeButton.isSelected = post.isSelfLiked
                    contentImageView.whenTapped {
                        Navigator.shared.dopen(dataModel.link)
                    }
                    
                    if let userName = post.user?.userName{
                        let link = Navigator.mymm.deeplink_u_userName + userName
                        iconImageView.whenTapped {
                            Navigator.shared.dopen(link)
                        }
                        nameLabel.whenTapped {
                            Navigator.shared.dopen(link)
                        }
                    }
                    if let images = post.images{
                        if images.count > 1{
                            statusImageView.isHidden = false
                        }else{
                            statusImageView.isHidden = true
                        }
                    }else {
                        statusImageView.isHidden = true
                    }
                }
            }
        }
    }
}
