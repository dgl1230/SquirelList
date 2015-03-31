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

        let mainStoryboard = UIStoryboard(name: "Main", bundle: nil)
        let usersViewController = mainStoryboard.instantiateViewControllerWithIdentifier("Users") as UINavigationController
        let squirrelsViewController = mainStoryboard.instantiateViewControllerWithIdentifier("Squirrels") as UINavigationController
        let chatViewController = mainStoryboard.instantiateViewControllerWithIdentifier("Chat") as UINavigationController

        //Since the moreViewController isn't hooked up to the HomeTableViewController in the storyboard, we need to set attritbutes
        let moreStoryboard = UIStoryboard(name: "More", bundle: nil)
        var moreViewController = moreStoryboard.instantiateViewControllerWithIdentifier("More") as UINavigationController
        moreViewController.tabBarItem = UITabBarItem(title: "", image: UIImage(named: "tabbar_more"), tag: 4)
        moreViewController.navigationBar.titleTextAttributes = [NSForegroundColorAttributeName: UIColor.whiteColor()]
        self.viewControllers = [usersViewController, squirrelsViewController, chatViewController, moreViewController]
    }


}
