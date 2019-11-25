//
//  ProductReviewViewController.swift
//  merchant-ios
//
//  Created by Gam Bogo on 6/2/16.
//  Copyright © 2016 WWE & CO. All rights reserved.
//

import Foundation
import PromiseKit
import ObjectMapper
import SwiftDate
import CSStickyHeaderFlowLayout
import SKPhotoBrowser

class ProductReviewViewController : MmViewController{
    
    private final let DefaultCellID = "DefaultCellID"
    
    private var photoBrowser: SKPhotoBrowser?
    //FOR REVIEW
    private var currentPageNo: Int = 1
    private var totalPage = 0
    private var reviewList = [SkuReview]()
    private var selectedRating = 0 // 0 means all rating
    private var isShowReviewWithImageOnly = false
    private var totalRating1 = 0
    private var totalRating2 = 0
    private var totalRating3 = 0
    private var totalRating4 = 0
    private var totalRating5 = 0
    private var totalRatingImage = 0
    var summaryReview: ProductReview?
    
    var ratingHeader: RatingMenuHeaderView?
    
    final let RatingMenuHeaderHeight: CGFloat = RatingMenuHeaderView.DefaltHeight
    final let RatingMenuHeaderViewIdentifier = "RatingMenuHeaderViewIdentifier"
    
    private var layout: CSStickyHeaderFlowLayout? {
        return self.collectionView?.collectionViewLayout as? CSStickyHeaderFlowLayout
    }
    
    private enum ReviewRow: Int {
        case unknown = -1
        case userReviewRow = 0
        case imagesReviewRow = 1
        case descriptionReviewRow = 2
    }
    
    private var noReviewView: UIView!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        title = String.localize("LB_CA_PROD_REVIEW_ALL")
        
        view.backgroundColor = UIColor.primary2()
        
        initAnalyticLog()
        
        createBackButton()
        setupCollectionView()
        
        loadTotalCountRating()
        loadReview(rating: 0)
        setupNoReviewView()
    }
    
    private func setupNoReviewView() {
        let noReviewViewSize = CGSize(width: 90, height: 156)
        let heightNavigation = CGFloat(64)
        noReviewView = UIView(frame: CGRect(x: (view.width - noReviewViewSize.width) / 2, y: (view.height - noReviewViewSize.height) / 2 + heightNavigation, width: noReviewViewSize.width, height: noReviewViewSize.height))
        noReviewView.isHidden = true
        
        let boxImageViewSize = CGSize(width: 76, height: 76)
        let boxImageView = UIImageView(frame: CGRect(x: (noReviewView.width - boxImageViewSize.width) / 2, y: 0, width: boxImageViewSize.width, height: boxImageViewSize.height))
        boxImageView.image = UIImage(named: "icon_no_review")
        noReviewView.addSubview(boxImageView)
        
        let label = UILabel(frame: CGRect(x: 0, y: boxImageView.frame.maxY, width: noReviewViewSize.width, height: 50))
        label.textAlignment = .center
        label.formatSize(16)
        label.textColor = UIColor.secondary3()
        label.text = String.localize("LB_CA_NO_COMMENT")
        noReviewView.addSubview(label)
        
        view.addSubview(noReviewView)
    }
    
    func reloadAllData() {
        self.collectionView.reloadData()
        
        self.collectionView.setContentOffset(CGPoint.zero, animated: false)
    }
    
    func initAnalyticLog(){
        var merchantCode = ""
        if let merchantId = summaryReview?.skuReview?.merchantId{
            merchantCode = CacheManager.sharedManager.cachedMerchantById(merchantId)?.merchantCode ?? ""
        }
        
        initAnalyticsViewRecord(
            merchantCode: merchantCode,
            viewDisplayName: summaryReview?.skuReview?.skuName,
            viewLocation: "AllReviews",
            viewRef: summaryReview?.skuReview?.styleCode,
            viewType: "Product"
        )
    }
    
    //MARK: - Set Up
    private func setupCollectionView() {
        collectionView.backgroundColor = UIColor.clear
        collectionView.register(UICollectionViewCell.self, forCellWithReuseIdentifier: DefaultCellID)
        collectionView.register(RatingUserCell.self, forCellWithReuseIdentifier: RatingUserCell.CellIdentifier)
        collectionView.register(PlainTextCell.self, forCellWithReuseIdentifier: PlainTextCell.CellIdentifier)
        collectionView.register(HorizontalImageCell.self, forCellWithReuseIdentifier: HorizontalImageCell.CellIdentifier)
        
        // Setup Rating Filter Menu Header
        setupRatingMenuHeader()
        
    }
    
    func setupRatingMenuHeader() {
        let flowLayout = CSStickyHeaderFlowLayout()
        flowLayout.parallaxHeaderAlwaysOnTop = true
        flowLayout.disableStickyHeaders = false
        flowLayout.parallaxHeaderReferenceSize = CGSize.zero
        self.collectionView.setCollectionViewLayout(flowLayout, animated: false)
        self.collectionView.bounces = true
        
        self.collectionView?.register(RatingMenuHeaderView.self, forSupplementaryViewOfKind: CSStickyHeaderParallaxHeader, withReuseIdentifier: RatingMenuHeaderViewIdentifier)
        self.layout?.parallaxHeaderReferenceSize = CGSize(width: self.view.frame.size.width, height: RatingMenuHeaderHeight)
        self.layout?.parallaxHeaderMinimumReferenceSize = CGSize(width: self.view.frame.size.width, height: RatingMenuHeaderHeight)
    }
    
    override func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        
        // Load More at Last Row
        if indexPath.section == reviewList.count && totalPage >= currentPageNo {
            loadReview(rating: selectedRating, isShowReviewWithImageOnly: isShowReviewWithImageOnly)
        }
        
        let skuReview: SkuReview = reviewList[indexPath.section]
        let reviewRow = self.getRow(skuReview: skuReview, index: indexPath.row)
        switch reviewRow {
        case .userReviewRow:
            let cell = collectionView.dequeueReusableCell(withReuseIdentifier: RatingUserCell.CellIdentifier, for: indexPath) as! RatingUserCell
            cell.backgroundColor = UIColor.white
            cell.ratingView.isUserInteractionEnabled = false
            cell.skuReview = skuReview
            cell.delegate = self
            
            cell.moreReviewHandler = { ratingUserCell -> Void in
                
                self.showPopupConfirmReport({ (confirm) in
                    if confirm {
                        if LoginManager.getLoginState() == .validUser {
                            let afterSalesViewController = AfterSalesViewController()
                            afterSalesViewController.currentViewType = .reportReview
                            afterSalesViewController.skuReview = skuReview
                            afterSalesViewController.delegate = self
                            let navigationController = MmNavigationController(rootViewController: afterSalesViewController)
                            self.present(navigationController, animated: true, completion: nil)
                        } else {
                            LoginManager.goToLogin()
                        }
                    }
                })
                
                ratingUserCell.recordAction(.Tap, sourceRef: "ReportReview", sourceType: .Button, targetRef: ratingUserCell.skuReview?.skuReviewId.toString() ?? "", targetType: AnalyticsActionRecord.ActionElement.Review)
            }
            
            cell.initAnalytics(withViewKey: analyticsViewRecord.viewKey, impressionKey: recordImpression("", authorType: skuReview.userTypeString(), brandCode: "", impressionRef: skuReview.skuReviewId.toString(), impressionType: "Product", impressionVariantRef: skuReview.skuReviewId.toString(), impressionDisplayName: skuReview.description.subStringToIndex(50), merchantCode: skuReview.merchantId.toString(), parentRef: skuReview.styleCode, parentType: "Product", positionComponent: "ReviewLiisting", positionIndex: indexPath.row + 1, positionLocation: "AllReviews"))
            
            return cell
        case .imagesReviewRow:
            let cell = collectionView.dequeueReusableCell(withReuseIdentifier: HorizontalImageCell.CellIdentifier, for: indexPath) as! HorizontalImageCell
            cell.hideHeaderView = true
            cell.backgroundColor = UIColor.white
            cell.imageBucketDelegate = self
            cell.dataSource = self.getImages(skuReview: skuReview)
            cell.disableScrollToTop()
            return cell
        case .descriptionReviewRow:
            let cell = collectionView.dequeueReusableCell(withReuseIdentifier: PlainTextCell.CellIdentifier, for: indexPath) as! PlainTextCell
            cell.backgroundColor = UIColor.white
            cell.contentLabel.text = skuReview.replyDescription
            
            return cell
        default:
            return self.getDefaultCell(collectionView, cellForItemAt: indexPath)
        }
        
    }
    
    func collectionView(_ collectionView: UICollectionView, viewForSupplementaryElementOfKind kind: String, at indexPath: IndexPath) -> UICollectionReusableView {
        
        if kind == CSStickyHeaderParallaxHeader {
            let view = collectionView.dequeueReusableSupplementaryView(ofKind: kind, withReuseIdentifier: RatingMenuHeaderViewIdentifier, for: indexPath)
            self.ratingHeader = (view as! RatingMenuHeaderView)
            if let header = self.ratingHeader {
                
                header.delegate = self
                header.backgroundColor = UIColor.white
                
                header.setTotalRating(ratingMenu: .showOneRating, ratingValue: totalRating1)
                header.setTotalRating(ratingMenu: .showTwoRating, ratingValue: totalRating2)
                header.setTotalRating(ratingMenu: .showThreeRating, ratingValue: totalRating3)
                header.setTotalRating(ratingMenu: .showFourRating, ratingValue: totalRating4)
                header.setTotalRating(ratingMenu: .showFiveRating, ratingValue: totalRating5)
                header.setTotalRating(ratingMenu: .showImageRating, ratingValue: totalRatingImage)
                
                return header
            }
            
        }
        return UICollectionReusableView()
        
    }
    
    func getDefaultCell(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell{
        let cell = collectionView.dequeueReusableCell(withReuseIdentifier: DefaultCellID, for: indexPath)
        cell.backgroundColor = UIColor.white
        return cell
    }
    
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, sizeForItemAt indexPath: IndexPath) -> CGSize {
        let skuReview: SkuReview = reviewList[indexPath.section]
        let reviewRow = self.getRow(skuReview: skuReview, index: indexPath.row)
        switch reviewRow {
        case .userReviewRow:
            return RatingUserCell.getCellSize(text: skuReview.description, cellWidth: view.width)
        case .imagesReviewRow:
            return CGSize(width: view.frame.width, height: view.frame.width / 3.9)
        case .descriptionReviewRow:
            return PlainTextCell.getSizeCell(text: skuReview.replyDescription, cellWidth: self.view.frame.size.width)
        default:
            return CGSize.zero
        }
        
    }
    
    func numberOfSections(in collectionView: UICollectionView) -> Int {
        return reviewList.count //Top section for filtering rating
    }
    
    override func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        let skuReview: SkuReview = reviewList[section]
        return getTotalReviewRows(skuReview: skuReview)
    }
    
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, minimumLineSpacingForSectionAt section: Int) -> CGFloat {
        return 0.0
    }
    
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, minimumInteritemSpacingForSectionAt section: Int) -> CGFloat {
        return 0.0
    }
    
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, insetForSectionAt section: Int) -> UIEdgeInsets {
        return UIEdgeInsets(top: 0.0, left: 0.0, bottom: 1.0, right: 0.0)
    }
    
    //MARK: - Review
    
    private func loadReview(rating: Int, isShowReviewWithImageOnly: Bool = false) {
        self.selectedRating = rating
        self.isShowReviewWithImageOnly = isShowReviewWithImageOnly
        
        if let summaryReview = self.summaryReview {
            if let skuReview = summaryReview.skuReview {
                showLoading()
                
                firstly {
                    return self.listReview(merchantId: skuReview.merchantId, styleCode: skuReview.styleCode, rating: rating, isShowReviewWithImageOnly: isShowReviewWithImageOnly, pageNo: currentPageNo)
                    }.then { _ -> Void in
                        self.currentPageNo += 1
                        self.reloadAllData()
                    }.always {
                        self.stopLoading()
                    }.catch { _ -> Void in
                        Log.error("error")
                }
            }
        }
    }
    
    //TODO: - Load several api to get total for each rating
    private func loadTotalCountRating() {
        if let summaryReview = self.summaryReview {
            if let skuReview = summaryReview.skuReview {
                showLoading()
                
                firstly {
                    return self.countRatingReview(merchantId: skuReview.merchantId, styleCode: skuReview.styleCode, rating: 1, isShowReviewWithImageOnly: false)
                    }.then { _ -> Promise<Any> in
                        return self.countRatingReview(merchantId: skuReview.merchantId, styleCode: skuReview.styleCode, rating: 2, isShowReviewWithImageOnly: false)
                    }.then { _ -> Promise<Any> in
                        return self.countRatingReview(merchantId: skuReview.merchantId, styleCode: skuReview.styleCode, rating: 3, isShowReviewWithImageOnly: false)
                    }.then { _ -> Promise<Any> in
                        return self.countRatingReview(merchantId: skuReview.merchantId, styleCode: skuReview.styleCode, rating: 4, isShowReviewWithImageOnly: false)
                    }.then { _ -> Promise<Any> in
                        return self.countRatingReview(merchantId: skuReview.merchantId, styleCode: skuReview.styleCode, rating: 5, isShowReviewWithImageOnly: false)
                    }.then { _ -> Promise<Any> in
                        return self.countRatingReview(merchantId: skuReview.merchantId, styleCode: skuReview.styleCode, rating: 0, isShowReviewWithImageOnly: true)
                    }.then { _ -> Void in
                        self.reloadAllData()
                    }.always {
                        self.stopLoading()
                    }.catch { _ -> Void in
                        Log.error("error")
                }
            }
        }
    }
    
    private func getTotalReviewRows(skuReview: SkuReview?) -> Int {
        var countReviewRows = 0
        if let skuReview = skuReview {
            // Row user review
            countReviewRows += 1
            
            if skuReview.getImages().count > 0 {
                // Row photo review
                countReviewRows += 1
            }
            
            if !skuReview.replyDescription.isEmpty {
                // Row description review
                countReviewRows += 1
            }
        }
        
        return countReviewRows
    }
    
    private func getRow(skuReview: SkuReview?, index: Int) -> ReviewRow {
        if let skuReview = skuReview {
            var countReviewRows = 0
            if index == countReviewRows {
                return ReviewRow.userReviewRow
            }
            
            if skuReview.getImages().count > 0 {
                // Row photo review
                countReviewRows += 1
                if index == countReviewRows {
                    return ReviewRow.imagesReviewRow
                }
            }
            
            if !skuReview.replyDescription.isEmpty {
                // Row description review
                countReviewRows += 1
                if index == countReviewRows {
                    return ReviewRow.descriptionReviewRow
                }
            }
        }
        
        return .unknown
    }
    
    func getImages(skuReview: SkuReview?) -> [ImageBucket] {
        var listReviewImages = [ImageBucket]()
        
        if let skuReview = skuReview {
            for image in skuReview.getImages() {
                listReviewImages.append(ImageBucket(imageKey: image, category: .review))
            }
        }
        
        return listReviewImages
    }
    
    //TODO: - Count Rating By Using List Review. should api update
    func countRatingReview(merchantId: Int, styleCode: String, rating: Int, isShowReviewWithImageOnly: Bool = false) -> Promise<Any> {
        return Promise{ fulfill, reject in
            ReviewService.listReview(merchantId: merchantId, styleCode: styleCode, rating: rating, isShowReviewWithImageOnly: isShowReviewWithImageOnly, pageNo: 1, completion: { [weak self] (response) in
                if let strongSelf = self {
                    if response.result.isSuccess {
                        if response.response?.statusCode == 200 {
                            if let skuReviewResponse = Mapper<SkuReviewResponse>().map(JSONObject: response.result.value) {
                                
                                switch rating {
                                case 1:
                                    strongSelf.totalRating1 = skuReviewResponse.hitsTotal
                                case 2:
                                    strongSelf.totalRating2 = skuReviewResponse.hitsTotal
                                case 3:
                                    strongSelf.totalRating3 = skuReviewResponse.hitsTotal
                                case 4:
                                    strongSelf.totalRating4 = skuReviewResponse.hitsTotal
                                case 5:
                                    strongSelf.totalRating5 = skuReviewResponse.hitsTotal
                                default:
                                    break
                                }
                                
                                if isShowReviewWithImageOnly {
                                    strongSelf.totalRatingImage = skuReviewResponse.hitsTotal
                                }
                            }
                        }
                        fulfill("OK")
                    } else {
                        reject(response.result.error!)
                    }
                }
            })
        }
    }
    
    //Rating and isReviewWithImage for filtering product
    func listReview(merchantId: Int, styleCode: String, rating: Int, isShowReviewWithImageOnly: Bool, pageNo: Int) -> Promise<Any> {
        return Promise{ fulfill, reject in
            ReviewService.listReview(merchantId: merchantId, styleCode: styleCode, rating: rating, isShowReviewWithImageOnly: isShowReviewWithImageOnly, pageNo: pageNo, completion: { [weak self] (response) in
                if let strongSelf = self {
                    if response.result.isSuccess {
                        if response.response?.statusCode == 200 {
                            if let skuReviewResponse = Mapper<SkuReviewResponse>().map(JSONObject: response.result.value) {
                                if let reviewList = skuReviewResponse.pageData {
                                    strongSelf.reviewList.append(contentsOf: reviewList)
                                    strongSelf.totalPage = skuReviewResponse.pageTotal
                                    
                                }
                                
                                if strongSelf.reviewList.isEmpty {
                                    
                                    strongSelf.noReviewView.isHidden = false
                                    
                                } else {
                                    strongSelf.noReviewView.isHidden = true
                                }
                                
                            }
                        }
                        fulfill("OK")
                    } else {
                        reject(response.result.error!)
                    }
                }
            })
        }
    }
    
    fileprivate func popupImageViewer(imageKeyList: [ImageBucket], index: Int) {
        var images = [SKPhoto]()
        for imageBucket in imageKeyList {
            let url = ImageURLFactory.URLSize1000(imageBucket.imageKey, category: imageBucket.imageCategory).absoluteString
            let photo = SKPhoto.photoWithImageURL(url)
            photo.shouldCachePhotoURLImage = true
            images.append(photo)
        }
        
        guard images.count >= imageKeyList.count else {
            return
        }
        
        photoBrowser = SKPhotoBrowser(photos: images)
        if let browser = photoBrowser {
            let initialIndex = index
            browser.initializePageIndex(initialIndex)
            navigationController?.present(browser, animated: true, completion: nil)
        }
    }
}

//MARK: - Extension
extension ProductReviewViewController : RatingMenuCollectionCellDelegate{
    func didRatingMenuItemTap(_ menuAction: ReviewRatingMenuAction) {
        
        currentPageNo = 1
        reviewList.removeAll()
        
        switch menuAction {
        case .showAll:
            loadReview(rating: 0)
        case .showOneRating:
            loadReview(rating: 1)
        case .showTwoRating:
            loadReview(rating: 2)
        case .showThreeRating:
            loadReview(rating: 3)
        case .showFourRating:
            loadReview(rating: 4)
        case .showFiveRating:
            loadReview(rating: 5)
        case .showImageRating:
            loadReview(rating: 0, isShowReviewWithImageOnly: true)
        default:
            break
        }
        
    }
}

extension ProductReviewViewController : RatingUserCellDelegate, HorizontalImageBucketCellDelegate, UIAlertViewDelegate {
    func didTapOnUser(_ userName: String) {
        DeepLinkManager.sharedManager.pushPublicProfile(viewController: self, userName: userName)
    }
    
    func ontap(imageBucketList: [ImageBucket], row: Int) {
        popupImageViewer(imageKeyList: imageBucketList, index: row)
    }
}



extension ProductReviewViewController: AfterSalesViewProtocol {
    
    func didSubmitReportReview(_ isSuccess: Bool) {
        if isSuccess {
            self.showSuccessPopupWithText(String.localize("LB_CA_REPORT_REVIEW_SUCCESS"))
        }
    }
    
    func didCancelOrder(_ isSuccess: Bool, orderItem: OrderItem?, orderCancel: OrderCancel?) {
        
    }
    
    func didDisputeOrder(_ isSuccess: Bool, orderItem: OrderItem?, orderReturn: OrderReturn?) {
        
    }
    
    func didReturnOrder(_ isSuccess: Bool, orderItem: OrderItem?, orderReturn: OrderReturn?) {
        
    }
}



