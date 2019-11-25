 
//
//  TagEditorViewController.swift
//  merchant-ios
//
//  Created by Vu Dinh Trung on 4/20/16.
//  Copyright © 2016 WWE & CO. All rights reserved.
//

import UIKit

class TagEditorViewController: MmViewController,TagViewDelegate, TagProductViewControllerDelegate, UINavigationControllerDelegate {

    private final let margin:CGFloat = 10.0
    private final let HeightBoardBottom: CGFloat = 150
    private final let ProductViewMarginLeft: CGFloat = 50
    
    var imageProduct = UIImage()
    
    var imageViewProduct = UIImageView()
    var editorView = UIView()
    var contentView = UIView()
    var tag = ProductTagView()
	
	var tagPoint : CGPoint!

	var lastPositionTap = CGPoint.zero
    var productTagViews = [ProductTagView]()
	
	var croppedImage = UIImage()
	var croppedImageSize : CGSize!
	
    var isFrom = ModeTagProduct.productListPage
    
	var editMessageLabel = UILabel()
		
	var selectedFrames : [CGRect]!
    private var productView : ProductView?
    //MARK: Init
	convenience init(imageCrop: UIImage, tagPercentage: (x: Int, y: Int), imageSize: CGSize, tagArrays: [ProductTagView]){
        self.init(nibName: nil, bundle: nil)
        
        self.imageProduct = imageCrop
		croppedImage = imageCrop
		croppedImageSize = imageSize
		
		self.productTagViews = tagArrays
				
        self.analyticsViewRecord.viewKey = Utils.UUID()
        if tagArrays.count > 0 {
            self.createImpression(tagArrays[0])
        }
		
    }
	
    func renderTagProduct() {
        for i in 0 ..< self.productTagViews.count {
            if let tag = productTagViews[i] as ProductTagView? {
				
				if tag.shouleBeHidden {
					continue
				}
				
                let addTag = ProductTagView(position: tag.finalLocation, price: tag.price, parentTag: tag.tagBodyButton.tag, delegate: self, oldPrice: tag.oldPriceFloat, newPrice: tag.newPriceFloat, logoImage: UIImage(named: "logo6")!, logo: tag.logoString, tagImageSize: self.imageViewProduct.frame.size, skuId: tag.skuId, place: tag.place,tagStyle: .Commodity)
                addTag.productMode = tag.productMode
                addTag.sku = tag.sku
                addTag.direction = tag.direction
                addTag.tagBodyButton.tag = tag.tagBodyButton.tag
                addTag.tag = tag.tagBodyButton.tag
                addTag.baseView.tag = tag.tagBodyButton.tag
				
				addTag.photoFrameIndex = tag.photoFrameIndex
                
				// default in edit for editing tags
                addTag.mode = .edit
				Log.debug("addTag photoFrameIndex : \(addTag.photoFrameIndex)")
				//Log.debug("addTag labelText : \(addTag.priceText)")
                Log.debug("addTag finalLocation : \(addTag.finalLocation)")
                let tapGeture = UITapGestureRecognizer(target: self, action: #selector(self.didSelectTag))
                addTag.addGestureRecognizer(tapGeture)

                imageViewProduct.addSubview(addTag)
                
            }
        }
    }
	deinit {
		NotificationCenter.default.removeObserver(self, name: Constants.Notification.tagDataFromSearchProduct, object: nil)
        NotificationCenter.default.removeObserver(self, name: Constants.Notification.updateTagArraysForPost, object: self.productTagViews)
	}
	
    override func viewDidLoad() {
        super.viewDidLoad()
		
		self.setupImageView()
		setupContentSizeWithImage(self.imageProduct)
		self.setupEditorView()
		self.setupTagMessageLabel()

        self.title = String.localize("LB_CA_EDIT_TAG")
        self.createBackButton()
        self.createRightButton(String.localize("LB_NEXT"), action: #selector(TagEditorViewController.handleRightButton))
        
        NotificationCenter.default.addObserver(self, selector: #selector(TagEditorViewController.updateTagArrays), name: Constants.Notification.updateTagArraysForPost, object: nil)
        
        self.initAnalyticLog()
    }
	
	override func viewWillAppear(_ animated: Bool) {
		super.viewWillAppear(animated)
		
		cleanUpPreviousTags()
		
		// populate tags on imageViewProduct
		renderTagProduct()
        self.navigationController?.delegate = self
	}
	
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        
        self.navigationController?.delegate = nil

    }
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }

	override func backButtonClicked(_ button: UIButton) {
		NotificationCenter.default.post(name: Constants.Notification.updateTagArraysForFrame, object: self.productTagViews)
		
		super.backButtonClicked(button)
	}
	
    @objc func updateTagArrays(_ notification: Notification) {
//        Log.debug("notification : \(notification)")
//        Log.debug("notification.object : \(notification.object)")
		
		cleanUpPreviousTags()
		
        self.productTagViews = notification.object as! [ProductTagView]
        
        renderTagProduct()
    }
	
	func cleanUpPreviousTags() {
		// remove previous tags
		for tag in self.productTagViews {
			tag.removeFromSuperview()
		}
		
		for view in self.imageViewProduct.subviews {
			view.removeFromSuperview()
		}
		
	}
	
    func setupImageView() -> Void {
        contentView.backgroundColor = UIColor.white
        self.view.addSubview(contentView)
        self.imageViewProduct.contentMode = .scaleAspectFill
        self.imageViewProduct.backgroundColor = UIColor.clear
        self.imageViewProduct.image = self.imageProduct
        self.imageViewProduct.isUserInteractionEnabled = true
        self.imageViewProduct.addGestureRecognizer(UITapGestureRecognizer(target: self, action: #selector(TagEditorViewController.didSelectedImageViewTag)))
        self.contentView.addSubview(self.imageViewProduct)
    }
	
	func setupEditorView() -> Void {
        editorView.backgroundColor = UIColor.white
        self.view.addSubview(editorView)
    }
	
	func setupTagMessageLabel() {
		
		let msgString = String.localize("LB_CA_PRODUCT_TAG_EDITOR_DESC")
    
		
		editMessageLabel.frame = CGRect(x: 0, y: 0, width: editorView.frame.width, height: editorView.frame.size.height)
		editMessageLabel.textAlignment = .center
		editMessageLabel.font = UIFont.systemFont(ofSize: 13)
		editMessageLabel.textColor = UIColor.secondary4()
        editMessageLabel.text = msgString
        editMessageLabel.numberOfLines = 0
		
		editorView.addSubview(editMessageLabel)

	}
	
    func setupContentSizeWithImage(_ image: UIImage) -> Void {

        let ratio = self.view.frame.width / image.size.width;
        self.imageViewProduct.frame = CGRect(x: 0, y: 0, width: image.size.width * ratio, height: image.size.width * ratio)
        self.editorView.frame = CGRect(x: 0, y: self.view.frame.height - HeightBoardBottom, width: self.view.frame.width, height: HeightBoardBottom)
		
    }
    
    override func viewWillLayoutSubviews() {
        super.viewWillLayoutSubviews()
        self.contentView.frame = CGRect(x: 0, y: StartYPos, width: self.view.frame.width, height: self.view.frame.height - 64 - HeightBoardBottom)
    }
	
	//MARK: handle Action    
    @objc func handleRightButton(_ sender: UIBarButtonItem) -> Void {
        Log.debug("Done editing Tags")
				
        let createOutfit = CreateOutfitViewController()
        createOutfit.currentStage = StageMode.secondStage
        createOutfit.imageCrop = imageProduct
        createOutfit.productTagViews = self.productTagViews
        createOutfit.isFrom = isFrom
		self.navigationController?.push(createOutfit, animated: true)
        
        sender.recordAction(
            .Tap,
            sourceRef: "Next",
            sourceType: .Button,
            targetRef: "Editor-Post",
            targetType: .View)

		
    }
	
	// TagProduct Delegate
    func didSelectedCloseButton(_ tagView: ProductTagView) {
        
        
        let optionMenu = UIAlertController(title: nil, message: nil, preferredStyle: .actionSheet)
        
        let deleteAction = UIAlertAction(title: String.localize("LB_PRODUCT_TAG_DELETION"), style: .default, handler: {
            (alert: UIAlertAction!) -> Void in
        
            tagView.removeFromSuperview()
           // self.tagArrays.removeObject(tagView)
            if let index = self.productTagViews.index(where: { $0.tag == tagView.tag }) {
                self.productTagViews.remove(at: index)
            }
            
        })
        
     
        let cancelAction = UIAlertAction(title:String.localize("LB_CANCEL"), style: .cancel, handler: {
            (alert: UIAlertAction!) -> Void in
       
        })
        
        optionMenu.addAction(deleteAction)
        optionMenu.addAction(cancelAction)

		self.present(optionMenu, animated: true, completion: nil)
        optionMenu.view.tintColor = UIColor.alertTintColor()
        
	}
	
    //MARK: - TagProduct Delegate
	func updateTag(_ tag: ProductTagView) {
		for i in 0 ..< self.productTagViews.count {
			if tag.skuId == self.productTagViews[i].skuId {
				self.productTagViews[i] = tag
			}
		}
	}

    func endMoveTag() {
        self.getProductView().hideProductWithAnimation(true)
    }
    
    func touchDown(_ tag: ProductTagView) {
        self.getProductView().setData(tag.sku)
        self.getProductView().showProductWithAnimation(true)
        Log.debug("toucheDown")
    }
    
    func touchUp(_ tag: ProductTagView) {
        Log.debug("toucheUp")
        self.getProductView().hideProductWithAnimation(true)
    }
    
    @objc func didSelectedImageViewTag(_ gesture: UITapGestureRecognizer) -> Void {
        if self.productTagViews.count < Constants.TagProduct.Limit {
			if self.productTagViews.count > 0
            {
				NotificationCenter.default.post(name: Constants.Notification.exitTagProductEditMode, object: nil)
			}
			
			self.lastPositionTap = gesture.location(in: self.imageViewProduct)
			
			let img = UIImageView(frame: CGRect(x: 0, y: 0, width: 40, height: 40))
			img.image = UIImage(named: "dotdot.png")
			self.imageViewProduct.addSubview(img)
			img.center = self.lastPositionTap
			
			img.alpha = 1.0
			img.transform = CGAffineTransform(scaleX: 0.1, y: 0.1)
			UIView.animate(withDuration: 0.3, animations: {
				img.transform = CGAffineTransform(scaleX: 1.0, y: 1.0)
				img.alpha = 0.0
				}, completion: { (success) in
					img.removeFromSuperview()
                    self.present(MmNavigationController(rootViewController: TagProductSelectionViewController(object: self)), animated: true, completion: nil)
			})
            
            var imageKey : String?
            if self.productTagViews.count > 0 {
                let tag = self.productTagViews[0]
                
                switch tag.productMode {
                case .shoppingCart:
                    imageKey = tag.sku.productImage
                    break
                case .wishlist, .search:
                    imageKey = tag.sku.imageDefault
                    break
                default:
                    break
                }
            }
            self.view.recordAction(
                .Tap,
                sourceRef: imageKey,
                sourceType: .Image,
                targetRef: "Editor-ProductTag-Collection",
                targetType: .View)
           
        }
        
    }
	
	func checkTagExistence(_ skuId: Int, tags: [ProductTagView], point: CGPoint) -> Bool {
		var exist = false
		
		for i in 0 ..< tags.count {
			 let tag : ProductTagView = tags[i] 
				if tag.skuId == skuId {
					
					tag.finalLocation = point
					tag.configDirection()
					exist = true
					
					break
				}
		}
		
		// update tagArrays
		self.productTagViews = tags
		
		return exist
	}
	
    @objc func didSelectTag(_ tapGesture: UITapGestureRecognizer){
        Log.debug("Tag tapped")
    }
    
    //MARK: Delgate
	func didSelectedItemForTag(_ postCreateData: PostCreateData, mode: ModeTagProduct) {
        var priceSale: Double = 0.0
        var priceRetail: Double = 0.0
        var brandImageKey  = ""
		var skuId = 0
        let tagPoint = self.lastPositionTap
		Log.debug("selectedFrames : \(selectedFrames)")
        var tagProduct : ProductTagView?
		switch mode {
        case .wishlist, .search, .shoppingCart:
            var price: Double = 0

            if let sku = postCreateData.skus?.first {
                
                skuId = sku.skuId
                priceSale =  sku.priceSale
                priceRetail = sku.priceRetail
                brandImageKey = sku.brandImage
                price = sku.price()
                tagProduct?.skuName = sku.skuName
            }
            
            // check tag existence
            if !self.checkTagExistence(skuId, tags: self.productTagViews, point: tagPoint) {
                
                // add new tag
                var tagId : Int = 0
                if self.productTagViews.count > 0 {
                    tagId = self.productTagViews[self.productTagViews.count - 1].tag + 1
                }
                var tag = ProductTagView(position: tagPoint, price: price, parentTag: tagId, delegate: self, oldPrice: priceSale, newPrice: priceRetail, logoImage: UIImage(named: "logo6")!, logo: brandImageKey, tagImageSize: self.imageViewProduct.frame.size, skuId: skuId, place: .undefined,tagStyle:ProductTagStyle.Commodity)
                
                tag.productMode = mode
                tag.sku = postCreateData.skus?.first ?? Sku()
                let tapGeture = UITapGestureRecognizer(target: self, action: #selector(self.didSelectTag))
                tag.addGestureRecognizer(tapGeture)
                tag = NewPhotoCollageViewController.updateTagsPhotoFrameIndex(tag, frames: selectedFrames)
                
                self.imageViewProduct.addSubview(tag)
                self.productTagViews.append(tag)
                tagProduct = tag
                
                
            }

            break
						
        default:
            break
        }
        tagProduct?.productMode = mode
		self.createImpression(tagProduct)
    }
	
    
	func tagDataReturnedFromSearch(_ noti: Notification) -> Void {
	}
    
    
    func navigationController(_ navigationController: UINavigationController, animationControllerFor operation: UINavigationControllerOperation, from fromVC: UIViewController, to toVC: UIViewController) -> UIViewControllerAnimatedTransitioning? {
        if operation == .pop {
            return PopFadingAnimator()
        }
        return nil
    }
    
    func getProductView() -> ProductView {
        if self.productView == nil{
            self.productView = ProductView(frame: CGRect(x: ProductViewMarginLeft, y: 30, width: self.view.width - ProductViewMarginLeft * 2 , height: 48))
        }
        return self.productView!
    }
    
    func initAnalyticLog(){
        let user = Context.getUserProfile()
        let authorType = user.userTypeString()
        initAnalyticsViewRecord(
            user.userKey,
            authorType: authorType,
            viewLocation: "Editor-ProductTag",
            viewType: "Post"
        )
    }
    
    func createImpression(_ tagProduct: ProductTagView?) {
    }
}
