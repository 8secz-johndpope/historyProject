//
//  TSChatVoiceView.swift
//  TSWeChat
//
//  Created by Hilen on 12/22/15.
//  Copyright © 2015 Hilen. All rights reserved.
//

import UIKit

private let kChatVoiceBubbleTopTransparentGapValue: CGFloat = 7  //气泡顶端有大约 7 像素的透明部分，绿色部分需要和头像持平
private let kChatVoicePlayingMarginLeft: CGFloat = 16  //播放小图标距离气泡箭头的值
private let kChatVoiceMaxWidth: CGFloat = 200
private let kChatVoiceMinWidth: CGFloat = 100
private let kChatVoiceHeight: CGFloat = 40
private let kChatVoiceIndicatorTopPadding: CGFloat = 6
private let kChatVoiceIndicatorLeftPadding: CGFloat = 10
private let kChatVoiceIndicatorRightPadding: CGFloat = 5
private let kChatVoiceDurationPadding: CGFloat = 5

class TSChatVoiceCell: TSChatBaseCell {
    @IBOutlet weak var listenVoiceButton: UIButton! {
        didSet{
            listenVoiceButton.isSelected = false
        }
    }
    
    @IBOutlet weak var actionView: UIView!
    
    @IBOutlet weak var statusIndicatorView: UIImageView!
    @IBOutlet weak var progressView: MMProgressView!
    @IBOutlet weak var durationLabel: UILabel!
    @IBOutlet weak var lblTimestamp: UILabel!
    
    override func awakeFromNib() {
        super.awakeFromNib()
        
        lblTimestamp.textColor = UIColor.secondary3()
        lblTimestamp.font = UIFont.systemFont(ofSize: 11)

        let longPress = UILongPressGestureRecognizer(target: self, action: #selector(TSChatVoiceCell.longPressGestureRecognized))
        actionView.addGestureRecognizer(longPress)
        
        let tap = TapGestureRecognizer()
        actionView.addGestureRecognizer(tap)
        tap.tapHandler = { [weak self] _ in
            if let strongSelf = self, let model = strongSelf.model {
                
                model.isPlayingAudio = !model.isPlayingAudio
                strongSelf.listenVoiceButton.isSelected = model.isPlayingAudio
                strongSelf.statusIndicatorView.isHighlighted = model.isPlayingAudio
                
                strongSelf.progressView.progress = 0
                
                guard let delegate = strongSelf.delegate else {
                    return
                }
                
                delegate.cellDidTapedVoiceButton(strongSelf, isPlayingVoice: model.isPlayingAudio)
            } else {
                ErrorLogManager.sharedManager.recordNonFatalError(withException: .NullPointer)
            }
        }
    }
    
    override func prepareForReuse() {
        super.prepareForReuse()
        
        listenVoiceButton.isSelected = false
        statusIndicatorView.isHighlighted = false
        progressView.progress = 0
    }
    
    override func layoutSubviews() {
        super.layoutSubviews()
        
        if let model = self.model {
            listenVoiceButton.isSelected = model.isPlayingAudio
            statusIndicatorView.isHighlighted = model.isPlayingAudio
        }
    }
    
    override func setCellContent(_ model: ChatModel) {
        super.setCellContent(model)
        self.durationLabel.text = String(format:"%zd”", Int(model.audioDuration))
        
        //设置 play/pause image
        self.statusIndicatorView.image = UIImage(named: "play")
        self.statusIndicatorView.highlightedImage = UIImage(named: "play_on")
        
        //设置 Normal 背景Image
        let bubbleImage = (model.fromMe ? TSChatTextCell.getSenderTextNodeBkg() : TSChatTextCell.getRecieveTextNodeBkg())
        self.listenVoiceButton.setBackgroundImage(bubbleImage, for: UIControlState())
        
        //设置 Highlighted  背景Image
        let bubbleImageHL = (model.fromMe ? TSChatTextCell.getSenderTextNodeBkg() : TSChatTextCell.getRecieveTextNodeBkg())
        self.listenVoiceButton.setBackgroundImage(bubbleImageHL, for: .highlighted)
        
        self.lblTimestamp.text = model.timeDate.detailChatTimeString
    }
    
    //停止音频的动画
    func resetVoiceAnimation() {
        self.listenVoiceButton.isSelected = false
        self.statusIndicatorView.isHighlighted = false
        self.progressView.progress = 0
        
        self.model?.isPlayingAudio = false
    }
    
    func updateVoiceProgress(_ progress: Float) {
        if let model = self.model, model.isPlayingAudio {
            self.progressView.progress = progress
        }
    }
    
    override func layoutContents() {
        super.layoutContents()
        guard let model = self.model else {
            return
        }
        
//        guard model.audioDuration > 0 else {
//            return
//        }
        
        let voiceLength = kChatVoiceMinWidth + kChatVoiceMinWidth * CGFloat(model.audioDuration/60)
        
        self.listenVoiceButton.width = min(voiceLength, kChatVoiceMaxWidth)
        self.listenVoiceButton.height = kChatVoiceHeight + kChatTimeStampHeight
        self.listenVoiceButton.top = kChatAvatarMarginTop
        
        self.actionView.width = min(voiceLength, kChatVoiceMaxWidth)
        self.actionView.height = kChatVoiceHeight + kChatTimeStampHeight
        self.actionView.top = kChatAvatarMarginTop

        if model.fromMe {
            self.listenVoiceButton.left = ScreenWidth - kChatAvatarMarginLeft - kChatAvatarWidth - kChatBubbleMaginLeft - self.listenVoiceButton.width
            self.actionView.left = ScreenWidth - kChatAvatarMarginLeft - kChatAvatarWidth - kChatBubbleMaginLeft - self.actionView.width

        } else {
            self.listenVoiceButton.left = kChatBubbleLeft
            self.actionView.left = kChatBubbleLeft
        }
        
        self.statusIndicatorView.top = self.listenVoiceButton.top + kChatVoiceIndicatorTopPadding
        self.statusIndicatorView.left = self.listenVoiceButton.left + kChatVoiceIndicatorLeftPadding
        
        self.durationLabel.frame = CGRect(
            x: self.listenVoiceButton.right - self.durationLabel.width - kChatVoiceIndicatorRightPadding,
            y: self.statusIndicatorView.frame.midY - self.durationLabel.height / 2,
            width: self.durationLabel.width,
            height: self.durationLabel.height
        )
        
        self.progressView.frame = CGRect(
            x: self.statusIndicatorView.right,
            y: self.statusIndicatorView.frame.midY - self.progressView.height / 2,
            width: self.durationLabel.left - self.statusIndicatorView.right - kChatVoiceDurationPadding,
            height: self.progressView.size.height
        )
        
        self.lblTimestamp.bottom = listenVoiceButton.bottom
        self.lblTimestamp.right = listenVoiceButton.right - 7
    }
    
    class func layoutHeight(_ model: ChatModel) -> CGFloat {
        return kChatAvatarMarginTop + kChatBubblePaddingBottom + kChatTimeStampHeight + kChatVoiceHeight
    }
    
    override func setSelected(_ selected: Bool, animated: Bool) {
        super.setSelected(selected, animated: animated)
        
        // Configure the view for the selected state
    }
    
    @objc func longPressGestureRecognized(_ gestureRecognizer: UIGestureRecognizer) {
        
        if gestureRecognizer.state == .began {
            
            becomeFirstResponder()
            let forward = UIMenuItem(title: String.localize("LB_CA_FORWARD"), action: #selector(TSChatVoiceCell.forwardVoiceTaped))
            let menuController = UIMenuController.shared
            menuController.menuItems = [forward]
            menuController.setTargetRect(self.listenVoiceButton.frame, in: self)
            menuController.setMenuVisible(true, animated: true)
            
        }

    }
    
    @objc func forwardVoiceTaped(_ sender: Any) {
        if let delegate = self.delegate {
            
            guard let model = self.model, let audioModel = model.audioModel else {
                return
            }
            
            audioModel.duration = Float(model.audioDuration)
            delegate.forwardVoiceDidTaped(audioModel)
        }
    }
    
    override var canBecomeFirstResponder : Bool {
        return true
    }
    
    override func canPerformAction(_ action: Selector, withSender sender: Any?) -> Bool {
        // You need to only return true for the actions you want, otherwise you get the whole range of
        //  iOS actions. You can see this by just removing the if statement here.
        if action == #selector(TSChatVoiceCell.forwardVoiceTaped) {
            return true
        }
        
        return false
    }
    
    deinit {
        NotificationCenter.default.removeObserver(self)
    }

    /*
    // Only override drawRect: if you perform custom drawing.
    // An empty implementation adversely affects performance during animation.
    override func drawRect(rect: CGRect) {
        // Drawing code
    }
    */

}
