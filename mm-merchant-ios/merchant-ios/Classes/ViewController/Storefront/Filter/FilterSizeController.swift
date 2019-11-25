//
//  FilterSizeController.swift
//  merchant-ios
//
//  Created by Koon Kit Chan on 25/11/15.
//  Copyright © 2015 Koon Kit Chan. All rights reserved.
//

import Foundation
import PromiseKit
import ObjectMapper

class FilterSizeController: FilterCollectionBaseViewController {
    
    private final let HeaderHeight: CGFloat = 30
    private final let SizeCellHeight: CGFloat = 49
    private final let MarginLeft: CGFloat = 15
    private final let MinSpacing: CGFloat = 5
    private final let SectionMarginTop: CGFloat = 10
    private var lineSpacing: CGFloat = 5
    
    private final let FilterSizeViewCellId = "FilterSizeViewCell"
    private final let HeaderIdentifier = "Header"
    
    private var sizes: [Size] = []
    private var filteredSizes: [Size] = []
    
    private var sizeGroupSections: [SizeGroupSection] = []{
        didSet{
            self.buttonCell.isHidden = isHideSubmitButton()
            
            collectionView.isHidden = !hasDataSource()
            
            updateNoItemView()
        }
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        self.title = String.localize("LB_CA_FILTER_SIZE")
        
        loadSizes()
        
        setupCollectionView()
        
        initCommon()
        initAnalyticLog()
    }
    
    override func refresh(_ sender: Any) {
        super.refresh(sender)
        
        loadSizes()
    }
    
    override func setupCollectionView() {
        super.setupCollectionView()
        collectionView.register(FilterSizeViewCell.self, forCellWithReuseIdentifier: FilterSizeViewCellId)
        collectionView.register(PickerCell.self, forSupplementaryViewOfKind: UICollectionElementKindSectionHeader, withReuseIdentifier: HeaderIdentifier)
    }
    
    func initCommon() {
        let numberOfColumn = Int((self.view.frame.maxX - (MarginLeft * 2 + MinSpacing)) / (SizeCellHeight + MinSpacing))
        lineSpacing = (self.view.frame.maxX - (CGFloat(numberOfColumn) * SizeCellHeight)) / CGFloat(numberOfColumn + 1)
    }
    
    func loadSizes() {
        showLoading()
        
        firstly{
            return self.listSizes()
        }.then { _ -> Void in
            
            if let strongAggregation = self.aggregations{
                let validSizes = self.sizes.filter({(strongAggregation.sizeArray.contains($0.sizeId))})
                self.filteredSizes = validSizes.filter{$0.sizeId != 1}
            }
            
            for size in self.filteredSizes {
                if let styleFilter = self.styleFilter {
                    if styleFilter.sizes.contains(where: {$0.sizeId == size.sizeId}) {
                        size.isSelected = true
                    }
                }
            }
            
            self.sizeGroupSections = self.buildSizeGroupSections()
            self.collectionView.reloadData()
        }.always {
            self.stopLoading()
            self.refreshControl.endRefreshing()
        }.catch { _ -> Void in
            Log.error("error")
        }
    }
    
    func listSizes() -> Promise<Any> {
        return Promise{ fulfill, reject in
            SearchService.searchSize() { [weak self] (response) in
                if let strongSelf = self {
                    if response.result.isSuccess{
                        strongSelf.sizes = Mapper<Size>().mapArray(JSONObject: response.result.value) ?? []
                        strongSelf.sizes = strongSelf.sizes.filter({$0.sizeId != 0})
                        fulfill("OK")
                    } else {
                        reject(response.result.error!)
                    }
                }
            }
        }
    }
    
    // MARK: - UICollectionView data source
    
    override func numberOfSections(in collectionView: UICollectionView) -> Int {
        if collectionView == self.filterCollectionView{
            return super.numberOfSections(in: collectionView)
        }
        return sizeGroupSections.count
    }
    
    override func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        if collectionView == self.filterCollectionView{
            return super.collectionView(collectionView, numberOfItemsInSection: section)
        }
        return self.sizeGroupSections[section].sizes.count
    }
    
    override func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        let cell = collectionView.dequeueReusableCell(withReuseIdentifier: FilterSizeViewCellId, for: indexPath) as! FilterSizeViewCell
        let sizes = self.sizeGroupSections[indexPath.section].sizes
        
        if sizes.count > indexPath.row {
            cell.imageView.image = nil
            cell.label.text = sizes[indexPath.row].sizeName
            
            if sizes[indexPath.row].isSelected {
                cell.border()
            } else {
                cell.unBorder()
            }
        }
        
        return cell
    }
    
    override func collectionView(_ collectionView: UICollectionView, viewForSupplementaryElementOfKind kind: String, at indexPath: IndexPath) -> UICollectionReusableView {
        if collectionView == self.filterCollectionView{
            return super.collectionView(collectionView, viewForSupplementaryElementOfKind: kind, at: indexPath)
        }
        
        switch kind {
        case UICollectionElementKindSectionHeader:
            let headerView = collectionView.dequeueReusableSupplementaryView(ofKind: kind, withReuseIdentifier: HeaderIdentifier, for: indexPath) as! PickerCell
            let sizeGroupSection = self.sizeGroupSections[indexPath.section]
            
            headerView.label.text = sizeGroupSection.sizeGroupName
            headerView.borderView.isHidden = false
            
            return headerView
        default:
            assert(false, "Unexpected element kind")
            let headerView = collectionView.dequeueReusableSupplementaryView(ofKind: kind, withReuseIdentifier: HeaderIdentifier, for: indexPath) as! PickerCell
            return headerView
        }
    }
    
    // MARK: - UICollectionView delegate (Flow Layout)
    
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, sizeForItemAt indexPath: IndexPath) -> CGSize {
        return CGSize(width: SizeCellHeight, height: SizeCellHeight)
    }
    
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, insetForSectionAt section: Int) -> UIEdgeInsets {
        return UIEdgeInsets(top: SectionMarginTop , left: MarginLeft , bottom: SectionMarginTop, right: MarginLeft)
    }
    
    override func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, referenceSizeForHeaderInSection section: Int) -> CGSize{
        if collectionView == self.filterCollectionView{
            return super.collectionView(collectionView, layout: collectionViewLayout, referenceSizeForHeaderInSection: section)
        }
        
        if self.sizeGroupSections[section].sizes.count > 0{
            return CGSize(width: view.width, height: HeaderHeight)
        }
        
        return CGSize.zero
    }
    
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, minimumLineSpacingForSectionAt section: Int) -> CGFloat {
        if collectionView == self.filterCollectionView{
            return 0
        }
        
        return lineSpacing
    }
    
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, minimumInteritemSpacingForSectionAt section: Int) -> CGFloat {
        return lineSpacing
    }
    
    // MARK: - UICollectionView delegate
    
    func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        let sizes = self.sizeGroupSections[indexPath.section].sizes
        let selectedSize = sizes[indexPath.row]
        
        if let strongStyleFilter = originalStyleFilter{
            if strongStyleFilter.hasSize(selectedSize.sizeId){
                return
            }
        }
        
        selectedSize.isSelected = !selectedSize.isSelected
        
        var hasSelectedSize = false
        
        for size in styleFilter?.sizes ?? []{
            if size.sizeId == selectedSize.sizeId{
                hasSelectedSize = true
                if !selectedSize.isSelected{
                    styleFilter?.removeTag(size.sizeId, filterType: FilterType.size)
                    styleFilter?.sizes.remove(size)
                }
            }
        }
        
        if !hasSelectedSize && selectedSize.isSelected == true{
            styleFilter?.addTag(selectedSize.sizeName, id: selectedSize.sizeId, filterType: FilterType.size)
            styleFilter?.sizes.append(selectedSize)
        }
        
        //Init data for Filter Selection Animation
        if selectedSize.isSelected{
            self.currentFilterSelectedAnimationData = FilterSelectedAnimationData(inView: self.view, filterTagName: selectedSize.sizeName, completion: {
                self.collectionView.isUserInteractionEnabled = true
            })
            self.currentFilterSelectedAnimationData?.filterSelectedAnimationState = FilterSelectedAnimationState.start
        }

        
        if let filterHeaderView = self.filterHeaderView{
            filterHeaderView.styleFilter = styleFilter ?? StyleFilter()
        }
        
        collectionView.reloadData()
        
        if let view = collectionView.dequeueReusableCell(withReuseIdentifier: FilterSizeViewCellId, for: indexPath) as? FilterSizeViewCell{
            showFilterSelectionAnimation(view)
        }
    }
    
    //MARK: - Override functions
    
    override func isHideSubmitButton() -> Bool {
        return !hasDataSource()
    }

    override func hasDataSource() -> Bool{
        return (filteredSizes.count > 0)
    }
    
    override func didUpdateStyleFilter(_ styleFilter: StyleFilter?, filterType: FilterType){
        super.didUpdateStyleFilter(styleFilter, filterType: filterType)
        
        if filterType == FilterType.size{
            for item in self.filteredSizes {
                item.isSelected = false
                if let styleFilter = self.styleFilter {
                    if styleFilter.sizes.contains(where: {$0.sizeId == item.sizeId}) {
                        item.isSelected = true
                    }
                }
            }
            self.collectionView.reloadData()
        }
        else{
            self.loadSizes()
        }
    }
    
    // MARK: Action
    
    override func reset(_ sender: UIBarButtonItem) {
        super.reset(sender)
        
        let strongOriginalStyleFilter = originalStyleFilter ?? StyleFilter()
        
        for size in self.filteredSizes {
            if !strongOriginalStyleFilter.hasSize(size.sizeId){
                size.isSelected = false
                styleFilter?.removeTag(size.sizeId, filterType: FilterType.size)
            }
        }

        styleFilter?.sizes = originalStyleFilter?.sizes ?? []
        
        if let filterHeaderView = self.filterHeaderView{
            filterHeaderView.styleFilter = styleFilter ?? StyleFilter()
        }
        
        self.loadSizes()
    }
    
    override func confirm(_ sender: UIButton) {
        super.confirm(sender)
        
        if let styleFilter = self.styleFilter {
            styleFilter.sizes = []
            
            for size in self.filteredSizes {
                if size.isSelected {
                    if !styleFilter.sizes.contains(where: {$0.sizeId == size.sizeId}) {
                        styleFilter.sizes.append(size)
                    }
                    
                }
            }
            
            filterStyleDelegate?.filterStyle(self.styles, styleFilter: styleFilter, selectedFilterCategories: nil)
        }
        self.navigationController?.popViewController(animated: true)
    }
    
    // MARK: Helpers
    
    private func buildSizeGroupSections() -> [SizeGroupSection] {
        self.filteredSizes.sort {(size1:Size, size2:Size) -> Bool in
            size1.sizeGroupId < size2.sizeGroupId
        }
        
        var groupId = -1
        var sizeArray: [Size] = []
        
        var groupDatas = [SizeGroupSection]()
        var groupData = SizeGroupSection()
        
        
        for size in self.filteredSizes {
            if groupId != size.sizeGroupId {
                if groupId != -1 {
                    sizeArray.sort {(size1:Size, size2:Size) -> Bool in
                        size1.sizeId < size2.sizeId
                    }
                    
                    groupData.sizes = sizeArray
                    groupDatas.append(groupData)
                }
                
                sizeArray = []
                sizeArray.append(size)
                
                groupData = SizeGroupSection(sizeGroupName: size.sizeGroupName)
                groupId = size.sizeGroupId
                
            } else {
                sizeArray.append(size)
            }
        }
        
        sizeArray.sort {(size1:Size, size2:Size) -> Bool in
            size1.sizeId < size2.sizeId
        }
        
        groupData.sizes = sizeArray
        groupDatas.append(groupData)
        return groupDatas
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
            viewDisplayName: "User: \(Context.getUserProfile().displayName)",
            viewParameters: Context.getUserProfile().userKey,
            viewLocation: "PLP-Filter-Size",
            viewRef: nil,
            viewType: "Product"
        )
    }
}

internal class SizeGroupSection{
    var sizeGroupName: String? = ""
    var sizes = [Size]()
    
    init(sizeGroupName: String? = "") {
        self.sizeGroupName = sizeGroupName
    }
}
