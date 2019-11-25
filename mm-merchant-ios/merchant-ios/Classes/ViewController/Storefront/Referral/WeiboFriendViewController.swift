//
//  WeiboFriendViewController.swift
//  merchant-ios
//
//  Created by khanh.nguyen on 2/6/17.
//  Copyright © 2017 WWE & CO. All rights reserved.
//

import UIKit
import ObjectMapper

class WeiboFriendViewController: MmViewController {

    var dataSource : [WeiboUser] = []
    var friendLists = [WeiboUser]()
    var searchBar = UISearchBar()
    private final let SearchBarHeight = CGFloat(40)
    private final let CellHeight = CGFloat(60)
    private final let CellId = "CellID"
    private final let WeiboUserCollectionViewCellId = "WeiboUserCollectionViewCellId"
    
    override func viewDidLoad() {
        super.viewDidLoad()

        createSearchBar()
        setupCollectionView()
        
        requestWeiboFriends()
        self.createBackButton()
        self.title = String.localize("LB_CA_WEIBO_FRIEND")
        
        self.initAnalyticsViewRecord(viewDisplayName: self.title, viewLocation: "Weibo-FriendsList", viewType: "Referral")
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    
    func setupCollectionView() {
        self.collectionView.frame.originY = searchBar.frame.maxY
        self.collectionView.frame.sizeHeight = self.view.frame.sizeHeight - searchBar.frame.maxY
        
        self.collectionView.register(WeiboUserCollectionViewCell.self, forCellWithReuseIdentifier: WeiboUserCollectionViewCellId)
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
            self.dataSource = self.friendLists.filter(){ ($0.name).lowercased().range(of: text.lowercased()) != nil}
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
            self.dataSource = self.friendLists
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
        return dataSource.count
    }
    
    override func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        if let cell = collectionView.dequeueReusableCell(withReuseIdentifier: WeiboUserCollectionViewCellId, for: indexPath) as? WeiboUserCollectionViewCell {
            cell.setData(dataSource[indexPath.row], inviteClicked: { (user) in
                ShareManager.sharedManager.inviteFriend(String.localize("LB_CA_NATURAL_REF_SNS_MSG"), description: String.localize("LB_CA_NATURAL_REF_SNS_DESC") + "@" + user.name, url: "", image: UIImage(named : "AppIcon"), method: .weiboWall)
                
                self.view.recordAction(.Tap, sourceRef: Constants.SNSFriendReferralEnabled ? "Incentive-Invite" : "Invite", sourceType: .Button, targetRef: "Weibo-Friends", targetType: .Channel)
            })
            return cell
        }
        return UICollectionViewCell()
        
    }
    
    func getDefaultCell(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell{
        let cell = collectionView.dequeueReusableCell(withReuseIdentifier: CellId, for: indexPath)
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
        if self.dataSource.count == 0{
            return collectionView.frame.size
        }
        return CGSize(width: view.frame.size.width , height: CellHeight)
    }
    
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, minimumInteritemSpacingForSectionAt section: Int) -> CGFloat {
        return 0.0
    }
    
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, minimumLineSpacingForSectionAt section: Int) -> CGFloat {
        return 0.0
    }
    
    //MARK:- Weilbo Service
    func requestWeiboOAuth() {
        let req = WBAuthorizeRequest()
        req.redirectURI = "https://mymm.com"
        req.scope = "all"
        WeiboSDK.send(req)
        NotificationCenter.default.addObserver(self, selector: #selector(WeiboFriendViewController.receivedAuthResponse), name: NSNotification.Name("weibo.receivedAuthResponse"), object: nil)
    }
    
    @objc func receivedAuthResponse() { //callback from auth
        requestWeiboFriends()
    }
    
    override func shouldHaveCollectionView() -> Bool {
        return true
    }
    
    func requestWeiboFriends() {
        
        NotificationCenter.default.removeObserver(self, name: NSNotification.Name(rawValue: "weibo.receivedAuthResponse"), object: nil)
        
        guard let token = ShareManager.sharedManager.weiboToken, Date().compare(token.expiryDate as Date) == .orderedAscending else {
            requestWeiboOAuth()
            return
        }

        
        _ = WBHttpRequest(accessToken: token.accessToken, url: "https://api.weibo.com/2/friendships/friends.json", httpMethod: "GET", params: ["source": Constants.weiboAppID, "uid": token.userID, "access_token": token.accessToken], queue: nil) { (wbRequest, response, error) in
            if let response = response as? [String: Any] {
                if let jsonArray = response["users"] as? [[String: Any]] {
                    let users = Mapper<WeiboUser>().mapArray(JSONArray: jsonArray)
                    self.dataSource = users
                    self.friendLists = users
                    self.collectionView.reloadData()
                }
            }
        }
        
    }
    

}
