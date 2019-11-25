//
//  CustomPhotoAlbumHelper.swift
//  merchant-ios
//
//  Created by khanh.nguyen on 2/9/17.
//  Copyright © 2017 WWE & CO. All rights reserved.
//

import UIKit
import Photos
class CustomAlbumHelper: NSObject {
    static let AlbumName = "MyMM Images"
    
    class func fetchAssetCollectionForAlbum() -> PHAssetCollection? {
        let fetchOptions = PHFetchOptions()
        fetchOptions.predicate = NSPredicate(format: "title = %@", CustomAlbumHelper.AlbumName)
        
        let collection = PHAssetCollection.fetchAssetCollections(with: .album, subtype: .any, options: fetchOptions)
        
        if collection.count > 0 {
            return collection.object(at: 0)
        }
        return nil
    }
    
    class func requestAcessPhotoLibrary(_ completion : @escaping (_ success: Bool) -> Void) {
        
        if PHPhotoLibrary.authorizationStatus() != PHAuthorizationStatus.notDetermined {
            completion(PHPhotoLibrary.authorizationStatus() ==  PHAuthorizationStatus.authorized ?  true : false)
        }else {
            PHPhotoLibrary.requestAuthorization({ (status: PHAuthorizationStatus) -> Void in
                ()
                completion(status ==  PHAuthorizationStatus.authorized ?  true : false)
            })
        }
        
    }
    
    @objc class func saveImageToAlbum(_ image: UIImage, completion: ((Bool, NSError) -> ())? = nil) {
        requestAcessPhotoLibrary { (success: Bool) in
            if success {
                if let assetCollection = self.fetchAssetCollectionForAlbum() {
                    self.save(assetCollection, image: image, completion: completion)
                }else {
                    PHPhotoLibrary.shared().performChanges({
                        PHAssetCollectionChangeRequest.creationRequestForAssetCollection(withTitle: CustomAlbumHelper.AlbumName)
                    }) { success, error in
                        if success {
                            if let assetCollection = self.fetchAssetCollectionForAlbum() {
                                self.save(assetCollection, image: image, completion: completion)
                            }
                        } else {
                            //handle error here
                            dispatch_async_safely_to_main_queue({
                                if let nserror = error as NSError? {
                                    completion?(false, nserror)
                                }else{
                                    let newNsError = NSError(domain: "", code: 0, userInfo: nil) as NSError
                                    completion?(false, newNsError)
                                }
                                
                                
                            })
                        }
                    }
                }
            }
        }
    }
    
    class func save(_ assetCollection: PHAssetCollection, image: UIImage, completion: ((Bool, NSError) -> ())? = nil) {
        PHPhotoLibrary.shared().performChanges({
            let assetChangeRequest = PHAssetChangeRequest.creationRequestForAsset(from: image)
            let assetPlaceHolder = assetChangeRequest.placeholderForCreatedAsset
            let albumChangeRequest = PHAssetCollectionChangeRequest(for: assetCollection)
            let enumeration: NSArray = [assetPlaceHolder!]
            albumChangeRequest!.addAssets(enumeration)
            
            }, completionHandler: { (success, error) in
                dispatch_async_safely_to_main_queue({
                    completion?(success, error ?? NSError(domain: "", code: 0, userInfo: nil))
                })
            } as? (Bool, Error?) -> Void)
    }
}
