//
//  PostDetailViewController.swift
//  merchant-ios
//
//  Created by Sang Nguyen on 6/13/16.
//  Copyright © 2016 WWE & CO. All rights reserved.
//

import UIKit
import PromiseKit
import ObjectMapper
import Kingfisher
import Alamofire

class PostDetailViewController: MmViewController, FilterStyleDelegate, MoreCommentFooterViewDelegate, PostCommentDetailCellDelegate, PinterestLayoutDelegate, UITextFieldDelegate {
    
    enum Section: Int {
        case PostImage = 0
        case PostDetail = 1
        case Comment = 2
        case PostRelated = 3 //Section post related
    }
    private final let MaxRelatedPosts = 20
    private final let MaxLatestComments = 10
    private final let HeightBaseCommentCell : CGFloat = 70
    private final let LowerLabelMinHeight : CGFloat = 24
    private final let HeightItemBar : CGFloat = 25
    private final let WidthItemBar : CGFloat = 30
    private final let HeightFooterView: CGFloat = 65
    private final let PostItemCollectionViewCellIdentifier = "PostItemCollectionViewCell"
    private final let NoCollectionItemCellID = "NoCollectionItemCellID"
    private final let HeaderViewIdentifier = "HeaderViewIdentifier"
    private var paidOrder: ParentOrder?
    private var filterdComments : [PostCommentList] = []
    private var commentList : [PostCommentList] = []
    private var userTag: String = ""
    private var imageSize: [UIImage] = []
    
    var postId : Int = 0
    var post: Post? = nil
    var isComeFromDeepLink = true //if value is false, Page will not display Search, Cart button
    var user : User?
    var postDetailManager: PostManager!
    var postRelatedManager : PostManager!
    var referrerUserKey: String?
    var firstLoaded = false
    var bottomView = AddCommentView()
    var gestureHideKeyboard: UITapGestureRecognizer?
    private var hasLoadMore = true
    private var pageNo : Int = 1
    var selectedIndex = -1
    var imagesSizes : [CGSize] = []
    
    convenience init(postId: Int){
        self.init()
        self.postId = postId
    }
    
    //MARK: Life Cycle
    override func viewDidLoad() {
        super.viewDidLoad()
        
        if let postId = ssn_Arguments["postId"]?.int {
            self.postId = postId
        }
        
        initAnalyticLog()
        setupNavigationBar()
        
        
        
        //        for images in post.images {
        //            UIImage.imageFromURL(ImageURLFactory.URLSize1000(image, category: .Post).absoluteString!, placeholder: UIImage(named: "default_cover")!, shouldCacheImage: true,noGetMain:true) {[weak self]
        //                (image: UIImage?) in
        //                if let strongSelf = self{
        //                    if image == nil {
        //                        return
        //                    }
        //                    strongSelf.imageSize = CGSizeMake(ScreenWidth, (image?.size.height)! / (image?.size.width)! * ScreenWidth)
        //                    strongSelf.collectionView.reloadSections(NSIndexSet(index: indexPath.section))
        //
        //                }
        //
        //            }
        //
        //        }
        
        configCollectionView()
        self.title = getPageTitle()
        postDetailManager = PostManager(postFeedTyle: .postDetail, postId: String(self.postId), collectionView: self.collectionView, viewController: self)
        postDetailManager.postIdsExpanded.append(postId) //MM-23754 Force expand post for post detail
        
        //Related Posts
        postRelatedManager = PostManager(postFeedTyle: .hashTag, postId:String(self.postId), collectionView: self.collectionView, viewController: self)
        
        self.addBottomView()
        self.setupDismissKeyboardGesture()
        
        gestureHideKeyboard = UITapGestureRecognizer(target: self, action: #selector(PostDetailViewController.hideKeyBoard))
        user = Context.getUserProfile()
        bottomView.shareButton.addTarget(self, action: #selector(self.didClickShareButton), for: .touchUpInside)
        bottomView.heartButton.addTarget(self, action: #selector(self.didClickedLike), for: .touchUpInside)
        
    }
    
    func getPageTitle() -> String {
        return String.localize("LB_CAPP_POST")
    }
    
    @objc func hideKeyBoard() {
        self.view.endEditing(true)
    }
    
    func addBottomView() {
        bottomView.frame = CGRect(x:0, y: self.view.bounds.sizeHeight - AddCommentView.ViewHeight - ScreenBottom, width: self.view.bounds.width, height: AddCommentView.ViewHeight + ScreenBottom)
        bottomView.textField.delegate = self
        view.addSubview(bottomView)
    }
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        if let navigationController = self.navigationController {
            navigationController.isNavigationBarHidden = false
        }
        self.navigationItem.setHidesBackButton(true, animated: false)
        
        self.updateNewsFeed()
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        
        //Un-load style to refresh style next time appear
        self.post?.styles = nil
    }
    
    //MARK: Create UI Region
    func configCollectionView() {
        self.collectionView.delegate = self
        self.collectionView.dataSource = self
        var navigationBarHeight: CGFloat = 20
        if let navigationBar = self.navigationController?.navigationBar {
            navigationBarHeight += navigationBar.frame.height
        }
        self.collectionView.frame = CGRect(x: 0 , y: navigationBarHeight, width: self.view.bounds.width, height: self.view.bounds.height - (tabBarHeight + navigationBarHeight + AddCommentView.ViewHeight))
        self.collectionView.backgroundColor = UIColor.primary2()
        // Setup Cell
        self.collectionView.register(NewsFeedDetailImagesCell.self, forCellWithReuseIdentifier: "NewsFeedDetailImagesCell")
        self.collectionView.register(NewsFeedDetailCell.self, forCellWithReuseIdentifier: NewsFeedDetailCell.CellIdentifier)
        self.collectionView.register(NoCollectionItemCell.self, forCellWithReuseIdentifier: NoCollectionItemCellID)
        self.collectionView?.register(PostCommentDetailCell.self, forCellWithReuseIdentifier: PostCommentDetailCell.CellIdentifier)
        self.collectionView!.register(MoreCommentFooterView.self, forSupplementaryViewOfKind: UICollectionElementKindSectionFooter, withReuseIdentifier: MoreCommentFooterView.FooterViewID)
        self.collectionView.register(PostDetailHeaderView.self, forSupplementaryViewOfKind: UICollectionElementKindSectionHeader, withReuseIdentifier: HeaderViewIdentifier)
        if let layout = collectionView.collectionViewLayout as? PinterestLayout {
            layout.delegate = self
        }
    }
    
    override func getCustomFlowLayout() -> UICollectionViewFlowLayout {
        let layout = PinterestLayout()
        layout.delegate = self
        return layout
    }
    
    func setupNavigationBar() {
        
        self.createBackButton()
        
        let ButtonHeight = CGFloat(25)
        let ButtonWidth = CGFloat(30)
        let optionButton = UIButton(type: .custom)
        optionButton.setImage(UIImage(named: "sdp_more"), for: UIControlState.normal)
        optionButton.addTarget(self, action: #selector(self.didClickedOptions), for: .touchUpInside)
        optionButton.frame = CGRect(x:0, y: 0, width: ButtonWidth, height: ButtonHeight)
        
        optionButton.contentEdgeInsets = UIEdgeInsets(top: 0, left: 0, bottom: 0, right: -14)
        
        var rightButtonItems = [UIBarButtonItem]()
        rightButtonItems.append(UIBarButtonItem(customView: optionButton))
        self.navigationItem.rightBarButtonItems = rightButtonItems
    }
    
    func createButtonBar(_ imageName: String, selectorName: Selector, size:CGSize,left: CGFloat, right: CGFloat) -> UIBarButtonItem {
        let button: UIButton = UIButton()
        button.setImage(UIImage(named: imageName), for: .normal)
        button.frame = CGRect(x:0, y: 0, width: size.width, height: size.height)
        button.contentEdgeInsets = UIEdgeInsets.init(top: 0, left: left, bottom: 0, right: right)
        button .addTarget(self, action: selectorName, for: UIControlEvents.touchUpInside)
        let barButtonItem:UIBarButtonItem = UIBarButtonItem()
        barButtonItem.customView = button
        return barButtonItem
    }
    //MARK: - View Actions
    
    @objc func didClickedLike(sender: UIButton) {
        sender.initAnalytics(withViewKey: self.analyticsViewRecord.viewKey)
        
        if let post = self.post {
            
            if self.postDetailManager.isUserAuthenticated() {
                let correlationKey = PostManager.correlationKeyOfPostLiked(post)
                if (correlationKey.length > 0) { //isLiked -> Unlike action
                    
                    //Analytics records
                    sender.recordAction(.Tap, sourceRef: "Unlike", sourceType: .Button, targetRef: "\(post.postId)", targetType: .Post)
                    
                    //update UI first
                    post.likeCount = max(post.likeCount - 1, 0)
                    self.bottomView.countLabel.text = "\(post.likeCount)"
                    self.bottomView.heartButton.isSelected = false
                    self.bottomView.layoutSubviews()
                    PostManager.updateUserLikes(correlationKey, post: post, likeStatus: Constants.StatusID.deleted)
                    
                    //call api
                    PostManager.changeLikeStatusNewsfeedPost(self.post!, likeStatus: Constants.StatusID.deleted, correlationKey: correlationKey).then { (_) -> Void in
                        
                        }.catch { error in
                            //rollback
                            post.likeCount += 1
                            PostManager.updateUserLikes(correlationKey, post: post, likeStatus: Constants.StatusID.active)
                            self.bottomView.countLabel.text = "\(post.likeCount)"
                    }
                }else{//Like post action
                    //generate like correlationkey
                    let correlationKey = Utils.UUID()
                    
                    sender.recordAction(.Tap, sourceRef: "Like", sourceType: .Button, targetRef: "\(post.postId)", targetType: .Post)
                    
                    //update UI first
                    post.likeCount += 1
                    PostManager.updateUserLikes(correlationKey, post: post, likeStatus: Constants.StatusID.active)
                    self.bottomView.countLabel.text = "\(post.likeCount)"
                    self.bottomView.heartButton.isSelected = true
                    self.bottomView.layoutSubviews()
                    
                    //call api
                    PostManager.changeLikeStatusNewsfeedPost(self.post!, likeStatus: Constants.StatusID.active, correlationKey: correlationKey).then { (likedCorrelationKey) -> Void in
                        
                        }.catch { error in
                            
                            //rollback
                            PostManager.updateUserLikes(correlationKey, post: post, likeStatus: Constants.StatusID.deleted)
                            post.likeCount = max(post.likeCount - 1, 0)
                            self.bottomView.countLabel.text = "\(post.likeCount)"
                            self.bottomView.layoutSubviews()
                    }
                }
            }
        }
    }
    
    func sendComment() {
        if LoginManager.getLoginState() != .validUser {
            LoginManager.goToLogin()
            return
        }
        
        if let commentext: String = bottomView.textField.text {
            if commentext.length > 0 {
                let comment = PostCommentList()
                comment.postId = self.post?.postId ?? 0
                comment.postCommentText = commentext
                self.createNewComment(comment)
                bottomView.textField.text = ""
            }
        }
        
        bottomView.textField.resignFirstResponder()
    }
    
    @objc func didClickShareButton(sender: UIButton) {
        if let post = self.post {
            sender.initAnalytics(withViewKey: self.analyticsViewRecord.viewKey)
            sender.recordAction(.Tap, sourceRef: "Share", sourceType: .Button, targetRef: "\(post.postId)", targetType: .Post)
            postDetailManager.didClickedShare(post)
        }
    }
    
    @objc func didClickedOptions() {
        
        if let post = self.post {
            let optionMenu = UIAlertController(title: nil, message: nil, preferredStyle: .actionSheet)
            let alertDeleteController = UIAlertController(title: nil, message: String.localize("LB_DELETE_POST_MESSAGE"), preferredStyle: UIAlertControllerStyle.alert)
            alertDeleteController.view.tintColor = UIColor.alertTintColor()
            let cancelDeleteAction = UIAlertAction(title: String.localize("LB_CA_CANCEL"), style: .cancel, handler: {
                (alert: UIAlertAction!) -> Void in
                
            })
            
            
            let confirmDeleteAction = UIAlertAction(title: String.localize("LB_CA_POST_DELETE"), style: .default, handler: {
                (alert: UIAlertAction!) -> Void in
                
                firstly {
                    return self.postDetailManager.deleteNewsFeed(String(post.postId))
                    }.then { _ -> Void in
                        post.statusId = Constants.StatusID.deleted.rawValue
                        post.lastModified = Date()
                        PostManager.updateLocalUserPostStatusChanged(post)
                        self.navigationController?.popViewController(animated: true)
                    }.catch { _ -> Void in
                        Log.error("error")
                }
                
            })
            
            alertDeleteController.addAction(cancelDeleteAction)
            alertDeleteController.addAction(confirmDeleteAction)
            
            
            let deleteAction = UIAlertAction(title: String.localize("LB_CA_POST_DELETE"), style: .default, handler: {
                (alert: UIAlertAction!) -> Void in
                self.present(alertDeleteController, animated: true, completion: nil)
            })
            
            
            let reportAction = UIAlertAction(title: String.localize("LB_CA_POST_REPORT"), style: .default, handler: {
                (alert: UIAlertAction!) -> Void in
                
                if self.postDetailManager.isUserAuthenticated(){
                    let controller = ReportFeedViewController()
                    controller.postId = post.postId
                    
                    self.navigationController?.pushViewController(controller, animated: true)
                }
            })
            
            let cancelAction = UIAlertAction(title: String.localize("LB_CA_CANCEL"), style: .cancel, handler: {
                (alert: UIAlertAction!) -> Void in
            })
            
            if let author = post.user, author.userKey == Context.getUserKey(){
                optionMenu.addAction(deleteAction)
            }else{
                optionMenu.addAction(reportAction)
            }
            optionMenu.addAction(cancelAction)
            
            optionMenu.view.tintColor = UIColor.secondary2()
            
            self.present(optionMenu, animated: true, completion: nil)
            optionMenu.view.tintColor = UIColor.alertTintColor()
        }
    }
    
    //MARK: Bar Button action
    @objc func onBackButton() {
        self.navigationController?.popViewController(animated:true)
    }
    
    func searchIconClicked(){
        let searchStyleController = SearchStyleController()
        searchStyleController.styles = [Style()]
        searchStyleController.filterStyleDelegate = self
        self.navigationController?.pushViewController(searchStyleController, animated: false)
    }
    
    //MARK: PostCommentViewCellDelegate
    
    
    func deleteCommentAction(_ collectionViewCell: UICollectionViewCell, index: Int){
        if index < self.filterdComments.count {
            let postCommentList =  self.filterdComments[index]
            
            var targetRef : String? = nil
            targetRef = postCommentList.correlationKey
            collectionViewCell.recordAction( .Tap, sourceRef: "DeleteComment", sourceType: .Button, targetRef: targetRef, targetType: .Comment)
            
            self.showLoading()
            firstly{
                return PostManager.changePostCommentStatus(postCommentList, statusId: Constants.StatusID.deleted.rawValue)
                }.then { _ -> Void in
                    Log.debug("success")
                    postCommentList.statusId = Constants.StatusID.deleted.rawValue
                    postCommentList.postCommentId = nil
                    postCommentList.lastModified = Date()
                    if let post = self.post {
                        if let localComments = PostManager.getLocalCommentByPostId(self.post?.postId) {
                            if localComments.filter({$0.correlationKey == postCommentList.correlationKey}).count == 0 {
                                PostManager.insertLocalPostCommentList(postCommentList, post: post)
                            } else {
                                PostManager.updatePostCommentCount(post, latestOwnComments: [postCommentList]) //TODO: need to verify
                            }
                        } else {
                            PostManager.insertLocalPostCommentList(postCommentList, post: post)
                        }
                    }
                    self.reloadDataSource()
                } .always {
                    self.stopLoading()
                }.catch { _ -> Void in
                    Log.error("error")
                    
            }
        }
        
    }
    
    func deleteClicked(_ collectionViewCell: UICollectionViewCell, index: Int) {
        
        UIView.animate(withDuration: 0.5, animations: {
            collectionViewCell.backgroundColor = UIColor.lightText
        }) { (completion) in
            var message = ""
            if index < self.filterdComments.count {
                let comment =  self.filterdComments[index]
                message = comment.postCommentText
                let maxLengthOfText = 45
                if maxLengthOfText < comment.postCommentText.length && maxLengthOfText > 0 {
                    message = (comment.postCommentText as NSString).substring(to: maxLengthOfText)
                    message = String(message.dropLast(3))
                    message = message + "..."
                }
                
            }
            
            let optionMenu = UIAlertController(title: message, message: nil, preferredStyle: .actionSheet)
            optionMenu.view.tintColor = UIColor.alertTintColor()
            let confirmAction = UIAlertAction(title: String.localize("LB_CA_POST_DELETE"), style: .default, handler: {[weak self] (alert: UIAlertAction!) -> Void in
                if let strongSelf = self {
                    strongSelf.deleteCommentAction(collectionViewCell,index: index)
                }
                
            })
            
            let cancelAction = UIAlertAction(title: String.localize("LB_CANCEL"), style: .cancel, handler: nil)
            
            optionMenu.addAction(confirmAction)
            optionMenu.addAction(cancelAction)
            
            optionMenu.view.tintColor = UIColor.secondary2()
            
            self.present(optionMenu, animated: true, completion: nil)
            optionMenu.view.tintColor = UIColor.secondary2()
            
            self.selectedIndex = index
            self.collectionView.reloadData()
        }
        
        
    }
    
    func didTapOnProfileImage(_ index: Int) {
        let postCommentList = filterdComments[index]
        
        let user = User()
        user.userKey = postCommentList.userKey
        
        let publicProfileVC = ProfileViewController()
        publicProfileVC.currentType = postCommentList.userKey == Context.getUserKey() ? .Private : .Public
        publicProfileVC.isFromPostComment = true
        
        if publicProfileVC.currentType == .Public {
            PushManager.sharedInstance.goToProfile(user, hideTabBar: true)
        }else{
            self.navigationController?.pushViewController(publicProfileVC, animated: true)
        }
        
    }
    
    //MARK: - TextField Delegate
    
    func textFieldShouldReturn(_ textField: UITextField) -> Bool {
        sendComment()
        return true
    }
    
    func textField(_ textField: UITextField, shouldChangeCharactersIn range: NSRange, replacementString string: String) -> Bool {
        
        let currentString = textField.text as NSString?
        if let newString = currentString?.replacingCharacters(in: range, with: string) {
            if userTag.length > 0 && !newString.contains(userTag) {
                textField.text = currentString?.replacingOccurrences(of: userTag, with: "")
                userTag = ""
                let beginingPosition = textField.beginningOfDocument
                textField.selectedTextRange = textField.textRange(from: beginingPosition, to: beginingPosition)
                return false
            }
        }
        
        return true
    }
    
    //MARK: - More Comment Footer delegate
    
    func expandComments() {
        
        let postCommentViewController = PostCommentViewController()
        postCommentViewController.post = self.post
        self.navigationController?.pushViewController(postCommentViewController, animated: true)
        
        //Uncoment these lines if you want to expand comments instead of go to comment page
        //self.collectionView.reloadData()
    }
    
    //MARK: FilterStyle Delegate
    
    func filterStyle(_ styles : [Style], styleFilter : StyleFilter, selectedFilterCategories: [Cat]?) {
        self.filterStyle(styles, styleFilter: styleFilter, isNeedSnapshot: false)
    }
    
    func filterStyle(_ styles : [Style], styleFilter : StyleFilter, isNeedSnapshot : Bool = false) {
        //TODO
    }
    
    func fetchStyles(_ styles: [Style], styleFilter: StyleFilter, isNeedSnapshot: Bool, merchantId: Int?, completion: ((SearchResponse?) -> Void)?) {
        
    }
    
    func didSelectBrandFromSearch(_ brand: Brand?) {
        
    }
    
    func didSelectMerchantFromSearch(_ merchant: Merchant?) {
    }
    
    //MARK: Getting Data
    
    func createNewComment(_ comment: PostCommentList) {
        self.showLoading()
        firstly{
            return PostManager.savePostComment(comment)
            }.then { _ -> Void in
                Log.debug("success")
                self.userTag = ""
                if let post = self.post {
                    comment.postId = self.post?.postId ?? 0
                    comment.userId = Context.getUserId()
                    comment.userKey = Context.getUserKey()
                    comment.userName = self.user?.userName ?? ""
                    comment.displayName = self.user?.displayName ?? ""
                    comment.profileImage = self.user?.getProfileImage() ?? ""
                    if let serverDate = TimestampService.defaultService.getServerTime() {
                        comment.lastCreated =  serverDate //Date()
                        comment.lastModified = serverDate //Date()
                    } else {
                        comment.lastCreated =  Date()
                        comment.lastModified = Date()
                    }
                    comment.statusId = Constants.StatusID.active.rawValue
                    
                    if post.postCommentLists == nil {
                        post.postCommentLists = [comment]
                    } else {
                        post.postCommentLists?.append(comment)
                    }
                    if let post = self.post {
                        PostManager.insertLocalPostCommentList(comment, post: post, atFirstIndex: false)
                    }
                    
                    self.reloadDataSource()
                    DispatchQueue.main.async {
                        self.scrollToBottom()
                    }
                    
                    self.view.recordAction(
                        .Tap,
                        sourceRef: "Submit",
                        sourceType: .Button,
                        targetRef: comment.correlationKey,
                        targetType: .Comment)
                    
                }
            }.always {
                self.stopLoading()
                
            }.catch { _ -> Void in
                Log.error("error")
        }
    }
    
    func updateNewsFeed() {
        
        if let post = self.post {
            self.renderUserView()
            
            self.postDetailManager.currentPosts = [post]
            self.bottomView.countLabel.text = "\(self.post!.likeCount)"
            self.bottomView.heartButton.isSelected = PostManager.isLikeThisPost(self.post!)
            self.bottomView.layoutSubviews()
            self.updateComment(self.pageNo)
            self.updatePostRelated(post.postText)
            
            self.downImages()
        } else {
            
            self.showLoading()
            firstly {
                // update inventory location if needed
                // if it is not updated, it will return success without api call
                return postDetailManager.fetchNewsFeed(.postDetail, postId: self.postId, pageno: 1)
                }.then { postIds -> Promise<Any> in
                    
                    return self.postDetailManager.getPostActivitiesByPostIds(postIds as! String)
                }.then { _ -> Void in
                    if self.postDetailManager.currentPosts.count > 0 {
                        self.post = self.postDetailManager.currentPosts[0]
                        self.bottomView.countLabel.text = "\(self.post!.likeCount)"
                        self.bottomView.heartButton.isSelected = PostManager.isLikeThisPost(self.post!)
                        self.bottomView.layoutSubviews()
                        self.updateComment(self.pageNo)
                        self.updatePostRelated(self.post!.postText)
                    } else {
                        Alert.alertWithSingleButton(self, title: "", message: String.localize("LB_CA_NOTIFICATION_POST_DELETED"), buttonString: String.localize("LB_OK"), actionComplete: {
                            self.navigationController?.popViewController(animated:true)
                        })
                    }
                    
                } .always {
                    self.downImages()
                    self.firstLoaded = true
                    self.renderUserView()
                    self.stopLoading()
                }.catch { _ -> Void in
                    Log.error("error")
            }
        }
        
    }
    
    func updatePostRelated(_ postText: String) {
        
        if postText.length <= 0 {
            return
        }
        
        let strings = postText.substringsMatches(pattern: RegexManager.ValidPattern.HashTag, exclude: RegexManager.ValidPattern.ExcludeHttp)
        var promises : [Promise<Void>] = []
        var hashTagSets = Set<String>()
        for hashTag in strings {
            if !hashTagSets.contains(hashTag) {
                hashTagSets.insert(hashTag)
                promises.append(self.fetchPostByHashTag(hashTag).asVoid())
            }
            
            //Fetch max 3 hashtags API for related post
            if hashTagSets.count >= 3 {
                break
            }
        }
        
        if promises.count > 0 {
            
            when(fulfilled: promises).then { [weak self] _ -> Void in
                
                if let strongSelf = self {
                    
                    //Filter Duplicated Post because we call 1 api many times
                    var filterPosts: [Post] = []
                    var listPostIDs: [String] = []
                    var currentPosts = strongSelf.postRelatedManager.currentPosts
                    currentPosts.sort(by: {$0.lastModified > $1.lastModified})
                    
                    var selfPostId = 0
                    if let post = strongSelf.post {
                        selfPostId = post.postId
                    }
                    
                    for post in currentPosts {
                        
                        if selfPostId == post.postId { //Don't show in related posts for current post detail
                            continue
                        }
                        
                        //Make sure unique post, won't be duplicated
                        //                            if let containPost = filterPosts.filter({$0.postId == post.postId}).first {
                        //                                continue
                        //                            }
                        
                        filterPosts.append(post)
                        listPostIDs.append("\(post.postId)")
                        if filterPosts.count >= strongSelf.MaxRelatedPosts {
                            break
                        }
                    }
                    
                    strongSelf.postRelatedManager.currentPosts = filterPosts
                    
                    if listPostIDs.count > 0 {
                        
                        let postIdsString = listPostIDs.joined(separator: ",")
                        
                        //Fetch detail of posts
                        firstly {
                            strongSelf.postRelatedManager.getPostActivitiesByPostIds(postIdsString)
                            }.then { _ -> Void in
                                
                                //To make sure displaying view easy to look
                                if strongSelf.postRelatedManager.currentPosts.count > 0 {
                                    strongSelf.collectionView.backgroundColor = UIColor.white
                                } else {
                                    strongSelf.collectionView.backgroundColor = UIColor.primary2()
                                }
                                
                                strongSelf.collectionView.reloadData()
                            }.catch { (error) in
                                strongSelf.stopLoading()
                        }
                    }
                    
                    
                }
                
                }.catch { (error) in
                    self.stopLoading()
            }
        }
    }
    
    func fetchPostByHashTag(_ hashTagValue: String) -> Promise<Any> {
        return Promise{ fulfill, reject in
            
            NewsFeedService.listNewsFeedByHashTag(hashTagValue, pageno: 1, completion: { [weak self] response in
                if let strongSelf = self {
                    if let newsFeedListResponse :  NewsFeedListResponse = Mapper<NewsFeedListResponse>().map(JSONObject: response.result.value) {
                        if let newsfeeds = newsFeedListResponse.pageData as [Post]? {
                            strongSelf.postRelatedManager.appendToCurrentPosts(FeedType.postDetail, remotePosts: newsfeeds)
                            //                            strongSelf.postRelatedManager.currentPosts.append(contentsOf: newsfeeds)
                            
                        }
                    }
                }
                
                fulfill("OK")
            })
            
        }
    }
    
    func reloadDataSource() {
        if let postCommentLists = self.post?.postCommentLists {
            //self.filterdComments = postCommentLists.filter({$0.statusId != Constants.StatusID.deleted.rawValue}).sort(){$0.lastModified < $1.lastModified} ?? []
            self.filterdComments = postCommentLists.filter({$0.statusId != Constants.StatusID.deleted.rawValue})
            
        } else {
            self.filterdComments = []
        }
        self.commentList = self.filterdComments
        let topComment = filterdComments.suffix(self.MaxLatestComments)
        filterdComments.removeAll()
        filterdComments.append(contentsOf: topComment)
        
        self.collectionView.reloadData()
        
    }
    
    func searchComment(_ postId : Int, pageno: Int) -> Promise<Any> {
        return Promise{ fulfill, reject in
            let callback : (DataResponse<Any>) -> Void = { [weak self] (response) in
                if let strongSelf = self {
                    if response.response?.statusCode == 200 {
                        
                        if let listCommentListResponse :  PostCommentListResponse = Mapper<PostCommentListResponse>().map(JSONObject: response.result.value) {
                            
                            if let comments = listCommentListResponse.pageData, comments.count > 0 {
                                let localComments = PostManager.getLocalCommentByPostId(postId) ?? []
                                if pageno == 1 {
                                    strongSelf.post?.postCommentLists = localComments
                                }
                                
                                for comment in comments {
                                    if let localComment = localComments.filter({$0.correlationKey == comment.correlationKey}).first {
                                        
                                        if localComment.lastModified >= comment.lastModified {
                                            comment.statusId = localComment.statusId
                                            comment.lastModified = localComment.lastModified
                                        } else {
                                            if localComment.statusId == Constants.StatusID.deleted.rawValue {
                                                comment.statusId = localComment.statusId
                                                comment.lastModified = localComment.lastModified
                                            }
                                        }
                                        localComment.postCommentId = comment.postCommentId
                                    } else {
                                        strongSelf.post?.postCommentLists?.append(comment)
                                    }
                                }
                                strongSelf.post?.postCommentLists?.sort(by: {$0.lastCreated < $1.lastCreated})
                                strongSelf.pageNo = pageno
                                strongSelf.hasLoadMore = listCommentListResponse.pageTotal > listCommentListResponse.pageCurrent //we have more page then current page
                            } else {
                                strongSelf.hasLoadMore = false
                            }
                        }
                        fulfill("OK")
                    } else {
                        strongSelf.hasLoadMore = true
                        var statusCode = 0
                        if let code = response.response?.statusCode {
                            statusCode = code
                        }
                        let error = NSError(domain: "", code: statusCode, userInfo: nil)
                        reject(error)
                    }
                } else {
                    self?.hasLoadMore = true
                    reject(response.result.error!)
                }
            }
            NewsFeedService.listPostComment(postId, pageno: pageno, completion: callback)
        }
    }
    
    func updateComment(_ pageno: Int){
        
        let postId = (post?.postId ?? self.postId)
        firstly {
            return self.searchComment(postId, pageno: pageno)
            }.then { _ -> Void in
                self.reloadDataSource()
                
            }.always {
                //self.refreshControl.endRefreshing()
            }.catch { _ -> Void in
                Log.error("error @ updateComment")
        }
    }
    
    func renderUserView() {
        self.collectionView.reloadData()
    }
    
    //MARK: - Delegate & Datasource
    
    func numberOfSections(in collectionView: UICollectionView) -> Int {
        
        if post == nil {
            return 1
        }
        
        return 4
        
    }
    
    override func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        
        if self.post == nil {
            return 1
        }
        
        switch section {
        case Section.PostImage.rawValue:
            if let images = post?.images{
                return images.count
            }else{
                return 0
            }
        case Section.PostDetail.rawValue:
            return 1
        case Section.Comment.rawValue:
            return filterdComments.count
        case Section.PostRelated.rawValue:
            return postRelatedManager.currentPosts.count
        default:
            break
        }
        
        return 0
    }
    func collectionView(_ collectionView: UICollectionView, shouldSelectItemAtIndexPath indexPath: IndexPath) -> Bool {
        return true
    }
    
    func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        if indexPath.section == Section.Comment.rawValue {
            if (indexPath.row < filterdComments.count) {
                let postCommentList = filterdComments[indexPath.row]
                if postCommentList.userKey != Context.getUserKey() {
                    let oldUserTag: String = userTag
                    userTag = "@\(postCommentList.displayName) "
                    if oldUserTag != userTag {
                        if let commentText = self.bottomView.textField.text, commentText.contains(oldUserTag) {
                            self.bottomView.textField.text = commentText.replacingOccurrences(of: oldUserTag, with: userTag)
                        } else {
                            let currentCommentString = NSMutableString(string: self.bottomView.textField.text ?? "")
                            currentCommentString.insert(userTag, at: 0)
                            self.bottomView.textField.text = currentCommentString as String
                        }
                    }
                    self.bottomView.textField.becomeFirstResponder()
                }
            }
            self.selectedIndex = indexPath.row
            self.collectionView.reloadData()
        } else if indexPath.section == Section.PostRelated.rawValue {
            if postRelatedManager.currentPosts.indices.contains(indexPath.row) {
                let post = self.postRelatedManager.currentPosts[indexPath.row]
                if let cell = collectionView.cellForItem(at: indexPath) {
                    cell.recordAction(.Tap, sourceRef: "\(post.postId)", sourceType: .Post, targetRef: "Post-Detail", targetType: .View)
                }
                let postDetailController = PostDetailViewController(postId: post.postId)
                postDetailController.post = post
                self.navigationController?.pushViewController(postDetailController, animated: true)
            }
        }
        
    }
    
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, minimumLineSpacingForSectionAtIndex section: Int) -> CGFloat {
        if section == Section.PostRelated.rawValue {
            return PostManager.NewsFeedLineSpacing
        }
        return 0
    }
    
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, minimumInteritemSpacingForSectionAtIndex section: Int) -> CGFloat {
        if section == Section.PostRelated.rawValue {
            return PostManager.NewsFeedLineSpacing
        }
        
        return 0
    }
    
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, insetForSectionAtSection section: Int) -> UIEdgeInsets {
        if section == Section.PostRelated.rawValue {
            return UIEdgeInsets(top: PostManager.NewsFeedLineSpacing, left: PostManager.NewsFeedLineSpacing, bottom: 25, right:PostManager.NewsFeedLineSpacing)
        }
        return UIEdgeInsets.zero
    }
    
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, referenceSizeForHeaderInSection section: Int) -> CGSize {
        if section == Section.PostRelated.rawValue && postRelatedManager.currentPosts.count > 0 {
            return CGSize(width: self.view.width, height: PostDetailHeaderView.ViewHeight)
        }
        return CGSize.zero
    }
    
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, referenceSizeForFooterInSection section: Int) -> CGSize {
        if section == Section.Comment.rawValue {
            if commentList.count > 0 {
                
                if commentList.count > MaxLatestComments {
                    //View more comments
                    return CGSize(width: self.view.bounds.width, height: HeightFooterView)
                    
                }
                
                //Seperate bottom line for comment
                let heightBottomBorder: CGFloat = 10
                return CGSize(width: self.view.bounds.width, height: heightBottomBorder)
            }
        }
        
        return CGSize.zero
    }
    
    func collectionView(_ collectionView: UICollectionView, viewForSupplementaryElementOfKind kind: String, at indexPath: IndexPath) -> UICollectionReusableView {
        
        if kind == UICollectionElementKindSectionHeader {
            let view = collectionView.dequeueReusableSupplementaryView(ofKind: UICollectionElementKindSectionHeader, withReuseIdentifier: HeaderViewIdentifier, for: indexPath)
            if let headerView = view as? PostDetailHeaderView {
                headerView.label.text = String.localize("LB_CA_POST_RELATED_POST")
            }
            
            return view
        }
        
        let view = collectionView.dequeueReusableSupplementaryView(ofKind: UICollectionElementKindSectionFooter, withReuseIdentifier: MoreCommentFooterView.FooterViewID, for: indexPath) as! MoreCommentFooterView
        view.analyticsViewKey = self.analyticsViewRecord.viewKey
        if self.commentList.count > MaxLatestComments {
            
            view.containerView.isHidden = false
            if let commentCount = self.post?.commentCount{
                view.titleLabel.text = String.localize("LB_CA_ALL_COMMENT").replacingOccurrences(of: "{}", with: "\(commentCount)")
            }
            
        } else {
            view.containerView.isHidden = true
        }
        
        view.delegate = self
        return view
    }
    
    @objc func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, sizeForItemAtIndexPath indexPath: IndexPath) -> CGSize {
        
        if self.post == nil {
            return collectionView.frame.size
        }
        
        switch indexPath.section {
        case Section.PostImage.rawValue:
            
            if let image = post?.images?[indexPath.row].upImage {
                return CGSize(width:ScreenWidth,height: image.size.height / image.size.width * ScreenWidth)
            }else{
                return CGSize.zero
            }
        case Section.PostDetail.rawValue:
            if let post = self.post {
                return CGSize(width: self.view.frame.size.width, height: NewsFeedDetailCell.getCellHeight(post))
            }
        case Section.Comment.rawValue:
            if filterdComments.count > 0 {
                var height = PostCommentDetailCell.getCommentTextHeight(self.view.frame.sizeWidth, text: filterdComments[indexPath.row].postCommentText)
                if height > 0 {
                    height = height + PostCommentDetailCell.CommentLabelMarginTop
                }
                
                return CGSize(width: self.view.frame.size.width , height: PostCommentDetailCell.BaseCellHeight + (height) + PostCommentDetailCell.CommentLabelMarginBottom)
            }
        case Section.PostRelated.rawValue:
            var text = ""
            var userSourceName: String? = nil
            if postRelatedManager.currentPosts.indices.contains(indexPath.row) {
                let post = postRelatedManager.currentPosts[indexPath.row]
                userSourceName = post.userSource?.userName
                text = post.postText
            }
            let height = SimpleFeedCollectionViewCell.getHeightForCell(text, userSourceName: userSourceName)
            return CGSize(width: SimpleFeedCollectionViewCell.getCellWidth(), height: height)
        default:
            break
        }
        
        return CGSize.zero
        
    }
    
    func collectionView(_ collectionView: UICollectionView, numberOfColumnsInSection section: Int) -> Int {
        if section == Section.PostRelated.rawValue {
            return 2
        }
        
        return 0
    }
    
    override func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        
        if self.post == nil {
            let cell = collectionView.dequeueReusableCell(withReuseIdentifier: NoCollectionItemCellID, for: indexPath) as! NoCollectionItemCell
            cell.label.text = String.localize("LB_POST_NOTEXIST")
            cell.imageView.image = UIImage(named: "placeholder_icon")
            cell.imageView.isHidden = !firstLoaded
            cell.label.isHidden = !firstLoaded
            return cell
        }
        
        if indexPath.section == Section.PostImage.rawValue {
            
            let cell = collectionView.dequeueReusableCell(withReuseIdentifier: "NewsFeedDetailImagesCell", for: indexPath) as! NewsFeedDetailImagesCell
            cell.images = post?.images?[indexPath.row]
            return cell
            
        } else if indexPath.section == Section.PostDetail.rawValue {
            
            let cell = postDetailManager.getNewsfeedDetailCell(indexPath) as! NewsFeedDetailCell
            cell.referrerUserKey = self.referrerUserKey ?? ""
            return cell
            
        } else if indexPath.section == Section.PostRelated.rawValue {
            
            let cell = postRelatedManager.getSimpleNewsFeedCell(indexPath)
            if let cell = cell as? SimpleFeedCollectionViewCell {
                cell.isUserInteractionEnabled = true
                cell.recordImpressionAtIndexPath(indexPath, positionLocation: "Post-Detail", positionComponent: "RelatedPost", viewKey: self.analyticsViewRecord.viewKey)
            }
            
            return cell
        } else {
            
            let cell = collectionView.dequeueReusableCell(withReuseIdentifier: PostCommentDetailCell.CellIdentifier, for: indexPath) as! PostCommentDetailCell
            let postCommentList = self.filterdComments[indexPath.row]
            cell.upperLabel.text = postCommentList.displayName
            cell.commentLabel.text = postCommentList.postCommentText
            cell.setImage(postCommentList.getProfileImage(), imageCategory: .user)
            cell.configImage(postCommentList.isCurator ? 1 : 0)
            cell.timeStampLabel.text = postCommentList.lastModified.commentTimeString
            cell.isCanDelete = (postCommentList.userKey == Context.getUserKey())
            cell.tag = indexPath.row
            cell.delegate = self
            
            let postCommentId = postCommentList.postCommentId ?? 0
            let viewKey = self.analyticsViewRecord.viewKey
            let impressionDisplayName = AnalyticsManager.trimTextForImpressionDisplayName(postCommentList.postCommentText)
            cell.initAnalytics(withViewKey: viewKey, impressionKey: AnalyticsManager.sharedManager.recordImpression(impressionRef:"\(postCommentId)", impressionType: "Review", impressionDisplayName: impressionDisplayName, positionComponent: "ReviewListing", positionIndex: indexPath.row + 1, positionLocation: "Post-Detail", viewKey: viewKey))
            
            if self.selectedIndex >= 0 && self.selectedIndex == indexPath.row {
                cell.backgroundColor = UIColor.lightText
            }else {
                cell.backgroundColor = UIColor.white
            }
            
            return cell
        }
    }

    //MARK: - Keyboard notification
    
    override func keyboardWillHideNotification(_ notification: NSNotification) {
        super.keyboardWillHideNotification(notification)
        bottomView.frame = CGRect(x:0, y: self.view.bounds.sizeHeight - AddCommentView.ViewHeight - ScreenBottom, width: self.view.bounds.width, height: AddCommentView.ViewHeight + ScreenBottom)
        collectionView.contentInset = UIEdgeInsets.zero
        collectionView.scrollIndicatorInsets = UIEdgeInsets.zero
        if let gestureHideKeyboard = gestureHideKeyboard {
            self.view.removeGestureRecognizer(gestureHideKeyboard)
        }
    }
    
    override func keyboardDidShowNotification(_ notification: NSNotification) {
        super.keyboardDidShowNotification(notification)
        
        //        bottomView.frame = CGRect(x:0, y: self.view.bounds.sizeHeight - AddCommentView.ViewHeight - keyboardSize.height, width: self.view.bounds.width, height: AddCommentView.ViewHeight)
    }
    
    override func keyboardWillShowNotification(_ notification: NSNotification) {
        super.keyboardWillShowNotification(notification)
        
        if let gestureHideKeyboard = gestureHideKeyboard {
            self.view.addGestureRecognizer(gestureHideKeyboard)
        }
        
        if let keyboardSize = (notification.userInfo?[UIKeyboardFrameEndUserInfoKey] as? NSValue)?.cgRectValue {
            
            let contentInsets = UIEdgeInsets(top: 0.0, left: 0.0, bottom: keyboardSize.height, right: 0.0)
            
            collectionView.contentInset = contentInsets
            collectionView.scrollIndicatorInsets = contentInsets
            
            bottomView.frame = CGRect(x:0, y: self.view.bounds.sizeHeight - AddCommentView.ViewHeight - keyboardSize.height, width: self.view.bounds.width, height: AddCommentView.ViewHeight)
        }
    }
    
    func scrollToBottom() {
        
        if (self.filterdComments.count > 0) {
            let indexPath = IndexPath(item: min(self.filterdComments.count - 1, MaxLatestComments - 1), section: Section.Comment.rawValue)
            self.collectionView.scrollToItem(at: indexPath, at: .bottom, animated: true)
        }
    }
    
    // MARK: - Logging
    
    func downImages() {
        let group = DispatchGroup()
        
        if let images = post?.images{
            for  index in 0..<images.count{
                group.enter()
                if let image = images[index].image{
                    KingfisherManager.shared.retrieveImage(with: ImageURLFactory.URLSize1000(image, category: .post), options: nil, progressBlock: nil, completionHandler: { (image, error, cacheType, imageURL) in
                        if let image = image {
                            self.imageSize.append(image)
                            self.post?.images![index].upImage = image
                            group.leave()
                        } else {
                            group.leave()
                        }
                    })
                }
                
            }
            group.notify(queue: DispatchQueue.main) {
                self.collectionView.reloadData()
            }
            
        }
        
        
    }
    func initAnalyticLog(){
        
        var currentPostId = self.postId
        if currentPostId <= 0 && self.post != nil {
            currentPostId = self.post!.postId
        }
        
        initAnalyticsViewRecord(
            nil,
            authorType: nil,
            brandCode: nil,
            merchantCode: nil,
            referrerRef: nil,
            referrerType: nil,
            viewDisplayName: self.getPageTitle(),
            viewParameters: nil,
            viewLocation: "Post-Detail",
            viewRef: "\(currentPostId)",
            viewType: "Post"
        )
    }
}

internal protocol MoreCommentFooterViewDelegate: NSObjectProtocol {
    func expandComments()
}

internal class MoreCommentFooterView : UICollectionReusableView {
    
    static let FooterViewID = "MoreCommentFooterView"
    private let SpacingBottom: CGFloat = 10
    var containerView = UIView()
    var bottomView = UIView()
    var titleLabel = UILabel()
    var buttonExpandComment = UIButton(type: .custom)
    weak var delegate: MoreCommentFooterViewDelegate?
    let imageViewExpandSize:CGSize = CGSize(width: 8.0, height: 5.0)
    var imageViewExpand = UIImageView(image: UIImage(named: "arrow_close"))
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        backgroundColor = UIColor.clear
        containerView.backgroundColor = UIColor.white
        
        titleLabel.frame = CGRect(x:0, y: 0, width: frame.width, height: frame.height)
        titleLabel.textAlignment = .center
        titleLabel.formatSize(13)
        titleLabel.textColor = UIColor.secondary3()
        titleLabel.text = String.localize("LB_CA_ALL_COMMENT")
        containerView.addSubview(titleLabel)
        
        containerView.addSubview(imageViewExpand)
        
        buttonExpandComment.frame = CGRect(x:0, y: 0, width: frame.width, height: frame.height)
        buttonExpandComment.addTarget(self, action: #selector(self.expandComments), for: .touchUpInside)
        containerView.addSubview(buttonExpandComment)
        
        addSubview(containerView)
        
        bottomView.backgroundColor = UIColor.primary2()
        addSubview(bottomView)
    }
    
    @objc func expandComments() {
        
        if let viewKey = self.analyticsViewKey {
            buttonExpandComment.initAnalytics(withViewKey: viewKey)
            buttonExpandComment.recordAction(
                .Tap,
                sourceRef: "AllReviews",
                sourceType: .Button,
                targetRef: "AllReviews",
                targetType: .View
            )
        }
        
        delegate?.expandComments()
    }
    
    override func layoutSubviews() {
        super.layoutSubviews()
        containerView.frame = CGRect(x:0, y: 0, width: bounds.sizeWidth, height: bounds.sizeHeight - SpacingBottom)
        titleLabel.frame = CGRect(x:0, y: 0, width: containerView.frame.width, height: containerView.frame.height)
        titleLabel.sizeToFit()
        let textWidth = titleLabel.frame.sizeWidth
        titleLabel.frame = CGRect(x: bounds.sizeWidth/2 - textWidth/2 - imageViewExpandSize.width, y: 0, width: textWidth, height: containerView.frame.height)
        imageViewExpand.frame = CGRect(x: titleLabel.frame.maxX + 6, y: (containerView.bounds.sizeHeight - imageViewExpandSize.height)/2, width: imageViewExpandSize.width, height: imageViewExpandSize.height)
        buttonExpandComment.frame = CGRect(x:0, y: 0, width: containerView.frame.width, height: containerView.frame.height)
        
        if containerView.isHidden {
            bottomView.frame = CGRect(x:0, y: 0, width: self.bounds.sizeWidth, height: self.bounds.sizeHeight)
        } else {
            bottomView.frame = CGRect(x:0, y: self.bounds.sizeHeight - SpacingBottom, width: self.bounds.sizeWidth, height: SpacingBottom)
        }
        
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}

class PostDetailHeaderView: UICollectionReusableView {
    
    static let ViewHeight: CGFloat = 42
    var leftView = UIView()
    var rightView = UIView()
    var label = UILabel()
    static let MarginTop = CGFloat(6)
    var padding = CGFloat(16)
    let PaddingLeft = CGFloat(16)
    let PaddingRight = CGFloat(16)
    private var lineSize: CGSize?
    
    static let LabelHeight:CGFloat = 15.0
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        self.backgroundColor = UIColor.white
        
        leftView.backgroundColor = UIColor.black
        rightView.backgroundColor = UIColor.black
        
        self.addSubview(leftView)
        self.addSubview(rightView)
        
        label.text = String.localize("LB_CA_HIGHLIGHT_PROMOTION")
        if let fontBold = UIFont(name: Constants.Font.Bold, size: 16) {
            label.font = fontBold
        } else {
            label.formatSizeBold(16)
        }
        label.textColor = UIColor.secondary3()
        self.addSubview(label)
        
    }
    
    override func layoutSubviews() {
        super.layoutSubviews()
        
        let originY = CGFloat(4)
        var width = StringHelper.getTextWidth(label.text ?? "", height: PostDetailHeaderView.LabelHeight, font: label.font)
        label.frame = CGRect(x:(self.bounds.sizeWidth - width) / 2, y:  originY, width: width, height: PostDetailHeaderView.LabelHeight)
        
        width = (self.bounds.sizeWidth - width - 2 * padding) / 2
        
        let lineSize = CGSize(width: 40, height: 0.5)
        leftView.frame = CGRect(x:label.frame.minX - padding - lineSize.width, y: label.frame.midY - lineSize.height / 2, width: lineSize.width, height: lineSize.height)
        rightView.frame = CGRect(x:label.frame.maxX + padding, y: label.frame.midY - lineSize.height / 2, width: lineSize.width, height: lineSize.height)
    }
    
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}

