//
//  HomeFooterView.swift
//  merchant-ios
//
//  Created by khanh.nguyen on 3/28/17.
//  Copyright © 2017 WWE & CO. All rights reserved.
//

import UIKit

protocol HomeFooterViewDelegate: NSObjectProtocol {
    func listAllItems(_ section: Int)
}

class HomeFooterView: UICollectionReusableView {
    
    var imageView = UIImageView()
    var label = UILabel()
    static let FooterIdentifier = "FooterIdentifier"
    static let ViewHeight = CGFloat(68)
    
    var section: Int?
    
    weak var delegate: HomeFooterViewDelegate?
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        self.backgroundColor = UIColor.white
        
        imageView.image = UIImage(named: "filter_right_arrow")
        self.addSubview(imageView)
        
        label.layer.borderColor = UIColor.secondary1().cgColor
        label.layer.borderWidth = CGFloat(0.5)
        label.layer.cornerRadius = Constants.Value.FollowButtonCornerRadius
        label.clipsToBounds = true
        
        label.formatSize(14)
        
        label.textAlignment = NSTextAlignment.center
        label.textColor = UIColor.secondary2()
        self.addSubview(label)
        
        label.addGestureRecognizer(UITapGestureRecognizer(target: self, action: #selector(self.didViewAllMerchant)))
        label.isUserInteractionEnabled = true
    }
    
    override func layoutSubviews() {
        super.layoutSubviews()
        let size = CGSize(width: 114, height: 38)
        let originY = CGFloat(15)
        let width = StringHelper.getTextWidth(label.text ?? "", height: HomeHeaderView.LabelHeight, font: label.font)
        label.frame = CGRect(x: (self.bounds.sizeWidth - size.width) / 2, y: originY, width: size.width, height: size.height)
        
        let imageSize = CGSize(width: 5, height: 8)
        let margin = CGFloat(10)
        imageView.frame = CGRect(x: label.frame.midX + margin + width / 2, y: label.frame.midY - imageSize.height / 2, width: imageSize.width, height: imageSize.height)
    }
    
    @objc func didViewAllMerchant(_ gesture : UITapGestureRecognizer) {
        guard let sec = section else { return }
        delegate?.listAllItems(sec)
    }
}
