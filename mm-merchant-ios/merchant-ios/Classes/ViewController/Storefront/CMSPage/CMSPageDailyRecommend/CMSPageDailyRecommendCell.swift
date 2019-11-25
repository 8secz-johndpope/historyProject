//
//  CMSPageDailyRecommendCell.swift
//  storefront-ios
//
//  Created by Leslie Zhang on 2018/7/17.
//  Copyright © 2018年 WWE & CO. All rights reserved.
//

import UIKit

class CMSPageDailyRecommendCell: UICollectionViewCell,UICollectionViewDelegate,UICollectionViewDataSource {
    private var _imageDatas = [CMSPageDataModel]()
    private var cellModel: CMSPageDailyRecommendCellModel?
    private var link:String?
    
    //MARK: - init
    override init(frame: CGRect) {
        super.init(frame: frame)
        
        self.backgroundColor = UIColor.primary2()
        
        self.addSubview(titleLabel)
        self.addSubview(collectionView)
        self.addSubview(boottomImageView)
    }
    
    //MARK: - UICollectionViewDataSource
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return _imageDatas.count
    }
    
    //MARK: - UICollectionViewDelegate
    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        let dataModel = _imageDatas[indexPath.row]
        
        var imageUrl: URL?
        let category: ImageCategory = dataModel.dType == DataType.SKU ? .product : .banner
        if let image = dataModel.imageUrl {
            imageUrl = ImageURLFactory.URLSize512(image, category: category)
        }
        
        if let cell = collectionView.dequeueReusableCell(withReuseIdentifier: "CMSPageDailyRecommendSkuCell", for: indexPath) as? CMSPageDailyRecommendSkuCell {
            
            if let url = imageUrl {
                cell.imageView.mm_setImageWithURL(ImageURLFactory.URLSize512(url.absoluteString, category: category), placeholderImage: UIImage(named: "brand_placeholder"), contentMode: .scaleAspectFill)
                
            } else {
                cell.imageView.image = UIImage(named: "brand_placeholder")
            }
            
            if let style = dataModel.style {
                cell.brandNameLabel.text = style.brandName
                var num = String.localize("LB_CA_TRENDING")
                if style.isOnSale() {
                    var price =  (style.priceSale / style.priceRetail) * 10
                    if price < 0.1 {
                        price = 0.1
                    } else if price > 9.9 && price < 1 {
                        price = 9.9
                    }
                    num = String(format: "%.1f", price)
                    if num == "10.0" {
                        num = String.localize("LB_CA_TRENDING")
                    } else {
                        num =  String.localize("LB_CA_COUPON_DISCOUNT_PERCENTAGE").replacingOccurrences(of: "{0}", with: num)
                    }
                    if style.priceSale == 0 {
                        num = String.localize("LB_CA_TRENDING")
                    }
                }
                cell.saleButton.setTitle(num, for: .normal)
            } else {
                cell.brandNameLabel.text = ""
//                cell.contentLabel.text = ""
            }
            cell.backgroundColor = UIColor.white
                        
            //埋点需要
            cell.track_visitId = dataModel.vid
            cell.track_media = dataModel.videoUrl
            
            return cell
        }
        
        return UICollectionViewCell()
    }
    
    func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        let dataModel = _imageDatas[indexPath.row]
        
        Navigator.shared.dopen(dataModel.link)
    }
    
    //MARK: - event response
    @objc func touchBoottomImageView() {
        if let link = link {
            Navigator.shared.dopen(link)
        }
    }
    
    //MARK: - private methods
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    override func ssn_onDisplay(_ tableView: UIScrollView, model: AnyObject, atIndexPath indexPath: IndexPath, reused: Bool) {
        if let cellModel: CMSPageDailyRecommendCellModel = model as? CMSPageDailyRecommendCellModel {
            
            self.cellModel = cellModel
            
            
            if let recommends = cellModel.recommends,recommends.count > 0 {
                let index = random(0, to: recommends.count - 1)
                let comsModel = recommends[index]
                
                titleLabel.text = comsModel.title
                titleLabel.sizeToFit()
                
                if let recommendLinks = cellModel.recommendLinks,recommendLinks.count > 0 {
                    self.link = recommendLinks[index]
                }
                
                if let data = comsModel.data,data.count > 0 {
                    _imageDatas = data
                    collectionView.reloadData()
                }
            }
  
        }
    }
    
   private func random(_ from: Int, to: Int) -> Int {
        let _to = to + 1
        guard _to > from else {
            assertionFailure("Can not generate negative random numbers")
            return 0
        }
        return Int(arc4random_uniform(UInt32(_to - from)) + UInt32(from))
    }
    
    //MARK: - lazy
    lazy private var layout:UICollectionViewLayout = {
        let layout = UICollectionViewFlowLayout()
        layout.minimumLineSpacing = 8
        layout.minimumInteritemSpacing = 0
        layout.scrollDirection = UICollectionViewScrollDirection.vertical
        layout.itemSize = CGSize(width: (self.bounds.width - 30 - 2 * 8) / CGFloat(3), height: (self.bounds.height - 60 - 48) / 2 - 4)
        return layout
    }()
    lazy private var collectionView:UICollectionView = {
        let collectionView = UICollectionView(frame: CGRect(x: 15, y: 48, width: self.bounds.width - 30 , height: self.bounds.height - 60 - 48 ), collectionViewLayout: layout)
        collectionView.dataSource = self
        collectionView.delegate = self
        collectionView.backgroundColor = UIColor(hexString: "#f5f5f5")
        collectionView.alwaysBounceVertical = false
        collectionView.bounces = false
        collectionView.showsHorizontalScrollIndicator = false
        collectionView.showsVerticalScrollIndicator = false
        collectionView.register(CMSPageDailyRecommendSkuCell.self, forCellWithReuseIdentifier: "CMSPageDailyRecommendSkuCell")
        return collectionView
    }()
    lazy private var boottomImageView:UIImageView = {
        let boottomImageView = UIImageView()
        boottomImageView.image = UIImage.init(named: "dailyrecommend_more_button_bg")
        boottomImageView.sizeToFit()
        boottomImageView.frame = CGRect.init(x: (self.bounds.width - boottomImageView.width) / 2, y: (self.bounds.height - 60) + (60 - boottomImageView.height) / 2, width: boottomImageView.width, height: boottomImageView.height)
        let tapGesture = UITapGestureRecognizer()
        boottomImageView.isUserInteractionEnabled = true
        tapGesture.addTarget(self, action: #selector(touchBoottomImageView))
        boottomImageView.addGestureRecognizer(tapGesture)
        return boottomImageView
    }()
    lazy private var titleLabel:UILabel = {
        let titleLabel = UILabel()
        titleLabel.font = UIFont.boldSystemFont(ofSize: 18)
        titleLabel.sizeToFit()
        titleLabel.frame = CGRect.init(x: 18, y: 14, width: titleLabel.width, height: titleLabel.height)
        return titleLabel
    }()
}

class CMSPageDailyRecommendSkuCell: UICollectionViewCell {

    //MARK: - init
    override init(frame: CGRect) {
        super.init(frame: frame)

        self.layer.cornerRadius = 4
        self.layer.masksToBounds = true
        self.contentView.backgroundColor = .white
        
        self.contentView.addSubview(imageView)
        self.contentView.addSubview(brandNameLabel)
        self.contentView.addSubview(saleButton)
        
        imageView.snp.makeConstraints { (make) in
            make.left.equalTo(self.contentView).offset(6)
            make.right.equalTo(self.contentView).offset(-6)
            make.top.equalTo(self.contentView.snp.top).offset(6)
            make.height.equalTo((self.contentView.frame.size.width - 12) / 3 * 4)
        }
        brandNameLabel.snp.makeConstraints { (make) in
            make.left.right.equalTo(imageView)
            make.bottom.equalTo(saleButton.snp.top).offset(-8)
        }
        saleButton.snp.makeConstraints { (make) in
            make.centerX.equalTo(self.contentView)
            make.bottom.equalTo(self.contentView).offset(-10)
            make.width.equalTo(60)
            make.height.equalTo(22)
        }
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    //MARK: - lazy
    lazy var imageView:UIImageView = {
        let imageView = UIImageView(image: UIImage(named: "brand_placeholder"))
        imageView.backgroundColor = UIColor.white
        return imageView
    }()
    lazy var brandNameLabel:UILabel = {
        let brandNameLabel = UILabel()
        brandNameLabel.font = UIFont.systemFont(ofSize: 12)
        brandNameLabel.textAlignment = .center
        brandNameLabel.textColor = UIColor.secondary15()
        return brandNameLabel
    }()
    lazy var saleButton:UIButton = {
        let saleButton = UIButton()
        saleButton.backgroundColor = UIColor(hexString: "#EB1647")
        saleButton.layer.cornerRadius = 2
        saleButton.layer.masksToBounds = true
        saleButton.setTitleColor(.white, for: .normal)
        saleButton.titleLabel?.font = UIFont.boldSystemFont(ofSize: 12)
        saleButton.isUserInteractionEnabled = false
        return saleButton
    }()
}
