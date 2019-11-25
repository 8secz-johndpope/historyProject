//
//  PageViewController.swift
//  NavigationItem
//
//  Created by Kam on 10/5/2017.
//  Copyright © 2017 MyMM. All rights reserved.
//

import UIKit

class NavPageViewController: MmViewController {
    
    struct SegmentedControlOptions {
        var enableSegmentControl: Bool
        var segmentedTitles: [String]?
        var selectedTitleColors: [UIColor]?
        var deSelectedTitleColor: UIColor
        var indicatorColors: [UIColor]?
        var hasRedDot: [Bool]?
        var segmentButtonFontSize: CGFloat
        var navigateToTabIndex: Int
        var segmentButtonWidth: Int?

        init(enableSegmentControl: Bool, segmentedTitles: [String]? = nil, selectedTitleColors: [UIColor]? = nil, deSelectedTitleColor: UIColor? = nil, indicatorColors: [UIColor]? = nil, hasRedDot: [Bool]? = nil, segmentButtonFontSize: CGFloat? = nil, navigateToTabIndex: Int? = nil, segmentButtonWidth: Int? = nil) {
            self.enableSegmentControl = enableSegmentControl
            self.segmentedTitles = segmentedTitles
            self.selectedTitleColors = selectedTitleColors
            self.deSelectedTitleColor = deSelectedTitleColor ?? UIColor.lightGray
            self.indicatorColors = indicatorColors
            self.hasRedDot = hasRedDot // nil means no red dot
            self.segmentButtonFontSize = segmentButtonFontSize ?? 14
            self.navigateToTabIndex = navigateToTabIndex ?? 0 /* default 0, assign your index for transtition*/
            self.segmentButtonWidth = segmentButtonWidth
        }
    }
    var options: SegmentedControlOptions?
    
    private var numOfPageCount = 0
    
    private var isPageScrollingFlag = false
    private var hasAppearedFlag = false

    var currentPageIndex = 0
    private var nextPageIndex = 0
    
    private var pageViewController: UIPageViewController!
    var pageScrollView: UIScrollView!
    
    var segmentedControl: SegmentedControlView?
    var viewControllers: [MmViewController]? {
        didSet {
            if let strongViewControllers = viewControllers, strongViewControllers.count > 0 {
                numOfPageCount = strongViewControllers.count

                for (index, vc) in strongViewControllers.enumerated() {
                    vc.index = index
                }
            }
        }
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        self.shouldRecordViewTag = false
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        
        if !self.hasAppearedFlag {
            
            if let options = options, options.enableSegmentControl {
                self.setupSegmentButtons()
            }
            self.setupPageViewController()
            self.hasAppearedFlag = true
            
            if let options = options, options.enableSegmentControl && options.navigateToTabIndex > 0 && numOfPageCount > options.navigateToTabIndex {
                if let button = self.segmentedControl?.segmentButtons[options.navigateToTabIndex] {
                    self.segmentedControl?.segmentButtonClicked(button)
                }
            }
        }
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
    }
    
    private func setupSegmentButtons() {
        let tabWidth = options?.segmentButtonWidth ?? 60
        
        self.segmentedControl = SegmentedControlView(
            frame: CGRect(x: 0, y: 0, width: tabWidth * numOfPageCount, height: NavPageViewController.getSegmentHeight()),
            segmentedTitles: options!.segmentedTitles!,
            hasRedDot: options!.hasRedDot,
            segmentButtonFontSize: options!.segmentButtonFontSize,
            selectedTitleColors: options!.selectedTitleColors!,
            deSelectedTitleColor: options!.deSelectedTitleColor,
            indicatorColors: options!.indicatorColors!
        )

        self.segmentedControl!.delegate = self
        self.navigationItem.titleView = self.segmentedControl
    }
    
    private func setupPageViewController() {
        self.pageViewController = UIPageViewController(transitionStyle: .scroll, navigationOrientation: .horizontal, options: nil)
        self.addChildViewController(self.pageViewController)
        self.pageViewController.dataSource = self
        self.pageViewController.delegate = self
        for view in pageViewController.view.subviews {
            if let scrollview = view as? UIScrollView {
                self.pageScrollView = scrollview
                scrollview.delegate = self
                break
            }
        }
        
        self.pageViewController.view.frame = CGRect(x:0, y:0, width:
                                                        self.view.frame.size.width, height:
                                                        self.view.frame.size.height)
        
        if let vcs = self.viewControllers, vcs.count > 0 {
            self.pageViewController.setViewControllers([vcs[0]], direction: .forward, animated: true, completion: nil)
        }
        self.view.addSubview(pageViewController.view)
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }

    override func scrollToTop() {
        
        if let viewControllers = self.viewControllers, viewControllers.count > currentPageIndex {
            let currentViewController = viewControllers[currentPageIndex]
            currentViewController.scrollToTop()
        }
        
    }
    
    class func getSegmentHeight()-> Int {
        return 44
    }
    
    func showTab(_ index: Int){
        guard (self.segmentedControl?.segmentButtons.indices.contains(index) ?? false) else{
            return
        }
        
        if let button = self.segmentedControl?.segmentButtons[index] {
            self.segmentedControl?.segmentButtonClicked(button)
        }
    }
    
    func pageViewDidChanged(_ index: Int) {
        
    }
    
}

extension NavPageViewController: UIPageViewControllerDelegate, UIPageViewControllerDataSource, SegmentedControlDelegate {
    
    func scrollViewWillBeginDragging(_ scrollView: UIScrollView) {
        self.isPageScrollingFlag = true
        self.segmentedControl?.isPageScrollingFlag = true
    }
    
    func scrollViewDidEndDecelerating(_ scrollView: UIScrollView) {
        self.isPageScrollingFlag = false
        self.segmentedControl?.isPageScrollingFlag = false
        
        if let vc = pageViewController.viewControllers?.get(0) as? MmViewController {
            if currentPageIndex != vc.index {
                currentPageIndex = vc.index
                segmentedControl?.currentPageIndex = vc.index
                segmentedControl?.pageViewTransitionCompleted(currentPageIndex)
                pageViewDidChanged(self.currentPageIndex)
                
                segmentedControl?.scrollViewDidScroll(scrollView, currentPageIndex: currentPageIndex)
            }
        }
    }
    
    func scrollViewDidScroll(_ scrollView: UIScrollView) {
        if isPageScrollingFlag {
            if scrollView.contentOffset.x <= 0 || scrollView.contentOffset.x >= scrollView.frame.size.width * 2 {
                currentPageIndex = nextPageIndex
                segmentedControl?.currentPageIndex = nextPageIndex
                segmentedControl?.pageViewTransitionCompleted(currentPageIndex)
                pageViewDidChanged(self.currentPageIndex)
            }

            segmentedControl?.scrollViewDidScroll(scrollView, currentPageIndex: currentPageIndex)
        }
    }
    
    //MARK:- PageViewController DataSource
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
    
    func pageViewController(_ pageViewController: UIPageViewController, willTransitionTo pendingViewControllers: [UIViewController]) {
        if let vcs = self.viewControllers {
            for i in 0..<vcs.count {
                if pendingViewControllers[0] == vcs[i] {
                    nextPageIndex = i
                    segmentedControl?.nextPageIndex = i
                    break
                }
            }
        }
    }
        
    func indexForViewController(_ viewController : UIViewController) -> Int {
        if let vc = viewController as? MmViewController {
            return vc.index
        }
        
        return 0
    }
    
    func viewControllerAtIndex(_ index : Int) -> UIViewController? {
        if index >= viewControllers?.count ?? 0 || index < 0 {
            return nil
        }
        
        return viewControllers?[index]
    }
    
    func segmentButtonClicked(_ sender: UIButton) {
        
        guard sender.tag != self.currentPageIndex else {
            return
        }
        
        if !self.isPageScrollingFlag {
            
            let tempIdx = self.currentPageIndex
            
            let completion = {
                self.currentPageIndex = self.nextPageIndex
                self.segmentedControl?.currentPageIndex = self.nextPageIndex
                self.segmentedControl?.isPageScrollingFlag = false
                self.pageViewDidChanged(self.currentPageIndex)
            }
            
            self.nextPageIndex = sender.tag
            self.segmentedControl?.nextPageIndex = sender.tag
            self.segmentedControl?.updateIndicator()
            
            if sender.tag > tempIdx {
                if let vcs = self.viewControllers, vcs.count > sender.tag {
                    pageViewController.setViewControllers([vcs[sender.tag]], direction: .forward, animated: false, completion: { (complete) in
                            
                        if complete {
                            completion()
                        }
                    })
                }
            } else if sender.tag < tempIdx {
                if let vcs = self.viewControllers, vcs.count > sender.tag {
                    pageViewController.setViewControllers([vcs[sender.tag]], direction: .reverse, animated: false, completion: { (complete) in
                            
                        if complete {
                            completion()
                        }
                    })
                }
            }
        }
    }

}
