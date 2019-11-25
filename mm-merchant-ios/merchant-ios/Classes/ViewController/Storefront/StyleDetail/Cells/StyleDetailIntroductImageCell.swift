//
//  StyleDetailIntroductImageCell.swift
//  storefront-ios
//
//  Created by Leslie Zhang on 14/09/2018.
//  Copyright © 2018 WWE & CO. All rights reserved.
//

import UIKit

class StyleDetailIntroductImageCell: UICollectionViewCell {

    //MARK: - init
    override init(frame: CGRect) {
        super.init(frame: frame)
        
        self.contentView.addSubview(contentImageView)
        
        contentImageView.snp.makeConstraints { (make) in
            make.edges.equalTo(self.contentView)
        }
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override func ssn_onDisplay(_ tableView: UIScrollView, model: AnyObject, atIndexPath indexPath: IndexPath, reused: Bool) {
        if let cellModel = model as? StyleDetailIntroductImageCellModel {
            if let imagekey = cellModel.imageData?.imageKey {
                contentImageView.mm_setImageWithURL(ImageURLFactory.URLSize1000(imagekey, category: .product), placeholderImage: UIImage(named: "holder"),contentMode: .scaleAspectFill)
            }
        }
    }
    
    //MARK: - lazy
    lazy private var contentImageView:UIImageView = {
        let contentImageView = UIImageView()
        contentImageView.backgroundColor = UIColor.white
        return contentImageView
    }()
}
