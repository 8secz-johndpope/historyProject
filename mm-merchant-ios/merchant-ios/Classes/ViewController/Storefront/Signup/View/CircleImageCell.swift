//
//  CircleImageCell.swift
//  merchant-ios
//
//  Created by Koon Kit Chan on 5/2/2016.
//  Copyright © 2016 WWE & CO. All rights reserved.
//

import Foundation


class CircleImageCell : UICollectionViewCell{
    private final let ImageHeight: CGFloat = 22
    private final let MarginTop: CGFloat = 4
    private final let CheckMarkScale : CGFloat = 1.4
    private final let OverWidth : CGFloat = 5
    var imageView = UIImageView()
    var blurView = UIView()
    var checkboxImageView = UIImageView()
    var isAnimating : Bool = false
    var circleView : CircleView?
    var circleOverlayView = CircleOverlayView()
    override init(frame: CGRect) {
        super.init(frame: frame)
        addSubview(imageView)
        addSubview(blurView)
        blurView.backgroundColor = UIColor.black
        blurView.alpha = 0.0
        checkboxImageView.image = UIImage(named: "icon_keyword_selected")
        checkboxImageView.isHidden = true
        
        addSubview(checkboxImageView)
        circleOverlayView.alpha = 0.0
        addSubview(circleOverlayView)
        layout()

    }

    override func layoutSubviews() {
        layout()
    }
    
    func layout(){
        imageView.frame = CGRect(x: self.bounds.midX - self.bounds.height/2, y: 0, width: self.bounds.height, height: self.bounds.height)
        imageView.round()
        blurView.frame = imageView.bounds
        blurView.round()
        let width = ImageHeight * CheckMarkScale * self.bounds.height / 120
        
        checkboxImageView.frame = CGRect(x: (imageView.frame.maxX - ImageHeight) - (width - ImageHeight) / 2, y: -(width - ImageHeight) / 2, width: width, height: width)
        
            
        
        circleView?.frame = imageView.bounds
        circleOverlayView.frame = CGRect(x: self.imageView.frame.minX - OverWidth, y: self.imageView.frame.minY - OverWidth, width: bounds.height + OverWidth * 2, height: bounds.height + OverWidth * 2)
    }
    func selected(_ isSelected: Bool) {
        if isSelected {
            checkboxImageView.isHidden = false
        }
        else {
            checkboxImageView.isHidden = true
        }
        
    }
    
    func drawSelect(_ isSelected: Bool, selecting: Bool) {
        if isSelected {
            checkboxImageView.isHidden = false
            self.addCircleView(selecting)
        }
        else {
            checkboxImageView.isHidden = true
            self.removeCircleView()
        }
        
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    func setImage(_ imageKey : String, category : ImageCategory){
       
        imageView.mm_setImageWithURL(ImageURLFactory.URLSize1000(imageKey, category: category), placeholderImage : UIImage(named: "holder"), contentMode: UIViewContentMode.scaleAspectFill)


    }
    func addCircleView(_ animated: Bool) {
        let circleWidth = imageView.bounds.width
        let circleHeight = circleWidth
        // Create a new CircleView
        if circleView == nil {
            circleView = CircleView(frame: CGRect(x: 0, y: 0, width: circleWidth, height: circleHeight))
            imageView.addSubview(circleView!)
        }
       
        circleView?.isHidden = false
        // Animate the drawing of the circle over the course of 1 second
        if animated {
            circleView!.animateCircle(0.2)
            self.scaleCheckBoxImage()
        } else {
            circleView!.animateCircle(0.0)
        }
    }
    
    func removeCircleView() {
        circleView?.isHidden = true
    }
    
    func scaleCheckBoxImage() {
       
        self.checkboxImageView.transform = CGAffineTransform(scaleX: 0.1, y: 0.1)
        isAnimating = true
        UIView.animate(withDuration: 0.25, delay: 0.0, options:
            UIViewAnimationOptions.allowUserInteraction, animations: {
                self.checkboxImageView.transform = CGAffineTransform(scaleX: self.CheckMarkScale, y: self.CheckMarkScale)
            }, completion: { finished in
                self.checkboxImageView.transform = CGAffineTransform(scaleX: 1.0, y: 1.0)
                self.isAnimating = false
            })
    }
    func centerAnimation()
    {
        self.circleOverlayView.alpha = 0.6
        UIView.animate(withDuration: 0.2, delay: 0.0, options:
            UIViewAnimationOptions.curveEaseIn, animations: {
                self.circleOverlayView.alpha = 0.3
                self.circleOverlayView.transform =  CGAffineTransform(scaleX: 2.0, y: 2.0)
            }, completion: { finished in
                self.circleOverlayView.alpha = 0.0
//                UIView.animate(withDuration: 0.1, delay: 0.0, options:
//                    UIViewAnimationOptions.CurveEaseIn, animations: {
//                        self.circleOverlayView.alpha = 0.0
//                    }, completion: { finished in
//                        
//                        
//                })
        })
    }
}
