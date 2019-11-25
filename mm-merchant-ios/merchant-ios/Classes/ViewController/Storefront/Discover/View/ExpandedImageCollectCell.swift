//
//  ExpandedImageCollectCell.swift
//  merchant-ios
//
//  Created by Koon Kit Chan on 18/12/2015.
//  Copyright © 2015 Koon Kit Chan. All rights reserved.
//

import Foundation

class ExpandedImageCollectCell : UICollectionViewCell {
    var imageView : UIImageView!
    var brandCollectionView : UICollectionView!
    var filter : UIView!
    var label : UILabel!
    var subCatCollectionView : UICollectionView!
    override init(frame: CGRect) {
        super.init(frame: frame)
        backgroundColor = UIColor.white
        imageView = UIImageView(frame: CGRect(x: bounds.minX, y: bounds.minY, width: bounds.width, height: bounds.height / 2))
        imageView.image = UIImage(named: "holder")
        addSubview(imageView)
        filter = UIView(frame: CGRect(x: bounds.minX , y: bounds.midY - 40, width: bounds.width, height: 40))
        filter.backgroundColor = UIColor.black
        filter.alpha = 0.3
        addSubview(filter)
        label = UILabel(frame:CGRect(x: bounds.minX , y: bounds.midY - 40, width: bounds.width, height: 40))
        label.formatSize(17)
        label.textColor = UIColor.white
        label.textAlignment = .center
        addSubview(label)
        let brandLayout: UICollectionViewFlowLayout = UICollectionViewFlowLayout()
        brandLayout.sectionInset = UIEdgeInsets(top: 0, left: 0, bottom: 0, right: 0)
        brandLayout.scrollDirection = UICollectionViewScrollDirection.horizontal
        brandCollectionView = UICollectionView(frame: CGRect(x: bounds.minX, y: bounds.midY, width: bounds.width, height: bounds.width/5), collectionViewLayout: brandLayout)
        brandCollectionView.showsHorizontalScrollIndicator = false
        addSubview(brandCollectionView)
        let subCatLayout: UICollectionViewFlowLayout = UICollectionViewFlowLayout()
        subCatLayout.sectionInset = UIEdgeInsets(top: 0, left: 0, bottom: 0, right: 0)
        subCatLayout.scrollDirection = UICollectionViewScrollDirection.vertical
        subCatCollectionView = UICollectionView(frame: CGRect(x: bounds.minX, y: bounds.midY + bounds.width/5 , width : bounds.width, height: bounds.height - 250), collectionViewLayout: subCatLayout)//TODO define constant for 250
        subCatCollectionView.showsHorizontalScrollIndicator = false
        subCatCollectionView.backgroundColor = UIColor.white
        addSubview(subCatCollectionView)
    }
    
    func setImage(_ key : String, imageCategory : ImageCategory ) {
        imageView.mm_setImageWithURL(ImageURLFactory.URLSize1000(key, category: imageCategory), placeholderImage : UIImage(named: "holder"), contentMode: .scaleAspectFill)
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

}
