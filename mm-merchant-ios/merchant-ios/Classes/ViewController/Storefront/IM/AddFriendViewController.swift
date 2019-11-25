//
//  AddFriendViewController.swift
//  merchant-ios
//
//  Created by Tony Fung on 4/3/2016.
//  Copyright © 2016年 WWE & CO. All rights reserved.
//

import Foundation

private let reuseIdentifier = "FriendMenuViewCell"

class AddFriendViewController: MmViewController {
    
    var isPresenting = false
    
    enum RowType: Int {
        case searchUser
        case scanQR
        case weibo
        case phoneBook
        case inviteFriend
        case unKnown
    }
    
    private final let CellHeight : CGFloat = 54
    private var addFriendDatas : [[AddFriendData]] = []
    
    override func viewDidLoad() {
        super.viewDidLoad()
        self.title = String.localize("LB_CA_IM_FIND_USER_ADD")
        
        self.view.backgroundColor = UIColor.white
        self.createRightButton(String.localize("LB_CA_IM_MY_QR"), action:  #selector(AddFriendViewController.myQRCode))
        self.collectionView!.register(FriendMenuViewCell.self, forCellWithReuseIdentifier: "FriendMenuViewCell")
        
        createSectionData()
        
        if isPresenting {
            self.createLeftBarItem()
        }else {
            self.createBackButton()
        }
        
        initAnalyticLog()
    }

    func initAnalyticLog() {
        initAnalyticsViewRecord(
            viewLocation: "AddUser",
            viewType: "IM"
        )
    }
    
    private func createLeftBarItem() {
        let closeButton = UIButton(type: .custom)
        closeButton.setImage(UIImage(named: "icon_cross"), for: UIControlState())
        closeButton.frame = CGRect(x: self.view.frame.size.width - Constants.Value.BackButtonWidth, y: 0, width: Constants.Value.BackButtonWidth, height: Constants.Value.BackButtonHeight)
        closeButton.addTarget(self, action: #selector(dismiss(_:)), for: .touchUpInside)
        
        self.navigationItem.leftBarButtonItem = UIBarButtonItem(customView: closeButton)
    }
    
    @objc func dismiss(_ sender: Any) {
        self.dismiss(animated: true, completion: nil)
    }
    
    //MARK: Collection View methods and delegates
    override func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        if section < addFriendDatas.count {
            return addFriendDatas[section].count
        }
        return 0
    }
    
    func numberOfSections(in collectionView: UICollectionView) -> Int {
        return addFriendDatas.count
    }
    
    override func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        let cell = collectionView.dequeueReusableCell(withReuseIdentifier: "FriendMenuViewCell", for: indexPath) as! FriendMenuViewCell
        
        let currentSectionData = addFriendDatas[indexPath.section]
        let currentRowData = currentSectionData[indexPath.row]
        cell.textLabel.text = currentRowData.title
        cell.lowerLabel.text = currentRowData.subTitle
        cell.imageView.image = UIImage(named: currentRowData.iconImagePath)
        
        switch currentRowData.rowType {
        case .inviteFriend:
            cell.ImageWidth = 24
        default:
            cell.ImageWidth = 30
        }
        
        if currentRowData.rowType == .scanQR || currentRowData.rowType == .weibo {
            cell.borderView.isHidden = true
        }
        else {
            cell.borderView.isHidden = false
        }
        
        cell.viewReferralContain.isHidden = !self.isActiveIncentiveReferral()
        cell.analyticsViewKey = self.analyticsViewRecord.viewKey
        
        return cell
    }
    
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, sizeForItemAt indexPath: IndexPath) -> CGSize {
            return CGSize(width: self.view.frame.size.width , height: CellHeight)
    }
    
    
    func collectionView(_ collectionView: UICollectionView,
        layout collectionViewLayout: UICollectionViewLayout,
        insetForSectionAt section: Int) -> UIEdgeInsets {

            if section == 0 {
                return UIEdgeInsets(top: 20.0, left: 0.0, bottom: 0, right: 0.0)
            } else{
                return UIEdgeInsets(top: 40.0, left: 0.0, bottom: 0, right: 0.0)
            }
            
    }
    
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, minimumInteritemSpacingForSectionAt section: Int) -> CGFloat {
        if section == 0 {
            return 22
        } else{
            return 50
        }
        
    }
    
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, minimumLineSpacingForSectionAt section: Int) -> CGFloat {
        return 0.0
    }
    
    func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        
        let currentSectionData = addFriendDatas[indexPath.section]
        let currentRowData = currentSectionData[indexPath.row]
       
        switch currentRowData.rowType {
        case .scanQR:
            Utils.checkCameraPermissionWithCallBack({[weak self] (granted) in
                if let strongSelf = self, granted {
                    if let cell = collectionView.cellForItem(at: indexPath) {
                        cell.recordAction(
                            .Tap,
                            sourceRef: "ScanQRCode",
                            sourceType: .Button,
                            targetRef: "ScanQRCode",
                            targetType: .View
                        )
                    }
                    
                    let supportsMetadataObjectTypes = try? QRCodeReader.supportsMetadataObjectTypes()
                    if let value = supportsMetadataObjectTypes, value == true {
                        strongSelf.navigationController?.push(MMScanQRCodeController(), animated: true)
                    }
                }
            })
            
            
        case .searchUser:
            
            // Action tag
            if let cell = collectionView.cellForItem(at: indexPath) {
                cell.recordAction(
                    .Tap,
                    sourceRef: "Search-User",
                    sourceType: .Button,
                    targetRef: "Search-User",
                    targetType: .View
                )
            }
            
            self.navigationController?.push(SearchFriendViewController(), animated: true)
        case .weibo:
            
            // Action tag
            if let cell = collectionView.cellForItem(at: indexPath) {
                cell.recordAction(
                    .Tap,
                    sourceRef: "ScanWeibo",
                    sourceType: .Button,
                    targetRef: "ScanWeibo",
                    targetType: .View
                )
            }
            
            if Reachability.shared().currentReachabilityStatus() == NotReachable {
                Alert.alertWithSingleButton(self, title: "", message: String.localize("MSG_ERR_NETWORK_FAIL"), buttonString: String.localize("LB_CA_CONFIRM"))
                return
            }
            
            if WeiboSDK.isWeiboAppInstalled() {
                self.navigationController?.push(WeiboFriendViewController(), animated: true)
            } else {
                Alert.alertWithSingleButton(self, title: "", message: String.localize("MSI_ERR_SINAWEIBO_INSTALL"), buttonString:String.localize("LB_OK"))
            }
            
        case .phoneBook:
            
            // Action tag
            if let cell = collectionView.cellForItem(at: indexPath) {
                cell.recordAction(
                    .Tap,
                    sourceRef: "Scanphonebook",
                    sourceType: .Button,
                    targetRef: "Scanphonebook",
                    targetType: .View
                )
            }
            
            self.navigationController?.push(PhoneBookFriendsViewController(), animated: true)
        case .inviteFriend:
            
            // Action tag
            if let cell = collectionView.cellForItem(at: indexPath) {
                cell.recordAction(
                    .Tap,
                    sourceRef: "InviteUser",
                    sourceType: .Button,
                    targetRef: "InviteUser",
                    targetType: .View
                )
            }
            BannerManager.sharedManager.getCampaigns().then { (success) -> Void in
                if !success {
                    self.inviteFriend()
                }
            }
        default:
            break
            
        }
        
       
    }
    
    func inviteFriend() {
        let shareViewController = ShareViewController(screenCapSharing: false)
        
        shareViewController.viewKey = self.analyticsViewRecord.viewKey
        shareViewController.isSharingByInviteFriend = true
        shareViewController.didSelectSNSHandler = { method in
            let appName = Bundle.main.infoDictionary!["CFBundleDisplayName"] as? String ?? ""
            var title = String.localize("LB_CA_NATURAL_REF_SNS_MSG")
            title = title.replacingOccurrences(of: "{0}", with: appName)
            
            ShareManager.sharedManager.inviteFriend(title, description: String.localize("LB_CA_NATURAL_REF_SNS_DESC"), url: (EntityURLFactory.deepShareInvitationURL(Constants.Path.DeepLinkURL, referrerUserKey: Context.getUserKey())?.absoluteString)!, image: UIImage(named : "AppIcon"), method: method)
        }
        self.present(shareViewController, animated: false, completion: nil)
    }
    
    @objc func myQRCode (_ sender : UIBarButtonItem) {
        // Action tag
        self.view.analyticsViewKey = self.analyticsViewRecord.viewKey
        self.view.recordAction(
            .Tap,
            sourceRef: "MyQRCode",
            sourceType: .Button,
            targetRef: "MyQRCode",
            targetType: .View
        )
        MyQRCodeViewController.presentQRCodeController(self)
    }
    
    private func createSectionData() {
        
        var sectionDatas: [AddFriendData] = []
        sectionDatas.append(AddFriendData(rowType: .searchUser, title: String.localize("LB_CA_IM_SEARCH_USER"), subTitle: "", iconImagePath: "search_icon"))
        addFriendDatas.append(sectionDatas)
        
        var sectionDatas_1: [AddFriendData] = []
        sectionDatas_1.append(AddFriendData(rowType: .scanQR, title: String.localize("LB_CA_IM_SCAN_QR"), subTitle: String.localize("LB_CA_IM_SCAN_QR_NOTE"), iconImagePath: "scan_icon"))
        
        guard Constants.SNSFriendReferralEnabled else {
            addFriendDatas.append(sectionDatas_1)
            return
        }
        
        sectionDatas_1.append(AddFriendData(rowType: .weibo, title: String.localize("LB_CA_WEIBO_FRIEND"), subTitle: String.localize("LB_CA_WEIBO_FRIEND_NOTE"), iconImagePath: "icon_webio_add"))
        
        sectionDatas_1.append(AddFriendData(rowType: .phoneBook, title: String.localize("LB_CA_PHONEBOOK_FRIEND"), subTitle: String.localize("LB_CA_PHONEBOOK_FRIEND_NOTE"), iconImagePath: "icon_phonebook_add"))

        addFriendDatas.append(sectionDatas_1)
        
        var sectionDatas_2: [AddFriendData] = []
        sectionDatas_2.append(AddFriendData(rowType: .inviteFriend, title: String.localize("LB_CA_IM_INVITE_FRD"), subTitle: String.localize("LB_CA_NATURAL_REFERRAL_CAPTION"), iconImagePath: "icon_invite"))
        addFriendDatas.append(sectionDatas_2)    }
    
    func reloadDataSource() {
        self.collectionView.reloadData()
    }

    
    func isActiveIncentiveReferral() -> Bool{
        return false //TODO: Hardcode waiting API
    }
}

internal class AddFriendData: NSObject { //Only use in here so define inside AddFriendViewController
    var rowType: AddFriendViewController.RowType = AddFriendViewController.RowType.unKnown
    var title: String = ""
    var subTitle: String = ""
    var iconImagePath: String = ""
    init(rowType: AddFriendViewController.RowType, title: String, subTitle: String, iconImagePath: String) {
        super.init()
        self.rowType = rowType
        self.title = title
        self.subTitle = subTitle
        self.iconImagePath = iconImagePath
    }
}
