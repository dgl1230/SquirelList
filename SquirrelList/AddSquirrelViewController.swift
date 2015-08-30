//
//  AddSquirrelViewController.swift
//  SquirelList
//
//  Created by Denis Geary Lopez on 2/4/15.
//  Copyright (c) 2015 Frenvu Inc. All rights reserved.
//

import UIKit

protocol AddSquirrelViewControllerDelegate: class {
    func createdSquirrel(controller: AddSquirrelViewController)
}


class AddSquirrelViewController: UITableViewController, UITextFieldDelegate {
    var activityIndicator: UIActivityIndicatorView = UIActivityIndicatorView()
    weak var delegate: AddSquirrelViewControllerDelegate?

    @IBOutlet weak var firstName: UITextField!
    @IBOutlet weak var lastName: UITextField!
    @IBOutlet weak var doneBarButton: UIBarButtonItem!
    
    
    @IBAction func done() {
        let first = firstName.text as String
        let last = lastName.text as String
        if count(first) > 10 {
            displayErrorAlert("Their first name is too long!", error: "Please keep first names to a max of 10 characters.")
            return
        } else if count(last) > 15 {
            displayErrorAlert("Their last name is too long!", error: "Please keep last names to a max of 15 characters.")
            return
        }
        //Check to make user didn't just enter spaces for either name 
        let spaces = NSCharacterSet(charactersInString: " ")
        if count(first.stringByTrimmingCharactersInSet(spaces)) == 0 || count(last.stringByTrimmingCharactersInSet(spaces)) == 0 {
            displayErrorAlert("That's not a name!", error: "Please provide letters (not whitespaces) for a Squirrel name. I expected better of you.")
            return
        }
        //We want to make sure users can't add a squirrel that starts or ends with a space or have numbers or weird punctuation
        let badSet: NSCharacterSet = NSCharacterSet(charactersInString: "!@#$%^&*()1234567890[]{}|;:<>,.?/_+=")
        if first.rangeOfCharacterFromSet(badSet, options: nil, range: nil) != nil || last.rangeOfCharacterFromSet(badSet, options: nil, range: nil) != nil {
                displayErrorAlert("No numbers or symbols!", error: "Stop trying to cheat the system, you animal.")
        } else {
                let trimmedFirst = first.stringByTrimmingCharactersInSet(badSet)
                let trimmedLast = last.stringByTrimmingCharactersInSet(badSet)
                let trimmedFirst2 = trimmedFirst.stringByTrimmingCharactersInSet(NSCharacterSet.whitespaceCharacterSet())
                let trimmedLast2 = trimmedLast.stringByTrimmingCharactersInSet(NSCharacterSet.whitespaceCharacterSet())
            
                let currentGroup = PFUser.currentUser()!["currentGroup"] as! PFObject
                //We fetch the currentGroup to guarantee that the user isn't about to create a squirrel that was just created by another user
                currentGroup.fetch()
                //We don't want to send push notifications to the logged in user, since the delegate is reloading the Squirrels tab for them
                let users = (currentGroup["users"] as! [String]).filter{ $0 != PFUser.currentUser()!.username! }
                let squirrelNames = currentGroup["squirrelFullNames"] as! [String]
            
                let squirrelName = "\(trimmedFirst2.lowercaseString) \(trimmedLast2.lowercaseString)"
                if (find(squirrelNames, squirrelName) != nil) {
                    self.displayErrorAlert( "That Squirrel already exists!", error: "Try adding another squirrel instead, you monster.")
                    
                } else {
                    //We create the Squirrel 
                    var newSquirrel = PFObject(className:"Squirrel")
                    newSquirrel["first_name"] = firstName.text
                    newSquirrel["last_name"] = lastName.text
                    newSquirrel["owner"] = PFUser.currentUser()!
                    newSquirrel["raters"] = []
                    newSquirrel["ratings"] = []
                    newSquirrel["avg_rating"] = 0
                    newSquirrel["group"] = PFUser.currentUser()!["currentGroup"]
                    newSquirrel["ownerUsername"] = PFUser.currentUser()!.username
                    newSquirrel["dropVotes"] = 0
                    newSquirrel["droppers"] = []
                    let picture = UIImage(named: "Squirrel_Profile_Pic")
                    let imageData = UIImagePNGRepresentation(picture)
                    let imageFile = PFFile(name: "Squirrel_Profile_Pic", data: imageData)
                    newSquirrel["picture"] = imageFile
        
                    newSquirrel.saveInBackgroundWithBlock {
                        (success: Bool, error: NSError?) -> Void in
                            if (success) {
                                var group = PFUser.currentUser()!["currentGroup"] as! PFObject
                                group.addObject(newSquirrel.objectId!, forKey: "squirrels")
                
                                LOGGED_IN_USER_SQUIRREL_SLOTS -= 1
                                let newSquirrelSlots = getNewArrayToSave(group["squirrelSlots"] as! [String], PFUser.currentUser()!.username!, String(LOGGED_IN_USER_SQUIRREL_SLOTS))
                                group["squirrelSlots"] = newSquirrelSlots
                                group.addObject(squirrelName, forKey: "squirrelFullNames")
                                group.save()
                                //Send silent push notifications for other users to have their Squirrel tab refresh
                                sendPushNotifications(0, "", "reloadSquirrels", users)
                                self.dismissViewControllerAnimated(true, completion: nil)
                                //Reloads the parent squirrelViewController
                            self.delegate!.createdSquirrel(self)
                            self.navigationController!.popViewControllerAnimated(true)
                        }
    
                    }

                }
        }
    }
    
    /* Parameters: Title, which is the title of the alert, and error, which is the error that the user should see in the UIAlertController
    What this does: displays a UIAlertController with a specified error and dismisses it when they press OK
    */
    func displayErrorAlert(title: String, error: String) {
        var alert = UIAlertController(title: title, message: error, preferredStyle: UIAlertControllerStyle.Alert)
        alert.addAction(UIAlertAction(title: "OK", style: .Default, handler: { action in
            self.dismissViewControllerAnimated(true, completion: nil)
        }))
        self.presentViewController(alert, animated: true, completion: nil)
    }
    
    override func tableView(tableView: UITableView, heightForRowAtIndexPath indexPath: NSIndexPath) -> CGFloat {
        return 44
    }
    
    override func tableView(tableView: UITableView, willSelectRowAtIndexPath indexPath: NSIndexPath) -> NSIndexPath? {
        return nil
    }
    
    override func viewWillAppear(animated: Bool) {
        super.viewWillAppear(animated)
        firstName.becomeFirstResponder()
    }
    
    override func viewDidLoad() {
        //Set the doneBarButton to 'fa-check-circle'
        doneBarButton.setTitleTextAttributes([NSFontAttributeName: UIFont(name: "FontAwesome", size: 30)!], forState: UIControlState.Normal)
        doneBarButton.title = "\u{f058}"
        doneBarButton.tintColor = UIColor.orangeColor()
    }
    
    //Should be its own extension 
    func textField(textField: UITextField, shouldChangeCharactersInRange range: NSRange, replacementString string: String) -> Bool {
            var untouchedName: NSString = ""
            var oldName: NSString = ""
            var newName: NSString = ""
            if textField.tag == 1 {
                //they are typing in the first name field
                untouchedName = lastName.text
                oldName = firstName.text
                newName = oldName.stringByReplacingCharactersInRange(range, withString: string)
            } else {
                //they are typing in the last name field 
                untouchedName = firstName.text
                oldName = lastName.text
                newName = oldName.stringByReplacingCharactersInRange(range, withString: string)
            }
        
            if newName.length > 0 && untouchedName.length > 0 {
                doneBarButton.enabled = true
            } else {
                doneBarButton.enabled = false
            }
            return true 
    }


    
}
