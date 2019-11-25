
//
//  HeaderMyProfileCell.swift
//  merchant-ios
//
//  Created by Trung Vu on 2/29/16.
//  Copyright © 2016 WWE & CO. All rights reserved.
//

import UIKit

import Kingfisher
import PromiseKit
import ObjectMapper


protocol HeaderMyProfileDelegate: NSObjectProtocol {
    func onTapWishlistButton(_ sender: UIButton)
    func onTapAvatarView(_ sender: UITapGestureRecognizer)
    func onTapEditCoverView(_ sender: UITapGestureRecognizer)
    func onTapFriendList(_ sender: UIButton)
    func onHandleAddFriend(_ friendStatus: StatusFriend)
    func onHandleAddFollow(_ followStatus: Bool)
    func onTapMyFollowersListView(_ sender: UIButton)
    func onTapMerchantListView(_ sender: UIButton)
    func onTapCuratorsListView(_ sender: UIButton)
    func didSelectDescriptionView(_ sender: UITapGestureRecognizer)
    func didSelectOption(_ sender: UIButton)
    func didSelectCustomerList(_ sender: UIButton)
    func reloadData()
}

enum ButtonType: Int {
	case FriendOrWishlist = 10,
	FollowingMerchants,
	FollowingCurators,
	FollowingUsers,
	MyFollowers
}

enum UserType: Int {
    case UserNormal = 0,
    CuratorType
}
class HeaderMyProfileCell: UICollectionReusableView, UITextFieldDelegate {
    
    enum ImageType: Int {
        case Cover = 20,
        Avatar
    }
    
    private final let HeightForCell: CGFloat = 134.0
    private final let HeightNavigation: CGFloat = 44.0
    private final let ImageAvatarWidth : CGFloat = 80.0
    private final let ImageIconWidth: CGFloat = 20.0
    final let HeighLabelUserName: CGFloat = 25.0
    private final let HeightAvatar: CGFloat = 92.0
    
    private final let HeightActionView: CGFloat = 120
    private final let HeightBottomView: CGFloat = 48.0
    private final let marginTop:CGFloat = 10.0
    private final let ImageCameraWidth:CGFloat = 15
    private final let marginLeftCamera:CGFloat = 15
    private final let ImageCameraHeight: CGFloat = 12
    private final let MarginActionButton:CGFloat = 20.0
    private final let WidthFollowerButton:CGFloat = 73.0
    private final let HeightImageCameraBottom: CGFloat = 26.0
    private final let grayColor = UIColor.secondary4()
    private final let NotiHasAvatar = NSNotification.Name("NotiHasAvatar")
    private final let WidthItemButton:CGFloat = 20
    private final let HeightItemButton:CGFloat = 20
    private final let space:CGFloat = 8.0
    
    final let QRCodeWidth = CGFloat(15)
    
    
    var coverImageView          = UIImageView()
    var overlayBottom           = UIImageView()
    var overlay                 = UIImageView()
    var avatarViewContain       = UIView()
    var avatarView              = UIView()
    var imageViewAvatar         = UIImageView()
    var imageViewCameraAvatar   = UIImageView()
    var backgroundViewCamara    = UIImageView()
    var imageViewIcon           = UIImageView()
    var labelUsername           = UILabel()
    var labelRealName           = UILabel()
    var cardLevelLabel          = UILabel()
    var cardTypeImageView       = UIImageView()
    let tfAlias                 = UITextField()
    var toolbar                 = UIToolbar()
    var doneButton: UIBarButtonItem!
    
    var actionView              = UIView()
    var tranparentView          = VisualEffectView()
    var buttonWhistlist         = UIButton()
    var buttonFollowBrand       = UIButton()
    var buttonFollowUser        = UIButton()
    var buttonMyFollowers       = UIButton()
    
    var isCuratorUser:Bool = false
    var isPrivateProfile: Bool = false
    weak var delegateMyProfile: HeaderMyProfileDelegate?
    var currentUser: User?
    var isTapProfile: Bool = false
    var wishlistCount: Int = 0
    var statusFriend: StatusFriend?
    var relationship: Relationship?
    
    var statusFollow: Bool = false
    var currentProfileType: TypeProfile = TypeProfile.Private
    var userType: UserType?
    var isFriend: Bool?
    var isFollowing:Bool?
    var relationShip = Relationship()
	
	private var showQRCodeButton : UIButton?

    var dismissKeyboardHandler: (() -> Void)?
	
    override init(frame: CGRect) {
        super.init(frame: frame)
        self.isUserInteractionEnabled = true
        self.backgroundColor = UIColor.white

        coverImageView.image = UIImage(named: "default_cover")
        coverImageView.tag = ImageType.Cover.rawValue
		//coverImageView.contentMode = .scaleAspectFill
		//coverImageView.clipsToBounds = false
//        coverImageView.setupImageViewer(with: self, initialIndex: 0, parentTag:ImageType.Cover.rawValue, onOpen: { () -> Void in }, onClose: { () -> Void in })
        let tapEdit = UITapGestureRecognizer(target: self, action: #selector(HeaderMyProfileCell.onTapEdit))
        coverImageView.addGestureRecognizer(tapEdit)
        coverImageView.isUserInteractionEnabled = true
        self.addSubview(coverImageView)
        
        overlay.image = UIImage(named: "overlay")
        coverImageView.addSubview(overlay)
        
        overlayBottom.image = UIImage(named: "overlay_bottom")
        coverImageView.addSubview(overlayBottom)
        
        //create avatar View
        imageViewAvatar.image = UIImage(named: "default_profile_icon")
        imageViewAvatar.tag = ImageType.Avatar.rawValue
//        imageViewAvatar.setupImageViewer(with: self, initialIndex: 0, parentTag:ImageType.Avatar.rawValue, onOpen: { () -> Void in }, onClose: { () -> Void in })
        backgroundViewCamara.image = UIImage()
        backgroundViewCamara.backgroundColor = UIColor.clear
        imageViewAvatar.addSubview(backgroundViewCamara)
        imageViewAvatar.backgroundColor = UIColor.clear
        let tapAvatar = UITapGestureRecognizer(target: self, action: #selector(HeaderMyProfileCell.onTapAvatar))
        backgroundViewCamara.isUserInteractionEnabled = true
        backgroundViewCamara.addGestureRecognizer(tapAvatar)
		backgroundViewCamara.becomeFirstResponder()
		
        avatarView.addSubview(imageViewAvatar)
        imageViewIcon.image = UIImage()
        avatarView.addSubview(imageViewIcon)
        avatarView.backgroundColor = UIColor.clear
        avatarViewContain.addSubview(avatarView)
        
        //create label user name
        labelUsername.text = " "
        labelUsername.formatSize(20)
        labelUsername.adjustsFontSizeToFitWidth = true
        labelUsername.minimumScaleFactor = 0.75
        labelUsername.textColor = UIColor.white
        labelUsername.textAlignment = NSTextAlignment.center
        labelUsername.backgroundColor = UIColor.clear
		labelUsername.lineBreakMode = .byTruncatingTail
        labelUsername.numberOfLines = 1
        if LoginManager.getLoginState() == .validUser {
            let tapUsername = UITapGestureRecognizer(target: self, action: #selector(HeaderMyProfileCell.labelUserNameTapped))
            labelUsername.addGestureRecognizer(tapUsername)
        }
        labelUsername.isUserInteractionEnabled = true
        actionView.addSubview(labelUsername)
        
        //
        labelRealName.text = " "
        labelRealName.formatSize(14)
        labelRealName.lineBreakMode = .byTruncatingTail
        labelRealName.numberOfLines = 1
        labelRealName.textColor = UIColor.secondary1()
        labelRealName.isHidden = true
        actionView.addSubview(labelRealName)
        
        avatarViewContain.backgroundColor = UIColor.clear
        actionView.addSubview(avatarViewContain)
        
        tfAlias.backgroundColor = UIColor.whiteColorWithAlpha()
        tfAlias.clearButtonMode = .whileEditing
        tfAlias.font = UIFont.systemFont(ofSize: 20)
        tfAlias.enablesReturnKeyAutomatically = true
        let paddingView = UIView(frame: CGRect(x:0, y: 0, width: 5, height: 1))
        tfAlias.leftView = paddingView
        tfAlias.leftViewMode = UITextFieldViewMode.always
        tfAlias.layer.cornerRadius = 2
        tfAlias.layer.borderColor = UIColor.secondary1().cgColor
        tfAlias.layer.borderWidth = Constants.TextField.BorderWidth
        tfAlias.delegate = self
        tfAlias.isHidden = true
        tfAlias.addTarget(self, action: #selector(textDidChange), for: .editingChanged)
        actionView.addSubview(tfAlias)
        
        //Vip Card
        cardLevelLabel.formatSize(13)
        cardLevelLabel.textColor = UIColor.white
        cardLevelLabel.textAlignment = .left
        cardLevelLabel.isHidden = true
        actionView.addSubview(cardLevelLabel)
        
        cardTypeImageView = UIImageView()
        cardTypeImageView.image = UIImage(named: "icon_vip_dark_grey")
        cardTypeImageView.isHidden = true
        actionView.addSubview(cardTypeImageView)
        
        toolbar.frame = CGRect(x:0, y: 0, width: frame.size.width, height: 50)
        toolbar.barStyle = UIBarStyle.default

        let cancelButton = UIBarButtonItem(title: String.localize("LB_CANCEL"), style: UIBarButtonItemStyle.plain, target: self, action: #selector(cancelTapped))
            cancelButton.tintColor = UIColor.black

        doneButton = UIBarButtonItem(title: String.localize("LB_DONE"), style: UIBarButtonItemStyle.plain, target: self, action: #selector(doneTapped))
        doneButton.tintColor = UIColor.red

        toolbar.items = [
                cancelButton,
                UIBarButtonItem(barButtonSystemItem: UIBarButtonSystemItem.flexibleSpace, target: nil, action: nil),
                doneButton]
        toolbar.sizeToFit()
        tfAlias.inputAccessoryView = toolbar
        
        //create action View
        buttonWhistlist = self.createButton(ButtonType.FriendOrWishlist.rawValue, textName: String.localize(""),number: "")
        buttonFollowBrand = self.createButton(ButtonType.FollowingMerchants.rawValue, textName: String.localize("LB_CA_FOLLOWING_BRAND"),number: "")
        buttonFollowUser = self.createButton(ButtonType.FollowingUsers.rawValue, textName: String.localize("LB_CA_FOLLOWING_USER"),number: "")
        //create My Followers button
        buttonMyFollowers = self.createButton(ButtonType.MyFollowers.rawValue, textName: String.localize("LB_CA_FOLLOWER"),number: "")
        if let view = buttonFollowUser.viewWithTag(9) {
            view.backgroundColor = UIColor.clear
        }

        tranparentView.frame = actionView.bounds
        tranparentView.alpha = 0.8
        tranparentView.backgroundColor = UIColor.clear
        tranparentView.tint(UIColor.secondary2(), blurRadius: 6)
        
        actionView.addSubview(tranparentView)
        actionView.addSubview(buttonWhistlist)
        actionView.addSubview(buttonFollowBrand)
        actionView.addSubview(buttonFollowUser)
        actionView.addSubview(buttonMyFollowers)
        
        buttonFollowBrand.isHidden = true
       
        self.addSubview(actionView)

        let objects = [imageViewAvatar, coverImageView]
        
        if currentProfileType == .Private {
            NotificationCenter.default.post(name: NotiHasAvatar, object: objects)
        }
		
        setNeedsLayout()
        
        actionView.backgroundColor = UIColor.clear
		
		// set images
		imageViewAvatar.image = UIImage(named: "default_profile_icon")
		coverImageView.image = UIImage(named: "default_cover")
        
        commit()
    }
    
    func setCoverImageSize(_ pointY: CGFloat) {
        coverImageView.frame = CGRect(x:0, y: 0 + pointY, width: self.frame.width, height: self.frame.height - pointY)
        overlay.frame = CGRect(x:0, y: 0 + pointY, width: self.frame.size.width, height: CGFloat(100))
        setNeedsDisplay()
        layoutIfNeeded()
    }
    
    func commit(){
        let height = CGFloat(100)
        coverImageView.frame = CGRect(x:0, y: 0, width: self.frame.width, height: self.frame.height)
        overlay.frame = CGRect(x:0, y: 0, width: self.frame.size.width, height: height)
    }
    
    override func layoutSubviews() {
        super.layoutSubviews()
        
        var rect = overlayBottom.frame
        rect.originX = 0
        rect.size.width = self.frame.width
        rect.size.height = height
        rect.originY = coverImageView.frame.height - rect.size.height
        overlayBottom.frame = rect
        
        //setup action View
        var viewHeight = HeightActionView
        if currentProfileType == .Public {
            viewHeight = 120
        }
        actionView.frame = CGRect(x:0, y: self.frame.height - viewHeight, width: self.frame.width, height: viewHeight)
        tranparentView.frame = actionView.bounds
        let widthButton = (self.frame.width - MarginActionButton - ImageAvatarWidth) / 3
        let heightButton = CGFloat(44)
        let originY = actionView.bounds.sizeHeight - heightButton - 10
        buttonWhistlist.frame = CGRect(x:MarginActionButton + ImageAvatarWidth, y: originY, width: widthButton, height: heightButton)
        buttonFollowBrand.frame = CGRect(x:buttonWhistlist.frame.maxX, y: originY, width: widthButton, height: heightButton)
//        buttonFollowUser.frame = CGRect(x:buttonFollowBrand.frame.maxX, y: originY, width: widthButton, height: heightButton)
        buttonFollowUser.frame = CGRect(x:buttonWhistlist.frame.maxX, y: originY, width: widthButton, height: heightButton)
        buttonMyFollowers.frame = CGRect(x: buttonFollowUser.frame.maxX, y: originY, width: widthButton, height: heightButton)
        
        actionView.sendSubview(toBack: tranparentView)
        
        // setup avatar
        avatarViewContain.frame = CGRect(x:MarginActionButton, y: -5, width: ImageAvatarWidth, height: ImageAvatarWidth)
        
        avatarView.frame = CGRect(x:(avatarViewContain.frame.width - ImageAvatarWidth-10)/2, y: 0, width: ImageAvatarWidth, height: ImageAvatarWidth)
        backgroundViewCamara.frame = CGRect(x:0, y: 0, width: ImageAvatarWidth - 2, height: ImageAvatarWidth - 2)
        imageViewAvatar.frame = CGRect(x:2, y: 0, width: ImageAvatarWidth - 2, height: ImageAvatarWidth - 2)
        imageViewAvatar.layer.cornerRadius = ImageAvatarWidth / 2
        imageViewAvatar.layer.borderColor = UIColor.clear.cgColor
        imageViewAvatar.layer.borderWidth = 0.0
        imageViewAvatar.layer.masksToBounds = true
        imageViewIcon.frame = CGRect(x:ImageAvatarWidth - ImageIconWidth , y: ImageAvatarWidth - ImageIconWidth, width: ImageIconWidth, height: ImageIconWidth)
        
        setFrameLabelUserName()
        
        labelRealName.frame = CGRect(x:labelUsername.frame.minX, y: labelUsername.frame.maxY + 5, width: self.frame.width - labelUsername.frame.minX, height: HeighLabelUserName)
        let originX = avatarViewContain.frame.maxX + Margin.left
        let width = actionView.width - Margin.right - originX - Margin.left * 2
        tfAlias.frame = CGRect(x:originX, y: labelUsername.frame.minY, width: width, height: HeighLabelUserName)
        
        //Card level info
        let cardTypeImageSize = CGSize(width: 15 * 7/5, height: 15)
        cardTypeImageView.frame = CGRect(x:labelUsername.frame.minX, y: labelUsername.frame.maxY + 5, width: cardTypeImageSize.width, height: cardTypeImageSize.height)
        cardLevelLabel.frame = CGRect(x:cardTypeImageView.frame.maxX + 6, y: cardTypeImageView.frame.midY - HeighLabelUserName/2 + 1, width: actionView.width - cardTypeImageView.frame.maxX - 12, height: HeighLabelUserName)
        cardTypeImageView.isHidden = !(currentProfileType == .Private)
        cardLevelLabel.isHidden = !(currentProfileType == .Private)
        
        // show QRCode button for user private profile
        self.setupQRCodeButton((currentProfileType == .Private))
    }
		
	func setupQRCodeButton(_ show: Bool) {
		
        if let showQRCodeButton = self.showQRCodeButton {
            showQRCodeButton.removeFromSuperview()
        }
		
        var imageName = ""
		if show {
            imageName = "qr_code"
        }
        else {
            imageName = "ic_mode_edit"
        }
        
        let width = CGFloat(15)
        showQRCodeButton = UIButton(type: .custom)
        showQRCodeButton!.frame = CGRect(x:labelUsername.frame.maxX + Margin.left , y: labelUsername.frame.origin.y + (HeighLabelUserName - width) / 2, width: width, height: width)
        showQRCodeButton!.setImage(UIImage(named: imageName), for: .normal)
        showQRCodeButton!.addTarget(self, action: #selector(HeaderMyProfileCell.labelUserNameTapped), for: .touchUpInside)
        showQRCodeButton!.isHidden = labelUsername.isHidden
        
        actionView.addSubview(showQRCodeButton!)
        
        if LoginManager.getLoginState() != .validUser  {
            showQRCodeButton!.isHidden =  true
        }
	}

	@objc func labelUserNameTapped() {
        if isPrivateProfile == true {
            NotificationCenter.default.post(name: Constants.Notification.showQRCodeOnProfileView, object: nil)
        }
        else {
            tfAlias.isHidden = false
            tfAlias.text = labelUsername.text
            if let showQRCodeButton = self.showQRCodeButton {
                showQRCodeButton.isHidden = true
            }
            labelUsername.isHidden = true
            tfAlias.becomeFirstResponder()
            NotificationCenter.default.post(name: Constants.Notification.aliasBeginEditting, object: nil)
        }
	}
	
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    func setFrameLabelUserName() {
        var width = StringHelper.getTextWidth(labelUsername.text!, height: HeighLabelUserName, font: labelUsername.font)
        
        let originX = avatarViewContain.frame.maxX + Margin.left
        let maxWidth = self.bounds.sizeWidth - originX - QRCodeWidth - Margin.left * 2
        if width > maxWidth {
            width = maxWidth
        }
        
        var originY = Margin.top
        if labelRealName.isHidden {
            originY = (buttonWhistlist.frame.minY - 2*HeighLabelUserName - 5) / 2.0 + 5
        }
        labelUsername.frame = CGRect(x:avatarViewContain.frame.maxX + Margin.left, y: originY, width: width, height: HeighLabelUserName)
    }
    
    func getTextHeight(_ text: String, width: CGFloat, font: UIFont) -> CGFloat {
        let constraintRect = CGSize(width: width, height: CGFloat.greatestFiniteMagnitude)
        let boundingBox = text.boundingRect(with: constraintRect, options: NSStringDrawingOptions.usesLineFragmentOrigin, attributes: [NSAttributedStringKey.font: font], context: nil)
        return boundingBox.height
    }
    
    func originY() -> CGFloat
    {
        var originY:CGFloat = 0;
        let application: UIApplication = UIApplication.shared
        if (application.isStatusBarHidden)
        {
            originY = application.statusBarFrame.size.height
        }
        return originY;
    }
    
    func createButton(_ index: Int, textName: String, number: String) -> UIButton {
        
        let width = (self.frame.width - MarginActionButton - ImageAvatarWidth) / 3
        let frm = CGRect(x:0, y: 0, width: width, height: 44)
        let buttonParent = UIButton(frame: frm)
        buttonParent.tag = index
        buttonParent.backgroundColor = UIColor.clear
        
        let labelNumber = UILabel(frame: CGRect(x:0, y: 8, width: width, height: 22))
        labelNumber.textAlignment = NSTextAlignment.center
        labelNumber.text = number
        labelNumber.tag = 2
        labelNumber.formatSize(15)
        labelNumber.textColor = UIColor.white
        labelNumber.frame = CGRect(x:0, y: 8, width: width, height: (StringHelper.heightForText(String.localize("LB_CA_FOLLOWED"), width: width, font: labelNumber.font)))
        buttonParent.addSubview(labelNumber)
        
        let labelName = UILabel(frame: CGRect(x: 0, y: labelNumber.frame.origin.y + (StringHelper.heightForText(String.localize("LB_CA_FOLLOWED"), width: width, font: labelNumber.font)), width: width, height: 22))
        labelName.textAlignment = NSTextAlignment.center
        labelName.text = textName
        labelName.formatSize(11)
        labelName.tag = 3
        labelName.textColor = UIColor.white
        buttonParent.addSubview(labelName)
        
        buttonParent.addTarget(self, action: #selector(HeaderMyProfileCell.onActionHeader), for: UIControlEvents.touchUpInside)
        return buttonParent
    }
    func getButtonOnActionView(_ tag: Int) -> UIButton {
        let button = actionView.viewWithTag(tag) as? UIButton
        return button!
    }
    
    //MARK: - Handle Action
    
    @objc func onActionHeader(_ sender: UIButton)
    {
		guard self.delegateMyProfile != nil else { return }
		
        switch (sender.tag){
        case ButtonType.FriendOrWishlist.rawValue:
            if isPrivateProfile == false {
//                if (wishlistCount > 0){
                     self.delegateMyProfile?.onTapWishlistButton(sender)
//                }
            } else {
//                if currentUser?.friendCount > 0 {
                    self.delegateMyProfile?.onTapFriendList(sender)
//                }
            }
            break
        case ButtonType.FollowingMerchants.rawValue:
//            if currentUser?.followingMerchantCount > 0 {
                self.delegateMyProfile?.onTapMerchantListView(sender)
//            }
            break
        case ButtonType.FollowingCurators.rawValue:
//            if currentUser?.followingCuratorCount > 0 {
                self.delegateMyProfile?.onTapCuratorsListView(sender)
//            }
            break
        case ButtonType.FollowingUsers.rawValue:
//            if currentUser?.followingUserCount > 0 {
                self.delegateMyProfile?.didSelectCustomerList(sender)
//            }
            break
		case ButtonType.MyFollowers.rawValue:
//            if currentUser?.followerCount > 0 {
                self.delegateMyProfile?.onTapMyFollowersListView(sender)
//            }
			break
		default:
            break
        }
    }
    
    @objc func onTapEdit(_ sender: UITapGestureRecognizer) {
		if let delegate = self.delegateMyProfile {
			self.isTapProfile = false
			delegate.onTapEditCoverView(sender)
		}
    }
    @objc func onTapAvatar(_ sender: UITapGestureRecognizer) {
        
        imageViewAvatar.analyticsViewKey = self.analyticsViewKey
        imageViewAvatar.recordAction(.Tap, sourceRef: "MyHead", sourceType: .Button, targetRef: "PhotoSelect", targetType: .View)
		if let delegate = self.delegateMyProfile {
			self.isTapProfile = true
			delegate.onTapAvatarView(sender)
		}
    }
    @objc func onHandleAddFriend(_ sender: UIButton) {

		guard LoginManager.getLoginState() == .validUser  else {
			NotificationCenter.default.post(name: Constants.Notification.notifyUserLogin, object: SignupMode.publicProfile.rawValue)
			return
		}

		if let delegate = self.delegateMyProfile {
			delegate.onHandleAddFriend(statusFriend ?? StatusFriend.unfriend)
		}
    }
    @objc func onHandleFollow(_ sender: UIButton){
		
		guard LoginManager.getLoginState() == .validUser else {
			NotificationCenter.default.post(name: Constants.Notification.notifyUserLogin, object: SignupMode.publicProfile.rawValue)
			return
		}
        
		if let delegate = self.delegateMyProfile {
			delegate.onHandleAddFollow(statusFollow)
		}
    }
	
    @objc func didSelectOption(_ sender: UIButton){
		
		if let delegate = self.delegateMyProfile {
			delegate.didSelectOption(sender)
		}
    }
	
    //MARK - setup Data
    func setCoverImage(_ key : String){
        coverImageView.mm_setImageWithURL(HeaderMyProfileCell.getCoverImageUrl(key, imageCategory: .user, width: self.width), placeholderImage: UIImage(named: "default_cover"))
    }
	
    func setAvatarImage(_ key : String){
        imageViewAvatar.mm_setImageWithURL(ImageURLFactory.URLSize256(key, category: .user), placeholderImage : UIImage(named: "default_profile_icon"))
		imageViewAvatar.contentMode = .scaleAspectFill
    }

	func setupProfileAvatarImage() {
		if let user = self.currentUser {
            if let pendingUploadProfileImage = user.pendingUploadProfileImage {
                imageViewAvatar.image = pendingUploadProfileImage
            } else if  (user.profileImage != "") {
				setAvatarImage(user.profileImage)
			} else {
				imageViewAvatar.image = UIImage(named: "default_profile_icon")
            }
            setupUserTapDefaultAvatarImage(true)
		}

	}
	
	func setupProfileCoverImage() {
		
		if let user = self.currentUser {
            if let pendingUploadCoverImage = user.pendingUploadCoverImage {
                coverImageView.image = pendingUploadCoverImage
            } else if (user.coverImage != "") {
				setCoverImage(user.coverImage)
			} else {
				coverImageView.image = UIImage(named: "default_cover")
			}
		}

	}
	
    func setupDataWithUser(_ user: User) {
        self.currentUser = user
		user.isFollowUser = FollowService.isFollowing(user.userKey)
		self.setupProfileAvatarImage()

		self.setupProfileCoverImage()
		
        labelRealName.text = String(format: "%@ : %@", String.localize("LB_CA_USERNAME"), user._displayName)
        labelUsername.text = String(format: "%@", user.displayName)
        
        if let alias = CacheManager.sharedManager.aliasForKey(user.userKey)?.alias, alias != user._displayName && currentProfileType == .Public {
            labelRealName.isHidden = false
        }
        else {
            labelRealName.isHidden = true
        }
        
        if user.isCurator == 1 {
            imageViewIcon.image = UIImage(named: "curator_diamond")
        } else {
            imageViewIcon.image = UIImage()
        }
        setupDataForFollowerBrand(user.followingMerchantCount)
        setupDataForFollowerUser(user.followingUserCount + user.followingCuratorCount)
        if isPrivateProfile {
            setupDataForWishlistAndFrienlist(user.friendCount)
            backgroundViewCamara.isHidden = false
        } else {
            //wish list count
            setupDataForWishlistAndFrienlist(wishlistCount)
            backgroundViewCamara.isHidden = true
            self.isTapProfile = true
        }
        setupDataForNumberFollowing(user.followerCount)
        
        //Loyalty
        if let loyalty = user.loyalty{
            cardLevelLabel.text = loyalty.memberLoyaltyStatusName
        }
        
        setNeedsLayout()
    }
    
    func updateViewWithLoyalty(_ loyalty: Loyalty){
        cardLevelLabel.text = loyalty.memberLoyaltyStatusName
    }

    func setupDataForWishlistAndFrienlist(_ number: Int) {
        let btnWishlist = getButtonOnActionView(ButtonType.FriendOrWishlist.rawValue)
        (btnWishlist.viewWithTag(2) as? UILabel)?.text = String(format: "%d", number)
        if isPrivateProfile {
            (btnWishlist.viewWithTag(3) as? UILabel)?.text = String(format: "%@", String.localize("LB_CA_FRIEND_LIST"))
        } else {
            (btnWishlist.viewWithTag(3) as? UILabel)?.text = String(format: "%@", String.localize("LB_CA_WISHLIST_PROD"))
        }
    }
    
    func setupDataForFollowerBrand(_ numberFollowerBrand: Int) {
        let btnFolowBrand = getButtonOnActionView(ButtonType.FollowingMerchants.rawValue)
        (btnFolowBrand.viewWithTag(2) as? UILabel)?.text = String(format: "%d", numberFollowerBrand)
    }
    
    func setupDataForFollowerCurator(_ numberFollowerCurator: Int){
        let btnFolowCurator = getButtonOnActionView(ButtonType.FollowingCurators.rawValue)
        (btnFolowCurator.viewWithTag(2) as? UILabel)?.text = String(format: "%d", numberFollowerCurator)
    }
    
    func setupDataForFollowerUser(_ numberFollowerUser: Int) {
        let btnFolowUser = getButtonOnActionView(ButtonType.FollowingUsers.rawValue)
        (btnFolowUser.viewWithTag(2) as? UILabel)?.text = String(format: "%d", numberFollowerUser)
    }
    
    func setupDataForNumberFollowing(_ numberFollowing: Int) {
        let followerBtn = getButtonOnActionView(ButtonType.MyFollowers.rawValue)
        (followerBtn.viewWithTag(2) as? UILabel)?.text = String(format: "%d", numberFollowing)
    }

    func didSelectDescriptionDetail(gesture: UITapGestureRecognizer){
        self.delegateMyProfile?.didSelectDescriptionView(gesture)
    }
    
    func setupUserTapDefaultAvatarImage(_ isStaus: Bool) {
        self.imageViewAvatar.isUserInteractionEnabled = isStaus
    }
    
    // MARK: - UITextField Delegate
    func textFieldShouldReturn(_ textField: UITextField) -> Bool {

        if let alias = textField.text?.trimmingCharacters(in: CharacterSet.whitespacesAndNewlines) , alias != "" {
                saveAlias(alias)
            }
        dismissKeyboard()
        return true
    }

    @objc func textDidChange(textField: UITextField) {
        if textField.text == "" {
            doneButton.isEnabled = false
        }
        else {
            doneButton.isEnabled = true
        }
    }

    func dismissKeyboard() {
        tfAlias.resignFirstResponder()
    
        if let showQRCodeButton = self.showQRCodeButton {
            showQRCodeButton.isHidden = false
        }
        labelUsername.isHidden = false
        tfAlias.isHidden = true
    
        removeDimBackground()
        setNeedsLayout()
    }
    
    func addDimBackgroundWithOffset(_ offset: CGFloat) {
        let rect = self.convert(tfAlias.frame, from: actionView)
        
        let viewTop = UIView(frame: CGRect(x:0, y: 0, width: self.width, height: rect.minY - offset))
        viewTop.backgroundColor = UIColor.black
        viewTop.alpha = 0.5
        viewTop.tag = 2000
        UIApplication.shared.windows.first?.addSubview(viewTop)
        
        let viewLeft = UIView(frame: CGRect(x:0, y: rect.minY, width: rect.minX, height: self.height - rect.minY))
        viewLeft.backgroundColor = UIColor.black
        viewLeft.alpha = 0.5
        viewLeft.tag = 2001
        self.addSubview(viewLeft)
        
        let viewBottom = UIView(frame: CGRect(x:rect.minX, y: rect.maxY, width: self.width - rect.minX, height: self.height - rect.maxY))
        viewBottom.backgroundColor = UIColor.black
        viewBottom.alpha = 0.5
        viewBottom.tag = 2002
        self.addSubview(viewBottom)
        
        let viewRight = UIView(frame: CGRect(x:rect.maxX, y: rect.minY, width: self.width - rect.maxY, height: rect.height))
        viewRight.backgroundColor = UIColor.black
        viewRight.alpha = 0.5
        viewRight.tag = 2003
        self.addSubview(viewRight)
        
        viewTop.addGestureRecognizer(UITapGestureRecognizer(target: self, action: #selector(cancelTapped)))
        viewLeft.addGestureRecognizer(UITapGestureRecognizer(target: self, action: #selector(cancelTapped)))
        viewBottom.addGestureRecognizer(UITapGestureRecognizer(target: self, action: #selector(cancelTapped)))
        viewRight.addGestureRecognizer(UITapGestureRecognizer(target: self, action: #selector(cancelTapped)))
    }

    func removeDimBackground() {
        if let view = UIApplication.shared.windows.first?.viewWithTag(2000) {
            view.removeFromSuperview()
        }
        
        if let view = self.viewWithTag(2001) {
            view.removeFromSuperview()
        }
        
        if let view = self.viewWithTag(2002) {
            view.removeFromSuperview()
        }
        
        if let view = self.viewWithTag(2003) {
            view.removeFromSuperview()
        }
    }

    @objc func doneTapped() {
        if let alias = tfAlias.text?.trimmingCharacters(in: CharacterSet.whitespacesAndNewlines) , alias != "" {
            saveAlias(alias)
        }
        dismissKeyboardHandler?()
    }
    
    @objc func cancelTapped() {
        dismissKeyboardHandler?()
    }

    func saveAlias(_ alias: String) {
        if let userKey = self.currentUser?.userKey {
            UserService.saveAlias(alias, forUserKey: userKey) { [weak self] (response) in
                if let strongSelf = self {
                    if response.result.isSuccess {
                        if response.response?.statusCode == 200 {
                            CacheManager.sharedManager.updateAlias(alias, forKey: userKey)
                            strongSelf.labelUsername.text = alias
                            strongSelf.labelRealName.isHidden = false
                            strongSelf.setNeedsLayout()
                            strongSelf.delegateMyProfile?.reloadData()
                            NotificationCenter.default.post(name: Constants.Notification.changeAliasOnProfileView, object: nil)
                        }
                    }
                }
            }
        }
    }
    
    static func getCoverImageUrl(_ key : String, imageCategory : ImageCategory, width: CGFloat) -> URL {
        let width = Int(width * UIScreen.main.scale)
        var url: URL!
        if width <= ResizerSize.size512.rawValue {
            url = ImageURLFactory.URLSize512(key, category:imageCategory)
        } else if width <= ResizerSize.size750.rawValue {
            url = ImageURLFactory.URLSize750(key, category:imageCategory)
        } else {
            url = ImageURLFactory.URLSize1000(key, category:imageCategory)
        }
        return url
    }
}
