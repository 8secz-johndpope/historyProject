//
//  PhotosSelectViewController.swift
//  merchant-ios
//
//  Created by Sang Nguyen on 12/21/16.
//  Copyright © 2016 WWE & CO. All rights reserved.
//

import UIKit
import Photos

class PhotosSelectViewController: MmViewController {

    enum PhotoViewMode {
        case gridView
        case listView //Albums List
    }

    private final let Spacing : CGFloat = 2
    private final let ImageCollectCellId = "PhotoSelectViewCell"
    private final let PhotoGroupCellId = "PhotoGroupCellId"
    private static let NumOfGridsInRow = CGFloat(3)
    private final let ThumbNailWidth = (UIScreen.main.bounds.width * UIScreen.main.scale) / NumOfGridsInRow
    weak var delegate : CreatePostProtocol?
    private var assetCollections = [PHAssetCollection]()
    private var selectedPhotoIdentifiers: [String] = []
    private var albumCollectionView: UICollectionView!
    private var fetchResult: PHFetchResult<PHAsset>?
    var photoViewMode: PhotoViewMode = .gridView
    var currentAlbumName : String?
    override func viewDidLoad() {
        super.viewDidLoad()
        super.pageAccessibilityId = "PhotoSelectPage"
        initAnalyticLog()
        self.setupCollectionView()
        // Do any additional setup after loading the view.
        NotificationCenter.default.addObserver(self, selector: #selector(self.didRemovePhoto), name: NSNotification.Name(rawValue: "DidRemovePhoto"), object: nil)
        self.fetchData(nil)
    }

    func fetchData(_ completion: ((Bool) -> Void)?) {
        let authStatus = Utils.checkPhotoPermission()
        if authStatus != .authorized && authStatus != .notDetermined {
            return
        }
        if authStatus == .notDetermined {
            PHPhotoLibrary.requestAuthorization({[weak self] (authStatus) in
                dispatch_async_safely_to_main_queue({
                    if authStatus != .authorized {
                        
                        TSAlertView_show(String.localize("LB_CA_IM_ACCESS_PHOTOS_PERMIT"), message: String.localize("LB_CA_IM_ACCESS_PHOTOS_DENIED"), labelCancel: nil)
                    } else {
                        if let strongSelf = self {
                            
                            strongSelf.fetchPhotos(completion)
                        }
                    }
                })
            })
        } else {
           self.fetchPhotos(completion)
        }
    }
    
    @objc func updatePhotoInAppForceGround() {
        self.fetchData(nil)
    }
    
    func fetchPhotos(_ completion: ((Bool) -> Void)?){
        if self.photoViewMode == .listView {
            self.fetchAllCollections(completion)
        } else {
            self.fetchFirstAssetCollection(completion)
        }
    }
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        self.updateFrameCollectionView()
        NotificationCenter.default.addObserver(self, selector: #selector(self.updateFrameCollectionView), name: Constants.Notification.createPostDidUpdatePhoto, object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(self.updatePhotoInAppForceGround), name: NSNotification.Name.UIApplicationWillEnterForeground, object: nil)
        Log.info("view will appear")
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        NotificationCenter.default.removeObserver(self, name: Constants.Notification.createPostDidUpdatePhoto, object: nil)
        NotificationCenter.default.removeObserver(self, name: NSNotification.Name.UIApplicationWillEnterForeground, object: nil)
    }
    
    func setupCollectionView() {
        collectionView.register(PhotoSelectViewCell.self, forCellWithReuseIdentifier: ImageCollectCellId)
        collectionView.register(PhotoGroupViewCell.self, forCellWithReuseIdentifier: PhotoGroupCellId)
        
        let layout: UICollectionViewFlowLayout = getCustomFlowLayout()
        layout.sectionInset = UIEdgeInsets(top: 0, left: 0, bottom: 0, right: 0)
        layout.itemSize = CGSize(width: self.view.frame.width, height: 120)
     
        albumCollectionView = UICollectionView(frame: collectionView.frame, collectionViewLayout: layout)
        albumCollectionView.dataSource = self
        albumCollectionView.delegate = self
        albumCollectionView.alwaysBounceVertical = true
        albumCollectionView.register(UICollectionViewCell.self, forCellWithReuseIdentifier: "Cell")
        albumCollectionView.backgroundColor = UIColor.white
        albumCollectionView.isHidden = true
        self.view.addSubview(albumCollectionView)
        albumCollectionView.register(PhotoGroupViewCell.self, forCellWithReuseIdentifier: PhotoGroupCellId)
    }
    
    @objc func updateFrameCollectionView() {
        let topBarHeight = ((self.delegate?.getTopViewHeight()) ?? 0) + 20
        let height = UIScreen.main.bounds.height - (topBarHeight + ((self.delegate?.getBottomViewHeight()) ?? 0))
        collectionView.frame = CGRect(x: 0, y: topBarHeight , width: self.view.width, height: height)
        
        var collectionFrame = collectionView.frame
        if photoViewMode == .gridView {
            collectionFrame.sizeHeight = 0
        }
        albumCollectionView.frame = collectionFrame
    }
    
    func fetchFirstAssetCollection(_ completion: ((Bool) -> Void)?){
        let smartAlbums = PHAssetCollection.fetchAssetCollections(with: .smartAlbum, subtype: .smartAlbumUserLibrary, options: nil)

        for i in 0..<smartAlbums.count {
            let assetCollection = smartAlbums.object(at: i)
            self.getFetchResult(assetCollection)
            break
        }
        
        self.collectionView.reloadData()
        completion?(true)
    }
    
    func getFetchResult(_ assetCollection: PHAssetCollection){
        let assets = PHAsset.fetchAssets(in: assetCollection, options: getFetchOption())
        if assets.count > 0 {
            self.assetCollections = [assetCollection]
            self.fetchResult = assets
        }
    }

    func getFetchOption() -> PHFetchOptions{
        let options = PHFetchOptions()
        options.sortDescriptors = [NSSortDescriptor(key: "creationDate", ascending: false)]
        return options
    }
    
    //flag to check fetch asset for thumnail group or not
    func getAssetAtIndexPath(_ indexPath: IndexPath, isGroupThumNail: Bool = false) -> PHAsset? {
        
        if let fetchResult = self.fetchResult, fetchResult.count > indexPath.row && !isGroupThumNail {
            return fetchResult.object(at: indexPath.row)
        }
        
        let assets = PHAsset.fetchAssets(in: self.assetCollections[indexPath.section], options: getFetchOption())
        return assets.object(at: indexPath.row)
    
    }

    func fetchAllCollections(_ completion: ((Bool) -> Void)?) {
        let smartAlbums = PHAssetCollection.fetchAssetCollections(with: .smartAlbum, subtype: .albumRegular, options: nil)
        let userAlbums = PHAssetCollection.fetchAssetCollections(with: .album, subtype: .albumRegular, options: nil)
        let allAlbums = [userAlbums, smartAlbums]
        
        var collections = [PHAssetCollection]()
        
        for indexCollection in 0 ..< allAlbums.count {
            let albums = allAlbums[indexCollection]
            for indexAlbum in 0 ..< albums.count {
                let assetCollection = albums.object(at: indexAlbum)
                let assets = PHAsset.fetchAssets(in: assetCollection, options: getFetchOption())
                if assets.count > 0 {
                    collections.append(assetCollection)
                }
            }
        }
        
        self.assetCollections = collections
        self.albumCollectionView.reloadData()
        
        completion?(true)
    }
    
    
    func isSelectedPhoto(_ weakAsset: PHAsset?) -> Bool {
        if let asset = weakAsset, selectedPhotoIdentifiers.contains(asset.localIdentifier) {
            return true
        }
        return false
    }
    
    func getNumberPhotoOfAlbum(_ index: Int) ->Int {
        if index < self.assetCollections.count {
           let assets: PHFetchResult = PHAsset.fetchAssets(in: self.assetCollections[index], options: getFetchOption())
           return assets.count
           
        }
        return 0
    }
    
    //MARK: - Animation
    
    
    
    func expandAlbumCollectionViewAnimation(_ completion: ((Bool) -> Void)?) {
        
        albumCollectionView.isHidden = false
        
        var collectionFrame = self.collectionView.frame
        collectionFrame.originY = -collectionFrame.sizeHeight
        self.albumCollectionView.frame = collectionFrame
        
        UIView.animate(withDuration: 0.5, animations: { [weak self] in
            if let strongSelf = self {
                
                collectionFrame.originY = strongSelf.collectionView.frame.originY
                strongSelf.albumCollectionView.frame = collectionFrame
            }
            }, completion: {[weak self] (success) in
                if let strongSelf = self {
                    strongSelf.collectionView.isHidden = true
                }
                completion?(success)
        }) 
    }
    
    func collapseAlbumCollectionViewAnimation (_ completion: ((Bool) -> Void)?) {
        self.collectionView.isHidden = false
        var collectionFrame = albumCollectionView.frame
        
        
        UIView.animate(withDuration: 0.5, animations: { [weak self] in
            if let strongSelf = self {
                collectionFrame.originY = -collectionFrame.sizeHeight
                strongSelf.albumCollectionView.frame = collectionFrame
            }
        }, completion: { [weak self](success) in
            
            if let strongSelf = self {
                strongSelf.albumCollectionView.isHidden = true
            }
            
            completion?(success)
        }) 
    }
    
    //MARK: - Collection Delegate
    func numberOfSections(in collectionView: UICollectionView) -> Int {
        if collectionView == albumCollectionView {
            return self.assetCollections.count
        }
        return 1
    }
    
    override func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        if collectionView == self.collectionView {
            if let fetchResult = self.fetchResult {
                return fetchResult.count + 1 //first cell is image capture
            }
            return 1
        }
        
        return 1
    }
    
    override func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        if (collectionView == albumCollectionView) {
            
            let cell = collectionView.dequeueReusableCell(withReuseIdentifier: PhotoGroupCellId, for: indexPath) as! PhotoGroupViewCell
            if indexPath.section < self.assetCollections.count {
                cell.groupLabel.text = "\(self.assetCollections[indexPath.section].localizedTitle ?? "") (\(self.getNumberPhotoOfAlbum(indexPath.section)))" //not counting take photo camera icon
                cell.asset = self.getAssetAtIndexPath(indexPath, isGroupThumNail: true)
            }
            
            return cell
            
        } else if collectionView == self.collectionView {
            
            let cell = collectionView.dequeueReusableCell(withReuseIdentifier: ImageCollectCellId, for: indexPath) as! PhotoSelectViewCell
            
            if indexPath.row == 0 {
                cell.isCameraCell = true
            } else {
                cell.isCameraCell = false
                
                let asset = self.getAssetAtIndexPath(IndexPath(row: indexPath.row - 1, section: indexPath.section))
                cell.asset = asset
                cell.setSelect(self.isSelectedPhoto(asset))
                self.setAccessibilityIdForView("UIBT_SELECT_PHOTO", view: cell)
            }
            
            return cell;
        }
        return UICollectionViewCell();
        
        
    }
    
    func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        
        if collectionView == albumCollectionView {
            self.photoViewMode = .gridView
            self.assetCollections = [self.assetCollections[indexPath.section]]
            let album = self.assetCollections[0]
            self.getFetchResult(album)
            self.collapseAlbumCollectionViewAnimation(nil)

            currentAlbumName = album.localizedTitle
            self.collectionView.reloadData()
            self.delegate?.didChangePhotoViewMode(self.photoViewMode, albumName: currentAlbumName)
        } else {
            
            if indexPath.row == 0 {
                self.delegate?.didSelectCamera()
            } else {
                let asset = self.getAssetAtIndexPath(IndexPath(item: indexPath.row - 1, section: indexPath.section))
                if !isSelectedPhoto(asset) && (self.delegate?.isEnoughPhoto()) ?? false {
                    self.delegate?.showErrorFull()
                } else {
                    if let asset = asset {
                        
                        guard asset.pixelWidth < Constants.NewsFeed.CONST_POST_IMG_RESOLUTION_LIMIT && asset.pixelHeight < Constants.NewsFeed.CONST_POST_IMG_RESOLUTION_LIMIT else {
                            UIAlertController.showAlert(in: self, withTitle: "", message: String.localize("MSG_ERR_CA_PHOTO_TOO_LARGE"), cancelButtonTitle: String.localize("LB_CA_CONFIRM"), destructiveButtonTitle: nil, otherButtonTitles: nil) { (controller , action, buttonIndex) -> Void in
                            }
                            return
                        }
                        
                        if isSelectedPhoto(asset) {
                            self.selectedPhotoIdentifiers.remove(asset.localIdentifier)
                        } else {
                            self.selectedPhotoIdentifiers.append(asset.localIdentifier)
                        }
                        self.collectionView.reloadItems(at: [indexPath])
                        let photo = Photo(asset: asset)
                        self.delegate?.didSelectPhoto(photo)
                    }
                }
            }
        }
    }
    
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, minimumInteritemSpacingForSectionAt section: Int) -> CGFloat {
        return 0.0
    }
    
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, minimumLineSpacingForSectionAt section: Int) -> CGFloat {
        return Spacing
    }
    
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, insetForSectionAt section: Int) -> UIEdgeInsets {
        return UIEdgeInsets.zero
    }
    
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, sizeForItemAt indexPath: IndexPath) -> CGSize {
        
        if collectionView == albumCollectionView {
            return CGSize(width: self.view.frame.sizeWidth, height: 70)
        } else {
            let width = (view.width - Spacing * 2) / 3
            return CGSize(width: width, height: width)
        }
    }
    @objc func didRemovePhoto(_ notification: Notification) {
        if let removedPhoto = notification.object as? Photo, let asset = removedPhoto.asset {
            if isSelectedPhoto(removedPhoto.asset) {
                self.selectedPhotoIdentifiers.remove(asset.localIdentifier)
                self.collectionView.reloadData()
            }
        }
    }
    
    //MARK: - Analytics
    
    func initAnalyticLog(){
        
        let user = Context.getUserProfile()
        let authorType = user.userTypeString()
        
        initAnalyticsViewRecord(
            Context.getUserKey(),
            authorType: authorType,
            brandCode: nil,
            merchantCode: nil,
            referrerRef: nil,
            referrerType: nil,
            viewDisplayName: nil,
            viewParameters: nil,
            viewLocation: "Editor-Image-Album",
            viewRef: nil,
            viewType: "Post"
        )
    }
}

//Use only for current class


class Photo: NSObject {
    var thumbNail : UIImage?
    static let imageManager = PHCachingImageManager()
    var fullImage : UIImage?
    var asset : PHAsset?
    var photoId = Utils.UUID()
    var index = 0
    init(thumbNail: UIImage? = nil, asset: PHAsset? = nil) {
        super.init()
        self.thumbNail = thumbNail
        self.asset = asset
    }
    
    func getThumbnailByAsset(_ imageSize: CGSize, resultHandler: @escaping (UIImage?) -> Void){
        
        guard asset != nil else {
            resultHandler(nil)
            return
        }
        
        let options = PHImageRequestOptions()
        options.deliveryMode = .highQualityFormat
        options.isSynchronous = false
        Photo.imageManager.allowsCachingHighQualityImages = false
        
        Photo.imageManager.requestImage(for: self.asset!,
                                          targetSize: imageSize,
                                          contentMode: .aspectFill,
                                          options: options,
                                          resultHandler: {
                                            (image, info) -> Void in
                                            resultHandler(image)
        })
        
        
    }
    
}
