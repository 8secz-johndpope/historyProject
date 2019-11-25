//
//  MMRefreshAnimator.swift
//  merchant-ios
//
//  Created by Tony Fung on 1/8/2016.
//  Copyright © 2016年 WWE & CO. All rights reserved.
//

import Foundation
import UIKit
import Refresher

class MMRefreshAnimator: UIView , PullToRefreshViewDelegate {
    let startSpringFrame : Int = 40
    let maxSpringFrame : Int = 73
    let lastFrameIndex = 93
    
    var isFromCheckout: Bool = false
    var checkoutLoadingSize: CGFloat = 0
    
    var referenceNavigationController : UINavigationController?
    
    public let imageView = UIImageView()
    //pulltorefresh2_final0001  - 26
    //pulltorefresh2_final0042
    public var images : [UIImage] = []
    
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        imageView.frame = CGRect(x: 0, y: 0, width: 50, height: 50)
        
        for i in startSpringFrame...lastFrameIndex {
            images.append(UIImage(named: "pulltorefresh_final400"+String(format: "%02d", i))!)
        }
    }
    
    required init(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override func layoutSubviews() {
        super.layoutSubviews()
        if (isFromCheckout){
            DispatchQueue.main.async {
                self.imageView.frame = CGRect(x: 0, y: 0, width: self.checkoutLoadingSize, height: self.checkoutLoadingSize)
            }
        }else{
            var loadingCenter = self.center
            loadingCenter.y += 10
            imageView.center = loadingCenter
        }
        self.addSubview(imageView)
        
    }

    //MARK: Delegates
    
    func pullToRefreshAnimationDidStart(_ view: PullToRefreshView) -> (){
        
        animateImageView()
    }
    
    func animateImageView() {
        var imagesArray = Array(images.suffix(from: maxSpringFrame - startSpringFrame))
        
        imagesArray += Array(images[0..<(maxSpringFrame - startSpringFrame)])
        imageView.animationImages = imagesArray
        imageView.animationDuration = 1
        imageView.startAnimating()
    }
    
    func stopAnimateImageView() {
        imageView.stopAnimating()
    }
    
    func pullToRefreshAnimationDidEnd(_ view: PullToRefreshView) -> (){
        

        
        imageView.stopAnimating()
        imageView.image = images.last
    }
    
    
    func pullToRefresh(_ view: PullToRefreshView, progressDidChange progress: CGFloat) -> (){
        
        var index = 0
        if progress > 0.75 {
            let progress = ((progress > 1 ? 1 : progress) - 0.75)
            let springFrame = CGFloat(maxSpringFrame - startSpringFrame)
            index = Int(progress * 4 * springFrame)
        }

        index = index < 1 ? 0 : index
        imageView.image = images[index]
        
        if (index == 0) {
            setNavigationBar(hidden: false)
        }else{
            setNavigationBar(hidden: true)
        }
    }

    
//    var animating = false
    
    var isBarHidden = false
    
    func setNavigationBar(hidden: Bool){
        
        if hidden == isBarHidden {
            return
        }
        isBarHidden = hidden
        if let navController = referenceNavigationController {
            navController.navigationBar.layer.removeAllAnimations()
            navController.navigationBar.alpha = hidden ? 1 : 0
            UIView.animate(withDuration: 0.5, animations: { 
                navController.navigationBar.alpha = hidden ? 0 : 1
                }, completion: { (completed) in
                    navController.setNavigationBarHidden(hidden, animated: false)
            })
            
        }
    }
    
    func pullToRefresh(_ view: PullToRefreshView, stateDidChange state: PullToRefreshViewState) -> (){
        
        
    }
    
    
    
}
