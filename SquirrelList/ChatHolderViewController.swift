//
//  ChatHolderViewController.swift
//  SquirrelList
//
//  Created by Denis Geary Lopez on 4/24/15.
//  Copyright (c) 2015 Frenvu Inc. All rights reserved.
//

//This view controller merely holds the containerView, which is MessagesViewController

import UIKit

class ChatHolderViewController: UIViewController {
    
    //Optional for storing whether the viewcontroller should reload (if the user changed their currentGroup)
    var shouldReLoad: Bool?


    override func prepareForSegue(segue: UIStoryboardSegue, sender: AnyObject?) {
        if segue.identifier == "messages" {
            let controller = segue.destinationViewController as! MessagesViewController
        }
    }
    
    func reloadWithNewGroup() {
        shouldReLoad = true
    }
    
    
    override func viewDidAppear(animated: Bool) {
        super.viewDidAppear(animated)
        if shouldReLoad == true {
            self.viewDidLoad()
        }
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        var groupName = PFUser.currentUser()!["currentGroup"]!["name"] as? String
        self.navigationItem.title = "\(groupName!) Chat"
        //Set notification to "listen" for when the the user has changed their currentGroup
        NSNotificationCenter.defaultCenter().addObserver(self, selector: "reloadWithNewGroup", name: reloadNotificationKey, object: nil)


    }


}
