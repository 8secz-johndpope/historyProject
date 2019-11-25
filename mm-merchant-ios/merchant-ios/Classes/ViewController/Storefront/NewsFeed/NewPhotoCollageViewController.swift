//
//  CreatePostSelectImageViewController.swift
//  merchant-ios
//
//  Created by Sang Nguyen on 12/22/16.
//  Copyright © 2016 WWE & CO. All rights reserved.
//

import UIKit
import Foundation
import Kingfisher
import Photos

protocol NewPhotoCollageDelegate: NSObjectProtocol {
    func didBackFromViewController(_ viewController: MmViewController?)
    func didChangePhotoFrames(_ photos: [PostCreateData])
    func didSelectTemplateIndex(_ templatePhotos: [PostCreateData], templateIndex: Int?)
    func didSelectAddMorePhoto(_ templatePhotos: [PostCreateData], templateIndex: Int?, atIndex: Int?)
}

class NewPhotoCollageViewController: MmViewController, TagProductViewControllerDelegate, TouchBaseViewDelegate, TagViewDelegate {
    
    private final let PhotoFrameStyleCellIdentifier = "PhotoFrameStyleCell"
    private final let CellHeight : CGFloat = 50
    private final let ImageMaxWidth = CGFloat(Constants.MaxImageWidth)
    private final let CollectionViewHeight : CGFloat = 100
    private final let NumberTagProductMax = 5
    var frameArray : [[CGRect]] = []
    var selectedFrameIndex : Int = 0
    var photoFrameView : UIView!
    var selectedIndex = 0
    var productTagViews  = [ProductTagView]()
    var isFromPDP =  ModeTagProduct.productListPage
    var selectedColorId = -1
    var selectedSizeId = -1
    var colorKey = ""
    var frameLabelView : UIView!
    var frameLabel : UILabel!
    private var buttonBack: UIButton?
    private var viewHint: UIView?
    var postCreateDataList = [PostCreateData]()
    private var touchBaseViews = [TouchBaseView]()
    private var isFirstLoading = true
    var resetTagsPositionFirstLoad = true
    private var productView : ProductView?
    private final let ProductViewMarginLeft: CGFloat = 50
    weak var delegate : NewPhotoCollageDelegate?
    var lastPositionTap = CGPoint.zero
    var downloadTimeout : TimeInterval?
    var templateIndex : Int?
    
    var selectedHashTag: String? = nil
    
    lazy var productTagView:ProductTagView = {
        let size = CGSize(width: ScreenWidth, height: ScreenWidth)
        let productTagView = ProductTagView(position: CGPoint(x: size.width / 3,y:64 + size.width / 2), price: 0, parentTag: 1, delegate: self, oldPrice: 0, newPrice: 0, logoImage: UIImage(named: "logo6")!, logo: "", tagImageSize: size, skuId: 0, place : TagPlace.right,tagStyle:.Add)
        productTagView.title = "添加商品和品牌标签"
        productTagView.mode = .special
        productTagView.isAddedManually = true
        productTagView.isUserInteractionEnabled = false
        return productTagView
    }()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view, typically from a nib.
        NotificationCenter.default.addObserver(self, selector: #selector(CreateOutfitViewController.updateTagArrays), name: Constants.Notification.updateTagArraysForPost, object: nil)
        self.createBackButton(.grayColor)
        buttonBack?.addTarget(self, action: #selector(self.backButtonClicked), for: .touchUpInside)
        self.title = String.localize("LB_CA_EDIT_PICTURE")
        self.createRightButton(String.localize(String.localize("LB_NEXT")), action: #selector(didSelectedRightButton))
        self.setupPhotoFrameView()
        self.frameArray = FrameManager.setupFrameArray()
        self.setupCollectionView()
        self.setupFrameLabelView()
        
        NotificationCenter.default.addObserver(self, selector: #selector(updateTagArrays), name: Constants.Notification.updateTagArraysForFrame, object: nil)
        if (LoginManager.getLoginState() == .guestUser){
            self.dismiss(animated: true, completion: {
                LoginManager.goToLogin()
            })
        }
        self.initAnalyticLog()
        
        self.view.addSubview(productTagView)
    }
    
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        self.updateAddButtons()
        if isFirstLoading {
            isFirstLoading = false
            let frameIndexDetected = self.detectFrame()
            if let previousTemplateIndex = self.templateIndex {
                let numberSubFrame = FrameManager.getNumberSubFrameFromFrameIndex(previousTemplateIndex)
                if self.postCreateDataList.count > numberSubFrame {
                    selectedFrameIndex = frameIndexDetected
                } else {
                    selectedFrameIndex = previousTemplateIndex
                }
            } else {
                selectedFrameIndex = frameIndexDetected
            }
            
            var countSku = 0
            for currentPost in self.postCreateDataList {
                if let strongSku = currentPost.skus {
                    countSku += strongSku.count
                }
            }
            
            if (countSku > self.productTagViews.count) {
                self.layoutFrameAndImage(selectedFrameIndex,isNeedRefreshTag: resetTagsPositionFirstLoad)
            } else {
                self.layoutFrameAndImage(selectedFrameIndex,isNeedRefreshTag: true)
            }
            
            //hints to tell the user the post can be tagged
            if productTagView.alpha == 1 {
                showProductTagView()
            }
            
        } else {
            self.showAllTags()
//            self.layoutFrameAndImage(selectedFrameIndex,isNeedRefreshTag: true)
        }
        
        if self.downloadTimeout == nil {
            self.downloadTimeout = KingfisherManager.shared.downloader.downloadTimeout
        }
        KingfisherManager.shared.downloader.downloadTimeout = 60
        
    }
    
    func showAllTags(){
        for productTagView in self.productTagViews {
            productTagView.isHidden = false
        }
    }
    
    
    func refreshAllTag(){
        for touchBaseView in self.touchBaseViews {
            if touchBaseView.tag < self.postCreateDataList.count {
                self.postCreateDataList[touchBaseView.tag].refreshData(touchBaseView.frame, index: touchBaseView.tag)
                let productTagViews = self.productTagViews.filter({$0.tag == touchBaseView.tag})
                for productTagView in productTagViews {
                    productTagView.photoFrameIndex = touchBaseView.tag
                    productTagView.layoutSubviews()
                }
            }
            
        }
    }
    func createTagProducts(){
        for i in 0..<postCreateDataList.count {
            
            switch postCreateDataList[i].itemType {
            case .album:
                if let photo = postCreateDataList[i].getImage() {
                    self.setPhotoForSubFrame(photo, subFrameIndex: i)
                }
            case .category, .wishlist:
                let skus = postCreateDataList[i].getSkuList()
                for sku in skus {
                    if let image = self.postCreateDataList[i].getImage() {
                        if postCreateDataList[i].itemType == .category {
                            self.setImageForSubFrame(image, mode: .search, subFrameIndex: i, sku: sku, uniqueId: postCreateDataList[i].uniqueId)
                        } else {
                            self.setImageForSubFrame(image, mode: .shoppingCart, subFrameIndex: i, sku: sku, uniqueId: postCreateDataList[i].uniqueId)
                        }
                    } else {
                        if postCreateDataList[i].itemType == .category {
                            self.getImageForTagProduct(sku, mode: .search, index: i, uniqueId: postCreateDataList[i].uniqueId)
                        } else {
                            self.getImageForTagProduct(sku, mode: .shoppingCart, index: i, uniqueId: postCreateDataList[i].uniqueId)
                        }
                    }
                }
            default: break
            }
            
        
            
            if postCreateDataList[i].getSkuList().count == 1 && postCreateDataList[i].tags?.count == nil{
                let sku = postCreateDataList[i].getSkuList()[0]

                let imageTage = ImagesTags()
                imageTage.place = .undefined
                imageTage.id = sku.skuId
                imageTage.tagImage = sku.productImage
                imageTage.positionX = sku.positionX
                imageTage.positionY = sku.positionY
                imageTage.sku = sku
                imageTage.title = sku.brandName
                imageTage.tagTitle = sku.skuName
                postCreateDataList[i].addTag(tag: imageTage)
            }
            
            
            let productTagViews = self.generateProductTagViewsFromSkus(postCreateDataList[i].tags, frameIndex: i)
            self.productTagViews.append(contentsOf: productTagViews)
        }
        if self.productTagViews.count > NumberTagProductMax {
            self.productTagViews = Array(self.productTagViews.prefix(NumberTagProductMax))
        }
    }
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        self.drawFrameBySelectedIndex()
        
    }
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        self.navigationController?.delegate = nil
        if let timeout = self.downloadTimeout {
            KingfisherManager.shared.downloader.downloadTimeout = timeout
        }
    }
    
    @objc override func backButtonClicked(_ button: UIButton) {
        for viewController in (self.navigationController?.viewControllers)! {
            if let checkoutViewController = viewController as? CreatePostSelectImageViewController {
                if checkoutViewController.fromMenuSelect {
                    self.navigationController?.popViewController(animated: true)
                    return
                }
            }
        }
        self.delegate?.didBackFromViewController(self)
        self.delegate?.didSelectTemplateIndex(self.postCreateDataList, templateIndex: self.selectedFrameIndex)
        super.backButtonClicked(button)
    }
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    func detectFrame()->Int {
        var frameIndex = 0
        switch postCreateDataList.count {
        case 1:
            frameIndex = FrameIndex.frame1.rawValue
        case 2:
            frameIndex = FrameIndex.frame2a.rawValue
        case 5:
            frameIndex = FrameIndex.frame5.rawValue
        default:
            frameIndex = postCreateDataList.count
        }
        return frameIndex
    }
    deinit {
        NotificationCenter.default.removeObserver(self, name: Constants.Notification.updateTagArraysForFrame, object: nil)
    }
    
    @objc func updateTagArrays(_ notification: Notification) {
        // remove previous tags
        if self.productTagViews.count > 0 {
            self.productTagViews.removeAll()
        }
        if let tags : [ProductTagView] = notification.object as? [ProductTagView] {
            self.productTagViews = tags
        }
    }

    func updateAddButtons() {
        for toucViewBase in touchBaseViews {
            if  (toucViewBase.touchImageView.image == nil){
                toucViewBase.buttonAdd.isHidden = false
            } else {
                toucViewBase.buttonAdd.isHidden = true
            }
        }
    }
    
    func drawFrameBySelectedIndex() {
        let indexPath = IndexPath(row: self.selectedFrameIndex, section: 0)
        self.collectionView.scrollToItem(at: indexPath, at: .centeredHorizontally, animated: true)
    }
    
    func setupPhotoFrameView() {
        photoFrameView = UIView(frame: CGRect(x: 0, y: (self.navigationController?.navigationBar.frame.size.height)! + 20, width: UIScreen.main.bounds.size.width, height: UIScreen.main.bounds.size.width))
        self.view.addSubview(photoFrameView)
        
    }
    func showProductTagView (){
        self.productTagView.alpha = 1
        UIView.animate(withDuration: 1.0, delay: 2.0, options: .curveEaseIn, animations: {
            self.productTagView.alpha = 0
        }) { (success) in
        }
    }
    func showHintEditTag() {
        
        let hintViewSize = CGSize(width: 160.0, height: 40.0)
        let paddingLeftRight: CGFloat = 10.0
        viewHint = UIView(frame: CGRect(x: (photoFrameView.bounds.width - hintViewSize.width) / 2 , y: (photoFrameView.bounds.height - hintViewSize.height) / 2, width: hintViewSize.width, height: hintViewSize.height))
        if let viewHint = self.viewHint {
            viewHint.backgroundColor = UIColor.black
            viewHint.alpha = 0.0
            viewHint.layer.cornerRadius = hintViewSize.height / 2
            viewHint.layer.borderWidth = 0.0
            viewHint.isUserInteractionEnabled = false
            
            let labelHint = UILabel(frame: CGRect(x: paddingLeftRight, y: 0, width: viewHint.bounds.width - 2 * paddingLeftRight, height: viewHint.bounds.height))
            labelHint.formatSize(14)
            labelHint.textColor = UIColor.white
            labelHint.text = String.localize("LB_CA_ADD_TAG_HINT")
            labelHint.adjustsFontSizeToFitWidth = true
            labelHint.textAlignment = .center
            viewHint.addSubview(labelHint)
            
            //photoFrameView.isUserInteractionEnabled = false
            photoFrameView.addSubview(viewHint)
            
            /*
             MM-25502 When user arrive this page, the centre hints (white text with grey overlay rectangle) will appear and fade in alpha from 0% to e.g. 70%
             */
            UIView.animate(withDuration: 1.0, delay: 0, options: UIViewAnimationOptions(), animations: {
                viewHint.alpha = 0.7
                }, completion: { (success) in
                    UIView.animate(withDuration: 1.0, delay: 2.0, options: UIViewAnimationOptions(), animations: {
                        viewHint.alpha = 0.0
                        }, completion: { (success) in
                                //strongSelf.photoFrameView.isUserInteractionEnabled = true
                                viewHint.removeFromSuperview()
                        })
            })
        }
    }
    
    func layoutFrameAndImage(_ frameIndex: Int, isNeedRefreshTag: Bool = false) {
        // clean up previous frame view
        for view in photoFrameView.subviews {
            view.removeFromSuperview()
        }
        let screenWidth = UIScreen.main.bounds.size.width
        var touchBaseViewArray = [TouchBaseView]()
        let array : [CGRect] = frameArray[frameIndex]
            for i in 0 ..< array.count {
                
                 let rect : CGRect = array[i]
                    let frameView = TouchBaseView(frame: rect)
                    frameView.setBaseFrame(TouchBaseView.addPaddingOnFrame(Define.FRAME_OFFSET, frame: frameView.frame))
                    frameView.touchImageView.isHidden = true
                    frameView.tag = i
                    frameView.touchBaseViewDelegate = self
                    frameView.buttonAdd.tag = i
                    frameView.buttonAdd.addTarget(self, action: #selector(NewPhotoCollageViewController.didTapOnAddPhotoButton), for: .touchUpInside)
                    if frameIndex == Define.CIRCLE_FRAME {
                        if (rect.size.width + Define.FRAME_OFFSET) < screenWidth {
                            frameView.layer.cornerRadius = frameView.frame.width / 2
                            frameView.touchImageView.backgroundColor = UIColor.secondary1()
                        }
                    }
                    if (rect.size.width + Define.FRAME_OFFSET) == screenWidth {
                        frameView.backgroundColor = UIColor.lightGray
                    }
                    // check and layout frame image
                    
                    frameView.frames = array
                    frameView.touchImageView.isHidden = false
                    photoFrameView.addSubview(frameView)
                    if i < self.postCreateDataList.count {
                        self.postCreateDataList[i].subFrame = frameView.frame
                        self.postCreateDataList[i].tag = i
                        self.postCreateDataList[i].tagViewDelegate = self
                        frameView.touchImageView.image = self.postCreateDataList[i].getImage()
                        frameView.buttonAdd.isHidden = frameView.touchImageView.image != nil
                    }
                    frameView.initAnalytics(withViewKey: self.analyticsViewRecord.viewKey)
                    touchBaseViewArray.append(frameView)
                
            }
        self.touchBaseViews = touchBaseViewArray
        self.createTagProducts()
        self.renderTagProduct(isNeedRefreshTag)
        self.hasImageFillAllFrame()
    }
    
    func setupFrameLabelView() {
        if self.frameLabelView != nil {
            self.frameLabelView.removeFromSuperview()
        }
        let screenWidth = UIScreen.main.bounds.size.width
        let labelViewHeight = self.view.height - self.collectionView.frame.maxY
        self.frameLabelView = UIView(frame: CGRect(x: 0, y: self.collectionView.frame.maxY, width: screenWidth, height: labelViewHeight))
        self.frameLabel = UILabel(frame: CGRect(x: 0, y: 0, width: screenWidth, height: labelViewHeight))
        self.frameLabel.text = String.localize("LB_CA_PRODUCT_TAG_EDITOR_DESC")
        self.frameLabel.font = UIFont.systemFont(ofSize: 12)
        self.frameLabel.numberOfLines = 0
        self.frameLabel.textAlignment = .center
        self.frameLabel.textColor = UIColor.secondary4()
        self.frameLabelView.addSubview(self.frameLabel)
        let line = UIView(frame: CGRect(x: 10, y: 0, width: screenWidth - 20, height: 1))
        line.backgroundColor = UIColor.secondary1()
        self.frameLabelView.addSubview(line)
        self.view.addSubview(self.frameLabelView)
    }
    
    func setupCollectionView() {
        
        let	layout = UICollectionViewFlowLayout()
        layout.itemSize = CGSize(width: ScreenWidth/5, height: ScreenWidth/5)
        layout.scrollDirection = .horizontal
        self.collectionView.frame = CGRect(x: 0, y: self.photoFrameView.frame.maxY + ScreenTop, width: UIScreen.main.bounds.size.width, height: CollectionViewHeight)
        self.collectionView.collectionViewLayout = layout
        self.collectionView.delegate = self
        self.collectionView.dataSource = self
//        self.collectionView.translatesAutoresizingMaskIntoConstraints = false
        self.collectionView.showsHorizontalScrollIndicator = false
        self.collectionView.showsVerticalScrollIndicator = false
        self.collectionView.alwaysBounceVertical = false
        self.collectionView = collectionView
        self.collectionView.register(PhotoFrameStyleCell.self, forCellWithReuseIdentifier: PhotoFrameStyleCellIdentifier)
    }
    
    func navigationController(_ navigationController: UINavigationController, animationControllerForOperation operation: UINavigationControllerOperation, fromViewController fromVC: UIViewController, toViewController toVC: UIViewController) -> UIViewControllerAnimatedTransitioning? {
        if operation == .push {
            return PushFadingAnimator()
        }
        return nil
    }
    
    
    //MARK: - Delegate & Datasource
    func numberOfSections(in collectionView: UICollectionView) -> Int {
        return 1
    }
    
    override func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        
        return frameArray.count
    }
    
    override func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        let cell = collectionView.dequeueReusableCell(withReuseIdentifier: PhotoFrameStyleCellIdentifier, for: indexPath) as! PhotoFrameStyleCell
        if indexPath.section == 0 {
            cell.tag = indexPath.row
            if let imageView = cell.frameImageView {
                imageView.image = UIImage(named: "frame\(indexPath.row+1)")
            }
            cell.isSelectedFrame((indexPath.row == selectedFrameIndex))
            return cell
        }
        return cell
    }
    
    func collectionView(_ collectionView: UICollectionView, shouldSelectItemAtIndexPath indexPath: IndexPath) -> Bool {
        return true
    }
    
    func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        NotificationCenter.default.post(name: Notification.Name(rawValue: "PhotoFrameStyleCellSelectedFrame"), object: nil)
        selectedFrameIndex = indexPath.row
        self.removeOrderEmptyPostCreateData()
        self.productTagViews.removeAll()
        self.layoutFrameAndImage(indexPath.row, isNeedRefreshTag: true)
        self.delegate?.didSelectTemplateIndex(self.postCreateDataList, templateIndex: self.selectedFrameIndex)
        collectionView.reloadData()
        collectionView.scrollToItem(at: indexPath, at: .centeredHorizontally, animated: true)
        self.view.recordAction(
            .Tap,
            sourceRef: "Template" + String(indexPath.row + 1),
            sourceType: .ImageTemplate,
            targetRef: "Editor-Image",
            targetType: .View)
    }
    
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, minimumInteritemSpacingForSectionAt section: Int) -> CGFloat {
        return 0.0
    }
    
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, minimumLineSpacingForSectionAt section: Int) -> CGFloat {
        return 10.0
    }
    
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, insetForSectionAt section: Int) -> UIEdgeInsets {
        let marginTopBottom = (CollectionViewHeight - CellHeight) / 2
        return UIEdgeInsets(top: marginTopBottom, left: 10.0, bottom: marginTopBottom, right: 10.0)
    }
    
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, sizeForItemAt indexPath: IndexPath) -> CGSize {
        if indexPath.section == 0 {
            return CGSize(width: CellHeight, height: CellHeight)
        }
        return CGSize.zero
    }
    
    func collectionView(_ collectionView: UICollectionView, viewForSupplementaryElementOfKind kind: String, at indexPath: IndexPath) -> UICollectionReusableView {
        return UICollectionReusableView()
    }
    
    func removeOrderEmptyPostCreateData(){
        self.postCreateDataList = self.postCreateDataList.filter({$0.itemType != .unknown})
        let numberSubFrame = FrameManager.getNumberSubFrameFromFrameIndex(self.selectedFrameIndex)
        let number = numberSubFrame - self.postCreateDataList.count
        if (number > 0) {
            for _ in 0 ..< number {
                self.postCreateDataList.append(PostCreateData())
            }
        }
        
    }
    // check  photo into frame
    @discardableResult
    func hasImageFillAllFrame() -> Bool {
        for touchBaseView in self.touchBaseViews {
            if touchBaseView.touchImageView.image == nil {
                self.updateRightButton(false)
                return false
            }
        }
        self.updateRightButton(true)
        return true
    }
    
    func updateRightButton(_ isEnable: Bool) {
        if let button = self.navigationItem.rightBarButtonItem?.customView as? UIButton {
            button.isEnabled = isEnable
        }
    }
    
    //MARK: - handle button right
    @objc func didSelectedRightButton(_ sender: UIBarButtonItem) -> Void {
        guard hasImageFillAllFrame() == true else {
            return
        }
        
        if let viewHint = self.viewHint {
            viewHint.removeFromSuperview()
        }
        
        // capture full image and push to tag editor view
        capturePhotoPost()
        sender.recordAction(
            .Tap,
            sourceRef: "Next",
            sourceType: .Button,
            targetRef: "Editor-ProductTag",
            targetType: .View)
    }
    
    func capturePhotoPost() {
        for touchBaseView in self.touchBaseViews {
            touchBaseView.buttonAdd.isHidden = true
        }
        for productView in self.productTagViews {
            productView.isHidden = true
        }
        // captrure photo
        let finalPhotoSize = CGSize(width: ImageMaxWidth, height: ImageMaxWidth)
        UIGraphicsBeginImageContextWithOptions(finalPhotoSize, false, 0)
        self.photoFrameView.drawHierarchy(in: CGRect(x: 0, y: 0, width: finalPhotoSize.width, height: finalPhotoSize.height), afterScreenUpdates: true)
        self.photoFrameView.layer.borderWidth = 0.0
        let imageCapture = UIGraphicsGetImageFromCurrentImageContext()
        UIGraphicsEndImageContext()
        //self.hideTagThatOutOfCurrentSelectedFrameLayout()
        let createOutfit = CreateOutfitViewController()
        createOutfit.currentStage = StageMode.secondStage
        createOutfit.imageCrop = imageCapture!
        createOutfit.productTagViews = self.productTagViews
        createOutfit.isFrom = isFromPDP
        createOutfit.selectedHashTag = self.selectedHashTag
        createOutfit.figureChoose = false
        var imagesList = [Images]()
        var tagList = [ImagesTags]()
        let images = Images()
        for post in self.postCreateDataList{
            images.upImage = post.processedImage

//            let images = Images()
//            images.upImage = post.processedImage
            
            if let tags = post.tags {
                for tag in tags {
                    tagList.append(tag)
                }
            }
//            imagesList.append(images)

        }
        images.tags = tagList
        imagesList.append(images)
        createOutfit.images = imagesList
        self.navigationController?.pushViewController(createOutfit, animated: true)
    }
    
    //    // hide tag that out of the current selected frame layout count
    //    func hideTagThatOutOfCurrentSelectedFrameLayout() {
    //        let frameCount = self.photoFrameView.subviews.count
    //        for i in 0 ..< self.allTagList.count {
    //            self.allTagList[i].shouleBeHidden = (self.allTagList[i].photoFrameIndex >= frameCount)
    //        }
    //    }
    
    func showActionSheet(_ sender: Any) {
        self.navigationController?.popViewController(animated: true)
    }
    
    func setPhotoForSubFrame(_ photo: UIImage, subFrameIndex: Int) {
        for touchBaseView in self.touchBaseViews {
            if touchBaseView.tag == subFrameIndex {
                // remove previous image's tag
                touchBaseView.touchImageView.image = photo
                touchBaseView.buttonAdd.isHidden = touchBaseView.touchImageView.image != nil
                break
            }
        }
        self.hasImageFillAllFrame()
    }
    
    func setImageForSubFrame(_ image: UIImage, mode: ModeTagProduct, subFrameIndex: Int, sku : Sku? = nil, uniqueId: String?) {
        for touchBaseView in self.touchBaseViews {
            if touchBaseView.tag == subFrameIndex {
                touchBaseView.touchImageView.setupDataByImageCrop(image)
                touchBaseView.buttonAdd.isHidden = true
                break
            }
        }
        for postCreateData in self.postCreateDataList {
            if postCreateData.uniqueId == uniqueId {
                postCreateData.fullImage = image
                break;
            }
        }
        self.hasImageFillAllFrame()
    }
    
    func didSelectedItemForTag(_ postCreateData: PostCreateData, mode: ModeTagProduct) {
        if let sku = postCreateData.skus?.first {
            if !self.checkTagExistence(sku.skuId, tags: self.productTagViews, point: lastPositionTap) {
                  addTagProduct(sku.price(), oldPrice: sku.priceSale, newPrice: sku.priceRetail, logo: sku.brandImage, skuId: sku.skuId, mode : mode, sku: sku,tagStyle:.Commodity,title: sku.brandName)
            }
        }
    }
    

    func addTagProduct(_ price: Double, oldPrice: Double, newPrice: Double, logo: String, skuId: Int, mode: ModeTagProduct, sku : Sku? = nil,tagStyle:ProductTagStyle? = nil,title:String? = nil,tagImage:String? = nil,brand:Brand? = nil){
        let tag = ProductTagView(position: lastPositionTap, price: price, parentTag: self.selectedIndex, delegate: self, oldPrice: oldPrice, newPrice: newPrice, logoImage: UIImage(named: "logo6")!, logo: logo, tagImageSize: self.photoFrameView.frame.size, skuId: skuId, place : .undefined,tagStyle:tagStyle)
        let postData = postCreateDataList[selectedIndex]
        if let sku = sku {
            sku.positionX = Int(lastPositionTap.x)
            sku.positionY = Int(lastPositionTap.y)
            tag.fillPriceByCartItem(sku)
            tag.sku = sku
            tag.skuName = sku.skuName
            tag.tagImage = sku.productImage
            if postCreateDataList.count > self.selectedIndex {
                postData.addSku(sku)
            }
        }
        tag.photoFrameIndex = self.selectedIndex
        
        tag.productMode = mode
        tag.mode = .edit
        tag.isAddedManually = true
        
        let imageTage = ImagesTags()
        imageTage.positionX = Int(lastPositionTap.x)
        imageTage.positionY = Int(lastPositionTap.y)
        imageTage.place = .undefined
        imageTage.id = skuId
        if title != nil {
            imageTage.title = title!
            tag.title = title!
            if let sku = sku {
                tag.tagTitle = sku.skuName
                imageTage.tagTitle = sku.skuName
            }else{
                tag.tagTitle = title!
                imageTage.tagTitle = title!
            }
            
        }
        if tagStyle != nil {
            imageTage.postTag = tagStyle!
        }
        if tagImage != nil{
            tag.tagImage = tagImage!
            imageTage.tagImage = tagImage!
        }
        if let sku = sku {
            imageTage.tagImage = sku.productImage
        }
        if sku != nil {
            let tagPercent = ProductTagView.getTapPercentage(CGPoint(x: imageTage.positionX, y: imageTage.positionY))
            sku!.positionX = tagPercent.x
            sku!.positionY = tagPercent.y
            imageTage.sku = sku!
        }
        if brand != nil {
            let tagPercent = ProductTagView.getTapPercentage(CGPoint(x: imageTage.positionX, y: imageTage.positionY))
            brand!.positionX = tagPercent.x
            brand!.positionY = tagPercent.y
            imageTage.brand = brand!
        }
        postData.addTag(tag: imageTage)
        
        if let count = postData.tags?.count{
            if count > 0{
                tag.tag = count - 1
            }
        }
        
        self.photoFrameView.addSubview(tag)
        self.productTagViews.append(tag)
        
        
    }
    
    func getImageForTagProduct(_ sku: Sku?, mode: ModeTagProduct, index: Int, uniqueId: String) {
        for touchBaseView in self.touchBaseViews {
            if touchBaseView.tag == index {
                var imageString = ""
                if let sku = sku {
                    // remove previous image's tag
                    imageString = sku.productImage
                    guard imageString.length > 0 else {
                        return
                    }
                    getImage(imageString, mode: mode, view: touchBaseView, sku: sku, uniqueId: uniqueId)
                    touchBaseView.buttonAdd.isHidden = true
                }
                break
            }
        }
    }
    
    /**
     get sku correct by selected color id
     - parameter colorId: colorId selected
     - parameter style:   selected
     - returns: image string key
     */
    func getSkueImageCorrectByColorId(_ skuId: Int, style: Style) -> String {
        let sku = style.findSkuBySkuId(skuId)
        if let key = sku?.imageDefault, !key.isEmpty {
            return key
        }
        if let key = style.defaultSku()?.imageDefault, !key.isEmpty {
            return key
        }
        return style.imageDefault
    }
    
    func getImage(_ imageString: String, mode: ModeTagProduct, view: TouchBaseView, sku : Sku? = nil, uniqueId: String?) {
        view.showLoading()
        
        KingfisherManager.shared.retrieveImage(with: ImageURLFactory.URLSize1000(imageString), options: nil, progressBlock: nil, completionHandler: {[weak self] (image, error, cacheType, imageURL) -> () in
            
            if let dimage = image {
                if let strongSelf = self {
                    if view.superview == nil {
                        strongSelf.layoutFrameAndImage(strongSelf.selectedFrameIndex)
                    } else {
                        if let sku = sku {
                            strongSelf.setImageForSubFrame(dimage, mode: mode, subFrameIndex: view.tag, sku : sku, uniqueId: uniqueId)
                        }
                    }
                }
            }
            view.hideLoading()
        })
    }
    
    func swapTwoFrame(_ intersectedFrameIndex : Int, selfIndex: Int){
        
        if intersectedFrameIndex < self.postCreateDataList.count && selfIndex < self.postCreateDataList.count {
            for productTagView in self.productTagViews {
                if productTagView.tag == intersectedFrameIndex || productTagView.tag == selfIndex {
                    productTagView.removeFromSuperview()
                }
            }
            
            for touchBaseView in self.touchBaseViews {
                if touchBaseView.tag == selfIndex {
                    self.postCreateDataList[intersectedFrameIndex].refreshData(touchBaseView.frame, index: touchBaseView.tag)
                    self.productTagViews = self.productTagViews.filter({$0.tag != selfIndex})
                    
                } else if touchBaseView.tag == intersectedFrameIndex {
                    self.postCreateDataList[selfIndex].refreshData(touchBaseView.frame, index: touchBaseView.tag)
                    self.productTagViews = self.productTagViews.filter({$0.tag != intersectedFrameIndex})
                }
            }
            self.postCreateDataList.swapAt(selfIndex, intersectedFrameIndex)
            let intersectedProductTagViews = self.generateProductTagViewsFromSkus(self.postCreateDataList[intersectedFrameIndex].tags, frameIndex: intersectedFrameIndex)
            self.productTagViews.append(contentsOf: intersectedProductTagViews)
            
            let selfProductTagViews = self.generateProductTagViewsFromSkus(self.postCreateDataList[intersectedFrameIndex].tags, frameIndex: selfIndex)
            self.productTagViews.append(contentsOf: selfProductTagViews)
            self.renderTagProduct()
        }
        
        let image: UIImage? = self.touchBaseViews[selfIndex].touchImageView.image
        self.touchBaseViews[selfIndex].setBaseImage(self.touchBaseViews[intersectedFrameIndex].touchImageView.image)
        self.touchBaseViews[intersectedFrameIndex].setBaseImage(image)
    }
    
    // MARK: - TouchBaseViewDelegate Method
    func intersectOnFrameIndex(_ intersectedFrameIndex : Int, selfIndex: Int) {
        guard intersectedFrameIndex >= 0 && selfIndex >= 0 else {
            return
        }
        self.swapTwoFrame(intersectedFrameIndex, selfIndex: selfIndex)
    }
    
    func didTapOnImage(_ tapPoint: CGPoint, subFrameIndex: Int) {
        if self.productTagViews.count < NumberTagProductMax {
            selectedIndex = subFrameIndex
            lastPositionTap = tapPoint
            PopManager.sharedInstance.chooseTageType(brandCallback: {
                PushManager.sharedInstance.gotoBrandList(brandCallback: { [weak self] (brand) in
                    if let strongSelf = self {
                        strongSelf.addTagProduct(0, oldPrice: 0, newPrice: 0, logo: "", skuId: brand.brandId, mode : .wishlist,tagStyle: .Brand,title:brand.brandName,tagImage:brand.smallLogoImage,brand:brand)
                        
                    }
                })
            }) {
                self.present(MmNavigationController(rootViewController: TagProductSelectionViewController(object: self)), animated: true, completion: nil)
            }
        }
        let postData = self.postCreateDataList[selectedIndex]
        self.view.initAnalytics(withViewKey: self.analyticsViewRecord.viewKey)
        let imageKey =  (postData.photo != nil) ? postData.photo?.photoId : ""
        self.view.recordAction(
            .Tap,
            sourceRef: "\(String(describing: imageKey))",
            sourceType: .Image,
            targetRef: "Editor-ProductTag-Collection",
            targetType: .View)
    }
    
    @objc func didTapOnAddPhotoButton(_ sender: UIButton) {
        self.delegate?.didSelectAddMorePhoto(self.postCreateDataList, templateIndex: selectedFrameIndex, atIndex: sender.tag)
        
        sender.initAnalytics(withViewKey: self.analyticsViewRecord.viewKey)
        sender.recordAction(.Tap, sourceRef: "Add-MoreImage", sourceType: .Button, targetRef: "Editor-Image-Album", targetType: .View)
        
        if let navigationController = self.navigationController {
            for viewController in navigationController.viewControllers {
                if let checkoutViewController = viewController as? CreatePostSelectImageViewController {
                    navigationController.popToViewController(checkoutViewController, animated: true)
                    break
                }
            }
        }
    }
    // Update Tag's photoFrameIndex
    class func updateTagsPhotoFrameIndex(_ tag: ProductTagView, frames: [CGRect]) -> ProductTagView {
        for i in 0 ..< frames.count {
            let thisFrame : CGRect = frames[i] as CGRect
                if thisFrame.contains(tag.finalLocation) {
                    tag.photoFrameIndex = i
                }
        }
        return tag
    }
    
    func didUpdateImage(){
        
    }
    
    func didFinishDraggingImage(_ subFrameIndex: Int) {
        let postData = self.postCreateDataList[subFrameIndex]
        self.view.initAnalytics(withViewKey: self.analyticsViewRecord.viewKey)
        let imageKey =  (postData.photo != nil) ? postData.photo?.photoId : ""
        self.view.recordAction(
            .Drag,
            sourceRef: "\(String(describing: imageKey))",
            sourceType: .Product,
            targetRef: "Editor-ProductTag",
            targetType: .View)
    }
    
    // delegate remove image
    func initAnalyticLog(){
        let user = Context.getUserProfile()
        let authorType = user.userTypeString()
        initAnalyticsViewRecord(
            user.userKey,
            authorType: authorType,
            viewLocation: "Editor-Image",
            viewType: "Post"
        )
    }
    
    func renderTagProduct(_ isNeedRefreshTag: Bool = false) {
        if(isNeedRefreshTag) {
            self.refreshAllTag()
        }
        for productTagView in self.productTagViews {
            if !productTagView.shouleBeHidden {
                photoFrameView.addSubview(productTagView)
            }
        }
    }
    
    func checkTagExistenceOnScreen(_ productTagView: ProductTagView) -> Bool {
        var found = false
        for item in photoFrameView.subviews {
            if let tag = item as? ProductTagView {
                if tag.sku.skuId == productTagView.sku.skuId {
                    found = true
                    break
                }
                
            }
        }
        return found

    }
    
    func removeAllTags(){
        for productTagView in self.productTagViews {
            productTagView.removeFromSuperview()
        }
    }
    
    
    func checkTagExistence(_ skuId: Int, tags: [ProductTagView], point: CGPoint) -> Bool {
        for productTagView in self.productTagViews {
            if productTagView.skuId == skuId {
                productTagView.sku.positionX = Int(point.x)
                productTagView.sku.positionY = Int(point.y)
                productTagView.finalLocation = point
                productTagView.configDirection()
                productTagView.layoutSubviews()
                return true
            }
        }
        return false
    }
    
    //MARK: - TagProduct Delegate
    
    func didSelectedCloseButton(_ tagView: ProductTagView) {
        let optionMenu = UIAlertController(title: nil, message: nil, preferredStyle: .actionSheet)
        let deleteAction = UIAlertAction(title: String.localize("LB_PRODUCT_TAG_DELETION"), style: .default, handler: {
            (alert: UIAlertAction!) -> Void in
            tagView.removeFromSuperview()
            // self.tagArrays.removeObject(tagView)
            if let index = self.productTagViews.index(where: { $0.tag == tagView.tag }) {
                self.productTagViews.remove(at: index)
            }
            
            if tagView.tag >= 0 && tagView.tag < self.postCreateDataList.count {
                let postData = self.postCreateDataList[tagView.tag]
                if let index = postData.skus?.index(where: { $0.skuId == tagView.skuId }) {
                    postData.skus?.remove(at: index)
                }
            }
            
        })
        let cancelAction = UIAlertAction(title:String.localize("LB_CANCEL"), style: .cancel, handler: {
            (alert: UIAlertAction!) -> Void in
            
        })
        optionMenu.addAction(deleteAction)
        optionMenu.addAction(cancelAction)
        self.present(optionMenu, animated: true, completion: nil)
        optionMenu.view.tintColor = UIColor.alertTintColor()
    }
    
    
    func updateTag(_ tag: ProductTagView) {
        for i in 0 ..< self.productTagViews.count {
            if tag.skuId == self.productTagViews[i].skuId {
                self.productTagViews[i] = tag
            }
        }
        
        if tag.tag >= 0  {
            var found = false
            for postData in self.postCreateDataList {
                if postData.subFrame.contains(tag.finalLocation) {
                    if (tag.photoFrameIndex != postData.tag && postData.photo != nil) {
                        found = true
                        break
                    }
                }
            }
            if tag.tag >= 0 {
                
            let postData = self.postCreateDataList[self.selectedIndex]
             
                
            if  postData.tags != nil {
                if tag.tag + 1 > (postData.tags?.count)!{
                    return
                }
                print(tag.tag)
                let tags = postData.tags![tag.tag]
                tags.positionX = Int(tag.finalLocation.x)
                tags.positionY = Int(tag.finalLocation.y)
                tags.place = tag.place
                
                let tagPercent = ProductTagView.getTapPercentage(CGPoint(x: tags.positionX, y: tags.positionY))
                let sku = tags.sku
                let brand = tags.brand
                
                if tags.postTag == .Brand{
                    brand?.positionX = tagPercent.x
                    brand?.positionY = tagPercent.y
                    tags.brand = brand
                }else if tags.postTag == .Commodity{
                    sku?.positionX = tagPercent.x
                    sku?.positionY = tagPercent.y
                    tags.sku = sku
                }
                postData.tags![tag.tag] = tags
                postCreateDataList[self.selectedIndex] = postData
            }
            
            var sku: Sku?
            if let index = postData.skus?.index(where: {$0.skuId == tag.skuId}) {
                sku = postData.skus?[index]
                if found {
                    postData.skus?.remove(at: index)
                    var postCreateData: PostCreateData?
                    for postData in self.postCreateDataList.reversed() {
                        if postData.subFrame.contains(tag.finalLocation) {
                            if let strongSku = sku {
                                strongSku.positionX = Int(tag.finalLocation.x)
                                strongSku.positionY = Int(tag.finalLocation.y)
                                postData.addSku(strongSku)
                                tag.tag = postData.tag
                            }
                            break
                        }
                    }
                    
                    if let strongPostCreateData = postCreateData {
                        if strongPostCreateData.tag < postData.tag {
                            postCreateData = postData
                        }
                    } else {
                        postCreateData = postData
                    }
                    //break should get top view
                } else {
                    if let strongSku = sku {
                        strongSku.positionX = Int(tag.finalLocation.x)
                        strongSku.positionY = Int(tag.finalLocation.y)
                    }
                }
            }
            }
        }
        
        
        tag.layoutSubviews()
        
    }
    
    
    func endMoveTag() {
        self.getProductView().hideProductWithAnimation(true)
    }
    
    func touchDown(_ tag: ProductTagView) {
        self.getProductView().setTagData(name: tag.tagTitle, imageUrl: tag.tagImage, type: tag.productTagStyle)
        self.getProductView().showProductWithAnimation(true)
        Log.debug("toucheDown")
    }
    
    func touchUp(_ tag: ProductTagView) {
        Log.debug("toucheUp")
        self.getProductView().hideProductWithAnimation(true)
    }
    
    func getProductView() -> ProductView {
        if self.productView == nil{
            self.productView = ProductView(frame: CGRect(x: ProductViewMarginLeft, y: 30, width: self.view.width - ProductViewMarginLeft * 2 , height: 48))
        }
        return self.productView!
    }
    
    func generateProductTagViewsFromSkus(_ tags: [ImagesTags]?, frameIndex: Int) -> [ProductTagView]{
        var productTagViews = [ProductTagView]()

//        let sku =  self.postCreateDataList[frameIndex].getSkuList()[0]
//
//        let imagesTag = ImagesTags()
//        imagesTag.positionX = sku.p
//
//        tags?.append(imagesTag)
        if let tags = tags {
            for index in 0..<tags.count {
                let tag = tags[index]
                let productTagView = ProductTagView(position: CGPoint(x: tag.positionX,y:tag.positionY), price: 0, parentTag: frameIndex, delegate: self, oldPrice: 0, newPrice: 0, logoImage: UIImage(named: "logo6")!, logo: "", tagImageSize: self.photoFrameView.size, skuId: tag.id, place : tag.place,tagStyle:tag.postTag)
                productTagView.productMode = .wishlist
                productTagView.title = tag.title
                productTagView.tagImage = tag.tagImage
                productTagView.tagTitle = tag.tagTitle
                productTagView.mode = .edit
                productTagView.photoFrameIndex = frameIndex
                productTagView.tag = index
                productTagViews.append(productTagView)
            }
        }
        return productTagViews
    }
    
}
