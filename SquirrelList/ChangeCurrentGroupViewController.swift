//
//  ChangeCurrentGroupViewController.swift
//  SquirrelList
//
//  Created by Denis Geary Lopez on 4/11/15.
//  Copyright (c) 2015 Frenvu Inc. All rights reserved.
//


import UIKit

class ChangeCurrentGroupViewController: PFQueryTableViewController {
    
    
    //this variable is for checking to see when the user presses done, if they have stayed on the same current group. If they have, then we don't want to send notifications to reload everything
    var currentGroup = PFUser.currentUser()!["currentGroup"]! as! PFObject
    
    

    // Initialise the PFQueryTable tableview
    override init(style: UITableViewStyle, className: String!) {
        super.init(style: style, className: className)
    }
	
    required init(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)!
  
        // Configure the PFQueryTableView
        self.parseClassName = "Group"
        self.textKey = "name"
        self.pullToRefreshEnabled = true
        self.paginationEnabled = false
    }
    
    
    // Define the query that will provide the data for the table view
    override func queryForTable() -> PFQuery {
        let query = PFQuery(className: "Group")
        query.whereKey("objectId", containedIn: PFUser.currentUser()!["groups"]! as! [String])
        query.orderByAscending("name")
        return query
    }
    
    
    override func tableView(tableView: UITableView, cellForRowAtIndexPath indexPath: NSIndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCellWithIdentifier("Cell", forIndexPath: indexPath) as! UsersCellTableViewCell
        //var name = cell.viewWithTag(1) as! UILabel
        cell.usernameLabel.text = objects![indexPath.row]["name"] as? String
        cell.usernameLabel.font = UIFont(name: "BebasNeue-Thin", size: 30)
        return cell
    }
    
    
    override func tableView(tableView: UITableView, commitEditingStyle editingStyle: UITableViewCellEditingStyle, forRowAtIndexPath indexPath: NSIndexPath) {
        if editingStyle == UITableViewCellEditingStyle.Delete {
            //Give the user a warning to verify that they want to leave the group
            let groups = PFUser.currentUser()!["groups"] as! [String]
            if groups.count == 1 {
                //This is their only group, and they can't leave it then
                let message = "This is your only group! You can only leave it if you have at least one other group to go to."
                let alert = UIAlertController(title: "", message: message, preferredStyle: UIAlertControllerStyle.Alert)
                alert.addAction(UIAlertAction(title: "Ok", style: .Default, handler:  { (action: UIAlertAction) in
                    return
                }))
                self.presentViewController(alert, animated: true, completion: nil)
                return
            }
            
            let group = objects![indexPath.row] as! PFObject
            let users = group["users"] as! [String]
            if users.count == 1 {
                let message = "Are you sure you want to leave this group? You're the only member right now, so leaving this group will delete it."
                let alert = UIAlertController(title: "", message: message, preferredStyle: UIAlertControllerStyle.Alert)
                alert.addAction(UIAlertAction(title: "Cancel", style: .Cancel, handler: { (action: UIAlertAction) in
                    alert.dismissViewControllerAnimated(true, completion: nil)
                }))
                alert.addAction(UIAlertAction(title: "Leave Group", style: .Default, handler:  { (action: UIAlertAction) in
                     //Global function that starts the loading animation and returns an array of [NVAcitivtyIndicatorView, UIView, UIView] so that we can pass these views into resumeInterActionEvents() later to suspend animation and dismiss the views
                    let viewsArray = displayLoadingAnimator(self.view)
                    let activityIndicatorView = viewsArray[0] as! NVActivityIndicatorView
                    let container = viewsArray[1] as! UIView
                    let loadingView = viewsArray[2] as! UIView
                    
                    
                    PFUser.currentUser()!.removeObject(group.objectId!, forKey: "groups")
                    PFUser.currentUser()!.save()
                    group.removeObject(PFUser.currentUser()!.username!, forKey: "users")
                    group.save()
                    self.tableView.reloadRowsAtIndexPaths([indexPath], withRowAnimation: UITableViewRowAnimation.Automatic)
                    self.viewDidLoad()
                    //Global function that stops the loading animation and dismisses the views it is attached to
                    resumeInteractionEvents(activityIndicatorView, container: container, loadingView: loadingView)
                }))
                self.presentViewController(alert, animated: true, completion: nil)
            } else {
                //The user will leave the group and we will update their squirrels
                let message = "Are you sure you want to leave this group? You'll lose all of your Squirrels in this group and won't be able to re-join unless you're invited back."
                let alert = UIAlertController(title: "", message: message, preferredStyle: UIAlertControllerStyle.Alert)
                alert.addAction(UIAlertAction(title: "Cancel", style: .Cancel, handler: { (action: UIAlertAction) in
                    alert.dismissViewControllerAnimated(true, completion: nil)
                }))
                alert.addAction(UIAlertAction(title: "Leave Group", style: .Default, handler:  { (action: UIAlertAction) in
                //Global function that starts the loading animation and returns an array of [NVAcitivtyIndicatorView, UIView, UIView] so that we can pass these views into resumeInterActionEvents() later to suspend animation and dismiss the views
                let viewsArray = displayLoadingAnimator(self.view)
                let activityIndicatorView = viewsArray[0] as! NVActivityIndicatorView
                let container = viewsArray[1] as! UIView
                let loadingView = viewsArray[2] as! UIView
                dispatch_async(dispatch_get_main_queue()) {
                    
                    let squirrelQuery = PFQuery(className: "Squirrel")
                    squirrelQuery.whereKey("objectId", containedIn: group["squirrels"] as! [String])
                    squirrelQuery.whereKey("owner", equalTo: PFUser.currentUser()!)
                    squirrelQuery.findObjectsInBackgroundWithBlock({ (squirrels: [AnyObject]?, error: NSError?) -> Void in
                        if error == nil {
                            for object in squirrels! {
                                    let squirrel = object as! PFObject
                                    squirrel.removeObjectForKey("ownerUsername")
                                    squirrel.removeObjectForKey("owner")
                                    squirrel.save()
                                }
                            }
                        })

                        let acorns = getFullUserInfo(group["acorns"] as! [String], username: PFUser.currentUser()!.username!)
                        let squirrelSlots = getFullUserInfo(group["squirrelSlots"] as! [String], username: PFUser.currentUser()!.username!)
                        let cumulativeDays = getFullUserInfo(group["cumulativeDays"] as! [String], username: PFUser.currentUser()!.username!)
                        let usersOnLastVist = getFullUserInfo(group["usersOnLastVisit"] as! [String], username: PFUser.currentUser()!.username!)
                        let lastVisit = getFullUserInfo(group["lastVisits"] as! [String], username: PFUser.currentUser()!.username!)
                        let rerate = getFullUserInfo(group["rerates"] as! [String], username: PFUser.currentUser()!.username!)
                        //Remove user from the group's users and remove all of the user's other fields
                        group.removeObject(PFUser.currentUser()!.username!, forKey: "users")
                        group.removeObject(acorns, forKey: "acorns")
                        group.removeObject(squirrelSlots, forKey: "squirrelSlots")
                        group.removeObject(cumulativeDays, forKey: "cumulativeDays")
                        group.removeObject(usersOnLastVist, forKey: "usersOnLastVisit")
                        group.removeObject(lastVisit, forKey: "lastVisits")
                        group.removeObject(rerate, forKey: "rerates")
                        //Remve the group from the user's group
                        PFUser.currentUser()!.removeObject(group.objectId!, forKey: "groups")
                        group.save()
                        PFUser.currentUser()!.save()
                        self.tableView.reloadRowsAtIndexPaths([indexPath], withRowAnimation: UITableViewRowAnimation.Automatic)
                        self.viewDidLoad()
                        //Global function that stops the loading animation and dismisses the views it is attached to
                        resumeInteractionEvents(activityIndicatorView, container: container, loadingView: loadingView)
                    }
                        
                }))
                self.presentViewController(alert, animated: true, completion: nil)
            }
        }
    }


    
    override func tableView(tableView: UITableView, didSelectRowAtIndexPath indexPath: NSIndexPath) {
        //Update the current group variable
        currentGroup = objects![indexPath.row] as! PFObject
        //We need to compare object ids to see if the user selected the group that is already their current group. If they do this, we don't need to send alerts to reload everything
        let userCurrentGroup = PFUser.currentUser()!["currentGroup"] as! PFObject
        if currentGroup.objectId != userCurrentGroup.objectId {
            //Global function that starts the loading animation and returns an array of [NVAcitivtyIndicatorView, UIView, UIView] so that we can pass these views into resumeInterActionEvents() later to suspend animation and dismiss the views
                let viewsArray = displayLoadingAnimator(self.view)
                _ = viewsArray[0] as! NVActivityIndicatorView
                _ = viewsArray[1] as! UIView
                _ = viewsArray[2] as! UIView
                dispatch_async(dispatch_get_main_queue()) {
            //We only want to reload everything if the user hasn't selected their same currentGroup
            PFUser.currentUser()!["currentGroup"] = self.currentGroup
            PFUser.currentUser()!.save()
            //UsersViewController, SquirrelViewController, MessagesViewController, SearchUsersViewController(for adding friends to group, and NotificationsViewController(for trade proposals) all new to be reloaded when their views appear
            NSNotificationCenter.defaultCenter().postNotificationName(reloadNotificationKey, object: nil)
            UIApplication.sharedApplication().endIgnoringInteractionEvents()
            }

        }
        self.dismissViewControllerAnimated(true, completion: nil)
    }
    
    
    //Customize the delete button on swipe left
    override func tableView(tableView: UITableView, editActionsForRowAtIndexPath indexPath: NSIndexPath) -> [UITableViewRowAction]? {
        let deleteButton = UITableViewRowAction(style: .Default, title: "Leave Group", handler: { (action, indexPath) in
        self.tableView.dataSource?.tableView?(
            self.tableView,
            commitEditingStyle: .Delete,
            forRowAtIndexPath: indexPath
        )
        return
    })
        return [deleteButton]
    }
    
    
    override func viewDidLoad() {
        super.viewDidLoad()
        //Register the UsersCellTableViewCell for use in the UserViewController tableView
        tableView.registerNib(UINib(nibName: "UsersCellTableViewCell", bundle: nil), forCellReuseIdentifier: "Cell")
    }


   
}
