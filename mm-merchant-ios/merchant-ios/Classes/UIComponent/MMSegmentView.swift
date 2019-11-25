//
//  MMSegmentView.swift
//  merchant-ios
//
//  Created by Sang Nguyen on 10/25/16.
//  Copyright © 2016 WWE & CO. All rights reserved.
//

import UIKit
protocol MMSegmentViewDelegate: NSObjectProtocol {
    func didSelectTabAtIndex(_ tabIndex : Int)
}
class MMSegmentView: UIView, UICollectionViewDataSource, UICollectionViewDelegate, UICollectionViewDelegateFlowLayout {
    
    var subCatCollectionView : UICollectionView!
    private var arrayTabs = [String]()
    var selectingTab : Int = 0
    weak var delegate: MMSegmentViewDelegate?
    private final let CatCellSpacing : CGFloat = 0
    private final let IndicatorOffset : CGFloat = 5
    private final let IndicatorHeight : CGFloat = 2
    private final let IndicatorLeadingMargin : CGFloat = -7.5
    private final let BottomPadding : CGFloat = 8
    private final let CellHeight : CGFloat = 45
    private final let FontSize : CGFloat = 13
    private var marginLeft = CGFloat(0)
    
    private final var indicatorLayer = CALayer()
    
    lazy private var indicatorColor = UIColor.primary1()
    lazy private var selectedTabColor = UIColor.secondary15()//UIColor.primary1()
    lazy private var unSelectedTabColor = UIColor.secondary16()//UIColor.secondary2()
    
    var indicatorFixedWidth: CGFloat?
    private lazy var tabSegmentSettings = [MMTabSegmentSetting]()
    
    override init(frame: CGRect) {
        super.init(frame: frame)
    }
    
    convenience init(frame: CGRect, tabs: [String]) {
        self.init(frame: frame)
        self.backgroundColor = UIColor.white
        arrayTabs = tabs
        let layout = UICollectionViewFlowLayout()
        layout.sectionInset = UIEdgeInsets(top: 0, left: 0, bottom: 0, right: 0)
        layout.itemSize = CGSize(width: frame.width, height: bounds.height)
        layout.scrollDirection = UICollectionViewScrollDirection.horizontal
        subCatCollectionView = UICollectionView(frame: CGRect(x:0, y: 0, width: frame.width, height: CellHeight), collectionViewLayout: layout)
        subCatCollectionView.register(SubCatCell.self, forCellWithReuseIdentifier: "SubCatCell")
        subCatCollectionView.backgroundColor = UIColor.white
        subCatCollectionView.showsHorizontalScrollIndicator = false
        subCatCollectionView.delegate = self
        subCatCollectionView.dataSource = self
        addSubview(subCatCollectionView)
        indicatorLayer.borderColor = indicatorColor.cgColor
        indicatorLayer.borderWidth = 1
        indicatorLayer.cornerRadius = IndicatorHeight/2
        indicatorLayer.backgroundColor = indicatorColor.cgColor
        self.layer.addSublayer(indicatorLayer)
        marginLeft = self.getMarginLeft()
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    func setData(_ array: [String]) {
        arrayTabs = array
        self.refreshUI()
    }
    
    func refreshUI(){
        self.subCatCollectionView?.reloadData()
        self.updateIndicatorLayer()
    }
    
    func setIndicatorColor(_ color: UIColor){
        indicatorColor = color
        indicatorLayer.borderColor = indicatorColor.cgColor
        indicatorLayer.backgroundColor = indicatorColor.cgColor
    }
    
    func setTabColor(selectedColor: UIColor, unSelectedColor: UIColor){
        selectedTabColor = selectedColor
        unSelectedTabColor = unSelectedColor
    }
    
    func setTabSegmentSettings(_ tabSegmentSettings: [MMTabSegmentSetting]){
        self.tabSegmentSettings = tabSegmentSettings
    }
    
    //MARK: CollectionView Methods
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return arrayTabs.count
    }
    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        let cell = collectionView.dequeueReusableCell(withReuseIdentifier: "SubCatCell", for: indexPath) as! SubCatCell
        cell.backgroundColor = UIColor.clear
        cell.label.text = arrayTabs[indexPath.row]
        cell.label.font = UIFont.fontWithSize(Int(FontSize), isBold: false)
        cell.label.textColor = UIColor.secondary2()
        if selectingTab == indexPath.row {
            cell.label.font = UIFont.fontWithSize(Int(FontSize + 1), isBold: true)
            cell.label.textColor = selectedTabColor
            if let tabSegmentSetting = tabSegmentSettings.filter({$0.tabIndex == selectingTab}).first {
                cell.label.textColor = tabSegmentSetting.selectedTabColor ?? selectedTabColor
                indicatorLayer.borderColor = (tabSegmentSetting.selectedIndicatorColor ?? indicatorColor).cgColor
                indicatorLayer.backgroundColor = (tabSegmentSetting.selectedIndicatorColor ?? indicatorColor).cgColor
            }
        } else {
            cell.label.textColor = unSelectedTabColor
        }
        cell.imageView.isHidden = true
        return cell
    }
    
    //MARK: - Collection Layout
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, minimumInteritemSpacingForSectionAt section: Int) -> CGFloat {
        return  CatCellSpacing
    }
    
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, minimumLineSpacingForSectionAt section: Int) -> CGFloat {
        return  CatCellSpacing
    }
    
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, insetForSectionAt section: Int) -> UIEdgeInsets {
        return UIEdgeInsets(top: 0, left: marginLeft, bottom: 0, right: marginLeft)
    }
    
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, sizeForItemAt indexPath: IndexPath) -> CGSize {
        let cellWith = ceil((bounds.width - marginLeft * 2) / CGFloat(arrayTabs.count))
        return CGSize(width: cellWith , height: CellHeight)
    }
    
    func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        if self.selectingTab != indexPath.row {
            self.delegate?.didSelectTabAtIndex(indexPath.row)
            
            self.setSelectedTab(indexPath.row)
        }
    }
    
    func getCellPostX(index: Int) -> CGFloat {
        let textWidth = StringHelper.getTextWidth(arrayTabs[index], height: CellHeight, font: UIFont.systemFont(ofSize: FontSize))
        let cellWidth = (bounds.width - marginLeft * 2) / CGFloat(arrayTabs.count)
        var indicatorWidth = textWidth + IndicatorOffset * 2
        if indicatorWidth > cellWidth {
            indicatorWidth = cellWidth
        }
        let postX = marginLeft + CGFloat(index) * cellWidth + (cellWidth - indicatorWidth) / 2
        return postX
    }
    
    func updateIndicatorLayer() {
        var indicatorWidth = StringHelper.getTextWidth(arrayTabs[self.selectingTab], height: CellHeight, font: UIFont.systemFont(ofSize: FontSize)) + 2*IndicatorLeadingMargin
        
        let cellWidth = (bounds.width - marginLeft * 2) / CGFloat(arrayTabs.count)
 
        if indicatorWidth > cellWidth {
            indicatorWidth = cellWidth
        }
        
        if let indicatorFixedWidth = self.indicatorFixedWidth{
            indicatorWidth = indicatorFixedWidth
        }
        
        let postX = marginLeft + CGFloat(self.selectingTab) * cellWidth + (cellWidth - indicatorWidth) / 2
        
        indicatorLayer.frame = CGRect(x:postX, y: bounds.height - BottomPadding, width: indicatorWidth, height: IndicatorHeight)
    }
    
    func getMarginLeft() -> CGFloat{
        if arrayTabs.count < 2 || arrayTabs.count > 5 {
            return 0
        }
        let tabCount = CGFloat(arrayTabs.count) //number of tab
        let marginPercent = self.getStartPointPercented();//value that was defined by product team
        let screenWidth = bounds.width
        let tabWidthPercent = (1 - marginPercent * 2) / ( tabCount - 1) //percent of 1 tab
        let margin = ((1 - tabWidthPercent * tabCount) / 2) * screenWidth
        return margin;
    }
    
    func getStartPointPercented() -> CGFloat {
        switch (arrayTabs.count) {
        case 1:
            return 0.5
        case 2:
            return 0.3
        case 3:
            return 0.25
        case 4:
            return 0.125
        case 5:
            return 0.10
        default:
            return 0
        }
    }
    
    func scrollDidScroll(_ contentOffsetX: CGFloat) {
        let width = StringHelper.getTextWidth(arrayTabs[self.selectingTab], height: CellHeight, font: UIFont.systemFont(ofSize: FontSize)) + IndicatorOffset * 2
        let originalX = self.getCellPostX(index: self.selectingTab)
        var offsetX = (contentOffsetX - Constants.ScreenSize.SCREEN_WIDTH) / CGFloat(arrayTabs.count)
        if offsetX > width {
            offsetX = width
        }else if offsetX < (width * (-1)) {
            offsetX = (width * (-1))
        }
        indicatorLayer.frame = CGRect(x:originalX + offsetX , y: bounds.height - BottomPadding, width: width , height: IndicatorHeight)
    }
    
    func setSelectedTab(_ tabIndex: Int){
        self.selectingTab = tabIndex
        self.refreshUI()
    }
}

class MMTabSegmentSetting {
    var tabIndex: Int?
    var selectedTabColor: UIColor?
    var unSelectedTabColor: UIColor?
    var selectedIndicatorColor: UIColor?
    var unSelectedIndicatorColor: UIColor?
    
    init(tabIndex: Int? = nil,
         selectedTabColor: UIColor? = nil,
         unSelectedTabColor: UIColor? = nil,
         selectedIndicatorColor: UIColor? = nil,
         unSelectedIndicatorColor: UIColor? = nil){
        self.tabIndex = tabIndex
        self.selectedTabColor = selectedTabColor
        self.unSelectedTabColor = unSelectedTabColor
        self.selectedIndicatorColor = selectedIndicatorColor
        self.unSelectedIndicatorColor = unSelectedIndicatorColor
    }
}
