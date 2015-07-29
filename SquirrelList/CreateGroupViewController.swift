//
//  CreateGroupViewController.swift
//  SquirrelList
//
//  Created by Denis Geary Lopez on 4/9/15.
//  Copyright (c) 2015 Frenvu Inc. All rights reserved.
//

import UIKit

class CreateGroupViewController: UITableViewController, UITextFieldDelegate {

    @IBOutlet weak var createGroupButton: UIBarButtonItem!
    @IBOutlet weak var groupNameTextField: UITextField!
    
    @IBAction func createGroup(sender: AnyObject) {
        if count(groupNameTextField.text) > 15 {
            let alertController = UIAlertController(title: "", message: "Please limit the name of the group to no more than 15 characters", preferredStyle: UIAlertControllerStyle.Alert)
                alertController.addAction(UIAlertAction(title: "Ok", style: UIAlertActionStyle.Default, handler: nil))
            self.presentViewController(alertController, animated: true, completion: nil)
            return
        }
        var group = PFObject(className: "Group")
        group["name"] = groupNameTextField.text as NSString
        group.addObject(PFUser.currentUser()!.username!, forKey: "userIDs")
        group["pendingUsers"] = []
        group["squirrels"] = []
        //Need to add the current user's squirrel list ID eventually as well
        group.save()
        
        let userGroupData = PFObject(className: "UserGroupData")
        userGroupData["user"] = PFUser.currentUser()!
        userGroupData["group"] = group
        userGroupData["acorns"] = 1000
        userGroupData["squirrelSlots"] = 5
        userGroupData["canRerate"] = false
        userGroupData["lastVisit"] = NSDate()
        userGroupData["numOfGroupUsers"] = 1
        userGroupData["cumulativeDaysVisited"] = 1
        userGroupData["groupName"] = groupNameTextField.text as NSString
        userGroupData.save()


        if PFUser.currentUser()!["currentGroup"] == nil {
            //The user can now access all tabs, since they now have a current group
            let appDelegate = UIApplication.sharedApplication().delegate as! AppDelegate
            appDelegate.window!.rootViewController = HomeTabViewController()
            appDelegate.window!.makeKeyAndVisible()
        }
        
        PFUser.currentUser()!.addObject(group.objectId!, forKey: "groups")
        PFUser.currentUser()!["currentGroupData"] = userGroupData
        PFUser.currentUser()!["currentGroup"] = group
        PFUser.currentUser()!.save()
        
 
        //UsersViewController, SquirrelViewController, ChatDetailViewController, SearchUsersViewController(for adding friends to group, and NotificationsViewController(for trade proposals) all need to be reloaded when their views appear 
            NSNotificationCenter.defaultCenter().postNotificationName(reloadNotificationKey, object: self)
        self.navigationController?.popViewControllerAnimated(true)    
    }
    override func viewDidLoad() {
        super.viewDidLoad()
        //Set the createGroupButton to 'fa-check-circle'
        createGroupButton.setTitleTextAttributes([NSFontAttributeName: UIFont(name: "FontAwesome", size: 30)!], forState: UIControlState.Normal)
        createGroupButton.title = "\u{f058}"
        createGroupButton.tintColor = UIColor.orangeColor()
        groupNameTextField.delegate = self
    }
    
    
    //Should be its own extension 
    func textField(textField: UITextField, shouldChangeCharactersInRange range: NSRange, replacementString string: String) -> Bool {
            var oldText: NSString = ""
            var newText: NSString = ""

            oldText = groupNameTextField.text
            newText = oldText.stringByReplacingCharactersInRange(range, withString: string)
        
            if newText.length > 0 {
                createGroupButton.enabled = true
            } else {
                createGroupButton.enabled = false
            }
            return true 
    }



}
