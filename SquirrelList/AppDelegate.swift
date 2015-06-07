//
//  AppDelegate.swift
//  SquirelList
//
//  Created by Denis Geary Lopez on 1/25/15.
//  Copyright (c) 2015 Frenvu Inc. All rights reserved.
//

import UIKit

@UIApplicationMain
class AppDelegate: UIResponder, UIApplicationDelegate, UITabBarControllerDelegate {

    var window: UIWindow?


    func application(application: UIApplication, didFinishLaunchingWithOptions launchOptions: [NSObject: AnyObject]?) -> Bool {
        Parse.setApplicationId("6BTcw6XSmVmHfXh7BOFBsxD1yafzwkGNqeiqaldq", clientKey: "p8a21bPoRIKkWmhneL262toyrjpCRH9CZUjVTVTm")

        let notificationTypes = UIUserNotificationType.Alert | UIUserNotificationType.Badge | UIUserNotificationType.Sound
        let notificationSettings = UIUserNotificationSettings(forTypes: notificationTypes, categories: nil)
        
        UIApplication.sharedApplication().registerUserNotificationSettings(notificationSettings)
        
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
            navigationController.navigationBar.barTintColor = UIColor(red: 0, green: 50, blue: 255, alpha: 1)
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
        println(error.localizedDescription)
    }
    
    func application(application: UIApplication, didReceiveRemoteNotification userInfo: [NSObject : AnyObject]) {
        //PFPush.handlePush(userInfo)
        //Alert the user when a new message has been sent 
        NSNotificationCenter.defaultCenter().postNotificationName("reloadMessages", object: nil)
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


}

