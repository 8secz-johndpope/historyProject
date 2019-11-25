//
//  TSChatTransferCell.swift
//  merchant-ios
//
//  Created by HungPM on 7/8/16.
//  Copyright © 2016 WWE & CO. All rights reserved.
//

import Foundation

private let kCommonFont: UIFont = UIFont.systemFont(ofSize: 13)
private let kContainerPaddingTop : CGFloat = 0
private let kContainerPaddingLeft : CGFloat = 10
private let kContainerPaddingRight : CGFloat = 10
private let kContainerPaddingBottom : CGFloat = 10
private let kAvatarWidth: CGFloat = 40
private let kAvatarMargin: CGFloat = 8

private let kLabelHeight: CGFloat = 40
private let kLabelMaxWidth : CGFloat = ScreenWidth - kContainerPaddingLeft - kContainerPaddingRight - kAvatarWidth - kAvatarMargin - 28 // 28 is arrow width + 3 margin

class TSChatTransferCell: TSChatBaseCell {

    @IBOutlet weak var containerView: UIView!
    @IBOutlet weak var commentLabel: TSChatEdgeLabel! {
        didSet {
            commentLabel.font = kCommonFont
            commentLabel.textColor = UIColor.secondary2()
        }
    }
    @IBOutlet weak var merchantLogo: UIImageView!
    @IBOutlet weak var lblTimestamp: UILabel!
    @IBOutlet weak var arrowImageView: UIImageView!

    override func prepareForReuse() {
        self.merchantLogo.image = nil
    }

    override func awakeFromNib() {
        self.selectionStyle = .none
        
        lblTimestamp.textColor = UIColor.secondary3()
        lblTimestamp.font = UIFont.systemFont(ofSize: 11)

        self.containerView.layer.cornerRadius = 5.0
        self.containerView.layer.masksToBounds = true
        
        let tap = TapGestureRecognizer()
        self.addGestureRecognizer(tap)
        tap.tapHandler = { [weak self] _ in
            if let strongSelf = self {
                guard let delegate = strongSelf.delegate else {
                    return
                }
                delegate.cellDidTaped?(strongSelf)
            }
        }
        
    }
    
    override func setCellContent(_ model: ChatModel) {
        self.model = model
        
        self.commentLabel.text = String.localize("MSG_INF_CS_CHAT_GROUP_NEW")
        
        if let fwMerchantId = model.transferRedirectModel?.forwardedMerchantId {
            if fwMerchantId == Constants.MMMerchantId {
                merchantLogo.image = Merchant().MMImageIconBlack
            }
            else {
                CacheManager.sharedManager.merchantById(fwMerchantId, completion: { (merchant) in
                    if let merchant = merchant {
                        self.merchantLogo.mm_setImageWithURL(ImageURLFactory.URLSize(.size128, key: merchant.largeLogoImage, category: ImageCategory.merchant), placeholderImage : UIImage(named: "Spacer"), contentMode: UIViewContentMode.scaleAspectFit)
                    }
                })
            }
        }
        else {
            merchantLogo.image = UIImage(named: "Spacer")
        }
        
        self.lblTimestamp.text = model.timeDate.detailChatTimeString

        self.setNeedsLayout()
    }
    
    override func layoutSubviews() {
        if let model = self.model {
            containerView.frame = CGRect(x: kContainerPaddingLeft, y: 0, width: Constants.ScreenSize.SCREEN_WIDTH - 2 * kContainerPaddingLeft, height: model.cellHeight - 10)
            
            let arrowImageWidth = CGFloat(25)
            arrowImageView.frame = CGRect(x: containerView.frame.width - arrowImageWidth, y: (containerView.frame.height - kChatTimeStampHeight - arrowImageWidth) / 2.0, width: arrowImageWidth, height: arrowImageWidth)
            
            let avatarImageWidth = CGFloat(40)
            merchantLogo.frame = CGRect(x: arrowImageView.frame.minX - avatarImageWidth - 3, y: (containerView.frame.height - kChatTimeStampHeight - avatarImageWidth) / 2.0, width: avatarImageWidth, height: avatarImageWidth)
            
            commentLabel.frame = CGRect(x: 0, y: 0, width: merchantLogo.frame.minX - 8, height: model.cellHeight - (kContainerPaddingTop + kContainerPaddingBottom + kChatTimeStampHeight))
        }
        self.lblTimestamp.bottom = containerView.bottom
        self.lblTimestamp.right = containerView.right - 17
    }
    
    class func layoutHeight(_ model: ChatModel) -> CGFloat {
        if model.cellHeight != 0 {
            return model.cellHeight
        }
        var height = kContainerPaddingTop + kContainerPaddingBottom + kChatTimeStampHeight
        
        let stringHeight: CGFloat = (String.localize("MSG_INF_CS_CHAT_GROUP_NEW")).stringHeightWithMaxWidth(kLabelMaxWidth, font: kCommonFont)
        height += stringHeight + 15
        
        let minHeight = CGFloat(75)
        if height < minHeight {
            height = minHeight
        }

        model.cellHeight = height
        return model.cellHeight
    }
    
    override func setSelected(_ selected: Bool, animated: Bool) {
        super.setSelected(selected, animated: animated)
        
        // Configure the view for the selected state
    }

}
