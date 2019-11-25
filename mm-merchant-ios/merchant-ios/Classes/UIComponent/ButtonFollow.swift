//
//  ButtonFollow.swift
//  merchant-ios
//
//  Created by LongTa on 11/16/16.
//  Copyright © 2016 WWE & CO. All rights reserved.
//

import UIKit

class ButtonFollow: UIButton {
    static let ButtonFollowSize:CGSize = CGSize(width: 60.0, height: 25.0)
    static let ImageViewSize:CGSize = CGSize(width: 8.0, height: 8.0)
    
    private let iconImageView = UIImageView()
    private var spinView: UIActivityIndicatorView?
    private var loadingView: UIView?
    public var isCollectType = false

    override init(frame: CGRect) {
        super.init(frame: frame)
        self.titleLabel?.font = UIFont(name: Constants.Font.Normal, size: 12)
        self.layer.cornerRadius = Constants.Value.FollowButtonCornerRadius
        self.layer.borderWidth = Constants.Value.FollowButtonBorderWidth
        self.clipsToBounds = true
        self.backgroundColor = UIColor.clear
        self.setFollowButtonState(false)
        
        iconImageView.image = UIImage(named: "curator_follow_icon_small")
        iconImageView.isHidden = true
        self.addSubview(iconImageView)
    }
    
    override func draw(_ rect: CGRect) {
        super.draw(rect)
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    func setFollowButtonState(_ isFollowed: Bool){
        if isFollowed && (LoginManager.getLoginState() == .validUser) {
            self.setBackgroundImage(UIImage(named: "button_following"), for: UIControlState())
            self.titleEdgeInsets = UIEdgeInsets.zero
            self.layer.borderColor = UIColor.secondary3().cgColor
            if isCollectType {
                self.setTitle(String.localize("LB_CA_PROFILE_COLLECTION_COLLECTED"), for: UIControlState())
            } else {
                self.setTitle(String.localize("LB_CA_FOLLOWED"), for: UIControlState())
            }

            self.setTitleColor(UIColor.secondary3(), for: UIControlState())
        }
        else{
            self.setBackgroundImage(UIImage(named: "button_follow"), for: UIControlState())
            let spacing:CGFloat = 10.0 // the amount of spacing to appear between image and title
            self.titleEdgeInsets = UIEdgeInsets(top: 0, left: spacing, bottom: 0, right: 0);
            self.layer.borderColor = UIColor.primary3().cgColor
            if isCollectType {
                self.setTitle(String.localize("LB_CA_PROFILE_COLLECTION"), for: UIControlState())
            } else {
                self.setTitle(String.localize("LB_CA_FOLLOW"), for: UIControlState())
            }
            
            self.setTitleColor(UIColor.primary3(), for: UIControlState())
        }
    }
    
    func updateFollowButtonState(_ isFollowed: Bool){
        if isFollowed{
            self.titleEdgeInsets = UIEdgeInsets.zero
            self.layer.borderColor = UIColor.white.cgColor
            self.setTitle(String.localize("LB_CA_FOLLOWED"), for: UIControlState())
            self.setTitleColor(UIColor.white, for: UIControlState())
            self.backgroundColor = UIColor.clear
            self.setImage(nil, for: UIControlState())
            iconImageView.isHidden = true
        }
        else{
            let spacing:CGFloat = 10 // the amount of spacing to appear between image and title
            self.titleEdgeInsets = UIEdgeInsets(top: 0, left: spacing, bottom: 0, right: 0);
            self.layer.borderColor = UIColor.clear.cgColor
            self.setTitle(String.localize("LB_CA_FOLLOW"), for: UIControlState())
            self.setTitleColor(UIColor.white, for: UIControlState())
            self.backgroundColor = UIColor.primary1()
            iconImageView.isHidden = false
        }
        self.setBackgroundImage(nil, for: UIControlState())
    }
    
    override func layoutSubviews() {
        super.layoutSubviews()
        iconImageView.frame = CGRect(x: Margin.left / 2, y: (self.bounds.sizeHeight - ButtonFollow.ImageViewSize.height) / 2, width: ButtonFollow.ImageViewSize.width, height: ButtonFollow.ImageViewSize.height)
        
        //Layout for loading indicator
        if let loadingView = self.loadingView, let activityView = spinView {
            loadingView.frame = self.bounds
            activityView.frame = CGRect(x: (loadingView.frame.sizeWidth - activityView.frame.sizeWidth) / 2, y: (loadingView.frame.sizeHeight - activityView.frame.sizeHeight) / 2, width: activityView.frame.sizeWidth, height: activityView.frame.sizeHeight)
        }
        
    }
    
    func showLoading(_ bgColor: UIColor? = nil) {
        if let backgroundLoadingView = self.loadingView, let activityView = spinView {
            backgroundLoadingView.isHidden = false
            activityView.startAnimating()
        }else {
            let bgView = UIView()
            bgView.frame = self.bounds
            if let backgroundColor = bgColor {
                bgView.backgroundColor = backgroundColor
            }else {
                bgView.backgroundColor = UIColor.white
            }
            
            
            let activity = UIActivityIndicatorView(activityIndicatorStyle: .gray)
            activity.frame = CGRect(x: (bgView.frame.sizeWidth - activity.frame.sizeWidth) / 2, y: (bgView.frame.sizeHeight - activity.frame.sizeHeight) / 2, width: activity.frame.sizeWidth, height: activity.frame.sizeHeight)
            bgView.addSubview(activity)
            activity.color = UIColor.secondary1()
            activity.startAnimating()
            
            self.loadingView = bgView
            self.spinView = activity
            
            self.addSubview(bgView)
        }
        if bgColor == nil {
            self.layer.borderColor = UIColor.secondary1().cgColor
        }else {
            // Update UI for curator
            self.setTitle("", for: UIControlState())
            self.setImage(nil, for: UIControlState())
            self.layer.borderColor = UIColor.secondary1().cgColor
            self.setBackgroundImage(nil, for: UIControlState())
            self.backgroundColor = UIColor.clear
            iconImageView.isHidden = true
        }
    }
    
    func hideLoading() {
        if let backgroundLoadingView = self.loadingView, let activityView = spinView {
            backgroundLoadingView.isHidden = true
            activityView.stopAnimating()
        }
    }

}
