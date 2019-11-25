//
//  ActionButtonView.swift
//  merchant-ios
//
//  Created by Quang Truong Dinh on 9/1/16.
//  Copyright © 2016 WWE & CO. All rights reserved.
//

import Foundation

class ActionButtonView: UIView {

    private let DefaultCellID = "DefaultCellID"
    
    var topBorderLine = UIView()
    var collectionView: UICollectionView!

    var orderActionData: OrderActionData? {
        didSet {
            collectionView.reloadData()
        }
    }
    
    var contactCustomerServiceWithOrder: ((Order) -> ())?
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        
        self.backgroundColor = UIColor.white
        
        let paddingContent: CGFloat = 10 // Align padding with order detail
        let layout = UICollectionViewFlowLayout()
        
        collectionView = UICollectionView(frame: CGRect(x: paddingContent, y: 0, width: frame.width - (paddingContent * 2), height: frame.height), collectionViewLayout: layout)
        
        collectionView.delegate = self
        collectionView.dataSource = self
        collectionView.register(OrderActionCell.self, forCellWithReuseIdentifier: OrderActionCell.CellIdentifier)
        collectionView.register(UICollectionViewCell.self, forCellWithReuseIdentifier: DefaultCellID)
        collectionView.backgroundColor = UIColor.clear
        addSubview(collectionView)
        
        topBorderLine = UIView(frame: CGRect(x: 0, y: 0, width: frame.width, height: 1))
        topBorderLine.backgroundColor = UIColor.backgroundGray()
        topBorderLine.isHidden = true
        addSubview(topBorderLine)
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override func layoutSubviews() {
        super.layoutSubviews()
    }
}

extension ActionButtonView : UICollectionViewDelegate, UICollectionViewDelegateFlowLayout {
    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        if let orderActionData = self.orderActionData {
            if let cell = collectionView.dequeueReusableCell(withReuseIdentifier: OrderActionCell.CellIdentifier, for: indexPath) as? OrderActionCell {
                cell.triangleImageView.isHidden = true
                cell.data = orderActionData
                
                if let order: Order = orderActionData.order {
                    cell.contactHandler = { [weak self] in
                        if let strongSelf = self {
                            if let action = strongSelf.contactCustomerServiceWithOrder {
                                action(order)
                            } else {
                                ErrorLogManager.sharedManager.recordNonFatalError(withException: .NullPointer)
                            }
                        } else {
                            ErrorLogManager.sharedManager.recordNonFatalError(withException: .NullPointer)
                        }
                    }
                } else {
                    ErrorLogManager.sharedManager.recordNonFatalError(withException: .NullPointerOrTypeMismatch)
                }
                
                return cell
            } else {
                ErrorLogManager.sharedManager.recordNonFatalError(withException: .NullPointerOrTypeMismatch)
            }
        } else {
            ErrorLogManager.sharedManager.recordNonFatalError(withException: .NullPointer)
        }
        
        return collectionView.dequeueReusableCell(withReuseIdentifier: DefaultCellID, for: indexPath)
    }
    
    func collectionView(_ collectionView: UICollectionView,
                        layout collectionViewLayout: UICollectionViewLayout,
                        insetForSectionAt section: Int) -> UIEdgeInsets {
        return UIEdgeInsets.zero
    }
    
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, referenceSizeForHeaderInSection section: Int) -> CGSize {
        return CGSize.zero
    }
    
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, minimumInteritemSpacingForSectionAt section: Int) -> CGFloat {
        return 0
    }
    
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, minimumLineSpacingForSectionAt section: Int) -> CGFloat {
        return 0
    }
    
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, sizeForItemAt indexPath: IndexPath) -> CGSize {
        return CGSize(width: collectionView.width, height: collectionView.height)
    }
}

extension ActionButtonView : UICollectionViewDataSource {
    
    func numberOfSections(in collectionView: UICollectionView) -> Int {
        return (orderActionData != nil) ? 1 : 0
    }
    
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return (orderActionData != nil) ? 1 : 0
    }
    
}
