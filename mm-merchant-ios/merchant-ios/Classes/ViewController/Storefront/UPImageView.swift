//
//  UpImageView.swift
//  merchant-ios
//
//  Created by Leslie Zhang on 2018/1/19.
//  Copyright © 2018年 WWE & CO. All rights reserved.
//

import UIKit

class UpImageView: UIView {
    var upImageViewCallBack:(() -> ())?
    var cancelUpImageViewCallBack:(() -> ())?
    var image:UIImage?{
        didSet{
            self.imageView.image = image
        }
    }
    lazy var imageView:UIImageView = {
        let imageView = UIImageView()
        imageView.contentMode = .scaleAspectFill
        imageView.clipsToBounds = true
        return imageView
    }()
    
    lazy var label:UILabel = {
        let label = UILabel()
        label.text = "正在发送..."
        label.font = UIFont.systemFont(ofSize: 14)
        return label
    }()
    
    lazy var rectButton:UIButton = {
        let rectButton = UIButton()
        rectButton.isHidden = true
        rectButton.setImage(UIImage(named: "refresh_ic"), for: UIControlState.normal)
        rectButton.sizeToFit()
        return rectButton
    }()
    
    lazy var cancelButton:UIButton = {
        let cancelButton = UIButton()
        cancelButton.isHidden = true
        cancelButton.setImage(UIImage(named: "close_ic-1"), for: UIControlState.normal)
        cancelButton.sizeToFit()
        return cancelButton
    }()
    
    lazy var boomLineView:UIView = {
        let boomLineView = UIView()
        boomLineView.backgroundColor = UIColor(hexString:"#ED2247")
        boomLineView.isHidden = true
        boomLineView.alpha = 0.3
        return boomLineView
    }()
    
    func showErro (erro:Bool){
        if erro {
            rectButton.isHidden = false
            cancelButton.isHidden = false
            boomLineView.isHidden = false
            label.text = "网络不给力我们会稍后重试"
            label.font = UIFont.systemFont(ofSize: 12)
            label.textColor = UIColor(hexString:"#6B6B6B")
            
            
        }else{
            rectButton.isHidden = true
            cancelButton.isHidden = true
            boomLineView.isHidden = true
            label.text = "正在发送..."
            label.font = UIFont.systemFont(ofSize: 14)
            label.textColor = UIColor.black
        }
        
    }
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        
        self.backgroundColor = UIColor(hexString:"#F5F5F5")
        
        addSubview(imageView)
        addSubview(label)
        addSubview(rectButton)
        addSubview(cancelButton)
        addSubview(boomLineView)
        
        rectButton.whenTapped {
            if let upImageViewCallBack = self.upImageViewCallBack{
                upImageViewCallBack()
            }
        }
        cancelButton.whenTapped {
            if let cancelUpImageViewCallBack = self.cancelUpImageViewCallBack{
                cancelUpImageViewCallBack()
            }
        }
        
        imageView.snp.makeConstraints { (make) in
            make.left.equalTo(self).offset(10)
            make.centerY.equalTo(self)
            make.width.height.equalTo(32)
        }
        label.snp.makeConstraints { (make) in
            make.centerY.equalTo(self)
            make.left.equalTo(imageView.snp.right).offset(10)
        }
        cancelButton.snp.makeConstraints { (make) in
            make.right.equalTo(self).offset(-10)
            make.centerY.equalTo(self)
            
        }
        rectButton.snp.makeConstraints { (make) in
            make.right.equalTo(cancelButton.snp.left).offset(-20)
            make.centerY.equalTo(self)
        }
        boomLineView.snp.makeConstraints { (make) in
            make.left.right.bottom.equalTo(self)
            make.height.equalTo(2)
        }
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
}

