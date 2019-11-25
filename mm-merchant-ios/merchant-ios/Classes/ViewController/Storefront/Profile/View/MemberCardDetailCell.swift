//
//  MemberCardDetailCell.swift
//  merchant-ios
//
//  Created by Quang Truong Dinh on 2/8/17.
//  Copyright © 2017 WWE & CO. All rights reserved.
//

import UIKit

class MemberCardDetailCell: UICollectionViewCell {
    static let CellIdentifier = "MemberCardDetailCellID"
    static let DefaultHeight: CGFloat = 250
    static let ContainerMargin = UIEdgeInsets(top: 0, left: 0, bottom: 0, right: 0)
    
    private var containerView = UIView()
    private var userImageView = UIImageView()
    private var paymentTotalLabel = UILabel()
    private var userNameLabel = UILabel()
    private var memberCardListView = MemberCardListView()
    
    var data: MemberCardDetailCellData?{
        didSet{
            if let data = data{
                memberCardType = data.memberCardType
                siderCardType = data.siderCardType
                memberCardListView.memberCardType = siderCardType
                memberCardListView.memberCardTypes = data.memberCardTypes
                memberCardListView.reloadData()
                
                paymentTotalLabel.text = String.localize("LB_CA_VIP_TOTAL_SPENDING") + ": " + (Int(data.paymentTotal).formatPrice() ?? "")

                layoutSubviews()
            }
        }
    }
    
    private var memberCardType: MemberCardType = MemberCardType.unknown
    private var siderCardType: MemberCardType = MemberCardType.unknown
    
    var didTapInCard: ((MemberCardType, MemberCardDetailCell)->())?
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        self.backgroundColor = UIColor.white
        self.clipsToBounds = true
        
        containerView.backgroundColor = UIColor.white
        addSubview(containerView)
        
        userImageView.mm_setImageWithURL(ImageURLFactory.URLSize1000(Context.getUserProfile().profileImage, category: .user), placeholderImage : UIImage(named: "default_profile_icon"))
        userImageView.backgroundColor = UIColor.gray
        containerView.addSubview(userImageView)
        
        userNameLabel.text = Context.getUserProfile().displayName
        userNameLabel.textAlignment = .center
        userNameLabel.formatSize(10)
        containerView.addSubview(userNameLabel)
        
        paymentTotalLabel.formatSizeBold(12)
        paymentTotalLabel.textColor = UIColor.black
        paymentTotalLabel.textAlignment = .center
        containerView.addSubview(paymentTotalLabel)
        
        memberCardListView.memberCardType = self.memberCardType
        memberCardListView.didTapOnCard = { [weak self] memberCardType in
            if let strongSelf = self, let memberCardType = memberCardType{
                strongSelf.memberCardListView.memberCardType = memberCardType
                strongSelf.didTapInCard?(memberCardType, strongSelf)
            }
        }
        containerView.addSubview(memberCardListView)
    }
    
    override func layoutSubviews() {
        super.layoutSubviews()
        let containerMargin = MemberCardDetailCell.ContainerMargin
        containerView.frame = CGRect(x: containerMargin.left, y: containerMargin.top, width: bounds.size.width - containerMargin.left - containerMargin.right, height: bounds.size.height - containerMargin.top - containerMargin.bottom)

        let userImageSize = CGSize(width: 48,height: 48)
        let toContainerTop: CGFloat = 26
        let toContainerLeading: CGFloat = containerView.frame.midX - userImageSize.width/2
        
        userImageView.frame = CGRect(x: toContainerLeading, y: toContainerTop, width: userImageSize.width, height: userImageSize.height)
        userImageView.round()
        
        let userNameWidth = userNameLabel.optimumWidth(height: 14)
        userNameLabel.frame = CGRect(x: userImageView.frame.midX - userNameWidth/2, y: userImageView.frame.maxY + 14, width: userNameWidth, height: 14)
        
        paymentTotalLabel.frame = CGRect(x: 6, y: userNameLabel.frame.maxY + 2, width: containerView.width - 12, height: 20)

        memberCardListView.frame = CGRect(x: 0, y: paymentTotalLabel.frame.maxY + 20, width: self.width, height: containerView.height - paymentTotalLabel.frame.maxY - 20)
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    class func getHeight() -> CGFloat{
        return MemberCardDetailCell.DefaultHeight
    }
}

internal class MemberCardListView : UIView{
    private var memberCardViews = [MemberCardView]()
    
    var memberCardType: MemberCardType = MemberCardType.unknown{
        didSet{
            self.layoutSubviews()
        }
    }
    
    var memberCardTypes = [MemberCardType](){
        didSet{
            self.setupMemberCardViews()
            self.layoutSubviews()
        }
    }
    
    var didTapOnCard: ((MemberCardType?)->())?
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        self.setupMemberCardViews()
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override func layoutSubviews() {
        super.layoutSubviews()
        
        self.layoutCardViews()
    }
    
    private func setupMemberCardViews(){
        for memberCardView in memberCardViews{
            memberCardView.removeFromSuperview()
        }
        
        memberCardViews.removeAll()
        
        for cardType in memberCardTypes{
            let memberCardView = MemberCardView()
            memberCardView.layoutViewWithSelectedStatus(cardType == memberCardType)
            memberCardView.cardType = cardType
            
            memberCardView.viewDidTap = { [weak self] view in
                if let strongSelf = self , let view = view as? MemberCardView{
                    strongSelf.memberCardType = view.cardType ?? MemberCardType.unknown
                    strongSelf.didTapOnCard?(view.cardType)
                }
            }
            addSubview(memberCardView)
            memberCardViews.append(memberCardView)
        }
    }
    
    private func layoutCardViews(){
        let numberOfCardType = memberCardViews.count
        
        var cardTypeWidth: CGFloat = 0.0
        if MemberCardType.count() > 0{
            cardTypeWidth = self.width/CGFloat(MemberCardType.count())
        }
        
        var cardPadding: CGFloat = 0.0
        let cardHeight: CGFloat = self.height
        
        if numberOfCardType <= 1{
            cardPadding = (self.width - CGFloat(numberOfCardType)*cardTypeWidth)/2
            if let memberCardView = memberCardViews.first{
                memberCardView.frame = CGRect(x: cardPadding, y: 0, width: cardTypeWidth, height: cardHeight)
            }
        }
        else{
            cardPadding = (self.width - CGFloat(numberOfCardType)*cardTypeWidth)/CGFloat(numberOfCardType - 1)
            for (index, memberCardView) in memberCardViews.enumerated(){
                
                memberCardView.frame = CGRect(x: CGFloat(index)*(cardTypeWidth + cardPadding), y: 0, width: cardTypeWidth, height: cardHeight)
            }
        }
    }
    
    func deselectAllMemmberCardViews(){
        for memberCardView in memberCardViews{
            memberCardView.layoutViewWithSelectedStatus(false)
        }
    }
    
    func reloadData(){
        for memberCardView in memberCardViews{
            memberCardView.reloadData()
        }
    }
}

internal class MemberCardView : UIView{
    private var shadowView = UIImageView()
    private var imageView = UIImageView()
    private var nameLabel = UILabel()
    private var quotaLabel = UILabel()
    private var tapGesture = UIGestureRecognizer()
    
    var cardType: MemberCardType?{
        didSet{
            self.reloadData()
        }
    }
    
    var viewDidTap: ((UIView?) -> ())?
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        shadowView.backgroundColor = UIColor.white
        self.addSubview(shadowView)
        
        self.addSubview(imageView)
        nameLabel.textAlignment = .center
        nameLabel.formatSize(10)
        nameLabel.textColor = UIColor.black
        self.addSubview(nameLabel)
        
        quotaLabel.textAlignment = .center
        quotaLabel.formatSize(10)
        quotaLabel.textColor = UIColor.secondary4()
        quotaLabel.text = ""
        
        self.addSubview(quotaLabel)
        
        self.isUserInteractionEnabled = true
        tapGesture = UITapGestureRecognizer(target: self, action: #selector(MemberCardView.viewDidTapHandler))
        self.addGestureRecognizer(tapGesture)
    }
    
    override func layoutSubviews() {
        super.layoutSubviews()
        shadowView.frame = CGRect(x: 2, y: 2, width: width - 4, height: height - 4)
        
        let padding: CGFloat = 20
        imageView.frame = CGRect(x: (self.width - 34)/2, y: 20, width: 34, height: 22)
        
        let labelHeight: CGFloat = 15
        let labelPadding: CGFloat = (shadowView.height - 2 * padding - imageView.height - 2 * labelHeight) / 2
        
        nameLabel.frame = CGRect(x: 4, y: imageView.frame.maxY + labelPadding, width: self.width - 8, height: labelHeight)
        quotaLabel.frame = CGRect(x: 4, y: nameLabel.frame.maxY + labelPadding, width: self.width - 8, height: labelHeight)
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    @objc func viewDidTapHandler(_ gesture: UIGestureRecognizer){
        viewDidTap?(gesture.view)
    }
    
    func reloadData(){
        guard let cardType = self.cardType  else {
            return
        }
        if let loyalty = LoyaltyManager.getLoyaltyById(cardType.rawValue){
            LoyaltyManager.setLoyaltyImage(imageView, loyaltyStatusId: loyalty.loyaltyStatusId)
            nameLabel.text = loyalty.loyaltyStatusName 
            if Context.getUserProfile().loyaltyStatusId == loyalty.loyaltyStatusId{
                quotaLabel.text = String.localize("LB_CA_VIP_CURRNT_TIER")
            }
            else if loyalty.quota >= 0{
                quotaLabel.text = "\(loyalty.quota)" + String.localize("LB_YUAN")
            }
        }
    }
    
    func layoutViewWithSelectedStatus(_ isSelected: Bool){
        nameLabel.textColor = isSelected ? UIColor.black : UIColor.secondary4()
        quotaLabel.textColor = isSelected ? UIColor.black : UIColor.secondary4()
        
        shadowView.layer.shadowOffset = CGSize(width: 0, height: 0)
        shadowView.layer.shadowOpacity = 0.7
        shadowView.layer.shadowRadius = 1
        shadowView.layer.shadowColor = isSelected ? UIColor.black.cgColor : UIColor.clear.cgColor
    }
}
