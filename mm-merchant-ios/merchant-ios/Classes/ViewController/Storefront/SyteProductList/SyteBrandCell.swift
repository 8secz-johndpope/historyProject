//
//  SyteBrandCell.swift
//  storefront-ios
//
//  Created by Leslie Zhang on 2018/8/20.
//  Copyright © 2018年 WWE & CO. All rights reserved.
//

import UIKit

import Foundation



class SyteBrandCell: UICollectionViewCell, UICollectionViewDataSource, UICollectionViewDelegate {
    private var brandList = [Brand]() {
        didSet {
            collectionView.setContentOffset(CGPoint(x: -15, y: 0), animated: false)
            collectionView.reloadData()
        }
    }
    
    // MARK: - init
    override init(frame: CGRect) {
        super.init(frame: frame)
        
        self.backgroundColor = UIColor.white
        
        contentView.addSubview(collectionView)
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    // MARK: - CollectionViewDataSoure & CollectionViewDelegate
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return brandList.count
    }
    
    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        if let cell = collectionView.dequeueReusableCell(withReuseIdentifier: "SyteBrandContentCell", for: indexPath) as? SyteBrandContentCell {
            cell.tag = indexPath.row
            
            let brand = self.brandList[indexPath.row]
            
            cell.contentImageView.mm_setImageWithURL(ImageURLFactory.URLSize512(brand.smallLogoImage, category: .brand), placeholderImage: UIImage(named: "brand_placeholder"))
            cell.track_visitId = brand.vid //埋点需要
            return cell
        }
        return UICollectionViewCell()
    }
    
    func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        let brand = self.brandList[indexPath.row]
        let link = Navigator.mymm.website_brand_brandId + String(brand.brandId)
        Navigator.shared.dopen(link)
    }
    
    
    override func ssn_onDisplay(_ tableView: UIScrollView, model: AnyObject, atIndexPath indexPath: IndexPath, reused: Bool) {
        if let model = model as? SyteBrandCellModel {
            if let brandList = model.brandList {
                self.brandList = brandList
            }
        }
    }
    
    // MARK: - lazy
    lazy var collectionView:UICollectionView = {
        let layout = UICollectionViewFlowLayout()
        layout.scrollDirection = .horizontal
        layout.itemSize = CGSize(width: 110, height: frame.height - 10)
        layout.minimumLineSpacing = 6
        layout.minimumInteritemSpacing = 0
        let collectionView = UICollectionView(frame: CGRect(x: 0, y: 10, width: frame.width, height: frame.height - 10), collectionViewLayout: layout)
        collectionView.contentInset = UIEdgeInsets(top: 0, left: 15, bottom: 0, right: 15)
        collectionView.backgroundColor = UIColor.white
        collectionView.showsHorizontalScrollIndicator = false
        collectionView.dataSource = self
        collectionView.delegate = self
        collectionView.register(SyteBrandContentCell.self, forCellWithReuseIdentifier: "SyteBrandContentCell")
        return collectionView
    }()
}

class SyteBrandContentCell: UICollectionViewCell {
    lazy var contentImageView:UIImageView = {
        let contentImageView = UIImageView(frame: self.contentView.bounds)
        contentImageView.backgroundColor = UIColor.red
        contentImageView.layer.cornerRadius = 4
        contentImageView.layer.masksToBounds = true
        return contentImageView
    }()
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        
        self.contentView.addSubview(contentImageView)
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}

