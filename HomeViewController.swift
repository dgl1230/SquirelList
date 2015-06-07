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

    @IBAction func login(sender: AnyObject) {
        self.performSegueWithIdentifier("login", sender: self)
    }

    @IBAction func register(sender: AnyObject) {
        self.performSegueWithIdentifier("register", sender: self)
    }
    

}
