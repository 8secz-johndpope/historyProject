//
//  CuratorCollectionViewController.swift
//  merchant-ios
//
//  Created by khanh.nguyen on 6/16/16.
//  Copyright © 2016 WWE & CO. All rights reserved.
//

import UIKit
import PromiseKit
import ObjectMapper

class CuratorCollectionViewController: MmViewController {
    
    private final let FilterCuratorCellId = "FilterCuratorCellId"
    private final let CellId = "CellId"
    
    var datasources = [Curator]() {
        didSet {
            if self.collectionView != nil {
                self.collectionView.reloadData()
            }
        }
    }
    var start: Int = 0
    var limit: Int = Constants.Paging.Offset
    var hasLoadMore = false
    var isMoreLoad = false
    var topOffsetY: CGFloat = 0
    static let Padding = CGFloat(13)
    var filterMode : FilterCuratorMode = FilterCuratorMode.recommended
    private var needReloadData = false
    var viewHeight = CGFloat(0)
    
    override func viewDidLoad() {
        super.viewDidLoad()
        self.createBackButton()
        self.configCollectionView()
        initAnalyticLog()
        NotificationCenter.default.addObserver(self, selector: #selector(self.followingDidUpdate), name: Constants.Notification.followingDidUpdate, object: nil)
        
        self.reloadDatasources()
        
        self.view.height = viewHeight
    }
    
    override func shouldHaveCollectionView() -> Bool {
        return true
    }
 
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        if self.needReloadData {
            self.needReloadData = false
        }
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        //        super.viewWillDisappear(animated)
        viewIsAppearing = false
        
        self.dismissKeyboardFromView()
        
        NotificationCenter.default.removeObserver(self, name: NSNotification.Name(rawValue: "refreshShoppingCartFinished"), object: nil)
        NotificationCenter.default.removeObserver(self, name: NSNotification.Name(rawValue: "refreshWishListFinished"), object: nil)
        
        if let _ = dismissKeyboardGesture {
            NotificationCenter.default.removeObserver(self)
        }
        
    }
    
    func configCollectionView() -> Void {
        
        let layout = UICollectionViewFlowLayout()
        layout.sectionInset = UIEdgeInsets.zero
        layout.scrollDirection = .vertical
        
        let statusBarHeight = UIApplication.shared.statusBarFrame.size.height
        
        self.collectionView.setCollectionViewLayout(layout, animated: false)
        self.collectionView.frame = CGRect(x: 0, y: 0, width: self.view.bounds.width, height: self.view.frame.size.height - tabBarHeight - topOffsetY - statusBarHeight)
        
        self.collectionView.register(FilterCuratorCell.self, forCellWithReuseIdentifier: FilterCuratorCellId)
        self.collectionView.register(UICollectionViewCell.self, forCellWithReuseIdentifier: CellId)
        self.view.addSubview(collectionView)
        self.collectionView.backgroundColor = UIColor.white
    }
    
    func reloadDatasources() {
        self.start = 0
        datasources.removeAll()
        fetchList()
    }
    func fetchList() -> Void {
        firstly {
                return getCuratorList()
            }.then { (_) -> Promise<[String]> in
                return FollowService.listFollowingUserKeys(useCacheOnlyIfAny: true)
            }.always {
                self.collectionView.reloadData()
            }.catch { _ -> Void in
                Log.error("error")
        }
    }
    
    @discardableResult
    func getCuratorList() -> Promise<Any> {
        
        return Promise{ fulfill, reject in
            if self.filterMode == .recommended {
                UserService.getRecommendedList (start: self.start, limit: self.limit, completion: { [weak self] (response) in
                    if let strongSelf = self {
                        if response.result.isSuccess {
                            if response.response?.statusCode == 200 {
                                let curatorList:[Curator] = Mapper<Curator>().mapArray(JSONObject: response.result.value) ?? []
                                
                                strongSelf.datasources.append(contentsOf: curatorList)
                                strongSelf.hasLoadMore = (curatorList.count >= strongSelf.limit)
                                strongSelf.start += strongSelf.limit
                                
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
                    })
            } else {
                UserService.getAllPopularCuratorList (start: self.start, limit: self.limit, completion: { [weak self] (response) in
                    if let strongSelf = self {
                        if response.result.isSuccess {
                            if response.response?.statusCode == 200 {
                                let curatorList:[Curator] = Mapper<Curator>().mapArray(JSONObject: response.result.value) ?? []
                                
                                strongSelf.datasources.append(contentsOf: curatorList)
                                strongSelf.hasLoadMore = (curatorList.count >= strongSelf.limit)
                                strongSelf.start += strongSelf.limit
                                
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
                    })
            }
        }
    }
    
    func openCuratorProfile(_ curator : Curator) -> Void {
        let publicProfileVC = CuratorProfileViewController()
        publicProfileVC.currentType = curator.userKey == Context.getUserKey() ? .Private : .Public
        let user = User()
        user.userKey = curator.userKey
        user.userName = curator.userName
        user.displayName = curator.displayName
        user.isCurator = 1
        if publicProfileVC.currentType ==  .Private{
            Navigator.shared.dopen(Navigator.mymm.website_account)
//            publicProfileVC.publicUser =  user
//            publicProfileVC.isHideTabBar = true
//            if curator.userKey == Context.getUserKey() {
//                publicProfileVC.user = user
//            }
//            self.navigationController?.pushViewController(publicProfileVC, animated: true)
        }else{
            PushManager.sharedInstance.goToProfile(user, hideTabBar: true)
        }
        
        
        
    }
    
    //MARK:- CollectionView Methods
    override func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return datasources.count
    }
    
    override func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        if indexPath.row == datasources.count - 1 && hasLoadMore {
            self.getCuratorList()
            return loadingCellForIndexPath(indexPath)
        }
        
        if let cell = collectionView.dequeueReusableCell(withReuseIdentifier: FilterCuratorCellId, for: indexPath) as? FilterCuratorCell {
            let curator = datasources[indexPath.row]
            cell.curator = curator
            let viewKey = self.analyticsViewRecord.viewKey
            cell.analyticsViewKey = viewKey
            cell.initAnalytics(withViewKey: viewKey, impressionKey: AnalyticsManager.sharedManager.recordImpression(impressionRef: "\(curator.userKey)", impressionType: "Curator", impressionDisplayName: curator.displayName, positionComponent: "CuratorListing", positionIndex: indexPath.row + 1, positionLocation: self.currentViewLocation(), viewKey: viewKey))
            
            return cell
        }else {
            return UICollectionViewCell()
        }
    }
    
    func getDefaultCell(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell{
        let cell = collectionView.dequeueReusableCell(withReuseIdentifier: CellId, for: indexPath)
        return cell
    }
    
    func loadingCellForIndexPath(_ indexPath: IndexPath) -> UICollectionViewCell {
        let cell = getDefaultCell(self.collectionView, cellForItemAt: indexPath)
        let activity = UIActivityIndicatorView(activityIndicatorStyle: .gray)
        activity.frame = CGRect(x:(cell.frame.sizeWidth - activity.frame.sizeWidth) / 2, y: (cell.frame.sizeHeight - activity.frame.sizeHeight) / 2, width: activity.frame.sizeWidth, height: activity.frame.sizeHeight)
        cell.addSubview(activity)
        activity.startAnimating()
        return cell
    }
    
    func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        let data = datasources[indexPath.row]
        self.openCuratorProfile(data)
        
        if let cell = collectionView.cellForItem(at: indexPath) {
            cell.recordAction(
                .Tap,
                sourceRef: data.userKey,
                sourceType: .Curator,
                targetRef: "CPP",
                targetType: .View
            )
        }
        //implement the action on parent controlller
        
    }
    
    //MARK: - Collection Layout
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, minimumInteritemSpacingForSectionAt section: Int) -> CGFloat {
        return CuratorCollectionViewController.Padding
    }
    
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, minimumLineSpacingForSectionAt section: Int) -> CGFloat {
        return CuratorCollectionViewController.Padding
    }
    
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, insetForSectionAt section: Int) -> UIEdgeInsets {
        return UIEdgeInsets(top: CuratorCollectionViewController.Padding, left: CuratorCollectionViewController.Padding, bottom: 0.0, right: CuratorCollectionViewController.Padding)
    }
    
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, sizeForItemAt indexPath: IndexPath) -> CGSize {
        let midSpacing : CGFloat = CuratorCollectionViewController.Padding
        let height = (self.collectionView.frame.size.width - midSpacing - CuratorCollectionViewController.Padding * 2) / 2
        return CGSize(width: self.collectionView.frame.size.width - 2 * CuratorCollectionViewController.Padding, height: height)
    }
    
    // MARK: Logging
    func initAnalyticLog(){
        
        initAnalyticsViewRecord(
            nil,
            authorType: nil,
            brandCode: nil,
            merchantCode: nil,
            referrerRef: nil,
            referrerType: nil,
            viewDisplayName: "User: \(Context.getUserProfile().displayName)",
            viewParameters: Context.getUserProfile().userKey,
            viewLocation: self.currentViewLocation(),
            viewRef: nil,
            viewType: "Curator"
        )
    }
    
    func currentViewLocation() -> String{
        let viewLocation = "AllCurators-Recommended"
        return viewLocation
    }
    
    //MARK: Handle update following event
    @objc func followingDidUpdate() {
        needReloadData = true
    }
}
