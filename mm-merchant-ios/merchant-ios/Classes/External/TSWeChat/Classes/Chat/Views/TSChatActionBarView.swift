
//
//  TSChatActionBarView.swift
//  TSWeChat
//
//  Created by Hilen on 12/16/15.
//  Copyright © 2015 Hilen. All rights reserved.
//

import UIKit
// FIXME: comparison operators with optionals were removed from the Swift Standard Libary.
// Consider refactoring the code to use the non-optional operators.
private func < <T : Comparable>(lhs: T?, rhs: T?) -> Bool {
  switch (lhs, rhs) {
  case let (l?, r?):
    return l < r
  case (nil, _?):
    return true
  default:
    return false
  }
}

// FIXME: comparison operators with optionals were removed from the Swift Standard Libary.
// Consider refactoring the code to use the non-optional operators.
private func >= <T : Comparable>(lhs: T?, rhs: T?) -> Bool {
  switch (lhs, rhs) {
  case let (l?, r?):
    return l >= r
  default:
    return !(lhs < rhs)
  }
}


/**
 *  表情按钮和分享按钮来控制键盘位置
 */
protocol TSChatActionBarViewDelegate: class {
    /**
     不显示任何自定义键盘，并且回调中处理键盘frame
     当唤醒的自定义键盘时候，这时候点击切换录音 button。需要隐藏掉
     */
    func chatActionBarRecordVoiceHideKeyboard()
    
    /**
     显示表情键盘，并且处理键盘高度
     */
    func chatActionBarShowEmotionKeyboard()
    
    /**
     显示分享键盘，并且处理键盘高度
     */
    func chatActionBarShowShareKeyboard()
    
    func chatActionBarShowListMessage()
}

class TSChatActionBarView: UIView {
    enum ChatKeyboardType: Int {
        case `default`, text, emotion, share, message
    }
    
    var keyboardType: ChatKeyboardType? = .default
    weak var delegate: TSChatActionBarViewDelegate?
    
    @IBOutlet weak var containerView:UIView!
    
    @IBOutlet weak var inputTextView: MMPlaceholderTextView! { didSet{
        inputTextView.font = UIFont.systemFont(ofSize: 17)
        inputTextView.layer.borderColor = UIColor.secondary1().cgColor
        inputTextView.layer.borderWidth = 1
        inputTextView.layer.cornerRadius = inputTextView.bounds.height / 2
        inputTextView.scrollsToTop = false
        inputTextView.textContainerInset = UIEdgeInsets(top: 7, left: 5, bottom: 5, right: 5)
        inputTextView.backgroundColor = UIColor(hexString: "#ffffff")
        inputTextView.returnKeyType = .default
        inputTextView.isHidden = false
        inputTextView.enablesReturnKeyAutomatically = true
        inputTextView.layoutManager.allowsNonContiguousLayout = false
        inputTextView.scrollsToTop = false
        inputTextView.accessibilityIdentifier = "IM_UserChat-UIBT_IM_CHAT_KEYBOARD"
        }}
    
//    @IBOutlet weak var voiceButton: TSChatButton!
//    @IBOutlet weak var emotionButton: TSChatButton! { didSet{
//        emotionButton.showTypingKeyboard = false
//        }}
    
    @IBOutlet weak var shareButton: TSChatButton! { didSet{
        shareButton.showTypingKeyboard = false
        
        shareButton.accessibilityIdentifier = "IM_UserChat-UIBT_IM_ATTACHMENT"
        
        shareButton.snp.makeConstraints { [weak self] (make) in
            if let strongSelf = self {
                make.right.equalTo(strongSelf.containerView.snp.right).offset(-11)
                make.height.equalTo(35)
                make.width.equalTo(35)
                make.bottom.equalTo(strongSelf.containerView.snp.bottom).offset(-7)
            }
        }
        
        }}
    
    @IBOutlet weak var sendButton: TSChatButton! { didSet {
        sendButton.showTypingKeyboard = false
        
        sendButton.setTitle(String.localize("LB_SEND"), for: UIControlState())
        sendButton.setTitleColor(UIColor.primary1(), for: UIControlState())
        sendButton.isHidden = true
        sendButton.accessibilityIdentifier = "IM_UserChat-UIBT_IM_CHAT_SEND"
        
        sendButton.snp.makeConstraints { [weak self] (make) in
            if let strongSelf = self {
                make.right.equalTo(strongSelf.containerView.snp.right).offset(4)
                make.height.equalTo(35)
                make.width.equalTo(60)
                make.bottom.equalTo(strongSelf.containerView.snp.bottom).offset(-7)
            }
        }
        
        }}
    
    @IBOutlet weak var messageButton: TSChatButton! { didSet{
        messageButton.showTypingKeyboard = false
        
        messageButton.accessibilityIdentifier = "IM_UserChat-UIBT_IM_CHAT_PREDEFINED_MESSAGE"
        
        messageButton.snp.makeConstraints { [weak self] (make) in
            if let strongSelf = self {
                make.right.equalTo(strongSelf.containerView.snp.right).offset(-51)
                make.height.equalTo(35)
                make.width.equalTo(35)
                make.bottom.equalTo(strongSelf.containerView.snp.bottom).offset(-7)
            }
        }

        }}

    @IBOutlet weak var recordButton: TSChatButton! { didSet{
        
        recordButton.accessibilityIdentifier = "IM_UserChat-UIBT_RECORD_VOICE_MSG"
        
        recordButton.snp.makeConstraints { [weak self] (make) in
            if let strongSelf = self {
                make.left.equalTo(strongSelf.containerView.snp.left).offset(3)
                make.height.equalTo(49)
                make.width.equalTo(49)
                make.bottom.equalTo(strongSelf.containerView.snp.bottom).offset(-1)
            }
        }
        
        }}
    
    var animatingView: UIView!
    @IBOutlet weak var progressBarContainer: UIView! { didSet{
        progressBarContainer.snp.makeConstraints { [weak self] (make) in
            if let strongSelf = self {
                make.left.equalTo(strongSelf.containerView.snp.left).offset(49)
                make.right.equalTo(strongSelf.containerView.snp.right)
                make.height.equalTo(50)
                make.bottom.equalTo(strongSelf.containerView.snp.bottom)
            }
        }
        
        }}
    
    @IBOutlet weak var audioProgressBar: UIProgressView!
    @IBOutlet weak var counterLabel: TSChatLabel!
    weak var progressTimer: Timer!
    weak var countdownTimer: Timer!

    var progressTime: Float? = 0.0
    var countdownTime: Float? = 0.0
    
    let maxRecording: Float? = 60.0

    override init (frame: CGRect) {
        super.init(frame : frame)
        self.initContent()
    }
    
    convenience init () {
        self.init(frame:CGRect.zero)
        self.initContent()
    }
    
    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
    }
    
    func initContent() {
    }
    
    /**
     画两根线, 也可以贴两个 UIView , 哈哈
     */
    override func draw(_ rect: CGRect) {
        let scale = self.window!.screen.scale
        let width = 1 / scale
        let centerChoice: CGFloat = scale.truncatingRemainder(dividingBy: 2) == 0 ? 4 : 2
        let offset = scale / centerChoice * width
		
		if let context = UIGraphicsGetCurrentContext() {
			context.setLineWidth(width)
			context.setStrokeColor(UIColor(hexString: "#C2C3C7").cgColor)
			
			let x1: CGFloat = 0 + offset
			let y1: CGFloat = 0 + offset
			let x2: CGFloat = ScreenWidth + offset
			let y2: CGFloat = 0 + offset
			
			context.beginPath()
			context.move(to: CGPoint(x: x1, y: y1))
			context.addLine(to: CGPoint(x: x2, y: y2))
			
			let x3: CGFloat = 0 + offset
			let y3: CGFloat = 49.5 + offset
			let x4: CGFloat = ScreenWidth + offset
			let y4: CGFloat = 49.5 + offset
			
			context.move(to: CGPoint(x: x3, y: y3))
			context.addLine(to: CGPoint(x: x4, y: y4))
			context.strokePath()
		}

    }
	
    override func awakeFromNib() {

    }
    
    func getAdjustOffset(hidden keybord:Bool) -> CGFloat {
        
        var th = self.inputTextView.contentSize.height + 14
        if th < 50 {
            th = 50
        } else if th > 160 {
            th = 160
        }
        
        return keybord ? (ScreenBottom + th) : th
    }
    
    func adjustBarHeight(hidden keybord:Bool) {
        if ScreenBottom <= 0.0 {
            return
        }
        var th = self.inputTextView.contentSize.height + 14
        if th < 50 {
            th = 50
        } else if th > 106 {
            th = 160
        }
        let h = keybord ? (ScreenBottom + th) : th
        
        var f = self.frame
        if f.size.height == h {
            return
        }
        f.origin.y = f.origin.y + (f.size.height - h)
        f.size.height = h
        self.frame = f
    }
	
    deinit {
        log.verbose("deinit")
    }
}

// MARK: - @extension TSChatActionBarView
//控制键盘的各种互斥事件
extension TSChatActionBarView {
    //重置所有 Button 的图片
    func resetButtonUI() {
        self.recordButton.setImage(UIImage(named:"btn_voice"), for: UIControlState())
        self.recordButton.setImage(UIImage(named:"btn_voice_on"), for: .highlighted)
        self.recordButton.setImage(UIImage(named:"btn_voice_on"), for: .selected)
        
//        self.emotionButton.setImage(TSAsset.Tool_emotion_1.image, for: .normal)
//        self.emotionButton.setImage(TSAsset.Tool_emotion_2.image, for: .Highlighted)
        
        self.shareButton.setImage(UIImage(named:"btn_add"), for: UIControlState())
        self.shareButton.setImage(UIImage(named:"btn_add_cancel"), for: .selected)
        
        self.messageButton.setImage(UIImage(named:"predefine_off"), for: UIControlState())
        self.messageButton.setImage(UIImage(named:"predefine_on"), for: .selected)
    }
    
    //当是表情键盘 或者 分享键盘的时候，此时点击文本输入框，唤醒键盘事件。
    func inputTextViewCallKeyboard() {
        self.keyboardType = .text
        self.inputTextView.isHidden = false
        
        //设置接下来按钮的动作
        self.recordButton.showTypingKeyboard = false
//        self.emotionButton.showTypingKeyboard = false
        self.shareButton.showTypingKeyboard = false
        self.shareButton.isSelected = false
        
        self.messageButton.showTypingKeyboard = false
        self.messageButton.isSelected = false
    }
    
    func setCountdownTimer() {
        countdownTime! = 0.0
        countdownTimer = Timer.scheduledTimer(timeInterval: 1.0, target: self, selector:#selector(TSChatActionBarView.checkCountdown), userInfo: nil, repeats: true)
    }
    
    @objc func checkCountdown() {
        countdownTime! += 1.0
        self.counterLabel.text = Int(countdownTime!).description + "”"
        
        if maxRecording! - countdownTime! == 10 /*remaining time*/ {
            DispatchQueue.main.async {
                self.counterLabel.startBlink()
            }
        }
        if progressTime >= maxRecording {
            self.stopCountdownTimer()
            self.stopAudioTimer()
        }
    }
    
    func stopCountdownTimer() {
        if self.countdownTimer != nil {
            countdownTimer.invalidate()
        }
        countdownTime! = 0.0
    }
    
    func setAudioTimer() {
        progressTime! = 0.0
        progressTimer = Timer.scheduledTimer(timeInterval: 0.01, target: self, selector:#selector(TSChatActionBarView.setAudioProgress), userInfo: nil, repeats: true)
    }
    
    @objc func setAudioProgress() {
        progressTime! += 0.01
        self.audioProgressBar.progress = progressTime! / maxRecording!
    }
    
    func stopAudioTimer() {
        if self.progressTimer != nil {
            progressTimer.invalidate()
        }
        progressTime! = 0.0
    }
    
    func showAudioProgressView() {
        self.progressBarContainer.isHidden = false
        self.shareButton.isHidden = true
        self.sendButton.isHidden = true
        self.messageButton.isHidden = true
        self.inputTextView.isHidden = true
    }
    
    func hideAudioProgressView() {
        self.progressBarContainer.isHidden = true
        if inputTextView.text.length > 0 {
            self.shareButton.isHidden = true
            self.sendButton.isHidden = false
        } else {
            self.shareButton.isHidden = false
            self.sendButton.isHidden = true
        }
        self.messageButton.isHidden = false
        self.inputTextView.isHidden = false
    }
    
    func stopAudioRecordAnimation() {
        self.recordButton.addOnRecordButtonAnimation(isRecording: false)
        self.recordButton.isSelected = false
        self.counterLabel.stopBlink()
    }
    
    func resetAudioProgressView() {
        self.audioProgressBar.setProgress(0, animated: false)
        self.counterLabel.text = "0”"
    }

    //显示文字输入的键盘
    func showTyingKeyboard() {
        self.keyboardType = .text
        self.inputTextView.becomeFirstResponder()
        self.inputTextView.isHidden = false
        
        //设置接下来按钮的动作
//        self.recordButton.isHidden = true
        self.recordButton.showTypingKeyboard = false
//        self.emotionButton.showTypingKeyboard = false
        self.shareButton.showTypingKeyboard = false
        self.messageButton.showTypingKeyboard = false
    }
    
    //显示录音
    func showRecording() {
        self.keyboardType = .default
        self.inputTextView.resignFirstResponder()
        self.inputTextView.isHidden = true
        if let delegate = self.delegate {
            delegate.chatActionBarRecordVoiceHideKeyboard()
        }
        //设置接下来按钮的动作
//        self.recordButton.isHidden = false
        self.recordButton.showTypingKeyboard = true
//        self.emotionButton.showTypingKeyboard = false
        self.shareButton.showTypingKeyboard = false
        self.messageButton.showTypingKeyboard = false
    }
 
    /*
    显示表情键盘
    当点击唤起自定义键盘时，操作栏的输入框需要 resignFirstResponder，这时候会给键盘发送通知。
    通知在  TSChatViewController+Keyboard.swift 中需要对 actionbar 进行重置位置计算
    */
    func showEmotionKeyboard() {
        self.keyboardType = .emotion
        self.inputTextView.resignFirstResponder()
        self.inputTextView.isHidden = false
        self.adjustBarHeight(hidden: false)
        if let delegate = self.delegate {
            delegate.chatActionBarShowEmotionKeyboard()
        }
        
        //设置接下来按钮的动作
//        self.recordButton.isHidden = true
//        self.emotionButton.showTypingKeyboard = true
        self.shareButton.showTypingKeyboard = false
    }
    
    //显示分享键盘
    func showShareKeyboard() {
        self.keyboardType = .share
        self.inputTextView.resignFirstResponder()
        self.inputTextView.isHidden = false
        self.adjustBarHeight(hidden: false)
        if let delegate = self.delegate {
            delegate.chatActionBarShowShareKeyboard()
        }

        //设置接下来按钮的动作
//        self.recordButton.isHidden = true
//        self.emotionButton.showTypingKeyboard = false
        self.shareButton.showTypingKeyboard = true
        self.messageButton.showTypingKeyboard = false
        self.messageButton.isSelected = false
    }
    
    func showMessageKeyboard() {
        self.keyboardType = .message
        self.inputTextView.resignFirstResponder()
        self.inputTextView.isHidden = false
        adjustBarHeight(hidden: false)
        if let delegate = self.delegate {
            delegate.chatActionBarShowListMessage()
        }
        
        //设置接下来按钮的动作
        //        self.recordButton.isHidden = true
        //        self.emotionButton.showTypingKeyboard = false
        self.shareButton.showTypingKeyboard = false
        self.shareButton.isSelected = false
        self.messageButton.showTypingKeyboard = true
    }

    //取消输入
    func resignKeyboard() {
        self.keyboardType = .default
        self.inputTextView.resignFirstResponder()
        self.adjustBarHeight(hidden: true)
        //设置接下来按钮的动作
//        self.emotionButton.showTypingKeyboard = false
        self.shareButton.showTypingKeyboard = false
        self.shareButton.isSelected = false
        self.messageButton.showTypingKeyboard = false
        self.messageButton.isSelected = false
    }
    
    /**
     <暂无用到>
     控制切换键盘的时候光标的颜色
     如果是切到 表情或分享 ，就是透明
     如果是输入文字，就是蓝色
     
     - parameter color: 目标颜色
     */
    private func changeTextViewCursorColor(_ color: UIColor) {
        self.inputTextView.tintColor = color
        UIView.setAnimationsEnabled(false)
        self.inputTextView.resignFirstResponder()
        self.inputTextView.becomeFirstResponder()
        UIView.setAnimationsEnabled(true)
    }
}




