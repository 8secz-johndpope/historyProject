
//
//  CuratorSettingViewController.swift
//  merchant-ios
//
//  Created by Vu Dinh Trung on 5/30/16.
//  Copyright © 2016 WWE & CO. All rights reserved.
//

import UIKit
import PromiseKit
import ObjectMapper

class DataSetting: NSObject {
    var text: String!
    init(text: String) {
        super.init()
        self.text = text
    }
}

class ImageDataResponse: NSObject {
    var profileImage : String!
    var coverImage : String!
    init (profileImage: String? = nil, cover: String? = nil) {
        super.init()

        self.profileImage = profileImage
        self.coverImage = cover
    }
}

class CuratorSettingViewController: MmViewController, CuratorSettingViewCellDelegate, UIImagePickerControllerDelegate, UINavigationControllerDelegate, ImageCropViewControllerDelegate {
    
    
    private let ItemCellHeight = CGFloat(46)
    var picker = UIImagePickerController()
    var datasource = [DataSetting]()
    var ratio = NSNumber(value: 0 as Int32)
    enum SectionType: Int {
        case coverSection
        case itemSection
    }
    
    
    enum UploadType: Int {
        case profile
        case cover
        case undefined
    }
    
    var uploadType = UploadType.undefined
    var imageData : ImageDataResponse!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        initUI()
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    //MARK - Init 
    func initUI() {
        self.title = String.localize("LB_CA_CURATOR_SETTING")
        createBackButton()
        setupCollectionView()
        getDataSource()
        reloadCollectionView()
        self.picker.delegate = self
    }
    
    func getDataSource() {
        datasource.append(DataSetting(text: String.localize("LB_CA_PROFILE_ABOUT")))
    }
    
    func reloadCollectionView() {
        self.collectionView.reloadData()
    }
    
    func setupCollectionView() {

        self.collectionView.register(CuratorSettingViewCell.self, forCellWithReuseIdentifier: CuratorSettingViewCell.CuratorSettingViewCellId)
        self.collectionView.register(CommonViewItemCell.self, forCellWithReuseIdentifier: CommonViewItemCell.CellIdentifier)
        self.collectionView.frame = CGRect(x: 0, y: StartYPos, width: view.bounds.width, height: view.bounds.height)
        self.collectionView.isScrollEnabled = false
    }
    
    func numberOfSections(in collectionView: UICollectionView) -> Int {
        return 2
    }
    
    override func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        if let section = SectionType(rawValue: indexPath.section) {
            
            switch section {
            case SectionType.coverSection:
                let cell = collectionView.dequeueReusableCell(withReuseIdentifier: CuratorSettingViewCell.CuratorSettingViewCellId, for: indexPath) as! CuratorSettingViewCell
                
                if imageData != nil {
                    cell.imageData = imageData
                }
                cell.curatorCellDelegate = self
                return cell
            case SectionType.itemSection:
                let cell = collectionView.dequeueReusableCell(withReuseIdentifier: CommonViewItemCell.CellIdentifier, for: indexPath) as! CommonViewItemCell
                cell.itemLabel.text = datasource[indexPath.row].text
                return cell
            }
            
        }
        return UICollectionViewCell()
    }
    
    func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        
        if let section = SectionType(rawValue: indexPath.section) {
            
            switch section {
            case SectionType.coverSection:
                break
            case SectionType.itemSection:
                
                let viewController = CuratorAboutViewController()
                self.navigationController?.push(viewController, animated: true)
                
                break
            }
            
        }
        
    }
    
    override func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        
        if let section = SectionType(rawValue: section) {
            switch section {
            case SectionType.coverSection:
                return 1
            default:
                return datasource.count
            }
        }
        return 0
        
    }
    
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, minimumInteritemSpacingForSectionAt section: Int) -> CGFloat {
        return 0.0
    }
    
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, minimumLineSpacingForSectionAt section: Int) -> CGFloat {
        return 0.0
    }
    
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, sizeForItemAt indexPath: IndexPath) -> CGSize {
        
        if let section = SectionType(rawValue: indexPath.section) {
            
            switch section {
            case SectionType.coverSection:
                return CGSize(width: view.bounds.width, height: CuratorSettingViewCell.getHeightCell())
            default:
                return CGSize(width: view.bounds.width, height: ItemCellHeight)
            }
        }
        return CGSize.zero
        
    }
    
    //MARK: - delegate curator cell
    
    func handleSelectedImageSquare(_ gesture: UITapGestureRecognizer) {
        uploadType = .profile
        self.showAlertOption()
    }
    
    func handleSelectedImageRect(_ gesture: UITapGestureRecognizer) {
        uploadType = .cover
        if let view = gesture.view {
            let ratio = view.frame.sizeHeight / view.frame.sizeWidth
            self.ratio = NSNumber(value: Float(ratio) as Float)
            self.showAlertOption()
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
    
    func openGallery() -> Void {
        picker.sourceType = UIImagePickerControllerSourceType.photoLibrary
        if UIDevice.current.userInterfaceIdiom == .phone {
            self.present(picker, animated: true, completion: nil)
        } else {
            Alert.alert(self, title: "Tablet not suported", message: "Tablet is not supported in this function")
        }
    }
    
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
    
    //MARK: - delegate gallery
    func imagePickerController(_ picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [String : Any]) {
        picker.dismiss(animated: true, completion: nil)
        
        if let image = (info[UIImagePickerControllerOriginalImage] as? UIImage)?.normalizedImage() {
            let imagecropVc = ImageCropViewController(image: image)
            imagecropVc?.delegate = self
            imagecropVc?.blurredBackground = true
            imagecropVc?.square = (self.uploadType == .profile ? true: false)
            imagecropVc?.horizontalRectangle = (self.uploadType == .profile ? false: true)
            
            if uploadType == .cover {
                imagecropVc?.ratio = self.ratio
                imagecropVc?.horizontalRectangle = true
                imagecropVc?.square = false
            }
            
            imagecropVc?.title = String.localize("LB_CA_EDIT_PICTURE")
            
            self.navigationController?.push(imagecropVc, animated: true)
        }
    }
    
    func imagePickerControllerDidCancel(_ picker: UIImagePickerController) {
        picker.dismiss(animated: true, completion: nil)
    }
    

    func imageCropViewControllerDidCancel(_ controller: UIViewController!) {
        
    }
    
    func imageCropViewControllerSuccess(_ controller: UIViewController!, didFinishCroppingImage croppedImage: UIImage!) {
        self.navigationController?.popViewController(animated: true)
        self.showLoading()
        
        switch uploadType {
        case .profile:
            uploadImage(ImageHelper.resizeImageLocal(croppedImage, maxWidth: ImageSizeCrop.width_max), imageType: .profileAlternateImage) { (image) in
                self.stopLoading()
                let data = ImageDataResponse(profileImage: image.entityId)
                self.imageData = data
                self.reloadCollectionView()
            }
            break
        case .cover:
            uploadImage(ImageHelper.resizeCoverImage(croppedImage), imageType: .coveraAternateImage) { (image) in
                self.stopLoading()
                let data = ImageDataResponse(cover: image.entityId)
                self.imageData = data
                self.reloadCollectionView()
            }
            break
        default:
            break
        }
        
    }
    
    
    func cropImage(_ cropImage: UIImage) -> UIImage {
        
        return UIImage()
    }
    
    //MARK: - call api
    
    func uploadImage(_ image: UIImage, imageType: ImageType, complete: ((_ image: ImageUploadResponse)->())? = nil) {
        if image.size.width > 0 {
            UserService.uploadImage(image, imageType: imageType, success: { [weak self] (response) in
                if response.result.isSuccess {
                    if response.response?.statusCode == 200 {
                        
                        if let imageUploadResponse = Mapper<ImageUploadResponse>().map(JSONObject: response.result.value) {
                            if let callback = complete {
                                callback(imageUploadResponse)
                            }
                        }
                    }
                }
                
                if let strongSelf = self {
                    strongSelf.stopLoading()
                }
                
                }, fail: { [weak self] encodingError in
                    if let strongSelf = self {
                        strongSelf.stopLoading()
                        strongSelf.showSuccessPopupWithText(String.localize("error"))
                    }
                })
        }
    }
    
}
