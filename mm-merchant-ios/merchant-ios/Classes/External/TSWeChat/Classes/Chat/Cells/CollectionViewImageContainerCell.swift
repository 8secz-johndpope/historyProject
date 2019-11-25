//
//  ImagesCollectionViewCell.swift
//  merchant-ios
//
//  Created by LongTa on 7/5/16.
//  Copyright © 2016 WWE & CO. All rights reserved.
//

import UIKit

class CollectionViewImageContainerCell: UICollectionViewCell, UICollectionViewDelegate,UICollectionViewDelegateFlowLayout,UICollectionViewDataSource {
    
    var listImagesURL = [String]()
    @IBOutlet weak var collectionView: UICollectionView!
    static let CellIdentifier = "CollectionViewImageContainerCellID"
    static let PaddingInset:CGFloat = 5
    
    override func awakeFromNib() {
        super.awakeFromNib()
        
        backgroundColor = UIColor.white
        collectionView.register(ImageCollectCell.self, forCellWithReuseIdentifier: "ImageCollectCell")
        collectionView.backgroundColor = UIColor.white
        collectionView.delegate = self
        collectionView.dataSource = self
        collectionView.reloadData()
    }
    
    //MARK: CollectionView
    func numberOfSections(in collectionView: UICollectionView) -> Int{
        return 1
    }
    
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return listImagesURL.count
    }

    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        let cell = collectionView.dequeueReusableCell(withReuseIdentifier: "ImageCollectCell", for: indexPath) as! ImageCollectCell
        if listImagesURL.count > indexPath.row{
            let imageKey = listImagesURL[indexPath.row]
            if imageKey.length > 0{
                cell.imageView.mm_setImageWithURL(ImageURLFactory.URLSize1000(imageKey, category: .orderReturnImage), placeholderImage : nil, contentMode: UIViewContentMode.scaleAspectFit)
            }
            else{
                cell.imageView.image = nil
            }
        }
        cell.hideBlurTextView()
        cell.filter.isHidden = true
        return cell
    }
    
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, sizeForItemAt indexPath: IndexPath) -> CGSize {
        return CGSize(width: self.frame.size.width/3 - 2*CollectionViewImageContainerCell.PaddingInset, height: OrderItemCell.DefaultHeight)
    }
    
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, insetForSectionAt section: Int) -> UIEdgeInsets {
        return UIEdgeInsets(top: 0, left: CollectionViewImageContainerCell.PaddingInset, bottom: 0, right: CollectionViewImageContainerCell.PaddingInset)
    }
}
