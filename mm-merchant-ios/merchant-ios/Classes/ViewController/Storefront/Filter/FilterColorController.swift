//
//  FilterColorController.swift
//  merchant-ios
//
//  Created by Koon Kit Chan on 24/11/15.
//  Copyright © 2015 Koon Kit Chan. All rights reserved.
//

import Foundation
import PromiseKit
import ObjectMapper

class FilterColorController: FilterCollectionBaseViewController {
    
    private let MarginLeft: CGFloat = 15
    private let MinSpacing: CGFloat = 20
    private var numberOfColumn: Int = 0
    
    private final let FilterColorCellId = "FilterColorCell"
    
    var colors: [Color] = []
    var validColors: [Color] = []
    var filteredColors: [Color] = []{
        didSet{
            self.buttonCell.isHidden = isHideSubmitButton()
            collectionView.isHidden = !hasDataSource()
            updateNoItemView()
        }
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        self.title = String.localize("LB_CA_COLOUR")
        
        loadColor()
        
        setupCollectionView()
        
        numberOfColumn = Int(100)
        initAnalyticLog()
    }
    
    override func refresh(_ sender: Any) {
        super.refresh(sender)
        
        loadColor()
    }
    
    // MARK: - Setup
    
    override func setupCollectionView() {
        super.setupCollectionView()
        collectionView.register(FilterColorCell.self, forCellWithReuseIdentifier: FilterColorCellId)
    }
    
    // MARK: - Data
    
    func loadColor() {
        showLoading()
        
        firstly{
            return self.listColor()
        }.then { _ -> Void in
            
            if let strongAggregation = self.aggregations{
                self.validColors = self.colors.filter({(strongAggregation.colorArray.contains($0.colorId))})
                self.filteredColors = self.validColors.filter{$0.colorId != 1}
            }
            
            
            for color in self.filteredColors {
                if let styleFilter = self.styleFilter {
                    if styleFilter.colors.contains(where: {$0.colorId == color.colorId}) {
                        color.isSelected = true
                    }
                }
            }
            
            self.collectionView.reloadData()
        }.always {
            self.stopLoading()
            self.refreshControl.endRefreshing()
        }.catch { _ -> Void in
            Log.error("error")
        }
    }
    
    func listColor() -> Promise<Any> {
        return Promise{ fulfill, reject in
            SearchService.searchColor() { [weak self] (response) in
                if let strongSelf = self {
                    if response.result.isSuccess {
                        
                        strongSelf.colors = Mapper<Color>().mapArray(JSONObject: response.result.value) ?? []
                        strongSelf.colors = strongSelf.colors.filter({$0.colorId != 0})
                        strongSelf.colors.sort(by: {(color1:Color, color2:Color) -> Bool in
                            color1.colorId < color2.colorId
                        })
                        
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
        return 1
    }
    
    override func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        if collectionView == self.filterCollectionView{
            return super.collectionView(collectionView, numberOfItemsInSection: section)
        }
        return filteredColors.count
    }
    
    override func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        let cell = collectionView.dequeueReusableCell(withReuseIdentifier: FilterColorCellId, for: indexPath) as! FilterColorCell
        
        if self.filteredColors.count > indexPath.row {
            cell.labelName.text = self.filteredColors[indexPath.row].colorName
            
            cell.imageView.mm_setImageWithURL(ImageURLFactory.URLSize1000(self.filteredColors[indexPath.row].colorImage, category: .color), placeholderImage: UIImage(named: "holder"), contentMode: .scaleAspectFit)
            
            if filteredColors[indexPath.row].isSelected {
                cell.border()
            } else {
                cell.unBorder()
            }
        }
        
        return cell
    }
    
    // MARK: - UICollectionView delegate (Flow Layout)
    
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, sizeForItemAt indexPath: IndexPath) -> CGSize {
        return CGSize(width: (self.view.frame.maxX - (MarginLeft * 2)) / CGFloat(numberOfColumn), height: Constants.Value.FilterColorWidth + 54.0)
    }
    
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, minimumLineSpacingForSectionAt section: Int) -> CGFloat {
        return 0.0
    }
    
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, minimumInteritemSpacingForSectionAt section: Int) -> CGFloat {
        return 0.0
    }

    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, insetForSectionAt section: Int) -> UIEdgeInsets {
        return UIEdgeInsets(top: 25 , left: MarginLeft , bottom: 0, right: MarginLeft)
    }
    
    // MARK: - UICollectionView delegate

    func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        let selectedColor = filteredColors[indexPath.row]
        
        if let strongStyleFilter = originalStyleFilter{
            if strongStyleFilter.hasColor(selectedColor.colorId){
                return
            }
        }
        
        selectedColor.isSelected = !filteredColors[indexPath.row].isSelected
        
        var hasSelectedColor = false
        
        for color in styleFilter?.colors ?? []{
            if color.colorId == selectedColor.colorId{
                hasSelectedColor = true
                if !selectedColor.isSelected{
                    styleFilter?.removeTag(color.colorId, filterType: FilterType.color)
                    styleFilter?.colors.remove(color)
                }
            }
        }
        
        if !hasSelectedColor && selectedColor.isSelected == true{
            styleFilter?.addTag(selectedColor.colorName, id: selectedColor.colorId, filterType: FilterType.color)
            styleFilter?.colors.append(selectedColor)
        }
        
        //Init data for Filter Selection Animation
        if selectedColor.isSelected{
            self.currentFilterSelectedAnimationData = FilterSelectedAnimationData(inView: self.view, filterTagName: selectedColor.colorName, completion: {
                self.collectionView.isUserInteractionEnabled = true
            })
            self.currentFilterSelectedAnimationData?.filterSelectedAnimationState = FilterSelectedAnimationState.start
        }
        
        if let filterHeaderView = self.filterHeaderView{
            filterHeaderView.styleFilter = styleFilter ?? StyleFilter()
        }
        
        collectionView.reloadData()
        
        if let view = collectionView.dequeueReusableCell(withReuseIdentifier: FilterColorCellId, for: indexPath) as? FilterColorCell{
            showFilterSelectionAnimation(view)
        }
    }
    
    //MARK: - Override functions
    
    override func isHideSubmitButton() -> Bool {
        return !hasDataSource()
    }
    
    override func hasDataSource() -> Bool{
        return (filteredColors.count > 0)
    }
    
    override func didUpdateStyleFilter(_ styleFilter: StyleFilter?, filterType: FilterType){
        super.didUpdateStyleFilter(styleFilter, filterType: filterType)
        
        if filterType == FilterType.color{
            for item in self.filteredColors {
                item.isSelected = false
                if let styleFilter = self.styleFilter {
                    if styleFilter.colors.contains(where: {$0.colorId == item.colorId}) {
                        item.isSelected = true
                    }
                }
            }
            self.collectionView.reloadData()
        }
        else{
            self.loadColor()
        }
    }
    
    // MARK: - Action
    
    override func reset(_ sender: UIBarButtonItem) {
        super.reset(sender)
        
        let strongOriginalStyleFilter = originalStyleFilter ?? StyleFilter()
        
        for color in filteredColors {
            if !strongOriginalStyleFilter.hasColor(color.colorId){
                color.isSelected = false
                styleFilter?.removeTag(color.colorId, filterType: FilterType.color)
            }
        }
        
        styleFilter?.colors = originalStyleFilter?.colors ?? []
        
        if let filterHeaderView = self.filterHeaderView{
            filterHeaderView.styleFilter = styleFilter ?? StyleFilter()
        }
        
        self.loadColor()
    }
    
    override func confirm(_ sender: UIButton) {
        super.confirm(sender)
        
        if let styleFilter = self.styleFilter {
            styleFilter.colors = []
            
            for color in self.filteredColors {
                if color.isSelected {
                    if !styleFilter.colors.contains(where: {$0.colorId == color.colorId}) {
                        styleFilter.colors.append(color)
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
            viewLocation: "PLP-Filter-Color",
            viewRef: nil,
            viewType: "Product"
        )
    }
}
