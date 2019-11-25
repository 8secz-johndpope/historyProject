//
//  MMFilterCollectionHeaderView.swift
//  storefront-ios
//
//  Created by Demon on 20/7/18.
//  Copyright © 2018年 WWE & CO. All rights reserved.
//

import UIKit

class MMFilterCollectionHeaderView: UICollectionReusableView {
    
    @IBOutlet weak var arrowBtn: UIButton!
    @IBOutlet weak var contentLb: UILabel!
    @IBOutlet weak var titleLb: UILabel!
    var isSelected: Bool = false {
        didSet {
            arrowBtn.isSelected = isSelected
        }
    }
    var arrowBtnClick: (() -> ())?
    var productTagSelectedArray: [String] = [] {
        didSet {
            if productTagSelectedArray.count > 0 {
                contentLb.text = productTagSelectedArray.joined(separator: ",")
                contentLb.textColor = UIColor(hexString: "#ED2247")
            }
        }
    }
    
    var headerViewType: MMFilterType? {
        didSet {
            titleLb.text = headerViewType?.sectionTitle
            arrowBtn.isHidden = (headerViewType == MMFilterType.priceRange) ? true : false
            contentLb.isHidden = (headerViewType == MMFilterType.priceRange) ? true : false
        }
    }
    
    @IBAction func arrowBtnClick(_ sender: UIButton) {
        sender.isSelected = !sender.isSelected
        if let click = arrowBtnClick {
            click()
        }
    }
    
    override func awakeFromNib() {
        super.awakeFromNib()
        contentLb.text = String.localize("LB_MORE")
        contentLb.textColor = UIColor(hexString: "#B2B2B2")
        contentLb.whenTapped { [weak self] in
            self?.arrowBtnClick((self?.arrowBtn)!)
        }
    }
    
}
