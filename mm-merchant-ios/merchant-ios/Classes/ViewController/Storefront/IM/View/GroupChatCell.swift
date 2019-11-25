//
//  GroupChatCell.swift
//  merchant-ios
//
//  Created by Vo Huy Hung on 6/15/16.
//  Copyright © 2016 WWE & CO. All rights reserved.
//

import UIKit

let GroupChatHeightOfARow = CGFloat(90)
let GroupChatMaximumUsersInARow = CGFloat(4)
let GroupChatMaximumRows = CGFloat(3)
let GroupChatPaddingTop = CGFloat(15)
let GroupChatMinimumLineSpacing = CGFloat(5)

class GroupChatCell: UICollectionViewCell, UICollectionViewDataSource, UICollectionViewDelegate, UICollectionViewDelegateFlowLayout {
    
    private final let UserCellID = "UserCellID"
    var collectionView : UICollectionView!
    var conv: Conv! {
        didSet {
            collectionView.frame = CGRect(x: 0, y: 0, width: self.frame.width, height: self.frame.height)
            collectionView.reloadData()
        }
    }
    
    var userCellTappedHandler: ((_ user: User) -> Void)?
    var userCellImpressionHandler: ((_ user: User) -> Void)?
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        self.setupCollectionView()
    }
    
    func setupCollectionView() {
        
        let spacing = CGFloat(20)
        
        let layout = UICollectionViewFlowLayout()
        layout.scrollDirection = UICollectionViewScrollDirection.vertical
        layout.headerReferenceSize = CGSize.zero
        layout.footerReferenceSize = CGSize.zero
        layout.sectionInset = UIEdgeInsets(top: GroupChatPaddingTop, left: spacing, bottom: 0, right: spacing)
        layout.minimumInteritemSpacing = 0
        layout.minimumLineSpacing = GroupChatMinimumLineSpacing
        layout.itemSize = CGSize(width: frame.width/GroupChatMaximumUsersInARow - spacing, height: GroupChatHeightOfARow)
        
        collectionView = UICollectionView(frame: CGRect(x: 0, y: 0, width: self.frame.width, height: self.frame.height), collectionViewLayout: layout)
        collectionView.contentInset = UIEdgeInsets(top: 0, left: 0, bottom: 0, right: 0)
        collectionView.backgroundColor = UIColor.clear
        collectionView.showsHorizontalScrollIndicator = false
        collectionView.dataSource = self
        collectionView.delegate = self
        collectionView.register(ShareCell.self, forCellWithReuseIdentifier: UserCellID)
        collectionView.isScrollEnabled = false
        self.contentView.addSubview(collectionView)
    }
    
    func expandShowDetailWithHeight(_ theHeight:CGFloat) {
        UIView.animate(withDuration: 0.3, animations: { 
            self.collectionView.frame = CGRect(x: self.collectionView.x, y: self.collectionView.y, width: self.collectionView.size.width, height: theHeight)
        }) 
    }
    
    func collapseRemoveDetailWithHeight(_ theHeight:CGFloat) {
        UIView.animate(withDuration: 0.3, animations: {
            self.collectionView.frame = CGRect(x: self.collectionView.x, y: self.collectionView.y, width: self.collectionView.size.width, height: theHeight)
        }) 
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    //MARK: CollectionView Data Source, Delegate Method
    
    func numberOfSections(in collectionView: UICollectionView) -> Int {
        return 1
    }
    
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return conv.userList.count
    }
    
    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        
        let cell = collectionView.dequeueReusableCell(withReuseIdentifier: UserCellID, for: indexPath) as! ShareCell
        
        if let userKey  = self.conv.userList[indexPath.row].userKey {
            
            var optionalUser = CacheManager.sharedManager.cachedUserForUserKey(userKey)
            if optionalUser == nil  {
                optionalUser = self.conv.userList[indexPath.row].userObj
            }
            
            if let user = optionalUser {
                cell.label.text = user.displayName
                cell.label.textColor = UIColor.black
                cell.loadImageKey(user.profileImage, category: .user)
                
                if user.isCurator == 0 {
                    cell.imageViewDiamond.isHidden = true
                } else {
                    cell.imageViewDiamond.isHidden = false
                }
                
                if let callback = self.userCellImpressionHandler {
                    callback(user)
                }
            }
            
        } else {
            cell.label.text = ""
            cell.imageView.image = nil
            cell.imageViewDiamond.isHidden = true
        }
    
        return cell
    }
    
    func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        
        if let callback = self.userCellTappedHandler, let user = self.conv.userList[indexPath.row].userObj {
            callback(user)
        }
    }
}
