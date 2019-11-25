//
//  FilterCuratorCell.swift
//  merchant-ios
//
//  Created by khanh.nguyen on 6/9/16.
//  Copyright © 2016 WWE & CO. All rights reserved.
//

import UIKit
import PromiseKit
import ObjectMapper
import Alamofire


class FilterCuratorCell: UICollectionViewCell {
    
    var curator : Curator? {
        didSet {
            if let data = curator {
                var url = ""
                if let coverImageUrl = data.coverAlternateImage {
                    url = coverImageUrl
                }else {
                    url = data.profileImage
                }
				
				// check square cell to show profileAlternateImage
				if self.frame.size.width == self.frame.size.height {
					if let coverImageUrl = data.profileAlternateImage {
						url = coverImageUrl
					}else {
						url = data.profileImage
					}
				}
				
                coverImageView.mm_setImageWithURL(ImageURLFactory.URLSize1000(url, category: .user), placeholderImage : UIImage(named: "curator_cover_image_placeholder"))
                
                
				url = data.profileImage
				
                avatarImageView.mm_setImageWithURL(ImageURLFactory.URLSize256(url, category: .user), placeholderImage : UIImage(named: Constants.ImageName.ProfileImagePlaceholder))
                
                nameLabel.text = data.displayName
                followersLabel.text = String(format: "%@ %@",String.localize("LB_CA_CURATORS_FOLLOWER_NO"), NumberHelper.getNumberMeasurementString(data.followerCount))
                data.isFollowing = self.isFollowed(data)
                self.followButton.updateFollowButtonState(data.isFollowing)
                self.followButton.isHidden = data.userKey == Context.getUserKey()
                if data.isLoading {
                    self.followButton.showLoading(UIColor.clear)
                }else {
                    self.followButton.hideLoading()
                }
            }
        }
    }
    
    private var followersLabel = UILabel()
    private var nameLabel = UILabel()
    private let coverImageView = UIImageView()
    private var avatarImageView = UIImageView()
    private var overlayImageView = UIImageView()
    
    private var marginLeft = CGFloat(10)
    private var marginBottom = CGFloat(10)
    private var avatarImageWidth = CGFloat(36)
    var followButton = ButtonFollow()
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        
//        followButton.addTarget(self, action: #selector(FilterCuratorCell.didSelectFollowButton(_:)), for: UIControlEvents.touchUpInside)
        followButton.isUserInteractionEnabled = false
        
        coverImageView.frame = contentView.bounds
        coverImageView.contentMode = .scaleAspectFill
        
        contentView.addSubview(coverImageView)
        
        avatarImageView.frame = CGRect(x: marginLeft, y: contentView.frame.maxY - marginBottom - width, width: avatarImageWidth, height: avatarImageWidth)
        avatarImageView.clipsToBounds = true
        avatarImageView.layer.cornerRadius = avatarImageView.frame.size.width / 2
        avatarImageView.contentMode = .scaleAspectFill
        
        
        followersLabel.formatSmall()
        followersLabel.textColor = UIColor.white
        
        nameLabel.font = UIFont.usernameFont()
        nameLabel.textColor = UIColor.white
        nameLabel.lineBreakMode = .byTruncatingTail
        overlayImageView.image = UIImage(named: "curator_overlay")
        contentView.addSubview(overlayImageView)
        
        contentView.addSubview(avatarImageView)
        contentView.addSubview(nameLabel)
        contentView.addSubview(followersLabel)
        contentView.addSubview(followButton)
        
        

    }
    
    override func layoutSubviews() {
        super.layoutSubviews()
        
        avatarImageView.frame = CGRect(x: marginLeft, y: contentView.frame.maxY - marginBottom - avatarImageWidth, width: avatarImageWidth, height: avatarImageWidth)
        coverImageView.frame = contentView.bounds
        
        let space = CGFloat(5)
        nameLabel.frame = CGRect(x: avatarImageView.frame.maxX + space, y: avatarImageView.frame.center.y - 17, width: contentView.frame.size.width - (avatarImageView.frame.maxX + marginLeft * 2), height: 15)
        followersLabel.frame = CGRect(x: avatarImageView.frame.maxX + space, y: nameLabel.frame.maxY + 2, width: contentView.frame.size.width - avatarImageView.frame.maxX + marginLeft - marginLeft, height: 15)
        
        let imageOverlayHeight = CGFloat(120)
        overlayImageView.frame = CGRect(x: 0, y: self.frame.sizeHeight - imageOverlayHeight, width: self.frame.sizeWidth, height: imageOverlayHeight)
        
        let paddingLeft = CGFloat(10)
        let paddingBottom = CGFloat(15)
        followButton.frame = CGRect(x: (self.bounds.sizeWidth - ButtonFollow.ButtonFollowSize.width - paddingLeft), y: self.bounds.maxY - paddingBottom - ButtonFollow.ButtonFollowSize.height, width: ButtonFollow.ButtonFollowSize.width, height: ButtonFollow.ButtonFollowSize.height)
        followButton.addTarget(self, action: #selector(FilterCuratorCell.didSelectFollowButton), for: .touchUpInside)
        followButton.isUserInteractionEnabled = true
        
    }
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
	
	func getCoverImageSize() -> CGSize {
		return coverImageView.size
	}
    
    func isFollowed(_ curator: Curator) ->Bool{
        return FollowService.instance.cachedFollowingUserKeys.contains(curator.userKey )
    }
    
    @objc func didSelectFollowButton(_ sender: Any) {
        if let data = self.curator {
            self.didSelectFollowUser(data, isFollowing: data.isFollowing)
        }
    }
    
    func didSelectFollowUser(_ curator: Curator, isFollowing: Bool) {
        if LoginManager.getLoginState() != .validUser {
            LoginManager.goToLogin()
            return
        }
        if isFollowing {
            if let activeController = Utils.findActiveController() as? MmViewController {
                let message = String.localize("LB_CA_UNFOLLOW_CONF").replacingOccurrences(of: "{0}", with: curator.displayName)
                Alert.alert(activeController, title: "", message: message, okActionComplete: { () -> Void in
                    self.followButton.showLoading(UIColor.clear)
                    curator.isLoading = true
                    firstly {
                        return FollowService.requestUnfollow(curator.userKey)
                        }.then { _ -> Void in
                            curator.isFollowing = false
                            curator.followerCount = max(curator.followerCount - 1, 0)
                            self.followButton.updateFollowButtonState(curator.isFollowing)
                        }.always {
                            curator.isLoading = false
                            self.followButton.hideLoading()
                            self.followButton.updateFollowButtonState(curator.isFollowing)
                            self.followersLabel.text = String(format: "%@ %@", String.localize("LB_CA_CURATORS_FOLLOWER_NO"), NumberHelper.getNumberMeasurementString(curator.followerCount))
                        }.catch { error -> Void in
                            Log.error("error")
                            let error = error as NSError
                            if let apiResp = error.userInfo["data"] as? ApiResponse {
                                activeController.handleApiResponseError(apiResponse: apiResp, statusCode: error.code)
                            }
                            curator.isLoading = false
                            
                    }
                    }, cancelActionComplete:nil)
            }
        }else {
            if let activeController = Utils.findActiveController() as? MmViewController {
                self.followButton.showLoading(UIColor.clear)
                curator.isLoading = true
                firstly {
                    return FollowService.requestFollow(curator.userKey)
                    }.then { _ -> Void in
                        curator.isFollowing = true
                        curator.followerCount += 1
                        self.followButton.updateFollowButtonState(curator.isFollowing)
                    }.always {
                        curator.isLoading = false
                        self.followButton.hideLoading()
                        self.followButton.updateFollowButtonState(curator.isFollowing)
                        self.followersLabel.text = String(format: "%@ %@", String.localize("LB_CA_CURATORS_FOLLOWER_NO"), NumberHelper.getNumberMeasurementString(curator.followerCount))
                        
                    }.catch { error -> Void in
                        Log.error("error")
                        let error = error as NSError
                        if let apiResp = error.userInfo["data"] as? ApiResponse {
                             activeController.handleApiResponseError(apiResponse: apiResp, statusCode: error.code)
                        }
                }
            }
        }
    }

}
