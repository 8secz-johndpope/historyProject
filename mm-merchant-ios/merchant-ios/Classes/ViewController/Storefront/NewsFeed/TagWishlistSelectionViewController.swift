//
//  TagWishlistSelectionViewController.swift
//  merchant-ios
//
//  Created by Vu Dinh Trung on 4/21/16.
//  Copyright © 2016 WWE & CO. All rights reserved.
//

import UIKit
import ObjectMapper
import PromiseKit


class TagWishlistSelectionViewController: WishListCartViewController {
    
    private final let heightTopView: CGFloat = 104
	
    let ReuseIdentifier = "CollectCell"
	
    private let headerHeight : CGFloat = 0
	
    private let sectionInsets = UIEdgeInsets(top: Constants.Margin.Left, left: Constants.Margin.Left, bottom: 0.0, right: Constants.Margin.Right)
	
	var dataSource: [CartItem]!
    
    weak var tagWishlistSelectionDelegate: TagSelectionDelegate?
    
    private final let NoCollectionItemCellID = "NoCollectionItemCellID"
	
	private final let SeperatorHeaderViewID_Wishlist = "SeperatorHeaderViewID_Wishlist"
	
    override func viewDidLoad() {
        super.viewDidLoad()

        self.collectionView.backgroundColor = UIColor.white
        setupCollectionView()
        
        self.dataSource = [CartItem]()
        
        self.initAnalyticLog()
        
    }
    
    func initAnalyticLog(){
        let user = Context.getUserProfile()
        let authorType = user.userTypeString()
        initAnalyticsViewRecord(
            user.userKey,
            authorType: authorType,
            viewLocation: "Editor-ProductTag-Wishlist",
            viewType: "Post"
        )
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        
        if LoginManager.getLoginState() == .validUser || Context.hasValidAnonymousWishListKey() {
            self.showLoading()
            
            firstly {
                return self.listWishlistItem()
            }.then { _ -> Void in
                self.wishlist = CacheManager.sharedManager.wishlist
                self.reloadDataSource()
            }.always {
                self.stopLoading()
            }.catch { _ -> Void in
                Log.error("error")
            }
        }
        
    }
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
	override func setupCollectionView() {
        self.collectionView!.register(CollectCell.self, forCellWithReuseIdentifier: ReuseIdentifier)
        self.collectionView.register(NoCollectionItemCell.self, forCellWithReuseIdentifier: NoCollectionItemCellID)
		
		self.collectionView.register(UICollectionReusableView.self, forSupplementaryViewOfKind: UICollectionElementKindSectionFooter, withReuseIdentifier: SeperatorHeaderViewID_Wishlist)
		
		self.collectionView.frame = CGRect(x: 0, y: 0.0, width: self.view.frame.width, height: self.view.frame.height - heightTopView)
	}

	override func reloadDataSource() {
        self.dataSource.removeAll()
        
        if let cartItems = self.wishlist?.cartItems {
			for cartItem : CartItem in cartItems {
				if cartItem.isProductValid() { //Fix bug MM-19496
					self.dataSource.append(cartItem)
				}
            }
        }
		
        firstLoaded = true
        self.collectionView!.reloadData()
    }
	
    //MARK:- Delegate & Datasource
    
    override func numberOfSections(in collectionView: UICollectionView) -> Int {
        if collectionView == self.collectionView{
            return 1 //show placeholder
        }
        else{
            return 0
        }
    }
    
    override func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        if self.dataSource.count == 0 {
            return 1
        }
        return self.dataSource.count
    }
	
	override func collectionView(_ collectionView: UICollectionView, viewForSupplementaryElementOfKind kind: String, at indexPath: IndexPath) -> UICollectionReusableView {
		let view = collectionView.dequeueReusableSupplementaryView(ofKind: kind, withReuseIdentifier: SeperatorHeaderViewID_Wishlist, for: indexPath)
		return view
	}
    
    override func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        if self.dataSource.count == 0 {
            let cell = collectionView.dequeueReusableCell(withReuseIdentifier: NoCollectionItemCellID, for: indexPath) as! NoCollectionItemCell
            cell.label.text = String.localize("LB_CA_COLLECTION_PRODUCT_EMPTY")
            cell.imageView.image = UIImage(named: "icon_wishlist_default")
            cell.imageView.isHidden = !firstLoaded
            cell.label.isHidden = !firstLoaded
            return cell
        }
        
        switch collectionView {
        case self.collectionView!:
            let cell = collectionView.dequeueReusableCell(withReuseIdentifier: ReuseIdentifier, for: indexPath) as! CollectCell
            cell.backgroundColor = UIColor.white
            cell.nameLabel.lineBreakMode = NSLineBreakMode.byWordWrapping
            cell.nameLabel.numberOfLines = 2
            cell.nameLabel.textAlignment = .center
            if self.dataSource.count > 0 {
                let data = self.dataSource[indexPath.row] as CartItem
                cell.data = data
            }
            cell.heartImageView.isHidden = true
			
            return cell
        default:
            return getDefaultCell(collectionView, cellForItemAt: indexPath)
        }
    }
    
    func getDefaultCell(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell{
        let cell = collectionView.dequeueReusableCell(withReuseIdentifier: ReuseIdentifier, for: indexPath)
        return cell
    }
    
    override func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, sizeForItemAt indexPath: IndexPath) -> CGSize {
        if self.dataSource.count == 0 {
            return CGSize(width: view.width , height: view.height - (self.navigationController?.toolbar.frame.height)!)
        }
        switch collectionView {
        case self.collectionView!:
            let width = (self.view.frame.size.width - (Constants.Margin.Left + Constants.Margin.Right + Constants.LineSpacing.ImageCell)) / 2
            return CGSize(width: width, height: width * Constants.Ratio.ProductImageHeight + Constants.Value.ProductBottomViewHeight)
               default:
            return CGSize(width: 0,height: 0)
            
        }
        
    }
    
    override func collectionView(_ collectionView: UICollectionView,
                        layout collectionViewLayout: UICollectionViewLayout,
                               insetForSectionAt section: Int) -> UIEdgeInsets {
        switch collectionView {
        case self.collectionView!:
            return self.sectionInsets
        default:
            return UIEdgeInsets(top: 0.0, left: 0.0, bottom: 0.0, right: 0.0)
        }
    }
    
    override func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, minimumInteritemSpacingForSectionAt section: Int) -> CGFloat {
        switch collectionView {
        default:
            return 0.0
        }
        
    }
    
    override func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, minimumLineSpacingForSectionAt section: Int) -> CGFloat {
        switch collectionView {
        case self.collectionView!:
            return Constants.LineSpacing.ImageCell
        default:
            return 0.0
        }
    }
    
    
    override func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, referenceSizeForHeaderInSection section: Int) -> CGSize{
        switch collectionView {
        case self.collectionView:
            switch section {
            case 0:
                return CGSize(width: self.view.frame.width, height: headerHeight)
            default:
                return CGSize(width: 0,height: 0)
                
            }
        default:
            return CGSize(width: 0,height: 0)
        }
    }
    
    override func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        if self.dataSource.count > 0 {
            let cartItem = self.dataSource[indexPath.row] as CartItem
            firstly {
                return ProductManager.searchStyleWithSkuId(cartItem.skuId)
                }.then { response -> Void in
                    if let style = response as? Style {
                        style.selectedSkuId = cartItem.skuId
                        if let sku = style.defaultSku() {
                            if let key = style.findImageKeyByColorKey(sku.colorKey) {
                                sku.productImage = key
                            }
                            sku.brandImage = style.brandHeaderLogoImage
                            sku.brandName = style.brandName
                            self.tagWishlistSelectionDelegate?.didSelectedItem(sku, itemType: .wishlist)
                            
                            self.view.recordAction(.Tap, sourceRef: sku.styleCode, sourceType: .Product, targetRef: "ProductTag", targetType: .Add)
                        }
                        
                        self.navigationController?.popViewController(animated:true)
                    }
                }.catch { _ -> Void in
                    Log.error("error")
            }

        }
    }
}
