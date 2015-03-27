//
//  PopUpViewController.swift
//  SquirrelList
//
//  Created by Denis Geary Lopez on 3/23/15.
//  Copyright (c) 2015 Frenvu Inc. All rights reserved.
//

/*
A view controller that "pops" up in front of the parent view controller. This class is the parent class for many sub PopUpViewControllers
*/

import UIKit


class PopUpViewController: UIViewController {

    @IBOutlet weak var popupView: UIView!
    
    @IBAction func close() {
        dismissViewControllerAnimated(true, completion: nil)
    }


    required init(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
        modalPresentationStyle = .Custom
        transitioningDelegate = self
    }
    

    override func viewDidLoad() {
        super.viewDidLoad()
        popupView.layer.cornerRadius = 10
        //Makes it so that touching outside of popupView dismisses the popupView
        let gestureRecognizer = UITapGestureRecognizer(target: self, action: Selector("close"))
        gestureRecognizer.cancelsTouchesInView = false
        gestureRecognizer.delegate = self
        view.addGestureRecognizer(gestureRecognizer)
        //To counteract the gradient view's 50% black transparency making the background darker than intended
        view.backgroundColor = UIColor.clearColor()
        //For if you want to change the tint
        //view.tintColor = UIColor(red: 20/255, green: 160/255, blue: 160/255, alpha: 1)
    }

}

extension PopUpViewController: UIViewControllerTransitioningDelegate {

    //To use custom animation controller
    func animationControllerForPresentedController(presented: UIViewController, presentingController presenting: UIViewController, sourceController source: UIViewController) -> UIViewControllerAnimatedTransitioning? {
        return BounceAnimationController()
    }
    
    func presentationControllerForPresentedViewController(presented: UIViewController, presentingViewController presenting: UIViewController!, sourceViewController source: UIViewController) -> UIPresentationController? {
            return DimmingPresentationViewController(presentedViewController: presented, presentingViewController: presenting)
    }
}


//Alerts you if the user touched outside of the popupView
extension PopUpViewController: UIGestureRecognizerDelegate {
    func gestureRecognizer(gestureRecognizer: UIGestureRecognizer, shouldReceiveTouch touch: UITouch) -> Bool {
        return (touch.view == view)
    }
}
