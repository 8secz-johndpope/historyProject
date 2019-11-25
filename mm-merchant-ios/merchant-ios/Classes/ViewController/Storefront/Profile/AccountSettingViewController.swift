//
//  AccountSettingViewController.swift
//  merchant-ios
//
//  Created by Stephen Yuen on 18/3/2016.
//  Copyright © 2016 WWE & CO. All rights reserved.
//

import UIKit
import PromiseKit
import ObjectMapper

import StoreKit

class AccountSettingViewController: AccountSettingBaseViewController, SKStoreProductViewControllerDelegate {
    
    enum SectionType: Int {
        case personalInformation = 0,
        appInformation = 1,
        logoutSection = 2
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        self.title = String.localize("LB_CA_SETTINGS")
        
        createBackButton()

        prepareDataList()
        setupSubViews()
        
        initAnalyticsViewRecord(viewDisplayName: "MyAccount", viewParameters: nil, viewLocation: "MyAccount", viewType: "User")
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    // MARK: - Setup Views
    
    private func prepareDataList() {
        var settingFirstSection = [
            SettingsData(title: String.localize("LB_CA_PERSONAL_INFO"), imageName: "icon_personal_info", action: { [weak self] (indexPath) in
                if let strongSelf = self {
                    strongSelf.navigationController?.push(PersonalInformationSettingViewController(), animated: true)
                }
            }),
            SettingsData(title: String.localize("LB_CA_ACCT_MGMT"), imageName: "icon_acct_mgmt", action: {[weak self] (indexPath) in
                self?.navigationController?.push(AccountManagementViewController(), animated: true)
            }),
            SettingsData(title: String.localize("LB_CA_SHIPPING_ADDR"), imageName: "icon_shipping_addr", action: {[weak self] (indexPath) in
                let addressListViewController = AddressSelectionViewController()
                addressListViewController.viewMode = .profile
                self?.navigationController?.push(addressListViewController, animated: true)
            }),
            
            SettingsData(title: String.localize("LB_CA_MY_REVIEW_ALL"), imageName: "icon_review", action: {[weak self] (indexPath) in
                self?.navigationController?.push(MyReviewViewController(), animated: true)
            })
        ]
        
        if isCurator() {
            let curatorSetting = SettingsData(title: String.localize("LB_CA_CURATOR_SETTING"), imageName: "MMcurator_icon", action: {[weak self] (indexPath) in
                self?.navigationController?.push(CuratorSettingViewController(), animated: true)
            })
            settingFirstSection.insert(curatorSetting, at: 1)
        }
        
        settingsDataList.append(settingFirstSection)
        
        settingsDataList.append([
            SettingsData(title: String.localize("LB_CA_ABOUT"), action: {[weak self] (indexPath) in
                self?.navigationController?.push(AboutViewController(), animated: true)
            }),
			
            SettingsData(title: String.localize("LB_CA_MY_ACCT_CONTACT_US"), action: {[weak self] (indexPath) in
				if let url = ContentURLFactory.urlForContentType(.mmContactUs) {
					self?.navigationController?.push(ContactUsDetailViewController(title: String.localize("LB_CA_MY_ACCT_CONTACT_US"), urlGetContentPage: url, push: false), animated: true)
				}
            }),
			
			SettingsData(title: String.localize("LB_CA_MM_RATING"), action: {[weak self] (indexPath) in //TODO: re-enable AppStore rating entry after submitted to AppStore
				self?.openStoreProductWithiTunesItemIdentifier(Constants.AppID);
			}),
			
            SettingsData(title: String.localize("LB_CA_GENERAL"), action: {[weak self] (indexPath) in
                self?.navigationController?.push(GeneralSettingsViewController(), animated: true)
            })
        
        ])
        
        settingsDataList.append([
			
            SettingsData(title: String.localize("LB_CA_PROF_LOGOUT"), action: { (indexPath) in
                
            })
            
        ])
		
    }
	
	func openStoreProductWithiTunesItemIdentifier(_ identifier: String) {
		let storeViewController = SKStoreProductViewController()
		storeViewController.delegate = self
		
		let parameters = [ SKStoreProductParameterITunesItemIdentifier : identifier]
		
		self.showLoading()
		
		var hasReturned = false
		
		storeViewController.loadProduct(withParameters: parameters) { [weak self] (loaded, error) -> Void in
            if let strongSelf = self {
                hasReturned = true
                
                strongSelf.stopLoading()
                
                if loaded {
                    // Parent class of self is UIViewContorller
                    strongSelf.present(storeViewController, animated: true, completion: nil)
                }
            }
		}

		// in case fail to open app store link time out in 5 seconds
		let delayTime = DispatchTime.now() + Double(Int64(5.0 * Double(NSEC_PER_SEC))) / Double(NSEC_PER_SEC)
		DispatchQueue.main.asyncAfter(deadline: delayTime) {
			if !hasReturned {
				self.stopLoading()
			}
		}

	}
	
	func productViewControllerDidFinish(_ viewController: SKStoreProductViewController) {
		viewController.dismiss(animated: true, completion: nil)
	}
	
    private func setupSubViews() {
        if let navigationController = navigationController  {
            
            let statusBarHeight = UIApplication.shared.statusBarFrame.height
            let navigationBarHeight = navigationController.navigationBar.height + statusBarHeight
            collectionView.frame = CGRect(x: 0, y: navigationBarHeight, width: self.view.width, height: self.view.height - tabBarHeight - navigationBarHeight)
        }
        
        collectionView.register(AccountSettingCell.self, forCellWithReuseIdentifier: AccountSettingCell.CellIdentifier)
        collectionView.register(CommonViewItemCell.self, forCellWithReuseIdentifier: CommonViewItemCell.CellIdentifier)
        
        collectionView.register(LogoutFooterView.self, forCellWithReuseIdentifier: LogoutFooterView.LogoutFooterViewID)

        
    }
    
    func isCurator() -> Bool {
        return (user.isCurator == 1)
    }
    
    override func collectionViewBottomPadding() -> CGFloat {
        return Constants.BottomButtonContainer.Height
    }
    
    // MARK: - Action
    private func logoutAction() {
        
        self.view.recordAction(.Logout, sourceRef: Context.getUsername(), sourceType: .User, targetRef: Context.getUserKey(), targetType: .User)
        
        if let registrationID = JPUSHService.registrationID(), Context.getUserKey() != "" && LoginManager.getLoginState() == .validUser {
            UserService.updateDevice(
                nil,
                deviceIdPrevious: registrationID,
                completion: nil
            )
        }
        
        LoginManager.logout()
        let user = Context.getUserProfile()
        user.isGuest = false //It means the user is logged out user, not guest user
        Context.saveUserProfile(user)
        
        LoginManager.goToStorefront()
    }
    
    private func showPopupConfirmLogout() {
        
        let optionMenu = UIAlertController(title: String.localize("LB_CA_LOGOUT_PROMPT"), message: nil, preferredStyle: .actionSheet)
        optionMenu.view.tintColor = UIColor.alertTintColor()
        let confirmAction = UIAlertAction(title: String.localize("LB_CONFIRM"), style: .default, handler: {[weak self] (alert: UIAlertAction!) -> Void in
            if let strongSelf = self {
                strongSelf.logoutAction()
            }
            
        })
        
        let cancelAction = UIAlertAction(title: String.localize("LB_CANCEL"), style: .cancel, handler: nil)
        
        optionMenu.addAction(confirmAction)
        optionMenu.addAction(cancelAction)
        
        optionMenu.view.tintColor = UIColor.secondary2()
        
        self.present(optionMenu, animated: true, completion: nil)
        optionMenu.view.tintColor = UIColor.secondary2()
        
    }

    
    // MARK: - Collection View Data Source methods
    

    
    override func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        let settingsData = settingsDataList[indexPath.section][indexPath.item]
        
        if let sectionType = SectionType(rawValue: indexPath.section) {
            switch sectionType {
            case .personalInformation:
                let cell = collectionView.dequeueReusableCell(withReuseIdentifier: AccountSettingCell.CellIdentifier, for: indexPath) as! AccountSettingCell
                
                cell.titleLabel.text = settingsData.title
                
                if settingsData.imageName != nil {
                    cell.setImage(imageName: settingsData.imageName!)
                }
                
                cell.showBorder(settingsData.hasBorder)
                
                return cell
            case .appInformation:
                let cell = collectionView.dequeueReusableCell(withReuseIdentifier: CommonViewItemCell.CellIdentifier, for: indexPath) as! CommonViewItemCell
                
                cell.itemLabel.text = settingsData.title
                cell.showTopBorder((indexPath.item == 0))
                cell.showBottomBorder(settingsData.hasBorder)
                cell.showDisclosureIndicator(true)
                
                return cell
                
            case .logoutSection:
                let cell = collectionView.dequeueReusableCell(withReuseIdentifier: LogoutFooterView.LogoutFooterViewID, for: indexPath) as! LogoutFooterView
                
                
                cell.logoutCompletionHandler = {[weak self] in
                    if let strongSelf = self {
                        strongSelf.showPopupConfirmLogout()
                    }
                }
                return cell
            }
        }
        
        return getDefaultCell(collectionView, cellForItemAt: indexPath)
    }
    
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, insetForSectionAt section: Int) -> UIEdgeInsets {
        if let sectionType = SectionType(rawValue: section), sectionType == .appInformation {
            return UIEdgeInsets(top: 22.0, left: 0.0, bottom: 0.0, right: 0.0)
        } else {
            return UIEdgeInsets.zero
        }
    }
    
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, sizeForItemAt indexPath: IndexPath) -> CGSize {
        if let sectionType = SectionType(rawValue: indexPath.section) {
            switch sectionType {
            case .personalInformation:
                return CGSize(width: view.width, height: AccountSettingCell.DefaultHeight)
            case .appInformation:
                return CGSize(width: view.width, height: CommonViewItemCell.DefaultHeight)
            case .logoutSection:
                return CGSize(width: collectionView.frame.sizeWidth, height: Constants.BottomButtonContainer.Height)
            }
        }
        
        return CGSize.zero
    }
    
}



class LogoutFooterView: UICollectionViewCell {
    
    
    static let LogoutFooterViewID = "LogoutFooterViewID"
    
    var bottomButtonContainer : UIView!
    var bottomButton : UIButton!
    
    var logoutCompletionHandler : (()->())?
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        
        createBottomButton(String.localize("LB_CA_PROF_LOGOUT"), customAction: #selector(LogoutFooterView.bottomButtonAction), useSecondaryStyle: true)
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    
    func createBottomButton(_ title: String, customAction: Selector?, useSecondaryStyle: Bool = false) {
        bottomButtonContainer = UIView()
        bottomButton = UIButton()
        bottomButton.accessibilityIdentifier = "bottom_button"
        bottomButtonContainer!.frame = CGRect(
            x: 0,
            y: 0,
            width: frame.size.width,
            height: Constants.BottomButtonContainer.Height
        )
        
        bottomButton!.frame = CGRect(
            x: Constants.BottomButtonContainer.MarginHorizontal,
            y: Constants.BottomButtonContainer.MarginVertical,
            width: (bottomButtonContainer?.frame.size.width)! - (Constants.BottomButtonContainer.MarginHorizontal * 2),
            height: (bottomButtonContainer?.frame.size.height)! - (Constants.BottomButtonContainer.MarginVertical * 2)
        )
        
        if useSecondaryStyle {
            bottomButton!.formatSecondary()
            bottomButton!.setTitleColor(UIColor.primary1(), for: UIControlState())
        } else {
            bottomButton!.formatPrimary()
            bottomButton!.setTitleColor(UIColor.white, for: UIControlState())
        }
        
        bottomButton!.setTitle(title, for: UIControlState())
        
        if customAction != nil && self.responds(to: customAction!) {
            bottomButton!.addTarget(self, action: customAction!, for: .touchUpInside)
        } else {
            bottomButton!.addTarget(self, action: #selector(LogoutFooterView.bottomButtonAction), for: .touchUpInside)
        }
        
        bottomButtonContainer?.addSubview(bottomButton!)
        self.addSubview(bottomButtonContainer!)
    }
    
    @objc func bottomButtonAction(_ sender : UIButton) {
        
        if let callback = logoutCompletionHandler {
            callback()
        }
        
    }
    
}
