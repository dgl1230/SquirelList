//
//  HomeViewController.swift
//  SquirrelList
//
//  Created by Denis Geary Lopez on 6/1/15.
//  Copyright (c) 2015 Frenvu Inc. All rights reserved.
//

// View controller for when user is logged out and they either need to login or regsiter

import UIKit

class HomeViewController: UIViewController {


    @IBOutlet weak var loginButton: UIButton!
    @IBOutlet weak var registerButton: UIButton!

    @IBAction func forgotPassword(sender: AnyObject) {
        self.performSegueWithIdentifier("forgotPassword", sender: self)
    }
    
    @IBAction func login(sender: AnyObject) {
        self.performSegueWithIdentifier("login", sender: self)
    }


    @IBAction func register(sender: AnyObject) {
        self.performSegueWithIdentifier("register", sender: self)
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        //Set the login and register buttons to have rounded corners
        loginButton.layer.cornerRadius = 5
        loginButton.layer.masksToBounds = true
        registerButton.layer.cornerRadius = 5
        registerButton.layer.masksToBounds = true
        //self.view.backgroundColor = UIColor(patternImage: UIImage(named: "squirrel-list-bg")!)
        
    }
    

}
