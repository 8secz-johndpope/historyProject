//
//  MyFeedCollectionViewCell.swift
//  merchant-ios
//
//  Created by Vu Dinh Trung on 4/23/16.
//  Copyright © 2016 WWE & CO. All rights reserved.
//

import UIKit
import PromiseKit
import ObjectMapper
import Kingfisher
import YYText

protocol SimpleFeedCollectionViewCellDelegate: NSObjectProtocol {
    func didSelectUser(_ user: User)
    func didClickedLike(_ post: Post, cell: UICollectionViewCell)
    func didSelectMerchant(_ merchant: Merchant)
    func didClickOnHashTag(_ hashTag: String)
    func didClickDescriptionText(_ post: Post)
    func didClickOnURL(_ url: String)
    func didClickOnPostImage(_ post: Post)
}

class SimpleFeedCollectionViewCell: BasePostCollectionViewCell {
    
    static let CellIdentifier = "SimpleFeedCollectionViewCell"
    static var descriptionFont : UIFont = UIFont.systemFont(ofSize: 12)
    static let BottomViewHeight: CGFloat = 25 + 8
    static let HeightUserName: CGFloat = 25
    static let PaddingLeftRight: CGFloat = 8
    static let TextPaddingTop: CGFloat = 14
    static let DescriptionMaxHeight: CGFloat = 45
    private static let SizelikeButton = CGSize(width: 56, height: SimpleFeedCollectionViewCell.HeightUserName)
    
    private static let AvatarSize = CGSize(width: 25, height: 25)
    var userNameLabel = UILabel()
    var avatarView = AvatarView(imageStr: "", width: AvatarSize.width, height: AvatarSize.height, mode: .custom)
    var diamondImageView = UIImageView()
    var postImageView = UIImageView()
    var descriptionLabel = YYLabel()
    var lineDescription = UIView()
    var descriptionViewContainer = UIView()
    var likeButton = UIButton(type: .custom)
    var bottomView = UIView()
    weak var delegate: SimpleFeedCollectionViewCellDelegate?
    var thisPost = Post()
    
    lazy var figureImageView:UIImageView = {
        let figureImageView = UIImageView()
        figureImageView.image = UIImage(named: "multi icon")
        figureImageView.isHidden = true
        return figureImageView
    }()
    
    override init(frame: CGRect) {
        super.init(frame: frame)
		backgroundColor = UIColor.secondary5()
        
        avatarView.sizeCustomAvatar = CGSize(width: SimpleFeedCollectionViewCell.AvatarSize.width, height: SimpleFeedCollectionViewCell.AvatarSize.height)
        avatarView.addGestureRecognizer(UITapGestureRecognizer(target: self, action: #selector(self.openAuthorProfile)))
        avatarView.isUserInteractionEnabled = true
        
        SimpleFeedCollectionViewCell.descriptionFont = UIFont.fontWithSize(12, isBold: false)
        descriptionLabel.textColor = UIColor.secondary2()
        descriptionLabel.text = ""
        descriptionLabel.lineBreakMode = NSLineBreakMode.byTruncatingTail
        descriptionLabel.numberOfLines = 3
        
        descriptionLabel.tintColor = UIColor.hashtagColor()
        descriptionLabel.isUserInteractionEnabled = true

        postImageView.contentMode = .scaleAspectFit
        postImageView.isUserInteractionEnabled = true
        postImageView.addGestureRecognizer(UITapGestureRecognizer(target: self, action: #selector(self.didClickPostImage)))
        self.addSubview(postImageView)
        self.addSubview(descriptionLabel)
        
        self.addSubview(bottomView)
        bottomView.addSubview(avatarView)
        
        diamondImageView.image = UIImage(named: "curator_diamond")
        diamondImageView.isHidden = true
        bottomView.addSubview(diamondImageView)
        if let likeImage = UIImage(named: "grey_heart") {
            likeButton.setImage(likeImage, for: .normal)
        }
        if let likedImage = UIImage(named: "red_heart") {
            likeButton.setImage(likedImage, for: .selected)
        }
        likeButton.setTitleColor(UIColor.secondary3(), for: .normal)
        //likeButton.contentHorizontalAlignment = .Right
        likeButton.titleLabel?.font = UIFont(name: Constants.Font.Normal, size: 12)
        likeButton.titleLabel?.textAlignment = .right
        likeButton.addTarget(self, action: #selector(self.didClickLikeButton), for: .touchDown)
        //likeButton.imageEdgeInsets = UIEdgeInsets(top: 0, left: 0, bottom: 0, right: 4)
        likeButton.titleEdgeInsets = UIEdgeInsets(top: 0, left: 0, bottom: 0, right: -4)
        
        bottomView.addSubview(likeButton)
        
        if let fontNameUser = UIFont(name: Constants.Font.Bold, size: 13) {
            userNameLabel.font = fontNameUser
        } else {
            userNameLabel.formatSizeBold(13)
        }
        userNameLabel.textColor = UIColor.black
        userNameLabel.textAlignment = .left
        userNameLabel.lineBreakMode = NSLineBreakMode.byTruncatingTail
        userNameLabel.addGestureRecognizer(UITapGestureRecognizer(target: self, action: #selector(self.openAuthorProfile)))
        userNameLabel.isUserInteractionEnabled = true
        bottomView.addSubview(userNameLabel)
        
        self.clipsToBounds = true
        postImageView.addSubview(figureImageView)
    }
    
    func setupDataByNewfeed(_ newsfeed: Post, isLiked: Bool = false) -> Void {
        self.thisPost = newsfeed
        if let author = newsfeed.user {
            self.userNameLabel.text = author.displayName
            
            self.avatarView.setupViewByUser(author, isMerchant: (newsfeed.isMerchantIdentity.rawValue == 1))
            
            self.diamondImageView.isHidden = !(newsfeed.isMerchantIdentity != .fromContentManager && author.isCurator == 1)
        }
        
        if let merchant = newsfeed.merchant {
            if newsfeed.isMerchantIdentity == .fromContentManager{
                self.avatarView.setupViewByMerchant(merchant)
                self.userNameLabel.text = merchant.merchantName.length > 0 ? merchant.merchantName : merchant.merchantCompanyName
            }
        }
        
        if newsfeed.postImage == "0" || newsfeed.postImage == "" {
            if let image = KingfisherManager.shared.cache.retrieveImageInDiskCache(forKey: newsfeed.correlationKey) {
                self.postImageView.image = image
            }else if let image = newsfeed.pendingUploadImage {
                self.postImageView.image = image
            }else {
                self.postImageView.image = UIImage(named: "postPlaceholder")
            }
        }else {
            self.postImageView.mm_setImageWithURL(ImageURLFactory.URLSize1000(newsfeed.postImage, category: .post), placeholderImage : UIImage(named: "postPlaceholder"))
        }
        
        self.postImageView.contentMode = .scaleAspectFill
        self.likeButton.contentMode = .scaleAspectFill
        self.likeButton.isSelected = isLiked
        
        if thisPost.userSource != nil {
            setUserShareDescription(thisPost.userSource)
        } else {
            self.setDescription(newsfeed.postText)
        }
        
        if newsfeed.likeCount > 0 {
            likeButton.setTitle(NumberHelper.formatLikeAndCommentCount(newsfeed.likeCount), for: .normal)
        } else {
            likeButton.setTitle("0" , for: .normal)
        }
        if let images = newsfeed.images{
            if images.count > 1{
                figureImageView.isHidden = false
            }else{
                figureImageView.isHidden = true
            }
        }else {
            figureImageView.isHidden = true
        }
    }
    
    func setUserShareDescription(_ userSource: User?) {
        if let user = userSource {
            
            let strings = String.localize("LB_CA_POST_SHARE_WHOSE_POST").components(separatedBy: "{0}")
            var userSourceSubText1 = ""
            var userSourceSubText2 = ""
            if strings.count > 1 {
                userSourceSubText1 = strings[0]
                userSourceSubText2 = strings[1]
            }
            
            //Make sure font is not null
            if let fontRegular = UIFont(name: "PingFangSC-Regular", size: 12), let fontMedium = UIFont(name: Constants.Font.Bold, size: 12) {
                
                let fontRegularAttribute = [
                    NSAttributedStringKey.font : fontRegular,
                    NSAttributedStringKey.foregroundColor : UIColor.secondary2()
                ]
                let fontMediumAttribute = [
                    NSAttributedStringKey.font : fontMedium,
                    NSAttributedStringKey.foregroundColor : UIColor.secondary2()
                ]
                
                let attributedSubText1 = NSMutableAttributedString(string:userSourceSubText1, attributes: fontRegularAttribute)
                let attributedDisplayName = NSMutableAttributedString(string:" \(user.displayName)", attributes: fontMediumAttribute)
                let attributedSubText2 = NSMutableAttributedString(string:" \(userSourceSubText2)", attributes: fontRegularAttribute)
                
                attributedSubText1.append(attributedDisplayName)
                attributedSubText1.append(attributedSubText2)
                self.descriptionLabel.attributedText = attributedSubText1
            } else {
                self.descriptionLabel.text = userSourceSubText1 + " " + user.displayName + " " + userSourceSubText2
            }
        }
    }
    
    override func layoutSubviews() {
        super.layoutSubviews()
        let paddingTopView: CGFloat = 0
        
        let sizeDiamond = CGSize(width: 12, height: 12)
        let paddingLeftRight = SimpleFeedCollectionViewCell.PaddingLeftRight
        postImageView.frame = CGRect(x:0, y: 0, width: self.width, height: self.width)
        descriptionLabel.frame = CGRect(x:paddingLeftRight, y: postImageView.frame.maxY, width: self.width - (2 * paddingLeftRight), height: self.height - SimpleFeedCollectionViewCell.BottomViewHeight - postImageView.frame.maxY)
        bottomView.frame = CGRect(x:0, y: descriptionLabel.frame.maxY, width: self.width, height: SimpleFeedCollectionViewCell.BottomViewHeight)
        likeButton.sizeToFit()
        let widthLikeButton = min(likeButton.frame.sizeWidth, SimpleFeedCollectionViewCell.SizelikeButton.width)
        likeButton.frame = CGRect(x:bottomView.width - paddingLeftRight - widthLikeButton, y: paddingTopView, width: widthLikeButton, height: SimpleFeedCollectionViewCell.SizelikeButton.height)
        avatarView.frame = CGRect(x:paddingLeftRight, y: paddingTopView, width: SimpleFeedCollectionViewCell.AvatarSize.width, height: SimpleFeedCollectionViewCell.AvatarSize.width)
        diamondImageView.frame = CGRect(x: avatarView.frame.maxX - sizeDiamond.width + 4 , y: avatarView.frame.maxY - sizeDiamond.height + 4, width: sizeDiamond.width, height: sizeDiamond.height)
        userNameLabel.frame = CGRect(x:avatarView.frame.maxX + 5, y: paddingTopView, width: likeButton.frame.originX - (avatarView.frame.maxX + 5), height: SimpleFeedCollectionViewCell.HeightUserName)
        figureImageView.frame = CGRect(x:self.width - 24 - 8,y: self.width - 24 - 8,width: 24,height: 24)
    }
	
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
	
    func setDescription(_ description: String?){
        self.descriptionLabel.text = description
        self.formatDescription(self.descriptionLabel, post: self.thisPost, fontSize: 12)
        self.layoutSubviews()
    }
    class func getCellWidth() -> CGFloat {
        let width = (UIScreen.main.bounds.width  - PostManager.NewsFeedLineSpacing * 3) / 2
        return width
    }

    class func getAnnotationHeight(text: String) -> CGFloat {
        if text.length == 0 {
            return SimpleFeedCollectionViewCell.BottomViewHeight + TextPaddingTop
        }
        let width = (UIScreen.main.bounds.width  - PostManager.NewsFeedLineSpacing * 3) / 2
        var height = StringHelper.heightForText(text, width: width - SimpleFeedCollectionViewCell.PaddingLeftRight * 2, font: SimpleFeedCollectionViewCell.descriptionFont)
        if height > SimpleFeedCollectionViewCell.DescriptionMaxHeight {
            height = SimpleFeedCollectionViewCell.DescriptionMaxHeight
        }
        return SimpleFeedCollectionViewCell.BottomViewHeight + height + TextPaddingTop * 2
    }
    
    private static var CellHeightCache = [String: CGFloat]()
    class func getHeightForCell(_ text: String, userSourceName: String?) -> CGFloat {
        let cacheKey = "\(text)#\(String(describing: userSourceName))"
        if let height = CellHeightCache[cacheKey] {
            return height
        }
        
        let photoWidth = (UIScreen.main.bounds.width  - PostManager.NewsFeedLineSpacing * 3) / 2
        if text.length == 0 && userSourceName == nil {
            return  photoWidth + SimpleFeedCollectionViewCell.BottomViewHeight + TextPaddingTop
        }
       
        //Remove certain app url
        var postDescription = ""
        if text.isEmpty {
            postDescription = text
        }else{
            postDescription = BasePostCollectionViewCell.getTextByRemovingAppUrls(text)
        }
        
        var height: CGFloat = 0
        if let userSourceName = userSourceName, userSourceName.length > 0 {
            height = StringHelper.heightForText(userSourceName, width: photoWidth - SimpleFeedCollectionViewCell.PaddingLeftRight * 2, font: SimpleFeedCollectionViewCell.descriptionFont)
        } else {
            height = StringHelper.heightForText(postDescription, width: photoWidth - SimpleFeedCollectionViewCell.PaddingLeftRight * 2, font: SimpleFeedCollectionViewCell.descriptionFont)
        }
        
        if height > SimpleFeedCollectionViewCell.DescriptionMaxHeight {
            height = SimpleFeedCollectionViewCell.DescriptionMaxHeight
        }
        
        let finalHeight = photoWidth + SimpleFeedCollectionViewCell.BottomViewHeight + height + TextPaddingTop * 2
        CellHeightCache[cacheKey] = finalHeight
        while CellHeightCache.count > 1000 {
            _ = CellHeightCache.popFirst() // randomly remove items inside the cache
        }
        return finalHeight
        
    }
    
    @objc func openAuthorProfile() {
        if( thisPost.isMerchantIdentity.rawValue == MerchantIdentity.fromContentManager.rawValue){
            if let merchant = thisPost.merchant {
                thisPost.merchant?.merchantId = thisPost.merchantId
                self.delegate?.didSelectMerchant(merchant)
            }
        } else if let user = thisPost.user {
            self.delegate?.didSelectUser(user)
        }
    }
    
    @objc func didClickPostImage(sender: UIView) {
        thisPost.analyticsImpressionKey = self.analyticsImpressionKey!
        thisPost.analyticsViewKey = self.analyticsViewKey!
        self.delegate?.didClickOnPostImage(thisPost)
    }
    
    @objc func didClickLikeButton(sender: UIButton) {
        //record action
        let sourceRef = sender.isSelected == true ? "Unlike":"Like"
        sender.analyticsViewKey = self.analyticsViewKey //make sure view key is copied
        sender.analyticsImpressionKey = self.analyticsImpressionKey //make sure impression key is copied
        sender.recordAction(.Tap, sourceRef: sourceRef, sourceType: .Button, targetRef: "\(self.thisPost.postId)", targetType: .Post)
        
        if !sender.isSelected {
            var wishListButton : ButtonRedDot?
            if let viewController = Utils.findActiveController() as? MmViewController {
                wishListButton = viewController.buttonWishlist
            }
            let wishListAnimation = WishListAnimation(heartImage: sender.imageView!, redDotButton: wishListButton)
            wishListAnimation.showAnimation(completion: {
                
            })
        }
        self.delegate?.didClickedLike(thisPost, cell: self)
    }
    
//    override func applyLayoutAttributes(layoutAttributes: UICollectionViewLayoutAttributes) {
//        super.applyLayoutAttributes(layoutAttributes)
//        if let attributes = layoutAttributes as? PinterestLayoutAttributes {
//            imageViewHeightLayoutConstraint.constant = attributes.photoHeight
//        }
//    }
    
    //MARK: - Analytics
    func recordImpressionAtIndexPath(_ indexPath: IndexPath, positionLocation: String, positionComponent: String = "PostListing", viewKey: String){
        self.analyticsViewKey = viewKey
        if let viewKey = self.analyticsViewKey{
            var impressionDisplayName = self.thisPost.postText
            if impressionDisplayName.length > 50 {
                let myNSString = impressionDisplayName as NSString
                impressionDisplayName = myNSString.substring(with: NSRange(location: 0, length: 50))
            }
            
            var merchantName = ""
            var merchantId = ""
            if let merchant = self.thisPost.merchant {
                merchantId = "\(merchant.merchantId)"
                if merchant.merchantName.length > 0 {
                    merchantName = merchant.merchantName
                }
            }
            var authorType = self.thisPost.user?.userTypeString()
//            var referrerType = authorType
            var impressionRef = ""
            var referrerRef = ""
            if let userSource = thisPost.userSource {
                impressionRef = "User"
                referrerRef = userSource.userKey
                authorType = userSource.userTypeString()
            } else {
                impressionRef = "\(self.thisPost.postId)"
//                referrerType = ""
            }
            self.initAnalytics(withViewKey: viewKey, impressionKey: AnalyticsManager.sharedManager.recordImpression(self.thisPost.user?.userKey,
                                                                                                                    authorType: authorType,
                                                                                                                    impressionRef: impressionRef,
                                                                                                                    impressionType: "Post",
                                                                                                                    impressionDisplayName: impressionDisplayName,
                                                                                                                    parentRef: merchantId,
                                                                                                                    parentType: merchantName,
                                                                                                                    positionComponent: positionComponent,
                                                                                                                    positionIndex: indexPath.row + 1,
                                                                                                                    positionLocation: positionLocation,
                                                                                                                    referrerRef:referrerRef,
                                                                                                                    viewKey: viewKey))
        }
    }
    
    override func didClickOnHashTag(_ tag: String) {
        self.delegate?.didClickOnHashTag(tag)
    }
    
    override func didClickDescriptionText(_ post: Post) {
        self.delegate?.didClickDescriptionText(thisPost)
    }

    override func didClickURL(_ url: String) {
        self.delegate?.didClickOnURL(url)
    }
}
