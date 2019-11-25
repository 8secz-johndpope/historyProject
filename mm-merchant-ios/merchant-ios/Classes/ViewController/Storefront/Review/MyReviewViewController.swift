//
//  MyReviewViewController.swift
//  merchant-ios
//
//  Created by Stephen Yuen on 24/6/2016.
//  Copyright © 2016 WWE & CO. All rights reserved.
//

import UIKit
import PromiseKit
import ObjectMapper

class MyReviewViewController: MmViewController {
    
    private final let DefaultCellID = "DefaultCellID"
    
    private var skuReviews = [SkuReview]()
    private var currentPage = 1
    private var totalPage = 0
	
	private var noReviewView: UIView!
    
    enum ReviewItemCellRow: Int {
        case product = 0,
        userReviewRow,
        imagesReviewRow,
        descriptionReviewRow
        
        static var count: Int { return ReviewItemCellRow.descriptionReviewRow.hashValue + 1 }
    }

    override func viewDidLoad() {
        super.viewDidLoad()

        title = String.localize("LB_CA_MY_REVIEW_ALL")  
        
        view.backgroundColor = UIColor.primary2()
        
        createBackButton()
        createRightButton(String.localize("LB_CA_OMS_REVIEW_WRITE"), action: #selector(writeReview))
        setupCollectionView()
        loadReviews(atPage: currentPage)
		setupNoReviewView()
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    // MARK: - Setup view
    
    private func setupCollectionView() {
        collectionView.backgroundColor = UIColor.clear
        collectionView.register(UICollectionViewCell.self, forCellWithReuseIdentifier: DefaultCellID)
        collectionView.register(OrderItemCell.self, forCellWithReuseIdentifier: OrderItemCell.CellIdentifier)
        collectionView.register(RatingUserCell.self, forCellWithReuseIdentifier: RatingUserCell.CellIdentifier)
        collectionView.register(HorizontalImageCell.self, forCellWithReuseIdentifier: HorizontalImageCell.CellIdentifier)
        collectionView.register(MyReviewPlainTextCell.self, forCellWithReuseIdentifier: MyReviewPlainTextCell.CellIdentifier)
    }
    
    private func getDefaultCell(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        let cell = collectionView.dequeueReusableCell(withReuseIdentifier: DefaultCellID, for: indexPath)
        cell.backgroundColor = UIColor.white
        
        return cell
    }
    
    // MARK: - Action
    
    @objc func writeReview(_ sender: UIBarButtonItem) {
        var bundle = QBundle()
        bundle["viewMode"] = QValue(Constants.OmsViewMode.toBeRated.rawValue)
        Navigator.shared.dopen(Navigator.mymm.website_order_list, params: bundle)
    }
    
    // MARK: - Data
    
    private func loadReviews(atPage page: Int) {
        showLoading()

        firstly {
            return self.listMyReviews(atPage: page)
        }.then { _ -> Void in
            if self.skuReviews.count > 0 {
                self.title = String.localize("LB_CA_MY_REVIEWS").replacingOccurrences(of: "{0}", with: "\(self.skuReviews.count)")
            }
            else {
                self.title = String.localize("LB_CA_MY_REVIEWS").replacingOccurrences(of: " ({0})", with: "")
            }
            self.collectionView.reloadData()
        }.always {
            self.stopLoading()
        }.catch { _ -> Void in
            Log.error("error")
        }
    }
	
	private func setupNoReviewView() {
		let noReviewViewSize = CGSize(width: 90, height: 156)
		noReviewView = UIView(frame: CGRect(x: (view.width - noReviewViewSize.width) / 2, y: (collectionView.height - noReviewViewSize.height) / 2, width: noReviewViewSize.width, height: noReviewViewSize.height))
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
	
    func listMyReviews(atPage page: Int) -> Promise<Any> {
        return Promise{ fulfill, reject in
            ReviewService.listMyReview(atPage: page, completion: { [weak self] (response) in
                if let strongSelf = self {
                    if response.result.isSuccess {
                        if response.response?.statusCode == 200 {
                            if let skuReviewResponse = Mapper<SkuReviewResponse>().map(JSONObject: response.result.value) {
                                if let skuReviews = skuReviewResponse.pageData, skuReviews.count > 0 {
                                    strongSelf.skuReviews.append(contentsOf: skuReviews)
                                    
                                    strongSelf.currentPage = skuReviewResponse.pageCurrent
                                    strongSelf.totalPage = skuReviewResponse.pageTotal
									
									strongSelf.noReviewView.isHidden = true
									
								} else {
									strongSelf.noReviewView.isHidden = false
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
    
    func getImages(skuReview: SkuReview?) -> [ImageBucket] {
        var reviewImages = [ImageBucket]()
        
        if let skuReview = skuReview {
            for image in skuReview.getImages() {
                reviewImages.append(ImageBucket(imageKey: image, category: .review))
            }
        }
        
        return reviewImages
    }
    
    // MARK: - Collection view data source
    
    func numberOfSections(in collectionView: UICollectionView) -> Int {
        return skuReviews.count
    }
    
    override func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return ReviewItemCellRow.count
    }
    
    override func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        let skuReview = skuReviews[indexPath.section]
        
        // Load More
        if indexPath.section == skuReviews.count - 1 && indexPath.item == 0 && totalPage > currentPage {
            loadReviews(atPage: currentPage + 1)
        }
        
        if let reviewItemCellRow = ReviewItemCellRow(rawValue: indexPath.row) {
            switch reviewItemCellRow {
            case .product:
                let cell = collectionView.dequeueReusableCell(withReuseIdentifier: OrderItemCell.CellIdentifier, for: indexPath) as! OrderItemCell
                cell.skuReview = skuReviews[indexPath.section]
                cell.hideBottomBorderView()

                cell.hidePriceLabel()
                cell.updateLayout()
                
                return cell
            case .userReviewRow:
                let cell = collectionView.dequeueReusableCell(withReuseIdentifier: RatingUserCell.CellIdentifier, for: indexPath) as! RatingUserCell
                cell.backgroundColor = UIColor.white
                cell.ratingView.isUserInteractionEnabled = false
                cell.displayAvatar = false
                cell.skuReview = skuReview
                cell.moreActionButton.isHidden = true
                return cell
            case .imagesReviewRow:
                let cell = collectionView.dequeueReusableCell(withReuseIdentifier: HorizontalImageCell.CellIdentifier, for: indexPath) as! HorizontalImageCell
                cell.backgroundColor = UIColor.white
                cell.hideHeaderView = true
                cell.dataSource = getImages(skuReview: skuReview)
                cell.disableScrollToTop()
                
                return cell
            case .descriptionReviewRow:
                let cell = collectionView.dequeueReusableCell(withReuseIdentifier: MyReviewPlainTextCell.CellIdentifier, for: indexPath) as! MyReviewPlainTextCell
                cell.backgroundColor = UIColor.white
                cell.contentLabel.text = skuReview.replyDescription
                return cell
            }
        }
        
        return getDefaultCell(collectionView, cellForItemAt: indexPath)
    }
    
    // MARK: - Collection view delegate
    
    func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        let skuReview = skuReviews[indexPath.section]
        
        if let reviewItemCellRow = ReviewItemCellRow(rawValue: indexPath.row) {
            if reviewItemCellRow == .product {
                let style = Style()
                style.styleCode = skuReview.styleCode
                style.merchantId = skuReview.merchantId
                
                let styleViewController = StyleViewController(style: style)
                
                self.navigationController?.pushViewController(styleViewController, animated: true)
            }
        }
    }
    
    // MARK: - Collection view delegate flow layout
    
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, sizeForItemAt indexPath: IndexPath) -> CGSize {
        let skuReview = skuReviews[indexPath.section]
        
        if let reviewItemCellRow = ReviewItemCellRow(rawValue: indexPath.row) {
            switch reviewItemCellRow {
            case .product:
                return CGSize(width: view.width, height: 120)
            case .userReviewRow:
                return RatingUserCell.getCellSize(text: skuReview.description, cellWidth: view.width, hasAvatar: false)
            case .imagesReviewRow:
                if getImages(skuReview: skuReview).count > 0 {
                    return CGSize(width: view.width, height: view.width / 3.9)
                }
            case .descriptionReviewRow:
                if skuReview.replyDescription.length > 0 {
                    return MyReviewPlainTextCell.getSizeCell(text: skuReview.replyDescription, cellWidth: view.width)
                }
            }
        }
        
        return CGSize.zero
    }
    
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, insetForSectionAt section: Int) -> UIEdgeInsets {
        return UIEdgeInsets(top: 0.0, left: 0.0, bottom: 1.0, right: 0.0)
    }
    
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, minimumLineSpacingForSectionAt section: Int) -> CGFloat {
        return 0.0
    }
    
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, minimumInteritemSpacingForSectionAt section: Int) -> CGFloat {
        return 0.0
    }
    
}
