//
//  SizeCollectionCell.swift
//  merchant-ios
//
//  Created by Quang Truong Dinh on 9/6/16.
//  Copyright © 2016 WWE & CO. All rights reserved.
//

import Foundation

class SizeCollectionCell: UICollectionViewCell {
    
    static let CellIdentifier = "SizeCollectionCellID"
    static let DefaultHeight: CGFloat = 35
    static let LabelHeight: CGFloat = 30
    
    private var nameLabel = UILabel()
    private var crossView = UIView()
    
    var name: String = "" {
        didSet {
            nameLabel.text = name
            
            self.layoutSubviews()
        }
    }
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        
        nameLabel.text = name
        nameLabel.textAlignment = .center
        nameLabel.formatSize(14)
        nameLabel.backgroundColor = UIColor.white
        nameLabel.layer.borderColor = UIColor.secondary1().cgColor
        nameLabel.layer.masksToBounds = true
        nameLabel.layer.borderWidth = 1
        nameLabel.layer.cornerRadius = 3
        addSubview(nameLabel)
        
        crossView.backgroundColor = UIColor.secondary1()
        addSubview(crossView)
        
        itemDisabled(false)
        
        self.layoutSubviews()
    }
    
    override func layoutSubviews() {
        super.layoutSubviews()
        
        nameLabel.frame = CGRect(x: 0, y: 0, width: SizeCollectionCell.getWidth(name), height: SizeCollectionCell.LabelHeight)
        crossView.frame = CGRect(x: nameLabel.frame.minX + 10, y: nameLabel.frame.midY, width: nameLabel.frame.width - 20, height: 1)
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    func itemDisabled(_ disabled: Bool) {
        if disabled {
            crossView.isHidden = false
            nameLabel.textColor = UIColor.secondary1()
            nameLabel.layer.borderColor = UIColor.secondary1().cgColor
            
            //Fix for UI displaying, item disable should not selected
            itemSelected(false)
            
        } else {
            crossView.isHidden = true
        }
    }
    
    func itemSelected(_ selected: Bool) {
        if selected {
            nameLabel.backgroundColor = UIColor.primary1()
            nameLabel.textColor = UIColor.white
            nameLabel.layer.borderColor = UIColor.primary1().cgColor
        } else {
            nameLabel.backgroundColor = UIColor.white
            nameLabel.textColor = UIColor.secondary2()
            nameLabel.layer.borderColor = UIColor.secondary1().cgColor
        }
        
        self.accessibilityValue = selected ? "true" : "false"
    }
    
    class func getWidth(_ sizeName: String) -> CGFloat {
        let label = UILabel(frame: CGRect(x: 0, y: 0, width: CGFloat.greatestFiniteMagnitude, height: SizeCollectionCell.LabelHeight))
        label.text = sizeName
        
        return label.optimumWidth() + 38
    }
}
