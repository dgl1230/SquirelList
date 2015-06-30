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
            if let label = textLabel {
                textLabel!.text = text
            }
            
        }
    }
    

    @IBOutlet weak var textLabel: UILabel?

    
    override func viewDidLoad() {
        super.viewDidLoad()
        textLabel?.text = text

    }

}
