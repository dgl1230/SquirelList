//
//  TradeViewController.swift
//  SquirrelList
//
//  Created by Denis Geary Lopez on 3/13/15.
//  Copyright (c) 2015 Frenvu Inc. All rights reserved.
//

import UIKit

//This view controller is for proposing trades to other users

class TradeViewController: UIViewController, SquirrelsForTradeDelegate {

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
                self.dismissViewControllerAnimated(true, completion: nil)
                
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
            //let navigationController = segue.destinationViewController as UINavigationController
            let controller = segue.destinationViewController as SquirrelsForTradingViewController
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
    func SquirrelForTradeDelegate(controller: SquirrelsForTradingViewController, selectedSquirrel: PFObject, desiredSquirrelOwnerTransfer: PFUser, desiredSquirrelTransfer: PFObject) {
            println("delegate working")
            //Ghetto way of transfering this info back from previous controller, might be able to get rid of it
            desiredSquirrel = desiredSquirrelTransfer
            desiredSquirrelOwner = desiredSquirrelOwnerTransfer
            offeredSquirrel = selectedSquirrel
        
            var firstName = selectedSquirrel["first_name"] as? String
            var lastName = selectedSquirrel["last_name"] as? String
            offeredSquirrelLabel.text = "\(firstName!) \(lastName!)"
            offeredSquirrelLabel.hidden = false
            proposeTradeButton.hidden = false
            selectSquirrelButton.hidden = true
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
