//
//  OrderReviewViewController.swift
//  merchant-ios
//
//  Created by Quang Truong Dinh on 6/1/16.
//  Copyright © 2016 WWE & CO. All rights reserved.
//

import Foundation
import PromiseKit
import ObjectMapper

protocol OrderReviewViewControllerDelegate: NSObjectProtocol {
    func didSubmitReview(isSuccess: Bool, shouldShowCampaignPopup: Bool) //MM-32778 show campaign pop up when
    func didDismissReview()
}

class OrderReviewViewController: MmViewController,RatingCellDelegate,MerchantReviewCellDelegate, UITextFieldDelegate, UITextViewDelegate, ImagePickerManagerDelegate, PlatformQuestionCellDelegate {
    
    private final let DefaultCellID = "DefaultCellID"
    
    private final let ImageMaxWidth: CGFloat = 500
    private final let DefaultRating = 5
    
    private var quantityCell: QuantityCell?
    private var uploadPhotoCell: UploadPhotoCell?
    private var activeTextView: UITextView?
    private var imagePickerManager: ImagePickerManager?
    
    var order: Order? {
        didSet{
            self.orderItems = order?.orderItems ?? []
        }
    }
    
    private var orderItems = [OrderItem]()
    weak var delegate: OrderReviewViewControllerDelegate?
    
    private var reviewImages = [UIImage]()
    private var reviewDataSection = [ReviewData]()
    private var reviewDataSections = [Any]()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        self.navigationController?.isNavigationBarHidden = false
        self.title = String.localize("LB_CA_OMS_REVIEW_WRITE")
        
        setupDismissKeyboardGesture()

        createSubViews()
        self.createBackButton(.crossSmall)
        self.createRightButton(String.localize("LB_CA_OMS_REVIEW_POST"), action: #selector(confirm))
    }
    
    override func backButtonClicked(_ button: UIButton) {
        self.dismiss(button)
    }

    private func createRightBarItem() {
        let closeButton = UIButton(type: .custom)
        closeButton.setImage(UIImage(named: "icon_order_refund_cancel"), for: UIControlState())
        closeButton.frame = CGRect(x: view.width - Constants.Value.BackButtonWidth, y: 0, width: Constants.Value.BackButtonWidth, height: Constants.Value.BackButtonHeight)
        closeButton.addTarget(self, action: #selector(dismiss(_:)), for: .touchUpInside)
        
        self.navigationItem.rightBarButtonItem = UIBarButtonItem(customView: closeButton)
    }
    
    private func createSubViews() {
        collectionView.backgroundColor = UIColor.backgroundGray()
        collectionView.register(UICollectionViewCell.self, forCellWithReuseIdentifier: DefaultCellID)
        collectionView.register(OrderItemCell.self, forCellWithReuseIdentifier: OrderItemCell.CellIdentifier)
        collectionView.register(AfterSalesDescriptionCell.self, forCellWithReuseIdentifier: AfterSalesDescriptionCell.CellIdentifier)
        collectionView.register(UploadPhotoCell.self, forCellWithReuseIdentifier: UploadPhotoCell.CellIdentifier)
        collectionView.register(MerchantReviewCollectionCell.self, forCellWithReuseIdentifier: MerchantReviewCollectionCell.CellIdentifier)
        collectionView.register(RatingCollectionCell.self, forCellWithReuseIdentifier: RatingCollectionCell.CellIdentifier)
        collectionView.register(PlatformQuestionCell.self, forCellWithReuseIdentifier: PlatformQuestionCell.CellIdentifier)
        
        //nps = net promoter score
        var npsSection = [NPSData]()
        npsSection.append(NPSData())
        self.reviewDataSections.append(npsSection as Any)
        
        for orderItem in self.orderItems {
            var reviewDataList = [ReviewData]()
            
            let productItem = ReviewData(title: nil, cellHeight: 140, hasBorder: true, reuseIdentifier: OrderItemCell.CellIdentifier, orderItem: orderItem)
            productItem.dataType = .productItem
            reviewDataList.append(productItem)
            
            let ratingRow = ReviewData(title: nil, cellHeight: RatingCollectionCell.DefaultHeight, hasBorder: true, reuseIdentifier: RatingCollectionCell.CellIdentifier, orderItem: nil)
            ratingRow.dataType = .rating
            reviewDataList.append(ratingRow)
            
            let description = ReviewData(title: nil, cellHeight: 90, hasBorder: true, reuseIdentifier: AfterSalesDescriptionCell.CellIdentifier, orderItem: orderItem)
            description.dataType = .description
            reviewDataList.append(description)
            
            let photo = ReviewData(title: String.localize("LB_CA_MAX_PHOTO"), cellHeight: 130, hasBorder: true, reuseIdentifier: UploadPhotoCell.CellIdentifier, orderItem: orderItem)
            photo.dataType = .photo
            reviewDataList.append(photo)
            
            self.reviewDataSections.append(reviewDataList as Any)
        }
        
        var merchantReviewSections = [MerchantReviewData]()
        merchantReviewSections.append(MerchantReviewData(title: nil, cellHeight: MerchantReviewCollectionCell.DefaultHeight, hasBorder: true, reuseIdentifier: MerchantReviewCollectionCell.CellIdentifier, order: self.order))
        self.reviewDataSections.append(merchantReviewSections as Any)
        
        collectionView.frame = CGRect(x: collectionView.x, y: collectionView.y + 20, width: collectionView.width, height: collectionView.height - 20)
    }
    
    // MARK: - Process Data
    
    private func isValidRatingData(isShowDialogError isShow: Bool = true) -> Bool {
        for index in 0 ..< self.reviewDataSections.count {
            if let reviewDataSection = reviewDataSections[index] as? [NPSData], reviewDataSection.count > 0 && reviewDataSection[0].ratingValue <= 0 {
                if isShow {
                    self.showErrorAlert(String.localize("LB_CA_REVIEW_NPS_MISSING"))
                }
                return false
            }
        }
        
        return true
    }
    
    private func createReview() -> Promise<Bool> {
        return Promise { fulfill, reject in
            var reviewSkus: [ReviewService.ReviewSku] = []
            
            var productDescriptionRating = DefaultRating
            var serviceRating = DefaultRating
            var logisticsRating = DefaultRating
            var npsRating = 0
            var shouldShowCampaignPopup = false //MM-32778 Only show the pop up when user is given 4 or 5 stars review of the product
            
            if self.reviewDataSections.count > 1 {
                for index in 0..<self.reviewDataSections.count {
                    if let reviewDataSection = reviewDataSections[index] as? [ReviewData] {
                        var reviewSku = ReviewService.ReviewSku()
                        
                         let productData: ReviewData = reviewDataSection[ReviewData.ReviewItemType.productItem.rawValue]
                            if let orderItem = productData.orderItem {
                                reviewSku.skuId = "\(orderItem.skuId)"
                            }
                        
                        
                        let ratingData: ReviewData = reviewDataSection[ReviewData.ReviewItemType.rating.rawValue]
                            reviewSku.rating = ratingData.ratingValue
                            if (ratingData.ratingValue >= 4) {
                                shouldShowCampaignPopup = true
                            }
                        
                        
                         let descriptionData: ReviewData = reviewDataSection[ReviewData.ReviewItemType.description.rawValue]
                            if !descriptionData.reviewDescription.isEmpty {
                                reviewSku.description = descriptionData.reviewDescription
                            } else {
                                reviewSku.description = String.localize("LB_CA_PROD_REVIEW_CONTENT_DEFAULT")
                            }
                       
                        
                       let imagesData: ReviewData = reviewDataSection[ReviewData.ReviewItemType.photo.rawValue]
                            if let reviewImages = imagesData.reviewImages{
                                reviewSku.images = reviewImages
                            }
                        
                        
                        reviewSkus.append(reviewSku)
                    } else if let reviewDataSection = reviewDataSections[index] as? [MerchantReviewData] {
                        let merchantReviewData: MerchantReviewData = reviewDataSection[0]
                            productDescriptionRating = merchantReviewData.productDescriptionRating
                            serviceRating = merchantReviewData.serviceRating
                            logisticsRating = merchantReviewData.logisticsRating
                        
                    } else if let reviewDataSection = reviewDataSections[index] as? [NPSData] {
                        if reviewDataSection.count > 0 {
                            npsRating = reviewDataSection[0].ratingValue
                        }
                    }
                }
            }
            if let shipment = self.order?.orderShipments?.first {
                ReviewService.createReview(orderKey: (shipment.orderShipmentKey), reviewSkus: reviewSkus, productDescriptionRating: productDescriptionRating, serviceRating: serviceRating, logisticsRating: logisticsRating, npsRating: npsRating, success: { [weak self] (response) -> Void in
                    if let strongSelf = self {
                        if response.result.isSuccess {
                            if response.response?.statusCode == 200 {
                                fulfill(shouldShowCampaignPopup)
                            } else {
                                strongSelf.handleApiResponseError(response, reject: reject)
                            }
                        } else {
                            reject(response.result.error!)
                        }
                    }
                    }, failure: { (errorType) in
                        
                })
            }
            
        }
    }
    
    // MARK: Action
    
    @objc func confirm() {
        view.endEditing(true)
        
        for index in 0 ..< self.reviewDataSections.count {
            if let reviewDataSection = reviewDataSections[index] as? [NPSData], reviewDataSection.count > 0 && reviewDataSection[0].ratingValue <= 0 {
                
                Alert.alert(self, title: "", message: String.localize("LB_CA_REVIEW_NPS_MISSING"), okActionComplete: {
                    self.submitReviewData()
                    }, cancelActionComplete: { 
                        
                    })
                
                return
            }
        }
        
        submitReviewData()
    }
    
    func submitReviewData() {
        
        showLoading()
        firstly {
            return self.createReview()
            }.then { (shouldShowCampaignPopup) -> Void in
                self.dismiss(animated: true, completion: { [weak self] in
                    if let strongSelf = self {
                        strongSelf.delegate?.didSubmitReview(isSuccess: true, shouldShowCampaignPopup: shouldShowCampaignPopup)
                        strongSelf.delegate?.didDismissReview()
                    }
                })
            }.always {
                self.stopLoading()
            }.catch { _ -> Void in
                Log.error("error")
        }
    }
    
    @objc func dismiss(_ sender: UIButton) {
        self.delegate?.didDismissReview()
        self.dismiss(animated: true, completion: nil)
    }
    
    func addPhoto() {
        if imagePickerManager == nil {
            imagePickerManager = ImagePickerManager(viewController: self, withDelegate: self)
        }
        
        imagePickerManager?.presentDefaultActionSheet(preferredCameraDevice: .rear)
    }
    
    // MARK: Observer
    
    override func keyboardWillShowNotification(_ notification: NSNotification) {
        super.keyboardWillShowNotification(notification)
        
        if let keyboardInfoKey = notification.userInfo![UIKeyboardFrameEndUserInfoKey] {
            let contentInsets = UIEdgeInsets(top: 0.0, left: 0.0, bottom: (keyboardInfoKey as! NSValue).cgRectValue.size.height, right: 0.0)
            
            collectionView.contentInset = contentInsets
            collectionView.scrollIndicatorInsets = contentInsets
            
            if let activeTextView = self.activeTextView {
                let rect = collectionView.convert(activeTextView.bounds, from: activeTextView)
                collectionView.scrollRectToVisible(rect, animated: false)
            }
        }
    }
    
    override func keyboardWillHideNotification(_ notification: NSNotification) {
        super.keyboardWillHideNotification(notification)
        
        collectionView.contentInset = UIEdgeInsets.zero
        collectionView.scrollIndicatorInsets = UIEdgeInsets.zero
        collectionView.reloadData()
    }
    
    // MARK: CollectionView
    
    func numberOfSections(in collectionView: UICollectionView) -> Int {
        return reviewDataSections.count
    }
    
    override func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return (reviewDataSections[section] as AnyObject).count
    }
    
    override func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        
        if reviewDataSections[indexPath.section] is [NPSData] {
        
            if let cell = collectionView.dequeueReusableCell(withReuseIdentifier: PlatformQuestionCell.CellIdentifier, for: indexPath) as? PlatformQuestionCell {
                
                cell.delegate = self
                cell.indexPath = indexPath
                
                return cell
            }
        }
        
        if let reviewDataSection = reviewDataSections[indexPath.section] as? [MerchantReviewData] {
            let merchantReviewData = reviewDataSection[indexPath.row]
            
            if let reuseIdentifier = merchantReviewData.reuseIdentifier{
                let cell = collectionView.dequeueReusableCell(withReuseIdentifier: reuseIdentifier, for: indexPath)
                
                switch reuseIdentifier {
                case MerchantReviewCollectionCell.CellIdentifier:
                    let itemCell = cell as! MerchantReviewCollectionCell
                    itemCell.data = merchantReviewData
                    itemCell.delegate = self
                    return itemCell
                default:
                    break
                }
            }
        }
        
        if let reviewDataSection = reviewDataSections[indexPath.section] as? [ReviewData] {
            let reviewData = reviewDataSection[indexPath.row]
            
            if let reuseIdentifier = reviewData.reuseIdentifier {
                let cell = collectionView.dequeueReusableCell(withReuseIdentifier: reuseIdentifier, for: indexPath)
                
                switch reuseIdentifier {
                case OrderItemCell.CellIdentifier:
                    let itemCell = cell as! OrderItemCell
                    itemCell.data = reviewData.orderItem
                    itemCell.updateLayout()
                    itemCell.formatToSecondLayout()
                    
                    return itemCell
                case RatingCollectionCell.CellIdentifier:
                    let itemCell = cell as! RatingCollectionCell
                    itemCell.data = reviewData
                    itemCell.delegate = self
                    return itemCell
                case AfterSalesDescriptionCell.CellIdentifier:
                    let itemCell = cell as! AfterSalesDescriptionCell
                    
                    itemCell.characterLimit = Constants.CharacterLimit.ReviewDescription
                    itemCell.characterCountLabel.isHidden = false
                    
                    itemCell.descriptionTextView.tag = indexPath.section
                    itemCell.setDescriptionText(reviewData.reviewDescription)
                    
                    itemCell.textViewBeginEditing = {
                        collectionView.scrollToItem(at: indexPath, at: .centeredVertically, animated: true)
                    }
                    
                    itemCell.textViewEndEditing = {
                        reviewData.reviewDescription = itemCell.getDescriptionText()
                    }
                    
                    return itemCell
                case UploadPhotoCell.CellIdentifier:
                    let itemCell = cell as! UploadPhotoCell
                    
                    itemCell.imageLimit = Constants.ImageLimit.Review
                    itemCell.showBorder(false)
                    itemCell.tag = indexPath.section
                    itemCell.removeAllPhotos()
                    
                    if let reviewImages = reviewData.reviewImages {
                        for image in reviewImages {
                            itemCell.addPhoto(image, imageKey: "")
                        }
                    }
                    
                    itemCell.cameraTappedHandler = { [weak self] in
                        
                        if let strongSelf = self {
                            strongSelf.uploadPhotoCell = itemCell
                            strongSelf.addPhoto()
                        }
                    }
                    
                    itemCell.deletePhotoTappedHandler = { [weak self] (image, index) in
                        if let strongSelf = self {
                            reviewData.reviewImages = strongSelf.getPhotoImages(uploadPhotoCell: itemCell)
                        }
                    }
                    
                    return itemCell
                default:
                    break
                }
            }
        }
        
        return defaultCell(collectionView, cellForItemAt: indexPath)
    }
    
    private func defaultCell(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        return collectionView.dequeueReusableCell(withReuseIdentifier: DefaultCellID, for: indexPath)
    }
    
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, insetForSectionAt section: Int) -> UIEdgeInsets {
        if section == 0 {
            return UIEdgeInsets.zero
        }
        
        return UIEdgeInsets(top: 10, left: 0, bottom: 10, right: 0)
    }
    
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, referenceSizeForHeaderInSection section: Int) -> CGSize {
        return CGSize.zero
    }
    
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, minimumInteritemSpacingForSectionAt section: Int) -> CGFloat {
        return 0.0
    }
    
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, minimumLineSpacingForSectionAt section: Int) -> CGFloat{
        return 0.0
    }
    
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, sizeForItemAt indexPath: IndexPath) -> CGSize {
        if let reviewDataSection = reviewDataSections[indexPath.section] as? [ReviewData] {
            return CGSize(width: view.width, height: reviewDataSection[indexPath.row].cellHeight)
        } else if let reviewDataSection = reviewDataSections[indexPath.section] as? [MerchantReviewData] {
            return CGSize(width: view.width, height: reviewDataSection[indexPath.row].cellHeight)
        } else if let _ = reviewDataSections[indexPath.section] as? [NPSData] {
            return PlatformQuestionCell.getSizeCell(view.width)
        } else {
            return CGSize.zero
        }
    }
    
    // MARK: - Platform Rating Delegate
    
    func ratingChanged(_ indexPath: IndexPath?, value: Int) {
        
        if let indexPath = indexPath, reviewDataSections.count > indexPath.section {
            if let npsSection = reviewDataSections[indexPath.section] as? [NPSData], npsSection.count > 0 {
                npsSection[0].ratingValue = value
            }
        }
    }
    
    // MARK: - Picker View Delegate
    
    func numberOfComponentsInPickerView(_ pickerView: UIPickerView) -> Int {
        return 1
    }
    
    // ImagePickerManagerDelegate
    
    func didPickImage(_ image: UIImage!) {
        if let uploadPhotoCell = uploadPhotoCell{
            if let reviewDataSection = reviewDataSections[uploadPhotoCell.tag] as? [ReviewData]{
                
                let reviewData: ReviewData = reviewDataSection[ReviewData.ReviewItemType.photo.rawValue] 
                    if reviewData.reviewImages == nil {
                        reviewData.reviewImages = [UIImage]()
                    }
                    
                    if let resizeImage = image.resize(CGSize(width: ImageMaxWidth, height: ImageMaxWidth / image.size.width * image.size.height)) {
                        reviewData.reviewImages!.append(resizeImage)
                    } else {
                        reviewData.reviewImages!.append(image)
                    }
                
            }
            
            uploadPhotoCell.addPhoto(image, imageKey: "")
        }
    }
   
    // MARK: - Text Field Delegate
    
    func textFieldDidBeginEditing(_ textField: UITextField) {
        
    }
    
    //MARK: - Merchant Review Cell Delgate
    func didTouchMerchantRatingView() {
        collectionView.isScrollEnabled = false
    }
    
    func didFinishTouchingMerchantRatingView() {
        collectionView.isScrollEnabled = true
    }
    
    //MARK: - Rating Cell Delegate 
    func didTouchRatingView() {
        collectionView.isScrollEnabled = false
    }
    
    func didFinishTouchingRatingView() {
        collectionView.isScrollEnabled = true
    }
    
    // MARK: - Helpers
    
    private func getPhotoImages(uploadPhotoCell: UploadPhotoCell) -> [UIImage] {
        var photoImages = [UIImage]()
        for reviewImageView in (uploadPhotoCell.getPhotos()){
            let imageKey = reviewImageView.imageKey ?? ""
            if imageKey.isEmpty {
                if let image = reviewImageView.imageView.image{
                    if let resizeImage = image.resize(CGSize(width: ImageMaxWidth, height: ImageMaxWidth / image.size.width * image.size.height)) {
                        photoImages.append(resizeImage)
                    } else {
                        photoImages.append(image)
                    }
                }
            }
        }
        
        return photoImages
    }
    
}

//MM-29317: NPS = net promoter score
internal class NPSData {
    var ratingValue: Int = 0
}
