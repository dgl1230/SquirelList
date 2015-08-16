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
        println(0)
        group!.addObject(PFUser.currentUser()!.username!, forKey: "users")
        group!.removeObject(PFUser.currentUser()!.username!, forKey: "pendingUsers")
        PFUser.currentUser()!.addObject(group!.objectId!, forKey: "groups")
        println(1)
        let numOfUsers = (group!["users"] as! [String]).count
        println(2)
        let squirrelSlots = (numOfUsers - 1) + 3
        println(3)
        let userGroupData = PFObject(className: "UserGroupData")
        println(4)
        userGroupData["user"] = PFUser.currentUser()!
        println(5)
        userGroupData["group"] = group!
        println(6)
        userGroupData["acorns"] = 1000
        println(7)
        userGroupData["squirrelSlots"] = squirrelSlots
        println(8)
        userGroupData["lastVisit"] = NSDate()
        println(9)
        userGroupData["numOfGroupUsers"] = numOfUsers + 1
        println(10)
        userGroupData["canRerate"] = false
        println(11)
        userGroupData["cumulativeDaysVisited"] = 0
        println(12)
        userGroupData["groupName"] = group!["name"] as! String
        println(13)
        userGroupData.save()
        println(14)
        group!.save()
        println(15)
        PFUser.currentUser()!.save()
        println(16)
        groupInvite!.delete()
        println(17)
        if PFUser.currentUser()!["currentGroup"] == nil {
            //Then the user is new, and they need a current group
            PFUser.currentUser()!["currentGroup"] = group!
            //The user is new and needs a currentGroupData
            PFUser.currentUser()!["currentGroupData"] = userGroupData
            PFUser.currentUser()!.save()
            //The user can now access all tabs, since they have a current group
            let appDelegate = UIApplication.sharedApplication().delegate as! AppDelegate
            appDelegate.window!.rootViewController = HomeTabViewController()
            appDelegate.window!.makeKeyAndVisible()
        }
        //Alert the inviter that the logged in user has accepted their group invite 
        let pushQuery = PFInstallation.query()
        pushQuery!.whereKey("username", equalTo: inviterName!)
        let push = PFPush()
        push.setQuery(pushQuery)
        let groupName = group!["name"] as? String
        let message = "\(PFUser.currentUser()!.username!) has accepted your invitation to join \(groupName!)"
        let inviteMessage = message as NSString
        let pushDict = ["alert": inviteMessage, "badge":"increment", "sounds":"", "content-available": 1]
        push.setData(pushDict)
        push.sendPushInBackgroundWithBlock(nil)
        dismissViewControllerAnimated(true, completion: nil)
        //Reload the notificationsViewController
        delegate?.reloadAfterGroupInviteDecision!(self)
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
