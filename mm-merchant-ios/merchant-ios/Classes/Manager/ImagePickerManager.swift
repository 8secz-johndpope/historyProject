//
//  ImagePickerManager.swift
//  merchant-ios
//
//  Created by Stephen Yuen on 26/5/2016.
//  Copyright © 2016 WWE & CO. All rights reserved.
//

import Foundation
import UIKit
import Photos

protocol ImagePickerManagerDelegate: class {
    func didPickImage(_ image: UIImage!)
}

class ImagePickerManager: NSObject, UINavigationControllerDelegate, UIImagePickerControllerDelegate, ImageCropViewControllerDelegate {
    
    weak private var viewController: UIViewController!
    private var imagePickerController = UIImagePickerController()
    weak var delegate: ImagePickerManagerDelegate?
    var requiredSquareImage = true
    
    init(viewController: UIViewController, withDelegate delegate: ImagePickerManagerDelegate? = nil) {
        self.viewController = viewController
        self.delegate = delegate
    }
    
    func presentDefaultActionSheet(preferredCameraDevice cameraDevice: UIImagePickerControllerCameraDevice = .front) {
        let alertController = UIAlertController(title: nil, message: nil, preferredStyle: .actionSheet)
        let openCameraAction = UIAlertAction(title: String.localize("LB_TAKE_PHOTO"), style: .default, handler: { (alert: UIAlertAction!) -> Void in
            self.openCamera(withDevice: cameraDevice)
        })
        
        let openPhotoLibraryAction = UIAlertAction(title: String.localize("LB_PHOTO_LIBRARY"), style: .default, handler: { (alert: UIAlertAction!) -> Void in
            self.openPhotoLibrary()
        })
        
        let cancelAction = UIAlertAction(title: String.localize("LB_CANCEL"), style: .cancel, handler: nil)
        
        alertController.addAction(openCameraAction)
        alertController.addAction(openPhotoLibraryAction)
        alertController.addAction(cancelAction)
        
        viewController.present(alertController, animated: true, completion: nil)
        alertController.view.tintColor = UIColor.alertTintColor()
    }
    
    func openCamera(withDevice cameraDevice: UIImagePickerControllerCameraDevice = .front) {
        if UIImagePickerController.isSourceTypeAvailable(.camera) {
            
            Utils.checkCameraPermissionWithCallBack({[weak self] (granted) in
                if let strongSelf = self, granted {
                    strongSelf.imagePickerController.sourceType = .camera
                    strongSelf.imagePickerController.cameraDevice = cameraDevice
                    strongSelf.imagePickerController.delegate = self
                    strongSelf.viewController.present(strongSelf.imagePickerController, animated: true, completion: nil)
                }
            })
            
        } else {
            Alert.alert(viewController, title: "Camera not found", message: "Cannot access the front camera. Please use photo gallery instead.")
        }
    }
    
    func openPhotoLibrary() {
        
        let authStatus = Utils.checkPhotoPermission()
        
        if authStatus != .authorized && authStatus != .notDetermined {
            return
        }
        
        if authStatus == .notDetermined {
            PHPhotoLibrary.requestAuthorization({ (authStatus) in
                if authStatus != .authorized {
                    dispatch_async_safely_to_main_queue({
                        TSAlertView_show(String.localize("LB_CA_IM_ACCESS_PHOTOS_PERMIT"), message: String.localize("LB_CA_IM_ACCESS_PHOTOS_DENIED"), labelCancel: nil)
                    })
                }
                else {
                    dispatch_async_safely_to_main_queue({
                        self.showPhotoPicker()
                    })
                }
            })
        }
        else {
            self.showPhotoPicker()
        }
    }
    
    func showPhotoPicker() {
        imagePickerController.sourceType = .photoLibrary
        imagePickerController.delegate = self
        dispatch_async_safely_to_main_queue({
            if UIDevice.current.userInterfaceIdiom == .phone {
                self.viewController.present(self.imagePickerController, animated: true, completion: nil)
            } else {
                Alert.alert(self.viewController, title: "Tablet not suported", message: "Tablet is not supported in this function")
            }
        })
        
    }
    
    // UIImagePickerController delegates
    
    func imagePickerController(_ picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [String : Any]) {
        imagePickerController.dismiss(animated: true) {
//            var image = (info[UIImagePickerControllerOriginalImage] as? UIImage)!
//            image = image.normalizedImage()
            if let image = (info[UIImagePickerControllerOriginalImage] as? UIImage)?.normalizedImage() {
                if self.requiredSquareImage {
                    let imageCropViewController = ImageCropViewController(image: image.copy() as! UIImage)
                    imageCropViewController?.blurredBackground = true
                    imageCropViewController?.delegate = self
                    imageCropViewController?.title = String.localize("LB_CA_EDIT_PICTURE")
                    
                    self.viewController.navigationController?.push(imageCropViewController, animated: true)
                } else {
                    self.delegate?.didPickImage(image)
                }
            }
        }
    }
    
    func imagePickerControllerDidCancel(_ picker: UIImagePickerController) {
        viewController.dismiss(animated: true) { () -> Void in
            
        }
    }
    
    // ImageCropViewController delegate
    
    func imageCropViewControllerSuccess(_ controller: UIViewController!, didFinishCroppingImage croppedImage: UIImage!) {
        delegate?.didPickImage(croppedImage)
        viewController.navigationController?.popViewController(animated: true)
    }
    
    func imageCropViewControllerDidCancel(_ controller: UIViewController!) {
        
    }
    
}
