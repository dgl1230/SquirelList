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

    //Optional value for determing if we're viewing someone else's squirrels, who's squirrels they are
    var selectedUser: PFUser?
    //Optional for determing if the user has room to add a Squirrel. Also passed along to SquirrelDetailViewController to allow them to pick up a Squirrel
    var canPickUpSquirrel: Bool?
    //Optional for storing whether the viewcontroller should reload (if the user changed their currentGroup)
    var shouldReLoad: Bool?
    
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
    @IBOutlet weak var tradeOfferButton: UIBarButtonItem!
    
    @IBAction func addSquirrel(sender: AnyObject) {
        self.performSegueWithIdentifier("AddSquirrel", sender: self)
    }
    
    
    @IBAction func viewTradeOffers(sender: AnyObject) {
        self.performSegueWithIdentifier("TradeOffers", sender: self)
    }


    // Initialise the PFQueryTable tableview
    override init(style: UITableViewStyle, className: String!) {
        super.init(style: style, className: className)
    }
	
    required init(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
  
        // Configure the PFQueryTableView
        self.parseClassName = "Squirrel"
        self.textKey = "first_name"
        if currentlyTrading == true {
            self.pullToRefreshEnabled = false
        } else {
            self.pullToRefreshEnabled = true
        }
        self.paginationEnabled = false
    }
    
    
    //Calculates the average, given an array of numbers
    func calculateAverageRating(ratings:[Int]) -> Int {
        var numOfRatings = ratings.count
        if numOfRatings == 0 {
            return 999
        }
        numOfRatings = 0
        var sum = 0
        for rating in ratings {
            sum += rating
            numOfRatings += 1
        }
        return Int(sum/numOfRatings)
    }
    
    
    //Calculates the color that the Squirrel name should be shown in, given the Squirrel's average rating
    func calculateColor(avg_rating: Int) -> UIColor {
        if avg_rating >= 9 {
            //We return a 'bright red' color
            return UIColor(red: 255, green: 0, blue: 0, alpha: 1)
        } else if avg_rating >= 7 {
            //We return a 'orange' color
            return UIColor(red: 255, green: 127, blue: 0, alpha: 1)
        } else if avg_rating >= 5 {
            //We return a 'orange-yellow' color
            UIColor(red: 255, green: 185, blue: 15, alpha: 1)
        }
        //Else we return a 'yellow-brown' color
        return UIColor(red: 205, green: 173, blue: 0, alpha: 1)
    }
    
    
    //Calculates the average rating of Squirrells owned by a user
    func calculateTeamRating(username:String) -> Int {
        var teamRatings: [Int] = []
        for squirrel in self.objects! {
            //For some reason a nil check always passes, but converting "avg_rating" to a string and then checking works
            if squirrel["avg_rating"] === nil {
                //Weird parse bug, can only check if nil by using ===
            }
            else if (squirrel["owner"] as! String == username){
                teamRatings.append(squirrel["avg_rating"] as! Int)
            }
        }
        var teamRating = calculateAverageRating(teamRatings as [Int])
        return teamRating
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
            let controller = segue.destinationViewController as! AddSquirrelViewController
            controller.delegate = self
            
        }
        if segue.identifier == "SquirrelDetails" {
            let controller = segue.destinationViewController as! SquirrelDetailViewController
            //controller.delegate = self
            controller.ratedSquirrel = sender as? PFObject
            if sender!["owner"] as! String != ""{
                var query = PFUser.query()
                query!.whereKey("username", equalTo: sender!["owner"]! as! String)
                var user = query!.getFirstObject()
                controller.squirrelOwner = user as? PFUser
                //Need to let controller know if the user can add the squirrel
                controller.canClaimSquirrel = canPickUpSquirrel!
            }
        }
        if segue.identifier == "TradeOffers" {
            let controller = segue.destinationViewController as! NotificationsViewController
        }
    }
    
    override func objectsDidLoad(error: NSError!) {
        super.objectsDidLoad(error)
        //Team ratings need to be calculated here because the query hasn't been calculated yet in viewDidLoad
        if (self.selectedUser != nil) {
            //We need to calculate the team rating
            var teamRating = calculateTeamRating(selectedUser!["username"] as! String)
            if teamRating == 999 {
                teamRatingLabel.text = "Their Squirrels haven't been rated :("
            } else {
                teamRatingLabel.text = "Team Rating: \(String(teamRating))"
            }
        }
    }
    
    // Define the query that will provide the data for the table view
    override func queryForTable() -> PFQuery {
        
        var query = PFQuery(className: "Squirrel")
        query.whereKey("group", equalTo: PFUser.currentUser()!["currentGroup"]!)
        if currentlyTrading == true {
            query.whereKey("owner", equalTo: PFUser.currentUser()!["username"]!)
        } else if selectedUser != nil {
            query.whereKey("owner", equalTo: selectedUser!["username"]!)
        }
        query.orderByDescending("avg_rating")
        return query
    }
    
    
    //Responds to NSNotication when user has changed their current group
    func reloadWithNewGroup() {
        shouldReLoad = true
    }
    
    
    override func tableView(tableView: UITableView, canEditRowAtIndexPath indexPath: NSIndexPath) -> Bool {
        //Squirrels can only be deleted if the user is going through their own squirrels
        if selectedUser?.objectId == PFUser.currentUser()!.objectId {
            return true
        }
        return false
    }
    
    override func tableView(tableView: UITableView, cellForRowAtIndexPath indexPath: NSIndexPath, object: PFObject?) -> PFTableViewCell? {
        var cell = tableView.dequeueReusableCellWithIdentifier("Cell", forIndexPath: indexPath) as! PFTableViewCell
            var first = cell.viewWithTag(1) as! UILabel
            first.text = object!["first_name"]!.capitalizedString
            //For some reason 2 is already being used as another tag
            var last = cell.viewWithTag(5) as! UILabel
            last.text = object!["last_name"]!.capitalizedString
            var ratingLabel = cell.viewWithTag(3) as! UILabel
            var avgRating: AnyObject! = object!["avg_rating"]
            if (avgRating != nil) {
                ratingLabel.text = "\(avgRating!)"
                var color = calculateColor(avgRating! as! Int)
                first.textColor = color
                last.textColor = color
                ratingLabel.textColor = color
            } else {
                //For some reason not setting unrated squirrels color to black, leads to them sometimes being other colors, despite 
                // the squirrel's avgRating not passing the if statemtnt
                ratingLabel.text = ""
                var color = UIColor.blackColor()
                first.textColor = color
                last.textColor = color
                ratingLabel.textColor = color
            }
            return cell
    }
    
    
    override func tableView(tableView: UITableView, commitEditingStyle editingStyle: UITableViewCellEditingStyle, forRowAtIndexPath indexPath: NSIndexPath) {
        if editingStyle == UITableViewCellEditingStyle.Delete {
            let squirrel = objects![indexPath.row] as! PFObject
            squirrel["owner"] = ""
            squirrel.save()
            var currentSquirrelCount = PFUser.currentUser()!["num_of_squirrels"] as! Int
            var newSquirrelCount = currentSquirrelCount - 1
            //Update Squirrel List average ratings and the number of squirrels owned in that squirrel list
            //There might be some bugs in this right now
            PFUser.currentUser()!["num_of_squirrels"]! = newSquirrelCount
            PFUser.currentUser()!.save()
            var teamRating = calculateTeamRating(selectedUser!["username"] as! String)
            teamRatingLabel.text = "Team Rating: \(String(teamRating))"
            self.loadObjects()
        }
    }
    
    override func tableView(tableView: UITableView, didSelectRowAtIndexPath indexPath: NSIndexPath) {
        if currentlyTrading == true {
            //dismissViewControllerAnimated(true, completion: nil)
            //Then the delegate will store the selected Squirrel and other trade information 
            delegate?.SquirrelTradeDelegate!(self, selectedSquirrel: objects![indexPath.row] as! PFObject, wantedSquirrelOwner:desiredSquirrelOwner!, wantedSquirrel: desiredSquirrel!)
            
            self.navigationController?.popViewControllerAnimated(true)
        }
        else {
            self.performSegueWithIdentifier("SquirrelDetails", sender: objects![indexPath.row])
        }
    }
    
    
    //Finds the user with the most Squirrels and checks if the logged in user has more Squirrels. Return false if user has more Squirrels than other user with most Squirrels. Returns true otherwise
    func userCanAddSquirrel() -> Bool {
        //Need to fetch in order to update "num_of"squirrels" field
        PFUser.currentUser()!.fetch()
        var query = PFUser.query()
        query?.whereKey("objectId", containedIn: PFUser.currentUser()!["currentGroup"]!["userIDs"]! as! [String])
        var users = query!.findObjects()
        //The most squirrels owned by one user
        var mostSquirrels = 0
        for user in users! {
            var userSquirrels = user["num_of_squirrels"] as! Int
            var username = user["username"]! as! String
            if (userSquirrels > mostSquirrels && username != PFUser.currentUser()!["username"] as! String) {
                mostSquirrels = userSquirrels
            }
        }
        if PFUser.currentUser()!["num_of_squirrels"] as! Int > mostSquirrels {
            return false
        }
        return true
    }
    
    
    override func viewDidLoad() {
        super.viewDidLoad()
        if selectedUser == nil {
            //Set the addSquirrelButton to 'fa-plus-circle'
            addSquirrelButton?.setTitleTextAttributes([NSFontAttributeName: UIFont(name: "FontAwesome", size: 30)!], forState: UIControlState.Normal)
            addSquirrelButton?.title = "\u{f055}"
            addSquirrelButton?.tintColor = UIColor.whiteColor()
            //Set the tradeOfferButton to 'fa-user-secret'
            tradeOfferButton?.setTitleTextAttributes([NSFontAttributeName: UIFont(name: "FontAwesome", size: 30)!], forState: UIControlState.Normal)
            tradeOfferButton?.title = "\u{f21b}"
            tradeOfferButton?.tintColor = UIColor.whiteColor()
        }
        canPickUpSquirrel = userCanAddSquirrel()
        
        //If the selected user is nil, then we are now on user squirrels, which has no addSquirrelButton
        if canPickUpSquirrel == false || self.selectedUser == nil {
            addSquirrelButton?.enabled = false
        }
        
        //Set notification to "listen" for when the the user has changed their currentGroup
        NSNotificationCenter.defaultCenter().addObserver(self, selector: "reloadWithNewGroup", name: reloadNotificationKey, object: nil)
    }
    
    
    override func viewWillAppear(animated: Bool) {
        if shouldReLoad == true {
            self.viewDidLoad()
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
        newSquirrel["owner"] = PFUser.currentUser()!["username"]
        newSquirrel["raters"] = []
        newSquirrel["ratings"] = []
        newSquirrel["dtd"] = false
        newSquirrel["out"] = false
        newSquirrel["avg_rating"] = 0
        newSquirrel["group"] = PFUser.currentUser()!["group"]
        newSquirrel.saveInBackgroundWithBlock {
            (success: Bool, error: NSError?) -> Void in
            if (success) {
                self.dismissViewControllerAnimated(true, completion: nil)
                //Update the number of squirrels the user has
                var currentNum = PFUser.currentUser()!["num_of_squirrels"]! as? Int
                PFUser.currentUser()!["num_of_squirrels"]! = currentNum! + 1
                PFUser.currentUser()!.save()
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

