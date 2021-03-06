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
    
    //Array for storing all the trades as PFObjects - for potentially deleting multiple trades without querying after user has accepted a trade. This variable if passed on to TradeOfferViewController
    var trades: [PFObject] = []
    
    var delegate: NotificationsViewControllerDelegate?
    
    
    //@IBOutlet weak var createGroupButton: UIBarButtonItem?
    @IBOutlet weak var searchGroupsButton: UIBarButtonItem?
    @IBOutlet weak var createGroupButton: UIButton?
    
    @IBAction func createGroup(sender: AnyObject) {
        performSegueWithIdentifier("CreateGroup", sender: self)
    }
    
    @IBAction func searchGroups(sender: AnyObject) {
        performSegueWithIdentifier("SearchGroups", sender: self)
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
            controller.trades = trades
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
            //Update trade array
            trades.append(objects![indexPath.row] as! PFObject)
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
    
    override func tableView(tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
    //If their were previously no objects, we want to remove the imageview and label we previously created for no squirrels existing. We remove the label and imageView by referencing their tags
        for subview in self.tableView.subviews {
            if subview.tag == 69 || subview.tag == 70 {
                subview.removeFromSuperview()
            }
        }
        //Check to see if there are no results, and thus we should display an image and text instead of an empty table view
        if objects!.count == 0 {
            let emptyLabel = UILabel(frame: CGRectMake(0, 50, self.view.bounds.size.width, 40))
            emptyLabel.font = UIFont(name: "BebasNeue-Thin", size: 40)
            emptyLabel.textColor = UIColor.grayColor()
            emptyLabel.textAlignment = .Center
            emptyLabel.adjustsFontSizeToFitWidth = true
            let emptyImageView = UIImageView(frame: CGRectMake(20, 85, 256, 256))
            emptyImageView.center.x = self.tableView.center.x
            emptyImageView.image = UIImage(named: "pineapple")
            if typeOfNotification == "invite" {
                emptyLabel.text = "You have no invitations"
            } else {
                //The user is viewing trade offers
                emptyLabel.text = "You have no trade offers"
                //We need to re-adjust the y postion of the label and imageView, because on trade offers there will not be another view directly below the navigation bar
                emptyLabel.center.y = 25
                emptyImageView.frame = CGRectMake(20, 45, 256, 256)
                emptyImageView.center.x = self.tableView.center.x
            }
            //We set tags to make it easy to potentialyl remove these subviews if the user searches a new group that does have a result
            emptyLabel.tag = 69
            emptyImageView.tag = 70
            self.view.addSubview(emptyLabel)
            self.view.addSubview(emptyImageView)
            self.tableView.addSubview(emptyImageView)
            //Using sepatorStyle doesn't get the separator lines to disappear if there's no objects, so we do this instead
            self.tableView.separatorColor = UIColor.clearColor()
            return 0
        }
        return objects!.count
    }
    
    
    override func viewDidLoad() {
        super.viewDidLoad()
        //Set the searchGroupsButton to 'fa-search'
        searchGroupsButton?.setTitleTextAttributes([NSFontAttributeName: UIFont(name: "FontAwesome", size: 30)!], forState: UIControlState.Normal)
        searchGroupsButton?.title = "\u{f002}"
        searchGroupsButton?.tintColor = UIColor.orangeColor()
        self.navigationController?.navigationBar.titleTextAttributes = [ NSFontAttributeName: UIFont(name: "BebasNeueBold", size: 26)!,  NSForegroundColorAttributeName: UIColor.whiteColor()]
        //Customize navigation controller back button to my only the back symbol
        let backItem = UIBarButtonItem(title: "", style: UIBarButtonItemStyle.Plain, target: nil, action: nil)
        navigationItem.backBarButtonItem = backItem
    }
    
    /*
    override func viewWillAppear(animated: Bool) {
        super.viewWillAppear(animated)
        if shouldReLoad == true {
            shouldReLoad = false
            self.viewDidLoad()
        }
    }
    */
    
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
