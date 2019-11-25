//
//  TSChatBaseCell.swift
//  TSWeChat
//
//  Created by Hilen on 1/11/16.
//  Copyright © 2016 Hilen. All rights reserved.
//

import UIKit
import SnapKit
import MBProgressHUD

private let kChatNicknameLabelHeight: CGFloat = 20  //昵称 label 的高度
let kChatAvatarMarginLeft: CGFloat = 10             //头像的 margin left
let kChatAvatarMarginTop: CGFloat = 0               //头像的 margin top
let kChatAvatarWidth: CGFloat = 35                  //头像的宽度

class TSChatBaseCell: UITableViewCell {
    weak var delegate: TSChatCellDelegate?

    var timeoutAction: DelayAction?
    var shouldShowLoadingImage = false
    
    @IBOutlet weak var avatarImageView: UIImageView!
    
    @IBOutlet weak var nicknameLabel: UILabel! {
        didSet{
            nicknameLabel.font = UIFont.systemFont(ofSize: 11)
            nicknameLabel.textColor = UIColor.darkGray
        }
    }
    
    lazy var retryButton: UIButton = {
        let button = UIButton(type: .custom)
        button.frame = CGRect(x: 0, y: 0, width: 30, height: 30)
        button.setImage(UIImage(named: "send_error"), for: UIControlState())
        button.addTarget(self, action: #selector(TSChatBaseCell.retrySend), for: .touchUpInside)
        return button
    } ()
    
    lazy var loadingView: UIActivityIndicatorView = {
        let view = UIActivityIndicatorView(frame: CGRect(x: 0, y: 0, width: 30, height: 30))
        view.activityIndicatorViewStyle = .gray
        return view
    } ()

    @IBOutlet weak var cellBackgroundRefView: UIView?
    
    var model: ChatModel?

    override func prepareForReuse() {
        self.avatarImageView.image = nil
        self.nicknameLabel.text = nil
        
        super.prepareForReuse()
    }
    
    override func awakeFromNib() {
        super.awakeFromNib()
        
        accessibilityIdentifier = "TSChatBaseCell"
        
        // Initialization code
        self.selectionStyle = .none
        self.contentView.backgroundColor = UIColor.clear
        
        //头像点击
        let tap = TapGestureRecognizer()
        self.avatarImageView.addGestureRecognizer(tap)
        self.avatarImageView.isUserInteractionEnabled = true
        tap.tapHandler = { [weak self ] _ in
            if let strongSelf = self {
                guard let delegate = strongSelf.delegate else {
                    return
                }
                delegate.cellDidTapedAvatarImage(strongSelf)
            }
        }
        
        avatarImageView.backgroundColor = UIColor.white
        avatarImageView.width = kChatAvatarWidth
        avatarImageView.height = kChatAvatarWidth

        avatarImageView.contentMode = .scaleAspectFit

        avatarImageView.clipsToBounds = true
        avatarImageView.layer.cornerRadius = avatarImageView.bounds.height/2
    }
    
    func shouldShowRetry() -> Bool {
        if let model = self.model {
            return model.fromMe && model.messageStatus == .failed && cellBackgroundRefView != nil
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
    }
    
    func setCellContent(_ model: ChatModel) {
        self.model = model
 
        reloadRetryStatus()

        if model.chatSenderProfileKey != nil {
            avatarImageView.mm_setImageWithURL(ImageURLFactory.URLSize128(model.chatSenderProfileKey!, category: ImageCategory.user), placeholderImage : UIImage(named: Constants.ImageName.ProfileImagePlaceholder), contentMode: .scaleAspectFit)
        } else {
            avatarImageView.image = UIImage(named: Constants.ImageName.ProfileImagePlaceholder)
        }
        
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
        
        self.setNeedsLayout()
    }
    
    override func layoutSubviews() {
        super.layoutSubviews()
        
        guard let model = self.model else {
            return
        }
        
        if model.fromMe {
            self.nicknameLabel.height = 0
            let left = self.bounds.width - kChatAvatarMarginLeft - kChatAvatarWidth
            self.avatarImageView.left = left
        } else {
            self.nicknameLabel.height = 0
            self.avatarImageView.left = kChatAvatarMarginLeft
        }
        
        layoutContents()
        
        if shouldShowRetry() {
            retryButton.center = CGPoint(
                x: cellBackgroundRefView!.frame.origin.x - retryButton.frame.size.width / 2,
                y: cellBackgroundRefView!.center.y
            )
        }
        
        if shouldShowLoadingImage {
            loadingView.center = CGPoint(
                x: cellBackgroundRefView!.frame.origin.x - loadingView.frame.size.width / 2,
                y: cellBackgroundRefView!.center.y
            )
        }
        
    }
    
    func layoutContents() {
        
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

    @objc func retrySend() {
        guard let model = self.model else {
            return
        }
        delegate?.resendMessage(model)
    }
    
    override func setSelected(_ selected: Bool, animated: Bool) {
        super.setSelected(selected, animated: animated)

        // Configure the view for the selected state
    }
    
}
