//
//  ShortcutCell.swift
//  merchant-ios
//
//  Created by khanh.nguyen on 4/21/17.
//  Copyright © 2017 WWE & CO. All rights reserved.
//

import UIKit

class ShortcutCell: UICollectionViewCell {
    static let CellIdentifier = "BannerCellID"
    
    var banner: Banner?
    private var imageView = UIImageView()
    private let placeholder = UIImageView(image: UIImage(named: "tile_placeholder"))
    var index = 0
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        
        self.addSubview(imageView)
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override func layoutSubviews() {
        super.layoutSubviews()
        let width = self.bounds.sizeWidth
        let height = self.bounds.sizeHeight
        imageView.frame = CGRect(x: 0, y: 0, width: width, height: height)
        
    }
    
    func setImage(_ imageKey : String, banner: Banner, index: Int) {
        imageView.mm_setImageWithURL(ImageURLFactory.URLSize256(imageKey, category: .banner), placeholderImage: UIImage(named: "postPlaceholder"), contentMode: .scaleAspectFit)
        self.index = index
        self.layoutSubviews()
    }
}
