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

    required init(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
    }

    @IBOutlet var tblOptions : UITableView?
    
    override func viewDidLoad() {
        super.viewDidLoad()
        // Uncomment the following line to preserve selection between presentations
        // self.clearsSelectionOnViewWillAppear = false
        self.tblOptions?.tableFooterView = UIView(frame: CGRectZero)

    }



    // MARK: - Table view data source

    override func numberOfSectionsInTableView(tableView: UITableView) -> Int {
        return 1
    }
    
    override func prepareForSegue(segue: UIStoryboardSegue, sender: AnyObject?) {
        if segue.identifier == "FindFriends" {
            let controller = segue.destinationViewController as FindFriendsViewController
        }
        if segue.identifier == "MyProfile" {
            println(2)
            let controller = segue.destinationViewController as UserProfileViewController
            println(3)
        }
        if segue.identifier == "TradeOffers" {
            let controller = segue.destinationViewController as NotificationsViewController
            controller.typeOfNotification = "trade"
        }
    }

    override func tableView(tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return 5
    }
    
    

    /*
    override func tableView(tableView: UITableView!, cellForRowAtIndexPath indexPath: NSIndexPath!) -> UITableViewCell! {
        let cell = tableView.dequeueReusableCellWithIdentifier("reuseIdentifier", forIndexPath: indexPath) as UITableViewCell

        // Configure the cell...

        return cell
    }
    */

    
    override func tableView(tableView: UITableView, didSelectRowAtIndexPath indexPath: NSIndexPath) {
        //let indexPathNew = tableView.indexPathForSelectedRow()
        let currentCell = tableView.cellForRowAtIndexPath(indexPath) as UITableViewCell!
        if indexPath.row  == 0 {
            //The user is selecting "My Profile"
            performSegueWithIdentifier("MyProfile", sender: self)
        }
        if indexPath.row == 1 {
            //The user is selecing "Trade Offers"
            performSegueWithIdentifier("TradeOffers", sender: self)
        }
        if indexPath.row == 3 {
            //The user is selecting "Find Friends"
            performSegueWithIdentifier("FindFriends", sender: self)
        }
        

        
    }

    

   
    
    

    /*
    // MARK: - Navigation

    // In a storyboard-based application, you will often want to do a little preparation before navigation
    override func prepareForSegue(segue: UIStoryboardSegue!, sender: AnyObject!) {
        // Get the new view controller using [segue destinationViewController].
        // Pass the selected object to the new view controller.
    }
    */

}
