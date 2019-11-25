//
//  CommentViewController.swift
//  merchant-ios
//
//  Created by HVN_Pivotal on 5/6/16.
//  Copyright © 2016 WWE & CO. All rights reserved.
//


import Foundation
import ObjectMapper
import PromiseKit
import SnapKit
import Kingfisher
import Alamofire

class PostCommentViewController : MmViewController ,UITextViewDelegate, PostCommentViewCellDelegate {
    
    private final let CellHeight : CGFloat = 70
    private final let LowerLabelMinHeight : CGFloat = 24
    private var lowerLabel = UILabel()
    var post : Post?
    var commentActionBarView: PostCommentActionBarView!  //action bar
    var actionBarPaddingBottomConstraint: Constraint? //action bar 的 bottom Constraint
    //var postId: Int = 0
    var collectionviewContentInset = UIEdgeInsets.zero
    var user : User?
    private var hasLoadMore = true
    private var pageNo : Int = 1
    //var refreshControl = UIRefreshControl()

    private var filterdComments : [PostCommentList] = []
    private var tapDismissKeyboard : UITapGestureRecognizer?
    private var userTag: String = ""
    var selectedIndex = -1
    override func viewDidLoad() {
        super.viewDidLoad()
        
        if let font = UIFont(name: Constants.Font.Normal, size: 12) {
            lowerLabel.font = font
        } else {
            lowerLabel.formatSize(12)
        }

        tapDismissKeyboard = UITapGestureRecognizer(target: self, action: #selector(self.dismissKeyboard))
        
        self.setTitleName()
        self.view.backgroundColor = UIColor.white
        self.collectionView?.register(PostCommentViewCell.self, forCellWithReuseIdentifier: "PostCommentViewCell")
        
        self.collectionView?.register(PlaceHolderCell.self, forCellWithReuseIdentifier: PlaceHolderCell.PlaceHolderCellIdentifier)
        self.createBackButton()
        self.setupActionBar()
        collectionviewContentInset = self.collectionView.contentInset
        collectionView.backgroundColor = UIColor.primary2()
        self.updateComment(pageNo)
        //self.setUpRefreshControl()
        
        if let post = self.post {
            self.post?.postCommentLists = PostManager.getLocalCommentByPostId(post.postId)
        }
        initAnalyticLog()
        
        user = Context.getUserProfile()
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
       
        
        NotificationCenter.default.addObserver(self, selector: #selector(self.keyboardWillShow), name:NSNotification.Name.UIKeyboardWillShow, object: nil);
        NotificationCenter.default.addObserver(self, selector: #selector(self.keyboardDidShow), name:NSNotification.Name.UIKeyboardDidShow, object: nil);
        NotificationCenter.default.addObserver(self, selector: #selector(self.keyboardWillHide), name:NSNotification.Name.UIKeyboardWillHide, object: nil);
        
        
        if user?.userKey != Context.getUserKey() {
            self.viewUser(Context.getUserKey())
        }
        
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        NotificationCenter.default.removeObserver(self)
    }
    
    
    func setupActionBar()  {
        self.commentActionBarView = PostCommentActionBarView.fromNib()
        self.commentActionBarView.inputTextView.delegate = self
        self.view.addSubview(self.commentActionBarView)
        self.commentActionBarView.snp.makeConstraints { [weak self] (make) -> Void in
            guard let strongSelf = self else {
                return
            }
            make.left.equalTo(strongSelf.view.snp.left)
            make.right.equalTo(strongSelf.view.snp.right)
            strongSelf.actionBarPaddingBottomConstraint = make.bottom.equalTo(strongSelf.view.snp.bottom).constraint
            make.height.equalTo(PostCommentActionBarView.ACTION_BAR_HEIGHT + ScreenBottom)
        }

        self.commentActionBarView.shareButton.addTarget(self, action: #selector(self.didClickSendButton), for: UIControlEvents.touchUpInside)
        
    }
    
    //MARK : Refresh Control
    
//    func setUpRefreshControl(){
//        self.refreshControl.addTarget(self, action: #selector(self.refresh(_:)), for: UIControlEvents.ValueChanged)
//        self.collectionView.addSubview(refreshControl)
//        self.collectionView.alwaysBounceVertical = true
//    }
    
//    func refresh(sender : Any){
//        self.updateComment(1)
//        Log.debug("setUpRefreshControl")
//    }
    
    
    //MARK: Collection View methods and delegates
    override func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return self.filterdComments.count > 0 ? self.filterdComments.count : 1
    }
    
    func numberOfSections(in collectionView: UICollectionView) -> Int {
        return 1
    }
    
    override func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        
        if self.filterdComments.count == 0 {
            let cell = collectionView.dequeueReusableCell(withReuseIdentifier: PlaceHolderCell.PlaceHolderCellIdentifier, for: indexPath) as! PlaceHolderCell
            cell.descriptionLabel.text = String.localize("LB_CA_NO_COMMENT")
            return cell
        }
        let cell = collectionView.dequeueReusableCell(withReuseIdentifier: "PostCommentViewCell", for: indexPath) as! PostCommentViewCell
        
      
        
        let index = indexPath.row;//self.filterdComments.count - (indexPath.row + 1)
        let postCommentList = filterdComments[index]
        cell.upperLabel.text = postCommentList.displayName
        cell.lowerLabel.text = postCommentList.postCommentText
        cell.setImage(postCommentList.getProfileImage(), imageCategory: .user)
        cell.configImage(postCommentList.isCurator ? 1 : 0)
        cell.rightLabel.text = postCommentList.lastModified.commentTimeString
        cell.isCanDelete = (postCommentList.userKey == Context.getUserKey())
        cell.tag = index
      
        
        if postCommentList.userKey == Context.getUserKey() { // can delete a comment
            cell.rightMenuItems = [
                SwipeActionMenuCellData(
                    text: String.localize("LB_CA_DELETE"),
                    icon: UIImage(named: "icon_swipe_delete"),
                    backgroundColor: UIColor(hexString: "#7A848C"),
                    defaultAction: true,
                    action: { [weak self, weak cell] () -> Void in
                        if let strongSelf = self, let collectionCell = cell {
                            
                            Alert.alert(strongSelf, title: "", message: String.localize("LB_CA_DEL_COMMENT_CONF"), okActionComplete: { () -> Void in
                                strongSelf.deleteCommentAction(collectionCell,index: index)
                                }, cancelActionComplete: nil)
                        } else {
                            ErrorLogManager.sharedManager.recordNonFatalError(withException: .NullPointer)
                        }
                    }
                )
            ]
        }


        
        cell.delegate = self
        if(indexPath.row == 0) {
            if self.hasLoadMore {
                self.hasLoadMore = false
                self.updateComment(pageNo + 1)
            }
        }
        cell.analyticsViewKey = self.analyticsViewRecord.viewKey
        let commentIdString = "\(postCommentList.correlationKey)"
        
        var impressionDisplayName: String =  postCommentList.postCommentText
        if impressionDisplayName.length > 50 {
            let lowerBound = impressionDisplayName.index(impressionDisplayName.startIndex, offsetBy: 0)
            let upperBound = impressionDisplayName.index(impressionDisplayName.startIndex, offsetBy: 49)
            impressionDisplayName = String(impressionDisplayName[lowerBound...upperBound])
        }
        var postCode : String? = nil
        if let post = self.post {
            postCode = "\(post.postId)"
        }
        cell.initAnalytics(withViewKey: self.analyticsViewRecord.viewKey, impressionKey: AnalyticsManager.sharedManager.recordImpression(Context.getUserProfile().userKey,authorType: self.getAuthorType(),brandCode: nil, impressionRef: commentIdString, impressionType: "Comment", impressionDisplayName: impressionDisplayName, parentRef: postCode,parentType: "Post", positionComponent: "Comment", positionIndex: indexPath.row, positionLocation: "PostComment", referrerRef: nil, referrerType: nil, viewKey: self.analyticsViewRecord.viewKey))
        
        if self.selectedIndex >= 0 && self.selectedIndex == indexPath.row {
            cell.backgroundColor = UIColor.lightText
        }else {
            cell.backgroundColor = UIColor.white
        }

        
        return cell
    }
    
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, sizeForItemAt indexPath: IndexPath) -> CGSize {
        if filterdComments.count == 0 {
            return CGSize(width: self.view.frame.size.width , height: self.collectionView.frame.height)
        }
        let postCommentList = self.filterdComments[indexPath.row]
        let height = self.getTextHeight(postCommentList.postCommentText)
        return CGSize(width: self.view.frame.size.width , height: CellHeight + (height - LowerLabelMinHeight))
        
    }
    
    func collectionView(_ collectionView: UICollectionView,
                        layout collectionViewLayout: UICollectionViewLayout,
                               insetForSectionAt section: Int) -> UIEdgeInsets {
        return UIEdgeInsets(top: 0.0, left: 0.0, bottom: self.commentActionBarView.frame.size.height, right: 0.0)
    }
    
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, minimumInteritemSpacingForSectionAt section: Int) -> CGFloat {
        return 0.0
    }
    
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, minimumLineSpacingForSectionAt section: Int) -> CGFloat {
        return 5.0
    }
    
    func collectionView(_ collectionView: UICollectionView,
                        didSelectItemAt indexPath: IndexPath) {
        Log.debug("didSelectItemAtIndexPath: \(indexPath.row)")
        if (indexPath.row < filterdComments.count) {
            let postCommentList = filterdComments[indexPath.row]
            if postCommentList.userKey != Context.getUserKey() {
                let oldUserTag: String = userTag
                userTag = "@\(postCommentList.displayName) "
                if oldUserTag != userTag {
                    if self.commentActionBarView.inputTextView.text.contains(oldUserTag) {
                        self.commentActionBarView.inputTextView.text = self.commentActionBarView.inputTextView.text.replacingOccurrences(of: oldUserTag, with: userTag)
                    } else {
                        let currentCommentString = NSMutableString(string: self.commentActionBarView.inputTextView.text)
                        currentCommentString.insert(userTag, at: 0)
                        self.commentActionBarView.inputTextView.text = currentCommentString as String
                    }
                }
                self.commentActionBarView.inputTextView.becomeFirstResponder()
            }
            selectedIndex = indexPath.row
            self.collectionView.reloadData()
        }
    }
    
    @objc func dismissKeyboard() {
        self.commentActionBarView.inputTextView.resignFirstResponder()
    }
    func reloadDataSource() {
        if let postCommentLists = self.post?.postCommentLists {
            //self.filterdComments = postCommentLists.filter({$0.statusId != Constants.StatusID.deleted.rawValue}).sort(){$0.lastModified < $1.lastModified} ?? []
            self.filterdComments = postCommentLists.filter({$0.statusId != Constants.StatusID.deleted.rawValue}) 
            
        } else {
            self.filterdComments = []
        }
        self.collectionView.reloadData()
        
    }
    
    func getTextHeight(_ text: String) -> CGFloat {
        let constraintRect = CGSize(width: self.view.bounds.width - 84, height: CGFloat.greatestFiniteMagnitude)
        let boundingBox = text.boundingRect(with: constraintRect, options: NSStringDrawingOptions.usesLineFragmentOrigin, attributes: [NSAttributedStringKey.font: lowerLabel.font], context: nil)
        if boundingBox.height < LowerLabelMinHeight {
            return LowerLabelMinHeight;
        }
        return boundingBox.height + 1
    }

    func textViewShouldBeginEditing(_ textView: UITextView) -> Bool {
        UIView.setAnimationsEnabled(false)
        let range = NSRange(location: textView.text.length - 1, length: 1)
        textView.scrollRangeToVisible(range)
        UIView.setAnimationsEnabled(true)
        return true
    }
    
    func textView(_ textView: UITextView, shouldChangeTextIn range: NSRange, replacementText text: String) -> Bool {
        
        let currentString = textView.text as NSString?
        if let newString = currentString?.replacingCharacters(in: range, with:text) {
            if userTag.length > 0 && !newString.contains(userTag) {
                textView.text = currentString?.replacingOccurrences(of: userTag, with: "")
                userTag = ""
                textView.selectedRange = NSRange(location: 0, length: 0)
                return false
            }
        }
        
        return true
    }
    
    @objc func didClickSendButton() {
        if LoginManager.getLoginState() != .validUser {
            LoginManager.goToLogin()
            return
        }
        
     let commentext:String = self.commentActionBarView.inputTextView.text.trim()
            if commentext.length > 0{
                let comment = PostCommentList()
                comment.postId = self.post?.postId ?? 0
                comment.postCommentText = commentext
                self.createNewComment(comment)
                Log.debug("didClickSendButton")
            }

    }
    
    func createNewComment(_ comment: PostCommentList) {
        self.showLoading()
        firstly{
            return PostManager.savePostComment(comment)
        }.then { _ -> Void in
            Log.debug("success")
            self.userTag = ""
            if let post = self.post {
                comment.postCommentText = self.commentActionBarView.inputTextView.text
                comment.postId = self.post?.postId ?? 0
                comment.userId = Context.getUserId()
                comment.userKey = Context.getUserKey()
                comment.userName = self.user?.userName ?? ""
                comment.displayName = self.user?.displayName ?? ""
                comment.profileImage = self.user?.getProfileImage() ?? ""
                if let serverDate = TimestampService.defaultService.getServerTime() {
                    comment.lastCreated = serverDate
                    comment.lastModified = serverDate
                } else {
                    comment.lastCreated = Date()
                    comment.lastModified = Date()
                }
                comment.statusId = Constants.StatusID.active.rawValue
                self.commentActionBarView.inputTextView.text = ""
               
                if post.postCommentLists == nil {
                    post.postCommentLists = [comment]
                } else {
                    post.postCommentLists?.append(comment)
                }
                if let post = self.post {
                    PostManager.insertLocalPostCommentList(comment, post: post)
                }
                self.reloadDataSource()
                self.scrollCollectionViewToRow(self.filterdComments.count - 1, animation: true)
                
                self.setTitleName()
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
    
    @objc func keyboardWillHide(sender: NSNotification) {
        if let tapGesture = tapDismissKeyboard {
            self.view.removeGestureRecognizer(tapGesture)
        }
        
        var frame = self.commentActionBarView.frame

        frame.size.height = PostCommentActionBarView.ACTION_BAR_HEIGHT + ScreenBottom
        frame.origin.y = self.view.bounds.height - frame.height
        self.commentActionBarView.frame = frame
        self.actionBarPaddingBottomConstraint?.update(offset: 0)
        
        
        let duration = sender.userInfo?[UIKeyboardAnimationDurationUserInfoKey] as! NSNumber
        let curve = sender.userInfo?[UIKeyboardAnimationCurveUserInfoKey] as! NSNumber
        self.view.setNeedsLayout()
        UIView.animate(
            withDuration: TimeInterval(truncating: duration),
            delay: 0,
            options: [UIViewAnimationOptions(rawValue: UInt(truncating: curve))], animations: {
                self.collectionView.contentInset = self.collectionviewContentInset
                self.collectionView.scrollIndicatorInsets = self.collectionviewContentInset
                self.view.layoutIfNeeded()
        }, completion: nil)
    }
    
    @objc func keyboardWillShow(sender: NSNotification) {
        
        if let tapGesture = tapDismissKeyboard {
            self.view.addGestureRecognizer(tapGesture)
        }
        
        
        let duration = sender.userInfo?[UIKeyboardAnimationDurationUserInfoKey] as! NSNumber
        let curve = sender.userInfo?[UIKeyboardAnimationCurveUserInfoKey] as! NSNumber
        let keyboardRect = (sender.userInfo?[UIKeyboardFrameEndUserInfoKey] as! NSValue).cgRectValue
        
        let convertedFrame = self.view.convert(keyboardRect, from: nil)
        let heightOffset = self.view.bounds.size.height - convertedFrame.origin.y
        
        self.actionBarPaddingBottomConstraint?.update(offset: -heightOffset)
        collectionviewContentInset = self.collectionView.contentInset
        let contentInsets = UIEdgeInsets(top: collectionviewContentInset.top, left: collectionviewContentInset.left, bottom: collectionviewContentInset.bottom + keyboardRect.size.height, right: collectionviewContentInset.right)
        
        self.view.setNeedsLayout()
        UIView.animate(
            withDuration: TimeInterval(truncating: duration),
            delay: 0,
            options: [UIViewAnimationOptions(rawValue: UInt(truncating: curve))], animations: {
                self.collectionView.contentInset = contentInsets
                self.collectionView.scrollIndicatorInsets = contentInsets
                self.view.layoutIfNeeded()
        }, completion: nil)

    }
    
    @objc func keyboardDidShow(sender: NSNotification) {
        var frame = self.commentActionBarView.frame
        if frame.size.height != PostCommentActionBarView.ACTION_BAR_HEIGHT {
            let diff = frame.size.height - PostCommentActionBarView.ACTION_BAR_HEIGHT
            frame.size.height = PostCommentActionBarView.ACTION_BAR_HEIGHT
            frame.origin.y = frame.origin.y + diff
            self.commentActionBarView.frame = frame
        }
    }
    
    private func viewUser(_ userKey: String) {
        
        UserService.viewWithUserKey(userKey, completion: { (response) in
            if response.result.isSuccess {
                if response.response?.statusCode == 200 {
                    self.user = Mapper<User>().map(JSONObject: response.result.value) ?? User()
                }
            }
        })
    }
    
    func scrollCollectionViewToRow(_ row: Int, animation: Bool){
        if row > -1 && row < self.filterdComments.count {
            let indexPath = IndexPath(item: row, section: 0)
            self.collectionView.scrollToItem(at: indexPath, at: UICollectionViewScrollPosition.top, animated: animation)
        }
    }
    
    //MARK: PostCommentViewCellDelegate
    
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
        let publicProfileVC = ProfileViewController()
        publicProfileVC.currentType = postCommentList.userKey == Context.getUserKey() ? .Private : .Public
        publicProfileVC.isFromPostComment = true
        let user = User()
        user.userKey = postCommentList.userKey
        user.userName = postCommentList.userName
        publicProfileVC.publicUser =  user

        if publicProfileVC.currentType == .Public {
            PushManager.sharedInstance.goToProfile(user, hideTabBar: true)
        }else{
            self.navigationController?.pushViewController(publicProfileVC, animated: true)
        }
        
        
        
   }
    
    func deleteCommentAction(_ collectionViewCell: UICollectionViewCell, index: Int){
        if index < self.filterdComments.count {
            let postCommentList =  self.filterdComments[index]
            
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
                    self.setTitleName()
                    self.reloadDataSource()
                } .always {
                    self.stopLoading()
                }.catch { _ -> Void in
                    Log.error("error")
                    
            }
            var targetRef : String? = nil
            targetRef = postCommentList.correlationKey
            collectionViewCell.recordAction(
                .Tap,
                sourceRef: "DeleteComment",
                sourceType: .Button,
                targetRef: targetRef,
                targetType: .Comment)
        }

    }

    
    var previousCount = 0
    
    func updateComment(_ pageno: Int){

        let postId = (post?.postId ?? 0)
        firstly {
            return self.searchComment(postId, pageno: pageno)
            }.then { _ -> Void in
                self.reloadDataSource()
                
                self.scrollCollectionViewToRow(self.filterdComments.count - 1 - self.previousCount, animation: pageno != 1)
                self.previousCount = self.filterdComments.count
            }.always {
                //self.refreshControl.endRefreshing()
            }.catch { _ -> Void in
                Log.error("error @ updateComment")
        }
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
                                strongSelf.post?.postCommentLists?.sort(by: { $0.lastCreated < $1.lastCreated })
                                strongSelf.pageNo = pageno
                                strongSelf.hasLoadMore = listCommentListResponse.pageTotal > listCommentListResponse.pageCurrent //we have more page then current page
                            } else {
                                strongSelf.hasLoadMore = false
                            }
                            strongSelf.setTitleName()
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
    func setTitleName() {
//        self.title = String.localize("LB_CA_POST_COMMENT_COUNT").replacingOccurrences(of: "{0}", with: "\(self.totalComment + self.totalCommentLocalComment)")
        self.title = String.localize("LB_CA_POST_COMMENT_COUNT").replacingOccurrences(of: "{0}", with: "\(self.post?.commentCount ?? 0)")
    }
    
    // MARK: Tagging
    func initAnalyticLog(){
        var viewRef: String? = nil
        if let post = self.post {
            viewRef = "\(post.postId)"
        }
        initAnalyticsViewRecord(
            Context.getUserProfile().userKey,
            authorType: self.getAuthorType(),
            referrerRef: self.getReferrerRef(),
            referrerType: self.getReferrerType(),
            viewDisplayName: nil,
            viewParameters: "CommentListing",
            viewLocation: "PostComment",
            viewRef: viewRef,
            viewType: "Post"
        )
    }

    func getAuthorType() -> String? {
        if let post = self.post {
            if let user = post.userSource { // This post was shared
                return user.userTypeString()
            }
            else {
                return post.user?.userTypeString()
            }
        }
        return nil
    }
    
    func getReferrerType() -> String? {
        
        if let post = post {
            var referrerType = post.user?.userTypeString()
            if post.userSource != nil {
                referrerType = ""
            }
            return referrerType
        }
        
        return nil
    }
    
    func getReferrerRef() -> String? {
        if let post = post {
            var referrerRef = ""
            if let userSource = post.userSource {
                referrerRef = userSource.userKey
                return referrerRef
            }
        }
        return nil
    }
}
