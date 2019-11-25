//
//  HeaderBrandLandingView.swift
//  merchant-ios
//
//  Created by Vu Dinh Trung on 7/4/16.
//  Copyright © 2016 WWE & CO. All rights reserved.
//



import UIKit

import Kingfisher

class HeaderBrandLandingView: UICollectionReusableView {
    
    private let heightCoverImage = CGFloat(Constants.ScreenSize.SCREEN_WIDTH * Constants.Ratio.PanelImageHeight)
    private let heightBottomView = CGFloat(64)
    private let widthLogo = CGFloat(162) * Constants.ScreenSize.RATIO_WIDTH
    private let heightLogo = CGFloat(53) * Constants.ScreenSize.RATIO_HEIGHT
    private let widthButton = CGFloat(135) * Constants.ScreenSize.RATIO_WIDTH
    private let heightButton = CGFloat(33) * Constants.ScreenSize.RATIO_HEIGHT
    
    var coverImageView          = UIImageView()
    var overlay                 = UIImageView()
    var overlayBottom           = UIImageView()
	var showAllProductButton	= UIButton()
    
    var labelName = UILabel()
    var bottomView = UIView()
    var line : UIView?
    var blurredEffectView: UIVisualEffectView?
    
    var brand : Brand? {
        didSet {
            if let brand = brand {
                setCoverImage(brand.profileBannerImage, imageCategory: .brand)

                labelName.text = brand.brandName
                self.layoutSubviews()

            }
        }
    }
    
    var completionSeeAllHandler: (()->())?
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        
        self.backgroundColor = UIColor.white
        
        coverImageView.image = UIImage(named: "overlay")
        coverImageView.contentMode = .scaleAspectFill
        coverImageView.clipsToBounds = true
        coverImageView.isUserInteractionEnabled = false
        self.addSubview(coverImageView)
        
        overlay.image = UIImage(named: "overlay")
        coverImageView.addSubview(overlay)
        
        overlayBottom.image = UIImage(named: "overlay_bottom")
        coverImageView.addSubview(overlayBottom)
		
        self.addSubview(bottomView)
        
        let labelHeight = CGFloat(21)
        
        let name = ""
        let widthName = StringHelper.getTextWidth(name, height: heightButton, font: (labelName.font)!)
        
        labelName = UILabel(frame: CGRect(x: (bounds.width - widthName)/2, y: (heightBottomView - labelHeight)/2, width: widthName, height: labelHeight))
        labelName.text = name
        labelName.formatSize(15)
        labelName.textAlignment = .center
        bottomView.addSubview(labelName)
        
        line = UIView()
        line!.backgroundColor = UIColor.backgroundGray()
        bottomView.addSubview(line!)
		
		let titleString = String.localize("LB_CA_BLP_ALL_PRODUCTS")
				
		showAllProductButton = UIButton(type: .custom)
		showAllProductButton.frame = CGRect(x: (bounds.width - widthButton) / 2, y: bottomView.frame.origin.y - heightButton - 12, width: widthButton, height: heightButton)
		showAllProductButton.setTitle(titleString, for: UIControlState())
		showAllProductButton.setTitleColor(UIColor.secondary2(), for: UIControlState())
		showAllProductButton.titleLabel?.font = UIFont.systemFont(ofSize: 14)
		showAllProductButton.addTarget(self, action: #selector(HeaderBrandLandingView.onHandleSeeAllProduct), for: .touchUpInside)
		showAllProductButton.viewBorder(UIColor.white, width: 1.0)
		showAllProductButton.backgroundColor = UIColor.whiteColorWithAlpha()
		
//        let blurEffect = UIBlurEffect(style: .Light)
//        blurredEffectView = UIVisualEffectView(effect: blurEffect)
//        addSubview(blurredEffectView!)
        
        self.addSubview(showAllProductButton)
        
		
    }
    
    override func layoutSubviews() {
        super.layoutSubviews()
        
        coverImageView.frame = CGRect(x: 0, y: 0, width: self.frame.width, height: self.frame.height - heightBottomView)
        
        let height = CGFloat(100)
        overlay.frame = CGRect(x: 0, y: 0, width: self.frame.size.width, height: height)
        
        var frameOverlayBottom = overlay.frame
        frameOverlayBottom.originY = coverImageView.frame.height - frameOverlayBottom.size.height
        overlayBottom.frame = frameOverlayBottom
        
        if let name = labelName.text {
            
            let widthName = StringHelper.getTextWidth(name, height: heightButton, font: (labelName.font)!)
            let labelHeight = CGFloat(21)
            labelName.frame = CGRect(x: (bounds.width - widthName)/2, y: (heightBottomView - labelHeight)/2, width: widthName, height: labelHeight)
            
        }

        
        bottomView.frame = CGRect(x: 0, y: self.frame.height - heightBottomView, width: bounds.width, height: heightBottomView)
        
        let marginLeft = CGFloat(15)
		line!.frame = CGRect(x: marginLeft, y: bottomView.frame.height - 1, width: bounds.width - marginLeft * 2, height: 1)
		showAllProductButton.frame = CGRect(x: (bounds.width - widthButton) / 2, y: bottomView.frame.origin.y - heightButton - 12, width: widthButton, height: heightButton)
		
//        blurredEffectView!.frame = buttonMore.frame
        		
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    func originY() -> CGFloat {
        var originY:CGFloat = 0;
        let application: UIApplication = UIApplication.shared
        if (application.isStatusBarHidden)
        {
            originY = application.statusBarFrame.size.height
        }
        return originY;
    }
    
    //MARK: loading data
    
    func setCoverImage(_ key : String, imageCategory : ImageCategory){
        if self.frame.height > 0 {
            coverImageView.mm_setImageWithURL(HeaderMyProfileCell.getCoverImageUrl(key, imageCategory: imageCategory, width: self.width), placeholderImage: UIImage(named: "default_cover"), contentMode: .scaleAspectFill)
        }
    }
	
    @objc func onHandleSeeAllProduct(_ sender: UIButton) {
        
        if let callback = completionSeeAllHandler {
            callback()
        }
        
        sender.analyticsViewKey = self.analyticsViewKey //make sure view key is copied
            
        //record action
        sender.recordAction(
            .Tap,
            sourceRef: "AllProducts",
            sourceType: .Button,
            targetRef: String(format: "%d",self.brand?.brandId ?? 0),
            targetType: .Brand
        )
    }
}
