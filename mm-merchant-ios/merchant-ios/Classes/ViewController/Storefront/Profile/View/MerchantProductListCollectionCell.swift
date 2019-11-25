//
//  MerchantProductListCollectionCell.swift
//  merchant-ios
//
//  Created by khanh.nguyen on 7/1/16.
//  Copyright © 2016 WWE & CO. All rights reserved.
//

import UIKit
// FIXME: comparison operators with optionals were removed from the Swift Standard Libary.
// Consider refactoring the code to use the non-optional operators.
private func < <T : Comparable>(lhs: T?, rhs: T?) -> Bool {
  switch (lhs, rhs) {
  case let (l?, r?):
    return l < r
  case (nil, _?):
    return true
  default:
    return false
  }
}

// FIXME: comparison operators with optionals were removed from the Swift Standard Libary.
// Consider refactoring the code to use the non-optional operators.
private func > <T : Comparable>(lhs: T?, rhs: T?) -> Bool {
  switch (lhs, rhs) {
  case let (l?, r?):
    return l > r
  default:
    return rhs < lhs
  }
}

private let sectionInsets = UIEdgeInsets(top: Constants.Margin.Left, left: Constants.Margin.Left, bottom: 0.0, right: Constants.Margin.Right)

protocol MerchantProductListDelegate : NSObjectProtocol { //Prevent memory leak
    func didSelectedHeartImageView(_ style: Style, cell: ProductCollectionViewCell)
    func didselctedProduct(_ style: Style)
}

class MerchantProductListCollectionCell: UICollectionViewCell, UICollectionViewDataSource, UICollectionViewDelegate, UICollectionViewDelegateFlowLayout, ProductCellDelegate, UIScrollViewDelegate {
    
    static let CellIdentifier = "Cell"
    let Padding = CGFloat(16)
    let PaddingLeft = CGFloat(16)
    let PaddingRight = CGFloat(16)
    
    weak var delegate: MerchantProductListDelegate? //Prevent memory leak
    weak var ownerViewController: MmViewController?
    
    var collectionView : UICollectionView!
    var styles : [Style] = []
    var filteredStyles : [Style] = []
    var merchant:Merchant?
    var leftView = UIView()
    var rightView = UIView()
    var titleLabel = UILabel()
    private var lineSize: CGSize?
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        self.initCollectionView()
    }
    override func layoutSubviews() {
        super.layoutSubviews()
        
        if let lineSize = self.lineSize{
            leftView.frame = CGRect(x: titleLabel.frame.minX - Padding - lineSize.width, y: titleLabel.frame.midY - lineSize.height / 2, width: lineSize.width, height: lineSize.height)
            rightView.frame = CGRect(x: titleLabel.frame.maxX + Padding, y: titleLabel.frame.midY - lineSize.height / 2, width: lineSize.width, height: lineSize.height)
        }
        else{
            leftView.frame = CGRect(x: PaddingLeft, y: titleLabel.frame.midY - height / 2, width: width - PaddingLeft, height: height)
            rightView.frame = CGRect(x: titleLabel.frame.maxX + Padding , y: titleLabel.frame.midY - height / 2, width: width - PaddingRight, height: height)
        }
        
    }
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    func initCollectionView() {
        let brandLayout: UICollectionViewFlowLayout = UICollectionViewFlowLayout()
        brandLayout.sectionInset = UIEdgeInsets(top: 0, left: 0, bottom: 0, right: 0)
        brandLayout.scrollDirection = UICollectionViewScrollDirection.horizontal
        
        let headerView = UIView()
        headerView.frame = CGRect(x: 0, y: 0, width: self.bounds.sizeWidth, height: 60)
        headerView.backgroundColor = UIColor.white
        self.contentView.addSubview(headerView)
        
        leftView.backgroundColor = UIColor.secondary1()
        rightView.backgroundColor = UIColor.secondary1()
        
        headerView.addSubview(leftView)
        headerView.addSubview(rightView)
        
        titleLabel.text = String.localize("LB_CA_NEW_PRODUCTS")
        if let fontBold = UIFont(name: Constants.Font.Bold, size: 16) {
            titleLabel.font = fontBold
        } else {
            titleLabel.formatSizeBold(16)
        }
        titleLabel.textColor = UIColor.black
        headerView.addSubview(titleLabel)
        
        let marginBottom = CGFloat(5)
        let frame = CGRect(x: bounds.minX, y: headerView.frame.maxY, width: bounds.width, height: self.bounds.height - headerView.frame.sizeHeight - marginBottom)
        collectionView = UICollectionView(frame: frame, collectionViewLayout: brandLayout)
        collectionView.showsHorizontalScrollIndicator = false
        collectionView.backgroundColor = UIColor.white
        collectionView.register(ProductCollectionViewCell.self, forCellWithReuseIdentifier: CollectCellId)
        collectionView.delegate = self
        collectionView.dataSource = self
        collectionView.alwaysBounceVertical = false
        self.contentView.addSubview(collectionView)
        
    }
    
    func formatStyle(_ textFont: UIFont? = nil, textColor: UIColor, lineColor: UIColor, lineSize: CGSize){
        if let textFont = textFont{
            titleLabel.font = textFont
        }
        else if let fontBold = UIFont(name: Constants.Font.Bold, size: 16) {
            titleLabel.font = fontBold
        } else {
            titleLabel.formatSizeBold(16)
        }
        
        titleLabel.textColor = textColor
        leftView.backgroundColor = lineColor
        rightView.backgroundColor = lineColor
        
        let originY = CGFloat(28)
        let textWidth = StringHelper.getTextWidth(titleLabel.text ?? "", height: HomeHeaderView.LabelHeight, font: titleLabel.font)
        titleLabel.frame = CGRect(x: (bounds.sizeWidth - textWidth) / 2,  y: originY, width: textWidth, height: HomeHeaderView.LabelHeight)
        
        self.lineSize = lineSize
        leftView.frame = CGRect(x: titleLabel.frame.minX - Padding - lineSize.width, y: titleLabel.frame.midY - lineSize.height / 2, width: lineSize.width, height: lineSize.height)
        rightView.frame = CGRect(x: titleLabel.frame.maxX + Padding, y: titleLabel.frame.midY - lineSize.height / 2, width: lineSize.width, height: lineSize.height)
    }
    
    func reloadData(_ styles: [Style], filteredStyles: [Style]) {
        self.styles = styles
        self.filteredStyles = filteredStyles
        self.collectionView.reloadData()
    }
    
    //MARK:- Product Cell Delegate
    func didTapOnHeartIcon(_ cell: ProductCollectionViewCell) {
        guard LoginManager.getLoginState() == .validUser else {
            LoginManager.goToLogin()
            return
        }
        if let style = cell.style {
            delegate?.didSelectedHeartImageView(style, cell: cell)
        }
    }
    
    //MARK: - CollectionView datasources
    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        
        let cell = collectionView.dequeueReusableCell(withReuseIdentifier: CollectCellId, for: indexPath) as! ProductCollectionViewCell
        
        cell.ownerViewController = self.ownerViewController
        
        if (filteredStyles.count > indexPath.row) {
            let style = self.filteredStyles[indexPath.row]
            var skuName = ""
            var skuCode = ""
            if let defaultSku = style.defaultSku() {
                
                skuName = defaultSku.skuName
                skuCode = defaultSku.skuCode
                cell.nameLabel.text = skuName
                cell.fillPrice(defaultSku.priceSale, priceRetail: defaultSku.priceRetail, isSale: defaultSku.isSale)
                
                ProductManager.setProductImage(imageView: cell.imageView, style: style, colorKey: defaultSku.colorKey, size: .size256, placeholderImage: UIImage(named: "holder"))
                
                let selectedSizeId = style.defaultSku()?.sizeId ?? 0
                var savedSku = style.searchSku(selectedSizeId, colorId: defaultSku.colorId, skuColor: defaultSku.colorKey)
                
                if savedSku == nil{
                    savedSku = style.defaultSku()
                }
                
                if savedSku!.isWished() {
                    cell.heartImageView.image = UIImage(named: "ic_red_star_plp")
                } else {
                    cell.heartImageView.image = UIImage(named: "ic_grey_star_plp")
                }
            }
            
            cell.nameLabel.lineBreakMode = NSLineBreakMode.byWordWrapping
            cell.nameLabel.numberOfLines = 2
            cell.nameLabel.textAlignment = .center
            
            
            cell.delegate = self
            cell.style = style
            cell.setBrandImage(style.brandHeaderLogoImage)
            
//            cell.accessibilityIdentifier = "discover_view_cell_\(indexPath.section)_\(indexPath.row)"
//            
//            cell.heartImageView.isAccessibilityElement = true
//            cell.heartImageView.accessibilityIdentifier = "heart_imageview_\(indexPath.section)_\(indexPath.row)"
            
            if style.badgeImage.isEmpty {
                cell.badgeImageView.isHidden = true
            } else {
                cell.badgeImageView.isHidden = false
                cell.setBadgeImage(style.badgeImage, isProductList: true)
            }
            
            if let viewKey = self.analyticsViewKey{
                if let merchant = self.merchant, self.merchant?.merchantName.length > 0{
                    cell.initAnalytics(withViewKey: viewKey, impressionKey: AnalyticsManager.sharedManager.recordImpression(authorType: nil, brandCode: nil, impressionRef: "\(style.styleCode)", impressionType: "Product", impressionVariantRef: skuCode, impressionDisplayName: skuName, merchantCode: merchant.merchantCode, parentRef: nil, parentType: nil, positionComponent: "NewProducts", positionIndex: (indexPath.row + 1), positionLocation: "MPP", referrerRef: nil, referrerType: nil, viewKey: viewKey))
                }
            }
        }
        
        return cell
    }
    
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        
        return filteredStyles.count
    }
    
    //MARK:- CollectionView Delegate
    func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        Log.debug("cell no: \(indexPath.row) of collection view: \(collectionView.tag)")
        
        if !self.filteredStyles.isEmpty {
            
            if let cell = self.collectionView.cellForItem(at: indexPath) as? ProductCollectionViewCell {
                
                let style = self.filteredStyles[indexPath.row]
                cell.recordAction(.Tap, sourceRef: style.styleCode, sourceType: .Product, targetRef: "PDP", targetType: .View)
                
                delegate?.didselctedProduct(filteredStyles[indexPath.row])
            }
        }
        
    }
    
    
    
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, sizeForItemAt indexPath: IndexPath) -> CGSize {
        var width = (Constants.ScreenSize.SCREEN_WIDTH - (Constants.Margin.Left + Constants.Margin.Right + Constants.LineSpacing.ImageCell)) / 3
        width += 30
        return CGSize(width: width, height: getSuggestionCellWidth() * Constants.Ratio.ProductImageHeight + Constants.Value.BrandImageHeight + 14)
    }
    
    func getSuggestionCellWidth() -> CGFloat {
        return (Constants.ScreenSize.SCREEN_WIDTH - (Constants.Margin.Left + Constants.Margin.Right + Constants.LineSpacing.ImageCell)) / 2
    }
    
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, insetForSectionAt section: Int) -> UIEdgeInsets {
        return sectionInsets
    }
    
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, minimumInteritemSpacingForSectionAt section: Int) -> CGFloat {
        return 0.0
    }
    
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, minimumLineSpacingForSectionAt section: Int) -> CGFloat {
        return Constants.LineSpacing.ImageCell
    }
    
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, referenceSizeForHeaderInSection section: Int) -> CGSize{
        return CGSize(width: 0,height: 0)
    }
    
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, referenceSizeForFooterInSection section: Int) -> CGSize{
        return CGSize(width: 0,height: 0)
    }

    func scrollViewWillEndDragging(_ scrollView: UIScrollView, withVelocity velocity: CGPoint, targetContentOffset: UnsafeMutablePointer<CGPoint>) {
        
        
    }
    
    func scrollViewWillBeginDragging(_ scrollView: UIScrollView) {
        collectionView.analyticsViewKey = self.analyticsViewKey
        collectionView.recordAction(.Swipe, sourceRef: "MPP", sourceType: .Product, targetRef: "MoreNewProduct", targetType: .View)
    }
}
