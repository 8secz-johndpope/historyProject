//
//  ContactHelper.swift
//  merchant-ios
//
//  Created by khanh.nguyen on 2/8/17.
//  Copyright © 2017 WWE & CO. All rights reserved.
//

import UIKit
import AddressBook

class ContactHelper: NSObject {
    
    class func extractABAddressBookRef(_ abRef: Unmanaged<ABAddressBook>!) -> ABAddressBook? {
        if let ab = abRef {
            return Unmanaged<NSObject>.fromOpaque(ab.toOpaque()).takeUnretainedValue()
        }
        return nil
    }
    
    
    class func getAllContacts(_ completion: @escaping (_ result: [Contact]?, _ success: Bool) -> Void) {
        if (ABAddressBookGetAuthorizationStatus() == ABAuthorizationStatus.notDetermined) {
            var errorRef: Unmanaged<CFError>? = nil
            let addressBook = extractABAddressBookRef(ABAddressBookCreateWithOptions(nil, &errorRef))
            ABAddressBookRequestAccessWithCompletion(addressBook, { success, error in
                if success {
                    completion(self.getContactNames(), true)
                }
                else {
                    completion(nil, false)
                }
            })
        }
        else if (ABAddressBookGetAuthorizationStatus() == ABAuthorizationStatus.denied || ABAddressBookGetAuthorizationStatus() == ABAuthorizationStatus.restricted) {
            completion(nil, false)
        }
        else if (ABAddressBookGetAuthorizationStatus() == ABAuthorizationStatus.authorized) {
            completion(self.getContactNames(), true)
        }
    }
    
    class func getContactNames() -> [Contact] {
        var result = [Contact]()
        var errorRef: Unmanaged<CFError>?
        let addressBook = extractABAddressBookRef(ABAddressBookCreateWithOptions(nil, &errorRef))
        let contactList = ABAddressBookCopyArrayOfAllPeople(addressBook).takeRetainedValue() as Array
        
        for record in contactList {
            let contactPerson: ABRecord = record 
                var fullName = ""
                if let contactFirstName = ABRecordCopyValue(contactPerson, kABPersonFirstNameProperty)?.takeRetainedValue() as? String {
                    fullName += contactFirstName
                }
                if let contactLastName = ABRecordCopyValue(contactPerson, kABPersonLastNameProperty)?.takeRetainedValue() as? String {
                    fullName += contactLastName
                }
                
                if let numbers:ABMultiValue = ABRecordCopyValue(contactPerson, kABPersonPhoneProperty)?.takeRetainedValue() {
                    for ix in 0 ..< ABMultiValueGetCount(numbers) {
                        let value = ABMultiValueCopyValueAtIndex(numbers,ix).takeRetainedValue() as? String
                        if let phoneNumber = value {
                            let user = Contact()
                            user.phoneNumber = phoneNumber
                            user.displayName = fullName
                            result.append(user)
                        }
                        
                    }
                }
                
           
        }
        
        return result
    }
}
