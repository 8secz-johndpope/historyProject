//
//  AccountSettingBaseViewController.swift
//  merchant-ios
//
//  Created by Stephen Yuen on 13/6/2016.
//  Copyright © 2016 WWE & CO. All rights reserved.
//

import Foundation
import UIKit
import PromiseKit
import ObjectMapper

class AccountSettingBaseViewController: MmViewController {
    
    static let DefaultCellID = "DefaultCellID"
    
    var settingsDataList = [[SettingsData]]()
    var user = User()
    
    override func viewDidLoad() {
        super.viewDidLoad()

        self.view.backgroundColor = UIColor.white
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    // MARK: - Data
    
    func fetchUser() -> Promise<Any> {
        return Promise{ fulfill, reject in
            UserService.view() { [weak self] (response) in
                if let strongSelf = self {
                    if response.result.isSuccess {
                        if response.response?.statusCode == 200 {
                            strongSelf.user = Mapper<User>().map(JSONObject: response.result.value)!
                            fulfill("OK")
                        } else {
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
                }
            }
        }
    }
    
    // MARK: - Collection view
    
    func getDefaultCell(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        return collectionView.dequeueReusableCell(withReuseIdentifier: AccountSettingBaseViewController.DefaultCellID, for: indexPath)
    }
    
    // MARK: - Collection view data source methods
    
    func numberOfSections(in collectionView: UICollectionView) -> Int {
        return settingsDataList.count
    }
    
    override func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return settingsDataList[section].count
    }
    
    // MARK: - Collection View delegate methods
    
    func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        let settingsData : SettingsData = settingsDataList[indexPath.section][indexPath.item]
        if settingsData.title == String.localize("LB_CA_USERNAME") && user.isSocialNetworkAccount() {
            return
        }
        
        if let action = settingsData.action {
            action(indexPath)
        }
    }
    
    // MARK: - Collection view delegate flow layout methods
    
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, minimumInteritemSpacingForSectionAt section: Int) -> CGFloat {
        return 0.0
    }
    
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, minimumLineSpacingForSectionAt section: Int) -> CGFloat {
        return 0.0
    }

}
