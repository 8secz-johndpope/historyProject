//
//  QRCodeView.swift
//  merchant-ios
//
//  Created by Tony Fung on 7/3/2016.
//  Copyright © 2016年 WWE & CO. All rights reserved.
//

import UIKit
import QRCode

class QRCodeView: UIView {

    /*
    // Only override drawRect: if you perform custom drawing.
    // An empty implementation adversely affects performance during animation.
    override func drawRect(rect: CGRect) {
        // Drawing code
    }
    */

    private var profileImageSize = CGSize(width: 70, height: 70)
    
    
    var profileImageView = UIImageView()
    var qrImageView = UIImageView()
    var qrLogoImageView = UIImageView()
    var userNameLabel = UILabel()
    var instructionLabel = UILabel()
    private var holderView = UIView()
    
    override init(frame: CGRect) {
        super.init(frame: frame)

 
        profileImageView.layer.cornerRadius = profileImageSize.height / 2
        profileImageView.layer.borderWidth = 2.0
        profileImageView.layer.borderColor = UIColor.white.cgColor
        profileImageView.clipsToBounds = true
        profileImageView.image = UIImage(named: "default_profile_icon")
        profileImageView.backgroundColor = UIColor.white
        
        instructionLabel.text = String.localize("LB_CA_IM_MY_QRCODE_NOTE")
        instructionLabel.formatSize(12)
        instructionLabel.textAlignment = .center
        
        userNameLabel.font = UIFont.usernameFont()
        userNameLabel.textColor = .black
        userNameLabel.textAlignment = .center
        
        holderView.backgroundColor = UIColor.white
        holderView.layer.cornerRadius = 10
        self.addSubview(holderView)
        
        holderView.addSubview(qrImageView)
        holderView.addSubview(userNameLabel)
        holderView.addSubview(instructionLabel)
        
//        holderView.pointInside(<#T##point: CGPoint##CGPoint#>, withEvent: <#T##UIEvent?#>)
        
        self.addSubview(profileImageView)
        

        qrLogoImageView.isHidden = true
        qrLogoImageView.image = UIImage(named: "QR_MMicon")
        holderView.addSubview(qrLogoImageView)
        
//        self.isUserInteractionEnabled = false
//        self.holderView.isUserInteractionEnabled = true
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    
    private let userNameLabelSize = CGSize(width: 260, height: 40)
    private let qrCodeImageSize = CGSize(width: 220, height: 220)
    private let qrLogoImageSize = CGSize(width: 40, height: 40)
    
    override func layoutSubviews() {
        super.layoutSubviews()
        profileImageView.frame = CGRect(x: bounds.midX - profileImageSize.width/2, y: bounds.minY, width: profileImageSize.width, height: profileImageSize.height)
        holderView.frame = CGRect(x: bounds.minX, y: bounds.minY + profileImageSize.height / 2, width: bounds.width, height: bounds.height - profileImageSize.height)
        userNameLabel.frame = CGRect(x: (holderView.bounds.width - userNameLabelSize.width)/2, y: holderView.bounds.minY + profileImageSize.height/2 + 5, width: userNameLabelSize.width, height: userNameLabelSize.height)
        qrImageView.frame = CGRect(x: bounds.midX - qrCodeImageSize.width/2, y: userNameLabel.frame.maxY + 5, width: qrCodeImageSize.width, height: qrCodeImageSize.height)
        instructionLabel.frame = CGRect(x: holderView.bounds.minX + 10, y: holderView.bounds.maxY - 40, width: holderView.bounds.width - 20, height: 30)
        
        qrLogoImageView.frame = CGRect(x: 0, y: 0, width: qrLogoImageSize.width, height: qrLogoImageSize.height)
        qrLogoImageView.center = qrImageView.center
    }
    
    func configUser(_ user: User){
        userNameLabel.text = user.displayName
        var qrCode = QRCode(EntityURLFactory.userURL(user).absoluteString)
        qrCode?.color = CIColor(rgba: "ed2247")
        qrImageView.image = qrCode?.image
        setProfileImage(user.profileImage)
        qrLogoImageView.isHidden = false
    }
    
    func setProfileImage(_ key : String){
      
        profileImageView.mm_setImageWithURL(ImageURLFactory.URLSize256(key, category: .user), placeholderImage : UIImage(named: Constants.ImageName.ProfileImagePlaceholder), contentMode: .scaleAspectFit)
    }
    
    
}
