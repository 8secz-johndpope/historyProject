//
//  PostListViewController.swift
//  merchant-ios
//
//  Created by Vu Dinh Trung on 6/14/16.
//  Copyright © 2016 WWE & CO. All rights reserved.
//

import UIKit
import PromiseKit
import ObjectMapper

class PostListViewController: MmViewController {

    private final let NoCollectionItemCellID = "NoCollectionItemCellID"
    
    private let defaultCellID = "defaultCellID"
    
    var indexPage = 1
    var viewHeight = CGFloat(0)
    
    let data = "" //TODO: data dummy let change later
    
    var pageNo = 1
    var postLists: [Post]!
    var hasLoadMore = false
	var firstLoaded = false
	
    override func viewDidLoad() {
        super.viewDidLoad()

		self.view.backgroundColor = UIColor.backgroundGray()

        setupCollectionView()
		
        postLists = [Post]()
        initAnalyticLog()
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        
        self.postLists.removeAll()
        pageNo = 1
        self.viewPostList(currentPage: pageNo)
		
		firstLoaded = true
    }
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }

    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
    }
    
    // MARK: - Remove Post
    
    func removePost(_ post: Post) {
        
        PostManager.didUnlikePost(post) { (error, likedCorrelationKey) in
            if let error = error {
                self.showError((error.userInfo["Error"] as? String) ?? String.localize("LB_ERROR"), animated: true)
            } else {
                PostManager.updateUserLikes(likedCorrelationKey, post: post, likeStatus: Constants.StatusID.deleted,isRefreshWishlish: false)
                PostManager.updateLocalUserPost(post)
                if let index = self.postLists.index(where: { $0.postId == post.postId }) {
                    let removedObject = self.postLists[index]
                    self.postLists.remove(removedObject)
                    DispatchQueue.main.async {
                        self.collectionView.reloadData()
                    }
                }
            }
        }
    }
    
    func refreshPostList() {
        pageNo = 1
        postLists.removeAll()
        self.viewPostList(currentPage: pageNo)
    }
    
    func setupCollectionView() {
        self.collectionView.register(PostListItemCell.self, forCellWithReuseIdentifier: PostListItemCell.postCellIndentifier)
		self.collectionView.register(NoCollectionItemCell.self, forCellWithReuseIdentifier: NoCollectionItemCellID)
		self.collectionView.backgroundColor = UIColor.clear
        self.collectionView.alwaysBounceVertical = true
        self.collectionView.frame = CGRect(x: 0, y:0, width: Constants.ScreenSize.SCREEN_WIDTH, height: viewHeight)
        self.collectionView.delegate = self
        self.collectionView.dataSource = self
        self.view.frame = self.collectionView.frame
        
        self.collectionView.register(UICollectionViewCell.self, forCellWithReuseIdentifier: defaultCellID)
    }
    
    override func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
		if self.postLists.count == 0 {
			return 1
		}
        
        return self.hasLoadMore ? self.postLists.count + 1 : self.postLists.count
    }
    
    override func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
		if self.postLists.count == 0 && firstLoaded {
			let cell = collectionView.dequeueReusableCell(withReuseIdentifier: NoCollectionItemCellID, for: indexPath) as! NoCollectionItemCell
			cell.label.text = String.localize("LB_CA_COLLECTION_POST_EMPTY")
			return cell
		}

        let cell = collectionView.dequeueReusableCell(withReuseIdentifier: PostListItemCell.postCellIndentifier, for: indexPath) as! PostListItemCell
        
        if indexPath.row == self.postLists.count {
            let cell = loadingCellForIndexPath(indexPath)
            
            if (!hasLoadMore) {
                cell.isHidden = true
            } else {
                cell.isHidden = false
                self.viewPostList(currentPage: pageNo)
            }
            
            return cell
        } else {
            if !postLists.isEmpty && postLists.indices.contains(indexPath.row){
                cell.setupData(postLists[indexPath.row])
                cell.disableSwipeLeft = true
                cell.leftMenuItems = [SwipeActionMenuCellData()]
                
                cell.rightMenuItems = [
                    SwipeActionMenuCellData(
                        text: String.localize("LB_CA_DELETE"),
                        icon: UIImage(named: "icon_swipe_delete"),
                        backgroundColor: UIColor(hexString: "#7A848C"),
                        defaultAction: true,
                        action: { [weak self, weak cell] () -> Void in
                            if let strongSelf = self {
                                cell?.recordAction(.Tap, sourceRef: "Delete", sourceType: .Button, targetRef: "Confirmation", targetType: .Message)
                                
                                Alert.alert(strongSelf, title: "", message: String.localize("LB_CA_COLLECTION_CONF_REMOVE_POST"), okActionComplete: { () -> Void in
                                    if strongSelf.postLists.indices.contains(indexPath.row) {
                                        let post = strongSelf.postLists[indexPath.row]
                                        strongSelf.removePost(post)
                                    }
                                }, cancelActionComplete:nil)
                            } else {
                                ErrorLogManager.sharedManager.recordNonFatalError(withException: .NullPointer)
                            }
                        }
                    )
                ]
                
                // Analytics
                let postItem: Post = postLists[indexPath.row]
                let user = postItem.user
                let merchant = postItem.merchant
                var authorType = "User"
                
                if user != nil {
                    if user?.isCurator == 1 {
                        authorType = "Curator"
                    } else if user?.isMerchant == 1 {
                        authorType = "MerchantUser"
                    }
                }
                
                var postText = postItem.postText
                
                if postText.length > 50 {
                    postText = (postText as NSString).substring(to: 50)
                }
                
                let impressionKey = AnalyticsManager.sharedManager.recordImpression(postItem.user?.userKey, authorType: authorType,  impressionRef: String(format: "%d",postItem.postId), impressionType: "Post", impressionDisplayName: postText, merchantCode: merchant?.merchantCode,  positionComponent: "PostListing", positionIndex: (indexPath.row + 1), positionLocation: "Collection", referrerRef: user?.userKey, referrerType: authorType, viewKey: self.analyticsViewRecord.viewKey)
                cell.initAnalytics(withViewKey: self.analyticsViewRecord.viewKey, impressionKey:impressionKey)
            }
        }
        
        // go to brand profile
        cell.brandLabelHandler = { [weak self] (data) in
            Log.debug(data)
            if let stringSelf = self {
                let post = stringSelf.postLists[indexPath.row]
                stringSelf.pushMerchantById(post.merchantId, fromViewController: stringSelf)
            }
        }
        
        return cell
    }
    
    func pushMerchantById(_ merchantId: Int, fromViewController viewController: UIViewController) {
        
        MerchantService.view(merchantId) { (response) in
            
            if response.result.isSuccess {
                if response.response?.statusCode == 200 {
                    if let array = response.result.value as? [[String: Any]], let obj = array.first , let merchant = Mapper<Merchant>().map(JSONObject: obj) {
                        Navigator.shared.dopen(Navigator.mymm.website_merchant_merchantId + "\(merchant.merchantId)")
                    } else {
                        ErrorLogManager.sharedManager.recordNonFatalError(withException: .NullPointer)
                    }
                }
            }
        }
    }
    
    func loadingCellForIndexPath(_ indexPath: IndexPath) -> UICollectionViewCell {
        let cell = getDefaultCell(self.collectionView, cellForItemAt: indexPath)
        let activity = UIActivityIndicatorView(activityIndicatorStyle: UIActivityIndicatorViewStyle.gray)
        activity.frame = CGRect(x: (cell.frame.sizeWidth - activity.frame.sizeWidth) / 2, y: (cell.frame.sizeHeight - activity.frame.sizeHeight) / 2, width: activity.frame.sizeWidth, height: activity.frame.sizeHeight)
        cell.addSubview(activity)
        activity.startAnimating()
        
        return cell
    }
    
    func getDefaultCell(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell{
        let cell = collectionView.dequeueReusableCell(withReuseIdentifier: defaultCellID, for: indexPath)
        return cell
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
    
    // MARK: Item Size Delegate for Collection View
    
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, sizeForItemAt indexPath: IndexPath) -> CGSize {
		if self.postLists.count == 0 {
			return CGSize(width: self.view.frame.size.width , height: self.view.height - ((self.navigationController?.toolbar.frame.height) ?? 0))
		}
        
		return CGSize(width: self.view.frame.size.width , height: PostListItemCell.CellHeight)
    }
    
    func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        didSelectedItemAtIndexPath(indexPath)
    }
    
    func didSelectedItemAtIndexPath(_ indexPath: IndexPath) {
        if !postLists.isEmpty {
            let data = postLists[indexPath.row]
            let postId = data.postId

            Navigator.shared.dopen(Navigator.mymm.deeplink_f_postId + "\(postId)")
            
            if let cell = self.collectionView.cellForItem(at: indexPath) as? PostListItemCell {
                cell.analyticsImpressionKey = nil
                cell.recordAction(.Tap, sourceRef: String(format: "%d",postId), sourceType: .Post, targetRef: "PostDetail", targetType: .View)
            } else {
                ErrorLogManager.sharedManager.recordNonFatalError(withException: .NullPointerOrTypeMismatch)
            }
        }
    }
    
    func reloadData() {
        DispatchQueue.main.async {
            self.collectionView.reloadData()
        }
    }
    
    // MARK: Override
    
    override func showLoading() {
        self.showLoadingInScreenCenter()
    }
    
    //MARK: API
    
    /**
     get data post liked
     - check user login
     */
    func viewPostList(currentPage pageNo: Int) {
        if LoginManager.getLoginState() == .validUser {
            if !firstLoaded{
                self.startBackgroundLoadingIndicator(self.collectionView)
            }
            firstly {
                return getPostList(currentPage: pageNo)
            }.then { postIds -> Promise<Any> in
                return self.fetchPostByPostIds((postIds as? String) ?? "")
            }.always {
                self.stopBackgroundLoadingIndicator()
                self.reloadData()
            }.catch { _ -> Void in
                Log.error("error")
                self.stopBackgroundLoadingIndicator()
            }
        }
    }
    
    func getPostList(currentPage pageNo: Int) -> Promise<Any> {
        return Promise { fullfill, reject in
			 PostManager.getPostLikedObjects(self.pageNo, completion: { [weak self] (response) in
				if let _ = self {
					let postList: [PostLike] = response 
					var postIds = ""
                    
					if postList.count > 0 {
						for i in 0..<postList.count {
							if let id = postList[i].postId {
								if i == postList.count - 1 {
									postIds += String(format: "%d", id)
								} else {
									postIds += String(format: "%d", id) + ","
								}
                            } else {
                                ErrorLogManager.sharedManager.recordNonFatalError(withException: .NullPointer)
                            }
						}
                        if let strongSelf = self {
                            strongSelf.hasLoadMore = postList.count >= Constants.Paging.LikeListOffset
                            
                            if strongSelf.hasLoadMore {
                                strongSelf.pageNo = strongSelf.pageNo + 1
                            }
                        }
						fullfill(postIds)
					} else {
                        if let strongSelf = self {
                            strongSelf.hasLoadMore = false
                        }
						let error = NSError(domain: "", code: 999, userInfo: nil)
						reject(error)
					}
                } else {
                    ErrorLogManager.sharedManager.recordNonFatalError(withException: .NullPointer)
                }
			})
        }
    }
    
    func getPostIds() ->String {
        var postIds = ""
        
        if self.postLists.count > 0 {
            for i  in 0..<self.postLists.count {
                let id = self.postLists[i].postId
                
                if i == self.postLists.count - 1 {
                    postIds += String(format: "%d", id)
                } else {
                    postIds += String(format: "%d", id) + ","
                }
            }
        }
        
        return postIds
    }
    
    /**
     get post by posdIds postids = 123, 134
     
     - parameter postIds: String
     
     - returns: list Post liked
     */
    
    func fetchPostByPostIds(_ postIds: String) -> Promise<Any> {
        return Promise { fullfill, reject in
            NewsFeedService.fetchPostLikedByPostIds(postIds, pageSize: Constants.Paging.LikeListOffset, completion: { [weak self] (response) in
                if let strongSelf = self {
                    if response.result.isSuccess {
                        if response.response?.statusCode == 200 {
                            if let newsFeed: NewsFeedListResponse = Mapper<NewsFeedListResponse>().map(JSONObject: response.result.value) {
                                let pageData:[Post] = newsFeed.pageData ?? []
                                
                                var postLikeLists = [Post]()
                                if !pageData.isEmpty {
                                    for item in pageData {
                                        if PostManager.isLikeThisPost(item) {
                                            postLikeLists.append(item)
                                        }
                                    }
                                    
                                }
                                
                                strongSelf.postLists.append(contentsOf: postLikeLists)
                                
                                fullfill("ok")
                            } else {
                                ErrorLogManager.sharedManager.recordNonFatalError(withException: .FailToParseAPIResponse)
                                
                                let error = NSError(domain: "", code: -999, userInfo: nil)
                                reject(error)
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
                } else {
                    ErrorLogManager.sharedManager.recordNonFatalError(withException: .NullPointer)
                }
            })
        }
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
            viewParameters: "u=\(Context.getUserProfile().userKey)",
            viewLocation: "Collection",
            viewRef: nil,
            viewType: "Post"
        )
    }

}
