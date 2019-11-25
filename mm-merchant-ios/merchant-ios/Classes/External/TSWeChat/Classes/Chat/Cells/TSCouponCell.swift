//
//  TSCouponCell.swift
//  merchant-ios
//
//  Created by Phan Manh Hung on 3/13/17.
//  Copyright © 2017 WWE & CO. All rights reserved.
//

import Foundation
import ObjectMapper
import Alamofire
import PromiseKit

class TSCouponCell: TSChatBaseCell {
    
    @IBOutlet weak var lblCouponNote: UILabel!
    @IBOutlet weak var lblCouponCode: UILabel!
    @IBOutlet weak var remark: UILabel!
    @IBOutlet weak var backgroundImage: UIImageView!
    @IBOutlet weak var viewContent: UIView!
    @IBOutlet weak var lblTimestamp: UILabel!
    @IBOutlet weak var lblAmount: UILabel!
    @IBOutlet weak var lblCouponName: UILabel!
    @IBOutlet weak var imgViewCoupon: UIImageView!
    
    private let Margin: CGFloat = 10
    private let MarginText: CGFloat = 5
    private let PaddingLeft: CGFloat = 12
    private let PaddingBottom: CGFloat = 17
    
    var targetUser: User?
    var me: User?
    
    override func awakeFromNib() {
        super.awakeFromNib()
        
        lblCouponNote.font = UIFont.systemFontWithSize(14)
        lblCouponCode.font = UIFont.systemFontWithSize(14)

        lblCouponName.textColor = UIColor.secondary3()
        
        lblTimestamp.textColor = UIColor.secondary3()
        lblTimestamp.font = UIFont.systemFontWithSize(11)

        remark.formatSmall()
        
        let longPressGestureRecognizer = UILongPressGestureRecognizer(target: self, action: #selector(longPressGestureRecognized))
        viewContent.addGestureRecognizer(longPressGestureRecognizer)
    }
    
    override func setCellContent(_ model: ChatModel) {
        super.setCellContent(model)
        if model.coupon != nil {
            fillContent(withModel: model)
        } else if let couponCode = model.couponCode {
            CouponService.checkCoupon(couponCode, merchantId: model.senderMerchantId ?? 0, success: { [weak self] (coupon) in
                if let strongSelf = self {
                    
                    if let couponType = model.couponType {
                        switch couponType {
                        case .MMClaiming:
                            coupon.couponDescription = ""
                            
                        case .MMInput,
                            .MerchantInput:
                            coupon.couponDescription = String.localize("LB_COUPON_CODE_INPUT_SHARE_NOTE")

                        case .MMDesignated,
                            .MerchantDesignated:
                            coupon.couponDescription = String.localize("LB_COUPON_DESIGNATED_SHARE_NOTE")

                        case .MerchantClaiming:
                            coupon.couponDescription = String.localize("LB_COUPON_MERC_SHARE_NOTE")

                        }
                    }

                    model.coupon = coupon
                    strongSelf.fillContent(withModel: model)
                    NotificationCenter.default.post(name: Notification.Name(rawValue: "cellDidLoad"), object: nil)
                }
                }, failure: { [weak self] _ -> Bool in
                    if let strongSelf = self {
                        strongSelf.showErrorCoupon("MSG_ERR_INVALID_COUPON", couponCode: couponCode, model: model)
                        NotificationCenter.default.post(name: Notification.Name(rawValue: "cellDidLoad"), object: nil)
                    }
                    return true
            })
        }
        
        self.lblTimestamp.text = model.timeDate.detailChatTimeString
    }
    
    func showErrorCoupon(_ errorCode: String, couponCode: String, model: ChatModel){
        let coupon = Coupon()
        coupon.couponReference = couponCode
        coupon.couponDescription = String.localize(errorCode)
        coupon.isError = true
        model.coupon = coupon
        fillContent(withModel: model)
    }
    
    func fillContent(withModel model: ChatModel) {
        guard let coupon = model.coupon else { return }
        
        lblCouponNote.text = coupon.couponDescription
        if coupon.isError {
            lblCouponCode.text = coupon.couponReference
            
            imgViewCoupon.isHidden = true
            lblAmount.isHidden = true
            lblCouponName.isHidden = true
        }
        else {
            imgViewCoupon.isHidden = false
            lblAmount.isHidden = false
            lblCouponName.isHidden = false

            if let couponType = model.couponType, couponType == .MMInput || couponType == .MerchantInput {
                lblCouponCode.text = coupon.couponReference
            }
            else {
                lblCouponCode.text = ""
            }
            
            if let amount = coupon.couponAmount.formatPrice() {
                let attString = NSMutableAttributedString(string: amount, attributes: [NSAttributedStringKey.foregroundColor: UIColor.secondary3()])
                attString.addAttributes([NSAttributedStringKey.font: UIFont.systemFontWithSize(14)], range: NSRange(location: 0, length: 1))
                attString.addAttributes([NSAttributedStringKey.font: UIFont.systemFontWithSize(26)], range: NSRange(location: 1, length: amount.length - 1))
                lblAmount.attributedText = attString
            }
            
            lblCouponName.text = coupon.couponName
        }
        
        remark.text = String.localize("LB_COUPON_DETAIL")
        
        self.setNeedsLayout()
    }
    
    class func layoutHeight(_ model: ChatModel) -> CGFloat {
        if let coupon = model.coupon, coupon.isError {
            return 63 + kChatAvatarMarginTop + kChatBubblePaddingBottom + getTextHeight(coupon.couponReference, font: UIFont.systemFontWithSize(14)) + getTextHeight(coupon.couponDescription, font: UIFont.systemFontWithSize(14))
        }

        if let couponType = model.couponType {
            switch couponType {
            case .MMClaiming:
                return 130 + kChatAvatarMarginTop + kChatBubblePaddingBottom
                
            case .MMInput,
                 .MerchantInput:
                return 145 + kChatAvatarMarginTop + kChatBubblePaddingBottom + getTextHeight(String.localize("LB_COUPON_CODE_INPUT_SHARE_NOTE"), font: UIFont.systemFontWithSize(14)) + getTextHeight(model.coupon?.couponReference, font: UIFont.systemFontWithSize(14))
                
            case .MMDesignated,
                 .MerchantDesignated:
                return 140 + kChatAvatarMarginTop + kChatBubblePaddingBottom + getTextHeight(String.localize("LB_COUPON_DESIGNATED_SHARE_NOTE"), font: UIFont.systemFontWithSize(14))
                
            case .MerchantClaiming:
                return 140 + kChatAvatarMarginTop + kChatBubblePaddingBottom + getTextHeight(String.localize("LB_COUPON_MERC_SHARE_NOTE"), font: UIFont.systemFontWithSize(14))
                
            }
        }
        
        return 1
    }
    
    override func layoutSubviews() {
        super.layoutSubviews()
        
        guard let model = self.model else {
            return
        }
        
        if model.fromMe {
            viewContent.left = ScreenWidth - kChatAvatarMarginLeft - kChatAvatarWidth - kChatBubbleMaginLeft - viewContent.width
            backgroundImage.image = UIImage(named: "shareUser_pink")
        } else {
            viewContent.left = kChatBubbleLeft
            backgroundImage.image = UIImage(named: "shareUser_wht")
        }
        viewContent.top = avatarImageView.top
        viewContent.width = contentView.width * 3/5

        if let coupon = model.coupon, coupon.isError {
            lblCouponNote.frame = CGRect(x: Margin, y: Margin, width: viewContent.width - 2*Margin, height: TSCouponCell.getTextHeight(lblCouponNote.text, font: lblCouponNote.font))
            lblCouponCode.frame = CGRect(x: Margin, y: lblCouponNote.frame.maxY + MarginText, width: viewContent.width - 2*Margin, height: TSCouponCell.getTextHeight(lblCouponCode.text, font: lblCouponCode.font))
            
            viewContent.height = lblCouponCode.frame.maxY + Margin + 38
        }
        else {
            if let couponType = model.couponType {
                switch couponType {
                case .MMClaiming:
                    imgViewCoupon.frame = CGRect(x: Margin, y: Margin, width: 152, height: 70)
                    
                case .MMInput,
                     .MerchantInput:
                    
                    lblCouponNote.frame = CGRect(x: Margin, y: Margin, width: viewContent.width - 2*Margin, height: TSCouponCell.getTextHeight(lblCouponNote.text, font: lblCouponNote.font))
                    lblCouponCode.frame = CGRect(x: Margin, y: lblCouponNote.frame.maxY + MarginText, width: viewContent.width - 2*Margin, height: TSCouponCell.getTextHeight(lblCouponCode.text, font: lblCouponCode.font))
                    imgViewCoupon.frame = CGRect(x: Margin, y: lblCouponCode.frame.maxY + Margin, width: 152, height: 70)
                    
                case .MMDesignated,
                     .MerchantClaiming,
                     .MerchantDesignated:
                    
                    lblCouponNote.frame = CGRect(x: Margin, y: Margin, width: viewContent.width - 2*Margin, height: TSCouponCell.getTextHeight(lblCouponNote.text, font: lblCouponNote.font))
                    imgViewCoupon.frame = CGRect(x: Margin, y: lblCouponNote.frame.maxY + Margin, width: 152, height: 70)
                    
                }
            }
            
            lblAmount.frame = CGRect(x: imgViewCoupon.frame.minX + PaddingLeft, y: imgViewCoupon.frame.minY + Margin, width: imgViewCoupon.width - 2*PaddingLeft, height: 36)
            
            let labelHeight = CGFloat(12)
            lblCouponName.frame = CGRect(x: imgViewCoupon.frame.minX + PaddingLeft, y: imgViewCoupon.frame.maxY - PaddingBottom - labelHeight, width: imgViewCoupon.width - 2*PaddingLeft, height: labelHeight)
            
            viewContent.height = imgViewCoupon.frame.maxY + Margin + 38
        }
        
        self.lblTimestamp.bottom = self.backgroundImage.bottom
        self.lblTimestamp.right = self.backgroundImage.right - 7
    }
    
    override var canBecomeFirstResponder : Bool {
        return true
    }
    
    override func canPerformAction(_ action: Selector, withSender sender: Any?) -> Bool {
        if let coupon = model?.coupon, let couponType = model?.couponType, (couponType == .MMInput || couponType == .MerchantInput) && action == #selector(copyCouponTapped) && !coupon.isError {
            return true
        }
        return false
    }
    
    @objc func longPressGestureRecognized(_ gestureRecognizer: UIGestureRecognizer) {
        if (gestureRecognizer.state == UIGestureRecognizerState.began) {
            becomeFirstResponder()
            let copy = UIMenuItem(title: String.localize("LB_COUPON_CODE_COPY"), action: #selector(copyCouponTapped))
           
            let menuController = UIMenuController.shared
            menuController.menuItems = [copy]
            let targetFrame = CGRect(x: self.viewContent.centerX - 46, y: 5, width: 0, height: 0)
            
            menuController.setTargetRect(targetFrame, in: self.viewContent)
            menuController.setMenuVisible(true, animated: true)
        }
    }
    
    @objc func copyCouponTapped() {
        if let couponReference = model?.coupon?.couponReference {
            UIPasteboard.general.string = couponReference
            showCopiedPopup()
            delegate?.cellDidPressLong(self)
        }
    }
    
    class func getTextHeight(_ text: String?, width: CGFloat = ScreenWidth * 3/5 - 20,  font: UIFont) -> CGFloat {
        if let text = text, text.length > 0 {
            return text.stringHeightWithMaxWidth(width, font: font)
        }
        return 0
    }
}
