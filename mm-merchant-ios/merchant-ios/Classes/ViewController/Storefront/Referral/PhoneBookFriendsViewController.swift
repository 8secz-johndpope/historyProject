//
//  PhoneBookFriendsViewController.swift
//  merchant-ios
//
//  Created by khanh.nguyen on 2/8/17.
//  Copyright © 2017 WWE & CO. All rights reserved.
//

import UIKit

class PhoneBookFriendsViewController: MmViewController, PhoneBookFriendCellDelegate {

    private var dataSources : [Contact] = [] {
        didSet {
            imageView.isHidden = dataSources.count != 0
            self.collectionView.isHidden = dataSources.count == 0
        }
    }
    var friendLists = [Contact]()
    var searchBar = UISearchBar()
    private final let SearchBarHeight = CGFloat(40)
    private final let CellHeight = CGFloat(60)
    private final let PhoneBookAddFriendViewCellId = "PhoneBookAddFriendViewCellId"
    private final let PhoneBookFriendViewCellId = "PhoneBookFriendViewCellId"
    var imageView = UIImageView()
    
    override func viewDidLoad() {
        super.viewDidLoad()

        createSearchBar()
        setupCollectionView()
        setupImageView()
        self.createBackButton()
        self.title = String.localize("LB_CA_PHONEBOOK_FRIEND")
        
        ContactHelper.getAllContacts { (result : [Contact]?, success : Bool) in
            if let contacts = result, success {
                //TODO : hard code for testing
            
                self.dataSources = self.hardCodeOnDataSource(contacts)
                self.friendLists = self.hardCodeOnDataSource(contacts)
                self.collectionView.reloadData()
            }
        }
        
    }

    func setupImageView() {
        imageView.image = UIImage(named: "no_contact_icon")
        self.view.addSubview(imageView)
        imageView.isHidden = true
        if let image = self.imageView.image {
            imageView.frame = CGRect(x: (self.view.bounds.sizeWidth - image.size.width)/2, y: (self.view.bounds.sizeHeight - image.size.height)/2, width: image.size.width, height: image.size.height)
        }

    }
    func hardCodeOnDataSource(_ contact: [Contact]) -> [Contact] {
        return contact
    /*
        var result = contact
        if result.count > 0 {
            result[0].type = .ADDFRIEND
        }
        if result.count > 1 {
            result[1].type = .CHATFRIEND
        }
        if result.count > 2 {
            result[2].type = .INVITE
        }
        
        let allContact = Contact()
        allContact.displayName = String.localize("LB_CA_PHONEBOOK_FRIEND_NO")
        allContact.type = .ADDALL
        allContact.totalFriendNumber = 2
        
        result.insert(allContact, at: 0)
        
        return result
    */
    }
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }

    func setupCollectionView() {
        self.collectionView.frame.originY = searchBar.frame.maxY
        self.collectionView.frame.sizeHeight = self.view.frame.sizeHeight - searchBar.frame.maxY
        
        self.collectionView.register(PhoneBookFriendViewCell.self, forCellWithReuseIdentifier: PhoneBookFriendViewCellId)
        self.collectionView.register(PhoneBookAddFriendCollectionViewCell.self, forCellWithReuseIdentifier: PhoneBookAddFriendViewCellId)
    }
    
    func createSearchBar() {
        searchBar.delegate = self
        searchBar.searchBarStyle = UISearchBarStyle.default
        searchBar.showsCancelButton = false
        let yPos = CGFloat(64.0) + ScreenTop
        searchBar.frame = CGRect(x: 0, y: yPos, width: Constants.ScreenSize.SCREEN_WIDTH, height: SearchBarHeight)
        searchBar.placeholder = String.localize("LB_CA_SEARCH")
        view.addSubview(searchBar)
    }
    
    //MARK: - Search Delegate
    private func filter(_ keyword : String?) {
        if let text = keyword {
            self.dataSources = self.friendLists.filter(){ ($0.displayName).lowercased().range(of: text.lowercased()) != nil}
            self.collectionView.reloadData()
        } else {
            // ignore nil
        }
    }
    
    internal func searchBarSearchButtonClicked(_ searchBar: UISearchBar) {
        self.filter(searchBar.text)
        searchBar.resignFirstResponder()
    }
    
    internal func searchBar(_ searchBar: UISearchBar, textDidChange searchText: String) {
        if searchBar.text?.length == 0 {
            self.dataSources = self.friendLists
            self.collectionView.reloadData()
        } else {
            self.filter(searchBar.text)
        }
    }
    
    func searchBarCancelButtonClicked(_ searchBar: UISearchBar) {
        self.view.endEditing(true)
        searchBar.showsCancelButton = false
    }
    
    func styleCancelButton(_ enable: Bool){
        if enable {
            if let _cancelButton = searchBar.value(forKey: "_cancelButton"),
                let cancelButton = _cancelButton as? UIButton {
                cancelButton.isEnabled = enable //comment out if you want this button disabled when keyboard is not visible
                if title != nil {
                    cancelButton.setTitle(String.localize("LB_CANCEL"), for: UIControlState())
                }
            }
        }
    }
    
    func searchBarShouldBeginEditing(_ searchBar: UISearchBar) -> Bool {
        searchBar.showsCancelButton = true
        styleCancelButton(true)
        return true
    }
    
    //MARK: - Collection View
    func numberOfSections(in collectionView: UICollectionView) -> Int {
        return 1
    }
    
    override func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return dataSources.count
    }
    
    override func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        let contact = dataSources[indexPath.row]
        if contact.type == .addfriend {
            if let cell = collectionView.dequeueReusableCell(withReuseIdentifier: PhoneBookAddFriendViewCellId, for: indexPath) as? PhoneBookAddFriendCollectionViewCell {
                cell.setData(contact)
                cell.delegate = self
                return cell
            }
        }else if let cell = collectionView.dequeueReusableCell(withReuseIdentifier: PhoneBookFriendViewCellId, for: indexPath) as? PhoneBookFriendViewCell {
            cell.setData(contact)
            cell.delegate = self
            return cell
        }
        return UICollectionViewCell()
        
        
    }
    
    func getDefaultCell(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell{
        let cell = collectionView.dequeueReusableCell(withReuseIdentifier: "CellId", for: indexPath)
        return cell
    }
    
    func loadingCellForIndexPath(_ indexPath: IndexPath) -> UICollectionViewCell {
        let cell = getDefaultCell(self.collectionView, cellForItemAt: indexPath)
        let activity = UIActivityIndicatorView(activityIndicatorStyle: UIActivityIndicatorViewStyle.gray)
        activity.center = cell.center
        cell.addSubview(activity)
        activity.startAnimating()
        return cell
    }
    
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, sizeForItemAt indexPath: IndexPath) -> CGSize {
        return CGSize(width: view.frame.size.width , height: CellHeight)
    }
    
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, minimumInteritemSpacingForSectionAt section: Int) -> CGFloat {
        return 0.0
    }
    
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, minimumLineSpacingForSectionAt section: Int) -> CGFloat {
        return 0.0
    }
    
    //MARK: Phone Book Cell Delegate
    func didTouchOnInviteButton(_ contact: Contact) {
        if contact.type == .invite {
            let phoneNumber = contact.phoneNumber
            var body: String = ""
            
            if let isReferralEnabled = Context.isReferralPopupEnable(), !isReferralEnabled {
                body = String.localize("SMS_CA_MOBILE_INVITE_CONTACTS")
                body = body.replacingOccurrences(of: "{Displayname}", with: Context.getUserProfile().displayName)
            } else {
                body = String.localize("SMS_CA_MOBILE_INVITE_CONTACTS_RERERRAL")
                body = body.replacingOccurrences(of: "{0}", with: Context.getUserProfile().userKey)
                body = body.replacingOccurrences(of: "{Displayname}", with: Context.getUserProfile().displayName)
            }
            
            ShareManager.sharedManager.sendSMSMessageToInviteFriend(["title" : body , "phoneNumber" : phoneNumber])
        }
    }
}
