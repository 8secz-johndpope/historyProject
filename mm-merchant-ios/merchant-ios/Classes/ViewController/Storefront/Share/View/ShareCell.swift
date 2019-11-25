//
//  ShareCell.swift
//  merchant-ios
//
//  Created by Vo Huy Hung on 3/18/16.
//  Copyright © 2016 WWE & CO. All rights reserved.
//

import UIKit


class ShareCell: UICollectionViewCell {
    var imageView = UIImageView()
    var imageViewDiamond = UIImageView()
    var label = UILabel()
    private final let PaddingTopBottom : CGFloat = 5
    private final let LabelHeight : CGFloat = 16
    private final let PaddingLeft : CGFloat = 7
    private final let DiamondWidth : CGFloat = 20.0
    override init(frame: CGRect) {
        super.init(frame: frame)
        
        contentView.backgroundColor = UIColor.clear
        imageView.image = UIImage(named: "spacer")
        imageView.contentMode = .scaleAspectFit
        imageView.clipsToBounds = true
        imageView.layer.cornerRadius = (frame.size.width - 2 * PaddingLeft)/2
    
        contentView.addSubview(imageView)
        label.formatSize(13)
        label.textAlignment = .center
        label.numberOfLines = 1
        label.lineBreakMode = .byTruncatingTail
        label.font = UIFont.usernameFont()
        contentView.addSubview(label)
        imageViewDiamond.image = UIImage(named: "curator_diamond")
        imageViewDiamond.isHidden = true
        contentView.addSubview(imageViewDiamond)
    }
    
    func loadImageKey(_ imageKey : String, category : ImageCategory){
       
        imageView.mm_setImageWithURL(ImageURLFactory.URLSize128(imageKey, category: category), placeholderImage : UIImage(named: "default_profile_icon"))
    }
    
    override func layoutSubviews() {
        super.layoutSubviews()
        imageView.frame = CGRect(x: PaddingLeft, y: 0, width: frame.size.width - 2 * PaddingLeft, height: frame.size.width - 2*PaddingLeft)
        imageViewDiamond.frame = CGRect(x: imageView.frame.maxX - (DiamondWidth - 3), y: imageView.frame.maxY - (DiamondWidth - 3), width: DiamondWidth, height: DiamondWidth)
        label.frame = CGRect(x: 0, y: imageView.frame.maxY + PaddingTopBottom, width: frame.size.width, height: LabelHeight)

        
    }
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}
