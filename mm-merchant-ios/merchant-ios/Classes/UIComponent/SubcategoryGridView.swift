//
//  MMGridView.swift
//  merchant-ios
//
//  Created by Kam on 19/4/2016.
//  Copyright © 2016 WWE & CO. All rights reserved.
//

import Foundation
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


protocol SubcategoryGridViewDelegate: NSObjectProtocol {
    func onBrandTapped(_ brand: BrandUnionMerchant, cate: Cat, sender: UIButton)
    func onSubcateTapped(_ subcate: Cat)
}

class SubcategoryGridView: UIView {
    
    private final let CategoryHeaderHeight: CGFloat = 60
    private final var BrandRowHeight: CGFloat = 104
    private final let SubcategoryRowHeight: CGFloat = 100
    private final let NumberOfBrandColumn: CGFloat = 4
    private final let NumberOfSubcateColumn: Float = 4
    private final var NumberOfSubcateRow: Int = 0
    
    private var headerView = UIView()
    private var headerLabel = UILabel()
    private var brandView = UIView()
    private var subcategoryView = UIView()
    
    weak var delegate: SubcategoryGridViewDelegate?
    var cate: Cat?
    fileprivate(set) var activeCategories = [Cat]()
    private var brandButtons = [UIButton]()
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        
        let width = UIScreen.main.bounds.width
        BrandRowHeight = (width / NumberOfBrandColumn) * 0.75
        
        headerView.backgroundColor = UIColor.black
        self.addSubview(headerView)
        
        headerLabel.textColor = UIColor.white
        headerLabel.backgroundColor = UIColor.clear
        headerLabel.textAlignment = .center
        headerView.addSubview(headerLabel)
        
        brandView.backgroundColor = UIColor.clear
        self.addSubview(brandView)
        
        subcategoryView.backgroundColor = UIColor.clear
        self.addSubview(subcategoryView)
    }
    
    override func layoutSubviews() {
        super.layoutSubviews()
        
        if cate?.categoryBrandMerchantList.count > 0 {
            BrandRowHeight = (width / NumberOfBrandColumn) * 0.75
        } else {
            BrandRowHeight = 0
        }
        
        headerView.frame = CGRect(x: 0, y: 0, width: width, height: CategoryHeaderHeight)
        headerLabel.frame = headerView.frame
        brandView.frame =  CGRect(x: 0, y: headerView.frame.maxY, width: width, height: BrandRowHeight)
        updateBrandButtonsFrame()
        subcategoryView.frame =  CGRect(x: 0, y: CategoryHeaderHeight+BrandRowHeight, width: width, height: calculateSubcategoryRowHeight())
    }
    
    func updateGridView(_ cat: Cat) {
        self.cate = cat
        
        if let cate = self.cate {
            self.setHeaderView(cate.categoryName)
            self.setBrandView(cate.categoryBrandMerchantList)
            
            if let categoryList = cate.categoryList {
                activeCategories = categoryList.filter({ $0.isActive() })
                
                self.setSubcategoryView(activeCategories)
            } else {
                subcategoryView.isHidden = true
            }
        } else {
            brandView.isHidden = true
            subcategoryView.isHidden = true
        }
    }
    
    func resizeGridSize() {
        self.size = CGSize(width: frame.width, height: getGridViewHeight())
        
        if let cate = self.cate {
            self.updateGridView(cate)
        }
    }
    
    private func recursiveRemoveSubviews(_ view: UIView) {
        for v in view.subviews {
            v.removeFromSuperview()
        }
    }
    
    private func setHeaderView(_ cateStr: String) {
        headerLabel.text = cateStr
    }
    
    private func setBrandView(_ brands: [BrandUnionMerchant]) {
        if brands.count == 0 {
            brandView.isHidden = true
            return
        } else {
            brandView.isHidden = false
        }
        
        recursiveRemoveSubviews(brandView)
        
        brandButtons = []
        
        let buttonSize = CGSize(width: frame.width / NumberOfBrandColumn, height: BrandRowHeight)
        
        for index in 0..<brands.count {
            let currentBrand = brands[index]
            
            let brandButton = UIButton(frame: CGRect(x: CGFloat(index) * buttonSize.width, y: 0, width: buttonSize.width, height: buttonSize.height))
            brandButton.tag = index
            brandButton.addTarget(self, action: #selector(openBrand), for: .touchUpInside)
            
            if !self.isHidden {
                brandButton.mm_setImageWithURL(ImageURLFactory.URLSize256(currentBrand.headerLogoImage, category: currentBrand.imageCategory), forState: UIControlState(), placeholderImage: nil)
            }
            
            brandButton.imageEdgeInsets = UIEdgeInsets(top: 14, left: 20, bottom: 14, right: 20)
            brandButton.imageView?.contentMode = .scaleAspectFit
            
            brandView.addSubview(brandButton)
            
            brandButtons.append(brandButton)
            
            if !self.isHidden {
                if let viewKey = self.analyticsViewKey {
                    brandButton.initAnalytics(withViewKey: viewKey, impressionKey: AnalyticsManager.sharedManager.recordImpression(brandCode: currentBrand.brandCode , impressionRef: "\(currentBrand.entityId)", impressionType: "Merchant", impressionDisplayName: currentBrand.name, merchantCode: currentBrand.merchantCode, positionComponent: "ExpandedView", positionIndex: index + 1, positionLocation: "BrowseByCategory", viewKey: viewKey))
                }
            }
        }
    }
    
    private func updateBrandButtonsFrame(){
        let buttonSize = CGSize(width: frame.width / NumberOfBrandColumn, height: BrandRowHeight)
        
        for brandButton in brandButtons {
            if let index = brandButtons.index(of: brandButton) {
                brandButton.frame = CGRect(x: CGFloat(index) * buttonSize.width, y: 0, width: buttonSize.width, height: buttonSize.height)
            }
        }
    }
    
    private func setSubcategoryView(_ subcategories: [Cat]) {
        if subcategories.count == 0 {
            subcategoryView.isHidden = true
            
            return
        } else {
            subcategoryView.isHidden = false
        }
        
        recursiveRemoveSubviews(subcategoryView)
        
        let topPadding: CGFloat = 10
        let imageSize = CGSize(width: 60, height: 60)
        let buttonSize = CGSize(width: floor(frame.width / CGFloat(NumberOfSubcateColumn)), height: SubcategoryRowHeight)
        
        if subcategories.count > 0 {
            let numOfRow = Float(Float(subcategories.count) / NumberOfSubcateColumn)
            NumberOfSubcateRow = Int(ceil(numOfRow))
            var index = 0
            
            for row in 0..<NumberOfSubcateRow {
                for column in 0..<Int(NumberOfSubcateColumn) {
                    let currentSubcat = subcategories[index]
                    
                    let frame = CGRect(x: CGFloat(column) * buttonSize.width, y: CGFloat(row) * buttonSize.height, width: buttonSize.width, height: buttonSize.height)
                    
                    let view = UIView(frame: frame)
                    
                    let imageView = UIImageView(frame: CGRect(x: (frame.width - imageSize.width) / 2, y: topPadding, width: imageSize.width, height: imageSize.height))
                    view.addSubview(imageView)
                    
                    let label = UILabel(frame: CGRect(x: 0, y: imageView.frame.maxY, width: frame.width, height: SubcategoryRowHeight - imageSize.height - (topPadding * 2)))
                    label.formatSize(12)
                    label.textColor = UIColor.black
                    label.text = currentSubcat.categoryName
                    label.textAlignment = .center
                    view.addSubview(label)
                    
                    let subcategoryButton = UIButton(frame: CGRect(x: 0, y: 0, width: buttonSize.width, height: buttonSize.height))
                    subcategoryButton.tag = index
                    subcategoryButton.addTarget(self, action: #selector(SubcategoryGridView.openSubcategory), for: .touchUpInside)
                    view.addSubview(subcategoryButton)
                    subcategoryButton.accessibilityIdentifier = "UIBT_SECOND_LEVEL_CATEGORY-\(currentSubcat.categoryName)"
                    
                    subcategoryView.addSubview(view)
                    index += 1
                    
                    if currentSubcat.categoryId == DiscoverCategoryViewController.AllCategory {
                        // Change image and label position
                        let actualHeight = frame.height - (topPadding * 2)
                        
                        imageView.y = (actualHeight - imageSize.height) / 2 + topPadding
                        label.y = (actualHeight - label.height) / 2 + topPadding
                        imageView.backgroundColor = UIColor.imagePlaceholder()
                    } else {
                        if !self.isHidden {
                            imageView.mm_setImageWithURL(ImageURLFactory.URLSize256(currentSubcat.featuredImage, category: .category), placeholderImage: UIImage(named: "brand_placeholder"), clipsToBounds: true, contentMode: .scaleAspectFit)
                        }
                        
                        imageView.backgroundColor = UIColor.clear
                    }
                    
                    if index >= subcategories.count {
                        break
                    }
                }
            }
        }
        
        subcategoryView.height = SubcategoryRowHeight * CGFloat(NumberOfSubcateRow)
    }
    
    private func calculateSubcategoryRowHeight() -> CGFloat {
        return SubcategoryRowHeight * CGFloat(NumberOfSubcateRow)
    }
    
    func getGridViewHeight() -> CGFloat {
        return CategoryHeaderHeight + BrandRowHeight + calculateSubcategoryRowHeight()
    }
    
    @objc func openBrand(_ sender: UIButton) {
        if let brand = cate?.categoryBrandMerchantList[sender.tag], let category = cate {
            self.delegate?.onBrandTapped(brand, cate: category, sender: sender)
        }
    }
    
    @objc func openSubcategory(_ sender: UIButton) {
        let categoryIndex = sender.tag
        
        if categoryIndex >= 0 && categoryIndex < activeCategories.count {
            self.delegate?.onSubcateTapped(activeCategories[categoryIndex])
        }
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}
