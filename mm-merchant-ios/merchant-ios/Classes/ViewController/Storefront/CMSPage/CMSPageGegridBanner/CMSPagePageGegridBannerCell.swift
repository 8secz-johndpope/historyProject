//
//  CMSPagePageGegridBannerCell.swift
//  MMDemoForLeslie_Swift4.0
//
//  Created by Leslie Zhang on 2018/3/26.
//  Copyright © 2018年 Leslie Zhang. All rights reserved.
//

import UIKit

class CMSPagePageGegridBannerCell: UICollectionViewCell,UICollectionViewDelegate,UICollectionViewDataSource{
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
        _layout.sectionInset = UIEdgeInsetsMake(0, 0,0, 0)
        
        _table = UICollectionView(frame: self.bounds, collectionViewLayout: _layout)
        _table.dataSource = self
        _table.delegate = self
        _table.backgroundColor = UIColor.clear
        _table.alwaysBounceVertical = false
        _table.bounces = false
        _table.showsHorizontalScrollIndicator = false
        _table.showsVerticalScrollIndicator = false
        _table.register(CMSPagePageGegridBannerContentCell.self, forCellWithReuseIdentifier: "CMSPagePageGegridBannerContentCell")
        _table.register(CMSPageGridBannerVideoCell.self, forCellWithReuseIdentifier: "CMSPageGridBannerVideoCell")
        
        self.contentView.addSubview(_table)
        _table.snp.makeConstraints { (make) in
            make.edges.equalTo(self.contentView)
        }
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    func numberOfSections(in collectionView: UICollectionView) -> Int {
        return 1
    }
    
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return _datas.count
    }

    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        let data = _datas[indexPath.row]
        
        var imageUrl: URL?
        if let image = data.imageUrl {
            imageUrl = ImageURLFactory.URLSizeOther(image, category: data.dType == DataType.SKU ? .product : .banner,width:0,isOriginalW:true)
        }
        
        let video = data.videoUrl
        if !video.isEmpty {
            let cell = collectionView.dequeueReusableCell(withReuseIdentifier: "CMSPageGridBannerVideoCell", for: indexPath) as! CMSPageGridBannerVideoCell
            cell.coverImage = imageUrl?.absoluteString
            cell.deeplink = data.link
            cell.videoUrl = video
            cell.track_visitId = data.vid
            cell.track_media = video
            
            let ratio = CGFloat(_datas.count)
            let playBtnSize = CGSize(width: cell.PlayButtonSize.width / ratio, height: cell.PlayButtonSize.height / ratio)
            cell.PlayButtonSize = playBtnSize
            
            let soundBtnSize = CGSize(width: cell.SoundButtonSize.width - (3 / (1/ratio)), height: cell.SoundButtonSize.height - (3 / (1/ratio)))
            cell.SoundButtonSize = soundBtnSize
            
            let fullscreenBtnSize = CGSize(width: cell.FullScreenButtonSize.width - (3 / (1/ratio)), height: cell.FullScreenButtonSize.height - (3 / (1/ratio)))
            cell.FullScreenButtonSize = fullscreenBtnSize
            
            return cell
        } else {
            let cell = collectionView.dequeueReusableCell(withReuseIdentifier: "CMSPagePageGegridBannerContentCell", for: indexPath) as! CMSPagePageGegridBannerContentCell
            cell.track_visitId = data.vid
            cell.track_media = ""
            if let imageUrl = imageUrl {
                cell.imageView.mm_setImageWithURL(imageUrl, placeholderImage: UIImage(named: "brand_placeholder"), contentMode: .scaleToFill)
            } else {
                cell.imageView.image = UIImage(named: "brand_placeholder")
            }
            
            return cell
        }
    }
    
    func collectionView(_ collectionView: UICollectionView, willDisplay cell: UICollectionViewCell, forItemAt indexPath: IndexPath) {
        if let cell = cell as? CMSPageGridBannerVideoCell {
            VideoPlayManager.shared.focusVideoPlayer(delegate: cell as PlayVideoDelegate)
        }
    }
    
    func collectionView(_ collectionView: UICollectionView, didEndDisplaying cell: UICollectionViewCell, forItemAt indexPath: IndexPath) {
        if let cell = cell as? CMSPageGridBannerVideoCell {
            VideoPlayManager.shared.unFocusVideoPlayer(delegate: cell as PlayVideoDelegate)
        }
    }
    
    func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        let dataModel = _datas[indexPath.row]
        Navigator.shared.dopen(dataModel.link)
    }
    
    @objc override func ssn_onDisplay(_ tableView: UIScrollView, model: AnyObject,atIndexPath indexPath: IndexPath, reused: Bool) {
        
        if let cellModel: CMSPagePageGegridBannerCellModel = model as? CMSPagePageGegridBannerCellModel{
            if let data = cellModel.data{
                _datas = data
                
                _layout.minimumLineSpacing = cellModel.border
                _layout.itemSize = CGSize(width: (self.bounds.width - cellModel.border * CGFloat(_datas.count - 1)) / CGFloat(_datas.count), height: self.bounds.size.height)
                
                _table.reloadData()
            }
        }
    }
}

class CMSPagePageGegridBannerContentCell: UICollectionViewCell {
    lazy var imageView:UIImageView = {
        let imageView = UIImageView()
        return imageView
    }()

    override init(frame: CGRect) {
        super.init(frame: frame)
        
        self.backgroundColor = .white
        
        self.addSubview(imageView)
        imageView.snp.makeConstraints { (make) in
            make.edges.equalTo(self)
        }
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}
