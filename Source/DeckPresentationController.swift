//
//  DeckPresentationController.swift
//  DeckTransition
//
//  Created by Harshil Shah on 15/10/16.
//  Copyright © 2016 Harshil Shah. All rights reserved.
//

import UIKit

final class DeckPresentationController: UIPresentationController, UIGestureRecognizerDelegate {
    
    // MARK: - Internal variables
    
    /// The presentation controller holds a strong reference to the
    /// transitioning delegate because `UIViewController.transitioningDelegate`
    /// is a weak property, and thus the `DeckTransitioningDelegate` would be
    /// unallocated right after the presentation animation.
    ///
    /// Since the transitioningDelegate only vends the presentation controller
    /// object and does not hold a reference to it, there is no issue of a
    /// circular dependency here.
    var transitioningDelegate: DeckTransitioningDelegate?
    
    // MARK: - Private variables
    
    private var isSwipeToDismissGestureEnabled = true
    private var pan: UIPanGestureRecognizer?
    private var scrollViewUpdater: ScrollViewUpdater?
    
    private let dimmingPresentingView = UIView()
    
    private var presentAnimation: (() -> ())? = nil
    private var presentCompletion: ((Bool) -> ())? = nil
    private var dismissAnimation: (() -> ())? = nil
    private var dismissCompletion: ((Bool) -> ())? = nil
	
    // MARK: - Initializers
    
    convenience init(presentedViewController: UIViewController,
                     presenting presentingViewController: UIViewController?,
                     isSwipeToDismissGestureEnabled: Bool,
                     presentAnimation: (() -> ())? = nil,
                     presentCompletion: ((Bool) ->())? = nil,
                     dismissAnimation: (() -> ())? = nil,
                     dismissCompletion: ((Bool) -> ())? = nil) {
        self.init(presentedViewController: presentedViewController,
                  presenting: presentingViewController)
        
        self.isSwipeToDismissGestureEnabled = isSwipeToDismissGestureEnabled
        self.presentAnimation = presentAnimation
        self.presentCompletion = presentCompletion
        self.dismissAnimation = dismissAnimation
        self.dismissCompletion = dismissCompletion
    }

    // MARK: - Sizing
    
    private var statusBarHeight: CGFloat {
        return UIApplication.shared.statusBarFrame.height
    }
	
    override var frameOfPresentedViewInContainerView: CGRect {
        guard let containerView = containerView else {
            return .zero
        }
        
        let yOffset: CGFloat = DeckConstants.topInsetForPresentedView + statusBarHeight
        
        return CGRect(x: CGFloat(0),
                      y: yOffset,
                      width: containerView.bounds.width,
                      height: containerView.bounds.height - yOffset)
    }
	
	// MARK: - Presentation
    
    override func presentationTransitionWillBegin() {
        guard let containerView = containerView else {
            return
        }
        
        /// A CGRect to be used as a proxy for the frame of the presentingView
        let initialFrame: CGRect = containerView.bounds
        
        dimmingPresentingView.backgroundColor = UIColor.black.withAlphaComponent(0)
        containerView.insertSubview(dimmingPresentingView, belowSubview: presentedViewController.view)
        dimmingPresentingView.frame = initialFrame
        
        presentedViewController.transitionCoordinator?.animate(
            alongsideTransition: { [weak self] context in
                guard let `self` = self else {
                    return
                }
                
                self.presentAnimation?()
                self.dimmingPresentingView.backgroundColor = UIColor.black.withAlphaComponent(DeckConstants.alphaValueForDimView)
            }, completion: { _ in
            }
        )
    }
    
    /// Method to ensure the layout is as required at the end of the
    /// presentation. This is required in case the modal is presented without
    /// animation.
    ///
    /// The various layout related functions performed by this method are:
    /// - Ensure that the view is in the same state as it would be after
    ///   animated presentation
    /// - Add a black background view to present to complete cover the
    ///   `presentingViewController`'s view
    ///
    /// It also sets up the gesture recognizer to handle dismissal of the modal
    /// view controller by panning downwards
    override func presentationTransitionDidEnd(_ completed: Bool) {
        presentedViewController.view.frame = frameOfPresentedViewInContainerView
        
        dimmingPresentingView.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            dimmingPresentingView.topAnchor.constraint(equalTo: presentingViewController.view.topAnchor),
            dimmingPresentingView.leftAnchor.constraint(equalTo: presentingViewController.view.leftAnchor),
            dimmingPresentingView.rightAnchor.constraint(equalTo: presentingViewController.view.rightAnchor),
            dimmingPresentingView.bottomAnchor.constraint(equalTo: presentingViewController.view.bottomAnchor)
        ])
        
        if isSwipeToDismissGestureEnabled {
            pan = UIPanGestureRecognizer(target: self, action: #selector(handlePan))
            pan!.delegate = self
            pan!.maximumNumberOfTouches = 1
            pan!.cancelsTouchesInView = false
            presentedViewController.view.addGestureRecognizer(pan!)
        }

        presentCompletion?(completed)
    }

    // MARK: - Dismissal
    
    /// Method to prepare the view hirarchy for the dismissal animation
    override func dismissalTransitionWillBegin() {
        guard let containerView = containerView else {
            return
        }
        
        let initialFrame: CGRect = containerView.bounds
        
        dimmingPresentingView.translatesAutoresizingMaskIntoConstraints = true
        dimmingPresentingView.frame = initialFrame
        
        presentedViewController.transitionCoordinator?.animate(
            alongsideTransition: { [weak self] context in
                guard let `self` = self else {
                    return
                }
                
                self.dismissAnimation?()
                self.dimmingPresentingView.backgroundColor = .clear
            }, completion: { _ in
            }
        )
    }
    
    /// Method to ensure the layout is as required at the end of the dismissal.
    /// This is required in case the modal is dismissed without animation.
    override func dismissalTransitionDidEnd(_ completed: Bool) {
        guard let containerView = containerView else {
            return
        }
        
        dimmingPresentingView.removeFromSuperview()
        
        let offscreenFrame = CGRect(x: CGFloat(0),
                                    y: containerView.bounds.height,
                                    width: containerView.bounds.width,
                                    height: containerView.bounds.height)
        presentedViewController.view.frame = offscreenFrame
        
        dismissCompletion?(completed)
    }
    
    // MARK: - Gesture handling
    
    private func isSwipeToDismissAllowed() -> Bool {
        guard let updater = scrollViewUpdater else {
            return isSwipeToDismissGestureEnabled
        }
        
        return updater.isDismissEnabled
    }
    
    @objc private func handlePan(gestureRecognizer: UIPanGestureRecognizer) {
        guard gestureRecognizer.isEqual(pan), isSwipeToDismissGestureEnabled else {
            return
        }
        
        switch gestureRecognizer.state {
        
        case .began:
            let detector = ScrollViewDetector(withViewController: presentedViewController)
            if let scrollView = detector.scrollView {
                scrollViewUpdater = ScrollViewUpdater(
                    withRootView: presentedViewController.view,
                    scrollView: scrollView)
            }
            gestureRecognizer.setTranslation(CGPoint(x: 0, y: 0), in: containerView)
        
        case .changed:
            if isSwipeToDismissAllowed() {
                let translation = gestureRecognizer.translation(in: presentedView)
                if translation.y < 50 {
                    // Skip first 50 points
                    return
                }
                updatePresentedViewForTranslation(inVerticalDirection: translation.y - 50)
            } else {
                gestureRecognizer.setTranslation(.zero, in: presentedView)
            }
        
        case .ended:
            var duration = 0.25
            if let requiredY = containerView?.frame.height,
                let currentY = presentedView?.frame.origin.y {
                    // Speed should be equal proportionaly to swiped space
                    let swipedSpacePercentage = Double(currentY/requiredY)
                    duration = swipedSpacePercentage * 0.25
                    
            }
            
            UIView.animate(
                withDuration: duration,
                animations: {
                    self.presentedView?.transform = .identity
                })
            scrollViewUpdater = nil

        default: break
        
        }
    }
    
    /// Method to update the modal view for a particular amount of translation
    /// by panning in the vertical direction.
    ///
    /// If elasticThreshold > 0 the translation of the modal view is proportional to the panning
    /// distance until the `elasticThreshold`, after which it increases at a
    /// slower rate, given by `elasticFactor`, to indicate that the
    /// `dismissThreshold` is nearing.
    ///
    /// Once the `dismissThreshold` is reached, the modal view controller is
    /// dismissed.
    ///
    /// - parameter translation: The translation of the user's pan gesture in
    ///   the container view in the vertical direction
    private func updatePresentedViewForTranslation(inVerticalDirection translation: CGFloat) {
        
        let elasticThreshold: CGFloat? = DeckConstants.translationElasticThreshold
        let dismissThreshold: CGFloat = DeckConstants.translationRequiredToDismiss
        
        let translationFactor: CGFloat = 1/2
        
        /// Nothing happens if the pan gesture is performed from bottom
        /// to top i.e. if the translation is negative
        if translation >= 0 {
            if let elasticThreshold = elasticThreshold {
                let translationForModal: CGFloat = {
                    if translation >= elasticThreshold {
                        let frictionLength = translation - elasticThreshold
                        let frictionTranslation = 30 * atan(frictionLength/120) + frictionLength/10
                        return frictionTranslation + (elasticThreshold * translationFactor)
                    } else {
                        return translation * translationFactor
                    }
                }()
                presentedView?.transform = CGAffineTransform(translationX: 0, y: translationForModal)
            } else {
                presentedView?.transform = CGAffineTransform(translationX: 0, y: translation)
            }
            
            if translation >= dismissThreshold {
                presentedViewController.dismiss(animated: true, completion: nil)
            }
            
        }
    }
}
