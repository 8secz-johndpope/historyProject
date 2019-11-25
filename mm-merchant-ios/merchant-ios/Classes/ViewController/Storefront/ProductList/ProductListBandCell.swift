//
//  ProductListBandCell.swift
//  storefront-ios
//
//  Created by Leslie Zhang on 2018/5/23.
//  Copyright © 2018年 WWE & CO. All rights reserved.
//

import UIKit

class ProductListBandCell: UICollectionViewCell {
    override init(frame: CGRect) {
        super.init(frame: frame)
        
        self.backgroundColor = .clear
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override func ssn_onDisplay(_ tableView: UIScrollView, model: AnyObject, atIndexPath indexPath: IndexPath, reused: Bool) {

        if let cellModel: ProductListBandCellModel = model as? ProductListBandCellModel{
            if let headView = cellModel.contentView {
                cellModel.superView = self.contentView
                
                let superView = headView.superview
                if superView == nil || superView! != self.contentView {
                    headView.frame = self.contentView.bounds
                    self.contentView.addSubview(headView)
                }
            }
        }
    }
}
