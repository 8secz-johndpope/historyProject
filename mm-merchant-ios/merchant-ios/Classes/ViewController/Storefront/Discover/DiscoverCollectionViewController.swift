//
//  DiscoverCollectionViewController.swift
//  merchant-ios
//
//  Created by Gam Bogo on 8/4/16.
//  Copyright © 2016 WWE & CO. All rights reserved.
//

import Foundation
import UIKit

class DiscoverCollectionViewController: MmViewController, UIPageViewControllerDelegate, UIPageViewControllerDataSource,MMSegmentViewDelegate {
    
    enum DiscoverViewMode: Int {
        case discoverBrand = 0
        case discoverCategory = 1
    }
    
    private final var bottomBorder = CALayer()
    private final let TopMenuHeight: CGFloat = 45
    private final let TotalPages = 2
    
    private final var dataSource = [[Any]](repeating: [Any](), count: 3)
    
    private final var pageController: UIPageViewController!
    private final var previousIndex = 0
    private final var viewControllers = [MmViewController]()
    
    private final var maxWidth: CGFloat = 0
    private final var bottomBorderWidth: CGFloat = 0
    private final var isDrag = false
    private var segmentSpacing: CGFloat = 0
    private final let segmentHorizontalPadding: CGFloat = 5
    private final let bottomBorderHeight: CGFloat = 1
    private final let segmentBottomPadding: CGFloat = 9
    
    private var brandSegmentLabel = UILabel()
    private var categorySegmentLabel = UILabel()
    
    var viewMode: DiscoverViewMode = .discoverBrand
    
    //Show from other Tab different with Discovery Tab
    //if show from Discovery tab it means the showFromOtherTabbar = false. otherwhise, it's = true
    var showFromOtherTabbar = false
    private var segmentView: MMSegmentView!
    private var isEndDecelerating = false
   
    private var presentTabIndex = -1
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        self.title = String.localize("LB_CA_MY_ORDERS")
        
        setupNavigationBar()
        createTopView()
        createPageViewController()
        
        view.backgroundColor = UIColor.white
        
        
    }
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        
        if presentTabIndex != -1 {
            segmentView.setSelectedTab(presentTabIndex)
            showPageByCurrentSelectedSegmentIndex(false, tabIndex: presentTabIndex)
            presentTabIndex = -1
        }
    }

    override func shouldHaveCollectionView() -> Bool {
        return false
    }
    
    /**
     create UISegmentController at the top View
     */
    
    func createTopView() {
        let paddingTop: CGFloat = navigationController?.navigationBar.frame.maxY ?? 0
        previousIndex = viewMode.rawValue
        segmentView = MMSegmentView(frame: CGRect(x: 0, y: paddingTop, width: self.view.bounds.width , height: Constants.Segment.Height), tabs: [String.localize("LB_AC_BRAND"),String.localize("LB_CA_CATEGORY_BRAND")])
        segmentView.delegate = self
        self.view.addSubview(segmentView)
        segmentView.refreshUI()
    }
    
    /**
     using UIPageController to switch tab
     */
    
    func createPageViewController() {
        pageController = UIPageViewController(transitionStyle: .scroll, navigationOrientation: .horizontal, options: nil)
        pageController.dataSource = self
        pageController.delegate = self
        
        pageController.view.frame = CGRect(x: 0, y: segmentView.frame.maxY, width: ScreenWidth, height: ScreenHeight - (self.navigationController?.navigationBar.height ?? 0) - segmentView.height - tabBarHeight - 20)
        
        let viewHeight: CGFloat = pageController.view.height
        
        let discoverBrandController = DiscoverBrandController()
        discoverBrandController.viewHeight = viewHeight
        viewControllers.append(discoverBrandController)
        
        let discoverCategoryViewController = DiscoverCategoryViewController()
        discoverCategoryViewController.viewHeight = viewHeight
        viewControllers.append(discoverCategoryViewController)
        
        self.addChildViewController(pageController)
        view.addSubview(pageController.view)
        
        pageController.didMove(toParentViewController: self)
        showPageByCurrentSelectedSegmentIndex(false, tabIndex: 0)
        setEnableScrollViewDelegate(true)
    }
    
    // MARK: - View 
    
    func setupNavigationBar() {
        if showFromOtherTabbar {
            createBackButton()
        } else {
            self.navigationItem.hidesBackButton = true
        }
        
        setupNavigationBarCartButton()
        setupNavigationBarWishlistButton()
        
        var rightButtonItems = [UIBarButtonItem]()
        
        if let buttonCart = self.buttonCart {
            rightButtonItems.append(UIBarButtonItem(customView: buttonCart))
        } else {
            ErrorLogManager.sharedManager.recordNonFatalError(withException: .NullPointer)
        }
        
        if let buttonWishlist = self.buttonWishlist {
            rightButtonItems.append(UIBarButtonItem(customView: buttonWishlist))
        } else {
            ErrorLogManager.sharedManager.recordNonFatalError(withException: .NullPointer)
        }
        
        buttonCart?.addTarget(self, action: #selector(self.goToShoppingCart), for: .touchUpInside)
        buttonWishlist?.addTarget(self, action: #selector(self.goToWishList), for: .touchUpInside)
        
        buttonCart?.accessibilityIdentifier = "view_cart_button"
        buttonWishlist?.accessibilityIdentifier = "view_wishlist_button"
        
        var widthTitleView = view.bounds.maxX * 2 / 3
        
        if showFromOtherTabbar {
            widthTitleView = widthTitleView - Constants.Value.BackButtonWidth
        }
        
        let viewTitle = UIView(frame: CGRect(x: 50, y: 0, width: widthTitleView, height: 32.5))
        
        let searchButton = UIButton(type: UIButtonType.custom)
        searchButton.frame = viewTitle.bounds
        searchButton.accessibilityIdentifier = "discover_search_button"
        searchButton.addTarget(self, action: #selector(HomeViewController.searchIconClicked), for: UIControlEvents.touchUpInside)
        
        viewTitle.addSubview(searchButton)
        
        let searchBarImage = UIImageView(image: UIImage(named: "search_bar_no_scan"))
        searchBarImage.frame = CGRect(x: 0, y: 0, width: viewTitle.bounds.maxX, height: searchBarImage.bounds.maxY * viewTitle.bounds.maxX / searchBarImage.bounds.maxX)
        searchButton.addSubview(searchBarImage)
        
        let searchLabelTitle = UILabel(frame: CGRect(x: 30, y: 0, width: viewTitle.bounds.maxX - 55, height: searchBarImage.frame.size.height))
        searchLabelTitle.text = String.localize("LB_CA_SEARCH_PLACEHOLDER")
        searchLabelTitle.textColor = UIColor.secondary4()
        searchLabelTitle.font = UIFont.systemFont(ofSize: 14.0)
        searchButton.addSubview(searchLabelTitle)
        
        self.navigationItem.titleView = viewTitle
        self.title = String.localize("LB_CA_PLP_PRODUCT_LIST")
        self.navigationItem.rightBarButtonItems = rightButtonItems
        
        if showFromOtherTabbar {
            createBackButton()
        }
    }
    
    func showPageByCurrentSelectedSegmentIndex(_ animated: Bool, tabIndex: Int) {
        
        guard viewControllers.count > tabIndex else { return }
        var direction = UIPageViewControllerNavigationDirection.reverse
        
        if previousIndex < tabIndex {
            direction = .forward
        }
        
         let pageViewController: MmViewController = viewControllers[tabIndex]
        
        pageController.setViewControllers([pageViewController], direction: direction, animated: animated, completion: nil)
        
        previousIndex = tabIndex
    }
    
    func setEnableScrollViewDelegate(_ isEnable: Bool) {
        if let pageController = pageController {
            for view in pageController.view.subviews {
                if let scrollview = view as? UIScrollView {
                    scrollview.alwaysBounceHorizontal = true
                    scrollview.delegate = isEnable ? self : nil
                } else {
                    ErrorLogManager.sharedManager.recordNonFatalError(withException: .NullPointerOrTypeMismatch)
                }
            }
        } else {
            ErrorLogManager.sharedManager.recordNonFatalError(withException: .NullPointer)
        }
    }
    
    // MARK: - View Action
    
    func searchIconClicked() {
        let searchViewController = ProductListSearchViewController()
        self.navigationController?.push(searchViewController, animated: false)
    }
    
    // MARK: - UIScrollView Delegate
    
    func scrollViewDidScroll(_ scrollView: UIScrollView) {
        if isDrag {
            segmentView.scrollDidScroll(scrollView.contentOffset.x)
        }
        
        if scrollView.contentOffset.x == Constants.ScreenSize.SCREEN_WIDTH && isEndDecelerating {
            segmentView.updateIndicatorLayer()
            isDrag = false
        }
    }
    
    func scrollViewWillBeginDecelerating(_ scrollView: UIScrollView) {
        isEndDecelerating = true
    }
    
    func scrollViewDidEndDragging(_ scrollView: UIScrollView, willDecelerate decelerate: Bool) {
        isDrag = false
    }
    
    func scrollViewWillBeginDragging(_ scrollView: UIScrollView) {
        isDrag = true
        isEndDecelerating = false
    }
    
    // MARK: - PageViewController DataSource
    
    func pageViewController(_ pageViewController: UIPageViewController, viewControllerBefore viewController: UIViewController) -> UIViewController? {
        var index = self.indexForViewController(viewController)
        index = index - 1
        
        return viewControllerAtIndex(index)
    }
    
    func pageViewController(_ pageViewController: UIPageViewController, viewControllerAfter viewController: UIViewController) -> UIViewController? {
        var index = self.indexForViewController(viewController)
        index = index + 1
        
        return viewControllerAtIndex(index)
    }
    
    // MARK: - PageViewController Delegate
    
    func pageViewController(_ pageViewController: UIPageViewController, didFinishAnimating finished: Bool, previousViewControllers: [UIViewController], transitionCompleted completed: Bool) {
        guard completed else {
            return
        }

        if let _ = pageViewController.viewControllers?[0] as? DiscoverBrandController {
            segmentView.setSelectedTab(0)
        } else {
            segmentView.setSelectedTab(1)
        }
    }

    func indexForViewController(_ viewController : UIViewController) -> Int {
        if viewController is DiscoverBrandController {
            return 0
        } else {
            return  1
        }
    }
    
    func viewControllerAtIndex(_ index : Int) -> UIViewController? {
        if index >= viewControllers.count || index < 0 {
            return nil
        }
        
        return viewControllers[index]
    }
    
    func getSegmentIndex() ->Int {
        if segmentView == nil {
            return 0
        }
        
        return segmentView.selectingTab
    }
    
    // MARK: - MMSegmentViewDelegate
    
    func didSelectTabAtIndex(_ tabIndex: Int) {
        showPageByCurrentSelectedSegmentIndex(true,tabIndex: tabIndex)
        
        if tabIndex == 0 {
            //record action
            self.view.recordAction(.Tap, sourceRef: "Category", sourceType: .Link, targetRef: "BrowseByBrand", targetType: .View)
        }
    }
    
    func showBrandPage(){
        
        presentTabIndex = 0
        
    }
    
    func showCategoryPage(){
        presentTabIndex = 1
    }
    
    override func scrollToTop() {
        if let segmentView = segmentView {
            if segmentView.selectingTab < self.viewControllers.count {
                self.viewControllers[segmentView.selectingTab].scrollToTop()
            }
        }
    }
}
