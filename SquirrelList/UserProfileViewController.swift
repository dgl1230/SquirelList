//
//  UserProfileViewController.swift
//  SquirrelList
//
//  Created by Denis Geary Lopez on 3/9/15.
//  Copyright (c) 2015 Frenvu Inc. All rights reserved.
//

import UIKit

class UserProfileViewController: UIViewController {
    
    //Optional for determining if user is going to trade proposals or invites, depending on button pushed
    var typeOfNotifcation: String?


    @IBOutlet weak var firstNameLabel: UILabel!
    @IBOutlet weak var lastNameLabel: UILabel!
    @IBOutlet weak var usernameLabel: UILabel!



    @IBAction func editProfile(sender: AnyObject) {
        self.performSegueWithIdentifier("EditProfile", sender: self)
    }
    
    
    @IBAction func seeInvites(sender: AnyObject) {
        typeOfNotifcation = "invite"
        self.performSegueWithIdentifier("userNotifications", sender: self)
    }
    
        

    @IBAction func logout(sender: AnyObject) {
        PFUser.logOut()
        self.dismissViewControllerAnimated(true, completion: nil)
    }
    
    
    override func prepareForSegue(segue: UIStoryboardSegue, sender: AnyObject?) {
        if segue.identifier == "EditProfile" {
            let controller = segue.destinationViewController as EditProfileViewController
            //controller.delegate = self
        }
        if segue.identifier == "userNotifications" {
            let navigationController = segue.destinationViewController as UINavigationController
            let controller = navigationController.topViewController as NotificationsViewController
            controller.typeOfNotification = typeOfNotifcation!
        }
        if segue.identifier == "pfQueryTest" {
            let navigationController = segue.destinationViewController as UINavigationController
            let controller = navigationController.topViewController as SquirrelViewController
            //controller.typeOfNotification = typeOfNotifcation!
        }


    }

    override func viewDidLoad() {
        super.viewDidLoad()
        var currentUser = PFUser.currentUser()
        if currentUser["first_name"] != nil {
            firstNameLabel.text = currentUser["first_name"] as? String
        }
        if currentUser["last_name"] != nil {
            lastNameLabel.text = currentUser["last_name"] as? String
        }
        if currentUser["username"] != nil {
            usernameLabel.text = currentUser["username"] as? String
        }
        
    }

    
    

    /*
    // MARK: - Navigation

    // In a storyboard-based application, you will often want to do a little preparation before navigation
    override func prepareForSegue(segue: UIStoryboardSegue, sender: AnyObject?) {
        // Get the new view controller using segue.destinationViewController.
        // Pass the selected object to the new view controller.
    }
    */

}
