//
//  SizeHeaderView.swift
//  merchant-ios
//
//  Created by Quang Truong Dinh on 9/6/16.
//  Copyright © 2016 WWE & CO. All rights reserved.
//

import Foundation

class SizeHeaderView: UICollectionReusableView {
    
    var sizeHeaderTappedHandler: (() -> Void)?
    
    static let ViewIdentifier = "SizeHeaderViewID"
    
    var topPadding: CGFloat = 7
    private let LabelHeight: CGFloat = 30
    private let arrowWidth: CGFloat = 6
    
    private var containerView = UIView()
    private var arrowImageView = UIImageView()
    private var sizeReferenceLabel = UILabel()
    private var sizeInformationLabel = UILabel()
    
//    var topPadding: CGFloat = 0
    var leftMargin: CGFloat = 0
    var rightMargin: CGFloat = 0
    
    var sizeGroupName = "" {
        didSet {
            sizeReferenceLabel.isHidden = sizeGroupName.isEmpty
            sizeReferenceLabel.text = String.localize("LB_CA_SIZE_REF") + sizeGroupName
            
            self.layoutSubviews()
        }
    }
    
    var colorName = "" {
        didSet {
            sizeReferenceLabel.isHidden = colorName.isEmpty
            sizeReferenceLabel.text = String.localize("LB_CA_COLOUR") + ": " + colorName
            
            self.layoutSubviews()
        }
    }
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        
        sizeReferenceLabel = UILabel()
        sizeReferenceLabel.text = String.localize("LB_CA_SIZE_REF")
        sizeReferenceLabel.backgroundColor = UIColor.primary2()
        sizeReferenceLabel.formatSize(14)
        sizeReferenceLabel.textColor = UIColor.secondary3()
        sizeReferenceLabel.textAlignment = .center
        sizeReferenceLabel.layer.masksToBounds = true
        sizeReferenceLabel.layer.borderWidth = 1
        sizeReferenceLabel.layer.borderColor = UIColor.clear.cgColor
        sizeReferenceLabel.layer.cornerRadius = LabelHeight / 2
        sizeReferenceLabel.lineBreakMode = .byTruncatingTail
        
        containerView.addSubview(sizeReferenceLabel)
        
        arrowImageView = UIImageView(frame: CGRect(x: frame.width - arrowWidth, y: 0, width: arrowWidth, height: LabelHeight))
        arrowImageView.image = UIImage(named: "arrow_right")
        arrowImageView.contentMode = .scaleAspectFit
        containerView.addSubview(arrowImageView)
        
        sizeInformationLabel = UILabel()
        sizeInformationLabel.text = String.localize("LB_CA_SIZEGRID")
        sizeInformationLabel.formatSize(14)
        sizeInformationLabel.textColor = UIColor.secondary2()
        sizeInformationLabel.sizeToFit()
        containerView.addSubview(sizeInformationLabel)
        
        addSubview(containerView)
        
        sizeInformationLabel.addGestureRecognizer(UITapGestureRecognizer(target: self, action: #selector(SizeHeaderView.sizeHeaderTapped)))
        sizeInformationLabel.isUserInteractionEnabled = true
        
        sizeReferenceLabel.accessibilityIdentifier = "PDP-UI_SIZE_GROUP"
        sizeInformationLabel.accessibilityIdentifier = "PDP-UI_SIZE_CHART"
    }
    
    override func layoutSubviews() {
        super.layoutSubviews()
        
        containerView.frame = CGRect(x: leftMargin, y: 0, width: width - leftMargin - rightMargin, height: LabelHeight)
        
        arrowImageView.frame = CGRect(x: containerView.width - arrowWidth, y: topPadding, width: arrowWidth, height: LabelHeight)
        
        sizeInformationLabel.frame = CGRect(x: arrowImageView.frame.minX - 3 - sizeInformationLabel.optimumWidth(), y: topPadding, width: sizeInformationLabel.optimumWidth(), height: LabelHeight)
        
        sizeReferenceLabel.frame = CGRect(x: 0, y: topPadding, width: sizeInformationLabel.frame.minX - 6, height: LabelHeight)
        sizeReferenceLabel.sizeToFit()
        let sizeReferenceLabelFrame = sizeReferenceLabel.frame
        sizeReferenceLabel.frame = CGRect(x: sizeReferenceLabelFrame.originX, y: sizeReferenceLabelFrame.originY, width: sizeReferenceLabelFrame.width + 30, height: LabelHeight)
        
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    func hideSizeInformation(_ isHidden: Bool){
        sizeInformationLabel.isHidden = isHidden
        arrowImageView.isHidden = isHidden
    }
    
    func setSizeReferenceLabelVisibility(_ isVisible: Bool){
        sizeReferenceLabel.isHidden = !isVisible
    }
    
    @objc func sizeHeaderTapped() {
        if let callback = self.sizeHeaderTappedHandler {
            callback()
        }
    }
    
    func hideSideReference (){
        sizeInformationLabel.isHidden = true
        arrowImageView.isHidden = true
    }
    
    func showSideReference (){
        sizeInformationLabel.isHidden = false
        arrowImageView.isHidden = false
    }
}

