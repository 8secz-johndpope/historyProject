//
//  SegmentedControlOptions.swift
//  NavigationItem
//
//  Created by Kam on 11/5/2017.
//  Copyright © 2017 MyMM. All rights reserved.
//

import UIKit

public struct SegmentedControlOptions {
    public static var enableSegmentControl = true
    public static var numOfPageCount = 2
    public static var segmentedTitles: [String] = ["Red", "Black"]
    public static var selectedTitleColors: [UIColor] = [UIColor.redColor(), UIColor.darkGrayColor()]
    public static var indicatorColors: [UIColor] = [UIColor.redColor(), UIColor.blackColor()]
    
    public static var deSelectedTitleColor = UIColor.lightGrayColor()
    public static var navigateToTabIndex = 0 /* default 0, assign your index for transtition*/
    public static var hasRedDot: [Bool]?
    public static var segmentButtonFontSize: CGFloat = 14
    public static var segmentButtonWidth: Int = 60
}
