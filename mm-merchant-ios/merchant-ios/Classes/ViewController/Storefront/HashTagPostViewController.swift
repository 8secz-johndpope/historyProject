//
//  StyleFeedController.swift
//  merchant-ios
//
//  Created by Sang Nguyen.
//  Copyright © 2015 Koon Kit Chan. All rights reserved.
//

import Foundation
import PromiseKit
import ObjectMapper
import Alamofire

class HashTagPostViewController : MmViewController, PullToRefreshViewUpdateDelegate {
    
    private final let LoadingCellIdentifier = "LoadingCellIdentifier"
    private final let NoCollectionItemCellID = "NoCollectionItemCellID"
    var customPullToRefreshView: PullToRefreshUpdateView?
    private var currentCurator: Curator?
    
    var floatingActionButton: MMFloatingPostTagButton?
    private var lastPositionY = CGFloat(0)
    private final let OffsetAllowance = CGFloat(5)
    
    private var searchButton = UIButton()
    var isUpdatingNewFeeds = false
    var hashTagValue: String = ""
    var postManager : PostManager!
    private var needReloadData = false
    override func viewDidLoad() {
        super.viewDidLoad()
        
        if let tagName = ssn_Arguments["tagName"]?.string {
            hashTagValue = tagName
        }
        
        self.createBackButton()
        self.createShareButton()
        postManager = PostManager(postFeedTyle: .hashTag, collectionView: self.collectionView, viewController: self)
        
        self.title = self.getHashTagTitle()
        NotificationCenter.default.addObserver(self, selector: #selector(self.followingDidUpdate), name: Constants.Notification.followingDidUpdate, object: nil)
        view.backgroundColor = UIColor.white
        self.configCollectionView()
        
        self.updateNewsFeed(pageNo: 1)
        initAnalyticLog()
    }
    
    func getHashTagTitle() -> String {
        if self.hashTagValue.length > 0 {
            if self.hashTagValue.hasPrefix("#") {
                return self.hashTagValue
            } else {
                return "#\(self.hashTagValue)"
            }
        }
        
        return ""
    }
    
    func createShareButton() {
        
        let ButtonHeight = CGFloat(25)
        let ButtonWidth = CGFloat(30)
        
        let shareButton = UIButton(type: .custom)
        shareButton.frame = CGRect(x:0, y: 0, width: ButtonWidth, height: ButtonHeight)
        shareButton.setImage(UIImage(named: "ic_share_black"), for: .normal)
        shareButton.contentEdgeInsets = UIEdgeInsets(top: 0, left: 0, bottom: 0, right: -14)
        shareButton.addTarget(self, action: #selector(HashTagPostViewController.sharePostHashTag), for: UIControlEvents.touchUpInside)
        
        self.navigationItem.rightBarButtonItem = UIBarButtonItem(customView: shareButton)
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        
        if self.floatingActionButton == nil {
            self.createFloatingButtonHashTagTopic()
        }
        
        NotificationCenter.default.addObserver(self, selector: #selector(self.didReceiveScreenCapNotification), name: NSNotification.Name.UIApplicationUserDidTakeScreenshot, object: nil)
        
        if self.needReloadData {
            self.needReloadData = false
            self.updateNewsFeed(pageNo: 1)
        }
        
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        
        NotificationCenter.default.removeObserver(self, name: NSNotification.Name.UIApplicationUserDidTakeScreenshot, object: nil)
        
    }
    
    func loadBaseData(){
        self.updateNewsFeed(pageNo: 1)
    }
    
    func configCollectionView() {
        //self.collectionView.frame = CGRect(x: 0 , y: 0, width: self.view.bounds.width, height: self.view.bounds.height)
        self.collectionView.backgroundColor = UIColor.feedCollectionViewBackground()
        self.collectionView.register(UICollectionViewCell.self, forCellWithReuseIdentifier: LoadingCellIdentifier)
        self.collectionView.register(NoCollectionItemCell.self, forCellWithReuseIdentifier: NoCollectionItemCellID)
        
        customPullToRefreshView = PullToRefreshUpdateView(frame: CGRect(x:(self.collectionView.frame.width - Constants.Value.PullToRefreshViewHeight) / 2, y: 258.0, width: Constants.Value.PullToRefreshViewHeight, height: Constants.Value.PullToRefreshViewHeight), scrollView: self.collectionView)
        customPullToRefreshView?.delegate = self
        self.collectionView.addSubview(customPullToRefreshView!)
        if let layout = collectionView.collectionViewLayout as? PinterestLayout {
            layout.delegate = self
        }
    }
    
    override func getCustomFlowLayout() -> UICollectionViewFlowLayout {
        let layout = PinterestLayout()
        layout.delegate = self
        return layout
    }
    
    func getDefaultCell(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell{
        let cell = collectionView.dequeueReusableCell(withReuseIdentifier: LoadingCellIdentifier, for: indexPath)
        return cell
    }
    
    func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        if postManager.currentPosts.indices.contains(indexPath.row) {
            let post = self.postManager.currentPosts[indexPath.row]
            if let cell = collectionView.cellForItem(at: indexPath) {
                cell.recordAction(.Tap, sourceRef: "\(post.postId)", sourceType: .Post, targetRef: "Post-Detail", targetType: .View)
            }
            let postDetailController = PostDetailViewController(postId: post.postId)
            postDetailController.post = post
            self.navigationController?.pushViewController(postDetailController, animated: true)
        }
    }

    override func shouldHaveCollectionView() -> Bool {
        return true
    }
    
    //MARK: - View Action
    
    @objc func sharePostHashTag() {
        let shareViewController = ShareViewController(screenCapSharing: false)
        
        shareViewController.viewKey = self.analyticsViewRecord.viewKey
        
        shareViewController.didUserSelectedHandler = { (data) in
            let myRole: UserRole = UserRole(userKey: Context.getUserKey())
            let targetRole: UserRole = UserRole(userKey: data.userKey)
            
            WebSocketManager.sharedInstance().sendMessage(
                IMConvStartMessage(
                    userList: [myRole, targetRole],
                    senderMerchantId: myRole.merchantId
                ),
                completion: { [weak self] (ack) in
                    if let strongSelf = self {
                        if let convKey = ack.data {
                            let viewController = UserChatViewController(convKey: convKey)
                            
                            let chatModel = ChatModel(text: strongSelf.getHashTagTitle())
                            chatModel.chatSendId = Context.getUserKey()
                            viewController.forwardChatModel = chatModel
                            strongSelf.navigationController?.pushViewController(viewController, animated: true)
                        } else {
                            ErrorLogManager.sharedManager.recordNonFatalError(withException: .NullPointer)
                        }
                    } else {
                        ErrorLogManager.sharedManager.recordNonFatalError(withException: .NullPointer)
                    }
                }, failure: { [weak self] in
                    if let strongSelf = self {
                        strongSelf.showErrorAlert(String.localize("MSG_ERR_NETWORK_1009"))
                    }
                }
            )
        }
        
        shareViewController.didSelectSNSHandler = { [weak self] method in
            if let strongSelf = self {
                ShareManager.sharedManager.shareHashTag(strongSelf.getHashTagTitle(), method: method)
            }
        }
        
        
        self.present(shareViewController, animated: false, completion: nil)
    }
    
    //MARK: - Floating Action Button
    
    private func createFloatingButtonHashTagTopic() {
        
        let buttonSize = CGSize(width: 130, height: 35)
        let frameButton = CGRect(x:(ScreenWidth - buttonSize.width) / 2, y: ScreenHeight - buttonSize.height - 15, width: buttonSize.width, height: buttonSize.height)
        self.floatingActionButton = MMFloatingPostTagButton(frame: frameButton)
        self.floatingActionButton!.tag = TagActionButton.ActionButtonTag.rawValue
        self.floatingActionButton!.transform = CGAffineTransform.identity
        self.floatingActionButton!.initAnalytics(withViewKey: self.analyticsViewRecord.viewKey)
        self.floatingActionButton!.createPostButton.initAnalytics(withViewKey: self.analyticsViewRecord.viewKey)
        self.floatingActionButton!.createPostButton.addTarget(self, action: #selector(self.didSelectedActionButton), for: .touchUpInside)
        self.view.addSubview(floatingActionButton!)
    }
    
    @objc func didSelectedActionButton(sender: UIButton) {
        
        if LoginManager.getLoginState() != .validUser {
            LoginManager.goToLogin()
            return
        }
        
        sender.recordAction(.Tap, sourceRef: "CreatePost", sourceType: .Topic, targetRef: "Editor-Image-Album", targetType: .View)
        
        PopManager.sharedInstance.selectPost(selectedHashTag: self.getHashTagTitle())
    }
    
    // MARK: - UIScrollView Delegate
    
    func scrollViewDidScroll(_ scrollView: UIScrollView) {
        if scrollView == self.collectionView {
            let offsetY = scrollView.contentOffset.y - lastPositionY
            lastPositionY = scrollView.contentOffset.y
            let maxY = CGFloat(64)
            if scrollView.contentOffset.y > maxY {
                if offsetY > OffsetAllowance  {
                    floatingActionButton?.fadeIn()
                }else if offsetY < -1 * OffsetAllowance{
                    floatingActionButton?.fadeOut()
                }
            }else if scrollView.contentOffset.y < maxY && (offsetY * -1) >= 0 {
                floatingActionButton?.fadeOut()
            }
            
        }
    }
    func scrollViewDidEndDragging(_ scrollView: UIScrollView, willDecelerate decelerate: Bool) {
        customPullToRefreshView?.scrollViewDidEndDragging()
    }
    
    // MARK: - UICollectionView Delegate
    
    func isEmptyPost() -> Bool {
        return postManager.currentPosts.count <= 0
    }
    
    func numberOfSections(in collectionView: UICollectionView) -> Int {
        return 1
    }
    
    override func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        
        if self.isEmptyPost() {
            return 1 //Placeholder Cell
        }
        
        return postManager.currentPosts.count
        
    }
    
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, referenceSizeForFooterInSection section: Int) -> CGSize {
        
        return CGSize(width: self.view.frame.sizeWidth, height: 100)
    }
    
    func collectionView(_ collectionView: UICollectionView, viewForSupplementaryElementOfKind kind: String, at indexPath: IndexPath) -> UICollectionReusableView {
        let view = collectionView.dequeueReusableSupplementaryView(ofKind: UICollectionElementKindSectionFooter, withReuseIdentifier: "LoadingFooterView", for: indexPath)
        
        if let footer = view as? LoadingFooterView {
            
            let shouldHideActivity = !postManager.hasLoadMore || self.isEmptyPost()
            footer.activity.isHidden = shouldHideActivity
            if shouldHideActivity {
                footer.activity.stopAnimating()
            } else {
                footer.activity.startAnimating()
            }
        }
        return view
    }
    

    
    override func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        
        if self.isEmptyPost() {
            let cell = collectionView.dequeueReusableCell(withReuseIdentifier: NoCollectionItemCellID, for: indexPath) as! NoCollectionItemCell
            cell.label.text = String.localize("ERR_MSG_HASHTAG_RESULT_BLANK")
            cell.imageView.image = UIImage(named: "placeholder_icon")
            cell.imageView.isHidden = false
            cell.label.isHidden = false
            return cell
        }
        
        if indexPath.row == postManager.currentPosts.count - 1 && postManager.hasLoadMore{
            self.updateNewsFeed(pageNo: postManager.currentPageNumber + 1)
        }
        
        let cell = postManager.getSimpleNewsFeedCell(indexPath)
        if let cell = cell as? SimpleFeedCollectionViewCell {
            cell.recordImpressionAtIndexPath(indexPath, positionLocation: "Newsfeed-Post-Topic", viewKey: self.analyticsViewRecord.viewKey)
            cell.isUserInteractionEnabled = true
            return cell
        }else {
            let defaultCell = self.getDefaultCell(self.collectionView, cellForItemAt: indexPath)
            return defaultCell
        }
        
        
    }
    
    func updateNewsFeed(pageNo: Int){
        
        if hashTagValue.length <= 0 {
            return
        }
        
        if isUpdatingNewFeeds {
            return
        }
        isUpdatingNewFeeds = true
        firstly {
            return self.postManager.fetchNewsFeed(.hashTag, hashTag: self.hashTagValue, pageno: pageNo)
            }.then { postIds -> Promise<Any> in
                return self.postManager.getPostActivitiesByPostIds(postIds as! String)
            }.then { _ -> Void in
                self.collectionView.reloadData()
                self.collectionView.collectionViewLayout.invalidateLayout()
            }.always {
                self.isUpdatingNewFeeds = false
            }.catch { _ -> Void in
                Log.error("error")
        }
    }
    
    deinit {
        NotificationCenter.default.removeObserver(self)
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
            viewDisplayName: self.getHashTagTitle(),
            viewParameters: nil,
            viewLocation: "Newsfeed-Post-Topic",
            viewRef: nil,
            viewType: "PostTopic"
        )
    }
    
    //MARK: Handle update following event
    @objc func followingDidUpdate() {
        needReloadData = true
    }
    
    override func refresh() {
        self.loadBaseData()
    }
    
    @objc func didReceiveScreenCapNotification(notification: NSNotification){
        self.postManager.sharePost()
    }
    
    //MARK: - PullToRefreshViewUpdateDelegate
    func didEndPullToRefresh() {
        self.loadBaseData()
    }
}

internal class MMFloatingPostTagButton: UIView {
    
    var createPostButton = UIButton(type: .custom)
    var isAnimating = false
    var animationDuration = TimeInterval(0.2)
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        
        if let cameraImage = UIImage(named: "camera_white") {
            createPostButton.titleEdgeInsets = UIEdgeInsets(top: 0, left: 10, bottom: 0, right: 0)
            createPostButton.setImage(cameraImage, for: .normal)
        }
        createPostButton.setTitleColor(UIColor.secondary3(), for: .normal)
        createPostButton.titleLabel?.font = UIFont.fontWithSize(14, isBold: false)
        createPostButton.setTitle(String.localize("LB_CA_HASHTAG_JOINTOPIC"), for: .normal)
        createPostButton.setTitleColor(UIColor.white, for: .normal)
        self.addSubview(createPostButton)
        
        self.backgroundColor = UIColor.primary1()
        self.transform = CGAffineTransform.identity
        
    }
    
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override func layoutSubviews() {
        super.layoutSubviews()
        self.createPostButton.frame = self.bounds
        self.layer.cornerRadius = self.bounds.sizeHeight / 2
        
    }
    
    func showFloatingButton() {
        DispatchQueue.main.async {[weak self] in
            self?.isHidden = false
        }
    }
    
    func hiddenFloatingButton() {
        DispatchQueue.main.async { [weak self] in
            self?.isHidden = true
        }
    }
    
    func removeFloatingButton() {
        DispatchQueue.main.async { [weak self] in
            self?.removeFromSuperview()
        }
    }
    
    func fadeOut() {
        if !self.isAnimating && self.isHidden == true {
            self.transform = CGAffineTransform(scaleX: 0.0, y: 0.0)
            self.isHidden = false
            UIView.animate(withDuration: animationDuration, delay: 0.0, options: [.curveLinear], animations: { () -> Void in
                self.transform = CGAffineTransform.identity
                self.isAnimating = true
            }) { (animationCompleted: Bool) -> Void in
                self.isAnimating = false
                self.isHidden = false
            }
        }
    }
    
    func fadeIn() {
        if !self.isAnimating &&  self.isHidden == false {
            self.transform = CGAffineTransform.identity
            self.isHidden = false
            UIView.animate(withDuration: animationDuration, delay: 0.0, options: [.curveLinear], animations: { () -> Void in
                self.transform = CGAffineTransform(scaleX: 0.2, y: 0.2)
                self.isAnimating = true
                
            }) { (animationCompleted: Bool) -> Void in
                self.isAnimating = false
                self.isHidden = true
                self.transform = CGAffineTransform(scaleX: 0, y: 0)
            }
        }
    }
    
    
    
}
extension HashTagPostViewController : PinterestLayoutDelegate {
    
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, sizeForItemAtIndexPath indexPath: IndexPath) -> CGSize {
        if  self.isEmptyPost() {
            return collectionView.frame.size
        }else {
            if indexPath.row == postManager.currentPosts.count {
                if (postManager.hasLoadMore) {
                    return CGSize(width: self.view.frame.size.width, height: Constants.Value.CatCellHeight)
                }
            }
            var text = ""
            var userSourceName: String? = nil
            if postManager.currentPosts.indices.contains(indexPath.row) {
                let post = postManager.currentPosts[indexPath.row]
                userSourceName = post.userSource?.userName
                text = post.postText
            }
            let height = SimpleFeedCollectionViewCell.getHeightForCell(text, userSourceName: userSourceName)
            return CGSize(width: SimpleFeedCollectionViewCell.getCellWidth(), height: height)

        }
        
    }
    
    func collectionView(_ collectionView: UICollectionView, numberOfColumnsInSection section: Int) -> Int {
        return self.isEmptyPost() ? 1 : 2
    }
    
    @objc func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, insetForSectionAtSection section: Int) -> UIEdgeInsets{
        
        return UIEdgeInsets(top: PostManager.NewsFeedLineSpacing, left: PostManager.NewsFeedLineSpacing, bottom: 25, right:PostManager.NewsFeedLineSpacing)
        
    }
    
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, minimumLineSpacingForSectionAtIndex section: Int) -> CGFloat {
        return PostManager.NewsFeedLineSpacing
    }
    
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, minimumInteritemSpacingForSectionAtIndex section: Int) -> CGFloat {
        return PostManager.NewsFeedLineSpacing
    }
}
