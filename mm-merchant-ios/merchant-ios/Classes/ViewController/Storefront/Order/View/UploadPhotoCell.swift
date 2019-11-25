//
//  UploadPhotoCell.swift
//  merchant-ios
//
//  Created by Quang Truong Dinh on 4/1/16.
//  Copyright © 2016 WWE & CO. All rights reserved.
//

import Foundation

class UploadPhotoCell: UICollectionViewCell {
    
    static let CellIdentifier = "UploadPhotoCellID"
    
    private final let PhotoImageViewSize = CGSize(width: 90, height: 90)
    
    var imageLimit = 0 {
        didSet {
            maxPhotoLabel.text = "0/\(imageLimit)"
        }
    }
    
    private var currentNumberOfPhoto = 0
    
    var maxPhotoLabel = UILabel()
    var cameraButton = UIButton()
    var borderView = UIView()
    var isAllowEdit = true
    
    private var photoScrollView = UIScrollView()
    
    private var uploadImageContainers = [UploadImageContainer]()
    
    var cameraTappedHandler: (() -> Void)?
    var deletePhotoTappedHandler: ((_ image: UIImage, _ atIndex: Int) -> Void)?
    var deleteButtonImageName: String?
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        self.backgroundColor = UIColor.white
        self.clipsToBounds = true
        
        maxPhotoLabel.formatSize(12)
        maxPhotoLabel.text = "0/\(imageLimit)"
        maxPhotoLabel.textAlignment = .center
        addSubview(maxPhotoLabel)
        
        cameraButton.setImage(UIImage(named: "icon_order_camera"), for: UIControlState())
        cameraButton.addTarget(self, action: #selector(cameraButtonTouched), for: .touchUpInside)
        addSubview(cameraButton)
        
        addSubview(photoScrollView)
        
        borderView.backgroundColor = UIColor.secondary1()
        addSubview(borderView)
    }
    
    override func layoutSubviews() {
        super.layoutSubviews()
        
        let marginLeft: CGFloat = 10
        let photoScrollViewHeight: CGFloat = 75
        let cameraButtonSize = CGSize(width: 50, height: 50)
        
        var photoScrollViewWidth = bounds.width - (marginLeft * 3)
        
        if isAllowEdit == false {
            cameraButton.isHidden = true
            maxPhotoLabel.isHidden = true
        }
        
        if !cameraButton.isHidden {
            photoScrollViewWidth =  photoScrollViewWidth - cameraButtonSize.width
        }
        
        cameraButton.frame = CGRect(x: bounds.maxX - 60 , y: 10 , width: cameraButtonSize.width, height: cameraButtonSize.height)
        
        photoScrollView.frame = CGRect(x: 2 * marginLeft , y: 10, width: photoScrollViewWidth, height: photoScrollViewHeight)
        photoScrollView.contentSize = photoScrollView.bounds.size
        
        maxPhotoLabel.frame = CGRect(x: bounds.maxX - 60, y: 60, width: cameraButtonSize.width, height: 30)
        
        borderView.frame = CGRect(x: marginLeft, y: bounds.maxY - 1, width: bounds.width - 20, height: 1)
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    func showBorder(_ isShow: Bool) {
        borderView.isHidden = !isShow
    }
    
    func showCameraButton(_ isShow: Bool) {
        cameraButton.isHidden = !isShow
        
        layoutSubviews()
    }
    
    @objc func cameraButtonTouched(_ sender: UIButton!) {
        if let callback = self.cameraTappedHandler {
            callback()
        } else {
            ErrorLogManager.sharedManager.recordNonFatalError(withException: .NullPointer)
        }
    }
    
    func loadImages(_ imageKeys: [String]?, imageCategory: ImageCategory) {
        if imageKeys == nil || imageKeys?.count == 0 {
            return
        }
        
        if let imageKeys = imageKeys {
            for imageKey in imageKeys {
                let imageView = UIImageView()
                imageView.frame = CGRect(x: UploadImageContainer.PaddingImageContent, y: UploadImageContainer.PaddingImageContent, width: PhotoImageViewSize.width - 2 * UploadImageContainer.PaddingImageContent, height: PhotoImageViewSize.height - 2 * UploadImageContainer.PaddingImageContent)
                
                imageView.mm_setImageWithURL(ImageURLFactory.URLSize512(imageKey, category: imageCategory), placeholderImage: nil, contentMode: .scaleAspectFit, completion: { [weak self] (image, error, cacheType, imageURL) -> Void in
                    if let error = error {
                        ErrorLogManager.sharedManager.recordNonFatalError(error)
                    } else {
                        if let strongSelf = self {
                            strongSelf.addPhoto(image, imageKey: imageKey)
                        } else {
                            ErrorLogManager.sharedManager.recordNonFatalError(withException: .NullPointer)
                        }
                    }
                })
            }
        } else {
            ErrorLogManager.sharedManager.recordNonFatalError(withException: .NullPointer)
        }
    }
    
    func addPhoto(_ image: UIImage?, imageKey: String?, enableFullScreenViewer: Bool =  false) {
        if currentNumberOfPhoto == imageLimit {
            return
        }
        
        if let _ = image {
            let imageViewHorizontalPadding: CGFloat = 10
            let imageViewTopPadding: CGFloat = 0
            
            let uploadImageContainer = UploadImageContainer(frame: CGRect(x: CGFloat(currentNumberOfPhoto) * PhotoImageViewSize.width + CGFloat(currentNumberOfPhoto) * imageViewHorizontalPadding, y: imageViewTopPadding, width: PhotoImageViewSize.width, height: PhotoImageViewSize.height), image: image, imageKey: imageKey, tag: currentNumberOfPhoto, deleteImageName: deleteButtonImageName)
            uploadImageContainer.deleteButton.addTarget(self, action: #selector(deletePhoto), for: .touchUpInside)
            
            if !isAllowEdit {
                uploadImageContainer.hideDeleteButton()
            }
            
            photoScrollView.addSubview(uploadImageContainer)
            
            photoScrollView.isUserInteractionEnabled = true;
            photoScrollView.canCancelContentTouches = false;
            photoScrollView.delaysContentTouches = false;
            
            currentNumberOfPhoto += 1
            
            uploadImageContainers.append(uploadImageContainer)
            
            maxPhotoLabel.text = "\(currentNumberOfPhoto)/\(imageLimit)"
            
            if currentNumberOfPhoto == imageLimit {
                self.showCameraButton(false)
            }
        } else {
            ErrorLogManager.sharedManager.recordNonFatalError(withException: .NullPointer)
        }
    }
    
    @objc func deletePhoto(_ button: UIButton) {
        let selectedButtonTag = button.tag
        var imageDeleted: UIImage?
        var indexDeleted: Int = -1
        
        for subView in self.photoScrollView.subviews {
            if let uploadImageContainer = subView as? UploadImageContainer {
                if selectedButtonTag == subView.tag {
                    subView.removeFromSuperview()
                    currentNumberOfPhoto -= 1
                    
                    if selectedButtonTag < uploadImageContainers.count {
                        indexDeleted = selectedButtonTag
                        imageDeleted = uploadImageContainers[selectedButtonTag].imageView.image
                        uploadImageContainers.remove(at: selectedButtonTag)
                    }
                } else if subView.tag > selectedButtonTag {
                    subView.frame = CGRect(x: subView.frame.originX - PhotoImageViewSize.width - 20, y: subView.frame.originY, width: subView.frame.width, height: subView.frame.height)
                    uploadImageContainer.updateTag(uploadImageContainer.tag - 1)
                }
            } else {
                ErrorLogManager.sharedManager.recordNonFatalError(withException: .NullPointerOrTypeMismatch)
            }
        }
        
        maxPhotoLabel.text = "\(currentNumberOfPhoto)/\(imageLimit)"
        
        if currentNumberOfPhoto < imageLimit {
            showCameraButton(true)
        }
        
        if imageDeleted != nil && indexDeleted != -1 {
            self.deletePhotoTappedHandler?(imageDeleted!, indexDeleted)
        } else {
            ErrorLogManager.sharedManager.recordNonFatalError(withException: .NullPointer)
        }
    }
    
    func removeAllPhotos() {
        if !uploadImageContainers.isEmpty {
            for subView in self.photoScrollView.subviews {
                if type(of: subView) == UploadImageContainer.self {
                    subView.removeFromSuperview()
                }
            }
            
            currentNumberOfPhoto = 0
            maxPhotoLabel.text = "\(currentNumberOfPhoto)/\(imageLimit)"
            showCameraButton(true)
            uploadImageContainers.removeAll()
        }
    }
    
    func getPhotos() -> [UploadImageContainer] {
        return uploadImageContainers
    }
}

class UploadImageContainer: UIView {
    
    static let PaddingImageContent: CGFloat = 16
    var imageKey: String?
    
    var deleteButton: UIButton!
    var imageView: UIImageView!
    
    init(frame: CGRect, image: UIImage?, imageKey: String?, tag: Int, deleteImageName: String? = nil) {
        super.init(frame: frame)
        
        self.clipsToBounds = true
        self.imageKey = imageKey
        
        imageView = UIImageView(frame: CGRect(x: UploadImageContainer.PaddingImageContent, y: UploadImageContainer.PaddingImageContent, width: frame.width - 2 * UploadImageContainer.PaddingImageContent, height: frame.height - 2 * UploadImageContainer.PaddingImageContent))
        imageView.isUserInteractionEnabled = true
        imageView.image = image
        imageView.contentMode = .scaleAspectFill
        imageView.clipsToBounds = true
        addSubview(imageView)
        
        let deleteButtonSize = CGSize(width: 32, height: 32)
        deleteButton = UIButton(frame: CGRect(x: frame.width - deleteButtonSize.width, y: 0, width: deleteButtonSize.width, height: deleteButtonSize.height))
        deleteButton.setImage(UIImage(named: (deleteImageName != nil ? deleteImageName! : "icon_delete")), for: UIControlState())
        deleteButton.isUserInteractionEnabled = true
        addSubview(deleteButton)
        
        updateTag(tag)
    }
  
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    func updateTag(_ tag: Int) {
        self.tag = tag
        deleteButton.tag = tag
        imageView.tag = tag
    }
    
    func hideDeleteButton() {
        deleteButton.isHidden = true
    }
}
