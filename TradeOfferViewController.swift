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
            var offeredAcorns = tradeProposal!["offeredAcorns"] as! Int
            var currentGroup = PFUser.currentUser()!["currentGroup"] as! PFObject

            var proposerAcorns = getUserInfo(currentGroup["acorns"] as! [String], tradeProposal!["offeringUsername"] as! String).toInt()
            let offeredSquirrelID = tradeProposal!["offeredSquirrelID"] as? String
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
                    self.changeOwners()
                    self.finishTrade()
                    alert.dismissViewControllerAnimated(true, completion: nil)
                    self.dismissViewControllerAnimated(true, completion: nil)
                }))
                self.presentViewController(alert, animated: true, completion: nil)
                return
            } else if proposerAcorns < offeredAcorns && proposerAcorns > 0 {
                //Then the offerer doesn't have as many acorns as they offered, but we can give the user the option to accept less acorns and get the offered squirrel
                let title = "There's a problem with the trade"
                let offeringUsername = tradeProposal!["offeringUsername"] as! String
                var message = "Unforuntately \(offeringUsername) doesn't have \(offeredAcorns) acorns but can offer \(proposerAcorns!) acorns instead. Would you still like to trade?"
                if offeredSquirrelID != nil {
                    message = "Unfortunately \(offeringUsername) doesn't have \(offeredAcorns) acorns but can offer \(proposerAcorns!) acorns and their squirrel. Would you still like to trade?"
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
                    //Reloading
                    self.delegate?.tradeOfferViewController(self)
                    var newProposerAcorns = "0"
                    var newUserAcorns = getNewArrayToSave(currentGroup["acorns"] as! [String], offeringUsername, newProposerAcorns)
                    var userAcorns2 = getUserInfo(newUserAcorns, PFUser.currentUser()!.username!).toInt()
                    userAcorns2! += proposerAcorns!
                    self.changeOwners()
                    self.tradeProposal!.deleteInBackgroundWithBlock({ (didDelete: Bool, error: NSError?) -> Void in
                        if error == nil {
                            self.finishTrade()
                            let newAcorns = getNewArrayToSave(newUserAcorns, PFUser.currentUser()!.username!, String(userAcorns2!))
                            currentGroup["acorns"] = newAcorns
                            currentGroup.save()
                            //Reloading
                            self.delegate?.tradeOfferViewController(self)
                            alert.dismissViewControllerAnimated(true, completion: nil)
                            self.dismissViewControllerAnimated(true, completion: nil)
    
                        } else {
                            //There was an error and we should alert them using the global function
                            displayAlert(self, "Oops", "There's been a problem. Would you mind trying again?")
                        }
                    })
                }))
                self.presentViewController(alert, animated: true, completion: nil)
                return

            } else {
                //The user has enough acorns for the trade
                //Need to subtract acorns from the offerer and add them to the logged in user
                proposerAcorns! -= offeredAcorns
                var newAcorns = getNewArrayToSave(currentGroup["acorns"] as! [String], offeringUsername, String(proposerAcorns!))
                
                var userAcorns = getUserInfo(newAcorns, PFUser.currentUser()!.username!).toInt()
           
                userAcorns! += offeredAcorns
                let newAcorns2 = getNewArrayToSave(newAcorns, PFUser.currentUser()!.username!, String(userAcorns!))
                currentGroup["acorns"] = newAcorns2
                currentGroup.save()
            }
        
        }
        
        ///End of acorn checks
        changeOwners()
        finishTrade()
    }
    
    
    @IBAction func declineTrade(sender: AnyObject) {
        tradeProposal!.deleteInBackground()
        dismissViewControllerAnimated(true, completion: nil)
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
                var usernames: [String] = []
                var tradeOffers = trades as? [PFObject]
                if tradeOffers?.count >= 1 {
                    for trade in tradeOffers! {
                        let object = trade as PFObject
                        let username = object["offeringUsername"] as! String
                        usernames.append(username)
                        trade.delete()
                    }
                }
                //Send notifications to all users that had their trade offers rejected
                let yourSquirrelFirstName = self.yourSquirrel!["first_name"] as! String
                let yourSquirrelLastName = self.yourSquirrel!["last_name"] as! String
                let yourSquirrelName = "\(yourSquirrelFirstName) \(yourSquirrelLastName)"
                let pushQuery = PFInstallation.query()
                pushQuery!.whereKey("username", containedIn: usernames)
                let push = PFPush()
                push.setQuery(pushQuery)
                let message = "\(PFUser.currentUser()!.username!) has rejected your offer for \(yourSquirrelName)"
                let NSMessage = message as NSString
                let pushDict = ["alert": NSMessage, "badge":0, "sounds":"", "content-available": 1]
                push.setData(pushDict)
                push.sendPushInBackgroundWithBlock(nil)
                self.dismissViewControllerAnimated(true, completion: nil)
                //Reloading
                self.delegate?.tradeOfferViewController(self)
            }
        }
    }
    
    //Finishes the trade
    func finishTrade() {
        let offeringUsername = tradeProposal!["offeringUsername"] as! String
        let desiredSquirrelName = tradeProposal!["desiredSquirrelName"] as! String
        tradeProposal!.deleteInBackgroundWithBlock { (didDelete: Bool, error: NSError?) -> Void in
            if error == nil {
                if self.tradeProposal!["offeredSquirrelID"] != nil {
                    self.changeOwners()
                }
                self.yourSquirrel?.save()
                self.offeredSquirrel?.save()
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
                
                self.tradeProposal!.delete()
                self.deleteOtherSquirrelOffers()
                //Reload the updated trades
                self.delegate?.tradeOfferViewController(self)
            } else {
            
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
    
    
    func changeOwners() {
        let offeringUser = tradeProposal!["offeringUsername"] as! String
        //Check to see if the user is offering a squirrel
        let offeredSquirrelID = tradeProposal!["offeredSquirrelID"] as? String
        if offeredSquirrelID != nil {
            //A squirrel was offered for your squirrel, so we need to update its date
            let offeredSquirrelRaters = offeredSquirrel!["raters"] as! [String]
            if find(offeredSquirrelRaters, PFUser.currentUser()!.username!) != nil{
                //Then the logged in user has rated the offered squirrel, and we need to remove their rating and remove them from raters
                let offeredRatings = removeRating(offeredSquirrel!, user: PFUser.currentUser()!.username!)
                offeredSquirrel!["ratings"] = offeredRatings
                offeredSquirrel!.removeObject(PFUser.currentUser()!.username!, forKey: "raters")
                offeredSquirrel!["avg_rating"] = calculateAverageRating(offeredRatings)
            }
            offeredSquirrel!["owner"] = PFUser.currentUser()!
            offeredSquirrel!["ownerUsername"] = PFUser.currentUser()!.username
            offeredSquirrel!.save()
        }
        let yourSquirrelRaters = yourSquirrel!["raters"] as! [String]
        if find(yourSquirrelRaters, offeringUser) != nil {
            //Then the offering user has rated your squirrel, and we need to remove their rating and remove them from the raters
            let yourRatings = removeRating(yourSquirrel!, user: offeringUser)
            yourSquirrel!["ratings"] = yourRatings
            yourSquirrel!.removeObject(offeringUser, forKey: "raters")
            yourSquirrel!["avg_rating"] = calculateAverageRating(yourRatings)
        }
        
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
