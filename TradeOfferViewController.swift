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
        let offeringUsername = tradeProposal!["offeringUsername"] as! String
        let desiredSquirrelName = tradeProposal!["desiredSquirrelName"] as! String
        
        if tradeProposal!["offeredAcorns"] != nil {
            /*
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
            */
            let currentGroupdata  = PFUser.currentUser()!["currentGroupData"] as! PFObject
            currentGroupdata.fetch()
            
            //We need to subtract the offered amount of acorns from the proposer of the trade
            let offeringUserGroupDataQuery = PFQuery(className: "UserGroupData")
            offeringUserGroupDataQuery.whereKey("user", equalTo: tradeProposal!["offeringUser"] as! PFObject)
            offeringUserGroupDataQuery.whereKey("group", equalTo: PFUser.currentUser()!["currentGroup"] as! PFObject)
            let offeringUserGroupData = offeringUserGroupDataQuery.getFirstObject()
            var proposerAcorns = offeringUserGroupData!["acorns"] as! Int
            let offeredAcorns = tradeProposal!["offeredAcorns"] as! Int
            println("proposerAcorns is \(proposerAcorns)")
            let offeredSquirrelID = tradeProposal!["offeredSquirrelID"] as? String
            println("offeredSquirrelID is \(offeredSquirrelID)")
            //We need to run a lot of checks to see if the user still has enough acorns that they offered for the trade
            if proposerAcorns == 0 && offeredSquirrelID == nil {
                //Then the offerer has no acorns and didn't propose a squirrel, so we have to tel the user that the trade is off
                let title = "There's a problem with the trade"
                let offeringUsername = tradeProposal!["offeringUsername"] as! String
                let message = "Unfortunately \(offeringUsername) didn't offer a Squirrel and spent all of his/her acorns, so this trade is off the table :("
                var alert = UIAlertController(title: title, message: message, preferredStyle: UIAlertControllerStyle.Alert)
                alert.addAction(UIAlertAction(title: "OK", style: .Cancel, handler: { (action: UIAlertAction!) in
                    self.tradeProposal!.delete()
                    //Reloading
                    self.delegate?.tradeOfferViewController(self)
                    alert.dismissViewControllerAnimated(true, completion: nil)
                    self.dismissViewControllerAnimated(true, completion: nil)
                }))
                self.presentViewController(alert, animated: true, completion: nil)
                return
            } else if proposerAcorns == 0 && offeredSquirrelID != nil {
                //Then the offerer has no acorns, but we give the user the option to just trade for the offered squirrel
                let title = "There's a problem with the trade"
                let offeringUsername = tradeProposal!["offeringUsername"] as! String
                let message = "Unfortunately \(offeringUsername) spent all of their acorns, but would you like to trade just squirrels?"
                var alert = UIAlertController(title: title, message: message, preferredStyle: UIAlertControllerStyle.Alert)
                alert.addAction(UIAlertAction(title: "No", style: .Cancel, handler: { (action: UIAlertAction!) in
                    self.tradeProposal!.delete()
                    //Reloading
                    self.delegate?.tradeOfferViewController(self)
                    alert.dismissViewControllerAnimated(true, completion: nil)
                    self.dismissViewControllerAnimated(true, completion: nil)
                }))
                alert.addAction(UIAlertAction(title: "Yes", style: .Default, handler: { (action: UIAlertAction!) in
                    self.tradeProposal!.delete()
                    //Reloading
                    self.delegate?.tradeOfferViewController(self)
                    self.swapSquirrelOwners()
                    self.deleteOtherSquirrelOffers()
                    alert.dismissViewControllerAnimated(true, completion: nil)
                    self.dismissViewControllerAnimated(true, completion: nil)
                }))
                self.presentViewController(alert, animated: true, completion: nil)
                return
            } else if proposerAcorns < offeredAcorns && proposerAcorns > 0 {
                //Then the offerer doesn't have as many acorns as they offered, but we can give the user the option to accept less acorns and get the offered squirrel
                let title = "There's a problem with the trade"
                let offeringUsername = tradeProposal!["offeringUsername"] as! String
                var message = "Unforuntately \(offeringUsername) doesn't have \(offeredAcorns) acorns but can offer \(proposerAcorns) acorns instead. Would you still like to trade?"
                if offeredSquirrelID != nil {
                    message = "Unfortunately \(offeringUsername) doesn't have \(offeredAcorns) acorns but can offer \(proposerAcorns) acorns and their squirrel. Would you still like to trade?"
                }
                var alert = UIAlertController(title: title, message: message, preferredStyle: UIAlertControllerStyle.Alert)
                alert.addAction(UIAlertAction(title: "No", style: .Cancel, handler: { (action: UIAlertAction!) in
                    self.tradeProposal!.delete()
                    //Reloading
                    self.delegate?.tradeOfferViewController(self)
                    alert.dismissViewControllerAnimated(true, completion: nil)
                    self.dismissViewControllerAnimated(true, completion: nil)
                    return
                }))
                alert.addAction(UIAlertAction(title: "Yes", style: .Default, handler: { (action: UIAlertAction!) in
                    self.tradeProposal!.delete()
                    //Reloading
                    self.delegate?.tradeOfferViewController(self)
                    var userAcorns = currentGroupdata["acorns"] as! Int
                    userAcorns += proposerAcorns
                    currentGroupdata["acorns"] = userAcorns
                    currentGroupdata.save()
                    offeringUserGroupData!["acorns"] = 0
                    offeringUserGroupData!.save()
                    if offeredSquirrelID != nil {
                        self.swapSquirrelOwners()
                    }
                    self.deleteOtherSquirrelOffers()
                    alert.dismissViewControllerAnimated(true, completion: nil)
                    self.dismissViewControllerAnimated(true, completion: nil)
                }))
                self.presentViewController(alert, animated: true, completion: nil)
                return

            } else {
                //The user has enough acorns for the trade
                proposerAcorns -= offeredAcorns
                var userAcorns = currentGroupdata["acorns"] as! Int
           
                userAcorns += offeredAcorns
                currentGroupdata["acorns"] = userAcorns
                currentGroupdata.save()
                offeringUserGroupData!["acorns"] = proposerAcorns
                offeringUserGroupData!.save()
            }
        
        }
        ///End of acorn checks
        
        if tradeProposal!["offeredSquirrelID"] != nil {
            swapSquirrelOwners()
        }
        
        //Alert the offering user that their proposal has been accepted
        let pushQuery = PFInstallation.query()
        pushQuery!.whereKey("username", equalTo: offeringUsername)
        let push = PFPush()
        push.setQuery(pushQuery)
        let message = "\(PFUser.currentUser()!.username!) has accepted your offer for \(desiredSquirrelName)"
        let inviteMessage = message as NSString
        let pushDict = ["alert": inviteMessage, "badge":"increment", "sounds":"", "content-available": 1]
        push.setData(pushDict)
        push.sendPushInBackgroundWithBlock(nil)
        
        
        tradeProposal!.delete()
        
        deleteOtherSquirrelOffers()
    
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
    
    //Deletes all other proposals where the desired squirrel is your squirrel (since owners have changed) and potentially deleted trades where offered squirrel (if there is one) is offered (since that squirrels owners have also changed)
    func deleteOtherSquirrelOffers() {
        //Need to delete all other proposals where the desired squirrel is yourSquirrel (since the owners have changed)
        let query1 = PFQuery(className: "TradeProposal")
        query1.whereKey("proposedSquirrelID", equalTo: yourSquirrel!.objectId!)
        
        var queries: [PFQuery] = [query1]
        
        if tradeProposal!["offeredSquirrelID"] != nil {
            //The other user offered a squirrel in this trade, and we need to delete all TradePropsal instances where this squirrel was offered (since that user will no longer own it)
            let query2 = PFQuery(className: "TradeProposal")
            query2.whereKey("offeredSquirrelID", equalTo: tradeProposal!["offeredSquirrelID"] as! String)
            queries.append(query2)
        }
        let query = PFQuery.orQueryWithSubqueries(queries)
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
    }
    
    
     //Removes the user's rating from the squirrel's "ratings" field and returns the new array 
    func removeRating(squirrel: PFObject, user: String) -> [String] {
        var index = find(squirrel["raters"] as! [String], user)
        var ratings = squirrel["ratings"] as! [String]
        ratings.removeAtIndex(index!)
        return ratings
    }
    
    
    func swapSquirrelOwners() {
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
        
        yourSquirrel!["owner"] = tradeProposal!["offeringUser"]
        yourSquirrel!["ownerUsername"] = tradeProposal!["offeringUsername"]
        yourSquirrel!.save()
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
            //Then the offerer is offering a Squirrel
            var offeredSquirrelQuery = PFQuery(className: "Squirrel")
            offeredSquirrelQuery.whereKey("objectId", equalTo: tradeProposal!["offeredSquirrelID"]!)
            offeredSquirrel = offeredSquirrelQuery.getFirstObject()
            var offeredFirstName = offeredSquirrel!["first_name"] as? String
            var offeredLastName = offeredSquirrel!["last_name"] as? String
            offeredlLabel.text = "\(offeredFirstName!) \(offeredLastName!)"
        }
        
        if tradeProposal!["offeredAcorns"] != nil {
            var acorns = tradeProposal!["offeredAcorns"] as! Int
            if tradeProposal!["offeredSquirrelID"] == nil {
                offeredlLabel.text = "\(acorns) acorns"
                offeredAcornsLabel.hidden = true
            } else {
                offeredAcornsLabel.text = "\(acorns) acorns and"
            }
        } else {
            offeredAcornsLabel.hidden = true
        }
    }


}
