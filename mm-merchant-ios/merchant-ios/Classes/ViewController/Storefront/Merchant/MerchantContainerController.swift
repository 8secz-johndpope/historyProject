//
//  MerchantContainerController.swift
//  merchant-ios
//
//  Created by HungPM on 5/23/17.
//  Copyright © 2017 WWE & CO. All rights reserved.
//

import Foundation

class MerchantContainerController: NavPageViewController {
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        options = SegmentedControlOptions(
            enableSegmentControl: true,
            segmentedTitles: [String.localize("LB_CA_REDZONE"), String.localize("LB_CA_BLACKZONE")],
            selectedTitleColors: [UIColor.secondary15(), UIColor.secondary15()],
            deSelectedTitleColor: UIColor.secondary16(),
            indicatorColors: [.red, UIColor.secondary15()],
            navigateToTabIndex: Context.currentZone.rawValue,
            segmentButtonWidth: 80
        )
        
        var height = view.height
        var navigationBarMaxY = CGFloat(0)
        if let navigationController = self.navigationController {
            navigationBarMaxY = navigationController.navigationBar.frame.maxY
        }
        height -= navigationBarMaxY

        let redzoneController = MerchantGridViewController()

        let blackzoneController = MerchantGridViewController()

        viewControllers = [redzoneController, blackzoneController]

        setupNavigationBarButton()
    }
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    override func pageViewDidChanged(_ index: Int) {
    }
    
    func setupNavigationBarButton() {
        let ButtonHeight = CGFloat(25)
        let ButtonWidth = CGFloat(30)

        let backButton = UIButton()
        backButton.frame = CGRect(x: 0, y: 0, width: ButtonWidth, height: ButtonHeight)
        backButton.setImage(UIImage(named: "back_grey"), for: UIControlState())
        backButton.addTarget(self, action: #selector(backButtonTapped), for: .touchUpInside)
        backButton.contentEdgeInsets = UIEdgeInsets(top: 0, left: Constants.Value.BackButtonMarginLeft , bottom: 0, right: 0)
        
        
        let searchButton = UIButton()
        searchButton.frame = CGRect(x: 0, y: 0, width: ButtonWidth, height: ButtonHeight)
        searchButton.setImage(UIImage(named: "search_grey"), for: UIControlState())
        searchButton.addTarget(self, action: #selector(searchButtonTapped), for: .touchUpInside)
        searchButton.contentEdgeInsets = UIEdgeInsets(top: 0, left: Constants.Value.BackButtonMarginLeft , bottom: 0, right: 0)
        
        
        let leftButtonItems = [UIBarButtonItem(customView: backButton), UIBarButtonItem(customView: searchButton)]
        navigationItem.leftBarButtonItems = leftButtonItems

        buttonCart = ButtonRedDot(type: .custom)
        buttonCart!.setImage(UIImage(named: "cart_grey"), for: UIControlState())
        buttonCart!.frame = CGRect(x: 0, y: 0, width: ButtonWidth, height: ButtonHeight)
        buttonCart!.addTarget(self, action: #selector(goToShoppingCart), for: .touchUpInside)
        buttonCart?.contentEdgeInsets = UIEdgeInsets(top: 0, left: 0 , bottom: 0, right: Constants.Value.NavigationButtonMargin)
        buttonCart?.redDotAdjust = CGPoint(x: -2, y: 0)
        let rightButtonItems = [UIBarButtonItem(customView: buttonCart!)]
        navigationItem.rightBarButtonItems = rightButtonItems
    }
    
    // MARK: - Actions
    @objc func backButtonTapped() {
        navigationController?.popViewController(animated: true)
    }
    
    @objc func searchButtonTapped() {
        let searchViewController = ProductListSearchViewController()
        navigationController?.push(searchViewController, animated: false)
    }
    
    override func segmentButtonClicked(_ sender: UIButton) {
        super.segmentButtonClicked(sender)
        
        let sourceRef = sender.tag == 0 ? "RedZone" : "BlackZone"
        view.recordAction(.Tap, sourceRef: sourceRef, sourceType: .Button, targetRef: "AllMerchants", targetType: .View)
    }

    override func shouldHaveCollectionView() -> Bool {
        return false
    }
}
