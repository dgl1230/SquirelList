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
    
    //Optional for keeping track if the user has no currentGroup
    var isNewUser: Bool?
    
    //Not sure if I need this or not, starting to think I don't 
    /*
    required init(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
    }
    */

    @IBOutlet var tblOptions : UITableView?
    

    override func numberOfSectionsInTableView(tableView: UITableView) -> Int {
        return 1
    }
    
    override func prepareForSegue(segue: UIStoryboardSegue, sender: AnyObject?) {
        if segue.identifier == "Friends" {
            let controller = segue.destinationViewController as! FriendsViewController
        }
        if segue.identifier == "GroupInvites" {
            let controller = segue.destinationViewController as! NotificationsViewController
            controller.typeOfNotification = "invite"
        }
        if segue.identifier == "Settings" {
            let controller = segue.destinationViewController as! SettingsViewController
        }
        if segue.identifier == "Squirrel Store" {
            let controller = segue.destinationViewController as! SquirrelStoreController
        }
        if segue.identifier == "NewUserScreens" {
            let controller = segue.destinationViewController as! TutorialViewController
            controller.typeOfContent = "more"
        }
    }

    override func tableView(tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        //If the user doesn't have a current group, then we hide the Squirrel Store
        if PFUser.currentUser()!["currentGroup"] == nil {
            return 3
        }
        return 4
    }
    
    
    override func tableView(tableView: UITableView, didSelectRowAtIndexPath indexPath: NSIndexPath) {
        //let indexPathNew = tableView.indexPathForSelectedRow()
        let currentCell = tableView.cellForRowAtIndexPath(indexPath) as UITableViewCell!
        if indexPath.row == 0 {
            //The user is selecting "Friends"
            performSegueWithIdentifier("Friends", sender: self)
        }
        if indexPath.row == 1 {
            //The user is selecting "Groups"
            performSegueWithIdentifier("GroupInvites", sender: self)
        }
        if indexPath.row == 2 {
            //The user is selecting "Settings"
            performSegueWithIdentifier("Settings", sender: self)
        }
        if indexPath.row == 3 {
            //The user is selecting "Squirrel Store"
            performSegueWithIdentifier("Squirrel Store", sender: self)
        }

    }
    
    
    override func viewDidLoad() {
        super.viewDidLoad()
        //Check to see if we need to show a new user tutorial screens first
        if PFUser.currentUser()!["newMoreTab"] as! Bool == true {
            //If new user, show them the tutorial screens
            performSegueWithIdentifier("NewUserScreens", sender: self)
        
        }
        
        if isNewUser == true {
            self.title = "Home"
        }
        self.tblOptions?.tableFooterView = UIView(frame: CGRectZero)
        //Customize navigation controller back button to my only the back symbol
        let backItem = UIBarButtonItem(title: "", style: UIBarButtonItemStyle.Plain, target: nil, action: nil)
        navigationItem.backBarButtonItem = backItem
        self.navigationController?.navigationBar.titleTextAttributes = [ NSFontAttributeName: UIFont(name: "BebasNeueBold", size: 26)!,  NSForegroundColorAttributeName: UIColor.whiteColor()]

    }

    


}
