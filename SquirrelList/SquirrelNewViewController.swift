//
//  SquirrelNewViewController.swift
//  SquirrelList
//
//  Created by Denis Geary Lopez on 3/23/15.
//  Copyright (c) 2015 Frenvu Inc. All rights reserved.
//

import UIKit

class SquirrelNewViewController: PFQueryTableViewController, AddSquirrelViewControllerDelegate, SquirrelDetailViewControllerDelegate {

    // Initialise the PFQueryTable tableview
    override init!(style: UITableViewStyle, className: String!) {
        super.init(style: style, className: className)
    }
	
    required init(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
  
        // Configure the PFQueryTableView
        self.parseClassName = "Squirrel"
        self.textKey = "first_name"
        self.pullToRefreshEnabled = true
        self.paginationEnabled = false
    }
    
    // Define the query that will provide the data for the table view
    override func queryForTable() -> PFQuery! {
        var query = PFQuery(className: "Squirrel")
        query.orderByAscending("last_name")
        return query
    }
    
    
    //override func tableView(tableView: UITableView, cellForRowAtIndexPath indexPath: NSIndexPath) -> UITableViewCell
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
    
    override func viewDidLoad() {
        super.viewDidLoad()
        tableView.registerNib(UINib(nibName: "SquirrelTableViewCell", bundle: nil), forCellReuseIdentifier: "Cell")
    }
   
   
   
   //should be made into its own extension 
    func addSquirrelViewControllerDidCancel(controller: AddSquirrelViewController) {
        dismissViewControllerAnimated(true, completion: nil)
    }
   
    
    //Should also be made into its own extension
    func addSquirrelViewController(controller: AddSquirrelViewController, didFinishAddingFirstName firstName: NSString, didFinishAddingLastName lastName: NSString) {

        var newSquirrel = PFObject(className:"Squirrel")
        newSquirrel["first_name"] = firstName
        newSquirrel["last_name"] = lastName
        newSquirrel["owner"] = PFUser.currentUser()["username"]
        newSquirrel["raters"] = []
        newSquirrel["ratings"] = []
        newSquirrel["dtd"] = false
        newSquirrel["out"] = false
        newSquirrel["avg_rating"] = ""
        newSquirrel.saveInBackgroundWithBlock {
            (success: Bool, error: NSError!) -> Void in
            if (success) {
                self.dismissViewControllerAnimated(true, completion: nil)
                //Update the number of squirrels the user has
                var currentNum = PFUser.currentUser()["num_of_squirrels"] as? Int
                PFUser.currentUser()["num_of_squirrels"] = currentNum! + 1
                PFUser.currentUser().save()
                
                self.tableView.reloadData()
                
            } else {
                println(error)
            }
        }

        
    }
    
    //Should be its own extension 
    func squirrelDetailViewController(controller: SquirrelDetailViewController) {
            self.tableView.reloadData()
    }

}

