//
//  HomeViewController.swift
//  SquirelList
//
//  Created by Denis Geary Lopez on 1/27/15.
//  Copyright (c) 2015 Frenvu Inc. All rights reserved.
//

import UIKit

class HomeTabViewController: UITabBarController {

    override func viewDidLoad() {
        super.viewDidLoad()
        
        //Configure the colors for the tab bar and tab icons
        let blue = UIColor(red: 0, green: 191, blue: 255, alpha: 1)
        self.tabBar.tintColor = UIColor.orangeColor()
        self.tabBar.barTintColor = blue
        //self.tabBar.selectedImageTintColor

        
        //Setting the tabs programmatically so that we can use multiple storyboards
        let mainStoryboard = UIStoryboard(name: "Main", bundle: nil)
        
        let usersViewController = mainStoryboard.instantiateViewControllerWithIdentifier("Users") as! UINavigationController
        usersViewController.tabBarItem = UITabBarItem(title: "Users", image: UIImage(named: "group"), tag: 4)
        
        let squirrelsViewController = mainStoryboard.instantiateViewControllerWithIdentifier("Squirrels")as! UINavigationController
        squirrelsViewController.tabBarItem = UITabBarItem(title: "Squirrels", image: UIImage(named: "squirrel"), tag: 4)
        //squirrelsViewController.tabBarItem.imageInsets.top = 6
        //squirrelsViewController.tabBarItem.imageInsets.bottom = -6
        
        let chatViewController = mainStoryboard.instantiateViewControllerWithIdentifier("Chat") as! UINavigationController

        //Since the moreViewController isn't hooked up to the HomeTableViewController in the storyboard, we need to set attritbutes
        let moreStoryboard = UIStoryboard(name: "More", bundle: nil)
        var moreViewController = moreStoryboard.instantiateViewControllerWithIdentifier("MoreNavigationController") as! UINavigationController
        moreViewController.tabBarItem = UITabBarItem(title: "", image: UIImage(named: "tabbar_more"), tag: 4)
        moreViewController.tabBarItem.imageInsets.top = 8
        moreViewController.tabBarItem.imageInsets.bottom = -8
        moreViewController.navigationBar.titleTextAttributes = [NSForegroundColorAttributeName: UIColor.whiteColor()]
        self.viewControllers = [usersViewController, squirrelsViewController, chatViewController, moreViewController]
        
    }
}
