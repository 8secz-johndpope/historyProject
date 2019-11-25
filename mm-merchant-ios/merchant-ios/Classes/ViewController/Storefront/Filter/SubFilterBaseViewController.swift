//
//  SubFilterBaseViewController.swift
//  merchant-ios
//
//  Created by Quang Truong Dinh on 11/28/16.
//  Copyright © 2016 WWE & CO. All rights reserved.
//

import Foundation

class SubFilterBaseViewController: MmViewController{
    
    let ButtonCellHeight: CGFloat = 60 + ScreenBottom
    
    var noItemView: UIView!
    var filterHeaderView: FilterHeaderView?
    var filterCollectionView: UICollectionView!
    var buttonCell = ButtonCell()
    
    weak var filterStyleDelegate: FilterStyleDelegate?
    
    var styles: [Style] = []
    
    var aggregations: Aggregations?
    var originalStyleFilter: StyleFilter?
    var styleFilter: StyleFilter?
    var styleFilterBackup: StyleFilter?
    var searchStyleFilter: StyleFilter?
    
    var isConfirmed = false
    
    var currentFilterSelectedAnimationData: FilterSelectedAnimationData?
    
    override func viewDidLoad() {
        super.viewDidLoad()
        createBackButton()
        
        createRightButton(String.localize("LB_CA_RESET"), action: #selector(self.reset))
        
        setupDismissKeyboardGesture()
    }
    
    override func viewWillAppear(_ animated: Bool){
        super.viewWillAppear(animated)
        updateNoItemView()
    }
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
    }
    
    func setupButtonCell() {
        buttonCell.frame = CGRect(x: self.view.bounds.minX, y: self.view.bounds.maxY - ButtonCellHeight - (self.navigationController?.navigationBar.frame.height)! - UIApplication.shared.statusBarFrame.size.height, width: view.width, height: ButtonCellHeight)
        buttonCell.layoutSubviews()
        buttonCell.button.setTitle(String.localize("LB_CA_CONFIRM"), for: UIControlState())
        buttonCell.itemLabel.text = ""
        buttonCell.button.addTarget(self, action: #selector(self.confirm), for: .touchUpInside)
        buttonCell.backgroundColor = UIColor.white
        buttonCell.isHidden = isHideSubmitButton()
        self.view.insertSubview(self.buttonCell, aboveSubview: self.collectionView)
    }
    
    func setupNoItemView() {
        let noOrderViewSize = CGSize(width: 90, height: 100)
        noItemView = UIView(frame: CGRect(x: (view.width - noOrderViewSize.width) / 2, y: (view.height + view.y - noOrderViewSize.height) / 2, width: noOrderViewSize.width, height: noOrderViewSize.height))
        noItemView.isHidden = true
        
        let boxImageViewSize = CGSize(width: 90, height: 70)
        let boxImageView = UIImageView(frame: CGRect(x: (noItemView.width - boxImageViewSize.width) / 2, y: 0, width: boxImageViewSize.width, height: boxImageViewSize.height))
        boxImageView.image = UIImage(named: "icon_empty_plp")
        noItemView.addSubview(boxImageView)
        
        let label = UILabel(frame: CGRect(x: 0, y: boxImageView.height + 10, width: noOrderViewSize.width, height: 20))
        label.textAlignment = .center
        label.formatSize(16)
        label.textColor = UIColor.secondary3()
        label.text = String.localize("LB_CA_CART_NOITEM")
        noItemView.addSubview(label)
        
        view.addSubview(noItemView)
    }
    
    func updateNoItemView() {
        noItemView.isHidden = hasDataSource()
    }
    
    func hasDataSource() -> Bool{
        return false
    }
    
    func isHideSubmitButton() -> Bool{
        return false
    }
    
    //MARK: - FilterHeaderView Delegate
    
    func didUpdateStyleFilter(_ styleFilter: StyleFilter?, filterType: FilterType){
    }
    
    // MARK: - Actions
    
    @objc func reset(_ sender: UIBarButtonItem) {
    }
    
    @objc func refresh(_ sender: Any) {
    }
    
    @objc func confirm(_ sender: UIButton) {
    }
    
    // MARK: - Helpers
    func isHiddenFilterHeader() -> Bool{
        if let styleFilter = self.styleFilter{
            return (styleFilter.filterTags.count == 0)
        }
        return true
    }
}
