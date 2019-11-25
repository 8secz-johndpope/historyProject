//
//  TutorialSplashController.swift
//  merchant-ios
//
//  Created by Tony Fung on 23/12/2016.
//  Copyright © 2016年 WWE & CO. All rights reserved.
//

import UIKit

class TutorialSplashController: UIViewController, UIScrollViewDelegate {
    
    @IBOutlet weak var nextButton: UIButton!
    @IBOutlet weak var pageControl: UIPageControl!
    @IBOutlet weak var titleLabel: UILabel!
    @IBOutlet weak var topConstraint: NSLayoutConstraint!
    @IBOutlet weak var bottomConstraint: NSLayoutConstraint!
    @IBOutlet weak var buttonHeightConstraint: NSLayoutConstraint!
    @IBOutlet weak var iconSpacingConstraint: NSLayoutConstraint!
    
    private let titleList = [
        "全球潮流 名牌直购",
        "美范生活 即刻拥有",
        "穿搭高手 分享心得",
        "对话品牌 轻松简单"
    ]
    
    private var currentIndex: Int = -1
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        nextButton.setTitle(String.localize("LB_CS_START_CHAT"), for: UIControlState())
        
        nextButton.accessibilityIdentifier = "TutorialSplashPage-UIBT_NEXT"
        titleLabel.accessibilityIdentifier = "TutorialSplashPage-UILB_TITLE"
        
        layoutScroll()
        
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        
        let designSpacing = CGFloat(667)
        let height = UIScreen.main.bounds.height
        let ratio = height / designSpacing
        
        topConstraint.constant *= ratio
        bottomConstraint.constant *= ratio
        buttonHeightConstraint.constant *= ratio
        iconSpacingConstraint.constant *= ratio
        
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
    }
    
    @IBAction func startClicked(_ sender: Any) {
        
        Context.setShownTutorialSpash()
        self.dismiss(animated: true, completion: nil)
        
    }
    
    func scrollViewDidScroll(_ scrollView: UIScrollView) {
        
        let width = scrollView.frame.size.width
        
        // calculate scroll over half
        let index = Int(floor(scrollView.contentOffset.x / width + 0.5))
        
        if index != currentIndex {
            layoutScroll(index)
        }
        
    }
    
    private func layoutScroll(_ index: Int = 0) {
        
        UIView.transition(
            with: titleLabel,
            duration: 0.3,
            options: [.transitionCrossDissolve],
            animations: {
                if index < self.titleList.count {
                    self.titleLabel.text = self.titleList[index]
                }
            },
            completion: nil
        )
        
        currentIndex = index
        pageControl.currentPage = currentIndex
        
    }
    
}
