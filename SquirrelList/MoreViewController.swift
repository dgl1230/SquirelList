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


class MoreTableViewController: UITableViewController, FriendsViewControllerDelegate, NotificationsViewControllerDelegate {
    
    //Optional for keeping track if the user has no currentGroup
    var isNewUser: Bool?
    
    //Not sure if I need this or not, starting to think I don't 
    /*
    required init(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
    }
    */

    
    @IBOutlet weak var friendsBadgeLabel: SwiftBadge!
    @IBOutlet weak var groupsBadgeLabel: SwiftBadge!
    @IBOutlet var tblOptions : UITableView?
    

    override func numberOfSectionsInTableView(tableView: UITableView) -> Int {
        return 1
    }
    
    override func prepareForSegue(segue: UIStoryboardSegue, sender: AnyObject?) {
        if segue.identifier == "Friends" {
            let controller = segue.destinationViewController as! FriendsViewController
            controller.delegate = self
        }
        if segue.identifier == "GroupInvites" {
            let controller = segue.destinationViewController as! NotificationsViewController
            controller.typeOfNotification = "invite"
            controller.delegate = self
        }
        if segue.identifier == "NewUserScreens" {
            let controller = segue.destinationViewController as! TutorialViewController
            controller.typeOfContent = "more"
        }
    }

    override func tableView(tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        //If the user doesn't have a current group, then we hide the Squirrel Store
        if PFUser.currentUser()!["currentGroup"] == nil {
            return 4
        }
        return 5
    }
    
    
    override func tableView(tableView: UITableView, didSelectRowAtIndexPath indexPath: NSIndexPath) {
        if indexPath.row == 0 {
            //The user is selecting "Friends"
            performSegueWithIdentifier("Friends", sender: self)
        }
        if indexPath.row == 1 {
            //The user is selecting "Groups"
            performSegueWithIdentifier("GroupInvites", sender: self)
        }
        if indexPath.row == 2 {
            //The user is selecting "Send Feedback"
            performSegueWithIdentifier("Feedback", sender: self)
        }
        if indexPath.row == 3 {
            //The user is selecting "Settings"
            performSegueWithIdentifier("Settings", sender: self)
        }
        if indexPath.row == 4 {
            //The user is selecting "Squirrel Store"
            performSegueWithIdentifier("Squirrel Store", sender: self)
        }
    }
    
    override func viewDidAppear(animated: Bool) {
        super.viewDidAppear(animated)
        //Check to see if we need to show a new user tutorial screens first
        if PFUser.currentUser()!["newMoreTab"] as! Bool == true {
            //If new user, show them the tutorial screens
            performSegueWithIdentifier("NewUserScreens", sender: self)
        } else if PFUser.currentUser()!["hasSeenMoreTab"] as! Bool == false && PFUser.currentUser()!["hasBeenAskedForPush"] as! Bool == false {
            //The user hasn't been asked for push notifications and it's their first time seeing the more tab, so we ask them if they want to register for push notifications to see friend requests and group invites 
            let title = "Let Squirrel List Access Notifications?"
            let message = "You'll be alerted when people friend request you and invite you to groups."
            let alert = UIAlertController(title: title, message: message, preferredStyle: UIAlertControllerStyle.Alert)
            alert.addAction(UIAlertAction(title: "Not Now", style: .Default, handler: { (action: UIAlertAction) -> Void in
                alert.dismissViewControllerAnimated(true, completion: nil)
                PFUser.currentUser()!["hasSeenMoreTab"] = true
                PFUser.currentUser()!.save()
            }))
            alert.addAction(UIAlertAction(title: "Give Access", style: .Default, handler: { (action: UIAlertAction) -> Void in
                //We ask the user for push notification permission in chat because it's easier to explain why they might need it
                alert.dismissViewControllerAnimated(true, completion: nil)
                let notificationTypes: UIUserNotificationType = [UIUserNotificationType.Alert, UIUserNotificationType.Badge, UIUserNotificationType.Sound]
                let notificationSettings = UIUserNotificationSettings(forTypes: notificationTypes, categories: nil)
        
                UIApplication.sharedApplication().registerUserNotificationSettings(notificationSettings)
                UIApplication.sharedApplication().applicationIconBadgeNumber = 0
                PFUser.currentUser()!["hasSeenMoreTab"] = true
                PFUser.currentUser()!["hasBeenAskedForPush"] = true
                PFUser.currentUser()!.save()
            }))
        self.presentViewController(alert, animated: true, completion: nil)
        }
    }
    
    
    override func viewDidLoad() {
        super.viewDidLoad()
        if isNewUser == true {
            self.title = "Home"
        }
        if PFUser.currentUser()!["hasSeenMoreTab"] as? Bool == nil {
            //Then the logged in user hasn't had their data fetched before this first update, so we need to fetch and update their new fields
            PFUser.currentUser()!["hasSeenMoreTab"] = true
            PFUser.currentUser()!.save()
        }
        let userFriendsData = PFUser.currentUser()!["friendData"] as! PFObject
        userFriendsData.fetch()
        //We only user the pendingInviters field, since we just want the friends basge to show the number of people that have requested the logged in user
        let pendingFriends = userFriendsData["pendingInviters"] as! [String]
        if pendingFriends.count > 0 {
            friendsBadgeLabel.text = "\(pendingFriends.count)"
            friendsBadgeLabel.backgroundColor = UIColor.redColor()
            friendsBadgeLabel.layer.cornerRadius = 8
            friendsBadgeLabel.layer.masksToBounds = true
            friendsBadgeLabel.hidden = false
        } else {
            //The user doesn't have any pending friends, so we hide the badge 
            friendsBadgeLabel.hidden = true
        }
        let groupInvites = userFriendsData["groupInvites"] as? Int
        if groupInvites == nil {
            //The user hasn't had their userFriendsData model updated yet
            userFriendsData["groupInvites"] = 0
            userFriendsData.save()
            //No badges to show since we just updated their info from nil
            groupsBadgeLabel.hidden = true
        } else if groupInvites > 0 {
            groupsBadgeLabel.text = "\(groupInvites!)"
            groupsBadgeLabel.backgroundColor = UIColor.redColor()
            groupsBadgeLabel.layer.cornerRadius = 8
            groupsBadgeLabel.layer.masksToBounds = true
            groupsBadgeLabel.hidden = false
        } else {
            //The user doesn't have any pending friends, so we hide the badge 
            groupsBadgeLabel.hidden = true
        }
        self.tblOptions?.tableFooterView = UIView(frame: CGRectZero)
        //Customize navigation controller back button to my only the back symbol
        let backItem = UIBarButtonItem(title: "", style: UIBarButtonItemStyle.Plain, target: nil, action: nil)
        navigationItem.backBarButtonItem = backItem
        self.navigationController?.navigationBar.titleTextAttributes = [ NSFontAttributeName: UIFont(name: "BebasNeueBold", size: 26)!,  NSForegroundColorAttributeName: UIColor.whiteColor()]
    }
    
    
    //FriendsViewControllerDelegate function - updates the badge icon to reflect number of current pending friends
    func updateFriendBadges(controller: FriendsViewController, numOfBadges: Int) {
        if numOfBadges == 0 {
            friendsBadgeLabel.hidden = true
        } else {
            friendsBadgeLabel.text = "\(numOfBadges)"
            friendsBadgeLabel.backgroundColor = UIColor.redColor()
            friendsBadgeLabel.layer.cornerRadius = 8
            friendsBadgeLabel.layer.masksToBounds = true
        }
    }

    
    func updateGroupBadges(controller: NotificationsViewController, numOfBadges: Int) {
        if numOfBadges == 0 {
            groupsBadgeLabel.hidden = true
        } else {
            groupsBadgeLabel.text = "\(numOfBadges)"
            groupsBadgeLabel.backgroundColor = UIColor.redColor()
            groupsBadgeLabel.layer.cornerRadius = 8
            groupsBadgeLabel.layer.masksToBounds = true
        }
    }
    

    


}
