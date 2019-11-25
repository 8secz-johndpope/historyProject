//
//  TSChatViewController+Interaction.swift
//  TSWeChat
//
//  Created by Hilen on 12/31/15.
//  Copyright © 2015 Hilen. All rights reserved.
//

import Foundation
import Photos
import MobileCoreServices
import ObjectMapper
import SKPhotoBrowser
// MARK: - @protocol ChatShareMoreViewDelegate
// 分享更多里面的 Button 交互
extension TSChatViewController: ChatShareMoreViewDelegate,SearchProductViewDelegage {
   
//    
//    func imagePickerController(picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [String : Any]) {
//        picker.dismiss(animated: true, completion: nil)
//        var image = (info[UIImagePickerControllerOriginalImage] as? UIImage)!
//        image = image.normalizedImage()
//        self.resizeAndSendImage(image)
//    }

    
    func chatAttachFriend() {
        let friendListViewController = FriendListViewController()
        friendListViewController.isFromUserChat = true
        friendListViewController.friendListMode = FriendListMode.attachFriend
        friendListViewController.didShareToUserHandler = {[weak self] (data) in
            if let strongSelf = self {
                let userModel = UserModel()
                userModel.user = data
                let chatModel = ChatModel.init(userModel: userModel)
                chatModel.messageContentType = MessageContentType.ShareUser
                strongSelf.sendShareModel(chatModel.userModel!)
            } else {
                ErrorLogManager.sharedManager.recordNonFatalError(withException: .NullPointer)
            }
        }
        self.navigationController?.pushViewController(friendListViewController, animated: true)
    }
    func getDataFromSearchProduct(_ style: Style) {
        let productModel = ProductModel()
        productModel.style = style
        productModel.sku = style.defaultSku()
        let chatModel = ChatModel(productModel: productModel)
        chatModel.messageContentType = MessageContentType.Product
        
        self.navigationController?.popViewController(animated:true)
        self.forwardChatModel = chatModel
        
        var targetType: AnalyticsActionRecord.ActionElement = .ChatCustomer
        if let conv = self.conv {
            if conv.isFriendChat() {
                targetType = .ChatFriend
            } else if conv.isInternalChat() {
                targetType = .ChatInternal
            }
        }
        // Action tag
        self.view.analyticsViewKey = self.analyticsViewRecord.viewKey
        self.view.recordAction(
            .Send,
            sourceRef: chatModel.productModel?.style?.styleCode,
            sourceType: .Product,
            targetRef: self.conv?.convKey,
            targetType: targetType
        )
        
        self.forwardPendingMessage()
    }
    func chatAttachProduct() {
        let productListViewController = ProductListViewController()
        
        if let merchantId = conv?.merchantId {
            let styleFilter = StyleFilter()
            if merchantId != Constants.MMMerchantId {
                let merchant = Merchant()
                merchant.merchantId = merchantId
                styleFilter.merchants = [merchant]
            }
            
            productListViewController.setStyleFilter(styleFilter, isNeedSnapshot: true)
        }

//        productListViewController.isFromUserChat = true
        productListViewController.merchantId = conv?.merchantId != Constants.MMMerchantId ? conv?.merchantId : nil
//        productListViewController.discoverMode = .searchProduct
        productListViewController.isEnableAutoCompleteSearch = false
        productListViewController.getStyleDelegate = self
        self.navigationController?.pushViewController(productListViewController, animated: true)
    }
    
    func chatInsertComment() {
        self.chatCommentActionBarView.isHidden = false
        let textView: MMPlaceholderTextView = self.chatCommentActionBarView.inputTextView
        textView.placeholder = String.localize("LB_CS_COMMENT_TEXTBOX")
        textView.placeholderColor = UIColor.secondary3()
        textView.becomeFirstResponder()
    }
    
    //选择打开相册
    func chatShareMoreViewPhotoTaped() {
        let authStatus = Utils.checkPhotoPermission()
        
        if authStatus != .authorized && authStatus != .notDetermined {
            return
        }

        if authStatus == .notDetermined {
            PHPhotoLibrary.requestAuthorization({ (authStatus) in
                if authStatus != .authorized {
                    dispatch_async_safely_to_main_queue({ 
                        TSAlertView_show(String.localize("LB_CA_IM_ACCESS_PHOTOS_PERMIT"), message: String.localize("LB_CA_IM_ACCESS_PHOTOS_DENIED"), labelCancel: nil)
                    })
                }
                else {
                    DispatchQueue.main.async {
                        self.showPhotoPicker()
                    }
                }
            })
        }
        else {
            showPhotoPicker()
        }
        
    }
    
    func showPhotoPicker() {
        if UIDevice.current.userInterfaceIdiom == .phone {
            imagePicker.delegate = self
            imagePicker.sourceType = UIImagePickerControllerSourceType.photoLibrary
            self.present(imagePicker, animated: true, completion: nil)
        } else {
            Alert.alert(self, title: "Tablet not suported", message: "Tablet is not supported in this function")
        }
    }
    
    //选择打开相机
    func chatShareMoreViewCameraTaped() {
        let authStatus: AVAuthorizationStatus = AVCaptureDevice.authorizationStatus(for: AVMediaType.video)
        if authStatus == .notDetermined {
            self.checkCameraPermission { (granted) in
                if granted {
                    self.openCamera()
                }
            }
        } else if authStatus == .restricted || authStatus == .denied {
            TSAlertView_show(String.localize("LB_CA_IM_ACCESS_CAMERA_PERMIT"), message: String.localize("LB_CA_IM_ACCESS_CAMERA_DENIED"), labelCancel: nil)
        } else if authStatus == .authorized {
            self.openCamera()
        }
    }
//    不允許 確定
    
    func checkCameraPermission (completion: ((Bool) -> Void)?) {
        AVCaptureDevice.requestAccess(for: AVMediaType.video, completionHandler: {granted in
            if !granted {
                TSAlertView_show(String.localize("LB_CA_IM_ACCESS_CAMERA_PERMIT"), message: String.localize("LB_CA_IM_ACCESS_CAMERA_DENIED"), labelCancel: nil)
            }
            if let block = completion {
                block(granted)
            }
        })
    }
    
    func openCamera() {
        self.imagePicker =  UIImagePickerController()
        self.imagePicker.delegate = self
        self.imagePicker.sourceType = .camera
        self.present(self.imagePicker, animated: true, completion: nil)
    }
    
    //处理图片，并且发送图片消息
    func resizeAndSendImage(_ theImage: UIImage, forwardMode: Bool = false, actionElement: AnalyticsActionRecord.ActionElement = .Unknown) {
        let originalImage = UIImage.fixImageOrientation(theImage)
        let storeKey = "send_image"+String(format: "%f", Date.milliseconds)
        
        let thumbSize = ChatConfig.getSendImageSize(originalImage.size, inboundSize: Constants.ChatSendImageSetting.ImageBoundSize)
        
        guard let thumbNail = originalImage.resize(thumbSize) else {
            //获取缩略图失败 ，抛出异常：发送失败
            return
        }
        
        ImageFilesManager.storeImage(thumbNail, key: storeKey, completionHandler: { [weak self] in
            guard let strongSelf = self else {
                return
            }
            
            //发送图片消息
            let sendImageModel = ChatImageModel(image: thumbNail) //we send the resized images only
            sendImageModel.localStoreName = storeKey
            
            if actionElement != .Unknown {
                var targetType: AnalyticsActionRecord.ActionElement = .ChatCustomer
                if let conv = strongSelf.conv {
                    if conv.isFriendChat() {
                        targetType = .ChatFriend
                    } else if conv.isInternalChat() {
                        targetType = .ChatInternal
                    }
                }
                // Action tag
                strongSelf.view.analyticsViewKey = strongSelf.analyticsViewRecord.viewKey
                strongSelf.view.recordAction(
                    .Send,
                    sourceRef: sendImageModel.imageId,
                    sourceType: actionElement,
                    targetRef: strongSelf.conv?.convKey,
                    targetType: targetType
                )
            }
            
            strongSelf.chatSendImage(sendImageModel, forwardMode: forwardMode)
        })

    }
}

// MARK: - @protocol UIImagePickerControllerDelegate
// 拍照完成，进行上传图片，并且发送的请求
extension TSChatViewController: UINavigationControllerDelegate, UIImagePickerControllerDelegate,ImagePreviewViewControllerDelegate {
    func imagePickerController(_ picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [String : Any]) {
        guard let mediaType = info[UIImagePickerControllerMediaType] as? String else {
            return
        }
     
        if mediaType == (kUTTypeImage as String) {
            guard let image: UIImage = info[UIImagePickerControllerOriginalImage] as? UIImage else {
                return
            }
            if picker.sourceType == .camera {
                self.resizeAndSendImage(image, actionElement: .PhotoCamera)
                picker.dismiss(animated: true, completion: nil)
                if picker.sourceType == .camera {
                    CustomAlbumHelper.saveImageToAlbum(image)
                }
            } else {
                let controller = ImagePreviewViewController()
                controller.delegate = self
                controller.image = image.normalizedImage()
                imagePicker.pushViewController(controller, animated: true)
            }
        }
       
    }
    
    func imagePickerControllerDidCancel(_ picker: UIImagePickerController) {
        picker.dismiss(animated: true, completion: nil)
    }
    
    //MARK - ImagePreviewViewControllerDelegate
    func didChooseImage (_ image: UIImage){
        self.resizeAndSendImage(image, actionElement: .PhotoLibrary)
    }
}


// MARK: - @protocol RecordAudioDelegate
// 语音录制完毕后
extension TSChatViewController: RecordAudioDelegate {
    func audioRecordUpdateMetra(_ metra: Float) {
//        self.chatActionBarView.shareButton.updateMetraAnimation(metra)
    }
    
    func audioRecordTooShort() {
        self.voiceIndicatorView.messageTooShort()
    }
    
    func audioRecordTooLong() {
        self.voiceIndicatorView.messageTooLong()
    }
    
    func stopAudioRecording() {
        self.chatActionBarView.hideAudioProgressView()
        self.chatActionBarView.stopAudioTimer()
        self.chatActionBarView.stopCountdownTimer()
        self.chatActionBarView.stopAudioRecordAnimation()
    }

    func audioRecordFinish(_ uploadAmrData: Data, recordTime: Float, fileHash: String) {
        self.voiceIndicatorView.endRecord()
        
        //发送本地音频
        let audioModel = ChatAudioModel()
        audioModel.keyHash = fileHash
        audioModel.audioURL = ""
        audioModel.duration = recordTime
        audioModel.dataBody = uploadAmrData
        self.chatSendVoice(audioModel)
    }
    
    func audioRecordFailed() {
//        TSAlertView_show("录音失败，请重试")
    }
    
    func audioRecordCanceled() {
        
    }
}

// MARK: - @protocol PlayAudioDelegate
extension TSChatViewController: PlayAudioDelegate {
    /**
     播放完毕
     */
    func audioPlayStart() {
    
    }
    
    /**
     播放完毕
     */
    func audioPlayFinished() {
        self.currentVoiceCell.resetVoiceAnimation()
        
    }
    
    /**
     播放失败
     */
    func audioPlayFailed() {
        self.currentVoiceCell.resetVoiceAnimation()
    }
    
    
    /**
     播放被中断
     */
    func audioPlayInterruption() {
        self.currentVoiceCell.resetVoiceAnimation()
    }
    
    func audioProgressDidUpdate(_ progress: Float) {
        self.currentVoiceCell.updateVoiceProgress(progress)
    }
}


// MARK: - @protocol ChatEmotionInputViewDelegate
// 表情点击完毕后
extension TSChatViewController: ChatEmotionInputViewDelegate {
    //点击表情
    func chatEmoticonInputViewDidTapCell(_ cell: TSChatEmotionCell) {
        var string = self.chatActionBarView.inputTextView.text
        string = string?.appending(cell.emotionModel!.text)
        self.chatActionBarView.inputTextView.text = string
    }
    
    //点击撤退删除
    func chatEmoticonInputViewDidTapBackspace(_ cell: TSChatEmotionCell) {
        self.chatActionBarView.inputTextView.deleteBackward()
    }
    
    //点击发送文字，包含表情
    func chatEmoticonInputViewDidTapSend() {
        self.chatSendText()
    }
}

// MARK: - @protocol UITextViewDelegate
extension TSChatViewController: UITextViewDelegate {
    func textView(_ textView: UITextView, shouldChangeTextIn range: NSRange, replacementText text: String) -> Bool {
        
        if let textViewText = textView.text {
            let prospectiveText = (textViewText as NSString).replacingCharacters(in: range, with:text)
            
            if prospectiveText.length > 0 {
                
                if self.chatCommentActionBarView.isHidden {
                    self.chatActionBarView.sendButton.isHidden = false
                    self.chatActionBarView.shareButton.isHidden = true
                    
                    textView.snp.remakeConstraints { [weak self] (make) in
                        guard let strongSelf = self else { return }
                        
                        make.left.equalTo(strongSelf.chatActionBarView.containerView.snp.left).offset(57)
                        make.top.equalTo(strongSelf.chatActionBarView.containerView.snp.top).offset(7)
                        make.right.equalTo(strongSelf.chatActionBarView.containerView.snp.right).offset(-48)
                        make.height.equalTo(strongSelf.chatActionBarView.containerView.snp.height).offset(-14).priority(.medium)
                    }

                    
                } else {
                    
                    self.chatCommentActionBarView.sendButton.isHidden = false
                    self.chatCommentActionBarView.shareButton.isHidden = true
                    
                    textView.snp.remakeConstraints { [weak self] (make) in
                        guard let strongSelf = self else { return }
                        
                        make.left.equalTo(strongSelf.chatActionBarView.containerView.snp.left).offset(5)
                        make.top.equalTo(strongSelf.chatActionBarView.containerView.snp.top).offset(7)
                        make.right.equalTo(strongSelf.chatActionBarView.containerView.snp.right).offset(-48)
                        make.height.equalTo(strongSelf.chatActionBarView.containerView.snp.height).offset(-14).priority(.medium)
                    }
                }
                
            } else  {
                
                if self.chatCommentActionBarView.isHidden {
                    self.chatActionBarView.sendButton.isHidden = true
                    self.chatActionBarView.shareButton.isHidden = false
                    
                    textView.snp.remakeConstraints { [weak self] (make) in
                        guard let strongSelf = self else { return }
                        
                        make.left.equalTo(strongSelf.chatActionBarView.containerView.snp.left).offset(57)
                        make.top.equalTo(strongSelf.chatActionBarView.containerView.snp.top).offset(7)
                        make.right.equalTo(strongSelf.chatActionBarView.containerView.snp.right).offset(strongSelf.textInputOffset ?? -48)
                        make.height.equalTo(strongSelf.chatActionBarView.containerView.snp.height).offset(-14).priority(.medium)
                    }
                } else  {
                    self.chatCommentActionBarView.sendButton.isHidden = true
                    self.chatCommentActionBarView.shareButton.isHidden = false
                    
                    textView.snp.remakeConstraints { [weak self] (make) in
                        guard let strongSelf = self else { return }
                        
                        make.left.equalTo(strongSelf.chatActionBarView.containerView.snp.left).offset(5)
                        make.top.equalTo(strongSelf.chatActionBarView.containerView.snp.top).offset(7)
                        make.right.equalTo(strongSelf.chatActionBarView.containerView.snp.right).offset(-48)
                        make.height.equalTo(strongSelf.chatActionBarView.containerView.snp.height).offset(-14).priority(.medium)
                    }
                }
            }
                
        }
        
        if let orginalText = textView.text {
            let validToTriggerContactList = (orginalText.hasSuffix(" ") ||  orginalText.length == 0)
            
            if text == "@" && validToTriggerContactList && conv?.isGroupChat() == true {
                
                let contactListViewController = ContactListViewController()
                contactListViewController.friendListMode = FriendListMode.tagMode
                
                var otherMembers = [User]()
                if let otherUserRoleList = conv?.otherUserRoleList {
                    for userRole in otherUserRoleList {
                        if let userObj = userRole.userObj {
                            otherMembers.append(userObj)
                        }
                        
                    }
                }
                contactListViewController.otherMembersInGroup = otherMembers
                
                contactListViewController.didShareToUserHandler = { (data) in
                    textView.text = textView.text + "@\(data.displayName)"
                    textView.becomeFirstResponder()
                }
                
                contactListViewController.didTaggingBackHandler = {
                    textView.text = textView.text + "@"
                    textView.becomeFirstResponder()
                }
                
                let navigation = UINavigationController()
                navigation.navigationBar.isTranslucent = false
                navigation.viewControllers = [contactListViewController]
                self.present(navigation, animated: true, completion: nil)
                
                return false
            }
        }
        
        return true
    }
    
    func textViewDidChange(_ textView: UITextView) {
        
        if previousChatBoxHeight != textView.contentSize.height {
            previousChatBoxHeight = textView.contentSize.height
            
            let maxHeight = CGFloat(106)
            let height = self.chatActionBarView.getAdjustOffset(hidden:false)

            self.actionBarHeightConstraint?.update(offset: height)
            
            var textInputOffset = CGFloat(-48)
        
            if self.chatCommentActionBarView.isHidden {
                
                if self.chatActionBarView.sendButton.isHidden {
                    textInputOffset = self.textInputOffset ?? -48
                }

                if let conv = self.conv, conv.merchantObject != nil {
                    textView.snp.remakeConstraints { [weak self] (make) in
                        guard let strongSelf = self else { return }
                        
                        make.left.equalTo(strongSelf.chatActionBarView.containerView.snp.left).offset(57)
                        make.top.equalTo(strongSelf.chatActionBarView.containerView.snp.top).offset(7)
                        make.right.equalTo(strongSelf.chatActionBarView.containerView.snp.right).offset(textInputOffset)
                        make.height.equalTo(strongSelf.chatActionBarView.containerView.snp.height).offset(-14).priority(.medium)
                        make.height.lessThanOrEqualTo(maxHeight).priority(.high)
                    }
                }
                else {
                    textView.snp.remakeConstraints { [weak self] (make) in
                        guard let strongSelf = self else { return }
                        
                        make.left.equalTo(strongSelf.chatActionBarView.containerView.snp.left).offset(57)
                        make.top.equalTo(strongSelf.chatActionBarView.containerView.snp.top).offset(7)
                        make.right.equalTo(strongSelf.chatActionBarView.containerView.snp.right).offset(textInputOffset)
                        make.height.equalTo(strongSelf.chatActionBarView.containerView.snp.height).offset(-14).priority(.medium)
                        make.height.lessThanOrEqualTo(maxHeight).priority(.high)
                    }
                }
            }
            else {
                
                textView.snp.remakeConstraints { [weak self] (make) in
                    guard let strongSelf = self else { return }
                    
                    make.left.equalTo(strongSelf.chatActionBarView.containerView.snp.left).offset(5)
                    make.top.equalTo(strongSelf.chatActionBarView.containerView.snp.top).offset(7)
                    make.right.equalTo(strongSelf.chatActionBarView.containerView.snp.right).offset(-48)
                    make.height.equalTo(strongSelf.chatActionBarView.containerView.snp.height).offset(-14).priority(.medium)
                    make.height.lessThanOrEqualTo(maxHeight).priority(.high)
                }
            }

            if previousChatBoxHeight < maxHeight {
                self.perform(#selector(resetContentOffSet), with: nil, afterDelay: 0.1)
            }
        }
    }
    
    @objc func resetContentOffSet() {
        self.chatActionBarView.inputTextView.contentOffset = CGPoint(x: 0, y: 0)
        self.chatCommentActionBarView.inputTextView.contentOffset = CGPoint(x: 0, y: 0)
    }
    
    func textViewShouldBeginEditing(_ textView: UITextView) -> Bool {
        previousChatBoxHeight = textView.contentSize.height
        
        let maxHeight = CGFloat(106)
        
        let height = self.chatActionBarView.getAdjustOffset(hidden:false)
        
        self.actionBarHeightConstraint?.update(offset: height)

        if !self.chatCommentActionBarView.isHidden {
            textView.snp.remakeConstraints { [weak self] (make) in
                guard let strongSelf = self else { return }
                
                make.left.equalTo(strongSelf.chatCommentActionBarView.snp.left).offset(5)
                make.top.equalTo(strongSelf.chatCommentActionBarView.snp.top).offset(7)
                make.right.equalTo(strongSelf.chatCommentActionBarView.snp.right).offset(-48)
                make.height.equalTo(strongSelf.chatCommentActionBarView.snp.height).offset(-14).priority(.medium)
                make.height.lessThanOrEqualTo(maxHeight).priority(.high)
            }
        }
        
        //设置键盘类型，响应 UIKeyboardWillShowNotification 事件
        self.chatActionBarView.inputTextViewCallKeyboard()
        
        //使 UITextView 滚动到末尾的区域
        UIView.setAnimationsEnabled(false)
        let range = NSRange(location: textView.text.length - 1, length: 1)
        textView.scrollRangeToVisible(range)
        UIView.setAnimationsEnabled(true)
        return true
    }
}

// MARK: - @protocol ChatPredefinedMessageDelegate
extension TSChatViewController: ChatPredefinedMessageDelegate {
    
//    func messageDidPick(message: String, image: UIImage?) {
    func messageDidPick(_ message: String) {
        Log.debug("messageDidPick")
        
        chatActionBarView.inputTextView.text = message
        chatActionBarView.showTyingKeyboard()
        
        self.chatActionBarView.sendButton.isHidden = false
        self.chatActionBarView.shareButton.isHidden = true
        
        chatActionBarView.inputTextView.snp.remakeConstraints { [weak self] (make) in
            guard let strongSelf = self else { return }
            
            make.left.equalTo(strongSelf.chatActionBarView.containerView.snp.left).offset(57)
            make.top.equalTo(strongSelf.chatActionBarView.containerView.snp.top).offset(7)
            make.right.equalTo(strongSelf.chatActionBarView.containerView.snp.right).offset(-48)
            make.height.equalTo(strongSelf.chatActionBarView.containerView.snp.height).offset(-14).priority(.medium)
        }
    }
}


// MARK: - @protocol TSChatCellDelegate
extension TSChatViewController: TSChatCellDelegate {
    /**
     点击了 cell 本身
     */
    func cellDidTaped(_ cell: TSChatBaseCell) {
        Log.debug("cellDidTaped")
        
        switch cell {
        case is TSChatShareProductCell:
            
            // Action tag
            cell.recordAction(
                .Tap,
                sourceRef: cell.model?.messageId,
                sourceType: .Message,
                targetRef: "PDP",
                targetType: .View
            )
            
            let styleViewController = StyleViewController(style: cell.model?.productModel?.style)

            self.navigationController?.pushViewController(styleViewController, animated: true)
            
        case is TSShareUserCell:
            if let user = cell.model?.userModel?.user {

                // Action tag
                let targetRef = user.targetProfilePageTypeString()
                cell.recordAction(
                    .Tap,
                    sourceRef: cell.model?.messageId,
                    sourceType: .Message,
                    targetRef: targetRef,
                    targetType: .View
                )
                
                PushManager.sharedInstance.goToProfile(user, hideTabBar: true)
            }
            
        case is TSShareMerchantCell:
            
            // Action tag
            cell.recordAction(
                .Tap,
                sourceRef: cell.model?.messageId,
                sourceType: .Message,
                targetRef: "MPP",
                targetType: .View
            )
  
            if let merchant = cell.model?.merchantModel?.merchant {
                Navigator.shared.dopen(Navigator.mymm.website_merchant_merchantId + "\(merchant.merchantId)")
            }
            
        case is TSShareBrandCell:
            
            // Action tag
            cell.recordAction(
                .Tap,
                sourceRef: cell.model?.messageId,
                sourceType: .Message,
                targetRef: "MPP",
                targetType: .View
            )
            
            let brandViewController = BrandViewController()
            if let brand = cell.model?.brandModel?.brand {
                brandViewController.brand = brand
            }
            self.navigationController?.pushViewController(brandViewController, animated: true)
            
        case is TSSharePostCell:
            if let postId = (cell.model?.model as? PostModel)?.post?.postId {
                let postDetailController = PostDetailViewController(postId: postId)
                if let chatModel = cell.model{
                    let authorUser: User? = chatModel.fromMe ? self.conv?.me : self.presenter
                    postDetailController.referrerUserKey = authorUser?.userKey
                }
                if let post = (cell.model?.model as? PostModel)?.post {
                    postDetailController.post = post
                }
                self.navigationController?.pushViewController(postDetailController, animated: true)
                
                // Action tag
                cell.recordAction(
                    .Tap,
                    sourceRef: cell.model?.messageId,
                    sourceType: .Message,
                    targetRef: "PostDetail",
                    targetType: .View
                )
            } 
        case is TSSharePageCell:
            if let pageKey = (cell.model?.model as? MagazineCoverModel)?.magazineCover?.contentPageKey {
                let magazineContentViewController = MagazineContentViewController(pageKey: pageKey)
                self.navigationController?.pushViewController(magazineContentViewController, animated: true)
            }
        case is TSCouponCell:
            if let code = (cell.model?.model as? CouponModel)?.coupon?.couponReference {
                //TODO handle tapping
                Log.debug("Did click coupon: \(code)")
            }
        case is TSShareOrderCell:
            if let conv = self.conv, conv.IAmCustomer() {
                if let orderType = cell.model?.orderType, orderType == .OrderReturn {
                    if let order = cell.model?.orderModel?.order, let orderItems = order.orderItems {
                        
                        let data = OrderSectionData(sectionHeader: [], reuseIdentifier: OrderItemCell.CellIdentifier, dataSource: orderItems, viewMode: .afterSales)
                        data.order = order
                        
                        let afterSalesHistoryViewController = AfterSalesHistoryViewController()
                        afterSalesHistoryViewController.order = data.order
                        
                        afterSalesHistoryViewController.orderDisplayStatus = data.orderDisplayStatus
                        afterSalesHistoryViewController.orderSectionData = data
                        afterSalesHistoryViewController.originalViewMode = Constants.OmsViewMode.all
                        
                        if let orderReturns = order.orderReturns, orderReturns.count > 0 {
                            afterSalesHistoryViewController.afterSalesKey = orderReturns.first?.orderReturnKey
                        }
                        
                        self.navigationController!.pushViewController(afterSalesHistoryViewController, animated: true)
                    }
                }
                else if let order = cell.model?.orderModel?.order, order.orderStatus == .cancelled {
                    if let orderItems = order.orderItems {
                        let data = OrderSectionData(sectionHeader: [], reuseIdentifier: OrderItemCell.CellIdentifier, dataSource: orderItems, viewMode: .afterSales)
                        data.order = order
                        
                        let afterSalesHistoryViewController = AfterSalesHistoryViewController()
                        afterSalesHistoryViewController.order = data.order
                        
                        afterSalesHistoryViewController.orderDisplayStatus = data.orderDisplayStatus
                        afterSalesHistoryViewController.orderSectionData = data
                        afterSalesHistoryViewController.originalViewMode = Constants.OmsViewMode.all
                        
                        if let orderCancels = order.orderCancels, orderCancels.count > 0 {
                            afterSalesHistoryViewController.afterSalesKey = orderCancels.first?.orderCancelKey
                        }
                        
                        self.navigationController!.pushViewController(afterSalesHistoryViewController, animated: true)
                    }
                }
                else if let order = cell.model?.orderModel?.order {
                    if let orderItems = order.orderItems{
                        
                        let data = OrderSectionData(sectionHeader: [], reuseIdentifier: OrderItemCell.CellIdentifier, dataSource: orderItems)
                        data.order = order
                        
                        if order.orderShipments != nil && order.orderShipments!.count > 0 {
                            data.orderShipment = order.orderShipments![0]
                        }
                        
                        let orderStatusData = OrderStatusData(order: data.order!, orderDisplayStatus: data.orderDisplayStatus)
                        data.insert(dataItem: orderStatusData, at: 0) //insert to data source at index 0
                        
                        let orderPriceData = OrderPriceData(order: data.order!)
                        data.append(dataItem: orderPriceData)  //append to data source
                        
                        let orderActionData = OrderActionData(order: data.order!, orderDisplayStatus: data.orderDisplayStatus)
                        data.append(dataItem: orderActionData) //append to data source
                        
                        let orderDetailViewController = OrderDetailViewController()
                        orderDetailViewController.orderSectionData = data
                        orderDetailViewController.originalViewMode = .all
                        self.navigationController?.pushViewController(orderDetailViewController, animated: true)
                    }
                }
            }
            
        case is TSShipmentCell:
            if let conv = self.conv, conv.IAmCustomer() {
                let orderType = cell.model?.shipmentModel?.orderType ?? .Order
                if orderType == .OrderReturn {//order return
                    if let order = cell.model?.shipmentModel?.orderReturn?.order{
                        if let orderItems = order.orderItems{
                            if let orderReturn = cell.model?.shipmentModel?.orderReturn{
                                order.orderReturns = [orderReturn]
                                let data = OrderSectionData(sectionHeader: [], reuseIdentifier: OrderItemCell.CellIdentifier, dataSource: orderItems, viewMode: .afterSales)
                                data.order = order
                                
                                let afterSalesHistoryViewController = AfterSalesHistoryViewController()
                                afterSalesHistoryViewController.order = data.order
                                afterSalesHistoryViewController.afterSalesKey = orderReturn.orderReturnKey
                                afterSalesHistoryViewController.orderDisplayStatus = data.orderDisplayStatus
                                afterSalesHistoryViewController.orderSectionData = data
                                afterSalesHistoryViewController.originalViewMode = Constants.OmsViewMode.all
                                self.navigationController!.pushViewController(afterSalesHistoryViewController, animated: true)
                            }
                        }
                    }
                } else {//shipment
                    if cell.model?.dataType == .OrderCancelNotification{//cancel shipment
                        if let orderCancelKey = cell.model?.shipmentModel?.orderCancel?.order?.orderKey {
                            DeepLinkManager.sharedManager.pushOrderPage(viewController: self, orderKey: orderCancelKey)
                        }
                    }
                    else{//shipment other types
                        if let orderKey = cell.model?.shipmentModel?.shipment?.orderKey, orderKey != "" {
                            DeepLinkManager.sharedManager.pushOrderPage(viewController: self, orderKey: orderKey)
                        }
                        else if let text = cell.model?.orderShipmentKey {
                            let components = text.components(separatedBy: "|")
                            
                            if !components.isEmpty {
                                let orderKey = components[0]
                                DeepLinkManager.sharedManager.pushOrderPage(viewController: self, orderKey: orderKey)
                            }
                        }
                    }
                }
            }
            
        case is TSChatTransferCell:
            if let convKey = cell.model?.transferRedirectModel?.transferConvKey {
                
                reloadConversation(Conv(convKey: convKey))

            }
        case is TSMasterCouponCell:
            if let merchantId = cell.model?.merchantId {
                Navigator.shared.dopen(Navigator.mymm.website_coupon_center + "\(merchantId)")
            }

        default: break
        }
    }
    
    /**
     点击了 cell 的头像
     */
    func cellDidTapedAvatarImage(_ cell: TSChatBaseCell) {
        
        if cell.model!.fromMe {
            return
        }
        let user = User()
        
        guard let model = cell.model, let userKey = model.chatSendId else {
            return
        }
        user.userKey = userKey
        
        PushManager.sharedInstance.goToProfile(user, hideTabBar: true)
    }
    
    /**
     点击了 cell 的图片
     */
    func cellDidTappedImageView(_ cell: TSChatBaseCell, model: ChatModel) {
        var images = [SKPhoto]()
        
        for imageData in self.imageDataSouce {
            if let image = imageData.imageModel?.image {
                let photo = SKPhoto.photoWithImage(image)
                images.append(photo)
            } else if let url = imageData.imageModel?.thumbURL {
                let photo = SKPhoto.photoWithImageURL(url)
                photo.shouldCachePhotoURLImage = true
                images.append(photo)
            } else if let localThumbnailImage = model.imageModel!.localThumbnailImage {
                let photo = SKPhoto.photoWithImage(localThumbnailImage)
                images.append(photo)
            }
        }
        
        guard images.count >= self.imageDataSouce.count else {
            return
        }
        
        let browser = SKPhotoBrowser(photos: images)
        let initialIndex = model.tag
        browser.initializePageIndex(initialIndex)
        self.navigationController?.present(browser, animated: true, completion: {})
    }
    
    /**
     点击了 cell 中文字的 URL
     */
    func cellDidTapedLink(_ cell: TSChatBaseCell, linkString: String) {
        
        if linkString.hasPrefix("#") {
            var hashTagValue = String(linkString.dropFirst())
            hashTagValue = hashTagValue.replacingOccurrences(of: "#", with: "")
            Navigator.shared.dopen(Navigator.mymm.deeplink_dk_tag_tagName + Urls.encoded(str: hashTagValue))
        } else if let deepUrl =  URL(string: linkString) {
            if let deeplinkDict = DeepLinkManager.sharedManager.getDeepLinkTypeValue(linkString), let deepLinkType = deeplinkDict.keys.first as DeepLinkManager.DeepLinkType? {
                switch deepLinkType {
                case .Campaign:
                    if let deepLinkValue = deeplinkDict[deepLinkType], deepLinkValue.lowercased() == "incentivereferral" {
                       BannerManager.sharedManager.pushCampaignViewController()
                    }
                    return
                default:
                    break
                }
            }
            Navigator.shared.dopen(deepUrl.absoluteString)
//            let webViewController = WebViewController()
//            webViewController.url = deepUrl as URL
//            webViewController.isTabBarHidden = true
//            self.navigationController?.pushViewController(webViewController, animated: true)
            
        }
    }
    
    /**
     点击了 cell 中文字的 电话
     */
    func cellDidTapedPhone(_ cell: TSChatBaseCell, phoneString: String) {
        TSAlertView_show("点击了电话")
    }
    
    /**
     点击了声音 cell 的播放 button
     */
    func cellDidTapedVoiceButton(_ cell: TSChatVoiceCell?, isPlayingVoice: Bool) {
        //在切换选中的语音 cell 之前把之前的动画停止掉
        if self.currentVoiceCell != nil && self.currentVoiceCell != cell {
            self.currentVoiceCell.resetVoiceAnimation()
        }
        
        guard let cell = cell, let indexPath = self.listTableView.indexPath(for: cell) else {
            return
        }

        if isPlayingVoice {
            itemDataSouce[indexPath.row].isPlayingAudio = true
            for (index, dataSource) in itemDataSouce.enumerated() {
                if dataSource.dataType == .AudioUUID && index != indexPath.row {
                    dataSource.isPlayingAudio = false
                }
            }
            
            self.currentVoiceCell = cell
            guard let audioModel = cell.model?.audioModel else {
                itemDataSouce[indexPath.row].isPlayingAudio = false
                AudioPlayInstance.stopPlayer()
                return
            }
            AudioPlayInstance.startPlaying(audioModel)
        } else {
            itemDataSouce[indexPath.row].isPlayingAudio = false
            AudioPlayInstance.stopPlayer()
        }
    }
    
    func cellDidPressLong(_ cell: TSChatBaseCell) {
        Log.debug("cellDidPressLong")
        
        switch cell {
        case is TSCouponCell:
            // Action tag - Copy coupon
            if let conv = self.conv {
                let targetRef = conv.chatTypeString()
                cell.recordAction(
                    .Copy,
                    sourceRef: cell.model?.couponCode,
                    sourceType: .Coupon,
                    targetRef: targetRef,
                    targetType: .View
                )
            }
            break
        default:
            break
        }
    }
}




