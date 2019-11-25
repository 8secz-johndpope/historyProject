//
//  TagCollectionViewCell.swift
//  merchant-ios
//
//  Created by Vu Dinh Trung on 4/8/16.
//  Copyright © 2016 WWE & CO. All rights reserved.
//

import UIKit

protocol TagCollectionViewDelegate: NSObjectProtocol {
    func handleTapAddTag(_ rowIndex: Int)
}
class TagCollectionViewCell: UICollectionViewCell, UICollectionViewDelegate, UICollectionViewDataSource, UICollectionViewDelegateFlowLayout {
    var imageViewIcon = UIImageView()

    var imageViewAdd = UIImageView()
    var line = UIView()
    var labelTag = UILabel()
    
    private let sectionInsets = UIEdgeInsets(top: 0.0, left: Constants.Margin.Left, bottom: 0.0, right: 0.0)
    private final let identifier = ""
    private final let MarginLeft : CGFloat = 16.0
    private final let Margin:CGFloat = 8.0
    private final let WidthIcon: CGFloat = 25.0
    private final let HeighIcon:CGFloat = 25.0
    private final let SizeIconAdd: CGFloat = 35.0
    private final let heightCollectionView: CGFloat = 32.0
    
    var tagCollectionViewDelegate: TagCollectionViewDelegate?
    var tagListCollectionView: UICollectionView!
    var datasource = [Any]()
    var mode = ModeGetTagList.brandTagList
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        
        imageViewIcon.contentMode = .scaleAspectFit
        self.addSubview(imageViewIcon)
        
        
        imageViewAdd.image = UIImage(named: "btn_request")
        imageViewAdd.contentMode = .scaleAspectFill
        imageViewAdd.isUserInteractionEnabled = true
        imageViewAdd.addGestureRecognizer(UITapGestureRecognizer(target: self, action: #selector(TagCollectionViewCell.handleTapAdd)))
        self.addSubview(imageViewAdd)
        
        initListCollectionViewByDatasource(self, delegate: self)
        
        line.backgroundColor = UIColor.secondary3()
        self.addSubview(line)
        layoutSubviews()
        
    }
    
    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
    }
 
    override func layoutSubviews() {
        super.layoutSubviews()
        imageViewIcon.frame = CGRect(x: MarginLeft, y: (self.frame.height - HeighIcon) / 2, width: WidthIcon, height: HeighIcon)
        imageViewAdd.frame = CGRect(x: self.frame.width - MarginLeft - WidthIcon, y: Margin, width: SizeIconAdd, height: SizeIconAdd)

        tagListCollectionView.frame = CGRect(x: self.imageViewIcon.frame.maxX + Margin, y: (bounds.maxY - heightCollectionView) / 2, width: self.imageViewAdd.frame.origin.x - self.imageViewIcon.frame.maxX  - Margin * 2, height: heightCollectionView)
        line.frame = CGRect(x: 0, y: self.frame.height - 1, width: self.frame.width, height: 1.0)
    }
    
    func setupDataForCell(_ style: StyleCell, indexPath: IndexPath) -> Void {
        self.imageViewIcon.image = style.imageIcon
        
        if indexPath.row == 0 {
            self.line.backgroundColor = UIColor.secondary1()
        }
        
    }
    
    @objc func handleTapAdd(_ gesture: UITapGestureRecognizer) -> Void {
        let view = gesture.view as! UIImageView
        self.tagCollectionViewDelegate?.handleTapAddTag(view.tag)
        
    }

    
    //MARK: delegate & datasource
    
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return datasource.count
    }
    
    func numberOfSections(in collectionView: UICollectionView) -> Int {
        return 1
    }
    
    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        switch mode {
        case .brandTagList:
            let cell = collectionView.dequeueReusableCell(withReuseIdentifier: BrandCollectionCellId, for: indexPath) as! BrandLogoCollectionViewCell
            cell.setupDataByMerchant(datasource[indexPath.row] as! Merchant)
            return cell
        case .friendTagList:
            let cell = collectionView.dequeueReusableCell(withReuseIdentifier: ObjectCollectionViewId, for: indexPath) as! ObjectCollectionView
            cell.setupDataByUser(datasource[indexPath.row] as! User)
            return cell
        case .wishlistTag:
            return UICollectionViewCell()
        }
        
        
    }
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, sizeForItemAt indexPath: IndexPath) -> CGSize {
        
        return CGSize(width: 32, height: 32)
        
    }
    
    func collectionView(_ collectionView: UICollectionView,
                        layout collectionViewLayout: UICollectionViewLayout,
                        insetForSectionAt section: Int) -> UIEdgeInsets {
        return sectionInsets
    }
    
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, minimumInteritemSpacingForSectionAt section: Int) -> CGFloat {
        return 0.0
    }
    
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, minimumLineSpacingForSectionAt section: Int) -> CGFloat {
        return 13
    }
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, referenceSizeForHeaderInSection section: Int) -> CGSize{
        return CGSize(width: 0,height: 0)
    }
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, referenceSizeForFooterInSection section: Int) -> CGSize{
        return CGSize(width: 0,height: 0)
    }
    func initListCollectionViewByDatasource<D: UICollectionViewDataSource, E: UICollectionViewDelegate>(_ datasource: D, delegate: E) -> Void {
    
        let brandLayout: UICollectionViewFlowLayout = UICollectionViewFlowLayout()
        brandLayout.sectionInset = UIEdgeInsets(top: 0, left: 0, bottom: 0, right: 0)
        brandLayout.scrollDirection = UICollectionViewScrollDirection.horizontal
        
        var  frame:CGRect = CGRect.zero
        frame  = CGRect(x: self.imageViewIcon.frame.maxX + Margin, y: (bounds.maxY - heightCollectionView) / 2, width: self.imageViewAdd.frame.origin.x - self.imageViewIcon.frame.maxX + Margin, height: heightCollectionView)
        let collectionView = UICollectionView(frame: frame, collectionViewLayout: brandLayout)
        collectionView.showsHorizontalScrollIndicator = false
        collectionView.backgroundColor = UIColor.white
        self.tagListCollectionView = collectionView
        self.tagListCollectionView.dataSource = datasource
        self.tagListCollectionView.delegate = delegate
        self.tagListCollectionView.register(ObjectCollectionView.self, forCellWithReuseIdentifier: ObjectCollectionViewId)
        self.tagListCollectionView.register(BrandLogoCollectionViewCell.self, forCellWithReuseIdentifier: BrandCollectionCellId)
        self.addSubview(tagListCollectionView)
        self.tagListCollectionView.reloadData()
        
    }
    
    func setupDataSourceAtIndexPath(_ indexPath: IndexPath, datasource: [Any]) -> Void {
        if indexPath.row == 0 {
            self.datasource = datasource as! [Merchant]
            mode = .brandTagList
            self.tagListCollectionView.reloadData()
        } else {
            self.datasource = datasource as! [User]
            mode = .friendTagList
            self.tagListCollectionView.reloadData()
        }
    }
}
