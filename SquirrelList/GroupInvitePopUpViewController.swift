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
        group!.addObject(PFUser.currentUser()!.username!, forKey: "userIDs")
        PFUser.currentUser()!.addObject(group!.objectId!, forKey: "groups")
        let numOfUsers = (group!["userIDs"] as! [String]).count
        let squirrelSlots = numOfUsers + 5
        let userGroupData = PFObject(className: "UserGroupData")
        userGroupData["user"] = PFUser.currentUser()!
        userGroupData["group"] = group!
        userGroupData["acorns"] = 1000
        userGroupData["squirrelSlots"] = squirrelSlots
        userGroupData["lastVisit"] = NSDate()
        userGroupData["numOfGroupUsers"] = numOfUsers + 1
        userGroupData["canRerate"] = false
        userGroupData["cumulativeDaysVisited"] = 0
        userGroupData["groupName"] = group!["name"] as! String
        userGroupData.save()
        group!.save()
        PFUser.currentUser()!.save()
        groupInvite!.delete()
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
        //Reload the notificationsViewController
        delegate?.reloadAfterGroupInviteDecision!(self)
        dismissViewControllerAnimated(true, completion: nil)
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
