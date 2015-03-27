//
//  NotificationsViewController.swift
//  SquirrelList
//
//  Created by Denis Geary Lopez on 3/15/15.
//  Copyright (c) 2015 Frenvu Inc. All rights reserved.
//

import UIKit

class NotificationsViewController: UITableViewController, TradeOfferViewControllerDelegate {

    var notifications = [PFObject]()
    
    //For determining if we're going through trade proposals or group invites 
    var typeOfNotification: String?

    
    override func numberOfSectionsInTableView(tableView: UITableView) -> Int {
        return 1
    }
    
    override func prepareForSegue(segue: UIStoryboardSegue, sender: AnyObject?) {
        if segue.identifier == "tradeOffer" {
            let controller = segue.destinationViewController as TradeOfferViewController
            controller.delegate = self
            controller.tradeProposal = sender as? PFObject
            
        }

    }
    
    
     override func tableView(tableView: UITableView, cellForRowAtIndexPath indexPath: NSIndexPath) -> UITableViewCell {
        if typeOfNotification == "invite" {
            var cell: UITableViewCell = self.tableView.dequeueReusableCellWithIdentifier("cell") as UITableViewCell
            var inviteLabel = cell.viewWithTag(1) as UILabel
            var inviter = notifications[indexPath.row]["inviterUsername"] as? String
            var groupName = notifications[indexPath.row]["groupName"] as? String
            inviteLabel.text = "\(inviter!) invites you to join \(groupName!)"
            return cell
        }
        else {
            //The user is going through their trade proposals 
            var cell: UITableViewCell = self.tableView.dequeueReusableCellWithIdentifier("cell") as UITableViewCell
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
            var cell: UITableViewCell = tableView.cellForRowAtIndexPath(indexPath)!
            self.performSegueWithIdentifier("tradeOffer", sender: notifications[indexPath.row])
        }
    }
    
    override func tableView(tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return notifications.count
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        
        if typeOfNotification == "invite" {
            self.title = "Invitations"
            var query = PFQuery(className: "Invitation")
            query.whereKey("receivingUserID", equalTo: PFUser.currentUser().objectId as String)
            
            query.findObjectsInBackgroundWithBlock({ (objects: [AnyObject]!, error: NSError!) -> Void in
                self.notifications.removeAll(keepCapacity: true)
                for object in objects {
                    var notification:PFObject = object as PFObject
                    self.notifications.append(notification)
                }
                self.tableView.reloadData()
            })
        } else {
            var query = PFQuery(className:"TradeProposal")
            query.whereKey("receivingUser", equalTo: PFUser.currentUser()["username"])
        
            query.findObjectsInBackgroundWithBlock({ (objects: [AnyObject]!, error: NSError!) -> Void in
                self.notifications.removeAll(keepCapacity: true)
                for object in objects {
                    var notification:PFObject = object as PFObject
                    self.notifications.append(notification)
                }
                self.tableView.reloadData()
            })
        }
    }


    //Needs to be its own extension 
    func tradeOfferViewController(controller: TradeOfferViewController) {
        //Not correctly reloading data. Might need to make it a PQueryTableViewController
        self.tableView.reloadData()
    }
    
    //Needs to be its own extension 
    
    /*
    func popupViewController(controller: PopUpViewController) {
        self.viewDidLoad()
    }
    */
 
    

    /*
    // MARK: - Navigation

    // In a storyboard-based application, you will often want to do a little preparation before navigation
    override func prepareForSegue(segue: UIStoryboardSegue, sender: AnyObject?) {
        // Get the new view controller using segue.destinationViewController.
        // Pass the selected object to the new view controller.
    }
    */

}
