//
//  TutorialContentViewController.swift
//  SquirrelList
//
//  Created by Denis Geary Lopez on 6/16/15.
//  Copyright (c) 2015 Frenvu Inc. All rights reserved.
//

//Displays an individual page for the tutorial content

import UIKit

class TutorialPageItemViewController: UIViewController {

    var itemIndex: Int = 0
    var text = "" {
        
        didSet {
            if let _ = textLabel {
                textLabel!.text = text
            }
            
        }
    }
    

    @IBOutlet weak var textLabel: UILabel?

    
    override func viewDidLoad() {
        super.viewDidLoad()
        textLabel?.text = text
        let screenSize: CGRect = UIScreen.mainScreen().bounds
        let screenWidth = screenSize.width
        if screenWidth == 414.0 {
            //The phone is an iphone 6 plus
            textLabel!.font = UIFont(name: "BebasNeueBook", size: 26.0)
        } else if screenWidth == 375.0 {
            //The phone is an iphone 6
            textLabel!.font = UIFont(name: "BebasNeueBook", size: 24.0)
        } else {
            //The phone is an iphone 5s, 5, or 4s
            textLabel!.font = UIFont(name: "BebasNeueBook", size: 20.0)
        }

    }

}
