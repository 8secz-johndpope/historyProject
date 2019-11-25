//
//  NewsFeedViewController.swift
//  merchant-ios
//
//  Created by khanh.nguyen on 5/12/17.
//  Copyright © 2017 WWE & CO. All rights reserved.
//

import UIKit

class NewsFeedViewController: NavPageViewController {

    private var searchButton = UIButton()
    let createPostButton = UIButton()
    
    //这个页面支持新的埋点
    override func track_support() -> Bool {
        return true
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()

        self.options = SegmentedControlOptions(
            enableSegmentControl: true,
            segmentedTitles: [String.localize("LB_CA_HOT_POSTS"), String.localize("LB_CA_ALL_CURATORS"), String.localize("LB_CA_MYMM_MAGAZINE")],
            selectedTitleColors: [UIColor.secondary15(), UIColor.secondary15(), UIColor.secondary15()],
            deSelectedTitleColor: UIColor.secondary16(),
            indicatorColors: [UIColor.primary1(), UIColor.primary1(), UIColor.primary1()],
            navigateToTabIndex: 0,
            segmentButtonWidth: 80
        )
        
        let normalFeedController = SubHomeViewController()
        normalFeedController.onAllUsersSelected = { [weak self] in
            Navigator.shared.dopen(Navigator.mymm.deeplink_dk_curator_list)
        }
        
        let curatorRecommendedController = CuratorCollectionViewController()
        curatorRecommendedController.topOffsetY = CGFloat(NavPageViewController.getSegmentHeight())
        let magazineController = MagazineLandingViewController()
        magazineController.topOffsetY = CGFloat(NavPageViewController.getSegmentHeight())
        self.viewControllers = [normalFeedController, curatorRecommendedController, magazineController]
        
        self.edgesForExtendedLayout = []
        // Do any additional setup after loading the view.
        
        self.setupNavigationBarButton()
        
        func pageViewDidChanged(_ index: Int) {
//            guard let zone = ColorZone(rawValue: index) else {return}
//            Context.currentZone = zone
//            StorefrontController.currentInstance?.updateLayout(zone)
        }
    }
    
    override func pageViewDidChanged(_ index: Int) {
        super.pageViewDidChanged(index)
        switch index {
        case 0:
            self.view.recordAction(.Tap, sourceRef: "PostListing", sourceType: .Link, targetRef: "Newsfeed-Home-User", targetType: .View)
        case 1:
            self.view.recordAction(.Tap, sourceRef: "CuratorListing", sourceType: .Link, targetRef: "AllCurators", targetType: .View)
        case 2:
            self.view.recordAction(.Tap, sourceRef: "Web", sourceType: .Button, targetRef: "ContentPage", targetType: .View)
        default:
            break
        }
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        updateButtonCartState()
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        self.pageScrollView.isScrollEnabled = false
    }

    @objc func createPostAuthoring()  {
        if LoginManager.getLoginState() != .validUser {
            LoginManager.goToLogin()
            return
        }
        
        PopManager.sharedInstance.selectPost()
        
        self.view.recordAction(.Tap, sourceRef: "CreatePost", sourceType: .Button, targetRef: "Editor-Image-Album", targetType: .View)
    }
    
    func setupNavigationBarButton() {
        let ButtonHeight = CGFloat(25 + 10)
        let ButtonWidth = CGFloat(30 + 10)
        
        searchButton.frame = CGRect(x: 0, y: 0, width: ButtonWidth, height: ButtonHeight)
        searchButton.contentEdgeInsets = UIEdgeInsets(top: 0, left: -18, bottom: 0, right: 0)
        searchButton.setImage(UIImage(named: "btn_search_grey"), for: UIControlState())
        searchButton.addTarget(self, action: #selector(NewsFeedViewController.searchIconClicked), for: UIControlEvents.touchUpInside)
        let leftBarButton = UIBarButtonItem(customView: searchButton)
        
        self.navigationItem.leftBarButtonItem = leftBarButton
        
        createPostButton.frame = CGRect(x: 0, y: 0, width: ButtonWidth, height: ButtonHeight)
        createPostButton.contentEdgeInsets = UIEdgeInsets(top: 0, left: 0, bottom: 0, right: -18)
        createPostButton.setImage(UIImage(named: "ic_camera"), for: UIControlState())
        createPostButton.addTarget(self, action: #selector(self.createPostAuthoring), for: UIControlEvents.touchUpInside)
        
        self.navigationItem.rightBarButtonItem = UIBarButtonItem(customView: createPostButton)
    }
    
    // MARK: - Views And Actions
    @objc func searchIconClicked() {
        let searchViewController = ProductListSearchViewController()
        self.navigationController?.push(searchViewController, animated: false)
    }
}

