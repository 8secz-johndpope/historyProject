//
//  TSChatAutoRespondCell.swift
//  merchant-ios
//
//  Created by HungPM on 7/27/16.
//  Copyright © 2016 WWE & CO. All rights reserved.
//

import UIKit
import YYText

private let kChatTextFont: UIFont = UIFont.systemFont(ofSize: 16)

class TSChatAutoRespondCell: TSChatBaseCell {
    static var receiveTextNodeBkg: UIImage!
    var contentString: String?
    
    static func getRecieveTextNodeBkg() ->UIImage {
        if receiveTextNodeBkg == nil {
            let stretchImage = UIImage(named: "textBox_wht")
            receiveTextNodeBkg = stretchImage!.resizableImage(withCapInsets: UIEdgeInsets(top: 30, left: 28, bottom: 30, right: 28), resizingMode: .stretch)
        }
        return receiveTextNodeBkg
    }
    @IBOutlet weak var contentLabel: YYLabel! {didSet{
        contentLabel.font = kChatTextFont
        contentLabel.numberOfLines = 0
        contentLabel.backgroundColor = UIColor.clear
        contentLabel.textVerticalAlignment = YYTextVerticalAlignment.top
        contentLabel.displaysAsynchronously = false
        contentLabel.ignoreCommonProperties = true
        contentLabel.highlightTapAction = ({[weak self] containerView, text, range, rect in
            self!.didTapRichLabelText(label: self!.contentLabel, textRange: range)
            })

        
        }}
    @IBOutlet weak var bubbleImageView: UIImageView!
    override func awakeFromNib() {
        super.awakeFromNib()
        // Initialization code
        lblTimestamp.textColor = UIColor.secondary3()
        lblTimestamp.font = UIFont.systemFont(ofSize: 11)
    }
    
    @IBOutlet weak var lblTimestamp: UILabel!
    
    override func setCellContent(_ model: ChatModel) {
        super.setCellContent(model)
        
        if let convKey = model.convKey, let conv = WebSocketManager.sharedInstance().conversationForKey(convKey) {
            if conv.merchantObject?.merchantId == Constants.MMMerchantId {
                self.avatarImageView.image = Merchant().MMImageIconBlack
            }
            else if let headerLogoImage = conv.merchantObject?.headerLogoImage {
                
                ImageFilesManager.cachedImageForKey(
                    headerLogoImage,
                    completion: { (image, error, cacheType, imageURL) in
                        
                        self.avatarImageView.contentMode = .scaleAspectFit
                        
                        if let returnedImage = image {
                            self.avatarImageView.image = returnedImage
                        } else {
                            self.avatarImageView.mm_setImageWithURL(ImageURLFactory.URLSize128(headerLogoImage, category: .merchant), placeholderImage: UIImage(named: "default_profile_pic"), contentMode: UIViewContentMode.scaleAspectFit)
                        }
                    }
                )
            }
        }

        if let richTextLinePositionModifier = model.richTextLinePositionModifier {
            self.contentLabel.linePositionModifier = richTextLinePositionModifier
        }
        
        if let richTextLayout = model.richTextLayout {
            self.contentLabel.textLayout = richTextLayout
        }
        
        if let richTextAttributedString = model.richTextAttributedString {
            self.contentLabel.attributedText = richTextAttributedString
        }
        
        self.lblTimestamp.text = model.timeDate.detailChatTimeString
    
        self.bubbleImageView.image = TSChatTextCell.getRecieveTextNodeBkg()
        self.contentString = model.messageContent
        self.setNeedsLayout()
    }
    
    /**
     解析点击文字
     
     - parameter label:     YYLabel
     - parameter textRange: 高亮文字的 NSRange，不是 range
     */
    private func didTapRichLabelText(label: YYLabel, textRange: NSRange) {
        //解析 userinfo 的文字
        let attributedString = label.textLayout!.text
        if textRange.location >= attributedString.length {
            return
        }
        guard let hightlight: YYTextHighlight = attributedString.yy_attribute(YYTextHighlightAttributeName, at: UInt(textRange.location)) as? YYTextHighlight else {
            return
        }
        guard let info = hightlight.userInfo, info.count > 0 else {
            return
        }
        
        guard let delegate = self.delegate else {
            return
        }
        
        if let phone = info[kChatTextKeyPhone] {
            if let str = phone as? String {
                delegate.cellDidTapedPhone(self, phoneString: str)
            } else if let str = phone as? Substring {
                delegate.cellDidTapedPhone(self, phoneString: String(str))
            }
        }
        
        if let URL = info[kChatTextKeyURL] {
            if let str = URL as? String {
                delegate.cellDidTapedLink(self, linkString: str)
            } else if let str = URL as? Substring {
                delegate.cellDidTapedLink(self, linkString: String(str))
            }
        }
    }
    
    override func layoutContents() {
        super.layoutContents()
        guard let model = self.model else {
            return
        }
        
        var aSize: CGSize = model.richTextLayout!.textBoundingSize
        if let text = model.messageContent, text.containsEmoji() {
            aSize.height += 3 // for emoji, add 3 pixels
        }
        self.contentLabel.size = aSize

        let minWidth = CGFloat(70)
        
        self.bubbleImageView.left = kChatBubbleLeft
        //设置气泡的宽
        self.bubbleImageView.width = max(self.contentLabel.width + kChatBubbleWidthBuffer, kChatBubbleImageViewWidth)
        if self.bubbleImageView.width < minWidth {
            self.bubbleImageView.width = minWidth
        }
        
        //设置气泡的高度
        self.bubbleImageView.height = max(self.contentLabel.height + kChatBubbleHeightBuffer + (kChatTimeStampHeight / 2.0), kChatBubbleImageViewHeight)
        //value = 头像的底部 - 气泡透明间隔值
        self.bubbleImageView.top = self.nicknameLabel.bottom - kChatBubblePaddingTop
        //valeu = 气泡顶部 + 文字和气泡的差值
        self.contentLabel.top = self.bubbleImageView.top + kChatTextMarginTop
        //valeu = 气泡左边 + 文字和气泡的差值
        self.contentLabel.left = self.bubbleImageView.left + kChatTextMarginLeft
        
        self.lblTimestamp.bottom = self.bubbleImageView.bottom
        self.lblTimestamp.right = self.bubbleImageView.right - 7
    }
    
    class func layoutHeight(_ model: ChatModel) -> CGFloat {
        if model.cellHeight != 0 {
            return model.cellHeight
        }
        //解析富文本
        var attributedString = NSMutableAttributedString()
        if let text = model.messageContent, text.length > 0 {
            attributedString = TSChatTextParser.parseText(text, font: kChatTextFont)!
            model.richTextAttributedString = attributedString
        }
        
        //初始化排版布局对象
        let modifier = TSYYTextLinePositionModifier(font: kChatTextFont)
        model.richTextLinePositionModifier = modifier
        
        //初始化 YYTextContainer
        let textContainer: YYTextContainer = YYTextContainer()
        textContainer.size = CGSize(width: kChatTextMaxWidth, height: CGFloat.greatestFiniteMagnitude)
        textContainer.linePositionModifier = modifier
        textContainer.maximumNumberOfRows = 0
        
        //设置 layout
        let textLayout = YYTextLayout(container: textContainer, text: attributedString)
        model.richTextLayout = textLayout
        
        //计算高度
        var height: CGFloat = kChatAvatarMarginTop + kChatBubblePaddingBottom + (kChatTimeStampHeight / 2.0)
        let stringHeight = modifier.heightForLineCount(Int(textLayout!.rowCount))
        
        height += max(stringHeight + kChatBubbleHeightBuffer + kChatBubbleBottomTransparentHeight, kChatBubbleImageViewHeight)
        model.cellHeight = height
        return model.cellHeight
    }
    
    override func setSelected(_ selected: Bool, animated: Bool) {
        super.setSelected(selected, animated: animated)
        
        // Configure the view for the selected state
    }
}
