//
//  TradeOfferNewViewController.swift
//  SquirrelList
//
//  Created by Denis Geary Lopez on 3/24/15.
//  Copyright (c) 2015 Frenvu Inc. All rights reserved.
//


//This view controller is for proposing trades to other users
import UIKit


class TradeViewController: PopUpViewController, UserSquirrelsPopUpViewControllerDelegate {

    var desiredSquirrel: PFObject?
    var desiredSquirrelOwner: PFUser?
    var offeredSquirrel: PFObject?


    @IBOutlet weak var desiredSquirrelLabel: UILabel!
    @IBOutlet weak var offeredSquirrelLabel: UILabel!
    @IBOutlet weak var proposeTradeButton: UIButton!
    @IBOutlet weak var selectSquirrelButton: UIButton!
    
    
    @IBAction func cancel(sender: AnyObject) {
        self.dismissViewControllerAnimated(true, completion: nil)
    }

    @IBAction func proposeTrade(sender: AnyObject) {
        var tradeProposal = PFObject(className:"TradeProposal")
        tradeProposal["offeringUser"] = PFUser.currentUser()["username"]
        tradeProposal["offeredSquirrelID"] = offeredSquirrel!.objectId
        tradeProposal["receivingUser"] = desiredSquirrelOwner!["username"]
        tradeProposal["proposedSquirrelID"] = desiredSquirrel!.objectId
        
        
       
        tradeProposal.saveInBackgroundWithBlock {
            (success: Bool, error: NSError!) -> Void in
            if (success) {
                var parent = self.parentViewController
                self.dismissViewControllerAnimated(true, completion: nil)
                self.parentViewController?.dismissViewControllerAnimated(true, completion: nil)
                let owner = self.desiredSquirrelOwner!["username"] as String
                let message = "You will be notified if \(owner) accepts your trade."
                let alert = UIAlertController(title: "Trade Offered", message: message, preferredStyle: UIAlertControllerStyle.Alert)
                alert.addAction(UIAlertAction(title: "Ok", style: UIAlertActionStyle.Default, handler: nil))
                self.presentViewController(alert, animated: true, completion: nil)
                
            } else {
                println(error)
            }
        }
    }
    @IBAction func selectSquirrel(sender: AnyObject) {
        self.performSegueWithIdentifier("userSquirrels", sender: self)
    }
    
    override func prepareForSegue(segue: UIStoryboardSegue, sender: AnyObject?) {
        if segue.identifier == "userSquirrels" {
            let controller = segue.destinationViewController as UserSquirrelsPopUpViewController
            controller.desiredSquirrel = desiredSquirrel
            controller.desiredSquirrelOwner = desiredSquirrelOwner
            controller.delegate = self
        }
    }
    
    
    override func viewDidLoad() {
        super.viewDidLoad()
        var firstName = desiredSquirrel!["first_name"] as? String
        var lastName = desiredSquirrel!["last_name"] as? String
        desiredSquirrelLabel.text = "\(firstName!) \(lastName!)"
        
        //Check whether we should be displaying the "choose a squirrel to offer" button
        if offeredSquirrel != nil {
            //The user has already selected a squirrel for trading
            var firstName = offeredSquirrel!["first_name"] as? String
            var lastName = offeredSquirrel!["last_name"] as? String
            offeredSquirrelLabel.text = "\(firstName!) \(lastName!)"
            selectSquirrelButton.hidden = true
        } else {
            //We need to first display the select squirrel button
            offeredSquirrelLabel.hidden = true
            proposeTradeButton.hidden = true
        }
        
    }
    
    //Should be its own extension
    func userSquirrelsPopUpViewControllerDelegate(controller: UserSquirrelsPopUpViewController, selectedSquirrel: PFObject, wantedSquirrelOwner: PFUser, wantedSquirrel: PFObject) {
            //Ghetto way of transfering this info back from previous controller, might be able to get rid of it
            desiredSquirrel = wantedSquirrel
            desiredSquirrelOwner = wantedSquirrelOwner
            offeredSquirrel = selectedSquirrel
        
            var firstName = selectedSquirrel["first_name"] as? String
            var lastName = selectedSquirrel["last_name"] as? String
            offeredSquirrelLabel.text = "\(firstName!) \(lastName!)"
            offeredSquirrelLabel.hidden = false
            proposeTradeButton.hidden = false
            selectSquirrelButton.hidden = true
        
    }

   
}
