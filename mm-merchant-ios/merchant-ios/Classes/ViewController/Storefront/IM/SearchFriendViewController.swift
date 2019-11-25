//
//  SearchFiendViewController.swift
//  merchant-ios
//
//  Created by HVN_Pivotal on 3/8/16.
//  Copyright © 2016 WWE & CO. All rights reserved.
//

import Foundation
import ObjectMapper
import PromiseKit


class SearchFriendViewController : MmViewController, UISearchResultsUpdating {
    
    private final let LimitOfSearch : Int = 50
    private var searchIndexOffset : Int = 0
    var hasLoadMore = false
    
    lazy var searchController = UISearchController(searchResultsController: nil)
    private final let CellHeight : CGFloat = 70
    private var isSearching : Bool = false
    var searchString : String = ""
    private(set) var dataSource: [User] = []
    private lazy var labelSearchResult = UILabel()
    private lazy var searchBarTextField = UITextField()
    
    private final let CellID = "CellID"
    private final let SearchFriendViewCellID = "SearchFriendViewCellID"
    
    override func viewDidLoad() {
        super.viewDidLoad()
        self.collectionView.register(SearchFriendViewCell.self, forCellWithReuseIdentifier: SearchFriendViewCellID)
        self.collectionView.register(UICollectionViewCell.self, forCellWithReuseIdentifier: CellID)
        self.collectionView.backgroundColor = UIColor.white
        self.collectionView.keyboardDismissMode = .onDrag;
        setupSearchResultsController()
        
        createSearchResultView()
        
        initAnalyticLog()
    }
    
    func initAnalyticLog() {
        initAnalyticsViewRecord(
            viewLocation: "Search-User",
            viewType: "User"
        )
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        self.showSearchBar()
        self.navigationItem.setHidesBackButton(true, animated: false)
    }

    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        if searchController.searchBar.text!.length < 1 && self.dataSource.count == 0 {
            labelSearchResult.isHidden = false
            DispatchQueue.main.async(execute: {
                self.searchController.searchBar.becomeFirstResponder()
            })
        }
    }

    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        searchBarTextField.layer.cornerRadius = searchBarTextField.bounds.height / 2
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        searchController.dismiss(animated: false, completion: nil)
    }
    
    func setupSearchResultsController(){
        self.searchController = UISearchController(searchResultsController: nil)
        self.searchController.searchResultsUpdater = self
        self.searchController.dimsBackgroundDuringPresentation = false
        self.searchController.hidesNavigationBarDuringPresentation = false
        self.searchController.searchBar.sizeToFit()
        definesPresentationContext = true
        self.searchController.searchBar.delegate = self
        self.searchController.searchBar.searchBarStyle = UISearchBarStyle.minimal
        self.searchController.searchBar.showsCancelButton = true
    }
    
    func createSearchResultView() {
        labelSearchResult = UILabel(frame: CGRect(x:0, y: self.view.frame.midY - 15, width: self.view.bounds.width, height: 30))
        labelSearchResult.format()
        labelSearchResult.textAlignment = .center
        labelSearchResult.text = String.localize("LB_SEARCH_NO_RESULT")
        labelSearchResult.isHidden = true
        self.view.addSubview(labelSearchResult)
    }

    //MARK: Collection View methods and delegates
    override func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        
        if hasLoadMore {
            return self.dataSource.count + 1
        }
        
        return self.dataSource.count
    }
    
    func numberOfSections(in collectionView: UICollectionView) -> Int {
        return 1
    }
    
    func getDefaultCell(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell{
        let cell = collectionView.dequeueReusableCell(withReuseIdentifier: CellID, for: indexPath)
        return cell
    }
    
    func loadingCellForIndexPath(_ indexPath: IndexPath) -> UICollectionViewCell {
        let cell = getDefaultCell(self.collectionView, cellForItemAt: indexPath)
        let activity = UIActivityIndicatorView(activityIndicatorStyle: UIActivityIndicatorViewStyle.gray)
        activity.center = cell.center
        cell.addSubview(activity)
        activity.startAnimating()
        
        return cell
    }
    
    override func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        
        if indexPath.row == dataSource.count {
            let cell = loadingCellForIndexPath(indexPath)
            if (!hasLoadMore) {
                cell.isHidden = true
            } else {
                cell.isHidden = false
                
                loadMore()
            }
            return cell
            
        } else {
            
            let cell = collectionView.dequeueReusableCell(withReuseIdentifier: SearchFriendViewCellID, for: indexPath) as! SearchFriendViewCell
            cell.isSearchFriend = true
            cell.addFollowButton.isHidden = true // MM-6144
            cell.addFriendButton.isHidden = true
            
            cell.analyticsViewKey = self.analyticsViewRecord.viewKey
            
            let user = dataSource[indexPath.row]
            cell.setData(user)
            
            // Impression tag
            let impressionKey = recordImpression(
                    impressionRef: user.userKey,
                    impressionType: user.userTypeString(),
                    impressionDisplayName: user.displayName,
                    merchantCode: user.merchant.merchantCode,
                    positionComponent: "UserListing",
                    positionIndex: indexPath.row + 1,
                    positionLocation: "Search-User"
            )
                
            cell.analyticsImpressionKey = impressionKey
            
            return cell
        }
    }
    
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, sizeForItemAt indexPath: IndexPath) -> CGSize {
        return CGSize(width: self.view.frame.size.width , height: CellHeight)
    }
    
    func collectionView(_ collectionView: UICollectionView,
        layout collectionViewLayout: UICollectionViewLayout,
        insetForSectionAt section: Int) -> UIEdgeInsets {
            return UIEdgeInsets(top: 0.0, left: 0.0, bottom: 0.0, right: 0.0)
    }
    
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, minimumInteritemSpacingForSectionAt section: Int) -> CGFloat {
        return 0.0
    }
    
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, minimumLineSpacingForSectionAt section: Int) -> CGFloat {
        return 0.0
    }
    
    func collectionView(_ collectionView: UICollectionView,
        didSelectItemAt indexPath: IndexPath) {
        Log.debug("didSelectItemAtIndexPath: \(indexPath.row)")
        
        if searchController.searchBar.isFirstResponder {
            searchController.searchBar.resignFirstResponder()
        }
        
        let user = dataSource[indexPath.row]
        
        if let cell = collectionView.cellForItem(at: indexPath) {
            // Action tag
            cell.recordAction(
                .Tap,
                sourceRef: user.userKey,
                sourceType: AnalyticsActionRecord.ActionElement(rawValue: user.userTypeString()) ?? .User,
                targetRef: user.targetProfilePageTypeString(),
                targetType: .View
            )
            
            // Action tag - Input search box
            cell.recordAction(
                .Input,
                sourceRef: searchString,
                sourceType: .Text,
                targetRef: user.userKey,
                targetType: .User
            )
        }
        
        self.showPublicProfile(user)
        
    }
    //MARK: Search Controller methods
    func updateSearchResults(for searchController: UISearchController) {
        if let text = searchController.searchBar.text {
            let string = text.trimmingCharacters(in: NSCharacterSet.whitespacesAndNewlines).lowercased()
            if string.length < 1{
                return
            }
        }
    }
    
    //MARK: Search bar methods
    func showSearchBar(){
        searchController.searchBar.alpha = 0
        navigationItem.titleView = self.searchController.searchBar
        navigationItem.setLeftBarButton(nil, animated: false)
        
        let uiButton = self.searchController.searchBar.value(forKey: "cancelButton") as! UIButton
        uiButton.setTitle(String.localize("LB_CANCEL"), for: .normal)
        
        searchController.searchBar.setImage(UIImage(named: "icon_search"), for: UISearchBarIcon.clear, state: .normal)
        searchController.searchBar.tintColor = UIColor.secondary2()
        searchController.searchBar.isUserInteractionEnabled = true
        searchController.searchBar.searchTextPositionAdjustment = UIOffset(horizontal: 10, vertical: 0)
        searchController.searchBar.setPositionAdjustment(UIOffset(horizontal: 2, vertical: 0), for: .search)
        
        for view in self.searchController.searchBar.subviews {
            for subsubView in view.subviews  {
                if let textField = subsubView as? UITextField {
                    textField.borderStyle = UITextBorderStyle.none
                    textField.layer.cornerRadius = 11
                    textField.backgroundColor = UIColor.backgroundGray()
                    textField.layer.borderColor = UIColor.backgroundGray().cgColor
                    textField.layer.borderWidth = 1.0
                    textField.placeholder = String.localize("LB_SEARCH")
                    textField.isEnabled = true
                    searchBarTextField = textField
                }
                
            }
        }
        
        UIView.animate(withDuration: 0.5, animations: { [weak self] in
            if let strongSelf = self {
                strongSelf.searchController.searchBar.alpha = 1
            }
            }, completion: { [weak self] finished in
                if let strongSelf = self {
                    strongSelf.searchController.searchBar.becomeFirstResponder()
                }
        })
    }
    
    //MARK: UISearchBarDelegate
    func searchBarCancelButtonClicked(_ searchBar: UISearchBar) {
        self.navigationController?.popViewController(animated: false)
    }
    
    func searchBarSearchButtonClicked(_ searchBar: UISearchBar) {
        searchBar.resignFirstResponder()
        
        searchString = searchController.searchBar.text!.trimmingCharacters(in: NSCharacterSet.whitespacesAndNewlines).lowercased()
        if searchString.length > 0 {
            doSearch(searchString, isRefresh:true)
        }
    }
    
    func loadMore(){
        if searchString.length > 0 {
            doSearch(searchString, isRefresh:false)
        }
    }
    
    func doSearch(_ string:String, isRefresh: Bool){
        
        if isSearching {
            return
        }
        isSearching = true
        firstly{
            return searchFriend(string, isRefresh: isRefresh)
            }.then { _ -> Void in
                self.isSearching = false
                self.reloadDataSource()
            }.always {
                if self.dataSource.isEmpty {
                    self.labelSearchResult.isHidden = false
                }
                else {
                    self.labelSearchResult.isHidden = true
                }
                self.isSearching = false
            }.catch { _ -> Void in
                Log.error("error")
        }
    }
    
    //MARK: Filter API Promise Call

    func searchFriend(_ string: String, isRefresh: Bool) -> Promise<Void> {
        if isRefresh {
            self.searchIndexOffset = 0
            self.dataSource.removeAll()
            self.reloadDataSource()
        }
        
        return Promise<Void> { fulfill, reject in
            FriendService.findFriend(string, limit: LimitOfSearch, startFrom: searchIndexOffset) {
                [weak self] (response) in
                if let strongSelf = self {
                    if response.result.isSuccess {
                        
                        if response.response?.statusCode == 200 {
                            
                            strongSelf.searchIndexOffset += strongSelf.LimitOfSearch
                            
                            let users = Mapper<User>().mapArray(JSONObject: response.result.value) ?? []
                            
                            if users.count >= strongSelf.LimitOfSearch {
                                strongSelf.hasLoadMore = true
                            } else {
                                strongSelf.hasLoadMore = false
                            }
                            
                            strongSelf.dataSource += users
                            strongSelf.dataSource.sortByDisplayName()
                            
                            fulfill(())
                        } else {
                            // status code not 200
                            reject(NSError(domain: "", code: -6003, userInfo: nil))
                            strongSelf.handleApiResponseError(response, reject: reject)
                        }
                    }
                    else{
                        reject(response.result.error!)
                        strongSelf.handleApiResponseError(response, reject: reject)
                    }
                }
            }
        }
    }
    
    func reloadDataSource() {
        self.collectionView?.reloadData()
    }
    
    func showPublicProfile(_ user: User) {
        
        var currentType: TypeProfile = .Private
        currentType =  user.userKey == Context.getUserKey() ? .Private : .Public
        
        if currentType == .Private{
//            let publicProfileVC = ProfileViewController()
//            publicProfileVC.currentType = TypeProfile.Public
//            publicProfileVC.publicUser = user
//            self.navigationController?.pushViewController(publicProfileVC, animated: true)
            Navigator.shared.dopen(Navigator.mymm.website_account)
        }else{
            Navigator.shared.dopen(Navigator.mymm.deeplink_u_userName + (user.userName.isEmpty ? user.userKey : user.userName))
//            let publicProfileVC = NewProfileViewController()
//            publicProfileVC.user = user
//            publicProfileVC.userKey = user.userKey
//            publicProfileVC.userName = user.userName
//            publicProfileVC.isHideTabBar = true
//            self.navigationController?.pushViewController(publicProfileVC, animated: true)
        }
    }

    func scrollViewDidScroll(_ scrollView: UIScrollView) {
        if searchController.searchBar.isFirstResponder {
            searchController.searchBar.resignFirstResponder()
        }
    }
}

