//
//  FirstViewController.swift
//  SquirelList
//
//  Created by Denis Geary Lopez on 1/25/15.
//  Copyright (c) 2015 Frenvu Inc. All rights reserved.
//

import UIKit

class FirstViewController: UIViewController {

    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view, typically from a nib.
        
        
        /*
        var score = PFObject(className: "Score")
        score.setObject("Rob", forKey: "name")
        score.setObject(95, forKey: "number")
        score.saveInBackgroundWithBlock{
        
            (success: Bool!, error: NSError!) -> Void in
            
            if success == true {
                println("Score created with ID: \(score.objectId)")
            } else {
                println(error)
            }
        }
        */
        
        var query = PFQuery(className: "Score")
        query.getObjectInBackgroundWithId("kvkEWeY3YQ") {
        
            (score: PFObject!, error: NSError!) -> Void in
            
            if error == nil {
                println(score)
            } else {
                println(error)
            }
        }
        

        
    }


    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }


}

