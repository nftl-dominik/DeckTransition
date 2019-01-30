//
//  DeckPresentingAnimationController.swift
//  DeckTransition
//
//  Created by Harshil Shah on 15/10/16.
//  Copyright © 2016 Harshil Shah. All rights reserved.
//

import UIKit

final class DeckPresentingAnimationController: NSObject, UIViewControllerAnimatedTransitioning {
    
    // MARK: - Private variables
    
    private let duration: TimeInterval
    
    // MARK: - Initializers
    
    init(duration: TimeInterval) {
        self.duration = duration
    }
    
    // MARK: - UIViewControllerAnimatedTransitioning
    
    func animateTransition(using transitionContext: UIViewControllerContextTransitioning) {
        guard let presentedViewController = transitionContext.viewController(forKey: .to) else {
            return
        }
        
        let containerView = transitionContext.containerView
        containerView.addSubview(presentedViewController.view)
        containerView.backgroundColor = .clear
        presentedViewController.view.backgroundColor = .clear
        presentedViewController.view.frame = CGRect(x: 0, y: containerView.bounds.height, width: containerView.bounds.width, height: containerView.bounds.height)
        
        let finalFrameForPresentedView = transitionContext.finalFrame(for: presentedViewController)
        
        UIView.animate(withDuration: transitionDuration(using: transitionContext), delay: 0, usingSpringWithDamping: 0.75, initialSpringVelocity: 0.7, options: [.curveEaseInOut], animations: {
            presentedViewController.view.frame = finalFrameForPresentedView
        }) { finished in
            transitionContext.completeTransition(finished)
        }
    }
    
    func transitionDuration(using transitionContext: UIViewControllerContextTransitioning?) -> TimeInterval {
        return duration
    }
    
}

