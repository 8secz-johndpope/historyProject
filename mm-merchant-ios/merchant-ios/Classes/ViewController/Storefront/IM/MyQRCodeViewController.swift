//
//  MyQRCodeViewController.swift
//  merchant-ios
//
//  Created by Tony Fung on 4/3/2016.
//  Copyright © 2016年 WWE & CO. All rights reserved.
//

import UIKit
import PromiseKit
import ObjectMapper

class MyQRCodeViewController: UIViewController {

    var user = User()
    var qrCodeView : QRCodeView!

    
    private var qrCodeSize = CGSize(width: 300, height: 420)
//    private var tapRecognizer = UITapGestureRecognizer(target: self, action: "tappedDismiss:")
    private var dismissButton = UIButton(type: UIButtonType.custom)
    
    
    static func presentQRCodeController(_ fromViewController: UIViewController){
        let qrCodeViewController = MyQRCodeViewController()
        qrCodeViewController.modalPresentationStyle = .overFullScreen
        qrCodeViewController.modalTransitionStyle = .crossDissolve
        fromViewController.present(qrCodeViewController, animated: true, completion: nil)
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        setupSubViews()
        updateUserView()
    }
    
    func initAnalyticLog(){
        let analyticsViewRecord = AnalyticsViewRecord()
        analyticsViewRecord.viewKey = Utils.UUID()
        analyticsViewRecord.viewDisplayName = "User: \(user.displayName)"
        analyticsViewRecord.viewParameters =  "u=\(user.userKey)"
        analyticsViewRecord.viewLocation = "MyQRCode"
        analyticsViewRecord.viewType = "IM"
        AnalyticsManager.sharedManager.recordView(analyticsViewRecord)
    }
    
    func setupSubViews(){

        dismissButton.frame = self.view.bounds
        self.view.addSubview(dismissButton)
        dismissButton.addTarget(self, action: #selector(MyQRCodeViewController.dismissClicked), for: UIControlEvents.touchDown)
        
        qrCodeView = QRCodeView(frame: CGRect(x: (self.view.frame.width - qrCodeSize.width)/2 , y: (self.view.frame.height - qrCodeSize.height)/2, width: qrCodeSize.width, height: qrCodeSize.height))
        self.view.backgroundColor = UIColor(red: 0, green: 0, blue: 0, alpha: 0.5)  
        self.view.addSubview(qrCodeView)
        
    }
    
    @objc func dismissClicked(_ sender: UIControl){
        Log.debug(sender)
        self.dismiss(animated: true, completion: nil)
		
		NotificationCenter.default.post(name: Constants.Notification.closeQRCodeOnProfileView, object: nil)
    }
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    func reloadUI(){
        qrCodeView.configUser(user)
        initAnalyticLog()
    }
    
    func updateUserView(){
        if(LoginManager.getLoginState() == .validUser){
            firstly{
                return fetchUser()
                }.then { _ -> Void in
                    self.reloadUI()
            }
        }
    }
    

    
    func fetchUser() -> Promise<Any>{
        return Promise{ fulfill, reject in
            UserService.view(){[weak self] (response) in
                if let strongSelf = self {
                    if response.result.isSuccess {
                        if response.response?.statusCode == 200 {
                            
                            strongSelf.user = Mapper<User>().map(JSONObject: response.result.value) ?? User()
                            fulfill("OK")
                        } else {
                            reject(response.result.error!)
                            strongSelf.handleApiResponseError(response, reject: reject)
                        }
                    } else {
                        reject(response.result.error!)
                        strongSelf.handleApiResponseError(response, reject: reject)
                    }
                } else {
                    ErrorLogManager.sharedManager.recordNonFatalError(withException: .NullPointer)
                }
            }
        }
    }

}
