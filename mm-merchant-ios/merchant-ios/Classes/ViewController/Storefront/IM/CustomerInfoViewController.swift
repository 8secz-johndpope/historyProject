//
//  CustomerInfoViewController.swift
//  merchant-ios
//
//  Created by Vo Huy Hung on 5/24/16.
//  Copyright © 2016 WWE & CO. All rights reserved.
//

import UIKit
import PromiseKit
import ObjectMapper

class CustomerInfoViewController: MmViewController {
    
    private final let CustomerInfoCellID = "CustomerInfoCellID"
    private final let CustomerInfoHeaderViewID = "CustomerInfoHeaderViewID"
    private final let CustomerInfoFooterViewID = "CustomerInfoFooterViewID"
    
    var viewHeight = CGFloat(0)
    
    var conv : Conv?
    
    private var titlesAndDetails = [[[Any]]]()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        setupCollectionView()
        
        if let user = self.conv?.presenter {
            
            initAnalyticLog(user)
            
            firstly {
                return getCustomerInfo(user.userKey)
                }.then { _ in
                    self.collectionView.reloadData()
            }
        } else {
            ErrorLogManager.sharedManager.recordNonFatalError(withException: .NullPointer)
        }
    }
        
    func initAnalyticLog(_ user: User){
        initAnalyticsViewRecord(
            viewDisplayName: user.displayName,
            viewLocation: "CustomerInfo",
            viewRef: conv?.convKey,
            viewType: "IM"
        )
    }
    
    func setupCollectionView() {
        self.collectionView.frame = CGRect(x: collectionView.frame.origin.x, y: 0, width: collectionView.frame.width, height: viewHeight)
        
        self.collectionView.register(CustomerInfoCell.self, forCellWithReuseIdentifier: CustomerInfoCellID)
        self.collectionView.register(CustomerInfoHeaderView.self, forSupplementaryViewOfKind: UICollectionElementKindSectionHeader, withReuseIdentifier: CustomerInfoHeaderViewID)
        self.collectionView.register(UICollectionReusableView.self, forSupplementaryViewOfKind: UICollectionElementKindSectionFooter, withReuseIdentifier: CustomerInfoFooterViewID)
    }
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    // MARK: - Services
    func getCustomerInfo(_ userKey: String) -> Promise<Any> {
        return Promise { fulfill, reject in
            
            if let merchantId = self.conv?.merchantId {
                UserService.customerView(userKey, merchantId: merchantId) { [weak self] (response) in
                    if let strongSelf = self {
                        if response.result.isSuccess {
                            if response.response?.statusCode == 200 {
                                if let user = Mapper<User>().map(JSONObject: response.result.value) {
                                    var sessionKey = ""
                                    var sessionTime: Date
                                    var accountState = ""
                                    
                                    if strongSelf.conv!.isClosed() {
                                        sessionKey = String.localize("LB_CS_CHAT_SESSION_END")
                                        sessionTime = strongSelf.conv!.timestampClosed
                                    }
                                    else {
                                        sessionKey = String.localize("LB_CS_CHAT_SESSION_BEGINS")
                                        sessionTime = strongSelf.conv!.timestamp
                                    }
                                    
                                    switch user.statusID {
                                    case 1:
                                        accountState = String.localize("LB_USER_STATUS_DEL")
                                    case 2:
                                        accountState = String.localize("LB_USER_STATUS_ACTIVE")
                                    case 3:
                                        accountState = String.localize("LB_USER_STATUS_PENDING")
                                    case 4:
                                        accountState = String.localize("LB_USER_STATUS_INACTIVE")
                                    default:break
                                    }
                                    
                                    var strGender = String.localize("LB_NA")
                                    if user.gender == "M" {
                                        strGender = String.localize("LB_CA_GENDER_M")
                                    }
                                    else if user.gender == "F" {
                                        strGender = String.localize("LB_CA_GENDER_F")
                                    }
                                    
                                    strongSelf.titlesAndDetails = [
                                        [
                                            [String.localize("LB_GENDER"), strGender],
                                            [String.localize("LB_AGE"), user.age != 0 ? "\(user.age)" : String.localize("LB_NA")],
                                            [String.localize("LB_ACCOUNT"), accountState]
                                        ],
                                        [
                                            [String.localize("LB_REGISTERED_ON"), user.lastCreated],
                                            [sessionKey, sessionTime]
                                        ]
                                    ]
                                } else {
                                        ErrorLogManager.sharedManager.recordNonFatalError(withException: .FailToParseAPIResponse)
                                }
                                
                                fulfill("OK")
                            }
                            else {
                                var statusCode = 0
                                if let code = response.response?.statusCode {
                                    statusCode = code
                                }
                                
                                let error = NSError(domain: "", code: statusCode, userInfo: nil)
                                reject(error)
                            }
                        } else {
                            reject(response.result.error!)
                        }
                    } else {
                        ErrorLogManager.sharedManager.recordNonFatalError(withException: .NullPointer)
                    }
                    
                }
            } else {
                ErrorLogManager.sharedManager.recordNonFatalError(withException: .NullPointer)
            }
        }
    }
    
    // MARK: - CollectionView Data Source, Delegate Method
    func numberOfSections(in collectionView: UICollectionView) -> Int {
        return titlesAndDetails.count
    }
    
    override func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        
        if section < titlesAndDetails.count {
            
            let detailList = titlesAndDetails[section]
            return detailList.count
        }
        
        return 0
    }
    
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, referenceSizeForHeaderInSection section: Int) -> CGSize {
        
        switch section {
        case 0:
            return CGSize(width: self.view.bounds.width, height: 110)
        case 1:
            return CGSize(width: self.view.bounds.width, height: 20)
        default:
            return CGSize.zero
        }
    }
    
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, referenceSizeForFooterInSection section: Int) -> CGSize {
        let heightOfFooterView = CGFloat(15)
        return CGSize(width: self.view.bounds.width, height: heightOfFooterView)
    }
    
    func collectionView(_ collectionView: UICollectionView, viewForSupplementaryElementOfKind kind: String, at indexPath: IndexPath) -> UICollectionReusableView {
        
        if kind == UICollectionElementKindSectionHeader {
            
            let headerView = collectionView.dequeueReusableSupplementaryView(ofKind: kind, withReuseIdentifier: CustomerInfoHeaderViewID, for: indexPath) as! CustomerInfoHeaderView
            
            switch indexPath.section {
            case 0:
                headerView.customerInfoHeaderMode = CustomerInfoHeaderMode.avatar
                if let user = self.conv?.presenter {
                    headerView.usernameLabel.text = user.displayName
                    headerView.avatarImageView.mm_setImageWithURL(ImageURLFactory.URLSize128(user.profileImage, category: ImageCategory.user), placeholderImage : UIImage(named: Constants.ImageName.ProfileImagePlaceholder), contentMode: .scaleAspectFit)
                    
                    // Impresstion tag
                    let impressionType = user.userTypeString()
                    recordImpression(
                        impressionRef: user.userKey,
                        impressionType: impressionType,
                        impressionDisplayName: user.displayName,
                        merchantCode: self.conv?.merchantObject?.merchantCode,
                        positionComponent:  "CustomerDetailedInfo",
                        positionLocation: "CustomerInfo"
                    )
                } else {
                    ErrorLogManager.sharedManager.recordNonFatalError(withException: .NullPointer)
                }
                
            case 1:
                headerView.customerInfoHeaderMode = CustomerInfoHeaderMode.blank
                
            default: break
            }
            
            return headerView
            
        } else {
            let footerView = collectionView.dequeueReusableSupplementaryView(ofKind: kind, withReuseIdentifier: CustomerInfoFooterViewID, for: indexPath)
            if footerView.viewWithTag(1001) == nil && indexPath.section == 0 {
                let padding = CGFloat(15)
                let separatorView = UIImageView(frame:CGRect(x: padding, y: footerView.frame.height - 1, width: footerView.frame.width - padding*2, height: 1))
                separatorView.backgroundColor = UIColor.secondary1()
                separatorView.tag = 1001
                footerView.addSubview(separatorView)
            }
            
            return footerView
        }
    }
    
    override func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        let cell = collectionView.dequeueReusableCell(withReuseIdentifier: CustomerInfoCellID, for: indexPath) as! CustomerInfoCell
        
        let texts = titlesAndDetails[indexPath.section][indexPath.row]
        
        var detailStr = ""
        switch texts[1] {
        case is Date:
            let dateFormatter = DateFormatter()
            dateFormatter.dateFormat = "yyyy-MM-dd HH:mm:ss"
            detailStr = dateFormatter.string(from: texts[1] as! Date)
        default:
            detailStr = texts[1] as! String
        }
        
        cell.fillData(texts[0] as! String, detailStr: detailStr)
        
        return cell;
    }
    
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, sizeForItemAt indexPath: IndexPath) -> CGSize {
        
        if indexPath.section == 0 {
            return CGSize(width: view.frame.width, height: 30)
        }
        
        return CGSize(width: view.frame.width, height: 35)
    }
    
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, minimumInteritemSpacingForSectionAt section: Int) -> CGFloat {
        return 0.0
    }
    
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, minimumLineSpacingForSectionAt section: Int) -> CGFloat {
        return 0.0
    }
    
    func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
    }
}
