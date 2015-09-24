//
//  ChatHolderViewController.swift
//  SquirrelList
//
//  Created by Denis Geary Lopez on 4/24/15.
//  Copyright (c) 2015 Frenvu Inc. All rights reserved.
//

//This view controller merely holds the containerView, which is MessagesViewController

import UIKit

class ChatHolderViewController: UIViewController {
    
    override func viewDidAppear(animated: Bool) {
        super.viewDidAppear(animated)
        //If the user has changed their group, we want to make sure the title is always up to date
        let groupName = PFUser.currentUser()!["currentGroup"]!["name"] as? String
        self.navigationItem.title = "\(groupName!) Chat"
    }
    

    override func viewDidLoad() {
        super.viewDidLoad()
        
        self.navigationController?.navigationBar.titleTextAttributes = [ NSFontAttributeName: UIFont(name: "BebasNeueBold", size: 26)!,  NSForegroundColorAttributeName: UIColor.whiteColor()]

        //Check to see whether we should prompt the user to enable push notifications
        let hasSeenChat = PFUser.currentUser()!["hasSeenChat"] as! Bool
        let hasBeenAskedForPush = PFUser.currentUser()!["hasBeenAskedForPush"] as! Bool
        if  (hasBeenAskedForPush == false) && (hasSeenChat == false) {
            //This is the first time that the user has seen the chat and they haven't enabled push notification, so we can prompt them
            let title = "Let Squirrel List Access Notifications?"
            let message = "This lets you receive messages in real time."
            let alert = UIAlertController(title: title, message: message, preferredStyle: UIAlertControllerStyle.Alert)
            alert.addAction(UIAlertAction(title: "Not Now", style: .Default, handler: { (action: UIAlertAction) -> Void in
                alert.dismissViewControllerAnimated(true, completion: nil)
                PFUser.currentUser()!["hasSeenChat"] = true
                PFUser.currentUser()!.save()
            }))
            alert.addAction(UIAlertAction(title: "Give Access", style: .Default, handler: { (action: UIAlertAction) -> Void in
                //We ask the user for push notification permission in chat because it's easier to explain why they might need it
                alert.dismissViewControllerAnimated(true, completion: nil)
                let notificationTypes: UIUserNotificationType = [UIUserNotificationType.Alert, UIUserNotificationType.Badge, UIUserNotificationType.Sound]
                let notificationSettings = UIUserNotificationSettings(forTypes: notificationTypes, categories: nil)
        
                UIApplication.sharedApplication().registerUserNotificationSettings(notificationSettings)
                UIApplication.sharedApplication().applicationIconBadgeNumber = 0
                PFUser.currentUser()!["hasSeenChat"] = true
                PFUser.currentUser()!["hasBeenAskedForPush"] = true
                PFUser.currentUser()!.save()
            }))
            
           self.presentViewController(alert, animated: true, completion: nil)
        }

    }


}
