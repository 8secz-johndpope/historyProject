//
//  MMPageViewController.swift
//  MMPager
//
//  Created by Kam on 21/2/2017.
//  Copyright © 2017 Kam. All rights reserved.
//

import UIKit

protocol MMPageViewControllerDelegate: NSObjectProtocol {
    func getIndex() -> Int
    func setIndex(index: Int)
}

protocol MMPageContainerDelegate: NSObjectProtocol {
    func didScrolledToPage(_ index: Int)
}

class MMPageViewController: MmViewController {

    weak var containerDelegate: MMPageContainerDelegate?
    public var isBounce = true // 控制是否左右滑动
    var dynamicWidthTab: Bool = false /* for less tabs case, will separate width to each tab */
    private let RED_DOT_TAG = 100

    private var X_BUFFER = 0
    private var Y_BUFFER = 14
    private var SELECTOR_WIDTH_BUFFER: CGFloat = 0.0
    private var BUTTON_WIDTH_BUFFER: CGFloat = 24.0
    var SEGMENT_HEIGHT: CGFloat = 45
    var MARGIN_Y:CGFloat = 0.0
    var SEGMENT_Y: CGFloat {
        if MARGIN_Y > 0.0 {
            return MARGIN_Y
        } else {
            return navigationController?.navigationBar.frame.maxY ?? StartYPos
        }
        
    }
    var SEARCHBAR_HEIGHT: CGFloat = 44
    private var ANIMATION_SPEED: CGFloat = 0.2
    private var SELECTOR_Y_BUFFER: CGFloat = 36
    private var SELECTOR_HEIGHT: CGFloat = 2.0
    private var SELECTOR_WIDTH: CGFloat {
        get {
            var btnWidth: CGFloat = 0.0
            var width: CGFloat = 0.0
            if let titles = segmentedTitles, titles.count > 0, buttons.count > currentPageIndex {
                if let title = titles.get(currentPageIndex), let nextTitle = titles.get(nextPageIndex) {
                    btnWidth = buttons[currentPageIndex].frame.size.width
                    let currentWidth = StringHelper.getTextWidth(title, height: SEGMENT_HEIGHT, font: UIFont.systemFont(ofSize: FontSize))
                    width = currentWidth
                    let nextWidth = StringHelper.getTextWidth(nextTitle, height: SEGMENT_HEIGHT, font: UIFont.systemFont(ofSize: FontSize))
                    
                    var diffWidth = nextWidth - currentWidth
                    if self.pageViewController.view.frame.size.width > self.pageScrollView.contentOffset.x { //scroll to left
                        let ratio = (self.pageViewController.view.frame.size.width - self.pageScrollView.contentOffset.x) / self.pageViewController.view.frame.size.width
                        
                        diffWidth *= ratio
                    } else { //scroll to right
                        let ratio = (self.pageScrollView.contentOffset.x - self.pageViewController.view.frame.size.width) / self.pageViewController.view.frame.size.width
                        
                        diffWidth *= ratio
                    }
                    width += diffWidth
                }
            }
            width += SELECTOR_WIDTH_BUFFER
            X_BUFFER = Int((btnWidth - width)/2)
            return width
        }
    }
    
    private var X_OFFSET = 0
    private var FontSize: CGFloat = 14

    var pageViewController: UIPageViewController!
    var pageScrollView: UIScrollView!
    var isContainSearchBar = false
    var shouldHaveSegment = true

    var viewControllers: [UIViewController]? {
        didSet {
            if let strongViewControllers = viewControllers, strongViewControllers.count > 0 {
                numOfPageCount = strongViewControllers.count
                for (index, vc) in strongViewControllers.enumerated() {
                    if let delegate = vc as? MMPageViewControllerDelegate {
                        delegate.setIndex(index: index)
                    }
                }
            }
        }
    }
    private var buttons = [UIButton]()
    private var numOfPageCount = 0
    var currentPageIndex = 0
    private var nextPageIndex = 0
    var navigateToTabIndex = 0 /* default 0, assign your index for redirection*/
    private var isPageScrollingFlag = false
    private var hasAppearedFlag = false
    
    var segmentedControlView: UIScrollView? {
        didSet {
            self.segmentedControlView?.showsVerticalScrollIndicator = false
            self.segmentedControlView?.showsHorizontalScrollIndicator = false
        }
    }
    var isSegmentScrollable = false
    var segmentedTitles: [String]? {
        didSet {
            if let segmentedTitles = segmentedTitles {
                for (index, title) in segmentedTitles.enumerated() {
                    if let button = buttons.get(index) {
                        button.setTitle(title, for: .normal)
                    }
                }
            }
        }
    }
    private var selectionIndicator: UIView!
    var backgroundColor: UIColor?
    open var segmentBackgroundColor: UIColor?
    private let IndicatorOffset: CGFloat = 5
    var hasRedDot = [Bool]()
    var searchBar: UISearchBar?
    
    var initialIndex: Int? = nil
    
    //返回top的控制器
    override func track_topPage() -> UIViewController {
        let index = self.currentPageIndex
        if let vs = self.viewControllers,vs.count > index {
            return vs[index].track_topPage()
        }
        return self
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        
        if !hasAppearedFlag, let _ = self.viewControllers {
            if !shouldHaveSegment || self.segmentedTitles != nil {
                self.reveal()
            }
        }
        hasAppearedFlag = true
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
    }
    
    override func shouldHaveCollectionView() -> Bool {
        return false
    }
    
    private func setupSegmentButtons() {
        
        self.segmentedControlView = UIScrollView(frame: CGRect(x: 0, y: SEGMENT_Y, width: self.view.frame.size.width, height: SEGMENT_HEIGHT))
        
        guard let titles = self.segmentedTitles, let segmentedControl = self.segmentedControlView else {
            return
        }
        
        var contentSizeWidth: CGFloat = 0.0
        for title in titles {
            contentSizeWidth += StringHelper.getTextWidth(title, height: SEGMENT_HEIGHT, font: UIFont.systemFont(ofSize: FontSize)) + BUTTON_WIDTH_BUFFER
        }
        
        var remainAverageW:CGFloat = 0.0
        if contentSizeWidth > segmentedControl.bounds.width {
            self.isSegmentScrollable = true
            segmentedControl.contentSize = CGSize(width: contentSizeWidth, height: SEGMENT_HEIGHT)
        } else if dynamicWidthTab {
            let remainWidth = segmentedControl.bounds.width - contentSizeWidth
            remainAverageW = remainWidth / CGFloat(titles.count)
        }
        
        if titles.count >= numOfPageCount {//safety guard
            for i in 0..<numOfPageCount {
                var buttonWidth: CGFloat = 0
                
                if isSegmentScrollable || dynamicWidthTab {
                    buttonWidth = StringHelper.getTextWidth(titles[i], height: SEGMENT_HEIGHT, font: UIFont.systemFont(ofSize: FontSize)) + BUTTON_WIDTH_BUFFER
                } else {
                    buttonWidth = ((self.view.frame.size.width) / CGFloat(numOfPageCount))
                }
                
                if dynamicWidthTab && !isSegmentScrollable {
                    buttonWidth += remainAverageW
                }
                
                let previousButtonMaxX = (buttons.count > 0) ? buttons[max(i - 1, 0)].frame.maxX : 0
                let button = SegmentedButton(frame: CGRect(x: previousButtonMaxX,
                    y: 0,
                    width: buttonWidth,
                    height: SEGMENT_HEIGHT))
                button.fontSize = FontSize

                button.tag = i
                let title = titles[i]
                button.setTitle(title, for: .normal)
                    
                let textWidth = StringHelper.getTextWidth(title, height: SEGMENT_HEIGHT, font: UIFont.systemFont(ofSize: FontSize))
                let view = UIView(frame: CGRect(x: (button.width + textWidth) / 2, y: 12, width: 5, height: 5))
                view.tag = RED_DOT_TAG
                view.round()
                view.backgroundColor = .red
                view.isHidden = true
                button.addSubview(view)
                
                button.addTarget(self, action: #selector(self.segmentButtonClicked), for: .touchUpInside)
                if i == 1 {
                    button.titleLabel?.adjustsFontSizeToFitWidth = true
                }
                button.setTitleColor(UIColor.secondary16(), for: .normal)
                button.setTitleColor(UIColor.secondary16(), for: .highlighted)
                button.setTitleColor(UIColor.secondary15(), for: .selected)
                
                buttons.append(button)
                segmentedControl.addSubview(button)
            }
            
            reloadSegmentState()
        }
        
        self.view.addSubview(self.segmentedControlView!)
        
        if let color = self.segmentBackgroundColor {
            self.segmentedControlView!.backgroundColor = color
        }
        
        if !saftyCheck(initialIndex) {
            return
        }
        
        buttons[initialIndex ?? 0].isSelected = true
    }
    
    open func reveal() {
        
        setupPageViewController(initialIndex ?? 0)
        
        if shouldHaveSegment {
            setupSegmentButtons()
        }
        
        if isContainSearchBar {
            setupSearchBar()
        }

        if saftyCheck(initialIndex) {
            
            // Indicator must setup after PageViewController
            if shouldHaveSegment {
                setupIndicator(initialIndex ?? 0)
            }
            
            if navigateToTabIndex > 0 && self.buttons.count > navigateToTabIndex {
                self.segmentButtonClicked(self.buttons[navigateToTabIndex])
            }
        }
        
        self.hasAppearedFlag = true
    }
    
    private func setupSearchBar() {
        self.searchBar = UISearchBar(frame: CGRect(x: 0, y: segmentedControlView?.frame.maxY ?? SEGMENT_Y, width: view.frame.size.width, height: SEARCHBAR_HEIGHT))
        self.view.addSubview(searchBar!)
    }

    // 判断当前控制器是不是栈中的第一个控制器
    private var isLocalNavigationRootViewController:Bool {
        guard let nav = self.navigationController,let root = nav.viewControllers.first else {
            return false
        }
        
        var vc:UIViewController? = self
        while (vc != nil) {
            if vc == nav {
                return false
            } else if vc == root {
                return true
            }
            vc = vc?.parent
        }
        return false
    }
    
    private func setupPageViewController(_ initialIndex: Int? = nil) {
        self.pageViewController = UIPageViewController(transitionStyle: .scroll, navigationOrientation: .horizontal, options: nil)
        //建立子父控制器关系
        self.addChildViewController(self.pageViewController)
        
        if let bgColor = self.backgroundColor {
            pageViewController.view.backgroundColor = bgColor
        }
        self.pageViewController.dataSource = self
        self.pageViewController.delegate = self
        
        for view in pageViewController.view.subviews {
            if let scrollview = view as? UIScrollView {
                self.pageScrollView = scrollview
                scrollview.delegate = self
                scrollview.bounces = isBounce
                break
            }
        }
        if let nav = navigationController, let pan = nav.interactivePopGestureRecognizer {
            if !isLocalNavigationRootViewController {
                pageScrollView.panGestureRecognizer.require(toFail: pan)
            }
        }

        var searchBarMaxY = shouldHaveSegment ? (self.segmentedControlView?.frame.maxY ?? SEGMENT_Y + SEGMENT_HEIGHT) : 0
        
        if let searchBar = self.searchBar {
            searchBarMaxY = searchBar.frame.maxY
        }
        
        self.pageViewController.view.frame = CGRect(x: 0, y: searchBarMaxY, width: view.frame.size.width, height: view.frame.maxY - searchBarMaxY - tabBarHeight)
        
        if let vcs = self.viewControllers, vcs.count > 0 {
            self.pageViewController.setViewControllers([vcs[initialIndex ?? 0]], direction: .forward, animated: true, completion: nil)
        }
        self.view.addSubview(pageViewController.view)
    }
    
    private func saftyCheck(_ idx:Int?) -> Bool {
        if let idx = idx,(idx < 0 || idx >= buttons.count) {
            return false
        }
        if buttons.isEmpty {
            return false
        }
        return true
    }
    
    private func setupIndicator(_ initialIndex: Int? = nil) {
        
        if !saftyCheck(initialIndex) {
            return
        }
        
        var x = CGFloat(X_BUFFER)
        var width = SELECTOR_WIDTH
        
        if let initialIndex = initialIndex, let title = segmentedTitles?.get(initialIndex) {
            width = StringHelper.getTextWidth(title, height: SEGMENT_HEIGHT, font: UIFont.systemFont(ofSize: FontSize)) + SELECTOR_WIDTH_BUFFER
            x = buttons[initialIndex].centerX - width / 2
            
            currentPageIndex = initialIndex
//            containerDelegate?.didScrolledToPage(currentPageIndex)
        }
        
        selectionIndicator = UIView(frame: CGRect(x: x, y: SELECTOR_Y_BUFFER, width: width, height: SELECTOR_HEIGHT))
        selectionIndicator.layer.cornerRadius = SELECTOR_HEIGHT/2
        selectionIndicator.backgroundColor = UIColor.primary1()
        segmentedControlView?.addSubview(selectionIndicator)
    }
    
    @objc func segmentButtonClicked(_ sender: UIButton!) {
        if !self.isPageScrollingFlag {

            let tempIdx = self.currentPageIndex
            
            let completion = { [weak self] in
                if let aSelf = self {
                    aSelf.currentPageIndex = aSelf.nextPageIndex
                    aSelf.containerDelegate?.didScrolledToPage(aSelf.currentPageIndex)
                    
                    for btn in aSelf.buttons {
                        btn.isSelected = false
                    }
                    sender.isSelected = true
                }
            }
            
            self.nextPageIndex = sender.tag
            updateIndicator()
            
            if sender.tag > tempIdx {
                if let vcs = self.viewControllers, vcs.count > sender.tag {

                    if isContainSearchBar {
                        resetSearchBar(vcs[sender.tag])
                    }

                    pageViewController.setViewControllers([vcs[sender.tag]], direction: .forward, animated: false, completion: { (complete) in
                        if complete {
                            completion()
                        }
                    })
                }
            } else if sender.tag < tempIdx {
                if let vcs = self.viewControllers, vcs.count > sender.tag {

                    if isContainSearchBar {
                        resetSearchBar(vcs[sender.tag])
                    }

                    pageViewController.setViewControllers([vcs[sender.tag]], direction: .reverse, animated: false, completion: { (complete) in
                        if complete {
                            completion()
                        }
                    })
                }
            }
        }
    }
    
    func updateIndicator() {
        if let title = segmentedTitles?.get(nextPageIndex) {
            let width = StringHelper.getTextWidth(title, height: SEGMENT_HEIGHT, font: UIFont.systemFont(ofSize: FontSize)) + SELECTOR_WIDTH_BUFFER
            let xPos = self.buttons[nextPageIndex].center.x - width / 2
            
            UIView.animate(withDuration: 0.2, animations: {
                self.selectionIndicator.frame = CGRect(
                    x: xPos,
                    y: CGFloat(self.selectionIndicator.frame.origin.y),
                    width: width,
                    height: CGFloat(self.selectionIndicator.frame.size.height)
                )
            })
        }
    }
    
    func selectTab(atIndex index: Int) {
        if !saftyCheck(index) {
            return
        }
        if let button = buttons.get(index) {
            segmentButtonClicked(button)
        }
    }
    
    func tab(atIndex index: Int, loadTitle title: String) {
        if !saftyCheck(index) {
            return
        }
        if let button = buttons.get(index) {
            button.setTitle(title, for: .normal)
        }
    }
    
    func resetSearchBar(_ viewController: UIViewController) {
        searchBar!.text = ""
        searchBar!.resignFirstResponder()
        searchBar!.delegate?.searchBar!(searchBar!, textDidChange: "")
        if let vc = viewController as? MmViewController{
            searchBar!.delegate = vc
        }
        
    }
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    override func backButtonClicked(_ button: UIButton) {
        super.backButtonClicked(button)
        
        pageScrollView?.delegate = nil
    }
    
    func reloadSegmentState() {
        for (index, button) in buttons.enumerated() {
            if let shouldShowRedDot = hasRedDot.get(index), shouldShowRedDot == true {
                button.viewWithTag(RED_DOT_TAG)?.isHidden = false
            }
            else {
                button.viewWithTag(RED_DOT_TAG)?.isHidden = true
            }
        }
    }
}

extension MMPageViewController : UIPageViewControllerDelegate, UIPageViewControllerDataSource {
    
    func scrollViewWillBeginDragging(_ scrollView: UIScrollView) {
        self.isPageScrollingFlag = true
    }
    
    func scrollViewDidEndDecelerating(_ scrollView: UIScrollView) {
        self.isPageScrollingFlag = false
    }
    
    func scrollViewDidScroll(_ scrollView: UIScrollView) {
//        guard !isScrollViewBouncing(scrollView) else {
//            return
//        }
        
        guard buttons.count > currentPageIndex else {
            return
        }
        
        if isPageScrollingFlag {
            
            if scrollView.contentOffset.x <= 0 || scrollView.contentOffset.x >= scrollView.frame.size.width * 2 {
                let previousButton = buttons.get(currentPageIndex)
                previousButton?.isSelected = false
                
                currentPageIndex = nextPageIndex
                containerDelegate?.didScrolledToPage(currentPageIndex)
                
                let currentButton = buttons.get(currentPageIndex)
                currentButton?.isSelected = true
                
                if let vc = viewControllers?.get(currentPageIndex), isContainSearchBar {
                    resetSearchBar(vc)
                }
            }
            
            animateIndicator(scrollView)
        }
    }
    
    private func isScrollViewBouncing(_ scrollView: UIScrollView) -> Bool {
        let minXOffset = scrollView.bounds.size.width - (CGFloat(self.currentPageIndex) * scrollView.bounds.size.width)
        let maxXOffset = CGFloat(numOfPageCount - self.currentPageIndex) * scrollView.bounds.size.width
        
        if scrollView.contentOffset.x <= minXOffset {
            scrollView.contentOffset = CGPoint(x: minXOffset, y: 0)
            return true
        } else if scrollView.contentOffset.x >= maxXOffset {
            scrollView.contentOffset = CGPoint(x: maxXOffset, y: 0)
            return true
        }
        return false
    }
    
    private func animateIndicator(_ scrollView: UIScrollView) {
        let xFromCenter: Int = Int(self.view.frame.size.width - scrollView.contentOffset.x)
        let width = SELECTOR_WIDTH
        
        let xCoor: CGFloat = CGFloat(X_BUFFER) + buttons[currentPageIndex].frame.origin.x
        let ratio: CGFloat = ((buttons[currentPageIndex].frame.size.width + buttons[nextPageIndex].frame.size.width) / 2) / self.view.frame.size.width
//            xCoor = (((self.segmentedControlView?.frame.size.width ?? self.view.frame.size.width) / CGFloat(numOfPageCount)) * CGFloat(currentPageIndex))
//            ratio = buttons[currentPageIndex].frame.size.width / self.view.frame.size.width
        
        self.selectionIndicator.frame = CGRect(
            x: xCoor - CGFloat(xFromCenter) * ratio,
            y: CGFloat(selectionIndicator.frame.origin.y),
            width: width,
            height: CGFloat(selectionIndicator.frame.size.height)
        )
        
        if isSegmentScrollable {
            pagingSegmentedControl()
        }
    }
    
    private func pagingSegmentedControl() {
        if let segmentView = self.segmentedControlView, buttons.count > currentPageIndex {
            let targetButton = buttons[currentPageIndex]
            let outsideBound: Bool = (segmentView.contentOffset.x + segmentView.width) <= targetButton.frame.maxX
                || segmentView.contentOffset.x > targetButton.frame.origin.x
            
            if outsideBound {
                segmentView.contentOffset = CGPoint(x: max(targetButton.frame.origin.x, 0), y: 0)
            }
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
                    break
                }
            }
        }
    }
    
    //MARK:- PageViewController Delegate
    func indexForViewController(_ viewController : UIViewController) -> Int {
        if let delegate = viewController as? MMPageViewControllerDelegate {
            let index = delegate.getIndex()
            return index
        }
        
        return 0
    }
    
    func viewControllerAtIndex(_ index : Int) -> UIViewController? {
        if let vcs = viewControllers{
            if index >= vcs.count || index < 0 {
                return nil
            }
        }
        return viewControllers?.get(index)
    }
}
