//
//  TSChatViewController+Subviews.swift
//  TSWeChat
//
//  Created by Hilen on 1/7/16.
//  Copyright © 2016 Hilen. All rights reserved.
//

import Foundation

private let kCustomKeyboardHeight: CGFloat = 216

// MARK: - @extension TSChatViewController
extension TSChatViewController {
    /**
     创建聊天的各种子 view
     */
    func setupSubviews(_ delegate: UITextViewDelegate) {
        self.initListTableViewTap()
        self.setupActionBar(delegate)
        self.setupKeyboardInputView()
        self.setupVoiceIndicatorView()
    }
    
    private func initListTableViewTap() {
        //点击 UITableView 隐藏键盘
        let tap = TapGestureRecognizer()
        tap.cancelsTouchesInView = false
        self.listTableView.addGestureRecognizer(tap)
        tap.tapHandler = { [weak self] _ in
            guard let strongSelf = self else {
                return
            }
            strongSelf.hideAllKeyboard()
        }
    }
    
    /**
     初始化操作栏
     */
    private func setupActionBar(_ delegate: UITextViewDelegate) {
        self.chatActionBarView = TSChatActionBarView.fromNib()
        self.chatActionBarView.delegate = self
        self.chatActionBarView.inputTextView.delegate = delegate
        self.view.addSubview(self.chatActionBarView)
        
        self.chatCommentActionBarView = TSChatActionBarView.fromNib()
        self.chatCommentActionBarView.delegate = self
        self.chatCommentActionBarView.inputTextView.delegate = delegate
        self.chatActionBarView.addSubview(self.chatCommentActionBarView)
        
        self.chatCommentActionBarView.backgroundColor = UIColor(hexString:"#FFDCE2")
        self.chatCommentActionBarView.isHidden =  true
    }
    
    /**
     初始化表情键盘，分享更多键盘
     */
    private func setupKeyboardInputView() {
        //emotionInputView init
        self.emotionInputView = TSChatEmotionInputView.fromNib()
        self.emotionInputView.delegate = self
        self.view.addSubview(self.emotionInputView)
        self.emotionInputView.snp.makeConstraints {[weak self] (make) -> Void in
            guard let strongSelf = self else {
                ErrorLogManager.sharedManager.recordNonFatalError(withException: .NullPointer)
                return
            }
            make.left.equalTo(strongSelf.view.snp.left)
            make.right.equalTo(strongSelf.view.snp.right)
            make.top.equalTo(strongSelf.chatActionBarView.snp.bottom).offset(0)
            make.height.equalTo(kCustomKeyboardHeight)
        }
        
        //shareMoreView init
        self.shareMoreView = TSChatShareMoreView.fromNib()
        self.shareMoreView!.delegate = self
        self.view.addSubview(self.shareMoreView)
        self.shareMoreView.snp.makeConstraints {[weak self] (make) -> Void in
            guard let strongSelf = self else {
                ErrorLogManager.sharedManager.recordNonFatalError(withException: .NullPointer)
                return
            }
            make.left.equalTo(strongSelf.view.snp.left)
            make.right.equalTo(strongSelf.view.snp.right)
            make.top.equalTo(strongSelf.chatActionBarView.snp.bottom).offset(0)
            make.height.equalTo(kCustomKeyboardHeight)
        }
        
        self.messageView = TSChatListPredefinedMessage.fromNib()
        self.messageView.analyticsViewKey = self.analyticsViewRecord.viewKey
        self.messageView.analyticsImpressionKey = self.view.analyticsImpressionKey
        
        self.view.addSubview(self.messageView)
        self.messageView.snp.makeConstraints {[weak self] (make) -> Void in
            guard let strongSelf = self else {
                ErrorLogManager.sharedManager.recordNonFatalError(withException: .NullPointer)
                return
            }
            make.left.equalTo(strongSelf.view.snp.left)
            make.right.equalTo(strongSelf.view.snp.right)
            make.top.equalTo(strongSelf.chatActionBarView.snp.bottom).offset(0)
            make.height.equalTo(kCustomKeyboardHeight)
        }
        
        self.messageView.delegate = self
    }
    
    /**
     初始化 VoiceIndicator
     */
    private func setupVoiceIndicatorView() {
        //voiceIndicatorView init
        self.voiceIndicatorView = TSChatVoiceIndicatorView.fromNib()
        self.view.addSubview(self.voiceIndicatorView)
        self.voiceIndicatorView.snp.makeConstraints {[weak self] (make) -> Void in
            guard let strongSelf = self else {
                ErrorLogManager.sharedManager.recordNonFatalError(withException: .NullPointer)
                return
            }
            make.left.equalTo(strongSelf.view.snp.left)
            make.top.equalTo(strongSelf.view.snp.top)
            make.bottom.equalTo(strongSelf.chatActionBarView.snp.bottom).offset(-60)
            make.right.equalTo(strongSelf.view.snp.right)
        }
        self.voiceIndicatorView.isHidden = true
    }
}


