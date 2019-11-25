//
//  WishListViewController.swift
//  merchant-ios
//
//  Created by khanh.nguyen on 12/21/16.
//  Copyright © 2016 WWE & CO. All rights reserved.
//

import UIKit
import PromiseKit
import ObjectMapper

class WishListViewController: MmViewController {
    
    private final let NoCollectionItemCellID = "NoCollectionItemCellID"
    private final let CellHeight: CGFloat = 100
    
    private var styles: [Style] = []
    var cartItems = [CartItem]()
    var wishlist: Wishlist?
    var firstLoaded = false
    weak var delegate : CreatePostProtocol?
    
    override func viewDidLoad() {
        super.viewDidLoad()
        super.pageAccessibilityId = "WishlistSelectPage"

        initAnalyticLog()
        setupCollectionView()
        NotificationCenter.default.addObserver(self, selector: #selector(self.didRemoveCartItem), name: NSNotification.Name(rawValue: "DidRemoveCartItem"), object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(WishListViewController.updateCollectionViewLayout), name: Constants.Notification.createPostDidUpdatePhoto, object: nil)
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        self.updateCollectionViewLayout()
        
        if LoginManager.getLoginState() == .validUser || Context.hasValidAnonymousWishListKey() {
            if !firstLoaded{
                startBackgroundLoadingIndicator(self.collectionView)
            }
            firstly {
                return self.listWishlistItem()
                }.then { _ -> Promise<Any> in
                    return self.searchStyleInWishlist()
                }.always{
                    self.stopBackgroundLoadingIndicator()
                    self.reloadDataSource()
                }.catch { _ -> Void in
                    Log.error("error")
            }
        }
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        
    }

    deinit {
        NotificationCenter.default.removeObserver(self)
    }
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    override func shouldHaveCollectionView() -> Bool {
        return true
    }

    @objc func updateCollectionViewLayout() {
        let maxY = CGFloat(64)
        self.collectionView.frame.originY = maxY
        self.collectionView.frame.sizeHeight = ScreenSize.height - maxY - (self.delegate?.getBottomViewHeight() ?? 0)
    }
    
    func setupCollectionView() {
        self.collectionView.frame = CGRect(x: 0, y: StartYPos, width: self.view.frame.width, height: self.view.frame.height)
        self.collectionView.register(WishListCollectionViewCell.self, forCellWithReuseIdentifier: WishListCollectionViewCell.CellIdentifier)
        self.collectionView.register(NoCollectionItemCell.self, forCellWithReuseIdentifier: NoCollectionItemCellID)
        self.collectionView.backgroundColor = UIColor.white
    }
    
    func listWishlistItem(_ userKey: String? = nil, saveToCache: Bool = true, completion complete:((_ wishlist: Wishlist?) -> Void)? = nil) -> Promise<Any> {
        return CacheManager.sharedManager.listWishlistItem(userKey, saveToCache: saveToCache, completion: complete)
    }
    
    func searchStyleInWishlist() -> Promise<Any> {
        return Promise{ fulfill, reject in
            
            self.wishlist = CacheManager.sharedManager.wishlist
            guard let wishlistCartItems = self.wishlist?.cartItems else {
                reject(NSError(domain: "", code: 0, userInfo: nil))
                return
            }
            
            var styleCodes = [String]()
            var merchantIds = [String]()
            for cartItem in wishlistCartItems {
                styleCodes.append(cartItem.styleCode)
                let merchantId = String(cartItem.merchantId)
                if !merchantIds.contains(merchantId) {
                    merchantIds.append(merchantId)
                }
            }
            
            if styleCodes.count <= 0 {
                reject(NSError(domain: "", code: 0, userInfo: nil))
                return
            }
            SearchService.searchStyleByStyleCodeAndMechantId(styleCodes.joined(separator: ","), merchantIds: merchantIds.joined(separator: ",")) { [weak self] (response) in
                if let strongSelf = self {
                    if response.result.isSuccess {
                        if let response = Mapper<SearchResponse>().map(JSONObject: response.result.value), let styles = response.pageData {
                            strongSelf.styles = styles
                            
                            for cartItem in wishlistCartItems {
                                if let style = strongSelf.styles.filter({ $0.styleCode == cartItem.styleCode }).first {
                                    cartItem.styleIsValid = style.isValid()
                                    cartItem.styleIsOutOfStock = style.isOutOfStock()
                                } else {
                                    cartItem.styleIsValid = false
                                }
                            }
                        } else {
                            ErrorLogManager.sharedManager.recordNonFatalError(withException: .FailToParseAPIResponse)
                        }
                        
                        fulfill("OK")
                    } else {
                        reject(response.result.error ?? NSError(domain: "", code: 0, userInfo: nil))
                    }
                } else {
                    ErrorLogManager.sharedManager.recordNonFatalError(withException: .NullPointer)
                }
            }
        }
    }
    
    func reloadDataSource() {
        self.cartItems.removeAll()
        
        if let cartItems = self.wishlist?.cartItems {
            for cartItem : CartItem in cartItems {
                if cartItem.styleIsValid {
                    self.cartItems.append(cartItem)
                    
                    if let selectedItem = self.delegate?.getSelectedItem() {
                        for i in 0..<selectedItem.count {
                            if selectedItem[i].defaultSkuId ==  cartItem.skuId {
                                cartItem.isSelected = true
                                break
                                
                            } else {
                                ErrorLogManager.sharedManager.recordNonFatalError(withException: .NullPointerOrTypeMismatch)
                            }
                        }
                    } else {
                        ErrorLogManager.sharedManager.recordNonFatalError(withException: .NullPointer)
                    }
                }
            }
        } else {
            ErrorLogManager.sharedManager.recordNonFatalError(withException: .NullPointer)
        }
        self.firstLoaded = true
        self.collectionView?.reloadData()
    }

    // MARK: - Delegate & Datasource

    func numberOfSections(in collectionView: UICollectionView) -> Int {
        return 1
    }

    override func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return self.cartItems.count > 0 ? self.cartItems.count : 1
    }
    
    override func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        if cartItems.count == 0 {
            if let cell = collectionView.dequeueReusableCell(withReuseIdentifier: NoCollectionItemCellID, for: indexPath) as? NoCollectionItemCell {
                cell.label.text = String.localize("LB_CA_COLLECTION_PRODUCT_EMPTY")
                cell.isHidden = !firstLoaded
                return cell
            } else {
                ErrorLogManager.sharedManager.recordNonFatalError(withException: .NullPointerOrTypeMismatch)
            }
        } else {
            if let cell = collectionView.dequeueReusableCell(withReuseIdentifier: WishListCollectionViewCell.CellIdentifier, for: indexPath) as? WishListCollectionViewCell {
                cell.backgroundColor = UIColor.white
                
                let cartItem = self.cartItems[indexPath.row]
                    cell.data = cartItem
                    if cartItem.isSelected {
                        cell.tickImageView.image = UIImage(named: "icon_checkbox_checked")
                    } else {
                        cell.tickImageView.image = UIImage(named: "icon_checkbox_unchecked2")
                    }
                
                self.setAccessibilityIdForView("UIBT_SELECT_PRODUCT", view: cell)
                return cell
            } else {
                ErrorLogManager.sharedManager.recordNonFatalError(withException: .NullPointerOrTypeMismatch)
            }
        }
        
        return UICollectionViewCell()
    }
    
    func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        if cartItems.count > 0 {
            if let del = self.delegate {
                let cartItem = self.cartItems[indexPath.row]
                if !del.isEnoughPhoto() || cartItem.isSelected {
                    cartItem.isSelected = !cartItem.isSelected
                    self.delegate?.didSelectCartItem(cartItem)
                    self.collectionView.reloadData()
                } else {
                    del.showErrorFull()
                }
            }
        }
    }
    
    func getDefaultCell(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell{
        let cell = collectionView.dequeueReusableCell(withReuseIdentifier: "", for: indexPath)
        return cell
    }
    
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, sizeForItemAt indexPath: IndexPath) -> CGSize {
        if self.cartItems.count == 0 {
            let maxY = CGFloat(64)
            return CGSize(width: ScreenSize.width, height: ScreenSize.height - maxY - (self.delegate?.getBottomViewHeight() ?? 0))
        }
        
        return CGSize(width: self.view.frame.size.width , height: CellHeight)
    }
    
    // MARK: - Notification
    @objc func didRemoveCartItem(_ notification: Notification) {
        if let skuId = notification.object as? Int {
            for cartItem in self.cartItems {
                if cartItem.skuId == skuId {
                    cartItem.isSelected = false
                    break
                }
            }
            
            self.collectionView.reloadData()
        } else {
            ErrorLogManager.sharedManager.recordNonFatalError(withException: .NullPointerOrTypeMismatch)
        }
    }
    
    //MARK: - Analytics
    
    
    func initAnalyticLog(){
        
        let user = Context.getUserProfile()
        let authorType = user.userTypeString()
        
        initAnalyticsViewRecord(
            Context.getUserKey(),
            authorType: authorType,
            brandCode: nil,
            merchantCode: nil,
            referrerRef: nil,
            referrerType: nil,
            viewDisplayName: nil,
            viewParameters: nil,
            viewLocation: "Editor-Image-Collection",
            viewRef: nil,
            viewType: "Post"
        )
    }
}
