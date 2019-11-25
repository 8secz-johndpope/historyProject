//
//  TSChatShareMoreView.swift
//  TSWeChat
//
//  Created by Hilen on 12/24/15.
//  Copyright © 2015 Hilen. All rights reserved.
//

import UIKit
import SnapKit

private var leftRightPadding: CGFloat = 31.0
private let kTopBottomPadding: CGFloat = 10.0
private let kItemWidth: CGFloat = 55.0
private let kItemCountOfRow: CGFloat = 4

class TSChatShareMoreView: TSChatParentView {
    @IBOutlet weak var pageControl: UIPageControl!
    @IBOutlet weak var listCollectionView: UICollectionView! {didSet {
        listCollectionView.scrollsToTop = false
        }}
    @IBOutlet weak var collectionViewHeightConstraint: NSLayoutConstraint!
    weak var delegate: ChatShareMoreViewDelegate?

    var itemDataSouce: [(name: String, iconImage: UIImage, accessibilityId: String)] = [
        (String.localize("LB_CA_IM_LIBRARY"), TSAsset.Sharemore_pic.image, "IM_UserChat-UIBT_IM_ATTACH_PHOTO_LIBRARY"),
        (String.localize("LB_CA_IM_CAMERA"), TSAsset.Sharemore_video.image, "IM_UserChat-UIBT_IM_ATTACH_PHOTO_CAMERA"),
//        ("位置", TSAsset.Sharemore_location.image),
        (String.localize("LB_CA_IM_FRD"), TSAsset.Sharemore_friendcard.image, "IM_UserChat-UIBT_IM_ATTACH_FRIEND"),
        
//        ("小视频", TSAsset.Sharemore_sight.image),
//        ("视频聊天", TSAsset.Sharemore_videovoip.image),
//        ("红包", TSAsset.Sharemore_wallet.image),  //Where is the lucky money icon!  T.T
//        ("转账", TSAsset.SharemorePay.image),
//        
//        ("收藏", TSAsset.Sharemore_myfav.image),
//        
//        ("语音输入", TSAsset.Sharemore_voiceinput.image),
//        ("卡券", TSAsset.Sharemore_wallet.image),
    ]
    private var groupDataSouce = [[(name: String, iconImage: UIImage, accessibilityId: String)]]()
    var isAgent = false
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        self.initialize()
    }
    
    required init(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)!
        self.initialize()
    }
    
    convenience init() {
        self.init(frame: CGRect.zero)
        self.initialize()
    }
    
    func initialize() {
        
    }
    
    override func awakeFromNib() {
        let layout = TSFullyHorizontalFlowLayout()
        leftRightPadding = (ScreenWidth - (kItemWidth * kItemCountOfRow )) / (kItemCountOfRow + 1)
        layout.minimumLineSpacing = leftRightPadding
        layout.minimumInteritemSpacing = 0
        layout.sectionInset = UIEdgeInsetsMake(
            kTopBottomPadding,
            leftRightPadding,
            kTopBottomPadding,
            leftRightPadding
        )
        //Calculate the UICollectionViewCell size
        let itemSizeWidth = (ScreenWidth - leftRightPadding*2 - layout.minimumLineSpacing*(kItemCountOfRow - 1)) / kItemCountOfRow
        let itemSizeHeight = (self.collectionViewHeightConstraint.constant - kTopBottomPadding*2)/2
        layout.itemSize = CGSize(width: itemSizeWidth, height: itemSizeHeight)
        
        self.listCollectionView.collectionViewLayout = layout
        self.listCollectionView.register(TSChatShareMoreCollectionViewCell.NibObject(), forCellWithReuseIdentifier: TSChatShareMoreCollectionViewCell.identifier)
        self.listCollectionView.showsHorizontalScrollIndicator = false
        self.listCollectionView.isPagingEnabled = true
        
        reloadSource()
    }
    
    func reloadSource() {
        /**
         The section count is come from the groupDataSource, and The pageControl.numberOfPages is equal to the groupDataSouce.count.
         So I cut the itemDataSouce into 2 arrays. And the UICollectionView will has 2 sections.
         And then set the minimumLineSpacing and sectionInset of the flowLayout. The UI will be perfect like WeChat.
         */

        self.groupDataSouce = self.chunk(self.itemDataSouce, size: Int(kItemCountOfRow)*2)
        if self.groupDataSouce.count < 2 {
            self.pageControl.isHidden = true
        } else {
            self.pageControl.numberOfPages = self.groupDataSouce.count
        }
    }
    
    override func layoutSubviews() {
        super.layoutSubviews()
        //Fix the width
        self.listCollectionView.width = ScreenWidth
    }

}

// MARK: - @protocol UICollectionViewDelegate
extension TSChatShareMoreView: UICollectionViewDelegate {
    func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        guard let delegate = self.delegate else {
            return
        }

        let section = indexPath.section
        let row = indexPath.row
        if section == 0 {
            if row == 0 {
                delegate.chatShareMoreViewPhotoTaped()
            } else if row == 1 {
                delegate.chatShareMoreViewCameraTaped()
            } else if row == 2 {
                if isAgent {
                    delegate.chatAttachProduct()
                }
                else {
                    delegate.chatAttachFriend()
                }
            }
            else if row == 3 {
                if isAgent {
                    delegate.chatInsertComment()
                }
            }
        }
    }
}


// MARK: - @protocol UICollectionViewDataSource
extension TSChatShareMoreView: UICollectionViewDataSource {
    func numberOfSections(in collectionView: UICollectionView) -> Int {
        return self.groupDataSouce.count
    }
    
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        let subArray = self.groupDataSouce.get(section)
        return subArray?.count ?? 0
    }
    
    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        let cell = collectionView.dequeueReusableCell(withReuseIdentifier: TSChatShareMoreCollectionViewCell.identifier, for: indexPath) as! TSChatShareMoreCollectionViewCell
        let subArray = self.groupDataSouce.get(indexPath.section)!
        let item = subArray.get(indexPath.row)!
        cell.itemButton.setImage(item.iconImage, for: .normal)
        cell.itemLabel.text = item.name
        cell.accessibilityIdentifier = item.accessibilityId
        return cell
    }
    
    override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
        print("touchesBegan start")
        
    }
}

// MARK: - @protocol UIScrollViewDelegate
extension TSChatShareMoreView: UIScrollViewDelegate {
    func scrollViewDidEndDecelerating(_ scrollView: UIScrollView) {
        let pageWidth: CGFloat = self.listCollectionView.frame.sizeWidth
        self.pageControl.currentPage = Int(self.listCollectionView.contentOffset.x / pageWidth)
    }
}


 // MARK: - @delgate ChatShareMoreViewDelegate
protocol ChatShareMoreViewDelegate: class {
    /**
     选择相册
     */
    func chatShareMoreViewPhotoTaped()
    
    /**
     选择相机
     */
    func chatShareMoreViewCameraTaped()
    
    func chatAttachFriend()
    
    func chatAttachProduct()
    
    func chatInsertComment()
}





