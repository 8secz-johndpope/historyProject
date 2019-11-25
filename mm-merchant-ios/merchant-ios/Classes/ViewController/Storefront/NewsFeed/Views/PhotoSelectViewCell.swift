//
//  PhotoSelectViewCell.swift
//  merchant-ios
//
//  Created by Sang Nguyen on 12/21/16.
//  Copyright © 2016 WWE & CO. All rights reserved.
//

import Foundation

class PhotoSelectViewCell: PhotoAssetCollectionViewCell {

    private final let MarginTopRight: CGFloat = 10
    private final let SelectIconWidth: CGFloat = 20
    private var imageView = UIImageView()
    private var imageSelect = UIImageView()
    
    var isCameraCell: Bool = false {
        didSet {
            imageSelect.isHidden = isCameraCell
            if isCameraCell {
                autoreleasepool {
                    imageView.image = UIImage(named: "capture_photo")
                }
            }
        }
    }
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        backgroundColor = UIColor.white
        imageView.contentMode = .scaleAspectFill
        imageView.clipsToBounds = true
        addSubview(imageView)
        addSubview(imageSelect)
    }
    
    override func layoutSubviews() {
        super.layoutSubviews()
        imageView.frame = bounds
        imageSelect.frame = CGRect(x: bounds.maxX - SelectIconWidth - MarginTopRight, y: MarginTopRight, width: SelectIconWidth, height: SelectIconWidth)
    }
    
    override func didAssetReady(_ image: UIImage?) {
        super.didAssetReady(image)
        if !isCameraCell {
            imageView.image = image
        }
    }
    
    func setSelect(_ isSelect: Bool){
        imageSelect.image = isSelect ? UIImage(named: "icon_checkbox_checked") : UIImage(named: "checkbox_nil")
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}

