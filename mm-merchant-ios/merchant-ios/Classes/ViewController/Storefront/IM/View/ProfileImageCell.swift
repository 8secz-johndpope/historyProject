//
//  ProfileImageCell.swift
//  merchant-ios
//
//  Created by HungPM on 6/15/16.
//  Copyright © 2016 WWE & CO. All rights reserved.
//

import Foundation

class ProfileImageCell: UICollectionViewCell {
    
    var profileImageView: UIImageView!
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        
        profileImageView = UIImageView(frame: CGRect(x: 0, y: 0, width: frame.size.width, height: frame.size.height))
        profileImageView.contentMode = .scaleAspectFit
        profileImageView.round()
        contentView.addSubview(profileImageView)
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

}
