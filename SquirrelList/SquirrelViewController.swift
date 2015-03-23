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
    
    //Optional value for determing if we're viewing someone else's squirrels
    var selectedUser: PFUser?
    
    var didTheyRate: Bool?
    
    
    //These are optionals for updating a Squirrel's rating
    var rating: String?
    var teamRatings = [String]()

    
    @IBOutlet weak var teamRatingLabel: UILabel!
    
    @IBOutlet weak var addSquirrelButton: UIBarButtonItem?
    
    
    @IBAction func addSquirrel(sender: AnyObject) {
        self.performSegueWithIdentifier("AddSquirrel", sender: self)
    }


    func calculateTeamRating(username:String) -> String? {
        teamRatings = []
        for squirrel in self.squirrels {
            //For some reason a nil check always passes, but converting "avg_rating" to a string and then checking works
            if (squirrel["owner"] as String == username) && (squirrel["avg_rating"] as String != ""){
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
            if sender!["owner"] != nil {
                controller.squirrelOwner = selectedUser?
            }
            
        }

    }
    
    
    func calculateAverageRating(ratings:[String]) -> String {
        var numOfRatings = ratings.count
        if numOfRatings == 0 {
            return "No Ratings"
        }
        numOfRatings = 0
        var sum = 0

        for rating in ratings {
            if let test = rating.toInt() {
                 sum += rating.toInt()!
                 numOfRatings += 1
            }
           
        }
        return String(Int(sum/numOfRatings))
        
    }
    
    
    //Reloads the tableview data and then ends the pull to refresh loading animation when complete
    func refresh(sender:AnyObject) {
        self.tableView.reloadData()
        self.refreshControl!.endRefreshing()
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
        //Need to fetch in order to update "num_of"squirrels" field
        PFUser.currentUser().fetch()
        var query = PFUser.query()
        var users = query.findObjects()
        //The most squirrels owned by one user
        var mostSquirrels = 0
        for user in users {
            if (user["num_of_squirrels"] as Int > mostSquirrels) {
                mostSquirrels = user["num_of_squirrels"] as Int
            }
        }
        if PFUser.currentUser()["num_of_squirrels"] as Int > mostSquirrels {
            return false
        }
        return true
    }

    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        //For allowing pull to refresh 
        self.refreshControl = UIRefreshControl()
        self.refreshControl!.attributedTitle = NSAttributedString(string: "Pull to refresh")
        self.refreshControl!.addTarget(self, action: "refresh:", forControlEvents: UIControlEvents.ValueChanged)
        self.tableView.addSubview(refreshControl!)
        
        tableView.registerNib(UINib(nibName: "SquirrelTableViewCell", bundle: nil), forCellReuseIdentifier: "Cell")
        var query = PFQuery(className:"Squirrel")

        //Check to see if we are viewing someone else's squirrels
        if (selectedUser != nil) {
            var username = self.selectedUser!["username"] as String
            self.title = "\(username)'s  Squirrels"
            query.whereKey("owner", equalTo: selectedUser!["username"])
        }
        query.findObjectsInBackgroundWithBlock({ (objects: [AnyObject]!, error: NSError!) -> Void in
            self.squirrels.removeAll(keepCapacity: true)
            for object in objects {
                var squirrel:PFObject = object as PFObject
                self.squirrels.append(squirrel)
            }
            self.tableView.reloadData()
            if (self.selectedUser != nil) {
                //We need to calculate the team rating AFTER all the the squirrels have been queried
                var teamRating = self.calculateTeamRating(self.selectedUser!["username"] as String)
                
                if teamRating == "No Ratings" {
                    self.teamRatingLabel.text = "Their Squirrels have not been rated yet"
                } else {
                    self.teamRatingLabel.text = "Team Rating: \(teamRating!)"
                }
                
            }
        })
        //If the selected user is nil, then we are now on user squirrels, which has no addSquirrelButton
        if userCanAddSquirrel() == false || self.selectedUser != nil {
            addSquirrelButton?.enabled = false
        }


    }
    
    
    
    //should be made into its own extension 
    func addSquirrelViewControllerDidCancel(controller: AddSquirrelViewController) {
        dismissViewControllerAnimated(true, completion: nil)
    }
   
    
    //Should also be made into its own extension
    func addSquirrelViewController(controller: AddSquirrelViewController, didFinishAddingFirstName firstName: NSString, didFinishAddingLastName lastName: NSString) {
        println("going to delegate function")
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
                //Update the number of squirrels the user has
                println(PFUser.currentUser()["num_of_squirrels"])
                var currentNum = PFUser.currentUser()["num_of_squirrels"] as? Int
                PFUser.currentUser()["num_of_squirrels"] = currentNum! + 1
                PFUser.currentUser().save()
                
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


