//
//  RootLoginView.swift
//  merchant-ios
//
//  Created by Leslie Zhang on 2017/12/14.
//  Copyright © 2017年 WWE & CO. All rights reserved.
//

import UIKit

class RootLoginView: UIView {
    //MARK: - Lazy
    lazy var bgImageView:UIImageView = {
        let bgImageView = UIImageView(frame: self.bounds)
        bgImageView.backgroundColor = UIColor.clear
        bgImageView.image = UIImage(named: "exclusive-bg")
        return bgImageView
    }()
    lazy var blackBgImageView:UIImageView = {
        let blackBgImageView = UIImageView(frame: self.bounds)
        blackBgImageView.backgroundColor = UIColor.clear
        blackBgImageView.image = UIImage(named: "cover-login")
        blackBgImageView.contentMode = .scaleAspectFill
        return blackBgImageView
    }()
    lazy var loginImageView:UIImageView = {
        let loginImageView = UIImageView()
        loginImageView.backgroundColor = UIColor.clear
        loginImageView.image = UIImage(named: "login_bg_logo")
        loginImageView.contentMode = .scaleAspectFill
        loginImageView.sizeToFit()
        loginImageView.isUserInteractionEnabled = true
        return loginImageView
    }()
    lazy var signButton:UIButton = {
        let signButton = UIButton()
        signButton.layer.cornerRadius = 4
        signButton.layer.masksToBounds = true
        signButton.backgroundColor = UIColor.black
        signButton.setTitle("新用户注册", for: UIControlState.normal)
        signButton.setTitleColor(UIColor.white, for: UIControlState.normal)
        signButton.titleLabel?.font = UIFont.systemFont(ofSize: 16)
        signButton.isHidden = true
        return signButton
    }()
    lazy var loginButton:UIButton = {
        let loginButton = UIButton()
        loginButton.setImage(UIImage.init(named: "login"), for: UIControlState.normal)
        loginButton.sizeToFit()
        return loginButton
    }()
    lazy var wechatButton:UIButton = {
        let wechatButton = UIButton()
        wechatButton.setImage(UIImage.init(named: "wechatLogin"), for: UIControlState.normal)
        wechatButton.sizeToFit()
        return wechatButton
    }()
    lazy var visitButton:UIButton = {
        let visitButton = UIButton()
        visitButton.setTitle("逛逛看", for: UIControlState.normal)
        visitButton.setTitleColor(UIColor.white, for: UIControlState.normal)
        visitButton.setImage(UIImage.init(named: "right_arrow"), for: UIControlState.normal)
        visitButton.titleLabel?.font = UIFont.systemFont(ofSize: 14)
        visitButton.sizeToFit()
        visitButton.setIconInRightWithSpacing(3)
        return visitButton
    }()
    
    //MARK: - Init
    override init(frame: CGRect) {
        super.init(frame: frame)
        
        setupUI()
        bgImageView.isHidden = true
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    //MARK: - Setup UI
    func setupUI() {
        self.addSubview(bgImageView)
        self.addSubview(blackBgImageView)
        self.addSubview(loginImageView)
        self.addSubview(signButton)
        self.addSubview(loginButton)
        self.addSubview(wechatButton)
        self.addSubview(visitButton)
        
        loginImageView.snp.makeConstraints { (make) in
            make.centerX.equalTo(self)
            make.top.equalTo(bgImageView).offset(90)
            
        }
        visitButton.snp.makeConstraints { (make) in
            make.centerX.equalTo(self)
            make.bottom.equalTo(self).offset(-12 - ScreenBottom)
        }

        signButton.snp.makeConstraints { (make) in
            make.width.equalTo(150)
            make.height.equalTo(48)
            make.bottom.equalTo(wechatButton.snp.top).offset(-24 - ScreenBottom)
            make.right.equalTo(-ScreenWidth/2 - 12.5)
        }
        loginButton.snp.makeConstraints { (make) in
             make.centerX.equalTo(self)
             make.bottom.equalTo(visitButton.snp.top).offset(-68)
             make.width.equalTo(ScreenWidth - 30)
             make.height.equalTo(48)
        }
        wechatButton.snp.makeConstraints { (make) in
            make.centerX.equalTo(self)
            make.bottom.equalTo(loginButton.snp.top).offset(-14)
            make.width.equalTo(ScreenWidth - 30)
            make.height.equalTo(48)
        }
    }
}
