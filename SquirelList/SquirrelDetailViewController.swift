//
//  SquirrelDetailViewController.swift
//  SquirelList
//
//  Created by Denis Geary Lopez on 2/28/15.
//  Copyright (c) 2015 Frenvu Inc. All rights reserved.
//

import UIKit

class SquirrelDetailViewController: UIViewController {
    
    var ratedSquirrel: PFObject?
    
    @IBOutlet weak var rateNumber: UITextField!
    
    @IBAction func rateSquirrel(sender: AnyObject) {
        //check if ["raters"] is nil. If it is, we create it
        var rater = PFUser.currentUser()["username"] as! String
        if let check: AnyObject = ratedSquirrel!["raters"] {
           ratedSquirrel!["raters"].addObject(rater)
        } else {
            ratedSquirrel!["raters"] = [rater]
        }
        
        //check if ["ratings"] is nil. If it is, we create it
        if let check: AnyObject = ratedSquirrel!["ratings"] {
            ratedSquirrel!["ratings"].addObject(rateNumber.text)
        } else {
            ratedSquirrel!["ratings"] = [rateNumber.text]
        }
        ratedSquirrel!["avg_rating"] = calculateAverageRating(ratedSquirrel!["ratings"] as! [String])
        ratedSquirrel!.save()
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
    
    override func viewDidLoad() {
        var firstName = ratedSquirrel!["first_name"] as! String
        var lastName = ratedSquirrel!["last_name"] as! String
        self.title = "\(firstName) \(lastName)"
    }


   
}
