//
//  OrderManagementCollectionViewController.swift
//  merchant-ios
//
//  Created by Gam Bogo on 7/18/16.
//  Copyright © 2016 WWE & CO. All rights reserved.
//

import Foundation
import UIKit

class OrderManagementCollectionViewController: MMPageViewController {
    
    var defaultViewMode: Constants.OmsViewMode = .all
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        title = String.localize("LB_CA_MY_ORDERS")
        
        createBackButton()
        
        segmentedTitles = [
            String.localize("LB_CA_OMS_TAB_ALL"),
            String.localize("LB_CA_UNPAID_ORDER_PENDING_PAYMENT"),
            String.localize("LB_CA_OMS_TAB_TO_BE_SHIPPED"),
            String.localize("LB_CA_OMS_TAB_TO_BE_RCVD"),
            String.localize("LB_CA_OMS_TAB_TO_BE_RATED"),
            String.localize("LB_CA_OMS_TAB_REFUND")
        ]
        
        let viewModes: [Constants.OmsViewMode] = [
            .all,
            .unpaid,
            .toBeShipped,
            .toBeReceived,
            .toBeRated,
            .afterSales
        ]
        
        var viewControllers: [UIViewController] = []
        
        for i in 0..<viewModes.count {
            if i == 1{
                let viewController = UnpaidOrderViewController()
                viewController.viewHeight = view.frame.maxY - tabBarHeight - SEGMENT_Y - SEARCHBAR_HEIGHT
                viewController.viewMode = viewModes[i]
                viewController.parentOrderManagementPage = self
                viewController.fromViewController = self
                viewControllers.append(viewController)
            }else{
                let viewController = OrderManagementViewController()
                viewController.viewHeight = view.frame.maxY - tabBarHeight - SEGMENT_Y - SEARCHBAR_HEIGHT
                viewController.parentOrderManagementPage = self
                viewController.viewMode = viewModes[i]
                viewController.fromViewController = self
                viewControllers.append(viewController)
            }
        }
        
        //默认选择
        if let viewMode = self.ssn_Arguments["viewMode"]?.int,let mode = Constants.OmsViewMode(rawValue:viewMode) {
            self.defaultViewMode = mode
        }
        
        
        if defaultViewMode != .all {
            initialIndex = defaultViewMode.rawValue
        }
        
        self.viewControllers = viewControllers
        
        backgroundColor = UIColor.backgroundGray()
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        
        initialIndex = nil

    }

    override func shouldHaveCollectionView() -> Bool {
        return false
    }
    
    func showView(_ viewMode: Constants.OmsViewMode) {
        selectTab(atIndex: viewMode.rawValue)
    }
    
    func getViewControler(_ viewMode: Constants.OmsViewMode) -> UIViewController?{
        if viewControllers?.indices.contains(viewMode.rawValue) ?? false{
            return viewControllers?[viewMode.rawValue]
        }
        
        return nil
    }
}
