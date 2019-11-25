//
//  CMSPageBrandListBannerCell.swift
//  MMDemoForLeslie_Swift4.0
//
//  Created by Leslie Zhang on 2018/3/26.
//  Copyright © 2018年 Leslie Zhang. All rights reserved.
//

import UIKit

class CMSPageBrandListBannerCell: UICollectionViewCell,UICollectionViewDelegate,UICollectionViewDataSource{
    var _layout:UICollectionViewFlowLayout!
    var _table:UICollectionView!
    var _datas = [CMSPageDataModel]()
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        
        self.backgroundColor = UIColor.white
        
        _layout = UICollectionViewFlowLayout()
        _layout.scrollDirection = UICollectionViewScrollDirection.horizontal
        
        _table = UICollectionView(frame: self.bounds, collectionViewLayout: _layout)
        _table.dataSource = self
        _table.delegate = self
        _table.backgroundColor = UIColor.clear
        _table.alwaysBounceVertical = false
        _table.bounces = false
        _table.showsHorizontalScrollIndicator = false
        _table.showsVerticalScrollIndicator = false
        _table.register(CMSPagePageGegridBannerContentCell.self, forCellWithReuseIdentifier: "CMSPagePageGegridBannerContentCell")
        self.contentView.addSubview(_table)
        _table.snp.makeConstraints { (make) in
            make.edges.equalTo(self)
        }
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    @objc override func ssn_onDisplay(_ tableView: UIScrollView, model: AnyObject,atIndexPath indexPath: IndexPath, reused: Bool) {
        
        if let cellModel: CMSPageBrandListBannerCellModel = model as? CMSPageBrandListBannerCellModel{
            if let data = cellModel.data{
                _datas = data
                _layout.minimumLineSpacing = cellModel.border
                _layout.minimumInteritemSpacing = 0
                _layout.sectionInset = UIEdgeInsetsMake(cellModel.border, 15,15, 0)
                _layout.itemSize = CGSize(width: (ScreenWidth - cellModel.border * CGFloat((_datas.count - 1)) - 30) / CGFloat(_datas.count) , height: self.bounds.size.height - cellModel.border)
                _table.reloadData()
            }
        }
    }
    
    
    func numberOfSections(in collectionView: UICollectionView) -> Int {
        return 1
    }
    
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return _datas.count
    }
    
    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        let cell = collectionView.dequeueReusableCell(withReuseIdentifier: "CMSPagePageGegridBannerContentCell", for: indexPath) as! CMSPagePageGegridBannerContentCell
        
        let dataModel = _datas[indexPath.row]
        
        var category:ImageCategory = .banner
        if dataModel.dType == DataType.SKU {
            category = .product
        }
        if let imageUrl = dataModel.imageUrl {
            cell.imageView.mm_setImageWithURL(ImageURLFactory.URLSize512(imageUrl, category: category), placeholderImage: UIImage(named: "brand_placeholder"), contentMode: .scaleAspectFill)
        }else{
            cell.imageView.image = UIImage(named: "brand_placeholder")
        }
        
        cell.backgroundColor = UIColor.white
        cell.layer.cornerRadius = 4
        cell.layer.masksToBounds = true
        
        //埋点需要
        cell.track_visitId = dataModel.vid
        cell.track_media = dataModel.videoUrl
        return cell
    }
    
    func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        let dataModel = _datas[indexPath.row]
        Navigator.shared.dopen(dataModel.link)
    }
}

