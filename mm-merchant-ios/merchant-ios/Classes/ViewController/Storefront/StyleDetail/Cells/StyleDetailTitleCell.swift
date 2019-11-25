//
//  StyleDetailTitleCell.swift
//  storefront-ios
//
//  Created by Leslie Zhang on 17/09/2018.
//  Copyright © 2018 WWE & CO. All rights reserved.
//

import UIKit

class StyleDetailTitleCell: UICollectionViewCell {
    //MARK: - init
    override init(frame: CGRect) {
        super.init(frame: frame)
        
        self.contentView.addSubview(titleLabel)
        titleLabel.snp.makeConstraints { (make) in
            make.center.equalTo(self.contentView)
        }
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    //MARK: - ssn_onDisplay
    override func ssn_onDisplay(_ tableView: UIScrollView, model: AnyObject, atIndexPath indexPath: IndexPath, reused: Bool) {
        if let cellModel = model as? StyleDetailTitleCellModel {
            if let title = cellModel.title {
                titleLabel.text = title
            }
        }
    }
    
    //MARK: - lazy
    lazy private var titleLabel:UILabel = {
        let titleLabel = UILabel()
        titleLabel.textColor = UIColor.secondary2()
        titleLabel.font = UIFont.systemFont(ofSize: 15)
        titleLabel.textAlignment = .center
        return titleLabel
    }()
}
