//
//  PublicWishlistViewController.swift
//  merchant-ios
//
//  Created by Vu Dinh Trung on 3/27/16.
//  Copyright © 2016 WWE & CO. All rights reserved.
//

import UIKit
import PromiseKit
import ObjectMapper

class PublicWishlistViewController: WishListCartViewController {
	
	var publicUser = User()
	private final let NoCollectionItemCellID = "NoCollectionItemCellID"
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        currentType = .Public
        
        setupNavigationBar()
        createBackButton()
        setupLayout()
        initAnalyticLog()
    }

    func setupLayout() {
         self.view.frame = CGRect(x: 0, y: 0, width: Constants.ScreenSize.SCREEN_WIDTH, height: Constants.ScreenSize.SCREEN_HEIGHT)
        self.collectionView.frame = CGRect(x: 0, y: StartYPos, width: Constants.ScreenSize.SCREEN_WIDTH, height: self.view.height - 64 - tabBarHeight)
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        updateButtonCartState()
        refreshWishList()
    }
	
	override func viewDidAppear(_ animated: Bool) {
        updateButtonCartState()
        updateButtonWishlistState()
	}
	
    func setupNavigationBar() {
        setupNavigationBarCartButton()
        setupNavigationBarWishlistButton()
        
        self.navigationController?.isNavigationBarHidden = false
        
        var rightButtonItems = [UIBarButtonItem]()
        rightButtonItems.append(UIBarButtonItem(customView: buttonCart!))
        buttonCart?.addTarget(self, action: #selector(self.goToShoppingCart), for: .touchUpInside)

        rightButtonItems.append(UIBarButtonItem(customView: buttonWishlist!))
        buttonWishlist?.addTarget(self, action: #selector(self.goToWishList), for: .touchUpInside)

        buttonCart?.accessibilityIdentifier = "view_cart_button"
        buttonWishlist?.accessibilityIdentifier = "view_wishlist_button"
        
        self.title = String.localize("LB_CA_MY_COLLECTION")
        self.navigationItem.rightBarButtonItems = rightButtonItems
    }
    
	override func refreshWishList() {
//		if LoginManager.getLoginState() == .validUser || Context.hasValidAnonymousWishListKey() {
			self.showLoading()
            
			firstly {
				return self.fetchWishList(publicUser)
            }.then { _ -> Void in
                self.reloadDataSource()
            }.always {
   
                self.stopLoading()
                
            }.catch { _ -> Void in
                Log.error("error")
			}
//        } else {
//            self.firstLoaded = true
//            self.collectionView.reloadData()
//        }
	}
	
	func fetchWishList(_ user: User) -> Promise<Any>{
		return Promise{ fulfill, reject in
			WishlistService.listByPublicUser(user) { [weak self] (response) in
				if let strongSelf = self {
					if response.result.isSuccess {
						if response.response?.statusCode == 200 {
                            
                            if let wishlist = Mapper<Wishlist>().map(JSONObject: response.result.value) {
                                wishlist.cartItems?.sort(by: { (DateTransformExtension().transformFromJSON($0.lastModified) ?? Date()).compare((DateTransformExtension().transformFromJSON($1.lastModified) ?? Date())) == .orderedDescending })
                                strongSelf.wishlist = wishlist
                            }
							
							fulfill("OK")
						} else {
							var statusCode = 0
							if let code = response.response?.statusCode {
								statusCode = code
							}
							
							let error = NSError(domain: "", code: statusCode, userInfo: nil)
							reject(error)
						}
					} else {
						reject(response.result.error!)
					}
				}
			}
		}
	}

	// override collection view to disable swipe action on public wishlist
	override func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
		
        let cellFromSuper = super.collectionView(collectionView, cellForItemAt: indexPath)
        
        if let cell = cellFromSuper as? WishListItemCell {
            cell.leftMenuItems = nil
            cell.rightMenuItems = nil
            
            return cell
        }
        
        return cellFromSuper
	}
    
    override func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, referenceSizeForFooterInSection section: Int) -> CGSize {
        return CGSize(width: self.view.width, height: 0)
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
            viewDisplayName: "Wishlist",
            viewParameters: nil,
            viewLocation: "Wishlist",
            viewRef: publicUser.userKey,
            viewType: "User"
        )
    }
}
