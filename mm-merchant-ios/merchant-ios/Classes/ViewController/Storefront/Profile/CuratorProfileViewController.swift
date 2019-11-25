//
//  CuratorProfileViewController.swift
//  merchant-ios
//
//  Created by khanh.nguyen on 6/7/16.
//  Copyright © 2016 WWE & CO. All rights reserved.
//

import Foundation

class CuratorProfileViewController: ProfileViewController {
    
    private final let WidthItemBar: CGFloat = 25
    private final let HeightItemBar: CGFloat = 25
    
    override func setupNavigationBarButtons() {
        super.setupNavigationBarButtons()
        
        let backBarItem = self.createBack(imageName: "back_wht", selector: #selector(ProfileViewController.onBackButton), size: CGSize(width: 30,height: HeightItemBar), left: -15, right: 0)
        let searchBarItem = self.createSearchButton(imageName: "search_wht", selectorName: "searchIconClicked", size: CGSize(width: WidthItemBar,height: 24), left: -21, right: 0)
        var leftButtonItems = [UIBarButtonItem]()
        leftButtonItems.append(backBarItem)
        leftButtonItems.append(searchBarItem)
        self.navigationItem.leftBarButtonItems = leftButtonItems
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        self.actionTargetType = AnalyticsActionRecord.ActionElement.Curator
    }
}
