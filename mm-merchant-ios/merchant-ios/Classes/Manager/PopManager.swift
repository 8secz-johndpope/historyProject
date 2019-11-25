//
//  PostPopView.swift
//  MMDemoForLeslie
//
//  Created by Leslie Zhang on 2018/1/8.
//  Copyright © 2018年 Leslie Zhang. All rights reserved.
//

import UIKit

class PopManager {
    private init() {
        
    }
    static let sharedInstance = PopManager()
    
    func createGackgroundView(backgroundColor:UIColor,alpha:CGFloat,touch:Bool,startY:CGFloat = 0.0) -> UIView {
        
        let window = UIApplication.shared.keyWindow!
        
        let background = UIView()
        background.backgroundColor = UIColor.clear
        
        let blackView = UIView()
        if startY > 0 {
            background.frame = CGRect(x: window.bounds.origin.x, y: startY, width: window.bounds.size.width, height:  window.bounds.size.height)
            blackView.frame = CGRect(x: window.bounds.origin.x, y: 0, width: window.bounds.size.width, height:  window.bounds.size.height)
        }else {
            background.frame = window.bounds
            blackView.frame = window.bounds
            
        }
        
        
        blackView.backgroundColor = backgroundColor
        
        blackView.alpha = alpha
        
        window.addSubview(background)
        background.addSubview(blackView)
        
        if touch {
            blackView.whenTapped {
                background.removeFromSuperview()
            }
        }
        return background
    }
    
    func selectPost(selectedHashTag:String? = nil) {
        
        
        let background = createGackgroundView(backgroundColor: UIColor.black,alpha: 0.4, touch: true)
        
        
        let whiteView = UIImageView(frame: CGRect(x:0, y: ScreenHeight, width: ScreenWidth, height: ScreenHeight/3))
        whiteView.isUserInteractionEnabled = true
        whiteView.image = UIImage(named: "popup_bg")
        
        
        let leftButton = UIButton()
        leftButton.setTitle("多图", for: UIControlState.normal)
        leftButton.setImage(UIImage(named: "multi_ic"), for: UIControlState.normal)
        
        leftButton.sizeToFit()
        leftButton.titleLabel?.font = UIFont.systemFont(ofSize: 12)
        leftButton.setTitleColor(UIColor.black, for: UIControlState.normal)
        leftButton.setIconInTopWithSpacing(6)
        
        let rightButton = UIButton()
        rightButton.setTitle("拼图", for: UIControlState.normal)
        rightButton.setImage(UIImage(named: "puzzle_ic"), for: UIControlState.normal)
        
        rightButton.sizeToFit()
        rightButton.titleLabel?.font = UIFont.systemFont(ofSize: 12)
        rightButton.setTitleColor(UIColor.black, for: UIControlState.normal)
        rightButton.setIconInTopWithSpacing(6)
        
        
        let cancelButton = UIButton()
        cancelButton.setImage(UIImage(named: "popup_close"), for: UIControlState.normal)
        cancelButton.sizeToFit()
        
        cancelButton.whenTapped {
            UIView.animate(withDuration: 0.2, animations: {
                whiteView.frame = CGRect(x:0, y: ScreenHeight, width: ScreenWidth, height: ScreenHeight/3)
                
            }, completion: { (bool) in
                background.removeFromSuperview()
                
            })
        }
        
        leftButton.whenTapped {
            UIView.animate(withDuration: 0.2, animations: {
                whiteView.frame = CGRect(x:0, y: ScreenHeight, width: ScreenWidth, height: ScreenHeight/3)
                
            }, completion: { (bool) in
                background.removeFromSuperview()
                PushManager.sharedInstance.gotoPhotoCollage(selectStyleType: .Figure,selectedHashTag:selectedHashTag)
            })
        }
        
        rightButton.whenTapped {
            UIView.animate(withDuration: 0.2, animations: {
                whiteView.frame = CGRect(x:0, y: ScreenHeight, width: ScreenWidth, height: ScreenHeight/3)
                
            }, completion: { (bool) in
                background.removeFromSuperview()
                PushManager.sharedInstance.gotoPhotoCollage(selectStyleType: .Puzzle,selectedHashTag:selectedHashTag)
                
            })
            
        }
        
        background.addSubview(whiteView)
        whiteView.addSubview(leftButton)
        whiteView.addSubview(rightButton)
        whiteView.addSubview(cancelButton)
        leftButton.snp.makeConstraints { (make) in
            make.centerX.equalTo(whiteView).offset(-80)
            make.top.equalTo(50)
            make.height.equalTo(120)
        }
        
        rightButton.snp.makeConstraints { (make) in
            make.centerX.equalTo(whiteView).offset(80)
            make.top.equalTo(50)
            make.height.equalTo(120)
        }
        
        cancelButton.snp.makeConstraints { (make) in
            make.centerX.equalTo(whiteView)
            make.top.equalTo(leftButton.snp.bottom).offset(-5)
        }
        
        UIView.animate(withDuration: 0.3) {
            whiteView.frame = CGRect(x:0, y: ScreenHeight/3*2, width: ScreenWidth, height: ScreenHeight/3)
        }
    }
    
    
    func chooseTageType(brandCallback: @escaping ()->(),commodityCallback: @escaping ()->())  {
        let background = createGackgroundView(backgroundColor: UIColor.white,alpha: 0.9, touch: true)
        
        let leftButton = UIButton()
        leftButton.setTitle("品牌", for: UIControlState.normal)
        leftButton.setImage(UIImage(named: "brand_ic"), for: UIControlState.normal)
        leftButton.setTitleColor(UIColor.black, for: UIControlState.normal)
        
        leftButton.sizeToFit()
        leftButton.titleLabel?.font = UIFont.systemFont(ofSize: 12)
        leftButton.setTitleColor(UIColor.black, for: UIControlState.normal)
        leftButton.setIconInTopWithSpacing(6)
        
        let rightButton = UIButton()
        rightButton.setTitle("商品", for: UIControlState.normal)
        rightButton.setImage(UIImage(named: "product_ic"), for: UIControlState.normal)
        rightButton.setTitleColor(UIColor.black, for: UIControlState.normal)
        rightButton.sizeToFit()
        rightButton.titleLabel?.font = UIFont.systemFont(ofSize: 12)
        rightButton.setIconInTopWithSpacing(6)
        
        background.addSubview(leftButton)
        background.addSubview(rightButton)
        
        leftButton.snp.makeConstraints { (make) in
            make.centerX.equalTo(background).offset(-80)
            make.centerY.equalTo(background)
            make.height.equalTo(120)
        }
        
        rightButton.snp.makeConstraints { (make) in
            make.centerX.equalTo(background).offset(80)
            make.centerY.equalTo(background)
            make.height.equalTo(120)
        }
        
        leftButton.whenTapped {
            background.removeFromSuperview()
            brandCallback()
            
        }
        
        rightButton.whenTapped {
            background.removeFromSuperview()
            commodityCallback()
        }
        
    }
    func postUpImage(brandCallback: ()->())  {
        
        let window = UIApplication.shared.keyWindow!
        
        let greyView = UIView(frame: CGRect(x: 0, y: StartYPos, width: ScreenWidth, height: 48))
        greyView.backgroundColor = UIColor.gray
        window.addSubview(greyView)
        
        let imageView = UIImageView()
        imageView.backgroundColor = UIColor.red
        
        let label = UILabel()
        label.text = "正在发送..."
        
        let rectButton = UIButton()
        rectButton.backgroundColor = UIColor.yellow
        
        let cancelButton = UIButton()
        cancelButton.backgroundColor = UIColor.blue
        
        let boomLineVie = UIView()
        boomLineVie.backgroundColor = UIColor.red
        
        greyView.addSubview(imageView)
        greyView.addSubview(label)
        greyView.addSubview(rectButton)
        greyView.addSubview(cancelButton)
        greyView.addSubview(boomLineVie)
        
        cancelButton.isHidden = true
        boomLineVie.isHidden = true
        rectButton.isHidden = true
        
        
        imageView.snp.makeConstraints { (make) in
            make.left.equalTo(greyView).offset(10)
            make.centerY.equalTo(greyView)
            make.width.height.equalTo(32)
        }
        label.snp.makeConstraints { (make) in
            make.centerY.equalTo(greyView)
            make.left.equalTo(imageView.snp.right).offset(10)
        }
        cancelButton.snp.makeConstraints { (make) in
            make.right.equalTo(greyView).offset(-10)
            make.centerY.equalTo(greyView)
            make.width.height.equalTo(20)
            
        }
        rectButton.snp.makeConstraints { (make) in
            make.right.equalTo(cancelButton.snp.left).offset(-20)
            make.centerY.equalTo(greyView)
            make.width.height.equalTo(20)
            
        }
        boomLineVie.snp.makeConstraints { (make) in
            make.left.right.bottom.equalTo(greyView)
            make.height.equalTo(2)
        }
    }
    
    func flashSale(imageListIsEmpty:Bool,imageKey:String,sku:Sku,brandCallback: @escaping ()->(),commodityCallback: @escaping ()->())  {
        let background = createGackgroundView(backgroundColor: UIColor.black,alpha: 0.4, touch: true)
        
        let contentView = UIView()
        contentView.backgroundColor = .white
        contentView.layer.cornerRadius = 4
        contentView.layer.masksToBounds = true
        
        let skuImageView = UIImageView()
        skuImageView.layer.cornerRadius = 50
        skuImageView.layer.masksToBounds = true
        skuImageView.backgroundColor = .lightGray
        
        if imageListIsEmpty{
            skuImageView.mm_setImageWithURL(ImageURLFactory.URLSize1000(imageKey,category: .color), placeholderImage : UIImage(named: "holder"), contentMode: .scaleAspectFill)
        } else {
            skuImageView.mm_setImageWithURL(ImageURLFactory.URLSize256(imageKey, category: .product), placeholderImage : UIImage(named: "holder"), contentMode: .scaleAspectFill)
        }
        
        let label = UILabel()
        let str = String.localize("LB_CA_NEWBIEPRICE_PDP_POPUP")
        label.text = str.replacingOccurrences(of: "{colorname}", with: " \(sku.colorName) ").replacingOccurrences(of: "{size}", with: " \(sku.sizeName) ")
        label.font = UIFont.systemFont(ofSize: 14)
        label.textAlignment = .center
        label.numberOfLines = 0
        
        let lineView = UIView()
        lineView.backgroundColor = UIColor.secondary1()
        
        let leftButton = UIButton()
        leftButton.setTitle(String.localize("LB_TO_CANCEL"), for: .normal)
        leftButton.titleLabel?.font = UIFont.systemFont(ofSize: 14)
        leftButton.setTitleColor(UIColor(hexString: "#999999"), for: .normal)
        leftButton.backgroundColor = UIColor(hexString: "#F5F5F5")

        
        let rightButton = UIButton()
        rightButton.setTitle(String.localize("LB_OK"), for: .normal)
        rightButton.titleLabel?.font = UIFont.systemFont(ofSize: 14)
        rightButton.setTitleColor(.black, for: .normal)
        rightButton.backgroundColor = UIColor(hexString: "#F5F5F5")
        
        background.addSubview(contentView)
        background.addSubview(skuImageView)
        background.addSubview(label)
        background.addSubview(lineView)
        background.addSubview(leftButton)
        background.addSubview(rightButton)
        
        let contentViewWidth = ScreenWidth - 36 * 2

        contentView.snp.makeConstraints { (make) in
            make.center.equalTo(background)
            make.width.equalTo(contentViewWidth)
            make.height.equalTo(164)
        }
        skuImageView.snp.makeConstraints { (make) in
            make.centerX.equalTo(background)
            make.bottom.equalTo(contentView.snp.top).offset(50)
            make.width.height.equalTo(100)
        }
        label.snp.makeConstraints { (make) in
            make.centerX.equalTo(contentView)
            make.top.equalTo(skuImageView.snp.bottom).offset(8)
            make.left.equalTo(contentView).offset(15)
            make.right.equalTo(contentView).offset(-15)
        }
        lineView.snp.makeConstraints { (make) in
            make.height.equalTo(48)
            make.width.equalTo(1)
            make.centerX.equalTo(contentView)
            make.bottom.equalTo(contentView)
        }
        leftButton.snp.makeConstraints { (make) in
            make.left.bottom.equalTo(contentView)
            make.height.equalTo(48)
            make.width.equalTo(contentViewWidth/2 - 0.5)
        }
        rightButton.snp.makeConstraints { (make) in
            make.right.bottom.equalTo(contentView)
            make.height.equalTo(48)
            make.width.equalTo(leftButton)
        }
        
        leftButton.whenTapped {
            background.removeFromSuperview()
            brandCallback()
        }
        
        rightButton.whenTapped {
            background.removeFromSuperview()
            commodityCallback()
        }
    }
    
    func popupCoupon(_ coupon:PopupCoupon,couponCallback: @escaping ()->())  {
         let background = createGackgroundView(backgroundColor: UIColor.black,alpha: 0.4, touch: false)
        
        let bgImageView = UIImageView()
        bgImageView.isUserInteractionEnabled = true
        bgImageView.image = UIImage(named: "bg_black")
        
        let contentImageView = UIImageView()
        contentImageView.isUserInteractionEnabled = true
        contentImageView.image = UIImage(named: "white_bg")
        
        let titleLabel = UILabel()
        titleLabel.text = "您的优惠券已到账"
        titleLabel.textColor = UIColor(hexString: "#D3A36B")
        titleLabel.font = UIFont.boldSystemFont(ofSize: 16)
        
        let tableView = PopMangerCouponView()
        tableView.coupon = coupon.pageData
        
        let colseImageView = UIImageView()
        colseImageView.image = UIImage(named: "close_ic-2")
        colseImageView.sizeToFit()
        colseImageView.isUserInteractionEnabled = true
        
        let toCouponButton = UIButton()
        toCouponButton.backgroundColor = UIColor(hexString: "#D3A36B")
        toCouponButton.setTitle("查看我的优惠券", for: .normal)
        toCouponButton.setTitleColor(.white, for: .normal)
        toCouponButton.layer.cornerRadius = 20
        toCouponButton.titleLabel?.font = UIFont.systemFont(ofSize: 14)
        toCouponButton.layer.masksToBounds = true
        
        let bottomImgeView = UIImageView()
        bottomImgeView.image = UIImage(named: "coupon_popup")
        bottomImgeView.sizeToFit()
        if let count =  coupon.pageData?.count{
            if count > 3{
                bottomImgeView.isHidden = false
            } else {
                bottomImgeView.isHidden = true
            }
        }

        background.addSubview(bgImageView)
        bgImageView.addSubview(contentImageView)
        contentImageView.addSubview(titleLabel)
        contentImageView.addSubview(tableView)
        bgImageView.addSubview(toCouponButton)
        bgImageView.addSubview(bottomImgeView)
        background.addSubview(colseImageView)
        
        let bgImageViewWidth = ScreenWidth - 24 * 2
        let contentImageViewWidth = bgImageViewWidth - 36 * 2
        let tableViewWidth = contentImageViewWidth - 18 * 2
        
        bgImageView.snp.makeConstraints { (make) in
            make.center.equalTo(background)
            make.width.equalTo(bgImageViewWidth)
            make.height.equalTo(bgImageViewWidth * 1.33)
        }
        toCouponButton.snp.makeConstraints { (make) in
            make.bottom.equalTo(bgImageView).offset(-20)
            make.centerX.equalTo(bgImageView)
            make.width.equalTo(150)
            make.height.equalTo(40)
        }
        contentImageView.snp.makeConstraints { (make) in
            make.top.equalTo(bgImageView).offset(37)
            make.bottom.equalTo(toCouponButton.snp.top).offset(-20)
            make.width.equalTo(contentImageViewWidth)
            make.centerX.equalTo(bgImageView)
        }
        titleLabel.snp.makeConstraints { (make) in
           make.top.equalTo(contentImageView).offset(26)
           make.centerX.equalTo(contentImageView)
        }
        tableView.snp.makeConstraints { (make) in
            make.centerX.equalTo(contentImageView)
            make.top.equalTo(titleLabel.snp.bottom).offset(22)
            make.width.equalTo(tableViewWidth)
            make.bottom.equalTo(contentImageView).offset(-40)
        }
        bottomImgeView.snp.makeConstraints { (make) in
            make.centerX.equalTo(tableView)
            make.width.equalTo(tableView).offset(5)
            make.bottom.equalTo(tableView)
        }
        colseImageView.snp.makeConstraints { (make) in
            make.centerX.equalTo(background)
            make.top.equalTo(bgImageView.snp.bottom).offset(15)
        }
        colseImageView.whenTapped {
            background.removeFromSuperview()
        }
        toCouponButton.whenTapped {
            background.removeFromSuperview()
            couponCallback()
        }
    }
}



