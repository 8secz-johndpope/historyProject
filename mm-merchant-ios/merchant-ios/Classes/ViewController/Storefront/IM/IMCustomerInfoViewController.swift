//
//  IMCustomerInfoViewController.swift
//  merchant-ios
//
//  Created by hungvo on 5/24/16.
//  Copyright © 2016 WWE & CO. All rights reserved.
//

import Foundation
import PromiseKit
import ObjectMapper

class IMCustomerInfoViewController: MmViewController, UIPageViewControllerDataSource, UIPageViewControllerDelegate {
    
    enum Tab: Int {
        case customerInfo
        case productList
    }
    
    private final var bottomBorder = CALayer()
    private final var segmentControl: UISegmentedControl!
    
    private final var start = 0
    
    private final var dataSource = [[Any]](repeating: [Any](), count: 2)
   
    private final let CellHeight = CGFloat(60)
    
    private final var pageController: UIPageViewController!
    private final var totalCountOfPages = 2
    private final var nextIndex = 0
    private final var previousIndex = 0
    private final var viewControllers = [MmViewController]()
    
    var productAttachedHandler: ((_ data: CartItem) -> Void)?
    
    var conv : Conv?
    
    //MARK: View lifecycle
    override func viewDidLoad() {
        super.viewDidLoad()
        title = String.localize("LB_CUST_INFO")
        view.backgroundColor = UIColor.white
        
        createBackButton()
        createTopView()
        createPageViewController()
    }
    
    func createTopView() {
        let items = [String.localize("LB_CS_CHAT_INFO"), String.localize("LB_CS_PRODUCT_LIST")]
        let paddingTop = self.getPaddingTop()
        
        segmentControl = UISegmentedControl(items: items)
        segmentControl.frame = CGRect(x: 0, y: paddingTop, width: Constants.ScreenSize.SCREEN_WIDTH, height: Constants.Value.CatCellHeight)
        segmentControl.setTitleTextAttributes([NSAttributedStringKey.foregroundColor : UIColor.secondary3()], for: UIControlState())
        segmentControl.setTitleTextAttributes([NSAttributedStringKey.foregroundColor : UIColor.primary1()], for: .selected)
        
        segmentControl.addTarget(self, action: #selector(segmentDidChange), for: .valueChanged)
        segmentControl.setBackgroundImage(UIImage(), for: UIControlState(), barMetrics: .default)
        segmentControl.setBackgroundImage(UIImage(), for: .selected, barMetrics: .default)
        segmentControl.setDividerImage(UIImage(), forLeftSegmentState: UIControlState(), rightSegmentState: UIControlState(), barMetrics: .default)
        view.addSubview(segmentControl)
        
        let separatorLine = UIView(frame:CGRect(x: 0, y: segmentControl.frame.height - 1, width: segmentControl.frame.width, height: 1))
        separatorLine.backgroundColor = UIColor.secondary1()
        segmentControl.addSubview(separatorLine)
        
        segmentControl.layer.addSublayer(bottomBorder)
        selectItemAtIndex(Tab.customerInfo.rawValue)
    }
    
    func getPaddingTop() -> CGFloat {
        return navigationController!.navigationBar.frame.maxY
    }
    
    func createPageViewController() {
        pageController = UIPageViewController(transitionStyle: .scroll, navigationOrientation: .horizontal, options: nil)
        pageController.dataSource = self
        pageController.delegate = self
        pageController.view.frame = CGRect(x: 0, y: segmentControl.frame.maxY, width: Constants.ScreenSize.SCREEN_WIDTH, height: self.tabBarController!.tabBar.frame.maxY - segmentControl.frame.maxY)

        let vc1 = CustomerInfoViewController()
        vc1.viewHeight = pageController.view.height
        vc1.conv = self.conv
        let vc2 = CustomerProductListViewController()
        vc2.user = self.conv?.presenter
        vc2.conv = self.conv
        vc2.viewHeight = pageController.view.height
        
        vc2.productAttachedHandler = { [weak self] (data) in
            if let strongSelf = self {
                if let callback = strongSelf.productAttachedHandler {
                    callback(data)
                } else {
                    ErrorLogManager.sharedManager.recordNonFatalError(withException: .NullPointer)
                }
            } else {
                ErrorLogManager.sharedManager.recordNonFatalError(withException: .NullPointer)
            }
        }
        
        viewControllers.append(vc1)
        viewControllers.append(vc2)
        
        pageController.setViewControllers([viewControllers[0]], direction: .forward, animated: false, completion: nil)
        self.addChildViewController(pageController)
        view.addSubview(pageController.view)
        
        pageController.didMove(toParentViewController: self)
    }
    

    //MARK: Actions
    override func backButtonClicked(_ button: UIButton) {
        super.backButtonClicked(button)
    }

    @objc func segmentDidChange(_ segmentControl: UISegmentedControl) {
        
        selectItemAtIndex(segmentControl.selectedSegmentIndex)
        
        var direction = UIPageViewControllerNavigationDirection.reverse
        
        if previousIndex < segmentControl.selectedSegmentIndex {
            direction = .forward
        }
        
        pageController.setViewControllers([viewControllers[segmentControl.selectedSegmentIndex]], direction: direction, animated: true, completion: nil)
        
        previousIndex = segmentControl.selectedSegmentIndex
    }
    
    func selectItemAtIndex(_ index: Int) {
        segmentControl.selectedSegmentIndex = index
        nextIndex = index
        bottomBorder.borderColor = UIColor.red.cgColor
        bottomBorder.borderWidth = 1
        
        var maxWidth: CGFloat!
        var width: CGFloat!

        maxWidth = segmentControl.size.width / 2
        width = segmentControl.size.width / 6
        
        bottomBorder.frame = CGRect(x: CGFloat(index) * maxWidth + ((maxWidth - width) / 2), y: segmentControl.frame.height - 5, width: width, height: 1)

    }
    
    //MARK: PageViewController DataSource
    func pageViewController(_ pageViewController: UIPageViewController, viewControllerBefore viewController: UIViewController) -> UIViewController? {
        
        if segmentControl.selectedSegmentIndex == 0 {
            return nil
        }
        
        return viewControllers[segmentControl.selectedSegmentIndex - 1]
    }
    
    func pageViewController(_ pageViewController: UIPageViewController, viewControllerAfter viewController: UIViewController) -> UIViewController? {
        
        if segmentControl.selectedSegmentIndex == totalCountOfPages - 1 {
            return nil
        }
        
        return viewControllers[segmentControl.selectedSegmentIndex + 1]

    }
    
    //MARK: PageViewController Delegate
    func pageViewController(_ pageViewController: UIPageViewController, willTransitionTo pendingViewControllers: [UIViewController]) {
        if pendingViewControllers[0] is CustomerProductListViewController {
            nextIndex = 1
        }
        else {
            nextIndex = 0
        }
    }
    
    func pageViewController(_ pageViewController: UIPageViewController, didFinishAnimating finished: Bool, previousViewControllers: [UIViewController], transitionCompleted completed: Bool) {
        
        guard completed else { return }
        
        if nextIndex != segmentControl.selectedSegmentIndex {
            selectItemAtIndex(nextIndex)
            previousIndex = segmentControl!.selectedSegmentIndex
        }
    }
        
    //MARK: Config view
    override func shouldHaveCollectionView() -> Bool {
        return false
    }
}
