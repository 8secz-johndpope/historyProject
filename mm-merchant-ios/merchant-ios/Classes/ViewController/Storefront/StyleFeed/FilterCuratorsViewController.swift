//
//  FilterCuratorsViewController.swift
//  merchant-ios
//
//  Created by khanh.nguyen on 6/9/16.
//  Copyright © 2016 WWE & CO. All rights reserved.
//

import UIKit

import PromiseKit
import ObjectMapper

enum FilterCuratorMode : Int {
    case recommended = 0
    case popular = 1
}

class FilterCuratorsViewController: MMPageViewController {
    
    private final let SubCatCellId = "SubCatCell"
    
    private final var bottomBorder = CALayer()
    
    private var recommendList = [Curator]()
    private var popularList = [Curator]()
    
    private final let CatCellMarginLeft : CGFloat = 5//20
    private final let CatCellSpacing : CGFloat = 0
    private var tabLabel : UILabel = UILabel()
    private var marginLeft = CGFloat(0)
    private var nextIndex = 0
    
    private var isEndDecelerating = false
    private var isDrag = false
    private var bottomPadding = CGFloat(9)
    private var startPoint = CGFloat(0)
    
    
    override func viewDidLoad() {
        super.viewDidLoad()
        self.initUI()
        
        let height = self.view.frame.maxY - (SEGMENT_Y + SEGMENT_HEIGHT) - tabBarHeight
        
        let curatorRecommendedController = CuratorCollectionViewController()
        curatorRecommendedController.filterMode = .recommended
        curatorRecommendedController.viewHeight = height
        
        let curatorPopularController = CuratorCollectionViewController()
        curatorPopularController.filterMode = .popular
        curatorPopularController.viewHeight = height
        
        self.viewControllers = [curatorRecommendedController, curatorPopularController]
        self.segmentedTitles = [String.localize("LB_CA_CURATOR_FILTER_RECOMM"), String.localize("LB_CA_CURATOR_FILTER_FOLLOWERS")]
    }
    
    func initUI() -> Void {
        tabLabel.formatSmall()
        self.createBackButton()
        self.title = String.localize("LB_CA_CURATOR_ALL")
    }

    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
    }
    
    override func createBackButton() {
        super.createBackButton()
    }
    
    
    override func shouldHaveCollectionView() -> Bool {
        return false
    }
    
    override func segmentButtonClicked(_ sender: UIButton!) {
        super.segmentButtonClicked(sender)
        self.actionLog()
    }
    
    private func actionLog() {
        var sourceRef = ""
        var targetRef = ""
        
        switch self.nextIndex {
        case FilterCuratorMode.recommended.rawValue:
            sourceRef = "Recommended"
            targetRef = "AllCurators-Recommended"
            break
        case FilterCuratorMode.popular.rawValue:
            sourceRef = "MostFollowers"
            targetRef = "AllCurators-MostFollowers"
            break
        default:
            break
        }
        
        self.view.recordAction(
            .Tap,
            sourceRef: sourceRef,
            sourceType: .View,
            targetRef: targetRef,
            targetType: .View
        )
    }
}
