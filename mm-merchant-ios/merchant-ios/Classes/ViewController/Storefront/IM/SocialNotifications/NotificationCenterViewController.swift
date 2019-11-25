//
//  NotificationCenterViewController.swift
//  storefront-ios
//
//  Created by Kam on 28/3/2018.
//  Copyright © 2018 WWE & CO. All rights reserved.
//

import UIKit

enum NotificationType: Int {
    case like = 0,
    comment,
    follower
}

class NotificationCenterViewController: MmViewController {
    
    private final let IMSocialCellID = "IMSocialCell"
    private final let CellHeight: CGFloat = 65
    private var postLikedUnread = 0
    private var postCommentUnread = 0
    private var followUnread = 0
    
    override func viewDidLoad() {
        super.viewDidLoad()
        self.createBackButton()
        self.collectionView.register(IMSocialCell.NibObject(), forCellWithReuseIdentifier: IMSocialCellID)
        NotificationCenter.default.addObserver(self, selector: #selector(getSocialMessageUnreadCount),
                                               name: NSNotification.Name(rawValue: SocialMessageUnreadChangedNotification), object: nil)
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        getSocialMessageUnreadCount()
    }
    
    @objc func getSocialMessageUnreadCount() {
        postLikedUnread = SocialMessageManager.sharedManager.postLikedUnread
        postCommentUnread = SocialMessageManager.sharedManager.postCommentUnread
        followUnread = SocialMessageManager.sharedManager.followUnread
        collectionView.reloadData()
    }
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    override func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return 3
    }
    
    override func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        
        let cell = collectionView.dequeueReusableCell(withReuseIdentifier: IMSocialCellID, for: indexPath) as! IMSocialCell
        
        if let notificationType = NotificationType(rawValue: indexPath.row) {
            switch notificationType {
            case .like:
                cell.imageView.image = UIImage(named: "like-1")
                cell.lblTitle.text = String.localize("LB_CA_NOTIFICATION_LIKE")
                
                if postLikedUnread == 0 {
                    cell.lblBadge.isHidden = true
                }
                else {
                    cell.lblBadge.isHidden = false
                    if postLikedUnread > 99 {
                        cell.lblBadge.text = "99+"
                        cell.lblBadge.font = UIFont.systemFont(ofSize: 8)
                    }
                    else {
                        cell.lblBadge.text = "\(postLikedUnread)"
                        cell.lblBadge.font = UIFont.systemFont(ofSize: 11)
                    }
                }
                
            case .comment:
                cell.imageView.image = UIImage(named: "sn_comment")
                cell.lblTitle.text = String.localize("LB_CA_NOTIFICATION_COMMENT")
                
                if postCommentUnread == 0 {
                    cell.lblBadge.isHidden = true
                }
                else {
                    cell.lblBadge.isHidden = false
                    if postCommentUnread > 99 {
                        cell.lblBadge.text = "99+"
                        cell.lblBadge.font = UIFont.systemFont(ofSize: 8)
                    }
                    else {
                        cell.lblBadge.text = "\(postCommentUnread)"
                        cell.lblBadge.font = UIFont.systemFont(ofSize: 11)
                    }
                }
                
            case .follower:
                cell.imageView.image = UIImage(named: "fans")
                cell.lblTitle.text = String.localize("LB_CA_NOTIFICATION_NEW_FOLLOWER")
                
                if followUnread == 0 {
                    cell.lblBadge.isHidden = true
                }
                else {
                    cell.lblBadge.isHidden = false
                    if followUnread > 99 {
                        cell.lblBadge.text = "99+"
                        cell.lblBadge.font = UIFont.systemFont(ofSize: 8)
                    }
                    else {
                        cell.lblBadge.text = "\(followUnread)"
                        cell.lblBadge.font = UIFont.systemFont(ofSize: 11)
                    }
                }
            }
        }
        return cell
    }
    
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, sizeForItemAt indexPath: IndexPath) -> CGSize {
        return CGSize(width: self.view.frame.size.width , height: CellHeight)
    }
    
    func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        let viewController = SocialNotificationViewController()
        if let notificationType = NotificationType(rawValue: indexPath.row) {
            switch notificationType {
            case .like:
                viewController.socialMessageType = .postLiked
            case .comment:
                viewController.socialMessageType = .postComment
            case .follower:
                viewController.socialMessageType = .follow
            }
        }
        self.navigationController?.push(viewController, animated: true)
    }
        
}
