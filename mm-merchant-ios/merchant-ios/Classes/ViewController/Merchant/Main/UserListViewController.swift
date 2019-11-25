//
//  UserListViewController.swift
//  merchant-ios
//
//  Created by Koon Kit Chan on 25/9/15.
//  Copyright © 2015 Koon Kit Chan. All rights reserved.
//

import Foundation
import UIKit
import ObjectMapper
import RealmSwift

class UserListViewController : UITableViewController{
    @IBOutlet var userListTableView: UITableView!
    var users : [User] = []
    
    override func viewDidLoad() {
        super.viewDidLoad()
        self.title = "User List View"
        self.showLoading()
        
//        UserService.list(){[weak self] (response) in
//            if let strongSelf = self {
//                strongSelf.stopLoading()
//                if response.result.isSuccess{
//                    strongSelf.users = Mapper<User>().mapArray(JSONObject: response.result.value) ?? []
//                    do{
//                        let realm = try Realm()
//                        try realm.write {
//                            realm.add(strongSelf.users)
//                        }
//                    } catch {
////                        Log.error(error)
//                    }
//                    strongSelf.userListTableView.reloadData()
//                } else {
//                    Alert.alert(strongSelf, title: "User Not Found", message: "User cannot be found at the moment, please retry later")
//                }
//            }
//        }
		
    }
    
    override func tableView(tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return self.users.count
    }
    
    override func tableView(tableView: UITableView, cellForRowAtIndexPath indexPath: IndexPath) -> UITableViewCell {
        let cell = self.userListTableView.dequeueReusableCellWithIdentifier("UserCell")!
        cell.textLabel!.text = self.users[indexPath.row].firstName
        cell.textLabel!.numberOfLines = 0
        cell.textLabel!.lineBreakMode = NSLineBreakMode.byWordWrapping
        cell.detailTextLabel!.text = self.users[indexPath.row].email
        cell.detailTextLabel!.numberOfLines = 0
        cell.detailTextLabel!.lineBreakMode = NSLineBreakMode.byWordWrapping
        cell.bounds = CGRect(x: 0, y: 0, width: CGRectGetWidth(tableView.bounds), height: 99999)
        cell.contentView.bounds = cell.bounds
        cell.layoutIfNeeded()
        
        cell.textLabel!.preferredMaxLayoutWidth = CGRectGetWidth(cell.textLabel!.frame)
        cell.detailTextLabel!.preferredMaxLayoutWidth = CGRectGetWidth(cell.detailTextLabel!.frame)
        return cell
    }
    
    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        
        Alert.alert(self, title: "Item selected", message: "You have selected the number " + String(indexPath.row) + " item")
        
        dispatch_async(dispatch_queue_create("background", DISPATCH_QUEUE_CONCURRENT )) {
            do{
                let realm = try Realm()
//                let retrievedUsers = realm.objects(User).filter("firstName = 'Albert'")
//                print (retrievedUsers)
            }catch {
//                Log.error(error)
            }
        }

    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        MobClick.beginLogPageView("UserListView")
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        MobClick.endLogPageView("UserListView")
    }


    
}

