//
//  FilterMerchantController.swift
//  merchant-ios
//
//  Created by Koon Kit Chan on 19/1/2016.
//  Copyright © 2016 WWE & CO. All rights reserved.
//

import Foundation
import PromiseKit
import ObjectMapper

class FilterMerchantController: FilterListBaseViewController {
    
    var merchants: [Merchant] = []
    var validMerchants: [Merchant] = []
    var filteredMerchants: [Merchant] = []{
        didSet{
            self.buttonCell.isHidden = isHideSubmitButton()
            collectionView.isHidden = !hasDataSource()
            updateNoItemView()
        }
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        self.title = String.localize("LB_CA_FILTER_MERCHANT")
        
        loadMerchant()
        initAnalyticLog()
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        self.initAnalyticsViewRecord(viewLocation: "PLP-Filter-Merchant", viewType: "Product")
    }
    
    func loadMerchant() {
        showLoading()
        
        firstly {
            return MerchantService.fetchMerchantsIfNeeded(.all)
        }.then { merchants -> Void in
            self.merchants = merchants.filter({$0.merchantId != 0})
            
            if let strongAggregation = self.aggregations{
                self.validMerchants = self.merchants.filter({(strongAggregation.merchantArray.contains($0.merchantId)) })
                self.filteredMerchants = self.validMerchants
            }
            
            self.filteredMerchants.sort(by: {$0.merchantName < $1.merchantName})
            
            for item in self.filteredMerchants {
                if let styleFilter = self.styleFilter {
                    if styleFilter.merchants.contains(where: {$0.merchantId == item.merchantId}) {
                        item.isSelected = true
                    }
                }
            }
            
            self.searchBar.isHidden = (self.filteredMerchants.count == 0)
            self.collectionView.reloadData()
            
        }.always {
            self.stopLoading()
            self.refreshControl.endRefreshing()
        }.catch { _ -> Void in
            Log.error("error")
        }
    }
    
    
    // MARK: - Collection view
    
    override func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        let cell = collectionView.dequeueReusableCell(withReuseIdentifier: "ImageMenuCell", for: indexPath) as! ImageMenuCell
        
        if self.filteredMerchants.count > indexPath.row {
            cell.upperLabel.text = self.filteredMerchants[indexPath.row].merchantName
            cell.lowerLabel.text = self.filteredMerchants[indexPath.row].merchantNameInvariant
            cell.setImage(self.filteredMerchants[indexPath.row].headerLogoImage, imageCategory: .merchant)
            
            if self.filteredMerchants[indexPath.row].isSelected {
                cell.tickImageView.image = UIImage(named: "tick")
            } else {
                cell.tickImageView.image = nil
            }
        }
        
        return cell
    }
    
    override func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return filteredMerchants.count
    }
    
    func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        let selectedMerchant = filteredMerchants[indexPath.row]
        
        if let strongStyleFilter = originalStyleFilter{
            if strongStyleFilter.hasMerchant(selectedMerchant.merchantId){
                return
            }
        }
        
        selectedMerchant.isSelected = !filteredMerchants[indexPath.row].isSelected
        
        var hasSelectedMerchant = false
        
        for merchant in styleFilter?.merchants ?? []{
            if merchant.merchantId == selectedMerchant.merchantId{
                hasSelectedMerchant = true
                if !selectedMerchant.isSelected{
                    styleFilter?.removeTag(merchant.merchantId, filterType: FilterType.merchant)
                    styleFilter?.merchants.remove(merchant)
                }
            }
        }
        
        if !hasSelectedMerchant && selectedMerchant.isSelected == true{
            styleFilter?.addTag(selectedMerchant.merchantName, id: selectedMerchant.merchantId, filterType: FilterType.merchant)
            styleFilter?.merchants.append(selectedMerchant)
        }
        
        //Init data for Filter Selection Animation
        if selectedMerchant.isSelected{
            self.currentFilterSelectedAnimationData = FilterSelectedAnimationData(inView: self.view, filterTagName: selectedMerchant.merchantName, completion: {
                self.collectionView.isUserInteractionEnabled = true
            })
            self.currentFilterSelectedAnimationData?.filterSelectedAnimationState = FilterSelectedAnimationState.start
        }
        
        if let filterHeaderView = self.filterHeaderView{
            filterHeaderView.styleFilter = styleFilter ?? StyleFilter()
        }
        collectionView.reloadData()
        
        if let view = collectionView.dequeueReusableCell(withReuseIdentifier: "ImageMenuCell", for: indexPath) as? ImageMenuCell{
            showFilterSelectionAnimation(view)
        }
    }
    
    //MARK: - Override functions
    
    override func isHideSubmitButton() -> Bool {
        return !hasDataSource()
    }

    override func hasDataSource() -> Bool {
        return (filteredMerchants.count > 0)
    }
    
    //MARK: - FilterHeader delegate
    
    override func didUpdateStyleFilter(_ styleFilter: StyleFilter?, filterType: FilterType){
        super.didUpdateStyleFilter(styleFilter, filterType: filterType)
        if filterType == FilterType.merchant{
            for item in self.filteredMerchants {
                item.isSelected = false
                if let styleFilter = self.styleFilter {
                    if styleFilter.merchants.contains(where: {$0.merchantId == item.merchantId}) {
                        item.isSelected = true
                    }
                }
            }
            self.collectionView.reloadData()
        }
        else{
            self.loadMerchant()
        }
    }
    
    // MARK: Refresh Control
    
    override func refresh(_ sender: Any) {
        loadMerchant()
    }
    
    // MARK: UISearchBarDelegate
    
    private func filter(_ text : String!) {
        self.filteredMerchants = self.validMerchants.filter(){ $0.merchantDisplayName.lowercased().range(of: text.lowercased()) != nil || $0.merchantCompanyName.lowercased().range(of: text.lowercased()) != nil }
        self.collectionView?.reloadData()
    }
    
    func searchBarSearchButtonClicked(_ searchBar: UISearchBar) {
        self.filter(searchBar.text!)
        searchBar.resignFirstResponder()
    }
    
    internal func searchBar(_ searchBar: UISearchBar, textDidChange searchText: String) {
        searchString = searchBar.text!
        
        if searchString.length == 0 {
            self.filteredMerchants = self.validMerchants
            self.collectionView.reloadData()
        } else {
            self.filter(searchString)
        }
    }
    
    // MARK: Confirm and Reset
    
    override func reset(_ sender: UIBarButtonItem) {
        let strongOriginalStyleFilter = originalStyleFilter ?? StyleFilter()
        
        for merchant in filteredMerchants {
            if !strongOriginalStyleFilter.hasMerchant(merchant.merchantId){
                merchant.isSelected = false
                styleFilter?.removeTag(merchant.merchantId, filterType: FilterType.merchant)
            }
        }

        styleFilter?.merchants = originalStyleFilter?.merchants ?? []
        
        if let filterHeaderView = self.filterHeaderView{
            filterHeaderView.styleFilter = styleFilter ?? StyleFilter()
        }
        
        self.loadMerchant()
    }
    
    override func confirm(_ sender: UIButton) {
        super.confirm(sender)
        if let styleFilter = self.styleFilter {
            styleFilter.merchants = []
            
            for merchant in self.validMerchants {
                if merchant.isSelected {
                    if !styleFilter.merchants.contains(where: {$0.merchantId == merchant.merchantId}) {
                        styleFilter.merchants.append(merchant)
                    }
                }
            }
            
            filterStyleDelegate?.filterStyle(self.styles, styleFilter: styleFilter, selectedFilterCategories: nil)
        }
        
        self.navigationController?.popViewController(animated: true)
    }
    
    // MARK: Logging
    func initAnalyticLog(){
        
        initAnalyticsViewRecord(
            nil,
            authorType: nil,
            brandCode: nil,
            merchantCode: nil,
            referrerRef: nil,
            referrerType: nil,
            viewDisplayName: nil,
            viewParameters: nil,
            viewLocation: "PLP-Filter-Merchant",
            viewRef: nil,
            viewType: "Product"
        )
    }
    
}
