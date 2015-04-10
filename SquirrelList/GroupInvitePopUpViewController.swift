//
//  GroupInvitePopUpViewController.swift
//  SquirrelList
//
//  Created by Denis Geary Lopez on 4/9/15.
//  Copyright (c) 2015 Frenvu Inc. All rights reserved.
//

import UIKit

class GroupInvitePopUpViewController: PopUpViewController {

    var inviterName: String?
    var group: PFObject?
    var groupInvite: PFObject?
    

    @IBOutlet weak var inviterLabel: UILabel!
    @IBOutlet weak var groupLabel: UILabel!
    
    
    @IBAction func accept(sender: AnyObject) {
        group!.addObject(PFUser.currentUser().objectId, forKey: "userIDs")
        PFUser.currentUser()["groups"].addObject(group!.objectId, forKey: "groups")
        group!.save()
        PFUser.currentUser().save()
        groupInvite!.delete()
        dismissViewControllerAnimated(true, completion: nil)
    }
    
    
    @IBAction func decline(sender: AnyObject) {
        groupInvite!.delete()
        dismissViewControllerAnimated(true, completion: nil)
        //Delegate reload
    
    }

    override func viewDidLoad() {
        super.viewDidLoad()

        inviterLabel.text = inviterName
        groupLabel.text = group!["name"] as? String
        group = groupInvite!["group"] as? PFObject
        inviterName = groupInvite!["inviter"] as? String
    }


    


}
