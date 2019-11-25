//
//  MMCategoryViewController.swift
//  storefront-ios
//
//  Created by Demon on 3/9/18.
//  Copyright © 2018年 WWE & CO. All rights reserved.
//

import UIKit
import MJRefresh

class MMCategoryViewController: MMUIController {
    
    private let columNumber: CGFloat = 4.0
    private final var navigationSearchBarBtn: UIButton!
    private final var allCategoryCats = [Cat]()
    fileprivate final var currentIndex = 0
    fileprivate final var isAnimation = false
    fileprivate final var rightCollectionCategories = [Cat]()
    fileprivate final var substitutionCollectionCategories = [Cat]()
    
    private final var tabbarHeight: CGFloat {
        get {
            var h = TabbarHeight
            if self.navigationController?.viewControllers.count ?? 0 > 1 {
                h = 0
            }
            return h
        }
    }
    
    override func onViewDidLoad() {
        super.onViewDidLoad()

        setNavigationBar()
  
        self.view.addSubview(self.substitutionCollectionView)
        self.view.addSubview(self.leftcategoryTableView)
        self.view.addSubview(self.rightCollectionView)
        self.addChildViewController(self.hotcategoryVC)
        self.view.addSubview(self.hotcategoryVC.view)
        if #available(iOS 11.0, *) {
            self.substitutionCollectionView.contentInsetAdjustmentBehavior = .never
            self.rightCollectionView.contentInsetAdjustmentBehavior = .never
        } else {
            self.automaticallyAdjustsScrollViewInsets = false
        }
        
        self.loadData()
    }
    
    private func loadData() {
        showLoading()
        CacheManager.sharedManager.fetchAllCategories { (categories, nextPage, error) in
            self.stopLoading()
            self.allCategoryCats = categories ?? []
            self.allCategoryCats = self.allCategoryCats.filter({($0.categoryList?.count ?? 0) > 0})
            let recommandCat = Cat()
            recommandCat.categoryNameOrigin = String.localize("LB_CA_CATEGORY_FIRST_HOT")
            recommandCat.categoryList = [Cat]()
            self.allCategoryCats.insert(recommandCat, at: 0)
            
            if self.allCategoryCats.count > 1 {
                let firstCategories = self.allCategoryCats[1]
                var seconds = [Cat]()
                seconds = firstCategories.categoryList!.filter({$0.isShow != 0})
                seconds.forEach { (level3) in
                    level3.categoryList = level3.categoryList?.filter({$0.isShow != 0})
                }
                self.rightCollectionCategories = seconds
                self.substitutionCollectionCategories = seconds
                self.substitutionCollectionView.reloadData()
                self.rightCollectionView.reloadData()
            }
        }
    }
    
    override func onViewWillAppear(_ animated: Bool) {
        super.onViewWillAppear(animated)
        setSearchBarPlaceHolder()
    }
    
    @objc private func openChatView() {
        Navigator.shared.dopen(Navigator.mymm.imLanding)
    }
    
    @objc private func backButtonClicked() {
        navigationController?.popViewController(animated: true)
    }
    
    @objc private func searchClicked() {
        let searchViewController = ProductListSearchViewController()
        self.navigationController?.push(searchViewController, animated: false)
    }
    
    private func setSearchBarPlaceHolder() {
        let histories = Context.getHistory()
        if histories.count > 0 {
            navigationSearchBarBtn.setTitle(" " + histories.first!, for: .normal)
        } else if let hotTerms = CacheManager.sharedManager.hotSearchTerms, hotTerms.count > 0 {
            navigationSearchBarBtn.setTitle(" " + hotTerms[0].searchTerm, for: .normal)
        } else {
            navigationSearchBarBtn.setTitle(" " + String.localize("LB_CA_HOMEPAGE_SEARCH"), for: .normal)
        }
    }
    
    // MARK: -  lazyload
    
    fileprivate lazy var hotcategoryVC: MMHotCategoryViewController = {
        let v = MMHotCategoryViewController()
        v.categoryControllerDelegate = self
        v.view.frame = CGRect(x: self.view.width/columNumber, y: StartYPos, width: self.view.width - self.view.width/columNumber, height: self.view.height - StartYPos - tabbarHeight)
        return v
    }()
    
    fileprivate lazy var leftcategoryTableView: UITableView = {
        let tv = UITableView(frame: CGRect(x: 0, y: StartYPos, width: self.view.width/columNumber, height: self.view.height - StartYPos - tabbarHeight), style: .plain)
        tv.backgroundColor = UIColor(hexString: "#F5F5F5")
        tv.separatorStyle = .none
        tv.rowHeight = 53
        tv.delegate = self
        tv.dataSource = self
        tv.showsVerticalScrollIndicator = false
        tv.register(MMCategoryTaleViewCell.self, forCellReuseIdentifier: "MMCategoryTaleViewCell")
        return tv
    }()
    
    fileprivate lazy var rightCollectionView: UICollectionView = {
        let ca = UICollectionView(frame: CGRect(x: self.view.width/columNumber, y: self.view.height, width: self.view.width - self.view.width/columNumber, height: self.view.height - StartYPos - tabbarHeight), collectionViewLayout: rightCollectionLayout)
        ca.delegate = self
        ca.dataSource = self
        ca.autoresizingMask = [.flexibleWidth, .flexibleHeight]
        ca.backgroundColor = UIColor.white
        ca.showsVerticalScrollIndicator = false
        ca.register(MMCategoryContentCollectionCell.self, forCellWithReuseIdentifier: "MMCategoryContentCollectionCell")
        ca.register(MMCategoryCollectionHeaderView.self, forSupplementaryViewOfKind: UICollectionElementKindSectionHeader, withReuseIdentifier: "MMCategoryCollectionHeaderView")
        ca.mj_header = MJRefreshHeader(refreshingTarget: self, refreshingAction: #selector(self.categoryScrollPreviousPage))
        ca.mj_footer = MJRefreshBackFooter(refreshingTarget: self, refreshingAction: #selector(self.hotCategoryScrollToNextPage))
        ca.tag = 100
        return ca
    }()
    
    fileprivate lazy var substitutionCollectionView: UICollectionView = {
        let ca = UICollectionView(frame: CGRect(x: self.view.frame.width/columNumber, y: self.view.height, width: self.view.width - self.view.width/columNumber, height: self.view.height - StartYPos - tabbarHeight), collectionViewLayout: substitutionLayouts)
        ca.delegate = self
        ca.dataSource = self
        ca.autoresizingMask = [.flexibleWidth, .flexibleHeight]
        ca.backgroundColor = UIColor.white
        ca.showsVerticalScrollIndicator = false
        ca.register(MMCategoryContentCollectionCell.self, forCellWithReuseIdentifier: "MMCategoryContentCollectionCell")
        ca.register(MMCategoryCollectionHeaderView.self, forSupplementaryViewOfKind: UICollectionElementKindSectionHeader, withReuseIdentifier: "MMCategoryCollectionHeaderView")
        ca.mj_header = MJRefreshHeader(refreshingTarget: self, refreshingAction: #selector(self.categoryScrollPreviousPage))
        ca.mj_footer = MJRefreshBackFooter(refreshingTarget: self, refreshingAction: #selector(self.hotCategoryScrollToNextPage))
        ca.tag = 101
        return ca
    }()
    
    lazy var rightCollectionLayout: UICollectionViewFlowLayout = {
        let layout = UICollectionViewFlowLayout()
        layout.minimumLineSpacing = 27
        layout.minimumInteritemSpacing = 0
        layout.itemSize = CGSize(width: self.view.frame.width/columNumber, height: 87)
        layout.headerReferenceSize = CGSize(width: self.view.frame.width/columNumber*3.0, height: 40)
        layout.sectionInset = UIEdgeInsets(top: 10, left: 0, bottom: 10, right: 0)
        layout.scrollDirection = .vertical
        return layout
    }()
    
    lazy var substitutionLayouts: UICollectionViewFlowLayout = {
        let layout = UICollectionViewFlowLayout()
        layout.minimumLineSpacing = 27
        layout.minimumInteritemSpacing = 0
        layout.itemSize = CGSize(width: self.view.frame.width/columNumber, height: 87)
        layout.headerReferenceSize = CGSize(width: self.view.frame.width/columNumber*3.0, height: 40)
        layout.sectionInset = UIEdgeInsets(top: 10, left: 0, bottom: 10, right: 0)
        layout.scrollDirection = .vertical
        return layout
    }()
}

// MARK: -  处理翻页效果
extension MMCategoryViewController {
    
    @objc private func categoryScrollPreviousPage() {
        self.rightCollectionView.mj_header.endRefreshing()
        self.substitutionCollectionView.mj_header.endRefreshing()
        if self.isAnimation { return }
        self.isAnimation = true
        
        currentIndex -= 1
        if currentIndex > 0 {
            self.hotcategoryVC.view.origin.y = -self.view.frame.height
        }
        
        let seconds = getSecondCats()
        
        if self.currentIndex == 0 {
            self.hotcategoryVC.hotCategoryCollectionView.scrollToTopAnimated(false)
            delay(delayBlock: {
            }, animationBlock: {
                self.hotcategoryVC.view.frame.originY = StartYPos
                self.substitutionCollectionView.frame.originY = self.view.height
                self.rightCollectionView.frame.originY = self.view.height
            }) {
                self.isAnimation = false
                self.leftcategoryTableView.reloadData()
            }
        } else {
            if self.rightCollectionView.frame.originY == StartYPos {
                self.substitutionCollectionCategories = seconds
                self.substitutionCollectionView.reloadData()
                self.substitutionCollectionView.frame.originY = -self.view.height
                self.substitutionCollectionView.scrollToTopAnimated(false)
                delay(delayBlock: {
                }, animationBlock: {
                    self.substitutionCollectionView.frame.originY = StartYPos
                    self.rightCollectionView.frame.originY = self.view.height
                }) {
                    self.isAnimation = false
                    self.leftcategoryTableView.reloadData()
                }
            } else {
                self.rightCollectionCategories = seconds
                self.rightCollectionView.reloadData()
                self.rightCollectionView.frame.originY = -self.view.height
                self.rightCollectionView.scrollToTopAnimated(false)
                delay(delayBlock: {
                }, animationBlock: {
                    self.rightCollectionView.frame.originY = StartYPos
                    self.substitutionCollectionView.frame.originY = self.view.height
                }) {
                    self.isAnimation = false
                    self.leftcategoryTableView.reloadData()
                }
            }
        }
    }
    
    @objc private func hotCategoryScrollToNextPage() {
        self.rightCollectionView.mj_footer.endRefreshing()
        self.substitutionCollectionView.mj_footer.endRefreshing()
        if self.isAnimation { return }
        if currentIndex + 1 >= self.allCategoryCats.count { return }
        self.isAnimation = true
        self.hotcategoryVC.view.origin.y = -self.view.frame.height
        
        currentIndex += 1
        let seconds = getSecondCats()
        
        if self.rightCollectionView.frame.originY == StartYPos {
            self.substitutionCollectionCategories = seconds
            self.substitutionCollectionView.reloadData()
            self.substitutionCollectionView.frame.originY = self.view.height
            self.substitutionCollectionView.scrollToTopAnimated(false)
            delay(delayBlock: {
            }, animationBlock: {
                self.rightCollectionView.frame.originY = -self.view.height
                self.substitutionCollectionView.frame.originY = StartYPos
            }) {
                self.isAnimation = false
                self.leftcategoryTableView.reloadData()
            }
        } else {
            self.rightCollectionCategories = seconds
            self.rightCollectionView.reloadData()
            self.rightCollectionView.frame.originY = self.view.height
            self.rightCollectionView.scrollToTopAnimated(false)
            delay(delayBlock: {
            }, animationBlock: {
                self.substitutionCollectionView.frame.originY = -self.view.height
                self.rightCollectionView.frame.originY = StartYPos
            }) {
                self.isAnimation = false
                self.leftcategoryTableView.reloadData()
            }
        }
    }
    
    public func hotCategoryNextPage() {
        if self.isAnimation { return }
        self.isAnimation = true
        currentIndex += 1
        self.rightCollectionCategories = getSecondCats()
        self.rightCollectionView.reloadData()
        
        self.rightCollectionView.frame.originY = self.view.height
        self.substitutionCollectionView.frame.originY = self.view.height

        self.rightCollectionView.scrollToTopAnimated(false)
        delay(delayBlock: {
        }, animationBlock: {
            self.hotcategoryVC.view.origin.y = -self.view.frame.height
            self.rightCollectionView.origin.y = StartYPos
        }) {
            self.isAnimation = false
            self.leftcategoryTableView.reloadData()
        }
    }
    
    private func getSecondCats() -> [Cat] {
        var seconds = [Cat]()
        let firstLevelCategory = self.allCategoryCats[currentIndex]
        if let categoryList = firstLevelCategory.categoryList, categoryList.count > 0 {
            seconds = categoryList.filter({$0.isShow != 0})
            seconds.forEach { (level3Cats) in
                level3Cats.categoryList = level3Cats.categoryList?.filter({$0.isShow != 0})
            }
        }
        return seconds
    }
    
    private func delay(delayBlock:(() -> Void)? = nil, animationBlock:(() -> Void)? = nil, completion: (() -> Void)? = nil) {
        DispatchQueue.main.asyncAfter(deadline: DispatchTime.now() + 0.3) {
            if let dblock = delayBlock {
                dblock()
            }
            UIView.animate(withDuration: 0.3, animations: {
                if let animation = animationBlock {
                    animation()
                }
            }, completion: { (_) in
                if let com = completion {
                    com()
                }
            })
        }
    }
}

extension MMCategoryViewController: UITableViewDataSource, UITableViewDelegate {
    
    func numberOfSections(in tableView: UITableView) -> Int {
        return 1
    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return self.allCategoryCats.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "MMCategoryTaleViewCell", for: indexPath) as! MMCategoryTaleViewCell
        cell.selectionStyle = .none
        cell.isSelectedCell = currentIndex == indexPath.row
        cell.setupModel(cat: self.allCategoryCats[indexPath.row])
        let cat = self.allCategoryCats[indexPath.row]
        cell.track_visitId = "category.menu.0.CATEGORY.\(cat.categoryId).\(indexPath.row)"
        return cell
    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        if self.isAnimation {
            return
        }
        if currentIndex == indexPath.row {
            return
        }
        currentIndex = indexPath.row
        if indexPath.row == 0 {
            self.hotcategoryVC.view.frame.originY = StartYPos
            self.rightCollectionView.frame.originY = self.view.height
            self.substitutionCollectionView.frame.originY = self.view.height
            self.view.bringSubview(toFront: self.hotcategoryVC.view)
        } else {
            let firstLevelCategory = self.allCategoryCats[indexPath.row]
            var seconds = [Cat]()
            if let categoryList = firstLevelCategory.categoryList, categoryList.count > 0 {
                seconds = categoryList.filter({$0.isShow != 0})
                seconds.forEach { (level3Cats) in
                    level3Cats.categoryList = level3Cats.categoryList?.filter({$0.isShow != 0})
                }
                self.rightCollectionCategories = seconds
                self.rightCollectionView.reloadData()
            }
            self.rightCollectionView.frame.originY = StartYPos
            self.rightCollectionView.scrollToTopAnimated(false)
            self.view.bringSubview(toFront: self.rightCollectionView)
            
            self.substitutionCollectionView.frame.originY = self.view.height
            self.hotcategoryVC.view.frame.originY = -self.view.height
        }
        leftcategoryTableView.reloadData()
    }
}

extension MMCategoryViewController: UICollectionViewDataSource, UICollectionViewDelegate {
 
    func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        let cell = collectionView.cellForItem(at: indexPath) as! MMCategoryContentCollectionCell
        let cat = cell.option
        // 跳转PLP
        if let cat = cat {
            var params = QBundle()
            params["cat"] = QValue(cat.categoryId)
            params["title"] = QValue(cat.categoryName)//设置title
            Navigator.shared.dopen(Navigator.mymm.deeplink_l, params:params)
        }
    }
    
    func numberOfSections(in collectionView: UICollectionView) -> Int {
        if collectionView == self.rightCollectionView {
            return self.rightCollectionCategories.count
        } else {
            return self.substitutionCollectionCategories.count
        }
    }
    
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        if collectionView == self.rightCollectionView {
            let number = self.rightCollectionCategories[section].categoryList?.count
            if let num = number {
                return num
            }
            return 0
        } else {
            let number = self.substitutionCollectionCategories[section].categoryList?.count
            if let num = number {
                return num
            }
            return 0
        }
    }
    
    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        if collectionView == self.rightCollectionView {
            let cell = collectionView.dequeueReusableCell(withReuseIdentifier: "MMCategoryContentCollectionCell", for: indexPath) as! MMCategoryContentCollectionCell
            cell.option = self.rightCollectionCategories[indexPath.section].categoryList?[indexPath.row]
            //埋点需要
            if let cat = cell.option {
                cell.track_visitId = "category.section.\(indexPath.section).CATEGORY.\(cat.categoryId).\(indexPath.row + 1)"//查看全部为index==0
            }
            return cell
        } else {
            let cell = collectionView.dequeueReusableCell(withReuseIdentifier: "MMCategoryContentCollectionCell", for: indexPath) as! MMCategoryContentCollectionCell
            cell.option = self.substitutionCollectionCategories[indexPath.section].categoryList?[indexPath.row]            //埋点需要
            if let cat = cell.option {
                cell.track_visitId = "category.section.\(indexPath.section).CATEGORY.\(cat.categoryId).\(indexPath.row + 1)"//查看全部为index==0
            }
            return cell
        }
    }
    
    func collectionView(_ collectionView: UICollectionView, viewForSupplementaryElementOfKind kind: String, at indexPath: IndexPath) -> UICollectionReusableView {
       let headView = collectionView.dequeueReusableSupplementaryView(ofKind: UICollectionElementKindSectionHeader, withReuseIdentifier: "MMCategoryCollectionHeaderView", for: indexPath) as! MMCategoryCollectionHeaderView
        let secondCat: Cat!
        if collectionView == self.rightCollectionView {
            secondCat = self.rightCollectionCategories[indexPath.section]
        } else {
            secondCat = self.substitutionCollectionCategories[indexPath.section]
        }
        headView.titleText = secondCat.categoryNameOrigin
        headView.selelctedAllBtnBlock = {
            var params = QBundle()
            params["cat"] = QValue(secondCat.categoryId)
            params["title"] = QValue(secondCat.categoryName)//设置title
            Navigator.shared.dopen(Navigator.mymm.deeplink_l, params:params)
        }
        headView.selectedAllBtn.track_visitId = "category.section.\(indexPath.section).CATEGORY.\(secondCat.categoryId).0" //查看全部为index==0
        return headView
    }
}

extension MMCategoryViewController {

    private func setNavigationBar() {
        if let nav = self.navigationController,nav.viewControllers.count > 1 {
            self.navigationItem.leftBarButtonItem = UIBarButtonItem(image: UIImage(named: "back_grey")?.withRenderingMode(.alwaysOriginal), style: .plain, target: self, action: #selector(self.backButtonClicked))
        } else {
            self.navigationItem.leftBarButtonItem = UIBarButtonItem.menuButtonItem(self, action: #selector(self.showLeftMenuView))
        }
        self.navigationItem.rightBarButtonItem = UIBarButtonItem.messageButtonItem(self, action: #selector(self.openChatView))
        setupSearchBar()
    }
    
    private func setupSearchBar() {
        let searchBarContainer = UIView(frame: CGRect(x: 0, y: 0, width: (self.navigationController?.navigationBar.width)! * 0.7, height: 32))
        searchBarContainer.backgroundColor = UIColor(hexString: "#F5F5F5")
        let searchBarBtn = UIButton(type: .custom)
        searchBarBtn.setImage(UIImage(named: "btn_Search"), for: .normal)
        searchBarBtn.setTitleColor(UIColor(hexString: "#BCBCBC"), for: .normal)
        searchBarBtn.setTitle(" " + String.localize("LB_CA_HOMEPAGE_SEARCH"), for: .normal)
        searchBarBtn.addTarget(self, action: #selector(self.searchClicked), for: UIControlEvents.touchUpInside)
        searchBarBtn.frame = CGRect(x: 5, y: 0, width: searchBarContainer.frame.width - 10, height: searchBarContainer.frame.height)
        searchBarBtn.titleLabel?.font = UIFont(name: "Helvetica", size: 12)
        searchBarContainer.round(4)
        searchBarContainer.addSubview(searchBarBtn)
        navigationSearchBarBtn = searchBarBtn
        self.navigationItem.titleView = searchBarContainer
    }
}
