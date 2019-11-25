//
//  PopFlashSaleViewController.swift
//  storefront-ios
//
//  Created by Leslie Zhang on 2018/5/10.
//  Copyright © 2018年 WWE & CO. All rights reserved.
//

import UIKit

class PopFlashSaleViewController: UIViewController {
    lazy var contentView:UIView = {
        let contentView = UIView()
        contentView.backgroundColor = .white
        return contentView
    }()
    override func viewDidLoad() {
        super.viewDidLoad()

        self.view.backgroundColor = .clear
        
        self.view.addSubview(contentView)
        contentView.snp.makeConstraints { (make) in
            make.center.equalTo(self.view)
            make.width.equalTo(ScreenWidth - 36 * 2)
            make.height.equalTo(164)
        }
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    

 

}
