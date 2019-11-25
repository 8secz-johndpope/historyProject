//
//  ForwardChatViewController.swift
//  merchant-ios
//
//  Created by HungPM on 6/1/16.
//  Copyright © 2016 WWE & CO. All rights reserved.
//

import Foundation
import PromiseKit
import MBProgressHUD

class ForwardChatViewController: MmViewController, ImagePickerManagerDelegate ,SearchProductViewDelegage{
    
    private final let MerchantCellID = "MerchantCellID"
    private final let SwitchCellID = "SwitchCellID"
    private final let CommentCellID = "CommentCellID"
    private final let AttachedProductCellID = "AttachedProductCellID"
    private final let UploadPhotoCellID = "UploadPhotoCellID"
    private final let DefaultCellID = "DefaultCellID"

    private final let MerchantCellHeight = CGFloat(60)
    private final let SwitchCellHeight = CGFloat(70)
    private final let CommentCellHeight = CGFloat(120)
    private final let ProductCellHeight = CGFloat(134)
    private final let ImageCellHeight = CGFloat(130)

    private final var uploadPhotoCell: UploadPhotoCell?
    private final var switchCell: ForwardChatSwitchCell?
    private final var commentCell: ForwardChatCommentCell?
    private final var imagePickerManager: ImagePickerManager?
    private final var productModel: ProductModel?
    private final var singleTap: UITapGestureRecognizer?
    private var sourceMerchantId: Int?
    
    var conv: Conv?
    var pickedMerchant: (merchant: Merchant, queueType: QueueType)?
    var finishedForwardingChat: ((_ stayOn: Bool) -> ())?
    var finishedTransferChat: ((_ stayOn: Bool, _ convKey: String) -> ())?
    
    // MARK: - View lifecycle
    override func viewDidLoad() {
        super.viewDidLoad()
        
        setupNavigationBar()
        
        if let merchantId = pickedMerchant?.merchant.merchantId, merchantId != Constants.MMMerchantId {
            sourceMerchantId = merchantId
        }
        
        setupCollectionView()
    }
    
    func setupCollectionView() {
        self.collectionView.register(ForwardChatMerchantCell.self, forCellWithReuseIdentifier: MerchantCellID)
        self.collectionView.register(ForwardChatSwitchCell.self, forCellWithReuseIdentifier: SwitchCellID)
        self.collectionView.register(ForwardChatCommentCell.self, forCellWithReuseIdentifier: CommentCellID)
        self.collectionView.register(ForwardChatProductCell.self, forCellWithReuseIdentifier: AttachedProductCellID)
        self.collectionView.register(UploadPhotoCell.self, forCellWithReuseIdentifier: UploadPhotoCellID)
        self.collectionView.register(UICollectionViewCell.self, forCellWithReuseIdentifier: DefaultCellID)

        self.collectionView.backgroundColor = UIColor.clear
    }
    
    func setupNavigationBar() {
        self.title = String.localize("LB_CS_FORWARD_CHAT_TO")
        self.createRightButton(String.localize("LB_CS_FORWARD_CHAT"), action: #selector(forwardButtonTapped))
        let leftButton = UIButton(type: .custom)
        leftButton.setImage(UIImage(named: "icon_cross"), for: UIControlState())
        leftButton.frame = CGRect(x: 0, y: 0, width: 30, height: 30)
        leftButton.addTarget(self, action: #selector(cancelButtonTapped), for: .touchUpInside)
        self.navigationItem.leftBarButtonItem = UIBarButtonItem(customView: leftButton)
    }

    // MARK: - Actions
    @objc func cancelButtonTapped() {
        Log.debug("cancelButtonTapped")
        
        self.dismiss(animated: true, completion: nil)
    }
    
    @objc func forwardButtonTapped() {
        Log.debug("forwardButtonTapped")
        
        guard self.pickedMerchant != nil else {
            Alert.alertWithSingleButton(self, title: "", message: String.localize("MSG_ERR_CS_FORWARD_AGENT_EMPTY"), buttonString: String.localize("LB_OK"))
            return
        }
        
        if Reachability.shared().currentReachabilityStatus() == NotReachable {
            Alert.alertWithSingleButton(self, title: "", message: String.localize("MSG_ERR_NETWORK_FAIL"), buttonString: String.localize("LB_CA_CONFIRM"))
            return
        }
        
        showLoading()
        
        if isTransferMessage() {
            // Transfer Chat
            if let pickedMerchant = self.pickedMerchant {
                
                if let oldConv = self.conv, let customer = oldConv.customer(), let myUserRole = oldConv.myUserRole {
                    var userList = [UserRole]()
                    userList.append(UserRole(userKey: customer.userKey))
                    if let switchCell = self.switchCell, switchCell.swt.isOn {
                        userList.append(myUserRole)
                    }
                    WebSocketManager.sharedInstance().sendMessage(
                        IMConvTransferMessage(
                            convKey: oldConv.convKey,
                            queue: pickedMerchant.queueType,
                            senderMerchantId: myUserRole.merchantId,
                            merchantId: pickedMerchant.merchant.merchantId,
                            myUserRole: myUserRole
                        ),
                        completion: { [weak self] ack in
                            if let strongSelf = self, let newConvKey = ack.data, let switchCell = strongSelf.switchCell {
                                
                                let newConv = Conv(convKey: newConvKey, userRole: strongSelf.conv?.myUserRole)
                                var promiseList = [strongSelf.forwardComment(newConvKey), strongSelf.forwardProduct(newConvKey)] + strongSelf.forwardImages(newConv)
                                
                                promiseList.append(strongSelf.transferRedirectSystemMessage(newConv.convKey))
                                promiseList.append(strongSelf.transferCommentSystemMessage(oldConv))

                                if switchCell.swt.isOn {
                                    promiseList.append(strongSelf.addMySelf(newConvKey))
                                }

                                when(fulfilled: promiseList).then { _ -> Void in
                                    strongSelf.stopLoading()
                                    
                                    strongSelf.dismiss(animated: false, completion: {
                                        strongSelf.finishedTransferChat?(switchCell.swt.isOn, newConvKey)
                                    })
                                }
                            }
                        }, failure: { [weak self] in
                            Log.debug("transfer fail")
                            if let strongSelf = self {
                                strongSelf.stopLoading()
                            }
                        }
                    )
                    
                }
                else {
                    Log.debug("error")
                    stopLoading()
                }
            } else {
                ErrorLogManager.sharedManager.recordNonFatalError(withException: .NullPointer)
            }
        }
        else {
            // Forward Chat
            if let conv = self.conv {
                let promiseList = [forwardComment(conv.convKey), forwardProduct(conv.convKey)] + forwardImages(conv)
                
                when(fulfilled: promiseList).then { _ in
                    self.sendForwardChat()
                }
            } else {
                ErrorLogManager.sharedManager.recordNonFatalError(withException: .NullPointer)
            }
        }
        
    }
    
    func forwardComment(_ convKey: String) -> Promise<Bool> {
        var message = ""
        if commentCell!.tvComment.textColor != UIColor.secondary3() {
            if let comment = commentCell?.tvComment.text {
                message = comment
            }
        }

        return Promise { fulfill, reject in
            if let merchantId = self.conv?.myMerchantObject()?.merchantId, let pickedMerchant = self.pickedMerchant, let conv = self.conv {
                WebSocketManager.sharedInstance().sendMessage(
                    IMForwardDescriptionMessage(
                        comment: message,
                        merchantId: merchantId,
                        convKey: convKey,
                        status: CommentStatus.Normal,
                        forwardedMerchantId: pickedMerchant.merchant.merchantId,
                        forwardedMerchantQueueName: pickedMerchant.queueType,
                        myUserRole: conv.myUserRole
                    ), completion: { _ in
                        fulfill(true)
                    }, failure: {
                        fulfill(false)
                    }
                )
            } else {
                fulfill(false)
            }
        }
    }
    
    func forwardProduct(_ convKey: String) -> Promise<Bool>  {
        return Promise { fulfill, reject in
            if let productModel = self.productModel {
                if let sku = productModel.sku, let conv = self.conv {
                    WebSocketManager.sharedInstance().sendMessage(
                        IMForwardProductMessage(
                            skuId: "\(sku.skuId)",
                            convKey: convKey,
                            myUserRole: conv.myUserRole
                        ), completion: { _ in
                            fulfill(true)
                        }, failure: {
                            fulfill(false)
                        }
                    )
                }
                else {
                    fulfill(false)
                }
            } else {
                fulfill(false)
            }
        }
    }
    
    func forwardImages(_ conv: Conv) -> [Promise<Bool>] {
        
        let uploadImageContainers = uploadPhotoCell!.getPhotos()
        
        var promiseList = [Promise<Bool>]()
        for uploadImageContainer in uploadImageContainers {
            
            let promise = Promise<Bool> { fulfill, reject in
                
                let storeKey = Utils.UUID()
                let originalImage = UIImage.fixImageOrientation(uploadImageContainer.imageView.image!)
                let thumbSize = ChatConfig.getSendImageSize(originalImage.size, inboundSize: Constants.ChatSendImageSetting.ImageBoundSize)
                
                guard let thumbNail = originalImage.resize(thumbSize) else {
                    fulfill(false)
                    return
                }
                
                ImageFilesManager.storeImage(
                    thumbNail,
                    key: storeKey,
                    completionHandler: {
                        
                        let sendImageModel = ChatImageModel(image: thumbNail) //we send the resized images only
                        let model = ChatModel(imageModel: sendImageModel, forwardMode: true)
                        model.localStoreName = storeKey
                        
                        if let localStoreName = model.localStoreName, let image = model.imageModel?.image {
                            model.convKey = conv.convKey
                            
                            let message = IMImageMessage(
                                localStoreName: localStoreName,
                                width: image.size.width,
                                height: image.size.height,
                                convKey: conv.convKey,
                                myUserRole: conv.myUserRole,
                                agentOnly: true
                            )
                            
                            message.dataType = MessageDataType.ForwardImage
                            
                            model.correlationKey = message.correlationKey
                            
                            WebSocketManager.sharedInstance().sendMessage(
                                message,
                                completion: { _ in
                                    fulfill(true)
                                }
                            )
                        } else {
                            fulfill(false)
                        }
                        
                    }
                )
                                
            }
            
            promiseList.append(promise)
            
        }
        
        return promiseList
    }
    
    func sendForwardChat() {
        if let conv = self.conv, let switchCell = self.switchCell, let pickedMerchant = self.pickedMerchant, let myMerchantId = self.conv?.myMerchantObject()?.merchantId {
            
            WebSocketManager.sharedInstance().sendMessage(
                IMConvForwardMessage(convKey: conv.convKey, convType: conv.convType, queue: pickedMerchant.queueType, merchantId: pickedMerchant.merchant.merchantId, senderMerchantId: myMerchantId, stayOn: switchCell.swt.isOn, myUserRole: conv.myUserRole),
                completion: { [weak self] ack in
                    if let strongSelf = self {
                        strongSelf.stopLoading()
                        
                        if !switchCell.swt.isOn {
                            WebSocketManager.sharedInstance().removeConv(conv)
                            CacheManager.sharedManager.deleteConv(conv.convKey)
                            strongSelf.showSuccessPopupWithText(String.localize("MSG_SUC_CS_FORWARD_CHAT"), delegate: strongSelf)
                        }
                        else {
                            strongSelf.dismiss(animated: false, completion: {
                                strongSelf.finishedForwardingChat?(true)
                            })
                        }
                    } else {
                        ErrorLogManager.sharedManager.recordNonFatalError(withException: .NullPointer)
                    }
                }, failure: { [weak self] in
                    if let strongSelf = self {
                        strongSelf.stopLoading()
                    }
                }
            )
        }
        else {
            stopLoading()
        }
    }
    
    func transferRedirectSystemMessage(_ newConvKey: String) -> Promise<Bool> {
        return Promise { fulfill, reject in
            if let oldConv = self.conv, let merchantId = self.conv?.myMerchantObject()?.merchantId, let switchCell = self.switchCell, let pickedMerchant = self.pickedMerchant {
                WebSocketManager.sharedInstance().sendMessage(
                    IMTransferRedirectMessage(
                        merchantId: merchantId,
                        stayOn: switchCell.swt.isOn,
                        convKey: oldConv.convKey,
                        transferConvKey: newConvKey,
                        forwardedMerchantId: pickedMerchant.merchant.merchantId,
                        myUserRole: oldConv.myUserRole
                    ), completion: { _ in
                        fulfill(true)
                    }, failure: {
                        fulfill(false)
                    }
                )
            } else {
                fulfill(false)
            }
        }
    }
    
    func transferCommentSystemMessage(_ oldConv: Conv) -> Promise<Bool> {
        return Promise { fulfill, reject in
            var message = ""
            if commentCell!.tvComment.textColor != UIColor.secondary3() {
                if let comment = commentCell?.tvComment.text {
                    message = comment
                }
            }
            
            if let merchantId = self.conv?.myMerchantObject()?.merchantId, let pickedMerchant = self.pickedMerchant {
                WebSocketManager.sharedInstance().sendMessage(
                    IMForwardDescriptionMessage(
                        comment: message,
                        merchantId: merchantId,
                        convKey: oldConv.convKey,
                        status: CommentStatus.Normal,
                        dataType: .TransferComment,
                        forwardedMerchantId: pickedMerchant.merchant.merchantId,
                        forwardedMerchantQueueName: pickedMerchant.queueType,
                        myUserRole: oldConv.myUserRole
                    ), completion: { _ in
                        fulfill(true)
                    }, failure: {
                        fulfill(false)
                    }
                )
            }
            else {
                fulfill(false)
            }
        }
    }
    
    func addMySelf(_ convKey: String) -> Promise<Bool> {
        return Promise { fulfill, reject in
            if let myUserRole = self.conv?.myUserRole {
                WebSocketManager.sharedInstance().sendMessage(
                    IMConvAddMessage(
                        convKey: convKey,
                        userList: [myUserRole],
                        myUserRole: myUserRole
                    ),
                    completion: { _ in
                        fulfill(true)
                    },
                    failure: {
                        fulfill(false)
                    }
                )
            }
            else {
                fulfill(false)
            }
        }
    }
    
    @objc func dismissKeyboard() {
        view.endEditing(true)
    }
    
    func addPhoto() {
        if imagePickerManager == nil {
            imagePickerManager = ImagePickerManager(viewController: self, withDelegate: self)
        }
        
        imagePickerManager!.presentDefaultActionSheet(preferredCameraDevice: .rear)
    }
    func getDataFromSearchProduct(_ style: Style) {
        let productModel = ProductModel()
        productModel.style = style
        productModel.sku = style.defaultSku()
        let chatModel = ChatModel(productModel: productModel)
        chatModel.messageContentType = MessageContentType.Product
        self.navigationController?.popViewController(animated: true)
        self.productModel = chatModel.productModel
        self.collectionView.reloadItems(at: [IndexPath(item: 3, section: 0)])
    }
    func attachProduct() {
        let productListViewController = ProductListViewController()
        productListViewController.isSearch = true
        productListViewController.getStyleDelegate = self
        productListViewController.merchantId = sourceMerchantId
        productListViewController.isEnableAutoCompleteSearch = false
        self.navigationController?.push(productListViewController, animated: true)
    }
    
    // MARK: - UICollectionView DataSource
    override func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return 5
    }
    
    func defaultCell(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        return collectionView.dequeueReusableCell(withReuseIdentifier: DefaultCellID, for: indexPath)
    }

    override func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        
        switch indexPath.row {
        case 0:
            let cell = collectionView.dequeueReusableCell(withReuseIdentifier: MerchantCellID, for: indexPath) as! ForwardChatMerchantCell
            
            if let pickedMerchant = self.pickedMerchant {

                let queueType = QueueStatistics.queueText(pickedMerchant.queueType)
                if queueType == "" {
                    if pickedMerchant.merchant.merchantId == Constants.MMMerchantId {
                        cell.nameLabel.text = QueueStatistics.queueText(QueueType.General)
                    } else {
                        cell.nameLabel.text = QueueStatistics.queueText(QueueType.Presales)
                        }
                } else  {
                    cell.nameLabel.text = queueType
                }
                
                cell.tagLabel.text = pickedMerchant.merchant.merchantName
                if pickedMerchant.merchant.merchantId != Constants.MMMerchantId { // not MM
                    cell.avatarImageView.mm_setImageWithURL(ImageURLFactory.URLSize128(pickedMerchant.merchant.headerLogoImage, category: .merchant), placeholderImage : UIImage(named: "spacer"), contentMode: .scaleAspectFit)
                } else {
                    cell.avatarImageView.image = Merchant().MMImageIconBlack
                }
                cell.displayContent(true)
            }
            else {
                cell.displayContent(false)
            }
            cell.layoutSubviews()

            return cell
            
        case 1:
            let cell = collectionView.dequeueReusableCell(withReuseIdentifier: SwitchCellID, for: indexPath) as! ForwardChatSwitchCell
            switchCell = cell
            
            if !isAllowToJoinNewChat() {
                cell.swt.isOn = false
                cell.isUserInteractionEnabled = false
            }
            else {
                cell.isUserInteractionEnabled = true
            }
            
            return cell
            
        case 2:
            let cell = collectionView.dequeueReusableCell(withReuseIdentifier: CommentCellID, for: indexPath) as! ForwardChatCommentCell
            commentCell = cell
            
            cell.textViewBeginEditting = { [weak self] in
                if let strongSelf = self {
                    if strongSelf.singleTap == nil {
                        strongSelf.singleTap = UITapGestureRecognizer(target: strongSelf, action: #selector(strongSelf.dismissKeyboard))
                    }
                    strongSelf.collectionView.addGestureRecognizer(strongSelf.singleTap!)
                }
            }
            
            cell.textViewEndEditting = { [weak self] in
                if let strongSelf = self {
                    strongSelf.collectionView.removeGestureRecognizer(strongSelf.singleTap!)
                }
            }
            
            return cell

        case 3:
            let cell = collectionView.dequeueReusableCell(withReuseIdentifier: AttachedProductCellID, for: indexPath) as! ForwardChatProductCell
            
            cell.productModel = self.productModel
            cell.buttonPickHandler = { [weak self] in
                if let strongSelf = self {
                    strongSelf.attachProduct()
                }
            }
            cell.buttonDeleteHandler = { [weak self] in
                if let strongSelf = self {
                    strongSelf.productModel = nil
                }
            }
            return cell

        case 4:
            let cell = collectionView.dequeueReusableCell(withReuseIdentifier: UploadPhotoCellID, for: indexPath) as! UploadPhotoCell
            cell.imageLimit = Constants.ImageLimit.ForwardChat
            cell.borderView.backgroundColor = UIColor.backgroundGray()
            cell.deleteButtonImageName = "btn_close_grey"
            cell.cameraButton.setImage(UIImage(named: "add_photo"), for: UIControlState())
            
            cell.cameraTappedHandler = { [weak self] in
                if let strongSelf = self {
                    strongSelf.addPhoto()
                }
            }
            
            self.uploadPhotoCell = cell

            return cell

        default:
            return defaultCell(collectionView, cellForItemAt: indexPath)
        }
    }
    
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, minimumInteritemSpacingForSectionAt section: Int) -> CGFloat {
        return 0.0
    }
    
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, minimumLineSpacingForSectionAt section: Int) -> CGFloat {
        return 0.0
    }
    
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, sizeForItemAt indexPath: IndexPath) -> CGSize {
        
        switch indexPath.row {
        case 0:
            return CGSize(width: self.view.frame.width, height: MerchantCellHeight)
            
        case 1:
            return CGSize(width: self.view.frame.width, height: SwitchCellHeight)

        case 2:
            return CGSize(width: self.view.frame.width, height: CommentCellHeight)
            
        case 3:
            return CGSize(width: self.view.frame.width, height: ProductCellHeight)
            
        case 4:
            return CGSize(width: self.view.frame.width, height: ImageCellHeight)
            
        default:
            return CGSize(width: self.view.frame.width, height: 0)
        }
    }
    
    func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        
        if indexPath.row != 0 {
            return
        }
        
        let contactListVC = ContactListViewController()
        contactListVC.isForwardChat = true
        contactListVC.conv = conv
        contactListVC.didPickMerchant = { [weak self] merchant, queueType in
            if let strongSelf = self {
                strongSelf.navigationController?.popViewController(animated: true)
                strongSelf.pickedMerchant = (merchant, queueType)
                
                let indexSet = [IndexPath(row: 0, section: 0), IndexPath(item: 1, section: 0)]
                strongSelf.collectionView.reloadItems(at: indexSet)
            }
        }
        self.navigationController?.push(contactListVC, animated: true)
    }
    
    //MARK: - ImagePickerManagerDelegate
    func didPickImage(_ image: UIImage!) {
        uploadPhotoCell?.addPhoto(image, imageKey: "", enableFullScreenViewer: true)
    }

    //MARK: - MBProgressHUD Delegate
    func hudWasHidden(_ hud: MBProgressHUD!) {
        dismiss(animated: false, completion: {
            self.finishedForwardingChat?(false)
        })
    }

    //MARK: - Config view
    override func collectionViewTopPadding() -> CGFloat {
        return self.navigationController!.navigationBar.frame.maxY - 20
    }
    
    func isTransferMessage() -> Bool {
        if let merchant = self.conv?.myMerchantObject(), let merchantQueue = self.pickedMerchant?.merchant {
            return merchant.merchantId != merchantQueue.merchantId
        }

        return false
    }

    func isAllowToJoinNewChat() -> Bool {
        if !isTransferMessage() {
            return true
        }

        if let conv = self.conv {
            return conv.IAmMM()
        }
        
        return true
    }
}
