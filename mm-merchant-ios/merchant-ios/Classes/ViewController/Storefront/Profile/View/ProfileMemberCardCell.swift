//
//  ProfileMemberCardCell.swift
//  merchant-ios
//
//  Created by Quang Truong Dinh on 2/7/17.
//  Copyright © 2017 WWE & CO. All rights reserved.
//

import UIKit

class ProfileMemberCardCell: UICollectionViewCell {
    static let CellIdentifier = "ProfileMemberCardCellID"
    static let DefaultHeight: CGFloat = 57
    
    private var containerView = UIView()
    private var redDotView = UIView()
    private var viewAllRow = UIView()
    private var viewAllButton = UIButton()
    private var disclosureIndicatorImageView = UIImageView()
   
    let titleLabel = UILabel()
    var viewAllLabel = UILabel()
    var titleImageView = UIImageView()
    var cardTypeImageView = UIImageView()

    var itemBadgeTopRightCorner: CGPoint?
    var containerMargin = UIEdgeInsets(top: 0, left: 0, bottom: 0, right: 0)
    
    var loyalty: Loyalty?{
        didSet{
            guard let loyalty = loyalty else {
                return
            }
            
            viewAllLabel.text = loyalty.memberLoyaltyStatusName
            
            layoutSubviews()
        }
    }

    var viewDidTap: ((ProfileMemberCardCell)->())?
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        self.backgroundColor = UIColor.primary2()
        self.clipsToBounds = true
        
        containerView.backgroundColor = UIColor.white
        viewAllRow.backgroundColor = UIColor.white
        
        viewAllButton.backgroundColor = UIColor.clear
        viewAllButton.addTarget(self, action: #selector(onTapViewAll), for: .touchUpInside)
        
        addSubview(containerView)
        containerView.addSubview(viewAllRow)
        
        titleImageView.contentMode = .scaleAspectFit
        viewAllRow.addSubview(titleImageView)
        
        titleLabel.formatSize(14)
        titleLabel.textColor = UIColor.secondary2()
        viewAllRow.addSubview(titleLabel)
        
        redDotView.backgroundColor = UIColor.red
        viewAllRow.addSubview(redDotView)
        redDotView.isHidden = true
        
        disclosureIndicatorImageView.image = UIImage(named: "filter_right_arrow")
        viewAllRow.addSubview(disclosureIndicatorImageView)
        
        viewAllLabel.formatSize(12)
        viewAllLabel.textColor = UIColor.secondary7()
        viewAllLabel.textAlignment = .right
        viewAllLabel.text = ""
        viewAllRow.addSubview(viewAllLabel)
        
        viewAllRow.addSubview(cardTypeImageView)
        
        viewAllRow.addSubview(viewAllButton)
    }
    
    override func layoutSubviews() {
        super.layoutSubviews()
        
        let viewAllRowHeight: CGFloat = ProfileMemberCardCell.getHeight()
        let containerHorizontalMargin: CGFloat = 12
        
        containerView.frame = CGRect(x: 0, y: containerMargin.top, width: bounds.size.width, height: bounds.size.height - (containerMargin.top - containerMargin.bottom))
        
        viewAllRow.frame = CGRect(x: containerHorizontalMargin, y: 0, width: containerView.frame.size.width - (containerHorizontalMargin * 2), height: viewAllRowHeight)
        
        // Title
        let titleImageSize = CGSize(width: 22, height: 22)
        titleImageView.frame = CGRect(x: 0, y: (viewAllRowHeight - titleImageSize.height)/2, width: titleImageSize.width, height: titleImageSize.height)
        
        titleLabel.frame = CGRect(x: titleImageView.frame.maxX + containerHorizontalMargin, y: 0, width: titleLabel.optimumWidth(), height: viewAllRow.frame.size.height)
        
        // Red dot
        redDotView.frame = CGRect(x: titleLabel.frame.maxX + 10, y: titleLabel.frame.midY - 3, width: 6, height: 6)
        redDotView.round()
        
        // Disclosure Indicator
        let disclosureIndicatorImageViewSize = CGSize(width: 6, height: 10)
        disclosureIndicatorImageView.frame = CGRect(x: viewAllRow.frame.size.width - disclosureIndicatorImageViewSize.width, y: (viewAllRow.frame.size.height - disclosureIndicatorImageViewSize.height) / 2 , width: disclosureIndicatorImageViewSize.width, height: disclosureIndicatorImageViewSize.height)
        
        // View all label
        viewAllLabel.frame = CGRect(x: disclosureIndicatorImageView.frame.origin.x - viewAllLabel.optimumWidth() - 6, y: 0, width: viewAllLabel.optimumWidth(), height: viewAllRow.frame.size.height)
        
        //Card Type ImageView
        let cardTypeImageSize = CGSize(width: 24, height: 24)
        cardTypeImageView.frame = CGRect(x: viewAllLabel.frame.minX - cardTypeImageSize.width - 6, y: (viewAllRowHeight - cardTypeImageSize.height)/2, width: cardTypeImageSize.width, height: cardTypeImageSize.height)
        
        // All Button
        viewAllButton.frame = viewAllRow.bounds
        
        // Border
        let borderView = UIView(frame: CGRect(x: 0, y: viewAllRow.frame.size.height - 1, width: viewAllRow.frame.size.width, height: 1))
        borderView.backgroundColor = UIColor.primary2()
        borderView.isHidden = Constants.SNSFriendReferralEnabled ? false : true
        viewAllRow.addSubview(borderView)
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    func showRedDot(_ isShow: Bool){
        redDotView.isHidden = !isShow
    }
    
    class func getHeight() -> CGFloat{
        return ProfileMemberCardCell.DefaultHeight
    }
    //MARK: - Action Entry Button
    
    @objc func onTapViewAll() {
        viewDidTap?(self)
    }
}
