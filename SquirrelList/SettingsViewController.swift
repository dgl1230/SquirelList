//
//  SettingsViewController.swift
//  SquirrelList
//
//  Created by Denis Geary Lopez on 3/29/15.
//  Copyright (c) 2015 Frenvu Inc. All rights reserved.
//

import UIKit

class SettingsViewController: UITableViewController, ChangeInfoViewControllerDelegate {

    @IBOutlet weak var emailLabel: UILabel!
    @IBOutlet weak var nameLabel: UILabel!
    @IBOutlet weak var usernameLabel: UILabel!
    
    
    
    override func prepareForSegue(segue: UIStoryboardSegue, sender: AnyObject?) {
        if segue.identifier == "Name" {
            let controller = segue.destinationViewController as! ChangeInfoController
            controller.infoBeingChanged = "name"
            controller.delegate = self
        }  else if segue.identifier == "Privacy Policy" {
            let controller = segue.destinationViewController as! PoliciesViewController
            controller.policy  = "Privacy Policy"
        } else if segue.identifier == "Terms of Service" {
            let controller = segue.destinationViewController as! PoliciesViewController
            controller.policy = "Terms of Service"
        } else if segue.identifier == "Email" {
            let controller = segue.destinationViewController as! ChangeInfoController
            controller.infoBeingChanged = "email"
            controller.delegate = self
        } else if segue.identifier == "Report" {
            let controller = segue.destinationViewController as! ChangeInfoController
            controller.infoBeingChanged = "report"
            controller.delegate = self
        }
    }
    
    
     
    override func tableView(tableView: UITableView, didSelectRowAtIndexPath indexPath: NSIndexPath) {
        let cell: UITableViewCell = tableView.cellForRowAtIndexPath(indexPath)!
        if cell.tag == 2 {
            //The user is selecting the "name" row
            self.performSegueWithIdentifier("Name", sender: self)
        } else if cell.tag == 3 {
            //The user is selecting the "email" row
            self.performSegueWithIdentifier("Email", sender: self)
        } else if cell.tag == 4 {
            //The user is selecting "Privacy Policy"
            self.performSegueWithIdentifier("Privacy Policy", sender: self)
        } else if cell.tag == 5 {
            //The user is selecting "Terms of Service"
            self.performSegueWithIdentifier("Terms of Service", sender: self)
        } else if cell.tag == 6 {
            //The user is selecting "Report"
            self.performSegueWithIdentifier("Report", sender: self)
        }
        if cell.tag == 7 {
            //They clicked the "Log Out" row
            let message = "Are you sure you want to log out?"
            let alert = UIAlertController(title: "", message: message, preferredStyle: UIAlertControllerStyle.Alert)
            alert.addAction(UIAlertAction(title: "Cancel", style: .Cancel, handler: { (action: UIAlertAction) in
                alert.dismissViewControllerAnimated(true, completion: nil)
            }))
            alert.addAction(UIAlertAction(title: "Log Out", style: .Default, handler:  { (action: UIAlertAction) in
                //Let SquirrelViewController and SquirrelStoreController know that global variables should be reloaded
                LOGGED_IN_USER_ACORNS = 123456789
                LOGGED_IN_USER_SQUIRREL_SLOTS = 123456789
                LOGGED_IN_USER_RERATES = 123456789
                let appDelegate = UIApplication.sharedApplication().delegate as! AppDelegate
                let loginRegisterStoryBoard = UIStoryboard(name: "Login-Register", bundle: nil)
                let homeController = loginRegisterStoryBoard.instantiateViewControllerWithIdentifier("Home") as! HomeViewController
                appDelegate.window!.rootViewController = homeController
                appDelegate.window!.makeKeyAndVisible()
                PFUser.logOut()
            }))
            
            
            self.presentViewController(alert, animated: true, completion: nil)
        }
        
    
    }

    

    override func viewDidLoad() {
        super.viewDidLoad()
        usernameLabel.text = PFUser.currentUser()!.username
        //Customize navigation controller back button to only the back symbol
        let backItem = UIBarButtonItem(title: "", style: UIBarButtonItemStyle.Plain, target: nil, action: nil)
        navigationItem.backBarButtonItem = backItem
        
        let name = PFUser.currentUser()!["name"] as? String
        if name != nil {
            nameLabel.text = name!
        } else {
            nameLabel.text = ""
        }
        //For some reason accessing email via currentUser()!.email results in an error
        let email = PFUser.currentUser()!["email"] as? String
        if email!.rangeOfString("squirrellist") != nil {
            //This is our rachet, fake email for all users and we should not display it
            emailLabel.text = ""
        } else {
            emailLabel.text = email
        }
        
        }
    
    //ChangeInfoViewControllerDelegate function - reloads so we can display the newly saved information
    func finishedSaving(controller: ChangeInfoController) {
        self.viewDidLoad()
    }
    
    

}
