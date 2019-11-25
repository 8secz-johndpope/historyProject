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


struct Margin {
    static let top: CGFloat = 8.0
    static let bottom: CGFloat = 7.0
    static let left: CGFloat = 15.0
    static let right: CGFloat = 15.0
    static let TopBottomOfDescription: CGFloat = 15.0
}

struct MarginUserName {
    static let left: CGFloat = 4.0
    static let right: CGFloat = 64.0
}

struct MarginTimeLabel {
    static let top: CGFloat = 14.0
    static let bottom: CGFloat = 9.0
}

struct MarginCommentView {
    static let left: CGFloat = 6.0
    static let right: CGFloat = 6.0
}

struct FrameCountButton {
    static let Marginleft: CGFloat = 10.0
    static let width: CGFloat = 55.0
    
}

struct SizeBtnOption {
    static let Width: CGFloat = 30
    static let height: CGFloat = 40
}

struct SizeDiamonIcon {
    static let Width: CGFloat = 14
    static let Height: CGFloat = 14
    static let Margin: CGFloat = 3
}
enum EnumTag:Int {
    case productTag = 100
}

let CollectCellId: String = "CollectCell"

struct ViewDefaultHeight {
    static let HeightUserCV: CGFloat = 32.0
    static let HeightBrandCV: CGFloat = 36.0
    static let HeightLabel: CGFloat = 21.0
    static let DescriptionLabelMaxHeight: CGFloat = 40.0
    static let HeightLine: CGFloat = 1
    static let HeightpostImageView: CGFloat = Constants.ScreenSize.SCREEN_WIDTH
    static let HeightActionView: CGFloat = 56.0
    static let HeightHeaderView: CGFloat = 60.0
    static let HeightTagMerchant: CGFloat = 18.0
}
protocol CheckoutDelegate: NSObjectProtocol { //Fix memory leak
    func doActionBuy(_ isSwipe : Bool, index: Int)
}
protocol MyFeedCollectionViewCellDelegate: NSObjectProtocol {
    func didSelectUser(_ user: User)
    func didSelectBrand(_ brand: Brand)
    func didSelectMerchant(_ merchant: Merchant)
    func didSelectSku(_ sku: Sku, post: Post, referrerUserKey: String)
    
    func collectionViewSelected(_ collectionViewItem : Int)
    func collectionViewSelectedExpandDescriptionView(_ collectionViewItem : Int)
	
    func didClickDescriptionText(_ post: Post)
    func didClickedShare(_ post: Post)
    func didClickedComment(_ post: Post)
    func didClickUserProfile(_ user: User)
    func didClickedLike(_ post: Post, cell: UICollectionViewCell)
    func didClickedTag(_ post: Post)
   
    func didClickedFollowUser(_ user: User, isGoingToFollow: Bool)
    func didClickedFollowMerchant(_ merchant: Merchant, isGoingToFollow: Bool)
    func didClickOnHashTag(_ hashTag: String)
    func didClickOnURL(_ url: String)
}

class MyFeedCollectionViewCell: BasePostCollectionViewCell, TagViewDelegate, BrandCollectionDelegate {
    private final let HeightLabel: CGFloat = 21.0
    
    private final let SizeImageExpand: CGFloat = 24.0
	
    private final let PaddingAvatarImageView: CGFloat = 10
    
    var heightForCell: CGFloat = 150.0
    var MarginLeftList: CGFloat = 60.0
    var heightSuggestView: CGFloat = 0.0
    var heightpostImageView: CGFloat = Constants.ScreenSize.SCREEN_WIDTH
    var heightBrandCV: CGFloat = ViewDefaultHeight.HeightBrandCV
    var heightUserCV: CGFloat = ViewDefaultHeight.HeightUserCV
    var heightLabel: CGFloat = ViewDefaultHeight.HeightLabel
    var heightLine: CGFloat = ViewDefaultHeight.HeightLine
    var headerView = UIView()
    var topLineCommentView = UIView()
    //Repost
    var labelNameUser = UILabel()
    var timeLabel = UILabel()
    //
    //var avatarView = AvatarView(imageStr: "", isCurator: 0)
    var avatarView = AvatarView(imageStr: "", width: 44.0, height: 44.0, mode: .custom)
    
    
    var merchantBahalfButton = UIButton()
    var merchantBehalfName = UILabel()
    //--------------end-header--------------//
    
    var postImageView = UIImageView()
    weak var activityIndicator: MMActivityIndicator?
    var descriptionLabel = YYLabel()

    
    var descriptionViewContainer = UIView()
    var actionView : ActionViewOnPost?
    
    var line = UIView()
    var diamondImageView = UIImageView()
    
    var shareLabel = UILabel()
    
    var listBrandView = UIView()
    var labelTextBrand = UILabel()

    var listUserView = UIView()
    
    var price: Float = 0
    var isExpand = false
    var thisPost = Post()
    
    weak var feedCollectionViewCellDelegate: MyFeedCollectionViewCellDelegate?
    weak var checkoutDelegate : CheckoutDelegate?
	var tagLayerView = UIView()
	
    let badgePadding: CGFloat = 2.0
    var userSourceSubText1 = ""
    var userSourceSubText2 = ""
	
	var topBorderView = UIView()
    private let TopBorderViewHeight: CGFloat = 5.0
    static let MyFeedCellId = "MyFeedCellId"
    
    var followButton = ButtonFollow()
    
    var showTopBorder = false
    
    override init(frame: CGRect) {
        super.init(frame: frame)
		backgroundColor = UIColor.white
        topBorderView = UIView(frame: CGRect(x: 0, y: 0, width: frame.sizeWidth, height: TopBorderViewHeight))
        topBorderView.backgroundColor = UIColor.primary2()
        topBorderView.isHidden = true
        addSubview(topBorderView)
        
        headerView.backgroundColor = UIColor.white
        avatarView.sizeCustomAvatar = CGSize(width: 36, height: 36)
        avatarView.addGestureRecognizer(UITapGestureRecognizer(target: self, action: #selector(self.openAuthorProfile)))
        headerView.addSubview(avatarView)
        
        diamondImageView.image = UIImage(named: "curator_diamond")
        diamondImageView.isHidden = true
        headerView.addSubview(diamondImageView)
        
        labelNameUser.text = ""
        
        if let fontNameUser = UIFont(name: Constants.Font.Bold, size: 15) {
            labelNameUser.font = fontNameUser
        } else {
            labelNameUser.formatSizeBold(15)
        }
        labelNameUser.textColor = UIColor.black
        labelNameUser.textAlignment = .left
        labelNameUser.lineBreakMode = NSLineBreakMode.byTruncatingTail
        labelNameUser.addGestureRecognizer(UITapGestureRecognizer(target: self, action: #selector(self.openAuthorProfile)))
        labelNameUser.isUserInteractionEnabled = true

        timeLabel.text = ""
        if let fontNameUserSub = UIFont(name: "PingFangSC-Regular", size: 13) {
            timeLabel.font = fontNameUserSub
        } else {
            timeLabel.formatSize(13)
        }
        timeLabel.textColor = UIColor.secondary3()
        timeLabel.numberOfLines = 1
        timeLabel.textAlignment = .left
        timeLabel.isUserInteractionEnabled = true
        timeLabel.lineBreakMode = NSLineBreakMode.byTruncatingTail
        
        headerView.backgroundColor = UIColor.white
        headerView.addSubview(labelNameUser)
        headerView.addSubview(timeLabel)
        let strings = String.localize("LB_CA_POST_SHARE_WHOSE_POST").components(separatedBy: "{0}")
        if strings.count > 1 {
            userSourceSubText1 = strings[0]
            userSourceSubText2 = strings[1]
        }
        
        shareLabel.text = ""
        shareLabel.applyFontSize(13, isBold: false)
        shareLabel.textColor = UIColor.secondary3()
        shareLabel.numberOfLines = 1
        shareLabel.textAlignment = .left
        shareLabel.isUserInteractionEnabled = true
        shareLabel.addGestureRecognizer(UITapGestureRecognizer(target: self, action: #selector(self.didClickUserSource)))
        shareLabel.lineBreakMode = NSLineBreakMode.byTruncatingTail
        self.addSubview(shareLabel)
        
        merchantBehalfName.backgroundColor = UIColor.white
        merchantBehalfName.text = ""
        merchantBehalfName.formatSize(10)
        merchantBehalfName.numberOfLines = 1
        merchantBehalfName.lineBreakMode = NSLineBreakMode.byTruncatingTail
        merchantBahalfButton.addSubview(merchantBehalfName)
        
        merchantBahalfButton.layer.cornerRadius = 2
        merchantBahalfButton.layer.borderWidth = 1
        merchantBahalfButton.layer.borderColor = UIColor.secondary1().cgColor
        merchantBahalfButton.addTarget(self, action: #selector(self.tapMechantBahalf), for: .touchUpInside)
        headerView.addSubview(merchantBahalfButton)
        
        headerView.addSubview(followButton)
        
        self.addSubview(headerView)
        
        postImageView.image = UIImage(named: "postPlaceholder")
        self.addSubview(postImageView)
		
        tagLayerView.addGestureRecognizer(UILongPressGestureRecognizer(target: self, action: #selector(self.handleLongPressOnPostImage)))
        tagLayerView.addGestureRecognizer(UITapGestureRecognizer(target: self, action: #selector(self.didClickImagePost)))
		self.addSubview(tagLayerView)
        
        actionView = ActionViewOnPost(price: "10.0")
        actionView?.buttonShare.addTarget(self, action: #selector(self.didClickShareButton), for: .touchUpInside)
        actionView?.buttonComment.addTarget(self, action: #selector(self.didClickCommentButton), for: .touchUpInside)
        actionView?.buttonLike.addTarget(self, action: #selector(self.didClickLikeButton), for: .touchDown)
        
        if let view = actionView {
            view.backgroundColor = UIColor.white
            self.addSubview(view)
            
        }
        
        descriptionViewContainer.backgroundColor = UIColor.white
        self.addSubview(descriptionViewContainer)

        descriptionLabel.text = ""
        
        descriptionLabel.lineBreakMode = NSLineBreakMode.byTruncatingTail
        descriptionLabel.numberOfLines = 0
        descriptionViewContainer.addSubview(descriptionLabel)

        
        labelTextBrand.formatSize(14)
        labelTextBrand.text = String.localize("LB_CA_POST_MENTIONED") + ":"
        self.addSubview(labelTextBrand)
        
        addTopBorderWithColor(UIColor.secondary1(), andWidth: 1.0)
        
        
        topLineCommentView.backgroundColor = UIColor.primary2()
        
    }
    
    override func layoutSubviews() {
        super.layoutSubviews()
        
        topBorderView.isHidden = !showTopBorder
        if showTopBorder {
            headerView.frame = CGRect(x: 0, y: TopBorderViewHeight, width: self.bounds.width, height: ViewDefaultHeight.HeightHeaderView)
        } else {
            headerView.frame = CGRect(x: 0, y: 0, width: self.bounds.width, height: ViewDefaultHeight.HeightHeaderView)
        }
        
        var frm = avatarView.frame
        frm.origin.x = PaddingAvatarImageView
        frm.origin.y = Margin.top
        avatarView.frame = frm
        
        labelNameUser.frame = CGRect(x: avatarView.frame.maxX + MarginUserName.left, y: avatarView.frame.originY + 3, width: 0, height: HeightLabel)
        
        followButton.frame = CGRect(x: self.frame.maxX - Margin.right - ButtonFollow.ButtonFollowSize.width, y: avatarView.frame.minY + (avatarView.frame.height - ButtonFollow.ButtonFollowSize.height) / 2, width: ButtonFollow.ButtonFollowSize.width, height:ButtonFollow.ButtonFollowSize.height)
        
        diamondImageView.frame = CGRect(x: avatarView.frame.maxX - SizeDiamonIcon.Width - SizeDiamonIcon.Margin , y: avatarView.frame.maxY - SizeDiamonIcon.Height - SizeDiamonIcon.Margin, width: SizeDiamonIcon.Width, height: SizeDiamonIcon.Height)
        
        self.setUserSource(thisPost.userSource)
        
        if let image = postImageView.image {
            setupImagePost(image)
        }

        tagLayerView.frame = postImageView.frame
		tagLayerView.backgroundColor = UIColor.clear
		
        setupdescriptionLabel()
        
        if let view = actionView {
            var frm:CGRect = view.frame
            frm.origin.y = self.descriptionViewContainer.frame.maxY
            view.frame = frm
        }
    }
	
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
	
	func toggleTagsVisible() {

        thisPost.isHideTag = !thisPost.isHideTag
		
		// hide Tags
		if thisPost.isHideTag {
			self.hideTags()
		}
		else {
			// show Tags
			self.setupTags(thisPost)
		}
        self.feedCollectionViewCellDelegate?.didClickedTag(thisPost)
        
        //record action
        self.recordTapAction(tagLayerView, sourceRef: String(self.thisPost.postId), sourceType: AnalyticsActionRecord.ActionElement.Post, targetRef: self.thisPost.isHideTag ? "ProductTag-Hide" : "ProductTag-Show", targetType: AnalyticsActionRecord.ActionElement.Product)
	}
	
    func hideTags(){
        self.tagLayerView.subviews.forEach({
            if $0 is ProductTagView {
                ($0 as! ProductTagView).stopAnimation()
            }
            $0.removeFromSuperview()
        })
    }

    
    //MARK: Style UI
    func setupdescriptionLabel() -> Void {//TODO
        if let _ = actionView{
            if thisPost.likeCount > 0 {
                actionView?.likeCountLabel.text = NumberHelper.formatLikeAndCommentCount(thisPost.likeCount)
            }
            if thisPost.commentCount > 0 {
                actionView?.commentCountLabel.text = NumberHelper.formatLikeAndCommentCount(thisPost.commentCount)
            }
            
            var postDescription = ""
            if thisPost.postText.isEmpty {
                 postDescription = thisPost.postText
            }else{
                 postDescription = BasePostCollectionViewCell.getTextByRemovingAppUrls(thisPost.postText)
            }
            
            let textHeight = MyFeedCollectionViewCell.getHeightDescription(postDescription, isExpandDescriptionText: thisPost.isExpand)
//            var marginTopBottom = textHeight > 0 ? Margin.TopBottomOfDescription : 0
            var margin: CGFloat = 8
            if textHeight == 0 {
                margin = 0
            }
//            if textHeight > 0 {
//                marginTopBottom = 0
//            }
            
            let heightActionView = actionView?.frame.sizeHeight ?? 0
            descriptionLabel.frame = CGRect(x: Margin.left, y: margin, width: self.bounds.width - Margin.left * 2, height: textHeight + margin)
            descriptionViewContainer.frame = CGRect(x: 0, y: self.postImageView.frame.maxY, width: self.bounds.width, height: self.bounds.sizeHeight - heightActionView - self.postImageView.frame.maxY)
            descriptionLabel.sizeToFit()
        }
    }
    
    
    class func getHeightDescription(_ postText: String, isExpandDescriptionText: Bool) -> CGFloat{
        if postText.length == 0{
            return 0
        }
        else{
            
            let heightLabel = BasePostCollectionViewCell.getDescriptionHeight(postText, fontSize: 14, width: Constants.ScreenSize.SCREEN_WIDTH - 2*Margin.left)
            return heightLabel
        }
    }

    
	
    func setupImagePost(_ image:UIImage ) -> Void {
        var originY = shareLabel.frame.maxY
        if let _ = thisPost.userSource {
            originY += Margin.TopBottomOfDescription
        }
        postImageView.frame = CGRect(x: 0, y: originY, width: ViewDefaultHeight.HeightpostImageView, height: self.heightpostImageView)
        activityIndicator = MMActivityIndicator(frame: postImageView.frame, type: .pdp)
        activityIndicator?.isHidden = false
        if let strongActivityIndicator = activityIndicator {
            insertSubview(strongActivityIndicator, belowSubview: postImageView)
        }
        activityIndicator?.startAnimating()
    }
    
    func getHeightForCell() -> CGFloat {
        return heightForCell
    }
    
    //MARK: - init child collection View

    func getSuggestionCellWidth() -> CGFloat {
        return (Constants.ScreenSize.SCREEN_WIDTH - (Constants.Margin.Left + Constants.Margin.Right + Constants.LineSpacing.ImageCell)) / 2
    }
	
    func addTopBorderWithColor(_ color: UIColor, andWidth borderWidth: CGFloat) {
        let border: UIView = UIView()
        border.backgroundColor = color
        border.autoresizingMask = [.flexibleWidth, .flexibleBottomMargin]
        border.frame = CGRect(x: 0, y: 0, width: listBrandView.frame.size.width, height: borderWidth)
        self.listBrandView.addSubview(border)
    }
    
    
    func handleExpand(_ post: Post) {
        thisPost = post
        self.setUserSource(thisPost.userSource)
    }
    

    
   
    
    func setupTags(_ newsfeed: Post, animated: Bool = true) {
        if let skus  = newsfeed.skuList {
			self.tagLayerView.subviews.forEach({
                if $0 is ProductTagView {
                    ($0 as! ProductTagView).stopAnimation()
                }
                $0.removeFromSuperview()
            })
            if !newsfeed.isHideTag {
                var index = 0
                for skue in skus {
                    let size =  CGSize(width: Constants.ScreenSize.SCREEN_WIDTH, height: Constants.ScreenSize.SCREEN_WIDTH)
                    
                    Log.debug("size : \(size)")
                    Log.debug("skue.positionX : \(skue.positionX)")
                    Log.debug("skue.positionY : \(skue.positionY)")
                    
                    let tagPercent = ProductTagView.getTapPercentage(CGPoint(x: skue.positionX, y: skue.positionY))
                    let tagPoint = ProductTagView.getTapPonit((skue.positionX, skue.positionY), imageSize: size)
					let productTagView = ProductTagView(
						position: tagPoint,
						price: skue.price(),
						parentTag: 0,
						delegate: self,
						oldPrice: skue.priceSale,
						newPrice: skue.priceRetail,
						logoImage: UIImage(),
						logo: skue.brandImage,
						tagImageSize: size,
						skuId: skue.skuId,
						place: skue.place,
						mode: .special,
                        tagStyle: .Commodity
					)
                    productTagView.styleCode = skue.styleCode
                    productTagView.skuCode = skue.skuCode
                    productTagView.skuName = skue.skuName
                    productTagView.analyticsViewKey = self.analyticsViewKey
                    productTagView.analyticsImpressionKey = self.analyticsImpressionKey
                    var frame = productTagView.baseView.frame
                    frame.size.height += 30
                    productTagView.baseView.frame = frame
                    tagLayerView.addSubview(productTagView)
                    setupTagTitle(productTagView, sku: skue)
                    productTagView.tag = index
                    productTagView.tagDelegate = self
                    Log.debug("skue.positionX : \(skue.positionX)")
                    Log.debug("skue.positionX : \(skue.positionY)")
                    Log.debug("tagPercent : \(tagPercent)")
                    Log.debug("tagPoint : \(tagPoint)")
                    Log.debug("tagp.finalLocation : \(productTagView.finalLocation)")
                    
                    //tagp.fillPrice(skue.priceSale, priRetail: skue.priceRetail, isSale: skue.isSale)
                    index += 1
					
                    if animated{
                        productTagView.alpha = 0.0
                        DispatchQueue.global(qos: DispatchQoS.QoSClass.default).async {
                            DispatchQueue.main.async(execute: {
                                UIView.animate(withDuration: 0.5, animations: {
                                    productTagView.alpha = 1.0
                                }) 
                            })
                        }
                    }					
                }
            }
        } else {
            self.tagLayerView.subviews.forEach({ $0.removeFromSuperview() })
            if let recognizers = tagLayerView.gestureRecognizers {
                for recognizer in recognizers {
                    tagLayerView.removeGestureRecognizer(recognizer as UIGestureRecognizer)
                }
            }
        }
    }
    
    func setupDataByNewfeed(_ newsfeed: Post, isLiked: Bool = false) -> Void {
		
		if let author = newsfeed.user {
			self.labelNameUser.text = author.displayName
			
			self.avatarView.setupViewByUser(author, isMerchant: (newsfeed.isMerchantIdentity.rawValue == 1))

            self.diamondImageView.isHidden = !(thisPost.isMerchantIdentity != .fromContentManager && author.isCurator == 1)
		}
		
		    
        self.followButton.addTarget(self, action: #selector(self.clickFollowing), for: .touchUpInside)
        
        if let merchant = newsfeed.merchant {
            if newsfeed.isMerchantIdentity == .fromContentManager{
                self.avatarView.setupViewByMerchant(merchant)
                self.labelNameUser.text = merchant.merchantName.length > 0 ? merchant.merchantName : merchant.merchantCompanyName
                merchantBahalfButton.isHidden = true
                self.followButton.setFollowButtonState(isFollowingMerchant(merchant))
            } else {
                merchantBehalfName.text = merchant.merchantName.length > 0 ? merchant.merchantName : merchant.merchantCompanyName
                merchantBahalfButton.isHidden = false
                if let author = newsfeed.user {
                    self.followButton.setFollowButtonState(isFollowingUser(author))
                }
            }
            
            if isLoadingMerchant(merchant) {
                self.followButton.showLoading()
            } else {
                self.followButton.hideLoading()
            }
        } else {
            merchantBahalfButton.isHidden = true
            if let author = newsfeed.user {
                self.followButton.setFollowButtonState(isFollowingUser(author))
                if isLoadingUser(author) {
                    self.followButton.showLoading()
                } else {
                    self.followButton.hideLoading()
                }
            }
        }
        
        
        
        let isMe = newsfeed.user?.userKey == Context.getUserKey()
        
        self.followButton.isHidden = isMe && newsfeed.isMerchantIdentity != .fromContentManager
        
        
        if newsfeed.postImage == "0" || newsfeed.postImage == "" {
            if let image = KingfisherManager.shared.cache.retrieveImageInDiskCache(forKey: newsfeed.correlationKey, options: nil) {
                self.postImageView.image = image
            }else if let image = newsfeed.pendingUploadImage {
                self.postImageView.image = image
            }else {
                self.postImageView.image = UIImage(named: "postPlaceholder")
            }
        }else {
            _ = self.postImageView.mm_setImageWithURL(ImageURLFactory.URLSize1000(newsfeed.postImage, category: .post), placeholderImage : UIImage(named: "postPlaceholder"))
        }
        
        self.postImageView.contentMode = .scaleAspectFill
        
        //self.setupTags(newsfeed)
        self.descriptionLabel.text = newsfeed.postText
        self.formatDescription(self.descriptionLabel, post: newsfeed, fontSize: 14)
        if let skuelist = newsfeed.skuList, skuelist.count > 0 {

            let _ = Double(skuelist.reduce(Double(0.00), { (lowest, sku) -> Double in
                var cur : Double = lowest
                if lowest == 0.00{
                    cur = sku.price()
                }
                else if lowest > sku.price(){
                    cur = sku.price()
                }
                
                return cur
            }))
            
            
        } else {
            
        }
        
        actionView?.buttonLike.isSelected = isLiked
       
        
        
        self.setNeedsLayout()
        if newsfeed.likeCount > 0 {
            actionView?.likeCountLabel.text = NumberHelper.formatLikeAndCommentCount(newsfeed.likeCount)

        }else {
            actionView?.likeCountLabel.text = ""
        }
        if newsfeed.commentCount > 0 {
            actionView?.commentCountLabel.text = NumberHelper.formatLikeAndCommentCount(newsfeed.commentCount)
        }else {
            actionView?.commentCountLabel.text = ""
        }
        actionView?.layoutSubviews()
    }
    
    @objc func clickFollowing(){
		
		// detect guest mode
		guard (LoginManager.getLoginState() == .validUser) else {
			LoginManager.goToLogin()
			return
		}
		
        if let merchant = thisPost.merchant {
            if thisPost.isMerchantIdentity == .fromContentManager{
                self.followButton.showLoading()
                let currentFollowing = isFollowingMerchant(merchant)
                self.feedCollectionViewCellDelegate?.didClickedFollowMerchant(merchant, isGoingToFollow: !currentFollowing) //inverse current state
                return
            }
        }
        
        if let author = thisPost.user {
            self.followButton.showLoading()
            let currentFollowing = isFollowingUser(author)
            self.feedCollectionViewCellDelegate?.didClickedFollowUser(author, isGoingToFollow: !currentFollowing)
        }
        
    }
    
    func isLoadingMerchant(_ merchant: Merchant) -> Bool{
        return FollowService.instance.cachedLoadingMerchantIds.contains(merchant.merchantId )
    }
    
    func isLoadingUser(_ user: User) -> Bool{
        return FollowService.instance.cachedLoadingUserKeys.contains(user.userKey )
    }
    
    func isFollowingMerchant(_ merchant: Merchant) -> Bool{
        return FollowService.instance.cachedFollowingMerchantIds.contains(merchant.merchantId )
    }
    
    func isFollowingUser(_ user: User) -> Bool{
        return FollowService.instance.cachedFollowingUserKeys.contains(user.userKey )
    }
    
    private func setupTagTitle(_ tag: ProductTagView, sku: Sku) {
        tag.tagTitleLabel.text = sku.brandName
	}
    
    //MARK: - Actions
    
    @objc func tapMechantBahalf(_ sender: Any){
        if let merchant = thisPost.merchant{
            self.feedCollectionViewCellDelegate?.didSelectMerchant(merchant)
        }
    }
    
    func didSelectSkuAtIndexPath(_ indexPath: IndexPath) {
        if let sku = thisPost.skuList?[indexPath.row] {
            //Analytic
            let actionRecord = AnalyticsManager.createActionRecord(analyticsViewKey: self.analyticsViewKey ?? "", analyticsImpressionKey: self.analyticsImpressionKey ?? "", actionTrigger: .Tap, sourceRef: sku.styleCode, sourceType: .Product, targetRef: "PDP", targetType: .View)
            AnalyticsManager.sharedManager.recordAction(actionRecord)
            self.feedCollectionViewCellDelegate?.didSelectSku(sku, post: thisPost, referrerUserKey: "")
        }
    }
    
    func didSelectBrandAtIndexPath(_ indexPath: IndexPath) {
        if indexPath.row < thisPost.merchantList.count {
            self.feedCollectionViewCellDelegate?.didSelectMerchant(thisPost.merchantList[indexPath.row - thisPost.brandList.count])
           
            
        } else if indexPath.row < (thisPost.merchantList.count + thisPost.userList.count) {
            let index = indexPath.row - thisPost.merchantList.count
            self.feedCollectionViewCellDelegate?.didSelectUser(thisPost.userList[index])
            
        } else {
            let index = indexPath.row - (thisPost.merchantList.count + thisPost.userList.count)
            self.feedCollectionViewCellDelegate?.didSelectBrand(thisPost.brandList[index])
        }
    }
    
    
    @objc func didClickUserProfile(_ tapGesture: UITapGestureRecognizer) {
        if let comments = self.thisPost.postCommentLists {
            if let comment = comments.filter({$0.statusId != Constants.StatusID.deleted.rawValue}).last {
                let user = User()
                user.userKey = comment.userKey
                user.userName = comment.userName
                self.feedCollectionViewCellDelegate?.didClickUserProfile(user)
            }
        }
    }
    
    @objc func didClickCommentButton(_ sender: UIButton) {
        self.feedCollectionViewCellDelegate?.didClickedComment(thisPost)
        
        sender.initAnalytics(withViewKey: self.analyticsViewKey ?? "", impressionKey: self.analyticsImpressionKey)
        //record action
        sender.recordAction(.Tap, sourceRef: "Comment", sourceType: .Button, targetRef: "\(self.thisPost.postId)", targetType: .Post)
    }
    
    @objc func didClickShareButton(_ sender: UIButton) {
        sender.initAnalytics(withViewKey: self.analyticsViewKey ?? "", impressionKey: self.analyticsImpressionKey)
        sender.recordAction(.Tap, sourceRef: "Share", sourceType: .Button, targetRef: "\(thisPost.postId)", targetType: .Post)
        self.feedCollectionViewCellDelegate?.didClickedShare(thisPost)
    }
    
    
    @objc func didClickImagePost() {
		//self.toggleTagsVisible()
        self.feedCollectionViewCellDelegate?.didClickDescriptionText(self.thisPost)
    }
    
    func recordTapAction(_ view: UIView,sourceRef: String,sourceType: AnalyticsActionRecord.ActionElement, targetRef: String, targetType: AnalyticsActionRecord.ActionElement = .View){
        view.initAnalytics(withViewKey: self.analyticsViewKey ?? "", impressionKey: self.analyticsImpressionKey)
        view.recordAction(
            .Tap,
            sourceRef: sourceRef,
            sourceType: sourceType,
            targetRef: targetRef,
            targetType: targetType)
    }
    
    func updateTag(_ tag: ProductTagView) {
        
         if let sku = thisPost.skuList?[tag.tag] {
            self.feedCollectionViewCellDelegate?.didSelectSku(sku, post: thisPost, referrerUserKey: "")
        }
    }

    @objc func didClickLikeButton(_ sender: UIButton) {
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
        
        self.feedCollectionViewCellDelegate?.didClickedLike(thisPost, cell: self)
    }
	
	deinit {
		NotificationCenter.default.removeObserver(self)
	}
    
    @objc func didClickUserSource() {
        if let user = thisPost.userSource {
            self.feedCollectionViewCellDelegate?.didSelectUser(user)
        }
    }
    

    
    @objc func openAuthorProfile() {
        if thisPost.isMerchantIdentity == .fromContentManager{
            if let merchant = thisPost.merchant {
                thisPost.merchant?.merchantId = thisPost.merchantId
                self.feedCollectionViewCellDelegate?.didSelectMerchant(merchant)
            }
        } else if let user = thisPost.user {
            self.feedCollectionViewCellDelegate?.didSelectUser(user)
        }
    }
    
    
    
    func setUserSource(_ userSource: User?) {
        var shareLabelHeight = CGFloat(0)
        if let user = userSource {
            
            //Make sure font is not null
            if let fontRegular = UIFont(name: "PingFangSC-Regular", size: 13), let fontMedium = UIFont(name: Constants.Font.Bold, size: 13) {
                
                let fontRegularAttribute = [
                    NSAttributedStringKey.font : fontRegular,
                    NSAttributedStringKey.foregroundColor : UIColor.secondary2()
                ]
                let fontMediumAttribute = [
                    NSAttributedStringKey.font : fontMedium,
                    NSAttributedStringKey.foregroundColor : UIColor.black
                ]
                
                let attributedSubText1 = NSMutableAttributedString(string:userSourceSubText1, attributes: fontRegularAttribute)
                let attributedDisplayName = NSMutableAttributedString(string:" \(user.displayName)", attributes: fontMediumAttribute)
                let attributedSubText2 = NSMutableAttributedString(string:" \(userSourceSubText2)", attributes: fontRegularAttribute)
                
                attributedSubText1.append(attributedDisplayName)
                attributedSubText1.append(attributedSubText2)
                self.shareLabel.attributedText = attributedSubText1
            } else {
                self.shareLabel.text = userSourceSubText1 + " " + user.displayName + " " + userSourceSubText2
            }
            shareLabelHeight = ViewDefaultHeight.HeightLabel
            self.shareLabel.sizeToFit()
        }
        else{
            shareLabelHeight = 0
            self.shareLabel.text = ""
        }
        
        self.timeLabel.text = thisPost.timeString()
        self.labelNameUser.sizeToFit()

        let nameLabelOriginY = labelNameUser.frame.originY

        
        let titleRightMargin = followButton.frame.minX

        merchantBehalfName.sizeToFit()
        var merchantTagWidth:CGFloat = 0.0
        var maximumWidthLabelNameUser = floor(titleRightMargin - (self.labelNameUser.frame.minX + MarginUserName.left + badgePadding * 2 ))
        
        if merchantBahalfButton.isHidden == false{
            
            let exceedLength = (merchantBehalfName.frame.sizeWidth + labelNameUser.frame.sizeWidth + badgePadding * 2 > maximumWidthLabelNameUser)
            if exceedLength {
                let badgeMaxWidth = StringHelper.getTextWidth("一二三四五六", height: merchantBehalfName.frame.height, font: merchantBehalfName.font)
                merchantBehalfName.width = (merchantBehalfName.frame.sizeWidth < badgeMaxWidth ? merchantBehalfName.frame.sizeWidth : badgeMaxWidth)
                merchantTagWidth = merchantBehalfName.width + badgePadding * 2
                maximumWidthLabelNameUser = maximumWidthLabelNameUser - merchantTagWidth - MarginUserName.left * 2
            } else {
                merchantTagWidth = merchantBehalfName.frame.sizeWidth + badgePadding * 2
                maximumWidthLabelNameUser = maximumWidthLabelNameUser - merchantTagWidth - MarginUserName.left * 2
            }
        }
        var labelNameUserFrame = labelNameUser.frame
        labelNameUserFrame.sizeWidth = labelNameUser.frame.sizeWidth < maximumWidthLabelNameUser ? labelNameUser.frame.sizeWidth:maximumWidthLabelNameUser
        labelNameUserFrame.originY = nameLabelOriginY
        labelNameUser.frame = labelNameUserFrame
        
        let contentSize = timeLabel.intrinsicContentSize
        timeLabel.frame = CGRect(x: self.labelNameUser.frame.minX, y: labelNameUser.frame.maxY, width: maximumWidthLabelNameUser, height: contentSize.height)
        
        shareLabel.frame = CGRect(x: Margin.left, y: headerView.frame.maxY, width: self.bounds.sizeWidth, height: shareLabelHeight)

        var merchantBahalfButtonFrame = merchantBahalfButton.frame
        merchantBahalfButtonFrame.origin.x = self.labelNameUser.frame.maxX + MarginUserName.left
        merchantBahalfButtonFrame.origin.y = self.labelNameUser.frame.originY
        merchantBahalfButtonFrame.size.width = merchantTagWidth
        merchantBahalfButtonFrame.size.height = ViewDefaultHeight.HeightTagMerchant
        merchantBahalfButton.frame = merchantBahalfButtonFrame
        merchantBehalfName.frame = CGRect(x: (merchantBahalfButton.frame.sizeWidth - merchantBehalfName.frame.sizeWidth)/2, y: (merchantBahalfButton.frame.sizeHeight - merchantBehalfName.frame.sizeHeight)/2, width: merchantBehalfName.frame.sizeWidth, height: merchantBehalfName.frame.sizeHeight)
    }
    
    func resetAnimation() {
        self.tagLayerView.subviews.forEach({
            if $0 is ProductTagView {
                ($0 as! ProductTagView).pinView.startAnimation()
            }
        })
    }
    
    func stopAnimation() {
        self.tagLayerView.subviews.forEach({
            if $0 is ProductTagView {
                ($0 as! ProductTagView).stopAnimation()
            }
        })
    }
    
    //MARK: Analytics
    func recordImpressionAtIndexPath(_ indexPath: IndexPath, positionLocation: String, viewKey: String){
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
            var referrerType = authorType
            var impressionRef = ""
            var referrerRef = ""
            if let userSource = thisPost.userSource {
                impressionRef = "User"
                referrerRef = userSource.userKey
                authorType = userSource.userTypeString()
            } else {
                impressionRef = "\(self.thisPost.postId)"
                referrerType = ""
            }
            self.initAnalytics(withViewKey: viewKey, impressionKey: AnalyticsManager.sharedManager.recordImpression(self.thisPost.user?.userKey,
                authorType: authorType,
                impressionRef: impressionRef,
                impressionType: "Post",
                impressionDisplayName: impressionDisplayName,
                parentRef: merchantId,
                parentType: merchantName,
                positionComponent: "PostListing",
                positionIndex: indexPath.row + 1,
                positionLocation: positionLocation,
                referrerRef:referrerRef,
                viewKey: viewKey))
            
            //impression for products
            if thisPost.isHasSkuList(){
                for subview in self.tagLayerView.subviews{
                    if let tagProduct = subview as? ProductTagView{
                        AnalyticsManager.sharedManager.recordImpression(self.thisPost.user?.userKey, authorType: authorType, impressionRef: tagProduct.styleCode, impressionType: "Product", impressionVariantRef: tagProduct.skuCode, impressionDisplayName: tagProduct.skuName, parentRef: "\(self.thisPost.postId)", parentType: "Post", positionComponent: "PostListing", positionIndex: self.tagLayerView.subviews.index(of: subview), positionLocation: positionLocation, referrerRef: referrerRef, referrerType: referrerType, viewKey: viewKey)
                    }
                }
            }
        }
    }
    
    // MARK: - Handle Long Press Gesture on Product Image
    @objc func handleLongPressOnPostImage(_ gesture: UILongPressGestureRecognizer) -> Void {
        if gesture.state == UIGestureRecognizerState.began {
            let optionMenu = UIAlertController(title: nil, message: nil, preferredStyle: .actionSheet)
            let saveAction = UIAlertAction(title: String.localize("LB_SAVE"), style: .default, handler: { (alert: UIAlertAction!) -> Void in
                if let image = self.postImageView.image{
                    UIImageWriteToSavedPhotosAlbum(image, nil, nil, nil);
                }
            })
            
            let cancelAction = UIAlertAction(title: String.localize("LB_CANCEL"), style: .cancel, handler: nil)
            
            optionMenu.addAction(saveAction)
            optionMenu.addAction(cancelAction)
            optionMenu.view.tintColor = UIColor.secondary2()
            
            if var topController = UIApplication.shared.keyWindow?.rootViewController {
                while let presentedViewController = topController.presentedViewController {
                    topController = presentedViewController
                }
                
                topController.present(optionMenu, animated: true, completion: nil)
            }
            
            optionMenu.view.tintColor = UIColor.alertTintColor()
        }
    }
    
    override func didClickOnHashTag(_ tag: String) {
        self.feedCollectionViewCellDelegate?.didClickOnHashTag(tag)
    }
    
    override func didClickDescriptionText(_ post: Post) {
        self.feedCollectionViewCellDelegate?.didClickDescriptionText(post)
    }
    
    override func didClickURL(_ url: String) {
        self.feedCollectionViewCellDelegate?.didClickOnURL(url)
    }
}
