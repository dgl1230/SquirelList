//
//  GlobalFunctions.swift
//  SquirrelList
//
//  Created by Denis Geary Lopez on 8/12/15.
//  Copyright (c) 2015 Frenvu Inc. All rights reserved.
//

import Foundation


//Global variables - yes it's bad practice, but it makes so that we do less NSNotifications
var LOGGED_IN_USER_ACORNS = 123456789
var LOGGED_IN_USER_SQUIRREL_SLOTS = 123456789
var LOGGED_IN_USER_RERATES = 123456789
var LOGGED_IN_USER_GROUP_NAME = ""
var SQUIRREL_MAIN_TAB_SHOULD_RELOAD = false
var ONLY_ONE_GROUP_USER = true
var COUNTER = 0

//For using various functions across different classes. Perhaps a bit insecure and should be made into extensions, but still better than lots of redundant code


    /*
    What this does: displays a UIAlertController with a specified error, dismisses it when they press OK, and potentially executes whatever is in the closure if they provide it
    */
    func displayAlert(controller: UIViewController, title: String, message: String) {
        let alert = UIAlertController(title: title, message: message, preferredStyle: UIAlertControllerStyle.Alert)
        //alert.addAction(UIAlertAction(title: "Ok", style: UIAlertActionStyle.Default, handler: nil))
        alert.addAction(UIAlertAction(title: "Okay", style: UIAlertActionStyle.Default, handler: { (action: UIAlertAction) -> Void in
            alert.dismissViewControllerAnimated(true, completion: nil)
        }))
        controller.presentViewController(alert, animated: true, completion: nil)
    }


    /*
    What this does: Creates a loading spinner in the center of the view that disables all Interaction events. To enable
    interaction events, the function resumeInteractionEvents() musts be called. We return the NVActivityIndicator so that we can pass it into resumeInteractionEvents() to stop it
    */
    func displayLoadingAnimator(uiView: UIView) -> [AnyObject] {
        print("staring global animatoon")
        //Make keyboard disappear
        uiView.endEditing(true)
        //We create a container the same size as self.view so that we can make the background whiter and more transparent
        let container = UIView()
        container.frame = uiView.frame
        container.center = uiView.center
        container.backgroundColor = UIColor(white: 0.7, alpha: 0.3)
        //Loading view is for holding activityIndicatorView
        let loadingView = UIView()
        loadingView.frame = CGRectMake(0, 0, 70, 70)
        loadingView.center = CGPointMake(container.frame.size.width / 2, container.frame.size.height / 2)
        loadingView.backgroundColor = UIColor(white: 0, alpha: 0.4)
        loadingView.clipsToBounds = true
        loadingView.layer.cornerRadius = 10
        
        _ = CGFloat(uiView.frame.size.width)
        _ = CGFloat(uiView.frame.height)
        _ = Int(uiView.frame.width / 2)
        _ = Int(uiView.frame.height / 2)
        let frame = CGRectMake(0, 0, 100, 100)
        let activityIndicatorView = NVActivityIndicatorView(frame: frame, type: .BallClipRotatePulse, color: UIColor.orangeColor(), size: CGSize(width: 50, height: 50))
        activityIndicatorView.center = CGPointMake(loadingView.frame.size.width / 2, loadingView.frame.size.height / 2)
        loadingView.addSubview(activityIndicatorView)
        container.addSubview(loadingView)
        uiView.addSubview(container)
        activityIndicatorView.startAnimation()
        UIApplication.sharedApplication().beginIgnoringInteractionEvents()
        print("ending global animation")
        return [activityIndicatorView, container, loadingView]
    }

    /*
    What this does: Stops animating the activity indicator of self and calls endsIgnoringInteractionEvents()
    */
    func resumeInteractionEvents(activityIndicatorView: NVActivityIndicatorView, container: UIView, loadingView: UIView) {
        activityIndicatorView.stopAnimation()
        loadingView.removeFromSuperview()
        container.removeFromSuperview()
        UIApplication.sharedApplication().endIgnoringInteractionEvents()
    }

    //Sends push notifications to users who's usernames are in the provided 
    func sendPushNotifications(badge: Int, message: String, type: String, users: [String]) {
        let pushQuery = PFInstallation.query()
        pushQuery!.whereKey("username", containedIn: users)
        let push = PFPush()
        push.setQuery(pushQuery)
        let data = ["alert": message, "badge": badge, "sounds":"", "content-available": 1, "type": type]
        push.setData(data as [NSObject : AnyObject])
        push.sendPushInBackgroundWithBlock(nil)
    }



    //PARSE FUNCTIONS - Used for getting and setting user info

    func getUserInfo(infoArray: [String], username: String) -> String {
        var index = 0
        for stringChunk in infoArray {
            if  (stringChunk.rangeOfString(username, options: [], range: nil, locale: nil) != nil) {
                break
            }
            index += 1
        }
        let userString = infoArray[index]
        let colonIndex = userString.characters.indexOf(":")
        let correctIndex = colonIndex!.successor()
        let userInfo = userString.substringFromIndex(correctIndex)
        return userInfo
    }

    //Returns a new array to be saved to the group's relevant field, with updated user information
    func getNewArrayToSave(oldArray: [String], username: String, newInfo: String) -> [String] {
        var index = 0
        var newArray = oldArray
        for stringChunk in oldArray {
            if (stringChunk.rangeOfString(username, options: [], range: nil, locale: nil) != nil) {
                break
            }
            index += 1
        }
        let newUserInfo = "\(username):\(newInfo)"
        newArray[index] = newUserInfo
        return newArray
    }

    //Used for deleting via parse, so that we can user the removeObject function
    func getFullUserInfo(oldArray: [String], username: String) -> String {
        var index = 0
        for stringChunk in oldArray {
            if (stringChunk.rangeOfString(username, options: [], range: nil, locale: nil) != nil) {
                break
            }
            index += 1
        }
        return oldArray[index]
    }

    //Used for verifiying that a user's data exists in a group's array
    func userDataExists(dataArray: [String], username: String) -> Bool {
        for stringChunk in dataArray {
            if (stringChunk.rangeOfString(username, options: [], range: nil, locale: nil) != nil) {
                return true
            }
        }
        return false
    }

