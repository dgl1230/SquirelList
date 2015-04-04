//
//  MoreViewController.swift
//  SquirrelList
//
//  Created by Denis Geary Lopez on 3/25/15.
//  Copyright (c) 2015 Frenvu Inc. All rights reserved.
//

/* This ViewController displays a list of options for the user to select, including "My Profile," 
*/


import UIKit

class MoreTableViewController: UITableViewController {

    @IBOutlet weak var friendsIcon: UILabel!
    @IBOutlet weak var groupsIcon: UILabel!
    @IBOutlet weak var settingsIcon: UILabel!
    
    required init(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
    }

    @IBOutlet var tblOptions : UITableView?
    

    // MARK: - Table view data source

    override func numberOfSectionsInTableView(tableView: UITableView) -> Int {
        return 1
    }
    
    override func prepareForSegue(segue: UIStoryboardSegue, sender: AnyObject?) {
        if segue.identifier == "Friends" {
            let controller = segue.destinationViewController as FriendsViewController
        }
        /*
        Need to think over if trade offers should be its own VC
        if segue.identifier == "TradeOffers" {
            let controller = segue.destinationViewController as NotificationsViewController
            controller.typeOfNotification = "trade"
        }
        */
    }

    override func tableView(tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return 3
    }
    
    
    override func tableView(tableView: UITableView, didSelectRowAtIndexPath indexPath: NSIndexPath) {
        //let indexPathNew = tableView.indexPathForSelectedRow()
        let currentCell = tableView.cellForRowAtIndexPath(indexPath) as UITableViewCell!
        if indexPath.row == 0 {
            //The user is selecing "Friends"
            performSegueWithIdentifier("Friends", sender: self)
        }
        if indexPath.row == 3 {
            //The user is selecing "Trade Offers"
            performSegueWithIdentifier("TradeOffers", sender: self)
        }

    }
    
    
    override func viewDidLoad() {
        super.viewDidLoad()
        // Uncomment the following line to preserve selection between presentations
        // self.clearsSelectionOnViewWillAppear = false
        self.tblOptions?.tableFooterView = UIView(frame: CGRectZero)
        //Set the friendsIcon to 'fa-smile-o'
        friendsIcon.text = "\u{f118}"
        //Set the groupsIcon to 'fa-users'
        groupsIcon.text = "\u{f0c0}"
        //Set the settings icon to 'fa-cog'
        settingsIcon.text = "\u{f013}"
        
    }

    


}
