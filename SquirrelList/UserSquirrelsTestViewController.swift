//
//  UserSquirrelsTestViewController.swift
//  SquirrelList
//
//  Created by Denis Geary Lopez on 3/24/15.
//  Copyright (c) 2015 Frenvu Inc. All rights reserved.
//

import UIKit

class UserSquirrelsTestViewController: PopUpViewController {

    var squirrels = [PFObject]?

    //Optional value for determining if user is going through their Squirrels to select a trade
    var currentlyTrading: Bool?
    //Squirrel that the logged in user wants in return for one of their squirrels
    var desiredSquirrel: PFObject?
    //The owner of the squirrel that the logged in user wants
    var desiredSquirrelOwner: PFUser?
    
    
     override func tableView(tableView: UITableView, cellForRowAtIndexPath indexPath: NSIndexPath, object: PFObject) ->PFTableViewCell {
            var cell = tableView.dequeueReusableCellWithIdentifier("Cell", forIndexPath: indexPath) as SquirrelTableViewCell
            var first = cell.viewWithTag(1) as UILabel
            first.text = object["first_name"].capitalizedString
            var last = cell.viewWithTag(5) as UILabel
            last.text = object["last_name"].capitalizedString
            var ratingLabel = cell.viewWithTag(3) as UILabel
            ratingLabel.text = object["avg_rating"] as? String
            return cell 
    }
   
}
