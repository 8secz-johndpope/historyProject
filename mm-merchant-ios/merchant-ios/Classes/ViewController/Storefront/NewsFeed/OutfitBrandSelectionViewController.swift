//
//  OutfitBrandSelectionViewController.swift
//  merchant-ios
//
//  Created by Vu Dinh Trung on 4/14/16.
//  Copyright © 2016 WWE & CO. All rights reserved.
//

import UIKit
import PromiseKit
import ObjectMapper

protocol OutfitBrandSelectionViewControllerDelegate: NSObjectProtocol {
    func returnDataSelectedAtIndexs(_ selectedObjectAtIndexs: [Any], listMode: ModeGetTagList, selectedIndexs: [Int])
}

class OutfitBrandSelectionViewController: MmViewController {

    
    
    var registerClass: AnyClass?
    var identifier : String?
    var searchBar =  UISearchBar()
    private var orginYSearhBar:CGFloat = 64.0
    private final let cellHeight : CGFloat = 75
    private final let topHeight: CGFloat = 64.0
    private final let heightLabel: CGFloat = 21.0
    private final let heightCollectionTop: CGFloat = 32.0
    private final let widhtLabel: CGFloat = 40.0
    
    private var CellId = "CellId"
    private var brandId = "BrandCollectionCellId"
    var userCellId = "ObjectCollectionCellId"
    var titleMain: String?
    var viewHeader = UIView()
    var labelHeader = UILabel()
    var mode : ModeGetTagList?
    var selectIndexs = [Int]()
    
    var hasLoadMore = false
    var merchants: NSMutableArray = NSMutableArray()
    var start: Int = 0
    var limit: Int = Constants.Paging.Offset
    var orgMerchants = [Merchant]()
    var arrayMerchant = [Merchant]()
    
    var dataSource = [User]()
    var users = [User]()
    var outfitBrandSelectionViewControllerDelegate: OutfitBrandSelectionViewControllerDelegate?
    
    var topView : UIView!
    var labelBrandTag = UILabel()
    var collectionViewTop : UICollectionView!
    var datasourceTop = NSMutableArray()
    
    var labelMaxTag = UILabel()
    var maxTag = 5
    var numberSelected = 0
    
    convenience init(selectedIndex:[Int], registerClass: AnyClass, id: String, title: String, mode: ModeGetTagList, object: OutfitBrandSelectionViewControllerDelegate, datasourceTop: [Any]){
        self.init(nibName: nil, bundle: nil)
        self.selectIndexs = selectedIndex
        self.registerClass = registerClass
        self.identifier = id
        self.titleMain = title
        self.mode = mode
        self.outfitBrandSelectionViewControllerDelegate = object
         let array = NSMutableArray(array: datasourceTop)
        self.datasourceTop = array
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        self.title = titleMain
        setupSearchBar()
        setupHeader()
        setupCollectionView()
        setupLeftButton()
        self.createRightButton(String.localize("LB_CA_CONFIRM"), action: #selector(OutfitBrandSelectionViewController.didSelectedRightButton))
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        
        start = 0
        
        loadingData()

    }
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }

    //MARK: - UI
    func setupLeftButton() -> Void {
        let buttonBack = UIButton(type: .custom)
        buttonBack.setImage(UIImage(named: "icon_cross"), for: UIControlState())
        buttonBack.frame = CGRect(x: 0, y: 0, width: Constants.Value.BackButtonWidth, height: Constants.Value.BackButtonHeight)
        buttonBack.contentEdgeInsets = UIEdgeInsets.init(top: 0, left: Constants.Value.BackButtonMarginLeft, bottom: 0, right: 0)
        let leftButton = UIBarButtonItem(customView: buttonBack)
        buttonBack.addTarget(self, action: #selector(OutfitBrandSelectionViewController.closeViewController), for: .touchUpInside)
        self.navigationItem.leftBarButtonItem = leftButton
    }

    func setupSearchBar() -> Void {
        searchBar.frame = CGRect(x: 0, y: orginYSearhBar, width: self.view.bounds.width, height: 40)
        searchBar.placeholder = String.localize("LB_CA_SEARCH")
        self.view.addSubview(self.searchBar)
        searchBar.delegate = self
        
        var textField : UITextField
        textField = searchBar.value(forKey: "_searchField") as! UITextField
        textField.layer.cornerRadius = 15
        textField.layer.masksToBounds = true
    }
    
    func setupHeader() -> Void {
        
        topView = UIView(frame: CGRect(x: 0, y: self.searchBar.frame.maxY, width: self.view.bounds.width, height: topHeight))
        
        let text = String.localize("LB_CA_BRANDS_TAGGED")
        let widthLabel = StringHelper.getTextWidth(text, height: heightLabel, font: self.labelBrandTag.font)
        labelBrandTag.frame = CGRect(x: Margin.left, y: (topHeight - heightLabel) / 2, width: widthLabel, height: heightLabel)
        labelBrandTag.text = text
        labelBrandTag.formatSize(14)
        topView.addSubview(labelBrandTag)
        
        let brandLayout: UICollectionViewFlowLayout = UICollectionViewFlowLayout()
        brandLayout.sectionInset = UIEdgeInsets(top: 0, left: 8, bottom: 0, right: 8)
        brandLayout.scrollDirection = UICollectionViewScrollDirection.horizontal
        
        var  frame:CGRect = CGRect.zero
        frame  = CGRect(x: labelBrandTag.frame.maxX + Margin.left, y: (topHeight - heightCollectionTop) / 2, width: (self.view.bounds.width - labelBrandTag.frame.maxX - Margin.left*2 - widhtLabel), height: heightCollectionTop)
        let collectionView = UICollectionView(frame: frame, collectionViewLayout: brandLayout)
        collectionView.showsHorizontalScrollIndicator = false
        collectionView.backgroundColor = UIColor.white
        collectionView.register(SuggestCollectionViewCell.self, forCellWithReuseIdentifier: CollectCellId)
        collectionView.delegate = self
        collectionView.dataSource = self
        self.collectionViewTop = collectionView
        self.collectionViewTop.register(BrandLogoCollectionViewCell.self, forCellWithReuseIdentifier: brandId)
        self.collectionViewTop.register(ObjectCollectionView.self, forCellWithReuseIdentifier: userCellId)
        self.topView.addSubview(self.collectionViewTop)
        self.view.addSubview(self.topView)
        
        labelMaxTag.frame = CGRect(x: collectionViewTop.frame.maxX, y: (topHeight - heightLabel) / 2, width: self.widhtLabel, height: heightLabel)
        labelMaxTag.text = String.init(format: "%d/%d", self.datasourceTop.count, maxTag)
        labelMaxTag.formatSize(14)
        labelMaxTag.textAlignment = .center
        topView.addSubview(labelMaxTag)
        
        self.viewHeader.frame = CGRect(x: 0, y: topView.frame.maxY, width: self.view.frame.width, height: 40)
        self.viewHeader.backgroundColor = UIColor.primary2()
        self.view.addSubview(self.viewHeader)
        
        self.labelHeader.frame = CGRect(x: 46, y: 9,width: ( self.viewHeader.frame.width - 55)/2, height: 21)
        self.labelHeader.formatSize(14)
        self.labelHeader.text = String.localize("LB_CA_TAG_BRAND_FOLLOWED")
        self.viewHeader.addSubview(self.labelHeader)
        
        
    }
    
    func setupCollectionView() -> Void {
        
        self.collectionView.frame = CGRect(x: 0, y: self.viewHeader.frame.maxY, width: self.view.bounds.width, height: self.view.bounds.height - self.viewHeader.frame.maxY)
        self.collectionView.register(registerClass.self, forCellWithReuseIdentifier: identifier!)
        self.collectionView.delegate = self
        self.collectionView.dataSource = self
        
    }
    
    //MARK: - Action
    @objc func closeViewController(_ sender: UIBarButtonItem) -> Void {
        self.dismiss(animated: true) { 
            
        }
    }
    
    @objc func didSelectedRightButton(_ sender: UIBarButtonItem) -> Void {
        if !selectIndexs.isEmpty {
            var arraySelected = [Merchant]()
            
            for i in 0 ..< selectIndexs.count {
                arraySelected.append(merchants.object(at: selectIndexs[i]) as! Merchant)
            }
            
            self.outfitBrandSelectionViewControllerDelegate?.returnDataSelectedAtIndexs(arraySelected, listMode: .brandTagList, selectedIndexs: selectIndexs)
            self.dismiss(animated: true, completion: nil)
        }
    }
    
    //MARK: - Delegate & data source
    func numberOfSections(in collectionView: UICollectionView) -> Int {
        return 1
    }
    
    override func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        switch (collectionView) {
        case self.collectionView:
            return self.merchants.count
        case self.collectionViewTop:
            return self.datasourceTop.count
        default:
            return 0
        }
    }
    
    override func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        switch collectionView {
        case self.collectionView:
            let cell = collectionView.dequeueReusableCell(withReuseIdentifier: identifier!, for: indexPath) as! OutfitBrandViewCell
            cell.tag = indexPath.row
            setupDataForCell(indexPath, cell: cell)
            if self.self.merchants.count > 0 {
                if self.checkExist(self.merchants[indexPath.row] as Any){
                    cell.imageViewIcon.image = UIImage(named: "icon_checkbox_checked")
                } else {
                    cell.imageViewIcon.image = UIImage(named: "icon_checkbox_unchecked2")
                }
            }
            
            return cell
        case self.collectionViewTop:
            
            let cell = registerClassTop(collectionView, id: brandId, indexPath: indexPath) as! BrandLogoCollectionViewCell
            cell.setupDataByMerchant(self.datasourceTop[indexPath.row] as! Merchant)
            cell.tag = indexPath.row
            return cell
        default:
            return getDefaultCell(collectionView, cellForItemAt: indexPath)
            
        }
    }
    
    func registerClassTop(_ collectionView: UICollectionView, id: String, indexPath: IndexPath) -> Any{
        let cell = collectionView.dequeueReusableCell(withReuseIdentifier: id, for: indexPath)
        return cell
    }
    
    func setupDataForCell(_ indexPath: IndexPath, cell: OutfitBrandViewCell) -> Void {
        let merchant = merchants[indexPath.row]
        cell.setupDataCell(merchant as! Merchant)
    }
    
    func getDefaultCell(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell{
        let cell = collectionView.dequeueReusableCell(withReuseIdentifier: CellId, for: indexPath)
        return cell
    }
    
    func loadingCellForIndexPath(_ indexPath: IndexPath) -> UICollectionViewCell {
        let cell = getDefaultCell(self.collectionView, cellForItemAt: indexPath)
        let activity = UIActivityIndicatorView(activityIndicatorStyle: UIActivityIndicatorViewStyle.whiteLarge)
        activity.center = cell.center
        cell .addSubview(activity)
        activity.startAnimating()
        return cell
    }
    
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, minimumInteritemSpacingForSectionAt section: Int) -> CGFloat {
        return 10.0
    }
    
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, minimumLineSpacingForSectionAt section: Int) -> CGFloat {
        return 10.0
    }
    
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, sizeForItemAt indexPath: IndexPath) -> CGSize {
        switch (collectionView) {
        case self.collectionView:
            return CGSize(width: self.view.frame.size.width , height: cellHeight)
        case self.collectionViewTop:
            return CGSize(width: heightCollectionTop, height: heightCollectionTop)
        default:
            return CGSize(width: self.view.frame.size.width / 4, height: Constants.Value.CatCellHeight)
        }
        
    }
    
    
    
    func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        switch collectionView {
        case self.collectionView:
            didSelectedItemAtIndex(indexPath)
            break
        case self.collectionViewTop:
            deSelectedItemAtIndex(indexPath)
            break
        default:
            break
        }
        didSelectedItemAtIndex(indexPath)
        
    }
    
    func checkExist(_ selectedObject:Any) -> Bool {
        if mode == ModeGetTagList.brandTagList {
            for item in self.datasourceTop {
                let mer = item as! Merchant
                if mer.merchantId == (selectedObject as! Merchant).merchantId {
                    return true
                }
            }
            
            return false
            
        } else {
            for item in self.datasourceTop {
                let mer = item as! User
                if mer.userKey == (selectedObject as! User).userKey {
                    return true
                }
            }
            return false
        }
    }
    
    func removeObject (_ selectedObject:Any) {
        if mode == ModeGetTagList.brandTagList {
            for item in self.datasourceTop {
                let mer = item as! Merchant
                if mer.merchantId == (selectedObject as! Merchant).merchantId {
                    self.datasourceTop.remove(item)
                }
            }
            
        } else {
            for item in self.datasourceTop {
                let mer = item as! User
                if mer.userKey == (selectedObject as! User).userKey {
                    self.datasourceTop.remove(item)
                }
            }
        }
    }
    
    func updateLayout(_ selectedObject: Any, isSelected: Bool) {
        if isSelected {
            if !checkExist(selectedObject) {
                self.datasourceTop.add(selectedObject)
            }
            
        } else {
            if checkExist(selectedObject){
                removeObject(selectedObject)
            }
        }

        
        self.labelMaxTag.text = String(format: "%d/%d", self.datasourceTop.count, self.maxTag)
        self.collectionViewTop.reloadData()
    }
    
    func didSelectedItemAtIndex(_ indexPath: IndexPath) -> Void {
        
        if let cell = collectionView.cellForItem(at: indexPath) as? OutfitBrandViewCell {
            
            if !selectIndexs.contains(cell.tag){
				
				if selectIndexs.count < Constants.TagProduct.Limit {
					selectIndexs.append(cell.tag)
                    if mode == ModeGetTagList.brandTagList {
                        updateLayout((self.merchants[indexPath.row] as! Merchant), isSelected: true)
                    } else {
                        updateLayout((self.dataSource[indexPath.row] ), isSelected: true)
                    }
                    
				}
				
            } else {
                selectIndexs.remove(cell.tag)
                if mode == ModeGetTagList.brandTagList {
                    updateLayout((self.merchants[indexPath.row] as! Merchant), isSelected: false)
                } else {
                    updateLayout((self.dataSource[indexPath.row] ), isSelected: false)
                }
                
            }
            self.collectionView.reloadData()
        }
        
    }
    
    func deSelectedItemAtIndex(_ indexPath: IndexPath) {
        if mode == ModeGetTagList.brandTagList {
            
            let index = getIndexOfMerchant(self.datasourceTop[indexPath.row] as! Merchant)
            if index != -1 {
                updateLayout(self.datasourceTop[indexPath.row] as! Merchant, isSelected: false)
                removeIndexSelected(index)
            }
    
        } else {
            
                let index = getIndexOfUser(self.datasourceTop[indexPath.row] as! User)
                if index != -1 {
                    updateLayout(self.datasourceTop[indexPath.row] as! User, isSelected: false)
                    removeIndexSelected(index)
                }
                
            }
        
    }
    
    func removeIndexSelected(_ index: Int) {
        if selectIndexs.count <= Constants.TagProduct.Limit {
            if selectIndexs.contains(index) {
                self.selectIndexs.remove(index)
                self.collectionView.reloadData()
            }
        }
    }
    
    func getIndexOfUser(_ user: User) -> Int {
        for i  in 0...self.dataSource.count - 1 {
            if self.dataSource[i].userKey == user.userKey {
                return i
            }
        }
        return -1
    }
    
    func getIndexOfMerchant(_ merchant: Merchant) -> Int {
        for i in 0...self.merchants.count - 1 {
            if (self.merchants[i] as! Merchant).merchantId == merchant.merchantId {
                return i
            }
        }
        return -1
    }
    
    //MARK: get DATA
    func loadingData() -> Void {
        updateMerchantView(start, pageSize: limit)
    }
    
    
    func filter(_ text: String){
        let array = self.arrayMerchant.filter(){ ($0.merchantNameInvariant).lowercased().range(of: text.lowercased()) != nil }
        self.merchants = NSMutableArray(array: array)
        self.collectionView.reloadData()
    }
    
    func updateMerchantView(_ pageIndex: Int, pageSize: Int){
        firstly{
            
            return FollowService.listFollowingMerchants(pageIndex, limit: pageSize)
            }.then { merchants -> Void in
                
                self.orgMerchants = merchants
                
                if merchants.count > 0 {
                    for merchant in merchants {
                        merchant.followStatus = true
                        self.merchants.add(merchant)
                    }
                    self.arrayMerchant = NSArray(array: self.merchants) as! [Merchant]
                    
                    self.hasLoadMore = merchants.count >= self.limit
                    
                    self.start += self.limit
                    
                } else {
                    self.hasLoadMore = false
                }

                self.renderMerchantView()
            }.always {
                self.renderMerchantView()
                self.stopLoading()
            }.catch { _ -> Void in
                Log.error("error")
        }
    }
    
    func renderMerchantView() {
        self.merchants = NSMutableArray(array: self.arrayMerchant)
        self.collectionView.reloadData()
    }
    
    //MARK: -SearchBarDelegate
    
    
    func searchBarTextDidBeginEditing(_ searchBar: UISearchBar) {
        
    }
    
    func searchBarTextDidEndEditing(_ searchBar: UISearchBar) {
        
    }
    
    func searchBarCancelButtonClicked(_ searchBar: UISearchBar) {
        
        self.view.endEditing(true)
        
    }
    
    func searchBarSearchButtonClicked(_ searchBar: UISearchBar) {
        self.filter(searchBar.text!)
        searchBar.resignFirstResponder()
    }
    func searchBar(_ searchBar: UISearchBar, textDidChange searchText: String) {
        if searchText.length == 0 {
            self.renderMerchantView()
        } else {
            self.filter(searchText)
        }
    }
    
    func searchBarShouldBeginEditing(_ searchBar: UISearchBar) -> Bool {
        
        searchBar.showsCancelButton = true
        styleCancelButton(true)
        return true
    }
    
    func searchBarShouldEndEditing(_ searchBar: UISearchBar) -> Bool {
        searchBar.showsCancelButton = false
        return true
    }
    
    func styleCancelButton(_ enable: Bool){
        if enable {
            if let _cancelButton = searchBar.value(forKey: "_cancelButton"),
                let cancelButton = _cancelButton as? UIButton {
                cancelButton.isEnabled = enable //comment out if you want this button disabled when keyboard is not visible
                if title != nil {
                    cancelButton.setTitle(String.localize("LB_CANCEL"), for: UIControlState())
                }
            }
        }
    }
}
