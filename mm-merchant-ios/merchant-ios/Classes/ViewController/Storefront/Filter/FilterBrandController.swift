//
//  FilterBrandController.swift
//  merchant-ios
//
//  Created by Koon Kit Chan on 23/11/15.
//  Copyright © 2015 Koon Kit Chan. All rights reserved.
//

import Foundation
import PromiseKit
import ObjectMapper

class FilterBrandController: FilterListBaseViewController {
    
    var brands: [Brand] = []
    var validBrands: [Brand] = []
    var filteredBrands: [Brand] = []{
        didSet{
            self.buttonCell.isHidden = isHideSubmitButton()
            collectionView.isHidden = !hasDataSource()
            updateNoItemView()
        }
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        self.title = String.localize("LB_CA_BRAND")
        
        loadBrand()
        
        self.searchBar.placeholder = String.localize("LB_CA_SEARCH_FILTER_PLACEHOLDER")
        
        setupDismissKeyboardGesture()
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        self.initAnalyticsViewRecord(viewLocation: "PLP-Filter-Brand", viewType: "Product")
    }
    
    func loadBrand() {
        showLoading()
        
        firstly {
            return self.listBrand()
        }.then { _ -> Void in
            
            if let strongAggregation = self.aggregations{
                self.validBrands = self.brands.filter({(strongAggregation.brandArray.contains($0.brandId))})
                
                self.filteredBrands = self.validBrands
            }
            
            self.filteredBrands.sort(by: {$0.brandName < $1.brandName})
            
            for item in self.filteredBrands {
                if let styleFilter = self.styleFilter {
                    if styleFilter.brands.contains(where: {$0.brandId == item.brandId}) {
                        item.isSelected = true
                    }
                }
            }
            
            self.searchBar.isHidden = (self.filteredBrands.count == 0)
            self.collectionView.reloadData()
        }.always {
            self.stopLoading()
            self.refreshControl.endRefreshing()
        }.catch { _ -> Void in
            Log.error("error")
        }
    }
    
    func listBrand() -> Promise<Any> {
        return Promise{ fulfill, reject in
            SearchService.searchBrand() { [weak self] (response) in
                if let strongSelf = self {
                    if response.result.isSuccess {
                        
                        strongSelf.brands = Mapper<Brand>().mapArray(JSONObject: response.result.value) ?? []
                        strongSelf.brands = strongSelf.brands.filter({$0.brandId != 0})

                        fulfill("OK")
                    } else {
                        reject(response.result.error!)
                    }
                }
            }
        }
    }

    // MARK: - Collection view
    
    override func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        let cell = collectionView.dequeueReusableCell(withReuseIdentifier: "ImageMenuCell", for: indexPath) as! ImageMenuCell
        
        if self.filteredBrands.count > indexPath.row {
            cell.upperLabel.text = self.filteredBrands[indexPath.row].brandName
            cell.lowerLabel.text = self.filteredBrands[indexPath.row].brandNameInvariant
            cell.setImage(self.filteredBrands[indexPath.row].headerLogoImage, imageCategory: .brand)
            
            if filteredBrands[indexPath.row].isSelected {
                cell.tickImageView.image = UIImage(named: "filter_icon_tick")
            } else {
                cell.tickImageView.image = nil
            }
        }
        
        return cell
    }
    
    override func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return filteredBrands.count
    }
    
    func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        let selectedBrand = filteredBrands[indexPath.row]
        
        if let strongStyleFilter = originalStyleFilter{
            if strongStyleFilter.hasBrand(selectedBrand.brandId){
                return
            }
        }
        
        selectedBrand.isSelected = !filteredBrands[indexPath.row].isSelected
        
        var hasSelectedBrand = false
        
        for brand in styleFilter?.brands ?? []{
            if brand.brandId == selectedBrand.brandId{
                hasSelectedBrand = true
                if !selectedBrand.isSelected{
                    styleFilter?.removeTag(brand.brandId, filterType: FilterType.brand)
                    styleFilter?.brands.remove(brand)
                }
            }
        }
        
        if !hasSelectedBrand && selectedBrand.isSelected == true{
            styleFilter?.addTag(selectedBrand.brandName, id: selectedBrand.brandId, filterType: FilterType.brand)
            styleFilter?.brands.append(selectedBrand)
        }
        
        //Init data for Filter Selection Animation
        if selectedBrand.isSelected{
            self.currentFilterSelectedAnimationData = FilterSelectedAnimationData(inView: self.view, filterTagName: selectedBrand.brandName, completion: {
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
    
    override func hasDataSource() -> Bool{
        return (filteredBrands.count > 0)
    }
    
    //MARK: - FilterHeader delegate
    
    override func didUpdateStyleFilter(_ styleFilter: StyleFilter?, filterType: FilterType){
        super.didUpdateStyleFilter(styleFilter, filterType: filterType)
        if filterType == FilterType.brand{
            for item in self.filteredBrands {
                item.isSelected = false
                if let styleFilter = self.styleFilter {
                    if styleFilter.brands.contains(where: {$0.brandId == item.brandId}) {
                        item.isSelected = true
                    }
                }
            }
            self.collectionView.reloadData()
        }
        else{
            self.loadBrand()
        }
    }
    
    //MARK: - Refresh Control
    
    override func refresh(_ sender: Any) {
        loadBrand()
    }
    
    // MARK: - UISearchBarDelegate
    
    private func filter(_ text: String!) {
        self.filteredBrands = self.validBrands.filter(){ $0.brandName.lowercased().range(of: text.lowercased()) != nil || $0.brandNameInvariant.lowercased().range(of: text.lowercased()) != nil }
        self.collectionView?.reloadData()
    }
    
    func searchBarSearchButtonClicked(_ searchBar: UISearchBar) {
        if let text = searchBar.text {
            self.filter(text)
        }
        searchBar.resignFirstResponder()
    }
    
    internal func searchBar(_ searchBar: UISearchBar, textDidChange searchText: String) {
        if let text = searchBar.text {
            searchString = text
        }
        
        if searchString.length == 0 {
            self.filteredBrands = self.validBrands
            self.collectionView.reloadData()
        } else {
            self.filter(searchString)
        }
    }
    
    // MARK: Confirm and Reset
    
    override func reset(_ sender: UIBarButtonItem) {
        for brand in filteredBrands {
            if let strongOriginalStyleFilter = originalStyleFilter{
                if !strongOriginalStyleFilter.hasBrand(brand.brandId){
                    brand.isSelected = false
                    styleFilter?.removeTag(brand.brandId, filterType: FilterType.brand)
                }
            }
        }

        styleFilter?.brands = originalStyleFilter?.brands ?? []
        
        if let filterHeaderView = self.filterHeaderView{
            filterHeaderView.styleFilter = styleFilter ?? StyleFilter()
        }
        
        loadBrand()
    }
    
    override func confirm(_ sender: UIButton) {
        super.confirm(sender)
        self.styleFilter?.brands = []
        
        for brand in self.validBrands {
            if brand.isSelected {
                if let styleFilter = self.styleFilter {
                    if !styleFilter.brands.contains(where: {$0.brandId == brand.brandId}) {
                        styleFilter.brands.append(brand)
                    }
                }
            }
        }
        
        filterStyleDelegate?.filterStyle(self.styles, styleFilter: self.styleFilter!, selectedFilterCategories: nil)
        self.navigationController?.popViewController(animated: true)
    }
}
