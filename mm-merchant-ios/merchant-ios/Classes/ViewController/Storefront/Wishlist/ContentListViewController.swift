//
//  ContentListViewController.swift
//  merchant-ios
//
//  Created by Vu Dinh Trung on 6/14/16.
//  Copyright © 2016 WWE & CO. All rights reserved.
//

import UIKit
import ObjectMapper
import PromiseKit

class ContentListViewController: MmViewController {

    private static let NoCollectionItemCellID = "NoCollectionItemCellID"
    private static let LoadingCellIdentifier = "LoadingCell"
    
    private var pageCurrent = 0
    private var pageTotal = 0
    private var datasource = [MagazineCover]()
	private var firstLoaded = false
    private var shouldShowNoMagazine = false

    var viewHeight: CGFloat = 0
    
    //MARK:- Viewlife cycle
    override func viewDidLoad() {
        super.viewDidLoad()

		view.backgroundColor = UIColor.backgroundGray()
        initAnalyticLog()
        setupCollectionView()
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        resetPage()
		firstLoaded = true
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
    }
    
    //MARK:- Views
    func setupCollectionView() {
        self.collectionView.register(ContentItemViewCell.self, forCellWithReuseIdentifier: ContentItemViewCell.postCellIndentifier)
        self.collectionView.register(LoadingCollectionViewCell.self, forCellWithReuseIdentifier: ContentListViewController.LoadingCellIdentifier)
		self.collectionView.register(NoCollectionItemCell.self, forCellWithReuseIdentifier: ContentListViewController.NoCollectionItemCellID)
        self.collectionView.backgroundColor = UIColor.clear
        self.collectionView.alwaysBounceVertical = true
        self.collectionView.frame = CGRect(x: 0, y:0, width: Constants.ScreenSize.SCREEN_WIDTH, height: viewHeight)
        self.collectionView.delegate = self
        self.collectionView.dataSource = self
        self.view.frame = self.collectionView.frame
    }
    
    //MARK:- UICollectionView DataSource
    override func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
		if self.datasource.count == 0 && shouldShowNoMagazine {
			return 1
		}
        
        if pageCurrent < pageTotal {
            return datasource.count + 1
        }
        
        return datasource.count
    }
    
    override func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
		if self.datasource.count == 0 {
			let cell = collectionView.dequeueReusableCell(withReuseIdentifier: ContentListViewController.NoCollectionItemCellID, for: indexPath) as! NoCollectionItemCell
			cell.label.text = String.localize("LB_CA_COLLECTION_CONTENT_EMPTY")
			return cell
		}
		
        if indexPath.row == datasource.count {
            let cell = collectionView.dequeueReusableCell(withReuseIdentifier: ContentListViewController.LoadingCellIdentifier, for: indexPath) as! LoadingCollectionViewCell

            loadListContent(withPage: pageCurrent + 1)
            
            return cell
        } else {
            let cell = collectionView.dequeueReusableCell(withReuseIdentifier: ContentItemViewCell.postCellIndentifier, for: indexPath) as! ContentItemViewCell

            let magazineCover = datasource[indexPath.row]
            cell.setupData(magazineCover)
            cell.disableSwipeLeft = true
            
            cell.rightMenuItems = [
                SwipeActionMenuCellData(
                    text: String.localize("LB_CA_DELETE"),
                    icon: UIImage(named: "icon_swipe_delete"),
                    backgroundColor: UIColor.swipeActionColor.backgroundColor(swipeActionType: .delete),
                    defaultAction: true,
                    action: { [weak self, weak cell] in
                        if let strongSelf = self {
                            cell?.recordAction(.Tap, sourceRef: "Delete", sourceType: .Button, targetRef: "Confirmation", targetType: .Message)
                            Alert.alert(strongSelf, title: "", message: String.localize("LB_CA_COLLECTION_CONF_REMOVE_ARTICLE"), okActionComplete: { () -> Void in
                                strongSelf.unlikePage(magazineCover)
                            }, cancelActionComplete:nil)
                        } else {
                            ErrorLogManager.sharedManager.recordNonFatalError(withException: .NullPointer)
                        }
                    }
                )
            ]
            
            // Analytics
            let itemId = magazineCover.contentPageKey
            var title = magazineCover.contentPageName
            
            if title.length > 50 {
                title = (title as NSString).substring(to: 50)
            }
            
            let impressionKey = AnalyticsManager.sharedManager.recordImpression(  impressionRef: itemId, impressionType: "Article",  impressionDisplayName: title,   positionComponent: "ArticleListing", positionIndex: (indexPath.row + 1), positionLocation: "Collection",  viewKey: self.analyticsViewRecord.viewKey)
            cell.initAnalytics(withViewKey: self.analyticsViewRecord.viewKey, impressionKey: impressionKey)
            
            // handle tap post image
            cell.completionPostImageTapped = { [weak self] cell in
                if let strongSelf = self {
                    strongSelf.openMagazinePage(magazineCover: magazineCover, cell: cell)
                }
            }
            
            return cell
        }
    }
    
    //MARK:- UICollectionView Delegate
    func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        // Action tag
        if !datasource.isEmpty {
            if let cell = collectionView.cellForItem(at: indexPath) {
                let magazineCover = self.datasource[indexPath.row]
                self.openMagazinePage(magazineCover: magazineCover, cell: cell)
            } else {
                ErrorLogManager.sharedManager.recordNonFatalError(withException: .NullPointer)
            }
        }
    }
    
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, minimumInteritemSpacingForSectionAt section: Int) -> CGFloat {
        return 0.0
    }
    
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, minimumLineSpacingForSectionAt section: Int) -> CGFloat {
        return 0.0
    }
    
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, insetForSectionAt section: Int) -> UIEdgeInsets {
        return UIEdgeInsets.zero
    }
    
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, sizeForItemAt indexPath: IndexPath) -> CGSize {
		if self.datasource.count == 0 {
            var toolBarHeight: CGFloat = 0
            
            if let strongNavigationController = self.navigationController {
                toolBarHeight = strongNavigationController.toolbar.frame.height
            } else {
                ErrorLogManager.sharedManager.recordNonFatalError(withException: .NullPointer)
            }
            
			return CGSize(width: self.view.frame.size.width, height: self.view.height - toolBarHeight)
		}
        
		return CGSize(width: self.view.frame.size.width, height: ContentItemViewCell.CellHeight)
    }
    
    //MARK: - Helper
    func resetPage() {
        pageCurrent = 1
        datasource.removeAll()
        loadListContent(withPage: pageCurrent)
    }
    
    func unlikePage(_ page: MagazineCover) {
        firstly {
            return unlikePostAPI(page)
        }.then { _ -> Void in
            self.collectionView.setContentOffset(CGPoint.zero, animated: true)
            self.resetPage()
        }.catch { _ -> Void in
            Log.error("error")
        }
    }
    
    func unlikePostAPI(_ page: MagazineCover) -> Promise<Any> {
        return Promise { fulfill, reject in
            MagazineService.unlikePageContent(page: page, completion: { (response) in
                if response.result.isSuccess {
                    if response.response?.statusCode == 200 {
                        CacheManager.sharedManager.removeLikedMagazieCover(page)
                        
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
                    reject(response.result.error ?? NSError(domain: "", code: 0, userInfo: nil))
                }
            })
        }
    }
    
    func loadListContent(withPage page: Int) {
        // check login
        if LoginManager.getLoginState() == .validUser {
            if !firstLoaded {
                startBackgroundLoadingIndicator(collectionView)
            }
            
            firstly {
                return listContentPage(page: page)
            }.always {
                self.shouldShowNoMagazine = true
                DispatchQueue.main.async {
                    self.stopBackgroundLoadingIndicator()
                    self.collectionView.reloadData()
                }
                
            }
        }
    }
    
    func listContentPage(page pageIndex: Int) -> Promise<Any> {
        return Promise { fullfill, reject in
            MagazineService.viewContentPageListByUserKey(pageIndex: pageIndex, completion: {[weak self] (response) in
                if let strongSelf = self {
                    if response.result.isSuccess {
                        if response.response?.statusCode == 200 {
                            if let contentPageList = Mapper<ContentPageList>().map(JSONObject: response.result.value), let pageData =  contentPageList.pageData {
                                //将喜欢的页面缓存下
                                for magazineCover in pageData {
                                    let pageLike = Fly.PageHotData()
                                    pageLike.pageKey = magazineCover.contentPageKey
                                    pageLike.isLike = true
                                    Fly.page.save(pageLike)
                                }
                                
                                strongSelf.datasource.append(contentsOf: pageData)
                                strongSelf.pageCurrent = contentPageList.pageCurrent
                                strongSelf.pageTotal = contentPageList.pageTotal
                                
                            } else {
                                ErrorLogManager.sharedManager.recordNonFatalError(withException: .FailToParseAPIResponse)
                            }
                            
                            fullfill("OK")
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
    
    func openMagazinePage(magazineCover: MagazineCover, cell: UICollectionViewCell) {
        let id = magazineCover.contentPageKey
        if magazineCover.contentPageTypeId == 3 { // cms页面
            Navigator.shared.dopen(Navigator.mymm.deeplink_cms_native + "\(magazineCover.contentPageId)")
        } else { // type == 1 || 2  1:静态页面 2:magazine页面
            Navigator.shared.dopen(Navigator.mymm.deeplink_p_pageKey + magazineCover.contentPageKey)
        }
        cell.recordAction(.Tap, sourceRef: id, sourceType: .Article, targetRef: "ArticleDetail", targetType: .View)
    }

    //MARK: - Analytics Log
    private func initAnalyticLog(){
        initAnalyticsViewRecord(
            nil,
            authorType: nil,
            brandCode: nil,
            merchantCode: nil,
            referrerRef: nil,
            referrerType: nil,
            viewDisplayName: "\(Context.getUserProfile().userName)",
            viewParameters: "\(Context.getUserKey())",
            viewLocation: "Collection",
            viewRef: nil,
            viewType: "Content"
        )
    }
    
}
