//
//  TSChatTextView.swift
//  TSWeChat
//
//  Created by Hilen on 12/22/15.
//  Copyright © 2015 Hilen. All rights reserved.
//

import UIKit
import YYText

let kChatTextLeft: CGFloat = 72                                         //消息在左边的时候， 文字距离屏幕左边的距离
let kChatTextMaxWidth: CGFloat = ScreenWidth - kChatTextLeft - 82    //消息在右边， 70：文本离屏幕左的距离，  82：文本离屏幕右的距离
let kChatTextMarginTop: CGFloat = 10                                   //文字的顶部和气泡顶部相差 12 像素
let kChatTextMarginBottom: CGFloat = 10                                 //文字的底部和气泡底部相差 11 像素
let kChatTextMarginLeft: CGFloat = 10                                   //文字的左边 和气泡的左边相差 17 ,包括剪头部门
let kChatBubbleWidthBuffer: CGFloat = kChatTextMarginLeft*2             //气泡比文字的宽度多出的值
let kChatBubbleBottomTransparentHeight: CGFloat = 0                   //气泡底部的透明高度 11
let kChatBubbleHeightBuffer: CGFloat = kChatTextMarginTop + kChatTextMarginBottom  //文字的顶部 + 文字底部距离
let kChatBubbleImageViewHeight: CGFloat = 25                            //Bubble minimum high 54 against the tensile deformation image
let kChatBubbleImageViewWidth: CGFloat = 40                             //气泡最小宽 50 ，防止拉伸图片变形
let kChatBubblePaddingTop: CGFloat = 3                                  //气泡顶端有大约 3 像素的透明部分，需要和头像持平
let kChatBubbleMaginLeft: CGFloat = 5                                   //气泡和头像的 gap 值：5
let kChatBubblePaddingBottom: CGFloat = 4                               //气泡距离底部分割线 gap 值：8
let kChatBubbleLeft: CGFloat = kChatAvatarMarginLeft + kChatAvatarWidth + kChatBubbleMaginLeft  //气泡距离屏幕左的距
let kChatTimeStampHeight: CGFloat = 20
private let kChatTextFont: UIFont = UIFont.systemFont(ofSize: 16)

class TSChatTextCell: TSChatBaseCell {
    static var senderTextNodeBkg: UIImage!
    static var receiveTextNodeBkg: UIImage!
    var copyingEnabled = false
    var contentString: String?
    static func getSenderTextNodeBkg() ->UIImage {
        if senderTextNodeBkg == nil {
            let stretchImage = UIImage(named: "textBox_pink")
            senderTextNodeBkg = stretchImage!.resizableImage(withCapInsets: UIEdgeInsets(top: 30, left: 28, bottom: 30, right: 28), resizingMode: .stretch)
        }
        return senderTextNodeBkg
    }
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
            self!.didTapRichLabelText(self!.contentLabel, textRange: range)
        })
    }}
    @IBOutlet weak var bubbleImageView: UIImageView!
    override func awakeFromNib() {
        super.awakeFromNib()
        // Initialization code
        lblTimestamp.textColor = UIColor.secondary3()
        lblTimestamp.font = UIFont.systemFont(ofSize: 11)

        self.copyingEnabled = true
        let longPressGestureRecognizer = UILongPressGestureRecognizer(target: self, action: #selector(TSChatTextCell.longPressGestureRecognized))
        self.contentLabel.addGestureRecognizer(longPressGestureRecognizer)
    }
    
    @IBOutlet weak var lblTimestamp: UILabel!    
    func debugYYLabel() -> YYTextDebugOption {
        let debugOptions = YYTextDebugOption()
        debugOptions.baselineColor = UIColor.red;
        debugOptions.ctFrameBorderColor = UIColor.red;
        debugOptions.ctLineFillColor = UIColor ( red: 0.0, green: 0.463, blue: 1.0, alpha: 0.18 )
        debugOptions.cgGlyphBorderColor = UIColor ( red: 0.9971, green: 0.6738, blue: 1.0, alpha: 0.360964912280702 )
        return debugOptions
    }
    
    override func setCellContent(_ model: ChatModel) {
        super.setCellContent(model)
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

        //拉伸图片区域
//        let stretchImage = model.fromMe ? TSAsset.SenderTextNodeBkg.image : TSAsset.ReceiverTextNodeBkg.image
//        let bubbleImage = stretchImage.resizableImageWithCapInsets(UIEdgeInsets(top: 30, 28, left: 30, bottom: 28), right: resizingMode: .Stretch)
        
        self.bubbleImageView.image = (model.fromMe ? TSChatTextCell.getSenderTextNodeBkg() : TSChatTextCell.getRecieveTextNodeBkg())
        self.contentString = model.messageContent
       
        if let txt = contentString?.md5() {
            accessibilityIdentifier = "IM_UserChat-UILB_IM_CHAT_TEXT_MESSAGE"
            accessibilityValue = "\(txt)"
        }
        
        self.setNeedsLayout()
    }
    
    override func layoutContents() {
        super.layoutContents()
        guard let model = self.model else {
            return
        }
        var aSize: CGSize = model.richTextLayout?.textBoundingSize ?? CGSize()
        if let text = model.messageContent, text.containsEmoji() {
            aSize.height += 3 // for emoji, add 3 pixels
        }
        self.contentLabel.size = aSize
        let minWidth = CGFloat(70)

        if model.fromMe {
            //value = 屏幕宽 - 头像的边距10 - 头像宽 - 气泡距离头像的 gap 值 - (文字宽 - 2倍的文字和气泡的左右距离 , 或者是最小的气泡图片距离)
            let width = self.contentLabel.width < 50 ? 50 : self.contentLabel.width
            self.bubbleImageView.left = ScreenWidth - kChatAvatarMarginLeft - kChatAvatarWidth - kChatBubbleMaginLeft - max(width + kChatBubbleWidthBuffer, kChatBubbleImageViewWidth)
        } else {
            //value = 距离屏幕左边的距离
            self.bubbleImageView.left = kChatBubbleLeft
        }
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

    /**
     解析点击文字
     
     - parameter label:     YYLabel
     - parameter textRange: 高亮文字的 NSRange，不是 range
     */
    private func didTapRichLabelText(_ label: YYLabel, textRange: NSRange) {
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
    
    /*
    // Only override drawRect: if you perform custom drawing.
    // An empty implementation adversely affects performance during animation.
    override func drawRect(rect: CGRect) {
    // Drawing code
    }
    */
    
    override var canBecomeFirstResponder : Bool {
        return true
    }
    
    override func canPerformAction(_ action: Selector, withSender sender: Any?) -> Bool {
        // You need to only return true for the actions you want, otherwise you get the whole range of
        //  iOS actions. You can see this by just removing the if statement here.
        if action == #selector(TSChatTextCell.copyTextTaped(_:)) || action == #selector(TSChatTextCell.forwardTextDidTapped) {
            return true
        }
        return false
    }
    
    @objc func longPressGestureRecognized(_ gestureRecognizer: UIGestureRecognizer) {
        if (gestureRecognizer.state == UIGestureRecognizerState.began) {
            becomeFirstResponder()
            let save = UIMenuItem(title: String.localize("LB_CA_COPY"), action: #selector(TSChatTextCell.copyTextTaped))
            let forward = UIMenuItem(title: String.localize("LB_CA_FORWARD"), action: #selector(TSChatTextCell.forwardTextDidTapped))
            let menuController = UIMenuController.shared
            menuController.menuItems = [save,forward]
            menuController.setTargetRect(self.contentLabel.frame, in: self)
            menuController.setMenuVisible(true, animated: true)
        }
    }
    @objc func copyTextTaped(_ sender: Any) {
        Log.debug("copyTextTaped")
        let pasteboard = UIPasteboard.general
        pasteboard.string = self.contentString;
        
        showCopiedPopup()
    }
    
    
    
    @objc func forwardTextDidTapped(_ sender: Any) {
        Log.debug("forwardTextDidTapped")
        if self.delegate != nil {
            self.delegate?.forwardTextDidTapped(self.contentString!)
        } else {
            ErrorLogManager.sharedManager.recordNonFatalError(withException: .NullPointer)
        }
    }

}
