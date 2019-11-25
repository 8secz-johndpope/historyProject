//
//  ProfileInviteFriendCell.swift
//  merchant-ios
//
//  Created by khanh.nguyen on 2/9/17.
//  Copyright © 2017 WWE & CO. All rights reserved.
//

import UIKit

class ProfileInviteFriendCell: UICollectionViewCell {
    static let CellIdentifier = "ProfileInviteFriendCellID"
    static let DefaultHeight: CGFloat = 48
    
    private var imageView = UIImageView()
    private var leftLabel = UILabel()
    private var rightLabel = UILabel()
    private var viewAllLabel = UILabel()
    private var disclosureIndicatorImageView = UIImageView()
    private var lineView = UIView()
    var viewDidTap: (()->())?
    
    var itemBadgeTopRightCorner: CGPoint?
    var containerMargin = UIEdgeInsets(top: 0, left: 0, bottom: 0, right: 0)
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        self.backgroundColor = UIColor.primary2()
        self.clipsToBounds = true
        
        contentView.backgroundColor = UIColor.white

        imageView.image = UIImage(named: "icon_invite")
        imageView.contentMode = .scaleAspectFit
        contentView.addSubview(imageView)
        
        leftLabel.formatSize(14)
        leftLabel.textColor = UIColor.secondary2()
        leftLabel.text = String.localize("LB_CA_IM_INVITE_FRD")
        
        contentView.addSubview(leftLabel)
        
        disclosureIndicatorImageView.image = UIImage(named: "filter_right_arrow")
        contentView.addSubview(disclosureIndicatorImageView)
        
        viewAllLabel.formatSize(12)
        viewAllLabel.textColor = UIColor.secondary7()
        viewAllLabel.textAlignment = .right
        viewAllLabel.text = String.localize("LB_CA_NATURAL_REFERRAL_CAPTION")
        contentView.addSubview(viewAllLabel)
        
        contentView.addGestureRecognizer(UITapGestureRecognizer(target: self, action: #selector(ProfileInviteFriendCell.onTapViewAll)))
        
    }
    
    override func layoutSubviews() {
        super.layoutSubviews()
        
        let margin: CGFloat = 12
        let imageSize = CGSize(width: 22, height: 22)
        
        imageView.frame = CGRect(x: margin, y: (self.frame.sizeHeight - imageSize.height) / 2, width: imageSize.width, height: imageSize.height)
        
        leftLabel.frame = CGRect(x: imageView.frame.maxX + margin, y: 0, width: leftLabel.optimumWidth(), height: self.frame.size.height)
        
        let disclosureIndicatorImageViewSize = CGSize(width: 6, height: 10)
        disclosureIndicatorImageView.frame = CGRect(x: self.frame.size.width - disclosureIndicatorImageViewSize.width - margin, y: (self.frame.size.height - disclosureIndicatorImageViewSize.height) / 2 , width: disclosureIndicatorImageViewSize.width, height: disclosureIndicatorImageViewSize.height)
        
        viewAllLabel.frame = CGRect(x: disclosureIndicatorImageView.frame.origin.x - viewAllLabel.optimumWidth() - (margin/2), y: 0, width: viewAllLabel.optimumWidth(), height: self.frame.size.height)

    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    class func getHeight() -> CGFloat{
        return ProfileMemberCardCell.DefaultHeight
    }
    
    @objc func onTapViewAll() {
        viewDidTap?()
    }
    
}
