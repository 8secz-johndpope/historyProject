//
//  TSSharePostCell.swift
//  merchant-ios
//
//  Created by Sang Nguyen on 17/6/2016.
//  Copyright © 2016 WWE & CO. All rights reserved.
//

import Foundation
import ObjectMapper

class TSSharePostCell: TSChatBaseCell { 
    
    @IBOutlet weak var viewContent: UIView!
    @IBOutlet weak var imageBackground: UIImageView!
    @IBOutlet weak var postImage: UIImageView!
    @IBOutlet weak var logoImage: UIImageView!
    
    @IBOutlet weak var diamondImage: UIImageView!
    @IBOutlet weak var postName: UILabel!
    @IBOutlet weak var postRemark: UILabel!
    @IBOutlet weak var lblTimestamp: UILabel!
    @IBOutlet weak var warningImage: UIImageView!
    
    var swipeMenu: SwipeMenu!
    private var post: Post?
    var targetUser: User?
    var me: User?
    var buyHandler: ((_ cell: TSSharePostCell, _ post: Post?, _ isSwipe: Bool?) -> Void)?
    
    override func awakeFromNib() {
        super.awakeFromNib()
        
        lblTimestamp.textColor = UIColor.secondary3()
        lblTimestamp.font = UIFont.systemFont(ofSize: 11)

        postName.font = UIFont.usernameFont()
        postName.textColor = .black
        
        postRemark.formatSmall()
        
        let longPress = LongPressGestureRecognizer()
        viewContent.addGestureRecognizer(longPress)
        viewContent.isUserInteractionEnabled = true
        
        longPress.longPressHandler = { [weak self] sender in
            guard let strongSelf = self else {
                return
            }
            
            if sender.state == .began {
                if let delegate = strongSelf.delegate {
                    delegate.cellDidPressLong(strongSelf)
                }
            }
        }
        
        
        let tap = TapGestureRecognizer()
        viewContent.addGestureRecognizer(tap)
        tap.tapHandler = { [weak self] _ in
            if let strongSelf = self {
                guard let delegate = strongSelf.delegate, let cellDidTaped = delegate.cellDidTaped else {
                    return
                }
                cellDidTaped(strongSelf)
            }
        }
        
        let Margin = CGFloat(5)
        
        swipeMenu = SwipeMenu(price: nil, centerText: true)
        swipeMenu!.frame = CGRect(x: 5, y: postImage.frame.maxY + Margin , width: swipeMenu!.frame.width, height: swipeMenu!.frame.height)
        var frame = self.postRemark.frame
        self.postRemark.frame = frame
        frame.origin.y = self.swipeMenu.frame.maxY + Margin
        viewContent.addSubview(swipeMenu)
        swipeMenu?.doBuyBolock = { [weak self] isSwipe in
            
            guard let strongSelf = self else {
                return
            }

            Log.debug("buy")
            if let callback = strongSelf.buyHandler {
                if let post = strongSelf.post {
                    callback(strongSelf, post, isSwipe)
                }
            }
            
        }
        
        self.logoImage.layer.cornerRadius = self.logoImage.bounds.height / 2
    }
    
    override func setCellContent(_ model: ChatModel) {
        super.setCellContent(model)
        
        if let postModel = model.model as? PostModel, let post = postModel.post {
            self.fillContentWithData(post, model: model)
        } else if let sharePostId = model.sharePostId {
            CacheManager.sharedManager.postById(sharePostId, completion: { [weak self] (response) in
                if let strongSelf = self {
                    if let post = response {
                        let postModel = PostModel()
                        postModel.post = post
                        model.model = postModel
                        strongSelf.fillContentWithData(post, model: model)
                    }
                    else {
                        strongSelf.showPostNotAvailable()
                    }
                    strongSelf.height = TSSharePostCell.layoutHeight(model)
                    strongSelf.setNeedsLayout()
                } else {
                    ErrorLogManager.sharedManager.recordNonFatalError(withException: .NullPointer)
                }
                })
        }
        
        
        self.lblTimestamp.text = model.timeDate.detailChatTimeString

        self.setNeedsLayout()
    }

    func showWarning(_ hidden: Bool) {
        
        swipeMenu.isHidden = hidden
        warningImage.isHidden = !hidden

        logoImage.image = UIImage(named: "default_profile_icon")
        postImage.image = nil
        postName.text = nil
        
        if hidden {
            postRemark.text = String.localize("MSG_ERR_IM_DELETE_POST")
            postImage.backgroundColor = UIColor.primary2()
            warningImage.center = postImage.center
        } else {
            postRemark.text = ""
            postImage.backgroundColor = UIColor.white
        }
    }
    
    func showPostNotAvailable() {
        showWarning(true)
    }
    
    func fillContentWithData(_ post: Post, model: ChatModel) {
        showWarning(false)
        
        self.post = post
        
        if let postModel = self.model?.model as? PostModel {
            postModel.imagePostHeight = self.postImage.frame.height
        }
        let key = post.postImage
        postImage.mm_setImageWithURL(
            ImageURLFactory.URLSize750(key, category: .post),
            placeholderImage: UIImage(named: "Spacer"))
        if let skuelist = post.skuList, skuelist.count > 0 {
            swipeMenu.isHidden = false
            //mm-8803
            let price = Double(skuelist.reduce(Double(0.0), { (sum, sku) -> Double in
                return sum + sku.price()
            }))
            swipeMenu.price = price.formatPrice()
            
        } else {
            swipeMenu.isHidden = true
        }
        
        if let merchant = post.merchant {
            postName.text = merchant.merchantName.length > 0 ? merchant.merchantName : merchant.merchantCompanyName
            logoImage.mm_setImageWithURL(ImageURLFactory.URLSize128(merchant.headerLogoImage, category: .merchant), placeholderImage : UIImage(named: "default_profile_icon"),clipsToBounds: true)
            logoImage.contentMode = .scaleAspectFit
        } else {
            if let author = post.user {
                postName.text = author.displayName
                logoImage.ts_setImageWithURLString(ImageURLFactory.URLSize128(author.profileImage, category: .user).absoluteString)
            }
        }
        
        if model.fromMe {
            postRemark.text = (me?.displayName ?? "") + String.localize("LB_CA_IM_SHARE_OUTFIT_REMARK")
        }
        else {
            postRemark.text = (targetUser?.displayName ?? "") + String.localize("LB_CA_IM_SHARE_OUTFIT_REMARK")
        }
        
        if let author = post.user {
            if author.isCurator == 0 || post.isMerchantIdentity.rawValue == 1 {
                self.diamondImage.isHidden = true
            } else {
                self.diamondImage.isHidden = false
            }
        }
        else {
            self.diamondImage.isHidden = true
        }
    }
    
    override func layoutContents() {
        super.layoutContents()
        guard let model = self.model else {
            return
        }
        
        if model.fromMe {
            self.viewContent.left = ScreenWidth - kChatAvatarMarginLeft - kChatAvatarWidth - kChatBubbleMaginLeft - self.viewContent.width
            imageBackground.image = UIImage(named: "shareUser_pink")
        } else {
            self.viewContent.left = kChatBubbleLeft
            imageBackground.image = UIImage(named: "shareUser_wht")
        }
    
        self.viewContent.top = self.avatarImageView.top
        
        if self.swipeMenu.isHidden == true {
            var postRemarkFrame = self.postRemark.frame
            postRemarkFrame.origin.y = self.swipeMenu.frame.maxY - SwipeMenu.SwipeMenuHeight - 5
            self.postRemark.frame = postRemarkFrame
            
            var imageBackgroundFrame = self.imageBackground.frame
            imageBackgroundFrame.size.height = self.contentView.height - 17
            self.imageBackground.frame = imageBackgroundFrame
        } else {
            var postRemarkFrame = self.postRemark.frame
            postRemarkFrame.origin.y = self.swipeMenu.frame.maxY + 5
            self.postRemark.frame = postRemarkFrame
            
            var imageBackgroundFrame = self.imageBackground.frame
            imageBackgroundFrame.size.height = self.contentView.height - 8
            self.imageBackground.frame = imageBackgroundFrame
        }
        
        self.lblTimestamp.bottom = self.imageBackground.bottom
        self.lblTimestamp.right = self.imageBackground.right - 7
    }
    
    class func layoutHeight(_ model: ChatModel) -> CGFloat {
        
        var height = kChatAvatarMarginTop + kChatBubblePaddingBottom
        let TopHeight = CGFloat(50)
        let BottomHeight = CGFloat(38.5)
        height += TopHeight + BottomHeight + 220 + 55
        
        if let postModel = model.model as? PostModel {
            if let skuList = postModel.post?.skuList, skuList.count == 0 {
                height -= SwipeMenu.SwipeMenuHeight
            }
        }
        
        model.cellHeight = height
        return model.cellHeight
    }
    
    override func setSelected(_ selected: Bool, animated: Bool) {
        super.setSelected(selected, animated: animated)
        
        // Configure the view for the selected state
    }
    
    /*
     // Only override drawRect: if you perform custom drawing.
     // An empty implementation adversely affects performance during animation.
     override func drawRect(rect: CGRect) {
     // Drawing code
     }
     */
    
    func CGRectCenterRectForResizableImage(_ image: UIImage) -> CGRect {
        return CGRect(
            x: image.capInsets.left / image.size.width,
            y: image.capInsets.top / image.size.height,
            width: (image.size.width - image.capInsets.right - image.capInsets.left) / image.size.width,
            height: (image.size.height - image.capInsets.bottom - image.capInsets.top) / image.size.height
        )
    }
    
    func _maskImage(_ image: UIImage, maskImage: UIImage) -> UIImage {
        let maskRef: CGImage = maskImage.cgImage!
        let mask: CGImage = CGImage(
            maskWidth: maskRef.width,
            height: maskRef.height,
            bitsPerComponent: maskRef.bitsPerComponent,
            bitsPerPixel: maskRef.bitsPerPixel,
            bytesPerRow: maskRef.bytesPerRow,
            provider: maskRef.dataProvider!,
            decode: nil,
            shouldInterpolate: false
            )!
        let maskedImageRef: CGImage = image.cgImage!.masking(mask)!
        let maskedImage: UIImage = UIImage(cgImage:maskedImageRef)
        // returns new image with mask applied
        return maskedImage
    }
    

    
}
