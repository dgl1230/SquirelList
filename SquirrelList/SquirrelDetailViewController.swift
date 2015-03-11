//
//  SquirrelDetailViewController.swift
//  SquirelList
//
//  Created by Denis Geary Lopez on 2/28/15.
//  Copyright (c) 2015 Frenvu Inc. All rights reserved.
//

import UIKit


protocol SquirrelDetailViewControllerDelegate: class {
    func squirrelDetailViewController(controller: SquirrelDetailViewController)
}

class SquirrelDetailViewController: UIViewController {
    
    weak var delegate: SquirrelViewController?
    var ratedSquirrel: PFObject?
    
    @IBOutlet weak var firstNameLabel: UILabel!
    
    @IBOutlet weak var lastNameLabel: UILabel!
    
    @IBOutlet weak var avgRatingLabel: UILabel!
    
    @IBOutlet weak var rateButton: UIButton!
    
    @IBOutlet weak var rateNumberTextField: UITextField!
    
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
        delegate?.squirrelDetailViewController(self)
        self.dismissViewControllerAnimated(true, completion: nil)
        
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
    
    override func viewDidLoad() {
        var firstName = ratedSquirrel!["first_name"] as String
        var lastName = ratedSquirrel!["last_name"] as String
        self.title = "\(firstName) \(lastName)"
        firstNameLabel.text = firstName
        lastNameLabel.text = lastName
        if ratedSquirrel!["avg_rating"] != nil {
            avgRatingLabel.text = ratedSquirrel!["avg_rating"] as? String
        } else {
            avgRatingLabel.text = "No Ratings"
        }
        var userRatedSquirrel = checkIfUserRatedSquirrel(PFUser.currentUser()["username"] as String, raters: ratedSquirrel!["raters"] as [String])
        
        if userRatedSquirrel {
            userRatingLabel.text = getUserRating(PFUser.currentUser()["username"] as String, raters: ratedSquirrel!["raters"] as [String], ratings: ratedSquirrel!["ratings"] as [String])
            rateNumberTextField.hidden = true
            rateButton.hidden = true
        } else {
            //The user did not rate the squirrel 
            yourRatingLabel.hidden = true
            userRatingLabel.hidden = true
        }
        
    }


   
}
