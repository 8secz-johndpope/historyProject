//
//  BannerCell.swift
//  merchant-ios
//
//  Created by Gam Bogo on 5/13/16.
//  Copyright © 2016 WWE & CO. All rights reserved.
//

import Foundation

protocol BannerCellDelegate: NSObjectProtocol {
    func didSelectBanner(_ banner: Banner)
}

class BannerCell: UICollectionViewCell, UICollectionViewDataSource, UICollectionViewDelegate, UICollectionViewDelegateFlowLayout {
    
    static let CellIdentifier = "BannerCellID"
    
    private var bannerCollectionViewHeight: CGFloat = 0
    private var bannerCollectionView: UICollectionView!
    private var pageControl: UIPageControl!
    private var currentPage = 0
    private var timer: Timer?
	
	private var overlay = UIImageView()
	private let placeholder = UIImageView(image: UIImage(named: "tile_placeholder"))
    var bottomPadding = CGFloat(10)
    
    
    weak var delegate: BannerCellDelegate?
    
    var bannerList = [Banner]() {
        didSet {
            if bannerList.count > 1 {
                pageControl.numberOfPages = bannerList.count
                pageControl.isHidden = false
                isAutoScroll = true
            } else {
                pageControl.isHidden = true
                isAutoScroll = false
            }
            
            self.bannerCollectionView.reloadData()
        }
    }
    
    var positionComponent = "HeroBanner"
    var positionLocation = "Newsfeed-Home-BlackZone"
    var sourceType: AnalyticsActionRecord.ActionElement = .HeroBanner
    var impressionVariantRef: String?
    var isShoppingCartBanner = false
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        setupFeaturedCollectionView()
		overlay.image = UIImage(named: "overlay")
        contentView.addSubview(placeholder)
        contentView.addSubview(bannerCollectionView)
		contentView.addSubview(overlay)
        contentView.addSubview(pageControl)
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override func layoutSubviews() {
        super.layoutSubviews()
        bannerCollectionViewHeight = frame.size.height
        bannerCollectionView.frame = CGRect(x: 0, y: 0, width: frame.width, height: bannerCollectionViewHeight)
        
        let pageControlHeight: CGFloat = 30
        pageControl.frame = CGRect(x: 0, y: bannerCollectionViewHeight - pageControlHeight, width: frame.width, height: pageControlHeight)
        pageControl.center = CGPoint(x: bannerCollectionView.center.x, y: bannerCollectionView.bounds.maxY - bottomPadding)
        let overlayFrame = CGRect(x: 0, y: 0, width: frame.size.width, height: frame.size.width / 750 * 160)
        overlay.frame = overlayFrame
        
        placeholder.center = CGPoint(x: self.frame.size.width / 2, y: self.frame.size.height/2)
    }
    
    // MARK: Views
    func setupFeaturedCollectionView() {
        let layout = UICollectionViewFlowLayout()
        layout.scrollDirection = .horizontal
        layout.headerReferenceSize = CGSize.zero
        layout.footerReferenceSize = CGSize.zero
        layout.sectionInset = UIEdgeInsets.zero
        layout.minimumInteritemSpacing = 0
        layout.minimumLineSpacing = 0
        layout.itemSize = CGSize(width: frame.width, height: bannerCollectionViewHeight)
        
        bannerCollectionView = UICollectionView(frame: CGRect(x: 0, y: 0, width: frame.width, height: bannerCollectionViewHeight), collectionViewLayout: layout)
        bannerCollectionView.contentInset = UIEdgeInsets.zero
        bannerCollectionView.isPagingEnabled = true
        self.backgroundColor = UIColor.primary2()
        bannerCollectionView.backgroundColor = UIColor.clear
        
        
        bannerCollectionView.showsHorizontalScrollIndicator = false
        bannerCollectionView.dataSource = self
        bannerCollectionView.delegate = self
        bannerCollectionView.register(FeatureCollectionCell.self, forCellWithReuseIdentifier: FeatureCollectionCell.CellIdentifier)
        
        let pageControlHeight: CGFloat = 30
       
        pageControl = UIPageControl(frame: CGRect(x: 0, y: bannerCollectionViewHeight - pageControlHeight, width: frame.width, height: pageControlHeight))
        pageControl.isHidden = false
        pageControl.currentPage = 0
        pageControl.numberOfPages = 0
        pageControl.tintColor = UIColor.primary1()
        pageControl.pageIndicatorTintColor = UIColor.primary2()
        pageControl.currentPageIndicatorTintColor = UIColor.primary1()
        pageControl.center = CGPoint(x: bannerCollectionView.center.x, y: bannerCollectionView.bounds.maxY - bottomPadding)
    }
    
    var isAutoScroll = false {
        didSet {
            if isAutoScroll {
                if timer != nil {
                    timer?.invalidate()
                    timer = nil
                }
                
                //Should animation update banner when more than 1 banner
                if bannerList.count > 1 {
                    timer = Timer.scheduledTimer(timeInterval: 5.0, target: self, selector: #selector(BannerCell.updatePage), userInfo: nil, repeats: true)
                }
            } else {
                timer?.invalidate()
                timer = nil
            }
        }
    }
    
    @objc func updatePage() {
        currentPage += 1
        
        if currentPage >= bannerList.count {
            currentPage = 0
        }
        
        if currentPage < pageControl.numberOfPages{
            pageControl.currentPage = currentPage
            if currentPage < bannerCollectionView.numberOfItems(inSection: 0){
                bannerCollectionView.scrollToItem(at: IndexPath(row: currentPage, section: 0), at: .left, animated: true)
            }
        }
    }
    
    func reset() {
        if pageControl != nil && bannerCollectionView != nil && bannerCollectionView.numberOfItems(inSection: 0) > 0 {
            currentPage = 0
            pageControl.currentPage = currentPage
            bannerCollectionView.scrollToItem(at: IndexPath(row: currentPage, section: 0), at: .left, animated: false)
        }
    }
    
    func showOverlay(_ isShow: Bool = true) {
        overlay.isHidden = !isShow
    }
    
    func hidePageControl(_ isHide: Bool = true) {
        self.pageControl.isHidden = isHide
    }
    
    func getCurrentPage() -> Int {
        return currentPage
    }
    // MARK: - Scroll View Delegate
   
    func scrollViewWillBeginDragging(_ scrollView: UIScrollView) {
        isAutoScroll = false
    }
    
    func scrollViewDidEndDragging(_ scrollView: UIScrollView, willDecelerate decelerate: Bool) {
        isAutoScroll = true
    }
    
    func scrollViewDidEndDecelerating(_ scrollView: UIScrollView) {
        let page = Int(ceil(bannerCollectionView.contentOffset.x / bannerCollectionView.width))
        if page != currentPage &&  page < bannerList.count {
			
			if currentPage >= bannerList.count {
				currentPage = page
			}
			
            let currentBanner = bannerList[currentPage]
            let banner = bannerList[page]
            let indexPath = IndexPath(row: page, section: 0)
            let cell = bannerCollectionView.cellForItem(at: indexPath)
            
            //record action
            cell?.recordAction(.Slide, sourceRef: "\(currentBanner.bannerId)", sourceType: .HeroBanner, targetRef: "\(banner.bannerId)", targetType: .Banner)
            currentPage = page
            pageControl.currentPage = currentPage
        }

    }
    
    // MARK: - Collection View Data Source methods
    
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, insetForSectionAt section: Int) -> UIEdgeInsets {
        return UIEdgeInsets.zero
    }
    
    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        let cell = collectionView.dequeueReusableCell(withReuseIdentifier: FeatureCollectionCell.CellIdentifier, for: indexPath) as! FeatureCollectionCell
		
        let bannerList: [Banner] = self.bannerList 
            let banner = bannerList[indexPath.row]
            cell.setImageRoundedCorners(banner.bannerImage, imageCategory: .banner)
            if let viewKey = self.analyticsViewKey {
                cell.initAnalytics(withViewKey: viewKey, impressionKey: AnalyticsManager.sharedManager.recordImpression(impressionRef: "\(banner.bannerKey)", impressionType: "Banner", impressionVariantRef: impressionVariantRef, impressionDisplayName: banner.bannerName, positionComponent: positionComponent, positionIndex: indexPath.row + 1, positionLocation: positionLocation, viewKey: viewKey))
            }
        
        return cell
        
    }
    
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, referenceSizeForHeaderInSection section: Int) -> CGSize {
        return CGSize.zero
    }
    
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, minimumInteritemSpacingForSectionAt section: Int) -> CGFloat {
        return 0.0
    }
    
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, minimumLineSpacingForSectionAt section: Int) -> CGFloat {
        return 0.0
    }
    
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, sizeForItemAt indexPath: IndexPath) -> CGSize {
        return bannerCollectionView.bounds.size
    }
    
    func numberOfSections(in collectionView: UICollectionView) -> Int {
        return 1
    }
    
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return self.bannerList.count
    }
    
    func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        let bannerList: [Banner] = self.bannerList 
            let banner = bannerList[indexPath.row]
            delegate?.didSelectBanner(banner)
            
            //record action
            if let cell = collectionView.cellForItem(at: indexPath) {
                if !(impressionVariantRef ?? "").isEmpty || isShoppingCartBanner{
                    cell.recordAction( .Tap,sourceRef: "\(banner.bannerName)",sourceType: .HeroBanner, targetRef: banner.link, targetType: .URL)
                } else {
                    
                    var sourceReference = ""
                    var targetType: AnalyticsActionRecord.ActionElement = .View
                    var targetReference = ""
                    
                    if positionLocation == "MyProfile" {
                        //Analytics for Profile Page
                        sourceReference = "MyProfile"
                        targetType = .URL
                        targetReference = banner.link
                        
                    } else if positionLocation == "Newsfeed-Home-User" {
                        sourceReference = banner.bannerKey
                        targetType = .URL
                        targetReference = banner.link
                        sourceType = .Banner
                    }else {
                        
                        sourceReference = "\(banner.bannerName)"
                        targetReference = "BannerDetails"
                    }
                    
                    cell.recordAction(
                        .Tap,
                        sourceRef: sourceReference,
                        sourceType: sourceType,
                        targetRef: targetReference,
                        targetType: targetType
                    )
                }
                
            }
        
    }
}
