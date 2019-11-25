//
//  CMSPageProductBannerCell.swift
//  MMDemoForLeslie_Swift4.0
//
//  Created by Leslie Zhang on 2018/3/26.
//  Copyright © 2018年 Leslie Zhang. All rights reserved.
//

import UIKit

class CMSPageProductBannerCell: UICollectionViewCell,UICollectionViewDelegate,UICollectionViewDataSource  {
    var layout: CarouselFlowLayout!
    var heroCollectionView: UICollectionView!
    var _datas = [[CMSPageDataModel]]()
    var curIndex:Int = 0
    var indexPath:IndexPath?
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        
        layout = CarouselFlowLayout()
        layout.sideItemScale = 1.0
        layout.sideItemAlpha = 1.0
        layout.spacingMode = .fixed(spacing: 5)
        layout.scrollDirection = .horizontal
        //        layout.sectionInset = UIEdgeInsetsMake(5, 5, 5, 5)
        layout.itemSize = CGSize(width: self.bounds.width - 30, height: self.bounds.height)
        
        heroCollectionView = UICollectionView(frame: CGRect.zero, collectionViewLayout: layout)
        heroCollectionView.dataSource = self
        heroCollectionView.delegate = self
        heroCollectionView.backgroundColor = UIColor.white
        heroCollectionView.alwaysBounceVertical = false
        heroCollectionView.bounces = false
        heroCollectionView.showsHorizontalScrollIndicator = false
        heroCollectionView.showsVerticalScrollIndicator = false
        heroCollectionView.register(ProductBannerVideoCell.self, forCellWithReuseIdentifier: "ProductBannerVideoCell")
        
        self.contentView.addSubview(heroCollectionView)

        heroCollectionView.snp.makeConstraints { (make) in
            make.edges.equalTo(self.contentView)
        }
        
       
        
    }
    
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    @objc override func ssn_onDisplay(_ tableView: UIScrollView, model: AnyObject,atIndexPath indexPath: IndexPath, reused: Bool) {
        self.indexPath = indexPath
        
        if reused {
            return
        }
        
        if let cellModel: CMSPageProductBannerCellModel = model as? CMSPageProductBannerCellModel {
            if let data = cellModel.data{
                _datas.removeAll()
                
                var index = 0
                for dateModel:CMSPageDataModel in data {
                    if dateModel.dType == DataType.BANNER{
                        var list = [CMSPageDataModel]()
                        list.append(dateModel)
                        _datas.append(list)
                        index = index + 1
                    }else if dateModel.dType == DataType.SKU{
                        if index <= _datas.count && index >= 1{
                            _datas[index - 1].append(dateModel)
                        }
                        
                    }
                }
                heroCollectionView.setContentOffset(CGPoint.zero, animated: false)
                heroCollectionView.reloadData()
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
        let cell = collectionView.dequeueReusableCell(withReuseIdentifier: "ProductBannerVideoCell", for: indexPath) as! ProductBannerVideoCell
        cell.type = .horizontal
        let datas = _datas[indexPath.row]
        let videoData = datas[0]
        let skuList = Array(datas[1..<datas.count])
        
        cell.videoData = videoData
        cell.skuList = skuList
        
        cell.backgroundColor = UIColor.white
        return cell
    }
    
    @objc func scrollViewDidEndDecelerating(_ scrollView: UIScrollView) {

        curIndex = Int((self.heroCollectionView.contentOffset.x + ( ScreenSize.width / 2 ) + 0.5 /*误差值*/ ) / ScreenSize.width )

        if let fetch = self.ssn_fetchs as? MMFetchsController<MMCellModel> {
            if let indexpath = self.indexPath,let cellModel = fetch.fetch[indexpath.row - 1] as? CMSPageTitleCellModel {
                cellModel.tipSelect = "\(curIndex + 1)"
                fetch.update(at: IndexPath.init(row: indexpath.row - 1, section: 0))
            }
        }
        
        let paths = heroCollectionView.indexPathsForVisibleItems

        var delegateWillFocus: PlayVideoDelegate?
        
        for path in paths {
            if let cell = heroCollectionView.cellForItem(at: path) as? ProductBannerVideoCell, cell.isVideo {
                if cell.isPlayerOutOfScreen(ratio: 0.3) /* assume not focusing */ {
                    VideoPlayManager.shared.unFocusVideoPlayer(delegate: cell)
                } else {
                    delegateWillFocus = cell
                }
            }
        }
        
        /* will do video play in here after all videos are unfocus */
        if let cell = delegateWillFocus {
            VideoPlayManager.shared.focusVideoPlayer(delegate: cell)
        }
    }
    
    func collectionView(_ collectionView: UICollectionView, willDisplay cell: UICollectionViewCell, forItemAt indexPath: IndexPath) {
        if let cell = cell as? ProductBannerVideoCell, cell.isVideo {
            VideoPlayManager.shared.focusVideoPlayer(delegate: cell as PlayVideoDelegate)
        }
    }

    func collectionView(_ collectionView: UICollectionView, didEndDisplaying cell: UICollectionViewCell, forItemAt indexPath: IndexPath) {
        if let cell = cell as? ProductBannerVideoCell, cell.isVideo {
            VideoPlayManager.shared.unFocusVideoPlayer(delegate: cell as PlayVideoDelegate)
        }
    }
}

class CMSPageProductBannerContentCell: UICollectionViewCell,UICollectionViewDelegate,UICollectionViewDataSource{
    var _layout:UICollectionViewFlowLayout!
    var _table:UICollectionView!
    var _datas = [CMSPageDataModel](){
        didSet{
            let category:ImageCategory = .banner
            if let imageUrl = _datas[0].imageUrl {
                topImageView.mm_setImageWithURL(ImageURLFactory.URLSize512(imageUrl, category: category), placeholderImage: UIImage(named: "brand_placeholder"), contentMode: .scaleAspectFill)
                topImageView.whenTapped {
                    Navigator.shared.dopen(self._datas[0].link)
                }
            }
            _imageDatas = Array(_datas[1..<_datas.count])
        }
    }
    var _imageDatas = [CMSPageDataModel](){
        didSet{
            _layout.itemSize = CGSize(width: (self.bounds.width - 2 * 15 - 15) / CGFloat(3), height: self.bounds.height - self.bounds.height * 0.5 - 2)
            _table.reloadData()
        }
    }
    
    lazy var topImageView:UIImageView = {
        let topImageView = UIImageView(image: UIImage(named: "brand_placeholder"))
        topImageView.isUserInteractionEnabled = true
        topImageView.layer.cornerRadius = 4.0
        topImageView.layer.masksToBounds = true
        return topImageView
    }()
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        
        self.addSubview(topImageView)
        
        topImageView.frame = CGRect(x: 0, y: 0, width: self.bounds.width, height: self.bounds.height * 0.5)
        
        _layout = UICollectionViewFlowLayout()
        _layout.minimumLineSpacing = 15
        _layout.minimumInteritemSpacing = 0
        _layout.scrollDirection = UICollectionViewScrollDirection.horizontal
        _layout.sectionInset = UIEdgeInsetsMake(0, 7.5,0, 7.5)
        
        _table = UICollectionView(frame: CGRect(x: 0, y: self.bounds.height * 0.5 + 2, width: self.bounds.width, height: self.bounds.height - self.bounds.height * 0.5 - 2), collectionViewLayout: _layout)
        _table.dataSource = self
        _table.delegate = self
        _table.backgroundColor = UIColor.white
        _table.alwaysBounceVertical = false
        _table.bounces = false
        _table.showsHorizontalScrollIndicator = false
        _table.showsVerticalScrollIndicator = false
        _table.register(CMSPageProductBannerSkuCell.self, forCellWithReuseIdentifier: "CMSPageProductBannerSkuCell")
        self.addSubview(_table)
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    func numberOfSections(in collectionView: UICollectionView) -> Int {
        return 1
    }
    
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return _imageDatas.count
    }
    
    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        
        let dataModel = _imageDatas[indexPath.row]
        
        var imageUrl: URL?
        let category: ImageCategory = dataModel.dType == DataType.SKU ? .product : .banner
        if let image = dataModel.imageUrl {
            imageUrl = ImageURLFactory.URLSize512(image, category: category)
        }

        let cell = collectionView.dequeueReusableCell(withReuseIdentifier: "CMSPageProductBannerSkuCell", for: indexPath) as! CMSPageProductBannerSkuCell
        
        if let url = imageUrl {
            cell.imageView.mm_setImageWithURL(ImageURLFactory.URLSize1000(url.absoluteString, category: category), placeholderImage: UIImage(named: "brand_placeholder"), contentMode: .scaleAspectFill)
        } else {
            cell.imageView.image = UIImage(named: "brand_placeholder")
        }
        
        if let style = dataModel.style {
            cell.priceLabel.attributedText = PriceHelper.fillPrice(style.priceSale, priceRetail: style.priceRetail, isSale: style.isOnSale() ? 1: 0,hasValidCoupon:false)
            cell.titleLabel.text = style.brandName
        } else {
            cell.titleLabel.text = ""
            cell.priceLabel.attributedText = NSMutableAttributedString(string: "")
        }
        cell.backgroundColor = UIColor.white
        
        //埋点需要
        cell.track_visitId = dataModel.vid
        cell.track_media = dataModel.videoUrl
        return cell
    }
    
    func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        let dataModel = _imageDatas[indexPath.row]
        
        let link = Navigator.mymm.website_product_skuId + String(dataModel.dId)
        Navigator.shared.dopen(link)
    }
    
    @objc override func ssn_onDisplay(_ tableView: UIScrollView, model: AnyObject,atIndexPath indexPath: IndexPath, reused: Bool) {
        if let cellModel = model as? CMSPageProductBannerVerticalCellModel {
            if let data = cellModel.data{
                _datas = data
            }
        }
    }
}

class CMSPageProductBannerSkuCell: UICollectionViewCell {
    
    lazy var imageView:UIImageView = {
        let imageView = UIImageView(image: UIImage(named: "brand_placeholder"))
        imageView.backgroundColor = UIColor.white
        return imageView
    }()
    
    lazy var titleLabel:UILabel = {
        let titleLabel = UILabel()
        titleLabel.font = UIFont.systemFont(ofSize: 14)
        titleLabel.textAlignment = .center
        return titleLabel
    }()
    
    lazy var priceLabel:UILabel = {
        let priceLabel = UILabel()
        priceLabel.font = UIFont.systemFont(ofSize: 12)
        priceLabel.textAlignment = .center
        return priceLabel
    }()
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        
        self.contentView.layer.borderColor = UIColor.secondary10().cgColor
        self.contentView.layer.borderWidth = 0.5
        self.contentView.layer.cornerRadius = 4
        self.contentView.layer.masksToBounds = true
        
        self.contentView.addSubview(imageView)
        self.contentView.addSubview(titleLabel)
        self.contentView.addSubview(priceLabel)
        
        imageView.snp.makeConstraints { (make) in
            make.left.right.equalTo(self.contentView)
            make.top.equalTo(self.contentView.snp.top)
            make.height.equalTo(self.contentView.frame.size.width * 1.164 - 5)
        }
        titleLabel.snp.makeConstraints { (make) in
            make.left.right.equalTo(self.contentView)
            make.bottom.equalTo(priceLabel.snp.top).offset(-2)
        }
        priceLabel.snp.makeConstraints { (make) in
            make.left.right.equalTo(self.contentView)
            make.bottom.equalTo(self.contentView).offset(-8)
        }
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    
}
