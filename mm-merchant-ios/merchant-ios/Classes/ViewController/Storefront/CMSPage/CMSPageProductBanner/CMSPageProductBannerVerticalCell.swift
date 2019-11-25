//
//  CMSPageProductBannerVerticalCell.swift
//  storefront-ios
//
//  Created by Leslie Zhang on 2018/4/16.
//  Copyright © 2018年 WWE & CO. All rights reserved.
//

import UIKit

class CMSPageProductBannerVerticalCell: UICollectionViewCell {
    
    override init(frame: CGRect) {
        super.init(frame: frame)
                let red = Double(arc4random()%256)/255.0
                let green = Double(arc4random()%256)/255.0
                let blue = Double(arc4random()%256)/255.0
        self.backgroundColor = UIColor(red: CGFloat(red), green: CGFloat(green), blue: CGFloat(blue), alpha: 1)
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    @objc override func ssn_onDisplay(_ tableView: UIScrollView, model: AnyObject,atIndexPath indexPath: IndexPath) {
        let cellModel: CMSPageProductBannerVerticalCellModel = model as! CMSPageProductBannerVerticalCellModel
        if let data = cellModel.data{

        }
    }
}
