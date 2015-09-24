//
//  DimmingPresentationViewController.swift
//  SquirrelList
//
//  Created by Denis Geary Lopez on 3/22/15.
//  Copyright (c) 2015 Frenvu Inc. All rights reserved.
//

import UIKit

class DimmingPresentationViewController: UIPresentationController {

    lazy var dimmingView = GradientView(frame: CGRect.zero)
    
    override func dismissalTransitionWillBegin() {
        if let transitionCoordinator = presentedViewController.transitionCoordinator() {
            transitionCoordinator.animateAlongsideTransition({ _ in self.dimmingView.alpha = 0}, completion: nil)
        }
    }
    
    override func presentationTransitionWillBegin() {
        dimmingView.frame = containerView!.bounds
        containerView!.insertSubview(dimmingView, atIndex: 0)
        
        //For the gradient to start to fade while the popupView is being animated
        dimmingView.alpha = 0
        if let transitionCoordinator = presentedViewController.transitionCoordinator() {
            transitionCoordinator.animateAlongsideTransition({ _ in
                self.dimmingView.alpha = 1
            }
            , completion: nil)
        }
    }
    
    override func shouldRemovePresentersView() -> Bool {
        return false
    }


}
