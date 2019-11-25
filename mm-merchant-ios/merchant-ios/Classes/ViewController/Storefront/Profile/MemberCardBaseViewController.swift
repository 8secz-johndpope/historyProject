//
//  MemberCardBaseViewController.swift
//  merchant-ios
//
//  Created by Quang Truong Dinh on 3/9/17.
//  Copyright © 2017 WWE & CO. All rights reserved.
//

import Foundation

class MemberCardBaseViewController : MmViewController{
    var sectionDatas = [[Any]]()
    var bottomView = UIView()
    
    var loyalty: Loyalty?{
        didSet{
            self.loadDataForBottomView()
        }
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        setUpBottomView()
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        initAnalyticsRecord()
    }
    
    func initAnalyticsRecord() {
    }
    
    func setUpBottomView(){
        bottomView = UIView()
        bottomView.backgroundColor = UIColor.primary2()
        bottomView.frame = CGRect(x: 0, y: self.view.frame.height - 50, width: self.view.frame.width, height: 50)
        self.view.addSubview(bottomView)
        
        collectionView.frame = CGRect(x: 0, y: collectionView.frame.minY, width: collectionView.width, height: collectionView.frame.height - bottomView.height)
    }
    
    func loadDataForBottomView(){
        for subview in bottomView.subviews{
            if let subview = subview as? TextCell{
                subview.removeFromSuperview()
            }
        }
        
        guard let loyalty = self.loyalty, loyalty.footers.count > 0 else{
            return
        }
        
        var textWidth: CGFloat = 100
        let padding: CGFloat = 10
        let footerCount: CGFloat = CGFloat(loyalty.footers.count)
        if footerCount*textWidth + (footerCount - 1)*padding > bottomView.width{
            textWidth = (bottomView.width - (footerCount - 1)*padding)/footerCount
        }
        
        let leftPadding: CGFloat = (bottomView.width - textWidth*footerCount - padding*(footerCount - 1))/2
        for (index, footer) in loyalty.footers.enumerated(){
            let footerTextCellData = TextCellData(text: footer.translationCode)
            footerTextCellData.textColor = UIColor.secondary4()
            footerTextCellData.isFormattedUnderline = true
            
            let footerView = TextCell(frame: CGRect(x: leftPadding + CGFloat(index)*(textWidth + padding), y: (bottomView.height - 35)/2, width: textWidth, height: 35))
            footerView.tag = index
            footerView.data = footerTextCellData
            let tapGesture = UITapGestureRecognizer(target: self, action: #selector(MemberCardBaseViewController.bottomLinkDidTap))
            footerView.addGestureRecognizer(tapGesture)
            bottomView.addSubview(footerView)
        }
    }
    
    @objc func bottomLinkDidTap(_ gesture: UITapGestureRecognizer){
        if let view = gesture.view{
            guard view.tag < (self.loyalty?.footers ?? []).count else {
                return
            }
            
            let footer = (self.loyalty?.footers ?? [])[view.tag]
            let footerLink = LoyaltyManager.getFooterLink(footer)
            
            Navigator.shared.dopen(footerLink)
//            if let footerUrl = URL(string: footerLink){
//                let webViewController = WebViewController()
//                webViewController.url = footerUrl
//                webViewController.customTitle = footer.translationCode
//                webViewController.isTabBarHidden = true
//                self.navigationController?.push(webViewController, animated: true)
//            }
            
            self.view.recordAction(.Tap, sourceType: .Link, targetRef: "VIPdescription", targetType: .View)
        }
    }
}

extension MemberCardBaseViewController: PrivilegeCellDelegate{
    func privilegeCell(_ privilegeCell: PrivilegeCell, didSelectLoyaltyPrivilege loyaltyPrivilege: LoyaltyPrivilege) {
        if let privilegePageUrl = URL(string: LoyaltyManager.getLoyaltyPrivilegePageLink(loyaltyPrivilege)){
            Navigator.shared.dopen(privilegePageUrl.absoluteString)
//            let webViewController = WebViewController()
//            webViewController.url = privilegePageUrl
//            webViewController.customTitle = loyaltyPrivilege.privilege?.translationCode ?? ""
//            webViewController.isTabBarHidden = true
//            self.navigationController?.push(webViewController, animated: true)
        }
    }
}
