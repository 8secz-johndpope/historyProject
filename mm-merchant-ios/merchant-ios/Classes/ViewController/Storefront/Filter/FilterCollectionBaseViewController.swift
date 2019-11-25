//
//  FilterCollectionBaseViewController.swift
//  merchant-ios
//
//  Created by Stephen Yuen on 19/7/2016.
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


class FilterCollectionBaseViewController: SubFilterBaseViewController {
    private final let DefaultHeaderID = "DefaultHeaderID"
    
    var refreshControl = UIRefreshControl()
    var filterContainerView: UIView!

    override func viewDidLoad() {
        super.viewDidLoad()
        
        styleFilterBackup = styleFilter?.clone()
        
        self.edgesForExtendedLayout = UIRectEdge()
        
        setupNoItemView()
        setupButtonCell()
        setupRefreshControl()
        setupCollectionView()
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
    
    // MARK: - Setup
    
    func setupCollectionView(){
        let layout: UICollectionViewFlowLayout = getCustomFlowLayout()
        layout.sectionInset = UIEdgeInsets(top: 0, left: 0, bottom: 0, right: 0)
        layout.itemSize = CGSize(width: self.view.frame.width, height: 120)
        
        if filterContainerView != nil{
            filterContainerView.removeFromSuperview()
        }
        if filterContainerView != nil{
            filterContainerView.removeFromSuperview()
        }
        let containerView = UIView(frame: CGRect(x: self.view.bounds.minX, y: view.bounds.minY, width: view.width, height: FilterHeaderView.DefaultHeight))
        filterContainerView = containerView
        containerView.backgroundColor = UIColor.filterBackground()
        filterCollectionView = UICollectionView(frame: CGRect(x: 0, y: containerView.bounds.minY, width: containerView.width, height: FilterHeaderView.DefaultHeight), collectionViewLayout: layout)
        filterCollectionView.dataSource = self
        filterCollectionView.delegate = self
        filterCollectionView.alwaysBounceVertical = false
        filterCollectionView.showsHorizontalScrollIndicator = false
        filterCollectionView.showsVerticalScrollIndicator = false
        filterCollectionView.isScrollEnabled = false
        filterCollectionView.backgroundColor = UIColor.white
        filterCollectionView.register(FilterHeaderView.self, forSupplementaryViewOfKind: UICollectionElementKindSectionHeader, withReuseIdentifier: FilterHeaderView.ViewIdentifier)
        filterCollectionView.register(UICollectionReusableView.self, forSupplementaryViewOfKind: UICollectionElementKindSectionHeader, withReuseIdentifier: DefaultHeaderID)
        containerView.addSubview(filterCollectionView)
        self.view.addSubview(containerView)
    }
    
    override func viewWillLayoutSubviews() {
        super.viewWillLayoutSubviews()
        var rect = self.view.frame
        rect.size.height = Constants.ScreenSize.SCREEN_HEIGHT - rect.originY
        self.view.frame = rect
        
        let updateCollectionframe = { [weak self]() -> Void in
            if let strongSelf = self{
                var collectionMinY: CGFloat = 0
                var filterContainerViewHidden = true
                if strongSelf.styleFilter?.filterTags.count > 0{
                    collectionMinY = FilterHeaderView.DefaultHeight
                    filterContainerViewHidden = false
                }
                strongSelf.filterContainerView.isHidden = filterContainerViewHidden
                strongSelf.filterCollectionView.isHidden = filterContainerViewHidden
                strongSelf.collectionView.frame = CGRect(
                    x: strongSelf.view.bounds.minX,
                    y: collectionMinY,
                    width: strongSelf.view.bounds.width,
                    height: strongSelf.view.frame.height - strongSelf.ButtonCellHeight - collectionMinY
                )
            }
        }
        
        updateCollectionframe()
        
        noItemView.frame = CGRect(x: (view.width - noItemView.width) / 2, y: (view.height + view.y - noItemView.height) / 2, width: noItemView.width, height: noItemView.height)
        
        styleFilter?.filterTagsObserver = { () -> Void in
            updateCollectionframe()
            self.filterCollectionView.reloadData()
        }
    }
    
    func setupRefreshControl() {
        self.refreshControl.addTarget(self, action: #selector(self.refresh(_:)), for: .valueChanged)
        self.collectionView.addSubview(refreshControl)
        self.collectionView.alwaysBounceVertical = true
    }
    
    // MARK: - Collection view delegate flow layout
    
    func numberOfSections(in collectionView: UICollectionView) -> Int {
        if collectionView == self.filterCollectionView{
           return 1
        }
        return 0
    }
    
    // MARK: - Collection view delegate flow layout
    
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, referenceSizeForHeaderInSection section: Int) -> CGSize{
        switch collectionView {
        case self.filterCollectionView:
            if section == 0 && !isHiddenFilterHeader(){
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
                        if let strongSelf = self{
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

    // MARK: - Data
    
    func searchStyle() -> Promise<Any> {
        return Promise{ fulfill, reject in
            if let strongStyleFilter = self.searchStyleFilter{
                SearchService.searchStyle(strongStyleFilter) { [weak self] (response) in
                    if let strongSelf = self {
                        if response.result.isSuccess {
                            if let styleResponse = Mapper<SearchResponse>().map(JSONObject: response.result.value) {
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
    
    // MARK: - Action
    
    override func confirm(_ sender: UIButton) {
        isConfirmed = true
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
