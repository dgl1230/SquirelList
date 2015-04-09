//
//  NotificationsViewController.swift
//  SquirrelList
//
//  Created by Denis Geary Lopez on 3/15/15.
//  Copyright (c) 2015 Frenvu Inc. All rights reserved.
//

import UIKit

class NotificationsViewController: PFQueryTableViewController, TradeOfferViewControllerDelegate {

    var notifications = [PFObject]()
    
    //For determining if we're going through trade proposals or group invites 
    var typeOfNotification: String?
    
    
    // Initialise the PFQueryTable tableview
    override init!(style: UITableViewStyle, className: String!) {
        super.init(style: style, className: className)
    }
	
    required init(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
  
        // Configure the PFQueryTableView
        if typeOfNotification? == "invite" {
            self.parseClassName = "GroupInvite"
            self.textKey = "groupName"
        } else {
            //The objects are trade proposals
            self.parseClassName = "TradeProposal"
            self.textKey = "offeringUser"
        }
        pullToRefreshEnabled = true
        self.paginationEnabled = false
    }


    
    override func prepareForSegue(segue: UIStoryboardSegue, sender: AnyObject?) {
        if segue.identifier == "tradeOffer" {
            let controller = segue.destinationViewController as TradeOfferViewController
            controller.delegate = self
            controller.tradeProposal = sender as? PFObject
        }
    }
    
    
    // Define the query that will provide the data for the table view
    override func queryForTable() -> PFQuery! {
        //Have to have this line to prevent xcode bug from thinking there's a way query wouldn't be returned
        var query = PFQuery()
        if typeOfNotification? == "invite" {
            query = PFQuery(className: "GroupInvite")
            query.whereKey("invitee", equalTo: PFUser.currentUser().objectId)
        }
        else  {
            query = PFQuery(className: "TradeProposal")
            query.whereKey("receivingUser", equalTo: PFUser.currentUser()["username"])
        } 
        query.orderByDescending("avg_rating")
        return query
    }
    
    
     override func tableView(tableView: UITableView, cellForRowAtIndexPath indexPath: NSIndexPath) -> UITableViewCell {
        if typeOfNotification == "invite" {
            var cell: UITableViewCell = self.tableView.dequeueReusableCellWithIdentifier("Cell") as PFTableViewCell
            var inviteLabel = cell.viewWithTag(1) as UILabel
            var inviter = notifications[indexPath.row]["inviterUsername"] as? String
            var groupName = notifications[indexPath.row]["groupName"] as? String
            inviteLabel.text = "\(inviter!) invites you to join \(groupName!)"
            return cell
        }
        else {
            //The user is going through their trade proposals 
            var cell: UITableViewCell = self.tableView.dequeueReusableCellWithIdentifier("Cell") as UITableViewCell
            var tradeOfferLabel = cell.viewWithTag(1) as UILabel
            var username = notifications[indexPath.row]["offeringUser"] as? String
            tradeOfferLabel.text = "\(username!) proposes a trade"
            return cell
        }
    }
    
    override func tableView(tableView: UITableView, didSelectRowAtIndexPath indexPath: NSIndexPath) {
        if typeOfNotification == "invite" {
            //segue to viewing invite
        }
        else {
            //They are viewing trade proposals offered to them
            var cell: UITableViewCell = tableView.cellForRowAtIndexPath(indexPath)!
            self.performSegueWithIdentifier("tradeOffer", sender: notifications[indexPath.row])
        }
    }
    


    //Needs to be its own extension 
    func tradeOfferViewController(controller: TradeOfferViewController) {
        //Not correctly reloading data. Might need to make it a PQueryTableViewController
        self.tableView.reloadData()
    }
    

 


}
