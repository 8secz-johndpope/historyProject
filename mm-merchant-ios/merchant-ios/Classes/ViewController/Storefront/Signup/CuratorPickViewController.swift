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

class CuratorPickViewController : MmViewController {
    var backgroundImageView : UIImageView!
    var curators : [User] = []
    var selectedCuratorCount = 0
    var rowCentered = -1
    var fansLabel : FansLabel!
    var countLabel = UILabel()
    var scrollPosition : UICollectionViewScrollPosition = UICollectionViewScrollPosition.centeredVertically
    private let continueButton = UIButton()
    private var titleTextAttributes : [NSAttributedStringKey: Any]!
    private var navigationBGImage : UIImage!
    private var navigationShadowImage : UIImage!
    private var navigationTranslucent : Bool = false
    private var navigationBGColor : UIColor!
    private var isFakeNavigationBarHiden : Bool = false
    private final let CircleImageCellHeight : CGFloat = 60
    private final let CircleExpansion : CGFloat = 60
    private final let ContinueButtonHeight : CGFloat = 50
    private final let MinCuratorCount = 3
    private final let MinFollower = 10000 //TODO Will be define later
    private final let CircleWithPercent : CGFloat = 0.8
    private final let DefaultCuratorNumber : Int = 5
    private final let MarginLeft : CGFloat = 10
    private final let SpacingLine : CGFloat = 30
    private final let collectionViewWidth : CGFloat = 280
    
    //private final let MaxRow : Int = 10000
    private var isScrolling = false
    private var curatorFollowerString : String = String.localize("LB_CA_CURATORS_FOLLOWER_NO")
    let formatter = NumberFormatter()
    override func viewDidLoad() {
        super.viewDidLoad()
        setupBackgroundView()
        setupCollectionView()
        
        setupLabels()//Lebel should front of circle
        setupContinueButton()
        couldContinue(false)
//        loadCurator()
        createBackButton(.whiteColor)
        formatter.numberStyle = .decimal
        formatter.locale = Locale(identifier: "zh_Hans_CN")
        formatter.maximumFractionDigits = 0
    }
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        self.title = String.localize("LB_CA_CURATORS_FOLLOW")
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
            titleTextAttributes = navigationController.navigationBar.titleTextAttributes
            navigationBGImage = navigationController.navigationBar.backgroundImage(for: UIBarMetrics.default)
            navigationShadowImage = navigationController.navigationBar.shadowImage
            navigationTranslucent = navigationController.navigationBar.isTranslucent
            navigationBGColor = navigationController.view.backgroundColor
        }
//        if let navigationController = self.navigationController as? GKFadeNavigationController {
//            isFakeNavigationBarHiden = navigationController.isFakeViewHiden()
//        }
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
    
    func setupBackgroundView() {
        backgroundImageView = UIImageView(frame: self.view.frame)
        backgroundImageView.image = UIImage(named: "curator_bg")
        self.view.insertSubview(backgroundImageView, belowSubview : collectionView)
    }
    
    func setupCollectionView() {
        collectionView.backgroundColor = UIColor.clear
        collectionView.frame = CGRect(x: self.view.frame.midX - collectionViewWidth / 2 , y: 50, width: collectionViewWidth , height: self.view.frame.height - 100)
        collectionView.center = self.view.center
        collectionView.alwaysBounceVertical = true
        collectionView.showsVerticalScrollIndicator = false
        collectionView.register(CircleImageCell.self, forCellWithReuseIdentifier: "CircleImageCell")
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
//        if let navigationController = self.navigationController as? GKFadeNavigationController {
//            navigationController.setFakeViewHiden(true)
//        }
    }
    
    func setupContinueButton(){
        continueButton.frame = CGRect(x: 0, y: self.view.bounds.maxY - ContinueButtonHeight, width: self.view.bounds.width, height: ContinueButtonHeight)
        continueButton.layer.backgroundColor = UIColor.primary1().cgColor
        continueButton.setTitle(String.localize("LB_CA_FOLLOW_CURATORS_CONT"), for: UIControlState())
        continueButton.addTarget(self, action: #selector(CuratorPickViewController.continueClicked), for: UIControlEvents.touchUpInside)
        self.view.addSubview(continueButton)
    }
    
    func setupLabels(){
        fansLabel = FansLabel(frame: CGRect(x: self.view.frame.midX + (CircleImageCellHeight + CircleExpansion) / 2 + 5 , y: self.view.frame.midY - 20, width: self.view.frame.midX - (CircleImageCellHeight + CircleExpansion) / 2, height: 60))
        self.fansLabel.bottomLabel.isHidden = true //Hide it temporary, will show again in future.
        self.view.insertSubview(fansLabel, aboveSubview: collectionView )
        countLabel.frame = CGRect(x: 0, y: 76, width: self.view.frame.width, height: 17)
        countLabel.formatSize(14)
        countLabel.textColor = UIColor.white
        countLabel.textAlignment = .center
        countLabel.backgroundColor = UIColor.clear
        countLabel.text = "\(String.localize("LB_CA_RECOMMENDED_CURATOR_PREFIX"))0\(String.localize("LB_CA_RECOMMENDED_CURATOR_PROFIX"))"
        self.view.insertSubview(countLabel, aboveSubview: collectionView )


    }
    
    //MARK: Promise Call
    @discardableResult
    func saveCurator(_ curators : [User])-> Promise<Any> {
        return Promise{ fulfill, reject in
            FollowService.saveCurator(curators){
                [weak self] (response) in
                if let strongSelf = self {
                    if response.response?.statusCode == 200 {
                        
                        strongSelf.navigationController?.pushViewController(MerchantPickViewController(), animated: true)
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
        let row = indexPath.row
        if (self.curators.count > row) {
            cell.setImage(self.curators[row].profileImage, category: .user)
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
        cell.drawSelect(curators[row].isSelected,selecting: curators[row].isClicking)
        curators[row].isClicking = false
        return cell
    }
    
    func numberOfSections(in collectionView: UICollectionView) -> Int {
        return 1
    }
    
    override func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return curators.count
    }
    
    
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, minimumLineSpacingForSectionAt section: Int) -> CGFloat{
        return SpacingLine
    }
    
    func collectionView(_ collectionView: UICollectionView,
        didSelectItemAt indexPath: IndexPath) {
        if isScrolling {
            return
        }
            let row = rowCentered
        Log.debug("row: \(row)  rowCenterd: \(rowCentered)  indexPath.row: \(indexPath.row)")
            if indexPath.row != rowCentered {

                collectionView.scrollToItem(at: indexPath, at: UICollectionViewScrollPosition.centeredVertically , animated: true)
                
                if (indexPath.row < rowCentered) {
                    collectionView.scrollToItem(at: IndexPath(item: self.curators.count - 1, section: 0), at: UICollectionViewScrollPosition.centeredVertically , animated: true)
                    collectionView.scrollToItem(at: indexPath, at: UICollectionViewScrollPosition.centeredVertically , animated: true)
                    
                    
                } else {
                    
                    collectionView.scrollToItem(at: IndexPath(item: 0, section: 0), at: UICollectionViewScrollPosition.centeredVertically , animated: true)
                    collectionView.scrollToItem(at: indexPath, at: UICollectionViewScrollPosition.centeredVertically , animated: true)
                    
                    
                    
                }
                
                collectionView.isScrollEnabled = false
                isScrolling = true
                return;
            }
            curators[row].isSelected = !curators[row].isSelected
            if curators[row].isSelected {
                selectedCuratorCount += 1
                curators[row].isClicking = true
            } else {
                selectedCuratorCount -= 1
                curators[row].isClicking = false
            }
            //updateProgress() //Remove center circle
            couldContinue(selectedCuratorCount >= MinCuratorCount)
            self.reloadAllData()
    }
    
    
    func reloadAllData(){
        self.collectionView.reloadData()
        let row = rowCentered 
        if rowCentered >= 0 {
            self.fansLabel.topLabel.text = curators[row].lastName + curators[row].firstName
            self.fansLabel.midLabel.text = curators[row].displayName
            let followerCount = curators[row].count * 9999
            if followerCount < MinFollower {
                self.fansLabel.bottomLabel.text = ""
            } else {
                self.fansLabel.bottomLabel.text = "\(curatorFollowerString)" + formatter.string(from: NSNumber(value: followerCount))!
            }
        }
        self.countLabel.text = "\(String.localize("LB_CA_RECOMMENDED_CURATOR_PREFIX"))\(formatter.string(from: NSNumber(value: curators.count))!)\(String.localize("LB_CA_RECOMMENDED_CURATOR_PROFIX"))"
        
    }
    func scrollViewDidEndDragging(_ scrollView: UIScrollView, willDecelerate decelerate: Bool) {
        if (!decelerate) {
            isScrolling = false
            scrollView.isScrollEnabled = true
             Log.debug("++++++++++++++: scrollViewDidEndDragging $$$$$$$$$$$")
        }
    }
    
    //MARK: Scroll View Method to control page control
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
        isScrolling = true
        Log.debug("============= scrollViewDidScroll")
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
        isScrolling = false
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
        var selectedCurators : [User] = []
        for curator in curators {
            if curator.isSelected {
                selectedCurators.append(curator)
            }
        }
        Log.debug("count: \(selectedCurators.count) curators")
        self.saveCurator(selectedCurators)
    }
    
    func updateProgress(){
        if selectedCuratorCount <= MinCuratorCount {
        }
    }
    
    // MARK: Skip button
    func skipButtonClicked (_ sender:UIBarButtonItem) {
        var selectedCurators : [User] = []
        var number = 0
        for curator in curators {
            if number >= DefaultCuratorNumber {
                break
            }
            else {
                selectedCurators.append(curator)
            }
            number += 1
        }
        Log.debug("count: \(selectedCurators.count) curators")
        self.saveCurator(selectedCurators)
    }
}
