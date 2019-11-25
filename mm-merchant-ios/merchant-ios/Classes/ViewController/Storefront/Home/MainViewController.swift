//
//  MainViewController.swift
//  merchant-ios
//
//  Created by Kam on 11/5/2017.
//  Copyright © 2017 WWE & CO. All rights reserved.
//

import UIKit

class MainViewController: PageViewController {

    override func viewDidLoad() {
        super.viewDidLoad()
        
        self.options = SegmentedControlOptions(
            enableSegmentControl: true,
            segmentedTitles: ["Red", "Black"],
            selectedTitleColors: [.redColor(), .darkGrayColor()],
            deSelectedTitleColor: .lightGrayColor(),
            indicatorColors: [.redColor(), .blackColor()],
            navigateToTabIndex: 1
        )
        
        let viewControllerA = MmViewController()
        let viewControllerB = MmViewController()
        self.viewControllers = [viewControllerA, viewControllerB]

        // Do any additional setup after loading the view.
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }

    override func pageViewDidChanged(index: Int) {
        Log.debug(index)
    }

}
