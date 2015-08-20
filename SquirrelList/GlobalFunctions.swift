//
//  GlobalFunctions.swift
//  SquirrelList
//
//  Created by Denis Geary Lopez on 8/12/15.
//  Copyright (c) 2015 Frenvu Inc. All rights reserved.
//

import Foundation

//For using various functions across different classes. Perhaps a bit insecure and should be made into extensions, but still better than lots of redundant code


    /* Parameters: error, which is the error that the user should see in the UIAlertController
    What this does: displays a UIAlertController with a specified error and dismisses it when they press OK
    */
    func displayAlert(controller: UIViewController, title: String, message: String) {
        var alert = UIAlertController(title: title, message: message, preferredStyle: UIAlertControllerStyle.Alert)
        alert.addAction(UIAlertAction(title: "Ok", style: UIAlertActionStyle.Default, handler: nil))
        controller.presentViewController(alert, animated: true, completion: nil)
    }


    /*
    What this does: Creates a loading spinner in the center of the view that disables all Interaction events. To enable
    interaction events, the function resumeInteractionEvents() musts be called. We return the NVActivityIndicator so that we can pass it into resumeInteractionEvents() to stop it
    */
    func displayLoadingAnimator(uiView: UIView) -> [AnyObject] {
        //Make keyboard disappear
        uiView.endEditing(true)
        //We create a container the same size as self.view so that we can make the background whiter and more transparent
        var container = UIView()
        container.frame = uiView.frame
        container.center = uiView.center
        container.backgroundColor = UIColor(white: 0.7, alpha: 0.3)
        //Loading view is for holding activityIndicatorView
        var loadingView = UIView()
        loadingView.frame = CGRectMake(0, 0, 70, 70)
        loadingView.center = uiView.center
        loadingView.backgroundColor = UIColor(white: 0, alpha: 0.4)
        loadingView.clipsToBounds = true
        loadingView.layer.cornerRadius = 10
        
        let x = CGFloat(uiView.frame.size.width)
        let y = CGFloat(uiView.frame.height)
        let cellWidth = Int(uiView.frame.width / 2)
        let cellHeight = Int(uiView.frame.height / 2)
        let frame = CGRectMake(0, 0, 100, 100)
        var activityIndicatorView = NVActivityIndicatorView(frame: frame, type: .BallClipRotatePulse, color: UIColor.orangeColor(), size: CGSize(width: 50, height: 50))
        activityIndicatorView.center = CGPointMake(loadingView.frame.size.width / 2, loadingView.frame.size.height / 2)
        loadingView.addSubview(activityIndicatorView)
        container.addSubview(loadingView)
        uiView.addSubview(container)
        activityIndicatorView.startAnimation()
        //uiView.bringSubviewToFront(activityIndicatorView)
        UIApplication.sharedApplication().beginIgnoringInteractionEvents()
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


    //PARSE FUNCTIONS - Used for getting and setting user info

    func getUserInfo(infoArray: [String], username: String) -> String {
        var index = 0
        for stringChunk in infoArray {
            if  (stringChunk.rangeOfString(username, options: nil, range: nil, locale: nil) != nil) {
                break
            }
            index += 1
        }
        let userString = infoArray[index]
        let colonIndex = find(userString, ":")
        let correctIndex = colonIndex!.successor()
        let userInfo = userString.substringFromIndex(correctIndex)
        return userInfo
    }

    //Returns a new array to be saved to the group's relevant field, with updated user information
    func getNewArrayToSave(oldArray: [String], username: String, newInfo: String) -> [String] {
        var index = 0
        var newArray = oldArray
        for stringChunk in oldArray {
            if (stringChunk.rangeOfString(username, options: nil, range: nil, locale: nil) != nil) {
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
            if (stringChunk.rangeOfString(username, options: nil, range: nil, locale: nil) != nil) {
                break
            }
            index += 1
        }
        return oldArray[index]
    }

