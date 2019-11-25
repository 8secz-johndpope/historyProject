//
//  SuggestionViewHeader.swift
//  merchant-ios
//
//  Created by Vu Dinh Trung on 7/21/16.
//  Copyright © 2016 WWE & CO. All rights reserved.
//

import UIKit

class SuggestionViewHeader: UICollectionReusableView,SegmentedControlDelegate {
    
    static let SuggestionViewHeaderId = "SuggestionViewHeaderId"
    var descriptionLabel : UILabel!
    weak var delegate: SegmentedControlDelegate?

    
    private final let HeightLabel = CGFloat(21)
    struct SegmentedControlOptions {
        var enableSegmentControl: Bool
        var segmentedTitles: [String]?
        var selectedTitleColors: [UIColor]?
        var deSelectedTitleColor: UIColor
        var indicatorColors: [UIColor]?
        var hasRedDot: [Bool]?
        var segmentButtonFontSize: CGFloat
        var navigateToTabIndex: Int
        var segmentButtonWidth: Int?
        
        init(enableSegmentControl: Bool, segmentedTitles: [String]? = nil, selectedTitleColors: [UIColor]? = nil, deSelectedTitleColor: UIColor? = nil, indicatorColors: [UIColor]? = nil, hasRedDot: [Bool]? = nil, segmentButtonFontSize: CGFloat? = nil, navigateToTabIndex: Int? = nil, segmentButtonWidth: Int? = nil) {
            self.enableSegmentControl = enableSegmentControl
            self.segmentedTitles = segmentedTitles
            self.selectedTitleColors = selectedTitleColors
            self.deSelectedTitleColor = deSelectedTitleColor ?? UIColor.lightGray
            self.indicatorColors = indicatorColors
            self.hasRedDot = hasRedDot // nil means no red dot
            self.segmentButtonFontSize = segmentButtonFontSize ?? 14
            self.navigateToTabIndex = navigateToTabIndex ?? 0 /* default 0, assign your index for transtition*/
            self.segmentButtonWidth = segmentButtonWidth
        }
    }
    var options: SegmentedControlOptions?
    
    lazy var stepOne:SuggestionSelectView = {
        let stepOne = SuggestionSelectView()
        return stepOne
    }()
    
    lazy var controlView:SegmentedControlView = {
        self.options = SegmentedControlOptions(
            enableSegmentControl: true,
            segmentedTitles: [String.localize("相似商品"), String.localize("最新商品")],
            selectedTitleColors: [UIColor.secondary15(), UIColor.secondary15()],
            deSelectedTitleColor: UIColor.secondary16(),
            indicatorColors: [UIColor.primary1(), UIColor.primary1()],
            navigateToTabIndex: 0,
            segmentButtonWidth: 80
        )
       let controlView = SegmentedControlView(
            frame: CGRect(x: self.frame.width * 0.2 * 0.5, y: 0, width: self.frame.width * 0.8, height: self.frame.height),
            segmentedTitles: options!.segmentedTitles!,
            hasRedDot: options!.hasRedDot,
            segmentButtonFontSize: options!.segmentButtonFontSize,
            selectedTitleColors: options!.selectedTitleColors!,
            deSelectedTitleColor: options!.deSelectedTitleColor,
            indicatorColors: options!.indicatorColors!
        )
        controlView.delegate = self
//        controlView.updateIndicator()
//        controlView.layoutSubviews()
        return controlView
    }()
    
    func segmentButtonClicked(_ sender: UIButton) {
//        controlView.currentPageIndex = sender.tag
        controlView.nextPageIndex = sender.tag
        
        controlView.isPageScrollingFlag = false
        controlView.updateIndicator()
        delegate?.segmentButtonClicked?(sender)
    }
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        backgroundColor = UIColor.white
        
//        let descripLabel = { () -> UILabel in
//            let label = UILabel(frame: CGRect(x: bounds.minX , y: (bounds.height - HeightLabel)/2, width: bounds.width, height: HeightLabel))
//            descriptionLabel = label
//            return label
//        }()
//        descriptionLabel.formatSize(15)
//        descriptionLabel.textColor = UIColor.secondary2()
//        descriptionLabel.textAlignment = .center
//        descriptionLabel.text = String.localize("LB_CA_NEW_PRODUCTS")
//        addSubview(descripLabel)
//
        addSubview(controlView)
    }
    override func layoutSubviews() {
        super.layoutSubviews()
        
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}

class SuggestionSelectView: UIView {
    override init(frame: CGRect) {
        super.init(frame: frame)
        
        self.addSubview(label)
        self.addSubview(lineView)
        
        label.snp.makeConstraints { (make) in
            make.center.equalTo(self)
        }
        lineView.snp.makeConstraints { (make) in
            make.top.equalTo(label.snp.bottom)
            make.width.equalTo(label)
            make.height.equalTo(0.5)
            make.center.equalTo(label)
        }
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    lazy var label:UILabel = {
        let label = UILabel()
        label.text = "最新商品"
        return label
    }()
    lazy var lineView:UIView = {
        let lineView = UIView()
        lineView.backgroundColor = .red
        return lineView
    }()
}
