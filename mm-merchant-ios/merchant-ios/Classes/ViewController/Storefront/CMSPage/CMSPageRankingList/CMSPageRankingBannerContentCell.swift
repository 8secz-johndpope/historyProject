//
//  CMSPageRankingBannerContentCell.swift
//  storefront-ios
//
//  Created by Leslie Zhang on 2018/5/28.
//  Copyright © 2018年 WWE & CO. All rights reserved.
//

import UIKit

class CMSPageRankingBannerContentCell: UICollectionViewCell,UITableViewDelegate,UITableViewDataSource {
    var data:CMSPageDataModel? {
        didSet {
            if let model = data{
                
                if let image = model.imageUrl {
                    let imageUrl = ImageURLFactory.URLSize1000(image, category: .banner)
                    backImageView.mm_setImageWithURL(imageUrl, placeholderImage: UIImage(named: "placeholder"))
                }
          
                titleLabel.text = model.bannerName
                
                tableView.reloadData()
            }
        }
    }
    lazy var titleLabel:UILabel = {
        let titleLabel = UILabel()
        titleLabel.textColor = .white
        titleLabel.font = UIFont.systemFont(ofSize: 20)
        return titleLabel
    }()
    
    lazy var tableView:UITableView = {
        let width = self.frame.size.width - 14 * 2
        let height = self.frame.size.height - 60 - 14
        let tableView = UITableView.init(frame: CGRect.init(x: (self.frame.size.width - width) / 2, y: 60, width: width, height: height))
        tableView.delegate = self
        tableView.dataSource = self
        tableView.estimatedRowHeight = 32
        tableView.rowHeight = UITableViewAutomaticDimension
        tableView.backgroundColor = UIColor.white
        tableView.bounces = false
        tableView.register(CMSPageRankingBannerContentSkuCell.self, forCellReuseIdentifier: "CMSPageRankingBannerContentSkuCell")
        tableView.layer.cornerRadius = 4
        tableView.layer.masksToBounds = true
        tableView.separatorStyle = .none
        tableView.isScrollEnabled = false
        return tableView
    }()
    var tableHeight:CGFloat = 0.0
    
    lazy var backImageView:UIImageView = {
        let backImageView = UIImageView()
        backImageView.isUserInteractionEnabled = true
        return backImageView
    }()
    
    lazy var blackView:UIView = {
        let blackView = UIView()
        blackView.backgroundColor = .black
        blackView.alpha = 0.1
        return blackView
    }()
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        
        self.contentView.addSubview(backImageView)
        self.contentView.addSubview(blackView)
        self.contentView.addSubview(tableView)
        self.contentView.addSubview(titleLabel)
        
        tableHeight = tableView.frame.size.height
        
        backImageView.snp.makeConstraints { (make) in
            make.edges.equalTo(self.contentView)
        }
        blackView.snp.makeConstraints { (make) in
            make.edges.equalTo(self.contentView)
        }
        titleLabel.snp.makeConstraints { (make) in
            make.centerY.equalTo(30)
            make.centerX.equalTo(self.contentView)
        }
       
        
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    func numberOfSections(in tableView: UITableView) -> Int {
        return 1
    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        if let count = data?.skuDatas.count{
            return count
        }
        return 0
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        if let cell = tableView.dequeueReusableCell(withIdentifier: "CMSPageRankingBannerContentSkuCell", for: indexPath) as? CMSPageRankingBannerContentSkuCell {
            if let data = data?.skuDatas[indexPath.row]{
                cell.data = data
            }
            
            return cell
        }
        return UITableViewCell()
    }
    
    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        if let count = data?.skuDatas.count{
            return (tableHeight - 38) / CGFloat(count)
        }
        return 0
    }
    
    //    func tableView(_ tableView: UITableView, viewForHeaderInSection section: Int) -> UIView? {
    //
    //    }
    func tableView(_ tableView: UITableView, heightForFooterInSection section: Int) -> CGFloat {
        return 38
    }
    
    func tableView(_ tableView: UITableView, viewForFooterInSection section: Int) -> UIView? {
        let view = UIView.init(frame: CGRect.init(x: 0, y: 0, width: self.frame.size.width - 14 * 2, height: 38))
        view.backgroundColor = .white
        let tapGesture = UITapGestureRecognizer()
        tapGesture.addTarget(self, action: #selector(tapFooterView))
        view.addGestureRecognizer(tapGesture)
        
        let label = UILabel()
        label.textColor = UIColor.secondary17()
        label.font = UIFont.systemFont(ofSize: 12)
        label.text = String.localize("LB_CA_POST_MORE_TOPIC")
        view.addSubview(label)
        
        let arrowImageView = UIImageView()
        arrowImageView.image = UIImage.init(named: "arrows_ic")
        arrowImageView.sizeToFit()
        view.addSubview(arrowImageView)
        
        label.snp.makeConstraints { (make) in
            make.center.equalTo(view)
        }
        arrowImageView.snp.makeConstraints { (make) in
            make.centerY.equalTo(view)
            make.left.equalTo(label.snp.right).offset(4)
        }
        return view
    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        if let data = data?.skuDatas[indexPath.row]{
            Navigator.shared.dopen(data.link)
        }
    }
    
    @objc func tapFooterView()  {
        if let data = data{
             Navigator.shared.dopen(data.link)
        
        }
    }
}

class CMSPageRankingBannerContentSkuCell: UITableViewCell {
    var data:CMSPageDataModel?{
        didSet{
            if let image = data?.imageUrl {
                skuImageView.mm_setImageWithURL(ImageURLFactory.URLSize512(image, category: .product), placeholderImage: UIImage(named: "brand_placeholder"), contentMode: .scaleAspectFit)
          
            }else {
                skuImageView.image = UIImage(named: "brand_placeholder")
            }
            
            if let style = data?.style{
                skuNameLabel.text = style.skuName
                skuPriceLabel.attributedText = PriceHelper.fillPrice(style.priceSale, priceRetail: style.priceRetail, isSale: style.isOnSale() ? 1: 0,hasValidCoupon:false,salePriceFontSize:12,sameColor:true)
            }else {
                skuNameLabel.text = ""
                skuPriceLabel.text = ""
            }
        }
    }
    
    lazy var skuImageView:UIImageView = {
        let skuImageView = UIImageView()
        skuImageView.layer.cornerRadius = 2
        skuImageView.layer.masksToBounds = true
        skuImageView.layer.borderColor = UIColor.secondary10().cgColor
        skuImageView.layer.borderWidth = 0.5
        return skuImageView
    }()
    
    lazy var skuNameLabel:UILabel = {
        let skuNameLabel = UILabel()
        skuNameLabel.font = UIFont.systemFont(ofSize: 13)
        return skuNameLabel
    }()
    
    lazy var skuPriceLabel:UILabel = {
        let skuPriceLabel = UILabel()
        return skuPriceLabel
    }()
    
    lazy var lineView:UIView = {
        let lineView = UIView()
        lineView.backgroundColor = UIColor.primary2()
        return lineView
    }()
    
    lazy var bagImageView:UIImageView = {
        let bagImageView = UIImageView()
        bagImageView.image = UIImage(named: "bag_ic")
        bagImageView.sizeToFit()
        return bagImageView
    }()
    
    override init(style: UITableViewCellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)
        
        self.selectionStyle = .none
        
        self.backgroundColor = .white
        
        self.contentView.addSubview(skuImageView)
        self.contentView.addSubview(skuNameLabel)
        self.contentView.addSubview(skuPriceLabel)
        self.contentView.addSubview(lineView)
        self.contentView.addSubview(bagImageView)
        
        skuImageView.snp.makeConstraints { (make) in
            make.centerY.equalTo(self.contentView)
            make.width.height.equalTo(44)
            make.left.equalTo(14)
        }
        skuNameLabel.snp.makeConstraints { (make) in
            make.top.equalTo(self.contentView).offset(16)
            make.left.equalTo(skuImageView.snp.right).offset(14)
            make.right.equalTo(lineView)
        }
        skuPriceLabel.snp.makeConstraints { (make) in
            make.top.equalTo(skuNameLabel.snp.bottom).offset(2)
            make.left.equalTo(skuNameLabel)
        }
        lineView.snp.makeConstraints { (make) in
            make.bottom.equalTo(self.contentView)
            make.left.equalTo(self.contentView).offset(14)
            make.right.equalTo(self.contentView).offset(-14)
            make.height.equalTo(1)
        }
        bagImageView.snp.makeConstraints { (make) in
            make.right.equalTo(lineView)
            make.bottom.equalTo(skuImageView)
        }
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}
