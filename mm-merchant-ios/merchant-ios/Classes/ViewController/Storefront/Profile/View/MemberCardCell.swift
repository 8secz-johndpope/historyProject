//
//  MemberCardCell.swift
//  merchant-ios
//
//  Created by Quang Truong Dinh on 2/7/17.
//  Copyright © 2017 WWE & CO. All rights reserved.
//

import UIKit

class MemberCardCell: UICollectionViewCell {
    static let CellIdentifier = "MemberCardCellID"
    static let DefaultCardImageViewSize = CGSize(width: 371, height: 248)
    static let DefaultHeight: CGFloat =
        (MemberCardCell.DefaultCardImageViewSize.height/MemberCardCell.DefaultCardImageViewSize.width)*(ScreenWidth - ContainerMargin.left - ContainerMargin.right) + ContainerMargin.top + ContainerMargin.bottom
    static let ContainerMargin = UIEdgeInsets(top: 0, left: 0, bottom: 0, right: 0)
    
    private var containerView = UIView()
    private var cardBackgroundImageView = UIImageView()
    private var cardImageView = UIImageView()
    private var userImageView = UIImageView()
    private var cardTypeLabel = UILabel()
    private var userNameLabel = UILabel()
    private var consumedAmmountNameLabel = UILabel()
    private var consumedAmmountLabel = UILabel()
    private var bottomLabel = UILabel()
    private var cumulativeConsumptionAmountNameLabel = UILabel()
    private var cumulativeConsumptionAmountLabel = UILabel()
    
    private var tapGesture = UIGestureRecognizer()
    
    var bottomLabelDidTap: ((MemberCardCell)->())?
    
    var data: MemberCardCellData?{
        didSet{
            if let data = data{
                self.cardType = data.memberCardType
                self.cardTypeLabel.text = data.cardTypeName
                self.consumedAmmountLabel.text = Int(data.paymentTotal).formatPrice()
                self.bottomLabel.text = cardType.spendingAmountToNextLevelMessage(data.paymentTotal)
            }
        }
    }
    
    private var cardType = MemberCardType.unknown {
        didSet{
            userNameLabel.textColor = cardType.nameTextColor()
            cardTypeLabel.textColor = cardType.cardTypeTextColor()
            cardImageView.image = UIImage(named: "vip_card_lv\(cardType.rawValue)")
            consumedAmmountNameLabel.textColor = cardType.cumulativeConsumptionColor()
            consumedAmmountNameLabel.isHidden = (cardType == MemberCardType.platinum)
            cumulativeConsumptionAmountLabel.text = cardType.vipRanking()
            cumulativeConsumptionAmountLabel.isHidden = !cardType.isShowVipRanking()
            cumulativeConsumptionAmountNameLabel.isHidden = !cardType.isShowVipRanking()
            cumulativeConsumptionAmountNameLabel.textColor = cardType.cumulativeConsumptionColor()
            cumulativeConsumptionAmountLabel.textColor = cardType.cumulativeConsumptionColor()
            layoutSubviews()
        }
    }
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        self.backgroundColor = UIColor.primary2()
        self.clipsToBounds = true
        
        containerView.backgroundColor = UIColor.clear
        addSubview(containerView)
        
        cardBackgroundImageView.image = UIImage(named: "vip_card_bg")
        containerView.addSubview(cardBackgroundImageView)
        
        containerView.addSubview(cardImageView)
        
        userImageView.mm_setImageWithURL(ImageURLFactory.URLSize256(Context.getUserProfile().profileImage, category: .user), placeholderImage : UIImage(named: "default_profile_icon"))
        userImageView.backgroundColor = UIColor.gray
        containerView.addSubview(userImageView)
        
        containerView.addSubview(userNameLabel)
        userNameLabel.text = Context.getUserProfile().displayName
        userNameLabel.formatSize(12)
        userNameLabel.textColor = cardType.nameTextColor()
        
        containerView.addSubview(cardTypeLabel)
        cardTypeLabel.formatSizeBold(20)
        cardTypeLabel.textColor = cardType.cardTypeTextColor()
        
        containerView.addSubview(consumedAmmountNameLabel)
        consumedAmmountNameLabel.text = String.localize("LB_CA_VIP_TOTAL_SPENDING")
        consumedAmmountNameLabel.formatSize(12)
        consumedAmmountNameLabel.textColor = cardType.cumulativeConsumptionColor()
        
        containerView.addSubview(consumedAmmountLabel)
        consumedAmmountLabel.formatSizeBold(32)
        consumedAmmountLabel.textColor = UIColor.white
        consumedAmmountLabel.minimumScaleFactor = 0.5
        consumedAmmountLabel.lineBreakMode = .byTruncatingTail
        consumedAmmountLabel.adjustsFontSizeToFitWidth = true
        consumedAmmountLabel.numberOfLines = 1
        consumedAmmountLabel.layer.shadowOffset = CGSize(width: 0, height: 0)
        consumedAmmountLabel.layer.shadowOpacity = 0.7
        consumedAmmountLabel.layer.shadowRadius = 1
        consumedAmmountLabel.layer.shadowColor = UIColor.black.cgColor
        
        containerView.addSubview(bottomLabel)
        bottomLabel.textAlignment = .center
        bottomLabel.formatSize(10)
        bottomLabel.textColor = UIColor.white
        bottomLabel.isUserInteractionEnabled = true
        tapGesture = UITapGestureRecognizer(target: self, action: #selector(MemberCardCell.bottomLabelTapGesture))
        bottomLabel.addGestureRecognizer(tapGesture)
        
        containerView.addSubview(cumulativeConsumptionAmountNameLabel)
        cumulativeConsumptionAmountNameLabel.text = String.localize("LB_CA_VIP_TOTAL_SPENDING_FOR_RANKING")
        cumulativeConsumptionAmountNameLabel.isHidden = !cardType.isShowVipRanking()
        cumulativeConsumptionAmountNameLabel.formatSize(12)
        cumulativeConsumptionAmountLabel.textAlignment = .center
        cumulativeConsumptionAmountNameLabel.textColor = cardType.cumulativeConsumptionColor()
        
        containerView.addSubview(cumulativeConsumptionAmountLabel)
        cumulativeConsumptionAmountLabel.textAlignment = .center
        cumulativeConsumptionAmountLabel.formatSize(12)
        cumulativeConsumptionAmountLabel.textColor = cardType.cumulativeConsumptionColor()
        cumulativeConsumptionAmountLabel.isHidden = !cardType.isShowVipRanking()
    }
    
    @objc func bottomLabelTapGesture(_ gesture: UIGestureRecognizer){
        if let _ = gesture.view{
            bottomLabelDidTap?(self)
        }
    }
    
    override func layoutSubviews() {
        super.layoutSubviews()
        let containerMargin = MemberCardCell.ContainerMargin
        containerView.frame = CGRect(x: containerMargin.left, y: containerMargin.top, width: bounds.size.width - containerMargin.left - containerMargin.right, height: bounds.size.height - containerMargin.top - containerMargin.bottom)
        
        //User image
        let rate = (ScreenWidth - containerMargin.left - containerMargin.right)/MemberCardCell.DefaultCardImageViewSize.width
        let toContainerTop: CGFloat = 26*rate
        let toContainerLeading: CGFloat = 26*rate
        let toContainerTrailing: CGFloat = 26*rate
        
        cardBackgroundImageView.frame = CGRect(x: 0, y: 0, width: containerView.width, height: containerView.height)
        
        cardImageView.frame = CGRect(x: 14, y: 14, width: containerView.width - 28, height: containerView.height - 28)
        
        userImageView.frame = CGRect(x: toContainerLeading, y: toContainerTop, width: 48, height: 48)
        userImageView.round()
        userNameLabel.frame = CGRect(x: userImageView.frame.maxX + 14, y: userImageView.frame.minY + 2, width: cardImageView.width - (userImageView.frame.maxX + 14), height: 17)
        cardTypeLabel.frame = CGRect(x: userImageView.frame.maxX + 14, y: userImageView.frame.maxY - 2 - 28, width: cardImageView.width - (userImageView.frame.maxX + 14), height: 28)
        
        consumedAmmountNameLabel.frame = CGRect(x: userImageView.frame.minX, y: containerView.frame.midY - 17 - 2, width: cardImageView.width - (userImageView.frame.maxX + 14), height: 17)
        
        let cumulativeConsumptionAmountWidth = cumulativeConsumptionAmountNameLabel.optimumWidth(height: 18)
        cumulativeConsumptionAmountNameLabel.frame = CGRect(x: containerView.width - toContainerTrailing - cumulativeConsumptionAmountWidth, y: consumedAmmountLabel.frame.midY - 20, width: cumulativeConsumptionAmountWidth, height: 20)
        cumulativeConsumptionAmountLabel.frame = CGRect(x: containerView.width - toContainerTrailing - cumulativeConsumptionAmountLabel.optimumWidth(), y: consumedAmmountLabel.frame.midY, width: cumulativeConsumptionAmountLabel.optimumWidth(), height: 20)
        
        var consumedAmmountLabelWidth: CGFloat = 0.0
        if cumulativeConsumptionAmountNameLabel.frame.minX < cumulativeConsumptionAmountLabel.frame.minX{
            consumedAmmountLabelWidth = cumulativeConsumptionAmountNameLabel.frame.minX - userImageView.frame.minX - 6
        }
        else{
            consumedAmmountLabelWidth = cumulativeConsumptionAmountLabel.frame.minX - userImageView.frame.minX - 6
        }
        consumedAmmountLabel.frame = CGRect(x: userImageView.frame.minX, y: containerView.frame.midY + 2, width: consumedAmmountLabelWidth, height: 36)
        bottomLabel.frame = CGRect(x: (containerView.width - bottomLabel.optimumWidth())/2, y: containerView.height - 44, width: bottomLabel.optimumWidth(), height: 30)
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    class func getHeight() -> CGFloat{
        return MemberCardCell.DefaultHeight
    }
}

class MemberCardCellData{
    var memberCardType = MemberCardType.unknown
    var cardTypeName = ""
    var paymentTotal: Double = 0
    
    init(memberCardType: MemberCardType = MemberCardType.unknown) {
        self.memberCardType = memberCardType
    }
}
