//
//  CuratorSettingViewCell.swift
//  merchant-ios
//
//  Created by Vu Dinh Trung on 5/31/16.
//  Copyright © 2016 WWE & CO. All rights reserved.
//

import UIKit

protocol CuratorSettingViewCellDelegate: NSObjectProtocol {
    func handleSelectedImageSquare(_ gesture: UITapGestureRecognizer)
    func handleSelectedImageRect(_ gesture: UITapGestureRecognizer)
}

class CuratorSettingViewCell: UICollectionViewCell {
    
    static let CuratorSettingViewCellId = "CuratorSettingViewCellId"
    
    private let heightLabel = CGFloat(22)
    private let heightTop = CGFloat(30)
    private var squareWidth = CGFloat(0)
    private var squareheight = CGFloat(0)
    private var widthRect = CGFloat(0)
    private var heightRect = CGFloat(0)

    var topView: UIView!
    var labelCuratorCover : UILabel!
    var imageViewCoverSquare: UIImageView!
    var imageViewCoverRect: UIImageView!
    var lineView: UIView!
    
    var labelSquare = UILabel()
    var labelRect = UILabel()
    
    weak var curatorCellDelegate: CuratorSettingViewCellDelegate!
   
    var imageData = ImageDataResponse() {
        
        didSet {
            if let cover = imageData.coverImage {
                self.imageViewCoverRect.mm_setImageWithURL(ImageURLFactory.URLSize1000(cover, category: .user), placeholderImage: UIImage(named: "curator_cover_placeholder_hoz"))
				self.updateCuratorSettingsImages(.coveraAternateImage, imageKey: cover)
            }
            if let profile = imageData.profileImage {
                self.imageViewCoverSquare.mm_setImageWithURL(ImageURLFactory.URLSize1000(profile, category: .user), placeholderImage: UIImage(named: "curator_cover_placeholder_vert"))
				self.updateCuratorSettingsImages(.profileAlternateImage, imageKey: profile)
            }
            
        }
    }
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        
        let widthUse = self.bounds.width - Margin.left * 2 * 3
        squareWidth = widthUse / 3
        squareheight = squareWidth
        
        widthRect = widthUse * 2 / 3
        heightRect = squareheight
        
        topView = UIView(frame: CGRect(x: 0, y: 0, width: bounds.width, height: heightTop))
        topView.backgroundColor = UIColor.secondary5()
        addBottomBorderWithColor(UIColor.secondary1(), andWidth: 1)
        addSubview(topView)
        
        labelCuratorCover = UILabel(frame: CGRect(x: Margin.left * 2, y: (heightTop - heightLabel) / 2, width: bounds.width - Margin.left * 4, height: heightLabel))
        labelCuratorCover.formatSize(14)
        labelCuratorCover.text = String.localize("LB_CA_CURATOR_COVER")
        topView.addSubview(labelCuratorCover)
        
        lineView = UIView(frame: CGRect(x: 0, y: topView.frame.maxY - 1, width: bounds.width, height: 1))
        lineView.backgroundColor = UIColor.secondary1()
        topView.addSubview(lineView)
        
        imageViewCoverSquare = UIImageView(frame: CGRect(x: Margin.left * 2, y: topView.frame.maxY + Margin.top * 2, width: squareWidth, height: squareheight))
        imageViewCoverSquare.image = UIImage(named: "curator_cover_placeholder_vert")
        imageViewCoverSquare.contentMode = .scaleAspectFill
        imageViewCoverSquare.round(10)
        imageViewCoverSquare.viewBorder(UIColor.secondary1(), width: 1)
        imageViewCoverSquare.isUserInteractionEnabled = true
        imageViewCoverSquare.addGestureRecognizer(UITapGestureRecognizer(target: self, action: #selector(CuratorSettingViewCell.didSelectSquareImage)))
        addSubview(imageViewCoverSquare)
        
        imageViewCoverRect = UIImageView(frame: CGRect(x: Margin.left * 2 + imageViewCoverSquare.frame.maxX, y: topView.frame.maxY + Margin.top * 2, width: bounds.width - Margin.left * 4 - imageViewCoverSquare.frame.maxX, height: heightRect))
        imageViewCoverRect.image = UIImage(named: "curator_cover_placeholder_hoz")
        imageViewCoverRect.contentMode = .scaleAspectFill
        imageViewCoverRect.round(10)
        imageViewCoverRect.viewBorder(UIColor.secondary1(), width: 1)
        imageViewCoverRect.isUserInteractionEnabled = true
        imageViewCoverRect.addGestureRecognizer(UITapGestureRecognizer(target: self, action: #selector(CuratorSettingViewCell.didSelectCoverImage)))
        addSubview(imageViewCoverRect)
        
        let textLabel = String.localize("LB_CA_CURATOR_COVER_SQUARE")
        labelSquare.formatSize(11)
        labelSquare.text = textLabel
        let widthLabel = StringHelper.getTextWidth(textLabel, height: heightLabel, font: labelSquare.font)
        labelSquare.frame = CGRect(x: imageViewCoverSquare.frame.maxX - widthLabel, y: imageViewCoverSquare.frame.maxY + 2, width: widthLabel, height: heightLabel)
        addSubview(labelSquare)
        
        let textLabelRect = String.localize("LB_CA_CURATOR_COVER_RECT")
        let widthLabelRect = StringHelper.getTextWidth(textLabel, height: heightLabel, font: labelSquare.font)
        labelRect.formatSize(11)
        labelRect.text = textLabelRect
        labelRect.frame = CGRect(x: imageViewCoverRect.frame.maxX - widthLabelRect, y: imageViewCoverRect.frame.maxY + 2, width: widthLabel, height: heightLabel)
        
        addSubview(labelRect)
		
		let user = Context.getUserProfile()
		if user.coverAlternateImage.length > 0 {
			self.imageViewCoverRect.mm_setImageWithURL(ImageURLFactory.URLSize1000(user.coverAlternateImage, category: .user), placeholderImage: UIImage(named: "curator_cover_placeholder_hoz"))
		}
		
		if user.profileAlternateImage.length > 0 {
			self.imageViewCoverSquare.mm_setImageWithURL(ImageURLFactory.URLSize512(user.profileAlternateImage, category: .user), placeholderImage: UIImage(named: "curator_cover_placeholder_vert"))
		}
		
	}
	
	func updateCuratorSettingsImages(_ imageType: ImageType, imageKey: String) {
		
		guard imageKey.length > 0 else { return }
		
		let user = Context.getUserProfile()
		
		switch imageType {
		case .coveraAternateImage:
			user.coverAlternateImage = imageKey
			break
		case .profileAlternateImage:
			user.profileAlternateImage = imageKey
			break
		default:
			break
		}
		
		Context.saveUserProfile(user)
	}
	
    func addBottomBorderWithColor(_ color: UIColor, andWidth borderWidth: CGFloat) {
        let border: UIView = UIView()
        border.backgroundColor = color
        border.autoresizingMask = [.flexibleWidth, .flexibleTopMargin]
        border.frame = CGRect(x: 0, y: self.frame.height - borderWidth, width: self.frame.size.width, height: borderWidth)
        self.topView.addSubview(border)
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    @objc func didSelectSquareImage(_ gesture: UITapGestureRecognizer) {
        if let delegate = self.curatorCellDelegate {
            delegate.handleSelectedImageSquare(gesture)
        }
    }
    
    @objc func didSelectCoverImage(_ gesture: UITapGestureRecognizer) {
        if let delegate = self.curatorCellDelegate {
            delegate.handleSelectedImageRect(gesture)
        }
    }
    
    class func getHeightCell() -> CGFloat {
        let width = Constants.ScreenSize.SCREEN_WIDTH - Margin.left * 2 * 3
        let heightLabel = CGFloat(24)
        return Margin.top * 2 * 3 + width / 3 + heightLabel
    }
}
