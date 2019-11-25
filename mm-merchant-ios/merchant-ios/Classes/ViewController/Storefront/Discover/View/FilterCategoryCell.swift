//
//  FilterCategoryCell.swift
//  merchant-ios
//
//  Created by Alan YU on 2/4/2018.
//  Copyright © 2018 WWE & CO. All rights reserved.
//

class FilterCategoryCell: UICollectionViewCell {
    
    @IBOutlet weak var titleLabel: UILabel!
    
    var category: Cat? {
        didSet {
            var title = ""
            if let category = category {
                title = category.categoryName
            }
            
            titleLabel.text = title
        }
    }
    
    var picked: Bool = false {
        didSet {
            if picked {
                layer.borderColor = UIColor.primary1().cgColor
                titleLabel.textColor = UIColor.primary1()
                backgroundColor = .clear
            } else {
                layer.borderColor = UIColor.secondary9().cgColor
                titleLabel.textColor = UIColor.secondary7()
                backgroundColor = UIColor.secondary9()
            }
           
        }
    }
    
    override func awakeFromNib() {
        super.awakeFromNib()
        
        titleLabel.font = UIFont.fontWithSize(12, isBold: false)
        
        layer.borderWidth = 0.5
        layer.cornerRadius = 2
        
        isSelected = false
        
    }
    
    deinit {
        
    }
    
}

// IB Actions
extension FilterCategoryCell {

}

// Actions
extension FilterCategoryCell {

}
