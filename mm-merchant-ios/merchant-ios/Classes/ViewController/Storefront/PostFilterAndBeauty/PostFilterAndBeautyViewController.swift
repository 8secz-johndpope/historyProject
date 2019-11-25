//
//  PostFilterAndBeautyViewController.swift
//  merchant-ios
//
//  Created by HungPM on 9/12/17.
//  Copyright © 2017 WWE & CO. All rights reserved.
//

import Foundation
import Photos
import PromiseKit

typealias BeautyOption = (key: String, title: String, normalImageName: String, selectImageName: String, selected: Bool,firstSelect:Bool)

typealias TagProductOption = (CGSize)

class PostFilterAndBeautyViewController: MmViewController {
    
    @IBOutlet weak var imageCollectionView: UICollectionView!
    @IBOutlet weak var filterCollectionView: UICollectionView!
    @IBOutlet weak var beautyCollectionView: UICollectionView!
    @IBOutlet weak var pageControl: UIPageControl!
    @IBOutlet weak var viewFilter: UIView!
    @IBOutlet weak var viewBeauty: UIView!
    @IBOutlet weak var beautySilder: UISlider!
    @IBOutlet weak var lblFilter: UILabel!
    @IBOutlet weak var lblBeauty: UILabel!
    @IBOutlet weak var imgViewFilter: UIImageView!
    @IBOutlet weak var imgViewBeauty: UIImageView!
    @IBOutlet weak var viewFilterIndicator: UIView!
    @IBOutlet weak var viewBeautyIndicator: UIView!
    var lastPositionTap = CGPoint.zero
    
    private var titleCollectionView: UICollectionView!
    
    private static let PostImageCellID = "PostImageCell"
    private static let PostFilterCellID = "PostFilterCell"
    private static let PostBeautyCellID = "PostBeautyCell"
    private static let TitleFilterAndBeautyCellID = "TitleFilterAndBeautyCell"
    
    private var beautyOptionsDataSource: [BeautyOption]!
    private var filterOptionsDataSource: [MMFilter]!
    private var filterViewKey: String?
    private var beautyViewKey: String?
    private var postImageCell:PostImageCell?
    
    var postCreateDataList = [PostCreateData]()
    var templateCreateDataList: [PostCreateData]?
    weak var delegate : NewPhotoCollageDelegate?
    var selectedHashTag: String? = nil
    var templateIndex : Int?
    var figureChoose = false
    private var productView : ProductView?
    
    lazy var figureButton:UIButton = {
        let figureButton = UIButton()
        figureButton.setImage(UIImage(named: "cut_ic"), for: UIControlState.normal)
        figureButton.sizeToFit()
        figureButton.addTarget(self, action: #selector(goToFigure), for: .touchUpInside)
        return figureButton
    }()
    lazy var productTagView:ProductTagView = {
        let size = CGSize(width: ScreenWidth, height: ScreenWidth)
        let productTagView = ProductTagView(position: CGPoint(x: size.width / 3,y:64 + size.width / 2), price: 0, parentTag: 1, delegate: self, oldPrice: 0, newPrice: 0, logoImage: UIImage(named: "logo6")!, logo: "", tagImageSize: size, skuId: 0, place : TagPlace.right,tagStyle:.Add)
        productTagView.title = "添加商品和品牌标签"
        productTagView.mode = .special
        productTagView.isAddedManually = true
        productTagView.isUserInteractionEnabled = false
        return productTagView
    }()
    
    // MARK:- View life cycle
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        
        if figureChoose {
            if productTagView.alpha == 1 {
                showProductTagView()
            }
        }
    }
    
    func showProductTagView (){
        self.productTagView.alpha = 1
        UIView.animate(withDuration: 1.0, delay: 2.0, options: .curveEaseIn, animations: {
            self.productTagView.alpha = 0
        }) { (success) in
        }
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        
        beautyOptionsDataSource = [
            (key: "reset", title: String.localize("LB_CA_BEAUTIFICATION_RESET"), normalImageName: "beauty_7_off", selectImageName: "beauty_7", selected: false, firstSelect: true),
            (key: "recommend", title: String.localize("LB_CA_ONE_CLICK_BEAUTIFY"), normalImageName: "beauty_1_off", selectImageName: "beauty_1", selected: false, firstSelect: true),
            (key: "smoothing", title: String.localize("LB_CA_BEAUTIFY_SMOOTH"), normalImageName: "beauty_2_off", selectImageName: "beauty_2", selected: false, firstSelect: true), // default selected
            (key: "whitening", title: String.localize("LB_CA_BEAUTIFY_WHITEN"), normalImageName: "beauty_3_off", selectImageName: "beauty_3", selected: false, firstSelect: true),
            (key: "skinColor", title: String.localize("LB_CA_BEAUTIFY_SKIN_TONE"), normalImageName: "beauty_4_off", selectImageName: "beauty_4", selected: false, firstSelect: true),
            (key: "eyeSize", title: String.localize("LB_CA_BEAUTIFY_BIGGER_EYES"), normalImageName: "beauty_5_off", selectImageName: "beauty_5", selected: false, firstSelect: true),
            (key: "chinSize", title: String.localize("LB_CA_BEAUTIFY_FACE_LIFT"), normalImageName: "beauty_6_off", selectImageName: "beauty_6", selected: false, firstSelect: true),
        ]
        
        filterOptionsDataSource = [
            (source: .myMM, filter: "ORIGINAL", title: String.localize("LB_CA_FILTERS_ORIGINAL"),
             normalImageName: "postFilter_1", selectImageName: "postFilter_1"),
            (source: .tuTu, filter: TutuWrapper.Filter.leica.rawValue, title: String.localize("LB_CA_FILTERS_LEICA"),
             normalImageName: "postFilter_2", selectImageName: "postFilter_2"),
            (source: .tuTu, filter: TutuWrapper.Filter.noir.rawValue, title: String.localize("LB_CA_FILTERS_BW"),
             normalImageName: "postFilter_3", selectImageName: "postFilter_3"),
            (source: .tuTu, filter: TutuWrapper.Filter.sweet002.rawValue, title: String.localize("LB_CA_FILTERS_SWEET"),
             normalImageName: "postFilter_4", selectImageName: "postFilter_4"),
            (source: .tuTu, filter: TutuWrapper.Filter.skinRuddy.rawValue, title: String.localize("LB_CA_FILTERS_RUDDY"),
             normalImageName: "postFilter_5", selectImageName: "postFilter_5"),
            (source: .tuTu, filter: TutuWrapper.Filter.tiffany.rawValue, title: String.localize("LB_CA_FILTERS_TIFFANY"),
             normalImageName: "postFilter_6", selectImageName: "postFilter_6"),
            (source: .tuTu, filter: TutuWrapper.Filter.olympus.rawValue, title: String.localize("LB_CA_FILTERS_OLYMPUS"),
             normalImageName: "postFilter_7", selectImageName: "postFilter_7"),
            (source: .tuTu, filter: TutuWrapper.Filter.skinPink.rawValue, title: String.localize("LB_CA_FILTERS_WHITEDELICATE"),
             normalImageName: "postFilter_8", selectImageName: "postFilter_8"),
            (source: .tuTu, filter: TutuWrapper.Filter.nude.rawValue, title: String.localize("LB_CA_FILTERS_NUDE"),
             normalImageName: "postFilter_9", selectImageName: "postFilter_9"),
            (source: .tuTu, filter: TutuWrapper.Filter.bonnie.rawValue, title: String.localize("LB_CA_FILTERS_BONNIE"),
             normalImageName: "postFilter_10", selectImageName: "postFilter_10"),
            (source: .tuTu, filter: TutuWrapper.Filter.modern.rawValue, title: String.localize("LB_CA_FILTERS_MODERN"),
             normalImageName: "postFilter_11", selectImageName: "postFilter_11")
        ]
        
        for i in 0..<postCreateDataList.count {
            let data = postCreateDataList[i]
            data.beautySettings = TutuWrapper.defaultSettings()
            if i == 0 {
                data.isCurrentFilterTarget = true
            }else{
                data.isCurrentFilterTarget = false
            }
            postCreateDataList[i] = data
        }
        
        
        
        setupView()
        setupNavigation()
        setupCollectionView()
        initAnalyticLog()
        
        if figureChoose {
            view.addSubview(productTagView)
        }
    }
    
    
    // MARK:- Analytics
    func initAnalyticLog(_ filterView: Bool = true) {
        let user = Context.getUserProfile()
        var viewLocation: String!
        if filterView {
            viewLocation = "Editor-Image-Filters"
            if filterViewKey == nil {
                filterViewKey = Utils.UUID()
                viewFilter.analyticsViewKey = filterViewKey
            }
            analyticsViewRecord.viewKey = filterViewKey!
            
        }
        else {
            viewLocation = "Editor-Image-Beautifcation"
            if beautyViewKey == nil {
                beautyViewKey = Utils.UUID()
                viewBeauty.analyticsViewKey = beautyViewKey
            }
            analyticsViewRecord.viewKey = beautyViewKey!
        }
        
        analyticsViewRecord.timestamp = Date()
        
        initAnalyticsViewRecord(user.userKey, authorType: user.userTypeString(), viewLocation: viewLocation, viewType: "Post")
    }
    
    // MARK:- Touch Methods
    @objc func goToFigure() {
        let vc = PostFigureViewController()
        let postCreateData =  self.postCreateDataList[self.pageControl.currentPage]
        vc.selectImage = { [weak self](image,selectImageRect) in
            if let strongSelf = self {
                let postData =  strongSelf.postCreateDataList[strongSelf.pageControl.currentPage]
                
                postData.imageRect = selectImageRect
                strongSelf.postCreateDataList[strongSelf.pageControl.currentPage] = postData
                strongSelf.imageCollectionView.reloadData()
                
            }
        }
        vc.sourceImage = postCreateData.processedImage
        self.present(vc, animated: true, completion: nil)
        
    }
    @objc func rightButtonTapped() {
        //是否第一次加载 否
        var resetTagsPositionFirstLoad = false
        
        let nextViewController = NewPhotoCollageViewController()
        nextViewController.delegate = delegate
        nextViewController.selectedHashTag = selectedHashTag
        
        //如果是选中图片数组大于索引数 为第一次加载
        if let templateIndex = self.templateIndex{
            let numberSubFrames: Int = FrameManager.getNumberSubFrameFromFrameIndex(templateIndex)
            if self.postCreateDataList.count > numberSubFrames {
                resetTagsPositionFirstLoad = true
            }
        }
        
        //比较模板图片数组和选中图片数组 传递不同参数
        if let templateCreateDataList = self.templateCreateDataList, templateCreateDataList.count > self.postCreateDataList.count {
            nextViewController.postCreateDataList = templateCreateDataList
            
        } else if let templateCreateDataList = self.templateCreateDataList, templateCreateDataList.count == self.postCreateDataList.count {
            self.templateCreateDataList = self.postCreateDataList
            nextViewController.postCreateDataList = self.postCreateDataList
            
        } else {
            resetTagsPositionFirstLoad = true
            self.templateCreateDataList = self.postCreateDataList
            nextViewController.templateIndex = nil
            nextViewController.postCreateDataList = self.postCreateDataList
            
        }
        nextViewController.resetTagsPositionFirstLoad = resetTagsPositionFirstLoad
        if figureChoose{
            
            let createOutfit = CreateOutfitViewController()
            createOutfit.currentStage = StageMode.secondStage
            let postCreateData =  self.postCreateDataList[0]
            if let imageRect = postCreateData.imageRect{
                createOutfit.imageCrop = (postCreateData.processedImage?.crop(bounds: imageRect))!
            }else{
                createOutfit.imageCrop = postCreateData.processedImage!
            }
            
            createOutfit.isFrom = ModeTagProduct.productListPage
            createOutfit.selectedHashTag = self.selectedHashTag
            createOutfit.figureChoose = true
            
            var imagesList = [Images]()
            for post in self.postCreateDataList{
                
                let images = Images()
                if let imageRect = post.imageRect{
                    images.upImage = post.processedImage?.crop(bounds: imageRect)
                    
                }else{
                    images.upImage = post.processedImage
                }
                
                images.tags = post.tags
                imagesList.append(images)
            }
            createOutfit.images = imagesList
            self.navigationController?.pushViewController(createOutfit, animated: true)
        }else{
            navigationController?.pushViewController(nextViewController, animated: true)
        }
        
        if viewFilter.isHidden {
            viewBeauty.recordAction(.Tap, sourceRef: "Next", sourceType: .Button, targetRef: "Editor-Post", targetType: .View)
        }
        else {
            viewFilter.recordAction(.Tap, sourceRef: "Next", sourceType: .Button, targetRef: "Beautifcation", targetType: .View)
        }
        
    }
    @IBAction func buttonFilterTapped(_ sender: UIButton) {
        guard viewFilter.isHidden else { return }
        
        lblFilter.textColor = UIColor.black
        lblBeauty.textColor = UIColor.secondary2()
        
        imgViewFilter.isHighlighted = true
        imgViewBeauty.isHighlighted = false
        
        viewFilterIndicator.isHidden = false
        viewBeautyIndicator.isHidden = true
        
        viewFilter.isHidden = false
        viewBeauty.isHidden = true
        
        initAnalyticLog()
        AnalyticsManager.sharedManager.recordView(analyticsViewRecord)
        
        viewFilter.recordAction(.Tap, sourceRef: "Filters", sourceType: .Button, targetRef: "Editor-Image-Filters", targetType: .View)
    }
    
    @IBAction func buttonBeautyTapped(_ sender: UIButton) {
        guard viewBeauty.isHidden else { return }
        
        lblFilter.textColor = UIColor.secondary2()
        lblBeauty.textColor = UIColor.black
        
        imgViewFilter.isHighlighted = false
        imgViewBeauty.isHighlighted = true
        
        viewFilterIndicator.isHidden = true
        viewBeautyIndicator.isHidden = false
        
        viewFilter.isHidden = true
        viewBeauty.isHidden = false
        
        initAnalyticLog(false)
        AnalyticsManager.sharedManager.recordView(analyticsViewRecord)
        
        viewBeauty.recordAction(.Tap, sourceRef: "Beautifcation", sourceType: .Button, targetRef: "Editor-Image-Beautifcation", targetType: .View)
    }
    
    @objc func backButton(_ button: UIButton) {
        
        for viewController in (self.navigationController?.viewControllers)! {
            if let checkoutViewController = viewController as? CreatePostSelectImageViewController {
                if checkoutViewController.fromMenuSelect {
                    self.dismiss(animated: false, completion: nil)
                    return
                }
                
            }
        }
        self.navigationController?.popViewController(animated: true)
    }

    override func shouldHaveCollectionView() -> Bool {
        return false
    }
    
    // MARK:- UIScrollViewDelegate
    func scrollViewDidEndDecelerating(_ scrollView: UIScrollView) {
        
        if scrollView == imageCollectionView {
            
            let index = Int(ceil(scrollView.contentOffset.x / scrollView.width))
            
            pageControl.currentPage = index
            
            if index <= postCreateDataList.count - 1{
                updateBeauty(index)
            }
            
        }
    }
    // MARK:- CollectionView
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, insetForSectionAt section: Int) -> UIEdgeInsets {
        
        switch collectionView {
        case filterCollectionView:
            return UIEdgeInsets(top: 0, left: 14, bottom: 0, right: 14)
            
        default:
            //titleCollectionView beautyCollectionView
            return UIEdgeInsets.zero
        }
    }
    
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, minimumLineSpacingForSectionAt section: Int) -> CGFloat {
        switch collectionView {
        case imageCollectionView:
            return 0
            
        case filterCollectionView:
            return 6
            
        case filterCollectionView:
            return 1
            
        default:
            //titleCollectionView
            return 2
        }
        
    }
    
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, minimumInteritemSpacingForSectionAt section: Int) -> CGFloat {
        return 0
    }
    
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, sizeForItemAt indexPath: IndexPath) -> CGSize {
        
        switch collectionView {
        case imageCollectionView:
            return CGSize(width: collectionView.width, height: collectionView.height)
            
        case filterCollectionView:
            return CGSize(width: 84, height: 109)
            
        case beautyCollectionView:
            return CGSize(width: (ScreenWidth - 4)/7 - 1, height: 70)
            
        default:
            //titleCollectionView
            return CGSize(width: 30, height: 30)
        }
    }
    
    override func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        
        switch collectionView {
        case imageCollectionView:
            return postCreateDataList.count
            
        case filterCollectionView:
            return filterOptionsDataSource.count
            
        case beautyCollectionView:
            return beautyOptionsDataSource.count
            
        default:
            //titleCollectionView
            return pageControl.numberOfPages
            
        }
    }
    
    override func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        
        switch collectionView {
        case imageCollectionView:
            let cell = collectionView.dequeueReusableCell(withReuseIdentifier: PostFilterAndBeautyViewController.PostImageCellID, for: indexPath) as! PostImageCell
            let postList = postCreateDataList[indexPath.item]
            cell.model = postList
            if figureChoose {
                let tap = UITapGestureRecognizer(target: self, action: #selector(touchImageCell(_:)))
                cell.addGestureRecognizer(tap)
                
                for view in cell.subviews{
                    if view.isKind(of: ProductTagView.self) {
                        view.removeFromSuperview()
                    }
                    
                }
                if let tags = postList.tags{
                    for index in 0..<tags.count {
                        let tag = tags[index]
                        let productTagView = ProductTagView(position: CGPoint(x: tag.positionX,y:tag.positionY), price: 0, parentTag: 1, delegate: self, oldPrice: 0, newPrice: 0, logoImage: UIImage(named: "logo6")!, logo: "", tagImageSize: cell.size, skuId: tag.id, place : tag.place,tagStyle:tag.postTag)
                        productTagView.productMode = .wishlist
                        productTagView.title = tag.title
                        productTagView.tagTitle = tag.tagTitle
                        productTagView.tagImage = tag.tagImage
                        productTagView.photoFrameIndex = self.pageControl.currentPage
                        productTagView.tag = index
                        productTagView.mode = .edit
                        cell.addSubview(productTagView)
                    }
                }
            }
            return cell
            
        case filterCollectionView:
            
            let filter = filterOptionsDataSource[indexPath.row]
            let selectedFilter = postCreateDataList[pageControl.currentPage].filter
            
            let cell:PostFilterCell = collectionView.dequeueReusableCell(withReuseIdentifier: PostFilterAndBeautyViewController.PostFilterCellID, for: indexPath) as! PostFilterCell
            cell.model = filter
            
            let isEmptyFilter = { () -> Bool in
                return selectedFilter == nil && filter.source == .myMM && filter.filter == "ORIGINAL"
            }
            
            let isSelected = { () -> Bool in
                return selectedFilter?.source == filter.source && selectedFilter?.filter == filter.filter
            }
            
            let selected =  isEmptyFilter() || isSelected()
            cell.setFilterSelected(selected)
            
            return cell
            
        case beautyCollectionView:
            let cell = collectionView.dequeueReusableCell(withReuseIdentifier: PostFilterAndBeautyViewController.PostBeautyCellID, for: indexPath) as! PostBeautyCell
            cell.model = beautyOptionsDataSource[indexPath.row]
            return cell
            
        default:
            //titleCollectionView
            let cell = collectionView.dequeueReusableCell(withReuseIdentifier: PostFilterAndBeautyViewController.TitleFilterAndBeautyCellID, for: indexPath) as! TitleFilterAndBeautyCell
            
            cell.model = postCreateDataList[indexPath.row]
            return cell
            
        }
    }
    
    func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        
        switch collectionView {
        case filterCollectionView:
            
            let selectedFilter = filterOptionsDataSource[indexPath.row]
            let postCreateData =  self.postCreateDataList[self.pageControl.currentPage]
            
            if selectedFilter.source == .myMM && selectedFilter.filter == "ORIGINAL" {
                postCreateDataList[pageControl.currentPage].removeAllEffects()
                postCreateData.filter = selectedFilter
                self.filterCollectionView.reloadData()
            } else {
                
                if let image = postCreateData.originalImage {
                    showLoading()
                    
                    firstly {
                        return PhotoFilterUtils.apply(selectedFilter, toImage: image, resource: postCreateData.resource)
                        }
                        .then { (resource, image) -> Void in
                            if resource != nil {
                                postCreateData.resource = resource
                            }
                            
                            postCreateData.removeAllEffects()
                            postCreateData.filteredImage = image
                            postCreateData.filter = selectedFilter
                            
                            self.imageCollectionView.reloadItems(at: [IndexPath(item: self.pageControl.currentPage, section: 0)])
                            self.titleCollectionView.reloadItems(at: [IndexPath(item: self.pageControl.currentPage, section: 0)])
                            self.filterCollectionView.reloadData()
                        }
                        .always {
                            self.stopLoading()
                    }
                }
            }
            
            imageCollectionView.reloadItems(at: [IndexPath(item: pageControl.currentPage, section: 0)])
            titleCollectionView.reloadItems(at: [IndexPath(item: self.pageControl.currentPage, section: 0)])
            filterCollectionView.reloadData()
            
            viewFilter.recordAction(.Tap, sourceRef: selectedFilter.title, sourceType: .Filters, targetRef: "Beautifcation", targetType: .View)
            
        case beautyCollectionView:
            let postData = postCreateDataList[pageControl.currentPage]
            
            for i in 0..<beautyOptionsDataSource.count {
                beautyOptionsDataSource[i].selected = (indexPath.row == i)
                
                
            }
            
            updateSlider(true)
            
            viewBeauty.recordAction(.Tap, sourceRef: beautyOptionsDataSource[indexPath.row].title, sourceType: .Beautifcation, targetRef: "Editor-Post", targetType: .View)
            
            if indexPath.row == 0 {
                postData.selectBeauty = ""
                
                // 取消reset按钮
                beautyOptionsDataSource[0].selected = false
                
                // 取消美颜效果
                postData.beautifiedImage = nil
                
                beautySilder.isHidden = true
                beautySilder.isEnabled = false
                
                // 重置美颜设置
                postData.beautySettings = TutuWrapper.defaultSettings()
                
                //为只记录选中的美颜效果 重置是否第一次选中
                for i in 0..<beautyOptionsDataSource.count {
                    beautyOptionsDataSource[i].firstSelect = true
                }
                
                //更新图片
                self.imageCollectionView.reloadItems(at: [IndexPath(item: self.pageControl.currentPage, section: 0)])
                
            }else{
                var option = beautyOptionsDataSource[indexPath.row]
                postData.selectBeauty = option.key
                
                //只记录选中的美颜效果 value值为0.5
                if option.firstSelect {
                    option.firstSelect = false
                    postCreateDataList[pageControl.currentPage] = saveValue(option, postData: postData, value: 0.5)
                    beautyOptionsDataSource[indexPath.row] = option
                    updateSlider(true)
                }
                
                //选中reset按钮
                beautyOptionsDataSource[0].selected = true
                
                //更新图片
                updateImage(CGFloat(beautySilder.value))
                
            }
            beautyCollectionView.reloadData()
            
        case titleCollectionView:
            self.imageCollectionView.setContentOffset(CGPoint(x: ScreenWidth * CGFloat(indexPath.row), y: 0), animated: false)
            pageControl.currentPage = indexPath.row
            
            updateBeauty(indexPath.row)
            
        default:
            break
        }
    }
}
//=======================================================
// MARK: - SetupUI
//=======================================================
extension PostFilterAndBeautyViewController{
    func setupNavigation() {
        //MM-22244 Container to reduce tap area of back button
        let container = UIView(frame: CGRect(x: 0, y: 0, width: Constants.Value.BackButtonWidth + 15, height: Constants.Value.BackButtonHeight + 20))
        
        let buttonBack = UIButton()
        buttonBack.setImage(UIImage(named: "back_grey"), for: UIControlState())
        buttonBack.frame = CGRect(x: 0, y: 0, width: container.width, height: container.height)
        let verticalPadding = (container.height - Constants.Value.BackButtonHeight)/2
        buttonBack.contentEdgeInsets = UIEdgeInsets.init(top: verticalPadding, left: Constants.Value.BackButtonMarginLeft, bottom: verticalPadding, right: (container.width - Constants.Value.BackButtonWidth))
        buttonBack.addTarget(self, action: #selector(backButton), for: .touchUpInside)
        buttonBack.accessibilityIdentifier = "UIBT_BACK"
        container.addSubview(buttonBack)
        let backButtonItem = UIBarButtonItem(customView: container)
        self.navigationItem.leftBarButtonItem = backButtonItem
        
        let rightButton = UIButton()
        rightButton.setTitle(String.localize("LB_NEXT"), for: UIControlState())
        rightButton.titleLabel!.font = UIFont.systemFont(ofSize: 14)
        rightButton.setTitleColor(UIColor.primary1(), for: UIControlState())
        rightButton.frame = CGRect(x: 0, y: 0, width: 50, height: Constants.Value.BackButtonHeight)
        rightButton.addTarget(self, action: #selector(rightButtonTapped), for: .touchUpInside)
        self.navigationItem.rightBarButtonItem = UIBarButtonItem(customView: rightButton)
        
        self.createTitleView()
    }
    
    
    
    
    
    func createTitleView() {
        let layout: UICollectionViewFlowLayout = UICollectionViewFlowLayout()
        layout.sectionInset = UIEdgeInsets(top: 0, left: 0, bottom: 0, right: 0)
        layout.itemSize = CGSize(width: 24, height: 24)
        layout.scrollDirection = .horizontal
        
        let width = (32 * pageControl.numberOfPages) + ((pageControl.numberOfPages - 1) * 2)
        
        titleCollectionView = UICollectionView(frame: CGRect(x: 0, y: 0, width: width, height: 32), collectionViewLayout: layout)
        titleCollectionView.dataSource = self
        titleCollectionView.delegate = self
        titleCollectionView.isScrollEnabled = true
        titleCollectionView.backgroundColor = UIColor.clear
        titleCollectionView.showsHorizontalScrollIndicator = false
        
        titleCollectionView.register(UINib(nibName: PostFilterAndBeautyViewController.TitleFilterAndBeautyCellID, bundle: nil), forCellWithReuseIdentifier: PostFilterAndBeautyViewController.TitleFilterAndBeautyCellID)
        navigationItem.titleView = titleCollectionView
    }
    
    func setupCollectionView() {
        imageCollectionView.register(PostImageCell.self, forCellWithReuseIdentifier: PostFilterAndBeautyViewController.PostImageCellID)
        filterCollectionView.register(UINib(nibName: PostFilterAndBeautyViewController.PostFilterCellID, bundle: nil), forCellWithReuseIdentifier: PostFilterAndBeautyViewController.PostFilterCellID)
        beautyCollectionView.register(UINib(nibName: PostFilterAndBeautyViewController.PostBeautyCellID, bundle: nil), forCellWithReuseIdentifier: PostFilterAndBeautyViewController.PostBeautyCellID)
    }
    
    func setupView() {
        pageControl.numberOfPages = postCreateDataList.count
        pageControl.pageIndicatorTintColor = UIColor.gray
        pageControl.currentPageIndicatorTintColor = UIColor.black
        
        // FIXME: update string
        lblFilter.text = String.localize("LB_CA_FILTERS")
        lblFilter.font = UIFont.systemFont(ofSize: 14)
        
        lblBeauty.text = String.localize("LB_CA_BEAUTIFY")
        lblBeauty.font = UIFont.systemFont(ofSize: 14)
        
        imgViewFilter.image = UIImage(named: "filter_grey")
        imgViewFilter.highlightedImage = UIImage(named: "filter_black")
        
        imgViewBeauty.image = UIImage(named: "beauty_grey")
        imgViewBeauty.highlightedImage = UIImage(named: "beauty_black")
        
        lblFilter.textColor = UIColor.black
        lblBeauty.textColor = UIColor.secondary2()
        
        imgViewFilter.isHighlighted = true
        imgViewBeauty.isHighlighted = false
        
        viewFilterIndicator.isHidden = false
        viewBeautyIndicator.isHidden = true
        
        viewFilter.isHidden = false
        viewBeauty.isHidden = true
        
        beautySilder.isHidden = true
        beautySilder.isEnabled = false
        
        if postCreateDataList.count == 1 {
            pageControl.isHidden = true
        }
        if figureChoose {
            view.addSubview(figureButton)
            figureButton.snp.makeConstraints { (make) in
                make.centerY.equalTo(pageControl)
                make.left.equalTo(15)
            }
        }
    }
}
//=======================================================
// MARK: - CollectionView Delegate & DataSouce
//=======================================================

//=======================================================
// MARK: - SetingFilterAndBeauty
//=======================================================
extension PostFilterAndBeautyViewController{
    func updateBeauty(_ index:Int){
        let data = postCreateDataList[index]
        
        for i in 0..<postCreateDataList.count {
            let data = postCreateDataList[i]
            data.isCurrentFilterTarget = (i == index)
        }
        
        for i in 0..<beautyOptionsDataSource.count {
            var option = beautyOptionsDataSource[i]
            
            switch option.key {
            case "smoothing":
                if data.beautySettings!.smoothing == TutuWrapper.defaultSettings().smoothing{
                    option.firstSelect = true
                }else{
                    option.firstSelect = false
                }
            case "whitening":
                if data.beautySettings!.whitening == TutuWrapper.defaultSettings().whitening{
                    option.firstSelect = true
                }else{
                    option.firstSelect = false
                }
            case "skinColor":
                if data.beautySettings!.skinColor == TutuWrapper.defaultSettings().skinColor{
                    option.firstSelect = true
                }else{
                    option.firstSelect = false
                }
            case "eyeSize":
                if data.beautySettings!.eyeSize == TutuWrapper.defaultSettings().eyeSize{
                    option.firstSelect = true
                }else{
                    option.firstSelect = false
                }
            case "chinSize":
                if data.beautySettings!.chinSize == TutuWrapper.defaultSettings().chinSize{
                    option.firstSelect = true
                }else{
                    option.firstSelect = false
                }
            default:
                break
            }
            
            beautyOptionsDataSource[i] = option
        }
        
        filterCollectionView.reloadData()
        
        let selectedFilter = postCreateDataList[pageControl.currentPage]
        
        for i in 0..<beautyOptionsDataSource.count {
            var option = beautyOptionsDataSource[i]
            if option.key ==  selectedFilter.selectBeauty{
                option.selected = true
                beautyOptionsDataSource[0].selected = true
            }else{
                option.selected = false
            }
            
            beautyOptionsDataSource[i] = option
            
        }
        beautyCollectionView.reloadData()
        
        if !beautyOptionsDataSource[0].selected {
            beautySilder.isHidden = true
            beautySilder.isEnabled = false
        }
        
        updateSlider(true)
        
        titleCollectionView.reloadData()
    }
    
    func updateSlider(_ selectBeauty:Bool) {
        
        var selectedBeautyOption: BeautyOption?
        
        for option in beautyOptionsDataSource {
            if option.selected && option.key != "reset"{
                selectedBeautyOption = option
                break
            }
        }
        
        if let selectedBeautyOption = selectedBeautyOption {
            
            let postData = postCreateDataList[pageControl.currentPage]
            
            let beautySettingsOrDfault = { () -> TutuWrapper.BeautySetting in
                var beautySettings = postData.beautySettings
                if beautySettings == nil {
                    beautySettings = TutuWrapper.defaultSettings()
                }
                return beautySettings!
            }
            
            beautySilder.isHidden = false
            beautySilder.isEnabled = true
            
            switch selectedBeautyOption.key {
            case "recommend":
                
                beautySilder.isHidden = true
                beautySilder.isEnabled = false
                
                if selectBeauty == false {
                    return
                }
                
                let beautySettings = postData.recommendSettings()
                
                if let image = postData.filteredImage {
                    showLoading()
                    TutuWrapper.beauty(image, settings: beautySettings)
                        .then { (beautySetting, image) -> Void in
                            postData.beautifiedImage = image
                            self.imageCollectionView.reloadItems(at: [IndexPath(item: self.pageControl.currentPage, section: 0)])
                        }
                        .always {
                            self.stopLoading()
                    }
                } else {
                    // no image to process!!
                }
                
            case "smoothing":
                beautySilder.value = Float((beautySettingsOrDfault().smoothing - TutuWrapper.MinValue) / (TutuWrapper.MaxValue - TutuWrapper.MinValue))
                
            case "whitening":
                beautySilder.value = Float((beautySettingsOrDfault().whitening - TutuWrapper.MinValue) / (TutuWrapper.MaxValue - TutuWrapper.MinValue))
                
            case "skinColor":
                beautySilder.value = Float((beautySettingsOrDfault().skinColor - TutuWrapper.MinValue) / (TutuWrapper.MaxValue - TutuWrapper.MinValue))
                
            case "eyeSize":
                beautySilder.value = Float((beautySettingsOrDfault().eyeSize - TutuWrapper.MinValue) / (TutuWrapper.MaxValue - TutuWrapper.MinValue))
                
            case "chinSize":
                beautySilder.value = Float((beautySettingsOrDfault().chinSize - TutuWrapper.MinValue) / (TutuWrapper.MaxValue - TutuWrapper.MinValue))
                
            default:
                break
            }
        }
    }
    
    func currentSelectedBeautyOption() -> BeautyOption {
        for i in 0..<beautyOptionsDataSource.count {
            let option = beautyOptionsDataSource[i]
            if option.key != "reset" && option.selected{
                return option
            }
        }
        return beautyOptionsDataSource[0] // return
    }
    @IBAction func beautySilderChanged(_ sender: UISlider) {
        updateImage(CGFloat(sender.value))
    }
    
    func updateImage(_ value:CGFloat) {
        let selectedOption = currentSelectedBeautyOption()
        let value = TutuWrapper.MinValue + (value * (TutuWrapper.MaxValue - TutuWrapper.MinValue))
        var postData = postCreateDataList[pageControl.currentPage]
        
        postData = saveValue(selectedOption, postData: postData, value: value)
        
        showLoading()
        
        if let image = postData.filteredImage {
            TutuWrapper.beauty(image, settings: postData.beautySettingsOrDefault())
                .then { (beautySetting, image) -> Void in
                    postData.beautifiedImage = image
                    self.imageCollectionView.reloadItems(at: [IndexPath(item: self.pageControl.currentPage, section: 0)])
                }
                .always {
                    self.stopLoading()
            }
        }
    }
    
    func saveValue(_ option:BeautyOption,postData:PostCreateData,value:CGFloat) -> PostCreateData{
        switch option.key {
        case "reset":
            return postData
        case "smoothing":
            postData.setSmoothing(value)
        case "whitening":
            postData.setWhitening(value)
        case "skinColor":
            postData.setSkinColor(value)
        case "eyeSize":
            postData.setEyeSize(value)
        case "chinSize":
            postData.setChinSize(value)
        default:
            break
        }
        return postData
    }
}
//=======================================================
// MARK: - TagProduct
//=======================================================
extension PostFilterAndBeautyViewController:TagViewDelegate,TagProductViewControllerDelegate{
    @objc func touchImageCell(_ gesture: UITapGestureRecognizer) {
        let point = gesture.location(in: gesture.view)
        self.postImageCell = gesture.view as? PostImageCell
        lastPositionTap = point
        
        let postData = postCreateDataList[self.pageControl.currentPage]
        
        if let tags = postData.tags {
            if tags.count > 4{
                showAlart(postData: postData)
            }else{
                chooseTageType()
            }
        }else{
            chooseTageType()
        }
    }
    
    func chooseTageType() {
        
        PopManager.sharedInstance.chooseTageType(brandCallback: {
            PushManager.sharedInstance.gotoBrandList(brandCallback: { [weak self] (brand) in
                if let strongSelf = self {
                    strongSelf.addTagProduct(id: brand.brandId, mode : ModeTagProduct.wishlist,title: brand.brandName,tagStyle: .Brand,tagTitle: brand.brandName,tagImage: brand.smallLogoImage,brand:brand)
                    strongSelf.imageCollectionView.reloadData()
                }
            })
        }) {
            self.present(MmNavigationController(rootViewController: TagProductSelectionViewController(object: self)), animated: true, completion: nil)
        }
    }
    
    func showAlart(postData:PostCreateData)  {
        var message = "单张图片最多5个标签哦! "
        if postData.alartShow  == 0{
            message = "单张图片最多5个标签哦! "
        }else if postData.alartShow  == 1{
            message = "再点我就打你哦~"
        }else if postData.alartShow  == 2{
            message = "真的打你哦~我在路上了！"
        }else{
            message = "站着别动！"
        }
        Alert.alertWithSingleButton(self, title: "", message: message, buttonString: String.localize("LB_OK"))
        postData.alartShow =  postData.alartShow + 1
    }
    
    func didSelectedItemForTag(_ postCreateData: PostCreateData, mode: ModeTagProduct) {
        
        let sku = (postCreateData.skus?.first)! as Sku
        addTagProduct(id: sku.skuId, mode : mode, title: sku.brandName,tagStyle:.Commodity,tagTitle: sku.skuName,tagImage: sku.productImage,sku: sku)
        self.imageCollectionView.reloadData()
    }
    func didSelectedCloseButton(_ tagView: ProductTagView) {
        let optionMenu = UIAlertController(title: nil, message: nil, preferredStyle: .actionSheet)
        let deleteAction = UIAlertAction(title: String.localize("LB_PRODUCT_TAG_DELETION"), style: .default, handler: {
            (alert: UIAlertAction!) ->  Void in
            let postData = self.postCreateDataList[self.pageControl.currentPage]
            if  postData.tags != nil {
                postData.tags!.remove(at: tagView.tag)
                self.postCreateDataList[self.pageControl.currentPage] = postData
            }
            self.imageCollectionView.reloadData()
            
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
        print(tag.tag)
        let postData = postCreateDataList[self.pageControl.currentPage]
        if  postData.tags != nil {
            let tags = postData.tags![tag.tag]
            tags.positionX = Int(tag.finalLocation.x)
            tags.positionY = Int(tag.finalLocation.y)
            tags.place = tag.place
            
            var positionX = tags.positionX
            var positionY = tags.positionY
            if CGFloat(tags.positionX) > tags.iamgeFrame.maxX || CGFloat(tags.positionX) < tags.iamgeFrame.origin.x || CGFloat(tags.positionY) > tags.iamgeFrame.maxY || CGFloat(tags.positionY) < tags.iamgeFrame.origin.y{
                positionX = Int(25)
                var margin = 0
                if tags.iamgeFrame.size.height > tags.iamgeFrame.size.width{
                    margin = 35
                }else {
                    margin = 70
                }
                positionY = Int(Int(ScreenWidth) - margin * tag.tag)
            }
            let tagPercent = ProductTagView.getTapPercentage(CGPoint(x: positionX, y: positionY))
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
            postCreateDataList[self.pageControl.currentPage] = postData
        }
    }
    
    func endMoveTag() {
        self.getProductView().hideProductWithAnimation(true)
    }
    func touchDown(_ tag: ProductTagView) {
        self.getProductView().setTagData(name: tag.tagTitle, imageUrl:tag.tagImage,type:tag.productTagStyle)
        self.getProductView().showProductWithAnimation(true)
        Log.debug("toucheDown")
    }
    
    func touchUp(_ tag: ProductTagView) {
        Log.debug("toucheUp")
        self.getProductView().hideProductWithAnimation(true)
    }
    
    func getProductView() -> ProductView {
        if self.productView == nil{
            self.productView = ProductView(frame: CGRect(x:50,y: 30,width: self.view.width - 50 * 2 ,height: 48))
        }
        return self.productView!
    }
    func addTagProduct(id: Int, mode: ModeTagProduct, title:String? = nil,tagStyle:ProductTagStyle? = nil,tagTitle:String? = nil,tagImage:String? = nil,sku:Sku? = nil,brand:Brand? = nil){
        let postData = postCreateDataList[self.pageControl.currentPage]
        
        
        
        let imageTage = ImagesTags()
        imageTage.positionX = Int(lastPositionTap.x)
        imageTage.positionY = Int(lastPositionTap.y)
        imageTage.place = .undefined
        imageTage.id = id
        imageTage.title = title!
        imageTage.tagTitle = tagTitle!
        imageTage.tagImage = tagImage!
        if tagStyle != nil {
            imageTage.postTag = tagStyle!
        }
        let cell = imageCollectionView.cellForItem(at: NSIndexPath.init(row: self.pageControl.currentPage, section: 0) as IndexPath) as!
        PostImageCell
        imageTage.iamgeFrame = cell.bgImageView.frame
        
        
        var positionX = imageTage.positionX
        var positionY = imageTage.positionY
        if CGFloat(imageTage.positionX) > imageTage.iamgeFrame.maxX || CGFloat(imageTage.positionX) < imageTage.iamgeFrame.origin.x || CGFloat(imageTage.positionY) > imageTage.iamgeFrame.maxY || CGFloat(imageTage.positionY) < imageTage.iamgeFrame.origin.y{
            positionX = Int(25)
            var margin = 0
            if imageTage.iamgeFrame.size.height > imageTage.iamgeFrame.size.width{
                margin = 35
            }else {
                margin = 70
            }
            if let tags = postData.tags{
                positionY = Int(Int(ScreenWidth) - margin * tags.count)
            }else{
                positionY = Int(ScreenWidth)
            }
            
        }
        if sku != nil {
            let tagPercent = ProductTagView.getTapPercentage(CGPoint(x: positionX, y: positionY))
            sku!.positionX = tagPercent.x
            sku!.positionY = tagPercent.y
            imageTage.sku = sku!
        }
        if brand != nil {
            let tagPercent = ProductTagView.getTapPercentage(CGPoint(x: positionX, y: positionY))
            brand!.positionX = tagPercent.x
            brand!.positionY = tagPercent.y
            imageTage.brand = brand!
        }
        postData.addTag(tag: imageTage)
        postCreateDataList[self.pageControl.currentPage] = postData
        
    }
    func didTapOnImage() {
        
        self.present(MmNavigationController(rootViewController: TagProductSelectionViewController(object: self)), animated: true, completion: nil)
        
    }
}

