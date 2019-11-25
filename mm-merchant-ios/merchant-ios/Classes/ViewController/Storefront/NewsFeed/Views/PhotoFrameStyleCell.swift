//
//  PhotoFrameStyleCell.swift
//  PhotoFrame
//
//  Created by Markus Chow on 4/5/2016.
//  Copyright © 2016 Markus Chow. All rights reserved.
//

import UIKit

class PhotoFrameStyleCell: UICollectionViewCell {
	
	var frameImageView : UIImageView!
	
	var imageButton : UIButton!
    
	private final let colorBackgroundSelected = UIColor.selectedRed()
    
	override init(frame: CGRect) {
		super.init(frame: frame)

		NotificationCenter.default.addObserver(self, selector: #selector(PhotoFrameStyleCell.isSelectedFrame), name: NSNotification.Name(rawValue: "PhotoFrameStyleCellSelectedFrame"), object: nil)
		
		setupImageView()
		
		// default not selected
		isSelectedFrame(false)
		
	}
	
	required init?(coder aDecoder: NSCoder) {
		fatalError("init(coder:) has not been implemented")
	}
	
	override func layoutSubviews() {
		super.layoutSubviews()
	}
	
	deinit {
		NotificationCenter.default.removeObserver(self, name: NSNotification.Name(rawValue: "PhotoFrameStyleCellSelectedFrame"), object: nil)
	}

	func setupImageView() {
		frameImageView = UIImageView(frame: CGRect(x: 0, y: 0, width: self.frame.size.width, height: self.frame.size.height))
		frameImageView.contentMode = .scaleAspectFit
		self.addSubview(frameImageView)
	}
	
	@objc func isSelectedFrame(_ selected: Bool = false) {

		/* disabled shift up frame for selected item
		let y = (selected == true ? -10.0 : 0.0) as CGFloat
		
		var rect = self.frameImageView.frame
		
		rect.origin.y = y
		
		self.frameImageView.frame = rect
		*/
  
//        if selected {
//            self.frameImageView.layer.borderColor = colorBackgroundSelected.cgColor
//            self.frameImageView.layer.borderWidth = 3.0
//        } else {
//            self.frameImageView.layer.borderWidth = 0.0
//        }
        if let imageView = self.frameImageView {
            if(selected){
                imageView.image = UIImage(named: "frame\(self.tag+1)_selected")
            } else {
                imageView.image = UIImage(named: "frame\(self.tag+1)")
            }
        }
    
	}
		
	
}
