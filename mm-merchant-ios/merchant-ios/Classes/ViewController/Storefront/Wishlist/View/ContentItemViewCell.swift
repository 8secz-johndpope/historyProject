//
//  ContentItemViewCell.swift
//  merchant-ios
//
//  Created by Vu Dinh Trung on 6/16/16.
//  Copyright © 2016 WWE & CO. All rights reserved.
//

import UIKit

class ContentItemViewCell: SwipeActionMenuCell {
    
    static let postCellIndentifier = "ContentItemViewCell"
    static let CellHeight : CGFloat = 100
    
    private final let heightLabel = CGFloat(21)
    private var widhtLabel = CGFloat(50)
    
    private var postImageView: UIImageView!
    private var brandDescriptionLabel: UILabel!

    var data: Any?
    var completionPostImageTapped : ((_ cell: ContentItemViewCell)-> ())?
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        
        let ContainerPaddingTop = CGFloat(10)
        let ContainerHeight = CGFloat(78)
        
        let containerFrame = CGRect(x: 0, y: ContainerPaddingTop, width: frame.width, height: ContainerHeight)
        let containerView = UIView(frame: containerFrame)
        
        self.contentView.addSubview(containerView)
        
        let singleTap = UITapGestureRecognizer(target: self, action: #selector(ContentItemViewCell.cellTapped))
        
        let MarginLeft = CGFloat(15)
        let productImageFrame = CGRect(x: MarginLeft, y: 0, width: 78, height: 78)
        let postImageView = UIImageView(frame: productImageFrame)
        postImageView.contentMode = .scaleAspectFit
        
        containerView.addSubview(postImageView)
        self.postImageView = postImageView
        self.postImageView.isUserInteractionEnabled = true
        self.postImageView.addGestureRecognizer(singleTap)
        self.postImageView.contentMode = .scaleAspectFill
        
        /// logo style
        let xPos = postImageView.frame.maxX + CGFloat(22)
		
        // description name label
        let descriptionLabel = { () -> UILabel in
			let descriptionLabel = UILabel(frame: CGRect(x: xPos, y: 0, width: self.width - xPos - Margin.left, height: postImageView.frame.size.height))
            descriptionLabel.formatSize(12)
            self.brandDescriptionLabel = descriptionLabel
            self.brandDescriptionLabel.text = ""
            self.brandDescriptionLabel.textColor = UIColor.secondary6()
            self.brandDescriptionLabel.textAlignment = .left
            
            return descriptionLabel
        }()
        
        containerView.addSubview(descriptionLabel)
		
        let lineHeight = CGFloat(1)
        let line = UIView(frame: CGRect(x: 0, y: self.contentView.frame.maxY - lineHeight, width: self.contentView.frame.width, height: lineHeight))
        line.backgroundColor = UIColor.backgroundGray()
        
        self.contentView.addSubview(line)
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override func layoutSubviews() {
        super.layoutSubviews()
		
		// clear left menu items
		self.leftMenuItems = nil
    }
    
    @objc func cellTapped() {
        if let callback = completionPostImageTapped {
            callback(self)
        }
    }
    
    func setupData(_ magazin: MagazineCover) {
        setImage(magazin.coverImage, category: .contentPageImages, targetImageView: self.postImageView, placeHolder: "default_cover")
        
        self.brandDescriptionLabel.text = magazin.contentPageName
		self.brandDescriptionLabel.lineBreakMode = NSLineBreakMode.byWordWrapping
		self.brandDescriptionLabel.numberOfLines = 0
        
        var brandDescriptionLabelHeight = self.brandDescriptionLabel.optimumHeight()
        
        if brandDescriptionLabelHeight > self.postImageView.height{
            brandDescriptionLabelHeight = self.postImageView.height
        }
        
        self.brandDescriptionLabel.frame = CGRect(x: self.brandDescriptionLabel.frame.minX, y: self.brandDescriptionLabel.frame.minY, width: self.brandDescriptionLabel.width, height: brandDescriptionLabelHeight)
    }
	
    /**
     set Image for image view
     
     - parameter imageKey:        key image String
     - parameter category:        category
     - parameter targetImageView: imageView
     */
    func setImage(_ imageKey : String, category : ImageCategory, targetImageView: UIImageView, placeHolder: String) {
        targetImageView.mm_setImageWithURL(ImageURLFactory.URLSize512(imageKey, category: category), placeholderImage : UIImage(named: placeHolder))
        targetImageView.contentMode = .scaleAspectFill
    }
}
