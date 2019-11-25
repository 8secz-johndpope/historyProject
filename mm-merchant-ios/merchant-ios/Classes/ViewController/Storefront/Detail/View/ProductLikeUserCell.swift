//
//  ProductLikeUserCell.swift
//  merchant-ios
//
//  Created by Quang Truong Dinh on 2/20/17.
//  Copyright © 2017 WWE & CO. All rights reserved.
//

import Foundation

class ProductLikeUserCell: FollowingUserViewCell {
    static let CellIdentifier = "ProductLikeUserCellId"
    static let DefaultHeight: CGFloat = 65
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        imageView.layer.borderWidth = 0
        upperLabel.formatSizeBold(15)
        upperLabel.textColor = UIColor.black
        diamondImageView.isHidden = true
        borderView.isHidden = true
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    func setupCellData(_ productLikeItem: ProductLikeItem) {
        setImage(productLikeItem.profileImage, category: .user, width: Constants.DefaultImageWidth.ProfilePicture)
        upperLabel.text = String(format: "%@", productLikeItem.displayName)
        bottomLabel.text = String(format: "%@", productLikeItem.lastModified.toProductLikeTimeString())
        followButton.setFollowButtonState(self.isFollowing(productLikeItem.userKey))
        followButton.isHidden = (productLikeItem.userKey == Context.getUserKey())
        if productLikeItem.isLoading {
            followButton.showLoading()
        }else {
            followButton.hideLoading()
        }
        self.layoutSubviews()
    }
    
    func isFollowing(_ userKey: String) ->Bool{
        return FollowService.instance.cachedFollowingUserKeys.contains(userKey)
    }
}
