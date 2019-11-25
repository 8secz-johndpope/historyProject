//
//  MMHotCatetoryViewController.swift
//  storefront-ios
//
//  Created by Demon on 17/8/18.
//  Copyright © 2018年 WWE & CO. All rights reserved.
//

import UIKit
import MJRefresh

class MMHotCategoryViewController: MMUIController {

    weak var categoryControllerDelegate: MMCategoryViewController?

    fileprivate var itemCellWidth: CGFloat {
        get {
            return CGFloat((ScreenWidth - 75.0)/4.0)
        }
    }
    
    private var hotCategories = [Cat]()
    private var hotBrands = [Brand]()
    
    override func onViewDidLoad() {
        super.onViewDidLoad()
        view.addSubview(hotCategoryCollectionView)
        if #available(iOS 11.0, *) {
            self.hotCategoryCollectionView.contentInsetAdjustmentBehavior = .never
        } else {
            self.automaticallyAdjustsScrollViewInsets = false
        }
        loadData()
    }
    
    override func onViewWillAppear(_ animated: Bool) {
        super.onViewWillAppear(animated)
    }
    
    private func loadData() {
        let hotBrandURL = Constants.Path.Host + "/hot/brands"
        let hotCategoryURL = Constants.Path.Host + "/hot/categories"
        
        HTTPAccesser.get(hotCategoryURL) { (response: GeneralResponse<Cat>) in
            if response.success {
                self.hotCategories = response.results
                self.hotCategoryCollectionView.reloadData()
            } else {
                self.showFailPopupWithText("网络连接错误")
            }
        }
        
        HTTPAccesser.get(hotBrandURL) { (response: GeneralResponse<Brand>) in
            if response.success {
                self.hotBrands = response.results
                self.hotCategoryCollectionView.reloadData()
            } else {
                self.showFailPopupWithText("网络连接错误")
            }
        }
    }
  
    lazy var hotCategoryCollectionView: UICollectionView = {
        let layout = UICollectionViewFlowLayout()
        let collectionView = UICollectionView(frame: self.view.bounds, collectionViewLayout: layout)
        collectionView.autoresizingMask = [.flexibleWidth, .flexibleHeight]
        collectionView.dataSource = self
        collectionView.delegate = self
        collectionView.alwaysBounceVertical = true
        collectionView.showsVerticalScrollIndicator = false
        collectionView.backgroundColor = UIColor.white
        collectionView.register(MMCategoryContentCollectionCell.self, forCellWithReuseIdentifier: "MMCategoryContentCollectionCell")
        collectionView.register(MMHotBrandCollectionViewCell.self, forCellWithReuseIdentifier: "MMHotBrandCollectionViewCell")
        collectionView.register(MMHotBrandCollectionHeaderView.self, forSupplementaryViewOfKind: UICollectionElementKindSectionHeader, withReuseIdentifier: "MMHotBrandCollectionHeaderView")
        collectionView.register(MMHotBrandCollectionFooterView.self, forSupplementaryViewOfKind: UICollectionElementKindSectionFooter, withReuseIdentifier: "MMHotBrandCollectionFooterView")
        collectionView.mj_footer = MJRefreshBackFooter(refreshingTarget: self, refreshingAction: #selector(self.hotCategoryScrollToNextPage))
        return collectionView
    }()
}

extension MMHotCategoryViewController: UICollectionViewDataSource, UICollectionViewDelegate, UICollectionViewDelegateFlowLayout {
    
    @objc private func hotCategoryScrollToNextPage() {
        self.hotCategoryCollectionView.mj_footer.endRefreshing()
        self.categoryControllerDelegate?.hotCategoryNextPage()
    }
    
    func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        if indexPath.section == 0 {
            // 跳转PLP
            let cat = self.hotCategories[indexPath.row]
            var params = QBundle()
            params["cat"] = QValue(cat.CategoryId ?? 0)
            params["title"] = QValue(cat.CategoryName ?? "")//设置title
            Navigator.shared.dopen(Navigator.mymm.deeplink_l, params:params)
        } else {
            let brand = self.hotBrands[indexPath.row]
            Navigator.shared.dopen(Navigator.mymm.deeplink_b_brandSubDomain + (brand.BrandSubdomain ?? ""))
        }
    }
    
    func numberOfSections(in collectionView: UICollectionView) -> Int {
        return 2
    }
    
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        if section == 0 {
            return self.hotCategories.count
        } else {
            return self.hotBrands.count
        }
    }
    
    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        if indexPath.section == 0 {
            let categoryCell = collectionView.dequeueReusableCell(withReuseIdentifier: "MMCategoryContentCollectionCell", for: indexPath) as! MMCategoryContentCollectionCell
            let cat = self.hotCategories[indexPath.row]
            categoryCell.categoryName.text = cat.CategoryName?.insertSomeStr(element: "\n", at: 6)
            categoryCell.categoryImageView.mm_setImageWithURL(ImageURLFactory.getRaw(cat.FeaturedImage ?? "", category: .category, width: Constants.DefaultImageWidth.Small), placeholderImage: UIImage(named: "brand_placeholder"), clipsToBounds: true, contentMode: .scaleAspectFit)
            return categoryCell
        } else {
            let brandCell = collectionView.dequeueReusableCell(withReuseIdentifier: "MMHotBrandCollectionViewCell", for: indexPath) as! MMHotBrandCollectionViewCell
            let brand = self.hotBrands[indexPath.row]
            brandCell.brandImageView.mm_setImageWithURL(ImageURLFactory.getRaw(brand.SmallLogoImage ?? "", category: ImageCategory.brand, width: Constants.DefaultImageWidth.Small), placeholderImage: nil)
            return brandCell
        }
    }
    
    func collectionView(_ collectionView: UICollectionView, viewForSupplementaryElementOfKind kind: String, at indexPath: IndexPath) -> UICollectionReusableView {
        if kind == UICollectionElementKindSectionHeader {
            let headerView = collectionView.dequeueReusableSupplementaryView(ofKind: UICollectionElementKindSectionHeader, withReuseIdentifier: "MMHotBrandCollectionHeaderView", for: indexPath) as! MMHotBrandCollectionHeaderView
            if indexPath.section == 0 {
                headerView.sectionText = String.localize("LB_CA_CATEGORY_HOT")
            } else {
                headerView.sectionText = String.localize("LB_CA_CATEGORY_HOT_BRANDS")
            }
            return headerView
        } else {
            let footerView = collectionView.dequeueReusableSupplementaryView(ofKind: UICollectionElementKindSectionFooter, withReuseIdentifier: "MMHotBrandCollectionFooterView", for: indexPath) as! MMHotBrandCollectionFooterView
            footerView.backgroundView.whenTapped { [weak self] in
                if let strongSelf = self {
                    strongSelf.mm_tabbarController?.setSelectIndex(index: MMTabBarType.brandPage.rawValue)
                }
            }
            return footerView
        }
    }
    
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, sizeForItemAt indexPath: IndexPath) -> CGSize {
        if indexPath.section == 0 {
            return CGSize(width: itemCellWidth, height: 87)
        }
        return CGSize(width: itemCellWidth, height: itemCellWidth)
    }
    
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, insetForSectionAt section: Int) -> UIEdgeInsets {
        return UIEdgeInsetsMake(5, 15, 10, 15)
    }
    
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, referenceSizeForHeaderInSection section: Int) -> CGSize {
        if section == 1 {
            return CGSize(width: self.view.frame.width, height: 60)
        }
        return CGSize(width: self.view.frame.width, height: 66)
    }
    
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, referenceSizeForFooterInSection section: Int) -> CGSize {
        if section == 1 {
            return CGSize(width: self.view.frame.width, height: 60)
        }
        return CGSize.zero
    }
    
}
