//
//  UserCell.swift
//  merchant-ios
//
//  Created by Koon Kit Chan on 3/12/2015.
//  Copyright © 2015 Koon Kit Chan. All rights reserved.
//

import Foundation
class UserCell : UICollectionViewCell{
    
    static let TopBorderViewHeight: CGFloat = 6.0
    let arrowSize = CGSize(width: 30, height: 30)
    
    var userCollectionView : UICollectionView!
    var topBorderView: UIView!
    var showTopBorder = false {
        didSet {
            
            topBorderView.isHidden = !showTopBorder
            if showTopBorder {
                let paddingTop: CGFloat = 10
                userCollectionView.frame = CGRect(x: 0, y: UserCell.TopBorderViewHeight + paddingTop, width: self.bounds.sizeWidth - arrowSize.width, height: self.bounds.sizeHeight - UserCell.TopBorderViewHeight - paddingTop)
            } else {
                userCollectionView.frame = CGRect(x: 0, y: 0, width: frame.width - arrowSize.width, height: frame.height)
            }
        }
    }
    
    var viewTapGesture: UITapGestureRecognizer!
    var viewDidTap: ((UserCell)->())?
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        backgroundColor = UIColor.white
        
        let arrowContainerView = UIView(frame: CGRect(x: frame.width - arrowSize.width - 10, y: 0, width: arrowSize.width + 10, height: frame.height))
        let arrowView = { () -> UIImageView in
            let imageView = UIImageView(frame: CGRect(x: 0, y: (arrowContainerView.frame.height + 35 - arrowSize.height) / 2, width: arrowSize.width, height: arrowSize.height))
            imageView.image = UIImage(named: "icon_arrow_small")
            imageView.contentMode = .scaleAspectFit
            imageView.isHidden = false
            return imageView
        } ()
        arrowContainerView.addSubview(arrowView)
        addSubview(arrowContainerView)
        
        let layout: UICollectionViewFlowLayout = UICollectionViewFlowLayout()
        layout.sectionInset = UIEdgeInsets(top: 0, left: 0, bottom: 0, right: 0)
        layout.scrollDirection = UICollectionViewScrollDirection.horizontal
        userCollectionView = UICollectionView(frame: CGRect(x: 0, y: 0, width: frame.width - arrowSize.width, height: frame.height), collectionViewLayout: layout)
        userCollectionView!.backgroundColor = UIColor.white
        userCollectionView.showsHorizontalScrollIndicator = false
        addSubview(userCollectionView!)
        
        topBorderView = UIView(frame: CGRect(x: 0, y: 0, width: frame.sizeWidth, height: UserCell.TopBorderViewHeight))
        topBorderView.backgroundColor = UIColor.primary2()
        topBorderView.isHidden = true
        addSubview(topBorderView)
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    func addViewTapGesture(){
        viewTapGesture = UITapGestureRecognizer(target: self, action: #selector(UserCell.viewDidTap(_:)))
        self.addGestureRecognizer(viewTapGesture)
    }
    
    func removeViewTapGesture(){
        self.removeGestureRecognizer(viewTapGesture)
        viewTapGesture = nil
    }
    
    @objc func viewDidTap(_ sender: UIView){
        viewDidTap?(self)
    }
}
