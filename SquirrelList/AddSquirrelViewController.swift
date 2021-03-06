//
//  AddSquirrelViewController.swift
//  SquirelList
//
//  Created by Denis Geary Lopez on 2/4/15.
//  Copyright (c) 2015 Frenvu Inc. All rights reserved.
//

import UIKit

@objc protocol AddSquirrelViewControllerDelegate: class {
    func createdSquirrel(controller: AddSquirrelViewController)
    optional func addSquirrelViewControllerDelegateErrorAlert(controller: AddSquirrelViewController, title: String, body: String)
    optional func addSquirrelUpdateLabels(controller: AddSquirrelViewController)
}


class AddSquirrelViewController: UITableViewController, UITextFieldDelegate {
    var activityIndicator: UIActivityIndicatorView = UIActivityIndicatorView()
    weak var delegate: AddSquirrelViewControllerDelegate?

    @IBOutlet weak var firstName: UITextField!
    @IBOutlet weak var lastName: UITextField!
    @IBOutlet weak var doneBarButton: UIBarButtonItem!
    
    /*
    @IBAction func done() {
        let first = firstName.text //as! String
        let last = lastName.text //as! String
        if first!.characters.count > 10 {
            displayErrorAlert("Their first name is too long!", error: "Please keep first names to a max of 10 characters.")
            return
        } else if last!.characters.count > 15 {
            displayErrorAlert("Their last name is too long!", error: "Please keep last names to a max of 15 characters.")
            return
        }
        //Check to make user didn't just enter spaces for either name 
        let spaces = NSCharacterSet(charactersInString: " ")
        if first!.stringByTrimmingCharactersInSet(spaces).characters.count == 0 || last!.stringByTrimmingCharactersInSet(spaces).characters.count == 0 {
            displayErrorAlert("That's not a name!", error: "Please provide letters (not whitespaces) for a Squirrel name. I expected better of you.")
            return
        }
        //We want to make sure users can't add a squirrel that starts or ends with a space or have numbers or weird punctuation
        let badSet: NSCharacterSet = NSCharacterSet(charactersInString: "!@#$%^&*()1234567890[]{}|;:<>,.?/_+=")
        if first!.rangeOfCharacterFromSet(badSet, options: [], range: nil) != nil || last!.rangeOfCharacterFromSet(badSet, options: [], range: nil) != nil {
                displayErrorAlert("No numbers or symbols!", error: "Stop trying to cheat the system, you animal.")
        } else {
                let trimmedFirst = first!.stringByTrimmingCharactersInSet(badSet)
                let trimmedLast = last!.stringByTrimmingCharactersInSet(badSet)
                let trimmedFirst2 = trimmedFirst.stringByTrimmingCharactersInSet(NSCharacterSet.whitespaceCharacterSet())
                let trimmedLast2 = trimmedLast.stringByTrimmingCharactersInSet(NSCharacterSet.whitespaceCharacterSet())
                //Global function that starts the loading animation and returns an array of [NVAcitivtyIndicatorView, UIView, UIView] so that we can pass these views into resumeInterActionEvents() later to suspend animation and dismiss the views
                let viewsArray = displayLoadingAnimator(self.view)
                let activityIndicatorView = viewsArray[0] as! NVActivityIndicatorView
                let container = viewsArray[1] as! UIView
                let loadingView = viewsArray[2] as! UIView
                createSquirrel(trimmedFirst2, last_name: trimmedLast2, activityIndicatorView: activityIndicatorView, container: container, loadingView: loadingView)
        }
        let priority = DISPATCH_QUEUE_PRIORITY_DEFAULT
        //We check in the background to make sure that Squirrel hasn't been recently created
        dispatch_async(dispatch_get_global_queue(priority, 0)) {
            let currentGroup = PFUser.currentUser()!["currentGroup"] as! PFObject

            //We fetch the currentGroup to guarantee that the user isn't about to create a squirrel that was just created by another user
                currentGroup.fetch()
                //We don't want to send push notifications to the logged in user, since the delegate is reloading the Squirrels tab for them
                //let users = (currentGroup["users"] as! [String]).filter{ $0 != PFUser.currentUser()!.username! }
                let squirrelNames = currentGroup["squirrelFullNames"] as! [String]
                let trimmedFirst = first!.stringByTrimmingCharactersInSet(badSet)
                let trimmedLast = last!.stringByTrimmingCharactersInSet(badSet)
                let trimmedFirst2 = trimmedFirst.stringByTrimmingCharactersInSet(NSCharacterSet.whitespaceCharacterSet())
                let trimmedLast2 = trimmedLast.stringByTrimmingCharactersInSet(NSCharacterSet.whitespaceCharacterSet())
                let squirrelName = "\(trimmedFirst2.lowercaseString) \(trimmedLast2.lowercaseString)"
                if (squirrelNames.indexOf(squirrelName) != nil) {
                    self.displayErrorAlert( "That Squirrel already exists!", error: "Try adding another squirrel instead, you monster.")
                }
        }
        
    }
    */
    
    @IBAction func done() {
        let first = firstName.text //as! String
        let last = lastName.text //as! String
        if first!.characters.count > 10 {
            displayErrorAlert("Their first name is too long!", error: "Please keep first names to a max of 10 characters.")
            return
        } else if last!.characters.count > 15 {
            displayErrorAlert("Their last name is too long!", error: "Please keep last names to a max of 15 characters.")
            return
        }
        //Check to make user didn't just enter spaces for either name 
        let spaces = NSCharacterSet(charactersInString: " ")
        if first!.stringByTrimmingCharactersInSet(spaces).characters.count == 0 || last!.stringByTrimmingCharactersInSet(spaces).characters.count == 0 {
            displayErrorAlert("That's not a name!", error: "Please provide letters (not whitespaces) for a Squirrel name. I expected better of you.")
            return
        }
        //We want to make sure users can't add a squirrel that starts or ends with a space or have numbers or weird punctuation
        let badSet: NSCharacterSet = NSCharacterSet(charactersInString: "!@#$%^&*()1234567890[]{}|;:<>,.?/_+=")
        if first!.rangeOfCharacterFromSet(badSet, options: [], range: nil) != nil || last!.rangeOfCharacterFromSet(badSet, options: [], range: nil) != nil {
                displayErrorAlert("No numbers or symbols!", error: "Stop trying to cheat the system, you animal.")
                return
        }
        LOGGED_IN_USER_SQUIRREL_SLOTS -= 1
        print("SQUIRREL SLOTS IS \(LOGGED_IN_USER_SQUIRREL_SLOTS)")
        //No current errors, so we run mostly everything else asynchonously
        let priority = DISPATCH_QUEUE_PRIORITY_DEFAULT
        dispatch_async(dispatch_get_global_queue(priority, 0)) {
            let currentGroup = PFUser.currentUser()!["currentGroup"] as! PFObject

            //We fetch the currentGroup to guarantee that the user isn't about to create a squirrel that was just created by another user
                currentGroup.fetch()
            let squirrelNames = currentGroup["squirrelFullNames"] as! [String]
            let trimmedFirst = first!.stringByTrimmingCharactersInSet(badSet)
            let trimmedLast = last!.stringByTrimmingCharactersInSet(badSet)
            let trimmedFirst2 = trimmedFirst.stringByTrimmingCharactersInSet(NSCharacterSet.whitespaceCharacterSet())
            let trimmedLast2 = trimmedLast.stringByTrimmingCharactersInSet(NSCharacterSet.whitespaceCharacterSet())
            let squirrelName = "\(trimmedFirst2.lowercaseString) \(trimmedLast2.lowercaseString)"
            if (squirrelNames.indexOf(squirrelName) != nil) {
                //We get an error if we change the UI in  a background thread
                dispatch_async(dispatch_get_main_queue()) {
                    LOGGED_IN_USER_SQUIRREL_SLOTS += 1
                    self.delegate!.addSquirrelViewControllerDelegateErrorAlert!(self, title: "That Squirrel already exists!", body: "Try adding another squirrel instead, you monster.")
                }
                return
            }
            //We create the Squirrel
            let newSquirrel = PFObject(className:"Squirrel")
            newSquirrel["first_name"] = trimmedFirst2
            newSquirrel["last_name"] = trimmedLast2
            newSquirrel["owner"] = PFUser.currentUser()!
            newSquirrel["raters"] = []
            newSquirrel["ratings"] = []
            newSquirrel["avg_rating"] = 0
            newSquirrel["group"] = PFUser.currentUser()!["currentGroup"]
            newSquirrel["ownerUsername"] = PFUser.currentUser()!.username
            newSquirrel["dropVotes"] = 0
            newSquirrel["droppers"] = []
            let picture = UIImage(named: "Squirrel_Profile_Pic")
            let imageData = UIImagePNGRepresentation(picture!)
            let imageFile = PFFile(name: "Squirrel_Profile_Pic", data: imageData!)
            newSquirrel["picture"] = imageFile
            newSquirrel.save()
            let group = PFUser.currentUser()!["currentGroup"] as! PFObject
            group.addObject(newSquirrel.objectId!, forKey: "squirrels")
            
            let newSquirrelSlots = getNewArrayToSave(group["squirrelSlots"] as! [String], username: PFUser.currentUser()!.username!, newInfo: String(LOGGED_IN_USER_SQUIRREL_SLOTS))
            group["squirrelSlots"] = newSquirrelSlots
            group.addObject(squirrelName, forKey: "squirrelFullNames")
            group.save()
            //Reloads the parent squirrelTabViewController
            self.delegate!.createdSquirrel(self)
        }
        delegate!.addSquirrelUpdateLabels!(self)
        self.navigationController!.popViewControllerAnimated(true)
        
        
    }
    
    
    //Creates the Squirrel, after first checking to make sure that the same Squirrel name doesn't exist already. Assumes that the Squirrel has already passed checks to make sure there are no white spaces, numbers, punctuations, etc. and that the first and last name have a correct length 
    func createSquirrel(first_name: String, last_name: String, activityIndicatorView: NVActivityIndicatorView, container: UIView, loadingView: UIView) {
                let squirrelName = "\(first_name.lowercaseString) \(last_name.lowercaseString)"
                    //We create the Squirrel 
                    let newSquirrel = PFObject(className:"Squirrel")
                    newSquirrel["first_name"] = first_name
                    newSquirrel["last_name"] = last_name
                    newSquirrel["owner"] = PFUser.currentUser()!
                    newSquirrel["raters"] = []
                    newSquirrel["ratings"] = []
                    newSquirrel["avg_rating"] = 0
                    newSquirrel["group"] = PFUser.currentUser()!["currentGroup"]
                    newSquirrel["ownerUsername"] = PFUser.currentUser()!.username
                    newSquirrel["dropVotes"] = 0
                    newSquirrel["droppers"] = []
                    let picture = UIImage(named: "Squirrel_Profile_Pic")
                    let imageData = UIImagePNGRepresentation(picture!)
                    let imageFile = PFFile(name: "Squirrel_Profile_Pic", data: imageData!)
                    newSquirrel["picture"] = imageFile
        
                    newSquirrel.saveInBackgroundWithBlock {
                        (success: Bool, error: NSError?) -> Void in
                            if (success) {
                                let group = PFUser.currentUser()!["currentGroup"] as! PFObject
                                group.addObject(newSquirrel.objectId!, forKey: "squirrels")
                
                                LOGGED_IN_USER_SQUIRREL_SLOTS -= 1
                                let newSquirrelSlots = getNewArrayToSave(group["squirrelSlots"] as! [String], username: PFUser.currentUser()!.username!, newInfo: String(LOGGED_IN_USER_SQUIRREL_SLOTS))
                                group["squirrelSlots"] = newSquirrelSlots
                                group.addObject(squirrelName, forKey: "squirrelFullNames")
                                group.save()
                                self.navigationController!.popViewControllerAnimated(true)
                                //Reloads the parent squirrelViewController
                                self.delegate!.createdSquirrel(self)
                        }
                        //Regardless of whether an error occurs, we need to resume interaction 
                        //Global function that stops the loading animation and dismisses the views it is attached to
                        //resumeInteractionEvents(activityIndicatorView, container: container, loadingView: loadingView)
                        UIApplication.sharedApplication().endIgnoringInteractionEvents()
    
                    }
    
    }
    
    /* Parameters: Title, which is the title of the alert, and error, which is the error that the user should see in the UIAlertController
    What this does: displays a UIAlertController with a specified error and dismisses it when they press OK
    */
    func displayErrorAlert(title: String, error: String) {
        let alert = UIAlertController(title: title, message: error, preferredStyle: UIAlertControllerStyle.Alert)
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
        firstName.autocorrectionType = UITextAutocorrectionType.No
        lastName.autocorrectionType = UITextAutocorrectionType.No
        
    }
    
    //Should be its own extension 
    func textField(textField: UITextField, shouldChangeCharactersInRange range: NSRange, replacementString string: String) -> Bool {
            var untouchedName: NSString = ""
            var oldName: NSString = ""
            var newName: NSString = ""
            if textField.tag == 1 {
                //they are typing in the first name field
                untouchedName = lastName.text!
                oldName = firstName.text!
                newName = oldName.stringByReplacingCharactersInRange(range, withString: string)
            } else {
                //they are typing in the last name field 
                untouchedName = firstName.text!
                oldName = lastName.text!
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
