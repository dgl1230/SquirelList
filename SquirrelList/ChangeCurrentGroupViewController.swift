//
//  ChangeCurrentGroupViewController.swift
//  SquirrelList
//
//  Created by Denis Geary Lopez on 4/11/15.
//  Copyright (c) 2015 Frenvu Inc. All rights reserved.
//


//This protocol is for reloading the parent view controller after a new group has been selected
protocol ChangeCurrentGroupViewControllerDelegate: class {
    func viewWillBeDismissed(controller: ChangeCurrentGroupViewController)
}

import UIKit

class ChangeCurrentGroupViewController: PFQueryTableViewController {
    
    //Optional for holding which cell should have a checkmark
    var checkMarkedCellIndex: NSIndexPath?
    var delegate: ChangeCurrentGroupViewControllerDelegate?
    
    
    @IBOutlet weak var doneButton: UIButton!
    
    
    @IBAction func done(sender: AnyObject) {
        PFUser.currentUser()!.save()
        delegate?.viewWillBeDismissed(self)
        self.dismissViewControllerAnimated(true, completion: nil)
        
    }

    // Initialise the PFQueryTable tableview
    override init(style: UITableViewStyle, className: String!) {
        super.init(style: style, className: className)
    }
	
    required init(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
  
        // Configure the PFQueryTableView
        self.parseClassName = "Group"
        self.textKey = "name"
        self.pullToRefreshEnabled = true
        self.paginationEnabled = false
    }
    
    
    // Define the query that will provide the data for the table view
    override func queryForTable() -> PFQuery {
        var query = PFQuery(className: "Group")
        query.whereKey("objectId", containedIn: PFUser.currentUser()!["groups"]! as! [String])
        query.orderByDescending("name")
        return query
    }
    
    
    override func tableView(tableView: UITableView, cellForRowAtIndexPath indexPath: NSIndexPath) -> UITableViewCell {
        var cell = tableView.dequeueReusableCellWithIdentifier("Cell", forIndexPath: indexPath) as! PFTableViewCell
        var name = cell.viewWithTag(1) as! UILabel
        name.text = objects![indexPath.row]["name"] as? String
        if objects![indexPath.row].objectId == PFUser.currentUser()!["currentGroup"]!.objectId {
            cell.accessoryType = .Checkmark
            checkMarkedCellIndex = indexPath
        }
        return cell
    }

    
    override func tableView(tableView: UITableView, didSelectRowAtIndexPath indexPath: NSIndexPath) {
        let cell = tableView.cellForRowAtIndexPath(indexPath)
        cell?.accessoryType = .Checkmark
        //Remove checkmark from old cell
        let oldCheckMarkedCell = tableView.cellForRowAtIndexPath(checkMarkedCellIndex!)
        oldCheckMarkedCell?.accessoryType = .None
        //Update checkMarkedCellIndex
        checkMarkedCellIndex = indexPath
        //Update user's currentGroups
        PFUser.currentUser()!["currentGroup"] = objects![indexPath.row] as! PFObject
    }
    
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        //Setting the doneButton with the 'fa-check-circle' button
        doneButton.titleLabel?.font = UIFont(name: "FontAwesome", size: 30)
        doneButton.setTitle("\u{f058}", forState: .Normal)
        
    }


   
}
