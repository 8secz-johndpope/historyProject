//
//  MagazineCategoryCell.swift
//  merchant-ios
//
//  Created by Gam Bogo on 5/19/16.
//  Copyright © 2016 WWE & CO. All rights reserved.
//

import Foundation

class MagazineCategoryCell: UICollectionViewCell {
    
    static let CellIdentifier = "MagazineCategoryCellID"
    
    private let TitleLabelHeight: CGFloat = 25
    private let TitleFontSize: Int = 14
    var categoryTitle: UILabel?
    private var borderBottom: UIView?
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        
        categoryTitle = UILabel(frame: CGRect(x: 0, y: (frame.height - TitleLabelHeight) / 2,  width: frame.width, height: TitleLabelHeight))
        categoryTitle!.formatSize(TitleFontSize)
        categoryTitle!.textColor = UIColor.white
        contentView.addSubview(categoryTitle!)
        
        borderBottom = UIView(frame: CGRect(x: 0, y: frame.height - 1, width: frame.width, height: 1.0))
        borderBottom?.backgroundColor = UIColor.white
        contentView.addSubview(borderBottom!)
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override func layoutSubviews() {
        super.layoutSubviews()
    }
}
