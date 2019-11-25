//
//  FilterListBaseViewController.swift
//  merchant-ios
//
//  Created by Stephen Yuen on 17/6/2016.
//  Copyright © 2016 WWE & CO. All rights reserved.
//

import UIKit
import PromiseKit
import ObjectMapper
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


class FilterListBaseViewController: SubFilterBaseViewController {
    private final let DefaultHeaderID = "DefaultHeaderID"
    private let HeaderHeight: CGFloat = 50
    private let ImageMenuCellHeight: CGFloat = 60
    private let SearchBarHeight: CGFloat = 40
    
    var searchBar = UISearchBar()
    var refreshControl = UIRefreshControl()

    var searchString = ""
    
    override func viewDidLoad() {
        super.viewDidLoad()

        setupNoItemView()
        
        self.edgesForExtendedLayout = UIRectEdge()
        
        let layout: UICollectionViewFlowLayout = getCustomFlowLayout()
        layout.sectionInset = UIEdgeInsets(top: 0, left: 0, bottom: 0, right: 0)
        layout.itemSize = CGSize(width: self.view.frame.width, height: 120)
        filterCollectionView = UICollectionView(frame: CGRect(x: self.view.bounds.minX, y: view.bounds.minY, width: view.width, height: FilterHeaderView.DefaultHeight), collectionViewLayout: layout)
        filterCollectionView.dataSource = self
        filterCollectionView.delegate = self
        filterCollectionView.alwaysBounceVertical = false
        filterCollectionView.isScrollEnabled = false
        filterCollectionView.backgroundColor = UIColor.white
        filterCollectionView.register(FilterHeaderView.self, forSupplementaryViewOfKind: UICollectionElementKindSectionHeader, withReuseIdentifier: FilterHeaderView.ViewIdentifier)
        filterCollectionView.register(UICollectionReusableView.self, forSupplementaryViewOfKind: UICollectionElementKindSectionHeader, withReuseIdentifier: DefaultHeaderID)
        
        self.view.addSubview(filterCollectionView)

        styleFilterBackup = self.styleFilter?.clone()
        
        collectionView.register(ImageMenuCell.self, forCellWithReuseIdentifier: "ImageMenuCell")
        
        searchBar.sizeToFit()
        searchBar.delegate = self
        searchBar.searchBarStyle = UISearchBarStyle.default
        searchBar.showsCancelButton = false
        searchBar.frame = CGRect(x: view.bounds.minX, y: view.bounds.minY + FilterHeaderView.DefaultHeight, width: view.width, height: SearchBarHeight)
        view.insertSubview(searchBar, aboveSubview: collectionView)
        
        setupButtonCell()
        
        setUpRefreshControl()
    }
    
    override func viewWillLayoutSubviews() {
        super.viewWillLayoutSubviews()
        var rect = self.view.frame
        rect.size.height = Constants.ScreenSize.SCREEN_HEIGHT - rect.originY
        self.view.frame = rect
        
        let updateCollectionframe = { () -> Void in
            var collectionMinY: CGFloat = 0
            if self.styleFilter?.filterTags.count > 0{
                collectionMinY = FilterHeaderView.DefaultHeight
            }
            self.filterCollectionView.isHidden = (self.styleFilter?.filterTags.count == 0)
            self.searchBar.frame = CGRect(x: self.view.bounds.minX, y: self.view.bounds.minY + collectionMinY, width: self.view.width, height: self.SearchBarHeight)
            self.collectionView.frame = CGRect(
                x: self.view.bounds.minX,
                y: collectionMinY + self.SearchBarHeight,
                width: self.view.bounds.width,
                height: self.view.bounds.height - self.SearchBarHeight - self.ButtonCellHeight - collectionMinY
            )
        }
        
        updateCollectionframe()
        
        noItemView.frame = CGRect(x: (view.width - noItemView.width) / 2, y: (view.height + view.y - noItemView.height) / 2, width: noItemView.width, height: noItemView.height)
        
        styleFilter?.filterTagsObserver = { () -> Void in
            updateCollectionframe()
            self.filterCollectionView.reloadData()
        }
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        if !isConfirmed{
            styleFilter = styleFilterBackup
            filterStyleDelegate?.filterStyle(self.styles, styleFilter: self.styleFilter!, selectedFilterCategories: nil)
        }
    }
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    // MARK: - Setup Views
    
    func setUpRefreshControl() {
        refreshControl.addTarget(self, action: #selector(refresh(_:)), for: .valueChanged)
        collectionView.addSubview(refreshControl)
        collectionView.alwaysBounceVertical = true
    }
    
    // MARK: - Action

    override func confirm(_ sender: UIButton) {
        isConfirmed = true
    }
    
    // MARK: - Data
    
    func searchStyle() -> Promise<Any> {
        return Promise{ fulfill, reject in
            if let strongFilter = self.searchStyleFilter{
                SearchService.searchStyle(strongFilter) { [weak self] (response) in
                    if let strongSelf = self {
                        if response.result.isSuccess {
                            if let styleResponse = Mapper<SearchResponse>().map(JSONObject: response.result.value){
                                if let aggregations = styleResponse.aggregations {
                                    strongSelf.aggregations = aggregations
                                    strongSelf.styles = styleResponse.pageData ?? []
                                } else {
                                    strongSelf.aggregations = Aggregations()
                                    strongSelf.styles = []
                                }
                                
                            }
                            fulfill("OK")
                        } else {
                            reject(response.result.error!)
                        }
                    }
                }
            }
            else{
                fulfill("OK")
            }
        }
    }
    
    // MARK: - Collection view
    
    func numberOfSections(in collectionView: UICollectionView) -> Int {
        return 1
    }
    
    // MARK: - Collection view delegate flow layout
    
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, referenceSizeForHeaderInSection section: Int) -> CGSize{
        switch collectionView {
        case self.filterCollectionView:
            if section == 0{
                return CGSize(width: view.width, height: FilterHeaderView.DefaultHeight)
            }
        default:
            break
        }
        
        return CGSize.zero
    }
    
    func collectionView(_ collectionView: UICollectionView, viewForSupplementaryElementOfKind kind: String, at indexPath: IndexPath) -> UICollectionReusableView {
        if collectionView == self.filterCollectionView {
            switch kind {
            case UICollectionElementKindSectionHeader:
                if indexPath.section == 0{
                    let view = collectionView.dequeueReusableSupplementaryView(ofKind: kind, withReuseIdentifier: FilterHeaderView.ViewIdentifier, for: indexPath) as! FilterHeaderView
                    view.backgroundColor = UIColor.filterBackground()
                    view.styleFilter = self.styleFilter ?? StyleFilter()
                    view.didUpdateStyleFilter = { [weak self] (styleFilter, filterType) -> Void in
                        if let strongSelf = self {
                            strongSelf.styleFilter = styleFilter
                            strongSelf.didUpdateStyleFilter(strongSelf.styleFilter, filterType: filterType)
                        }
                    }
                    filterHeaderView = view
                    return view
                }
            default:
                break
            }
        }
        let headerView = collectionView.dequeueReusableSupplementaryView(ofKind: kind, withReuseIdentifier: DefaultHeaderID, for: indexPath)
        return headerView
    }
    
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, sizeForItemAt indexPath: IndexPath) -> CGSize {
        if collectionView == self.collectionView {
            return CGSize(width: view.width, height: ImageMenuCellHeight)
        }
        
        return CGSize.zero
    }
    
    // MARK: - Animation
    
    func showFilterSelectionAnimation(_ fromView: UIView){
        if let view = self.filterHeaderView{
            if let data = self.currentFilterSelectedAnimationData, data.filterSelectedAnimationState == FilterSelectedAnimationState.start{
                data.fromView = fromView
                self.collectionView.isUserInteractionEnabled = false
                view.showSelectedAnimation(data)
            }
        }
    }
}
