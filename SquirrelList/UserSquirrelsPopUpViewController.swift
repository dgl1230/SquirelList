//
//  UserSquirrelsPopUpViewController.swift
//  SquirrelList
//
//  Created by Denis Geary Lopez on 3/27/15.
//  Copyright (c) 2015 Frenvu Inc. All rights reserved.
//

/*
The PopUpViewController that holds the tableviewcontroller container for going through one's squirrels to offer a trade for
*/

import UIKit

@objc protocol UserSquirrelsPopUpViewControllerDelegate: class {

    optional func userSquirrelsPopUpViewControllerDelegate(controller: UserSquirrelsPopUpViewController, selectedSquirrel: PFObject, wantedSquirrelOwner: PFUser, wantedSquirrel: PFObject)
}

class UserSquirrelsPopUpViewController: PopUpViewController, UsersSquirrelsViewControllerDelegate {

    //These optionals need to be passed to the tableviewcontroller container and then passed back to the TradeViewController
    var desiredSquirrel: PFObject?
    var desiredSquirrelOwner: PFUser?
    var offeredSquirrel: PFObject?
    
    var delegate: UserSquirrelsPopUpViewControllerDelegate?

    
    override func prepareForSegue(segue: UIStoryboardSegue, sender: AnyObject?) {
        if segue.identifier == "userSquirrelsEmbed" {
            let controller = segue.destinationViewController as! UsersSquirrelsViewController
            controller.currentlyTrading = true
            controller.desiredSquirrel = desiredSquirrel
            controller.desiredSquirrelOwner = desiredSquirrelOwner
            controller.delegate = self
        }
    }
    
    /*
    //Delegate function for passing selected squrirel and other trade info back to the TradeViewController
    func SquirrelTradeDelegate(controller: SquirrelViewController, selectedSquirrel: PFObject, wantedSquirrelOwner: PFUser, wantedSquirrel: PFObject) {
            delegate?.userSquirrelsPopUpViewControllerDelegate!(self, selectedSquirrel: selectedSquirrel, wantedSquirrelOwner: wantedSquirrelOwner, wantedSquirrel: wantedSquirrel)
            dismissViewControllerAnimated(true, completion: nil)
    }
    */
    
    func selectedSquirrelForTrade(controller: UsersSquirrelsViewController, selectedSquirrel: PFObject, wantedSquirrelOwner: PFUser, wantedSquirrel: PFObject) {
            delegate!.userSquirrelsPopUpViewControllerDelegate!(self, selectedSquirrel: selectedSquirrel, wantedSquirrelOwner: wantedSquirrelOwner, wantedSquirrel: wantedSquirrel)
            dismissViewControllerAnimated(true, completion: nil)
    }


    


}
