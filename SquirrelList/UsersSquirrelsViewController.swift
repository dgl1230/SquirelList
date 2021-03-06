//
//  SquirrelNewViewController.swift
//  SquirrelList
//
//  Created by Denis Geary Lopez on 3/23/15.
//  Copyright (c) 2015 Frenvu Inc. All rights reserved.
//


import UIKit

//For passing back squirrel information when a user is selecting a squirrel to propose a trade to 
@objc protocol  UsersSquirrelsViewControllerDelegate: class {
    optional func selectedSquirrelForTrade(controller: UsersSquirrelsViewController, selectedSquirrel: PFObject, wantedSquirrelOwner: PFUser, wantedSquirrel: PFObject)
}

class UsersSquirrelsViewController: PFQueryTableViewController, NewSquirrelDetailslViewControllerDelegate {

    //Variable for storing the logged in user's current group
    var currentGroup: PFObject?
    //Optional value for determing if we're viewing someone else's squirrels, who's squirrels they are
    var selectedUser: PFUser?
    weak var delegate: UsersSquirrelsViewControllerDelegate?
    
    //Optional values for if the user is currently trying to trade - this to to pass back the relevant data to TradeOfferViewController after the user has selected a squirrel of theirs to offer in the trade 
    
    //Variable for determining if user is going through their Squirrels to select a trade
    var currentlyTrading = false
    //Squirrel that the logged in user wants in return for one of their squirrels
    var desiredSquirrel: PFObject?
    //The owner of the squirrel that the logged in user wants
    var desiredSquirrelOwner: PFUser?
    
    @IBOutlet weak var teamRatingLabel: UILabel!


    // Initialise the PFQueryTable tableview
    override init(style: UITableViewStyle, className: String!) {
        super.init(style: style, className: className)
    }
	
    required init(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)!

        // Configure the PFQueryTableView
        self.parseClassName = "Squirrel"
        self.textKey = "first_name"
        self.pullToRefreshEnabled = false
        self.paginationEnabled = false
    }
    
    /*
    //Calculates the average, given an array of numbers
    func calculateAverageRating(ratings:[Double]) -> Double {
        var numOfRatings = ratings.count
        if numOfRatings == 0 {
            return 999
        }
        numOfRatings = 0
        var sum = 0.0
        for rating in ratings {
            sum += rating
            numOfRatings += 1
        }
        let unroundedRating = Double(sum)/Double(numOfRatings)
        return round((10 * unroundedRating)) / 10
    }
    */
    
    /*
    //Calculates the average rating of Squirrells owned by a user
    func calculateTeamRating(username:String) -> Double {
        var teamRatings: [Double] = []
        for squirrel in self.objects! {
            let owner = squirrel["ownerUsername"] as? String
            if squirrel["avg_rating"] === 0 {
                //Weird parse bug, can only check if nil by using ===
            } else if (owner == username){
                teamRatings.append(squirrel["avg_rating"] as! Double)
            }
        }
        let teamRating = calculateAverageRating(teamRatings as [Double])
        return teamRating
    }
    */
    
    /*
    //Goes through the list of raters a Squirrel has and if the username of said user is found, returns false. Else it returns true
    func didUserRatedSquirrel(username:String, raters: [String]) -> Bool {
        if (raters.indexOf(username) == nil) {
            return false
        }
        return true
    }
    */
    
    
    override func prepareForSegue(segue: UIStoryboardSegue, sender: AnyObject?) {
        if segue.identifier == "SquirrelDetails" {
            let controller = segue.destinationViewController as! NewSquirrelDetailsViewController
            controller.delegate = self
            controller.ratedSquirrel = sender as? PFObject
            //var squirrelSlots = Int(getUserInfo(currentGroup!["squirrelSlots"] as! [String], username: PFUser.currentUser()!.username!))
            /*
            let userRerates = Int(getUserInfo(currentGroup!["rerates"] as! [String], username: PFUser.currentUser()!.username!))
            if userRerates == 1 {
                controller.canRerate = true
            } else {
                controller.canRerate = false
            }
            */
            let owner = sender!["owner"] as? PFObject
            if owner != nil {
                let user = sender!["owner"] as? PFUser
                controller.squirrelOwner = user
            } 
        }
    }
    
    /*
    override func objectsDidLoad(error: NSError!) {
        super.objectsDidLoad(error)
        //Team ratings and squirrel slots are calculated here
        //Team ratings need to be calculated here because the query hasn't been calculated yet in viewDidLoad
        if (self.selectedUser != nil) {
            //We need to calculate the team rating
            let teamRating = calculateTeamRating(selectedUser!["username"] as! String)
            //If rating is 999.0, then no one has rated their team
            if teamRating == 999.0 && selectedUser!.objectId == PFUser.currentUser()!.objectId {
                teamRatingLabel.text = "No one has rated your team"
            } else if teamRating == 999.0 {
                teamRatingLabel.text = "No one has rated their team"
            }else {
                teamRatingLabel.text = "Team Rating: \(teamRating)"
            }
        }
    }
    */
    
    // Define the query that will provide the data for the table view
    override func queryForTable() -> PFQuery {
        currentGroup = PFUser.currentUser()!["currentGroup"] as? PFObject
        let query = PFQuery(className: "Squirrel")
        query.whereKey("objectId", containedIn: currentGroup!["squirrels"] as! [String])
        if currentlyTrading == true {
            query.whereKey("owner", equalTo: PFUser.currentUser()!)
        } else {
            query.whereKey("owner", equalTo: selectedUser!)
        }
        query.orderByDescending("first_name")
        return query
    }
    
    
    func reload() {
        self.loadObjects()
        updateLabels()
    }
    
    
    func updateLabels() {
        let name = selectedUser!["name"] as? String
        if selectedUser!.username == PFUser.currentUser()!.username {
            self.title = "My Squirrels"
        } else if name != nil {
            self.title = "\(name!)'s Squirrels"
        } else {
            self.teamRatingLabel.text = "\(selectedUser!.username!)'s Squirrels"
        }
    }
    
    
    override func tableView(tableView: UITableView, canEditRowAtIndexPath indexPath: NSIndexPath) -> Bool {
        //Squirrels can only be dropped if the user is going through their own squirrels when they're not trading
        if selectedUser?.objectId == PFUser.currentUser()!.objectId && currentlyTrading == false {
            return true
        }
        return false
    }
    
    override func tableView(tableView: UITableView, cellForRowAtIndexPath indexPath: NSIndexPath, object: PFObject?) -> PFTableViewCell? {
            let cell = tableView.dequeueReusableCellWithIdentifier("Cell", forIndexPath: indexPath) as! PFTableViewCell
            //It looks strange to have the row highlighted in gray 
            cell.selectionStyle = UITableViewCellSelectionStyle.None
            let openLabel = cell.viewWithTag(6) as? UILabel
            let first = cell.viewWithTag(1) as! UILabel
            first.text = object!["first_name"]!.capitalizedString
            //For some reason 2 is already being used as another tag
            let last = cell.viewWithTag(5) as! UILabel
            last.text = object!["last_name"]!.capitalizedString
            let ratingLabel = cell.viewWithTag(3) as! UILabel
            //let avgRating = object!["avg_rating"] as! Double
            let squirrel = objects![indexPath.row] as! PFObject
            let owner = squirrel["owner"] as? PFUser
            if owner == nil {
                openLabel?.hidden = false
            } else {
                openLabel?.hidden = true
            }
            //To hide ratings
            ratingLabel.text = ""
            /*
            if avgRating != 0 && avgRating >= 9 {
                ratingLabel.text = "\(avgRating)"
                cell.backgroundColor = UIColor.redColor()
            } else if avgRating != 0 && avgRating >= 7 {
                ratingLabel.text = "\(avgRating)"
                cell.backgroundColor = UIColor.orangeColor()
            } else if avgRating != 0 && avgRating >= 5 {
                ratingLabel.text = "\(avgRating)"
                cell.backgroundColor = UIColor.yellowColor()
            } else {
                //For some reason not setting unrated squirrels color to black, leads to them sometimes being other colors, despite 
                ratingLabel.text = ""
                cell.backgroundColor = UIColor.yellowColor()
            }
            */
            cell.backgroundColor = UIColor.redColor()
            return cell
    }
    
    
    override func tableView(tableView: UITableView, commitEditingStyle editingStyle: UITableViewCellEditingStyle, forRowAtIndexPath indexPath: NSIndexPath) {
        if editingStyle == UITableViewCellEditingStyle.Delete {
                let message = "Are you sure you want to drop your squirrel? Your friends may claim it!"
                let alert = UIAlertController(title: "", message: message, preferredStyle: UIAlertControllerStyle.Alert)
                alert.addAction(UIAlertAction(title: "Cancel", style: .Cancel, handler: { (action: UIAlertAction) in
                    alert.dismissViewControllerAnimated(true, completion: nil)
                }))
                alert.addAction(UIAlertAction(title: "Drop Squirrel", style: .Default, handler:  { (action: UIAlertAction) in
                    //Global function that starts the loading animation and returns an array of [NVAcitivtyIndicatorView, UIView, UIView] so that we can pass these views into resumeInterActionEvents() later to suspend animation and dismiss the views
                    let viewsArray = displayLoadingAnimator(self.view)
                    let activityIndicatorView = viewsArray[0] as! NVActivityIndicatorView
                    let container = viewsArray[1] as! UIView
                    let loadingView = viewsArray[2] as! UIView
            
                    dispatch_async(dispatch_get_main_queue()) {
                        let squirrel = self.objects![indexPath.row] as! PFObject
                        squirrel.fetch()
                        let potentialOwner = squirrel["ownerUsername"] as? String
                        if potentialOwner != nil && potentialOwner != PFUser.currentUser()!.username! {
                            //Then a trade was just accepted recently and the logged in user is trying to drop a squirrel that's not there's anymore
                            //Global function that stops the loading animation and dismisses the views it is attached to
                            resumeInteractionEvents(activityIndicatorView, container: container, loadingView: loadingView)
                            displayAlert(self, title: "You sneaky Squirreler", message: "That squirrel isn't yours anymore! But nice try ;)")
                            //Reload the view
                            self.loadObjects()
                            return
                        }
                        
                        squirrel.removeObjectForKey("owner")
                        squirrel.removeObjectForKey("ownerUsername")
                        squirrel.save()
                        //let teamRating = self.calculateTeamRating(self.selectedUser!["username"] as! String)
                        //self.teamRatingLabel.text = "Team Rating: \(teamRating)"
                        //Give the user a squirrel slot
                        let squirrelSlots = Int(getUserInfo(self.currentGroup!["squirrelSlots"] as! [String], username: PFUser.currentUser()!.username!))
                        LOGGED_IN_USER_SQUIRREL_SLOTS = squirrelSlots!
                        LOGGED_IN_USER_SQUIRREL_SLOTS += 1
                        let newSquirrelSlots = getNewArrayToSave(self.currentGroup!["squirrelSlots"] as! [String], username: PFUser.currentUser()!.username!, newInfo: String(LOGGED_IN_USER_SQUIRREL_SLOTS))
                        self.currentGroup!["squirrelSlots"] = newSquirrelSlots
                        self.currentGroup!.save()
                        self.tableView.reloadRowsAtIndexPaths([indexPath], withRowAnimation: UITableViewRowAnimation.Automatic)
                        //Reload the view
                        self.loadObjects()
                        //Global function that stops the loading animation and dismisses the views it is attached to
                        resumeInteractionEvents(activityIndicatorView, container: container, loadingView: loadingView)
                    }
                    
                }))
            self.presentViewController(alert, animated: true, completion: nil)
        }
    }
    
    override func tableView(tableView: UITableView, didSelectRowAtIndexPath indexPath: NSIndexPath) {
        //let squirrel = objects![indexPath.row] as! PFObject
        if currentlyTrading == true {
            //Then the delegate will store the selected Squirrel and other trade information and pass it back to the UsersSquirrelsViewController
            delegate!.selectedSquirrelForTrade!(self, selectedSquirrel: objects![indexPath.row] as! PFObject, wantedSquirrelOwner:desiredSquirrelOwner!, wantedSquirrel: desiredSquirrel!)
            self.navigationController?.popViewControllerAnimated(true)
        }
        else {
            self.performSegueWithIdentifier("SquirrelDetails", sender: objects![indexPath.row])
        }
    }
    
    
    //Customize the delete button on swipe left
    override func tableView(tableView: UITableView, editActionsForRowAtIndexPath indexPath: NSIndexPath) -> [UITableViewRowAction]? {
        let title = "Drop"
        let deleteButton = UITableViewRowAction(style: .Default, title: title, handler: { (action, indexPath) in
            self.tableView.dataSource?.tableView?(
                self.tableView, commitEditingStyle: .Delete, forRowAtIndexPath: indexPath
            )
        })
        return [deleteButton]
    }

    
    override func viewDidLoad() {
        super.viewDidLoad()
        //Check to see if we need to show a new user tutorial screens first
        if currentlyTrading == true {
            //We don't need to load or calculate anything else if we're just displaying the user's squirrels to offer for a trade
            return
        }
        if PFUser.currentUser()!["newSquirrelTab"] as! Bool == true && selectedUser == nil {
            //If new user, show them the tutorial screens, but we only want to present these screens from the main squirrel tab
            performSegueWithIdentifier("NewUserScreens", sender: self)
        }
        updateLabels()
        self.navigationController?.navigationBar.titleTextAttributes = [ NSFontAttributeName: UIFont(name: "BebasNeueBold", size: 26)!,  NSForegroundColorAttributeName: UIColor.whiteColor()]
        //Customize navigation controller back button to my only the back symbol
        let backItem = UIBarButtonItem(title: "", style: UIBarButtonItemStyle.Plain, target: nil, action: nil)
        navigationItem.backBarButtonItem = backItem
    }


    
    //Delegate function is called for squirrelDetailViewController so that we can reload after a user has rated a squirrel
    func reloadParent(controller: NewSquirrelDetailsViewController, usedRerate: Bool) {
        if usedRerate == true {
            //Then the user used their rerate and it needs to be set back to false
            let newRerates = getNewArrayToSave(currentGroup!["rerates"] as! [String], username: PFUser.currentUser()!.username!, newInfo: "0")
            currentGroup!["rerates"] = newRerates
            currentGroup!.save()
        }
        reload()
    }
}


