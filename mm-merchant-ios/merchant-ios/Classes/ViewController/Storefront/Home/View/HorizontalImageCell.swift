//
//  HorizontalImageCell.swift
//  merchant-ios
//
//  Created by Gam Bogo on 5/27/16.
//  Copyright © 2016 WWE & CO. All rights reserved.
//

import Foundation
import SKPhotoBrowser

protocol HorizontalImageCellDelegate: NSObjectProtocol {
    func ontap(merchant: Merchant)
    func ontap(brand: BrandUnionMerchant)
    func ontap(category: Cat)
    func onTapBrandAll()
    func onTapCategoryAll()
}

protocol HorizontalImageBucketCellDelegate: NSObjectProtocol {
    /// 点击评论的图片
    ///
    /// - Parameters:
    ///   - imageBucketList: image list
    ///   - row: row
    func ontap(imageBucketList: [ImageBucket],row: Int)
}

class HorizontalImageCell: UICollectionViewCell, UICollectionViewDataSource, UICollectionViewDelegate, UICollectionViewDelegateFlowLayout {
    
    static let CellIdentifier = "HorizontalImageCellID"
    
    let ImageCellId = "ImageCellId"
    
    //Collection Item height = Super View height - HeaderViewHeight
    var collectionItemHeight: CGFloat = 0
    var collectionView: UICollectionView!
    var headerView = UIView()
    private var headerButton = UIButton()
    weak var imageBucketDelegate: HorizontalImageBucketCellDelegate?
    weak var delegate: HorizontalImageCellDelegate?
    var headerLabel: UILabel!
    var lineSpacingItems: CGFloat = 2.0 //The Space between Image Cells
    
    var hideHeaderView = false {
        didSet {
            headerView.isHidden = hideHeaderView
            
            if hideHeaderView {
                let paddingContentLeftRight: CGFloat = 15
                let paddingContentTop: CGFloat = 10
                collectionItemHeight = frame.size.height - 2 * paddingContentLeftRight
                collectionView.frame = CGRect(x: paddingContentLeftRight, y: paddingContentTop, width: frame.width - 2 * paddingContentLeftRight, height: collectionItemHeight)
            } else {
                collectionItemHeight = frame.size.height - HorizontalImageCell.getHeaderViewHeight()
                collectionView.frame = CGRect(x: 0, y: HorizontalImageCell.getHeaderViewHeight(), width: frame.width, height: collectionItemHeight)
            }
        }
    }
    
    var collectionViewBackgroundColor: UIColor? {
        didSet {
            if let collectionViewBackgroundColor = self.collectionViewBackgroundColor {
                collectionView.backgroundColor = collectionViewBackgroundColor
                contentView.backgroundColor = collectionViewBackgroundColor
            }
        }
    }
    
    var dataSource: [Any]? {
        didSet {
            self.collectionView.reloadData()
        }
    }
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        
        headerView.backgroundColor = UIColor.white
        contentView.backgroundColor = UIColor.white
        self.backgroundColor = UIColor.white
        
         //Collection Item height = Super View height - HeaderViewHeight
        collectionItemHeight = frame.size.height - HorizontalImageCell.getHeaderViewHeight()
        
        setupCollectionView()
        setupHeaderView()
        
        contentView.addSubview(collectionView)
        contentView.addSubview(headerView)
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override func layoutSubviews() {
        super.layoutSubviews()
    }
    
    // MARK: Views
    
    func setupCollectionView() {
        let layout = UICollectionViewFlowLayout()
        layout.scrollDirection = .horizontal
        layout.headerReferenceSize = CGSize.zero
        layout.footerReferenceSize = CGSize.zero
        layout.sectionInset = UIEdgeInsets.zero
        layout.minimumInteritemSpacing = 0
        layout.minimumLineSpacing = 0
        layout.itemSize = CGSize(width: frame.width, height: collectionItemHeight)
        
        collectionView = UICollectionView(frame: CGRect(x: 0, y: HorizontalImageCell.getHeaderViewHeight(), width: frame.width, height: collectionItemHeight), collectionViewLayout: layout)
        collectionView.contentInset = UIEdgeInsets.zero
        collectionView.backgroundColor = UIColor.white
        collectionView.showsHorizontalScrollIndicator = false
        collectionView.dataSource = self
        collectionView.delegate = self
        collectionView.register(ImageCollectCell.self, forCellWithReuseIdentifier: ImageCellId)
    }
    
    func setupHeaderView() {
        let headerViewHeight = HorizontalImageCell.getHeaderViewHeight()
        headerView.frame = CGRect(x: 0, y: 0, width: frame.width, height: headerViewHeight)
        
        // Title
        headerLabel = UILabel(frame: CGRect(x: 6, y: 0, width: 100, height: headerViewHeight))
        headerLabel.formatSmall()
        headerLabel.textColor = UIColor.blackTitleColor()
        headerView.addSubview(headerLabel)
        
        // Disclosure Indicator
        let disclosureIndicatorImageViewSize = CGSize(width: 6, height: 10)
        let disclosureIndicatorImageView = UIImageView(image: UIImage(named: "filter_right_arrow"))
        disclosureIndicatorImageView.frame = CGRect(x: headerView.frame.size.width - 12, y: (headerView.frame.size.height - disclosureIndicatorImageViewSize.height) / 2 , width: disclosureIndicatorImageViewSize.width, height: disclosureIndicatorImageViewSize.height)
        headerView.addSubview(disclosureIndicatorImageView)
        
        // View all label
        let viewAllLabel = UILabel(frame: CGRect(x: disclosureIndicatorImageView.frame.origin.x - 100 - 15, y: 0, width: 100, height: headerViewHeight))
        viewAllLabel.formatSize(11)
        viewAllLabel.textColor = UIColor.blackTitleColor()
        viewAllLabel.textAlignment = .right
        viewAllLabel.text = String.localize("LB_CA_ALL")
        headerView.addSubview(viewAllLabel)
        
        // All Button
        headerButton.addTarget(self, action: #selector(onTapViewAll), for: .touchUpInside)
        headerButton.frame = headerView.bounds
        headerView.addSubview(headerButton)
    }
    
    func reset() {
        if collectionView != nil && collectionView.numberOfItems(inSection: 0) > 0 {
            collectionView.scrollToItem(at: IndexPath(row: 0, section: 0), at: .left, animated: false)
        }
    }
    
    class func getHeaderViewHeight() -> CGFloat {
        return 40
    }
    
    // MARK: - Collection View Data Source methods
    
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, insetForSectionAt section: Int) -> UIEdgeInsets {
        return UIEdgeInsets.zero
    }
    
    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        let cell = collectionView.dequeueReusableCell(withReuseIdentifier: ImageCellId, for: indexPath) as! ImageCollectCell
        cell.backgroundColor = collectionViewBackgroundColor
        
        if let brandList = self.dataSource as? [BrandUnionMerchant] {
            let brand = brandList[indexPath.row]
            cell.setImage(brand.largeLogoImage, category: brand.imageCategory)
            cell.filter.alpha = 0.0
            
            //Make sure blur view don't appear
            cell.hideBlurTextView()
            cell.label.text = ""
            
        } else if let categoriesList = self.dataSource as? [Cat] {
            let category = categoriesList[indexPath.row]
            cell.label.text = category.categoryName
            cell.setImage(category.categoryImage, category: .category)
            cell.imageView.contentMode = .scaleAspectFill
            cell.showBlurTextView()
            cell.filter.alpha = 0.0
            
        } else if let imageList = self.dataSource as? [ImageBucket] {
             let imageData: ImageBucket = imageList[indexPath.row]
                
                cell.imageView.mm_setImageWithURL(ImageURLFactory.URLSize1000(imageData.imageKey, category: imageData.imageCategory), placeholderImage : UIImage(named: "holder"), contentMode: UIViewContentMode.scaleAspectFill)
                cell.filter.alpha = 0.0
                
                //Make sure blur view don't appear
                cell.hideBlurTextView()
                cell.label.text = ""
//                cell.imageView.setupImageViewer(with: self, initialIndex: indexPath.row, parentTag: indexPath.row, onOpen: { () -> Void in }, onClose: { () -> Void in })
//                cell.imageView.isFullScreenItemOnDisplay = true
                cell.imageView.contentMode = UIViewContentMode.scaleAspectFill
            
        }
        
        return cell
    }
    
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, referenceSizeForHeaderInSection section: Int) -> CGSize {
        return CGSize(width: 2.0, height: 0.0)
    }
    
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, referenceSizeForFooterInSection section: Int) -> CGSize {
        return CGSize(width: 2.0, height: 0.0)
    }
    
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, minimumInteritemSpacingForSectionAt section: Int) -> CGFloat {
        return 0.0
    }
    
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, minimumLineSpacingForSectionAt section: Int) -> CGFloat {
        return lineSpacingItems
    }
    
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, sizeForItemAt indexPath: IndexPath) -> CGSize {
        return CGSize(width: collectionView.bounds.sizeHeight, height: collectionView.bounds.sizeHeight)
    }
    
    func numberOfSections(in collectionView: UICollectionView) -> Int {
        return 1
    }
    
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        if dataSource != nil {
            return (dataSource?.count)!
        }
        
        return 0
    }
    
    func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        if let brandList = self.dataSource as? [BrandUnionMerchant] {
             let brand: BrandUnionMerchant = brandList[indexPath.row]
                self.delegate?.ontap(brand: brand)
            
        } else if let categoriesList = self.dataSource as? [Cat] {
             let category: Cat = categoriesList[indexPath.row]
                self.delegate?.ontap(category: category)
           
        } else if let imageBucketList = self.dataSource as? [ImageBucket] {
            if !imageBucketList.isEmpty {
                imageBucketDelegate?.ontap(imageBucketList: imageBucketList, row: indexPath.row)
            }
        }
    }
    
    //MARK: Action
    
    @objc func onTapViewAll() {
        if let _ = self.dataSource as? [BrandUnionMerchant] {
            self.delegate?.onTapBrandAll()
        } else if let _ = self.dataSource as? [Cat] {
            self.delegate?.onTapCategoryAll()
        }
    }
}
