//
//  ShareViewController.swift
//  merchant-ios
//
//  Created by Vo Huy Hung on 3/18/16.
//  Copyright © 2016 WWE & CO. All rights reserved.
//

import UIKit
import PromiseKit
import ObjectMapper

enum ViewHeight: CGFloat {
    case viewHeaderHeight = 44,
    viewCollectionViewHeight = 100,
    viewSeperateLineHeight = 1
}

class ShareViewController: MmViewController, UITextFieldDelegate {
    
//    private final let ContentViewHeight = CGFloat(451)
    
    static let ConfirmViewHeight = CGFloat(72)
    private final let ConfirmButtonMargin = CGFloat(12)
    private final var HeaderHeight : CGFloat = ViewHeight.viewHeaderHeight.rawValue
    static let CollectionViewHeight : CGFloat = ViewHeight.viewCollectionViewHeight.rawValue
    private final var CollectionViewFriendHeight : CGFloat = ViewHeight.viewCollectionViewHeight.rawValue
    
    static let PhotoContainerTopPadding : CGFloat = 100
    static let CapscreenPadding = UIEdgeInsets(top: 25, left: 30, bottom: 10, right: 30)
    
    static let CapscreenContentRatio : CGFloat = 1.5
    
    private final var SeperateLineHeight : CGFloat = ViewHeight.viewSeperateLineHeight.rawValue
    private final let CornerRadius : CGFloat = 10
    
    private let sectionInsets = UIEdgeInsets(top: 10, left: 12.0, bottom: 10, right: 12.0)
    private let sizeOfCell = CGSize(width: 70, height: 80)
    
    private let minimumLineSpacing : CGFloat = 15
    private let minimumInteritemSpacing : CGFloat = 10
    private final let MarginLeftRight : CGFloat = 15
    private final let DefaultCellID = "DefaultCellID"
    private final let ShareCellID = "ShareCellID"
    private final let ShareHeaderViewID = "ShareHeaderViewID"
    
    private let contentView = UIView()
    private let topView = UIView()
    private let searchView = UIView()
    private var confirmView : UIView?
    private let searchTextField = UITextField()
    private let searchButton = UIButton(type: UIButtonType.system)
    private var confirmButton = UIButton(type: UIButtonType.system)
    private var originFriends: [User] = []
    private var filteredFriends: [User] = []
    var didUserSelectedHandler: ((User) -> ())?
    var didMMSelectedHandler: (() -> Void)?
    var didSelectSNSHandler: ((ShareMethod) -> ())?
    
    var provideCapscreenView: (() -> (UIView))?
    
    private var collectionViewFriend: UICollectionView?
    
    var viewKey = ""
    
    var isSharePost:Bool = false
    
    private var isSharingByScreenCap = false
    var isSharingByInviteFriend = false
    
    required init(nibName nibNameOrNil: String?, bundle nibBundleOrNil: Bundle?) {
        super.init(nibName: nibNameOrNil, bundle: nibBundleOrNil)
        self.modalPresentationStyle = .overFullScreen
    }
    
    convenience init(screenCapSharing: Bool = false) {
        self.init(nibName: nil, bundle: nil)
        self.isSharingByScreenCap = screenCapSharing
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()

        // Do any additional setup after loading the view.
        self.collectionView.delegate = nil
        self.collectionView.dataSource = nil
        self.collectionView.backgroundColor = UIColor.clear
        self.view.backgroundColor = UIColor.clear
        
        let tapSearchView = UITapGestureRecognizer(target: self, action: #selector(self.didClickSearchIcon))
        searchView.addGestureRecognizer(tapSearchView)
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        NotificationCenter.default.addObserver(self, selector: #selector(self.keyboardWillShow), name:NSNotification.Name.UIKeyboardWillShow, object: nil);
        NotificationCenter.default.addObserver(self, selector: #selector(self.keyboardWillHide), name:NSNotification.Name.UIKeyboardWillHide, object: nil);
        
        //load from will appear to has animation
        
        if isSharingByScreenCap {
            setupLayoutForScreenCap()
        }else {
            if isSharingByInviteFriend {
                self.setupLayoutForInviteFriend()
            }else {
                 loadFriendList()
            }
        }

    }
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        NotificationCenter.default.removeObserver(self)
    }

    func showSheetView(){
        UIView.animate(withDuration: 0.3, animations: { () -> Void in
            self.contentView.transform = CGAffineTransform(translationX: 0, y: -self.contentView.bounds.height)
        }) 
    }
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    func createPhotoSection() -> CGRect {
        let photoContainer = UIView()
        photoContainer.frame = CGRect(x: 0, y: 0, width: self.topView.bounds.width, height: contentView.frame.height - ShareViewController.ConfirmViewHeight - ShareViewController.CollectionViewHeight - 1)
        
        let shareContentViewHeight = photoContainer.height - ShareViewController.CapscreenPadding.top - ShareViewController.CapscreenPadding.bottom * 2 - 20
        let shareContentViewWidth = shareContentViewHeight / ShareViewController.CapscreenContentRatio
        
        let shareContentView = UIView(frame: CGRect(x: (photoContainer.frame.width - shareContentViewWidth) / 2 , y: ShareViewController.CapscreenPadding.top, width: shareContentViewWidth, height: shareContentViewHeight))
        shareContentView.backgroundColor = UIColor.white
        shareContentView.layer.shadowColor = UIColor.black.cgColor
        shareContentView.layer.shadowOpacity = 0.5
        shareContentView.layer.shadowOffset = CGSize.zero
        shareContentView.layer.shadowRadius = 10
        
        let descriptionLabel = UILabel(frame: CGRect(x: 0, y: shareContentView.frame.maxY + ShareViewController.CapscreenPadding.bottom, width: self.topView.bounds.width, height: 20))
        descriptionLabel.text = String.localize("LB_CA_SCREEN_CAP_TO_SHARE")
        descriptionLabel.textAlignment = .center
        descriptionLabel.formatSizeBold(15)
        descriptionLabel.textColor = UIColor.secondary4()
        
        photoContainer.addSubview(descriptionLabel)
        photoContainer.addSubview(shareContentView)
        

        self.topView.addSubview(photoContainer)
        
        
        if let capscreenBlock = self.provideCapscreenView {
            let capscreen = capscreenBlock()
            capscreen.frame = shareContentView.bounds
            shareContentView.addSubview(capscreen)
        }
        
        return photoContainer.frame
    }
    
    func setupLayoutForScreenCap(){
        HeaderHeight = ViewHeight.viewHeaderHeight.rawValue
        CollectionViewFriendHeight = ViewHeight.viewCollectionViewHeight.rawValue
        SeperateLineHeight = ViewHeight.viewSeperateLineHeight.rawValue
        
        self.contentView.frame =  CGRect(x: 0, y: self.view.bounds.height, width: self.view.bounds.width , height: self.view.bounds.height - ShareViewController.PhotoContainerTopPadding)
        self.contentView.backgroundColor = UIColor.clear
        view.addSubview(self.contentView)
        
        
        topView.frame = CGRect(x: MarginLeftRight, y: 0, width: self.view.bounds.width - MarginLeftRight * 2 , height: self.contentView.frame.height - ShareViewController.ConfirmViewHeight)
        topView.backgroundColor = UIColor(white: 1, alpha: 0.8)
        topView.clipsToBounds = true
        self.topView.layer.cornerRadius = CornerRadius
        self.contentView.addSubview(topView)
        
        // transparent view
        let transparentView = UIView()
        transparentView.backgroundColor = UIColor.init(white: 0.0, alpha: 0.6)
        transparentView.frame = self.view.bounds
        transparentView.autoresizingMask = [.flexibleWidth, .flexibleHeight]
        transparentView.addGestureRecognizer(UITapGestureRecognizer(target: self, action: #selector(ShareViewController.dismissWithoutCallback)))
        self.view.insertSubview(transparentView, belowSubview: contentView)

        
        let photoSectionRect = self.createPhotoSection()
        
        let line2 = UIView()
        line2.backgroundColor = UIColor.secondary4()
        line2.frame = CGRect(x: 0, y: photoSectionRect.maxY, width: self.topView.bounds.width, height: SeperateLineHeight)
        self.topView.addSubview(line2)
        self.createCollectionView(line2.frame)
        
        // confirm view
        confirmView = { () -> UIView in
            let view = UIView(frame: CGRect(x: 0, y: contentView.bounds.height - ShareViewController.ConfirmViewHeight, width: contentView.bounds.width, height: ShareViewController.ConfirmViewHeight))
            
            confirmButton = UIButton(frame: CGRect(x: ConfirmButtonMargin, y: ConfirmButtonMargin, width: self.view.bounds.width - ConfirmButtonMargin*2 , height: ShareViewController.ConfirmViewHeight - ConfirmButtonMargin*2))
            confirmButton.setTitle(String.localize("LB_CX"), for: UIControlState())
            confirmButton.formatPrimary()
            confirmButton.layer.cornerRadius = CornerRadius
            confirmButton.setTitleColor(UIColor.black, for: UIControlState())
            confirmButton.backgroundColor = UIColor.white
            confirmButton.addTarget(self, action: #selector(ShareViewController.confirmButtonTapped), for: .touchUpInside)
            view.addSubview(confirmButton)
            
            return view
        } ()
        if let confirmView = self.confirmView {
            self.contentView.addSubview(confirmView)
        }
        
        self.reloadDataSource()
        self.showSheetView()
    }
    
    func setupLayoutForInviteFriend() {
        HeaderHeight = ViewHeight.viewHeaderHeight.rawValue
        CollectionViewFriendHeight = 0
        SeperateLineHeight = ViewHeight.viewSeperateLineHeight.rawValue
        
        self.contentView.frame =  CGRect(x: 0, y: self.view.bounds.height, width: self.view.bounds.width , height: HeaderHeight + ShareViewController.CollectionViewHeight + CollectionViewFriendHeight + 2 + ShareViewController.ConfirmViewHeight)
        self.contentView.backgroundColor = UIColor.clear
        view.addSubview(self.contentView)
        
        
        topView.frame = CGRect(x: MarginLeftRight, y: 0, width: self.view.bounds.width - MarginLeftRight * 2 , height: HeaderHeight + ShareViewController.CollectionViewHeight + CollectionViewFriendHeight + 2)
        topView.backgroundColor = UIColor.white
        topView.clipsToBounds = true
        self.topView.layer.cornerRadius = CornerRadius
        self.contentView.addSubview(topView)
        
        let titleLabel = UILabel()
        titleLabel.formatSize(14)
        titleLabel.textColor = UIColor.secondary2()
        titleLabel.textAlignment = .center
        titleLabel.text = String.localize("LB_CA_INCENTIVE_REF_INVITE")
        titleLabel.frame = CGRect(x: 0, y: 0, width: topView.frame.sizeWidth, height: HeaderHeight)
        topView.addSubview(titleLabel)
        
//        self.createSearchView()
        // transparent view
        let transparentView = UIView()
        transparentView.backgroundColor = UIColor.init(white: 0.0, alpha: 0.6)
        transparentView.frame = self.view.bounds
        transparentView.autoresizingMask = [.flexibleWidth, .flexibleHeight]
        transparentView.addGestureRecognizer(UITapGestureRecognizer(target: self, action: #selector(ShareViewController.dismissWithoutCallback)))
        self.view.insertSubview(transparentView, belowSubview: contentView)
        
        let line1 = UIView()
        line1.backgroundColor = UIColor.secondary1()
        line1.frame = CGRect(x: 0, y: HeaderHeight, width: self.topView.bounds.width, height: SeperateLineHeight)
        self.topView.addSubview(line1)
        self.createCollectionViewFriend()
        let line2 = UIView()
        line2.backgroundColor = UIColor.secondary1()
        line2.frame = CGRect(x: 0, y: self.collectionViewFriend!.frame.maxY, width: self.topView.bounds.width, height: SeperateLineHeight)
        self.topView.addSubview(line2)
        self.createCollectionView(line2.frame)
        
        // confirm view
        confirmView = { () -> UIView in
            let view = UIView(frame: CGRect(x: 0, y: contentView.bounds.height - ShareViewController.ConfirmViewHeight, width: contentView.bounds.width, height: ShareViewController.ConfirmViewHeight))
            
            confirmButton = UIButton(frame: CGRect(x: ConfirmButtonMargin, y: ConfirmButtonMargin, width: self.view.bounds.width - ConfirmButtonMargin*2 , height: ShareViewController.ConfirmViewHeight - ConfirmButtonMargin*2))
            confirmButton.setTitle(String.localize("LB_CX"), for: UIControlState())
            confirmButton.formatPrimary()
            confirmButton.layer.cornerRadius = CornerRadius
            confirmButton.setTitleColor(UIColor.black, for: UIControlState())
            confirmButton.backgroundColor = UIColor.white
            confirmButton.addTarget(self, action: #selector(ShareViewController.confirmButtonTapped), for: .touchUpInside)
            view.addSubview(confirmButton)
            
            return view
        } ()
        if let confirmView = self.confirmView {
            self.contentView.addSubview(confirmView)
        }
        
        self.reloadDataSource()
        self.showSheetView()

    }
    
    func setupLayout() {
        
        HeaderHeight = ViewHeight.viewHeaderHeight.rawValue
        CollectionViewFriendHeight = ViewHeight.viewCollectionViewHeight.rawValue
        SeperateLineHeight = ViewHeight.viewSeperateLineHeight.rawValue
        
        self.contentView.frame =  CGRect(x: 0, y: self.view.bounds.height, width: self.view.bounds.width , height: HeaderHeight + ShareViewController.CollectionViewHeight + CollectionViewFriendHeight + 2 + ShareViewController.ConfirmViewHeight)
        self.contentView.backgroundColor = UIColor.clear
        view.addSubview(self.contentView)
        
        
        topView.frame = CGRect(x: MarginLeftRight, y: 0, width: self.view.bounds.width - MarginLeftRight * 2 , height: HeaderHeight + ShareViewController.CollectionViewHeight + CollectionViewFriendHeight + 2)
        topView.backgroundColor = UIColor.white
        topView.clipsToBounds = true
        self.topView.layer.cornerRadius = CornerRadius
        self.contentView.addSubview(topView)
        self.createSearchView()
        // transparent view
        let transparentView = UIView()
        transparentView.backgroundColor = UIColor.init(white: 0.0, alpha: 0.6)
        transparentView.frame = self.view.bounds
        transparentView.autoresizingMask = [.flexibleWidth, .flexibleHeight]
        transparentView.addGestureRecognizer(UITapGestureRecognizer(target: self, action: #selector(ShareViewController.dismissWithoutCallback)))
        self.view.insertSubview(transparentView, belowSubview: contentView)
        
        let line1 = UIView()
        line1.backgroundColor = UIColor.secondary1()
        line1.frame = CGRect(x: 0, y: HeaderHeight, width: self.topView.bounds.width, height: SeperateLineHeight)
        self.topView.addSubview(line1)
        self.createCollectionViewFriend()
        let line2 = UIView()
        line2.backgroundColor = UIColor.secondary1()
        line2.frame = CGRect(x: 0, y: self.collectionViewFriend!.frame.maxY, width: self.topView.bounds.width, height: SeperateLineHeight)
        self.topView.addSubview(line2)
        self.createCollectionView(line2.frame)

        // confirm view
        confirmView = { () -> UIView in
            let view = UIView(frame: CGRect(x: 0, y: contentView.bounds.height - ShareViewController.ConfirmViewHeight, width: contentView.bounds.width, height: ShareViewController.ConfirmViewHeight))
            
            confirmButton = UIButton(frame: CGRect(x: ConfirmButtonMargin, y: ConfirmButtonMargin, width: self.view.bounds.width - ConfirmButtonMargin*2 , height: ShareViewController.ConfirmViewHeight - ConfirmButtonMargin*2))
            confirmButton.setTitle(String.localize("LB_CX"), for: UIControlState())
            confirmButton.formatPrimary()
            confirmButton.layer.cornerRadius = CornerRadius
            confirmButton.setTitleColor(UIColor.black, for: UIControlState())
            confirmButton.backgroundColor = UIColor.white
            confirmButton.addTarget(self, action: #selector(ShareViewController.confirmButtonTapped), for: .touchUpInside)
            view.addSubview(confirmButton)
            
            return view
        } ()
        if let confirmView = self.confirmView {
            self.contentView.addSubview(confirmView)
        }
        
        self.reloadDataSource()
        self.showSheetView()
    }
   
    func createSearchView()  {
        searchView.frame = CGRect(x: 0, y: 0, width: self.topView.bounds.width , height: HeaderHeight)
        searchView.backgroundColor = UIColor.white
        searchView.clipsToBounds = true
        
        self.topView.addSubview(searchView)
        if let imageSearch = UIImage(named: "search_grey") {
            searchButton.setImage(imageSearch, for: UIControlState())
            searchButton.frame = CGRect(x: 15, y: (searchView.frame.height - imageSearch.size.height) / 2, width: imageSearch.size.width, height: imageSearch.size.height)
            searchButton.tintColor = UIColor.gray
            searchButton.addTarget(self, action: #selector(self.didClickSearchIcon), for: UIControlEvents.touchUpInside)
            self.searchView.addSubview(searchButton)
        }
        self.searchTextField.frame = CGRect(x: searchButton.frame.maxX + 5, y: 0, width: self.searchView.frame.width - (searchButton.frame.maxX + 10) - 5, height: HeaderHeight)
        self.searchTextField.delegate = self
        self.searchTextField.returnKeyType = .search
        self.searchTextField.formatSize(15)
        self.searchTextField.layer.borderWidth = 0
        self.searchTextField.textAlignment = .center
        self.searchTextField.placeholder = String.localize("LB_SHARE_TO_FRIENDS")
        self.searchTextField.rightViewMode = .always
        self.searchTextField.isEnabled = false
        let clearButton = UIButton(type: UIButtonType.system)
        clearButton.setImage(UIImage(named: "icon_search"), for: UIControlState())
        clearButton.frame = CGRect(x: searchTextField.frame.width - 22, y: (searchTextField.frame.height - 22) / 2, width: 32, height: 22)
        clearButton.tintColor = UIColor.gray
        clearButton.addTarget(self, action: #selector(self.didClickClearButton), for: UIControlEvents.touchUpInside)
        clearButton.isHidden = true
        self.searchTextField.rightView = clearButton
        if let clearButton =  self.searchTextField.value(forKey: "_clearButton") {
            (clearButton as AnyObject).setImage(UIImage(named: "icon_search"), for: UIControlState())
        }
        self.searchView.addSubview(searchTextField)
    }
    
    func createCollectionViewFriend() {
        
        let layout: UICollectionViewFlowLayout = getCustomFlowLayout()
        layout.sectionInset = UIEdgeInsets(top: 0, left: 0, bottom: 0, right: 0)
        layout.itemSize = CGSize(width: self.view.frame.width, height: 120)
        layout.scrollDirection = UICollectionViewScrollDirection.horizontal
        let frame =  CGRect(x: 0, y: HeaderHeight + 1, width: topView.bounds.width, height: CollectionViewFriendHeight)
        
        let collectionViewFriend = UICollectionView(frame: frame, collectionViewLayout: layout)
        collectionViewFriend.dataSource = self
        collectionViewFriend.delegate = self
        collectionViewFriend.bounces = false
        collectionViewFriend.showsHorizontalScrollIndicator = false
        collectionViewFriend.alwaysBounceHorizontal = true
        collectionViewFriend.register(UICollectionViewCell.self, forCellWithReuseIdentifier: "Cell")
        collectionViewFriend.backgroundColor = UIColor.white
        collectionViewFriend.register(ShareCell.self, forCellWithReuseIdentifier: self.ShareCellID)
        
        collectionViewFriend.register(UICollectionViewCell.self, forCellWithReuseIdentifier: self.DefaultCellID)
        
        self.collectionViewFriend = collectionViewFriend
        self.topView.addSubview(collectionViewFriend)
    }
    
    
    func createCollectionView(_ topViewFrame: CGRect) {
        let layout = self.collectionView.collectionViewLayout as! UICollectionViewFlowLayout
        layout.scrollDirection = UICollectionViewScrollDirection.horizontal
        // collection view
        self.collectionView.frame = CGRect(x: 0, y: topViewFrame.maxY, width: topView.bounds.width, height: ShareViewController.CollectionViewHeight)
        self.collectionView.delegate = self
        self.collectionView.dataSource = self
        self.collectionView?.backgroundColor = UIColor.clear
        self.collectionView?.alwaysBounceHorizontal = true
        self.collectionView?.alwaysBounceVertical = false
        self.collectionView?.bounces = false
        self.collectionView?.showsHorizontalScrollIndicator = false
        self.collectionView?.register(ShareCell.self, forCellWithReuseIdentifier: self.ShareCellID)
        self.collectionView?.register(UICollectionViewCell.self, forCellWithReuseIdentifier: self.DefaultCellID)
        self.collectionView?.register(ShareHeaderView.self, forSupplementaryViewOfKind: UICollectionElementKindSectionHeader, withReuseIdentifier: ShareHeaderViewID)
        
        self.topView.addSubview(collectionView)
    }
    
    @objc func confirmButtonTapped() {
        confirmButton.initAnalytics(withViewKey: self.viewKey)
        confirmButton.recordAction(.Tap, sourceRef: "Cancel", sourceType: .Button, targetRef: "Share", targetType: .View)
        dismiss(nil)
    }
    
    @objc func dismissWithoutCallback() {
        self.dismiss(nil)
    }
    
    func dismiss(_ completion: (() -> Void)?){
        self.searchTextField.resignFirstResponder()
        UIView.animate(
            withDuration: 0.3,
            animations: { () -> Void in
                self.contentView.transform = CGAffineTransform.identity
            },
            completion: { (success) -> Void in
                self.dismiss(animated: false, completion: completion)
            }
        )
    }
    
    
    func loadFriendList() {
        if LoginManager.getLoginState() == .validUser {
//            self.originFriends = CacheManager.sharedManager.friendList
//            self.filteredFriends = self.originFriends.filter({$0.displayName.length > 0})
            self.setupLayout()
            
            //update list friend if there have more friend added
            updateFriendList()
        }
        else{
            self.setupLayout()
        }
    }
    
    func updateFriendList() {
        firstly{
            return self.listFriend()
            }.then
            { _ -> Void in
                self.filteredFriends = self.originFriends.filter({$0.displayName.length > 0})
                self.reloadDataSource()
            }.catch { _ -> Void in
                Log.error("error")
        }
    }
    
    func listFriend() -> Promise<Any> {
        return Promise{ fulfill, reject in
            FriendService.listFriends(){
                [weak self] (response) in
                if let strongSelf = self {
                    if response.result.isSuccess {
                        if response.response?.statusCode == 200 {
                            
                            let friend:[User] = Mapper<User>().mapArray(JSONObject: response.result.value) ?? []
                            
                            if friend.count > 0 {
                                strongSelf.originFriends += friend
                                strongSelf.filteredFriends = strongSelf.originFriends.filter({$0.displayName.length > 0})
                            }
                            
                            fulfill("OK")
                        } else {
                            strongSelf.handleApiResponseError(response, reject: reject)
                        }
                    }
                    else{
                        reject(response.result.error!)
                        strongSelf.handleApiResponseError(response, reject: reject)
                    }
                }
                else {
                    ErrorLogManager.sharedManager.recordNonFatalError(withException: .NullPointer)
                }
            }
        }
    }
    
    func reloadDataSource() {
        self.collectionView.reloadData()
        if !self.isSharingByScreenCap, let collectionViewFriend = self.collectionViewFriend {
            collectionViewFriend.reloadData()
        }
    }
    
    //MARK: CollectionView Data Source, Delegate Method
    func numberOfSections(in collectionView: UICollectionView) -> Int {
        return 1
    }
    
    override func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        if collectionView == self.collectionViewFriend {
            if filteredFriends.count <= 0 {
                return 1
            } else {
                return filteredFriends.count
            }
            
        } else {
            return shareMethodIcons().count
        }
    }
    
    func shareMethodIcons() -> [(UIImage?, String, ShareMethod)]{
        var shareMethods = [(UIImage?, String, ShareMethod)]()
        if self.isSharePost{
            shareMethods.append((UIImage(named: "AppIcon"), "MM", ShareMethod.mmInternal))
        }
        shareMethods.append((UIImage(named: "wechat"), "微信好友", ShareMethod.weChatMessage))
        shareMethods.append((UIImage(named: "wechat-2"), "微信朋友圈", ShareMethod.weChatMoment))
        shareMethods.append((UIImage(named: "weibo"), "新浪微博", ShareMethod.weiboWall))
        shareMethods.append((UIImage(named: "qq_fiend"), "QQ好友", ShareMethod.qqMessage))
        shareMethods.append((UIImage(named: "qq_space"), "QQ空间", ShareMethod.qqZone))
        shareMethods.append((UIImage(named: "sms"), "短讯", ShareMethod.sms))
        return shareMethods
    }
    
    override func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        let cell = collectionView.dequeueReusableCell(withReuseIdentifier: ShareCellID, for: indexPath) as! ShareCell
        cell.backgroundColor = UIColor.clear
        
        if collectionView == self.collectionViewFriend {

            if self.filteredFriends.count > 0 {
                
                let user = self.filteredFriends[indexPath.row]
                cell.label.text = user.displayName
                cell.loadImageKey(user.profileImage, category: .user)
                cell.imageViewDiamond.isHidden = !(user.isCurator == 1)
                
                AnalyticsManager.sharedManager.recordImpression(impressionRef: "\(user.userKey)", impressionType: "User", impressionDisplayName: user.userName, positionComponent: "FriendList", positionIndex: indexPath.row, positionLocation: "Share", viewKey: viewKey)
                cell.initAnalytics(withViewKey: viewKey)
                
                return cell
                
            }else {
                cell.label.text = String.localize("LB_CA_ADD_NEW_FRIEND")
                cell.imageView.image = UIImage(named: "btn_share_addFriend")
                return cell
            }

            
        } else {

            
            cell.imageView.image = shareMethodIcons()[indexPath.row].0
            cell.label.adjustsFontSizeToFitWidth = true
            cell.label.text = shareMethodIcons()[indexPath.row].1
            cell.imageViewDiamond.isHidden = true
            
            return cell
            
        }

    }
    
//    func collectionView(_ collectionView: UICollectionView, viewForSupplementaryElementOfKind kind: String, at indexPath: IndexPath) -> UICollectionReusableView {
//        let headerView = collectionView.dequeueReusableSupplementaryView(ofKind: kind, withReuseIdentifier: ShareHeaderViewID, forIndexPath: indexPath) as! ShareHeaderView
//        
//        if indexPath.section == 0 {
//            headerView.titleLabel.text = String.localize("LB_CA_SHARE")
//        } else {
//            headerView.titleLabel.text = String.localize("LB_CA_PROFILE_MSG_CHAT")
//        }
//        
//        return headerView
//    }
    
//    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, referenceSizeForHeaderInSection section: Int) -> CGSize {
//        return CGSize(width: self.view.bounds.width, height: HeaderHeight)
//    }
    
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, insetForSectionAt section: Int) -> UIEdgeInsets {
        return sectionInsets
    }
    
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, sizeForItemAt indexPath: IndexPath) -> CGSize {
        return sizeOfCell
    }
    
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, minimumInteritemSpacingForSectionAt section: Int) -> CGFloat {
        return minimumInteritemSpacing
    }
    
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, minimumLineSpacingForSectionAt section: Int) -> CGFloat {
        return minimumLineSpacing
    }
    
    //MARK: Collection View Delegate methods
    func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        if collectionView == self.collectionView {
        
            let method = shareMethodIcons()[indexPath.row].2
            
            switch method {
            case .unknown:
                break
            case .weChatMessage, .weChatMoment, .qqMessage, .sms, .weiboWall, .qqZone:
                dismiss({
                    if let callback = self.didSelectSNSHandler {
                        callback(method)
                    }
                })
                self.recordAction(collectionView, indexPath: indexPath, method: method)
            case .mmInternal://MM Icon
                dismiss({
                    if let callback = self.didMMSelectedHandler {
                        callback()
                    }
                })
                self.recordAction(collectionView, indexPath: indexPath, method: method)
            default:
                break
            }
    
            
        }else if collectionView == self.collectionViewFriend {
			
			// detect guest mode
			if (LoginManager.getLoginState() != .validUser) {				
				self.dismiss(animated: true, completion: { 
					LoginManager.goToLogin()
					return
				})
			}
			
            if self.filteredFriends.count > 0 {
                let user =  self.filteredFriends[indexPath.row]
                
                Alert.alert(self, title: String.localize("LB_CA_FORWARD"), message:user.displayName , okActionComplete: { () -> Void in
                    if let callback = self.didUserSelectedHandler {
                        self.dismiss(nil)
                        callback(user)
                    }
                    }, cancelActionComplete:nil)
                
                if let cell = collectionView.cellForItem(at: indexPath) {
                    cell.recordAction(.Tap, sourceRef: "Share", sourceType: .Button, targetRef: user.userKey, targetType: .User)
                }
            }else {
                let viewController = AddFriendViewController()
                viewController.isPresenting = true
                let navi = MmNavigationController(rootViewController: viewController)
                
                self.dismiss({
                    if let activeController = ShareManager.sharedManager.getTopViewController() {
                        activeController.present(navi, animated: true, completion: {
                            
                        })
                    }
                })
                
            }
        }
        
    }
    
    func recordAction(_ collectionView: UICollectionView, indexPath: IndexPath, method: ShareMethod) {
        if let cell = collectionView.cellForItem(at: indexPath) {
            cell.initAnalytics(withViewKey: self.viewKey)
            switch method {
            case .weChatMoment:
                cell.recordAction(.Tap, sourceRef: "Share", sourceType: .Button, targetRef: "WechatMoments", targetType: .View)
            case .weChatMessage:
                cell.recordAction(.Tap, sourceRef: "Share", sourceType: .Button, targetRef: "WeChatFriends", targetType: .View)
            case .weiboWall:
                cell.recordAction(.Tap, sourceRef: "Share", sourceType: .Button, targetRef: "Weibo", targetType: .View)
            case .qqMessage:
                cell.recordAction(.Tap, sourceRef: "Share", sourceType: .Button, targetRef: "QQFriends", targetType: .View)
            case .qqZone:
                cell.recordAction(.Tap, sourceRef: "Share", sourceType: .Button, targetRef: "QQZone", targetType: .View)
            case .sms:
                cell.recordAction(.Tap, sourceRef: "Share", sourceType: .Button, targetRef: "SMS", targetType: .View)
            case .mmInternal:
                cell.recordAction(.Tap, sourceRef: "Share", sourceType: .Button, targetRef: "MyMM", targetType: .View)
            default:
                return
            }
            
        }
    }
    
    func textField(_ textField: UITextField, shouldChangeCharactersIn range: NSRange, replacementString string: String) -> Bool {
         Timer.scheduledTimer(timeInterval: 0.1, target: self, selector: #selector(self.doSearch), userInfo: nil, repeats: false)
        return true
    }
    func textFieldShouldBeginEditing(_ textField: UITextField) -> Bool {
        self.searchTextField.textAlignment = .left
        self.searchTextField.placeholder = String.localize("LB_AC_SEARCH")
        self.searchTextField.rightView?.isHidden = false
        return true
    }
    
    func textFieldDidEndEditing(_ textField: UITextField) {
        if textField.text?.length == 0 {
            self.searchTextField.textAlignment = .center
            self.searchTextField.placeholder = String.localize("LB_SHARE_TO_FRIENDS")
        } else {
            self.searchTextField.textAlignment = .left
        }
    }
    
    func textFieldShouldReturn(_ textField: UITextField) -> Bool {
        self.searchTextField.resignFirstResponder()
        if textField.text?.length == 0 {
            self.searchTextField.textAlignment = .center
            self.searchTextField.placeholder = String.localize("LB_SHARE_TO_FRIENDS")
        } else {
            self.searchTextField.textAlignment = .left
        }
        self.doSearch()
        return true
    }
    
    func didClickCancelButton() {
        self.searchTextField.resignFirstResponder()
        self.searchTextField.text = ""
        self.searchTextField.isEnabled = false
        self.searchTextField.textAlignment = .center
        self.searchTextField.placeholder = String.localize("LB_SHARE_TO_FRIENDS")
        doSearch()
    }
    
    @objc func didClickClearButton() {
        self.searchTextField.text = ""
        doSearch()
        
    }
    
    @objc func didClickSearchIcon() {
        self.searchTextField.isEnabled = true
        self.searchTextField.becomeFirstResponder()
        
        searchButton.initAnalytics(withViewKey: self.viewKey)
        searchButton.recordAction(.Tap, sourceRef: "Search", sourceType: .Button, targetRef: "Share", targetType: .View)
        
    }
    @objc func keyboardWillShow(_ sender: Notification) {
        if let userInfo = sender.userInfo {
            let keyboardRect = (userInfo[UIKeyboardFrameEndUserInfoKey] as! NSValue).cgRectValue
            let curve = (userInfo[UIKeyboardAnimationCurveUserInfoKey] as! NSNumber).uint32Value
            let options = UIViewAnimationOptions(rawValue: UInt(curve) << 16 | UIViewAnimationOptions.beginFromCurrentState.rawValue)
            let duration = (userInfo[UIKeyboardAnimationDurationUserInfoKey] as! NSNumber).doubleValue
            var frame = self.contentView.frame
            frame.origin.y = self.view.bounds.size.height - (self.contentView.frame.height + keyboardRect.height + 10 - ShareViewController.ConfirmViewHeight)
            self.confirmView?.isHidden = true
            UIView.animate(
                withDuration: duration,
                delay: 0,
                options: options,
                animations: {
                    self.contentView.frame = frame
                },
                completion: { bool in
                    
            })
        }
    }
    
    
    @objc func keyboardWillHide(_ sender: Notification) {
        if let userInfo = sender.userInfo {
            let curve = (userInfo[UIKeyboardAnimationCurveUserInfoKey] as! NSNumber).uint32Value
            let options = UIViewAnimationOptions(rawValue: UInt(curve) << 16 | UIViewAnimationOptions.beginFromCurrentState.rawValue)
            let duration = (userInfo[UIKeyboardAnimationDurationUserInfoKey] as! NSNumber).doubleValue
            var frame = self.contentView.frame
            frame.origin.y = self.view.bounds.size.height - self.contentView.frame.height
            UIView.animate(
                withDuration: duration,
                delay: 0,
                options: options,
                animations: {
                    self.contentView.frame = frame
                },
                completion: { bool in
                    self.confirmView?.isHidden = false
                    
            })
        }
    }
    
    @objc func doSearch() {
        let string = self.searchTextField.text!.trimmingCharacters(in:
            CharacterSet.whitespacesAndNewlines
            ).lowercased()
        if string.length > 0{
            self.filteredFriends = self.originFriends.filter({$0.userName.lowercased().range(of: string) != nil || $0.displayName.lowercased().range(of: string) != nil})
        } else {
            self.filteredFriends = self.originFriends.filter({$0.userName.length > 0 || $0.displayName.length > 0})
        }
        if let friendCollectionView = self.collectionViewFriend {
            friendCollectionView.reloadData()
        }
    }
}
