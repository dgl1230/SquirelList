//
//  TradeOfferNewViewController.swift
//  SquirrelList
//
//  Created by Denis Geary Lopez on 3/25/15.
//  Copyright (c) 2015 Frenvu Inc. All rights reserved.
//

//This view controller is for individual trades that have already been proposed to the user. Not for trades that the user will create to propose to other users. This view controller displays an individual trade that the user either accepts or declines.

import UIKit

protocol TradeOfferViewControllerDelegate: class {
    func tradeOfferViewController(controller: TradeOfferViewController)
}

class TradeOfferViewController: PopUpViewController {

    var delegate: TradeOfferViewControllerDelegate?
    var offeredSquirrel: PFObject?
    var tradeProposal: PFObject?
    var yourSquirrel: PFObject?
    
    @IBOutlet weak var offeredlLabel: UILabel!
    @IBOutlet weak var yourSquirrelLabel: UILabel!
    
    
    @IBAction func acceptTrade(sender: AnyObject) {
        offeredSquirrel!["owner"] = PFUser.currentUser()!
        yourSquirrel!["owner"] = tradeProposal!["offeringUser"]

        offeredSquirrel!.save()
        yourSquirrel!.save()
    
        tradeProposal!.deleteInBackground()
        dismissViewControllerAnimated(true, completion: nil)
        delegate?.tradeOfferViewController(self)
    }
    
    
    @IBAction func declineTrade(sender: AnyObject) {
        tradeProposal!.deleteInBackground()
        dismissViewControllerAnimated(true, completion: nil)
        delegate?.tradeOfferViewController(self)
    }
    

    override func viewDidLoad() {
        super.viewDidLoad()
        
        var offeredSquirrelQuery = PFQuery(className: "Squirrel")
        offeredSquirrelQuery.whereKey("objectId", equalTo: tradeProposal!["offeredSquirrelID"]!)
        offeredSquirrel = offeredSquirrelQuery.getFirstObject()
        
        var offeredFirstName = offeredSquirrel!["first_name"] as? String
        var offeredLastName = offeredSquirrel!["last_name"] as? String
        offeredlLabel.text = "\(offeredFirstName!) \(offeredLastName!)"
        
        
        var yourSquirrelQuery = PFQuery(className: "Squirrel")
        yourSquirrelQuery.whereKey("objectId", equalTo: tradeProposal!["proposedSquirrelID"]!)
        yourSquirrel = yourSquirrelQuery.getFirstObject()
        
        var yourFirstName = yourSquirrel!["first_name"] as? String
        var yourLastName = yourSquirrel!["last_name"] as? String
        yourSquirrelLabel.text = "\(yourFirstName!) \(yourLastName!)"
    }


}
