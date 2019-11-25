//
//  UILabelExtension.swift
//  merchant-ios
//
//  Created by Koon Kit Chan on 15/10/15.
//  Copyright © 2015 Koon Kit Chan. All rights reserved.
//

import Foundation
import ObjectiveC

var UILabelAssociatedObjectHandle: UInt8 = 0

extension UILabel {
    
    var escapeFontSubstitution: Bool {
        get {
            return objc_getAssociatedObject(self, &UILabelAssociatedObjectHandle) as? Bool ?? false
        }
        set {
            objc_setAssociatedObject(self, &UILabelAssociatedObjectHandle, newValue, objc_AssociationPolicy.OBJC_ASSOCIATION_RETAIN_NONATOMIC)
        }
    }
    
    var substituteAllFontName : String {
        get {
            return self.font.fontName
        }
        
        set {
            guard let font = self.font else { return }
            if self.escapeFontSubstitution == false && (font.fontName != Constants.Font.Bold && font.fontName.lowercased().range(of: "bold") == nil) {
                self.font = UIFont(name: newValue, size: font.pointSize)
            }
        }
    }
    
    var substituteAllFontNameBold : String {
        get {
            return self.font.fontName
        }
        set {
            guard let font = self.font else { return }
            if self.escapeFontSubstitution == false && (font.fontName == Constants.Font.Bold || font.fontName.lowercased().range(of: "bold") != nil) {
                self.font = UIFont(name: newValue, size: font.pointSize)
            }
        }
    }
    
    func format(){
        self.textColor = UIColor.secondary2()
        self.lineBreakMode = .byWordWrapping
        self.numberOfLines = 0
    }
    
    func formatSize(_ size: Int) {
        formatSizeInFloat(CGFloat(size))
    }
    
    func formatSizeInFloat(_ size: CGFloat) {
        self.format()
        self.font = UIFont(name: self.font.fontName, size: size)
    }
    
    func formatSizeBold(_ size: Int) {
        self.format()
        self.font = UIFont.boldSystemFont(ofSize: CGFloat(size))
    }
    
    func formatSmall() {
        self.formatSize(14)
    }
    
    func applyFontSize(_ size: Int, isBold: Bool) {
        if let font = UIFont(name: isBold ? Constants.Font.Bold : Constants.Font.Normal, size: CGFloat(size)) {
            self.font = font
        } else {
            self.formatSize(size)
        }
    }
    
    func formatSingleLine(_ fontSize: Int = 0) {
        self.textColor = UIColor.secondary2()
        self.adjustsFontSizeToFitWidth = true
        if fontSize != 0 {
            self.font = UIFont(name: self.font.fontName, size: CGFloat(fontSize))
        }
    }
    
    func formatError() {
        self.font = UIFont(name: self.font.fontName, size: CGFloat(14))
        self.lineBreakMode = .byWordWrapping
        self.numberOfLines = 0
        self.textColor = UIColor.white
        self.textAlignment = .center
    }
    
    func formatNote() {
        self.font = UIFont(name: self.font.fontName, size: CGFloat(11))
        self.textColor = UIColor.noteColor()
        self.numberOfLines = 0
    }
    
    func optimumHeight(text: String? = nil, width: CGFloat? = nil) -> CGFloat {
        let label = UILabel(frame: CGRect(x: 0, y: 0, width: (width != nil) ? width! : frame.width, height: CGFloat.greatestFiniteMagnitude))
        label.numberOfLines = 0
        label.lineBreakMode = lineBreakMode
        label.font = font
        label.text = (text != nil) ? text! : self.text
        
        label.sizeToFit()
        
        return label.frame.height
    }
    
    func optimumWidth(text: String? = nil, height: CGFloat? = nil) -> CGFloat {
        let label = UILabel(frame: CGRect(x: 0, y: 0, width: CGFloat.greatestFiniteMagnitude, height: (height != nil) ? height! : frame.height))
        label.numberOfLines = 1
        label.font = font
        label.text = (text != nil) ? text! : self.text
        
        label.sizeToFit()
        
        return label.frame.width
    }
    
    func addImage(_ imageName: String, imageWidth: CGFloat = 0, imageHeight: CGFloat = 0, afterLabel bolAfterLabel: Bool = false)
    {
        
        self.removeImage()
        let attachment: NSTextAttachment = NSTextAttachment()
        attachment.image = UIImage(named: imageName)
        
        if let image = attachment.image{
            if (imageWidth == 0 || imageHeight == 0){
                attachment.bounds = CGRect(x: 0, y: -2.5, width: image.size.width, height: image.size.height);
            }else{
                attachment.bounds = CGRect(x: 0, y: 0, width: imageWidth, height: imageHeight);
            }
            
        }
        let attachmentString: NSAttributedString = NSAttributedString(attachment: attachment)
        let spacing = NSAttributedString(string: " ")
        
        let paraStyle = NSMutableParagraphStyle()
        paraStyle.lineBreakMode = .byTruncatingTail
        paraStyle.alignment = .center
        if (bolAfterLabel)
        {
            let strLabelText: NSMutableAttributedString = NSMutableAttributedString(string: self.text ?? "")
            strLabelText.append(spacing)
            strLabelText.append(attachmentString)
            strLabelText.addAttribute(NSAttributedStringKey.paragraphStyle, value: paraStyle, range: NSRange(location: 0, length: strLabelText.length))
            self.attributedText = strLabelText
        }
        else
        {
            let strLabelText: NSAttributedString = NSAttributedString(string: self.text ?? "")
            let mutableAttachmentString: NSMutableAttributedString = NSMutableAttributedString(attributedString: attachmentString)
            mutableAttachmentString.append(spacing)
            mutableAttachmentString.append(strLabelText)
            mutableAttachmentString.addAttribute(NSAttributedStringKey.paragraphStyle, value: paraStyle, range: NSRange(location: 0, length: mutableAttachmentString.length))
            self.attributedText = mutableAttachmentString
            
        }
    }
    
    func removeImage()
    {
        let text = self.text
        self.attributedText = nil
        self.text = text
    }
	
	func layoutInactiveOrOutOfStockLabel(forView view: UIView, sizePercentage: CGFloat) {
		let size = view.frame.width * sizePercentage
		self.frame = CGRect(x: 0, y: 0, width: size, height: size)
		self.center = view.center
		self.alpha = 0.7
		self.backgroundColor = UIColor.secondary4()
		self.textColor = UIColor.white
		self.textAlignment = .center
		self.font = UIFont.systemFont(ofSize: 14)
		self.text = ""
		
		// Circle mask
		let maskPath = UIBezierPath(roundedRect: self.bounds, byRoundingCorners: [.allCorners], cornerRadii: CGSize(width: size / 2, height: size / 2))
		let shape = CAShapeLayer()
		shape.path = maskPath.cgPath
		self.layer.mask = shape
		
	}
    
    func formatUnderline(){
        guard let text = self.text else{
            return
        }
        let textRange = NSMakeRange(0, text.count)
        let attributedText = NSMutableAttributedString(string: text)
        attributedText.addAttribute(NSAttributedStringKey.underlineStyle, value:NSUnderlineStyle.styleSingle.rawValue, range: textRange)
        self.attributedText = attributedText
    }
}
