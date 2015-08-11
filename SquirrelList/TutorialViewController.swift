//
//  TutorialViewController.swift
//  SquirrelList
//
//  Created by Denis Geary Lopez on 6/27/15.
//  Copyright (c) 2015 Frenvu Inc. All rights reserved.
//

//Controller for the TutorialPageItemViewController

import UIKit

class TutorialViewController: UIViewController, UIPageViewControllerDataSource, UIPageViewControllerDelegate {

    var pageViewController: UIPageViewController?
    var textContent: [String] = []
    
    let moreContent = ["Wait for friends to invite you to a group", "Or create a group and invite them"]
    let squirrelTabContent = ["Squirrel Slots = # of squirrels you can get", "Every user in a group = +1 Squirrel Slot", "Swipe left to delete a squirrel","View trades from the top left corner"]
    let userTabContent = ["Check out all of your friends' squirrels", "Swipe left on your squirrels to drop them", "Get acorns for visiting groups daily", "Use acorns to buy Squirrel Slots or Rerates", "You have separate acorns in each group"]
    
    //Variable for keeping track of what content to show, depending on what tab the user is on. Value will either be "more" "squirrel" or "user"
    var typeOfContent = ""
    
    
    
    private func createPageViewController() {
        let pageController = self.storyboard!.instantiateViewControllerWithIdentifier("PageController") as! UIPageViewController
        pageController.dataSource = self
        pageController.delegate = self
        
        if textContent.count > 0 {
            let firstController = getItemController(0)!
            let startingViewControllers: NSArray = [firstController]
            pageController.setViewControllers(startingViewControllers as [AnyObject], direction: UIPageViewControllerNavigationDirection.Forward, animated: false, completion: nil)
        }
        
        pageViewController = pageController
        addChildViewController(pageViewController!)
        self.view.addSubview(pageViewController!.view)
        pageViewController!.didMoveToParentViewController(self)
    }
    
    private func setupPageControl() {
        let appearance = UIPageControl.appearance()
        let blue = UIColor(red: 0, green: 191/255, blue: 1, alpha: 1)
        appearance.pageIndicatorTintColor = UIColor.grayColor()
        appearance.currentPageIndicatorTintColor = blue
        appearance.backgroundColor = UIColor.whiteColor()
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        if typeOfContent == "more" {
            textContent = moreContent
        } else if typeOfContent == "squirrel" {
            textContent = squirrelTabContent
        } else if typeOfContent == "user" {
            textContent = userTabContent
        }
        createPageViewController()
        setupPageControl()

    }
    
    // MARK: - UIPageViewControllerDataSource
    
    func pageViewController(pageViewController: UIPageViewController, viewControllerBeforeViewController viewController: UIViewController) -> UIViewController? {
        
        let itemController = viewController as! TutorialPageItemViewController
        if itemController.itemIndex > 0 {
            return getItemController(itemController.itemIndex-1)
        }
        
        return nil
    }
    
    func pageViewController(pageViewController: UIPageViewController, viewControllerAfterViewController viewController: UIViewController) -> UIViewController? {
        
        let itemController = viewController as! TutorialPageItemViewController
        
        if itemController.itemIndex + 1 < textContent.count {
            return getItemController(itemController.itemIndex+1)
        }

        return UIViewController()
    }
    
    func pageViewController(pageViewController: UIPageViewController, willTransitionToViewControllers pendingViewControllers: [AnyObject]) {
        let itemController = pendingViewControllers[0] as? TutorialPageItemViewController
        //Then the casting failed, and the user has swiped through all of the tutorialPageItemControllers
        if itemController == nil {
            let appDelegate = UIApplication.sharedApplication().delegate as! AppDelegate
            
            if PFUser.currentUser()!["currentGroup"] == nil {
                //Present just the MoreViewController to the user because they are still new
                let mainStoryboard = UIStoryboard(name: "More", bundle: nil)
                let moreController = mainStoryboard.instantiateViewControllerWithIdentifier("More") as! MoreTableViewController
                moreController.isNewUser = true
                let navigationController = UINavigationController(rootViewController: moreController)
                let blue = UIColor(red: 0, green: 191/255, blue: 1, alpha: 1)
                navigationController.navigationBar.barTintColor = blue
                appDelegate.window!.rootViewController = navigationController
                appDelegate.window!.makeKeyAndVisible()
            } else {
                //Present the tab bar with all the tabs
                //appDelegate.window!.rootViewController = HomeTabViewController()
                //appDelegate.window!.makeKeyAndVisible()
                self.dismissViewControllerAnimated(true, completion: nil)
            }
            //Make keyboard disappear
            self.view.endEditing(true)

            //We want to show these screens to users only once
            if typeOfContent == "more" {
               PFUser.currentUser()!["newMoreTab"] = false
            } else if typeOfContent == "squirrel" {
                PFUser.currentUser()!["newSquirrelTab"] = false
            } else if typeOfContent == "user" {
                PFUser.currentUser()!["newUserTab"] = false
            }
            PFUser.currentUser()!.save()
        }
    }
    
    private func getItemController(itemIndex: Int) -> TutorialPageItemViewController? {
        if itemIndex < textContent.count {
            let pageItemController = self.storyboard!.instantiateViewControllerWithIdentifier("PageItemController") as! TutorialPageItemViewController
            pageItemController.itemIndex = itemIndex
            pageItemController.text = textContent[itemIndex]
            return pageItemController
        }
        return nil
    }
    
    // MARK: - Page Indicator
    
    func presentationCountForPageViewController(pageViewController: UIPageViewController) -> Int {
        return textContent.count
    }
    
    func presentationIndexForPageViewController(pageViewController: UIPageViewController) -> Int {
        return 0
    }


}
