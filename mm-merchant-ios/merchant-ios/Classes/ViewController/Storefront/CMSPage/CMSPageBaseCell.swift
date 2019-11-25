//
//  CMSPageBaseCell.swift
//  MMDemoForLeslie_Swift4.0
//
//  Created by Leslie Zhang on 2018/3/27.
//  Copyright © 2018年 Leslie Zhang. All rights reserved.
//

import UIKit

class CMSPageBaseCell: UICollectionViewCell,UICollectionViewDelegate,UICollectionViewDataSource {
    var _layout:UICollectionViewFlowLayout!
    var _table:UICollectionView!
    var _datas = [CMSPageDataModel]()
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        
        self.backgroundColor = UIColor.white
        
        _layout = UICollectionViewFlowLayout()
        _layout.minimumLineSpacing = 0
        _layout.minimumInteritemSpacing = 0
        _layout.scrollDirection = UICollectionViewScrollDirection.horizontal
        _layout.sectionInset = UIEdgeInsetsMake(0, 0,0, 0)
        
        _table = UICollectionView(frame: self.bounds, collectionViewLayout: _layout)
        _table.dataSource = self
        _table.delegate = self
        _table.backgroundColor = UIColor.clear
        _table.alwaysBounceVertical = false
        _table.bounces = false
        _table.showsHorizontalScrollIndicator = false
        _table.showsVerticalScrollIndicator = false
        _table.register(CMSPageShortcutBannerCell.self, forCellWithReuseIdentifier: "CMSPageShortcutBannerCell")
        _table.register(CMSPageBrandListCell.self, forCellWithReuseIdentifier: "CMSPageBrandListCell")
        self.addSubview(_table)
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    func numberOfSections(in collectionView: UICollectionView) -> Int {
        return _datas.count
    }
    
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return 1
    }
    
    @objc override func ssn_onDisplay(_ tableView: UIScrollView, model: AnyObject,atIndexPath indexPath: IndexPath) {
        let cellModel: CMSPageBaseCellModel = model as! CMSPageBaseCellModel
        if let data = cellModel.data{
            _datas = data
            _layout.itemSize = CGSize(width: ScreenWidth / CGFloat(_datas.count), height: self.bounds.size.height)
            _table.reloadData()
        }

    }
    
    
    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {

        let cell = collectionView.dequeueReusableCell(withReuseIdentifier: "CMSPageShortcutBannerCell", for: indexPath) as! CMSPageBrandListCell
        
        let red = Double(arc4random()%256)/255.0
        let green = Double(arc4random()%256)/255.0
        let blue = Double(arc4random()%256)/255.0
        
        cell.backgroundColor = UIColor(red: CGFloat(red), green: CGFloat(green), blue: CGFloat(blue), alpha: 1)
        return cell
    }
}
