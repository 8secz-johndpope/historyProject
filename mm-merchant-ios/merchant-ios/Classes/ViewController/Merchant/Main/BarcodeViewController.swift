//
//  barcodeViewController.swift
//  merchant-ios
//
//  Created by Koon Kit Chan on 18/9/15.
//  Copyright © 2015 Koon Kit Chan. All rights reserved.
//

import Foundation
import AVFoundation
import UIKit
import QRCodeReader

class BarcodeViewController: UIViewController, QRCodeReaderViewControllerDelegate {
    @IBOutlet weak var scannedProductTextField: UITextField!
    
    var appDelegate : AppDelegate?

    lazy var reader = QRCodeReaderViewController(metadataObjectTypes: [AVMetadataObjectTypeQRCode])

    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view, typically from a nib.
        if let navigationController = self.navigationController {
            navigationController.navigationBar.isHidden = false
        }
        self.title = "Scan"

        appDelegate = UIApplication.shared.delegate as? AppDelegate
        
        let scanButton : UIBarButtonItem = UIBarButtonItem(title: "Scan", style: UIBarButtonItemStyle.plain, target: self, action: #selector(BarcodeViewController.scanAction(_:)))
        
        self.navigationItem.rightBarButtonItem = scanButton
       
    }
   
    @IBAction func userListButtonClicked(sender: Any) {
        let userStoryBoard = UIStoryboard(name: "User", bundle: nil)
        let userListViewController = userStoryBoard.instantiateViewControllerWithIdentifier("UserListViewController")
        self.navigationController?.pushViewController(userListViewController, animated: true)

    
    }
    
    
    @IBAction func ProfileButtonClicked(sender: UIButton) {
        let userStoryBoard = UIStoryboard(name: "User", bundle: nil)
        let profileViewController = userStoryBoard.instantiateViewControllerWithIdentifier("UserViewController")
        self.navigationController?.pushViewController(profileViewController, animated: true)

        
    }
    
    @IBAction func CollectionViewButtonClicked(sender: UIButton) {
        let productStoryBoard = UIStoryboard(name: "Product", bundle: nil)
        let productCollectionViewController = productStoryBoard.instantiateViewControllerWithIdentifier("ProductCollectionViewController")
        self.navigationController?.pushViewController(productCollectionViewController, animated: true)
        
    }
    
    @IBAction func TableViewButtonClicked(sender: UIButton) {
        let productStoryBoard = UIStoryboard(name: "Product", bundle: nil)
        let productTableViewController = productStoryBoard.instantiateViewControllerWithIdentifier("ProductTableViewController")
        self.navigationController?.pushViewController(productTableViewController, animated: true)
      
    }
    
    
    @IBAction func scanAction(sender: Any) {
        if (!QRCodeReader.supportsMetadataObjectTypes()){
            Alert.alert(self, title: "Media type not support", message: "Your phone does not support the media type")
            return
        }

        reader.delegate = self
        reader.modalPresentationStyle = .FormSheet
        present(reader, animated: true, completion: nil)
    }
    
    // MARK: - QRCodeReader Delegate Methods
    
    func reader(reader: QRCodeReaderViewController, didScanResult result: String){
        Log.debug(result)
        self.scannedProductTextField.text = result
        self.dismiss(animated: true, completion: nil)
    }
    
    func readerDidCancel(reader: QRCodeReaderViewController){
        self.dismiss(animated: true, completion: nil)
    }
    
//    @IBAction func toggle(sender: Any) {
//        navigationController?.setNavigationBarHidden(navigationController?.isNavigationBarHidden == false, animated: true) //or animated: false
//    }
//    
//    override func prefersStatusBarHidden() -> Bool {
//        return navigationController?.isNavigationBarHidden == true
//    }
//    
//    override func preferredStatusBarUpdateAnimation() -> UIStatusBarAnimation {
//        return UIStatusBarAnimation.Fade
//    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        MobClick.beginLogPageView("BarcodeView")
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        MobClick.endLogPageView("BarcodeView")
    }
    
    

}
