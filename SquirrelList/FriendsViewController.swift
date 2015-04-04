//
//  FriendsViewController.swift
//  SquirrelList
//
//  Created by Denis Geary Lopez on 3/30/15.
//  Copyright (c) 2015 Frenvu Inc. All rights reserved.
//

/* ViewController that displays all of the logged in user's friends
*/

import UIKit

class FriendsViewController: PFQueryTableViewController, FindFriendsViewControllerDelegate {

    var shouldReload: Bool?
  
    @IBOutlet weak var findFriendsButton: UIBarButtonItem!
    
    @IBAction func findFriends(sender: AnyObject) {
        performSegueWithIdentifier("FindFriends", sender: self)
    }
    
    // Initialise the PFQueryTable tableview
    override init!(style: UITableViewStyle, className: String!) {
        super.init(style: style, className: className)
    }
	
    
    required init(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
  
        // Configure the PFQueryTableView
        self.parseClassName = "User"
        self.textKey = "username"
        self.pullToRefreshEnabled = true
        self.paginationEnabled = false
    }
    
    
    
    override func prepareForSegue(segue: UIStoryboardSegue, sender: AnyObject?) {
            if segue.identifier == "FindFriends" {
                let controller = segue.destinationViewController as FindFriendsViewController
                controller.delegate = self
            }
    }
    
    
    // Define the query that will provide the data for the table view
    override func queryForTable() -> PFQuery! {
        var query = PFUser.query()
        query.whereKey("objectId", containedIn: PFUser.currentUser()["friends"] as [String])
        query.orderByAscending("username")
        return query
    }
    
    override func tableView(tableView: UITableView, cellForRowAtIndexPath indexPath: NSIndexPath) -> UITableViewCell {
        var cell: UITableViewCell = self.tableView.dequeueReusableCellWithIdentifier("Cell") as UITableViewCell
        var name = cell.viewWithTag(1) as UILabel
        name.text = objects[indexPath.row]["username"] as? String
        return cell
        
    }
    
    override func viewDidAppear(animated: Bool) {
        if shouldReload? == true {
            println("working")
            self.tableView.reloadData()
        }
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        //Setting the find friend image, which is 'fa-user-plus'
        findFriendsButton.setTitleTextAttributes([NSFontAttributeName: UIFont(name: "FontAwesome", size: 25)!], forState: UIControlState.Normal)
        findFriendsButton.title = "\u{f234}"
        findFriendsButton.tintColor = UIColor.whiteColor()
        self.tableView.allowsSelection = false

    }
    
    //Should be its own extension
    func findFriendsViewController(controller: FindFriendsViewController) {
        shouldReload = true
    }
   
}
