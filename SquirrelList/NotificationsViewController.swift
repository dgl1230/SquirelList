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


    @IBAction func back(sender: AnyObject) {
        self.dismissViewControllerAnimated(true, completion: nil)
    }
    
    override func numberOfSectionsInTableView(tableView: UITableView) -> Int {
        return 1
    }
    
    override func prepareForSegue(segue: UIStoryboardSegue, sender: AnyObject?) {
        if segue.identifier == "tradeOffer" {
            println("going to this segue")
            let controller = segue.destinationViewController as TradeOfferViewController
            controller.delegate = self
            println(sender)
            controller.tradeProposal = sender as? PFObject
            
        }

    }
    
    
     override func tableView(tableView: UITableView, cellForRowAtIndexPath indexPath: NSIndexPath) -> UITableViewCell {
    
        var cell: UITableViewCell = self.tableView.dequeueReusableCellWithIdentifier("cell") as UITableViewCell
        var usernameLabel = cell.viewWithTag(1) as UILabel
        usernameLabel.text = notifications[indexPath.row]["offeringUser"] as? String
        
        return cell
    }
    
    override func tableView(tableView: UITableView, didSelectRowAtIndexPath indexPath: NSIndexPath) {
        var cell: UITableViewCell = tableView.cellForRowAtIndexPath(indexPath)!
        self.performSegueWithIdentifier("tradeOffer", sender: notifications[indexPath.row])
    }
    
    override func tableView(tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return notifications.count
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        
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


    //Needs to be its own extension 
    func tradeOfferViewController(controller: TradeOfferViewController) {
        self.viewDidLoad()
    }
 
    

    /*
    // MARK: - Navigation

    // In a storyboard-based application, you will often want to do a little preparation before navigation
    override func prepareForSegue(segue: UIStoryboardSegue, sender: AnyObject?) {
        // Get the new view controller using segue.destinationViewController.
        // Pass the selected object to the new view controller.
    }
    */

}
