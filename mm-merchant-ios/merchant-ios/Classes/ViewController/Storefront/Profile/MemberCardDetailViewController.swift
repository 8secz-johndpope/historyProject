//
//  MemberCardDetailViewController.swift
//  merchant-ios
//
//  Created by Quang Truong Dinh on 2/8/17.
//  Copyright © 2017 WWE & CO. All rights reserved.
//

import Foundation

class MemberCardDetailViewController : MemberCardBaseViewController{
    
    private enum ViewSection: Int {
        case card = 0
        case privilege = 1
        
        static func count() -> Int{
            return ViewSection.privilege.rawValue + 1
        }
    }
    
    var memberCardType = MemberCardType.unknown
    var paymentTotal: Double = 0
    var memberCardDetailCellData = MemberCardDetailCellData()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        self.title = String.localize("LB_CA_VIP_TIERS_INTRO")
        
        createBackButton()
        configCollectionView()
        setUpDataSource(self.memberCardType, sliderCardType: self.memberCardType, memberCardTypes: [])
        
        self.showLoading()
        LoyaltyManager.handleGetLoyaltyPrivileges(success: { [weak self] (loyalties, privileges) in
            if let strongSelf = self{
                strongSelf.stopLoading()
                strongSelf.loyalty = LoyaltyManager.getLoyaltyById(strongSelf.memberCardType.rawValue)
                strongSelf.setUpDataSource(strongSelf.memberCardType, sliderCardType: strongSelf.memberCardType, memberCardTypes: LoyaltyManager.getMemberCardTypes())
                strongSelf.collectionView.reloadData()
            }
            }) { (errorType) in
        }
    }

    func configCollectionView() {
        self.collectionView.backgroundColor = UIColor.primary2()
        self.collectionView.register(MemberCardDetailCell.self, forCellWithReuseIdentifier: MemberCardDetailCell.CellIdentifier)
        self.collectionView.register(PrivilegeCell.self, forCellWithReuseIdentifier: PrivilegeCell.CellIdentifier)
    }
    
    func setUpDataSource(_ memberCardType: MemberCardType, sliderCardType: MemberCardType, memberCardTypes: [MemberCardType]){
        sectionDatas.removeAll()
        for i in 0...(ViewSection.count() - 1){
            if let viewSection = ViewSection(rawValue: i){
                switch viewSection {
                case .card:
                    let memberCardData = MemberCardDetailCellData(memberCardType: memberCardType)
                    memberCardData.siderCardType = sliderCardType
                    memberCardData.paymentTotal = paymentTotal
                    memberCardData.memberCardTypes = memberCardTypes
                    memberCardDetailCellData = memberCardData
                    sectionDatas.append([memberCardData])
                case .privilege:
                    if let loyalty = self.loyalty{
                       sectionDatas.append([loyalty])
                    }
                    
                }
            }
        }
    }
    
    override func initAnalyticsRecord() {
        initAnalyticsViewRecord(viewLocation: "VIPtiers", viewType: "VIP")
    }
    
    func numberOfSections(in collectionView: UICollectionView) -> Int {
        return sectionDatas.count
    }
    
    override func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int{
        return sectionDatas[section].count
    }
    
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, minimumInteritemSpacingForSectionAt section: Int) -> CGFloat {
        return 0.0
    }
    
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, minimumLineSpacingForSectionAt section: Int) -> CGFloat {
        return 0.0
    }
    
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, insetForSectionAt section: Int) -> UIEdgeInsets {
        return UIEdgeInsets.zero
    }
    
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, sizeForItemAt indexPath: IndexPath) -> CGSize {
        if let viewSection = ViewSection(rawValue: indexPath.section){
            switch viewSection {
            case .card:
                return CGSize(width: self.view.width, height: MemberCardDetailCell.getHeight())
            case .privilege:
                return CGSize(width: self.view.width, height: PrivilegeCell.getHeight(sectionDatas.count))
            }
        }
        
        return CGSize.zero
    }
    
    override func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell{
        let cell = collectionView.dequeueReusableCell(withReuseIdentifier: "Cell", for: indexPath)
        let data = self.sectionDatas[indexPath.section][indexPath.row]
        if let data = data as? MemberCardDetailCellData{
            if let cell = collectionView.dequeueReusableCell(withReuseIdentifier: MemberCardDetailCell.CellIdentifier, for: indexPath) as? MemberCardDetailCell{
                cell.data = data
                cell.didTapInCard = { [weak self] siderCardType, memberCardDetailCell in
                    if let strongSelf = self{
                        strongSelf.loyalty = LoyaltyManager.getLoyaltyById(siderCardType.rawValue)
                        strongSelf.setUpDataSource(strongSelf.memberCardType, sliderCardType: siderCardType, memberCardTypes: LoyaltyManager.getMemberCardTypes())
                        strongSelf.collectionView.reloadData()

                        var sourceReference = ""
                        switch siderCardType{
                        case .standard:
                            sourceReference = "Standard"
                        case .ruby:
                            sourceReference = "Ruby"
                        case .silver:
                            sourceReference = "Silver"
                        case .gold:
                            sourceReference = "Gold"
                        case .platinum:
                            sourceReference = "Platinum"
                        default:
                            break
                        }
                        
                        strongSelf.view.recordAction(.Tap, sourceRef: sourceReference, sourceType: .Button, targetRef: "VIPtier-Benefits", targetType: .View)
                    }
                }
                return cell
            }
        }
        else if let loyalty = data as? Loyalty{
            if let cell = collectionView.dequeueReusableCell(withReuseIdentifier: PrivilegeCell.CellIdentifier, for: indexPath) as? PrivilegeCell{
                cell.loyalty = loyalty
                cell.privilegeCellDelegate = self
                return cell
            }
        }
        
        return cell
    }
}

class MemberCardDetailCellData{
    var memberCardType = MemberCardType.unknown
    var siderCardType = MemberCardType.unknown
    var memberCardTypes = [MemberCardType]()
    var paymentTotal: Double = 0
    
    init(memberCardType: MemberCardType = MemberCardType.unknown) {
        self.memberCardType = memberCardType
        self.siderCardType = memberCardType
    }
}
