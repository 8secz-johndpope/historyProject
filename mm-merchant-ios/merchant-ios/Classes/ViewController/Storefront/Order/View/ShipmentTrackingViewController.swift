//
//  ShipmentTrackingViewController.swift
//  merchant-ios
//
//  Created by Quang Truong Dinh on 7/1/16.
//  Copyright © 2016 WWE & CO. All rights reserved.
//

import Foundation
import PromiseKit
import ObjectMapper

class ShipmentTrackingViewController: MmViewController {
    
    enum Section: Int {
        case courierInformation
        case receiverAddress
        case shipmentEvent
        case consolidationShipmentEvent
    }
    
    var addressData: AddressData?
    var orderShipment: Shipment?
    
    private var shipmentStatus: KuaiDi100ShipmentStatus?
    private var consolidationShipmentStatus: KuaiDi100ShipmentStatus?
    
    private var loadedShipmentStatus = false
    private var loadedConsolidationShipmentStatus = false
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        self.view.backgroundColor = UIColor.primary2()
        self.title = String.localize("LB_CA_SHIPEMNT_TRACKING")
        
        setupCollectionView()
        createBackButton()
        
        if let orderShipment = orderShipment {
            loadShipmentStatus(withOrderShipment: orderShipment)
        } else {
            ErrorLogManager.sharedManager.recordNonFatalError(withException: .NullPointer)
        }
    }
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
    }

    // MARK: - Setup
    
    private func setupCollectionView() {
        collectionView.backgroundColor = UIColor.clear
        collectionView.register(CourierCell.self, forCellWithReuseIdentifier: CourierCell.CellIdentifier)
        collectionView.register(ReceiverAddressCell.self, forCellWithReuseIdentifier: ReceiverAddressCell.CellIdentifier)
        collectionView.register(ShipmentEventCell.self, forCellWithReuseIdentifier: ShipmentEventCell.CellIdentifier)
        
        let summaryViewHeight: CGFloat = 50
        
        let summaryView = { () -> UIView in
            let view = UIView(frame: CGRect(x: 0, y: self.view.frame.maxY - summaryViewHeight, width: collectionView.width, height: summaryViewHeight))
            view.backgroundColor = UIColor.white
            
            let topBorderView = UIView(frame:CGRect(x: 0, y: 0, width: view.frame.width, height: 1))
            topBorderView.backgroundColor = UIColor.secondary1()
            view.addSubview(topBorderView)
            
            let textViewHorizontalPadding: CGFloat = 30
            let textViewVerticalPadding: CGFloat = 5
            
            let textView = { () -> UITextView in
                let textView = UITextView(frame: CGRect(x: textViewHorizontalPadding, y: textViewVerticalPadding, width: view.width - (textViewHorizontalPadding * 2), height: view.height - (textViewVerticalPadding * 2)))
                textView.backgroundColor = UIColor.white
                textView.text = String.localize("LB_OMS_LOGISTIC_NOTE")
                textView.textColor = UIColor.secondary1()
                textView.isUserInteractionEnabled = false
                textView.fitHeight()
                return textView
            }()
            
            view.frame = CGRect(x: 0, y: self.view.frame.maxY - textView.height - 10, width: view.width, height: textView.height + 10)
            view.addSubview(textView)
            
            return view
        }()
        view.addSubview(summaryView)
        
        collectionView.frame = CGRect(x: collectionView.x, y: collectionView.y, width: collectionView.width, height: collectionView.height - summaryView.frame.height)
    }
    
    // MARK: Data
    
    private func loadShipmentStatus(withOrderShipment orderShipment: Shipment) {
        showLoading()
        
        if let courierData = orderShipment.courierData {
            fetchShipmentStatus(withCourierData: courierData)
        } else {
            loadedShipmentStatus = true
        }
        
        if let consolidationCourierData = orderShipment.consolidationCourierData {
            fetchShipmentStatus(withCourierData: consolidationCourierData)
        } else {
            loadedConsolidationShipmentStatus = true
        }
        
        if loadedShipmentStatus && loadedConsolidationShipmentStatus {
            stopLoading()
        }
    }
    
    @discardableResult
    private func fetchShipmentStatus(withCourierData courierData: CourierData) -> Promise<Any> {
        return Promise { fulfill, reject in
            KuaiDi100Service.listShipmentStatus(withCourierCode: courierData.courierCode, consignmentNumber: courierData.consignmentNumber, completion: { [weak self] (response) in
                let statusCode = response.response?.statusCode ?? 0
                
                if let strongSelf = self {
                    if response.result.isSuccess {
                        if statusCode == 200 {
                            if let shipmentStatus = Mapper<KuaiDi100ShipmentStatus>().map(JSONObject: response.result.value) {
                                switch courierData.type {
                                case .normal:
                                    strongSelf.shipmentStatus = shipmentStatus
                                    strongSelf.loadedShipmentStatus = true
                                case .consolidation:
                                    strongSelf.consolidationShipmentStatus = shipmentStatus
                                    strongSelf.loadedConsolidationShipmentStatus = true
                                }
                                
                                if strongSelf.loadedShipmentStatus && strongSelf.loadedConsolidationShipmentStatus {
                                    DispatchQueue.main.async {
                                        strongSelf.collectionView.reloadData()
                                        strongSelf.stopLoading()
                                    }
                                }
                            } else {
                                ErrorLogManager.sharedManager.recordNonFatalError(withException: .FailToParseAPIResponse)
                            }
                            
                            fulfill("OK")
                        } else {
                            let error = NSError(domain: "", code: statusCode, userInfo: nil)
                            reject(error)
                        }
                    } else {
                        reject(response.result.error ?? NSError(domain: "", code: 0, userInfo: nil))
                    }
                } else {
                    ErrorLogManager.sharedManager.recordNonFatalError(withException: .NullPointer)
                }
            })
        }
    }
    
    // MARK: - Collection View Data Source methods
    
    func numberOfSections(in collectionView: UICollectionView) -> Int {
        return 4
    }
    
    override func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        if let section = Section(rawValue: section) {
            switch section {
            case .courierInformation:
                return 1
            case .receiverAddress:
                if let _ = self.addressData {
                    return 1
                } else {
                    ErrorLogManager.sharedManager.recordNonFatalError(withException: .NullPointer)
                }
            case .shipmentEvent:
                if let shipmentStatus = shipmentStatus {
                    return shipmentStatus.data.count
                }
            case .consolidationShipmentEvent:
                if let consolidationShipmentStatus = consolidationShipmentStatus {
                    return consolidationShipmentStatus.data.count
                }
            }
        } else {
            ErrorLogManager.sharedManager.recordNonFatalError(withException: .TypeMismatch)
        }
        
        return 0
    }
    
    override func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        if let section = Section(rawValue: indexPath.section) {
            switch section {
            case .courierInformation:
                let cell = collectionView.dequeueReusableCell(withReuseIdentifier: CourierCell.CellIdentifier, for: indexPath) as! CourierCell
                
                if let courierData = orderShipment?.courierData {
                    cell.data = courierData
                } else if let consolidationCourierData = orderShipment?.consolidationCourierData {
                    cell.data = consolidationCourierData
                }
            
                return cell
            case .receiverAddress:
                let cell = collectionView.dequeueReusableCell(withReuseIdentifier: ReceiverAddressCell.CellIdentifier, for: indexPath) as! ReceiverAddressCell
                cell.separateLineView.isHidden = false
                cell.data = addressData
                
                return cell
            case .shipmentEvent:
                let cell = collectionView.dequeueReusableCell(withReuseIdentifier: ShipmentEventCell.CellIdentifier, for: indexPath) as! ShipmentEventCell
                
                cell.isCurrentEvent = (indexPath.item == 0)
                cell.dateTimeLabel.text = ""
                cell.statusAndContextLabel.text = ""
                
                if let shipmentStatus = shipmentStatus {
                    let data = shipmentStatus.data[indexPath.item]
                    cell.data = data
                }
                
                return cell
            case .consolidationShipmentEvent:
                let cell = collectionView.dequeueReusableCell(withReuseIdentifier: ShipmentEventCell.CellIdentifier, for: indexPath) as! ShipmentEventCell
                
                cell.isCurrentEvent = (indexPath.item == 0 && shipmentStatus == nil)
                cell.dateTimeLabel.text = ""
                cell.statusAndContextLabel.text = ""
                
                if let consolidationShipmentStatus = consolidationShipmentStatus {
                    let data = consolidationShipmentStatus.data[indexPath.item]
                    cell.data = data
                }
                
                return cell
            }
        } else {
            ErrorLogManager.sharedManager.recordNonFatalError(withException: .TypeMismatch)
        }
        
        return UICollectionViewCell()
    }
    
    // MARK: - Collection View Delegate (Flow Layout) methods
    
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, insetForSectionAt section: Int) -> UIEdgeInsets {
        return UIEdgeInsets.zero
    }
    
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, minimumInteritemSpacingForSectionAt section: Int) -> CGFloat {
        return 0.0
    }
    
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, minimumLineSpacingForSectionAt section: Int) -> CGFloat {
        return 0.0
    }
    
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, sizeForItemAt indexPath: IndexPath) -> CGSize {
        if let section = Section(rawValue: indexPath.section) {
            switch section {
            case .courierInformation:
                return CGSize(width: view.width, height: CourierCell.DefaultHeight)
            case .receiverAddress:
                if let addressData = self.addressData {
                    return CGSize(width: view.width, height: ReceiverAddressCell.getCellHeight(withAddress: addressData.getFullAddress(), cellWidth: view.width))
                } else {
                    ErrorLogManager.sharedManager.recordNonFatalError(withException: .NullPointer)
                }
            case .shipmentEvent:
                if let shipmentStatus = shipmentStatus {
                    let data = shipmentStatus.data[indexPath.item]
                    return CGSize(width: view.width, height: ShipmentEventCell.getHeight(statusAndContextText: data.context))
                } else {
                    return CGSize(width: view.width, height: ShipmentEventCell.DefaultHeight)
                }
            case .consolidationShipmentEvent:
                if let consolidationShipmentStatus = consolidationShipmentStatus {
                    let data = consolidationShipmentStatus.data[indexPath.item]
                    return CGSize(width: view.width, height: ShipmentEventCell.getHeight(statusAndContextText: data.context))
                } else {
                    return CGSize(width: view.width, height: ShipmentEventCell.DefaultHeight)
                }
            }
        } else {
            ErrorLogManager.sharedManager.recordNonFatalError(withException: .TypeMismatch)
        }
        
        return CGSize.zero
    }
    
}
