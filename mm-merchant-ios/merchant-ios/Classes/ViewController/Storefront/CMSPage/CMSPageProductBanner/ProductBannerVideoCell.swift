//
//  ProductBannerVideoCell.swift
//  storefront-ios
//
//  Created by Kam on 18/4/2018.
//  Copyright © 2018 WWE & CO. All rights reserved.
//

import UIKit

class ProductBannerVideoCell: BannerVideoCell,UICollectionViewDelegate,UICollectionViewDataSource {
    open var isVideo: Bool = false
    private let MARGIN:CGFloat = 15
    private let SKUMARGIN:CGFloat = 8
    private var _table:UICollectionView!
    private let COLLECTIONVIEWMARGIN:CGFloat = 7
    public var type:CmsOrientationType = .vertical
    private var _layout:UICollectionViewFlowLayout!
    private var cellModel:CMSPageProductBannerVerticalCellModel?
    
    var videoData: CMSPageDataModel? {
        didSet {
            guard let vData = self.videoData else {
                return
            }
            var image: String = ""
            if let _image = vData.imageUrl {
                image = ImageURLFactory.URLSize1000(_image, category: vData.dType == DataType.SKU ? .product : .banner).absoluteString
            }
            self.setImageURL(image)
            
            isVideo = !vData.videoUrl.isEmpty
            if isVideo {
                showVideoComponent()
                self.setVideoURL(vData.videoUrl)
                self.setDeeplink(vData.link)
            } else {
                showCoverImage()
                self.featureImageView.round(4)
                self.featureImageView.isUserInteractionEnabled = true
                self.featureImageView.whenTapped { [weak self] in
                    if let strongSelf = self {
                        let width = strongSelf.featureImageView.frame.width
                        let height = strongSelf.featureImageView.frame.height
                        let ratio = width / ScreenWidth
                        let bounds = CGRect(x: 0, y: 0, width: width/ratio, height: height/ratio)
                        let imageView = ProductListImageView(frame: bounds)
                        imageView.image = strongSelf.featureImageView.image
                        Navigator.shared.sopen(vData.link, headView: imageView)
                    }
                }
            }
            self.track_visitId = vData.vid
            self.track_media = vData.videoUrl
        }
    }
    
    var skuList: [CMSPageDataModel]? {
        didSet {
            if let skuList = skuList{
                _imageDatas = skuList
            }
            
            // do here
        }
    }
    
    var _imageDatas = [CMSPageDataModel](){
        didSet{
            var padding:CGFloat = 0.0
            var margin:CGFloat = 0.0
            if let model = cellModel,model.padding >= 0 {
                padding = model.padding
                margin = MARGIN * 2
            }
            
             _layout.itemSize = CGSize(width: (self.bounds.width - margin - 2 * SKUMARGIN) / CGFloat(3), height: self.bounds.height - (self.bounds.width - padding * 2) * (9/16) - COLLECTIONVIEWMARGIN)
            _table.reloadData()
        }
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        self.bannerType = .productBanner
        
        let _frame = CGRect(x: 0, y: 0, width: frame.size.width, height: frame.size.width * (9/16))
        
        self.playerLayer?.view.frame = _frame
        self.overlayVideoView.frame = _frame
        self.featureImageView.frame = _frame
        
        _layout = UICollectionViewFlowLayout()
        _layout.minimumLineSpacing = SKUMARGIN
        _layout.minimumInteritemSpacing = 0
        _layout.scrollDirection = UICollectionViewScrollDirection.horizontal
        _layout.sectionInset = UIEdgeInsetsMake(0, 0, 0, 0)
        
        _table = UICollectionView(frame: CGRect(x: 0, y: _frame.size.height + COLLECTIONVIEWMARGIN, width: self.bounds.width, height: self.bounds.height - _frame.size.height - COLLECTIONVIEWMARGIN), collectionViewLayout: _layout)
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
            cell.imageView.mm_setImageWithURL(ImageURLFactory.URLSize512(url.absoluteString, category: category), placeholderImage: UIImage(named: "brand_placeholder"), contentMode: .scaleAspectFill)
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
            self.cellModel = cellModel
            if let data = cellModel.data{
                videoData = data[0]
                _imageDatas = Array(data[1..<data.count])
                
                var padding:CGFloat = 0.0
                if cellModel.padding >= 0 {
                   padding = cellModel.padding
                }
                let _frame = CGRect(x: padding, y: 0, width: frame.size.width - padding * 2, height: (frame.size.width - padding * 2) * (9/16))
                
                
                self.playerLayer?.view.frame = _frame
                self.overlayVideoView.frame = _frame
                self.featureImageView.frame = _frame
                self.padding = padding
                self.layoutSubviews()

                _table.frame =  CGRect(x: MARGIN, y:_frame.size.height + COLLECTIONVIEWMARGIN, width: self.bounds.width - MARGIN * 2 , height: self.bounds.height - _frame.size.height - COLLECTIONVIEWMARGIN)
            }
        }
    }
}
