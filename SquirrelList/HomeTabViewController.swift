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
        let blue = UIColor(red: 0, green: 191/255, blue: 1, alpha: 1)
        self.tabBar.tintColor = UIColor.orangeColor()
        self.tabBar.barTintColor = blue
        UITabBarItem.appearance().setTitleTextAttributes([NSForegroundColorAttributeName: UIColor.whiteColor()], forState:.Normal)
        


        
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
        
        //Set each tab image to white
        for item in self.tabBar.items as! [UITabBarItem] {
            if let image = item.image {
                item.image = image.imageWithColor(UIColor.whiteColor()).imageWithRenderingMode(.AlwaysOriginal)
            }
        }
        
    }
    
}

// Image extension to customize default color of each tab image
    extension UIImage {
        func imageWithColor(tintColor: UIColor) -> UIImage {
        UIGraphicsBeginImageContextWithOptions(self.size, false, self.scale)

        let context = UIGraphicsGetCurrentContext() as CGContextRef
        CGContextTranslateCTM(context, 0, self.size.height)
        CGContextScaleCTM(context, 1.0, -1.0);
        CGContextSetBlendMode(context, kCGBlendModeNormal)

        let rect = CGRectMake(0, 0, self.size.width, self.size.height) as CGRect
        CGContextClipToMask(context, rect, self.CGImage)
        tintColor.setFill()
        CGContextFillRect(context, rect)

        let newImage = UIGraphicsGetImageFromCurrentImageContext() as UIImage
        UIGraphicsEndImageContext()

        return newImage
    }
}
