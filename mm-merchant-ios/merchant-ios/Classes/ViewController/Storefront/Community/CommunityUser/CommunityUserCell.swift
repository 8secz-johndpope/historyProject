//
//  CommunityUserCell.swift
//  storefront-ios
//
//  Created by Leslie Zhang on 2018/8/6.
//  Copyright © 2018年 WWE & CO. All rights reserved.
//

import UIKit

class CommunityUserCell: UICollectionViewCell {
    
    //MARK: - init
    override init(frame: CGRect) {
        super.init(frame: frame)
        
        backgroundColor = .yellow

    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override func ssn_onDisplay(_ tableView: UIScrollView, model: AnyObject, atIndexPath indexPath: IndexPath, reused: Bool) {
        if let _ = model as? CommunityUserCellModel {
            print("")
        }
    }
}
