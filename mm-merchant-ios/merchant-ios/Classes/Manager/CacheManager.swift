//
//  DataManager.swift
//  merchant-ios
//
//  Created by HungPM on 1/29/16.
//  Copyright © 2016 WWE & CO. All rights reserved.
//

import Foundation
import PromiseKit
import ObjectMapper
import RealmSwift
// FIXME: comparison operators with optionals were removed from the Swift Standard Libary.
// Consider refactoring the code to use the non-optional operators.
private func < <T : Comparable>(lhs: T?, rhs: T?) -> Bool {
    switch (lhs, rhs) {
    case let (l?, r?):
        return l < r
    case (nil, _?):
        return true
    default:
        return false
    }
}

// FIXME: comparison operators with optionals were removed from the Swift Standard Libary.
// Consider refactoring the code to use the non-optional operators.
private func > <T : Comparable>(lhs: T?, rhs: T?) -> Bool {
    switch (lhs, rhs) {
    case let (l?, r?):
        return l > r
    default:
        return rhs < lhs
    }
}

class CacheManager {
    class var sharedManager: CacheManager {
        get {
            struct Singleton {
                static let instance = CacheManager()
            }
            return Singleton.instance
        }
    }
    
    //private init
    private init() {}
    
    var wishlist : Wishlist?{
        didSet{
            if let newCartItems = wishlist?.cartItems {
                if let oldCartItems = oldValue?.cartItems {
                    if oldCartItems.count < newCartItems.count{
                        Context.setVisitedWishlist(false)
                    }
                }
                
                WishListSkuModel.clearWishlist()
                var list = [WishListSkuModel]()
                for cartItem in newCartItems where !cartItem.isOutOfStock() {
                    let model = WishListSkuModel(skuId: cartItem.skuId, styleCode: cartItem.styleCode, brandId: cartItem.brandId, brandCode: cartItem.brandCode, merchantId: cartItem.merchantId, lastModified: cartItem.lastModified)
                    list.append(model)
                }
                WishListSkuModel.insertToTable(objects: list)
                //blp update db model wishlist
            }
        }
    }
    
    var hotSearchTerms: [SearchTerm]? // 热门搜索记录
    var likedMagazineCovers : [MagazineCover]?
    var cart : Cart?{
        didSet{
            if let newCartItems = cart?.itemList {
                if let oldCartItems = oldValue?.itemList {
                    if oldCartItems.count < newCartItems.count {
                        Context.setVisitedCart(false)
                    }
                }
                
                CartSkuModel.truncate()
                var list = [CartSkuModel]()
                for cartItem in newCartItems where !cartItem.isOutOfStock() {
                    let model = CartSkuModel(skuId: cartItem.skuId, styleCode: cartItem.styleCode, brandId: cartItem.brandId, brandCode: cartItem.brandCode, merchantId: cartItem.merchantId, lastModified: cartItem.lastModified)
                    list.append(model)
                }
                CartSkuModel.insertToTable(objects: list)
            }
        }
    }
    var friends: NSMutableDictionary?
    var friendList = [User]()
    var selectedAddress: Address?
    var userAliasList = [UserAlias]()
    var photoFrames = [PhotoFrame]()
    var postDescription: String? = nil
    fileprivate(set) var userAliasMap = [String: UserAlias]()
    
    fileprivate(set) var numberOfFriendRequests: Int = 0
    func updateNumberOfFriendRequests(_ value: Int, notify: Bool = false) {
        numberOfFriendRequests = value
        if notify {
            PostNotification(FriendRequestDidUpdateNotification)
        }
    }
    
    func clearNumberOfFriendRequests() {
        numberOfFriendRequests = 0
    }
    
    var promptedSolution = false
    
    //MARK: Shopping Cart
    func refreshCart() {
        if LoginManager.getLoginState() != .validUser && (Context.anonymousShoppingCartKey() == nil || Context.anonymousShoppingCartKey() == "0") {
            return
        }
        
        RunOnFetchingThread {
            self.listCartItem()
        }
    }
    
    func hasCartItem() -> Bool {
        if self.cart?.merchantList?.count > 0 {
            return !Context.getVisitedCart()
        }
        return false
    }
    
    func numberOfCartItems() -> Int {
        return self.cart?.itemList?.count ?? 0
    }
    
    func listCartItem(_ success: (() -> Void)? = nil, fail: (() -> Void)? = nil) {
        let promiseCart = Promise<Any> { fulfill, reject in
            CartService.list(completion: {
                [weak self] (response) in
                if let strongSelf = self {
                    if response.result.isSuccess {
                        if response.response?.statusCode == 200 {
                            let cart = Mapper<Cart>().map(JSONObject: response.result.value)
                            strongSelf.cart = strongSelf.sortCartItems(cart)
                            fulfill("OK")
                            DispatchQueue.main.async(execute: {
                                NotificationCenter.default.post(name: Notification.Name(rawValue: "refreshShoppingCartFinished"), object: nil)
                            })
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
        
        firstly {
            return promiseCart
            }.then { _ -> Void in
                self.getMerchantInfo(success)
            }.catch { _ -> Void in
                if let failBlock = fail {
                    failBlock()
                }
        }
    }
    
    func getMerchantInfo(_ success: (() -> Void)? = nil) {
        var listMerchantId = [Int]()
        if let merchantList = self.cart?.merchantList {
            for merchant in merchantList {
                listMerchantId.append(merchant.merchantId)
            }
        }
        
        MerchantService.viewListWithMerchantIDs(
            listMerchantId,
            completion: { (merchants, _) in
                for merchant in merchants {
                    if let merchantList = self.cart?.merchantList {
                        for aMerchant in merchantList {
                            if merchant.merchantId == aMerchant.merchantId {
                                aMerchant.merchantName = merchant.merchantName
                                aMerchant.merchantImage = merchant.headerLogoImage
                                aMerchant.isCrossBorder = merchant.isCrossBorder
                                aMerchant.freeShippingThreshold = merchant.freeShippingThreshold
                                break
                            }
                        }
                    }
                }
                
                if let callback = success {
                    callback()
                } else {
                    NotificationCenter.default.post(name: NSNotification.Name(rawValue: "refreshShoppingCartFinished"), object: nil)
                }
        }
        )
    }
    
    func sortCartItems(_ unsortedCart: Cart?) -> Cart? {
        // "CartItem" of "CartMerchant" should be null or empty, what is the coding doing as following:
        // 1.   Get the all merchant ID from orginial cart item, and make a list
        // 2.   Create [New CartMerchant list] base on the list and added related "CartItem"
        // 3.   Sorted the [New CartMerchant list]
        
        if let cart = unsortedCart, let orgCartItemList = cart.itemList {
            var sortedMerchantList: [CartMerchant]? = [CartMerchant]()
            
            let sortedCart = Cart()
            sortedCart.cartKey = cart.cartKey
            sortedCart.userKey = cart.userKey
            
            if orgCartItemList.count > 0 {
                // To check if the Merchant is duplicated
                var noDupliMerchantList = [Int]()
                for cartItem in orgCartItemList {
                    if !noDupliMerchantList.contains(cartItem.merchantId) {
                        noDupliMerchantList.append(cartItem.merchantId)
                    }
                }
                
                // "noDupliMerchantList" will get cart item from orginal cart
                if noDupliMerchantList.count > 0 {
                    for merchantId in noDupliMerchantList {
                        let newMerchant = CartMerchant()
                        newMerchant.merchantId = merchantId
                        
                        var tempCartItem = [CartItem]()
                        if (orgCartItemList.count > 0) {
                            tempCartItem = orgCartItemList.filter { $0.merchantId == merchantId}
                        }
                        newMerchant.itemList = tempCartItem
                        sortedMerchantList?.append(newMerchant)
                    }
                }

                if let _ = sortedMerchantList {
                    var _tempMerchantList = sortedMerchantList
                    if !_tempMerchantList!.isEmpty {
                        for tempMerchant in _tempMerchantList! {
                            if let _ = tempMerchant.itemList{
                                var tempCartItemList = tempMerchant.itemList!
                                tempCartItemList.sort { (DateTransformExtension().transformFromJSON($0.lastModified) ?? Date()).compare((DateTransformExtension().transformFromJSON($1.lastModified) ?? Date())) == .orderedDescending }
                                tempMerchant.itemList = tempCartItemList
                                tempMerchant.lastModified = tempCartItemList.first!.lastModified
                            }
                            
                        }
                        _tempMerchantList!.sort { (DateTransformExtension().transformFromJSON($0.lastModified) ?? Date()).compare((DateTransformExtension().transformFromJSON($1.lastModified) ?? Date())) == .orderedDescending }
                        sortedMerchantList = _tempMerchantList
                    }
                }
            }
            sortedCart.merchantList = sortedMerchantList
            sortedCart.itemList = orgCartItemList
            return sortedCart
        }
        return nil
    }
    
    // MARK: Wish List
    func refreshWishList() {
        if LoginManager.getLoginState() != .validUser && (Context.anonymousWishListKey() == nil || Context.anonymousWishListKey() == "0") {
            return
        }
        
        firstly {
            return self.listWishlistItem()
            }.always {
                NotificationCenter.default.post(name: NSNotification.Name(rawValue: "refreshWishListFinished"), object: nil)
            }.catch { _ -> Void in
                Log.error("error")
        }
        self.refreshLikedMagazineCover()
    }
    
    func hasWishListItem() -> Bool {
        if self.wishlist?.cartItems?.count > 0 {
            return !Context.getVisitedWishlist()
        }
        return false
    }
    
    func listWishlistItem(_ userKey: String? = nil, saveToCache: Bool = true, completion complete:((_ wishlist: Wishlist?) -> Void)? = nil) -> Promise<Any> {
        return Promise{ fulfill, reject in
            WishlistService.list(userKey, completion: { [weak self] (response) in
                if let strongSelf = self {
                    strongSelf.RunOnFetchingThread({
                        if response.result.isSuccess{
                            if response.response?.statusCode == 200 {
                                if let wishlist = Mapper<Wishlist>().map(JSONObject: response.result.value) {
                                    wishlist.cartItems?.sort(by: { (DateTransformExtension().transformFromJSON($0.lastModified) ?? Date()).compare((DateTransformExtension().transformFromJSON($1.lastModified) ?? Date())) == .orderedDescending })
                                    if saveToCache {
                                        strongSelf.wishlist = wishlist
                                    }
                                    DispatchQueue.main.async {
                                        complete?(wishlist)
                                    }
                                }
                                DispatchQueue.main.async {
                                    fulfill("OK")
                                }
                            } else {
                                var statusCode = 0
                                if let code = response.response?.statusCode {
                                    statusCode = code
                                }
                                
                                let error = NSError(domain: "", code: statusCode, userInfo: nil)
                                DispatchQueue.main.async {
                                    reject(error)
                                }
                            }
                        } else{
                            DispatchQueue.main.async {
                                reject(response.result.error!)
                            }
                        }
                    })
                }
            })
        }
    }
    
    // MARK: Mapping a style with wishlist item
    func cartItemIdForStyle(_ style : Style) -> Int {
        if let cartItems = CacheManager.sharedManager.wishlist?.cartItems {
            for cartItem in cartItems {
                if cartItem.styleCode == style.styleCode {
                    return cartItem.cartItemId
                }
            }
        }
        return NSNotFound
    }
    
    func cartItemIdForSku(_ sku : Sku) -> Int {
        if let cartItems = CacheManager.sharedManager.wishlist?.cartItems {
            for cartItem in cartItems {
                if cartItem.skuId == sku.skuId {
                    return cartItem.cartItemId
                }
            }
        }
        return NSNotFound
    }
    
    func cacheObject<T: Object>(_ objT: T?) {
        guard let obj = objT else {
            return
        }
        do {
            let realm = try Realm()
            try realm.write {
                realm.add(obj)
            }
        } catch let error as NSError {
            Log.debug("Realm cache fail : \(error)")
        }
    }
    
    func cacheListObjects(_ list: [Object]) {
        guard !list.isEmpty else { return }
        
        do {
            let realm = try Realm()
            try realm.write {
                for object in list {
                    realm.add(object)
                }
            }
        } catch let error as NSError {
            Log.debug("Realm cache fail : \(error)")
        }
    }
    
    func updateCacheConvList(_ convs: [IMConvCacheObject]) {
        do {
            let realm = try Realm()
            try realm.write {
                realm.delete(realm.objects(IMConvCacheObject.self))
                for conv in convs {
                    realm.add(conv, update: .all)
                }
            }
        } catch {
        }
    }
    
    func cacheObject<T: Object>(_ objs: [T]) {
        do {
            let realm = try Realm()
            try realm.write {
                for obj in objs {
                    realm.add(obj, update: .all)
                }
            }
        } catch let error as NSError {
            Log.debug("Realm cache fail : \(error)")
        }
    }
    
    func cachedMerchantForId(_ merchantId: Int) -> Merchant? {
        if let cache: MerchantCacheObject = cachedObjectsForPredicate("merchantId = \(merchantId)")?.first {
            return cache.object()
        }
        return nil
    }
    
    func cachedUserForUserKey(_ userKey: String) -> User? {
        if let cache: UserCacheObject = cachedObjectsForPredicate("userKey = '\(userKey)'")?.first {
            return cache.object()
        }
        return nil
    }
    
    func cachedBannerForBannerId(_ bannerKey: String) -> Banner? {
        if let cache: BannerCacheObject = cachedObjectsForPredicate("bannerKey = '\(bannerKey)'")?.first {
            return cache.object()
        }
        return nil
    }
    
    func cachedObjectsForPredicate<T: Object>(_ predicate: String) -> Results<T>? {
        do {
            let realm = try Realm()
            return realm.objects(T.self).filter(predicate)
        } catch {}
        return nil
    }
    
    func cachedMessageForConv(_ conv: Conv, latestModel: ChatModel? = nil, oldestModel: ChatModel? = nil) -> [ChatModel] {
        return cachedMessageForConv(conv, latestDate: latestModel?.timeDate as Date?, oldestDate: oldestModel?.timeDate as Date?)
    }
    
    func cachedMessageForConv(_ conv: Conv, latestDate: Date?, oldestDate: Date?) -> [ChatModel] {
        var result = [ChatModel]()
        do{
            let realm = try Realm()
            
            var predicate: NSPredicate!
            if let latest = latestDate, let oldest = oldestDate {
                predicate = NSPredicate(format: "convKey = '\(conv.convKey)' and timestamp =< %@ and timestamp >= %@ ", latest as CVarArg, oldest as CVarArg)
            } else if let oldest = oldestDate {
                predicate = NSPredicate(format: "convKey = '\(conv.convKey)' and timestamp >= %@ ", oldest as CVarArg)
            } else {
                predicate = NSPredicate(format: "convKey = '\(conv.convKey)'")
            }
            
            let cacheList = realm
                .objects(IMMsgCacheObject.self)
                .filter(predicate)
                .sorted(byKeyPath: "timestamp", ascending: true)
            
            var offset: Int = 0
            if latestDate == nil && oldestDate == nil {
                offset = cacheList.count - min(cacheList.count, Constants.Paging.Offset)
            }
            
            for i in offset..<cacheList.count {
                if let msg = cacheList[i].object() {
                    result.append(msg)
                }
            }
        } catch {}
        return result
    }
    
    func cachedConvList() -> [Conv] {
        var result = [Conv]()
        do{
            let realm = try Realm()
            let cacheList = realm.objects(IMConvCacheObject.self)
            for i in 0..<cacheList.count {
                if let conv = cacheList[i].object() {
                    result.append(conv)
                }
            }
        } catch {}
        return result
    }
    
    func cachedStyleForSkiId(_ skuId: Int) -> Style? {
        if let cache: StyleCacheObject = cachedObjectsForPredicate("skuId = \(skuId)")?.first {
            return cache.object()
        }
        return nil
    }
    
    func deleteMsg(_ correlationKey: String) {
        do {
            let realm = try Realm()
            let cacheList = realm
                .objects(IMMsgCacheObject.self)
                .filter("correlationKey = '\(correlationKey)'")
            if let cacheObject = cacheList.first {
                try realm.write {
                    realm.delete(cacheObject)
                }
            }
        } catch {
        }
    }
    
    func deleteConv(_ convKey: String) {
        do {
            let realm = try Realm()
            let cacheList = realm
                .objects(IMConvCacheObject.self)
                .filter("convKey = '\(convKey)'")
            if let convCacheObject = cacheList.first {
                try realm.write {
                    realm.delete(convCacheObject)
                }
            }
        } catch {
        }
    }
    
    func removeIMCache() {
        do {
            let realm = try Realm()
            try realm.write {
                realm.delete(realm.objects(IMConvCacheObject.self))
                realm.delete(realm.objects(IMMsgCacheObject.self))
            }
        } catch let error as NSError {
            Log.debug(error)
        }
    }
    
    func removeAllUserCache() {
        do {
            let realm = try Realm()
            try realm.write {
                realm.delete(realm.objects(UserCacheObject.self))
            }
        } catch let error as NSError {
            Log.debug(error)
        }
    }
    
    func removeAllBannerCache() {
        do {
            let realm = try Realm()
            try realm.write {
                realm.delete(realm.objects(BannerCacheObject.self))
            }
        } catch let error as NSError {
            Log.debug(error)
        }
    }
    
    func addFriend(_ user: User){
        let cachedUsers = self.friendList.filter({$0.userKey == user.userKey})
        if cachedUsers.count > 0 {
            //delete old user
            self.deleteFriend(user)
        }
        self.friendList.append(user)
        if !FollowService.instance.cachedFollowingUserKeys.contains(user.userKey) {
            FollowService.instance.cachedFollowingUserKeys.insert(user.userKey)
        }
    }
    
    func deleteFriend(_ user: User){
        let cachedUsers = self.friendList.filter({$0.userKey == user.userKey})
        self.friendList = self.friendList.filter{!cachedUsers.contains($0)}
    }
    
    func aliasForKey(_ userKey: String) -> UserAlias? {
        return userAliasMap[userKey]
    }
    
    func updateAlias(_ alias: String, forKey userKey: String) {
        userAliasMap[userKey] = UserAlias(userKey: userKey, alias: alias)
    }
    
    func updateAlias(_ aliasList: [UserAlias]) {
        self.userAliasList = aliasList
        for userAlias in self.userAliasList {
            if let userKey = userAlias.userKey {
                self.userAliasMap[userKey] = userAlias
            }
        }
    }
    
    func clearAlias() {
        userAliasList.removeAll()
        userAliasMap.removeAll()
    }
    
    typealias BrandFetchingHandler = () -> Void
    typealias MerchantFetchingHandler = () -> Void
    typealias CategoryFetchingHandler = (_ cats: [Cat]?, _ nextPage: Int, _ error: NSError?) -> Void
    private let fetchingQueue = DispatchQueue(label: "com.mm.fetchingQueue", attributes: [])
    fileprivate(set) var merchantPoolReady = false
    open var merchantFetchCompletion:  (() -> Void)?
    fileprivate(set) var merchantPool = [Int: Merchant]() // 后边传来的merchant数据变成key value的形式
    fileprivate(set) var merchantArrayPool = [Merchant]() // 为了保证后台传来的merchant数据顺序不变,用数组接收
    fileprivate(set) var brandPoolReady = false
    fileprivate(set) var brandPool = [Int: Brand]()
    
    private var postPool = [Int: Post]()
    private var categoryPool = [Int: Cat]()
    private var subcategoryPool = [Int: Cat]()
    private var waitingPool = [MerchantFetchingHandler]()
    private var categoryWaitingPool = [CategoryFetchingHandler]()
    private var categories = [Cat]()
    var clonedCategories: [Cat]{
        get {
            var clonedCats = [Cat]()
            for cat in categories{
                if let clonedCat = cat.clone(){
                    clonedCats.append(clonedCat)
                }
            }
            
            return clonedCats
        }
    }
    
    private var fetchingMerchants = false
    private var fetchingCategories = false
    private var fetchingTimes = 0
    private var fetchingUsers = false
    fileprivate(set) var categoryNextPage = 1
    private func RunOnFetchingThread(_ block: @escaping ()->()) {
        fetchingQueue.async(execute: block)
    }
    
    
    private var fetchingBrands = false
    private var brandCallbacks = [BrandFetchingHandler]()
    
    func fetchAllBrands(_ completion: BrandFetchingHandler? = nil) {
        RunOnFetchingThread {
            if let callback = completion {
                self.brandCallbacks.append(callback)
            }
            
            if self.fetchingBrands {
                return
            }
            self.fetchingBrands = true
            self.fetchBrands()
        }
    }
    
    private func fetchBrands(_ pageNumber: Int = 1) {
        SearchService.searchAllBrand(pageSize: Constants.Paging.BrandBatch, pageNo: pageNumber, completion: { (response) in
            self.RunOnFetchingThread {
                if let brands = Mapper<Brand>().mapArray(JSONObject: response.result.value), response.result.isSuccess {
                    for brand in brands {
                        self.brandPool[brand.brandId] = brand
                    }
                    
                    if brands.count > 0 {
                        self.fetchBrands(pageNumber + 1)
                        return
                    }
                }
                for callback in self.brandCallbacks {
                    callback()
                }
                self.brandCallbacks.removeAll()
                self.fetchingBrands = false
                self.brandPoolReady = true
            }
        })
    }
    
    func brandById(_ brandId: Int, completion: @escaping ((Brand?) -> Void)) {
        RunOnFetchingThread {
            if let brand = self.brandPool[brandId] {
                DispatchQueue.main.async {
                    completion(brand)
                }
            } else {
                self.fetchAllBrands(){
                    DispatchQueue.main.async {
                        completion(self.brandPool[brandId])
                    }
                }
            }
        }
    }
    
    func cachedBrandById(_ brandId: Int) -> Brand? {
        if let brand = self.brandPool[brandId] {
            return brand
        }
        return nil
    }
    
    func fetchAllMerchants(_ completion: MerchantFetchingHandler? = nil) {
        RunOnFetchingThread {
            if let callback = completion {
                self.waitingPool.append(callback)
            }
            
            if self.fetchingMerchants {
                return
            }
            
            self.fetchingMerchants = true
            SearchService.searchAllMerchants() { (response) in
                self.RunOnFetchingThread {
                    if  let merchants = Mapper<Merchant>().mapArray(JSONObject: response.result.value), response.result.isSuccess {
                        for merchant in merchants {
                            self.merchantPool[merchant.merchantId] = merchant
                        }
                        self.merchantArrayPool = merchants
                    }
                    for callback in self.waitingPool {
                        callback()
                    }
                    self.waitingPool.removeAll()
                    self.fetchingMerchants = false
                    self.merchantPoolReady = true
                    
                    if let completion = self.merchantFetchCompletion {
                        completion()
                    }
                }
            }
        }
    }
    
    func merchantById(_ merchantId: Int, completion: @escaping ((_ merchant: Merchant?) -> Void)) {
        RunOnFetchingThread {
            if let merchant = self.merchantPool[merchantId] {
                DispatchQueue.main.async(execute: {
                    completion(merchant)
                })
            } else {
                self.fetchAllMerchants(){
                    DispatchQueue.main.async(execute: {
                        completion(self.merchantPool[merchantId])
                    })
                }
            }
        }
    }
    
    func cachedMerchantById(_ merchantId: Int) -> Merchant? {
        if let merchant = self.merchantPool[merchantId] {
            return merchant
        }
        return nil
    }
    
    func isActiveMerchant(_ merchantId: Int?) -> Bool {
        if let merchantId = merchantId {
            if merchantId == Constants.MMMerchantId {
                return true
            }
            if let _ = self.merchantPool[merchantId] {
                return true
            }
        }
        return false
    }
    
    func fetchAllUsers() {
        RunOnFetchingThread {
            if self.fetchingUsers {
                return
            }
            
            self.fetchingUsers = true
            
            let convList = WebSocketManager.sharedInstance().convList
            
            var userList = [String]()
            if let me = WebSocketManager.sharedInstance().userKey {
                userList.append(me)
            }
            
            for conv in convList {
                for userRole in conv.userList {
                    if let userKey = userRole.userKey, !userKey.isEmpty && !userList.contains(userRole.userKey!) {
                        userList.append(userRole.userKey!)
                    }
                }
            }
            
            var userPromise = [Promise<[String: User]>]()
            while userList.count > Constants.MAX_USER_REQUEST {
                let cutList = userList.initial(userList.count - Constants.MAX_USER_REQUEST)
                userList = userList.rest(Constants.MAX_USER_REQUEST)
                
                userPromise.append(Promise<[String: User]> { fufill, fail in
                    UserService.viewListWithUserKeys(
                        cutList,
                        getFromCache: false,
                        completion: { (map) in
                            fufill(map)
                    })
                })
            }
            
            userPromise.append(Promise<[String: User]> { fufill, fail in
                UserService.viewListWithUserKeys(
                    userList,
                    getFromCache: false,
                    completion: { (map) in
                        fufill(map)
                })
            })
            
            when(fulfilled: userPromise).then { maps -> Void in
                var me: User?
                var mergedMap = [String: User]()
                
                maps.eachWithIndex({ (index, map) in
                    if index == 0 {
                        mergedMap = map
                    }
                    else {
                        mergedMap.mergeAll(map)
                    }
                })
                
                if let userKey = WebSocketManager.sharedInstance().userKey {
                    me = mergedMap[userKey]
                }
                for conv in convList {
                    conv.updateUsers(me, map: mergedMap)
                }
                self.fetchingUsers = false
            }
        }
    }
    
    func fetchAllCategories(_ s: String? = "", sort : String? = "Priority", completion: CategoryFetchingHandler? = nil) {
        if self.categoryNextPage < 1 {
            if let strongCompletion = completion {
                strongCompletion(self.clonedCategories, self.categoryNextPage, nil)
            }
            return
        }
        
        if self.categoryNextPage >= 1 {
            self.fetchNextCategoryPage(completion: {(cats, nextPage, error) in
                if self.categoryNextPage >= 1 {
                    self.fetchAllCategories(completion: completion)
                } else if self.categoryNextPage == -1 {
                    if let strongCompletion = completion {
                        strongCompletion(self.clonedCategories, self.categoryNextPage, nil)
                    }
                }
            })
        }
    }
    
    func fetchNextCategoryPage(_ pageSize: Int = Constants.Paging.CategoryOffset, s: String? = "", sort : String? = "Priority", completion: CategoryFetchingHandler? = nil) {
        if self.categoryNextPage < 1 {
            if let strongCompletion = completion {
                strongCompletion(self.clonedCategories, self.categoryNextPage, nil)
            }
            return
        }
        
        RunOnFetchingThread {
            if let callback = completion {
                self.categoryWaitingPool.append(callback)
            }
            
            if self.fetchingCategories {
                return
            }
            
            self.fetchingCategories = true
            
            //如果请求每次失败，则会循环请求无限次 [糟糕的逻辑] TODO : FIXME
            self.fetchingTimes = self.fetchingTimes + 1
            if self.fetchingTimes > 100 {
                return
            }
            
            let block:(_ cats:[Cat]?, _ error:Error?) -> Void = { (cats,err) in
                var validCats = [Cat]()
                var error: NSError?
                if let cats = cats {
                    self.fetchingTimes = self.fetchingTimes - 1
                    if self.fetchingTimes < 0 {
                        self.fetchingTimes = 0
                    }
                    
                    validCats = cats.filter(){ $0.categoryId != 0 && $0.isActive() }
                    for currentCat in validCats {
                        self.categoryPool[currentCat.categoryId] = currentCat
                        currentCat.categoryList = currentCat.categoryList?.filter(){ $0.categoryId != 0 && $0.isActive() }
                        if let categoryList = currentCat.categoryList {
                            for subCat in categoryList {
                                self.subcategoryPool[subCat.categoryId] = subCat
                                subCat.categoryList = subCat.categoryList?.filter(){ $0.categoryId != 0 && $0.isActive() }
                            }
                        }
                    }
                    
                    if cats.count >= pageSize {
                        self.categoryNextPage = self.categoryNextPage + 1
                    } else {
                        self.categoryNextPage = -1
                    }
                } else if let err = err {
                    error = err as NSError
                }
                
                if validCats.count > 0{
                    self.categories.append(contentsOf: validCats)
                }
                
                for callback in self.categoryWaitingPool {
                    callback(validCats, self.categoryNextPage, error)
                }
                self.categoryWaitingPool.removeAll()
                self.fetchingCategories = false
            }
            
            SearchService.searchCategory(self.categoryNextPage, pageSize: pageSize, success: { (list) in
                self.RunOnFetchingThread {
                    block(list,nil)
                }
            }, failure: { (error) -> Bool in
                self.RunOnFetchingThread {
                    block(nil,error)
                }
                return true
            })
        }
    }
    
    func cachedCategoryById(_ categoryId: Int) -> Cat? {
        if let category = self.categoryPool[categoryId] {
            return category
        }
        return nil
    }
    
    func cachedSubcategoryById(_ subcateId: Int) -> Cat? {
        if let subcate = self.subcategoryPool[subcateId] {
            return subcate
        }
        return nil
    }
    
    func postById(_ postId: Int, completion: @escaping ((_ post: Post?) -> Void)) {
        if let post = self.postPool[postId] {
            completion(post)
        } else {
            NewsFeedService.listNewsFeedByPostId(postId, completion: { (response)  in
                if response.response?.statusCode == 200 {
                    if let newsFeedListResponse = Mapper<NewsFeedListResponse>().map(JSONObject: response.result.value), let newsfeeds = newsFeedListResponse.pageData as [Post]?, newsfeeds.count > 0 {
                        self.postPool[postId] = newsfeeds[0]
                        completion(newsfeeds[0])
                    } else {
                        completion(nil)
                    }
                } else {
                    completion(nil)
                }
            })
        }
    }
    
    //MARK - Magazine
    
    func refreshLikedMagazineCover() {
        firstly {
            return self.listLikedContentPage(pageIndex: 1)
            }.always {
                NotificationCenter.default.post(name: NSNotification.Name(rawValue: "refreshWishListFinished"), object: nil)
            }.catch { _ -> Void in
                Log.error("error")
        }
    }
    
    func listLikedContentPage(pageIndex: Int, saveToCache: Bool = true, completion:((_ magazineCovers: [MagazineCover]?) -> Void)? = nil) -> Promise<Any> {
        return Promise { fullfill, reject in
            MagazineService.viewContentPageListByUserKey(pageIndex: pageIndex, completion: {[weak self] (response) in
                if let strongSelf = self {
                    if response.result.isSuccess {
                        if response.response?.statusCode == 200 {
                            
                            if let data = Mapper<ContentPageList>().map(JSONObject: response.result.value) {
                                if saveToCache {
                                    strongSelf.likedMagazineCovers = data.pageData
                                }
                                if let contentPageList = strongSelf.likedMagazineCovers {
                                    fullfill(contentPageList)
                                }
                            }
                            if let strongCompletion = completion {
                                strongCompletion(strongSelf.likedMagazineCovers)
                            }
                            fullfill("OK")
                        } else {
                            var statusCode = 0
                            if let code = response.response?.statusCode {
                                statusCode = code
                            }
                            let error = NSError(domain: "", code: statusCode, userInfo: nil)
                            reject(error)
                        }
                    } else{
                        reject(response.result.error!)
                    }
                }
            })
        }
    }
    
    func removeLikedMagazieCover(_ magazineCover: MagazineCover){
        if let index = self.likedMagazineCovers?.index(where: { (element) -> Bool in
            return element.contentPageKey == magazineCover.contentPageKey}){
            self.likedMagazineCovers?.remove(at: index)
        }
        NotificationCenter.default.post(name: Notification.Name(rawValue: "refreshWishListFinished"), object: nil)
    }
    
    func addLikedMagazieCover(_ magazineCover: MagazineCover) {
        if let _ = self.likedMagazineCovers?.index(where: { (element) -> Bool in
            return element.contentPageKey == magazineCover.contentPageKey}) {
            return
        }
        if self.likedMagazineCovers == nil {
            self.likedMagazineCovers = []
        }
        
        self.likedMagazineCovers?.append(magazineCover)
        NotificationCenter.default.post(name: Notification.Name(rawValue: "refreshWishListFinished"), object: nil)
    }
    
    var hasNewClaimedCoupon = UserDefaults.standard.bool(forKey: "hasNewClaimedCoupon") {
        didSet {
            UserDefaults.standard.set(hasNewClaimedCoupon, forKey: "hasNewClaimedCoupon")
            UserDefaults.standard.synchronize()
            NotificationCenter.default.post(name: Constants.Notification.couponClaimedDidUpdate, object: nil)
        }
    }
    
    func clearClaimedCouponFlag() {
        hasNewClaimedCoupon = false
    }
    
    private let couponCacheInterval = TimeInterval(30)
    private var couponLastUpdateTimestamp: TimeInterval? = nil
    var listMMCoupon = [Coupon]()
    var hasMMCoupon = false
    
    private func fetchMMCoupon() -> Promise<Any> {
        return Promise { fulfill, reject in
            CouponService.listClaimedCoupon(CouponMerchant.mm.rawValue, success: { [weak self] (couponList) in
                if let strongSelf = self {
                    strongSelf.listMMCoupon.removeAll()
                    if let coupons = couponList.pageData {
                        let activeCoupons = coupons.filter { $0.isAvailable && $0.isRedeemable }
                        if !activeCoupons.isEmpty {
                            for coupon in activeCoupons {
                                if coupon.availableTo == nil && coupon.availableFrom == nil {
                                    strongSelf.hasMMCoupon = true
                                    strongSelf.listMMCoupon.append(coupon)
                                } else if let startDate = coupon.availableFrom, let endDate = coupon.availableTo {
                                    if startDate < Date() && endDate > Date() {
                                        strongSelf.hasMMCoupon = true
                                        strongSelf.listMMCoupon.append(coupon)
                                    }
                                }
                            }
                        }
                        fulfill("OK")
                    }
                }
                }, failure: { (error) -> Bool in
                    reject(error)
                    return true
            })
        }
    }
    
    func listClaimedCoupon() -> Promise<Any> {
        return Promise { fulfill, reject in
            let now = Date().timeIntervalSince1970
            if couponLastUpdateTimestamp == nil || (now - couponLastUpdateTimestamp! > couponCacheInterval) {
                self.couponLastUpdateTimestamp = now
                firstly {
                    return fetchMMCoupon()
                    }.always {
                        fulfill("OK")
                }
            } else {
                fulfill("OK")
            }
        }
    }
    
    func resetCouponFetchingTime() {
        couponLastUpdateTimestamp = nil
    }
    
    //MARK: 保存cps跳转过来的参数 start
    
    /// 保存cps传过来的code和时间戳
    ///
    /// - Parameter query: url.query
    func saveSmzdmCode(query:QBundle) {
        guard let feedback = query["feedback"]?.string, !feedback.isEmpty else {
            return
        }
        
        var queryDic = ["feedback" : feedback]
        if let cpsTime = query["cpsTime"]?.string, !cpsTime.isEmpty {
            queryDic["cpsTime"] = cpsTime
        }
        
        if queryDic.count > 0 {
            UserDefaults.standard.set(queryDic, forKey: "cps_feedback_time")
            UserDefaults.standard.synchronize()
            print(queryDic)
        } else {
            Log.debug("save cpscode fail")
        }
    }
    
    /// 获取cps的code字典
    ///
    /// - Returns: [string: any]
    func getSmzdeCode() -> [String : Any]? {
        if let queryDic : [String: String] = UserDefaults.standard.dictionary(forKey: "cps_feedback_time") as? [String : String] {
            let cpst = queryDic["cpsTime"]
            let date = Date(timeIntervalSince1970: TimeInterval((atof(cpst))/1000))
            let day = date.isDaysAgo()
            if day <= 30 && day >= 0 {
                // 三十天之内添加code
                return ["CPS":["Name":"Smzdm","Code":queryDic["feedback"] ?? ""]]
            } else {
                return /**["CPS":["Name":"","Code":""]]*/ nil
            }
        }
        return /**["CPS":["Name":"","Code":""]]*/ nil
    }
    //MARK: 保存cps跳转过来的参数 end
}

