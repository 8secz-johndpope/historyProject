//
//  TSChatCommentCell.swift
//  TSWeChat
//
//  Created by hungvo on 5/20/16.
//  Copyright © 2016 WWE & CO. All rights reserved.
//

import UIKit
import MBProgressHUD
import ObjectMapper

private let kCommonFont: UIFont = UIFont.systemFont(ofSize: 13)
private let kContainerPaddingTop : CGFloat = 0
private let kContainerPaddingLeft : CGFloat = 10
private let kContainerPaddingRight : CGFloat = 10
private let kContainerPaddingBottom : CGFloat = 10

private let kAvatarMargin: CGFloat = 8
private let kAvatarWidth: CGFloat = 40

private let kLabelMargin : CGFloat = 8
private let kLabelHeight: CGFloat = 20

private let kLabelInfoMaxWidth : CGFloat = ScreenWidth - kContainerPaddingLeft - kContainerPaddingRight - kAvatarWidth - kAvatarMargin - 4
private let kLabelCommentMaxWidth : CGFloat = ScreenWidth - kContainerPaddingLeft - kContainerPaddingRight - kAvatarWidth - kAvatarMargin - 28

class TSChatCommentCell: UITableViewCell {
    var timeoutAction: DelayAction?
    var shouldShowLoadingImage = false

    @IBOutlet weak var containerView: UIView!
    
    @IBOutlet weak var infoLabel: UILabel! { didSet {
        infoLabel.font = kCommonFont
        infoLabel.textColor = UIColor.secondary3()
        }
    }

    @IBOutlet weak var commentLabel: TSChatEdgeLabel!{didSet {
        commentLabel.font = kCommonFont
        commentLabel.textColor = UIColor.secondary2()
        }
    }
    
    @IBOutlet weak var avatarImageView: UIImageView!
    @IBOutlet weak var chatIcon: UIImageView!
    @IBOutlet weak var lblTimestamp: UILabel!

    var model: ChatModel?
    var targetUser: User?
    var merchantObject: Merchant?
    
    lazy var retryButton: UIButton = {
        let button = UIButton(type: .custom)
        button.frame = CGRect(x: 0, y: 0, width: 30, height: 30)
        button.setImage(UIImage(named: "send_error"), for: UIControlState())
        button.addTarget(self, action: #selector(retrySend), for: .touchUpInside)
        return button
    } ()

    lazy var loadingView: UIActivityIndicatorView = {
        let view = UIActivityIndicatorView(frame: CGRect(x: 0, y: 0, width: 30, height: 30))
        view.activityIndicatorViewStyle = .gray
        return view
    } ()

    var resendMessage: ((_ model: ChatModel) -> ())?

    override func awakeFromNib() {
        super.awakeFromNib()
        self.selectionStyle = .none
        
        lblTimestamp.textColor = UIColor.secondary3()
        lblTimestamp.font = UIFont.systemFont(ofSize: 11)

        self.containerView.layer.cornerRadius = 5.0
        self.containerView.layer.masksToBounds = true
        
        self.avatarImageView.round()

        let longPressGestureRecognizer = UILongPressGestureRecognizer(target: self, action: #selector(TSChatCommentCell.longPressGestureRecognized))
        self.addGestureRecognizer(longPressGestureRecognizer)
    }
    
    @objc func longPressGestureRecognized(_ gestureRecognizer: UIGestureRecognizer) {
        if (gestureRecognizer.state == UIGestureRecognizerState.began) {
            becomeFirstResponder()
            let copy = UIMenuItem(title: String.localize("LB_CA_COPY"), action: #selector(TSChatCommentCell.copyTextTaped))
            let menuController = UIMenuController.shared
            menuController.menuItems = [copy]
            menuController.setTargetRect(self.containerView.frame, in: self)
            menuController.setMenuVisible(true, animated: true)
        }
    }
    
    override var canBecomeFirstResponder : Bool {
        return true
    }
    
    override func canPerformAction(_ action: Selector, withSender sender: Any?) -> Bool {
        // You need to only return true for the actions you want, otherwise you get the whole range of
        //  iOS actions. You can see this by just removing the if statement here.
        if action == #selector(TSChatCommentCell.copyTextTaped) {
            return true
        }
        
        return false
    }
    
    @objc func copyTextTaped(_ sender: Any) {
        Log.debug("copyTextTaped")
        let pasteboard = UIPasteboard.general
        pasteboard.string = self.commentLabel.text;
        showCopiedPopup()
    }
    
    func showCopiedPopup() {
        if let app = UIApplication.shared.delegate as? AppDelegate, let window = app.window {
            let hud = MBProgressHUD.showAdded(to: window, animated: true)
            hud?.mode = .customView
            hud?.opacity = 0.7
            let imageView = UIImageView(image: UIImage(named: "alert_ok"))
            imageView.contentMode = .scaleAspectFit
            imageView.frame = CGRect(x: 0, y: 0, width: 60, height: 60)
            hud?.customView = imageView
            hud?.labelText = String.localize("LB_COPIED")
            hud?.hide(true, afterDelay: 1.5)
        }
    }
    
    func shouldShowRetry() -> Bool {
        if let model = self.model {
            return model.fromMe && model.messageStatus == .failed
        }
        return false
    }
    
    func reloadRetryStatus() {
        
        if shouldShowRetry() {
            shouldShowLoadingImage = false
            loadingView.removeFromSuperview()
            addSubview(retryButton)
            self.setNeedsLayout()
        } else {
            retryButton.removeFromSuperview()
        }
        
    }

    func showLoading() {
        if loadingView.superview == nil {
            shouldShowLoadingImage = true
            addSubview(loadingView)
            loadingView.startAnimating()
            self.setNeedsLayout()
        }
    }
    
    func hideLoading() {
        shouldShowLoadingImage = false
        loadingView.removeFromSuperview()
        
        self.setNeedsLayout()
    }

    func setCellContent(_ model: ChatModel) {
        self.model = model
        
        reloadRetryStatus()

        var str : String!
        if model.messageContentType == .ForwardDescription || model.messageContentType == .TransferComment {
            str = String.localize("LB_MC_CS_CHAT_FOWARD_NOTE")
            
            if let fwMerchantName = model.commentModel?.forwardedMerchantName {
                str = str.replacingOccurrences(of: "{2}", with: fwMerchantName)
            }
            else if let fwMerchantId = model.commentModel?.forwardedMerchantId {
                if fwMerchantId == Constants.MMMerchantId {
                    model.commentModel!.forwardedMerchantName = Merchant.MM().merchantName
                    str = str.replacingOccurrences(of: "{2}", with: model.commentModel!.forwardedMerchantName!)
                }
                else {
                    CacheManager.sharedManager.merchantById(fwMerchantId, completion: { (merchant) in
                        if let merchant = merchant, let commentModel = model.commentModel {
                            model.commentModel!.forwardedMerchantName = merchant.merchantName
                            str = str.replacingOccurrences(of: "{2}", with: merchant.merchantName)
                            self.infoLabel.text = str
                            commentModel.infoText = str
                            NotificationCenter.default.post(name: Notification.Name(rawValue: "commentCellLoaded"), object: nil)
                        }
                    })
                }
            }
            
            var name = ""
            if let queueType = model.commentModel?.forwardedMerchantQueueName {
                name = QueueStatistics.queueText(queueType)
            }
            
            str = str.replacingOccurrences(of: "{3}", with: name)

        }
        else if model.commentModel?.status == CommentStatus.Normal {
            str = String.localize("LB_CS_COMMENT_NOTE")
        } else  {
            str = String.localize("LB_CS_COMMENT_CLOSE")
        }
        
        var agentName = ""
        if let targetUser = self.targetUser {
            agentName = targetUser.displayName
        }
        
        str = str.replacingOccurrences(of: "{0}", with: agentName)

        if let merchantName = model.commentModel?.merchantName {
            str = str.replacingOccurrences(of: "{1}", with: merchantName)
        }
        else if let merchantObject = self.merchantObject {
            if let commentModel = model.commentModel {
                commentModel.merchantName = merchantObject.merchantName
                str = str.replacingOccurrences(of: "{1}", with: commentModel.merchantName ?? "")
            }
        }
        else {
            if let merchantId = model.commentModel?.merchantId {
                CacheManager.sharedManager.merchantById(merchantId, completion: { (merchant) in
                    if let merchant = merchant, let commentModel = model.commentModel {
                        commentModel.merchantName = merchant.merchantName
                        
                        str = str.replacingOccurrences(of: "{1}", with: merchant.merchantName)
                        self.infoLabel.text = str
                        commentModel.infoText = str
                        NotificationCenter.default.post(name: Notification.Name(rawValue: "commentCellLoaded"), object: nil)
                    }
                })
            }
        }
        
        self.infoLabel.text = str
        if let commentModel = model.commentModel {
            commentModel.infoText = str
        }

        self.commentLabel.text = model.commentModel?.comment
        
        if model.chatSenderProfileKey != nil {
            avatarImageView.mm_setImageWithURL(ImageURLFactory.URLSize128(model.chatSenderProfileKey!, category: ImageCategory.user), placeholderImage : UIImage(named: Constants.ImageName.ProfileImagePlaceholder), contentMode: UIViewContentMode.scaleAspectFit)
        } else {
            avatarImageView.image = UIImage(named: Constants.ImageName.ProfileImagePlaceholder)
        }
        avatarImageView.contentMode = .scaleAspectFill
        
        timeoutAction?.cancel()
        if let model = self.model {
            if model.messageStatus == .pending {
            
                showLoading()

                let delta = Date().timeIntervalSince(model.timeDate as Date)
                let waitingTime = Constants.IMTimeout - delta
                
                if waitingTime > 0 {
                    timeoutAction = DelayAction(
                        delayInSecond: waitingTime,
                        actionBlock: { [weak self] in
                            if let me = self {
                                me.reloadRetryStatus()
                            }
                        }
                    )
                }
            }
            else if model.messageStatus == .sent {
                hideLoading()
            }
        }

        self.lblTimestamp.text = model.timeDate.detailChatTimeString

        self.setNeedsLayout()
    }
    
    override func layoutSubviews() {
        
        if shouldShowRetry() {
            let xPos = 2*kContainerPaddingLeft + retryButton.bounds.width
            containerView.frame = CGRect(x: xPos, y: containerView.frame.origin.y, width: Constants.ScreenSize.SCREEN_WIDTH - xPos - kContainerPaddingRight, height: containerView.frame.height)
            
            retryButton.center = CGPoint(
                x: containerView!.frame.origin.x - retryButton.frame.size.width / 2,
                y: containerView!.center.y
            )
        }
        else if shouldShowLoadingImage {
            let xPos = 2*kContainerPaddingLeft + loadingView.bounds.width
            containerView.frame = CGRect(x: xPos, y: containerView.frame.origin.y, width: Constants.ScreenSize.SCREEN_WIDTH - xPos - kContainerPaddingRight, height: containerView.frame.height)
            
            loadingView.center = CGPoint(
                x: containerView!.frame.origin.x - loadingView.frame.size.width / 2,
                y: containerView!.center.y
            )
        }
        else {
            containerView.frame = CGRect(x: kContainerPaddingLeft, y: containerView.frame.origin.y, width: Constants.ScreenSize.SCREEN_WIDTH - kContainerPaddingLeft - kContainerPaddingRight, height: containerView.frame.height)
        }
        
        self.avatarImageView.center = CGPoint(x: self.avatarImageView.center.x, y: self.containerView.center.y)
        
        if let model = self.model, let infoHeight = self.model?.commentModel?.infoHeight {
            
            if let comment = model.commentModel?.comment, comment != "" {
                infoLabel.frame = CGRect(x: infoLabel.frame.origin.x, y: kLabelMargin, width: infoLabel.frame.size.width, height: infoHeight)

                commentLabel.frame = CGRect(x: commentLabel.frame.origin.x, y: infoLabel.frame.maxY, width: commentLabel.frame.size.width, height: model.cellHeight - (2 * kLabelMargin) - infoLabel.frame.maxY)
                
                chatIcon.center = CGPoint(x: chatIcon.center.x, y: commentLabel.center.y)
                commentLabel.isHidden = false
                chatIcon.isHidden = false
            }
            else {
                infoLabel.frame = CGRect(x: infoLabel.frame.origin.x, y: 0, width: infoLabel.frame.size.width, height: self.containerView.frame.height)

                commentLabel.isHidden = true
                chatIcon.isHidden = true
            }
        }
        self.lblTimestamp.bottom = self.containerView.bottom
        self.lblTimestamp.right = self.containerView.width - 7
    }
    
    class func layoutHeight(_ model: ChatModel) -> CGFloat {
        
        var height = kContainerPaddingTop + kContainerPaddingBottom + kLabelMargin + kLabelHeight + kLabelMargin + kChatTimeStampHeight

        var stringHeight: CGFloat
        if let commentText = model.commentModel?.comment, commentText != "" {
            stringHeight = commentText.stringHeightWithMaxWidth(kLabelCommentMaxWidth, font: kCommonFont)
        }
        else {
            stringHeight = 0
        }
        
        if let infoText = model.commentModel?.infoText {
            let infoHeight: CGFloat = infoText.stringHeightWithMaxWidth(kLabelInfoMaxWidth, font: kCommonFont) 
            height += infoHeight - kLabelHeight - kLabelMargin
            
            model.commentModel?.infoHeight = infoHeight
        }
    
        height += stringHeight + 10
        
        let minHeight = CGFloat(59)
        if height < minHeight {
            height = minHeight
        }
        
        model.cellHeight = height
        
        return height
    }
    
    override func setSelected(_ selected: Bool, animated: Bool) {
        super.setSelected(selected, animated: animated)
        
        // Configure the view for the selected state
    }
    
    @objc func retrySend() {
        guard let model = self.model else {
            return
        }
        
        resendMessage?(model)
    }
}



