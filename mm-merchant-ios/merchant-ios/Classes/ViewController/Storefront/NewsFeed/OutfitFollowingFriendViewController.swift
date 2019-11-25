//
//  OutfitFollowingFriendViewController.swift
//  merchant-ios
//
//  Created by Vu Dinh Trung on 4/14/16.
//  Copyright © 2016 WWE & CO. All rights reserved.
//

import UIKit
import PromiseKit
import ObjectMapper

class OutfitFollowingFriendViewController: OutfitBrandSelectionViewController {
    private let MarginCollectionView: CGFloat = 64.0
    
    
    private var friends: [User] = []
    
    override func viewDidLoad() {
        super.viewDidLoad()

        styeView()
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    func styeView() {
        self.labelBrandTag.text = String.localize("LB_CA_FRIENDS_TAGGED")
        var frm = self.viewHeader.frame
        frm.size.height = 20
        self.viewHeader.frame = frm
        self.labelHeader.isHidden = true
        
        self.collectionView.frame = CGRect(x: 0, y: self.viewHeader.frame.maxY, width: self.view.bounds.width, height: self.view.bounds.height - self.viewHeader.frame.maxY)
    }
    
    override func loadingData() {
        loadFriend()
    }
    
    func reloadData() -> Void {
        self.dataSource = self.friends
        self.collectionView.reloadData()
    }
    
    func loadFriend() {
        firstly{
            return self.listFriend()
            }.then
            { _ -> Void in
                self.reloadData()
            }.always {
                self.stopLoading()
            }.catch { _ in
                Log.error("error")
        }
    }
    
    func listFriend() -> Promise<Any> {
        return Promise{ fulfill, reject in
            FriendService.listFriends() {
                [weak self] (response) in
                if let strongSelf = self {
                    if response.result.isSuccess {
                        if response.response?.statusCode == 200 {
                            
                            let friend:[User] = Mapper<User>().mapArray(JSONObject: response.result.value) ?? []
                            
                            if friend.count > 0 {
                                strongSelf.friends = friend
                            }
                            
                            fulfill("OK")
                        } else {
                            strongSelf.handleApiResponseError(response, reject: reject)
                        }
                    }
                    else{
                        reject(response.result.error!)
                        strongSelf.handleApiResponseError(response, reject: reject)
                    }
                }
            }
        }
    }
    
    func reloadDataSource() -> Void {
        self.collectionView.reloadData()
    }
    
    override func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        switch (collectionView) {
        case self.collectionView:
            return self.dataSource.count
        case self.collectionViewTop:
            return self.datasourceTop.count
        default:
            return 0
        }
    }
    
    override func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        switch collectionView {
        case self.collectionView:
            let cell = collectionView.dequeueReusableCell(withReuseIdentifier: identifier!, for: indexPath) as! OutfitBrandViewCell
            cell.tag = indexPath.row
            if mode == ModeGetTagList.friendTagList {
                cell.imageView.layer.cornerRadius = cell.imageView.frame.width / 2
                cell.imageView.layer.masksToBounds = true
            }
            setupDataForCell(indexPath, cell: cell)
            if self.dataSource.count > 0 {
                if self.checkExist(self.dataSource[indexPath.row]){
                    cell.imageViewIcon.image = UIImage(named: "icon_checkbox_checked")
                } else {
                    cell.imageViewIcon.image = UIImage(named: "icon_checkbox_unchecked2")
                }
            }
            
            return cell
            
        case self.collectionViewTop:
            let cell = registerClassTop(collectionView, id: userCellId, indexPath: indexPath) as! ObjectCollectionView
            cell.setupDataByUser(self.datasourceTop[indexPath.row] as! User)
            cell.tag = indexPath.row
            return cell
        default:
            return getDefaultCell(collectionView, cellForItemAt: indexPath)
            
        }
    }
    
    override func setupDataForCell(_ indexPath: IndexPath, cell: OutfitBrandViewCell) {
        let user = self.dataSource[indexPath.row]
        cell.setupDataCellByUser(user, mode: .friendTagList)
        
    }
    // action right
    override func didSelectedRightButton(_ sender: UIBarButtonItem) {
        if !selectIndexs.isEmpty {
            var arraySelected = [User]()
            
            for i in 0 ..< selectIndexs.count {
                arraySelected.append(friends[selectIndexs[i]])
            }
            
            self.outfitBrandSelectionViewControllerDelegate?.returnDataSelectedAtIndexs(arraySelected, listMode: ModeGetTagList.friendTagList, selectedIndexs: selectIndexs)
            self.dismiss(animated: true, completion: nil)
        }
    }
    
    override func filter(_ text: String) {
        self.dataSource = self.friends.filter(){ ($0.displayName).lowercased().range(of: text.lowercased()) != nil}
        // update selected Indes
        
        self.collectionView.reloadData()
    }
    
    override func searchBar(_ searchBar: UISearchBar, textDidChange searchText: String){
        if searchBar.text!.length == 0 {
            self.reloadData()
        } else {
            self.filter(searchBar.text!)
        }
    }
    
    
}
