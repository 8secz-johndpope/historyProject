//
//  ProfileCollectionReusableView.swift
//  merchant-ios
//
//  Created by Leslie Zhang on 2017/12/12.
//  Copyright © 2017年 WWE & CO. All rights reserved.
//

import UIKit
import YYText

class ProfileCollectionReusableView: UICollectionReusableView {
    var tapFans: (() -> Void)?
    var tapFollow: (() -> Void)?
    var tapCancelFollow: ((_ isFollow:Bool) -> ())?
    var tapAddFollow: ((_ isFollow:Bool) -> ())?
    var tapAvatar: ((_ user: User) -> ())?
    var tapFriend: ((_ friendStatus: StatusFriend) -> ())?
    var statusFriend: StatusFriend?
    var viewKey:String = ""
    var relationship: Relationship?{
        didSet{
            if let relationship = relationship {
                 changeFriendButton(relationship)
            }
        }

    }
    var isFollowUser:Bool? {
        didSet{
            if let isFollowUser = isFollowUser{
                changeFollowButton(isFollowUser)
            }
           
        }
    }
    var user: User? {
        didSet{
            if let user = user {
                nameLabel.text = String(user.displayName)
                introductionLabel.text = user.userDescription
                fansNumLabel.text = String(user.followerCount)
                followNumLabel.text = String(user.followingUserCount + user.followingCuratorCount)
                avatarImageView.mm_setImageWithURL(ImageURLFactory.URLSize256(user.profileImage, category: .user), placeholderImage : UIImage(named: "default_profile_icon"))
                if user.isCurator == 1 {
                memberImageView.image = UIImage(named: "curator_diamond")
                memberImageView.isHidden = false
                } else {
                memberImageView.image = UIImage()
                memberImageView.isHidden = true
                }
                if Context.getUserKey() == user.userKey {
                    followButton.isHidden = true
                }
            }
        }
    }
    var followingUsers: NSMutableArray? {
        didSet{
            if let followingUsers = followingUsers {
             
                if followingUsers.count > 0 {
                    boomView.isHidden = false
                    boomView.followingUsers = followingUsers
                }else{
                    boomView.isHidden = true
                    self.snp.makeConstraints({ (make) in
                        make.bottom.equalTo(fansLabel.snp.bottom).offset(10)
                    })
                }
            }
        }
    }
    lazy var avatarImageView: UIImageView = {
        let avatarImageView = UIImageView()
        avatarImageView.backgroundColor = UIColor.clear
        avatarImageView.layer.borderWidth = 2.0
        avatarImageView.layer.borderColor = UIColor.white.cgColor
        avatarImageView.layer.cornerRadius = 32
        avatarImageView.layer.masksToBounds = true
        avatarImageView.contentMode = UIViewContentMode.scaleAspectFill
        avatarImageView.tag = HeaderMyProfileCell.ImageType.Avatar.rawValue
        avatarImageView.isUserInteractionEnabled = true
        
        let tap = TapGestureRecognizer()
        avatarImageView.addGestureRecognizer(tap)
        tap.tapHandler = { [weak self] _ in
            if let strongSelf = self {
                if let callback = strongSelf.tapAvatar {
                    if let user = strongSelf.user {
                        callback(user)
                    }
                } else {
                    ErrorLogManager.sharedManager.recordNonFatalError(withException: .NullPointer)
                }
            }
        }
        return avatarImageView
    }()
    lazy var memberImageView:UIImageView = {
        let memberImageView = UIImageView()
        memberImageView.layer.cornerRadius = 8
        memberImageView.layer.masksToBounds = true
        return memberImageView
    }()
    lazy var nameLabel:UILabel = {
        let nameLabel = UILabel()
        nameLabel.font = UIFont.systemFont(ofSize: 18)
        return nameLabel
    }()
    lazy var introductionLabel:UILabel = {
        let introductionLabel = UILabel()
        introductionLabel.font = UIFont.systemFont(ofSize: 13)
        introductionLabel.numberOfLines = 2
        return introductionLabel
    }()
    lazy var fansNumLabel:YYLabel = {
        let fansNumLabel = YYLabel()
        fansNumLabel.font = UIFont.systemFont(ofSize: 14)
        fansNumLabel.textTapAction = { (view, attribute, range: NSRange, rect) in
            if let callback = self.tapFans {
                callback()
            } else {
                ErrorLogManager.sharedManager.recordNonFatalError(withException: .NullPointer)
            }
        }
        return fansNumLabel
    }()
    lazy var fansLabel:YYLabel = {
        let fansLabel = YYLabel()
        fansLabel.textColor = UIColor.gray
        fansLabel.font = UIFont.systemFont(ofSize: 12)
        fansLabel.text = String.localize("LB_CA_FOLLOWER")
        fansLabel.textTapAction = { (view, attribute, range: NSRange, rect) in
            if let callback = self.tapFans {
                callback()
            } else {
                ErrorLogManager.sharedManager.recordNonFatalError(withException: .NullPointer)
            }
        }
        return fansLabel
    }()
    lazy var followNumLabel:YYLabel = {
        let followNumLabel = YYLabel()
        followNumLabel.font = UIFont.systemFont(ofSize: 14)
        followNumLabel.textTapAction = { (view, attribute, range: NSRange, rect) in
            if let callback = self.tapFollow {
                callback()
            } else {
                ErrorLogManager.sharedManager.recordNonFatalError(withException: .NullPointer)
            }
        }
        return followNumLabel
    }()
    lazy var followLabel:YYLabel = {
        let followLabel = YYLabel()
        followLabel.textColor = UIColor.gray
        followLabel.font = UIFont.systemFont(ofSize: 12)
        followLabel.text = String.localize("LB_CA_FOLLOW")
        followLabel.textTapAction = { (view, attribute, range: NSRange, rect) in
            if let callback = self.tapFollow {
                callback()
            } else {
                ErrorLogManager.sharedManager.recordNonFatalError(withException: .NullPointer)
            }
        }
        return followLabel
    }()
    lazy var followButton:UIButton = {
        let followButton = UIButton()
        followButton.backgroundColor = UIColor(hexString: "#F5F5F5")
        followButton.setTitle(String.localize("LB_CA_FOLLOW"), for: UIControlState.normal)
        followButton.setTitleColor(UIColor.black, for: UIControlState.normal)
        followButton.titleLabel?.font = UIFont.systemFont(ofSize: 14)
        followButton.layer.cornerRadius = 4
        followButton.layer.masksToBounds = true
        followButton.setImage(UIImage.init(named: "Profile_add"), for: UIControlState.normal)
        followButton.setIconInLeftWithSpacing(10)
        followButton.addTarget(self, action:#selector(touchFollowButton), for: UIControlEvents.touchUpInside)

        return followButton
    }()
    lazy var cancelFollowButton:UIButton = {
        let cancelFollowButton = UIButton()
        cancelFollowButton.backgroundColor = UIColor.clear
        cancelFollowButton.addTarget(self, action:#selector(touchCancelFollowButton), for: UIControlEvents.touchUpInside)
        cancelFollowButton.setImage(UIImage(named: "followed"), for: UIControlState.normal)
        cancelFollowButton.isHidden = true
        return cancelFollowButton
    }()
    lazy var boomView:recentConcernsView = {
        let boomView = recentConcernsView()
        boomView.viewKey = self.viewKey
        return boomView
    }()
    
    init(frame: CGRect, viewKey:String) {
        super.init(frame: frame)
        
        self.viewKey = viewKey
        
        self.backgroundColor = UIColor.white
        
        self.addSubview(avatarImageView)
        self.addSubview(memberImageView)
        self.addSubview(nameLabel)
        self.addSubview(introductionLabel)
        self.addSubview(fansNumLabel)
        self.addSubview(fansLabel)
        self.addSubview(followNumLabel)
        self.addSubview(followLabel)
        self.addSubview(followButton)
        self.addSubview(cancelFollowButton)
        self.addSubview(boomView)
        
        avatarImageView.snp.makeConstraints { (make) in
            make.left.equalTo(15)
            make.width.height.equalTo(64)
            make.top.equalTo(self).offset(-32)
        }
        memberImageView.snp.makeConstraints { (make) in
            make.right.bottom.equalTo(avatarImageView).offset(-2)
            make.width.height.equalTo(16)
        }
        nameLabel.snp.makeConstraints { (make) in
            make.left.equalTo(avatarImageView)
            make.top.equalTo(avatarImageView.snp.bottom).offset(10)
            make.width.equalTo(ScreenWidth/2 - 10)
        }

        introductionLabel.snp.makeConstraints { (make) in
            make.left.equalTo(avatarImageView)
            make.top.equalTo(nameLabel.snp.bottom).offset(14)
            make.width.equalTo(ScreenWidth - 30)
        }
        fansNumLabel.snp.makeConstraints { (make) in
            make.left.equalTo(avatarImageView)
            make.top.equalTo(introductionLabel.snp.bottom).offset(10)
        }
        fansLabel.snp.makeConstraints { (make) in
            make.left.equalTo(avatarImageView)
            make.top.equalTo(fansNumLabel.snp.bottom)
        }
        followNumLabel.snp.makeConstraints { (make) in
            make.left.equalTo(fansLabel.snp.right).offset(40)
            make.top.equalTo(introductionLabel.snp.bottom).offset(10)
        }
        followLabel.snp.makeConstraints { (make) in
            make.left.equalTo(followNumLabel)
            make.top.equalTo(followNumLabel.snp.bottom)
        }
        followButton.snp.makeConstraints { (make) in
            make.top.equalTo(nameLabel)
            make.right.equalTo(self).offset(-15)
            make.width.equalTo(89)
            make.height.equalTo(32)
        }
        cancelFollowButton.snp.makeConstraints { (make) in
            make.width.equalTo(44)
            make.height.equalTo(32)
            make.left.equalTo(followButton.snp.right).offset(6)
            make.top.equalTo(followButton)
        }
        
        boomView.snp.makeConstraints { (make) in
            make.top.equalTo(fansLabel.snp.bottom).offset(10)
            make.left.right.width.equalTo(self)
            make.height.equalTo(76)
            make.bottom.equalTo(self)
        }
    }
    func changeFriendButton(_ relationship: Relationship) {
        var str:String
        if let isFollowUser = isFollowUser{
            if !isFollowUser {
                return
            }
        }
            if (relationship.isFriend == true) {
                str = String.localize("LB_CA_PROFILE_MSG_CHAT")
                statusFriend = StatusFriend.friend
            }else if (relationship.isFriendRequested == true) {
                str = String.localize("LB_CA_ULP_CANCEL_REQUEST")
                statusFriend = StatusFriend.pending
            }else if relationship.isFriendRequestReceived == true {
                statusFriend = StatusFriend.receivedFriendRequest
                str = String.localize("LB_CA_ULP_CHAT_REQUEST")
            }else {
                statusFriend = StatusFriend.unfriend
                str = String.localize("LB_CA_ULP_CHAT_REQUEST")
            }
       followButton.setTitle(str, for: UIControlState.normal)
        if relationship.isFriend == true {
            followButton.setImage(UIImage(named: "profile_wechat"), for: UIControlState.normal)
            followButton.setIconInLeftWithSpacing(10)
            followButton.initAnalytics(withViewKey: viewKey)
            followButton.recordAction(
                .Tap,
                sourceRef: "Chat",
                sourceType: .Button,
                targetRef: "\(String(describing: user?.userKey))",
                targetType: .User
            )
        }else{
            followButton.setImage(UIImage(named: ""), for: UIControlState.normal)
            followButton.setIconInLeftWithSpacing(0)
        }
    }
    
    func changeFollowButton(_ follow:Bool) {
        var titleStr:String
        var iconStr:String
        var point:CGFloat
        var followStr:String
        
        if follow {
            titleStr = String.localize("LB_CA_PROFILE_MSG_CHAT")
            point = 65
            cancelFollowButton.isHidden = false
            followStr = "Follow"
        }else{
            titleStr = String.localize("LB_CA_FOLLOW")
            iconStr = "Profile_add"
            point = 15
            cancelFollowButton.isHidden = true
            followButton.setIconInLeftWithSpacing(10)
            followButton.setImage(UIImage(named: iconStr), for: UIControlState.normal)
            followStr = "Unfollow"

        }
        followButton.initAnalytics(withViewKey: viewKey)
        followButton.recordAction(
            .Tap,
            sourceRef: followStr,
            sourceType: .Button,
            targetRef: "\(String(describing: user?.userKey))",
            targetType: .User
        )
        followButton.setTitle(titleStr, for: UIControlState.normal)
        followButton.snp.updateConstraints { (make) in
            make.right.equalTo(self).offset(-point)
        }
    }
    
    @objc func  touchCancelFollowButton()  {
        if let callback = self.tapCancelFollow {
            if let isFollowUser = isFollowUser{
                if isFollowUser {
                    callback(isFollowUser)
                }else{
                    
                }
            }
            
        } else {
            ErrorLogManager.sharedManager.recordNonFatalError(withException: .NullPointer)
        }
    }
    
    @objc func touchFollowButton()  {
        if let isFollowUser = isFollowUser{
            if isFollowUser {
                if let callback = self.tapFriend {
                    if let statusFriend = statusFriend{
                        callback(statusFriend)
                    }
                } else {
                    ErrorLogManager.sharedManager.recordNonFatalError(withException: .NullPointer)
                }
            }else{
                if let callback = self.tapAddFollow {
                    callback(isFollowUser)
                } else {
                    ErrorLogManager.sharedManager.recordNonFatalError(withException: .NullPointer)
                }
                
            }
        }
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
}

class recentConcernsView: UIView {
    var viewKey:String = ""
    var tapUser: ((User) -> ())?
    var followingUsers: NSMutableArray? {
        didSet{
            concernsCollectionView.reloadData()
        }
    }
    lazy var concernsLabel:UILabel = {
        let concernsLabel = UILabel()
        concernsLabel.text = String.localize("LB_CA_ULP_RECENTLY_FOLLOWED")
        concernsLabel.font = UIFont.systemFont(ofSize: 12)
        return concernsLabel
    }()
    
    lazy var concernsCollectionView:UICollectionView = {
        let layout = UICollectionViewFlowLayout()
        layout.minimumInteritemSpacing = 10
        layout.itemSize = CGSize(width: 32, height: 32)
        layout.scrollDirection = UICollectionViewScrollDirection.horizontal
        layout.sectionInset = UIEdgeInsets(top: 0, left: 10, bottom: 0, right: 10)
        
        let concernsCollectionView = UICollectionView.init(frame: CGRect.zero, collectionViewLayout: layout)
        concernsCollectionView.backgroundColor = UIColor(hexString: "#F5F5F5")
        concernsCollectionView.register(ProfileBoomCollectionViewCell.self, forCellWithReuseIdentifier: "ProfileBoomCollectionViewCell")
        concernsCollectionView.showsHorizontalScrollIndicator = false
        return concernsCollectionView
    }()
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        
        self.backgroundColor = UIColor(hexString: "#F5F5F5")
        
        self.addSubview(concernsLabel)
        self.addSubview(concernsCollectionView)
        
        concernsCollectionView.delegate = self
        concernsCollectionView.dataSource = self
        
        concernsLabel.snp.makeConstraints { (make) in
            make.top.equalTo(self).offset(10)
            make.left.equalTo(self).offset(15)
        }
        
        concernsCollectionView.snp.makeConstraints { (make) in
            make.top.equalTo(concernsLabel.snp.bottom)
            make.left.bottom.right.width.equalTo(self)
        }
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}

extension recentConcernsView:UICollectionViewDelegate,UICollectionViewDataSource{
    
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        if let follwingUser = followingUsers{
            return follwingUser.count
        }else{
            return 0
        }
    }
    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        let cell = collectionView.dequeueReusableCell(withReuseIdentifier: "ProfileBoomCollectionViewCell", for: indexPath) as! ProfileBoomCollectionViewCell
        if let follwingUser = followingUsers{
            cell.user = follwingUser[indexPath.row] as? User
        }
        return cell
    }
    func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        if let follwingUser = followingUsers{
            let user = follwingUser[indexPath.row] as? User
            
            if let tapUser = tapUser {
                if let user = user {
                    let cell = collectionView.cellForItem(at: indexPath) as! ProfileBoomCollectionViewCell
                    cell.initAnalytics(withViewKey: viewKey)
                    cell.recordAction(
                        .Tap,
                        sourceRef: "\(user.userKey)",
                        sourceType: .Avatar,
                        targetRef: "UPP",
                        targetType: .View
                    )
                    tapUser(user)
                }
          
            }
        }
    }
}

class ProfileBoomCollectionViewCell: UICollectionViewCell {
    var user: User? {
        didSet{
            if let user = user {

                avatarImageView.mm_setImageWithURL(ImageURLFactory.URLSize256(user.profileImage, category: .user), placeholderImage : UIImage(named: "default_profile_icon"))
                
            }
        }
    }
    lazy var avatarImageView:UIImageView = {
        let avatarImageView = UIImageView(frame: self.bounds)
        avatarImageView.backgroundColor = UIColor.red
        avatarImageView.layer.cornerRadius = 16
        avatarImageView.layer.masksToBounds = true
        return avatarImageView
    }()
    override init(frame: CGRect) {
        super.init(frame: frame)
        
        self.addSubview(avatarImageView)
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}

class ProfileDetailCollectionViewCell: UICollectionViewCell {
    var post: Post? {
        didSet{
            if let post = post{
                imageView.mm_setImageWithURL(ImageURLFactory.URLSize1000(post.postImage, category: .post), placeholderImage : UIImage(named: "postPlaceholder"))
                introductionLabel.text = post.postText
            }
        }
    }
    lazy var imageView:UIImageView = {
        let imageView = UIImageView()
        imageView.backgroundColor = UIColor.clear
        return imageView
    }()
    
    lazy var introductionLabel:YYLabel = {
        let introductionLabel = YYLabel()
        introductionLabel.textColor = UIColor.secondary2()
        introductionLabel.lineBreakMode = NSLineBreakMode.byTruncatingTail
        introductionLabel.numberOfLines = 3
        introductionLabel.tintColor = UIColor.hashtagColor()
        introductionLabel.isUserInteractionEnabled = true
        return introductionLabel
    }()
    
    lazy var avatarImageView:UIImageView = {
        let avatarImageView = UIImageView()
        avatarImageView.backgroundColor = UIColor.clear
        avatarImageView.layer.cornerRadius = 12
        avatarImageView.layer.masksToBounds = true
        
        return avatarImageView
    }()
    lazy var nameLabel:UILabel = {
        let nameLabel = UILabel()
        nameLabel.font = UIFont.systemFont(ofSize: 18)
        return nameLabel
    }()
    lazy var likeImageView:UIImageView = {
        let likeImageView = UIImageView()
        likeImageView.backgroundColor = UIColor.red
        return likeImageView
    }()
    lazy var likeLabel:UILabel = {
        let likeLabel = UILabel()
        likeLabel.font = UIFont.systemFont(ofSize: 12)
        return likeLabel
    }()
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        
        self.backgroundColor = UIColor.yellow
        
        self.addSubview(imageView)
        self.addSubview(introductionLabel)
        self.addSubview(avatarImageView)
        self.addSubview(nameLabel)
        self.addSubview(likeLabel)
        self.addSubview(likeImageView)
        
        imageView.snp.makeConstraints { (make) in
            make.top.left.right.width.equalTo(self)
            make.height.equalTo(imageView.snp.width)
        }
        introductionLabel.snp.makeConstraints { (make) in
            make.left.equalTo(10)
            make.width.equalTo((ScreenWidth - 30)/2 - 20)
            make.top.equalTo(imageView.snp.bottom).offset(8)
        }
        avatarImageView.snp.makeConstraints { (make) in
            make.width.height.equalTo(24)
            make.left.equalTo(introductionLabel)
            make.top.equalTo(introductionLabel.snp.bottom)
        }
        nameLabel.snp.makeConstraints { (make) in
            make.centerY.equalTo(avatarImageView)
            make.left.equalTo(avatarImageView.snp.right).offset(6)
        }
        likeLabel.snp.makeConstraints { (make) in
            make.right.equalTo(self).offset(-10)
            make.centerY.equalTo(avatarImageView)
        }
        likeImageView.snp.makeConstraints { (make) in
            make.width.equalTo(14)
            make.height.equalTo(12)
            make.centerY.equalTo(avatarImageView)
            make.right.equalTo(likeLabel.snp.left).offset(-6)
        }
        
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}

