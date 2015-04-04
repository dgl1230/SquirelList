//
//  FindFreindsTableViewCell.swift
//  SquirrelList
//
//  Created by Denis Geary Lopez on 3/31/15.
//  Copyright (c) 2015 Frenvu Inc. All rights reserved.
//

import UIKit

class FindFriendsTableViewCell: PFTableViewCell {


    @IBOutlet weak var addFriendButton: UIButton!
    @IBOutlet weak var nameLabel: UILabel!
    
    @IBAction func addFriend(sender: AnyObject) {
        //Setting the addFriendButton with the 'fa-plus-square-o' button
        addFriendButton.titleLabel?.font = UIFont(name: "FontAwesome", size: 20)
        addFriendButton.setTitle("\u{f196}", forState: .Normal)
    }
    
}
