//
//  DetailViewController.swift
//  SquirrelList
//
//  Created by Denis Geary Lopez on 3/22/15.
//  Copyright (c) 2015 Frenvu Inc. All rights reserved.
//

import UIKit

protocol DetailViewControllerDelegate: class {
    func detailViewController(controller: DetailViewController)
}

class DetailViewController: UIViewController {

    var delegate: DetailViewControllerDelegate?
    
    var offeredSquirrel: PFObject?

    var tradeProposal: PFObject?
    
    var yourSquirrel: PFObject?


    @IBOutlet weak var offeredSquirrelLabel: UILabel!
    
    
    @IBOutlet weak var popupView: UIView!

    @IBOutlet weak var yourSquirrelLabel: UILabel!

    @IBAction func acceptOffer(sender: AnyObject) {
    
        offeredSquirrel!["owner"] = PFUser.currentUser()["username"]
        
        yourSquirrel!["owner"] = tradeProposal!["offeringUser"]
        
        offeredSquirrel!.save()
        yourSquirrel!.save()
    
        tradeProposal!.deleteInBackground()
        delegate?.detailViewController(self)
        //self.navigationController?.popViewControllerAnimated(true)
        dismissViewControllerAnimated(true, completion: nil)
    
    }
    
    
    @IBAction func declineOffer(sender: AnyObject) {
        tradeProposal!.deleteInBackground()
        dismissViewControllerAnimated(true, completion: nil)
        delegate?.detailViewController(self)
    
    }

    required init(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
        modalPresentationStyle = .Custom
        transitioningDelegate = self
    }

    @IBAction func close() {
        dismissViewControllerAnimated(true, completion: nil)
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
        var offeredSquirrelQuery = PFQuery(className: "Squirrel")
        offeredSquirrelQuery.whereKey("objectId", equalTo: tradeProposal!["offeredSquirrelID"])
        offeredSquirrel = offeredSquirrelQuery.getFirstObject()
        
        var offeredFirstName = offeredSquirrel!["first_name"] as? String
        var offeredLastName = offeredSquirrel!["last_name"] as? String
        offeredSquirrelLabel.text = "\(offeredFirstName!) \(offeredLastName!)"
        
        
        var yourSquirrelQuery = PFQuery(className: "Squirrel")
        yourSquirrelQuery.whereKey("objectId", equalTo: tradeProposal!["proposedSquirrelID"])
        yourSquirrel = yourSquirrelQuery.getFirstObject()
        
        var yourFirstName = yourSquirrel!["first_name"] as? String
        var yourLastName = yourSquirrel!["last_name"] as? String
        yourSquirrelLabel.text = "\(yourFirstName!) \(yourLastName!)"
    }

    

    /*
    // MARK: - Navigation

    // In a storyboard-based application, you will often want to do a little preparation before navigation
    override func prepareForSegue(segue: UIStoryboardSegue, sender: AnyObject?) {
        // Get the new view controller using segue.destinationViewController.
        // Pass the selected object to the new view controller.
    }
    */

}

extension DetailViewController: UIViewControllerTransitioningDelegate {

    //To use custom animation controller
    func animationControllerForPresentedController(presented: UIViewController, presentingController presenting: UIViewController, sourceController source: UIViewController) -> UIViewControllerAnimatedTransitioning? {
        return BounceAnimationController()
    }
    
    func presentationControllerForPresentedViewController(presented: UIViewController, presentingViewController presenting: UIViewController!, sourceViewController source: UIViewController) -> UIPresentationController? {
            return DimmingPresentationViewController(presentedViewController: presented, presentingViewController: presenting)
    }
}


//Alerts you if the user touched outside of the popupView
extension DetailViewController: UIGestureRecognizerDelegate {
    func gestureRecognizer(gestureRecognizer: UIGestureRecognizer, shouldReceiveTouch touch: UITouch) -> Bool {
        return (touch.view == view)
    }
}



