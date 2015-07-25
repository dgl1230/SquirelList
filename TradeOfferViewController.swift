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
    
    @IBOutlet weak var acceptButton: UIButton!
    @IBOutlet weak var declineButton: UIButton!
    @IBOutlet weak var offeredlLabel: UILabel!
    @IBOutlet weak var yourSquirrelLabel: UILabel!
    @IBOutlet weak var offeredAcornsLabel: UILabel!
    
    
    @IBAction func acceptTrade(sender: AnyObject) {
        //Finish implementing remove ratings later
        if tradeProposal!["offeredSquirrelID"] != nil {
            //Check to see if the user is offering a squirrel
            let offeredUsername = offeredSquirrel!["ownerUsername"] as! String
            //First we need to check if either user has rated the squirrel that they'll be receiving, and if they have, we need to remove their rating
            let offeredSquirrelRaters = offeredSquirrel!["raters"] as! [String]
            let yourSquirrelRaters = yourSquirrel!["raters"] as! [String]
            if find(offeredSquirrelRaters, PFUser.currentUser()!.username!) != nil{
                //Then the logged in user has rated the offered squirrel, and we need to remove their rating and remove them from raters
                let offeredRatings = removeRating(offeredSquirrel!, user: PFUser.currentUser()!.username!)
                offeredSquirrel!["ratings"] = offeredRatings
                offeredSquirrel!.removeObject(PFUser.currentUser()!.username!, forKey: "raters")
                offeredSquirrel!["avg_rating"] = calculateAverageRating(offeredRatings)
            
            }
            if find(yourSquirrelRaters, offeredUsername) != nil {
                //Then the offering user has rated your squirrel, and we need to remove their rating and remove them from the raters
                let yourRatings = removeRating(yourSquirrel!, user: offeredUsername)
                yourSquirrel!["ratings"] = yourRatings
                yourSquirrel!.removeObject(offeredUsername, forKey: "raters")
                yourSquirrel!["avg_rating"] = calculateAverageRating(yourRatings)
            }
            offeredSquirrel!["owner"] = PFUser.currentUser()!
            offeredSquirrel!["ownerUsername"] = PFUser.currentUser()!.username
            offeredSquirrel!.save()
        }
        
        if tradeProposal!["offeredAcorns"] != nil {
            let currentGroupdata  = PFUser.currentUser()!["currentGroupData"] as! PFObject
            currentGroupdata.fetch()
            var acorns = currentGroupdata["acorns"] as! Int
            let offeredAcorns = tradeProposal!["offeredAcorns"] as! Int
            acorns += offeredAcorns
            currentGroupdata["acorns"] = acorns
            currentGroupdata.save()
            //We need to subtract the offered amount of acorns from the proposer of the trade
            let offeringUserGroupDataQuery = PFQuery(className: "UserGroupData")
            offeringUserGroupDataQuery.whereKey("user", equalTo: tradeProposal!["offeringUser"] as! PFObject)
            offeringUserGroupDataQuery.whereKey("group", equalTo: PFUser.currentUser()!["currentGroup"] as! PFObject)
            let offeringUserGroupData = offeringUserGroupDataQuery.getFirstObject()
            var proposerAcorns = offeringUserGroupData!["acorns"] as! Int
            proposerAcorns -= offeredAcorns
            offeringUserGroupData!["acorns"] = proposerAcorns
            offeringUserGroupData!.save()
            
        }

        yourSquirrel!["owner"] = tradeProposal!["offeringUser"]
        yourSquirrel!["ownerUsername"] = tradeProposal!["offeringUsername"]
        yourSquirrel!.save()
        
        //Alert the offering user that their proposal has been accepted
        let pushQuery = PFInstallation.query()
        let offeringUsername = tradeProposal!["offeringUsername"] as! String
        let desiredSquirrelName = tradeProposal!["desiredSquirrelName"] as! String
        pushQuery!.whereKey("userID", equalTo: offeringUsername)
        let push = PFPush()
        push.setQuery(pushQuery)
        let message = "\(PFUser.currentUser()!.username!) has accepted your offer for \(desiredSquirrelName)!"
        let inviteMessage = message as NSString
        let pushDict = ["alert": inviteMessage, "badge":"increment", "sounds":"", "content-available": 1]
        push.setData(pushDict)
        push.sendPushInBackgroundWithBlock(nil)
        
        
        tradeProposal!.delete()
        
        //Need to delete all other proposals where the desired squirrel is yourSquirrel (since the owners have changed)
        var query = PFQuery(className: "TradeProposal")
        //This line is redundant, I thinks
        //query.whereKey("receivingUsername", equalTo: PFUser.currentUser()!.username!)
        query.whereKey("proposedSquirrelID", equalTo: yourSquirrel!.objectId!)
        query.findObjectsInBackgroundWithBlock { (trades: [AnyObject]?, error: NSError?) -> Void in
            if error == nil {
                var tradeOffers = trades as? [PFObject]
                if tradeOffers?.count >= 1 {
                    for trade in tradeOffers! {
                        trade.delete()
                    }
                }
            }
        }
        dismissViewControllerAnimated(true, completion: nil)
        //Reloading
        delegate?.tradeOfferViewController(self)
    }
    
    
    @IBAction func declineTrade(sender: AnyObject) {
        tradeProposal!.deleteInBackground()
        dismissViewControllerAnimated(true, completion: nil)
        delegate?.tradeOfferViewController(self)
    }
    
    func calculateAverageRating(ratings:[String]) -> Double {
        var numOfRatings = ratings.count
        if numOfRatings == 0 {
            return 0
        }
        var sum = 0.0

        for rating in ratings {
            var rating1 = rating as NSString
            sum += rating1.doubleValue
        }
        var unroundedRating = Double(sum)/Double(numOfRatings)
        return round((10 * unroundedRating)) / 10
    }
    
    
     //Removes the user's rating from the squirrel's "ratings" field and returns the new array 
    func removeRating(squirrel: PFObject, user: String) -> [String] {
        var index = find(squirrel["raters"] as! [String], user)
        var ratings = squirrel["ratings"] as! [String]
        ratings.removeAtIndex(index!)
        return ratings
    }
    

    override func viewDidLoad() {
        super.viewDidLoad()
        
        var yourSquirrelQuery = PFQuery(className: "Squirrel")
        yourSquirrelQuery.whereKey("objectId", equalTo: tradeProposal!["proposedSquirrelID"]!)
        yourSquirrel = yourSquirrelQuery.getFirstObject()
        
        var yourFirstName = yourSquirrel!["first_name"] as? String
        var yourLastName = yourSquirrel!["last_name"] as? String
        yourSquirrelLabel.text = "\(yourFirstName!) \(yourLastName!)"
        //Give buttons rounded edges
        acceptButton.layer.cornerRadius = 5
        acceptButton.layer.masksToBounds = true
        declineButton.layer.cornerRadius = 5
        declineButton.layer.masksToBounds = true

        if tradeProposal!["offeredSquirrelID"] != nil {
            println("pass1")
            //Then the offerer is offering a Squirrel
            var offeredSquirrelQuery = PFQuery(className: "Squirrel")
            offeredSquirrelQuery.whereKey("objectId", equalTo: tradeProposal!["offeredSquirrelID"]!)
            offeredSquirrel = offeredSquirrelQuery.getFirstObject()
            var offeredFirstName = offeredSquirrel!["first_name"] as? String
            var offeredLastName = offeredSquirrel!["last_name"] as? String
            offeredlLabel.text = "\(offeredFirstName!) \(offeredLastName!)"
        }
        
        if tradeProposal!["offeredAcorns"] != nil {
            println("pass3")
            var acorns = tradeProposal!["offeredAcorns"] as! Int
            if tradeProposal!["offeredSquirrelID"] == nil {
                println("pass4")
                offeredlLabel.text = "\(acorns) acorns"
                offeredAcornsLabel.hidden = true
            } else {
                println("pass5")
                offeredAcornsLabel.text = "\(acorns) acorns +"
            }
        } else {
            offeredAcornsLabel.hidden = true
        }
    }


}
