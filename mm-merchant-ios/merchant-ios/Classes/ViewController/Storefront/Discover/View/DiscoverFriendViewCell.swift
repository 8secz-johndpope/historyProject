//
//  DiscoverFriendViewCell.swift
//  merchant-ios
//
//  Created by Quang Truong on 12/12/17.
//  Copyright © 2017 WWE & CO. All rights reserved.
//

import Foundation

class DiscoverFriendViewCell: SearchFriendViewCell{
    
    private final let MarginRight : CGFloat = 20
    
    var followButton = ButtonFollow()
    var followButtonClickHandler: ((DiscoverFriendViewCell, ButtonFollow) -> ())?
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        
        buttonView.isHidden = true
        followButton.addTarget(self, action: #selector(DiscoverFriendViewCell.followButtonClicked), for: UIControlEvents.touchUpInside)
        addSubview(followButton)
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override func layoutSubviews() {
        super.layoutSubviews()
        followButton.frame = CGRect(x: frame.sizeWidth - ButtonFollow.ButtonFollowSize.width - MarginRight, y: (bounds.height - ButtonFollow.ButtonFollowSize.height)/2, width: ButtonFollow.ButtonFollowSize.width, height: ButtonFollow.ButtonFollowSize.height)
        
        upperLabel.frame = CGRect(x: upperLabel.frame.origin.x, y: upperLabel.frame.origin.y, width: upperLabel.frame.width - 90, height: upperLabel.frame.height)
    }
    
    override func gestureRecognizerShouldBegin(_ gestureRecognizer: UIGestureRecognizer) -> Bool {
        return false
    }
    
    override func setData(_ user: User) {
        super.setData(user)
        followButton.setFollowButtonState(FollowService.instance.cachedFollowingUserKeys.contains(user.userKey ))
    }
    
    @objc func followButtonClicked(_ sender: ButtonFollow){
        followButtonClickHandler?(self, sender)
    }
}
