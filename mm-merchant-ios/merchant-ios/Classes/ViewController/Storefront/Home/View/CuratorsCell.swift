//
//  CuratorsCell.swift
//  merchant-ios
//
//  Created by Quang Truong Dinh on 5/26/16.
//  Copyright © 2016 WWE & CO. All rights reserved.
//

import Foundation

protocol CuratorsCellDelegate: NSObjectProtocol {
    func didSelectUser(_ user: User)
    func didSelectAllUsers()
}

class CuratorsCell: UICollectionViewCell, UICollectionViewDataSource, UICollectionViewDelegate, UICollectionViewDelegateFlowLayout {
    
    override func ssn_onDisplay(_ tableView: UIScrollView, model: AnyObject, atIndexPath indexPath: IndexPath, reused: Bool) {
        if let model = model as? CommunityUserCellModel {
            if let userList = model.userList {
                 curatorList = userList
            }
        }
    }
    
    static let CellIdentifier = "CuratorsCellID"
    static let CuratorsCellPaddingBottom:CGFloat = 10.0
    
    private var collectionView: UICollectionView!
    
    private var currentPage = 0
    
    weak var delegate: CuratorsCellDelegate?
    private var maximumCurators:Int = 12
    
    var impressionKey:String?
    let MarginLeft = CGFloat(10)
    let Padding = CGFloat(12)
    
    var curatorList = [User]() {
        didSet {
            let profile = Context.getUserProfile()
            if profile.isCurator == 1 {
                curatorList.insert(profile, at: 0)
                maximumCurators = 13
            }
            self.collectionView.reloadData()
        }
    }
    
    var sourceRef = ""

    override init(frame: CGRect) {
        super.init(frame: frame)
        
        self.backgroundColor = UIColor.white
        
        setupCollectionView()
        contentView.addSubview(collectionView)
        
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override func layoutSubviews() {
        super.layoutSubviews()
    }
    
    // MARK: Views
    
    func setupCollectionView() {
        let layout = UICollectionViewFlowLayout()
        layout.scrollDirection = .horizontal
        
        collectionView = UICollectionView(frame: CGRect(x: 0, y: 0, width: frame.width, height: self.bounds.sizeHeight), collectionViewLayout: layout)
        collectionView.contentInset = UIEdgeInsets(top: 0, left: MarginLeft, bottom: 0, right: 0)
        collectionView.backgroundColor = UIColor.white
        collectionView.showsHorizontalScrollIndicator = false
        collectionView.dataSource = self
        collectionView.delegate = self
        collectionView.register(CuratorCell.self, forCellWithReuseIdentifier: CuratorCell.CellIdentifier)
        
    }

    func maximumNumberOfCell() -> Int{
        if curatorList.count > maximumCurators {
            return maximumCurators + 1
        }
        else{
            return curatorList.count + 1
        }
    }
    
    // MARK: - Collection View Data Source methods
    
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return self.maximumNumberOfCell()
    }
    
    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        let cell = collectionView.dequeueReusableCell(withReuseIdentifier: CuratorCell.CellIdentifier, for: indexPath) as! CuratorCell
        cell.tag = indexPath.row
        
        if indexPath.row <= 0 {
            cell.shouldShowListAll = true
        } else {
            cell.shouldShowListAll = false
            let curator = self.curatorList[indexPath.row - 1]
            cell.userKey = curator.userKey
            cell.nameLabel.text = curator.displayName
            cell.setImage(curator.profileImage, imageCategory: ImageCategory.user,index: indexPath.row, width: Constants.DefaultImageWidth.LargeIcon)
            
            //impression
            if let viewKey = self.analyticsViewKey {
                self.impressionKey = AnalyticsManager.sharedManager.recordImpression(impressionRef: curator.userKey, impressionType: "Curator", impressionDisplayName: curator.displayName, positionComponent: "CuratorListing", positionIndex: indexPath.row + 1, positionLocation: "Newsfeed-Home-User", viewKey: viewKey)
                cell.initAnalytics(withViewKey: viewKey, impressionKey: self.impressionKey!)
            }
        }
        
        
        return cell
    }
    
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, referenceSizeForHeaderInSection section: Int) -> CGSize {
        return CGSize.zero
    }

    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, minimumLineSpacingForSectionAt section: Int) -> CGFloat {
        return 0.0
    }
    
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, sizeForItemAt indexPath: IndexPath) -> CGSize {
        return CGSize(width: CuratorCell.CuratorCellWidth, height: collectionView.frame.height)
    }
    
    func numberOfSections(in collectionView: UICollectionView) -> Int {
        return 1
    }
    
    func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        
        if indexPath.row <= 0 {
            //record action
            if let cell = collectionView.cellForItem(at: indexPath) {
                cell.recordAction(
                    .Tap,
                    sourceRef: "AllCurators",
                    sourceType: .Link,
                    targetRef: "AllCurators",
                    targetType: .View
                )
            }
            if let delegate = self.delegate {
                delegate.didSelectAllUsers()
            }
        } else {
            let user = self.curatorList[indexPath.row - 1]
            
            //record action
            if let cell = collectionView.cellForItem(at: indexPath) {
                cell.recordAction(
                    .Tap,
                    sourceRef: user.userKey,
                    sourceType: .Curator,
                    targetRef: "CPP",
                    targetType: .View
                )
            }
            
            if let delegate = self.delegate {
                delegate.didSelectUser(user)
            }
            
        }
    }
    
    func isFollowed(_ user: User) ->Bool{
        return FollowService.instance.cachedFollowingUserKeys.contains(user.userKey)
    }
    
    //MARK: UIScrollViewDelegate
    func scrollViewWillBeginDecelerating(_ scrollView: UIScrollView) {
        if sourceRef.length == 0{
            let cells = collectionView.visibleCells.sorted(by: {$0.tag < $1.tag})
            if let lastCell = cells.last as? CuratorCell, cells.count > 1 {
                let curator:User?
                curator = self.curatorList[lastCell.tag - 1]
                if let curator = curator {
                    sourceRef = curator.userKey
                }
            }
        }
    }
    
    func scrollViewDidEndDecelerating(_ scrollView: UIScrollView) {
        let cells = collectionView.visibleCells.sorted(by: {$0.tag < $1.tag})
        if let firstCell = cells.first as? CuratorCell{
            //Cell all curators
            if firstCell.tag <= 0 {
                //use next cell insteads
                if cells.count > 1 {
                    if let secondCell = cells[1] as? CuratorCell {
                        let curator = self.curatorList[secondCell.tag - 1]
                        if sourceRef.length > 0{
                            //record action
                            secondCell.recordAction(
                                .Slide,
                                sourceRef: sourceRef,
                                sourceType: .Curator,
                                targetRef: curator.userKey,
                                targetType: .Curator
                            )
                            sourceRef = ""
                        }
                    }
                }
            } else {
                let curator = self.curatorList[firstCell.tag - 1]
                if sourceRef.length > 0{
                    //record action
                    firstCell.recordAction(
                        .Slide,
                        sourceRef: sourceRef,
                        sourceType: .Curator,
                        targetRef: curator.userKey,
                        targetType: .Curator
                    )
                    sourceRef = ""
                }
            }
        }
    }
}
