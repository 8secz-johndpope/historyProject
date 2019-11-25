//
//  ProfileViewController.swift
//  merchant-ios
//
//  Created by Koon Kit Chan on 22/9/15.
//  Copyright © 2015 Koon Kit Chan. All rights reserved.
//

import Foundation
import UIKit
import ObjectMapper
import FXBlurView
import PromiseKit

struct LogoDisplayMode {
    static let hideConstrant = CGFloat(20) // set to 20 to hide the space area of logo
    static let showConstrant = CGFloat(125)
}


class UserViewController : UIViewController, UIScrollViewDelegate, ChangeInventoryLocationDelegate{
    @IBOutlet weak var profileLabel: UILabel!
    
    var user : User?
    var merch : Merchant?
    var currentInventoryLocation : InventoryLocation?
    var profileImage : UIImage?
    var logoImage : UIImage?
    var isUpdating : Bool? = false

    @IBOutlet weak var bannerImageView: UIImageView!
    @IBOutlet weak var inventoryLabel: UILabel!
    @IBOutlet weak var countryLabel: UILabel!
    @IBOutlet weak var provinceLabel: UILabel!
    @IBOutlet weak var cityLabel: UILabel!
    @IBOutlet weak var districtLabel: UILabel!
    @IBOutlet weak var brandLabel: UILabel!
    @IBOutlet weak var inventoryButton: UIButton!
    @IBOutlet weak var scrollView: UIScrollView!
    @IBOutlet weak var userView: UserView!
    
    @IBOutlet weak var typeLabel: UILabel!
    @IBOutlet weak var locationLabel: UILabel!
    // title label
    @IBOutlet weak var inventoryTitleLabel: UILabel!
    @IBOutlet weak var provinceTitleLabel: UILabel!
    @IBOutlet weak var cityTitleLabel: UILabel!
    @IBOutlet weak var districtTitleLabel: UILabel!
    @IBOutlet weak var countryTitleLabel: UILabel!
    
    @IBOutlet weak var typeTitleLabel: UILabel!
    @IBOutlet weak var locationIdTitleLabel: UILabel!
    
    @IBAction func inventoryButtonClicked(sender: UIButton) {
        let inventoryVeiwController = UIStoryboard(name: "Inventory", bundle: nil).instantiateViewControllerWithIdentifier("InventoryViewController") as! InventoryViewController
        inventoryVeiwController.delegate = self
        inventoryVeiwController.user = self.user
        self.navigationController?.pushViewController(inventoryVeiwController, animated: true)
    }

    @IBOutlet weak var profileImageView: UIImageView!
    
    @IBOutlet weak var logoImageView: UIImageView!
    // layout 
    @IBOutlet weak var brandNameConstraint: NSLayoutConstraint!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        self.brandNameConstraint.constant = LogoDisplayMode.hideConstrant
        self.logoImageView.contentMode = UIViewContentMode.scaleAspectFit
        
        // localization
        localization()
        
        NotificationCenter.default.addObserverForName(Constants.Notification.LangaugeChanged, object: nil, queue: nil) {[weak self] (notification) in
            if let strongSelf = self {
                strongSelf.localization()
            }
        }
    }

    deinit {
        NotificationCenter.default.removeObserver(self)
    }
    
    // MARK: Visual Effect and Rendering

    func renderUserView(){
        inventoryLabel.text = currentInventoryLocation?.locationName
        inventoryLabel.numberOfLines = 0
        inventoryLabel.lineBreakMode = NSLineBreakMode.byWordWrapping
        locationLabel.text = currentInventoryLocation?.locationExternalCode
        typeLabel.text = currentInventoryLocation?.inventoryLocationTypeName
        countryLabel.text = currentInventoryLocation?.geoCountryName
        provinceLabel.text = currentInventoryLocation?.geoProvinceName
        cityLabel.text = currentInventoryLocation?.geoCityName
        districtLabel.text = currentInventoryLocation?.district
        inventoryButton.formatSecondary()
        scrollView.delegate = self
        
        self.view.layoutMargins = UIEdgeInsets(top: 0, left: 0, bottom: 0, right: 0)
        // show setting button
        let button: UIButton = UIButton(type: UIButtonType.custom)
        button.setImage(UIImage(named: "setting_rest"), for: UIControlState.normal)
        button.setImage(UIImage(named: "setting_hover"), for: UIControlState.Highlighted)
        button.addTarget(self, action: #selector(UserViewController.btnSetting), for: UIControlEvents.touchUpInside)
        button.frame = CGRect(x:0, y: 0, width: 18.5, height: 18.5)
        let barButton = UIBarButtonItem(customView: button)
        self.navigationItem.rightBarButtonItem = barButton
        
        self.profileLabel.numberOfLines = 0
        self.profileLabel.text = self.user?.displayName
    }
    
    func renderMerchView() {
        // render merchant name
        if self.user?.merchant.merchantDisplayName.length > 0 {
            self.brandLabel.text = self.user?.merchant.merchantDisplayName
        }
        // render background image
        if self.user?.merchant.backgroundImage.length > 0 {
            ImageService.view((self.user?.merchant.backgroundImage)!){[weak self] (response) in
                if let strongSelf = self {
                    let rawImage = response.result.value
                    let size = strongSelf.bannerImageView.frame.size
                    Log.debug(NSStringFromCGSize(size))
                    let processedImage = rawImage!.af_imageAspectScaledToFitSize(size)
                    strongSelf.bannerImageView.image = processedImage.blurredImageWithRadius(12, iterations: 12, tintColor: UIColor.clear)
                }
            }
        }
        // render logo image
        if self.user?.merchant.logoImage.length > 0 {
            ImageService.view((self.user?.merchant.logoImage)!){[weak self] (response) in
                if let strongSelf = self {
                    if response.result.isSuccess {
                        // show merchant logo if load success
                        strongSelf.brandNameConstraint.constant = LogoDisplayMode.showConstrant
                        
                        let rawImage = response.result.value
                        let size = CGSize(width: 240.0, height: 170.0)
                        let processedImage = rawImage!.af_imageAspectScaledToFitSize(size)
                        strongSelf.logoImage = processedImage
                        strongSelf.logoImageView.image = strongSelf.logoImage
                        strongSelf.logoImageView.layoutIfNeeded()
                        strongSelf.logoImageView.clipsToBounds = true
                    }
                }
            }
        } else {
            self.brandNameConstraint.constant = LogoDisplayMode.hideConstrant
        }
    }
    
    func fetchUser() -> Promise<Any>{
        return Promise{ fulfill, reject in
            UserService.view(){[weak self] (response) in
                if let strongSelf = self {
                    if response.result.isSuccess {
                        if response.response?.statusCode == 200 {
                            strongSelf.user = Mapper<User>().map(JSONObject: response.result.value)
                            fulfill("OK")
                        } else {
                            reject(response.result.error!)
                        }
                    } else {
                        reject(response.result.error!)
                    }
                }
            }
        }
    }
    
    func fetchProfileImage() {
        if (user?.profileImage == ""){
            self.profileImage = UIImage(named: "placeholder")
            self.profileImageView.image = self.profileImage
            self.profileImageView.round()
        } else{
            ImageService.view((user?.profileImage)!, size:200){[weak self] (response) in
                if let strongSelf = self {
                    if let rawImage = response.result.value {
                        let size = CGSize(width: 90.0, height: 90.0)
                        let aspectScaledToFillImage = rawImage.af_imageAspectScaledToFillSize(size)
                        strongSelf.profileImage = aspectScaledToFillImage
                        strongSelf.profileImageView.image = strongSelf.profileImage
                        strongSelf.profileImageView.round()
                    }
                }
            }
        }
    }

    @objc func btnSetting() {
        let settingViewController = UIStoryboard(name: "Setting", bundle: nil).instantiateViewControllerWithIdentifier("SettingViewController") as! SettingViewController
        settingViewController.user = self.user
        self.navigationController?.pushViewController(settingViewController, animated: true)
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        MobClick.beginLogPageView("UserView")
        let bar:UINavigationBar! =  self.navigationController?.navigationBar
        bar.setBackgroundImage(UIImage(), forBarMetrics: UIBarMetrics.Default)
        bar.shadowImage = UIImage()
        bar.backgroundColor = UIColor.clear
        bar.translucent = true
        
        if let _ = UIFont(name: Constants.Font.Normal, size: Constants.Font.Size) {
            bar.titleTextAttributes = [NSAttributedStringKey.foregroundColor : UIColor.white,
                NSAttributedStringKey.font: UIFont(name: Constants.Font.Normal, size: Constants.Font.Size)!]
        } else {
            bar.titleTextAttributes = [NSAttributedStringKey.foregroundColor : UIColor.white,
                NSAttributedStringKey.font: UIFont(name: Constants.iOS8Font.Normal, size: Constants.Font.Size)!]
        }        

        // update user info
        updateUserView()
    }
    
    func localization() {
        self.title = String.localize("LB_HOME")
        self.inventoryTitleLabel.text = String.localize("LB_INVENTORY_LOCATION")
        self.locationIdTitleLabel.text = String.localize("LB_LOC_ID")
        self.typeTitleLabel.text = String.localize("LB_LOC_TYPE")
        self.provinceTitleLabel.text = String.localize("LB_PROVINCE")
        self.districtTitleLabel.text = String.localize("LB_DISTRICT_POSTCODE")
        self.cityTitleLabel.text = String.localize("LB_CITY")
        self.countryTitleLabel.text = String.localize("LB_COUNTRY")
        self.inventoryButton.setTitle(String.localize("LB_INVENTORY_LOCATION_CHANGE"), for: UIControlState.normal)
    }
    
    func updateUserView(){
        self.showLoading()
        firstly{

            // update inventory location if needed
            // if it is not updated, it will return success without api call
            return updateInventoryLocation()
        }.then { _ in
            return self.fetchUser()
        }.then { _  in
            return self.fetchCurrentInventoryLocation()
        }.then { _ -> Void in
            self.fetchProfileImage()
            self.renderUserView()
            self.renderMerchView()
        }.always {
            self.stopLoading()
        }.catch { _ -> Void in
            Log.error("error")
        }
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        MobClick.endLogPageView("UserView")
        let bar:UINavigationBar! =  self.navigationController?.navigationBar
        bar.setBackgroundImage(UIImage(), forBarMetrics: UIBarMetrics.Default)
        bar.shadowImage = UIImage()
        bar.backgroundColor = UIColor.clear
        bar.translucent = false
        
        if let _ = UIFont(name: Constants.Font.Normal, size: Constants.Font.Size) {
            bar.titleTextAttributes = [NSAttributedStringKey.foregroundColor : UIColor.secondary2(),
                NSAttributedStringKey.font: UIFont(name: Constants.Font.Normal, size: Constants.Font.Size)!]
        } else {
            bar.titleTextAttributes = [NSAttributedStringKey.foregroundColor : UIColor.secondary2(),
                NSAttributedStringKey.font: UIFont(name: Constants.iOS8Font.Normal, size: Constants.Font.Size)!]
        }
    }
    
    func scrollViewDidScroll(_ scrollView: UIScrollView) {
        if (scrollView.contentOffset.x > 0){
            scrollView.contentOffset = CGPoint(x: 0, y: scrollView.contentOffset.y)
        }
    }
    
    // MARK: Change Inventory
    
    func fetchCurrentInventoryLocation() -> Promise<Any>{
        return Promise{ fulfill, reject in
            if self.user?.inventoryLocationId > 0 {
                InventoryService.view((self.user?.inventoryLocationId)!){[weak self] (response) in
                    if let strongSelf = self {
                        if response.result.isSuccess {
                            if response.response?.statusCode == 200 {
                                strongSelf.currentInventoryLocation = Mapper<InventoryLocation>().map(JSONObject: response.result.value)
                                fulfill("OK")
                            } else {
                                reject(response.result.error!)
                            }
                        } else {
                            reject(response.result.error!)
                        }
                    }
                }
            } else {
                fulfill("OK")
            }
        }
    }
    
    func updateInventoryLocation() -> Promise<Any> {
        return Promise{ fulfill, reject in
            if self.isUpdating == true {
                UserService.changeInventoryLocation(self.user!){[weak self] (response) in
                    if let strongSelf = self {
                        if response.result.isSuccess {
                            if response.response?.statusCode == 200 {
                                strongSelf.isUpdating = false
                                fulfill("OK")
                            } else {
                                reject(response.result.error!)
                            }
                        } else {
                            reject(response.result.error!)
                        }
                    }
                }
            } else {
                fulfill("OK")
            }
        }
    }
    
    // MARK: ChangeInventoryLocationDelegate
    
    func changeInventoryLocation(inventoryLocation : InventoryLocation) {
        self.isUpdating = true
        self.user?.inventoryLocationId = inventoryLocation.inventoryLocationId
    }
}
