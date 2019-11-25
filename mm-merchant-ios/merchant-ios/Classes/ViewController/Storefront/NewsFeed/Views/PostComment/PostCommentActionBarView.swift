
//
//  TSChatActionBarView.swift
//  TSWeChat
//
//  Created by Hilen on 12/16/15.
//  Copyright © 2015 Hilen. All rights reserved.
//

import UIKit

protocol PostCommentActionBarViewDelegate: class {
   func showKeyboard()
}


class PostCommentActionBarView: UIView {
    
    static let ACTION_BAR_HEIGHT:CGFloat = 50
    
    weak var delegate: PostCommentActionBarViewDelegate?
    
    @IBOutlet weak var inputTextView: MMPlaceholderTextView! { didSet{
        inputTextView.font = UIFont.systemFont(ofSize: 17)
        inputTextView.layer.borderColor = UIColor.secondary1().cgColor
        inputTextView.layer.borderWidth = 1
        inputTextView.layer.cornerRadius = inputTextView.bounds.height / 2
        inputTextView.scrollsToTop = false
        inputTextView.textContainerInset = UIEdgeInsets(top: 7, left: 5, bottom: 5, right: 5)
        inputTextView.backgroundColor = UIColor(hexString: "#ffffff")
        inputTextView.returnKeyType = .default
        inputTextView.isHidden = false
        inputTextView.enablesReturnKeyAutomatically = true
        inputTextView.layoutManager.allowsNonContiguousLayout = false
        inputTextView.scrollsToTop = false
        inputTextView.placeholder = String.localize("LB_CA_COMMENT")
        }}
    

    
    @IBOutlet weak var shareButton: UIButton! {
        didSet {
            shareButton.setTitle(String.localize("LB_CA_POST_PUBLISH"), for: UIControlState())
        }
    }
    override init (frame: CGRect) {
        super.init(frame : frame)
        self.initContent()
    }
    
    convenience init () {
        self.init(frame:CGRect.zero)
        self.initContent()
    }
    
    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
    }
    
    func initContent() {
    }
    
    
    override func draw(_ rect: CGRect) {
        let scale = self.window!.screen.scale
        let width = 1 / scale
        let centerChoice: CGFloat = scale.truncatingRemainder(dividingBy: 2) == 0 ? 4 : 2
        let offset = scale / centerChoice * width
		
		if let context = UIGraphicsGetCurrentContext() {
			context.setLineWidth(width)
			context.setStrokeColor(UIColor(hexString: "#C2C3C7").cgColor)
			
			let x1: CGFloat = 0 + offset
			let y1: CGFloat = 0 + offset
			let x2: CGFloat = ScreenWidth + offset
			let y2: CGFloat = 0 + offset
			
			context.beginPath()
			context.move(to: CGPoint(x: x1, y: y1))
			context.addLine(to: CGPoint(x: x2, y: y2))
			
//            let x3: CGFloat = 0 + offset
//            let y3: CGFloat = 49.5 + offset
//            let x4: CGFloat = ScreenWidth + offset
//            let y4: CGFloat = 49.5 + offset
//
//            context.move(to: CGPoint(x: x3, y: y3))
//            context.addLine(to: CGPoint(x: x4, y: y4))
            context.strokePath()
		}
    }
	
    override func awakeFromNib() {

    }
	
    deinit {
        log.verbose("deinit")
    }
}




