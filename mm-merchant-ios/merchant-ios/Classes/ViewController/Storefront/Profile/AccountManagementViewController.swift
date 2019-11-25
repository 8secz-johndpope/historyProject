//
//  AccountManagementViewController.swift
//  merchant-ios
//
//  Created by Stephen Yuen on 23/3/2016.
//  Copyright © 2016 WWE & CO. All rights reserved.
//

import Foundation
import UIKit
import PromiseKit

class AccountManagementViewController: AccountSettingBaseViewController, UINavigationControllerDelegate, MobileSignupViewControllerDelegate, PasswordSettingDelegate {
    
    private var userNameSettingsData: SettingsData!
    private var passwordSettingsData: SettingsData!
    private var mobileNumberSettingsData: SettingsData!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        self.title = String.localize("LB_CA_ACCT_MGMT")
        
        createBackButton()
        prepareSettingsData()
        setupSubViews()
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        
        self.navigationController?.setNavigationBarHidden(false, animated: false)
        showLoading()
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        
        updateUserView()
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        
        stopLoading()
    }

    // MARK: - Setup Views
    
    private func prepareSettingsData() {
        
        userNameSettingsData = SettingsData(title: String.localize("LB_CA_USERNAME"), hasDisclosureIndicator: false, action: { (indexPath) in
            
        })

        passwordSettingsData = SettingsData(title: String.localize("LB_CA_MY_ACCT_MODIFY_PW"), hasDisclosureIndicator: true, action: { (indexPath) in
            let passwordSettingViewController = PasswordSettingViewController()
            passwordSettingViewController.delegate = self
            self.navigationController?.push(passwordSettingViewController, animated: true)
        })
        
        mobileNumberSettingsData = SettingsData(title: String.localize("LB_CA_MY_ACCT_MODIFY_MOBILE"), hasDisclosureIndicator: true, action: { (indexPath) in
            let mobileSignupViewController = MobileSignupViewController()
            mobileSignupViewController.viewMode = .profile
            mobileSignupViewController.delegate = self
            self.navigationController?.push(mobileSignupViewController, animated: true)
        })
    }
    
    private func setupSubViews() {
        collectionView.register(PersonalInformationSettingMenuCell.self, forCellWithReuseIdentifier: PersonalInformationSettingMenuCell.CellIdentifier)
    }
    
    private func reloadAllData() {
        userNameSettingsData.value = user.userName
        
        mobileNumberSettingsData.value = StringHelper.formatPhoneNumber("\(user.mobileCode)\(user.mobileNumber)")
        
        var section1List = [SettingsData]()
        
        section1List.append(userNameSettingsData)
        
        if user.userSocialAccounts == nil || user.userSocialAccounts!.count == 0 || user.isPass == 1 {
            section1List.append(passwordSettingsData)
        }
        
        section1List.append(mobileNumberSettingsData)
        
        settingsDataList.removeAll()
        settingsDataList.append(section1List)
        
        collectionView.reloadData()
    }
		
    // MARK: - Data
    
    private func updateUserView() {
        firstly {
            return fetchUser()
        }.then { _ -> Void in
            self.reloadAllData()
        }.always {
            self.stopLoading()
        }.catch { _ -> Void in
            Log.error("error")
        }
    }
    
    // MARK: - Collection View Data Source methods
    
    override func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        let settingsData = settingsDataList[indexPath.section][indexPath.item]
        
        let cell = collectionView.dequeueReusableCell(withReuseIdentifier: PersonalInformationSettingMenuCell.CellIdentifier, for: indexPath) as! PersonalInformationSettingMenuCell
        
        cell.itemLabel.text = settingsData.title
        cell.valueLabel.text = settingsData.value
        cell.showBorder(settingsData.hasBorder)
		
		if settingsData.title == String.localize("LB_CA_USERNAME") && user.isSocialNetworkAccount() {
			cell.valueLabel.text = String.localize("LB_MY_ACCT_USERNAME_SNS_LOGIN")
		}
        cell.showDisclosureIndicator(settingsData.hasDisclosureIndicator)
		
        
        return cell
    }
    
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, sizeForItemAt indexPath: IndexPath) -> CGSize {
        return CGSize(width: view.width, height: PersonalInformationSettingMenuCell.DefaultHeight)
    }
    
    // MARK: - MobileSignupViewControllerDelegate
    
    func didUpdateMobile(isSuccess: Bool) {
        if isSuccess {
            Alert.alertWithSingleButton(self, title: "", message: String.localize("MSG_CA_MY_ACCT_CHANGE_MOBILE_SUC"), buttonString: String.localize("LB_CA_CONFIRM"))
        }
    }
    
    // MARK: - PasswordSettingDelegate
    
    func didUpdatePassword(isSuccess: Bool) {
        if isSuccess {
            showSuccAlert(String.localize("MSG_CA_MY_ACCT_CHANGE_PW_SUC"))
        }
    }
}
