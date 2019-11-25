//
//  PopMangerCouponCell.swift
//  storefront-ios
//
//  Created by Leslie Zhang on 2018/5/30.
//  Copyright © 2018年 WWE & CO. All rights reserved.
//

import UIKit
import YYText

class PopMangerCouponView: UIView,UITableViewDelegate,UITableViewDataSource {
    var selectTap: ((Int) -> Void)?
    var coupon:[Coupon]?{
        didSet {
            if let _ = coupon{
                tableView.reloadData()
            }
        }
    }
    
    lazy var tableView:UITableView = {
        let tableView = UITableView.init(frame: self.frame)
        tableView.delegate = self
        tableView.dataSource = self
        tableView.estimatedRowHeight = 32
        tableView.rowHeight = UITableViewAutomaticDimension
        tableView.backgroundColor = UIColor.white
        tableView.bounces = false
        tableView.separatorStyle = UITableViewCellSeparatorStyle.none
        tableView.register(PopMangerCouponViewCell.self, forCellReuseIdentifier: "PopMangerCouponViewCell")
        return tableView
    }()
    
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        self.addSubview(tableView)
        
        tableView.snp.makeConstraints { (make) in
            make.edges.equalTo(self)
        }
    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        if let coupon = coupon{
            return coupon.count
        }
        return 0
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        if let cell = tableView.dequeueReusableCell(withIdentifier: "PopMangerCouponViewCell", for: indexPath) as? PopMangerCouponViewCell{
            if let coupon = coupon {
                cell.coupon = coupon[indexPath.row]
            }
            return cell
        }
        return UITableViewCell()
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        return 60
    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        if let selectTap = selectTap {
            selectTap(indexPath.row)
        }
    }
    
}

class PopMangerCouponViewCell: UITableViewCell {
    var coupon:Coupon?{
        didSet {
            if let model = coupon{
                titleLabel.text = model.couponName
                let attributedString:NSMutableAttributedString = NSMutableAttributedString.init(string: "￥\(Int(model.couponAmount))")
//                attributedString.yy_setFont(UIFont.systemFont(ofSize: 12), range: (NSMakeRange(1, 1))

                    attributedString.yy_setFont(UIFont.systemFont(ofSize: 12), range: NSMakeRange(0, 1))
                attributedString.yy_setFont(UIFont.systemFont(ofSize: 15), range: NSMakeRange(1, attributedString.length - 1))
                attributedString.yy_setColor(UIColor(hexString: "#D3A36B"), range: NSMakeRange(0, attributedString.length))
                    priceLabel.attributedText = attributedString
                    contentLabel.text = "满￥\(Int(model.minimumSpendAmount))可用"
            }
        }
    }
    
    lazy var bgImageView:UIImageView = {
        let bgImageView = UIImageView()
        bgImageView.image = UIImage(named: "toCoupon_bg")
        return bgImageView
    }()
    lazy var titleLabel:UILabel = {
        let  titleLabel = UILabel()
        titleLabel.font = UIFont.systemFont(ofSize: 14)
        return titleLabel
    }()
    lazy var contentLabel:UILabel = {
        let  contentLabel = UILabel()
        contentLabel.font = UIFont.systemFont(ofSize: 12)
        contentLabel.textColor = UIColor.secondary17()
        return contentLabel
    }()
    lazy var priceLabel:YYLabel = {
        let  priceLabel = YYLabel()
        priceLabel.textColor = UIColor(hexString: "#D3A36B")
        return priceLabel
    }()
    
    
    override init(style: UITableViewCellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)
        
        self.selectionStyle = .none
        
        self.contentView.addSubview(bgImageView)
        self.contentView.addSubview(titleLabel)
        self.contentView.addSubview(contentLabel)
        self.contentView.addSubview(priceLabel)
        
        bgImageView.snp.makeConstraints { (make) in
            make.left.right.top.equalTo(self.contentView)
            make.bottom.equalTo(self.contentView).offset(-10)
        }
        titleLabel.snp.makeConstraints { (make) in
            make.top.equalTo(self.contentView).offset(9)
            make.width.equalTo(self.frame.width * 0.35)
            make.left.equalTo(17)
        }
        contentLabel.snp.makeConstraints { (make) in
            make.top.equalTo(titleLabel.snp.bottom).offset(3)
            make.left.equalTo(titleLabel)
        }
        priceLabel.snp.makeConstraints { (make) in
            make.centerY.equalTo(27)
            //            let centerX = self.frame.size.width * 0.58 + (self.frame.size.width - self.frame.size.width * 0.58)/2
            make.centerX.equalTo(self).offset(self.frame.width * 0.2)
        }
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}
