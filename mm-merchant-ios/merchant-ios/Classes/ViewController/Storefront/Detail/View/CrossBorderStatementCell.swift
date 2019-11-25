//
//  CrossBorderStatementCell.swift
//  merchant-ios
//
//  Created by Quang Truong Dinh on 8/24/16.
//  Copyright © 2016 WWE & CO. All rights reserved.
//

class CrossBorderStatementCell : UICollectionViewCell{
    static let cellIdentifier = "CrossBorderStatementCellID"
    
    private var descriptionLabel = UILabel()
    var topView = UIView()
    var bottomView = UIView()
    static let HorizontalMargin : CGFloat = 10
    static let SeperatorHeight : CGFloat = 5
    static let MarginTop: CGFloat = 10
    override init(frame: CGRect) {
        super.init(frame: frame)
        backgroundColor = UIColor.white
        
        descriptionLabel.formatSmall()
        descriptionLabel.text = String.localize("LB_CA_XB_TAX_DESC_DTL")
        descriptionLabel.lineBreakMode = NSLineBreakMode.byWordWrapping
        descriptionLabel.textColor = UIColor.secondary4()
        descriptionLabel.numberOfLines = 0
        addSubview(descriptionLabel)
        addSubview(topView)
        addSubview(bottomView)
        layoutSubviews()
    }
    override func layoutSubviews() {
        super.layoutSubviews()
        topView.frame = CGRect(x: 0,y: 0,width: bounds.width,height: CrossBorderStatementCell.SeperatorHeight)
        topView.backgroundColor = UIColor.primary2()
        
        let descriptionLabelWidth = bounds.width - 2*CrossBorderStatementCell.HorizontalMargin
        descriptionLabel.frame = CGRect(x: CrossBorderStatementCell.HorizontalMargin, y: CrossBorderStatementCell.SeperatorHeight + CrossBorderStatementCell.MarginTop, width: descriptionLabelWidth, height: descriptionLabel.optimumHeight(text: descriptionLabel.text, width: descriptionLabelWidth))
        bottomView.frame = CGRect(x: 0,y: bounds.height - CrossBorderStatementCell.SeperatorHeight,width: bounds.width,height: CrossBorderStatementCell.SeperatorHeight)
        bottomView.backgroundColor = UIColor.primary2()
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    class func getHeight(_ width: CGFloat) -> CGFloat{
        let label = UILabel()
        label.lineBreakMode = NSLineBreakMode.byWordWrapping
        label.formatSmall()

        if let font = UIFont(name: Constants.Font.Normal, size: 14) {
            label.font = font
        } else {
            label.formatSizeBold(14)
        }
        label.frame = CGRect(x: 0, y: 0, width: width - 2*CrossBorderStatementCell.HorizontalMargin, height: 0)

        label.text = String.localize("LB_CA_XB_TAX_DESC_DTL")
        if let font = UIFont(name: Constants.Font.Normal, size: label.font.pointSize){
            label.font = font
        }
        return  2*CrossBorderStatementCell.SeperatorHeight + 3*MarginTop + label.optimumHeight()
    }
}
