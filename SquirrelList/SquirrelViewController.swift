//
//  FirstViewController.swift
//  SquirelList
//
//  Created by Denis Geary Lopez on 1/25/15.
//  Copyright (c) 2015 Frenvu Inc. All rights reserved.
//

import UIKit

class SquirrelViewController: UITableViewController, AddSquirrelViewControllerDelegate, SquirrelDetailViewControllerDelegate {

    var squirrels = [PFObject]()
    var selectedUser: PFUser?
    var didTheyRate: Bool?
    
    //There are optionals for updating a Squirrel's rating
    
    var rating: String?
    var teamRatings = [String]()

    
    @IBOutlet weak var teamRatingLabel: UILabel!
    
    @IBOutlet weak var addSquirrelButton: UIBarButtonItem!


    func calculateTeamRating(username:String) -> String? {
        teamRatings = []
        for squirrel in self.squirrels {
            if (squirrel["owner"] as String == username) && (squirrel["avg_rating"] != nil){
                teamRatings.append(squirrel["avg_rating"] as String)
            }
        }
        var teamRating = calculateAverageRating(teamRatings)
        return String(teamRating)
    }
    
    


    func checkIfUserRatedSquirrel(username:String, raters: [String]) -> Bool {
        if (find(raters, username) == nil) {
            return false
        }
        return true
    }
   
    
    override func numberOfSectionsInTableView(tableView: UITableView) -> Int {
        return 1
    }
    
    override func prepareForSegue(segue: UIStoryboardSegue, sender: AnyObject?) {
        if segue.identifier == "AddSquirrel" {
            let navigationController = segue.destinationViewController as UINavigationController
            let controller = navigationController.topViewController as AddSquirrelViewController
            controller.delegate = self
            
        }
        if segue.identifier == "SquirrelDetails" {
            let controller = segue.destinationViewController as SquirrelDetailViewController
            controller.delegate = self
            controller.ratedSquirrel = sender as? PFObject
            
        }

    }
    
    
    func calculateAverageRating(ratings:[String]) -> Int {
        var numOfRatings = ratings.count
        if numOfRatings == 0 {
            return 0
        }
        numOfRatings = 0
        var sum = 0

        for rating in ratings {
            if let test = rating.toInt() {
                println(rating)
                 sum += rating.toInt()!
                 numOfRatings += 1
            }
           
        }
        return Int(Float(sum)/Float(numOfRatings))
        
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
        
        var raters = squirrels[indexPath.row]["raters"] as? [String]
        if let check = raters {
            didTheyRate = checkIfUserRatedSquirrel(PFUser.currentUser().username, raters: squirrels[indexPath.row]["raters"] as [String])
        } else {
            didTheyRate = false
        }
        if (didTheyRate == false) {
            var rate = cell.viewWithTag(4) as UIButton
            rate.setTitle("Rate", forState: UIControlState.Normal)
        }
        return cell
    }
    
    
    override func tableView(tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return squirrels.count
    }
    
    
    override func tableView(tableView: UITableView, didSelectRowAtIndexPath indexPath: NSIndexPath) {
        var cell: UITableViewCell = tableView.cellForRowAtIndexPath(indexPath)!
        var username = PFUser.currentUser()["username"] as String
        var raters = squirrels[indexPath.row]["raters"] as [String]
        self.performSegueWithIdentifier("SquirrelDetails", sender: squirrels[indexPath.row])        
        
    }
    
    
    func userCanAddSquirrel() -> Bool {
        var query = PFUser.query()
        var loggedInUserQuery = PFUser.query()
        loggedInUserQuery.whereKey("username", equalTo: PFUser.currentUser()["username"])
        var loggedInUser = loggedInUserQuery.getFirstObject()
        var users = query.findObjects()
        for user in users {
            if (loggedInUser["num_of_squirrels"] as Int > user["num_of_squirrels"] as Int) {
                return false
            }
        }
        return true
            
        
        
    }

    
    override func viewDidLoad() {
        super.viewDidLoad()
        tableView.registerNib(UINib(nibName: "SquirrelTableViewCell", bundle: nil), forCellReuseIdentifier: "Cell")
        var query = PFQuery(className:"Squirrel")
        if (selectedUser != nil) {
            //Then we are going to a selected user's list of Squirrels
            query.whereKey("owner", equalTo: selectedUser!["username"])
        }
        query.findObjectsInBackgroundWithBlock({ (objects: [AnyObject]!, error: NSError!) -> Void in
            self.squirrels.removeAll(keepCapacity: true)
            for object in objects {
                var squirrel:PFObject = object as PFObject
                self.squirrels.append(squirrel)
            }
            self.tableView.reloadData()
            //test to see if they are viewing someone's squirrel list 
            if let test = self.selectedUser {
                var username = self.selectedUser!["username"] as String
                self.title = "\(username)'s  Squirrels"
                var teamRating = self.calculateTeamRating(self.selectedUser!["username"] as String)
                self.teamRatingLabel.text = "Team Rating: \(teamRating!)"
            } 
        })
        //If the selected user is nil, then we are not on user squirrels, which has no addSquirrelButton
        if !userCanAddSquirrel() && self.selectedUser == nil {
            addSquirrelButton.enabled = false
        }

    }
    
    
    
    //should be made into its own extension 
    func addSquirrelViewControllerDidCancel(controller: AddSquirrelViewController) {
        dismissViewControllerAnimated(true, completion: nil)
    }
   
    
    //Should also be made into its own extension
    
    
    func addSquirrelViewController(controller: AddSquirrelViewController, didFinishAddingFirstName firstName: NSString, didFinishAddingLastName lastName: NSString) {
        let newRowIndex = squirrels.count

        var newSquirrel = PFObject(className:"Squirrel")
        newSquirrel["first_name"] = firstName
        newSquirrel["last_name"] = lastName
        newSquirrel["owner"] = PFUser.currentUser()["username"]
        newSquirrel["raters"] = []
        newSquirrel["ratings"] = []
        newSquirrel["dtd"] = false
        newSquirrel["out"] = false
        newSquirrel["avg_rating"] = ""
        squirrels.append(newSquirrel)
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
    
    //Should be its own extension 
    func squirrelDetailViewController(controller: SquirrelDetailViewController) {
            self.tableView.reloadData()
    }
    
    

}


