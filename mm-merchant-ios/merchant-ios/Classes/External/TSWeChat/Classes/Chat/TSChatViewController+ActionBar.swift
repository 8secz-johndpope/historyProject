//
//  TSChatViewController+ActionBar.swift
//  TSWeChat
//
//  Created by Hilen on 1/4/16.
//  Copyright © 2016 Hilen. All rights reserved.
//

import Foundation

// MARK: - @extension TSChatViewController
extension TSChatViewController {
    /**
     初始化操作栏的 button 事件。包括 声音按钮，录音按钮，表情按钮，分享按钮 等各种事件的交互
     */
    func setupActionBarButtonInterAction(_ isAgent: Bool = false) {
//        let voiceButton: TSChatButton = self.chatActionBarView.voiceButton
        let recordButton: TSChatButton = self.chatActionBarView.recordButton
//        let emotionButton: TSChatButton = self.chatActionBarView.emotionButton
        let shareButton: TSChatButton = self.chatActionBarView.shareButton
        
        let sendButton: TSChatButton = self.chatActionBarView.sendButton
        
        //切换声音按钮
//        voiceButton.rx_tap.subscribeNext{[weak self] _ in
//            guard let strongSelf = self else {
//                return
//            }
//            strongSelf.chatActionBarView.resetButtonUI()
//            //根据不同的状态进行不同的键盘交互
//            if strongSelf.chatActionBarView.recordButton.hidden {
//                strongSelf.chatActionBarView.showRecording()
//                voiceButton.emotionSwiftVoiceButtonUI(showKeyboard: true)
//            } else {
//                strongSelf.chatActionBarView.showTyingKeyboard()
//                voiceButton.emotionSwiftVoiceButtonUI(showKeyboard: false)
//            }
//        }.addDisposableTo(self.disposeBag)
        
        
        //录音按钮
        var finishRecording: Bool = true  //控制滑动取消后的结果，决定停止录音还是取消录音
        let longTap = LongPressGestureRecognizer()
        longTap.minimumPressDuration = 0.002
        recordButton.addGestureRecognizer(longTap)
        longTap.longPressHandler = { [weak self] sender in
            guard let strongSelf = self else {
                ErrorLogManager.sharedManager.recordNonFatalError(withException: .NullPointer)
                return
            }
            
            if sender.state == .began { //长按开始
                if !AudioRecordInstance.checkPermissionAndSetupRecord() {
                    return
                }
                
                // reset audio playback ui when recording started
                strongSelf.cellDidTapedVoiceButton(nil, isPlayingVoice: false)
                
                finishRecording = true
                strongSelf.voiceIndicatorView.recording()
                strongSelf.chatActionBarView.resetAudioProgressView()
                strongSelf.chatActionBarView.showAudioProgressView()
                strongSelf.chatActionBarView.setAudioTimer()
                strongSelf.chatActionBarView.setCountdownTimer()
                AudioRecordInstance.startRecord()
                recordButton.addOnRecordButtonAnimation(isRecording: true)
                recordButton.isSelected = true
                if shareButton.isSelected {
                    strongSelf.shareMoreView.isUserInteractionEnabled = false
                }
                if strongSelf.chatActionBarView.messageButton.isSelected {
                    strongSelf.messageView.isUserInteractionEnabled = false
                }
                strongSelf.listTableView.isUserInteractionEnabled = false
                strongSelf.navigationController?.navigationBar.isUserInteractionEnabled = false
            } else if sender.state == .changed { //长按平移
                if !strongSelf.voiceIndicatorView.isMessageTooLong {
                    let point = sender.location(in: self!.voiceIndicatorView)
                    if strongSelf.voiceIndicatorView.point(inside: point, with: nil) {
                        strongSelf.voiceIndicatorView.slideToCancelRecord()
                        finishRecording = false
                    } else {
                        strongSelf.voiceIndicatorView.recording()
                        finishRecording = true
                    }
                }
            } else if sender.state == .ended { //长按结束
                if finishRecording {
                    AudioRecordInstance.stopRecord()
                } else {
                    AudioRecordInstance.cancelRecord()
                }
                strongSelf.voiceIndicatorView.endRecord()
                recordButton.addOnRecordButtonAnimation(isRecording: false)
                recordButton.isSelected = false
                strongSelf.chatActionBarView.hideAudioProgressView()
                strongSelf.chatActionBarView.stopAudioTimer()
                strongSelf.chatActionBarView.stopCountdownTimer()
                strongSelf.voiceIndicatorView.isMessageTooLong = false
                strongSelf.shareMoreView.isUserInteractionEnabled = true
                strongSelf.messageView.isUserInteractionEnabled = true
                strongSelf.listTableView.isUserInteractionEnabled = true
                strongSelf.navigationController?.navigationBar.isUserInteractionEnabled = true
            }
        }
        
        
        //表情按钮
//        emotionButton.rx_tap.subscribeNext{[weak self] _ in
//            guard let strongSelf = self else {
//                return
//            }
//            strongSelf.chatActionBarView.resetButtonUI()
//            //设置 button 的UI
//            emotionButton.replaceEmotionButtonUI(showKeyboard: !emotionButton.showTypingKeyboard)
//            //根据不同的状态进行不同的键盘交互
//            if emotionButton.showTypingKeyboard {
//                strongSelf.chatActionBarView.showTyingKeyboard()
//            } else {
//                strongSelf.chatActionBarView.showEmotionKeyboard()
//            }
//        }.addDisposableTo(self.disposeBag)
        
        
        //分享按钮
        shareButton.tapHandler = { [weak self] _ in
            guard let strongSelf = self else {
                ErrorLogManager.sharedManager.recordNonFatalError(withException: .NullPointer)
                return
            }
            
            strongSelf.chatActionBarView.resetButtonUI()
            //根据不同的状态进行不同的键盘交互
            if shareButton.showTypingKeyboard {
                shareButton.isSelected = false
                strongSelf.chatActionBarView.showTyingKeyboard()
            } else {
                strongSelf.chatActionBarView.showShareKeyboard()
                shareButton.isSelected = true
            }
            
            
        }
        
        sendButton.tapHandler = { [weak self] _ in
            guard let strongSelf = self else {
                ErrorLogManager.sharedManager.recordNonFatalError(withException: .NullPointer)
                return
            }
            
            strongSelf.chatSendText()
            let keyBoardHidden = strongSelf.chatActionBarView.bottom == strongSelf.view.bottom ? true : false
            strongSelf.actionBarHeightConstraint?.update(offset: strongSelf.chatActionBarView.getAdjustOffset(hidden:keyBoardHidden))
            
        }

        
        //文字框的点击，唤醒键盘
        let textView: UITextView = self.chatActionBarView.inputTextView
        let tap = TapGestureRecognizer()
        textView.addGestureRecognizer(tap)
        tap.tapHandler = { _ in
            textView.inputView = nil
            textView.becomeFirstResponder()
            textView.reloadInputViews()
        }
        
        var rect = textView.frame
        rect.size.width = Constants.ScreenSize.SCREEN_WIDTH - rect.minX - 47
        textView.frame = rect
        
        self.chatActionBarView.snp.makeConstraints { [weak self] (make) -> Void in
            guard let strongSelf = self else {
                ErrorLogManager.sharedManager.recordNonFatalError(withException: .NullPointer)
                return
            }
            make.left.equalTo(strongSelf.view.snp.left)
            make.right.equalTo(strongSelf.view.snp.right)
            strongSelf.actionBarPaddingBottomConstraint = make.bottom.equalTo(strongSelf.view.snp.bottom).constraint
            strongSelf.actionBarHeightConstraint = make.height.equalTo(strongSelf.chatActionBarView.getAdjustOffset(hidden:true)).constraint
        }

        if isAgent {
            textView.snp.makeConstraints { [weak self] (make) in
                guard let strongSelf = self else {
                    ErrorLogManager.sharedManager.recordNonFatalError(withException: .NullPointer)
                    return
                }
                
                make.left.equalTo(strongSelf.chatActionBarView.containerView.snp.left).offset(57)
                make.top.equalTo(strongSelf.chatActionBarView.containerView.snp.top).offset(7)
                make.right.equalTo(strongSelf.chatActionBarView.containerView.snp.right).offset(-91)
                strongSelf.textInputOffset = -91
                make.height.equalTo(strongSelf.chatActionBarView.containerView.snp.height).offset(-14).priority(.medium)
            }
        }
        else {
            textView.snp.makeConstraints { [weak self] (make) in
                guard let strongSelf = self else {
                    ErrorLogManager.sharedManager.recordNonFatalError(withException: .NullPointer)
                    return
                }
                
                make.left.equalTo(strongSelf.chatActionBarView.containerView.snp.left).offset(57)
                make.top.equalTo(strongSelf.chatActionBarView.containerView.snp.top).offset(7)
                make.right.equalTo(strongSelf.chatActionBarView.containerView.snp.right).offset(-48)
                strongSelf.textInputOffset = -48
                make.height.equalTo(strongSelf.chatActionBarView.containerView.snp.height).offset(-14).priority(.medium)
            }
        }
    }
    
    func setupActionBarForAgent() {
        setupActionBarButtonInterAction(true)
        let messageButton: TSChatButton = self.chatActionBarView.messageButton

        messageButton.tapHandler = { [weak self] _ in
            guard let strongSelf = self else {
                ErrorLogManager.sharedManager.recordNonFatalError(withException: .NullPointer)
                return
            }
            strongSelf.chatActionBarView.resetButtonUI()
            //根据不同的状态进行不同的键盘交互
            if messageButton.showTypingKeyboard {
                messageButton.isSelected = false
                strongSelf.chatActionBarView.showTyingKeyboard()
            } else {
                strongSelf.chatActionBarView.showMessageKeyboard()
                messageButton.isSelected = true
            }
            
        }
    }
    
    func setupActionBarForAgentComment() {
        
        self.chatCommentActionBarView.messageButton.isHidden = true
        self.chatCommentActionBarView.recordButton.isHidden = true
        
        self.chatCommentActionBarView.shareButton.addTarget(self, action: #selector(dismissCommentActionBar), for: .touchUpInside)
        
        self.chatCommentActionBarView.sendButton.addTarget(self, action: #selector(sendCommentActionBarHandle), for: .touchUpInside)
        
        self.chatCommentActionBarView.snp.makeConstraints { [weak self] (make) -> Void in
            guard let strongSelf = self else {
                ErrorLogManager.sharedManager.recordNonFatalError(withException: .NullPointer)
                return
            }
            make.left.equalTo(strongSelf.chatActionBarView.containerView.snp.left)
            make.right.equalTo(strongSelf.chatActionBarView.containerView.snp.right)
            make.bottom.equalTo(strongSelf.chatActionBarView.containerView.snp.bottom)
            make.top.equalTo(strongSelf.chatActionBarView.containerView.snp.top)
        }
        
        self.chatCommentActionBarView.inputTextView.snp.makeConstraints( { [weak self] (make) -> Void in
            guard let strongSelf = self else {
                ErrorLogManager.sharedManager.recordNonFatalError(withException: .NullPointer)
                return
            }
            
            make.left.equalTo(strongSelf.chatCommentActionBarView.snp.left).offset(5)
            make.top.equalTo(strongSelf.chatCommentActionBarView.snp.top).offset(7)
            make.right.equalTo(strongSelf.chatCommentActionBarView.snp.right).offset(-48)
            make.height.equalTo(strongSelf.chatCommentActionBarView.snp.height).offset(-14)
        })
        
    }
    
    @objc func dismissCommentActionBar() {
        self.chatCommentActionBarView.inputTextView.resignFirstResponder()
        self.chatCommentActionBarView.isHidden = true
    }
    
    @objc func sendCommentActionBarHandle() {
        self.chatSendText()
        self.actionBarHeightConstraint?.update(offset: self.chatActionBarView.getAdjustOffset(hidden:true))
    }
}
