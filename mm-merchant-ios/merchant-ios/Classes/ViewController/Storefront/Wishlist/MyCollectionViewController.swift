//
//  MyCollectionViewController.swift
//  merchant-ios
//
//  Created by Vu Dinh Trung on 6/14/16.
//  Copyright © 2016 WWE & CO. All rights reserved.
//

import UIKit

class MyCollectionViewController: MmViewController, UIPageViewControllerDelegate, UIPageViewControllerDataSource, MMSegmentViewDelegate{

    enum Tab: Int {
        case wishList
        case post
        case content
    }
    
    private var segmentView: MMSegmentView!
    var user:User?
    
    private final var dataSource = [[Any]](repeating: [Any](), count: 3)
    private final var previousIndex = 0
    private final var viewControllers = [MmViewController]()
    
    private final var pageController: UIPageViewController!
    private final var isEndDecelerating = false
    private final var isDrag = false
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        setupNavigationBar()
        createBackButton()
        createTopView()
        createPageViewController()
    
        view.backgroundColor = UIColor.backgroundGray()
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
    
    }

    func setupNavigationBar() {
        setupNavigationBarCartButton()
        
        self.navigationController!.isNavigationBarHidden = false
        
        var rightButtonItems = [UIBarButtonItem]()
        rightButtonItems.append(UIBarButtonItem(customView: buttonCart!))
        
        buttonCart?.addTarget(self, action: #selector(self.goToShoppingCart), for: .touchUpInside)
        
        self.navigationItem.title = String.localize("LB_CA_MY_COLLECTION")
        self.navigationItem.rightBarButtonItems = rightButtonItems
    }

    /**
     create UISegmentController at the top View
     */
    
    func createTopView() {
        let items = [String.localize("LB_CA_COLLECTED_PRODUCT"),
                     String.localize("LB_COUPON_SEGMENT_BRAND"),
                     String.localize("LB_CA_MERCHANT"),
                 String.localize("LB_CA_COLLECTED_POST"),
                 String.localize("LB_CA_COLLECTED_CONTENT")]
        let paddingTop = self.getPaddingTop()
        
        segmentView = MMSegmentView(frame: CGRect(x: 0, y: paddingTop, width: self.view.bounds.width , height: 45), tabs: items)
        segmentView.delegate = self
        self.view.addSubview(segmentView)
        segmentView.setSelectedTab(Tab.wishList.rawValue)
    }
    
    /**
     should hidden collection on main class
     x`
     - returns: false
     */
    override func shouldHaveCollectionView() -> Bool {
        return false
    }
    
    func getPaddingTop() -> CGFloat {
        return navigationController!.navigationBar.frame.maxY 
    }
    
    /**
     using UIPageController to switch tab
     */
    
    func createPageViewController() {
        var originY = segmentView.frame.maxY
        
        if LoginManager.getLoginState() == .guestUser || (Context.anonymousWishListKey() == nil && Context.anonymousWishListKey() == "0") {
            originY = self.getPaddingTop()
            self.segmentView.isHidden = true
        }
        
        pageController = UIPageViewController(transitionStyle: .scroll, navigationOrientation: .horizontal, options: nil)
        pageController.dataSource = self
        pageController.delegate = self
        
        var viewHeight: CGFloat = 0
        //fix height for collectionView
        
        viewHeight = ScreenHeight
        
        pageController.view.frame = CGRect(x: 0, y: originY + Margin.top, width: Constants.ScreenSize.SCREEN_WIDTH, height: viewHeight - segmentView.frame.maxY - Margin.top)
        
        let vc1 = WishListCartViewController()
        vc1.viewHeight = pageController.view.height - tabBarHeight
        vc1.buttonCart = buttonCart
        
        let vc2 = BrandListViewController()
        vc2.isFollowBrandList = true
        
        let vc3 = MerchantListViewController()
        if let user = user {
            vc3.user = user
        }

        let vc4 = PostListViewController()
        vc4.viewHeight = pageController.view.height - tabBarHeight
        
        let vc5 = ContentListViewController()
        vc5.viewHeight = pageController.view.height - tabBarHeight
        
        viewControllers.append(vc1)
        viewControllers.append(vc2)
        viewControllers.append(vc3)
        viewControllers.append(vc4)
        viewControllers.append(vc5)
        
        pageController.setViewControllers([viewControllers[0]], direction: .forward, animated: false, completion: nil)
        self.addChildViewController(pageController)
        view.addSubview(pageController.view)
        
        pageController.didMove(toParentViewController: self)
    }

    // MARK: - UIScrollView Delegate
    
    func scrollViewDidScroll(_ scrollView: UIScrollView) {
        if scrollView.contentOffset.x == Constants.ScreenSize.SCREEN_WIDTH && isEndDecelerating {
            isDrag = false
        }
    }
    
    func scrollViewWillBeginDragging(_ scrollView: UIScrollView) {
        isEndDecelerating = false
        isDrag = true
    }

    func scrollViewWillBeginDecelerating(_ scrollView: UIScrollView) {
        isEndDecelerating = true
    }
    
    // MARK: - PageViewController DataSource
    
    func pageViewController(_ pageViewController: UIPageViewController, viewControllerBefore viewController: UIViewController) -> UIViewController? {
        return nil
    }
    
    func pageViewController(_ pageViewController: UIPageViewController, viewControllerAfter viewController: UIViewController) -> UIViewController? {
        return nil
    }
    
    // MARK: - PageViewController Delegate
    
    func pageViewController(_ pageViewController: UIPageViewController, willTransitionTo pendingViewControllers: [UIViewController]) {
       
    }
    
    func pageViewController(_ pageViewController: UIPageViewController, didFinishAnimating finished: Bool, previousViewControllers: [UIViewController], transitionCompleted completed: Bool) {
        
    }
    
    func refreshPageByIndex (_ index: Int) {
        let viewController = viewControllers[index]
        let className = type(of: viewControllers[index]).description()
        
        switch className {
        case WishListCartViewController.description():
            if let wishListCartViewController = viewController as? WishListCartViewController {
                wishListCartViewController.refreshWishList()
            } else {
                ErrorLogManager.sharedManager.recordNonFatalError(withException: .NullPointerOrTypeMismatch)
            }
        case ContentListViewController.description():
            if let contentPageList = viewController as? ContentListViewController {
                contentPageList.resetPage()
            } else {
                ErrorLogManager.sharedManager.recordNonFatalError(withException: .NullPointerOrTypeMismatch)
            }
        default:
            break
        }
    }

    // MARK: - MMSegmentViewDelegate
    
    func didSelectTabAtIndex(_ tabIndex: Int) {
        var direction = UIPageViewControllerNavigationDirection.reverse
        
        if previousIndex < tabIndex {
            direction = .forward
        }
        
        self.segmentView.isUserInteractionEnabled = false
        pageController.setViewControllers([viewControllers[tabIndex]], direction: direction, animated: true, completion: { [weak self] (completed) in
            if completed {
                if let strongSelf = self {
                    strongSelf.segmentView.isUserInteractionEnabled = true
                }
            }
        })
        
        previousIndex = tabIndex
        
        segmentView.initAnalytics(withViewKey: self.analyticsViewRecord.viewKey)
        
        if let tab = Tab(rawValue: tabIndex) {
            switch tab {
            case .wishList:
                segmentView.recordAction(.Tap, sourceRef: "Product", sourceType: .Link, targetRef: "Collection", targetType: .View)
            case .post:
                segmentView.recordAction(.Tap, sourceRef: "Post", sourceType: .Link, targetRef: "Collection", targetType: .View)
            case .content:
                segmentView.recordAction(.Tap, sourceRef: "Article", sourceType: .Link, targetRef: "Collection", targetType: .View)
            }
        }
    }
    
}
