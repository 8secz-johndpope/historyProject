//
//  SignupErroView.swift
//  storefront-ios
//
//  Created by Leslie Zhang on 2018/5/16.
//  Copyright © 2018年 WWE & CO. All rights reserved.
//

import UIKit

class SignupErroView: UIView {
    var contentStr:String?{
        didSet {
            if let str = contentStr{
                label.text = str
                self.snp.updateConstraints { (make) in
                    make.width.equalTo(str.stringSizeWithMaxWidth(ScreenWidth, font: UIFont.systemFont(ofSize: 14)).width + 14 * 5 + 6)
                }
            }
        }
    }
    
    lazy var bgImageView:UIImageView = {
        let bgImageView = UIImageView()
        bgImageView.image = UIImage(named: "code_error_bg")
        return bgImageView
    }()
    
    lazy var iconImageView:UIImageView = {
        let iconImageView = UIImageView()
        iconImageView.image = UIImage(named: "error_ic")
        return iconImageView
    }()
    
    lazy var label:UILabel = {
        let label = UILabel()
        label.font = UIFont.systemFont(ofSize: 14)
        label.numberOfLines = 0
        return label
    }()
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        
        self.addSubview(bgImageView)
        self.addSubview(iconImageView)
        self.addSubview(label)
        
        self.snp.makeConstraints { (make) in
            make.width.equalTo(label.size.width + 14 * 5 + 6)
            make.bottom.equalTo(label).offset(10)
        }
        
        bgImageView.snp.makeConstraints { (make) in
            make.edges.equalTo(self)
        }
        iconImageView.snp.makeConstraints { (make) in
            make.left.equalTo(self).offset(28)
            make.width.height.equalTo(14)
            make.centerY.equalTo(label)
        }
        label.snp.makeConstraints { (make) in
            make.top.equalTo(self).offset(10)
            make.left.equalTo(iconImageView.snp.right).offset(6)
            make.right.equalTo(self).offset(-14)
        }
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}
