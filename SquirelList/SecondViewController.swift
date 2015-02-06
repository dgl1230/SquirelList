//
//  FirstViewController.swift
//  SquirelList
//
//  Created by Denis Geary Lopez on 1/25/15.
//  Copyright (c) 2015 Frenvu Inc. All rights reserved.
//

import UIKit

class SecondViewController: UITableViewController, AddSquirrelViewControllerDelegate {

    var squirrels = [""]

    
    override func numberOfSectionsInTableView(tableView: UITableView) -> Int {
        return 1
    }
    
    override func prepareForSegue(segue: UIStoryboardSegue, sender: AnyObject?) {
        if segue.identifier == "AddSquirrel" {
            let navigationController = segue.destinationViewController as UINavigationController
            let controller = navigationController.topViewController as AddSquirrelViewController
            controller.delegate = self
        }
    }
    
    
    override func tableView(tableView: UITableView, cellForRowAtIndexPath indexPath: NSIndexPath) -> UITableViewCell {
        var cell: UITableViewCell = self.tableView.dequeueReusableCellWithIdentifier("cell2") as UITableViewCell
        cell.textLabel?.text = squirrels[indexPath.row]
        return cell
    }
    
    
    override func tableView(tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return squirrels.count
    }
    
    
    override func tableView(tableView: UITableView, didSelectRowAtIndexPath indexPath: NSIndexPath) {
        var cell: UITableViewCell = tableView.cellForRowAtIndexPath(indexPath)!
        if cell.accessoryType == UITableViewCellAccessoryType.Checkmark {
            cell.accessoryType = UITableViewCellAccessoryType.None
        } else {
            cell.accessoryType = UITableViewCellAccessoryType.Checkmark
        }
    }

    
    override func viewDidLoad() {
        super.viewDidLoad()
        var query = PFQuery(className:"Squirrel")
        query.findObjectsInBackgroundWithBlock({ (objects: [AnyObject]!, error: NSError!) -> Void in
            self.squirrels.removeAll(keepCapacity: true)
            for object in objects {
                var squirrel:PFObject = object as PFObject
                self.squirrels.append(squirrel["first_name"] as NSString)
            }
            self.tableView.reloadData()
        })

    }
    
    //should be made into its own extension 
    func addSquirrelViewControllerDidCancel(controller: AddSquirrelViewController) {
        dismissViewControllerAnimated(true, completion: nil)
    }
    
    func addSquirrelViewController(controller: AddSquirrelViewController, didFinishAddingFirstName firstName: NSString, didFinishAddingLastName lastName: NSString) {
        let newRowIndex = squirrels.count

        var newSquirrel = PFObject(className:"Squirrel")
        newSquirrel["first_name"] = firstName
        newSquirrel["last_name"] = lastName
        squirrels.append(firstName)
        newSquirrel.saveInBackgroundWithBlock {
            (success: Bool, error: NSError!) -> Void in
            if (success) {
                self.dismissViewControllerAnimated(true, completion: nil)
                //updating the rows in the table view
                let indexPath = NSIndexPath(forRow: newRowIndex, inSection: 0)
                let indexPaths = [indexPath]
                self.tableView.insertRowsAtIndexPaths(indexPaths, withRowAnimation: .Automatic)
                
                self.tableView.reloadData()
                
            } else {
                println(error)
            }
        }

        
    }

}


