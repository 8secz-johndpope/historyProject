//
//  NewsFeedDetailCell.swift
//  merchant-ios
//
//  Created by Sang Nguyen on September 07 2017
//  Copyright © 2016 WWE & CO. All rights reserved.
//

import UIKit
import PromiseKit
import ObjectMapper
import Kingfisher
import YYText

protocol NewsFeedDetailCellDelegate: NSObjectProtocol {
    func didSelectUser(_ user: User)
    func didSelectMerchant(_ merchant: Merchant)
    func didSelectSku(_ sku: Sku, post: Post, referrerUserKey: String)
	func refreshCollectionViewWithStyles(_ styles : [Style], byIndex: Int)
    func didClickUserProfile(_ user: User)
    func didClickedTag(_ post: Post)
    func didClickedFollowUser(_ user: User, isGoingToFollow: Bool)
    func didClickedFollowMerchant(_ merchant: Merchant, isGoingToFollow: Bool)
    func didClickOnHashTag(_ hashTag: String)
    func didClickOnURL(_ url: String)
}

class NewsFeedDetailCell: BasePostCollectionViewCell, TagViewDelegate, SuggestCollectionDelegate,SuggestCollectionViewDatasourceDelegate, ListObjectCollectionDelegate {
    
    static let CellIdentifier = "NewsFeedDetailCellID"
    
    struct Margin {
        static let top: CGFloat = 12.0
        static let bottom: CGFloat = 7.0
        static let left: CGFloat = 15.0
        static let right: CGFloat = 15.0
        static let bottomOfDescription: CGFloat = 10
        static let topMarginReleatedLabel: CGFloat = 24
    }
    
    struct MarginUserName {
        static let top: CGFloat = 13
        static let left: CGFloat = 12.0
        static let right: CGFloat = 64.0
        
    }
    
    struct SizeDiamonIcon {
        static let Width: CGFloat = 14
        static let Height: CGFloat = 14
        static let Margin: CGFloat = 1
    }
    enum EnumTag:Int {
        case productTag = 100
    }
    
    struct ViewDefaultHeight {
        static let HeightRelatedProductView: CGFloat = 50
        static let HeightpostImageView: CGFloat = Constants.ScreenSize.SCREEN_WIDTH
        static let HeightMessage: CGFloat = 18.0
        static let HeightUserView: CGFloat = 60.0
        static let HeightTagMerchant: CGFloat = 18.0
        static let HeightLikeCommentCount: CGFloat = 42.0
        static let HeightUserSource: CGFloat = 15
    }
    
    private final let HeightLabel: CGFloat = 21.0
    
    private final let SizeImageExpand: CGFloat = 24.0
    private final let CommentTimeStampLabelWidth: CGFloat = 90.0
	
    private final let imageViewExpandSize:CGSize = CGSize(width: 8.0, height: 5.0)
    private final let TimeStampLabelWidth : CGFloat = 100
    private final let PaddingAvatarImageView: CGFloat = 14
    
    var referrerUserKey = "" {
        didSet {
            self.dataProviderSku.referrerUserKey = referrerUserKey.length > 0 ? referrerUserKey : thisPost.user?.userKey
        }
    }
    
    var MarginLeftList: CGFloat = 60.0
    var heightSuggestView: CGFloat = 0.0
    var heightpostImageView: CGFloat = Constants.ScreenSize.SCREEN_WIDTH
    var userView = UIView()
    var labelNameUser = UILabel()
    var avatarView = AvatarView(imageStr: "", width: 40.0, height: 40.0, mode: .custom)
    
    var timeStampLabel = UILabel()
    var userSourceLabel = UILabel()
    
    //-------- Merchant badge --------------//
    
    var merchantBahalfButton = UIButton()
    var merchantBehalfName = UILabel()
    //--------------end-header--------------//
    
    var postImageView = UIImageView()
    weak var activityIndicator: MMActivityIndicator?
    var descriptionLabel = YYLabel()
    
    var descriptionViewContainer = UIView()
    
    var relatedProductView = UIView()
    var relatedProductLabel = UILabel()
    var leftLineRelatedProduct = UIView()
    var rightLineRelatedProduct = UIView()
    var bottomLineView = UIView()
    
    //------------suggestCollectionView----//
    var collectionViewDataSource : UICollectionViewDataSource!
    
    var collectionViewDelegate : UICollectionViewDelegate!
    
    var suggestCollectionView : UICollectionView!
    
    //-------------------suggest object------------------//
    var listUserView = UIView()
    var diamondImageView = UIImageView()
    var price: Float = 0
    var thisPost = Post()
    
    var dataProviderSku = SuggestCollectionViewDatasource()
    var delegateSkue = SuggestCollectionViewDelegate()

    weak var delegate: NewsFeedDetailCellDelegate?
	var tagLayerView = UIView()
	
    let badgePadding: CGFloat = 2.0
    var userSourceSubText1 = ""
    var userSourceSubText2 = ""
	
    var followButton = ButtonFollow()
    
    var showTopBorder = false
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        
        userView.backgroundColor = UIColor.white
        self.delegateSkue.delegate = self
        self.dataProviderSku.delegate = self
        avatarView.sizeCustomAvatar = CGSize(width: 40, height: 40)
        avatarView.addGestureRecognizer(UITapGestureRecognizer(target: self, action: #selector(self.openAuthorProfile)))
        userView.addSubview(avatarView)
        
        diamondImageView.image = UIImage(named: "curator_diamond")
        diamondImageView.isHidden = true
        userView.addSubview(diamondImageView)
        
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

        timeStampLabel.text = ""
        timeStampLabel.formatSize(12)
        timeStampLabel.textColor = UIColor.secondary3()
        timeStampLabel.textAlignment = .left
        
        userView.backgroundColor = UIColor.white
        userView.addSubview(labelNameUser)
        userView.addSubview(timeStampLabel)
        
        let strings = String.localize("LB_CA_POST_SHARE_WHOSE_POST").components(separatedBy: "{0}")
        if strings.count > 1 {
            userSourceSubText1 = strings[0]
            userSourceSubText2 = strings[1]
        }
        
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
        userView.addSubview(merchantBahalfButton)
        
        userView.addSubview(followButton)
        
        self.addSubview(userView)
        
        //------------//
        postImageView.image = UIImage(named: "postPlaceholder")
        self.addSubview(postImageView)
        
        let gesture = UIPinchGestureRecognizer(target: self, action:#selector(NewsFeedDetailCell.pinch))
        tagLayerView.addGestureRecognizer(gesture)
		
		//------------//
        tagLayerView.addGestureRecognizer(UILongPressGestureRecognizer(target: self, action: #selector(self.handleLongPressOnPostImage)))
        tagLayerView.addGestureRecognizer(UITapGestureRecognizer(target: self, action: #selector(self.didClickImagePost)))
		self.addSubview(tagLayerView)
        
        //------------//
        descriptionViewContainer.backgroundColor = UIColor.white
        self.addSubview(descriptionViewContainer)
        descriptionLabel.font = UIFont.fontWithSize(14, isBold: false)
        descriptionLabel.textColor = UIColor.black
        descriptionLabel.text = ""
        descriptionLabel.lineBreakMode = NSLineBreakMode.byTruncatingTail
        descriptionLabel.numberOfLines = 0
        
        descriptionLabel.tintColor = UIColor.hashtagColor()
        descriptionLabel.isUserInteractionEnabled = true

        userSourceLabel.text = ""
        userSourceLabel.formatSize(14)
        userSourceLabel.textColor = UIColor.secondary3()
        userSourceLabel.textAlignment = .left
        userSourceLabel.isHidden = true
        userSourceLabel.addGestureRecognizer(UITapGestureRecognizer(target: self, action: #selector(self.didClickUserSource)))
        userSourceLabel.isUserInteractionEnabled = true
        
        descriptionViewContainer.addSubview(userSourceLabel)
        descriptionViewContainer.addSubview(descriptionLabel)
        
        relatedProductView.backgroundColor = UIColor.white
        self.addSubview(relatedProductView)
        
        leftLineRelatedProduct.backgroundColor = UIColor.secondary3()
        rightLineRelatedProduct.backgroundColor = UIColor.secondary3()
        relatedProductLabel.formatSize(15)
        relatedProductLabel.textColor = UIColor.secondary2()
        relatedProductLabel.textAlignment = .center
        relatedProductLabel.text = String.localize("LB_CA_USER_POST_RELATED_PROD")
        relatedProductView.addSubview(relatedProductLabel)
        relatedProductView.addSubview(leftLineRelatedProduct)
        relatedProductView.addSubview(rightLineRelatedProduct)
        
        self.initCollectionViewWithDatasource(self.dataProviderSku, delegate: self.delegateSkue)

        bottomLineView.backgroundColor = UIColor.primary2()
        self.addSubview(bottomLineView)
    }
    
    override func layoutSubviews() {
        super.layoutSubviews()

        if let images = thisPost.images, images.count > 0 {
            userView.frame = CGRect(x: 0, y: 0, width: self.bounds.width, height: ViewDefaultHeight.HeightUserView)

        }else{
            if let image = postImageView.image {
                setupImagePost(image)
            }
            userView.frame = CGRect(x: 0, y: postImageView.frame.maxY, width: self.bounds.width, height: ViewDefaultHeight.HeightUserView)
        }
        var frm = avatarView.frame
        frm.origin.x = PaddingAvatarImageView
        frm.origin.y = Margin.top
        avatarView.frame = frm
        labelNameUser.frame = CGRect(x: avatarView.frame.maxX + MarginUserName.left, y: MarginUserName.top, width: 0, height: HeightLabel)
        
        followButton.frame = CGRect(x: self.frame.maxX - Margin.right - ButtonFollow.ButtonFollowSize.width, y: avatarView.frame.minY + (avatarView.frame.height - ButtonFollow.ButtonFollowSize.height) / 2, width: ButtonFollow.ButtonFollowSize.width, height:ButtonFollow.ButtonFollowSize.height)
        
        diamondImageView.frame = CGRect(x: avatarView.frame.maxX - SizeDiamonIcon.Width - SizeDiamonIcon.Margin , y: avatarView.frame.maxY - SizeDiamonIcon.Height - SizeDiamonIcon.Margin, width: SizeDiamonIcon.Width, height: SizeDiamonIcon.Height)
        
        self.setUserSource(thisPost.userSource)

        labelNameUser.frame.originY = MarginUserName.top
        timeStampLabel.frame = CGRect(x: labelNameUser.frame.originX, y: labelNameUser.frame.maxY + 1, width: followButton.frame.originX - labelNameUser.frame.maxX, height: 15)
        if thisPost.userSource != nil {
            
            self.setUserShareSource(thisPost.userSource)
            userSourceLabel.isHidden = false
            userSourceLabel.frame = CGRect(x: Margin.left, y: 5, width: self.bounds.width - Margin.left * 2, height: ViewDefaultHeight.HeightUserSource)
        } else {
            userSourceLabel.isHidden = true
        }
        
		tagLayerView.frame = postImageView.frame
		tagLayerView.backgroundColor = UIColor.clear
       
        setupdescriptionLabel()
        
        //Set up related products
        if !thisPost.isHasSkuList(){
            relatedProductView.isHidden = true
            self.suggestCollectionView.isHidden = true
            self.relatedProductView.frame = CGRect(x: 0, y: descriptionViewContainer.frame.maxY, width: bounds.width, height: 0)
            self.suggestCollectionView.frame = CGRect(x: bounds.minX, y: relatedProductView.frame.maxY, width: bounds.width, height: 0)
        } else {
            relatedProductView.frame = CGRect(x: 0, y: descriptionViewContainer.frame.maxY, width: bounds.width, height: ViewDefaultHeight.HeightRelatedProductView)
            relatedProductView.isHidden = false
            self.suggestCollectionView.isHidden = false
            self.suggestCollectionView.frame = CGRect(x: 0, y: relatedProductView.frame.maxY, width: bounds.width, height: heightSuggestView)
        }
        
        let padding = CGFloat(16)
        let lineSize = CGSize(width: 50, height: 1)
        let textWidth = StringHelper.getTextWidth(relatedProductLabel.text ?? "", height: relatedProductView.height , font: relatedProductLabel.font)
        let heightBottomLine: CGFloat = 10
        relatedProductLabel.frame = CGRect(x: (bounds.sizeWidth - textWidth) / 2,  y: Margin.topMarginReleatedLabel, width: textWidth, height: HomeHeaderView.LabelHeight)
        leftLineRelatedProduct.frame = CGRect(x: relatedProductLabel.frame.minX - padding - lineSize.width, y: relatedProductLabel.frame.midY - lineSize.height / 2, width: lineSize.width, height: lineSize.height)
        rightLineRelatedProduct.frame = CGRect(x: relatedProductLabel.frame.maxX + padding, y: relatedProductLabel.frame.midY - lineSize.height / 2, width: lineSize.width, height: lineSize.height)
        bottomLineView.frame = CGRect(x: 0, y: self.bounds.sizeHeight - heightBottomLine, width: self.bounds.width, height: heightBottomLine)
    }
	
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
	
    @objc func pinch(_ gesture: UIPinchGestureRecognizer) {
        
        TMImageZoom.shared().gestureStateChanged(gesture, withZoom: self.postImageView)
        
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
        self.delegate?.didClickedTag(thisPost)
        
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
    
    func setupdescriptionLabel() -> Void {//TODO
      
        var textHeight:CGFloat = 0.0
        
        if let string = descriptionLabel.attributedText?.string {
            textHeight = NewsFeedDetailCell.getHeightDescription(string)
        } else {
            textHeight = NewsFeedDetailCell.getHeightDescription(descriptionLabel.text ?? thisPost.postText)
        }
        
        var heightDescriptionContainer = textHeight + Margin.bottomOfDescription + 5
        if thisPost.userSource != nil {
            descriptionLabel.frame = CGRect(x: Margin.left, y: userSourceLabel.frame.maxY + 5, width: self.bounds.width - Margin.left * 2, height: textHeight)
            heightDescriptionContainer = heightDescriptionContainer + ViewDefaultHeight.HeightUserSource + 5
        } else {
            descriptionLabel.frame = CGRect(x: Margin.left, y: 5 , width: self.bounds.width - Margin.left * 2, height: textHeight)
        }
        
        descriptionViewContainer.frame = CGRect(x: 0, y: self.userView.frame.maxY, width: self.bounds.width, height: heightDescriptionContainer)
        descriptionLabel.sizeToFit()
    }
    
    class func getHeightDescription(_ postText: String) -> CGFloat{
        if postText.length == 0{
            return 0
        }
        else{
            var heightLabel = BasePostCollectionViewCell.getDescriptionHeight(postText, fontSize: 14, width: Constants.ScreenSize.SCREEN_WIDTH - 2*Margin.left)
            if heightLabel > 0 {
                let moreHeight: CGFloat = 8 //more height for fix displaying  text is not enough space
                heightLabel = heightLabel + moreHeight
            }
            return heightLabel
        }
    }

    
	
    func setupImagePost(_ image:UIImage ) -> Void {
        postImageView.frame = CGRect(x: 0, y: 0, width: ViewDefaultHeight.HeightpostImageView, height: self.heightpostImageView)
        activityIndicator = MMActivityIndicator(frame: postImageView.frame, type: .pdp)
        activityIndicator?.isHidden = false
        if let strongActivityIndicator = activityIndicator {
            insertSubview(strongActivityIndicator, belowSubview: postImageView)
        }
        activityIndicator?.startAnimating()
    }
    
    //MARK: - init child collection View
    func initCollectionViewWithDatasource (_ datasource: UICollectionViewDataSource, delegate: UICollectionViewDelegate) {
        self.collectionViewDataSource = datasource
        self.collectionViewDelegate = delegate
        let brandLayout: UICollectionViewFlowLayout = UICollectionViewFlowLayout()
        brandLayout.sectionInset = UIEdgeInsets(top: 0, left: 0, bottom: 0, right: 0)
        brandLayout.scrollDirection = UICollectionViewScrollDirection.horizontal
        
        let frame = CGRect(x: bounds.minX, y: descriptionViewContainer.frame.maxY, width: bounds.width, height: heightSuggestView)
        let collectionView = UICollectionView(frame: frame, collectionViewLayout: brandLayout)
        collectionView.showsHorizontalScrollIndicator = false
        collectionView.backgroundColor = UIColor.white
        collectionView.register(SuggestCollectionViewCell.self, forCellWithReuseIdentifier: CollectCellId)
        collectionView.delegate = self.collectionViewDelegate
        collectionView.dataSource = self.collectionViewDataSource
        self.suggestCollectionView = collectionView
        self.addSubview(suggestCollectionView)
        
        self.suggestCollectionView.reloadData()
    }
	
    func getSuggestionCellWidth() -> CGFloat {
        return (Constants.ScreenSize.SCREEN_WIDTH - (Constants.Margin.Left + Constants.Margin.Right + Constants.LineSpacing.ImageCell)) / 2
    }
    
    func updateCellStyles(_ index: Int) {
        let styleCodes = (thisPost.skuList ?? []).map({ $0.styleCode })
        let merchantIds = thisPost.getMerchantIds()
        //MM-24260 Empty array mean style means style is fetched no need to fetch in the future
        thisPost.styles = []
        self.updateStyles(styleCodes, byIndex: index, merchantIds: merchantIds)
    }
	
    func updateStyles(_ styleCodes: [String], byIndex: Int, merchantIds: [String]) {
		
		SearchService.searchStyleByStyleCodeAndMechantId(styleCodes.joined(separator: ","), merchantIds: merchantIds.joined(separator: ",")) { (response) in
			
			if response.result.isSuccess {
				if let response = Mapper<SearchResponse>().map(JSONObject: response.result.value), let styles = response.pageData {
					
					self.delegate?.refreshCollectionViewWithStyles(styles, byIndex: byIndex)
					
					Log.debug("successfully getting styles")
                }
				
			} else {
				Log.debug("error getting styles")
			}
            
		}
		
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
            // remove showTagButton and tap action
            self.tagLayerView.subviews.forEach({ $0.removeFromSuperview() })
            if let recognizers = tagLayerView.gestureRecognizers {
                for recognizer in recognizers {
                    tagLayerView.removeGestureRecognizer(recognizer as UIGestureRecognizer)
                }
            }
        }
    }
    
    func setupDataByNewfeed(_ newsfeed: Post) -> Void {
        thisPost = newsfeed
        
        self.heightSuggestView = PostManager.getSuggestionCellHeight(self.thisPost)
        
		if let author = newsfeed.user {
			self.labelNameUser.text = author.displayName
			
			self.avatarView.setupViewByUser(author, isMerchant: (newsfeed.isMerchantIdentity.rawValue == 1))

            self.diamondImageView.isHidden = !(thisPost.isMerchantIdentity != .fromContentManager && author.isCurator == 1)
		}
		
		
        self.timeStampLabel.text = newsfeed.timeString()
        
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
        
        self.formatDescription(self.descriptionLabel, post: newsfeed, fontSize: 14)
        if let skuelist = newsfeed.skuList, skuelist.count > 0 {
           
            self.dataProviderSku.post = newsfeed
            self.dataProviderSku.referrerUserKey = referrerUserKey.length > 0 ? referrerUserKey : thisPost.user?.userKey
            self.suggestCollectionView.reloadData()
        }
        if let images =  newsfeed.images,images.count > 0{
            self.postImageView.isHidden = true
            self.tagLayerView.isHidden = true
        }
        self.setNeedsLayout()
        DispatchQueue.main.async {
            self.layoutSubviews()
        }
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
                self.delegate?.didClickedFollowMerchant(merchant, isGoingToFollow: !currentFollowing) //inverse current state
                return
            }
        }
        
        if let author = thisPost.user {
            self.followButton.showLoading()
            let currentFollowing = isFollowingUser(author)
            self.delegate?.didClickedFollowUser(author, isGoingToFollow: !currentFollowing)
        }
        
    }
    
    func isLoadingMerchant(_ merchant: Merchant) -> Bool{
        return FollowService.instance.cachedLoadingMerchantIds.contains(merchant.merchantId)
    }
    
    func isLoadingUser(_ user: User) -> Bool{
        return FollowService.instance.cachedLoadingUserKeys.contains(user.userKey)
    }
    
    func isFollowingMerchant(_ merchant: Merchant) -> Bool{
        return FollowService.instance.cachedFollowingMerchantIds.contains(merchant.merchantId)
    }
    
    func isFollowingUser(_ user: User) -> Bool{
        return FollowService.instance.cachedFollowingUserKeys.contains(user.userKey)
    }
    
    private func setupTagTitle(_ tag: ProductTagView, sku: Sku) {
        tag.tagTitleLabel.text = sku.brandName
	}
    
    //Set Original User Post
    func setUserShareSource(_ userShare: User?) {
        if let user = userShare {
            
            let strings = String.localize("LB_CA_POST_SHARE_WHOSE_POST").components(separatedBy: "{0}")
            var userSourceSubText1 = ""
            var userSourceSubText2 = ""
            var userDisplayName = user.displayName
            if userDisplayName.length > 20 {
                userDisplayName = userDisplayName.subStringToIndex(20)
            }
            if strings.count > 1 {
                userSourceSubText1 = strings[0]
                userSourceSubText2 = strings[1]
            }
            
            //Make sure font is not null
            if let fontRegular = UIFont(name: "PingFangSC-Regular", size: 14), let fontMedium = UIFont(name: Constants.Font.Bold, size: 14) {
                
                let fontRegularAttribute = [
                    NSAttributedStringKey.font : fontRegular,
                    NSAttributedStringKey.foregroundColor : UIColor.secondary2()
                ]
                let fontMediumAttribute = [
                    NSAttributedStringKey.font : fontMedium,
                    NSAttributedStringKey.foregroundColor : UIColor.secondary2()
                ]
                
                let attributedSubText1 = NSMutableAttributedString(string:userSourceSubText1, attributes: fontRegularAttribute)
                let attributedDisplayName = NSMutableAttributedString(string:" \(userDisplayName)", attributes: fontMediumAttribute)
                let attributedSubText2 = NSMutableAttributedString(string:" \(userSourceSubText2)", attributes: fontRegularAttribute)
                
                attributedSubText1.append(attributedDisplayName)
                attributedSubText1.append(attributedSubText2)
                self.userSourceLabel.attributedText = attributedSubText1
            } else {
                self.userSourceLabel.text = userSourceSubText1 + " " + userDisplayName + " " + userSourceSubText2
            }
            
            
        }
    }

    //MARK: - Actions
    func didBuySuccess (_ parentOrder: ParentOrder) {
        
    }
    
    @objc func tapMechantBahalf(_ sender: Any){
        if let merchant = thisPost.merchant{
            self.delegate?.didSelectMerchant(merchant)
        }
    }
    
    func didSelectSkuAtIndexPath(_ indexPath: IndexPath) {
        if let sku = thisPost.skuList?[indexPath.row] {
            //Analytic
            let actionRecord = AnalyticsManager.createActionRecord(analyticsViewKey: self.analyticsViewKey ?? "", analyticsImpressionKey: self.analyticsImpressionKey ?? "", actionTrigger: .Tap, sourceRef: sku.styleCode, sourceType: .Product, targetRef: "PDP", targetType: .View)
            AnalyticsManager.sharedManager.recordAction(actionRecord)
            self.delegate?.didSelectSku(sku, post: thisPost, referrerUserKey: self.referrerUserKey)
        }
    }
    
    func didSelectUserAtIndexPath(_ indexPath: IndexPath, isLike: Bool) {
        var user:User
        
        if isLike {
            var likeList = thisPost.likeList
            if PostManager.isLikeThisPost(thisPost) {
                let index = likeList.index(where: { (likedUser) -> Bool in
                    return likedUser.userKey == Context.getUserKey() //we have the item in like list
                })
                if index == nil {
                    likeList.append(Context.getUserProfile())
                }
            }
            user = likeList[indexPath.row]
        } else {
            user = thisPost.userList[indexPath.row]
        }
        self.delegate?.didSelectUser(user)
    }
    
    func didClickUserProfile(_ tapGesture: UITapGestureRecognizer) {
        if let comments = self.thisPost.postCommentLists {
            if let comment = comments.filter({$0.statusId != Constants.StatusID.deleted.rawValue}).last {
                let user = User()
                user.userKey = comment.userKey
                user.userName = comment.userName
                self.delegate?.didClickUserProfile(user)
            }
        }
    }
    
    
    @objc func didClickImagePost() {
		self.toggleTagsVisible()
        if let topVC = Utils.findActiveNavigationController()?.viewControllers[0] {
            topVC.view.endEditing(true)
        }
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
            showProductDetailPage(sku: sku)
        }
    }
    
    func showProductDetailPage(sku: Sku) {
        
        SearchService.searchStyleBySkuId(sku.skuId) { (response) in
            
            
            if response.result.isSuccess {
                if response.response?.statusCode == 200 {
                    if let styleResponse = Mapper<SearchResponse>().map(JSONObject: response.result.value) {
                        if let pageData = styleResponse.pageData {
                            if pageData.count > 0 {
                                if pageData.first != nil  {
                                    let style = Style()
                                    style.styleCode = sku.styleCode
                                    style.merchantId = sku.merchantId
                                    let styleViewController = StyleViewController(style: style)
                                    PushManager.sharedInstance.getTopViewController().navigationController?.pushViewController(styleViewController, animated: true)
                                } else {
                                    ErrorLogManager.sharedManager.recordNonFatalError(withException: .NullPointer)
                                }
                            } else {
                                let styleViewController = StyleViewController(isProductActive: false)
                                
                                PushManager.sharedInstance.getTopViewController().navigationController?.pushViewController(styleViewController, animated: true)
                            }
                        } else {
                            ErrorLogManager.sharedManager.recordNonFatalError(withException: .NullPointer)
                        }
                    } else {
                        ErrorLogManager.sharedManager.recordNonFatalError(withException: .FailToParseAPIResponse)
                    }
                }
            }
        }
    }
    
	deinit {
		NotificationCenter.default.removeObserver(self)
	}
    
    @objc func didClickUserSource() {
        if let user = thisPost.userSource {
            self.delegate?.didSelectUser(user)
        }
    }
    
    @objc func openAuthorProfile() {
        if thisPost.isMerchantIdentity == .fromContentManager {
            if let merchant = thisPost.merchant {
                thisPost.merchant?.merchantId = thisPost.merchantId
                self.delegate?.didSelectMerchant(merchant)
            }
        } else if let user = thisPost.user {
            self.delegate?.didSelectUser(user)
        }
    }
    
    
    
    func setUserSource(_ userSource: User?) {
        
        self.labelNameUser.sizeToFit()

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
        labelNameUser.frame = labelNameUserFrame
        
        var merchantBahalfButtonFrame = merchantBahalfButton.frame
        merchantBahalfButtonFrame.origin.x = self.labelNameUser.frame.maxX + MarginUserName.left
        merchantBahalfButtonFrame.origin.y = MarginUserName.top
        merchantBahalfButtonFrame.size.width = merchantTagWidth
        merchantBahalfButtonFrame.size.height = ViewDefaultHeight.HeightTagMerchant
        merchantBahalfButton.frame = merchantBahalfButtonFrame
        merchantBehalfName.frame = CGRect(x: (merchantBahalfButton.frame.sizeWidth - merchantBehalfName.frame.sizeWidth)/2, y: (merchantBahalfButton.frame.sizeHeight - merchantBehalfName.frame.sizeHeight)/2, width: merchantBehalfName.frame.sizeWidth, height: merchantBehalfName.frame.sizeHeight)
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
    
    //MARK: - Class function
    
    // Height Calculation
    class func getCellHeight(_ post: Post) -> CGFloat {
        var heightPhoto:CGFloat = ScreenWidth
        if let images = post.images,images.count > 0{
            heightPhoto = 0
        }
        let heightUserView = ViewDefaultHeight.HeightUserView
        let heightUserSource = post.userSource != nil ? ViewDefaultHeight.HeightUserSource + 5 : 5
        let bottomLineHeight: CGFloat = 10
        let postDescription = BasePostCollectionViewCell.getTextByRemovingAppUrls(post.postText)
        
        var descriptionHeight =  NewsFeedDetailCell.getHeightDescription(postDescription)
        
        var heighSkuListView = PostManager.getSuggestionCellHeight(post)
        if heighSkuListView > 0 {
            heighSkuListView = heighSkuListView + ViewDefaultHeight.HeightRelatedProductView
        }
        descriptionHeight = descriptionHeight + Margin.bottomOfDescription
        
        return heightPhoto + heightUserView + descriptionHeight + heighSkuListView + heightUserSource + bottomLineHeight
        
    }
    
    override func didClickOnHashTag(_ tag: String) {
        self.delegate?.didClickOnHashTag(tag)
    }

    override func didClickURL(_ url: String) {
        self.delegate?.didClickOnURL(url)
    }
}
class NewsFeedDetailImagesCell:UICollectionViewCell,TagViewDelegate{
    var contentImageBlack: ((_ contentImageViewSize:CGSize) -> ())?
    var hiddenTag: Bool = false
    var images:Images?{
        didSet{
            if let image = images?.upImage{
                self.contentImageView.image = image
            }
            contentImageView.removeAllSubviews()
            
            if images?.skuList == nil && images?.brandList == nil{
                if let tags = images?.tags{
                    var skuList = [Sku]()
                    var brandList = [Brand]()
                    for index in 0..<tags.count{
                        let tagList = tags[index]
                        if tagList.postTag == .Commodity {
                            if let sku = tagList.sku{
                                skuList.append(sku)
                            }
                        }else if tagList.postTag == .Brand{
                            if let brand = tagList.brand{
                                brandList.append(brand)
                            }
                        }
                    }
                    images?.skuList = skuList
                    images?.brandList = brandList
                }
            }
            
            if let skuList = images?.skuList{
                
                for index in 0..<skuList.count{
                    let sku = skuList[index]
                    if let image = images?.upImage{
                        
                        let size = CGSize(width: ScreenWidth, height: ScreenWidth * image.size.height /  image.size.width)
                        let tagPoint = ProductTagView.getTapPonit((sku.positionX, sku.positionY), imageSize: size)
                        let productTagView = ProductTagView(position: tagPoint, price: 0, parentTag: 1, delegate: self, oldPrice: 0, newPrice: 0, logoImage: UIImage(named: "logo6")!, logo: "", tagImageSize: size, skuId: sku.skuId, place : sku.place,mode:.special,tagStyle:.Commodity)
                        productTagView.tag = index
                        productTagView.isHidden = hiddenTag
                        productTagView.title = sku.brandName
                        productTagView.photoFrameIndex = 0
                        productTagView.isUserInteractionEnabled = true
                        contentImageView.addSubview(productTagView)
                    }
                }
            }
            
            if let brandList = images?.brandList{
                for index in 0..<brandList.count{
                    let brand = brandList[index]
                    if let image = images?.upImage{
                        let size = CGSize(width:ScreenWidth,height:ScreenWidth * image.size.height /  image.size.width )
                        let tagPoint = ProductTagView.getTapPonit((brand.positionX, brand.positionY), imageSize: size)
                        
                        let productTagView = ProductTagView(position:tagPoint, price: 0, parentTag: 1, delegate: self, oldPrice: 0, newPrice: 0, logoImage: UIImage(named: "logo6")!, logo: "", tagImageSize: size, skuId: brand.brandId, place : brand.place,mode:.special,tagStyle:.Brand)
                        productTagView.title = brand.brandName
                        productTagView.tag = index
                        productTagView.isHidden = hiddenTag
                        productTagView.photoFrameIndex = 0
                        productTagView.isUserInteractionEnabled = true
                        contentImageView.addSubview(productTagView)
                    }
                }
            }
        }
    }
    var contentImageViewSize:CGSize?

    func updateTag(_ tag: ProductTagView) {
        if images?.skuList == nil && images?.brandList == nil{
            if let tags = images?.tags{
                for index in 0..<tags.count{
                    let tagList = tags[index]
                    if tag.productTagStyle == .Brand {
                        let brandViewController = BrandViewController()
                        brandViewController.brand = tagList.brand
                        PushManager.sharedInstance.getTopViewController().push(brandViewController, animated: true)
                    }
                    else if tag.productTagStyle == .Commodity{
                        if let sku = tagList.sku{
                            showProductDetailPage(sku:sku)
                        }
                    }
                }
            }
        }
        if tag.productTagStyle == .Brand {
            if let brand = images?.brandList?[tag.tag]{
                let brandViewController = BrandViewController()
                brandViewController.brand = brand
                PushManager.sharedInstance.getTopViewController().push(brandViewController, animated: true)
                
            }
        }else if tag.productTagStyle == .Commodity{
            if let sku = images?.skuList?[tag.tag]{
                let style = Style()
                
                let s : Sku = sku
                if style.skuList.count == 0 {
                    s.isDefault = 1
                    style.skuList.append(s)
                }
                
                showProductDetailPage(sku: sku)
                
            }
        }
    }

    func showProductDetailPage(sku: Sku) {
        
        SearchService.searchStyleBySkuId(sku.skuId) { (response) in
            
            
            if response.result.isSuccess {
                if response.response?.statusCode == 200 {
                    if let styleResponse = Mapper<SearchResponse>().map(JSONObject: response.result.value) {
                        if let pageData = styleResponse.pageData {
                            if pageData.count > 0 {
                                if pageData.first != nil {
                                    let style = Style()
                                    style.styleCode = sku.styleCode
                                    style.merchantId = sku.merchantId
                                    let styleViewController = StyleViewController(style: style)
                                    PushManager.sharedInstance.getTopViewController().navigationController?.pushViewController(styleViewController, animated: true)
                                } else {
                                    ErrorLogManager.sharedManager.recordNonFatalError(withException: .NullPointer)
                                }
                            } else {
                                let styleViewController = StyleViewController(isProductActive: false)
                                
                                PushManager.sharedInstance.getTopViewController().navigationController?.pushViewController(styleViewController, animated: true)
                            }
                        } else {
                            ErrorLogManager.sharedManager.recordNonFatalError(withException: .NullPointer)
                        }
                    } else {
                        ErrorLogManager.sharedManager.recordNonFatalError(withException: .FailToParseAPIResponse)
                    }
                }
            }
        }
    }
    lazy var contentImageView:UIImageView = {
        let contentImageView = UIImageView()
        contentImageView.isUserInteractionEnabled = true
        return contentImageView
    }()
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        
        self.backgroundColor = UIColor.white
        createUI()
        
        self.addGestureRecognizer(UILongPressGestureRecognizer(target: self, action: #selector(self.handleLongPressOnPostImage)))
        
        contentImageView.whenTapped {
            self.hiddenTag = !self.hiddenTag
            for tag in self.contentImageView.subviews{
                if tag.isKind(of: ProductTagView.self){
                    tag.isHidden = !tag.isHidden
                }
            }
        }
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    func createUI() {
        self.addSubview(contentImageView)
        
        contentImageView.snp.makeConstraints { (make) in
            make.edges.equalTo(self)
        }
    }
    
    // MARK: - Handle Long Press Gesture on Product Image
    @objc func handleLongPressOnPostImage(gesture: UILongPressGestureRecognizer) -> Void {
        if gesture.state == UIGestureRecognizerState.began {
            let optionMenu = UIAlertController(title: nil, message: nil, preferredStyle: .actionSheet)
            let saveAction = UIAlertAction(title: String.localize("LB_SAVE"), style: .default, handler: { (alert: UIAlertAction!) -> Void in
                if let image = self.images?.upImage{
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
}
