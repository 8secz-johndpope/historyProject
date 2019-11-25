//
//  SettingViewController.swift
//  merchant-ios
//
//  Created by Koon Kit Chan on 12/10/15.
//  Copyright © 2015 Koon Kit Chan. All rights reserved.
//

import Foundation
import Alamofire
import ObjectMapper
import KSToastView

//MARK:- Delegate Protocol
protocol ChangeNameDelegate{
    func changeName(user : User)
}

protocol ChangeEmailDelegate{
    func changeEmail(user : User)
}


protocol ChangeLanguageDelegate{
    func changeLanguage(language : Language)
}

protocol ChangePasswordDelegate{
    func changePassword(user : User)
}

//MARK: SettingViewController

class SettingViewController : UITableViewController, UIImagePickerControllerDelegate, UINavigationControllerDelegate, ChangeNameDelegate, ChangeEmailDelegate, ChangeMobileDelegate, ChangeLanguageDelegate, ChangePasswordDelegate {
    
    @IBOutlet weak var profileCell: UITableViewCell!
    @IBOutlet weak var nameCell: UITableViewCell!
    @IBOutlet weak var passwordCell: UITableViewCell!
    @IBOutlet weak var emailCell: UITableViewCell!
    @IBOutlet weak var mobileCell: UITableViewCell!
    @IBOutlet weak var languageCell: UITableViewCell!
    @IBOutlet weak var problemCell: UITableViewCell!
    @IBOutlet weak var logoutCell: UITableViewCell!
    
    var picker:UIImagePickerController? = UIImagePickerController()
    var user : User?

    
    override func viewDidLoad() {
        super.viewDidLoad()
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)

        self.picker?.delegate = self
        renderProfileImage()
        renderNameCell()
        renderEmailCell()
        renderMobileCell()
        
        // localization
        self.title = String.localize("LB_SETTING")
        self.profileCell.textLabel!.text = String.localize("LB_PROFILE_PIC")
        self.nameCell.textLabel!.text = String.localize("LB_DISP_NAME")
        self.passwordCell.textLabel!.text = String.localize("LB_CHANGE_PASSWORD")
        self.emailCell.textLabel!.text = String.localize("LB_CHANGE_EMAIL")
        self.mobileCell.textLabel!.text = String.localize("LB_CHANGE_MOBILE")
        self.languageCell.textLabel!.text = String.localize("LB_LANGUAGE")
        self.problemCell.textLabel!.text = String.localize("LB_REPORT_PROBLEM")
        self.logoutCell.textLabel!.text = String.localize("LB_LOGOUT")
    }
    
    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        switch(indexPath.section){
        case 0:
            switch (indexPath.row){
            case 0:
             changeProfileImage()
                break
            case 1:
               changeName()
                break
            default:
                break
            }
            break
        case 1:
            switch (indexPath.row){
            case 0:
                changePassword()
                break
            case 1:
                changeEmail()
                break
            case 2:
                changeMobile()
                break
            default:
                break
            }
            break
        case 2:
            changeLanguage()
            break
        case 3:
            reportProblem()
            break
        case 4:
            LoginManager.logout()
            break
        default:
            break
        }

    }
    
    //# MARK: - Photo Methods
    func openCamera(){
		
        Utils.checkCameraPermissionWithCallBack({[weak self] (granted) in
            if let strongSelf = self, granted {
                if(UIImagePickerController .isSourceTypeAvailable(UIImagePickerControllerSourceType.Camera)) {
                    strongSelf.picker!.sourceType = UIImagePickerControllerSourceType.Camera
                    strongSelf.picker!.cameraDevice = UIImagePickerControllerCameraDevice.Front
                    strongSelf.present(strongSelf.picker!, animated: true, completion: nil)
                }else {
                    Alert.alert(strongSelf, title: "Camera not found", message: "Cannot access the front camera. Please use photo gallery instead.")
                }
            }
        })
		
    }
    
    func openGallery(){
        picker!.sourceType = UIImagePickerControllerSourceType.PhotoLibrary
        if UIDevice.currentDevice().userInterfaceIdiom == .Phone {
            self.present(picker!, animated: true, completion: nil)
        } else {
            Alert.alert(self, title: "Tablet not suported", message: "Tablet is not supported in this function")
        }
    }
    
    func imagePickerController(picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [String : Any]) {
        picker.dismiss(animated: true, completion: nil)
//        var rawImage = info[UIImagePickerControllerOriginalImage] as? UIImage
//        rawImage = rawImage?.normalizedImage()
        if let rawImage = (info[UIImagePickerControllerOriginalImage] as? UIImage)?.normalizedImage() {
            let imagePickedData = UIImageJPEGRepresentation(rawImage!, Constants.CompressionRatio.JPG_COMPRESSION)!
            Alamofire.upload(
                .POST,
                Constants.Path.Host + "/image/upload", headers: Context.getHTTPHeader(Constants.AppVersion),
                multipartFormData: { multipartFormData in
                    multipartFormData.appendBodyPart(data: imagePickedData, name: "file", fileName: "iosFile.jpg", mimeType: "image/jpg")
                },
                encodingCompletion: { encodingResult in
                    switch encodingResult {
                    case .Success(let upload, _, _):
                        upload.responseJSON { response in
                            let imageUploadResponse = Mapper<ImageUploadResponse>().map(JSONObject: response.result.value)
                            self.user?.profileImage = (imageUploadResponse?.imageKey)!
                            UserService.save(self.user!) {[weak self] (response) in
                                if let strongSelf = self {
                                    Log.debug(response.result)
                                    Log.debug(response.response?.statusCode)
                                    Log.debug(response.result.value)
                                    strongSelf.renderProfileImage()
                                }
                            }
                            
                        }
                    case .Failure(_): break
                    }
                }
            )
            
        }
        
    }
    
    func imagePickerControllerDidCancel(picker: UIImagePickerController) {
        self.dismiss(animated: true) { () -> Void in
        }
    }
    
    func changeProfileImage(rawImage : UIImage){
        let size = CGSize(width: 80.0, height: 80.0)
        let aspectScaledToFillImage = rawImage.af_imageAspectScaledToFillSize(size)
        self.profileCell.accessoryView = UIImageView(image: aspectScaledToFillImage)
        (self.profileCell.accessoryView as! UIImageView).round()
    }
    
    func renderProfileImage(){
        if (user?.profileImage == ""){
            self.changeProfileImage(UIImage(named: "placeholder")!)
            
        } else{
            
            ImageService.view((user?.profileImage)!, size:200){[weak self] (response) in
                if let strongSelf = self {
                    Log.debug(response.request)
                    Log.debug(response.response)
                    Log.debug(response.result)
                    
                    if let rawImage = response.result.value {
                        strongSelf.changeProfileImage(rawImage)
                    }
                }
            }
        }
    }
    
    func changeProfileImage(){
        let optionMenu = UIAlertController(title: nil, message: nil, preferredStyle: .actionSheet)
        let deleteAction = UIAlertAction(title: String.localize("LB_TAKE_PHOTO"), style: .default, handler: {
            (alert: UIAlertAction!) -> Void in
            self.openCamera()
        })
        let saveAction = UIAlertAction(title: String.localize("LB_PHOTO_LIBRARY"), style: .default, handler: {
            (alert: UIAlertAction!) -> Void in
            self.openGallery()
        })
        let cancelAction = UIAlertAction(title: String.localize("LB_CANCEL"), style: .cancel, handler: {
            (alert: UIAlertAction!) -> Void in
        })
        optionMenu.addAction(deleteAction)
        optionMenu.addAction(saveAction)
        optionMenu.addAction(cancelAction)
		optionMenu.view.tintColor = UIColor.secondary2()
        self.present(optionMenu, animated: true, completion: nil)
        optionMenu.view.tintColor = UIColor.alertTintColor()
        self.tableView.deselectRowAtIndexPath(IndexPath(row: 0, section: 0), animated: true)
    }
    
    //# MARK: - Logout, Reactivate and Navigation Methods

    
    class func logout(){
        LoginManager.logout()
        let appDelegate = UIApplication.shared.delegate as! AppDelegate
        let loginNavViewController = UIStoryboard(name: "Login", bundle: nil).instantiateViewControllerWithIdentifier("LoginNavigation")
        appDelegate.window!.rootViewController = loginNavViewController
    }
    
    class func reactivate(){
        LoginManager.logout()
        let appDelegate = UIApplication.shared.delegate as! AppDelegate
        let changeMobileNavViewController = UIStoryboard(name: "Mobile", bundle: nil).instantiateViewControllerWithIdentifier("ChangeMobileNav")
        appDelegate.window!.rootViewController = changeMobileNavViewController
    }
    
    func scanBarcode(){
        let barcodeViewController = UIStoryboard(name: "Main", bundle: nil).instantiateViewControllerWithIdentifier("BarcodeViewController")
        self.navigationController?.pushViewController(barcodeViewController, animated: true)
    }
    
    //# MARK: - UI Rendering
    
    func renderNameCell(){
        nameCell.detailTextLabel?.text = self.user?.displayName
    }
    
    func renderEmailCell(){
        emailCell.detailTextLabel?.text = self.user?.email
    }
    
    func renderMobileCell(){
        mobileCell.detailTextLabel?.text = (self.user?.mobileCode)! + " " + (self.user?.mobileNumber)!
    }
    
    //# MARK: - Trigger changer viewcontroller
    
    func changeName(){
        let nameVeiwController = UIStoryboard(name: "Setting", bundle: nil).instantiateViewControllerWithIdentifier("NameViewController") as! NameViewController
        nameVeiwController.delegate = self
        nameVeiwController.user = self.user
        self.navigationController?.pushViewController(nameVeiwController, animated: true)
    }
    
    func changeEmail(){
        let emailVeiwController = UIStoryboard(name: "Setting", bundle: nil).instantiateViewControllerWithIdentifier("EmailViewController") as! EmailViewController
        emailVeiwController.delegate = self
        emailVeiwController.user = self.user
        self.navigationController?.pushViewController(emailVeiwController, animated: true)
    }
    
    func changeMobile(){
        let mobileVeiwController = UIStoryboard(name: "Setting", bundle: nil).instantiateViewControllerWithIdentifier("MobileViewController") as! MobileViewController
        mobileVeiwController.delegate = self
        mobileVeiwController.user = self.user
        self.navigationController?.pushViewController(mobileVeiwController, animated: true)
    }
    
    func changeLanguage(){
        let languageViewController = UIStoryboard(name: "Language", bundle: nil).instantiateViewControllerWithIdentifier("LanguageViewController") as! LanguageViewController
        languageViewController.delegate = self
        languageViewController.user = self.user
        self.navigationController?.pushViewController(languageViewController, animated: true)

    }
    
    func changePassword(){
        let passwordViewController = UIStoryboard(name: "Password", bundle: nil).instantiateViewControllerWithIdentifier("PasswordViewController") as! PassWordViewController
        passwordViewController.delegate = self
        passwordViewController.user = self.user
        self.navigationController?.pushViewController(passwordViewController, animated: true)
    }
    
    func reportProblem(){
        let reportProblemViewController = UIStoryboard(name: "Report", bundle: nil).instantiateViewControllerWithIdentifier("ReportProblemViewController") as! ReportProblemViewController
        reportProblemViewController.user = self.user
        self.navigationController?.pushViewController(reportProblemViewController, animated: true)
    }
    
    //# MARK: - Delegate methods
    
    func changeName(user: User) {
        nameCell.detailTextLabel?.text = user.firstName + " " + user.lastName
        UserService.save(user) {response in
            if response.response?.statusCode == 200 {
                KSToastView.ks_showToast(String.localize("MSG_SUC_DISP_NAME_CHANGE"))
            }
        }
    }
    
    func changeEmail(user: User) {
        let existingEmail : String! = emailCell.detailTextLabel?.text
        emailCell.detailTextLabel?.text = user.email
        UserService.changeEmail(user) {[weak self] (response) in
            if let strongSelf = self {
                Log.debug(response.result)
                Log.debug(response.response?.statusCode)
                Log.debug(response.result.value)

                if response.response?.statusCode == 200 {
                    KSToastView.ks_showToast(String.localize("MSG_SUC_EMAIL_CHANGE"))
                } else {
                    strongSelf.user?.email = existingEmail
                    strongSelf.emailCell.detailTextLabel?.text = existingEmail
                }
            }
        }
    }
    
    func changeMobile(user: User) {
        mobileCell.detailTextLabel?.text = user.mobileCode + " " + user.mobileNumber
        UserService.changeMobile(user) {response in
            Log.debug(response.result)
            Log.debug(response.response?.statusCode)
            Log.debug(response.result.value)
            SettingViewController.reactivate()
        }
    }
    
    func changeLanguage(language: Language) {
        languageCell.detailTextLabel?.text = language.languageName
        self.user?.languageId = language.languageId
        Context.setCc(language.cultureCode)
        UserService.save(self.user!) {response in
            Log.debug(response.result)
            Log.debug(response.response?.statusCode)
            Log.debug(response.result.value)
        }
        NotificationCenter.default.post(name: Constants.Notification.langaugeChanged, object: nil)
    }
    
    func changePassword(user: User) {
//        UserService.changePassword(user) {response in
//            if response.response?.statusCode == 200 {
//                KSToastView.ks_showToast(String.localize("MSG_SUC_PASSWORD_CHANGE"))
//            }
//        }
    }
    
}
