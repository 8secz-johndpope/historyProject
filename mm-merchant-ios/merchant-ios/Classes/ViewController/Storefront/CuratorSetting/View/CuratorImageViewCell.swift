//
//  CuratorImageViewCell.swift
//  merchant-ios
//
//  Created by Vu Dinh Trung on 6/2/16.
//  Copyright © 2016 WWE & CO. All rights reserved.
//

import UIKit

protocol CuratorImageViewCellDelegate: NSObjectProtocol {
    func handleRemovePicture(_ sender: UIButton)
}
class CuratorImageViewCell: UICollectionViewCell {
    
    static let cellHeight = CGFloat(514)
    static let cellId = "CuratorImageViewCell"
    private let widthcloseButton = CGFloat(18)
    private let heightcloseButton = CGFloat(18)
    
    var imageView = UIImageView()
    var closeButton = UIButton()
    weak var delegate: CuratorImageViewCellDelegate!
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        
        
        imageView.image = UIImage(named: "curator_cover_image_placeholder")

		imageView.contentMode = .scaleAspectFill
		imageView.clipsToBounds = true

        self.addSubview(imageView)
        
        closeButton.setImage(UIImage(named: "close_has_background"), for: UIControlState())
        
        closeButton.addTarget(self, action: #selector(CuratorImageViewCell.onCloseHander), for: .touchUpInside)
        self.addSubview(closeButton)
    }
    
    @objc func onCloseHander(_ sender: UIButton) {
        
        if let delegate = self.delegate {
            delegate.handleRemovePicture(sender)
        }
    }
    
    override func layoutSubviews() {
        super.layoutSubviews()
        
        imageView.frame = CGRect(x: Margin.left / 2, y: Margin.left / 2, width: bounds.width - Margin.left , height: bounds.height - Margin.left )
        closeButton.frame = CGRect(x: imageView.frame.maxX - widthcloseButton/2 , y: 0, width: widthcloseButton, height: heightcloseButton)
    }
}
