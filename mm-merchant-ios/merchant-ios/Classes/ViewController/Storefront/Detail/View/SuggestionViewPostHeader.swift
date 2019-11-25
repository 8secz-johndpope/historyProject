//
//  SuggestionViewPostHeader.swift
//  storefront-ios
//
//  Created by Leslie Zhang on 2018/8/21.
//  Copyright © 2018年 WWE & CO. All rights reserved.
//

import UIKit

class SuggestionViewPostHeader: UICollectionReusableView {
    static let SuggestionViewPostHeaderId = "SuggestionViewPostHeaderId"
    var descriptionLabel : UILabel!
    
    private final let HeightLabel = CGFloat(21)
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        backgroundColor = UIColor.white
        
        let descripLabel = { () -> UILabel in
            let label = UILabel(frame: CGRect(x: bounds.minX , y: (bounds.height - HeightLabel)/2, width: bounds.width, height: HeightLabel))
            descriptionLabel = label
            return label
        }()
        descriptionLabel.formatSize(15)
        descriptionLabel.textColor = UIColor.secondary2()
        descriptionLabel.textAlignment = .center
        descriptionLabel.text = String.localize("LB_CA_NEW_PRODUCTS")
        addSubview(descripLabel)
        
    }
    override func layoutSubviews() {
        super.layoutSubviews()
        
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}
