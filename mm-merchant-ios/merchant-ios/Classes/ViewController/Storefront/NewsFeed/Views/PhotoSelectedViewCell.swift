//
//  PhotoSelectedViewCellCollectionViewCell.swift
//  merchant-ios
//
//  Created by Sang Nguyen on 12/21/16.
//  Copyright © 2016 WWE & CO. All rights reserved.
//

import UIKit
protocol PhotoSelectedViewCellDelegate: NSObjectProtocol {
    func removedCellAtIndex(_ index: Int)
}
class PhotoSelectedViewCell: UICollectionViewCell {
    private final let MarginTopBottom: CGFloat = 5
    private final let MarginLeftRight: CGFloat = 5
    private final let DeleteButtonWidth: CGFloat = 30
    var imageView = UIImageView()
    var removeButton = UIButton()
    weak var delegate : PhotoSelectedViewCellDelegate?
    var isAmimating = false
    override init(frame: CGRect) {
        super.init(frame: frame)
        backgroundColor = UIColor.white
        imageView.clipsToBounds = true
        self.contentView.addSubview(imageView)
        removeButton.setImage(UIImage(named: "remove_btn"), for: UIControlState())
        self.contentView.addSubview(removeButton)
        self.clipsToBounds = true
        self.backgroundColor = UIColor.secondary2()
        self.contentView.backgroundColor = UIColor.clear
    }
    
    override func layoutSubviews() {
        super.layoutSubviews()
        self.contentView.frame = bounds
        imageView.frame = CGRect(x: MarginLeftRight, y: MarginTopBottom, width: bounds.width - MarginLeftRight * 2, height: bounds.height - MarginTopBottom * 2)
        removeButton.frame = CGRect(x: bounds.maxX - DeleteButtonWidth, y: 0, width: DeleteButtonWidth, height: DeleteButtonWidth)
        let paddingEdgeInset = DeleteButtonWidth - 20
        removeButton.contentEdgeInsets = UIEdgeInsets(top: 0, left: paddingEdgeInset, bottom: paddingEdgeInset, right: 0)
    }
    
    func setImage(_ image: UIImage) {
        imageView.image = image
        imageView.contentMode = .scaleAspectFill
    }
    
    func setImage(_ imageKey: String, category: ImageCategory) {
        let placeholder = UIImage(named: Constants.ImageName.BrandPlaceholder)
        if imageKey.isEmpty {
            self.imageView.image = placeholder
            return
        }
        imageView.mm_setImageWithURL(ImageURLFactory.URLSize1000(imageKey, category: category), placeholderImage: placeholder, contentMode: .scaleAspectFill, progress: nil, optionsInfo: nil, completion: { (image, error, cacheType, imageURL) -> Void in
            if error == nil {
                self.imageView.image = image
            }
        })
    }
    
    func addAnimation() {
        var frame = self.contentView.frame
        frame.origin.y = frame.height
        self.contentView.frame = frame
        frame.origin.y = 0
        UIView.animate(
            withDuration: 0.25,
            animations: { () -> Void in
                self.contentView.frame = frame
            },
            completion:nil)
    }
    
    func removeAnimation(_ index: Int) {
        if self.isAmimating {
            return
        }
        self.isAmimating = true
        var frame = self.contentView.frame
        frame.origin.y = frame.height
        UIView.animate(
            withDuration: 0.25,
            animations: { () -> Void in
                self.contentView.frame = frame
            }, completion: { (success) in
                self.isAmimating = false
                self.delegate?.removedCellAtIndex(index)
                self.layoutSubviews()
                self.isAmimating = false
            })
    }
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}
