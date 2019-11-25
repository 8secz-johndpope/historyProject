//
//  ContactListViewController.swift
//  merchant-ios
//
//  Created by HungPM on 5/16/16.
//  Copyright © 2016 WWE & CO. All rights reserved.
//

import Foundation

let FriendRequestDidUpdateNotification = "FriendRequestDidUpdateNotification" 

class ContactListViewController: MMPageViewController {
    enum Tab: Int {
        case friend
        case friendRequest
        case company
        case other
    }
        
    private var numberOfPages = 2

    var isForwardChat = false
    var isFromProfile = false
    var isFromUserChat = false
    var isAgent = true
    var friendListMode: FriendListMode = .normalMode
    var conv: Conv?
    var otherMembersInGroup: [User]?
    var chatModel: ChatModel?
    var isFirstLoad = true

    var didTaggingBackHandler: (() -> Void)?
    var didPopHandler: ((User, ChatModel) -> ())?
    var didShareToUserHandler: ((User) -> ())?
    var didPickMerchant: ((Merchant, QueueType) -> ())?

    //MARK:- View lifecycle
    override func viewDidLoad() {
        super.viewDidLoad()

        // for automation purpose
        self.pageAccessibilityId = "IM_FriendList"

        view.backgroundColor = UIColor.white
        
        if isForwardChat {
            title = String.localize("LB_CS_FORWARD_CHAT_TO")
        } else if isFromProfile {
            title = String.localize("LB_CA_FRIEND_LIST")
        }
        else if friendListMode == .tagMode {
            title = String.localize("LB_CA_IM_MENTION_CONTACT")
        }
        else {
            title = String.localize("LB_CA_CONTACT_LIST")
        }
        
        if isAgent {
            numberOfPages = 4
        }
        
        if friendListMode == .shareMode || friendListMode == .tagMode || isForwardChat {
            numberOfPages = 1
            if friendListMode == .tagMode {
                isAgent = false
            }
        }
        
        createLeftButton()
        if !isForwardChat && friendListMode != .shareMode && friendListMode != .tagMode {
            segmentedTitles = createSegmentData()
            if friendListMode == FriendListMode.normalMode {
                createRightBarButton()
            }
            isContainSearchBar = true
        }
        else {
            shouldHaveSegment = false
            SEGMENT_HEIGHT = 0
            isContainSearchBar = false
            SEARCHBAR_HEIGHT = 0
        }
        
        let height = self.view.frame.maxY - tabBarHeight - SEGMENT_Y - (isContainSearchBar ? SEARCHBAR_HEIGHT : 0) - (shouldHaveSegment ? SEGMENT_HEIGHT : 0)
        
        var searchBarMaxY = (isContainSearchBar ? SEARCHBAR_HEIGHT : 0) + SEGMENT_Y
        if shouldHaveSegment {
            searchBarMaxY += SEGMENT_HEIGHT
        }
        
        var vcs = [ContactViewController]()
        
        for index in 0 ..< numberOfPages {
            let viewController = ContactViewController()
            viewController.viewHeight = height
            viewController.searchBarMaxY = searchBarMaxY
            viewController.friendListMode = friendListMode
            viewController.isForwardChat = isForwardChat
            viewController.isFromProfile = isFromProfile
            viewController.tbHeight = tabBarHeight
            viewController.index = index
            if !shouldHaveSegment && !isContainSearchBar {
                viewController.topMargin = CGFloat(0)
            }
            
            viewController.pushViewController = { [weak self] viewController in
                if let strongSelf = self {
                    strongSelf.navigationController?.push(viewController, animated: true)
                }
            }
            
            viewController.dismissSearchBar = { [weak self] in
                if let strongSelf = self {
                    strongSelf.searchBar?.resignFirstResponder()
                }
            }
            
            switch index {
            case Tab.friend.rawValue:
                viewController.viewControllerType = .friendViewController
                
                if friendListMode == .tagMode {
                    viewController.otherMembersInGroup = otherMembersInGroup
                    
                    viewController.dismissViewController = { [weak self] user in
                        if let strongSelf = self {
                            strongSelf.dismiss(animated: true, completion: {
                                if let user = user {
                                    strongSelf.didShareToUserHandler?(user)
                                }
                            })
                        }
                    }
                }
                else if friendListMode == .shareMode {
                    viewController.chatModel = chatModel

                    viewController.didPopHandler = { [weak self] (user, chatModel) in
                        if let strongSelf = self {
                            strongSelf.didPopHandler?(user, chatModel)
                        }
                    }
                }
                else if friendListMode == .attachFriend {
                    viewController.popViewController = { [weak self] user in
                        if let strongSelf = self {
                            strongSelf.didShareToUserHandler?(user)
                            strongSelf.navigationController?.popViewController(animated: true)
                        }
                    }
                }
                
                if isForwardChat {
                    viewController.viewControllerType = .otherViewController
                    viewController.conv = conv
                    viewController.didPickMerchant = { [weak self] (merchant, queueType) in
                        if let strongSelf = self {
                            strongSelf.didPickMerchant?(merchant, queueType)
                        }
                    }
                }
                
                
            case Tab.friendRequest.rawValue:
                viewController.viewControllerType = .friendRequestViewController
                viewController.needUpdateTitle = { [weak self] in
                    if let strongSelf = self {
                        var string = String.localize("LB_CA_FRIENDS_REQUEST")
                        
                        if CacheManager.sharedManager.numberOfFriendRequests > 0 {
                            string = string + "(\(CacheManager.sharedManager.numberOfFriendRequests))"
                        }

                        strongSelf.tab(atIndex: Tab.friendRequest.rawValue, loadTitle: string)
                    }
                }
            case Tab.company.rawValue:
                viewController.viewControllerType = .companyViewController

            case Tab.other.rawValue:
                viewController.viewControllerType = .otherViewController

            default: break
            }
            
            vcs.append(viewController)
        }

        viewControllers = vcs

        NotificationCenter.default.addObserver(self, selector: #selector(didUpdateFriendRequest),
                                                         name: Constants.Notification.refreshFriendRequest, object: nil)
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        
        if isFirstLoad {
            isFirstLoad = false
            if numberOfPages > 1 && CacheManager.sharedManager.numberOfFriendRequests > 0 {
                selectTab(atIndex: Tab.friendRequest.rawValue)
            }
        }
    }
    
    //MARK:- Views
    func createLeftButton() {
        if friendListMode == .normalMode || friendListMode == .attachFriend || friendListMode == .shareMode || isAgent {
            createBackButton()
        } else {
            createBackButton(.cross)
        }
    }
    
    func createRightBarButton() {
        let rightButton = UIButton(type: .custom)
        rightButton.setTitle("", for: UIControlState())
        rightButton.setImage(UIImage(named: "addFriend_icon"), for: UIControlState())
        rightButton.frame = CGRect(x: 0, y: 0, width: 40, height: 40)
        rightButton.contentEdgeInsets = UIEdgeInsets(top: 0, left: 0, bottom: 0, right: Constants.Value.NavigationButtonMargin)
        rightButton.addTarget(self, action: #selector(addFriendTapped), for: .touchUpInside)
        navigationItem.rightBarButtonItem = UIBarButtonItem(customView: rightButton)
        
        setAccessibilityIdForView("UIBT_ADD_FRD", view: rightButton)
    }

    func createSegmentData() ->[String] {
        var arrayTabs = [String]()
        for index in 0 ..< numberOfPages {
            var title = ""
            
            switch index {
            case Tab.friend.rawValue:
                title = String.localize("LB_CA_IM_FRD")
            
            case Tab.friendRequest.rawValue:
                var string = String.localize("LB_CA_FRIENDS_REQUEST")
                if CacheManager.sharedManager.numberOfFriendRequests > 0 {
                    string = string + "(\(CacheManager.sharedManager.numberOfFriendRequests))"
                }

                title = string
                
            case Tab.company.rawValue:
                title = String.localize("LB_CA_CS_CONTACT_COMPANY")
                
            case Tab.other.rawValue:
                title = String.localize("LB_CA_CS_CONTACT_QUEUE")
            
            default: break
            }
            
            arrayTabs.append(title)
        }
        
        return arrayTabs
    }
    
    //MARK:- Actions
    override func backButtonClicked(_ button: UIButton) {
        pageScrollView?.delegate = nil

        if friendListMode == .normalMode || friendListMode == .attachFriend || friendListMode == .shareMode || isAgent {
            super.backButtonClicked(button)
        } else {
            self.dismiss(animated: true, completion: {
                if self.friendListMode == .tagMode {
                    self.didTaggingBackHandler?()
                }
            })
        }
    }

    @objc func addFriendTapped(){
        // Action tag
        view.analyticsViewKey = analyticsViewRecord.viewKey
        view.recordAction(
            .Tap,
            sourceRef: "AddFriend",
            sourceType: .Button,
            targetRef: "AddFriend",
            targetType: .View
        )
        
        navigationController?.push(AddFriendViewController(), animated: true)
    }
    
    //MARK:- Notifications
    @objc func didUpdateFriendRequest() {
        if currentPageIndex == Tab.friendRequest.rawValue {
            if let contactVC = viewControllers?.get(currentPageIndex) as? ContactViewController {
                contactVC.getDataSource()
            }
        }
    }
    
    //MARK:- Config view
    override func shouldHaveCollectionView() -> Bool {
        return false
    }
}
