//
//  NotificationsViewController.swift
//  SquirrelList
//
//  Created by Denis Geary Lopez on 3/15/15.
//  Copyright (c) 2015 Frenvu Inc. All rights reserved.
//

//TableVieWController for displaying rows of group invitations and trade proposals to the logged in user

import UIKit

@objc protocol NotificationsViewControllerDelegate: class {
    optional func updateGroupBadges(controller: NotificationsViewController, numOfBadges: Int)
}

class NotificationsViewController: PFQueryTableViewController, TradeOfferViewControllerDelegate, GroupInvitePopUpDelegate {

    
    //For determining if we're going through trade proposals or group invites 
    //If it equals 'invite' then we're going through the users Group Invites
    var typeOfNotification: String?
    //Optional for storing whether the viewcontroller should reload (if the user changed their currentGroup)
    var shouldReLoad: Bool?
    //Variable for keeping track of whether we should save the users friendData to update their number of group
    var shouldUpdateGroupInvite = false
    //Variable for updating new number of group invites, if user has accepted or rejectred group invites
    var numToDecreaseInvitesBy = 0
    //Variable for keeping track of whether we should update the trade offers for the logged in user
    var shouldUpdateTradeOffers = false
    //Variable for updating new number of trade offers, if user has accepted or rejected offers
    var numOfTradeOffers = 0
    
    var delegate: NotificationsViewControllerDelegate?
    
    
    @IBOutlet weak var createGroupButton: UIBarButtonItem?
    
    @IBAction func createGroup(sender: AnyObject) {
        performSegueWithIdentifier("CreateGroup", sender: self)
    }
    
    // Initialise the PFQueryTable tableview
    override init(style: UITableViewStyle, className: String!) {
        super.init(style: style, className: className)
    }
	
    required init(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)!
  
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
        if segue.identifier == "groupInvite" {
            let controller = segue.destinationViewController as! GroupInvitePopUpViewController
            let groupInvite = sender as! PFObject
            let inviter = groupInvite["inviter"] as! String
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
        return query
    }
    
    
    //Responds to NSNotication when user has changed their current group
    func reloadWithNewGroup() {
        shouldReLoad = true
    }

    
    
     override func tableView(tableView: UITableView, cellForRowAtIndexPath indexPath: NSIndexPath) -> UITableViewCell {
        if typeOfNotification == "invite" {
            let cell: UITableViewCell = self.tableView.dequeueReusableCellWithIdentifier("Cell") as! PFTableViewCell
            let inviteLabel = cell.viewWithTag(1) as! UILabel
            let inviter = objects![indexPath.row]["inviter"] as? String
            let groupName = objects![indexPath.row]["groupName"] as? String
            inviteLabel.text = "\(inviter!) invites you to join \(groupName!)"
            return cell
        }
        else {
            //The user is going through their trade proposals 
            let cell: UITableViewCell = self.tableView.dequeueReusableCellWithIdentifier("Cell")! //as! UITableViewCell
            let tradeOfferLabel = cell.viewWithTag(1) as! UILabel
            let user = objects![indexPath.row]["offeringUsername"] as! String
            let desiredSquirrel = objects![indexPath.row]["desiredSquirrelName"] as! String
            tradeOfferLabel.text = "\(user) wants \(desiredSquirrel)"
            return cell
        }
    }
    
    override func tableView(tableView: UITableView, didSelectRowAtIndexPath indexPath: NSIndexPath) {
        if typeOfNotification == "invite" {
            //var cell: UITableViewCell = tableView.cellForRowAtIndexPath(indexPath)!
            self.performSegueWithIdentifier("groupInvite", sender: objects![indexPath.row])
        }
        else {
            //They are viewing trade proposals offered to them
            //var cell = tableView.cellForRowAtIndexPath(indexPath)!
            self.performSegueWithIdentifier("TradeOffer", sender: objects![indexPath.row])
        }
    }
    
    
    override func viewDidLoad() {
        super.viewDidLoad()
        //Set the createGroupButton to 'fa-plus'
        createGroupButton?.setTitleTextAttributes([NSFontAttributeName: UIFont(name: "FontAwesome", size: 30)!], forState: UIControlState.Normal)
        createGroupButton?.title = "\u{f067}"
        createGroupButton?.tintColor = UIColor.orangeColor()
        self.navigationController?.navigationBar.titleTextAttributes = [ NSFontAttributeName: UIFont(name: "BebasNeueBold", size: 26)!,  NSForegroundColorAttributeName: UIColor.whiteColor()]
        //Set notification to "listen" for when the the user has changed their currentGroup
        NSNotificationCenter.defaultCenter().addObserver(self, selector: "reloadWithNewGroup", name: reloadNotificationKey, object: nil)
        //Customize navigation controller back button to my only the back symbol
        let backItem = UIBarButtonItem(title: "", style: UIBarButtonItemStyle.Plain, target: nil, action: nil)
        navigationItem.backBarButtonItem = backItem
    }
    
    
    override func viewWillAppear(animated: Bool) {
        super.viewWillAppear(animated)
        if shouldReLoad == true {
            shouldReLoad = false
            self.viewDidLoad()
        }
    }
    
    override func viewWillDisappear(animated: Bool) {
        super.viewWillAppear(animated)
        //Check to see if we need to update the trade offers of group invites for the logged in user
        if shouldUpdateGroupInvite == true {
            let userFriendsData = PFUser.currentUser()!["friendData"] as! PFObject
            userFriendsData.fetch()
            let oldNumOfInvites = userFriendsData["groupInvites"] as! Int
            let newNumOfInvites = oldNumOfInvites - numToDecreaseInvitesBy
            userFriendsData["groupInvites"] = newNumOfInvites
            userFriendsData.save()
            delegate!.updateGroupBadges!(self, numOfBadges: newNumOfInvites)
        }// Logic for updating trade badges - will implement later
        /*
        else if shouldUpdateTradeOffers == true {
            print("should be updating number of trade offers")
            let currentGroup = PFUser.currentUser()!["currentGroup"] as! PFObject
            //currentGroup.fetch()
            let newTradeOffers = numOfTradeOffers + 1
            let newTradeOffersArray = getNewArrayToSave(currentGroup["tradeOffers"] as! [String], username: PFUser.currentUser()!.username!, newInfo: String(newTradeOffers))
            currentGroup["tradeOffers"] = newTradeOffersArray
            currentGroup.save()
        
        }
        */
    }


    //This is merely for reloading the data everytime the user accepts or declines a trade - delegate function
    func tradeOfferViewController(controller: TradeOfferViewController) {
        //Whether the user accepts or declines the trade offer, afterwards we need to subtract their trade offers by 1
        // Logic for updating trade badges - will implement later
        //shouldUpdateTradeOffers = true
        //numOfTradeOffers -= 1
        self.viewDidLoad()
    }
    
    //For relading after a user has accepted or declined a group inviation - delegate function
    func reloadAfterGroupInviteDecision(controller: GroupInvitePopUpViewController) {
        //Whether the user accepts or declines the trade offer, afterwards we need to subtract their trade offers by 1
        shouldUpdateGroupInvite = true
        numToDecreaseInvitesBy += 1
        self.viewDidLoad()
    }
    
    
    

 


}
