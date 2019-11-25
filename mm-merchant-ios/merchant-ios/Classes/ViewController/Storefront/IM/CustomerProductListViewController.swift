//
//  CustomerProductListViewController.swift
//  merchant-ios
//
//  Created by Vo Huy Hung on 5/24/16.
//  Copyright © 2016 WWE & CO. All rights reserved.
//

import UIKit
import PromiseKit
import ObjectMapper

class CustomerProductListViewController: MmCartViewController {
    
    let CellId = "ItemCell"
    private final let CellHeight : CGFloat = 175
    
    private var dataSource = [CartItem]()
    var wishlist : Wishlist?
    
    var viewHeight = CGFloat(0)
    
    var productAttachedHandler: ((_ data: CartItem) -> Void)?
    var conv: Conv?
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        self.collectionView.frame = CGRect(x: collectionView.frame.origin.x, y: 0, width: collectionView.frame.width, height: viewHeight)
        
        // Do any additional setup after loading the view.
        self.dataSource = [CartItem]()
        self.refreshWishList()
        
        self.collectionView.register(CustomerProductCell.self, forCellWithReuseIdentifier: CellId)
    }
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    func refreshWishList() {
        if LoginManager.getLoginState() == .validUser || Context.hasValidAnonymousWishListKey() {
            self.showLoading()
            
            firstly {
                return self.listWishlistItem(self.user?.userKey, saveToCache: false, completion: { wishlist in
                    if let cartItems = wishlist?.cartItems, let merchantId = self.conv?.merchantId, merchantId != Constants.MMMerchantId {
                        for item in cartItems {
                            if item.merchantId != merchantId {
                                wishlist!.cartItems!.remove(item)
                            }
                        }
                    }
                    
                    self.wishlist = wishlist
                })
            }.then { _ -> Void in
                self.reloadDataSource()
            }.always {
                self.stopLoading()
            }.catch { _ -> Void in
                Log.error("error")
            }
        } else {
            ErrorLogManager.sharedManager.recordNonFatalError(withException: .NullPointer)
        }
    }
    
    func reloadDataSource() {
        self.dataSource.removeAll()
        
        if let cartItems = self.wishlist?.cartItems {
            for cartItem in cartItems {
                self.dataSource.append(cartItem)
            }
        }
        
        self.collectionView!.reloadData()
    }
    
    func showProductDetailPage(cartItem:CartItem) {
        self.showLoading()
        
        _ = SearchService.searchStyleBySkuId(cartItem.skuId) { [weak self] (response) in
            if let strongSelf = self {
                strongSelf.stopLoading()
                
                if response.result.isSuccess && response.response?.statusCode == 200 {
                    if let style = Mapper<SearchResponse>().map(JSONObject: response.result.value)?.pageData?.first {
                        
                        let color = Color()
                        color.colorId = cartItem.colorId
                        color.colorKey = cartItem.colorKey
                        let styleFilter = StyleFilter()
                        styleFilter.colors = [color]
                        
                        let styleViewController = StyleViewController(style: style, styleFilter: styleFilter)
                        
                        strongSelf.navigationController?.isNavigationBarHidden = false
                        strongSelf.navigationController?.pushViewController(styleViewController, animated: true)
                    } else {
                        ErrorLogManager.sharedManager.recordNonFatalError(withException: .FailToParseAPIResponse)
                    }
                }
            } else {
                ErrorLogManager.sharedManager.recordNonFatalError(withException: .NullPointer)
            }
        }
    }
    
    //MARK: CollectionView
    override func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return self.dataSource.count
    }
    
    override func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        
        let cell = collectionView.dequeueReusableCell(withReuseIdentifier: CellId, for: indexPath) as! CustomerProductCell
        let data = self.dataSource[indexPath.row] as CartItem
        
        cell.data = data
        
        cell.cellTappedHandler = { [weak self] (data) in
            if let strongSelf = self {
                strongSelf.showProductDetailPage(cartItem: data)
            } else {
                ErrorLogManager.sharedManager.recordNonFatalError(withException: .NullPointer)
            }
        }

        cell.productAttachedHandler = { [weak self] (data) in
            if let strongSelf = self {
                if let callback = strongSelf.productAttachedHandler {
                    callback(data)
                } else {
                    ErrorLogManager.sharedManager.recordNonFatalError(withException: .NullPointer)
                }
            } else {
                ErrorLogManager.sharedManager.recordNonFatalError(withException: .NullPointer)
            }
        }
        
        return cell
    }
    
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, minimumInteritemSpacingForSectionAt section: Int) -> CGFloat {
        return 0.0
    }
    
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, minimumLineSpacingForSectionAt section: Int) -> CGFloat {
        return 0.0
    }
    
    //MARK: Item Size Delegate for Collection View
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, sizeForItemAt indexPath: IndexPath) -> CGSize {
        return CGSize(width: self.view.frame.size.width , height: CellHeight)
    }
    
}
