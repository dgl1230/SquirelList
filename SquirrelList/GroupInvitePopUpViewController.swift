//
//  GroupInvitePopUpViewController.swift
//  SquirrelList
//
//  Created by Denis Geary Lopez on 4/9/15.
//  Copyright (c) 2015 Frenvu Inc. All rights reserved.
//

import UIKit

//Delegate for reloading notificationsViewController after the user has either accepted or declined group invitation
@objc protocol GroupInvitePopUpDelegate: class {
    optional func reloadAfterGroupInviteDecision(controller: GroupInvitePopUpViewController)
}

class GroupInvitePopUpViewController: PopUpViewController {

    var inviterName: String?
    var group: PFObject?
    var groupInvite: PFObject?
    var delegate: GroupInvitePopUpDelegate?
    

    @IBOutlet weak var acceptButton: UIButton!
    @IBOutlet weak var declineButton: UIButton!
    @IBOutlet weak var inviterLabel: UILabel!
    @IBOutlet weak var groupLabel: UILabel!
    
    
    @IBAction func accept(sender: AnyObject) {
        group!.addObject(PFUser.currentUser()!.username!, forKey: "users")
        group!.removeObject(PFUser.currentUser()!.username!, forKey: "pendingUsers")
        PFUser.currentUser()!.addObject(group!.objectId!, forKey: "groups")
        //We add one to take into consideration the logged in user who is accepting
        let numOfUsers = (group!["users"] as! [String]).count + 1
        let squirrelSlots = numOfUsers + 2
        group!.addObject("\(PFUser.currentUser()!.username!):750", forKey: "acorns")
        group!.addObject("\(PFUser.currentUser()!.username!):\(squirrelSlots)", forKey: "squirrelSlots")
        group!.addObject("\(PFUser.currentUser()!.username!):1", forKey: "cumulativeDays")
        group!.addObject("\(PFUser.currentUser()!.username!):\(numOfUsers)", forKey: "usersOnLastVisit")
        group!.addObject("\(PFUser.currentUser()!.username!):0", forKey: "rerates")
        let today = NSDate()
        let formatter = NSDateFormatter()
        formatter.dateFormat = "yyyy-MM-dd"
        let todayString = formatter.stringFromDate(today)
        group!.addObject("\(PFUser.currentUser()!.username!):\(todayString)", forKey: "lastVisits")
        group!.saveInBackgroundWithBlock { (didSave: Bool, error: NSError?) -> Void in
            if error == nil {
                //Alert the inviter that the logged in user has accepted their group invite
                let inviterName = self.groupInvite!["inviter"] as! String
                let groupName = self.group!["name"] as? String
                
                let message = "\(PFUser.currentUser()!.username!) has accepted your invitation to join \(groupName!)"
                sendPushNotifications(0, message: message, type: "acceptedGroupInvite", users: [inviterName])
                PFUser.currentUser()!.save()
                self.groupInvite!.delete()
                if PFUser.currentUser()!["currentGroup"] == nil {
                    let userFriendsData = PFUser.currentUser()!["friendData"] as! PFObject
                    userFriendsData.fetch()
                    var groupInvites = userFriendsData["groupInvites"] as! Int
                    groupInvites -= 1
                    userFriendsData["groupInvites"] = groupInvites
                    userFriendsData.save()
                    //Then the user is new, and they need a current group
                    PFUser.currentUser()!["currentGroup"] = self.group!
                    //The user can now access all tabs, since they have a current group
                    let appDelegate = UIApplication.sharedApplication().delegate as! AppDelegate
                    appDelegate.window!.rootViewController = HomeTabViewController()
                    appDelegate.window!.makeKeyAndVisible()
                } else {
                    self.dismissViewControllerAnimated(true, completion: nil)
                    //Reload the notificationsViewController
                    self.delegate!.reloadAfterGroupInviteDecision!(self)
                }
            } else {
                //There was an error, and we display an alert via the global function to the user
                displayAlert(self, title: "Ooops", message: "There's been an error. Would you mind trying again?")
            }
        }
        
    }
    
    
    @IBAction func decline(sender: AnyObject) {
        groupInvite!.delete()
        let priority = DISPATCH_QUEUE_PRIORITY_DEFAULT
        dispatch_async(dispatch_get_global_queue(priority, 0)) {
            //So that the user can be invited again if they decline
            self.group!.removeObject(PFUser.currentUser()!.username!, forKey: "pendingUsers")
            self.group!.save()
        }
        self.delegate!.reloadAfterGroupInviteDecision!(self)
        //Reload the notificationsViewController
        dismissViewControllerAnimated(true, completion: nil)
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        group = groupInvite!["group"] as? PFObject
        //Need to fetch to update values of group object
        group!.fetch()

        inviterLabel.text = inviterName
        groupLabel.text = group!["name"] as? String
        inviterName = groupInvite!["inviter"] as? String
        //Give buttons rounded edges
        acceptButton.layer.cornerRadius = 5
        acceptButton.layer.masksToBounds = true
        declineButton.layer.cornerRadius = 5
        declineButton.layer.masksToBounds = true
    }


    


}
