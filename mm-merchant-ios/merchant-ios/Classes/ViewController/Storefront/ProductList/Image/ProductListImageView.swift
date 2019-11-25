//
//  ProductListImageView.swift
//  storefront-ios
//
//  Created by Kam on 13/8/2018.
//  Copyright © 2018 WWE & CO. All rights reserved.
//

import UIKit

class ProductListImageView: UIImageView {
    
    private lazy var blackBgImageView: UIView = {
        let blackBgImageView = UIView()
        blackBgImageView.backgroundColor = .black
        blackBgImageView.alpha = 0.2
        return blackBgImageView
    }()
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        self.addSubview(blackBgImageView)
        
        blackBgImageView.snp.makeConstraints { (make) in
            make.edges.equalTo(self)
        }
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    deinit {
        print("deinit header image view")
    }
    
    

}
