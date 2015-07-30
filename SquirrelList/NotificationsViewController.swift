//
//  NotificationsViewController.swift
//  SquirrelList
//
//  Created by Denis Geary Lopez on 3/15/15.
//  Copyright (c) 2015 Frenvu Inc. All rights reserved.
//

//TableVieWController for displaying rows of group invitations and trade proposals to the logged in user

import UIKit

class NotificationsViewController: PFQueryTableViewController, TradeOfferViewControllerDelegate, GroupInvitePopUpDelegate {

    
    //For determining if we're going through trade proposals or group invites 
    //If it equals 'invite' then we're going through the users Group Invites
    var typeOfNotification: String?
        //Optional for storing whether the viewcontroller should reload (if the user changed their currentGroup)
    var shouldReLoad: Bool?
    
    
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
            var groupInvite = sender as! PFObject
            var inviter = groupInvite["inviter"] as! String
            controller.groupInvite = groupInvite
            controller.inviterName = inviter
            controller.delegate = self
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
            query.whereKey("invitee", equalTo: PFUser.currentUser()!.username!)
        }
        else  {
            query = PFQuery(className: "TradeProposal")
            query.whereKey("receivingUser", equalTo: PFUser.currentUser()!)
            query.whereKey("group", equalTo: PFUser.currentUser()!["currentGroup"]!)
        } 
        query.orderByDescending("avg_rating")
        return query
    }
    
    
    //Responds to NSNotication when user has changed their current group
    func reloadWithNewGroup() {
        shouldReLoad = true
    }
    
    
     override func tableView(tableView: UITableView, cellForRowAtIndexPath indexPath: NSIndexPath) -> UITableViewCell {
        if typeOfNotification == "invite" {
            var cell: UITableViewCell = self.tableView.dequeueReusableCellWithIdentifier("Cell") as! PFTableViewCell
            var inviteLabel = cell.viewWithTag(1) as! UILabel
            var inviter = objects![indexPath.row]["inviter"] as? String
            var groupName = objects![indexPath.row]["groupName"] as? String
            inviteLabel.text = "\(inviter!) invites you to join \(groupName!)"
            return cell
        }
        else {
            //The user is going through their trade proposals 
            var cell: UITableViewCell = self.tableView.dequeueReusableCellWithIdentifier("Cell") as! UITableViewCell
            var tradeOfferLabel = cell.viewWithTag(1) as! UILabel
            var user = objects![indexPath.row]["offeringUsername"] as! String
            var desiredSquirrel = objects![indexPath.row]["desiredSquirrelName"] as! String
            tradeOfferLabel.text = "\(user) wants \(desiredSquirrel)"
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
        createGroupButton?.tintColor = UIColor.orangeColor()
        self.navigationController?.navigationBar.titleTextAttributes = [ NSFontAttributeName: UIFont(name: "BebasNeueBold", size: 26)!,  NSForegroundColorAttributeName: UIColor.whiteColor()]
        //Set notification to "listen" for when the the user has changed their currentGroup
        NSNotificationCenter.defaultCenter().addObserver(self, selector: "reloadWithNewGroup", name: reloadNotificationKey, object: nil)
        //Customize navigation controller back button to my only the back symbol
        let backItem = UIBarButtonItem(title: "", style: UIBarButtonItemStyle.Plain, target: nil, action: nil)
        navigationItem.backBarButtonItem = backItem


    }
    
    
    override func viewWillAppear(animated: Bool) {
        if shouldReLoad == true {
            shouldReLoad = false
            self.viewDidLoad()
        }
    }
    


    //This is merely for reloading the data everytime the user accepts or declines a trade
    func tradeOfferViewController(controller: TradeOfferViewController) {
        self.viewDidLoad()
    }
    
    //For relading after a user has accepted or declined a group inviation
    func reloadAfterGroupInviteDecision(controller: GroupInvitePopUpViewController) {
        self.viewDidLoad()
    }
    
    
    

 


}
