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
    //For keeping track of which trades to delete that involve the same squirrel - if user accepts a trade
    var trades: [PFObject] = []
    
    @IBOutlet weak var acceptButton: UIButton!
    @IBOutlet weak var declineButton: UIButton!
    @IBOutlet weak var offeredlLabel: UILabel!
    @IBOutlet weak var yourSquirrelLabel: UILabel!
    @IBOutlet weak var offeredAcornsLabel: UILabel!
    
    
    @IBAction func acceptTrade(sender: AnyObject) {
        //Global function that starts the loading animation and returns an array of [NVAcitivtyIndicatorView, UIView, UIView] so that we can pass these views into resumeInterActionEvents() later to suspend animation and dismiss the views
        let viewsArray = displayLoadingAnimator(self.view)
        let activityIndicatorView = viewsArray[0] as! NVActivityIndicatorView
        let container = viewsArray[1] as! UIView
        let loadingView = viewsArray[2] as! UIView
        dispatch_async(dispatch_get_main_queue()) {
            self.startAcceptingTrade(activityIndicatorView, container: container, loadingView: loadingView)
        }
    }
    
    
    @IBAction func declineTrade(sender: AnyObject) {
        tradeProposal!.deleteInBackground()
        let priority = DISPATCH_QUEUE_PRIORITY_DEFAULT
        dispatch_async(dispatch_get_global_queue(priority, 0)) {
            //Send push notification alerting them that their trade has been rejected
            let offeringUsername = self.tradeProposal!["offeringUsername"] as! String
            let yourSquirrelName = self.tradeProposal!["desiredSquirrelName"] as! String
            let message = "\(PFUser.currentUser()!.username!) has rejected your offer for \(yourSquirrelName)"
            sendPushNotifications(0, message: message, type: "rejectedTrade", users: [offeringUsername])
        }
        
        dismissViewControllerAnimated(true, completion: nil)
        //Reloading
        self.delegate?.tradeOfferViewController(self)
    }
    
    func calculateAverageRating(ratings:[String]) -> Double {
        let numOfRatings = ratings.count
        if numOfRatings == 0 {
            return 0
        }
        var sum = 0.0

        for rating in ratings {
            let rating1 = rating as NSString
            sum += rating1.doubleValue
        }
        let unroundedRating = Double(sum)/Double(numOfRatings)
        return round((10 * unroundedRating)) / 10
    }
    
    /*
    //Deletes all other proposals where the desired squirrel is your squirrel (since owners have changed) and potentially deleted trades where offered squirrel (if there is one) is offered (since that squirrels owners have also changed). 
    // Parameters: the offerer's username, because at this point the tradeProposal optional will have already been deleted
    func deleteOtherSquirrelOffers(offeringUsername: String) {
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
        //let offerer = tradeProposal
        let query = PFQuery.orQueryWithSubqueries(queries)
        query.findObjectsInBackgroundWithBlock { (trades: [AnyObject]?, error: NSError?) -> Void in
            if error == nil {
                var usernames: [String] = []
                let tradeOffers = trades as? [PFObject]
                if tradeOffers?.count >= 1 {
                    for trade in tradeOffers! {
                        let object = trade as PFObject
                        let username = object["offeringUsername"] as! String
                        if username != offeringUsername {
                            //If the offerer who had their trade approved also had multiple offers, we just want to send an approval alert, not a rejection alert too
                            usernames.append(username)
                        }
                        trade.delete()
                    }
                }
                //Send notifications to all users that had their trade offers rejected
                let yourSquirrelFirstName = self.yourSquirrel!["first_name"] as! String
                let yourSquirrelLastName = self.yourSquirrel!["last_name"] as! String
                let yourSquirrelName = "\(yourSquirrelFirstName) \(yourSquirrelLastName)"
                let message = "\(PFUser.currentUser()!.username!) has rejected your offer for \(yourSquirrelName)"
                sendPushNotifications(0, message: message, type: "rejectedTrade", users: usernames)
                self.dismissViewControllerAnimated(true, completion: nil)
                //Reloading
                self.delegate?.tradeOfferViewController(self)
            }
        }
    }
    */
    
    func deleteTradeOffers() {
        let yourSquirrelName = tradeProposal!["desiredSquirrelName"] as! String
        for trade in trades {
            let desiredSquirrelName = trade["desiredSquirrelName"] as! String
            if yourSquirrelName == desiredSquirrelName {
                trade.deleteInBackground()
            }
        }

    
    }
    
    //Finishes the trade
    func finishTrade() {
        let offeringUsername = tradeProposal!["offeringUsername"] as! String
        let desiredSquirrelName = tradeProposal!["desiredSquirrelName"] as! String
        if self.tradeProposal!["offeredSquirrelID"] != nil {
            self.changeOwners()
        }
        self.yourSquirrel?.save()
        self.offeredSquirrel?.save()
        //Alert the offering user that their proposal has been accepted
        let message = "\(PFUser.currentUser()!.username!) has accepted your offer for \(desiredSquirrelName)"
        sendPushNotifications(0, message: message, type: "acceptedTrade", users: [offeringUsername])
        self.tradeProposal!.delete()
        //self.deleteOtherSquirrelOffers(offeringUsername)
        self.deleteTradeOffers()
        
        //Reload the updated trades
        self.delegate?.tradeOfferViewController(self)
        //Alert the Squirrel Tab to reload
        NSNotificationCenter.defaultCenter().postNotificationName(reloadSquirrels, object: self)
    /*
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
                let message = "\(PFUser.currentUser()!.username!) has accepted your offer for \(desiredSquirrelName)"
                sendPushNotifications(0, message: message, type: "acceptedTrade", users: [offeringUsername])
                self.tradeProposal!.delete()
                //self.deleteOtherSquirrelOffers(offeringUsername)
                self.deleteTradeOffers()
                //Reload the updated trades
                self.delegate?.tradeOfferViewController(self)
                //Alert the Squirrel Tab to reload
                NSNotificationCenter.defaultCenter().postNotificationName(reloadSquirrels, object: self)
            } else {
            
            }
        }
        */
    }
    
     //Removes the user's rating from the squirrel's "ratings" field and returns the new array
    func removeRating(squirrel: PFObject, user: String) -> [String] {
        let index = (squirrel["raters"] as! [String]).indexOf(user)
        var ratings = squirrel["ratings"] as! [String]
        ratings.removeAtIndex(index!)
        return ratings
    }
    
    
    func changeOwners() {
        let offeringUser = tradeProposal!["offeringUsername"] as! String
        //Check to see if the user is offering a squirrel
        let offeredSquirrelID = tradeProposal!["offeredSquirrelID"] as? String
        if offeredSquirrelID != nil {
            //A squirrel was offered for your squirrel, so we need to update its owner/ratings
            let offeredSquirrelRaters = offeredSquirrel!["raters"] as! [String]
            if offeredSquirrelRaters.indexOf((PFUser.currentUser()!.username!)) != nil{
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
        if yourSquirrelRaters.indexOf(offeringUser) != nil {
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
    
    //If the proposer has offered only acorns, then we need to take away a squirrel slot from them and give the logged in user a squirrel slot
    func newSquirrelSlots(group: PFObject) -> [String] {
        var proposerSquirrelSlots = Int(getUserInfo(group["squirrelSlots"] as! [String], username: tradeProposal!["offeringUsername"] as! String))
        //var yourSquirrelSlots = getUserInfo(group["squirrelSlots"] as! [String], PFUser.currentUser()!.username!).toInt()
        proposerSquirrelSlots! -= 1
        //yourSquirrelSlots! += 1
        LOGGED_IN_USER_SQUIRREL_SLOTS += 1
        let newSquirrelSlots1 = getNewArrayToSave(group["squirrelSlots"] as! [String], username: tradeProposal!["offeringUsername"] as! String, newInfo: String(proposerSquirrelSlots!))
        let newSquirrelSlots2 = getNewArrayToSave(newSquirrelSlots1, username: PFUser.currentUser()!.username!, newInfo: String(LOGGED_IN_USER_SQUIRREL_SLOTS))
        return newSquirrelSlots2
    }
    
    
    //All of this is in a function so that it's easier to put in as a block to be run asychonously (which lets us show a loading animation)
    func startAcceptingTrade(activityIndicatorView: NVActivityIndicatorView, container: UIView, loadingView: UIView) {
        //Finish implementing remove ratings later
        let offeringUsername = tradeProposal!["offeringUsername"] as! String
        let desiredSquirrelName = tradeProposal!["desiredSquirrelName"] as! String
        
        let offeredSquirrelPointer = tradeProposal!["offeredSquirrel"] as? PFObject
        if offeredSquirrelPointer != nil {
            //Odds are this is not the case, but if a squirrel was offered, we need to make sure that the owner didn't leave the group or drop said offered squirrel recently. If they did, then the trade is off
            offeredSquirrelPointer!.fetch()
            let owner = offeredSquirrelPointer!["ownerUsername"] as? String
            if owner == nil || owner != offeringUsername {
                //Global function that stops the loading animation and dismisses the views it is attached to
                resumeInteractionEvents(activityIndicatorView, container: container, loadingView: loadingView)
                //Then the squirrel being offered recently got a different owner or is ownerless, and the trade is off
                let title = "There's a problem with the trade"
                let offeringUsername = tradeProposal!["offeringUsername"] as! String
                let message = "Unfortunately \(offeringUsername) doesn't have ownership over this squirrel anymore. They must have dropped this squirrel or group very recently :("
                let alert = UIAlertController(title: title, message: message, preferredStyle: UIAlertControllerStyle.Alert)
                alert.addAction(UIAlertAction(title: "OK", style: .Cancel, handler: { (action: UIAlertAction) in
                    self.tradeProposal!.delete()
                    alert.dismissViewControllerAnimated(true, completion: nil)
                    self.dismissViewControllerAnimated(true, completion: nil)
                    //Reload
                    self.delegate!.tradeOfferViewController(self)
                }))
                self.presentViewController(alert, animated: true, completion: nil)
                return
            }
    
        }
        
        if tradeProposal!["offeredAcorns"] != nil {
            let offeredAcorns = tradeProposal!["offeredAcorns"] as! Int
            let currentGroup = PFUser.currentUser()!["currentGroup"] as! PFObject
            currentGroup.fetch()
            
            let proposerSquirrelSlots = Int(getUserInfo(currentGroup["squirrelSlots"] as! [String], username: offeringUsername))
            var proposerAcorns = Int(getUserInfo(currentGroup["acorns"] as! [String], username: tradeProposal!["offeringUsername"] as! String))
            let offeredSquirrelID = tradeProposal!["offeredSquirrelID"] as? String
            //We need to run a lot of checks to see if the user still has enough acorns that they offered for the trade
            if proposerAcorns == 0 && offeredSquirrelID == nil {
                //Global function that stops the loading animation and dismisses the views it is attached to
                resumeInteractionEvents(activityIndicatorView, container: container, loadingView: loadingView)
                //Then the offerer has no acorns and didn't propose a squirrel, so we have to tel the user that the trade is off
                let title = "There's a problem with the trade"
                let offeringUsername = tradeProposal!["offeringUsername"] as! String
                let message = "Unfortunately \(offeringUsername) didn't offer a Squirrel and spent all of his/her acorns, so this trade is off the table :("
                let alert = UIAlertController(title: title, message: message, preferredStyle: UIAlertControllerStyle.Alert)
                alert.addAction(UIAlertAction(title: "OK", style: .Cancel, handler: { (action: UIAlertAction) in
                    self.tradeProposal!.delete()
                    //Send alert that proposer's trade was deleted
                    let rejection = "\(PFUser.currentUser()!.username!) has rejected your offer for \(desiredSquirrelName)"
                    sendPushNotifications(0, message: rejection, type: "rejectedTrade", users: [offeringUsername])
                    alert.dismissViewControllerAnimated(true, completion: nil)
                    self.dismissViewControllerAnimated(true, completion: nil)
                    //Reload
                    self.delegate!.tradeOfferViewController(self)
                }))
                self.presentViewController(alert, animated: true, completion: nil)
                return
            }
            
            else if (proposerAcorns! > 0) && (proposerSquirrelSlots == 0) && (offeredSquirrelID == nil) {
                //The user cant accept this trade because the offerer has no squirrel slots to give up (to balance the trade)
                //Global function that stops the loading animation and dismisses the views it is attached to
                resumeInteractionEvents(activityIndicatorView, container: container, loadingView: loadingView)
                let title = "There's a problem with the trade"
                let offeringUsername = tradeProposal!["offeringUsername"] as! String
                let message = "Unfortunately \(offeringUsername) doesn't have any Squirrel Slots to give up (since he's the only one getting a Squirrel), so this trade is off the table :("
                let alert = UIAlertController(title: title, message: message, preferredStyle: UIAlertControllerStyle.Alert)
                alert.addAction(UIAlertAction(title: "OK", style: .Cancel, handler: { (action: UIAlertAction) in
                    self.tradeProposal!.delete()
                    //Send alert that proposer's trade was deleted
                    let rejection = "\(PFUser.currentUser()!.username!) has rejected your offer for \(desiredSquirrelName)"
                    sendPushNotifications(0, message: rejection, type: "rejectedTrade", users: [offeringUsername])
                    alert.dismissViewControllerAnimated(true, completion: nil)
                    self.dismissViewControllerAnimated(true, completion: nil)
                    //Reload
                    self.delegate!.tradeOfferViewController(self)
                }))
                self.presentViewController(alert, animated: true, completion: nil)
                return
            }

            else if proposerAcorns == 0 && offeredSquirrelID != nil {
                //Then the offerer has no acorns, but we give the user the option to just trade for the offered squirrel
                let title = "There's a problem with the trade"
                let offeringUsername = tradeProposal!["offeringUsername"] as! String
                let message = "Unfortunately \(offeringUsername) spent all of their acorns, but would you like to trade just squirrels?"
                //Global function that stops the loading animation and dismisses the views it is attached to
                resumeInteractionEvents(activityIndicatorView, container: container, loadingView: loadingView)
                let alert = UIAlertController(title: title, message: message, preferredStyle: UIAlertControllerStyle.Alert)
                alert.addAction(UIAlertAction(title: "No", style: .Cancel, handler: { (action: UIAlertAction) in
                    self.tradeProposal!.delete()
                    //Send alert that proposer's trade was deleted
                    let rejection = "\(PFUser.currentUser()!.username!) has rejected your offer for \(desiredSquirrelName)"
                    sendPushNotifications(0, message: rejection, type: "rejectedTrade", users: [offeringUsername])
                    alert.dismissViewControllerAnimated(true, completion: nil)
                    self.dismissViewControllerAnimated(true, completion: nil)
                    //Reload
                    self.delegate!.tradeOfferViewController(self)
                }))
                alert.addAction(UIAlertAction(title: "Yes", style: .Default, handler: { (action: UIAlertAction) in
                    self.changeOwners()
                    self.finishTrade()
                    alert.dismissViewControllerAnimated(true, completion: nil)
                    self.dismissViewControllerAnimated(true, completion: nil)
                }))
                self.presentViewController(alert, animated: true, completion: nil)
                return
            } else if proposerAcorns < offeredAcorns && proposerAcorns > 0 {
                //Then the offerer doesn't have as many acorns as they offered, but we can give the user the option to accept less acorns and get the offered squirrel
                //Global function that stops the loading animation and dismisses the views it is attached to
                resumeInteractionEvents(activityIndicatorView, container: container, loadingView: loadingView)
                let title = "There's a problem with the trade"
                let offeringUsername = tradeProposal!["offeringUsername"] as! String
                var message = "Unforuntately \(offeringUsername) doesn't have \(offeredAcorns) acorns but can offer \(proposerAcorns!) acorns instead. Would you still like to trade?"
                if offeredSquirrelID != nil {
                    message = "Unfortunately \(offeringUsername) doesn't have \(offeredAcorns) acorns but can offer \(proposerAcorns!) acorns and their squirrel. Would you still like to trade?"
                }
                let alert = UIAlertController(title: title, message: message, preferredStyle: UIAlertControllerStyle.Alert)
                alert.addAction(UIAlertAction(title: "No", style: .Cancel, handler: { (action: UIAlertAction) in
                    self.tradeProposal!.delete()
                    //Send alert that proposer's trade was deleted
                    let rejection = "\(PFUser.currentUser()!.username!) has rejected your offer for \(desiredSquirrelName)"
                    sendPushNotifications(0, message: rejection, type: "rejectedTrade", users: [offeringUsername])
                    alert.dismissViewControllerAnimated(true, completion: nil)
                    self.dismissViewControllerAnimated(true, completion: nil)
                    //Reload
                    self.delegate!.tradeOfferViewController(self)
                    return
                }))
                alert.addAction(UIAlertAction(title: "Yes", style: .Default, handler: { (action: UIAlertAction) in
                    //Reloading
                    self.delegate?.tradeOfferViewController(self)
                    let newProposerAcorns = "0"
                    let newUserAcorns = getNewArrayToSave(currentGroup["acorns"] as! [String], username: offeringUsername, newInfo: newProposerAcorns)
                    var userAcorns2 = Int(getUserInfo(newUserAcorns, username: PFUser.currentUser()!.username!))
                    userAcorns2! += proposerAcorns!
                    //For immediately displaying the user's new acorns
                    LOGGED_IN_USER_ACORNS = userAcorns2!
                    self.changeOwners()
                    self.tradeProposal!.deleteInBackgroundWithBlock({ (didDelete: Bool, error: NSError?) -> Void in
                        if error == nil {
                            self.finishTrade()
                            let newAcorns = getNewArrayToSave(newUserAcorns, username: PFUser.currentUser()!.username!, newInfo: String(userAcorns2!))
                            currentGroup["acorns"] = newAcorns
                            if self.tradeProposal!["offeredSquirrelID"] == nil {
                                //Update squirrel slots
                                let squirrelSlots = self.newSquirrelSlots(currentGroup)
                                currentGroup["squirrelSlots"] = squirrelSlots
                            }
                            currentGroup.save()
                            alert.dismissViewControllerAnimated(true, completion: nil)
                            self.dismissViewControllerAnimated(true, completion: nil)
                            //Reload
                            self.delegate!.tradeOfferViewController(self)
    
                        } else {
                            //There was an error and we should alert them using the global function
                            displayAlert(self, title: "Oops", message: "There's been a problem. Would you mind trying again?")
                        }
                    })
                }))
                self.presentViewController(alert, animated: true, completion: nil)
                return

            } else {
                //The user has enough acorns for the trade
                //Need to subtract acorns from the offerer and add them to the logged in user
                proposerAcorns! -= offeredAcorns
                let newAcorns = getNewArrayToSave(currentGroup["acorns"] as! [String], username: offeringUsername, newInfo: String(proposerAcorns!))
                
                var userAcorns = Int(getUserInfo(newAcorns, username: PFUser.currentUser()!.username!))
           
                userAcorns! += offeredAcorns
                //For immediately displaying the user's new acorns
                LOGGED_IN_USER_ACORNS = userAcorns!
                let newAcorns2 = getNewArrayToSave(newAcorns, username: PFUser.currentUser()!.username!, newInfo: String(userAcorns!))
                currentGroup["acorns"] = newAcorns2
                if self.tradeProposal!["offeredSquirrelID"] == nil {
                    let squirrelSlots = self.newSquirrelSlots(currentGroup)
                    currentGroup["squirrelSlots"] = squirrelSlots
                }
                currentGroup.save()
            }
        
        }
        
        ///End of acorn checks
        changeOwners()
        finishTrade()
        //Global function that stops the loading animation and dismisses the views it is attached to
        resumeInteractionEvents(activityIndicatorView, container: container, loadingView: loadingView)
        self.dismissViewControllerAnimated(true, completion: nil)
    }
    

    override func viewDidLoad() {
        super.viewDidLoad()
        let yourSquirrelQuery = PFQuery(className: "Squirrel")
        yourSquirrelQuery.whereKey("objectId", equalTo: tradeProposal!["proposedSquirrelID"]!)
        yourSquirrel = yourSquirrelQuery.getFirstObject()
        
        let yourFirstName = yourSquirrel!["first_name"] as? String
        let yourLastName = yourSquirrel!["last_name"] as? String
        yourSquirrelLabel.text = "\(yourFirstName!) \(yourLastName!)"
        //Give buttons rounded edges
        acceptButton.layer.cornerRadius = 5
        acceptButton.layer.masksToBounds = true
        declineButton.layer.cornerRadius = 5
        declineButton.layer.masksToBounds = true

        if tradeProposal!["offeredSquirrelID"] != nil {
            //Then the offerer is offering a Squirrel
            let offeredSquirrelQuery = PFQuery(className: "Squirrel")
            offeredSquirrelQuery.whereKey("objectId", equalTo: tradeProposal!["offeredSquirrelID"]!)
            offeredSquirrel = offeredSquirrelQuery.getFirstObject()
            let offeredFirstName = offeredSquirrel!["first_name"] as? String
            let offeredLastName = offeredSquirrel!["last_name"] as? String
            offeredlLabel.text = "\(offeredFirstName!) \(offeredLastName!)"
        }
        
        if tradeProposal!["offeredAcorns"] != nil {
            let acorns = tradeProposal!["offeredAcorns"] as! Int
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
