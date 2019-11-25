//
//  DiscoverCategoryCell.swift
//  merchant-ios
//
//  Created by Kam on 18/4/2016.
//  Copyright © 2016 WWE & CO. All rights reserved.
//

import Foundation

class DiscoverCategoryCell: UICollectionViewCell {
    
    static let CellIdentifier = "DiscoverCategoryCellID"
    static let DefaultHeight: CGFloat = 120
    
    var label = UILabel()
    var imageView = UIImageView()
    var alphaView = UIView()
    let gridView = SubcategoryGridView()
    var category: Cat?
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        backgroundColor = UIColor.white
        
        imageView.frame = CGRect(x: 0, y: 0, width: bounds.width, height: bounds.height)
        imageView.clipsToBounds = true
        contentView.addSubview(imageView)
        
        label.frame = bounds
        label.font = UIFont.systemFont(ofSize: 16)
        label.textColor = UIColor.white
        label.textAlignment = .center
        label.backgroundColor = UIColor.clear
        contentView.addSubview(label)
        
        alphaView.frame = imageView.bounds
        alphaView.backgroundColor = UIColor.black
        alphaView.alpha = 0.5
        imageView.addSubview(alphaView)
        
        gridView.frame = CGRect(x: 0, y: bounds.center.y, width: bounds.width, height: bounds.height)
        gridView.isHidden = true
        gridView.backgroundColor = UIColor.white
        gridView.clipsToBounds = true
        contentView.addSubview(gridView)
    }
    
    func setImage(_ key : String, imageCategory : ImageCategory) {
        imageView.mm_setImageWithURL(ImageURLFactory.URLSize1000(key, category: imageCategory), placeholderImage : UIImage(named: "holder"), contentMode: .scaleAspectFill)
    }
    
    func expandShowDetail() {
        self.gridView.size = CGSize(width: self.gridView.size.width, height: 1)
        gridView.isHidden = false
        
        UIView.transition(with: gridView, duration: 0.3, options: UIViewAnimationOptions(), animations: {
            self.gridView.frame = CGRect(x: 0, y: 0, width: self.gridView.size.width, height: self.getSubviewHeight())
            }, completion: { (finished: Bool) -> () in
                self.gridView.resizeGridSize()
        })
    }
    
    func collapseRemoveDetail(_ completion: ((_ finished: Bool) -> ())? = nil){
        UIView.transition(with: gridView, duration: 0.3, options: UIViewAnimationOptions(), animations: {
            self.gridView.frame = CGRect(x: 0, y: super.bounds.center.y, width: self.gridView.size.width, height: 0)
            }, completion: { (finished: Bool) -> () in
                self.gridView.isHidden = true
                if let action = completion{
                    action(finished)
                }
        })
    }
    
    func handleGridView(_ isSelect: Bool) {
        gridView.isHidden = !isSelect
        
        if isSelect {
            self.gridView.size = CGSize(width: self.gridView.size.width, height: self.getSubviewHeight())
        } else {
            self.gridView.size = CGSize(width: self.gridView.size.width, height: 0)
        }
    }
    
    func getSubviewHeight() -> CGFloat {
        return gridView.getGridViewHeight()
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    //For fixing wrong frame when scroll out of screen when category expanded
    func updateSubviewFrames() {
        var gridViewFrame = self.gridView.frame
        gridViewFrame.origin.y = 0
        self.gridView.frame = gridViewFrame
    }
}
