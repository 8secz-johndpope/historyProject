//
//  GalleryViewController.swift
//  merchant-ios
//
//  Created by Vu Dinh Trung on 4/11/16.
//  Copyright © 2016 WWE & CO. All rights reserved.
//

import UIKit
import Photos
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
private func > <T : Comparable>(lhs: T?, rhs: T?) -> Bool {
  switch (lhs, rhs) {
  case let (l?, r?):
    return l > r
  default:
    return rhs < lhs
  }
}


protocol GalleryViewControllerDelegate: NSObjectProtocol {
    func handleDismisGalleryViewController(_ stage: StageMode)
    func imageCropViewControllerSuccess(_ controller: UIViewController!, didFinishCroppingImage croppedImage: UIImage!)
    func imageCropViewControllerDidCancel(_ controller: UIViewController!)
}

class GalleryViewController: MmViewController, PHPhotoLibraryChangeObserver, UIImagePickerControllerDelegate,UINavigationControllerDelegate, ImageCropViewControllerDelegate {
    
    var images: PHFetchResult<PHAsset>!
//    var albums: PHFetchResult<Any>!
    let imageManager = PHCachingImageManager()
    var imageCacheController: ImageCacheController!
    
    var selectedImage : UIImage?
    var selectedIndex : Int?
    private final let idCell = "imagesCell"
    var viewFooter = UIView()
    private final let HeightFooter: CGFloat = 50.0
    var catCollectionView : UICollectionView!
    private final let SubCatCellId = "SubCatCell"
    private final let CellId = "Cell"
    private final let CatCellHeight : CGFloat = 40
    private var currentIndex: Int = 0
    var picker = UIImagePickerController()
    var isFromCrop = false
    weak var galleryDelegate_ : GalleryViewControllerDelegate?
    var stage: StageMode?
    
	var isShowCrop = false
	
	var cropSquare = false
	
	var horizontalRectangle = false
    
    var ratio : CGFloat?
    
	override func viewDidLoad() {
        super.viewDidLoad()
        styleView()
        setupLeftButton()
        self.createRightButton(String.localize("LB_NEXT"), action: #selector(GalleryViewController.didSelectedRightButton))
        setupPicker()
    }

    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        
    }
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        currentIndex = 0
        setTabBottom()
        setupInitData()
    }
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        
    }
    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        
    }
    //MARK: - Init
    func setupPicker() -> Void {
        self.picker.delegate = self
    }
    func setupInitData() -> Void {

		let allPhotosOptions = PHFetchOptions()
		allPhotosOptions.sortDescriptors = [NSSortDescriptor(key: "creationDate", ascending: false)]
        
        images = PHAsset.fetchAssets(with: PHAssetMediaType.image, options: allPhotosOptions)
		
		imageCacheController = ImageCacheController(imageManager: imageManager, images: images, preheatSize: 1)
//        PHPhotoLibrary.sharedPhotoLibrary().registerChangeObserver(self)		

    }
    
    func styleView() -> Void {
        self.title = String.localize("LB_CA_ALBUM")
        
        self.collectionView.delegate = self
        self.collectionView.dataSource = self
        self.collectionView.frame = CGRect(x: 0, y: StartYPos, width: self.view.frame.width, height: self.view.frame.height - 64 - HeightFooter)
        self.collectionView.register(ImagesCollectionViewCell.self, forCellWithReuseIdentifier: idCell)
        
        
        let layout: SnapFlowLayout = SnapFlowLayout()
        layout.sectionInset = UIEdgeInsets(top: 0, left: 0, bottom: 0, right: 0)
        layout.scrollDirection = UICollectionViewScrollDirection.horizontal
        self.catCollectionView = UICollectionView(frame: CGRect(x: 0, y: self.view.bounds.height - HeightFooter, width: self.view.bounds.width, height: HeightFooter), collectionViewLayout: layout)
        self.catCollectionView.delegate = self
        self.catCollectionView.dataSource = self
        self.catCollectionView.backgroundColor = UIColor.white
        self.catCollectionView.register(SubCatCell.self, forCellWithReuseIdentifier: SubCatCellId)
        self.catCollectionView.isScrollEnabled = false
        self.view.addSubview(self.catCollectionView)
        addTopBorderWithColor(UIColor.secondary1(), andWidth: 1.0)
    }
    
    func setupLeftButton() -> Void {
        let buttonBack = UIButton(type: .custom)
        buttonBack.setImage(UIImage(named: "icon_cross"), for: UIControlState())
        buttonBack.frame = CGRect(x: 0, y: 0, width: Constants.Value.BackButtonWidth, height: Constants.Value.BackButtonHeight)
        buttonBack.contentEdgeInsets = UIEdgeInsets.init(top: 0, left: Constants.Value.BackButtonMarginLeft, bottom: 0, right: 0)
        let leftButton = UIBarButtonItem(customView: buttonBack)
        buttonBack.addTarget(self, action: #selector(GalleryViewController.closeViewController), for: .touchUpInside)
        self.navigationItem.leftBarButtonItem = leftButton
    }
    
    
    //MARK: - Action button
    @objc func closeViewController(_ sender: UIBarButtonItem) -> Void {
        self.stage = StageMode.firstStage
        if let st = stage {
            self.galleryDelegate_?.handleDismisGalleryViewController(st)
        }
        self.dismiss(animated: true, completion: nil)
    }
    
    @objc func didSelectedRightButton(_ sender: UIBarButtonItem) -> Void {
        
		self.goNextStep()
		
    }
	
	func goNextStep() {
		if let selectedIndex = selectedIndex {
            self.imageManager.requestImage(for: images[selectedIndex], targetSize: PHImageManagerMaximumSize, contentMode: .aspectFit, options: nil) { image, info in
				if image != nil {
                    if self.isShowCrop {
						let imagecropVc = ImageCropViewController(image: image)
						imagecropVc?.delegate = self
						imagecropVc?.blurredBackground = true
						imagecropVc?.square = self.cropSquare
						imagecropVc?.horizontalRectangle = self.horizontalRectangle
                        if let ratio = self.ratio {
                            imagecropVc?.ratio = NSNumber(value: Float(ratio) as Float)
                        }
						imagecropVc?.title = String.localize("LB_CA_EDIT_PICTURE")
						self.navigationController?.push(imagecropVc, animated: true)
 
                    } else {
                        self.galleryDelegate_?.imageCropViewControllerSuccess(self, didFinishCroppingImage: image)
                        self.navigationController?.popViewController(animated: true)
                        self.stage = StageMode.secondStage
                        self.closeViewController(UIBarButtonItem())
                    }
				}
			}
		}

	}

	//MARK: - PHPhotoLibraryChangeObserver
    func photoLibraryDidChange(_ changeInstance: PHChange) {
		
        if let changeDetails = changeInstance.changeDetails(for: images) {
            self.images = changeDetails.fetchResultAfterChanges
            self.collectionView.reloadData()
            DispatchQueue.main.async {
                // Loop through the visible cell indices
                let indexPaths = self.collectionView.indexPathsForVisibleItems
                for indexPath in indexPaths {
                    if changeDetails.changedIndexes!.contains(indexPath.item) {
                        let cell = self.collectionView?.cellForItem(at: indexPath) as! ImagesCollectionViewCell
                        cell.imageAsset = changeDetails.fetchResultAfterChanges[indexPath.item]
                    }
                }
            }
        }
        
    }
    //MARK: - Delegate & datasource
    // MARK: - CollectionView DataSource
    
    override func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        
        switch collectionView {
            
        case self.catCollectionView:
            return 2
        default:
            return images.count
        }
        
    }
    
    override func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {

        
        switch collectionView {
            
        case self.catCollectionView:
            let cell = collectionView.dequeueReusableCell(withReuseIdentifier: SubCatCellId, for: indexPath) as! SubCatCell
            switch indexPath.row {
            case 0:
                cell.label.text = String.localize("LB_CA_ALBUM")
                cell.label.textColor = UIColor.secondary2()
                cell.label.font = UIFont.boldSystemFont(ofSize: 14.0)
                cell.imageView.isHidden = true
                
                break
            case 1:
                cell.label.text = String.localize("LB_CA_TAKE_PIC")
                cell.label.textColor = UIColor.secondary2()
                cell.label.font = UIFont.boldSystemFont(ofSize: 14.0)
                cell.imageView.isHidden = true
                break
            
                
            default:
                break
            }
            
            if indexPath.row == currentIndex {
                selectedCell(cell)
            }
            return cell
        case self.collectionView:
            let cell = collectionView.dequeueReusableCell(withReuseIdentifier: idCell, for: indexPath) as! ImagesCollectionViewCell
            // Configure the cell
            cell.imageManager = imageManager
            cell.imageAsset = images[indexPath.item]
            if indexPath.row == selectedIndex {
                cell.layer.borderColor = UIColor.primary1().cgColor
                cell.layer.borderWidth = 5.0
            } else {
                cell.layer.borderColor = UIColor.primary1().cgColor
                cell.layer.borderWidth = 0.0
            }
            
            return cell
        default:
            
            return getDefaultCell(collectionView, cellForItemAt: indexPath)
        }

        
    }
    
    func getDefaultCell(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell{
        let cell = collectionView.dequeueReusableCell(withReuseIdentifier: CellId, for: indexPath)
        return cell
    }
    
    func setDefaultCell() {
        let cells = self.catCollectionView.visibleCells as! [SubCatCell]
        
        for i in 0 ..< self.catCollectionView.visibleCells.count {
            let cell = cells[i] as SubCatCell
            cell.label.textColor = UIColor.secondary2()
            cell.label.font = UIFont.boldSystemFont(ofSize: 14.0)
            cell.imageView.isHidden = true
        }
    }
    func selectedCell(_ cell: SubCatCell) {
        cell.imageView.image = UIImage(named: "underLineBrand")
        cell.label.font = UIFont.boldSystemFont(ofSize: 14.0)
        cell.imageView.isHidden = false
    }
    // MARK: - CollectionView Delegate

    func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        switch collectionView {
            
        case self.catCollectionView:
            currentIndex = indexPath.row
            switch indexPath.row {
            case 0:
                setTabBottom()
                break
            case 1:
                setTabBottom()
                openCamera()
                break
                
            default:
                break
            }
        case self.collectionView:
            didSelectedImage(indexPath)
            break
        default:
            break
        }

       
    }
    func setTabBottom() -> Void {
        let cells = self.catCollectionView.visibleCells as! [SubCatCell]
        if !cells.isEmpty {
            let cell = cells[currentIndex]
            cell.imageView.image = UIImage(named: "underLineBrand")
            cell.label.font = UIFont.boldSystemFont(ofSize: 14.0)
            cell.imageView.isHidden = false
        }
        self.catCollectionView.reloadData()
    }
    func collectionView(_ collectionView: UICollectionView, didDeselectItemAtIndexPath indexPath: IndexPath) {
        switch collectionView {
        case self.collectionView:
            let cell = collectionView.cellForItem(at: indexPath)
            cell?.layer.borderColor = UIColor.primary1().cgColor
            cell?.layer.borderWidth = 0.0
            break
        default:
            break
        }
    }
    func didSelectedImage(_ indexPath: IndexPath) -> Void {
        selectedIndex = indexPath.row
        let cell = collectionView.cellForItem(at: indexPath)
        cell?.layer.borderColor = UIColor.primary1().cgColor
        cell?.layer.borderWidth = 5.0
		
		self.goNextStep()
		
    }
    // MARK: - CollectionView FlowDelegate
    
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, sizeForItemAt indexPath: IndexPath) -> CGSize {
        
        switch collectionView {
            
        case self.catCollectionView:
           
			return CGSize(width: self.view.frame.size.width / 4, height: HeightFooter)
			
        default:
            return CGSize(width: (self.collectionView.frame.width - 10.0) / 3, height: (self.collectionView.frame.width - 10.0) / 3)
            
        }
        
    }
    
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, minimumInteritemSpacingForSectionAt section: Int) -> CGFloat {
        return 0.0
    }
    
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, minimumLineSpacingForSectionAt section: Int) -> CGFloat {
        return 5.0
    }
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, insetForSectionAt section: Int) -> UIEdgeInsets {
        
        switch collectionView {
            
        case self.catCollectionView:
            let space = (self.view.frame.width / 2 - Constants.LineSpacing.SubCatCell) / 2
            return  UIEdgeInsets(top: 0.0, left: space, bottom: 0.0, right: space)
            
        default:
            return UIEdgeInsets(top: 5.0, left: 0.0, bottom: 5.0, right: 0.0)
            
        }

        
    }
    
    // MARK: - ScrollViewDelegate
    func scrollViewDidScroll(_ scrollView: UIScrollView) {
        let indexPaths = collectionView?.indexPathsForVisibleItems
        if indexPaths?.count > 0 {
            if let ins = indexPaths {
                imageCacheController.updateVisibleCells(ins)
            }
        }
    }
    
    
    func openCamera() {
		
        Utils.checkCameraPermissionWithCallBack({[weak self] (granted) in
            if let strongSelf = self, granted {
                if(UIImagePickerController .isSourceTypeAvailable(UIImagePickerControllerSourceType.camera)) {
                    strongSelf.picker.sourceType = UIImagePickerControllerSourceType.camera
                    strongSelf.picker.cameraDevice = UIImagePickerControllerCameraDevice.rear
                    
                    strongSelf.present(strongSelf.picker, animated: true, completion: nil)
                } else {
                    Alert.alert(strongSelf, title: "Camera not found", message: "Cannot access the front camera. Please use photo gallery instead.")
                }
            }
        })
    }
    
    func imagePickerController(_ picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [String : Any]) {
        picker.dismiss(animated: true, completion: nil)
        
        if let imageCrop = (info[UIImagePickerControllerOriginalImage] as? UIImage)?.normalizedImage() {
            let imageCopy: UIImage = imageCrop.copy() as! UIImage
            let imagecropVc = ImageCropViewController(image: imageCopy)
            imagecropVc?.delegate = self
            imagecropVc?.blurredBackground = true
			imagecropVc?.square = self.cropSquare
			imagecropVc?.horizontalRectangle = self.horizontalRectangle
			
            imagecropVc?.title = String.localize("LB_CA_EDIT_PICTURE")
            if let ratio = self.ratio {
                imagecropVc?.ratio = NSNumber(value: Float(ratio) as Float)
            }
            
            self.navigationController?.push(imagecropVc, animated: true)
        }
    }
    func imagePickerControllerDidCancel(_ picker: UIImagePickerController) {
        self.dismiss(animated: true) { () -> Void in
            self.currentIndex = 0
            self.setTabBottom()
        }
    }
    func addTopBorderWithColor(_ color: UIColor, andWidth borderWidth: CGFloat) {
        let border: UIView = UIView()
        border.backgroundColor = color
        border.autoresizingMask = [.flexibleWidth, .flexibleBottomMargin]
        border.frame = CGRect(x: 0, y: 0, width: self.view.frame.size.width, height: borderWidth)
        self.catCollectionView.addSubview(border)
    }
    
    func imageCropViewControllerSuccess(_ controller: UIViewController!, didFinishCroppingImage croppedImage: UIImage!) {
        self.galleryDelegate_?.imageCropViewControllerSuccess(controller, didFinishCroppingImage: croppedImage)
        self.navigationController?.popViewController(animated: true)
        self.stage = StageMode.secondStage
        self.closeViewController(UIBarButtonItem())
    }
    func imageCropViewControllerDidCancel(_ controller: UIViewController!) {
        self.galleryDelegate_?.imageCropViewControllerDidCancel(controller)
    }
}
