//
//  PlatformQuestionCell.swift
//  merchant-ios
//
//  Created by Sang Nguyen on 7/26/17.
//  Copyright © 2017 WWE & CO. All rights reserved.
//

import Foundation

protocol PlatformQuestionCellDelegate: NSObjectProtocol {
    func ratingChanged(_ indexPath: IndexPath?, value: Int)
}

class PlatformQuestionCell: UICollectionViewCell {
    
    static let CellIdentifier = "PlatformQuestionCellID"
    
    static let FontSize = 14
    
    static let MaxRatingNumber: Int = 10
    
    var indexPath: IndexPath?
    var contentLabel = UILabel()
    var containerRatingView = UIView()
    var topLineRatingView = UIView()
    var ratingButtons = [UIButton]()
    var ratingValue: Int {
        get {
            if let indexSelected = self.ratingButtons.index(where: {$0.isSelected == true }) {
                return indexSelected + 1
            }
            return PlatformQuestionCell.MaxRatingNumber
        }
        
        set {
            for index in 0 ..< PlatformQuestionCell.MaxRatingNumber {
                let button = ratingButtons[index]
                if newValue == index + 1 {
                    button.isSelected = true
                    button.layer.borderColor = UIColor.primary1().cgColor
                    button.layer.borderWidth = 1.0
                    button.layer.cornerRadius = button.height / 2
                } else {
                    button.isSelected = false
                    button.layer.borderWidth = 0
                }
            }
        }
    }
    
    weak var delegate: PlatformQuestionCellDelegate?
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        
        contentLabel.formatSize(PlatformQuestionCell.FontSize)
        contentLabel.text = "\(String.localize("LB_CA_REVIEW_NPS_TITLE"))\n\(String.localize("LB_CA_REVIEW_NPS_SUBTITLE"))"
        contentLabel.textAlignment = .center
        self.addSubview(contentLabel)
        
        topLineRatingView.backgroundColor = UIColor.secondary1()
        containerRatingView.addSubview(topLineRatingView)
        self.backgroundColor = UIColor.white
        self.addSubview(containerRatingView)
        
        for index in 1...PlatformQuestionCell.MaxRatingNumber {
            let button = UIButton(type: .custom)
            button.setTitle("\(index)", for: UIControlState())
            button.setTitle("\(index)", for: .selected)
            button.setTitleColor(UIColor.secondary2(), for: UIControlState())
            button.setTitleColor(UIColor.primary1(), for: .selected)
            button.addTarget(self, action: #selector(self.ratingButtonPressed), for: .touchUpInside)
            ratingButtons.append(button)
            containerRatingView.addSubview(button)
        }
        
    }
    
    //MARK: - Actions
    
    @objc func ratingButtonPressed(_ sender: UIButton) {
        if let indexRating = self.ratingButtons.index(of: sender) {
            self.ratingValue = indexRating + 1
            self.delegate?.ratingChanged(self.indexPath, value: self.ratingValue)
        }
    }
    
    //MARK: - Views
    
    override func layoutSubviews() {
        super.layoutSubviews()
        
        let leftRightPaddingLabel: CGFloat = 10
        let heightLabel: CGFloat = 82
        contentLabel.frame = CGRect(x: leftRightPaddingLabel, y: 0, width: self.bounds.width - 2 * leftRightPaddingLabel, height: heightLabel)
        
        
        let leftPaddingRatingView: CGFloat = 10
        containerRatingView.frame = CGRect(x: leftPaddingRatingView, y: contentLabel.frame.maxY, width: self.bounds.width - 2 * leftPaddingRatingView, height: self.bounds.height - contentLabel.frame.maxY)
        topLineRatingView.frame = CGRect(x: 0, y: 0, width: containerRatingView.width, height: 1.0)
        
        
        let widthButton: CGFloat = containerRatingView.width / CGFloat(ratingButtons.count)
        var currentX: CGFloat = 0
        for button in ratingButtons {
            button.frame = CGRect(x: currentX, y: (containerRatingView.frame.height - topLineRatingView.frame.maxY - widthButton) / 2, width: widthButton, height: widthButton)
            if button.isSelected {
                button.layer.cornerRadius = button.height / 2
                button.layer.borderColor = UIColor.primary1().cgColor
                button.layer.borderWidth = 1.0
            } else {
                button.layer.borderWidth = 0
            }
            currentX += widthButton
        }
        
    }
    
    
    // MARK: - Size
    class func getSizeCell(_ cellWidth: CGFloat) -> CGSize {
        
        return CGSize(width: cellWidth, height: 145)
        
    }
}
