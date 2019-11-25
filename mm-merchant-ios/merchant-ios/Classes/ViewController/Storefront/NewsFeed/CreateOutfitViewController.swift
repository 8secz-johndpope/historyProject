//
//  CreateOutfitViewController.swift
//  merchant-ios
//
//  Created by Vu Dinh Trung on 4/8/16.
//  Copyright © 2016 WWE & CO. All rights reserved.
//

import UIKit
import Photos
import PromiseKit
import ObjectMapper
import Kingfisher

class StyleCell: NSObject {
    var imageIcon : UIImage?
    var text: String?
    var tagList: String?
    
    init(imageicon: String, text: String, tagList: String) {
        super.init()
        self.imageIcon = UIImage(named: imageicon)
        self.text = text
        self.tagList = tagList
    }
    
}

enum StageMode : Int {
    case firstStage = 0,
    secondStage
}
enum TagButton: Int {
    case buttonCamera = 101
}
enum ModeGetTagList: Int {
    case brandTagList = 0,
    friendTagList,
    wishlistTag
}

enum TypeMerchant: Int {
    case ambassador = 9
    case contentManager = 8
    case undefined = -1
}

class CreateOutfitViewController: MmViewController, GalleryViewControllerDelegate,TagCollectionViewDelegate, OutfitBrandSelectionViewControllerDelegate, AmbassadorPostingViewControllerDelelgate, HashTagViewDelegate, AddTopicDelegate {
    
    var textViewDescription = MMPlaceholderTextView()
    var line = UIView()
    var hashTagView = HashTagView()
    
    var viewTagMerchant = UIView()
    var imageViewIconMerchant = UIImageView()
    var labelMerchantTag = UILabel()
    var buttonAdd = UIButton()
    
    var viewTagUser = UIView()
    var imageViewIconFriend = UIImageView()
    var labelUserTag = UILabel()
    
    var buttonCamera = UIButton()
    var buttonTakePhoto = UIButton()
    var labelTitleButton = UILabel()
    
    var shareBarView = UIView()
    var shareToLabel = UILabel()
    var shareToWeChatWallBtn = UIButton(type: .custom)
    var shareToWeiboBtn = UIButton(type: .custom)
    var shareToQQBtn = UIButton(type: .custom)
    var shareToWeChatFriendBtn = UIButton(type: .custom)
    var tapHideKeyBoard: UITapGestureRecognizer? = nil
    var styles = [StyleCell]()
    
    private final let HeightOfDecriptionView: CGFloat = 120.0
    private final let MarginViewTop:CGFloat = 64.0
    private final let HeightOfTagView:CGFloat = 50.0
    private final let CellHeight: CGFloat = 50.0
    private final let CellId = "CellId"
    private final let IdentifierMainCell = "IdentifierMainCell"
    private final let SizeButtonCamera: CGFloat = 51.0
    private final let SizeButtonClose: CGFloat = 25.0
    
    private final let widthButtonTakePhoto:CGFloat = 81
    private final let heightButtonTakePhoto:CGFloat = 31
    private final let heightTopView : CGFloat = 20
    
    var currentStage = StageMode.firstStage
    
    var labelEdit = UILabel()
    var imageViewFinish = UIImageView()
    var imageViewBack = UIView()
    
    var scrollView = UIScrollView()
    var imageCrop = UIImage()
    var selectedMerchantsIndex = [Int]()
    var selectedFriendsIndex = [Int]()
    
    var selectedMerchants = [Merchant]()
    var selectedFriends = [User]()
    
    var productTagViews = [ProductTagView]()
    
    var postId : String!
    
    var isFrom = ModeTagProduct.productListPage
    
    var groupKey : String = ""
    
    var labelLimitCharacter : UILabel!
    var topView : UIView!
    var selectedHashTag: String? = nil
    var postedHashTag = [String]()
    var figureChoose = false
    var images : [Images]?
    
    override func viewDidLoad() {
        super.viewDidLoad()
        super.pageAccessibilityId = "PostEditorPage"
        
        NotificationCenter.default.addObserver(self, selector: #selector(CreateOutfitViewController.updateTagArrays), name: Constants.Notification.updateTagArraysForPost, object: nil)
        
        self.title = String.localize("LB_CA_EDIT_POST")
        self.createBackButton()
        self.createRightButton(String.localize("LB_CA_POST_PUBLISH"), action: #selector(CreateOutfitViewController.handleRightButton), isEnable: true)
        self.initAnalyticLog()
        
        setupScrollView()
        styleDescriptionView()
        setupTopView()
        setupShareBar()
        setupLine()
        setupHashTagView()
        setupStage()
        setupDismissKeyboardGesture()
        
        if let postDescription = CacheManager.sharedManager.postDescription {
            textViewDescription.text = postDescription
            formatHashTag(isTypingKeyboard: false)
        } else if let selectedHashTag = self.selectedHashTag {
            textViewDescription.text = "\(selectedHashTag) "
            formatHashTag(isTypingKeyboard: false)
        }
        self.listFeatureTags()
        
        
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        
        textViewDescription.becomeFirstResponder()
        
    }
    
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        
    }
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        self.title = ""
        CacheManager.sharedManager.postDescription = self.textViewDescription.text
    }
    
    deinit {
        NotificationCenter.default.removeObserver(self, name: Constants.Notification.updateTagArraysForPost, object: nil)
    }
    
    @discardableResult
    private func listFeatureTags() -> Promise<Any> {
        return Promise{ fulfill, reject in
            HashTagService.listFeatureTags(.Post, completion: { [weak self] (response) in
                if let strongSelf = self {
                    if response.result.isSuccess {
                        if let hashTagData = Mapper<HashTagList>().map(JSONObject: response.result.value) {
                            if let hashTagList = hashTagData.pageData {
                                
                                strongSelf.hashTagView.datasources = Array(hashTagList.prefix(Constants.Value.MaximumOfficalHashTag))
                                strongSelf.hashTagView.frame = CGRect(x:0, y: strongSelf.line.frame.maxY, width: strongSelf.view.width, height: hashTagList.count > 0 ? HashTagView.ViewHeight : HashTagView.EmptyTagViewHeight)
                                
                                strongSelf.layoutSubView()
                            }
                            
                        }
                        fulfill("OK")
                    } else {
                        reject(response.result.error ?? strongSelf.getError(response))
                    }
                }
            })
        }
    }
    
    
    func renderTagProduct(array: [ProductTagView]) {
        
        // remove previous tags
        for tag in self.productTagViews {
            tag.removeFromSuperview()
        }
        
        // populate tags on imageViewFinish
        self.populateTagsOnFinalImage(array, finalImage: imageViewFinish)
        
    }
    
    @objc func updateTagArrays(notification: NSNotification) {
        
        // remove previous tags
        for tag in self.productTagViews {
            tag.removeFromSuperview()
        }
        
        if let tags : [ProductTagView] = notification.object as? [ProductTagView] {
            self.productTagViews = tags
            
            // populate tags on imageViewFinish
            self.populateTagsOnFinalImage(self.productTagViews, finalImage: imageViewFinish)
            
        }
        
    }
    
    // populate tags on imageViewFinish
    func populateTagsOnFinalImage(_ tags: [ProductTagView], finalImage: UIImageView) {
        guard tags.count > 0  || finalImage.image != nil else { return }
        
        for i in 0 ..< tags.count {
            if let tag = tags[i] as ProductTagView? {
                Log.debug("finalLocation : \(tag.finalLocation)")
                
                tag.isUserInteractionEnabled = false
                
                tag.mode = .view
                //                tag.pinImageView.image = UIImage(named: "RedDot")
                
                if !tag.shouleBeHidden {
                    finalImage.addSubview(tag)
                }
                
            }
        }
    }
    
    //MARK: style UI
    
    func setupScrollView() -> Void {
        self.view.addSubview(scrollView)
        self.scrollView.frame = CGRect(x:0, y: MarginViewTop, width: self.view.frame.width, height: ScreenSize.height - MarginViewTop)
    }

    override func backButtonClicked(_ button: UIButton) {
        super.backButtonClicked(button)
    }
    
    
    private let ShareBarSize : CGFloat = 44.0
    
    func setupShareBar() {
        
        shareToLabel.text = String.localize("LB_CA_SHARE_TO")
        shareToLabel.formatSize(12)
        shareToLabel.numberOfLines = 1
        shareToLabel.frame = CGRect(x:Margin.left, y: 0, width: 80, height: ShareBarSize)
        let size = shareToLabel.sizeThatFits(shareToLabel.frame.size)
        shareToLabel.frame = CGRect(x:Margin.left, y: 0, width: size.width, height: ShareBarSize)
        
        shareBarView.addSubview(shareToLabel)
        
        shareToWeChatWallBtn.setImage(UIImage(named: "wechat moment-grey"), for: .normal)
        shareToWeChatWallBtn.setImage(UIImage(named: "wechat moment"), for: .selected)
        
        shareToWeChatFriendBtn.setImage(UIImage(named: "wechat_friend_grey"), for: .normal)
        shareToWeChatFriendBtn.setImage(UIImage(named: "wechatFriend"), for: .selected)
        
        shareToWeiboBtn.setImage(UIImage(named: "sina_weibo_grey"), for: .normal)
        shareToWeiboBtn.setImage(UIImage(named: "sina_weibo"), for: .selected)
        
        shareToQQBtn.setImage(UIImage(named: "qq-grey"), for: .normal)
        shareToQQBtn.setImage(UIImage(named: "qq-normal"), for: .selected)
        
        
        shareBarView.addSubview(shareToWeChatWallBtn)
        shareBarView.addSubview(shareToWeChatFriendBtn)
        shareBarView.addSubview(shareToWeiboBtn)
        shareBarView.addSubview(shareToQQBtn)
        
        shareBarView.frame = CGRect(x:0, y: self.view.size.height - ShareBarSize, width: self.view.width, height: ShareBarSize)
        shareBarView.backgroundColor = UIColor.primary2()
        
        
        shareToWeChatWallBtn.frame = CGRect(x:shareToLabel.frame.maxX, y: 0, width: ShareBarSize, height: ShareBarSize)
        shareToWeChatFriendBtn.frame = CGRect(x:shareToWeChatWallBtn.frame.maxX, y: 0, width: ShareBarSize, height: ShareBarSize)
        shareToWeiboBtn.frame = CGRect(x:shareToWeChatFriendBtn.frame.maxX, y: 0, width: ShareBarSize, height: ShareBarSize)
        shareToQQBtn.frame = CGRect(x:shareToWeiboBtn.frame.maxX, y: 0, width: ShareBarSize, height: ShareBarSize)
        
        self.view.addSubview(shareBarView)
        self.view.bringSubview(toFront: shareBarView)
        
        shareToWeChatFriendBtn.addTarget(self, action: #selector(self.toggleShareButton), for: .touchUpInside)
        shareToWeChatWallBtn.addTarget(self, action: #selector(self.toggleShareButton), for: .touchUpInside)
        shareToWeiboBtn.addTarget(self, action: #selector(self.toggleShareButton), for: .touchUpInside)
        shareToQQBtn.addTarget(self, action: #selector(self.toggleShareButton), for: .touchUpInside)
        
    }
    
    func recordShareAction(button: UIButton) {
        var targetRef = ""
        switch button {
        case shareToWeChatFriendBtn:
            targetRef = "WeChat-Friends"
            break
        case shareToWeChatWallBtn:
            targetRef = "WeChat-Moments"
        case shareToWeiboBtn:
            targetRef = "Weibo"
            break
        case shareToQQBtn:
            targetRef = "QQ-Friends"
            break
        default:
            break
        }
        
        self.view.recordAction(.Tap, sourceRef: "Share", sourceType: .Button, targetRef: targetRef, targetType: .Channel)
    }
    
    @objc func toggleShareButton(button: UIButton){
        
        self.recordShareAction(button: button)
        
        switch button {
        case shareToWeChatWallBtn, shareToWeChatFriendBtn :
            guard WXApi.isWXAppInstalled() else {
                Alert.alertWithSingleButton(self, title: "", message: String.localize("MSI_ERR_WECHAT_INSTALL"), buttonString:String.localize("LB_OK"))
                return
            }
            break
        case shareToWeiboBtn:
            guard WeiboSDK.isWeiboAppInstalled() else {
                Alert.alertWithSingleButton(self, title: "", message: String.localize("MSI_ERR_SINAWEIBO_INSTALL"), buttonString:String.localize("LB_OK"))
                return
            }
            break
        case shareToQQBtn:
            guard QQApiInterface.isQQInstalled() else {
                Alert.alertWithSingleButton(self, title: "", message: String.localize("MSI_ERR_QQ_INSTALL"), buttonString:String.localize("LB_OK"))
                return
            }
            break
        default: break
        }
        
        button.isSelected = !button.isSelected
        
    }
    
    
    func setupTopView() {
        
        // topview
        let topViewHeight = heightTopView
        let limitationLabelWidth = CGFloat(50)
        let topView = { () -> UIView in
            let view = UIView(frame: CGRect(x:0, y: textViewDescription.frame.maxY, width: self.view.frame.sizeWidth, height: topViewHeight))
            view.backgroundColor = UIColor.clear
            return view
        } ()
        self.scrollView.addSubview(topView)
        self.topView = topView
        
        let labelLimit = { () -> UILabel in
            let limitationLabel = UILabel(frame: CGRect(x:self.view.frame.sizeWidth - limitationLabelWidth - Margin.right, y: 0, width: limitationLabelWidth, height: topViewHeight))
            limitationLabel.textColor = UIColor.secondary2()
            limitationLabel.formatSize(12)
            limitationLabel.textAlignment = .right
            limitationLabel.text = String(format : "%d/%d",0, Constants.LimitNumber.LimitPostText)
            self.labelLimitCharacter = limitationLabel
            return limitationLabel
        }()
        topView.addSubview(labelLimit)
        
    }
    
    func styleDescriptionView(){
        textViewDescription.frame = CGRect(x:Margin.left, y: ScreenTop, width: self.view.width - Margin.left * 2, height: HeightOfDecriptionView - heightTopView)
        textViewDescription.placeholder = String.localize("LB_CA_POST_DESC")
        textViewDescription.format()
        textViewDescription.font = UIFont.fontWithSize(14, isBold: false)
        textViewDescription.delegate = self
        textViewDescription.layer.borderWidth = 0
        self.scrollView.addSubview(textViewDescription)
        self.setAccessibilityIdForView("UITA_POST_DESC", view: textViewDescription)
        
        tapHideKeyBoard = UITapGestureRecognizer(target: self, action: #selector(CreateOutfitViewController.shouldHiddenKeyBoard))
        tapHideKeyBoard!.cancelsTouchesInView = false
        self.scrollView.addGestureRecognizer(tapHideKeyBoard!)
    }
    
    func updateLimitCharacter(_ lenght: Int) {
        labelLimitCharacter.text = String(format : "%d/%d", lenght, Constants.LimitNumber.LimitPostText)
    }
    
    func setupLine() -> Void {
        line.backgroundColor = UIColor.primary2()
        self.scrollView.addSubview(line)
        line.frame = CGRect(x:Margin.left, y: self.textViewDescription.frame.maxY + heightTopView, width: self.view.width - Margin.left * 2, height: 1.0)
    }
    
    
    func setupStage() -> Void {
        setupSecondStage()
        
    }
    
    func setupHashTagView() {
        hashTagView.delegate = self
        self.scrollView.addSubview(hashTagView)
        hashTagView.frame = CGRect(x:0, y: self.line.frame.maxY, width: self.view.width, height: HashTagView.EmptyTagViewHeight)
        hashTagView.clipsToBounds = true
        hashTagView.analyticsViewKey = self.analyticsViewRecord.viewKey
    }
    
    
    func setupSecondStage() -> Void {
        self.imageViewFinish.image = imageCrop
        self.imageViewFinish.isUserInteractionEnabled = true
        let tapImageView = UITapGestureRecognizer(target: self, action: #selector(CreateOutfitViewController.didSelectedImageProduct))
        self.imageViewFinish.addGestureRecognizer(tapImageView)
        self.imageViewFinish.contentMode = .scaleAspectFill
        self.imageViewFinish.clipsToBounds = true
        self.scrollView.addSubview(imageViewFinish)
        
        self.imageViewBack.backgroundColor = UIColor.clear
        self.imageViewFinish.addSubview(self.imageViewBack)
        
        
        if figureChoose {
            self.imageViewBack.isHidden = false
        }else{
            self.imageViewBack.isHidden = true
        }
        setupContentSizeWithImage(imageCrop)
    }
    
    func setupContentSizeDefaul() -> Void {
        self.scrollView.contentSize = CGSize(width: self.view.frame.width, height: self.view.frame.height - MarginViewTop)
    }
    
    func setupContentSizeWithImage(_ image: UIImage) -> Void {
        let imageSize = CGFloat(100)
        self.imageViewFinish.frame = CGRect(x:Margin.left, y: self.hashTagView.frame.maxY + 10.0, width: imageSize, height: imageSize)
        self.imageViewBack.frame = CGRect(x:68, y:imageSize / 5 * 4, width:32, height:imageSize / 5)
        addIamgeNumView(superView: self.imageViewBack)
        var contentSize = self.scrollView.contentSize
        contentSize.height = self.imageViewFinish.frame.maxY
        contentSize.height = self.scrollView.height > contentSize.height ? self.scrollView.height : contentSize.height
        self.scrollView.contentSize = contentSize
        
    }
    
    func addIamgeNumView (superView:UIView ){
        let backView = UIView()
        backView.backgroundColor = UIColor.black
        backView.alpha = 0.5
        superView.addSubview(backView)
        
        let iconImageView = UIImageView()
        iconImageView.image = UIImage(named: "thumbnail_ic")
        iconImageView.sizeToFit()
        superView.addSubview(iconImageView)
        
        let numLabel = UILabel()
        if let iamge = images{
            numLabel.text = "\(iamge.count)"
        }
        
        numLabel.font = UIFont.systemFont(ofSize: 12)
        numLabel.textColor = UIColor.white
        superView.addSubview(numLabel)
        
        backView.snp.makeConstraints { (make) in
            make.edges.equalTo(superView)
        }
        numLabel.snp.makeConstraints { (make) in
            make.right.equalTo(superView).offset(-5)
            make.centerY.equalTo(superView)
        }
        iconImageView.snp.makeConstraints { (make) in
            make.right.equalTo(numLabel.snp.left).offset(-2)
            make.centerY.equalTo(superView)
        }
        
    }
    
    @objc func didSelectedImageProduct(gesture: UITapGestureRecognizer) -> Void {
        
        if isFrom == .productListPage || isFrom == .productDetailPage || isFrom == .profilePage || isFrom == .wishlist {
            self.didSelectEditButton()
            return
        }
        
        if let imageCrop = self.imageViewFinish.image {
            
            let imageSize = self.imageViewFinish.frame.size
            
            let touchPoint = gesture.location(in: self.imageViewFinish)
            
            let tagPercentage = ProductTagView.getTapPercentage(touchPoint)
            
            let tagEditorView = TagEditorViewController(imageCrop: imageCrop, tagPercentage: tagPercentage, imageSize: imageSize, tagArrays: productTagViews)
            
            self.navigationController?.pushViewController(tagEditorView, animated: true)
            
        }
    }
    
    
    @objc func shouldHiddenKeyBoard(tapGesture: UITapGestureRecognizer) -> Void {
        let point = tapGesture.location(in: self.hashTagView)
        let isInsideHashTagView = self.hashTagView.bounds.contains(point)
        if !isInsideHashTagView {
            self.view.endEditing(true)
        }
    }
    
    
    func checkMerchantType(securityGroups: [MerchantRoles]) -> TypeMerchant {
        if securityGroups.count > 0 {
            for item in securityGroups {
                if item.roles.count > 0 {
                    if item.roles.contains(TypeMerchant.ambassador.rawValue) {
                        return TypeMerchant.ambassador
                    } else if (item.roles.contains(TypeMerchant.contentManager.rawValue)) {
                        return TypeMerchant.contentManager
                    }
                }
            }
            
        }
        return TypeMerchant.undefined
    }
    
    private var sharingPost : Post? = nil
    
    func handlePost(_ merchantId: Int = -1, merchant: Merchant? = nil, includeSelf: Bool = false) -> Post {
        if !(imageViewFinish.image != nil) {
            imageViewFinish.image = UIImage()
        }
        
        let post = Post()
        post.userKey = Context.getUserKey()
        post.postText = textViewDescription.text.trimmingCharacters(in: CharacterSet.whitespacesAndNewlines)
        post.merchantList = selectedMerchants
        post.userList = selectedFriends
        post.pendingUploadImage = imageViewFinish.image //it is important for upload image as well
        post.merchant = merchant
        
        if figureChoose {
            post.feature = "1"
        }else{
            post.feature = "0"
        }
        
        // only post the non-hidden Tag's sku
        var tags = [ProductTagView]()
        for i in 0 ..< self.productTagViews.count {
            let tag : ProductTagView = self.productTagViews[i] as ProductTagView
            if !tag.shouleBeHidden {
                tags.append(tag)
            }
        }
        
        if !figureChoose {
            if images != nil {
                let imageList = images![0]
                imageList.upImage = post.pendingUploadImage
            }
            
            
        }
        
        post.images = images
        
        
        if images != nil {
            post.images = images
            if let iamge = post.images![0].image{
                post.postImage = iamge
            }
            
            
            if !figureChoose {
                post.skuList = tags.map({ (tagProduct) -> Sku in
                    return tagProduct.getSku()
                })
            }else{
                post.getSkus()
            }
        }
        //We do morething to ensure we can have local cache display correctly.
        
        if merchantId != -1 {
            post.merchantId = merchantId
            post.groupKey = groupKey
            let user = Context.getUserProfile()
            let securityGroups = user.formattedUserMerchantSecurityGroupArray
            for item in securityGroups {
                if item.roles.count > 0 {
                    if item.merchantId == merchantId{
                        if item.roles.contains(TypeMerchant.contentManager.rawValue) {
                            post.isMerchantIdentity = MerchantIdentity.fromContentManager
                        }
                        else{
                            post.isMerchantIdentity = MerchantIdentity.fromAmbassador
                        }
                        break
                    }
                }
            }
        }
        
        if includeSelf {
            post.groupKey = self.groupKey
        }
        
        self.addNewFeedPost(post)
        
        return post
    }
    
    func sharePost() {
        
        var shareOptions : [ShareMethod] = []
        if shareToWeChatWallBtn.isSelected { shareOptions.append(ShareMethod.weChatMoment) }
        if shareToWeiboBtn.isSelected { shareOptions.append(ShareMethod.weiboWall) }
        if shareToQQBtn.isSelected { shareOptions.append(ShareMethod.qqMessage) }
        if shareToWeChatFriendBtn.isSelected { shareOptions.append(ShareMethod.weChatMessage) }
        
        guard sharingPost != nil else {
            return //no stored instance. drop
        }
        
        var identity = SharePostIdentity.myself
        if let merchant = sharingPost!.merchant, sharingPost!.isMerchantIdentity == .fromContentManager {
            identity = SharePostIdentity.merchant(merchantName: merchant.merchantName)
        }
        
        ShareManager.sharedManager.sharePost(sharingPost!, shareIdentity: identity, postImage: sharingPost!.pendingUploadImage, methods: shareOptions, referrer: Context.getUserKey())
        
    }
    
    //MARK: - Keyboard notification
    
    override func keyboardWillHideNotification(_ notification: NSNotification) {
        super.keyboardWillShowNotification(notification)
        collectionView.contentInset = UIEdgeInsets.zero
        collectionView.scrollIndicatorInsets = UIEdgeInsets.zero
        
        shareBarView.frame = CGRect(x:0, y: self.view.frame.height - ShareBarSize, width: self.view.width, height: ShareBarSize)
        
    }
    
    override func keyboardWillShowNotification(_ notification: NSNotification) {
        super.keyboardWillShowNotification(notification)
        if let keyboardSize = notification.userInfo?[UIKeyboardFrameEndUserInfoKey] as? CGRect {
            
            let contentInsets = UIEdgeInsets(top: 0.0, left: 0.0, bottom: keyboardSize.height, right: 0.0)
            
            scrollView.contentInset = contentInsets
            scrollView.scrollIndicatorInsets = contentInsets
            
            shareBarView.frame = CGRect(x:0, y: self.view.frame.height - contentInsets.bottom - ShareBarSize, width: self.view.width, height: ShareBarSize)
            
            self.view.bringSubview(toFront: shareBarView)
        }
        
        
    }
    
    //MARK:- HashTagView Delegate
    func hashTagViewAddTopic() {
        let vc = AddTopicViewController()
        vc.delegate = self
        self.present(vc, animated: true, completion: nil)
    }
    
    func selectedHashTag(tag: String) {
        self.hashTagViewSelectedTag(tag)
        self.postedHashTag.append(tag)
    }
    
    func hashTagViewSelectedTag(_ item: String) {
        
        self.postedHashTag.append(item)
        
        let maxLength = Constants.LimitNumber.LimitPostText
        let currentString = textViewDescription.text ?? ""
        
        var newTag = item
        
        let newString = currentString + newTag
        if newString.length <= maxLength {
            
            var range: NSRange = textViewDescription.selectedRange
            let firstHalfString = textViewDescription.text.subStringToIndex(range.location)
            
            //To make sure won't duplicated '#'
            if firstHalfString.last == "#" && newTag.hasPrefix("#") {
                newTag.remove(at: newTag.startIndex)
            }
            
            let secondHalfString = textViewDescription.text.subStringFromIndex(range.location)
            
            textViewDescription.text = "\(firstHalfString)\(newTag)\(secondHalfString)"
            let lengthNewTag = (newTag as NSString).length
            range.location += lengthNewTag
            textViewDescription.selectedRange = range
            
            updateLimitCharacter(newString.length)
            self.formatHashTag(isTypingKeyboard: false)
        }
        
        if !textViewDescription.isFirstResponder {
            textViewDescription.becomeFirstResponder()
        }
        
    }
    
    func formatHashTag(isTypingKeyboard: Bool) {
        
        if let selectedTextRange = textViewDescription.markedTextRange, isTypingKeyboard {
            if !selectedTextRange.isEmpty {
                return
            }
        }
        
        //Back up selected range
        let selectedRange = textViewDescription.selectedRange
        let text = textViewDescription.text ?? ""
        
        let attributedString = NSMutableAttributedString(string:text)
        
        attributedString.addAttributes([NSAttributedStringKey.font : UIFont.fontWithSize(14, isBold: false)], range: NSRange(location: 0, length: (text as NSString).length))
        
        textViewDescription.textColor = UIColor.black
        
        //Hight Light URLs first
        do {
            let detector = try NSDataDetector(types: NSTextCheckingResult.CheckingType.link.rawValue)
            let matchesURLs = detector.matches(in: text, options:[], range:NSRange(location: 0, length: (text as NSString).length))
            for match in matchesURLs {
                attributedString.addAttribute(NSAttributedStringKey.foregroundColor, value: UIColor(hexString: "#507DAF"), range: match.range)
            }
        } catch _ {
            Log.debug("Highlight URL Error")
        }
        
        let ranges = text.rangeMatches(pattern:RegexManager.ValidPattern.HashTag, exclude:RegexManager.ValidPattern.ExcludeHttp)
        for range in ranges {
            attributedString.addAttribute(NSAttributedStringKey.foregroundColor, value: UIColor.hashtagColor(), range: range)
            attributedString.addAttribute(NSAttributedStringKey.font, value: UIFont.fontWithSize(14, isBold: true), range: range)
            textViewDescription.attributedText = attributedString
        }
        
        textViewDescription.attributedText = attributedString
        
        //Restore selected range
        textViewDescription.selectedRange = selectedRange
    }
    
    
    //MARK: - Post
    
    func updateLatestUserMerchantInfo() -> Promise<Any> {
        return Promise{ fulfill, reject in
            UserService.view() { (response) in
                if response.result.isSuccess {
                    if response.response?.statusCode == 200 {
                        if let user = Mapper<User>().map(JSONObject: response.result.value){
                            Context.saveUserProfile(user)
                        }
                        fulfill("OK")
                    } else {
                        var statusCode = 0
                        if let code = response.response?.statusCode {
                            statusCode = code
                        }
                        
                        let error = NSError(domain: "", code: statusCode, userInfo: nil)
                        reject(error)
                    }
                } else {
                    if let error = response.result.error {
                        reject(error)
                    } else {
                        reject(NSError(domain: "Unidentified", code: 9999, userInfo: nil))
                    }
                }
            }
        }
    }
    func compareHashTag(){
        let hashTags = RegexManager.matchesForRegexInText(RegexManager.ValidPattern.HashTag, text: self.textViewDescription.text, hashTag: true)
        
        for postedTag in self.postedHashTag {
            for tag in hashTags {
                if (tag != postedTag) {
                    self.postedHashTag.append(tag)
                }
            }
        }
    }
    
    @objc func handleRightButton(sender: UIBarButtonItem) {
        Log.debug("Post action")
        self.setRightButtonEnable(false)
        showLoading()
        firstly {
            return self.updateLatestUserMerchantInfo()
            }.then { (_) -> Void in
                self.showAmbassadorViewController()
            }.always {
                self.stopLoading()
                self.compareHashTag()
                
            }.catch { _ -> Void in
                Log.error("error")
                self.stopLoading()
                self.setRightButtonEnable(true)
        }
        
        
        //record action
        sender.recordAction(
            .Tap,
            sourceRef: "Publish",
            sourceType: .Button,
            targetRef: "MyProfile",
            targetType: .View)
    }
    
    func showAmbassadorViewController(){
        
        let user = Context.getUserProfile()
        let securityGroups = user.formattedUserMerchantSecurityGroupArray
        let ambassadorVC = AmbassadorPostingViewController()
        
        var merchantChoices = 0
        
        for item in securityGroups {
            if item.roles.count > 0 {
                if (item.roles.contains(TypeMerchant.contentManager.rawValue) || item.roles.contains(TypeMerchant.ambassador.rawValue)) {
                    //add merchant to list
                    let merchants = user.merchants.filter({$0.merchantId == item.merchantId && $0.statusId == Constants.StatusID.active.rawValue})
                    if merchants.count > 0{
                        ambassadorVC.merchants.append(contentsOf: merchants)
                        merchantChoices += 1
                    }
                }
            }
        }
        
        if merchantChoices == 0 {
            self.sharingPost = handlePost(-1, includeSelf: true)
            return
        }
        
        ambassadorVC.ambassdorPostingDelegate = self
        self.present(ambassadorVC, animated: false, completion: nil)
    }
    
    func cancelSendPost(){
        self.setRightButtonEnable(true)
    }
    
    func sendPost(_ merchants: [Merchant], includeSelf: Bool) {
        if merchants.count > 0 || includeSelf {
            self.groupKey = Utils.UUID()
            for i in 0 ..< merchants.count {
                let post = handlePost(merchants[i].merchantId, merchant: merchants[i])
                if sharingPost == nil || sharingPost?.isMerchantIdentity == MerchantIdentity.fromContentManager { //replace the stored instance if the stored instance is from content manager (not prefer)
                    sharingPost = post
                }
            }
            if includeSelf {
                self.sharingPost = handlePost(-1, includeSelf: true)
            }
        } else {
            self.groupKey = ""
            self.sharingPost = handlePost()
        }
    }
    
    //MARK: - Post NewsFeed API
    func addNewFeedPost(_ postData: Post) {
        if let image = postData.pendingUploadImage {
            autoreleasepool {
                if (image.size.width * image.scale) > CGFloat(Constants.MaxImageWidth) {
                    if let compressedImage = image.resizeWithWidth(CGFloat(Constants.MaxImageWidth)){
                        if let data = UIImageJPEGRepresentation(compressedImage, 0.9) {
                            postData.pendingUploadImage = UIImage(data: data)
                        }
                        
                    }
                }
            }
        }
        self.showLoading()
        
        self.handlePopToView()
        
        if let images = images {
            
            PostManager.uploadPostImageWithRetry(post: postData, retry: 0, imageNum: images.count, tagImages: images, postCallback: {(post) in
                
                self.createPost(postData:post)
                
            })
        }
    }
    func createPost(postData:Post)  {
        PostManager.createNewPost(postData).then { postId -> Void in
            
            CacheManager.sharedManager.postDescription = nil
            let postId : Int = Int(postData.postId)
            //            let postIdString = String(postId)
            postData.statusId = Constants.StatusID.active.rawValue
            postData.postId = postId
            if postData.merchantId != 0 {
                PostManager.insertLocalPost(merchantId: postData.merchantId, post: postData)
            } else {
                PostManager.insertLocalPost(postData.userKey, post: postData)
                
            }
            
            if let imagesList = postData.images{
                
                for image in imagesList{
                    if let image = image.image{
                        KingfisherManager.shared.cache.removeImage(forKey: ImageURLFactory.URLSize1000(image, category: .post).absoluteString, processorIdentifier: "", fromDisk: true, completionHandler: nil)
                    }
                }
            }
            self.stopLoading()
            DropDownBanner.backgroundColor = UIColor.black
            DropDownBanner.titleColor = UIColor.white
            DropDownBanner.subtitleColor = UIColor.white
            let image = Merchant().MMImageIconBlack
            let title = "发帖成功"
            
            let announcement = Announcement(title: title, subtitle: "", image: image, duration: 1, action: nil, swipeToDismiss: nil)
            
            shoutView.show(announcement, completion: nil)
            
            //            PostManager.uploadPostImageWithRetry(postData.pendingUploadImage, postId: postIdString, post: postData, retry: 3)
            
            self.stopLoading()
            //            self.handlePopToView()
            }.always {
                self.stopLoading()
                self.setRightButtonEnable(true)
                self.handleHashTag()
            }.catch { error -> Void in
                Log.error("error")
                
                if let errMsg = (error as NSError).userInfo[NSLocalizedDescriptionKey] as? String {
                    self.showFailPopupWithText(String.localize(errMsg))
                }
        }
        
    }
    func handleHashTag() {
        var historyHashTags = Context.historyHashtags
        for tag in self.postedHashTag {
            let text = tag.replacingOccurrences(of: " ", with: "")
            if !historyHashTags.contains(text) && text.length > 0 {
                historyHashTags.insert(text, at: 0)
            }
        }
        Context.historyHashtags = historyHashTags
        self.postedHashTag.removeAll()
    }
    
    func setRightButtonEnable(_ enable: Bool) {
        if let rightButton = self.navigationItem.rightBarButtonItem?.customView as? UIButton {
            rightButton.isEnabled = enable
        }
    }
    
    func handlePopToView() {
        //        let presentingViewController = self.navigationController?.presentingViewController
        self.navigationController?.dismiss(animated: true, completion: {
            //            self.showSuccessPopupFromPresentingController(presentingViewController)
            self.sharePost()
        })
    }
    
    func showSuccessPopupFromPresentingController(_ presentingViewController: UIViewController?) {
        //MM-32778 Show success view when last posting time more than 24 Hours
        var lastPostedTimeMoreThan24Hours = false
        
        if let lastPostingTime = Context.getLastPostingTime() {
            let hoursPeriod = (NSDate().timeIntervalSince1970 - lastPostingTime)/3600
            if hoursPeriod >= 24 {
                lastPostedTimeMoreThan24Hours = true
            }
            
        } else {
            lastPostedTimeMoreThan24Hours = true
        }
        
        if lastPostedTimeMoreThan24Hours {
            //            let successPopupView = SuccessPopUpView(frame: CGRect.zero)
            //            successPopupView.showPopup()
        } else {
            if let tabbarController = presentingViewController as? UITabBarController{
                if let lastNavigationController = tabbarController.viewControllers?[tabbarController.selectedIndex] as? UINavigationController{
                    if let lastViewController = lastNavigationController.viewControllers.last as? MmViewController{
                        lastViewController.showSuccessPopupWithText(String.localize("MSG_SUC_POST"))
                    }
                    // =======
                    //        if let tabbarController = presentingViewController as? UITabBarController{
                    //            if let lastNavigationController = tabbarController.viewControllers?[1] as? UINavigationController{
                    //                if let lastViewController = lastNavigationController.viewControllers.last() as? MmViewController{
                    //                    lastViewController.showSuccessPopupWithText(String.localize("MSG_SUC_POST"))
                    // >>>>>>> PostFigure
                }
            }
        }
        
        Context.setLastPostingTime(Date().timeIntervalSince1970)
    }
    
    func didSelectEditButton(sender: UIButton? = nil) -> Void {
        switch self.isFrom {
        case .productListPage, .productDetailPage, .profilePage, .wishlist:
            //            NotificationCenter.default.post(name: Constants.Notification.UpdateTagArraysForPost, object: self.productTagViews)
            CacheManager.sharedManager.postDescription = self.textViewDescription.text
            self.navigationController?.popViewController(animated:true)
            break
        default:
            break
        }
        
        self.imageViewFinish.initAnalytics(withViewKey: analyticsViewRecord.viewKey)
        self.imageViewFinish.recordAction(
            .Tap,
            sourceRef: "Edit",
            sourceType: .Button,
            targetRef: "Editor-ProductTag",
            targetType: .View)
        
    }
    override func stopLoading() {
        super.stopLoading()
    }
    
    override func viewWillLayoutSubviews() {
        super.viewWillLayoutSubviews()
        
        
    }
    
    
    //MARK: - delegate gallery
    func handleDismisGalleryViewController(_ stage: StageMode) {
        
    }
    
    func imageCropViewControllerSuccess(_ controller: UIViewController!, didFinishCroppingImage croppedImage: UIImage!) {
        self.currentStage = .secondStage
        setupContentSizeWithImage(croppedImage)
        setupStage()
        self.imageViewFinish.image = croppedImage
        
    }
    
    func imageCropViewControllerDidCancel(_ controller: UIViewController!) {
        
    }
    
    func handleTapAddTag(_ rowIndex: Int) {
        switch rowIndex {
        case ModeGetTagList.brandTagList.rawValue:
            let controller = OutfitBrandSelectionViewController(selectedIndex: selectedMerchantsIndex, registerClass: OutfitBrandViewCell.self, id: "OutfitBrandViewCell", title: String.localize("LB_CA_ALL_BRAND"), mode: ModeGetTagList.brandTagList, object: self, datasourceTop: self.selectedMerchants)
            let navi = UINavigationController()
            navi.viewControllers = [controller]
            self.navigationController?.present(navi, animated:true , completion: {
                
            })
            break
        case ModeGetTagList.friendTagList.rawValue:
            let controller = OutfitFollowingFriendViewController(selectedIndex: selectedFriendsIndex,registerClass: OutfitBrandViewCell.self, id: "OutfitBrandViewCell", title: String.localize("LB_CA_TAG_FRIENDS"), mode: ModeGetTagList.friendTagList, object: self, datasourceTop: self.selectedFriends)
            let navi = UINavigationController()
            navi.viewControllers = [controller]
            self.navigationController?.present(navi, animated:true , completion:nil)
            break
            
        default:
            break
        }
    }
    
    //Delegate Outfit Selection
    func returnDataSelectedAtIndexs(_ selectedObjectAtIndexs: [Any], listMode: ModeGetTagList, selectedIndexs: [Int]) {
        if listMode == .brandTagList {
            self.selectedMerchants = selectedObjectAtIndexs as! [Merchant]
            self.selectedMerchantsIndex = selectedIndexs
            
            
        } else { // friend list
            self.selectedFriends = selectedObjectAtIndexs as! [User]
            self.selectedFriendsIndex = selectedIndexs
            
        }
    }
    
    func initAnalyticLog(){
        let user = Context.getUserProfile()
        let authorType = user.userTypeString()
        initAnalyticsViewRecord(
            user.userKey,
            authorType: authorType,
            viewLocation: "Editor-Post",
            viewType: "Post"
        )
    }
    
}

extension CreateOutfitViewController : UITextViewDelegate {
    
    //MARK: Delegate UITextView
    
    func textViewDidChange(_ textView: UITextView) {
        let string = textView.text as NSString
        updateLimitCharacter(string.length)
        
        var height = textView.contentSize.height
        if height < HeightOfDecriptionView - heightTopView {
            height = HeightOfDecriptionView - heightTopView
        }
        UITextView.beginAnimations(nil, context: nil)
        
        var frame = textView.frame
        frame.size.height = height
        textView.frame = frame
        
        UITextView.commitAnimations()
        
        self.layoutSubView()
        
        formatHashTag(isTypingKeyboard: true)
    }
    
    func layoutSubView() {
        self.topView.frame.originY = self.textViewDescription.frame.maxY
        self.line.frame.originY = self.textViewDescription.frame.maxY + heightTopView
        self.hashTagView.frame.originY = self.line.frame.maxY
        
        
        
        self.imageViewFinish.frame.originY = self.hashTagView.frame.maxY + 10.0
        textViewDescription.setContentOffset(CGPoint(x: 0, y: 0), animated: false)
        
        var contentSize = self.scrollView.contentSize
        contentSize.height = self.imageViewFinish.frame.maxY
        contentSize.height = self.scrollView.height > contentSize.height ? self.scrollView.height : contentSize.height
        self.scrollView.contentSize = contentSize
    }
    
    func textView(_ textView: UITextView, shouldChangeTextIn range: NSRange, replacementText text: String) -> Bool {
        let maxLength = Constants.LimitNumber.LimitPostText
        let currentString: String = textView.text!
        let newString: String = currentString.replacingCharacters(in: Range(range, in: currentString)!, with:text)
        if newString.length < maxLength {
            if text == "#" {
                textView.text = newString as String
                var selectedRange = range
                selectedRange.location += (text as NSString).length
                textView.selectedRange = selectedRange
                self.hashTagViewAddTopic()
            }
            return true
        }else {
            return false
        }
    }
    
    internal class SuccessPopUpView: UIView {
        
        let ImageSize = CGSize(width: 60, height: 60)
        let ButtonSize = CGSize(width: 130, height: 40)
        let ViewSize = CGSize(width: 280, height: 240)
        let topImage = UIImageView()
        let labelTop = UILabel()
        let labelContent = UILabel()
        let buttonShare = UIButton(type: .custom)
        let contentView = UIView()
        let tranparentView = UIView()
        let closeButton = UIButton(type: .custom)
        
        private final let CloseButtonHeight :CGFloat = 70
        
        override init(frame: CGRect) {
            super.init(frame: frame)
            
            tranparentView.backgroundColor = UIColor.black.withAlphaComponent(0.4)
            tranparentView.isUserInteractionEnabled = true
            tranparentView.addGestureRecognizer(UITapGestureRecognizer(target: self, action: #selector(self.hidePopup)))
            addSubview(tranparentView)
            
            topImage.image = UIImage(named: "icon_order_timeline_complete_inactive")
            contentView.addSubview(topImage)
            
            labelTop.text = String.localize("MSG_SUC_POST")
            labelTop.formatSizeBold(16)
            labelTop.textAlignment = .center
            contentView.addSubview(labelTop)
            
            labelContent.text = String.localize("LB_CA_REFERRAL_COUPON_SHARE")
            labelContent.formatSizeBold(14)
            labelContent.textAlignment = .center
            labelContent.backgroundColor = UIColor.backgroundGray()
            contentView.addSubview(labelContent)
            
            buttonShare.setTitle(String.localize("LB_CA_INCENTIVE_REF_SHARE"), for: .normal)
            buttonShare.formatPrimary()
            buttonShare.addTarget(self, action: #selector(SuccessPopUpView.campaginPopupPressed(sender:)), for: .touchUpInside)
            contentView.addSubview(buttonShare)
            
            contentView.backgroundColor = UIColor.white
            contentView.layer.cornerRadius = 10
            contentView.clipsToBounds = false
            self.addSubview(contentView)
            
            closeButton.setBackgroundImage(UIImage(named: "btn_close_light")?.withRenderingMode(.alwaysTemplate), for: .normal)
            closeButton.tintColor = UIColor.white
            closeButton.addTarget(self, action: #selector(SuccessPopUpView.hidePopup), for: .touchUpInside)
            self.addSubview(closeButton)
        }
        
        @objc func campaginPopupPressed(sender: UIButton) {
            self.dismissPopup {
                BannerManager.sharedManager.pushCampaignViewController()
            }
        }
        
        
        override func layoutSubviews() {
            super.layoutSubviews()
            
            let marginLeftRight = (self.bounds.sizeWidth - ViewSize.width)/2
            let marginTopBottom = (self.bounds.sizeHeight - ViewSize.height)/2
            
            contentView.frame = CGRect(x: marginLeftRight, y: marginTopBottom, width: ViewSize.width, height: ViewSize.height)
            topImage.frame = CGRect(x: (ViewSize.width - ImageSize.width)/2, y: 20, width: ImageSize.width, height: ImageSize.height)
            
            let yLabelTop = topImage.frame.maxY + 10
            let heightLabelTop: CGFloat = 25
            labelTop.frame = CGRect(x: marginLeftRight, y: yLabelTop, width: ViewSize.width - 2 * marginLeftRight, height: heightLabelTop)
            
            let yLabelContent = labelTop.frame.maxY + 10
            let heightLabelContent: CGFloat = 30
            labelContent.frame = CGRect(x: 0, y: yLabelContent, width: ViewSize.width, height: heightLabelContent)
            
            buttonShare.frame = CGRect(x: (ViewSize.width - ButtonSize.width)/2, y: labelContent.frame.maxY + 15, width: ButtonSize.width, height: ButtonSize.height)
            
            closeButton.frame = CGRect(x: (self.bounds.sizeWidth - CloseButtonHeight)/2, y: contentView.frame.maxY + 0, width: CloseButtonHeight, height: CloseButtonHeight)
        }
        
        required init?(coder aDecoder: NSCoder) {
            fatalError("init(coder:) has not been implemented")
        }
 
        @objc func hidePopup() {
            self.dismissPopup(nil)
        }
        
        private func dismissPopup(_ completion: (() -> Void)?) {
            
            UIView.animate(withDuration: 0.25, animations: {
                self.frame = CGRect(x: 0, y: self.size.height, width: self.bounds.sizeWidth, height: self.bounds.sizeHeight)
            }) { (completed) in
                self.removeFromSuperview()
                completion?()
            }
            
        }
    }
    
}



