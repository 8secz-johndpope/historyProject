//
//  MMScanQRCodeController.swift
//  QRCodeReader.swift
//
//  Created by Tony Fung on 8/3/2016.
//  Copyright © 2016年 Yannick Loriot. All rights reserved.
//

import UIKit
import AVFoundation
import ObjectMapper
import PromiseKit

class MMScanQRCodeController: MmViewController {
    
    private var cameraView = ReaderOverlayView()
    private var cancelButton = UIButton()
  
    var codeReader: QRCodeReader!
    
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        codeReader = QRCodeReader(metadataObjectTypes: [AVMetadataObject.ObjectType.qr])
        view.backgroundColor = .black
        
        codeReader.didFindCode = { [weak self] resultAsObject in
            if let weakSelf = self {
                
                //                let optionMenu = UIAlertController(title: nil, message: resultAsObject.value, preferredStyle: .alert)
                //                let cancelAction = UIAlertAction(title: String.localize("LB_CANCEL"), style: .cancel, handler: {
                //                    (alert: UIAlertAction!) -> Void in
                //                })
                //                optionMenu.addAction(cancelAction)
                //                weakSelf.present(optionMenu, animated: true, completion: nil)
                
                weakSelf.handleScannedString(resultAsObject.value)
                
            }
        }
        
        setupUIComponentsWithCancelButtonTitle()
        setupAutoLayoutConstraints()
        
        cameraView.layer.insertSublayer(codeReader.previewLayer, at: 0)
        
        NotificationCenter.default.addObserver(self, selector: #selector(MMScanQRCodeController.orientationDidChanged), name: NSNotification.Name.UIDeviceOrientationDidChange, object: nil)
        
        self.createBackButton()
        self.createRightButton(String.localize("LB_CA_IM_MY_QR"), action: #selector(MMScanQRCodeController.myQRCode))
        self.title = String.localize("LB_CA_IM_SCAN_QRCODE")
        
        initAnalyticLog()
        
        
    }
    
    func initAnalyticLog() {
        initAnalyticsViewRecord(
            viewLocation: "ScanQRCode",
            viewType: "IM"
        )
    }

    override func shouldHaveCollectionView() -> Bool {
        return true
    }

    
    @objc func myQRCode (_ sender : UIBarButtonItem){
        // Action tag
        self.view.analyticsViewKey = self.analyticsViewRecord.viewKey
        self.view.recordAction(
            .Tap,
            sourceRef: "MyQRCode",
            sourceType: .Button,
            targetRef: "MyQRCode",
            targetType: .View
        )
        MyQRCodeViewController.presentQRCodeController(self)
    }
    
    deinit {
        codeReader.stopScanning()
        NotificationCenter.default.removeObserver(self)
    }
    
    func handleScannedString(_ qrString: String) {
        let str = qrString.trim()
        if str.isEmpty {
            return
        }
        
        if Navigator.shared.open(str) {
            //埋点继续保留
            if let url = URL(string: str), let username = EntityURLFactory.getUserNameFromURL(url) {
                firstly {
                    return viewUser(username)
                    }.then { _ -> Void in
                        
                        // Action tag
                        self.view.analyticsViewKey = self.analyticsViewRecord.viewKey
                        self.view.recordAction(
                            .Scan,
                            sourceRef: self.scannedUser.displayName,
                            sourceType: .User,
                            targetRef: self.scannedUser.targetProfilePageTypeString(),
                            targetType: .View
                        )
//                        PushManager.sharedInstance.goToProfile(self.scannedUser,hideTabBar: true)
                        
                    }.always {
//                        self.stopLoading()
                    }.catch { _ -> Void in
                        Log.error("error")
                        self.codeReader.startScanning()
                        
                }
            }
        }  else if Navigator.shared.isValid(url: str) { //说明验证是通过的，浏览器打开
            var q = QBundle()
            q[ROUTER_ON_BROWSER_KEY] = QValue("1")
            let _ = Navigator.shared.open(str, params: q)
        } else if let url = URL(string: str), let scheme = url.scheme, scheme.starts(with: "http") {
            let alert = UIAlertController(title: String.localize("LB_NON_MM_WEB_ADDRESS"), message: str, preferredStyle: .alert)
            alert.addAction(UIAlertAction(title: String.localize("LB_OK"), style: .default, handler: { (_) -> Void in
                if #available(iOS 10.0, *) {
                    UIApplication.shared.open(url)
                } else {
                    UIApplication.shared.openURL(url)
                }
            }))
            alert.addAction(UIAlertAction(title: String.localize("LB_CANCEL"), style: .cancel, handler: { (_) -> Void in
                //
            }))
            
            self.present(alert, animated: true, completion: nil)
            
        } else {
            let alert = UIAlertController(title: String.localize("LB_COPY_TO_CLIPBOARD"), message: str, preferredStyle: .alert)
            alert.addAction(UIAlertAction(title: String.localize("LB_OK"), style: .default, handler: { (_) -> Void in
                UIPasteboard.general.string = str
            }))
            alert.addAction(UIAlertAction(title: String.localize("LB_CANCEL"), style: .cancel, handler: { (_) -> Void in
                //
            }))
            
            self.present(alert, animated: true, completion: nil)
        }
        
        /*
        if let url = URL(string: qrString), let username = EntityURLFactory.getUserNameFromURL(url) {
            
            codeReader.stopScanning() //we pause it first
            self.showLoading()

            firstly {
                return viewUser(username)
            }.then { _ -> Void in
                
                // Action tag
                self.view.analyticsViewKey = self.analyticsViewRecord.viewKey
                self.view.recordAction(
                    .Scan,
                    sourceRef: self.scannedUser.displayName,
                    sourceType: .User,
                    targetRef: self.scannedUser.targetProfilePageTypeString(),
                    targetType: .View
                )
                
                PushManager.sharedInstance.goToProfile(self.scannedUser,hideTabBar: true)
                
            }.always {
                self.stopLoading()
            }.catch { _ -> Void in
                Log.error("error")
                self.codeReader.startScanning()

            }

        }else{
            //incorrect url path
            self.showError(String.localize("MSG_ERR_IM_QR_SCAN"),animated: true)//Fix MM-20903
            Log.error("incorrect qr code format")
        }
         */
    }
    
    private var scannedUser = User()
    
    func viewUser(_ username: String) -> Promise<Any> {
        return Promise{ fulfill, reject in
            UserService.viewWithUserName(username){
                [weak self] (response) in
                if let strongSelf = self {
                    if response.result.isSuccess {
                        if response.response?.statusCode == 200 {
                            strongSelf.scannedUser = Mapper<User>().map(JSONObject: response.result.value) ?? User()
                            if strongSelf.scannedUser.userKey.length == 0{ //Fix MM-20903
                                strongSelf.showError(String.localize("MSG_ERR_IM_QR_SCAN"),animated: true)//Fix MM-20903
                                let error = NSError(domain: "", code: response.response?.statusCode ?? 0, userInfo: nil)
                                reject(error)
                            } else {
                                fulfill("OK")
                            }
                        } else {
                            let error = NSError(domain: "", code: response.response?.statusCode ?? 0, userInfo: nil)
                            reject(error)
                            
                            strongSelf.handleApiResponseError(response, reject: reject)
                        }
                    }
                    else{
                        reject(response.result.error!)
                        strongSelf.handleApiResponseError(response, reject: reject)
                    }
                } else {
                    ErrorLogManager.sharedManager.recordNonFatalError(withException: .NullPointer)
                }
            }
        }
    }

    
    // MARK: - Managing the Orientation
    @objc func orientationDidChanged(_ notification: Notification) {
        cameraView.setNeedsDisplay()
        
        if codeReader.previewLayer.connection != nil {
            let deviceOrientation = UIDevice.current.orientation
            codeReader.previewLayer.connection?.videoOrientation = QRCodeReader.videoOrientation(deviceOrientation: deviceOrientation, withSupportedOrientations: .portrait)
        }
    }
    
    // MARK: - Initializing the AV Components
    
    private func setupUIComponentsWithCancelButtonTitle() {
        cameraView.clipsToBounds = true
        cameraView.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(cameraView)
        
        codeReader.previewLayer.frame = CGRect(x: 0, y: 0, width: view.frame.size.width, height: view.frame.size.height)
        
        if codeReader.previewLayer.connection?.isVideoOrientationSupported == true {
            let deviceOrientation = UIDevice.current.orientation
            codeReader.previewLayer.connection?.videoOrientation = QRCodeReader.videoOrientation(deviceOrientation: deviceOrientation, withSupportedOrientations: .portrait)
        }
        
    }

    
    private func setupAutoLayoutConstraints() {
        let views = ["cameraView": cameraView]
        
        view.addConstraints(NSLayoutConstraint.constraints(withVisualFormat: "V:|[cameraView]|", options: [], metrics: nil, views: views))
        view.addConstraints(NSLayoutConstraint.constraints(withVisualFormat: "H:|[cameraView]|", options: [], metrics: nil, views: views))
     
    }
    
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        startScanning()

    }
    
    override func viewDidAppear(_ animated: Bool){
        super.viewDidAppear(animated)
//        cameraView.animateScanning() //tbc - missing function
    }

    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        stopScanning()
    }

    
    /// Starts scanning the codes.
    func startScanning() {
        codeReader.startScanning()
    }
    
    /// Stops scanning the codes.
    func stopScanning() {
        codeReader.stopScanning()
        
        
//        cameraView.scanningEffect.layer.removeAllAnimations() //tbc - missing function
    }
    

    
}
