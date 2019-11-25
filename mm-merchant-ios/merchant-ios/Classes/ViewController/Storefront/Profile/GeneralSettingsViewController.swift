//
//  GeneralSettingsViewController.swift
//  merchant-ios
//
//  Created by Stephen Yuen on 7/4/2016.
//  Copyright © 2016 WWE & CO. All rights reserved.
//

import UIKit
import JPSVolumeButtonHandler

class GeneralSettingsViewController: AccountSettingBaseViewController {
    
    var sessionKeyData: SettingsData!

    override func viewDidLoad() {
        super.viewDidLoad()

        self.title = String.localize("LB_CA_GENERAL")
        
        createBackButton()
        prepareDataList()
        setupSubViews()
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }

    // MARK: - Setup Views
    
    private func prepareDataList() {
        let clearCacheSettingsData = SettingsData(title: String.localize("LB_CA_CLEAR_CACHE"), isAlertStyle: true, action: { (indexPath) in
            ImageCacheManager.clearCache()
            VideoFilesManager.shared.removeAllVideoCache()
            self.showSuccessPopupWithText(String.localize("LB_CA_CLEAR_CACHE_SUCCESS"))
        })
        
        let jPushSettingsData = SettingsData(title: "JPUSH ID")
        
        if Platform.DeveloperMode {
            if let registrationID = JPUSHService.registrationID() {
                jPushSettingsData.value = registrationID
            } else {
                jPushSettingsData.value = "N/A"
            }
            
            sessionKeyData = SettingsData(title: "Session Key", action: { (indexPath) in
                AnalyticsManager.sharedManager.send()
                AnalyticsManager.sharedManager.resetSendTimer()
                
                self.sessionKeyData.value = AnalyticsManager.sharedManager.getSessionKey()
                self.collectionView.reloadData()
            })
            sessionKeyData.value = AnalyticsManager.sharedManager.getSessionKey()
        }
        
        let appVersionSettingsData = SettingsData(title: String.localize("LB_AC_APP_VER"), action: { (indexPath) in
			
        })

        if let version = Bundle.main.object(forInfoDictionaryKey: "CFBundleShortVersionString") as? String,
            let buildVerion = Bundle.main.object(forInfoDictionaryKey: kCFBundleVersionKey as String) as? String {
            appVersionSettingsData.value = "\(version) (\(buildVerion))"
        } else {
            appVersionSettingsData.value = Constants.AppVersion
        }
        
        if Platform.DeveloperMode {
            if let show = Bundle.main.object(forInfoDictionaryKey: "SHOW_GIT_COMMIT_ID") as? String,
                let version = Bundle.main.object(forInfoDictionaryKey: "GIT_HEAD_COMMIT_ID") as? String,show == "SHOW" {
                let gitVersion = SettingsData(title: "Build Git Head", action: { (indexPath) in
                })
                gitVersion.value = version
                settingsDataList.append([clearCacheSettingsData, jPushSettingsData, sessionKeyData, appVersionSettingsData, gitVersion])
            } else {
                settingsDataList.append([clearCacheSettingsData, jPushSettingsData, sessionKeyData, appVersionSettingsData])
            }
        } else {
            if let show = Bundle.main.object(forInfoDictionaryKey: "SHOW_GIT_COMMIT_ID") as? String,
                let version = Bundle.main.object(forInfoDictionaryKey: "GIT_HEAD_COMMIT_ID") as? String,show == "SHOW" {
                let gitVersion = SettingsData(title: "Build Git Head", action: { (indexPath) in
                })
                gitVersion.value = version
                settingsDataList.append([clearCacheSettingsData, appVersionSettingsData, gitVersion])
            } else {
                settingsDataList.append([clearCacheSettingsData, appVersionSettingsData])
            }
        }
    }
    
    private func setupSubViews() {
        collectionView.register(CommonViewItemCell.self, forCellWithReuseIdentifier: CommonViewItemCell.CellIdentifier)
    }

    // MARK: - Collection View Data Source methods
    
    override func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        let settingsData = settingsDataList[indexPath.section][indexPath.item]
        let cell = collectionView.dequeueReusableCell(withReuseIdentifier: CommonViewItemCell.CellIdentifier, for: indexPath) as! CommonViewItemCell
        var cellStyle: CommonViewItemCell.CellStyle = .normal
        
        if settingsData.isAlertStyle {
            cellStyle = .alert
        }
        
        cell.itemLabel.text = settingsData.title
        cell.itemValue.text = settingsData.value
        
        cell.setCellStyle(cellStyle)
        
        // Only for General Settings
        cell.itemValue.lineBreakMode = .byTruncatingTail
        cell.itemValue.adjustsFontSizeToFitWidth = true
        cell.itemValue.minimumScaleFactor = 0.3
        cell.itemValue.numberOfLines = 2
        
        cell.showDisclosureIndicator(settingsData.hasDisclosureIndicator)
        cell.showBottomBorder(settingsData.hasBorder)
        
        return cell
    }
    
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, sizeForItemAt indexPath: IndexPath) -> CGSize {
        return CGSize(width: view.width, height: CommonViewItemCell.DefaultHeight)
    }
    
    // MARK: - Developer mode
    
    override func setupVolumeButtonHandler() {
        volumeButtonHandler = JPSVolumeButtonHandler(up: {
            self.volumeUpCount = self.volumeUpCount + 1
            
            if self.volumeUpCount == 3 {
                let alertController = UIAlertController(title: "Message", message: "Touch Pointer is enabled.", preferredStyle: .alert)
                alertController.view.tintColor = UIColor.alertTintColor()
                alertController.addAction(UIAlertAction(title: "OK", style: .default, handler: nil))
                self.present(alertController, animated: true, completion: nil)
            }
        }, downBlock: {
            self.volumeDownCount = self.volumeDownCount + 1
            if self.volumeDownCount == 3 {
                Constants.IsDeveloperMode = true
                
                let alertController = UIAlertController(title: "Message", message: "Developer mode is enabled.\n\n\n\(Constants.Path.Host)", preferredStyle: .alert)
                alertController.view.tintColor = UIColor.alertTintColor()
                alertController.addAction(UIAlertAction(title: "OK", style: .default, handler: nil))
                self.present(alertController, animated: true, completion: nil)
            }
        })
    }

}
