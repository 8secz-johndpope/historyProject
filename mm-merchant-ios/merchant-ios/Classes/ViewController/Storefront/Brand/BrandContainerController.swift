//
//  BrandContainerController.swift
//  merchant-ios
//
//  Created by HungPM on 5/23/17.
//  Copyright © 2017 WWE & CO. All rights reserved.
//

import Foundation

class BrandContainerController: NavPageViewController {
    var fromePost = false
    var didSelectBrandHandler: ((Brand) -> ())?
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        self.edgesForExtendedLayout = [.bottom]

        options = SegmentedControlOptions(
            enableSegmentControl: true,
            segmentedTitles: [String.localize("LB_CA_REDZONE"), String.localize("LB_CA_BLACKZONE")],
            selectedTitleColors: [UIColor.secondary15(), UIColor.secondary15()],
            deSelectedTitleColor: UIColor.secondary16(),
            indicatorColors: [.red, UIColor.secondary15()],
            navigateToTabIndex: Context.currentZone.rawValue,
            segmentButtonWidth: 80
        )
        
        let redzoneController = BrandListViewController()
        redzoneController.zoneMode = .red
        redzoneController.viewHeight = view.height
        
        let blackzoneController = BrandListViewController()
        blackzoneController.zoneMode = .black
        blackzoneController.viewHeight = view.height
        redzoneController.didSelectBrandHandler = { [weak self] brand in
            if let strongSelf = self {
                if strongSelf.fromePost {
                    if let didSelectBrandHandler = strongSelf.didSelectBrandHandler{
                        didSelectBrandHandler(brand)
                    }
                }else{
                    let brandViewController = BrandViewController()
                    brandViewController.brand = brand
                    strongSelf.navigationController?.pushViewController(brandViewController, animated: true)
                }
            }
        }
        blackzoneController.didSelectBrandHandler = { [weak self] brand in
            if let strongSelf = self {
                if strongSelf.fromePost {
                    if let didSelectBrandHandler = strongSelf.didSelectBrandHandler{
                        didSelectBrandHandler(brand)
                    }
                }else{
                    let brandViewController = BrandViewController()
                    brandViewController.brand = brand
                    strongSelf.navigationController?.pushViewController(brandViewController, animated: true)
                }
                
            }
        }
        
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
        
        let searchButton = UIButton()
        searchButton.frame = CGRect(x: 0, y: 0, width: ButtonWidth, height: ButtonHeight)
        searchButton.setImage(UIImage(named: "search_grey"), for: UIControlState())
        searchButton.addTarget(self, action: #selector(searchButtonTapped), for: .touchUpInside)
        
        let leftButtonItems = [UIBarButtonItem(customView: backButton), UIBarButtonItem(customView: searchButton)]
        navigationItem.leftBarButtonItems = leftButtonItems
        
        buttonCart = ButtonRedDot(type: .custom)
        buttonCart!.setImage(UIImage(named: "cart_grey"), for: UIControlState())
        buttonCart!.frame = CGRect(x: 0, y: 0, width: ButtonWidth, height: ButtonHeight)
        buttonCart!.addTarget(self, action: #selector(goToShoppingCart), for: .touchUpInside)
        
        let rightButtonItems = [UIBarButtonItem(customView: buttonCart!)]
        navigationItem.rightBarButtonItems = rightButtonItems
        
        if fromePost {
            buttonCart?.isHidden = true
        }else{
            buttonCart?.isHidden = false
        }
    }
    
    // MARK: - Actions
    @objc func backButtonTapped() {
        navigationController?.popViewController(animated: true)
    }
    
    @objc func searchButtonTapped() {
        if self.fromePost {
            let searchStyleController = SearchStyleController()
            searchStyleController.searchType = .postTagBrand
            if let selectBrandCallback = self.didSelectBrandHandler {
                searchStyleController.didSelectBrandHandler = selectBrandCallback
            }
            self.navigationController?.pushViewController(searchStyleController, animated: false)
        } else {
            let searchViewController = ProductListSearchViewController()
            navigationController?.push(searchViewController, animated: false)
        }
    }
    
    override func segmentButtonClicked(_ sender: UIButton) {
        super.segmentButtonClicked(sender)
        
        let sourceRef = sender.tag == 0 ? "RedZone" : "BlackZone"
        view.recordAction(.Tap, sourceRef: sourceRef, sourceType: .Button, targetRef: "AllBrands", targetType: .View)
    }

    override func shouldHaveCollectionView() -> Bool {
        return false
    }
}
