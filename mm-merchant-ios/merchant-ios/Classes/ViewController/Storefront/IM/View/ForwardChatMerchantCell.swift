//
//  ForwardChatMerchantCell.swift
//  merchant-ios
//
//  Created by HungPM on 6/1/16.
//  Copyright © 2016 WWE & CO. All rights reserved.
//

import Foundation

class ForwardChatMerchantCell: UICollectionViewCell {
    var arrowImageView: UIImageView!
    var avatarImageView: UIImageView!
    let nameLabel = UILabel()
    let tagLabel = UILabel()

    override init(frame: CGRect) {
        super.init(frame: frame)
        
        let Margin = CGFloat(5)

        arrowImageView = { () -> UIImageView in
            let Width = CGFloat(15)
            let imageView = UIImageView(frame: CGRect(x: Margin, y: (frame.height - Width) / 2.0, width: Width, height: Width))
            imageView.contentMode = .scaleAspectFit
            imageView.image = UIImage(named: "fwd_icon")
            
            return imageView
        }()
        contentView.addSubview(arrowImageView)

        avatarImageView = { () -> UIImageView in
            let Width = CGFloat(40)
            let imageView = UIImageView(frame: CGRect(x: arrowImageView.frame.maxX + Margin, y: (frame.height - Width) / 2.0, width: Width, height: Width))
            imageView.contentMode = .scaleAspectFit
            
            return imageView

        }()
        contentView.addSubview(avatarImageView)

        nameLabel.formatSize(15)
        nameLabel.numberOfLines = 1
        contentView.addSubview(nameLabel)

        tagLabel.formatSize(15)
        tagLabel.layer.borderWidth = 1
        tagLabel.layer.cornerRadius = 3
        tagLabel.layer.borderColor = UIColor.backgroundGray().cgColor
        tagLabel.textAlignment = .center
        tagLabel.numberOfLines = 1
        contentView.addSubview(tagLabel)
        
        let separatorView = { () -> UIView in
            let view = UIView(frame: CGRect(x: Margin, y: frame.size.height - 1, width: frame.width - (2 * Margin), height: 1))
            view.backgroundColor = UIColor.backgroundGray()

            return view
        }()
        contentView.addSubview(separatorView)
        
        layoutSubviews()
    }
    
    override func layoutSubviews() {
        super.layoutSubviews()
        
        let Margin = CGFloat(5)

        nameLabel.sizeToFit()
        nameLabel.frame = CGRect(x: avatarImageView.frame.maxX + Margin, y: (frame.height - nameLabel.frame.height) / 2.0, width: nameLabel.frame.width, height: nameLabel.frame.height)

        tagLabel.sizeToFit()
        tagLabel.frame = CGRect(x: nameLabel.frame.maxX + Margin, y: (frame.height - tagLabel.frame.height - 10) / 2.0, width: tagLabel.frame.width + 10, height: tagLabel.frame.height + 10)
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    func displayContent(_ hasContent: Bool) {
        if !hasContent {
            avatarImageView.isHidden = true
            nameLabel.isHidden = true
            tagLabel.isHidden = true
        }
        else {
            avatarImageView.isHidden = false
            nameLabel.isHidden = false
            tagLabel.isHidden = false
        }
    }
}
