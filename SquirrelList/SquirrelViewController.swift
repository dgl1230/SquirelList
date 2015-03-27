//
//  SquirrelNewViewController.swift
//  SquirrelList
//
//  Created by Denis Geary Lopez on 3/23/15.
//  Copyright (c) 2015 Frenvu Inc. All rights reserved.
//

import UIKit

@objc protocol SquirrelViewControllerDelegate: class {

    optional func SquirrelTradeDelegate(controller: SquirrelViewController, selectedSquirrel: PFObject, wantedSquirrelOwner: PFUser, wantedSquirrel: PFObject)
}

class SquirrelViewController: PFQueryTableViewController, AddSquirrelViewControllerDelegate, SquirrelDetailViewControllerDelegate {

    //Optional value for determing if we're viewing someone else's squirrels
    var selectedUser: PFUser?
    
    weak var delegate: SquirrelViewControllerDelegate?
    
    //Optional values for if the user is currently trying to trade
    
    //Optional value for determining if user is going through their Squirrels to select a trade
    var currentlyTrading: Bool?
    //Squirrel that the logged in user wants in return for one of their squirrels
    var desiredSquirrel: PFObject?
    //The owner of the squirrel that the logged in user wants
    var desiredSquirrelOwner: PFUser?
    
    @IBOutlet weak var teamRatingLabel: UILabel!
    
    @IBOutlet weak var addSquirrelButton: UIBarButtonItem?
    
    @IBAction func addSquirrel(sender: AnyObject) {
        self.performSegueWithIdentifier("AddSquirrel", sender: self)
    }


    // Initialise the PFQueryTable tableview
    override init!(style: UITableViewStyle, className: String!) {
        super.init(style: style, className: className)
    }
	
    required init(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
  
        // Configure the PFQueryTableView
        self.parseClassName = "Squirrel"
        self.textKey = "first_name"
        if currentlyTrading? == true {
            self.pullToRefreshEnabled = false
        } else {
            self.pullToRefreshEnabled = true
        }
        self.paginationEnabled = false
    }
    
    
    //Calculates the average, given an array of numbers
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
    
    
    //Calculates the average rating of Squirrells owned by a user
    func calculateTeamRating(username:String) -> String? {
        var teamRatings: [String] = []
        for squirrel in self.objects{
            //For some reason a nil check always passes, but converting "avg_rating" to a string and then checking works
            if (squirrel["owner"] as String == username) && (squirrel["avg_rating"] as String != ""){
                teamRatings.append(squirrel["avg_rating"] as String)
            }
        }
        var teamRating = calculateAverageRating(teamRatings as [String])
        return String(teamRating)
    }
    
    
    //Goes through the list of raters a Squirrel has and if the username of said user is found, returns false. Else it returns true
    func didUserRatedSquirrel(username:String, raters: [String]) -> Bool {
        if (find(raters, username) == nil) {
            return false
        }
        return true
    }
    
    
    override func prepareForSegue(segue: UIStoryboardSegue, sender: AnyObject?) {
        if segue.identifier == "AddSquirrel" {
            let controller = segue.destinationViewController as AddSquirrelViewController
            controller.delegate = self
            
        }
        if segue.identifier == "SquirrelDetails" {
            let controller = segue.destinationViewController as SquirrelDetailViewController
            //controller.delegate = self
            controller.ratedSquirrel = sender as? PFObject
            if sender!["owner"] != nil {
                controller.squirrelOwner = selectedUser?
            }
        }
    }
    
    override func objectsDidLoad(error: NSError!) {
        super.objectsDidLoad(error)
        //Team ratings need to be calculated here because the query hasn't been calculated yet in viewDidLoad
        if (self.selectedUser != nil) {
            //We need to calculate the team rating
            var teamRating = calculateTeamRating(selectedUser!["username"] as String)
            if teamRating == "No Ratings" {
                teamRatingLabel.text = "Their Squirrels haven't been rated :("
            } else {
                teamRatingLabel.text = "Team Rating: \(teamRating!)"
            }
        }
    }
    
    // Define the query that will provide the data for the table view
    override func queryForTable() -> PFQuery! {
        var query = PFQuery(className: "Squirrel")
        if currentlyTrading? == true {
            query.whereKey("owner", equalTo: PFUser.currentUser()["username"])
        }
        else if selectedUser != nil {
            query.whereKey("owner", equalTo: selectedUser!["username"])
        } 
        query.orderByAscending("last_name")
        return query
    }
    
    
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
    
    override func tableView(tableView: UITableView, didSelectRowAtIndexPath indexPath: NSIndexPath) {
        println(currentlyTrading)
        if currentlyTrading? == true {
            //dismissViewControllerAnimated(true, completion: nil)
            delegate?.SquirrelTradeDelegate!(self, selectedSquirrel: objects[indexPath.row] as PFObject, wantedSquirrelOwner:desiredSquirrelOwner!, wantedSquirrel: desiredSquirrel!)
            
            self.navigationController?.popViewControllerAnimated(true)
        }
        else {
            self.performSegueWithIdentifier("SquirrelDetails", sender: objects[indexPath.row])
        }
    }
    
    
    //Finds the user with the most Squirrels and checks if the logged in user has more Squirrels. Return false if user has more Squirrels than other user with most Squirrels. Returns true otherwise
    func userCanAddSquirrel() -> Bool {
        //Need to fetch in order to update "num_of"squirrels" field
        PFUser.currentUser().fetch()
        var query = PFUser.query()
        var users = query.findObjects()
        //The most squirrels owned by one user
        var mostSquirrels = 0
        for user in users {
            var userSquirrels = user["num_of_squirrels"] as Int
            var username = user["username"] as String
            if (userSquirrels > mostSquirrels && username != PFUser.currentUser()["username"] as String) {
                mostSquirrels = userSquirrels
            }
        }
        if PFUser.currentUser()["num_of_squirrels"] as Int > mostSquirrels {
            return false
        }
        return true
    }
    
    
    override func viewDidLoad() {
        super.viewDidLoad()
        tableView.registerNib(UINib(nibName: "SquirrelTableViewCell", bundle: nil), forCellReuseIdentifier: "Cell")

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

