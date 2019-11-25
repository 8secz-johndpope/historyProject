//
//  PushFadingAnimator.swift
//  merchant-ios
//
//  Created by Tony Fung on 12/8/2016.
//  Copyright © 2016年 WWE & CO. All rights reserved.
//

import UIKit


class PushFadingAnimator: NSObject, UIViewControllerAnimatedTransitioning {
    
    func transitionDuration(using transitionContext: UIViewControllerContextTransitioning?) -> TimeInterval {
        return 0.5
    }
    
    func animateTransition(using transitionContext: UIViewControllerContextTransitioning)  {
        if let toController = transitionContext.viewController(forKey: UITransitionContextViewControllerKey.to){
            transitionContext.containerView.addSubview(toController.view)
            toController.view.alpha = 0.0
            UIView.animate(withDuration: self.transitionDuration(using: transitionContext), animations: {
                toController.view.alpha = 1.0
            }, completion: { (completed) in
                transitionContext.completeTransition(!transitionContext.transitionWasCancelled)
            }) 
        }
    }
    
}


class PopFadingAnimator: NSObject, UIViewControllerAnimatedTransitioning {
    
    func transitionDuration(using transitionContext: UIViewControllerContextTransitioning?) -> TimeInterval {
        return 0.5
    }
    
    func animateTransition(using transitionContext: UIViewControllerContextTransitioning)  {
        if let toController = transitionContext.viewController(forKey: UITransitionContextViewControllerKey.to), let fromController = transitionContext.viewController(forKey: UITransitionContextViewControllerKey.from){
            transitionContext.containerView.addSubview(toController.view)
            transitionContext.containerView.insertSubview(toController.view, belowSubview: fromController.view)
            
            UIView.animate(withDuration: self.transitionDuration(using: transitionContext), animations: {
                fromController.view.alpha = 0.0
            }, completion: { (completed) in
                transitionContext.completeTransition(!transitionContext.transitionWasCancelled)
            }) 
        }
    }
    
}
