//
//  HashTagView.swift
//  merchant-ios
//
//  Created by khanh.nguyen on 9/6/17.
//  Copyright © 2017 WWE & CO. All rights reserved.
//

import UIKit

protocol HashTagViewDelegate: NSObjectProtocol {
    func hashTagViewAddTopic()
    func hashTagViewSelectedTag(_ item: String)
}

class HashTagView: UIView, UICollectionViewDelegate, UICollectionViewDataSource, UICollectionViewDelegateFlowLayout {

    
    static let HashTagHeight = CGFloat(25)
    static let HashTagFontSize = Int(15)
    static let ViewHeight = CGFloat(90)
    static let EmptyTagViewHeight = CGFloat(45)
    var collectionView: UICollectionView!
    weak var delegate:HashTagViewDelegate?
    var datasources = [HashTag]() {
        didSet {
            self.collectionView.reloadData()
        }
    }
    
    var leftLabel = UILabel()
    var rightLabel = UILabel()
    var iconImageView = UIImageView()
    var lineView = UIView()
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        self.setupCollectionView()
        self.addSubview(collectionView)
        
        leftLabel.applyFontSize(14, isBold: false)
        leftLabel.text = String.localize("LB_CA_POST_ADD_TOPIC")
        leftLabel.textColor = UIColor.secondary2()
        leftLabel.addGestureRecognizer(UITapGestureRecognizer(target: self, action: #selector(HashTagView.addTopic)))
        leftLabel.isUserInteractionEnabled = true
        self.addSubview(leftLabel)
        
        
        rightLabel.applyFontSize(14, isBold: false)
        rightLabel.text = String.localize("LB_CA_POST_MORE_TOPIC")
        rightLabel.textColor = UIColor.secondary2()
        rightLabel.textAlignment = .right
        rightLabel.addGestureRecognizer(UITapGestureRecognizer(target: self, action: #selector(HashTagView.moreTopic)))
        rightLabel.isUserInteractionEnabled = true
        self.addSubview(rightLabel)
        
        iconImageView.image = UIImage(named: "filter_right_arrow")
        iconImageView.contentMode = .scaleAspectFit
        self.addSubview(iconImageView)
        
        self.backgroundColor = UIColor.white
        
        lineView.backgroundColor = UIColor.primary2()
        self.addSubview(lineView)
        
        
    }
    
    @objc func moreTopic() {
        delegate?.hashTagViewAddTopic()
        self.recordAction(.Tap, sourceRef: "MoreTopic", sourceType: .Button, targetRef: "SearchTopic", targetType: .View)
    }
    
    @objc func addTopic() {
        delegate?.hashTagViewAddTopic()
        self.recordAction(.Tap, sourceRef: "AddTopic", sourceType: .Button, targetRef: "SearchTopic", targetType: .View)
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override func layoutSubviews() {
        super.layoutSubviews()
        let labelHeight = CGFloat(35)
        var width = StringHelper.getTextWidth(leftLabel.text ?? "", height: labelHeight, font: leftLabel.font)
        leftLabel.frame = CGRect(x: Margin.left, y: 0, width: bounds.size.width / 2, height: labelHeight)
        
        let iconSize = CGSize(width: 6, height: 24)
        
        width = StringHelper.getTextWidth(rightLabel.text ?? "", height: labelHeight, font: rightLabel.font)
        
        let margin = CGFloat(5)
        rightLabel.frame = CGRect(x: bounds.size.width -  Margin.left - width - iconSize.width - margin, y: 0, width: width, height: labelHeight)
        
        iconImageView.frame = CGRect(x: bounds.size.width -  Margin.left - iconSize.width, y: rightLabel.frame.midY - iconSize.height / 2 , width: iconSize.width, height: iconSize.height)
        
        
        collectionView.frame = CGRect(x: 0, y: leftLabel.frame.maxY + 5, width: bounds.size.width, height: HashTagView.HashTagHeight)
        
        lineView.frame = CGRect(x: 0, y: self.frame.sizeHeight - 10, width: self.frame.sizeWidth, height: 10)
        
    }
    
    func setupCollectionView() {
        let layout = UICollectionViewFlowLayout()
        layout.scrollDirection = .horizontal
        layout.headerReferenceSize = CGSize.zero
        layout.footerReferenceSize = CGSize.zero
        layout.sectionInset = UIEdgeInsets.zero
        layout.minimumInteritemSpacing = 0
        layout.minimumLineSpacing = 0
        layout.itemSize = CGSize(width: frame.width, height: 44)
        
        collectionView = UICollectionView(frame: CGRect(x: 0, y: 0, width: frame.width, height: 44), collectionViewLayout: layout)
        collectionView.contentInset = UIEdgeInsets.zero
        collectionView.backgroundColor = UIColor.clear
        
        collectionView.showsHorizontalScrollIndicator = false
        collectionView.dataSource = self
        collectionView.delegate = self
        collectionView.register(HashTagCell.self, forCellWithReuseIdentifier: HashTagCell.CellIdentifier)
        collectionView.contentInset = UIEdgeInsets(top: 0, left: Margin.left, bottom: 0, right: 0)
        
    }
    
    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        let cell = collectionView.dequeueReusableCell(withReuseIdentifier: HashTagCell.CellIdentifier, for: indexPath) as! HashTagCell
        
        let text =  datasources[indexPath.row].getHashTag()
        cell.label.text = text
        
        
        if let viewKey = self.analyticsViewKey {
            cell.initAnalytics(withViewKey: viewKey, impressionKey: AnalyticsManager.sharedManager.recordImpression( impressionType: "HotTopic", impressionDisplayName: text, positionComponent: "HotListing", positionIndex: indexPath.row + 1, positionLocation: "Editor-Post", viewKey: viewKey))
        }
        
        return cell
        
    }
    
    
    
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, minimumInteritemSpacingForSectionAt section: Int) -> CGFloat {
        return 10.0
    }
    
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, minimumLineSpacingForSectionAt section: Int) -> CGFloat {
        return 0.0
    }
    
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, sizeForItemAt indexPath: IndexPath) -> CGSize {
        let text = "#" + datasources[indexPath.row].tag
        let width = StringHelper.getTextWidth(text, height: HashTagView.HashTagHeight, font: UIFont.fontWithSize(HashTagCell.FontSize, isBold: false))
        return CGSize(width: width + Margin.left * 2, height: HashTagView.HashTagHeight)
    }
    
    func numberOfSections(in collectionView: UICollectionView) -> Int {
        return 1
    }
    
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return datasources.count
    }
    
    func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        let text =  datasources[indexPath.row].getHashTag()

        delegate?.hashTagViewSelectedTag(text + " ")
        
        self.recordAction(.Tap, sourceRef: text, sourceType: .Topic, targetRef: "PostDescription", targetType: .Add)
    }
    
    class func getCellWidth(_ text: String) -> CGFloat {
        var width = StringHelper.getTextWidth(text, height: HashTagView.HashTagHeight, font: UIFont.fontWithSize(HashTagCell.FontSize, isBold: false))
        width = width + Margin.left
        if width > UIScreen.size().width - 2 * Margin.left {
            width = UIScreen.size().width - 2 * Margin.left
        }
        return width

    }


}
