//
//  TagShopingCartSelectionViewController.swift
//  merchant-ios
//
//  Created by Vu Dinh Trung on 4/21/16.
//  Copyright © 2016 WWE & CO. All rights reserved.
//

import UIKit
import ObjectMapper
import PromiseKit

//@objc
protocol TagSelectionDelegate: NSObjectProtocol {
    func didSelectedItem(_ sku: Sku?, itemType : PostCreateData.ItemType)
}


class TagShopingCartSelectionViewController: WishListCartViewController {

    private var cart : Cart?
    private var listMerchant : [CartMerchant] = [CartMerchant]()
    var dataSource = [CartItem]()
    private var listCartItemIdSelected : [Int] = [Int]()
    let ReuseIdentifier = "CollectCell"
    private let HeaderHeight : CGFloat = 0
    private final let heightTopView: CGFloat = 104

    private let sectionInsets = UIEdgeInsets(top: Constants.Margin.Left, left: Constants.Margin.Left, bottom: 0.0, right: Constants.Margin.Right)
    weak var tagShoppingCartSelectionDelegate: TagSelectionDelegate?
    
    private final let NoCollectionItemCellID = "NoCollectionItemCellID"
	
	private final let SeperatorHeaderViewID_ShoppingCart = "SeperatorHeaderViewID_ShoppingCart"

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
            viewLocation: "Editor-ProductTag-Cart",
            viewType: "Post"
        )
    }

    
	override func viewDidAppear(_ animated: Bool) {
		isAppeared = true
		
		self.showFloatingActionButton(self.dataSource.count > 0)
	}

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        
        self.dataSource.removeAll()
        if LoginManager.getLoginState() == .validUser || (Context.anonymousShoppingCartKey() != nil && Context.anonymousShoppingCartKey() != "0") {
            self.showLoading()
            
            listCartItem({
                self.cart = CacheManager.sharedManager.cart
                if let cart = self.cart {
                    self.getListProductInShoppingCart(cart)
                }
                self.stopLoading()

                }, fail: {
                    self.stopLoading()
                    Log.error("error")

            })
        }
    }
	
    func getListProductInShoppingCart(_ cart: Cart) -> Void {
		self.dataSource.removeAll()
		
        if let merchants = cart.merchantList {
            for merchant in merchants {
                if let itemLists = merchant.itemList {
                    for item : CartItem in itemLists {
						if item.isProductValid() { //Fix bug MM-19496
							self.dataSource.append(item)
						}
                    }
                }
            }
        }
        
		firstLoaded = true
		self.collectionView.reloadData()
    }
	
    override func setupCollectionView() {
		
        self.collectionView!.register(CollectCell.self, forCellWithReuseIdentifier: ReuseIdentifier)
        self.collectionView.register(NoCollectionItemCell.self, forCellWithReuseIdentifier: NoCollectionItemCellID)
		
		self.collectionView.register(UICollectionReusableView.self, forSupplementaryViewOfKind: UICollectionElementKindSectionFooter, withReuseIdentifier: SeperatorHeaderViewID_ShoppingCart)
		
        self.collectionView.frame = CGRect(x: 0, y: 0.0, width: self.view.frame.width, height: self.view.frame.height - heightTopView)
    }
	
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
		Log.debug("self.dataSource.count : \(self.dataSource.count)")
        return self.dataSource.count
    }

	override func collectionView(_ collectionView: UICollectionView, viewForSupplementaryElementOfKind kind: String, at indexPath: IndexPath) -> UICollectionReusableView {
		var reusableview = UICollectionReusableView()
		if kind == UICollectionElementKindSectionFooter {
			reusableview = collectionView.dequeueReusableSupplementaryView(ofKind: kind, withReuseIdentifier: SeperatorHeaderViewID_ShoppingCart, for: indexPath)
			reusableview.backgroundColor = UIColor.yellow
		}
		return reusableview
	}
	
    override func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        if self.dataSource.count == 0 {
            let cell = collectionView.dequeueReusableCell(withReuseIdentifier: NoCollectionItemCellID, for: indexPath) as! NoCollectionItemCell
            cell.label.text = String.localize("LB_CA_CART_NOITEM")
            cell.imageView.image = UIImage(named: "cart_blank_icon")
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
            if  self.dataSource.count > 0 {
                let data = self.dataSource[indexPath.row] as CartItem
                cell.nameLabel.text = data.skuName
				
                cell.setProductImage(data.productImage)

                let priceText = NSMutableAttributedString()
                
                let saleFont = UIFont.systemFont(ofSize: 16)
                let retailFont = UIFont.systemFont(ofSize: 11)
                
                if data.isSale > 0 {
                    if let priceSale = data.priceSale.formatPrice() {
                        let saleText = NSAttributedString(
                            string: priceSale + " ",
                            attributes: [
                                NSAttributedStringKey.foregroundColor: UIColor.primary3(),
                                NSAttributedStringKey.font: saleFont,
                                NSAttributedStringKey.strikethroughStyle: NSUnderlineStyle.styleNone.rawValue
                            ]
                        )
                        
                        priceText.append(saleText)
                    }
                    
                    if let priceRetail = data.priceRetail.formatPrice() {
                        let retailText = NSAttributedString(
                            string: priceRetail,
                            attributes: [
                                NSAttributedStringKey.foregroundColor: UIColor(hexString: "#757575"),
                                NSAttributedStringKey.strikethroughStyle: NSUnderlineStyle.styleSingle.rawValue,
                                NSAttributedStringKey.font: retailFont,
                                NSAttributedStringKey.baselineOffset: (saleFont.capHeight - retailFont.capHeight) / 2
                            ]
                        )
                        
                        priceText.append(retailText)
                    }
                } else {
                    if let priceRetail = data.priceRetail.formatPrice() {
                        let retailText = NSAttributedString(
                            string: priceRetail,
                            attributes: [
                                NSAttributedStringKey.foregroundColor: UIColor.secondary2(),
                                NSAttributedStringKey.font: saleFont
                            ]
                        )
                        
                        priceText.append(retailText)
                    }
                }
                cell.priceLabel.attributedText = priceText
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
                return CGSize(width: self.view.frame.width, height: HeaderHeight)
            default:
                return CGSize(width: 0,height: 0)
                
            }
        default:
            return CGSize(width: 0,height: 0)
        }
    }
	
	override func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, referenceSizeForFooterInSection section: Int) -> CGSize {
		return CGSize.zero
	}

    override func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        if self.dataSource.count > 0 {
            let data = self.dataSource[indexPath.row] as CartItem
            let sku = PostCreateData.createSkuFromCart(data)
            self.tagShoppingCartSelectionDelegate?.didSelectedItem(sku, itemType: .category )
            self.navigationController?.popViewController(animated: true)
            
            self.view.recordAction(.Tap, sourceRef: sku.styleCode, sourceType: .Product, targetRef: "ProductTag", targetType: .Add)
        }
    }
}
