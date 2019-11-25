//
//  PrivilegeCell.swift
//  merchant-ios
//
//  Created by Quang Truong Dinh on 3/9/17.
//  Copyright © 2017 WWE & CO. All rights reserved.
//

import Foundation

protocol PrivilegeCellDelegate: NSObjectProtocol{
    func privilegeCell(_ privilegeCell: PrivilegeCell, didSelectLoyaltyPrivilege loyaltyPrivilege: LoyaltyPrivilege)
}

class PrivilegeCell : UICollectionViewCell, UICollectionViewDelegate, UICollectionViewDataSource, UICollectionViewDelegateFlowLayout {
    static let CellIdentifier = "PrivilegeCellID"
    static let DefaultHeight: CGFloat = 100
    static let PrivilegeSpacing: CGFloat = 15
    
    private enum CellSection: Int {
        case privilegeTitle = 0,
        privilegeDetail
        
        static func count() -> Int{
            return CellSection.privilegeDetail.rawValue + 1
        }
    }
    
    var collectionView = UICollectionView(frame: CGRect.zero, collectionViewLayout: UICollectionViewFlowLayout())
    
    var sectionDatas = [[Any]]()
    
    var loyalty: Loyalty?{
        didSet{
            if let loyalty = self.loyalty{
                self.loyaltyPrivileges = loyalty.loyaltyPrivileges
                
                self.setUpDataSource()
                
                self.collectionView.reloadData()
            }
        }
    }
    
    var loyaltyPrivileges = [LoyaltyPrivilege]()
    
    weak var privilegeCellDelegate: PrivilegeCellDelegate?
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        let layout: UICollectionViewFlowLayout = UICollectionViewFlowLayout()
        layout.sectionInset = UIEdgeInsets(top: 0, left: 0, bottom: 0, right: 0)
        layout.itemSize = CGSize(width: self.frame.width, height: 120)
        
        collectionView = UICollectionView(frame: frame, collectionViewLayout: layout)
        collectionView.backgroundColor = UIColor.white
        collectionView.register(PrivilegeItemCell.self, forCellWithReuseIdentifier: PrivilegeItemCell.CellIdentifier)
        collectionView.register(TextCell.self, forCellWithReuseIdentifier: TextCell.CellIdentifier)
        collectionView.delegate = self
        collectionView.dataSource = self
        self.addSubview(collectionView)
    }
    
    override func layoutSubviews() {
        super.layoutSubviews()
        collectionView.frame = CGRect(x: 0, y: 0, width: self.width, height: self.height)
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    func setUpDataSource(){
        sectionDatas.removeAll()
        for i in 0...(CellSection.count() - 1){
            if let cellSection = CellSection(rawValue: i){
                switch cellSection {
                case .privilegeTitle:
                    let titleData = TextCellData(text: loyalty?.titleTranslationCode ?? "")
                    titleData.textColor = UIColor.black
                    titleData.fontSize = 15
                    let subTitleData = TextCellData(text: loyalty?.subtitleTranslationCode ?? "")
                    subTitleData.textColor = UIColor.secondary4()
                    subTitleData.fontSize = 14
                    sectionDatas.append([titleData, subTitleData])
                case .privilegeDetail:
                    sectionDatas.append(loyaltyPrivileges)
                }
            }
        }
        
        collectionView.isHidden = (sectionDatas.count == 0)
    }
    
    func numberOfSections(in collectionView: UICollectionView) -> Int {
        return sectionDatas.count
    }
    
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int{
        return sectionDatas[section].count
    }
    
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, minimumInteritemSpacingForSectionAt section: Int) -> CGFloat {
        return 0.0
    }
    
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, minimumLineSpacingForSectionAt section: Int) -> CGFloat {
        if let cellSection = CellSection(rawValue: section){
            switch cellSection {
            case .privilegeDetail:
                return PrivilegeCell.PrivilegeSpacing
            default:
                break
            }
        }
        return 0.0
    }
    
    func collectionView(_ collectionView: UICollectionView,
                        layout collectionViewLayout: UICollectionViewLayout,
                        insetForSectionAt section: Int) -> UIEdgeInsets {
        if let cellSection = CellSection(rawValue: section){
            switch cellSection {
            case .privilegeTitle:
                return UIEdgeInsets(top: 15, left: 0, bottom: 30, right: 0)
            default:
                break
            }
        }
        return UIEdgeInsets.zero
    }
    
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, sizeForItemAt indexPath: IndexPath) -> CGSize {
        if let cellSection = CellSection(rawValue: indexPath.section){
            switch cellSection {
            case .privilegeTitle:
                return CGSize(width: self.width, height: 25)
            case .privilegeDetail:
                if let _ = self.sectionDatas[indexPath.section][indexPath.row] as? LoyaltyPrivilege{
                    return CGSize(width: self.width/4, height: PrivilegeItemCell.DefaultHeight)
                }
            }
        }
        
        return CGSize.zero
    }
    
    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell{
        let cell = UICollectionViewCell()
        let data = self.sectionDatas[indexPath.section][indexPath.row]
        if let data = data as? TextCellData{
            if let cell = collectionView.dequeueReusableCell(withReuseIdentifier: TextCell.CellIdentifier, for: indexPath) as? TextCell{
                cell.data = data
                return cell
            }
        }
        else if let loyaltyPrivilege = data as? LoyaltyPrivilege{
            if let cell = collectionView.dequeueReusableCell(withReuseIdentifier: PrivilegeItemCell.CellIdentifier, for: indexPath) as? PrivilegeItemCell{
                cell.loyaltyPrivilege = loyaltyPrivilege
                return cell
            }
        }
        
        return cell
    }
    
    func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        let data = self.sectionDatas[indexPath.section][indexPath.row]
        if let loyaltyPrivilege = data as? LoyaltyPrivilege{
            privilegeCellDelegate?.privilegeCell(self, didSelectLoyaltyPrivilege: loyaltyPrivilege)
        }
    }

    
    class func getHeight(_ count: Int) -> CGFloat{
        let privilegeRowCount: Int = Int(count / 4) + Int(count % 4)
        return PrivilegeCell.DefaultHeight + CGFloat(privilegeRowCount)*PrivilegeItemCell.DefaultHeight + (CGFloat(privilegeRowCount) - 1)*PrivilegeCell.PrivilegeSpacing
    }
}
