//
//  SettingsViewController.swift
//  SquirrelList
//
//  Created by Denis Geary Lopez on 3/29/15.
//  Copyright (c) 2015 Frenvu Inc. All rights reserved.
//

import UIKit

class SettingsViewController: UITableViewController {


    @IBOutlet weak var nameLabel: UILabel!
    @IBOutlet weak var usernameLabel: UILabel!
    
    
    
    override func prepareForSegue(segue: UIStoryboardSegue, sender: AnyObject?) {
        if segue.identifier == "Name" {
            let controller = segue.destinationViewController as! ChangeInfoController
            controller.infoBeingChanged = "name"
        }  else if segue.identifier == "Privacy Policy" {
            let controller = segue.destinationViewController as! PoliciesViewController
            controller.policy  = "Privacy Policy"
        } else if segue.identifier == "Terms of Service" {
            let controller = segue.destinationViewController as! PoliciesViewController
            controller.policy = "Terms of Service"
        }
    }
    
    
     
    override func tableView(tableView: UITableView, didSelectRowAtIndexPath indexPath: NSIndexPath) {
        var cell: UITableViewCell = tableView.cellForRowAtIndexPath(indexPath)!
        if cell.tag == 1 {
            //The user is selecting the "name" row
            self.performSegueWithIdentifier("Name", sender: self)
        } else if cell.tag == 3 {
            //The user is selecting "Privacy Policy"
            self.performSegueWithIdentifier("Privacy Policy", sender: self)
        } else if cell.tag == 4 {
            //The user is selecting "Terms of Service"
            self.performSegueWithIdentifier("Terms of Service", sender: self)
        }
        if cell.tag == 5 {
            //They clicked the "Log Out" row
            var message = "Are you sure you want to log out?"
            var alert = UIAlertController(title: "", message: message, preferredStyle: UIAlertControllerStyle.Alert)
            alert.addAction(UIAlertAction(title: "Cancel", style: .Cancel, handler: { (action: UIAlertAction!) in
                alert.dismissViewControllerAnimated(true, completion: nil)
            }))
            alert.addAction(UIAlertAction(title: "Log Out", style: .Default, handler:  { (action: UIAlertAction!) in
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
        //Customize navigation controller back button to my only the back symbol
        let backItem = UIBarButtonItem(title: "", style: UIBarButtonItemStyle.Plain, target: nil, action: nil)
        navigationItem.backBarButtonItem = backItem
        
        let name = PFUser.currentUser()!["name"] as? String
        println(name)
        if name != nil {
            nameLabel.text = name!
        } else {
            nameLabel.text = ""
        }

        
        }
    

}
