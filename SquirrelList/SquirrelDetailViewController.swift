//
//  SquirrelDetailNewViewController.swift
//  SquirrelList
//
//  Created by Denis Geary Lopez on 3/23/15.
//  Copyright (c) 2015 Frenvu Inc. All rights reserved.
//

import UIKit

protocol SquirrelDetailViewControllerDelegate: class {
    func squirrelDetailViewController(controller: SquirrelDetailViewController)
}

class SquirrelDetailViewController: PopUpViewController {

    weak var delegate: SquirrelViewController?
    var ratedSquirrel: PFObject?
    var squirrelOwner: PFUser?
    
    @IBOutlet weak var squirrelNameLabel: UILabel!
    @IBOutlet weak var avgRatingLabel: UILabel!
    
    //Label that says "owner:" doesn't actually say the owner's name
    @IBOutlet weak var ownerLabel: UILabel!
    @IBOutlet weak var rateButton: UIButton!
    @IBOutlet weak var rateNumberTextField: UITextField!
    //Label that displays the owners name
    @IBOutlet weak var squirrelOwnerLabel: UILabel!
    @IBOutlet weak var tradeButton: UIButton!
    //This label displays the user's actual rating
    @IBOutlet weak var userRatingLabel: UILabel!
    //The label that says "Your Rating" - it does not actually display the rating
    @IBOutlet weak var yourRatingLabel: UILabel!
    
    
    @IBAction func rateSquirrel(sender: AnyObject) {
        //check if ["raters"] is nil. If it is, we create it
        var rater = PFUser.currentUser()["username"] as String
        if let check: AnyObject = ratedSquirrel!["raters"] {
           ratedSquirrel!["raters"].addObject(rater)
        } else {
            ratedSquirrel!["raters"] = [rater]
        }
        
        //check if ["ratings"] is nil. If it is, we create it
        if let check: AnyObject = ratedSquirrel!["ratings"] {
            ratedSquirrel!["ratings"].addObject(rateNumberTextField.text)
        } else {
            ratedSquirrel!["ratings"] = [rateNumberTextField.text]
        }
        ratedSquirrel!["avg_rating"] = calculateAverageRating(ratedSquirrel!["ratings"] as [String])
        ratedSquirrel!.save()
        //delegate?.squirrelDetailViewController(self)
        self.dismissViewControllerAnimated(true, completion: nil)
        
    }
    
    
    @IBAction func tradeSquirrel(sender: AnyObject) {
        self.performSegueWithIdentifier("tradeSquirrel", sender: self)
    }
    
    
    
    
    func calculateAverageRating(ratings:[String]) -> String {
        var numOfRatings = ratings.count
        if numOfRatings == 0 {
            return "0"
        }
        var sum = 0

        for rating in ratings {
            sum += rating.toInt()!
        }
        return String(Int(Float(sum)/Float(numOfRatings)))
    }
    
    
    func checkIfUserRatedSquirrel(username:String, raters: [String]) -> Bool {
        if (find(raters, username) == nil) {
            return false
        }
        return true
    }
    
    func getUserRating(username:String, raters:[String], ratings:[String]) -> String {
        if (find(raters, username) == nil) {
            return "No rating"
        }
        var index = find(raters, username)
        return ratings[index!]
    }
    
    
    override func prepareForSegue(segue: UIStoryboardSegue, sender: AnyObject?) {
        if segue.identifier == "tradeSquirrel" {
            let controller = segue.destinationViewController as TradeViewController
            controller.desiredSquirrelOwner = squirrelOwner!
            controller.desiredSquirrel = ratedSquirrel!
        }

    }
    
    override func touchesBegan(touches: NSSet, withEvent event: UIEvent) {
        self.view.endEditing(true)
    }


    

    override func viewDidLoad() {
        super.viewDidLoad()
        
        var firstName = ratedSquirrel!["first_name"] as String
        var lastName = ratedSquirrel!["last_name"] as String
        squirrelNameLabel.text = "\(firstName) \(lastName)"
        
        //Check if the squirrel has an average rating 
        if ratedSquirrel!["avg_rating"] != nil {
            avgRatingLabel.text = ratedSquirrel!["avg_rating"] as? String
        } else {
            avgRatingLabel.text = "No Ratings"
        }
        var userRatedSquirrel = checkIfUserRatedSquirrel(PFUser.currentUser()["username"] as String, raters: ratedSquirrel!["raters"] as [String])
        
        //Check if the user has rated the squirrel
        if userRatedSquirrel {
            yourRatingLabel.text = getUserRating(PFUser.currentUser()["username"] as String, raters: ratedSquirrel!["raters"] as [String], ratings: ratedSquirrel!["ratings"] as [String])
            rateNumberTextField.hidden = true
            rateButton.hidden = true
        } else {
            //The user did not rate the squirrel 
            yourRatingLabel.hidden = true
            userRatingLabel.hidden = true
        }
        
        //Check if the squirrel has an owner to propose a trade with
        if ratedSquirrel!["owner"] == nil {
            tradeButton.hidden = true
            ownerLabel.hidden = true
            squirrelOwnerLabel.hidden = true
        } else if ratedSquirrel!["owner"] as String == PFUser.currentUser()["username"] as String{
            tradeButton.hidden = true
            ownerLabel.hidden = false
            squirrelOwnerLabel.text = "me"
        } else {
            //Squirrel does have an owner
            ownerLabel.hidden = false
            squirrelOwnerLabel.text = ratedSquirrel!["owner"] as? String
        }

    }

   

    /*
    // MARK: - Navigation

    // In a storyboard-based application, you will often want to do a little preparation before navigation
    override func prepareForSegue(segue: UIStoryboardSegue, sender: AnyObject?) {
        // Get the new view controller using segue.destinationViewController.
        // Pass the selected object to the new view controller.
    }
    */

}
