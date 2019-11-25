//  TutorialViewController.swift
//  merchant-ios
//
//  Created by khanh.nguyen on 5/30/16.
//  Copyright © 2016 WWE & CO. All rights reserved.
//

import UIKit

class TutorialViewController: InvitationCodeSuccessfulViewController, TutorialCellDelegate{

    
    static let CellIdentifier = "TutorialCollectionViewCell"
//    private var collectionView: UICollectionView!
    private var pageControl: UIPageControl!
    private var currentPage = 0
    private var numberOfPages = 4
    private var bannerCollectionViewHeight = CGFloat(0.0)
    private var skipButton : UIButton!
    var offsetX = CGFloat(0)

    override func viewDidLoad() {
        super.viewDidLoad()
        
        bannerCollectionViewHeight = self.view.frame.size.height
        configCollectionView()
        self.view.addSubview(collectionView)
        self.view.addSubview(pageControl)
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    override func getCustomFlowLayout() -> UICollectionViewFlowLayout {
        return UICollectionViewFlowLayout()
    }
    
    func configCollectionView() -> Void {
        let layout = UICollectionViewFlowLayout()
        layout.scrollDirection = UICollectionViewScrollDirection.horizontal
        layout.headerReferenceSize = CGSize.zero
        layout.footerReferenceSize = CGSize.zero
        layout.sectionInset = UIEdgeInsets(top: 0, left: 0, bottom: 0, right: 0)
        layout.minimumInteritemSpacing = 0
        layout.minimumLineSpacing = 0
        layout.itemSize = CGSize(width: CGFloat(self.view.frame.width), height: bannerCollectionViewHeight)

        collectionView = MMCollectionView(frame: self.view.bounds, collectionViewLayout: layout)
        collectionView.contentInset = UIEdgeInsets(top: 0, left: 0, bottom: 0, right: 0)
        collectionView.isPagingEnabled = true
        collectionView.showsHorizontalScrollIndicator = false
        collectionView.dataSource = self
        collectionView.delegate = self
        collectionView.register(TutorialCell.self, forCellWithReuseIdentifier: TutorialViewController.CellIdentifier)
        
        collectionView.backgroundColor = UIColor.clear
        collectionView.backgroundView = UIView(frame: CGRect.zero)
        
        let bottomPadding: CGFloat = 40
        let pageControlHeight: CGFloat = 30
        let width = self.view.frame.width / 2
        
        pageControl = UIPageControl(frame: CGRect(x: (self.view.frame.sizeWidth - width) / 2, y: CGFloat(bannerCollectionViewHeight) - pageControlHeight, width: width, height: pageControlHeight))
        pageControl.currentPage = 0
        pageControl.numberOfPages = numberOfPages - 1
        pageControl.pageIndicatorTintColor = UIColor.secondary13()
        pageControl.currentPageIndicatorTintColor = UIColor.secondary2()
        pageControl.center = CGPoint(x: collectionView.center.x, y: collectionView.bounds.maxY - bottomPadding)
    }
    
    override func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int{
        return numberOfPages
    }
    
    override func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell{
        let cell = collectionView.dequeueReusableCell(withReuseIdentifier: TutorialViewController.CellIdentifier, for: indexPath) as! TutorialCell
        cell.delegate = self
        cell.configCellAtIndexPath(indexPath)
        return cell
    }
    
    func didSelectedDoneButton() {
//        Context.setShownTutorialSpash()
//        LoginManager.goToLogin(true)
        self.goToLoginPage()
    }
    
    func didSelectedSkipButton(_ id : Any) {
        self.goToLoginPage()
    }
    
    func goToLoginPage() {
        self.collectionView.removeFromSuperview()
        self.pageControl.removeFromSuperview()
        Context.setShownTutorialSpash()
    }
    
    // MARK: - Scroll View Delegate
    func scrollViewDidScroll(_ scrollView: UIScrollView) {
        let offset = scrollView.contentOffset
        if offset.x < 0 {
            scrollView.setContentOffset(CGPoint(x: 0, y: offset.y), animated: false)
        }
        if offset.x > (scrollView.contentSize.width - scrollView.frame.size.width) {
            scrollView.setContentOffset(CGPoint(x: scrollView.contentSize.width - scrollView.frame.size.width, y: offset.y), animated: false)
        }
        if offset.x > scrollView.frame.size.width * 2 {
            pageControl.isHidden = true
        }else {
            pageControl.isHidden = false
        }
        
        let page = scrollView.contentOffset.x / scrollView.frame.size.width
        currentPage = Int(floor(page + 0.005))
        if currentPage >= 3 {
            goToLoginPage()
        } else {
            pageControl.currentPage = currentPage
        }
    }
    
}
