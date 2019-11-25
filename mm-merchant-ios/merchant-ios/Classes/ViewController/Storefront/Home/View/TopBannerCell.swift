//
//  TopBannerCell.swift
//  merchant-ios
//
//  Created by khanh.nguyen on 9/5/17.
//  Copyright © 2017 WWE & CO. All rights reserved.
//

import UIKit

protocol TopBannerCellDelegate: NSObjectProtocol {
    func didClickOnCloseButton()
}

class TopBannerCell: BannerCell {
    
    static let ViewHeight = CGFloat(100)
    private var closeButton = UIButton()
    private var iconImageView = UIImageView()
    var topBannerCellDelegate: TopBannerCellDelegate?
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        
        closeButton.addTarget(self, action: #selector(TopBannerCell.clickOnCloseButton), for: .touchUpInside)
        iconImageView.image = UIImage(named: "close_has_background")
        
        self.addSubview(closeButton)
        
        self.addSubview(iconImageView)
    }
    
    override func layoutSubviews() {
        super.layoutSubviews()
        let iconSize = CGSize(width: 20, height: 20)
        let buttonSize = CGSize(width: 44, height: 44)
        closeButton.frame = CGRect(x: self.frame.size.width - buttonSize.width - Margin.left, y: Margin.top, width: buttonSize.width, height: buttonSize.height)
        iconImageView.frame = CGRect(x: self.frame.size.width - iconSize.width - Margin.left, y: Margin.top, width: iconSize.width, height: iconSize.height)
    }
 
    
    @objc func clickOnCloseButton(_ sender: Any) {
        topBannerCellDelegate?.didClickOnCloseButton()
        let currentPage = self.getCurrentPage()
        if currentPage > 0 && currentPage < self.bannerList.count {
            let currentBanner = self.bannerList[currentPage]
            
            self.recordAction(.Tap, sourceRef: currentBanner.bannerKey, sourceType: .Banner, targetRef: "Newsfeed-Home-User", targetType: .View)
        }
        
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}
