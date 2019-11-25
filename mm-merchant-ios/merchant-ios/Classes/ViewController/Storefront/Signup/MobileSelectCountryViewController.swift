//
//  MobileSelectCountryViewController.swift
//  merchant-ios
//
//  Created by Koon Kit Chan on 2/2/2016.
//  Copyright © 2016 WWE & CO. All rights reserved.
//

import Foundation
import PromiseKit
import ObjectMapper


class MobileSelectCountryViewController : MmViewController {
    var geoCountries : [GeoCountry] = []
    weak var selectGeoCountryDelegate : SelectGeoCountryDelegate!
    var refreshControl = UIRefreshControl()
    var buttonCell = ButtonCell()
    var isNeedToDismiss = false
    var selectedCountry : GeoCountry?
    private let ImageMenuCellHeight : CGFloat = 40
    override func viewDidLoad() {
        super.viewDidLoad()
        self.edgesForExtendedLayout = UIRectEdge()
        self.title = String.localize("LB_COUNTRY_PICK")
        self.collectionView.dataSource = self
        self.collectionView.delegate = self
        self.collectionView.frame = CGRect(x: self.view.bounds.minX, y: 0, width: self.view.bounds.width, height: self.view.bounds.height - (self.navigationController?.navigationBar.frame.height)! - UIApplication.shared.statusBarFrame.size.height)
        if geoCountries.count == 0 {
            loadCountry()
        }
        self.createRightButton(String.localize("LB_CA_RESET"), action: #selector(MobileSelectCountryViewController.resetTapped))
        self.collectionView.register(SelectCountryCell.self, forCellWithReuseIdentifier: "SelectCountryCell")
        self.setUpRefreshControl()
        self.createBackButton()
        
        
    }
    
    override var hidesBottomBarWhenPushed: Bool {
        get { return true }
        set {}
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        
    }
    
    func loadCountry() {
        self.showLoading()
        firstly{
                return self.listCountry()
            }.then
            { _ -> Void in
                if let selectedCountry = self.selectedCountry {
                    for country in self.geoCountries {
                        if country.mobileCode == selectedCountry.mobileCode {
                            country.isSelected = true
                        }
                    }
                }
                self.collectionView.reloadData()
            }.always {
                self.stopLoading()
                self.refreshControl.endRefreshing()
                
            }.catch { _ -> Void in
                Log.error("error")
        }
        
    }
    
    func listCountry() -> Promise<Any> {
        return Promise{ fulfill, reject in
            GeoService.storefrontCountries(){
                [weak self] (response) in
                if let strongSelf = self {
                    if response.result.isSuccess{
                        if response.response?.statusCode == 200 {
                            strongSelf.geoCountries = Mapper<GeoCountry>().mapArray(JSONObject: response.result.value) ?? []
                            fulfill("OK")
                        } else {
                            strongSelf.handleError(response, animated: true)
                        }
                    }
                    else{
                        reject(response.result.error!)
                    }
                }
            }
        }
    }
    
    override func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        let cell = collectionView.dequeueReusableCell(withReuseIdentifier: "SelectCountryCell", for: indexPath) as! SelectCountryCell
        
        if (self.geoCountries.count > indexPath.row) {
            let country = self.geoCountries[indexPath.row]
            cell.countryNameLabel.text = country.geoCountryName
            cell.countryCodeLabel.text = country.mobileCode
            cell.checkboxButton.isSelected = country.isSelected
        }
        
        return cell
    }
    
    func numberOfSections(in collectionView: UICollectionView) -> Int {
        return 1
    }
    
    override func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return self.geoCountries.count
    }
    
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, sizeForItemAt indexPath: IndexPath) -> CGSize {
            switch collectionView {
            case self.collectionView!:
                switch indexPath.row {
                default:
                    return CGSize(width: self.view.frame.size.width, height: ImageMenuCellHeight)
                }
            default:
                return CGSize(width: 0,height: 0)
            }
    }
    
    
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, minimumInteritemSpacingForSectionAt section: Int) -> CGFloat {
        return 0.0
    }
    
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, minimumLineSpacingForSectionAt section: Int) -> CGFloat {
        return 0.0
    }
    
    func collectionView(_ collectionView: UICollectionView,
        didSelectItemAt indexPath: IndexPath) {
        
        for country in self.geoCountries {
            country.isSelected = false
        }
        selectedCountry = geoCountries[indexPath.row]
        selectedCountry?.isSelected = true
        self.collectionView.reloadData()
    }
    
    //MARK : Refresh Control
    
    func setUpRefreshControl(){
        self.refreshControl.addTarget(self, action: #selector(MobileSelectCountryViewController.refresh(_:)), for: UIControlEvents.valueChanged)
        self.collectionView.addSubview(refreshControl)
        self.collectionView.alwaysBounceVertical = true
    }
    
    @objc func refresh(_ sender : Any){
        loadCountry()
    }
    
    // MARK: Confirm and Reset
    @objc func resetTapped (_ sender:UIBarButtonItem) {
        if self.geoCountries.count > 0 {
            selectedCountry = nil
            for country in self.geoCountries {
                if country.mobileCode == Constants.CountryMobileCode.DEFAULT {
                    selectedCountry = country
                } else {
                    country.isSelected = false
                }
            }
            if selectedCountry == nil {
               selectedCountry = self.geoCountries[0]
            }
            selectedCountry?.isSelected = true
            self.collectionView.reloadData()
        }
    }
    
    override func backButtonClicked(_ button: UIButton) {
        if self.isNeedToDismiss {
            self.dismiss(animated: true, completion: {
                if let country = self.selectedCountry {
                    self.selectGeoCountryDelegate?.selectGeoCountry(country)
                }
            })
        } else {
            if let country = self.selectedCountry {
                selectGeoCountryDelegate?.selectGeoCountry(country)
            }
            super.backButtonClicked(button)
        }
    }
}
