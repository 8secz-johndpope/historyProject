//
//  TSChatImageCell.swift
//  TSWeChat
//
//  Created by Hilen on 12/22/15.
//  Copyright © 2015 Hilen. All rights reserved.
//

import UIKit
import SnapKit
import Kingfisher

let kChatImageMaxWidth: CGFloat = 140 //最大的图片宽度
let kChatImageMinWidth: CGFloat = 50 //最小的图片宽度
let kChatImageMaxHeight: CGFloat = 180 //最大的图片高度
let kChatImageMinHeight: CGFloat = 50 //最小的图片高度

class TSChatImageCell: TSChatBaseCell {
    
    @IBOutlet weak var chatImageView: UIImageView!
    @IBOutlet weak var coverImageView: UIImageView!
    @IBOutlet weak var loadingIndicator: UIActivityIndicatorView!
    @IBOutlet weak var lblTimestamp: UILabel!
    private final let mGradient = CAGradientLayer()
    
    override func awakeFromNib() {
        super.awakeFromNib()
        
        lblTimestamp.textColor = UIColor.secondary1()
        lblTimestamp.font = UIFont.systemFont(ofSize: 11)

        var colors = [CGColor]()
        colors.append(UIColor(red: 0, green: 0, blue: 0, alpha: 0.6).cgColor)
        colors.append(UIColor(red: 0, green: 0, blue: 0, alpha: 0).cgColor)
        mGradient.colors = colors
        
        mGradient.startPoint = CGPoint(x: 0.5, y: 1)
        mGradient.endPoint = CGPoint(x: 0.5, y: 0)

        chatImageView.layer.addSublayer(mGradient)

        //图片点击
        let tap = TapGestureRecognizer()
        self.chatImageView.addGestureRecognizer(tap)
        self.chatImageView.isUserInteractionEnabled = true
        tap.tapHandler = { [weak self] _ in
            if let strongSelf = self {
                guard let delegate = strongSelf.delegate else {
                    return
                }
                
                if let model = strongSelf.model {
                    delegate.cellDidTappedImageView(strongSelf, model: model)
                }
            }
        }
        
        let longPressGestureRecognizer = UILongPressGestureRecognizer(target: self, action: #selector(TSChatImageCell.longPressGestureRecognized))
        self.chatImageView.addGestureRecognizer(longPressGestureRecognizer)
    }
    
    override func setCellContent(_ model: ChatModel) {
        super.setCellContent(model)
        if let image = model.imageModel?.image {
            self.chatImageView.image = image
        } else if let localThumbnailImage = model.imageModel!.localThumbnailImage {
            self.chatImageView.image = localThumbnailImage
        } else if let url = model.imageModel?.thumbURL {
            self.chatImageView.isUserInteractionEnabled = false
            self.loadingIndicator.startAnimating()
            self.chatImageView.mm_setImageWithURLString(
                url,
                placeholderImage: UIImage(named: "holder"),
                contentMode: self.chatImageView.contentMode,
                progress: { (receivedSize, totalSize) in
                    model.downloadProgress = Float(Double(receivedSize) / Double(totalSize))
                },
                optionsInfo: [.transition(ImageTransition.fade(0.5))],
                completion: { image, _, _, _ in
                    self.loadingIndicator.stopAnimating()
                    self.chatImageView.isUserInteractionEnabled = true
                }
            )
        }
        
        self.lblTimestamp.text = model.timeDate.detailChatTimeString
        self.setNeedsLayout()
    }
    
    override func layoutContents() {
        super.layoutContents()
        guard let model = self.model else {
            return
        }
        
        guard let imageModel = model.imageModel else {
            return
        }
        
        var imageOriginalWidth = kChatImageMinWidth  //默认临时加上最小的值
        var imageOriginalHeight = kChatImageMinHeight   //默认临时加上最小的值
        
        if (imageModel.imageWidth != nil) {
            imageOriginalWidth = imageModel.imageWidth!
        }
        
        if (imageModel.imageHeight != nil) {
            imageOriginalHeight = imageModel.imageHeight!
        }
        
        //根据原图尺寸等比获取缩略图的 size
        let originalSize = CGSize(width: imageOriginalWidth, height: imageOriginalHeight)
        self.chatImageView.size = ChatConfig.getThumbImageSize(originalSize)

        if model.fromMe {
            //value = 屏幕宽 - 头像的边距10 - 头像宽 - 气泡距离头像的 gap 值 - 图片宽
            self.chatImageView.left = ScreenWidth - kChatAvatarMarginLeft - kChatAvatarWidth - kChatBubbleMaginLeft - self.chatImageView.width
        } else {
            //value = 距离屏幕左边的距离
            self.chatImageView.left = kChatBubbleLeft
        }
        
        self.chatImageView.top = self.avatarImageView.top
        self.loadingIndicator.center = self.chatImageView.center
        
        lblTimestamp.bottom = chatImageView.bottom
        lblTimestamp.right = chatImageView.right - 7
        mGradient.frame = CGRect(x: 0, y: chatImageView.bottom - 60, width: chatImageView.width, height: 60)

        /**
         *  绘制 imageView 的 bubble layer
         */
        self.chatImageView.layer.masksToBounds = true
        let path = model.fromMe ? UIBezierPath(roundedRect:self.chatImageView.bounds, byRoundingCorners:[.topLeft, .bottomLeft, .bottomRight], cornerRadii: CGSize(width: 10, height: 10)) : UIBezierPath(roundedRect:self.chatImageView.bounds, byRoundingCorners:[.topRight, .bottomLeft, .bottomRight], cornerRadii: CGSize(width: 10, height: 10))
        let maskLayer = CAShapeLayer()
        maskLayer.path = path.cgPath
        self.chatImageView.layer.mask = maskLayer
    }
    
    override var canBecomeFirstResponder : Bool {
        return true
    }
    
    override func canPerformAction(_ action: Selector, withSender sender: Any?) -> Bool {
        // You need to only return true for the actions you want, otherwise you get the whole range of
        //  iOS actions. You can see this by just removing the if statement here.
        if action == #selector(TSChatImageCell.saveImageTaped) {
            return true
        } else if action == #selector(TSChatImageCell.forwardImageTaped) {
            return true
        }
        return false
    }
    
    @objc func longPressGestureRecognized(_ gestureRecognizer: UIGestureRecognizer) {

        if (gestureRecognizer.state == UIGestureRecognizerState.began) {
            becomeFirstResponder()
            let save = UIMenuItem(title: String.localize("LB_AC_SAVE"), action: #selector(TSChatImageCell.saveImageTaped))
            let forward = UIMenuItem(title: String.localize("LB_CA_FORWARD"), action: #selector(TSChatImageCell.forwardImageTaped))
            let menuController = UIMenuController.shared
            menuController.menuItems = [save,forward]
            menuController.setTargetRect(self.chatImageView.frame, in: self)
            menuController.setMenuVisible(true, animated: true)
        }
    }
    @objc func saveImageTaped(_ sender: Any) {
        Log.debug("saveImageTaped")
        if self.delegate != nil {
            self.delegate?.saveImageDidTaped(self.chatImageView.image!)
        }
    }
    @objc func forwardImageTaped(_ sender: Any) {
        Log.debug("forwardImageTaped")
        if self.delegate != nil {
            self.delegate?.forwardImageDidTaped(self.chatImageView.image!)
        }
    }
    
    class func layoutHeight(_ model: ChatModel) -> CGFloat {
        if model.cellHeight != 0 {
            return model.cellHeight
        }
        
        guard let imageModel = model.imageModel else {
            return 0
        }
        
        var height = kChatAvatarMarginTop + kChatBubblePaddingBottom
        
        let imageOriginalWidth = imageModel.imageWidth!
        let imageOriginalHeight = imageModel.imageHeight!
        
        /**
        *  1）如果图片的高度 >= 图片的宽度 , 高度就是最大的高度，宽度等比
        *  2）如果图片的高度 < 图片的宽度 , 以宽度来做等比，算出高度
        */
        if imageOriginalHeight >= imageOriginalWidth {
            height += kChatImageMaxHeight
        } else {
//            let scaleHeight = imageOriginalHeight * kChatImageMaxWidth / imageOriginalWidth
//            height += ((scaleHeight > kChatImageMinHeight) ? scaleHeight : kChatImageMinHeight)
            height += kChatImageMaxWidth
        }
        height += 5  // 图片距离底部的距离 12
        
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


