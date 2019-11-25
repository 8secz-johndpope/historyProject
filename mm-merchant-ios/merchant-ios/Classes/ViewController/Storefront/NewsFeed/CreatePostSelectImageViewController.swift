//
//  CreatePostSelectImageViewController.swift
//  merchant-ios
//
//  Created by Sang Nguyen on 12/20/16.
//  Copyright © 2016 WWE & CO. All rights reserved.
//

import UIKit
import Photos
import PromiseKit
import Kingfisher

protocol CreatePostProtocol: NSObjectProtocol {
    func getTopViewHeight()-> CGFloat
    func getBottomViewHeight()-> CGFloat
    func didSelectPhoto(_ photo: Photo)
    func didSelectStyle(_ style: Style)
    func didSelectCartItem(_ cartItem: CartItem)
    func didSelectCamera()
    func getSelectedItem() -> [PostCreateData]
    func isEnoughPhoto()-> Bool
    func showErrorFull()
    func didSelectSubCategory()
    func didChangePhotoViewMode(_ photoViewMode: PhotosSelectViewController.PhotoViewMode, albumName: String?)
    
}
enum CreatePostControllerIndex: Int {
    case photosSelectIndex = 0,
    wishListIndex,
    categoryIndex
}
enum PostSelectStyleType: Int {
    case Figure = 0
    case Puzzle = 1
}
class CreatePostSelectImageViewController: MmViewController, UIPageViewControllerDataSource, UIPageViewControllerDelegate, MMSegmentViewDelegate, CreatePostProtocol, ImageCropViewControllerDelegate, GalleryViewControllerDelegate, UIImagePickerControllerDelegate, UINavigationControllerDelegate, PhotoSelectedViewCellDelegate, NewPhotoCollageDelegate {
    private final let PhotoSelectedViewCellId = "PhotoSelectedViewCellId"
    private final let TabHeight : CGFloat = 44 + ScreenBottom / 2
    private final let Spacing : CGFloat = 10
    private final let CollectionViewHeight : CGFloat = 70 + ScreenBottom / 2
    private final let CellWidth : CGFloat = 60
    private final var MaxPhotoNumber : Int = 5
    private final let PageControllerTag = 111
    private var isDrag = false
    private var isEndDecelerating = false
    private final var nextIndex = 0
    private final var previousIndex = 0
    private var segmentView: MMSegmentView!
    private final var pageController: UIPageViewController!
    private var viewControllers = [MmViewController]()

    private var postCreateDataList = [PostCreateData]()
    private var templateCreateDataList: [PostCreateData]?
    private var templateIndexToAdd: Int?
    private let picker = UIImagePickerController()
    
    private var animatedCellIndex : Int = 0
    private var templateIndex: Int?
    private var viewTitle: UILabel?
    private var titleImage: UIImageView?

    var canTapNavBar = true
    var selectedStyles = [Style]()
    let categoryViewController = CategoryViewController()
    var selectedIndex: CreatePostControllerIndex?
    var selectedHashTag: String? = nil
    var fromMenuSelect = false
    var selectStyleType:PostSelectStyleType?
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        if let selectStyleType = selectStyleType{
            if selectStyleType == .Figure{
                MaxPhotoNumber = 12
            }else if selectStyleType == .Puzzle{
                MaxPhotoNumber = 5
            }
        }
        
        super.pageAccessibilityId = "CreatePostSelectImagePage"
        self.setupSegmentView()
        self.setupCollectionView()
        self.setupTitleView()
        
        self.setupPageViewController()
        self.createBackButton(.crossSmall)
        
        
        self.createRightButton()
        self.picker.delegate = self
        
        CacheManager.sharedManager.photoFrames = [PhotoFrame]()
        CacheManager.sharedManager.postDescription = nil
    }

    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        self.reloadData()
    }
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    // MARK: - Navigation
    
    func setupTitleView() {
        
        guard let navigationController = self.navigationController else { return }
        
        let navigationTitleView = UIView(frame: CGRect(x: 0, y: 0, width: (navigationController.navigationBar.frame.size.width) / 3, height: (navigationController.navigationBar.frame.size.height) / 2))
        self.titleImage = UIImageView(image: UIImage(named: "arrow_close"))
        guard let titleImage = self.titleImage else { return }
        let viewTitle = UILabel(frame: CGRect(x: 0, y: 0, width: navigationTitleView.frame.size.width - titleImage.frame.size.width, height: (navigationController.navigationBar.frame.size.height) / 2))
        
        titleImage.frame = CGRect(x: viewTitle.frame.sizeWidth * 0.75 + 4, y: 8, width: 9, height: 7)
        
        navigationTitleView.addSubview(viewTitle)
        navigationTitleView.addSubview(titleImage)
        
        
        viewTitle.textColor = UIColor.secondary1()
        viewTitle.formatSize(16)
        viewTitle.minimumScaleFactor = 0.5
        viewTitle.adjustsFontSizeToFitWidth = true
        viewTitle.textAlignment = .center
        viewTitle.numberOfLines = 1
        viewTitle.isUserInteractionEnabled = true
        let tapGesture = UITapGestureRecognizer(target: self, action: #selector(self.navigationTitlePressed))
        navigationTitleView.addGestureRecognizer(tapGesture)
        

        
        self.navigationItem.titleView = navigationTitleView
        self.viewTitle = viewTitle
        
        if self.selectedStyles.count > 0 || self.selectedIndex == .categoryIndex {
            viewTitle.text = String.localize("LB_CA_CATEGORY")
        } else if self.selectedIndex == .wishListIndex{
            viewTitle.text = String.localize("LB_CA_MY_COLLECTION")
        } else {
            viewTitle.text = String.localize("LB_CA_PHOTO_ALBUM")
        }
        
        positionTitleView()
    }
    
    func positionTitleView() {
        viewTitle?.sizeToFit()
        viewTitle?.center = CGPoint(x: (viewTitle?.superview?.bounds.width ?? 0) / 2 , y: (viewTitle?.superview?.bounds.height ?? 0) / 2 )
        titleImage?.x = viewTitle!.frame.maxX + 4
    }
    
    func setupCollectionView(){
        self.collectionView.register(PhotoSelectedViewCell.self, forCellWithReuseIdentifier: PhotoSelectedViewCellId)
        self.collectionView.frame = CGRect(x: 0, y: self.view.height - (CollectionViewHeight + TabHeight) , width: self.view.width, height: CollectionViewHeight )
        self.collectionView.isHidden = true
        self.collectionView.alwaysBounceHorizontal = true
        self.collectionView.alwaysBounceVertical = false
        self.collectionView.showsHorizontalScrollIndicator = false
        self.collectionView.backgroundColor = UIColor.secondary2()
    }
    
    override func getCustomFlowLayout() -> UICollectionViewFlowLayout {
        let layout = UICollectionViewFlowLayout()
        layout.scrollDirection = UICollectionViewScrollDirection.horizontal
        return layout
    }
    func setupPageViewController() {
        let photosSelectViewController = PhotosSelectViewController()
        photosSelectViewController.delegate = self
        photosSelectViewController.view.tag = CreatePostControllerIndex.photosSelectIndex.rawValue
        viewControllers.append(photosSelectViewController)
        
        let wishListViewControlller = WishListViewController()
        wishListViewControlller.delegate = self
        wishListViewControlller.view.tag = CreatePostControllerIndex.wishListIndex.rawValue
        viewControllers.append(wishListViewControlller)
        
        
        categoryViewController.delegate = self
        
        if selectedStyles.count > 0 {
            selectedIndex = .photosSelectIndex
            categoryViewController.styles = selectedStyles
            for style in selectedStyles {
                self.addPostDataList(PostCreateData(style: style, itemType: .category))
            }
        }
        
        categoryViewController.view.tag = CreatePostControllerIndex.categoryIndex.rawValue
        viewControllers.append(categoryViewController)
        
        pageController = UIPageViewController(transitionStyle: .scroll, navigationOrientation: .horizontal, options: nil)
        pageController.dataSource = self
        pageController.delegate = self
    
        let height = self.view.frame.maxY - TabHeight
        pageController.view.frame = CGRect(x: 0, y: 0, width: Constants.ScreenSize.SCREEN_WIDTH, height: height)
        for view in pageController.view.subviews {
            if let scrollview = view as? UIScrollView {
                scrollview.delegate = self
                scrollview.tag = PageControllerTag
                break
            }
        }
        if let index = self.selectedIndex {
            pageController.setViewControllers([viewControllers[index.rawValue]], direction: .forward, animated: false, completion: nil)
            self.selectItemAtIndex(index.rawValue)
        }else {
            pageController.setViewControllers([viewControllers[0]], direction: .forward, animated: false, completion: nil)
        }
        self.addChildViewController(pageController)
        view.addSubview(pageController.view)
        pageController.didMove(toParentViewController: self)
        
        if selectedStyles.count > 0 {
            didClickRightBarButton(nil)
        }
    }

    func setupSegmentView() {
        segmentView = MMSegmentView(frame: CGRect(x: 0, y: self.view.frame.height - TabHeight , width: self.view.bounds.width , height: TabHeight ), tabs: [String.localize("LB_CA_ALBUM"),String.localize("LB_CA_MY_COLLECTION"),String.localize("LB_CA_CATEGORY")])
        segmentView.delegate = self
        segmentView.setIndicatorColor(UIColor.clear)
        segmentView.setTabColor(selectedColor: UIColor.secondary2(), unSelectedColor: UIColor.secondary14())
        
        segmentView.subCatCollectionView.isScrollEnabled = false
        self.view.addSubview(segmentView)
        segmentView.refreshUI()
    }

    // MARK: - UIScrollView Delegate
    
    func scrollViewDidScroll(_ scrollView: UIScrollView) {
        if scrollView.tag == PageControllerTag {
            if isDrag {
                segmentView.scrollDidScroll(scrollView.contentOffset.x)
            }
            
            if scrollView.contentOffset.x == Constants.ScreenSize.SCREEN_WIDTH && isEndDecelerating {
                segmentView.updateIndicatorLayer()
                isDrag = false
            }
        }
    }
    
    func scrollViewWillBeginDragging(_ scrollView: UIScrollView) {
        if scrollView.tag == PageControllerTag {
            isEndDecelerating = false
            isDrag = true
        }
    }
    
    func scrollViewWillBeginDecelerating(_ scrollView: UIScrollView) {
        if scrollView.tag == PageControllerTag {
            isEndDecelerating = true
        }
    }

    func showPageByCurrentSelectedSegmentIndex(_ animated: Bool, tabIndex: Int) {
        var direction = UIPageViewControllerNavigationDirection.reverse
        
        if previousIndex < tabIndex {
            direction = .forward
        }
        
        if tabIndex >= 0 && tabIndex < viewControllers.count {
            let controller = viewControllers[tabIndex]
            pageController.setViewControllers([controller], direction: direction, animated: animated, completion: nil)
        } else {
            ErrorLogManager.sharedManager.recordNonFatalError(withException: .NullPointerOrTypeMismatch)
        }
        
        previousIndex = tabIndex
    }
    
    //MARK: PageViewController DataSource
    
    func pageViewController(_ pageViewController: UIPageViewController, viewControllerBefore viewController: UIViewController) -> UIViewController? {
        if let controller = viewController as? MmViewController {
            if controller.view.tag == 0 {
                return nil
            } else {
                let preViewController = viewControllers[controller.view.tag - 1]
                return preViewController
            }
        } else {
            ErrorLogManager.sharedManager.recordNonFatalError(withException: .NullPointerOrTypeMismatch)
        }
        
        return nil
    }
    
    func pageViewController(_ pageViewController: UIPageViewController, viewControllerAfter viewController: UIViewController) -> UIViewController? {
        if let controller = viewController as? MmViewController {
            if controller.view.tag >= viewControllers.count - 1 {
                return nil
            } else {
                let nextViewController = viewControllers[controller.view.tag + 1]
                return nextViewController
            }
        } else {
            ErrorLogManager.sharedManager.recordNonFatalError(withException: .NullPointerOrTypeMismatch)
        }
        
        return nil
    }
    
    // MARK: PageViewController Delegate
    
    func pageViewController(_ pageViewController: UIPageViewController, willTransitionTo pendingViewControllers: [UIViewController]) {
        
    }
    
    func pageViewController(_ pageViewController: UIPageViewController, didFinishAnimating finished: Bool, previousViewControllers: [UIViewController], transitionCompleted completed: Bool) {
        guard completed else { return }
        
        if let currentPage = pageViewController.viewControllers?[0] as? MmViewController  {
            selectItemAtIndex(currentPage.view.tag)
        } else {
            ErrorLogManager.sharedManager.recordNonFatalError(withException: .NullPointerOrTypeMismatch)
        }
    }
    
    func selectItemAtIndex(_ index: Int){
        if index < 0 {
            return
        }
        
        if index >= viewControllers.count {
            return
        }
        
        nextIndex = index
        segmentView.setSelectedTab(index)
        self.titleImage?.isHidden = true
        if index == 1 {
            self.viewTitle?.text = String.localize("LB_CA_MY_COLLECTION")
            self.createBackButton(.crossSmall)
        } else if index == 2 {
            self.viewTitle?.text = String.localize("LB_CA_CATEGORY")
            if let viewController = self.pageController.viewControllers?[0] as? CategoryViewController {
                self.createBackButton(viewController.isShowStyleList ? .grayColor : .crossSmall)
            }
        } else {
            if let viewController = self.pageController.viewControllers?[0] as? PhotosSelectViewController {
                self.updateTitleImage(viewController.photoViewMode, albumName: viewController.currentAlbumName)
            }
            if let _ = self.pageController.viewControllers?[0] as? PhotosSelectViewController {
                self.titleImage?.isHidden = false
            }
            self.createBackButton(.crossSmall)
         }
        positionTitleView()
    }

    //MARK: MMSegmentViewDelegate
    func didSelectTabAtIndex(_ tabIndex: Int) {
        showPageByCurrentSelectedSegmentIndex(true, tabIndex: tabIndex)
        self.selectItemAtIndex(tabIndex)
    }

    override func backButtonClicked(_ button: UIButton) {
        if let categoryController = viewControllers[CreatePostControllerIndex.categoryIndex.rawValue] as? CategoryViewController {
            if categoryController.isShowStyleList {
                if let controllers = self.pageController.viewControllers, (controllers.count > 0 && controllers[0] is CategoryViewController) {//Handle back button in case come from PDP/PLP
                    categoryController.isShowStyleList = false
                    categoryController.refreshUI()
                    if selectedStyles.count > 0 {
                        categoryController.feedCategory()
                    }
                    self.createBackButton(.crossSmall)
                    return
                }
            }
        }
        self.dismiss(animated: true, completion: nil)
    }
    
    private func fetchFullImages(_ postDataList: [PostCreateData]) -> Promise<[PostCreateData]> {
        
        return Promise { fulfill, reject in
            
            background_async {
                for i in 0 ..< postDataList.count {
                    if let item = postDataList[i].photo {
                        if let asset = item.asset {
                            self.getFullImage(asset, complete: { (image) in
                                item.fullImage = image
                                }, error:{ info in
                                    
                                    var errorDomain = ""
                                    if let info = info {
                                        errorDomain = info.description
                                    }
                                    let error = NSError(domain: errorDomain, code: 0, userInfo: nil)
                                    reject(error)
                                    return
                            })
                        }
                    }
                }
                
                main_async {
                    fulfill(postDataList)
                }
            }
            
        }
    }
    
    private func fetchProductFullImages(_ postDataList: [PostCreateData]) -> Promise<[PostCreateData]> {
        var promise = [Promise<PostCreateData>]()
        for data in postDataList {
            if data.itemType == .wishlist || data.itemType == .category {
                promise.append(
                    Promise { fulfill, reject in
                        
                        KingfisherManager.shared.retrieveImage(with: ImageURLFactory.URLSize1000(data.defaultProductImage), options: nil, progressBlock: nil, completionHandler: { (image, error, cacheType, imageURL) -> () in
                            data.fullImage = image
                            fulfill(data)
                        })
                        
                    }
                )
            } else {
                promise.append(
                    Promise { fulfill, reject in
                        fulfill(data)
                    }
                )
            }
        }
        
        return when(fulfilled: promise)
    
    }
    
    @objc func didClickRightBarButton(_ button: UIButton?){
        let postFilterViewController = PostFilterAndBeautyViewController(nibName: "PostFilterAndBeautyViewController", bundle: nil)
        
        
        if self.postCreateDataList.count > 0 {
            
            self.showLoading()
            
            firstly {
                
                //获取完整图像
                return fetchFullImages(postCreateDataList)
                
                }
                .then { (postDataList) -> Promise<[PostCreateData]> in
                    
                    //获取完整图像
                    return self.fetchProductFullImages(postDataList)
                    
                }
                .then { [weak self] (postDataList) -> Void in
                    
                    if let strongSelf = self {
                        strongSelf.stopLoading()
                        
                        //赋值
                        strongSelf.postCreateDataList = postDataList
 
                        postFilterViewController.delegate = strongSelf
                        postFilterViewController.selectedHashTag = strongSelf.selectedHashTag
                        postFilterViewController.templateIndex = strongSelf.templateIndex
                        postFilterViewController.postCreateDataList = strongSelf.postCreateDataList
                        postFilterViewController.templateCreateDataList = strongSelf.templateCreateDataList
                        if strongSelf.selectStyleType == .Figure{
                            postFilterViewController.figureChoose = true
                        }else if strongSelf.selectStyleType == .Puzzle{
                            postFilterViewController.figureChoose = false
                        }
                        strongSelf.navigationController?.pushViewController(postFilterViewController, animated: button != nil)
                    }
                    
                }
                .catch { _ -> Void in
                    self.stopLoading()
                    self.showErrorAlert(String.localize("MSG_ERR_NETWORK_FAIL"))
                }
        }
    }
    
    func createRightButton() {
        var title = String.localize(String.localize("LB_CA_CONTINUE"))
        var isEnable = false
        if self.postCreateDataList.count > 0 {
            title = "\(self.postCreateDataList.count) " + title
            isEnable = true
        }
        let rightButton = UIButton(type: UIButtonType.system)
        rightButton.setTitle(title, for: UIControlState())
        rightButton.titleLabel?.formatSize(14)
        rightButton.setTitleColor( UIColor.white, for: UIControlState())
        if isEnable {
            rightButton.backgroundColor = UIColor.primary1()
        } else {
            rightButton.backgroundColor = UIColor.secondary1()
        }
        rightButton.layer.cornerRadius = 3
        let constraintRect = CGSize(width: CGFloat.greatestFiniteMagnitude, height: Constants.Value.BackButtonHeight)
        let boundingBox = title.boundingRect(with: constraintRect, options: NSStringDrawingOptions.usesLineFragmentOrigin, attributes: [NSAttributedStringKey.font: rightButton.titleLabel!.font], context: nil)
        rightButton.frame = CGRect(x: 0, y: 0, width: boundingBox.width + 10, height: Constants.Value.BackButtonHeight)
        rightButton.addTarget(self, action: #selector(self.didClickRightBarButton), for: UIControlEvents.touchUpInside)
        self.navigationItem.rightBarButtonItem = UIBarButtonItem(customView: rightButton)
        self.setAccessibilityIdForView("UIBT_CA_CONTINUE", view: rightButton)
    }
    
    //MARK: - CreatePostProtocol
    func getTopViewHeight()-> CGFloat {
        return (self.navigationController?.navigationBar.frame.size.height) ?? 0
    }
    
    func getBottomViewHeight()-> CGFloat {
        return (self.collectionView.isHidden ? TabHeight : CollectionViewHeight + TabHeight)
    }
    
    func didSelectPhoto(_ photo: Photo) {
        if let viewController = self.pageController.viewControllers?[0] as? PhotosSelectViewController {
            if viewController.isSelectedPhoto(photo.asset) {
                if self.postCreateDataList.count >= MaxPhotoNumber {
                    return
                }
                self.animatedCellIndex = self.postCreateDataList.count
                let postCreateData = PostCreateData(photo: photo, itemType: .album)
                self.addPostDataList(postCreateData)
            } else {
                for i in 0..<self.postCreateDataList.count {
                    if let item = self.postCreateDataList[i].photo {
                        if let assetItem = item.asset, let assetPhoto = photo.asset, assetItem.localIdentifier == assetPhoto.localIdentifier {
                            let postRemoving = self.postCreateDataList[i]
                            self.removePostDataList(postRemoving)
                            break
                        }
                    }
                }
            }
            self.reloadData()
        }
    }
    
    func didSelectCamera(){
        self.openCamera()
    }
    
    func didSelectStyle(_ style: Style) {
        if style.selected {
            self.animatedCellIndex = self.postCreateDataList.count
            let postCreateData = PostCreateData(style: style, itemType: .category)
            self.addPostDataList(postCreateData)
        } else {
            for i in 0..<self.postCreateDataList.count {
                if self.postCreateDataList[i].itemType == .category {
                    if let skuId = self.postCreateDataList[i].defaultSkuId {
                        if skuId == style.defaultSku()?.skuId {
                            let postRemoving = self.postCreateDataList[i]
                            self.removePostDataList(postRemoving)
                            break
                        }
                    }
                }
            }
        }
        
        self.reloadData()
    }
    
    
    func didSelectCartItem(_ cartItem: CartItem) {
        if cartItem.isSelected {
            self.animatedCellIndex = self.postCreateDataList.count
            let postCreateData = PostCreateData(cartItem: cartItem, itemType: .wishlist)
            self.addPostDataList(postCreateData)
        } else {
            for i in 0..<self.postCreateDataList.count {
                if let skuId = self.postCreateDataList[i].defaultSkuId {
                    if skuId == cartItem.skuId {
                        let postRemoving = self.postCreateDataList[i]
                        self.removePostDataList(postRemoving)
                        break
                    }
                }
            }
        }
        
        self.reloadData()
    }
    
    func getSelectedItem() ->  [PostCreateData] {
        return self.postCreateDataList
    }
    
    func isEnoughPhoto() -> Bool {
        return self.postCreateDataList.count >= MaxPhotoNumber
    }
    
    func showErrorFull() {
        var message = String.localize("LB_CA_MAX_PHOTO_PDT_SELECTION")
        if selectStyleType == .Figure {
            message = String.localize("最多12个选择")
        }else if selectStyleType == .Puzzle{
            message = String.localize("LB_CA_MAX_PHOTO_PDT_SELECTION")
        }
        
        Alert.alertWithSingleButton(self, title: "", message: message, buttonString: String.localize("LB_OK"))

    }
    
    func didSelectSubCategory() {
        self.createBackButton(.grayColor)
    }
    
    func didBackFromViewController(_ viewController: MmViewController?) {
        if let _ = viewController as? NewPhotoCollageViewController, selectedStyles.count > 0{
            navigationController?.dismiss(animated: true, completion: nil)
        }
    }
    
    func didSelectTemplateIndex(_ templatePhotos: [PostCreateData], templateIndex: Int?) {
        self.templateCreateDataList = templatePhotos
        self.templateIndex = templateIndex
        self.templateIndexToAdd = nil
    }
    
    func didSelectAddMorePhoto(_ templatePhotos: [PostCreateData], templateIndex: Int?, atIndex: Int?) {
        templateCreateDataList = templatePhotos
        self.templateIndex = templateIndex
        self.templateIndexToAdd = atIndex
    }
    
    //MARK: - Post Data Processing
    func addPostDataList(_ postCreateData: PostCreateData) {
        self.postCreateDataList.append(postCreateData)
        if self.templateCreateDataList != nil {
            if let templateIndexToAdd = self.templateIndexToAdd, self.templateCreateDataList!.count > templateIndexToAdd && self.templateCreateDataList![templateIndexToAdd].itemType == .unknown {
                self.templateCreateDataList![templateIndexToAdd] = postCreateData
            } else if let indexPost = self.templateCreateDataList!.index(where: { $0.itemType == .unknown}) {
                self.templateCreateDataList![indexPost] = postCreateData
            }
        }
    }
    
    func removePostDataList(_ postCreateData: PostCreateData) {
        self.postCreateDataList.remove(postCreateData)
        if self.templateCreateDataList != nil {
            if let indexPost = self.templateCreateDataList!.index(where: { $0 == postCreateData}) {
                self.templateCreateDataList![indexPost] = PostCreateData()
            }
        }
    }
    
    func reloadData(){
        let isHiden = self.collectionView.isHidden
        self.collectionView.isHidden = postCreateDataList.count <= 0
        self.collectionView.reloadData()
       
        if isHiden != self.collectionView.isHidden {
            //TODO post notification
            let height = self.view.frame.maxY - (TabHeight + (isHiden ? CollectionViewHeight : 0))
            pageController.view.frame = CGRect(x: 0, y: 0, width: Constants.ScreenSize.SCREEN_WIDTH, height: height)
            NotificationCenter.default.post(name: Constants.Notification.createPostDidUpdatePhoto, object: nil)
        }
        self.createRightButton()
    }
    
    //MARK: - CollectionView Delegate
    override func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return self.postCreateDataList.count
    }
    
    override func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        
        let cell = collectionView.dequeueReusableCell(withReuseIdentifier: PhotoSelectedViewCellId, for: indexPath) as! PhotoSelectedViewCell
        self.setAccessibilityIdForView("UIBT_SELECTED_PIC", view: cell)
       
        let postCreateData = self.postCreateDataList[indexPath.row]
        switch postCreateData.itemType {
        case .album:
            if let photo = postCreateData.photo {
                if let thumb = photo.thumbNail {
                    cell.setImage(thumb)
                }else {
                    
                    let width = (self.view.width - self.Spacing * 2) / 3
                    let imageSize = CGSize(width: width, height: width)
                    
                    photo.getThumbnailByAsset(imageSize, resultHandler: { (image) in
                        if let img = image {
                            cell.setImage(img)
                        }
                    })
                }
                
            }
        case .category, .wishlist:
            cell.setImage(postCreateData.defaultProductImage, category: ImageCategory.product)
            
        default:
            break
        }
        
        cell.removeButton.tag = indexPath.row
        cell.removeButton.addTarget(self, action: #selector(self.didTouchRemoveButton), for: UIControlEvents.touchUpInside)
        if indexPath.row == animatedCellIndex {
            animatedCellIndex = self.postCreateDataList.count
            cell.addAnimation()
        }
        cell.delegate = self
        return cell;
    }
    
    func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
       
    }
    
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, minimumInteritemSpacingForSectionAt section: Int) -> CGFloat {
        return 0.0
    }
    
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, minimumLineSpacingForSectionAt section: Int) -> CGFloat {
        return Spacing
    }
    
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, insetForSectionAt section: Int) -> UIEdgeInsets {
        return UIEdgeInsets(top: 0, left: 15, bottom: 0, right: 15)
    }
    
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, sizeForItemAt indexPath: IndexPath) -> CGSize {
        return CGSize(width: CellWidth, height: CellWidth)
    }
    
    @objc func didTouchRemoveButton(_ button: UIButton){
        let indexPath = IndexPath(row: button.tag, section: 0)
        if let cell = collectionView.cellForItem(at: indexPath) as? PhotoSelectedViewCell {
            cell.removeAnimation(button.tag)
        } else {
            self.removedCellAtIndex(button.tag)
        }
        
    }
    
    //MARK: PhotoSelectedCellDelegate
    func didChangePhotoViewMode(_ photoViewMode: PhotosSelectViewController.PhotoViewMode, albumName: String?) {
        self.updateTitleImage(photoViewMode, albumName: albumName)
    }
    
    func removedCellAtIndex(_ index: Int) {
        if index < self.postCreateDataList.count {
            switch self.postCreateDataList[index].itemType {
            case .album:
                NotificationCenter.default.post(name: Notification.Name(rawValue: "DidRemovePhoto"), object: self.postCreateDataList[index].photo)
            case .category:
                NotificationCenter.default.post(name: Notification.Name(rawValue: "DidRemoveStyle"), object: postCreateDataList[index].defaultSkuId)
            case .wishlist:
                NotificationCenter.default.post(name: Notification.Name(rawValue: "DidRemoveCartItem"), object: postCreateDataList[index].defaultSkuId)
            default:
                break
            }
            
            let postRemoving = self.postCreateDataList[index]
            self.removePostDataList(postRemoving)
            self.reloadData()
        }
    }
    
    //MARK: - Photo Collapse Delegate
    func didChangePhotoFrames(_ array: [PostCreateData]) {
        
        var postCreateDatas = [PostCreateData]()
        for postCreateData in array {
            if postCreateData.itemType != .unknown {
                postCreateDatas.append(postCreateData)
            }
        }
        self.postCreateDataList = postCreateDatas
        self.reloadData()
    }
    
    
    
    //# MARK: - Photo Methods
    
    @objc func navigationTitlePressed() {
        
        guard canTapNavBar else {
            return
        }
        
        canTapNavBar = false
        if let viewController = self.pageController.viewControllers?[0] as? PhotosSelectViewController {
            if viewController.photoViewMode == .listView {
                viewController.photoViewMode = .gridView
                
                viewController.collapseAlbumCollectionViewAnimation({ (success) in
                    self.canTapNavBar = true
                })
            } else {
                viewController.photoViewMode = .listView
                
                //always refresh list of albums
                viewController.fetchData({ (success) in
                    viewController.expandAlbumCollectionViewAnimation({ (success) in
                        if success {
                            self.canTapNavBar = true
                        }
                    })
                    
                })
            }
            self.updateTitleImage(viewController.photoViewMode, albumName: viewController.currentAlbumName)
        }
    }
    
    func updateTitleImage(_ photoViewMode: PhotosSelectViewController.PhotoViewMode, albumName: String? = nil) {
        if photoViewMode == .gridView {
            if let viewTitle = self.viewTitle {
                viewTitle.text = albumName ?? String.localize("LB_CA_PHOTO_ALBUM")
            }
            self.titleImage?.image = UIImage(named: "arrow_close")
        } else {
            if let viewTitle = self.viewTitle {
                viewTitle.text = String.localize("LB_CA_ALBUM")

            }
            self.titleImage?.image = UIImage(named: "arrow_open")
        }
        positionTitleView()

    }
    
    func openCamera(){
        Utils.checkCameraPermissionWithCallBack({[weak self] (granted) in
            if let strongSelf = self, granted {
                if(UIImagePickerController.isSourceTypeAvailable(UIImagePickerControllerSourceType.camera)) {
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
        
        if let image = (info[UIImagePickerControllerOriginalImage] as? UIImage)?.normalizedImage() {
            
            self.imageCropViewControllerSuccess(self, didFinishCroppingImage: image)
            
            if picker.sourceType == .camera {
                CustomAlbumHelper.saveImageToAlbum(image)
            }
            
        }
    }
    
    //MARK: - Image Crop Delegate
    func handleDismisGalleryViewController(_ stage: StageMode) {
        
    }
    
    func imageCropViewControllerSuccess(_ controller: UIViewController!, didFinishCroppingImage croppedImage: UIImage!) {
        
        let photo = Photo(thumbNail: croppedImage)
        photo.fullImage = photo.thumbNail!
        if !isEnoughPhoto(){
            
            self.addPostDataList(PostCreateData(photo: photo, itemType: .album))
            self.reloadData()
        } else {
            showErrorFull()
        }

    }
    
    func imageCropViewControllerDidCancel(_ controller: UIViewController!) {
        
    }

    private func getFullImage(_ asset: PHAsset, complete: ((UIImage)->())? = nil, error: ((NSDictionary?)->())? = nil){
        let imageManager = PHCachingImageManager()
        let imageSize = CGSize(width: CGFloat(asset.pixelWidth), height: CGFloat(asset.pixelHeight))
        let options = PHImageRequestOptions()
        options.deliveryMode = .fastFormat
        options.isSynchronous = true
        options.isNetworkAccessAllowed = true
        imageManager.requestImage(for: asset,
            targetSize: imageSize,
            contentMode: .aspectFill,
            options: options,
            resultHandler: {
                (image, info) -> Void in
                if let strongImage = image {
                    complete?(strongImage)
                } else {
                    error?(info as NSDictionary?)
                }
        })
    }
}
