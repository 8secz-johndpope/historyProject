//
//  MerchantListViewController.swift
//  merchant-ios
//
//  Created by Trung Vu on 3/7/16.
//  Copyright © 2016 WWE & CO. All rights reserved.
//

import UIKit
import PromiseKit
import ObjectMapper
import Alamofire

enum MerchantGetMode: Int {
    case getMerchantListByUserKey = 0
    case getmerchantListByMerchantId
}
class MerchantListViewController: MmViewController, MerchantCellDelegate, FollowViewControllerDelegate {
    
    private final let CellId = "Cell"
    private final let MerchantListCellId = "MerchantListViewCell"
    
    private final let CatCellHeight : CGFloat = 40
    private final let CellHeight : CGFloat = 85
    private final let heightTopView: CGFloat = 144
    var contentView = UIView()
    var dataSource  = NSArray()
    var merchants: NSMutableArray = NSMutableArray()
    var start: Int = 0
    var limit: Int = Constants.Paging.Offset
    var orgMerchants = [Merchant]()
    var arrayMerchant = [Merchant]()
    
    var currentProfileType: TypeProfile = TypeProfile.Private
    var user: User = User()
    var merchantGetMode: MerchantGetMode?
    var merchant = Merchant()
    var hasLoadMore = false
    var searchText:String = ""
    var searchBar:UISearchBar?
    
    override func viewDidLoad() {
        super.viewDidLoad()
        setupCollectionView()
        initAnalyticLog()
        view.backgroundColor = UIColor.backgroundGray()
    }
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
	
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)

        reloadData()
    }
	
    func reloadData(){
        start = 0
        refreshCollectionView()
        
        switch (currentProfileType) {
        case .Private:
            self.updateMerchantView(start, pageSize: limit)
            break
        case .Public:
            self.updateMerchantView(start, pageSize: limit, userKey: user.userKey)
            
            break
        }
    
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        //        super.viewWillDisappear(animated)
		// override to stop calling super class viewWillDisappear
    }
	
    //MARK: - style View
    func setupCollectionView() {
        self.collectionView.delegate = self
        self.collectionView.dataSource = self
        self.collectionView.frame = CGRect(x: 0, y: 0, width: self.view.bounds.width, height: self.view.bounds.height - heightTopView)
        self.collectionView.backgroundColor = UIColor.backgroundGray()
        self.collectionView!.register(MerchantListViewCell.self, forCellWithReuseIdentifier: MerchantListCellId)
        self.collectionView?.register(NoCollectionItemCell.self, forCellWithReuseIdentifier: "NoCollectionItemCell")
    }
	
    func refreshCollectionView(){
        self.merchants.removeAllObjects()
        self.collectionView.reloadData()
    }
	
    //MARK: - delegate & datasource
    
    func numberOfSections(in collectionView: UICollectionView) -> Int {
        return 1
    }
    
    override func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        switch (collectionView) {
        case self.collectionView:
            return self.merchants.count + 1
        default:
            return 0
        }
    }
    
    override func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        switch collectionView {
        case self.collectionView:
            if(self.merchants.count == 0) {
                let cell = collectionView.dequeueReusableCell(withReuseIdentifier: "NoCollectionItemCell", for: indexPath) as! NoCollectionItemCell
                cell.label.text = String.localize("没有已收藏的商家")
//                cell.descriptionLabel.text = String.localize("LB_CA_NO_FOLLOWED_MERCHANT")
//                cell.imageView.image = UIImage(named: "placeholder_icon_follow")
                return cell
            }
            let cell = collectionView.dequeueReusableCell(withReuseIdentifier: MerchantListCellId, for: indexPath) as! MerchantListViewCell
			
			// hide follow / unfollow button for public profile
			cell.followButton.isHidden = (currentProfileType == .Public) && (user.userKey != Context.getUserKey())

            if indexPath.row == self.merchants.count {
                let cell = loadingCellForIndexPath(indexPath)
                if (!hasLoadMore) {
                    cell.isHidden = true
                } else {
                    cell.isHidden = false

                    switch (currentProfileType) {
                    case .Private:
                        self.updateMerchantView(start, pageSize: limit)
                        break
                    case .Public:
						self.updateMerchantView(start, pageSize: limit, userKey: user.userKey)
                        break
                    }
                }
                return cell
            }
            else {
				
                cell.delegateMerchantList = self
                cell.followButton.tag = indexPath.row
                if self.merchants.count > 0 {
                    if let merchant = self.merchants[indexPath.row] as? Merchant {
                        cell.followButton.isHidden =  false
                        cell.setupDataCell(merchant)
                        cell.analyticsViewKey = self.analyticsViewRecord.viewKey
                        if let viewKey = cell.analyticsViewKey {
                            cell.initAnalytics(withViewKey: viewKey, impressionKey: AnalyticsManager.sharedManager.recordImpression(impressionRef: "\(merchant.merchantId)", impressionType: "Merchant", impressionDisplayName: merchant.merchantName, merchantCode: "\(merchant.merchantId)", positionComponent: "BrandListing", positionIndex: indexPath.row + 1, positionLocation: "MyFollow-Brand", viewKey: viewKey))
                        }
                    }
                }
            }

            return cell
            
        default:
            return getDefaultCell(collectionView, cellForItemAt: indexPath)
            
        }
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
        return 0.0
    }
    
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, minimumLineSpacingForSectionAt section: Int) -> CGFloat {
        return 0.0
    }
	
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, sizeForItemAt indexPath: IndexPath) -> CGSize {
            switch (collectionView) {
            case self.collectionView:
                if self.merchants.count == 0 {
                    return CGSize(width: self.view.frame.size.width , height: self.collectionView.frame.height)
                }
                return CGSize(width: self.view.frame.size.width , height: CellHeight)
            default:
                return CGSize(width: self.view.frame.size.width / 4, height: Constants.Value.CatCellHeight)
            }
            
    }
    
    func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
         if self.merchants.count > 0 {
            let merchant = self.merchants[indexPath.row] as? Merchant
            
            if let merchant = merchant {
                Navigator.shared.dopen(Navigator.mymm.website_merchant_merchantId + "\(merchant.merchantId)")
            }
            //record action
            if let cell = collectionView.cellForItem(at: indexPath), let merchantId: Int = merchant?.merchantId {
                cell.recordAction(.Tap, sourceRef: String(format: "%d",merchantId), sourceType: .Merchant, targetRef: "MPP", targetType: .View)
                
                if searchText.length > 0 {
                    recordSearchBarAction(merchantId)
                }
            }
        }
    }
    
    func renderMerchantView() {
        self.merchants = NSMutableArray(array: self.arrayMerchant)
        self.collectionView.reloadData()
    }
	
    func searchTextChanged(_ text: String, searchBar: UISearchBar){
        searchText = text
        self.searchBar = searchBar
        if text.length == 0 {
            self.renderMerchantView()
        } else {
            self.filter(text, searchBar: searchBar)
        }
    }

    func filter(_ text: String, searchBar: UISearchBar){
        let array = self.arrayMerchant.filter(){ ($0.merchantNameInvariant).lowercased().range(of: text.lowercased()) != nil }
        self.merchants = NSMutableArray(array: array)
        self.collectionView.reloadData()
        if array.count == 0{
            recordSearchBarAction(nil)
        }
    }
    
    func recordSearchBarAction(_ merchantId: Int?){
        if let searchBar = self.searchBar{
            searchBar.initAnalytics(withViewKey: self.analyticsViewRecord.viewKey)
            searchBar.recordAction(.Input, sourceRef: searchText, sourceType: .Text, targetRef: (merchantId == nil ? "": merchantId?.toString()), targetType: .Merchant)
        }
    }
    
    func updateMerchantView(_ pageIndex: Int, pageSize: Int, userKey: String = Context.getUserKey()){

        firstly{
            
            return FollowService.listFollowingMerchants(pageIndex, limit: pageSize, userKey: userKey)
        }.then { (merchants) -> Void in
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
    
    
    // handle follow merchant
    func unfollowMerchant(_ merchant: Merchant, sender: ButtonFollow) {
        let message = String.localize("LB_CA_UNFOLLOW_CONF").replacingOccurrences(of: "{0}", with: merchant.merchantNameInvariant)
        Alert.alert(self, title: "", message: message, okActionComplete: { () -> Void in
            //record action
            
            if let analyticsImpressionKeySuperview = sender.superview?.analyticsImpressionKey {
                
                sender.initAnalytics(withViewKey: self.analyticsViewRecord.viewKey, impressionKey: analyticsImpressionKeySuperview)

                sender.recordAction(.Tap, sourceRef: "Unfollow", sourceType: .Button, targetRef: merchant.merchantCode, targetType: .Merchant)
                
            }
            sender.showLoading()
            merchant.isLoading = true
            // call api unfollow request
            firstly{
                return FollowService.requestUnfollow(merchant: merchant)
                
            }.then { _ -> Void in
                merchant.followStatus = false
                merchant.followerCount -= 1
                self.renderMerchantView()
                sender.hideLoading()
                merchant.isLoading = false
            }.catch { error -> Void in
                Log.error("error")
                let error = error as NSError
                if let apiResp = error.userInfo["data"] as? ApiResponse {
                    self.handleError(apiResp, statusCode: error.code, animated: true)
                }
                sender.hideLoading()
                merchant.isLoading = false
                self.collectionView.reloadData()
            }
                
        }, cancelActionComplete:nil)
    }
	
	
    func followMerchant(_ merchant: Merchant, sender: ButtonFollow) {
        //record action
        
        if let analyticsImpressionKeySuperview = sender.superview?.analyticsImpressionKey {
            
            sender.initAnalytics(withViewKey: self.analyticsViewRecord.viewKey, impressionKey: analyticsImpressionKeySuperview)

            sender.recordAction(.Tap, sourceRef: "Follow", sourceType: .Button, targetRef: merchant.merchantCode, targetType: .Merchant)
        }
        sender.showLoading()
        merchant.isLoading = true
        firstly{
            return FollowService.requestFollow(merchant: merchant)
            }.then { _ -> Void in
                merchant.followStatus = true
                merchant.followerCount += 1
                self.renderMerchantView()
                sender.hideLoading()
                merchant.isLoading = false
            }.catch { error -> Void in
                Log.error("error")
                let error = error as NSError
                if let apiResp = error.userInfo["data"] as? ApiResponse {
                    self.handleError(apiResp, statusCode: error.code, animated: true)
                }
                sender.hideLoading()
                merchant.isLoading = false
                self.collectionView.reloadData()
        }
    }
	
    
    
    //MARK: - MerchantCellDelegate
    func onTapFollowHandle(_ rowIndex: Int, sender: ButtonFollow) {
        let merchant = self.merchants[rowIndex] as! Merchant
        if merchant.followStatus == true {
            self.unfollowMerchant(merchant, sender: sender)
        } else {
            self.followMerchant(merchant, sender: sender)
        }
    }
    
    //MARK: FollowViewControllerDelegate
    func didSelectCancelButton(_ searchBar: UISearchBar) {
        log.debug("Cancel Search")
    }
    func didSelectSearchButton(_ text: String, searchBar: UISearchBar) {
        searchTextChanged(text, searchBar: searchBar)
    }
    
    func didTextChange(_ text: String, searchBar: UISearchBar) {
        searchTextChanged(text, searchBar: searchBar)
    }

    
    // MARK: Logging
    func initAnalyticLog(){
        let user = self.currentUser()
        if user.userName.length > 0 && user.userKey.length > 0{
            initAnalyticsViewRecord(
                nil,
                authorType: nil,
                brandCode: nil,
                merchantCode: user.merchant.merchantCode,
                referrerRef: nil,
                referrerType: nil,
                viewDisplayName: user.userName,
                viewParameters: nil,
                viewLocation: "MyFollow-Brand",
                viewRef: user.userKey,
                viewType: "User"
            )

        }
    }
    
    func currentUser() -> User{
        return (self.currentProfileType == .Public ? self.user : Context.getUserProfile())
    }
}
