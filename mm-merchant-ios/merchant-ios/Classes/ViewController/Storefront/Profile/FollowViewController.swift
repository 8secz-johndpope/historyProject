
//
//  FollowViewController.swift
//  merchant-ios
//
//  Created by Trung Vu on 3/7/16.
//  Copyright © 2016 WWE & CO. All rights reserved.
//

import UIKit

enum ModeList: Int {
    case curatorList = 0
    case usersList
}

@objc
protocol FollowViewControllerDelegate: NSObjectProtocol {
    @objc optional func didTextChange(_ text: String, searchBar: UISearchBar)
    @objc optional func didSelectCancelButton(_ searchBar: UISearchBar)
    @objc optional func didSelectSearchButton(_ text: String, searchBar: UISearchBar)
}

class FollowViewController: MmViewController, UIPageViewControllerDelegate, UIPageViewControllerDataSource, MMSegmentViewDelegate {
    
    private final let SubCatCellId = "SubCatCell"
    private final let CellId = "Cell"
    private final let CatCellHeight : CGFloat = 40
    final let CatCellMarginLeft : CGFloat = 20
    final let CatCellSpacing : CGFloat = 42
    
    private var orginYSearhBar: CGFloat = 104
	
    var selectedIndex: Int = 0
    var searchActive : Bool = false
	
    var contentView: UIView = UIView()
    var searchBar: UISearchBar = UISearchBar()
    var curatorListViewController = CuratorListViewController()
    var followingUserListViewController = FollowingUserListViewController()
    var user: User?
    var currentProfileType: TypeProfile = TypeProfile.Private
    var merchantGetMode: MerchantGetMode?
    weak var delegate_: FollowViewControllerDelegate?
    var modelist: ModeList = ModeList.curatorList
    var currentTab: Int = 10
    var tabFont : UIFont = UIFont.systemFont(ofSize: 12)
    private var tabWidth : CGFloat = 0
    //private var contentInset = UIEdgeInsets.zero;
    var segmentView: MMSegmentView!
    var activeViewController: UIViewController? {
        didSet {
            removeInactiveViewController(oldValue)
            updateActiveViewController(self.contentView, activeViewController: activeViewController)
        }
    }
	
    private final var pageController: UIPageViewController!
    private var nextIndex = 0
    
    private var isEndDecelerating = false
    private var isDrag = false
    private var bottomPadding = CGFloat(10)
    var bottomBorder = CALayer()

	private var totalCountOfPages = 3
    var marginLeft = CGFloat(0)
	
    func shouldHavePageViewController() -> Bool {
        return true
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()

		self.title = String.localize("LB_CA_FOLLOWING_LIST")
		
        //setting up the user and profile type
        if let viewingUser = user {
            curatorListViewController.user = viewingUser
            followingUserListViewController.user = viewingUser
        }
        
        curatorListViewController.currentProfileType = currentProfileType
        followingUserListViewController.currentProfileType = currentProfileType

        
        self.view.backgroundColor = UIColor.white
        self.createBackButton()
        createTopView()
        if self.shouldHavePageViewController() {
            self.createPageViewController()
        }else {
            createContentView()
        }
		
        
        switchTab(selectedIndex)
        
         self.view.initAnalytics(withViewKey: self.analyticsViewRecord.viewKey)
    }
	
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        NotificationCenter.default.addObserver(self, selector: #selector(FollowViewController.keyboardWillShow), name:NSNotification.Name.UIKeyboardWillShow, object: nil);
        NotificationCenter.default.addObserver(self, selector: #selector(FollowViewController.keyboardWillHide), name:NSNotification.Name.UIKeyboardWillHide, object: nil);
    }
	
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        NotificationCenter.default.removeObserver(self, name: NSNotification.Name.UIKeyboardWillShow, object: nil)
        NotificationCenter.default.removeObserver(self, name: NSNotification.Name.UIKeyboardWillHide, object: nil)
    }
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
	
	func switchTab(_ index: Int) {
		
		switch(index) {
		case ModeList.curatorList.rawValue:
			showCuratorList()
			currentTab = selectedIndex
			break
		case ModeList.usersList.rawValue:
			showFollowingUser()
			currentTab = selectedIndex
			break
		default:
			break
		}

	}
	
    func createTopView() {
		
        if shouldHavePageViewController() {

            segmentView = MMSegmentView(frame: CGRect(x: 0, y: StartYPos, width: self.view.bounds.width , height: Constants.Segment.Height), tabs: [String.localize("LB_CA_CURATOR"),String.localize("LB_CA_USER")])
            segmentView.delegate = self
            self.view.addSubview(segmentView)
            segmentView.refreshUI()

            orginYSearhBar = segmentView.frame.maxY
        }
        
        searchBar.frame = CGRect(x: 0, y: orginYSearhBar, width: self.view.bounds.width, height: 40)
        searchBar.placeholder = String.localize("LB_CA_SEARCH")
        self.view.addSubview(self.searchBar)
        searchBar.delegate = self
        var textField : UITextField
        textField = searchBar.value(forKey: "_searchField") as! UITextField
        textField.layer.cornerRadius = 15
        textField.layer.masksToBounds = true
        
    }
	
    func createContentView() {
        contentView.frame = CGRect(x: 0, y: self.searchBar.frame.maxY, width: self.view.frame.width, height: self.view.frame.height - (self.searchBar.frame.maxY + tabBarHeight))
        
        contentView.backgroundColor = UIColor.gray
        self.view.addSubview(contentView)
		
		self.addSwipeGesture(#selector(FollowViewController.respondToSwipeGesture), direction: UISwipeGestureRecognizerDirection.right)
		self.addSwipeGesture(#selector(FollowViewController.respondToSwipeGesture), direction: UISwipeGestureRecognizerDirection.left)
		
    }
	
	private func addSwipeGesture(_ selector: Selector, direction: UISwipeGestureRecognizerDirection) {
		let swipeGestureRecognizer = UISwipeGestureRecognizer(target: self, action: selector)
		swipeGestureRecognizer.direction = direction
		swipeGestureRecognizer.delegate = self
		self.view.addGestureRecognizer(swipeGestureRecognizer)
	}
	
    func backupNavigationTitleColor() {
        if let navi = self.navigationController {
            navi.navigationBar.titleTextAttributes = [NSAttributedStringKey.foregroundColor:UIColor.secondary4()]
        }
    }

	// MARK: - UIGestureRecognizerDelegate
	@objc func respondToSwipeGesture(_ gesture: UIGestureRecognizer) {
		
		if let swipeGesture = gesture as? UISwipeGestureRecognizer {
			switch swipeGesture.direction {
			case UISwipeGestureRecognizerDirection.right:
				selectedIndex = (selectedIndex - 1) >= 0 ? selectedIndex - 1 : 0
			case UISwipeGestureRecognizerDirection.left:
				selectedIndex = (selectedIndex + 1) <= ModeList.usersList.rawValue ? selectedIndex + 1 : ModeList.usersList.rawValue
			default:
				break
			}
		}
		
		switchTab(selectedIndex)
	}
	
    func hideKeyboard() {
        self.view.endEditing(true)
    }

    func showMerchantList() {
        let previousIndex = selectedIndex
        self.setSelectedViewController(previousIndex, index: selectedIndex)
        
    }
    
    
    func showCuratorList() {
        let previousIndex = selectedIndex
        self.updateCuratorListData()
        self.setSelectedViewController(previousIndex, index: selectedIndex)
        
    }
    
    func updateCuratorListData() {
        selectedIndex = ModeList.curatorList.rawValue
        setSelectedViewControler(selectedIndex)
		
        if shouldHavePageViewController() == false {
            activeViewController = curatorListViewController
        }
        
        self.delegate_ = curatorListViewController.self
        self.view.endEditing(true)
		
    }
    
    func showFollowingUser() {
        let previousIndex = selectedIndex
        self.updateFollowingData()
        
        self.setSelectedViewController(previousIndex, index: selectedIndex)
        
    }
    
    func updateFollowingData() {
        selectedIndex = ModeList.usersList.rawValue
        setSelectedViewControler(selectedIndex)
		
        followingUserListViewController.arrayUser.removeAll()
        if shouldHavePageViewController() == false {
            activeViewController = followingUserListViewController
        }
        self.delegate_ = followingUserListViewController.self
        self.view.endEditing(true)
		
    }
    
    func setSelectedViewController(_ previousIndex : Int, index : Int) {
        if shouldHavePageViewController() {
           // updateSelectedLayer()
            if let viewController = self.viewControllerAtIndex(index) {
                
                var direction = UIPageViewControllerNavigationDirection.reverse
                
                if previousIndex < index {
                    direction = .forward
                }
                pageController.setViewControllers([viewController], direction: direction, animated: true, completion: nil)
            }
        }
    }
    
    func setSelectedViewControler(_ index: Int) {
        if self.shouldHavePageViewController() {
            segmentView.setSelectedTab(index)
        }
    }
	
    //MARK: - searchbar delegate
    func searchBarTextDidBeginEditing(_ searchBar: UISearchBar) {
        searchActive = true;
    }
    
    func searchBarTextDidEndEditing(_ searchBar: UISearchBar) {
        searchActive = false;
    }
    
    func searchBarCancelButtonClicked(_ searchBar: UISearchBar) {
        searchActive = false;
        self.view.endEditing(true)
        self.delegate_?.didSelectCancelButton?(searchBar)
    }
    
    func searchBarSearchButtonClicked(_ searchBar: UISearchBar) {
        searchActive = false;
        self.delegate_?.didSelectSearchButton?(searchBar.text ?? "", searchBar: searchBar)
        searchBar.resignFirstResponder()
    }
	
    func searchBar(_ searchBar: UISearchBar, textDidChange searchText: String) {
        self.delegate_?.didTextChange?(searchText, searchBar: searchBar)
    }
    
    func searchBarShouldBeginEditing(_ searchBar: UISearchBar) -> Bool {
        searchBar.showsCancelButton = true
        styleCancelButton(true)
        return true
    }
    
    func searchBarShouldEndEditing(_ searchBar: UISearchBar) -> Bool {
        searchBar.showsCancelButton = false
        return true
    }
    
    func styleCancelButton(_ enable: Bool){
        if enable {
            if let _cancelButton = searchBar.value(forKey: "_cancelButton"),
                let cancelButton = _cancelButton as? UIButton {
                    cancelButton.isEnabled = enable //comment out if you want this button disabled when keyboard is not visible
                    if title != nil {
                        cancelButton.setTitle(String.localize("LB_CANCEL"), for: UIControlState())
                    }
            }
        }
    }
    
    func removeInactiveViewController(_ inactiveViewController: UIViewController?) {
        if let inActiveVC = inactiveViewController {
            // call before removing child view controller's view from hierarchy
            inActiveVC.willMove(toParentViewController: nil)
            
            inActiveVC.view.removeFromSuperview()
            
            // call after removing child view controller's view from hierarchy
            inActiveVC.removeFromParentViewController()
        }
    }
    
    func updateActiveViewController(_ viewContent: UIView, activeViewController: UIViewController!) {
        if let activeVC = activeViewController {
            // call before adding child view controller's view as subview
            addChildViewController(activeVC)
            
            activeVC.view.frame = viewContent.bounds
            viewContent.addSubview(activeVC.view)
            
            // call before adding child view controller's view as subview
            activeVC.didMove(toParentViewController: self)
            backupNavigationTitleColor()
        }
    }
    
    func createPageViewController() {
        pageController = UIPageViewController(transitionStyle: .scroll, navigationOrientation: .horizontal, options: nil)
        pageController.dataSource = self
        pageController.delegate = self
        
        let maxY = searchBar.frame.maxY
        
        pageController.view.frame = CGRect(x: 0, y: maxY, width: self.view.bounds.width, height: self.view.frame.size.height - maxY)
        
        self.addChildViewController(pageController)
        self.view.addSubview(pageController.view)
        pageController.view.backgroundColor = UIColor.white
        
        for view in pageController.view.subviews {
            if let scrollview = view as? UIScrollView {
                scrollview.delegate = self
                break
            }
        }
    }
    
    func viewControllerAtIndex(_ index : Int) -> UIViewController? {
        switch index {
        case 0:
            return curatorListViewController
        case 1:
            return followingUserListViewController
        default:
            return nil
        }
    }
    
    func indexForViewController(_ viewController : UIViewController) -> Int {
        if viewController == curatorListViewController {
            return  0
        }else if viewController == followingUserListViewController {
            return  1
        }else {
            return  0
        }
    }
    
	
    // MARK: - UIScrollView Delegate
    func scrollViewDidScroll(_ scrollView: UIScrollView) {
        if isDrag {
            if self.shouldHavePageViewController() { //Fix bug crash if dont have segment
                segmentView.scrollDidScroll(scrollView.contentOffset.x)
            }
        }
        
        if scrollView.contentOffset.x == Constants.ScreenSize.SCREEN_WIDTH && isEndDecelerating {
            //updateSelectedLayer()
            if self.shouldHavePageViewController() { //Fix bug crash if dont have segment
                segmentView.updateIndicatorLayer()
            }
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
    
    //MARK: PageViewController DataSource
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
    
    //MARK: PageViewController Delegate
    func pageViewController(_ pageViewController: UIPageViewController, willTransitionTo pendingViewControllers: [UIViewController]) {
        let viewController = pendingViewControllers[0]
        nextIndex = self.indexForViewController(viewController)
        
    }
    
    func pageViewController(_ pageViewController: UIPageViewController, didFinishAnimating finished: Bool, previousViewControllers: [UIViewController], transitionCompleted completed: Bool) {
        if completed {
            if let currentViewController = self.viewControllerAtIndex(nextIndex) {
                selectedIndex = self.indexForViewController(currentViewController)
                switch currentViewController {
                case curatorListViewController:
                    self.updateCuratorListData()
                case followingUserListViewController:
                    self.updateFollowingData()
                default:
                    break
                }
            }
        }else {
            nextIndex = selectedIndex
        }
    }
    
    @objc func keyboardWillHide(_ sender: Notification) {
        if let currentCollectionView = self.getCurrentCollectionView() {
            currentCollectionView.contentInset = UIEdgeInsets.zero
        }
    }
    
    @objc func keyboardWillShow(_ sender: Notification) {
        if let currentCollectionView = self.getCurrentCollectionView() {
                if let keyboardFrame = (sender.userInfo?[UIKeyboardFrameEndUserInfoKey] as? NSValue) {
                    let keyboardSize = keyboardFrame.cgRectValue.size
                    let heightOfset = ((keyboardSize.height + searchBar.frame.maxY + currentCollectionView.frame.height ) - self.view.bounds.size.height)
                    if heightOfset > 0 {
                        var edgeInset = currentCollectionView.contentInset;
                        edgeInset.bottom = heightOfset
                        currentCollectionView.contentInset = edgeInset
                    }
                }
        }
    }
    func getCurrentCollectionView() -> UICollectionView? {
        switch selectedIndex {
        case ModeList.curatorList.rawValue:
            return curatorListViewController.collectionView
        case ModeList.usersList.rawValue:
            return followingUserListViewController.collectionView
        default:
            return nil
        }
    }
    
    //MARK: MMSegmentViewDelegate
    func didSelectTabAtIndex(_ tabIndex: Int) {
        switch tabIndex {
        case 0:
            showCuratorList()
            self.view.recordAction(.Tap, sourceRef: "Curator", sourceType: .Link, targetRef: "MyFollow-Curator", targetType: .View)
            break
        case 1:
            showFollowingUser()
            self.view.recordAction(.Tap, sourceRef: "User", sourceType: .Link, targetRef: "MyFollow-User", targetType: .View)
            break
        default:
            break
        }
    }
}

