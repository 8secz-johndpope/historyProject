//
//  MemberCardViewController.swift
//  merchant-ios
//
//  Created by Quang Truong Dinh on 2/7/17.
//  Copyright © 2017 WWE & CO. All rights reserved.
//

import Foundation

enum MemberCardType : Int{
    case unknown = 0,
    standard,
    ruby,
    silver,
    gold,
    platinum
    
    func spendingAmountToNextLevelMessage(_ currentPaymentTotal: Double) -> String{
        switch self{
        case .standard, .ruby, .silver, .gold:
            if let nextCardType = MemberCardType(rawValue: self.rawValue + 1){
                let filterLoyalties = LoyaltyManager.cachedLoyalties.filter{$0.loyaltyStatusId == nextCardType.rawValue}
                if let loyalty = filterLoyalties.first{
                    var message = String.localize("LB_CA_VIP_UPGRADE_SPENDING")
                    var remainingPaymentTotal = Int(loyalty.minimumPaymentTotal) - Int(currentPaymentTotal)
                    if remainingPaymentTotal < 0{
                        remainingPaymentTotal = 0
                    }
                    message = message.replacingOccurrences(of: "{0}", with: Double(remainingPaymentTotal).formatPriceWithoutCurrencySymbol() ?? "")
                    message = message.replacingOccurrences(of: "{1}", with: loyalty.loyaltyStatusName)
                    message.append(String.localize("LB_CA_MEMBERSHIP"))
                    return message + " >"
                }
                return ""
            }
            return ""
        case .platinum:
            return String.localize("LB_CA_VIP_UPGRADE_TOP_TIER")
        default:
            return ""
        }
    }

    func isShowVipRanking() -> Bool{
        switch self{
        case .unknown, .standard:
            return false
        default:
            return true
        }
    }
    
    func vipRanking() -> String{
        let rankingText = String.localize("LB_CA_VIP_RANKING")
        var rangeValue = ""
        switch self{
        case .standard:
            return ""
        case .ruby:
            rangeValue = "75-95%"
        case .silver:
            rangeValue = "55-75%"
        case .gold:
            rangeValue = "25-55%"
        case .platinum:
            rangeValue = "10%"
        default:
            rangeValue = ""
        }
        
        return rankingText + " " + rangeValue
    }
    
    func cardUrl() -> String{
        switch self{
        case .standard:
            return "http://okuwin.net/mymm/card.html" //TODO
        case .ruby:
            return "http://okuwin.net/mymm/card.html" //TODO
        case .silver:
            return "http://okuwin.net/mymm/card.html" //TODO
        case .gold:
            return "http://okuwin.net/mymm/card.html" //TODO
        case .platinum:
            return "http://okuwin.net/mymm/card.html" //TODO
        default:
            return ""
        }
    }
    
    func cardDetailUrl() -> String{
        switch self{
        case .standard:
            return "http://okuwin.net/mymm/detail.html" //TODO
        case .ruby:
            return "http://okuwin.net/mymm/detail.html" //TODO
        case .silver:
            return "http://okuwin.net/mymm/detail.html" //TODO
        case .gold:
            return "http://okuwin.net/mymm/detail.html" //TODO
        case .platinum:
            return "http://okuwin.net/mymm/detail.html" //TODO
        default:
            return ""
        }
    }
    
    func nameTextColor() -> UIColor{
        return UIColor.white
    }
    
    func cardTypeTextColor() -> UIColor{
        return UIColor.white
    }
    
    func cumulativeConsumptionColor() -> UIColor{
        switch self{
        case .standard:
            return UIColor.secondary3()
        default:
            return UIColor.white
        }
    }
    
    static func count() -> Int{
        return MemberCardType.platinum.rawValue
    }
}

class MemberCardViewController : MemberCardBaseViewController{
    
    var memberCardType = MemberCardType.unknown
    var cardTypeName = ""
    var paymentTotal: Double = 0
    
    private enum ViewSection: Int {
        case card = 0
        case privilege = 1
        
        static func count() -> Int{
            return ViewSection.privilege.rawValue + 1
        }
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        self.title = String.localize("LB_CA_VIP_PAGE_TITLE")
        
        let user = Context.getUserProfile()
        initDataSource(user)
        
        createBackButton()
        configCollectionView()
        setUpDataSource()
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        
        if loyalty == nil{
            self.showLoading()
        }
        
        
        initAnalyticsRecord()
    }

    func configCollectionView() {
        self.collectionView.backgroundColor = UIColor.primary2()
        self.collectionView.register(UICollectionViewCell.self, forCellWithReuseIdentifier: "Cell")
        self.collectionView.register(MemberCardCell.self, forCellWithReuseIdentifier: MemberCardCell.CellIdentifier)
        self.collectionView.register(PrivilegeCell.self, forCellWithReuseIdentifier: PrivilegeCell.CellIdentifier)
    }
    
    func initDataSource(_ user: User){
        loyalty = user.loyalty
        cardTypeName = user.loyalty?.loyaltyStatusName ?? ""
        paymentTotal = user.paymentTotal
        
        if let memberCardType = MemberCardType(rawValue: user.loyaltyStatusId){
            self.memberCardType = memberCardType
        }

        LoyaltyManager.handleGetLoyaltyPrivileges(success: { [weak self] (loyalties, privileges) in
            if let strongSelf = self{
                strongSelf.stopLoading()
                strongSelf.loyalty = LoyaltyManager.getLoyaltyById(strongSelf.memberCardType.rawValue)
                strongSelf.cardTypeName = strongSelf.loyalty?.loyaltyStatusName ?? ""
                strongSelf.setUpDataSource()
                strongSelf.collectionView?.reloadData()
            }
        }) { (errorType) in
        }
    }
    
    func reloadData(){
        setUpDataSource()
        
        collectionView?.reloadData()
        if let cv = collectionView {
            var excitingFrame = cv.frame
            let cvsize = cv.contentSize
            excitingFrame.size.height = cvsize.height
            DispatchQueue.main.async {
                self.collectionView?.frame = excitingFrame
            }
            
        }
        
    }
    
    func setUpDataSource(){
        sectionDatas.removeAll()
        for i in 0...(ViewSection.count() - 1){
            if let viewSection = ViewSection(rawValue: i){
                switch viewSection {
                case .card:
                    let memberCardData = MemberCardCellData(memberCardType: self.memberCardType)
                    memberCardData.paymentTotal = self.paymentTotal
                    memberCardData.cardTypeName = cardTypeName
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
        initAnalyticsViewRecord(viewLocation: "VIP-Dashboard-User", viewType: "VIP")
    }
    
    func numberOfSections(in collectionView: UICollectionView) -> Int {
        return sectionDatas.count
    }
    
    override func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int{
        return sectionDatas[section].count
    }
    
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, sizeForItemAt indexPath: IndexPath) -> CGSize {
        if let viewSection = ViewSection(rawValue: indexPath.section){
            switch viewSection {
            case .card:
                return CGSize(width: self.view.width, height: MemberCardCell.getHeight())
            case .privilege:
                var count = 0
                let cell = PrivilegeCell()
                cell.loyalty = loyalty
                count = cell.loyaltyPrivileges.count
                return CGSize(width: self.view.width, height: PrivilegeCell.getHeight(count))
            }
        }
        
        return CGSize.zero
    }
    
    override func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell{
        let cell = collectionView.dequeueReusableCell(withReuseIdentifier: "Cell", for: indexPath)
        let data = self.sectionDatas[indexPath.section][indexPath.row]
        if let data = data as? MemberCardCellData{
            if let cell = collectionView.dequeueReusableCell(withReuseIdentifier: MemberCardCell.CellIdentifier, for: indexPath) as? MemberCardCell{
                cell.data = data
                cell.bottomLabelDidTap = { [weak self] cell in
                    if let strongSelf = self{
                        let data = strongSelf.sectionDatas[indexPath.section][indexPath.row]
                        if let data = data as? MemberCardCellData{
                            let vc = MemberCardDetailViewController()
                            vc.memberCardType = data.memberCardType
                            vc.paymentTotal = data.paymentTotal
                            strongSelf.navigationController?.push(vc, animated: true)
                        }
                        
                        strongSelf.view.recordAction(.Tap, sourceType: .Link, targetRef: "VIPtiers", targetType: .View)
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
    
    func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
    }
}
