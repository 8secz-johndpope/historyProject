//
//  TSShareMerchantCell.swift
//  merchant-ios
//
//  Created by HungPM on 3/18/16.
//  Copyright © 2016 WWE & CO. All rights reserved.
//

import Foundation
import ObjectMapper

class TSShareMerchantCell: TSChatBaseCell {
    
    @IBOutlet weak var merchantImage: UIImageView!
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

        name.formatSmall()
        remark.formatSmall()

        let longPress = UILongPressGestureRecognizer(target: self, action: #selector(TSShareMerchantCell.cellDidPressLong))
        viewContent.addGestureRecognizer(longPress)
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
    }
    
    @objc func cellDidPressLong(_ gesture: UIGestureRecognizer) {
        
        if gesture.state == UIGestureRecognizerState.began {
            if let delegate = self.delegate {
                delegate.cellDidPressLong(self)
            } else {
                ErrorLogManager.sharedManager.recordNonFatalError(withException: .NullPointer)
            }
        }
    }
    
    override func setCellContent(_ model: ChatModel) {
        super.setCellContent(model)
        
        if let merchant = model.merchantModel?.merchant {
            fillContentWithData(merchant, model: model)
        } else if let shareMerchantId = model.shareMerchantId {
            CacheManager.sharedManager.merchantById(shareMerchantId, completion: { [weak self] (merchant) in
                if let strongSelf = self, let merchant = merchant {
                    
                    let merchantModel = MerchantModel()
                    merchantModel.merchant = merchant
                    model.merchantModel = merchantModel
                    
                    strongSelf.fillContentWithData(merchant, model: model)
                } else {
                    ErrorLogManager.sharedManager.recordNonFatalError(withException: .NullPointer)
                }
            })
        }
        
        self.lblTimestamp.text = model.timeDate.detailChatTimeString
        
        self.setNeedsLayout()
    }
    
    func fillContentWithData(_ merchant: Merchant, model: ChatModel) {
        merchantImage.ts_setImageWithURLString(ImageURLFactory.URLSize(.size128, key: merchant.headerLogoImage, category: .merchant).absoluteString)
        dispatch_async_safely_to_main_queue({ () -> () in
            self.name.text = merchant.merchantName
            if model.fromMe {
                self.remark.text = (self.me?.displayName ?? "") + String.localize("LB_CA_IM_SHARE_MERC_MERCHANT_REMARK")
            }
            else {
                self.remark.text = (self.targetUser?.displayName ?? "") + String.localize("LB_CA_IM_SHARE_MERC_MERCHANT_REMARK")
            }
        })
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
    
}
