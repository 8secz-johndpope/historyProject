//
//  MagazineCollectionViewController.swift
//  merchant-ios
//
//  Created by Quang Truong Dinh on 5/16/16.
//  Copyright © 2016 Quang Truong Dinh. All rights reserved.
//

import UIKit
import PromiseKit
import ObjectMapper

class MagazineCollectionViewController: MmViewController, MagazinecellDelegate {
    
    private final let RightMenuWidth: CGFloat = 187
    private final let RightMenuCellSize = CGSize(width: 167, height: 110)
    private final let NumberOfFixedItems = 0
    
    private var rightMenuButton: UIButton!
    private var rightMenuView: UIView!
    private var rightMenuCollectionView: UICollectionView!
    private var rightMenuBackButton: UIButton!
    private var rightMenuCategoryAllButton: UIButton!
    
    private var navigationBarBottomLayer: CALayer!
    
    private var tapHideRightMenuGesture: UITapGestureRecognizer?
    private var panRightMenuGesture: UIPanGestureRecognizer?
    private var contentPageCollectionList: [ContentPageCollection]?
    
    // Magazine
    private var magazines = [Any]()
    private var featuredCellTag = 0
    private var isChangedFeaturedCell = false
    private var magazineCoverList: MagazineCoverList?
    private var currentPage = 1
    
    var contentPageList: ContentPageList?
    
    func setupOverlay() {
        let overlayFrame = CGRect(x: 0, y: 0, width: self.view.frame.size.width, height: self.view.frame.size.width / 750 * 160)
        let overlay = UIImageView(frame: overlayFrame)
        overlay.image = UIImage(named: "overlay")
        self.view.addSubview(overlay)
        
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        initVariables()
        setupCollectionView()
        setupRightMenuView()
        createBackButton(.whiteColor)
        
        setupOverlay()
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        
        addRightMenu()
        loadViewData()
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        
        cleanUpRightMenu()
    }

    // MARK: - Data
    
    func loadContentPageCollection() -> Promise<Any> {
        return Promise { fulfill, reject in
            //TODO: HARD CODE = 2 for getting typeId, there's no defination for type id now and type id = 2 works well
            ContentPageCollectionService.listContentPageCollection(2, completion: { [weak self] (response) in
                if let strongSelf = self {
                    if response.result.isSuccess {
                        if response.response?.statusCode == 200 {
                            if let contentPageCollections = Mapper<ContentPageCollection>().mapArray(JSONObject: response.result.value) {
                                strongSelf.contentPageCollectionList = contentPageCollections
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
                } else {
                    ErrorLogManager.sharedManager.recordNonFatalError(withException: .NullPointer)
                }
                })
        }
    }
    
    func loadViewData(_ page: Int = 1) {
        showLoading()
        
        firstly {
            
            return self.loadMagazineCovers(page: page)
            
            }.then { data -> Promise<Any> in
                self.dismissNoConnectionView()

                return self.listLikedContentPage(page)
                
            }.then { _ -> Void in
                
                self.updateLikeForMagazinCover()
                
            }.then { _ -> Promise<Any> in
                
                return self.loadContentPageCollection()
                
            }.then { _ -> Void in
                self.collectionView.reloadData()
                self.rightMenuCollectionView.reloadData()
            }.always {
                self.stopLoading()
            }.catch { _ -> Void in
                Log.error("error")
                self.showNoConnectionView()
                self.noConnectionView!.reloadHandler = { [weak self] in
                    if let strongSelf = self {
                        strongSelf.currentPage = 1
                        strongSelf.loadViewData(strongSelf.currentPage)
                    }
                }
        }
    }
    
    private func updateLikeForMagazinCover() {
        if let contentPageLists = self.contentPageList {
            
            for magazine in magazines {
                if let magazine = magazine as? MagazineCover{
                    magazine.isLike = contentPageLists.isLikedContentPageByContentKey(magazine.contentPageKey)
                }
            }
        }
    }
    
    func loadMagazineCovers(_ contentPageCollectionId: Int? = nil, page: Int = 1) -> Promise<Any> {
        return Promise { fulfill, reject in
            MagazineService.magazineCoverList(typeId: 2, collectionId: contentPageCollectionId, page: page, size: Constants.Paging.Offset,
                success: { [weak self] (magazineCoverList) in
                    if let strongSelf = self {
                        if page == 1 {
                            strongSelf.magazineCoverList = magazineCoverList
                            strongSelf.magazines = magazineCoverList.pageData?.contentPages ?? []
                            if contentPageCollectionId != nil {
                                if let contentPageCollection = magazineCoverList.pageData?.contentPageCollection {
                                    if strongSelf.magazines.count > 0 {
                                        strongSelf.magazines.insert(contentPageCollection, at: 0)
                                    } else {
                                        strongSelf.magazines.append(contentPageCollection)
                                    }
                                }
                            }
                        } else { // load more
                            if let originalCover = strongSelf.magazineCoverList {
                                
                                var finalData = [MagazineCover]()
                                if let contentPages = originalCover.pageData?.contentPages {
                                    finalData += contentPages
                                }
                                
                                if let contentPages = magazineCoverList.pageData?.contentPages {
                                    finalData += contentPages
                                }
                                
                                strongSelf.magazineCoverList?.pageData?.contentPages = finalData
                                strongSelf.magazines = finalData
                            }
                        }
                        fulfill(strongSelf.magazines)
                    } else {
                        ErrorLogManager.sharedManager.recordNonFatalError(withException: .NullPointer)
                    }
                },
                failure: { error in
                    reject(error)
                    return false
                }
            )
        }
    }
    
    //MARK: - View
    
    func addRightMenu() {
        let mainView = UIApplication.shared.delegate?.window
        mainView!!.addGestureRecognizer(panRightMenuGesture!)
        mainView!!.addSubview(rightMenuView)
    }
    
    func cleanUpRightMenu() {
        let mainView = UIApplication.shared.delegate?.window
        mainView!!.removeGestureRecognizer(panRightMenuGesture!)
        rightMenuView.removeFromSuperview()
        self.hideRightCategoryView(sender: nil)
    }
    
    @objc func panRightCategoryView(_ sender: UIPanGestureRecognizer) {
        if sender.state == UIGestureRecognizerState.changed {
            let velocity = sender.velocity(in: self.navigationController!.view)
            
            var rightMenuViewFrame = rightMenuView!.frame
            rightMenuViewFrame.originX = rightMenuViewFrame.originX + velocity.x / 50
            rightMenuViewFrame.originX = max(rightMenuViewFrame.originX, view.frame.width - RightMenuWidth)
            rightMenuViewFrame.originX = min(rightMenuViewFrame.originX, view.frame.width)
            
            if rightMenuViewFrame.originX <= view.frame.width - RightMenuWidth {
                showRightCategoryView(sender: nil)
            } else if rightMenuViewFrame.originX >= view.frame.width {
                hideRightCategoryView(sender: nil)
            } else {
                rightMenuView!.isHidden = false
                navigationController?.view.addGestureRecognizer(self.tapHideRightMenuGesture!)
                rightMenuView!.frame = rightMenuViewFrame
            }
        } else if sender.state == UIGestureRecognizerState.ended {
            let rightMenuViewFrame = rightMenuView!.frame
            
            if rightMenuViewFrame.originX <= (view.frame.width - (RightMenuWidth / 2)) {
                showRightCategoryView(sender: nil)
            } else {
                hideRightCategoryView(sender: nil)
            }
        }
    }
    
    func buttonAllCategoryTap() {
        hideRightCategoryView(sender: nil)
    }
    
    //MARK: - Set up
    
    func initVariables () {
        tapHideRightMenuGesture = UITapGestureRecognizer(target: self, action: #selector(MagazineCollectionViewController.hideRightCategoryView))
        panRightMenuGesture = UIPanGestureRecognizer(target: self, action: #selector(MagazineCollectionViewController.panRightCategoryView))
    }
    
    func setupRightMenuView() {
        // Superview Right Menu
        rightMenuView = UIView(frame: CGRect(x: ScreenWidth, y: 0, width: RightMenuWidth, height: view.height - tabBarHeight)) // Align menu height with Android
        rightMenuView.isHidden = true
        rightMenuView.backgroundColor = UIColor.clear
        
        let blurEffect = UIBlurEffect(style: .dark)
        let blurEffectView = UIVisualEffectView(effect: blurEffect)
        blurEffectView.frame = rightMenuView.bounds
        blurEffectView.alpha = 0.95
        rightMenuView.addSubview(blurEffectView)
        
        let backButtonSize = CGSize(width: 20, height: 20)
        let topButtonSize = CGSize(width: 50, height: 35)
        
        let buttonTopMarginBack: CGFloat = 33
        let buttonTopMarginTop: CGFloat = 26
        let topMarginLineView: CGFloat = 90
        let leftMarginBackButton: CGFloat = 12
        let marginAllButton: CGFloat = 5
        
        rightMenuBackButton = UIButton(type: .custom)
        rightMenuBackButton.setImage(UIImage(named: "back_wht"), for: UIControlState())
        rightMenuBackButton.frame = CGRect(x: leftMarginBackButton, y: buttonTopMarginBack, width: backButtonSize.width, height: backButtonSize.height)
        rightMenuBackButton.backgroundColor = UIColor.clear
        rightMenuBackButton.contentEdgeInsets = UIEdgeInsets(top: 5, left: 7, bottom: 5, right: 7)
        rightMenuBackButton.addTarget(self, action: #selector(MagazineCollectionViewController.hideRightCategoryView), for: .touchUpInside)
        rightMenuView.addSubview(rightMenuBackButton)
        
        rightMenuCategoryAllButton = UIButton(type: .custom)
        rightMenuCategoryAllButton.backgroundColor = UIColor.clear
        rightMenuCategoryAllButton.titleLabel!.formatSize(12)
        rightMenuCategoryAllButton.setTitleColor(UIColor.white, for: UIControlState())
        rightMenuCategoryAllButton.setTitle(String.localize("LB_CA_SELECT_ALL"), for: UIControlState())
        rightMenuCategoryAllButton.frame = CGRect(x: leftMarginBackButton + marginAllButton + backButtonSize.width, y: buttonTopMarginTop, width: topButtonSize.width, height: topButtonSize.height)
        rightMenuCategoryAllButton.contentHorizontalAlignment = .left
        rightMenuCategoryAllButton.addTarget(self, action: #selector(MagazineCollectionViewController.allCategoryButtonOnTap), for: .touchUpInside)
        rightMenuView.addSubview(rightMenuCategoryAllButton)
        
        let topViewLine = UIView(frame: CGRect(x: RightMenuWidth - RightMenuCellSize.width, y: topMarginLineView, width: RightMenuCellSize.width, height: 1))
        topViewLine.backgroundColor = UIColor.white
        rightMenuView.addSubview(topViewLine)
        
        // Collection View
        let layout = UICollectionViewFlowLayout()
        layout.scrollDirection = UICollectionViewScrollDirection.vertical
        layout.headerReferenceSize = CGSize.zero
        layout.footerReferenceSize = CGSize.zero
        layout.sectionInset = UIEdgeInsets.zero
        layout.minimumInteritemSpacing = 0
        layout.minimumLineSpacing = 0
        layout.itemSize = RightMenuCellSize
        
        rightMenuCollectionView = UICollectionView(
            frame: CGRect(x: RightMenuWidth - RightMenuCellSize.width, y: topViewLine.frame.maxY, width: RightMenuCellSize.width, height: rightMenuView.height - topViewLine.frame.maxY),
            collectionViewLayout: layout
        )
        
        rightMenuCollectionView.contentInset = UIEdgeInsets.zero
        rightMenuCollectionView.isPagingEnabled = true
        rightMenuCollectionView.backgroundColor = UIColor.clear
        rightMenuCollectionView.showsHorizontalScrollIndicator = false
        rightMenuCollectionView.dataSource = self
        rightMenuCollectionView.delegate = self
        rightMenuCollectionView.register(MagazineCategoryCell.self, forCellWithReuseIdentifier: MagazineCategoryCell.CellIdentifier)
        rightMenuView.addSubview(rightMenuCollectionView)
        
        // Button Menu
        let menuButtonSize = CGSize(width: 40, height: 35)
        rightMenuButton = UIButton(type: .custom)
        rightMenuButton.frame = CGRect(x: 0, y: 0 , width: menuButtonSize.width, height: menuButtonSize.height)
        rightMenuButton.backgroundColor = UIColor.clear
        rightMenuButton.setImage(UIImage(named: "menu_white"), for: UIControlState())
        rightMenuButton.addTarget(self, action: #selector(MagazineCollectionViewController.showRightCategoryView), for: .touchUpInside)
        
        let rightButtonItems = [
            UIBarButtonItem(customView: rightMenuButton!)
        ]
        self.navigationItem.rightBarButtonItems = rightButtonItems
    }
    
    func setupCollectionView() {
        let viewLayout = MagazineCollectionViewLayout()
        viewLayout.numberOfFixedItems = NumberOfFixedItems
        
        collectionView.setCollectionViewLayout(viewLayout, animated: true)
        collectionView.register(MagazineCell.self, forCellWithReuseIdentifier: MagazineCell.CellIdentifier)
        collectionView.decelerationRate = UIScrollViewDecelerationRateFast
        collectionView.frame = CGRect(x: 0, y: 0, width: view.width, height: view.height - tabBarHeight)
        collectionView.backgroundColor = UIColor.backgroundGray()
        if #available(iOS 10.0, *) {
            collectionView.isPrefetchingEnabled = false
        }
    }
    
    func setupNavigationBar() {
        setupNavigationBarCartButton()
        setupNavigationBarWishlistButton()
        
        buttonCart?.addTarget(self, action: #selector(self.goToShoppingCart), for: .touchUpInside)
        buttonWishlist?.addTarget(self, action: #selector(self.goToWishList), for: .touchUpInside)
        
        buttonCart?.accessibilityIdentifier = "view_cart_button"
        buttonWishlist?.accessibilityIdentifier = "view_wishlist_button"
        
        // Use white icons
        buttonCart?.setImage(UIImage(named:"shop"), for: UIControlState())
        buttonWishlist?.setImage(UIImage(named: "heart"), for: UIControlState())
        
        let rightButtonItems = [
            UIBarButtonItem(customView: buttonCart!),
            UIBarButtonItem(customView: buttonWishlist!)
        ]
        
        self.navigationItem.rightBarButtonItems = rightButtonItems
        
        let viewTitle = UIView(frame: CGRect(x: 50, y: 0, width: self.view.bounds.maxX * 2 / 3, height: 20))
        
        let searchButton = UIButton(type: UIButtonType.custom)
        searchButton.frame = CGRect(x: 0, y: 0, width: 20, height: 20)
        searchButton.setImage(UIImage(named: "search_wht"), for: UIControlState())
        searchButton.addTarget(self, action: #selector(MagazineCollectionViewController.searchIconClicked), for: .touchUpInside)
        
        viewTitle.addSubview(searchButton)
        self.navigationItem.titleView = viewTitle
        // Navigation bar Bottom Line
        navigationBarBottomLayer = CALayer()
        navigationBarBottomLayer.borderColor = UIColor.white.cgColor
        navigationBarBottomLayer.borderWidth = 1
        
        let navigationLayer = self.navigationController!.navigationBar.layer
        navigationBarBottomLayer.frame = CGRect(x: 0, y: navigationLayer.frame.height - 1, width: navigationLayer.frame.width, height: 1)
        navigationLayer.addSublayer(navigationBarBottomLayer)
    }
    
    // MARK: - Action
    
    @objc func showRightCategoryView(sender: UIButton?) {
        rightMenuView.isHidden = false
        
        UIView.animate(withDuration: 0.3, animations: {
            self.rightMenuView.frame = CGRect(x: self.view.width - self.RightMenuWidth, y: 0, width: self.RightMenuWidth, height: self.view.height)
            self.navigationController?.view.addGestureRecognizer(self.tapHideRightMenuGesture!)
            }, completion: { isFinish -> Void in
                
        })
        
        if let button = sender {
            button.initAnalytics(withViewKey: self.analyticsViewRecord.viewKey)
            button.recordAction(.Tap, sourceRef: "Filter", sourceType: .Button, targetRef: "ContentListing-Filter", targetType: .View)
        }
    }
    
    @objc func hideRightCategoryView(sender: UIButton?) {
        self.navigationController?.view.removeGestureRecognizer(tapHideRightMenuGesture!)
        
        UIView.animate(withDuration: 0.3, animations: {
            self.rightMenuView.frame = CGRect(x: self.view.width, y: 0, width: self.RightMenuWidth, height: self.view.height)
            }, completion: { isFinish -> Void in
                self.rightMenuView.isHidden = true
        })
        if let button = sender  {
            if button.isKind(of: UIButton.self) {
                button.initAnalytics(withViewKey: self.analyticsViewRecord.viewKey)
                button.recordAction(.Tap, sourceRef: "All", sourceType: .Collection, targetRef: "ContentListing", targetType: .View)
            }
        }
    }
    
    @objc func allCategoryButtonOnTap() {
        hideRightCategoryView(sender: nil)
        showLoading()
        
        self.currentPage = 1
        
        firstly {
            
            return self.loadMagazineCovers()
            
            }.then { data -> Promise<Any> in
                
                return self.listLikedContentPage()
                
            }.then { _ -> Void in
                
                self.updateLikeForMagazinCover()
                
            }.then { _ -> Void in
                
                self.magazines = (self.magazineCoverList?.pageData?.contentPages)!
                self.collectionView.reloadData()
                self.rightMenuCollectionView.reloadData()
            }.always {
                self.stopLoading()
            }.catch { _ -> Void in
                Log.error("error")
        }
    }
    
    // MARK: - Collection View
    
    func numberOfSections(in collectionView: UICollectionView) -> Int {
        return 1
    }
    
    override func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        if collectionView == rightMenuCollectionView {
            if let contentPageCollectionList = self.contentPageCollectionList {
                return contentPageCollectionList.count
            }
            
            return 0
        }
        
        return magazines.count + NumberOfFixedItems
    }
    
    override func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        if collectionView == rightMenuCollectionView {
            // Right Category Magazine Collection
            let cell = collectionView.dequeueReusableCell(withReuseIdentifier: MagazineCategoryCell.CellIdentifier, for: indexPath) as! MagazineCategoryCell
            
            if let contentPageCollectionList = self.contentPageCollectionList {
                let contentPageCollection = contentPageCollectionList[indexPath.item]
                cell.categoryTitle!.text = contentPageCollection.contentPageCollectionName
            } else {
                cell.categoryTitle!.text = ""
            }
            
            cell.contentView.backgroundColor = UIColor.clear
            
            return cell
        } else {
            // Magazine Collection
            let cell = collectionView.dequeueReusableCell(withReuseIdentifier: MagazineCell.CellIdentifier, for: indexPath) as! MagazineCell
            cell.likeButton.tag = indexPath.row
            cell.delegate = self
            if indexPath.item < magazines.count {
                let data = magazines[indexPath.item]
                
                if type(of: data) == ContentPageCollection.self {
                    cell.contentPageCollection = data as? ContentPageCollection
                    cell.showLikeView(false)
                    
                    guard cell.contentPageCollection != nil else { return cell }
                    
                    cell.backgroundImageView.mm_setImageWithURL(ImageURLFactory.URLSize1000(cell.contentPageCollection!.coverImage, category: ImageCategory.contentPageCollectionImages), placeholderImage : UIImage(named: "Spacer"), contentMode: UIViewContentMode.scaleAspectFill, completion: { (image, error, cacheType, imageURL) in
                        
                        if image == nil {
                            cell.backgroundImageView.image = UIImage(named: "mm_white")
                            cell.backgroundImageView.backgroundColor = UIColor.gray
                            cell.backgroundImageView.contentMode = .center
                        }
                        else {
                            cell.backgroundImageView.backgroundColor = UIColor.clear
                        }

                    })
                } else if type(of: data) == MagazineCover.self {
                    cell.magazine = data as? MagazineCover
                    cell.backgroundImage = nil
                    cell.showLikeView(true)
                    
                    guard cell.magazine != nil else { return cell }
                    
                    cell.backgroundImageView.mm_setImageWithURL(ImageURLFactory.URLSize1000(cell.magazine!.coverImage, category: ImageCategory.contentPageImages), placeholderImage : UIImage(named: "Spacer"), contentMode: UIViewContentMode.scaleAspectFill, completion: { (image, error, cacheType, imageURL) in
                        
                        if image == nil {
                            cell.backgroundImageView.image = UIImage(named: "mm_white")
                            cell.backgroundImageView.backgroundColor = UIColor.gray
                            cell.backgroundImageView.contentMode = .center
                        }
                        else {
                            cell.backgroundImageView.backgroundColor = UIColor.clear
                        }
                        
                    })
                    
                    if let magazine = cell.magazine {
                        cell.initAnalytics(withViewKey: self.analyticsViewRecord.viewKey, impressionKey:AnalyticsManager.sharedManager.recordImpression(Context.getUserKey(), impressionRef: magazine.contentPageKey, impressionType: "ContentPage", impressionDisplayName: magazine.contentPageName, positionComponent: "ContentListing", positionIndex: indexPath.row + 1, positionLocation: "ContentListing", referrerRef: Context.getUserKey(), referrerType: nil, viewKey: self.analyticsViewRecord.viewKey))
                    }
                }
                
            } else {
                cell.magazine = MagazineCover()
                cell.backgroundImage = UIImage(named: "dummy-magazine-row-\(indexPath.item - magazines.count + 1)")
                cell.showLikeView(false)
            }
            
            cell.tag = indexPath.item
            
            // load more
            let pageTotal = magazineCoverList?.pageTotal ?? 0
            if indexPath.item >= magazines.count - 1 && pageTotal > currentPage {
                currentPage += 1
                loadViewData(currentPage);
            }
            
            return cell
        }
    }
    
    func handleLikeAction(isLike islike: Bool, sender: UIButton) {
        
        let isLike: Int = islike ? 1: 0
        if let magazin = magazines[sender.tag] as? MagazineCover {
            
            firstly {
                
                return self.actionLike(isLike, magazineCover: magazin)
                
                }.then { _ -> Void in
                    
                    magazin.isLike = islike
                    
                    if islike {
                        magazin.likeCount += 1
                    } else {
                        
                        magazin.likeCount -= 1
                    }
                    //                    self.collectionView.reloadData()
                    
                }.catch { _ -> Void in
                    
            }
            sender.initAnalytics(withViewKey: self.analyticsViewRecord.viewKey)
            sender.recordAction(.Tap, sourceRef: (islike ? "Like" : "Unlike"), sourceType: .Button, targetRef: magazin.contentPageKey, targetType: .ContentPage)
        }
        
    }
    
    /**
     action like on content page
     
     - parameter isLike:     1: 0
     - parameter contentKey: contetn page key
     
     - returns: Promize
     */
    func actionLike(_ isLike: Int, magazineCover: MagazineCover) -> Promise<Any>{
        
        return Promise{ fulfill, reject in
            MagazineService.actionLikeMagazine(isLike, contentPageKey: magazineCover.contentPageKey, completion: { (response) in
                if response.result.isSuccess{
                    if response.response?.statusCode == 200 {
                        
                        if let result = response.result.value as? [String: Any], (result["Success"] as? Int) == 1{
                            Log.debug("likePostCall OK" + magazineCover.contentPageKey)
                            
                            let pageLike = Fly.PageHotData()
                            pageLike.pageKey = magazineCover.contentPageKey
                            pageLike.isLike = isLike == 1
                            Fly.page.save(pageLike)
                            
                            //以下代码将废弃，使用Fly.page管理即可
                            if isLike == 1{
                                CacheManager.sharedManager.addLikedMagazieCover(magazineCover)
                            }
                            else{
                                CacheManager.sharedManager.removeLikedMagazieCover(magazineCover)
                            }
                            
                            fulfill("ok")
                        }
                        
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
                
            })
        }
    }
    
    func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        if collectionView == rightMenuCollectionView {
            // Right Category Magazine Collection
            hideRightCategoryView(sender: nil)
            
            let contentPageCollection: ContentPageCollection = contentPageCollectionList![indexPath.item] 
                showLoading()
                
                self.currentPage = 1
                
                firstly {
                    
                    return self.loadMagazineCovers(contentPageCollection.contentPageCollectionId)
                    
                    }.then { data -> Promise<Any> in
                        
                        return self.listLikedContentPage()
                        
                    }.then { _ -> Void in
                        
                        self.updateLikeForMagazinCover()
                        
                    }.then { _ -> Void in
                        
                        self.collectionView.scrollToTopAnimated(false)
                        self.collectionView.reloadData()
                        self.rightMenuCollectionView.reloadData()
                        
                    }.always {
                        self.stopLoading()
                    }.catch { _ -> Void in
                        Log.error("error")
                }
                if let cell = collectionView.cellForItem(at: indexPath) as? MagazineCategoryCell{
                    cell.initAnalytics(withViewKey: self.analyticsViewRecord.viewKey)
                    cell.recordAction(.Tap, sourceRef: String(format: "%d",(indexPath.row+1)), sourceType: .Collection, targetRef: "ContentListing", targetType: .View)
                }
                
            
        } else {
            // Magazine Collection
            if indexPath.item < magazines.count {
                let data = magazines[indexPath.item]
                
                if type(of: data) == MagazineCover.self {
                    let magazineContentVC = MagazineContentViewController()
                    magazineContentVC.magazineCover = data as? MagazineCover
                    self.navigationController?.push(magazineContentVC, animated: true)
                    
                    if let cell = collectionView.dequeueReusableCell(withReuseIdentifier: MagazineCell.CellIdentifier, for: indexPath) as? MagazineCell, let mangazine = magazineContentVC.magazineCover {
                        cell.recordAction(.Tap, sourceRef: mangazine.contentPageKey, sourceType: .ContentPage, targetRef: "ContentPage", targetType: .View)
                        
                    }
                }
            }
        }
    }
    
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, sizeForItemAt indexPath: IndexPath) -> CGSize {
        if collectionView == rightMenuCollectionView {
            // Right Magazine Category Collection
            return RightMenuCellSize
        } else {
            // Magazine Collection
            return CGSize.zero
        }
    }
    
    //    func scrollViewDidScroll(_ scrollView: UIScrollView) {
    //        for cell in collectionView!.visibleCells() {
    //            let cell:MagazineCell = cell as! MagazineCell
    //            let yOffset:CGFloat = ((collectionView!.contentOffset.y - cell.frame.origin.y) / cell.backgroundImageView.bounds.height) * 35.0
    //            cell.setBackgroundImageOffset(CGPoint(x: 0, y: yOffset))
    //
    //        }
    //    }
    
    //MARK - Actions
    
    @objc func searchIconClicked() {
        let searchViewController = ProductListSearchViewController()
        self.navigationController?.push(searchViewController, animated: false)
    }
    
    
    //MARK- get  liked content page list
    
    func listLikedContentPage(_ page: Int = 1) -> Promise<Any> {
        
        if !LoginManager.isValidUser() {
            return Promise { fullfill, reject in
                fullfill("OK")
            }
        }
        
        return Promise { fullfill, reject in
            MagazineService.viewContentPageListByUserKey(pageIndex: page, size: Constants.Paging.Offset, completion: {[weak self] (response) in
                if let strongSelf = self {
                    if response.result.isSuccess {
                        if response.response?.statusCode == 200 {
                            if let data = Mapper<ContentPageList>().map(JSONObject: response.result.value) {
                                if page == 1 {
                                    strongSelf.contentPageList = data
                                    
                                } else {
                                    var final = [MagazineCover]()
                                    if let pageData = strongSelf.contentPageList?.pageData {
                                        final += pageData
                                    }
                                    if let pageData = data.pageData {
                                        final += pageData
                                    }
                                    strongSelf.contentPageList?.pageData = final
                                }
                            }
                            fullfill("OK")
                        }
                        else {
                            var statusCode = 0
                            if let code = response.response?.statusCode {
                                statusCode = code
                            }
                            
                            let error = NSError(domain: "", code: statusCode, userInfo: nil)
                            reject(error)
                        }
                    } else{
                        reject(response.result.error!)
                    }
                } else {
                    ErrorLogManager.sharedManager.recordNonFatalError(withException: .NullPointer)
                }
                })
        }
    }
}

extension MagazineCollectionViewController: MMNavigationControllerDelegate {
    func preferredNavigationBarVisibility() -> MmFadeNavigationControllerNavigationBarVisibility? {
        return .hidden
    }
}
