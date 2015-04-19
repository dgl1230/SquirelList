//
//  NotificationsViewController.swift
//  SquirrelList
//
//  Created by Denis Geary Lopez on 3/15/15.
//  Copyright (c) 2015 Frenvu Inc. All rights reserved.
//

//TableVieWController for displaying rows of group invitations and trade proposals to the logged in user

import UIKit

class NotificationsViewController: PFQueryTableViewController, TradeOfferViewControllerDelegate {

    
    //For determining if we're going through trade proposals or group invites 
    //If it equals 'invite' then we're going through the users Group Invites
    var typeOfNotification: String?
    
    
    @IBOutlet weak var createGroupButton: UIBarButtonItem?
    
    @IBAction func createGroup(sender: AnyObject) {
        performSegueWithIdentifier("CreateGroup", sender: self)
    }
    
    // Initialise the PFQueryTable tableview
    override init(style: UITableViewStyle, className: String!) {
        super.init(style: style, className: className)
    }
	
    required init(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
  
        // Configure the PFQueryTableView
        if typeOfNotification == "invite" {
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
        if segue.identifier == "CreateGroup" {
            let controller = segue.destinationViewController as! CreateGroupViewController
        }
        if segue.identifier == "groupInvite" {
            let controller = segue.destinationViewController as! GroupInvitePopUpViewController
            controller.groupInvite = sender as? PFObject
            
        }
        if segue.identifier == "TradeOffer" {
            let controller = segue.destinationViewController as! TradeOfferViewController
            controller.delegate = self
            controller.tradeProposal = sender as? PFObject
        }
    }
    
    
    // Define the query that will provide the data for the table view
    override func queryForTable() -> PFQuery {
        //Have to have this line to prevent xcode bug from thinking there's a way query wouldn't be returned
        var query = PFQuery()
        if typeOfNotification == "invite" {
            query = PFQuery(className: "GroupInvite")
            query.whereKey("invitee", equalTo: PFUser.currentUser()!.objectId!)
        }
        else  {
            query = PFQuery(className: "TradeProposal")
            query.whereKey("receivingUser", equalTo: PFUser.currentUser()!["username"]!)
        } 
        query.orderByDescending("avg_rating")
        return query
    }
    
    
     override func tableView(tableView: UITableView, cellForRowAtIndexPath indexPath: NSIndexPath) -> UITableViewCell {
        if typeOfNotification == "invite" {
            var cell: UITableViewCell = self.tableView.dequeueReusableCellWithIdentifier("Cell") as! PFTableViewCell
            var inviteLabel = cell.viewWithTag(1) as! UILabel
            var inviter = objects![indexPath.row]["inviter"] as? String
            var groupName = objects![indexPath.row]["groupName"] as? String
            inviteLabel.text = "\(inviter!) invites you to join \(groupName)"
            return cell
        }
        else {
            //The user is going through their trade proposals 
            var cell: UITableViewCell = self.tableView.dequeueReusableCellWithIdentifier("Cell") as! UITableViewCell
            var tradeOfferLabel = cell.viewWithTag(1) as! UILabel
            var username = objects![indexPath.row]["offeringUser"] as? String
            tradeOfferLabel.text = "\(username!) proposes a trade"
            return cell
        }
    }
    
    override func tableView(tableView: UITableView, didSelectRowAtIndexPath indexPath: NSIndexPath) {
        if typeOfNotification == "invite" {
            var cell: UITableViewCell = tableView.cellForRowAtIndexPath(indexPath)!
            self.performSegueWithIdentifier("groupInvite", sender: objects![indexPath.row])
        }
        else {
            //They are viewing trade proposals offered to them
            var cell: UITableViewCell = tableView.cellForRowAtIndexPath(indexPath)!
            self.performSegueWithIdentifier("TradeOffer", sender: objects![indexPath.row])
        }
    }
    
    
    override func viewDidLoad() {
        super.viewDidLoad()
        //Set the createGroupButton to 'fa-plus-circle'
        createGroupButton?.setTitleTextAttributes([NSFontAttributeName: UIFont(name: "FontAwesome", size: 30)!], forState: UIControlState.Normal)
        createGroupButton?.title = "\u{f055}"
        createGroupButton?.tintColor = UIColor.whiteColor()
    }
    


    //Needs to be its own extension 
    func tradeOfferViewController(controller: TradeOfferViewController) {
        //Not correctly reloading data. Might need to make it a PQueryTableViewController
        self.tableView.reloadData()
    }
    
    
    

 


}
