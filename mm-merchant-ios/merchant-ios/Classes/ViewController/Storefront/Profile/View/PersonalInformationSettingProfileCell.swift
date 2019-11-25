//
//  PersonalInformationSettingProfileCell.swift
//  merchant-ios
//
//  Created by Sang on 2/2/16.
//  Copyright © 2016 WWE & CO. All rights reserved.
//

import Foundation


class PersonalInformationSettingProfileCell: UICollectionViewCell {
    
    static let CellIdentifier = "PersonalInformationSettingProfileCellID"
    
    private final let MarginLeft: CGFloat = 20
    private final let ItemLabelHeight: CGFloat = 42
    private final let ProfileImageDimension: CGFloat = 40
    private final let ProfileImageMarginRight: CGFloat = 16
    
    var itemLabel = UILabel()
    var profileImageView = UIImageView()
    private var disclosureIndicatorImageView = UIImageView()
    private var borderView = UIView()
    
    var tappedDisclosureIndicator: (()->())?
    var arrowButton : UIButton!
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        self.backgroundColor = UIColor.white
        self.clipsToBounds = true
        
        itemLabel.formatSize(14)
        addSubview(itemLabel)
        
        profileImageView.image = UIImage(named: Constants.ImageName.ProfileImagePlaceholder)
        profileImageView.isUserInteractionEnabled = true
        profileImageView.round()
        addSubview(profileImageView)
        
        arrowButton = UIButton()
        arrowButton.addSubview(disclosureIndicatorImageView)
        arrowButton.addTarget(self, action: #selector(PersonalInformationSettingProfileCell.onTappedDisclorsureIndicator), for: UIControlEvents.touchUpInside)
        addSubview(arrowButton)
        
        disclosureIndicatorImageView.image = UIImage(named: "filter_right_arrow")
        addSubview(disclosureIndicatorImageView)
        
        borderView.backgroundColor = UIColor.secondary1()
        addSubview(borderView)
    }
    
    override func layoutSubviews() {
        super.layoutSubviews()
        
        borderView.frame = CGRect(x: bounds.minX, y: bounds.maxY - 1, width: bounds.width, height: 1)
       
        disclosureIndicatorImageView.frame = CGRect(x: bounds.maxX - 35 , y: bounds.midY - disclosureIndicatorImageView.image!.size.height / 2 , width: disclosureIndicatorImageView.image!.size.width, height: disclosureIndicatorImageView.image!.size.height)
        
        
        profileImageView.frame = CGRect(
            x: disclosureIndicatorImageView.frame.origin.x - ProfileImageDimension - ProfileImageMarginRight,
            y: bounds.midY - (ProfileImageDimension / 2),
            width: ProfileImageDimension,
            height: ProfileImageDimension
        )
        
        arrowButton.frame = CGRect(x: profileImageView.frame.maxX, y: 0, width: bounds.width - profileImageView.frame.maxX, height: bounds.height)
        
        
        
        itemLabel.frame = CGRect(
            x: MarginLeft,
            y: bounds.midY - (ItemLabelHeight / 2),
            width: bounds.width - MarginLeft - profileImageView.frame.origin.x,
            height: ItemLabelHeight
        )
        
        profileImageView.layer.cornerRadius = ProfileImageDimension / 2
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    func setProfileImage(_ key: String) {
        profileImageView.mm_setImageWithURL(ImageURLFactory.URLSize128(key, category: .user), placeholderImage: UIImage(named: Constants.ImageName.ProfileImagePlaceholder), contentMode: .scaleAspectFit)
    }
    
    func showBorder(_ isShow: Bool) {
        borderView.isHidden = !isShow
    }
    
    func showDisclosureIndicator(_ isShow: Bool) {
        disclosureIndicatorImageView.isHidden = !isShow
    }
    
    @objc func onTappedDisclorsureIndicator() {
        
        if let callback = tappedDisclosureIndicator {
            callback()
        }
        
    }
}
