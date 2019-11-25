//
//  MerchantDescriptionViewController.swift
//  merchant-ios
//
//  Created by Vu Dinh Trung on 3/18/16.
//  Copyright © 2016 WWE & CO. All rights reserved.
//

import UIKit
import ObjectMapper
import PromiseKit
import Kingfisher


enum DescriptionMode: Int {
    case modeCurator = 0,
    modeMerchant,
    modeBrand
}
class MerchantDescriptionViewController: MmViewController {
    
    private final let WidthItemBar : CGFloat = 25
    private final let HeightItemBar : CGFloat = 25
    private final let WidthLogo:CGFloat = 120.0
    private final let HeightLogo:CGFloat = 35.0
    private final let HeightImageCell: CGFloat = Constants.ScreenSize.SCREEN_WIDTH * Constants.Ratio.PanelImageHeight
    
    private final let DescriptionId = "DescriptionId"
    private final let CellId = "CellId"
    private final let DefaultUIEdgeInsets : UIEdgeInsets = UIEdgeInsets(top: 0.0, left: 0.0, bottom: 0.0, right: 0.0)
    
    var searchBarButtonItem : UIBarButtonItem!
    var buttonSearch: UIButton?
    var buttonBack = UIButton()
    var backButtonItem = UIBarButtonItem()
    var imageViewLogo: UIImageView?
    
    var merchant = Merchant() {
        didSet {
            headerLogoImage = merchant.headerLogoImage
        }
    }
    
    var brand = Brand(){
        didSet {
            if let mode = self.mode, mode == .modeBrand{
                self.headerLogoImage = self.brand.headerLogoImage
            }
        }
    }
    var user  = User()
    var label = UILabel()
    var merchantImages = [MerchantImage]()
    var mode: DescriptionMode!
    var headerLogoImage: String = ""
    var brandImages = [BrandImage]()
    
    var curatorImages = [CuratorImage]()
    let userkey = ""
    
    var merchantSummaryResponse: MerchantSummaryResponse!
    var imagesDataSource = [UIImage]()

	override func viewDidLoad() {
        super.viewDidLoad()
        
        configCollectionView()
        createBackButton()
        
        fetchRating()
	
		checkForCuratorUserDescription()
		
    }
	
	func checkForCuratorUserDescription() {
		
		if self.user.isCurator == 1 {
			if self.user.userKey == Context.getUserKey() {
				
				var rightButtonItems = [UIBarButtonItem]()

				let editBarBtn = UIBarButtonItem(title: String.localize("LB_CA_EDIT"), style: .plain, target: self, action: #selector(self.openCuratorAboutView))
				
				rightButtonItems.append(editBarBtn)
				
				self.navigationItem.rightBarButtonItems = rightButtonItems
			
				self.mode = .modeCurator
			}
		}
	}
	
	@objc func openCuratorAboutView() {
		let viewController = CuratorAboutViewController()
		self.navigationController?.push(viewController, animated: true)
	}

    func loadHeaderLogo() {
        if mode == DescriptionMode.modeMerchant || mode == DescriptionMode.modeBrand {
            addLogoOnNavi()
        } else if mode == DescriptionMode.modeCurator {
            self.title = user.displayName
        }
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        self.loadHeaderLogo()
		
		loadViewData()
		
    }
	
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        removeLogo()
    }
    
    //MARK: - Data Processing
    
    func loadViewData() {
		
		self.imagesDataSource.removeAll()
		
		if mode == .modeCurator {
			
			getDataSourceCurator()
			
		} else {
		
			if mode == .modeMerchant {
				if let images = merchant.merchantImages {
					merchantImages = images.filter({$0.imageTypeCode.lowercased().range(of: "Desc".lowercased()) != nil})
				}
			} else if mode == .modeBrand {
				if brand.brandImages != nil {
					brandImages = brand.brandImages!
				}
			}
			
			self.downloadImages {
                self.collectionView.reloadData()
			}
			
		}
    }
	
    func getDataSourceCurator() {
		
		self.showLoading()
		
		firstly {
			return fetchUser()
			}.then { _ -> Void in
				self.refreshImages()
			}.always {
				self.stopLoading()
			}.catch { _ -> Void in
				Log.error("error")
		}
		
    }
	
	func fetchUser() -> Promise<Any> {
		return Promise{ fulfill, reject in
			UserService.viewWithUserKey(self.user.userKey) { [weak self] (response) in
				if let strongSelf = self {
					if response.result.isSuccess {
						if response.response?.statusCode == 200 {
							strongSelf.user = Mapper<User>().map(JSONObject: response.result.value)!
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
	
	func refreshImages() {
		fetchImages(user.userKey) {
			self.downloadImages {
				self.collectionView.reloadData()
			}
		}
	}
	
    //MARK: - style UI
	
    func createBack(_ imageName: String, selectorName: String, size:CGSize,left: CGFloat, right: CGFloat) -> UIBarButtonItem {
        buttonBack.setImage(UIImage(named: imageName), for: UIControlState())
        buttonBack.frame = CGRect(x: 0, y: 0, width: size.width, height: size.height)
        buttonBack.contentEdgeInsets = UIEdgeInsets.init(top: 0, left: left, bottom: 0, right: right)
        buttonBack .addTarget(self, action:Selector(selectorName), for: UIControlEvents.touchUpInside)
        let temp:UIBarButtonItem = UIBarButtonItem()
        temp.customView = buttonBack
        return temp
    }
    func backupButtonColorOn() {
        buttonCart?.setImage(UIImage(named: "cart_grey"), for: UIControlState())
        buttonWishlist?.setImage(UIImage(named: "icon_heart_stroke"), for: UIControlState())
        buttonSearch?.setImage(UIImage(named: "search_grey"), for: UIControlState())
        buttonBack.setImage(UIImage(named: "back_grey"), for: UIControlState())
        if mode == DescriptionMode.modeMerchant || mode == DescriptionMode.modeBrand {
            addLogoOnNavi()
        } else if mode == DescriptionMode.modeCurator {
            self.title = user.displayName
        }
        
    }
    
    func addLogoOnNavi() {
        imageViewLogo = UIImageView(frame: CGRect(x: (self.view.frame.width - WidthLogo)/2, y: 0, width: WidthLogo, height: HeightLogo))
        setDataImageviewLogo(self.headerLogoImage)
        imageViewLogo?.tag = 99
        self.navigationItem.titleView = imageViewLogo!
    }
    
    func setDataImageviewLogo(_ key : String){
        let imageCategory: ImageCategory!
        if mode == DescriptionMode.modeMerchant {
            imageCategory = .merchant
        } else {
            imageCategory = .brand
        }
        imageViewLogo?.mm_setImageWithURL(ImageURLFactory.getRaw(self.headerLogoImage, category: imageCategory, width: ResizerSize.size256.rawValue), placeholderImage: nil, clipsToBounds: true, contentMode: .scaleAspectFit, progress: nil, optionsInfo: nil, completion: nil)
        imageViewLogo?.contentMode = .scaleAspectFit
    }
    
    func removeLogo() {
        self.navigationItem.titleView = nil
    }
    
    func searchIconClicked() {
        let searchViewController = ProductListSearchViewController()
        self.navigationController?.push(searchViewController, animated: false)
    }
    
    //MARK: - Collection View
    func configCollectionView() {        
        self.collectionView.delegate = self
        self.collectionView.dataSource = self
        self.collectionView.frame = CGRect(x: 0 , y: StartYPos, width: self.view.bounds.width, height: self.view.bounds.height - tabBarHeight - 64)
        // Setup Cell
        self.collectionView.register(MerchantImageViewCell.self, forCellWithReuseIdentifier: CellId)
        self.collectionView.register(DescriptionViewCell.self, forCellWithReuseIdentifier: DescriptionId)
        self.collectionView.register(MerchantDescriptionFooterView.self, forSupplementaryViewOfKind: UICollectionElementKindSectionFooter, withReuseIdentifier: MerchantDescriptionFooterView.FooterView)
        
        if let fontBold = UIFont(name: Constants.Font.Normal, size: 14) {
            label.font = fontBold
        } else {
            label.formatSizeBold(14)
        }
    }
    
    override func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        var count = 0
        if self.user.displayName.length > 0 || self.user.userDescription.length > 0 {
            count = count + 1
        }
        
        if self.merchant.merchantName.length > 0 || self.merchant.merchantDesc.length > 0 {
            count = count + 1
        }
        //		count = ((mode == DescriptionMode.ModeMerchant) ? (self.merchantImages.count + count) : self.brandImages.count + 1)
        
        switch mode! {
        case .modeMerchant:
            return imagesDataSource.count + count
        case .modeBrand:
            return self.imagesDataSource.count + 1
        case .modeCurator:
            return imagesDataSource.count + count
        }
        
        
    }
    override func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        
        let cell = collectionView.dequeueReusableCell(withReuseIdentifier: CellId, for: indexPath) as! MerchantImageViewCell
        switch (indexPath.row){
        case 0:
            let descriptionCell = collectionView.dequeueReusableCell(withReuseIdentifier: DescriptionId, for: indexPath) as! DescriptionViewCell
            
            switch mode! {
            case .modeMerchant:
                descriptionCell.setUpData(merchant)
            case .modeBrand:
                descriptionCell.setUpData(brand)
            case .modeCurator:
				Log.debug("user.userDescription : \(user.userDescription)")
                descriptionCell.setUpData(user)
            }
            
            return descriptionCell
        default:
            
            let image = imagesDataSource[indexPath.row - 1]
            cell.imageView.image = image
            return cell
        }
    }
    
    func getDefaultCell(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell{
        
        let cell = collectionView.dequeueReusableCell(withReuseIdentifier: CellId, for: indexPath)
        return cell
    }
    
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, minimumInteritemSpacingForSectionAt section: Int) -> CGFloat {
        return 0
    }
    
    func collectionView(_ collectionView: UICollectionView, viewForSupplementaryElementOfKind kind: String, at indexPath: IndexPath) -> UICollectionReusableView {
        if let view = collectionView.dequeueReusableSupplementaryView(ofKind: UICollectionElementKindSectionFooter, withReuseIdentifier: MerchantDescriptionFooterView.FooterView, for: indexPath) as? MerchantDescriptionFooterView {
            
            view.merchantSummaryResponse = merchantSummaryResponse
            
            return view
        }
        return UICollectionReusableView()
    }
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, referenceSizeForFooterInSection section: Int) -> CGSize {
        
        if let summary = merchantSummaryResponse {
            
            guard !(summary.ratingProductDescriptionAverage == 0 &&
                    summary.ratingServiceAverage == 0 &&
                    summary.ratingLogisticsAverage  == 0) else {
                return CGSize.zero
            }
            
            return CGSize(width: collectionView.frame.sizeWidth, height: mode == DescriptionMode.modeMerchant ?  MerchantDescriptionFooterView.Height : 0)
        }
        return CGSize(width: collectionView.frame.sizeWidth, height: 0)
    }
    
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, minimumLineSpacingForSectionAt section: Int) -> CGFloat {
        return 0
    }
    func collectionView(_ collectionView: UICollectionView,
                        layout collectionViewLayout: UICollectionViewLayout,
                               insetForSectionAt section: Int) -> UIEdgeInsets {
        return DefaultUIEdgeInsets
    }
    
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, sizeForItemAt indexPath: IndexPath) -> CGSize {
        var desc = String.localize("LB_CA_CURATOR_PROF_DESC_NIL")
        switch (indexPath.row){
        case 0:
            switch mode! {
            case .modeMerchant:
                //self.name = merchant.merchantName
                desc = merchant.merchantDesc
            case .modeBrand:
                //self.name = brand.brandName
                desc = brand.brandDesc
            case .modeCurator:
                //self.name = user.displayName
                if user.userDescription.trim().length != 0 {
                    let descriptionText : String = user.userDescription
                    desc = descriptionText
                } else {
                    desc = String.localize("LB_CA_CURATOR_PROF_DESC_NIL")
                }
            }
            
            
            
            let height = StringHelper.heightForText(desc, width: self.view.frame.size.width - DescriptionViewCell.MarginLeft * 2, font: self.label.font) + DescriptionViewCell.LabelNameHeight + DescriptionViewCell.MarginBottom + DescriptionViewCell.MarginTop + 10
            
            return CGSize(width: self.view.frame.size.width, height: height )
			
        default:

            let row = indexPath.row - 1
            if self.imagesDataSource[row].size.width > 0 {
                let ratio = view.bounds.width / self.imagesDataSource[row].size.width
                return CGSize(width: view.bounds.width, height: ceil(self.imagesDataSource[row].size.height * ratio))
            }
            return CGSize(width: view.bounds.width, height: 0)
        }
        
    }
        
    //MARK: API
    @discardableResult
    func fetchImages(_ userkey: String, complete: (() -> Void)? = nil) -> Promise<Any> {
        return Promise{ fulfill, reject in
            UserService.listImagesCuratorByUserKey(userkey) { [weak self] (response) in
                if let strongSelf = self {
                    if response.result.isSuccess {
                        if response.response?.statusCode == 200 {
                            Log.debug(response.result.value)
                            if let images: Array<CuratorImage> = Mapper<CuratorImage>().mapArray(JSONObject: response.result.value) {
                                strongSelf.curatorImages = images
                                if let callback = complete {
                                    callback()
                                }
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
    
    func getImageFromUrl(_ complete: ((UIImage, String)->())? = nil) {
        
        if !self.curatorImages.isEmpty {
            for idx in 0...self.curatorImages.count - 1 {
                let curatorImage = self.curatorImages[idx]
                var imageString = ""
                imageString = curatorImage.image
                guard imageString.length > 0 else {
                    return
                }
                
                KingfisherManager.shared.retrieveImage(with: ImageURLFactory.URLSize1000(imageString, category: .user), options: nil, progressBlock: nil, completionHandler: { (image, error, cacheType, imageURL) -> () in
                    
                    if let dimage = image {
                        
                        // call back
                        if let callback = complete {
                            callback(dimage.scaleImage(self.view.width), curatorImage.userImageKey)
                        }
                        
                    } else {
                        
                    }
                })
            }
        }
    }
    
    
    func fetchRating() {
        guard mode == DescriptionMode.modeMerchant else { return }
        self.showLoading()
        firstly {
            return getRatingReview(merchant.merchantId)
            }.always {
                self.collectionView.reloadData()
                self.stopLoading()
        }
    }
    
    func getRatingReview(_ merchantId: Int) -> Promise<Any> {
        return Promise { fullfill, reject in
            ReviewService.getMerchantReview(merchantId: merchantId, completion: { [weak self](response) in
                if let strongSelf = self {
                    
                    if response.result.isSuccess {
                        if response.response?.statusCode == 200 {
                            
                            if let object = Mapper<MerchantSummaryResponse>().map(JSONObject: response.result.value) {
                                strongSelf.merchantSummaryResponse = object
                            }
                            fullfill("ok")
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
            })
        }
    }
    
    
    func downloadImages(_ complete: (()->())? = nil) {
        var count : Int = 0
        var imageDefault = "curator_cover_image_placeholder"
        var images : [String] = []
        var imageCategory: ImageCategory = ImageCategory.user
        switch mode! {
        case .modeMerchant:
            count = merchantImages.count - 1
            for merchantImage in self.merchantImages {
                images.append(merchantImage.merchantImage)
            }
            imageCategory = ImageCategory.merchant
        case .modeBrand:
            count = brandImages.count - 1
            for brandImage in self.brandImages {
                images.append(brandImage.brandImage)
            }
            imageDefault = "brand_placeholder"
            imageCategory = ImageCategory.brand
        case .modeCurator:
            count = curatorImages.count - 1
            for curatorImage in self.curatorImages {
                images.append(curatorImage.image)
            }
            imageDefault = "curator_cover_image_placeholder"
        }


        
        if count > -1 {
            for idx in 0...count {
                
                if let strongImage = UIImage(named: imageDefault) {
                    self.imagesDataSource.append(strongImage)
                }
                
                let imageString = images[idx]
                guard imageString.length > 0 else {
                    return
                }
                
                KingfisherManager.shared.retrieveImage(with: ImageURLFactory.URLSize1000(imageString, category: imageCategory), options: nil, progressBlock: nil, completionHandler: { (image, error, cacheType, imageURL) -> () in
                    if let strongImage = image {
                        // call back
                        self.imagesDataSource[idx] = strongImage
                    }
                    
                    if let callback = complete {
                        callback()
                    }
                    
                })
            }
        }
    }

   
}
