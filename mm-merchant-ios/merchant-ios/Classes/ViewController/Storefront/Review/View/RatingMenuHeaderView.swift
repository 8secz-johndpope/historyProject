//
//  RatingMenuHeaderView.swift
//  merchant-ios
//
//  Created by Quang Truong Dinh on 6/2/16.
//  Copyright © 2016 WWE & CO. All rights reserved.
//

import Foundation

enum ReviewRatingMenuAction: Int {
    case unknown = 0,
    showAll,
    showFiveRating,
    showFourRating,
    showThreeRating,
    showTwoRating,
    showOneRating,
    showImageRating
}

protocol RatingMenuCollectionCellDelegate: NSObjectProtocol {
    func didRatingMenuItemTap(_ menuAction: ReviewRatingMenuAction)
}

class RatingMenuHeaderView: UICollectionReusableView {
    
    static let DefaltHeight: CGFloat = 67
    
    let LeftMargin: CGFloat = 10
    let RightMargin: CGFloat = 10
    
    private final var RatingMenuItemDatas = [RatingMenuItemData]()
    
    var ratingMenuItems = [RatingMenuItemView]()
    
    weak var delegate: RatingMenuCollectionCellDelegate?
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        
        self.setupRatingMenuData()
        
        let numberOfMenuItem = RatingMenuItemDatas.count
        
        let menuItemSpace: CGFloat = 10
        
        let menuItemWidth = (frame.width - LeftMargin - RightMargin - CGFloat(numberOfMenuItem - 1)*menuItemSpace)/CGFloat(numberOfMenuItem)
        let menuItemHeigh = menuItemWidth
        
        var index  = 0
        for ratingMenuItemData in self.RatingMenuItemDatas {
            let menuItemView = { () -> RatingMenuItemView in
                let view = RatingMenuItemView(frame: CGRect(x: LeftMargin + CGFloat(index)*menuItemWidth + CGFloat(index)*menuItemSpace, y: frame.height/2 - menuItemHeigh/2, width: menuItemHeigh, height: menuItemWidth), ratingMenuItemData: ratingMenuItemData)
                
                view.actionButton.addTarget(self, action: #selector(ratingMenuItemTapped), for: UIControlEvents.touchUpInside)
                
                view.actionButton.tag = index
                view.tag = index
                return view
            }()
            
            addSubview(menuItemView)
            
            ratingMenuItems.append(menuItemView)
            
            menuItemView.isSelected = (index == 0)
            
            index = index + 1
        }
    }
    
    override func layoutSubviews() {
        super.layoutSubviews()

    }
    
    private func setupRatingMenuData(){
        self.RatingMenuItemDatas.append(RatingMenuItemData(name: String.localize("LB_CA_ALL"), selectedImage: "rateBtn0_on", unSelectedImage: "ratebtn0", hasRatingCount: false, action: ReviewRatingMenuAction.showAll))
        self.RatingMenuItemDatas.append(RatingMenuItemData(selectedImage: "rateBtn5_on", unSelectedImage: "rateBtn5", action: ReviewRatingMenuAction.showFiveRating))
        self.RatingMenuItemDatas.append(RatingMenuItemData(selectedImage: "rateBtn4_on", unSelectedImage: "rateBtn4", action: ReviewRatingMenuAction.showFourRating))
        self.RatingMenuItemDatas.append(RatingMenuItemData(selectedImage: "rateBtn3_on", unSelectedImage: "rateBtn3", action: ReviewRatingMenuAction.showThreeRating))
        self.RatingMenuItemDatas.append(RatingMenuItemData(selectedImage: "rateBtn2_on", unSelectedImage: "rateBtn2", action: ReviewRatingMenuAction.showTwoRating))
        self.RatingMenuItemDatas.append(RatingMenuItemData(selectedImage: "rateBtn1_on", unSelectedImage: "rateBtn1", action: ReviewRatingMenuAction.showOneRating))
        self.RatingMenuItemDatas.append(RatingMenuItemData(name: String.localize("LB_CA_PROD_REVIEW_IMG"), selectedImage: "rateBtn0_on", unSelectedImage: "ratebtn0", action: ReviewRatingMenuAction.showImageRating))
    }
    
    //MARK: - Views
    func setTotalRating(ratingMenu: ReviewRatingMenuAction, ratingValue: Int) {
        
        let indexButton = self.RatingMenuItemDatas.index(where: { (menuItemData) -> Bool in
            return menuItemData.action == ratingMenu
        })
        
        if indexButton != nil {
            let tappedMenuItem: RatingMenuItemView = self.ratingMenuItems[indexButton!]
                tappedMenuItem.ratingCountLabel.text = "(\(ratingValue))"
            
        }
    }
    
    //MARK: - User Actions
    
    @objc private func ratingMenuItemTapped(_ sender: UIButton){
        
        var ratingMenuAction = ReviewRatingMenuAction.unknown
        
        if sender.tag < self.ratingMenuItems.count && sender.tag >= 0{
            let ratingMenuItemData = self.RatingMenuItemDatas[sender.tag]
            ratingMenuAction = ratingMenuItemData.action
        }
        
        self.delegate?.didRatingMenuItemTap(ratingMenuAction)
        
        for tappedMenuItem in self.ratingMenuItems {
            tappedMenuItem.isSelected = (tappedMenuItem.tag == sender.tag)
        }
    }
}

internal class RatingMenuItemView: UIView{
    var backgroundImageView = UIImageView()
    var ratingCountLabel = UILabel()
    private var titleLabel = UILabel()
    var actionButton = UIButton()
    
    var isSelected: Bool = false {
        didSet {
            self.updateBackgroundImage()
        }
    }
    
    var selectedImage = ""
    var unSelectedImage = ""
    
    init(frame: CGRect, ratingMenuItemData: RatingMenuItemData?) {
        super.init(frame: frame)
        
        self.selectedImage = ratingMenuItemData?.selectedImage ?? ""
        self.unSelectedImage = ratingMenuItemData?.unSelectedImage ?? ""
        
        addSubview(backgroundImageView)
        addSubview(actionButton)
        
        titleLabel.text = ratingMenuItemData?.name
        addSubview(titleLabel)
        
        ratingCountLabel.isHidden = !(ratingMenuItemData?.hasRatingCount ?? false)
        addSubview(ratingCountLabel)
    }
    
    override func layoutSubviews() {
        super.layoutSubviews()
        backgroundImageView.frame = CGRect(x: 0, y: 0, width: frame.width, height: frame.height)
        
        actionButton.frame = CGRect(x: 0, y: 0, width: frame.width, height: frame.height)
        actionButton.backgroundColor = UIColor.clear
        
        ratingCountLabel.frame = CGRect(x: 0, y: frame.height - 15, width: frame.width, height: 15)
        ratingCountLabel.textAlignment = NSTextAlignment.center
        ratingCountLabel.formatSize(10)
        ratingCountLabel.textColor = UIColor.secondary2()
        
        var heighRating = CGFloat(0)
        if let ratingString = ratingCountLabel.text {
            heighRating = StringHelper.heightForText(ratingString, width: frame.width, font: ratingCountLabel.font)
        }
        
        titleLabel.frame = CGRect(x: 0, y: heighRating > 0 ? ratingCountLabel.frame.minY - frame.height/3 : frame.height/2 - frame.height/6, width: frame.width, height: frame.height/3)
        titleLabel.textAlignment = NSTextAlignment.center
        titleLabel.formatSize(14)
        titleLabel.textColor = UIColor.secondary3()
        
        self.updateBackgroundImage()
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    func updateBackgroundImage() {
        if isSelected {
            titleLabel.textColor = UIColor.white
            ratingCountLabel.textColor = UIColor.white
            backgroundImageView.image = UIImage(named: self.selectedImage)
        } else {
            titleLabel.textColor = UIColor.secondary3()
            ratingCountLabel.textColor = UIColor.secondary2()
            backgroundImageView.image = UIImage(named: self.unSelectedImage)
        }
    }
}

internal class RatingMenuItemData {
    var name: String?
    var selectedImage: String?
    var unSelectedImage: String?
    var hasRatingCount = false
    var action: ReviewRatingMenuAction = .unknown
    
    init(name: String? = "", selectedImage: String?, unSelectedImage: String?, hasRatingCount: Bool = true, action: ReviewRatingMenuAction = .unknown) {
        self.name = name
        self.selectedImage = selectedImage
        self.unSelectedImage = unSelectedImage
        self.hasRatingCount = hasRatingCount
        self.action = action
    }
}
