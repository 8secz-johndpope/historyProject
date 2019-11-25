//
//  PaymentMethodViewController.swift
//  merchant-ios
//
//  Created by Gambogo on 3/22/16.
//  Copyright © 2016 WWE & CO. All rights reserved.
//

import Foundation

class PaymentMethodViewController: MmViewController, PaymentMethodViewCellDelegate {
    
    private final let PaymentCellHeight: CGFloat = 70
    
    private var settingsDataList = [SettingsData]()
    private var selectedPaymentMethod: String = Context.getDefaultPaymentMethod()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        self.navigationController!.isNavigationBarHidden = false
        self.view.backgroundColor = UIColor.backgroundGray()
        self.title = String.localize("LB_CA_PAYMENT_METHOD")
        
        createBackButton()
        prepareDataList()
        setupSubViews()
    }
    
    // MARK: - Setup Views
    
    private func prepareDataList() {
        settingsDataList.append(SettingsData(title: String.localize("LB_CA_ALIPAY"), valueKey: "LB_CA_ALIPAY", hasDisclosureIndicator: true))
    }
    
    private func setupSubViews() {
        collectionView.register(PaymentMethodViewCell.self, forCellWithReuseIdentifier: PaymentMethodViewCell.CellIdentifier)
        collectionView.backgroundColor = UIColor.primary2()
        collectionView.alwaysBounceVertical = true
    }
    
    private func setSelectedPaymentItem(_ itemIndex: Int) {
        Alert.alert(self, title: "", message: String.localize("LB_CA_SET_DEFAULT_PAYMENT_METHOD"), okActionComplete: { () -> Void in
            let settingsData = self.settingsDataList[itemIndex]
            
            if settingsData.valueKey != nil {
                Context.setDefaultPaymentMethod(settingsData.valueKey!)
                self.selectedPaymentMethod = settingsData.valueKey!
                    
                DispatchQueue.main.async {
                    self.collectionView.reloadData()
                }
            }
        }, cancelActionComplete: nil)
    }
    
    func onPaymentItemSelect(_ cell: PaymentMethodViewCell) {
        if settingsDataList.count > 1 {
            if let indexPath = collectionView.indexPath(for: cell) {
                setSelectedPaymentItem(indexPath.row)
            }
        }
    }
    
    // MARK: - CollectionView
    
    func numberOfSections(in collectionView: UICollectionView) -> Int {
        return 1
    }
    
    override func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return settingsDataList.count
    }
    
    override func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        let cell = collectionView.dequeueReusableCell(withReuseIdentifier: PaymentMethodViewCell.CellIdentifier, for: indexPath) as! PaymentMethodViewCell
        cell.delegate = self
        
        let settingsData = settingsDataList[indexPath.row]
        
        cell.itemLabel.text = settingsData.title
        
        if settingsData.valueKey != nil && (settingsData.valueKey!) == selectedPaymentMethod {
            cell.showPaymentSelected(true)
        } else {
            cell.showPaymentSelected(false)
        }
        
        cell.showDisclosureIndicator(settingsData.hasDisclosureIndicator)
        
        return cell
    }
    
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, minimumInteritemSpacingForSectionAt section: Int) -> CGFloat {
        return 0.0
    }
    
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, minimumLineSpacingForSectionAt section: Int) -> CGFloat {
        return 0.0
    }
    
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, sizeForItemAt indexPath: IndexPath) -> CGSize {
        return CGSize(width: view.width, height: PaymentCellHeight)
    }
    
}
