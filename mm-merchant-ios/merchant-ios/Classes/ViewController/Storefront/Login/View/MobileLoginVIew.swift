//
//  LoginContentView.swift
//  merchant-ios
//
//  Created by Koon Kit Chan on 29/1/2016.
//  Copyright © 2016 WWE & CO. All rights reserved.
//

import Foundation

enum MobileLoginViewTextfieldTag:Int {
    case upperTextFieldTag = 7
    case lowerTextFieldTag = 8
}

class MobileLoginView : UIView {
    struct Padding{
        static let width : CGFloat = 22
        static let top : CGFloat = 26
        static let LeftRight : CGFloat = 100
    }
    struct Size{
        static let height: CGFloat = 46.5
        static let width : CGFloat = 120
    }

    var upperTextField = UITextField()
    var lowerTextField = UITextField()
    var imageView = UIImageView(image: UIImage(named: "input_box")!.resizableImage(withCapInsets: UIEdgeInsetsMake(30, 28, 30, 28)))
    var button = UIButton()
    var cornerButton = UIButton()
    
    var signupInputView = SignupInputView()
    var isTall = false
    var borderUpperTF = UITextField()
    var borderLowerTF = UITextField()
    override init(frame: CGRect) {
        super.init(frame: frame)
        addSubview(imageView)
        addSubview(upperTextField)
        upperTextField.tag = MobileLoginViewTextfieldTag.upperTextFieldTag.rawValue
        addSubview(lowerTextField)
        lowerTextField.tag = MobileLoginViewTextfieldTag.lowerTextFieldTag.rawValue
        button.formatDisable(UIColor.white)
        addSubview(button)
        cornerButton.formatWhite()
        addSubview(cornerButton)

        upperTextField.autocorrectionType = .no
        upperTextField.spellCheckingType = .no
        upperTextField.autocapitalizationType = .none
        
        lowerTextField.spellCheckingType = .no
        lowerTextField.autocapitalizationType = .none
        lowerTextField.isSecureTextEntry = true
        addSubview(signupInputView)
        
        self.addSubview(borderUpperTF)
        borderUpperTF.layer.borderColor = UIColor.primary1().cgColor
        borderUpperTF.layer.borderWidth = 1
        borderUpperTF.isUserInteractionEnabled = false
        borderUpperTF.isHidden = true
        
        self.addSubview(borderLowerTF)
        borderLowerTF.layer.borderColor = UIColor.primary1().cgColor
        borderLowerTF.layer.borderWidth = 1
        borderLowerTF.isUserInteractionEnabled = false
        borderLowerTF.isHidden = true
        
        layout(isTall)
        
        upperTextField.returnKeyType = .next
        lowerTextField.returnKeyType = .done
    }
    
    override func layoutSubviews() {
        super.layoutSubviews()
        layout(isTall)
    }
    
    func layout(_ isTall: Bool){
        if isTall {
            signupInputView.frame = CGRect(x: bounds.minX + Padding.width , y: bounds.minY + Padding.top, width: bounds.width - 2 * Padding.width, height: Size.height * 2 + 2)
            signupInputView.layout()
            imageView.frame = CGRect(x: bounds.minX + Padding.width , y: signupInputView.bounds.maxY + Padding.top * 2 , width: bounds.width - 2 * Padding.width, height: Size.height + 2)
            imageView.image = UIImage(named: "password")!.resizableImage(withCapInsets: UIEdgeInsets(top: 0, left: 100, bottom: 0, right: 100))
            lowerTextField.frame = CGRect(x:  bounds.width / 3, y: signupInputView.bounds.maxY + Padding.top * 2, width: bounds.width / 3 * 2, height: Size.height)
            button.frame = CGRect(x: bounds.minX + Padding.width, y: signupInputView.bounds.maxY  + Padding.top * 3 + Size.height , width: bounds.width - 2 * Padding.width, height: Size.height)
            cornerButton.frame = CGRect(x: bounds.maxX - Padding.width - Size.width, y: button.frame.maxY + Padding.top, width: Size.width, height: Size.height)
        } else {
            imageView.frame = CGRect(x: bounds.minX + Padding.width , y: bounds.minY + Padding.top, width: bounds.width - 2 * Padding.width, height: Size.height * 2)
            imageView.image = UIImage(named: "input_box")!.resizableImage(withCapInsets: UIEdgeInsets(top: 0, left: Padding.LeftRight, bottom: 0, right: Padding.LeftRight))
            
            upperTextField.frame = CGRect(x: imageView.frame.minX + Padding.LeftRight , y: bounds.minY + Padding.top, width: bounds.width - (Padding.width * 2 + Padding.LeftRight), height: Size.height)
            lowerTextField.frame = CGRect(x:  upperTextField.frame.minX, y: bounds.minY + Padding.top + upperTextField.bounds.height, width: upperTextField.bounds.width, height: Size.height)
            button.frame = CGRect(x: bounds.minX + Padding.width, y: bounds.minY + Padding.top * 2 + Size.height * 2 , width: bounds.width - 2 * Padding.width, height: Size.height)
            cornerButton.frame = CGRect(x: bounds.maxX - Padding.width - Size.width, y: button.frame.maxY + Padding.top, width: Size.width, height: Size.height)
            
            borderUpperTF.frame = CGRect(x: bounds.minX + Padding.width , y: bounds.minY + Padding.top, width: bounds.width - 2 * Padding.width - 1, height: Size.height + 1)
            
            borderLowerTF.frame = CGRect(x: bounds.minX + Padding.width , y: borderUpperTF.frame.maxY - 1, width: bounds.width - 2 * Padding.width - 1, height: Size.height)
        }
    }
    
    func showCodeInput(){
        signupInputView.isHidden = false
        upperTextField.isHidden = true
        isTall = true
        layout(isTall)
    }
    
    func hideCodeInput(){
        signupInputView.isHidden = true
        upperTextField.isHidden = false
        isTall = false
        layout(isTall)

    }
    
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}
