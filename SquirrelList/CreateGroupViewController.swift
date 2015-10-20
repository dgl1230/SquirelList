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
    @IBOutlet weak var anonymousChatEnabledButton: UIButton!
    @IBOutlet weak var publicGroupEnabledButton: UIButton!
    
    //Variable for keeping track of whether the group's chat should be anonymous
    var anonymousChat = false
    //Variable for keeping track of whether the group is public 
    var isPublic = false
    
    @IBAction func createGroup(sender: AnyObject) {
        if groupNameTextField.text!.characters.count > 15 {
            let alertController = UIAlertController(title: "", message: "Please limit the name of the group to no more than 15 characters", preferredStyle: UIAlertControllerStyle.Alert)
                alertController.addAction(UIAlertAction(title: "Ok", style: UIAlertActionStyle.Default, handler: nil))
            self.presentViewController(alertController, animated: true, completion: nil)
            return
        }
        //If they are making a public group, we make sure a group with that name doesn't exist already
        if isPublic == true {
            let existanceQueryCheck = PFQuery(className: "Group")
            existanceQueryCheck.whereKey("lowercaseName", equalTo: groupNameTextField.text!.lowercaseString)
            let results = existanceQueryCheck.getFirstObject()
            if results != nil {
                //That name exists already
                displayAlert(self, title: "", message: "There's already a public group with that name :/")
                return
            } else if groupNameTextField.text!.characters.count < 3 {
                //To avoid awkwardly showing all groups that start with one or two letters, we only want users to be able to create groups with at least 3 characters. We also don't show results in the search bar for searches with one or two characters. 
                displayAlert(self, title: "", message: "If you're making a public group, please have it be at least three characters")
                return
            }
        }
        let group = PFObject(className: "Group")
        group["name"] = groupNameTextField.text //as NSString
        group["lowercaseName"] = groupNameTextField.text!.lowercaseString
        group.addObject(PFUser.currentUser()!.username!, forKey: "users")
        group["pendingUsers"] = []
        group["squirrels"] = []
        group["squirrelFullNames"] = []
        group["acorns"] = ["\(PFUser.currentUser()!.username!):750"]
        group["squirrelSlots"] = ["\(PFUser.currentUser()!.username!):3"]
        group["cumulativeDays"] = ["\(PFUser.currentUser()!.username!):1"]
        group["usersOnLastVisit"] = ["\(PFUser.currentUser()!.username!):1"]
        group["rerates"] = ["\(PFUser.currentUser()!.username!):0"]
        group["anonymousChatEnabled"] = anonymousChat
        group["isPublic"] = isPublic
        
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

    @IBAction func anonymousChatEnabled(sender: AnyObject) {
        if anonymousChat == false {
            //Set it equal to true
            anonymousChat = true
            //Set the anonymousChatEnabledd button to 'fa-square-check-o'
            anonymousChatEnabledButton.titleLabel!.font = UIFont(name: "FontAwesome", size: 20)
            anonymousChatEnabledButton.setTitle("\u{f046}", forState: .Normal)
        } else {
            //The box was checked, and now they are unchecking it
            anonymousChat = false
            //Set the anonymousChatEnabledd button to 'fa-square-o'
            anonymousChatEnabledButton.titleLabel!.font = UIFont(name: "FontAwesome", size: 20)
            anonymousChatEnabledButton.setTitle("\u{f096}", forState: .Normal)
        }
    }
    
    @IBAction func publicOptionEnabled(sender: AnyObject) {
        if isPublic == false {
            //Set it equal to true
            isPublic = true
            //Set the publicGroupEnabledButton to 'fa-square-check-o'
            publicGroupEnabledButton.titleLabel!.font = UIFont(name: "FontAwesome", size: 20)
            publicGroupEnabledButton.setTitle("\u{f046}", forState: .Normal)
        } else {
            //The box was checked, and now they are unchecking it
            isPublic = false
            //Set the publicGroupEnabledButton to 'fa-square-o'
            publicGroupEnabledButton.titleLabel!.font = UIFont(name: "FontAwesome", size: 20)
            publicGroupEnabledButton.setTitle("\u{f096}", forState: .Normal)
        }
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        //Set the createGroupButton to 'fa-check-circle'
        createGroupButton.setTitleTextAttributes([NSFontAttributeName: UIFont(name: "FontAwesome", size: 30)!], forState: UIControlState.Normal)
        createGroupButton.title = "\u{f058}"
        createGroupButton.tintColor = UIColor.orangeColor()
        groupNameTextField.delegate = self
        //Set the anonymousChatEnabledd button to 'fa-square-o'
        anonymousChatEnabledButton.titleLabel!.font = UIFont(name: "FontAwesome", size: 20)
        anonymousChatEnabledButton.setTitle("\u{f096}", forState: .Normal)
        //Set the publicGroupEnabledButton to 'fa-square-o'
        publicGroupEnabledButton.titleLabel!.font = UIFont(name: "FontAwesome", size: 20)
        publicGroupEnabledButton.setTitle("\u{f096}", forState: .Normal)
    
        
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
