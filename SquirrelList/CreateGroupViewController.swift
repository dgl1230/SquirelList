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
        if groupNameTextField.text!.characters.count > 15 {
            let alertController = UIAlertController(title: "", message: "Please limit the name of the group to no more than 15 characters", preferredStyle: UIAlertControllerStyle.Alert)
                alertController.addAction(UIAlertAction(title: "Ok", style: UIAlertActionStyle.Default, handler: nil))
            self.presentViewController(alertController, animated: true, completion: nil)
            return
        }
        let group = PFObject(className: "Group")
        group["name"] = groupNameTextField.text //as NSString
        group.addObject(PFUser.currentUser()!.username!, forKey: "users")
        group["pendingUsers"] = []
        group["squirrels"] = []
        group["squirrelFullNames"] = []
        group["acorns"] = ["\(PFUser.currentUser()!.username!):750"]
        group["squirrelSlots"] = ["\(PFUser.currentUser()!.username!):3"]
        group["cumulativeDays"] = ["\(PFUser.currentUser()!.username!):1"]
        group["usersOnLastVisit"] = ["\(PFUser.currentUser()!.username!):1"]
        group["rerates"] = ["\(PFUser.currentUser()!.username!):0"]
        
        let today = NSDate()
        let formatter = NSDateFormatter()
        formatter.dateFormat = "yyyy-MM-dd"
        let todayString = formatter.stringFromDate(today)
        group["lastVisits"] = ["\(PFUser.currentUser()!.username!):\(todayString)"]
        group.save()
        let currentUserGroup = PFUser.currentUser()!["currentGroup"] as? PFObject
        PFUser.currentUser()!.addObject(group.objectId!, forKey: "groups")
        PFUser.currentUser()!["currentGroup"] = group
        PFUser.currentUser()!.save()

        //UsersViewController, SquirrelViewController, ChatDetailViewController, SearchUsersViewController(for adding friends to group, and NotificationsViewController(for trade proposals) all need to be reloaded when their views appear 
        NSNotificationCenter.defaultCenter().postNotificationName(reloadNotificationKey, object: self)


        if currentUserGroup == nil {
            //The user can now access all tabs, since they now have a current group
            let appDelegate = UIApplication.sharedApplication().delegate as! AppDelegate
            appDelegate.window!.rootViewController = HomeTabViewController()
            appDelegate.window!.makeKeyAndVisible()
        } else {
            self.navigationController?.popViewControllerAnimated(true)
        }

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

            oldText = groupNameTextField.text!
            newText = oldText.stringByReplacingCharactersInRange(range, withString: string)
        
            if newText.length > 0 {
                createGroupButton.enabled = true
            } else {
                createGroupButton.enabled = false
            }
            return true 
    }



}
