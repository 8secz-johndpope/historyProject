//
//  CuratorAboutViewController.swift
//  merchant-ios
//
//  Created by khanh.nguyen on 6/1/16.
//  Copyright © 2016 WWE & CO. All rights reserved.
//

import UIKit
import PromiseKit
import ObjectMapper
import Kingfisher

class DataImageCurator: NSObject {
    var image = UIImage()
    var isFromServer = false
    var userImageKey = ""
    var willBeDeleted = false
   
    override init() {
        super.init()
    }
    
    init(image: UIImage, isFromServer: Bool, userImageKey: String? = nil) {
        super.init()
        self.image = image
        self.isFromServer = isFromServer
        if let key = userImageKey {
            self.userImageKey = key
        }
        
    }
    
}

class CuratorAboutViewController: MmViewController, UITextViewDelegate, UIImagePickerControllerDelegate, UINavigationControllerDelegate, GalleryViewControllerDelegate, ImageCropViewControllerDelegate, CuratorImageViewCellDelegate {
    
    private let topViewHeight = CGFloat(30)
    private let textViewHeight = CGFloat(150)
    private let limitationLabelWidth = CGFloat(80)
    private let ImageSize = CGSize(width: 110, height: 110)
    var textView = MMPlaceholderTextView()
    private var limitationLabel = UILabel()
    
    private var scrollView = UIScrollView()
    
    var datasource = [DataImageCurator]()
    var imagesWillBeDeleted = [DataImageCurator]()
    
    var picker = UIImagePickerController()
    private var numberImage : Int = 0
    private var itemPerRow = Int(3)
    enum Section: Int {
        case barLimitView = 0
        case imageCuratorView
        case third
    }
    
    var user : User!
    var curatorImages = [CuratorImage]()
    let unit = CGFloat(1024)
    
    var userId : Int = Context.getUserId()
    
    override func viewDidLoad() {
        super.viewDidLoad()
    
        self.createRightButton(String.localize("LB_CA_SAVE"), action: #selector(CuratorAboutViewController.didSelectRightButton))
        self.createBackButton(MmViewController.ButtonStyle.cancelTitle)
        
        self.title = String.localize("LB_CA_EDIT")
        
        initUI()
        configCollectionView()
        
        self.setupDismissKeyboardGesture()
        
        self.updateUserView()
        
        fetchImages {
            self.getImageFromUrl({ (image, userImageKey) in
                
                self.datasource.append(DataImageCurator(image: image, isFromServer: true, userImageKey: userImageKey))
                self.reloadCollectionView()
                self.updateLayout()
            })
        }
        
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        
        NotificationCenter.default.addObserver(self, selector: #selector(CuratorAboutViewController.keyboardWillShow), name: NSNotification.Name.UIKeyboardWillShow, object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(CuratorAboutViewController.keyboardWillHide), name: NSNotification.Name.UIKeyboardWillHide, object: nil)
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        
        NotificationCenter.default.removeObserver(self, name: NSNotification.Name.UIKeyboardWillShow, object: nil)
        NotificationCenter.default.removeObserver(self, name: NSNotification.Name.UIKeyboardWillHide, object: nil)
        
        self.view.endEditing(true)
    }
    
    @objc func keyboardWillHide(_ sender: NSNotification) {
        super.keyboardWillHideNotification(sender)
        
        var frame = self.scrollView.frame
        frame.size.height = self.view.frame.size.height - frame.origin.y
        
        UIView.animate(withDuration: 0.25, delay: 0.0, options: .curveEaseOut, animations: {
            self.scrollView.frame = frame;
            }, completion: { finished in
                Log.debug("keyboard hidded!")
        })
    }
    
    @objc func keyboardWillShow(_ sender: NSNotification) {
        super.keyboardWillShowNotification(sender)
        
        if let info = sender.userInfo, let kbObj = info[UIKeyboardFrameEndUserInfoKey] {
            var kbRect = (kbObj as! NSValue).cgRectValue
            kbRect = self.view.convert(kbRect, from: nil)
            var frame = self.scrollView.frame
            frame.size.height = self.view.frame.size.height - (frame.origin.y + kbRect.height)
            UIView.animate(withDuration: 0.25, delay: 0.0, options: .curveEaseOut, animations: {
                self.scrollView.frame = frame;
                }, completion: { finished in
                    Log.debug("keyboard shown!")
            })
        }
    }

    func initUI() -> Void {
        
        self.scrollView.frame = CGRect(x: 0, y: StartYPos, width: self.view.width, height: self.view.height - 64)
        self.view.addSubview(self.scrollView)
        
        let topView = UIView(frame: CGRect(x: 0, y: 0, width: self.view.frame.sizeWidth, height: topViewHeight))
        topView.backgroundColor = UIColor.secondary5()
        
        let descriptionLabel = UILabel(frame: CGRect(x: Margin.left, y: 0, width: self.view.frame.sizeWidth - limitationLabelWidth - Margin.right - Margin.left, height: topViewHeight))
        descriptionLabel.textColor = UIColor.secondary2()
        descriptionLabel.applyFontSize(15, isBold: true)
        descriptionLabel.text = String.localize("LB_CA_PROFILE_ABOUT")
        
        
        limitationLabel = UILabel(frame: CGRect(x: self.view.frame.sizeWidth - limitationLabelWidth - Margin.right , y: 0, width: limitationLabelWidth, height: topViewHeight))
        limitationLabel.textColor = UIColor.secondary2()
        limitationLabel.formatSize(12)
        limitationLabel.textAlignment = .right
        limitationLabel.text = String(format : "%d/%d",0, Constants.LimitNumber.LimitCharactor)
        
        topView.addSubview(descriptionLabel)
        topView.addSubview(limitationLabel)
        
        self.scrollView.addSubview(topView)
        
        textView.frame = CGRect(x: Margin.left, y: topView.frame.maxY + Margin.top, width: self.view.frame.sizeWidth - Margin.right - Margin.left, height: textViewHeight)
        if let font = UIFont(name: Constants.Font.Normal, size: CGFloat(14)) {
            textView.font = font
        } else {
            textView.font = UIFont.systemFont(ofSize: 14)
        }
        textView.textColor = UIColor.secondary2()
        textView.delegate = self
        textView.placeholder = String.localize("LB_CA_CURATOR_PROF_DESC_NIL")
        textView.placeholderColor = UIColor.secondary3()
        self.scrollView.addSubview(textView)
        
        self.picker.delegate = self
    }
    
    func configCollectionView() -> Void {
        
        self.collectionView.frame = CGRect(x: 0, y: self.textView.frame.maxY + Margin.top , width: self.view.width, height: self.view.height - self.textView.frame.maxY - Margin.top * 3)
        self.collectionView.alwaysBounceVertical = true
        self.collectionView.register(CuratorBarViewCell.self, forCellWithReuseIdentifier: CuratorBarViewCell.CellId)
        self.collectionView.register(CuratorImageViewCell.self, forCellWithReuseIdentifier: CuratorImageViewCell.cellId)
        self.collectionView.register(AddPhotoCell.self, forCellWithReuseIdentifier: AddPhotoCell.CellIdentifier)
        self.collectionView.backgroundColor = UIColor.white
        self.collectionView.isScrollEnabled = false
        self.scrollView.addSubview(self.collectionView)
        self.scrollView.contentSize = CGSize(width: self.scrollView.frame.size.width, height: self.collectionView.frame.maxY - CuratorBarViewCell.heightCell)
    }
    
    func textViewDidChange(_ textView: UITextView) {
        
        updateLimitCharactor(textView.text)
    }
    
    func updateLimitCharactor(_ string: String) {
        limitationLabel.text = String(format : "%d/%d",string.length, Constants.LimitNumber.LimitCharactor)
    }
    
    func textView(_ textView: UITextView, shouldChangeTextIn range: NSRange, replacementText text: String) -> Bool {
        let maxLength = Constants.LimitNumber.LimitCharactor
        let currentString: NSString = textView.text! as NSString
        let newString: NSString = currentString.replacingCharacters(in: range, with: text) as NSString
        return  newString.length <= maxLength
    }
    
    @objc func didSelectRightButton(_ sender: UIBarButtonItem) {
        
        updateUserInfo()
        
    }
    
    func removeImages(_ array : [DataImageCurator]) {
        if self.checkArray(array) {
            for item in array {
                if item.willBeDeleted == true {
                    self.showLoading()
                    firstly{
                        return self.deleteImageFromServer(item.userImageKey)
                        }.then { _ -> Void in
                            
                        }.always{
                            item.willBeDeleted = false
                            if self.checkArray(array) {
                                self.removeImages(array)
                            }else {
                                if self.numberImage <= 0 {
                                    self.stopLoading()
                                    self.handleSubmitEdit()
                                }
                            }

                        }.catch { (errorType) -> Void in
                            
                    }
                    break
                }
            }

        }
    }
    
    func checkArray(_ array : [DataImageCurator]) -> Bool {
        for item in array {
            if item.willBeDeleted == true {
                return true
            }
        }
        return false
    }
    
    func canAddMorePhoto() -> Bool {
        return datasource.count < Constants.LimitNumber.ImagesNumber
    }
    
    //MARK: - delegate & datasource
    
    func numberOfSections(in collectionView: UICollectionView) -> Int {
        return 2
    }
    
    override func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        
        if let section = Section(rawValue: indexPath.section) {
            switch section {
            case Section.barLimitView:
                
                let cell = collectionView.dequeueReusableCell(withReuseIdentifier: CuratorBarViewCell.CellId, for: indexPath) as! CuratorBarViewCell
                cell.maxImageLabel.text = String(format: "%d/%d", self.datasource.count, Constants.LimitNumber.ImagesNumber)
                
                return cell
                
            case Section.imageCuratorView:
                if self.canAddMorePhoto() && indexPath.row == datasource.count {
                    let cell = collectionView.dequeueReusableCell(withReuseIdentifier: AddPhotoCell.CellIdentifier, for: indexPath) as! AddPhotoCell
                    return cell
                }
                let cell = collectionView.dequeueReusableCell(withReuseIdentifier: CuratorImageViewCell.cellId, for: indexPath) as! CuratorImageViewCell
                cell.closeButton.tag = indexPath.row
                cell.delegate = self
                let data = datasource[indexPath.row]
                cell.imageView.image = data.image
                
                return cell
                
            default:
                return UICollectionViewCell()
            }
        }
        return UICollectionViewCell()
        
    }
    
    func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        if self.canAddMorePhoto() && indexPath.row == datasource.count {
            self.didTapCameraButton()
        }
    }
    
    override func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        
        if let section = Section(rawValue: section) {
            
            switch section {
            case Section.barLimitView:
                return 1
            case Section.imageCuratorView:
                return self.canAddMorePhoto() ? datasource.count + 1 : datasource.count
            default:
                return 1
            }
            
        }
        return 0
    }
    
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, minimumInteritemSpacingForSectionAt section: Int) -> CGFloat {
        return 0
    }
    
    
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, minimumLineSpacingForSectionAt section: Int) -> CGFloat {
        return 0
    }
    
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, insetForSectionAt section: Int) -> UIEdgeInsets {
        
        if let section = Section(rawValue: section) {
            switch section {
            case .barLimitView:
                return UIEdgeInsets.zero
            case .imageCuratorView:
                let rightMargin = self.view.bounds.sizeWidth - Margin.left/2 - 3 * self.ImageSize.width
                return UIEdgeInsets(top: Margin.left / 2, left: Margin.left / 2, bottom: 0, right: rightMargin)
            default:
                return UIEdgeInsets.zero
            }
        }
        return UIEdgeInsets.zero
    }
    
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, sizeForItemAt indexPath: IndexPath) -> CGSize {
        
        if let section = Section(rawValue: indexPath.section) {
        
            switch section {
            case Section.barLimitView:
                return CGSize(width: view.bounds.width, height: CuratorBarViewCell.heightCell)
                
            case Section.imageCuratorView:
                if self.canAddMorePhoto() && indexPath.row == datasource.count {
                    return self.ImageSize
                }else {
                    if self.datasource[indexPath.row].image.size.width > 0 {
                        return self.ImageSize
                    }
                }
                
                return CGSize(width: view.bounds.width, height: 0)
            default:
                return CGSize(width: view.bounds.width, height: 0)
            }
            
        }
        return CGSize.zero
    }
    
    
    //MARK: delegate bar cell
    
    func didTapCameraButton() {
        if datasource.count == Constants.LimitNumber.ImagesNumber {
            self.showErrorAlert(String.localize("MSG_ERR_CA_CURATOR_DESC_IMG_LIMIT"))
        } else {
            showAlertOption()
        }
        
    }
    
    // show option choose
    func showAlertOption() {
        let optionMenu = UIAlertController(title: nil, message: nil, preferredStyle: .actionSheet)
        let keyTake = String.localize("LB_CA_PROF_PIC_TAKE_PHOTO")
        let keyChoose = String.localize("LB_CA_PROF_PIC_CHOOSE_LIBRARY")
        let capture = UIAlertAction(title: String.localize(keyTake), style: .default, handler: {
            (alert: UIAlertAction!) -> Void in
            self.openCamera()
        })
        let library = UIAlertAction(title: String.localize(keyChoose), style: .default, handler: {
            (alert: UIAlertAction!) -> Void in
            self.openGallery()
        })
        
        let cancelAction = UIAlertAction(title: String.localize("LB_CANCEL"), style: .cancel, handler: {
            (alert: UIAlertAction!) -> Void in
        })

        optionMenu.addAction(capture)
        optionMenu.addAction(library)
        optionMenu.addAction(cancelAction)
        
        self.present(optionMenu, animated: true, completion: nil)
        optionMenu.view.tintColor = UIColor.alertTintColor()
    }
    
    //open camera
    func openCamera() {
        Utils.checkCameraPermissionWithCallBack({[weak self] (granted) in
            if let strongSelf = self, granted {
                if UIImagePickerController.isSourceTypeAvailable(UIImagePickerControllerSourceType.camera) {
                    strongSelf.picker.sourceType = UIImagePickerControllerSourceType.camera
                    strongSelf.picker.cameraDevice = UIImagePickerControllerCameraDevice.rear
                    
                    strongSelf.present(strongSelf.picker, animated: true, completion: nil)
                } else {
                    Alert.alert(strongSelf, title: "Camera not found", message: "Cannot access the front camera. Please use photo gallery instead.")
                }
            }
            
        })
        
        
    }
    
    // Delegate media
    func imagePickerController(_ picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [String : Any]) {
        picker.dismiss(animated: true, completion: nil)
        if let profileImage = (info[UIImagePickerControllerOriginalImage] as? UIImage)?.normalizedImage() {
//          var profileImage = (info[UIImagePickerControllerOriginalImage] as? UIImage)!
//          profileImage = profileImage.normalizedImage()
            //let finalImage = profileImage.scaleImage(self.view.width)
            datasource.append(DataImageCurator(image: profileImage, isFromServer: false))
            reloadCollectionView()
            updateLayout()
        }
    }
    
    // ratio by max Width
    func getHeightCell(_ image: UIImage) -> CGFloat {
        if image.size.width > 0 {
            let ratio = view.bounds.width / image.size.width
            return image.size.height * ratio
        }
        return 0
    }
    
    func openGallery() -> Void {
        picker.sourceType = UIImagePickerControllerSourceType.photoLibrary
        if UIDevice.current.userInterfaceIdiom == .phone {
            self.present(picker, animated: true, completion: nil)
        } else {
            Alert.alert(self, title: "Tablet not suported", message: "Tablet is not supported in this function")
        }
    }
    
    //MARK: - Delegate Gallery
    
    func imageCropViewControllerDidCancel(_ controller: UIViewController!) {
        
    }
    
    func imageCropViewControllerSuccess(_ controller: UIViewController!, didFinishCroppingImage croppedImage: UIImage!) {
        let finalImage = croppedImage.scaleImage(self.view.width)
        datasource.append(DataImageCurator(image: finalImage, isFromServer: false))
        reloadCollectionView()
        updateLayout()
    }
    
    func handleDismisGalleryViewController(_ stage: StageMode) {
        
    }
    
    
    //reload page
    
    func reloadCollectionView() {
        self.collectionView.reloadData()
    }
    
    func updateLayout() {
        
        var frame = self.collectionView.frame
        var  height = CuratorBarViewCell.heightCell
        
        let row = ceil(CGFloat(datasource.count + 1) / CGFloat(itemPerRow))
        height += row * self.ImageSize.height
        
        frame.size.height = height
        self.collectionView.frame = frame
        
        updateContentSizeScrollView()
        
    }
    
    func updateContentSizeScrollView() {
        var contentSize = scrollView.contentSize
        contentSize.height = textView.frame.maxY + self.collectionView.frame.height + Margin.bottom * 3
        scrollView.contentSize = contentSize
    }
    
    func handleRemovePicture(_ sender: UIButton) {
        Alert.alert(self, title: "", message: String.localize("LB_CA_REMOVE_IMG_CONF"), okActionComplete: { () -> Void in
            // remove on server
            let index = sender.tag
            let data = self.datasource[index]
            
            if data.isFromServer {
                data.willBeDeleted = true
                self.imagesWillBeDeleted.append(data)
            }
            self.datasource.remove(at: index)
            self.reloadCollectionView()
            self.updateLayout()
            }, cancelActionComplete:nil)
    }
    
    func deleteImage(_ index: Int) {
        let data = self.datasource[index]
        self.showLoading()
        firstly{
            return self.deleteImageFromServer(data.userImageKey)
            }.then { _ -> Void in
                self.datasource.remove(at: index)
                self.reloadCollectionView()
                self.updateLayout()
            }.always{
                self.stopLoading()
            }.catch { (errorType) -> Void in
                
        }
    }
    
    func renderUserView() {
        
        if let user = user {
            
            self.textView.text = user.userDescription
            updateLimitCharactor(user.userDescription)
           
            self.collectionView.reloadData()
        }
        
    }
    
    
    func getImageFromUrl(_ complete: ((_ image: UIImage, _ userImageKey: String)->())? = nil) {
        if !self.curatorImages.isEmpty {
            for idx in 0...self.curatorImages.count - 1 {
                let curatorImage = self.curatorImages[idx]
                var imageString = ""
                imageString = curatorImage.image
                
                guard imageString.length > 0, let urlString = URL(string: imageString) else {
                    return
                }
                
                KingfisherManager.shared.retrieveImage(with: urlString, options: nil, progressBlock: nil, completionHandler: { (image, error, cacheType, imageURL) -> () in
                    if let strongImage = image {
                        // call back
                        if let callback = complete {
                            callback(strongImage, curatorImage.userImageKey)
                        }
                        
                    } else {
                        if let strongImage = UIImage(named: "curator_cover_image_placeholder") {
                            if let callback = complete {
                                callback(strongImage, curatorImage.userImageKey)
                            }
                        }
                    }
                    
                })
            }
        }
    }

    
    //MARK: API
    
    // get info user
    
    func updateUserView() {
        self.showLoading()
        firstly {
            
            return self.fetchUser()
            }.then { _ -> Void in
                self.renderUserView()
            }.always {
                self.renderUserView()
                self.stopLoading()
            }.catch { _ -> Void in
                Log.error("error")
        }
    }
    
    
    
    func fetchUser() -> Promise<Any> {
        return Promise{ fulfill, reject in
            UserService.view() { [weak self] (response) in
                if let strongSelf = self {
                    if response.result.isSuccess {
                        if response.response?.statusCode == 200 {
                            strongSelf.user = Mapper<User>().map(JSONObject: response.result.value)!
                            Context.saveUserProfile(strongSelf.user)
                            fulfill("OK")
                        } else {
                            var statusCode = 0
                            if let code = response.response?.statusCode {
                                statusCode = code
                            }
                            
                            let error = NSError(domain: "", code: statusCode, userInfo: nil)
                            reject(error)
                        }
                    } else {
                        reject(response.result.error!)
                    }
                }
            }
        }
    }
    
   @discardableResult
   func fetchImages(_ complete: (() -> Void)? = nil) -> Promise<Any> {
        return Promise{ fulfill, reject in
            UserService.listImagesCuratorAbout() { [weak self] (response) in
                if let strongSelf = self {
                    if response.result.isSuccess {
                        if response.response?.statusCode == 200 {
                            
                            if let images: Array<CuratorImage> = Mapper<CuratorImage>().mapArray(JSONObject: response.result.value) {
                                strongSelf.curatorImages = images
                                if let callback = complete {
                                    callback()
                                }
                            }
                            fulfill("OK")
                            
                        } else {
                            var statusCode = 0
                            if let code = response.response?.statusCode {
                                statusCode = code
                            }
                            
                            let error = NSError(domain: "", code: statusCode, userInfo: nil)
                            reject(error)
                        }
                    } else {
                        reject(response.result.error!)
                    }
                }
            }
        }
    }
    
    func deleteImageFromServer(_ userImageKey: String) -> Promise<Any> {
        return Promise{ fulfill, reject in
            UserService.deleteImageCurator(userImageKey) { [weak self] (response) in
                if let _ = self {
                    if response.result.isSuccess {
                        if response.response?.statusCode == 200 {
                            fulfill("OK")
                            
                        } else {
                            var statusCode = 0
                            if let code = response.response?.statusCode {
                                statusCode = code
                            }
                            
                            let error = NSError(domain: "", code: statusCode, userInfo: nil)
                            reject(error)
                        }
                    } else {
                        reject(response.result.error!)
                    }
                }
            }
        }
    }

    func uploadDescription(_ description: String) -> Promise<Any>  {
        return Promise{ fulfill, reject in
            UserService.uploadUserDescription(description) { [weak self] (response) in
                if let _ = self {
                    if response.result.isSuccess {
                        if response.response?.statusCode == 200 {
                            fulfill("OK")
                            
                        } else {
                            var statusCode = 0
                            if let code = response.response?.statusCode {
                                statusCode = code
                            }
                            
                            let error = NSError(domain: "", code: statusCode, userInfo: nil)
                            reject(error)
                        }
                    } else {
                        reject(response.result.error!)
                    }
                }
            }
        }

    }
    
    func updateUserInfo() {
        self.showLoading()
        firstly {
            
            return self.uploadDescription(self.textView.text.trimmingCharacters(in: CharacterSet.whitespacesAndNewlines)) 
            }.then { _ -> Void in
                self.uploadImages()
            }.then { _ -> Void in
                self.removeImages(self.imagesWillBeDeleted)
            } .always {
//                self.handleSubmitEdit()
//                self.stopLoading()
            }.catch { _ -> Void in
                Log.error("error")
                self.stopLoading()
        }
    }

    func handleSubmitEdit() {
        self.showSuccessPopupWithText(String.localize("LB_EDIT_PAGE_SUCCEED"))
        self.navigationController?.popViewController(animated: true)
    }
    
    func uploadCuratorPhoto(_ image: UIImage, imageType: ImageType) {
        if image.size.width > 0 {
            UserService.uploadPhoto(Context.getUserKey(),image: image, success: { [weak self] (response) in
                    if let strongSelf = self {
                        if response.result.isSuccess {
                            if response.response?.statusCode == 200 {
                                
                            }
                        }
                        strongSelf.handleUploadImage()
                    }
                
                }, fail: { [weak self] encodingError in
                    if let strongSelf = self {
                        strongSelf.showSuccessPopupWithText(String.localize("error"))
                        strongSelf.handleUploadImage()
                    }
                })
        }
    }
    
    func handleUploadImage() {
        self.numberImage -= 1
        if self.numberImage == 0 && !self.checkArray(self.imagesWillBeDeleted) {
            self.stopLoading()
            self.handleSubmitEdit()
        }
    }
    
    func uploadImages() {
        if !self.checkSizeDataImage() {
            let errorMessage =  String.localize("MSG_ERR_CS_ATTACH_IMG").replacingOccurrences(of: "{CONST_BG_IMG_FILE_SIZE}", with: "\(Int(Constants.LimitNumber.LimitSizeImage))")
            self.showErrorAlert(errorMessage)
            if !self.checkArray(self.imagesWillBeDeleted) {
                self.stopLoading()
            }
        } else {
            self.numberImage = 0
            for data in self.datasource {
                if !data.isFromServer {
                    self.numberImage += 1
                    self.uploadCuratorPhoto(data.image, imageType: .curatorImage)
                }
            }
            if self.numberImage == 0 && !self.checkArray(self.imagesWillBeDeleted) {
                self.stopLoading()
                self.handleSubmitEdit()
            }
        }
        
    }
    
    //check size data image > 10MB
    func checkSizeDataImage() -> Bool {
        
        var totalSize = 0
        for data in self.datasource {
            if !data.isFromServer {
                if let dataByte = UIImageJPEGRepresentation(data.image, Constants.CompressionRatio.JPG_COMPRESSION) {
                    totalSize += dataByte.count
                }
            }
        }
        
        let mb = CGFloat(totalSize) / unit / unit
        if mb > Constants.LimitNumber.LimitSizeImage {
            return false
        }
        return true
    }
    
}
