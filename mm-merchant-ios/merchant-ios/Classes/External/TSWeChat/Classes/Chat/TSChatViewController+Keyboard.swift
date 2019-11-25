//
//  TSChatViewController+Keyboard.swift
//  TSWeChat
//
//  Created by Hilen on 12/18/15.
//  Copyright © 2015 Hilen. All rights reserved.
//

import Foundation

//http://stackoverflow.com/questions/4279730/keep-uitableview-static-when-inserting-rows-at-the-top/11602040#11602040 Keep uitableview static when inserting rows at the top

/*
所有的键盘动画都是控制 chatActionBar 的 bottomConstraint。
表情键盘和分享键盘的约束都是依赖 chatActionBar
*/

// MARK: - @extension TSChatViewController
extension TSChatViewController {
    /**
     键盘控制
     */
    func keyboardControl() {
        
        var tempObserver: AnyObject
        
        /**
         Keyboard notifications
         */
        let notificationCenter = NotificationCenter.default
        tempObserver = notificationCenter.addObserver(self, name: NSNotification.Name.UIKeyboardWillShow.rawValue, object: nil, handler: {
            [weak self] observer, notification in
            guard let strongSelf = self else {
                ErrorLogManager.sharedManager.recordNonFatalError(withException: .NullPointer)
                return
            }
            strongSelf.listTableView.scrollToBottomAnimated(false)
            strongSelf.keyboardControl(notification, isShowing: true)
        }) as AnyObject
        self.keyboardObservers.append(tempObserver)
        
        tempObserver = notificationCenter.addObserver(self, name: NSNotification.Name.UIKeyboardDidShow.rawValue, object: nil, handler: {observer, notification in
            if let keyboardSize = (notification.userInfo?[UIKeyboardFrameBeginUserInfoKey] as? NSValue)?.cgRectValue {
                _ = UIEdgeInsets(top: 0, left: 0, bottom: keyboardSize.height, right: 0)
            }
        }) as AnyObject
        self.keyboardObservers.append(tempObserver)
        
        tempObserver = notificationCenter.addObserver(self, name: NSNotification.Name.UIKeyboardWillHide.rawValue, object: nil, handler: {
            [weak self] observer, notification in
            guard let strongSelf = self else {
                ErrorLogManager.sharedManager.recordNonFatalError(withException: .NullPointer)
                return
            }
            strongSelf.keyboardControl(notification, isShowing: false)
        }) as AnyObject
        self.keyboardObservers.append(tempObserver)
        
        tempObserver = notificationCenter.addObserver(self, name: NSNotification.Name.UIKeyboardDidHide.rawValue, object: nil, handler: { observer, notification in
        }) as AnyObject
        self.keyboardObservers.append(tempObserver)

//        notificationCenter.addObserverForName(
//            UIKeyboardWillChangeFrameNotification,
//            object: nil,
//            queue: nil
//            ) {[weak self] (notification) in
//                return
//                //如果是 表情键盘或者 分享键盘 ，走自己的处理键盘事件。高度 和 inputview 动画
//                let keyboardType = self!.chatActionBarView.keyboardType
//                if keyboardType == .Emotion || keyboardType == .Share {
//                    return
//                }
//                
//                let userInfo = notification.userInfo!
//                let frameEnd = userInfo[UIKeyboardFrameEndUserInfoKey]!.CGRectValue
//                let convertedFrameEnd = self!.view.convertRect(frameEnd, fromView: nil)
//                let heightOffset = self!.view.bounds.size.height - convertedFrameEnd.origin.y
//                let curve = userInfo[UIKeyboardAnimationCurveUserInfoKey]!.unsignedIntValue
//                let options = UIViewAnimationOptions(rawValue: UInt(curve) << 16)
//                
//                self!.listTableView.stopScrolling()
//                self!.actionBarPaddingBottomConstranit?.updateOffset(-heightOffset)
//                self!.tableViewMarginBottomConstraint.constant = heightOffset + self!.chatActionBarView.height
//                UIView.animate(withDuration: 
//                    userInfo[UIKeyboardAnimationDurationUserInfoKey]!.doubleValue,
//                    delay: 0,
//                    options: options.union(.LayoutSubviews).union(.BeginFromCurrentState),
//                    animations: {
//                        self!.view.layoutIfNeeded()
//                    },
//                    completion: { bool in
//                })
//        }
    }
    
    
    func removeKeyboardControl() {
        
        for currentObserver in keyboardObservers {
            let notificationCenter = NotificationCenter.default
            if let observer = currentObserver as? NSObjectProtocol {
                notificationCenter.removeObserver(observer)
            }
        }
        keyboardObservers.removeAll()
    }
    
    /**
     控制键盘事件
     http://stackoverflow.com/questions/19311045/uiscrollview-animation-of-height-and-contentoffset-jumps-content-from-bottom
     - parameter notification: NSNotification 对象
     - parameter isShowing:    是否显示键盘？
     */
    func keyboardControl(_ notification: Notification, isShowing: Bool) {
        /*
        如果是表情键盘或者 分享键盘 ，走自己 delegate 的处理键盘事件。

        因为：当点击唤起自定义键盘时，操作栏的输入框需要 resignFirstResponder，这时候会给键盘发送通知。
        通知中需要对 actionbar frame 进行重置位置计算, 在 delegate 回调中进行计算。所以在这里进行拦截。
        Button 的点击方法中已经处理了 delegate。
        */
        let keyboardType = self.chatActionBarView.keyboardType
        if keyboardType == .emotion || keyboardType == .share || keyboardType == .message {
            return
        }
        
        /*
        处理 Default, Text 的键盘属性
        */
        var userInfo = notification.userInfo!
        let keyboardRect = (userInfo[UIKeyboardFrameEndUserInfoKey] as! NSValue).cgRectValue
        let curve = (userInfo[UIKeyboardAnimationCurveUserInfoKey] as! NSNumber).uint32Value
        
        let convertedFrame = self.view.convert(keyboardRect, from: nil)
        let heightOffset = self.view.bounds.size.height - convertedFrame.origin.y
        let options = UIViewAnimationOptions(rawValue: UInt(curve) << 16 | UIViewAnimationOptions.beginFromCurrentState.rawValue)
        let duration = (userInfo[UIKeyboardAnimationDurationUserInfoKey] as! NSNumber).doubleValue

        self.listTableView.stopScrolling()
        self.actionBarPaddingBottomConstraint?.update(offset: -heightOffset)

        var contentInsets = UIEdgeInsets.zero
        if isShowing {
            contentInsets = UIEdgeInsets(top: 0.0, left: 0.0, bottom: keyboardRect.size.height, right: 0.0)
        }

        UIView.animate(
            withDuration: duration,
            delay: 0,
            options: options,
            animations: {
                self.listTableView.contentInset = contentInsets
                self.listTableView.scrollIndicatorInsets = contentInsets
//                if isShowing {
//                    self.listTableView.scrollBottomToLastRow()
//                }
//                self.view.layoutIfNeeded()
            },
            completion: { bool in
                if isShowing {
                    self.listTableView.scrollBottomToLastRow()
                }
        })
    }
    
    //获取键盘的高度
    func appropriateKeyboardHeight(_ notification: Notification) -> CGFloat {
        let endFrame = (notification.userInfo![UIKeyboardFrameEndUserInfoKey] as! NSValue).cgRectValue
        var keyboardHeight: CGFloat = 0.0
        if notification.name == NSNotification.Name.UIKeyboardWillShow {
            keyboardHeight = min(endFrame.width, endFrame.height)
        }
        
        if notification.name.rawValue == "" {
            keyboardHeight = UIScreen.main.bounds.height - endFrame.origin.y
            keyboardHeight -= self.tabBarController!.tabBar.frame.height
        }
        return keyboardHeight
    }
    
    func appropriateKeyboardHeight()-> CGFloat {
        var height = self.view.bounds.size.height
        height -= self.keyboardHeightConstraint!.constant
        
        guard height > 0 else {
            return 0
        }
        return height
    }
    
    /**
     隐藏自定义键盘，当唤醒的自定义键盘时候，这时候点击切换录音 button。需要隐藏掉
     */
    private func hideCusttomKeyboard() {
        
        let keyboardType = self.chatActionBarView.keyboardType
        if keyboardType == .default || keyboardType == .text {
            return
        }
        
        let heightOffset: CGFloat = 0
        self.listTableView.stopScrolling()
        self.actionBarPaddingBottomConstraint?.update(offset: -heightOffset)
        let contentInsets = UIEdgeInsets(top: 0.0, left: 0.0, bottom: heightOffset, right: 0.0)
        self.chatActionBarView.shareButton.isSelected = false
        UIView.animate(
            withDuration: 0.25,
            delay: 0,
            options: UIViewAnimationOptions(),
            animations: {
                self.listTableView.contentInset = contentInsets
                self.listTableView.scrollIndicatorInsets = contentInsets
                
                self.tableViewMarginBottomConstraint.constant = self.chatActionBarView.height
                self.view.layoutIfNeeded()
            },
            completion: { bool in
        })
    }
    
    /**
     隐藏所有键盘, 
     使用场景：
        1.点击 UITableView 使用
        2.开始滚动 UITableView 使用
     */
    func hideAllKeyboard() {
        self.hideCusttomKeyboard()
        self.chatActionBarView.resignKeyboard()
        self.chatCommentActionBarView.resignKeyboard()
        self.chatCommentActionBarView.isHidden = true
    }
}

// MARK: - @delegate TSChatActionBarViewDelegate
extension TSChatViewController: TSChatActionBarViewDelegate {
    /**
     隐藏自定义键盘
     */
    func chatActionBarRecordVoiceHideKeyboard() {
        self.hideCusttomKeyboard()
    }
    
    /**
     调起表情键盘
     */
    func chatActionBarShowEmotionKeyboard() {
        let heightOffset = self.emotionInputView.height
        self.listTableView.stopScrolling()
        self.actionBarPaddingBottomConstraint?.update(offset: -heightOffset)
        let contentInsets = UIEdgeInsets(top: 0.0, left: 0.0, bottom: heightOffset, right: 0.0)
    
        UIView.animate(
            withDuration: 0.25,
            delay: 0,
            options: UIViewAnimationOptions(),
            animations: {
                //表情键盘归位
//                self.chatActionBarView.adjustBarHeight(hidden: false)
                self.emotionInputView.snp.updateConstraints { make in
                    make.top.equalTo(self.chatActionBarView.snp.bottom).offset(0)
                }
                //分享键盘隐藏
                self.shareMoreView.snp.updateConstraints { make in
                    make.top.equalTo(self.chatActionBarView.snp.bottom).offset(self.view.height)
                }
                self.listTableView.contentInset = contentInsets
                self.listTableView.scrollIndicatorInsets = contentInsets
                self.listTableView.scrollBottomToLastRow()
                self.view.layoutIfNeeded()
            },
            completion: { [weak self] bool in
                if bool {
                    self?.chatActionBarView.adjustBarHeight(hidden: false)
                }
        })
    }
    
    /**
     调起分享键盘
     */
    func chatActionBarShowShareKeyboard() {
        let heightOffset = self.shareMoreView.height
        self.listTableView.stopScrolling()
        self.actionBarPaddingBottomConstraint?.update(offset: -heightOffset)
        let contentInsets = UIEdgeInsets(top: 0.0, left: 0.0, bottom: heightOffset, right: 0.0)
        
        self.shareMoreView.top = self.view.height
        self.view.bringSubview(toFront: self.shareMoreView)
        let options = UIViewAnimationOptions()
        
        UIView.animate(
            withDuration: 0.25,
            delay: 0,
            options: options.union(.layoutSubviews).union(.beginFromCurrentState),
            animations: {
                //分享键盘归位，盖在表情键盘上，所以不需要控制表情键盘
//                self.chatActionBarView.adjustBarHeight(hidden: false)
                self.shareMoreView.snp.updateConstraints { make in
                    make.top.equalTo(self.chatActionBarView.snp.bottom).offset(0)
                }
                self.listTableView.contentInset = contentInsets
                self.listTableView.scrollIndicatorInsets = contentInsets
//                self.view.layoutIfNeeded()
                self.listTableView.scrollBottomToLastRow()
                
                self.tableViewMarginBottomConstraint.constant = heightOffset + self.chatActionBarView.height
                self.view.layoutIfNeeded()

            },
            completion: { [weak self] bool in
                if bool {
                    self?.chatActionBarView.adjustBarHeight(hidden: false)
                }
        })
    }
    
    func chatActionBarShowListMessage() {
        let heightOffset = self.messageView.height
        self.listTableView.stopScrolling()
        self.actionBarPaddingBottomConstraint?.update(offset: -heightOffset)
        let contentInsets = UIEdgeInsets(top: 0.0, left: 0.0, bottom: heightOffset, right: 0.0)
        
        self.messageView.conv = self.conv
        self.messageView.top = self.view.height
        self.view.bringSubview(toFront: self.messageView)
        let options = UIViewAnimationOptions()
        
        UIView.animate(
            withDuration: 0.25,
            delay: 0,
            options: options.union(.layoutSubviews).union(.beginFromCurrentState),
            animations: {
                //分享键盘归位，盖在表情键盘上，所以不需要控制表情键盘
//                self.chatActionBarView.adjustBarHeight(hidden: false)
                self.messageView.snp.updateConstraints { make in
                    make.top.equalTo(self.chatActionBarView.snp.bottom).offset(0)
                }
                self.listTableView.contentInset = contentInsets
                self.listTableView.scrollIndicatorInsets = contentInsets
                //                self.view.layoutIfNeeded()
                self.listTableView.scrollBottomToLastRow()
                
                self.tableViewMarginBottomConstraint.constant = heightOffset + self.chatActionBarView.height
                self.view.layoutIfNeeded()
                
            },
            completion: { [weak self] bool in
                if bool {
                    self?.chatActionBarView.adjustBarHeight(hidden: false)
                }
        })
    }
}






