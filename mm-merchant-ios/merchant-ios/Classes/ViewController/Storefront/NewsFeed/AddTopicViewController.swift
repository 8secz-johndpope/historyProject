//
//  AddTopicViewController.swift
//  merchant-ios
//
//  Created by khanh.nguyen on 9/7/17.
//  Copyright © 2017 WWE & CO. All rights reserved.
//

import UIKit
import PromiseKit
import ObjectMapper

enum HashTagSection: Int {
    case historySection = 0,
    officalSection
}

protocol AddTopicDelegate {
    func selectedHashTag(tag: String)
}

class AddTopicViewController: MmViewController, HashTagHeaderDelegate {

    var delegate: AddTopicDelegate?
    var searchBar = UISearchBar()
    var cancelButton = UIButton()
    var officialHashTags = [HashTag]() {
        didSet {
            self.collectionView.reloadData()
        }
    }
    var filterDatasources = [HashTag]()
    var historyHashTags = [String]() {
        didSet {
            self.collectionView.reloadData()
        }
    }
    var isFilterMode = false
    var hashTagFlow = HashTagCollectionViewFlowLayout()

    
    override func getCustomFlowLayout() -> UICollectionViewFlowLayout {
        hashTagFlow.historySection = 0
        return hashTagFlow
    }
    override func viewDidLoad() {
        super.viewDidLoad()

        let width = CGFloat(50)
        let originY = CGFloat(20 + ScreenTop)
        
        cancelButton.frame = CGRect(x: self.view.frame.sizeWidth - Margin.left - width, y: originY, width: width, height: 40)
        cancelButton.addTarget(self, action: #selector(AddTopicViewController.cancelButtonClicked), for: .touchUpInside)
        cancelButton.setTitleColor(UIColor.secondary2(), for: UIControlState())
        cancelButton.setTitle(String.localize("LB_CA_CANCEL"), for: UIControlState())
        cancelButton.titleLabel?.font = UIFont.fontWithSize(14, isBold: false)
        self.view.addSubview(cancelButton)
        
        searchBar.frame = CGRect(x: 0, y: originY, width: self.view.bounds.width - width - Margin.left , height: 40)
        searchBar.placeholder = String.localize("LB_CA_POST_SEARCH_TOPIC")
        searchBar.isTranslucent = true
        searchBar.barTintColor = UIColor.white
        searchBar.searchBarStyle = UISearchBarStyle.minimal
        self.view.addSubview(self.searchBar)
        searchBar.delegate = self
        var textField : UITextField
        textField = searchBar.value(forKey: "_searchField") as! UITextField
        textField.layer.cornerRadius = 15
        textField.layer.masksToBounds = true
        
        self.setupCollectionView()
        setupDismissKeyboardGesture()
        dismissKeyboardGesture?.cancelsTouchesInView = false
        
        self.getListHistoryHashTag()
        _ = self.listFeatureTags()
        self.initAnalyticLog()
        
    }
    
    private func listFeatureTags() -> Promise<Any> {
        return Promise{ fulfill, reject in
            HashTagService.listFeatureTags(.Post, completion: { [weak self] (response) in
                if let strongSelf = self {
                    if response.result.isSuccess {
                        if let hashTagData = Mapper<HashTagList>().map(JSONObject: response.result.value) {
                            if let hashTagList = hashTagData.pageData {
                                let arraySlice = hashTagList.prefix(Constants.Value.MaximumOfficalHashTag)
                                strongSelf.officialHashTags = Array(arraySlice)
                                strongSelf.filterDatasources = strongSelf.officialHashTags
                            }
                        }
                        fulfill("OK")
                    } else {
                        reject(response.result.error ?? strongSelf.getError(response))
                    }
                }
                })
        }
    }
    
    private func getListHistoryHashTag() {
        self.historyHashTags = [String]()
        var maxWidth = CGFloat(0)
        let contraintWidth = self.view.frame.size.width - 2 * Margin.left
        var line = 1
        for item in Context.historyHashtags {
            let width = HashTagView.getCellWidth(item)
            if maxWidth == 0 && width == contraintWidth && line == 1 {
                line = line + 1
                maxWidth = contraintWidth
            }else {
                maxWidth += width + Margin.left / 2
            }
            
            
            if maxWidth  > contraintWidth * CGFloat(line) {
                line = line + 1
                maxWidth =  contraintWidth * CGFloat(line - 1) + width + Margin.left / 2
            }
            
            
            if line <= 2 {
                self.historyHashTags.append(item)
            }
        }
    }
    
    
    func initAnalyticLog(){
        let user = Context.getUserProfile()
        let authorType = user.userTypeString()
        initAnalyticsViewRecord(
            user.userKey,
            authorType: authorType,
            viewLocation: "Editor-Post-AddTopic",
            viewType: "Post"
        )
    }
    
    @objc func cancelButtonClicked(_ sender: Any) {
        self.delegate?.selectedHashTag(tag: "")
        self.dismiss(animated: true) { 
            
        }
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    override func shouldHaveCollectionView() -> Bool {
        return true
    }
    
    //MARK:- search bar delegate
    
    func searchBar(_ searchBar: UISearchBar, textDidChange searchText: String) {
        if searchText.length == 0 {
            filterDatasources = self.officialHashTags
        }else {
            filterDatasources = self.officialHashTags.filter(){ ($0.tag).lowercased().range(of: searchText.lowercased()) != nil }
            let array = self.officialHashTags.filter(){ ($0.tag).lowercased() == searchText.lowercased() }
            if array.count == 0 {
                let newHashTag = HashTag.init(name: searchText, placeHolderString: String.localize("LB_CA_POST_SEARCH_TOPIC_UCG"))
                filterDatasources.insert(newHashTag, at: 0)
            }
            self.view.recordAction(.Tap, sourceRef: searchText, sourceType: .Topic, targetRef: "Editor-Post", targetType: .View)
            
        }
        isFilterMode = searchText.length > 0
        self.collectionView.reloadData()
    }
    
    func searchBarSearchButtonClicked(_ searchBar: UISearchBar) {
        
    }
    
    func searchBarShouldBeginEditing(_ searchBar: UISearchBar) -> Bool {
        return true
    }
    

    func searchBar(_ searchBar: UISearchBar, shouldChangeTextIn range: NSRange, replacementText text: String) -> Bool {
        if let _ = text.rangeOfCharacter(from: CharacterSet.whitespaces) {
            return false
        }

        let currentString = (searchBar.text ?? "") as NSString
        var width = StringHelper.getTextWidth(String.localize("LB_CA_POST_SEARCH_TOPIC_UCG"), height: 20, font: UIFont.fontWithSize(14, isBold: false))
        let maxLength = self.view.frame.sizeWidth - width - Margin.left * 3
        
        let newString: String = "#" + currentString.replacingCharacters(in: range, with: text)
        
        width = StringHelper.getTextWidth(newString as String, height: 20, font: UIFont.fontWithSize(14, isBold: false))
        
        return width <= maxLength

    }
    
    func setupCollectionView() {
        
        
        collectionView.frame = CGRect(x: 0, y: searchBar.frame.maxY, width: self.view.frame.sizeWidth, height: self.view.frame.sizeHeight - searchBar.frame.maxY)
        collectionView.contentInset = UIEdgeInsets.zero
        collectionView.backgroundColor = UIColor.clear
        
        collectionView.showsHorizontalScrollIndicator = false
        collectionView.dataSource = self
        collectionView.delegate = self
        collectionView.register(HashTagCell.self, forCellWithReuseIdentifier: HashTagCell.CellIdentifier)
        collectionView.register(HashTagHeaderView.self, forSupplementaryViewOfKind: UICollectionElementKindSectionHeader, withReuseIdentifier: HashTagHeaderView.ViewIdentifier)
        collectionView.register(HashTagOfficalCell.self, forCellWithReuseIdentifier: HashTagOfficalCell.CellIdentifier)
        
        
    }
    
    override func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        if indexPath.section == HashTagSection.historySection.rawValue {
            let cell = collectionView.dequeueReusableCell(withReuseIdentifier: HashTagCell.CellIdentifier, for: indexPath) as! HashTagCell
            
            let text = historyHashTags[indexPath.row]
            cell.label.text = text
            
            if let viewKey = self.view.analyticsViewKey {
                cell.initAnalytics(withViewKey: viewKey, impressionKey: AnalyticsManager.sharedManager.recordImpression( impressionType: "HistoryTopic", impressionDisplayName: text, positionComponent: "HistoryListing", positionIndex: indexPath.row + 1, positionLocation: "Editor-Post-AddTopic", viewKey: viewKey))
            }

            
            
            return cell

        }else {
            let cell = collectionView.dequeueReusableCell(withReuseIdentifier: HashTagOfficalCell.CellIdentifier, for: indexPath) as! HashTagOfficalCell
            
            let hashTag =  filterDatasources[indexPath.row]
            cell.data = hashTag
            
            if let viewKey = self.view.analyticsViewKey {
                cell.initAnalytics(withViewKey: viewKey, impressionKey: AnalyticsManager.sharedManager.recordImpression( impressionType: "HotTopic", impressionDisplayName:  hashTag.getHashTag(), positionComponent: "HotListing", positionIndex: indexPath.row + 1, positionLocation: "Editor-Post-AddTopic", viewKey: viewKey))
            }
            
            
            return cell
        }
    }
    
    func collectionView(_ collectionView: UICollectionView, viewForSupplementaryElementOfKind kind: String, at indexPath: IndexPath) -> UICollectionReusableView {
        if kind == UICollectionElementKindSectionHeader {
            if let view = collectionView.dequeueReusableSupplementaryView(ofKind: UICollectionElementKindSectionHeader, withReuseIdentifier: HashTagHeaderView.ViewIdentifier, for: indexPath) as? HashTagHeaderView {
                if indexPath.section == HashTagSection.historySection.rawValue {
                    view.leftLabel.text = String.localize("LB_CA_POST_ADDED_TOPIC_HISTORY")
                    view.iconImageView.isHidden = false
                }else {
                    view.leftLabel.text = String.localize("LB_CA_POST_ADDED_TOPIC_FEATURED")
                    view.iconImageView.isHidden = true
                }
                view.delegate = self
                return view
            }
        }
        return UICollectionReusableView()
    }
    
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, referenceSizeForHeaderInSection section: Int) -> CGSize {
        
        if isFilterMode || (section == HashTagSection.historySection.rawValue && historyHashTags.count == 0) || (section == HashTagSection.officalSection.rawValue && self.officialHashTags.count == 0) {
            return CGSize.zero
        }else {
            return CGSize(width: collectionView.frame.size.width, height: 50)
        }
    }

    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, insetForSectionAt section: Int) -> UIEdgeInsets {
        if section == 0 {
            return UIEdgeInsets(top: 0, left: 15, bottom: 0, right: 15)
        }
        return UIEdgeInsets.zero
    }

    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, minimumInteritemSpacingForSectionAt section: Int) -> CGFloat {
        if section == 0 {
            return 10.0
        }
        return 0.0
    }
    
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, minimumLineSpacingForSectionAt section: Int) -> CGFloat {
        if section == HashTagSection.historySection.rawValue {
            return 10.0
        }
        return 0.0
    }
    
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, sizeForItemAt indexPath: IndexPath) -> CGSize {
        if indexPath.section == HashTagSection.historySection.rawValue {
            let text =  historyHashTags[indexPath.row]
            return CGSize(width: HashTagView.getCellWidth(text), height: HashTagView.HashTagHeight)
        }else {
            return CGSize(width: self.collectionView.frame.width, height: HashTagOfficalCell.ViewHeight)
        }
        
    }
    
    
    func numberOfSections(in collectionView: UICollectionView) -> Int {
        return 2
    }
    
    override func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        if section == HashTagSection.historySection.rawValue {
            return isFilterMode ? 0 : historyHashTags.count
        }else {
            return filterDatasources.count
        }
    }
    
    func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        var result = ""
        var sourceType = AnalyticsActionRecord.ActionElement.Unknown
        if indexPath.section == HashTagSection.historySection.rawValue {
            result = historyHashTags[indexPath.row]
            sourceType = .HistoryTopic
        }else {
            result = filterDatasources[indexPath.row].getHashTag()
            sourceType = .HotTopic
        }
        
        self.delegate?.selectedHashTag(tag: result + " ")
        self.dismiss(animated: true, completion: nil)
        
        self.view.recordAction(.Tap, sourceRef: result, sourceType: sourceType, targetRef: "Editor-Post", targetType: .View)
    }

    //MARK:- HashTag Header View Delegate
    func hashtagHeaderClickOnRecycleButton() {
        Context.historyHashtags = [String]()
        self.historyHashTags = [String]()
        self.collectionView.reloadData()
    }
    
    //MARK: - Keyboard notification
    
    override func keyboardWillHideNotification(_ notification: NSNotification) {
        super.keyboardWillShowNotification(notification)
        collectionView.contentInset = UIEdgeInsets.zero
        collectionView.scrollIndicatorInsets = UIEdgeInsets.zero
        
        
    }
    
    override func keyboardWillShowNotification(_ notification: NSNotification) {
        super.keyboardWillShowNotification(notification)
        if let keyboardSize = (notification.userInfo?[UIKeyboardFrameEndUserInfoKey] as? NSValue)?.cgRectValue {
            
            let contentInsets = UIEdgeInsets(top: 0.0, left: 0.0, bottom: keyboardSize.height, right: 0.0)
            
            collectionView.contentInset = contentInsets
            collectionView.scrollIndicatorInsets = contentInsets
            
        }
        
        
    }

    

}

internal class HashTagCollectionViewFlowLayout : UICollectionViewFlowLayout{
    var historySection: Int = -1
    
    override func layoutAttributesForElements(in rect: CGRect) -> [UICollectionViewLayoutAttributes]? {
        let attributes = super.layoutAttributesForElements(in: rect)
        
        var leftMargin: CGFloat = Margin.left
        var maxY: CGFloat = -1.0
        
        attributes?.forEach { layoutAttribute in
            if layoutAttribute.indexPath.section == self.historySection && layoutAttribute.representedElementKind != UICollectionElementKindSectionHeader{
                if layoutAttribute.frame.origin.y >= maxY {
                    leftMargin = CGFloat(15)
                }
                layoutAttribute.frame.origin.x = leftMargin
                
                leftMargin += layoutAttribute.frame.width + CGFloat(8)
                maxY = max(layoutAttribute.frame.maxY , maxY)
            }
        }
        
        return attributes
    }
}
