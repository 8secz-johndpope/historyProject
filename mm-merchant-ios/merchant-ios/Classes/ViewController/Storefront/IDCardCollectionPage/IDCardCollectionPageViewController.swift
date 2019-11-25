//
//  IDCardCollectionPageViewController.swift
//  merchant-ios
//
//  Created by HungPM on 2/22/16.
//  Copyright © 2016 WWE & CO. All rights reserved.
//

import Foundation
import AVFoundation
import Photos

enum UpdateCardAction: Int {
    case setting = 0
    case swipeToPay = 1
    case none
}

class IDCardCollectionPageViewController : MmViewController, UITextFieldDelegate, ImagePickerManagerDelegate {
    
    enum IndexPathRow: Int {
        case InfoHeader = 0
//        case FirstCardImage
//        case SecondCardImage
        case Lastname
        case Firstname
        case IdCardNumber
//        case IdTickbox
        case Count
    }
    var order : ParentOrder?

    private final let LENGTH_ID_NUMBER = 18
    private final let IDLabelCellID = "IDLabelCellID"
    private final let IDCardImageCellID = "IDCardImageCellID"
    private final let IDNameCellID = "IDNameCellID"
    private final let IDCardNumberCellID = "IDCardNumberCellID"
//    private final let IDTickCellID = "IDTickCellID"
    private final let DefaultCellID = "DefaultCellID"
    
    private var buttonOK: UIButton!
    private var activeTextField: UITextField!
    
    private var idCardImageFront: UIImageView!
    private var idCardImageBack: UIImageView!
    private var isFrontImagePicked = false
    private var isBackImagePicked = false
    
    private var isFrontImageChose = true
    
    private let imagePicker = UIImagePickerController()

    private var tfFirstName: UITextField!
    private var tfLastName: UITextField!
    private var tfIDNumber: UITextField!
    private var currentID = ""

    private var updateCardAction: UpdateCardAction = .setting
    var paymentMethod: Constants.PaymentMethod = .alipay
    
    private var imagePickerManager: ImagePickerManager?
    var identification: Identification?
    var callBackAction: (() -> Void)?
    
    convenience init(updateCardAction: UpdateCardAction) {
        self.init(nibName: nil, bundle: nil)
        self.updateCardAction = updateCardAction
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        self.navigationController!.isNavigationBarHidden = false
        self.title = String.localize("LB_CA_ID_CARD_VER")
        
        setupNavigationBar()
        setupDismissKeyboardGesture()
        
        self.collectionView!.register(UICollectionViewCell.self, forCellWithReuseIdentifier: self.DefaultCellID)
        
        self.collectionView!.register(IDLabelCell.self, forCellWithReuseIdentifier: self.IDLabelCellID)
        self.collectionView!.register(IDCardImageCell.self, forCellWithReuseIdentifier: self.IDCardImageCellID)
        self.collectionView!.register(IDNameCell.self, forCellWithReuseIdentifier: self.IDNameCellID)
        self.collectionView!.register(IDCardNumberCell.self, forCellWithReuseIdentifier: self.IDCardNumberCellID)
//        self.collectionView!.register(IDTickCell.self, forCellWithReuseIdentifier: self.IDTickCellID)
        
        IDCardService.getIdentification(Context.getUserKey(), success: { [weak self] (value) in
            if let strongSelf = self {
                strongSelf.identification = value
                strongSelf.currentID = value.identificationNumber
                strongSelf.collectionView!.reloadData()

                strongSelf.setEnableRightButton(false) //never been enable before edit
            }
        })
	}
    
    func setEnableRightButton(_ isEnable: Bool) {
        if isEnable {
            self.navigationItem.rightBarButtonItem?.isEnabled = true
        } else {
            self.navigationItem.rightBarButtonItem?.isEnabled = false
        }
    }
    
    func addTargetTextField(_ textField: UITextField) {
        
        textField.addTarget(self, action: #selector(IDCardCollectionPageViewController.textFieldDidChange), for: UIControlEvents.editingChanged)
    }

    func setupNavigationBar() {
        self.createBackButton()
        createRightButton(String.localize("LB_CA_CONFIRM"), action: #selector(okButtonTapped))
    }
    
    // MARK: Actions
    
    
    func styleErrorValidate(_ textField: UITextField, message: String) {
        self.showError(message, animated: true)
        textField.shouldHighlight(true)
        textField.becomeFirstResponder()
    }
    
    @objc func okButtonTapped() {
        Log.debug("okButtonTapped")
        
        // Vailidate info
//        guard isFrontImagePicked else {
//            self.showError(String.localize("MSG_ERR_CA_IDINFO_FRONT_IMG_NIL"), animated: true)
//            
//            return
//        }
//        
//        guard isBackImagePicked else {
//            self.showError(String.localize("MSG_ERR_CA_IDINFO_BACK_IMG_NIL"), animated: true)
//            return
//        }
        
        if let lastName = tfLastName.text, let firstName = tfFirstName.text {
            if !lastName.isPureChinese {
                styleErrorValidate(tfLastName, message: String.localize("LB_CA_XBORDER_PRC_ID_NAME_CHECK"))
                return
            } else if !firstName.isPureChinese || firstName.isLadyOrSir {
                styleErrorValidate(tfFirstName, message: String.localize("LB_CA_XBORDER_PRC_ID_NAME_CHECK"))
                return
            }
        }
        
        guard (tfLastName.text != nil && !tfLastName.text!.isEmptyOrNil()) else {
            styleErrorValidate(tfLastName, message: String.localize("MSG_ERR_CA_IDINFO_LAST_NAME_NIL"))
            return
        }
        
        tfLastName.shouldHighlight(false)
        
        guard (tfFirstName.text != nil && !tfFirstName.text!.isEmptyOrNil()) else {
            styleErrorValidate(tfFirstName, message: String.localize("MSG_ERR_CA_IDINFO_FIRST_NAME_NIL"))
            return
        }
        tfFirstName.shouldHighlight(false)
        
        guard !currentID.isEmptyOrNil() else {
//            self.showError(String.localize("MSG_ERR_CA_IDINFO_IDNUM_NIL"), animated: true)
            styleErrorValidate(tfIDNumber, message: String.localize("MSG_ERR_CA_IDINFO_IDNUM_NIL"))
            return
        }
        tfIDNumber.shouldHighlight(false)
        
        if let length = tfIDNumber.text?.length, length > 6 {
            tfIDNumber.text = maskedString(tfIDNumber.text!)
        }

//        let imageFrontData = UIImageJPEGRepresentation(idCardImageFront.image!, Constants.CompressionRatio.JPG_COMPRESSION)
//        let imageBackData = UIImageJPEGRepresentation(idCardImageBack.image!, Constants.CompressionRatio.JPG_COMPRESSION)
        
//        if let imgFrontData = imageFrontData, imgBackData = imageBackData {
        
            self.showLoading()
        
        
            //MM-31882: ID card info API now USE FIRST NAME AS FULL NAME, so last name should be empty
            IDCardService.uploadIDCardInfo("", firstName: self.tfFirstName.text!, lastName: self.tfLastName.text!, idNumber: currentID, success: { [weak self] (response) in
                if let strongSelf = self {
                    strongSelf.stopLoading()

                    if response.result.isSuccess && response.response?.statusCode == 200 {
                        switch strongSelf.updateCardAction {
                        case .setting:
                            strongSelf.navigationController?.popViewController(animated:true)
                            
                        case .none:
                            let viewController = PaymentMethodSelectionViewController()
                            viewController.order = strongSelf.order
                            strongSelf.navigationController?.pushViewController(viewController, animated: true)
                            
                        case .swipeToPay:
                            strongSelf.navigationController?.popViewController(animated:true)
                        }
                        if let callback = strongSelf.callBackAction  {
                            callback()
                        }
                        strongSelf.showSuccessPopupWithText(String.localize("MSG_CA_MY_ACCT_CHANGE_IDENTIFICATION_INFO_SUC"))
                        return
                    }
                    
                    strongSelf.tfIDNumber.text = strongSelf.currentID
                    strongSelf.handleError(response, animated: true, reject: nil)
                }
            }, fail: { [weak self] encodingError in
                Log.debug("encodingError")
                if let strongSelf = self {
                    strongSelf.stopLoading()
                    strongSelf.tfIDNumber.text = strongSelf.currentID
                }
            })
//        }
    }
    
    func toggleCheckbox(sender : UIButton) {
        Log.debug("toggleCheckbox")
        sender.isSelected = !sender.isSelected
    }
    
    func linkTapped() {
        Log.debug("Link tapped")
    }
    
    func viewDidTap() {
        self.view.endEditing(true)
    }
    
    func submitOrder() {
        Log.debug("submit button Tapped")
    }
    
    // MARK: CollectionView
    
    func numberOfSections(in collectionView: UICollectionView) -> Int {
        switch collectionView {
        case self.collectionView!:
            return 1
        default:
            return 0
        }
    }
    
    override func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        switch collectionView {
        case self.collectionView!:
            return IndexPathRow.Count.rawValue
        default:
            return 0
        }
    }
    
    override func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        switch collectionView {
            
        case self.collectionView!:
            var reuseIdentifier: String!
            
            if let indexPathRow = IndexPathRow(rawValue: indexPath.row) {
                switch indexPathRow {
                case .InfoHeader:
                    reuseIdentifier = self.IDLabelCellID
//                case .FirstCardImage, .SecondCardImage:
//                    reuseIdentifier = self.IDCardImageCellID
                case .Firstname, .Lastname:
                    reuseIdentifier = self.IDNameCellID
                case .IdCardNumber:
                    reuseIdentifier = self.IDNameCellID
//            case .IdTickbox:
//                reuseIdentifier = self.IDTickCellID
                default:
                    reuseIdentifier = ""
                }
                
                let cell = collectionView.dequeueReusableCell(withReuseIdentifier: reuseIdentifier, for: indexPath)
                
                switch indexPathRow {
//                case .FirstCardImage, .SecondCardImage:
//                    let cellItem = cell as! IDCardImageCell
//                    
//                    cellItem.imageHandler = {
//                        self.viewDidTap()
//                        
//                        if indexPath.row == IndexPathRow.FirstCardImage.rawValue {
//                            self.isFrontImageChose = true
//                        } else {
//                            self.isFrontImageChose = false
//                        }
//                        
//                        if self.imagePickerManager == nil {
//                            self.imagePickerManager = ImagePickerManager(viewController: self, withDelegate: self)
//                            self.imagePickerManager?.requiredSquareImage = false
//                        }
//                        
//                        self.imagePickerManager!.presentDefaultActionSheet(preferredCameraDevice: .Rear)
//                    }
//                    
//                    if indexPathRow == .FirstCardImage {
//                        idCardImageFront = cellItem.imageView
//                        idCardImageFront.image = UIImage(named: "idcard_holder")
//                    } else {
//                        idCardImageBack = cellItem.imageView
//                        idCardImageBack.image = UIImage(named: "idcard_back")
//                    }
                    
//                    cellItem.label.text = String.localize("LB_EDIT") // comment remove edit label in ticket MM-20755
                case .Lastname:
                    let cellItem = cell as! IDNameCell
                    cellItem.textField.delegate = self
                    cellItem.textField.text = self.identification?.lastName
                    cellItem.textField.placeholder = String.localize("LB_CA_LASTNAME")
                    tfLastName = cellItem.textField
                    addTargetTextField(tfLastName)
                    
                case .Firstname:
                    let cellItem = cell as! IDNameCell
                    cellItem.textField.delegate = self
                    cellItem.textField.text = self.identification?.firstName
                    cellItem.textField.placeholder = String.localize("LB_CA_FIRSTNAME")
                    tfFirstName = cellItem.textField
                    addTargetTextField(tfFirstName)
                    
                case .IdCardNumber:
                    let cellItem = cell as! IDNameCell
                    cellItem.textField.delegate = self
                    cellItem.textField.text = self.identification?.identificationNumber
                    if let length = cellItem.textField.text?.length, length > 6 {
                        cellItem.textField.text = maskedString(cellItem.textField.text!)
                    }
                    cellItem.textField.placeholder = String.localize("LB_ID_NO")
                    tfIDNumber = cellItem.textField
                    addTargetTextField(tfIDNumber)
                    
                    
//                case .IdTickbox:
//                    let cellItem = cell as! IDTickCell
//                    cellItem.checkboxButton.addTarget(self, action: "toggleCheckbox:", for: .touchUpInside)
//                    cellItem.linkButton.addTarget(self, action: "linkTapped", for: .touchUpInside)
                default:
                    break
                }
                
                return cell
            }
        default:
            break
        }
        
        return self.defaultCell(collectionView, cellForItemAt: indexPath)
    }
    
    func defaultCell(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        return collectionView.dequeueReusableCell(withReuseIdentifier: DefaultCellID, for: indexPath)
    }
    
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, minimumInteritemSpacingForSectionAt section: Int) -> CGFloat {
        return 0.0
    }
    
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, minimumLineSpacingForSectionAt section: Int) -> CGFloat {
        return 0.0
    }
    
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, sizeForItemAt indexPath: IndexPath) -> CGSize {
        
        switch collectionView {
        case self.collectionView!:
            
            var height : CGFloat = IDNameCell.DefaultHeight
            var width = self.view.frame.size.width
            switch indexPath.row {
                
            case IndexPathRow.InfoHeader.rawValue:
                height = IDLabelViewHeight
            case IndexPathRow.Firstname.rawValue:
                width = self.view.frame.size.width*(2/3)
            case IndexPathRow.Lastname.rawValue:
                width = self.view.frame.size.width*(1/3)
//            case IndexPathRow.IdCardNumber.rawValue:
//                height = IDNameCell.DefaultHeight
                
            default:
                height = IDNameCell.DefaultHeight
                
            }
            
            return CGSize(width: width, height: height)
        default:
            return CGSize.zero
        }
    }
    
    // MARK: - ImagePickerManagerDelegate
    
    let IDCardImageBoundSize = CGSize(width: 500, height: 500)
    
    func didPickImage(_ image: UIImage!) {
        let normlizedImage = { (originalImage: UIImage) -> UIImage in
            let image = originalImage.normalizedImage()
            let size = ChatConfig.getSendImageSize(image.size, inboundSize: self.IDCardImageBoundSize)

            guard let resizedImage = image.resize(size) else {
                return image
            }

            return resizedImage
        }
        
        if isFrontImageChose {
            idCardImageFront.image = normlizedImage(image)
            isFrontImagePicked = true
        } else {
            idCardImageBack.image = normlizedImage(image)
            isBackImagePicked = true
        }
    }
    
    // MARK: View Config
    // MARK: UITextField Delegate
    
    func textFieldShouldBeginEditing(_ textField: UITextField) -> Bool {
        activeTextField = textField
        
        if textField == tfIDNumber, let text = tfIDNumber.text, text.contain("*") {
            currentID = ""
            tfIDNumber.text = ""
        }
        
        return true
    }
    
    
    func textFieldShouldReturn(_ textField: UITextField) -> Bool {
        textField.resignFirstResponder()
        return true
    }
    
    @objc func textFieldDidChange(textField: UITextField) {
        
        textField.setStyleDefault()
        
        if textField == tfIDNumber {
            currentID = textField.text ?? ""
            
            if currentID.length == LENGTH_ID_NUMBER {
                self.setEnableRightButton(true)
            } else {
                self.setEnableRightButton(false)
            }
        }
    }
    
    func textField(_ textField: UITextField, shouldChangeCharactersIn range: NSRange, replacementString string: String) -> Bool {

        if (textField == tfFirstName || textField == tfLastName), let text = tfIDNumber.text, text.contain("*") {
            currentID = ""
            tfIDNumber.text = ""
        }
        
        return true
    }
    
    
    
    func maskedString(_ text: String) -> String {
        // mask 7-16
        if text.count == 18 {
            let range = text.index(text.startIndex, offsetBy: 6)...text.index(text.startIndex, offsetBy: 15)
            return text.replacingCharacters(in: range, with: String.init(repeating: "*", count: 10))
        }
        // if not 18 characters then mean not a valid id number so just return itself
        return text
    }
    
    // MARK: Keyboard
    
    override func keyboardWillShowNotification(_ notification: NSNotification) {
        super.keyboardWillShowNotification(notification)
        
        if let info = notification.userInfo, let kbObj = info[UIKeyboardFrameEndUserInfoKey] as? NSValue {
            let buttonViewHeight = (bottomButtonContainer != nil) ? bottomButtonContainer!.frame.size.height : 0
            
            var kbRect = kbObj.cgRectValue
            kbRect = self.view.convert(kbRect, from: nil)
            let contentInsets = UIEdgeInsets(top: 0.0, left: 0.0, bottom: kbRect.size.height - buttonViewHeight, right: 0.0)
            
            self.collectionView.contentInset = contentInsets
            self.collectionView.scrollIndicatorInsets = contentInsets;
            
            var aRect = self.view.frame
            aRect.size.height -= kbRect.size.height - buttonViewHeight
            
            if let activeTextField = self.activeTextField, !aRect.contains(activeTextField.frame.origin) {
                self.collectionView.scrollRectToVisible(activeTextField.frame, animated:true);
            }
        }
    }
    
    override func keyboardWillHideNotification(_ notification: NSNotification) {
        super.keyboardWillHideNotification(notification)
        
        self.collectionView.contentInset = UIEdgeInsets.zero
        self.collectionView.scrollIndicatorInsets = UIEdgeInsets.zero
    }
    
    
}
