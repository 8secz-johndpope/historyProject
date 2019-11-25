//
//  CuratorPickViewController.swift
//  merchant-ios
//
//  Created by Koon Kit Chan on 5/2/2016.
//  Copyright © 2016 WWE & CO. All rights reserved.
//

import Foundation
import PromiseKit
import ObjectMapper

class MerchantPickViewController : MmViewController {
    var backgroundImageView : UIImageView!
    var merchants : [Merchant] = []
    var selectedMerchantsCount = 0
    var rowCentered = -1
    var distanceRatio = CGFloat(1)
    var fansLabel : FansLabel!
    var countLabel = UILabel()
    private let continueButton = UIButton()
    private var titleTextAttributes : [NSAttributedStringKey: Any]!
    private var navigationBGImage : UIImage!
    private var navigationShadowImage : UIImage!
    private var navigationTranslucent : Bool = false
    private var navigationBGColor : UIColor!
    private var isFakeNavigationBarHiden : Bool = false
    private final let CircleImageCellHeight : CGFloat = 60
    private final let CircleExpansion : CGFloat = 60
    private final let CircleWithPercent : CGFloat = 0.8
    private final let ContinueButtonHeight : CGFloat = 50
    private final let MinMerchantCount = 3
    private final let MarginLeft : CGFloat = 10
    private final let SpacingLine : CGFloat = 30
    private final let DefaultCuratorNumber : Int = 5
    private final let collectionViewWidth : CGFloat = 280
    
    var scrollPosition : UICollectionViewScrollPosition = UICollectionViewScrollPosition.centeredVertically
    override func viewDidLoad() {
        super.viewDidLoad()
        
        backgroundImageView = UIImageView(frame: self.view.frame)
        backgroundImageView.image = UIImage(named: "curator_bg")
        self.view.insertSubview(backgroundImageView, belowSubview : collectionView)
        collectionView.backgroundColor = UIColor.clear
        collectionView.frame = CGRect(x: self.view.frame.midX - collectionViewWidth / 2 , y: 50, width: collectionViewWidth , height: self.view.frame.height - 100)
        collectionView.center = self.view.center
        collectionView.alwaysBounceVertical = true
        collectionView.showsVerticalScrollIndicator = false
        collectionView.register(CircleImageCell.self, forCellWithReuseIdentifier: "CircleImageCell")
        
        setupLabels()
        setupContinueButton()
        couldContinue(false)
//        loadMerchant()
        createBackButton(.whiteColor)
    }
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        self.title = String.localize("LB_CA_BRANDS_FOLLOW")
        self.navigationController?.setNavigationBarHidden(false, animated: false)
        self.backupNavigationBar()
        self.setupNavigationBar()
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        self.revertNavigationBar()
    }
    
    //MARK: Navigation Bar methods
    func backupNavigationBar() {
        if let navigationController = self.navigationController {
            titleTextAttributes = navigationController.navigationBar.titleTextAttributes!
            navigationBGImage = navigationController.navigationBar.backgroundImage(for: UIBarMetrics.default)
            navigationShadowImage = navigationController.navigationBar.shadowImage
            navigationTranslucent = navigationController.navigationBar.isTranslucent
            navigationBGColor = navigationController.view.backgroundColor
        }
    }
    func revertNavigationBar() {
        if let navigationController = self.navigationController {
            navigationController.navigationBar.titleTextAttributes = titleTextAttributes
            navigationController.navigationBar.setBackgroundImage(navigationBGImage, for: UIBarMetrics.default)
            navigationController.navigationBar.shadowImage = navigationShadowImage
            navigationController.navigationBar.isTranslucent = navigationTranslucent
            navigationController.view.backgroundColor = navigationBGColor
        }
//        if let navigationController = self.navigationController as? GKFadeNavigationController {
//            navigationController.setFakeViewHiden(isFakeNavigationBarHiden)
//        }
    }
    func setupNavigationBar() {
        if let navigationController = self.navigationController {
            navigationController.navigationBar.titleTextAttributes = [NSAttributedStringKey.foregroundColor : UIColor.white]
            navigationController.navigationBar.setBackgroundImage(UIImage(), for: UIBarMetrics.default)
            navigationController.navigationBar.shadowImage = UIImage()
            navigationController.navigationBar.isTranslucent = true
            navigationController.view.backgroundColor = UIColor.clear
        }
        self.navigationItem.setHidesBackButton(false, animated:false);
//        if let navigationBar = self.navigationController as? GKFadeNavigationController {
//            navigationBar.setFakeViewHiden(true)
//        }
    }
    
    func setupContinueButton(){
        continueButton.frame = CGRect(x: 0, y: self.view.bounds.maxY - ContinueButtonHeight, width: self.view.bounds.width, height: ContinueButtonHeight)
        continueButton.layer.backgroundColor = UIColor.primary1().cgColor
        continueButton.setTitle(String.localize("LB_CA_FOLLOW_CURATORS_CONT"), for: UIControlState())
        continueButton.addTarget(self, action: #selector(MerchantPickViewController.continueClicked), for: UIControlEvents.touchUpInside)
        self.view.addSubview(continueButton)
    }
    
    func setupLabels(){
        fansLabel = FansLabel(frame: CGRect(x: self.view.frame.midX + (CircleImageCellHeight + CircleExpansion) / 2 + 5, y: self.view.frame.midY - 20, width: self.view.frame.midX - (CircleImageCellHeight + CircleExpansion) / 2 , height: 60))
        self.fansLabel.bottomLabel.isHidden = true //Hide it temporary, will show again in future.
        self.view.insertSubview(fansLabel, aboveSubview: collectionView )
        countLabel.frame = CGRect(x: 0, y: 76, width: self.view.frame.width, height: 17)
        countLabel.formatSize(14)
        countLabel.textColor = UIColor.white
        countLabel.textAlignment = .center
        countLabel.backgroundColor = UIColor.clear
        countLabel.text = "\(String.localize("LB_CA_RECOMMENDED_MERCHANT_PREFIX"))0\(String.localize("LB_CA_RECOMMENDED_MERCHANT_PROFIX"))"
        self.view.insertSubview(countLabel, aboveSubview: collectionView )
        
        
    }
    
    func scrollToFirstItem () {
        self.collectionView.scrollToItem(at: IndexPath(item: 0, section: 0), at: .centeredVertically, animated: true)
    }
    
    //MARK: Promise Call
    @discardableResult
    func saveMerchant(_ merchants : [Merchant])-> Promise<Any> {
        return Promise{ fulfill, reject in
            FollowService.saveMerchant(merchants){
                [weak self] (response) in
                if let strongSelf = self {
                    if response.response?.statusCode == 200 {
                        
                        LoginManager.goToStorefront()
                        fulfill("OK")
                    } else {
                        strongSelf.handleError(response, animated: true)
                    }
                    
                }
            }
        }
    }
    //MARK: Collection View Delegates
    
    override func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        let cell = collectionView.dequeueReusableCell(withReuseIdentifier: "CircleImageCell", for: indexPath) as! CircleImageCell
        if (self.merchants.count > indexPath.row) {
            cell.setImage(self.merchants[indexPath.row].largeLogoImage, category: .merchant)
        }
        if indexPath.row == rowCentered {
            cell.imageView.alpha = 1.0
        } else {
            if indexPath.row == rowCentered + 1 || indexPath.row == rowCentered - 1 {
                cell.imageView.alpha = 0.6
            } else {
                if indexPath.row == rowCentered + 2 || indexPath.row == rowCentered - 2 {
                    cell.imageView.alpha = 0.3
                } else {
                    cell.imageView.alpha = 0.1
                    
                }
            }
        }
        cell.drawSelect(merchants[indexPath.row].isSelected,selecting: merchants[indexPath.row].isClicking)
        merchants[indexPath.row].isClicking = false
        return cell
    }
    
    func numberOfSections(in collectionView: UICollectionView) -> Int {
        return 1
    }
    
    override func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return self.merchants.count
    }
    
    
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, minimumLineSpacingForSectionAt section: Int) -> CGFloat{
        return SpacingLine
    }
    
    
    func collectionView(_ collectionView: UICollectionView,
        didSelectItemAt indexPath: IndexPath) {
            if indexPath.row != rowCentered {
                
                collectionView.scrollToItem(at: indexPath, at: UICollectionViewScrollPosition.centeredVertically , animated: true)
                
                if (indexPath.row < rowCentered) {
                    collectionView.scrollToItem(at: IndexPath(item: self.merchants.count - 1, section: 0), at: UICollectionViewScrollPosition.centeredVertically , animated: true)
                    collectionView.scrollToItem(at: indexPath, at: UICollectionViewScrollPosition.centeredVertically , animated: true)
                } else {
                    collectionView.scrollToItem(at: IndexPath(item: 0, section: 0), at: UICollectionViewScrollPosition.centeredVertically , animated: true)
                    collectionView.scrollToItem(at: indexPath, at: UICollectionViewScrollPosition.centeredVertically , animated: true)
                }
                
                collectionView.isScrollEnabled = false
                return;
                
            }
        
            merchants[indexPath.row].isSelected = !merchants[indexPath.row].isSelected
            if merchants[indexPath.row].isSelected {
                selectedMerchantsCount += 1
                merchants[indexPath.row].isClicking = true
            } else {
                selectedMerchantsCount -= 1
                merchants[indexPath.row].isClicking = false
            }
           // updateProgress()
            couldContinue(selectedMerchantsCount >= MinMerchantCount)
            self.reloadAllData()
    }
    
    func reloadAllData(){
        self.collectionView.reloadData()
        if rowCentered >= 0 {
            self.fansLabel.topLabel.text = merchants[rowCentered].merchantName
            self.fansLabel.midLabel.text = merchants[rowCentered].merchantNameInvariant
            self.fansLabel.bottomLabel.text = "\(String.localize("LB_CA_CURATORS_FOLLOWER_NO")) \(merchants[rowCentered].count * 9999)"
            
        }
        self.countLabel.text = "\(String.localize("LB_CA_RECOMMENDED_MERCHANT_PREFIX"))\(merchants.count)\(String.localize("LB_CA_RECOMMENDED_MERCHANT_PROFIX"))"
        
    }
    
    func scrollViewDidEndScrollingAnimation(_ scrollView: UIScrollView) {
        Log.debug("--------------: scrollViewDidEndScrollingAnimation $$$$$$$$$$$")
        if scrollPosition == UICollectionViewScrollPosition.bottom {
            Timer.scheduledTimer(timeInterval: 0.25, target: self, selector: #selector(self.stopScrolling), userInfo: nil, repeats: false)
        } else if scrollPosition == UICollectionViewScrollPosition.top {
            self.scrollViewDidEndDecelerating(scrollView)
        } else {
            Timer.scheduledTimer(timeInterval: 0.25, target: self, selector: #selector(self.stopScrolling), userInfo: nil, repeats: false)
        }
    }

    
    //MARK: Scroll View Method to control page control
    func scrollViewDidEndDecelerating(_ scrollView: UIScrollView) {
        
        Timer.scheduledTimer(timeInterval: 0.25, target: self, selector: #selector(self.stopScrolling), userInfo: nil, repeats: false)
        scrollView.isScrollEnabled = true
        scrollPosition = UICollectionViewScrollPosition.centeredVertically
        
        let cell = self.collectionView.cellForItem(at: IndexPath(item:  rowCentered, section: 0))
        if cell != nil {
            (cell as! CircleImageCell).centerAnimation()
        }
        
    }
    
    func scrollViewDidScroll(_ scrollView: UIScrollView) {
        
        if scrollView == collectionView{
            var point : CGPoint = CGPoint(x: self.view.bounds.midX, y: self.view.bounds.midY)
            point = view.convert(point, to: collectionView)
            let index = collectionView.indexPathForItem(at: point)
            
            if let indexPath = index {
                if rowCentered != indexPath.row {
                    rowCentered = indexPath.row
                    self.reloadAllData()
                }
            }
        }
    }
    
    @objc func stopScrolling() {
        self.collectionView.isScrollEnabled = true
    }
    
    //MARK : Override parent class
    override func getCustomFlowLayout() -> UICollectionViewFlowLayout{
        let layout = CirclePickerFlowLayout()
        return layout
    }
    
    func couldContinue(_ couldContinue : Bool){
        if couldContinue {
            continueButton.isEnabled = true
            continueButton.alpha = 1.0
        } else {
            continueButton.isEnabled = false
            continueButton.alpha = 0.5
        }
    }
    
    @objc func continueClicked(_ sender : UIButton) {
        var selectedMerchants : [Merchant] = []
        for merchant in merchants {
            if merchant.isSelected {
                selectedMerchants.append(merchant)
            }
        }
        Log.debug("count: \(selectedMerchants.count) merchants")
        self.saveMerchant(selectedMerchants)
    }
    
    func updateProgress(){
        if selectedMerchantsCount <= MinMerchantCount {
        }
    }
    
    // MARK: Skip button
    func skipButtonClicked (_ sender:UIBarButtonItem) {
        var selectedMerchants : [Merchant] = []
        var number = 0
        for merchant in merchants {
            if number >= DefaultCuratorNumber {
                break
            }
            else {
                selectedMerchants.append(merchant)
            }
            number += 1
        }
        Log.debug("count: \(selectedMerchants.count) curators")
        self.saveMerchant(selectedMerchants)
    }
}
