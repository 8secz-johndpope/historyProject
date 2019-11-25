//
//  TutorialCell.swift
//  merchant-ios
//
//  Created by khanh.nguyen on 5/30/16.
//  Copyright © 2016 WWE & CO. All rights reserved.
//

import UIKit

protocol TutorialCellDelegate: NSObjectProtocol {
    func didSelectedDoneButton()
}


class TutorialCell: UICollectionViewCell {
    
    private var imageView : UIImageView!
    private var doneButton: UIButton!
    private var skipButton: UIButton!
    weak var delegate : TutorialCellDelegate?
    static var fixedSize = CGSize(width: 320, height: 568)
    
    override init(frame: CGRect) {
        super.init(frame: frame)
		
		// UX changed to fill the tutorial page full screen
		TutorialCell.fixedSize = CGSize(width: UIScreen.main.bounds.width, height: UIScreen.main.bounds.height)
		
        let imageView = UIImageView(frame: CGRect(x: (self.frame.size.width - TutorialCell.fixedSize.width) / 2, y: (self.frame.size.height - TutorialCell.fixedSize.height)/2, width: TutorialCell.fixedSize.width, height: TutorialCell.fixedSize.height))
        
        imageView.contentMode = .scaleAspectFit
        imageView.backgroundColor = UIColor.clear
        contentView.addSubview(imageView)
        contentView.backgroundColor = UIColor.white
        self.imageView = imageView
        
        self.addSkipButton()
        self.addDoneButton()
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    func configCellAtIndexPath(_ indexPath : IndexPath) -> Void {
        imageView.isHidden = false
        self.contentView.alpha = 1.0
        switch indexPath.row {
        case 0:
            imageView.image = UIImage(named: "ios_tut_1")
            skipButton.isHidden = false
            doneButton.isHidden = true
            break
        case 1:
            imageView.image = UIImage(named: "ios_tut_2")
            skipButton.isHidden = false
            doneButton.isHidden = true
            break
        case 2:
            imageView.image = UIImage(named: "ios_tut_3")
            skipButton.isHidden = true
            doneButton.isHidden = false
            break
        case 3:
            imageView.isHidden = true
            skipButton.isHidden = true
            doneButton.isHidden = true
            self.contentView.alpha = 0.0
            self.backgroundView = nil
            self.backgroundColor = UIColor.clear
            
        default:
            break
        }
    }
    
    func addSkipButton() -> Void {
        let bottomPadding: CGFloat = 10
        let rightPadding = CGFloat(10)
        let buttonHeight: CGFloat = 30
        let buttonWidth : CGFloat = 68
        
        let button = UIButton(frame: CGRect(x: self.frame.size.width - buttonWidth - rightPadding, y: self.frame.size.height - bottomPadding - buttonHeight, width: buttonWidth, height: buttonHeight))
        button.addTarget(self, action: #selector(TutorialCell.didSelectedDoneButton), for: UIControlEvents.touchUpInside)
        button.setImage(UIImage(named: "skip_button"), for: UIControlState())
        
        contentView.addSubview(button)
        
        self.skipButton = button
    }
    
    func addDoneButton() -> Void {
        let bottomPadding: CGFloat = 83
        let buttonHeight: CGFloat = 37
        let buttonWidth : CGFloat = 107
        
        let button = UIButton(frame: CGRect(x: (self.frame.size.width - buttonWidth) / 2, y: self.frame.size.height - bottomPadding - buttonHeight, width: buttonWidth, height: buttonHeight))
        button.addTarget(self, action: #selector(TutorialCell.didSelectedDoneButton), for: UIControlEvents.touchUpInside)
        button.setImage(UIImage(named: "open_btn"), for: UIControlState())
        
        contentView.addSubview(button)
        
        self.doneButton = button
    }

    
    @objc func didSelectedDoneButton(_ id : Any) -> Void {
        delegate?.didSelectedDoneButton()
    }
    
}
