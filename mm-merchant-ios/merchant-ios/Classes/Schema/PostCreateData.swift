//
//  PostCreateData.swift
//  merchant-ios
//
//  Created by Sang Nguyen on 1/4/17.
//  Copyright © 2017 WWE & CO. All rights reserved.
//

import UIKit

class PostCreateData: NSObject {
    enum ItemType: Int {
        case album = 0,
        wishlist,
        category,
        unknown
    }
    
    
    init(cartItem: CartItem? = nil, style: Style? = nil, photo: Photo? = nil, itemType: ItemType = ItemType.unknown) {
        super.init()
        if let cartItem = cartItem {
            self.skus = [PostCreateData.createSkuFromCart(cartItem)]
            self.defaultSkuId = cartItem.skuId
            self.defaultProductImage = cartItem.productImage
        }
        if let style = style {
            if let sku = style.defaultSku() {
                sku.brandImage = style.brandHeaderLogoImage
                sku.brandName = style.brandName
                if let key = style.findImageKeyByColorKey(sku.colorKey) {
                    sku.productImage = key
                    self.defaultProductImage = key
                }
                self.skus = [sku]
                self.defaultSkuId = sku.skuId
            }
        }
        if let photo = photo {
            self.photo = photo
        }
        self.itemType = itemType
    }
    
    var itemType : ItemType = ItemType.unknown
    var photo: Photo?
    var removedTag = false
    var defaultSkuId : Int?
    var defaultProductImage : String = ""
    var skus : [Sku]?
    var tags: [ImagesTags]?
    var TagProduct: [CGSize]?
    var tag = 0
    var subFrame: CGRect = CGRect.zero
    var photoFrameSize: CGSize = CGSize(width: UIScreen.main.bounds.size.width, height: UIScreen.main.bounds.size.width)
    weak var tagViewDelegate : TagViewDelegate?
    var fullImage: UIImage?
    var uniqueId = Utils.UUID()
    var selectBeauty = ""
    var imageRect:CGRect?
    var alartShow = 0
    
    static func createSkuFromCart(_ cartItem : CartItem) -> Sku{
        let sku = Sku()
        sku.skuId = cartItem.skuId
        sku.skuCode = cartItem.skuCode
        sku.skuName = cartItem.skuName
        sku.brandImage = cartItem.brandImage
        sku.brandId = cartItem.brandId
        sku.brandName = cartItem.brandName
        sku.brandNameInvariant = cartItem.brandNameInvariant
        sku.priceRetail = cartItem.priceRetail
        sku.priceSale = cartItem.priceSale
        sku.isSale = cartItem.isSale
        sku.availableFrom = cartItem.availableFrom
        sku.availableTo = cartItem.availableTo
        sku.productImage = cartItem.productImage
        sku.colorKey = cartItem.colorKey
        sku.colorName = cartItem.colorName
        sku.colorId = cartItem.colorId
        sku.styleCode = cartItem.styleCode
        sku.merchantId = cartItem.merchantId
        sku.badgeId = cartItem.badgeId
        sku.seasonId = cartItem.seasonId
        sku.sizeId = cartItem.sizeId
        sku.colorId = cartItem.colorId
        sku.geoCountryId = cartItem.geoCountryId
        sku.launchYear = cartItem.launchYear
        sku.saleFrom = cartItem.saleFrom
        sku.saleTo = cartItem.saleTo
        sku.qtySafetyThreshold = cartItem.qtySafetyThreshold
        sku.primaryCategoryId = cartItem.primaryCategoryId
        sku.sizeName = cartItem.sizeName
        sku.locationCount = cartItem.locationCount
        sku.inventoryStatusId = cartItem.inventoryStatusId
        sku.productImage = cartItem.productImage
        sku.lastCreated = cartItem.lastCreated
        return sku
    }
    
    func getSkuList()->[Sku] {
        if let skus = self.skus {
            for sku in skus {
                //Centralize tag only when positions is not defined
                if (sku.positionX == 0 && sku.positionY == 0) {
                    let point = self.getTagProductPoint()
                    sku.positionX = Int(point.x)
                    sku.positionY = Int(point.y)
                }
            }
            return skus
        }
        self.skus = [Sku]()
        return self.skus!
    }
    
    func addSku(_ sku: Sku) {
        if self.skus == nil {
            self.skus = [Sku] ()
        }
        self.skus!.append(sku)
    }
    
    func addTag(tag: ImagesTags) {
        if self.tags == nil {
            self.tags = [ImagesTags] ()
        }
        self.tags!.append(tag)
    }
    
    func createTagProduct(_ mode: ModeTagProduct, sku : Sku) ->ProductTagView? {
        if let tagViewDelegate = self.tagViewDelegate{
            var parentTag = 1
            if mode == .wishlist {
                parentTag = self.tag
            }
            let tag = ProductTagView(position: self.getTagProductPoint(), price:  sku.price(), parentTag: parentTag, delegate: tagViewDelegate, oldPrice: sku.priceSale, newPrice: sku.priceRetail, logoImage: UIImage(named: "logo6")!, logo: sku.brandImage, tagImageSize: self.photoFrameSize, skuId: sku.skuId, place: TagPlace.undefined,tagStyle:.Commodity)
            tag.productMode = mode
            tag.sku = sku
            tag.skuName = sku.skuName
            tag.mode = .edit
            tag.photoFrameIndex = self.tag
            tag.tag = self.tag
            return tag
        }
        return nil
    }
    
    func getTagProductPoint()->CGPoint{
        return CGPoint(x: self.subFrame.minX + self.subFrame.width / 2, y: self.subFrame.minY + self.subFrame.height / 2)
    }
    
    func refreshData(_ subFrame: CGRect, index: Int){
        self.subFrame = subFrame
        self.tag = index
        let skus = self.getSkuList()
        for sku in skus {
            let tapPoint = self.getTagProductPoint()
            sku.positionX = Int(tapPoint.x)
            sku.positionY = Int(tapPoint.y)
//            tag.finalLocation = tag.tapPoint
//            tag.tag = index
//            tag.photoFrameIndex = index
//            tag.layoutSubviews()
        }
    }
    
    func getImage() -> UIImage? {
        return processedImage
    }
    
    // Filter
    var resource: Camera360Wrapper.Resource?
    var isCurrentFilterTarget = false
    
    var originalImage: UIImage? {
        switch itemType {
        case ItemType.album:
            return self.photo?.fullImage
        default:
            break
        }
        return self.fullImage
    }
    private var _cropImage: UIImage?
    var cropImage: UIImage? {
        
        get {
            if _cropImage != nil {
                return _cropImage
            }
            return originalImage
        }
        set {
            _cropImage = newValue
        }
    }
    
    private var _filteredImage: UIImage?
    var filteredImage: UIImage? {
        get {
            if _filteredImage != nil {
                return _filteredImage
            }
            
            return originalImage
        }
        set {
            _filteredImage = newValue
        }
    }
    
    var _beautifiedImage: UIImage?
    var beautifiedImage: UIImage? {
        get {
            if _beautifiedImage != nil {
                return _beautifiedImage
            }
            
            return filteredImage
        }
        set {
            _beautifiedImage = newValue
        }
    }
    
    var processedImage: UIImage? {
        get {
            return beautifiedImage
        }
    }
    
    func removeAllEffects() {
        _beautifiedImage = nil
        _filteredImage = nil
    
    }
    
    var beautySettings: TutuWrapper.BeautySetting?
    var filter: MMFilter?
    
    func beautySettingsOrDefault() -> TutuWrapper.BeautySetting {
        setDefaultBeautySettingsIfNeeded()
        return beautySettings!
    }
    
    func recommendSettings() -> TutuWrapper.BeautySetting {
        beautySettings = (smoothing: 0.3, whitening: 0.5, skinColor: 0.5, eyeSize: 0.6, chinSize: 0.5,false)
        return beautySettings!
    }
    
    func setDefaultBeautySettingsIfNeeded() {
        if beautySettings == nil {
            beautySettings = TutuWrapper.defaultSettings()
        }
    }
    
    func setSmoothing(_ value: CGFloat) {
        setDefaultBeautySettingsIfNeeded()
        beautySettings?.smoothing = value
    }
    
    func setWhitening(_ value: CGFloat) {
        setDefaultBeautySettingsIfNeeded()
        beautySettings?.whitening = value
    }
    
    func setSkinColor(_ value: CGFloat) {
        setDefaultBeautySettingsIfNeeded()
        beautySettings?.skinColor = value
    }
    
    func setEyeSize(_ value: CGFloat) {
        setDefaultBeautySettingsIfNeeded()
        beautySettings?.eyeSize = value
    }
    
    func setChinSize(_ value: CGFloat) {
        setDefaultBeautySettingsIfNeeded()
        beautySettings?.chinSize = value
    }
    func setTagProductOptione(value: CGSize) {
        TagProduct?.append(value)
    }

}
