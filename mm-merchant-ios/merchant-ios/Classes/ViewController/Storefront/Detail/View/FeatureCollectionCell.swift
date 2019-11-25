//
//  FeatureCollectionCell.swift
//  merchant-ios
//
//  Created by Koon Kit Chan on 7/12/2015.
//  Copyright © 2015 Koon Kit Chan. All rights reserved.
//

import Foundation

class FeatureCollectionCell : UICollectionViewCell {
    
    static let CellIdentifier = "FeatureCollectionCellID"
    
    var featureImageView: UIImageView!
    var activityIndicator: MMActivityIndicator!
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        
        backgroundColor = UIColor.white
        
        activityIndicator = MMActivityIndicator(frame: bounds, type: .pdp)
        activityIndicator.isHidden = true
        addSubview(activityIndicator)
        
        featureImageView = UIImageView(frame: bounds)
        addSubview(featureImageView)
        
        
    }
    
    //MARK: - 
    
    func startActivityIndicator() {
        activityIndicator.isHidden = false
        activityIndicator.startAnimating()
    }
    
    func stopAnimatingActivityIndicator() {
        activityIndicator.isHidden = true
        activityIndicator.stopAnimating()
    }
    
    func setImageRoundedCorners(_ imageKey: String, imageCategory: ImageCategory) {
        
        if imageKey.isEmpty {
            self.featureImageView.image = getPlaceholderImage()
            return
        }
        
        let url = ImageURLFactory.URLSize1000(imageKey, category: imageCategory)
        
        featureImageView.mm_setImageWithURL(url, placeholderImage: getPlaceholderImage(), contentMode: .scaleAspectFill)
    }
    
    
    override func layoutSubviews() {
        super.layoutSubviews()
        featureImageView.frame = self.bounds
        
    }
    
    func setImageURL(urlString: String, contentMode: UIViewContentMode = .scaleAspectFill) {
        if let url = URL(string: urlString) {
            featureImageView.mm_setImageWithURL(url, placeholderImage: getPlaceholderImage(), contentMode: contentMode) { (image, error, cacheType, imageURL) in
                self.stopAnimatingActivityIndicator()
            }
        }
        
    }
    
    func setImage(_ imageKey: String, contentMode: UIViewContentMode = .scaleAspectFill, completion: ((_ image: UIImage) ->())?  ){

        featureImageView.mm_setImageWithURL(ImageURLFactory.URLSize1000(imageKey, category: .product), placeholderImage: getPlaceholderImage(), contentMode: contentMode) { (image, error, cacheType, imageURL) in
            self.stopAnimatingActivityIndicator()
            if let _image = image {
                completion?(_image)
            }
            
        }
        featureImageView.accessibilityValue = imageKey
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
    
    deinit {
        activityIndicator.stopAnimating()
    }
    
}
