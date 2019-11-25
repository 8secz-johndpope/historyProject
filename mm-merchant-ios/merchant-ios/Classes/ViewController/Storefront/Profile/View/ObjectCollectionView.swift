//
//  ObjectCollectionView.swift
//  merchant-ios
//
//  Created by Vu Dinh Trung on 4/24/16.
//  Copyright © 2016 WWE & CO. All rights reserved.
//

import UIKit

class ObjectCollectionView: UICollectionViewCell {
    
    private final let AvatarImageWidth : CGFloat = 32
    var avatarView = AvatarView(imageStr: "", width: 32, height: 32, mode: ModeSizeAvatar.small)
    
    var user = User()
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        self.addSubview(avatarView)
        avatarView.clipsToBounds = true
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override func layoutSubviews() {
        super.layoutSubviews()
        avatarView.imageView.frame = CGRect(x: 0, y: 0, width: AvatarImageWidth, height: AvatarImageWidth)
        avatarView.imageView.layer.cornerRadius = AvatarImageWidth / 2
    }
    
    func setupDataByUser(_ user: User) -> Void {
        self.user = user
        self.avatarView.setAvatarImage(user.profileImage)
    }
}
