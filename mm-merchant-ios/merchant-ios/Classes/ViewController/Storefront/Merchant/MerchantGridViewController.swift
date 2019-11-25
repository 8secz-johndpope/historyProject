//
//  MerchantGridViewController.swift
//  merchant-ios
//
//  Created by HungPM on 5/23/17.
//  Copyright © 2017 WWE & CO. All rights reserved.
//

import Foundation
import PromiseKit
import ObjectMapper

class MerchantGridViewController: MmViewController {
    private let navigationSearchHeight:CGFloat = 35
    private static let MerchantGridCellIdentifier = "MerchantGridCell"
    private static let LoadingCellIdentifier = "LoadingCell"
    private let EgdeInset = UIEdgeInsets(top: 10, left: 10, bottom: 10, right: 10)
    private let Spacing = CGFloat(5)
    private var merchantList = [Merchant]()
    private var pageNo = 1
    
    //MARK:- life cycle
    override func viewDidLoad() {
        super.viewDidLoad()
        
        self.title = ""
        
        self.automaticallyAdjustsScrollViewInsets = true
        
        setupCollectionView()
        
        loadMerchant()
        
        initAnalyticsViewRecord(viewParameters: "RedZone", viewLocation: "AllMerchants", viewType: "Merchant")
        
        setupNavigationBarButton()
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
    }
    
    //MARK:- service response
    func loadMerchant() {
        showLoading()
        MerchantService.fetchMerchantsIfNeeded(.featuredRedZone).then { (merchants) -> Void in
            self.merchantList = merchants
            self.collectionView.reloadData()
            }.always {
                self.stopLoading()
            }.catch { (error) in
        }
    }
    
    //MARK:- UICollectionViewDataSource
    override func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        
        return merchantList.count
    }
    
    override func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {

        let cell = collectionView.dequeueReusableCell(withReuseIdentifier: MerchantGridViewController.MerchantGridCellIdentifier, for: indexPath) as! MerchantGridCell
        
        let merchant = merchantList[indexPath.item]
        cell.imageView.mm_setImageWithURL(ImageURLFactory.URLSize512(merchant.largeLogoImage, category: .merchant), placeholderImage: UIImage(named: "brand_placeholder"), contentMode: .scaleAspectFit)
        
        //analytic
        let impressionKey = recordImpression(impressionRef: "\(merchant.merchantId)", impressionType: "Merchant", impressionVariantRef: "RedZone", impressionDisplayName: merchant.merchantName, merchantCode: merchant.merchantCode, positionComponent: "MerchantListing", positionIndex: indexPath.item + 1, positionLocation: "AllMerchants")
        cell.initAnalytics(withViewKey: analyticsViewRecord.viewKey, impressionKey: impressionKey)
        
        return cell
    }
    
    //MARK:- UICollectionViewDelegateFlowLayout
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, minimumLineSpacingForSectionAt section: Int) -> CGFloat {
        return Spacing
    }
    
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, minimumInteritemSpacingForSectionAt section: Int) -> CGFloat {
        return Spacing
    }
    
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, insetForSectionAt section: Int) -> UIEdgeInsets {
        return EgdeInset
    }
    
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, sizeForItemAt indexPath: IndexPath) -> CGSize {
        let width = (collectionView.width - EgdeInset.left - EgdeInset.right - Spacing) / 2
        return CGSize(width: width, height: width)
    }
    
    //MARK:- UICollectionDelegate
    func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        if let merchant = merchantList.get(indexPath.item) {
            //analytic
            if let cell = collectionView.cellForItem(at: indexPath) {
                cell.recordAction(.Tap, sourceRef: "\(merchant.merchantId)", sourceType: .Merchant, targetRef: "MPP", targetType: .View)
            }
            
            Navigator.shared.dopen(Navigator.mymm.website_merchant_merchantId + "\(merchant.merchantId)")
    
        }
    }
    
    //MARK: - private methods
    func setupCollectionView() {
        collectionView.frame = self.view.bounds
        collectionView.register(UINib(nibName: MerchantGridViewController.MerchantGridCellIdentifier, bundle: nil), forCellWithReuseIdentifier: MerchantGridViewController.MerchantGridCellIdentifier)
        collectionView.register(LoadingCollectionViewCell.self, forCellWithReuseIdentifier: MerchantGridViewController.LoadingCellIdentifier)
    }
    func setupNavigationBarButton() {
        if let navigationBar = self.navigationController?.navigationBar{
            let customView = UIView(frame: CGRect(x: 0, y: 0, width: navigationBar.width * 0.7, height: navigationSearchHeight))
            customView.layer.cornerRadius = 4
            customView.layer.masksToBounds = true
            customView.backgroundColor = UIColor.imagePlaceholder()
            customView.addGestureRecognizer(UITapGestureRecognizer(target: self, action: #selector(searchButtonTapped)))
            
            
            searchButton.frame =  CGRect(x: (customView.width - searchButton.width) / 2, y: (navigationSearchHeight - searchButton.height) / 2, width: searchButton.width, height:searchButton.height)
            customView.addSubview(searchButton)

            setupNavigationBarCartButton()
            buttonCart!.addTarget(self, action: #selector(goToShoppingCart), for: .touchUpInside)
            let historires = Context.getHistory()
            if historires.count > 0 {
                searchButton.setTitle(historires.first, for: .normal)
            } else if let searchTerms = CacheManager.sharedManager.hotSearchTerms, searchTerms.count > 0 {
                searchButton.setTitle(searchTerms.first?.searchTerm, for: .normal)
            }

            self.navigationItem.leftBarButtonItems = [UIBarButtonItem(customView: backButton),UIBarButtonItem(customView: customView)]
            self.navigationItem.rightBarButtonItems = [UIBarButtonItem(customView: buttonCart!)]
        }
    }

    //MARK: - event response
    @objc func popViewController() {
        self.navigationController?.popViewController(animated: true)
    }
    
    @objc func searchButtonTapped() {
        let searchViewController = ProductListSearchViewController()
        navigationController?.push(searchViewController, animated: false)
    }
    
    //MARK: - lazy
    lazy var backButton:UIButton = {
        let backButton: UIButton = UIButton()
        backButton.setImage(UIImage(named: "back_grey"), for: .normal)
        backButton.frame = CGRect(x: 0, y: 0, width: 30, height: 25)
        backButton.contentEdgeInsets = UIEdgeInsets.init(top: 0, left: Constants.Value.BackButtonMarginLeft, bottom: 0, right: 0)
        backButton.addTarget(self, action: #selector(popViewController), for: .touchUpInside)
        return backButton
    }()
    lazy var searchButton:UIButton = {
        let searchButton = UIButton()
        searchButton.isUserInteractionEnabled = false
        searchButton.setTitle(String.localize("LB_CA_HOMEPAGE_SEARCH"), for: UIControlState.normal)
        searchButton.setImage(UIImage(named: "search"), for: UIControlState.normal)
        searchButton.titleLabel?.font = UIFont.systemFont(ofSize: 12)
        searchButton.setTitleColor(UIColor(hexString: "#BCBCBC"), for: UIControlState.normal)
        searchButton.setIconInLeftWithSpacing(6)
        searchButton.sizeToFit()
        return searchButton
    }()
}
