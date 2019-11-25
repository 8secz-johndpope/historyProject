//
//  ImagesCollectionViewCell.swift
//  merchant-ios
//
//  Created by Vu Dinh Trung on 4/11/16.
//  Copyright © 2016 WWE & CO. All rights reserved.
//

import UIKit
import PhotosUI
class ImagesCollectionViewCell: UICollectionViewCell {
    var imageManager: PHImageManager?
    
    var photoImageView =  UIImageView()
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        photoImageView.contentMode = .scaleAspectFill
        photoImageView.clipsToBounds = true
        
        self.addSubview(photoImageView)
    }
    
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    override func layoutSubviews() {
        super.layoutSubviews()
        self.photoImageView.frame = self.bounds
    }
    var imageAsset: PHAsset? {
        didSet {
            let screen: UIScreen = UIScreen.main
            let scale: CGFloat = screen.scale
            // Sizing is very rough... more thought required in a real implementation
            let imageSize: CGFloat = max(screen.bounds.size.width, screen.bounds.size.height) * 1.5
//            var imageTargetSize: CGSize = CGSize(width: imageSize * scale, height: imageSize * scale)
            let thumbTargetSize: CGSize = CGSize(width: imageSize / 3.0 * scale, height: imageSize / 3.0 * scale)

            self.imageManager?.requestImage(for: imageAsset!, targetSize: thumbTargetSize, contentMode: .aspectFit, options: nil) { image, info in
                self.photoImageView.image = image
            }
        }
    }
    
    
}
