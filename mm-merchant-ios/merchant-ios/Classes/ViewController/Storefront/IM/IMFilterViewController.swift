//
//  IMFilterViewController.swift
//  merchant-ios
//
//  Created by Vo Huy Hung on 5/16/16.
//  Copyright © 2016 WWE & CO. All rights reserved.
//

import UIKit

enum FilterButtons : Int {
    case friend = 0
    case customer = 1
    case `internal` = 2
    case chatting = 3
    case closed = 4
    case follow = 5
}

class IMFilterViewController: MmViewController {
    
    private final let IMFilterCellID = "IMFilterCellID"
    private final let IMFilterHeaderViewID = "IMFilterHeaderViewID"
    private final let IMFilterFooterViewID = "IMFilterFooterViewID"
    
    private final let SummaryViewHeight = CGFloat(62)
    
    private var summaryLabel: UILabel!
    
    private let filterTitles = [String.localize("LB_CA_IM_FRD"), String.localize("LB_CA_IM_CUSTOMER"), String.localize("LB_CA_IM_INTERNAL"), String.localize("LB_AC_IM_CHATTING"), String.localize("LB_CLOSED"), String.localize("LB_CS_FOLLOW_UP")]
    
    var filterValues = IMFilterCache.sharedInstance.filterChat()
    var originalFilterValues = [Bool]()
    var enableStatus = [true, true, true, false, false, false]

    override func viewDidLoad() {
        super.viewDidLoad()
        
        initAnalyticsViewRecord(
            viewDisplayName: "ChatFilter",
            viewLocation: "ChatFilter",
            viewType: "IM"
        )

        originalFilterValues = filterValues
        
        // Do any additional setup after loading the view.
        setupNavigationBar()
        
        self.collectionView!.register(IMFilterCell.self, forCellWithReuseIdentifier: IMFilterCellID)
        self.collectionView!.register(IMFilterHeaderView.self, forSupplementaryViewOfKind: UICollectionElementKindSectionHeader, withReuseIdentifier: IMFilterHeaderViewID)
        self.collectionView!.register(UICollectionReusableView.self, forSupplementaryViewOfKind: UICollectionElementKindSectionFooter, withReuseIdentifier: IMFilterFooterViewID)
        
        updateEnableStatus()
        self.collectionView.reloadData()
        self.addSumView()
        self.updateSumView()
    }
    
    func addSumView() {
        
        let summaryView = { () -> UIView in
            
            let frame = CGRect(x: 0, y: self.collectionView.frame.maxY - SummaryViewHeight, width: self.collectionView.frame.width, height: SummaryViewHeight)
            
            let view = UIView(frame: frame)
            view.backgroundColor = UIColor.white
            
            let separatorView = { () -> UIView in
                
                let view = UIView(frame: CGRect(x: 0, y: 0, width: frame.width, height: 1))
                view.backgroundColor = UIColor.backgroundGray()
                
                return view
            } ()
            view.addSubview(separatorView)
            
            //
            let confirmButton = { () -> UIButton in
                
                let rightPadding = CGFloat(15)
                let buttonSize = CGSize(width: 105, height: 38)
                let xPos = frame.width - buttonSize.width - rightPadding
                let yPos = (frame.height - buttonSize.height) / 2
                
                let button = UIButton(type: .custom)
                button.frame = CGRect(x: xPos, y: yPos, width: buttonSize.width, height: buttonSize.height)
                button.setTitle(String.localize("LB_CA_CONFIRM"), for: UIControlState())
                button.addTarget(self, action: #selector(IMFilterViewController.confirmFilter), for: .touchUpInside)
                button.formatPrimary()
                return button
                
            } ()
            view.addSubview(confirmButton)
            
            //
            let summaryLabel = { () -> UILabel in
                
                let padding = CGFloat(15)
                let label = UILabel(
                    frame:
                    UIEdgeInsetsInsetRect(
                        CGRect(
                            x: 0,
                            y: 0,
                            width: frame.width - confirmButton.frame.width - 10,
                            height: frame.height
                        ),
                        UIEdgeInsets(top: 0, left: padding, bottom: 0, right: padding)
                    )
                    
                )
                label.textAlignment = .right
                label.formatSingleLine(14)
                return label
                
            } ()
            view.addSubview(summaryLabel)
            self.summaryLabel = summaryLabel
            
            return view
        } ()
        
        self.view.addSubview(summaryView)
    }
    
    func updateSumView() {
        let convNum : Int = WebSocketManager.sharedInstance().listConvFilter(filterValues).count
        self.summaryLabel.text = String.localize("LB_CA_CS_FILTER_CHATS").replacingOccurrences(of: "{0}", with: "\(convNum)")
    }
    
    @objc func confirmFilter() {
        
        // Action tag
        self.view.analyticsViewKey = self.analyticsViewRecord.viewKey
        self.view.recordAction(
            .Tap,
            sourceRef: "Confirm",
            sourceType: .Button,
            targetRef: "IMLanding-Agent",
            targetType: .View
        )
        
        IMFilterCache.sharedInstance.saveFilterChat(filterValues)
        
        for i in stride(from: 0, to: filterValues.count, by: 1) {
            let value = filterValues[i]
            if value != originalFilterValues[i] {
                
                self.view.analyticsViewKey = self.analyticsViewRecord.viewKey
                
                switch i {
                case FilterButtons.friend.rawValue:
                    self.view.recordAction(
                        .Tap,
                        sourceRef: !value ? "Friend-Checked" : "Friend-Unchecked",
                        sourceType: .Button,
                        targetRef: value ? "Friend-Checked" : "Friend-Unchecked",
                        targetType: .Button
                    )
                    break
                case FilterButtons.customer.rawValue:
                    self.view.recordAction(
                        .Tap,
                        sourceRef: !value ? "Customer-Checked" : "Customer-Unchecked",
                        sourceType: .Button,
                        targetRef: value ? "Customer-Checked" : "Customer-Unchecked",
                        targetType: .Button
                    )
                    break
                case FilterButtons.internal.rawValue:
                    self.view.recordAction(
                        .Tap,
                        sourceRef: !value ? "Internal-Checked" : "Internal-Unchecked",
                        sourceType: .Button,
                        targetRef: value ? "Internal-Checked" : "Internal-Unchecked",
                        targetType: .Button
                    )
                    break
                case FilterButtons.chatting.rawValue:
                    self.view.recordAction(
                        .Tap,
                        sourceRef: !value ? "Chatting-Checked" : "Chatting-Unchecked",
                        sourceType: .Button,
                        targetRef: value ? "Chatting-Checked" : "Chatting-Unchecked",
                        targetType: .Button
                    )
                    break
                case FilterButtons.closed.rawValue:
                    self.view.recordAction(
                        .Tap,
                        sourceRef: !value ? "Closed-Checked" : "Closed-Unchecked",
                        sourceType: .Button,
                        targetRef: value ? "Closed-Checked" : "Closed-Unchecked",
                        targetType: .Button
                    )
                    break
                case FilterButtons.follow.rawValue:
                    self.view.recordAction(
                        .Tap,
                        sourceRef: !value ? "Followup-Checked" : "Followup-Unchecked",
                        sourceType: .Button,
                        targetRef: value ? "Followup-Checked" : "Followup-Unchecked",
                        targetType: .Button
                    )
                    break
                    
                default:
                    break
                    
                }
            }
        }
        
        self.navigationController?.popViewController(animated: true)
    }
    
    func setupNavigationBar() {
        self.title = String.localize("LB_CA_FILTER")
        self.createBackButton()
        self.createRightButton(String.localize("LB_CA_FILTER_RESET"), action: #selector(handleRightButton))
    }
        
    @objc func handleRightButton() {
        
        // Action tag
        self.view.analyticsViewKey = self.analyticsViewRecord.viewKey
        self.view.recordAction(
            .Tap,
            sourceRef: "Reset",
            sourceType: .Button,
            targetRef: "ChatFilter",
            targetType: .View
        )
        
        filterValues = [false, false, false, false, false, false]
        updateEnableStatus()
        self.collectionView.reloadData()
        self.updateSumView()
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    

    // MARK: - CollectionView Data Source, Delegate Method
    
    func numberOfSections(in collectionView: UICollectionView) -> Int {
        return 2
    }
    
    override func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return 3
    }
    
    func collectionView(_ collectionView: UICollectionView, viewForSupplementaryElementOfKind kind: String, at indexPath: IndexPath) -> UICollectionReusableView {
        
        if kind == UICollectionElementKindSectionHeader {
            
            let headerView = collectionView.dequeueReusableSupplementaryView(ofKind: kind, withReuseIdentifier: IMFilterHeaderViewID, for: indexPath) as! IMFilterHeaderView
            
            switch indexPath.section {
            case 0:
                headerView.titleLabel.text = String.localize("LB_IM_CS_CHAT_TYPE")
                break
            default:
                headerView.titleLabel.text = String.localize("LB_IM_CS_CHAT_STATUS")
                break
            }
            return headerView
            
        } else {
            let footerView = collectionView.dequeueReusableSupplementaryView(ofKind: kind, withReuseIdentifier: IMFilterFooterViewID, for: indexPath)
            if footerView.viewWithTag(1001) == nil {
                let separatorView = UIImageView(frame:CGRect(x: 0, y: footerView.frame.height - 1, width: footerView.frame.width, height: 1))
                separatorView.backgroundColor = UIColor.secondary1()
                separatorView.tag = 1001
                footerView.addSubview(separatorView)
            }
            
            return footerView
        }
        
    }
    
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, referenceSizeForHeaderInSection section: Int) -> CGSize {
        let heightOfHeaderView = CGFloat(50)
        return CGSize(width: self.view.bounds.width, height: heightOfHeaderView)
    }
    
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, referenceSizeForFooterInSection section: Int) -> CGSize {
        let heightOfFooterView = CGFloat(15)
        return CGSize(width: self.view.bounds.width, height: heightOfFooterView)
    }

    override func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        let cell = collectionView.dequeueReusableCell(withReuseIdentifier: IMFilterCellID, for: indexPath) as! IMFilterCell
        
        let iIndex = indexPath.section*3 + indexPath.row
        cell.label.text = filterTitles[iIndex]
        cell.isSelected = filterValues[iIndex]
        cell.enable = enableStatus[iIndex]
        cell.reloadUI()
        
        return cell;
    }
    
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, sizeForItemAt indexPath: IndexPath) -> CGSize {
        
        let padding = CGFloat(20)
        return CGSize(width: (self.view.bounds.width - padding*4)/3 , height: 40)
    }
    
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, insetForSectionAt section: Int) -> UIEdgeInsets {
        let padding = CGFloat(20)
        return UIEdgeInsets(top: 0, left: padding, bottom: 0, right: padding)
    }
    
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, minimumInteritemSpacingForSectionAt section: Int) -> CGFloat {
        return 0.0
    }
    
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, minimumLineSpacingForSectionAt section: Int) -> CGFloat {
        return 0.0
    }
    
    func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {

        let pos : Int = indexPath.section * 3 + indexPath.row;
        if pos > 2 {
            if !enableStatus[pos] {
                return
            }
        }
        
        filterValues[pos] = !filterValues[pos]
        self.updateEnableStatus()
        
        collectionView.reloadData()
        self.updateSumView()
    }
    
    func updateEnableStatus() {
        
        if filterValues[FilterButtons.customer.rawValue] {
            enableStatus = [true, true, true, true, true, true]
        }
        else if filterValues[FilterButtons.internal.rawValue] {
            enableStatus = [true, true, true, true, false, true]
        }
        else if filterValues[FilterButtons.friend.rawValue] {
            enableStatus = [true, true, true, true, false, false]
        } else {
            enableStatus = [true, true, true, false, false, false]
        }
        
        if !filterValues[FilterButtons.customer.rawValue] {
            filterValues[FilterButtons.closed.rawValue] = false
        }

        if !filterValues[FilterButtons.customer.rawValue] && !filterValues[FilterButtons.internal.rawValue] {
            filterValues[FilterButtons.closed.rawValue] = false
            filterValues[FilterButtons.follow.rawValue] = false
        }
        
        if !filterValues[FilterButtons.friend.rawValue] && !filterValues[FilterButtons.customer.rawValue] && !filterValues[FilterButtons.internal.rawValue] {
            filterValues[FilterButtons.chatting.rawValue] = false
            filterValues[FilterButtons.closed.rawValue] = false
            filterValues[FilterButtons.follow.rawValue] = false
        }
    }

}
