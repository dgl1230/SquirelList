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
        let numOfUsers = (group!["users"] as! [String]).count
        let squirrelSlots = (numOfUsers - 1) + 3
        let userGroupData = PFObject(className: "UserGroupData")
        userGroupData["user"] = PFUser.currentUser()!
        userGroupData["group"] = group!
        userGroupData["acorns"] = 750
        userGroupData["squirrelSlots"] = squirrelSlots
        userGroupData["lastVisit"] = NSDate()
        userGroupData["numOfGroupUsers"] = numOfUsers + 1
        userGroupData["canRerate"] = false
        userGroupData["cumulativeDaysVisited"] = 0
        userGroupData["groupName"] = group!["name"] as! String
        group!.saveInBackgroundWithBlock { (didSave: Bool, error: NSError?) -> Void in
            if error == nil {
                userGroupData.save()
                //Alert the inviter that the logged in user has accepted their group invite
                let pushQuery = PFInstallation.query()
                pushQuery!.whereKey("username", equalTo: self.inviterName!)
                let push = PFPush()
                push.setQuery(pushQuery)
                let groupName = self.group!["name"] as? String
                let message = "\(PFUser.currentUser()!.username!) has accepted your invitation to join \(groupName!)"
                let inviteMessage = message as NSString
                let pushDict = ["alert": inviteMessage, "badge":"increment", "sounds":"", "content-available": 1]
                push.setData(pushDict)
                push.sendPushInBackgroundWithBlock(nil)
                PFUser.currentUser()!.save()
                self.groupInvite!.delete()
                if PFUser.currentUser()!["currentGroup"] == nil {
                    //Then the user is new, and they need a current group
                    PFUser.currentUser()!["currentGroup"] = self.group!
                    //The user is new and needs a currentGroupData
                    PFUser.currentUser()!["currentGroupData"] = userGroupData
                    //The user can now access all tabs, since they have a current group
                    let appDelegate = UIApplication.sharedApplication().delegate as! AppDelegate
                    appDelegate.window!.rootViewController = HomeTabViewController()
                    appDelegate.window!.makeKeyAndVisible()
                } else {
                    self.dismissViewControllerAnimated(true, completion: nil)
                    //Reload the notificationsViewController
                    self.delegate?.reloadAfterGroupInviteDecision!(self)
                }
            } else {
                //There was an error, and we display an alert via the global function to the user
                displayAlert(self, "Ooops", "There's been an error. Would you mind trying again?")
            }
        }
        
        
        
            

        /*
        group!.saveInBackgroundWithBlock { (didSave: Bool, error: NSError?) -> Void in
            if error == nil {
                println(18)
                PFUser.currentUser()!.save()
                println(19)
                println("Group invite is \(self.groupInvite)")
                self.groupInvite!.delete()
                println(20)
                if PFUser.currentUser()!["currentGroup"] == nil {
                    println(21)
                    //Then the user is new, and they need a current group
                    PFUser.currentUser()!["currentGroup"] = self.group!
                    println(22)
                    //The user is new and needs a currentGroupData
                    PFUser.currentUser()!["currentGroupData"] = userGroupData
                    println(23)
                    PFUser.currentUser()!.save()
                    println(24)
                    //The user can now access all tabs, since they have a current group
                    let appDelegate = UIApplication.sharedApplication().delegate as! AppDelegate
                    println(25)
                    appDelegate.window!.rootViewController = HomeTabViewController()
                    println(26)
                    appDelegate.window!.makeKeyAndVisible()
                    println(27)
                }
                //Alert the inviter that the logged in user has accepted their group invite
                let pushQuery = PFInstallation.query()
                println(28)
                pushQuery!.whereKey("username", equalTo: self.inviterName!)
                println(29)
                let push = PFPush()
                println(30)
                push.setQuery(pushQuery)
                println(31)
                let groupName = self.group!["name"] as? String
                println(32)
                let message = "\(PFUser.currentUser()!.username!) has accepted your invitation to join \(groupName!)"
                println(33)
                let inviteMessage = message as NSString
                println(34)
                let pushDict = ["alert": inviteMessage, "badge":"increment", "sounds":"", "content-available": 1]
                println(35)
                push.setData(pushDict)
                println(36)
                push.sendPushInBackgroundWithBlock(nil)
                println(37)
                println(37.5)
                self.dismissViewControllerAnimated(true, completion: nil)
                println(38)
                //Reload the notificationsViewController
                self.delegate?.reloadAfterGroupInviteDecision!(self)
                println(39)
            } else {
                //There was an error and we should alert the user with an alert using the global function
                println(40)
                displayAlert(self, "Ooops", "There was an error. Would you mind trying again?")
                println(41)
            }
            
        }
        */
        
    }
    
    
    @IBAction func decline(sender: AnyObject) {
        groupInvite!.delete()
        //Reload the notificationsViewController
        dismissViewControllerAnimated(true, completion: nil)
        delegate?.reloadAfterGroupInviteDecision!(self)
    
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        group = groupInvite!["group"] as? PFObject
        //Need to fetch to update values of group object
        group?.fetch()

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
