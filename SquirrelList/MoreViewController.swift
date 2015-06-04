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
    }

    override func tableView(tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return 3
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

    }
    
    
    override func viewDidLoad() {
        super.viewDidLoad()
        if isNewUser == true {
            self.title = "Home"
        }
        self.tblOptions?.tableFooterView = UIView(frame: CGRectZero)
        //Set the friendsIcon to 'fa-smile-o'
        friendsIcon.text = "\u{f118}"
        //Set the groupsIcon to 'fa-users'
        groupsIcon.text = "\u{f0c0}"
        //Set the settings icon to 'fa-cog'
        settingsIcon.text = "\u{f013}"
        //Customize navigation controller back button to my only the back symbol
        let backItem = UIBarButtonItem(title: "", style: UIBarButtonItemStyle.Plain, target: nil, action: nil)
        navigationItem.backBarButtonItem = backItem

    }

    


}
