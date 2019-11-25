//
//  ContentNotFoundView.swift
//  merchant-ios
//
//  Created by Markus Chow on 26/8/2016.
//  Copyright © 2016 WWE & CO. All rights reserved.
//

import Foundation

class ContentNotFoundView: UIView {
	
	class func showContentNotFoundView(_ frame: CGRect, onView: UIView) {
		
		let contentNotFoundView = UIView(frame: frame)
		contentNotFoundView.backgroundColor = UIColor.primary2()
		onView.addSubview(contentNotFoundView)
		
		let notFoundIconVIew = UIImageView(frame: CGRect(x: ((contentNotFoundView.size.width - 45) / 2), y: ((contentNotFoundView.size.height - 45) / 2), width: 45, height: 45))
		notFoundIconVIew.image = UIImage(named: "icon_warning.png")
		notFoundIconVIew.contentMode = .scaleAspectFill
		onView.addSubview(notFoundIconVIew)
		
		let label = UILabel(frame: CGRect(x: 0, y: notFoundIconVIew.origin.y + notFoundIconVIew.size.height + 5, width: contentNotFoundView.size.width, height: 40))
		label.textAlignment = .center
		label.textColor = UIColor.secondary4()
		label.text = String.localize("LB_CA_PAGENOTFOUND")
		
		onView.addSubview(label)
		
	}
}
