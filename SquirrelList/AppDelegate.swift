
//
//  AppDelegate.swift
//  SquirelList
//
//  Created by Denis Geary Lopez on 1/25/15.
//  Copyright (c) 2015 Frenvu Inc. All rights reserved.
//

import UIKit

let networkDown = "com.frenvu.squirrellist.GOD_NETWORK_WHY"

@UIApplicationMain
class AppDelegate: UIResponder, UIApplicationDelegate, UITabBarControllerDelegate {

    var window: UIWindow?
    var reachability: Reachability?

    func application(application: UIApplication, didFinishLaunchingWithOptions launchOptions: [NSObject: AnyObject]?) -> Bool {
        NSNotificationCenter.defaultCenter().addObserver(self, selector: "checkForReachability:", name: kReachabilityChangedNotification, object: nil)
        self.reachability = Reachability.reachabilityForInternetConnection()
        self.reachability!.startNotifier()
        Parse.setApplicationId("6BTcw6XSmVmHfXh7BOFBsxD1yafzwkGNqeiqaldq", clientKey: "p8a21bPoRIKkWmhneL262toyrjpCRH9CZUjVTVTm")
        
        //For now we reset their badge numbers anytime the app launches 
        UIApplication.sharedApplication().applicationIconBadgeNumber = 0
        
        if PFUser.currentUser() == nil {
            //If the user isn't logged in, we need to present the login/register storyboard
            let loginRegisterStoryBoard = UIStoryboard(name: "Login-Register", bundle: nil)
            let loginController = loginRegisterStoryBoard.instantiateViewControllerWithIdentifier("Home") as! HomeViewController
            self.window!.rootViewController = loginController
            self.window!.makeKeyAndVisible()
        } else if PFUser.currentUser()!["currentGroup"] == nil {
            //Present just the MoreViewController to the user because they are still new
            let mainStoryboard = UIStoryboard(name: "More", bundle: nil)
            let moreController = mainStoryboard.instantiateViewControllerWithIdentifier("More") as! MoreTableViewController
            moreController.isNewUser = true
            let navigationController = UINavigationController(rootViewController: moreController)
            let blue = UIColor(red: 0, green: 191/255, blue: 1, alpha: 1)
            navigationController.navigationBar.barTintColor = blue
            self.window!.rootViewController = navigationController
            self.window!.makeKeyAndVisible()
        } else {
            //Present the tab bar with all the tabs
            self.window!.rootViewController = HomeTabViewController()
            self.window!.makeKeyAndVisible()
        }

        return true
  
    }
    
    func application(application: UIApplication, didRegisterUserNotificationSettings notificationSettings: UIUserNotificationSettings) {
        UIApplication.sharedApplication().registerForRemoteNotifications()
    }
    
    
    func application(application: UIApplication, didFailToRegisterForRemoteNotificationsWithError error: NSError) {

    }
    
    func application(application: UIApplication, didReceiveRemoteNotification userInfo: [NSObject : AnyObject]) {
        let aps = userInfo["aps"] as? NSDictionary
        let alert = aps!["alert"] as? NSString
        let message = alert as! String
        //The type can be "friendRequest", "groupInvite", "acceptedGroupInvite", "acceptedFriendRequest", "acceptedTrade", "proposedTrade", "reloadMessages", "reloadSquirrels", "rejectedTrade"
        let type = userInfo["type"] as! NSString
        
        if type == "acceptedFriendReuqest" {
            showBanner(UIColor.orangeColor(), message: message, title: "Friendship Accepted")
        } else if type == "acceptedGroupInvite" {
            showBanner(UIColor.orangeColor(), message: message, title: "Invitation Accepted")
             NSNotificationCenter.defaultCenter().postNotificationName(reloadSquirrels, object: self)
        } else if type == "acceptedTrade" {
            showBanner(UIColor.orangeColor(), message: message, title: "Trade Completed")
            //We should reload the user's squirrels if they have changed owners
            NSNotificationCenter.defaultCenter().postNotificationName(reloadSquirrels, object: self)
        } else if type == "friendRequest" {
            showBanner(UIColor.orangeColor(), message: message, title: "Friend Request")
        } else if type == "groupInvite" {
            showBanner(UIColor.orangeColor(), message: message, title: "Group Invitation")
        } else if type == "proposedTrade" {
            showBanner(UIColor.orangeColor(), message: message, title: "Trade Offer")
        } else if type == "rejectedTrade" {
            showBanner(UIColor.orangeColor(), message: message, title: "Trade Rejected")
        }else if type == "reloadMessages" {
            NSNotificationCenter.defaultCenter().postNotificationName("reloadMessages", object: self)
        } else if type == "reloadSquirrels" {
            NSNotificationCenter.defaultCenter().postNotificationName(reloadSquirrels, object: self)
        }
    }
    
    func application(application: UIApplication, didRegisterForRemoteNotificationsWithDeviceToken deviceToken: NSData) {
        let currentInstallation = PFInstallation.currentInstallation()
        currentInstallation.setDeviceTokenFromData(deviceToken)
        currentInstallation.saveInBackgroundWithBlock(nil)
    }

    func applicationWillResignActive(application: UIApplication) {
        // Sent when the application is about to move from active to inactive state. This can occur for certain types of temporary interruptions (such as an incoming phone call or SMS message) or when the user quits the application and it begins the transition to the background state.
        // Use this method to pause ongoing tasks, disable timers, and throttle down OpenGL ES frame rates. Games should use this method to pause the game.
    }

    func applicationDidEnterBackground(application: UIApplication) {
        // Use this method to release shared resources, save user data, invalidate timers, and store enough application state information to restore your application to its current state in case it is terminated later.
        // If your application supports background execution, this method is called instead of applicationWillTerminate: when the user quits.
    }

    func applicationWillEnterForeground(application: UIApplication) {
        // Called as part of the transition from the background to the inactive state; here you can undo many of the changes made on entering the background.
    }

    func applicationDidBecomeActive(application: UIApplication) {
        // Restart any tasks that were paused (or not yet started) while the application was inactive. If the application was previously in the background, optionally refresh the user interface.
    }

    func applicationWillTerminate(application: UIApplication) {
        // Called when the application is about to terminate. Save data if appropriate. See also applicationDidEnterBackground:.
    }
    
    
    //NON APPDELEGATE FUNCTIONS
    
    func checkForReachability(notification: NSNotification) {
        let remoteHostStatus = self.reachability!.currentReachabilityStatus()
        if (remoteHostStatus.rawValue == NotReachable.rawValue) {
            let mainStoryBoard = UIStoryboard(name: "ShittyConnection", bundle: nil)
            let monkeyController = mainStoryBoard.instantiateViewControllerWithIdentifier("MonkeyController") 
            self.window!.rootViewController = monkeyController
            self.window!.makeKeyAndVisible()
        } else if PFUser.currentUser() == nil {
            //If the user isn't logged in, we need to present the login/register storyboard
            let loginRegisterStoryBoard = UIStoryboard(name: "Login-Register", bundle: nil)
            let loginController = loginRegisterStoryBoard.instantiateViewControllerWithIdentifier("Home") as! HomeViewController
            self.window!.rootViewController = loginController
            self.window!.makeKeyAndVisible()
        } else if PFUser.currentUser()!["currentGroup"] == nil {
            //Present just the MoreViewController to the user because they are still new
            let mainStoryboard = UIStoryboard(name: "More", bundle: nil)
            let moreController = mainStoryboard.instantiateViewControllerWithIdentifier("More") as! MoreTableViewController
            moreController.isNewUser = true
            let navigationController = UINavigationController(rootViewController: moreController)
            let blue = UIColor(red: 0, green: 191/255, blue: 1, alpha: 1)
            navigationController.navigationBar.barTintColor = blue
            self.window!.rootViewController = navigationController
            self.window!.makeKeyAndVisible()
        } else {
            //Present the tab bar with all the tabs
            self.window!.rootViewController = HomeTabViewController()
            self.window!.makeKeyAndVisible()
        }
    }
    
    //Shows a notification banner
    func showBanner(color: UIColor, message: String, title: String) {
        let banner = Banner(title: title, subtitle: message , backgroundColor: color)
        banner.dismissesOnTap = true
        banner.show(5.0)
    }


}

