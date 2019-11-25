//
//  TSShareUserCell.swift
//  merchant-ios
//
//  Created by HungPM on 3/18/16.
//  Copyright © 2016 WWE & CO. All rights reserved.
//

import Foundation
import ObjectMapper

class TSShareUserCell: TSChatBaseCell {
    
    @IBOutlet weak var userImage: UIImageView!
    @IBOutlet weak var name: UILabel!
    @IBOutlet weak var remark: UILabel!
    @IBOutlet weak var backgroundImage: UIImageView!
    @IBOutlet weak var viewContent: UIView!
    @IBOutlet weak var lblTimestamp: UILabel!
    var targetUser: User?
    var me: User?
    
    override func awakeFromNib() {
        super.awakeFromNib()
        
        lblTimestamp.textColor = UIColor.secondary3()
        lblTimestamp.font = UIFont.systemFont(ofSize: 11)

        userImage.round()
        
        name.formatSmall()
        remark.formatSmall()

        viewContent.isUserInteractionEnabled = true

        let tap = TapGestureRecognizer()
        self.viewContent.addGestureRecognizer(tap)
        self.viewContent.isUserInteractionEnabled = true
        tap.tapHandler = { [weak self] _ in
            if let strongSelf = self {
                guard let delegate = strongSelf.delegate, let cellDidTapped = delegate.cellDidTaped else {
                    ErrorLogManager.sharedManager.recordNonFatalError(withException: .NullPointer)
                    return
                }
                cellDidTapped(strongSelf)
            }
        }
        let longPressGestureRecognizer = UILongPressGestureRecognizer(target: self, action: #selector(TSShareUserCell.longPressGestureRecognized))
        self.viewContent.addGestureRecognizer(longPressGestureRecognizer)
    }
    
    override func setCellContent(_ model: ChatModel) {
        super.setCellContent(model)
        
        if let user = model.userModel?.user {
            fillContentWithData(user, model: model)
        } else if let shareUserKey = model.shareUserKey {
            UserService.fetchUserIfNeeded(shareUserKey){ [weak self] (response) in
                if let strongSelf = self, let user = response {
                    let userModel = UserModel()
                    userModel.user = user
                    model.userModel = userModel
                    
                    strongSelf.fillContentWithData(user, model: model)
                } else {
                    ErrorLogManager.sharedManager.recordNonFatalError(withException: .NullPointer)
                }
            }
        }

        self.lblTimestamp.text = model.timeDate.detailChatTimeString

        self.setNeedsLayout()
    }
    
    func fillContentWithData(_ user: User, model: ChatModel) {
        userImage.ts_setImageWithURLString(ImageURLFactory.URLSize128(user.profileImage, category: .user).absoluteString, placeholderImage: UIImage(named: "default_profile_icon"))
        name.text = user.displayName
        if model.fromMe {
            remark.text = (me?.displayName ?? "") + String.localize("LB_CA_IM_SHARE_USER_PROFILE_REMARK")
        }
        else {
            remark.text = (targetUser?.displayName ?? "") + String.localize("LB_CA_IM_SHARE_USER_PROFILE_REMARK")
        }
    }
    
    class func layoutHeight(_ model: ChatModel) -> CGFloat {
        return 112.5 + kChatAvatarMarginTop + kChatBubblePaddingBottom
    }

    override func layoutContents() {
        super.layoutContents()
        guard let model = self.model else {
            return
        }
        
        if model.fromMe {
            self.viewContent.left = ScreenWidth - kChatAvatarMarginLeft - kChatAvatarWidth - kChatBubbleMaginLeft - self.viewContent.width
            backgroundImage.image = UIImage(named: "shareUser_pink")
        } else {
            self.viewContent.left = kChatBubbleLeft
            backgroundImage.image = UIImage(named: "shareUser_wht")
        }

        self.viewContent.top = self.avatarImageView.top
        
        self.lblTimestamp.bottom = self.backgroundImage.bottom
        self.lblTimestamp.right = self.backgroundImage.right - 7
    }
 
    
    override var canBecomeFirstResponder : Bool {
        return true
    }
    
    override func canPerformAction(_ action: Selector, withSender sender: Any?) -> Bool {
        if action == #selector(TSShareUserCell.forwardUserTaped) {
            return true
        }
        return false
    }
    
    @objc func longPressGestureRecognized(_ gestureRecognizer: UIGestureRecognizer) {
        
        if (gestureRecognizer.state == UIGestureRecognizerState.began) {
            becomeFirstResponder()
            let forward = UIMenuItem(title: String.localize("LB_CA_FORWARD"), action: #selector(TSShareUserCell.forwardUserTaped))
            let menuController = UIMenuController.shared
            menuController.menuItems = [forward]
            menuController.setTargetRect(self.viewContent.frame, in: self)
            menuController.setMenuVisible(true, animated: true)
        }
    }

    @objc func forwardUserTaped(_ sender: Any) {
        Log.debug("forwardUserTaped")
        if self.delegate != nil, let user = self.model?.userModel?.user {
            self.delegate?.forwardUserDidTaped(user)
        }
    }
}
