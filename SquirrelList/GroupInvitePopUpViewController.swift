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
        group!.addObject(PFUser.currentUser()!.objectId!, forKey: "userIDs")
        PFUser.currentUser()!.addObject(group!.objectId!, forKey: "groups")
        group!.save()
        PFUser.currentUser()!.save()
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
        group = groupInvite!["group"] as? PFObject
        //Need to fetch to update values of group object
        group?.fetch()

        inviterLabel.text = inviterName
        groupLabel.text = group!["name"] as? String
        inviterName = groupInvite!["inviter"] as? String
    }


    


}
