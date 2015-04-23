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
        var group = PFObject(className: "Group")
        group["name"] = groupNameTextField.text as NSString
        group.addObject(PFUser.currentUser()!.objectId!, forKey: "userIDs")
        //Need to add the current user's squirrel list ID eventually as well
        group.save()
        PFUser.currentUser()!.addObject(group.objectId!, forKey: "groups")
        PFUser.currentUser()!["currentGroup"] = group
        PFUser.currentUser()!.save()
        //UsersViewController, SquirrelViewController, ChatDetailViewController, SearchUsersViewController(for adding friends to group, and NotificationsViewController(for trade proposals) all new to be reloaded when their views appear 
        NSNotificationCenter.defaultCenter().postNotificationName(reloadNotificationKey, object: self)
        self.navigationController?.popViewControllerAnimated(true)    
    }
    override func viewDidLoad() {
        super.viewDidLoad()
        //Set the createGroupButton to 'fa-check-circle'
        createGroupButton.setTitleTextAttributes([NSFontAttributeName: UIFont(name: "FontAwesome", size: 30)!], forState: UIControlState.Normal)
        createGroupButton.title = "\u{f058}"
        createGroupButton.tintColor = UIColor.whiteColor()
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
