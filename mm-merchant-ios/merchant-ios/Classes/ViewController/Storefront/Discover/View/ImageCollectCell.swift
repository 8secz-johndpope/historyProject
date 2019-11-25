//
//  ImageCollectCell.swift
//  merchant-ios
//
//  Created by Koon Kit Chan on 17/12/2015.
//  Copyright © 2015 Koon Kit Chan. All rights reserved.
//

import Foundation

class ImageCollectCell: UICollectionViewCell {
    
    var imageView = UIImageView()
    var activityIndicator: MMActivityIndicator!
    var filter = UIView()
    var label = UILabel()
    var blurEffectView: UIVisualEffectView!
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        backgroundColor = UIColor.white
        
        activityIndicator = MMActivityIndicator(frame: bounds, type: .pdp)
        activityIndicator.isHidden = true
        addSubview(activityIndicator)
        
        imageView.image = nil
        addSubview(imageView)
        
        filter.backgroundColor = UIColor.black
        filter.alpha = 0.3
        addSubview(filter)
        
        let blurEffect = UIBlurEffect(style: .dark)
        blurEffectView = UIVisualEffectView(effect: blurEffect)
        blurEffectView.alpha = 0.8
        blurEffectView.isHidden = true
        addSubview(blurEffectView)
        
        label.formatSmall()
        label.textAlignment = .center
        addSubview(label)
    }
    
    override func layoutSubviews() {
        super.layoutSubviews()
        imageView.frame = bounds
        label.frame = CGRect(x: bounds.midX - 30, y: bounds.midY - 20, width: 60, height: 40)
        filter.frame = bounds
    }
    

    func setImage(_ imageKey: String, category: ImageCategory, size: ResizerSize = .size1000) {
        if imageKey.isEmpty {
            self.imageView.image = self.placeholderImage()
            return
        }
        
        self.imageView.image = self.placeholderImage()
        
        imageView.mm_setImageWithURL(ImageURLFactory.URLSize(size, key: imageKey, category: category), placeholderImage: self.placeholderImage(), contentMode: .scaleAspectFit, progress: nil, optionsInfo: nil, completion: { (image, error, cacheType, imageURL) -> Void in
            if error == nil {
                self.imageView.image = image
            }
        })
    }
    
    func placeholderImage() -> UIImage?{
        return UIImage(named: Constants.ImageName.BrandPlaceholder)
    }
    
    func setLocalImage(_ name: String) {
        imageView.image = UIImage(named: name)
        imageView.contentMode = .scaleAspectFit
    }
    
    func setImageRoundedCorners(_ imageKey: String, category: ImageCategory) {
        imageView.mm_setImageWithURL(ImageURLFactory.URLSize1000(imageKey, category: category), placeholderImage: getPlaceholderImage(), contentMode: .scaleAspectFill)
    }
    
    func showBlurTextView() {
        label.textColor = UIColor.white
        blurEffectView.frame = CGRect(x: bounds.midX - 30, y: bounds.midY - 15, width: 60, height: 30)
        blurEffectView.isHidden = false
    }

    func hideBlurTextView() {
        blurEffectView.isHidden = true
    }
    
    func startActivityIndicator() {
        activityIndicator.isHidden = false
        activityIndicator.startAnimating()
    }
    
    func stopAnimatingActivityIndicator() {
        activityIndicator.isHidden = true
        activityIndicator.stopAnimating()
    }
    
    private func getPlaceholderImage() -> UIImage? {
        if activityIndicator.isHidden {
            return UIImage(named: "holder")
        }
        
        return nil
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}
