//
//  SquirrelTableViewCell.swift
//  SquirelList
//
//  Created by Denis Geary Lopez on 2/23/15.
//  Copyright (c) 2015 Frenvu Inc. All rights reserved.
//

import UIKit


class SquirrelTableViewCell: UITableViewCell {
    
   var squirrel: PFObject?
   var username: String?
   
   
    
    @IBOutlet weak var rateButton: UIButton!
    
    
    
    override func awakeFromNib() {
        super.awakeFromNib()
        // Initialization code
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
    
    

    override func setSelected(selected: Bool, animated: Bool) {
        super.setSelected(selected, animated: animated)

        // Configure the view for the selected state
    }
    
}
