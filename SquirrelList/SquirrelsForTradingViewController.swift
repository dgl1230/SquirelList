//
//  SquirrelsForTradingViewController.swift
//  SquirrelList
//
//  Created by Denis Geary Lopez on 3/15/15.
//  Copyright (c) 2015 Frenvu Inc. All rights reserved.
//

import UIKit


protocol SquirrelsForTradeDelegate: class {

    func SquirrelForTradeDelegate(controller: SquirrelsForTradingViewController, selectedSquirrel: PFObject, desiredSquirrelOwnerTransfer: PFUser, desiredSquirrelTransfer: PFObject)
}


class SquirrelsForTradingViewController: UITableViewController {

    weak var delegate: SquirrelsForTradeDelegate?
    var squirrels = [PFObject]()
    
    //Need to have these two values to pass back to TradeViewController after I dismiss this VC. Might be able to change this depending upon the push option I choose in story board (modal vs push)
    var desiredSquirrel: PFObject?
    var desiredSquirrelOwner: PFUser?
    
    
    override func numberOfSectionsInTableView(tableView: UITableView) -> Int {
        return 1
    }
    
    override func tableView(tableView: UITableView, cellForRowAtIndexPath indexPath: NSIndexPath) -> UITableViewCell {
    
        let cell = tableView.dequeueReusableCellWithIdentifier("Cell", forIndexPath: indexPath) as SquirrelTableViewCell
        
        cell.squirrel = squirrels[indexPath.row]
        cell.username = PFUser.currentUser()["username"] as? String
        var first = cell.viewWithTag(1) as UILabel
        first.text = squirrels[indexPath.row]["first_name"].capitalizedString
        var last = cell.viewWithTag(5) as UILabel
        last.text = squirrels[indexPath.row]["last_name"].capitalizedString
        var ratingLabel = cell.viewWithTag(3) as UILabel
        ratingLabel.text = squirrels[indexPath.row]["avg_rating"] as? String
        
        return cell
    }
    
    
    override func tableView(tableView: UITableView, didSelectRowAtIndexPath indexPath: NSIndexPath) {
        delegate?.SquirrelForTradeDelegate(self, selectedSquirrel: squirrels[indexPath.row], desiredSquirrelOwnerTransfer: desiredSquirrelOwner!, desiredSquirrelTransfer: desiredSquirrel!)
        self.navigationController?.popViewControllerAnimated(true)
        
    }
    
    override func tableView(tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return squirrels.count
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        tableView.registerNib(UINib(nibName: "SquirrelTableViewCell", bundle: nil), forCellReuseIdentifier: "Cell")
        var query = PFQuery(className:"Squirrel")
        query.whereKey("owner", equalTo: PFUser.currentUser()["username"])
        query.findObjectsInBackgroundWithBlock({ (objects: [AnyObject]!, error: NSError!) -> Void in
            self.squirrels.removeAll(keepCapacity: true)
            for object in objects {
                var squirrel:PFObject = object as PFObject
                self.squirrels.append(squirrel)
            }
            self.tableView.reloadData()
        })
        

        
    }

   
}
