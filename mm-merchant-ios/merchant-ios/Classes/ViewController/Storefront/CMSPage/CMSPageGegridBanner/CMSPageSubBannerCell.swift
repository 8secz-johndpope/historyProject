//
//  CMSPageSubBannerCell.swift
//  MMDemoForLeslie_Swift4.0
//
//  Created by Leslie Zhang on 2018/3/26.
//  Copyright © 2018年 Leslie Zhang. All rights reserved.
//

import UIKit
import Kingfisher

class CMSPageSubBannerCell: UICollectionViewCell,UICollectionViewDelegate,UICollectionViewDataSource{
    var _layout:UICollectionViewFlowLayout!
    var _table:UICollectionView!
    var _datas = [CMSPageDataModel]()
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        
        self.backgroundColor = UIColor.white
        
        _layout = UICollectionViewFlowLayout()
        _layout.minimumLineSpacing = 0
        _layout.minimumInteritemSpacing = 0
        _layout.scrollDirection = UICollectionViewScrollDirection.horizontal
        _layout.sectionInset = UIEdgeInsetsMake(0, 0, 0, 0)
        
        _table = UICollectionView(frame: self.bounds, collectionViewLayout: _layout)
        _table.dataSource = self
        _table.delegate = self
        _table.backgroundColor = UIColor.white
        _table.alwaysBounceVertical = false
        _table.bounces = false
        _table.showsHorizontalScrollIndicator = false
        _table.showsVerticalScrollIndicator = false
        _table.register(CMSPageSubBannerContentCell.self, forCellWithReuseIdentifier: "CMSPageSubBannerContentCell")
        self.contentView.addSubview(_table)
        _table.snp.makeConstraints { (make) in
            make.edges.equalTo(self.contentView)
        }
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    @objc override func ssn_onDisplay(_ tableView: UIScrollView, model: AnyObject,atIndexPath indexPath: IndexPath, reused: Bool) {
        let cellModel: CMSPageSubBannerCellModel = model as! CMSPageSubBannerCellModel
        if let data = cellModel.data{
            _datas = data
            _layout.itemSize = CGSize(width: self.bounds.width / CGFloat(_datas.count), height: self.bounds.size.height)
            _table.reloadData()
        }
    }
    
    func numberOfSections(in collectionView: UICollectionView) -> Int {
        return 1
    }
    
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return _datas.count
    }
    
    
    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        let cell = collectionView.dequeueReusableCell(withReuseIdentifier: "CMSPageSubBannerContentCell", for: indexPath) as! CMSPageSubBannerContentCell
        
        let dataModel = _datas[indexPath.row]
        
        var category:ImageCategory = .banner
        if dataModel.dType == DataType.SKU {
            category = .product
        }
        
        if let imageUrl = dataModel.imageUrl {
            cell.imageView.mm_setImageWithURL(ImageURLFactory.URLSize512(imageUrl, category: category), placeholderImage: UIImage(named: "brand_placeholder"), contentMode: .scaleAspectFit)
        }else{
            cell.imageView.image = UIImage(named: "brand_placeholder")
        }
        
        //埋点需要
        cell.track_visitId = dataModel.vid
        cell.track_media = dataModel.videoUrl
        return cell
    }
}

class CMSPageSubBannerContentCell: UICollectionViewCell {
    lazy var imageView:UIImageView = {
        let imageView = UIImageView(frame: self.bounds)
        return imageView
    }()
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        
        self.addSubview(imageView)
    }
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}
