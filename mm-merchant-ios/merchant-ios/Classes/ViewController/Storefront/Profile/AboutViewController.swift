//
//  AboutViewController.swift
//  merchant-ios
//
//  Created by Quang Truong Dinh on 3/22/16.
//  Copyright © 2016 WWE & CO. All rights reserved.
//

import Foundation

class AboutViewController: AccountSettingBaseViewController {
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        self.title = String.localize("LB_CA_ABOUT")
        
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
		let aboutMMSettingsData = SettingsData(title: String.localize("LB_CA_ABOUT_MYMM"), action: { (indexPath) in
			
			if let url = ContentURLFactory.urlForContentType(.mmAbout) {
				self.navigationController?.push(AboutDetailViewController(title: String.localize("LB_CA_ABOUT_MYMM"), urlGetContentPage: url), animated: true)
			}
			
		})

		let copyrightSettingsData = SettingsData(title: String.localize("LB_CA_COPYRIGHT_INFO"), action: { (indexPath) in
			
			if let url = ContentURLFactory.urlForContentType(.mmCopyRight) {
				self.navigationController?.push(AboutDetailViewController(title: String.localize("LB_CA_COPYRIGHT_INFO"), urlGetContentPage: url), animated: true)
			}
			
		})
		
		let legalSettingsData = SettingsData(title: String.localize("LB_CA_LEGAL_NOTICES"), action: { (indexPath) in
			
			if let url = ContentURLFactory.urlForContentType(.mmLegalStatement) {
				self.navigationController?.push(AboutDetailViewController(title: String.localize("LB_CA_LEGAL_NOTICES"), urlGetContentPage: url), animated: true)
			}
			
		})
		
		let ipSettingsData = SettingsData(title: String.localize("LB_CA_IPR"), action: { (indexPath) in
			
			if let url = ContentURLFactory.urlForContentType(.mmipStatement) {
				self.navigationController?.push(AboutDetailViewController(title: String.localize("LB_CA_IPR"), urlGetContentPage: url), animated: true)
			}
			
		})
		
		let privacySettingsData = SettingsData(title: String.localize("LB_CA_PRIVACY_POLICY"), action: { (indexPath) in
			
			if let url = ContentURLFactory.urlForContentType(.mmPrivacyStatement) {
				self.navigationController?.push(AboutDetailViewController(title: String.localize("LB_CA_PRIVACY_POLICY"), urlGetContentPage: url), animated: true)
			}
			
		})
		
		let agreementSettingsData = SettingsData(title: String.localize("LB_CA_SW_LICENSE_AGREEMENT"), action: { (indexPath) in
			if let url = ContentURLFactory.urlForContentType(.mmUserAgreement) {
				self.navigationController?.push(AboutDetailViewController(title: String.localize("LB_CA_SW_LICENSE_AGREEMENT"), urlGetContentPage: url), animated: true)
			}
			
		})

		let returnPolicySettingsData = SettingsData(title: String.localize("LB_CA_MYMM_RMA_POLICY"), action: { (indexPath) in
			
			if let url = ContentURLFactory.urlForContentType(.mmReturn) {
				
				self.navigationController?.push(AboutDetailViewController(title: String.localize("LB_CA_MYMM_RMA_POLICY"), urlGetContentPage: url), animated: true)
			}
			
		})

		
		settingsDataList.append([aboutMMSettingsData, copyrightSettingsData, legalSettingsData, ipSettingsData, privacySettingsData, agreementSettingsData , returnPolicySettingsData])
    }
    
    private func setupSubViews() {
        collectionView.register(CommonViewItemCell.self, forCellWithReuseIdentifier: CommonViewItemCell.CellIdentifier)
    }
    
    // MARK: - Collection View Data Source methods
    
    override func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        let settingsData = settingsDataList[indexPath.section][indexPath.item]
        
        let cell = collectionView.dequeueReusableCell(withReuseIdentifier: CommonViewItemCell.CellIdentifier, for: indexPath) as! CommonViewItemCell
        
        cell.itemLabel.text = settingsData.title
        cell.showBottomBorder(settingsData.hasBorder)
        cell.showDisclosureIndicator(true)
        
        return cell
    }
    
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, sizeForItemAt indexPath: IndexPath) -> CGSize {
        return CGSize(width: view.width, height: CommonViewItemCell.DefaultHeight)
    }
    
}
