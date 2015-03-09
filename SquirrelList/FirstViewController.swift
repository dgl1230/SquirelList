//
//  FirstViewController.swift
//  SquirelList
//
//  Created by Denis Geary Lopez on 1/25/15.
//  Copyright (c) 2015 Frenvu Inc. All rights reserved.
//

import UIKit

class FirstViewController: UITableViewController {

    var users = [PFUser]()


    @IBAction func logout(sender: AnyObject) {
        PFUser.logOut()
        self.dismissViewControllerAnimated(true, completion: nil)
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    
    override func numberOfSectionsInTableView(tableView: UITableView) -> Int {
        return 1
    }
    
    
    override func prepareForSegue(segue: UIStoryboardSegue, sender: AnyObject?) {
        if segue.identifier == "SingleUserSquirrels" {
            let controller = segue.destinationViewController as SquirrelViewController
            var selectedUser = sender as PFUser
            controller.selectedUser = selectedUser
            //var addButton = self.view.viewWithTag(69) as! UIBarButtonItem
            
        }

    }
    
    
    override func tableView(tableView: UITableView, cellForRowAtIndexPath indexPath: NSIndexPath) -> UITableViewCell {
        var cell: UITableViewCell = self.tableView.dequeueReusableCellWithIdentifier("cell") as UITableViewCell
        if (users[indexPath.row]["username"] as? String == PFUser.currentUser().username) {
             cell.textLabel?.text = "me"
        }
        else {
            cell.textLabel?.text = users[indexPath.row]["username"] as? String
        }
        return cell
    }
    
    
    override func tableView(tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return users.count
    }
    
    
    override func tableView(tableView: UITableView, didSelectRowAtIndexPath indexPath: NSIndexPath) {
        var cell: UITableViewCell = tableView.cellForRowAtIndexPath(indexPath)!
        self.performSegueWithIdentifier("SingleUserSquirrels", sender: users[indexPath.row])
    }

    
    override func viewDidLoad() {
        super.viewDidLoad()
        var query = PFUser.query()
        //query.whereKey("owner", equalTo: selectedUser!["username"])
        
        query.findObjectsInBackgroundWithBlock({ (objects: [AnyObject]!, error: NSError!) -> Void in
            self.users.removeAll(keepCapacity: true)
            for object in objects {
                var user:PFUser = object as PFUser
                self.users.append(user)
                
            }
            self.tableView.reloadData()
        
        })
    }



}

