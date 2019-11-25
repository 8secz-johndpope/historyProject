//
//  BrandDetailViewController.swift
//  merchant-ios
//
//  Created by Markus Chow on 18/4/2016.
//  Copyright © 2016 WWE & CO. All rights reserved.
//

import Foundation
import PromiseKit
import ObjectMapper
import CSStickyHeaderFlowLayout
import Alamofire

import Kingfisher

class BrandDetailViewController: MerchantDetailViewController {

	var brand : Brand?


	func fetchBrand(_ brand: Brand) -> Promise<Any>{
        return Promise{ fulfill, reject in
            if brand.brandId > 0 {
                BrandService.view(brand.brandId){ [weak self](response) in
                    
                    if response.result.isSuccess {
                        if response.response?.statusCode == 200 {
							
                            if let array = response.result.value as? [[String: Any]], let obj = array.first , let brand = Mapper<Brand>().map(JSONObject: obj) {
                                if let strongSelf = self {
                                    strongSelf.brand = brand
                                }
								fulfill("OK")
								
							} else {
								let error = NSError(domain: "", code: -999, userInfo: nil)
								reject(error)
							}							
							
                        } else {
                            var statusCode = 0
                            if let code = response.response?.statusCode {
                                statusCode = code
                            }
                            let error = NSError(domain: "", code: statusCode, userInfo: nil)
                            reject(error)
                        }
                    }
                    else {
                        reject(response.result.error!)
                    }
                    
                }
            } else {
                BrandService.viewBrandBySubdomain(brand.brandSubdomain){ [weak self] (response) in
                    
                    if response.result.isSuccess {
                        if response.response?.statusCode == 200 {
                            
                            if let strongSelf = self {
                                strongSelf.brand = Mapper<Brand>().map(JSONObject: response.result.value)!
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
                    }
                    else {
                        reject(response.result.error!)
                    }
                    
                }
                
            }
            
        }
	}

    
	override func backupButtonColorOn() {
		buttonCart?.setImage(UIImage(named: "cart_grey"), for: UIControlState())
		buttonWishlist?.setImage(UIImage(named: "icon_heart_stroke"), for: UIControlState())
		buttonSearch?.setImage(UIImage(named: "search_grey"), for: UIControlState())
		buttonBack.setImage(UIImage(named: "back_grey"), for: UIControlState())
		if brand != nil {
			addLogoOnNavi()
		} else {
			self.title = ""
		}
		
	}
	
	override func updateMerchantViewWithRefreshedData(){
		
        if let brand = self.brand {
		
            self.showLoading()
            firstly {
				
				// update inventory location if needed
				// if it is not updated, it will return success without api call
				return self.fetchBrand(brand)
				
                }.then { _ -> Void in
                    self.reloadDataSource()
                }.always {
                    self.stopLoading()
                }.catch { _ -> Void in
                    Log.error("error")
            }
        }
	}
	
	override func updateMerchantViewForGuestUser() {
		self.updateMerchantViewWithRefreshedData()
	}

	override func addLogoOnNavi() {
		
		removeLogo()
		
		imageViewLogo = UIImageView(frame: CGRect(x: (self.view.frame.width - WidthLogo)/2, y: 0, width: WidthLogo, height: HeightLogo))
		setDataImageviewLogo(brand!.headerLogoImage)
		imageViewLogo?.tag = 99
		self.navigationItem.titleView = imageViewLogo!
	}
	
	override func setDataImageviewLogo(_ key : String){
		imageViewLogo?.contentMode = .scaleAspectFit
		
		imageViewLogo?.mm_setImageWithURL(ImageURLFactory.URLSize512(brand!.headerLogoImage, category: .brand), placeholderImage: nil)
	}

	override func collectionView(_ collectionView: UICollectionView, viewForSupplementaryElementOfKind kind: String, at indexPath: IndexPath) -> UICollectionReusableView {
		
		if kind == CSStickyHeaderParallaxHeader {
			let view = collectionView.dequeueReusableSupplementaryView(ofKind: kind, withReuseIdentifier: HeaderProfileIdentifier, for: indexPath)
			header = (view as! HeaderMerchantProfileView)
            if brand != nil {
                header?.configDataWithBrand(brand!)
                header?.delegateMerchantProfile = self
            }
			return header!
		}
		return UICollectionReusableView()
		
	}

	override func didSelectDescriptionView(_ gesture: UITapGestureRecognizer) {
		let merchantDescriptionVC = MerchantDescriptionViewController()
		merchantDescriptionVC.brand = self.brand!
		merchantDescriptionVC.mode = DescriptionMode.modeBrand
		self.navigationController?.push(merchantDescriptionVC, animated: true)
	}

    override func didSelectButtonShare(_ sender: UIButton) {
        let shareViewController = ShareViewController ()
        
        shareViewController.viewKey = self.analyticsViewRecord.viewKey
        
        shareViewController.didUserSelectedHandler = { [weak self] (data) in
            if let strongSelf = self {
                let myRole: UserRole = UserRole(userKey: Context.getUserKey())
                let targetRole: UserRole = UserRole(userKey: data.userKey)
                
                WebSocketManager.sharedInstance().sendMessage(
                    IMConvStartMessage(userList: [myRole, targetRole], senderMerchantId: myRole.merchantId),
                    checkNetwork: true,
                    viewController: strongSelf,
                    completion: { (ack) in
                        if let convKey = ack.data {
                            let viewController = UserChatViewController(convKey: convKey)
                            let merchantModel = MerchantModel()
                            merchantModel.merchant = strongSelf.merchant
                            let chatModel = ChatModel.init(merchantModel: merchantModel)
                            chatModel.messageContentType = MessageContentType.ShareMerchant
                            
                            viewController.forwardChatModel = chatModel
                            strongSelf.navigationController?.pushViewController(viewController, animated: true)
                        }
                    }
                )
            }
        }
        
        shareViewController.didSelectSNSHandler = { method in
            if let brand = self.brand {
                ShareManager.sharedManager.shareBrand(brand, method: method)
            }
            
        }
        self.present(shareViewController, animated: false, completion: nil)
    }

}
