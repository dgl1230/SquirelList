//
//  FindFriendsViewController.swift
//  SquirrelList
//
//  Created by Denis Geary Lopez on 3/27/15.
//  Copyright (c) 2015 Frenvu Inc. All rights reserved.
//

/*
Lets users search and find other users via their usernames
*/

import UIKit

class FindFriendsViewController: PFQueryTableViewController, UISearchBarDelegate, UISearchDisplayDelegate {

    var filteredUsers = [PFUser]()
    

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
    
    func filterContentForSearchText(searchText: String) {
        //Filter the array using the filter method
        self.filteredUsers = (self.objects as [PFUser]).filter() {( user: PFUser) -> Bool in
            let stringMatch = (user["username"] as String).rangeOfString(searchText)
            return stringMatch != nil
        }
    }
    
    
    // Define the query that will provide the data for the table view
    override func queryForTable() -> PFQuery! {
        var query = PFUser.query()
        query.whereKey("username", notEqualTo: PFUser.currentUser()["username"])
        query.orderByAscending("username")
        return query
    }
    
    
    func searchDisplayController(controller: UISearchDisplayController!, shouldReloadTableForSearchString searchString: String!) -> Bool {
            println(self.filteredUsers.count)
            self.filterContentForSearchText(searchString)
            return true
    }
 
    
    
    override func tableView(tableView: UITableView, cellForRowAtIndexPath indexPath: NSIndexPath) -> UITableViewCell {
        var cell: UITableViewCell = self.tableView.dequeueReusableCellWithIdentifier("Cell") as UITableViewCell
        var user = filteredUsers[indexPath.row]
        cell.textLabel?.text = filteredUsers[indexPath.row]["username"] as? String
        return cell
        
    }
    
    
    override func tableView(tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        if tableView == self.searchDisplayController!.searchResultsTableView {
            return self.filteredUsers.count
        } else {
            return 0
        }
    }
    
    
    
     override func viewDidLoad() {
        super.viewDidLoad()
    }

    

}
