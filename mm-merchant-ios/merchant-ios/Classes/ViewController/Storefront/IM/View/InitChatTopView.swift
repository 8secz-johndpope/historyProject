//
//  InitChatTopView.swift
//  merchant-ios
//
//  Created by HungPM on 6/14/16.
//  Copyright © 2016 WWE & CO. All rights reserved.
//

import Foundation
// FIXME: comparison operators with optionals were removed from the Swift Standard Libary.
// Consider refactoring the code to use the non-optional operators.
private func < <T : Comparable>(lhs: T?, rhs: T?) -> Bool {
  switch (lhs, rhs) {
  case let (l?, r?):
    return l < r
  case (nil, _?):
    return true
  default:
    return false
  }
}

// FIXME: comparison operators with optionals were removed from the Swift Standard Libary.
// Consider refactoring the code to use the non-optional operators.
private func > <T : Comparable>(lhs: T?, rhs: T?) -> Bool {
  switch (lhs, rhs) {
  case let (l?, r?):
    return l > r
  default:
    return rhs < lhs
  }
}


class InitChatTopView: UIView, UICollectionViewDataSource, UICollectionViewDelegate, UITextFieldDelegate {
    private final let ProfileImageCellID = "ProfileImageCellID"
    private var MaxWidth: CGFloat!
    private var deleteCount = 0

    var merchantView: UIView!
    let nameLabel = UILabel()
    let roleLabel = UILabel()
    var tfContact: CustomTextField!
    var collectionView: UICollectionView!
    
    var dataSource = [User]()
    private var filterDataSource = [User]()

    private final var lblSendFrom: UILabel!
    var lblSendTo: UILabel!
    private final var contactView: UIView!

    var viewMerchantTapHandler: (() -> Void)?
    var userTapHandler: ((_ user: User) -> ())?
    var searchFieldTextDidChangeHandler: ((_ text: String) -> ())?

    override init(frame: CGRect) {
        super.init(frame: frame)
        
        let height = CGFloat(60)
        let Margin = CGFloat(10)
        
        merchantView = UIView(frame: CGRect(x: 0, y: 0, width: frame.width, height: height))
        
        lblSendFrom = UILabel()
        lblSendFrom.text = String.localize("LB_IM_CHAT_WITH_ONBEHALF")
        lblSendFrom.formatSmall()
        lblSendFrom.textColor = UIColor(hexString: "#757575")
        lblSendFrom.numberOfLines = 1
        lblSendFrom.sizeToFit()
        lblSendFrom.frame = CGRect(x: Margin, y: 0, width: lblSendFrom.frame.width, height: height)
        merchantView.addSubview(lblSendFrom)

        nameLabel.formatSize(15)
        nameLabel.numberOfLines = 1
        nameLabel.lineBreakMode = .byTruncatingTail
        nameLabel.text = Context.getUserProfile().displayName
        merchantView.addSubview(nameLabel)
        
        roleLabel.formatSize(15)
        roleLabel.layer.borderWidth = 1
        roleLabel.layer.cornerRadius = 3
        roleLabel.layer.borderColor = UIColor.backgroundGray().cgColor
        roleLabel.textAlignment = .center
        roleLabel.numberOfLines = 1
        merchantView.addSubview(roleLabel)
        
        let arrowRightMargin = CGFloat(10)
        let ArrowWidth = CGFloat(10)
        let arrowImageView = UIImageView(frame: CGRect(x: merchantView.frame.width - ArrowWidth - arrowRightMargin, y: (merchantView.frame.height - ArrowWidth) / 2, width: ArrowWidth, height: ArrowWidth))
        arrowImageView.image = UIImage(named: "arrow_close")
        arrowImageView.contentMode = .scaleAspectFit
        merchantView.addSubview(arrowImageView)
        
        let separatorViewMerchant = { () -> UIView in
            let view = UIView(frame: CGRect(x: 0, y: merchantView.size.height - 1, width: frame.width, height: 1))
            view.backgroundColor = UIColor.backgroundGray()
            
            return view
        }()
        
        merchantView.addSubview(separatorViewMerchant)
        merchantView.addGestureRecognizer(UITapGestureRecognizer(target: self, action: #selector(merchantViewTapped)))

        contactView = UIView(frame: CGRect(x: 0, y: frame.size.height - height, width: frame.width, height: height))
        
        lblSendTo = UILabel()
        lblSendTo.formatSmall()
        lblSendTo.textColor = UIColor(hexString: "#757575")
        lblSendTo.numberOfLines = 1
        contactView.addSubview(lblSendTo)

        tfContact = CustomTextField()
        tfContact.placeholder = String.localize("LB_IM_CHAT_USER_SEARCH")
        tfContact.delegate = self
        NotificationCenter.default.addObserver(self, selector: #selector(textDidChange), name: NSNotification.Name.UITextFieldTextDidChange, object: tfContact)
        tfContact.deleteHandler = { [weak self] in
            guard let strongSelf = self else { return }
            
            guard !strongSelf.filterDataSource.isEmpty else { return }
            
            guard let user = strongSelf.filterDataSource.last, user.canDelete else { return }
            
            strongSelf.deleteCount += 1
            
            let indexPath = IndexPath(item: strongSelf.filterDataSource.count - 1, section: 0)
            strongSelf.collectionView.scrollToItem(at: indexPath, at: .right, animated: false)
            
            if strongSelf.deleteCount == 1 {
                if let cell = strongSelf.collectionView.cellForItem(at: indexPath) as? ProfileImageCell {
                    cell.profileImageView.alpha = 0.5
                }
            }
            else {
                strongSelf.deleteCount = 0
                strongSelf.removeUser(user)
                strongSelf.userTapHandler?(user)
            }
            
        }
        contactView.addSubview(tfContact)

        let itemWidth = CGFloat(40)
        let layout: UICollectionViewFlowLayout = UICollectionViewFlowLayout()
        layout.sectionInset = UIEdgeInsets(top: 10, left: 0, bottom: 10, right: 5)
        layout.itemSize = CGSize(width: itemWidth, height: itemWidth)
        layout.minimumLineSpacing = 5
        layout.minimumInteritemSpacing = 0
        layout.scrollDirection = .horizontal
        collectionView = UICollectionView(frame: CGRect(x: 0, y: 0, width: 0, height: height), collectionViewLayout: layout)
        collectionView.backgroundColor = UIColor.clear
        collectionView.showsHorizontalScrollIndicator = false
        collectionView.register(ProfileImageCell.self, forCellWithReuseIdentifier: ProfileImageCellID)
        collectionView.dataSource = self
        collectionView.delegate = self
        
        tfContact.leftView = collectionView
        
        let separatorViewContact = { () -> UIView in
            let view = UIView(frame: CGRect(x: 0, y: contactView.size.height - 1, width: frame.width, height: 1))
            view.backgroundColor = UIColor.backgroundGray()
            
            return view
        }()
        contactView.addSubview(separatorViewContact)

        addSubview(merchantView)
        addSubview(contactView)
        
        layoutSubviews()
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override func layoutSubviews() {
        super.layoutSubviews()
        
        let Margin = CGFloat(5)
        
        lblSendTo.sizeToFit()
        lblSendTo.frame = CGRect(x: 10, y: 0, width: lblSendTo.frame.width, height: 60)

        let MinWidthSearch = CGFloat(100)
        let posX = lblSendTo.frame.maxX + 5
        MaxWidth = frame.width - posX - MinWidthSearch
        
        tfContact.frame = CGRect(x: posX, y: 0, width: contactView.frame.width - posX, height: 60)

        roleLabel.sizeToFit()
        nameLabel.sizeToFit()
        var width = nameLabel.frame.width
        let arrowRightMargin = CGFloat(10)
        let ArrowWidth = CGFloat(10)

        let totalMargin = Margin * 3 - arrowRightMargin - 10
        let maxWidth = merchantView.width - roleLabel.frame.width - lblSendFrom.frame.maxX - ArrowWidth - totalMargin
        if width > maxWidth {
            width = maxWidth
        }
        nameLabel.frame = CGRect(x: lblSendFrom.frame.maxX + Margin, y: (merchantView.frame.height - nameLabel.frame.height) / 2.0, width: width, height: nameLabel.frame.height)
        
        roleLabel.frame = CGRect(x: nameLabel.frame.maxX + Margin, y: (merchantView.frame.height - roleLabel.frame.height - 10) / 2.0, width: roleLabel.frame.width + 10, height: roleLabel.frame.height + 10)
    }

    @objc private func merchantViewTapped() {
        viewMerchantTapHandler?()
    }
    
    // MARK: - CollectionView
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return filterDataSource.count
    }
    
    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        let cell = collectionView.dequeueReusableCell(withReuseIdentifier: ProfileImageCellID, for: indexPath) as! ProfileImageCell
        
        let user = filterDataSource[indexPath.row]
        
        let defaultProfile = UIImage(named: "default_profile_icon")
        if (user.profileImage.length > 0) {
            cell.profileImageView.mm_setImageWithURL(ImageURLFactory.URLSize128(user.profileImage, category: .user), placeholderImage: defaultProfile, contentMode: .scaleAspectFill)
        } else {
            cell.profileImageView.image = defaultProfile
        }
        if deleteCount == 0 {
            cell.profileImageView.alpha = 1
        }
        else {
            cell.profileImageView.alpha = 0.5
        }
        
        return cell
    }
    
    func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        let user = filterDataSource[indexPath.row]
        
        guard user.canDelete else { return }
        
        removeUser(user)
        userTapHandler?(user)
    }
    
    func addUser(_ user: User) {
        resetUserState()
        dataSource.append(uniqueUser: user)
        updateSize()
        collectionView.reloadData()

        if !filterDataSource.isEmpty {
            let indexPath = IndexPath(item: filterDataSource.count - 1, section: 0)
            collectionView.scrollToItem(at: indexPath, at: .right, animated: false)
        }
    }
    
    func removeUser(_ user: User) {
        resetUserState()
        if dataSource.contains(user) {
            dataSource.remove(user)
        }
        updateSize()
        collectionView.reloadData()
    }
    
    func removeAllSelectedUsers() {
        dataSource.removeAll()
        updateSize()
        collectionView.reloadData()
    }
    
    func updateSize() {
        let ProfileImageWidth = CGFloat(40)
        let PaddingBetweenItem = CGFloat(5)
        var width: CGFloat!
        
        filterDataSource = dataSource.filter { $0.canDelete }
        
        if filterDataSource.count == 0 {
            width = 0
            tfContact.leftViewMode = .never
        }
        else {
            width = CGFloat(filterDataSource.count) * ProfileImageWidth + CGFloat((filterDataSource.count)) * PaddingBetweenItem
            tfContact.leftViewMode = .always
        }
        
        if width > MaxWidth {
            width = MaxWidth
        }
        
        collectionView.frame = CGRect(x: 0, y: 0, width: width, height: 60)
        tfContact.reloadInputViews()
    }
    
    // MARK: - UITextField
    func textFieldShouldReturn(_ textField: UITextField) -> Bool {
        textField.resignFirstResponder()
        
        resetUserState()
        return true
    }
    
    @objc func textDidChange(_ notification: Notification) {
        if let textField = notification.object as? UITextField {
            resetUserState()
            
            searchFieldTextDidChangeHandler?(textField.text ?? "")
        }
    }
    
    func resetUserState() {
        if self.deleteCount == 1 {
            self.deleteCount = 0
            
            if !filterDataSource.isEmpty {
                let indexPath = IndexPath(item: filterDataSource.count - 1, section: 0)
                let cell = self.collectionView.cellForItem(at: indexPath) as! ProfileImageCell
                cell.profileImageView.alpha = 1
            }
        }
    }
    
    deinit {
        NotificationCenter.default.removeObserver(self)
    }
    
    
}

class CustomTextField: UITextField {
    
    var deleteHandler: (() -> Void)?
    
    override func deleteBackward() {
        if self.text == "" {
            deleteHandler?()
        }
        super.deleteBackward()
    }
}
