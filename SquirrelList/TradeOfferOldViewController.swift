//
//  TradeOfferViewController.swift
//  SquirrelList
//
//  Created by Denis Geary Lopez on 3/17/15.
//  Copyright (c) 2015 Frenvu Inc. All rights reserved.
//

/*
import UIKit


//This view controller is for trades that have already been proposed to the user. Not for trade that the user will create to propose to other users

//Need to change it to a popupViewController


protocol TradeOfferViewControllerDelegate: class {
    func tradeOfferViewController(controller: TradeOfferViewController)
}


class TradeOfferOldViewController: UIViewController {

    var delegate: TradeOfferViewControllerDelegate?
    
    var offeredSquirrel: PFObject?

    var tradeProposal: PFObject?
    
    var yourSquirrel: PFObject?
    
    
    

    @IBOutlet weak var offeredSquirrelLabel: UILabel!

    @IBOutlet weak var yourSquirrelLabel: UILabel!
    
    
    @IBAction func acceptTrade(sender: AnyObject) {
        
        offeredSquirrel!["owner"] = PFUser.currentUser()["username"]
        
        yourSquirrel!["owner"] = tradeProposal!["offeringUser"]
        
        offeredSquirrel!.save()
        yourSquirrel!.save()
    
        tradeProposal!.deleteInBackground()
        delegate?.tradeOfferViewController(self)
        self.navigationController?.popViewControllerAnimated(true)
    
    }
    
    
    @IBAction func declineTrade(sender: AnyObject) {
        tradeProposal!.deleteInBackground()
        dismissViewControllerAnimated(true, completion: nil)
        delegate?.tradeOfferViewController(self)
    }
    
    override func viewDidLoad() {
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
        //yourSquirrelLabel.adjustsFontSizeToFitWidth
    
        
        super.viewDidLoad()

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

*/
