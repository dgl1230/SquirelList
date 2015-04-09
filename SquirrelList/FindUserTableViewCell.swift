//
//  FindFreindsTableViewCell.swift
//  SquirrelList
//
//  Created by Denis Geary Lopez on 3/31/15.
//  Copyright (c) 2015 Frenvu Inc. All rights reserved.
//

import UIKit

class FindUserTableViewCell: PFTableViewCell {


    @IBOutlet weak var addButton: UIButton!
    @IBOutlet weak var nameLabel: UILabel!


    @IBAction func add(sender: AnyObject) {
        //Setting the addButton with the 'fa-plus-square-o' button
        addButton.titleLabel?.font = UIFont(name: "FontAwesome", size: 20)
        addButton.setTitle("\u{f196}", forState: .Normal)
    }
    
}
