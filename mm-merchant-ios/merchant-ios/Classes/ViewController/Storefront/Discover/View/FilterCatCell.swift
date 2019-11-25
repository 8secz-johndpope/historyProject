//
//  FilterCatCell.swift
//  merchant-ios
//
//  Created by HVN_Pivotal on 2/16/16.
//  Copyright © 2016 WWE & CO. All rights reserved.
//

import Foundation
import UIKit
class FilterCatCell: UICollectionViewCell {
    
    private final let TextMarginLeft: CGFloat = 14
    private final let BackgroundMarginLeft: CGFloat = 2
    private final let MarginTop: CGFloat = 0.0
    static let CheckBoxSize = CGSize(width: 15, height: 15)
    
    var nameLabel = UILabel()
    var viewBackground = UIView()
    var checkBoxImageView = UIImageView(image: UIImage(named: "icon_checkbox_checked"))
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        viewBackground.backgroundColor = UIColor.clear
        viewBackground.layer.borderColor = UIColor.secondary1().cgColor
        viewBackground.layer.borderWidth = 1.0
        viewBackground.layer.cornerRadius = 3.0
        addSubview(viewBackground)
        
        viewBackground.addSubview(checkBoxImageView)
        
        nameLabel.formatSize(13)
        nameLabel.textColor = UIColor.secondary2()
        nameLabel.textAlignment = .center
        
        nameLabel.numberOfLines = 1
        nameLabel.lineBreakMode = .byTruncatingTail
        addSubview(nameLabel)
        
    }
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    override func layoutSubviews() {
        super.layoutSubviews()
        nameLabel.frame = CGRect(x: 5 , y: 0, width: self.bounds.maxX - 5, height: self.bounds.maxY)
        viewBackground.frame = CGRect(x: BackgroundMarginLeft, y: MarginTop, width: self.bounds.maxX - BackgroundMarginLeft * 2, height: self.bounds.maxY - MarginTop)
        checkBoxImageView.frame = CGRect(x: viewBackground.frame.maxX - FilterCatCell.CheckBoxSize.width - 5, y: viewBackground.frame.midY - FilterCatCell.CheckBoxSize.height/2, width: FilterCatCell.CheckBoxSize.width, height: FilterCatCell.CheckBoxSize.height)
    }
    func selected(_ isSelected: Bool) {
        checkBoxImageView.isHidden = !isSelected
        if isSelected {
            viewBackground.layer.borderColor = UIColor.primary1().cgColor
            nameLabel.textColor = UIColor.primary1()
            nameLabel.textAlignment = .left
        }
        else {
            viewBackground.layer.borderColor = UIColor.secondary1().cgColor
            nameLabel.textColor = UIColor.secondary2()
            nameLabel.textAlignment = .center
        }
    }
    
}
