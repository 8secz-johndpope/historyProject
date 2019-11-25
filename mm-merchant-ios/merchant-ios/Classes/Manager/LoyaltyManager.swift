//
//  LoyaltyManager.swift
//  merchant-ios
//
//  Created by Quang Truong Dinh on 2/27/17.
//  Copyright © 2017 WWE & CO. All rights reserved.
//

import Foundation
import ObjectMapper
import PromiseKit
import Kingfisher

class LoyaltyManager{
    static var cachedLoyalties = [Loyalty]()
    static var cachedPrivilegeLoyalties = [Loyalty]()
    static var cachedPrivileges = [Privilege]()
    
    class func fetchLoyaltyStatusList(){
        LoyaltyManager.handleListLoyaltyStatus(true, success: { (loyalties) in
            
        }) { (errorType) in
            
        }
    }
    
    class func handleListLoyaltyStatus(_ isReload: Bool = false, success: (([Loyalty])->())?, failure: ((Error?)->())?){
        if !isReload{
            if !LoyaltyManager.cachedLoyalties.isEmpty{
                success?(LoyaltyManager.cachedLoyalties)
                return
            }
        }
        
        firstly {
            return LoyaltyManager.listLoyaltyStatus()
            }.then { response -> Void in
                if let loyalties = response as? [Loyalty]{
                    LoyaltyManager.cachedLoyalties = loyalties
                    success?(loyalties)
                }
            }.always {
                
            }.catch { error -> Void in
                failure?(error)
        }
    }
    
    class func listLoyaltyStatus() -> Promise<Any> {
        return Promise { fulfill, reject in
            LoyaltyService.listLoyaltyStatus({ (response) in
                let statusCode = response.response?.statusCode ?? 0
                
                if response.result.isSuccess {
                    if statusCode == 200 {
                        if let loyalties = Mapper<Loyalty>().mapArray(JSONObject: response.result.value) {
                            fulfill(loyalties)
                            return
                        } else {
                            ErrorLogManager.sharedManager.recordNonFatalError(withException: .DataIsEmpty)
                        }
                        
                        fulfill("OK")
                    } else {
                        let error = NSError(domain: "", code: statusCode, userInfo: nil)
                        reject(error)
                    }
                } else {
                    reject(response.result.error ?? NSError(domain: "", code: 0, userInfo: nil))
                }
            })
        }
    }
    
    class func handleGetLoyaltyPrivileges(_ isReload: Bool = false, success: (([Loyalty], [Privilege])->())?, failure: ((Error?)->())?){
        if !isReload{
            if !LoyaltyManager.cachedPrivilegeLoyalties.isEmpty && !LoyaltyManager.cachedPrivileges.isEmpty{
                success?(LoyaltyManager.cachedPrivilegeLoyalties, LoyaltyManager.cachedPrivileges)
                return
            }
        }
        
        firstly {
            return LoyaltyManager.getLoyaltyPrivileges()
            }.then { response -> Void in
                if let getPrivilegesResponse = response as? GetPrivilegesResponse{
                    let privileges = getPrivilegesResponse.privileges
                    let loyalties = getPrivilegesResponse.loyalties
                    for loyalty in loyalties{
                        for loyaltyPrivilege in loyalty.loyaltyPrivileges{
                            if let privilege = privileges.filter({$0.privilegeId == loyaltyPrivilege.privilegeId}).first {
                                loyaltyPrivilege.privilege = privilege.clone()
                            }
                        }
                    }
                    
                    LoyaltyManager.cachedPrivilegeLoyalties = loyalties
                    LoyaltyManager.cachedPrivileges = privileges
                    success?(loyalties, privileges)
                }
            }.always {
                
            }.catch { error -> Void in
                failure?(error)
        }
    }
    
    class func getLoyaltyPrivileges() -> Promise<Any> {
        return Promise { fulfill, reject in
            _ = LoyaltyService.getLoyaltyPrivileges({ (response) in
                let statusCode = response.response?.statusCode ?? 0
                
                if response.result.isSuccess {
                    if statusCode == 200 {
                        if let loyalties = Mapper<GetPrivilegesResponse>().map(JSONObject: response.result.value) {
                            fulfill(loyalties)
                            return
                        } else {
                            ErrorLogManager.sharedManager.recordNonFatalError(withException: .DataIsEmpty)
                        }
                        
                        fulfill("OK")
                    } else {
                        let error = NSError(domain: "", code: statusCode, userInfo: nil)
                        reject(error)
                    }
                } else {
                    reject(response.result.error ?? NSError(domain: "", code: 0, userInfo: nil))
                }
            })
        }
    }
    
    class func setLoyaltyImage(_ imageView: UIImageView, loyaltyStatusId: Int, placeholderImage: UIImage? = nil, completion: ((_ image: Image?, _ error: NSError?) -> ())? = nil){
        let privilegeLoyalties = LoyaltyManager.cachedPrivilegeLoyalties.filter{$0.loyaltyStatusId == loyaltyStatusId}
        
        if let privilegeLoyalty = privilegeLoyalties.first, let imageUrl = URL(string: LoyaltyService.MARKETING_LOYALTY_PATH + "/" + privilegeLoyalty.iconUrl){
            imageView.mm_setImageWithURL(imageUrl, placeholderImage: placeholderImage, clipsToBounds: true, contentMode: .scaleAspectFit, progress: nil, optionsInfo: nil, completion: { (image, error, cacheType, imageURL) in
                if let completion = completion {
                    completion(image, error)
                }
            })
        }
    }
    
    class func setPrivilegeImage(_ imageView: UIImageView, privilegeId: Int, placeholderImage: UIImage? = nil, completion: ((_ image: Image?, _ error: NSError?) -> ())? = nil){
        let privileges = LoyaltyManager.cachedPrivileges.filter{$0.privilegeId == privilegeId}
        
        if let privilege = privileges.first, let imageUrl = URL(string: LoyaltyService.MARKETING_LOYALTY_PATH + "/" + privilege.iconUrl){
            imageView.mm_setImageWithURL(imageUrl, placeholderImage: placeholderImage, clipsToBounds: true, contentMode: .scaleAspectFit, progress: nil, optionsInfo: nil, completion: { (image, error, cacheType, imageURL) in
                if let completion = completion {
                    completion(image, error)
                }
            })
        }
    }
    
    class func getLoyaltyById(_ loyaltyStatusId: Int) -> Loyalty?{
        let privilegeLoyalties = LoyaltyManager.cachedPrivilegeLoyalties.filter{$0.loyaltyStatusId == loyaltyStatusId}
        return privilegeLoyalties.first
    }
    
    class func getPrivilegesByIds(_ ids: [Int]) -> [Privilege]{
        let privileges = LoyaltyManager.cachedPrivileges.filter{ids.contains($0.privilegeId)}
        return privileges
    }
    
    class func getMemberCardTypes() -> [MemberCardType]{
        var memberCardTypes = [MemberCardType]()
        for privilegeLoyalty in LoyaltyManager.cachedPrivilegeLoyalties{
            if let memberCardType = MemberCardType(rawValue: privilegeLoyalty.loyaltyStatusId){
                memberCardTypes.append(memberCardType)
            }
        }
        
        return memberCardTypes
    }
    
    class func getFooterLink(_ footer: LoyaltyFooter) -> String{
        return LoyaltyService.MARKETING_LOYALTY_PATH + "/" + footer.url
    }
    
    class func getLoyaltyPrivilegePageLink(_ loyaltyPrivilege: LoyaltyPrivilege) -> String{
        return LoyaltyService.MARKETING_LOYALTY_PATH + "/" + loyaltyPrivilege.privilegePageUrl
    }
}
